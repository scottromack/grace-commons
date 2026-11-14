---
title: Actor Suspension — history
nav_exclude: true
search_exclude: true
---

# Actor Suspension — history

The dated record of how [Actor Suspension](./actor-suspension.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/actor-suspension.md`.

## Decisions

Entries that record a migration or an editorial rule rather than a turn the pattern took.

- **2026-09-15 — Constituent guarantees are quantified, never counted.** *Chose:* `EVERY` constituent invariant holds over its store, each constituent's own acceptance bar cleared over its own store, and a rule forbidding this spec to count them. *Over:* the prose's per-constituent invariant and check counts. *Because:* every one of those figures had moved since it was written, so the clause asserting that nothing was weakened was itself stale — a number a tool can compute belongs to the tool, and the corpus has now lost the same wager often enough to write the prohibition down.
- **2026-09-15 — Rewritten in GRACE lang v0.41.** *Chose:* 133.6 KB of prose replaced by labelled rules across fifteen families, five invariant numbers unchanged, seven of nine Ledger lines closed by the rewrite. *Over:* a transliteration that would have carried the page's stale counts and its unclosable-member trap into the rule surface. *Because:* a defect the rewrite finds is repaired in the pass that finds it; the two lines that stay open are the formal model's, which is a model change and not a language one.

## Ledger

The gate record the Ledger's `last gate:` line carried behind its latest until 2026-10-20:

- 2026-06-10 — Final Critique 4, fresh reader — clean

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Actor Suspension](./actor-suspension.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 30. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Composition state 31. Execution Contract Database 3 and Execution Contract Database 4 own it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 3. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 5. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 29. Execution Contract Database 2 owns it.
Deleted: Capability requirement 30. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 31. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 32. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to lease.
Deleted: Capability requirement 33. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to lease.
Deleted: Capability requirement 34. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 35. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section for a deployment to lack.
Deleted: Capability requirement 39. Execution Contract Database 3 owns it.
Deleted: Capability requirement 44. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Capability requirement 46. Execution Contract Logic confinement 7 owns it.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 7. Execution Contract Database 1 owns it.
Deleted: Audit arm 9. Execution Contract Database 1 owns it.
Deleted: Audit arm 16. Execution Contract Database 1 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 1. Execution Contract Database 2 owns it.
Deleted: Action wiring 2. Execution Contract Database 2 owns it.
Deleted: Action wiring 3. Execution Contract Database 2 owns it.
Deleted: Action wiring 22. Execution Contract Database 2 owns it.
Deleted: Action wiring 23. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to lose.
Deleted: Action wiring 24. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to find unavailable.
Deleted: Action wiring 33. Execution Contract Database 1 owns it.
Deleted: Action wiring 35. Primitive policy 11 owns it: a credential Credential refuses as invalid-request still stands effective-active, so the act answers invalid-request and commits nothing (Invariant 1.3, Execution Contract Read 4).
Deleted: Action wiring 40. Execution Contract Database 1 owns it.
Deleted: Action wiring 41. Execution Contract Database 1 owns it.
Deleted: Action wiring 42. Execution Contract Database 1 owns it.
Deleted: Action wiring 43. Reconciliation 17 and Execution Contract Database 2 own it.
Deleted: Action wiring 44. Reconciliation 17 and Execution Contract Database 2 own it.
Deleted: Action wiring 46. Reconciliation 16 and Execution Contract Database 2 own it.
Deleted: Action wiring 47. Reconciliation 15 and Execution Contract Database 2 own it.
Deleted: Action wiring 54. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Action wiring 69. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section for [Suspension Report] to take.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 4. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 5. Execution Contract Database 1 owns it.
Deleted: Reconciliation 8. Execution Contract Database 1 owns it.
Deleted: Reconciliation 10. Execution Contract Database 2 owns it.
Deleted: Reconciliation 11. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section for another holder to hold.
Deleted: Reconciliation 12. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, so the sweep skips no candidate.
Deleted: Reconciliation 13. Execution Contract Database 2 owns it.
Deleted: Reconciliation 14. Execution Contract Database 2 owns it.
Deleted: Reconciliation 24. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 30. Execution Contract Database 2 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 3.3. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Check 6.9. Execution Contract Database 1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 7. Execution Contract Database 2 owns it.
Deleted: External check 8. Execution Contract Database 2 owns it.
Deleted: External check 9. Execution Contract Database 3 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 5. Execution Contract Database 1 owns it.
Deleted: Atomic writes 6. Execution Contract Database 1 owns it.
Deleted: Atomic writes 7. Execution Contract Database 1 owns it.
Deleted: Atomic writes 8. Execution Contract Database 1 owns it.
Deleted: Atomic writes 9. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Identity 16, Action wiring 48 and Action wiring 84 own it: intent instant, suspension instant and reinstatement instant are every timestamp this composition stamps, and each takes the injected now.
Deleted: Clock semantics 1. Capability requirement 1 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 8. Composes 31 owns it.
Deleted: Clock semantics 13. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 14. Non-goal 19 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 2 owns it.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Deleted: Concurrency 9. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no serialization obligation for [Suspension Report] to stand outside.
```
