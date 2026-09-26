---
title: Execute Gated Workflow
parent: Conceptual Compositions
nav_order: 10
has_toc: true
toc: true
---

# Execute Gated Workflow

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>


## Summary

Execute Gated Workflow freezes a declared process map (states, allowed transitions, and which transitions require human approval) and enforces permissions on who may start or advance it.

A guarded transition is gated by an Approval Step that an authorized actor opens on demand and assigns to the named approver's in-tray — the work list a person sees; the transition cannot fire until that step is Approved.

The Audit Trail substrate — the shared regulated-audit layer every act is recorded on — attributes every transition and gate decision to the acting actor's identity, governs retention, and seals the record tamper-evident — a records-alone forensic proof.

Together these produce what no constituent provides alone: the process followed only its declared path, every gate was cleared by a real human decision (not a bare assertion), and the full history is attributed, sealed, and reconstructible.

This composition is the structural form of FDA (US Food and Drug Administration) 21 CFR (Code of Federal Regulations) Part 11 electronic records workflows, SOX (Sarbanes-Oxley Act — US law on corporate financial reporting and records integrity) section 404 process-control records, ISO (International Organization for Standardization) 9001 clause 8.5.1 production-process documentation, and any regulated domain that must prove compliant execution from records alone.

---

## Intent

Multi-step regulated processes share a common structure: an entity moves through a declared sequence of states, some transitions require explicit human approval before they may fire, every transition must be attributed and tamper-evidenced, and the entire history must be reconstructible from the records alone. A pharmaceutical batch-release process requires declared quality-control steps with a qualified-person approval gate before release. A financial journal-entry promotion requires controller sign-off at the booking gate. A clinical-trial protocol change requires investigator and sponsor approvals before the change may proceed. A software change request requires a review approval before it can be merged to production. In every case the structure is the same: a declared state machine governing the process instance, a set of gates (transitions that may not fire until a named approver has actually decided), an authorization surface governing who may advance the process at all, a work-tracking surface that keeps each pending gate in the right person's in-tray, and a regulated-audit substrate that makes every advancement and every gate decision attributed, sealed, and retention-governed.

The constituent atoms address each of these concepts freestanding. [State Machine](../atoms/state-machine.md) enforces declared-transition discipline — only declared transitions fire, exactly one current state at all times, the full transition history is append-only, total-ordered, and replay-deterministic. [Approval Step](../atoms/approval-step.md) is the per-gate primitive — one named approver, one subject, one scope, one outcome (Pending → Approved | Rejected | Withdrawn), with approver exclusivity enforced by its Invariant 4. [Permissions](../atoms/permissions.md) governs standing authorization — who holds the `workflows:start`, `workflows:open-gate`, `workflows:fire`, and `workflows:read` grants that permit process-level actions. [Assignment](../atoms/assignment.md) binds each open gate to the named approver's in-tray and recalls the binding when the gate is decided. [Audit Trail](./audit-trail.md) is the regulated-audit substrate that supplies Event Log, Actor Identity, Retention Window, and Tamper Evidence as a single composition.

What the constituent atoms cannot answer alone is the central regulated question: *did this guarded transition fire only after its named approval was genuinely recorded?* State Machine's guard model (State Machine Invariant 8 — guard gating without evaluation) deliberately does not evaluate guard predicates; it trusts a caller-asserted `guard_satisfied = true` and records the assertion. Its Edge cases name this as a calling-system obligation and explicitly flag approval-gate evaluation as the concept this composition re-converges. This composition is where that re-convergence happens: it binds each guarded transition to an Approval Step (`gate_binding`), reads the bound step's state before any `fire` call, and asserts `guard_satisfied = true` to `WorkflowStateMachine.fire` only when the bound step is in Approved. The caller of this composition never supplies `guard_satisfied` directly for a guarded transition; the composition derives it from the gate's actual approval record.

This is not a new primitive. The four constituent atoms and the Audit Trail substrate are unchanged. The composition is the wiring that makes their concepts coherent — one consolidated multi-actor regulated-workflow surface rather than five parallel record stores the auditor must correlate by hand.

The composition addresses what State Machine's EOS (Essence of Software — Daniel Jackson's framework for specifying software concepts as freestanding, composable units) extraction correctly deferred — guard evaluation, non-repudiable attribution, retention governance, and Permissions gating — and adds the in-tray binding for pending approvals, a need the gate mechanism itself creates rather than one the atom deferred. The composition resolves those obligations without re-deriving the underlying primitives.

---

## Composes

- **[State Machine](../atoms/state-machine.md)** — the orchestrating spine: one State Machine workflow per run, only declared transitions firing, one current state, an append-only, totally ordered, replay-deterministic history.
- **[Approval Step](../atoms/approval-step.md)** — the per-gate primitive: one step per opened gate, its named approver alone deciding it and its submitter alone withdrawing it.
- **[Permissions](../atoms/permissions.md)** — standing authorization for the workflow-level actions and the read.
- **[Assignment](../atoms/assignment.md)** — the in-tray binding: one responsibility record per open gate, naming its approver, recalled when the gate is decided or mooted.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate: every intent, outcome, moot record and recovery record is an attributed, sealed, retention-governed Audit Trail event.

```
Composes 1: EXACTLY ONE State Machine instance MUST serve the composition.
Composes 2: EXACTLY ONE Approval Step instance MUST serve the composition.
Composes 3: EXACTLY ONE Permissions instance MUST serve the composition.
Composes 4: EXACTLY ONE Assignment instance MUST serve the composition.
Composes 5: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 6: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 7: The composition MUST NOT change a constituent's spec.
Composes 8: The composition MUST reach a transitive atom ONLY through Audit Trail.
Composes 9: The composition MUST NOT compose an instance of a transitive atom.
Composes 10: The composition MUST select audit events through the log read.
Composes 11: The composition MUST read an event by id ONLY through the record read.
Composes 12: A deployment MUST NOT call a machine write outside the composition.
Composes 13: A deployment MUST NOT call a step write outside the composition.
Composes 14: A deployment MUST NOT call an assignment write outside the composition.
Composes 15: A deployment MUST NOT record an event under the workflow namespace outside the composition.
Composes 16: The composition MUST NOT write the Permissions instance.
Composes 17: EXACTLY ONE State Machine workflow MUST serve a workflow run.
```

Term composition: this pattern's wiring of [State Machine](../atoms/state-machine.md), [Approval Step](../atoms/approval-step.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md) and [Audit Trail](./audit-trail.md) — the gated workflow, the gate, the moot cascade, the read and the restart sweep.

Term constituents: [State Machine](../atoms/state-machine.md), [Approval Step](../atoms/approval-step.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md), [Audit Trail](./audit-trail.md).

Term transitive atoms: [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md), [Tamper Evidence](../atoms/tamper-evidence.md) and [Retention Window](../atoms/retention-window.md), reached through Audit Trail.

Term workflow machine: the State Machine workflow serving one workflow run — `WorkflowStateMachine` in an implementation.

Term log read: Event Log's read by sequence-number range, from one with an open upper bound, passed through Audit Trail unchanged, with every selection by action reference and payload field made in the composition's own code.

Term record read: Audit Trail's read_record on an event id.

Term audit write: Audit Trail's record_action.

Term verification: Audit Trail's verify_record on an event id and a presentation.

Term machine write: State Machine's instantiate or fire.

Term step write: Approval Step's submit, approve, reject or withdraw.

Term assignment write: Assignment's assign or recall.

Term workflow namespace: the action references workflow_start_intended, workflow_started, gate_open_intended, gate_opened, gate_decision_intended, gate_decided, transition_intended, transition_fired, moot_gate_recalled and workflow_recovery_intended on the composition's Audit Trail instance.

WHY:
**What no constituent answers alone** is the regulated question — *did this guarded transition fire only after its named approval was genuinely recorded?* State Machine's guard model records a caller-asserted guard and deliberately evaluates nothing: its own edge cases name approval-gate evaluation as a concept this composition re-converges. So this composition binds each guarded transition to an Approval Step, reads that step before any fire, and asserts the guard only on an Approved step; the caller never supplies it (Wiring decision 1). **Approval Step** is one gate; **Permissions** says who may start, open, fire and read; **Assignment** keeps an open gate in its approver's in-tray — the work list a person sees — and knows nothing of gates; **Audit Trail** attributes, seals and retains every act, with Event Log, Actor Identity, Tamper Evidence and Retention Window reached through it and never instanced here (Composes 8 and 9; the section titled Compositions of compositions in `spec-format.md`).

**Every write surface is reserved** (Composes 12 through 16; 2026-08-26-h, 2026-08-30-b). The prose declared single-write-path exclusivity for State Machine alone, while its restart sweep read the Approval Step and Assignment instances as this composition's: an out-of-band approve would clear a gate with no decision event, and an out-of-band submit would look like an unrecorded opening. Reserving the machine, step and assignment writes and the namespace makes each a deployment's conformance failure, which the sweep reports rather than re-audits (Reconciliation 17 and 22). **Permissions is read-only here** (Composes 16): grants are administered by a Permissions-administration layer — [Attributed Permissions Admin](./attributed-permissions-admin.md) — and this composition only asks.

**The declared reads** (Composes 10 and 11). The rebuilds, the plan derivation, the read's set-valued queries, the sweep and the checks select by action reference and payload field, and the substrate serves no such read: Audit Trail passes a sequence-range read through to Event Log and routes every query by payload field to a Reverse Index pattern *(forthcoming)*. So the route is the pass-through range read with the selection in composition code, and the wired instance must expose it (Capability requirement 21). From the constituents the composition consumes Approval Step's read — the singleton step query, the Pending-state query and the unfiltered read the atom declares returns every step — and Assignment's active_for and history_for.

