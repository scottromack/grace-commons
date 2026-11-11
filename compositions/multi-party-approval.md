---
title: Multi-Party Approval
id: 4
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

Multi-Party Approval enforces an approval requiring several named approvers, over a single thing, in a way that cannot be bypassed through the composition and is provable.

The rule for how many approvers are needed is a quorum rule — all of them, a majority, or any one of them. It combines four patterns, and the fifth, Recoverable Invocation, is the protocol each change follows: the single-approver gate (Approval Step), a permission system controlling who may start, withdraw, or read an approval chain (Permissions), a task-tracker that puts each pending approval in the right approver's queue (Assignment), and the tamper-evident audit record (Audit Trail) that stamps and seals every step. Each action that changes a chain follows [Recoverable Invocation](./recoverable-invocation.md): an audit intent before the change, an audit outcome after it, and a sweep that recovers the outcome of a change whose record never landed — so a change is never left both made and unrecorded without that standing visible.

The load-bearing addition is checking, after each individual decision, whether the quorum has now been met or has become impossible, and ending the chain accordingly — something none of the parts can do, because the single-gate pattern does not count approvals across steps and the others know nothing about quorum at all.

The check is deterministic: anyone with the records can recompute the chain's outcome from the individual decisions and the quorum rule and confirm it. That is what makes the gate impossible to bypass through the composition — a chain cannot reach "approved" unless the required decisions are actually present in the records, and a decision made around the composition is marked and alarmed, never counted (Wiring decision 7, Wiring decision 8, Reconciliation 20).

Once a chain ends, its outcome and its declared terms cannot change; corrections require a new chain. This is the mechanism behind dual-sign-off financial controls, pharmaceutical batch releases, electronic-signature chains, clinical-trial approvals, and change-control gates — any decision that must make it provable that a required set of named approvers actually decided before an action proceeded is a candidate for this composition.

---

## Intent

Many regulated actions require more than one human approval before they may proceed. A SOX-controlled (Sarbanes-Oxley Act — US corporate financial-reporting law) journal entry above a materiality threshold requires the regional finance director, the CFO (Chief Financial Officer) *and* the CEO (Chief Executive Officer). A pharmaceutical batch release under the FDA's (the US Food and Drug Administration's) 21 CFR (Code of Federal Regulations — the codification of US federal agency rules) Part 211 requires the qualified person on duty plus the QA (Quality Assurance) director. A clinical protocol deviation under ICH E6 GCP (the International Council for Harmonisation's E6 Good Clinical Practice guideline) requires the principal investigator plus, for substantive deviations, the IRB (Institutional Review Board — the committee that oversees research ethics) chair. A high-value engineering change order requires the engineering lead, the quality lead, and (when safety-critical) the safety officer. In each case the structure is the same: a set of named approvers, a quorum rule (all of them, a majority of them, any one of them), and a terminal decision that becomes the auditable evidence the control operated.

[Approval Step](../atoms/approval-step.md) is the per-gate primitive — one named approver, one subject, one scope, one decision. It deliberately does not know about chains: it does not count approvals, does not interpret quorum, and does not wire multiple gates together. Multi-Party Approval is the composition that does. The atom's single-gate scope is preserved unchanged; the composition adds the chain identity, the quorum rule, the cross-step state evaluation, and the cascade (secondary effects triggered automatically by a primary event) behavior when a chain is withdrawn or quorum becomes unachievable.

The composition addresses what the constituent atoms cannot answer alone. Approval Step records each gate but never asks *"is the chain done?"* Permissions records who may initiate a chain but never asks *"did the quorum's named approvers actually decide?"* Assignment binds work to actors but never asks *"is the work part of a multi-actor gate?"* Audit Trail records actions of consequence but never asks *"do these actions constitute a complete approval chain under the named rule?"* Stacked correctly, the four answer the auditor's actual question in one structure: a chain identity that names the required approvers and rule, N Approval Step records under that chain identity, an Assignment record per pending step, attestations and event-log entries for every chain-level and step-level action, and a deterministic chain-state evaluation whose result is provable.

This is a composition, not a new primitive. The five constituents — three atoms, the Audit Trail substrate and the Recoverable Invocation protocol — are unchanged. The composition is the wiring that makes their concepts coherent — one consolidated multi-party-approval surface rather than four parallel record sets the auditor has to correlate by hand.

What it waits on is narrow. Each of its five state-changing actions waits on calls it does not own — Approval Step's and Assignment's writes, and Audit Trail's records of them — and composes Recoverable Invocation for that wait rather than recovering the act itself. The approvers' own answers are not such a wait: no rule ends a wait on a person (Non-goal 6), so a Pending step is no open act, and nothing here sweeps, times out or recovers a chain because its approvers have not yet decided (Non-goal 17).

---

## Composes

- **[Approval Step](../atoms/approval-step.md)** — the per-gate primitive: one step per approver slot, each with its own subject, approver, submitter, scope and lifecycle, only the named approver deciding it and only the submitter withdrawing it.
- **[Permissions](../atoms/permissions.md)** — the authorization surface for the chain-level actions and the read.
- **[Assignment](../atoms/assignment.md)** — the in-tray binding: one responsibility record per step, naming its approver, recalled when the step or its chain ends.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate: every intent, outcome and refusal record is an attributed, sealed, retention-governed Audit Trail event.
- **[Recoverable Invocation](./recoverable-invocation.md)** — the protocol the five state-changing actions follow around their constituent writes: an intent before the commit, an outcome after it, and a sweep that closes the record of a commit whose outcome never landed; this page restates none of it.

```
Composes 1: EXACTLY ONE Approval Step instance MUST serve the composition.
Composes 2: EXACTLY ONE Permissions instance MUST serve the composition.
Composes 3: EXACTLY ONE Assignment instance MUST serve the composition.
Composes 4: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST NOT change a constituent's spec.
Composes 7: The composition MUST reach a transitive atom ONLY through the constituent that composes the atom.
Composes 8: The composition MUST NOT compose an instance of a transitive atom.
Composes 9: The composition MUST select audit events through the log read.
Composes 10: The composition MUST read an event by id ONLY through the record read.
Composes 11: A deployment MUST NOT call a step write outside the composition.
Composes 12: A deployment MUST NOT record an event under the chain namespace outside the composition.
Composes 13: EXACTLY ONE Recoverable Invocation instance MUST serve the composition.
Composes 14: The Recoverable Invocation instance MUST write to the composition's Audit Trail instance.
Composes 15: The composition MUST bind the act kinds PER the chain bindings.
Composes 16: The composition MUST NOT bind [Read Chain] as an act kind.
Composes 17: The composition MUST NOT hold an instance of Lease, which Recoverable Invocation reaches.
Composes 18: A deployment MUST NOT call Assignment's reassign on a chain's step assignment.
```

Term composition: this pattern's wiring of [Approval Step](../atoms/approval-step.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md), [Audit Trail](./audit-trail.md) and [Recoverable Invocation](./recoverable-invocation.md) — the chain, the quorum rule, the cascade, the read, the chain bindings and the write-ownership leg.

Term constituents: [Approval Step](../atoms/approval-step.md), [Permissions](../atoms/permissions.md), [Assignment](../atoms/assignment.md), [Audit Trail](./audit-trail.md), [Recoverable Invocation](./recoverable-invocation.md).

Term transitive atoms: [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md), [Tamper Evidence](../atoms/tamper-evidence.md) and [Retention Window](../atoms/retention-window.md), reached through Audit Trail, and [Lease](../atoms/lease.md), reached through Recoverable Invocation.

Term log read: Event Log's read by sequence-number range, from one with an open upper bound, passed through Audit Trail unchanged (Audit Trail Action wiring 1), with every selection by action reference and payload field made in the composition's own code.

Term record read: Audit Trail's read_record on an event id.

Term audit write: Audit Trail's record_action.

Term verification: Audit Trail's verify_record on an event id and a presentation.

Term step write: Approval Step's submit, approve, reject or withdraw.

Term chain namespace: the action references of the five act kinds' vocabularies on the composition's Audit Trail instance — chain.initiation.intended, chain.initiation.initiated, chain.initiation.refused, chain.approval.intended, chain.approval.approved, chain.approval.refused, chain.rejection.intended, chain.rejection.rejected, chain.rejection.refused, chain.step_withdrawal.intended, chain.step_withdrawal.withdrawn, chain.step_withdrawal.refused, chain.withdrawal.intended, chain.withdrawal.withdrawn and chain.withdrawal.refused, with the recovery_intended, abandoned and escalated references Recoverable Invocation derives under each kind (Recoverable Invocation journal 3).

Term state-changing action: [Initiate Chain], a decision action or [Withdraw Chain].

Term act kind: chain.initiation, chain.approval, chain.rejection, chain.step_withdrawal or chain.withdrawal — the five act kinds this composition binds on its Recoverable Invocation instance, one per state-changing action ([Initiate Chain], [Approve Step], [Reject Step], [Withdraw Step], [Withdraw Chain]), each with its own commit, outcome reference and probe.

Term chain bindings: each act kind's bindings, under the name Recoverable Invocation gives each. For chain.initiation: act key — the chain id, which the host injects at [Initiate Chain]'s seam ahead of the open (Capability requirement 20), so no minted-key deviation is declared; commit — the initiation transaction; journal events — chain.initiation.intended, the one outcome chain.initiation.initiated, chain.initiation.refused; pairing datum — the chain record's initiated instant; act probe — the initiation probe; actor at the open and the close — the initiator. For chain.approval, chain.rejection and chain.step_withdrawal: act key — the decision key; commit — the decision transaction; journal events — the kind's intended record, the one outcome chain.approval.approved, chain.rejection.rejected or chain.step_withdrawal.withdrawn, the kind's refused record; pairing datum — the step's decision instant, or for chain.step_withdrawal its withdrawal instant; act probe — the decision probe; actor at the open and the close — the approver for chain.approval and chain.rejection, the initiator for chain.step_withdrawal. For chain.withdrawal: act key — the chain id; commit — the withdrawal transaction; journal events — chain.withdrawal.intended, the one outcome chain.withdrawal.withdrawn, chain.withdrawal.refused; pairing datum — the chain record's terminal instant; act probe — the withdrawal probe; actor at the open and the close — the initiator. For all five: the pairing datum is the invocation's now, which the composition stamps on the chain record (Capability requirement 23) and the host injects into Approval Step's seam (Capability requirement 37); repeatable — yes; invocation completion bound — the decision completion bound; commit round trip and probe round trip — the deployment's disclosed bounds; journal — the composition's Audit Trail instance; retention period — the retention horizon; settling period — the deployment's settling period; service identity — the recovery identity; outcome envelope — the larger payload at the payload budget (Primitive policy 10).

Term decision key: the chain id and the step id, in that order — the act key of the three decision kinds, the step resolved under the chain through the step-chain index ahead of the open (Action wiring 17), so every record Recoverable Invocation writes for a decision carries its chain id.

Term initiation transaction: the chain record's write, Approval Step's submit per approver slot, Assignment's assign per step id, and the landed ids and the three index entries they give, committed together or not at all (Execution Contract Database 1) — the one commit Recoverable Invocation's bound commit stands for for chain.initiation (Composition notes).

Term decision transaction: the re-read of the chain state against the decision intent's trailing flag, the decision's step write, the step's recall, and — unless the decision is trailing — the chain evaluation, with the cascade and the terminal summary a terminal answer fires, committed together or not at all (Execution Contract Database 1, Execution Contract Database 2) — the one commit for the three decision kinds.

Term withdrawal transaction: the re-read of the chain state, the chain record set Withdrawn with its terminal instant, the cascade and the terminal summary, committed together or not at all — the one commit for chain.withdrawal.

Term commit partition: committed where the commit answers its record — the initiation transaction every step id and assignment id, the decision transaction the step write's success, the withdrawal transaction the chain Withdrawn; pre-commit where a constituent refuses a call inside the transaction — a submit's invalid-request, an assign's invalid-request or already-assigned, a step refusal, a cascade withdraw's temporal invalid-request — where a re-read finds the chain state the action did not admit (Action wiring 65, 67), where a constituent answers storage-failure (Execution Contract Constituent failure 1), or where the database answers state-unavailable (Execution Contract Constituent failure 3); unknown where a call answers a code its constituent does not declare, or where its reply has not arrived when the commit round trip has elapsed since the call's issue (Recoverable Invocation commit 6, commit 7).

Term initiation probe: the read that answers whether an open initiation intent's chain committed — the composition's read of the chain records by the intent's chain id. A chain record whose initiated instant EQUALS the intent's pairing datum answers committed carrying the chain shape the chain record holds; none answers not-committed; a read that fails or gives no answer answers unavailable (Recoverable Invocation act probe 4).

Term decision probe: the read that answers whether an open decision intent's step write committed — Approval Step's read filtered to the act key's step id and to a range whose start and end are the intent's pairing datum, on the decision instant or, for chain.step_withdrawal, on the withdrawal instant, kept in the composition's code to a step whose state is the kind's (Approved, Rejected or Withdrawn) and whose deciding actor or withdrawing actor EQUALS the intent's actor. Exactly one answers committed carrying the chain id, the step id, the decider and the reason, and the terminal summary where the chain record's terminal summary names the intent's invocation id; none answers not-committed; a read that answers invalid-query or gives no answer answers unavailable (Recoverable Invocation act probe 4, act probe 5), and an invalid-query is surfaced on the finding surface. The trailing flag stays on the intent, where the routed vector reads it (Term routed vector).

Term withdrawal probe: the read that answers whether an open withdrawal intent's withdrawal committed — the composition's read of the chain record by the intent's chain id. A chain record Withdrawn by a chain withdrawal, its terminal summary naming the withdrawal path, whose terminal instant EQUALS the intent's pairing datum, answers committed carrying the reason and the terminal summary; any other answers not-committed; a read that fails or gives no answer answers unavailable.

Term terminal summary: what a chain's terminating commit writes onto the chain record, and the terminating act's outcome carries — the chain state, the terminal instant, the terminal path (resolution or withdrawal), the rule reason or the withdrawal reason, the recalled step ids, the cascade-withdrawn step ids, the superseded step ids, the deterministic-arm step ids, and the terminating invocation's invocation id.

Term recovery identity: the composition's registered actor reference and credential, `application_actor_ref` and `application_credential` — the service identity of the five act kinds, under which Recoverable Invocation's sweep attests every write it makes for them (Recoverable Invocation service identity 3); no write the composition's own actions make is attested under it.

Adjacent, **not** constituents: [Privileged Access Provisioning](./privileged-access-provisioning.md) and [Execute Gated Workflow](./execute-gated-workflow.md) compose this chain as their approval surface; [Notification](../atoms/notification.md) and [Notification Fanout](./notification-fanout.md) tell approvers of work (Non-goal 7); [Legal Hold](../atoms/legal-hold.md) suspends purge over the chain's events through the substrate (Capability requirement 24); [Owed Record](../atoms/owed-record.md) and [Erasure Tombstone](../atoms/erasure-tombstone.md) take the extraction-pending classifications (Composition state 9, Composition state 11).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the chain records, the step list index, the step-chain index, the step-assignment index AND the event index.
Composition state 2: A chain record MUST carry the declared fields, the chain state, the terminal instant AND the landed ids.
Composition state 3: EVERY record of the chain namespace MUST carry the chain id through the record's act key.
Composition state 4: An initiation event MUST carry the chain shape.
Deleted: Composition state 5. Action wiring 9 and Action wiring 12 own it: a refused submit or assign fails the initiation transaction whole, so no initiation-failed record exists to carry a disposition.
Composition state 6: A terminating act's outcome MUST carry the terminal summary.
Composition state 7: A terminal chain record MUST carry the terminal summary.
Composition state 8: The composition MUST NOT remove a chain record.
Composition state 9: The composition MUST classify a chain record in an open initiation window as extraction-pending against Owed Record.
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
Composition state 22: IF the chain rebuild finds a terminal event whose terminal summary differs from the chain record's OR two terminal events for one chain THEN the composition MUST alert the finding surface carrying the chain id.
Composition state 23: IF the chain rebuild finds an initiation event whose chain shape differs from the chain record's THEN the composition MUST alert the finding surface carrying the chain id.
Composition state 24: IF the chain rebuild finds two initiation events OR two terminal events for one chain THEN the rebuild MUST bind the first by sequence number.
Composition state 25: The composition MUST NOT store a record of the Recoverable Invocation instance.
Composition state 26: A rebuild MUST NOT change a terminal chain record's chain state (Invariant 7.1).
Composition state 27: A rebuild MUST NOT change a terminal chain record's terminal instant (Invariant 7.2).
```

Term chain records: the set of chain records — `chain_store` in an implementation.

Term chain record: one approval chain's record.

Term declared fields: the chain id, the subject reference, the scope, the initiator reference, the approver set, the quorum rule, the initiated instant and the initiation's invocation id.

Term chain id: the id the host injects at the seam for a new chain — chain_id.

Term chain state: Pending | Approved | Rejected | Withdrawn.

Term terminal instant: the now of the invocation whose commit moved the chain out of Pending — chain_terminal_at, a field of the chain record.

Term landed ids: the step ids and assignment ids an initiation appended to the chain record as each was minted.

Term step list index: the map from a chain id to the chain's ordered step ids — `chain_to_steps` in an implementation.

Term step list: a chain's ordered step ids as the step list index holds them.

Term step-chain index: the map from a step id to its chain id — `step_to_chain` in an implementation.

Term step-assignment index: the map from a step id to its assignment id — `step_to_assignment` in an implementation.

Term event index: the map from a chain id to the event ids recorded for the chain in recording order, the chain's initiation intent among them, each with the step id the event names — `chain_to_events` in an implementation, the declared chain-to-audit traversal.

Term index entry: one key's value in one of the five record sets above.

Term chain-shape event: an initiation event — the invocation's, one Recoverable Invocation's sweep recovered, or one an operator wrote through the invocation resolve.

Term chain shape: the declared fields with the ordered step ids, the paired assignment ids and the initiated instant.

Term open initiation window: the span in which a chain record inside the retention horizon carries an open initiation intent and no chain-shape event — its initiation event owed, which Recoverable Invocation's sweep closes (Recoverable Invocation Invariant 4.1).

Term source event: the chain-shape event of a chain record or step list entry, or the event an event index entry names.

Term live index entry: an index entry whose source event the record read answers Retained, or a step-chain or step-assignment entry.

Term purged index entry: a chain record, step list entry or event index entry whose source event the record read answers Purged, a held event included (Audit Trail Invariant 8.2b).

Term chain rebuild: the log read kept to the chain-shape events, each recorded as its chain shape — the initiator from the initiation intent's actor, the act key giving the chain id — with the chain state, the terminal instant and the terminal summary from the chain's terminal event, Pending where none exists AND no terminal chain record stands, a terminal chain record keeping its chain state and terminal instant (Composition state 26, Composition state 27). A decision's outcome may precede its chain's initiation event in the log, the sweep recovering the one after the other landed, so the rebuild reads no order between a chain's initiation event and its other events.

Term event rebuild: the log read kept to the chain namespace, each record entered against the chain id its act key carries with the step id it names — the records the invocation wrote, the ones Recoverable Invocation's sweep recovered and the ones an operator wrote through the invocation resolve, each rebuilt rather than written by the composition (Recoverable Invocation Sweep never 1).

Term terminal-data alert: the alert Composition state 22 raises — an operator's terminal event disagreeing with the chain record, or a second terminal event for one chain.

Term shape alert: the alert Composition state 23 raises — an operator's initiation event whose chain shape disagrees with the chain record.

NOTE: Contract classification, per the section titled Composition state in `execution-contract.md` — Composition state 9 through 11 classify the composition's own records. The open initiation intent, not the chain record, now stands for the owed initiation event, and Recoverable Invocation's sweep closes it; the chain record in that window keeps its extraction-pending classification, since the chain rebuild cannot yet produce it. Recoverable Invocation's maps and findings register are that instance's state, reached through the instance (Composition state 25).

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
Deleted: Capability requirement 8. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 9. Recoverable Invocation sweep cadence 2 and Recoverable Invocation sweep cadence 3 own it.
Deleted: Capability requirement 10. Term reconciliation run bound owns it: the run bound counts every write's landing.
Deleted: Capability requirement 11. Recoverable Invocation Instance start 4 owns it: the worst closure against the closure window, the sweep's run counted in it.
Capability requirement 12: A deployment MUST provision the recovery identity.
Deleted: Capability requirement 13. Recoverable Invocation service identity 3 owns it: no write of the composition's own actions is attested under the recovery identity, so none is gated on a grant.
Capability requirement 14: A deployment MUST retire a compromised service credential in the actor registry.
Deleted: Capability requirement 15. Execution Contract Database 2 owns it.
Deleted: Capability requirement 16. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 18. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for a host to lack.
Capability requirement 19: The host MUST inject now, the invocation id, the run id AND the operator run id at the seam once PER invocation.
Capability requirement 20: The host MUST inject the chain id at [Initiate Chain]'s seam.
Capability requirement 21: The wired Audit Trail instance MUST expose the log read.
Capability requirement 22: A deployment MUST declare the id widths.
Capability requirement 23: The composition MUST stamp EVERY instant one invocation writes from the invocation's now.
Capability requirement 24: A deployment composing Legal Hold MUST place a subject's hold over the event ids the event index names for the subject's chains ONLY AFTER rebuilding each such chain's event index entry.
Capability requirement 25: A deployment needing reader authentication MUST bind the actor reference to an authenticated caller above the composition.
Capability requirement 26: The deployment MUST supply the database PER Execution Contract Database 1 through 4, Execution Contract Query 1 through 4 and Execution Contract Read 6, AND the act section PER Execution Contract Database 7 AND Execution Contract Refusal 1 (Recoverable Invocation Capability requirement 12).
Capability requirement 27: A deployment MUST declare the operating skew.
Deleted: Capability requirement 28. Recoverable Invocation run bound owns it: the sweep's own, and the write-ownership leg runs inside it.
Deleted: Capability requirement 29. Recoverable Invocation Instance start 5 owns it: the retention floor.
Deleted: Capability requirement 30. Recoverable Invocation act section 1 and Recoverable Invocation act section 11 own it: the sweep takes the act's critical section, and the composition holds no Lease (Composes 17).
Deleted: Capability requirement 31. Recoverable Invocation act section 3 owns it.
Deleted: Capability requirement 32. Recoverable Invocation act section 1 owns it: the critical section has the Lease atom's semantics.
Deleted: Capability requirement 33. Recoverable Invocation act section 16 owns it.
Deleted: Capability requirement 34. Recoverable Invocation pause bound 1 owns it: the instance's pause bound.
Deleted: Capability requirement 35. Recoverable Invocation act section 2 owns it.
Capability requirement 36: A deployment MUST set the intent candidates cap.
Capability requirement 37: The host MUST inject the invocation's now into Approval Step's seam AND Assignment's seam for the commit of a state-changing action.
Capability requirement 38: The host MUST NOT inject an equal now into two invocations of one act key on any node of the instance.
Capability requirement 39: A deployment MUST supply the act section Recoverable Invocation takes (Recoverable Invocation Capability requirement 11).
Capability requirement 40: A deployment MUST disclose the commit round trip, the probe round trip AND the settling period.
Capability requirement 41: A deployment MUST set the instance's bounds PER Recoverable Invocation Instance start 4 through 8.
Capability requirement 42: A deployment MUST NOT remove a probed record BEFORE the retention horizon destroys the payload of the record's outcome (Recoverable Invocation Binding 9).
Capability requirement 43: A deployment MUST declare id widths under which the decision key DOES NOT EXCEED Audit Trail's reference length cap (Recoverable Invocation Primitive policy 1).
```

Term approver set minimum: the smallest approver set a chain may declare — `approver_set_minimum`, default one; a single-gate chain is degenerate and valid.

Term approver set uniqueness: whether an approver set's references must be pairwise distinct — `approver_set_uniqueness`, default true.

Term allowed quorum rules: the quorum rules the deployment permits — `quorum_rule_allowed`, default [All Of N], [M Of N] and [One Of N].

Term audit retention policy: the retention policy configured on the composition's single Audit Trail instance — `audit_trail_retention_policy`: a seven-year SOX policy, a Part 11 predicate-rule policy, an ICH E6 trial-master-file policy.

Term retention horizon: the audit retention policy's horizon.

Term decision completion bound: the deployment's declared maximum for a state-changing action's invocation — each act kind's invocation completion bound: the longest it takes from the invocation open's take of the critical section to the invocation close's last write (the invocation yield's return where the commit answers an unknown arm), the commit's every constituent call included and sized for the largest cascade the approver set allows — `decision_completion_bound`.

