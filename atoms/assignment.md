---
title: Assignment
parent: Atomic Concepts
has_toc: true
toc: true
---

# Assignment

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Assignment records who is responsible for a piece of work, and keeps the history of everyone who has held that responsibility. Each assignment is a record linking one task to one responsible person: it starts out active and ends at most once, either recalled (withdrawn with nobody taking over) or transferred (handed to someone new), and it records when it began and, once it ends, when it ended. The pattern guarantees that a task has at most one active assignment at a time, and a handoff (a reassign) ends the old assignment and starts the new one in a single step, so a handoff never leaves the task with nobody responsible. Assignment never deletes an assignment, and the task, the person and the start time an assignment records never change, so who held a task, and when, can be rebuilt from the records. Each assignment carries an identifier that means nothing by itself, supplied, like the clock reading, by the system running Assignment from outside Assignment's own logic. Whether the person accepts the work, who may assign it and how much work one person may hold are left to separate patterns that attach to it, which keeps it usable as-is for project boards, support-ticket queues, healthcare shift handoffs and legal case routing.

*Also known as: a work assignment, a responsibility binding, a task owner, an owner of record.*

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Work gets handed to people, and the handing has to be answerable: who holds this now, who held it before, and when did it change hands. Most systems carry an `assignee` column and lose the second two questions the moment somebody edits it. This atom makes each binding a record with its own life — created, held, ended one of two ways — so the column becomes a history. Two decisions do the work. A task has at most one live assignment, so *who is responsible* has exactly one answer or none, never two. And a handoff is one step, not a recall followed by an assign, so the task is never momentarily nobody's. Everything else an assignment regime wants — acceptance, deadlines, workload caps, who was allowed to assign — is a composing pattern, named and declined here.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify an assignment by the assignment id.
Identity 2: The host MUST allocate an assignment id at the atom's seam.
Identity 3: The transition MUST NOT allocate an assignment id.
Identity 4: The business caller MUST NOT supply an assignment id.
Deleted: Identity 5. Invariant 6.1 owns it.
Identity 6: The atom MUST NOT identify an assignment by the task reference.
Identity 7: The atom MUST NOT identify an assignment by the task reference with the assignee reference.
Deleted: Identity 8. Invariant 6.1 owns it.
```

NOTE: open 2026-10-26-a — the assignment id's source is named as the host's allocation (Identity 2) and not among what the deployment supplies (Capability requirement 1, Capability requirement 4).

Term assignment: one binding of a unit of work to a responsible actor — an [Assignment].

Term assignment id: the opaque value naming one assignment — an [Assignment Id].

Term task reference: the opaque reference naming the unit of work — a [Task Reference]; the host owns what a task is.

Term assignee reference: the opaque reference naming the responsible actor — an [Assignee Reference]; the actor registry is a separate concept.

Term seam: the atom's I/O (input and output) boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the assignment id here.

Term transition: the atom's evaluation of one call against the assignment records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

NOTE: open 2026-10-21-a — Term seam, Term transition and Term business caller cite the section titled Logic Confinement Principle in `execution-contract.md`, which declares none of them.

### State

```
State 1: EVERY assignment MUST stand in EXACTLY ONE OF active, recalled, transferred.
State 2: EVERY assignment MUST carry assignment id, task reference, assignee reference, assignment instant and status.
State 3: A recalled assignment MUST carry recall instant.
State 4: A transferred assignment MUST carry transfer instant.
State 5: [Assign] MUST stamp assignment instant from the injected now.
State 6: [Recall] MUST stamp recall instant from the injected now.
State 7: [Reassign] MUST stamp transfer instant from the injected now.
Deleted: State 8. Invariant 4.1 owns it.
Deleted: State 9. Invariant 4.2 owns it.
Deleted: State 10. Invariant 10.1 owns it.
State 11: The atom MUST NOT hold a task's lifecycle.
State 12: The atom MUST NOT hold an assignee's workload.
State 13: The atom MUST NOT re-derive an instant an assignment carries from a later reading.
```

Term status: active | recalled | transferred — in force, withdrawn with nobody after, or handed on to a new assignee.

Term assignment instant: the instant the assignment was created — an [Assignment Instant].

Term recall instant: the instant the assignment was withdrawn — a [Recall Instant].

Term transfer instant: the instant the assignment was handed on — a [Transfer Instant].

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 4: The deployment MUST supply the assignment records PER Execution Contract Database 1 through 6, Execution Contract Order 1, Execution Contract Read 1 through 4, Execution Contract Refusal 1, Execution Contract Error model 1 and Execution Contract Conformance 9.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. State 13 owns it.
```

