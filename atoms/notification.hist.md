---
title: Notification — history
nav_exclude: true
search_exclude: true
---

# Notification — history

The dated record of how [Notification](./notification.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/notification.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the six actions as a signature block, the three terminal transitions sharing one declared term and one precondition pair, the nine invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into notification` prints nothing, so no number is frozen from outside, and this atom completes [Notification Fanout](../compositions/notification-fanout.md)'s constituent set with [Subscription](./subscription.md).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Notification](./notification.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Non-goal 16 owns it.
```

### Structure › Operations

```
Deleted: Operation 21. Execution Contract Read 5 owns it.
Deleted: Operation 24. Capability requirement 1 owns it.
Deleted: Operation 25. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 26. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 27. Execution Contract Read 1 owns it.
Deleted: Operation 28. Execution Contract Read 1 owns it: after the read, every refusal rule of [Create] answers invalid-request.
Deleted: Operation 29. Execution Contract Refusal 1 owns it.
Deleted: Operation 30. Execution Contract Input 4 owns it.
```

### Structure › Invariants › Invariant 2 — Status monotonicity

```
  Deleted: Invariant 2.1. State 1 owns it.
```

### Structure › Invariants › Invariant 3 — Terminal states are exclusive

```
  Deleted: Invariant 3.2. State 6 owns it.
```

### Structure › Invariants › Invariant 4 — Terminal timestamps match status

```
  Deleted: Invariant 4.1. State 3 owns it.
  Deleted: Invariant 4.3. State 4 owns it.
  Deleted: Invariant 4.5. State 5 owns it.
```

### Structure › Invariants › Invariant 5 — Id stability

```
  Deleted: Invariant 5.2. Invariant 1.1 owns it.
```

### Structure › Invariants › Invariant 7 — Pending query excludes terminals

```
  Deleted: Invariant 7.1. Operation 20 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 5. Execution Contract Conformance 9 owns it.
```

### Non-goals

```
Deleted: Non-goal 7. Execution Contract Read 5 owns it.
```

### Edge cases › String policy

```
Deleted: String 5. GRACE-lang Term blank owns it.
```

### Edge cases › Atomicity of a terminal transition

```
Deleted: Terminal atomicity 1. Execution Contract Database 1 owns it.
Deleted: Terminal atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Terminal atomicity 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Terminal atomicity 4. Execution Contract Database 2 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Capability requirement 7 owns it.
Deleted: Composition note 2. Capability requirement 8 owns it.
Deleted: Composition note 7. Operation 14b owns it.
```
