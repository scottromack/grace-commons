---
title: Shared Todo
parent: Conceptual Compositions
nav_order: 4
has_toc: true
toc: true
---

# Shared Todo

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
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

The pattern addresses the form of multi-actor work that recurs across virtually every collaborative domain: a development team's sprint board where tasks are visible to all but editable only by their owners; a support queue where tickets are assigned to agents with different role-based access; a clinical care plan where nurses and physicians see the same task list but hold different permissions over it; a legal matter where paralegals and partners share a checklist with clear ownership of each item.

The shape is constant across all of them: actors see and act on tasks according to granted scopes (opaque permission tokens, such as `tasks:edit`, that the composition defines and Permissions enforces); one actor is responsible for each task at any given time; the full history of who held what permission and who was responsible for what task is provable.

This is a composition, not a new primitive. Personal Todo, Permissions, and Assignment are unchanged. The composition is the wiring that makes their three concepts coherent — a single multi-actor task surface rather than three separate record sets the caller has to coordinate by hand.

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
Composes 5: The composition MUST replace the constituents' own caller surface.
Composes 6: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 7: The composition MUST discharge Permissions Composition note 2.
Composes 8: The composition MUST discharge Assignment Composition note 2.
Composes 9: The composition MUST NOT answer a constituent's rejection changed.
```

Term composition: this pattern's wiring of [Personal Todo](../atoms/personal-todo.md), [Permissions](../atoms/permissions.md) and [Assignment](../atoms/assignment.md) — the gate, the cascade, the scope vocabulary and the actions below.

Term constituents: [Personal Todo](../atoms/personal-todo.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST NOT store a record.
Composition state 2: The composition MUST derive the responsible actor from Assignment's active_for.
Composition state 3: The composition MUST derive the visible tasks from Personal Todo's records.
Composition state 4: The composition MUST NOT materialize a derived query.
```

Term task id: the Personal Todo id a call names a task by (Action wiring 6).

Term actor reference: the opaque reference a call carries for the actor making it; the composition checks it and never authenticates it (Non-goal 12).

Term responsible actor: the assignee reference of the active assignment Assignment's active_for answers for a task id — none if Assignment answers none.

