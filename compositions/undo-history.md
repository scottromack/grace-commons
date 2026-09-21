---
title: Undo History
parent: Conceptual Compositions
nav_order: 1
has_toc: true
toc: true
---

# Undo History

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Undo History combines two simpler patterns — a single-user task list ([Personal Todo](../atoms/personal-todo.md)) and an add-only record of everything that happens ([Event Log](../atoms/event-log.md)) — to give the task list a familiar undo that neither part has on its own.

The trick is that the list's current state is not stored. It is recomputed by replaying the recorded history of actions and skipping any that have been undone. Every action a user takes appends an event; an undo appends an event marking the most recent action as skipped; replaying the adjusted history produces exactly the state the user expects.

Combining the two produces a guarantee neither has alone: undoing a deletion brings the task back with its original identifier, timestamps and description intact, rather than as a brand-new task.

This is the building block for any single-user surface where people expect undo to work and a recoverable history is wanted as a side effect.

---

## Intent

The user expects to take back the last thing they did. Personal Todo does not provide that — each action is committed and there is no undo surface. Event Log records faithfully and acts on nothing.

This composition wires the two together. Every action against Personal Todo is recorded in an Event Log instance the composition owns, and an [Undo] action consults the log, finds the most recent forward action not already undone, and adjusts the derived state to be what it would have been had that action never happened.

The composition is event-sourced: the state is defined by replaying the log rather than stored. Forward actions append events, undo appends compensating events, replay produces the current state. Neither atom's spec changes. The composition is the wiring.

---

## Composes

- **[Personal Todo](../atoms/personal-todo.md)** — the state machine the replayed state takes the shape of.
- **[Event Log](../atoms/event-log.md)** — the durable, append-only record of every action, one instance per Personal Todo.

```
Composes 1: EXACTLY ONE Personal Todo shape MUST serve the composition.
Composes 2: EXACTLY ONE Event Log instance MUST serve the composition.
Composes 3: The composition MUST derive the Personal Todo state from the event log instance.
Composes 4: The composition MUST NOT store the derived state as a truth.
Composes 5: The composition MUST NOT call a Personal Todo action that reverses a transition.
Composes 6: The composition MUST NOT change a constituent's spec.
Composes 7: The composition MUST replace Personal Todo's own caller surface.
```

Term composition: this pattern's wiring of [Personal Todo](../atoms/personal-todo.md) and [Event Log](../atoms/event-log.md) — the actions below, the event schemas and the replay.

Term constituents: [Personal Todo](../atoms/personal-todo.md), [Event Log](../atoms/event-log.md).

Term event log instance: the one [Event Log](../atoms/event-log.md) instance the composition owns for one Personal Todo shape; the composition's sole truth.

Term derived state: the Personal Todo shape the replay produces — a derived index by construction, regenerable from the event log instance and never a second truth.

Term unit: one task in the derived state, named by an id as [Personal Todo](../atoms/personal-todo.md)'s identity model declares it.

Term seam: the composition's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects a new unit's id here.

WHY:
Composes 4 and Composes 5 are the whole composition stated twice, from the storage side and from the call side. The log is the truth and the state is a projection, so an undo is a re-derivation rather than a reversal — and the constituent is never asked to move a unit from done back to pending, which is a transition Personal Todo's own spec forbids. The composition operates one level down, at the log, where the atom only ever sees forward valid actions during replay.

Composes 7 is what makes the first six enforceable. If callers could still reach Personal Todo directly, an action could change the state without appending an event and the log would stop being the truth — Invariant 1.1 would fail silently, and the failure would be invisible until someone undid something.

---

## Composition logic

### Composition state

The composition's one state is the derived state the replay builds from the log, and it is a derived index: the log is the sole truth and the replay is the named rebuild procedure (the section titled Composition state in `execution-contract.md`; Replay 15 through 17).

#### Replay