### Operations

```
assign(task_ref, assignee_ref)
  answers assignment_id
  refuses invalid-request | already-assigned | storage-failure

recall(assignment_id)
  answers ok
  refuses not-known | not-active | storage-failure

reassign(assignment_id, new_assignee_ref)
  answers new_assignment_id
  refuses not-known | not-active | invalid-request | storage-failure

active_for(task_ref)
  answers assignment | none

history_for(task_ref)
  answers assignments
```

```
Operation 1: [Assign] MUST record EXACTLY ONE assignment per successful call.
Operation 2: [Assign] MUST stand the assignment in active.
Operation 3: [Assign] MUST answer assignment id.
Operation 4: IF task reference EQUALS blank THEN [Assign] MUST answer invalid-request.
Operation 5: IF assignee reference EQUALS blank THEN [Assign] MUST answer invalid-request.
Operation 6: IF an active assignment EXISTS for the task reference THEN [Assign] MUST answer already-assigned.
Operation 7: IF the database refuses the write THEN [Assign] MUST answer storage-failure.
Operation 8: IF no assignment EXISTS for the assignment id THEN [Recall] MUST answer not-known.
Operation 9: IF the assignment's status EQUALS recalled THEN [Recall] MUST answer not-active.
Operation 10: IF the assignment's status EQUALS transferred THEN [Recall] MUST answer not-active.
Operation 11: [Recall] MUST stand the assignment in recalled.
Operation 12: [Recall] MUST leave the task reference with no active assignment.
Operation 13: IF the database refuses the write THEN [Recall] MUST answer storage-failure.
Operation 14: IF no assignment EXISTS for the assignment id THEN [Reassign] MUST answer not-known.
Operation 15: IF the assignment's status EQUALS recalled THEN [Reassign] MUST answer not-active.
Operation 16: IF the assignment's status EQUALS transferred THEN [Reassign] MUST answer not-active.
Operation 17: IF new assignee reference EQUALS blank THEN [Reassign] MUST answer invalid-request.
Operation 18: [Reassign] MUST stand the old assignment in transferred.
Operation 19: [Reassign] MUST record EXACTLY ONE active assignment for the task reference.
Deleted: Operation 20. Execution Contract Database 1 owns it.
Operation 21: [Reassign] MUST answer the new assignment id.
Operation 22: IF the database refuses either write THEN [Reassign] MUST answer storage-failure.
Deleted: Operation 23. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Operation 24. Execution Contract Read 4 and Execution Contract Database 3 own it: a refused call writes nothing, and a write that did not commit leaves nothing.
Operation 25: [Active For] MUST answer the active assignment for the task reference.
Operation 26: [Active For] MUST answer none for a task reference with no active assignment.
Operation 27: [History For] MUST answer EVERY assignment carrying the task reference.
Operation 28: [History For] MUST order the answer by assignment instant, earliest first.
Operation 28a: [History For] MUST order two assignments sharing an assignment instant by recording commit, earliest first.
Operation 29: [Active For] MUST NOT write.
Operation 30: [History For] MUST NOT write.
Deleted: Operation 30a. Execution Contract Logic confinement 3 owns it.
Operation 30b: [Reassign] MUST stamp the new assignment's assignment instant from the injected now.
Deleted: Operation 31. Capability requirement 1 owns it.
Deleted: Operation 32. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 33. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 34. Execution Contract Read 1 owns it.
Deleted: Operation 35. Execution Contract Refusal 1 owns it.
Deleted: Operation 36. Execution Contract Refusal 1 owns it.
Deleted: Operation 37. Execution Contract Refusal 1 owns it.
Operation 38: [Reassign] MUST set the new assignment's assignee reference to the new assignee reference.
```

NOTE: watch read-order polarity (Operation 28).

Term new assignee reference: the opaque reference naming the actor a reassignment hands the task to — a [New Assignee Reference].

