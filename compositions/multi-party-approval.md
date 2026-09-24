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

Multi-Party Approval enforces an approval requiring several named approvers, over a single thing, in a way that cannot be bypassed and is fully reconstructable from the records.

The rule for how many approvers are needed is a quorum rule — all of them, a majority, or any one of them. It combines four patterns: the single-approver gate (Approval Step), a permission system controlling who may start, withdraw, or read an approval chain (Permissions), a task-tracker that puts each pending approval in the right approver's queue (Assignment), and the tamper-evident audit record (Audit Trail) that stamps and seals every step.

The load-bearing addition is checking, after each individual decision, whether the quorum has now been met or has become impossible, and ending the chain accordingly — something none of the parts can do, because the single-gate pattern does not count approvals across steps and the others know nothing about quorum at all.

The check is deterministic: anyone with the records can recompute the chain's outcome from the individual decisions and the quorum rule and confirm it. That is what makes the gate impossible to bypass — a chain cannot reach "approved" unless the required decisions are actually present in the records.

Once a chain ends, its outcome and its declared terms cannot change; corrections require a new chain. This is the mechanism behind dual-sign-off financial controls, pharmaceutical batch releases, electronic-signature chains, clinical-trial approvals, and change-control gates — any decision that must prove, from records alone, that a required set of named approvers actually decided before an action proceeded is a candidate for this composition.

---

## Intent

Many regulated actions require more than one human approval before they may proceed. A SOX-controlled (Sarbanes-Oxley Act — US corporate financial-reporting law) journal entry above a materiality threshold requires the regional finance director, the CFO (Chief Financial Officer) *and* the CEO (Chief Executive Officer). A pharmaceutical batch release under 21 CFR (Code of Federal Regulations — the codification of US federal agency rules) Part 211 requires the qualified person on duty plus the QA (Quality Assurance) director. A clinical protocol deviation under ICH E6 GCP (the International Council for Harmonisation's E6 Good Clinical Practice guideline) requires the principal investigator plus, for substantive deviations, the IRB (Institutional Review Board — the committee that oversees research ethics) chair. A high-value engineering change order requires the engineering lead, the quality lead, and (when safety-critical) the safety officer. In each case the structure is the same: a set of named approvers, a quorum rule (all of them, a majority of them, any one of them), and a terminal decision that becomes the auditable evidence the control operated.

[Approval Step](../atoms/approval-step.md) is the per-gate primitive — one named approver, one subject, one scope, one decision. It deliberately does not know about chains: it does not count approvals, does not interpret quorum, and does not wire multiple gates together. Multi-Party Approval is the composition that does. The atom's single-gate scope is preserved unchanged; the composition adds the chain identity, the quorum rule, the cross-step state evaluation, and the cascade (secondary effects triggered automatically by a primary event) behavior when a chain is withdrawn or quorum becomes unachievable.

The composition addresses what the constituent atoms cannot answer alone. Approval Step records each gate but never asks *"is the chain done?"* Permissions records who may initiate a chain but never asks *"did the quorum's named approvers actually decide?"* Assignment binds work to actors but never asks *"is the work part of a multi-actor gate?"* Audit Trail records actions of consequence but never asks *"do these actions constitute a complete approval chain under the named rule?"* Stacked correctly, the four answer the auditor's actual question in one structure: a chain identity that names the required approvers and rule, N Approval Step records under that chain identity, an Assignment record per pending step, attestations and event-log entries for every chain-level and step-level action, and a deterministic chain-state evaluation that any reader can reproduce from the records.

This is a composition, not a new primitive. The four constituents — three atoms and the Audit Trail substrate — are unchanged. The composition is the wiring that makes their concepts coherent — one consolidated multi-party-approval surface rather than four parallel record stores the auditor has to correlate by hand.

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

Term chain namespace: the action references chain_initiation_intended, chain_initiated, chain_initiation_failed, step_decision_intended, step_approved, step_rejected, step_withdrawn, chain_withdrawal_intended, chain_withdrawn, chain_resolved, cascade_completed and chain.recovery_intended on the composition's Audit Trail instance.

WHY:
**Approval Step is one gate and deliberately knows no chain** — it does not count approvals, interpret a quorum or wire gates together, and its own EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) boundary defends that. **Permissions** knows who may start, withdraw or read a chain and nothing of whether the named approvers decided; **Assignment** binds work to an actor and nothing of whether the work is one gate of many; **Audit Trail** records acts of consequence and nothing of whether they make a complete chain under a named rule. Stacked, the four answer the auditor's question in one structure: a chain naming its approvers and rule, one step per slot, one in-tray record per step, an audit event for every act, and a chain outcome any reader recomputes from the records. Event Log, Actor Identity, Tamper Evidence and Retention Window are reached through the substrate and never instanced here (Composes 7 and 8; the section titled Compositions of compositions in `spec-format.md`).

**Assignment supplies the binding, not an in-tray view** (2026-08-26-i). Its queries are keyed by task — active_for and history_for on a task reference — so *which steps sit in my in-tray* is not answerable from its surface, and this composition does not absorb it: an assignee-keyed view is a Reverse Index *(forthcoming)* lookup a deployment builds over the assignment store. The composition reads a step's assignments through history_for on the step id.

**The write surfaces are reserved** (Composes 11 and 12). A step decided by a direct call carries no principal — Approval Step takes no credential and compares references byte for byte — so it is an out-of-band transition the quorum rule never counts (Wiring decision 7); an event written under the chain namespace by another writer would read as this composition's. Reserving both makes either a deployment's conformance failure, reported from the records.

**The log read is declared, not assumed** (Composes 9 and 10; 2026-08-26-h). The rebuilds, the sweep and the checks select by action reference and payload field, and the substrate serves no such read: Audit Trail passes a sequence-range read through to Event Log and routes every query by payload field to Reverse Index. So the route is the pass-through range read with the selection in composition code, and the wired instance must expose it (Capability requirement 21).