Term visible tasks: EVERY task of the Personal Todo instance, for an actor reference holding tasks:view.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply the constituents' database PER Execution Contract Database 1 and Execution Contract Database 2.
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
```

```
Action wiring 1: The composition MUST call a constituent ONLY AFTER Permissions' permitted answers.
Action wiring 2: IF Permissions' permitted answers denied THEN the composition MUST answer permission-denied.
Action wiring 3: The composition MUST NOT call a constituent for a denied answer.
Action wiring 4: The composition MUST call Permissions' permitted with the call's actor reference.
Action wiring 5: An admitted add MUST call Personal Todo's add with the description.
Action wiring 6: An admitted edit MUST call Personal Todo's edit with the task id and the new description.
Action wiring 7: An admitted complete MUST call Personal Todo's complete with the task id.
Action wiring 8: An admitted complete MUST NOT recall the task's active assignment.
Action wiring 9: An admitted delete MUST call Assignment's recall for the task's active assignment.
Action wiring 10: An admitted delete MUST call Personal Todo's delete ONLY AFTER the recall answers ok.
Deleted: Action wiring 11. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 12. Execution Contract Database 1 owns it.
Action wiring 13: An admitted assign MUST answer not-known for a task id the Personal Todo instance does not carry.
Action wiring 14: An admitted assign MUST call Assignment's assign ONLY AFTER the task id's existence check clears.
Action wiring 15: An admitted assign MUST accept a task id whose unit state EQUALS done.
Action wiring 16: An admitted reassign MUST call Assignment's reassign with the assignment id and the new assignee reference.
Action wiring 17: An admitted recall MUST call Assignment's recall with the assignment id.
Action wiring 18: The composition MUST answer the constituent's answer.
Action wiring 19: The composition MUST NOT answer an empty task set for a denied tasks:view.
Action wiring 20: [Responsible Actor] MUST answer not-known for a task id the Personal Todo instance does not carry.
Action wiring 21: [Responsible Actor] MUST answer unassigned for a task carrying no active assignment.
Deleted: Action wiring 22. Execution Contract Database 2 owns it.
```

Term admitted add: an [Add Task] call whose tasks:add check answered permitted.

Term admitted edit: an [Edit Task] call whose tasks:edit check answered permitted.

Term admitted complete: a [Complete Task] call whose tasks:complete check answered permitted.

Term admitted delete: a [Delete Task] call whose tasks:delete check answered permitted.

Term admitted assign: an [Assign Task] call whose tasks:assign check answered permitted.

Term admitted reassign: a [Reassign Task] call whose tasks:assign check answered permitted.

Term admitted recall: a [Recall Assignment] call whose tasks:recall check answered permitted.

### Wiring decision

```
Wiring decision 1: The composition MUST delete a task ONLY AFTER the task's active assignment is recalled.
Deleted: Wiring decision 2. Execution Contract Database 1 owns it.
Deleted: Wiring decision 3. Execution Contract Database 1 owns it.
```

WHY:
The cascade is the composition's load-bearing decision and neither constituent holds it — [Personal Todo](../atoms/personal-todo.md) knows nothing of assignments and [Assignment](../atoms/assignment.md) knows nothing of task deletion.

### Scope vocabulary

```
Scope vocabulary 1: The composition MUST define the action scopes the Permissions instance carries.
Scope vocabulary 2: The composition MUST gate [Responsible Actor] AND [Visible Tasks] on tasks:view.
Scope vocabulary 3: The composition MUST gate [Add Task] on tasks:add.
Scope vocabulary 4: The composition MUST gate [Edit Task] on tasks:edit.
Scope vocabulary 5: The composition MUST gate [Complete Task] on tasks:complete.
Scope vocabulary 6: The composition MUST gate [Delete Task] on tasks:delete.
Scope vocabulary 7: The composition MUST gate [Assign Task] on tasks:assign.
Scope vocabulary 8: The composition MUST gate [Reassign Task] on tasks:assign.
Scope vocabulary 9: The composition MUST gate [Recall Assignment] on tasks:recall.
Scope vocabulary 10: A deployment MAY define a finer action scope.
Scope vocabulary 11: A deployment defining a finer action scope MUST wire the gate to the finer action scope.
```

Term action scopes: `tasks:view` | `tasks:add` | `tasks:edit` | `tasks:complete` | `tasks:delete` | `tasks:assign` | `tasks:recall` — the canonical vocabulary, and the minimum useful set.

---

## Composition-level invariants

Each of these needs two or all three constituents working together. None is available from one atom called alone.

- **Invariant 1 — Permission enforcement.**
  ```
  Invariant 1.1: EVERY state-changing call MUST follow a permitted answer for the call's scope.
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
  Invariant 4.1: The Assignment instance MUST answer a task's responsible actor.
  Invariant 4.2: The Assignment instance MUST answer a task's responsibility history.
  ```
- **Invariant 5 — Authorization history completeness.**
  ```
  Invariant 5.1: The Permissions instance MUST answer an actor reference's grant history.
  Invariant 5.2: A task's delete MUST NOT change a grant record.
  Deleted: Invariant 6. Composes 6 owns it.
  Deleted: Invariant 7. Composes 6 owns it.
  Deleted: Invariant 8. Composes 6 owns it.
  ```

Permission enforcement and the cascade together give the coherent multi-actor surface: no actor acts beyond the actor's grants, and no assignment is left dangling against a deleted task. Responsibility queryability and authorization-history completeness together give recoverable accountability — for any task and any actor, what the actor was allowed to do and who held the task is provable.

---

## Examples

### Sprint board — role-based editing with task handoff

A four-person team. The engineering manager holds `tasks:view`, `tasks:assign`, and `tasks:delete` grants; developers hold `tasks:add`, `tasks:edit`, `tasks:complete`, and `tasks:view`. No developer holds `tasks:delete` or `tasks:assign`.

- Dev Alice calls `add_task(alice, "implement login flow") → task_t1`. Permitted: `tasks:add`. Task enters Pending.
- Manager calls `assign_task(manager, task_t1, alice) → assignment_a1`. Permitted: `tasks:assign`. Alice is now responsible.
- Alice calls `edit_task(alice, task_t1, "implement login flow — OAuth2 only") → ok`. Permitted: `tasks:edit`.
- Alice gets pulled onto an incident. Manager calls `reassign_task(manager, assignment_a1, bob) → assignment_a2`. Alice's assignment moves to Transferred; Bob is now responsible.
- Bob completes the task: `complete_task(bob, task_t1) → ok`. Assignment a2 remains Active — it becomes the completion-attribution record.
- Dev Carol tries `delete_task(carol, task_t1)` → permission-denied. Carol holds no `tasks:delete` grant.
- Manager calls `delete_task(manager, task_t1)`. Assignment a2 is recalled (cascade-on-delete); task_t1 is deleted.

The responsibility history is intact: a1 (Alice, day 1–4, Transferred), a2 (Bob, day 4–completion, Recalled-on-delete).

### Support queue — agent assignment and escalation

A support team has tier-1 and tier-2 agents and a supervisor. Agents at both tiers hold `tasks:complete` and `tasks:view`. The supervisor holds all scopes.

- A new ticket arrives. The supervisor calls `add_task(supervisor, "Customer cannot log in — account locked") → ticket_t22`.
- Supervisor assigns to tier-1 agent: `assign_task(supervisor, ticket_t22, agent_j) → assignment_b5`.
- Agent J investigates but cannot resolve. They have no `tasks:assign` grant, so they cannot reassign directly. They flag the supervisor.
- Supervisor calls `reassign_task(supervisor, assignment_b5, agent_k_tier2) → assignment_b6`. Tier-2 is now responsible.
- Tier-2 resolves: `complete_task(agent_k_tier2, ticket_t22) → ok`.

The Assignment records show: agent J held responsibility for 2 hours (Transferred); tier-2 agent K held it for 45 minutes (Active at completion). SLA (service-level agreement) analysis uses `assigned_at` and `transferred_at` per record.

### Clinical care plan — shared task list with role separation

A ward team: attending physician (all scopes), registered nurses (`tasks:view`, `tasks:complete`, `tasks:add`), orderlies (`tasks:view`, `tasks:complete`).

- Nurse adds a care task: `add_task(nurse_m, "Vitals check q4h — patient p31") → task_c7`. Permitted.
- Physician assigns it: `assign_task(physician, task_c7, nurse_m) → assignment_c1`. Nurse M is responsible.
- At shift change, physician reassigns: `reassign_task(physician, assignment_c1, nurse_n) → assignment_c2`.
- Orderly tries to add a task: `add_task(orderly_o, "Transport to radiology") → permission-denied`. Orderly holds no `tasks:add` grant.
- Nurse N completes the vitals check: `complete_task(nurse_n, task_c7) → ok`.

The accountability record is complete at the responsibility level: which nurse held responsibility at each shift, and which role level held which grants. Who *invoked* each reassignment is not recorded by any constituent here — Assignment records the responsibility chain, not the acting caller — so a regulated clinical environment needing invocation-level attribution composes the action surface with Audit Trail (which also makes the record tamper-evident and retention-bounded).

---

## Generation acceptance

The closing claim above is the acceptance bar and this section distributes it: *for any task and any actor, what the actor was allowed to do and who held the task is provable.* Every check below clears from the three constituent records; where a claim needs evidence the records do not carry, it is an external check and says so.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY assignment of a deleted task whose status EQUALS EXACTLY ONE OF recalled, transferred (Invariant 3.1).
Check 1.2: An auditor MUST find no active assignment naming a task id the Personal Todo records do not carry (Invariant 3.2).
Check 2.1: An auditor MUST find no task id carrying two active assignments in the Assignment records (Invariant 2.1).
Check 3.1: An auditor MUST find a task's responsible actor from the Assignment records (Invariant 4.1).
Check 3.2: An auditor MUST find a task's responsibility sequence from the Assignment records (Invariant 4.2).
Check 4.1: An auditor MUST find an actor reference's grant history in the Permissions records (Invariant 5.1).
Deleted: Check 4.2. External check 5 owns it.
Check 5.1: An auditor MUST find [Responsible Actor] answering unassigned for a task carrying no active assignment (Action wiring 21).
Check 5.2: An auditor MUST find [Responsible Actor] answering not-known for a task id the Personal Todo records do not carry (Action wiring 20).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the gate's order confirmed MUST read the deployment's own implementation (Invariant 1.1).
External check 2: An auditor needing a denied call confirmed unreached MUST read the deployment's own implementation (Invariant 1.2).
External check 3: An auditor needing an enumeration of authorization attempts MUST read a composed Audit Trail (Non-goal 7).
External check 4: An auditor needing the actor reference bound to a caller MUST read the deployment's authentication layer (Non-goal 12).
External check 5: An auditor needing a task's delete confirmed clear of the grants MUST read the deployment's own implementation (Invariant 5.2).
Deleted: External check 6. Execution Contract Database 2 owns it.
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT scope visibility per task.
Non-goal 2: The composition MUST NOT grant tasks:view with an assignment.
Non-goal 3: The composition MUST NOT refuse a self-assignment.
Non-goal 4: The composition MUST NOT own whether a completed task's assignment is recalled.
Non-goal 5: The composition MUST NOT offer an undo.
Deleted: Non-goal 6. Execution Contract Database 5 owns it.
Non-goal 7: The composition MUST NOT record an action.
Non-goal 8: A deployment needing a tamper-evident record MUST compose Audit Trail.
Non-goal 9: The composition MUST NOT carry a task's priority.
Non-goal 10: The composition MUST NOT carry a task's due date.
Non-goal 11: The composition MUST NOT wire an action for Permissions' grant.
Non-goal 12: The composition MUST NOT authenticate an actor reference.
Non-goal 13: A deployment needing an authenticated actor reference MUST compose an authenticating pattern.
Non-goal 14: An authenticating pattern MUST supply the actor reference the composition checks.
Non-goal 15: The composition MUST NOT partition the Personal Todo instance's description uniqueness per actor.
```

