# Incident evidence

Collected when you were paged at 02:10 WIB (UTC+7) on Wednesday 14 Oct 2026. Kubernetes and
application timestamps are in UTC.

| File | What it is |
|---|---|
| `slack-claims-eng.md` | #claims-eng channel, Tuesday afternoon until now |
| `git-log.txt` | Recent commits on `main` |
| `kubectl-get-pods.txt` | `kubectl -n claims get pods` |
| `kubectl-describe-pod.txt` | `kubectl -n claims describe pod` for one of the pods |
| `claims-worker.log` | `kubectl -n claims logs --previous` for the same pod |
| `sqs-get-queue-attributes.json` | `aws sqs get-queue-attributes --attribute-names All` for `claims-documents` |
| `cloudwatch-describe-alarms.json` | `aws cloudwatch describe-alarms --alarm-name-prefix claims-documents` |
| `db-slow-queries.txt` | Export from the database's slow query log, Tuesday |
