# Security

GuardDuty is on. Findings go to `#security-alerts` through the Lambda in
`modules/guardduty-2slack`.

I tested it with an EC2 SSH brute-force finding and a message showed up. Severity
filter is 4 (MEDIUM and above).

The Slack webhook is in the terragrunt inputs. I know that is not ideal. Moving it
to SSM was on my list.

S3: the reports bucket is used by an IAM user (`claims-reports-uploader`) because the
claims team wanted access keys for laptop scripts. Same pattern if anyone else asks.

I have not turned on bucket encryption or versioning. Default SSE-S3 is probably on
anyway.
