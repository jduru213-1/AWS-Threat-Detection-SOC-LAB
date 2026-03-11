# 🛡️ AWS Threat Detection SOC Lab

CloudTrail, Config, VPC Flow → S3 → Splunk (Docker). Detection practice + Stratus Red Team.

Built by me, with AI assistance (Cursor and Codex) to speed up iteration and documentation.

<p align="center">
  <img width="1330" height="778" alt="Architecture: AWS → S3 → SQS → Splunk (Docker)" src="https://github.com/user-attachments/assets/c8b22a6b-affa-441a-88df-82d818fa1a4e" />
</p>

---

## ✨ Overview

This repo is a repeatable lab for standing up **AWS logging** and ingesting it into **Splunk** so you can practice **search + detection engineering** with real telemetry.

---

## 🧩 Components (what you’re building)

| Component | What it does | Where |
|----------|--------------|------|
| Splunk (Docker) | Local Splunk Enterprise for searching and dashboards | `soc/` |
| Index setup | Creates `aws_cloudtrail`, `aws_config`, `aws_vpcflow` | `scripts/setup_splunk.py` |
| Splunk Add-on for AWS | Pulls logs from S3 into the right index | Splunk UI |
| AWS logging | CloudTrail, Config, VPC Flow Logs → S3 buckets | `infra/` (Terraform) |
| Stratus Red Team | Generates “known-bad” activity to validate detections | `attacks/` |

---

## ✅ Requirements

Docker Desktop · Python 3.10+ · AWS account · PowerShell · `aws configure`

---

## 🚀 Deployment (quick start)

1. Start Splunk (Docker):

```bash
cd soc
docker compose up -d
```

Open https://localhost:8000

2. Create indexes:

```bash
pip install splunk-sdk
python ./scripts/setup_splunk.py
```

3. Install the [Splunk Add-on for AWS](https://splunkbase.splunk.com/app/1876/) (Apps → Install from file), then restart Splunk.

4. Build AWS resources:

```powershell
cd infra
.\build.ps1
```

Save the bucket names + Splunk IAM keys from the output.

5. Configure the add-on:
   - Configuration → AWS Account (paste keys)
   - Inputs → create 3 S3 inputs (CloudTrail/Config/VPC Flow) pointing at the buckets from Step 4 and indexes `aws_cloudtrail`, `aws_config`, `aws_vpcflow`

6. Optional Stratus Red Team:

```powershell
cd attacks
.\configure-stratus.ps1
stratus list --platform aws
```

[Full steps](guides/step-by-step.md)

---

## 🔎 Verify data

Splunk Search: `index=aws_cloudtrail earliest=-1h` (and `aws_config`, `aws_vpcflow`). Wait if empty.

---

## 🧹 Cleanup

```powershell
cd infra
.\destroy.ps1
```

Same credentials as build (not Stratus).

---

## 🔐 Notes on security

- Don’t commit `.env*` files or access keys.
- Use `soc-lab-splunk-addon` only for ingestion and `soc-lab-stratus` only for attack simulation.

---

## 🗂️ Layout

| Path | What |
|------|------|
| `infra/` | `build.ps1`, `destroy.ps1`, Terraform |
| `soc/` | Splunk Docker, add-on |
| `scripts/` | `setup_splunk.py` |
| `guides/` | [Step-by-step](guides/step-by-step.md) |
| `attacks/` | [Stratus Red Team](attacks/README.md) |

Medium blog (link TBD) for deeper walkthroughs.