Term reconciliation run bound: Recoverable Invocation's run bound on this composition's instance, inside which the write-ownership leg runs.

Term intent candidates cap: Recoverable Invocation's intent candidates cap on this composition's instance — the most database candidates an escalation names — `intent_candidates_cap`.

Term clock offset allowance: Recoverable Invocation's clock allowance on this composition's instance.

Term invocation id: the fresh id the host injects at the seam per state-changing invocation, carried by every record Recoverable Invocation writes for the invocation (Recoverable Invocation Term invocation id), by the chain record an initiation writes and by the terminal summary a terminating commit writes.

Term commit round trip: the deployment's disclosed bound on one commit, from issue to reply — the initiation transaction, the decision transaction or the withdrawal transaction.

Term probe round trip: the deployment's disclosed bound on one act probe, from issue to answer.

Term settling period: the time the deployment declares for an operator to settle an escalated act through the invocation resolve (Recoverable Invocation Term settling period).

Term probed record: a chain record or a step record — what an act probe of the five kinds reads.

Term seam: the composition's input and output boundary — the one place the host reads the clock and mints the chain id and the invocation id, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term id widths: the widest chain id, step id, assignment id and event id the seam and the constituents mint — the substrate's own attestation id width move, so a payload carrying id lists is sized at validation.

Term operating skew: the deployment's declared bound on the difference between the composition's seam and a constituent's — read by an auditor's grant comparison (Check 3.1, Check 3.2); every recovery comparison reads the clock offset allowance instead.

### Primitive policy

```
Primitive policy 1: IF the actor reference EQUALS blank THEN a state-changing action MUST answer invalid-request.
Primitive policy 2: IF a reference's length EXCEEDS Audit Trail's reference length cap THEN a state-changing action MUST answer invalid-request.
Primitive policy 3: IF a capped string EQUALS blank THEN [Initiate Chain] MUST answer invalid-request.
Primitive policy 4: IF a capped string's length EXCEEDS the field length cap OR a capped string's length EXCEEDS Approval Step's string cap THEN [Initiate Chain] MUST answer invalid-request.
Primitive policy 5: IF the approver set minimum EXCEEDS the approver set's count THEN [Initiate Chain] MUST answer invalid-request.
Primitive policy 6: IF the approver set uniqueness EQUALS true AND the approver set carries a repeated reference THEN [Initiate Chain] MUST answer invalid-request.
Primitive policy 7: IF the quorum rule IS NOT IN the allowed quorum rules THEN [Initiate Chain] MUST answer invalid-request.
Primitive policy 8: IF the quorum count IS NOT IN the valid quorum counts THEN [Initiate Chain] MUST answer invalid-request.
Primitive policy 9: IF the reason EQUALS blank THEN a reason-bearing action MUST answer invalid-request.
Primitive policy 10: IF the larger payload EXCEEDS the payload budget THEN a state-changing action MUST answer invalid-request.
Primitive policy 11: An action refused under Primitive policy 1 through 10 MUST NOT write.
Primitive policy 12: The composition MUST NOT call a constituent BEFORE Primitive policy 1 through 10 pass.
Primitive policy 13: The composition MUST compare a reference AND an id byte-exact.
Primitive policy 14: The composition MUST NOT normalize a caller string.
Primitive policy 15: The composition MUST NOT inspect a credential.
Primitive policy 16: The composition MUST NOT write a credential into an event payload.
Primitive policy 17: The composition MUST read a chain id's order ONLY as [Read Chain]'s tiebreak (Execution Contract Logic confinement 10).
Primitive policy 18: IF the reason's length EXCEEDS Approval Step's string cap THEN [Withdraw Chain] MUST answer invalid-request AND MUST NOT write.
Primitive policy 19: The composition MUST NOT call a constituent BEFORE Primitive policy 18 passes.
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
NOTE: open 2026-11-06-b — a deployment may declare a field length cap below the default, which makes a query filter value over it malformed (Term query) while another deployment answers the same filter normally; the cap's floor protects ids and not a reference filter.

Term larger payload: the larger of an action's intent payload and its outcome payload, every id at the id widths and the reason with its prefix — at [Initiate Chain], of every act the chain can take, the terminating outcome's terminal summary at the approver set's count included.

Term payload budget: Audit Trail's configured payload cap less the envelope the composition's event data adds.

Term credential: the caller's authentication material, consumed only by the audit write.

### Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Primitive policy 19 owns it for the intent of the five bound actions.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 23 owns it for the intent of the five bound actions.
Deleted: Audit arm 3. Recoverable Invocation Primitive policy 41 owns it for the intent of the five bound actions.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 43 owns it.
Audit arm 5: The deployment MUST alert on EVERY invalid-request the invocation open answers as a deployment fault.
Deleted: Audit arm 6. Execution Contract Database 1 owns it.
Deleted: Audit arm 7. Recoverable Invocation Primitive policy 27 owns it: the outcome's invalid-request(step-4) is read back by invocation id.
Deleted: Audit arm 8. Recoverable Invocation Primitive policy 35 owns it: the read-back matches by invocation id over the delta range.
Deleted: Audit arm 9. Recoverable Invocation Primitive policy 28 and Recoverable Invocation Primitive policy 36 own it: a record the read-back finds is landed.
Deleted: Audit arm 10. Recoverable Invocation commit 8d, Recoverable Invocation Primitive policy 29 through 31 own it: an outcome that does not land answers recording-failure(outcome).
Deleted: Audit arm 11. Recoverable Invocation Primitive policy 37 and Recoverable Invocation Primitive policy 40 own it.
Deleted: Audit arm 12. Execution Contract Database 2 owns it.
Deleted: Audit arm 13. Recoverable Invocation Primitive policy 29 owns it, reversed: the close retries a recording-failure(step-2) under the critical section to the terminus.
Deleted: Audit arm 14. Recoverable Invocation Invariant 8.3 owns it: recording-failure(intent) is a committed nothing, and the caller may retry.
Deleted: Audit arm 15. Recoverable Invocation Invariant 8.4 owns it: recording-failure(outcome) is an act that may exist, whose record the sweep closes, and the caller does not retry.
Deleted: Audit arm 16. Recoverable Invocation Primitive policy 42 owns it: the hard alert on the outcome's invalid-request below step-4.
```

Term intent: an initiation intent, a decision intent or a withdrawal intent — the record the invocation open writes before the commit, the one that verifies the caller's credential (Recoverable Invocation Primitive policy 19), carrying the invocation's parameters other than the credential, the pairing datum, and no constituent-minted id.

Term outcome: an initiation event, a decision's outcome or a withdrawal event — the record the invocation close writes after the commit, one Recoverable Invocation's sweep recovered under the recovery identity, or one an operator wrote through the invocation resolve.

Term refusal record: the chain.initiation.refused, chain.approval.refused, chain.rejection.refused, chain.step_withdrawal.refused or chain.withdrawal.refused record the invocation refuse writes for a pre-commit arm, carrying the code the pre-commit arm answered — the constituent's, or the composition's own for a re-read refusal such as chain-state-changed (Recoverable Invocation refuse step 3.1).

Term position: intent | outcome | refusal — Recoverable Invocation's (Recoverable Invocation Primitive policy 19 through 31): where a recording-failure of a state-changing action sat.

Term recovery flag: Recoverable Invocation's recovery set to true — carried by an outcome its sweep wrote under the recovery identity or an operator wrote through the invocation resolve, and by no other (Recoverable Invocation Term recovery).

### Action wiring

```
initiate_chain(actor_ref, credential, subject_ref, scope, approver_set, quorum_rule, optional reason)
  answers chain id | recording-failure(outcome, chain id)
  refuses permission-denied | invalid-request | invalid-credential | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | already-assigned | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

approve_step(actor_ref, credential, chain_id, step_id, optional reason)
  answers approved | recording-failure(outcome)
  refuses invalid-request | invalid-credential | not-known | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | chain-state-changed | not-pending | unauthorized | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

reject_step(actor_ref, credential, chain_id, step_id, reason)
  answers rejected_outcome | recording-failure(outcome)
  refuses invalid-request | invalid-credential | not-known | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | chain-state-changed | not-pending | unauthorized | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

withdraw_step(actor_ref, credential, chain_id, step_id, reason)
  answers withdrawn | recording-failure(outcome)
  refuses invalid-request | invalid-credential | not-known | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | chain-state-changed | not-pending | unauthorized | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

withdraw_chain(actor_ref, credential, chain_id, reason)
  answers withdrawn | recording-failure(outcome)
  refuses permission-denied | invalid-request | invalid-credential | not-known | not-pending | unauthorized | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

read_chain(actor_ref, query)
  answers chain results
  refuses permission-denied | invalid-query
```

Term chain results: the chains a query matches, in Action wiring 55's order, each carrying the chain record, its step records, each step's assignment records, each step's out-of-band mark and the chain's event ids.

Term query: any combination of filters on chain id, subject reference, scope, initiator reference, chain state, initiated instant and terminal instant, a filter on initiated instant or terminal instant carrying a range. A query is malformed where it filters on another axis, where a filter carries a blank string, where a filter's value exceeds the field length cap, or where a range's end precedes its start.

NOTE: watch the blank filter value (Term query).
NOTE: watch the filter value over the cap (Term query).

