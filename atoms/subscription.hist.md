---
title: Subscription — history
nav_exclude: true
search_exclude: true
---

# Subscription — history

The dated record of how [Subscription](./subscription.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/subscription.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the nine invariant numbers unchanged, Generation acceptance as conformance checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan; this atom carries no cross-spec citations, so the rewrite is free of frozen-number risk.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Subscription](./subscription.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
```

### Structure › State

```
Deleted: State 6. Invariant 2.2 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
```

### Structure › Operations

```
Deleted: Operation 15. Execution Contract Database 3 owns it.
Deleted: Operation 21. Term event scope owns it.
Deleted: Operation 26. Capability requirement 1 owns it.
Deleted: Operation 27. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 28. Execution Contract Logic confinement 3 owns it.
```

### Structure › Invariants › Invariant 2 — Status monotonicity

```
  Deleted: Invariant 2.1. State 1 owns it.
```

### Structure › Invariants › Invariant 3 — Cancellation is terminal

```
  Deleted: Invariant 3.1. Operation 10 owns it.
  Deleted: Invariant 3.2. Operation 20 owns it.
```

### Structure › Invariants › Invariant 8 — Absence means not-subscribed

```
  Deleted: Invariant 8.2. Operation 20 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 1. Execution Contract Conformance 9 owns it.
```

### Edge cases › Atomicity of a cancel

```
Deleted: Cancel atomicity 1. Execution Contract Database 1 owns it.
Deleted: Cancel atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Cancel atomicity 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
```

### Edge cases › The pair race

```
Deleted: Pair race 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Pair race 2. Execution Contract Database 2 owns it.
Deleted: Pair race 3. Execution Contract Database 2 owns it: the pair check and the write are one transaction, and the atom names no rule left for a uniqueness constraint to discharge.
```

### Composition notes

```
Deleted: Composition note 1. Capability requirement 8 owns it.
Deleted: Composition note 3a. Lost ledger 2 owns it.
Deleted: Composition note 3b. Lost ledger 3 owns it.
Deleted: Composition note 4. Non-goal 12 owns it.
```