```
Replay 1: The replay MUST read EVERY event of the event log instance in sequence number order.
Replay 2: The replay MUST build the undone set from EVERY undo event.
Replay 3: The replay MUST skip an undo event.
Replay 4: The replay MUST skip an event whose event id IS IN the undone set.
Replay 5: The replay MUST apply a surviving event to the derived state under construction.
Replay 6: The replay MUST introduce a unit at the add event's id in pending.
Replay 7: The replay MUST record the add event's recorded at as the unit's added at.
Replay 8: The replay MUST record the add event's description on the unit.
Replay 9: The replay MUST replace the unit's description with the edit event's new description.
Replay 10: The replay MUST record the edit event's recorded at as the unit's last edited at.
Replay 11: The replay MUST move the unit at the complete event's id to done.
Replay 12: The replay MUST record the complete event's recorded at as the unit's completed at.
Replay 13: The replay MUST remove the unit at the delete event's id from the derived state.
Replay 14: The replay MUST produce one derived state PER event log instance.
Replay 15: The implementation MAY materialize the derived state.
Replay 16: The implementation MUST rebuild a materialized derived state on a miss.
Replay 17: An auditor MUST NOT read a materialized derived state in preference to a fresh replay.
```

Term replay: the named rebuild procedure Replay 1 through 13 state — the composition's only route from the event log instance to the derived state.

Term surviving event: a forward event whose event id IS NOT IN the undone set.

WHY:
Replay 5 rests on something worth stating: a surviving event was recorded only because its action succeeded, so Personal Todo's preconditions held when it was written and hold again at every replay step. The replay never has to validate — it is re-running a history that was valid when it happened. Event Log Invariant 5 is what bounds the replay to exactly that set.

Replay 15 through 17 are the contract classification stated as rules (the section titled Composition state in `execution-contract.md`). The derived state is a derived index by construction: the log is the sole truth, Replay 1 through 13 *are* the named rebuild, and nothing is stored that the rebuild does not regenerate. So the Contract's three obligations hold trivially — the projection sits outside any atomicity surface, since there is no second truth-bearing write to coordinate with the append; a lost materialization is a rebuild trigger and never data loss; and no consistency claim attaches beyond the replay's own determinism. A cache is permitted and is an ordinary derived index; Replay 17 is what stops an invariant being evaluated against one.

### Action wiring

```
add(description)
  answers id
  refuses invalid-description | duplicate-active | storage-failure

edit(id, new_description)
  answers ok
  refuses not-known | not-editable | invalid-description | duplicate-active | storage-failure

complete(id)
  answers ok
  refuses not-known | not-pending | storage-failure

delete(id)
  answers ok
  refuses not-known | storage-failure

undo()
  answers undone_event_type
  refuses nothing-to-undo | storage-failure

read_history(query)
  answers the matching events
  refuses invalid-query
```

```
Action wiring 1: A forward action MUST validate the call against Personal Todo's precondition for the action.
Action wiring 2: A forward action MUST validate the call against the derived state.
Action wiring 3: IF Personal Todo's precondition fails THEN a forward action MUST answer the precondition's rejection.
Action wiring 4: A forward action MUST append the action's event ONLY IF EVERY precondition passes.
Action wiring 5: IF Event Log answers storage-failure THEN an action MUST answer storage-failure.
Action wiring 6: A refused action MUST NOT change the derived state.
Action wiring 7: An admitted action MUST recompute the derived state PER the replay.
Action wiring 8: An admitted add MUST record the id the seam supplies.
Action wiring 9: The composition MUST NOT generate an id.
Action wiring 10: An admitted add MUST answer the id.
Action wiring 11: A no-op edit MUST NOT append an event.
Action wiring 12: A no-op edit MUST NOT record a prior description.
Action wiring 13: A no-op edit MUST NOT change the derived state.
Action wiring 14: A no-op edit MUST answer ok.
Action wiring 15: An admitted undo MUST target the undo target.
Action wiring 16: IF no undo target EXISTS THEN [Undo] MUST answer nothing-to-undo.
Action wiring 17: An admitted undo MUST append an undo event naming the undo target's event id.
Action wiring 18: An admitted undo MUST answer the undo target's event type.
Action wiring 19: [Undo] MUST NOT target an undo event.
Action wiring 20: [Read History] MUST answer Event Log's read for the query.
Action wiring 21: [Read History] MUST NOT change the derived state.
```