Adjacent, **not** constituents: [Multi-Party Approval](./multi-party-approval.md), the composing enrichment for a gate that needs several approvers (Non-goal 1); [Compensable Workflow](./compensable-workflow.md), for a process whose steps have effects to undo; [Legal Hold](../atoms/legal-hold.md), which suspends purge over the workflow's events through the substrate.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the workflow store, the gate binding index, the gate-assignment index AND the transition-event index.
Composition state 2: A workflow record MUST carry the instance id, the subject reference, the initiator reference, the declaration reference, the [Gate Spec] AND the started instant.
Composition state 3: The composition MUST NOT change a workflow record.
Composition state 4: The composition MUST key the gate binding index by gate key.
Composition state 5: A gate binding MUST carry the bound step, the consumed mark AND the mooted mark.
Composition state 6: The composition MUST NOT remove a gate binding.
Composition state 7: A start event MUST carry the whole workflow record.
Composition state 8: An opening event MUST carry the gate key, the step id, the assignment id, the approver reference, the scope AND the submitted instant.
Composition state 9: The composition MUST NOT rebuild an index from an intent.
Composition state 10: The composition MUST classify a live index entry as a derived index.
Composition state 11: The composition MUST rebuild the workflow store PER the workflow rebuild.
Composition state 12: The composition MUST rebuild the gate binding index PER the binding rebuild.
Composition state 13: The composition MUST rebuild the gate-assignment index from Approval Step's unfiltered read AND each step's assignment history.
Composition state 14: The composition MUST rebuild the transition-event index PER the firing rebuild.
Composition state 15: A rebuild MUST retain EVERY index entry the rebuild does not reproduce.
Composition state 16: The composition MUST classify a purged mark as truth-bearing.
Composition state 17: The composition MUST classify the marks as extraction-pending against Binding Registry.
Composition state 18: The deployment MUST persist the marks PER the mark durability.
Composition state 19: The composition MUST NOT store a clock-derived flag.
Composition state 20: The composition MUST NOT duplicate a constituent's store.
```

Term workflow store: the set of workflow records — `workflow_store` in an implementation.

Term workflow record: one workflow run's record.

Term instance id: the id State Machine's instantiate mints for the run — instance_id.

Term declaration reference: the caller's optional opaque name for the process definition — declaration_ref, typically a Definition Registry key, stored and recorded verbatim and never dereferenced.

Term gate key: an instance id, a from-state and an action — the key State Machine's transition uniqueness implies, since one action name may leave two states under two different guards.

Term gate binding index: the map from a gate key to the gate currently bound to it — `gate_binding` in an implementation.

Term gate binding: one gate key's entry.

Term bound step: the Approval Step a gate binding currently names.

Term consumed mark: the transition id of the one guarded firing a bound step authorized, set on the gate binding.

Term mooted mark: the transition id of the firing that mooted a bound step, set on the gate binding.

Term marks: the consumed mark and the mooted mark.

Term gate-assignment index: the map from a step id to its in-tray assignment id — `gate_to_assignment` in an implementation.

Term transition-event index: the map from a transition id to the event id of its firing event — `transition_to_event` in an implementation.

Term live index entry: a workflow record, gate binding or transition-event entry whose source event the record read answers Retained, or any gate-assignment entry.

Term purged mark: a mark whose source event — the firing event or the moot record — the record read answers Purged.

Term workflow rebuild: the log read kept to the start events, each recorded as its payload's workflow record — the initiator from the payload, never from the event's actor, since a recovery re-emission is the service identity's.

Term binding rebuild: the log read kept to the opening events, the latest per gate key in Event Log order naming the bound step; the consumed marks from the firing events' step ids, and the mooted marks from the moot records'.

Term firing rebuild: the log read kept to the firing events, each event id recorded against its payload's transition id.

Term unfiltered read: Approval Step's read on an empty query — every step in the store, which Approval Step never removes.

Term assignment history: Assignment's history_for on a step id as the task.

Term active assignment read: Assignment's active_for on a step id as the task.

Term clock-derived flag: a stored eligible, expired or overdue value.

WHY:
**Four derived indexes over two kinds of source** (Composition state 1 through 14; the section titled Composition state in `execution-contract.md`). Three rebuild from this composition's own outcome events, which carry what the indexes need: the start event the whole workflow record, the [Gate Spec] included — a composition-introduced surface no constituent holds, which is exactly why it rides the event; the opening event the gate key, so the binding rebuild is key-exact; the firing event the transition id. The fourth rebuilds from the constituent stores alone — every step through the unfiltered read, and each step's one assignment through its history, since each gate's task is its own fresh step id — so it is total at every age and the opening events only cross-check it. **No index rebuilds from an intent** (Composition state 9): an intent carries only what existed before its act, and sourcing a map from one would resolve ids for invocations that committed nothing. Each index sits outside its action's atomicity surface, a lost entry is a rebuild trigger, and none claims cross-constituent consistency. **The binding history is append-only** (Composition state 6): a re-bind appends an opening event and repoints the map, and a mooted or spent binding stays, so the traversal the checks walk is never severed.

**The horizon splits the classification, and the marks are the truth-bearing half** (Composition state 15 through 18; the section titled *A derived index splits at the horizon* in `pressure-testing.md`). A lawful purge destroys a payload whole. The workflow record, the binding and the transition-event entry are then not rebuildable, and the rebuild retains what it can no longer reproduce rather than dropping it. Their loss is kept benign by the ordering obligation — the horizon outlasts every workflow the deployment admits (Capability requirement 3) — so while a run is live its payloads are readable. **The marks are different**: once a firing event or moot record purges, the mark is the only record that a bound step's approval was spent, and nothing rebuilds it. The prose named no owner for that half (2026-08-30-d). Each mark pairs a step id to the transition id that spent it, once, durably — the write-once pairing a Binding Registry *(forthcoming)* is named for — so the marks are extraction-pending against it, and until it lands the durability is the deployment's. A mark lost past the horizon is read fail-closed (Wiring decision 6).

**No stored validity** (Composition state 19): the gate is state-valued — whether the bound step is Approved and unspent — so nothing at this layer consults or caches the clock. State Machine owns the current state and the history; Approval Step, Assignment and Permissions own their records (Composition state 20).

### Capability requirement

```
Capability requirement 1: A deployment MUST set the audit retention policy on the Audit Trail instance.
Capability requirement 2: The composition MUST NOT pass a retention input to the audit write.
Capability requirement 3: The longest workflow lifetime MUST NOT EXCEED the audit horizon.
Capability requirement 4: A deployment MUST set the completion bound.
Capability requirement 5: A deployment MUST set the compensation window.
Capability requirement 6: A deployment MUST set the reconciliation cadence.
Capability requirement 7: A deployment MUST disclose the record write latency.
Capability requirement 8: The composition MUST start ONLY IF the compensation window EXCEEDS the liveness sum.
Capability requirement 9: A deployment MUST provision the service identity.
Capability requirement 10: The host MUST supply the instance exclusion keyed by instance id.
Capability requirement 11: The host MUST release the instance exclusion on the holder's return.
Capability requirement 12: The host MUST release the instance exclusion on the holder's death.
Capability requirement 13: IF the host holds the instance exclusion as a lease THEN the host MUST set the lease length to the completion bound.
Capability requirement 14: The composition MUST read a lease's expiry as the holder's terminus.
Capability requirement 15: IF the host supplies no instance exclusion THEN the composition MUST NOT run a state-changing action.
Capability requirement 16: A deployment MUST set the clock offset allowance.
Capability requirement 17: A deployment MUST declare the mark durability.
Capability requirement 18: A deployment MUST set the intent candidates cap.
Capability requirement 19: A deployment MUST declare the id widths.
Capability requirement 20: The host MUST inject now at the seam once per invocation.
Capability requirement 21: The wired Audit Trail instance MUST expose the log read.
Capability requirement 22: The composition MUST pass the invocation's now to EVERY constituent call accepting an instant.
Capability requirement 23: A deployment parsing a gate subject MUST encode the subject reference injectively.
```

Term audit retention policy: the retention policy configured on the composition's single Audit Trail instance — `audit_trail_retention_policy`: a seven-year SOX policy, a Part 11 predicate-rule policy, a HIPAA six-year policy, an ICH E6 trial-master-file policy.

Term audit horizon: the audit retention policy's horizon.

Term longest workflow lifetime: the longest a workflow run the deployment admits stays live — a business fact, for a trial master file or a change-control record its own expected duration.

Term completion bound: the longest a state-changing invocation may hold the instance exclusion, from its intent to its outcome and, for a firing, its moot cascade — `workflow_completion_bound`: the sweep's lower edge, the lease length and the invocation's terminus.

Term compensation window: the duration within which an owed record or cascade must land or be escalated — `compensation_window`.

Term reconciliation cadence: the interval between the sweep's runs, beside the run at every restart — `reconciliation_cadence`.

Term record write latency: the deployment's disclosed bound on one audit write landing — `record_write_latency`.

Term liveness sum: `completion bound + reconciliation cadence + record write latency`.

Term service identity: the composition's registered actor reference and credential — `application_actor_ref` and `application_credential` — under which the composition attests every write no present human's invocation owns.

Term instance exclusion: the host-supplied mutual exclusion on an instance id, taken before an invocation's intent and held through its outcome and cascade, and taken by the sweep for every instance it touches — `instance_serialization`.

Term holder: an invocation or a sweep run holding the instance exclusion.

Term clock offset allowance: the declared bound on the divergence between the composition's seam clock and the substrate's — `clock_offset_allowance`.

Term mark durability: the deployment's declaration that the store carrying the marks retains them for as long as any binding on the key could still be fired or re-bound — `binding_flag_durability`.

Term intent candidates cap: the most intent candidates a recovery re-emission may name — `intent_candidates_cap`.

Term id widths: the widest instance id, step id, assignment id, transition id and event id the constituents mint — the substrate's own attestation id width move, so an id-carrying payload is sized before any id exists.

Term seam: the composition's input and output boundary — the one place the host reads the clock, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam, once per invocation.

Term gate subject: the workflow's subject reference, a colon and the action — the step's subject, never parsed back by the composition.

WHY:
**The horizon outlasts every workflow, as an obligation** (Capability requirement 1 through 3; 2026-08-30-c). The audit write takes no per-call retention input, so every event inherits the instance's policy. The workflow store, the binding index and the moot plan's derivation read payloads, and past the horizon the [Gate Spec] — held by no constituent — leaves the rebuild, and the plan's derivation degrades to whatever the binding index still holds, which is the silent under-reporting the event-anchored derivation exists to prevent. Check 8.1 tests it where both durations are readable; where the lifetime is a business fact the records cannot see it is External check 2.

**Liveness is arithmetic, and the bound is the invocation's terminus** (Capability requirement 4 through 8 and 10 through 15; the sections titled *Liveness is arithmetic* and *A compensator is exclusive* in `pressure-testing.md`). An owed record created at *t* is invisible to the sweep until `t + bound`, the next run is at most a cadence later, and the record lands a latency after that; *a cadence no longer than the window* is satisfied by a deployment that breaches on every orphan. The bound is also where the one writer changes: an invocation holds the exclusion from before its intent to after its cascade, re-attempts an owed write only inside the bound, and past it has yielded — whether or not its process is alive; the sweep takes the same exclusion and re-reads its pre-check under it. An invocation that lost its lease re-takes it before any pre-check and writes nothing it cannot hold it for, so it never resumes between the sweep's look and the sweep's write. No constituent declares a section spanning calls to four of them, so it is named here as the host's (the section titled *Capability provenance* in `pressure-testing.md`).

**The service identity** (Capability requirement 9) attests exactly two kinds of write: the moot record, which the cascade emits with no human deciding it; and every recovery re-emission — an owed record landed outside its invocation, or one whose human's credential was refused mid-flight — which names the human in its payload (2026-08-27-e). Every other workflow event carries the human caller. A forged moot record claiming a gate was mooted by a firing the machine history shows never left its state is refuted by cross-reading the history.

**One reading, passed through** (Capability requirement 16, 20 and 22; Execution Contract Logic confinement 7). Where a constituent accepts an instant — instantiate, fire, submit, approve, reject, withdraw — the composition passes the invocation's reading rather than letting the constituent take a second one, so the machine's history, the step and the event payload name one instant, and the sweep can pair by equality. Where the composition's reading is judged against the substrate's horizon, the two clocks differ, and the comparison is widened by the allowance toward examining rather than excusing (Wiring decision 5; the section titled *A stamp from another seam never decides a write alone* in `pressure-testing.md`).

**The caps size the largest record** (Capability requirement 18 and 19; the section titled *An outcome is sized before the intent* in `pressure-testing.md`): the start event embedding the whole [Gate Spec], the fire intent carrying a full moot plan, and every recovery re-emission — an outcome's payload plus the human, the recovery flag and up to the candidates cap. **The gate subject is never parsed back** (Capability requirement 23): the step-to-transition truth is the binding and its opening event, not the string, so no delimiter escaping is owed here; a deployment that parses gate subjects in its own tooling picks an injective encoding.

### Primitive policy

```
Primitive policy 1: IF a caller reference EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 2: IF the credential IS NOT IN the parseable credentials THEN the action MUST answer invalid-request.
Primitive policy 3: IF a supplied reason EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 4: IF the decision IS NOT IN the decisions THEN [Decide Gate] MUST answer invalid-request.
Primitive policy 5: IF the decision IS IN the reason-bearing decisions AND the reason EQUALS blank THEN [Decide Gate] MUST answer invalid-request.
Primitive policy 6: IF a guarded transition's guard label names no [Gate Spec] entry THEN [Start Workflow] MUST answer invalid-request.
Primitive policy 7: IF a [Gate Spec] entry names no guard label of the declaration THEN [Start Workflow] MUST answer invalid-request.
Primitive policy 8: IF an entry's approver reference OR scope EQUALS blank THEN [Start Workflow] MUST answer invalid-request.
Primitive policy 9: IF a capped field's length EXCEEDS the field's cap THEN the action MUST answer invalid-request.
Primitive policy 10: IF the guarded transition count EXCEEDS the guarded transition cap THEN [Start Workflow] MUST answer invalid-request.
Primitive policy 11: IF the instance id OR the action EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 12: An action refused under Primitive policy 1 through 11 MUST NOT write.
Primitive policy 13: The composition MUST NOT call a constituent BEFORE Primitive policy 1 through 11 pass.
Primitive policy 14: The composition MUST compare a reference, a guard label, an id AND a gate key byte-exact.
Primitive policy 15: The composition MUST NOT normalize a caller string.
Primitive policy 16: The composition MUST NOT inspect a credential.
```

Term caller reference: an actor reference, a subject reference, an approver reference or a submitter reference.

Term actor reference: the calling actor — actor_ref.

Term subject reference: the opaque reference to the entity whose lifecycle the workflow governs — subject_ref.

Term approver reference: the actor a [Gate Spec] entry names to decide its gate.

Term parseable credentials: the non-null values of the deployment's declared credential type.

Term credential: the caller's authentication material, consumed only by the audit write.

Term reason: the caller's free text — optional at [Start Workflow], [Open Gate] and [Fire Transition], optional for an approval and required for a rejection or a withdrawal.

Term decisions: approve | reject | withdraw.

Term reason-bearing decisions: reject | withdraw — Approval Step's mandatory-reason rule.

Term capped field: a guard label, an approver reference, a scope, a subject reference, a declaration reference or a reason — each bounded by a cap the deployment derives from its Audit Trail instance's payload budget and reference caps.

Term guarded transition count: how many transitions of the declaration carry a guard label — the count that bounds a moot plan, since several transitions may share one label.

Term guarded transition cap: the budget-derived bound on the guarded transition count.

Term action: the transition name a call addresses — a well-formed but undeclared action lands on invalid-transition, never invalid-request.

WHY:
**Validation runs before any constituent is called**, the permission check included (Primitive policy 12 and 13). **The [Gate Spec] covers the declaration exactly** (Primitive policy 6 through 8): a guarded transition with no named approver cannot be governed, and an entry for a label the declaration never uses names a gate that will never exist. **The caps foreclose the payload-size source of the audit write's invalid-request by construction** (Primitive policy 9 and 10): the largest record any act can write is bounded before the first id is minted — which is why this validation precedes the start intent, whose payload carries the whole [Gate Spec]. The guarded transition count, not the entry count, bounds the moot plan, because the plan carries one entry per bound gate and the binding index is keyed per transition. **Byte-exact throughout** (Primitive policy 14 through 16; 2026-08-26-j): every constituent declares byte-exact equality, and the guard label, the gate key and every reference compare as bytes here too.

### Audit arm

```
Audit arm 1: IF Audit Trail answers invalid-credential at an intent THEN the action MUST answer invalid-credential.
Audit arm 2: IF Audit Trail answers recording-failure at an intent THEN the action MUST answer recording-failure carrying pre-commit.
Audit arm 3: IF Audit Trail answers invalid-request at an intent THEN the action MUST answer invalid-request.
Audit arm 4: The composition MUST NOT retry an invalid-request answer.
Audit arm 5: The deployment MUST alert on EVERY invalid-request from the audit write as a deployment fault.
Audit arm 6: IF Audit Trail answers recording-failure carrying the retention step at an outcome THEN the invocation MUST read the outcome back.
Audit arm 7: IF Audit Trail answers invalid-request at an outcome THEN the invocation MUST read the outcome back.
Audit arm 8: A read-back MUST match the outcome carrying the act's minted id.
Audit arm 9: IF the read-back finds the outcome THEN the invocation MUST proceed as landed.
Audit arm 10: IF Audit Trail answers invalid-credential at an outcome THEN the invocation MUST record the outcome under the service identity carrying the recovery flag AND the human actor.
Audit arm 11: IF Audit Trail answers recording-failure carrying a pre-append step at an outcome THEN the action MUST answer recording-failure carrying post-commit.
Audit arm 12: A yielded invocation MUST NOT retry an outcome.
Audit arm 13: A caller MUST read recording-failure carrying pre-commit as a committed nothing.
Audit arm 14: A caller MUST NOT re-invoke an instance action on recording-failure carrying post-commit.
Audit arm 15: IF [Start Workflow] answers recording-failure carrying post-commit THEN the caller MAY re-invoke [Start Workflow].
```

Term intent: a start intent, an open intent, a decision intent or a fire intent — the audit write an action makes before its load-bearing call, the one that verifies the caller's credential.

Term outcome: a start event, an opening event, a decision event or a firing event — the audit write an action owes after its load-bearing call.

Term act's minted id: the instance id for a start event, the step id for an opening event, the step id with the decision for a decision event, the transition id for a firing event.

Term pre-append step: a recording-failure step naming a step before the substrate's append — step-2 or step-3; the event is not in the log.

Term retention step: the recording-failure step naming the substrate's retention placement — step-4; the event is appended and attested.

Term stage: pre-commit | post-commit — where a recording-failure sat relative to the action's load-bearing write: the instantiate, the submit, the decision or the fire.

Term yielded invocation: an invocation whose intent instant plus the completion bound PRECEDES now, or whose lease expired.

Term human actor: the caller whose act an outcome records, carried in a recovery re-emission's payload.

WHY:
**Mapped by stage and by step** (the section titled *A transcribed rejection arm keeps its payload and its reachability* in `pressure-testing.md`). Every intent is a pre-commit write by construction — it precedes the load-bearing call — so a refused intent means the act does not happen and nothing is owed; the re-emission rule never reaches one. At an outcome the act has committed: the retention step and the retention-source invalid-request arrive with the event appended — the prose treated both as transient, and a retry there appends a second outcome for one act — so the invocation reads back by the act's minted id and proceeds where the event is there (2026-08-26-d). The substrate's invalid-request has two sources and neither loops: its payload-size source is foreclosed by the caps; its retention-configuration source, which also carries reference-cap and policy faults the substrate routes there, is a pageable deployment fault. **invalid-credential at an outcome is landed by attribution** (Audit arm 10): a caller whose registration changed mid-flight cannot orphan a committed act's record, and an invalid-credential on the service identity's own emission is the deployment's credential, paged, never looped.

**The stage rides the exported code, and the caller's recourse splits by action class** (Audit arm 13 through 15; the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`; 2026-08-26-o). A mutation — a decision or a firing — must never be re-invoked on post-commit: a firing is not idempotent and would fire again, and the caller confirms the committed state through [Read Workflow]. [Open Gate]'s committed step and assignment are completed by the implementation, the gate held out of reach until its opening is audited — no binding exists, so [Decide Gate] answers gate-not-open and [Fire Transition] gate-not-cleared — and a re-invoke before the binding lands would pass the no-binding check and submit a second gate. [Start Workflow]'s orphan instance is referenced by nothing, so a re-invoke on post-commit mints fresh ids safely; the orphan is quarantined for store maintenance and is External check 1.

### Action wiring

```
start_workflow(actor_ref, declaration, subject_ref, gate_spec, credential, optional declaration_ref, optional reason)
  answers instance id
  refuses permission-denied | invalid-credential | invalid-declaration | invalid-request | recording-failure(stage)

open_gate(actor_ref, instance_id, action, credential)
  answers gate handle
  refuses permission-denied | invalid-credential | invalid-request | not-known | invalid-transition | not-guarded | gate-not-available | already-open(open state) | recording-failure(stage)

decide_gate(actor_ref, instance_id, action, decision, optional reason, credential)
  answers decision outcome
  refuses not-known | gate-not-open | not-pending | unauthorized | invalid-credential | invalid-request | recording-failure(stage)

fire_transition(actor_ref, instance_id, action, credential)
  answers new state
  refuses permission-denied | invalid-credential | invalid-request | not-known | terminal | invalid-transition | gate-not-cleared | recording-failure(stage)

read_workflow(actor_ref, query)
  answers workflow views
  refuses permission-denied | invalid-request | invalid-query
```

Term gate handle: the step id and the assignment id of an opened gate.

Term open state: pending | cleared-unconsumed — the bound step is Pending, or a live approval.

Term decision outcome: approved | rejected_outcome | withdrawn — Approval Step's success token for the decision.

