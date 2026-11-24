---
title: Shared Todo
id: 26
audience: common
nav_order: 4
has_toc: true
toc: true
---

# Shared Todo

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## Summary

Shared Todo turns a single-user task list into a shared, multi-person one where every change is gated by a permission check and every task has at most one person responsible for it at a time.

It combines three simpler patterns: a task list (Personal Todo), a grant-based permission system (Permissions), and a responsibility-tracking pattern (Assignment). None of the three knows about the others — the task list has no notion of who is acting, the permission system treats access scopes as meaningless strings until the composition gives them meaning, and the responsibility tracker records who owns a task but does not enforce anything.

The composition wires them together so that every action passes a permission check first, deleting a task automatically recalls whoever was responsible for it, and two new queries become possible that no single pattern could answer alone: who is responsible for a task right now, and which tasks a given person is allowed to see.

Combining the patterns produces guarantees none has alone — no one can change the list beyond their granted permissions, no responsibility is left dangling against a deleted task, and the full history of who could do what and who owned what is provable. This is the standard building block for any collaborative task system where ownership and access control must be auditable.

The most common uses are software development sprint boards with role-based edit and assignment rights, support queue systems where tickets are assigned to agents with different tier-level access, clinical care planning where nurses and physicians share a task list but hold different permissions over it, and legal or compliance workflows where checklist items require clear ownership and an auditable record of who held which permission.

---

## Intent

Personal Todo is single-actor by design. It has no concept of who is acting, no concept of what different actors are allowed to do, and no concept of one actor being responsible for completing a task someone else created. Those three concepts — task lifecycle, authorization, and responsibility — are each freestanding atoms that compose cleanly. Shared Todo is the composition that wires them.

The pattern addresses the form of multi-actor work that recurs across virtually every collaborative domain: a development team's sprint board where every task is visible to each actor holding the view grant but editable only by actors holding the edit grant; a support queue where tickets are assigned to agents with different role-based access; a clinical care plan where nurses and physicians see the same task list but hold different permissions over it; a legal matter where paralegals and partners share a checklist with clear ownership of each item.

The shape is constant across all of them: actors see and act on tasks according to granted scopes (opaque permission tokens, such as `tasks:edit`, that the composition defines and Permissions enforces); at most one actor is responsible for a task at any given time; the full history of who held what permission and who was responsible for what task is provable.

This is a composition, not a new primitive. Personal Todo, Permissions, and Assignment are unchanged. The composition is the wiring that joins their three concepts — a single multi-actor task surface rather than three separate record sets the caller has to coordinate by hand.

---

## Composes

- **[Personal Todo](../atoms/personal-todo.md)** — the task lifecycle and its invariants.
- **[Permissions](../atoms/permissions.md)** — the authorization surface every state-changing action checks.
- **[Assignment](../atoms/assignment.md)** — the responsibility binding that names who is accountable for a task.

```
Composes 1: EXACTLY ONE Personal Todo instance MUST serve the composition.
Composes 2: EXACTLY ONE Permissions instance MUST serve the composition.
Composes 3: EXACTLY ONE Assignment instance MUST serve the composition.
Composes 4: The composition MUST NOT change a constituent's spec.
Composes 5: The composition MUST replace the constituents' own caller surface other than Permissions' grant surface, which the deployment administers (Composition note 4).
Composes 6: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 7: The composition MUST discharge Permissions Composition note 2.
Composes 8: The composition MUST discharge Assignment's Term task reference.
Composes 9: The composition MUST NOT answer a constituent's rejection changed.
```

Term composition: this pattern's wiring of [Personal Todo](../atoms/personal-todo.md), [Permissions](../atoms/permissions.md) and [Assignment](../atoms/assignment.md) — the gate, the cascade, the scope vocabulary and the actions below.

Term constituents: [Personal Todo](../atoms/personal-todo.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md).

