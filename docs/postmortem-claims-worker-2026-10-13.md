# Postmortem: claim documents not processed (13-14 Oct 2026)

**Author:** platform engineer. **Written:** 14 Oct 2026.
**Status:** service restoration prepared, pending apply. Action items open.
**Audience:** Claims Engineering (Rina), Customer Support, management.
**Format:** blameless. This document looks at how our system and process allowed the problem, not at who made a change.

All times are WIB (UTC+7) unless noted.

## Summary

From about 17:40 on Tuesday 13 Oct, no claim document uploaded by a customer was processed. The
service that reads uploaded documents (the claims worker) stopped working after a routine
naming cleanup in production. Nobody was alerted. We found out at 01:38 on Wednesday, when Customer
Support reported customers complaining. The service was still down when the platform engineer was
paged at 02:10, about 8.5 hours after it stopped.

No customer data has been lost so far. The uploaded documents are waiting in a queue and will be
processed once the worker runs again. The queue keeps each document for 4 days, so recovery must
finish before then.

## Impact

| Area | Impact |
|---|---|
| Customers | Claims stuck at "documents uploaded" for at least 8.5 hours. 40+ complaints to Customer Support by 01:38 |
| Backlog | 48,213 documents waiting in the queue when the evidence was collected |
| Data | No loss so far. The queue deletes a document 4 days after it was uploaded. **The oldest waiting documents (from about 17:40 on 13 Oct) are deleted from about 17:40 on 17 Oct if they are not processed** |
| Time to detect | About 8 hours (17:43 to 01:38), and customers found it, not our monitoring |
| Time to respond | 32 minutes from the first customer report to the page (01:38 to 02:10). Time to recovery: to be added after the fix is applied |
| Other systems | The database and the claims API were healthy. Only document processing was affected |
| Team | The incident was found by customers, not by monitoring. It was handled by one person at night |

## Timeline

| Time (WIB) | Event |
|---|---|
| Tue 13 Oct, earlier | Monthly report job slows the claims dashboard for a while. It ends by 15:47. This was unrelated, but it later pointed the first investigation at the database |
| 17:38 | A routine cleanup is committed: the claims worker's Kubernetes service account is renamed from `claims-worker` to `claims-worker-sa` to match a naming convention used in another repository |
| 17:40 | The change is applied to production |
| 17:43 | New worker pods start and immediately crash. Each pod stops in under 1 second |
| 17:55 | The first apply timed out. The second apply reports "nothing to change", so the change is assumed to be fine. No step exists that checks the pods after an apply |
| 18:12 | The queue-age alarm goes into `ALARM` (documents older than 15 minutes). The alarm has no notification target, so nobody is told |
| Wed 14 Oct 01:38 | Customer Support reports 40+ tickets from customers |
| 02:10 | The claims lead pages the platform engineer. The claims lead suspects the database |
| 02:10 onward | Investigation. All 30 worker pods are in `CrashLoopBackOff`, with 60 to 98 restarts each |

## Root cause

The worker proves its identity to AWS through its Kubernetes service account. The AWS role it uses
(`claims-worker-prod`) only trusts a service account called `claims-worker`. After the rename, the
pods presented the name `claims-worker-sa`. AWS refused the request (HTTP 403, `AccessDenied`),
the worker could not read from the queue, and it exited.

In short: the name was changed in one place (Kubernetes) and not in the other (AWS), and nothing
told us the two had to match.

## Why it was not the database

The first guess was the database, because of slow queries during the afternoon. The evidence shows
otherwise:

- The slow queries came from the monthly report job and stopped by 15:29 (08:29 UTC).
- The dashboard was fast again at 15:47, two hours before the incident began.
- The worker log shows a successful database connection, followed by the AWS error.

## Contributing factors

1. **No link between the two names.** The service account name lives in the Helm values, and the
   trusted name lives in the Terragrunt/IAM stack. Nothing checks that they agree. The documentation
   (`docs/claims-worker.md`) warned about this, but a warning in a document is easy to miss.