Adjacent, **not** constituents: [Privileged Access Provisioning](./privileged-access-provisioning.md) and [Execute Gated Workflow](./execute-gated-workflow.md) compose this chain as their approval surface; [Notification](../atoms/notification.md) and [Notification Fanout](./notification-fanout.md) tell approvers of work (Non-goal 7); [Legal Hold](../atoms/legal-hold.md) suspends purge over the chain's events through the substrate (Capability requirement 24).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the chain store, the step list index, the step-chain index, the step-assignment index AND the event index.
Composition state 2: A chain record MUST carry the declared fields, the chain state, the terminal instant, the quarantine flag AND the landed ids.
Composition state 3: EVERY audit event other than an initiation intent MUST carry the chain id.
Composition state 4: A chain-shape event MUST carry the chain shape.
Composition state 5: An initiation-failed record MUST carry the disposition AND the initiator reference.
Composition state 6: A resolution event MUST carry the chain state, the terminal instant, the reason AND the recalled step ids.
Composition state 7: A withdrawal event MUST carry the terminal instant AND the reason.
Composition state 8: The composition MUST NOT remove a chain record.
Composition state 9: The composition MUST classify a chain record in an open initiation window as truth-bearing.
Composition state 10: The composition MUST classify a live index entry as a derived index.
Composition state 11: The composition MUST classify a purged index entry as truth-bearing.
Composition state 12: The composition MUST rebuild the chain store AND the step list index PER the chain rebuild.
Composition state 13: A rebuild MUST retain EVERY chain record the chain rebuild does not produce.
Composition state 14: A rebuild MUST hand a retained chain record inside the audit horizon to the initiation leg.
Composition state 15: A rebuild MUST NOT hand an aged chain's record to the initiation leg.
Composition state 16: The composition MUST rebuild the step-chain index by inverting the step list index.
Composition state 17: The composition MUST rebuild the step-assignment index through the assignment history of each step id.
Composition state 18: The composition MUST rebuild the event index PER the event rebuild.
Composition state 19: The deployment MUST persist the chain store, the step list index AND the event index PER the chain store durability.
Composition state 20: The composition MUST decide an index entry's horizon by the record read on the entry's source event.
```

Term chain store: the set of chain records — `chain_store` in an implementation.

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

Term event index: the map from a chain id to the event ids recorded for the chain in recording order, each with the step id the event names — `chain_to_events` in an implementation, the declared chain-to-audit traversal.

Term index entry: one key's value in one of the five stores above.

Term chain-shape event: an initiation event or an initiation-failed record.

Term chain shape: the declared fields with the ordered step ids, the paired assignment ids and the initiated instant.

Term open initiation window: the span in which a chain record inside the audit horizon has no chain-shape event.

Term source event: the chain-shape event of a chain record or step list entry, or the event an event index entry names.

Term live index entry: an index entry whose source event the record read answers Retained, or a step-chain or step-assignment entry.

Term purged index entry: a chain record, step list entry or event index entry whose source event the record read answers Purged.

Term chain rebuild: the log read kept to the chain-shape events, each recorded as its chain shape — the initiator from an initiation event's actor, or from an initiation-failed record's payload — with the chain state and terminal instant from the chain's resolution or withdrawal event, Pending where none exists, and the quarantine flag absent.

Term event rebuild: the log read kept to the chain namespace, each event recorded against its payload's chain id with the step id it names, and each initiation intent recorded against the chain record carrying the intent's invocation id.

Term assignment history: Assignment's history_for on a step id as the task — every assignment the step ever carried.

Term chain store durability: the deployment's declaration that the chain store, the step list index and the event index are persisted as primary stores and never rebuilt by replacement — `chain_store_durability`.

WHY:
**Every element is a derived index inside the horizon, and the payload requirement is what makes the rebuilds total** (Composition state 1 through 7, 10 and 12 through 18; the section titled Composition state in `execution-contract.md`). The composition records its chain-level truth *as audit events* through its own substrate, and the rebuilds read it back: every event carries the chain id except the initiation intent, which is written before the chain exists and is joined by its invocation id instead (2026-08-29-e); the chain-shape events carry the whole declared shape with the landed ids and the seam-stamped instant, so the rebuild is byte-exact; the terminal events carry the terminal facts. The step list lives nowhere in Approval Step — its submit takes no chain argument — which is exactly why the composition writes it into its own event. The step-assignment pairing does not need the events: Assignment keys every record by its task, which is the step id, so history_for rebuilds it at any age (Composition state 17; 2026-08-29-m). A missing required field on an event is a conformance failure, not a formatting choice. The usual three obligations attach — outside the atomicity surface, rebuild-on-miss, no cross-constituent consistency claim.

**The rebuild is additive, never a replacement** (Composition state 8, 9 and 13 through 15). Inside an open initiation window the chain record is the only record of the chain, because it exists before its chain-shape event does — and the landed ids ride on it for that reason, so a recovery never scans a constituent store for them. A rebuild that replaced the store there would find no event for that chain and drop it: the repair mechanism destroying the only record it was repairing, at a crash, which is when a rebuild is most likely to run. So the rebuild reconstructs from the events and **retains** every record it did not produce, split by age: inside the horizon a retained record is the initiation leg's to judge (Reconciliation 8), and past it the record is the truth-bearing class, its events lawfully destroyed and nothing owed. Without the split every lawfully purged chain would read as a crashed initiation at the next restart. The initiation leg takes the per-chain exclusion [Initiate Chain] holds through its recovery, so a live initiation is never read as a crashed one; the blindness the prose carried as open is closed by that serialization (2026-08-29-i). **Reconcile, never replace, and never let the repair mechanism outrank the record it is repairing** — the enumeration-anchoring class `roadmap.md` names as methodology debt #19.

**The horizon splits the classification** (Composition state 11, 19 and 20; the section titled *A derived index splits at the horizon* in `pressure-testing.md`). A lawful purge destroys a payload whole and keeps the event id and, through the destruction record, the action reference and the actor. The chain's fields, its step list and its event index lived only in payloads, so past the horizon those entries are the composition's only copy and carry the chain store durability; an implementation that rebuilt the chain store by replacement would discard every post-horizon chain on the first rebuild. The event index keeps even a purged event's id and the step it named, which is what lets the routed rule still recognize a purged decision intent by its surviving action reference and actor (Wiring decision 7). The step-chain and step-assignment entries are derivable at any age — one from the step list, one from Assignment — and so stay derived.

### Capability requirement

```
Capability requirement 1: A deployment MUST set the approver set minimum.
Capability requirement 2: A deployment MUST set the approver set uniqueness.
Capability requirement 3: A deployment MUST set the allowed quorum rules.
Capability requirement 4: A deployment MUST declare the chain store durability.
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
Capability requirement 15: The host MUST supply the chain exclusion keyed by chain id.
Capability requirement 16: The host MUST release the chain exclusion on the holder's return.
Capability requirement 17: The host MUST release the chain exclusion on the holder's death.
Capability requirement 18: IF the host supplies no chain exclusion THEN the composition MUST NOT run a state-changing action.
Capability requirement 19: The host MUST inject now AND the invocation id at the seam once per invocation.
Capability requirement 20: The host MUST inject the chain id at [Initiate Chain]'s seam.
Capability requirement 21: The wired Audit Trail instance MUST expose the log read.
Capability requirement 22: A deployment MUST declare the id widths.
Capability requirement 23: The composition MUST stamp EVERY instant one invocation writes from the invocation's now.
Capability requirement 24: A deployment composing Legal Hold MUST place a subject's hold over the event ids the event index names for the subject's chains.
Capability requirement 25: A deployment needing reader authentication MUST bind the actor reference to an authenticated caller above the composition.
```

Term approver set minimum: the smallest approver set a chain may declare — `approver_set_minimum`, default one; a single-gate chain is degenerate and valid.

Term approver set uniqueness: whether an approver set's references must be pairwise distinct — `approver_set_uniqueness`, default true.

Term allowed quorum rules: the quorum rules the deployment permits — `quorum_rule_allowed`, default [All Of N], [M Of N] and [One Of N].

Term audit retention policy: the retention policy configured on the composition's single Audit Trail instance — `audit_trail_retention_policy`: a seven-year SOX policy, a Part 11 predicate-rule policy, an ICH E6 trial-master-file policy.

Term audit horizon: the audit retention policy's horizon.

Term decision completion bound: the longest a state-changing invocation may run from its intent to its outcome — the sweep's lower edge — `decision_completion_bound`.

Term compensation window: the duration within which an open marker must close or be escalated — `compensation_window`.

Term reconciliation cadence: the interval between the sweep's runs, beside the run at every process start — `reconciliation_cadence`.

Term outcome write latency: the deployment's disclosed bound on one audit write landing.

Term liveness sum: `decision completion bound + reconciliation cadence + outcome write latency`.

Term service identity: the composition's registered actor reference and credential — `application_actor_ref` and `application_credential` — under which the composition attests every write no present human caused.

Term chain exclusion: the host-supplied mutual exclusion on a chain id, under which [Initiate Chain] runs from the chain record through its recovery, every chain evaluation runs, [Withdraw Chain] runs from its gate through its outcome, and the sweep runs every write for the chain.

Term holder: an invocation or a sweep run holding the chain exclusion.

Term invocation id: the fresh id the host injects at the seam per state-changing invocation or sweep run, carried by every event the composition writes and by the chain record an initiation writes.

Term seam: the composition's input and output boundary — the one place the host reads the clock and mints the chain id and the invocation id, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam, once per invocation.

Term id widths: the widest chain id, step id, assignment id and event id the seam and the constituents mint — the substrate's own attestation id width move, so a payload carrying id lists is sized at validation.

WHY:
**The chain-shape knobs are the deployment's** (Capability requirement 1 through 3). A minimum above one makes a genuine multi-party gate; uniqueness true keeps one actor from holding two slots, and under false an actor named twice decides twice — once per step — because quorum is counted per step, and one decision crediting two slots would silently collapse two gates into one. **Retention is the substrate's** (Capability requirement 5 and 6): the audit write takes no per-call retention input.

**Liveness is arithmetic** (Capability requirement 7 through 11; the section titled *Liveness is arithmetic* in `pressure-testing.md`). The bound is the sweep's lower edge: a transition whose intent is younger may belong to an invocation still between its constituent write and its outcome, and a re-emission there lands a second outcome for one decision. An orphan created at *t* is surfaced by `t + bound + cadence` and closed a latency later, so the window must strictly exceed the sum; *a cadence no longer than the window*, which the prose stated, is satisfied by a deployment that breaches on every orphan.

**The service identity is a registered actor, not a special-cased nil** (Capability requirement 12 through 14). It attests the resolution event, the closure records, the initiation-failed record and every recovery emission — the writes no human caused or no human's credential is present for — and its attestations verify like any other. No Permissions grant gates it: the scope vocabulary declares no emit scope and the substrate carries no Permissions layer, so revoking a grant would retire nothing; retiring the credential in the actor registry is what stops a leaked one verifying. Compromise Disclosure *(forthcoming)* owns the reinterpretation of attestations made under a compromised credential, and the rotation discipline stands in until it lands. **The forgery defense is records-alone**: a forged resolution event whose state the step records do not support fails Invariant 2, and the service identity cannot write a step decision — Approval Step's approver exclusivity admits only the named approver — so the attack surface is limited to chain-level claims the step records refute.

**One exclusion per chain, the host's** (Capability requirement 15 through 18; the section titled *Capability provenance* in `pressure-testing.md`). It spans calls of four constituents and no constituent declares one, so it is named here. A deployment that cannot supply it cannot run the write surface conformingly: the terminal-stable guard and the sweep's never-a-second-outcome both rest on it.

**One clock authority and one invocation identity** (Capability requirement 19, 20 and 23; Execution Contract Logic confinement 7). The invocation's one reading stamps the intent, the chain record and the terminal, so an intent and its outcome carry one instant by construction and are never ordered by stamps. The invocation id rides on every event and on the chain record, which makes the initiation intent's join to its chain exact where the prose's tuple of declared fields and instant was not — two same-shape chains by one initiator in one clock instant share the tuple (2026-08-29-e; the section titled *Intents pair with outcomes* in `pressure-testing.md`); it also makes a read-back after an indeterminate audit arm exact (Audit arm 8). Approval Step and Assignment stamp at their own seams, since the composition passes them no instant.

**The holds and the reader are deployment obligations** (Capability requirement 24 and 25). Audit Trail's hold is per event and conditional on composing Legal Hold, so mapping a subject-level hold onto a chain's events is the deployment's, over the event index this composition keeps (2026-08-29-j). [Read Chain] checks a scope over a reference no one verified; binding that reference to an authenticated caller is the calling layer's (Invariant 3.3). A deployment whose regulator tolerates no quarantine may write the initiation event ahead of the constituent writes — write-ahead audit — a variant this composition accommodates and does not require.

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
Primitive policy 17: The composition MUST read a chain id's byte order ONLY as [Read Chain]'s tiebreak.
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

WHY:
**Validation runs before any constituent is called** (Primitive policy 11 and 12): the permission check is itself a constituent call, and the caps are this layer's. **Two caps, for two refusals the substrate would otherwise raise late** (Primitive policy 2 through 4 and 10). Every reference becomes some write's actor reference — an approver reference becomes the actor of that approver's decisions — so a reference over the substrate's reference cap would be accepted at initiation and refused at every decision it tried, leaving an all-of-N chain unreachable; and the capped strings travel whole in every chain-shape event, so their own budget-derived cap is what makes the payload check cover the full constructed data. Sizing the larger of the intent and the outcome — the outcome adds the minted ids — is what makes invalid-request at every audit write unreachable for caller input.

**A required reason is non-blank here, before anything commits** (Primitive policy 9). Approval Step refuses a whitespace-only reason on reject and withdraw, but its refusal arrives too late on one path: [Withdraw Chain] sets the chain terminal before its cascade calls withdraw, and a present-but-blank reason would have every cascade withdrawal refused — a partial cascade no retry could close. With the check here that arm is unreachable for validated input, and the atom's rule is the backstop.

**Opaque and byte-exact** (Primitive policy 13 through 17): nothing is trimmed, case-folded or normalized, so qp_lopez and QP_Lopez are two actors, and the permission match, Approval Step's approver exclusivity and the quorum count all compare bytes. Ids carry no ordering semantics except the one [Read Chain] declares for totality (2026-08-26-r).

### Audit arm

```
Audit arm 1: IF Audit Trail answers invalid-credential at an intent THEN the action MUST answer invalid-credential.
Audit arm 2: IF Audit Trail answers recording-failure at an intent THEN the action MUST answer recording-failure carrying intent.
Audit arm 3: IF Audit Trail answers invalid-request at an intent THEN the action MUST answer invalid-request.
Audit arm 4: The composition MUST NOT retry an invalid-request answer.
Audit arm 5: The deployment MUST alert on EVERY invalid-request from the audit write as a deployment fault.
Audit arm 6: IF Audit Trail answers recording-failure carrying the retention step at an outcome THEN the invocation MUST read the outcome back.
Audit arm 7: IF Audit Trail answers invalid-request at an outcome THEN the invocation MUST read the outcome back.
Audit arm 8: A read-back MUST match the outcome carrying the invocation id.
Audit arm 9: IF the read-back finds the outcome THEN the invocation MUST proceed as landed.
Audit arm 10: IF Audit Trail answers recording-failure carrying a pre-append step at an outcome THEN the action MUST answer recording-failure carrying outcome.
Audit arm 11: IF the read-back finds no outcome THEN the action MUST answer recording-failure carrying outcome.
Audit arm 12: IF Audit Trail answers invalid-credential at an outcome THEN the action MUST answer invalid-credential.
Audit arm 13: The composition MUST NOT retry an outcome inside the invocation.
Audit arm 14: A caller MUST read recording-failure carrying intent as a committed nothing.
Audit arm 15: A caller MUST read recording-failure carrying outcome as a committed act.
```

Term intent: an initiation intent, a decision intent or a withdrawal intent — the audit write an action makes before anything commits, the one that verifies the caller's credential.

Term outcome: an initiation event, an approval event, a rejection event, a step withdrawal event or a withdrawal event — the audit write an action owes after its commit.

Term pre-append step: a recording-failure step naming a step before the substrate's append — step-2 or step-3; the event is not in the log.

Term retention step: the recording-failure step naming the substrate's retention placement — step-4; the event is appended and attested.

Term position: intent | outcome — where a recording-failure sat.

WHY:
**Mapped by position relative to the commit, and by step** (the section titled *A transcribed rejection arm keeps its payload and its reachability* in `pressure-testing.md`). At an intent nothing has committed: every arm is a clean pre-state refusal and the whole action may be retried — none reaches the recovery discipline, which exists to compensate committed writes. At an outcome the constituent write stands: the retention step means the event is appended, and the substrate's invalid-request has the same two faces — a cap source, foreclosed for caller input by the primitive caps, and its retention-configuration source, which arrives with the event appended — so the invocation reads back by its invocation id and proceeds where the event is there, rather than handing the caller a failure over a landed record. An outcome that did not land is the sweep's, never retried in the invocation (Audit arm 13): the sweep re-emits it as the one writer (Reconciliation 17). invalid-credential at an outcome survives only as a mid-flight revocation, since the same credential validated at the intent, and is surfaced as itself over the committed state.

**The position rides the exported code** (Audit arm 14 and 15; the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`). The prose exported a bare token on both sides of every commit. A decision or a withdrawal re-run after an outcome failure is refused not-pending, but an initiation re-run is not refused at all: it opens a second chain beside the first, which the recovery withdraws only while no approver has decided it (Reconciliation 9) — a quarantined chain its approvers drive to Approved stands, and so would its duplicate. The position tells the caller which it is. [Privileged Access Provisioning](./privileged-access-provisioning.md), which composes these actions, maps the recording-failure family and reads either position unchanged.

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

Term chain results: the chains a query matches in declared order, each carrying the chain record, its step records, each step's assignment records, each step's out-of-band mark and the chain's event ids.

Term query: a filter on chain id, subject reference, scope, initiator reference, chain state, or a range on the initiated instant or the terminal instant in Approval Step's `{after, before}` form.

