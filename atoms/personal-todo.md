---
title: Personal Todo
parent: Atomic Concepts
has_toc: true
toc: true
---

# Personal Todo

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>


## Summary

Personal Todo is a single-person to-do list: one user records tasks, edits them while they are still open, marks them done, and deletes them. Every task gets a permanent internal identifier that never changes, so editing the wording of a task does not change which task it is. Each task is always in exactly one state — open (Pending) or finished (Done) — until it is deleted. No two active tasks can share the same wording, and the same text typed two different ways still counts as a match. It is built for one person managing their own list — personal tasks, reading lists, grocery lists, goals — not for shared or delegated lists, which are handled by separate patterns that build on this one.

---

## Intent

WHY:
One person, a list of things to do, and nothing else. The atom exists because every larger system that tracks work contains this shape and buries it: a unit is recorded, may be revised, is finished or abandoned, and leaves. Isolating it makes the additions visible as additions — an owner, a priority, a due date, a second actor are each a composing pattern rather than a field quietly added here. Two decisions carry the weight. A unit's identity is an opaque id, never its text, so revising the text does not make it a different unit; and the text is unique across everything live, so a list cannot silently hold *buy milk* twice. Everything else follows from those, including the thing the atom deliberately does not do: remember what was deleted.

## Structure

### Identity model

```text
Identity 1: The atom MUST identify a unit by the id.
Identity 2: The host MUST allocate an id at the atom's seam.
Identity 3: The transition MUST NOT allocate an id.
Identity 4: The business caller MUST NOT supply an id.
Identity 5: The atom MUST NOT reuse an id.
Identity 6: The atom MUST NOT identify a unit by the description.
Identity 7: The implementation MUST own the id's scheme.
```

Terms › `unit`: one thing to do — the record this atom holds; recorded, revised, finished or abandoned.

Terms › `id`: the opaque value naming one unit — an [Id]; stable across sessions, unique for the system's life.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading and the id here.

Terms › `transition`: the atom's evaluation of one call against the list, as `execution-contract.md` §Logic confinement declares it.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

### Description policy

```text
Description 1: The atom MUST trim a description's leading and trailing whitespace.
Description 2: The atom MUST normalize a description to Unicode normal form C.
Description 3: The atom MUST preserve a description's internal whitespace.
Description 4: IF the normalized description is empty THEN the atom MUST answer invalid-description.
Description 5: IF the normalized description EXCEEDS the description cap THEN the atom MUST answer invalid-description.
Description 6: The atom MUST compare two descriptions case-sensitively.
Description 7: The atom MUST compare two descriptions on the normalized form.
Description 8: The atom MUST show the normalized form.
```

Terms › `description`: the text the person gives a unit — a [Description]; normalized before it enters the list and before any comparison.

Terms › `description cap`: the bound on a normalized description's length; 1024 codepoints where a deployment declares none.

WHY:
Normalization before comparison is what makes *café* typed and *café* pasted the same text — different sources produce different Unicode forms, and without normal form C the uniqueness rule would let one list hold both (Description 2, Invariant 6.1). Case sensitivity and internal whitespace are kept verbatim because the person's own text is what the person recognizes; a case-insensitive or fuzzy variant is a wrapping pattern's policy, not this atom's (Description 3, Description 6).

### State

```text
State 1: EVERY known unit MUST stand in EXACTLY ONE OF pending, done.
State 2: EVERY unit MUST carry id, description and added_at.
State 3: A unit MAY carry last_edited_at.
State 4: A done unit MUST carry completed_at.
State 5: [Add] MUST stamp added_at from the injected now.
State 6: [Edit] MUST stamp last_edited_at from the injected now.
State 7: [Complete] MUST stamp completed_at from the injected now.
State 8: [Delete] MUST take the unit out of the list.
State 9: The atom MUST NOT offer a done-to-pending transition.
State 10: The atom MUST NOT hold a deleted unit.
```

Terms › `unit state`: `pending` | `done` — recorded and unfinished, or finished and unremoved.

Terms › `added_at`: the instant the unit was recorded — an [Added At].

Terms › `last_edited_at`: the instant the unit's description last changed — a [Last Edited At]; absent until an edit lands.

Terms › `completed_at`: the instant the unit was finished — a [Completed At].

Terms › `active set`: the units standing in pending together with the units standing in done — what uniqueness ranges over.

