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

Combining the patterns produces guarantees none has alone — no one can change the list beyond their granted permissions, no responsibility is left dangling against a deleted task, and the full history of who could do what and who owned what is recoverable from the records. This is the standard building block for any collaborative task system where ownership and access control must be auditable.

The most common uses are software development sprint boards with role-based edit and assignment rights, support queue systems where tickets are assigned to agents with different tier-level access, clinical care planning where nurses and physicians share a task list but hold different permissions over it, and legal or compliance workflows where checklist items require clear ownership and an auditable record of who held which permission.

---

## Intent

Personal Todo is single-actor by design. It has no concept of who is acting, no concept of what different actors are allowed to do, and no concept of one actor being responsible for completing a task someone else created. Those three concepts — task lifecycle, authorization, and responsibility — are each freestanding atoms that compose cleanly. Shared Todo is the composition that wires them.

The pattern addresses the form of multi-actor work that recurs across virtually every collaborative domain: a development team's sprint board where tasks are visible to all but editable only by their owners; a support queue where tickets are assigned to agents with different role-based access; a clinical care plan where nurses and physicians see the same task list but hold different permissions over it; a legal matter where paralegals and partners share a checklist with clear ownership of each item.

The shape is constant across all of them: actors see and act on tasks according to granted scopes (opaque permission tokens, such as `tasks:edit`, that the composition defines and Permissions enforces); one actor is responsible for each task at any given time; the full history of who held what permission and who was responsible for what task is recoverable from the records alone.

This is a composition, not a new primitive. Personal Todo, Permissions, and Assignment are unchanged. The composition is the wiring that makes their three concepts coherent — a single multi-actor task surface rather than three separate record stores the caller has to coordinate by hand.

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
Composes 6: The composition MUST inherit a constituent's invariants PER the section titled Conformance in `execution-contract.md`.
Composes 7: The composition MUST discharge Permissions Composition note 2.
Composes 8: The composition MUST discharge Assignment Composition note 2.
Composes 9: The composition MUST NOT answer a constituent's rejection changed.
```

Term composition: this pattern's wiring of [Personal Todo](../atoms/personal-todo.md), [Permissions](../atoms/permissions.md) and [Assignment](../atoms/assignment.md) — the gate, the cascade, the scope vocabulary and the actions below.

Term constituents: [Personal Todo](../atoms/personal-todo.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md).

WHY:
Composes 6 is one rule where the prose carried three. [`execution-contract.md`](../execution-contract.md) §Conformance already settles it — *no composing layer is obligated to re-verify what the substrate's own conformance already establishes; inheriting a guarantee by reference is the point of naming a substrate* — so a composition that re-asserts each constituent's invariants as its own is restating a rule it cites (Authority 6, council read 53). What the prose's three rules carried beyond the blanket is Composes 9, which is not inherited at all: a constituent's guarantee says nothing about whether the composing layer relays the constituent's refusal intact, and this composition does.

Composes 7 and Composes 8 name the two constituent assignments this composition takes up. [Permissions](../atoms/permissions.md)'s `Composition note 2` assigns the scope vocabulary to a composing pattern; §Scope vocabulary is this composition owning it. [Assignment](../atoms/assignment.md)'s `Composition note 2` assigns *what a task is*; Action wiring 14's existence check is this composition owning it. Two further constituent notes are **not** discharged here and §Non-goals says so rather than leaving them silent — Assignment's `Composition note 4` (whether a completed task's assignment is recalled) and Permissions' `Composition note 3` (the caller-to-subject binding) are both passed to the deployment, which is a choice this composition makes and not an omission (council read 55).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST NOT store a record.
Composition state 2: The composition MUST derive the responsible actor from Assignment's active_for.
Composition state 3: The composition MUST derive the visible tasks from Personal Todo's store.
Composition state 4: The composition MUST NOT materialize a derived query.
```

Term task_id: the Personal Todo id a call names a task by (Action wiring 6).

Term actor_ref: the opaque reference a call carries for the actor making it; the composition checks it and never authenticates it (Non-goal 12).

