---
title: Permissions — history
nav_exclude: true
search_exclude: true
---

# Permissions — history

The dated record of how [Permissions](./permissions.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/permissions.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the three actions as a signature block, the string policy as its own rule family, the ten invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan, and this atom completes [Shared Todo](../compositions/shared-todo.md)'s constituent set — Personal Todo, Assignment and Permissions all migrated, which makes that composition the one with no inherited term collision to resolve.

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every grant with its stored fields (Operation 26 through 29). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — "the current set of grants", each with its fields — and the migration dropped it with the section, while Deprovisioning 2, Check 1.1, Attributed Permissions Admin and Actor Suspension all read the store through it. Restored as the prose had it, not widened: no filter, so a composing pattern filters in its own code. Found by the cold regeneration of the Attributed Permissions Admin demo (council read 228).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Permissions](./permissions.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Invariant 5.1 owns it.
```

### Structure › State

```
Deleted: State 6. Invariant 2.2 owns it.
Deleted: State 7. Invariant 10.1 owns durability.
Deleted: State 8. Non-goal 1 owns it.
Deleted: State 9. Non-goal 3 owns it.
Deleted: State 10. Non-goal 6 owns it.
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
Deleted: Operation 8. Execution Contract Database 1 owns it.
Deleted: Operation 12. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Operation 14. Execution Contract Database 3 owns it.
Deleted: Operation 19. Operation 16 and Execution Contract Read 2 own it.
Deleted: Operation 23. Capability requirement 1 owns it.
Deleted: Operation 24. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 25. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 29. Operation 26 and Execution Contract Read 2 own it.
Deleted: Operation 30. Execution Contract Read 1 owns it.
Deleted: Operation 31. Execution Contract Read 1 owns it: after the read, every refusal rule of [Grant] before the write answers invalid-request.
Deleted: Operation 32. Execution Contract Refusal 1 owns it.
```

### Structure › Invariants › Invariant 2 — Status monotonicity

```
  Deleted: Invariant 2.1. State 1 owns it.
```

### Structure › Invariants › Invariant 3 — Revocation is terminal

```
  Deleted: Invariant 3.1. Operation 10 owns it.
```

### Structure › Invariants › Invariant 10 — Grant record durability

```
  Deleted: Invariant 10.2. Invariant 10.1 owns it (Execution Contract Database 6).
  Deleted: Invariant 10.3. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 5. Execution Contract Conformance 9 owns it.
Deleted: External check 4. Execution Contract Database 2 owns it.
```

### Edge cases › Deprovisioning a subject

```
Deleted: Deprovisioning 1. Identity 8 owns one revoke reaching one grant.
```

### Edge cases › Grant concurrency and revoke concurrency

```
Deleted: Revoke concurrency 1. Execution Contract Database 2 owns it.
Deleted: Revoke concurrency 2. Execution Contract Database 2 owns it.
```

### Edge cases › Revoke persistence failure

```
Deleted: Revoke persistence 1. Operation 15 owns it.
```