Term new state: the state the firing moved the workflow to.

Term workflow views: the workflows a query matches, each carrying its workflow record, the machine's current state and history with each entry's firing event id, and each gate's step, marks and assignment records — and the horizon mark where a set-valued query's range reached purged start events.

Term query: a filter on instance id, subject reference, initiator reference, or a range on the started instant in the `{after, before}` form.

```
Action wiring 1: A validated start MUST call the permission check with the actor reference AND [Workflows Start].
Action wiring 2: IF the permission check answers denied THEN the action MUST answer permission-denied.
Action wiring 3: A permitted start MUST record the start intent carrying the subject reference, the declaration reference, the [Gate Spec] AND now as the intent instant.
Action wiring 4: An intent MUST NOT carry an id the intent's act mints.
Action wiring 5: An admitted start MUST call instantiate with the declaration, the actor reference, the subject reference and the guard labels as metadata, AND now as the instantiated instant.
Action wiring 6: IF instantiate answers invalid-declaration THEN [Start Workflow] MUST answer invalid-declaration.
Action wiring 7: IF a load-bearing call answers storage-failure THEN the action MUST answer recording-failure carrying pre-commit.
Action wiring 8: IF an instant-bearing call answers invalid-request THEN the action MUST answer recording-failure carrying pre-commit.
Action wiring 9: An instantiated start MUST record the start event carrying the intent event id, the whole workflow record AND the reason.
Action wiring 10: An unlanded start MUST leave the instance quarantined for store maintenance.
Action wiring 11: A landed start MUST write the workflow record.
Action wiring 12: A landed start MUST answer the instance id.
Action wiring 13: The composition MUST write an index entry ONLY AFTER the event the entry derives from lands.
Action wiring 14: A failed index write MUST NOT change an action's answer.
Action wiring 15: A validated opening MUST call the permission check with the actor reference AND [Workflows Open Gate].
Action wiring 16: An instance action MUST NOT answer not-known BEFORE rebuilding the instance's workflow record.
Action wiring 17: IF the workflow store carries no record for the instance id THEN the instance action MUST answer not-known.
Action wiring 18: A found action MUST take the instance exclusion on the instance id.
Action wiring 19: A found action MUST read the workflow machine's current state AND declaration.
Action wiring 20: IF a read-side call refuses THEN the action MUST answer recording-failure carrying the call's stage.
Action wiring 21: The deployment MUST alert on EVERY read-side refusal as an index anomaly.
Action wiring 22: IF the current state IS IN the declaration's terminal states THEN [Open Gate] MUST answer gate-not-available.
Action wiring 23: IF no declared transition leaves the current state under the action THEN the action MUST answer invalid-transition.
Action wiring 24: IF the matched transition carries no guard label THEN [Open Gate] MUST answer not-guarded.
Action wiring 25: IF the gate key's bound step EQUALS Pending THEN [Open Gate] MUST answer already-open carrying pending.
Action wiring 26: IF the gate key's bound step IS IN the live approvals THEN [Open Gate] MUST answer already-open carrying cleared-unconsumed.
Action wiring 27: A guarded opening MUST record the open intent carrying the gate key, the guard label, the approver reference, the scope AND now as the intent instant.
Action wiring 28: An admitted opening MUST call submit with the gate subject, the entry's approver reference, the workflow's initiator reference as the submitter, the entry's scope AND now as the submitted instant.
Action wiring 29: A submitted opening MUST call assign with the step id as the task AND the entry's approver reference as the assignee.
Action wiring 30: IF assign answers already-assigned THEN the opening MUST read the assignment id through the active assignment read.
Action wiring 31: IF assign answers storage-failure THEN the invocation MUST retry assign under the instance exclusion.
Action wiring 32: IF the completion bound elapses on an unassigned opening THEN [Open Gate] MUST answer recording-failure carrying post-commit.
Action wiring 33: A staffed opening MUST record the opening event carrying the intent event id, the gate key, the step id, the assignment id, the approver reference, the scope AND the submitted instant.
Action wiring 34: A landed opening MUST write the gate binding AND the gate-assignment entry.
Action wiring 35: A landed opening MUST answer the gate handle.
Action wiring 36: IF the gate binding index carries no binding for the current gate key THEN [Decide Gate] MUST answer gate-not-open.
Action wiring 37: A bound decision MUST record the decision intent carrying the gate key, the step id, the decision, the reason AND now as the intent instant.
Action wiring 38: An admitted decision MUST call the decision's step write with the step id, the actor reference as the decider, the reason AND now as the decided instant.
Action wiring 39: IF the step write answers not-pending OR unauthorized THEN [Decide Gate] MUST answer the step write's answer.
Action wiring 40: IF the step write answers not-known THEN [Decide Gate] MUST answer recording-failure carrying pre-commit.
Action wiring 41: A decided decision MUST call recall on the step's assignment id.
Action wiring 42: IF recall answers not-active THEN the decided decision MUST proceed.
Action wiring 43: IF recall answers storage-failure THEN the invocation MUST retry recall under the instance exclusion.
Action wiring 44: IF recall answers not-known THEN the decided decision MUST rebuild the gate-assignment index AND call recall once more.
Action wiring 45: IF recall answers not-known after the rebuild THEN the deployment MUST alert on the answer as a conformance fault.
Action wiring 46: A decided decision MUST record the decision event carrying the intent event id, the gate key, the step id, the decision, the reason AND the decided instant.
Action wiring 47: A landed decision MUST answer the decision outcome.
Action wiring 48: A validated firing MUST call the permission check with the actor reference AND [Workflows Fire].
Action wiring 49: IF the current state IS IN the declaration's terminal states THEN [Fire Transition] MUST answer terminal.
Action wiring 50: IF the matched transition carries a guard label AND the gate binding index carries no binding for the gate key THEN [Fire Transition] MUST answer gate-not-cleared.
Action wiring 51: IF the matched transition carries a guard label AND the gate key's bound step IS NOT IN the live approvals THEN [Fire Transition] MUST answer gate-not-cleared.
Action wiring 52: A cleared firing MUST derive the moot plan.
Action wiring 53: A cleared firing MUST record the fire intent carrying the gate key, the to-state, the guarded flag, the bound step id where guarded, the moot plan AND now as the intent instant.
Action wiring 54: A moot plan MUST NOT name the firing's own gate key.
Action wiring 55: An admitted firing MUST call fire with the instance id, the action, the actor reference AND now as the fired instant.
Action wiring 56: IF the matched transition carries a guard label THEN an admitted firing MUST pass the guard as satisfied.
Action wiring 57: IF fire answers not-known, terminal OR invalid-transition THEN [Fire Transition] MUST answer the fire's answer.
Action wiring 58: A fired firing MUST read the appended entry's transition id from the workflow machine's history.
Action wiring 59: A fired firing MUST record the firing event carrying the intent event id, the instance id, the action, the from-state, the new state, the transition id, the guarded flag, the bound step id where guarded AND the fired instant.
Action wiring 60: A landed firing MUST write the transition-event entry.
Action wiring 61: IF the landed firing is guarded THEN the landed firing MUST set the gate binding's consumed mark.
Action wiring 62: A fired firing MUST run the moot cascade.
Action wiring 63: A fired firing MUST NOT answer BEFORE the moot cascade's calls answer.
Action wiring 64: A landed firing MUST answer the new state.
Action wiring 65: A validated read MUST call the permission check with the actor reference AND [Workflows Read].
Action wiring 66: IF the query carries an unrecognized key THEN [Read Workflow] MUST answer invalid-query.
Action wiring 67: A permitted read MUST resolve an instance id query through the workflow store with a rebuild on a miss.
Action wiring 68: A permitted read MUST resolve a set-valued query from the start events.
Action wiring 69: A permitted read MUST enumerate a workflow's gates from the workflow's opening events.
Action wiring 70: IF a set-valued query's range reaches a purged start event THEN the workflow views MUST carry the horizon mark.
Action wiring 71: A permitted read MUST answer the workflow views.
Action wiring 72: [Read Workflow] MUST NOT record an audit event.
```

Term start intent: the workflow_start_intended event.

Term start event: the workflow_started event.

Term open intent: the gate_open_intended event.

Term opening event: the gate_opened event.

Term decision intent: the gate_decision_intended event.

Term decision event: the gate_decided event.

Term fire intent: the transition_intended event.

Term firing event: the transition_fired event.

Term intent event id: the event id of the intent an outcome pairs with — intent_event_id.

Term intent instant: the now an intent carries — intended_at.

Term started instant: the now a start stamps on its workflow record and passes to instantiate — started_at, equal to instantiated_at.

Term submitted instant: the now an opening passes to submit and its opening event carries — submitted_at.

Term decided instant: the now a decision passes to its step write and its decision event carries — decided_at, or withdrawn_at for a withdrawal.

Term fired instant: the now a firing passes to fire and its firing event carries — fired_at.

Term guarded flag: whether the fired transition carries a guard label.

Term matched transition: the declared transition leaving the current state under the action.

Term to-state: the matched transition's declared target state.

Term decision's step write: Approval Step's approve, reject or withdraw, by the decision — the decider passed as decided_by, or as withdrawn_by.

Term load-bearing call: instantiate, submit, the decision's step write, or fire.

Term instant-bearing call: a constituent call carrying the invocation's now.

Term read-side call: the workflow machine's current, read_declaration or history, Approval Step's read, or Assignment's active_for or history_for.

Term call's stage: pre-commit where the read precedes the action's load-bearing call, post-commit where it follows it.

Term instance action: [Open Gate], [Decide Gate] or [Fire Transition].

Term validated start: a [Start Workflow] call whose inputs cleared Primitive policy.

Term permitted start: a validated start whose permission check answered permitted.

Term admitted start: a permitted start whose start intent landed.

Term instantiated start: an admitted start whose instantiate answered an instance id.

Term landed start: an instantiated start whose start event landed or was read back.

Term unlanded start: an instantiated start whose start event neither landed nor was read back.

Term validated opening: an [Open Gate] call whose inputs cleared Primitive policy.

Term found action: an instance action whose permission check, where it carries one, answered permitted and whose instance id the workflow store resolves.

Term guarded opening: a found [Open Gate] whose matched transition carries a guard label and whose gate key's bound step is absent or IS IN the re-bindable steps.

Term admitted opening: a guarded opening whose open intent landed.

Term submitted opening: an admitted opening whose submit answered a step id.

Term unassigned opening: a submitted opening whose assign has not answered an assignment id.

Term staffed opening: a submitted opening whose assign answered, or whose assignment id was read back.

Term landed opening: a staffed opening whose opening event landed or was read back.

Term bound decision: a found [Decide Gate] whose current gate key carries a gate binding.

Term admitted decision: a bound decision whose decision intent landed.

Term decided decision: an admitted decision whose step write answered its decision outcome.

Term landed decision: a decided decision whose decision event landed or was read back.

Term validated firing: a [Fire Transition] call whose inputs cleared Primitive policy.

Term cleared firing: a found [Fire Transition] whose matched transition is unguarded, or whose gate key's bound step IS IN the live approvals.

Term admitted firing: a cleared firing whose fire intent landed.

Term fired firing: an admitted firing whose fire answered the new state.

Term landed firing: a fired firing whose firing event landed or was read back.

Term validated read: a [Read Workflow] call whose inputs cleared Primitive policy.

Term permitted read: a validated read whose permission check answered permitted and whose query conforms.

Term horizon mark: horizon_bounded set to true on the workflow views — a short answer past the horizon is never read as *no such workflow*.

WHY:
**Permission, intent, load-bearing call, outcome** — every state-changing action's shape, and the intent is where the credential is verified (Invariant 8). [Decide Gate] has no permission check, its authorization being Approval Step's approver and submitter exclusivity; its order is intent, decision, outcome. Every outcome carries its intent's event id for an exact join.

**[Start Workflow]** (Action wiring 1 through 12). The intent carries the [Gate Spec] and no instance id — none exists, and the start event is what the workflow rebuild traverses. The start event carries the whole workflow record, so the store rebuilds from the event alone; the record lands before the map, since a map entry ahead of its event would be a ghost the read serves and a rebuild drops. Gates open lazily, never at start.

**[Open Gate]** (Action wiring 15 through 35). Terminal is checked before the transition match, in the constituent's own refusal order, since a terminal state has no outgoing transition and the reversed order would make the arm dead. **The gate's submitter is the workflow's initiator, not the opener**: withdrawal authority over the gate — Approval Step's submitter-only rule — is the initiator's, which is what authorizes both a withdrawal through [Decide Gate] and the moot cascade; the opener is attributed on the opening event. A gate is re-bound over a Rejected, Withdrawn or spent step — the binding history appends, the map repoints — and never over a Pending step or a live approval, which is never silently discarded (Wiring decision 7). After the submit commits the implementation owns completion: an already-assigned on retry means the first attempt landed, the fresh step id guaranteeing no other assignment owns the task; and the gate stays out of reach until its opening is audited.

**[Decide Gate]** (Action wiring 36 through 47). The binding resolves through the current state: gates open only for transitions leaving it, and the cascade moots the rest. The decision intent is where the approver's reference is verified — before it, Approval Step's exclusivity compared two unverified strings, so the load-bearing claim *the named approver approved* rested on an assertion. Approval Step's not-known here is an index anomaly — the composition's own binding named a step the store does not know — never the caller's unknown instance. The recall is discharge bookkeeping and fails nothing: not-active means the cascade already discharged it, a failed recall is retried inside the bound and the sweep's after it.

**[Fire Transition]** (Action wiring 48 through 64) — the load-bearing wiring. The gate resolution is read-only and settled **before** the intent, so a gate-not-cleared — the ordinary answer to polling a Pending gate — leaves no intent behind. **The fire intent carries the moot plan** where the other intents carry no derived set: the cascade withdraws human approvals under the service identity in a burst the caller never sees, so naming the plan before the fire makes *what this firing was about to moot* a fact on the record whether or not the cascade completed; the plan never names the firing's own key, whose approval is spent, not left behind (Action wiring 54). fire returns only the new state, so the transition id is read from the history's newest entry, which under the instance exclusion is this firing's. **The cascade runs on the commit, not on the answer** (Action wiring 62 and 63): a cascade conditioned on the firing event landing would leave the mooted gates Pending with live assignments on exactly the post-commit path — a human approval surviving to clear a transition the workflow already left.

**[Read Workflow]** (Action wiring 65 through 72). An instance-id query is a keyed lookup with a rebuild on a miss. **A set-valued query is anchored in the start events, never an enumeration of the store**: an enumeration has no miss to observe, so a lost entry would drop a workflow from the answer silently, and Invariant 6 would rest on a read the index's contract does not cover. A permission denial is always the explicit refusal, never an empty answer, which would make *denied* and *nothing matches* indistinguishable; a deployment preferring deny-by-empty builds it above the composition. The view surfaces event ids and leaves the verification to the auditor.

**Every read-side refusal is landed** (Action wiring 20 and 21; 2026-08-26-b): the machine's reads, Approval Step's read and Assignment's reads answer not-known or invalid-request only when an index names what the store does not know — an anomaly for store maintenance, surfaced at the stage the read sat, never a caller's fault.

### Wiring decision

```
Wiring decision 1: [Fire Transition] MUST pass the guard as satisfied ONLY IF the gate key's bound step IS IN the live approvals.
Wiring decision 2: The composition MUST NOT accept a guard assertion from a caller.
Wiring decision 3: The composition MUST read a bound step as consumed PER the consumption rule.
Wiring decision 4: The composition MUST read a bound step as mooted PER the mooting rule.
Wiring decision 5: The consumption rule MUST NOT read an aged entry as an unrecorded firing.
Wiring decision 6: IF a gate binding carries no consumed mark AND a guarded firing out of the gate key IS IN the aged entries THEN the composition MUST read the bound step as consumed.
Wiring decision 7: The composition MUST re-bind a gate key ONLY IF the bound step IS IN the re-bindable steps.
Wiring decision 8: The composition MUST NOT evaluate a guard other than an approval guard.
```

