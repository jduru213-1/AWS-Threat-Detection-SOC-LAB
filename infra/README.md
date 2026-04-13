# Infra

This folder creates and tears down the AWS side of the lab.

## AWS credentials and permissions

`build.sh` / Terraform use the **same credential chain** as the AWS CLI (`aws sts get-caller-identity` must work). They do **not** prompt for keys.

The caller needs **broad permissions** to create IAM, S3, SQS, SNS, CloudTrail, VPC Flow Logs, and related resources. Restricted users often see **`AccessDenied`** during apply. For a sandbox lab, **`AdministratorAccess`** on an IAM user in a test account is the usual approach. Match **region** to `aws configure` (or `AWS_REGION`) and to what you want in `variables.tf` / `aws_region`.

## Recommended way

- Build: `./build.sh`
- Destroy: `./destroy.sh`

These scripts are the easiest path because they include prompts, checks, and safer defaults.

`build.sh` verifies the **`splunk-sdk`** Python package is importable (same interpreter as `python`), because `scripts/setup_splunk.py` needs it for indexes. Install with `pip install splunk-sdk` before running the build if you have not already. For a machine that only runs Terraform and never Splunk setup, you can set **`SOC_LAB_SKIP_SPLUNK_SDK_CHECK=1`**.

## What gets created

- S3 buckets for telemetry
- CloudTrail and VPC Flow Logs integrations
- IAM user for Splunk ingestion
- IAM user for Stratus simulation
- Optional SQS resources for S3-to-Splunk ingestion
- Optional EC2 "Stratus target" instance so adversary techniques have something to manipulate

## Raw Terraform (manual option)

If you prefer to run Terraform commands directly:

### 1. Use a saved AWS profile (recommended)
```bash
cd infra
export AWS_PROFILE=soc-lab-admin
export AWS_REGION=us-east-1
```
### 2. Confirm credentials are valid
```
aws sts get-caller-identity
```
### 3. Build
```
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```
### 4. Teardown later
```
terraform destroy
```

Use raw Terraform only if you want full manual control.