WHY:
Deletion is the only way out and it is terminal: the atom keeps no memory of what left, which is why re-adding a deleted description succeeds and why a system that wants *not twice this morning* composes [Duplicate Prevention](./duplicate-prevention.md) rather than asking this atom to remember (State 10, Composition note 2). There is no reopening, because a person who reopens a finished thing is describing a different pattern — one with history — and adding the transition here would quietly take that pattern's job (State 9).

### Operations

```
add(description) → id | rejected(invalid-description | duplicate-active | storage-failure)
edit(id, new_description) → ok | rejected(not-known | not-editable | invalid-description | duplicate-active | storage-failure)
complete(id) → ok | rejected(not-known | not-pending | storage-failure)
delete(id) → ok | rejected(not-known | storage-failure)
```

```text
Operation 1: [Add] MUST record EXACTLY ONE unit per successful call.
Operation 2: [Add] MUST stand the unit in pending.
Operation 3: [Add] MUST answer id.
Operation 4: IF the normalized description matches a unit in the active set THEN [Add] MUST answer duplicate-active.
Operation 5: IF the store refuses the write THEN [Add] MUST answer storage-failure.
Operation 6: [Add] MUST NOT record a unit on storage-failure.
Operation 7: IF the id NOT EXISTS THEN [Edit] MUST answer not-known.
Operation 8: IF the unit stands in done THEN [Edit] MUST answer not-editable.
Operation 9: IF the unit stands in pending AND the normalized new_description matches another unit in the active set THEN [Edit] MUST answer duplicate-active.
Operation 9a: IF the unit stands in pending AND the normalized new_description fails the description policy THEN [Edit] MUST answer invalid-description.
Operation 10: IF the unit stands in pending AND the normalized new_description = the unit's description THEN [Edit] MUST answer ok.
Operation 11: [Edit] MUST NOT write for a new_description equal to the unit's description.
Operation 12: [Edit] MUST NOT stamp last_edited_at for a new_description equal to the unit's description.
Operation 13: [Edit] MUST replace the unit's description.
Operation 14: [Edit] MUST leave the unit standing in pending.
Operation 15: IF the id NOT EXISTS THEN [Complete] MUST answer not-known.
Operation 16: IF the unit stands in done THEN [Complete] MUST answer not-pending.
Operation 17: [Complete] MUST stand the unit in done.
Operation 18: IF the id NOT EXISTS THEN [Delete] MUST answer not-known.
Operation 19: [Delete] MUST take a pending unit out of the list.
Operation 20: [Delete] MUST take a done unit out of the list.
Operation 21: IF the store refuses the write THEN [Edit] MUST answer storage-failure.
Operation 22: IF the store refuses the write THEN [Complete] MUST answer storage-failure.
Operation 23: IF the store refuses the write THEN [Delete] MUST answer storage-failure.
Operation 24: A refused call MUST leave the unit as the call found the unit.
Operation 25: The host MUST read the clock at the atom's seam.
Operation 26: The transition MUST NOT read a clock.
Operation 27: The business caller MUST NOT supply now.
```

Terms › `new_description`: the text an edit offers for a unit — a [New Description]; normalized under the description policy.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the list |
|---|---|---|---|
| [Add] | description valid, no active match, store accepts | `id` | one unit lands in [Pending] (Operation 1, Operation 2) |
| [Add] | description empty or over the cap | [Invalid Description] | none (Description 4, Description 5) |
| [Add] | description matches a live unit | [Duplicate Active] | none (Operation 4) |
| [Edit] | valid, different, no active match, store accepts | `ok` | description and `last_edited_at` change (Operation 13, State 6) |
| [Edit] | same normalized text | `ok` | none — no write, no stamp (Operation 10–12) |
| [Edit] | unit is done | [Not Editable] | none (Operation 8) |
| [Complete] | unit is pending | `ok` | [Pending] → [Done], `completed_at` stamped (Operation 17, State 7) |
| [Complete] | unit is done | [Not Pending] | none (Operation 16) |
| [Delete] | unit is pending or done | `ok` | the unit leaves; the id is retired (Operation 19, Operation 20, Identity 5) |
| any | id names nothing | [Not Known] | none (Operation 7, Operation 15, Operation 18) |
| any writing call | store refuses | [Storage Failure] | none (Operation 5, Operation 21–24) |

