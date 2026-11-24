---
title: Evidence
nav_order: 4
has_children: true
---

# Evidence

The assurance ladder. Every claim in this library is supposed to be checkable, but *checkable* comes in rungs — and each page below is one rung, so a skeptic can enter by whichever door matches how much they distrust us:

| Rung | The question it answers | The door |
|---|---|---|
| It runs | "Is this real software or a paper exercise?" | [Demos](./evidence/demos.md) — live deployments, with generated RECIPEs naming exactly what each is built from |
| You can check it | "Why should I believe your numbers?" | [Verify It Yourself](./evidence/verify.md) — the full evidence chain, re-runnable from a cold clone, negative control included |
| It is continuously checked | "What about next week?" | [Live Status](./evidence/status.md) — the CI gates, rendered from GitHub's record, never hand-written |
| It is enforced | "Which of the grammar's must-reject rules does the checker really hold?" | [What the checker enforces](./evidence/enforcement.md) — each rule, the check that holds it, and what slips through |
| It is quantified | "What does a verified pattern cost?" | [Measurement](./evidence/measurement.md) — the token-cost ledger, platform-sourced, estimates labeled |

The rung this section deliberately does not house: *proved* — the formal models and their rejected twins live with the patterns they verify, in [the corpus](corpus.md), because a proof belongs beside its claim.
