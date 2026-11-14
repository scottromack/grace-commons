---
title: Message Preference — history
nav_exclude: true
search_exclude: true
---

# Message Preference — history

The dated record of how [Message Preference](./message-preference.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/message-preference.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the five actions as a signature block, the ten invariant numbers unchanged and Timestamp ordering kept outside them as its own label family, the six acceptance checks renumbered only into `Check N.k`, the case space kept beside the rules as a table, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk.

## Migration notes

- **2026-09-15 — Clock dependence 1 and 2, moved from Operation.** Whether a guard's decision may depend on the clock reading, and under what condition. Both rules stood under `Operation` until council read 75 swept the corpus by rule text rather than by family name; neither word changed.
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Message Preference](./message-preference.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 11. Execution Contract Logic confinement 13 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 5. State 11 and State 12 own it: one injected now stamps both instants of a supersession.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 4. Capability requirement 5 owns it.
```

### Structure › Operations

```
Deleted: Operation 6. State 4 owns it: an empty channel preferences map EQUALS blank.
Deleted: Operation 7. State 4 owns it: an empty channel preferences map EQUALS blank.
Deleted: Operation 9. Execution Contract Refusal 1 owns it.
Deleted: Operation 15. Execution Contract Database 1 owns it.
Deleted: Operation 30. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Operation 39. Capability requirement 1 owns it.
Deleted: Operation 40. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 41. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 42. Clock dependence 1 owns it.
Deleted: Operation 43. Clock dependence 2 owns it.
```

### Structure › Invariants › Invariant 2 — Status monotonicity

```
  Deleted: Invariant 2.1. State 1 owns it.
  Deleted: Invariant 2.2. State 1 and Invariant 2.3 own it.
```

### Structure › Invariants › Invariant 4 — Supersession atomicity

```
  Deleted: Invariant 4.1. Execution Contract Database 1 owns it.
  Deleted: Invariant 4.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 4.3. Execution Contract Database 1 and Execution Contract Database 3 own it.
  Deleted: Invariant 4.4. Execution Contract Database 1 and Execution Contract Database 3 own it.
```

### Structure › Invariants › Invariant 5 — Channel preferences reference declared channels, and the proof is on the record

```
  Deleted: Invariant 5.2. Check 5.1 owns it.
```

### Structure › Invariants › Invariant 6 — Suspension is value-preserving

```
  Deleted: Invariant 6.2. Operation 21 owns it.
```

### Structure › Invariants › Invariant 8 — No id reuse

```
  Deleted: Invariant 8.1. Instance 2 owns it: the rule ranges over one database instance.
```

### Structure › Invariants › Invariant 9 — Record durability over this atom's own surface

```
  Deleted: Invariant 9.2. State 17 and Execution Contract Database 4 own it.
```

### Structure › Invariants › Invariant 10 — Validation-context self-containment

```
  Deleted: Invariant 10.3. Check 5.1 owns it: a conformance check reads the records alone.
```

### Structure › Invariants › Temporal property — Timestamp ordering

```
  Deleted: Temporal property 4. State 11 and State 12 own it: one injected now stamps both instants of a supersession.
  Deleted: Temporal property 5. Execution Contract Logic confinement 7 owns it: the deployment owns the clock's guarantees, the implementation none of them.
```

### Structure › Database instance model

```
Deleted: Instance 1. Execution Contract Database 7 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 4.1. State 11 and State 12 own it: one injected now stamps both instants of a supersession.
Deleted: Check 4.2. State 11 and State 12 own it: one injected now stamps both instants of a supersession.
Deleted: Check 4.3. Capability requirement 5 owns it; a deployment obligation is not an auditor's check.
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
Deleted: Check 6.2. Capability requirement 7 owns it; a deployment obligation is not an auditor's check.
```

### Generation acceptance › External checks

```
Deleted: External check 1. Execution Contract Conformance 9 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 1 owns it.
```

### Edge cases › Supersession atomicity

```
Deleted: Supersession atomicity 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Supersession atomicity 2. Execution Contract Database 2 owns it.
Deleted: Supersession atomicity 3. Execution Contract Database 2 owns it.
Deleted: Supersession atomicity 4. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Supersession atomicity 5. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Supersession atomicity 6. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Supersession atomicity 7. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Supersession atomicity 8. Execution Contract Database 3 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Capability requirement 10 owns it.
Deleted: Composition note 13. Channel set evolution 1 owns it: the declared channel set and its change history are the deployment's.
```