Term live approvals: the bound steps in Approved that are neither consumed nor mooted.

Term consumption rule: a bound step is consumed where a firing event names it; or where the workflow machine's history holds a guarded firing out of its gate key, inside the widened horizon, that no firing event names — a committed firing whose record is still owed; or where its consumed mark is set.

Term mooting rule: a bound step is mooted where a moot record names it, where a committed firing's fire intent names it in its moot plan, or where its mooted mark is set.

Term widened horizon: the history entries whose fired instant plus the audit horizon plus the clock offset allowance DOES NOT PRECEDE now.

Term aged entries: the history entries whose fired instant plus the audit horizon plus the clock offset allowance PRECEDES now.

Term aged entry: a history entry in the aged entries.

Term re-bindable steps: the bound steps in Rejected or Withdrawn, and the bound steps in Approved that are consumed or mooted.

Term approval guard: a guard whose evaluation is whether a named approver approved a named subject under a named scope.

Term spent step: a bound step that is consumed or mooted.

WHY:
**An approval-gated transition: a guarded transition fires only when its bound step is a live approval, and the composition — never the caller — makes the assertion.**

*Principle.* A regulated workflow must prove from the records alone that the process moved only through declared transitions and that every guarded one fired only after its named approval was genuinely recorded — attributed, sealed and retained.

*Likely objection.* State Machine already accepts a caller-asserted guard. Why not let the caller assert it, or trust the caller's word?

*Mechanism.* State Machine deliberately left guard evaluation out: guards recur as approvals, thresholds, quorums and external conditions, each with its own lifecycle, and the atom absorbs none. For approval guards this composition is the evaluation layer: it binds each guarded transition to an Approval Step and, at the fire, reads the bound step's own state; the caller supplies no guard for a guarded transition (Wiring decision 1 and 2). Guards of any other kind stay the caller's or a composing rules engine's (Wiring decision 8).

*Result.* The process moved only through declared transitions; each guarded transition cleared its named approval by the named approver; every firing and decision is attributed, sealed and retained. No transition fires on a bare assertion.

**One approval, one firing** (Wiring decision 3 through 7). An approval is a decision about the workflow in the state its gate was opened from, and it authorizes exactly one firing out of that key. **Consumption reads durable stores, never process memory**: the history arm catches a firing whose record is still owed, so a crash between the fire and its record can never leave the approval reading unspent and fire twice. **The history arm stops at the horizon** (Wiring decision 5): past it a firing event's payload — its transition id — is destroyed, and an unbounded arm would read every purged firing as unrecorded and every later binding on the key, a return path's fresh gate included, as consumed forever. The horizon runs on the substrate's clock and the fired instant on this one's, so the arm is widened by the allowance toward reading *consumed*. Past it the marks answer, and a mark lost there reads fail-closed (Wiring decision 6): the transition does not fire on an approval that may already have been spent, and a re-entry opens a fresh gate — an approval that was in fact unspent then stands unused, the horizon's conservative cost, named. **Mooting is on the record, not by deletion**: an approval left behind when the workflow departs its state would otherwise clear the transition on a return path arbitrarily later with no fresh decision. Approval Step's terminal absorption forbids withdrawing an Approved step, and its withdrawal is the submitter's alone, so there is no discard path — a live approval is consumed by its firing, mooted on the record, or it stands.

### Reconciliation

```
Reconciliation 1: The sweep MUST run at EVERY process start.
Reconciliation 2: The sweep MUST run every reconciliation cadence.
Reconciliation 3: The sweep MUST enumerate the workflows from the start events.
Reconciliation 4: The sweep MUST NOT examine a young intent.
Reconciliation 5: The sweep MUST NOT examine an aged record.
Reconciliation 6: The sweep MUST NOT pre-check a workflow BEFORE taking the workflow's instance exclusion.
Reconciliation 7: IF another holder holds the instance exclusion THEN the sweep MUST leave the workflow to the sweep's next run.
Reconciliation 8: The sweep MUST NOT commit constituent state BEFORE the sweep's recovery intent for the closure lands.
Reconciliation 9: A recovery intent MUST carry the instance id, the leg, the intent reference AND the plan.
Reconciliation 10: The sweep MUST attest EVERY write the sweep makes under the service identity carrying the recovery flag AND the human actor.
Reconciliation 11: IF a history entry's transition id no firing event names THEN the firing leg MUST re-emit the firing event from the entry.
Reconciliation 12: The firing leg MUST pair a re-emitted firing event to the unmatched fire intents on the entry's gate key whose intent instant EQUALS the entry's fired instant AND whose actor EQUALS the entry's actor.
Reconciliation 13: The firing leg MUST set the consumed mark of a re-emitted guarded firing.
Reconciliation 14: IF a committed firing's moot plan names a step no moot record names THEN the cascade leg MUST run the moot cascade's owed calls for the step.
Reconciliation 15: IF a Pending step no opening event names pairs to an open intent THEN the opening leg MUST complete the step's assign AND record the step's opening event.
Reconciliation 16: The opening leg MUST pair a Pending step to the unmatched open intents whose intent instant EQUALS the step's submitted instant AND whose approver reference AND scope EQUAL the step's.
Reconciliation 17: IF a Pending step no opening event names pairs to no open intent THEN the sweep MUST open an out-of-band finding for the step.
Reconciliation 18: IF a terminal step an opening event names carries no decision event AND no moot record THEN the decision leg MUST pair the step to the matching decision intents.
Reconciliation 19: IF one decision intent matches THEN the decision leg MUST record the step's decision event.
Reconciliation 20: IF no decision intent matches THEN the decision leg MUST NOT record a decision event.
Reconciliation 21: IF no decision intent matches AND the step IS IN the planned steps THEN the sweep MUST leave the step to the cascade leg.
Reconciliation 22: IF no decision intent matches AND the step IS NOT IN the planned steps THEN the sweep MUST open an out-of-band finding for the step.
Reconciliation 23: IF a decided step's decision event landed AND the active assignment read answers an assignment for the step THEN the decision leg MUST call recall on the assignment.
Reconciliation 24: IF the candidate count EXCEEDS one THEN the re-emitted record MUST carry the intent candidates.
Reconciliation 25: IF the firing leg's candidate count EXCEEDS one THEN the cascade leg MUST run over the union of the candidates' moot plans.
Reconciliation 26: IF the candidate count EXCEEDS the intent candidates cap THEN the sweep MUST open an unresolved finding for the record.
Reconciliation 27: The sweep MUST NOT re-emit a start event.
Reconciliation 28: The sweep MUST retry ONLY a transient arm.
Reconciliation 29: IF an owed record's escalation instant PRECEDES the sweep's now THEN the sweep MUST open an unresolved finding for the record.
Reconciliation 30: IF Audit Trail answers invalid-credential to the service identity THEN the deployment MUST page on the answer as a service credential fault.
```

Term sweep: the reconciliation the composition runs outside every invocation, at restart and on the cadence — four legs diffing the constituent stores against the trail.

Term firing leg: the sweep's leg landing a committed firing's owed firing event.

Term cascade leg: the sweep's leg landing a committed firing's owed moot cascade.

Term opening leg: the sweep's leg completing a committed opening.

Term decision leg: the sweep's leg landing a committed decision's owed event and recall.

Term leg: firing | cascade | opening | decision.

Term aged record: a record whose instant plus the audit horizon plus the clock offset allowance PRECEDES the sweep's now.

Term planned steps: the steps a committed firing's moot plan names.

Term young intent: an intent whose intent instant plus the completion bound DOES NOT PRECEDE the sweep's now.

Term recovery intent: the workflow_recovery_intended event (2026-08-30-a).

Term intent reference: the intent event id where one intent pairs, or the intent candidates.

Term plan: the owed calls the sweep is about to make for the closure.

Term matching decision intents: the unmatched decision intents naming the step whose decision matches the step's terminal state, whose actor equals the step's decider, and whose intent instant equals the step's decided instant.

Term candidate count: how many intents a leg pairs to one owed record.

Term intent candidates: the paired intents where more than one pairs on the clock's resolution — intent_event_candidates.

Term transient arm: a recording-failure at a pre-append step; a storage-failure on assign, withdraw or recall; a constituent's temporal invalid-request, cured by a later reading.

Term escalation instant: an owed record's commit instant plus the compensation window.

WHY:
**Every retry-until-lands obligation is a diff, not a memory** (2026-08-27; the sections titled *A reconciliation is bounded at both ends*, *A compensator is exclusive* and *Recovery commits under a declared service identity* in `pressure-testing.md`). A crash between a commit and its record — or between a fire and the cascade it owes — loses every in-flight retry, and an obligation that lived only there would leave the act unrecorded, the mooted gates Pending, and a guarded firing's approval reading unspent. So each obligation is stated as a diff between a constituent store and the trail, computed by the sweep; an implementation's in-flight retry set is a cache of the same diff, extraction-pending against a durable Outbox atom *(forthcoming)* owning records owed for committed acts. **Bounded at both ends, exclusive, as the composition**: no intent younger than the bound, whose invocation may still be about to write; no record past the widened horizon, where the payloads a leg would join on are destroyed; every pre-check re-read under the instance exclusion; every commit preceded by its recovery intent and attested under the service identity with the human in the payload. It is **Reconciliation, not Housekeeping**: an auditor awaits its output.

**The legs join on the shared reading and never choose** (Reconciliation 11 through 26). Each invocation passes one reading to its constituent and stamps the same on its intent, so a history entry, a step or a decision pairs to its intent by equality on that reading plus the actor — and where the clock's resolution admits two, the re-emission names both and the cascade runs over the union of their plans. **The decision leg re-emits only what an intent authorizes** (Reconciliation 18 through 22): refused intents accumulate on a step by design, and joining on the step id alone would land a decision event for a decision that never happened; a step withdrawn with the cascade's reason by the initiator is the cascade leg's; any other unmatched terminal step, and a Pending step no open intent pairs, was written outside the composition and is a finding, never given a record it did not earn. **The start orphan is not a leg** (Reconciliation 27): the caller re-invoked, and an orphan instance is unreachable through State Machine's keyed reads — External check 1.

**Retry transience, partitioned** (Reconciliation 28 through 30). A retry loops only on a transient arm; every deterministic arm lands once. Past the window an owed record is escalated as an unresolved finding rather than left as a loop nobody can tell from an abandoned one. invalid-credential on the service identity's own write is the deployment's credential, paged until rotated.

### Scope vocabulary

```
Scope vocabulary 1: The composition MUST define workflows start, workflows open gate, workflows fire AND workflows read for the Permissions instance.
Scope vocabulary 2: The composition MUST NOT gate [Decide Gate] on a Permissions scope.
```

WHY:
Permissions treats scopes as opaque; the four are the minimum useful set, and a deployment distinguishing initiator roles adds finer scopes and wires them. Gate decisions are gated by Approval Step's approver and submitter exclusivity (Scope vocabulary 2) — a second check would be redundant and could drift — as Multi-Party Approval does for its steps.

### Cascade

```
Cascade 1: The moot cascade MUST act on the fire intent's recorded moot plan.
Cascade 2: IF a planned entry's moot kind EQUALS pending-withdrawn THEN the moot cascade MUST call Approval Step's withdraw on the entry's step with the initiator reference as the withdrawer, the moot reason AND the firing's now.
Cascade 3: The moot cascade MUST NOT call withdraw on an approved-unconsumed entry's step.
Cascade 4: The moot cascade MUST call recall on EVERY planned step's assignment.
Cascade 5: IF withdraw answers not-pending THEN the moot cascade MUST read the withdrawal as done.
Cascade 6: IF recall answers not-active THEN the moot cascade MUST read the recall as done.
Cascade 7: The moot cascade MUST record a moot record per planned entry carrying the fire intent's event id, the transition id, the entry's gate key, the fired action, the step id, the moot kind, the moot reason AND the firing's now under the service identity.
Cascade 8: A landed moot record MUST set the entry's mooted mark.
Cascade 9: The moot cascade MUST NOT change a gate binding's bound step.
Cascade 10: IF a cascade call fails THEN the moot cascade MUST proceed through the remaining calls.
Cascade 11: A failed cascade call MUST NOT change the firing's answer.
Cascade 12: IF a cascade call fails on a transient arm THEN the invocation MUST retry the call under the instance exclusion.
```

Term moot cascade: the secondary calls a committed firing owes the gates it left behind.

Term moot plan: the gate keys of the instance other than the firing's own, whose from-state differs from the to-state and whose bound step is Pending or a live approval — enumerated from the instance's opening events, the latest per gate key, each key resolved through the keyed binding lookup with a rebuild on a miss — each carrying its moot kind.

Term moot kind: pending-withdrawn | approved-unconsumed.

Term moot record: the moot_gate_recalled event.

Term moot reason: "Gate moot: workflow left the gate's from_state by firing a different transition".

Term fired action: the action of the firing that mooted the gate, beside the mooted gate's own.

WHY:
**The plan is derived from the events, not by enumerating the index** (Cascade 1). The binding index is a derived index whose contract is a keyed lookup with a rebuild on a miss, and a lookup that finds nothing is observable; an enumeration of the same index has no miss to observe, so a lost entry would drop a gate from the plan silently and permanently — the cascade would never moot it, the check keyed on the plan could never notice, and a human approval this firing made moot would stand ready to clear the transition if the workflow ever returned. So the plan enumerates the append-only opening events and resolves each key through the keyed lookup; only a miss that survives the rebuild is a miss. The derivation is payload-sourced and bounded by the horizon, which is why Capability requirement 3 keeps the horizon beyond every workflow's life (2026-08-30-g). **Under the instance exclusion the plan is exact**, since nothing can decide a bound step between the derivation and the cascade — so a planned gate with no moot record is an owed withdrawal, and a moot record the plan never named is a conformance failure (Check 7.1 and 7.2).

**Two kinds, one record** (Cascade 2 through 9). A Pending step is withdrawn under the initiator — the gate's submitter — with the firing's own reading, since the cascade is part of the firing's invocation; an Approved step is not withdrawn, Approval Step's terminal absorption forbidding it, and its assignment was already recalled at its decision, so what spends it is the moot record and the mooted mark — a step standing in the store as a decision that authorized nothing. The binding is never deleted: a withdrawn step's terminal state or an Approved step's mooted mark is what marks it discharged, and a return-path re-entry re-binds a fresh gate through [Open Gate]. **A failed cascade call fails nothing** (Cascade 10 through 12): the firing stands, and the owed call is retried inside the bound and is the cascade leg's past it.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent, and each needs two or more working together. The relations they rest on, per the section titled Structural-relation invariant templates in `spec-format.md`: a workflow has **zero or more** gate bindings, one current binding per gate key, the key's full history in its opening events; each bound step has **exactly one** assignment, mandatory at a landed opening; each firing has **exactly one** firing event at quiescence; each workflow has exactly one workflow record. A lost index entry is a rebuild trigger, never a relation violation — the relations hold in the events.

- **Invariant 1 — Approval-gated transition, one firing per approval.**
  ```
  Invariant 1.1: EVERY guarded history entry MUST carry a firing event naming a step the entry's [Gate Spec] approver approved.
  Invariant 1.2: Two guarded firing events MUST NOT carry one step id.
  Invariant 1.3: A guarded firing event MUST NOT name a step a moot record names earlier in the Event Log sequence.
  ```
  WHY: the load-bearing claim — a history entry with its guard asserted means the composition verified a live approval, not that it trusted a caller. The binding is resolved from the firing event's own step id, never from the opening events' order, which a recovery window can reorder (2026-08-26-f). One decision cannot authorize repeated regulated firings: a return path re-binds a fresh gate. Inside a firing's recovery window the committed-but-unrecorded firing is itself the consumption, so the window admits no second firing; an approval the workflow departed from is mooted on the record, so a return path never fires on it. Since the decision intent verifies the approver before the step records the decision (Invariant 8), the claim reaches a principal and not merely a matching reference. *Rests on* State Machine Invariant 3 and 8, Approval Step Invariant 4, Wiring decision 1 through 7, and the mark durability past the horizon.
