---
title: Assignment — history
nav_exclude: true
search_exclude: true
---

# Assignment — history

The dated record of how [Assignment](./assignment.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/assignment.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the five actions as a signature block, the refusal order carried by each rule's own condition, the ten invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into assignment` prints nothing, so no number is frozen from outside.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Assignment](./assignment.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Invariant 6.1 owns it.
Deleted: Identity 8. Invariant 6.1 owns it.
```

### Structure › State

```
Deleted: State 8. Invariant 4.1 owns it.
Deleted: State 9. Invariant 4.2 owns it.
Deleted: State 10. Invariant 10.1 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. State 13 owns it.
```

### Structure › Operations

```
Deleted: Operation 20. Execution Contract Database 1 owns it.
Deleted: Operation 23. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Operation 24. Execution Contract Read 4 and Execution Contract Database 3 own it: a refused call writes nothing, and a write that did not commit leaves nothing.
Deleted: Operation 30a. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 31. Capability requirement 1 owns it.
Deleted: Operation 32. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 33. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 34. Execution Contract Read 1 owns it.
Deleted: Operation 35. Execution Contract Refusal 1 owns it.
Deleted: Operation 36. Execution Contract Refusal 1 owns it.
Deleted: Operation 37. Execution Contract Refusal 1 owns it.
```

### Structure › Invariants › Invariant 3 — Status monotonicity

```
  Deleted: Invariant 3.1. State 1 owns it.
```

### Structure › Invariants › Invariant 5 — Id stability

```
  Deleted: Invariant 5.2. Invariant 2.1 owns it.
```

### Structure › Invariants › Invariant 7 — Reassign atomicity

```
  Deleted: Invariant 7.1. Operation 18, Operation 19 and Invariant 1.1 own it: a landed reassign leaves the task reference one active assignment, the one the reassign recorded, and a later recall may leave none.
  Deleted: Invariant 7.3. Execution Contract Database 1 owns it.
  Deleted: Invariant 7.4. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 9 — Complete responsibility history

```
  Deleted: Invariant 9.3. State 3 and State 4 own it: an ended holding carries its recall instant or its transfer instant, and an active one has not ended.
```

### Structure › Invariants › Invariant 10 — Assignment record durability

```
  Deleted: Invariant 10.2. Invariant 10.1 owns it (Execution Contract Database 6).
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 4. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: External check 5. Execution Contract Conformance 9 owns it.
```

### Edge cases › Reassign atomicity

```
Deleted: Reassign atomicity 1. Execution Contract Database 1 owns it.
Deleted: Reassign atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reassign atomicity 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reassign atomicity 4. Execution Contract Database 1 owns it.
```

### Edge cases › The assign race

```
Deleted: Assign race 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Assign race 2. Execution Contract Database 2 owns it.
Deleted: Assign race 3. Execution Contract Database 2 owns it.
```

### Composition notes

```
Deleted: Composition note 2. Term task reference owns it: the host owns what a task is.
```