```
Action wiring 1: A validated initiation MUST call the permission check with the actor reference AND [Chains Initiate].
Action wiring 2: IF the permission check answers denied THEN the action MUST answer permission-denied.
Action wiring 3: A permitted initiation MUST record the initiation intent carrying the invocation id, the subject reference, the scope, the approver set, the quorum rule, the reason AND now as the intent instant.
Action wiring 4: An initiation intent MUST NOT carry a minted id.
Action wiring 5: An admitted initiation MUST take the chain exclusion on the chain id.
Action wiring 6: An admitted initiation MUST write the chain record carrying Pending, the declared fields AND now as the initiated instant.
Action wiring 7: An admitted initiation MUST call Approval Step's submit per approver slot in declaration order with the subject reference, the approver reference, the actor reference as the submitter, the scope AND the prefixed reason.
Action wiring 8: An admitted initiation MUST append EVERY step id submit answers to the chain record's landed ids, the step list index AND the step-chain index.
Action wiring 9: IF submit answers storage-failure OR invalid-request THEN the initiation MUST run the initiation recovery carrying disposition a.
Action wiring 10: A submitted initiation MUST call Assignment's assign per step id with the step id as the task AND the step's approver reference as the assignee.
Action wiring 11: A submitted initiation MUST append EVERY assignment id assign answers to the chain record's landed ids AND the step-assignment index.
Action wiring 12: IF assign answers storage-failure, invalid-request OR already-assigned THEN the initiation MUST run the initiation recovery carrying disposition b.
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
Action wiring 23: IF the step write answers storage-failure THEN the decision action MUST answer recording-failure carrying intent.
Action wiring 24: A decided decision MUST call Assignment's recall on the step's assignment id.
Action wiring 25: IF the step-assignment index names no assignment for the step THEN the decided decision MUST NOT call recall.
Action wiring 26: IF recall answers not-active THEN the decided decision MUST proceed.
Action wiring 27: IF recall answers storage-failure THEN the decided decision's outcome MUST carry the partial flag.
Action wiring 28: IF recall OR withdraw answers not-known THEN the deployment MUST alert on the answer as an index anomaly.
Action wiring 29: A decided decision MUST record the decision's outcome carrying the invocation id, the intent event id, the acting actor reference, the chain id, the step id, the reason, the trailing flag, the cascade flag as false AND the partial flag where set.
Action wiring 30: IF the trailing flag EQUALS false THEN a decided decision MUST run the chain evaluation.
Action wiring 31: IF the trailing flag EQUALS true THEN a decided decision MUST NOT change the chain record.
Action wiring 32: A landed decision MUST answer the step write's answer.
Action wiring 33: The chain evaluation MUST run under the chain exclusion.
Action wiring 34: IF the chain state DOES NOT EQUAL Pending THEN the chain evaluation MUST NOT write.
Action wiring 35: IF the quorum rule answers a terminal state on the routed vector THEN the chain evaluation MUST set the chain state to the terminal state AND the terminal instant to now.
Action wiring 36: The chain evaluation MUST NOT run the cascade BEFORE setting the chain state.
Action wiring 37: A terminating evaluation MUST run the cascade with the rule reason.
Action wiring 38: A terminating evaluation MUST record the resolution event carrying the invocation id, the chain id, the chain state, the terminal instant, the rule reason, the recalled step ids AND the partial flag where set under the service identity.
Action wiring 39: A terminating evaluation MUST record the resolution event ONLY AFTER EVERY cascade call answers.
Action wiring 40: A validated chain withdrawal MUST call the permission check with the actor reference AND [Chains Withdraw].
Action wiring 41: IF the chain store carries no record for the chain id THEN [Withdraw Chain] MUST answer not-known.
Action wiring 42: A found chain withdrawal MUST take the chain exclusion on the chain id.
Action wiring 43: A found chain withdrawal MUST run the chain evaluation.
Action wiring 44: IF the chain state DOES NOT EQUAL Pending THEN [Withdraw Chain] MUST answer not-pending.
Action wiring 45: IF the chain's initiator reference DOES NOT EQUAL the actor reference THEN [Withdraw Chain] MUST answer unauthorized.
Action wiring 46: An open chain withdrawal MUST record the withdrawal intent carrying the invocation id, the chain id, the reason AND now as the intent instant.
Action wiring 47: An admitted chain withdrawal MUST set the chain state to Withdrawn AND the terminal instant to now.
Action wiring 48: An admitted chain withdrawal MUST run the cascade with the reason.
Action wiring 49: An admitted chain withdrawal MUST record the withdrawal event carrying the invocation id, the intent event id, the acting actor reference, the chain id, the reason, the terminal instant AND the partial flag where set.
Action wiring 50: A landed chain withdrawal MUST answer withdrawn.
Action wiring 51: A validated read MUST call the permission check with the actor reference AND [Chains Read].
Action wiring 52: IF the query breaks Approval Step's read rules THEN [Read Chain] MUST answer invalid-query.
Action wiring 53: A permitted read MUST answer the chain results.
Action wiring 54: A permitted read MUST read a step's assignment records through the step's assignment history.
Action wiring 55: A permitted read MUST order chains by initiated instant AND then by chain id byte order.
Action wiring 56: [Read Chain] MUST NOT record an audit event.
Action wiring 57: The composition MUST write EVERY landed event's id into the event index with the step id the event names.
Action wiring 58: An invocation MUST release the chain exclusion at EVERY answer.
Action wiring 59: [Approve Step] MUST call Approval Step's approve as the decision's step write.
Action wiring 60: [Reject Step] MUST call Approval Step's reject as the decision's step write.
Action wiring 61: [Withdraw Step] MUST call Approval Step's withdraw as the decision's step write.
```

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

Term partial flag: cascade_partial set to true on a terminal event or a decision's outcome whose cascade or recall left a call unanswered on a transient arm.

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

Term terminating evaluation: a chain evaluation whose quorum rule answered a terminal state.

Term validated chain withdrawal: a [Withdraw Chain] call whose inputs cleared Primitive policy.

Term found chain withdrawal: a validated chain withdrawal whose permission check answered permitted and whose chain id the chain store carries.

Term open chain withdrawal: a found chain withdrawal whose chain stayed Pending through its chain evaluation and whose initiator reference equals the actor reference.

Term admitted chain withdrawal: an open chain withdrawal whose withdrawal intent landed.

Term landed chain withdrawal: an admitted chain withdrawal whose withdrawal event landed or was read back.

Term validated read: a [Read Chain] call whose inputs cleared Primitive policy.

Term permitted read: a validated read whose permission check answered permitted and whose query conforms.

WHY:
**Validation, permission, intent, commits, outcome** — the shape of every state-changing action, and the intent is where the credential is verified. Before the intent existed each action's only audit write came *after* its constituent writes, so an unverified caller could create a chain of N steps and N assignments, or commit an approval, and be refused afterwards. The intent is written before anything commits and every outcome carries its event id back (Invariant 10). The permission check runs before it and commits nothing.

**[Initiate Chain] writes in order, never atomically** (Action wiring 1 through 16). The intent carries the declared shape and no minted id — none exists yet, and an intent naming a chain would put into the trail a chain that may never have been created (Action wiring 4). The chain id is the host's, injected at the seam, and the chain exclusion is taken before the chain record so the sweep never reads a live initiation as a crashed one. Each landed id is appended to the chain record as it is minted, which is what lets the recovery carry the ids that actually landed without scanning a constituent store (Composition state 9). The step's stored reason carries its chain id: the atom mints the step id before the composition appends it, and a crash between leaves a Pending step in no chain's list, which only that prefix attributes to exactly one initiation (Reconciliation 14). already-assigned is unreachable by construction — each task is a freshly minted step id — so it is id reuse, alerted.

**A decision is not gated by its chain** (Action wiring 17 through 32). A chain already terminal still accepts decisions on its trailing Pending steps; the step's own state, checked by the atom, is the gate. The trailing flag records which case a decision was on both its intent and its outcome, so a decision after the chain's resolution reads as declared rather than as a contradiction; one interleaving is benign — a decision that serialized before the terminal can land its outcome after the resolution event, as trailing false, since the flag speaks to the chain's state when the decision resolved, not to record order. **The decision actions carry no Permissions check by design**: authorization is Approval Step's approver and submitter exclusivity, which compares the supplied reference against the step's stored one, and a second check here would be redundant and could drift. Both sides of that comparison were unverified strings until the decision intent — so the intent is the only thing standing between an asserted reference and a committed decision in someone else's name. The atom's invalid-request can reach a well-formed caller after the intent: its temporal rule refuses a decided instant below the step's submitted instant, which cross-seam skew produces and a later reading cures, so the caller retries (2026-08-29-l). The recall discharges the in-tray binding whatever the chain state; not-active is the trailing case, the assignment already recalled by the cascade; a missing assignment — a case-b partial — is never dialed; a failed recall rides on the outcome as the partial flag for the sweep's recall leg.

**The chain evaluation sets the terminal first, then cascades, then resolves** (Action wiring 33 through 39). With the chain already terminal, any re-evaluation a cascade step transition might trigger is a no-op under the terminal-stable guard (Action wiring 34), which is what forecloses a spurious second resolution. The resolution event is the service identity's: the quorum rule fires it, and no caller authorizes it.

**[Withdraw Chain] evaluates before it answers** (Action wiring 40 through 50). A chain stored Pending whose routed vector already satisfies a firing arm carries a lost evaluation from an earlier crash; the gate fires it, so the chain terminates by the rule and the call answers not-pending — never a withdrawal racing a lost evaluation. That is what makes Invariant 2.2's reconstruct-to-Pending sound on every withdrawal event. The gate and the initiator check run before the intent, and the gate's writes are outside the authentication ordering by the rule's own terms (Invariant 10's WHY). Only the initiator withdraws a chain, and only while it is Pending.

**[Read Chain] is a pure projection** (Action wiring 51 through 56). It takes no credential and records nothing. Its malformed-query rules are Approval Step's read rules adopted by reference: a blank string axis, a state outside the four, a range ending before it starts, or an unknown key is invalid-query, never silently ignored. It returns every step's assignment records, not only Pending ones, through history_for on the step id (2026-08-26-i), which surfaces the residue Invariant 4.2's window admits — an Active assignment on a decided step — and each step's out-of-band mark (2026-08-29-h). It surfaces the chain's event ids and leaves the verification to the auditor, who takes each through the substrate's two calls — the record read for the covering seal's range, then the two-argument verification with that range re-presented. The order is total and deterministic: the initiated instant alone is not, since two chains can share a stamp.

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

Term routed vector: the counts (A, R, W, P) over a chain's step list — A the steps Approved by a routed transition, R Rejected by one, W Withdrawn by one, and P `= N − A − R − W`, where N is the step list's length (2026-08-29-a, 2026-08-26-l).

Term approved count: A.

Term rejected count: R.

Term withdrawn count: W.

Term met vectors: under [All Of N], `A = N`; under [M Of N], `A ≥ M`; [One Of N] is [M Of N] with M one.

Term lost vectors: under [All Of N], `R + W ≥ 1`; under [M Of N], `N − R − W < M`.

Term open vectors: the vectors neither met nor lost.

Term routed transition: a step decision a decision intent pairs — one naming the chain id and the step id whose actor equals the step record's decider — or, past the audit horizon, one whose event index entry names an event the record read answers Purged with a surviving action reference of step_decision_intended and a surviving actor equal to the decider; or a cascade withdrawal a cascade step withdrawal event or a closure record names.

Term out-of-band transition: a step decision in the Approval Step store no routed transition covers — written around the composition.

Term rule reason: the generated reason a chain evaluation carries — "quorum met: A of N approved under" and the rule, for Approved; "quorum unreachable:" and the rule, then "N − R − W remain achievable; rejections present", for Rejected; "chain withdrawn by cascade:" and the rule, then "quorum unreachable by withdrawal alone", for Withdrawn — non-blank by construction (2026-08-26-g, 2026-08-29-g, 2026-08-29-p).

WHY:
**Chain state is a deterministic function of the routed step states under the named quorum rule, re-evaluated at each step transition — owned here, and stored nowhere as independent truth.**

*Principle.* The auditor's question is *did the required approvers actually decide?*, and only an outcome that is a pure function of their recorded decisions answers it from the records alone. The composition is the only layer that can own it: Approval Step knows no chain, and the other three know no quorum.

*Likely objection.* Why not let the calling workflow count approvals — it already reads the steps — or push the quorum into Approval Step, where the decisions live?

*Mechanism.* A calling-system count is the unauditable form: the outcome would live in a system no spec governs, and *the chain approved* would be that system's assertion rather than a recomputable fact. Approval Step cannot hold it without ceasing to be the freestanding single-gate atom its EOS boundary defends, since counting across steps needs chain identity. So the rule lives here as a pure function of named counts with no clock term (Wiring decision 5), and the stored chain state is its memo, cross-checkable against the step records at any time (Invariant 2) — which is what makes a forged terminal detectable. The three sets are disjoint: under all-of-N a met vector has no rejection or withdrawal, and under M-of-N a met vector has `A ≥ M` while a lost one has `A ≤ N − R − W < M`. **A rejection outranks a withdrawal** (Wiring decision 2 and 3): a rejection is an approver's negative decision, a withdrawal is the initiator retracting a mis-submitted gate, and the terminal state keeps the two audit signals apart — Rejected names a quorum failure attributable to named decisions; Withdrawn, a chain retracted before its quorum was determined.

**Only routed transitions count** (Wiring decision 6 through 8; 2026-08-29-c). Approval Step takes no credential and its exclusivity check is a byte comparison, so a decision written straight to its store carries no principal, and counting it would let an unauthenticated write move quorum. A decision counts only where a decision intent pairs it — the recovery's own records evidence cascade withdrawals and nothing else, since a forged re-emission under a compromised service credential would otherwise launder an out-of-band decision into a composition-attested one. An out-of-band step counts as Pending, is alerted, is never re-emitted, and is marked on [Read Chain]; the atom's terminal absorption means it cannot be re-decided, so the only lawful resolution is the initiator withdrawing the chain and initiating afresh. **Past the horizon the pairing survives on the attestation** (2026-08-29-d): a purge destroys the decision intent's payload but keeps its action reference and actor through the destruction record, and the event index kept the event id against its step — so a Pending chain whose earlier decisions' intents purged does not demote them to Pending and stall forever.