NOTE: the owners — [Audit Trail](./audit-trail.md) (Non-goal 7, Non-goal 8, External check 3); [Attributed Permissions Admin](./attributed-permissions-admin.md) for a regulated deployment (Non-goal 11, Composition note 4); the deployment (Non-goal 15).

---

## Edge cases

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Concurrency 4: The composition MUST check permitted at a call's start.
Deleted: Concurrency 5. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so a revoke of the grant a gate read commits before the read or after the action's writes.
Deleted: Concurrency 6. Execution Contract Database 2 owns it.
```

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A deployment MUST bind an actor reference to an authenticated caller.
Composition note 3: A deployment MUST own whether a completed task's assignment is recalled.
Composition note 4: A deployment MUST administer the Permissions instance's grants.
Composition note 5: A deployment MUST NOT wire a second Assignment instance over the task list.
Deleted: Composition note 6. Execution Contract Database 2 owns it.
```

---

## Terms

The canonical concepts this spec refers to. Each `[Term]` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind** — one of five: **Type** (a thing or category), **Operation** (a behavior), **Member** (a value of an enumerated Type), or, for a named datum, **Field** (a datum a Type carries — *what does it carry?*) or **Parameter** (a value an Operation needs — *what does it need?*). A term entry also names the Type it is a **Member of** / **Field of**, the Operation it is a **Parameter of**, and its **Role** where the domain assigns one. A term entry carries one **Projection** line — the concept's single canonical lowering token, the one place the concrete name stays visible on the page — for every Field, Parameter, and pinned/wire Member. Everything else about casing (each target's snake / camel / pascal / const / wire form) is **derived** from that one token by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs), never hand-written. This is a composition, so its own concepts are the composed action-wirings and derived queries plus the scope vocabulary it defines; references to the constituent atoms ([Personal Todo](../atoms/personal-todo.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md)) and their operations remain qualified calls to those atoms. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term terms: composition, constituents, responsible actor, visible tasks, action scopes, admitted add, admitted edit, admitted complete, admitted delete, admitted assign, admitted reassign, admitted recall, task id, actor reference.

