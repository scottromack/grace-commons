---
title: Assignment
id: 30
audience: common
---

# Assignment

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Assignment records who is responsible for a piece of work, and keeps the history of everyone who has held that responsibility. Each assignment is a record pairing one task id with one actor id, the responsible person: it starts out active and ends at most once, either recalled (withdrawn with nobody taking over) or transferred (handed to someone new), and it records when it began and, once it ends, when it ended. The pattern guarantees that a task has at most one active assignment at a time, and a handoff (a reassign) ends the old assignment and starts the new one in a single step, so a handoff never leaves the task with nobody responsible. Assignment never deletes an assignment, and the task, the person and the start time an assignment records never change, so who held a task, and when, can be rebuilt from the records. Each assignment carries an identifier that means nothing by itself, supplied, like the clock reading, by the system running Assignment from outside Assignment's own logic. Whether the person accepts the work, who may assign it and how much work one person may hold are left to separate patterns that attach to it, which keeps it usable as-is for project boards, support-ticket queues, healthcare shift handoffs and legal case routing.

*Also known as: a work assignment, a responsibility binding, a task owner, an owner of record.*

<details markdown="block">
<summary>WHY</summary>

Work gets handed to people, and the handing has to be answerable: who holds this now, who held it before, and when did it change hands. Most systems carry an `assignee` column and lose the second two questions the moment somebody edits it. This atom makes each binding a record with its own life — created, held, ended one of two ways — so the column becomes a history. Two decisions do the work. A task has at most one live assignment, so *who is responsible* has exactly one answer or none, never two. And a handoff is one step, not a recall followed by an assign, so the task is never momentarily nobody's. Everything else an assignment regime wants — acceptance, deadlines, workload caps, who was allowed to assign — is a composing pattern, named and declined here.

</details>

## What it keeps

### The assignments

Term assignment: one binding of a unit of work to a responsible actor — an [Assignment].

#### Assignment

The record this atom defines: a binding of a unit of work to the actor responsible for completing it. It carries its [Assignment Id], [Task Reference], [Assignee Reference], [Assignment Instant], [Status], and — where applicable — [Recall Instant] or [Transfer Instant]. The [Assignment Id], [Task Reference], [Assignee Reference], and [Assignment Instant] are immutable from creation. Its status field holds one of [Active], [Recalled], or [Transferred]; at most one [Assignment] per task is [Active] at any time.

Kind: Type

```
Identity 1: The atom MUST identify an assignment by the assignment id.
Identity 2: The host MUST allocate an assignment id at the atom's seam.
Identity 6: The atom MUST NOT identify an assignment by the task reference.
Identity 7: The atom MUST NOT identify an assignment by the task reference with the assignee reference.
```

Term assignment id: the opaque value naming one assignment — an [Assignment Id].

#### Assignment Id

The opaque, immutable identity of an [Assignment], host-allocated from injected id material at the I/O seam and never reused. The [Task Reference] and [Assignee Reference] are properties of the [Assignment], not its identity.

Kind:       Field
Field of:   Assignment
Projection: assignment_id

Term task reference: the task id naming the unit of work — a [Task Reference]; the host owns what a task is.

#### Task Reference

The task id identifying the unit of work an [Assignment] is for. The atom does not know what a task is or how its lifecycle is managed. Set on creation, immutable thereafter.

Kind:       Field
Field of:   Assignment
Projection: task_ref

Term assignee reference: the actor id naming the responsible actor — an [Assignee Reference]; the actor registry is a separate concept.

#### Assignee Reference

The actor id identifying the actor an [Assignment] binds responsibility to. The actor registry is a separate concept. Set on creation, immutable thereafter.

Kind:       Field
Field of:   Assignment
Projection: assignee_ref

Term assignment instant: the instant the assignment was created — an [Assignment Instant].

#### Assignment Instant

The wall-time the [Assignment] was created, stamped from the injected [Now] on [Assign], and on the new [Assignment] a [Reassign] records (Operation 30b). Immutable thereafter. Where the [Assignment] carries a [Recall Instant] or a [Transfer Instant], that instant does not precede the [Assignment Instant] (Invariant 8.1, Invariant 8.2).

Kind:       Field
Field of:   Assignment
Projection: assigned_at

Term recall instant: the instant the assignment was withdrawn — a [Recall Instant].

#### Recall Instant

The wall-time the [Assignment] was recalled, stamped from the injected [Now] on [Recall]. Present only in [Recalled]; immutable once set.

Kind:       Field
Field of:   Assignment
Projection: recalled_at

Term transfer instant: the instant the assignment was handed on — a [Transfer Instant].