**Order-independent in outcome, order-sensitive in timing.** For any final vector the terminal state is the rule's, whatever order the transitions came in; the terminal instant is the reading of whichever evaluation first fired under the chain exclusion — the triggering invocation's, [Withdraw Chain]'s gate, or the sweep's evaluation leg (2026-08-26-k). Where the first-firing moment must be adversarially defensible, the substrate's own recording stamps on the triggering event and the resolution event are the pair to compare.

### Reconciliation

```
Reconciliation 1: The sweep MUST run at EVERY process start.
Reconciliation 2: The sweep MUST run every reconciliation cadence.
Reconciliation 3: The sweep MUST NOT run the initiation leg BEFORE the evaluation leg completes.
Reconciliation 4: The sweep MUST NOT examine a young transition.
Reconciliation 5: The sweep MUST NOT examine an aged chain.
Reconciliation 6: The sweep MUST NOT pre-check a chain BEFORE taking the chain exclusion.
Reconciliation 7: IF another holder holds the chain exclusion THEN the sweep MUST leave the chain to the sweep's next run.
Reconciliation 8: IF a chain record inside the audit horizon carries no chain-shape event THEN the initiation leg MUST run the initiation recovery.
Reconciliation 9: The initiation recovery MUST run the chain evaluation.
Reconciliation 10: IF the chain state DOES NOT EQUAL Pending THEN the initiation recovery MUST record the initiation event carrying the chain shape from the chain record AND the recovery flag.
Reconciliation 11: IF the chain state EQUALS Pending THEN the initiation recovery MUST set the quarantine flag.
Reconciliation 12: IF the chain state EQUALS Pending THEN the initiation recovery MUST record the initiation-failed record carrying the chain shape from the chain record, the disposition AND the initiator reference under the service identity.
Reconciliation 13: IF the initiation-failed record lands THEN the initiation recovery MUST set the chain state to Withdrawn AND run the cascade with the recovery reason.
Reconciliation 14: The initiation recovery MUST withdraw EVERY chainless step of the chain PER the cascade.
Reconciliation 15: The initiation recovery MUST record the withdrawal event carrying the recovery flag AND the initiation-failed record's event id under the service identity.
Reconciliation 16: The initiation recovery MUST clear the quarantine flag ONLY AFTER the chain-shape event lands.
Reconciliation 17: IF a routed transition carries no outcome THEN the transition leg MUST re-emit the transition's outcome.
Reconciliation 18: The transition leg MUST match a transition ONLY to an audit record.
Reconciliation 19: The sweep MUST NOT re-emit an out-of-band transition's outcome.
Reconciliation 20: The sweep MUST alert on EVERY out-of-band transition as a conformance fault.
Reconciliation 21: A re-emitted outcome MUST carry the intent candidates, the acting actor reference from the step record AND the recovery flag under the service identity.
Reconciliation 22: The transition leg MUST re-run a re-audited decision's recall AND chain evaluation.
Reconciliation 23: IF a Pending chain's routed vector IS NOT IN the open vectors THEN the evaluation leg MUST run the chain evaluation.
Reconciliation 24: IF a settled step carries an Active assignment AND no partial flag names the step THEN the recall leg MUST call recall on the assignment.
Reconciliation 25: IF a Withdrawn chain carries a Pending step AND no partial flag names the step THEN the recall leg MUST withdraw the step PER the cascade.
Reconciliation 26: The sweep MUST retry a call a partial flag names on a transient arm at EVERY run.
Reconciliation 27: The sweep MUST NOT retry a deterministic arm.
Reconciliation 28: The sweep MUST NOT commit a closure BEFORE the sweep's recovery intent for the closure lands.
Reconciliation 29: A recovery intent MUST carry the invocation id, the chain id, the leg AND the intent candidates.
Reconciliation 30: The sweep MUST record a closure record carrying the chain id, the step id AND the closure mark for EVERY call the sweep closes.
Reconciliation 31: The sweep MUST attest EVERY write the sweep makes under the service identity.
Reconciliation 32: IF an open marker's escalation instant PRECEDES the sweep's now THEN the sweep MUST open an unresolved finding for the chain.
Reconciliation 33: IF Audit Trail answers invalid-credential to the service identity THEN the deployment MUST page on the answer as a service credential fault.
Reconciliation 34: A re-emitted resolution event MUST carry the sweep's recalls AND the late-recalled steps as the recalled step ids.
```

Term sweep: the reconciliation the composition runs outside every invocation — four legs over the records, whose output an auditor awaits within the compensation window.

Term initiation leg: the sweep's leg comparing the chain store against the chain-shape events.

Term transition leg: the sweep's leg comparing the committed step transitions and chain terminals against their audit records.

Term evaluation leg: the sweep's leg firing a Pending chain's lost evaluation.

Term recall leg: the sweep's leg recalling a lost recall and withdrawing a lost cascade withdrawal.

Term young transition: a transition whose intent's intent instant plus the decision completion bound DOES NOT PRECEDE the sweep's now.

Term aged chain: a chain whose initiated instant plus the audit horizon PRECEDES now.

Term settled step: a step that is terminal, or whose chain is terminal.

Term late-recalled steps: the chain's steps whose recall instant DOES NOT PRECEDE the terminal instant — a best-effort set, marked by the recovery flag.

Term initiation recovery: the closure of an initiation that committed constituent writes and landed no chain-shape event — run inside the failing invocation, or by the initiation leg.

Term disposition: a | b | c | d — where the initiation stopped: a at submit, b at assign, c at the initiation event, d a quarantined chain its approvers drove terminal before the recovery ran (2026-08-29-k).

Term initiation-failed record: the chain_initiation_failed event, carrying the intent event id where the recovery runs inside the failing invocation.

Term chainless step: a Pending step whose subject reference, submitter and scope equal the chain's, whose stored reason carries the chain's id, and which no chain record's landed ids name.

Term recovery reason: "initiation-failed recovery (disposition" and the disposition, then ")".

Term intent candidates: every unmatched intent for the transition's chain and step whose actor equals the step record's decider, in log order — intent_event_candidates — or the intent event id alone where one matches.

Term closure record: the cascade_completed event.

Term superseded mark: superseded_by_decision set to true on a closure record.

Term closure mark: retried where the retried call succeeded; superseded_by_decision where a retried withdrawal answered not-pending, the step decided by its named approver in the window; store_anomaly where a retried recall answered not-known (2026-08-26-n).

Term recovery intent: the chain.recovery_intended event.

Term open marker: a quarantine flag set, a partial flag with no closure record for every call it names, or a routed transition with no audit record.

Term escalation instant: an open marker's opening instant plus the compensation window.

Term transient arm: a recording-failure at a pre-append step; a storage-failure on withdraw or recall; Approval Step's temporal invalid-request on a cascade withdrawal, cured by a later reading.

Term deterministic arm: every other arm — not-pending, closed as a supersession; not-known and unauthorized, alerted once.

WHY:
**One discipline, four legs, no second store.** Every marker is the discrepancy itself or a field on a record the composition already writes: the quarantine flag on the chain record; the partial flag on a terminal event or a decision's outcome; the closure records that close it; and the committed transition whose own audit record failed, for which no flag can exist at failure time — the failed call is the record that did not land — so the marker *is* the store-against-events discrepancy. It is **Reconciliation, not Housekeeping**: an auditor awaits its output. **The extraction gate, run** (2026-08-26-m): the quarantine flag is new state the constituents lack, so Gate 3 holds for it — but it is a marker over this composition's own record with no lifecycle of its own beyond set and clear, which names no freestanding concept; the recurring shape it belongs to — intent, outcome, exclusion, terminus, bounded reconciliation — is the one the higher-order composition test in `pressure-testing.md` was written for, and extraction is that test's to decide, not this page's.

**Bounded at both ends, exclusive, as the composition** (Reconciliation 3 through 7, 28, 29 and 31; the sections titled *A reconciliation is bounded at both ends*, *A compensator is exclusive* and *Recovery commits under a declared service identity* in `pressure-testing.md`). Below the bound a transition may belong to an invocation still between its commit and its outcome; past the horizon an absent event is lawful destruction. The evaluation leg runs first, so a quarantined chain carrying a lost evaluation is fired by the rule, never withdrawn by the recovery. Every closure that commits constituent state or emits a transition record is preceded by a recovery intent naming the chain, the leg and the candidates, so the trail shows the sweep occasioned it.

**The initiation recovery evaluates first** (Reconciliation 8 through 16; 2026-08-29-t, -o). Nothing gates decisions on the quarantine flag — approvers must be able to act on a chain whose only defect is a missing record — so a quarantined chain can reach a lawful terminal before the recovery runs, and withdrawing it then would overturn a credential-verified approval in the initiator's name. So the recovery evaluates, and a terminal chain is re-audited, not withdrawn — disposition d, the only case that lands an initiation event rather than an initiation-failed record; cases a, b and c close with the initiation-failed record and an audited withdrawal. The withdrawal event carries the initiation-failed record's id as its provenance and no intent event id: no withdrawal was ever intended. The chainless-step scan is sibling-safe because the prefix names the chain: two chains one initiator opens concurrently over one subject and scope are serialized per chain, not against each other, and a subject-keyed scan would withdraw the sibling's step. A missing assignment is a map miss, never dialed.

**The transition leg re-emits only what an intent authorizes** (Reconciliation 17 through 22). A transition matches only an outcome-shaped record — an intent never does, or a lost outcome would read as audited and the marker would close without opening. The re-emission names the candidates rather than choosing: nothing in the comparison says which invocation's intent owned the lost call, and a step can be named by several. Two inferences are admitted and carried by the recovery flag — the re-emitted trailing flag is derived from the chain's terminal stamps, and a re-emitted resolution's recalled steps are the best-effort set (Reconciliation 34). **The closure duty re-runs the skipped logic**, not only the record: a crash can skip the recall and the evaluation even where every record landed, which is why the evaluation and recall legs exist — a quorum-satisfied chain can never sit Pending for want of another decision call.

**Retry transience, partitioned** (Reconciliation 26, 27 and 30 through 33; 2026-08-26-f). A retry is well formed only over a transient arm, with a landing for every deterministic one — a loop over an arm that answers the same way every time is not a recovery. The transient arms are three, not one. A retried withdrawal answered not-pending was overtaken by the step's named approver in the open window — lawful, and it closes as a supersession; a retried recall answered not-known closes with the anomaly mark so its partial flag cannot stand forever. The substrate's invalid-request is foreclosed for caller input and, from its retention source, arrives with the event appended and nothing owed. invalid-credential on a retry cannot be a caller's — every retry is the service identity's — so it is the deployment's own credential, paged until rotated. Past the window an open marker is escalated as an unresolved finding rather than left as a loop nobody can tell from an abandoned one.

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

WHY:
**The trailing steps are treated by terminal state, by design** (Cascade 1 and 2). Under Approved or Rejected a trailing step stays Pending — Approval Step's terminal absorption applies to steps, not chains — and only its in-tray binding is discharged: the work is moot for the chain, and the approver may still decide it for the record (Invariant 7). Under Withdrawn the trailing steps are withdrawn too, as [Withdraw Chain] does, so a later decision on one is refused not-pending — outside an open partial window, where a withdrawal that failed leaves the step Pending, a decision landing there is lawful and supersedes it, and the retry closes as a supersession rather than pretending it can still withdraw. **Attribution is keyed on one fact** (Cascade 5 and 6): whether the invocation holds the initiator's validated credential. A [Withdraw Chain] or [Withdraw Step] holds it; [Withdraw Chain]'s evaluate-first gate, the sweep, and an approver's own decision completing a lost withdrawal-driven evaluation do not — the approver's credential is validated but is not the initiator's, and Approval Step admits only the initiator's reference on a withdrawal. The key generalizes to any future trigger; a site-by-site list did not. **A partial cascade is housekeeping around a transition that stands** (Cascade 8, 9 and 13): the chain has structurally terminated, the caller gets the decision's success, and the recalled step ids list only what was recalled; an in-invocation not-pending is the same supersession the retry closes with, and Invariant 2.2's reconstruction counts that step as decided.

### Scope vocabulary

```
Scope vocabulary 1: The composition MUST define chains initiate, chains withdraw AND chains read for the Permissions instance.
Scope vocabulary 2: The composition MUST NOT gate a decision action on a Permissions scope.
```

WHY:
Permissions treats scopes as opaque; these three are the minimum useful set, and a deployment distinguishing *read your own chains* from *read any chain* adds finer scopes and wires them. Step decisions are gated by Approval Step's exclusivity instead (Scope vocabulary 2). **The withdrawal authorities are asymmetric by design**: [Withdraw Step] is Approval Step's submitter-only rule, so an initiator who has lost [Chains Withdraw] can still correct one gate — a property of the submitter role earned at initiation — but cannot retract the whole chain, which takes standing chain-level authority. A deployment wanting both to need [Chains Withdraw] adds the check in front of [Withdraw Step].

## Composition-level invariants

