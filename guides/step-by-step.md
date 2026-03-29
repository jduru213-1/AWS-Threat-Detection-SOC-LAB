# Step-by-step

Work through the steps in order; skip anything you have already finished. This guide matches the [main README](../README.md) Quick start. For narrative detail and Splunk/AWS UI specifics, see the project’s Medium blog.

---

## Requirements

### Tools on your machine

- **Docker Desktop** — Splunk runs in Compose under `soc/`.
- **Python 3.10+** — for `scripts/setup_splunk.py` and the Splunk SDK.
- **Bash** — `build.sh` / `destroy.sh` are bash scripts (Git Bash on Windows is fine).

### AWS account and CLI

- Use an AWS account you can treat as a **lab or sandbox** (avoid production).
- Install the **AWS CLI** and run **`aws configure`** so credentials exist locally. Terraform and `build.sh` use the **same credential chain** as the CLI — see [`infra/README.md`](../infra/README.md).

### IAM permissions

**`aws configure` only stores keys; it does not grant API rights.** The identity you use for **`./build.sh`** must be allowed to create and manage everything in the Terraform stack: IAM users and policies, S3 buckets and policies, SQS, SNS, CloudTrail, AWS Config (recorder, roles, delivery), VPC Flow Logs on the default VPC, and related resources.

A **narrow IAM user** often fails mid-apply with **`AccessDenied`**. For a personal lab, use an IAM user or role with **`AdministratorAccess`** in a **non-production account**. If your org gives you a restricted role, align policy with Terraform’s failed API calls — this repo does not ship a minimal fixed IAM policy.

**Check:** `aws sts get-caller-identity` must succeed **before** you run `cd infra && ./build.sh`.

---

## 1. Docker Splunk

| | |
|---|---|
| **Why** | Local Splunk is the SIEM for this lab (Docker). |
| **You need** | Docker Desktop running. |
| **Do** | From the repo root: |

```bash
cd soc
docker compose up -d
```

| **Then** | Open **https://localhost:8000**, sign in as **`admin`**. Default password **`ChangeMe123!`** (see `soc/docker-compose.yml`). Optional: set a password in **`soc/.env`** next to the compose file. |

---

## 2. Indexes

| | |
|---|---|
| **Why** | CloudTrail, Config, and VPC Flow should land in separate indexes. |
| **You need** | Python, **`splunk-sdk`** (`pip install splunk-sdk`), Splunk from step 1 up. |
| **Do** | From the repo root: |

```bash
pip install splunk-sdk
python ./scripts/setup_splunk.py
```

| **Verify** | In Splunk: **Settings → Indexes** — you should see **`aws_cloudtrail`**, **`aws_config`**, **`aws_vpcflow`**. |

---

## 3. AWS add-on

| | |
|---|---|
| **Why** | The add-on pulls S3 notifications via SQS into Splunk. |
| **You need** | Splunk running (step 1). |
| **Do** | 1. Download **[Splunk Add-on for AWS](https://splunkbase.splunk.com/app/1876/)**.<br>2. In Splunk: **Apps → Manage Apps → Install app from file**, upload the `.tgz`, restart Splunk when prompted. |
| **Note** | **Inputs** are configured in step 5 — install only here. |

---

## 4. Build AWS

| | |
|---|---|
| **Why** | Terraform (via `build.sh`) creates buckets, trails, Config, queues, IAM users, etc. |
| **You need** | AWS CLI credentials and **IAM** as in [Requirements](#requirements) (see [IAM permissions](#iam-permissions)). Steps 1–3 can run before step 4; you need step 2 indexes before ingestion matters. |
| **Do** | |

```bash
cd infra
./build.sh
```

| **Then** | Approve the apply with **`yes`**. **Save from the output:** S3 bucket names, SQS queue URLs, **`soc-lab-splunk-addon`** access key and secret (and Stratus outputs if shown). |
| **If it fails** | **`chmod +x ./build.sh`** then rerun (Unix). Use **`aws configure`** so the CLI stops prompting. Queue URLs are also described in [`infra/outputs_sqs.tf`](../infra/outputs_sqs.tf). |

---

## 5. Data ingestion (SQS-based S3)

| | |
|---|---|
| **Why** | Connect Splunk to the queues Terraform created so logs flow into the right indexes. |
| **You need** | Add-on installed (step 3), Splunk IAM keys from **step 4**, queue names/URLs from **`build.sh`** / `terraform output`. |
| **Do** | 1. **Configuration → AWS Account** — paste the **Splunk** IAM access key and secret from step 4.<br>2. **Inputs → Create New Input** — type **SQS-based S3**. Create **three** inputs: |

| Type | Queue (from Terraform / `build.sh` output) | Index |
|------|---------------------------------------------|--------|
| CloudTrail | CloudTrail SQS queue URL | `aws_cloudtrail` |
| Config | Config SQS queue URL | `aws_config` |
| VPC Flow Logs | VPC Flow SQS queue URL | `aws_vpcflow` |

| **Note** | The Splunk IAM user already has SQS permissions from Terraform. |
| **Verify** | In Search: `index=aws_cloudtrail earliest=-30m` (repeat for `aws_config`, `aws_vpcflow`). Allow a few minutes; retry if empty. |

---

## 6. Red team (Stratus)

| | |
|---|---|
| **Why** | Generate safe attack simulations; events appear in CloudTrail and then Splunk. |
| **You need** | AWS stack built (step 4), repo-root **`.env.stratus`** from `build.sh` outputs (see [attacks/README.md](../attacks/README.md)). |
| **Do** | |

```bash
cd attacks
source ./configure-stratus.sh
stratus list --platform aws
stratus detonate <technique-id> --cleanup
```

| **Note** | Re-run **`source ./configure-stratus.sh`** in each new shell. Use **Stratus** credentials only for simulations, not for `destroy.sh`. |

---

## 7. Detections / dashboard

| | |
|---|---|
| **Why** | Turn searches into monitoring and practice. |
| **You need** | Data in indexes (step 5). |
| **Try** | Example searches: |

- Failed console login: `index=aws_cloudtrail eventName=ConsoleLogin errorMessage=*`
- IAM user created: `index=aws_cloudtrail eventName=CreateUser`
- Security group change: `index=aws_cloudtrail eventName=AuthorizeSecurityGroupIngress OR RevokeSecurityGroupIngress`

| **Dashboard** | **Splunk → Dashboards → Create** — add panels from saved searches (counts, timeline, failed logins). More ideas: [`detections/`](../detections/README.md). |

---

## Cleanup

| | |
|---|---|
| **Why** | Remove AWS resources and avoid ongoing cost when the lab is idle. |
| **You need** | The **same AWS identity** you used for **`build.sh`** — **not** the Stratus profile. |
| **Do** | |

```bash
cd infra
./destroy.sh
```

| **Then** | Confirm with **`yes`**. The script empties buckets before destroy; you may be asked whether to **keep** Splunk/Stratus IAM users for a rebuild. See **`./destroy.sh --help`** for flags. |
