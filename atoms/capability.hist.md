---
title: Capability — history
nav_exclude: true
search_exclude: true
---

# Capability — history

The dated record of how [Capability](./capability.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/capability.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the thirteen invariant numbers and the six acceptance checks unchanged, the derived lapse routed through a declared lapsed and revocable so no rule carries the comparison, the arithmetic in `allocated_at + ttl` moved into a declared expiry deadline (Hard invariant 24), the two things the store cannot clear promoted from prose caveats to `External check 1 through 2`, the two Alloy-confirmed entailments kept as prose beneath the invariants rather than given numbers they never had, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk. The rewrite surfaced one cross-atom fork it does not resolve: a lapsed capability answers [Already Terminal] to [Revoke] while a lapsed [Session](./session.md) accepts one, same mechanic and opposite rulings, neither declaring the other — docketed rather than reconciled, because reconciling it is logic.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
- **2026-09-15 — Clock dependence 1 and 2, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. Both rules keep the words they carried as Clock semantics 4 and 5; only the heading changed.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Capability](./capability.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 8. Invariant 12.1 owns it.
Deleted: Identity 11. Invariant 12.2 owns it.
Deleted: Identity 13. Non-goal 1 owns it.
```

### Structure › State

```
Deleted: State 3. Invariant 10.1 owns it.
Deleted: State 5. Invariant 6.2 owns it.
Deleted: State 8. Invariant 13.1 owns it.
Deleted: State 9. Invariant 13.2 owns it.
Deleted: State 10. Invariant 3.4 owns it.
Deleted: State 14. Non-goal 3 owns it.
```

### Structure › State › Expiry

```
Deleted: Expiry 1. Invariant 13.3 owns it.
Deleted: Expiry 8. Operation 26 owns it.
Deleted: Expiry 9. Operation 38 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Clock dependence 1 owns it.
Deleted: Clock semantics 5. Clock dependence 2 owns it.
Deleted: Clock semantics 6. Non-goal 28 owns it.
```

### Structure › Operations

```
Deleted: Operation 20. Invariant 3.1 owns it.
Deleted: Operation 30. Operation 71 owns it.
Deleted: Operation 34. Execution Contract Database 1 owns it.
Deleted: Operation 45. Execution Contract Database 1 owns it.
Deleted: Operation 49. Execution Contract Database 3 owns it.
Deleted: Operation 55. Capability requirement 1 owns it.
Deleted: Operation 56. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 57. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 61. Execution Contract Input 1 owns it.
Deleted: Operation 62. Execution Contract Read 1 owns it.
Deleted: Operation 64. Execution Contract Read 1 owns it: after the read, every refusal rule of [Allocate] answers invalid-request.
Deleted: Operation 66. Execution Contract Refusal 1 owns it.
Deleted: Operation 67. Execution Contract Input 1 owns it.
```

### Structure › Invariants › Invariant 2 — Redemption counter monotonic

```
  Deleted: Invariant 2.2. Operation 17 owns it.
  Deleted: Invariant 2.4. Operation 71 owns it.
```

### Structure › Invariants › Invariant 4 — Exhaustion atomicity

```
  Deleted: Invariant 4.1. Execution Contract Database 1 owns it.
  Deleted: Invariant 4.2. Execution Contract Database 2 owns it.
  Deleted: Invariant 4.3. Execution Contract Database 2 owns it.
  Deleted: Invariant 4.5. Execution Contract Database 1 and Execution Contract Database 3 own it.
  Deleted: Invariant 4.6. Execution Contract Database 3 owns it.
  Deleted: Invariant 4.7. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 8 — Scope immutability

```
  Deleted: Invariant 8.2. Non-goal 29 owns it.
```

### Structure › Invariants › Invariant 11 — Capability durability over this atom's own surface

```
  Deleted: Invariant 11.3. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 12 — Capability token uniqueness

```
  Deleted: Invariant 12.3. Identity 6 owns it.
```

### Generation acceptance › Conformance checks › External checks

```
Deleted: External check 3. Check 1.2 owns it.
```

### Non-goals

```
Deleted: Non-goal 4. Composition note 2 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it: the counter's read and write are one transaction, and the atom names no rule left for a compare-and-set to discharge.
```

### Edge cases › String policy

```
Deleted: String 8. Execution Contract Logic confinement 13 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Capability requirement 9 owns it.
Deleted: Composition note 7. Execution Contract Atom interface 1 owns it.
```
