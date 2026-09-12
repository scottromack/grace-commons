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

Assignment records who is responsible for a piece of work and the full history of everyone who has held that responsibility. Each assignment is a record that links a task to the person responsible for it. It moves through three states: Active (in force), Recalled (withdrawn with no replacement), or Transferred (handed off to a new person). The pattern guarantees that a task can have at most one responsible person at a time. The handoff action (reassign) does the swap in a single step, so the task is never left with no one responsible. And because records are never overwritten or deleted, you can always reconstruct who held a task and when. Each assignment carries an opaque, immutable identifier the host supplies at the atom's one boundary with the outside world — the same place the clock is read, so the pattern's own logic stays free of both; the task it is for and the actor it binds are fixed when the assignment is created and never change. It deliberately leaves out related questions — whether the person accepts the work, who is allowed to assign it, how much work one person may hold — because those are handled by separate patterns that attach to it. This makes it usable as-is for project boards, support-ticket queues, healthcare shift handoffs, legal case routing, and any other place where accountability for work needs to be tracked.

*Also known as: a work assignment, a responsibility binding, a task owner, an owner of record.*

---

## Intent

WHY:
Work gets handed to people, and the handing has to be answerable: who holds this now, who held it before, and when did it change hands. Most systems carry an `assignee` column and lose the second two questions the moment somebody edits it. This atom makes each binding a record with its own life — created, held, ended one of two ways — so the column becomes a history. Two decisions do the work. A task has at most one live assignment, so *who is responsible* has exactly one answer or none, never two. And a handoff is one step, not a recall followed by an assign, so the task is never momentarily nobody's. Everything else an assignment regime wants — acceptance, deadlines, workload caps, who was allowed to assign — is a composing pattern, named and declined here.

## Structure

### Identity model

```text
Identity 1: The atom MUST identify an assignment by the assignment_id.
Identity 2: The host MUST allocate an assignment_id at the atom's seam.
Identity 3: The transition MUST NOT allocate an assignment_id.
Identity 4: The business caller MUST NOT supply an assignment_id.
Identity 5: The atom MUST NOT reuse an assignment_id.
Identity 6: The atom MUST NOT identify an assignment by the task_ref.
Identity 7: The atom MUST NOT identify an assignment by the task_ref with the assignee_ref.
Identity 8: Two assignments over one task MUST carry two assignment_ids.
```

Terms › `assignment`: one binding of a unit of work to a responsible actor — an [Assignment].

Terms › `assignment_id`: the opaque value naming one assignment — an [Assignment Id].

Terms › `task_ref`: the opaque reference naming the unit of work — a [Task Ref]; the host owns what a task is.

Terms › `assignee_ref`: the opaque reference naming the responsible actor — an [Assignee Ref]; the actor registry is a separate concept.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading and the assignment_id here.

Terms › `transition`: the atom's evaluation of one call against the assignment store, as `execution-contract.md` §Logic confinement declares it.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

WHY:
Identity by task would make a reassignment overwrite its predecessor, which destroys the answer to *who held this before*; identity by the task-and-assignee pair would collapse a re-assignment of the same actor after an intervening recall, which destroys *how many times* (Identity 6, Identity 7). One binding, one id, is what makes Invariant 9.1's chain recoverable.

### State

```text
State 1: EVERY assignment MUST stand in EXACTLY ONE OF active, recalled, transferred.
State 2: EVERY assignment MUST carry assignment_id, task_ref, assignee_ref, assigned_at and status.
State 3: A recalled assignment MUST carry recalled_at.
State 4: A transferred assignment MUST carry transferred_at.
State 5: [Assign] MUST stamp assigned_at from the injected now.
State 6: [Recall] MUST stamp recalled_at from the injected now.
State 7: [Reassign] MUST stamp transferred_at from the injected now.
State 8: The atom MUST NOT offer a transition out of recalled.
State 9: The atom MUST NOT offer a transition out of transferred.
State 10: The atom MUST NOT delete an assignment.
State 11: The atom MUST NOT hold a task's lifecycle.
State 12: The atom MUST NOT hold an assignee's workload.
```

