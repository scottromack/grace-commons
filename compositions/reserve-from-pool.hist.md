---
title: Reserve from Pool — history
nav_exclude: true
search_exclude: true
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

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Reserve from Pool](./reserve-from-pool.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 5. Execution Contract Database 1 owns it.
Deleted: Composition state 8. Execution Contract Database 1 owns it.
Deleted: Composition state 9. Execution Contract Database 1 owns it.
Deleted: Composition state 12. Execution Contract Database 1 owns it.
Deleted: Composition state 13. Execution Contract Database 1 owns it.
Deleted: Composition state 14. Execution Contract Database 1 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 4. Execution Contract Database 1 owns it.
Deleted: Capability requirement 5. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Capability requirement 6. Execution Contract Database 1 owns it.
Deleted: Capability requirement 7. Execution Contract Database 1 owns it.
Deleted: Capability requirement 8. Execution Contract Database 1 owns it.
Deleted: Capability requirement 9. Execution Contract Database 1 owns it: the composition names no liveness sum for the compensation window to exceed.
Deleted: Capability requirement 10. Execution Contract Database 1 owns it.
Deleted: Capability requirement 11. Execution Contract Database 1 owns it.
Deleted: Capability requirement 12. Execution Contract Database 3 owns it.
Deleted: Capability requirement 13. Execution Contract Database 3 owns it.
Deleted: Capability requirement 14. Execution Contract Database 3 owns it.
Deleted: Capability requirement 16. Execution Contract Database 1 owns it.
Deleted: Capability requirement 18. Execution Contract Database 1 owns it.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it.
Deleted: Capability requirement 22. Execution Contract Database 2 owns it.
Deleted: Capability requirement 23. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 24. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 25. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to lease.
Deleted: Capability requirement 26. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 30. Execution Contract Database 3 owns it.
Deleted: Capability requirement 32. Execution Contract Database 3 owns it.
Deleted: Capability requirement 33. Execution Contract Database 3 owns it.
Deleted: Capability requirement 34. Execution Contract Database 3 owns it.
Deleted: Capability requirement 36. Execution Contract Database 3 owns it.
Deleted: Capability requirement 38. Execution Contract Database 3 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 2. Execution Contract Database 2 owns it.
Deleted: Action wiring 3. Execution Contract Database 2 owns it.
Deleted: Action wiring 4. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Action wiring 16. Execution Contract Database 1 owns it.
Deleted: Action wiring 17. Execution Contract Database 1 owns it.
Deleted: Action wiring 33. Execution Contract Database 2 owns it.
Deleted: Action wiring 34. Execution Contract Database 2 owns it.
Deleted: Action wiring 35. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion for a later write to hold.
Deleted: Action wiring 36. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to lose.
Deleted: Action wiring 37. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to take again.
Deleted: Action wiring 38. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 39. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 40. Execution Contract Database 1 owns it.
Deleted: Action wiring 41. Execution Contract Database 1 owns it.
Deleted: Action wiring 42. Execution Contract Database 1 owns it.
Deleted: Action wiring 43. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 44. Execution Contract Database 1 owns it.
Deleted: Action wiring 57. Execution Contract Database 1 owns it.
Deleted: Action wiring 58. Execution Contract Database 1 owns it.
Deleted: Action wiring 59. Execution Contract Database 1 owns it.
Deleted: Action wiring 60. Execution Contract Database 1 owns it.
Deleted: Action wiring 61. Execution Contract Read 4 owns it: a place hold refusal refuses [Reserve], which writes nothing, its allocate and its reserve intent included.
Deleted: Action wiring 65. Execution Contract Database 1 owns it.
Deleted: Action wiring 66. Execution Contract Database 1 owns it.
Deleted: Action wiring 67. Execution Contract Database 1 owns it.
Deleted: Action wiring 68. Execution Contract Database 1 owns it.
Deleted: Action wiring 69. Execution Contract Database 1 owns it.
Deleted: Action wiring 70. Execution Contract Database 1 owns it.
Deleted: Action wiring 71. Execution Contract Database 1 owns it.
Deleted: Action wiring 72. Execution Contract Database 1 owns it.
Deleted: Action wiring 73. Execution Contract Database 1 owns it.
Deleted: Action wiring 74. Execution Contract Database 1 owns it.
Deleted: Action wiring 75. Execution Contract Database 1 owns it.
Deleted: Action wiring 76. Execution Contract Database 1 owns it.
Deleted: Action wiring 77. Execution Contract Database 1 owns it.
Deleted: Action wiring 83. Execution Contract Read 4 owns it: a recording-failure carrying inconsistency refuses the action, which writes nothing.
Deleted: Action wiring 94. Execution Contract Database 1 owns it.
Deleted: Action wiring 99. Execution Contract Database 1 owns it.
Deleted: Action wiring 100. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 101. Execution Contract Database 1 owns it.
Deleted: Action wiring 102. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 103. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 104. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 105. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 107. Execution Contract Database 1 owns it.
Deleted: Action wiring 108. Execution Contract Database 1 owns it.
Deleted: Action wiring 109. Execution Contract Database 1 owns it.
Deleted: Action wiring 112. Execution Contract Database 1 owns it.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 4. Execution Contract Database 1 owns it.
Deleted: Wiring decision 5. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 2. Execution Contract Database 1 owns it.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Deleted: Reconciliation 4. Execution Contract Database 1 owns it.
Deleted: Reconciliation 5. Execution Contract Database 1 owns it.
Deleted: Reconciliation 6. Execution Contract Database 1 owns it.
Deleted: Reconciliation 7. Execution Contract Database 1 owns it.
Deleted: Reconciliation 8. Execution Contract Database 1 owns it.
Deleted: Reconciliation 9. Execution Contract Database 1 owns it.
Deleted: Reconciliation 10. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Reconciliation 11. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Reconciliation 12. Execution Contract Database 1 owns it.
Deleted: Reconciliation 13. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Reconciliation 14. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Reconciliation 15. Execution Contract Database 1 owns it.
Deleted: Reconciliation 16. Execution Contract Database 1 owns it.
Deleted: Reconciliation 17. Execution Contract Database 1 owns it.
Deleted: Reconciliation 18. Execution Contract Database 1 owns it.
Deleted: Reconciliation 19. Execution Contract Database 1 owns it.
Deleted: Reconciliation 20. Execution Contract Database 1 owns it.
Deleted: Reconciliation 21. Execution Contract Database 1 owns it.
Deleted: Reconciliation 22. Execution Contract Database 1 owns it.
Deleted: Reconciliation 23. Execution Contract Database 1 owns it.
Deleted: Reconciliation 24. Execution Contract Database 1 owns it.
Deleted: Reconciliation 25. Execution Contract Database 1 owns it.
Deleted: Reconciliation 26. Execution Contract Database 1 owns it.
Deleted: Reconciliation 27. Execution Contract Database 1 owns it.
Deleted: Reconciliation 28. Execution Contract Database 1 owns it.
Deleted: Reconciliation 29. Execution Contract Database 1 owns it.
Deleted: Reconciliation 30. Execution Contract Database 1 owns it.
Deleted: Reconciliation 31. Execution Contract Database 1 owns it.
Deleted: Reconciliation 32. Execution Contract Database 1 owns it.
Deleted: Reconciliation 33. Execution Contract Database 1 owns it.
Deleted: Reconciliation 34. Execution Contract Database 1 owns it.
Deleted: Reconciliation 35. Execution Contract Database 1 owns it.
Deleted: Reconciliation 36. Execution Contract Database 1 owns it.
Deleted: Reconciliation 37. Execution Contract Database 1 owns it.
Deleted: Reconciliation 38. Execution Contract Database 1 owns it.
Deleted: Reconciliation 39. Execution Contract Database 1 and Execution Contract Database 2 own it.
```

### Composition-level invariants › Invariant 1 — Allocation coherence

```
  Deleted: Invariant 1.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 1.3. Execution Contract Database 1 owns it.
  Deleted: Invariant 1.4. Execution Contract Database 1 owns it.
```

### Composition-level invariants › Invariant 8 — Authentication precedes commitment

```
  Deleted: Invariant 7. Composes 5 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.5. Execution Contract Database 1 owns it.
Deleted: Check 1.7. Execution Contract Database 1 owns it.
Deleted: Check 3.2. Execution Contract Database 1 owns it.
Deleted: Check 3.3. Execution Contract Database 1 owns it.
Deleted: Check 3.4. Execution Contract Database 1 owns it.
Deleted: Check 3.5. Execution Contract Database 1 owns it.
Deleted: Check 3.6. Execution Contract Database 1 owns it.
Deleted: Check 3.7. Execution Contract Database 1 owns it.
Deleted: Check 3.8. Execution Contract Database 1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 3. Execution Contract Database 1 owns it.
Deleted: External check 4. Execution Contract Database 2 owns it.
Deleted: External check 5. Execution Contract Database 3 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 2. Execution Contract Database 1 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Edge cases › Expiry sweep

```
Deleted: Expiry sweep 2. Execution Contract Database 1 owns it.
Deleted: Expiry sweep 3. Execution Contract Database 1 owns it.
```