These emerge from the composition; none belongs to one constituent, and each needs two or more working together. Three structural relations frame them, per the section titled Structural-relation invariant templates in `spec-format.md`: **chain to steps**, one-to-many, exactly one step per approver slot, mandatory on both sides at quiescence; **step to assignment**, one-to-one, mandatory at creation, recalled and never replaced — the composition performs no reassign; **chain to audit events**, one-to-many, at least one per chain, every event other than an intent naming an existing chain. The inverse directions are read through the derived indexes, and a lost index entry is a rebuild trigger, never a relation violation.

- **Invariant 1 — Chain completeness.**
  ```
  Invariant 1.1: IF a chain IS IN the quiescent chains AND the chain IS NOT IN the recovery-closed chains THEN the chain's step list's count MUST EQUAL the approver set's count.
  Invariant 1.2: IF a chain IS IN the recovery-closed chains THEN the chain's step list MUST EQUAL the landed step ids the chain's initiation-failed record carries.
  Invariant 1.3: EVERY step id in a step list MUST name an Approval Step record.
  Invariant 1.4: The step-chain index MUST name EXACTLY ONE chain for EVERY step id in a step list.
  Invariant 1.5: The Approval Step store MUST carry no chainless step of a quiescent chain.
  ```
  Term quiescent chains: the chains with no invocation in flight and no open marker.

  Term quiescent chain: a chain in the quiescent chains.

  Term recovery-closed chains: the chains whose initiation-failed record landed.

  WHY: every chain has one step per declared slot, fixed at initiation and never extended or replaced; every step submitted through the composition belongs to exactly one chain — steps written around the composition are outside the quantifier, since this composition declares one way in (Composes 11). **The recovery's own terminal is carved in on the invariant** (Invariant 1.2; 2026-08-26-e): a case-a chain closes with fewer steps than slots — none at all where the first submit failed — and that shape is the honest record, verified against the ids its initiation-failed record carries. *Open marker* includes the discrepancy form, so a crash that died before setting the quarantine flag reads as an open window, never as a violation in waiting.
- **Invariant 2 — Quorum determinism, split by terminal path.**
  ```
  Invariant 2.1: IF a chain IS IN the resolution-terminated chains THEN the chain state MUST EQUAL the quorum rule's answer on the chain's routed vector.
  Invariant 2.2: IF a chain IS IN the withdrawal-terminated chains THEN the quorum rule MUST answer Pending on the chain's pre-withdrawal vector.
  ```
  Term pre-withdrawal vector: the routed vector with the chain's cascade step withdrawals, its retry-closed withdrawals and its superseded closures counted back as Pending.

  WHY: the chain's terminal state is verifiable from the records, and how depends on the path, which the terminal event's action reference names (2026-08-27-g — *the withdrawal path*, since recovery-closed chains terminate there with no initiator act). **Resolution** (Invariant 2.1): the rule's terminal sets are absorbing and a trailing decision cannot move a vector out of the set that fired, so recomputing over the final routed vector reaches the stored state — routed, because an out-of-band step contributes Pending by design and a recomputation over raw step states would disagree on purpose (2026-08-29-b). **Withdrawal** (Invariant 2.2): the terminal is set directly while the rule read Pending and the cascade then withdraws every Pending step, so the final vector is not what the chain terminated on — a chain withdrawn while a survivable rejection stood has a final vector the rule maps to Rejected, a lawful history that must not read as a failure. Counting the cascade's work back as Pending recovers the vector the gate evaluated, and a step whose cascade withdrawal was overtaken by a decision was Pending when the initiator acted, whatever it reads now. *Rests on* Wiring decision 1 through 7 and [Withdraw Chain]'s evaluate-first gate (Action wiring 43).
- **Invariant 3 — Permission enforcement.**
  ```
  Invariant 3.1: [Initiate Chain] MUST NOT commit for an actor reference the permission check denied.
  Invariant 3.2: [Withdraw Chain] MUST NOT commit for an actor reference the permission check denied.
  Invariant 3.3: [Read Chain] MUST NOT answer a chain to an actor reference the permission check denied.
  ```
  WHY: over a verified principal for the two state-changing chain actions — the grant checked, then the credential validated by the intent before anything commits (Invariant 10) — and **over a reference for the read**: [Read Chain] takes no credential and records nothing, so a chain's approver set, decisions, deciders and reasons are disclosed to a reference nobody verified. A credential on the read was weighed: with no audit event the substrate's verification is not reached, and a read meta-event — the posture [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md) takes for consent records — would make every read of the auditor's own high-volume surface a write. The gap is the calling layer's and named (Capability requirement 25; Non-goal 11). Existence-hiding is not offered: a denial is itself informative, and an empty answer for *denied* would be indistinguishable from *nothing matches*. Step decisions carry no permission check; Approval Step's exclusivity is their enforcement (Scope vocabulary 2).
- **Invariant 4 — Assignment coverage, safety and liveness at quiescence.**
  ```
  Invariant 4.1: IF a step IS IN the open steps AND the step's chain IS IN the quiescent chains THEN the step MUST carry EXACTLY ONE Active assignment.
  Invariant 4.2: IF a step IS IN the settled steps AND the step's chain IS IN the quiescent chains THEN the step MUST carry no Active assignment.
  Invariant 4.3: The composition MUST NOT recall the assignment of a Pending step in a Pending chain.
  ```
  Term open steps: the Pending steps whose chain is Pending.

  WHY: **safety** (Invariant 4.3): every recall is paired with the step or chain transition that discharges the responsibility. **At quiescence** (Invariant 4.1 and 4.2): the three windows the spec itself describes are bounded, surfaced transients, not violations — a partial cascade leaving trailing assignments Active on a terminal chain, an initiation partial leaving steps briefly assignment-less, and a decision's failed recall leaving one Active assignment on a decided step — each an open marker until the sweep closes it. A static always-both-sides claim would be falsified by exactly those paths. A late decision recalls an already-recalled assignment and reads not-active as done.
- **Invariant 5 — Audit completeness.**
  ```
  Invariant 5.1: IF a chain IS IN the quiescent chains THEN EVERY committed transition on the chain MUST carry EXACTLY ONE audit record.
  Invariant 5.2: EVERY chain namespace event other than an intent MUST name a chain the chain store carries.
  Invariant 5.3: The deployment MUST alert on EVERY orphan attestation carrying a chain namespace action reference.
  ```
  Term audit record: a committed transition's outcome, its cascade step withdrawal event, its closure record, its re-emitted outcome or its resolution or withdrawal event.

  Term committed transition: a step's move out of Pending in the Approval Step store, or a chain's move out of Pending in the chain store.

  WHY: every state-changing action writes one intent and exactly one outcome, every cascade transition its own step withdrawal event — a transition without a record would be a decision of consequence invisible to the trail — and every resolution its own event. **One carve-in** (2026-08-26-f): a cascade call closed by the sweep is recorded by its closure record, since the initiator's credential belonged to the failed invocation and demanding an initiator-attributed record would demand one no honest implementation can produce. **One window**: a committed transition whose outcome failed is open until the transition leg re-emits it and re-runs the skipped recall and evaluation. **The substrate's atomicity is inherited, not re-derived** (Invariant 5.3): Audit Trail's own edge case admits an attestation with no Event Log entry when attest succeeds and append fails; the composition surfaces such an orphan on its own action references, and the claim holds modulo the substrate's contract. *Rests on* Audit Trail Invariant 1 and 3.
- **Invariant 7 — Chain terminal absorption.**
  ```
  Invariant 7.1: The composition MUST NOT change a terminal chain's chain state.
  Invariant 7.2: The composition MUST NOT change a terminal chain's terminal instant.
  Invariant 7.3: Two resolution events MUST NOT carry one chain id.
  Deleted: Invariant 6. Composes 5 owns it.
  ```
  WHY: the chain-level counterpart of Approval Step's terminal absorption on steps. A trailing decision produces its step record and its outcome and moves neither the chain state nor the terminal instant; a second resolution event for one chain is a failure observable from the records — the defense against a re-evaluation race is structural. The deleted invariant asserted each constituent's invariants hold over its instance, which Execution Contract Conformance 8 settles by reference (council read 53).
- **Invariant 8 — Declared fields are immutable.**
  ```
  Invariant 8.1: The composition MUST NOT change a declared field.
  Invariant 8.2: The composition MUST set the quarantine flag ONLY through the initiation recovery.
  ```
  WHY: only the chain state, the terminal instant, the quarantine flag and the landed ids change — the state once out of Pending, the instant once from unset, the flag set once by the recovery and cleared when the chain-shape event lands, the ids appended during the initiation — the same fields Composition state 2 names mutable, so the two sections agree by construction. A chain cannot be re-targeted to a different subject, scope, approver set or rule; a correction is a withdrawal and a new chain.
- **Invariant 9 — Chain reconstructibility, within the audit horizon.**
  ```
  Invariant 9.1: EVERY chain's lifecycle MUST resolve from the chain store, the Approval Step store, the Assignment store AND the chain's events alone.
  ```
  Term lifecycle: the chain record; the ordered step records with each decision, decider, decision instant and reason; each step's assignment records; and the verified attestation of every chain-level and step-level act through the event index.

  WHY: the chain-layer counterpart of the substrate's forensic completability, named apart so the two are never conflated in a citation. Past the horizon a chain is verifiable only to the depth its surviving attestations and its truth-bearing records carry (Retention asymmetry 1), and the checks that walk events run inside it.
- **Invariant 10 — Authentication precedes commitment.**
  ```
  Invariant 10.1: The composition MUST NOT write a chain record BEFORE Audit Trail validates the initiator's credential at the initiation intent.
  Invariant 10.2: The composition MUST NOT call a decision's step write BEFORE Audit Trail validates the caller's credential at the decision intent.
  Invariant 10.3: [Withdraw Chain] MUST NOT set a chain Withdrawn BEFORE Audit Trail validates the caller's credential at the withdrawal intent.
  ```
  WHY: at the five state-changing actions nothing commits before the acting reference's credential validates against the actor registry, and invalid-credential is a pre-state refusal with the whole action retryable. **Three paths are outside the quantifier, and the carve-out is narrow**: [Withdraw Chain]'s evaluate-first gate, the sweep, and an approver's decision completing a lost withdrawal-driven evaluation. They authenticate no principal and commit no decision the recorded step states did not already determine — the rule fires identically for any caller. What they do not do is commit nothing on a named actor's authority: each calls Approval Step's withdraw with the initiator as withdrawer, which the atom admits only for the step's submitter, so **the atom's immutable record says the initiator withdrew a step the initiator never touched** — Approval Step exposes no composition-actor withdrawal. The disambiguator is records-alone: the paired step withdrawal event is the service identity's and carries the recovery flag, and the two records must be read together; the initiation recovery's withdrawals carry the same residue. **The binding half** is where the composition's load-bearing claim rested: the decision actions carry no permission check, and Approval Step's exclusivity compares an unverified reference against a stored one, so a caller who knew an approver's reference could commit that approver's decision and move quorum. The intent establishes the caller *is* the actor compared, for decisions routed through the composition — the routed rule is what tells the two apart (Wiring decision 6). **What a validation does not establish**: that the presenter is the actor — a stolen credential validates — nor a channel binding or replay resistance, nor that the named approver was the *right* one (External check 2). *Rests on* the audit write and the Actor Identity attestation reached through it; Check 10.1 tests the order from the records.

Chain completeness and quorum determinism give *bypass resistance* — a chain cannot read Approved without the quorum-named decisions present, and any reader can verify it. Permission enforcement and audit completeness give *non-repudiation*. Terminal absorption and immutability give *finality* — a terminated chain's outcome is fixed, and corrections are new chains, never edits.

---

## Examples

### Walkthrough — SOX-controlled journal entry, all-of-N quorum

A multinational bank's general-ledger system uses Multi-Party Approval to gate posting of journal entries above the $5M materiality threshold. The deployment configures `approver_set_minimum = 2`, `approver_set_uniqueness = true`, `quorum_rule_allowed = {all-of-N}`, `audit_trail_retention_policy = sox_7_year`.

