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

The Audit Trail substrate — the shared regulated-audit layer every act is recorded on — attributes every transition and gate decision to the acting actor's identity, governs retention, and seals the record tamper-evident, so every act is provable.

Together these produce what no constituent provides alone: the process followed only its declared path, every gate was cleared by a real human decision (not a bare assertion), and the full history is attributed, sealed, and reconstructible.

This composition is the structural form of FDA (US Food and Drug Administration) 21 CFR (Code of Federal Regulations) Part 11 electronic records workflows, SOX (Sarbanes-Oxley Act — US law on corporate financial reporting and records integrity) section 404 process-control records, ISO (International Organization for Standardization) 9001 clause 8.5.1 production-process documentation, and any regulated domain whose compliant execution must be provable.

---

## Intent

Multi-step regulated processes share a common structure: an entity moves through a declared sequence of states, some transitions require explicit human approval before they may fire, every transition must be attributed and tamper-evidenced, and the entire history must be provable. A pharmaceutical batch-release process requires declared quality-control steps with a qualified-person approval gate before release. A financial journal-entry promotion requires controller sign-off at the booking gate. A clinical-trial protocol change requires investigator and sponsor approvals before the change may proceed. A software change request requires a review approval before it can be merged to production. In every case the structure is the same: a declared state machine governing the process instance, a set of gates (transitions that may not fire until a named approver has actually decided), an authorization surface governing who may advance the process at all, a work-tracking surface that keeps each pending gate in the right person's in-tray, and a regulated-audit substrate that makes every advancement and every gate decision attributed, sealed, and retention-governed.

The constituent atoms address each of these concepts freestanding. [State Machine](../atoms/state-machine.md) enforces declared-transition discipline — only declared transitions fire, exactly one current state at all times, the full transition history is append-only, total-ordered, and replay-deterministic. [Approval Step](../atoms/approval-step.md) is the per-gate primitive — one named approver, one subject, one scope, one outcome (Pending → Approved | Rejected | Withdrawn), with approver exclusivity enforced by its Invariant 4. [Permissions](../atoms/permissions.md) governs standing authorization — who holds the `workflows:start`, `workflows:open-gate`, `workflows:fire`, and `workflows:read` grants that permit process-level actions. [Assignment](../atoms/assignment.md) binds each open gate to the named approver's in-tray and recalls the binding when the gate is decided. [Audit Trail](./audit-trail.md) is the regulated-audit substrate that supplies Event Log, Actor Identity, Retention Window, and Tamper Evidence as a single composition.

What the constituent atoms cannot answer alone is the central regulated question: *did this guarded transition fire only after its named approval was genuinely recorded?* State Machine's guard model (State Machine Invariant 8 — guard gating without evaluation) deliberately does not evaluate guard predicates; it trusts a caller-asserted `guard_satisfied = true` and records the assertion. Its Edge cases name this as a calling-system obligation and explicitly flag approval-gate evaluation as the concept this composition re-converges. This composition is where that re-convergence happens: it binds each guarded transition to an Approval Step (`gate_binding`), reads the bound step's state before any `fire` call, and asserts `guard_satisfied = true` to `WorkflowStateMachine.fire` only when the bound step is in Approved. The caller of this composition never supplies `guard_satisfied` directly for a guarded transition; the composition derives it from the gate's actual approval record.

This is not a new primitive. The four constituent atoms and the Audit Trail substrate are unchanged. The composition is the wiring that makes their concepts coherent — one consolidated multi-actor regulated-workflow surface rather than five parallel record sets the auditor must correlate by hand.

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

Term composition: this pattern's wiring of [State Machine](../atoms/state-machine.md), [Approval Step](../atoms/approval-step.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md) and [Audit Trail](./audit-trail.md) — the gated workflow, the gate, the moot cascade, the read and the sweep.

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

Adjacent, **not** constituents: [Multi-Party Approval](./multi-party-approval.md), the composing enrichment for a gate that needs several approvers (Non-goal 1); [Compensable Workflow](./compensable-workflow.md), for a process whose steps have effects to undo; [Legal Hold](../atoms/legal-hold.md), which suspends purge over the workflow's events through the substrate.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the workflow records, the gate binding index, the gate-assignment index AND the transition-event index.
Composition state 2: A workflow record MUST carry the instance id, the subject reference, the initiator reference, the declaration reference, the [Gate Spec] AND the started instant.
Composition state 3: The composition MUST NOT change a workflow record.
Composition state 4: The composition MUST key the gate binding index by gate key.
Composition state 5: A gate binding MUST carry the bound step, the consumed mark AND the mooted mark.
Composition state 6: The composition MUST NOT remove a gate binding.
Composition state 7: A start event MUST carry the whole workflow record.
Composition state 8: An opening event MUST carry the gate key, the step id, the assignment id, the approver reference, the scope AND the submitted instant.
Composition state 9: The composition MUST NOT rebuild an index from an intent.
Composition state 10: The composition MUST classify a live index entry as a derived index.
Composition state 11: The composition MUST rebuild the workflow records PER the workflow rebuild.
Composition state 12: The composition MUST rebuild the gate binding index PER the binding rebuild.
Composition state 13: The composition MUST rebuild the gate-assignment index from Approval Step's unfiltered read AND each step's assignment history.
Composition state 14: The composition MUST rebuild the transition-event index PER the firing rebuild.
Composition state 15: A rebuild MUST retain EVERY index entry the rebuild does not reproduce.
Composition state 16: The composition MUST classify a purged mark as truth-bearing.
Composition state 17: The composition MUST classify the marks as extraction-pending against Binding Registry.
Composition state 21: The composition MUST classify a purged index entry as extraction-pending against Erasure Tombstone.
NOTE: watch the unnamed purged half (Composition state 21).
Deleted: Composition state 18. Execution Contract Database 3 and Execution Contract Database 4 own it.
Composition state 19: The composition MUST NOT store a clock-derived flag.
Composition state 20: The composition MUST NOT duplicate a constituent's records.
```

Term workflow records: the set of workflow records — `workflow_store` in an implementation.

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

Term purged index entry: a workflow record, gate binding or transition-event entry whose source event the record read answers Purged, a gate binding's marks aside.

Term workflow rebuild: the log read kept to the start events, each recorded as its payload's workflow record — the initiator from the payload, never from the event's actor, since a recovery re-emission is the service identity's.

Term binding rebuild: the log read kept to the opening events, the latest per gate key in Event Log order naming the bound step; the consumed marks from the firing events' step ids, and the mooted marks from the moot records'.

Term firing rebuild: the log read kept to the firing events, each event id recorded against its payload's transition id.

Term unfiltered read: Approval Step's read on an empty query — every step in the database, which Approval Step never removes.

Term assignment history: Assignment's history_for on a step id as the task.

Term clock-derived flag: a stored eligible, expired or overdue value.

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
Deleted: Capability requirement 10. Execution Contract Database 2 owns it.
Deleted: Capability requirement 11. Execution Contract Database 2 owns it: an action's reads of a workflow and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 12. Execution Contract Database 2 owns it: an action's reads of a workflow and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 13. Execution Contract Database 2 owns it: an action's reads of a workflow and the writes they decide are one transaction, and the composition names no exclusion to lease.
Deleted: Capability requirement 14. Execution Contract Database 2 owns it: an action's reads of a workflow and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 15. Execution Contract Database 2 owns it: an action's reads of a workflow and the writes they decide are one transaction, and the composition names no exclusion for a host to lack.
Capability requirement 16: A deployment MUST set the clock offset allowance.
Deleted: Capability requirement 17. Execution Contract Database 3 and Execution Contract Database 4 own it.
Capability requirement 18: A deployment MUST set the intent candidates cap.
Capability requirement 19: A deployment MUST declare the id widths.
Capability requirement 20: The host MUST inject now at the seam once per invocation.
Capability requirement 21: The wired Audit Trail instance MUST expose the log read.
Capability requirement 22: The composition MUST pass the invocation's now to EVERY constituent call accepting an instant.
Capability requirement 23: A deployment parsing a gate subject MUST encode the subject reference injectively.
Capability requirement 24: The deployment MUST supply the database PER Execution Contract Database 1 through 4 and Execution Contract Query 1 through 4.
```

