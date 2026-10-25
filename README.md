# Qoala — Platform Engineer take-home

This is Qoala’s hiring exercise for a **sole-owner** platform / DevOps engineer. The company
in the tasks (“Acme Insure”) is fictional; the stack matches how we work.

**Do not open a pull request against this repository.** Fork it, work on **your** fork, and
email the recruiter your fork URL when you are done. A PR opened here will be closed.

---

# Acme Insure — Platform Engineer Challenge

Welcome, and thanks for taking the time to do this.

## The situation

Acme Insure is a (fictional) digital insurance company in Indonesia. Customers buy policies and file
claims through a mobile app; partners integrate through APIs. Everything runs on AWS in
`ap-southeast-3` (Jakarta).

You have just joined as **the only platform/DevOps engineer**. The previous engineer, Budi, left two
weeks ago. There was no handover. Product engineers have write access to this repo and sometimes
change things themselves. Nobody else in the company knows how the infrastructure works — from today,
you own it.

This repository is everything Budi left behind.

## What we want from you

There are four tasks in [`tasks/`](./tasks). Read all of them before you start.

| If time runs out | Task | What it's about |
|---|---|---|
| 3rd — short list is enough | [01 — Take over the platform](./tasks/01-takeover.md) | Understand what you inherited and decide what matters |
| 1st — finish this | [02 — Incident](./tasks/02-incident.md) | Something is broken in production right now |
| 2nd | [03 — Feature request](./tasks/03-feature-request.md) | A product team needs something from you |
| last — notes are enough | [04 — Design](./tasks/04-design.md) | Get the platform off one person's laptop |

**We expect about 5 hours of focused work**, taken within about a week. That is not enough to
finish every task perfectly, and that is intentional. In this role nobody will prioritize for you,
so deciding what to do, what to do well, and what to leave for later is part of what we assess.

If time runs out: **finish 02, then 03, then a short 01 list. Leave 04 as notes.** A rushed
complete set scores lower than a deep partial. Tell us what you skipped and why.

Please tell us honestly how long you spent. More hours do not earn a higher score.

## Ground rules

- **No AWS account is needed.** Nothing here is deployed. Everything can be checked locally (see
  below). If you want to go further — LocalStack, a local `kind` cluster, anything — that's your call.
- **The requirements are incomplete on purpose.** That's what real requests look like. When something
  is unclear, make a reasonable assumption and write it down. If something genuinely blocks you, you
  may email the recruiter one set of questions; we'll answer within one business day.
- **AI tools are allowed.** Tell us where and how you used them. In the follow-up interview we will go
  through your work together and ask you to explain and change it, so make sure you understand
  everything you submit.
- **Everything here is fake**: account IDs, URLs, credentials, people. Don't worry about "leaking" anything.
- Your fork of this repo will be **public** (GitHub does not allow private forks of public repos).
  Do not put real credentials, customer data, or anything from another employer in it.

## How to start and submit

### 1. Fork this repository

On this page, click **Fork** (top right). Keep **Copy the `main` branch only** checked. Create the
fork under **your** GitHub account.

Do **not** use “Use this template”. Do **not** clone this repo directly and push somewhere else
unless the recruiter asked you to.

### 2. Clone **your** fork

```bash
git clone https://github.com/<your-username>/devops-challenge.git
cd devops-challenge
```

If `git remote -v` shows someone else’s account as `origin`, you cloned the wrong repo. Delete it
and clone your fork.

### 3. Work on a branch

```bash
git checkout -b submission
```

Use more branches if you want. Commit as you would at work.

### 4. Push to **your** fork

```bash
git push -u origin submission
```

### 5. Open a pull request **on your fork** (not here)

GitHub’s “Contribute” / “Open pull request” button on a fork defaults to sending the PR **here**.
That is the wrong PR. Close it if you already opened one.

Do this instead:

1. Open **your** fork: `https://github.com/<your-username>/devops-challenge`
2. Click **Pull requests** → **New pull request**
3. Click **compare across forks**
4. Set **base repository** to `<your-username>/devops-challenge` and **base** to `main`
5. Set **compare** to your `submission` branch
6. Fill in the PR template. Do not merge.

If the base repository is `adel-almasabi/devops-challenge` (or any account that is not yours), you
are opening a PR against the brief. Stop and fix the base.

### 6. Email the recruiter

Reply to the recruiter with:

- the URL of **your fork** (`https://github.com/<your-username>/devops-challenge`)
- the URL of the pull request **on that fork**

Anything that isn’t code — notes, plans, postmortems, designs — goes in Markdown files in the repo,
in the PR description, or both. Where it goes is up to you.

## Repository map

```text
live/                      Terragrunt live config: account > region > business unit > env > stack
  terragrunt.hcl           Root config (provider, remote state, common inputs)
  acme/ap-southeast-3/
    platform/{dev,prod}/   VPC, EKS, security tooling
    claims/{dev,prod}/     Claims team resources
modules/                   Internal Terraform modules used by live/
apps/                      helmfile config per EKS cluster
charts/service/            Generic Helm chart used by internal services
incident/evidence/         Material for task 02
docs/                      Whatever documentation Budi left
.github/workflows/         CI and deployment workflows
```

## Local tooling

You don't need all of these; use what you need.

| Tool | Used for |
|---|---|
| Terraform >= 1.7 (see `.terraform-version`) | `terraform validate`, `terraform test` (modules use `mock_provider`, no AWS needed) |
| Terragrunt | Reading/structuring `live/` (you won't be able to `plan` without AWS) |
| tflint, checkov | Linting / static security checks |
| Helm 3, helmfile, kubeconform | Rendering and validating Kubernetes manifests |
| Node.js 22 | `modules/guardduty-2slack` Lambda tests |

The CI workflow in [`.github/workflows/ci.yml`](./.github/workflows/ci.yml) runs the same checks on
pull requests. On your fork, GitHub Actions must be enabled (Actions tab → “I understand my workflows,
go ahead and enable them”) if you want CI to run. That is optional.

Good luck — we're looking forward to reading your work.
