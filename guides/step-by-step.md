# 🧭 Step-by-step deployment

This guide takes you from nothing running through **AWS logs in Splunk**, **adversary simulation**, and **corporate-style detections**. Skip any step you have already completed.

---

## ✨ Overview

| Step | What you do |
|------|-------------|
| 1 | Host Splunk in Docker. |
| 2 | Create indexes for AWS data. |
| 3 | Install Splunk Add-on for AWS. |
| 4 | Use Terraform (via `build.ps1`) to create AWS logging. |
| 5 | Configure add-on inputs and verify data ingestion. |
| 6 | Run lab-safe red team simulation to generate events. |
| 7 | Build detections and a corporate dashboard. |


---

## ✅ Requirements

- Docker Desktop  
- Python 3.10+  
- AWS account  
- PowerShell  

If `build.ps1` keeps asking for keys, run `aws configure` once, then rerun build.

---

## 1. 🐳 Using Docker to host Splunk

Splunk runs locally in a container so you can search logs without a cloud-hosted Splunk instance. Once it’s set up, you can also start/stop it from **Docker Desktop**.

```bash
cd soc
docker compose up -d
```

Open **https://localhost:8000**. Default login is `admin` with password from `soc/.env` or compose defaults (e.g. `ChangeMe123!`). First start may take several minutes.

---

## 2. 📚 Splunk setup for indexes

Create the indexes the add-on will write to.

```bash
pip install splunk-sdk
python ./scripts/setup_splunk.py
```

Use the Splunk admin password when prompted. Confirm under **Settings → Indexes** that `aws_cloudtrail`, `aws_config`, and `aws_vpcflow` exist.

---

## 3. 📦 Installing the AWS add-on

The Splunk Add-on for AWS reads from S3 buckets. Splunkbase “Already installed” applies to your account only—you still install the `.tgz` into your Splunk instance.

1. Download: https://splunkbase.splunk.com/app/1876/  
2. Optional: save the `.tgz` under `soc/add-on/`  
3. In Splunk: **Apps → Manage Apps → Install app from file** → upload → restart  

Inputs are configured after the AWS build (Step 5).

---

## 4. ☁️ Terraform basics and usage to build infra in AWS

Terraform provisions AWS resources as code. You define **what** you want (buckets, trail, Config, VPC Flow Logs, IAM user); Terraform figures out **how** to create it.

**Key concepts:**

| Command | Purpose |
|---------|---------|
| `terraform init` | Download providers and prepare state. |
| `terraform plan` | Show what would change without applying. |
| `terraform apply` | Create or update resources. |
| `terraform destroy` | Remove all resources. |

**This lab:** `build.ps1` runs `init` and `apply` for you. It installs AWS CLI and Terraform if missing and prompts for credentials unless `aws configure` is set.

```powershell
cd infra
.\build.ps1
```

Use your IAM user keys if prompted. Confirm with `yes`.

**Before closing the terminal**, copy:

- Three bucket names (`soc-lab-cloudtrail-…`, `soc-lab-config-…`, `soc-lab-vpcflow-…`)  
- `soc-lab-splunk-addon` access key ID and secret (add-on only; secret is shown once)

### Credentials {#credentials}

```powershell
aws configure
```

Stops repeated credential prompts on later runs.

If the script is blocked:

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

Direct Terraform use: [infra/README.md](../infra/README.md).

---

## 5. 🔄 Data ingestion in Splunk

Connect the add-on to your buckets so Splunk pulls events from S3.

> **Tip:** Plain S3 is simplest. SQS-based S3 is supported if you enable the queues in Terraform.

### Build output to use

From Step 4, capture:

| Output | Use in add-on |
|--------|----------------|
| cloudtrail bucket name | CloudTrail S3 input |
| config bucket name | Config S3 input |
| vpc_flow_logs bucket name | VPC Flow S3 input |
| splunk IAM access key ID / secret | AWS Account configuration |

### Configure inputs

1. Add-on **Configuration → AWS Account** — enter the Splunk IAM keys from Step 4.  
2. **Inputs → Create New Input** — create three S3 inputs:

| Input type | Bucket (from build output) | Index |
|------------|---------------------------|--------|
| CloudTrail | cloudtrail bucket | `aws_cloudtrail` |
| Config | config bucket | `aws_config` |
| VPC Flow Logs | vpcflow bucket | `aws_vpcflow` |

Use **plain S3** only—do not use SQS-based S3 inputs.

### Plain S3 vs SQS-based S3 {#plain-s3-vs-sqs}

