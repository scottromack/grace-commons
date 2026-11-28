---
title: Task
id: 52
audience: common
---

# Task

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Task keeps the tasks of a list: it records a task in one list, edits it while it is still open, marks it done and saves who did it, and deletes it, or deletes every task of a list when the list ends. Every task gets a permanent task id that never changes, so editing the wording of a task does not change which task it is. Each task is always in exactly one state — open (Pending) or finished (Done) — until it is deleted. No two tasks in one list, open or finished, can share the same wording, ignoring whitespace at either end but not a difference of capital letters (*Buy milk* and *buy milk* are two tasks), and the same text typed two different ways (an accented letter entered as one character, or as a plain letter followed by an accent mark) still counts as a match. Reading a list answers its open tasks and the tasks finished within a window back from now, a week where the call names none. The atom is given a list id and makes none, and it is given the completer and judges no one.

<details markdown="block">
<summary>WHY</summary>

A list of things to do, and nothing else. The atom exists because every larger system that tracks work contains this shape and buries it: a task is recorded, may be revised, is finished or abandoned, and leaves. Isolating it makes the additions visible as additions — an owner, a priority, a due date, a second actor are each another job rather than a field quietly added here. Three decisions carry the weight. A task's identity is an opaque task id, never its text, so revising the text does not make it a different task; the text is unique across every task in one list, pending or done, so a list cannot silently hold *buy milk* twice; and a task belongs to one list, whose list id the task carries and the atom never makes, because a list is its author's and the atom keeps only the tasks in it (Scott, 2026-11-25 9:15 AM Central, from the to-do design). Everything else follows from those, including the thing the atom deliberately does not do: remember what was deleted.

</details>

## What it keeps

### The tasks

Term task: one thing to do in one list — the record this atom holds; recorded, revised or finished, until it is deleted — a [Task Record]; one for each task id.

#### Task Record

Holds the task id, the list id, the description, the addition instant, the last edit instant, the completion instant and the completer. A task id that no record carries names no task, and a deleted task's record has ended.

Kind: Type

```
Identity 1: The atom MUST identify a task by the task id.
Identity 2: The host MUST allocate a task id for [Add] at the atom's seam.
Identity 4: [Add] MUST NOT take a task id from the business caller.
Identity 5: The atom MUST NOT reuse a task id.
Identity 6: The atom MUST NOT identify a task by the description.
Identity 7: The implementation MUST own the task id's scheme.
```

NOTE: watch the allocation ban (Execution Contract Logic confinement 3).

Term description: the text the person gives a task — a [Description]; normalized before it enters a list and before any comparison.

#### Description

The user-supplied text of a task, normalized (trim + NFC) before it enters state. It is mutable via [Edit] while [Pending], unique across the active set ([Pending] ∪ [Done]) of its list, and a property of the task rather than its identity.

Kind:       Field
Field of:   Task Record
Projection: description

Term addition instant: the instant the task was recorded — an [Addition Instant].

#### Addition Instant

The wall-time a task was created, stamped from the injected [Now] on [Add]. Immutable thereafter.

Kind:       Field
Field of:   Task Record
Projection: added_at

Term last edit instant: the instant the task's description last changed — a [Last Edit Instant]; absent until a change of description lands.

#### Last Edit Instant

The wall-time of the most recent [Edit] that changed a task's description, stamped from the injected [Now]. Absent on a task whose description has never changed.

Kind:       Field
Field of:   Task Record
Projection: last_edited_at

Term completion instant: the instant the task was finished — a [Completion Instant].

#### Completion Instant

The wall-time a task was marked done, stamped from the injected [Now] on [Complete]. Present only while the task is [Done].

Kind:       Field
Field of:   Task Record
Projection: completed_at

Term completer: the actor id of the party who finished the task — a [Completer]; the atom reads nothing in it.

#### Completer

Set by [Complete] from its input (Execution Contract Input 4) and held as supplied: this atom declares no reference, so Execution Contract Logic confinement 13 canonicalizes nothing in it; keeping the same actor id for one party across every other record that names that party is the app's. Present only while the task is [Done].

Kind:       Field
Field of:   Task Record
Projection: completed_by

Term task state: pending | done — recorded and unfinished, or finished and unremoved.

#### Pending

The state of a recorded task that is not yet completed — the one editable live state. A task enters [Pending] on [Add] and leaves it on [Complete] (to [Done]), [Delete] or [Delete List Tasks].

Kind:       Member
Member of:  the task state
Role:       Outcome
Projection: pending

#### Done

The state of a completed task, not yet removed. A task enters [Done] on [Complete] and leaves only on [Delete] or [Delete List Tasks]; there is no [Done] → [Pending] transition.

Kind:       Member
Member of:  the task state
Role:       Outcome
Projection: done

Term active set: of one list, the tasks that carry the list's list id and whose task state EQUALS pending together with those whose task state EQUALS done — what uniqueness ranges over.

```
State 1: EVERY known task MUST stand in EXACTLY ONE OF pending, done.
State 2: EVERY task MUST carry task id, description and addition instant.
State 3: A task MAY carry last edit instant.
State 4: A done task MUST carry completion instant.
State 5: [Add] MUST stamp addition instant from the injected now.
State 6: IF the normalized new description DOES NOT EQUAL the task's description THEN [Edit] MUST stamp last edit instant from the injected now.
State 7: [Complete] MUST stamp completion instant from the injected now.
State 9: The atom MUST NOT offer a done-to-pending transition.
State 10: The atom MUST NOT hold a deleted task.
State 11: EVERY task MUST carry list id.
State 12: A done task MUST carry completer.
```

## What people do

### Every action

```
Operation 35: IF the task id is malformed THEN [Edit] MUST answer not-known (Execution Contract Input 1).
Operation 36: IF the task id is malformed THEN [Complete] MUST answer not-known (Execution Contract Input 1).
Operation 37: IF the task id is malformed THEN [Delete] MUST answer not-known (Execution Contract Input 1).
Operation 48: [Add], [Edit], [Complete] AND [Delete] MUST append one task events record through the atom's journal need for EVERY admitted call.
```

NOTE: watch the untyped input (Operation 35, Operation 36, Operation 37).