Terms › `status`: `active` | `recalled` | `transferred` — in force, withdrawn with nobody after, or handed on to a successor.

Terms › `assigned_at`: the instant the assignment was created — an [Assigned At].

Terms › `recalled_at`: the instant the assignment was withdrawn — a [Recalled At].

Terms › `transferred_at`: the instant the assignment was handed on — a [Transferred At].

WHY:
Recalled and transferred are two terminal states rather than one because they answer different audit questions: recalled means the task is nobody's, transferred means it is somebody else's, and a single *closed* state would make an auditor infer the difference from the presence of a successor (State 8, State 9). Nothing is deleted, so the chain of responsibility is the store rather than a reconstruction (State 10).

### Operations

```
assign(task_ref, assignee_ref) → assignment_id | rejected(invalid-request | already-assigned | storage-failure)
recall(assignment_id) → ok | rejected(not-known | not-active | storage-failure)
reassign(assignment_id, new_assignee_ref) → new_assignment_id | rejected(not-known | not-active | invalid-request | storage-failure)
active_for(task_ref) → assignment | none
history_for(task_ref) → assignments
```

```text
Operation 1: [Assign] MUST record EXACTLY ONE assignment per successful call.
Operation 2: [Assign] MUST stand the assignment in active.
Operation 3: [Assign] MUST answer assignment_id.
Operation 4: IF task_ref is blank THEN [Assign] MUST answer invalid-request.
Operation 5: IF assignee_ref is blank THEN [Assign] MUST answer invalid-request.
Operation 6: IF an active assignment EXISTS for the task_ref THEN [Assign] MUST answer already-assigned.
Operation 7: IF the store refuses the write THEN [Assign] MUST answer storage-failure.
Operation 8: IF the assignment_id NOT EXISTS THEN [Recall] MUST answer not-known.
Operation 9: IF the assignment stands in recalled THEN [Recall] MUST answer not-active.
Operation 10: IF the assignment stands in transferred THEN [Recall] MUST answer not-active.
Operation 11: [Recall] MUST stand the assignment in recalled.
Operation 12: [Recall] MUST leave the task_ref with no active assignment.
Operation 13: IF the store refuses the write THEN [Recall] MUST answer storage-failure.
Operation 14: IF the assignment_id NOT EXISTS THEN [Reassign] MUST answer not-known.
Operation 15: IF the assignment stands in recalled THEN [Reassign] MUST answer not-active.
Operation 16: IF the assignment stands in transferred THEN [Reassign] MUST answer not-active.
Operation 17: IF new_assignee_ref is blank THEN [Reassign] MUST answer invalid-request.
Operation 18: [Reassign] MUST stand the old assignment in transferred.
Operation 19: [Reassign] MUST record EXACTLY ONE active assignment for the task_ref.
Operation 20: [Reassign] MUST commit the two writes together.
Operation 21: [Reassign] MUST answer the new assignment_id.
Operation 22: IF the store refuses either write THEN [Reassign] MUST answer storage-failure.
Operation 23: [Reassign] MUST withdraw both writes on storage-failure.
Operation 24: A refused call MUST leave the store as the call found the store.
Operation 25: [Active For] MUST answer the active assignment for the task_ref.
Operation 26: [Active For] MUST answer none for a task_ref with no active assignment.
Operation 27: [History For] MUST answer EVERY assignment carrying the task_ref.
Operation 28: [History For] MUST order the answer by assigned_at.
Operation 29: [Active For] MUST NOT write.
Operation 30: [History For] MUST NOT write.
Operation 30a: [Reassign] MUST read one now per call.
Operation 30b: [Reassign] MUST stamp transferred_at and assigned_at against that one now.
Operation 31: The host MUST read the clock at the atom's seam.
Operation 32: The transition MUST NOT read a clock.
Operation 33: The business caller MUST NOT supply now.
```

