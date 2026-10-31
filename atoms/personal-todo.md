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

Personal Todo is a single-person to-do list: one user records tasks, edits them while they are still open, marks them done, and deletes them. Every task gets a permanent internal identifier that never changes, so editing the wording of a task does not change which task it is. Each task is always in exactly one state — open (Pending) or finished (Done) — until it is deleted. No two tasks on the list, open or finished, can share the same wording, ignoring spaces at either end, and the same text typed two different ways (an accented letter entered as one character, or as a plain letter followed by an accent mark) still counts as a match. It is built for one person managing their own list — personal tasks, reading lists, grocery lists, goals — not for shared or delegated lists, which are handled by separate patterns that build on this one.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

One person, a list of things to do, and nothing else. The atom exists because every larger system that tracks work contains this shape and buries it: a unit is recorded, may be revised, is finished or abandoned, and leaves. Isolating it makes the additions visible as additions — an owner, a priority, a due date, a second actor are each a composing pattern rather than a field quietly added here. Two decisions carry the weight. A unit's identity is an opaque id, never its text, so revising the text does not make it a different unit; and the text is unique across every unit on the list, pending or done, so a list cannot silently hold *buy milk* twice. Everything else follows from those, including the thing the atom deliberately does not do: remember what was deleted.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a unit by the id.
Identity 2: The host MUST allocate an id at the atom's seam.
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
Identity 4: The business caller MUST NOT supply an id.
Identity 5: The atom MUST NOT reuse an id.
Identity 6: The atom MUST NOT identify a unit by the description.
Identity 7: The implementation MUST own the id's scheme.
```

NOTE: watch the allocation ban (Identity 3).

Term unit: one thing to do — the record this atom holds; recorded, revised, finished or abandoned.

Term id: the opaque value naming one unit — an [Id]; stable across sessions, unique for the system's life.

Term seam: the atom's I/O (input and output) boundary; the host injects the clock reading and the id here.

Term transition: the atom's evaluation of one call against the list.

Term business caller: the party whose action the call carries; never the source of an injected value.

NOTE: watch the seam citation (Term seam, Term transition, Term business caller).

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

### State

```
State 1: EVERY known unit MUST stand in EXACTLY ONE OF pending, done.
State 2: EVERY unit MUST carry id, description and addition instant.
State 3: A unit MAY carry last edit instant.
State 4: A done unit MUST carry completion instant.
State 5: [Add] MUST stamp addition instant from the injected now.
State 6: IF the normalized new description DOES NOT EQUAL the unit's description THEN [Edit] MUST stamp last edit instant from the injected now.
State 7: [Complete] MUST stamp completion instant from the injected now.
State 8: [Delete] MUST take the unit out of the list.
State 9: The atom MUST NOT offer a done-to-pending transition.
State 10: The atom MUST NOT hold a deleted unit.
```

Term unit state: pending | done — recorded and unfinished, or finished and unremoved.

Term addition instant: the instant the unit was recorded — an [Addition Instant].

Term last edit instant: the instant the unit's description last changed — a [Last Edit Instant]; absent until an edit lands.

Term completion instant: the instant the unit was finished — a [Completion Instant].

Term active set: the units whose unit state EQUALS pending together with the units whose unit state EQUALS done — what uniqueness ranges over.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 4: The deployment MUST supply the database PER Execution Contract Database 1 through 7 and Execution Contract Input 1.
Capability requirement 5: The deployment MAY declare the description cap.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Non-goal 16 owns it.
```

### Operations

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

read()
  answers every unit