#### Transfer Instant

The wall-time the [Assignment] was transferred, stamped from the injected [Now] on [Reassign]. Present only in [Transferred]; immutable once set.

Kind:       Field
Field of:   Assignment
Projection: transferred_at

Term status: active | recalled | transferred — in force, withdrawn with nobody after, or handed on to a new assignee.

Term terminal status: recalled or transferred — a status no action moves an assignment out of (Invariant 4.1, Invariant 4.2).

#### Status

The [Assignment]'s lifecycle state — [Active], [Recalled] or [Transferred]. Set to [Active] on creation; moves once, to one terminal state, and never back (State 1, Invariant 3.2).

Kind:       Field
Field of:   Assignment
Projection: status

#### Active

The single non-terminal state: the [Assignment] is in force and the assignee is the current responsible actor for the task. At most one [Assignment] per [Task Reference] is [Active]. The lifecycle proceeds [Active] → one of {[Recalled], [Transferred]}.

Kind:      Member
Member of: the assignment status
Role:      Outcome

#### Recalled

The terminal state an [Assignment] reaches when the assigner withdrew it without a successor — the task is now unassigned. Absorbing: no action transitions it elsewhere.

Kind:      Member
Member of: the assignment status
Role:      Outcome

#### Transferred

The terminal state an [Assignment] reaches when a [Reassign] superseded it with a new [Active] [Assignment] — the task has a new responsible actor. Absorbing: no action transitions it elsewhere.

Kind:      Member
Member of: the assignment status
Role:      Outcome

```
State 1: EVERY assignment MUST stand in EXACTLY ONE OF active, recalled, transferred.
State 2: EVERY assignment MUST carry assignment id, task reference, assignee reference, assignment instant and status.
State 3: A recalled assignment MUST carry recall instant.
State 4: A transferred assignment MUST carry transfer instant.
State 5: [Assign] MUST stamp assignment instant from the injected now.
State 6: [Recall] MUST stamp recall instant from the injected now.
State 7: [Reassign] MUST stamp transfer instant from the injected now.
State 11: The atom MUST NOT hold a task's life cycle.
State 12: The atom MUST NOT hold an assignee's workload.
State 13: The atom MUST NOT re-derive an instant an assignment carries from a later reading.
```

## What people do

### Every action

```
Operation 40: [Assign], [Recall] and [Reassign] MUST append one assignment events record through the atom's journal need for EVERY admitted call.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the assignment records |
|---|---|---|---|
| [Recall] or [Reassign] | id names nothing | [Not Known] | none (Operation 8, Operation 14) |
| any call | its read of the assignment records fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| [Assign], [Recall] or [Reassign], admitted | the database accepts | the call's answer | one assignment events record appended (Operation 40) |
| [Assign], [Recall], [Reassign] or [Recall For Task], preconditions pass | the journal refuses the append of Operation 40 or Operation 53 | [Storage Failure] | none, the writes to the assignment records roll back with it (Execution Contract Database 1, Execution Contract Constituent failure 1) |

Where two cases of one action hold at once, the refusal listed first on the action's refuses line answers (Execution Contract Refusal 1).

An [Assign] is undone by a [Recall]; a [Recall] leaves the recalled assignment final (Invariant 4.1, Invariant 10.1), so a later [Assign] records afresh and no undo is owed; a [Reassign] leaves the old assignment final the same way and is handed on by another [Reassign] (Execution Contract Undo 4).

#### Invalid Request

The refusal [Assign] returns when [Task Reference] or [Assignee Reference] is blank, and [Reassign] returns when [New Assignee Reference] is blank (Operation 4, Operation 5, Operation 17). A guard rejection that fails before any database write; no [Assignment] is created or changed.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Not Known

The refusal [Recall] or [Reassign] returns when the supplied [Assignment Id] references no known [Assignment]. A lookup miss, distinct from a state rejection.

Kind:       Member
Member of:  the resolving-action rejection
Role:       Outcome
Projection: not-known

#### Not Active

The refusal [Recall] or [Reassign] returns when the referenced [Assignment] is already terminal — [Recalled] or [Transferred]. This is the terminal-absorption guard: a resolving action on an already-resolved [Assignment] is refused without modifying any record.

Kind:       Member
Member of:  the resolving-action rejection
Role:       Outcome
Projection: not-active

#### Storage Failure

The refusal [Assign], [Recall], [Reassign] or [Recall For Task] returns when the database write fails after the preconditions pass, or when the journal refuses the append of Operation 40 for [Assign], [Recall] and [Reassign], or Operation 53 for [Recall For Task] (Execution Contract Constituent failure 1). No [Assignment] is created (for [Assign]), or the [Assignment] remains [Active] (for [Recall], [Reassign] and [Recall For Task]): a write that did not commit leaves nothing (Execution Contract Database 3).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Assign

The behavior that binds a unit of work to a responsible actor, recording a new [Assignment]. It assigns a fresh [Assignment Id] from injected id material at the seam, sets [Task Reference], [Assignee Reference], and [Assignment Instant] = [Now], enters the [Assignment] in [Active], and returns the [Assignment Id] (or a rejection naming the failed precondition). It refuses [Already Assigned] if an [Active] [Assignment] already exists for the [Task Reference].

Kind: Operation

```
assign(task_ref, assignee_ref)
  answers assignment_id
  refuses invalid-request | already-assigned | storage-failure