Term responsible actor: the assignee_ref of the active assignment Assignment's active_for answers for a task_id — none if Assignment answers none.

Term visible tasks: EVERY task of the Personal Todo instance IF the actor_ref holds tasks:view — none otherwise.

WHY:
The contract classification is *conforming, no stored composition state* (`execution-contract.md` §Composition state), and there is no element to classify, which is that rule's best case. Both derived queries are joins over surfaces the constituents already declare, computed per call, so nothing here can go stale and nothing needs a rebuild.

[Responsible Actor] joins two constituents because one cannot answer it: Assignment alone cannot tell an unassigned task from a task that never existed, and the Personal Todo side of the join is exactly what separates `unassigned` from `not-known`.

### Action wiring

```
Action wiring 1: The composition MUST call a constituent ONLY AFTER Permissions' permitted answers.
Action wiring 2: IF Permissions' permitted answers denied THEN the composition MUST answer permission-denied.
Action wiring 3: The composition MUST NOT call a constituent for a denied answer.
Action wiring 4: The composition MUST call Permissions' permitted with the call's actor_ref.
Action wiring 5: An admitted add MUST call Personal Todo's add with the description.
Action wiring 6: An admitted edit MUST call Personal Todo's edit with the task_id and the new_description.
Action wiring 7: An admitted complete MUST call Personal Todo's complete with the task_id.
Action wiring 8: An admitted complete MUST NOT recall the task's active assignment.
Action wiring 9: An admitted delete MUST call Assignment's recall for the task's active assignment.
Action wiring 10: An admitted delete MUST call Personal Todo's delete ONLY AFTER the recall commits.
Action wiring 11: IF the recall answers storage-failure THEN an admitted delete MUST answer storage-failure.
Action wiring 12: IF the recall answers storage-failure THEN an admitted delete MUST NOT call Personal Todo's delete.
Action wiring 13: An admitted assign MUST answer not-known for a task_id the Personal Todo instance does not carry.
Action wiring 14: An admitted assign MUST call Assignment's assign ONLY AFTER the task_id's existence check clears.
Action wiring 15: An admitted assign MUST accept a task_id whose unit state EQUALS done.
Action wiring 16: An admitted reassign MUST call Assignment's reassign with the assignment_id and the new_assignee_ref.
Action wiring 17: An admitted recall MUST call Assignment's recall with the assignment_id.
Action wiring 18: The composition MUST answer the constituent's answer.
Action wiring 19: The composition MUST NOT answer an empty task set for a denied tasks:view.
```

Term admitted add: an [Add Task] call whose tasks:add check answered permitted.

Term admitted edit: an [Edit Task] call whose tasks:edit check answered permitted.

Term admitted complete: a [Complete Task] call whose tasks:complete check answered permitted.

Term admitted delete: a [Delete Task] call whose tasks:delete check answered permitted.

Term admitted assign: an [Assign Task] call whose tasks:assign check answered permitted.

Term admitted reassign: a [Reassign Task] call whose tasks:assign check answered permitted.

Term admitted recall: a [Recall Assignment] call whose tasks:recall check answered permitted.

WHY:
Action wiring 1 through 3 are the whole gate, stated once for seven actions rather than seven times. Every action's shape is identical — check, then call — and the rules below name only what each action does *after* the gate clears.

Action wiring 13 and Action wiring 14 pick up the referential-integrity delegation [Assignment](../atoms/assignment.md)'s `Composition note 2` hands to a composing pattern. Personal Todo retires an id permanently, so a deleted task_id can never return to legitimize a dangling assignment, which is what makes Invariant 3's *no active assignment on a deleted task* standing rather than delete-time only.

Action wiring 19 is a refusal to be helpful. An empty answer is a fact about the task set; a denied read is a fact about the caller, and a composition that returned the first for the second would make the two indistinguishable and would vary by deployment.

### Wiring decision