Term caller surface: the actions and reads a constituent's own pattern declares to its callers — what a caller of that constituent alone would call.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST NOT store a record.
Composition state 2: The composition MUST derive the responsible actor from Assignment's active_for.
Composition state 3: The composition MUST derive the visible tasks from Personal Todo's records.
Composition state 4: The composition MUST NOT materialize a derived query.
```

Term task id: the Personal Todo id a call names a task by (Personal Todo's Id entry).

Term actor reference: the opaque reference a call carries for the actor making it; the composition checks it and never authenticates it (Non-goal 12).

Term responsible actor: the assignee reference of the active assignment Assignment's active_for answers for a task id — unassigned if Assignment answers none for a task id the Personal Todo instance carries, and not-known for a task id it does not carry.

Term visible tasks: EVERY task of the Personal Todo instance, for an actor reference holding tasks:view.

Term assignment id: the opaque identity of one assignment, which [Assign Task] and [Reassign Task] answer and [Reassign Task] and [Recall Assignment] take.

Term assignee reference: the opaque reference a call carries for the actor an assignment binds responsibility to; the composition passes it to Assignment and never interprets it.

Term unassigned: the answer [Responsible Actor] and [Active Assignment] give for a task id the Personal Todo instance carries where Assignment's active_for answers none.

Term new assignment id: the assignment id [Reassign Task] answers for the assignment it opens in place of the one it moves.

Term description: the text a task carries, which [Add Task] takes and Personal Todo validates.

Term new description: the text [Edit Task] sets in place of a task's description, which Personal Todo validates as it does a description.

Term done: Personal Todo's Done member of the unit state, which Personal Todo's complete sets.

Term reference: actor reference, assignee reference, task id OR assignment id — every opaque reference a call carries; the deployment canonicalizes each at the seam (Execution Contract Logic confinement 13).

### Capability requirement

```
Capability requirement 1: The deployment MUST supply the constituents' database PER Execution Contract Database 1 and Execution Contract Database 2.
Capability requirement 2: The deployment MUST supply now at the seam PER Personal Todo Capability requirement 1, Permissions Capability requirement 1 AND Assignment Capability requirement 1.
Capability requirement 3: The deployment MUST supply at the seam, for each [Assign Task] call and each [Reassign Task] call, an assignment id no assignment has carried PER Assignment Capability requirement 5.
```

### Primitive policy

```
Primitive policy 1: A deployment MAY declare the length bound of EVERY opaque input PER Execution Contract Input 2.
Primitive policy 2: The composition MUST answer a blank, malformed, over-bound input as the Closure table's Inputs rows say.
Primitive policy 3: The composition MUST check an input byte-exact.
Primitive policy 4: The composition MUST NOT change an input.
```

### Action wiring

```
add_task(actor_ref, description)
  answers task_id
  refuses permission-denied | invalid-description | duplicate-active | storage-failure

edit_task(actor_ref, task_id, new_description)
  answers ok
  refuses permission-denied | not-known | not-editable | invalid-description | duplicate-active | storage-failure

complete_task(actor_ref, task_id)
  answers ok
  refuses permission-denied | not-known | not-pending | storage-failure

delete_task(actor_ref, task_id)
  answers ok
  refuses permission-denied | not-known | storage-failure

assign_task(actor_ref, task_id, assignee_ref)
  answers assignment_id
  refuses permission-denied | not-known | invalid-request | already-assigned | storage-failure

reassign_task(actor_ref, assignment_id, new_assignee_ref)
  answers new_assignment_id
  refuses permission-denied | not-known | not-active | invalid-request | storage-failure

recall_assignment(actor_ref, assignment_id)
  answers ok
  refuses permission-denied | not-known | not-active | storage-failure

responsible_actor(actor_ref, task_id)
  answers assignee_ref | unassigned
  refuses permission-denied | not-known

visible_tasks(actor_ref)
  answers visible tasks
  refuses permission-denied

active_assignment(actor_ref, task_id)
  answers assignment_id | unassigned
  refuses permission-denied | not-known