Terms › `new_assignee_ref`: the opaque reference naming the successor a reassignment hands the task to — a [New Assignee Ref].

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the assignment store |
|---|---|---|---|
| [Assign] | refs present, task unassigned, store accepts | `assignment_id` | one assignment lands in [Active] (Operation 1, Operation 2) |
| [Assign] | blank `task_ref` or `assignee_ref` | [Invalid Request] | none (Operation 4, Operation 5) |
| [Assign] | task already has a live assignment | [Already Assigned] | none (Operation 6) |
| [Recall] | assignment is live | `ok` | [Active] → [Recalled]; the task is nobody's (Operation 11, Operation 12) |
| [Recall] | assignment is recalled or transferred | [Not Active] | none (Operation 9, Operation 10) |
| [Reassign] | assignment live, successor present, store accepts | the new `assignment_id` | old → [Transferred] and a new [Active] one, in one commit (Operation 18–21) |
| [Reassign] | blank `new_assignee_ref` | [Invalid Request] | none (Operation 17) |
| [Reassign] | assignment is recalled or transferred | [Not Active] | none (Operation 15, Operation 16) |
| [Reassign] | either write refused | [Storage Failure] | none — both withdrawn, the old stays [Active] (Operation 22, Operation 23) |
| any | id names nothing | [Not Known] | none (Operation 8, Operation 14) |
| [Active For] | task has a live assignment | that assignment | none — the call reads (Operation 25, Operation 29) |
| [Active For] | task is unassigned | `none` | none (Operation 26) |
| [History For] | any task | every assignment for it, by `assigned_at` | none (Operation 27, Operation 28, Operation 30) |

WHY:
Reassign is one commit and not a recall followed by an assign, which is the whole reason the operation exists: the two-call version leaves a window where the task is nobody's, and a system that reports coverage during that window reports a gap that never should have opened (Operation 20, Invariant 7.1). Its failure arm is the expensive one — two writes, and a partial landing leaves the task unassigned after a call the caller believes succeeded — so the withdrawal is stated rather than assumed (Operation 23, Reassign atomicity 1–4). Both stamps come from one clock reading, the discipline [Retention Window](./retention-window.md) states for its purge: two readings would drift the successor's `assigned_at` from the predecessor's `transferred_at`, and Check 2.3 reads a handoff by that equality (Operation 30a, Operation 30b).

### Invariants

- **Invariant 1 — At most one Active assignment per task.**
  ```text
  Invariant 1.1: Two active assignments MUST NOT share a task_ref.
  ```
- **Invariant 2 — Assignment immutability.**
  ```text
  Invariant 2.1: A recorded assignment's assignment_id, task_ref, assignee_ref and assigned_at MUST NOT change.
  ```
- **Invariant 3 — Status monotonicity.**
  ```text
  Invariant 3.1: A status MUST move from active to EXACTLY ONE OF recalled, transferred.
  Invariant 3.2: A status MUST NOT move to active from a terminal status.
  ```
- **Invariant 4 — Terminal states are absorbing.**
  ```text
  Invariant 4.1: A recalled assignment MUST NOT take a further transition.
  Invariant 4.2: A transferred assignment MUST NOT take a further transition.
  ```
- **Invariant 5 — Id stability.**
  ```text
  Invariant 5.1: [Assign] MUST set the assignment_id.
  Invariant 5.2: An assignment_id MUST NOT change.
  ```
- **Invariant 6 — No id reuse.**
  ```text
  Invariant 6.1: Two assignments MUST NOT share an assignment_id.
  ```
- **Invariant 7 — Reassign atomicity.**
  ```text
  Invariant 7.1: A task_ref MUST carry EXACTLY ONE active assignment once [Reassign] lands.
  Invariant 7.2: The reassigned assignment MUST stand in transferred once [Reassign] lands.
  Invariant 7.3: A reader MUST NOT observe two active assignments for one task_ref.
  Invariant 7.4: A reader MUST NOT observe the task_ref unassigned once the first write lands AND the second write NOT EXISTS.
  ```
- **Invariant 8 — Timestamp ordering.**
  ```text
  Invariant 8.1: assigned_at MUST NOT EXCEED recalled_at ONLY IF recalled_at EXISTS.
  Invariant 8.2: assigned_at MUST NOT EXCEED transferred_at ONLY IF transferred_at EXISTS.
  Invariant 8.3: The atom MUST stamp EVERY timestamp once.
  ```
  WHY: best-effort under a clock that moves backward; a stamp is never re-derived from a later reading (Clock semantics 1–3).
