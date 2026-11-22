Task 2

root couse

2026-10-13T19:08:41.934Z ERROR sqs: ReceiveMessage failed: WebIdentityErr: failed to retrieve credentials
caused by: AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity
	status code: 403, request id: 7f1c2e9a-4b3d-4e8f-a1c6-2d9b5e7f0a3c
    
**Dimas** — 17:40
small cleanup: renamed the claims-worker service account to `claims-worker-sa` so it matches the
`<app>-sa` naming we use in the payments repo. applying to prod now

commit 8f3c2a1e6d9b7c4a5f0e1d2c3b4a59687f6e5d4c
Author: Dimas Pratama <dimas@acme-insure.example>
Date:   Tue Oct 13 17:38:52 2026 +0700

    chore(claims-worker): rename service account to follow <app>-sa convention

 apps/acme-prod-cluster/values/claims-worker.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

clue from read docs /docs/claims-worker.md

on apps/acme-prod-cluster/values
 serviceAccount:
  name: claims-worker-sa
  roleArn: arn:aws:iam::111111111111:role/claims-worker-prod

    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Tue, 13 Oct 2026 19:08:41 +0000
      Finished:     Tue, 13 Oct 2026 19:08:42 +0000

but on live/acme/ap-southeast-3/claims/prod/claims-worker-iam
inputs = {
  name              = "claims-worker-prod"
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  namespace         = "claims"
  service_account   = "claims-worker"

alarm
      "AlarmActions": [],
      
      "StateReason": "Threshold Crossed: 3 out of the last 3 datapoints [1621.0 (13/10/26 11:05:00), 1322.0 (13/10/26 11:00:00), 1019.0 (13/10/26 10:55:00)] were greater than the threshold (900.0) (minimum 3 datapoints for OK -> ALARM transition).",
      "StateUpdatedTimestamp": "2026-10-13T11:12:00.000Z",