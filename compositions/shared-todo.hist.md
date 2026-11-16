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

- **2026-09-14 — Two constituent assignments are declined, and the declining is written down.** *Chose:* `Non-goal 4` and `Non-goal 12` to state the refusals, with `Composition note 2` and `Composition note 3` restating them as obligations on the deployment. *Over:* silence, which is what a composition usually offers for a note it does not take. *Because:* [Assignment](../atoms/assignment.md)'s `Composition note 4` and [Permissions](../atoms/permissions.md)'s `Composition note 3` both say *a composing pattern MUST own* — so a composition that neither owns nor names a receiver leaves an obligation falling between two layers with no rule anywhere naming who holds it. Passing an assignment down with the receiver named is the most a composition can do with one it does not want, and the corpus has no form for it (council read 55).

- **2026-09-28 — What the cold regeneration met, restored.** *Chose:* the nine signatures back on the page, with Responsible Actor's unassigned and not-known as Action wiring 20 and 21, where the rewrite kept the rules that gate and relay and dropped every action's parameters, answers and refusals, leaving Check 5.1 and 5.2 citing Composition state 2, which states neither answer; visible tasks defined for a caller holding tasks:view, where the term's *none otherwise* read as the empty set Action wiring 19 forbids; and Invariant 5.2 as *a task's delete changes no grant*, with its check moved to External check 5, where Check 4.2 asked an auditor for a grant record keyed on a task id, which no grant carries. *Over:* the 2026-09-14 rewrite's readings. *Because:* each contradicted the page's own rules or the constituents' stores, and the signatures are the prose's projected contracts carried across unchanged. The re-pass is owed.

- **2026-10-20 — Undo History retired, and an undo is the store's history.** *Chose:* Non-goal 6, a deployment needing an undo composing Undo History, tombstoned to Execution Contract Store 5; rules 99 to 98. *Over:* an undo through a composition that replayed an event log of the list's actions. *Because:* the maintainer ruled 2026-10-20 that Undo History retires: Store 5 keeps every committed version of a record readable, so an undone deletion comes back with its id, timestamps and description. The composition itself still offers no undo (Non-goal 5). What the composition does for its domain is unchanged.

- **2026-10-21 — The store's guarantees cited, not restated, and a delete's recall and deletion one transaction.** *Chose:* the store supplied under Execution Contract Store 1 and Execution Contract Store 2 (Capability requirement 1), and the eleven rules that restated it, or existed only for a store that could split a write, tombstoned to their owner — to Store 1, under which a delete's recall and the task's deletion commit together: the bar on wrapping the two in one transaction, the recalled assignment left standing beside a task whose delete failed (Wiring decision 2, 3) and the bar on calling Personal Todo's delete after the recall answered storage-failure (Action wiring 12); and to Store 2, under which an action's guard reads and the writes they decide are one transaction: the host's serialization of two calls naming one task id and of two description writes, with the deployment's supply of it and its external check (Concurrency 1, 6, Composition note 6, External check 6), the answers it left the loser of two assigns and of two deletes (Concurrency 2, 3), a delete's second recall after the first answered not-active (Action wiring 22) and the bar on checking permitted again inside a call (Concurrency 5); with them the delete calls Personal Todo's delete once the recall answers ok rather than once the recall commits (Action wiring 10); rules 98 to 88. *Over:* a recall and a delete committed apart, recall first, so that a delete that failed left an over-recall rather than a dangling assignment, with the host serializing calls by task id and a grant revoked mid-call left to the deployment — the prose spec's design, which the GRACE rewrite carried as Wiring decision 2 and 3 and the Concurrency rules, and Final Critique 7 and 8 extended with Action wiring 22 and Concurrency 6. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included: Personal Todo's, Permissions' and Assignment's records are one store, so a delete's recall and its deletion commit together or not at all, and a delete that stops leaves neither an over-recall nor a dangling assignment. Store 2 reads the state an action's guards decide on — the permitted answer, the task's existence, its active assignment, the active set's descriptions — inside the transaction that writes the action's effects, so two calls on one task, two description writes and a reassign beside a delete are serialized for every deployment, and a revoke of a grant the gate read commits before the read or after the action's writes. The other calls a rule decided: Wiring decision 1 stays as the cascade's positive rule and the order of its calls inside the one transaction, Action wiring 11 still answers a recall's storage-failure, and Concurrency 4 still checks permitted at a call's start; the responsibility and grant histories are Assignment's and Permissions' own records with their own instants, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.

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