- **Invariant 9 — Complete responsibility history.**
  ```text
  Invariant 9.1: The assignments carrying one task_ref MUST record EVERY actor who held the task.
  Invariant 9.2: The assignments carrying one task_ref MUST record when each holding began.
  Invariant 9.3: The assignments carrying one task_ref MUST record how each holding ended.
  ```
- **Invariant 10 — Assignment store durability.**
  ```text
  Invariant 10.1: The atom MUST NOT delete an assignment record.
  Invariant 10.2: The assignment set MUST NOT shrink.
  ```

At-most-one and reassign atomicity give the *unambiguous accountability* property — *who is responsible for this task?* has one answer or none, never two. Immutability, the complete history and durability give *auditability* — the chain is the store, and nothing leaves it quietly.

## Examples

The same atom, four domains, identical mechanic.

### Project management — task handoff mid-sprint

A sprint board has a task *"implement login flow"* (task_ref: `task_t44`). The engineering manager assigns it to a developer: `assign(task_t44, dev_alice) → assignment_id a1`. Alice picks it up. Mid-sprint, Alice is pulled onto a production incident; the manager reassigns: `reassign(a1, dev_bob) → a2`. Alice's assignment (`a1`) moves to [Transferred]; Bob's (`a2`) is now [Active]. The sprint retrospective can reconstruct: Alice held the task from day 1 to day 4; Bob held it from day 4 to completion. At no point was the task unassigned.

### Customer support — ticket escalation

A support ticket is auto-assigned to a tier-1 agent: `assign(ticket_t99, agent_tier1_j) → a5`. The agent cannot resolve the issue; they escalate. The supervisor calls `reassign(a5, agent_tier2_k) → a6`. Tier-2 resolves it. The audit log shows: tier-1 held the ticket for 2 hours, tier-2 for 45 minutes. If the customer complains about resolution time, both ownership windows are on record. SLA (Service-Level Agreement — a commitment to a measurable level of service, such as a maximum resolution time) calculations use the [Assigned At] and [Transferred At] of each assignment record.

### Healthcare — patient-to-nurse assignment on a ward

A patient is admitted and assigned to the on-call nurse: `assign(patient_p31, nurse_n7) → a12`. At shift change, the charge nurse reassigns: `reassign(a12, nurse_n14) → a13`. If a clinical incident occurs overnight, the investigation can determine which nurse held the assignment at what time. The assignment store is the accountability record; the clinical event log (Event Log atom) is the action record; both compose to answer the investigation's questions.

### Rejection paths

A single sequence exercising all rejection reasons:

- `assign(task_t1, dev_a) → a1` — accepted.
- `assign(task_t1, dev_b)` → rejected `already-assigned` (Invariant 1; `task_t1` already has an [Active] [Assignment] in `a1`).
- `recall(unknown_id)` → rejected `not-known`.
- `recall(a1) → ok` — `a1` moves to [Recalled]; `task_t1` is now unassigned.
- `recall(a1)` → rejected `not-active` (a1 is already [Recalled]; terminal).
- `reassign(a1, dev_c)` → rejected `not-active` (a1 is terminal).
- `assign(task_t1, dev_b) → a2` — accepted; `task_t1` is now unassigned so a fresh [Assignment] is allowed.
- `reassign(a2, "")` → rejected `invalid-request` (empty assignee).
- `assign(task_t2, dev_c)` → rejected `storage-failure` (store write fails; no [Assignment] created; `task_t2` remains unassigned).

