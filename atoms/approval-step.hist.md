---
title: Approval Step — history
nav_exclude: true
search_exclude: true
---

# Approval Step — history

The dated record of how [Approval Step](./approval-step.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/approval-step.md`.

## Decisions

Entries that record a migration or a repair rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the five actions as a signature block, Invariant 1 through 10 keeping their numbers, every success effect conditioned on a declared admitted submit, admitted resolve or admitted read (Hard invariant 16), the six-step rejection precedence — repeated verbatim in four places in the prose, once per resolving action and once in the state table — collapsed to one seven-row case space with the ordering carried by `ONLY IF` guards, the three resolving actions unified under declared resolving action, deciding reference and decision instant terms so [Approve], [Reject] and [Withdraw] state their shared guards once instead of three times, the six acceptance areas opened into `Check 1.1 through 6.3` with four `External check`s, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 20` family and five edge-case families (`String`, `Clock semantics`, `Concurrency`, `Atomic writes`, `Indeterminate outcome`). *Over:* the prose spec. *Because:* the migration plan; `cites.py --into approval-step` found nothing citing this atom by label. 81.1 KB → 62.7 KB.

- **2026-09-12 — Three propositions had two owners each.** *Chose:* `Invariant 2.1` owns membership exclusivity and the `State` family no longer restates it; `Operation 8` owns *an admitted submit stands the step in pending*; `Identity 12` owns *the atom does not confirm a subject reference*. *Over:* keeping each pair. *Because:* Authority 3, and all three were found by `W-duplicate-proposition` rather than by reading — the same pattern as State Machine, where the duplicates a 169-rule surface hides are exactly the ones no reader finds.

- **2026-09-12 — A cross-spec citation was written in the local form.** *Chose:* `Selective Disclosure Invariant 5.1`, the qualified form Hard invariant 28 declares. *Over:* `[Selective Disclosure](./selective-disclosure.md) states as its \`Invariant 5\``, which reads as a citation of *this* spec's Invariant 5 — submitter exclusivity, an unrelated rule. *Because:* the citation-aim audit resolved it against the local registry and the aim was wrong. Nothing enforces the qualified form, and a census over the corpus returns 24 candidates of which nearly all are local citations that merely sit near a spec link — so the class is docketed rather than instrumented.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Approval Step](./approval-step.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 6. Execution Contract Logic confinement 10 owns it.
Deleted: Identity 7. Execution Contract Database 7 owns it.
Deleted: Identity 14. Execution Contract Logic confinement 13 owns it.
```

### Structure › State

```
Deleted: State 1. Invariant 3.1 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. State 15 owns it.
Deleted: Clock semantics 5. Non-goal 21 owns it.
```

### Structure › Operations

```
Deleted: Operation 59. Execution Contract Input 1 owns it.
Deleted: Operation 12. Execution Contract Refusal 1 owns it.
Deleted: Operation 14. Execution Contract Refusal 1 owns it.
Deleted: Operation 60. Execution Contract Input 1 owns it, among the attribution checks (Term attribution check).
Deleted: Operation 23. Execution Contract Refusal 1 owns it.
Deleted: Operation 31. Execution Contract Database 1 owns it.
Deleted: Operation 35. Execution Contract Refusal 1 owns it.
Deleted: Operation 43. Execution Contract Query 3 and Operation 41 own it: a step carrying no instant on a range filter's axis fails the filter.
Deleted: Operation 49. Capability requirement 1 owns it.
Deleted: Operation 50. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 51. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 52. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 53. Execution Contract Read 1 owns it.
Deleted: Operation 54. Execution Contract Read 1 owns it: after the read, every refusal rule of [Submit] answers invalid-request.
Deleted: Operation 55. Execution Contract Refusal 1 and Operation 20 own it.
Deleted: Operation 56. Execution Contract Read 1 owns it: after the read, every refusal rule of [Read] answers invalid-query.
```

### Structure › Invariants › Invariant 10 — Record durability

```
  Deleted: Invariant 10.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 10.3. Execution Contract Database 3 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 1. Execution Contract Database 3 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Edge cases › Indeterminate outcome

```
Deleted: Indeterminate outcome 2. Execution Contract Error model 1 owns it.
Deleted: Indeterminate outcome 3. Execution Contract Error model 1 owns it.
```

### Edge cases › String policy

```
Deleted: String 7. Execution Contract Logic confinement 13 owns it.
```

### Composition notes

```
Deleted: Composition note 11. Execution Contract Atom interface 1 owns it.
```