NOTE: an admitted [Add] answers task id, and an admitted [Edit], [Complete], [Delete] or [Delete List Tasks] answers ok, the one answer each signature block gives (Closed vocabulary 21, Closed vocabulary 22, Closed vocabulary 25), so no operation restates either but Operation 10, which says an unchanged description within the cap answers ok, and Operation 51, which says the same of [Delete List Tasks] so that its case rows can cite it.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the tasks |
|---|---|---|---|
| [Edit], [Complete] or [Delete] | task id names nothing, or is malformed | [Not Known] | none (Operation 7, Operation 15, Operation 18, Operation 35 through 37) |
| any writing call | database refuses | [Storage Failure] | none (Execution Contract Read 4) |
| any | the database read fails | state-unavailable | none (Execution Contract Read 1, Execution Contract Read 3) |
| any admitted call of [Add], [Edit], [Complete] or [Delete] | the database accepts | the call's answer | one task events record appended (Operation 48) |

#### Not Known

The refusal [Edit], [Complete], [Delete] or [Read Task] returns when the supplied task id references no task the system holds or is malformed.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Invalid Description

The refusal [Add] returns when the [Description] is malformed, exceeds the length cap as the call carries it, or is blank once normalized, and [Edit], on a [Pending] task, when the [New Description] is malformed or exceeds the length cap as the call carries it, or, its normalized form differing from the task's own [Description], is blank once normalized. No task is created or changed.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-description

#### Duplicate Active

The refusal [Add] or [Edit] returns when the normalized [Description] already belongs to a task in the active set of the task's list ([Pending] or [Done]). No task is created or changed.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: duplicate-active

#### Storage Failure

The refusal any writing action returns when the underlying database write fails after all preconditions pass. The task is left in its prior state, and the call may be retried; a retry of a call whose answer was lost meets what that call left (Execution Contract Error model 1).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Add

The behavior that records a new task of work in one list. It allocates a fresh task id, carries the list id the call gives, normalizes the supplied [Description], stamps [Addition Instant], and places the task in [Pending], returning the task id.

Kind: Operation

```
add(list_id, description)
  answers task id
  refuses invalid-list-id | invalid-description | duplicate-active | storage-failure
```

```
Operation 1: [Add] MUST record EXACTLY ONE task per successful call, the task carrying the normalized description.
Operation 2: [Add] MUST stand the task in pending.
Operation 4: IF the normalized description matches a task in the active set of the list id the call carries THEN [Add] MUST answer duplicate-active.
Operation 38: [Add] MUST give the task the list id the call carries.
Operation 39: IF the list id EQUALS blank THEN [Add] MUST answer invalid-list-id.
Operation 40: IF the list id is malformed THEN [Add] MUST answer invalid-list-id (Execution Contract Input 1).
```

| Call | Case | Answer | Effect on the tasks |
|---|---|---|---|
| [Add] | list id and description valid, no active match in the list, database accepts | task id | one task lands in [Pending], carrying the list id (Operation 1, Operation 2, Operation 38) |
| [Add] | list id blank or malformed | [Invalid List Id] | none (Operation 39, Operation 40) |
| [Add] | description blank, over the cap or malformed | [Invalid Description] | none (Description 4, Description 5, Description 9) |
| [Add] | description matches a task in the list's active set | [Duplicate Active] | none (Operation 4) |

- `add("l1", "buy milk")` — answers a task id, say `t1`: the task stands in [Pending] in list `l1`.
- `add("l2", "buy milk")` — answers another task id, `t2`: the active set of `l2` holds no match, so the same wording stands in two lists (Operation 4).
- `add("", "buy milk")` — rejected as [Invalid List Id].

#### Invalid List Id

The refusal [Add] returns when the list id is blank or malformed (Operation 39, Operation 40). No task is created.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-list-id

#### Duplicate Recent

The refusal a **composing pattern** returns when its recency guard reports the [Description] as recently seen — the *"buy milk twice in the same morning"* rejection. It is the composing pattern's outcome and the composing pattern's to pin: this atom's [Add] never raises it, and its signature block does not carry it (Closed vocabulary 21). The term entry is here because a reader of this atom meets the string in a composed deployment, not because this atom owns it.

Kind:       Member
Member of:  the composing pattern's add rejection
Role:       Outcome
Projection: duplicate-recent
Wire:       pinned

### Edit

The behavior that revises a [Pending] task's [Description]. Where the normalized [New Description] differs from the description, it replaces the value and stamps [Last Edit Instant]; where it does not and the call is within the cap, the edit answers ok and changes no field. The task's state, task id and list id are unchanged.

Kind: Operation

```
edit(task_id, new_description)
  answers ok
  refuses not-known | not-editable | invalid-description | duplicate-active | storage-failure
```

```
Operation 7: IF no task EXISTS for the task id THEN [Edit] MUST answer not-known.
Operation 8: IF the task state EQUALS done THEN [Edit] MUST answer not-editable.
Operation 9: IF the task state EQUALS pending AND the normalized new description matches another task in the active set of the task's list THEN [Edit] MUST answer duplicate-active.
Operation 10: IF the task state EQUALS pending AND the normalized new description EQUALS the task's description AND the new description the call carries DOES NOT EXCEED the description cap AND the new description is not malformed THEN [Edit] MUST answer ok.
Operation 12: IF the normalized new description EQUALS the task's description THEN [Edit] MUST NOT stamp last edit instant.
Operation 13: IF the normalized new description DOES NOT EQUAL the task's description THEN [Edit] MUST replace the task's description with the normalized new description.
Operation 14: [Edit] MUST leave the task standing in pending.
Operation 32: IF the task state EQUALS pending AND the normalized new description DOES NOT EQUAL the task's description AND the normalized new description EQUALS blank THEN [Edit] MUST answer invalid-description.
Operation 33: IF the task state EQUALS pending AND the new description the call carries EXCEEDS the description cap THEN [Edit] MUST answer invalid-description (Execution Contract Input 2).
Operation 34: IF the task state EQUALS pending AND the new description is malformed THEN [Edit] MUST answer invalid-description (Execution Contract Input 1).
```

Term new description: the text an edit offers for a task — a [New Description]; normalized under the description policy.

#### New Description

The replacement text [Edit] needs — supplied per call, normalized, and (unless it equals the current [Description], a no-op) written into the task's [Description]. It is consumed by [Edit], not stored under this name.

Kind:         Parameter
Parameter of: Edit
Projection:   new_description

| Call | Case | Answer | Effect on the tasks |
|---|---|---|---|
| [Edit] | task is pending, new description valid, different, no active match in the list, database accepts | ok | description and last edit instant change, no other field and not the task id (Operation 13, State 6, Invariant 5.2, Invariant 8.2, Invariant 8.3) |
| [Edit] | task is pending, same normalized text, within the cap and not malformed | ok | no field changes (Operation 10, Operation 12) |
| [Edit] | task is pending, new description malformed, blank and different, or over the cap | [Invalid Description] | none (Operation 32, Operation 33, Operation 34) |
| [Edit] | task is pending, new description matches another task in its list's active set | [Duplicate Active] | none (Operation 9) |
| [Edit] | task is done, whatever the new description | [Not Editable] | none (Operation 8) |