WHY:
The no-op edit is a real accepted case that writes nothing, which is why it cannot answer `storage-failure` — a person retyping the same words has changed nothing and should not see a failure from a store that was never asked (Operation 10–12). Uniqueness ranges over pending and done together: a finished *buy milk* still blocks a second one, because a list showing the same text twice is confusing whichever column it sits in (Operation 4, Invariant 6.1).

### Invariants

- **Invariant 1 — Membership exclusivity.**
  ```text
  Invariant 1.1: EVERY known unit MUST stand in EXACTLY ONE OF pending, done.
  ```
- **Invariant 2 — Add-then-Pending persistence.**
  ```text
  Invariant 2.1: A recorded unit MUST stand in pending ONLY IF [Complete] NOT EXISTS AND [Delete] NOT EXISTS for the unit.
  ```
- **Invariant 3 — Complete-then-Done persistence.**
  ```text
  Invariant 3.1: A completed unit MUST stand in done ONLY IF [Delete] NOT EXISTS for the unit.
  ```
- **Invariant 4 — Delete is terminal.**
  ```text
  Invariant 4.1: A deleted unit's id MUST NOT stand in the list.
  NOTE: Invariant 4.2 deleted — Identity 5 owns id reuse for every id, deleted or not.
  ```
- **Invariant 5 — Edit preserves state.**
  ```text
  Invariant 5.1: An edited unit MUST stand in pending.
  Invariant 5.2: [Edit] MUST NOT change a field other than description and last_edited_at.
  ```
- **Invariant 6 — Active-set description uniqueness.**
  ```text
  Invariant 6.1: Two units in the active set MUST NOT share a normalized description.
  ```
- **Invariant 7 — Timestamp monotonicity.**
  ```text
  Invariant 7.1: added_at MUST NOT EXCEED last_edited_at ONLY IF last_edited_at EXISTS.
  Invariant 7.2: added_at MUST NOT EXCEED completed_at ONLY IF completed_at EXISTS.
  Invariant 7.3: last_edited_at MUST NOT EXCEED completed_at ONLY IF last_edited_at EXISTS AND completed_at EXISTS.
  ```
  WHY: best-effort under a clock that moves backward; the deployment owns clock quality (Clock semantics 1–3).
- **Invariant 8 — Id stability.**
  ```text
  Invariant 8.1: [Add] MUST set the id.
  Invariant 8.2: An id MUST NOT change.
  Invariant 8.3: [Edit] MUST NOT change the id.
  ```

## Examples

The same pattern, three personal-scope domains, identical mechanic. A fourth example walks the rejection paths.

### Personal task management

A user opens a notes app, types *"buy milk."* The system trims, NFC-normalizes, returns id `t1`. The user marks `t1` done after the errand, then deletes `t1`. A week later, types *"buy milk"* again — accepted; new id `t2` is issued (no temporal memory in this pattern). Adds *"renew passport"* (id `t3`), edits it to *"renew passport before Italy trip"* the next day (still `t3`, [Last Edited At] updated), leaves it pending for six weeks, eventually deletes `t3` because they renewed via a different channel.

### Reading list

A user adds *"Essence of Software"* (id `b1`), finishes it three weeks later, marks it done, deletes it from the Done list. Adds *"TLA+ in Action"* (id `b2`), abandons it after fifty pages, deletes `b2`. Two days later, decides to retry — adds *"TLA+ in Action"* again — accepted with new id `b3` (no recency check in this pattern alone).

### Personal goal capture

A user adds *"call mom this week"* on Monday (id `g1`), completes `g1` Friday, deletes `g1`. Adds the same description the following Monday — accepted, id `g2`. Adds *"learn Python"* (id `g3`), edits it the next day to *"learn Python — finish first three Real Python tutorials"* to make the goal concrete. Same id `g3`, updated [Description], updated [Last Edited At].

### Rejection paths

The same user, exercising the rejection surface in one short sequence:

- Adds *"buy milk"* — accepted, id `r1`.
- Tries to add *"buy milk"* again immediately while `r1` is still in [Pending] — rejected as [Duplicate Active] (active-set uniqueness protects this case).
- Marks `r1` done. Tries to add *"buy milk"* once more while `r1` is in [Done] — rejected as [Duplicate Active] ([Done] counts toward active-set uniqueness).
- Tries to edit `r1` (currently in [Done]) — rejected as [Not Editable].
- Tries to add *"   "* (whitespace-only) — rejected as [Invalid Description] (empty after trim).
- Tries to add a 5,000-codepoint description — rejected as [Invalid Description] (exceeds default 1,024 limit).
- Pastes *"café"* in NFD form (`cafe` + combining acute) while `r1`'s description *"café"* in NFC form is in [Done] — rejected as [Duplicate Active] (NFC normalization unifies the two forms).
- Tries to complete an unknown id — rejected as [Not Known].
- Deletes `r1`. Now *"buy milk"* is no longer in the active set; a fresh `add("buy milk")` would succeed with a new id (id `r2`).

This sequence covers four of the rejection reasons ([Invalid Description], [Duplicate Active], [Not Editable], [Not Known]) in a single thread of user action. The fifth reason, [Not Pending], is exercised separately — for example, attempting to [Complete] an id that is already [Done].

---

## Non-goals

```text
Non-goal 1: The atom MUST NOT hold a second actor.
Non-goal 2: A deployment needing a shared list MUST compose [Shared Todo](../compositions/shared-todo.md).
Non-goal 3: The atom MUST NOT assign a unit to an actor.
Non-goal 4: The atom MUST NOT remember a deleted description.
Non-goal 5: A deployment needing a recency guard MUST compose [Duplicate Prevention](./duplicate-prevention.md).
Non-goal 6: The atom MUST NOT restore a deleted unit.
Non-goal 7: A deployment needing restoration MUST compose [Undo History](../compositions/undo-history.md).
Non-goal 8: The atom MUST NOT reopen a done unit.
Non-goal 9: The atom MUST NOT regenerate a unit on a schedule.
Non-goal 10: The atom MUST NOT order units.
Non-goal 11: The atom MUST NOT hold a due date.
Non-goal 12: The atom MUST NOT hold a dependency between units.
Non-goal 13: The atom MUST NOT keep a description's history.
Non-goal 14: The atom MUST NOT resolve two concurrent calls on one unit.
Non-goal 15: The atom MUST NOT match descriptions case-insensitively.
```

WHY:
Each of these is a field somebody will want to add here and each is a pattern: priority and ordering, due dates, dependencies and recurrence compose *(all forthcoming)*, and the moment one of them lands inside this atom the atom stops being the thing every larger system contains (Non-goal 9–12). Deletion keeps no memory by design, which is what makes the recency behaviour a composition rather than a mode (Non-goal 4, Non-goal 5). Only `last_edited_at` survives an edit — prior text is gone, and a system that needs the trail composes a history pattern (Non-goal 13).

Where the atom breaks down: any system with more than one actor; a system where *finished* is not binary; a system where the description is not a property worth constraining; a host that cannot make a transition atomic.

## Edge cases

### Concurrency on one unit

```text
Concurrency 1: The atom MUST assume a linear sequence of calls from one actor.
Concurrency 2: The implementation MUST make EVERY transition atomic.
Concurrency 3: A deployment running two clients MUST compose a concurrency-resolution pattern.
```

WHY:
Two tabs acting on one unit is outside the atom: a crash or a race that leaves a unit in neither state breaks Invariant 1.1, and the transactional boundary that prevents it is the implementor's (Concurrency 2).

### Clock semantics

```text
Clock semantics 1: The deployment MUST own the clock's monotonicity.
Clock semantics 2: The deployment MUST own the clock's timezone handling.
Clock semantics 3: A deployment needing a defensible timeline MUST compose a trusted-timestamping pattern.
```

### Re-adding a deleted description

```text
Re-adding 1: The atom MUST accept a description equal to a deleted unit's description.
Re-adding 2: [Add] MUST answer a fresh id for such a unit.
```

WHY:
*Buy milk* deleted this morning and added again this afternoon is a new unit with a new id, and nothing in the atom objects. A deployment that wants the second one refused inside a window composes [Duplicate Prevention](./duplicate-prevention.md), whose guard opens on the delete and closes on its own clock (Composition note 2).

## Composition notes

```text
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern needing a recency guard MUST record a deleted description with [Duplicate Prevention](./duplicate-prevention.md).
Composition note 3: A composing pattern needing a recency guard MUST NOT call [Add] BEFORE a [Duplicate Prevention](./duplicate-prevention.md) check.
Composition note 4: A composing pattern needing restoration MUST append a deleted unit to an [Event Log](./event-log.md).
Composition note 5: A composing pattern needing a shared list MUST compose [Permissions](./permissions.md) and [Assignment](./assignment.md).
```