Term audit retention policy: the retention policy configured on the composition's single Audit Trail instance — `audit_trail_retention_policy`: a seven-year SOX policy, a Part 11 predicate-rule policy, a HIPAA six-year policy, an ICH E6 trial-master-file policy.

Term audit horizon: the audit retention policy's horizon.

Term longest workflow lifetime: the longest a workflow run the deployment admits stays live — a business fact, for a trial master file or a change-control record its own expected duration.

Term completion bound: the longest a state-changing invocation may run, from its intent to its outcome and, for a firing, its moot cascade — `workflow_completion_bound`.

Term compensation window: the duration within which an owed record or cascade must land or be escalated — `compensation_window`.

Term reconciliation cadence: the interval between the sweep's runs — `reconciliation_cadence`.

Term record write latency: the deployment's disclosed bound on one audit write landing — `record_write_latency`.

Term liveness sum: `((completion bound + reconciliation cadence) + record write latency)`.

Term service identity: the composition's registered actor reference and credential — `application_actor_ref` and `application_credential` — under which the composition attests every write no present human's invocation owns.

Term clock offset allowance: the declared bound on the divergence between the composition's seam clock and the substrate's — `clock_offset_allowance`.

Term intent candidates cap: the most intent candidates a recovery re-emission may name — `intent_candidates_cap`.

Term id widths: the widest instance id, step id, assignment id, transition id and event id the constituents mint — the substrate's own attestation id width move, so an id-carrying payload is sized before any id exists.

Term seam: the composition's input and output boundary — the one place the host reads the clock, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term gate subject: the workflow's subject reference, a colon and the action — the step's subject, never parsed back by the composition.

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

### Audit arm

```
Audit arm 1: IF Audit Trail answers invalid-credential at an intent THEN the action MUST answer invalid-credential.
Audit arm 2: IF Audit Trail answers recording-failure at an intent THEN the action MUST answer recording-failure carrying pre-commit.
Audit arm 3: IF Audit Trail answers invalid-request carrying a step below step-3 at an intent THEN the action MUST answer invalid-request.
Audit arm 4: The composition MUST NOT retry an invalid-request answer.
Audit arm 5: The deployment MUST alert on EVERY invalid-request from the audit write as a deployment fault.
Deleted: Audit arm 6. Execution Contract Database 1 owns it.
Audit arm 7: IF Audit Trail answers invalid-request(step-4) at an outcome THEN the invocation MUST read the outcome back.
Audit arm 8: A read-back MUST match the outcome carrying the act's minted id.
Audit arm 9: IF the read-back finds the outcome THEN the invocation MUST proceed as landed.
Deleted: Audit arm 10. Execution Contract Database 2 owns it.
Audit arm 11: IF Audit Trail answers recording-failure at an outcome THEN the action MUST answer recording-failure carrying post-commit.
NOTE: watch the retention step's recording failure (Audit arm 11).
Deleted: Audit arm 12. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an outcome.
Audit arm 13: A caller MUST read recording-failure carrying pre-commit as a committed nothing.
Audit arm 14: A caller MUST NOT re-invoke an instance action on recording-failure carrying post-commit.
Audit arm 15: IF [Start Workflow] answers recording-failure carrying post-commit THEN the caller MAY re-invoke [Start Workflow].
Audit arm 16: IF Audit Trail answers invalid-request carrying a step above step-2 at an intent THEN the action MUST answer invalid-request AND MUST NOT write an outcome for the standing intent.
Audit arm 17: IF Audit Trail answers invalid-request carrying a step below step-4 at an outcome THEN the action MUST answer recording-failure carrying post-commit.
```

Term intent: a start intent, an open intent, a decision intent or a fire intent — the audit write an action makes before its load-bearing call, the one that verifies the caller's credential.

Term outcome: a start event, an opening event, a decision event or a firing event — the audit write an action owes after its load-bearing call.

Term act's minted id: the instance id for a start event, the step id for an opening event, the step id with the decision for a decision event, the transition id for a firing event.

Term pre-append step: a recording-failure step naming a step before the substrate's append — step-2 or step-3; the event is not in the log.

Term retention step: the step naming the substrate's retention placement on an invalid-request — step-4; the event is appended and attested.

Term invalid-request step: step-1 | step-2 | step-3 | step-4 — the step of Audit Trail's record action that landed the refusal; step-4 is the retention step, and at step-1 through step-3 the event is not in the log.

Term stage: pre-commit | post-commit — where a recording-failure sat relative to the action's load-bearing write: the instantiate, the submit, the decision or the fire.

Term human actor: the caller whose act an outcome records, carried in a recovery re-emission's payload.

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

Term query: a filter on instance id, subject reference, initiator reference, or a range on the started instant in the `{after, before}` form, whose after is its start and whose before is its end. A range carrying its after alone holds its after and every later instant, and one carrying its before alone holds its before and every earlier instant, which Execution Contract Query 1 would read as malformed.