```

```
Operation 1: [Assign] MUST record EXACTLY ONE assignment per successful call.
Operation 2: [Assign] MUST stand the assignment in active.
Operation 4: IF task reference EQUALS blank THEN [Assign] MUST answer invalid-request.
Operation 5: IF assignee reference EQUALS blank THEN [Assign] MUST answer invalid-request.
Operation 6: IF an active assignment EXISTS for the task reference THEN [Assign] MUST answer already-assigned.
Operation 7: IF the database refuses the write THEN [Assign] MUST answer storage-failure.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the assignment records |
|---|---|---|---|
| [Assign] | refs present, task unassigned, database accepts | assignment id | one assignment lands in [Active] (Operation 1, Operation 2) |
| [Assign] | blank task reference or assignee reference | [Invalid Request] | none (Operation 4, Operation 5) |
| [Assign] | task already has an active assignment | [Already Assigned] | none (Operation 6) |
| [Assign] | database refuses the write | [Storage Failure] | none (Operation 7) |

#### Already Assigned

The refusal [Assign] returns when an [Active] [Assignment] already exists for the [Task Reference]. No [Assignment] is created. This is the at-most-one-Active guard (Invariant 1) enforced at the [Assign] boundary.

Kind:       Member
Member of:  the Assign rejection
Role:       Outcome
Projection: already-assigned

- `assign(task_t1, dev_a) → a1` — accepted.
- `assign(task_t1, dev_b)` → rejected already-assigned (Invariant 1; `task_t1` already has an [Active] [Assignment] in `a1`).
- `assign(task_t2, dev_c)` → rejected storage-failure (database write fails; no [Assignment] created; `task_t2` remains unassigned).

### Recall

The behavior that withdraws an [Active] [Assignment] without a successor, leaving the task unassigned. Permitted only on an [Active] [Assignment]; it moves the [Assignment] [Active] → [Recalled] and stamps [Recall Instant]. On an unknown id it is rejected [Not Known]; on an already-terminal [Assignment] it is rejected [Not Active].

Kind: Operation

```
recall(assignment_id)
  answers ok
  refuses not-known | not-active | storage-failure
```

```
Operation 8: IF no assignment EXISTS for the assignment id THEN [Recall] MUST answer not-known.
Operation 9: IF the assignment's status EQUALS recalled THEN [Recall] MUST answer not-active.
Operation 10: IF the assignment's status EQUALS transferred THEN [Recall] MUST answer not-active.
Operation 11: [Recall] MUST stand the assignment in recalled.
Operation 12: [Recall] MUST leave the assignment's task reference with no active assignment.
Operation 13: IF the database refuses the write THEN [Recall] MUST answer storage-failure.
Operation 39: [Recall] MUST answer ok.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the assignment records |
|---|---|---|---|
| [Recall] | assignment is active | ok | [Active] → [Recalled]; the task is nobody's; its assignment id, task reference, assignee reference and assignment instant stand (Operation 11, Operation 12, Operation 39, Invariant 2.1) |
| [Recall] | assignment is recalled or transferred | [Not Active] | none (Operation 9, Operation 10) |
| [Recall] | database refuses the write | [Storage Failure] | none — the assignment stays [Active] (Operation 13) |

- `recall(unknown_id)` → rejected not-known.
- `recall(a1) → ok` — `a1` moves to [Recalled]; `task_t1` is now unassigned.
- `recall(a1)` → rejected not-active (a1 is already [Recalled]; terminal).

### Recall For Task

Recalls the active assignment of one task, given the task reference alone, as [Recall] recalls an assignment by its id; the action the task id need's on end names, which the app calls when an action the meeting offer's ends names ends the task (Needs). A task with no active assignment is left as it is. Answers ok.

Kind: Operation

```
recall_for_task(task_ref)
  answers ok
  refuses storage-failure