WHY:
The three landed compositions are the worked examples: [Undo History](../compositions/undo-history.md) appends every deletion to an Event Log so the list becomes restorable from records; [Shared Todo](../compositions/shared-todo.md) adds Permissions and Assignment to make one person's list many people's; and a container wanting *not twice in one morning* wires [Duplicate Prevention](./duplicate-prevention.md) around delete and add, which is where the [Duplicate Recent] refusal comes from — that refusal is the composing pattern's, never this atom's (Composition note 2, Composition note 3). Forthcoming: Priority and Ordering, Task Dependencies, Recurring, Reopen and Revision, Concurrency Resolution.

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a person; a unit; a call; the store; the list.

Terms › `records`: `unit` — one thing to do, carrying `id`, `description`, `added_at`, a unit state and, once they land, `last_edited_at` and `completed_at`.

Terms › `record verbs`: call, identify, allocate, supply, reuse, own, trim, normalize, preserve, answer, compare, show, stand, carry, stamp, take, offer, hold, record, replace, leave, write, read, match, change, set, share, assume, make, compose, remember, restore, reopen, regenerate, order, keep, resolve, assign, accept, check, append, exceed.

Terms › `value sets`: add answers = id | rejected(invalid-description | duplicate-active | storage-failure). edit answers = ok | rejected(not-known | not-editable | invalid-description | duplicate-active | storage-failure). complete answers = ok | rejected(not-known | not-pending | storage-failure). delete answers = ok | rejected(not-known | storage-failure). `unit state` = pending | done.

Terms › `bounds`: `description cap` (the bound on a normalized description's length).

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-12).

Terms › `terms`: `now`, `unit`, `id`, `seam`, `transition`, `business caller`, `description`, `description cap`, `unit state`, `added_at`, `last_edited_at`, `completed_at`, `active set`, `new_description`.

#### Add

The behavior that records a new unit of work. It allocates a fresh [Id], normalizes the supplied [Description], stamps [Added At], and places the unit in [Pending], returning the [Id].

Kind: Operation

#### Edit

The behavior that revises a [Pending] unit's [Description]. It replaces the value with the normalized [New Description] and stamps [Last Edited At]; the unit's state and [Id] are unchanged.

Kind: Operation

#### Complete

The behavior that marks a [Pending] unit done, moving it [Pending] → [Done] and stamping [Completed At].

Kind: Operation

#### Delete

The behavior that removes a unit from the system entirely. Deletion is terminal; the [Id] is retired and not reused.

Kind: Operation

#### Id

The opaque, immutable identity of a unit, host-allocated at the I/O seam on [Add] and never changed. The unit's [Description] is a property under uniqueness constraint, not its identity — two units with the same [Description] still have different ids.

Kind:     Field
Field of: Personal Todo
Projects: id

#### Description

The user-supplied text of a unit, normalized (trim + NFC) before it enters state. It is mutable via [Edit] while [Pending], unique across the active set ([Pending] ∪ [Done]), and a property of the unit rather than its identity.

Kind:     Field
Field of: Personal Todo
Projects: description

#### Added At

The wall-time a unit was created, stamped from the injected [Now] on [Add]. Immutable thereafter.

Kind:     Field
Field of: Personal Todo
Projects: added_at

#### Last Edited At

The wall-time of a unit's most recent [Edit], stamped from the injected [Now]. Absent on a unit that has never been edited.

Kind:     Field
Field of: Personal Todo
Projects: last_edited_at

#### Completed At

The wall-time a unit was marked done, stamped from the injected [Now] on [Complete]. Present only while the unit is [Done].

Kind:     Field
Field of: Personal Todo
Projects: completed_at

#### New Description

The replacement text [Edit] needs — supplied per call, normalized, and (unless it equals the current [Description], a no-op) written into the unit's [Description]. It is consumed by [Edit], not stored under this name.

Kind:         Parameter
Parameter of: Edit
Projects:     new_description

#### Now

The current wall-time reading the transitions stamp timestamps from, supplied to the pure transition by the host at the I/O seam (never read inside the transition, never supplied by the business caller).