```

```
Operation 1: [Add] MUST record EXACTLY ONE unit per successful call.
Operation 2: [Add] MUST stand the unit in pending.
Operation 3: [Add] MUST answer id.
Operation 4: IF the normalized description matches a unit in the active set THEN [Add] MUST answer duplicate-active.
Operation 5: IF the database refuses the write THEN [Add] MUST answer storage-failure.
Deleted: Operation 6. Execution Contract Database 3 owns it.
Operation 7: IF no unit EXISTS for the id THEN [Edit] MUST answer not-known.
Operation 8: IF the unit state EQUALS done THEN [Edit] MUST answer not-editable.
Operation 9: IF the unit state EQUALS pending AND the normalized new description matches another unit in the active set THEN [Edit] MUST answer duplicate-active.
Deleted: Operation 9a. Operation 32 and Operation 33 own it.
Operation 10: IF the unit state EQUALS pending AND the normalized new description EQUALS the unit's description THEN [Edit] MUST answer ok.
Deleted: Operation 11. Execution Contract Conformance 1 owns the admitted call's write.
Operation 12: IF the normalized new description EQUALS the unit's description THEN [Edit] MUST NOT stamp last edit instant.
Operation 13: IF the normalized new description DOES NOT EQUAL the unit's description THEN [Edit] MUST replace the unit's description.
Operation 14: [Edit] MUST leave the unit standing in pending.
Operation 15: IF no unit EXISTS for the id THEN [Complete] MUST answer not-known.
Operation 16: IF the unit state EQUALS done THEN [Complete] MUST answer not-pending.
Operation 17: [Complete] MUST stand the unit in done.
Operation 18: IF no unit EXISTS for the id THEN [Delete] MUST answer not-known.
Operation 19: [Delete] MUST take a pending unit out of the list.
Operation 20: [Delete] MUST take a done unit out of the list.
Operation 21: IF the database refuses the write THEN [Edit] MUST answer storage-failure.
Operation 22: IF the database refuses the write THEN [Complete] MUST answer storage-failure.
Operation 23: IF the database refuses the write THEN [Delete] MUST answer storage-failure.
Deleted: Operation 24. Execution Contract Read 4 owns it.
Deleted: Operation 25. Capability requirement 1 owns it.
Deleted: Operation 26. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 27. Execution Contract Logic confinement 3 owns it.
Operation 28: [Read] MUST answer EVERY unit, pending AND done.
Operation 29: [Read] MUST answer a unit's id, description, state, addition instant, last edit instant AND completion instant.
Operation 30: [Read] MUST NOT write.
Operation 31: [Read] MUST NOT refuse a call.
Operation 32: IF the unit state EQUALS pending AND the normalized new description DOES NOT EQUAL the unit's description AND the normalized new description EQUALS blank THEN [Edit] MUST answer invalid-description.
Operation 33: IF the unit state EQUALS pending AND the normalized new description DOES NOT EQUAL the unit's description AND the normalized new description EXCEEDS the description cap THEN [Edit] MUST answer invalid-description.
Operation 34: IF the unit state EQUALS pending AND the new description is malformed THEN [Edit] MUST answer invalid-description (Execution Contract Input 1).
```

Term new description: the text an edit offers for a unit — a [New Description]; normalized under the description policy.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the list |
|---|---|---|---|
| [Add] | description valid, no active match, database accepts | id | one unit lands in [Pending] (Operation 1, Operation 2) |
| [Add] | description blank, over the cap or malformed | [Invalid Description] | none (Description 4, Description 5, Description 9) |
| [Add] | description matches a live unit | [Duplicate Active] | none (Operation 4) |
| [Edit] | valid, different, no active match, database accepts | ok | description and last edit instant change (Operation 13, State 6) |
| [Edit] | same normalized text | ok | no field changes (Operation 10, Operation 12) |
| [Edit] | new description malformed, or blank or over the cap and different | [Invalid Description] | none (Operation 32, Operation 33, Operation 34) |
| [Edit] | new description matches another unit in the active set | [Duplicate Active] | none (Operation 9) |
| [Edit] | unit is done | [Not Editable] | none (Operation 8) |
| [Complete] | unit is pending | ok | [Pending] → [Done], completion instant stamped (Operation 17, State 7) |
| [Complete] | unit is done | [Not Pending] | none (Operation 16) |
| [Delete] | unit is pending or done | ok | the unit leaves; the id is retired (Operation 19, Operation 20, Identity 5) |
| any | id names nothing | [Not Known] | none (Operation 7, Operation 15, Operation 18) |
| any writing call | database refuses | [Storage Failure] | none (Operation 5, Operation 21 through 23; Execution Contract Read 4) |
| any | the database read fails | state-unavailable | none (Execution Contract Read 1, Execution Contract Read 3) |
| [Read] | the database answers the read | every unit, with its stored fields | none (Operation 28 through 31) |

### Invariants

- **Invariant 1 — Membership exclusivity.**
  ```
  Deleted: Invariant 1.1. State 1 owns it.
  ```
- **Invariant 2 — Add-then-Pending persistence.**
  ```
  Invariant 2.1: A recorded unit MUST stand in pending ONLY IF no [Complete] EXISTS for the unit AND no [Delete] EXISTS for the unit.
  ```
- **Invariant 3 — Complete-then-Done persistence.**
  ```
  Invariant 3.1: A completed unit MUST stand in done ONLY IF no [Delete] EXISTS for the unit.
  ```
- **Invariant 4 — Delete is terminal.**
  ```
  Invariant 4.1: A deleted unit's id MUST NOT stand in the list.
  Deleted: Invariant 4.2. Identity 5 owns id reuse for every id, deleted or not.
  ```
- **Invariant 5 — Edit preserves state.**
  ```
  Deleted: Invariant 5.1. Invariant 5.2 and Operation 8 own it.
  Invariant 5.2: [Edit] MUST NOT change a field other than description and last edit instant.
  ```
- **Invariant 6 — Active-set description uniqueness.**
  ```
  Invariant 6.1: Two units in the active set MUST NOT share a normalized description.
  ```
- **Invariant 7 — Timestamp monotonicity.**
  ```
  Invariant 7.1: IF last edit instant DOES NOT EQUAL blank THEN last edit instant MUST NOT PRECEDE addition instant.
  Invariant 7.2: IF completion instant DOES NOT EQUAL blank THEN completion instant MUST NOT PRECEDE addition instant.
  Invariant 7.3: IF last edit instant DOES NOT EQUAL blank AND completion instant DOES NOT EQUAL blank THEN completion instant MUST NOT PRECEDE last edit instant.
  ```
- **Invariant 8 — Id stability.**
  ```
  Deleted: Invariant 8.1. State 2 owns it.
  Invariant 8.2: An id MUST NOT change.
  Invariant 8.3: [Edit] MUST NOT change the id.
  ```

### Description policy

```
Description 1: The atom MUST trim a description's leading and trailing whitespace.
Description 2: The atom MUST normalize a description to Unicode normal form C.
Description 3: The atom MUST preserve a description's internal whitespace.
Description 4: IF the normalized description EQUALS blank THEN [Add] MUST answer invalid-description.
Description 5: IF the normalized description EXCEEDS the description cap THEN [Add] MUST answer invalid-description.
Description 6: The atom MUST compare two descriptions case-sensitively.
Description 7: The atom MUST compare two descriptions on the normalized form.
Description 8: The atom MUST show the normalized form.
Description 9: IF the description is malformed THEN [Add] MUST answer invalid-description (Execution Contract Input 1).
```

Term description: the text the person gives a unit — a [Description]; normalized before it enters the list and before any comparison.

Term description cap: the bound on a normalized description's length; 1024 codepoints where a deployment declares none.

## Examples

The same pattern, three personal-scope domains, identical mechanic. A fourth example walks the rejection paths.

### Personal task management

A user opens a notes app, types *"buy milk."* The system trims, NFC-normalizes (NFC: Normalization Form C, the Unicode standard's canonical composed form, which gives equivalent characters one standard byte sequence), returns id `t1`. The user marks `t1` done after the errand, then deletes `t1`. A week later, types *"buy milk"* again — accepted; new id `t2` is issued (no temporal memory in this pattern). Adds *"renew passport"* (id `t3`), edits it to *"renew passport before Italy trip"* the next day (still `t3`, [Last Edit Instant] updated), leaves it pending for six weeks, eventually deletes `t3` because they renewed via a different channel.

### Reading list

A user adds *"Essence of Software"* (id `b1`), finishes it three weeks later, marks it done, deletes it from the Done list. Adds *"TLA+ in Action"* (a book on TLA+, the Temporal Logic of Actions specification language; id `b2`), abandons it after fifty pages, deletes `b2`. Two days later, decides to retry — adds *"TLA+ in Action"* again — accepted with new id `b3` (no recency check in this pattern alone).

### Personal goal capture

A user adds *"call mom this week"* on Monday (id `g1`), completes `g1` Friday, deletes `g1`. Adds the same description the following Monday — accepted, id `g2`. Adds *"learn Python"* (id `g3`), edits it the next day to *"learn Python — finish first three Real Python tutorials"* to make the goal concrete. Same id `g3`, updated [Description], updated [Last Edit Instant].

### Rejection paths

The same user, exercising the rejection surface in one short sequence:

- Adds *"buy milk"* — accepted, id `r1`.
- Tries to add *"buy milk"* again immediately while `r1` is still in [Pending] — rejected as [Duplicate Active] (active-set uniqueness protects this case).
- Marks `r1` done. Tries to add *"buy milk"* once more while `r1` is in [Done] — rejected as [Duplicate Active] ([Done] counts toward active-set uniqueness).
- Tries to edit `r1` (currently in [Done]) — rejected as [Not Editable].
- Tries to add *"   "* (whitespace-only) — rejected as [Invalid Description] (empty after trim).
- Tries to add a 5,000-codepoint description — rejected as [Invalid Description] (exceeds default 1,024 limit).
- Adds *"café"* — accepted, id `r2`. Pastes *"café"* in NFD form (Normalization Form D, the decomposed form: `cafe` + combining acute) while `r2`'s description *"café"* in NFC form is in [Pending] — rejected as [Duplicate Active] (NFC normalization unifies the two forms).
- Tries to complete an unknown id — rejected as [Not Known].
- Deletes `r1`. Now *"buy milk"* is no longer in the active set; a fresh `add("buy milk")` would succeed with a new id (id `r3`).

This sequence covers four of the rejection reasons ([Invalid Description], [Duplicate Active], [Not Editable], [Not Known]) in a single thread of user action. The fifth reason, [Not Pending], is exercised separately — for example, attempting to [Complete] an id that is already [Done].

---

## Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given the list, with its committed versions (Execution Contract Generation acceptance 1), and the atom's own surface. This is the corpus's smallest atom and the reference implementation's first worked example, so the section is deliberately plain: every check is one reading of the list against one rule, and the external set is one line long because almost nothing here needs evidence the list does not carry.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY known unit standing in EXACTLY ONE OF pending, done (State 1).
Check 1.2: An auditor MUST find EVERY unit carrying id, description AND addition instant (State 2).
Check 1.3: An auditor MUST find EVERY done unit carrying completion instant (State 4).
Check 2.1: An auditor MUST find no deleted unit whose id IS IN the list (Invariant 4.1; Execution Contract Generation acceptance 1).
Check 2.2: An auditor MUST find no two units sharing an id across the list's committed versions (Identity 5; Execution Contract Generation acceptance 1).
Check 2.3: An auditor MUST find a unit's id unchanged across an edit (Invariant 8.3; Execution Contract Generation acceptance 1).
Check 3.1: An auditor MUST find no two units in the active set sharing a normalized description (Invariant 6.1).
Deleted: Check 3.2. Check 3.3 owns it.
Check 3.3: An auditor MUST find an edit changing no field beside description AND last edit instant (Invariant 5.2; Execution Contract Generation acceptance 1).
Check 3.4: An auditor MUST find no last edit instant stamped for an edit answering ok on an unchanged description (Operation 12; Execution Contract Generation acceptance 1).
Check 4.1: An auditor MUST find no unit whose last edit instant PRECEDES the unit's addition instant (Invariant 7.1).
Check 4.2: An auditor MUST find no unit whose completion instant PRECEDES the unit's addition instant (Invariant 7.2).
Check 4.3: An auditor MUST find no unit whose completion instant PRECEDES the unit's last edit instant (Invariant 7.3).
Deleted: Check 5.1. Execution Contract Read 4 owns it.
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the clock's monotonicity confirmed MUST read the deployment's own clock discipline (Invariant 7.1 through 7.3).
Deleted: External check 2. Execution Contract Database 1 owns it.
Deleted: External check 3. Execution Contract Database 2 owns it.
```