```

```
Operation 49: IF an active assignment EXISTS for the task reference THEN [Recall For Task] MUST stand the assignment in recalled.
Operation 50: IF [Recall For Task] stands an assignment in recalled THEN [Recall For Task] MUST stamp the assignment's recall instant from the injected now.
Operation 51: [Recall For Task] MUST answer ok.
Operation 52: IF no active assignment EXISTS for the task reference THEN [Recall For Task] MUST NOT write.
Operation 53: IF [Recall For Task] stands an assignment in recalled THEN [Recall For Task] MUST append one assignment events record through the atom's journal need.
```

| Call | Case | Answer | Effect on the assignment records |
|---|---|---|---|
| [Recall For Task] | the task has an active assignment | ok | [Active] → [Recalled], its recall instant stamped; the task is nobody's; one assignment events record appended (Operation 49, Operation 50, Operation 53, Invariant 2.1) |
| [Recall For Task] | the task has no active assignment | ok | none, no write (Operation 52, Operation 51) |
| [Recall For Task] | the task has an active assignment, the database refuses the write | [Storage Failure] | none — the assignment stays [Active] (Execution Contract Read 4, Execution Contract Database 1) |

### Reassign

The behavior that hands an [Active] [Assignment] off to a new actor. It moves the old [Assignment] [Active] → [Transferred] (stamping [Transfer Instant]) and creates a new [Active] [Assignment] for the same [Task Reference] with the [New Assignee Reference]; it returns the new [Assignment Id].

Kind: Operation

```
reassign(assignment_id, new_assignee_ref)
  answers new_assignment_id
  refuses not-known | not-active | invalid-request | storage-failure
```

```
Operation 14: IF no assignment EXISTS for the assignment id THEN [Reassign] MUST answer not-known.
Operation 15: IF the assignment's status EQUALS recalled THEN [Reassign] MUST answer not-active.
Operation 16: IF the assignment's status EQUALS transferred THEN [Reassign] MUST answer not-active.
Operation 17: IF new assignee reference EQUALS blank THEN [Reassign] MUST answer invalid-request.
Operation 18: [Reassign] MUST stand the old assignment in transferred.
Operation 19: [Reassign] MUST record EXACTLY ONE active assignment for the old assignment's task reference.
Operation 22: IF the database refuses either write THEN [Reassign] MUST answer storage-failure.
Operation 30b: [Reassign] MUST stamp the new assignment's assignment instant from the injected now.
Operation 38: [Reassign] MUST set the new assignment's assignee reference to the new assignee reference.
```

Term new assignee reference: the actor id naming the actor a reassignment hands the task to — a [New Assignee Reference].

#### New Assignee Reference

The reference to the new responsible actor [Reassign] consumes and writes into the new [Active] [Assignment]'s [Assignee Reference] (Operation 38). A blank one is refused [Invalid Request] (Operation 17). It is not stored under its own name — only the new [Assignment]'s [Assignee Reference] is stored.

Kind:         Parameter
Parameter of: Reassign
Projection:   new_assignee_ref

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the assignment records |
|---|---|---|---|
| [Reassign] | assignment active, new assignee reference present, database accepts | the new assignment id | old → [Transferred], its assignment id, task reference, assignee reference and assignment instant standing, and its transfer instant stamped from the injected now; and a new [Active] one carrying the same task reference, the new assignee reference and an assignment instant stamped from the injected now (Operation 18, Operation 19, Operation 30b, Operation 38, State 7, Invariant 2.1, Invariant 8.3) |
| [Reassign] | blank new assignee reference | [Invalid Request] | none (Operation 17) |
| [Reassign] | assignment is recalled or transferred | [Not Active] | none (Operation 15, Operation 16) |
| [Reassign] | either write refused | [Storage Failure] | none — the old stays [Active] (Operation 22) |

- `reassign(a1, dev_c)` → rejected not-active (a1 is terminal).
- `reassign(a2, "")` → rejected invalid-request (empty assignee).

### Active For

The read query that returns the at-most-one [Active] [Assignment] for a given [Task Reference], or none if the task is currently unassigned. Read-only; consistent with Invariant 1.

Kind: Operation

```
active_for(task_ref)
  answers assignment | none
```

```
Operation 25: [Active For] MUST answer the active assignment for the task reference.
Operation 26: [Active For] MUST answer none for a task reference with no active assignment, a blank one included.
Operation 29: [Active For] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the assignment records |
|---|---|---|---|
| [Active For] | task has an active assignment | that assignment | none — the call reads (Operation 25, Operation 29) |
| [Active For] | task is unassigned | none | none (Operation 26) |