```

```
Action wiring 1: The composition MUST call a constituent other than Permissions ONLY AFTER Permissions' permitted answers.
Action wiring 2: IF Permissions' permitted answers denied THEN the composition MUST answer permission-denied.
Action wiring 3: The composition MUST NOT call a constituent for a denied answer.
Action wiring 4: The composition MUST call Permissions' permitted with the call's actor reference.
Action wiring 5: An admitted add MUST call Personal Todo's add with the description.
Action wiring 6: An admitted edit MUST call Personal Todo's edit with the task id and the new description.
Action wiring 7: An admitted complete MUST call Personal Todo's complete with the task id.
Action wiring 8: An admitted complete MUST NOT recall the task's active assignment.
Action wiring 9: An admitted delete MUST call Assignment's active_for with the task id, and ONLY IF active_for answers an assignment MUST call Assignment's recall with that assignment's id.
Action wiring 10: An admitted delete of a task whose active_for answers an assignment MUST call Personal Todo's delete ONLY AFTER the recall answers ok.
Action wiring 10a: An admitted delete of a task whose active_for answers none MUST call Personal Todo's delete.
Action wiring 13: An admitted assign MUST answer not-known for a task id the Personal Todo instance does not carry.
Action wiring 14: An admitted assign MUST call Assignment's assign with the task id and the assignee reference ONLY AFTER Action wiring 13's existence check clears.
Action wiring 15: An admitted assign MUST accept a task id whose unit state EQUALS done.
Action wiring 16: An admitted reassign MUST call Assignment's reassign with the assignment id and the new assignee reference.
Action wiring 17: An admitted recall MUST call Assignment's recall with the assignment id.
Action wiring 18: An admitted state-changing action MUST answer a constituent call's refusal as that refusal, and otherwise the answer of the action's last constituent call.
Action wiring 19: The composition MUST NOT answer an empty task set for a denied tasks:view.
Action wiring 20: [Responsible Actor] MUST answer not-known for a task id the Personal Todo instance does not carry.
Action wiring 21: [Responsible Actor] MUST answer unassigned for a task id the Personal Todo instance carries where Assignment's active_for answers none.
Action wiring 23: [Active Assignment] MUST answer not-known and unassigned on the conditions Action wiring 20 and Action wiring 21 state for [Responsible Actor].
Action wiring 24: [Active Assignment] MUST call Assignment's active_for with the task id.
Action wiring 25: [Active Assignment] MUST answer the assignment id of the assignment active_for answers.
Action wiring 26: The composition MUST check whether the Personal Todo instance carries a task id by filtering Personal Todo's read for the task id.
```

Term admitted add: an [Add Task] call whose tasks:add check answered permitted.

Term admitted edit: an [Edit Task] call whose tasks:edit check answered permitted.

Term admitted complete: a [Complete Task] call whose tasks:complete check answered permitted.

Term admitted delete: a [Delete Task] call whose tasks:delete check answered permitted.

Term admitted assign: an [Assign Task] call whose tasks:assign check answered permitted.

Term admitted reassign: a [Reassign Task] call whose tasks:assign check answered permitted.

Term admitted recall: a [Recall Assignment] call whose tasks:recall check answered permitted.

#### Closure table

Every input an action takes, and every answer a constituent call can meet, with where the action lands it and the rule that owns the landing. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1); the composition maps each constituent refusal as the Contract's rule for a composing action does, propagated unchanged unless a rule here renames it (Execution Contract Substrate composition invocation). A call that never answers is the lost answer of Execution Contract Error model 1: its caller cannot tell whether the call landed, and the record a caller reads before retrying an [Assign Task] or a [Reassign Task] is [Active Assignment]. The enumeration is exhaustive: an answer a constituent adds is a row this table lacks.

**Inputs.**

| Action | Input | Lands | Owner |
|---|---|---|---|
| every action | an actor reference that is blank or malformed | Permissions' permitted answers denied, so permission-denied | Action wiring 2, 4; Permissions' Denied entry |
| [Edit Task], [Complete Task], [Delete Task] | a task id that is blank, malformed or names no task | not-known | Personal Todo's Not Known entry |
| [Assign Task] | a task id that is blank, malformed or names no task | not-known | Action wiring 13 |
| [Responsible Actor], [Active Assignment] | a task id that is blank, malformed or names no task | not-known | Action wiring 20, 23 |
| [Add Task], [Edit Task] | a description or a new description Personal Todo refuses | invalid-description or duplicate-active, propagated | Action wiring 5, 6, 18 |
| [Assign Task], [Reassign Task] | an assignee reference or a new assignee reference that is blank | invalid-request, propagated | Action wiring 14, 16, 18; Assignment's Invalid Request entry |
| [Reassign Task], [Recall Assignment] | an assignment id that names no assignment | not-known, propagated | Action wiring 16, 17, 18; Assignment's Not Known entry |

**Constituent calls.**

| Action | Call | Answer | Lands | Owner |
|---|---|---|---|---|
| every action | Permissions' permitted | permitted | the action's next call | Action wiring 1 |
| every action | Permissions' permitted | denied | permission-denied, no other constituent called | Action wiring 2, 3 |
| every action | any read of the database | fails | state-unavailable, unchanged, nothing written | Execution Contract Read 1, 3; Constituent failure 3 |
| every action | any call | never answers | no answer, the caller unable to tell whether the call landed | Execution Contract Error model 1 |
| [Add Task] | Personal Todo's add | the id | the task id | Action wiring 5, 18 |
| [Add Task] | Personal Todo's add | invalid-description, duplicate-active | propagated | Action wiring 5, 18; Composes 9 |
| [Edit Task] | Personal Todo's edit | ok | ok | Action wiring 6, 18 |
| [Edit Task] | Personal Todo's edit | not-known, not-editable, invalid-description, duplicate-active | propagated | Action wiring 6, 18; Composes 9 |
| [Complete Task] | Personal Todo's complete | ok | ok, the task's assignment left standing | Action wiring 7, 8, 18 |
| [Complete Task] | Personal Todo's complete | not-known, not-pending | propagated | Action wiring 7, 18; Composes 9 |
| [Delete Task] | Assignment's active_for | an assignment | the recall call | Action wiring 9 |
| [Delete Task] | Assignment's active_for | none | the delete call, no recall | Action wiring 9, 10a |
| [Delete Task] | Assignment's recall | ok | the delete call | Action wiring 9, 10 |
| [Delete Task] | Assignment's recall | not-known, not-active | none arises: the assignment the read found active is active when the recall runs, since the read and the recall are one transaction | Execution Contract Database 1, 2 |
| [Delete Task] | Personal Todo's delete | ok | ok, no grant record changed | Action wiring 10, 10a, 18; Invariant 5.2 |
| [Delete Task] | Personal Todo's delete | not-known | not-known, nothing written: no active assignment names a task id the Personal Todo instance does not carry | Action wiring 18; Invariant 3.2 |
| [Assign Task] | Personal Todo's read, filtered for the task id | the task id carried | the assign call | Action wiring 13, 14, 26 |
| [Assign Task] | Personal Todo's read, filtered for the task id | the task id not carried | not-known | Action wiring 13, 26 |
| [Assign Task] | Assignment's assign | the assignment id | the assignment id | Action wiring 14, 18 |
| [Assign Task] | Assignment's assign | invalid-request, already-assigned | propagated | Action wiring 14, 18; Composes 9 |
| [Reassign Task] | Assignment's reassign | the new assignment id | the new assignment id | Action wiring 16, 18 |
| [Reassign Task] | Assignment's reassign | not-known, not-active, invalid-request | propagated | Action wiring 16, 18; Composes 9 |
| [Recall Assignment] | Assignment's recall | ok | ok | Action wiring 17, 18 |
| [Recall Assignment] | Assignment's recall | not-known, not-active | propagated | Action wiring 17, 18; Composes 9 |
| [Responsible Actor] | Personal Todo's read, filtered for the task id | the task id not carried | not-known | Action wiring 20, 26 |
| [Responsible Actor] | Assignment's active_for | an assignment | the assignee reference of the assignment | Composition state 2; Term responsible actor |
| [Responsible Actor] | Assignment's active_for | none | unassigned | Action wiring 21 |
| [Visible Tasks] | Personal Todo's read | every unit | the visible tasks | Composition state 3; Term visible tasks |
| [Active Assignment] | Personal Todo's read, filtered for the task id | the task id not carried | not-known | Action wiring 23, 26 |
| [Active Assignment] | Assignment's active_for | an assignment | the assignment id | Action wiring 24, 25 |
| [Active Assignment] | Assignment's active_for | none | unassigned | Action wiring 23 |
| [Add Task], [Edit Task], [Complete Task], [Delete Task], [Assign Task], [Reassign Task], [Recall Assignment] | any constituent write | storage-failure | storage-failure, nothing committed, the writes of the action's earlier calls included | Execution Contract Constituent failure 1; Database 1 |

### Wiring decision

```
Wiring decision 1: The composition MUST own the cascade of a delete over an active assignment.
```

### Scope vocabulary

```
Scope vocabulary 1: The composition MUST define the action scopes the Permissions instance carries.
Scope vocabulary 2: The composition MUST gate [Responsible Actor] AND [Visible Tasks] AND [Active Assignment] on tasks:view.
Scope vocabulary 3: The composition MUST gate [Add Task] on tasks:add.
Scope vocabulary 4: The composition MUST gate [Edit Task] on tasks:edit.
Scope vocabulary 5: The composition MUST gate [Complete Task] on tasks:complete.
Scope vocabulary 6: The composition MUST gate [Delete Task] on tasks:delete.
Scope vocabulary 7: The composition MUST gate [Assign Task] on tasks:assign.
Scope vocabulary 8: The composition MUST gate [Reassign Task] on tasks:assign.
Scope vocabulary 9: The composition MUST gate [Recall Assignment] on tasks:recall.
Scope vocabulary 10: A deployment MAY define a finer action scope.
Scope vocabulary 11: A deployment defining a finer action scope MUST name the action scope the vocabulary names that the finer scope refines, and MUST gate that action on the finer action scope in addition to the action scope the vocabulary names.
```

Term action scopes: `tasks:view` | `tasks:add` | `tasks:edit` | `tasks:complete` | `tasks:delete` | `tasks:assign` | `tasks:recall` — the canonical vocabulary, and the minimum useful set.

---

## Composition-level invariants

Each of these is a property of the composed list. Invariant 1, 3, 4.1 and 5.2 need two or all three constituents working together; Invariant 2.1, 4.2 and 5.1 are one constituent's records, stated here because the closing claim rests on them.

- **Invariant 1 — Permission enforcement.**
  ```
  Invariant 1.1: IF a call changes a constituent's records THEN EVERY scope the call's action is gated on MUST answer permitted.
  Invariant 1.2: A denied answer MUST NOT reach a constituent.
  ```
- **Invariant 2 — At most one responsible actor per task.**
  ```
  Invariant 2.1: EVERY task MUST NOT carry two active assignments.
  ```
- **Invariant 3 — Cascade-on-delete.**
  ```
  Invariant 3.1: EVERY deleted task MUST carry no active assignment.
  Invariant 3.2: The composition MUST NOT leave an active assignment naming a task id the Personal Todo instance does not carry.
  ```
- **Invariant 4 — Responsibility queryability.**
  ```
  Invariant 4.1: [Responsible Actor]'s answer for EVERY task the Personal Todo records carry MUST derive from the Personal Todo records and the Assignment records alone.
  Invariant 4.2: The Assignment records MUST carry EVERY assignment a task has had, transferred and recalled ones included.
  ```
- **Invariant 5 — Authorization history completeness.**
  ```
  Invariant 5.1: The Permissions records MUST carry EVERY grant naming an actor reference, revoked ones included.
  Invariant 5.2: A task's delete MUST NOT change a grant record.
  ```

Permission enforcement and the cascade together give the coherent multi-actor surface: no actor acts beyond the actor's grants, and no assignment is left dangling against a deleted task. Responsibility queryability and authorization-history completeness together give recoverable accountability — for any task and any actor, what the actor was allowed to do and who held the task is provable.

---

## Examples

### Sprint board — role-based editing with task handoff

A four-person team. The engineering manager holds `tasks:view`, `tasks:assign`, and `tasks:delete` grants; developers hold `tasks:add`, `tasks:edit`, `tasks:complete`, and `tasks:view`. No developer holds `tasks:delete` or `tasks:assign`.

- Dev Alice calls `add_task(alice, "implement login flow") → task_t1`. Permitted: `tasks:add`. Task enters Pending.
- Manager calls `assign_task(manager, task_t1, alice) → assignment_a1`. Permitted: `tasks:assign`. Alice is now responsible.
- Alice calls `edit_task(alice, task_t1, "implement login flow — OAuth2 only") → ok`. Permitted: `tasks:edit`. (OAuth2 is an open standard for delegated sign-in.)
- Alice gets pulled onto an incident. Manager calls `reassign_task(manager, assignment_a1, bob) → assignment_a2`. Alice's assignment moves to Transferred; Bob is now responsible.
- Bob completes the task: `complete_task(bob, task_t1) → ok`. Assignment a2 remains Active — it becomes the completion-attribution record.
- Alice reads: `responsible_actor(alice, task_t1) → bob`, `active_assignment(alice, task_t1) → assignment_a2` and `visible_tasks(alice)` → every task of the list, `task_t1` among them. Each is permitted: `tasks:view`.
- Dev Carol tries `delete_task(carol, task_t1)` → permission-denied. Carol holds no `tasks:delete` grant.
- Manager calls `delete_task(manager, task_t1)`, and the database refuses the cascade's write: storage-failure, nothing committed. Assignment a2 is still Active and `task_t1` is still carried, since the recall and the delete are one transaction (Action wiring 9, 10; Execution Contract Database 1).
- Manager calls `delete_task(manager, task_t1)` again. Assignment a2 is recalled (cascade-on-delete); task_t1 is deleted.

The responsibility history is intact: a1 (Alice, Transferred at the reassign), a2 (Bob, Recalled by the delete), each with the instants Assignment stamped.

### Support queue — agent assignment and escalation

A support team has tier-1 and tier-2 agents and a supervisor. Agents at both tiers hold `tasks:complete` and `tasks:view`. The supervisor holds all scopes.

- A new ticket arrives. The supervisor calls `add_task(supervisor, "Customer cannot log in — account locked") → ticket_t22`.
- Supervisor assigns to tier-1 agent: `assign_task(supervisor, ticket_t22, agent_j) → assignment_b5`.
- Agent J investigates but cannot resolve. They have no `tasks:assign` grant, so they cannot reassign directly. They flag the supervisor.
- Supervisor calls `reassign_task(supervisor, assignment_b5, agent_k_tier2) → assignment_b6`. Tier-2 is now responsible.
- Tier-2 resolves: `complete_task(agent_k_tier2, ticket_t22) → ok`.
- The deployment recalls a resolved ticket's assignment (Composition note 3): `recall_assignment(supervisor, assignment_b6) → ok`. Permitted: `tasks:recall`. `responsible_actor(supervisor, ticket_t22) → unassigned`.

The Assignment records show: agent J held responsibility for 2 hours (Transferred); tier-2 agent K held it for 45 minutes (Active at completion, Recalled by the deployment right after). SLA (service-level agreement) analysis uses `assigned_at` and `transferred_at` per record.

### Clinical care plan — shared task list with role separation

A ward team: attending physician (all scopes), registered nurses (`tasks:view`, `tasks:complete`, `tasks:add`), orderlies (`tasks:view`, `tasks:complete`).

- Nurse adds a care task: `add_task(nurse_m, "Vitals check q4h — patient p31") → task_c7`. Permitted.
- Physician assigns it: `assign_task(physician, task_c7, nurse_m) → assignment_c1`. Nurse M is responsible.
- At shift change, physician reassigns: `reassign_task(physician, assignment_c1, nurse_n) → assignment_c2`.
- Orderly tries to add a task: `add_task(orderly_o, "Transport to radiology") → permission-denied`. Orderly holds no `tasks:add` grant.
- Nurse N completes the vitals check: `complete_task(nurse_n, task_c7) → ok`.

The accountability record is complete at the responsibility level: which nurse held responsibility at each shift, and which actor reference held which grants. No constituent records who invoked a reassignment: Assignment records the responsibility chain, not the acting caller. A regulated clinical deployment needing that record composes Audit Trail (Non-goal 7, External check 3).

---

## Generation acceptance

The closing claim above is the acceptance bar and this section distributes it: *for any task and any actor, what the actor was allowed to do and who held the task is provable.* Every check below clears from the three constituent records; where a claim needs evidence the records do not carry, it is an external check and says so.

### Conformance checks

```
Check 1.2: An auditor MUST find no active assignment naming a task id the Personal Todo records do not carry (Invariant 3.1, Invariant 3.2).
Check 2.1: An auditor MUST find no task id carrying two active assignments in the Assignment records (Invariant 2.1).
Check 3.1: An auditor MUST find a task's responsible actor from the Personal Todo and Assignment records, through [Responsible Actor] (Invariant 4.1).
Check 3.2: An auditor MUST find a task's responsibility sequence from the Assignment records, by filtering for the task id (Invariant 4.2).
Check 4.1: An auditor MUST find an actor reference's grant history in the Permissions records, by filtering the read's grants for the actor reference (Invariant 5.1).
Check 5.1: An auditor MUST find [Responsible Actor] answering unassigned for a task id the Personal Todo records carry where the Assignment records carry no active assignment for the task id (Action wiring 21).
Check 5.2: An auditor MUST find [Responsible Actor] answering not-known for a task id the Personal Todo records do not carry (Action wiring 20).
Check 5.3: An auditor MUST find [Active Assignment] answering the assignment id the Assignment records carry active for a task id (Action wiring 25).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the gate's order confirmed MUST read the deployment's own implementation (Invariant 1.1).
External check 2: An auditor needing a denied call confirmed unreached MUST read the deployment's own implementation (Invariant 1.2).
External check 3: An auditor needing an enumeration of authorization attempts MUST read a composed Audit Trail (Non-goal 7).
External check 4: An auditor needing the actor reference bound to a caller MUST read the deployment's binding of callers to actor references (Non-goal 12, Composition note 2).
External check 5: An auditor needing a task's delete confirmed clear of the grants MUST read the deployment's own implementation (Invariant 5.2).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT scope visibility per task.
Non-goal 2: The composition MUST NOT grant tasks:view with an assignment.
Non-goal 3: The composition MUST NOT refuse a self-assignment.
Non-goal 4: The composition MUST NOT own whether a completed task's assignment is recalled.
Non-goal 5: The composition MUST NOT offer an undo.
Non-goal 7: The composition MUST NOT record an action.
Non-goal 8: A deployment needing a tamper-evident record MUST compose Audit Trail.
Non-goal 9: The composition MUST NOT carry a task's priority.
Non-goal 10: The composition MUST NOT carry a task's due date.
Non-goal 11: The composition MUST NOT wire an action for Permissions' grant.
Non-goal 12: The composition MUST NOT authenticate an actor reference.
Non-goal 13: A deployment needing an authenticated actor reference MUST compose an authenticating pattern.
Non-goal 14: An authenticating pattern MUST supply the actor reference the composition checks.
Non-goal 15: The composition MUST NOT partition the Personal Todo instance's description uniqueness per actor.
Non-goal 16: The composition MUST NOT refuse an assignee reference on whether the assignee may hold the task.
Non-goal 17: The composition MUST NOT wire an action for a deprovisioning sweep.
```

NOTE: the owners — [Audit Trail](./audit-trail.md) (Non-goal 7, Non-goal 8, External check 3); [Attributed Permissions Admin](./attributed-permissions-admin.md) for a regulated deployment's grant administration (Non-goal 11); Execution Contract Database 5 (Non-goal 5); a priority and ordering pattern *(forthcoming)* (Non-goal 9); a due-date pattern *(forthcoming)* (Non-goal 10); the deployment (Non-goal 1, Non-goal 2, Non-goal 3, Non-goal 4 with Composition note 3, Non-goal 12 through 14 with Composition note 2, Non-goal 15, Non-goal 16 with Composition note 8, Non-goal 17 with Composition note 7).

---

## Edge cases

### Concurrency

```
Concurrency 4: The composition MUST check permitted at a call's start.
```

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A deployment MUST own the binding between a caller and the actor reference the caller's calls carry.
Composition note 3: A deployment MUST own whether a completed task's assignment is recalled, through a call of [Recall Assignment].
Composition note 4: A deployment MUST administer the Permissions instance's grants.
Composition note 5: A deployment MUST NOT wire a second Assignment instance over the task list.
Composition note 7: A deployment MUST own a departing actor reference's deprovisioning sweep.
Composition note 8: A deployment MUST own whether an assignee reference may hold a task.
```