All five rejection reasons (`invalid-request`, `already-assigned`, `not-known`, `not-active`, `storage-failure`) exercised in one thread.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the assignment store's stored fields, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```text
Check 1.1: An auditor MUST find no task_ref carrying two active assignments (Invariant 1.1).
Check 2.1: An auditor MUST reconstruct a task's chain of responsibility from the assignments carrying the task_ref (Invariant 9.1, Invariant 9.2, Invariant 9.3).
Check 2.2: An auditor MUST read a recalled assignment as the task standing unassigned at recalled_at (Operation 12).
Check 2.3: An auditor MUST read a transferred assignment as a successor standing active at transferred_at (Invariant 7.1, Invariant 7.2).
Check 3.1: An auditor MUST find no assignment whose status moved out of a terminal status (Invariant 3.2, Invariant 4.1, Invariant 4.2).
Check 4.1: An auditor MUST find no assignment whose assigned_at EXCEEDS the assignment's terminal stamp (Invariant 8.1, Invariant 8.2).
Check 5.1: An auditor MUST identify which composing patterns a deployment wired in (Composition note 1).
```

### External checks

```text
External check 1: An auditor MUST read the assigner's authority from the composing [Permissions](./permissions.md) records (Non-goal 5).
External check 2: An auditor MUST read who issued an assignment from the composing [Actor Identity](./actor-identity.md) attestations (Non-goal 7).
External check 3: An auditor MUST read a task's completion from the host's task system (Non-goal 11).
External check 4: An auditor MUST read the serialization evidence from the deployment's own concurrency probe (Invariant 7.3, Invariant 7.4, Assign race 1).
```

NOTE: Invariant 7.3 and Invariant 7.4 forbid a reader *observing* a state. Records written after the fact cannot show what was observable between two writes, so no conformance check clears them and External check 4 names the probe that can — the records-alone gap `open-questions.md` §*Generation trust* docks, with its first load-bearing resident (CR-14).

NOTE: EVERY check names the rule the check tests. The assignment store answers *who holds this and who held it*; who was allowed to hand it over, and whether the work is done, are the composing patterns' records.

## Non-goals

```text
Non-goal 1: The atom MUST NOT require an assignee's acceptance.
Non-goal 2: A deployment needing acceptance MUST compose an acceptance pattern.
Non-goal 3: The atom MUST NOT expire an assignment.
Non-goal 4: A deployment needing a time-bounded assignment MUST compose a temporal-grant pattern.
Non-goal 5: The atom MUST NOT check an assigner's authority.
Non-goal 6: A deployment needing an authorized assigner MUST compose [Permissions](./permissions.md).
Non-goal 7: The atom MUST NOT record who issued an assignment.
Non-goal 8: A deployment needing assigner attribution MUST compose [Actor Identity](./actor-identity.md).
Non-goal 9: The atom MUST NOT cap an assignee's active assignments.
Non-goal 10: The atom MUST NOT bind two assignees to one active assignment.
Non-goal 11: The atom MUST NOT read a task's state.
Non-goal 12: The atom MUST NOT recall an assignment on the task's completion.
```

WHY:
The atom binds and records; every judgment around the binding is somebody else's. Acceptance, deadlines, authority and attribution each compose (Non-goal 1–8). A workload cap is a Capacity Constraint pattern reading the assignee's live count before the assign, which this atom deliberately does not count (Non-goal 9). Team assignment — where any member may act — is a different concept and not a wider `assignee_ref` (Non-goal 10). Completion is the task system's event: the composing pattern decides whether a finished task leaves its assignment standing as an attribution record or is recalled to close the lifecycle, and both are ordinary (Non-goal 12, Composition note 4).

Where the atom breaks down: when responsibility is genuinely shared at the same time; when an assignment must end on its own without anyone withdrawing it; when the assigner must be authorized before assigning; when the assignee must consent before holding.

## Edge cases

### Reassign atomicity

```text
Reassign atomicity 1: The implementation MUST commit the transferred write and the active write together.
Reassign atomicity 2: A crash inside [Reassign] MUST NOT leave the task_ref unassigned.
Reassign atomicity 3: A crash inside [Reassign] MUST NOT leave two active assignments for one task_ref.
Reassign atomicity 4: An implementation that cannot withdraw a landed write MUST NOT accept a further call BEFORE the implementation repairs the partial state.
```

WHY:
The dangerous half is the quiet one: old marked transferred, successor never written, task unassigned, and the caller told the handoff succeeded. Invariant 1.1 is satisfied vacuously by that state; Reassign atomicity 2 forbids the crash residue and Invariant 7.4 forbids any reader seeing the gap, whether transient or stable — and an implementation without rollback owes a repair pass rather than a note in a runbook (`execution-contract.md` §Multi-write atomicity).

### The assign race

```text
Assign race 1: The implementation MUST make the active-assignment check and the write one transition.
Assign race 2: The implementation MUST NOT record two active assignments for one task_ref under concurrent calls.
Assign race 3: The second concurrent [Assign] for one task_ref MUST answer already-assigned.
```

### Clock semantics

```text
Clock semantics 1: The deployment MUST own the clock's monotonicity.
Clock semantics 2: The deployment MUST own the clock's timezone handling.
Clock semantics 3: The atom MUST NOT re-derive a stamp from a later reading.
```

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own what a task is.
Composition note 3: A composing pattern MUST own whether an assignee may hold the task.
Composition note 4: A composing pattern MUST own whether a completed task's assignment is recalled.
Composition note 5: A composing pattern needing assigner attribution MUST attest [Assign] under the assigner's credential.
```