```
Action wiring 1: A validated initiation MUST call the permission check with the actor reference AND [Chains Initiate].
Action wiring 2: IF the permission check answers denied THEN the action MUST answer permission-denied.
Action wiring 3: A permitted initiation MUST call the invocation open with the act kind chain.initiation, the chain id as the act key, the actor reference, the credential AND the intent data carrying the subject reference, the scope, the approver set, the quorum rule, the reason AND now as the pairing datum (Recoverable Invocation Action wiring 4).
Action wiring 4: An initiation intent MUST NOT carry a minted id other than the chain id.
Deleted: Action wiring 5. Execution Contract Database 1 owns it.
Action wiring 6: An admitted initiation MUST write the chain record carrying Pending, the declared fields AND now as the initiated instant.
Action wiring 7: An admitted initiation MUST call Approval Step's submit per approver slot in declaration order with the subject reference, the approver reference, the actor reference as the submitter, the scope AND the prefixed reason.
Action wiring 8: An admitted initiation MUST append EVERY step id submit answers to the chain record's landed ids, the step list index AND the step-chain index.
Action wiring 9: IF submit answers invalid-request THEN the initiation transaction MUST commit no write AND [Initiate Chain] MUST close the pre-commit arm through the invocation refuse AND answer invalid-request (Recoverable Invocation commit 2, commit 3).
Action wiring 10: A submitted initiation MUST call Assignment's assign per step id with the step id as the task AND the step's approver reference as the assignee.
Action wiring 11: A submitted initiation MUST append EVERY assignment id assign answers to the chain record's landed ids AND the step-assignment index.
Action wiring 12: IF assign answers invalid-request OR already-assigned THEN the initiation transaction MUST commit no write AND [Initiate Chain] MUST close the pre-commit arm through the invocation refuse AND answer that code.
Action wiring 13: IF assign answers already-assigned THEN the deployment MUST alert on the answer as id reuse in a constituent.
Action wiring 14: [Initiate Chain] MUST close a staffed initiation through the invocation close naming chain.initiation.initiated, the outcome carrying the chain shape AND the reason (Recoverable Invocation commit 4).
NOTE: open 2026-11-10-e — the invocation's initiation outcome carries the chain shape and the reason, and the one the sweep recovers carries the chain shape alone (Term initiation probe); the page does not say whether the two payloads are one shape.
Deleted: Action wiring 15. Action wiring 68, Action wiring 69 and Recoverable Invocation Invariant 8.4 own it: an initiation whose close does not land answers recording-failure(outcome) carrying the chain id, the chain stays live, and its initiation event is the sweep's.
Action wiring 16: A landed initiation MUST answer the chain id.
Action wiring 17: IF the step-chain index's chain id for the step id DOES NOT EQUAL the chain id THEN the decision action MUST answer not-known.
Action wiring 18: A resolved decision MUST compute the trailing flag from the chain state.
Action wiring 19: A resolved decision MUST NOT refuse on the chain state.
Action wiring 20: A resolved decision MUST call the invocation open with the decision's act kind, the decision key as the act key, the actor reference, the credential AND the intent data carrying the chain id, the step id, the reason, the trailing flag AND now as the pairing datum.
Action wiring 21: An admitted decision MUST call the decision's step write with the step id, the actor reference as the decider AND the reason.
Action wiring 22: IF the step write answers a step refusal THEN the decision transaction MUST commit no write AND the decision action MUST close the pre-commit arm through the invocation refuse AND answer the step refusal.
Action wiring 23: IF Approval Step OR Assignment answers storage-failure THEN the action's commit MUST commit no write AND the action MUST close the pre-commit arm through the invocation refuse AND answer storage-failure (Execution Contract Constituent failure 1).
Action wiring 24: A decided decision MUST call Assignment's recall on the step's assignment id.
Action wiring 25: IF the step-assignment index names no assignment for the step THEN the decided decision MUST NOT call recall.
Action wiring 26: IF recall answers not-active THEN the decided decision MUST proceed.
Deleted: Action wiring 27. Execution Contract Database 1 owns it.
Action wiring 28: IF recall OR withdraw answers not-known THEN the deployment MUST alert on the answer as an index anomaly.
Action wiring 29: A decision action MUST close a decided decision through the invocation close naming the kind's one outcome reference, the outcome carrying the chain id, the step id, the reason, the trailing flag AND, where the decision transaction terminated the chain, the terminal summary (Recoverable Invocation commit 4).
Action wiring 30: IF the trailing flag EQUALS false THEN a decided decision MUST run the chain evaluation.
Action wiring 31: IF the trailing flag EQUALS true THEN a decided decision MUST NOT change the chain record.
Action wiring 32: A landed decision MUST answer the step write's answer.
Deleted: Action wiring 33. Execution Contract Database 2 owns it.
Action wiring 34: IF the chain state DOES NOT EQUAL Pending THEN the chain evaluation MUST NOT write.
Action wiring 35: IF the chain state EQUALS Pending AND the quorum rule answers a terminal state on the routed vector THEN the chain evaluation MUST set the chain state to the terminal state AND the terminal instant to now.
Action wiring 36: The chain evaluation MUST NOT run the cascade BEFORE setting the chain state.
Action wiring 37: A terminating evaluation MUST run the cascade with the rule reason.
Action wiring 38: A terminating evaluation MUST write the terminal summary onto the chain record inside the decision transaction.
Deleted: Action wiring 39. Recoverable Invocation Action wiring 4 and Term decision transaction own it: the cascade runs inside the commit, and the close follows the commit.
Action wiring 40: A validated chain withdrawal MUST call the permission check with the actor reference AND [Chains Withdraw].
Action wiring 41: IF the chain records carry no record for the chain id THEN [Withdraw Chain] MUST answer not-known.
Deleted: Action wiring 42. Execution Contract Database 2 owns it.
Deleted: Action wiring 43. Execution Contract Database 1 owns it.
Action wiring 44: IF the chain state DOES NOT EQUAL Pending THEN [Withdraw Chain] MUST answer not-pending.
Action wiring 45: IF the chain's initiator reference DOES NOT EQUAL the actor reference THEN [Withdraw Chain] MUST answer unauthorized.
Action wiring 46: An open chain withdrawal MUST call the invocation open with the act kind chain.withdrawal, the chain id as the act key, the actor reference, the credential AND the intent data carrying the chain id, the reason AND now as the pairing datum.
Action wiring 47: An admitted chain withdrawal MUST set the chain state to Withdrawn AND the terminal instant to now.
Action wiring 48: An admitted chain withdrawal MUST run the cascade with the reason.
Action wiring 49: [Withdraw Chain] MUST close a committed chain withdrawal through the invocation close naming chain.withdrawal.withdrawn, the outcome carrying the chain id, the reason AND the terminal summary (Recoverable Invocation commit 4).
Action wiring 50: A landed chain withdrawal MUST answer withdrawn.
Action wiring 51: A validated read MUST call the permission check with the actor reference AND [Chains Read].
Action wiring 52: IF the query is malformed THEN [Read Chain] MUST answer invalid-query.
Action wiring 53: A permitted read MUST answer the chain results ONLY AFTER rebuilding the event index entry of EVERY chain the results carry.
Action wiring 54: A permitted read MUST read a step's assignment records through the step's assignment history.
Action wiring 55: A permitted read MUST order chains by initiated instant AND then by chain id ascending (Execution Contract Logic confinement 10).
Action wiring 56: [Read Chain] MUST NOT record an audit event.
Action wiring 57: The composition MUST write EVERY event id the invocation open, the invocation close AND the invocation refuse return into the event index with the step id the event names.
Deleted: Action wiring 58. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Action wiring 59: [Approve Step] MUST call Approval Step's approve as the decision's step write.
Action wiring 60: [Reject Step] MUST call Approval Step's reject as the decision's step write.
Action wiring 61: [Withdraw Step] MUST call Approval Step's withdraw as the decision's step write.
Action wiring 62: IF [Initiate Chain] answers recording-failure carrying outcome THEN the answer MUST carry the chain id.
Action wiring 63: IF [Initiate Chain] answers recording-failure carrying intent THEN the answer MUST NOT carry a chain id.
Action wiring 64: An admitted decision MUST NOT call the decision's step write BEFORE re-reading the chain state inside the decision transaction.
Action wiring 65: IF the re-read chain state DOES NOT EQUAL Pending AND the decision intent's trailing flag EQUALS false THEN the decision transaction MUST commit no write AND the decision action MUST close the pre-commit arm through the invocation refuse AND answer chain-state-changed.
Action wiring 66: An admitted chain withdrawal MUST NOT set the chain state BEFORE re-reading the chain state inside the withdrawal transaction.
Action wiring 67: IF the re-read chain state DOES NOT EQUAL Pending THEN the withdrawal transaction MUST commit no write AND [Withdraw Chain] MUST close the pre-commit arm through the invocation refuse AND answer not-pending.
Action wiring 68: IF a call of a state-changing action's commit answers an arm of the unknown partition THEN the action MUST call the invocation yield AND answer recording-failure(outcome) (Recoverable Invocation commit 8).
Action wiring 69: IF the invocation open, refuse OR close answers a code of Recoverable Invocation's Action wiring table THEN the action MUST answer that code.
Action wiring 70: An admitted chain withdrawal MUST write the terminal summary onto the chain record inside the withdrawal transaction.
Action wiring 71: IF a read the action makes answers state-unavailable THEN the action MUST answer state-unavailable PER Execution Contract Read 1.
Action wiring 72: A chain evaluation MUST NOT compute the routed vector BEFORE reading the chain's decision intents through the record read on the event ids the event index names.
Action wiring 73: [Read Chain] MUST NOT answer a step's out-of-band mark BEFORE reading the chain's decision intents through the record read on the event ids the event index names.
```

Term minted id: a chain id, a step id or an assignment id.

Term prefixed reason: "chain:" and the chain id, then, where the caller supplies a reason, even a blank one, ": " and that reason — the step's stored reason, which names its chain on the atom's own record.

Term initiation intent: the chain.initiation.intended record.

Term initiation event: the chain.initiation.initiated record.

Term decision intent: the chain.approval.intended, chain.rejection.intended or chain.step_withdrawal.intended record, by the decision.

Term withdrawal intent: the chain.withdrawal.intended record.

Term approval event: the chain.approval.approved record.

Term rejection event: the chain.rejection.rejected record.

Term step withdrawal event: the chain.step_withdrawal.withdrawn record.

Term withdrawal event: the chain.withdrawal.withdrawn record.

Term resolution event: a decision's outcome carrying a terminal summary — the record of the chain evaluation's terminal answer.

Term terminal event: a resolution event or a withdrawal event — a terminating act's outcome.

Term terminating act: the invocation whose commit moved its chain out of Pending — a decision whose chain evaluation answered a terminal state, or a chain withdrawal.

Term decision's outcome: an approval event, a rejection event or a step withdrawal event, by the decision.

Term decision: approve for [Approve Step], reject for [Reject Step], withdraw for [Withdraw Step].

Term decision's step write: Approval Step's approve, reject or withdraw, by the decision — the decider passed as decided_by, or as withdrawn_by for a withdrawal.

Term step refusal: invalid-request | not-known | not-pending | unauthorized — Approval Step's refusals of a step write, relayed by name.

Term initiated instant: the now an initiation stamps on its chain record — initiated_at.

Term trailing flag: [Trailing] — true where the chain state did not equal Pending when the decision resolved.

Term validated initiation: an [Initiate Chain] call whose inputs cleared Primitive policy.

Term permitted initiation: a validated initiation whose permission check answered permitted.

Term admitted initiation: a permitted initiation whose invocation open landed the initiation intent.

Term submitted initiation: an admitted initiation whose every submit answered a step id.

Term staffed initiation: a submitted initiation whose every assign answered an assignment id — its initiation transaction committed.

Term landed initiation: a staffed initiation whose invocation close landed its initiation event.

Term resolved decision: an [Approve Step], [Reject Step] or [Withdraw Step] call whose inputs cleared Primitive policy and whose step id the step-chain index names under the chain id.

Term admitted decision: a resolved decision whose invocation open landed the decision intent.

Term decided decision: an admitted decision whose step write answered its success — its decision transaction committed.

Term landed decision: a decided decision whose invocation close landed its decision's outcome.

Term decision action: [Approve Step], [Reject Step] or [Withdraw Step].

Term chain evaluation: running the quorum rule over a chain's routed vector, with the terminal, the cascade and the terminal summary a terminal answer fires.

Term terminating evaluation: a chain evaluation of a chain whose chain state EQUALS Pending, whose quorum rule answered a terminal state.

Term validated chain withdrawal: a [Withdraw Chain] call whose inputs cleared Primitive policy.

Term found chain withdrawal: a validated chain withdrawal whose permission check answered permitted and whose chain id the chain records carry.

Term open chain withdrawal: a found chain withdrawal whose chain is Pending and whose initiator reference equals the actor reference.

Term admitted chain withdrawal: an open chain withdrawal whose invocation open landed the withdrawal intent.

Term committed chain withdrawal: an admitted chain withdrawal whose withdrawal transaction committed.

Term landed chain withdrawal: a committed chain withdrawal whose invocation close landed its withdrawal event.

Term validated read: a [Read Chain] call whose inputs cleared Primitive policy.

Term permitted read: a validated read whose permission check answered permitted and whose query is not malformed.

#### Closure table

Every input an action takes, and every answer a call of the six actions, of the chain evaluation and cascade they run, and of the write-ownership leg can meet — Permissions' permission check, Approval Step's submit, step writes, withdraw and read, Assignment's assign, recall and history_for, Audit Trail's record read and log read, and Recoverable Invocation's open, close, refuse and yield — with where the call lands it and the rule that owns the landing. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here. The five state-changing actions are Recoverable Invocation's: the intent commits at the open, ahead of the commit (Execution Contract Constituent failure 1), the commit is the initiation transaction, the decision transaction or the withdrawal transaction, and the outcome lands at the close, so open, commit and close are three commits and not one transaction (Non-goal 15; Recoverable Invocation Non-goal 1); an act whose outcome never lands is the sweep's, closed within its closure window (Recoverable Invocation reconcile). Inside a commit, every write of the action's commits together or not at all (Execution Contract Database 1), so a refusal inside it writes nothing but the refusal record the refuse lands (Recoverable Invocation commit 3); where two refusals of one action apply to one call, the one listed first on its refuses line answers (Execution Contract Refusal 1). The enumeration is exhaustive: an answer a constituent adds is a row this table lacks, and a cell no rule owns is a finding against the page.

**Inputs.**

| Action | Input | Lands | Owner |
|---|---|---|---|
| every action but [Read Chain] | a blank actor reference, or a reference longer than Audit Trail's reference length cap | invalid-request, nothing written and no constituent called | Primitive policy 1, 2, 11, 12 |
| [Read Chain] | a blank or over-long actor reference | the permission check's answer, the read's refuses line carrying no invalid-request | Action wiring 51, Action wiring 2 |
| [Initiate Chain] | a blank subject reference, scope or approver reference, or one longer than the field length cap or Approval Step's string cap | invalid-request, nothing written | Primitive policy 3, 4, 11 |
| [Initiate Chain] | an approver set smaller than the approver set minimum, or repeating a reference where the approver set uniqueness is true | invalid-request, nothing written | Primitive policy 5, 6, 11 |
| [Initiate Chain] | a quorum rule outside the allowed quorum rules, or a quorum count outside the valid quorum counts | invalid-request, nothing written | Primitive policy 7, 8, 11 |
| [Initiate Chain] | an approver set naming the initiator reference | admitted | Non-goal 13 |
| [Reject Step], [Withdraw Step], [Withdraw Chain] | a blank reason | invalid-request, nothing written | Primitive policy 9, 11 |
| [Withdraw Chain] | a reason longer than Approval Step's string cap, which the cascade's withdraw would refuse inside the commit | invalid-request, nothing written and no constituent called | Primitive policy 18, 19 |
| [Initiate Chain], [Approve Step] | a reason supplied blank | carried as supplied, never normalized; at [Initiate Chain] the prefixed reason stays non-blank, and at [Approve Step] a refusal of the step write is relayed | Primitive policy 14, Term prefixed reason, Action wiring 22 |
| every action but [Read Chain] | a larger payload over the payload budget | invalid-request, nothing written; the open's own sizing never meets it, and an invalid-request the open answers is alerted | Primitive policy 10, 11, Audit arm 5, Recoverable Invocation Primitive policy 12, 13 |
| every action but [Read Chain] | the credential | consumed by the invocation open's intent record alone, never inspected or written into a payload | Primitive policy 15, 16 |
| a decision action | a step id the step-chain index does not name under the chain id, a missing entry rebuilt first | not-known, nothing written, ahead of the open | Action wiring 17, Composition state 21 |
| a decision action | a step whose chain is terminal | admitted, the trailing flag true in the intent and the chain record unchanged | Action wiring 18, 19, 31 |
| [Withdraw Chain] | a chain id the chain records carry no record for, a missing record rebuilt first | not-known, ahead of the open | Action wiring 41, Composition state 21 |
| [Withdraw Chain] | a chain that is not Pending | not-pending, ahead of the open | Action wiring 44 |
| [Withdraw Chain] | an actor reference other than the chain's initiator reference | unauthorized, ahead of the open | Action wiring 45 |
| [Read Chain] | a malformed query | invalid-query, nothing read; permission-denied where the permission check also denies the caller | Action wiring 52, Action wiring 2, Execution Contract Refusal 1 |
| [Read Chain] | a query no chain matches | chain results carrying no chain | Action wiring 53 |

**Permissions: the permission check**, at [Initiate Chain], [Withdraw Chain] and [Read Chain] (Action wiring 1, 40, 51).

