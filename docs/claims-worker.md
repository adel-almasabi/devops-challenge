# Claims worker

Consumes `claims-documents` (prod) / `claims-documents-dev`. Each message is a claim
document that needs OCR.

- Chart: `charts/service`
- Values: `apps/acme-*/values/claims-worker.yaml`
- IAM: `live/.../claims/*/claims-worker-iam`
- Queue: `live/.../claims/*/claims-documents-queue`

Service account must be `claims-worker`. The IRSA role trust policy is bound to that
name. Do not rename it without changing the IAM stack.

KEDA scales on queue depth. `identityOwner: operator` means KEDA's operator role is
what talks to SQS for the scaler (not the worker's role).

Alarms: `claims-documents-oldest-message-age`. I meant to point this at #claims-alerts
and never did. The alarm exists; nothing is subscribed.

## Image tags

Dev is pinned. Prod uses `latest` so the claims team can ship without asking me to
bump a tag. They push to ECR and restart the deployment.
