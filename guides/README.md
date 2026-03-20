# 📚 Guides

| Step | Link | What |
|------|------|------|
| 1 | [Docker Splunk](step-by-step.md#1-docker-splunk) | Start Splunk |
| 2 | [Indexes](step-by-step.md#2-indexes) | Create aws_cloudtrail, aws_config, aws_vpcflow |
| 3 | [AWS add-on](step-by-step.md#3-aws-add-on) | Install from Splunkbase |
| 4 | [Build AWS](step-by-step.md#4-build-aws) | `.\build.ps1` |
| 5 | [Ingestion](step-by-step.md#5-data-ingestion) | Add-on inputs, verify |
| 6 | [Red team](step-by-step.md#6-red-team-stratus) | Stratus / simulation |
| 7 | [Detections](step-by-step.md#7-detections--dashboard) | Searches, dashboard |

Teardown: `infra` → `.\destroy.ps1` (use build credentials, not Stratus).