Kind:         Parameter
Parameter of: Add
Projects:     now

#### Pending

The state of a recorded unit that is not yet completed — the one editable live state. A unit enters [Pending] on [Add] and leaves it on [Complete] (to [Done]) or [Delete].

Kind:      Member
Member of: the unit state
Role:      Outcome

#### Done

The state of a completed unit, not yet removed. A unit enters [Done] on [Complete] and leaves only on [Delete]; there is no [Done] → [Pending] transition.

Kind:      Member
Member of: the unit state
Role:      Outcome

#### Invalid Description

The refusal [Add] or [Edit] returns when the normalized [Description] is empty or exceeds the length cap. No unit is created or changed.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  invalid-description

#### Duplicate Active

The refusal [Add] or [Edit] returns when the normalized [Description] already belongs to a unit in [Pending] or [Done] (the active set). No unit is created or changed.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  duplicate-active

#### Not Known

The refusal [Edit], [Complete], or [Delete] returns when the supplied [Id] references no unit the system holds.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  not-known

#### Not Pending

The refusal [Complete] returns when the referenced unit is not in [Pending] (it is already [Done]).

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  not-pending

#### Not Editable

The refusal [Edit] returns when the referenced unit is not in [Pending] — necessarily [Done], since those are the only two live states.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  not-editable

#### Storage Failure

The refusal any writing action returns when the underlying store write fails after all preconditions pass. The unit is left in its prior state; the caller must retry.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

#### Duplicate Recent

The refusal a **composing pattern** returns when [Duplicate Prevention](./duplicate-prevention.md) reports the [Description] as recently seen — the *"buy milk twice in the same morning"* rejection. It is the composing pattern's outcome and the composing pattern's to pin: this atom's [Add] never raises it, and its signature block does not carry it (Closed vocabulary 21). The card is here because a reader of this atom meets the string in a composed deployment, not because this atom owns it.

Kind:      Member
Member of: the composing pattern's add rejection
Role:      Outcome
Projects:  duplicate-recent
Wire:      pinned

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Add]: #add
[Edit]: #edit
[Complete]: #complete
[Delete]: #delete
[Id]: #id
[Description]: #description
[Added At]: #added-at
[Last Edited At]: #last-edited-at
[Completed At]: #completed-at
[New Description]: #new-description
[Now]: #now
[Pending]: #pending
[Done]: #done
[Invalid Description]: #invalid-description
[Duplicate Active]: #duplicate-active
[Not Known]: #not-known
[Not Pending]: #not-pending
[Not Editable]: #not-editable
[Storage Failure]: #storage-failure
[Duplicate Recent]: #duplicate-recent

---

## Standards references

Personal Todo is a primitive, not a regulated business pattern. It has no direct ISO / IEEE / regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the conception of a "concept" as a composable, behavioral, freestanding unit of software design. The discipline of *not* absorbing concepts that belong to other concepts.
- **Eiffel's design-by-contract** — preconditions on `add`, `edit`, `complete`, `delete`.
- **Linear temporal logic** — Add-then-Pending and Complete-then-Done expressed as `until` properties.
- **Unicode Standard Annex #15** — NFC normalization for the description policy.

A formal-methods version of a similar concept exists in [concept-catalog](https://github.com/dpapathanasiou/concept-catalog/blob/main/concepts/todo.als), expressed in Alloy 6. The Alloy version uses fully opaque Task atoms (`var sig Task {}`) with no description, no identity-by-content, no edit, and no duplicate prevention; its operational principles cover `add`, `complete`, and `delete` over those atoms. Personal Todo is *informed by* that structure but is a distinct concept: it adds an `id`-as-identity model with description as a mutable property under uniqueness constraint, an `edit` action, timestamps, normalized comparison rules, and explicit Behavior / Feedback / Examples coverage. Recency-based duplicate prevention, initially absorbed into the spec on the first iteration, was extracted to a separate freestanding concept ([Duplicate Prevention](./duplicate-prevention.md)).

---

## Status

`grounded on Final Critique 4 — 2026-06-18` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-06-18
formal: not applicable — vote no 2026-06-03
last gate: 2026-06-18 — Final Critique 4, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/personal-todo.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the description policy as its own rule family, the eight invariant numbers unchanged, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan, and this atom is the corpus's simplest shape — the one a reader meets first.

NOTE: End of Personal Todo.