#### Not Editable

The refusal [Edit] returns when the referenced task is not in [Pending] — necessarily [Done], since those are the only two live states.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-editable

### Complete

The behavior that marks a [Pending] task done, moving it [Pending] → [Done], stamping [Completion Instant] and saving the [Completer]. The first check-off wins: a task already [Done] answers not-pending and keeps the completer it has.

Kind: Operation

```
complete(task_id, completer)
  answers ok
  refuses invalid-completer | not-known | not-pending | storage-failure
```

```
Operation 15: IF no task EXISTS for the task id THEN [Complete] MUST answer not-known.
Operation 16: IF the task state EQUALS done THEN [Complete] MUST answer not-pending.
Operation 17: [Complete] MUST stand the task in done.
Operation 41: [Complete] MUST give the task the completer the call carries.
Operation 42: IF the completer EQUALS blank THEN [Complete] MUST answer invalid-completer.
Operation 43: IF the completer is malformed THEN [Complete] MUST answer invalid-completer (Execution Contract Input 1).
```

| Call | Case | Answer | Effect on the tasks |
|---|---|---|---|
| [Complete] | task is pending, completer valid | ok | [Pending] → [Done], completion instant stamped, completer saved; the task id stands (Operation 17, State 7, Operation 41, Invariant 8.2) |
| [Complete] | task is done | [Not Pending] | none, the first completer stands (Operation 16) |
| [Complete] | completer blank or malformed | [Invalid Completer] | none (Operation 42, Operation 43) |

- `complete("t1", "a1")` — answers ok: `t1` stands in [Done], completer `a1`.
- `complete("t1", "a2")` — rejected as [Not Pending]: `a1` checked it off first, and stays the completer.

#### Invalid Completer

The refusal [Complete] returns when the completer is blank or malformed (Operation 42, Operation 43). No task is changed.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-completer

#### Not Pending

The refusal [Complete] returns when the referenced task is not in [Pending] (it is already [Done]).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-pending

### Delete

The behavior that removes a task from the system entirely. Deletion is terminal; the task id is retired and not reused.

Kind: Operation

```
delete(task_id)
  answers ok
  refuses not-known | storage-failure
```

```
Operation 18: IF no task EXISTS for the task id THEN [Delete] MUST answer not-known.
Operation 19: [Delete] MUST take a pending task out of the tasks.
Operation 20: [Delete] MUST take a done task out of the tasks.
```

| Call | Case | Answer | Effect on the tasks |
|---|---|---|---|
| [Delete] | task is pending or done | ok | the task leaves; its task id is not reused (Operation 19, Operation 20, Identity 5) |

### Delete List Tasks

The behavior that removes every task of one list, pending and done, as [Delete] removes each; the action the list id need's on end names, which the app calls when an action the meeting offer's ends names ends the list (Needs). A list id no task carries is left as it is. Answers ok.

Kind: Operation

```
delete_list_tasks(list_id)
  answers ok
  refuses storage-failure
```

```
Operation 50: [Delete List Tasks] MUST take EVERY task carrying the list id out of the tasks, pending AND done.
Operation 51: [Delete List Tasks] MUST answer ok.
Operation 52: IF no task carries the list id THEN [Delete List Tasks] MUST NOT write.
Operation 53: IF a task carries the list id THEN [Delete List Tasks] MUST append one task events record through the atom's journal need for EVERY task the call takes out.
```

| Call | Case | Answer | Effect on the tasks |
|---|---|---|---|
| [Delete List Tasks] | the list carries tasks | ok (Operation 51) | every task of the list leaves, each task id not reused (Operation 50, Identity 5), and one task events record is appended for each (Operation 53) |
| [Delete List Tasks] | no task carries the list id | ok (Operation 51) | none, no write (Operation 52) |

Each task the call takes out ends a task id, so the app calls the on end of every need on the task id that Task's offer serves for each (Bonds Key 3): the two-level case, which Bonds Key 7 leaves order-free.

### Read

The read-only query answering one list's tasks: every pending task of the list, and every done task of it whose completion instant lies inside the window back from now, each with its stored fields, in the order Execution Contract Read 5 gives (addition instant, then task id ascending), since the atom orders no tasks (Non-goal 10); a last edit instant, completion instant or completer a task does not carry is answered blank. It changes nothing and refuses no call; where the database read fails it answers state-unavailable (Execution Contract Read 1). A list id that no task carries answers no tasks, a blank one, one over its cap or one that is no string included, the pattern's own answer standing in place of Query 5's (Execution Contract Query 5).

Kind: Operation

```
read(list_id, optional window)
  answers tasks
```

```
Operation 28: IF the window the call carries or takes is not malformed THEN [Read] MUST answer EVERY pending task that carries the list id the call carries.
Operation 29: IF [Read] answers a task THEN [Read] MUST answer the task's task id, description, task state, addition instant, last edit instant, completion instant AND completer.
Operation 30: [Read] MUST NOT write.
Operation 44: IF the call omits the optional window THEN [Read] MUST take the window as the default window.
Operation 45: IF the window the call carries or takes is not malformed AND a done task carries the list id the call carries AND the task's completion instant DOES NOT PRECEDE the window start THEN [Read] MUST answer the task.
Operation 46: IF the window the call carries or takes is not malformed AND a done task's completion instant PRECEDES the window start THEN [Read] MUST NOT answer the task.
Operation 47: IF no task carries the list id the call carries THEN [Read] MUST answer no tasks.
Operation 49: IF the window the call carries is malformed THEN [Read] MUST answer no tasks.
```

Term window: the length of time back from now within which a done task is answered, a duration, a length of time that is never below zero, so a window that is not blank and is not a duration, and a window below zero, are malformed, and a blank window is omitted (GRACE-lang Earned vocabulary 22) and takes the default window (Operation 44) — a [Window]; the call may carry one.

#### Window

The optional input of [Read]: how far back from now a done task's completion instant may lie for the task to be answered.

Kind:         Parameter
Parameter of: Read
Projection:   window

Term window start: (now - the window) — the instant that lies the window before now, where now is the call's one clock reading (Execution Contract Logic confinement 11), taken before the database read (Execution Contract Logic confinement 20); the same for every task of one call.