- **Invariant 2 — Permission-gated advancement.**
  ```
  Invariant 2.1: [Start Workflow] MUST NOT commit for an actor reference the permission check denied.
  Invariant 2.2: [Open Gate] MUST NOT commit for an actor reference the permission check denied.
  Invariant 2.3: [Fire Transition] MUST NOT commit for an actor reference the permission check denied.
  ```
  WHY: the claim is the grant held at the check; grants may change afterwards. The permission check takes a reference and no credential, so the reference whose grant was checked is anchored by Invariant 8's intent. Gate decisions are Approval Step's exclusivity, not a scope (Scope vocabulary 2).
- **Invariant 3 — Attributed and sealed history.**
  ```
  Invariant 3.1: IF a workflow IS IN the quiescent workflows THEN EVERY committed act on the workflow MUST carry EXACTLY ONE outcome.
  Invariant 3.2: EVERY moot cascade entry on a quiescent workflow MUST carry EXACTLY ONE moot record.
  Invariant 3.3: EVERY outcome MUST name a workflow the workflow store carries.
  ```
  Term quiescent workflows: the workflows with no invocation in flight and no record owed past its invocation.

  Term committed act: a machine history entry, or a step's submission or decision through the composition.

  WHY: every workflow start, opening, decision and firing produces exactly one outcome, and every mooted gate one moot record; intents are outside the count, since an invocation refused and retried leaves several for one eventual act, and the recovery intents are the sweep's own. The lifecycle reads forward through the trail in the substrate's sequence and backward through the transition-event and binding indexes. The substrate's atomicity is inherited: its edge case admits an attestation with no Event Log entry when attest succeeds and append fails, and the deployment alerts on such an orphan on this composition's action references. *Rests on* each action's outcome, the sweep, and Audit Trail's own invariants.
- **Invariant 4 — Gate assignment coverage.**
  ```
  Invariant 4.1: IF a gate's bound step EQUALS Pending AND the workflow IS IN the quiescent workflows THEN the step MUST carry EXACTLY ONE Active assignment.
  Invariant 4.2: IF a gate's bound step IS IN the settled steps AND the workflow IS IN the quiescent workflows THEN the step MUST carry no Active assignment.
  ```
  Term settled steps: the steps in a terminal state, and the steps a moot record names.

  WHY: an assignment is recalled at the gate's decision or by the moot cascade, and two windows are admitted, each alerting and each re-derived by the sweep: a decision's recall still retrying, and a firing's cascade still landing — the cascade runs on the commit, so the post-commit path opens the window rather than escaping the cascade. The coverage rests on the plan's derivation from the opening events (Cascade 1): computed by enumerating the binding index, a lost entry would be indistinguishable from a gate never opened and this invariant would be false in a way no check could see.
- **Invariant 5 — Only declared transitions, replay-deterministic.**
  ```
  Invariant 5.1: The composition MUST NOT write the workflow machine's history outside fire.
  Invariant 5.2: EVERY history entry MUST name a declared transition.
  ```
  WHY: State Machine's own Invariant 3 and 7, surfaced because the audit proof rests on them: guarded and unguarded transitions fire through the same surface, and only the guard's assertion differs — the composition's, never the caller's.
- **Invariant 6 — Records-alone process proof, within the audit horizon.**
  ```
  Invariant 6.1: EVERY workflow's process proof MUST resolve from the records alone.
  ```
  Term process proof: that the process moved only through declared transitions; that each guarded entry's firing event names a step Approved under the [Gate Spec] entry — the binding current at the firing, which a later re-bind may have repointed; that the approving actor matched the entry's approver; that the firing actor held [Workflows Fire]; and that the history is attributed and sealed.

  WHY: State Machine supplies the path, Approval Step the approval and its approver, Permissions the grant, Audit Trail attribution and sealing; the composition joins them in one surface. The read's set-valued queries are anchored in the start and opening events, so a lost index entry cannot drop a workflow or a gate from the proof (2026-08-27-f). *Rests on* Action wiring 67 through 71, the declared log read and the horizon's ordering obligation.
- **Invariant 8 — Authentication precedes commitment.**
  ```
  Invariant 8.1: The composition MUST NOT call instantiate BEFORE Audit Trail validates the caller's credential at the start intent.
  Invariant 8.2: The composition MUST NOT call submit BEFORE Audit Trail validates the caller's credential at the open intent.
  Invariant 8.3: The composition MUST NOT call a decision's step write BEFORE Audit Trail validates the caller's credential at the decision intent.
  Invariant 8.4: The composition MUST NOT call fire BEFORE Audit Trail validates the caller's credential at the fire intent.
  Deleted: Invariant 7. Composes 6 owns it.
  ```
  WHY: at the four state-changing actions nothing commits before the acting reference's credential validates against the actor registry; invalid-credential is a pre-commit refusal and the whole action is retryable. [Read Workflow] commits nothing and is outside. **The binding half** is where the load-bearing claim rested: [Decide Gate] carries no permission check, and Approval Step's exclusivity compares a supplied reference against a stored one — both unverified strings until the intent — so a caller who knew an approver's reference could commit that approver's decision. The intent does not change the comparison; it establishes the caller *is* the actor compared, before the decision commits, which is what makes Invariant 1's *the named approver approved* a statement about a principal; Invariant 2's grant check gains the same anchor. **What a validation does not establish**: that the presenter is the actor — a stolen credential validates — nor a channel binding or replay resistance, nor that the named approver was the *correct* authority (External check 3 and 5). The deleted invariant asserted each constituent's invariants hold over its instance, which Execution Contract Conformance 8 settles by reference (council read 53). *Rests on* the audit write and the Actor Identity attestation reached through it; Check 6.1 tests the order from the records.

---

## Examples

### Walkthrough — FDA 21 CFR Part 11 / ISO 9001 pharmaceutical batch release

A pharmaceutical manufacturer's batch-release system uses this composition to govern the lifecycle of batch `BR-2026-0412` under FDA 21 CFR Part 211 (Current Good Manufacturing Practice for Finished Pharmaceuticals) and FDA 21 CFR Part 11 (Electronic Records; Electronic Signatures). The deployment configures `audit_trail_retention_policy = fda_part_11_predicate_rule`.

**Declaration.** The deployment declares the following process:

```
states: {sampled, testing, qp-review, released, rejected}
transitions: [
  {from: sampled,    action: begin-testing,  to: testing},
  {from: testing,    action: complete-tests, to: qp-review},
  {from: qp-review,  action: release,        to: released, guard: "QP-sign-off"},
  {from: qp-review,  action: reject-batch,   to: rejected, guard: "QP-rejection"},
  {from: testing,    action: fail-tests,     to: rejected}
]
initial_state: sampled
terminal_states: {released, rejected}
```

QP is the qualified person, the named batch-releaser role under EU (European Union) and FDA pharmaceutical manufacturing rules. The gate_spec maps `"QP-sign-off"` to `{approver_ref: "qp_director_santos", scope: "pharma:batch-release:qp-sign-off"}` and `"QP-rejection"` to `{approver_ref: "qp_director_santos", scope: "pharma:batch-release:qp-rejection"}`.

1. **QA (quality assurance) manager starts the workflow.** `start_workflow(actor_ref=qa_manager, declaration, subject_ref="br-2026-0412", gate_spec, credential=qa_credential)` → Permissions returns permitted (qa_manager holds `workflows:start`); gate_spec validates (two guarded transitions, two matching entries, both within the guarded-transition cap) — **validation precedes the intent record deliberately**, because the intent event's payload carries the whole gate_spec and it is this validation that keeps that payload inside the budget; then — **before any instance is minted** — Audit Trail records `workflow_start_intended`, which is where `qa_credential` is checked against the actor registry (had it not validated, the call would have returned `rejected(invalid-credential)` with no State Machine instance created); `WorkflowStateMachine.instantiate(declaration)` → `instance_id="wf-batch-br-2026-0412"`; Audit Trail records `workflow_started`; the `workflow_store` record is written over the landed event (record before map). Returns `{instance_id="wf-batch-br-2026-0412"}`.

2. **Lab technician begins testing.** `fire_transition(actor_ref=lab_tech_rivera, instance_id, action="begin-testing", credential)` → Permissions permitted; `begin-testing` is an unguarded transition; the moot-gate plan is empty (no gate is bound yet) and Audit Trail records `transition_intended` carrying it, verifying the technician's credential; `WorkflowStateMachine.fire(instance_id, "begin-testing", actor_ref=lab_tech_rivera)` → `new_state="testing"`; Audit Trail records `transition_fired`; `transition_to_event` updated. Returns `"testing"`.

3. **Tests complete; QA manager advances to QP review.** `fire_transition(actor_ref=qa_manager, instance_id, action="complete-tests", credential)` → unguarded; `transition_intended` records first (empty plan), verifying the credential; fires; Audit Trail records `transition_fired` carrying `intent_event_id`. `current_state = "qp-review"`.

4. **QA manager opens the release gate.** `open_gate(actor_ref=qa_manager, instance_id, action="release", credential)` → Permissions permitted (qa_manager holds `workflows:open-gate`); matched transition has guard `"QP-sign-off"`; not already open; Audit Trail records `gate_open_intended` — verifying the manager's credential before any Approval Step exists, and carrying no `step_id`, since none has been minted; `ApprovalStep.submit(subject_ref="br-2026-0412:release", approver_ref="qp_director_santos", submitter_ref="qa_manager", scope="pharma:batch-release:qp-sign-off")` → `step_id="step-qp-0412-release"`; `Assignment.assign(task_ref=step_id, assignee_ref="qp_director_santos")` → `assignment_id="asgn-qp-0412"`; Audit Trail records `gate_opened`; maps written over the landed event (record before maps). Returns `{step_id, assignment_id}`.

5. **QP Director reviews and approves.** `decide_gate(actor_ref=qp_director_santos, instance_id, action="release", decision="approve", reason="Batch specification limits met; COA (Certificate of Analysis) reviewed; QP sign-off granted under 21 CFR 211.68", credential=qp_credential)` → no Permissions check (Approval Step Invariant 4 is the enforcement); `gate_binding[(instance_id, "qp-review", "release")]` → `step_id`; then Audit Trail records `gate_decision_intended` → `ev_dec_int`, **which is where `qp_credential` is validated against the actor registry — so the sign-off that follows is made by a verified principal, not by whoever supplied the string `"qp_director_santos"`**; `ApprovalStep.approve(step_id, decided_by="qp_director_santos", reason=...)` → approved; `Assignment.recall(asgn-qp-0412)`; Audit Trail records `gate_decided`. Returns approved.

6. **QA manager fires the release transition.** `fire_transition(actor_ref=qa_manager, instance_id, action="release", credential)` → Permissions permitted; matched transition is guarded; `gate_binding[(instance_id, "qp-review", "release")]` → `step_id="step-qp-0412-release"`; `ApprovalStep.read({step_id})` → step state is Approved and unconsumed — the gate resolution is read-only and settles the gate before anything is recorded; then Audit Trail records `transition_intended` carrying `{guarded: true, step_id: "step-qp-0412-release", to_state: "released", moot_gate_plan: []}` → `ev_fire_int` — the plan is **empty** because the only gate ever opened on this instance is the one this firing consumes — excluded from the plan by Action wiring 54, since its approval is spent by the firing, not left behind by it — and no other gate is bound and Pending or Approved-and-unconsumed; an empty plan is a positive claim, not a missing field, and Check 7.1 reads it as *this firing was to moot nothing*, verifying `qa_manager`'s credential before the batch is released; composition asserts `guard_satisfied = true`; `WorkflowStateMachine.fire(instance_id, "release", actor_ref="qa_manager", guard_satisfied=true)` → `new_state="released"`; Audit Trail records `transition_fired` with `guarded=true, step_id`; `transition_to_event` updated. Check moot-gate cascade: `current_state` is now `"released"` (terminal); the `"QP-rejection"` gate was never opened, so no cascade is needed. Returns `"released"`.

7. **Attempt to fire after terminal state.** `fire_transition(actor_ref=qa_manager, instance_id, action="release", credential)` → Permissions permitted; `WorkflowStateMachine.current(instance_id)` → `"released"` ∈ `terminal_states`; returns terminal.

8. **Two years later — FDA Part 11 inspection.** Inspector queries `read_workflow({instance_id: "wf-batch-br-2026-0412"})`. The composed view returns: workflow record; State Machine history (3 entries — `begin-testing`, `complete-tests`, `release` — tracing sampled → testing → qp-review → released); each transition's Audit Trail `event_id`; the `"QP-sign-off"` gate's Approval Step (Approved, `decided_by=qp_director_santos`, `decided_at`, `decision_reason`). The inspector calls `AuditTrail.verify_record(event_id, payload)` for the `transition_fired` event on the release transition and receives `verified`. The inspector confirms: (a) the batch moved only through declared states (Invariant 5); (b) the release transition fired with `guard_satisfied=true` and the bound step is in Approved state (Invariant 1); (c) the QP's identity is attested under Part 11 section 11.50 (Audit Trail Actor Identity). Control evidence is complete from the records alone.

---

### Happy path — SOX section 404 journal-entry posting workflow

A financial system governs posting of journal entries above the $5M materiality threshold. The declaration has states `{draft, submitted, posted, rejected}` with an unguarded `submit` transition (draft → submitted), a guarded `post` transition (submitted → posted, guard `"controller-sign-off"`), and an unguarded reject transition (submitted → rejected). The gate_spec binds `"controller-sign-off"` to `{approver_ref: "controller_morgan", scope: "financial:journal-entry:post:materiality-tier-3"}`.

JE-2026-0441: the preparer calls [Start Workflow]; fires `submit`; calls `open_gate(action="post")`; the controller calls `decide_gate(decision="approve")`; the preparer calls `fire_transition(action="post")`. Each of those five invocations opens with its own intent record — the write that verifies the caller's credential before anything commits — and each outcome event carries `intent_event_id` back to it (Invariant 8, Check 6.1); the narration below elides them only for brevity, and an implementation that elided them would fail Check 6.1. The composition verifies the controller's Approval Step is in Approved, asserts `guard_satisfied=true`, and fires. Audit Trail records each action under `sox_7_year` retention. Seven years later, a SOX section 404 audit queries the workflow and confirms Invariants 1, 2, and 6.

---

### Rejection path — guarded transition attempted without open gate

The QA manager in the pharmaceutical scenario, after `current_state = "qp-review"`, calls `fire_transition(action="release")` without having called [Open Gate] first. At [Fire Transition]'s gate resolution: `gate_binding[(instance_id, "qp-review", "release")]` does not exist; the composition returns gate-not-cleared. The State Machine records no transition. No history entry is written. The QA manager must call [Open Gate] first, then wait for the QP's decision, then retry [Fire Transition].

---

### Rejection path — guarded transition attempted with gate in Pending

The QA manager has opened the release gate (`gate_binding` set) but the QP has not yet decided. The QA manager calls `fire_transition(action="release")`. At [Fire Transition]'s gate read: `ApprovalStep.read({step_id})` → state is Pending; the composition returns gate-not-cleared. No `WorkflowStateMachine.fire` call is made. The gate must reach Approved before the transition can fire.

---

### Rejection path — unauthorized transition attempt

An actor lacking `workflows:fire` calls [Fire Transition]. At the permission check, `Permissions.permitted(actor_ref, workflows:fire)` → `denied`; returns [Permission Denied] immediately. No State Machine call is made. No Audit Trail entry is produced for the unauthorized attempt (Non-goal 6).

---

### Rejected gate and recovery — re-binding after a Rejected step

