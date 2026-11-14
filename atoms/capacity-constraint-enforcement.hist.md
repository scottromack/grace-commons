---
title: Capacity Constraint Enforcement — history
nav_exclude: true
search_exclude: true
---

# Capacity Constraint Enforcement — history

The dated record of how [Capacity Constraint Enforcement](./capacity-constraint-enforcement.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/capacity-constraint-enforcement.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.36; nothing but language changed.** *Chose:* the eight actions as a signature block, the fourteen invariant numbers unchanged, the six acceptance areas opened into `Check 1.1 through 6.1` with three External checks for what the store cannot answer, the arithmetic routed through declared requested total and released total so no rule carries a sum, the three host obligations Invariant 4 rests on given their own families (`Concurrency`, `Crash atomicity`, `Arithmetic`). *Over:* the prose spec. *Because:* the migration plan; nothing cites this atom by label. The open question this atom was picked to answer — whether a domain whose logic *is* arithmetic survives Hard invariant 24 — answers yes: `MUST NOT EXCEED` and `EXCEEDS` carry every comparison directly, and only the two sums needed names.

## Migration notes

- **2026-09-15 — Clock dependence 1 and 2, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. Both rules keep the words they carried as Clock semantics 4 and 5; only the heading changed.
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Capacity Constraint Enforcement](./capacity-constraint-enforcement.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 6. Execution Contract Logic confinement 3 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 4. Clock dependence 1 owns it.
Deleted: Clock semantics 5. Clock dependence 2 owns it.
Deleted: Clock semantics 6. Non-goal 29 owns it.
```

### Structure › Operations

```
Deleted: Operation 14. Execution Contract Refusal 1 owns it.
Deleted: Operation 55. Operation 51 and Execution Contract Read 1 own it.
Deleted: Operation 56. Execution Contract Read 1 owns it.
Deleted: Operation 60. Execution Contract Refusal 1 owns it.
Deleted: Operation 61. Capability requirement 1 owns it.
Deleted: Operation 62. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 63. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 64. Clock dependence 1 owns it.
```

### Structure › Invariants › Invariant 1 — Pool record permanence under this atom's actions

```
  Deleted: Invariant 1.3. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 14 — Action atomicity

```
  Deleted: Invariant 14.1. Execution Contract Database 1 owns it.
  Deleted: Invariant 14.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 14.3. Execution Contract Database 1 owns it: an action's writes commit together or not at all, and the atom names no host obligation left for the commit to rest on.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.1. Execution Contract Database 6 owns it.
Deleted: Check 5.2. Execution Contract Database 6 owns it.
Deleted: Check 5.3. Execution Contract Database 6 owns it.
Deleted: Check 5.4. Execution Contract Database 6 owns it.
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › Conformance checks › External checks

```
Deleted: External check 4. Execution Contract Conformance 9 owns it.
Deleted: External check 5. Execution Contract Database 6 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it: the arithmetic guard and the write are one transaction, and the atom names no rule left for a compare-and-set to discharge.
```

### Edge cases › String policy

```
Deleted: String 3. Execution Contract Input 2 owns it, and Term actor reference cap supplies the default.
```

### Edge cases › Crash atomicity

```
Deleted: Crash atomicity 1. Execution Contract Database 1 owns it.
Deleted: Crash atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Crash atomicity 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Crash atomicity 5. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Crash atomicity 4. Execution Contract Database 3 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns it.
Deleted: Composition note 8. Execution Contract Atom interface 1 owns it.
```
