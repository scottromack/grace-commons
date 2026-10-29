---
title: Multi-Party Approval
parent: Conceptual Compositions
nav_order: 6
has_toc: true
toc: true
---

# Multi-Party Approval

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Multi-Party Approval enforces an approval requiring several named approvers, over a single thing, in a way that cannot be bypassed and is provable.

The rule for how many approvers are needed is a quorum rule — all of them, a majority, or any one of them. It combines four patterns: the single-approver gate (Approval Step), a permission system controlling who may start, withdraw, or read an approval chain (Permissions), a task-tracker that puts each pending approval in the right approver's queue (Assignment), and the tamper-evident audit record (Audit Trail) that stamps and seals every step.

The load-bearing addition is checking, after each individual decision, whether the quorum has now been met or has become impossible, and ending the chain accordingly — something none of the parts can do, because the single-gate pattern does not count approvals across steps and the others know nothing about quorum at all.

The check is deterministic: anyone with the records can recompute the chain's outcome from the individual decisions and the quorum rule and confirm it. That is what makes the gate impossible to bypass — a chain cannot reach "approved" unless the required decisions are actually present in the records.

Once a chain ends, its outcome and its declared terms cannot change; corrections require a new chain. This is the mechanism behind dual-sign-off financial controls, pharmaceutical batch releases, electronic-signature chains, clinical-trial approvals, and change-control gates — any decision that must make it provable that a required set of named approvers actually decided before an action proceeded is a candidate for this composition.

---

## Intent

