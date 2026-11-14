---
title: Legal Hold — history
nav_exclude: true
search_exclude: true
---

# Legal Hold — history

The dated record of how [Legal Hold](./legal-hold.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/legal-hold.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the three actions as a signature block, the read's filter axes and malformed-query grounds as rules rather than a paragraph, the eight invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan, and this atom completes [Defensible Retention](../compositions/defensible-retention.md)'s constituent set with [Retention Window](./retention-window.md) and [Audit Trail](../compositions/audit-trail.md).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Legal Hold](./legal-hold.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 6. Execution Contract Logic confinement 10 owns it.
```

### Structure › State

```
Deleted: State 6. Invariant 3.2 owns the absent re-activation.
Deleted: State 9. Non-goal 9 owns the case lifecycle.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Non-goal 17 owns it.
```

### Structure › Operations

```
Deleted: Operation 9. Execution Contract Logic confinement 12 owns it.
Deleted: Operation 18a. Execution Contract Logic confinement 12 owns it.
Deleted: Operation 22. Execution Contract Database 3 owns it.
Deleted: Operation 32. Execution Contract Query 3 and Operation 23 own it.
Deleted: Operation 33. Execution Contract Query 3 and Operation 23 own it.
Deleted: Operation 35. Capability requirement 1 owns it.
Deleted: Operation 36. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 37. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 42. Execution Contract Refusal 1 owns it.
```

### Structure › Invariants › Invariant 8 — Hold record durability

```
  Deleted: Invariant 8.3. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 7.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 5. Execution Contract Conformance 9 owns it.
```

### Non-goals

```
Deleted: Non-goal 16. Execution Contract Database 4 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```