Term forward action: [Add] | [Edit] | [Complete] | [Delete] — every action appending a forward event.

Term no-op edit: an [Edit] whose normalized new description equals the unit's current description — an accepted write of nothing, as [Personal Todo](../atoms/personal-todo.md) declares it.

Term undone set: the undone event id of every undo event in the event log instance.

Term undo target: the most recent forward event whose event id IS NOT IN the undone set.

Term admitted add: an [Add] call whose preconditions pass and whose append commits.

Term admitted edit: an [Edit] call whose preconditions pass and whose append commits, or a no-op edit.

Term admitted complete: a [Complete] call whose preconditions pass and whose append commits.

Term admitted delete: a [Delete] call whose preconditions pass and whose append commits.

Term admitted undo: an [Undo] call whose undo target exists and whose append commits.

Term admitted action: an admitted add, an admitted edit, an admitted complete, an admitted delete OR an admitted undo.

WHY:
Action wiring 4 through 7 are the order the whole composition rests on: validate, append, then recompute. A state recomputed before the append would expose a change the log does not carry, and a storage-failure after a recompute would leave the derived state ahead of its own truth. The action did not happen unless the append landed.

Action wiring 11 through 14 mirror the constituent exactly rather than improving on it. [Personal Todo](../atoms/personal-todo.md) declares a normalized-equal edit an accepted no-op that writes nothing, so this composition appends nothing — which means a no-op edit is never an [Undo] target and [Storage Failure] is not among its answers, because there is no append to fail.

Action wiring 19 is the boundary against redo. Undo events are not forward events, so no [Undo] reaches one; reversing an undo is redo, and redo is a different pattern reading a different class of compensating event (Non-goal 1).

### Wiring decision

```
Wiring decision 1: The composition MUST restore an undone delete's unit at the unit's original id.
Wiring decision 2: The composition MUST restore an undone delete's unit carrying the unit's original instants.
Wiring decision 3: The composition MUST restore an undone delete's unit through the replay.
Wiring decision 4: The composition MUST NOT restore an undone delete's unit from the snapshot.
Wiring decision 5: The composition MUST NOT call Personal Todo's add to restore an undone delete's unit.
```

WHY:
The principle: when a user undoes a delete, the unit must come back at its original id with its original `added_at`, its `last_edited_at` where it had one, and its state intact — not as a fresh unit with a new id and reset instants. That identity preservation is what users mean by undo and what makes this composition useful under an audit trail.

The likely objection: *could the delete save a snapshot and the undo restore from it?* Per-action snapshots — the Memento shape — restore the state and produce a new copy of the unit. A fresh add against Personal Todo issues a new id, resets the instants and loses the unit's history.

The mechanism: the original add event is still in the log. Undoing the delete appends a compensating event and re-replays, skipping the delete — so the unit is reconstructed from its own add, at its own id, with its own instants. Personal Todo's delete is terminal and irreversible; this composition does not overturn that, it operates at the log level where the delete simply never happened.

The result: Invariant 6.1 falls out of the replay rather than being designed in as a special case. The atoms are unchanged; the composition is entirely in the wiring.

### Event schemas

```
{type: "add",      event_id, recorded_at, id, description}
{type: "edit",     event_id, recorded_at, id, prior_description, new_description}
{type: "complete", event_id, recorded_at, id}
{type: "delete",   event_id, recorded_at, id, snapshot}
{type: "undo",     event_id, recorded_at, undone_event_id, undone_event_type}
```

