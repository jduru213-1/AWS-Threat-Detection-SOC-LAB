# Step-by-step

Skip steps you’ve already done. For more depth, see the project’s Medium blog.

---

## Requirements

Docker Desktop · Python 3.10+ · AWS account · PowerShell · `aws configure` (so build doesn’t keep prompting)

---

## 1. Docker Splunk

```bash
cd soc
docker compose up -d
```

Open https://localhost:8000 — login `admin`, password in `soc/.env` or compose default. Start/stop via Docker Desktop.

---

## 2. Indexes

```bash
pip install splunk-sdk
python ./scripts/setup_splunk.py
```

Confirm **Settings → Indexes**: `aws_cloudtrail`, `aws_config`, `aws_vpcflow`.

---

## 3. AWS add-on

1. Download [Splunk Add-on for AWS](https://splunkbase.splunk.com/app/1876/)
2. Splunk → **Apps → Manage Apps → Install app from file** → upload → restart

Inputs come in Step 5.

---

## 4. Build AWS

```powershell
cd infra
.\build.ps1
```

Confirm with `yes`. **Save from output:** bucket names, `soc-lab-splunk-addon` access key + secret.

- Credentials: `aws configure` to stop repeated prompts.
- Blocked script: `powershell -ExecutionPolicy Bypass -File .\build.ps1`

---

## 5. Data ingestion

1. Add-on **Configuration → AWS Account** — paste Splunk IAM keys from Step 4.
2. **Inputs → Create New Input** — three S3 inputs:

| Type | Bucket (from build) | Index |
|------|---------------------|--------|
| CloudTrail | cloudtrail bucket | `aws_cloudtrail` |
| Config | config bucket | `aws_config` |
| VPC Flow Logs | vpcflow bucket | `aws_vpcflow` |

Use plain S3 inputs (no SQS). If add-on shows SQS errors, leave Assume Role blank and use S3-only.

Verify: `index=aws_cloudtrail earliest=-30m` (and `aws_config`, `aws_vpcflow`). Wait and retry if empty.

---

## 6. Red team (Stratus)

Use [attacks/README.md](attacks/README.md): `cd attacks` → `.\configure-stratus.ps1` → `stratus list --platform aws` and `stratus detonate <id> --cleanup`. Events show in CloudTrail → Splunk.

---

## 7. Detections / dashboard

Example Splunk searches:

- Failed console login: `index=aws_cloudtrail eventName=ConsoleLogin errorMessage=*`
- IAM user created: `index=aws_cloudtrail eventName=CreateUser`
- Security group change: `index=aws_cloudtrail eventName=AuthorizeSecurityGroupIngress OR RevokeSecurityGroupIngress`

**Dashboard:** Splunk → Dashboards → Create; add panels from saved searches (event counts, timeline, failed logins).

---

## Cleanup

```powershell
cd infra
.\destroy.ps1
```

Use **build credentials** (not Stratus). Confirm with `yes`.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Script blocked | `powershell -ExecutionPolicy Bypass -File .\build.ps1` |
| SQS / add-on errors | Use plain S3 inputs; clear Assume Role in AWS Account config |
| Destroy fails (AccessDenied) | Run destroy in a terminal where you haven’t set Stratus profile; use same creds as build |
