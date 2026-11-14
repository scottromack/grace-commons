---
title: State Machine — history
nav_exclude: true
search_exclude: true
---

# State Machine — history

The dated record of how [State Machine](./state-machine.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/state-machine.md`.

## Decisions

Entries that record a migration or a repair rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the five actions as a signature block, Invariant 1 through 10 keeping their numbers, the declaration's ten well-formedness checks raised to a `Declaration 1 through 17` family of their own, every success effect conditioned on a declared admitted instantiate, admitted fire or admitted history (Hard invariant 16), [Fire]'s seven-step rejection precedence kept beside the rules as an eight-row case space with the ordering carried by `ONLY IF` guards rather than by a prose *rejection priority* line repeated in two sections, the six acceptance areas opened into `Check 1.1 through 8.2` with three `External check`s for what the store cannot answer, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 21` family and four edge-case families (`String`, `Clock semantics`, `Concurrency`, `Atomic writes`), the Composition notes prose raised to `Composition note 1 through 10`. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into state-machine` found nothing in the corpus citing this atom by label. 78.8 KB → 67.0 KB.

- **2026-09-12 — The within-workflow temporal bound is a precedence, not a `≥`.** *Chose:* `Operation 20` — *IF the resolved firing instant precedes the workflow's instantiation instant THEN [Fire] MUST answer invalid-request*. *Over:* `IF fired_at EXCEEDS instantiated_at OR fired_at = instantiated_at`, the two-arm spelling the condition operator set forces on a `≥`. *Because:* that spelling is a watched class at five sites across two specs (council read 29), and this atom would have been the third. A bound that admits its own boundary is a *precedes* prohibition in one arm — the boundary case (a transition firing at the instant of instantiation) is legal, and one arm says so. The class may still earn an operator; it does not need this atom's vote.

- **2026-09-12 — Four propositions had two owners each.** *Chose:* `Invariant 2` owns exactly-one-current-state and the `State` family no longer restates it; `Operation 21` owns *one entry per admitted fire* and `Invariant 5` no longer does; `State 4` owns the history entry's field set and `Invariant 9` no longer does; `Invariant 8.2` owns *the atom does not evaluate a guard* and the `Non-goal` family no longer does. *Over:* keeping each pair for emphasis. *Because:* Authority 3. All four were found by `W-duplicate-proposition`, which is the check earning its keep on the largest atom migrated so far — 192 rules, where a reader cannot hold the whole surface at once and a duplicate is invisible by construction.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [State Machine](./state-machine.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 6. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 11. Execution Contract Logic confinement 10 owns it.
Deleted: Identity 12. Execution Contract Database 7 owns it.
Deleted: Identity 17. Execution Contract Input 2 owns it.
Deleted: Identity 18. Execution Contract Input 2 owns it.
```

### Structure › State

```
Deleted: State 12. Invariant 10.1 and Execution Contract Database 4 own it.
Deleted: State 13. Invariant 10.2 and Execution Contract Database 4 own it.
Deleted: State 14. Execution Contract Database 3 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 6. Execution Contract Conformance 9 owns it.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 8. Execution Contract Input 2 owns it.
```

### Structure › Operations

```
Deleted: Operation 1. Execution Contract Refusal 1 owns it.
Deleted: Operation 62. Execution Contract Input 1 owns it.
Deleted: Operation 65. Execution Contract Input 3 owns it.
Deleted: Operation 74. Execution Contract Input 4 owns it.
Deleted: Operation 12. Execution Contract Refusal 1 owns it.
Deleted: Operation 14. Execution Contract Refusal 1 owns it.
Deleted: Operation 16. Execution Contract Refusal 1 owns it.
Deleted: Operation 18. Execution Contract Refusal 1 owns it.
Deleted: Operation 63. Execution Contract Input 1 owns it, among the firing checks (Term firing check).
Deleted: Operation 27. Execution Contract Database 1 owns it.
Deleted: Operation 32. Operation 15 and Declaration 10 own it.
Deleted: Operation 34. Execution Contract Refusal 1 owns it.
Deleted: Operation 40. Execution Contract Read 6 owns it.
Deleted: Operation 41. Execution Contract Query 3 through 4 own it.
Deleted: Operation 44. Execution Contract Query 5 owns it.
Deleted: Operation 79. Execution Contract Query 5 owns it.
Deleted: Operation 46. Execution Contract Refusal 1 owns it.
Deleted: Operation 51. Capability requirement 1 owns it.
Deleted: Operation 52. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 53. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 54. Execution Contract Logic confinement 3 owns it.
```

### Structure › Invariants › Invariant 10 — Record durability

```
  Deleted: Invariant 10.3. Execution Contract Database 1 owns it.
```

### Structure › The declaration

```
Deleted: Declaration 1. Declaration 5 and Declaration 8 own it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.2. Check 1.1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 4. Execution Contract Conformance 9 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 5. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 5. Non-goal 22 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```

### Edge cases › String policy

```
Deleted: String 7. Execution Contract Logic confinement 13 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns it.
Deleted: Composition note 10. Execution Contract Atom interface 1 owns it.
```
