---
title: Shared Todo — history
nav_exclude: true
search_exclude: true
---

# Shared Todo — history

The dated record of how [Shared Todo](./shared-todo.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/shared-todo.md`.

## Decisions

Entries that record a migration, a council read's collapse or a regeneration rather than a turn the pattern took.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except three invariants the Execution Contract already owns.** *Chose:* `Composes` for the three constituents and the two assignments taken up, then `Composition state`, `Scope vocabulary`, `Action wiring`, `Wiring decision` and `Concurrency` as the wiring surfaces, the five surviving invariant numbers unchanged, and an acceptance section distributed from the closing claim the prose already made — *what the actor was allowed to do and who held the task is readable from the records alone*. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. `Wiring decision` reaches two specs with this one, which is the family Undo History minted and the first sign it recurs.
- **2026-09-14 — Three invariants asserting a constituent's invariants hold are one citation.** *Chose:* `Composes 6` — *the composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8* — with `Invariant 6`, `Invariant 7` and `Invariant 8` tombstoned to it. *Over:* keeping the three, which is what the prose carried. *Because:* the contract already settles it — *conformance extends recursively, and no composing layer is obligated to re-verify what the substrate's own conformance already establishes; inheriting a guarantee by reference is the point of naming a substrate* — so three invariants re-asserting it were a citing spec restating a rule it cites (Authority 6), which is council read 53's ruling applied to a second seam. What the three carried *beyond* the blanket survives and is not inherited: the relay of an unchanged constituent rejection is `Composes 9`, and the single-instance decisions that make the constituents' guarantees reachable at all are `Composes 1` through `Composes 3` — which is why `Invariant 2.1` stands where `Invariant 7` fell (council read 55).
- **2026-09-28 — What the cold regeneration met, restored.** *Chose:* the nine signatures back on the page, with Responsible Actor's unassigned and not-known as Action wiring 20 and 21, where the rewrite kept the rules that gate and relay and dropped every action's parameters, answers and refusals, leaving Check 5.1 and 5.2 citing Composition state 2, which states neither answer; visible tasks defined for a caller holding tasks:view, where the term's *none otherwise* read as the empty set Action wiring 19 forbids; and Invariant 5.2 as *a task's delete changes no grant*, with its check moved to External check 5, where Check 4.2 asked an auditor for a grant record keyed on a task id, which no grant carries. *Over:* the 2026-09-14 rewrite's readings. *Because:* each contradicted the page's own rules or the constituents' stores, and the signatures are the prose's projected contracts carried across unchanged. The re-pass is owed.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Shared Todo](./shared-todo.md) may carry it again.

### Composition logic › Action wiring

```
Deleted: Action wiring 11. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 12. Execution Contract Database 1 owns it.
Deleted: Action wiring 22. Execution Contract Database 2 owns it.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 2. Execution Contract Database 1 owns it.
Deleted: Wiring decision 3. Execution Contract Database 1 owns it.
```

### Composition-level invariants › Invariant 5 — Authorization history completeness

```
  Deleted: Invariant 6. Composes 6 owns it.
  Deleted: Invariant 7. Composes 6 owns it.
  Deleted: Invariant 8. Composes 6 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 4.2. External check 5 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 6. Execution Contract Database 2 owns it.
```

### Non-goals

```
Deleted: Non-goal 6. Execution Contract Database 5 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 5. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so a revoke of the grant a gate read commits either before the gate's read or after the action's writes.
Deleted: Concurrency 6. Execution Contract Database 2 owns it.
```

### Composition notes

```
Deleted: Composition note 6. Execution Contract Database 2 owns it.
```
