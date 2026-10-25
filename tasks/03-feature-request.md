# 03 — Feature request

If you are short on time, finish this after the incident, before polishing 01 or 04.

A message from the claims team:

> **Rina (Claims Engineering Lead)**
> hi! we're redesigning the claim submission flow. customers will upload photos of their KTP and
> hospital receipts/medical documents straight from the app. we need somewhere to store those files,
> in dev first and then prod.
>
> the claims-worker needs to read them for OCR. product wants us to keep them "as long as needed for
> the claim".
>
> also can you make an IAM user with access keys so our backend and our laptop scripts can upload
> directly? like what Budi did for the reports bucket. we'd like to start testing in dev this week 🙏

## What we want

1. **The infrastructure**, as code, consistent with how this repository is organized (or improve that
   organization if you have a good reason, and explain it).
2. **Your reply to Rina**: a message you would actually send her. Say what you built, anything you're
   doing differently from what she asked and why, and what you need from her or from product to finish
   the job.
