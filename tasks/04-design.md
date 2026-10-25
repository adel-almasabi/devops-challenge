# 04 — Design: getting the platform off one laptop

If you are short on time, **notes in the PR are enough**. Do not start a new toolchain.

Today, infrastructure (`live/`, via Terragrunt) and cluster apps (`apps/`, via helmfile) are applied
from an engineer's laptop: Budi's before, and now yours. There's also
`.github/workflows/apply.yml`, which Budi started and nobody really uses.

Management has asked for two things:

> 1. "Deployments must not depend on one person's laptop."
> 2. "The regulator (OJK) will ask who changed production, when, and who approved it. We need to be
>    able to answer."

Constraints: you are the only platform engineer, product engineers will keep shipping changes to this
repo, and the budget for new tools is small.

## What we want

A design document, **two pages at most**, covering:

- How a change gets from a pull request into production, for both infrastructure and cluster apps.
- How AWS access works for humans and for automation.
- What you would deliberately **not** do (yet), and why.
- How you'd roll this out step by step without blocking the business.

Optional: implement a first step.
