---
title: Execute Gated Workflow — history
nav_exclude: true
---

# Execute Gated Workflow — history

The dated record of how [Execute Gated Workflow](./execute-gated-workflow.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/execute-gated-workflow.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-24 — Rewritten in GRACE lang v0.62; twenty-eight of thirty open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` (the approval-gated transition, with the consumption and mooting rules), `Reconciliation` (the restart sweep, as four legs), `Scope vocabulary` and `Cascade` (the moot cascade, the family Multi-Party Approval opened) as the surfaces; invariant numbers 1 through 6 and 8 unchanged, Invariant 7 tombstoned to Composes 6; the record checks renumbered by the invariant each tests; the edge cases split into Non-goals and four Edge cases families. Choices the page left open, each decided by a standing rule: one State Machine workflow per run, stated as its own serve rule beside the one State Machine instance (Composes 1 and 17 — Compensable Workflow's shape for the same atom); every constituent write surface reserved to the composition, Permissions read-only (2026-08-26-h, 2026-08-30-b); the marks extraction-pending against Binding Registry, a write-once pairing of a step to the transition that spent it (2026-08-30-d — *A derived index splits at the horizon*); the retention step and invalid-request(step-4) at an outcome read back by the act's minted id and proceeding as landed (2026-08-26-d — *A transcribed rejection arm keeps its payload*); every read-side refusal landed (2026-08-26-b); the audit-completeness count taken from the constituent stores and the start half routed external (2026-08-26-e, 2026-08-30-c); the firing's binding read from its own event (2026-08-26-f); the grant reconstruction pinned to the outcome's payload instant (2026-08-26-g); a lost answer met by reading before re-invoking, and at-most-once left to the caller's key as it is for fire (2026-08-26-i — *make all things mean one thing*); approval staleness a non-goal (2026-08-26-k); the recovery intent renamed with underscores like every other kind here (2026-08-30-a). *Over:* the prose's step lists, a serialization rule titled for one action, and a Standards line claiming the substrate *satisfies* Part 11 where it is the structural form. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-20, newest first:

- 2026-08-27 — authentication-precedence gate, fresh reader — 3 foundational pre-existing routed (all since closed), 8 refining/rhetorical routed
- Final Critique 9's 1 other foundational (since closed), 13 refining (1 since closed) and 4 rhetorical also routed