---

## Terms

The canonical concepts this spec refers to. Each `[Term]` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind** — one of five: **Type** (a thing or category), **Operation** (a behavior), **Member** (a value of an enumerated Type), or, for a named datum, **Field** (a datum a Type carries — *what does it carry?*) or **Parameter** (a value an Operation needs — *what does it need?*). A term entry also names the Type it is a **Member of** / **Field of**, the Operation it is a **Parameter of**, and its **Role** where the domain assigns one. A term entry carries one **Projection** line — the concept's single canonical lowering token, the one place the concrete name stays visible on the pattern — for every Field, Parameter, and pinned/wire Member. Everything else about casing (each target's snake / camel / pascal / const / wire form) is **derived** from that one token by [`tools/harness/term-adapter.mjs`](https://github.com/scottromack/grace-commons/blob/main/tools/harness/term-adapter.mjs), never hand-written. This is a composition, so its own concepts are the composed action-wirings and derived queries plus the scope vocabulary it defines; references to the constituent atoms ([Personal Todo](../atoms/personal-todo.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md)) and their operations remain qualified calls to those atoms. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term terms: composition, constituents, caller surface, responsible actor, visible tasks, assignment id, assignee reference, unassigned, new assignment id, description, new description, done, reference, action scopes, admitted add, admitted edit, admitted complete, admitted delete, admitted assign, admitted reassign, admitted recall, task id, actor reference.

Term record verbs: call, answer, gate, define, derive, store, materialize, recall, delete, assign, reassign, add, edit, complete, read, write, check, leave, accept, refuse, carry, stand, follow, reach, find, name, own, discharge, inherit, change, replace, serve, compose, declare, bind, administer, wire, scope, grant, offer, record, authenticate, partition, outlive, supply.

Term actors: the composition; the constituents; a deployment; an auditor; an actor; an assignee; a task; an assignment; a grant; a caller.

Term cited: Execution Contract Conformance 8 — recursive conformance and the inherited guarantee. The section titled Composition state in `execution-contract.md` — the no-stored-state classification. [Permissions](../atoms/permissions.md) `Composition note 2` — the scope vocabulary. [Permissions](../atoms/permissions.md) `Composition note 3` — the caller-to-subject binding, left to the deployment (Composition note 2). [Permissions](../atoms/permissions.md) `Composition note 5` — a departing subject's deprovisioning sweep, left to the deployment (Composition note 7). [Assignment](../atoms/assignment.md) `Term task reference` — what a task is, which the host owns (Action wiring 13). [Assignment](../atoms/assignment.md) `Composition note 3` — whether an assignee may hold the task, left to the deployment (Composition note 8). [Assignment](../atoms/assignment.md) `Composition note 4` — the completed task's assignment, left to the deployment (Composition note 3).

#### Add Task

The composition action that adds a task to the shared list — gates on [Tasks Add] via Permissions, then delegates to Personal Todo's `add`. Returns the new task id, or [Permission Denied] before any delegated Personal Todo rejection.

Kind: Operation

#### Edit Task

The composition action that edits a pending task's description — gates on [Tasks Edit], then delegates to Personal Todo's `edit`. Rejected [Permission Denied] or a delegated Personal Todo rejection.

Kind: Operation

#### Complete Task

The composition action that marks a task done — gates on [Tasks Complete], then delegates to Personal Todo's `complete`. Does not auto-recall the task's Active assignment (that is deployment policy). Rejected [Permission Denied] or a delegated rejection.

Kind: Operation

#### Delete Task

The composition action that deletes a task — gates on [Tasks Delete], recalls any Active assignment first (the cascade-on-delete rule, Invariant 3), then delegates to Personal Todo's `delete`. Rejected [Permission Denied] or a delegated rejection.

Kind: Operation

#### Assign Task

The composition action that binds responsibility for a task to an actor — gates on [Tasks Assign], checks the task exists (Pending or Done; else not-known — the referential-integrity check Assignment delegates to its composing system), then delegates to Assignment's `assign`. Returns the new assignment_id, or [Permission Denied] / not-known / a delegated rejection.

Kind: Operation

#### Reassign Task

The composition action that moves responsibility to a new actor — gates on [Tasks Assign], then delegates to Assignment's `reassign`. Returns the new assignment_id, or [Permission Denied] / a delegated rejection.

Kind: Operation

#### Recall Assignment

The composition action that withdraws responsibility — gates on [Tasks Recall], then delegates to Assignment's `recall`. Rejected [Permission Denied] or a delegated rejection.

Kind: Operation

#### Responsible Actor

The derived read query joining Personal Todo and Assignment — gates on [Tasks View], then returns the actor holding the active assignment for a task, unassigned for a task id the Personal Todo instance carries where Assignment answers none, or not-known for a task id the Personal Todo instance does not carry, a deleted task's included (the join's existence side). Neither constituent answers it alone.