## Non-goals

```
Non-goal 1: The atom MUST NOT hold a second actor.
Non-goal 2: A deployment needing a shared list MUST compose Shared Todo.
Non-goal 3: The atom MUST NOT assign a unit to an actor.
Non-goal 4: The atom MUST NOT remember a deleted description.
Non-goal 5: A deployment needing a recency guard MUST compose Duplicate Prevention.
Non-goal 6: The atom MUST NOT restore a deleted unit.
Deleted: Non-goal 7. Execution Contract Database 5 owns it.
Non-goal 8: The atom MUST NOT reopen a done unit.
Non-goal 9: The atom MUST NOT regenerate a unit on a schedule.
Non-goal 10: The atom MUST NOT order units.
Non-goal 11: The atom MUST NOT hold a due date.
Non-goal 12: The atom MUST NOT hold a dependency between units.
Non-goal 13: The atom MUST NOT keep a description's history.
Non-goal 14: The atom MUST NOT resolve two concurrent calls on one unit.
Non-goal 15: The atom MUST NOT match descriptions case-insensitively.
Non-goal 16: A deployment needing a defensible timeline MUST compose a trusted timestamping pattern.
```

NOTE: the owners — [Shared Todo](../compositions/shared-todo.md) (Non-goal 1 through 3, Composition note 5); [Duplicate Prevention](./duplicate-prevention.md) and the composing pattern that answers [Duplicate Recent] (Non-goal 4, Non-goal 5, Composition note 2, Composition note 3; State 10); Execution Contract Database 5 (Non-goal 6); a history pattern (Non-goal 8, Non-goal 13; State 9); a recurrence pattern *(forthcoming)* (Non-goal 9); a priority and ordering pattern *(forthcoming)* (Non-goal 10); a due-date pattern *(forthcoming)* (Non-goal 11); a dependency pattern *(forthcoming)* (Non-goal 12); Execution Contract Database 2 (Non-goal 14); a wrapping pattern (Non-goal 15); Trusted Timestamping *(forthcoming)* (Non-goal 16).