```
Action wiring 1: A validated start MUST call the permission check with the actor reference AND [Workflows Start].
Action wiring 2: IF the permission check answers denied THEN the action MUST answer permission-denied.
Action wiring 3: A permitted start MUST record the start intent carrying the subject reference, the declaration reference, the [Gate Spec] AND now as the intent instant.
Action wiring 4: An intent MUST NOT carry an id the intent's act mints.
Action wiring 5: An admitted start MUST call instantiate with the declaration, the actor reference, the subject reference and the guard labels as metadata, AND now as the instantiated instant.
Action wiring 6: IF instantiate answers invalid-declaration THEN [Start Workflow] MUST answer invalid-declaration.
Action wiring 7: IF a load-bearing call answers storage-failure THEN the action MUST answer recording-failure carrying pre-commit (Execution Contract Constituent failure 1).
Action wiring 8: IF an instant-bearing call answers invalid-request THEN the action MUST answer recording-failure carrying pre-commit.
Action wiring 9: An instantiated start MUST record the start event carrying the intent event id, the whole workflow record AND the reason.
Action wiring 10: An unlanded start MUST leave the instance quarantined for database maintenance.
Action wiring 11: A landed start MUST write the workflow record.
Action wiring 12: A landed start MUST answer the instance id.
Action wiring 13: The composition MUST write an index entry ONLY AFTER the event the entry derives from lands.
Action wiring 14: A failed index write MUST NOT change an action's answer.
Action wiring 15: A validated opening MUST call the permission check with the actor reference AND [Workflows Open Gate].
Action wiring 16: An instance action MUST NOT answer not-known BEFORE rebuilding the instance's workflow record.
Action wiring 17: IF the workflow records carry no record for the instance id THEN the instance action MUST answer not-known.
Deleted: Action wiring 18. Execution Contract Database 2 owns it.
Action wiring 19: A found action MUST read the workflow machine's current state AND declaration.
Action wiring 20: IF a read-side call refuses THEN the action MUST answer recording-failure carrying the call's stage.
Action wiring 21: The deployment MUST alert on EVERY read-side refusal as an index anomaly.
Action wiring 74: An instance action MUST NOT read a gate key as carrying no gate binding BEFORE rebuilding the gate key's gate binding.
NOTE: watch the miss read before its rebuild (Action wiring 74).
Action wiring 22: IF the current state IS IN the declaration's terminal states THEN [Open Gate] MUST answer gate-not-available.
Action wiring 23: IF no declared transition leaves the current state under the action THEN the action MUST answer invalid-transition.
Action wiring 24: IF the matched transition carries no guard label THEN [Open Gate] MUST answer not-guarded.
Action wiring 25: IF the gate key's bound step EQUALS Pending THEN [Open Gate] MUST answer already-open carrying pending.
Action wiring 26: IF the gate key's bound step IS IN the live approvals THEN [Open Gate] MUST answer already-open carrying cleared-unconsumed.
Action wiring 27: A guarded opening MUST record the open intent carrying the gate key, the guard label, the approver reference, the scope AND now as the intent instant.
Action wiring 28: An admitted opening MUST call submit with the gate subject, the entry's approver reference, the workflow's initiator reference as the submitter, the entry's scope AND now as the submitted instant.
Action wiring 29: A submitted opening MUST call assign with the step id as the task AND the entry's approver reference as the assignee.
Deleted: Action wiring 30. Execution Contract Database 1 owns it.
Deleted: Action wiring 31. Execution Contract Database 1 owns it.
Deleted: Action wiring 32. Execution Contract Database 1 owns it.
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
Deleted: Action wiring 43. Execution Contract Database 1 owns it.
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
Action wiring 67: A permitted read MUST resolve an instance id query through the workflow records with a rebuild on a miss.
Action wiring 68: A permitted read MUST resolve a set-valued query from the start events.
Action wiring 69: A permitted read MUST enumerate a workflow's gates from the workflow's opening events.
Action wiring 70: IF a set-valued query's range reaches a purged start event THEN the workflow views MUST carry the horizon mark.
Action wiring 71: A permitted read MUST answer the workflow views.
Action wiring 72: [Read Workflow] MUST NOT record an audit event.
Action wiring 73: IF the query is malformed THEN [Read Workflow] MUST answer invalid-query.
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

Term found action: an instance action whose permission check, where it carries one, answered permitted and whose instance id the workflow records resolve.

Term guarded opening: a found [Open Gate] whose matched transition carries a guard label and whose gate key's bound step is absent or IS IN the re-bindable steps.

Term admitted opening: a guarded opening whose open intent landed.

Term submitted opening: an admitted opening whose submit answered a step id.

Term staffed opening: a submitted opening whose assign answered.

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

<details markdown="block">
<summary>WHY</summary>

*Principle.* A regulated workflow must make it provable that the process moved only through declared transitions and that every guarded one fired only after its named approval was genuinely recorded — attributed, sealed and retained.

*Likely objection.* State Machine already accepts a caller-asserted guard. Why not let the caller assert it, or trust the caller's word?

*Mechanism.* State Machine deliberately left guard evaluation out: guards recur as approvals, thresholds, quorums and external conditions, each with its own lifecycle, and the atom absorbs none. For approval guards this composition is the evaluation layer: it binds each guarded transition to an Approval Step and, at the fire, reads the bound step's own state; the caller supplies no guard for a guarded transition (Wiring decision 1 and 2). Guards of any other kind stay the caller's or a composing rules engine's (Wiring decision 8).

*Result.* The process moved only through declared transitions; each guarded transition cleared its named approval by the named approver; every firing and decision is attributed, sealed and retained. No transition fires on a bare assertion.

</details>

### Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Reconciliation 2: The sweep MUST run every reconciliation cadence.
Reconciliation 3: The sweep MUST enumerate the workflows from the start events.
Deleted: Reconciliation 4. Execution Contract Database 1 owns it.
Reconciliation 5: The sweep MUST NOT examine an aged record.
Deleted: Reconciliation 6. Execution Contract Database 2 owns it.
Deleted: Reconciliation 7. Execution Contract Database 2 owns it: the sweep's reads of a workflow and the writes they decide are one transaction, and the composition names no exclusion for another holder to hold.
Reconciliation 8: The sweep MUST NOT commit constituent state BEFORE the sweep's recovery intent for the closure lands.
Reconciliation 9: A recovery intent MUST carry the instance id, the leg, the intent reference AND the plan.
Reconciliation 10: The sweep MUST attest EVERY write the sweep makes under the service identity carrying the recovery flag AND the human actor.
Reconciliation 11: IF a history entry's transition id no firing event names THEN the firing leg MUST re-emit the firing event from the entry.
Reconciliation 12: The firing leg MUST pair a re-emitted firing event to the unmatched fire intents on the entry's gate key whose intent instant EQUALS the entry's fired instant AND whose actor EQUALS the entry's actor.
Reconciliation 13: The firing leg MUST set the consumed mark of a re-emitted guarded firing.
Reconciliation 14: IF a committed firing's moot plan names a step no moot record names THEN the cascade leg MUST run the moot cascade's owed calls for the step.
Reconciliation 15: IF a Pending step no opening event names pairs to an open intent THEN the opening leg MUST record the step's opening event.
Reconciliation 16: The opening leg MUST pair a Pending step to the unmatched open intents whose intent instant EQUALS the step's submitted instant AND whose approver reference AND scope EQUAL the step's.
Reconciliation 17: IF a Pending step no opening event names pairs to no open intent THEN the sweep MUST open an out-of-band finding for the step.
Reconciliation 18: IF a terminal step an opening event names carries no decision event AND no moot record THEN the decision leg MUST pair the step to the matching decision intents.
Reconciliation 19: IF one decision intent matches THEN the decision leg MUST record the step's decision event.
Reconciliation 20: IF no decision intent matches THEN the decision leg MUST NOT record a decision event.
Reconciliation 21: IF no decision intent matches AND the step IS IN the planned steps THEN the sweep MUST leave the step to the cascade leg.
Reconciliation 22: IF no decision intent matches AND the step IS NOT IN the planned steps THEN the sweep MUST open an out-of-band finding for the step.
Deleted: Reconciliation 23. Execution Contract Database 1 owns it.
Reconciliation 24: IF the candidate count EXCEEDS one THEN the re-emitted record MUST carry the intent candidates.
Reconciliation 25: IF the firing leg's candidate count EXCEEDS one THEN the cascade leg MUST run over the union of the candidates' moot plans.
Reconciliation 26: IF the candidate count EXCEEDS the intent candidates cap THEN the sweep MUST open an unresolved finding for the record.
Reconciliation 27: The sweep MUST NOT re-emit a start event.
Reconciliation 28: The sweep MUST retry ONLY a transient arm.
Reconciliation 29: IF an owed record's escalation instant PRECEDES the sweep's now THEN the sweep MUST open an unresolved finding for the record.
Reconciliation 30: IF Audit Trail answers invalid-credential to the service identity THEN the deployment MUST page on the answer as a service credential fault.
```

Term sweep: the reconciliation the composition runs outside every invocation, on the cadence — four legs diffing the constituent records against the trail.

Term firing leg: the sweep's leg landing a committed firing's owed firing event.

Term cascade leg: the sweep's leg landing a committed firing's owed moot cascade.

Term opening leg: the sweep's leg completing a committed opening.

Term decision leg: the sweep's leg landing a committed decision's owed event and recall.

Term leg: firing | cascade | opening | decision.

Term aged record: a record whose instant plus the audit horizon plus the clock offset allowance PRECEDES the sweep's now.