Kind: Operation

#### Visible Tasks

The derived read query joining Personal Todo and Permissions — returns the tasks an actor may see (all tasks under a [Tasks View] grant in the canonical list-level deployment), or [Permission Denied] without one. Neither constituent answers it alone.

Kind: Operation

#### Active Assignment

The derived read query joining Personal Todo, Permissions and Assignment — gates on [Tasks View], then returns the assignment id of the active assignment Assignment's `active_for` answers for a task id, unassigned for a task id the Personal Todo instance carries where Assignment answers none, or not-known for a task id the Personal Todo instance does not carry. It is the record a caller reads for the assignment id [Reassign Task] and [Recall Assignment] take, before retrying an [Assign Task] or [Reassign Task] whose answer was lost (Execution Contract Error model 1), since the composition replaces the constituents' own caller surface (Composes 5). No constituent answers it alone.

Kind: Operation

#### Tasks View

The scope permitting read of the shared task list (tasks and their assignees). Gates [Visible Tasks] and the other read queries; a list-level grant in the canonical deployment.

Kind:       Member
Member of:  the scope vocabulary
Role:       Scope
Projection: tasks:view

#### Tasks Add

The scope permitting [Add Task] (which delegates to Personal Todo's `add`).

Kind:       Member
Member of:  the scope vocabulary
Role:       Scope
Projection: tasks:add

#### Tasks Edit

The scope permitting [Edit Task] on any pending task.

Kind:       Member
Member of:  the scope vocabulary
Role:       Scope
Projection: tasks:edit

#### Tasks Complete

The scope permitting [Complete Task] on any task.

Kind:       Member
Member of:  the scope vocabulary
Role:       Scope
Projection: tasks:complete

#### Tasks Delete

The scope permitting [Delete Task] on any task.

Kind:       Member
Member of:  the scope vocabulary
Role:       Scope
Projection: tasks:delete

#### Tasks Assign

The scope permitting [Assign Task] and [Reassign Task].

Kind:       Member
Member of:  the scope vocabulary
Role:       Scope
Projection: tasks:assign

#### Tasks Recall

The scope permitting [Recall Assignment].

Kind:       Member
Member of:  the scope vocabulary
Role:       Scope
Projection: tasks:recall

#### Permission Denied

The composition's own rejection — returned by any composition action when the up-front Permissions check yields `denied`; it short-circuits before any constituent atom is invoked (Invariant 1).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: permission-denied

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Add Task]: #add-task
[Edit Task]: #edit-task
[Complete Task]: #complete-task
[Delete Task]: #delete-task
[Assign Task]: #assign-task
[Reassign Task]: #reassign-task
[Recall Assignment]: #recall-assignment
[Responsible Actor]: #responsible-actor
[Visible Tasks]: #visible-tasks
[Active Assignment]: #active-assignment
[Tasks View]: #tasks-view
[Tasks Add]: #tasks-add
[Tasks Edit]: #tasks-edit
[Tasks Complete]: #tasks-complete
[Tasks Delete]: #tasks-delete
[Tasks Assign]: #tasks-assign
[Tasks Recall]: #tasks-recall
[Permission Denied]: #permission-denied