A journal-entry workflow's `post` transition is guarded; its gate is open and bound to `step-je-091`. The controller rejects: `decide_gate(..., decision="reject", reason="Supporting docs incomplete — resubmit with invoice attached")` → `gate_decision_intended` records first, which is where the controller's credential is validated — this action has no Permissions check, so that record is the only thing standing between an asserted actor_ref and a committed rejection — then `ApprovalStep.reject` → rejected_outcome; the Assignment is recalled; `gate_decided` is recorded carrying `intent_event_id`. A subsequent `fire_transition(..., action="post")` reads the bound step, finds `Rejected`, and returns `rejected(gate-not-cleared)` — the rejection stands as the gate's outcome, but it does not brick the transition: after the preparer attaches the invoice, `open_gate(..., action="post")` finds the bound step in `Rejected` (a terminal non-Approved state — Wiring decision 7's re-binding rule), records `gate_open_intended`, binds a fresh Approval Step `step-je-114`, repoints `gate_binding`, and assigns it to the controller's in-tray. The controller approves the fresh gate (its own intent record first); fire_transition now reads `Approved` on the current binding and fires. Both gates' histories persist — two `gate_opened` events for the pair, the Rejected step immutable in the Approval Step store with its stated reason — so the auditor sees the rejection, the rework, and the eventual approval as three records, not a mutated one.

### Failure path — transition fired, audit write fails

A fire_transition commits its `WorkflowStateMachine.fire` (the load-bearing write) and the step-6 `record_action` fails: the caller receives `rejected(recording-failure(post-commit))` — the stage discriminator says the transition **did** fire, so the caller must not re-invoke (a retry would fire again; the transition is non-idempotent) and instead confirms the new state via [Read Workflow]. The implementation retries the audit write until it lands or `workflow_completion_bound` elapses — after which the write is the restart sweep's alone — the landed entry — emitted under the composition actor when the retry completes outside the original invocation, the firing actor in its `data` and `recovery = true` (an ordinary payload field — the substrate offers no marker surface, and none is needed) — letting the auditor distinguish the recovered attestation from a clean one; until it lands, the missing entry is a gap in Invariant 3 surfaced as a hard alerting condition (Reconciliation 11). The moot cascade still ran before the action returned — it is conditioned on the fire's commit, not on the record — and, had the process died before either the record or the cascade completed, the restart sweep would have found the history entry no `transition_fired` event names, re-emitted the record, and completed the cascade from the intent event's plan; the bound step reads consumed throughout, because the consumption test reads the history.

### Moot-gate cascade — alternate transition leaves a gate unreachable

A purchase-order workflow has `current_state = "awaiting-approval"` with a guarded approve transition (guard `"finance-sign-off"`) and an unguarded `cancel` transition, both departing from `awaiting-approval`. The finance director's approval gate has been opened (`gate_binding[(instance_id, "awaiting-approval", "approve")]` set, Approval Step in Pending). A process manager calls `fire_transition(action="cancel")`. The `cancel` transition is unguarded, so the firing derives the moot plan read-only — the declared `to_state` is `"cancelled"`, and the one bound gate on this instance keys from `"awaiting-approval"` with its step still Pending, so the plan is `[{from_state: "awaiting-approval", action: "approve", step_id}]` — and records `transition_intended` carrying it, verifying the process manager's credential before the cancellation commits. The fire then succeeds; `new_state = "cancelled"`. The moot cascade: the `"approve"` gate's `from_state = "awaiting-approval"` ≠ `"cancelled"` = `new_state`; the gate is moot. The composition calls `ApprovalStep.withdraw(step_id, withdrawn_by=initiator_ref, reason="Gate moot: ...")`, `Assignment.recall(assignment_id)`, and `AuditTrail.record_action(action_ref=moot_gate_recalled, actor_ref=application_actor_ref, ...)`. The finance director's in-tray no longer shows the approval task. The audit trail records the withdrawal and the reason. Had the finance director already approved the gate and nobody fired approve before the cancellation, the plan would have named the same key with `moot_kind = approved-unconsumed`: no withdraw (the step is terminal), the recall an idempotent `not-active`, one `moot_gate_recalled` recording that the approval was mooted, and the binding's mooted flag set — so a return to `awaiting-approval` re-binds a fresh gate rather than firing on the stale sign-off.

---

### Regulated adversarial scenarios

Three adversarial reads this composition must survive in regulated contexts:

#### Regulator audit — SOX section 404 / FDA 21 CFR Part 11: prove declared-path and gate-cleared