| Pattern | Behavior | This lab |
|---------|----------|----------|
| **Plain S3** | Splunk lists and reads objects in the bucket. | Supported |
| **SQS-based S3** | S3 events go to a queue; Splunk consumes the queue. | Supported (optional) |

If you choose SQS-based inputs, re-run Terraform so the queues and permissions exist (Step 4), then configure the input with the queue that matches the bucket.

### What each source writes

- **CloudTrail** — Management API activity. Trail delivers JSON into the CloudTrail bucket.
- **AWS Config** — Configuration snapshots and changes into the Config bucket via the delivery channel.
- **VPC Flow Logs** — Network flow metadata (accept/reject, src/dst) into the VPC Flow bucket. Delivery is asynchronous; allow time after first traffic.

### ✅ Verify

```
index=aws_cloudtrail earliest=-30m
index=aws_config earliest=-30m
index=aws_vpcflow earliest=-30m
```

Empty results at first are normal; AWS and the add-on poll asynchronously—wait and retry.

---

## 6. 🎭 Red team strategies for adversary simulation

Once data flows, you can **simulate adversary activity** in your AWS account to generate events and validate that your detections fire. The goal is purple-team style: safe, controlled actions that mirror real threats.

**Lab-safe approach:**

- Use a **dedicated lab account** or isolated resources.  
- Do not target production workloads or shared assets.  
- Actions should be **detectable** (CloudTrail, Config, VPC Flow) but **reversible**.

**Example scenarios to simulate:**

| Scenario | What to do | What gets logged |
|----------|------------|------------------|
| IAM privilege escalation | Create a new IAM user or attach a policy; then remove. | CloudTrail `CreateUser`, `AttachUserPolicy`, etc. |
| Console access from new region | Log in from a different region or IP (VPN/cloud shell). | CloudTrail `ConsoleLogin`. |
| S3 bucket exposure | Change bucket ACL or policy to public; revert. | CloudTrail + Config snapshot. |
| Unusual API volume | Run `Describe*` calls in a loop (e.g. via AWS CLI). | CloudTrail API events. |
| Security group changes | Open a port, add a rule; revert. | CloudTrail + Config. |

**Tools and frameworks:**

- [MITRE ATT&CK for Cloud (AWS)](https://attack.mitre.org/matrices/enterprise/cloud/aws/) — map TTPs to CloudTrail event names.  
- [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team) — atomic tests for many platforms; adapt cloud tests for your lab.  

After running simulations, search Splunk to confirm events appear and your detections (Step 7) fire.

---

## 7. 📊 Detections to build corporate dashboard

Use Splunk to build **detections** and a **corporate-style dashboard** that give visibility over the lab’s AWS activity.

**Example searches (detections):**

| Detection | SPL (concept) |
|-----------|---------------|
| Failed console login | `index=aws_cloudtrail eventName=ConsoleLogin errorMessage=*` |
| IAM user created | `index=aws_cloudtrail eventName=CreateUser` |
| Security group modified | `index=aws_cloudtrail eventName=AuthorizeSecurityGroupIngress OR RevokeSecurityGroupIngress` |
| S3 bucket policy changed | `index=aws_cloudtrail eventName=PutBucketPolicy` |
| Config non-compliant changes | `index=aws_config complianceType=NON_COMPLIANT` |
| Unusual API caller | `index=aws_cloudtrail eventName=* \| stats count by userIdentity.userName \| where count > 100` |

**Building the dashboard:**

1. **Splunk → Dashboards → Create New Dashboard**  
2. Add panels for:  
   - **Alerts by severity** — count of high-impact events (e.g. IAM, policy changes).  
   - **Top event names** — `stats count by eventName` for CloudTrail.  
   - **Timeline** — events over time.  
   - **Failed logins** — from the failed ConsoleLogin search above.  

Use saved searches and convert them to dashboard panels. Style it like a corporate SOC dashboard: key metrics upfront, drill-down into raw events.

---

## 🧹 Cleanup

```powershell
cd infra
.\destroy.ps1
```

Confirm with `yes`. Splunk can remain running; only AWS resources are removed.

---

## 🔐 Notes on security

- Keep `soc-lab-splunk-addon` keys out of repos; use only in the add-on UI.  
- Restrict execution policy bypass to trusted scripts only.  
- Run adversary simulation only in lab accounts.

---

## 🛠️ Troubleshooting

| Issue | Action |
|-------|--------|
| Script blocked by policy | `powershell -ExecutionPolicy Bypass -File .\build.ps1` |
| SQS errors in add-on | [Step 5 — Plain S3 vs SQS](#plain-s3-vs-sqs) — use plain S3 inputs only. |