```
Event schema 1: The composition MUST append an event carrying EXACTLY ONE OF the five schemas.
Event schema 2: Event Log MUST assign event id and recorded at at the log's own seam.
Event schema 3: The composition MUST NOT change an appended event.
Event schema 4: An admitted delete MUST record the unit's snapshot on the delete event.
Event schema 5: An admitted edit MUST record the unit's prior description on the edit event.
Event schema 6: The replay MUST NOT read a snapshot.
Event schema 7: The replay MUST NOT read a prior description.
Event schema 8: The composition MUST NOT answer Event Log's invalid-payload to a caller.
```

Term event type: add | edit | complete | delete | undo.

Term forward event: an event carrying add, edit, complete OR delete — every event an [Undo] may target.

Term snapshot: the unit's full state at a delete — its description, its Personal Todo state and every instant it carries.

WHY:
Event schema 6 and Event schema 7 are the load-bearing absence. Both fields exist and neither feeds the replay: what a delete removed and what an edit replaced are readable straight from the log through [Read History], with no replay at all, and they are kept in the schemas for *that* reading. A replay that consumed them would be restoring state from a snapshot, which is the design this composition exists to reject (the section titled Wiring decision).

The undo schema is the only one carrying two fields of its own: [Undone Event Id], which the replay builds the undone set from (Replay 2), and [Undone Event Type], which the undo answers to the caller (Action wiring 18).

Event schema 8 is a foreclosure rather than a mapping. [Event Log](../atoms/event-log.md)'s `append` declares an `invalid-payload` arm, and every payload this composition appends is one of five fixed schemas built by machine from already-validated inputs — so the arm cannot be reached, and reaching it would be a defect in this composition rather than a caller's fault. It surfaces as a deployment fault and is mapped to no caller rejection.

---

## Composition-level invariants

Each of these emerges from the composition. None belongs to a single constituent; each needs both atoms working together.

- **Invariant 1 — Log faithfulness.**
  ```
  Invariant 1.1: EVERY state-changing admitted action MUST append EXACTLY ONE event.
  Invariant 1.2: EVERY event of the event log instance MUST follow an admitted action.
  Deleted: Invariant 1.3. Action wiring 11 owns it.
  ```
  WHY: Action wiring 11 is the one exception and it is the constituent's, not this composition's. Personal Todo declares a normalized-equal edit an accepted action that writes nothing; mirroring that exactly is what keeps Invariant 1.1 true of *state-changing* actions rather than of all of them.
- **Invariant 2 — State equivalence.**
  ```
  Invariant 2.1: The derived state MUST equal the replay of the event log instance.
  ```
- **Invariant 3 — An undo targets the most recent surviving forward event.**
  ```
  Invariant 3.1: EVERY undo event's undone event id MUST name the undo target the undo found.
  ```
- **Invariant 4 — Personal Todo's invariants hold over the derived state.**
  ```
  Invariant 4.1: EVERY Personal Todo invariant MUST hold over one replayed derived state.
  Invariant 4.2: The composition MUST NOT claim a Personal Todo invariant across two replays.
  ```
  WHY: the scoping is the point and it is deliberate. Within any single replayed state every Personal Todo invariant holds, the temporal ones included, exactly as over a direct forward history — because every surviving event was a successful action against a then-valid state. Across successive replays the exposed timeline deliberately rewinds, since an undo removes the newest surviving event, so a claim like *a completion once exposed stays exposed* is this composition's designed undo behaviour rather than a constituent violation. Invariant 4.2 says so rather than leaving a reader to discover it.
- **Invariant 5 — Event Log's invariants hold.**
  ```
  Invariant 5.1: EVERY Event Log invariant MUST hold over the event log instance.
  Invariant 5.2: The composition MUST NOT remove an event.
  Invariant 5.3: The composition MUST NOT rewrite an event.
  ```
  WHY: [Event Log](../atoms/event-log.md)'s `Composition note 5` obliges a composing pattern to cite its invariants by number, because `Composition note 4` freezes those numbers against the citations. This composition rests on six of the seven, each named in the qualified form because this spec carries an Invariant 1 through 7 of its own, so the unqualified form is wrong for every one of the six: Event Log Invariant 1 (append-only) and Event Log Invariant 2 (event immutability), which Invariant 5.2 and Invariant 5.3 mirror from this side; Event Log Invariant 3 (total order) and Event Log Invariant 4 (sequence-number monotonicity), without which Replay 1's *in sequence number order* names nothing; Event Log Invariant 5 (read consistency), which bounds the replay's input to exactly the landed events; and Event Log Invariant 6 (no id reuse), which is what lets an undone event id name one event for the life of the log (Invariant 3.1, Check 3.3). It does not rest on Event Log Invariant 7: recorded at is an annotation this composition never orders by.