WHY:
[Shared Todo](../compositions/shared-todo.md) is the landed wiring: [Personal Todo](./personal-todo.md) supplies the task, [Permissions](./permissions.md) gates who may act, and this atom binds responsibility — three atoms, one multi-actor list, none of them knowing the others' rules. Attribution composes the same way [Attributed Permissions Admin](../compositions/attributed-permissions-admin.md) does it for grants: an [Actor Identity](./actor-identity.md) attestation beside the record, never a field added here (Composition note 5). Forthcoming: Acceptance, Temporal Grant, Capacity Constraint, Team Assignment.

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; an assigner; an assignee; an auditor; a reader; the store; an assignment; a task; a call; a crash.

Terms › `records`: `assignment` — one binding, carrying `assignment_id`, `task_ref`, `assignee_ref`, `assigned_at`, `status` and, once it ends, `recalled_at` or `transferred_at`.

Terms › `record verbs`: identify, allocate, supply, reuse, carry, stand, stamp, offer, delete, hold, record, answer, leave, write, read, commit, withdraw, order, set, change, move, take, share, observe, shrink, make, repair, accept, require, expire, check, cap, bind, recall, compose, own, attest, declare, find, reconstruct, identify, re-derive, exceed.

Terms › `value sets`: assign answers = assignment_id | rejected(invalid-request | already-assigned | storage-failure). recall answers = ok | rejected(not-known | not-active | storage-failure). reassign answers = new_assignment_id | rejected(not-known | not-active | invalid-request | storage-failure). active_for answers = an assignment | none. history_for answers = the assignments carrying the task_ref, by assigned_at. `status` = active | recalled | transferred.

Terms › `bounds`: empty.

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-12).

Terms › `terms`: `assignment`, `assignment_id`, `task_ref`, `assignee_ref`, `seam`, `transition`, `business caller`, `now`, `status`, `assigned_at`, `recalled_at`, `transferred_at`, `new_assignee_ref`.

#### Assignment

The record this atom defines: a binding of a unit of work to the actor responsible for completing it. It carries its [Assignment Id], [Task Ref], [Assignee Ref], [Assigned At], the status field below, and — where applicable — [Recalled At] or [Transferred At]. The [Assignment Id], [Task Ref], [Assignee Ref], and [Assigned At] are immutable from creation. Its status field holds one of [Active], [Recalled], or [Transferred]; at most one [Assignment] per task is [Active] at any time.

Kind: Type

#### Status

The [Assignment]'s lifecycle state — [Active], [Recalled] or [Transferred]. Set to [Active] on creation; moves once, to one terminal state, and never back (Invariant 3.1, Invariant 3.2).

Kind:     Field
Field of: the assignment
Projects: status

#### Assign