| Answer | Lands | Owner |
|---|---|---|
| permitted | the open; at [Withdraw Chain] its chain, Pending and initiator checks first; the read | Action wiring 3, 41, 44, 45, 46, 53 |
| denied | permission-denied, nothing written and nothing recorded | Action wiring 2, Non-goal 9 |
| state-unavailable | passed through unchanged, nothing written | Action wiring 71, Execution Contract Read 1 through 3 |
| no answer | no answer to give | Execution Contract Error model 1 |

**Recoverable Invocation: the open, the close, the refuse and the yield**, at the five state-changing actions.

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the open | an intent event id | the commit | Action wiring 3, 20, 46, Term admitted initiation, Term admitted decision, Term admitted chain withdrawal |
| the open | invalid-credential, invalid-request, act-in-flight, section-unavailable, journal-unavailable, recording-failure(intent) | the same code, nothing committed; an invalid-request alerted as a deployment fault | Action wiring 63, 69, Audit arm 5, Recoverable Invocation Action wiring table |
| the open | act-landed | never: every kind is repeatable | Recoverable Invocation repeatable 1, Term chain bindings |
| the open | recording-failure(outcome) | the same code, at [Initiate Chain] carrying the chain id; the commit is never issued and the open intent is the sweep's, which finds nothing and escalates it | Action wiring 62, 69, Recoverable Invocation Action wiring table |
| the close | an event id | the action's answer | Action wiring 16, 32, 50, 57 |
| the close | recording-failure(outcome) | recording-failure(outcome), the act committed and its record the sweep's; at [Initiate Chain] carrying the chain id | Action wiring 62, 69, Recoverable Invocation commit 4 |
| the refuse | an event id | the constituent's own code, the attempt recorded | Action wiring 9, 12, 22, 23, 65, 67, Cascade 14 |
| the refuse | already-accounted or recording-failure(refusal, constituent_code) | that code; the sweep records the attempt where the refusal did not land | Action wiring 69, Recoverable Invocation Action wiring table |
| the yield | its return | recording-failure(outcome), the act possibly committed and its record the sweep's; at [Initiate Chain] carrying the chain id | Action wiring 62, 68 |

**Approval Step and Assignment, inside a commit.** A storage-failure from any of these calls, or a state-unavailable from the database, is a pre-commit arm: the commit writes nothing and the refuse lands the refusal record (Action wiring 23, Execution Contract Constituent failure 1, 3). A call with no answer, or with an answer its constituent does not declare, is the unknown partition, closed through the yield (Action wiring 68, Term commit partition). The other answers:

| Call | Answer | Lands | Owner |
|---|---|---|---|
| submit, per approver slot | a step id | the landed ids, the step list index and the step-chain index | Action wiring 8 |
| submit | invalid-request | invalid-request, the initiation transaction committing no write, refused | Action wiring 9 |
| assign, per step id | an assignment id | the landed ids and the step-assignment index; the last one the close | Action wiring 11, 14 |
| assign | invalid-request or already-assigned | that code, the initiation transaction committing no write, refused; an already-assigned alerted as id reuse | Action wiring 12, 13 |
| the decision transaction's re-read | Pending, or a terminal state the intent's trailing flag reads | the step write | Action wiring 64 |
| the decision transaction's re-read | a terminal state on an intent whose trailing flag is false | chain-state-changed, nothing written, refused; the caller's retry is a trailing decision | Action wiring 65 |
| the decision's step write | approved, rejected_outcome or withdrawn | the recall and, unless trailing, the chain evaluation; then the close | Action wiring 24, 29, 30 |
| the decision's step write | invalid-request, not-known, not-pending or unauthorized | the step refusal relayed by name, nothing written, refused | Action wiring 22 |
| a decided decision's recall | ok or not-active | the decision proceeds | Action wiring 26 |
| a decided decision's recall | not-known | alerted as an index anomaly; the decision proceeds | Action wiring 28 |
| a decided decision's recall | not called where the step-assignment index names no assignment, a missing entry rebuilt first | the decision proceeds | Action wiring 25, Composition state 21 |
| the withdrawal transaction's re-read | Pending | the chain Withdrawn and the cascade | Action wiring 66, 47, 48 |
| the withdrawal transaction's re-read | a terminal state | not-pending, nothing written, refused | Action wiring 67 |
| a cascade's withdraw | withdrawn | the step named among the terminal summary's cascade-withdrawn step ids | Cascade 2, Term terminal summary |
| a cascade's withdraw | not-pending | the step named among the superseded step ids | Cascade 10 |
| a cascade's withdraw | unauthorized or not-known | a deterministic arm: alerted, the cascade proceeds, the step named among the deterministic-arm step ids | Cascade 8, 12, 15, Action wiring 28 |
| a cascade's withdraw | the temporal invalid-request | invalid-request, the commit writing nothing, refused; the chain stays Pending | Cascade 14 |
| a cascade's withdraw | any other invalid-request | not met: the withdrawer is the step's submitter and the cascade reason is non-blank and within Approval Step's string cap | Cascade 2, Term cascade reason, Primitive policy 18 |
| a cascade's recall | ok | the recalled step ids | Cascade 13 |
| a cascade's recall | not-active | read as done | Cascade 11 |
| a cascade's recall | not-known | a deterministic arm: alerted, the cascade proceeds, the step named among the deterministic-arm step ids | Cascade 8, 15, Action wiring 28 |
| a cascade's recall | not called where the step-assignment index names no assignment, a missing entry rebuilt first | the cascade proceeds | Cascade 7, Composition state 21 |
| Approval Step's read, on a chain's step ids | the steps | the chain results' step records and out-of-band marks | Action wiring 53, Term out-of-band mark |
| Approval Step's read | invalid-query | not met: one filter on the step id axis, each id one submit minted | Action wiring 8 |
| history_for, per step id | the assignments | the chain results' assignment records, and the rebuild of a step-assignment entry | Action wiring 54, Composition state 17 |

**Audit Trail: the record read and the log read.**

| Read | Answer | Lands | Owner |
|---|---|---|---|
| the record read, on an index entry's source event | Retained or Purged | the entry live, or purged | Composition state 20, Term live index entry, Term purged index entry |
| the record read, on an event id the event index names | not-known | not met: the event index names landed events alone | Action wiring 57 |
| the record read, on the event ids the event index names under a chain's decision intents | each intent's actor, pairing datum and trailing flag, or Purged with the surviving reference and actor | the routed vector, the out-of-band marks | Action wiring 72, 73 |
| the log read, from one with an open upper bound | the events | the chain rebuild, the event rebuild and their alerts | Composition state 12, 18, 22, 23, Action wiring 53 |
| the log read | invalid-query | not met: the range has a start and no end | Term log read |

Inside an action, a read that fails passes through unchanged and writes nothing (Execution Contract Read 1 through 3), and a read with no answer leaves the action none to give (Execution Contract Error model 1).

**The composition's own records.** A chain record or index entry the action writes commits inside the action's commit (Execution Contract Database 1), and a write of them that fails answers storage-failure, closed through the refuse (Execution Contract Read 4, Action wiring 23); a key found carrying no index entry is rebuilt before any rule reads it so (Composition state 21). The event index takes the event ids the open, the close and the refuse return (Action wiring 57); a record the sweep or an operator wrote reaches it only through the event rebuild, which [Read Chain] runs on every chain it answers (Action wiring 53).

**The leg.** It answers no caller, and decides only on an answered read (Reconciliation 39): a chain-record read, a step read or a log read that fails or gives no answer decides nothing, and the record is examined again at the next run (Reconciliation 2). It opens findings and alerts; it writes no outcome, which is the sweep's under the recovery identity.

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

Term routed transition: a step decision a decision intent carries — an intent of the decision's kind whose act key names the chain id and the step id, whose actor equals the step record's decider, whose pairing datum EQUALS the step's decision instant for an approval or rejection intent and the step's withdrawal instant for a step_withdrawal intent, the step excluded where the chain record's terminal summary names the step among its cascade-withdrawn step ids — or, past the retention horizon, a step whose event index entries name more purged events with a surviving action reference of the decision kind's intended record and a surviving actor equal to the decider than purged events with a surviving action reference of the decision kind's refused record or of an abandoned reference the kind derives and a surviving actor equal to the decider; or a cascade withdrawal the chain record's terminal summary names.

Term out-of-band transition: a step decision in the Approval Step records no routed transition covers — written around the composition.

Term out-of-band mark: a step's mark, set where an out-of-band transition decided the step and clear on every other step — read at each [Read Chain] from the Approval Step records and the chain's routed transitions, and kept in no record.

Term rule reason: the generated reason a chain evaluation carries — "quorum met: A of N approved under" and the rule, for Approved; "quorum unreachable:" and the rule, then "N − R − W remain achievable; rejections present", for Rejected; "chain withdrawn by cascade:" and the rule, then "quorum unreachable by withdrawal alone", for Withdrawn — non-blank by construction (2026-08-26-g, 2026-08-29-g, 2026-08-29-p).

NOTE: open 2026-11-10-d — the Rejected arm's "N − R − W remain achievable" is M-of-N arithmetic and the Withdrawn arm names no counts, against Wiring decision 9's "AND the counts"; which string each arm carries is not written.

<details markdown="block">
<summary>WHY</summary>

*Principle.* The auditor's question is *did the required approvers actually decide?*, and only an outcome that is a pure function of their recorded decisions answers it provably. The composition is the only layer that can own it: Approval Step knows no chain, and the other three know no quorum.

*Likely objection.* Why not let the calling workflow count approvals — it already reads the steps — or push the quorum into Approval Step, where the decisions live?

*Mechanism.* A calling-system count is the unauditable form: the outcome would live in a system no spec governs, and *the chain approved* would be that system's assertion rather than a recomputable fact. Approval Step cannot hold it without ceasing to be the freestanding single-gate atom its EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) boundary defends, since counting across steps needs chain identity. So the rule lives here as a pure function of named counts with no clock term (Wiring decision 5), and the stored chain state is its memo, cross-checkable against the step records at any time (Invariant 2) — which is what makes a forged terminal detectable. The three sets are disjoint: under all-of-N a met vector has no rejection or withdrawal, and under M-of-N a met vector has `A ≥ M` while a lost one has `A ≤ N − R − W < M`. **A rejection outranks a withdrawal** (Wiring decision 2 and 3): a rejection is an approver's negative decision, a withdrawal is the initiator retracting a mis-submitted gate, and the terminal state keeps the two audit signals apart — Rejected names a quorum failure attributable to named decisions; Withdrawn, a chain retracted before its quorum was determined.

</details>

### Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Scheduled leg 1 and Recoverable Invocation sweep cadence 2 own it: the sweep runs at every process start, and the reconciliation runs beside it (Reconciliation 2, Reconciliation 46).
Reconciliation 2: The reconciliation MUST run every sweep cadence.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Deleted: Reconciliation 4. Execution Contract Database 1 owns it.
Reconciliation 5: The reconciliation MUST NOT examine an aged record.
Reconciliation 39: The reconciliation MUST decide ONLY on an answered read.
Deleted: Reconciliation 6. Execution Contract Database 2 owns it.
Deleted: Reconciliation 7. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for another holder to hold.
Deleted: Reconciliation 8. Recoverable Invocation reconcile step 1.2 and Term initiation probe own it: an open initiation intent is examined once past its examine edge and closed by the probe's answer.
Deleted: Reconciliation 9. Recoverable Invocation Sweep never 1 owns it: the sweep runs no adopter code other than the act probe, and a recovered initiation leaves its chain live.
Deleted: Reconciliation 10. Recoverable Invocation reconcile step 3.2 and Term initiation probe own it: a committed initiation is closed by the recovered chain.initiation.initiated carrying the chain shape the chain record holds.
Deleted: Reconciliation 11. Recoverable Invocation Invariant 4.1 and Recoverable Invocation Invariant 9.2 own it: the open initiation intent stands for the owed initiation event, and the sweep writes no adopter state.
Deleted: Reconciliation 12. Action wiring 9 and Action wiring 12 own it: a refused submit or assign fails the initiation transaction whole, so no initiation-failed record exists.
Deleted: Reconciliation 12a. Action wiring 9 owns it.
Deleted: Reconciliation 12b. Action wiring 12 owns it.
Deleted: Reconciliation 12c. Action wiring 68 and Recoverable Invocation reconcile step 3.2 own it: a staffed initiation whose initiation event did not land is the sweep's, recovered rather than torn down.
Deleted: Reconciliation 13. Action wiring 9, Action wiring 12 and Recoverable Invocation Invariant 9.2 own it: no partial initiation commits, and a lost initiation event is recovered, its chain left live.
Deleted: Reconciliation 14. Execution Contract Database 1 owns it.
Deleted: Reconciliation 15. Action wiring 9 and Action wiring 12 own it: no initiation recovery withdraws a chain.
Deleted: Reconciliation 16. Recoverable Invocation Invariant 4.1 owns it: the open initiation intent stands for the quarantine flag, and closes when the initiation event lands.
Deleted: Reconciliation 17. Recoverable Invocation reconcile step 1.2, Recoverable Invocation reconcile step 3.2 and Term decision probe own it: an open decision intent is closed by the recovered outcome or escalated.
Deleted: Reconciliation 35. Composition state 6, Term decision probe, Term withdrawal probe and Recoverable Invocation reconcile step 3.2 own it: a terminal chain's terminal event is its terminating act's outcome, which the sweep recovers carrying the terminal summary, and the cascade ran inside the terminating commit.
Deleted: Reconciliation 18. Recoverable Invocation Invariant 3.2 and Recoverable Invocation Invariant 3.3 own it: the sweep pairs by invocation id in the journal and by the pairing datum in the database.
Deleted: Reconciliation 19. Recoverable Invocation reconcile step 1.1 and Recoverable Invocation reconcile step 1.2 own it: the sweep closes intents alone, and an out-of-band transition carries none.
Reconciliation 20: IF a decided step Reconciliation 45 reads IS an out-of-band transition THEN the reconciliation MUST open a write-ownership finding for the step id.
Deleted: Reconciliation 21. Recoverable Invocation Invariant 3.5a, Recoverable Invocation Invariant 5.2 and Recoverable Invocation Primitive policy 11a own it: an outcome never carries candidates, and the recovered outcome carries the recovery flag, the acting actor reference and the intent event id.
Deleted: Reconciliation 22. Execution Contract Database 1 owns it.
Deleted: Reconciliation 23. Execution Contract Database 1 owns it.
Deleted: Reconciliation 24. Execution Contract Database 1 owns it.
Deleted: Reconciliation 25. Execution Contract Database 1 owns it.
Deleted: Reconciliation 26. Cascade 14 owns it: a cascade's temporal refusal fails its commit, so no partial flag names a call to retry.
Deleted: Reconciliation 27. Cascade 14 owns it: the sweep retries no call.
Deleted: Reconciliation 28. Recoverable Invocation Invariant 5.1 and Recoverable Invocation reconcile step 3.2a own it: the recovery intent before any recovered outcome.
Deleted: Reconciliation 29. Recoverable Invocation reconcile step 3.2a owns it: the kind's recovery_intended record carries the invocation id, the intent event id, the act key and the plan.
Deleted: Reconciliation 29a. Recoverable Invocation reconcile step 3.2a and Term decision key own it: a decision kind's act key carries the step id.
Deleted: Reconciliation 30. Cascade 10 and Cascade 14 own it: no call is left for the sweep to close, and a superseded cascade withdrawal rides the terminal summary.
Deleted: Reconciliation 31. Recoverable Invocation Invariant 5.2 and Recoverable Invocation service identity 3 own it: the sweep writes under the recovery identity, and the reconciliation writes no event.
Deleted: Reconciliation 32. Recoverable Invocation reconcile step 3.5, Recoverable Invocation reconcile step 3.8 and Recoverable Invocation reconcile step 5.1 own it: an intent the sweep cannot close is escalated once and reported at risk.
Deleted: Reconciliation 33. Recoverable Invocation reconcile step 3.18 and Recoverable Invocation External check 10 own it.
Deleted: Reconciliation 34. Term decision probe and Recoverable Invocation act probe 6 own it: the recalled step ids come from the terminal summary the commit wrote.
Deleted: Reconciliation 36. Term decision probe and Term terminal summary own it: the rule reason is written on the chain record by the terminating commit.
Deleted: Reconciliation 37. Recoverable Invocation Primitive policy 11a, Recoverable Invocation Invariant 5.2 and Term withdrawal probe own it.
Deleted: Reconciliation 38. Action wiring 9 and Action wiring 12 own it: no withdrawal lacks its intent.
Deleted: Reconciliation 40. Recoverable Invocation act section 11 and Recoverable Invocation act section 12 own it: the sweep takes the act's critical section, and the composition holds no Lease (Composes 17).
Deleted: Reconciliation 41. Recoverable Invocation reconcile step 2.3 owns it.
Deleted: Reconciliation 42. Recoverable Invocation act section 15 owns it.
Deleted: Reconciliation 43. Recoverable Invocation reconcile step 3.8 and Recoverable Invocation Invariant 3.5a own it: an escalation carries the database candidates, and an outcome never does.
Reconciliation 44: The reconciliation MUST NOT examine a young record.
Reconciliation 45: The reconciliation MUST read EVERY chain record AND EVERY decided step of a chain record's step list that Reconciliation 5 AND Reconciliation 44 admit, each by the instant Term young record reads, against the intents.
Reconciliation 46: The reconciliation MUST read the sweep's run reading of now, which Recoverable Invocation's run takes once at the sweep's own seam, AND MUST NOT read now at a seam of the reconciliation.
Reconciliation 47: The reconciliation MUST take the enumeration of Reconciliation 45 once PER run, at the run's start.
Reconciliation 48: IF a chain record Reconciliation 45 reads IS NOT a carried chain record THEN the reconciliation MUST open a write-ownership finding for the chain id.
Reconciliation 49: IF a terminal chain record Reconciliation 45 reads IS NOT a carried terminal THEN the reconciliation MUST open a write-ownership finding for the chain id.
Reconciliation 50: The reconciliation MUST alert the finding surface carrying the record's id for EVERY false closing Reconciliation 45 reads.
```

Term reconciliation: the leg the composition runs outside every invocation, beside Recoverable Invocation's sweep — the reading of the chain records and the decided steps against the intents, whose output, a write-ownership finding or a false-closing alert, an auditor awaits at the sweep cadence and within no window of its own.

Term carried chain record: a chain record an initiation intent carries — an intent of chain.initiation whose act key is the chain id and whose pairing datum EQUALS the chain record's initiated instant.

Term carried terminal: a terminal chain record whose terminating commit an intent carries — an intent whose act key carries the chain id, whose invocation id the chain record's terminal summary names and whose pairing datum EQUALS the chain record's terminal instant.

Term carrying intent: the intent that makes a chain record a carried chain record, a terminal a carried terminal, or a step decision a routed transition — one at most, an equal now never reaching two invocations of one act key (Capability requirement 38).

Term young record: a chain record whose initiated instant, a terminal chain record whose terminal instant, or a decided step whose decision instant or withdrawal instant stands within the examine window end of the act kind of the intent that carries it — chain.initiation for an initiated instant, the terminating act's kind for a terminal instant, the decision's kind for a decision instant or withdrawal instant — measured back from the sweep's now: a record whose invocation the sweep may still be closing (Recoverable Invocation Term examine window end).

Term aged record: a chain record or a decided step for which the sweep's now DOES NOT PRECEDE `(((instant + retention horizon) - (2 * clock offset allowance)) - reconciliation run bound)`, the instant read as Term young record reads it — a record whose intent the retention horizon may have destroyed, which the reconciliation would read as no intent.

Term write-ownership finding: a finding that a chain record, a terminal chain record's terminal or a step decision is not carried — a write against the chain records or Approval Step outside the composition's surface (Composes 11, Composes 12).

Term false closing: a carried chain record, carried terminal or routed transition whose carrying intent an abandonment or a refusal closed — an act that committed, read as one that did not.

Term finding surface: the deployment's compliance surface — the surface Recoverable Invocation's instance writes its register to. A write-ownership finding and this page's alerts are written beside that register and are no part of it (Recoverable Invocation findings 6).

Term aged chains: the chains whose initiated instant plus the retention horizon PRECEDES now.

Term aged chain: a chain in the aged chains.

Term settled step: a step that is terminal, or whose chain is terminal.

Term chainless step: a Pending step whose subject reference, submitter and scope equal the chain's, whose stored reason carries the chain's id, and which no chain record's landed ids name.

### Scope vocabulary

```
Scope vocabulary 1: The composition MUST define chains initiate, chains withdraw AND chains read for the Permissions instance.
Scope vocabulary 2: The composition MUST NOT gate a decision action on a Permissions scope.
```

### Cascade

```
Cascade 1: A cascade MUST call recall on the assignment of EVERY still-Pending step of the chain's step list, in the step list's order.
Cascade 2: IF the chain state EQUALS Withdrawn THEN the cascade MUST call Approval Step's withdraw on EVERY still-Pending step of the chain's step list with the initiator reference as the withdrawer AND the cascade reason.
Cascade 3: The cascade MUST NOT call recall on a withdrawn step BEFORE the step's withdraw answers.
Deleted: Cascade 4. Composition state 6 and Recoverable Invocation Action wiring 6 own it: the cascade's withdrawals ride the terminal summary in the terminating act's outcome, and the act writes no other journal record.
Deleted: Cascade 5. Composition state 6 owns it: no cascade record exists to attest; the terminating act's outcome is attested at the invocation close under the caller's credential.
Deleted: Cascade 6. Recoverable Invocation Invariant 5.2 owns it: an outcome the sweep recovers carries the recovery identity's attestation, the caller in the acting actor reference.
Cascade 7: IF the step-assignment index names no assignment for a step THEN the cascade MUST NOT call recall for the step.
Cascade 8: IF a cascade call answers a deterministic arm THEN the cascade MUST proceed through the remaining calls.
Deleted: Cascade 9. Cascade 14 owns it: a temporal refusal fails the commit, so no terminal event carries a partial flag.
Cascade 10: IF withdraw answers not-pending THEN the cascade MUST name the step id among the terminal summary's superseded step ids.
Cascade 11: IF recall answers not-active THEN the cascade MUST read the recall as done.
Cascade 12: IF withdraw answers unauthorized THEN the deployment MUST alert on the answer as a conformance fault.
Cascade 13: The recalled step ids MUST list the steps whose recall answered ok, in recall order.
Cascade 14: IF a cascade's withdraw answers the temporal invalid-request THEN the commit MUST commit no write AND the action MUST close the pre-commit arm through the invocation refuse AND answer invalid-request.
Cascade 15: IF a cascade call answers a deterministic arm THEN the cascade MUST name the step id among the terminal summary's deterministic-arm step ids.
Cascade 16: The terminal summary's cascade-withdrawn, superseded AND deterministic-arm step ids MUST list the steps in the step list's order.
```

Term cascade: the secondary calls a terminal chain owes its still-Pending steps, run inside the terminating commit.

Term still-Pending step: a step of the chain's step list that the routed vector counts as Pending — a step no routed transition counted among A, R or W, a step decided out of band among them (Wiring decision 7), read at the terminating commit.

Term cascade reason: the rule reason, or the initiator's validated reason on the [Withdraw Chain] path — non-blank by construction and, on the [Withdraw Chain] path, within Approval Step's string cap by Primitive policy 18, so Approval Step never refuses a cascade withdrawal over its reason.

Term recalled step ids: the steps whose assignments a cascade recalled — always present in a terminal summary, empty where none.

Term temporal invalid-request: Approval Step's invalid-request on a cascade withdrawal whose resolved decision instant PRECEDES the step's submission instant (Approval Step Operation 19) — under the injected now, reachable only where a node's clock stepped back between the initiation and the withdrawal.

Term deterministic arm: a cascade call's not-known or unauthorized — alerted (Action wiring 28, Cascade 12) and never refused, since refusing it would leave the chain unwithdrawable for good.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent, and each needs two or more working together. Three structural relations frame them, per the section titled Structural-relation invariant templates in `spec-format.md`: **chain to steps**, one-to-many, exactly one step per approver slot, mandatory on both sides at quiescence; **step to assignment**, one-to-one, mandatory at creation, recalled and never replaced — the composition performs no reassign; **chain to audit events**, one-to-many, at least one per chain, every event other than an intent naming an existing chain. The inverse directions are read through the derived indexes, and a lost index entry is a rebuild trigger, never a relation violation.

- **Invariant 1 — Chain completeness.**
  ```
  Invariant 1.1: IF a chain IS IN the quiescent chains THEN the chain's step list's count MUST EQUAL the approver set's count.
  Deleted: Invariant 1.2. Action wiring 9 and Action wiring 12 own it: a refused submit or assign fails the initiation transaction whole, so no chain is closed short of its step list.
  Invariant 1.3: EVERY step id in a step list MUST name an Approval Step record.
  Invariant 1.4: The step-chain index MUST name EXACTLY ONE chain for EVERY step id in a step list.
  Invariant 1.5: The Approval Step records MUST carry no chainless step of a quiescent chain.
  ```
  Term quiescent chains: the chains with no invocation in flight and no open intent.

  Term quiescent chain: a chain in the quiescent chains.

- **Invariant 2 — Quorum determinism, split by terminal path.**
  ```
  Invariant 2.1: IF a chain IS IN the resolution-terminated chains THEN the chain state MUST EQUAL the quorum rule's answer on the chain's routed vector.
  Invariant 2.2: IF a chain IS IN the withdrawal-terminated chains THEN the quorum rule MUST answer Pending on the chain's pre-withdrawal vector.
  ```
  Term pre-withdrawal vector: the routed vector with the cascade withdrawals and the superseded steps the chain record's terminal summary names counted back as Pending.

  NOTE: the routed vector reads Approval Step's records, the decision intents and the chain record's terminal summary, never an outcome, and Recoverable Invocation writes no adopter state (Recoverable Invocation Invariant 9.2), so Invariant 2.1 and Invariant 2.2 hold against an operator's closing as against the invocation's: prevented, not detected.

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
  Invariant 5.1: EVERY committed transition on a quiescent chain MUST resolve to EXACTLY ONE OF the transition's one audit record, an escalation of the transition's carrying intent, a false closing, a write-ownership finding.
  Invariant 5.2: EVERY chain namespace event other than an intent MUST name a chain the chain records carry.
  Invariant 5.3: The deployment MUST alert on EVERY orphan attestation carrying a chain namespace action reference.
  NOTE: the invocation resolve checks neither an operator's outcome nor the data it carries against the chain records or Approval Step (Recoverable Invocation resolve 28, Recoverable Invocation resolve 31), so Invariant 5.1 and Invariant 7.3 are detected, not prevented, for an operator's closing: the terminal-data alert and the shape alert (Composition state 22, Composition state 23), the false-closing alert (Reconciliation 50), Check 5.1, Check 7.1, Check 7.2 and Check 8.1 find it.
  ```
  Term audit record: a committed transition's outcome — the decision's outcome for a routed step decision, the terminal event for a chain's move out of Pending and for every cascade withdrawal its terminal summary names, the initiation event for a chain's creation — whether the invocation, Recoverable Invocation's sweep or an operator wrote it.

  Term committed transition: a chain's creation in the chain records, a step's move out of Pending in the Approval Step records, or a chain's move out of Pending in the chain records.

- **Invariant 7 — Chain terminal absorption.**
  ```
  Invariant 7.1: The composition MUST NOT change a terminal chain's chain state.
  Invariant 7.2: The composition MUST NOT change a terminal chain's terminal instant.
  Invariant 7.3: Two terminal events MUST NOT carry one chain id.
  Deleted: Invariant 6. Composes 5 owns it.
  ```
- **Invariant 8 — Declared fields are immutable.**
  ```
  Invariant 8.1: The composition MUST NOT change a declared field.
  Deleted: Invariant 8.2. Recoverable Invocation Invariant 4.1 owns it: no quarantine flag exists; the open initiation intent stands for it.
  ```
- **Invariant 9 — Chain reconstructibility, within the retention horizon.**
  ```
  Invariant 9.1: IF a chain IS NOT IN the aged chains THEN the chain's lifecycle MUST resolve from the chain records, the Approval Step records, the Assignment records AND the chain's events alone.
  ```
  Term lifecycle: the chain record; the ordered step records with each decision, decider, decision instant and reason; each step's assignment records; and the verified attestation of every chain-level and step-level act through the chain's event index entry, rebuilt before [Read Chain] answers it (Action wiring 53).

- **Invariant 10 — Authentication precedes commitment.**
  ```
  Deleted: Invariant 10.1. Recoverable Invocation Invariant 1.1 owns it: the chain record's write follows the invocation open, whose intent record verified the initiator's credential.
  Deleted: Invariant 10.2. Recoverable Invocation Invariant 1.1 owns it: the step write follows the invocation open, whose intent record verified the caller's credential.
  Deleted: Invariant 10.3. Recoverable Invocation Invariant 1.1 owns it: the chain set Withdrawn follows the invocation open, whose intent record verified the initiator's credential.
  ```

Chain completeness and quorum determinism give *bypass resistance* — a chain cannot read Approved without the quorum-named decisions present, and any reader can verify it. Permission enforcement and audit completeness give *non-repudiation*. Terminal absorption and immutability give *finality* — a terminated chain's outcome is fixed, and corrections are new chains, never edits.

---

## Examples

### Walkthrough — SOX-controlled journal entry, all-of-N quorum

A multinational bank's general-ledger system uses Multi-Party Approval to gate posting of journal entries above the $5M materiality threshold. The deployment configures `approver_set_minimum = 2`, `approver_set_uniqueness = true`, `quorum_rule_allowed = {all-of-N}`, `audit_trail_retention_policy = sox_7_year`.

1. **A controller prepares a journal entry.** Journal entry JE-2026-0441 posts a $12M intercompany transfer. Under the deployment's business rules, materiality of this size requires the regional controller, the CFO, and the CEO (Chief Executive Officer). The controller calls `initiate_chain(actor_ref=controller_morgan, credential=morgan_credential, subject_ref="je-2026-0441", scope="financial:journal-entry:post:materiality-tier-3", approver_set=[finance_director_chen, cfo_park, ceo_walsh], quorum_rule="all-of-N", reason="$12M intercompany transfer per Q1 close")`.
2. **The composition validates and writes.** Validation passes (three pairwise-distinct approvers, all-of-N is allowed, the constructed payload in budget) and Permissions returns `permitted` (`controller_morgan` holds `chains:initiate`). Then — **before anything is created** — Recoverable Invocation's open records `chain.initiation.intended` → `ev_init_int`, keyed by `chain-2026-0441`, the id the host injected at the seam, which is where `morgan_credential` is checked against the actor registry; had it not validated, the call would have returned `rejected(invalid-credential)` with no chain, no Approval Steps and no Assignments, and nothing to undo. The payload names the declared chain shape and the invocation's now as its pairing datum, and no step or assignment id, since an intent carries no constituent-minted id (Action wiring 4). Only then does the initiation transaction write the chain record in Pending, its initiated instant that now, submit three Approval Steps (`step-001`, `step-002`, `step-003`) and create three Assignments (one per approver's in-tray), all committing together; the invocation close records `chain.initiation.initiated` carrying the chain shape and `intent_event_id: ev_init_int`. Returns `chain_id = chain-2026-0441`.
3. **The CFO approves first.** `approve_step(actor_ref=cfo_park, credential=park_credential, chain_id=chain-2026-0441, step_id=step-002, reason="Reviewed Q1 close package; transfer is in-policy")` → the open records `chain.approval.intended` → `ev_dec_int_02` first, keyed by `(chain-2026-0441, step-002)`, **which is where `park_credential` is validated — this action has no Permissions check, so that record is the only thing standing between an asserted actor_ref and a committed approval in the CFO's name**; then, in one transaction, the chain is re-read Pending, Step 002 transitions to Approved with its decision instant the invocation's now, and the Assignment is recalled; the close records `chain.approval.approved` carrying `intent_event_id: ev_dec_int_02`. Quorum evaluation: `A=1, R=0, W=0, P=2`; all-of-N requires `A == N(=3)`; not satisfied; no quorum failure (no rejections or withdrawals); chain stays Pending.
4. **The controller's regional finance director approves second.** `approve_step(actor_ref=finance_director_chen, credential=chen_credential, chain_id=chain-2026-0441, step_id=step-001, reason="Mapping verified; consolidation rules applied correctly")` → its own `chain.approval.intended` record validates `chen_credential`, then the approval commits and `chain.approval.approved` carries the join. `A=2, R=0, W=0, P=1`; still not at quorum.
5. **The CEO approves third.** `approve_step(actor_ref=ceo_walsh, credential=walsh_credential, chain_id=chain-2026-0441, step_id=step-003, reason="Reviewed and authorized")` → approved. `A=3, R=0, W=0, P=0`; `A == N`; inside the same transaction the chain transitions to Approved, `chain_terminal_at` is set and the terminal summary is written onto the chain record; the close records `chain.approval.approved` carrying that terminal summary — the chain's resolution event. The composing workflow system releases JE-2026-0441 for posting.
6. **Three years later, a SOX section 404 audit.** The auditor queries `read_chain({subject_ref: "je-2026-0441"})`. The result is one chain in Approved with three step records, eight attestations, eight retention records under the seven-year policy — one initiation intent, one `chain.initiation.initiated`, three decision intents and three `chain.approval.approved`, the third carrying the terminal summary, each `record_action` producing one attestation and one retention record, and a Tamper Evidence seal covering the relevant range. `verify_record` on each Audit Trail event returns `verified`. The auditor confirms (a) Approval Step Invariant 4 was enforced on each step (`decided_by` matched `approver_ref`), (b) Invariant 2 holds (chain state matches the deterministic quorum evaluation), and (c) no chain-state edit occurred after `chain_terminal_at`. Control evidence is complete and provable.

*Every invocation in the runs below follows the same order — validation, any Permissions check, the intent record that verifies the caller, the constituent writes in one transaction, the outcome record carrying `intent_event_id` — and the narrations elide it except where the example turns on it. An implementation that elided it would fail Recoverable Invocation Check 1.1. **[Withdraw Chain]'s checks are the one place the order shows**: its Pending check and its initiator check both run before its intent record, and its transaction re-reads Pending before it writes.*

### Happy path — FDA Part 11 batch release, M-of-N(2) quorum across three qualified persons

A pharmaceutical manufacturer's batch release system requires any two of three Qualified Persons (QPs — the designated batch-release authorities under EU (European Union) and FDA manufacturing rules) to approve a batch release under 21 CFR Part 211. The deployment uses `quorum_rule = M-of-N(2)`. A batch BR-2026-0412 is ready for release. The QA manager initiates: `initiate_chain(actor_ref=qa_manager, credential=qa_manager_credential, subject_ref="br-2026-0412", scope="pharma:batch-release:bulk", approver_set=[qp_santos, qp_lopez, qp_kim], quorum_rule="M-of-N(2)")` → `chain-2026-0412`. QP Santos approves first (`A=1`); QP Lopez approves second (`A=2`); `A ≥ M`; the chain transitions to Approved without needing QP Kim's decision. QP Kim's step remains Pending unless Kim later decides — the chain has terminated, but the step's submission record is immutable (Approval Step Invariant 1) and the trailing decision, if Kim later approves, is recorded in the audit trail without altering the chain state (Invariant 7). The released batch carries the chain id as its control evidence; an FDA inspector queries the chain and confirms the two named QPs decided affirmatively under their respective Actor Identity attestations.

### Happy path — ICH E6 GCP protocol deviation, one-of-N quorum across a delegated approver pool

A clinical trial protocol deviation at a multi-site study can be approved by any one of the site principal investigators (PIs) on call. The trial coordinator initiates: `initiate_chain(actor_ref=coordinator_lee, credential=lee_credential, subject_ref="dev-2026-1057", scope="clinical-trial:protocol-deviation:non-substantive", approver_set=[pi_chen, pi_okafor, pi_müller, pi_singh], quorum_rule="one-of-N")`. PI Okafor approves: `A=1, M=1`; chain Approved. The other three steps remain Pending in the Approval Step records, their assignments recalled by the cascade. If a fifth approval is needed later (e.g., for a substantive deviation that requires escalation), a new chain is initiated with the appropriate quorum and approver set; the original chain is not modified.

### Rejection path — all-of-N quorum, one approver rejects

In the SOX walkthrough above, suppose the CEO finds the entry suspicious and rejects: `reject_step(actor_ref=ceo_walsh, credential=walsh_credential, chain_id=chain-2026-0441, step_id=step-003, reason="Counterparty not on approved-affiliates list; refer back to finance team for review")` → rejected_outcome. Quorum evaluation: `R = 1 ≥ 1`; under all-of-N the chain transitions to **Rejected** with reason `"quorum unreachable: all-of-N; 2 remain achievable; rejections present"`. `chain_terminal_at` is set; the close records `chain.rejection.rejected` carrying the terminal summary, the chain's resolution event. JE-2026-0441 is not released for posting; the composing workflow routes the entry back to the controller, who must initiate a new chain for the corrected entry (a fresh chain_id, fresh step ids — no editing of the rejected chain's records).