Term planned steps: the steps a committed firing's moot plan names.

Term recovery intent: the workflow_recovery_intended event (2026-08-30-a).

Term intent reference: the intent event id where one intent pairs, or the intent candidates.

Term plan: the owed calls the sweep is about to make for the closure.

Term matching decision intents: the unmatched decision intents naming the step whose decision matches the step's terminal state, whose actor equals the step's decider, and whose intent instant equals the step's decided instant.

Term candidate count: how many intents a leg pairs to one owed record.

Term intent candidates: the paired intents where more than one pairs on the clock's resolution — intent_event_candidates.

Term transient arm: a recording-failure at a pre-append step; a storage-failure on withdraw or recall; a constituent's temporal invalid-request, cured by a later reading.

Term escalation instant: an owed record's commit instant plus the compensation window.

### Scope vocabulary

```
Scope vocabulary 1: The composition MUST define workflows start, workflows open gate, workflows fire AND workflows read for the Permissions instance.
Scope vocabulary 2: The composition MUST NOT gate [Decide Gate] on a Permissions scope.
```

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
Deleted: Cascade 12. Execution Contract Database 1 owns it: a cascade call's storage failure fails the whole firing, so no invocation retries a cascade call.
```

Term moot cascade: the secondary calls a committed firing owes the gates it left behind.

Term moot plan: the gate keys of the instance other than the firing's own, whose from-state differs from the to-state and whose bound step is Pending or a live approval — enumerated from the instance's opening events, the latest per gate key, each key resolved through the keyed binding lookup with a rebuild on a miss — each carrying its moot kind.

Term moot kind: pending-withdrawn | approved-unconsumed.

Term moot record: the moot_gate_recalled event.

Term moot reason: "Gate moot: workflow left the gate's from_state by firing a different transition".

Term fired action: the action of the firing that mooted the gate, beside the mooted gate's own.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent, and each needs two or more working together. The relations they rest on, per the section titled Structural-relation invariant templates in `spec-format.md`: a workflow has **zero or more** gate bindings, one current binding per gate key, the key's full history in its opening events; each bound step has **exactly one** assignment, mandatory at a landed opening; each firing has **exactly one** firing event at quiescence; each workflow has exactly one workflow record. A lost index entry is a rebuild trigger, never a relation violation — the relations hold in the events.

- **Invariant 1 — Approval-gated transition, one firing per approval.**
  ```
  Invariant 1.1: EVERY guarded history entry MUST carry a firing event naming a step the entry's [Gate Spec] approver approved.
  Invariant 1.2: Two guarded firing events MUST NOT carry one step id.
  Invariant 1.3: A guarded firing event MUST NOT name a step a moot record names earlier in the Event Log sequence.
  ```
- **Invariant 2 — Permission-gated advancement.**
  ```
  Invariant 2.1: [Start Workflow] MUST NOT commit for an actor reference the permission check denied.
  Invariant 2.2: [Open Gate] MUST NOT commit for an actor reference the permission check denied.
  Invariant 2.3: [Fire Transition] MUST NOT commit for an actor reference the permission check denied.
  ```
- **Invariant 3 — Attributed and sealed history.**
  ```
  Invariant 3.1: IF a workflow IS IN the quiescent workflows THEN EVERY committed act on the workflow MUST carry EXACTLY ONE outcome.
  Invariant 3.2: EVERY moot cascade entry on a quiescent workflow MUST carry EXACTLY ONE moot record.
  Invariant 3.3: EVERY outcome MUST name a workflow the workflow records carry.
  ```
  Term quiescent workflows: the workflows with no invocation in flight and no record owed past its invocation.

  Term committed act: a machine history entry, or a step's submission or decision through the composition.

- **Invariant 4 — Gate assignment coverage.**
  ```
  Invariant 4.1: IF a gate's bound step EQUALS Pending AND the workflow IS IN the quiescent workflows THEN the step MUST carry EXACTLY ONE Active assignment.
  Invariant 4.2: IF a gate's bound step IS IN the settled steps AND the workflow IS IN the quiescent workflows THEN the step MUST carry no Active assignment.
  ```
  Term settled steps: the steps in a terminal state, and the steps a moot record names.

- **Invariant 5 — Only declared transitions, replay-deterministic.**
  ```
  Invariant 5.1: The composition MUST NOT write the workflow machine's history outside fire.
  Invariant 5.2: EVERY history entry MUST name a declared transition.
  ```
- **Invariant 6 — Provable process proof, within the audit horizon.**
  ```
  Invariant 6.1: EVERY workflow's process proof MUST resolve provably.
  ```
  Term process proof: that the process moved only through declared transitions; that each guarded entry's firing event names a step Approved under the [Gate Spec] entry — the binding current at the firing, which a later re-bind may have repointed; that the approving actor matched the entry's approver; that the firing actor held [Workflows Fire]; and that the history is attributed and sealed.

- **Invariant 8 — Authentication precedes commitment.**
  ```
  Invariant 8.1: The composition MUST NOT call instantiate BEFORE Audit Trail validates the caller's credential at the start intent.
  Invariant 8.2: The composition MUST NOT call submit BEFORE Audit Trail validates the caller's credential at the open intent.
  Invariant 8.3: The composition MUST NOT call a decision's step write BEFORE Audit Trail validates the caller's credential at the decision intent.
  Invariant 8.4: The composition MUST NOT call fire BEFORE Audit Trail validates the caller's credential at the fire intent.
  Deleted: Invariant 7. Composes 6 owns it.
  ```

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

8. **Two years later — FDA Part 11 inspection.** Inspector queries `read_workflow({instance_id: "wf-batch-br-2026-0412"})`. The composed view returns: workflow record; State Machine history (3 entries — `begin-testing`, `complete-tests`, `release` — tracing sampled → testing → qp-review → released); each transition's Audit Trail `event_id`; the `"QP-sign-off"` gate's Approval Step (Approved, `decided_by=qp_director_santos`, `decided_at`, `decision_reason`). The inspector calls `AuditTrail.verify_record(event_id, payload)` for the `transition_fired` event on the release transition and receives `verified`. The inspector confirms: (a) the batch moved only through declared states (Invariant 5); (b) the release transition fired with `guard_satisfied=true` and the bound step is in Approved state (Invariant 1); (c) the QP's identity is attested under Part 11 section 11.50 (Audit Trail Actor Identity). Control evidence is complete and provable.

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

A journal-entry workflow's `post` transition is guarded; its gate is open and bound to `step-je-091`. The controller rejects: `decide_gate(..., decision="reject", reason="Supporting docs incomplete — resubmit with invoice attached")` → `gate_decision_intended` records first, which is where the controller's credential is validated — this action has no Permissions check, so that record is the only thing standing between an asserted actor_ref and a committed rejection — then `ApprovalStep.reject` → rejected_outcome; the Assignment is recalled; `gate_decided` is recorded carrying `intent_event_id`. A subsequent `fire_transition(..., action="post")` reads the bound step, finds `Rejected`, and returns `rejected(gate-not-cleared)` — the rejection stands as the gate's outcome, but it does not brick the transition: after the preparer attaches the invoice, `open_gate(..., action="post")` finds the bound step in `Rejected` (a terminal non-Approved state — Wiring decision 7's re-binding rule), records `gate_open_intended`, binds a fresh Approval Step `step-je-114`, repoints `gate_binding`, and assigns it to the controller's in-tray. The controller approves the fresh gate (its own intent record first); fire_transition now reads `Approved` on the current binding and fires. Both gates' histories persist — two `gate_opened` events for the pair, the Rejected step immutable in the Approval Step records with its stated reason — so the auditor sees the rejection, the rework, and the eventual approval as three records, not a mutated one.

### Failure path — transition fired, audit write fails

A fire_transition commits its `WorkflowStateMachine.fire` (the load-bearing write), and the `record_action` for its `transition_fired` event answers `recording-failure(step-3)`: the Event Log append answered nothing, its reply lost. The caller receives `rejected(recording-failure(post-commit))` — the stage discriminator says the transition **did** fire, so the caller must not re-invoke (a retry would fire again; the transition is non-idempotent) and instead confirms the new state via [Read Workflow]. The firing's record is owed, a gap in Invariant 3 surfaced as a hard alerting condition, and the sweep's firing leg lands it (Reconciliation 11): it finds the history entry no `transition_fired` event names — had the lost append landed after all, it would find that event and write nothing — and, behind its recovery intent, re-emits the record under the composition actor, the firing actor in its `data` and `recovery = true` (an ordinary payload field — the substrate offers no marker surface, and none is needed), letting the auditor distinguish the recovered attestation from a clean one. The moot cascade still ran before the action returned — it is conditioned on the fire's commit, not on the record — and the bound step reads consumed throughout, because the consumption test reads the history.

### Moot-gate cascade — alternate transition leaves a gate unreachable

A purchase-order workflow has `current_state = "awaiting-approval"` with a guarded approve transition (guard `"finance-sign-off"`) and an unguarded `cancel` transition, both departing from `awaiting-approval`. The finance director's approval gate has been opened (`gate_binding[(instance_id, "awaiting-approval", "approve")]` set, Approval Step in Pending). A process manager calls `fire_transition(action="cancel")`. The `cancel` transition is unguarded, so the firing derives the moot plan read-only — the declared `to_state` is `"cancelled"`, and the one bound gate on this instance keys from `"awaiting-approval"` with its step still Pending, so the plan is `[{from_state: "awaiting-approval", action: "approve", step_id}]` — and records `transition_intended` carrying it, verifying the process manager's credential before the cancellation commits. The fire then succeeds; `new_state = "cancelled"`. The moot cascade: the `"approve"` gate's `from_state = "awaiting-approval"` ≠ `"cancelled"` = `new_state`; the gate is moot. The composition calls `ApprovalStep.withdraw(step_id, withdrawn_by=initiator_ref, reason="Gate moot: ...")`, `Assignment.recall(assignment_id)`, and `AuditTrail.record_action(action_ref=moot_gate_recalled, actor_ref=application_actor_ref, ...)`. The finance director's in-tray no longer shows the approval task. The audit trail records the withdrawal and the reason. Had the finance director already approved the gate and nobody fired approve before the cancellation, the plan would have named the same key with `moot_kind = approved-unconsumed`: no withdraw (the step is terminal), the recall an idempotent `not-active`, one `moot_gate_recalled` recording that the approval was mooted, and the binding's mooted flag set — so a return to `awaiting-approval` re-binds a fresh gate rather than firing on the stale sign-off.

---

### Regulated adversarial scenarios

Three adversarial reads this composition must survive in regulated contexts:

#### Regulator audit — SOX section 404 / FDA 21 CFR Part 11: prove declared-path and gate-cleared

An FDA inspector or SOX auditor demands evidence that process instance `wf-batch-br-2026-0412` moved only through its declared states and that the qualified-person gate was genuinely cleared before the release transition fired. The auditor queries `read_workflow({instance_id: "wf-batch-br-2026-0412"})` and receives the composed view. The auditor confirms: (a) every transition in the State Machine history corresponds to a declared transition (`read_declaration` returns the immutable declaration; Invariant 5 — constituent State Machine Invariant 3 — guarantees no undeclared transition could have produced a history entry); (b) the `"release"` history entry carries `guard_satisfied: true`, and its `transition_fired` event — reached via `transition_to_event` — carries the `step_id` pointing to the bound Approval Step (the history entry itself carries no `step_id`; the binding lives in the composition's records); (c) `ApprovalStep.read({step_id})` returns `state: Approved`, `decided_by: "qp_director_santos"`, `decided_at`, and `decision_reason`; (d) Approval Step Invariant 4 guarantees `decided_by` matched `approver_ref` at the time of the approve call; (e) `AuditTrail.verify_record(event_id, payload)` for the `transition_fired` event returns `verified`. The auditor's structural questions — *did the batch move only through declared states?* and *was the release gate cleared by the named QP?* — have provable answers under Invariants 1, 5, and 6.

#### Disputed transition — party claims a guarded transition fired without its approval

An external party (an auditor, a counterparty, an investigator) claims that the `"release"` transition fired in instance `wf-batch-br-2026-0412` without QP approval, or that an unauthorized actor advanced the process. The structural rebuttal:

For the "no approval" claim: the State Machine history entry for the release transition carries `guard_satisfied: true` (State Machine Invariant 8 — the atom records whether the caller asserted the guard). The composition's `gate_binding[(instance_id, "qp-review", "release")]` maps to `step_id="step-qp-0412-release"`. `ApprovalStep.read({step_id})` returns `state: Approved`. Invariant 1 of this composition states that `guard_satisfied = true` was asserted by the composition only because the bound step was in Approved at the time of [Fire Transition]'s gate read. A forgery would require either (a) fabricating an Approved Approval Step record for a step whose `approver_ref` is `qp_director_santos` — foreclosed by Approval Step Invariant 4 (only the named approver may decide) and by the Audit Trail's tamper-evident sealing — or (b) fabricating a State Machine history entry with `guard_satisfied: true` — foreclosed by State Machine Invariant 5 (history append-only — no `fire` writes an entry unless it succeeded; every one of its rejection arms writes nothing) and by Tamper Evidence sealing. Invariants 1, 3, and 5 together constitute the structural rebuttal.

For the "unauthorized actor advanced the process" claim: `AuditTrail.verify_record` for the `transition_fired` event returns the Actor Identity attestation, binding the actor reference to the action at the attested timestamp. Invariant 2 (Permission-gated process advancement) guarantees the firing actor held `workflows:fire` at the time of the Permissions check. An auditor confirms both.

#### Breach or incident investigation — reconstruct transitions and gate decisions during anomaly window

During a security incident (suspected credential compromise from 2026-05-01T00:00:00Z to 2026-05-03T23:59:59Z), the incident response team must determine which workflow transitions fired and which gates were cleared during the window. The team queries `read_workflow({started_at: {after: "2026-04-25T00:00:00Z"}})` for all recently started workflows — a set-valued query, answered from the `workflow_started` events and never from an enumeration of `workflow_store` (Action wiring 68). For each instance, the team inspects the State Machine history and — via `transition_to_event` — the corresponding Audit Trail `event_id`s. For each `transition_fired` event in the anomaly window, the team calls `AuditTrail.verify_record(event_id, payload)` to confirm integrity. Any `failed-verification(seal-proof-invalid)` or `failed-verification(seal-record-set-mismatch)` response — the substrate's actual tamper-indicating reason tokens — indicates a post-hoc modification, a forensic finding. For guarded transitions in the window, the team cross-references the bound Approval Step via `gate_binding`: `ApprovalStep.read({step_id})` returns `decided_by` and `decided_at`, and the Audit Trail `gate_decided` event confirms the gate decision under the Actor Identity attestation. The team also queries the Permissions records for actors who held `workflows:fire` during the window; a transition fired by an actor whose grant was not active at the firing instant is a candidate finding, judged best-effort in wall time as Check 5.1 states. Invariants 3 and 5 bound the forensic window precisely: the transition history is the complete ordered record of every step that advanced the process; the Audit Trail provides the integrity attestation for each.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when the checks below are provable to an external auditor given the composition's emergent state and the constituent records. Every trail walk runs through the log read, assuming no payload index; every check that walks events runs inside the audit horizon.

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

Term stored subject: a workflow, a step or a history entry the database carries.

Term uncounted event: an intent or a recovery intent.

Term accounted entry: a moot plan entry a moot record names, or whose owed call is still open inside the compensation window.

Term start count: whether every instantiated workflow carries its start event, and which orphan instance stands behind an unmatched start intent.

### External checks

```
External check 1: An auditor needing the start count confirmed MUST read the deployment's State Machine database-maintenance surface (Action wiring 10).
External check 2: An auditor needing the longest workflow lifetime against the audit horizon confirmed MUST read the deployment's process documentation (Capability requirement 3).
External check 3: An auditor needing a [Gate Spec] entry's approver confirmed as the correct authority MUST read the deployment's role-authorization registry at the started instant (Invariant 1.1).
External check 4: An auditor needing the declaration confirmed against the regulation's process MUST read the deployment's process documentation beside the regulation (Invariant 5.2).
External check 5: An auditor needing a named approver's standing authorization for the scope confirmed MUST read the deployment's standing-authorization registry at the started instant (Invariant 1.1).
```

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

NOTE: the owners — a Parallel Workflow composition *(not yet in the library)* (Non-goal 2); a Definition Registry *(forthcoming)* (Non-goal 3); a scheduler the deployment wires above the composition (Non-goal 4); the caller's own idempotency key, through [Idempotent Reservation](./idempotent-reservation.md) (Non-goal 5); a Failed-Attempt Log *(forthcoming)* (Non-goal 6); the deployment (Non-goal 7, External check 3 through 5); a Reverse Index *(forthcoming)* lookup a deployment builds over the assignment records (Non-goal 8); a Permissions-administration layer, [Attributed Permissions Admin](./attributed-permissions-admin.md) (Composes 16).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the machine's sequence number as the order of the history.
Clock semantics 2: The composition MUST read the Event Log sequence as the order of an intent AND the intent's outcome.
Clock semantics 3: A comparison of the composition's instant with the substrate's MUST NOT decide a write alone.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```