| Call | Case | Answer | Effect on the tasks |
|---|---|---|---|
| [Read] | the database answers the read and the window is not malformed | the list's pending tasks and its done tasks inside the window, with their stored fields | none (Operation 28 through 30, Operation 45, Operation 46) |
| [Read] | the call omits the window | as above, the window the default window | none (Operation 44) |
| [Read] | a done task's completion instant lies before the window start | the task is left out | none (Operation 46) |
| [Read] | no task carries the list id, or the window is malformed | no tasks | none (Operation 47, Operation 49, Operation 30) |

- `read("l1")` — answers the open tasks of `l1` and the ones finished in the last week, each with its completer.
- `read("l1", 1 day)` — the same with the window narrowed to one day: a task finished two days ago is left out.

### Read Task

The read that answers one task by its task id, pending or done, with its stored fields: the existence read Task's key offer names (Offers; Bonds Key 26). It writes nothing; a task id no task carries answers not-known, and so does a malformed one, the pattern's own answer standing in place of Query 5's (Execution Contract Query 5).

Kind: Operation

```
read_task(task_id)
  answers task
  refuses not-known
```

```
Operation 54: IF no task carries the task id THEN [Read Task] MUST answer not-known.
Operation 55: [Read Task] MUST answer the task's task id, list id, description, addition instant AND task state.
Operation 57: [Read Task] MUST answer EVERY last edit instant, completion instant AND completer the task carries.
Operation 56: [Read Task] MUST NOT write.
Operation 58: IF the task id is malformed THEN [Read Task] MUST answer not-known (Execution Contract Query 5).
```

| Call | Case | Answer | Effect on the tasks |
|---|---|---|---|
| [Read Task] | a task carries the task id | the task, with its stored fields | none (Operation 55 through 57) |
| [Read Task] | no task carries the task id, or the task id is malformed | [Not Known] | none (Operation 54, Operation 56, Operation 58) |

## What is and what should never be (Invariants)

- **Invariant 1 — Membership exclusivity.**
- **Invariant 2 — Add-then-Pending persistence.**
  ```
  Invariant 2.1: A recorded task MUST stand in pending ONLY IF no [Complete] EXISTS for the task AND no [Delete] EXISTS for the task.
  ```
- **Invariant 3 — Complete-then-Done persistence.**
  ```
  Invariant 3.1: A completed task MUST stand in done ONLY IF no [Delete] EXISTS for the task.
  ```
- **Invariant 4 — Delete is terminal.**
  ```
  Invariant 4.1: A deleted task's task id MUST NOT stand in the tasks.
  ```
- **Invariant 6 — Active-set description uniqueness.**
  ```
  Invariant 6.1: Two tasks in one list's active set MUST NOT share a normalized description.
  ```
- **Invariant 7 — Timestamp monotonicity.**
  ```
  Invariant 7.1: IF last edit instant DOES NOT EQUAL blank THEN last edit instant MUST NOT PRECEDE addition instant.
  Invariant 7.2: IF completion instant DOES NOT EQUAL blank THEN completion instant MUST NOT PRECEDE addition instant.
  Invariant 7.3: IF last edit instant DOES NOT EQUAL blank AND completion instant DOES NOT EQUAL blank THEN completion instant MUST NOT PRECEDE last edit instant.
  ```
- **Invariant 5 — Edit preserves state.**
  ```
  Invariant 5.2: [Edit] MUST NOT change a field other than description and last edit instant.
  ```
- **Invariant 8 — Task id stability.**
  ```
  Invariant 8.2: A task id MUST NOT change.
  Invariant 8.3: [Edit] MUST NOT change the task id.
  ```
- **Invariant 9 — A task stays in its list.**
  ```
  Invariant 9.1: A task's list id MUST NOT change between two versions of the task.
  ```

## When something happens

### Concurrency on one task

```
Concurrency 1: The atom MUST assume a linear sequence of calls from one actor.
```

### Re-adding a deleted description

```
Re-adding 1: The atom MUST accept a description equal to a deleted task's description.
Re-adding 2: [Add] MUST answer a fresh task id for such a task.
```

## While something is so

### Description policy

```
Description 1: The atom MUST trim a description's leading and trailing white space (the grammar's Term blank).
Description 2: The atom MUST normalize a description to Unicode normal form C.
Description 3: The atom MUST preserve a description's internal white space as Description 2's normal form leaves the white space.
Description 4: IF the normalized description EQUALS blank THEN [Add] MUST answer invalid-description.
Description 5: IF the description the call carries EXCEEDS the description cap THEN [Add] MUST answer invalid-description (Execution Contract Input 2).
Description 6: The atom MUST compare two descriptions with letter case kept.
Description 7: The atom MUST compare two descriptions on the normalized form.
Description 8: The atom MUST show the normalized form.
Description 9: IF the description is malformed THEN [Add] MUST answer invalid-description (Execution Contract Input 1).
```