Term recording commit: the commit of the [Assign] or [Reassign] call that recorded an assignment, one position in the single order Execution Contract Order 1 gives every commit.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the assignment records |
|---|---|---|---|
| [Assign] | refs present, task unassigned, database accepts | assignment id | one assignment lands in [Active] (Operation 1, Operation 2) |
| [Assign] | blank task reference or assignee reference | [Invalid Request] | none (Operation 4, Operation 5) |
| [Assign] | task already has an active assignment | [Already Assigned] | none (Operation 6) |
| [Assign] | database refuses the write | [Storage Failure] | none (Operation 7) |
| [Recall] | assignment is active | ok | [Active] → [Recalled]; the task is nobody's (Operation 11, Operation 12) |
| [Recall] | assignment is recalled or transferred | [Not Active] | none (Operation 9, Operation 10) |
| [Recall] | database refuses the write | [Storage Failure] | none — the assignment stays [Active] (Operation 13) |
| [Reassign] | assignment active, new assignee reference present, database accepts | the new assignment id | old → [Transferred] and a new [Active] one carrying the new assignee reference (Operation 18, Operation 19, Operation 21, Operation 38) |
| [Reassign] | blank new assignee reference | [Invalid Request] | none (Operation 17) |
| [Reassign] | assignment is recalled or transferred | [Not Active] | none (Operation 15, Operation 16) |
| [Reassign] | either write refused | [Storage Failure] | none — the old stays [Active] (Operation 22) |
| [Recall] or [Reassign] | id names nothing | [Not Known] | none (Operation 8, Operation 14) |
| [Active For] | task has an active assignment | that assignment | none — the call reads (Operation 25, Operation 29) |
| [Active For] | task is unassigned | none | none (Operation 26) |
| [History For] | any task reference | every assignment for the task, by assignment instant, earliest first, two sharing one by recording commit | none (Operation 27, Operation 28, Operation 28a, Operation 30) |
| any call | its read of the assignment records fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |

Where two cases of one action hold at once, the refusal listed first on the action's refuses line answers (Execution Contract Refusal 1).

### Invariants

- **Invariant 1 — At most one Active assignment per task.**
  ```
  Invariant 1.1: Two active assignments MUST NOT share a task reference.
  ```
- **Invariant 2 — Assignment immutability.**
  ```
  Invariant 2.1: A recorded assignment's assignment id, task reference, assignee reference and assignment instant MUST NOT change.
  ```
- **Invariant 3 — Status monotonicity.**
  ```
  Deleted: Invariant 3.1. State 1 owns it.
  Invariant 3.2: A status MUST NOT move to active from a terminal status.
  ```
- **Invariant 4 — Terminal states are absorbing.**
  ```
  Invariant 4.1: A recalled assignment MUST NOT take a further transition.
  Invariant 4.2: A transferred assignment MUST NOT take a further transition.
  ```
- **Invariant 5 — Id stability.**
  ```
  Invariant 5.1: [Assign] MUST set the assignment id.
  Deleted: Invariant 5.2. Invariant 2.1 owns it.
  ```
- **Invariant 6 — No id reuse.**
  ```
  Invariant 6.1: Two assignments MUST NOT share an assignment id.
  ```
- **Invariant 7 — Reassign atomicity.**
  ```
  Deleted: Invariant 7.1. Operation 18, Operation 19 and Invariant 1.1 own it: a landed reassign leaves the task reference one active assignment, the one the reassign recorded, and a later recall may leave none.
  Invariant 7.2: The reassigned assignment MUST stand in transferred once [Reassign] lands.
  Deleted: Invariant 7.3. Execution Contract Database 1 owns it.
  Deleted: Invariant 7.4. Execution Contract Database 1 owns it.
  ```
- **Invariant 8 — Timestamp ordering.**
  ```
  Invariant 8.1: IF recall instant DOES NOT EQUAL blank THEN recall instant MUST NOT PRECEDE assignment instant.
  Invariant 8.2: IF transfer instant DOES NOT EQUAL blank THEN transfer instant MUST NOT PRECEDE assignment instant.
  Invariant 8.3: The atom MUST stamp EVERY instant an assignment carries once.
  ```
- **Invariant 9 — Complete responsibility history.**
  ```
  Invariant 9.1: The assignments carrying one task reference MUST record EVERY actor who held the task.
  Invariant 9.2: The assignments carrying one task reference MUST record when each holding began.
  Deleted: Invariant 9.3. State 3 and State 4 own it: an ended holding carries its recall instant or its transfer instant, and an active one has not ended.
  ```