```
Wiring decision 1: The composition MUST delete a task ONLY AFTER the task's active assignment is recalled.
Wiring decision 2: The composition MUST NOT wrap the recall and the delete in one transaction.
Wiring decision 3: The composition MUST leave a recalled assignment standing for a delete that fails.
```

WHY:
The cascade is the composition's load-bearing decision and neither constituent holds it — [Personal Todo](../atoms/personal-todo.md) knows nothing of assignments and [Assignment](../atoms/assignment.md) knows nothing of task deletion. The ordering is what makes the failure safe rather than the transaction: recall first means a failed delete leaves an assignment Recalled against a task that still exists — an over-recall, which Assignment admits and [Responsible Actor] reports as `unassigned` — where delete-first would leave an Active assignment against a task that is gone, which Invariant 3 forbids. Invariant 3 is one-way on purpose, and Wiring decision 3 is the cost named rather than hidden.

### Scope vocabulary

```
Scope vocabulary 1: The composition MUST define the action scopes the Permissions instance carries.
Scope vocabulary 2: The composition MUST gate a read on tasks:view.
Scope vocabulary 3: The composition MUST gate an add on tasks:add.
Scope vocabulary 4: The composition MUST gate an edit on tasks:edit.
Scope vocabulary 5: The composition MUST gate a complete on tasks:complete.
Scope vocabulary 6: The composition MUST gate a delete on tasks:delete.
Scope vocabulary 7: The composition MUST gate an assign on tasks:assign.
Scope vocabulary 8: The composition MUST gate a reassign on tasks:assign.
Scope vocabulary 9: The composition MUST gate a recall on tasks:recall.
Scope vocabulary 10: A deployment MAY define a finer action scope.
Scope vocabulary 11: A deployment defining a finer action scope MUST wire the gate to the finer action scope.
```

Term action scopes: `tasks:view` | `tasks:add` | `tasks:edit` | `tasks:complete` | `tasks:delete` | `tasks:assign` | `tasks:recall` — the canonical vocabulary, and the minimum useful set.

WHY:
[Permissions](../atoms/permissions.md) treats an action scope as an opaque string and `Composition note 2` assigns the vocabulary to a composing pattern; this section is that assignment discharged. Scope vocabulary 7 and Scope vocabulary 8 share one scope deliberately — reassign is an assign with a recall folded in, and a deployment that wants them separable takes Scope vocabulary 10.

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
  WHY: this is Assignment's own guarantee holding over the composition's single instance (Composes 6). It is stated here because the *single instance* is this composition's decision — two Assignment instances over one task list would satisfy the atom and break the claim.
- **Invariant 3 — Cascade-on-delete.**
  ```
  Invariant 3.1: EVERY deleted task MUST carry no active assignment.
  Invariant 3.2: The composition MUST NOT leave an active assignment naming a task_id the Personal Todo instance does not carry.
  ```
- **Invariant 4 — Responsibility queryability.**
  ```
  Invariant 4.1: The Assignment instance MUST answer a task's responsible actor.
  Invariant 4.2: The Assignment instance MUST answer a task's responsibility history.
  ```
- **Invariant 5 — Authorization history completeness.**
  ```
  Invariant 5.1: The Permissions instance MUST answer an actor_ref's grant history.
  Invariant 5.2: A grant record MUST outlive the task the grant governed.
  Deleted: Invariant 6. Composes 6 owns it.
  Deleted: Invariant 7. Composes 6 owns it.
  Deleted: Invariant 8. Composes 6 owns it.
  ```
  WHY: the three deleted invariants each asserted that a constituent's invariants hold over this composition's instance. [`execution-contract.md`](../execution-contract.md) §Conformance already establishes it — conformance extends recursively, and no composing layer is obligated to re-verify what a constituent's own conformance establishes — so restating it three times was a citing spec restating a rule it cites (Authority 6, council read 53). What the prose carried beyond the blanket survives: the relay of an unchanged constituent rejection is Composes 9, and the single-instance decisions that make Assignment's and Permissions' guarantees *reachable* here are Composes 1 through 3.

