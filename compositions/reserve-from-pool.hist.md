---
title: Reserve from Pool — history
nav_exclude: true
---

# Reserve from Pool — history

The dated record of how [Reserve from Pool](./reserve-from-pool.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/reserve-from-pool.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-23 — Rewritten in GRACE lang v0.61; twenty of twenty-two open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration and Logic confinement both — `Primitive policy`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, the prose's *Cross-store consistency under partial failure* becoming the reconciliation it described; invariant numbers 1 through 6 and 8 unchanged, Invariant 7 tombstoned to Composes 5; the checks renumbered `Check 1.1` through `Check 7.2`; `Non-goals` and `Edge cases` split, with `Clock semantics`, `Concurrency` and `Expiry sweep` under the second; the host's mutual exclusion named an *exclusion*, since the grammar owns *section*; and the outcome entries' balances named for what Capacity Constraint Enforcement's events carry now, the opening and closing balance, where the prose still said *Allocated Before* and *Allocated After*. The lines' fixes: the replay declared a bearer answer that attests and journals nothing, since a replay commits nothing and Invariant 8 is about commitment (2026-08-26-e, 2026-08-30-e); Actor Identity's store durability inherited (2026-08-26-f); *bound cryptographically* replaced by Invariant 8's own mechanism-neutral words (2026-08-26-h); the fail-closed check landed as recording-failure carrying outcome, unsettled (2026-08-26-i); no oversell read at quiescence and from the pool's own acceptance, joining no two logs (2026-08-26-j); *attestation* glossed in the Summary (2026-08-26-k); an Action Reference term entry (2026-08-26-l); the digest's exclusion of the actor reference and the credential as rules (2026-08-26-o); validation pinned before the intent against each constituent's own field rules, uncached, the constituents' invalid-request settled after it (2026-08-26-r, 2026-08-30-f); the Terms preamble's count, the idempotency surface declared here rather than deferred, and the Customer Onboarding pointers removed (2026-08-26-t, u, v); the pool leg releasing never more than the open returns, an excess reported (2026-08-30-a); a release reading of unknown, rebuilt as such, and the recovery entries' balances outside the chain (2026-08-30-b); Provisional Commitment's not-known landed as a third position, inconsistency, settled and alerted (2026-08-30-g); the expiry sweep reading not-known as an orphan hold the reconciliation's partial leg resolves (2026-08-30-h); the seam glossed (2026-08-30-k). *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. The two formal lines stay open (2026-08-29-a, 2026-08-30-l). The rewrite also found the reconciliation's partial leg had no way to reach the orphan hold it was told to drive terminal — the hold is unjournaled — and gave it one: the Held commitments no binding names whose resource and requester match the open partial's intent (Reconciliation 30).

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-21, newest first:

- 2026-08-26 authentication-precedence gate — 3 foundational routed (all since closed), 4 foundational and 8 refining/rhetorical corrected in-round, 9 refining routed (3 since closed)
- Final Critique 8's 7 refining and 3 rhetorical also routed
