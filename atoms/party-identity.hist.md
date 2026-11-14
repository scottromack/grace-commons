---
title: Party Identity — history
nav_exclude: true
search_exclude: true
---

# Party Identity — history

The dated record of how [Party Identity](./party-identity.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/party-identity.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-13 — Insertion order is authoritative and a recorded instant is advisory, stated as its own rule family.** *Chose:* an `Ordering` family, with Ordering 4 and Ordering 5 forbidding a reading or a reconstruction from turning on an instant. *Over:* the prose's paragraph saying the same thing beside the state machine. *Because:* Operation 18's *most recent suspend* is the atom's central guarantee and it is decidable two ways, one of which is unsound — under clock skew a later event can carry an earlier instant, and two readers would then disagree about whether a party may be reinstated. A rule family is what makes the sound reading the one a generator implements.
- **2026-09-13 — Invariant 9 and Invariant 10 are tombstoned; Identity owns assigned id stability and uniqueness.** *Chose:* Identity 6 through 9 as the single owners. *Over:* keeping the invariants, which restated them. *Because:* Authority 3. Checked before removing: the corpus cites Party Identity Invariants 1, 4, 5 and 11 — from [Customer Onboarding](../compositions/customer-onboarding.md) and the coverage matrix — and cites neither 9 nor 10, so the tombstones break no citation.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Party Identity](./party-identity.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 17. Execution Contract Database 7 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 3. Execution Contract Database 2 owns it.
Deleted: Capability requirement 4. Execution Contract Database 3 owns it.
Deleted: Capability requirement 5. Execution Contract Database 1 owns it.
Deleted: Capability requirement 6. Execution Contract Logic confinement 13 owns it.
Deleted: Capability requirement 8. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 9. Execution Contract Logic confinement 7 owns it.
```

### Structure › Operations

```
Deleted: Operation 17. Execution Contract Refusal 1 owns it.
Deleted: Operation 19. Execution Contract Refusal 1 owns it.
Deleted: Operation 20. Execution Contract Refusal 1 owns it.
Deleted: Operation 28. Operation 37 owns it.
Deleted: Operation 38. Execution Contract Database 1 owns it.
Deleted: Operation 40. Execution Contract Refusal 1 owns it.
Deleted: Operation 57. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 58. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 59. Operation 6, Operation 24 and Operation 34 own it.
```

### Structure › Invariants › Invariant 1 — Party record permanence

```
  Deleted: Invariant 1.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 1.3. Invariant 1.1 and Execution Contract Database 4 own it.
```

### Structure › Invariants › Invariant 7 — Enrollment fields are immutable under the atom's actions

```
  Deleted: Invariant 7.1. Non-goal 3 owns it.
```

### Structure › Invariants › Invariant 8 — No transition is silent

```
  Deleted: Invariant 9. Identity 6 owns assigned id stability.
  Deleted: Invariant 10. Identity 7, Identity 8 and Identity 9 own assigned id uniqueness.
```

### Structure › Invariants › Invariant 11 — Action atomicity

```
  Deleted: Invariant 11.1. Execution Contract Database 1 owns it.
  Deleted: Invariant 11.2. Execution Contract Database 1 and Execution Contract Database 3 own it.
```

### Structure › Ordering

```
Deleted: Ordering 1. Execution Contract Order 1 owns it.
Deleted: Ordering 2. Execution Contract Order 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.2. Ordering 3 and Ordering 4 own it.
Deleted: Check 4.1. Check 5.1 owns it.
Deleted: Check 6.1. Execution Contract Database 6 owns it.
Deleted: Check 6.2. Execution Contract Database 6 owns it.
Deleted: Check 6.3. Execution Contract Database 6 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 3. Non-goal 12 and Composition note 8 own it.
Deleted: External check 9. Execution Contract Database 6 owns it.
Deleted: External check 10. Execution Contract Database 6 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 7 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Edge cases › Indeterminate outcome

```
Deleted: Indeterminate outcome 2. Execution Contract Error model 1 owns it.
```

### Edge cases › String policy

```
Deleted: String 8. String 7 and GRACE-lang Closed vocabulary 29 own it.
```

### Composition notes

```
Deleted: Composition note 9. Composition note 8 owns it.
Deleted: Composition note 10. Composition note 8 owns it.
```