- **Invariant 6 — Identity is preserved across a delete and its undo.**
  ```
  Invariant 6.1: An undone delete's unit MUST carry the unit's original id, instants and Personal Todo state.
  ```
  WHY: Personal Todo alone cannot do this — its delete is terminal and a fresh add produces a new id. Composed with Event Log it comes back, because the original add event is still there to replay.
- **Invariant 7 — Prior states are reachable by undoing.**
  ```
  Invariant 7.1: A finite sequence of [Undo] calls MUST walk the derived state back through the surviving event sequence.
  Invariant 7.2: The composition MUST NOT reach a state an undo abandoned.
  Invariant 7.3: The composition MUST NOT reach a state a forward action abandoned.
  ```
  WHY: Invariant 7.2 and Invariant 7.3 mark the two classes of prior state deliberately outside the walk, and both are redo's territory. Add, complete, undo leaves the done state behind and no further undo revisits it; and once forward actions resume, the states behind already-undone events are gone from the walk. In both cases the events remain in the log — only a separate redo pattern re-applies them.

---

## Examples

### Walkthrough

`add("buy milk")` → `u1`, appending `{add, id: u1}`. `complete(u1)` → ok, appending `{complete, id: u1}`; the replay now shows `u1` done. `undo()` → complete, appending `{undo, undone_event_id: <the complete>}`; the replay skips the complete and `u1` is pending again — and Personal Todo was never asked to move a done unit back to pending, because the replay simply never applies the complete.

### Identity across a delete and its undo

`add("call the vet")` → `u2` at `added_at: 09:14`. `edit(u2, "call the vet about Rosie")` → ok. `delete(u2)` → ok, the delete event carrying `u2`'s snapshot. `undo()` → delete; the replay skips the delete and re-derives `u2` from its own add and edit events — same id, same `added_at: 09:14`, the edited description, pending. The snapshot on the delete event was never read (Event schema 6); it is there for a reader of the log, not for the replay.

### Audit as a side effect

`read_history(query)` passes through to the log and answers every event in order — adds, edits, completes, deletes and undos alike. Nothing was written for the audit; the log *is* the state, so the history came free with the undo.

### Rejection paths

`add("")` → invalid-description, refused against Personal Todo's own precondition before anything is appended. `complete(u_unknown)` → not-known. `complete(u1)` where `u1` is already done → not-pending. `undo()` on a fresh log → nothing-to-undo — no forward event exists to target. `edit(u2, "call the vet about Rosie")` where that is already the description → ok, and nothing is appended (Action wiring 11), so the edit is not an undo target and storage-failure is not among its possible answers.

---

## Generation acceptance

This composition's acceptance is records-alone: every invariant above is checkable from the event log instance by replay, with no stored state, runbook or developer narration consulted.

### Conformance checks