---

## Standards references

Shared Todo is a wiring of three primitives and not a regulated pattern, so it carries no standard of its own at this layer and no regulated adversarial scenarios; the clinical example shows a role split, not a regulated acceptance bar. The standards it touches are its constituents' and are cited there: [Personal Todo](../atoms/personal-todo.md), [Permissions](../atoms/permissions.md) and [Assignment](../atoms/assignment.md).

## Status

`done — 2026-11-21` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-21
formal: verified — shared-todo.tla + 1 twin (2026-06-03); shared-todo.als + 8 twins (the static data model, 2026-11-12: Invariant 1.1, 1.2, 3.1, 3.2, 4.1 and 5.2 checked on every call of the composition, over what its transaction reads of the three constituents' records and what it leaves in them, Invariant 3.1 and 3.2 a cross-check with the TLA+ model; nothing testable in Alloy for Invariant 2.1, 4.2 and 5.1: whether two active assignments co-exist depends on the order of the calls that wrote them, Assignment's guard, which Assignment's own TLA+ model checks (Composes 6), and a whole history is that no record of it is later removed or rewritten, which a single state cannot show; the model found that Scope vocabulary 11 names no action for "that action", so whether a finer scope refining tasks:assign gates [Assign Task], [Reassign Task] or both is unsaid); coverage 2026-11-10 (unit formal: more coverage for the yes votes), 2026-11-12: owes TLA+ checks of Invariant 4.2 and 5.1 (across steps); owed rows: Invariant 4.2; Invariant 5.1, 2026-11-12
last gate: 2026-11-21 — Final Critique 12, frozen at f9d54b1c — delta, foundational count 0, clean, no sample; Linus's one report, read on Zen's minimax-m3 as the round's one pass, brought two foundational findings and a refining one, and both triages refuted all three, none by a cure (the settle's one edit is the sprint-board example's citation of the one transaction, which now names Execution Contract Database 1 beside Action wiring 9, 10): an assign racing a delete leaves no assignment on a deleted task, since Execution Contract Database 2 reads an action's guards inside the transaction that writes its effects, so no write commits against a state its guards did not see and a conflict is read again and decided again; two concurrent deletes of one task leave no loser whose recall answer is unowned, since the closure table's row for Assignment's recall answering not-known or not-active says none arises, the read and the recall being one transaction (Execution Contract Database 1, 2); and every action's scope is stated, in Scope vocabulary 2 through 9 and the admitted terms, so Action wiring 4 owes no scope of its own; 2026-11-05 — Final Critique 11, a delta round, frozen at 227ba75 — foundational count 0, clean, no sample; 2026-11-04 — Final Critique 10, frozen at 493f80f — foundational count 4, cured, not clean, no sample; Final Critique 9, 2026-09-30, cold reader — 0 foundational, 14 refining (8 already open, 6 routed open), 3 rhetorical (routed open)

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./shared-todo.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- compositions/shared-todo.md`.

</details>

NOTE: End of Shared Todo.