Many regulated actions require more than one human approval before they may proceed. A SOX-controlled (Sarbanes-Oxley Act — US corporate financial-reporting law) journal entry above a materiality threshold requires the regional finance director, the CFO (Chief Financial Officer) *and* the CEO (Chief Executive Officer). A pharmaceutical batch release under the FDA's (the US Food and Drug Administration's) 21 CFR (Code of Federal Regulations — the codification of US federal agency rules) Part 211 requires the qualified person on duty plus the QA (Quality Assurance) director. A clinical protocol deviation under ICH E6 GCP (the International Council for Harmonisation's E6 Good Clinical Practice guideline) requires the principal investigator plus, for substantive deviations, the IRB (Institutional Review Board — the committee that oversees research ethics) chair. A high-value engineering change order requires the engineering lead, the quality lead, and (when safety-critical) the safety officer. In each case the structure is the same: a set of named approvers, a quorum rule (all of them, a majority of them, any one of them), and a terminal decision that becomes the auditable evidence the control operated.

[Approval Step](../atoms/approval-step.md) is the per-gate primitive — one named approver, one subject, one scope, one decision. It deliberately does not know about chains: it does not count approvals, does not interpret quorum, and does not wire multiple gates together. Multi-Party Approval is the composition that does. The atom's single-gate scope is preserved unchanged; the composition adds the chain identity, the quorum rule, the cross-step state evaluation, and the cascade (secondary effects triggered automatically by a primary event) behavior when a chain is withdrawn or quorum becomes unachievable.

The composition addresses what the constituent atoms cannot answer alone. Approval Step records each gate but never asks *"is the chain done?"* Permissions records who may initiate a chain but never asks *"did the quorum's named approvers actually decide?"* Assignment binds work to actors but never asks *"is the work part of a multi-actor gate?"* Audit Trail records actions of consequence but never asks *"do these actions constitute a complete approval chain under the named rule?"* Stacked correctly, the four answer the auditor's actual question in one structure: a chain identity that names the required approvers and rule, N Approval Step records under that chain identity, an Assignment record per pending step, attestations and event-log entries for every chain-level and step-level action, and a deterministic chain-state evaluation whose result is provable.

This is a composition, not a new primitive. The four constituents — three atoms and the Audit Trail substrate — are unchanged. The composition is the wiring that makes their concepts coherent — one consolidated multi-party-approval surface rather than four parallel record sets the auditor has to correlate by hand.

---

## Composes

- **[Approval Step](../atoms/approval-step.md)** — the per-gate primitive: one step per approver slot, each with its own subject, approver, submitter, scope and lifecycle, only the named approver deciding it and only the submitter withdrawing it.
- **[Permissions](../atoms/permissions.md)** — the authorization surface for the chain-level actions and the read.
- **[Assignment](../atoms/assignment.md)** — the in-tray binding: one responsibility record per step, naming its approver, recalled when the step or its chain ends.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate: every intent, outcome, cascade transition and recovery record is an attributed, sealed, retention-governed Audit Trail event.

```
Composes 1: EXACTLY ONE Approval Step instance MUST serve the composition.
Composes 2: EXACTLY ONE Permissions instance MUST serve the composition.
Composes 3: EXACTLY ONE Assignment instance MUST serve the composition.
Composes 4: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST NOT change a constituent's spec.
Composes 7: The composition MUST reach a transitive atom ONLY through Audit Trail.
Composes 8: The composition MUST NOT compose an instance of a transitive atom.
Composes 9: The composition MUST select audit events through the log read.
Composes 10: The composition MUST read an event by id ONLY through the record read.
Composes 11: A deployment MUST NOT call a step write outside the composition.
Composes 12: A deployment MUST NOT record an event under the chain namespace outside the composition.
```

Term composition: this pattern's wiring of [Approval Step](../atoms/approval-step.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md) and [Audit Trail](./audit-trail.md) — the chain, the quorum rule, the cascade, the read and the recovery discipline.

Term constituents: [Approval Step](../atoms/approval-step.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md), [Audit Trail](./audit-trail.md).

Term transitive atoms: [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md), [Tamper Evidence](../atoms/tamper-evidence.md) and [Retention Window](../atoms/retention-window.md), reached through Audit Trail.

Term log read: Event Log's read by sequence-number range, from one with an open upper bound, passed through Audit Trail unchanged, with every selection by action reference and payload field made in the composition's own code.

Term record read: Audit Trail's read_record on an event id.

Term audit write: Audit Trail's record_action.

Term verification: Audit Trail's verify_record on an event id and a presentation.

Term step write: Approval Step's submit, approve, reject or withdraw.

Term chain namespace: the action references chain_initiation_intended, chain_initiated, chain_initiation_failed, step_decision_intended, step_approved, step_rejected, step_withdrawn, chain_withdrawal_intended, chain_withdrawn, chain_resolved, cascade_completed and chain_recovery_intended on the composition's Audit Trail instance.

Adjacent, **not** constituents: [Privileged Access Provisioning](./privileged-access-provisioning.md) and [Execute Gated Workflow](./execute-gated-workflow.md) compose this chain as their approval surface; [Notification](../atoms/notification.md) and [Notification Fanout](./notification-fanout.md) tell approvers of work (Non-goal 7); [Legal Hold](../atoms/legal-hold.md) suspends purge over the chain's events through the substrate (Capability requirement 24).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the chain records, the step list index, the step-chain index, the step-assignment index AND the event index.
Composition state 2: A chain record MUST carry the declared fields, the chain state, the terminal instant, the quarantine flag AND the landed ids.
Composition state 3: EVERY audit event other than an initiation intent MUST carry the chain id.
Composition state 4: A chain-shape event MUST carry the chain shape.
Composition state 5: An initiation-failed record MUST carry the disposition AND the initiator reference.
Composition state 6: A resolution event MUST carry the chain state, the terminal instant, the reason AND the recalled step ids.
Composition state 7: A withdrawal event MUST carry the terminal instant AND the reason.
Composition state 8: The composition MUST NOT remove a chain record.
Composition state 9: The composition MUST classify a chain record in an open initiation window as extraction-pending against Outbox.
Composition state 10: The composition MUST classify a live index entry as a derived index.
Composition state 11: The composition MUST classify a purged index entry as extraction-pending against Erasure Tombstone.
NOTE: watch the unnamed purged half (Composition state 11).
Composition state 12: The composition MUST rebuild the chain records AND the step list index PER the chain rebuild.
Composition state 13: A rebuild MUST retain EVERY chain record the chain rebuild does not produce.
Deleted: Composition state 14. Execution Contract Database 1 owns it.
Deleted: Composition state 15. Execution Contract Database 1 owns it: an initiation's chain record and its chain-shape event commit together, and the composition names no record a rebuild hands to the initiation leg.
Composition state 16: The composition MUST rebuild the step-chain index by inverting the step list index.
Composition state 17: The composition MUST rebuild the step-assignment index through the assignment history of each step id.
Composition state 18: The composition MUST rebuild the event index PER the event rebuild.
Deleted: Composition state 19. Execution Contract Database 3 and Execution Contract Database 4 own it.
Composition state 20: The composition MUST decide an index entry's horizon by the record read on the entry's source event.
Composition state 21: The composition MUST NOT read a key as carrying no index entry BEFORE rebuilding the key's index entry.
NOTE: watch the miss read before its rebuild (Composition state 21).
```

Term chain records: the set of chain records — `chain_store` in an implementation.

Term chain record: one approval chain's record.

Term declared fields: the chain id, the subject reference, the scope, the initiator reference, the approver set, the quorum rule, the initiated instant and the initiation's invocation id.

Term chain id: the id the host injects at the seam for a new chain — chain_id.

Term chain state: Pending | Approved | Rejected | Withdrawn.

Term terminal instant: the reading of the invocation or reconciliation run that moved the chain out of Pending — chain_terminal_at, a field of the chain record.

Term quarantine flag: audit_pending set to true on a chain record whose constituent writes committed and whose chain-shape event has not landed.

Term landed ids: the step ids and assignment ids an initiation appended to the chain record as each was minted.

Term step list index: the map from a chain id to the chain's ordered step ids — `chain_to_steps` in an implementation.

Term step-chain index: the map from a step id to its chain id — `step_to_chain` in an implementation.

Term step-assignment index: the map from a step id to its assignment id — `step_to_assignment` in an implementation.

Term event index: the map from a chain id to the event ids recorded for the chain in recording order, the chain's initiation intent among them, each with the step id the event names — `chain_to_events` in an implementation, the declared chain-to-audit traversal.

Term index entry: one key's value in one of the five record sets above.

Term chain-shape event: an initiation event or an initiation-failed record.

Term chain shape: the declared fields with the ordered step ids, the paired assignment ids and the initiated instant.

Term open initiation window: the span in which a chain record inside the audit horizon has no chain-shape event.

Term source event: the chain-shape event of a chain record or step list entry, or the event an event index entry names.

Term live index entry: an index entry whose source event the record read answers Retained, or a step-chain or step-assignment entry.

Term purged index entry: a chain record, step list entry or event index entry whose source event the record read answers Purged.

Term chain rebuild: the log read kept to the chain-shape events, each recorded as its chain shape — the initiator from an initiation event's actor, or from an initiation-failed record's payload — with the chain state and terminal instant from the chain's resolution or withdrawal event, Pending where none exists, and the quarantine flag absent.

Term event rebuild: the log read kept to the chain namespace, each event recorded against its payload's chain id with the step id it names, and each initiation intent recorded against the chain record carrying the intent's invocation id.

Term assignment history: Assignment's history_for on a step id as the task — every assignment the step ever carried.

### Capability requirement

```
Capability requirement 1: A deployment MUST set the approver set minimum.
Capability requirement 2: A deployment MUST set the approver set uniqueness.
Capability requirement 3: A deployment MUST set the allowed quorum rules.
Deleted: Capability requirement 4. Execution Contract Database 3 and Execution Contract Database 4 own it.
Capability requirement 5: A deployment MUST set the audit retention policy on the Audit Trail instance.
Capability requirement 6: The composition MUST NOT pass a retention input to the audit write.
Capability requirement 7: A deployment MUST set the decision completion bound.
Capability requirement 8: A deployment MUST set the compensation window.
Capability requirement 9: A deployment MUST set the reconciliation cadence.
Capability requirement 10: A deployment MUST disclose the outcome write latency.
Capability requirement 11: The composition MUST start ONLY IF the compensation window EXCEEDS the liveness sum.
Capability requirement 12: A deployment MUST provision the service identity.
Capability requirement 13: The composition MUST NOT gate a service-identity write on a Permissions grant.
Capability requirement 14: A deployment MUST retire a compromised service credential in the actor registry.
Deleted: Capability requirement 15. Execution Contract Database 2 owns it.
Deleted: Capability requirement 16. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 18. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for a host to lack.
Capability requirement 19: The host MUST inject now AND the invocation id at the seam once per invocation.
Capability requirement 20: The host MUST inject the chain id at [Initiate Chain]'s seam.
Capability requirement 21: The wired Audit Trail instance MUST expose the log read.
Capability requirement 22: A deployment MUST declare the id widths.
Capability requirement 23: The composition MUST stamp EVERY instant one invocation writes from the invocation's now.
Capability requirement 24: A deployment composing Legal Hold MUST place a subject's hold over the event ids the event index names for the subject's chains.
Capability requirement 25: A deployment needing reader authentication MUST bind the actor reference to an authenticated caller above the composition.
Capability requirement 26: The deployment MUST supply the database PER Execution Contract Database 1 through 4 and Execution Contract Query 1 through 4.
Capability requirement 27: A deployment MUST declare the operating skew.
```

Term approver set minimum: the smallest approver set a chain may declare — `approver_set_minimum`, default one; a single-gate chain is degenerate and valid.

Term approver set uniqueness: whether an approver set's references must be pairwise distinct — `approver_set_uniqueness`, default true.

Term allowed quorum rules: the quorum rules the deployment permits — `quorum_rule_allowed`, default [All Of N], [M Of N] and [One Of N].

Term audit retention policy: the retention policy configured on the composition's single Audit Trail instance — `audit_trail_retention_policy`: a seven-year SOX policy, a Part 11 predicate-rule policy, an ICH E6 trial-master-file policy.

Term audit horizon: the audit retention policy's horizon.

Term decision completion bound: the longest a state-changing invocation may run from its intent to its outcome — `decision_completion_bound`.

Term compensation window: the duration within which an open marker must close or be escalated — `compensation_window`.

Term reconciliation cadence: the interval between the sweep's runs, beside the run at every process start — `reconciliation_cadence`.

Term outcome write latency: the deployment's disclosed bound on one audit write landing.

Term liveness sum: `((decision completion bound + reconciliation cadence) + outcome write latency)`.

Term service identity: the composition's registered actor reference and credential — `application_actor_ref` and `application_credential` — under which the composition attests every write no present human caused.

Term invocation id: the fresh id the host injects at the seam per state-changing invocation or sweep run, carried by every event the composition writes and by the chain record an initiation writes.

Term seam: the composition's input and output boundary — the one place the host reads the clock and mints the chain id and the invocation id, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term id widths: the widest chain id, step id, assignment id and event id the seam and the constituents mint — the substrate's own attestation id width move, so a payload carrying id lists is sized at validation.

Term operating skew: the deployment's declared bound on the difference between the composition's seam and a constituent's.

### Primitive policy

```
Primitive policy 1: IF the actor reference EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 2: IF a reference's length EXCEEDS Audit Trail's reference length cap THEN the action MUST answer invalid-request.
Primitive policy 3: IF a capped string EQUALS blank THEN [Initiate Chain] MUST answer invalid-request.
Primitive policy 4: IF a capped string's length EXCEEDS the field length cap THEN [Initiate Chain] MUST answer invalid-request.
Primitive policy 5: IF the approver set minimum EXCEEDS the approver set's count THEN [Initiate Chain] MUST answer invalid-request.
Primitive policy 6: IF the approver set uniqueness EQUALS true AND the approver set carries a repeated reference THEN [Initiate Chain] MUST answer invalid-request.
Primitive policy 7: IF the quorum rule IS NOT IN the allowed quorum rules THEN [Initiate Chain] MUST answer invalid-request.
Primitive policy 8: IF the quorum count IS NOT IN the valid quorum counts THEN [Initiate Chain] MUST answer invalid-request.
Primitive policy 9: IF the reason EQUALS blank THEN a reason-bearing action MUST answer invalid-request.
Primitive policy 10: IF the larger payload EXCEEDS the payload budget THEN the action MUST answer invalid-request.
Primitive policy 11: An action refused under Primitive policy 1 through 10 MUST NOT write.
Primitive policy 12: The composition MUST NOT call a constituent BEFORE Primitive policy 1 through 10 pass.
Primitive policy 13: The composition MUST compare a reference AND an id byte-exact.
Primitive policy 14: The composition MUST NOT normalize a caller string.
Primitive policy 15: The composition MUST NOT inspect a credential.
Primitive policy 16: The composition MUST NOT write a credential into an event payload.
Primitive policy 17: The composition MUST read a chain id's order ONLY as [Read Chain]'s tiebreak (Execution Contract Logic confinement 10).
```

Term reference: an actor reference or an approver reference — each becomes the actor reference of some audit write.

Term capped string: a subject reference, a scope or an approver reference.

Term actor reference: the calling actor — actor_ref.

Term subject reference: the opaque reference to the thing under approval — subject_ref.

Term scope: the subject's approval scope, passed to Approval Step unchanged — never one of the composition's own Permissions scopes.

Term approver set: the approver references a chain names, one slot each — approver_set.

Term approver reference: one element of the approver set.

Term quorum rule: [All Of N], [M Of N] carrying the quorum count, or [One Of N].

Term quorum count: the M an [M Of N] rule carries.

Term valid quorum counts: `1 ≤ M ≤ |approver set|`.

Term reason: the caller's free text, stored verbatim in the audit data and, at [Initiate Chain], behind the chain id prefix in each step's stored reason.

Term reason-bearing action: [Reject Step], [Withdraw Step] or [Withdraw Chain], whose reason is required.

Term field length cap: the byte length a capped string may not exceed, derived from Audit Trail's payload cap less the composition's event envelope, so every event's constructed data fits by construction.

Term larger payload: the larger of an action's intent payload and its outcome payload, every id at the id widths and the reason with its prefix.

Term payload budget: Audit Trail's configured payload cap less the envelope the composition's event data adds.

Term credential: the caller's authentication material, consumed only by the audit write.

### Audit arm

```
Audit arm 1: IF Audit Trail answers invalid-credential at an intent THEN the action MUST answer invalid-credential.
Audit arm 2: IF Audit Trail answers recording-failure at an intent THEN the action MUST answer recording-failure carrying intent.
Audit arm 3: IF Audit Trail answers invalid-request carrying any step at an intent THEN the action MUST answer invalid-request.
Audit arm 4: The composition MUST NOT retry an invalid-request answer.
Audit arm 5: The deployment MUST alert on EVERY invalid-request from the audit write as a deployment fault.
Deleted: Audit arm 6. Execution Contract Database 1 owns it.
Audit arm 7: IF Audit Trail answers invalid-request carrying the retention step at an outcome THEN the invocation MUST read the outcome back.
Audit arm 8: A read-back MUST match the outcome carrying the invocation id.
Audit arm 9: IF the read-back finds the outcome THEN the invocation MUST proceed as landed.
Audit arm 10: IF Audit Trail answers recording-failure at an outcome THEN the action MUST answer recording-failure carrying outcome.
NOTE: watch the retention step's recording failure (Audit arm 10).
Audit arm 11: IF the read-back finds no outcome THEN the action MUST answer recording-failure carrying outcome.
Deleted: Audit arm 12. Execution Contract Database 2 owns it.
Audit arm 13: The composition MUST NOT retry an outcome inside the invocation.
Audit arm 14: A caller MUST read recording-failure carrying intent as a committed nothing.
Audit arm 15: A caller MUST read recording-failure carrying outcome as a committed act.
Audit arm 16: IF Audit Trail answers invalid-request carrying step-1, step-2 or step-3 at an outcome THEN the action MUST answer recording-failure carrying outcome.
```

Term intent: an initiation intent, a decision intent or a withdrawal intent — the audit write an action makes before anything commits, the one that verifies the caller's credential.

Term outcome: an initiation event, a decision's outcome or a withdrawal event — the audit write an action owes after its commit.

Term retention step: the step naming the substrate's retention placement on an invalid-request — step-4; the event is appended and attested.

Term read-back: the record read on the event id an invalid-request carrying the retention step returns among its committed ids.

Term position: intent | outcome — where a recording-failure sat.

### Action wiring

```
initiate_chain(actor_ref, credential, subject_ref, scope, approver_set, quorum_rule, optional reason)
  answers chain id
  refuses permission-denied | invalid-request | invalid-credential | recording-failure(position)

approve_step(actor_ref, credential, chain_id, step_id, optional reason)
  answers approved
  refuses invalid-request | invalid-credential | not-known | not-pending | unauthorized | recording-failure(position)

reject_step(actor_ref, credential, chain_id, step_id, reason)
  answers rejected_outcome
  refuses invalid-request | invalid-credential | not-known | not-pending | unauthorized | recording-failure(position)

withdraw_step(actor_ref, credential, chain_id, step_id, reason)
  answers withdrawn
  refuses invalid-request | invalid-credential | not-known | not-pending | unauthorized | recording-failure(position)

withdraw_chain(actor_ref, credential, chain_id, reason)
  answers withdrawn
  refuses permission-denied | invalid-request | invalid-credential | not-known | not-pending | unauthorized | recording-failure(position)

read_chain(actor_ref, query)
  answers chain results
  refuses permission-denied | invalid-query
```

Term chain results: the chains a query matches, in Action wiring 55's order, each carrying the chain record, its step records, each step's assignment records, each step's out-of-band mark and the chain's event ids.

Term query: any combination of filters on chain id, subject reference, scope, initiator reference, chain state, initiated instant and terminal instant, a filter on initiated instant or terminal instant carrying a range. A query is malformed where it filters on another axis, where a filter carries a blank string, or where a range's end precedes its start.

NOTE: watch the blank filter value (Term query).

```
Action wiring 1: A validated initiation MUST call the permission check with the actor reference AND [Chains Initiate].
Action wiring 2: IF the permission check answers denied THEN the action MUST answer permission-denied.
Action wiring 3: A permitted initiation MUST record the initiation intent carrying the invocation id, the subject reference, the scope, the approver set, the quorum rule, the reason AND now as the intent instant.
Action wiring 4: An initiation intent MUST NOT carry a minted id.
Deleted: Action wiring 5. Execution Contract Database 1 owns it.
Action wiring 6: An admitted initiation MUST write the chain record carrying Pending, the declared fields AND now as the initiated instant.
Action wiring 7: An admitted initiation MUST call Approval Step's submit per approver slot in declaration order with the subject reference, the approver reference, the actor reference as the submitter, the scope AND the prefixed reason.
Action wiring 8: An admitted initiation MUST append EVERY step id submit answers to the chain record's landed ids, the step list index AND the step-chain index.
Action wiring 9: IF submit answers invalid-request THEN the initiation MUST run the initiation recovery carrying disposition a.
Action wiring 10: A submitted initiation MUST call Assignment's assign per step id with the step id as the task AND the step's approver reference as the assignee.
Action wiring 11: A submitted initiation MUST append EVERY assignment id assign answers to the chain record's landed ids AND the step-assignment index.
Action wiring 12: IF assign answers invalid-request OR already-assigned THEN the initiation MUST run the initiation recovery carrying disposition b.
Action wiring 13: IF assign answers already-assigned THEN the deployment MUST alert on the answer as id reuse in a constituent.
Action wiring 14: A staffed initiation MUST record the initiation event carrying the invocation id, the intent event id, the chain shape AND the reason.
Action wiring 15: An unlanded initiation MUST run the initiation recovery carrying disposition c.
Action wiring 16: A landed initiation MUST answer the chain id.
Action wiring 17: IF the step-chain index's chain id for the step id DOES NOT EQUAL the chain id THEN the decision action MUST answer not-known.
Action wiring 18: A resolved decision MUST compute the trailing flag from the chain state.
Action wiring 19: A resolved decision MUST NOT refuse on the chain state.
Action wiring 20: A resolved decision MUST record the decision intent carrying the invocation id, the chain id, the step id, the decision, the reason, the trailing flag AND now as the intent instant.
Action wiring 21: An admitted decision MUST call the decision's step write with the step id, the actor reference as the decider AND the reason.
Action wiring 22: IF the step write answers a step refusal THEN the decision action MUST answer the step refusal.
Action wiring 23: IF Approval Step OR Assignment answers storage-failure THEN the action MUST answer recording-failure carrying intent (Execution Contract Constituent failure 1).
Action wiring 24: A decided decision MUST call Assignment's recall on the step's assignment id.
Action wiring 25: IF the step-assignment index names no assignment for the step THEN the decided decision MUST NOT call recall.
Action wiring 26: IF recall answers not-active THEN the decided decision MUST proceed.
Deleted: Action wiring 27. Execution Contract Database 1 owns it.
Action wiring 28: IF recall OR withdraw answers not-known THEN the deployment MUST alert on the answer as an index anomaly.
Action wiring 29: A decided decision MUST record the decision's outcome carrying the invocation id, the intent event id, the acting actor reference, the chain id, the step id, the reason, the trailing flag AND the cascade flag as false.
Action wiring 30: IF the trailing flag EQUALS false THEN a decided decision MUST run the chain evaluation.
Action wiring 31: IF the trailing flag EQUALS true THEN a decided decision MUST NOT change the chain record.
Action wiring 32: A landed decision MUST answer the step write's answer.
Deleted: Action wiring 33. Execution Contract Database 2 owns it.
Action wiring 34: IF the chain state DOES NOT EQUAL Pending THEN the chain evaluation MUST NOT write.
Action wiring 35: IF the chain state EQUALS Pending AND the quorum rule answers a terminal state on the routed vector THEN the chain evaluation MUST set the chain state to the terminal state AND the terminal instant to now.
Action wiring 36: The chain evaluation MUST NOT run the cascade BEFORE setting the chain state.
Action wiring 37: A terminating evaluation MUST run the cascade with the rule reason.
Action wiring 38: A terminating evaluation MUST record the resolution event carrying the invocation id, the chain id, the chain state, the terminal instant, the rule reason, the recalled step ids AND the partial flag where set under the service identity.
Action wiring 39: A terminating evaluation MUST record the resolution event ONLY AFTER EVERY cascade call answers.
Action wiring 40: A validated chain withdrawal MUST call the permission check with the actor reference AND [Chains Withdraw].
Action wiring 41: IF the chain records carry no record for the chain id THEN [Withdraw Chain] MUST answer not-known.
Deleted: Action wiring 42. Execution Contract Database 2 owns it.
Deleted: Action wiring 43. Execution Contract Database 1 owns it.
Action wiring 44: IF the chain state DOES NOT EQUAL Pending THEN [Withdraw Chain] MUST answer not-pending.
Action wiring 45: IF the chain's initiator reference DOES NOT EQUAL the actor reference THEN [Withdraw Chain] MUST answer unauthorized.
Action wiring 46: An open chain withdrawal MUST record the withdrawal intent carrying the invocation id, the chain id, the reason AND now as the intent instant.
Action wiring 47: An admitted chain withdrawal MUST set the chain state to Withdrawn AND the terminal instant to now.
Action wiring 48: An admitted chain withdrawal MUST run the cascade with the reason.
Action wiring 49: An admitted chain withdrawal MUST record the withdrawal event carrying the invocation id, the intent event id, the acting actor reference, the chain id, the reason, the terminal instant AND the partial flag where set.
Action wiring 50: A landed chain withdrawal MUST answer withdrawn.
Action wiring 51: A validated read MUST call the permission check with the actor reference AND [Chains Read].
Action wiring 52: IF the query is malformed THEN [Read Chain] MUST answer invalid-query.
Action wiring 53: A permitted read MUST answer the chain results.
Action wiring 54: A permitted read MUST read a step's assignment records through the step's assignment history.
Action wiring 55: A permitted read MUST order chains by initiated instant AND then by chain id ascending (Execution Contract Logic confinement 10).
Action wiring 56: [Read Chain] MUST NOT record an audit event.
Action wiring 57: The composition MUST write EVERY landed event's id into the event index with the step id the event names.
Deleted: Action wiring 58. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Action wiring 59: [Approve Step] MUST call Approval Step's approve as the decision's step write.
Action wiring 60: [Reject Step] MUST call Approval Step's reject as the decision's step write.
Action wiring 61: [Withdraw Step] MUST call Approval Step's withdraw as the decision's step write.
Action wiring 62: IF the initiation recovery runs inside the invocation THEN [Initiate Chain] MUST answer recording-failure carrying outcome.
```

NOTE: open 2026-10-26-b — [Initiate Chain]'s recording-failure carrying outcome (Action wiring 62) carries no chain id, so a caller reading it as a committed act (Audit arm 15) holds no id to read the chain back by.

Term minted id: a chain id, a step id or an assignment id.

Term prefixed reason: "chain:" and the chain id, then ": " and the caller's reason where supplied — the step's stored reason, which names its chain on the atom's own record.

Term initiation intent: the chain_initiation_intended event.

Term initiation event: the chain_initiated event.

Term decision intent: the step_decision_intended event.

Term withdrawal intent: the chain_withdrawal_intended event.

Term approval event: the step_approved event.

Term rejection event: the step_rejected event.

Term step withdrawal event: the step_withdrawn event.

Term withdrawal event: the chain_withdrawn event.

Term resolution event: the chain_resolved event.

Term decision's outcome: an approval event, a rejection event or a step withdrawal event, by the decision.

Term decision: approve for [Approve Step], reject for [Reject Step], withdraw for [Withdraw Step].

Term decision's step write: Approval Step's approve, reject or withdraw, by the decision — the decider passed as decided_by, or as withdrawn_by for a withdrawal.

Term step refusal: invalid-request | not-known | not-pending | unauthorized — Approval Step's refusals of a step write, relayed by name.

Term intent event id: the event id of the intent an outcome pairs with — intent_event_id.

Term intent instant: the now an intent carries — intended_at.

Term initiated instant: the now an initiation stamps on its chain record — initiated_at.

Term acting actor reference: the human caller, duplicated in an outcome's payload — acting_actor_ref — so a re-emission under the service identity keeps who acted.

Term trailing flag: [Trailing] — true where the chain state did not equal Pending when the decision resolved.

Term cascade flag: cascade — true only on the step withdrawal events a cascade records.

Term partial flag: cascade_partial set to true on a terminal event whose cascade left a call unanswered on a transient arm, with each such call named by its step id and its call — the calls the flag names.

Term recovery flag: recovery set to true on every event the composition records outside the invocation that owed it.

Term validated initiation: an [Initiate Chain] call whose inputs cleared Primitive policy.

Term permitted initiation: a validated initiation whose permission check answered permitted.

Term admitted initiation: a permitted initiation whose initiation intent landed.

Term submitted initiation: an admitted initiation whose every submit answered a step id.

Term staffed initiation: a submitted initiation whose every assign answered an assignment id.

Term landed initiation: a staffed initiation whose initiation event landed or was read back.

Term unlanded initiation: a staffed initiation whose initiation event neither landed nor was read back.

Term resolved decision: an [Approve Step], [Reject Step] or [Withdraw Step] call whose inputs cleared Primitive policy and whose step id the step-chain index names under the chain id.

Term admitted decision: a resolved decision whose decision intent landed.

Term decided decision: an admitted decision whose step write answered its success.

Term landed decision: a decided decision whose outcome landed or was read back.

Term decision action: [Approve Step], [Reject Step] or [Withdraw Step].

Term chain evaluation: running the quorum rule over a chain's routed vector, with the terminal, the cascade and the resolution event a terminal answer fires.

Term terminating evaluation: a chain evaluation of a chain whose chain state EQUALS Pending, whose quorum rule answered a terminal state.

Term validated chain withdrawal: a [Withdraw Chain] call whose inputs cleared Primitive policy.

Term found chain withdrawal: a validated chain withdrawal whose permission check answered permitted and whose chain id the chain records carry.

Term open chain withdrawal: a found chain withdrawal whose chain is Pending and whose initiator reference equals the actor reference.

Term admitted chain withdrawal: an open chain withdrawal whose withdrawal intent landed.

Term landed chain withdrawal: an admitted chain withdrawal whose withdrawal event landed or was read back.

Term validated read: a [Read Chain] call whose inputs cleared Primitive policy.

Term permitted read: a validated read whose permission check answered permitted and whose query is not malformed.

#### Closure table

Every input an action takes, and every answer a call of the six actions, of the chain evaluation and cascade they run, and of the sweep can meet — Permissions' permission check, Approval Step's submit, step writes, withdraw and read, Assignment's assign, recall and history_for, and Audit Trail's audit write, record read and log read — with where the call lands it and the rule that owns the landing. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here. Each action is one transaction (Execution Contract Database 1), so a call that fails the action leaves none of its writes, its intent included, and where two refusals of one action apply to one call, the one listed first on its refuses line answers (Execution Contract Refusal 1). The enumeration is exhaustive: an answer a constituent adds is a row this table lacks, and a cell no rule owns is a finding against the page.

**Inputs.**

| Action | Input | Lands | Owner |
|---|---|---|---|
| every action but [Read Chain] | a blank actor reference, or a reference longer than Audit Trail's reference length cap | invalid-request, nothing written and no constituent called | Primitive policy 1, 2, 11, 12 |
| [Read Chain] | a blank or over-long actor reference | the permission check's answer, the read's refuses line carrying no invalid-request | Action wiring 51, Action wiring 2 |
| [Initiate Chain] | a blank subject reference, scope or approver reference, or one longer than the field length cap | invalid-request, nothing written | Primitive policy 3, 4, 11 |
| [Initiate Chain] | an approver set smaller than the approver set minimum, or repeating a reference where the approver set uniqueness is true | invalid-request, nothing written | Primitive policy 5, 6, 11 |
| [Initiate Chain] | a quorum rule outside the allowed quorum rules, or a quorum count outside the valid quorum counts | invalid-request, nothing written | Primitive policy 7, 8, 11 |
| [Initiate Chain] | an approver set naming the initiator reference | admitted | Non-goal 13 |
| [Reject Step], [Withdraw Step], [Withdraw Chain] | a blank reason | invalid-request, nothing written | Primitive policy 9, 11 |
| [Initiate Chain], [Approve Step] | a reason supplied blank | carried as supplied, never normalized; at [Initiate Chain] the prefixed reason stays non-blank, and at [Approve Step] a refusal of the step write is relayed | Primitive policy 14, Term prefixed reason, Action wiring 22 |
| every action but [Read Chain] | a larger payload over the payload budget | invalid-request, nothing written | Primitive policy 10, 11 |
| every action but [Read Chain] | the credential | consumed by the audit write alone, never inspected or written into a payload | Primitive policy 15, 16 |
| a decision action | a step id the step-chain index does not name under the chain id, a missing entry rebuilt first | not-known, nothing written | Action wiring 17, Composition state 21 |
| a decision action | a step whose chain is terminal | admitted, the trailing flag true and the chain record unchanged | Action wiring 18, 19, 31 |
| [Withdraw Chain] | a chain id the chain records carry no record for, a missing record rebuilt first | not-known, ahead of the withdrawal intent | Action wiring 41, Composition state 21 |
| [Withdraw Chain] | a chain that is not Pending | not-pending, ahead of the withdrawal intent | Action wiring 44 |
| [Withdraw Chain] | an actor reference other than the chain's initiator reference | unauthorized, ahead of the withdrawal intent | Action wiring 45 |
| [Read Chain] | a malformed query | invalid-query, nothing read; permission-denied where the permission check also denies the caller | Action wiring 52, Action wiring 2, Execution Contract Refusal 1 |
| [Read Chain] | a query no chain matches | chain results carrying no chain | Action wiring 53 |

**Permissions: the permission check**, at [Initiate Chain], [Withdraw Chain] and [Read Chain] (Action wiring 1, 40, 51).

| Answer | Lands | Owner |
|---|---|---|
| permitted | the initiation intent; at [Withdraw Chain] its chain, Pending and initiator checks; the read | Action wiring 3, 41, 44, 45, 53 |
| denied | permission-denied, nothing written and nothing recorded | Action wiring 2, Non-goal 9 |
| state-unavailable | passed through unchanged, nothing written | Execution Contract Read 1 through 3 |
| no answer | no answer to give | Execution Contract Error model 1 |

**Approval Step and Assignment, inside an action.** A storage-failure from any of these calls fails the whole action, at whatever call it comes: recording-failure carrying intent, nothing committed (Action wiring 23, Execution Contract Constituent failure 1). A state-unavailable passes through unchanged and writes nothing (Execution Contract Read 1 through 3), and a call with no answer leaves the action none to give (Execution Contract Error model 1). The other answers:

| Call | Answer | Lands | Owner |
|---|---|---|---|
| submit, per approver slot | a step id | the landed ids, the step list index and the step-chain index | Action wiring 8 |
| submit | invalid-request | the initiation recovery, disposition a; [Initiate Chain] answers recording-failure carrying outcome | Action wiring 9, 62 |
| assign, per step id | an assignment id | the landed ids and the step-assignment index | Action wiring 11 |
| assign | invalid-request or already-assigned | the initiation recovery, disposition b, an already-assigned alerted as id reuse; recording-failure carrying outcome | Action wiring 12, 13, 62 |
| the decision's step write | approved, rejected_outcome or withdrawn | the recall, the decision's outcome and, unless trailing, the chain evaluation | Action wiring 24, 29, 30 |
| the decision's step write | invalid-request, not-known, not-pending or unauthorized | the step refusal relayed by name, nothing written | Action wiring 22 |
| a decided decision's recall | ok or not-active | the decision proceeds to its outcome | Action wiring 26, 29 |
| a decided decision's recall | not-known | alerted as an index anomaly; the decision proceeds to its outcome | Action wiring 28, 29 |
| a decided decision's recall | not called where the step-assignment index names no assignment, a missing entry rebuilt first | the decision proceeds to its outcome | Action wiring 25, Composition state 21 |
| a cascade's withdraw | withdrawn | the step withdrawal event | Cascade 4 |
| a cascade's withdraw | not-pending | a closure record carrying the superseded mark | Cascade 10 |
| a cascade's withdraw | unauthorized or not-known | alerted, never retried; the cascade proceeds | Cascade 8, Cascade 12, Action wiring 28, Reconciliation 27 |
| a cascade's withdraw | the temporal invalid-request | a transient arm: the cascade proceeds and its terminal event carries the partial flag | Cascade 8, Cascade 9, Term transient arm |
| a cascade's withdraw | any other invalid-request | not met: the withdrawer is the step's submitter and the cascade reason is non-blank | Cascade 2, Term cascade reason |
| a cascade's recall | ok | the recalled step ids | Cascade 13 |
| a cascade's recall | not-active | read as done | Cascade 11 |
| a cascade's recall | not-known | alerted, never retried; the cascade proceeds | Cascade 8, Action wiring 28, Reconciliation 27 |
| a cascade's recall | not called where the step-assignment index names no assignment, a missing entry rebuilt first | the cascade proceeds | Cascade 7, Composition state 21 |
| Approval Step's read, on a chain's step ids | the steps | the chain results' step records and out-of-band marks | Action wiring 53, Term out-of-band mark |
| Approval Step's read | invalid-query | not met: one filter on the step id axis, each id one submit minted | Action wiring 8 |
| history_for, per step id | the assignments | the chain results' assignment records, and the rebuild of a step-assignment entry | Action wiring 54, Composition state 17 |

**Audit Trail: the audit write**, by what it records. An intent is the initiation, decision or withdrawal intent; an outcome is the initiation event, a decision's outcome or the withdrawal event; the resolution event is the chain evaluation's; the initiation recovery's records are its initiation event, initiation-failed record and withdrawal event.

| Answer | an intent | an outcome | the resolution event | a cascade's step withdrawal event | the initiation recovery's records |
|---|---|---|---|---|---|
| an event id | the act proceeds (Term admitted initiation, admitted decision, admitted chain withdrawal) | landed: the action's answer (Action wiring 16, 32, 50) | the chain's terminal event | the cascade withdrawal routed (Term routed transition) | the chain-shape event landed, the chain withdrawn where Pending and the quarantine flag cleared (Reconciliation 13, 16); a withdrawal event, the chain's terminal event |
| invalid-credential | invalid-credential, nothing written (Audit arm 1) | not met: attested inside the transaction whose intent validated the credential (Execution Contract Database 2) | a service credential fault, paged (Reconciliation 33); the chain left with no terminal event, an open marker | not met: in an action under the credential its intent validated (Cascade 5, Execution Contract Database 2), in the sweep after its recovery intent landed (Reconciliation 28) | paged (Reconciliation 33); the record unlanded, as for a recording-failure |
| invalid-request carrying step-1, step-2 or step-3 | invalid-request, never retried, a deployment fault alerted (Audit arm 3, 4, 5) | recording-failure carrying outcome, alerted (Audit arm 16, 5) | alerted (Audit arm 5); the chain left with no terminal event, an open marker | alerted, never retried (Audit arm 4, 5) | alerted (Audit arm 5); the record unlanded, as for a recording-failure |
| invalid-request carrying the retention step | invalid-request, never retried, alerted (Audit arm 3, 4, 5) | read back: found, landed; not found, recording-failure carrying outcome (Audit arm 7, 8, 9, 11) | alerted; the event appended and attested, the chain's terminal event (Audit arm 5, Term retention step) | alerted; the event appended and attested (Audit arm 5, Term retention step) | alerted; the record appended and attested, so landed (Audit arm 5, Term retention step) |
| recording-failure | recording-failure carrying intent, nothing committed (Audit arm 2, 14) | recording-failure carrying outcome, a committed act whose record the sweep owes (Audit arm 10, 15) | the chain left with no terminal event, an open marker (Term open marker) | a transient arm: the partial flag (Term transient arm, Cascade 9) | an initiation-failed record or initiation event unlanded, the chain record left for the initiation leg (Reconciliation 8, 11, 16); a withdrawal event unlanded, the chain left with no terminal event, an open marker |

Where the resolution event or a record of the initiation recovery is refused, the action answers as its own records land: a decision its step write's answer (Action wiring 32), [Initiate Chain] recording-failure carrying outcome (Action wiring 62). A state-unavailable at any write passes through unchanged and writes nothing (Execution Contract Read 1 through 3), and a write with no answer leaves the action none to give (Execution Contract Error model 1), no outcome being retried inside the invocation (Audit arm 13). The sweep closes what is left open: a chain record with no chain-shape event by the initiation leg (Reconciliation 8), a routed transition with no outcome (Reconciliation 17), a call a partial flag names (Reconciliation 26) and a terminal chain with no terminal event (Reconciliation 35) by the transition leg.

**Audit Trail: the record read and the log read.**

| Read | Answer | Lands | Owner |
|---|---|---|---|
| the read-back, on the event id an outcome's invalid-request returns | the outcome | landed | Audit arm 8, 9 |
| the read-back | not-known | recording-failure carrying outcome | Audit arm 11 |
| the record read, on an index entry's source event | Retained or Purged | the entry live, or purged | Composition state 20, Term live index entry, Term purged index entry |
| the record read, on an event id the event index names | not-known | not met: the event index names landed events alone | Action wiring 57 |
| the log read, from one with an open upper bound | the events | the chain rebuild, the event rebuild and the sweep's two legs | Composition state 12, 18, Term initiation leg, Term transition leg |
| the log read | invalid-query | not met: the range has a start and no end | Term log read |

Inside an action, a read that fails passes through unchanged and writes nothing (Execution Contract Read 1 through 3), and a read with no answer leaves the action none to give (Execution Contract Error model 1).

**The composition's own records.** A chain record or index entry the action writes commits with the action's other writes (Execution Contract Database 1), and a write of them that fails answers storage-failure (Execution Contract Read 4); a key found carrying no index entry is rebuilt before any rule reads it so (Composition state 21).

**The sweep.** It answers no caller. It decides only on an answered read (Reconciliation 39): a read that fails or gives no answer decides nothing, and the chain is examined again at the next run (Reconciliation 2). It commits a closure only after the closure's recovery intent lands (Reconciliation 28). A write of the sweep's that does not land — its recovery intent, a re-emitted outcome or terminal event, a closure record, an initiation recovery's record or a cascade's call — leaves the open marker it was closing open for the next run (Reconciliation 8, 17, 26, 35), escalated once the marker's escalation instant passes (Reconciliation 32), an invalid-credential paged besides (Reconciliation 33); a write with no answer is decided by what the next run reads (Execution Contract Error model 1). A retried withdraw or recall lands as a cascade's does and records its closure mark (Reconciliation 30, Term closure mark), a storage-failure here being a transient arm (Term transient arm) retried at every run (Reconciliation 26) and a deterministic arm never (Reconciliation 27).

### Wiring decision

```
Wiring decision 1: IF the routed vector IS IN the met vectors THEN the quorum rule MUST answer Approved.
Wiring decision 2: IF the routed vector IS IN the lost vectors AND the rejected count EXCEEDS zero THEN the quorum rule MUST answer Rejected.
Wiring decision 3: IF the routed vector IS IN the lost vectors AND the rejected count EQUALS zero THEN the quorum rule MUST answer Withdrawn.
Wiring decision 4: IF the routed vector IS IN the open vectors THEN the quorum rule MUST answer Pending.
Wiring decision 5: The quorum rule MUST NOT read an instant.
Wiring decision 6: The quorum rule MUST count a step ONLY through a routed transition.
Wiring decision 7: The composition MUST count a step decided by an out-of-band transition as Pending.
Wiring decision 8: The composition MUST mark EVERY out-of-band transition's step as out-of-band.
Wiring decision 9: A rule reason MUST name the firing arm AND the counts.
```

Term routed vector: the counts (A, R, W, P) over a chain's step list — A the steps Approved by a routed transition, R Rejected by one, W Withdrawn by one, a routed transition whose decision intent carries the trailing flag as true counting in none of the three, and P `= (((N - A) - R) - W)`, where N is the approver set's count.

Term approved count: A.

Term rejected count: R.

Term withdrawn count: W.

Term met vectors: under [All Of N], `A = N`; under [M Of N], `A ≥ M`; [One Of N] is [M Of N] with M one.

Term lost vectors: under [All Of N], `(R + W) ≥ 1`; under [M Of N], `((N - R) - W) < M`.

Term open vectors: the vectors neither met nor lost.

Term routed transition: a step decision a decision intent pairs — one naming the chain id and the step id whose actor equals the step record's decider — or, past the audit horizon, one whose event index entry names an event the record read answers Purged with a surviving action reference of step_decision_intended and a surviving actor equal to the decider; or a cascade withdrawal a cascade step withdrawal event or a closure record names.

Term out-of-band transition: a step decision in the Approval Step records no routed transition covers — written around the composition.

Term out-of-band mark: a step's mark, set where an out-of-band transition decided the step and clear on every other step — read at each [Read Chain] from the Approval Step records and the chain's routed transitions, and kept in no record.

Term rule reason: the generated reason a chain evaluation carries — "quorum met: A of N approved under" and the rule, for Approved; "quorum unreachable:" and the rule, then "N − R − W remain achievable; rejections present", for Rejected; "chain withdrawn by cascade:" and the rule, then "quorum unreachable by withdrawal alone", for Withdrawn — non-blank by construction (2026-08-26-g, 2026-08-29-g, 2026-08-29-p).

<details markdown="block">
<summary>WHY</summary>

*Principle.* The auditor's question is *did the required approvers actually decide?*, and only an outcome that is a pure function of their recorded decisions answers it provably. The composition is the only layer that can own it: Approval Step knows no chain, and the other three know no quorum.

*Likely objection.* Why not let the calling workflow count approvals — it already reads the steps — or push the quorum into Approval Step, where the decisions live?

*Mechanism.* A calling-system count is the unauditable form: the outcome would live in a system no spec governs, and *the chain approved* would be that system's assertion rather than a recomputable fact. Approval Step cannot hold it without ceasing to be the freestanding single-gate atom its EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) boundary defends, since counting across steps needs chain identity. So the rule lives here as a pure function of named counts with no clock term (Wiring decision 5), and the stored chain state is its memo, cross-checkable against the step records at any time (Invariant 2) — which is what makes a forged terminal detectable. The three sets are disjoint: under all-of-N a met vector has no rejection or withdrawal, and under M-of-N a met vector has `A ≥ M` while a lost one has `A ≤ N − R − W < M`. **A rejection outranks a withdrawal** (Wiring decision 2 and 3): a rejection is an approver's negative decision, a withdrawal is the initiator retracting a mis-submitted gate, and the terminal state keeps the two audit signals apart — Rejected names a quorum failure attributable to named decisions; Withdrawn, a chain retracted before its quorum was determined.

</details>

### Reconciliation

```
Reconciliation 1: The sweep MUST run at EVERY process start.
Reconciliation 2: The sweep MUST run every reconciliation cadence.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Deleted: Reconciliation 4. Execution Contract Database 1 owns it.
Reconciliation 5: The sweep MUST NOT examine an aged chain.
Reconciliation 39: The sweep MUST decide ONLY on an answered read.
Deleted: Reconciliation 6. Execution Contract Database 2 owns it.
Deleted: Reconciliation 7. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for another holder to hold.
Reconciliation 8: IF a chain record inside the audit horizon carries no chain-shape event THEN the initiation leg MUST run the initiation recovery.
Reconciliation 9: The initiation recovery MUST run the chain evaluation.
Reconciliation 10: IF the chain state DOES NOT EQUAL Pending AND the chain's step list's count EQUALS the approver set's count THEN the initiation recovery MUST record the initiation event carrying the chain shape from the chain record, disposition d AND the recovery flag.
Reconciliation 11: IF the chain state EQUALS Pending THEN the initiation recovery MUST set the quarantine flag.
Reconciliation 12: IF the chain state EQUALS Pending OR the chain's step list's count DOES NOT EQUAL the approver set's count THEN the initiation recovery MUST record the initiation-failed record carrying the chain shape from the chain record, the disposition AND the initiator reference under the service identity.
Reconciliation 13: IF the initiation-failed record lands AND the chain state EQUALS Pending THEN the initiation recovery MUST set the chain state to Withdrawn AND run the cascade with the recovery reason.
Deleted: Reconciliation 14. Execution Contract Database 1 owns it.
Reconciliation 15: IF the initiation recovery sets the chain state to Withdrawn THEN the initiation recovery MUST record the withdrawal event carrying the recovery flag AND the initiation-failed record's event id under the service identity.
Reconciliation 16: The initiation recovery MUST clear the quarantine flag ONLY AFTER the chain-shape event lands.
Reconciliation 17: IF a routed transition carries no outcome AND the transition's chain IS NOT IN the aged chains THEN the transition leg MUST re-emit the transition's outcome.
Reconciliation 35: IF a terminal chain carries no terminal event AND the chain IS NOT IN the aged chains THEN the transition leg MUST run the cascade with the owed terminal event's reason AND re-emit the chain's owed terminal event.
Reconciliation 18: The transition leg MUST match a transition ONLY to an audit record.
Reconciliation 19: The sweep MUST NOT re-emit an out-of-band transition's outcome.
Reconciliation 20: The sweep MUST alert on EVERY out-of-band transition as a conformance fault.
Reconciliation 21: A re-emitted outcome MUST carry the intent candidates, the acting actor reference from the step record AND the recovery flag under the service identity.
Deleted: Reconciliation 22. Execution Contract Database 1 owns it.
Deleted: Reconciliation 23. Execution Contract Database 1 owns it.
Deleted: Reconciliation 24. Execution Contract Database 1 owns it.
Deleted: Reconciliation 25. Execution Contract Database 1 owns it.
Reconciliation 26: IF a partial flag's chain IS NOT IN the aged chains THEN the sweep MUST retry a call the partial flag names on a transient arm at EVERY run.
Reconciliation 27: The sweep MUST NOT retry a deterministic arm.
Reconciliation 28: The sweep MUST NOT commit a closure BEFORE the sweep's recovery intent for the closure lands.
Reconciliation 29: A recovery intent MUST carry the invocation id, the chain id, the leg AND the intent candidates.
Reconciliation 30: The sweep MUST record a closure record carrying the chain id, the step id AND the closure mark for EVERY call the sweep closes.
Reconciliation 31: The sweep MUST attest EVERY write the sweep makes under the service identity.
Reconciliation 32: IF an open marker's escalation instant PRECEDES the sweep's now AND the marker's chain IS NOT IN the aged chains THEN the sweep MUST open an unresolved finding for the chain on Audit Trail's alerting surface.
Reconciliation 33: IF Audit Trail answers invalid-credential to the service identity THEN the deployment MUST page on the answer as a service credential fault.
Reconciliation 34: A re-emitted resolution event MUST carry the sweep's recalls AND the late-recalled steps as the recalled step ids.
Reconciliation 36: A re-emitted resolution event MUST carry the rule reason of the quorum rule's answer on the chain's pre-withdrawal vector.
Reconciliation 37: IF a withdrawal intent carries the chain id THEN a re-emitted withdrawal event MUST carry the withdrawal intent's event id as the intent event id, the withdrawal intent's actor as the acting actor reference AND the withdrawal intent's reason.
Reconciliation 38: IF no withdrawal intent carries the chain id THEN a re-emitted withdrawal event MUST carry the initiation-failed record's event id AND the recovery reason.
```

NOTE: open 2026-10-26-a — the intent candidates a re-emitted outcome carries (Reconciliation 21) and the chain results a read answers are lists with no bound, and the payload budget sizes no candidate list.

Term sweep: the reconciliation the composition runs outside every invocation — two legs over the records, whose output an auditor awaits within the compensation window.

Term initiation leg: the sweep's leg comparing the chain records against the chain-shape events.

Term transition leg: the sweep's leg comparing the committed step transitions and chain terminals against their audit records.

Term owed terminal event: the terminal event a terminal chain owes — the resolution event where the quorum rule answers the chain state on the chain's pre-withdrawal vector, and the withdrawal event otherwise.

Term aged chains: the chains whose initiated instant plus the audit horizon PRECEDES now.

Term aged chain: a chain in the aged chains.

Term settled step: a step that is terminal, or whose chain is terminal.

Term late-recalled steps: the chain's steps whose recall instant DOES NOT PRECEDE the terminal instant — a best-effort set, marked by the recovery flag.

Term initiation recovery: the closure of an initiation that committed constituent writes and landed no chain-shape event — run inside the failing invocation, or by the initiation leg.

Term disposition: a | b | c | d — where the initiation stopped: a at submit, b at assign, c at the initiation event, d a quarantined chain with its full step list, driven terminal before the recovery ran.

Term initiation-failed record: the chain_initiation_failed event, carrying the intent event id where the recovery runs inside the failing invocation.

Term chainless step: a Pending step whose subject reference, submitter and scope equal the chain's, whose stored reason carries the chain's id, and which no chain record's landed ids name.

Term recovery reason: "initiation-failed recovery (disposition" and the disposition, then ")".

Term intent candidates: every unmatched intent for the transition's chain and step whose actor equals the step record's decider, in log order — intent_event_candidates — or the intent event id alone where one matches.

Term closure record: the cascade_completed event.

Term superseded mark: superseded_by_decision set to true on a closure record.

Term closure mark: retried where the retried call succeeded; superseded_by_decision where a retried withdrawal answered not-pending; store_anomaly where a retried recall answered not-known.

Term recovery intent: the chain_recovery_intended event.

Term open marker: a quarantine flag set, a partial flag with no closure record for every call it names, a routed transition with no audit record, or a terminal chain with no terminal event.

Term escalation instant: an open marker's opening instant plus the compensation window.

Term opening instant: the instant an open marker opened — the initiated instant for a quarantine flag, the terminal instant for a partial flag and for a terminal chain with no terminal event, and the intent instant of the transition's decision intent for a routed transition with no audit record.

Term transient arm: a recording-failure from the audit write; a storage-failure on withdraw or recall; Approval Step's temporal invalid-request on a cascade withdrawal, cured by a later reading.

Term deterministic arm: every other arm — not-pending, closed as a supersession; not-known and unauthorized, alerted once.

### Scope vocabulary

```
Scope vocabulary 1: The composition MUST define chains initiate, chains withdraw AND chains read for the Permissions instance.
Scope vocabulary 2: The composition MUST NOT gate a decision action on a Permissions scope.
```

### Cascade

```
Cascade 1: A cascade MUST call recall on the assignment of EVERY still-Pending step in the step list's order.
Cascade 2: IF the chain state EQUALS Withdrawn THEN the cascade MUST call Approval Step's withdraw on EVERY still-Pending step with the initiator reference as the withdrawer AND the cascade reason.
Cascade 3: The cascade MUST NOT call recall on a withdrawn step BEFORE the step's withdraw answers.
Cascade 4: The cascade MUST record a step withdrawal event carrying the invocation id, the chain id, the step id, the cascade reason, the trailing flag as false AND the cascade flag as true for EVERY step the cascade withdraws.
Cascade 5: IF the invocation holds the initiator's validated credential THEN the cascade MUST attest the cascade's step withdrawal events under that credential.
Cascade 6: IF the invocation holds no initiator's validated credential THEN the cascade MUST attest the cascade's step withdrawal events under the service identity carrying the recovery flag.
Cascade 7: IF the step-assignment index names no assignment for a step THEN the cascade MUST NOT call recall for the step.
Cascade 8: IF a cascade call fails THEN the cascade MUST proceed through the remaining calls.
Cascade 9: IF a cascade call fails on a transient arm THEN the cascade's terminal event MUST carry the partial flag.
Cascade 10: IF withdraw answers not-pending THEN the cascade MUST record a closure record carrying the step id AND the superseded mark.
Cascade 11: IF recall answers not-active THEN the cascade MUST read the recall as done.
Cascade 12: IF withdraw answers unauthorized THEN the deployment MUST alert on the answer as a conformance fault.
Cascade 13: The recalled step ids MUST list the steps whose recall answered ok, in recall order.
```

Term cascade: the secondary calls a terminal chain owes its still-Pending steps.

Term cascade reason: the rule reason, the initiator's validated reason on the [Withdraw Chain] path, or the recovery reason — non-blank by construction, so Approval Step never refuses a cascade withdrawal over its reason.

Term recalled step ids: the steps whose assignments a cascade recalled — always present on a resolution event, empty where none.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent, and each needs two or more working together. Three structural relations frame them, per the section titled Structural-relation invariant templates in `spec-format.md`: **chain to steps**, one-to-many, exactly one step per approver slot, mandatory on both sides at quiescence; **step to assignment**, one-to-one, mandatory at creation, recalled and never replaced — the composition performs no reassign; **chain to audit events**, one-to-many, at least one per chain, every event other than an intent naming an existing chain. The inverse directions are read through the derived indexes, and a lost index entry is a rebuild trigger, never a relation violation.

- **Invariant 1 — Chain completeness.**
  ```
  Invariant 1.1: IF a chain IS IN the quiescent chains AND the chain IS NOT IN the recovery-closed chains THEN the chain's step list's count MUST EQUAL the approver set's count.
  Invariant 1.2: IF a chain IS IN the recovery-closed chains THEN the chain's step list MUST EQUAL the landed step ids the chain's initiation-failed record carries.
  Invariant 1.3: EVERY step id in a step list MUST name an Approval Step record.
  Invariant 1.4: The step-chain index MUST name EXACTLY ONE chain for EVERY step id in a step list.
  Invariant 1.5: The Approval Step records MUST carry no chainless step of a quiescent chain.
  ```
  Term quiescent chains: the chains with no invocation in flight and no open marker.

  Term quiescent chain: a chain in the quiescent chains.

  Term recovery-closed chains: the chains whose initiation-failed record landed.

- **Invariant 2 — Quorum determinism, split by terminal path.**
  ```
  Invariant 2.1: IF a chain IS IN the resolution-terminated chains THEN the chain state MUST EQUAL the quorum rule's answer on the chain's routed vector.
  Invariant 2.2: IF a chain IS IN the withdrawal-terminated chains THEN the quorum rule MUST answer Pending on the chain's pre-withdrawal vector.
  ```
  Term pre-withdrawal vector: the routed vector with the chain's cascade step withdrawals, its retry-closed withdrawals and its superseded closures counted back as Pending.

- **Invariant 3 — Permission enforcement.**
  ```
  Invariant 3.1: [Initiate Chain] MUST NOT commit for an actor reference the permission check denied.
  Invariant 3.2: [Withdraw Chain] MUST NOT commit for an actor reference the permission check denied.
  Invariant 3.3: [Read Chain] MUST NOT answer a chain to an actor reference the permission check denied.
  ```
- **Invariant 4 — Assignment coverage, safety and liveness at quiescence.**
  ```
  Invariant 4.1: IF a step IS IN the open steps AND the step's chain IS IN the quiescent chains THEN the step MUST carry EXACTLY ONE Active assignment.
  Invariant 4.2: IF a step IS IN the settled steps AND the step's chain IS IN the quiescent chains THEN the step MUST carry no Active assignment.
  Invariant 4.3: The composition MUST NOT recall the assignment of a Pending step in a Pending chain.
  ```
  Term open steps: the Pending steps whose chain is Pending.

- **Invariant 5 — Audit completeness.**
  ```
  Invariant 5.1: IF a chain IS IN the quiescent chains THEN EVERY committed transition on the chain MUST carry EXACTLY ONE audit record.
  Invariant 5.2: EVERY chain namespace event other than an intent MUST name a chain the chain records carry.
  Invariant 5.3: The deployment MUST alert on EVERY orphan attestation carrying a chain namespace action reference.
  ```
  Term audit record: a committed transition's outcome, its cascade step withdrawal event, its closure record, its re-emitted outcome or its resolution or withdrawal event.

  Term committed transition: a step's move out of Pending in the Approval Step records, or a chain's move out of Pending in the chain records.

- **Invariant 7 — Chain terminal absorption.**
  ```
  Invariant 7.1: The composition MUST NOT change a terminal chain's chain state.
  Invariant 7.2: The composition MUST NOT change a terminal chain's terminal instant.
  Invariant 7.3: Two resolution events MUST NOT carry one chain id.
  Deleted: Invariant 6. Composes 5 owns it.
  ```
- **Invariant 8 — Declared fields are immutable.**
  ```
  Invariant 8.1: The composition MUST NOT change a declared field.
  Invariant 8.2: The composition MUST set the quarantine flag ONLY through the initiation recovery.
  ```
- **Invariant 9 — Chain reconstructibility, within the audit horizon.**
  ```
  Invariant 9.1: IF a chain IS NOT IN the aged chains THEN the chain's lifecycle MUST resolve from the chain records, the Approval Step records, the Assignment records AND the chain's events alone.
  ```
  Term lifecycle: the chain record; the ordered step records with each decision, decider, decision instant and reason; each step's assignment records; and the verified attestation of every chain-level and step-level act through the event index.

- **Invariant 10 — Authentication precedes commitment.**
  ```
  Invariant 10.1: The composition MUST NOT write a chain record BEFORE Audit Trail validates the initiator's credential at the initiation intent.
  Invariant 10.2: The composition MUST NOT call a decision's step write BEFORE Audit Trail validates the caller's credential at the decision intent.
  Invariant 10.3: [Withdraw Chain] MUST NOT set a chain Withdrawn BEFORE Audit Trail validates the caller's credential at the withdrawal intent.
  ```

Chain completeness and quorum determinism give *bypass resistance* — a chain cannot read Approved without the quorum-named decisions present, and any reader can verify it. Permission enforcement and audit completeness give *non-repudiation*. Terminal absorption and immutability give *finality* — a terminated chain's outcome is fixed, and corrections are new chains, never edits.

---

## Examples

### Walkthrough — SOX-controlled journal entry, all-of-N quorum

A multinational bank's general-ledger system uses Multi-Party Approval to gate posting of journal entries above the $5M materiality threshold. The deployment configures `approver_set_minimum = 2`, `approver_set_uniqueness = true`, `quorum_rule_allowed = {all-of-N}`, `audit_trail_retention_policy = sox_7_year`.

1. **A controller prepares a journal entry.** Journal entry JE-2026-0441 posts a $12M intercompany transfer. Under the deployment's business rules, materiality of this size requires the regional controller, the CFO, and the CEO (Chief Executive Officer). The controller calls `initiate_chain(actor_ref=controller_morgan, credential=morgan_credential, subject_ref="je-2026-0441", scope="financial:journal-entry:post:materiality-tier-3", approver_set=[finance_director_chen, cfo_park, ceo_walsh], quorum_rule="all-of-N", reason="$12M intercompany transfer per Q1 close")`.
2. **The composition validates and writes.** Validation passes (three pairwise-distinct approvers, all-of-N is allowed, the constructed payload in budget) and Permissions returns `permitted` (`controller_morgan` holds `chains:initiate`). Then — **before anything is created** — the composition records `chain_initiation_intended` → `ev_init_int`, which is where `morgan_credential` is checked against the actor registry; had it not validated, the call would have returned `rejected(invalid-credential)` with no chain, no Approval Steps and no Assignments, and no teardown cascade to run. The payload names the declared chain shape and no chain_id, since an intent carries no minted id (Action wiring 4). Only then does the composition write the chain record for `chain-2026-0441`, the id the host injected at the seam, in Pending, submit three Approval Steps (`step-001`, `step-002`, `step-003`), create three Assignments (one per approver's in-tray), and record the `chain_initiated` event carrying `intent_event_id: ev_init_int`. Returns `chain_id = chain-2026-0441`.
3. **The CFO approves first.** `approve_step(actor_ref=cfo_park, credential=park_credential, chain_id=chain-2026-0441, step_id=step-002, reason="Reviewed Q1 close package; transfer is in-policy")` → the composition records `step_decision_intended` → `ev_dec_int_02` first, **which is where `park_credential` is validated — this action has no Permissions check, so that record is the only thing standing between an asserted actor_ref and a committed approval in the CFO's name**; then Step 002 transitions to Approved; the Assignment is recalled; `step_approved` records carrying `intent_event_id: ev_dec_int_02`. Quorum evaluation: `A=1, R=0, W=0, P=2`; all-of-N requires `A == N(=3)`; not satisfied; no quorum failure (no rejections or withdrawals); chain stays Pending.
4. **The controller's regional finance director approves second.** `approve_step(actor_ref=finance_director_chen, credential=chen_credential, chain_id=chain-2026-0441, step_id=step-001, reason="Mapping verified; consolidation rules applied correctly")` → its own `step_decision_intended` record validates `chen_credential`, then the approval commits and `step_approved` carries the join. `A=2, R=0, W=0, P=1`; still not at quorum.
5. **The CEO approves third.** `approve_step(actor_ref=ceo_walsh, credential=walsh_credential, chain_id=chain-2026-0441, step_id=step-003, reason="Reviewed and authorized")` → approved. `A=3, R=0, W=0, P=0`; `A == N`; chain transitions to Approved; `chain_terminal_at` is set; the audit trail records the `chain_resolved` event. The composing workflow system releases JE-2026-0441 for posting.
6. **Three years later, a SOX section 404 audit.** The auditor queries `read_chain({subject_ref: "je-2026-0441"})`. The result is one chain in Approved with three step records, nine attestations, nine retention records under the seven-year policy — one initiation intent, one `chain_initiated`, three decision intents, three `step_approved`, and one `chain_resolved`, each `record_action` producing one attestation and one retention record, and a Tamper Evidence seal covering the relevant range. `verify_record` on each Audit Trail event returns `verified`. The auditor confirms (a) Approval Step Invariant 4 was enforced on each step (`decided_by` matched `approver_ref`), (b) Invariant 2 holds (chain state matches the deterministic quorum evaluation), and (c) no chain-state edit occurred after `chain_terminal_at`. Control evidence is complete and provable.

*Every invocation in the runs below follows the same order — validation, any Permissions check, the intent record that verifies the caller, the constituent writes, the outcome record carrying `intent_event_id` — and the narrations elide it except where the example turns on it. An implementation that elided it would fail Check 10.1. **[Withdraw Chain] is the one exception**: its Pending check and its initiator check both run before its intent record.*

### Happy path — FDA Part 11 batch release, M-of-N(2) quorum across three qualified persons

A pharmaceutical manufacturer's batch release system requires any two of three Qualified Persons (QPs — the designated batch-release authorities under EU (European Union) and FDA manufacturing rules) to approve a batch release under 21 CFR Part 211. The deployment uses `quorum_rule = M-of-N(2)`. A batch BR-2026-0412 is ready for release. The QA manager initiates: `initiate_chain(actor_ref=qa_manager, credential=qa_manager_credential, subject_ref="br-2026-0412", scope="pharma:batch-release:bulk", approver_set=[qp_santos, qp_lopez, qp_kim], quorum_rule="M-of-N(2)")` → `chain-2026-0412`. QP Santos approves first (`A=1`); QP Lopez approves second (`A=2`); `A ≥ M`; the chain transitions to Approved without needing QP Kim's decision. QP Kim's step remains Pending unless Kim later decides — the chain has terminated, but the step's submission record is immutable (Approval Step Invariant 1) and the trailing decision, if Kim later approves, is recorded in the audit trail without altering the chain state (Invariant 7). The released batch carries the chain id as its control evidence; an FDA inspector queries the chain and confirms the two named QPs decided affirmatively under their respective Actor Identity attestations.

### Happy path — ICH E6 GCP protocol deviation, one-of-N quorum across a delegated approver pool

A clinical trial protocol deviation at a multi-site study can be approved by any one of the site principal investigators (PIs) on call. The trial coordinator initiates: `initiate_chain(actor_ref=coordinator_lee, credential=lee_credential, subject_ref="dev-2026-1057", scope="clinical-trial:protocol-deviation:non-substantive", approver_set=[pi_chen, pi_okafor, pi_müller, pi_singh], quorum_rule="one-of-N")`. PI Okafor approves: `A=1, M=1`; chain Approved. The other three steps remain Pending in the Approval Step records, their assignments recalled by the cascade. If a fifth approval is needed later (e.g., for a substantive deviation that requires escalation), a new chain is initiated with the appropriate quorum and approver set; the original chain is not modified.

### Rejection path — all-of-N quorum, one approver rejects

In the SOX walkthrough above, suppose the CEO finds the entry suspicious and rejects: `reject_step(actor_ref=ceo_walsh, credential=walsh_credential, chain_id=chain-2026-0441, step_id=step-003, reason="Counterparty not on approved-affiliates list; refer back to finance team for review")` → rejected_outcome. Quorum evaluation: `R = 1 ≥ 1`; under all-of-N the chain transitions to **Rejected** with reason `"quorum unreachable: all-of-N; 2 remain achievable; rejections present"`. `chain_terminal_at` is set; the audit trail records the chain resolution. JE-2026-0441 is not released for posting; the composing workflow routes the entry back to the controller, who must initiate a new chain for the corrected entry (a fresh chain_id, fresh step ids — no editing of the rejected chain's records).

### Rejection path — chain withdrawal by initiator

In an alternative history of the same chain, the controller submitting JE-2026-0441 discovers a clerical error in the entry before any approver has decided: the chain was opened against the wrong subject. The controller calls `withdraw_chain(actor_ref=controller_morgan, credential=morgan_credential, chain_id=chain-2026-0441, reason="Wrong journal entry id; superseded by new chain on JE-2026-0441-revised")`. The chain transitions to Withdrawn; each of the three still-Pending steps cascades to Approval Step's Withdrawn state; each Assignment is recalled; the audit trail records the chain withdrawal and the three step withdrawals. A new chain is initiated on the corrected entry.

### Selected outcome runs

Three one-paragraph runs over branches the walkthroughs above do not reach — chosen because each exercises a surface the composition's defenses turn on: the withdrawal-driven cascade, the trailing-decision discipline, and the partial-cascade recovery.

**Chain-Withdrawn-by-cascade — a step withdrawal makes quorum unreachable with no rejection.** A three-approver `M-of-N(2)` engineering change chain has one approval in (`A=1`) when the initiator discovers the second gate names the wrong reviewer and calls `withdraw_step(actor_ref=initiator_ross, credential=ross_credential, chain_id=chain-ec-118, step_id=step-b, reason="Wrong reviewer named; superseding chain to follow")`, then realizes the third gate is mis-scoped too and withdraws it the same way. On the second withdrawal the rule reads `A=1, R=0, W=2`: `(N−R−W)=1 < M=2 ∧ R=0 ∧ W≥1` — quorum unreachable purely by withdrawal — so the chain transitions to **Withdrawn**, not Rejected: no approver made a negative decision, and the terminal state says so. The state is set first; there are no still-Pending steps left to cascade-withdraw (`recalled_step_ids = []` on the `chain_resolved` event, whose `data.state = Withdrawn` marks this as the cascade path, distinct from a `chain_withdrawn` event's initiator path); the one approval already recorded stays immutable.

**A trailing decision — the third Qualified Person approves after the chain closed.** Continuing the batch-release example: two days after `chain-2026-0412` reached Approved on the second approval, QP Kim reviews the batch anyway and calls `approve_step(actor_ref=qp_kim, credential=kim_credential, chain_id=chain-2026-0412, step_id=step-kim, reason="Independent review complete; concur")`. Resolution finds the chain terminal — the call is *not* refused (the step's own Pending state is the gate) — and computes `trailing = true`. The atom records the approval, the already-Recalled assignment's recall returns `not-active` (idempotent success), and the audit event lands as `step_approved` with `trailing = true`, `cascade = false`. The chain evaluation does not run: no re-evaluation, no second `chain_resolved`, `chain_store` untouched. An auditor later walking the trail sees a `step_approved` after the chain's `chain_resolved` and reads the flag, not a contradiction.

**A partial cascade and its recovery, closed from the records.** An `all-of-N` chain of four is withdrawn by its initiator moments after it opened (chain **Withdrawn**). The cascade must withdraw four Pending steps; Approval Step refuses the third with its temporal invalid-request, its reading of the withdrawal a moment before that step's submission instant under cross-seam skew. The composition proceeds (no abort), sets nothing back, recalls the four assignments, and emits `chain_withdrawn` with `cascade_partial = true` naming the third withdrawal; the caller still receives withdrawn — the load-bearing transition succeeded. [Read Chain] now shows a terminal chain with one still-Pending step: the surfaced residue. At the next restart the recovery discipline retries, the withdrawal lands under a later reading, and a `cascade_completed` event (composition actor) referencing the chain closes the marker. The auditor's closure procedure — match the failure to its `cascade_completed` — is Check 5.4, run here on a one-element list.

### Regulated adversarial scenarios

Three adversarial reads the composition must survive in regulated contexts:

- **Regulator audit — SOX section 404 control evidence query, "show me every chain that approved a material journal entry in Q1 with full attribution."** The auditor queries `read_chain({scope: "financial:journal-entry:post:materiality-tier-3", state: Approved, initiated_at: {start: "2026-01-01T00:00:00Z", end: "2026-03-31T23:59:59Z"}})`. Every chain in the result set carries its approver set, its quorum rule, its constituent step records (with `decided_by` matched to `approver_ref` by Approval Step Invariant 4), and its Audit Trail attestations under the seven-year retention. The auditor independently computes the expected chain state from the step records and the quorum rule and confirms Invariant 2 holds: no chain reached Approved without the quorum-named decisions actually present. The auditor also queries `read_chain({scope: "...:tier-3", state: Pending, initiated_at: {start: ..., end: ...}})` to verify no chain was left unresolved — a non-empty result identifies a stalled material chain — lawful here, since a chain has no deadline (Non-goal 6), and a question for the deployment's deadline policy. The covered entity has documentable, provable control evidence.

- **Disputed approval — FDA Part 11 electronic signature challenge against a chain participant.** An FDA investigator reviewing batch BR-2026-0412 challenges the authenticity of QP Lopez's approval: the actor claims they did not approve the batch. The investigator queries `read_chain({subject_ref: "br-2026-0412"})` and retrieves the chain plus its step records. Step `step-lopez-0412` shows `decided_by: "qp_lopez"`, `decided_at: "2026-04-15T16:04:00Z"`, `decision_reason: "Specification limits met; COA (Certificate of Analysis) reviewed"`. Approval Step Invariant 4 guarantees that the *value* `qp_lopez` was presented and matched `approver_ref` at decision time — that atom takes no credential, and its identity model is byte equality on the reference as supplied, so the record alone does not establish who presented it. What does is the `step_decision_intended` record that **preceded** the decision and the Actor Identity attestation on it: the principal Lopez presented material matching the registry's public material for that reference before the step could be decided (Invariant 10). The bound is the honest one — a stolen credential validates — so the records establish that Lopez's credential was used, not that Lopez was at the keyboard. The Audit Trail's Actor Identity attestation for the corresponding `step_approved` event is then verified against `qp_lopez`'s registered public material at the attestation's own `attested_at` — the substrate's stamp, not Approval Step's `decided_at`, which is another seam's reading. The denied-approval claim cannot be sustained against the structural record without claiming credential compromise; that reinterpretation is the **Compromise Disclosure** *(forthcoming)* composing pattern's responsibility, not the chain composition's.

- **Breach or incident forensics — unauthorized chain initiation investigation.** During a security incident review, the incident response team needs to determine whether any chains were initiated by actors who should not have held `chains:initiate` during a window of suspected privilege escalation (2026-05-01T00:00:00Z through 2026-05-03T23:59:59Z). The team queries `read_chain({initiated_at: {start: ..., end: ...}})` and, for each chain in the window, walks the Audit Trail back to the `chain_initiated` event and verifies its Actor Identity attestation. The team also queries the Permissions records for grants of `chains:initiate` active during the same window; any initiator whose grant was not active at `initiated_at` is a finding — judged under the deployment's operating skew: the grant stamps and `initiated_at` are two seams' readings, so the audit condemns only violations wider than that skew and reads boundary-width discrepancies as inconclusive (Invariant 3's check-time enforcement is the gate; this audit reads its evidence trail). The chain composition's records faithfully document every initiation and outcome; the cross-record verification — initiator attestation vs. Permissions grant state at the initiation timestamp — is the audit operation that surfaces unauthorized chains.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when the checks below are provable to an external auditor given the composition's emergent state and the constituent records. Every enumeration of audit events runs through the log read; every check that walks events runs inside the audit horizon.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY quiescent chain's step list complete PER Invariant 1.1 AND Invariant 1.2 (Invariant 1.1).
Check 1.2: An auditor MUST find EVERY step id in a step list naming an Approval Step record the step-chain index maps back to the chain (Invariant 1.4).
Check 2.1: An auditor MUST find EVERY resolution-terminated chain's chain state equal to the quorum rule's answer on the chain's routed vector (Invariant 2.1).
Check 2.2: An auditor MUST find the quorum rule answering Pending on EVERY withdrawal-terminated chain's pre-withdrawal vector (Invariant 2.2).
Check 2.3: An auditor MUST NOT run Check 2.1's recomputation on a withdrawal-terminated chain (Invariant 2.2).
Check 3.1: An auditor MUST find the initiator of EVERY initiation event holding [Chains Initiate] at the initiated instant, within the operating skew (Invariant 3.1).
Check 3.2: An auditor MUST find the actor of EVERY withdrawal event holding [Chains Withdraw] at the terminal instant, within the operating skew (Invariant 3.2).
Check 4.1: An auditor MUST find EVERY quiescent chain's assignments PER Invariant 4.1 AND Invariant 4.2 (Invariant 4.1).
Check 4.2: An auditor MUST read an Active assignment under an open partial flag as an open marker (Invariant 4.2).
Check 5.1: An auditor MUST find EXACTLY ONE audit record for EVERY committed transition on a quiescent chain (Invariant 5.1).
Check 5.2: An auditor MUST find EVERY chain namespace event other than an intent naming a chain the chain records carry (Invariant 5.2).
Check 5.3: An auditor MUST find the service identity attesting EVERY resolution event, closure record, initiation-failed record, recovery intent AND recovery-flagged event, AND nothing else (Capability requirement 12).
Check 5.4: An auditor MUST find a closure record for EVERY call a partial flag names on a quiescent chain (Reconciliation 30).
Check 6.1: An auditor MUST clear Approval Step's Generation acceptance over the Approval Step instance (Composes 5).
Check 6.2: An auditor MUST clear Permissions' Generation acceptance over the Permissions instance (Composes 5).
Check 6.3: An auditor MUST clear Assignment's Generation acceptance over the Assignment instance (Composes 5).
Check 6.4: An auditor MUST clear Audit Trail's Generation acceptance over the Audit Trail instance (Composes 5).
Check 7.1: An auditor MUST find EXACTLY ONE terminal event for EVERY terminal chain, carrying the chain's stored chain state AND terminal instant (Invariant 7.1).
Check 7.2: An auditor MUST find no chain id two resolution events carry (Invariant 7.3).
Check 8.1: An auditor MUST find EVERY chain record's declared fields equal to the chain shape the chain's chain-shape event carries (Invariant 8.1).
Check 10.1: An auditor MUST resolve EVERY outcome's intent event id to an intent that PRECEDES the outcome in the Event Log sequence AND names the same actor (Invariant 10.1).
Check 10.2: An auditor MUST resolve EVERY initiation intent to a chain record through the invocation id (Invariant 10.1).
Check 10.3: IF an outcome carries intent candidates THEN an auditor MUST find EVERY candidate naming the acting actor reference AND preceding the outcome AND a recovery intent naming the same candidates preceding the outcome (Reconciliation 21).
Check 10.4: An auditor MUST NOT join an outcome to an intent by any key weaker than the intent event id (Invariant 10.1).
Check 10.5: An auditor MUST NOT read an intent carrying no outcome as a conformance failure (Reconciliation 17).
```

NOTE: EVERY check names the rule the check tests.

Term resolution-terminated chain: a chain whose terminal event is a resolution event.

Term withdrawal-terminated chain: a chain whose terminal event is a withdrawal event — withdrawn by its initiator, or by the initiation recovery.

### External checks

```
External check 1: An auditor needing a reader's identity confirmed MUST read the calling layer's authentication evidence (Invariant 3.3).
External check 2: An auditor needing the approver set's policy fit confirmed MUST read the calling system's policy declaration (Non-goal 4).
External check 3: An auditor needing an approver's standing authorization confirmed MUST read the deployment's standing-authorization registry at the initiated instant (Non-goal 5).
External check 4: An auditor needing a chains initiate grant's appropriateness confirmed MUST read the Permissions-administration layer (Invariant 3.1).
External check 5: An auditor needing an escalated marker's resolution confirmed MUST read Audit Trail's alerting surface (Reconciliation 32).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT evaluate a quorum rule outside [All Of N], [M Of N] AND [One Of N].
Non-goal 2: The composition MUST NOT order the approvals within a chain.
Non-goal 3: The composition MUST NOT admit a delegate's decision on a named approver's step.
Non-goal 4: The composition MUST NOT judge an approver set's fit to the subject.
Non-goal 5: The composition MUST NOT check an approver's standing authorization for the scope.
Non-goal 6: The composition MUST NOT expire a chain.
Non-goal 7: The composition MUST NOT notify an approver.
Non-goal 8: The composition MUST NOT relate two chains on one subject.
Non-goal 9: The composition MUST NOT record a pre-intent refusal.
Non-goal 10: The composition MUST NOT re-open a decided step under the step's chain.
Non-goal 11: The composition MUST NOT authenticate a reader.
Non-goal 12: The composition MUST NOT serve an assignee-keyed in-tray view.
Non-goal 13: The composition MUST NOT refuse an approver set naming the initiator reference.
Non-goal 14: The composition MUST NOT administer a Permissions grant.
```

Term pre-intent refusal: a refusal an action answers ahead of its intent — validation, permission, and at [Withdraw Chain] an unknown chain, not-pending and an initiator mismatch.

NOTE: the owners — other compositions, and a Sequenced Approval Chain *(forthcoming)* for ordering (Non-goal 1, Non-goal 2); a Delegation pattern *(forthcoming)* (Non-goal 3); a composing Permissions layer, the calling system and the governance layer (Non-goal 4, External check 2; Non-goal 5; Non-goal 13); the Permissions-administration layer (Non-goal 14, External check 4); a composing scheduler or a Deadline Escalation pattern *(forthcoming)* (Non-goal 6); [Notification](../atoms/notification.md) and [Notification Fanout](./notification-fanout.md) (Non-goal 7); a higher-order policy (Non-goal 8); a Failed-Attempt Log *(forthcoming)* (Non-goal 9); the calling layer (Non-goal 11, Capability requirement 25, External check 1); a Reverse Index *(forthcoming)* lookup the deployment builds (Non-goal 12).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the Event Log sequence as the order of an intent AND the intent's outcome.
Clock semantics 2: The composition MUST NOT compare the terminal instant with a step's decided instant.
Clock semantics 3: The composition MUST NOT pass an instant to a constituent.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for a decision's step write to run outside.
```

### Retention asymmetry

```
Retention asymmetry 1: The composition MUST keep an aged chain's chain record AND step records.
Retention asymmetry 2: An auditor MUST read failed-verification carrying purged on a chain's event as lawful destruction.
```

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are its six actions — [Initiate Chain], the three step decisions [Approve Step], [Reject Step] and [Withdraw Step], [Withdraw Chain] and [Read Chain]; the [Trailing] flag; the three scopes it defines for its Permissions instance, [Chains Initiate], [Chains Withdraw] and [Chains Read]; the three quorum rules [All Of N], [M Of N] and [One Of N]; and the refusals it names, [Permission Denied] and [Recording Failure]. The chain states overload Approval Step's step states and are declared, not carded. The deployment settings keep their wire spellings in configuration — `approver_set_minimum`, `approver_set_uniqueness`, `quorum_rule_allowed`, `audit_trail_retention_policy`, `decision_completion_bound`, `compensation_window`, `reconciliation_cadence`, `application_actor_ref`, `application_credential` — and the record sets their own in an implementation, `chain_store`, `chain_to_steps`, `step_to_chain`, `step_to_assignment`, `chain_to_events`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the sweep; the initiation leg; the transition leg; the initiation recovery; the chain evaluation; the quorum rule; a cascade; a rebuild; a deployment; a deployment composing Legal Hold; a deployment needing reader authentication; an auditor; a caller; an invocation; a validated initiation; a permitted initiation; an admitted initiation; a submitted initiation; a staffed initiation; a landed initiation; a resolved decision; an admitted decision; a decided decision; a landed decision; a decision action; a terminating evaluation; a validated chain withdrawal; an open chain withdrawal; an admitted chain withdrawal; a landed chain withdrawal; a validated read; a permitted read; a reason-bearing action.

Term records: the chain records and the four indexes' entries; the intents, outcomes, resolution events, initiation-failed records, closure records and recovery intents the composition records through the audit write — each an Event Log event carrying one action reference of the chain namespace; and the steps and assignments it writes through Approval Step and Assignment.

Term record verbs: EQUAL, administer, admit, alert, answer, append, attest, authenticate, bind, call, carry, change, check, classify, clear, commit, compare, compose, compute, count, decide, declare, define, disclose, evaluate, examine, expire, expose, find, gate, inherit, inject, inspect, join, judge, keep, list, mark, match, name, normalize, notify, open, order, page, pass, place, proceed, provision, re-emit, re-open, reach, read, rebuild, recall, record, refuse, relate, remove, resolve, retain, retire, retry, run, select, serve, set, stamp, start, store, supply, write.

Term value sets: chain state, disposition, closure mark, decision, position and the quorum rule are declared where the section that owns each declares it.

Term bounds: decision completion bound (decision_completion_bound), outcome write latency (outcome_write_latency), approver set minimum (approver_set_minimum), field length cap, id widths, operating skew, compensation window (compensation_window), audit horizon (audit_trail_retention_policy).

Term cadences: reconciliation cadence (reconciliation_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive atoms, log read, record read, audit write, verification, step write, chain namespace, chain records, chain record, declared fields, chain id, chain state, terminal instant, quarantine flag, landed ids, step list index, step-chain index, step-assignment index, event index, index entry, chain-shape event, chain shape, open initiation window, source event, live index entry, purged index entry, chain rebuild, event rebuild, assignment history, approver set minimum, approver set uniqueness, allowed quorum rules, audit retention policy, audit horizon, decision completion bound, compensation window, reconciliation cadence, outcome write latency, liveness sum, service identity, invocation id, seam, now, id widths, operating skew, reference, capped string, actor reference, subject reference, scope, approver set, approver reference, quorum rule, quorum count, valid quorum counts, reason, reason-bearing action, field length cap, larger payload, payload budget, credential, intent, outcome, retention step, read-back, position, chain results, query, minted id, prefixed reason, initiation intent, initiation event, decision intent, withdrawal intent, approval event, rejection event, step withdrawal event, withdrawal event, resolution event, decision's outcome, decision, decision's step write, step refusal, intent event id, intent instant, initiated instant, acting actor reference, trailing flag, cascade flag, partial flag, recovery flag, validated initiation, permitted initiation, admitted initiation, submitted initiation, staffed initiation, landed initiation, unlanded initiation, resolved decision, admitted decision, decided decision, landed decision, decision action, chain evaluation, terminating evaluation, validated chain withdrawal, found chain withdrawal, open chain withdrawal, admitted chain withdrawal, landed chain withdrawal, validated read, permitted read, routed vector, approved count, rejected count, withdrawn count, met vectors, lost vectors, open vectors, routed transition, out-of-band transition, out-of-band mark, rule reason, sweep, initiation leg, transition leg, owed terminal event, aged chains, aged chain, settled step, late-recalled steps, initiation recovery, disposition, initiation-failed record, chainless step, recovery reason, intent candidates, closure record, superseded mark, closure mark, recovery intent, open marker, escalation instant, opening instant, transient arm, deterministic arm, cascade, cascade reason, recalled step ids, quiescent chains, quiescent chain, recovery-closed chains, pre-withdrawal vector, open steps, audit record, committed transition, lifecycle, resolution-terminated chain, withdrawal-terminated chain, pre-intent refusal.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. The section titled Structural-relation invariant templates in `spec-format.md` — the three relations. record_action, read_record, verify_record, payload cap, reference length cap, attestation id width, step-2, step-3, step-4, invalid-credential, invalid-request, recording-failure, verified, failed-verification, purged, Retained, Purged, committed ids, alerting surface, Erasure Tombstone, Reverse Index, Failed-Attempt Log, Trusted Timestamping, Compromise Disclosure: Audit Trail. submit, approve, reject, withdraw, read, submitted_at, decided_by, withdrawn_by, approved, rejected_outcome, withdrawn, Pending, Approved, Rejected, Withdrawn, invalid-request, not-known, not-pending, unauthorized, storage-failure, invalid-query: Approval Step. assign, recall, active_for, history_for, ok, not-active, already-assigned, Active, Recalled: Assignment. permitted, denied: Permissions. read: Event Log. Sequenced Approval Chain, Delegation, Deadline Escalation, Outbox: forthcoming.

Term composing patterns: [Privileged Access Provisioning](./privileged-access-provisioning.md); [Execute Gated Workflow](./execute-gated-workflow.md); [Notification](../atoms/notification.md); [Notification Fanout](./notification-fanout.md); [Legal Hold](../atoms/legal-hold.md); [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md).

#### Initiate Chain

The composition action that creates an approval chain over one subject and scope: it validates the chain shape against the deployment's quorum-rule and approver-set knobs, records `chain_initiation_intended` — the write that verifies the initiator's credential, before anything is created — then submits one Approval Step per named approver, binds each to the approver's in-tray, and audits the chain (`chain_initiated`). Gated by [Chains Initiate]. Returns the chain_id; the chain is now Pending.

Kind: Operation

#### Approve Step

The composition action wrapping one approver's Approval Step approval: it records `step_decision_intended` first — the write that verifies the caller's credential, and the only thing standing between an asserted actor reference and a committed approval, since this action has no Permissions check — then on success recalls the in-tray binding, audits the decision (`step_approved`, tagged with [Trailing]), and — unless the decision is trailing — re-evaluates the quorum rule, terminating the chain if quorum is now met.

Kind: Operation

#### Reject Step

The composition action wrapping one approver's Approval Step rejection: it records `step_decision_intended` first (verifying the caller's credential), then on success recalls the in-tray binding, audits the decision (`step_rejected`) and re-evaluates the quorum rule, which may transition the chain to Rejected when quorum becomes unreachable.

Kind: Operation

#### Withdraw Step

The composition action by which the chain initiator withdraws a single mis-submitted gate (wrong approver or scope) through Approval Step — recording `step_decision_intended` first, which verifies the initiator's credential before the withdrawal commits, without retracting the whole chain where quorum remains achievable (a withdrawal that alone makes quorum unreachable cascades the chain to Withdrawn) — audited (`step_withdrawn`) and counted toward quorum-unreachability alongside rejections.

Kind: Operation

#### Withdraw Chain

The composition action by which the chain initiator retracts the whole chain while still Pending. It checks the initiator, records `chain_withdrawal_intended` (verifying the initiator's credential), sets the chain terminal, cascade-withdraws every still-Pending step — auditing each (`step_withdrawn`, `cascade = true`) — recalls their in-tray bindings, and audits the withdrawal (`chain_withdrawn`). Gated by [Chains Withdraw].

Kind: Operation

#### Read Chain

The read-only query returning chain records and their composed step / assignment / attestation surface — the chain's audit `event_id`s from `chain_to_events` included, and the `audit_pending` quarantine flag when set — in declared order (ascending `initiated_at`, tie-broken by chain_id). Gated by [Chains Read]; produces no audit event and takes no credential.

Kind: Operation

#### Trailing

The flag the composition records on every step-decision audit event: `true` when the decision lands on a step whose chain had *already* reached a terminal state (a permitted late decision), `false` otherwise. It is the audit-distinguishing signal that makes a late decision provably distinct from an on-chain one — without it a `step_approved` event after the chain's `chain_resolved` reads as a contradiction. Its sibling flag cascade (backticked, not carded) marks the composition's own cascade-emitted step withdrawals; the two never overlap — a cascade record is part of the termination (`trailing = false`), a trailing record comes after it (`cascade = false`).

Kind:       Field
Field of:   the step-decision audit event
Role:       the late-decision audit flag
Projection: trailing

#### Chains Initiate

The scope permitting [Initiate Chain] — create a new approval chain.

Kind:       Member
Member of:  the chain scope vocabulary
Role:       Scope
Projection: chains:initiate

#### Chains Withdraw

The scope permitting [Withdraw Chain] — withdraw a chain (the chain initiator's act).

Kind:       Member
Member of:  the chain scope vocabulary
Role:       Scope
Projection: chains:withdraw

#### Chains Read

The scope permitting [Read Chain] — read chain records and their composed step, assignment, and attestation surface.

Kind:       Member
Member of:  the chain scope vocabulary
Role:       Scope
Projection: chains:read

#### All Of N

The quorum rule requiring every named approver to approve: the chain is Approved when `A == N`, and Rejected the moment any step is rejected.

Kind:       Member
Member of:  the quorum rule
Role:       Quorum rule
Projection: all-of-N

#### M Of N

The quorum rule requiring any M of the N named approvers (with `1 ≤ M ≤ N`): the chain is Approved when `A ≥ M`, and Rejected once fewer than M steps remain achievable with a rejection present.

Kind:       Member
Member of:  the quorum rule
Role:       Quorum rule
Projection: M-of-N

#### One Of N

The quorum rule requiring any single approver (the `M = 1` case of [M Of N]): the first approval Approves the chain.

Kind:       Member
Member of:  the quorum rule
Role:       Quorum rule
Projection: one-of-N

#### Permission Denied

The composition's rejection when the acting actor lacks the required chain scope at the Permissions check in [Initiate Chain], [Withdraw Chain], or [Read Chain]. (Step decisions are not chain-layer permission-gated — Approval Step's own approver and submitter exclusivity is the enforcement.)

Kind:       Member
Member of:  the chain rejection
Role:       Rejection
Projection: permission-denied

#### Recording Failure

The composition's rejection for a constituent `storage-failure` or an Audit Trail `record_action` failure surfaced at the composition boundary, carrying its position — intent, nothing committed and the action retryable in whole; outcome, the act committed and its audit record the sweep's — the failure the partial-state recovery paths and the `audit_pending` quarantine address. invalid-credential is not folded into it: a credential the substrate refuses surfaces under its own code. Nor is a failed read: a constituent's state-unavailable passes through unchanged and writes nothing (Execution Contract Read 1 through 3).

Kind:       Member
Member of:  the chain rejection
Role:       Rejection
Projection: recording-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Initiate Chain]: #initiate-chain
[Approve Step]: #approve-step
[Reject Step]: #reject-step
[Withdraw Step]: #withdraw-step
[Withdraw Chain]: #withdraw-chain
[Read Chain]: #read-chain
[Trailing]: #trailing
[Chains Initiate]: #chains-initiate
[Chains Withdraw]: #chains-withdraw
[Chains Read]: #chains-read
[All Of N]: #all-of-n
[M Of N]: #m-of-n
[One Of N]: #one-of-n
[Permission Denied]: #permission-denied
[Recording Failure]: #recording-failure

---

## Standards references

This composition is the structural form of what every multi-actor regulatory approval regime requires:

- **Sarbanes-Oxley section 404 (15 U.S.C. (United States Code) section 7262) — Internal control over financial reporting.** Material financial actions require multi-actor approval; SOX auditors query the approval chain to confirm the control existed and operated. The composition is the structural form. Composes with Audit Trail's SOX section 802 retention obligation (7 years).
- **FDA 21 CFR Part 211 (Current Good Manufacturing Practice for Finished Pharmaceuticals)** — batch release requires authorization by a Qualified Person (QP) or equivalent designated authority. Multi-QP releases under M-of-N(M) quorum are the canonical composition for high-value batches and for batches requiring QA-plus-QP dual signoff.
- **FDA 21 CFR Part 11 (Electronic Records; Electronic Signatures)** — each approval in a chain is an electronic signature event. Part 11 section 11.50 requires signatures be attributable; section 11.70 requires they be linked to records to prevent removal, substitution, or falsification. The composition's Audit Trail substrate (with Actor Identity providing the cryptographic binding and Tamper Evidence providing the linking) satisfies both.
- **ICH E6(R3) Good Clinical Practice — Guideline.** Sections 4–5 require documented approvals at multiple points in the trial lifecycle, often by multiple parties (investigator, sponsor, IRB). One-of-N over a delegated PI pool is a recurring composition shape for non-substantive deviations; M-of-N is the form for substantive deviations requiring both PI and sponsor approval.
- **ISO 9001:2015 clause 8.5.1 (Control of production and service provision)** and **clause 7.5.3 (Control of documented information)** — the International Organization for Standardization's quality-management standard; controlled changes require approval by named authorities. Multi-party chains map to ISO 9001 documented-procedure approval requirements.
- **ISO 13485:2016 clause 7.3 (Design and development)** — medical device design changes require multi-disciplinary approval (design lead, quality, regulatory affairs, often clinical). M-of-N quorum is the structural form.
- **SOC 2 (System and Organization Controls 2 — the Trust Services Criteria attestation framework; Control Activities, Common Criteria CC2.1, CC8.1)** — changes to data, infrastructure, or business processes require documented multi-party approval; SOC 2 audits query the approval chain as control evidence. The composition is one structural form.
- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-53 Rev. 5 (AC-5 Separation of Duties; CM-3 Configuration Change Control)** — multi-actor approval is the operational form of separation of duties for change control. The composition is the structural form.
- **PCI DSS (Payment Card Industry Data Security Standard) Requirement 6.5.3 (Production data must not be used for testing or development) and 6.4.5 (Change control procedures)** — production changes require documented multi-party approval.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the composition discipline: the per-gate atom is freestanding; the chain is the composing pattern that wires N gates under a quorum rule.
- **Approval chain literature in change-control and regulatory engineering** — every major change-management framework (ITIL (Information Technology Infrastructure Library) change advisory boards, FDA design-control reviews, SOC change-control gates) names multi-party approval as the structural form; the composition is the formal version.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — multi-party-approval.tla + 8 twins + 7 probes, 2026-10-26
last gate: 2026-10-29 — Final Critique 13 — foundational count 2, not clean, no sample

open:
- 2026-08-29-u · refining · formal · multi-party-approval.tla models no audit write, so no model checks that the sweep's recovery intent lands before its closure (Reconciliation 28, 29) → model the audit writes the sweep orders
- 2026-10-26-a · refining · Reconciliation 21, Term chain results, Term intent candidates · a re-emitted outcome's intent candidates and a read's chain results are lists with no bound, and the payload budget sizes no candidate list → bound each, or size the candidates with the outcome
- 2026-10-26-b · refining · Action wiring 62 · [Initiate Chain]'s recording-failure carrying outcome carries no chain id to read the committed act back by → carry the chain id on the refusal, or name how a caller finds the chain
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/multi-party-approval.md`; the migration that got it here is in [its history](./multi-party-approval.hist.md).

- **2026-10-20 — The store's guarantees cited, not restated, the chain exclusion among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 26), and the twenty-eight rules that restated it, or existed only for a store that could lose or split a write, tombstoned to their owner — the chain store durability the deployment declared and persisted by (Capability requirement 4, Composition state 19), to Store 3 and Store 4; the chain exclusion the host supplied (Capability requirement 15) and every rule holding it across an evaluation, a withdrawal or the sweep's pre-check (Action wiring 33, 42, Reconciliation 6, Concurrency 1, 2), its release on the holder's return and death and at every answer, the bar on running without it, the sweep's skip of a held chain and the bar on serializing two decisions ahead of their evaluations (Capability requirement 16, 17, 18, Action wiring 58, Reconciliation 7, Concurrency 3), and the mid-flight revocation of a credential the intent validated (Audit arm 12), to Store 2; and to Store 1, under which an action's intent, constituent writes, cascade and outcome commit together, the initiation's exclusion that kept the sweep off it (Action wiring 5), the decision's own failed recall riding on its outcome (Action wiring 27), [Withdraw Chain]'s evaluate-first gate, the evaluation leg and its place ahead of the initiation leg (Action wiring 43, Reconciliation 3, 23), the sweep's lower edge (Reconciliation 4), the chainless-step scan (Reconciliation 14), the re-run of a skipped recall and evaluation (Reconciliation 22), the recall leg for calls no partial flag names (Reconciliation 24, 25), the rebuild's hand-off of a retained record to the initiation leg (Composition state 14, 15), and the read-back of a recording-failure at step 4, a split Audit Trail's own rewrite removed (Audit arm 6); with them a submit's or an assign's storage-failure no longer runs the initiation recovery (Action wiring 9, 12) and a decision's outcome carries no partial flag (Action wiring 29); rules 285 to 258. *Over:* a host exclusion on each chain, held across every evaluation, withdrawal and sweep write and released on its holder's return or death; a sweep bounded below by the decision completion bound; and legs that recovered an evaluation, a recall or a cascade withdrawal a crash had lost — the lower edge and the evaluate-first gate are turns of 2026-08-29, below. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice: every write this composition's actions make is a store write, its cascade's included, so Store 2 reads what an evaluation or a withdrawal decides on inside the transaction that writes it, which is what the exclusion was for, and no crash leaves half an action for a leg to find. The initiation recovery, the quarantine, the transition leg's re-emission and the partial-flag retry stay on the refusals that still reach them — a constituent's invalid-request or already-assigned, a refused outcome, a retired service credential, Audit Trail's no-answer arms and Approval Step's temporal invalid-request on a cascade withdrawal; the rebuild still retains every record it cannot produce (Composition state 13), and the decision completion bound stays in the liveness sum (Capability requirement 7, 11). What the composition does for its domain is unchanged.
- **2026-08-29 — The sweep is bounded below as well as above, names candidate intents rather than declaring them unrecoverable, and records its intent before it commits.** *Chose:* `decision_completion_bound` as the transition sweep's lower edge (the horizon it already carried as its upper), `compensation_window` and `reconciliation_cadence` declared; `intent_event_candidates` on every re-emitted record in place of `intent_event_id_unrecoverable = true`; a `chain.recovery_intended` record before every closure that recalls, withdraws, resolves, or re-emits; the cross-store edge case's "atomically or" restated as ordered. *Over:* a sweep whose lower edge was the store-against-events comparison alone, and a flag that said the pairing was unknowable when the records name the candidates. *Because:* the comparison cannot see an invocation that has not written yet, so a sweep inside the bound lands a second outcome for one decision; the candidates are on the trail and naming them is what the pairing rule asks for; and a recall or withdrawal the sweep performs with no record of its own is indistinguishable from a direct call (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*, *Recovery commits under a declared service identity*).
- **2026-08-29 — Recovery is horizon-bounded, evaluate-first, and keyed on the chain's own id.** *Chose:* the initiation leg and the additive rebuild's quarantine apply only inside the audit horizon, with post-horizon chain records declared truth-bearing under `chain_store_durability`; every recovery withdrawal runs the evaluate-first gate and the evaluation leg runs before the initiation leg; each step's stored reason carries its chain_id so the case-(a) scan is exact; every cascade arm is landed with the in-invocation not-pending closing as a supersession. *Over:* an unbounded initiation leg, a recovery that withdrew without evaluating, a scan keyed on subject and initiator, and a cascade whose arms were enumerated only for `storage-failure`. *Because:* the unbounded leg withdrew every lawfully purged chain at each restart; the ungated recovery overturned credential-verified approvals in the initiator's name; the subject-keyed scan withdrew a concurrently-initiating sibling's step; and the unenumerated arms gave check 2(b) two opposite verdicts on one history.
- **2026-08-26 — Invariant 4 is safety plus liveness at quiescence, not a static always-claim.** *Chose:* the assignment-cascade claim holds at quiescence conditioned on no open recovery marker, with the partial-cascade and step-7 windows named as bounded surfaced transients; check 4 audits under the same structure. *Over:* the static "always both sides" statement. *Because:* the partial-cascade and trailing-decision paths the spec itself describes reach and violate the static form.
- **2026-08-26 — Recovery emissions are composition-attributed and the retry loop runs only on transient failure.** *Chose:* every record emitted outside the original human invocation attests under `application_actor_ref` with the human in `data` and `recovery = true`; invalid-request foreclosed by budget-derived caps; one vocabulary shared with Execute Gated Workflow. *Over:* re-presenting human credentials on retry, or looping on every rejection. *Because:* a human credential is unavailable to a recovery path, and a deterministic rejection retried forever is a stall.

</details>

NOTE: End of Multi-Party Approval.
