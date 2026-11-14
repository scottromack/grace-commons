---
title: Retention Window — history
nav_exclude: true
search_exclude: true
---

# Retention Window — history

The dated record of how [Retention Window](./retention-window.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/retention-window.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, the refusal order carried by each rule's own condition rather than by the order the rules sit in, the eleven invariant numbers frozen exactly as Audit Trail cites them, Generation acceptance moved ahead of Non-goals as `spec-format.md` requires, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail cites this atom's Invariants 1, 3, 7 and 11 (`tools/grace/cites.py --into retention-window`).

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every retention with its stored fields and, while retained, purge eligible (Operation 29 through 33). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — the retained and purged sets, each retention with its fields, and purge eligibility derived at read time — and the migration dropped it with the section, while Operation 28, Customer Onboarding and Defensible Retention all read the store through it. Restored as the prose had it, not widened. Found beside the same loss in Permissions and Actor Identity, which the cold regeneration of the Attributed Permissions Admin demo surfaced (council read 228).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Retention Window](./retention-window.md) may carry it again.

### Structure › State

```
Deleted: State 1. Invariant 1.1 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 4. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Capability requirement 4a. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Capability requirement 6. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
```

### Structure › Operations

```
Deleted: Operation 6a. Execution Contract Refusal 1 owns it.
Deleted: Operation 8a. Execution Contract Refusal 1 owns it.
Deleted: Operation 9a. Execution Contract Refusal 1 owns it.
Deleted: Operation 10. Execution Contract Database 1 owns it.
Deleted: Operation 19a. Execution Contract Refusal 1 owns it.
Deleted: Operation 22. Operation 13 and Operation 21 own it: [Purge] judges against one injected now per call and stamps purge instant from the injected now.
Deleted: Operation 23. Capability requirement 1 owns it.
Deleted: Operation 24c. Execution Contract Refusal 1 owns it.
Deleted: Operation 25. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 27. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 28. Invariant 11.2 owns it.
Deleted: Operation 33. Operation 29 and Execution Contract Read 2 own it.
Deleted: Operation 34. Execution Contract Read 1 owns it.
Deleted: Operation 35. Execution Contract Refusal 1 owns it.
Deleted: Operation 36. Execution Contract Refusal 1 owns it.
```

### Structure › Invariants › Invariant 6 — Retention window monotonicity

```
  Deleted: Invariant 6.3. Operation 7 and Operation 7a own a duration that does not advance the deadline, and an invariant restating a precondition is a second owner.
```

### Structure › Invariants › Invariant 8 — Purge timestamp consistency

```
  Deleted: Invariant 8.2. Execution Contract Logic confinement 7 owns it.
```

### Structure › Invariants › Invariant 10 — Retention record durability

```
  Deleted: Invariant 10.3. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 6. Execution Contract Conformance 9 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Non-goal 13 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Edge cases › Record divergence

```
Deleted: Record divergence 1. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Record divergence 1a. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Record divergence 2. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Record divergence 2a. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Record divergence 2b. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
```

### Composition notes

```
Deleted: Composition note 3. Simultaneous retention 5 and Simultaneous retention 6a own it: a deployment that places two retentions over one record composes the pattern that owns joint enforcement, and a pattern that owns the destruction owns joint enforcement.
```