- **Invariant 10 — Assignment record durability.**
  ```
  Invariant 10.1: The atom MUST NOT delete an assignment record.
  Deleted: Invariant 10.2. Invariant 10.1 owns it (Execution Contract Database 6).
  ```

NOTE: watch the modal with no temporal scope (State 1, Invariant 3.2).

At-most-one and reassign atomicity give the *unambiguous accountability* property — *who is responsible for this task?* has one answer or none, never two. Immutability, the complete history and durability give *auditability* — the chain is the database, and nothing leaves it quietly.

## Examples

The same atom, four domains, identical mechanic.

### Project management — task handoff mid-sprint

A sprint board has a task *"implement login flow"* (task reference: `task_t44`). The engineering manager assigns it to a developer: `assign(task_t44, dev_alice) → assignment_id a1`. Alice picks it up. Mid-sprint, Alice is pulled onto a production incident; the manager reassigns: `reassign(a1, dev_bob) → a2`. Alice's assignment (`a1`) moves to [Transferred]; Bob's (`a2`) is now [Active]. The sprint retrospective can reconstruct from the assignment records: Alice held the task from day 1 to day 4, and Bob from day 4 on; when the work was finished is the task system's record (External check 3). At no point was the task unassigned.

### Customer support — ticket escalation

A support ticket is auto-assigned to a tier-1 agent: `assign(ticket_t99, agent_tier1_j) → a5`. The agent cannot resolve the issue; they escalate. The supervisor calls `reassign(a5, agent_tier2_k) → a6`. Tier-2 resolves it, and the support system — the composing pattern that owns whether a resolved ticket's assignment is recalled (Composition note 4) — calls `recall(a6) → ok`. The assignment records show: tier-1 held the ticket for 2 hours, tier-2 for 45 minutes. If the customer complains about resolution time, both ownership windows are on record. SLA (Service-Level Agreement — a commitment to a measurable level of service, such as a maximum resolution time) calculations use each assignment record's [Assignment Instant] and its [Transfer Instant] or [Recall Instant].

### Healthcare — patient-to-nurse assignment on a ward

A patient is admitted and assigned to the on-call nurse: `assign(patient_p31, nurse_n7) → a12`. At shift change, the charge nurse reassigns: `reassign(a12, nurse_n14) → a13`. If a clinical incident occurs overnight, the investigation can determine which nurse held the assignment at what time. The assignment records are the accountability record; the clinical event log (Event Log atom) is the action record; both compose to answer the investigation's questions.

### Rejection paths

A single sequence exercising all rejection reasons:

- `assign(task_t1, dev_a) → a1` — accepted.
- `assign(task_t1, dev_b)` → rejected already-assigned (Invariant 1; `task_t1` already has an [Active] [Assignment] in `a1`).
- `recall(unknown_id)` → rejected not-known.
- `recall(a1) → ok` — `a1` moves to [Recalled]; `task_t1` is now unassigned.
- `recall(a1)` → rejected not-active (a1 is already [Recalled]; terminal).
- `reassign(a1, dev_c)` → rejected not-active (a1 is terminal).
- `assign(task_t1, dev_b) → a2` — accepted; `task_t1` is now unassigned so a fresh [Assignment] is allowed.
- `reassign(a2, "")` → rejected invalid-request (empty assignee).
- `assign(task_t2, dev_c)` → rejected storage-failure (database write fails; no [Assignment] created; `task_t2` remains unassigned).

All five rejection reasons (invalid-request, already-assigned, not-known, not-active, storage-failure) exercised in one sequence.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the assignment records' stored fields and the order of the commits that recorded them.

### Conformance checks

```
Check 1.1: An auditor MUST find no task reference carrying two active assignments (Invariant 1.1).
Check 2.1: An auditor MUST reconstruct a task's chain of responsibility from the assignments carrying the task reference, ordered by assignment instant, earliest first, and then by recording commit (Invariant 9.1, Invariant 9.2, State 3, State 4).
Check 2.2: An auditor MUST read a recalled assignment as the recalling call leaving the task reference with no active assignment (Operation 12).
Check 2.3: An auditor MUST read a transferred assignment as handed on to the assignment the transferring call recorded for the same task reference (Operation 18, Operation 19, Invariant 7.2).
Check 3.1: An auditor MUST find no assignment whose status moved out of a terminal status (Invariant 3.2, Invariant 4.1, Invariant 4.2).
Check 4.1: An auditor MUST find no assignment carrying an instant that PRECEDES the assignment's assignment instant (Invariant 8.1, Invariant 8.2).
Deleted: Check 5.1. Execution Contract Conformance 9 owns it.
```