Permission enforcement and the cascade together give the coherent multi-actor surface: no actor acts beyond the actor's grants, and no assignment is left dangling against a deleted task. Responsibility queryability and authorization-history completeness together give recoverable accountability — for any task and any actor, what the actor was allowed to do and who held the task is readable from the records alone.

---

## Examples

### Sprint board — role-based editing with task handoff

A four-person team. The engineering manager holds `tasks:view`, `tasks:assign`, and `tasks:delete` grants; developers hold `tasks:add`, `tasks:edit`, `tasks:complete`, and `tasks:view`. No developer holds `tasks:delete` or `tasks:assign`.

- Dev Alice calls `add_task(alice, "implement login flow") → task_t1`. Permitted: `tasks:add`. Task enters Pending.
- Manager calls `assign_task(manager, task_t1, alice) → assignment_a1`. Permitted: `tasks:assign`. Alice is now responsible.
- Alice calls `edit_task(alice, task_t1, "implement login flow — OAuth2 only") → ok`. Permitted: `tasks:edit`.
- Alice gets pulled onto an incident. Manager calls `reassign_task(manager, assignment_a1, bob) → assignment_a2`. Alice's assignment moves to Transferred; Bob is now responsible.
- Bob completes the task: `complete_task(bob, task_t1) → ok`. Assignment a2 remains Active — it becomes the completion-attribution record.
- Dev Carol tries `delete_task(carol, task_t1)` → `permission-denied`. Carol holds no `tasks:delete` grant.
- Manager calls `delete_task(manager, task_t1)`. Assignment a2 is recalled (cascade-on-delete); task_t1 is deleted.

The responsibility history is intact: a1 (Alice, day 1–4, Transferred), a2 (Bob, day 4–completion, Recalled-on-delete).

### Support queue — agent assignment and escalation

A support team has tier-1 and tier-2 agents and a supervisor. Agents at both tiers hold `tasks:complete` and `tasks:view`. The supervisor holds all scopes.

- A new ticket arrives. The supervisor calls `add_task(supervisor, "Customer cannot log in — account locked") → ticket_t22`.
- Supervisor assigns to tier-1 agent: `assign_task(supervisor, ticket_t22, agent_j) → assignment_b5`.
- Agent J investigates but cannot resolve. They have no `tasks:assign` grant, so they cannot reassign directly. They flag the supervisor.
- Supervisor calls `reassign_task(supervisor, assignment_b5, agent_k_tier2) → assignment_b6`. Tier-2 is now responsible.
- Tier-2 resolves: `complete_task(agent_k_tier2, ticket_t22) → ok`.

The assignment store records: agent J held responsibility for 2 hours (Transferred); tier-2 agent K held it for 45 minutes (Active at completion). SLA (service-level agreement) analysis uses `assigned_at` and `transferred_at` per record.

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