```
Check 1.1: An auditor MUST find EXACTLY ONE event PER state-changing admitted action in the event log instance (Invariant 1.1).
Check 1.2: An auditor MUST find an admitted action behind EVERY event of the event log instance (Invariant 1.2).
Check 2.1: An auditor MUST find the derived state equal to a fresh replay of the event log instance (Invariant 2.1).
Check 2.2: An auditor MUST run the replay against the event log instance and NOT against a materialized derived state (Replay 17).
Check 3.1: An auditor MUST find EVERY undo event's undone event id naming a forward event (Invariant 3.1).
Check 3.2: An auditor MUST find no undo event's undone event id naming an undo event (Action wiring 19).
Check 3.3: An auditor MUST find no two undo events naming one undone event id (Invariant 3.1).
Check 4.1: An auditor MUST find EVERY Personal Todo invariant holding over one replayed derived state (Invariant 4.1).
Check 5.1: An auditor MUST find no event absent from a later read of the event log instance (Invariant 5.2).
Check 5.2: An auditor MUST find a re-read event unchanged (Invariant 5.3).
Check 6.1: An auditor MUST find an undone delete's unit carrying the unit's original id and instants in the replay (Invariant 6.1).
Check 6.2: An auditor MUST reconstruct an undone delete's unit from the unit's own add event (Wiring decision 3).
Check 7.1: An auditor MUST walk the derived state back through the surviving event sequence by replaying the sequence minus the sequence's newest event (Invariant 7.1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing the event log instance confirmed durable across a restart MUST read the deployment's own storage (Non-goal 5).
External check 2: A deployment needing the event log instance confirmed to be this Personal Todo's own history MUST read the deployment's wiring (Non-goal 6).
External check 3: A deployment needing an undo's surface meaning confirmed MUST read the deployment's own interface (Non-goal 9).
External check 4: A deployment needing a replay bounded in time MUST read a snapshot pattern (Non-goal 8).
```

WHY:
External check 1 is the one a deployment can lose silently. Every invariant here is checkable by replay, and a replay needs a log that survived; a volatile Event Log instance leaves a composition that satisfies every rule above and loses the user's undo history at restart, which is not what anyone expects. The composition assumes durability and cannot check it.