Where the atom breaks down: any system with more than one actor; a system where *finished* is not binary; a system where the description is not a property worth constraining; a host that cannot make a transition atomic.

## Edge cases

### Concurrency on one unit

```
Concurrency 1: The atom MUST assume a linear sequence of calls from one actor.
Deleted: Concurrency 2. Execution Contract Database 1 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Re-adding a deleted description

```
Re-adding 1: The atom MUST accept a description equal to a deleted unit's description.
Re-adding 2: [Add] MUST answer a fresh id for such a unit.
```

## Composition notes

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern needing a recency guard MUST record a deleted description with Duplicate Prevention.
Composition note 3: A composing pattern needing a recency guard MUST NOT call [Add] BEFORE a Duplicate Prevention check.
Deleted: Composition note 4. Execution Contract Database 5 owns it.
Composition note 5: A composing pattern needing a shared list MUST compose Permissions and Assignment.
```

NOTE: composing patterns — [Shared Todo](../compositions/shared-todo.md). Forthcoming: Priority and Ordering, Task Dependencies, Recurring, Reopen and Revision.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a person; a unit; a call; the database; the list; an auditor.

Term records: unit — one thing to do, carrying id, description, addition instant, a unit state and, once they land, last edit instant and completion instant.

Term record verbs: call, identify, allocate, declare, supply, reuse, own, trim, normalize, preserve, answer, compare, show, stand, carry, stamp, take, offer, hold, record, replace, leave, write, read, match, change, set, share, assume, compose, remember, restore, reopen, regenerate, order, keep, resolve, assign, accept, check, precede, find, refuse.