The closing claim above is the acceptance bar and this section distributes it: *for any task and any actor, what the actor was allowed to do and who held the task is readable from the records alone.* Every check below clears from the three constituent stores; where a claim needs evidence the stores do not carry, it is an external check and says so.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY assignment of a deleted task whose status EQUALS EXACTLY ONE OF recalled, transferred (Invariant 3.1).
Check 1.2: An auditor MUST find no active assignment naming a task_id the Personal Todo store does not carry (Invariant 3.2).
Check 2.1: An auditor MUST find no task_id carrying two active assignments in the Assignment store (Invariant 2.1).
Check 3.1: An auditor MUST find a task's responsible actor from the Assignment store (Invariant 4.1).
Check 3.2: An auditor MUST find a task's responsibility sequence from the Assignment store (Invariant 4.2).
Check 4.1: An auditor MUST find an actor_ref's grant history in the Permissions store (Invariant 5.1).
Check 4.2: An auditor MUST find a grant record for a task_id the Personal Todo store does not carry (Invariant 5.2).
Check 5.1: An auditor MUST find [Responsible Actor] answering unassigned for a task carrying no active assignment (Composition state 2).
Check 5.2: An auditor MUST find [Responsible Actor] answering not-known for a task_id the Personal Todo store does not carry (Composition state 2).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the gate's order confirmed MUST read the deployment's own implementation (Invariant 1.1).
External check 2: An auditor needing a denied call confirmed unreached MUST read the deployment's own implementation (Invariant 1.2).
External check 3: An auditor needing an enumeration of authorization attempts MUST read a composed Audit Trail (Non-goal 7).
External check 4: An auditor needing the actor_ref bound to a caller MUST read the deployment's authentication layer (Non-goal 12).
```

WHY:
The split is the honest one and it is the same shape [Session-Gated Authorization](./session-gated-authorization.md) found. The three stores record *what stands*: an assignment's terminal state, a grant's history, a task's existence — so Check 1.1 through 5.2 clear from records. They do not record *what was attempted*: a denied call writes nothing anywhere, so the count of refusals and the order of the two steps inside an admitted call leave no trace in any constituent store. That is External check 1 through 3, and it is why a regulated deployment composes [Audit Trail](./audit-trail.md) rather than reading harder.

External check 4 is the one a deployment can fail silently, and §Non-goals names it as a seam rather than a gap: every guarantee here is stated over the actor_ref values presented to the composition, and nothing here authenticates them.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT scope visibility per task.
Non-goal 2: The composition MUST NOT grant tasks:view with an assignment.
Non-goal 3: The composition MUST NOT refuse a self-assignment.
Non-goal 4: The composition MUST NOT own whether a completed task's assignment is recalled.
Non-goal 5: The composition MUST NOT offer an undo.
Non-goal 6: A deployment needing an undo MUST compose Undo History.
Non-goal 7: The composition MUST NOT record an action.
Non-goal 8: A deployment needing a tamper-evident record MUST compose Audit Trail.
Non-goal 9: The composition MUST NOT carry a task's priority.
Non-goal 10: The composition MUST NOT carry a task's due date.
Non-goal 11: The composition MUST NOT wire an action for Permissions' grant.
Non-goal 12: The composition MUST NOT authenticate an actor_ref.
Non-goal 13: A deployment needing an authenticated actor_ref MUST compose an authenticating pattern.
Non-goal 14: An authenticating pattern MUST supply the actor_ref the composition checks.
Non-goal 15: The composition MUST NOT partition the Personal Todo instance's description uniqueness per actor.
```

WHY:
Non-goal 4 and Non-goal 12 are the two constituent obligations this composition declines, and declining them is a decision rather than an oversight. [Assignment](../atoms/assignment.md)'s `Composition note 4` assigns *whether a completed task's assignment is recalled* to a composing pattern, and both answers are defensible — an Active assignment on a Done task is a completion-attribution record, and recalling it is a clean close — so the composition supports either and the deployment picks. [Permissions](../atoms/permissions.md)'s `Composition note 3` assigns the caller-to-subject binding, and this composition passes actor_ref through unauthenticated: an unauthenticated deployment lets any caller act under any actor's grants, which Non-goal 13 names the cure for. Both are pushed down one layer with the receiver named, which is the most a composition can do with an assignment it does not want.

Non-goal 11 is narrower than it reads. The composition gates every action on the Permissions instance and wires no action for `grant` or `revoke` — who may administer grants is a governance surface of its own, and a regulated deployment composes [Attributed Permissions Admin](./attributed-permissions-admin.md) over the same instance.

Non-goal 14 is the single shared instance's bill. One Personal Todo instance means its active-set description uniqueness holds globally, so two actors cannot hold pending tasks with normalized-equal descriptions and `duplicate-active` tells a caller that *someone's* matching task exists — a mild existence oracle for an actor holding `tasks:add` and not `tasks:view`. A deployment for which that is unacceptable partitions instances.

---

## Edge cases