### Indeterminate outcome

```
Indeterminate outcome 1: A caller holding a lost [Start Workflow] answer MUST NOT re-invoke [Start Workflow] BEFORE reading the workflows by subject reference AND initiator reference (Execution Contract Error model 1).
Indeterminate outcome 2: A caller holding a lost instance action answer MUST NOT re-invoke the instance action BEFORE reading the workflow (Execution Contract Error model 1).
```

Term lost answer: an answer that never reached the caller.

### Retention asymmetry

```
Retention asymmetry 1: The composition MUST read an aged entry naming no firing event as lawful destruction.
Retention asymmetry 2: The composition MUST read a purged gate binding's spending through the binding's marks.
```

Term purged gate binding: a gate binding whose opening event the record read answers Purged.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are its five actions — [Start Workflow], [Open Gate], [Decide Gate], [Fire Transition] and [Read Workflow]; the [Gate Spec] a workflow freezes at start; the four scopes it defines for its Permissions instance, [Workflows Start], [Workflows Open Gate], [Workflows Fire] and [Workflows Read]; and the refusals it names — [Permission Denied], [Recording Failure], [Not Guarded], [Gate Not Available], [Already Open], [Gate Not Open] and [Gate Not Cleared]. The workflow records and the three indexes are declared in Composition state and carded nowhere: they are the composition's records, not concepts a caller names. The deployment settings keep their wire spellings in configuration — `audit_trail_retention_policy`, `workflow_completion_bound`, `compensation_window`, `reconciliation_cadence`, `record_write_latency`, `application_actor_ref`, `application_credential`, `clock_offset_allowance`, `intent_candidates_cap` — and the record sets their own in an implementation, `workflow_store`, `gate_binding`, `gate_to_assignment`, `transition_to_event`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the sweep; the firing leg; the cascade leg; the opening leg; the decision leg; the moot cascade; the consumption rule; a rebuild; a deployment; a deployment parsing a gate subject; an auditor; a caller; an invocation; an instance action; a found action; a validated start; a permitted start; an admitted start; an instantiated start; a landed start; an unlanded start; a validated opening; a guarded opening; an admitted opening; a submitted opening; a staffed opening; a landed opening; a bound decision; an admitted decision; a decided decision; a landed decision; a validated firing; a cleared firing; an admitted firing; a fired firing; a landed firing; a validated read; a permitted read.