NOTE: the white space Description 1 trims is the code points with the Unicode White_Space property, as GRACE-lang Term blank gives it.

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 4: The deployment MUST supply the database PER Execution Contract Database 1 through 7 and Execution Contract Input 1.
Capability requirement 5: The deployment MAY declare the description cap.
```

Term seam: the atom's I/O (input and output) boundary; the host injects the clock reading and, for [Add], the task's task id here.

Term transition: the atom's evaluation of one call against the tasks.

Term business caller: the party whose action the call carries; never the source of an injected value.

NOTE: watch the seam citation (Term seam, Term transition, Term business caller).

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

#### Now

The current wall-time reading the transitions stamp timestamps from and [Read] measures its window from, supplied to the pure transition by the host at the I/O seam (never read inside the transition, never supplied by the business caller).

Kind:         Parameter
Parameter of: Add, Edit, Complete and Read
Projection:   now

Term description cap: the bound on a description's length as the call carries it, before it is normalized (Execution Contract Input 2); 1024 codepoints where a deployment declares none.

NOTE: watch the cap's measure (Term description cap, Term bounds).

Term default window: the window [Read] takes where the call omits one, seven days of twenty-four hours each; a call may carry another window (Scott, 2026-11-25 9:11 AM Central, "Make the default a week").

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice. [Add], [Edit], [Complete], [Delete], [Delete List Tasks], [Read] and [Read Task] take no caller and check none (Non-goal 1): who may act on a task is the app's permission, gated before the call.

Term need key: key list id; pairs tasks; on end Delete List Tasks.

Term need key: key actor id; pairs completers.

Term need journal: records task events; calls append; arms event_id.

## Offers

Term offer key: key task id; carried by tasks; ends Delete, Delete List Tasks; calls Read Task.

## Left to others

```
Non-goal 1: The atom MUST NOT judge who acts: the atom carries the completer the call gives and checks no one.
Non-goal 2: The atom MUST NOT tell a second actor's standing in a list.
Non-goal 3: The atom MUST NOT assign a task to an actor.
Non-goal 4: The atom MUST NOT remember a deleted description.
Non-goal 5: The atom MUST NOT keep a guard against a description seen a short time before.
Non-goal 6: The atom MUST NOT restore a deleted task.
Non-goal 8: The atom MUST NOT reopen a done task.
Non-goal 9: The atom MUST NOT regenerate a task on a schedule.
Non-goal 10: The atom MUST NOT keep an order of tasks other than the answer order of Execution Contract Read 5.
Non-goal 11: The atom MUST NOT hold a due date.
Non-goal 12: The atom MUST NOT hold a dependency between tasks.
Non-goal 13: The atom MUST NOT keep a description's history.
Non-goal 14: The atom MUST NOT resolve two concurrent calls on one task.
Non-goal 15: The atom MUST NOT match descriptions with letter case ignored.
Non-goal 16: The atom MUST NOT keep a defensible timeline of a task's instants.
```

NOTE: the owners — the app's permission, gated before the call (Non-goal 1); the app's own rule for a shared list (Non-goal 2); the atom that holds who is responsible (Non-goal 3); a recency guard and the composing pattern that answers [Duplicate Recent] (Non-goal 4, Non-goal 5, Composition note 2, Composition note 3; State 10); Execution Contract Database 5 (Non-goal 6); a history pattern *(forthcoming)* (Non-goal 8, Non-goal 13; State 9); a recurrence pattern *(forthcoming)* (Non-goal 9); the atom that keeps an order (Non-goal 10); a due-date pattern *(forthcoming)* (Non-goal 11); a dependency pattern *(forthcoming)* (Non-goal 12); Execution Contract Database 2 (Non-goal 14); a wrapping pattern *(forthcoming)* (Non-goal 15); a timestamping pattern *(forthcoming)* (Non-goal 16).

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern needing a recency guard MUST record a deleted description with the guard.
Composition note 3: A composing pattern needing a recency guard MUST NOT call [Add] BEFORE the guard's check.
Composition note 5: A composing pattern needing a shared list MUST decide who may act on each task AND who a task is assigned to.
Composition note 6: A composing pattern needing a recency guard MUST NOT call [Delete] BEFORE the guard's record of the task's description.
```

NOTE: composing patterns — none yet.

## Example

The same pattern, three personal-scope domains, identical mechanic. A fourth example walks the rejection paths.

### Personal task management