The behavior that binds a unit of work to a responsible actor, recording a new [Assignment]. It assigns a fresh [Assignment Id] from injected id material at the seam, sets [Task Ref], [Assignee Ref], and [Assigned At] = [Now], enters the [Assignment] in [Active], and returns the [Assignment Id] (or a rejection naming the failed precondition). It refuses [Already Assigned] if an [Active] [Assignment] already exists for the [Task Ref].

Kind: Operation

#### Recall

The behavior that withdraws an [Active] [Assignment] without a successor, leaving the task unassigned. Permitted only on an [Active] [Assignment]; it moves the [Assignment] [Active] → [Recalled] and stamps [Recalled At]. On an unknown id it is rejected [Not Known]; on an already-terminal [Assignment] it is rejected [Not Active].

Kind: Operation

#### Reassign

The behavior that hands an [Active] [Assignment] off to a new actor atomically. In one committed step it moves the old [Assignment] [Active] → [Transferred] (stamping [Transferred At]) and creates a new [Active] [Assignment] for the same [Task Ref] with the [New Assignee Ref]; it returns the new [Assignment Id]. There is no observable state in which both are [Active] or neither is (Invariant 7).

Kind: Operation

#### Active For

The read query that returns the at-most-one [Active] [Assignment] for a given [Task Ref], or `none` if the task is currently unassigned. Read-only; consistent with Invariant 1.

Kind: Operation

#### History For

The read query that returns all assignments ([Active], [Recalled], [Transferred]) for a given [Task Ref], ordered by [Assigned At] — the complete responsibility chain required by Invariant 9. Read-only.

Kind: Operation

#### Assignment Id

The opaque, immutable identity of an [Assignment], host-allocated from injected id material at the I/O seam and never reused after a terminal state. The [Task Ref] and [Assignee Ref] are properties of the [Assignment], not its identity.

Kind:     Field
Field of: Assignment
Projects: assignment_id

#### Task Ref

The opaque reference identifying the unit of work an [Assignment] is for. The atom does not know what a task is or how its lifecycle is managed. Set on creation, immutable thereafter.

Kind:     Field
Field of: Assignment
Projects: task_ref

#### Assignee Ref

The opaque reference identifying the actor an [Assignment] binds responsibility to. The actor registry is a separate concept. Set on creation, immutable thereafter.

Kind:     Field
Field of: Assignment
Projects: assignee_ref

#### Assigned At

The wall-time the [Assignment] was created, stamped from the injected [Now] on [Assign] (and on the [Assign] inside [Reassign]). Immutable thereafter. [Assigned At] ≤ [Recalled At] and [Assigned At] ≤ [Transferred At] always hold.

Kind:     Field
Field of: Assignment
Projects: assigned_at

#### Recalled At

The wall-time the [Assignment] was recalled, stamped from the injected [Now] on [Recall]. Present only in [Recalled]; immutable once set.

Kind:     Field
Field of: Assignment
Projects: recalled_at

#### Transferred At

The wall-time the [Assignment] was transferred, stamped from the injected [Now] on [Reassign]. Present only in [Transferred]; immutable once set.

Kind:     Field
Field of: Assignment
Projects: transferred_at

#### New Assignee Ref

The reference to the new responsible actor [Reassign] consumes and writes into the new [Active] [Assignment]'s [Assignee Ref]. Required well-formed and non-empty. It is not stored under its own name — only the new [Assignment]'s [Assignee Ref] is stored.

Kind:         Parameter
Parameter of: Reassign
Projects:     new_assignee_ref

#### Now

The current clock reading every writing action consumes — the pipeline's `clock_t`, supplied at the atom's seam, never read inside the transition and never a signature parameter. Its only use is the immutable timestamp stamps inside committed transitions ([Assigned At], [Recalled At], [Transferred At]).

Kind:         Parameter
Parameter of: Assign, Recall and Reassign
Projects:     now

#### Active

The single non-terminal state: the [Assignment] is in force and the assignee is the current responsible actor for the task. At most one [Assignment] per [Task Ref] is [Active]. The lifecycle proceeds [Active] → one of {[Recalled], [Transferred]}.

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

