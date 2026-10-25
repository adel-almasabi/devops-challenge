# Platform architecture

_Last updated: March 2025 — Budi_

## Overview

- One AWS account (`acme`), region `ap-southeast-3`.
- Two EKS clusters: `acme-dev` and `acme-prod`.
- Nodes are provisioned by **Karpenter**.
- Applications are deployed by **ArgoCD**, which watches `apps/`.
- Secrets are encrypted with **SOPS** (see `.sops.yaml`) and decrypted by helm-secrets at deploy time.

## Terraform

- All infrastructure lives in `live/` and is applied with Terragrunt.
- State is stored in S3 (`acme-terraform-state-<account-id>`), with locking in DynamoDB.
- Changes are applied by `.github/workflows/apply.yml` after the PR is approved.

## Access

- Engineers use their own IAM users with MFA.
- Product teams request access through the #platform channel.

## Monitoring

- CloudWatch alarms for queues and databases page the on-call engineer through PagerDuty.
- GuardDuty findings are posted to #security-alerts.

## TODO

- [ ] Runbooks
- [ ] Backups for claims-db
- [ ] Separate prod account