Term records: the workflow records and the three indexes' entries; the intents, outcomes, moot records and recovery intents the composition records through the audit write — each an Event Log event carrying one action reference of the workflow namespace; and the instances, history entries, steps and assignments it writes through the constituents.

Term record verbs: accept, act, alert, answer, attest, bound, call, carry, change, classify, clear, commit, compare, compose, count, decide, declare, define, derive, disclose, duplicate, encode, enumerate, evaluate, examine, expose, find, gate, hold, inherit, inject, inspect, join, judge, key, leave, make, match, name, normalize, open, page, pair, pass, proceed, provision, re-bind, re-emit, re-invoke, reach, read, rebuild, record, remove, resolve, retain, retry, run, select, serve, set, share, start, store, supply, write.

Term value sets: decisions, reason-bearing decisions, stage, open state, decision outcome, moot kind and leg are declared where the section that owns each declares it.

Term bounds: completion bound (workflow_completion_bound), record write latency (record_write_latency), intent candidates cap (intent_candidates_cap), guarded transition cap, id widths, clock offset allowance (clock_offset_allowance), compensation window (compensation_window), audit horizon (audit_trail_retention_policy).

Term cadences: reconciliation cadence (reconciliation_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.62 (2026-09-24).

Term terms: composition, constituents, transitive atoms, workflow machine, log read, record read, audit write, verification, machine write, step write, assignment write, workflow namespace, workflow records, workflow record, instance id, declaration reference, gate key, gate binding index, gate binding, bound step, consumed mark, mooted mark, marks, gate-assignment index, transition-event index, live index entry, purged mark, purged index entry, workflow rebuild, binding rebuild, firing rebuild, unfiltered read, assignment history, clock-derived flag, audit retention policy, audit horizon, longest workflow lifetime, completion bound, compensation window, reconciliation cadence, record write latency, liveness sum, service identity, clock offset allowance, intent candidates cap, id widths, seam, now, gate subject, caller reference, actor reference, subject reference, approver reference, parseable credentials, credential, reason, decisions, reason-bearing decisions, capped field, guarded transition count, guarded transition cap, action, intent, outcome, act's minted id, pre-append step, retention step, stage, human actor, gate handle, open state, decision outcome, new state, workflow views, query, start intent, start event, open intent, opening event, decision intent, decision event, fire intent, firing event, intent event id, intent instant, started instant, submitted instant, decided instant, fired instant, guarded flag, matched transition, to-state, decision's step write, load-bearing call, instant-bearing call, read-side call, call's stage, instance action, validated start, permitted start, admitted start, instantiated start, landed start, unlanded start, validated opening, found action, guarded opening, admitted opening, submitted opening, staffed opening, landed opening, bound decision, admitted decision, decided decision, landed decision, validated firing, cleared firing, admitted firing, fired firing, landed firing, validated read, permitted read, horizon mark, live approvals, consumption rule, mooting rule, widened horizon, aged entries, aged entry, re-bindable steps, approval guard, spent step, sweep, firing leg, cascade leg, opening leg, decision leg, leg, aged record, planned steps, recovery intent, intent reference, plan, matching decision intents, candidate count, intent candidates, transient arm, escalation instant, moot cascade, moot plan, moot kind, moot record, moot reason, fired action, quiescent workflows, committed act, settled steps, process proof, settlement record, stored subject, uncounted event, accounted entry, start count, repeatable act, lost answer, purged gate binding.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. The section titled Structural-relation invariant templates in `spec-format.md` — the relations. record_action, read_record, verify_record, payload cap, reference length cap, attestation id width, step-2, step-3, step-4, invalid-credential, invalid-request, recording-failure, verified, failed-verification, Retained, Purged, Erasure Tombstone, Reverse Index, Failed-Attempt Log, Trusted Timestamping: Audit Trail. instantiate, fire, current, history, read_declaration, instantiated_at, fired_at, guard_satisfied, invalid-declaration, not-known, terminal, invalid-transition, storage-failure, invalid-request: State Machine. submit, approve, reject, withdraw, read, submitted_at, decided_by, withdrawn_by, decided_at, withdrawn_at, approved, rejected_outcome, withdrawn, Pending, Approved, Rejected, Withdrawn, not-pending, unauthorized: Approval Step. assign, recall, active_for, history_for, ok, not-active, already-assigned, Active, Recalled: Assignment. permitted, denied: Permissions. read: Event Log. Binding Registry, Outbox, Definition Registry: forthcoming.

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

The read-only query returning a composed view over the workflow record, the State Machine current state and transition history (each entry enriched with its Audit Trail `event_id`), and each gate's Approval Step and Assignment status. Gated by [Workflows Read]. The provable forensic surface (Invariant 6).

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

The composition's rejection for a load-bearing call's `storage-failure` (Action wiring 7) or an Audit Trail `record_action` failure surfaced at the composition boundary; a `storage-failure` on an assign, a recall or a moot cascade's withdraw fails the whole action and surfaces as `storage-failure` itself (Execution Contract Constituent failure 1). Carries its stage — `recording-failure(pre-commit | post-commit)`: pre-commit means nothing committed and the caller retries the whole action; post-commit means the load-bearing write committed and the caller must not re-invoke — the sweep lands the owed record (a bounded gap in Invariant 3).

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

- **FDA 21 CFR Part 11 (Electronic Records; Electronic Signatures)** — every transition in a Part 11 electronic records system is an electronic record; guarded transitions driven by approval gates constitute electronic signatures. Part 11 section 11.50 requires signatures be attributable; section 11.70 requires they be linked to records to prevent removal, substitution, or falsification. The composition's Audit Trail substrate (Actor Identity providing cryptographic binding; Tamper Evidence providing the linking) is the structural form of both; a recovery re-emission attests the service identity and carries the human in its payload, so its signature's attribution is read as Check 5.2 reads it. The only-declared-transitions enforcement (Invariant 5) and the approval-gated-transition claim (Invariant 1) make it provable that section 11.10 system access controls and section 11.70 record integrity requirements were honored.

- **FDA 21 CFR Part 211 (Current Good Manufacturing Practice for Finished Pharmaceuticals)** — batch release requires authorization by a Qualified Person or equivalent designated authority. A State Machine-governed batch lifecycle with a QP approval gate on the release transition is the structural form of the Part 211 batch-release control. The guarded-transition record (history entry with `guard_satisfied: true` and bound Approved Approval Step) is the per-batch control evidence.

- **SOX (Sarbanes-Oxley Act) section 404 (15 U.S.C. (United States Code) section 7262) — Internal control over financial reporting.** Process-control records for financial workflows (journal entry posting, purchase order approval, account reconciliation) must demonstrate that the required control steps occurred in the declared order and that each gate was cleared by an authorized actor. The composition's provable process proof (Invariant 6) is the structural form of the SOX section 404 control evidence requirement. Composes with Audit Trail's SOX section 802 retention obligation (7 years).

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
last gate: 2026-10-28 — Final Critique 12 — foundational count 1, not clean, no sample

open:
- 2026-08-29-a · refining · formal · the model's sweep carries no age bound and no recovery record → extend the model with the bounded sweep behind `workflow_recovery_intended`
- 2026-08-30-e · refining · formal · the model carries no mooted flag, no horizon bound on the consumption arm and no decision-matched join for leg (4) → extend it
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/execute-gated-workflow.md`; the migration and the earlier gate records that got it here are in [its history](./execute-gated-workflow.hist.md).

- **2026-10-21 — The process proof reads as provable.** *Chose:* *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where the page wrote *from the records alone*, *records-alone* or *without recourse to source code, runbooks or developer narration*: Invariant 6.1, under which every workflow's process proof resolves provably, with Invariant 6's heading, and, by wording alone, the Summary, the Intent, the Wiring decision's principle, the two inspection examples, the acceptance bar, the [Read Workflow] term entry and two standards; rules 261 to 261. *Over:* the phrase restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Invariant 6.1 changed and no obligation did.
- **2026-10-20 — The store's guarantees cited, not restated, the instance exclusion among them.** *Chose:* Capability requirement 24 citing Execution Contract Store 1 through 4 for the store the five constituents and the four indexes keep their records in; the rules restating what that store guarantees tombstoned to it — the host's instance exclusion over every state-changing invocation and the sweep, with its supply, its release, its lease, its terminus and the bar on running without it (Capability requirement 10 through 15, Action wiring 18, Concurrency 1, 2, Reconciliation 6, 7), the invalid-credential at an outcome, which the one transaction's read of the actor registry forecloses (Audit arm 10), and the marks' declared durability (Composition state 18, Capability requirement 17); and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the sweep's run at every process start and its lower edge (Reconciliation 1, 4), the invocation's own retry of an outcome, an assign, a recall and a cascade call, with the read-back of an assign that answered already-assigned and the opening left unassigned past the bound (Audit arm 12, Action wiring 30 through 32, 43, Cascade 12), the read-back of a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing (Audit arm 6), and the decision leg's recall of an assignment a decision left active (Reconciliation 23); the opening leg records the opening event alone, a submit's assign now committing with it (Reconciliation 15). Rules 284 to 261. *Over:* intent, load-bearing call, constituent writes, outcome and moot cascade committed one by one under a host's instance exclusion held from before the intent through the cascade, ordered so that a crash between them left a state the composition could name — a committed firing with no record, a submitted step with no assignment, a decided step whose assignment stayed active, a cascade call unanswered — with an invocation that retried its own writes up to the completion bound and then yielded them, and a sweep that ran at every restart, waited out that bound and took the same exclusion. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal. State Machine, Approval Step, Permissions, Assignment and Audit Trail each supply their store under Store 1 through 4, and no action here makes an act outside the store, so an action's intent, constituent writes and outcome commit together, and the instance exclusion only held store writes apart, which Store 2 now serializes. The census's question is decided by the reading Multi-Party Approval took for its own cascade: a cascade is part of the action that fires it (the section titled Multi-write atomicity in `execution-contract.md` names a cascade's writes as writes of one Step 3), so a cascade call's storage failure fails the whole firing, while a refusal — Approval Step's temporal invalid-request on a withdraw, Audit Trail's refusal of a moot record — leaves the firing standing and the call owed (Cascade 10, 11) for the cascade leg to close on a later reading (Reconciliation 14, 28); the invocation's own retry of that call goes, since its one reading cannot cure the refusal (Capability requirement 20). An Audit Trail refusal at an outcome — its invalid-request, or an append whose answer was lost — still leaves the act committed and its record owed (Audit arm 11, 17), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the read-back of an invalid-request at the retention step (Audit arm 7 through 9), the caller's bar on re-invoking a committed act and the start's re-invoke (Audit arm 14, 15), the unlanded start's quarantine and the bar on re-emitting a start event (Action wiring 10, Reconciliation 27, External check 1), the consumption rule's history arm (Wiring decision 3, 5), and the sweep on its cadence, with its horizon edge, enumeration, recovery intent, service identity, four legs, pairing, candidates, retry on a transient arm, window and escalation (Reconciliation 2, 3, 5, 8 through 22, 24 through 30), and the bounds and the liveness rule its window must clear (Capability requirement 4 through 8, 18, Check 3.5); the completion bound stays because the liveness sum reads it. The intents stay, since an intent is where the caller's credential is validated before any constituent write (Invariant 8). The four indexes stay derived indexes outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps them, so their population after the landed event, their rebuild on a miss and the landing of an index anomaly stay (Composition state 9 through 15, Action wiring 13, 14, 16, 20, 21, 40, 44, 45, 67). The rebuilds read the machine's sequence numbers and the Event Log's order (Clock semantics 1, 2), and Check 5.1 reads Permissions' own stored instants, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.
- **2026-09-30 — Audit Trail's invalid-request is read by its step at an outcome.** *Chose:* `invalid-request(step-4)` at an outcome read back and proceeded as landed, and `invalid-request(step-1 | step-2 | step-3)` answered recording-failure carrying post-commit, as a pre-append step is (Audit arm 7 and 17); at an intent the answer stays a bare invalid-request, the intent standing with no outcome at step-3 and step-4 (Audit arm 3 and 16). *Over:* one read-back for every step, which left the not-found case unanswered, and a bare invalid-request over a committed act. *Because:* Audit Trail now refuses `invalid-request(step)` so a caller can tell a committed act from a clean refusal (its Decisions entry of 2026-09-30); the frozen rule that a composition's own rejection arm carries the retry bit, and the post-commit stage this page already exports, decide it.
- **2026-08-30 — An approval is mooted on the record when the workflow leaves its state, the consumption arm stops at the horizon, the sweep's decision leg joins on the outcome, and the maps are read only at the shape their contract covers.** *Chose:* the moot-gate plan and cascade extended to Approved-and-unconsumed gates — one `moot_gate_recalled` with `moot_kind = approved-unconsumed` and a durable mooted flag, the step left standing as a decision that authorized nothing, [Open Gate] re-binding over it and [Fire Transition] refusing it; the consumption rule's history arm bounded to firings inside the audit horizon widened by `clock_offset_allowance`, with the consumed and mooted flags carried by every deployment under `binding_flag_durability` rather than offered as a fallback; sweep leg (4) joining a terminal step only to the `gate_decision_intended` whose decision, actor and stamp match the step's own, candidates on a tie and a surfaced finding on zero, never a re-emission; [Read Workflow]'s set-valued queries and the sweep's instance enumeration anchored in the `workflow_started` and `gate_opened` events with keyed rebuild-on-miss per instance; `gate_to_assignment` rebuilt from `ApprovalStep.read({})` and `Assignment.history_for(task_ref)` at every retention state; `recording-failure(pre-commit | post-commit)` and `already-open(pending | cleared-unconsumed)` on the signatures; the invocation yielding every owed write at `workflow_completion_bound` under a whole-invocation hold, the sweep re-reading its pre-check under the same serialization; the liveness inequality written out with `record_write_latency`; `intent_candidates_cap` sizing the recovery envelope; and, from the closure check, the firing's own consumed step excluded from its moot-gate plan, `instance_serialization` declared as the deployment's capability with lease-at-the-bound semantics and the re-take-before-pre-check rule, sweep leg (2) covering a withdraw that committed before its record, and leg (4) owning the recall [Decide Gate] could not land inside its bound. *Over:* an approval that survived a departure and cleared a return-path firing with no fresh decision; an unbounded history arm that read every purged firing as unrecorded and bricked the key; a leg that landed `gate_decided` for whichever intent named the step; queries that enumerated a derived index with no miss to observe; a payload-sourced rebuild declared *not rebuildable* on a capability gap the constituent does not have; a bare token on both sides of the commit; *retry until it lands* beside a sweep that starts at the bound; *cadence no longer than the window*; a plan that mooted the approval its own firing spent; a critical section attributed to nobody. *Because:* the cascade exists to keep a stale human decision from clearing a transition in a context the approver never saw, and Pending was the wrong place to stop; a horizon that destroys the event must not also destroy the key; a decision's outcome is on the step and the join must read it; an index read at a shape its contract does not cover puts the records-alone proof on a cache; a constituent's declared surface outranks the composition's memory of it; a caller who cannot tell pre-commit from post-commit re-fires a committed transition; and a section no Configuration names is a section whose lease nobody bounds (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen — with §*Intents pair with outcomes*, §*A derived index is trustworthy only where a miss is observable* and §*A derived index splits at the horizon*).
- **2026-08-26 — Every audit record emitted outside the original human invocation is composition-attributed.** *Chose:* retries, recovery emissions and cascade recalls attest under `application_actor_ref` / `application_credential`, with the human actor in the event `data` and `recovery = true`; the retry loop runs only on the substrate's transient failure, invalid-request foreclosed by budget-derived caps and minted-id width bounds. *Over:* re-presenting the human's credential on retry, or looping on every rejection. *Because:* a human credential is not available to a recovery path and a deterministic rejection retried forever is a stall, not a recovery; the discipline is shared with Multi-Party Approval so the two recovery vocabularies stay one.
- **2026-08-29 — The restart sweep is bounded at both edges, writes a recovery record before it commits, and pairs a firing to its intent on the shared reading.** *Chose:* `workflow_completion_bound` below and the audit horizon above for every leg, with the sweep holding the per-instance serialization; a `workflow.recovery_intended` record before any leg that commits constituent state; leg (1) joined on `fired_at = intended_at` plus actor rather than "the latest unmatched intent", with `intent_event_candidates` and the union of plans where more than one matches; `compensation_window` and `reconciliation_cadence` declared. *Over:* a sweep on "a fixed cadence" whose pre-check was its only guard, and a definite-article join. *Because:* the pre-check cannot see an invocation that has not written yet, so a leg fired inside the completion bound lands a second outcome for one commit; a sweep that withdraws steps and recalls assignments without a record of its own is indistinguishable from a direct call; and "the latest" chooses where the records may not (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*).
- **2026-08-27 — Committed-but-unrecorded work is re-derived from the constituent stores, never remembered by the process.** *Chose:* the consumption test's second arm reads State Machine history, the moot-gate cascade is conditioned on the fire's commit, and a four-leg restart sweep diffs the constituent stores against the trail to land every owed record; the in-flight pending set is a cache classified extraction-pending against a forthcoming Outbox atom. *Over:* retry-until-lands obligations held in process memory, and a cascade conditioned on the action returning success. *Because:* a crash between a commit and its record lost the obligation entirely — one approval could fire twice and mooted gates stayed Pending with live Assignments — and an obligation that a records-alone auditor cannot re-derive is not one the pattern can claim.
- **2026-08-27 — Caller authentication is the composition's own obligation, before any constituent call.** *Chose:* an intent record whose substrate attestation verifies the credential before the Approval Step decision commits. *Over:* assuming an authenticated-caller binding the spec never declared, which let a parseable-garbage credential drive a committed Approved step. *Because:* Permissions assigns the actor-to-caller binding to "the composing system", and this composition is that system.

</details>

NOTE: End of Execute Gated Workflow.