### Rejection path — chain withdrawal by initiator

In an alternative history of the same chain, the controller submitting JE-2026-0441 discovers a clerical error in the entry before any approver has decided: the chain was opened against the wrong subject. The controller calls `withdraw_chain(actor_ref=controller_morgan, credential=morgan_credential, chain_id=chain-2026-0441, reason="Wrong journal entry id; superseded by new chain on JE-2026-0441-revised")`. In one transaction the chain transitions to Withdrawn, each of the three still-Pending steps cascades to Approval Step's Withdrawn state and each Assignment is recalled; the close records `chain.withdrawal.withdrawn`, whose terminal summary names the three cascade withdrawals. A new chain is initiated on the corrected entry.

### Selected outcome runs

Three one-paragraph runs over branches the walkthroughs above do not reach — chosen because each exercises a surface the composition's defenses turn on: the withdrawal-driven cascade, the trailing-decision discipline, and a cascade a clock step refuses — with one failure path, a lost outcome the sweep recovers.

**Chain-Withdrawn-by-cascade — a step withdrawal makes quorum unreachable with no rejection.** A three-approver `M-of-N(2)` engineering change chain has one approval in (`A=1`) when the initiator discovers the second gate names the wrong reviewer and calls `withdraw_step(actor_ref=initiator_ross, credential=ross_credential, chain_id=chain-ec-118, step_id=step-b, reason="Wrong reviewer named; superseding chain to follow")`, then realizes the third gate is mis-scoped too and withdraws it the same way. On the second withdrawal the rule reads `A=1, R=0, W=2`: `(N−R−W)=1 < M=2 ∧ R=0 ∧ W≥1` — quorum unreachable purely by withdrawal — so the chain transitions to **Withdrawn**, not Rejected: no approver made a negative decision, and the terminal state says so. The state is set first; there are no still-Pending steps left to cascade-withdraw (`recalled_step_ids = []` in the terminal summary the second `chain.step_withdrawal.withdrawn` carries, whose chain state, Withdrawn, on a decision's outcome marks this as the cascade path (Composition state 6), distinct from a `chain.withdrawal.withdrawn` outcome's initiator path); the one approval already recorded stays immutable.