Term record verbs: call, answer, gate, define, derive, store, materialize, recall, delete, assign, reassign, add, edit, complete, read, write, check, leave, accept, refuse, carry, stand, follow, reach, find, name, own, discharge, inherit, change, replace, serve, compose, declare, bind, administer, wire, scope, grant, offer, record, authenticate, partition, outlive, supply.

Term actors: the composition; the constituents; a deployment; an auditor; an actor; an assignee; a task; an assignment; a grant; a caller.

Term cited: Execution Contract Conformance 8 — recursive conformance and the inherited guarantee. The section titled Composition state in `execution-contract.md` — the no-stored-state classification. [Permissions](../atoms/permissions.md) `Composition note 2` — the scope vocabulary. [Permissions](../atoms/permissions.md) `Composition note 3` — the caller-to-subject binding, declined. [Assignment](../atoms/assignment.md) `Composition note 2` — what a task is. [Assignment](../atoms/assignment.md) `Composition note 4` — the completed task's assignment, declined.

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

The derived read query joining Personal Todo and Assignment — gates on [Tasks View], then returns the actor holding the active assignment for a task, unassigned for an existing task with none, or not-known for a task the database never held (the join's existence side). Neither constituent answers it alone.

Kind: Operation

#### Visible Tasks

The derived read query joining Personal Todo and Permissions — returns the tasks an actor may see (all tasks under a [Tasks View] grant in the canonical list-level deployment), or [Permission Denied] without one. Neither constituent answers it alone.

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

Shared Todo is a wiring of three primitives and not a regulated pattern, so it carries no standard of its own at this layer. The standards it touches are its constituents' and are cited there: [Personal Todo](../atoms/personal-todo.md), [Permissions](../atoms/permissions.md) and [Assignment](../atoms/assignment.md).

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — shared-todo.tla + 1 twin, 2026-06-03
last gate: 2026-09-30 — Final Critique 9, cold reader — 0 foundational, 14 refining (8 already open, 6 routed open), 3 rhetorical (routed open)

open:
- 2026-09-30-a · refining · Final Critique 7 · routed open, non-blocking: Action wiring 8 bars recall-on-complete that Non-goal 4 leaves to the deployment; the Summary's and Intent's overclaims (the list beyond granted permissions, owners-only editing, a query no single pattern answers); the unconditional Composition note 2 beside the conditional Non-goal 13; whether a finer scope replaces or adds to the canonical one; Assignment Composition note 3 and Permissions note 5 neither discharged nor declined, clock and ids absent from the deployment's notes; the delete with no active assignment unstated, Action wiring 14's arguments, Action wiring 1's wording; happy-path examples and the cascade recall's scope shown only in an example → one refining pass
- 2026-09-30-b · refining · Final Critique 8 · routed open, non-blocking: Action wiring 13, 14 and 20's existence check is a filter the composition runs over Personal Todo's Read (Operation 28), which offers no lookup by id, and no rule names it; Composes 5's caller surface read against Composition note 4's grant administration, which needs a Permissions surface the literal replacement removes; the clinical Example 3 invokes a regulated domain and Regulated adversarial scenarios stand nowhere in the examples, beside Standards references calling the pattern not regulated; Example 1's Recalled-on-delete is no fact of any record, since Assignment stores recalled and no cause → one refining pass
- 2026-09-30-c · rhetorical · Final Critique 8 · Term responsible actor says none where Action wiring 21 answers unassigned, and Tasks View promises the tasks and their assignees where Visible Tasks answers tasks only → one word for the absent answer; the term's promise cut to what the query returns
- 2026-09-30-d · refining · Final Critique 9 · routed open, non-blocking: Action wiring 18 answers the constituent's answer where a delete makes two constituent calls and responsible_actor answers an assignee where active_for answers an assignment; the sentence before the invariants says none is available from one atom, false for Invariants 2, 4 and 5, and Invariant 5.1 pins a by-subject history on Permissions, whose only read is every grant; Check 1.1 names a deleted task no database holds and collapses into Check 1.2 → one refining pass
- 2026-09-30-e · rhetorical · Final Critique 9 · Wiring decision 1 restates Action wiring 10; Example 3's which role level held which grants names roles Permissions does not hold → drop the restatement; say which actor reference held which grants
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/shared-todo.md`; the migration, the council read's collapse and the regeneration that got it here are in [its history](./shared-todo.hist.md).

- **2026-09-14 — Two constituent assignments are declined, and the declining is written down.** *Chose:* `Non-goal 4` and `Non-goal 12` to state the refusals, with `Composition note 2` and `Composition note 3` restating them as obligations on the deployment. *Over:* silence, which is what a composition usually offers for a note it does not take. *Because:* [Assignment](../atoms/assignment.md)'s `Composition note 4` and [Permissions](../atoms/permissions.md)'s `Composition note 3` both say *a composing pattern MUST own* — so a composition that neither owns nor names a receiver leaves an obligation falling between two layers with no rule anywhere naming who holds it. Passing an assignment down with the receiver named is the most a composition can do with one it does not want, and the corpus has no form for it (council read 55).

- **2026-10-20 — Undo History retired, and an undo is the store's history.** *Chose:* Non-goal 6, a deployment needing an undo composing Undo History, tombstoned to Execution Contract Store 5; rules 99 to 98. *Over:* an undo through a composition that replayed an event log of the list's actions. *Because:* the maintainer ruled 2026-10-20 that Undo History retires: Store 5 keeps every committed version of a record readable, so an undone deletion comes back with its id, timestamps and description. The composition itself still offers no undo (Non-goal 5). What the composition does for its domain is unchanged.

- **2026-10-21 — The store's guarantees cited, not restated, and a delete's recall and deletion one transaction.** *Chose:* the store supplied under Execution Contract Store 1 and Execution Contract Store 2 (Capability requirement 1), and the eleven rules that restated it, or existed only for a store that could split a write, tombstoned to their owner — to Store 1, under which a delete's recall and the task's deletion commit together: the bar on wrapping the two in one transaction, the recalled assignment left standing beside a task whose delete failed (Wiring decision 2, 3) and the bar on calling Personal Todo's delete after the recall answered storage-failure (Action wiring 12); and to Store 2, under which an action's guard reads and the writes they decide are one transaction: the host's serialization of two calls naming one task id and of two description writes, with the deployment's supply of it and its external check (Concurrency 1, 6, Composition note 6, External check 6), the answers it left the loser of two assigns and of two deletes (Concurrency 2, 3), a delete's second recall after the first answered not-active (Action wiring 22) and the bar on checking permitted again inside a call (Concurrency 5); with them the delete calls Personal Todo's delete once the recall answers ok rather than once the recall commits (Action wiring 10); rules 98 to 88. *Over:* a recall and a delete committed apart, recall first, so that a delete that failed left an over-recall rather than a dangling assignment, with the host serializing calls by task id and a grant revoked mid-call left to the deployment — the prose spec's design, which the GRACE rewrite carried as Wiring decision 2 and 3 and the Concurrency rules, and Final Critique 7 and 8 extended with Action wiring 22 and Concurrency 6. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included: Personal Todo's, Permissions' and Assignment's records are one store, so a delete's recall and its deletion commit together or not at all, and a delete that stops leaves neither an over-recall nor a dangling assignment. Store 2 reads the state an action's guards decide on — the permitted answer, the task's existence, its active assignment, the active set's descriptions — inside the transaction that writes the action's effects, so two calls on one task, two description writes and a reassign beside a delete are serialized for every deployment, and a revoke of a grant the gate read commits before the read or after the action's writes. The other calls a rule decided: Wiring decision 1 stays as the cascade's positive rule and the order of its calls inside the one transaction, Action wiring 11 still answers a recall's storage-failure, and Concurrency 4 still checks permitted at a call's start; the responsibility and grant histories are Assignment's and Permissions' own records with their own instants, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.

NOTE: End of Shared Todo.
