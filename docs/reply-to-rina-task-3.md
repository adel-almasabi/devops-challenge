# Reply to Rina (task 03)

> Message I would send to Rina in #claims-eng.

Hi Rina! Thanks for the details. Here is where I am with the claim documents storage.

**What I built (in code, dev first)**
- A private S3 bucket for the KTP and hospital/medical documents: `acme-claims-documents-dev`.
  No public access, encrypted by default (AWS-managed), HTTPS only, and Terraform cannot delete it by accident.
  Old versions of a file are removed after 30 days. Files in dev expire after 30 days, so please only use
  fake documents in dev.
- The claims-worker can read from the bucket for OCR. It can only read files (`GetObject`), nothing else.
- Your backend gets its own role that can only upload files to the bucket. There is no key to store.
  The role is written but **switched off** until you confirm the service account name (question 2), because the
  role only trusts that exact name.

Nothing is applied yet. I will apply to dev once I have your answers to questions 2 and 3 below.
Prod comes after you have tested dev.

**What I am doing differently from your request**
- **No IAM user with access keys.** Access keys never expire, and a key on a laptop or in a script that can reach
  customer KTP and medical documents is a real risk. The same pattern was used for the reports bucket, and
  GuardDuty has findings of unusual access to it from an outside IP address (see my question 5).
  Instead:
  - The backend uploads with its own role.
  - The mobile app uploads with a short-lived upload link that the backend creates for each file.
  - For test scripts on a laptop in dev, we can use temporary credentials that expire after a few hours.
    Tell me who needs this and I will set it up.
- **No retention period yet.** "As long as needed for the claim" is not something I can turn into a number, and these
  documents are personal data, so they should not be kept forever. Right now the bucket keeps files until someone
  deletes them.

**What I need from you or product**
1. How long must we keep the documents after a claim is closed? Please confirm with whoever owns compliance
   (OJK and personal data rules).
2. Which service and namespace in the cluster does the uploading? I assumed the namespace `claims` and the
   service account `claims-api`. If the name is different, the upload will be denied, so please check it.
3. Does the app upload straight to S3 with an upload link, or send the file through the backend?
4. Which file types and what maximum size should we allow?
5. Does anyone use the existing `claims-reports-uploader` keys? I want to rotate them, and I need to know what
   would stop working.

Thanks!