WHY:
**Partial delete — the recall committed and the delete failed.** Wiring decision 1 commits the recall first, so a `storage-failure` or a concurrent-delete `not-known` at the delete leaves the assignment Recalled while the task stands. That is an over-recall and never a dangling assignment: Invariant 3 is one-way, Assignment admits a Recalled assignment on a live task, and [Responsible Actor] reports `unassigned`. The remedy is operational — retry the delete, or re-assign if the deletion is abandoned. No transaction wraps the two writes (Wiring decision 2); the ordering is what buys the safe side.

**Assignment on a Done task.** Action wiring 15 admits it deliberately. An Active assignment on a Done task is the completion-attribution pattern Non-goal 4 leaves to the deployment, and refusing it would decide that question by construction.

**A revoked grant mid-call.** Concurrency 4 checks at the call's start and Concurrency 5 does not re-check. A grant revoked during an in-flight action does not reach that action.

### Concurrency

```
Concurrency 1: The composition MUST rest on the host's serialization for two calls naming one task_id.
Concurrency 2: The composition MUST answer Assignment's already-assigned to the loser of two assigns.
Concurrency 3: The composition MUST answer Personal Todo's not-known to the loser of two deletes.
Concurrency 4: The composition MUST check permitted at a call's start.
Concurrency 5: The composition MUST NOT recheck permitted inside a call.
```