### External checks

```
External check 1: An auditor MUST read the assigner's authority from the composing Permissions records (Non-goal 5).
External check 2: An auditor MUST read who issued an assignment from the composing Actor Identity attestations (Non-goal 7).
External check 3: An auditor MUST read a task's completion from the host's task system (Non-goal 11).
Deleted: External check 4. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: External check 5. Execution Contract Conformance 9 owns it.
```

NOTE: EVERY check names the rule the check tests. The assignment records answer *who holds this and who held it*; who was allowed to hand it over is in the composing patterns' records, and whether the work is done in the host's task system.

## Non-goals

```
Non-goal 1: The atom MUST NOT require an assignee's acceptance.
Non-goal 2: A deployment needing acceptance MUST compose an acceptance pattern.
Non-goal 3: The atom MUST NOT expire an assignment.
Non-goal 4: A deployment needing a time-bounded assignment MUST compose a temporal-grant pattern.
Non-goal 5: The atom MUST NOT check an assigner's authority.
Non-goal 6: A deployment needing an authorized assigner MUST compose Permissions.
Non-goal 7: The atom MUST NOT record who issued an assignment.
Non-goal 8: A deployment needing assigner attribution MUST compose Actor Identity.
Non-goal 9: The atom MUST NOT cap an assignee's active assignments.
Non-goal 10: The atom MUST NOT bind two assignees to one active assignment.
Non-goal 11: The atom MUST NOT read a task's state.
Non-goal 12: The atom MUST NOT recall an assignment on the task's completion.
```

NOTE: the owners — a Capacity Constraint pattern *(forthcoming)* (Non-goal 9); a Team Assignment pattern *(forthcoming)* (Non-goal 10); the host's task system (Non-goal 11, External check 3); the composing pattern (Non-goal 12, Composition note 4).

Where the atom breaks down: when responsibility is genuinely shared at the same time; when an assignment must end on its own without anyone withdrawing it; when the assigner must be authorized before assigning; when the assignee must consent before holding.

## Edge cases

### Reassign atomicity

```
Deleted: Reassign atomicity 1. Execution Contract Database 1 owns it.
Deleted: Reassign atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reassign atomicity 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reassign atomicity 4. Execution Contract Database 1 owns it.
```

### The assign race