External check 2 follows from the same assumption in the other direction. The composition assumes its Event Log instance is fresh or carries this same Personal Todo's prior history; an instance inherited from a different substrate would replay into a state that never existed here, and nothing in the log says which substrate wrote it.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT reapply an undone event.
Non-goal 2: A deployment needing redo MUST compose a redo pattern.
Non-goal 3: The composition MUST NOT offer a branching history.
Non-goal 4: The composition MUST NOT undo a forward event beside the undo target.
Non-goal 5: The composition MUST NOT guarantee the event log instance's durability.
Non-goal 6: The composition MUST NOT confirm that the event log instance carries this Personal Todo's history.
Non-goal 7: The composition MUST NOT serve two actors.
Non-goal 8: The composition MUST NOT bound the replay's cost.
Non-goal 9: The composition MUST NOT define an undo's surface meaning.
Non-goal 10: The composition MUST NOT reverse an action's external effect.
```

WHY:
Non-goal 4 is the one users argue with, and the rule is unambiguous where intuition is not. [Undo] always takes the most recent forward event not already undone; undoing a specific earlier action while keeping later ones would need event-dependency analysis and is a separate pattern. In a long sequence with several undos the rule can diverge from what a user imagines, because intuition walks back through *visible* history and the rule walks back through *unredacted* history — Non-goal 9 puts the reconciliation in the interface, where it belongs.

Non-goal 10 is where the composition breaks down rather than where it declines. Replay reverses an action by never applying it, which works exactly as long as the action's only effect was on the derived state. Substitute a substrate whose actions send email or charge cards and skipping the event un-does nothing in the world; the composition would report a state the world does not share.

Non-goal 8 is honest about cost. A replay runs the whole log, so it is linear in the log's length, and a deployment with millions of events composes a snapshot pattern that lets the replay start from the most recent capture.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the composition; the deployment; the implementation; the seam; a caller; a user; an auditor; a reader; the replay; an event; a forward event; an undo event; a surviving event; a unit; an action; a forward action; a refused action; an admitted action; a no-op edit; the derived state; the event log instance; the undone set; the undo target; a snapshot; a query.

Term records: event — one appended record in the event log instance, carrying event id, recorded at, a type and the type's own fields.

Term record verbs: serve, derive, store, call, change, replace, append, assign, read, skip, apply, introduce, remove, move, record, answer, validate, refuse, recompute, capture, restore, preserve, hold, carry, stand, commit, leave, name, mirror, bound, compose, wire, decide, define, guarantee, confirm, reach, walk, target, generate, materialize, rebuild, equal, follow, reverse, surface, claim, build, produce, rewrite, find, run, reconstruct, offer, undo, reapply.

Term value sets: event type = add | edit | complete | delete | undo. forward event = add | edit | complete | delete.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term terms: composition, constituents, event log instance, derived state, unit, seam, event type, forward event, snapshot, forward action, no-op edit, undone set, undo target, replay, surviving event, admitted add, admitted edit, admitted complete, admitted delete, admitted undo, admitted action.

Term cited: the section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Composition state in `execution-contract.md` — the derived index and its rebuild obligations.

#### Add

The action that records a new [Unit]. Validates against [Personal Todo](../atoms/personal-todo.md)'s own add precondition and against the derived state, takes the new id from the seam, appends an add event, and answers the id.

Kind: Operation

#### Edit

The action that changes a [Unit]'s description. Validates against Personal Todo's edit precondition, captures the [Prior Description], appends an edit event, and answers ok. A [No-op Edit] appends nothing and answers ok anyway, mirroring the constituent.

Kind: Operation

#### Complete

The action that moves a [Unit] to done. Validates against Personal Todo's complete precondition, appends a complete event, answers ok.

Kind: Operation

#### Delete

The action that removes a [Unit] from the derived state. Appends a delete event carrying the unit's [Snapshot] — which the replay never reads, and which an undo therefore never restores from.

Kind: Operation

#### Undo

The action that takes back the last thing the user did. Finds the [Undo Target], appends an undo event naming it, re-derives the state with that event skipped, and answers the undone event's type. It reverses by re-derivation, never by a reversing call to the constituent.

Kind: Operation

#### Read History

The read-only pass-through to [Event Log](../atoms/event-log.md)'s own read, answering the matching events in order. The audit surface that came free with the undo.

Kind: Operation

#### Unit

One task in the derived state, named by an id as [Personal Todo](../atoms/personal-todo.md)'s identity model declares it. Reconstructed by the replay rather than stored, which is why its identity survives a delete and its undo.

Kind: Type
Projection: unit

#### Snapshot

The unit's full state captured on a delete event — its description, its Personal Todo state and every instant it carries. An audit convenience, readable straight from the log; never a replay input (Event schema 6).

Kind:       Field
Field of:   the delete event
Projection: snapshot

#### Prior Description

The unit's description before an edit, captured on the edit event. Like [Snapshot], readable from the log and never replayed (Event schema 7).

Kind:       Field
Field of:   the edit event
Projection: prior_description

#### New Description

The description an [Edit] supplies, recorded on the edit event and applied by the replay. When it normalizes equal to the unit's current description the edit is a [No-op Edit].

Kind:         Parameter
Parameter of: Edit
Projection:   new_description

#### No-op Edit

An [Edit] whose [New Description] normalizes equal to the unit's current description. [Personal Todo](../atoms/personal-todo.md) declares it an accepted action that writes nothing, and this composition mirrors it exactly: no append, no [Prior Description], no state change, ok answered, and never an [Undo Target].

Kind: Type
Projection: no_op_edit

#### Undone Event Id

The event id an undo event names — the [Undo Target] it took back. Every one of these forms the [Undone Set].

Kind:       Field
Field of:   the undo event
Projection: undone_event_id

#### Undone Event Type

The [Event Type] of the event an undo took back, recorded on the undo event and answered to the caller so a surface can say *what* was undone.

Kind:       Field
Field of:   the undo event
Projection: undone_event_type

#### Undone Set

The undone event id of every undo event in the event log instance — what the replay skips by.

Kind: Type
Projection: undone_set

#### Undo Target

The most recent forward event whose event id is not in the [Undone Set]. What an [Undo] takes back, and what [Nothing To Undo] says does not exist.

Kind: Type
Projection: undo_target

#### Event Type

Which of the five schemas an event carries: add, edit, complete, delete or undo. The first four are [Forward Event]s; the fifth is not, and is never an [Undo Target].

Kind:       Field
Field of:   the event
Projection: type

#### Forward Event

An event carrying add, edit, complete or delete — every event an [Undo] may target, and every event the replay may apply.

Kind: Type
Projection: forward_event

#### Nothing To Undo

The refusal [Undo] returns when no [Undo Target] exists — a fresh log, or one where every forward event is already undone.

Kind:       Member
Member of:  the Undo rejection
Role:       Outcome
Projection: nothing-to-undo

#### Storage Failure

The refusal any appending action returns when [Event Log](../atoms/event-log.md)'s `append` refuses. The derived state is not recomputed and the action did not happen.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Add]: #add
[Edit]: #edit
[Complete]: #complete
[Delete]: #delete
[Undo]: #undo
[Read History]: #read-history
[Unit]: #unit
[Snapshot]: #snapshot
[Prior Description]: #prior-description
[New Description]: #new-description
[No-op Edit]: #no-op-edit
[Undone Event Id]: #undone-event-id
[Undone Event Type]: #undone-event-type
[Undone Set]: #undone-set
[Undo Target]: #undo-target
[Event Type]: #event-type
[Forward Event]: #forward-event
[Nothing To Undo]: #nothing-to-undo
[Storage Failure]: #storage-failure

---

## Standards references

- **Event sourcing (Fowler; CQRS literature)** — the shape this composition instantiates: state derived by replaying a log rather than stored, with compensating events rather than mutation. The composition's contribution is not the shape but what the shape buys when the substrate is a concept with its own invariants — identity preservation across a terminal delete.
- **The Memento pattern (Gamma et al.)** — the design this composition explicitly rejects for restoration, and keeps for inspection. A memento restores state and produces a new copy; the section titled Wiring decision states why that loses the property users mean by undo.
- **Command pattern with undo (Gamma et al.)** — the classical undo shape, which reverses by invoking an inverse operation. This composition cannot use it, because [Personal Todo](../atoms/personal-todo.md)'s delete is terminal and its completion is persistent: there is no inverse to invoke, so the reversal happens one level down, at the log.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the composition posture: two freestanding concepts, unchanged, with the new guarantee living entirely in the wiring.
- **Grace Commons composition conventions** — the emergent-invariant discipline from `pressure-testing.md`: a composition earns its place by a guarantee no constituent has alone.

---

## Status

`grounded on Final Critique 6 — 2026-08-26` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 6 — 2026-08-26
formal: verified — undo-history.tla + 3 twins, 2026-06-14
last gate: 2026-08-26 — Final Critique 6, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/undo-history.md`.

- **2026-09-14 — The first composition migrated after the atom set, and the shape it sets.** *Chose:* `Composes` for the constituent contract, then a family per wiring surface — `Event schema`, `Action wiring`, `Replay`, `Wiring decision` — above the composition-level `Invariant` family, with `Check` and `External check` below it. *Over:* folding the wiring into `Operation`, which is what an atom uses. *Because:* a composition's rules are about *where a call goes* rather than about what one record does, and the families name the surfaces a reader has to hold apart: what gets written, what each action does with it, how the state is rebuilt, and the one decision the whole composition exists to enforce. `Operation` would have flattened four different kinds of claim into one family.
- **2026-09-14 — The acceptance section is written from one sentence the prose already carried, and nothing more.** *Chose:* thirteen `Check` rules and four `External check` rules, each naming the rule it tests. *Over:* leaving acceptance unwritten, which is how the prose stood — it claimed only that *the verification surface is records-alone: every invariant above is checkable by replay*. *Because:* that sentence is a claim per invariant, and distributing it is language rather than new obligation. Where the prose gave no basis for a check, none was invented; the four External checks are the four assumptions the prose already named as outside the composition's reach.

NOTE: End of Undo History.