1. **A controller prepares a journal entry.** Journal entry JE-2026-0441 posts a $12M intercompany transfer. Under the deployment's business rules, materiality of this size requires the regional controller, the CFO, and the CEO (Chief Executive Officer). The controller calls `initiate_chain(actor_ref=controller_morgan, credential=morgan_credential, subject_ref="je-2026-0441", scope="financial:journal-entry:post:materiality-tier-3", approver_set=[finance_director_chen, cfo_park, ceo_walsh], quorum_rule="all-of-N", reason="$12M intercompany transfer per Q1 close")`.
2. **The composition validates and writes.** Validation passes (three pairwise-distinct approvers, all-of-N is allowed, the constructed payload in budget) and Permissions returns `permitted` (`controller_morgan` holds `chains:initiate`). Then — **before anything is created** — the composition records `chain_initiation_intended` → `ev_init_int`, which is where `morgan_credential` is checked against the actor registry; had it not validated, the call would have returned `rejected(invalid-credential)` with no chain, no Approval Steps and no Assignments, and no teardown cascade to run. The payload names the declared chain shape and no chain_id, since none is minted yet. Only then does the composition allocate `chain-2026-0441`, write the chain record in Pending, submits three Approval Steps (`step-001`, `step-002`, `step-003`), creates three Assignments (one per approver's in-tray), and records the `chain_initiated` event carrying `intent_event_id: ev_init_int`. Returns `chain_id = chain-2026-0441`.
3. **The CFO approves first.** `approve_step(actor_ref=cfo_park, credential=park_credential, chain_id=chain-2026-0441, step_id=step-002, reason="Reviewed Q1 close package; transfer is in-policy")` → the composition records `step_decision_intended` → `ev_dec_int_02` first, **which is where `park_credential` is validated — this action has no Permissions check, so that record is the only thing standing between an asserted actor_ref and a committed approval in the CFO's name**; then Step 002 transitions to Approved; the Assignment is recalled; `step_approved` records carrying `intent_event_id: ev_dec_int_02`. Quorum evaluation: `A=1, R=0, W=0, P=2`; all-of-N requires `A == N(=3)`; not satisfied; no quorum failure (no rejections or withdrawals); chain stays Pending.
4. **The controller's regional finance director approves second.** `approve_step(actor_ref=finance_director_chen, credential=chen_credential, chain_id=chain-2026-0441, step_id=step-001, reason="Mapping verified; consolidation rules applied correctly")` → its own `step_decision_intended` record validates `chen_credential`, then the approval commits and `step_approved` carries the join. `A=2, R=0, W=0, P=1`; still not at quorum.
5. **The CEO approves third.** `approve_step(actor_ref=ceo_walsh, credential=walsh_credential, chain_id=chain-2026-0441, step_id=step-003, reason="Reviewed and authorized")` → approved. `A=3, R=0, W=0, P=0`; `A == N`; chain transitions to Approved; `chain_terminal_at` is set; the audit trail records the `chain_resolved` event. The composing workflow system releases JE-2026-0441 for posting.
6. **Three years later, a SOX §404 audit.** The auditor queries `read_chain({subject_ref: "je-2026-0441"})`. The result is one chain in Approved with three step records, nine attestations, nine retention records under the seven-year policy — one initiation intent, one `chain_initiated`, three decision intents, three `step_approved`, and one `chain_resolved`, each `record_action` producing one attestation and one retention record, and a Tamper Evidence seal covering the relevant range. `verify_record` on each Audit Trail event returns `verified`. The auditor confirms (a) Approval Step Invariant 4 was enforced on each step (`decided_by` matched `approver_ref`), (b) Invariant 2 holds (chain state matches the deterministic quorum evaluation), and (c) no chain-state edit occurred after `chain_terminal_at`. Control evidence is complete from the records alone.

*Every invocation in the runs below follows the same order — validation, any Permissions check, the intent record that verifies the caller, the constituent writes, the outcome record carrying `intent_event_id` — and the narrations elide it except where the example turns on it. An implementation that elided it would fail Check 10.1. **[Withdraw Chain] is the one exception**: its evaluate-first gate and its initiator check both run before its intent record, for the reasons Invariant 10 gives.*

### Happy path — FDA Part 11 batch release, M-of-N(2) quorum across three qualified persons

A pharmaceutical manufacturer's batch release system requires any two of three Qualified Persons (QPs — the designated batch-release authorities under EU (European Union) and FDA manufacturing rules) to approve a batch release under 21 CFR Part 211. The deployment uses `quorum_rule = M-of-N(2)`. A batch BR-2026-0412 is ready for release. The QA manager initiates: `initiate_chain(actor_ref=qa_manager, credential=qa_manager_credential, subject_ref="br-2026-0412", scope="pharma:batch-release:bulk", approver_set=[qp_santos, qp_lopez, qp_kim], quorum_rule="M-of-N(2)")` → `chain-2026-0412`. QP Santos approves first (`A=1`); QP Lopez approves second (`A=2`); `A ≥ M`; the chain transitions to Approved without needing QP Kim's decision. QP Kim's step remains Pending unless Kim later decides — the chain has terminated, but the step's submission record is immutable (Approval Step Invariant 1) and the trailing decision, if Kim later approves, is recorded in the audit trail without altering the chain state (Invariant 7). The released batch carries the chain id as its control evidence; an FDA inspector queries the chain and confirms the two named QPs decided affirmatively under their respective Actor Identity attestations.

### Happy path — ICH E6 GCP protocol deviation, one-of-N quorum across a delegated approver pool

A clinical trial protocol deviation at a multi-site study can be approved by any one of the site principal investigators (PIs) on call. The trial coordinator initiates: `initiate_chain(actor_ref=coordinator_lee, credential=lee_credential, subject_ref="dev-2026-1057", scope="clinical-trial:protocol-deviation:non-substantive", approver_set=[pi_chen, pi_okafor, pi_müller, pi_singh], quorum_rule="one-of-N")`. PI Okafor approves: `A=1, M=1`; chain Approved. The other three steps remain Pending in the Approval Step store, their assignments recalled by the cascade. If a fifth approval is needed later (e.g., for a substantive deviation that requires escalation), a new chain is initiated with the appropriate quorum and approver set; the original chain is not modified.

### Rejection path — all-of-N quorum, one approver rejects

In the SOX walkthrough above, suppose the CEO finds the entry suspicious and rejects: `reject_step(actor_ref=ceo_walsh, credential=walsh_credential, chain_id=chain-2026-0441, step_id=step-003, reason="Counterparty not on approved-affiliates list; refer back to finance team for review")` → rejected_outcome. Quorum evaluation: `R = 1 ≥ 1`; under all-of-N the chain transitions to **Rejected** with reason `"quorum unreachable: all-of-N requires every approval; step step-003 was rejected"`. `chain_terminal_at` is set; the audit trail records the chain resolution. JE-2026-0441 is not released for posting; the composing workflow routes the entry back to the controller, who must initiate a new chain for the corrected entry (a fresh chain_id, fresh step ids — no editing of the rejected chain's records).

### Rejection path — chain withdrawal by initiator

In an alternative history of the same chain, the controller submitting JE-2026-0441 discovers a clerical error in the entry before any approver has decided: the chain was opened against the wrong subject. The controller calls `withdraw_chain(actor_ref=controller_morgan, credential=morgan_credential, chain_id=chain-2026-0441, reason="Wrong journal entry id; superseded by new chain on JE-2026-0441-revised")`. The chain transitions to Withdrawn; each of the three still-Pending steps cascades to Approval Step's Withdrawn state; each Assignment is recalled; the audit trail records the chain withdrawal and the three step withdrawals. A new chain is initiated on the corrected entry.

### Selected outcome runs

Three one-paragraph runs over branches the walkthroughs above do not reach — chosen because each exercises a surface the composition's defenses turn on: the withdrawal-driven cascade, the trailing-decision discipline, and the partial-cascade recovery.

**Chain-Withdrawn-by-cascade — a step withdrawal makes quorum unreachable with no rejection.** A three-approver `M-of-N(2)` engineering change chain has one approval in (`A=1`) when the initiator discovers the second gate names the wrong reviewer and calls `withdraw_step(actor_ref=initiator_ross, credential=ross_credential, chain_id=chain-ec-118, step_id=step-b, reason="Wrong reviewer named; superseding chain to follow")`, then realizes the third gate is mis-scoped too and withdraws it the same way. On the second withdrawal the rule reads `A=1, R=0, W=2`: `(N−R−W)=1 < M=2 ∧ R=0 ∧ W≥1` — quorum unreachable purely by withdrawal — so the chain transitions to **Withdrawn**, not Rejected: no approver made a negative decision, and the terminal state says so. The state is set first; there are no still-Pending steps left to cascade-withdraw (`recalled_step_ids = []` on the `chain_resolved` event, whose `data.state = Withdrawn` marks this as the cascade path, distinct from a `chain_withdrawn` event's initiator path); the one approval already recorded stays immutable.

**A trailing decision — the third Qualified Person approves after the chain closed.** Continuing the batch-release example: two days after `chain-2026-0412` reached Approved on the second approval, QP Kim reviews the batch anyway and calls `approve_step(actor_ref=qp_kim, credential=kim_credential, chain_id=chain-2026-0412, step_id=step-kim, reason="Independent review complete; concur")`. Resolution finds the chain terminal — the call is *not* refused (the step's own Pending state is the gate) — and computes `trailing = true`. The atom records the approval, the already-Recalled assignment's recall returns `not-active` (idempotent success), and the audit event lands as `step_approved` with `trailing = true`, `cascade = false`. The chain evaluation does not run: no re-evaluation, no second `chain_resolved`, `chain_store` untouched. An auditor later walking the trail sees a `step_approved` after the chain's `chain_resolved` and reads the flag, not a contradiction.

**A partial cascade and its recovery, closed from the records.** An `all-of-N` chain of four is rejected by its second approver (`R=1` → chain **Rejected**). The cascade must recall three trailing assignments; the Assignment store refuses the third with `storage-failure`. The composition proceeds (no abort), sets nothing back, and emits `chain_resolved` with `data.state = Rejected`, `recalled_step_ids = [step-1, step-3]`, and `cascade_partial = true`; the caller still receives their rejected_outcome — the load-bearing transition succeeded. [Read Chain] now shows a terminal chain with one still-Active assignment: the surfaced residue. At the next restart the recovery discipline retries, the recall lands, and a `cascade_completed` event (composition actor) referencing the chain closes the marker. The auditor's closure procedure — match the failure to its `cascade_completed` — is Check 5.4, run here on a one-element list.

### Regulated adversarial scenarios

Three adversarial reads the composition must survive in regulated contexts:

- **Regulator audit — SOX §404 control evidence query, "show me every chain that approved a material journal entry in Q1 with full attribution."** The auditor queries `read_chain({scope: "financial:journal-entry:post:materiality-tier-3", state: Approved, initiated_at: {after: "2026-01-01T00:00:00Z", before: "2026-03-31T23:59:59Z"}})`. Every chain in the result set carries its approver set, its quorum rule, its constituent step records (with `decided_by` matched to `approver_ref` by Approval Step Invariant 4), and its Audit Trail attestations under the seven-year retention. The auditor independently computes the expected chain state from the step records and the quorum rule and confirms Invariant 2 holds: no chain reached Approved without the quorum-named decisions actually present. The auditor also queries `read_chain({scope: "...:tier-3", state: Pending, initiated_at: {after: ..., before: ...}})` to verify no chain was left unresolved — a non-empty result identifies a stalled material chain — lawful here, since a chain has no deadline (Non-goal 6), and a question for the deployment's deadline policy. The covered entity has documentable, auditable control evidence with no recourse to developer testimony.

- **Disputed approval — FDA Part 11 electronic signature challenge against a chain participant.** An FDA investigator reviewing batch BR-2026-0412 challenges the authenticity of QP Lopez's approval: the actor claims they did not approve the batch. The investigator queries `read_chain({subject_ref: "br-2026-0412"})` and retrieves the chain plus its step records. Step `step-lopez-0412` shows `decided_by: "qp_lopez"`, `decided_at: "2026-04-15T16:04:00Z"`, `decision_reason: "Specification limits met; COA (Certificate of Analysis) reviewed"`. Approval Step Invariant 4 guarantees that the *value* `qp_lopez` was presented and matched `approver_ref` at decision time — that atom takes no credential, and its identity model is byte equality on the reference as supplied, so the record alone does not establish who presented it. What does is the `step_decision_intended` record that **preceded** the decision and the Actor Identity attestation on it: the principal Lopez presented material matching the registry's public material for that reference before the step could be decided (Invariant 10). The bound is the honest one — a stolen credential validates — so the records establish that Lopez's credential was used, not that Lopez was at the keyboard. The Audit Trail's Actor Identity attestation for the corresponding `step_approved` event is then verified against `qp_lopez`'s registered public material at the attestation's own `attested_at` — the substrate's stamp, not Approval Step's `decided_at`, which is another seam's reading. The denied-approval claim cannot be sustained against the structural record without claiming credential compromise; that reinterpretation is the **Compromise Disclosure** *(forthcoming)* composing pattern's responsibility (Capability requirement 14's WHY glosses its status), not the chain composition's.

- **Breach or incident forensics — unauthorized chain initiation investigation.** During a security incident review, the incident response team needs to determine whether any chains were initiated by actors who should not have held `chains:initiate` during a window of suspected privilege escalation (2026-05-01T00:00:00Z through 2026-05-03T23:59:59Z). The team queries `read_chain({initiated_at: {after: ..., before: ...}})` and, for each chain in the window, walks the Audit Trail back to the `chain_initiated` event and verifies its Actor Identity attestation. The team also queries the Permissions store for grants of `chains:initiate` active during the same window; any initiator whose grant was not active at `initiated_at` is a finding — judged under the deployment's operating skew: the grant stamps and `initiated_at` are two seams' readings, so the audit condemns only violations wider than that skew and reads boundary-width discrepancies as inconclusive (Invariant 3's check-time enforcement is the gate; this audit reads its evidence trail). The chain composition's records faithfully document every initiation and outcome; the cross-store verification — initiator attestation vs. Permissions grant state at the initiation timestamp — is the audit operation that surfaces unauthorized chains.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when an external auditor, given the composition's emergent state and the constituent stores, can clear the checks below without recourse to source code, runbooks or developer narration. Every enumeration of audit events runs through the log read; every check that walks events runs inside the audit horizon.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY quiescent chain's step list complete PER Invariant 1.1 AND Invariant 1.2 (Invariant 1.1).
Check 1.2: An auditor MUST find EVERY step id in a step list naming an Approval Step record the step-chain index maps back to the chain (Invariant 1.4).
Check 2.1: An auditor MUST find EVERY resolution-terminated chain's chain state equal to the quorum rule's answer on the chain's routed vector (Invariant 2.1).
Check 2.2: An auditor MUST find the quorum rule answering Pending on EVERY withdrawal-terminated chain's pre-withdrawal vector (Invariant 2.2).
Check 2.3: An auditor MUST NOT run Check 2.1's recomputation on a withdrawal-terminated chain (Invariant 2.2).
Check 3.1: An auditor MUST find the initiator of EVERY initiation event holding [Chains Initiate] at the initiated instant, within the deployment's operating skew (Invariant 3.1).
Check 3.2: An auditor MUST find the actor of EVERY withdrawal event holding [Chains Withdraw] at the terminal instant, within the deployment's operating skew (Invariant 3.2).
Check 4.1: An auditor MUST find EVERY quiescent chain's assignments PER Invariant 4.1 AND Invariant 4.2 (Invariant 4.1).
Check 4.2: An auditor MUST read an Active assignment under an open partial flag as an open marker (Invariant 4.2).
Check 5.1: An auditor MUST find EXACTLY ONE audit record for EVERY committed transition on a quiescent chain (Invariant 5.1).
Check 5.2: An auditor MUST find EVERY chain namespace event other than an intent naming a chain the chain store carries (Invariant 5.2).
Check 5.3: An auditor MUST find the service identity attesting EVERY resolution event, closure record, initiation-failed record AND recovery-flagged event, AND nothing else (Capability requirement 12).
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

Term withdrawal-terminated chain: a chain whose terminal event is a withdrawal event — withdrawn by its initiator, or closed by the initiation recovery.

WHY:
**Completeness and determinism by path** (Check 1.1 through 2.3; 2026-08-29-b). The recomputation runs over the routed vector, since an out-of-band step contributes Pending by design; running it against a withdrawal-terminated chain is a check error, not a finding. A recovery-closed chain verifies against the ids its initiation-failed record carries.

**The permission checks the prose lacked** (Check 3.1 and 3.2; 2026-08-27-e). The grant stamps and the chain's instants are two seams' readings, so the check condemns only violations wider than the deployment's operating skew and reads boundary-width discrepancies as inconclusive; the gate itself is check-time enforcement, and this reads its evidence. Whether the grant was *appropriate* is External check 4. The constituent checks (Check 6.1 through 6.4) are what Composes 5 means, cited rather than counted.

**Audit completeness in both directions** (Check 5.1 through 5.4; 2026-08-29-f). The forward comparison — every committed transition against its audit records — is how the transition leg's marker is read, so an unmatched transition is an open marker, or a finding with the markers closed. The reverse direction excludes intents, since every pre-state refusal leaves one with no chain behind it. The attribution rule is read from each event's actor, action reference, cascade flag and recovery flag.

**Records-alone, one observation** (Check 7.1, 7.2 and 8.1; 2026-08-26-p). The prose compared snapshots; the payload requirement makes a single observation enough — a chain's stored state and terminal instant against its one terminal event, and its declared fields against its chain-shape event.

**The join is the intent event id, the order is the sequence** (Check 10.1 through 10.5). An intent and its outcome carry one instant by construction, so their stamps cannot order them. One initiator opening two chains over one subject and scope is ordinary use, so no join by actor, subject and scope; the initiation intent joins its chain by the invocation id both carry (2026-08-29-e). A re-emitted outcome names candidates, and its check is weaker than the exact join where the set is not a singleton — reported as such. **An intent with no outcome is not a failure**, and the population is large: every pre-state refusal leaves one, and a decision refused by the atom after its intent leaves a permanent, sealed record of an attempt that was authenticated. An auditor reads an intent as *an attempt that was authenticated*, never as *an act that happened*, and never writes a compensating outcome for an intent whose effect cannot be found — that would fabricate a decision or a terminal that never happened.

### External checks

```
External check 1: An auditor needing a reader's identity confirmed MUST read the calling layer's authentication evidence (Invariant 3.3).
External check 2: An auditor needing the approver set's policy fit confirmed MUST read the calling system's policy declaration (Non-goal 4).
External check 3: An auditor needing an approver's standing authorization confirmed MUST read the deployment's standing-authorization registry at the initiated instant (Non-goal 5).
External check 4: An auditor needing a chains initiate grant's appropriateness confirmed MUST read the Permissions-administration layer (Invariant 3.1).
External check 5: An auditor needing an escalated marker's resolution confirmed MUST read the deployment's finding surface (Reconciliation 32).
```

WHY:
The records prove a chain's shape, its decisions and its terminal; they cannot say whether the approver set was the *right* set for the subject under the deployment's regime — *was this $12M entry required to be approved by exactly these three?* — whether each named approver held the standing authority for the scope, or whether the initiator's grant was correctly issued, segregation of duties included. Those are the calling system's and the governance layer's, cross-read at the initiated instant under the deployment's operating skew.

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
```

Term pre-intent refusal: a refusal an action answers ahead of its intent — validation, permission, and at [Withdraw Chain] an unknown chain, not-pending and an initiator mismatch.

WHY:
**Richer quorums and ordering are other compositions** (Non-goal 1 and 2). Weighted votes, conditional quorums that must include named actors, and sequenced chains — the safety officer before the engineering lead — each carry a richer semantics; this chain treats approvers as equal voters and outcomes as order-independent, and submits every step at initiation. Ordering is left to a Sequenced Approval Chain *(forthcoming)*, which would consume the step list as a sequence and refuse an out-of-order decision as *not yet eligible*. **Delegation and segregation of duties are policy layers** (Non-goal 3 through 5): a Delegation pattern *(forthcoming)* intercepts the decision actions and re-authorizes a delegate; a composing Permissions layer refuses an initiation whose initiator and approver set break a declared segregation policy — the uniqueness knob covers only the pairwise-distinct case within one chain — and a chain naming an intern on a controller-only gate is structurally accepted here, the calling system owning the check before it calls.

**A Pending chain has no deadline** (Non-goal 6): the quorum rule carries no clock term, which is what keeps Invariant 2 clock-independent, and an expiry fired inside the composition would break it. A composing scheduler or Deadline Escalation pattern *(forthcoming)* watches the initiated instant through [Read Chain] and withdraws or escalates when its policy elapses — an ordinary, attributed withdrawal. An indefinitely Pending chain is therefore lawful here, and a stalled material chain is a question for the deployment's deadline policy, not a control failure of this composition (2026-08-27-i). **Delivery is its own concept** (Non-goal 7): [Notification](../atoms/notification.md) and [Notification Fanout](./notification-fanout.md) own channels, preferences and retries, and the in-tray binding is the truth a notifier would announce. **Chains are independent** (Non-goal 8): a transaction under both a SOX chain and an AML (anti-money-laundering) chain has two chains, and *every chain on X must approve* is a higher-order policy.

**The audit surface is committed acts plus authenticated attempts** (Non-goal 9): refusals before the intent — validation, permission, and at [Withdraw Chain] an unknown chain, not-pending and an initiator mismatch — leave nothing, and high-assurance deployments compose a Failed-Attempt Log *(forthcoming)*, as Audit Trail's own failed-attribution edge case names. **A decided step is never re-opened under its chain** (Non-goal 10); a redo is a new chain, Approval Step's terminal absorption lifted to the chain. **The reader and the in-tray view are named gaps** (Non-goal 11 and 12; Invariant 3.3; Composes' WHY).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the Event Log sequence as the order of an intent AND the intent's outcome.
Clock semantics 2: The composition MUST NOT compare the terminal instant with a step's decided instant.
Clock semantics 3: The composition MUST NOT pass an instant to a constituent.
```

WHY:
The composition's one reading per invocation stamps the intent instant, the initiated instant and the terminal instant (Capability requirement 23). Approval Step, Assignment and the substrate stamp at their own seams, since the composition passes them no instant (Clock semantics 3), so a chain's terminal instant and the decision that fired it are two readings, and under seam skew the terminal can fall marginally before its cause — which is why nothing rests on comparing them (Clock semantics 2) and every ordering claim reads the substrate's sequence. The quorum rule has no clock term, so skew leaves Invariant 2 untouched. Clock quality is the deployment's; where terminal instants carry legal weight a Trusted Timestamping pattern *(forthcoming)*, the one [Audit Trail](./audit-trail.md)'s clock check names, is the resolution.

### Concurrency

```
Concurrency 1: The chain exclusion MUST span EVERY chain evaluation on one chain.
Concurrency 2: The chain exclusion MUST span [Withdraw Chain] from the chain's evaluation through the chain's outcome.
Concurrency 3: The composition MUST NOT serialize two decisions on distinct steps BEFORE the decisions' chain evaluations.
```

WHY:
Two approvers deciding distinct steps of one chain commit independently at their own atom records; the re-evaluation after each is what races, so it is serialized per chain and reads one consistent vector (Concurrency 1 and 3). Whichever serializes first sets the terminal instant, and the spec promises nothing about which. A withdrawal and a decision on one chain serialize the same way (Concurrency 2); a decision that commits at its own atom while a cascade holds the exclusion is met by the cascade as not-pending — the supersession the cascade closes in-line.

### Retention asymmetry

```
Retention asymmetry 1: The composition MUST keep an aged chain's chain record AND step records.
Retention asymmetry 2: An auditor MUST read failed-verification carrying purged on a chain's event as lawful destruction.
```

WHY:
The audit events purge at the horizon; the step records do not — Approval Step keeps its store for life — and the chain record past the horizon is the truth-bearing half of the chain store. So a chain past its retention still answers [Read Chain] with its structure — who decided what, when, under which approver set — while the verification on its events answers purged: *consistent but staggered*. That satisfies Audit Trail's honest representation of destruction and not an obligation for signatures re-verifiable forever; a deployment needing that configures a longer audit retention, and the composition surfaces the trade rather than resolving it.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are its six actions — [Initiate Chain], the three step decisions [Approve Step], [Reject Step] and [Withdraw Step], [Withdraw Chain] and [Read Chain]; the [Trailing] flag; the three scopes it defines for its Permissions instance, [Chains Initiate], [Chains Withdraw] and [Chains Read]; the three quorum rules [All Of N], [M Of N] and [One Of N]; and the refusals it names, [Permission Denied] and [Recording Failure]. The chain states overload Approval Step's step states and are declared, not carded. The deployment settings keep their wire spellings in configuration — `approver_set_minimum`, `approver_set_uniqueness`, `quorum_rule_allowed`, `chain_store_durability`, `audit_trail_retention_policy`, `decision_completion_bound`, `compensation_window`, `reconciliation_cadence`, `application_actor_ref`, `application_credential` — and the stores their own in an implementation, `chain_store`, `chain_to_steps`, `step_to_chain`, `step_to_assignment`, `chain_to_events`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the sweep; the initiation leg; the transition leg; the evaluation leg; the recall leg; the initiation recovery; the chain evaluation; the quorum rule; a cascade; a rebuild; a deployment; a deployment composing Legal Hold; a deployment needing reader authentication; an auditor; a caller; an invocation; a holder; a validated initiation; a permitted initiation; an admitted initiation; a submitted initiation; a staffed initiation; a landed initiation; a resolved decision; an admitted decision; a decided decision; a landed decision; a decision action; a terminating evaluation; a validated chain withdrawal; a found chain withdrawal; an open chain withdrawal; an admitted chain withdrawal; a landed chain withdrawal; a validated read; a permitted read; a reason-bearing action.

Term records: the chain records and the four indexes' entries; the intents, outcomes, resolution events, initiation-failed records, closure records and recovery intents the composition records through the audit write — each an Event Log event carrying one action reference of the chain namespace; and the steps and assignments it writes through Approval Step and Assignment.

Term record verbs: EQUAL, admit, alert, answer, append, attest, authenticate, bind, call, carry, change, check, classify, clear, commit, compare, compose, compute, count, decide, declare, define, disclose, evaluate, examine, expire, expose, find, gate, hand, inherit, inject, inspect, join, judge, keep, leave, list, mark, match, name, normalize, notify, open, order, page, pass, persist, place, pre-check, proceed, provision, re-emit, re-open, re-run, reach, read, rebuild, recall, record, refuse, relate, release, remove, resolve, retain, retire, retry, run, select, serialize, serve, set, span, stamp, start, store, supply, take, withdraw, write.

Term value sets: chain state, disposition, closure mark, decision, position and the quorum rule are declared where the section that owns each declares it.

Term bounds: decision completion bound (decision_completion_bound), outcome write latency (outcome_write_latency), approver set minimum (approver_set_minimum), field length cap, id widths, compensation window (compensation_window), audit horizon (audit_trail_retention_policy).

Term cadences: reconciliation cadence (reconciliation_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive atoms, log read, record read, audit write, verification, step write, chain namespace, chain store, chain record, declared fields, chain id, chain state, terminal instant, quarantine flag, landed ids, step list index, step-chain index, step-assignment index, event index, index entry, chain-shape event, chain shape, open initiation window, source event, live index entry, purged index entry, chain rebuild, event rebuild, assignment history, chain store durability, approver set minimum, approver set uniqueness, allowed quorum rules, audit retention policy, audit horizon, decision completion bound, compensation window, reconciliation cadence, outcome write latency, liveness sum, service identity, chain exclusion, holder, invocation id, seam, now, id widths, reference, capped string, actor reference, subject reference, scope, approver set, approver reference, quorum rule, quorum count, valid quorum counts, reason, reason-bearing action, field length cap, larger payload, payload budget, credential, intent, outcome, pre-append step, retention step, position, chain results, query, minted id, prefixed reason, initiation intent, initiation event, decision intent, withdrawal intent, approval event, rejection event, step withdrawal event, withdrawal event, resolution event, decision's outcome, decision, decision's step write, step refusal, intent event id, intent instant, initiated instant, acting actor reference, trailing flag, cascade flag, partial flag, recovery flag, validated initiation, permitted initiation, admitted initiation, submitted initiation, staffed initiation, landed initiation, unlanded initiation, resolved decision, admitted decision, decided decision, landed decision, decision action, chain evaluation, terminating evaluation, validated chain withdrawal, found chain withdrawal, open chain withdrawal, admitted chain withdrawal, landed chain withdrawal, validated read, permitted read, routed vector, approved count, rejected count, withdrawn count, met vectors, lost vectors, open vectors, routed transition, out-of-band transition, rule reason, sweep, initiation leg, transition leg, evaluation leg, recall leg, young transition, aged chain, settled step, late-recalled steps, initiation recovery, disposition, initiation-failed record, chainless step, recovery reason, intent candidates, closure record, superseded mark, closure mark, recovery intent, open marker, escalation instant, transient arm, deterministic arm, cascade, cascade reason, recalled step ids, quiescent chains, quiescent chain, recovery-closed chains, pre-withdrawal vector, open steps, audit record, committed transition, lifecycle, resolution-terminated chain, withdrawal-terminated chain, pre-intent refusal.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index classification. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. The section titled Structural-relation invariant templates in `spec-format.md` — the three relations. record_action, read_record, verify_record, payload cap, reference length cap, attestation id width, step-2, step-3, step-4, invalid-credential, invalid-request, recording-failure, verified, failed-verification, purged, Retained, Purged, Reverse Index, Failed-Attempt Log, Trusted Timestamping, Compromise Disclosure: Audit Trail. submit, approve, reject, withdraw, read, submitted_at, decided_by, withdrawn_by, approved, rejected_outcome, withdrawn, Pending, Approved, Rejected, Withdrawn, invalid-request, not-known, not-pending, unauthorized, storage-failure, invalid-query: Approval Step. assign, recall, active_for, history_for, ok, not-active, already-assigned, Active, Recalled: Assignment. permitted, denied: Permissions. read: Event Log. Sequenced Approval Chain, Delegation, Deadline Escalation: forthcoming.

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

The composition action by which the chain initiator retracts the whole chain while still Pending. Its Pending gate **evaluates the quorum rule before it answers**, so a chain whose lost evaluation has left it stored-Pending terminates by the rule and the call returns not-pending rather than withdrawing. Otherwise: it checks the initiator, records `chain_withdrawal_intended` (verifying the initiator's credential), sets the chain terminal, cascade-withdraws every still-Pending step — auditing each (`step_withdrawn`, `cascade = true`) — recalls their in-tray bindings, and audits the withdrawal (`chain_withdrawn`). Gated by [Chains Withdraw].

Kind: Operation

#### Read Chain

The read-only query returning chain records and their composed step / assignment / attestation surface — the chain's audit `event_id`s from `chain_to_events` included, and the `audit_pending` quarantine flag when set — in declared order (ascending `initiated_at`, tie-broken by chain_id). Gated by [Chains Read]; produces no audit event and takes no credential.

Kind: Operation

#### Trailing

The flag the composition records on every step-decision audit event: `true` when the decision lands on a step whose chain had *already* reached a terminal state (a permitted late decision), `false` otherwise. It is the audit-distinguishing signal that lets an auditor tell a late decision from an on-chain one from the records alone — without it a `step_approved` event after the chain's `chain_resolved` reads as a contradiction. Its sibling flag cascade (backticked, not carded) marks the composition's own cascade-emitted step withdrawals; the two never overlap — a cascade record is part of the termination (`trailing = false`), a trailing record comes after it (`cascade = false`).

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

The composition's rejection for a constituent `storage-failure` or an Audit Trail `record_action` failure surfaced at the composition boundary, carrying its position — intent, nothing committed and the action retryable in whole; outcome, the act committed and its audit record the sweep's — the failure the partial-state recovery paths and the `audit_pending` quarantine address. invalid-credential is not folded into it: a credential the substrate refuses surfaces under its own code, over whatever committed constituent state the recovery paths own.

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

- **Sarbanes-Oxley §404 (15 U.S.C. (United States Code) §7262) — Internal control over financial reporting.** Material financial actions require multi-actor approval; SOX auditors query the approval chain to confirm the control existed and operated. The composition is the structural form. Composes with Audit Trail's SOX §802 retention obligation (7 years).
- **FDA 21 CFR Part 211 (Current Good Manufacturing Practice for Finished Pharmaceuticals)** — batch release requires authorization by a Qualified Person (QP) or equivalent designated authority. Multi-QP releases under M-of-N(M) quorum are the canonical composition for high-value batches and for batches requiring QA-plus-QP dual signoff.
- **FDA 21 CFR Part 11 (Electronic Records; Electronic Signatures)** — each approval in a chain is an electronic signature event. Part 11 §11.50 requires signatures be attributable; §11.70 requires they be linked to records to prevent removal, substitution, or falsification. The composition's Audit Trail substrate (with Actor Identity providing the cryptographic binding and Tamper Evidence providing the linking) satisfies both.
- **ICH E6(R3) Good Clinical Practice — Guideline.** Sections 4–5 require documented approvals at multiple points in the trial lifecycle, often by multiple parties (investigator, sponsor, IRB). One-of-N over a delegated PI pool is a recurring composition shape for non-substantive deviations; M-of-N is the form for substantive deviations requiring both PI and sponsor approval.
- **ISO 9001:2015 §8.5.1 (Control of production and service provision)** and **§7.5.3 (Control of documented information)** — the International Organization for Standardization's quality-management standard; controlled changes require approval by named authorities. Multi-party chains map to ISO 9001 documented-procedure approval requirements.
- **ISO 13485:2016 §7.3 (Design and development)** — medical device design changes require multi-disciplinary approval (design lead, quality, regulatory affairs, often clinical). M-of-N quorum is the structural form.
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
formal: pending — vote yes 2026-06-03, but no model file exists on disk; the vote entry's "model present" is unevidenced
last gate: 2026-08-29 — second gate after closure, fresh reader — 7 foundational (all since closed), 14 refining, 6 rhetorical

open:
- 2026-08-29-u · refining · formal · the model's sweep carries no lower edge and no recovery record → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/multi-party-approval.md`.

- **2026-09-24 — Rewritten in GRACE lang v0.61; forty of forty-one open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` (the quorum rule), `Reconciliation` (the recovery discipline, as four legs), `Cascade` and `Scope vocabulary` as the surfaces; invariant numbers 1 through 5 and 7 through 10 unchanged, Invariant 6 tombstoned to Composes 5; the seven acceptance checks renumbered by the invariant each tests, with the permission and constituent checks the prose lacked; the edge cases split into Non-goals and three Edge cases families. Choices the page left open, each decided by a standing rule: the invocation id the seam injects rides on every event and on the chain record, so the initiation intent joins its chain exactly (2026-08-29-e — *Intents pair with outcomes*); the routed vector defined for all four counts with P derived, a decision routed only by its decision intent, and a purged intent still recognized by its surviving action reference and actor through the event index (2026-08-29-a, -b, -c, -d, 2026-08-26-l); the position exported on every action that straddles a commit, because a re-run initiation is not refused (*A composition's own rejection arm carries the retry bit*); the retention-step arm and the retention-source invalid-request read back by invocation id and proceeding as landed (*A transcribed rejection arm keeps its payload*); the compensation window set against the liveness sum rather than the cadence alone (*Liveness is arithmetic*); the step-assignment pairing rebuilt through Assignment's history_for at any age (2026-08-29-m, 2026-08-26-i); the resolution reason declared on every arm (2026-08-26-g, 2026-08-29-g); a retried recall answered not-known closed with an anomaly mark (2026-08-26-n); and the extraction gate run on the recovery discipline, its verdict left to the higher-order composition test (2026-08-26-m). *Over:* the prose's step lists, a case list ordered a, b, d, c under *order of severity*, a terminal instant defined as *the first moment the rule fired* that two stamping sites contradicted, and an open finding the per-chain serialization had already closed. *Because:* the rules state each landing once; the formal line stays open because the model, not the page, is what it owes.
- **2026-08-29 — The sweep is bounded below as well as above, names candidate intents rather than declaring them unrecoverable, and records its intent before it commits.** *Chose:* `decision_completion_bound` as the transition sweep's lower edge (the horizon it already carried as its upper), `compensation_window` and `reconciliation_cadence` declared; `intent_event_candidates` on every re-emitted record in place of `intent_event_id_unrecoverable = true`; a `chain.recovery_intended` record before every closure that recalls, withdraws, resolves, or re-emits; the cross-store edge case's "atomically or" restated as ordered. *Over:* a sweep whose lower edge was the store-against-events comparison alone, and a flag that said the pairing was unknowable when the records name the candidates. *Because:* the comparison cannot see an invocation that has not written yet, so a sweep inside the bound lands a second outcome for one decision; the candidates are on the trail and naming them is what the pairing rule asks for; and a recall or withdrawal the sweep performs with no record of its own is indistinguishable from a direct call (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*, *Recovery commits under a declared service identity*).
- **2026-08-29 — Recovery is horizon-bounded, evaluate-first, and keyed on the chain's own id.** *Chose:* the initiation leg and the additive rebuild's quarantine apply only inside the audit horizon, with post-horizon chain records declared truth-bearing under `chain_store_durability`; every recovery withdrawal runs the evaluate-first gate and the evaluation leg runs before the initiation leg; each step's stored reason carries its chain_id so the case-(a) scan is exact; every cascade arm is landed with the in-invocation not-pending closing as a supersession. *Over:* an unbounded initiation leg, a recovery that withdrew without evaluating, a scan keyed on subject and initiator, and a cascade whose arms were enumerated only for `storage-failure`. *Because:* the unbounded leg withdrew every lawfully purged chain at each restart; the ungated recovery overturned credential-verified approvals in the initiator's name; the subject-keyed scan withdrew a concurrently-initiating sibling's step; and the unenumerated arms gave check 2(b) two opposite verdicts on one history.
- **2026-08-26 — Invariant 4 is safety plus liveness at quiescence, not a static always-claim.** *Chose:* the assignment-cascade claim holds at quiescence conditioned on no open recovery marker, with the partial-cascade and step-7 windows named as bounded surfaced transients; check 4 audits under the same structure. *Over:* the static "always both sides" statement. *Because:* the partial-cascade and trailing-decision paths the spec itself describes reach and violate the static form.
- **2026-08-26 — Recovery emissions are composition-attributed and the retry loop runs only on transient failure.** *Chose:* every record emitted outside the original human invocation attests under `application_actor_ref` with the human in `data` and `recovery = true`; invalid-request foreclosed by budget-derived caps; one vocabulary shared with Execute Gated Workflow. *Over:* re-presenting human credentials on retry, or looping on every rejection. *Because:* a human credential is unavailable to a recovery path, and a deterministic rejection retried forever is a stall.

NOTE: End of Multi-Party Approval.
