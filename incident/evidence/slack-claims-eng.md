# #claims-eng — Tuesday 13 Oct 2026

**Rina** — 14:22
anyone else seeing the claims dashboard being slow? some queries taking 5-6 seconds

**Dimas** — 14:31
yeah the monthly report job is running, it does a big scan on claim_documents. should be done by 15:30

**Rina** — 15:47
dashboard is fast again 👍

**Dimas** — 17:40
small cleanup: renamed the claims-worker service account to `claims-worker-sa` so it matches the
`<app>-sa` naming we use in the payments repo. applying to prod now

**Dimas** — 17:55
first `helmfile apply` timed out (my VPN has been flaky today), ran it again and it said there was
nothing to change, so I guess it went through ✅

**Dimas** — 17:56
heading home, see you tomorrow

---

# #claims-eng — Wednesday 14 Oct 2026

**Ayu (Customer Support)** — 01:38
hi team, we have 40+ tickets since last night from customers saying their claim is stuck at
"documents uploaded" 😟 is something down?

**Rina** — 02:10
@platform can you take a look? see DM