A user opens a notes app and starts a list, `l1`, then types *"buy milk."* The system trims, NFC-normalizes (NFC: Normalization Form C, the Unicode standard's canonical composed form, which gives equivalent characters one standard byte sequence), returns task id `t1`. The user marks `t1` done after the errand, as actor `a1`, then deletes `t1`. A week later, types *"buy milk"* again — accepted; new task id `t2` is issued (no temporal memory in this pattern). Adds *"renew passport"* (task id `t3`), edits it to *"renew passport before Italy trip"* the next day (still `t3`, [Last Edit Instant] updated), leaves it pending for six weeks, eventually deletes `t3` because they renewed via a different channel.

### Reading list

A user adds *"Essence of Software"* (task id `b1`) to their list `l2`, finishes it three weeks later, marks it done, deletes it from the Done list. Adds *"TLA+ in Action"* (a book on TLA+, the Temporal Logic of Actions specification language; task id `b2`), abandons it after fifty pages, deletes `b2`. Two days later, decides to retry — adds *"TLA+ in Action"* again — accepted with new task id `b3` (no recency check in this pattern alone).

### Personal goal capture

A user adds *"call mom this week"* on Monday (task id `g1`) to list `l3`, completes `g1` Friday, deletes `g1`. Adds the same description the following Monday — accepted, task id `g2`. Adds *"learn Python"* (task id `g3`), edits it the next day to *"learn Python — finish first three Real Python tutorials"* to make the goal concrete. Same task id `g3`, updated [Description], updated [Last Edit Instant].

### Rejection paths

The same user, exercising the rejection surface in one short sequence, all in list `l1`:

- Adds *"buy milk"* — accepted, task id `r1`.
- Tries to add *"buy milk"* again immediately while `r1` is still in [Pending] — rejected as [Duplicate Active] (active-set uniqueness protects this case).
- Marks `r1` done, as actor `a1`. Tries to add *"buy milk"* once more while `r1` is in [Done] — rejected as [Duplicate Active] ([Done] counts toward active-set uniqueness).
- Tries to edit `r1` (currently in [Done]) — rejected as [Not Editable].
- Tries to add *"   "* (whitespace-only) — rejected as [Invalid Description] (empty after trim).
- Tries to add a 5,000-codepoint description — rejected as [Invalid Description] (exceeds default 1,024 limit).
- Adds *"café"* — accepted, task id `r2`. Pastes *"café"* in NFD form (Normalization Form D, the decomposed form: `cafe` + combining acute) while `r2`'s description *"café"* in NFC form is in [Pending] — rejected as [Duplicate Active] (NFC normalization unifies the two forms).
- Tries to complete an unknown task id — rejected as [Not Known].
- Deletes `r1`. Now *"buy milk"* is no longer in the active set; a fresh `add("l1", "buy milk")` would succeed with a new task id (`r3`).

This sequence covers four of the seven rejection reasons ([Invalid Description], [Duplicate Active], [Not Editable], [Not Known]) in a single thread of user action. [Not Pending], [Invalid List Id] and [Invalid Completer] are exercised separately — for example, attempting to [Complete] a task id that is already [Done], to [Add] to a blank list id, or to [Complete] with a blank completer. [Storage Failure] is exercised separately too: an [Add] of *"read the manual"* whose write the database refuses answers [Storage Failure] and records nothing, and the same [Add] sent again once the database accepts the write records the task and answers its task id.

## Source

Task is a primitive, not a regulated business pattern. It has no direct ISO (International Organization for Standardization), IEEE (Institute of Electrical and Electronics Engineers) or regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the conception of a "concept" as a composable, behavioral, freestanding unit of software design. The discipline of *not* absorbing concepts that belong to other concepts.
- **Eiffel's design-by-contract** — preconditions on add, edit, complete, delete.
- **Linear temporal logic** — Add-then-Pending and Complete-then-Done expressed as `until` properties.
- **Unicode Standard Annex #15** — NFC normalization for the description policy.

A formal-methods version of a similar concept exists in [concept-catalog](https://github.com/dpapathanasiou/concept-catalog/blob/main/concepts/todo.als), expressed in Alloy 6. The Alloy version uses fully opaque Task atoms (`var sig Task {}`) with no description, no identity-by-content, no edit, and no duplicate prevention; its operational principles cover add, complete, and delete over those atoms. Task is *informed by* that structure but is a distinct concept: it adds a task id as identity with description as a mutable property under uniqueness constraint, an edit action, timestamps, normalized comparison rules, and explicit Behavior / Feedback / Examples coverage. Recency-based duplicate prevention, initially absorbed into the spec on the first iteration, was extracted to a separate freestanding concept.

## Proof

### Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given the tasks, with their committed versions (Execution Contract Generation acceptance 1), and the atom's own surface. Check 1.1 through 1.3, Check 3.1 and Check 4.1 through 4.3 are checks of one state (Execution Contract Database 8). This is the corpus's smallest atom and the reference implementation's first worked example, so the section is deliberately plain: every check is one reading of the tasks against one rule, and the external set is one line long because almost nothing here needs evidence the tasks do not carry.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY known task standing in EXACTLY ONE OF pending, done (State 1).
Check 1.2: An auditor MUST find EVERY task carrying task id, description AND addition instant (State 2).
Check 1.3: An auditor MUST find EVERY done task carrying completion instant (State 4).
Check 1.4: An auditor MUST find EVERY task carrying list id (State 11).
Check 1.5: An auditor MUST find EVERY done task carrying completer (State 12).
Check 2.1: An auditor MUST find no deleted task whose task id IS IN the tasks (Invariant 4.1; Invariant 2.1; Invariant 3.1; Execution Contract Generation acceptance 1).
Check 2.2: An auditor MUST find no two tasks sharing a task id across the tasks' committed versions (Identity 5; Execution Contract Generation acceptance 1).
Check 2.3: An auditor MUST find a task's task id unchanged across an edit (Invariant 8.3; Execution Contract Generation acceptance 1).
Check 2.4: An auditor MUST find no task whose task state EQUALS pending in a committed version that comes after a committed version in which the task state EQUALS done (Invariant 2.1; State 9; Execution Contract Generation acceptance 1).
Check 2.5: An auditor MUST find a task's list id unchanged across the task's committed versions (Invariant 9.1; Execution Contract Generation acceptance 1).
Check 3.1: An auditor MUST find no two tasks in one list's active set sharing a normalized description (Invariant 6.1).
Check 3.3: An auditor MUST find an edit changing no field beside description AND last edit instant (Invariant 5.2; Execution Contract Generation acceptance 1).
Check 3.4: An auditor MUST find no last edit instant stamped for an edit answering ok on an unchanged description (Operation 12; Execution Contract Generation acceptance 1).
Check 4.1: An auditor MUST find no task whose last edit instant PRECEDES the task's addition instant (Invariant 7.1).
Check 4.2: An auditor MUST find no task whose completion instant PRECEDES the task's addition instant (Invariant 7.2).
Check 4.3: An auditor MUST find no task whose completion instant PRECEDES the task's last edit instant (Invariant 7.3).
```

NOTE: EVERY check names the rule the check tests.

#### External checks

```
External check 1: An auditor needing the guarantee that the clock never goes backward confirmed MUST read the deployment's own clock discipline (Invariant 7.1 through 7.3; Execution Contract Logic confinement 7).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a person; a task; a call; the database; a list; an auditor.

Term records: task — one thing to do in one list, carrying task id, list id, description, addition instant, a task state and, once they land, last edit instant, completion instant and completer; completer — the actor id a done task carries for the party who finished it.

Term record verbs: call, identify, allocate, declare, supply, reuse, own, trim, normalize, preserve, answer, compare, show, stand, carry, stamp, take, offer, hold, record, replace, leave, write, read, match, change, set, share, assume, compose, remember, restore, reopen, regenerate, order, keep, resolve, assign, accept, check, precede, find, refuse, append, give, save, judge, tell, decide.

Term value sets: task state = pending | done; action rejection — invalid-list-id | invalid-description | duplicate-active | invalid-completer | not-known | not-pending | not-editable | storage-failure.

Term bounds: description cap (the bound on a description's length as the call carries it).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: now, task, description, description cap, task state, addition instant, last edit instant, completion instant, completer, active set, new description, window, window start, default window, ok.

Term cited: task id, list id, actor id, task events: Declarations.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Add]: #add
[Edit]: #edit
[Complete]: #complete
[Delete]: #delete
[Delete List Tasks]: #delete-list-tasks
[Read]: #read
[Read Task]: #read-task
[Task Record]: #task-record
[Description]: #description
[Addition Instant]: #addition-instant
[Last Edit Instant]: #last-edit-instant
[Completion Instant]: #completion-instant
[Completer]: #completer
[New Description]: #new-description
[Window]: #window
[Now]: #now
[Pending]: #pending
[Done]: #done
[Invalid List Id]: #invalid-list-id
[Invalid Description]: #invalid-description
[Invalid Completer]: #invalid-completer
[Duplicate Active]: #duplicate-active
[Not Known]: #not-known
[Not Pending]: #not-pending
[Not Editable]: #not-editable
[Storage Failure]: #storage-failure
[Duplicate Recent]: #duplicate-recent

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — task.als + 18 twins (the static data model: State 1, 2 and 4 through 7, Identity 5, Invariant 6.1 and 7.1 through 7.3, Description 1, 2, 4 and 5 checked on every state a sequence of admitted calls leaves, Identity 4 and 6 caught by the Identity 5 check, Operation 9 and Description 7 by the Invariant 6.1 check, Operation 8 by the Invariant 7.3 check, Operation 32 and 33 by the Description 4 and 5 checks); task.tla + 11 twins (across steps, as the clock moves: Invariant 2.1, 3.1, 4.1, 5.2, 8.2 and 8.3, State 9, Operation 4 (Description 6, Re-adding 1), 12 and 30); the vote no of 2026-06-03 superseded by the maintainer's ruling of 2026-11-09 (both models; only the writing vetoes one), and neither vetoed; owed rows: Operation 28 and 29, Description 3, 2026-11-11; model redraw deferred to Lean: task.als, Invariant 6.1, State 11 and State 12; task.tla, Operation 4, Operation 9, Operation 17 and Operation 38 through 49 (the models check the one-list case, which the rules still hold), 2026-11-25
last gate: 2026-11-28 — Final Critique 18, a delta round (diff base 35741f8b, 5 labels: Operation 54 through 57 and Term offer key, the existence read Read Task that Key 26 asks of the key offer, bf3c98b8), one reader (Linus opencode/minimax-m3; its first pass lapsed, no spec in a reading set my freeze left without delta.md, and was not counted, the rerun is the round's one pass; GRID and EOS not run; the Claude reader off), frozen at 136c1460 — foundational count 2 after the blind second triage, cured, not clean, no sample; Linus reported no foundational finding, pressed three questions it held, and rated three refining and one rhetorical; the blind second triage (one cold reader on Opus 5.5) placed two foundational, Kind A, cause coverage: Read Task states no answer for a malformed task id, though Execution Contract Query 5 makes a blank, over-cap or non-string id filter malformed and sends it to the refusal the page answers a malformed query with, which Read Task lacks (the page states it for Read's list id and, for the writing actions, in Operation 35 through 37), so a build may answer not-known (Operation 54) and another invalid-request (Linus's Refining 3 and third question, whose clearance named a malformed-input check no rule carries), cured by Operation 58 (not-known, citing Query 5), the case row, the Not Known entry and the prose; and the task state's members, Pending and Done, carried no Projection (spec-format, the ruling of 2026-11-14) while Operation 55 and Operation 29 named the one field task state and state, so two renders may emit different tokens, cured by Projection pending and done and Operation 29 naming task state (the first triage placed this one refining B, a debt the ruling cures as a page reopens); Linus's Refining 1 (EVERY over three fields each one value, an absent one blank, GRACE-lang Term blank), the field order and casing of Refining 2 (the Field Projections pin the names), and the reorder it asked for (rhetorical, GRACE-lang Timing 13: meaning is never read from order) placed refuted or rhetorical, no cure; the checker's Read Task arm-row refining, cured by a case table for Read Task, its code-entry hits and acronym hits false (an answer that carries a record or a list needs a term, not a Projection; TLA+ is glossed at line 615), its Invariant 1 label a tombstoned heading as Final Critique 16 and 17 placed it; the Needs prose lists Read Task among the actions that take no caller, a stale list the blind triage found, cured; model redraw: none, the twins check no read; 2026-11-28 — Final Critique 17, a delta round (diff base 78215dc4, 2 labels, Description 1 and Description 3 as Final Critique 16's settle left them, and the allocation-ban NOTE), one reader (Linus opencode-go/beam-free; GRID and EOS not run; the Claude reader off), frozen at 35741f8b — foundational count 0 after the blind second triage, clean, one sample; Linus's three pressed questions (trim and normalize in either order, the trim set's owner, Description 1 against Description 3) held and placed refuted by both triages: the only normal-form mappings that touch White_Space code points have White_Space at both ends, GRACE-lang Term blank states the White_Space code points inside its own declaration, and Description 1 reaches the leading and trailing runs while Description 3 reaches the interior; of its four refining items one (writing GRACE-lang for the grammar in Description 1) was decided by the corpus's lint, which reads GRACE in capitals in a rule as a reserved token (R-caps, council read 85), so the form stays "the grammar's Term blank", the form Condition Register, Observation and State Machine carry; one (the Unicode version of White_Space, which only U+180E, until Unicode 6.3, ever changed) is a hardening of GRACE-lang Term blank, held for the maintenance window as a held cure; the NOTE on the allocation ban restates no rule of this page; the spelling item rhetorical; the checker's code-entry, acronym and Invariant 1 hits false or settled by this round's done status (the tombstone of Invariant 1.1 stands in the history file, where a done page keeps it); model redraw: none; 2026-11-27 — Final Critique 16, a delta round (diff base f5f4ab98, 6 labels, the reach of Final Critique 15's settle, the table-of-contents lines and the grammar batch), one reader (Linus opencode-go/beam-free; GRID and EOS not run), frozen at 78215dc4 — foundational count 1 after the blind second triage, cured, not clean, no sample; Linus's one foundational claim, that "white space" in Description 1 and Description 3 is defined only in a NOTE, was placed refuted by both triages (GRACE-lang Term blank gives it as the code points with the Unicode White_Space property, a normative term the page's words fall under, so no two builds differ; refining residue cured by citing the term in Description 1; the NOTE on the allocation ban, which pointed at the deleted Identity 3, now points at its owner, Execution Contract Logic confinement 3) and his four other findings refuted or rhetorical; the blind second triage, one cold reader on Opus 5.5, found a foundational defect of its own, Kind A: Description 2 normalizes a description to normal form C, which respells U+2000 and U+2001 as U+2002 and U+2003, while Description 3 preserves the internal white space, so no build satisfies both and one answers duplicate-active where another accepts; cured by Description 3 preserving the internal white space as Description 2's normal form leaves the white space, so the page is doing and its next round is a delta round; 2026-11-25 — Final Critique 15, a delta round (diff base 2fe1b251, 14 labels and the whole new section Delete List Tasks), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at f5f4ab98 — foundational count 0 after the blind second triage, clean, one sample; Linus's three questions held (Operation 51 against the storage-failure arm, refuted by Execution Contract Read 4; a malformed window against Operation 28, decided by Operation 49; a done task with no completion instant, unreachable by State 4) and his four items placed: the case row citing Operation 51 for id reuse, refining by the first triage (rhetorical by the blind one, the higher standing stands), cured by moving Operation 51 to the answer cells of the two [Delete List Tasks] rows; the trigger sentence, Operation 50's AND and Term default window's seven days, rhetorical, left as written; the blind second triage found six more refining items the reader missed, all in the lists the new action left out, cured: the case row of the journal (any admitted call of [Add], [Edit], [Complete] or [Delete], so it no longer says one record for a call of [Delete List Tasks]), the Pending and Done entries (a task leaves on [Delete List Tasks] too), the NOTE on answers (Operation 51), the sentence that no action takes a caller (Non-goal 1), and What it is; declined as rhetorical or restating a rule stated once: a blank or malformed list id (Operation 39 and Execution Contract Input 1 to 3 state it, and [Read] leaves it the same way), a Non-goal on an ended list (an [Add] to an unknown list id was always accepted: the list id is opaque), examples for [Delete List Tasks] ([Delete] has none), the wording of Storage Failure and of the as [Delete] removes each clause; 2026-11-25 — Final Critique 14, a delta round (diff base fe3c8388, 8 labels), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 2fe1b251 — foundational count 0 after the blind second triage, clean, one sample; Linus's two foundational claims placed by both triages: the carried window against an app-passed one (Term window, Operation 28, Operation 49), refuted as foundational (the first triage placed it refining B), since the signature read(list_id, optional window) is the one way a window reaches [Read], a malformed window is not blank and so is never omitted and never takes the default window (Operation 44, Earned vocabulary 22), and every conforming build answers no tasks by Operation 49, so no two builds differ; cured by deleting the leftover clause an app may pass another than the default from Term window, the twin of the clause Final Critique 13 cured in Term default window, and the finder's cure was refused (its Operation 49 old text occurs three times, and its app-passed window would let an omitted window take another than the default window, against Operation 44 and Term default window); Operation 46 without the guard of Operation 45, refining B by both triages, since Operation 49 answers no tasks for a malformed window and no build can break it, cured by the finder's guard, the window the call carries or takes is not malformed; 2026-11-25 — Final Critique 13, a delta round (diff base 985bb27d, 10 labels), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at fe3c8388 — foundational count 1 after the first triage (no blind second triage, the count is not zero), cured in the round, not clean, no sample; Linus's one foundational claim confirmed (an Opus subagent decided it): Term window made a window that is not a duration malformed, and a window the call omits is blank (Earned vocabulary 22) and a blank window is no duration, so Operation 44 took the default window on one build and Operation 49, with the gates of Operation 28 and Operation 45, answered no tasks on another, since 'the window the call carries' reaches a blank value in the corpus's own wording (Input 4, Query 5) and no rule that reaches [Read] keeps blank off it (Input 1's blank clause binds writing actions; Logic confinement 12 binds instants), cured by Term window saying a window that is not blank and is not a duration is malformed and a blank window is omitted and takes the default window, one place for Operation 28, Operation 45 and Operation 49 and the case rows to read; the finder's cure (a not-blank clause in Operation 49) was refused as ungrammatical and as leaving Operation 28 and Operation 45 open to the same reading; refining: Term default window's an app may pass another read as a lasting override, cured by a call may carry another window; rhetorical, left as written: the boundary example for Operation 45 (DOES NOT PRECEDE and PRECEDES are exact complements); 2026-11-25 — Final Critique 12, a delta round, one reader (Linus claude-sonnet-5-5), frozen at 985bb27d — foundational count 0 after the blind second triage, clean, one sample; Linus's three refining items and two rhetorical ones placed: a window that is not a duration, refining B (the blind triage; the first triage placed it the same), since Term window already types the window as a duration and every rule of the corpus that defines malformed makes a value of another type malformed, so Operation 49 already answered it, cured by Term window saying so; Check 2.4, refining by the first triage and rhetorical D by the blind one, the higher standing, cured by the value test the task state EQUALS pending and EQUALS done (Earned vocabulary 15); Non-goal 10's NOTE naming Ordering, refuted by the atom shape of spec-format (a specification names no other atom), no edit; declined as rhetorical: Term default window's seven days of twenty-four hours each (a constant with a unit, which no build reads as 168 hours or as seven calendar days), Term window's second phrase (it puts the floor on the duration); the blind second triage found one more, Term window start written as arithmetic in words, rhetorical A, cured by declared arithmetic (now - the window) and the citation of Execution Contract Logic confinement 20; 2026-11-25 — Final Critique 11, a delta round, one reader (Linus claude-sonnet-5-5), frozen at 47c9ab5b — foundational count 1 after the blind second triage, not clean, one sample; the window's floor and unit placed foundational by the second triage (the first triage placed it refining): read(list, minus one day) took the window as a valid duration on one build, answering the pending tasks, and as malformed on another, answering none, since Term window gave a duration no sign, and the default week could be 168 hours or seven calendar days; cured by Term window (a duration is a length of time never below zero, so a window below zero is malformed) and Term default window (seven days of twenty-four hours each); Linus's one foundational claim, Non-goal 10 against Execution Contract Read 5, placed refining by both triages: the Read action's own text already answers in the order Read 5 gives, since the atom orders no tasks, so a build answering in storage order breaks Read 5 and none conforms, and delta.md did not carry that unlabelled line; Non-goal 10 now says the atom keeps no order other than Read 5's answer order; the other refining items cured: Operation 49 no longer cites Execution Contract Input 1, which governs a writing action's inputs, and Operation 28 and 45 say the window the call carries or takes, so an omitted window reads as the default window; Check 2.4 says a committed version that comes after, no bare AFTER; declined or owned elsewhere: a description NFC expansion past the cap (Term description cap states the carried measure and Execution Contract Input 2 covers a record already over it), the event id of the journal need (the journal's arm, Term need journal), a malformed window answering no tasks (stated by Operation 49 and the case row), the Execution Contract's PersonalTodo names (held cure), Non-goal 6's owner against Restorable Delete (to Scott), the reading names of the round files and the Source section's two senses of Task (rhetorical); 2026-11-25 — Final Critique 10, a delta round, one reader (Linus opencode/beam-free), frozen at 6015eb7f — foundational count 1, not clean, one sample; Linus's eight foundational claims placed: seven refuted by Execution Contract Read 4 (a rule saying what an action does or answers other than a refusal holds only for a call the action admits, so Operations 2, 10, 13, 14, 17, 19, 20, 38 and 41 and States 5, 6 and 7 stand beside the refusals that keep a refused call from being admitted, and Refusal 1 orders the refusals), one confirmed and cured: Operation 28 (and Operation 45, which reads the window start a malformed window has none of) obliged answering the pending tasks while Operation 49, new in the bonded commit, obliged answering none for a malformed window, so two builds differ on read(list, malformed window); both now hold for a window that is not malformed, and the case table says so; the two refining items cured (the Invalid Description entry now says the cap refusal needs no differing text, as Operation 33 does, and the Completer entry leaves the one actor id across records to the app, as the atom canonicalizes nothing in it); 2026-11-19 — Final Critique 9, a delta round, one reader (Linus minimax-m3), frozen at 36366af9 — foundational count 0 after the blind second triage, clean, one sample; Linus's two foundational claims placed refining by both triages: F1 (an [Edit] whose carried text is over the cap and whose normalized text equals the unit's) because Execution Contract Input 2 makes the call malformed and Operation 34 refuses it, so a build answering ok breaks both, cured by Operation 33 conditioned on the call alone, Operation 10 holding within the cap and a Decisions entry that reverses the 2026-10-22 guard (its premise, a cap lowered below stored text, Input 2 now bars); F2 (two calls reading the whole active set) because Database 2's first sentence and Concurrency 1 decide it, cured by one Concurrency sentence; the seven other refining items cured (the NOTE's own exception, Composition note 2 before [Delete], the [Edit] closure rows' pending qualifier, whitespace by GRACE-lang Term blank, Database 8, the id injected for [Add] only, the id unique for the instance), one refuted (the clock's monotonicity is External check 1's), the three rhetorical declined or refuted; 2026-11-04 — Final Critique 8, a delta round, frozen at 17878a4 — foundational count 0, clean, one sample; 2026-11-03 — Final Critique 7 — foundational count 3, not clean, no sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./task.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/task.md`.

</details>

NOTE: End of Task.