An FDA inspector or SOX auditor demands evidence that process instance `wf-batch-br-2026-0412` moved only through its declared states and that the qualified-person gate was genuinely cleared before the release transition fired. The auditor queries `read_workflow({instance_id: "wf-batch-br-2026-0412"})` and receives the composed view. The auditor confirms: (a) every transition in the State Machine history corresponds to a declared transition (`read_declaration` returns the immutable declaration; Invariant 5 — constituent State Machine Invariant 3 — guarantees no undeclared transition could have produced a history entry); (b) the `"release"` history entry carries `guard_satisfied: true`, and its `transition_fired` event — reached via `transition_to_event` — carries the `step_id` pointing to the bound Approval Step (the history entry itself carries no `step_id`; the binding lives in the composition's records); (c) `ApprovalStep.read({step_id})` returns `state: Approved`, `decided_by: "qp_director_santos"`, `decided_at`, and `decision_reason`; (d) Approval Step Invariant 4 guarantees `decided_by` matched `approver_ref` at the time of the approve call; (e) `AuditTrail.verify_record(event_id, payload)` for the `transition_fired` event returns `verified`. The auditor's structural questions — *did the batch move only through declared states?* and *was the release gate cleared by the named QP?* — are answered from the records alone under Invariants 1, 5, and 6. No recourse to source code, runbooks, or developer narration is needed.

#### Disputed transition — party claims a guarded transition fired without its approval

An external party (an auditor, a counterparty, an investigator) claims that the `"release"` transition fired in instance `wf-batch-br-2026-0412` without QP approval, or that an unauthorized actor advanced the process. The structural rebuttal:

For the "no approval" claim: the State Machine history entry for the release transition carries `guard_satisfied: true` (State Machine Invariant 8 — the atom records whether the caller asserted the guard). The composition's `gate_binding[(instance_id, "qp-review", "release")]` maps to `step_id="step-qp-0412-release"`. `ApprovalStep.read({step_id})` returns `state: Approved`. Invariant 1 of this composition states that `guard_satisfied = true` was asserted by the composition only because the bound step was in Approved at the time of [Fire Transition]'s gate read. A forgery would require either (a) fabricating an Approved Approval Step record for a step whose `approver_ref` is `qp_director_santos` — foreclosed by Approval Step Invariant 4 (only the named approver may decide) and by the Audit Trail's tamper-evident sealing — or (b) fabricating a State Machine history entry with `guard_satisfied: true` — foreclosed by State Machine Invariant 5 (history append-only — no `fire` writes an entry unless it succeeded; every one of its rejection arms writes nothing) and by Tamper Evidence sealing. Invariants 1, 3, and 5 together constitute the structural rebuttal.

For the "unauthorized actor advanced the process" claim: `AuditTrail.verify_record` for the `transition_fired` event returns the Actor Identity attestation, binding the actor reference to the action at the attested timestamp. Invariant 2 (Permission-gated process advancement) guarantees the firing actor held `workflows:fire` at the time of the Permissions check. An auditor confirms both.

#### Breach or incident investigation — reconstruct transitions and gate decisions during anomaly window

During a security incident (suspected credential compromise from 2026-05-01T00:00:00Z to 2026-05-03T23:59:59Z), the incident response team must determine which workflow transitions fired and which gates were cleared during the window. The team queries `read_workflow({started_at: {after: "2026-04-25T00:00:00Z"}})` for all recently started workflows — a set-valued query, answered from the `workflow_started` events and never from an enumeration of `workflow_store` (Action wiring 68). For each instance, the team inspects the State Machine history and — via `transition_to_event` — the corresponding Audit Trail `event_id`s. For each `transition_fired` event in the anomaly window, the team calls `AuditTrail.verify_record(event_id, payload)` to confirm integrity. Any `failed-verification(seal-proof-invalid)` or `failed-verification(seal-record-set-mismatch)` response — the substrate's actual tamper-indicating reason tokens — indicates a post-hoc modification, a forensic finding. For guarded transitions in the window, the team cross-references the bound Approval Step via `gate_binding`: `ApprovalStep.read({step_id})` returns `decided_by` and `decided_at`, and the Audit Trail `gate_decided` event confirms the gate decision under the Actor Identity attestation. The team also queries the Permissions store for actors who held `workflows:fire` during the window; a transition fired by an actor whose grant was not active at the firing instant is a candidate finding, judged best-effort in wall time as Check 5.1 states. Invariants 3 and 5 bound the forensic window precisely: the transition history is the complete ordered record of every step that advanced the process; the Audit Trail provides the integrity attestation for each.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when an external auditor, given the composition's emergent state and the constituent stores, can clear the checks below without recourse to source code, runbooks or developer narration. Every trail walk runs through the log read, assuming no payload index; every check that walks events runs inside the audit horizon.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY guarded history entry's firing event naming a step Approved by the entry's [Gate Spec] approver (Invariant 1.1).
Check 1.2: An auditor MUST resolve a guarded firing's binding from the firing event's own step id (Invariant 1.1).
Check 1.3: An auditor MUST find no step id two guarded firing events carry (Invariant 1.2).
Check 1.4: An auditor MUST find no guarded firing event naming a step a moot record named earlier in the Event Log sequence (Invariant 1.3).
Check 2.1: An auditor MUST find EVERY history entry naming a declared transition (Invariant 5.2).
Check 2.2: An auditor MUST find EVERY workflow's history replaying from the initial state to the current state (Invariant 5.1).
Check 2.3: An auditor MUST find a workflow's declaration byte-identical across two reads (Invariant 5.1).
Check 3.1: An auditor MUST find EXACTLY ONE firing event for EVERY history entry of a quiescent workflow (Invariant 3.1).
Check 3.2: An auditor MUST find EXACTLY ONE opening event for EVERY step the composition submitted AND EXACTLY ONE settlement record for EVERY settled step (Invariant 3.1).
Check 3.3: An auditor MUST find EVERY outcome naming a stored subject (Invariant 3.3).
Check 3.4: An auditor MUST NOT count an uncounted event in Check 3.1 through 3.3 (Invariant 3.1).
Check 3.5: An auditor MUST find the compensation window exceeding the liveness sum (Capability requirement 8).
Check 4.1: An auditor MUST enumerate the gates from the opening events AND find the assignments PER Invariant 4.1 AND Invariant 4.2 (Invariant 4.1).
Check 5.1: An auditor MUST find the actor of EVERY start event, opening event AND firing event holding the matching scope at the outcome's payload instant (Invariant 2.1 through 2.3).
Check 5.2: An auditor MUST read a recovery-flagged outcome's actor from the payload's human actor (Invariant 2.1 through 2.3).
Check 6.1: An auditor MUST resolve EVERY outcome's intent reference to an intent that PRECEDES the outcome in the Event Log sequence AND names the same actor (Invariant 8.1 through 8.4).
Check 6.2: An auditor MUST NOT join an outcome to an intent by any key weaker than the intent event id (Invariant 8.1 through 8.4).
Check 6.3: An auditor MUST NOT read an intent carrying no outcome as a conformance failure (Audit arm 13).
Check 7.1: An auditor MUST find EVERY entry of a committed firing's moot plan accounted (Cascade 1).
Check 7.2: An auditor MUST find no moot record naming a step the firing's moot plan omits (Cascade 1).
Check 7.3: An auditor MUST find no moot plan naming the firing's own gate key (Action wiring 54).
Check 8.1: An auditor MUST find the longest workflow lifetime not exceeding the audit horizon where both are readable (Capability requirement 3).
Check 9.1: An auditor MUST clear State Machine's Generation acceptance over EVERY workflow machine (Composes 6).
Check 9.2: An auditor MUST clear Approval Step's Generation acceptance over the Approval Step instance (Composes 6).
Check 9.3: An auditor MUST clear Permissions' Generation acceptance over the Permissions instance (Composes 6).
Check 9.4: An auditor MUST clear Assignment's Generation acceptance over the Assignment instance (Composes 6).
Check 9.5: An auditor MUST clear Audit Trail's Generation acceptance over the Audit Trail instance (Composes 6).
```

NOTE: EVERY check names the rule the check tests.

Term settlement record: a decision event or a moot record.

Term stored subject: a workflow, a step or a history entry the stores carry.

Term uncounted event: an intent or a recovery intent.

Term accounted entry: a moot plan entry a moot record names, or whose owed call is still open inside the compensation window.

Term start count: whether every instantiated workflow carries its start event, and which orphan instance stands behind an unmatched start intent.

WHY:
**The binding at the firing is the firing event's own** (Check 1.1 through 1.4; 2026-08-26-f). The prose resolved it from the opening events' order, which a recovery window can reorder; the firing event names the step it consumed, which is the join. A step recurring across two guarded firings, or mooted before it fired, is a failure.

**Only declared transitions** (Check 2.1 through 2.3): the history replays in sequence order to the current state; the declaration's immutability is State Machine's, and its runnable form is two reads compared — the start event carries the declaration reference, not the declaration.

**Audit completeness is counted from the constituent stores, not from an index rebuilt from the same events** (Check 3.1 through 3.5; 2026-08-26-e, 2026-08-30-c). Firings are enumerated from the machine history and gates from the Approval Step store — counting starts from a workflow store rebuilt from the start events would be circular, so the start half is External check 1. Intents and recovery intents are outside both directions: a refused-and-retried invocation leaves several intents for one act, and one refused at its load-bearing call leaves an intent that corresponds to nothing, by design. The liveness inequality is read whole from the configuration.

**Gates are enumerated from the opening events** (Check 4.1): an auditor enumerating the binding index would quantify over a derived index whose losses are invisible to that read, and pass over exactly the gate whose assignment the check exists to verify. The two windows Invariant 4 admits are alerting conditions, not failures.

**Permission, at the pinned instant, from two sources** (Check 5.1 and 5.2; 2026-08-26-g). *Who acted* is the attestation — for a recovery-flagged outcome the service identity's, with the human in the payload corroborated by the constituent's own attribution; *whether they held the scope* is the Permissions store's point-in-time reconstruction, evaluated at the outcome's payload instant — the composition's own reading of the act, never the substrate's recording instant. Permissions mutations are not in this trail, so no shared order spans the two sources and the reconstruction is best-effort in wall time; a deployment needing an exact interleaving records its Permissions mutations to the same trail.

**The join is the intent event id and the order is the sequence** (Check 6.1 through 6.3). A return path re-fires one action on one instance, so a join by actor, instance and action would let a stale intent satisfy the check for a later firing it never authorized. A re-emission names candidates and the check runs over each. **An intent with no outcome is not a failure**, and the population is large — every pre-commit refusal leaves one. A decision or guarded firing intent carries a step id and triages against the step and the history; an unguarded firing intent joins on its gate key and, where a return path re-fires the same key, is counted rather than matched; an open intent's residue is a Pending step no opening event names; a start intent's residue is unreachable here — External check 1. Never write a compensating outcome for an intent whose effect cannot be found.

**The cascade against its plan** (Check 7.1 through 7.3): under the instance exclusion the plan is exact, so both directions are findings, and a plan naming the firing's own key would moot the approval the firing spent.

### External checks

```
External check 1: An auditor needing the start count confirmed MUST read the deployment's State Machine store-maintenance surface (Action wiring 10).
External check 2: An auditor needing the longest workflow lifetime against the audit horizon confirmed MUST read the deployment's process documentation (Capability requirement 3).
External check 3: An auditor needing a [Gate Spec] entry's approver confirmed as the correct authority MUST read the deployment's role-authorization registry at the started instant (Invariant 1.1).
External check 4: An auditor needing the declaration confirmed against the regulation's process MUST read the deployment's process documentation beside the regulation (Invariant 5.2).
External check 5: An auditor needing a named approver's standing authorization for the scope confirmed MUST read the deployment's standing-authorization registry at the started instant (Invariant 1.1).
```

WHY:
**The start half and the orphan** (External check 1): State Machine's reads are keyed by an instance id this composition may never have issued, and the atom declares no enumeration, so an orphan instance behind a start intent — and, for the same reason, the forward count of starts — needs the deployment's store surface or an enumerate-all-instances capability on the wired instance. **The lifetime** (External check 2) is a business fact — how long a trial stays open — the composition holds no expectation of. **Policy** (External check 3 through 5): the composition records the [Gate Spec] and the declaration the calling system supplied and validates their shape; whether *qp_director_santos* was the required qualified person under 21 CFR Part 211, or whether the declaration is the process the regulation requires, is the deployment's.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT gate a transition on several approvers.
Non-goal 2: The composition MUST NOT hold parallel current states in one workflow.
Non-goal 3: The composition MUST NOT share a declaration across workflows.
Non-goal 4: The composition MUST NOT bound an approval's age.
Non-goal 5: The composition MUST NOT make a repeatable act at-most-once.
Non-goal 6: The composition MUST NOT record a denied attempt.
Non-goal 7: The composition MUST NOT judge a [Gate Spec]'s fit to the regulation.
Non-goal 8: The composition MUST NOT serve an assignee-keyed in-tray view.
```

Term repeatable act: a firing or a start.

WHY:
**Several approvers are an enrichment** (Non-goal 1). A gate needing all, M or one of N approvers binds a [Multi-Party Approval](./multi-party-approval.md) chain in place of a single step, and the fire reads the chain's Approved state as it reads a step's; the [Gate Spec] entry then names a chain rather than an approver, a different entry shape, so the enrichment adjusts the validation along with the wiring. **One current state** (Non-goal 2): State Machine's own invariant; parallel active states with fork and join are a Parallel Workflow composition *(not yet in the library)*. **A declaration is a value** (Non-goal 3), fixed per run by State Machine; a shared, versioned template is a Definition Registry's, from which the caller fetches the value it supplies.

**An approval is valid while the workflow stays in its state** (Non-goal 4; 2026-08-26-k). A departure moots it on the record, but nothing here expires an approval that simply waits: the gate is state-valued and consults no clock, which is what keeps the proof clock-free. A deployment needing an approval to lapse wires a scheduler above the composition that withdraws the Pending gate or, for an Approved one, fires nothing on it and opens a fresh gate — an ordinary, attributed act. **At-most-once is the caller's key** (Non-goal 5; 2026-08-26-i): fire is not idempotent, and a start re-invoked after a lost answer mints a second workflow for one subject — which a subject may lawfully carry; a caller needing at-most-once supplies its own idempotency key through [Idempotent Reservation](./idempotent-reservation.md), and the stage on every refusal says whether a re-invoke is safe (Audit arm 13 through 15), and a lost answer is read before it is re-invoked (Indeterminate outcome 1). **Denied attempts are unrecorded** (Non-goal 6): the audit surface is committed acts and authenticated attempts; a high-assurance deployment composes a Failed-Attempt Log *(forthcoming)*. **Policy is the deployment's** (Non-goal 7; External check 3 through 5). **The in-tray view** (Non-goal 8; 2026-08-27-d): Assignment's queries are keyed by task, so *which gates sit in my in-tray* is not answerable from its surface, and this composition does not absorb it — an assignee-keyed view is a Reverse Index *(forthcoming)* lookup a deployment builds over the assignment store.

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the machine's sequence number as the order of the history.
Clock semantics 2: The composition MUST read the Event Log sequence as the order of an intent AND the intent's outcome.
Clock semantics 3: A comparison of the composition's instant with the substrate's MUST NOT decide a write alone.
```

WHY:
The invocation's one reading stamps the intent and is passed to every constituent that accepts an instant, so an intent and its outcome carry one instant by construction and are never ordered by stamps; the history's sequence number and the substrate's sequence are the order sources. Skew across the constituents' seams can make a fresh reading fall below a stored bound — a decided instant below the step's submitted instant, a fired instant below the instantiated instant — and the constituent refuses invalid-request; the composition validated the caller first, so that refusal is the skew case, landed as pre-commit and cured by a later reading (Action wiring 8). Clock quality is the deployment's, and a dishonest injected reading is the residual risk; where transition instants must be adversarially defensible, a Trusted Timestamping pattern *(forthcoming)* is the resolution.

### Concurrency

```
Concurrency 1: The instance exclusion MUST span EVERY state-changing invocation on one workflow.
Concurrency 2: The instance exclusion MUST span a firing from the firing's intent through the firing's moot cascade.
```

WHY:
The serialization domain is the instance id across all three state-changing actions — the rule the prose titled for [Fire Transition] alone (2026-08-30-h). Two firings on one workflow serialize; a firing and a decision serialize, or the composition could read a step's state that changes between the read and the fire; an opening and a firing serialize, or a firing leaving the gate's state while the opening is mid-flight would land a fresh gate the cascade never saw — under the exclusion the late opening re-reads the current state and answers invalid-transition. Under the exclusion the newest history entry after a fire is that fire's, and the moot plan is exact.

### Indeterminate outcome

```
Indeterminate outcome 1: A caller holding a lost [Start Workflow] answer MUST NOT re-invoke [Start Workflow] BEFORE reading the workflows by subject reference AND initiator reference.
Indeterminate outcome 2: A caller holding a lost instance action answer MUST NOT re-invoke the instance action BEFORE reading the workflow.
```

Term lost answer: an answer that never reached the caller.

WHY:
A lost answer is not a refusal: the act may have landed (2026-08-26-i). A start whose event landed and whose answer was lost is a live workflow, and a blind re-invoke mints a second one; a firing whose answer was lost may have moved the workflow, and a blind re-fire moves it again. The caller reads first — [Read Workflow]'s set-valued query for a start, its instance query for the rest.

### Retention asymmetry

```
Retention asymmetry 1: The composition MUST read an aged entry naming no firing event as lawful destruction.
Retention asymmetry 2: The composition MUST read a purged gate binding's spending through the binding's marks.
```

Term purged gate binding: a gate binding whose opening event the record read answers Purged.

WHY:
State Machine keeps its history and Approval Step its steps for life; the events that attest them purge at the horizon. So past it a history entry no firing event names is destruction, never an unrecorded firing — the sweep does not re-emit for it and the consumption rule does not read it — and whether a bound step's approval was spent is read from the marks alone (Composition state 16).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are its five actions — [Start Workflow], [Open Gate], [Decide Gate], [Fire Transition] and [Read Workflow]; the [Gate Spec] a workflow freezes at start; the four scopes it defines for its Permissions instance, [Workflows Start], [Workflows Open Gate], [Workflows Fire] and [Workflows Read]; and the refusals it names — [Permission Denied], [Recording Failure], [Not Guarded], [Gate Not Available], [Already Open], [Gate Not Open] and [Gate Not Cleared]. The workflow store and the three indexes are declared in Composition state and carded nowhere: they are the composition's records, not concepts a caller names. The deployment settings keep their wire spellings in configuration — `audit_trail_retention_policy`, `workflow_completion_bound`, `compensation_window`, `reconciliation_cadence`, `record_write_latency`, `application_actor_ref`, `application_credential`, `instance_serialization`, `clock_offset_allowance`, `binding_flag_durability`, `intent_candidates_cap` — and the stores their own in an implementation, `workflow_store`, `gate_binding`, `gate_to_assignment`, `transition_to_event`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the sweep; the firing leg; the cascade leg; the opening leg; the decision leg; the moot cascade; the consumption rule; a rebuild; a deployment; a deployment parsing a gate subject; an auditor; a caller; an invocation; a holder; an instance action; a found action; a validated start; a permitted start; an admitted start; an instantiated start; a landed start; an unlanded start; a validated opening; a guarded opening; an admitted opening; a submitted opening; a staffed opening; a landed opening; a bound decision; an admitted decision; a decided decision; a landed decision; a validated firing; a cleared firing; an admitted firing; a fired firing; a landed firing; a validated read; a permitted read.

Term records: the workflow records and the three indexes' entries; the intents, outcomes, moot records and recovery intents the composition records through the audit write — each an Event Log event carrying one action reference of the workflow namespace; and the instances, history entries, steps and assignments it writes through the constituents.

Term record verbs: accept, act, alert, answer, attest, bound, call, carry, change, classify, clear, commit, compare, complete, compose, count, decide, declare, define, derive, disclose, duplicate, encode, enumerate, evaluate, examine, expose, find, gate, hold, inherit, inject, inspect, join, judge, key, leave, make, match, name, normalize, open, page, pair, pass, persist, pre-check, proceed, provision, re-bind, re-emit, re-invoke, reach, read, rebuild, record, release, remove, resolve, retain, retry, run, select, serve, set, share, span, start, store, supply, take, write.

Term value sets: decisions, reason-bearing decisions, stage, open state, decision outcome, moot kind and leg are declared where the section that owns each declares it.

Term bounds: completion bound (workflow_completion_bound), record write latency (record_write_latency), intent candidates cap (intent_candidates_cap), guarded transition cap, id widths, clock offset allowance (clock_offset_allowance), compensation window (compensation_window), audit horizon (audit_trail_retention_policy).

Term cadences: reconciliation cadence (reconciliation_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.62 (2026-09-24).

Term terms: composition, constituents, transitive atoms, workflow machine, log read, record read, audit write, verification, machine write, step write, assignment write, workflow namespace, workflow store, workflow record, instance id, declaration reference, gate key, gate binding index, gate binding, bound step, consumed mark, mooted mark, marks, gate-assignment index, transition-event index, live index entry, purged mark, workflow rebuild, binding rebuild, firing rebuild, unfiltered read, assignment history, active assignment read, clock-derived flag, audit retention policy, audit horizon, longest workflow lifetime, completion bound, compensation window, reconciliation cadence, record write latency, liveness sum, service identity, instance exclusion, holder, clock offset allowance, mark durability, intent candidates cap, id widths, seam, now, gate subject, caller reference, actor reference, subject reference, approver reference, parseable credentials, credential, reason, decisions, reason-bearing decisions, capped field, guarded transition count, guarded transition cap, action, intent, outcome, act's minted id, pre-append step, retention step, stage, yielded invocation, human actor, gate handle, open state, decision outcome, new state, workflow views, query, start intent, start event, open intent, opening event, decision intent, decision event, fire intent, firing event, intent event id, intent instant, started instant, submitted instant, decided instant, fired instant, guarded flag, matched transition, to-state, decision's step write, load-bearing call, instant-bearing call, read-side call, call's stage, instance action, validated start, permitted start, admitted start, instantiated start, landed start, unlanded start, validated opening, found action, guarded opening, admitted opening, submitted opening, unassigned opening, staffed opening, landed opening, bound decision, admitted decision, decided decision, landed decision, validated firing, cleared firing, admitted firing, fired firing, landed firing, validated read, permitted read, horizon mark, live approvals, consumption rule, mooting rule, widened horizon, aged entries, aged entry, re-bindable steps, approval guard, spent step, sweep, firing leg, cascade leg, opening leg, decision leg, leg, aged record, planned steps, young intent, recovery intent, intent reference, plan, matching decision intents, candidate count, intent candidates, transient arm, escalation instant, moot cascade, moot plan, moot kind, moot record, moot reason, fired action, quiescent workflows, committed act, settled steps, process proof, settlement record, stored subject, uncounted event, accounted entry, start count, repeatable act, lost answer, purged gate binding.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index classification. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. The section titled Structural-relation invariant templates in `spec-format.md` — the relations. record_action, read_record, verify_record, payload cap, reference length cap, attestation id width, step-2, step-3, step-4, invalid-credential, invalid-request, recording-failure, verified, failed-verification, Retained, Purged, Reverse Index, Failed-Attempt Log, Trusted Timestamping: Audit Trail. instantiate, fire, current, history, read_declaration, instantiated_at, fired_at, guard_satisfied, invalid-declaration, not-known, terminal, invalid-transition, storage-failure, invalid-request: State Machine. submit, approve, reject, withdraw, read, submitted_at, decided_by, withdrawn_by, decided_at, withdrawn_at, approved, rejected_outcome, withdrawn, Pending, Approved, Rejected, Withdrawn, not-pending, unauthorized: Approval Step. assign, recall, active_for, history_for, ok, not-active, already-assigned, Active, Recalled: Assignment. permitted, denied: Permissions. read: Event Log. Binding Registry, Outbox, Definition Registry: forthcoming.

Term composing patterns: [Multi-Party Approval](./multi-party-approval.md); [Compensable Workflow](./compensable-workflow.md); [Idempotent Reservation](./idempotent-reservation.md); [Attributed Permissions Admin](./attributed-permissions-admin.md); [Legal Hold](../atoms/legal-hold.md).

#### Start Workflow

The composition's instantiating action: freeze a declared process map and its [Gate Spec] into one new workflow run under an authorized initiator. Validates the [Gate Spec] against the declaration (every guarded transition named), instantiates the State Machine instance, records the `workflow_started` audit event, and only then writes the workflow record over it. Returns `{instance_id}` or a rejection.

Kind: Operation

#### Open Gate

Opens an approval gate for a guarded transition whose `from_state` is the instance's current state — lazily, on demand, by an actor holding [Workflows Open Gate]. Submits one Approval Step (with the workflow initiator as submitter), assigns it to the named approver's in-tray, binds it via `gate_binding`, and records `gate_opened`. Returns `{step_id, assignment_id}` or a rejection.

Kind: Operation

#### Decide Gate

Wraps the bound gate's Approval Step approve / reject / withdraw for the transition matched from the current state. Structural authorization is Approval Step's own (only the named approver may approve or reject; only the submitter — the initiator — may withdraw), so no redundant workflow-layer permission check is added. Recalls the in-tray assignment and records `gate_decided`.

Kind: Operation

#### Fire Transition

The composition's load-bearing action: advance the workflow through a transition. For an unguarded transition it calls `WorkflowStateMachine.fire` directly; for a guarded one it reads the bound Approval Step's state and asserts `guard_satisfied = true` only when that step is Approved — the caller never supplies the guard. Once the fire has committed it records `transition_fired` and runs the moot-gate cascade — both conditioned on the commit, not on the action returning success.

Kind: Operation

#### Read Workflow

The read-only query returning a composed view over the workflow record, the State Machine current state and transition history (each entry enriched with its Audit Trail `event_id`), and each gate's Approval Step and Assignment status. Gated by [Workflows Read]. The records-alone forensic surface (Invariant 6).

Kind: Operation

#### Gate Spec

The map, frozen at [Start Workflow] and immutable thereafter, from each guarded transition's guard label to the `{approver_ref, scope}` naming the approval that gate requires. Structurally validated at start (every guarded transition has an entry; every entry names a real guard label and carries a non-whitespace approver and scope); whether the named approver is the *correct* authority is a deployment policy question the composition records but does not adjudicate.

Kind:       Field
Field of:   the workflow record
Role:       the per-gate approval specification
Projection: gate_spec

#### Workflows Start

The scope permitting [Start Workflow] — instantiate a new workflow run.

Kind:       Member
Member of:  the workflow scope vocabulary
Role:       Scope
Projection: workflows:start

#### Workflows Open Gate

The scope permitting [Open Gate] — open an approval gate for a guarded transition.

Kind:       Member
Member of:  the workflow scope vocabulary
Role:       Scope
Projection: workflows:open-gate

#### Workflows Fire

The scope permitting [Fire Transition] — advance the workflow through a transition.

Kind:       Member
Member of:  the workflow scope vocabulary
Role:       Scope
Projection: workflows:fire

#### Workflows Read

The scope permitting [Read Workflow] — read workflow records and their composed gate, assignment, and attestation surface.

Kind:       Member
Member of:  the workflow scope vocabulary
Role:       Scope
Projection: workflows:read

#### Permission Denied

The composition's rejection when the acting actor lacks the required workflow scope at the Permissions check that opens [Start Workflow], [Open Gate], [Fire Transition], or [Read Workflow]. (Gate decisions are not permission-gated here — Approval Step's own approver and submitter exclusivity is the enforcement.)

Kind:       Member
Member of:  the workflow rejection
Role:       Rejection
Projection: permission-denied

#### Recording Failure

The composition's uniform rejection for a constituent `storage-failure` or an Audit Trail `record_action` failure surfaced at the composition boundary. Carries its stage — `recording-failure(pre-commit | post-commit)`: pre-commit means nothing committed and the caller retries the whole action; post-commit means the load-bearing write committed and the caller must not re-invoke — the implementation lands the owed record (a bounded gap in Invariant 3), inside `workflow_completion_bound` by the invocation and past it by the restart sweep.

Kind:       Member
Member of:  the workflow rejection
Role:       Rejection
Projection: recording-failure

#### Not Guarded

The [Open Gate] rejection when the matched transition carries no `guard` label — unguarded transitions are fired directly through [Fire Transition] without opening a gate.

Kind:       Member
Member of:  the open-gate rejection
Role:       Rejection
Projection: not-guarded

#### Gate Not Available

The [Open Gate] rejection when the instance is in a terminal state, so no gate can be opened.

Kind:       Member
Member of:  the open-gate rejection
Role:       Rejection
Projection: gate-not-available

#### Already Open

The [Open Gate] rejection when a live gate is already bound for the matched transition (`already-open(pending)`, or `already-open(cleared-unconsumed)` for an `Approved` step neither consumed nor mooted) — resolve it via [Decide Gate], or fire the cleared transition, before opening a replacement. An `Approved`-and-mooted step is not live: the key re-binds.

Kind:       Member
Member of:  the open-gate rejection
Role:       Rejection
Projection: already-open

#### Gate Not Open

The [Decide Gate] rejection when no Approval Step is bound for the matched transition from the current state — call [Open Gate] first.

Kind:       Member
Member of:  the decide-gate rejection
Role:       Rejection
Projection: gate-not-open

#### Gate Not Cleared

The load-bearing [Fire Transition] rejection: a guarded transition whose gate has not been opened, whose bound Approval Step is not in Approved (Pending, Rejected, or Withdrawn), or whose approval is already spent — consumed (its one authorized firing has happened, or has committed with its record still landing) or mooted (the workflow left the gate's `from_state` before the approval was fired, and the cascade recorded it) — cannot fire. The structural refusal that makes the gate unbypassable — there is no surface by which the caller can assert the guard themselves.

Kind:       Member
Member of:  the fire-transition rejection
Role:       Rejection
Projection: gate-not-cleared

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Start Workflow]: #start-workflow
[Open Gate]: #open-gate
[Decide Gate]: #decide-gate
[Fire Transition]: #fire-transition
[Read Workflow]: #read-workflow
[Gate Spec]: #gate-spec
[Workflows Start]: #workflows-start
[Workflows Open Gate]: #workflows-open-gate
[Workflows Fire]: #workflows-fire
[Workflows Read]: #workflows-read
[Permission Denied]: #permission-denied
[Recording Failure]: #recording-failure
[Not Guarded]: #not-guarded
[Gate Not Available]: #gate-not-available
[Already Open]: #already-open
[Gate Not Open]: #gate-not-open
[Gate Not Cleared]: #gate-not-cleared

---

## Standards references

This composition is the structural form of what every multi-actor regulated workflow requires:

- **FDA 21 CFR Part 11 (Electronic Records; Electronic Signatures)** — every transition in a Part 11 electronic records system is an electronic record; guarded transitions driven by approval gates constitute electronic signatures. Part 11 section 11.50 requires signatures be attributable; section 11.70 requires they be linked to records to prevent removal, substitution, or falsification. The composition's Audit Trail substrate (Actor Identity providing cryptographic binding; Tamper Evidence providing the linking) is the structural form of both; a recovery re-emission attests the service identity and carries the human in its payload, so its signature's attribution is read as Check 5.2 reads it. The only-declared-transitions enforcement (Invariant 5) and the approval-gated-transition claim (Invariant 1) are the records-alone proof that section 11.10 system access controls and section 11.70 record integrity requirements were honored.

- **FDA 21 CFR Part 211 (Current Good Manufacturing Practice for Finished Pharmaceuticals)** — batch release requires authorization by a Qualified Person or equivalent designated authority. A State Machine-governed batch lifecycle with a QP approval gate on the release transition is the structural form of the Part 211 batch-release control. The guarded-transition record (history entry with `guard_satisfied: true` and bound Approved Approval Step) is the per-batch control evidence.

- **SOX (Sarbanes-Oxley Act) section 404 (15 U.S.C. (United States Code) section 7262) — Internal control over financial reporting.** Process-control records for financial workflows (journal entry posting, purchase order approval, account reconciliation) must demonstrate that the required control steps occurred in the declared order and that each gate was cleared by an authorized actor. The composition's records-alone process proof (Invariant 6) is the structural form of the SOX section 404 control evidence requirement. Composes with Audit Trail's SOX section 802 retention obligation (7 years).

- **ISO 9001:2015 clause 8.5.1 (Control of production and service provision)** — production and service provision activities must be controlled by documented procedures with controlled transition points. A State Machine instance governing a production process is the documented procedure record section 8.5.1 anticipates; the composition adds the human-gate enforcement and the regulated-audit substrate.

- **BPMN 2.0 (Business Process Model and Notation 2.0 — an international standard for modeling business processes, published by the Object Management Group)** — this composition is the runtime form of a BPMN process diagram with human task gates. BPMN states map to declared State Machine states; BPMN sequence flows map to declared transitions; BPMN human task gates map to the approval-step-gated transitions. The composition enforces the BPMN model's declared process semantics at runtime.

- **ICH E6(R3) GCP (International Council for Harmonisation E6(R3) Good Clinical Practice — the global standard for clinical trial conduct)** — clinical trial lifecycle events (protocol submission, IRB (institutional review board) approval, deviation handling, trial closure) require documented approvals at defined points by named authorities. This composition is the structural form of the GCP-required documented approval trail.

- **ISO 13485:2016 clause 7.3 (Design and development)** — medical device design changes require multi-disciplinary approval (design lead, quality, regulatory affairs, often clinical) at defined process gates. This composition's guarded-transition model is the per-gate enforcement layer; [Multi-Party Approval](./multi-party-approval.md) is the composing enrichment for gates requiring multiple approvers.

It inherits from:

- **The Audit Trail substrate** — SOX section 802, HIPAA (Health Insurance Portability and Accountability Act — US law governing protected health information) section 164.530(j), PCI DSS (Payment Card Industry Data Security Standard) Requirement 10.5, ISO/IEC (International Electrotechnical Commission) 27001:2022 clause A.8.15 (logging) retention and integrity obligations, via the Audit Trail composition's own standards inheritance.
- **Daniel Jackson, *The Essence of Software*** — the composition discipline: State Machine and Approval Step are freestanding atoms with orthogonal concepts; this composition is the wiring that makes them coherent in the regulated-workflow context.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation, 2026-08-30: execute-gated-workflow.tla + 2 twins verified 2026-06-04 over an unbounded consumption arm, Pending-only mooting and a single-writer invocation with no terminus; re-derive over the mooted flag, the horizon-bounded consumption arm, the invocation and the sweep as two processes with the bound as the yield point, and leg (4)'s decision-matched join (2026-08-29-a, 2026-08-30-e)
last gate: 2026-08-30 — third gate, fresh reader, under the frozen rules — 5 foundational corrected in-round, 6 refining and 3 rhetorical routed (9 refining and 2 rhetorical also corrected in-round; 2 of the routed refining already open; the closure check's 1 foundational, 2 refining and 7 consistency items corrected in-round); 2026-08-27 — authentication-precedence gate, fresh reader — 3 foundational pre-existing routed (all since closed), 8 refining/rhetorical routed; Final Critique 9's 1 other foundational (since closed), 13 refining (1 since closed) and 4 rhetorical also routed

open:
- 2026-08-29-a · refining · formal · the model's sweep carries no age bound and no recovery record → extend the model with the bounded sweep behind `workflow_recovery_intended`
- 2026-08-30-e · refining · formal · the model carries no mooted flag, no horizon bound on the consumption arm, no invocation terminus and no decision-matched join for leg (4) → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/execute-gated-workflow.md`.

- **2026-09-24 — Rewritten in GRACE lang v0.62; twenty-eight of thirty open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` (the approval-gated transition, with the consumption and mooting rules), `Reconciliation` (the restart sweep, as four legs), `Scope vocabulary` and `Cascade` (the moot cascade, the family Multi-Party Approval opened) as the surfaces; invariant numbers 1 through 6 and 8 unchanged, Invariant 7 tombstoned to Composes 6; the record checks renumbered by the invariant each tests; the edge cases split into Non-goals and four Edge cases families. Choices the page left open, each decided by a standing rule: one State Machine workflow per run, stated as its own serve rule beside the one State Machine instance (Composes 1 and 17 — Compensable Workflow's shape for the same atom); every constituent write surface reserved to the composition, Permissions read-only (2026-08-26-h, 2026-08-30-b); the marks extraction-pending against Binding Registry, a write-once pairing of a step to the transition that spent it (2026-08-30-d — *A derived index splits at the horizon*); the retention step and the retention-source invalid-request at an outcome read back by the act's minted id and proceeding as landed (2026-08-26-d — *A transcribed rejection arm keeps its payload*); every read-side refusal landed (2026-08-26-b); the audit-completeness count taken from the constituent stores and the start half routed external (2026-08-26-e, 2026-08-30-c); the firing's binding read from its own event (2026-08-26-f); the grant reconstruction pinned to the outcome's payload instant (2026-08-26-g); a lost answer met by reading before re-invoking, and at-most-once left to the caller's key as it is for fire (2026-08-26-i — *make all things mean one thing*); approval staleness a non-goal (2026-08-26-k); the recovery intent renamed with underscores like every other kind here (2026-08-30-a). *Over:* the prose's step lists, a serialization rule titled for one action, and a Standards line claiming the substrate *satisfies* Part 11 where it is the structural form. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.
- **2026-08-30 — An approval is mooted on the record when the workflow leaves its state, the consumption arm stops at the horizon, the sweep's decision leg joins on the outcome, and the maps are read only at the shape their contract covers.** *Chose:* the moot-gate plan and cascade extended to Approved-and-unconsumed gates — one `moot_gate_recalled` with `moot_kind = approved-unconsumed` and a durable mooted flag, the step left standing as a decision that authorized nothing, [Open Gate] re-binding over it and [Fire Transition] refusing it; the consumption rule's history arm bounded to firings inside the audit horizon widened by `clock_offset_allowance`, with the consumed and mooted flags carried by every deployment under `binding_flag_durability` rather than offered as a fallback; sweep leg (4) joining a terminal step only to the `gate_decision_intended` whose decision, actor and stamp match the step's own, candidates on a tie and a surfaced finding on zero, never a re-emission; [Read Workflow]'s set-valued queries and the sweep's instance enumeration anchored in the `workflow_started` and `gate_opened` events with keyed rebuild-on-miss per instance; `gate_to_assignment` rebuilt from `ApprovalStep.read({})` and `Assignment.history_for(task_ref)` at every retention state; `recording-failure(pre-commit | post-commit)` and `already-open(pending | cleared-unconsumed)` on the signatures; the invocation yielding every owed write at `workflow_completion_bound` under a whole-invocation hold, the sweep re-reading its pre-check under the same serialization; the liveness inequality written out with `record_write_latency`; `intent_candidates_cap` sizing the recovery envelope; and, from the closure check, the firing's own consumed step excluded from its moot-gate plan, `instance_serialization` declared as the deployment's capability with lease-at-the-bound semantics and the re-take-before-pre-check rule, sweep leg (2) covering a withdraw that committed before its record, and leg (4) owning the recall [Decide Gate] could not land inside its bound. *Over:* an approval that survived a departure and cleared a return-path firing with no fresh decision; an unbounded history arm that read every purged firing as unrecorded and bricked the key; a leg that landed `gate_decided` for whichever intent named the step; queries that enumerated a derived index with no miss to observe; a payload-sourced rebuild declared *not rebuildable* on a capability gap the constituent does not have; a bare token on both sides of the commit; *retry until it lands* beside a sweep that starts at the bound; *cadence no longer than the window*; a plan that mooted the approval its own firing spent; a critical section attributed to nobody. *Because:* the cascade exists to keep a stale human decision from clearing a transition in a context the approver never saw, and Pending was the wrong place to stop; a horizon that destroys the event must not also destroy the key; a decision's outcome is on the step and the join must read it; an index read at a shape its contract does not cover puts the records-alone proof on a cache; a constituent's declared surface outranks the composition's memory of it; a caller who cannot tell pre-commit from post-commit re-fires a committed transition; and a section no Configuration names is a section whose lease nobody bounds (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen — with §*Intents pair with outcomes*, §*A derived index is trustworthy only where a miss is observable* and §*A derived index splits at the horizon*).
- **2026-08-26 — Every audit record emitted outside the original human invocation is composition-attributed.** *Chose:* retries, recovery emissions and cascade recalls attest under `application_actor_ref` / `application_credential`, with the human actor in the event `data` and `recovery = true`; the retry loop runs only on the substrate's transient failure, invalid-request foreclosed by budget-derived caps and minted-id width bounds. *Over:* re-presenting the human's credential on retry, or looping on every rejection. *Because:* a human credential is not available to a recovery path and a deterministic rejection retried forever is a stall, not a recovery; the discipline is shared with Multi-Party Approval so the two recovery vocabularies stay one.
- **2026-08-29 — The restart sweep is bounded at both edges, writes a recovery record before it commits, and pairs a firing to its intent on the shared reading.** *Chose:* `workflow_completion_bound` below and the audit horizon above for every leg, with the sweep holding the per-instance serialization; a `workflow.recovery_intended` record before any leg that commits constituent state; leg (1) joined on `fired_at = intended_at` plus actor rather than "the latest unmatched intent", with `intent_event_candidates` and the union of plans where more than one matches; `compensation_window` and `reconciliation_cadence` declared. *Over:* a sweep on "a fixed cadence" whose pre-check was its only guard, and a definite-article join. *Because:* the pre-check cannot see an invocation that has not written yet, so a leg fired inside the completion bound lands a second outcome for one commit; a sweep that withdraws steps and recalls assignments without a record of its own is indistinguishable from a direct call; and "the latest" chooses where the records may not (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*).
- **2026-08-27 — Committed-but-unrecorded work is re-derived from the constituent stores, never remembered by the process.** *Chose:* the consumption test's second arm reads State Machine history, the moot-gate cascade is conditioned on the fire's commit, and a four-leg restart sweep diffs the constituent stores against the trail to land every owed record; the in-flight pending set is a cache classified extraction-pending against a forthcoming Outbox atom. *Over:* retry-until-lands obligations held in process memory, and a cascade conditioned on the action returning success. *Because:* a crash between a commit and its record lost the obligation entirely — one approval could fire twice and mooted gates stayed Pending with live Assignments — and an obligation that a records-alone auditor cannot re-derive is not one the pattern can claim.
- **2026-08-27 — Caller authentication is the composition's own obligation, before any constituent call.** *Chose:* an intent record whose substrate attestation verifies the credential before the Approval Step decision commits. *Over:* assuming an authenticated-caller binding the spec never declared, which let a parseable-garbage credential drive a committed Approved step. *Because:* Permissions assigns the actor-to-caller binding to "the composing system", and this composition is that system.

NOTE: End of Execute Gated Workflow.