2. **The apply result was trusted without checking.** "Nothing to change" after a timed-out apply looked like success.
   There is no habit or step of checking pod health after an apply.
3. **The alarm was not connected to anyone.** The queue-age alarm worked and fired about 30 minutes after the change,
   but it had no notification target. The need to connect it was known and not done.
4. **No alarm for crashing pods or the dead-letter queue.** Only one alarm existed.
5. **Production applies run from one person's laptop.** There is no review step, no second pair of eyes,
   and no automatic post-deploy check.
6. **Autoscaling amplified the failure.** The queue backlog made autoscaling grow to the maximum of
   30 pods. All 30 crashed repeatedly.

## What went well

- The queue kept every document, and the retention period (4 days) gives us time to recover.
- The alarm itself triggered quickly. Only its notification was missing.
- The evidence collected (logs, pod details, queue and alarm state, git log) was enough to find the cause
  without access to the cluster.

## Where we were lucky

- The failure happened early in the 4-day retention window. If it had gone unnoticed over a long weekend,
  documents could have expired.
- The failure did not affect the database or the customer-facing API.

## Recovery plan

1. Set the production service account name back to `claims-worker` in
   `apps/acme-prod-cluster/values/claims-worker.yaml`. Only the Helm values change; the AWS side is not touched.
2. Preview with `helmfile diff`, then `helmfile apply`.
3. Confirm: pods are `Running` with no new restarts, the worker log has no `AccessDenied`, and the queue
   size and the age of the oldest message are going down.
4. Roll back by reverting the commit if the new pods still fail.

**Risk to watch during recovery:** the backlog (48,213 documents) will be processed in a burst, and
autoscaling can raise the worker count to 30. Each pod opens up to 8 database connections. We will watch
database connections and load, and cap the worker count if needed.

## Action items

I am the owner of all items. Priorities reflect that I am the only platform engineer.

| # | Action | Prevents | Priority | Effort | Target |
|---|---|---|---|---|---|
| 1 | Restore the service account name and verify recovery (above) | Ongoing outage | P0 | 30 min | Tonight |
| 2 | **Done (minimal):** the queue-age alarm now emails an address through SNS when it fires and when it recovers (`alarm_email` in `modules/sqs-queue`). **Next:** post to a Slack channel instead of email | Finding out from customers | P1 | 2 h | Email: in this PR. Slack: this week |
| 3 | Add alarms for crashing pods and for messages in the dead-letter queue | Silent failures | P1 | 2 h | This week |
| 4 | Add a CI check that the service account name in the Helm values matches the IAM stack | This exact failure | P1 | 3 h | This week |
| 5 | Make "check pod health after apply" a written step, and later automate it in CI/CD | Trusting a bad apply | P1 | 1 h | This week |
| 6 | Move the database password out of the plain environment variables (it is visible in `kubectl describe`), then rotate it | Credential exposure | P1 | 4 h | Next week |
| 7 | Limit the worker role to the one queue instead of all queues, pin the image tag, set resource limits, lower the worker concurrency | Larger blast radius | P2 | 1 day | 30 days |
| 8 | Decide the maximum worker count against the database connection limit | Database overload during recovery | P2 | 2 h | 30 days |
| 9 | Move production applies off a laptop into reviewed CI/CD (see task 04) | Unreviewed changes | P2 | Several days | 90 days |

## What we need from the claims team

- Confirm that the OCR step can handle a burst of about 48,000 documents, or tell us the acceptable pace.
- Tell Customer Support that documents are safe and will be processed after recovery, and share the expected time once recovery starts.
- Tell us if any claims have a deadline that cannot wait for the backlog to clear.

## Open questions

- When exactly will the backlog finish? This depends on the recovery speed and database load.
- Did customers re-upload documents during the outage? Duplicate documents may exist in the queue.
- Which Slack channel should receive alerts? The documentation mentions `#claims-alerts`, which was never connected.