Term value sets: unit state = pending | done.

Term bounds: description cap (the bound on a normalized description's length).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: now, unit, id, seam, transition, business caller, description, description cap, unit state, addition instant, last edit instant, completion instant, active set, new description.

#### Add

The behavior that records a new unit of work. It allocates a fresh [Id], normalizes the supplied [Description], stamps [Addition Instant], and places the unit in [Pending], returning the [Id].

Kind: Operation

#### Edit

The behavior that revises a [Pending] unit's [Description]. Where the normalized [New Description] differs from the description, it replaces the value and stamps [Last Edit Instant]; where it does not, the edit answers ok and changes no field. The unit's state and [Id] are unchanged.

Kind: Operation

#### Complete

The behavior that marks a [Pending] unit done, moving it [Pending] → [Done] and stamping [Completion Instant].

Kind: Operation

#### Delete

The behavior that removes a unit from the system entirely. Deletion is terminal; the [Id] is retired and not reused.

Kind: Operation

#### Read

The read-only query answering every unit in the list, pending and done, each with its stored fields, in no order the atom states, since the atom orders no units (Non-goal 10); a last edit instant or completion instant the unit does not carry is answered blank. It changes nothing and refuses nothing.

Kind: Operation

#### Id

The opaque, immutable identity of a unit, host-allocated at the I/O seam on [Add] and never changed. The unit's [Description] is a property under uniqueness constraint, not its identity — two units with the same [Description] still have different ids.

Kind:       Field
Field of:   Personal Todo
Projection: id

#### Description

The user-supplied text of a unit, normalized (trim + NFC) before it enters state. It is mutable via [Edit] while [Pending], unique across the active set ([Pending] ∪ [Done]), and a property of the unit rather than its identity.

Kind:       Field
Field of:   Personal Todo
Projection: description

#### Addition Instant

The wall-time a unit was created, stamped from the injected [Now] on [Add]. Immutable thereafter.

Kind:       Field
Field of:   Personal Todo
Projection: added_at

#### Last Edit Instant

The wall-time of a unit's most recent [Edit], stamped from the injected [Now]. Absent on a unit that has never been edited.

Kind:       Field
Field of:   Personal Todo
Projection: last_edited_at

#### Completion Instant

The wall-time a unit was marked done, stamped from the injected [Now] on [Complete]. Present only while the unit is [Done].

Kind:       Field
Field of:   Personal Todo
Projection: completed_at

#### New Description

The replacement text [Edit] needs — supplied per call, normalized, and (unless it equals the current [Description], a no-op) written into the unit's [Description]. It is consumed by [Edit], not stored under this name.

Kind:         Parameter
Parameter of: Edit
Projection:   new_description

#### Now

The current wall-time reading the transitions stamp timestamps from, supplied to the pure transition by the host at the I/O seam (never read inside the transition, never supplied by the business caller).

Kind:         Parameter
Parameter of: Add, Edit and Complete
Projection:   now

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

The refusal [Add] returns when the [Description] is malformed or the normalized [Description] is blank or exceeds the length cap, and [Edit], on a [Pending] unit, when the [New Description] is malformed or the normalized [New Description] is blank or exceeds the length cap and differs from the unit's own [Description]. No unit is created or changed.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-description

#### Duplicate Active

The refusal [Add] or [Edit] returns when the normalized [Description] already belongs to a unit in [Pending] or [Done] (the active set). No unit is created or changed.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: duplicate-active

#### Not Known

The refusal [Edit], [Complete], or [Delete] returns when the supplied [Id] references no unit the system holds.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Not Pending

The refusal [Complete] returns when the referenced unit is not in [Pending] (it is already [Done]).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-pending

#### Not Editable

The refusal [Edit] returns when the referenced unit is not in [Pending] — necessarily [Done], since those are the only two live states.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-editable

#### Storage Failure

The refusal any writing action returns when the underlying database write fails after all preconditions pass. The unit is left in its prior state, and the call may be retried.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

#### Duplicate Recent

The refusal a **composing pattern** returns when [Duplicate Prevention](./duplicate-prevention.md) reports the [Description] as recently seen — the *"buy milk twice in the same morning"* rejection. It is the composing pattern's outcome and the composing pattern's to pin: this atom's [Add] never raises it, and its signature block does not carry it (Closed vocabulary 21). The term entry is here because a reader of this atom meets the string in a composed deployment, not because this atom owns it.

Kind:       Member
Member of:  the composing pattern's add rejection
Role:       Outcome
Projection: duplicate-recent
Wire:       pinned

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Add]: #add
[Edit]: #edit
[Complete]: #complete
[Delete]: #delete
[Read]: #read
[Id]: #id
[Description]: #description
[Addition Instant]: #addition-instant
[Last Edit Instant]: #last-edit-instant
[Completion Instant]: #completion-instant
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