WHY:
Concurrency 4 and Concurrency 5 are the revoked-grant window stated rather than closed. A grant revoked while an action is in flight does not reach that action; the composition's guarantee is point-in-time at the check, and a deployment needing tighter coupling re-checks at its own layer.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A deployment MUST bind an actor_ref to an authenticated caller.
Composition note 3: A deployment MUST own whether a completed task's assignment is recalled.
Composition note 4: A deployment MUST administer the Permissions instance's grants.
Composition note 5: A deployment MUST NOT wire a second Assignment instance over the task list.
```

WHY:
Composition note 2 and Composition note 3 are the two constituent assignments this composition passes down, restated as obligations on the receiver so they do not fall between the layers. Composition note 5 is Invariant 2.1's precondition: Assignment's at-most-one-active guarantee is per instance, so two instances over one task list satisfy the atom and break the composition's claim.

---

## Terms

The canonical concepts this spec refers to. Each `[Term]` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind** — one of five: **Type** (a thing or category), **Operation** (a behavior), **Member** (a value of an enumerated Type), or, for a named datum, **Field** (a datum a Type carries — *what does it carry?*) or **Parameter** (a value an Operation needs — *what does it need?*). A term entry also names the Type it is a **Member of** / **Field of**, the Operation it is a **Parameter of**, and its **Role** where the domain assigns one. A term entry carries one **Projection** line — the concept's single canonical lowering token, the one place the concrete name stays visible on the page — for every Field, Parameter, and pinned/wire Member. Everything else about casing (each target's snake / camel / pascal / const / wire form) is **derived** from that one token by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs), never hand-written. This is a composition, so its own concepts are the composed action-wirings and derived queries plus the scope vocabulary it defines; references to the constituent atoms ([Personal Todo](../atoms/personal-todo.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md)) and their operations remain qualified calls to those atoms. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term terms: composition, constituents, responsible actor, visible tasks, action scopes, admitted add, admitted edit, admitted complete, admitted delete, admitted assign, admitted reassign, admitted recall, task_id, actor_ref.

Term record verbs: call, answer, gate, define, derive, store, materialize, recall, delete, assign, reassign, add, edit, complete, read, write, check, recheck, rest, leave, wrap, accept, refuse, carry, stand, follow, reach, find, name, own, discharge, inherit, change, replace, serve, compose, declare, bind, administer, wire, scope, grant, offer, record, authenticate, partition, outlive, supply.

Term actors: the composition; the constituents; a deployment; an auditor; an actor; an assignee; a task; an assignment; a grant; a caller.

Term cited: `execution-contract.md` §Conformance — recursive conformance and the inherited guarantee. `execution-contract.md` §Composition state — the no-stored-state classification. [Permissions](../atoms/permissions.md) `Composition note 2` — the scope vocabulary. [Permissions](../atoms/permissions.md) `Composition note 3` — the caller-to-subject binding, declined. [Assignment](../atoms/assignment.md) `Composition note 2` — what a task is. [Assignment](../atoms/assignment.md) `Composition note 4` — the completed task's assignment, declined.

#### Add Task

The composition action that adds a task to the shared list — gates on [Tasks Add] via Permissions, then delegates to Personal Todo's `add`. Returns the new task_id, or [Permission Denied] before any delegated Personal Todo rejection.

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

The composition action that binds responsibility for a task to an actor — gates on [Tasks Assign], checks the task exists (Pending or Done; else `not-known` — the referential-integrity check Assignment delegates to its composing system), then delegates to Assignment's `assign`. Returns the new `assignment_id`, or [Permission Denied] / `not-known` / a delegated rejection.

Kind: Operation

#### Reassign Task

The composition action that moves responsibility to a new actor — gates on [Tasks Assign], then delegates to Assignment's `reassign`. Returns the new `assignment_id`, or [Permission Denied] / a delegated rejection.

Kind: Operation

#### Recall Assignment

The composition action that withdraws responsibility — gates on [Tasks Recall], then delegates to Assignment's `recall`. Rejected [Permission Denied] or a delegated rejection.

Kind: Operation

#### Responsible Actor

The derived read query joining Personal Todo and Assignment — gates on [Tasks View], then returns the actor holding the active assignment for a task, `unassigned` for an existing task with none, or `not-known` for a task the store never held (the join's existence side). Neither constituent answers it alone.

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

`grounded on Final Critique 6 — 2026-08-26` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 6 — 2026-08-26
formal: verified — shared-todo.tla + 1 twin, 2026-06-03
last gate: 2026-08-26 — Final Critique 6, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/shared-todo.md`.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except three invariants the Execution Contract already owns.** *Chose:* `Composes` for the three constituents and the two assignments taken up, then `Composition state`, `Scope vocabulary`, `Action wiring`, `Wiring decision` and `Concurrency` as the wiring surfaces, the five surviving invariant numbers unchanged, and an acceptance section distributed from the closing claim the prose already made — *what the actor was allowed to do and who held the task is readable from the records alone*. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. `Wiring decision` reaches two specs with this one, which is the family [Undo History](./undo-history.md) minted and the first sign it recurs.
- **2026-09-14 — Three invariants asserting a constituent's invariants hold are one citation.** *Chose:* `Composes 6` — *the composition MUST inherit a constituent's invariants PER `execution-contract.md` §Conformance* — with `Invariant 6`, `Invariant 7` and `Invariant 8` tombstoned to it. *Over:* keeping the three, which is what the prose carried. *Because:* the contract already settles it — *conformance extends recursively, and no composing layer is obligated to re-verify what the substrate's own conformance already establishes; inheriting a guarantee by reference is the point of naming a substrate* — so three invariants re-asserting it were a citing spec restating a rule it cites (Authority 6), which is council read 53's ruling applied to a second seam. What the three carried *beyond* the blanket survives and is not inherited: the relay of an unchanged constituent rejection is `Composes 9`, and the single-instance decisions that make the constituents' guarantees reachable at all are `Composes 1` through `Composes 3` — which is why `Invariant 2.1` stands where `Invariant 7` fell (council read 55).
- **2026-09-14 — Two constituent assignments are declined, and the declining is written down.** *Chose:* `Non-goal 4` and `Non-goal 12` to state the refusals, with `Composition note 2` and `Composition note 3` restating them as obligations on the deployment. *Over:* silence, which is what a composition usually offers for a note it does not take. *Because:* [Assignment](../atoms/assignment.md)'s `Composition note 4` and [Permissions](../atoms/permissions.md)'s `Composition note 3` both say *a composing pattern MUST own* — so a composition that neither owns nor names a receiver leaves an obligation falling between two layers with no rule anywhere naming who holds it. Passing an assignment down with the receiver named is the most a composition can do with one it does not want, and the corpus has no form for it (council read 55).

NOTE: End of Shared Todo.