**A trailing decision — the third Qualified Person approves after the chain closed.** Continuing the batch-release example: two days after `chain-2026-0412` reached Approved on the second approval, QP Kim reviews the batch anyway and calls `approve_step(actor_ref=qp_kim, credential=kim_credential, chain_id=chain-2026-0412, step_id=step-kim, reason="Independent review complete; concur")`. Resolution finds the chain terminal — the call is *not* refused (the step's own Pending state is the gate) — and computes `trailing = true`, which the `chain.approval.intended` record carries. The transaction re-reads the chain, finds it terminal as the flag says, and the atom records the approval; the already-Recalled assignment's recall returns `not-active` (idempotent success), and the close records `chain.approval.approved` with `trailing = true` and no terminal summary. The chain evaluation does not run: no re-evaluation, no second resolution event, `chain_store` untouched. An auditor later walking the trail sees a `chain.approval.approved` after the chain's resolution event and reads the flag, not a contradiction. Had Kim's call resolved a moment before the second approval terminated the chain, its intent would carry `trailing = false`, the re-read would find the chain Approved, and the call would answer chain-state-changed with nothing written; Kim's retry is the trailing decision above (Action wiring 65).

**A cascade a clock step refuses, and the initiator's retry.** An `all-of-N` chain of four is withdrawn by its initiator moments after it opened. The host injected the invocation's now into Approval Step's seam, but the node's clock had stepped back between the initiation and the withdrawal, so that now precedes the third step's submission instant, and Approval Step refuses the third cascade withdrawal with its temporal invalid-request. The withdrawal transaction commits no write (Cascade 14): the chain stays Pending, all four steps and their assignments stand, the refuse lands `chain.withdrawal.refused` carrying invalid-request, and the initiator receives invalid-request. A moment later the initiator retries under a later now; the cascade lands whole, and `chain.withdrawal.withdrawn` carries a terminal summary naming four cascade withdrawals and four recalls. No Pending step stands on the chain this withdrawal terminated, so no sweep has a residue to retry.

**A lost outcome on a terminating approval, recovered.** In the M-of-N(2) batch release, QP Lopez's approval is the second: the decision transaction commits — Lopez's step Approved, its decision instant the invocation's now, the chain Approved, the terminal summary on the chain record naming the invocation — but the close's write of `chain.approval.approved` answers recording-failure carrying step-3, its reply lost, and the read-back by invocation id finds nothing, so Lopez's call returns `recording-failure(outcome)` and is not re-run. The chain is already Approved for every reader of [Read Chain]. Recovery is Recoverable Invocation's: once the intent ages past its examine edge, the sweep runs the decision probe — Approval Step's read of Lopez's step at the intent's pairing datum, kept to an Approved step decided by `qp_lopez` — finds the step, reads the terminal summary off the chain record because it names the intent's invocation id, writes `chain.approval.recovery_intended`, and lands `chain.approval.approved` under the recovery identity with `recovery = true`, `qp_lopez` as the acting actor reference, and the terminal summary: the chain's resolution event, recovered. The next [Read Chain] rebuilds the chain's event index entry before answering it, so the chain's event ids name the recovered event (Action wiring 53).

### Regulated adversarial scenarios

Three adversarial reads the composition must survive in regulated contexts:

- **Regulator audit — SOX section 404 control evidence query, "show me every chain that approved a material journal entry in Q1 with full attribution."** The auditor queries `read_chain({scope: "financial:journal-entry:post:materiality-tier-3", state: Approved, initiated_at: {start: "2026-01-01T00:00:00Z", end: "2026-03-31T23:59:59Z"}})`. Every chain in the result set carries its approver set, its quorum rule, its constituent step records (with `decided_by` matched to `approver_ref` by Approval Step Invariant 4), and its Audit Trail attestations under the seven-year retention. The auditor independently computes the expected chain state from the step records and the quorum rule and confirms Invariant 2 holds: no chain reached Approved without the quorum-named decisions actually present. The auditor also queries `read_chain({scope: "...:tier-3", state: Pending, initiated_at: {start: ..., end: ...}})` to verify no chain was left unresolved — a non-empty result identifies a stalled material chain — lawful here, since a chain has no deadline (Non-goal 6), and a question for the deployment's deadline policy. The covered entity has documentable, provable control evidence.

- **Disputed approval — FDA Part 11 electronic signature challenge against a chain participant.** An FDA investigator reviewing batch BR-2026-0412 challenges the authenticity of QP Lopez's approval: the actor claims they did not approve the batch. The investigator queries `read_chain({subject_ref: "br-2026-0412"})` and retrieves the chain plus its step records. Step `step-lopez-0412` shows `decided_by: "qp_lopez"`, `decided_at: "2026-04-15T16:04:00Z"`, `decision_reason: "Specification limits met; COA (Certificate of Analysis) reviewed"`. Approval Step Invariant 4 guarantees that the *value* `qp_lopez` was presented and matched `approver_ref` at decision time — that atom takes no credential, and its identity model is byte equality on the reference as supplied, so the record alone does not establish who presented it. What does is the `chain.approval.intended` record that **preceded** the decision and the Actor Identity attestation on it: the principal Lopez presented material matching the registry's public material for that reference before the step could be decided (Recoverable Invocation Invariant 1.1). The bound is the honest one — a stolen credential validates — so the records establish that Lopez's credential was used, not that Lopez was at the keyboard. The Audit Trail's Actor Identity attestation for the corresponding `chain.approval.approved` event is then verified against `qp_lopez`'s registered public material at the attestation's own `attested_at` — the substrate's stamp, not Approval Step's `decided_at`, which is another seam's reading. The denied-approval claim cannot be sustained against the structural record without claiming credential compromise; that reinterpretation is the **Compromise Disclosure** *(forthcoming)* composing pattern's responsibility, not the chain composition's.

- **Breach or incident forensics — unauthorized chain initiation investigation.** During a security incident review, the incident response team needs to determine whether any chains were initiated by actors who should not have held `chains:initiate` during a window of suspected privilege escalation (2026-05-01T00:00:00Z through 2026-05-03T23:59:59Z). The team queries `read_chain({initiated_at: {start: ..., end: ...}})` and, for each chain in the window, walks the Audit Trail back to the `chain.initiation.initiated` event and verifies its Actor Identity attestation. The team also queries the Permissions records for grants of `chains:initiate` active during the same window; any initiator whose grant was not active at `initiated_at` is a finding — judged under the deployment's operating skew: the grant stamps and `initiated_at` are two seams' readings, so the audit condemns only violations wider than that skew and reads boundary-width discrepancies as inconclusive (Invariant 3's check-time enforcement is the gate; this audit reads its evidence trail). The chain composition's records faithfully document every initiation and outcome; the cross-record verification — initiator attestation vs. Permissions grant state at the initiation timestamp — is the audit operation that surfaces unauthorized chains.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when the checks below are provable to an external auditor given the composition's emergent state and the constituent records. Every enumeration of audit events runs through the log read; every check that walks events runs inside the retention horizon.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY quiescent chain's step list complete (Invariant 1.1).
Check 1.2: An auditor MUST find EVERY step id in a step list naming an Approval Step record the step-chain index maps back to the chain (Invariant 1.4).
Check 1.3: An auditor MUST find the Approval Step records carrying no chainless step of a quiescent chain (Invariant 1.5).
Check 2.1: An auditor MUST find EVERY resolution-terminated chain's chain state equal to the quorum rule's answer on the chain's routed vector (Invariant 2.1).
Check 2.2: An auditor MUST find the quorum rule answering Pending on EVERY withdrawal-terminated chain's pre-withdrawal vector (Invariant 2.2).
Check 2.3: An auditor MUST NOT run Check 2.1's recomputation on a withdrawal-terminated chain (Invariant 2.2).
Check 3.1: An auditor MUST find the initiator of EVERY initiation event holding [Chains Initiate] at the initiated instant, within the operating skew (Invariant 3.1).
Check 3.2: An auditor MUST find the actor of EVERY withdrawal event holding [Chains Withdraw] at the terminal instant, within the operating skew (Invariant 3.2).
Check 4.1: An auditor MUST find EVERY quiescent chain's assignments PER Invariant 4.1 AND Invariant 4.2 (Invariant 4.1).
Deleted: Check 4.2. Cascade 14 owns it: a temporal refusal fails the commit, so no Active assignment stands under a partial flag.
Check 5.1: An auditor MUST resolve EVERY committed transition on a quiescent chain to EXACTLY ONE OF the transition's one audit record, an escalation of the transition's carrying intent, a false closing, a write-ownership finding (Invariant 5.1).
Check 5.2: An auditor MUST find EVERY chain namespace event other than an intent naming a chain the chain records carry (Invariant 5.2).
Deleted: Check 5.3. Recoverable Invocation Check 5.1 and Recoverable Invocation Check 5.2 own it: every record the recovery identity attests names an intent another actor attested.
Deleted: Check 5.4. Cascade 14 owns it: no partial flag names a call.
Check 6.1: An auditor MUST clear Approval Step's Generation acceptance over the Approval Step instance (Composes 5).
Check 6.2: An auditor MUST clear Permissions' Generation acceptance over the Permissions instance (Composes 5).
Check 6.3: An auditor MUST clear Assignment's Generation acceptance over the Assignment instance (Composes 5).
Check 6.4: An auditor MUST clear Audit Trail's Generation acceptance over the Audit Trail instance (Composes 5).
Check 6.5: An auditor MUST clear Recoverable Invocation's Generation acceptance over the Recoverable Invocation instance (Composes 5).
Check 7.1: An auditor MUST find EXACTLY ONE terminal event for EVERY terminal chain whose terminating act's intent stands closed, carrying the chain record's terminal summary (Invariant 7.3, Invariant 5.1).
Check 7.2: An auditor MUST find no chain id two terminal events carry (Invariant 7.3).
Check 8.1: An auditor MUST find EVERY chain record's declared fields equal to the chain shape the chain's chain-shape event carries (Invariant 8.1).
Check 9.1: An auditor MUST resolve EVERY chain record AND EVERY decided step of a step list that is neither a young record nor an aged record to EXACTLY ONE OF a carried record whose carrying intent stands open, a carried record whose carrying intent stands escalated, a carried record an outcome names, a false closing, a write-ownership finding (Reconciliation 20, Reconciliation 48, Reconciliation 49, Reconciliation 50).
Deleted: Check 10.1. Recoverable Invocation Check 1.1 owns it.
Check 10.2: An auditor MUST resolve EVERY initiation intent whose initiation transaction committed to a chain record through the intent's act key (Composition state 3).
Deleted: Check 10.3. Recoverable Invocation Invariant 3.5a and Recoverable Invocation Check 6.5 own it: no outcome carries candidates, and an escalation's candidates match the database.
Deleted: Check 10.4. Recoverable Invocation Check 1.1 and Recoverable Invocation Invariant 3.2 own it.
Deleted: Check 10.5. Recoverable Invocation Check 3.1 owns it: an intent carrying no outcome is closed or escalated within the closure window.
```

NOTE: EVERY check names the rule the check tests.

Term resolution-terminated chain: a chain whose terminal summary names the resolution path — terminated by a decision's chain evaluation.

Term withdrawal-terminated chain: a chain whose terminal summary names the withdrawal path — withdrawn by its initiator through [Withdraw Chain].

### External checks

```
External check 1: An auditor needing a reader's identity confirmed MUST read the calling layer's authentication evidence (Invariant 3.3).
External check 2: An auditor needing the approver set's policy fit confirmed MUST read the calling system's policy declaration (Non-goal 4).
External check 3: An auditor needing an approver's standing authorization confirmed MUST read the deployment's standing-authorization registry at the initiated instant (Non-goal 5).
External check 4: An auditor needing a chains initiate grant's appropriateness confirmed MUST read the Permissions-administration layer (Invariant 3.1).
External check 5: An auditor needing an escalated intent's resolution confirmed MUST read the finding surface (Recoverable Invocation External check 1).
External check 6: An auditor needing the obligation of Capability requirement 37 AND Capability requirement 38 confirmed MUST clear the obligation from external evidence (Recoverable Invocation External check 12).
External check 7: An auditor needing the closure window, the sweep cadence, the run bound AND the decision completion bound confirmed MUST clear Recoverable Invocation Check 4.1 AND Recoverable Invocation External check 3 over the instance (Capability requirement 7, Capability requirement 41).
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
NOTE: watch the segregation policy (Non-goal 13).
NOTE: watch the adopter's policy note (Non-goal 13).
Non-goal 14: The composition MUST NOT administer a Permissions grant.
Non-goal 15: The composition MUST NOT describe the three commits of a state-changing action as atomic (Recoverable Invocation Non-goal 1).
Non-goal 16: The composition MUST NOT own a re-entry arm beyond Approval Step's not-pending AND the withdrawal transaction's not-pending (Recoverable Invocation Non-goal 4).
Non-goal 17: The composition MUST NOT bind a Pending step's wait on the step's approver as an act kind.
```

Term pre-intent refusal: a refusal an action answers ahead of its intent — validation, permission, a decision's unresolved step, and at [Withdraw Chain] an unknown chain, not-pending and an initiator mismatch. A refusal inside a commit is no pre-intent refusal: the refuse records it (Recoverable Invocation commit 3).

NOTE: the owners — other compositions, and a Sequenced Approval Chain *(forthcoming)* for ordering (Non-goal 1, Non-goal 2); Delegation *(forthcoming)* (Non-goal 3); a composing Permissions layer, the calling system and the governance layer (Non-goal 4, External check 2; Non-goal 5; Non-goal 13); the Permissions-administration layer (Non-goal 14, External check 4); a composing scheduler or a Deadline Escalation pattern *(forthcoming)* (Non-goal 6); [Notification](../atoms/notification.md) and [Notification Fanout](./notification-fanout.md) (Non-goal 7); a higher-order policy (Non-goal 8); a Failed-Attempt Log *(forthcoming)* (Non-goal 9); the calling layer (Non-goal 11, Capability requirement 25, External check 1); a Reverse Index *(forthcoming)* lookup the deployment builds (Non-goal 12). Non-goal 17 is the scope of the method rule *A wait composes, never hand-rolls* in `pressure-testing.md`: the approvers' own answers are not a wait on a call, since no rule ends a wait on a person (Non-goal 6), so a Pending step is no open act and no sweep reads it; the waits Recoverable Invocation closes are the five state-changing actions' own calls.

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
Retention asymmetry 2: IF no hold keeps a chain's event THEN an auditor MUST read failed-verification carrying purged on the event as lawful destruction.
Retention asymmetry 2a: IF a hold keeps a chain's event THEN an auditor MUST read failed-verification carrying purged on the event as held.
NOTE: open 2026-11-05-a — Retention asymmetry 2a reads the answer purged as held where a hold keeps the event, while Audit Trail Invariant 8.2b gives a held event the same answer as a purged one; where the auditor reads that a hold keeps the event is not written.
```

### Cross-record consistency under partial failure

```
Cross-record consistency 1: IF a state-changing action's commit commits AND the invocation's close does not land THEN the committed records MUST stand beside an open intent, closed by the sweep within the closure window.
```

This is Recoverable Invocation's Cross-record consistency for the five act kinds, which the sweep closes: the chain record, the step or the chain's terminal is carried, its carrying intent open until the sweep's committed probe writes the outcome, and the records are honest throughout — a decision reads the chain state from the chain record, and [Read Chain] answers the chain record whatever its outcome's state. The records an action keeps as evidence of a refused call — its intent and its refusal record — stay committed (Recoverable Invocation commit 3).

---

## Composition notes

**Recoverable Invocation.** The five state-changing actions follow [Recoverable Invocation](./recoverable-invocation.md) around their constituent writes (Composes 13 through 17): an intent before the commit, the one outcome as the close, a refusal record where a constituent or a re-read refuses, the act's critical section over them, and a sweep and an operator's invocation resolve for what an invocation left open. The page binds the five act kinds once (Term chain bindings) and restates none of the protocol. [Read Chain] is not bound (Composes 16): it writes nothing, so nothing outlives the invocation.

**The approvers' answers are not a wait.** A chain waits on its approvers for as long as they take, and no rule ends that wait (Non-goal 6); a Pending step is no open act, and nothing in the protocol reads it. What the composition waits on is its own calls — a submit, a step write, a recall, a withdraw and the audit records around them — and those are Recoverable Invocation's (Non-goal 17).

**A recovered initiation leaves its chain live.** An initiation whose transaction committed and whose initiation event did not land stands as an open initiation intent beside a live Pending chain; its approvers may decide meanwhile, and the sweep writes the initiation event from the chain record. Nothing withdraws the chain for the missing record (the initiation recovery the 2026-11-10 decision retired).

**The resolution rides the decision.** The chain's terminal answer commits in the decision transaction that produced it, so it has no wait of its own: the terminating decision's outcome carries the terminal summary, and no separate resolution record, cascade record or closure record is written (Recoverable Invocation Action wiring 6). The resolution is attested under the decider, the chain withdrawal's under the initiator.

**Recoverable Invocation's commit is one call.** Recoverable Invocation's bound commit is one constituent call whose arms the constituent partitions; the initiation transaction is a chain-record write and up to twice the approver set's count of constituent calls, the decision transaction up to two calls and twice the approver set's count more, and the withdrawal transaction a write and twice the approver set's count of calls, each in one database transaction (Term initiation transaction, decision transaction, withdrawal transaction), whose partition belongs to the transaction. Recoverable Invocation's closed list of deviations has no entry for it, and the page treats the transaction as the commit and records the mismatch as an open line (Recoverable Invocation Deviation 2), as Chain of Custody, Capability-Backed Sharing and Propagate Consent Revocation Downstream do.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are its six actions — [Initiate Chain], the three step decisions [Approve Step], [Reject Step] and [Withdraw Step], [Withdraw Chain] and [Read Chain]; the [Trailing] flag; the three scopes it defines for its Permissions instance, [Chains Initiate], [Chains Withdraw] and [Chains Read]; the three quorum rules [All Of N], [M Of N] and [One Of N]; and the refusals it names, [Permission Denied], [Chain State Changed] and [Recording Failure]. The chain states overload Approval Step's step states and are declared, not carded. The deployment settings keep their wire spellings in configuration — `approver_set_minimum`, `approver_set_uniqueness`, `quorum_rule_allowed`, `audit_trail_retention_policy`, `decision_completion_bound`, `intent_candidates_cap`, `application_actor_ref`, `application_credential`, and the Recoverable Invocation instance's own settings under the names that page gives them — and the record sets their own in an implementation, `chain_store`, `chain_to_steps`, `step_to_chain`, `step_to_assignment`, `chain_to_events`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the reconciliation; Recoverable Invocation's sweep; an operator; the chain evaluation; the quorum rule; a cascade; a rebuild; a deployment; a deployment composing Legal Hold; a deployment needing reader authentication; an auditor; a caller; an invocation; an action; a validated initiation; a permitted initiation; an admitted initiation; a submitted initiation; a staffed initiation; a landed initiation; a resolved decision; an admitted decision; a decided decision; a landed decision; a decision action; a terminating evaluation; a terminating act; a validated chain withdrawal; a found chain withdrawal; an open chain withdrawal; an admitted chain withdrawal; a committed chain withdrawal; a landed chain withdrawal; a validated read; a permitted read; a reason-bearing action; a state-changing action.

Term records: the chain records and the four indexes' entries; the intent records, outcome records and refusal records Recoverable Invocation writes for the five state-changing actions through the composition's Audit Trail instance — each an Event Log event carrying one action reference of the chain namespace — with the recovery intents, abandonments and escalations it derives under each kind; and the steps and assignments the composition writes through Approval Step and Assignment.

Term record verbs: EQUAL, administer, admit, alert, answer, append, attest, authenticate, bind, call, carry, change, check, classify, clear, commit, compare, compose, compute, count, decide, declare, define, disclose, evaluate, examine, expire, expose, find, gate, inherit, inject, inspect, join, judge, keep, leave, list, mark, match, name, normalize, notify, open, order, page, pass, place, present, proceed, provision, re-emit, re-open, reach, read, rebuild, recall, record, refuse, relate, release, remove, resolve, retain, retire, retry, run, select, serve, set, share, stamp, start, store, supply, take, write, hold, close, describe, own, stand.

Term value sets: event type = chain.initiation.intended | chain.initiation.initiated | chain.initiation.refused | chain.approval.intended | chain.approval.approved | chain.approval.refused | chain.rejection.intended | chain.rejection.rejected | chain.rejection.refused | chain.step_withdrawal.intended | chain.step_withdrawal.withdrawn | chain.step_withdrawal.refused | chain.withdrawal.intended | chain.withdrawal.withdrawn | chain.withdrawal.refused, with the references Recoverable Invocation derives under each kind. finding = write-ownership. The rest are declared where the section that owns each declares it: chain state, act kind, terminal path, decision, position and the quorum rule.

Term bounds: decision completion bound (decision_completion_bound), reconciliation run bound (Recoverable Invocation's run bound), clock offset allowance (Recoverable Invocation's clock allowance), intent candidates cap (intent_candidates_cap), commit round trip, probe round trip, settling period, approver set minimum (approver_set_minimum), field length cap, id widths, operating skew, retention horizon (audit_trail_retention_policy).

Term cadences: Recoverable Invocation's sweep cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

NOTE: open 2026-11-10-f — the grammar this page is read against is v0.69; the page's migration to it is the maintainer's.

Term terms: composition, constituents, transitive atoms, log read, record read, audit write, verification, step write, chain namespace, state-changing action, act kind, chain bindings, decision key, initiation transaction, decision transaction, withdrawal transaction, commit partition, initiation probe, decision probe, withdrawal probe, terminal summary, recovery identity, chain records, chain record, declared fields, chain id, chain state, terminal instant, landed ids, step list index, step-chain index, step-assignment index, event index, index entry, chain-shape event, chain shape, open initiation window, source event, live index entry, purged index entry, chain rebuild, event rebuild, terminal-data alert, shape alert, assignment history, approver set minimum, approver set uniqueness, allowed quorum rules, audit retention policy, retention horizon, decision completion bound, reconciliation run bound, intent candidates cap, clock offset allowance, invocation id, commit round trip, probe round trip, settling period, probed record, seam, now, id widths, operating skew, reference, capped string, actor reference, subject reference, scope, approver set, approver reference, quorum rule, quorum count, valid quorum counts, reason, reason-bearing action, field length cap, larger payload, payload budget, credential, intent, outcome, refusal record, position, recovery flag, chain results, query, minted id, prefixed reason, initiation intent, initiation event, decision intent, withdrawal intent, approval event, rejection event, step withdrawal event, withdrawal event, resolution event, terminal event, terminating act, decision's outcome, decision, decision's step write, step refusal, initiated instant, trailing flag, validated initiation, permitted initiation, admitted initiation, submitted initiation, staffed initiation, landed initiation, resolved decision, admitted decision, decided decision, landed decision, decision action, chain evaluation, terminating evaluation, validated chain withdrawal, found chain withdrawal, open chain withdrawal, admitted chain withdrawal, committed chain withdrawal, landed chain withdrawal, validated read, permitted read, routed vector, approved count, rejected count, withdrawn count, met vectors, lost vectors, open vectors, routed transition, out-of-band transition, out-of-band mark, rule reason, reconciliation, carried chain record, carried terminal, carrying intent, young record, aged record, write-ownership finding, false closing, finding surface, aged chains, aged chain, settled step, chainless step, cascade, cascade reason, recalled step ids, temporal invalid-request, deterministic arm, quiescent chains, quiescent chain, pre-withdrawal vector, open steps, audit record, committed transition, lifecycle, resolution-terminated chain, withdrawal-terminated chain, pre-intent refusal.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. The section titled Structural-relation invariant templates in `spec-format.md` — the three relations. Execution Contract Read 1 — a failed read answers state-unavailable. record_action, read_record, verify_record, payload cap, reference length cap, attestation id width, step-2, step-3, step-4, invalid-credential, invalid-request, recording-failure, verified, failed-verification, purged, Retained, Purged, committed ids, alerting surface, Erasure Tombstone, Reverse Index, Failed-Attempt Log, Trusted Timestamping, Compromise Disclosure: Audit Trail. submit, approve, reject, withdraw, read, submitted_at, decided_by, withdrawn_by, approved, rejected_outcome, withdrawn, Pending, Approved, Rejected, Withdrawn, invalid-request, not-known, not-pending, unauthorized, storage-failure, invalid-query, string cap, decision instant, withdrawal instant: Approval Step. assign, recall, active_for, history_for, ok, not-active, already-assigned, Active, Recalled: Assignment. permitted, denied: Permissions. open, close, refuse, yield, resolve, sweep, act key, pairing datum, act probe, commit, repeatable, journal, service identity, outcome envelope, invocation completion bound, closure window, sweep cadence, run bound, clock allowance, examine window end, reference length cap, act-in-flight, section-unavailable, journal-unavailable, already-accounted, act-landed, recovery, acting actor reference, act section, compliance surface, run id, operator run id: Recoverable Invocation. Lease: reached through Recoverable Invocation. read: Event Log. Sequenced Approval Chain, Delegation, Deadline Escalation: forthcoming.

Term composing patterns: [Privileged Access Provisioning](./privileged-access-provisioning.md); [Execute Gated Workflow](./execute-gated-workflow.md); [Notification](../atoms/notification.md); [Notification Fanout](./notification-fanout.md); [Legal Hold](../atoms/legal-hold.md); [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md).

#### Initiate Chain

The composition action that creates an approval chain over one subject and scope: it validates the chain shape against the deployment's quorum-rule and approver-set knobs, opens its invocation with `chain.initiation.intended` keyed by the chain id the host injected — the write that verifies the initiator's credential, before anything is created — then, in one transaction, writes the chain record, submits one Approval Step per named approver and binds each to the approver's in-tray, and closes with `chain.initiation.initiated` carrying the chain shape. Gated by [Chains Initiate]. Returns the chain_id; the chain is now Pending. A refused submit or assign creates nothing and answers the constituent's code; an initiation whose close did not land answers recording-failure(outcome) carrying the chain id, the chain live and its initiation event the sweep's.

Kind: Operation

#### Approve Step

The composition action wrapping one approver's Approval Step approval: it opens its invocation with `chain.approval.intended` first — the write that verifies the caller's credential, and the only thing standing between an asserted actor reference and a committed approval, since this action has no Permissions check — then, in one transaction, re-reads the chain state against the intent's [Trailing] flag, approves the step, recalls the in-tray binding and — unless the decision is trailing — re-evaluates the quorum rule, terminating the chain if quorum is now met; it closes with `chain.approval.approved`, which carries the terminal summary where this approval terminated the chain.

Kind: Operation

#### Reject Step

The composition action wrapping one approver's Approval Step rejection: it opens its invocation with `chain.rejection.intended` first (verifying the caller's credential), then, in one transaction, re-reads the chain state, rejects the step, recalls the in-tray binding and re-evaluates the quorum rule, which may transition the chain to Rejected when quorum becomes unreachable; it closes with `chain.rejection.rejected`.

Kind: Operation

#### Withdraw Step

The composition action by which the chain initiator withdraws a single mis-submitted gate (wrong approver or scope) through Approval Step — opening its invocation with `chain.step_withdrawal.intended` first, which verifies the initiator's credential before the withdrawal commits, without retracting the whole chain where quorum remains achievable (a withdrawal that alone makes quorum unreachable cascades the chain to Withdrawn inside the same transaction) — closed with `chain.step_withdrawal.withdrawn` and counted toward quorum-unreachability alongside rejections.

Kind: Operation

#### Withdraw Chain

The composition action by which the chain initiator retracts the whole chain while still Pending. It checks the initiator, opens its invocation with `chain.withdrawal.intended` (verifying the initiator's credential), then, in one transaction, re-reads Pending, sets the chain terminal, cascade-withdraws every still-Pending step, recalls their in-tray bindings and writes the terminal summary; it closes with `chain.withdrawal.withdrawn`, whose terminal summary names the cascade. A cascade withdrawal Approval Step refuses with its temporal invalid-request refuses the whole withdrawal, and the initiator retries. Gated by [Chains Withdraw].

Kind: Operation

#### Read Chain

The read-only query returning chain records and their composed step / assignment / attestation surface — the chain's audit `event_id`s from `chain_to_events`, each answered chain's entry rebuilt first, included, and the terminal summary on a terminal chain — in declared order (ascending `initiated_at`, tie-broken by chain_id). Gated by [Chains Read]; produces no audit event, takes no credential, and is not an act kind (Composes 16).

Kind: Operation

#### Trailing

The flag the composition records on every decision intent, and on the decision's outcome the invocation writes: `true` when the decision lands on a step whose chain had *already* reached a terminal state (a permitted late decision), `false` otherwise. It is the audit-distinguishing signal that makes a late decision provably distinct from an on-chain one — without it a `chain.approval.approved` after the chain's resolution event reads as a contradiction. The routed vector reads it from the intent, so a decision's outcome the sweep recovered, which carries only what Approval Step's records re-derive, need not carry it; the decision transaction re-reads the chain state and refuses a decision whose flag the chain no longer bears out (Action wiring 65).

Kind:       Field
Field of:   the decision intent
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

#### Chain State Changed

The composition's refusal from a decision action whose intent was opened with [Trailing] false but whose decision transaction re-read the chain terminal — another decision or a chain withdrawal ended the chain between the resolution and the commit. Nothing is written but the refusal record; the caller's retry resolves as a trailing decision (Action wiring 65).

Kind:       Member
Member of:  the chain rejection
Role:       Rejection
Projection: chain-state-changed

#### Recording Failure

The composition's rejection for an Audit Trail `record_action` failure at one of Recoverable Invocation's records, surfaced at the composition boundary carrying its position — intent, nothing committed and the action retryable in whole; outcome, the act may have committed and its audit record is the sweep's, with the chain id at [Initiate Chain] for the caller to read the act back by (Action wiring 62); refusal, the act refused and its refusal record the sweep's (Recoverable Invocation Invariant 8.3, Recoverable Invocation Invariant 8.4). invalid-credential is not folded into it: a credential the substrate refuses surfaces under its own code. Nor is a constituent's storage-failure, which refuses the commit under its own code (Action wiring 23), nor a failed read: a constituent's state-unavailable passes through unchanged and writes nothing (Execution Contract Read 1 through 3).

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
[Chain State Changed]: #chain-state-changed
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
formal: verified — multi-party-approval.tla + 17 twins + 8 reachability probes, re-derived 2026-11-10 over the split arc (each state-changing action an open, a commit and a close; the initiation, decision and withdrawal transactions one commit each, a refusal inside one writing nothing), against Recoverable Invocation's contracts (the sweep's closing by this page's initiation, decision and withdrawal probes, the escalation, an operator's resolve unchecked against the records), with a step decided out of band, the write-ownership leg and the chain rebuild's alerts; one model under TLC, 926,652 states (one chain of three slots, the quorum rule chosen at the start, three invocations, one failure, one out-of-band decision); Invariant 1.1, 2.1, 2.2, bypass resistance, 4.1, 4.2, 7.1, the cascade's withdrawn residue (Cascade 2, 14), the trailing re-read (Action wiring 64, 65), the owed outcome (Invariant 5.1), the probes' outcomes and terminal summary (Composition state 6, 7), the terminal-data and shape alerts (Composition state 22, 23), the pairing datum (Capability requirement 37, 38), the write-ownership finding (Reconciliation 20) and the false-closing alert (Reconciliation 50), each broken by a twin alone; Invariant 10.1 through 10.3 inherited from Recoverable Invocation Invariant 1.1, the closure window from Recoverable Invocation Invariant 4.2; not modelled: Recoverable Invocation's mechanism, the clock (the young and aged records, the horizon, Invariant 7.2), Permissions, validation ahead of the open, the cascade's deterministic and superseded arms, a chain record written outside every invocation (Reconciliation 48, 49), the derived indexes; coverage 2026-11-10: owes Alloy (the static data model); owed rows: Invariant 1.3, 1.4; Invariant 1.5; Invariant 3.1 through 3.3; Invariant 4.3; Invariant 5.2, 5.3; Invariant 7.2; Invariant 8.1; Invariant 9.1, 2026-11-10
last gate: 2026-11-11 — Final Critique 19 — full, frozen at 6ea0894 — foundational count 7, not clean, no sample; 2026-11-06 — Final Critique 18 — full, frozen at 56ae031 — foundational count 0, clean, three fresh passes; 2026-11-06 — Final Critique 17 — delta — foundational count 2, not clean, no sample

open:
- 2026-11-05-a · refining · Retention asymmetry 2a; Audit Trail Invariant 8.2b · a held event answers failed-verification carrying purged as a purged one does, and the page does not say where an auditor reads that a hold keeps the event → name the record the auditor reads, a decision on what a hold is
- 2026-11-06-b · refining · Term field length cap; Term query; Primitive policy 4 · a deployment's smaller field length cap makes a query filter malformed that another deployment answers, and the cap's floor does not reach a reference filter → decide whether the cap's floor covers a query filter
- 2026-11-10-a · refining · Composition notes; Term initiation transaction; Term decision transaction; Term withdrawal transaction · Recoverable Invocation's bound commit is one constituent call, and each of this page's three commits is many calls in one database transaction (the initiation up to twice the approver set's count, a decision's cascade up to twice the approver set's count more), a case Recoverable Invocation's closed deviation list does not name (Recoverable Invocation Deviation 2) → carry to Recoverable Invocation's next revision as evidence, or declare it there
- 2026-11-10-b · refining · Reconciliation 20, Reconciliation 45, Reconciliation 48, Reconciliation 49; Term routed transition · a chain record, a terminal or a step decision written before the composition bound its act kinds carries the old vocabulary and no Recoverable Invocation intent, so the leg reads it as uncarried and opens a write-ownership finding until it ages past the horizon, and the routed vector reads such a step decision as out-of-band → decide whether the leg and the routed vector read from a declared cut-over instant, or the old decision intents are read as carrying by a rule of their own
- 2026-11-10-d · refining · Term rule reason; Wiring decision 9 · the Rejected arm's "N − R − W remain achievable" is M-of-N arithmetic (under all-of-N one rejection rejects whatever remains) and the Withdrawn arm names no counts → decide the string each arm carries
- 2026-11-10-e · refining · Action wiring 14; Term initiation probe · the invocation's initiation outcome carries the chain shape and the reason, and the sweep-recovered one the chain shape alone, one reference with two payload shapes → decide whether the recovered outcome carries the reason, read from the first step's stored reason, or the shape is one
- 2026-11-10-f · refining · Term qualifiers · migrated in GRACE lang v0.61, read against v0.69 → migrate
- 2026-11-10-c · refining · Invariant 1.5; Check 1.3; Reconciliation 45; Term chainless step · the leg reads the steps a chain record's step list names, and a chainless step no step list names is left to the auditor's Check 1.3; Approval Step's read has no reason axis, so the leg cannot find a step by its chain-id prefix → decide whether the leg reads by subject reference and submitter, or the auditor's check stays the only reader
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/multi-party-approval.md`; the migration that got it here is in [its history](./multi-party-approval.hist.md).

- **2026-11-10 — The waits retired: the five state-changing actions are five Recoverable Invocation act kinds.** *Chose:* (Scott, 2026-11-09 9:17 PM Central, "A", and 2026-11-10 7:15 AM Central, the wait ruling, "simple DRY"; the map rounds/mpa-ri-map-2026-11-10.md, its directions settled under A, 2026-11-10 7:55 AM Central) the five state-changing actions each bind one act kind — chain.initiation keyed by the chain id the host injects ahead of the open, so no minted-key deviation, chain.approval, chain.rejection and chain.step_withdrawal keyed by the decision key, chain.withdrawal keyed by the chain id, every kind repeatable — with the initiation transaction, the decision transaction and the withdrawal transaction their commits (A: act kinds split by the wait, G1, G2, G15); the intent commits at the open and the outcome at the close, so an Audit Trail fault at the outcome leaves an open intent the sweep closes from the chain record or Approval Step's records, and a constituent's storage-failure is a pre-commit refusal (A: an audit failure composes rather than committing a partial); a refused submit or assign fails the initiation transaction whole, so no partial chain commits and the initiation recovery, its dispositions, the initiation-failed record and the quarantine go (A, G4); a lost initiation event is recovered, the chain left live, not torn down (A, G5); the resolution, the cascade's withdrawals and its supersessions fold into the terminating act's outcome as its terminal summary, written onto the chain record in the same commit, so chain_resolved, the cascade step_withdrawn, cascade_completed and chain_initiation_failed retire and the resolution is attested under the decider (A: kinds split by the wait, the resolution having none of its own, G3, G9); a cascade's temporal invalid-request fails the commit, with the invocation's now injected into Approval Step's seam so that only a clock stepping back meets it, and a deterministic arm proceeds, alerted and named in the summary, so the partial flag, its retry and its closure records go (A, G6, G7; Cascade 14, 15; Capability requirement 37); the trailing flag computed ahead of the open is re-checked inside the decision transaction, a mismatch refused chain-state-changed, and [Withdraw Chain]'s Pending re-read inside its transaction (A: a collision becomes a refusal, G8; Action wiring 64 through 67); every acting action's caller-visible codes Recoverable Invocation's, recording-failure(outcome) answered, [Initiate Chain]'s carrying the chain id, a step refusal and the mismatch leaving a refusal record, the events renamed chain.<kind>.* (A: codes change to Recoverable Invocation's, G14); an operator's outcome detected, not prevented, by the terminal-data alert and the shape alert (Composition state 22, 23), with the false-closing alert in the leg, while the routed vector reads no outcome, so quorum determinism and bypass resistance stay prevented (A: detected, not prevented, with an alert, G11; Reconciliation 50); an intent whose invocation died before its commit escalated for an operator (A, G12); a step decision, a chain record or a terminal no intent carries a write-ownership finding (A: a record with no intent becomes a finding, G13; Reconciliation 20, 48, 49); the mayor's derivable calls taken as the map recommends: one identity, `application_actor_ref`, as the recovery identity, freed once no write of the composition's own actions is attested under it (G10); one completion bound for the five kinds, re-anchored to Recoverable Invocation's span (G16); the chainless-step enumeration and the pre-switch cut-over carried as open lines (G13). Capability requirement 8, 9, 11, 13, 28 through 35, Composition state 5, every live Audit arm rule but 5, Action wiring 15, 39, every live Reconciliation rule but 2, 5, 20 and 39, Cascade 4, 5, 6, 9, Invariant 1.2, 8.2, 10.1 through 10.3, Check 4.2, 5.3, 5.4, 10.1, 10.3, 10.4 and 10.5 tombstoned to what owns them; Composes 13 through 17, Composition state 22 through 25, Capability requirement 37 through 43, Action wiring 64 through 71, Reconciliation 44 through 50, Cascade 14, 15, Check 6.5, 9.1, External check 6, 7, Non-goal 15 through 17 and Cross-record consistency 1 new; the closure table rewritten in Recoverable Invocation's form. Rules 286 to 249. Open lines 2026-11-05-b, 2026-11-06-a and 2026-08-29-u dissolve with the rules and the model they named; 2026-11-06-c is carried, sharpened; 2026-11-10-a, 2026-11-10-b and 2026-11-10-c are opened. *Over:* removing the wait by reversing 2026-10-20 at its other end, so that an Audit Trail refusal of any outcome fails the whole action, which every write here being a database write allows, but which would make Audit Trail's health a precondition of every decision and every withdrawal, so that a deterministic outcome refusal froze every chain on the instance; and keeping the page's own sweep beside Recoverable Invocation, which would have covered the intent-and-outcome pairing twice. *Because:* the waits were self-made: the 2026-10-20 decision kept a committed act when an audit record or a cascade call was refused, and the page then built the initiation recovery and its quarantine, the transition leg's re-emission, the partial-flag retry, a Lease of its own, the compensation window, its cadence, run bound, liveness sum and escalation reach to close them, which Recoverable Invocation owns; sixteen of the twenty-four foundational findings of Final Critique 12 through 17 sat in that machinery or in the audit-arm positions Recoverable Invocation's open, close and refuse own. It turns the 2026-10-20 entry's "stay on the refusals that still reach them", refusal by refusal; the 2026-08-29 entries in part (the sweep's lower edge, its recovery intent and its candidates are Recoverable Invocation's, and the evaluate-first gate loses its subject); the first 2026-08-26 entry in part (the partial-cascade window goes); and the second 2026-08-26 entry (recovery attests under Recoverable Invocation's recovery identity, and the retry loop goes). *Costs:* five bindings and the instance's bounds and sweep, the Lease host the page already had now serving Recoverable Invocation's act section; every acting action's caller-visible codes, which Privileged Access Provisioning relays; the auditor-visible vocabulary, chain_resolved among it, and the resolution's attestation moved from the service identity to the decider; a decision whose chain ended between its resolution and its commit refused chain-state-changed and retried; a chain withdrawal a clock step refuses, which the initiator retries (the partial-cascade run's "the caller still receives withdrawn" no longer holds); operator work for an intent whose invocation died before its commit, which Database 1 had rolled back unseen; Invariant 5.1 and 7.3 fall from prevented to detected against an operator's resolve.
- **2026-10-20 — The store's guarantees cited, not restated, the chain exclusion among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 26), and the twenty-eight rules that restated it, or existed only for a store that could lose or split a write, tombstoned to their owner — the chain store durability the deployment declared and persisted by (Capability requirement 4, Composition state 19), to Store 3 and Store 4; the chain exclusion the host supplied (Capability requirement 15) and every rule holding it across an evaluation, a withdrawal or the sweep's pre-check (Action wiring 33, 42, Reconciliation 6, Concurrency 1, 2), its release on the holder's return and death and at every answer, the bar on running without it, the sweep's skip of a held chain and the bar on serializing two decisions ahead of their evaluations (Capability requirement 16, 17, 18, Action wiring 58, Reconciliation 7, Concurrency 3), and the mid-flight revocation of a credential the intent validated (Audit arm 12), to Store 2; and to Store 1, under which an action's intent, constituent writes, cascade and outcome commit together, the initiation's exclusion that kept the sweep off it (Action wiring 5), the decision's own failed recall riding on its outcome (Action wiring 27), [Withdraw Chain]'s evaluate-first gate, the evaluation leg and its place ahead of the initiation leg (Action wiring 43, Reconciliation 3, 23), the sweep's lower edge (Reconciliation 4), the chainless-step scan (Reconciliation 14), the re-run of a skipped recall and evaluation (Reconciliation 22), the recall leg for calls no partial flag names (Reconciliation 24, 25), the rebuild's hand-off of a retained record to the initiation leg (Composition state 14, 15), and the read-back of a recording-failure at step 4, a split Audit Trail's own rewrite removed (Audit arm 6); with them a submit's or an assign's storage-failure no longer runs the initiation recovery (Action wiring 9, 12) and a decision's outcome carries no partial flag (Action wiring 29); rules 285 to 258. *Over:* a host exclusion on each chain, held across every evaluation, withdrawal and sweep write and released on its holder's return or death; a sweep bounded below by the decision completion bound; and legs that recovered an evaluation, a recall or a cascade withdrawal a crash had lost — the lower edge and the evaluate-first gate are turns of 2026-08-29, below. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice: every write this composition's actions make is a store write, its cascade's included, so Store 2 reads what an evaluation or a withdrawal decides on inside the transaction that writes it, which is what the exclusion was for, and no crash leaves half an action for a leg to find. The initiation recovery, the quarantine, the transition leg's re-emission and the partial-flag retry stay on the refusals that still reach them — a constituent's invalid-request or already-assigned, a refused outcome, a retired service credential, Audit Trail's no-answer arms and Approval Step's temporal invalid-request on a cascade withdrawal; the rebuild still retains every record it cannot produce (Composition state 13), and the decision completion bound stays in the liveness sum (Capability requirement 7, 11). What the composition does for its domain is unchanged.
- **2026-08-29 — The sweep is bounded below as well as above, names candidate intents rather than declaring them unrecoverable, and records its intent before it commits.** *Chose:* `decision_completion_bound` as the transition sweep's lower edge (the horizon it already carried as its upper), `compensation_window` and `reconciliation_cadence` declared; `intent_event_candidates` on every re-emitted record in place of `intent_event_id_unrecoverable = true`; a `chain.recovery_intended` record before every closure that recalls, withdraws, resolves, or re-emits; the cross-store edge case's "atomically or" restated as ordered. *Over:* a sweep whose lower edge was the store-against-events comparison alone, and a flag that said the pairing was unknowable when the records name the candidates. *Because:* the comparison cannot see an invocation that has not written yet, so a sweep inside the bound lands a second outcome for one decision; the candidates are on the trail and naming them is what the pairing rule asks for; and a recall or withdrawal the sweep performs with no record of its own is indistinguishable from a direct call (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*, *Recovery commits under a declared service identity*).
- **2026-08-29 — Recovery is horizon-bounded, evaluate-first, and keyed on the chain's own id.** *Chose:* the initiation leg and the additive rebuild's quarantine apply only inside the audit horizon, with post-horizon chain records declared truth-bearing under `chain_store_durability`; every recovery withdrawal runs the evaluate-first gate and the evaluation leg runs before the initiation leg; each step's stored reason carries its chain_id so the case-(a) scan is exact; every cascade arm is landed with the in-invocation not-pending closing as a supersession. *Over:* an unbounded initiation leg, a recovery that withdrew without evaluating, a scan keyed on subject and initiator, and a cascade whose arms were enumerated only for storage-failure. *Because:* the unbounded leg withdrew every lawfully purged chain at each restart; the ungated recovery overturned credential-verified approvals in the initiator's name; the subject-keyed scan withdrew a concurrently-initiating sibling's step; and the unenumerated arms gave check 2(b) two opposite verdicts on one history.
- **2026-08-26 — Invariant 4 is safety plus liveness at quiescence, not a static always-claim.** *Chose:* the assignment-cascade claim holds at quiescence conditioned on no open recovery marker, with the partial-cascade and step-7 windows named as bounded surfaced transients; check 4 audits under the same structure. *Over:* the static "always both sides" statement. *Because:* the partial-cascade and trailing-decision paths the spec itself describes reach and violate the static form.
- **2026-08-26 — Recovery emissions are composition-attributed and the retry loop runs only on transient failure.** *Chose:* every record emitted outside the original human invocation attests under `application_actor_ref` with the human in `data` and `recovery = true`; invalid-request foreclosed by budget-derived caps; one vocabulary shared with Execute Gated Workflow. *Over:* re-presenting human credentials on retry, or looping on every rejection. *Because:* a human credential is unavailable to a recovery path, and a deterministic rejection retried forever is a stall.

</details>

NOTE: End of Multi-Party Approval.