### History For

The read query that returns all assignments ([Active], [Recalled], [Transferred]) for a given [Task Reference], ordered by [Assignment Instant], earliest first, two sharing one by the commit that recorded each — the complete responsibility chain required by Invariant 9. Read-only.

Kind: Operation

```
history_for(task_ref)
  answers assignments
```

```
Operation 27: [History For] MUST answer EVERY assignment carrying the task reference, none for a blank one.
Operation 28: [History For] MUST order the answer by assignment instant, earliest first.
Operation 28a: [History For] MUST order two assignments sharing an assignment instant by recording commit, earliest first.
Operation 30: [History For] MUST NOT write.
```

NOTE: watch read-order polarity (Operation 28).

Term recording commit: the commit of the [Assign] or [Reassign] call that recorded an assignment, one position in the single order Execution Contract Order 1 gives every commit.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the assignment records |
|---|---|---|---|
| [History For] | any task reference | every assignment for the task, by assignment instant, earliest first, two sharing one by recording commit | none (Operation 27, Operation 28, Operation 28a, Operation 30) |

## What is and what should never be (Invariants)

- **Invariant 1 — At most one Active assignment per task.**
  ```
  Invariant 1.1: Two active assignments MUST NOT share a task reference.
  ```
- **Invariant 5 — Id stability.**
  ```
  Invariant 5.1: EVERY assignment MUST carry the assignment id the host allocated for the call recording the assignment.
  ```
- **Invariant 6 — No id reuse.**
  ```
  Invariant 6.1: Two assignments MUST NOT share an assignment id.
  ```
- **Invariant 7 — Reassign atomicity.**
  ```
  Invariant 7.2: The reassigned assignment MUST stand in transferred once [Reassign] lands.
  ```
- **Invariant 8 — Timestamp ordering.**
  ```
  Invariant 8.1: IF recall instant DOES NOT EQUAL blank THEN recall instant MUST NOT PRECEDE assignment instant.
  Invariant 8.2: IF transfer instant DOES NOT EQUAL blank THEN transfer instant MUST NOT PRECEDE assignment instant.
  Invariant 8.3: An instant an assignment carries MUST NOT change.
  ```
- **Invariant 9 — Complete responsibility history.**
  ```
  Invariant 9.1: The assignments carrying one task reference MUST record EVERY actor who held the task.
  Invariant 9.2: The assignments carrying one task reference MUST record when each holding began.
  ```
- **Invariant 2 — Assignment immutability.**
  ```
  Invariant 2.1: A recorded assignment's assignment id, task reference, assignee reference and assignment instant MUST NOT change.
  ```
- **Invariant 3 — Status monotonicity.**
  ```
  Invariant 3.2: A status MUST NOT move to active from a terminal status.
  ```
- **Invariant 4 — Terminal states are absorbing.**
  ```
  Invariant 4.1: A recalled assignment's status MUST NOT change.
  Invariant 4.2: A transferred assignment's status MUST NOT change.
  ```
- **Invariant 10 — Assignment record durability.**
  ```
  Invariant 10.1: The atom MUST NOT delete an assignment record.
  ```