```
Deleted: Assign race 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Assign race 2. Execution Contract Database 2 owns it.
Deleted: Assign race 3. Execution Contract Database 2 owns it.
```

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Deleted: Composition note 2. Term task reference owns it: the host owns what a task is.
Composition note 3: A composing pattern MUST own whether an assignee may hold the task.
Composition note 4: A composing pattern MUST own whether a completed task's assignment is recalled.
Composition note 5: A composing pattern needing assigner attribution MUST attest [Assign] and [Reassign] under the assigner's credential.
```

NOTE: composing patterns — [Shared Todo](../compositions/shared-todo.md). Forthcoming: Acceptance, Temporal Grant, Capacity Constraint, Team Assignment.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the deployment; a composing pattern (also: a pattern); a business caller; an assigner; an assignee; an auditor; the database; an assignment; a task; a call.

Term records: assignment — one binding, carrying assignment id, task reference, assignee reference, assignment instant, status and, once it ends, recall instant or transfer instant.

Term record verbs: identify, allocate, supply, reuse, carry, stand, stamp, offer, delete, hold, record, answer, leave, write, read, order, set, change, move, take, share, shrink, require, expire, check, cap, bind, recall, compose, own, attest, declare, find, reconstruct, re-derive, precede.

Term value sets: status = active | recalled | transferred.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: assignment, assignment id, task reference, assignee reference, seam, transition, business caller, now, status, assignment instant, recall instant, transfer instant, new assignee reference, recording commit.

#### Assignment

The record this atom defines: a binding of a unit of work to the actor responsible for completing it. It carries its [Assignment Id], [Task Reference], [Assignee Reference], [Assignment Instant], [Status], and — where applicable — [Recall Instant] or [Transfer Instant]. The [Assignment Id], [Task Reference], [Assignee Reference], and [Assignment Instant] are immutable from creation. Its status field holds one of [Active], [Recalled], or [Transferred]; at most one [Assignment] per task is [Active] at any time.

Kind: Type

#### Status

The [Assignment]'s lifecycle state — [Active], [Recalled] or [Transferred]. Set to [Active] on creation; moves once, to one terminal state, and never back (State 1, Invariant 3.2).

Kind:       Field
Field of:   the assignment
Projection: status

#### Assign

The behavior that binds a unit of work to a responsible actor, recording a new [Assignment]. It assigns a fresh [Assignment Id] from injected id material at the seam, sets [Task Reference], [Assignee Reference], and [Assignment Instant] = [Now], enters the [Assignment] in [Active], and returns the [Assignment Id] (or a rejection naming the failed precondition). It refuses [Already Assigned] if an [Active] [Assignment] already exists for the [Task Reference].

Kind: Operation

#### Recall

The behavior that withdraws an [Active] [Assignment] without a successor, leaving the task unassigned. Permitted only on an [Active] [Assignment]; it moves the [Assignment] [Active] → [Recalled] and stamps [Recall Instant]. On an unknown id it is rejected [Not Known]; on an already-terminal [Assignment] it is rejected [Not Active].

Kind: Operation

#### Reassign

The behavior that hands an [Active] [Assignment] off to a new actor. It moves the old [Assignment] [Active] → [Transferred] (stamping [Transfer Instant]) and creates a new [Active] [Assignment] for the same [Task Reference] with the [New Assignee Reference]; it returns the new [Assignment Id].

Kind: Operation

#### Active For

The read query that returns the at-most-one [Active] [Assignment] for a given [Task Reference], or none if the task is currently unassigned. Read-only; consistent with Invariant 1.

Kind: Operation

#### History For

The read query that returns all assignments ([Active], [Recalled], [Transferred]) for a given [Task Reference], ordered by [Assignment Instant], earliest first, two sharing one by the commit that recorded each — the complete responsibility chain required by Invariant 9. Read-only.

Kind: Operation

#### Assignment Id

The opaque, immutable identity of an [Assignment], host-allocated from injected id material at the I/O seam and never reused. The [Task Reference] and [Assignee Reference] are properties of the [Assignment], not its identity.

Kind:       Field
Field of:   Assignment
Projection: assignment_id

#### Task Reference

The opaque reference identifying the unit of work an [Assignment] is for. The atom does not know what a task is or how its lifecycle is managed. Set on creation, immutable thereafter.

Kind:       Field
Field of:   Assignment
Projection: task_ref

#### Assignee Reference

The opaque reference identifying the actor an [Assignment] binds responsibility to. The actor registry is a separate concept. Set on creation, immutable thereafter.

Kind:       Field
Field of:   Assignment
Projection: assignee_ref

#### Assignment Instant

The wall-time the [Assignment] was created, stamped from the injected [Now] on [Assign], and on the new [Assignment] a [Reassign] records (Operation 30b). Immutable thereafter. Where the [Assignment] carries a [Recall Instant] or a [Transfer Instant], that instant does not precede the [Assignment Instant] (Invariant 8.1, Invariant 8.2).

Kind:       Field
Field of:   Assignment
Projection: assigned_at

#### Recall Instant

The wall-time the [Assignment] was recalled, stamped from the injected [Now] on [Recall]. Present only in [Recalled]; immutable once set.

Kind:       Field
Field of:   Assignment
Projection: recalled_at

#### Transfer Instant

The wall-time the [Assignment] was transferred, stamped from the injected [Now] on [Reassign]. Present only in [Transferred]; immutable once set.

Kind:       Field
Field of:   Assignment
Projection: transferred_at

#### New Assignee Reference

The reference to the new responsible actor [Reassign] consumes and writes into the new [Active] [Assignment]'s [Assignee Reference] (Operation 38). A blank one is refused [Invalid Request] (Operation 17). It is not stored under its own name — only the new [Assignment]'s [Assignee Reference] is stored.

Kind:         Parameter
Parameter of: Reassign
Projection:   new_assignee_ref

#### Now

The current clock reading every writing action consumes — the pipeline's `clock_t`, supplied at the atom's seam, never read inside the transition and never a signature parameter. Its only use is the immutable timestamp stamps inside committed transitions ([Assignment Instant], [Recall Instant], [Transfer Instant]).

Kind:         Parameter
Parameter of: Assign, Recall and Reassign
Projection:   now

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

#### Invalid Request

The refusal [Assign] returns when [Task Reference] or [Assignee Reference] is blank, and [Reassign] returns when [New Assignee Reference] is blank (Operation 4, Operation 5, Operation 17). A guard rejection that fails before any database write; no [Assignment] is created or changed.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Already Assigned

The refusal [Assign] returns when an [Active] [Assignment] already exists for the [Task Reference]. No [Assignment] is created. This is the at-most-one-Active guard (Invariant 1) enforced at the [Assign] boundary.

Kind:       Member
Member of:  the Assign rejection
Role:       Outcome
Projection: already-assigned

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

The refusal [Assign], [Recall] or [Reassign] returns when the database write fails after the preconditions pass. No [Assignment] is created (for [Assign]), or the [Assignment] remains [Active] (for [Recall] and [Reassign]): a write that did not commit leaves nothing (Execution Contract Database 3).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Assignment]: #assignment
[Assign]: #assign
[Recall]: #recall
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

---

## Standards references

Assignment is a productivity primitive with broad operational anchoring and lighter regulatory footprint than the compliance atoms:

- **ITIL (Information Technology Infrastructure Library)** — incident and request management define assignment as the binding of a work item to a responsible individual or group. ITIL's assignment and escalation mechanics are the operational reference for the support-queue examples.
- **ISO/IEC 20000 (Information Technology Service Management)** — the International Organization for Standardization / International Electrotechnical Commission service-management standard; it formalizes incident assignment and reassignment as required process steps with audit-trail obligations. The assignment records supply the assignment and reassignment trail that standard audits.
- **HL7 FHIR (Health Level Seven Fast Healthcare Interoperability Resources — the standard for exchanging healthcare data electronically) Task resource** — healthcare task management defines assignment as a `Task.owner` binding, with history of ownership tracked per task. The atom's responsibility-history invariant (Invariant 9) is the FHIR-compatible form.
- **PMI PMBOK (the Project Management Institute's Project Management Body of Knowledge)** — responsibility assignment matrices (RAM), such as the RACI chart (Responsible, Accountable, Consulted, Informed), are the structured form of the same mechanic: binding work packages to responsible individuals. The atom is the dynamic runtime form of a RACI row.
- **GDPR (General Data Protection Regulation — the European Union's data-protection law) Article 5(1)(f) and Article 32** — in systems processing personal data, assignment records establish who was responsible for personal data at what time. The assignment records are part of the accountability trail.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — freestanding-atom posture; the discipline of keeping accept/decline, authorization, capacity, and expiry as composing concepts rather than absorbing them.
- **Eiffel's design-by-contract** — preconditions on [Assign], [Recall], [Reassign]; named rejection reasons.

---

## Status

`grounded on Final Critique 7 — 2026-10-26` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 7 — 2026-10-26
formal: verified — assignment.tla + 1 twin, 2026-06-03
last gate: 2026-10-26 — Final Critique 7 — foundational count 0, clean, one sample

open:
- 2026-10-21-a · refining · Term seam; Term transition; Term business caller · each says the section titled Logic Confinement Principle in `execution-contract.md` declares it, and that section declares none of the three and calls the composition layer the seam (Logic confinement 2); seam, transition and business caller have no term entry → declare the three there, the corpus's one seam wording, or point each at its declaration, and give each a term entry
- 2026-10-26-a · refining · Identity 2; Capability requirement 1, 4 · the assignment id's source is named as the host's allocation (Identity 2) and not among what the deployment supplies, where the atom shape in `spec-format.md` lists an id source under Capability requirement; Event Log (its 2026-10-22-b) and Tamper Evidence (its 2026-10-22-a) route the same form → name the source among the Capability requirements, in the one form the corpus settles for its twenty host-allocation atoms
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/assignment.md`; the migration that got it here is in [its history](./assignment.hist.md).

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the assignment store supplied under Execution Contract Store 1 through 4 (Capability requirement 4), and the twelve rules that restated them tombstoned to their owner — Operation 20, Invariant 7.3 and 7.4 and Reassign atomicity 1, the reassign's two writes committed together with no reader seeing one without the other, and Reassign atomicity 4, the repair owed for a landed half, to Store 1; Operation 23, both writes withdrawn on storage-failure, and Reassign atomicity 2 and 3, a crash inside [Reassign] leaving the task neither unassigned nor held twice, to Store 1 and Store 3; Assign race 1, the active-assignment check and the write as one transition, and External check 4, the deployment's evidence of that atomicity and serialization, to Store 1 and Store 2; Assign race 2 and 3, two concurrent assigns never both recording and the later answering already-assigned, to Store 2; rules 110 to 99. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. A handoff is still one action, not a recall followed by an assign (Operation 18 and 19, Invariant 7.1 and 7.2); the atom's own no-delete rules stay (State 10, Invariant 10.1 and 10.2), and so does a refused call leaving the store as found (Operation 24), which covers the guard refusals no Store rule reaches. A task's responsibility chain is separate records ordered by assignment instant, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — A failed read answers on every action, each write's refusals in one stated order; a tie of assignment instants falls to commit order; the wiring declaration is an external check; a holding's end is its terminal stamp.** *Chose:* state-unavailable on all five actions where the read of the assignment records fails, the Execution Contract's Step 1 failure (Operation 34, Term database read), [Active For] and [History For] answering only on an answered read (Operation 25 through 27); the refusals of [Assign], [Recall] and [Reassign] in one stated order each, the read first and then the sequence Final Critique 4's prose gave — the inputs before already-assigned, and a known assignment, then an active one, then the successor (Operation 35 through 37, Term assign refusal order, Term recall refusal order, Term reassign refusal order); two assignments sharing an assignment instant ordered by the commit that recorded each (Operation 28a, Term recording commit), the records supplied under Execution Contract Order 1 beside Database 1 through 4 (Capability requirement 4), and Check 2.1 and the acceptance bar reading that order; the composing patterns a deployment wired in read from the deployment's own declaration (External check 5); and Invariant 9.3, which asked an active holding how it ended, deleted to State 3 and State 4. *Over:* [Active For] answering none, and a write answering no code the page names, when the records cannot be read; one reassign answered two ways by two builds; a [History For] two builds order two ways, and a chain of handoffs at one instant no auditor can rebuild; a conformance check reading what the records do not carry; an invariant every assign breaks. *Because:* Final Critique 5 found each a divergence between conforming builds, or a stated check a conforming build fails, and the corpus already held four of the cures: Actor Identity's fifth round answers a failed read on every action and reads the composing patterns from the deployment's declaration; Retention Window's eighth answers each writing action's refusals in one stated order, the form the maintainer ruled for Verified Repair on 2026-10-19; and Party Identity cites Order 1 beside the Database contract. The entry of 2026-10-19 said a task's chain needs no Order 1, the assignment instants ordering it; a clock that repeats a reading, which Logic confinement 7 allows, ties them, and only the commit order keeps the chain. Compositions affected: the pages that compose this atom route state-unavailable from all five actions, when their rounds read them.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 4, Execution Contract Read 1 through 3) and the rule that restated it, the atom-wide state-unavailable (Operation 34), deleted to Read 1; the read's condition off the read answers it held to an answered read (Operation 25 through 27), the read off the assign, recall and reassign refusal orders, Term database read deleted, state-unavailable off every signature, and the failed read off the case table and the rejection-path example, which now exercises five reasons; rules 103 to 102. *Over:* the page stating for itself what every action answers when the assignment records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's fifth Final Critique had made one of the cures the contract's Read family is written from. What each action answers on an answered read is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each writing action's refuses line kept as the page wrote it, already in the order its refusal order gave — [Assign] invalid-request, already-assigned; [Recall] not-known, not-active; [Reassign] not-known, not-active, invalid-request; storage-failure last on each, answering only at the write — and the order cited from the Execution Contract (Capability requirement 4, Execution Contract Refusal 1); Operation 35, Operation 36 and Operation 37, which evaluated the three refusal orders, deleted to Refusal 1, and Term assign refusal order, Term recall refusal order and Term reassign refusal order deleted with them; rules 102 to 99. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's fifth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-22 — The wiring is read outside the records, as the Execution Contract says.** *Chose:* External check 5, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 5.1's tombstone, which named it, now naming the contract, and the label cited on Capability requirement 4; rules 99 to 98. *Over:* the page stating for itself that the wiring is an external check. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration among them; this page's fifth Final Critique had made the cure one specification at a time. What each action does and answers is unchanged.

</details>

NOTE: End of Assignment.
