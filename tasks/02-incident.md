# 02 — Incident

If you are short on time, **this is the task to finish**.

It's **02:10 on Wednesday**. Your phone lights up:

> **Rina (Claims Engineering Lead)** — 02:10
> hey sorry for the late ping 🙏 claim documents haven't been processed since yesterday evening.
> customer support has 40+ complaints already, people uploaded their hospital receipts and nothing
> happens. could it be the database? I saw some slow queries yesterday afternoon.
>
> **Rina** — 02:11
> also... why did nobody get alerted?? we only found out from customers

You're the only person who can deal with this. Everything you can see is in
[`incident/evidence/`](../incident/evidence) plus the repository itself.

## What we want

1. **Find the root cause and fix it in code.** Tell us what you would actually run, in what order, to
   restore service tonight. Include how you'd check it worked and how you'd roll it back if it didn't.
2. **A postmortem** that Rina and management can read: what happened, the impact, the timeline, the root
   cause, why we only found out from customers, and the follow-up actions.
   You'll own every follow-up action yourself, so prioritize them realistically.
3. **Prevention.** Implement at least the follow-up you think is most important, so this class of
   problem is caught before customers notice it.