At-most-one and reassign atomicity give the *unambiguous accountability* property — *who is responsible for this task?* has one answer or none, never two. Immutability, the complete history and durability give *auditability* — the chain is the database, and nothing leaves it quietly.

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 7 and Execution Contract Logic confinement 11.
Capability requirement 4: The deployment MUST supply the assignment records PER Execution Contract Database 1 through 8, Execution Contract Order 1, Execution Contract Read 1 through 4, Execution Contract Refusal 1, Execution Contract Error model 1 and Execution Contract Conformance 9.
Capability requirement 5: The deployment MUST supply at the seam, for each [Assign] call and each [Reassign] call, an assignment id no assignment has carried PER Execution Contract Logic confinement 3 and Execution Contract Logic confinement 16.
```

Term seam: the atom's I/O (input and output) boundary as Execution Contract Logic confinement 14 declares it; the host injects the clock reading and the assignment id here.

Term transition: the atom's evaluation of one call against the assignment records, as Execution Contract Logic confinement 14 declares it.

Term business caller: the business caller per Execution Contract Logic confinement 14.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it; the atom spends no clock allowance, since it compares a call's reading only with an instant an earlier call stamped from the deployment's one clock, whose monotonicity and agreement across nodes the deployment owns (Execution Contract Logic confinement 7 and Execution Contract Logic confinement 18).

#### Now

The current clock reading every writing action consumes — the pipeline's `clock_t`, supplied at the atom's seam, never read inside the transition and never a signature parameter. Its only use is the immutable timestamp stamps inside committed transitions ([Assignment Instant], [Recall Instant], [Transfer Instant]).

Kind:         Parameter
Parameter of: Assign, Recall and Reassign
Projection:   now

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice. [Assign], [Recall] and [Reassign] take no caller and check none (Non-goal 5): who may assign is the app's permission, gated before the call, and a claim is an assignment whose assignee the app passes as the caller, a glue line of the app's.

Term need key: key task id; pairs assignments; on end Recall For Task.

Term need key: key actor id; pairs assignees.

Term need journal: records assignment events; calls append; arms event_id.

## Left to others

```
Non-goal 1: The atom MUST NOT require an assignee's acceptance.
Deleted: Non-goal 2. Non-goal 1 owns it: the atom requires no acceptance, and which pattern does is the app's choice.
Non-goal 3: The atom MUST NOT expire an assignment.
Deleted: Non-goal 4. Non-goal 3 owns it: the atom expires no assignment, and which pattern bounds one in time is the app's choice.
Non-goal 5: The atom MUST NOT check an assigner's authority.
Deleted: Non-goal 6. Non-goal 5 owns it: the atom checks no assigner's authority; the app's permission gates the call.
Non-goal 7: The atom MUST NOT record who issued an assignment.
Deleted: Non-goal 8. Non-goal 7 owns it: the atom records no assigner, and which pattern attests one is the app's choice.
Non-goal 9: The atom MUST NOT cap an assignee's active assignments.
Non-goal 10: The atom MUST NOT bind two assignees to one active assignment.
Non-goal 11: The atom MUST NOT read a task's state.
Non-goal 12: The atom MUST NOT recall an assignment on the task's completion.
```

NOTE: the owners — patterns the app chooses: one that requires acceptance (Non-goal 1), bounds an assignment in time (Non-goal 3), decides who may assign (Non-goal 5), attests who assigned (Non-goal 7, Composition note 5), caps an assignee's load (Non-goal 9) and binds a team to one assignment (Non-goal 10); the host's task system (Non-goal 11, External check 3); the composing pattern (Non-goal 12, Composition note 4).

Where the atom breaks down: when responsibility is genuinely shared at the same time; when an assignment must end on its own without anyone withdrawing it; when the assigner must be authorized before assigning; when the assignee must consent before holding.

```
Composition note 3: A composing pattern MUST own whether an assignee may hold the task.
Composition note 4: A composing pattern MUST own whether a completed task's assignment is recalled.
Composition note 5: A composing pattern needing assigner attribution MUST attest [Assign] and [Reassign] under the assigner's sign-in proof.
```

NOTE: composing patterns — an app names the atoms it composes; this pattern names none.

## Example

The same atom, four domains, identical mechanic.

### Project management — task handoff mid-sprint

A sprint board has a task *"implement login flow"* (task reference: `task_t44`). The engineering manager assigns it to a developer: `assign(task_t44, dev_alice) → assignment_id a1`. Alice picks it up. Mid-sprint, Alice is pulled onto a production incident; the manager reassigns: `reassign(a1, dev_bob) → a2`. Alice's assignment (`a1`) moves to [Transferred]; Bob's (`a2`) is now [Active]. The sprint retrospective can reconstruct from the assignment records: Alice held the task from day 1 to day 4, and Bob from day 4 on; when the work was finished is the task system's record (External check 3). At no point was the task unassigned.

### Customer support — ticket escalation

A support ticket is auto-assigned to a tier-1 agent: `assign(ticket_t99, agent_tier1_j) → a5`. The agent cannot resolve the issue; they escalate. The supervisor calls `reassign(a5, agent_tier2_k) → a6`. Tier-2 resolves it, and the support system — the composing pattern that owns whether a resolved ticket's assignment is recalled (Composition note 4) — calls `recall(a6) → ok`. The assignment records show: tier-1 held the ticket for 2 hours, tier-2 for 45 minutes. If the customer complains about resolution time, both ownership windows are on record. SLA (Service-Level Agreement — a commitment to a measurable level of service, such as a maximum resolution time) calculations use each assignment record's [Assignment Instant] and its [Transfer Instant] or [Recall Instant].

### Healthcare — patient-to-nurse assignment on a ward

A patient is admitted and assigned to the on-call nurse: `assign(patient_p31, nurse_n7) → a12`. At shift change, the charge nurse reassigns: `reassign(a12, nurse_n14) → a13`. If a clinical incident occurs overnight, the investigation can determine which nurse held the assignment at what time. The assignment records are the accountability record; the clinical event log is the action record; both compose to answer the investigation's questions.

## Source

Assignment is a productivity primitive with broad operational anchoring and lighter regulatory footprint than the compliance atoms:

- **ITIL (Information Technology Infrastructure Library)** — incident and request management define assignment as the binding of a work item to a responsible individual or group. ITIL's assignment and escalation mechanics are the operational reference for the support-queue examples.
- **ISO/IEC 20000 (Information Technology Service Management)** — the International Organization for Standardization / International Electrotechnical Commission service-management standard; it formalizes incident assignment and reassignment as required process steps with audit-trail obligations. The assignment records supply the assignment and reassignment trail that standard audits.
- **HL7 FHIR (Health Level Seven Fast Healthcare Interoperability Resources — the standard for exchanging healthcare data electronically) Task resource** — healthcare task management defines assignment as a `Task.owner` binding, with history of ownership tracked per task. The atom's responsibility-history invariant (Invariant 9) is the FHIR-compatible form.
- **PMI PMBOK (the Project Management Institute's Project Management Body of Knowledge)** — responsibility assignment matrices (RAM), such as the RACI chart (Responsible, Accountable, Consulted, Informed), are the structured form of the same mechanic: binding work packages to responsible individuals. The atom is the dynamic runtime form of a RACI row.
- **GDPR (General Data Protection Regulation — the European Union's data-protection law) Article 5(1)(f) and Article 32** — in systems processing personal data, assignment records establish who was responsible for personal data at what time. The assignment records are part of the accountability trail.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — freestanding-atom posture; the discipline of keeping accept/decline, authorization, capacity, and expiry as composing concepts rather than absorbing them.
- **Eiffel's design-by-contract** — preconditions on [Assign], [Recall], [Reassign]; named rejection reasons.

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the assignment records' stored fields and the order of the commits that recorded them.

#### Conformance checks

```
Check 1.1: An auditor MUST find no task reference carrying two active assignments (Invariant 1.1).
Check 2.1: An auditor MUST reconstruct a task's chain of responsibility from the assignments carrying the task reference, ordered by assignment instant, earliest first, and then by recording commit (Invariant 9.1, Invariant 9.2, State 3, State 4).
Check 2.2: An auditor MUST read a recalled assignment as the recalling call leaving the task reference with no active assignment (Operation 12).
Check 2.3: An auditor MUST read a transferred assignment as handed on to the assignment the transferring call recorded for the same task reference (Operation 18, Operation 19, Invariant 7.2).
Check 3.1: An auditor MUST find no assignment whose status moved out of a terminal status (Invariant 3.2, Invariant 4.1, Invariant 4.2).
Check 4.1: An auditor MUST find no assignment carrying an instant that PRECEDES the assignment's assignment instant (Invariant 8.1, Invariant 8.2).
Check 6.1: An auditor MUST find no assignment id carried by two assignments (Invariant 6.1).
```

#### External checks

```
External check 1: An auditor MUST read the assigner's authority from the app's permission records (Non-goal 5).
External check 2: An auditor MUST read who issued an assignment from the composing pattern's attestations of the assigner (Non-goal 7).
External check 3: An auditor MUST read a task's completion from the host's task system (Non-goal 11).
```

NOTE: EVERY check names the rule the check tests. The assignment records answer *who holds this and who held it*; who was allowed to hand it over is in the composing patterns' records, and whether the work is done in the host's task system.

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the transition; the deployment; a composing pattern (also: a pattern); a business caller; an assigner; an assignee; an auditor; the database; an assignment; a task; a call.

Term records: assignment — one binding, carrying assignment id, task reference (a task id), assignee reference (an actor id), assignment instant, status and, once it ends, recall instant or transfer instant.

Term record verbs: identify, allocate, supply, reuse, carry, stand, stamp, offer, delete, hold, record, answer, leave, write, read, order, set, change, move, take, share, shrink, require, expire, check, cap, bind, recall, compose, own, attest, declare, find, reconstruct, re-derive, precede, append.

Term value sets: status = active | recalled | transferred.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: assignment, assignment id, task reference, assignee reference, seam, transition, business caller, now, status, assignment instant, recall instant, transfer instant, new assignee reference, recording commit, terminal status.

Term cited: task id, actor id, assignment events: Declarations.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Assignment]: #assignment
[Assign]: #assign
[Recall]: #recall
[Recall For Task]: #recall-for-task
[Reassign]: #reassign
[Active For]: #active-for
[History For]: #history-for
[Assignment Id]: #assignment-id
[Task Reference]: #task-reference
[Assignee Reference]: #assignee-reference
[Assignment Instant]: #assignment-instant
[Recall Instant]: #recall-instant
[Transfer Instant]: #transfer-instant
[New Assignee Reference]: #new-assignee-reference
[Now]: #now
[Active]: #active
[Recalled]: #recalled
[Transferred]: #transferred
[Invalid Request]: #invalid-request
[Already Assigned]: #already-assigned
[Not Known]: #not-known
[Not Active]: #not-active
[Storage Failure]: #storage-failure
[Status]: #status

## Status

`done — 2026-11-25` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-25
formal: verified — assignment.tla + 1 twin (2026-06-03); assignment.als + 11 twins (the static data model, 2026-11-11: State 1 through 4 and Invariant 5.1, 6.1, 7.2, 8.1, 8.2, 9.1 and 9.2 checked on every record an admitted [Assign], [Recall] or [Reassign] leaves, Invariant 7.2 a cross-check with the TLA+ model; nothing testable in Alloy for Invariant 1.1, 2.1, 3.2, 4.1, 4.2, 8.3 and 10.1: whether two active assignments co-exist depends on the order of the calls that wrote them, and the others each compare a record with a later version of it, which a single state cannot show, so they are the TLA+ model's); coverage 2026-11-10 (unit formal: more coverage for the yes votes): owes TLA+ checks of Invariant 2, 3, 4, 8.3 and 10 (across steps); owed rows: Invariant 2; Invariant 3; Invariant 4; Invariant 8.3; Invariant 10, 2026-11-11
last gate: 2026-11-27 — Final Critique 15, a delta round (diff base c00e24f8, 2 labels reached: State 11, whose wording the grammar batch changed from lifecycle to life cycle, and Capability requirement 5, which the reach tool named although its line is unchanged), one reader (Linus anthropic/claude-sonnet-5-5; GRID and EOS not run), frozen at 79b69293 — foundational count 0 after the blind second triage, clean, one sample; Linus counted 0 foundational, 2 refining, 1 rhetorical: State 11's "a task's life cycle" is the corpus's one form for a negative scope rule (twelve other atoms, Task, Capability, Legal Hold and Notification among them, write "The atom MUST NOT hold" the same way) and the Task Reference entry and Term task reference say the host owns the task, so the first triage placed it no defect, and the blind second triage placed it refining A on Closed vocabulary 4, with no two builds differing (Data layer contract, State 2 and Non-goal 11 hold no task state) and so no edit; the two citations under one PER tail are the form of Capability requirement 1 and 4 and GRACE-lang's Term run of labels, no defect; "no assignment has carried" is the sentence Logic confinement 16 itself sanctions ("an id names no record already held stands beside this one"), no defect; 2026-11-26 — Final Critique 14, a delta round (diff base f5f4ab98, 3 labels reached: Capability requirement 1, 4 and 5, which cite the Execution Contract rules the App model changed, Conformance 9 among them), one reader (Linus anthropic/claude-sonnet-5-5; GRID and EOS not run), frozen at c00e24f8 — foundational count 0 after the blind second triage, clean, one sample; Linus counted 0 foundational, 4 refining, 1 rhetorical, and the blind second triage placed all five no defect: the Storage Failure block's silence on a refused [Reassign]'s replacement is Database 3's, Operation 22's and the [Reassign] table's (a refused write leaves nothing), the journal row's citation of Constituent failure 1 is the one Bonds' journal need fields and Final Critique 12's cure rest on, the entropy-read failure of [Assign] and [Reassign] is Execution Contract Input 2's (no specification owes its restatement), the "any call" read-failure row holds because every action here reads first (Read 1), and the dash in the new [Recall For Task] row is the form the [Recall], [Reassign] and [Active For] rows already write; no edit; 2026-11-25 — Final Critique 13, a delta round (diff base 153bc911, 6 labels reached: the new action Recall For Task and the task id need's on end), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at f5f4ab98 — foundational count 0 after the blind second triage, clean, one sample; Linus's one foundational claim placed refining B by both triages: the case-space row and the Storage Failure member name only Assign, Recall and Reassign, so a journal refusal of Operation 53 on Recall For Task is no case of the table, but Execution Contract Database 1 and Constituent failure 1 roll the whole action back and answer storage-failure, so no two builds differ; cured by citation, not restatement: the row and the member now also name Recall For Task and Operation 53, and Recall For Task's own table gains the row for a database refusal of the write (Execution Contract Read 4, Database 1), the one the blind second triage found missing)

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./assignment.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/assignment.md`.

</details>

NOTE: End of Assignment.