Personal Todo is a primitive, not a regulated business pattern. It has no direct ISO (International Organization for Standardization), IEEE (Institute of Electrical and Electronics Engineers) or regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the conception of a "concept" as a composable, behavioral, freestanding unit of software design. The discipline of *not* absorbing concepts that belong to other concepts.
- **Eiffel's design-by-contract** — preconditions on add, edit, complete, delete.
- **Linear temporal logic** — Add-then-Pending and Complete-then-Done expressed as `until` properties.
- **Unicode Standard Annex #15** — NFC normalization for the description policy.

A formal-methods version of a similar concept exists in [concept-catalog](https://github.com/dpapathanasiou/concept-catalog/blob/main/concepts/todo.als), expressed in Alloy 6. The Alloy version uses fully opaque Task atoms (`var sig Task {}`) with no description, no identity-by-content, no edit, and no duplicate prevention; its operational principles cover add, complete, and delete over those atoms. Personal Todo is *informed by* that structure but is a distinct concept: it adds an id-as-identity model with description as a mutable property under uniqueness constraint, an edit action, timestamps, normalized comparison rules, and explicit Behavior / Feedback / Examples coverage. Recency-based duplicate prevention, initially absorbed into the spec on the first iteration, was extracted to a separate freestanding concept ([Duplicate Prevention](./duplicate-prevention.md)).

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: not applicable — vote no 2026-06-03
last gate: 2026-10-31 — Final Critique 6 — foundational count 3, not clean, no sample

open: none
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/personal-todo.md`; the rounds and the migration that got it here are in [its history](./personal-todo.hist.md).

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 4), and the five rules that restated them tombstoned to their owner — Concurrency 2, every transition atomic, and External check 2, the auditor's evidence of that atomicity, to Store 1; Concurrency 3, a deployment running two clients composing a concurrency-resolution pattern, and External check 3, the auditor's evidence of that pattern, to Store 2; Operation 6, no unit recorded by an [Add] that answers storage-failure, to Store 3; rules 111 to 107. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. Two clients' calls on one unit, all the page gave a concurrency-resolution pattern to resolve, are serialized by Store 2 for every deployment: the later call reads what the earlier committed, and the active-set duplicate check reads inside the transaction that writes. A refused call leaving the unit as the call found it stays the atom's own (Operation 24), as do the linear sequence of one actor's calls the atom assumes (Concurrency 1), the atom itself resolving no two concurrent calls (Non-goal 14) and the id that never changes (Invariant 8.2). The atom keeps no history of a unit (State 10, Non-goal 13), its checks compare the auditor's own reads, and it orders no units (Non-goal 10), so it cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.
- **2026-10-20 — Undo History retired, and restoration is the store's history.** *Chose:* Non-goal 7, a deployment needing restoration composing Undo History, and Composition note 4, a composing pattern needing restoration appending a deleted unit to an Event Log, tombstoned to Execution Contract Store 5; rules 107 to 105. *Over:* restoration through a composition that kept its own copy of every deleted unit in an event log and replayed it. *Because:* the maintainer ruled 2026-10-20 that Undo History retires: Store 5 keeps every committed version of a record readable, so an undone deletion comes back with its id, timestamps and description, and no composing pattern needs a copy of its own. The atom itself still restores nothing (Non-goal 6). What the atom does for its domain is unchanged.
- **2026-10-22 — An edit resubmitting a unit's own text is a no-op under any cap, and an edit's state is held by the rules of the edit.** *Chose:* Operation 9a held to a new description that differs from the unit's own, with Description 4 and Description 5 naming [Add], so an [Edit] that resubmits a unit's text answers ok, writes nothing and stamps nothing, though a deployment has since lowered the description cap below the stored text; Invariant 5.1, that an edited unit stands in pending, deleted to Invariant 5.2 and Operation 8, and Check 3.2, which tested it, to Check 3.3. *Over:* two rules obliging invalid-description and ok on one call; and a property of every reachable state that a unit edited and then completed breaks, with a check that every conforming list holding such a unit fails. *Because:* Final Critique 5 found both. The case table already answered every same-text edit ok, and under the method's 2026-10-08 rule a rule a lawful state breaks is deleted to the rules that already hold that state: [Edit] lands only on a pending unit (Operation 8) and changes no field beside description and last edit instant (Invariant 5.2), the unit state among them. Smaller fixes rode with them: Invariant 7.1 through 7.3 compare instants with PRECEDES (GRACE-lang Earned vocabulary 18), and Check 4.1 through 4.3 read only a unit carrying the instants they compare; Check 1.1 in Invariant 1.1's words; the Now entry names every action that stamps from now; acronyms glossed at first use; rules 105 to 103. What each action answers and writes is unchanged except on the one call the two rules had split.
- **2026-10-31 — What a call writes is the contract's.** *Chose:* Operation 11, that an [Edit] resubmitting a unit's text writes nothing, deleted to Execution Contract Conformance 1, so that edit writes the unit unchanged, as every admitted call does, and answers storage-failure where the database refuses the write; Operation 24, that a refused call leaves the unit as it found it, and Check 5.1, which tested it, deleted to Execution Contract Read 4. *Over:* the page saying for itself what its calls write, against the pipeline's Step 3 in the first case and restating Read 4 in the second. *Because:* Final Critique 6 found that no build could obey both Operation 11 and the pipeline, which writes on every admitted call, and that no record names a refused call, so Check 5.1 passed every deployment, one writing on a refused call included. The 2026-10-22 entry's *writes nothing* and the 2026-10-20 entry's Operation 24 came before Read 4 (2026-10-22). Smaller fixes rode with them: [Edit]'s invalid-description rests on stated conditions (Operation 32 through 34) where Operation 9a leaned on rules naming [Add], and a malformed description answers it on both actions (Description 9, Operation 34); Invariant 1.1 deleted to State 1, Invariant 8.1 to State 2 and Identity 3 to Execution Contract Logic confinement 3; the checks read the committed versions (Execution Contract Generation acceptance 1); the description cap is the deployment's to declare (Capability requirement 5); rules 103 to 101. What each action answers is unchanged except where the page had said two things or nothing: a same-text edit whose write the database refuses, an edit's blank or over-cap text, and a malformed description.

</details>

NOTE: End of Personal Todo.
