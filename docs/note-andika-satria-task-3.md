Task 3

need development for storing object
On the existing reports bucket and its IAM user (claims-reports-uploader)
- The IAM user policy allows `s3:*` (every S3 action) on the whole bucket.
- The policy has no conditions, so the access keys work from any IP address (no source IP allowlist).
- The bucket does not require HTTPS and does not block public access.
- The access keys never expire.


question from Rina
also can you make an IAM user with access keys so our backend and our laptop scripts can upload directly? like what Budi did for the reports bucket. we'd like to start testing in dev this week

`docs/security.md` says "Same pattern if anyone else asks", so the unsafe pattern is meant to be repeated.
The GuardDuty sample findings in `modules/guardduty-2slack/events/` show the same IAM user in use from the same
unknown IP address (198.51.100.77): `iam-anomalous-behavior.json` (10 Oct 01:05 UTC, severity 5) and
`s3-anomalous-exfiltration.json` (9 Oct 22:40 UTC, severity 8).

"title": "Unusual discovery API calls by IAM user claims-reports-uploader.",
    "description": "APIs commonly used to discover resources (ListBuckets, GetBucketPolicy, ListUsers) were invoked by claims-reports-uploader in an unusual way."

-----------------------------------------------------

    "title": "Anomalous S3 data access by IAM user claims-reports-uploader.",
    "description": "An IAM entity invoked an S3 API in a suspicious way. GetObject was called 18,422 times on acme-claims-reports-prod from an unusual location.",

          "remoteIpDetails": { "ipAddressV4": "198.51.100.77", "country": { "countryName": "Unknown" } }


Decision: reject the request for an IAM user with access keys. An IP allowlist would reduce the risk but not remove it,
because the keys are still long-lived. Use IRSA for the backend and short-lived credentials for laptop scripts.

Decision: keep the backend upload role disabled
(`live/acme/ap-southeast-3/claims/dev/claims-api-iam/terragrunt.hcl.disabled`)
until Rina confirms the backend service account name. A wrong name does not fail at apply; the upload would fail
later with AccessDenied.

Built so far:
- `modules/s3-bucket` hardened: public access block, HTTPS only, no ACLs, `force_destroy` off, cleanup of old versions
  and unfinished uploads. Encryption stays on the AWS default (SSE-S3). KMS is a later step.
- Impact on prod: `reports-bucket` uses the same module, so the next plan for it will show these changes. Review it before applying.
- Dev bucket `acme-claims-documents-dev` (`live/.../claims/dev/claims-documents-bucket`), with versioning on and test files expiring after 30 days.
- Dev read access for the claims-worker: `s3:GetObject` on this bucket only.
- Reply to Rina: `docs/reply-to-rina-task-3.md`.

Not done: prod bucket and permissions (after dev is tested), retention period (waiting for Rina and compliance).