The refusal [Assign] returns when [Task Ref] or [Assignee Ref] is not well-formed or is empty, and [Reassign] returns when [New Assignee Ref] is not well-formed or is empty. A guard rejection that fails before any store write; no [Assignment] is created or changed.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  invalid-request

#### Already Assigned

The refusal [Assign] returns when an [Active] [Assignment] already exists for the [Task Ref]. The loser of a concurrent assign race for the same [Task Ref] also receives this. No [Assignment] is created. This is the at-most-one-Active guard (Invariant 1) enforced at the [Assign] boundary.

Kind:      Member
Member of: the Assign rejection
Role:      Outcome
Projects:  already-assigned

#### Not Known

The refusal [Recall] or [Reassign] returns when the supplied [Assignment Id] references no known [Assignment]. A lookup miss, distinct from a state rejection.

Kind:      Member
Member of: the resolving-action rejection
Role:      Outcome
Projects:  not-known

#### Not Active

The refusal [Recall] or [Reassign] returns when the referenced [Assignment] is already terminal — [Recalled] or [Transferred]. This is the terminal-absorption guard: a resolving action on an already-resolved [Assignment] is refused without modifying any record.

Kind:      Member
Member of: the resolving-action rejection
Role:      Outcome
Projects:  not-active

#### Storage Failure

The refusal any action returns when the store write fails after the preconditions pass. No [Assignment] is created (for [Assign]), the [Assignment] remains [Active] (for [Recall]), or both [Reassign] writes are rolled back. The caller must treat it as definitive.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Assignment]: #assignment
[Assign]: #assign
[Recall]: #recall
[Reassign]: #reassign
[Active For]: #active-for
[History For]: #history-for
[Assignment Id]: #assignment-id
[Task Ref]: #task-ref
[Assignee Ref]: #assignee-ref
[Assigned At]: #assigned-at
[Recalled At]: #recalled-at
[Transferred At]: #transferred-at
[New Assignee Ref]: #new-assignee-ref
[Now]: #now
[Active]: #active
[Recalled]: #recalled
[Transferred]: #transferred
[Invalid Request]: #invalid-request
[Already Assigned]: #already-assigned
[Not Known]: #not-known
[Not Active]: #not-active
[Storage Failure]: #storage-failure

---

## Standards references

Assignment is a productivity primitive with broad operational anchoring and lighter regulatory footprint than the compliance atoms:

- **ITIL (IT Infrastructure Library)** — incident and request management define assignment as the binding of a work item to a responsible individual or group. ITIL's assignment and escalation mechanics are the operational reference for the support-queue examples.
- **ISO/IEC 20000 (IT Service Management)** — formalizes incident assignment and reassignment as required process steps with audit-trail obligations. The assignment store satisfies the audit requirement.
- **HL7 FHIR (Health Level Seven Fast Healthcare Interoperability Resources — the standard for exchanging healthcare data electronically) Task resource** — healthcare task management defines assignment as a `Task.owner` binding, with history of ownership tracked per task. The atom's responsibility-history invariant (Invariant 9) is the FHIR-compatible form.
- **PMI PMBOK (Project Management Body of Knowledge)** — responsibility assignment matrices (RAM / RACI) are the structured form of the same mechanic: binding work packages to responsible individuals. The atom is the dynamic runtime form of a RACI row.
- **GDPR (EU General Data Protection Regulation) Article 5(1)(f) and Article 32** — in systems processing personal data, assignment records establish who had access and responsibility for personal data at what time. The assignment store is part of the accountability trail.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — freestanding-atom posture; the discipline of keeping accept/decline, authorization, capacity, and expiry as composing concepts rather than absorbing them.
- **Eiffel's design-by-contract** — preconditions on [Assign], [Recall], [Reassign]; named rejection reasons.

---


## Status

`grounded on Final Critique 4 — 2026-06-18` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-06-18
formal: verified — assignment.tla + 1 twin, 2026-06-03
last gate: 2026-06-18 — Final Critique 4, fresh reader — clean

open: none
```


## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/assignment.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the five actions as a signature block, the refusal order carried by each rule's own condition, the ten invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into assignment` prints nothing, so no number is frozen from outside.

NOTE: End of Assignment.
