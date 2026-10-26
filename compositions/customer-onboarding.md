---
title: Customer Onboarding
parent: Conceptual Compositions
nav_order: 16
has_toc: true
toc: true
---

# Customer Onboarding

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Customer Onboarding is a regulated composition (a spec that wires two or more atoms — freestanding, self-contained pattern specs — together) that solves a problem none of its constituents solves alone: ensuring that an external party (customer, counterparty, beneficial owner) reaches regulated activity only after their identity has been verified through an attributed, tamper-evident process, that the relationship is monitored on an ongoing basis with adverse triggers driving suspension, and that the identity record survives for the regulator-mandated period after the relationship ends. It wires three constituents: Party Identity (the persistent, verifiable identity record with its Unverified → Verified → Suspended → Closed lifecycle), Retention Window (the policy-bounded record lifetime, used in two distinct placements — one renewed through the relationship, one at relationship end), and the Audit Trail substrate (the tamper-evident — designed so unauthorized changes are detectable — regulated-audit substrate that attribution-stamps and seals every state-changing decision).

The composition's defining emergent guarantee (a property that appears only when atoms are combined — no single atom carries it) is verification-gates-activity: a single read-only query, [Activity Permitted], answers permitted if and only if the party has an onboarding case with Customer Onboarding **and** Party Identity reports the party in `Verified` state — a party verified outside the composition's own case surface does not pass. Activity systems consume this query rather than reading Party Identity directly, so the gate is implemented exactly once instead of re-implemented (or skipped) per activity system. Customer Onboarding is the layer that centralizes both that the `Verified` state was reached through an attributed, tamper-evident verification (recorded in the Audit Trail) and that the gate query is the single surface activity consumes. This is the structural form of the check-the-customer-before-business obligation that US banking law names Customer Due Diligence (CDD) under the Bank Secrecy Act / Anti-Money Laundering rules (BSA/AML).

Beyond the gate, the composition guarantees four further emergent properties. Every `Unverified → Verified` transition produces a tamper-evident Audit Trail event carrying the verification identifiers. Every adverse monitoring trigger produces an Audit Trail event ordered before any suspension it precipitates, so no trigger-driven suspension exists in the records without its precipitating trigger ordered ahead of it. A party reinstated after an adverse trigger has a passed verification recorded after the most recent suspend, and the clearing actor — whose credential this composition verifies — attests that the fresh evidence was recorded before the reinstatement. The party record is under a live Retention Window placement at every instant of the relationship — renewed at each periodic review, because a placement is fixed-duration and nothing else renews it — and a closed party's record cannot be purged before its post-closure floor (the BSA/AML five-year period under 31 CFR (Title 31 of the Code of Federal Regulations) section 1020.220) elapses.

Its most common uses are retail and commercial bank customer onboarding under BSA/AML, broker-dealer counterparty onboarding, payments-processor merchant onboarding, and crypto-exchange customer onboarding under the EU 5th Anti-Money Laundering Directive (AMLD5). Any system that must make it provable that every party with regulated activity was verified before that activity, that adverse triggers were acted on, and that closed-party records were retained for the mandated post-closure period, is a candidate for this composition.

---

## Intent

Every financial institution that admits an external customer faces the same regulated arc, and the arc is the same whether the institution is a retail bank, a broker-dealer, a payments processor, or a crypto exchange. The customer's identity must be established and verified before regulated activity begins; the verified status must be the precondition any account-opening, transaction, or service-provisioning system checks; the relationship must be monitored on an ongoing basis so that a sanctions match, a politically-exposed-person (PEP — Politically Exposed Person) status change, or adverse media triggers suspension and re-verification; and when the relationship ends, the identity record and its Customer Due Diligence (CDD) evidence must survive for a regulator-mandated period after closure. FATF (Financial Action Task Force — the international standard-setter for anti-money-laundering and counter-terrorist-financing rules) Recommendations 10–12 name the arc as Customer Due Diligence: identify, verify, conduct ongoing monitoring. BSA/AML (Bank Secrecy Act / Anti-Money Laundering) 31 CFR section 1020.220 fixes the record-retention floor at five years after the business relationship ends. The domain varies; the structural obligation is constant.

Neither Party Identity nor Retention Window, alone, enforces this arc. Party Identity owns the verification lifecycle — Unverified, Verified, Suspended, Closed — and refuses a reinstatement without a recorded passed verification after the most recent suspension (Party Identity Invariant 4). But Party Identity exposes no gate: it records that a party is Verified, and it neither enforces that activity systems consult that state nor knows what regulated activity means. Retention Window owns the record-lifetime clock, and knows nothing of when a relationship begins or ends; it takes a `policy_ref` and a `record_ref` and enforces a no-early-purge guarantee, nothing more. The Audit Trail substrate records attributed, tamper-evident, retention-bounded events, and does not know which events constitute a verification chain or a monitoring history. The structure that makes the three coherent as a single Customer Due Diligence surface — the gate that centralizes the verification precondition, the monitoring schedule that drives re-verification, the placements that bracket the relationship — belongs to no single constituent. It belongs to the composition, and this composition is that structure.

This is a composition, not a new primitive. Party Identity, Retention Window, and Audit Trail are unchanged; the composition is the wiring that makes them coherent as a single Customer Due Diligence surface. It introduces emergent actions — [Initiate Onboarding], [Clear Review], [Activity Permitted] — that belong to no single constituent and exist only because the three are wired together. [Clear Review], in particular, wraps a Party Identity `verify(passed)`, a Party Identity `reinstate`, and two Audit Trail records into one named surface, so that clearing an adverse-trigger investigation is a single auditable act rather than a sequence of leaked atom internals an operator must orchestrate by hand.

What the composition is *not*: it is not the verification workflow (document OCR (Optical Character Recognition), biometric check, sanctions-database query — those produce the verification result Party Identity records); it is not the risk-scoring or enhanced-due-diligence (EDD) engine; it is not the consent surface for downstream non-obligatory processing (the Customer Due Diligence processing basis is GDPR (General Data Protection Regulation) Article 6(1)(c) legal obligation, not consent); and it is not the scheduling engine (the composition holds schedule state and an external scheduler fires the monitoring triggers). Each is named explicitly in Non-goals.

---

## Composes

- **[Party Identity](../atoms/party-identity.md)** — the persistent, verifiable identity record and its lifecycle.
- **[Retention Window](../atoms/retention-window.md)** — the policy-bounded lifetime of the party record.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate every decision is recorded through.

```
Composes 1: EXACTLY ONE Party Identity instance MUST serve the composition.
Composes 2: EXACTLY ONE Retention Window instance MUST serve the composition.
Composes 3: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 4: The composition MUST NOT change a constituent's spec.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST read Audit Trail as a substrate PER the section titled Substrate composition invocation in `execution-contract.md`.
Composes 7: The composition MUST NOT hold an instance of a constituent Audit Trail reaches.
Composes 8: The party retention instance MUST NOT govern an audit event.
Composes 9: The composition MUST reach a constituent through the constituent's declared surface.
Composes 10: The composition MUST NOT read a constituent's records beside the constituent's declared read.
Composes 11: The composition MUST NOT call Retention Window's purge.
Composes 12: The composition MUST read the substrate's events by an open-ended sequence range.
Composes 13: The composition MUST select an event in the composition's own code.
Composes 14: The composition MUST NOT query the substrate by a payload predicate.
Composes 15: The composition MUST attest an invocation's audit record under the calling actor's credential.
Composes 16: The composition MUST attest the reconciliation's audit record under the service identity.
Composes 17: The composition MUST NOT attest the reconciliation's audit record under a calling actor's credential.
Composes 18: The composition MUST call Party Identity's enroll ONLY IF the direct path stands.
Composes 19: The composition MUST own EVERY verification transition on the Party Identity instance.
Composes 20: A deployment MUST NOT admit a second writer of a verification transition on the Party Identity instance.
Composes 21: The composition MUST place a party retention through Retention Window's place_under_retention.
Composes 22: The composition MUST read a placement's policy reference, retention instant, retention deadline AND purge eligibility through Retention Window's declared read.
Composes 23: The composition MUST read a party's state through Party Identity's declared read.
Composes 24: The composition MUST read an audit record through Audit Trail's read_record.
Composes 25: The composition MUST verify an audit record through Audit Trail's verify_record.
Composes 26: The composition MUST NOT call Audit Trail's purge_event.
```

Term composition: this pattern's wiring of [Party Identity](../atoms/party-identity.md), [Retention Window](../atoms/retention-window.md) and the [Audit Trail](./audit-trail.md) substrate — the six actions, the gate, the four indexes and the reconciliation.

Term constituents: [Party Identity](../atoms/party-identity.md), [Retention Window](../atoms/retention-window.md), [Audit Trail](./audit-trail.md).

Term party retention instance: the one [Retention Window](../atoms/retention-window.md) instance this composition wires over party records — distinct from the instance [Audit Trail](./audit-trail.md) carries for the substrate's own events.

Term service identity: application_actor_ref and application_credential — the composition's own registered actor and credential, and the attested emitter of every record the reconciliation writes.

Term direct path: an [Initiate Onboarding] call carrying no party id, on which the composition enrolls the party.

Term external path: an [Initiate Onboarding] call carrying a party id External Onboarding already enrolled.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store a case-to-monitoring index.
Composition state 2: The composition MUST store a party-to-case index.
Composition state 3: The composition MUST store a case-to-retentions index.
Composition state 4: The composition MUST store a case-to-open-triggers index.
Composition state 5: The composition MUST classify EVERY index as derived index.
Composition state 6: EVERY index MUST carry a rebuild.
Composition state 7: An index MUST NOT stand inside an action's atomicity surface.
Composition state 8: An index MUST NOT claim cross-constituent transactional consistency.
Composition state 9: An action MUST read an index under rebuild on miss.
Composition state 10: An absent index entry MUST stand as a miss.
Composition state 11: An index entry carrying no value for a read field MUST stand as a miss.
Composition state 12: An empty open-trigger set MUST NOT stand as a miss.
Composition state 13: A false active flag MUST NOT stand as a miss.
Composition state 14: An absent post closure placement MUST NOT stand as a miss.
Composition state 15: A rebuild MUST select an event over an open-ended sequence range.
Composition state 16: A rebuild MUST select an event by the event's action reference.
Composition state 17: A rebuild MUST read an event's action reference through Audit Trail's read_record.
Composition state 18: A rebuild MUST NOT read an aged-out event's payload.
Composition state 19: A rebuild MUST recognize an aged-out event PER event.
Composition state 20: An entry whose binding-bearing events stand aged out MUST stand unrebuildable.
Composition state 21: An unrebuildable entry MUST NOT stand as a miss.
Composition state 22: The composition MUST alert on an unrebuildable entry.
Composition state 23: The rebuild of the party-to-case index MUST select the initiated events AND the retention renewed events.
Composition state 24: The rebuild of the party-to-case index MUST take the case id AND the enrollment path from the latest selected payload PER party id.
Composition state 25: The rebuild of the party-to-case index MUST write the case's active flag set to true ONLY IF no party closed event names the case id.
Composition state 26: The rebuild of the case-to-monitoring index MUST take the party id from the latest binding-bearing payload PER case id.
Composition state 27: The rebuild of the case-to-monitoring index MUST take the opening instant from the initiated payload.
Composition state 28: The rebuild of the case-to-monitoring index MUST take the next review due from the latest schedule-bearing payload PER case id.
Composition state 29: The rebuild of the case-to-retentions index MUST take the current placement from the latest placement-bearing payload PER case id.
Composition state 30: The rebuild of the case-to-retentions index MUST take the post closure placement from the party closed payload.
Composition state 31: The rebuild of the case-to-open-triggers index MUST select the adverse monitoring triggered events PER case id.
Composition state 32: The rebuild of the case-to-open-triggers index MUST drop a trigger a trigger voided event names.
Composition state 33: The rebuild of the case-to-open-triggers index MUST drop a trigger a party closed event's open triggers at close names.
Composition state 34: The rebuild of the case-to-open-triggers index MUST drop a trigger a review cleared event's closed triggers names ONLY IF the clearance's party reinstated event stands landed.
Composition state 35: The composition MUST populate an index ONLY AFTER the index's backing outcome.
Composition state 36: EXACTLY ONE active case MUST stand PER party.
Composition state 37: A case MUST name EXACTLY ONE party.
Composition state 38: EXACTLY ONE current placement MUST stand PER active case.
Composition state 39: A case MUST NOT carry two post closure placements.
Composition state 40: A closed case MUST carry a post closure placement.
Composition state 41: An open trigger MUST name EXACTLY ONE case.
Composition state 42: A case MAY carry no open trigger.
Composition state 43: A case MAY carry two open triggers.
Composition state 44: A party-to-case entry MUST name a party the Party Identity instance holds.
Composition state 45: A case-to-retentions entry MUST name a retention the party retention instance holds.
Composition state 46: A case-to-monitoring entry MUST stand for a closed case.
Composition state 47: The composition MUST NOT drop a case-to-monitoring entry.
Composition state 48: The composition MUST NOT store a review due flag.
Composition state 49: The composition MUST NOT store an overdue flag.
Composition state 50: The composition MUST NOT duplicate a constituent's records.
```

Term case-to-monitoring index: case_to_monitoring — the composition's index from a case id to the case's party id, opening instant and [Next Review Due]; the auditor's first query surface for monitoring continuity.

Term party-to-case index: party_to_case — the composition's index from a party id to the party's case id, enrollment path and active flag; the gate's first read and the join an auditor makes from an activity record to an onboarding case.

Term active flag: true | false — whether a case is open: true from the case's initiated record, false once a landed party closed record names the case (Composition state 25, Action wiring 130).

Term active case: a case whose active flag EQUALS true.

Term case-to-retentions index: case_to_retentions — the composition's index from a case id to the current placement and the post closure placement.

Term case-to-open-triggers index: case_to_open_triggers — the composition's index from a case id to the open adverse triggers standing against the case, each carrying a trigger id, a trigger type, a trigger ref and a trigger instant.

Term index: the case-to-monitoring index, the party-to-case index, the case-to-retentions index, OR the case-to-open-triggers index.

Term current placement: the latest active relationship retention the composition placed over a case's party — active_relationship_retention_id.

Term post closure placement: the retention [Close Party] places over the party record at the relationship's end — post_closure_retention_id.

Term audit horizon: the age past which the audit instance has destroyed an event's payload, set by the instance's audit_trail_retention_policy.

Term aged-out event: an event whose age exceeds the audit horizon.

Term rebuild: the composition's named regeneration of an index — select this composition's events over an open-ended sequence range, keep the events the index names by action reference, and take the index's fields from their payloads in Event Log order.

Term miss: an index read the composition answers by rebuilding rather than by the stored value.

Term unrebuildable entry: an index entry every one of whose binding-bearing events stands aged out.

Term binding-bearing payload: an initiated payload OR a retention renewed payload — the two that carry a case's case id, party id and enrollment path.

Term schedule-bearing payload: an initiated payload, a verification recorded payload carrying a next review due, a monitoring triggered payload carrying a next review due, OR a party reinstated payload.

Term placement-bearing payload: an initiated payload OR a retention renewed payload.

Term landed record: an audit record the substrate has appended and attested, whatever the substrate then answered.

Term owed record: an audit record this composition must write and the substrate has not appended.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The host MUST supply a case id at the seam PER admitted initiation.
Capability requirement 3: The host MUST supply a trigger id at the seam PER admitted trigger.
Deleted: Capability requirement 4. Execution Contract Logic confinement 3 owns it.
Capability requirement 5: The transition MUST NOT mint an id.
Deleted: Capability requirement 6. Execution Contract Logic confinement 3 owns it.
Capability requirement 7: The composition MUST NOT mint a party id.
Capability requirement 8: The composition MUST NOT mint a verification id.
Capability requirement 9: The composition MUST NOT mint a state change id.
Capability requirement 10: The composition MUST NOT mint a retention id.
Capability requirement 11: The composition MUST NOT mint an event id.
Capability requirement 12: The composition MUST NOT generate cryptographic material.
Capability requirement 13: A deployment MUST configure the audit instance with an audit retention policy.
Capability requirement 14: The binding floor MUST NOT EXCEED the audit horizon.
Capability requirement 15: A deployment MUST set the active relationship policy.
Capability requirement 16: A deployment MUST set the post closure policy.
Capability requirement 17: The post closure minimum MUST NOT EXCEED the post closure policy's duration.
Capability requirement 18: A deployment MUST set the monitoring interval.
Capability requirement 19: A deployment MUST set the scheduler tolerance.
Capability requirement 20: A deployment MAY start an instance ONLY IF the active relationship policy's duration EXCEEDS the renewal floor.
Capability requirement 21: A deployment MUST set the adverse trigger types.
Capability requirement 22: The adverse trigger types MUST NOT carry the periodic trigger type.
Capability requirement 23: A deployment MUST set the onboarding completion bound.
Capability requirement 24: A deployment MUST set the compensation window.
Capability requirement 25: A deployment MUST set the reconciliation cadence.
Capability requirement 26: A deployment MUST disclose the audit write latency.
Capability requirement 27: A deployment MAY start an instance ONLY IF the compensation window EXCEEDS the closure floor.
Capability requirement 28: A deployment MUST provision the service identity as a registered actor.
Capability requirement 29: A deployment MUST rotate the service identity's credential.
Capability requirement 30: A deployment MUST set a field cap PER payload field.
Capability requirement 31: A field cap MUST NOT EXCEED the audit instance's payload cap.
Capability requirement 32: A deployment MUST set the trigger set cap.
Capability requirement 33: The audit instance MUST serve an open-ended sequence range read.
Capability requirement 34: The audit instance MUST serve read_record for an aged-out event.
Capability requirement 35: The party retention instance MUST serve a placement read carrying the policy reference, the retention instant, the retention deadline AND the purge eligibility.
Capability requirement 36: The Party Identity instance MUST serve a singleton read by party id.
Capability requirement 37: A deployment MUST resolve a policy reference at Retention Window's seam.
Capability requirement 38: The composition MUST NOT reconcile two policies.
Capability requirement 39: An activity system MUST NOT read the Party Identity instance.
Capability requirement 40: A deployment MUST run a review scheduler outside the composition.
Capability requirement 41: The composition MUST NOT fire a review.
Capability requirement 42: A deployment under the Bank Secrecy Act and Anti-Money Laundering rules MUST alert on an owed record.
Capability requirement 43: A deployment MUST NOT set the monitoring interval PER party at this composition.
Capability requirement 45: The deployment MUST supply the database PER Execution Contract Database 1 through 4 and Execution Contract Read 1 through 3.
Deleted: Capability requirement 44. Execution Contract Logic confinement 7 owns it.
```

Term seam: the composition's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects one clock reading, one case id and one trigger id here.
Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term transition: the composition's evaluation of one call against the constituents, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term monitoring interval: monitoring_interval — the deployment's declared duration between a party's periodic reviews.

Term scheduler tolerance: scheduler_tolerance — the deployment's declared allowance for how late the external scheduler may fire a due review.

Term renewal floor: `(monitoring_interval + scheduler_tolerance)` — the interval a placement's duration must outlast for the chain to stay continuous under a late review.

Term binding floor: the monitoring interval taken with the scheduler tolerance and the post closure policy's duration — the age a binding-bearing event's payload must survive to.

Term closure floor: `((onboarding_completion_bound + reconciliation_cadence) + audit write latency)` — the longest interval in which the reconciliation can close an open marker.

Term onboarding completion bound: onboarding_completion_bound — the deployment's declared maximum duration between an invocation's intent and the invocation's outcome.

Term active relationship policy: active_relationship_policy_ref — the deployment's recommended Retention Window policy for a live relationship's party record.

Term post closure policy: post_closure_retention_policy_ref — the Retention Window policy [Close Party] applies.

Term post closure minimum: the applicable regulatory floor on a closed party's record — five years after the relationship ends under BSA/AML 31 CFR section 1020.220.

Term adverse trigger types: adverse_trigger_types — the deployment's set of trigger_type values that drive suspension; canonically sanctions-match | pep-status-change | adverse-media.

Term periodic trigger type: periodic-review-due — the one non-adverse trigger type.

Term trigger set cap: trigger_set_cap — the deployment's declared maximum number of open triggers a payload carries in full.

Term field cap: the deployment's declared maximum size of one audit payload field.

### Primitive policy

```
Primitive policy 1: An action MUST call a constituent ONLY AFTER the boundary predicate.
Primitive policy 2: The boundary predicate MUST refuse a blank opaque input.
Primitive policy 3: The boundary predicate MUST refuse a blank actor reference.
Primitive policy 4: The boundary predicate MUST refuse a blank method.
Primitive policy 5: The boundary predicate MUST refuse a blank evidence reference.
Primitive policy 6: The boundary predicate MUST refuse a blank reason.
Primitive policy 7: The boundary predicate MUST refuse a trigger type outside the trigger vocabulary.
Primitive policy 8: The boundary predicate MUST refuse a verification result outside the verification results.
Primitive policy 9: The boundary predicate MUST refuse a composed suspend reason exceeding Party Identity's reason cap.
Primitive policy 10: The composition MUST NOT normalize an opaque input.
Primitive policy 11: The composition MUST NOT fold an opaque input's case.
Primitive policy 12: The composition MUST NOT trim an opaque input.
Primitive policy 13: The composition MUST compare an opaque input by byte identity.
Primitive policy 14: An action MUST answer invalid-request for a boundary predicate refusal.
Primitive policy 15: The composition MUST propagate a constituent's invalid-request as invalid-request.
Primitive policy 16: The composition MUST NOT judge an enrollment field.
Primitive policy 17: The composition MUST NOT cap a reason beside Party Identity's reason cap.
Primitive policy 18: The composition MUST truncate a payload field exceeding the field's cap.
Primitive policy 19: A truncated payload field MUST carry the truncation marker.
Primitive policy 20: The composition MUST carry an open-trigger set exceeding the trigger set cap as the trigger count AND the set digest.
Primitive policy 21: The boundary predicate MUST refuse a blank retention policy reference.
```


Term boundary predicate: the composition's own validation of an input at an action's boundary, judged before any constituent call.

Term opaque input: party id | case id | trigger id | trigger ref | actor reference | verifying actor reference | closing actor reference | credential | retention policy reference.

Term actor reference: actor reference | verifying actor reference | closing actor reference | enrolling actor reference.

Term trigger vocabulary: the periodic trigger type OR a member of the adverse trigger types.

Term verification results: passed | failed.

Term truncation marker: the marker a payload field carries when the composition has cut the field to the field's cap.

Term set digest: a content-derived summary of an open-trigger set, standing in the payload where the set itself exceeds the trigger set cap.

### Identity

```
Identity 1: A case MUST carry a case id.
Identity 2: The seam MUST allocate a case id.
Identity 3: A case id MUST stand immutable.
Identity 4: The composition MUST NOT reuse a case id.
Identity 5: A trigger MUST carry a trigger id.
Identity 6: The seam MUST allocate a trigger id.
Identity 7: A trigger id MUST stand immutable.
Identity 8: The composition MUST NOT reuse a trigger id.
Identity 9: An intent MUST carry the case id.
Identity 10: An intent MUST carry the invocation's inputs.
Identity 11: An intent MUST NOT carry a constituent-minted id.
Identity 12: An intent MUST carry the injected now as intent instant.
Identity 13: An outcome MUST carry the intent's event id as intent event id.
Identity 14: The composition MUST pair an outcome to an intent by the intent event id.
Identity 15: The composition MUST NOT pair an outcome to an intent by a payload resemblance.
Identity 16: The composition MUST NOT pair an outcome to an intent by the case id.
Identity 17: A trigger path's intent event id MUST name the monitoring triggered event.
Identity 18: A case MUST NOT identify a party.
Identity 19: A party id MUST NOT identify a case.
```

Term intent instant: the instant an intent records (Identity 12).

Term intent event id: the event id the substrate answers for an intent, carried by the outcome paired to it (Identity 13, Identity 14).

Term opening instant: the instant an initiated outcome records (Action wiring 146).

Term trigger instant: the instant a monitoring triggered outcome records (Action wiring 147).

Term suspension instant: the instant a party suspended outcome records (Action wiring 148).

Term renewal instant: the instant a retention renewed outcome records (Action wiring 149).

Term clearance instant: the instant a review cleared outcome records (Action wiring 150).

Term reinstatement instant: the instant a party reinstated outcome records (Action wiring 151).

Term closure instant: the instant a party closed outcome records — a committing closure's injected now (Action wiring 152).

Term intent: the record_action call naming what an invocation is about to do, written before any committing call — `customer-onboarding.initiation-intended` | `customer-onboarding.verification-intended` | `customer-onboarding.clearance-intended` | `customer-onboarding.closure-intended` | `customer-onboarding.monitoring-triggered` | `customer-onboarding.recovery-intended`.

Term outcome: the record_action call naming what an invocation did — `customer-onboarding.initiated` | `customer-onboarding.verification-recorded` | `customer-onboarding.party-suspended` | `customer-onboarding.trigger-on-suspended-party` | `customer-onboarding.trigger-voided` | `customer-onboarding.retention-renewed` | `customer-onboarding.review-cleared` | `customer-onboarding.party-reinstated` | `customer-onboarding.party-closed`.

Term committing call: `PartyIdentity.enroll` | `PartyIdentity.verify` | `PartyIdentity.suspend` | `PartyIdentity.reinstate` | `PartyIdentity.close` | `RetentionWindow.place_under_retention` — a constituent call that writes outside the audit instance.

### Audit arm

```
Audit arm 1: An invocation MUST make a committing call ONLY AFTER the landed intent.
Audit arm 2: IF Audit Trail answers invalid-credential at an intent THEN the action MUST answer invalid-credential.
Audit arm 3: IF Audit Trail answers invalid-request carrying a step below step-3 at an intent THEN the action MUST answer invalid-request.
Audit arm 4: IF Audit Trail answers recording-failure at an intent THEN the action MUST answer recording-failure carrying intent.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Deleted: Audit arm 6. Execution Contract Database 1 owns it.
Audit arm 7: The composition MUST leave an appended intent standing as an open marker.
Deleted: Audit arm 8. Execution Contract Database 2 owns it.
Audit arm 9: IF Audit Trail answers invalid-request carrying any step at an outcome THEN the action MUST answer recording-failure carrying outcome.
Audit arm 10: IF Audit Trail answers recording-failure at an outcome THEN the action MUST answer recording-failure carrying outcome.
Audit arm 11: A caller MUST read recording-failure carrying intent as a committed nothing.
Audit arm 12: A caller MUST read recording-failure carrying outcome as a committed act.
Audit arm 13: A caller MUST NOT retry an action answering recording-failure carrying outcome.
Deleted: Audit arm 14. Execution Contract Database 1 owns it.
Deleted: Audit arm 15. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an owed record.
Deleted: Audit arm 16. Reconciliation 8 and Execution Contract Database 1 own it.
Deleted: Audit arm 17. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an owed record.
Deleted: Audit arm 18. Execution Contract Database 1 owns it.
Audit arm 19: The composition MUST alert on an owed record.
Audit arm 20: The composition MUST NOT read an invalid-request answer as a transient fault.
Audit arm 21: The composition MUST read an invalid-request answer as a deployment fault.
Audit arm 22: A recovery outcome MUST carry the recovery marker.
Audit arm 23: A recovery outcome MUST name the acting human in the outcome's data.
Audit arm 24: IF Audit Trail answers invalid-request carrying a step above step-2 at an intent THEN the action MUST answer recording-failure carrying intent.
Audit arm 25: The composition MUST NOT retry an invalid-request answer carrying a step above step-2.
```

Term landed intent: the invocation's intent the substrate has appended and attested and answered.

Term open marker: an intent carrying no outcome under the intent's own intent event id — an invocation that committed nothing, or committed and failed to record.

Term outcome traversal: the composition's read of the trail over an open-ended sequence range for an outcome carrying a named intent event id, taken before any compensating write.

Term recovery marker: recovery — the marker a recovery outcome carries so a reader tells a clean act from a recovered one.

Term recovery outcome: the outcome the reconciliation emits for a committed act whose own invocation did not record one.

### Action wiring

```
initiate_onboarding(optional party_id, optional enrollment_fields, actor_ref, credential, retention_policy_ref)
  answers case_id
  refuses invalid-request | invalid-credential | party-not-known | party-not-admissible(state) | already-onboarded | enrollment-failed(enrollment failure) | recording-failure(position)

record_verification(case_id, verifying_actor_ref, method, verification_result, evidence_ref, credential)
  answers recorded
  refuses invalid-request | invalid-credential | not-known | not-active | already-closed | recording-failure(position)

trigger_monitoring_review(case_id, trigger_type, trigger_ref, actor_ref, credential)
  answers recorded
  refuses invalid-request | invalid-credential | not-known | not-active | not-verified(state) | recording-failure(position)

clear_review(case_id, verifying_actor_ref, method, evidence_ref, actor_ref, credential, reason)
  answers cleared
  refuses invalid-request | invalid-credential | not-known | no-open-trigger | verification-failed | already-closed | recording-failure(position)

close_party(case_id, closing_actor_ref, reason, credential)
  answers closed
  refuses invalid-request | invalid-credential | not-known | not-active | recording-failure(position)

activity_permitted(party_id)
  answers permitted
  refuses not-known | not-verified(state) | state-unavailable
```

Term enrollment failure: invalid-request | storage-failure — Party Identity's enroll codes an initiation passes through.

Term position: intent | outcome — whether the invocation had committed a constituent write when it failed: intent where it had not, so the caller may retry the whole action; outcome where it had (Audit arm 11, Audit arm 12). A constituent's own refusal after the intent landed carries intent.

```
Action wiring 1: [Initiate Onboarding] MUST answer invalid-request for a call carrying a party id AND enrollment fields.
Action wiring 2: [Initiate Onboarding] MUST answer invalid-request for a call carrying no party id AND no enrollment fields.
Action wiring 3: [Initiate Onboarding] MUST answer invalid-request for an unset monitoring interval.
Action wiring 4: An external path call MUST read the party through Party Identity's declared read.
Action wiring 5: IF no party EXISTS for the party id THEN [Initiate Onboarding] MUST answer party-not-known.
Deleted: Action wiring 154. Execution Contract Read 1 owns it.
Action wiring 6: IF the party's state IS NOT IN the admissible states THEN [Initiate Onboarding] MUST answer party-not-admissible carrying the state.
Action wiring 7: IF an active case EXISTS for the party THEN [Initiate Onboarding] MUST answer already-onboarded.
Action wiring 8: An admitted initiation MUST record an initiation intent.
Action wiring 9: A direct path initiation MUST NOT carry a party id on the initiation intent.
Action wiring 10: A direct path initiation MUST call Party Identity's enroll with the enrollment fields.
Action wiring 11: IF Party Identity answers invalid-request for an enroll THEN [Initiate Onboarding] MUST answer enrollment-failed carrying invalid-request.
Action wiring 12: IF Party Identity answers storage-failure for an enroll THEN [Initiate Onboarding] MUST answer enrollment-failed carrying storage-failure.
Action wiring 13: An admitted initiation MUST call Retention Window's place_under_retention with the party id AND the retention policy reference.
Action wiring 14: An admitted initiation MUST NOT substitute the active relationship policy for the retention policy reference.
Action wiring 15: IF Retention Window answers invalid-policy for an initiation THEN [Initiate Onboarding] MUST answer invalid-request.
Action wiring 16: IF Retention Window answers policy-not-found for an initiation THEN [Initiate Onboarding] MUST answer invalid-request.
Action wiring 17: IF Retention Window answers storage-failure for an external path initiation THEN [Initiate Onboarding] MUST answer recording-failure carrying intent.
Deleted: Action wiring 18. Execution Contract Database 1 owns it.
Action wiring 19: An admitted initiation MUST record an initiated outcome carrying the case id, the party id, the enrollment path, the current placement, the opening instant AND the next review due.
Action wiring 20: An admitted initiation MUST answer the case id.
Action wiring 21: The composition MUST read the case-to-monitoring index at [Record Verification].
Action wiring 22: IF no case EXISTS for the case id THEN [Record Verification] MUST answer not-known.
Action wiring 23: IF the case's active flag EQUALS false THEN [Record Verification] MUST answer not-active.
Action wiring 24: An admitted verification MUST record a verification intent.
Action wiring 25: An admitted verification MUST call Party Identity's verify with the party id, the verifying actor reference, the method, the verification result AND the evidence reference.
Action wiring 26: IF Party Identity answers already-closed for a verify THEN [Record Verification] MUST answer already-closed.
Action wiring 27: IF Party Identity answers not-known for a verify THEN [Record Verification] MUST answer recording-failure carrying intent.
Action wiring 28: IF Party Identity answers storage-failure for a verify THEN [Record Verification] MUST answer recording-failure carrying intent.
Action wiring 29: An admitted verification MUST record a verification recorded outcome carrying the case id, the party id, the verification id, the state change id AND the verification result.
Action wiring 30: A transitioning verification MUST carry the next review due on the verification recorded outcome.
Action wiring 31: A verification carrying no state change id MUST NOT carry a next review due on the verification recorded outcome.
Action wiring 32: A transitioning verification MUST advance the next review due.
Action wiring 33: A verification carrying no state change id MUST NOT advance the next review due.
Action wiring 34: IF the verification recorded record fails THEN [Record Verification] MUST answer recording-failure carrying outcome.
Action wiring 35: An admitted verification MUST answer recorded.
Action wiring 36: A reader MUST NOT read recorded as a verified state.
Action wiring 37: The composition MUST read the case-to-monitoring index at [Trigger Monitoring Review].
Action wiring 38: IF no case EXISTS for the case id THEN [Trigger Monitoring Review] MUST answer not-known.
Action wiring 39: IF the case's active flag EQUALS false THEN [Trigger Monitoring Review] MUST answer not-active.
Action wiring 40: The composition MUST read the party through Party Identity's declared read at [Trigger Monitoring Review].
Deleted: Action wiring 41. Execution Contract Read 1 owns it.
Action wiring 42: IF Party Identity answers invalid-query THEN [Trigger Monitoring Review] MUST answer invalid-request.
Action wiring 43: The composition MUST read an invalid-query answer as the composition's own defect.
Action wiring 44: IF the trigger type belongs to the adverse trigger types AND the party's state IS NOT IN the suspendable states THEN [Trigger Monitoring Review] MUST answer not-verified carrying the state.
Action wiring 45: A periodic trigger MUST NOT refuse a party's state.
Action wiring 46: An admitted trigger MUST record a monitoring triggered outcome carrying the case id, the party id, the trigger id, the trigger type, the trigger ref AND the trigger instant.
Action wiring 47: An admitted periodic trigger against an unsuspended party MUST carry the next review due on the monitoring triggered record.
Action wiring 48: An admitted trigger against a suspended party MUST NOT carry a next review due on the monitoring triggered record.
Action wiring 49: An adverse trigger MUST NOT carry a next review due on the monitoring triggered record.
Action wiring 50: IF the monitoring triggered record fails THEN [Trigger Monitoring Review] MUST answer recording-failure carrying intent.
Action wiring 51: IF the monitoring triggered record fails THEN the invocation MUST NOT make a committing call.
Action wiring 52: An adverse trigger MUST call Party Identity's suspend with the party id, the actor reference AND the composed suspend reason.
Action wiring 53: IF Party Identity answers already-suspended for a suspend THEN the invocation MUST record a trigger on suspended party outcome.
Action wiring 54: IF Party Identity answers already-suspended for a suspend THEN the invocation MUST add the trigger to the open-trigger set.
Action wiring 55: IF Party Identity refuses a suspend outside already-suspended THEN the invocation MUST record a trigger voided outcome carrying the constituent's answer.
Action wiring 56: IF Party Identity refuses a suspend outside already-suspended THEN the invocation MUST NOT add the trigger to the open-trigger set.
Action wiring 57: IF Party Identity answers not-verifiable for a suspend THEN [Trigger Monitoring Review] MUST answer not-verified carrying unverified.
Action wiring 58: IF Party Identity answers already-closed for a suspend THEN [Trigger Monitoring Review] MUST answer not-verified carrying closed.
Action wiring 59: IF Party Identity answers not-known for a suspend THEN [Trigger Monitoring Review] MUST answer not-known.
Action wiring 60: IF Party Identity answers invalid-request for a suspend THEN [Trigger Monitoring Review] MUST answer invalid-request.
Action wiring 61: IF Party Identity answers storage-failure for a suspend THEN [Trigger Monitoring Review] MUST answer recording-failure carrying intent.
Action wiring 62: IF the trigger voided record fails THEN [Trigger Monitoring Review] MUST answer recording-failure carrying intent.
Action wiring 63: A suspending trigger MUST record a party suspended outcome carrying the case id, the party id, the trigger id, the trigger type, the trigger ref, the state change id AND the suspension instant.
Action wiring 64: A suspending trigger MUST add the trigger to the open-trigger set whatever the party suspended record's answer.
Action wiring 65: IF the party suspended record fails THEN [Trigger Monitoring Review] MUST answer recording-failure carrying outcome.
Action wiring 66: A periodic trigger MUST read the current placement's policy reference through Retention Window's declared read.
Action wiring 67: A periodic trigger MUST call Retention Window's place_under_retention with the party id AND the current placement's policy reference.
Action wiring 68: A periodic trigger MUST renew the placement whatever the party's state.
Action wiring 69: A periodic trigger MUST renew the placement whatever the current placement's remaining cover.
Action wiring 70: IF Retention Window answers storage-failure for a renewal THEN [Trigger Monitoring Review] MUST answer recording-failure carrying intent.
Action wiring 71: IF Retention Window answers invalid-policy for a renewal THEN [Trigger Monitoring Review] MUST answer invalid-request.
Action wiring 72: IF Retention Window answers policy-not-found for a renewal THEN [Trigger Monitoring Review] MUST answer invalid-request.
Action wiring 73: A renewing trigger MUST record a retention renewed outcome carrying the case id, the party id, the enrollment path, the trigger id, the prior placement, the renewed placement, the policy reference AND the renewal instant.
Action wiring 74: IF the retention renewed record fails THEN [Trigger Monitoring Review] MUST answer recording-failure carrying outcome.
Action wiring 75: A renewing trigger MUST repoint the case-to-retentions index ONLY AFTER the landed retention renewed record.
Action wiring 76: A periodic trigger against an unsuspended party MUST advance the next review due whatever the renewal's answer.
Action wiring 77: A periodic trigger against a suspended party MUST NOT advance the next review due.
Action wiring 78: The reconciliation MUST match a renewal recovery on the trigger id.
Action wiring 79: An admitted trigger MUST answer recorded.
```
```
Action wiring 80: The composition MUST read the case-to-monitoring index at [Clear Review].
Action wiring 81: IF no case EXISTS for the case id THEN [Clear Review] MUST answer not-known.
Action wiring 82: IF the open-trigger set stands empty THEN [Clear Review] MUST answer no-open-trigger.
Action wiring 83: An admitted clearance MUST record a clearance intent carrying the open-trigger set.
Action wiring 84: An admitted clearance MUST call Party Identity's verify with the party id, the verifying actor reference, the method, passed AND the evidence reference.
Action wiring 85: An admitted clearance MUST NOT call Party Identity's verify with failed.
Action wiring 86: IF Party Identity answers already-closed for a clearance verify THEN [Clear Review] MUST answer already-closed.
Action wiring 87: IF Party Identity answers not-known for a clearance verify THEN [Clear Review] MUST answer not-known.
Action wiring 88: IF Party Identity answers invalid-request for a clearance verify THEN [Clear Review] MUST answer invalid-request.
Action wiring 89: IF Party Identity answers storage-failure for a clearance verify THEN [Clear Review] MUST answer recording-failure carrying intent.
Action wiring 90: An admitted clearance MUST record a review cleared outcome carrying the case id, the party id, the verification id, the closed triggers, the reason AND the clearance instant.
Action wiring 91: A review cleared outcome MUST NOT carry a next review due.
Action wiring 92: IF the review cleared record fails THEN [Clear Review] MUST answer recording-failure carrying outcome.
Action wiring 93: IF the review cleared record fails THEN the invocation MUST NOT call Party Identity's reinstate.
Action wiring 94: An admitted clearance MUST call Party Identity's reinstate ONLY AFTER the landed review cleared record.
Action wiring 95: An admitted clearance MUST call Party Identity's reinstate with the party id, the actor reference AND the reason.
Action wiring 96: IF Party Identity answers no-passed-verification-since-suspend for a reinstate THEN [Clear Review] MUST answer verification-failed.
Action wiring 97: IF Party Identity answers not-suspended for a reinstate THEN [Clear Review] MUST answer verification-failed.
Action wiring 98: IF Party Identity answers already-closed for a reinstate THEN [Clear Review] MUST answer already-closed.
Action wiring 99: IF Party Identity answers not-known for a reinstate THEN [Clear Review] MUST answer not-known.
Action wiring 100: IF Party Identity answers invalid-request for a reinstate THEN [Clear Review] MUST answer invalid-request.
Deleted: Action wiring 101. Execution Contract Database 1 owns it.
Action wiring 102: An admitted clearance MUST record a party reinstated outcome carrying the case id, the party id, the state change id, the reinstatement instant AND the next review due.
Action wiring 103: IF the party reinstated record fails THEN [Clear Review] MUST answer recording-failure carrying outcome.
Action wiring 104: An admitted clearance MUST drop the closed triggers from the open-trigger set ONLY AFTER the landed party reinstated record.
Action wiring 105: An admitted clearance MUST drop exactly the closed triggers the review cleared record names.
Action wiring 106: An admitted clearance MUST NOT drop a trigger the review cleared record does not name.
Action wiring 107: An admitted clearance MUST advance the next review due to the party reinstated record's next review due.
Deleted: Action wiring 108. Execution Contract Database 1 owns it.
Deleted: Action wiring 109. Execution Contract Database 1 owns it.
Deleted: Action wiring 110. Execution Contract Database 1 and Execution Contract Database 3 own it.
Action wiring 111: An admitted clearance MUST answer cleared.
Action wiring 112: The composition MUST read the case-to-monitoring index at [Close Party].
Action wiring 113: IF no case EXISTS for the case id THEN [Close Party] MUST answer not-known.
Action wiring 114: IF the case's active flag EQUALS false THEN [Close Party] MUST answer not-active.
Action wiring 115: An admitted closure MUST record a closure intent.
Action wiring 116: An admitted closure MUST call Party Identity's close with the party id, the closing actor reference AND the reason.
Deleted: Action wiring 117. Reconciliation 8 and Execution Contract Database 1 own it.
Deleted: Action wiring 118. Execution Contract Database 1 owns it: a closure's close, floor and record commit together, so no invocation completes an earlier closure.
Action wiring 119: IF Party Identity answers already-closed for a close AND a party closed event names the case THEN [Close Party] MUST answer not-active.
Action wiring 120: IF Party Identity answers not-known for a close THEN [Close Party] MUST answer not-known.
Action wiring 121: IF Party Identity answers invalid-request for a close THEN [Close Party] MUST answer invalid-request.
Action wiring 122: IF Party Identity answers storage-failure for a close THEN [Close Party] MUST answer recording-failure carrying intent.
Action wiring 123: An admitted closure MUST call Retention Window's place_under_retention with the party id AND the post closure policy.
Action wiring 124: IF Retention Window answers invalid-policy for a closure THEN [Close Party] MUST answer invalid-request.
Action wiring 125: IF Retention Window answers policy-not-found for a closure THEN [Close Party] MUST answer invalid-request.
Deleted: Action wiring 126. Execution Contract Database 1 owns it.
Action wiring 127: An admitted closure MUST record a party closed outcome carrying the case id, the party id, the state change id, the post closure placement, the reason, the closure instant AND the open triggers at close.
Action wiring 128: IF the party closed record fails THEN [Close Party] MUST answer recording-failure carrying outcome.
Action wiring 129: An admitted closure MUST populate the case-to-retentions index's post closure placement ONLY AFTER the landed party closed record.
Action wiring 130: An admitted closure MUST write the case's active flag set to false ONLY AFTER the landed party closed record.
Action wiring 131: An admitted closure MUST empty the open-trigger set ONLY AFTER the landed party closed record.
Action wiring 132: An admitted closure MUST answer closed.
Deleted: Action wiring 133. Execution Contract Database 1 owns it.
Action wiring 134: The composition MUST read the party-to-case index at [Activity Permitted].
Action wiring 135: IF the party id IS NOT IN the party-to-case index THEN [Activity Permitted] MUST answer not-known.
Action wiring 136: The composition MUST read the party through Party Identity's declared read at [Activity Permitted].
Action wiring 137: IF the party's state EQUALS verified THEN [Activity Permitted] MUST answer permitted.
Action wiring 138: IF the party's state DOES NOT EQUAL verified THEN [Activity Permitted] MUST answer not-verified carrying the state.
Deleted: Action wiring 139. Execution Contract Read 1 owns it.
Action wiring 140: IF the read answers no party THEN [Activity Permitted] MUST answer state-unavailable.
Deleted: Action wiring 141. Execution Contract Read 1 and Execution Contract Read 2 own it.
Action wiring 142: [Activity Permitted] MUST NOT write.
Action wiring 143: [Activity Permitted] MUST NOT record an audit event.
Action wiring 144: [Activity Permitted] MUST NOT read a clock.
Action wiring 145: [Activity Permitted] MUST NOT compare a timestamp.
```

Term party state: [Party Identity](../atoms/party-identity.md)'s declared lifecycle states, cited rather than restated.

Term admissible states: unverified — the one party state an external path initiation admits.

Term suspendable states: verified | suspended — the party states an adverse trigger's suspend may reach.

Term admitted initiation: an [Initiate Onboarding] call whose boundary predicate passed, whose party stands admissible and whose intent landed.

Term admitted verification: a [Record Verification] call whose boundary predicate passed, whose case's active flag EQUALS true and whose intent landed.

Term admitted trigger: a [Trigger Monitoring Review] call whose boundary predicate passed, whose case's active flag EQUALS true and whose pre-check admitted the trigger type against the party's state.

Term admitted clearance: a [Clear Review] call whose boundary predicate passed, whose case carries an open trigger and whose intent landed.

Term admitted closure: a [Close Party] call whose boundary predicate passed, whose case's active flag EQUALS true and whose intent landed.

Term transitioning verification: an admitted verification Party Identity answered with a state change id.

Term adverse trigger: an admitted trigger whose trigger type belongs to the adverse trigger types.

Term periodic trigger: an admitted trigger whose trigger type EQUALS the periodic trigger type.

Term suspending trigger: an adverse trigger whose suspend Party Identity admitted.

Term renewing trigger: a periodic trigger whose renewal Retention Window admitted.

Term committing closure: an admitted closure Party Identity answered with a state change id.

Term composed suspend reason: `"monitoring-trigger:" + trigger_type + ":" + trigger_ref` — the reason an adverse trigger passes to Party Identity's suspend.

Term closed triggers: the trigger ids a review cleared record names as resolved by the clearance.

Term open triggers at close: the trigger ids a party closed record names as closed-unresolved at the relationship's end.

Term prior placement: the current placement a renewal supersedes.

Term renewed placement: the placement a renewal makes, which becomes the case's current placement once the renewal's record lands.

```
Action wiring 146: An initiated outcome MUST carry the injected now as opening instant.
Action wiring 147: A monitoring triggered outcome MUST carry the injected now as trigger instant.
Action wiring 148: A party suspended outcome MUST carry the injected now as suspension instant.
Action wiring 149: A retention renewed outcome MUST carry the injected now as renewal instant.
Action wiring 150: A review cleared outcome MUST carry the injected now as clearance instant.
Action wiring 151: A party reinstated outcome MUST carry the injected now as reinstatement instant.
Action wiring 152: A committing closure MUST carry the injected now as closure instant on the party closed outcome.
Action wiring 153: An invocation MUST derive the next review due from the injected now.
```

### Wiring decision

```
Wiring decision 1: The composition MUST hold the activity gate.
Wiring decision 2: [Activity Permitted] MUST answer permitted ONLY IF the composition's own case names the party.
Wiring decision 3: [Activity Permitted] MUST answer permitted ONLY IF Party Identity reports the party verified.
Wiring decision 4: The composition MUST NOT answer permitted from a party's state alone.
Wiring decision 5: An activity system MUST NOT hold a second gate.
Wiring decision 6: The composition MUST NOT push the gate into a constituent.
Wiring decision 7: Party Identity MUST NOT know a regulated activity.
Wiring decision 8: The composition MUST drive a verification transition through [Record Verification].
Wiring decision 9: The composition MUST drive a reinstatement through [Clear Review].
```

Term regulated activity: an account opening, a transaction, a service provisioning, or any other act the deployment's regulator conditions on completed Customer Due Diligence.

WHY:
*Principle.* BSA/AML and FATF Recommendations 10–12 require that Customer Due Diligence be completed before a business relationship's regulated activity begins. Structurally that means no account opening, no transaction and no service provisioning proceeds for a party outside a substantiated `Verified` state, and the system makes both provable: that the party was verified, and that no activity preceded the verification.

*Likely objection.* Party Identity already owns the `Verified` state and already refuses a reinstatement without a passed verification after the most recent suspend. Why not have each activity system read Party Identity's state directly? The atom already enforces the substance of the gate.

*Mechanism that resolves it.* Party Identity owns the state and exposes no gate: it records that a party is Verified, does not enforce that activity systems consult it, and does not know what regulated activity means — importing that notion would break the atom's freestanding status, which is what Wiring decision 6 and Wiring decision 7 refuse. The Audit Trail substrate records attributed, tamper-evident events and does not know which of them constitute a verification chain. Neither can, alone, deliver both halves of the obligation. The composition wires them: every `Unverified → Verified` transition flows through [Record Verification], which records an event carrying both the `verification_id` and the `state_change_id`, so the verification is attributed and tamper-evident (Invariant 2.1); and [Activity Permitted] is the *single* gate query, so the precondition is implemented exactly once at the composition boundary rather than re-implemented — or quietly skipped — in each activity system. Wiring decision 2 is the half a reader most often misses: the gate consults this composition's own case index as well as the party's state, so a party driven to `Verified` outside this composition has no case entry and fails the gate. The attribution half is delivered by Invariant 2.1 together with the exclusive-ownership obligation of Composes 19 and Composes 20, not by the state read; the gate's own job is to confine permitted to the `Verified` parties this composition governs.

*Result.* The gate is structural and centralized. It is provable to an auditor that for every party with regulated activity a verification record carrying a `state_change_id` precedes the activity (Check 1.1), and that no activity system held its own copy of the gate logic to drift from. The single-surface discipline is what makes it provable: the verification precondition lives in one place, is exercised through one query, and produces one tamper-evident event class the auditor reads.

### Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Reconciliation 2: The composition MUST run the reconciliation PER reconciliation cadence.
Reconciliation 3: The reconciliation MUST select an open marker over an open-ended sequence range.
Deleted: Reconciliation 4. Execution Contract Database 1 owns it.
Reconciliation 5: The reconciliation MUST NOT examine an aged-out event.
Reconciliation 6: The reconciliation MUST resolve an open marker against the constituents' declared reads.
Reconciliation 7: IF no committing call EXISTS for the open marker THEN the reconciliation MUST close the marker.
Reconciliation 8: IF a committing call EXISTS for the open marker THEN the reconciliation MUST emit the owed outcome.
Reconciliation 9: The reconciliation MUST emit a recovery outcome ONLY AFTER the landed recovery intent.
Reconciliation 10: The reconciliation MUST record a recovery intent ONLY AFTER the outcome traversal.
Reconciliation 11: The reconciliation MUST attest a recovery record under the service identity.
Deleted: Reconciliation 12. Execution Contract Database 1 owns it.
Deleted: Reconciliation 13. Execution Contract Database 1 owns it.
Reconciliation 14: The reconciliation MUST NOT enroll a party.
Reconciliation 15: The reconciliation MUST NOT verify a party.
Reconciliation 16: The reconciliation MUST NOT suspend a party.
Reconciliation 17: The reconciliation MUST NOT reinstate a party.
Reconciliation 18: The reconciliation MUST NOT close a party.
Reconciliation 19: The reconciliation MUST close an open marker WITHIN the compensation window.
Reconciliation 20: The reconciliation MUST escalate an open marker outside the compensation window.
Deleted: Reconciliation 21. Execution Contract Database 1 owns it.
Reconciliation 22: The reconciliation MUST alert on an active case carrying an elapsed placement.
Reconciliation 23: The reconciliation MUST alert on a suspended party carrying an empty open-trigger set.
Reconciliation 24: The reconciliation MUST alert on a landed trigger carrying no outcome.
Reconciliation 25: The reconciliation MUST alert on a verified party carrying no verification record.
Deleted: Reconciliation 26. Execution Contract Database 2 owns it.
Reconciliation 27: The reconciliation MUST resolve a verification intent's commitment on the party id, the verifying actor reference, the evidence reference AND the intent's intent instant.
Reconciliation 28: The reconciliation MUST resolve a placement intent's commitment on the party id, the policy reference AND the intent's intent instant.
Reconciliation 29: The reconciliation MUST NOT resolve an enrolment intent's commitment.
Reconciliation 30: The reconciliation MUST escalate an unresolved enrolment intent as a finding.
Reconciliation 31: The reconciliation MUST NOT match a recovery on a payload resemblance.
Reconciliation 32: The reconciliation MUST answer nothing to a caller.
Reconciliation 33: A caller MUST NOT invoke the reconciliation.
```

Term reconciliation: the leg the Reconciliation rules state — this composition's own, over its open markers.

Term elapsed placement: a placement whose retention deadline does not exceed the injected now.

---

## Composition-level invariants

```
Invariant 1.1: [Activity Permitted] MUST answer permitted ONLY IF the party-to-case index names the party AND Party Identity reports the party verified.
Invariant 1.2: [Activity Permitted] MUST answer permitted for a party the party-to-case index names AND Party Identity reports verified.
Invariant 1.3: A party MUST reach regulated activity ONLY IF [Activity Permitted] answers permitted.
Invariant 2.1: A transitioning verification MUST carry a landed verification recorded record naming the verification id AND the state change id.
Invariant 2.2: A verification recorded record MUST stand under a seal PER Audit Trail's seal cadence.
Invariant 2.3: A quiescent verified party MUST carry a verification recorded record.
Invariant 2.4: A verified party MAY carry an owed verification recorded record WITHIN the compensation window.
Invariant 3.1: A party suspended record MUST stand later in the log than the record's monitoring triggered record.
Invariant 3.2: A trigger on suspended party record MUST stand later in the log than the record's monitoring triggered record.
Invariant 3.3: A reader MUST read later in the log as the Event Log's insertion order.
Invariant 3.4: A reader MUST NOT read later in the log as a timestamp difference.
Invariant 4.1: A reinstated party MUST carry a passed verification standing later in the log than the party's most recent suspension.
Invariant 4.2: A reinstated party MUST carry a landed review cleared record naming the verification id.
Invariant 4.3: The clearing actor MUST attest the fresh evidence.
Invariant 4.4: The composition MUST NOT claim the verifying actor reference stands authenticated.
Invariant 5.1: An active case's party record MUST stand under an unelapsed placement.
Invariant 5.2: An active case's placements MUST stand as a continuous chain.
Invariant 5.3: A closed case's party record MUST stand under the post closure placement.
Invariant 5.4: A purging layer MUST destroy a party record ONLY IF EVERY placement over the record stands elapsed.
Invariant 5.5: The composition MUST NOT expose a purge surface.
Invariant 5.6: A purging layer MUST NOT destroy a closed case's party record BEFORE the post closure floor.
Invariant 6.1: A verified party under an active case MUST carry a case-to-monitoring entry.
Invariant 6.2: A case-to-monitoring entry MUST carry a next review due.
Invariant 7.1: A quiescent active case MUST carry a non-empty open-trigger set ONLY IF the state of the case's party EQUALS suspended.
Invariant 7.2: A quiescent suspended party under an active case MUST carry a non-empty open-trigger set.
Invariant 7.3: A verified party carrying a closed trigger inside the clearance window MUST stand as a surfaced orphan.
Invariant 7.4: A quiescent closed case MUST carry an empty open-trigger set.
Invariant 7.5: A party closed record MUST name EVERY trigger the closure swept.
Invariant 8.1: The composition MUST NOT commit a constituent write under an unvalidated credential.
Invariant 8.2: An action MUST validate EXACTLY ONE actor's credential.
Invariant 8.3: The composition MUST NOT claim a recorded actor reference stands authenticated.
Invariant 8.4: A credential validation MUST NOT establish the presenter's identity.
Invariant 8.5: A credential validation MUST NOT establish a channel binding.
Invariant 8.6: A credential validation MUST NOT establish an authorization.
Invariant 8.7: A credential validation MUST NOT establish the customer's evidence.
```

Term quiescent case: a case carrying no invocation in flight.

Term quiescent verified party: a party whose state EQUALS verified whose case carries no invocation in flight.

Term quiescent suspended party: a party whose state EQUALS suspended whose case carries no invocation in flight.

Term quiescent closed case: a closed case carrying no invocation in flight.

Term continuous chain: a sequence of placements over one party in which each link's retention instant does not exceed the predecessor's retention deadline.

Term post closure floor: the instant a closed case's post closure placement reaches the placement's retention deadline — the earliest lawful destruction of the party record on the post-closure side.

Term unelapsed placement: a placement whose retention deadline exceeds the injected now.

Term clearance window: the interval between a clearance's reinstate committing and the clearance's party reinstated record landing.

Term surfaced orphan: a state the composition has alerted on and the reconciliation owes a close.

Term clearing actor: the actor reference a [Clear Review] call carries — the one actor whose credential the composition validates on that call.

---

## Examples

### Walkthrough — retail bank customer onboarding under BSA/AML (direct path)

A bank onboards a retail customer with no prior system identity. Configuration: `active_relationship_policy_ref = bsa_active_cdd`, `post_closure_retention_policy_ref = bsa_5yr_post_closure`, `audit_trail_retention_policy = bsa_audit_9yr`, `monitoring_interval = P1Y`, `adverse_trigger_types = {sanctions-match, pep-status-change, adverse-media}`.

1. **Initiate.** `initiate_onboarding(party_id=absent, enrollment_fields={name:"Amara Osei", date_of_birth:"1981-03-14", document_type:"passport", document_ref:"doc_p901", enrolling_actor_ref:"officer_r3"}, actor_ref="officer_r3", credential=<officer_r3>, retention_policy_ref="bsa_active_cdd") → case_5501`. The intent record `customer-onboarding.initiation-intended` lands first, carrying `case_5501` and no party id; `PartyIdentity.enroll` returns `party_9017` in `Unverified`; `RetentionWindow.place_under_retention(party_9017, bsa_active_cdd)` returns `ret_active_9017`; `customer-onboarding.initiated` lands carrying intent event id, the schedule pair and the placement; the three indexes are populated after it.

2. **Gate before verification.** `activity_permitted(party_9017) → not-verified(Unverified)`. The account is not opened.

3. **Verification.** `record_verification(case_5501, verifying_actor_ref="system_verification_auto", method="automated-ocr", verification_result="passed", evidence_ref="evidence_ocr_442", credential=<system_verification_auto>) → recorded`. `customer-onboarding.verification-intended` lands, `PartyIdentity.verify` returns `{verif_1101, sc_4401}` — the `Unverified → Verified` transition — and `customer-onboarding.verification-recorded` lands carrying both ids and the advanced deadline.

4. **Gate after verification.** `activity_permitted(party_9017) → permitted`. `account_a883` is opened against `party_9017`.

5. **Periodic review.** A year later the external scheduler calls `trigger_monitoring_review(case_5501, trigger_type="periodic-review-due", trigger_ref="annual-review-2027", actor_ref="system_monitor", credential=<system_monitor>) → recorded`. `customer-onboarding.monitoring-triggered` lands and is this invocation's intent; no state transition; `RetentionWindow.place_under_retention(party_9017, bsa_active_cdd)` returns `ret_active_9017_2`; `customer-onboarding.retention-renewed` lands naming `ret_active_9017` as prior and re-carrying the case binding; the case-to-retentions index repoints after it; the deadline advances.

6. **Closure.** Ten years later, `close_party(case_5501, closing_actor_ref="officer_r3", reason="account-closed-customer-request", credential=<officer_r3>) → closed`. `customer-onboarding.closure-intended` lands; `PartyIdentity.close` returns `sc_9901`; `RetentionWindow.place_under_retention(party_9017, bsa_5yr_post_closure)` returns `ret_postclose_9017` — the five-year floor; `customer-onboarding.party-closed` lands carrying the floor and an empty open-triggers set; the indexes follow it.

7. **Gate after closure.** `activity_permitted(party_9017) → not-verified(Closed)`.

### External path — upstream enrollment

A broker-dealer admits a counterparty through External Onboarding, which enrolls the party `Unverified` and registers a credential. `initiate_onboarding(party_id="party_4421", enrollment_fields=absent, actor_ref="onboard_svc", credential=<onboard_svc>, retention_policy_ref="bsa_active_cdd") → case_6602`. The read confirms `party_4421` is known **and `Unverified`**, the intent lands carrying the party id, the placement is made, and `customer-onboarding.initiated` records `enrollment_path = external-onboarding`. A party the read showed `Verified`, `Suspended` or `Closed` answers `party-not-admissible(<state>)` and opens no case.

### Adverse trigger and clearance — sanctions match

An existing `Verified` party, `party_7732` (case `case_7700`), triggers a sanctions screening alert. The screening list is OFAC's SDN list (Office of Foreign Assets Control — the US Treasury office that administers sanctions — Specially Designated Nationals).

1. **Adverse trigger.** `trigger_monitoring_review(case_7700, trigger_type="sanctions-match", trigger_ref="ofac-sdn-12894", actor_ref="compliance_mgr_01", credential=<compliance_mgr_01>) → recorded`. The pre-check reads the party `Verified`; `customer-onboarding.monitoring-triggered` lands **first**; `PartyIdentity.suspend` returns `sc_7701`; `customer-onboarding.party-suspended` lands carrying it; the trigger enters the open set. Invariant 3 holds — the trigger record is ordered before the suspension record.

2. **Gate during investigation.** `activity_permitted(party_7732) → not-verified(Suspended)`.

3. **Clearance.** The match is a false positive. `clear_review(case_7700, verifying_actor_ref="compliance_analyst_02", method="database-check", evidence_ref="evidence_db_clearance_882", actor_ref="compliance_mgr_01", credential=<compliance_mgr_01>, reason="ofac-match-resolved-different-individual") → cleared`. `customer-onboarding.clearance-intended` lands carrying the open set; `PartyIdentity.verify(passed)` returns `verif_3901` with no `state_change_id` — a passed verification against a `Suspended` party records the event and changes no state; `customer-onboarding.review-cleared` lands carrying `verif_3901` and the `closed_triggers` set **and no deadline**; `PartyIdentity.reinstate` returns `sc_7702`; `customer-onboarding.party-reinstated` lands carrying `sc_7702` and the advanced deadline; the closed triggers are dropped and the deadline is taken from that payload.

4. **Gate after clearance.** `activity_permitted(party_7732) → permitted`.

### Rejection path — clearing a review with no open trigger

A compliance officer calls `clear_review(case_5501, …)` for a party with no open adverse trigger: the open set is empty → no-open-trigger. No intent is recorded, no verification, no reinstatement — and, because the guard sits before the intent, the officer's credential is never validated.

### Rejection path — periodic trigger against an unknown case

`trigger_monitoring_review("case_bogus", …) → not-known` at the index read. No audit event is recorded: the case is unknown, so there is no party to attribute a trigger to.

### Rejection path — a credential that does not validate

An operator whose credential was revoked calls `record_verification(case_5501, verifying_actor_ref="officer_r7", method="manual-review", verification_result="passed", evidence_ref="evidence_manual_77", credential=<stale_officer_r7>)`. The index read passes, the boundary predicate passes, and `customer-onboarding.verification-intended` refuses with invalid-credential → invalid-credential. **Nothing committed**: `PartyIdentity.verify` was never called, so a mis-credentialed actor could not drive the transition and be discovered over it afterwards. This is the seam Invariant 8 exists for, and it is the path that makes invalid-credential a declared code on every state-changing signature rather than a theoretical arm.

### Failure path — the intent appended and the call still failed

`close_party(case_5501, …)` reaches its closure intent, and `AuditTrail.record_action` answers `invalid-request(step-4)`: the audit instance's Retention Window answered policy-not-found at the substrate's **retention** step, after the event was appended and attested — so the credential *was* validated — and the substrate keeps both as the refusal's evidence (Audit Trail record action step 7.11). The invocation **aborts with nothing committed**: `PartyIdentity.close` is not called, the intent is not re-recorded (a blind re-record would double-append), and the appended `customer-onboarding.closure-intended` stands as an open marker. The reconciliation finds the marker, re-queries Party Identity, sees no closure, and closes the marker — nothing to compensate. The caller receives `recording-failure(intent)` and may retry the whole action once the deployment repairs the audit instance's policy.

### Failure path — an unmatched intent

A [Record Verification] invocation records its intent and calls `PartyIdentity.verify`, which commits `verif_2210`; its outcome record's Event Log append then answers nothing, the reply lost, so Audit Trail answers `recording-failure(step-3)` and the action answers `recording-failure(outcome)`: the verification stands committed and its record is owed. The trail holds `customer-onboarding.verification-intended` with no outcome carrying its intent event id. The reconciliation traverses for an outcome carrying that intent event id — had the lost append landed after all, the traversal would find it and nothing would be written — finds none, re-queries Party Identity on party id + verifying actor reference + evidence reference + the intent's intent instant, finds `verif_2210`, records `customer-onboarding.recovery-intended` under the service identity, and emits `customer-onboarding.verification-recorded` carrying `recovery = true` with `officer_r3` named in the payload. An auditor reading the trail sees a recovered verification rather than a clean one — and Check 6.1 compares against the human in the payload rather than the attesting service actor, which is why a recovered action does not read as an authentication failure.

### Failure path — verification committed, outcome record fails

A [Record Verification] call drives the `Unverified → Verified` transition and its outcome record fails: `recording-failure(outcome)` — the position telling the caller the verification is committed and the action must not be re-run. The party *is* `Verified`, so the gate answers permitted while Invariant 2.3's coverage is temporarily broken; Invariant 2.4 is the window, bounded by the compensation window. The composition alerts on the owed record, and the reconciliation emits it. Deployments under BSA/AML exposure treat the open window as a hard alerting condition.

### Regulated adversarial scenarios

**Regulator audit — show me that every active customer was verified before regulated activity.** A FATF/BSA examiner queries the trail and the activity records. For every party with an activity record, the examiner confirms a `customer-onboarding.verification-recorded` event carrying a non-absent `state_change_id` exists, that `AuditTrail.verify_record` answers verified for it, and that it precedes the first activity record. The two halves of Invariant 1 answer two different questions and the examiner asks both: Invariant 1.1 and Invariant 1.2 are the composition's own biconditional — the gate answered permitted for exactly the parties this composition initiated and Party Identity reports `Verified` — while Invariant 1.3, that no activity path other than the gate exists, is the deployment's obligation and is cleared by the deployment's own evidence that its activity systems consume [Activity Permitted] (External check 7). Flattening the two loses the distinction between what the records prove and what the deployment must attest. Invariant 2 is the guarantee that the verifying transition is in the records, attributed and tamper-evident. A party with an activity record and no predating, verified verification record carrying a `state_change_id` is a conformance failure.

**Disputed onboarding — the party claims they were never properly verified.** Counsel challenges the bank's claim that the identity was verified before the account opened. The investigator retrieves the case's `customer-onboarding.verification-recorded` events; each carries `verification_id`, `result` and, for the transition, `state_change_id`. The Party Identity verification record for each `verification_id` names verifying actor reference, method, evidence reference and `verified_at`. Party Identity's immutability and append-only invariants establish that no verification event was altered or back-inserted; the substrate's seal establishes that the composition's own record was not altered. The evidence reference points to the document record that supported the verification. Invariant 2 with Party Identity's own invariants is the rebuttal.

**Breach or incident forensics — which parties were Verified during the compromise window, and were any verifications altered.** Given a window, the investigator replays each case's `customer-onboarding.initiated`, `customer-onboarding.verification-recorded`, `customer-onboarding.monitoring-triggered`, `customer-onboarding.party-suspended`, `customer-onboarding.trigger-on-suspended-party`, `customer-onboarding.trigger-voided`, `customer-onboarding.review-cleared`, `customer-onboarding.party-reinstated` and `customer-onboarding.party-closed` events in Event Log insertion order to determine each party's state at the window's bounds — the intake and closure classes included, without which the replay cannot place a case's start or reconstruct a closure at all — then runs `AuditTrail.verify_record` against representative events in each seal's coverage to bound any tampering window. Invariant 3 is load-bearing here: every suspension in the window has a precipitating trigger ordered ahead of it, and a suspension with no precipitating trigger — or a trigger inserted *after* its suspension — is itself a finding, which the append-only sealed log forecloses an attacker doing silently. Invariant 6 lets the investigator confirm that every `Verified`, active party in the window had an open monitoring entry. Where the window has legal force as wall-time rather than event-index bounds, a Trusted Timestamping composition supplies the anchor; absent it the reconstruction is event-index-authoritative. The newest events — the substrate's unsealed tail — carry per-event immutability and become seal-verifiable only after the next seal cadence, so the integrity bound on the most recent events is the substrate's configured unsealed-tail policy.

---

## Generation acceptance

A derived implementation is *acceptable* — in the regulator-acceptance sense — when every check below is provable to an external auditor given the composition's indexes plus the Party Identity, Retention Window and Audit Trail records. Every selection is made composition-side over the declared open-ended sequence range, never by asking the substrate for a payload predicate it does not serve.

### Conformance checks

```
Check 1.1: An auditor MUST find a verification recorded record carrying a state change id PER party carrying a regulated activity record (Invariant 1.3).
Check 1.2: An auditor MUST confirm Audit Trail's verify_record answers verified for the found verification recorded record (Invariant 2.2).
Check 1.3: An auditor MUST confirm the found verification recorded record stands earlier in the log than the party's first activity record (Invariant 1.3).
Check 1.4: An auditor MUST read Check 1.3 as a wall-time comparison ONLY IF the deployment composes Trusted Timestamping (Clock semantics 8).
Check 1.5: An auditor MUST read Check 1.3 against activity records carrying no log anchor as best-effort (Clock semantics 8).
Check 1.6: An auditor MUST confirm the party-to-case index names EVERY party the gate answered permitted for (Invariant 1.1).
Check 2.1: An auditor MUST find a verification recorded record naming the verification id AND the state change id PER transitioning verification in Party Identity's records (Invariant 2.1).
Check 2.2: An auditor MUST find a verification recorded record PER quiescent verified party (Invariant 2.3).
Check 2.3: An auditor MUST read a verified party carrying an owed verification recorded record inside the compensation window as a surfaced orphan (Invariant 2.4).
Check 3.1: An auditor MUST find a monitoring triggered record carrying the same trigger id earlier in the log PER party suspended record (Invariant 3.1).
Check 3.2: An auditor MUST find a monitoring triggered record carrying the same trigger id earlier in the log PER trigger on suspended party record (Invariant 3.2).
Check 4.1: An auditor MUST find a review cleared record naming a verification id earlier in the log PER party reinstated record (Invariant 4.2).
Check 4.2: An auditor MUST confirm the named verification stands passed in Party Identity's records (Invariant 4.1).
Check 4.3: An auditor MUST confirm the named verification stands later in the log than the party's most recent suspension (Invariant 4.1).
Check 4.4: An auditor MUST confirm the review cleared record's attested actor reference matches the party reinstated record's attested actor reference (Invariant 4.3).
Check 5.1: An auditor MUST find a post closure placement whose retention state EQUALS retained PER closed party outside lawful destruction (Invariant 5.3).
Check 5.2: An auditor MUST read a closed party's record destroyed inside the post closure floor as a conformance failure (Invariant 5.6).
Check 5.3: An auditor MUST find a current placement standing unelapsed PER quiescent active case (Invariant 5.1).
Check 5.4: An auditor MUST reproduce the chain of placements from the initiated payload AND the retention renewed payloads in Event Log order (Composition state 29).
Check 5.5: An auditor MUST confirm the reproduced chain stands as a continuous chain (Invariant 5.2).
Check 5.6: An auditor MUST read a party record destroyed under an unelapsed placement as a conformance failure (Invariant 5.4).
Check 6.1: An auditor MUST find a case-to-monitoring entry PER verified party under an active case (Invariant 6.1).
Check 6.2: An auditor MUST reproduce the next review due as the latest schedule-bearing payload PER case (Composition state 28).
Check 6.3: An auditor MUST read a reproduced next review due disagreeing with the index as a rebuild trigger (Composition state 9).
Check 6.4: An auditor MUST read a case carrying no schedule-bearing payload as a conformance failure (Invariant 6.2).
Check 7.1: An auditor MUST reproduce the open-trigger set PER active case (Composition state 31).
Check 7.2: An auditor MUST confirm the party's state EQUALS suspended PER active case carrying a non-empty reproduced set (Invariant 7.1).
Check 7.3: An auditor MUST confirm the reproduced set stands non-empty PER suspended party under an active case (Invariant 7.2).
Check 7.4: An auditor MUST find a trigger outcome PER adverse monitoring triggered record (Invariant 7.1).
Check 7.5: An auditor MUST confirm a party closed record's open triggers at close names EVERY trigger the reproduced set carried at the closure (Invariant 7.5).
Check 7.6: An auditor MUST read a verified party carrying a reproduced open trigger whose clearance stands recorded as a surfaced orphan (Invariant 7.3).
Check 8.1: An auditor MUST find an intent carrying the outcome's intent event id earlier in the log PER state-changing outcome (Invariant 8.1).
Check 8.2: An auditor MUST confirm the found intent and the outcome name one case id (Identity 9).
Check 8.3: An auditor MUST compare a recovery outcome against the human the outcome's data names (Audit arm 23).
Check 8.4: An auditor MUST NOT compare a recovery outcome against the outcome's attesting actor reference (Audit arm 23).
Check 8.5: An auditor MUST NOT read an intent carrying no outcome as a conformance failure (Reconciliation 7).
Check 8.6: An auditor MUST resolve an intent carrying no outcome against the constituents' declared reads (Reconciliation 6).
Check 9.1: An auditor MUST clear Party Identity's conformance checks over the Party Identity records (Composes 5).
Check 9.2: An auditor MUST clear Retention Window's conformance checks over the party retention instance (Composes 5).
Check 9.3: An auditor MUST clear Audit Trail's conformance checks over the audit instance (Composes 5).
Check 9.4: An auditor MUST recognize an aged-out event PER event through Audit Trail's read_record (Composition state 19).
Check 9.5: An auditor MUST NOT read an aged-out event's payload (Composition state 18).
```

### External checks

```
External check 1: The deployment MUST establish the verification method's adequacy for the party's risk tier (Non-goal 3).
External check 2: The deployment MUST establish the screening list's currency at the screening's instant (Non-goal 1).
External check 3: The deployment MUST establish the verifying actor reference's identity (Invariant 8.3).
External check 4: The deployment MUST establish the enrolling actor reference's identity (Invariant 8.3).
External check 5: The deployment MUST establish an actor's authorization to record a verification (Invariant 8.6).
External check 6: The deployment MUST establish the lawful basis of a non-obligatory downstream processing (Non-goal 11).
External check 7: The deployment MUST establish that every activity system consumes [Activity Permitted] (Invariant 1.3).
External check 8: The deployment MUST establish that no second writer drives a verification transition on the Party Identity instance (Composes 20).
External check 9: The deployment MUST establish that the active relationship policy's duration exceeds the renewal floor (Capability requirement 20).
External check 10: The deployment MUST establish that the post closure policy's duration meets the post closure minimum (Capability requirement 17).
External check 11: The deployment MUST establish the scheduler's lateness against the scheduler tolerance (Capability requirement 19).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT run a verification workflow.
Non-goal 2: The composition MUST NOT judge an identity document.
Non-goal 3: The composition MUST NOT decide a risk tier.
Non-goal 4: The composition MUST NOT decide a verification method.
Non-goal 5: The composition MUST NOT decide a re-verification cadence PER party.
Non-goal 6: The composition MUST NOT schedule a review.
Non-goal 7: The composition MUST NOT model a pending verification.
Non-goal 8: The composition MUST NOT model an ownership graph.
Non-goal 9: The composition MUST NOT deduplicate a retried job.
Non-goal 10: The composition MUST NOT unwind an open commitment for a closed party.
Non-goal 11: The composition MUST NOT adjudicate a lawful basis.
Non-goal 12: The composition MUST NOT adjudicate an erasure request.
Non-goal 13: The composition MUST NOT purge a party record.
Non-goal 14: The composition MUST NOT purge an audit event.
Non-goal 15: The composition MUST NOT reconcile two retention policies.
Non-goal 16: The composition MUST NOT gate an authorization.
Non-goal 17: The composition MUST NOT own a recurring-review deadline as an atom.
Non-goal 18: The composition MUST NOT anchor a timestamp to wall time.
Non-goal 19: The composition MUST NOT index the audit log by a payload field.
Non-goal 20: The composition MUST NOT admit a second Party Identity writer.
Non-goal 21: The composition MUST NOT detect a dishonest clock reading.
```

NOTE: the owners — a Risk Tiering / EDD composing pattern *(forthcoming)* (Non-goal 3 through 5); [Duplicate Prevention](../atoms/duplicate-prevention.md), wired by a deployment in front of [Record Verification] or [Trigger Monitoring Review] (Non-goal 9); the composing system (Non-goal 10); a composing [Permissions](../atoms/permissions.md) layer (Non-goal 16, External check 5); a Review Schedule atom *(forthcoming)* (Non-goal 17); a Reverse Index *(forthcoming)* a deployment composes over the trail (Non-goal 19, Composes 14).

---

## Edge cases

### Atomic writes

```
Atomic writes 1: An invocation MUST record an outcome ONLY AFTER the invocation's committing call.
Atomic writes 2: An invocation MUST populate an index ONLY AFTER the invocation's landed outcome.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 5. Execution Contract Database 1 owns it.
Deleted: Atomic writes 6. Execution Contract Database 1 owns it.
Deleted: Atomic writes 7. Execution Contract Database 1 owns it.
Deleted: Atomic writes 8. Execution Contract Database 1 owns it.
Deleted: Atomic writes 9. Execution Contract Database 1 owns it.
Atomic writes 10: The composition MUST NOT reverse a committed constituent write.
Atomic writes 11: The composition MUST surface an orphan.
Atomic writes 12: A deployment MUST treat an orphan as an alerting condition.
```

Term trigger outcome: a party suspended record, a trigger on suspended party record, OR a trigger voided record — the three an adverse trigger's own record may be followed by.

Term orphan: a committed constituent write carrying an owed record, or a committed act carrying an index the composition has not populated.

### Clock semantics

```
Clock semantics 4: The next review due MUST NOT EXCEED the placement's cover.
Deleted: Clock semantics 2. Action wiring 146 through 152 own it, one outcome at a time.
Deleted: Clock semantics 1. Capability requirement 1 owns it.
Deleted: Clock semantics 3. Action wiring 153 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 6. Execution Contract Logic confinement 3 owns it.
Clock semantics 7: A reader MUST read insertion order as authoritative.
Clock semantics 8: A reader MUST read a timestamp as advisory.
Clock semantics 9: A reader MUST read a divergence between a trigger's trigger instant and the trigger's suspension instant as a conformance failure.
Deleted: Clock semantics 10. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 11. Non-goal 21 owns it.
```

Term placement's cover: `(the current placement's retention_until - scheduler_tolerance)` — the instant past which a review would fire too late to renew the placement before the placement lapses.

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Concurrency 2: A deployment MUST NOT serialize [Activity Permitted].
Concurrency 3: [Activity Permitted]'s two reads MUST NOT stand atomic.
Concurrency 4: A skewed gate read MUST NOT answer permitted.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Concurrency 6: The composition MUST read a state rejection the trigger pre-check forecloses as a serialization breach.
Deleted: Concurrency 7. Execution Contract Database 2 owns it.
Deleted: Concurrency 8. Execution Contract Database 2 owns it.
```

---

## Composition notes

These are adjacent compositions, **not** constituents of Customer Onboarding:

- **[External Onboarding](./external-onboarding.md)** — the upstream admission gate. External Onboarding admits a party in `Unverified` state (enroll, credential registration and invitation acceptance, all audited); Customer Onboarding is the verification gate downstream. A deployment requiring `Verified` status before granting access places this composition downstream of it: External Onboarding's party id flows into [Initiate Onboarding] on the external path, and the `Unverified` state the admission leaves the party in is exactly the state Action wiring 6 admits.
- **[Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md)** — governs non-obligatory processing beyond the Customer Due Diligence legal obligation. This composition's processing basis is GDPR Article 6(1)(c); that composition governs the Article 6(1)(a) consent basis for downstream processing this composition does not touch.
- **[Defensible Retention](./defensible-retention.md)** — the purge-side peer. Invariant 5.4's joint-enforcement obligation is discharged structurally by a deployment that purges party records through that composition's cross-retention gate; a host purging directly against the Retention Window instance owes the same joint check itself.
- **[Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md)** — handles data-subject access and erasure requests against party records, adjudicating the tension between an erasure request and the post-closure floor. This composition records the retention state at request time; that pattern adjudicates.
- **Ownership Structure / Beneficial Owner** *(forthcoming)* — models the ownership graph across Party Identity records. Each beneficial owner is verified through an onboarding case of their own; this composition is a constituent of that pattern, not its replacement.

---

## Terms

The canonical concepts this spec refers to. Each `[Term]` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind**, the Type it is a **Member of** or **Field of**, the Operation it is a **Parameter of**, its **Role** where the domain assigns one, and one **Projection** line — the concept's single canonical lowering token. Everything else about casing is derived from that token by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs), never hand-written. The emergent indexes (case_to_monitoring, party_to_case, case_to_retentions, case_to_open_triggers), the `customer-onboarding.*` event classes, the deployment trigger vocabulary, the constituent calls and their outcomes, the relayed constituent tokens and the deployment knobs stay backticked as wire values; the party lifecycle states are [Party Identity](../atoms/party-identity.md)'s and are not carded here.

### Vocabulary

Term actors: the composition; a deployment; the host; the seam; the transition; the reconciliation; a caller; an auditor; an activity system; an implementation; a reader; a writer; an invocation; an action; an intent; an outcome; an open marker; a recovery intent; a recovery outcome; the gate; a rebuild; an index; the case-to-monitoring index; the party-to-case index; the case-to-retentions index; the case-to-open-triggers index; an index entry; an unrebuildable entry; a case; a quiescent case; a quiescent closed case; an active case; a closed case; a party; a quiescent verified party; a quiescent suspended party; a reinstated party; a verified party; a suspended party; a case's party; a party state; an admissible state; a suspendable state; a trigger; an adverse trigger; a periodic trigger; a suspending trigger; a renewing trigger; an open trigger; a closed trigger; a trigger set; a verification; a transitioning verification; a clearance; an admitted initiation; an admitted verification; an admitted trigger; an admitted clearance; an admitted closure; a direct path initiation; an external path call; a placement; a current placement; a prior placement; a renewed placement; a post closure placement; an elapsed placement; an unelapsed placement; a continuous chain; a renewal; a purging layer; a committing call; a landed record; a landed intent; an owed record; an aged-out event; an audit event; an orphan; a surfaced orphan; a boundary predicate; an opaque input; an actor reference; the clearing actor; a credential; a credential validation; a field cap; the trigger set cap; the binding floor; the closure floor; the renewal floor; the audit horizon; the monitoring interval; the scheduler tolerance; a policy; the active relationship policy; the post closure policy; the post closure minimum; the adverse trigger types; the periodic trigger type; a regulated activity; a review scheduler; Party Identity; Retention Window; Audit Trail; Event Log; the party retention instance; the audit instance; the service identity; a truncation marker; a set digest; a payload field; a timestamp; insertion order; a clock reading; a skewed gate read; a state rejection; a divergence.

Term record verbs: serve, change, inherit, read, hold, reach, call, select, query, attest, own, place, admit, drive, know, push, store, classify, carry, stand, claim, populate, name, alert, drop, take, rebuild, recognize, supply, mint, generate, accept, configure, set, provision, rotate, disclose, start, run, fire, serialize, resolve, reconcile, refuse, normalize, fold, trim, compare, judge, propagate, cap, truncate, allocate, reuse, pair, make, retry, leave, record, answer, substitute, add, clear, empty, write, advance, repoint, renew, find, confirm, reproduce, establish, match, escalate, close, emit, examine, expose, validate, commit, detect, inject, stamp, derive, deduplicate, model, schedule, adjudicate, purge, unwind, gate, index, anchor, surface, treat, sweep, spend, enroll, verify, suspend, reinstate, belong, elapse, substantiate, invoke, duplicate, block, govern, identify, decide, reverse, destroy.

Term records: empty.

Term bounds: onboarding completion bound (onboarding_completion_bound), compensation window, audit horizon (audit_trail_retention_policy), monitoring interval (monitoring_interval), scheduler tolerance (scheduler_tolerance), renewal floor, binding floor, closure floor, field cap, trigger set cap (trigger_set_cap), `placement's cover`, post closure minimum, audit write latency.

Term cadences: reconciliation cadence, seal cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.41 (2026-09-14).

Term value sets: admissible states = unverified. suspendable states = verified | suspended. verification results = passed | failed. trigger vocabulary = periodic-review-due | a member of the adverse trigger types. adverse trigger types = sanctions-match | pep-status-change | adverse-media, extended by the deployment. intent = customer-onboarding.initiation-intended | customer-onboarding.verification-intended | customer-onboarding.clearance-intended | customer-onboarding.closure-intended | customer-onboarding.monitoring-triggered | customer-onboarding.recovery-intended. outcome = customer-onboarding.initiated | customer-onboarding.verification-recorded | customer-onboarding.party-suspended | customer-onboarding.trigger-on-suspended-party | customer-onboarding.trigger-voided | customer-onboarding.retention-renewed | customer-onboarding.review-cleared | customer-onboarding.party-reinstated | customer-onboarding.party-closed. enrollment path = direct | external-onboarding.

Term terms: composition, constituents, party retention instance, service identity, direct path, external path, case-to-monitoring index, party-to-case index, case-to-retentions index, case-to-open-triggers index, index, current placement, post closure placement, audit horizon, aged-out event, rebuild, miss, unrebuildable entry, binding-bearing payload, schedule-bearing payload, placement-bearing payload, landed record, owed record, seam, transition, monitoring interval, scheduler tolerance, renewal floor, binding floor, closure floor, onboarding completion bound, active relationship policy, post closure policy, post closure minimum, adverse trigger types, periodic trigger type, trigger set cap, field cap, blank, boundary predicate, opaque input, actor reference, trigger vocabulary, verification results, truncation marker, set digest, intent, outcome, committing call, landed intent, open marker, outcome traversal, recovery marker, recovery outcome, party state, admissible states, suspendable states, admitted initiation, admitted verification, admitted trigger, admitted clearance, admitted closure, transitioning verification, adverse trigger, periodic trigger, suspending trigger, renewing trigger, committing closure, composed suspend reason, closed triggers, open triggers at close, prior placement, renewed placement, regulated activity, reconciliation, elapsed placement, quiescent case, quiescent verified party, quiescent suspended party, quiescent closed case, continuous chain, unelapsed placement, post closure floor, clearance window, surfaced orphan, clearing actor, `placement's cover`, trigger outcome, orphan, enrollment failure, position, intent instant, intent event id, opening instant, trigger instant, suspension instant, renewal instant, clearance instant, reinstatement instant, closure instant, active flag, active case.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the derived-index classification and its obligations. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Structural-relation invariant templates in `spec-format.md` — referential integrity. read_record, verify_record, purge_event, action reference, event id: Audit Trail.

Term composing patterns: Risk Tiering / EDD *(forthcoming)*; Ownership Structure / Beneficial Owner *(forthcoming)*; Review Schedule *(forthcoming)*; Reverse Index *(forthcoming)*; Trusted Timestamping *(forthcoming)*; Policy Reconciliation *(forthcoming)*; [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md); [External Onboarding](./external-onboarding.md); [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md); [Defensible Retention](./defensible-retention.md); [Duplicate Prevention](../atoms/duplicate-prevention.md); [Permissions](../atoms/permissions.md).

Term trigger type: trigger_type — which kind of adverse trigger a record carries.

Term enrollment path: enrollment_path — the path a case was enrolled by.

#### Initiate Onboarding

The composition's intake action: open a Customer Due Diligence case for a party — enrolling the party on the direct path, or admitting one External Onboarding already enrolled in `Unverified` state on the external path, with enrollment path recording which — placing the first active-relationship retention, opening the monitoring schedule, and recording the case. Answers the case id; refuses [Already Onboarded] for a party that already has an active case (Action wiring 7) and [Enrollment Failed] for a direct path enroll Party Identity refuses (Action wiring 11, Action wiring 12).

Kind: Operation

#### Record Verification

The action that records a verification result against a case's party, driving the `Unverified → Verified` transition on a passed first verification, and recording the verification and state-change identifiers — the attribution-and-tamper-evidence half of verification-gates-activity (Invariant 2). Advances [Next Review Due] on a state-changing pass and on nothing else. A case whose active flag is false is refused [Not Active] here and at [Trigger Monitoring Review] and [Close Party] (Action wiring 23, Action wiring 39, Action wiring 114).

Kind: Operation

#### Trigger Monitoring Review

The audit-first entry point an external monitoring or screening system calls: it records the trigger *before* any resulting transition (Invariant 3), then — for an adverse trigger — suspends the party, or — for a periodic one — renews the active-relationship retention and advances [Next Review Due] unless the party stands suspended. No suspension exists in the records without its precipitating trigger ordered ahead of it. An adverse trigger against a party already suspended records [Trigger On Suspended Party], and one whose suspend Party Identity refuses otherwise records [Trigger Voided] (Action wiring 53, Action wiring 55).

Kind: Operation

#### Clear Review

The single emergent action that clears an adverse-trigger investigation and returns the party to Verified — wrapping a fresh passed verification, a `reinstate`, and two audit records into one act. Requires an open trigger ([No Open Trigger] otherwise), answers [Verification Failed] where Party Identity refuses the reinstate as not-suspended or for no passed verification since the suspend (Action wiring 96, Action wiring 97), and closes exactly the triggers its clearance record names.

Kind: Operation

#### Close Party

The action that ends the relationship and places the *post-closure* retention — the placement that sets the BSA/AML five-year-after-relationship-end floor — then records the closure with the disposition of any investigation still open at closure.

Kind: Operation

#### Activity Permitted

The read-only verification-gates-activity query every activity system consumes rather than reading Party Identity directly: answers permitted only for a party this composition itself initiated and Party Identity reports Verified, else [Not Verified] naming the actual state, [Party Not Known], or [State Unavailable]. Produces no audit event — it changes no state.

Kind: Operation

#### Next Review Due

The monitoring-schedule datum in each case's entry: the instant by which the party's next periodic review is due, advanced on a state-changing verification pass, a periodic review against an unsuspended party, or a review clearance — stamped on the reinstatement record, once the reinstate has committed — and capped below the current placement's cover so the review that renews the placement always fires before the placement lapses. It deliberately does not roll forward while a party is Suspended. A Verified party with no monitoring entry is a structural finding (Invariant 6.1).

Kind:       Field
Field of:   the monitoring-schedule entry
Role:       the next-periodic-review deadline
Projection: next_review_due

#### Not Verified

The load-bearing [Activity Permitted] refusal, parameterized by the party's actual state (`Unverified`, `Suspended` or `Closed`), so an activity system distinguishes *not yet verified* from *under investigation* from *relationship ended* and knows whether to retry, wait or stop. [Trigger Monitoring Review] answers it too, on the adverse pre-check and on the defence-in-depth arm behind it; the gate is the ordinary producer.

Kind:       Member
Member of:  the gate rejection
Role:       Rejection
Projection: not-verified

#### State Unavailable

The [Activity Permitted] fail-closed refusal when the party's state read cannot be answered — an unanswered read at the seam, or a case entry whose party the database no longer answers for. The gate refuses rather than treating an unreadable identity records as `Verified`, because the cheapest-compliant reading — unavailable implies permit — is exactly the before-activity hole the gate exists to close. [Trigger Monitoring Review]'s pre-check mirrors it.

Kind:       Member
Member of:  the gate rejection
Role:       Rejection
Projection: state-unavailable

#### No Open Trigger

The [Clear Review] refusal when the case carries no open adverse trigger — there is nothing to clear. Its faithfulness as a *nothing to clear* signal is Invariant 7.

Kind:       Member
Member of:  the clear-review rejection
Role:       Rejection
Projection: no-open-trigger

#### Enrollment Failed

The [Initiate Onboarding] refusal wrapping a Party Identity `enroll` failure on the direct path, surfaced under a composition-layer name rather than flattened into a recording failure precisely because it occurs before any case or placement exists — there is no orphan to recover.

Kind:       Member
Member of:  the initiate rejection
Role:       Rejection
Projection: enrollment-failed

#### Party Not Known

The [Initiate Onboarding] refusal on the external path when the supplied party id names no party the Party Identity instance holds.

Kind:       Member
Member of:  the initiate rejection
Role:       Rejection
Projection: party-not-known

#### Party Not Admissible

The [Initiate Onboarding] refusal on the external path when the named party stands outside `Unverified` — parameterized by the state found. A `Verified` admit would pass the gate with no verification record of this composition's, a `Suspended` admit would open a case with an empty open-trigger set against a suspended party, and a `Closed` party can never reach `Verified` at all, Party Identity's Closed being absorbing. A returning customer whose party record is Closed re-onboards by **fresh enrollment on the direct path, receiving a new party id**; the prior party record and its case history remain as governed records.

Kind:       Member
Member of:  the initiate rejection
Role:       Rejection
Projection: party-not-admissible

#### Already Onboarded

The [Initiate Onboarding] refusal when the named party already has an active case — the one-active-case-per-party relation. Re-onboarding an actively governed party would repoint the case index and orphan the live case's monitoring and retention entries. A party whose prior case closed is a `Closed` party and is refused as [Party Not Admissible]; the route back is fresh enrollment under a new party id, never a second case over the old record.

Kind:       Member
Member of:  the initiate rejection
Role:       Rejection
Projection: already-onboarded

#### Verification Failed

The [Clear Review] refusal when the reinstatement's precondition is unmet — a concurrent suspend re-armed it, or the party was not Suspended.

Kind:       Member
Member of:  the clear-review rejection
Role:       Rejection
Projection: verification-failed

#### Not Active

The refusal the three repeatable actions answer for a case whose relationship has ended. Monitoring does not fire against a closed relationship, a closed case takes no further verification, and a second closure has nothing to close; the guard sits before the intent, so a closed case never reaches a constituent and never leaves an intent for an act that could not happen.

Kind:       Member
Member of:  the case-guard rejection
Role:       Rejection
Projection: not-active

#### Trigger On Suspended Party

The audit event class an adverse trigger records when the party already stands suspended — a real trigger, no new transition. A distinct class from the suspension record so a second adverse alert is not read as a second suspension and an auditor does not miscount transitions; the trigger still enters the open set, and one clearance closes every trigger it names.

Kind:       Member
Member of:  the outcome event classes
Role:       Audit event
Projection: customer-onboarding.trigger-on-suspended-party

#### Trigger Voided

The audit event class recorded when a trigger landed and its `suspend` was refused, naming the constituent's answer. Without it the landed trigger rebuilds as an open investigation against a party nobody suspended, which [Clear Review] would then *clear* — recording a fresh verification, attempting a reinstate the constituent refuses, and never landing the record whose absence would keep the trigger open forever.

Kind:       Member
Member of:  the outcome event classes
Role:       Audit event
Projection: customer-onboarding.trigger-voided

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Initiate Onboarding]: #initiate-onboarding
[Record Verification]: #record-verification
[Trigger Monitoring Review]: #trigger-monitoring-review
[Clear Review]: #clear-review
[Close Party]: #close-party
[Activity Permitted]: #activity-permitted
[Next Review Due]: #next-review-due
[Not Verified]: #not-verified
[State Unavailable]: #state-unavailable
[No Open Trigger]: #no-open-trigger
[Enrollment Failed]: #enrollment-failed
[Party Not Known]: #party-not-known
[Party Not Admissible]: #party-not-admissible
[Already Onboarded]: #already-onboarded
[Verification Failed]: #verification-failed
[Not Active]: #not-active
[Trigger On Suspended Party]: #trigger-on-suspended-party
[Trigger Voided]: #trigger-voided

---

## Standards references

- **FATF Recommendations 10–12** — R.10 (Customer Due Diligence) gathers the CDD limbs: identify and verify the customer using reliable independent sources, identify and verify beneficial owners, and conduct ongoing due diligence and monitoring of the business relationship. R.11 (record-keeping) requires CDD and transaction records be kept at least five years. R.12 extends enhanced CDD to politically-exposed persons. This composition's [Initiate Onboarding] → [Record Verification] → [Trigger Monitoring Review] arc is the structural form of R.10's identify–verify–monitor obligation; the post-closure placement carries R.11's record-keeping floor; the verification-gates-activity decision is the before-relationship-activity limb.
- **BSA/AML — 31 CFR section 1020.220 (Customer Identification Program)** — minimum identity attributes, verification, and **record retention for five years after the business relationship ends**. [Close Party]'s post-closure placement is the structural form of that floor (Invariant 5.3), and Capability requirement 17 is where the deployment's configured duration is held to it.
- **FinCEN (Financial Crimes Enforcement Network) Beneficial Ownership Rule — 31 CFR section 1010.230** — legal-entity customers must identify and verify beneficial owners owning at least 25% and a single control person. Each beneficial owner is a Party Identity record verified through an onboarding case of their own; the ownership graph belongs to the Ownership Structure composing pattern (Non-goal 8).
- **EU 5th Anti-Money Laundering Directive (AMLD5)** — enhanced CDD requirements, beneficial-ownership registries, and ongoing-monitoring obligations, aligned with FATF. This composition is the onboarding-and-monitoring surface an AMLD5 deployment builds on.
- **GDPR Article 6(1)(c) — legal obligation as processing basis.** Customer Due Diligence processing rests on Article 6(1)(c), **not** Article 6(1)(a) consent. The distinction is load-bearing: the customer cannot revoke the basis for Customer Due Diligence processing while the AML obligation stands, which is why Consent is not a constituent. Consent governs *non-obligatory* downstream processing (Non-goal 11).
- **HIPAA (Health Insurance Portability and Accountability Act) section 164.312(a)(1) (Access control)** — in covered healthcare deployments where a verified party identity is the precondition to granting access to protected health information, the verification-gates-activity decision is the structural form of the access-granting event: access is provisioned only through a substantiated, audited verification. This composition is anchored in the BSA/AML/FATF cluster; the HIPAA mapping applies where a covered entity uses verification-based provisioning.

The three constituents carry their own deep standards inheritance — see each constituent's Standards references.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — customer-onboarding.tla + 1 twin, 2026-06-03
last gate: 2026-08-29 — second gate after closure, fresh reader — 6 foundational (all since closed), 12 refining, 6 rhetorical

open:
- 2026-08-29-s · refining · formal · the model's reconciliation carries no age bound → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/customer-onboarding.md`; the migration and the regeneration that got it here are in [its history](./customer-onboarding.hist.md).

- **2026-08-26 — Invariant 4 is narrowed to the actor the composition authenticates.** *Chose:* the clearing actor, whose credential is verified, attests that fresh evidence naming the verifying actor was recorded before the reinstatement. *Over:* requiring `verifying_actor_ref == actor_ref`, or taking a second credential. *Because:* the first collapses a real separation of duties (an analyst gathers evidence, a manager clears the review) and the second is a signature change; the guarantee was narrowed to what the records can show.
- **2026-08-27 — The active-relationship retention is a renewed chain, not one placement.** *Chose:* the periodic path of [Trigger Monitoring Review] places a fresh active-relationship retention at every review, recorded as `customer-onboarding.retention-renewed`, with Configuration requiring the policy's duration to exceed the review interval. *Over:* a single placement at intake, or an active-case purge gate composed through Defensible Retention. *Because:* a Retention Window placement is fixed-duration and its policy immutable, so a single placement lawfully lapses under a relationship longer than its duration; a purge gate would protect the record but leave it under no retention obligation at all, and the composition exposes no purge surface to gate.
- **2026-08-29 — The reconciliation is a declared, bounded scan whose pre-check keys on the intent.** *Chose:* onboarding_completion_bound below and the audit horizon above; compensation window and reconciliation cadence declared; the pre-check traversal matched on intent event id rather than on "the same identifying payload". *Over:* a retry-until-lands with an undeclared cadence and a payload-resemblance pre-check. *Because:* the pre-check cannot see an invocation that has not written yet, so a re-emission inside the bound lands a second outcome for one act; and resemblance chooses where a key does not (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*).
- **2026-09-14 — The monitoring schedule and the open-trigger set are derived indexes, not extraction-pending state.** *Chose:* all four indexes classified as derived index, each with a named rebuild, a per-index definition of *miss*, and the same horizon bound; the proposed **Review Schedule** atom kept as `Non-goal 17` rather than as a classification. *Over:* keeping the schedule half flagged extraction-pending, or extending the flag to the open-trigger set for consistency. *Because:* the section titled Composition state in `execution-contract.md` asks one question — is every fact derivable from the constituents' stores through their declared reads — and the spec's own rebuild answered yes for both, in the same subsection that flagged one of them as non-derivable. Two sentences cannot both be the classification, and the Contract's test picks which. The extraction may still be worth making; it is a concept named for someone to own, not a debt riding this composition's classification. Closes the Ledger's `2026-08-26-k` (the flag asserted Pass 2 gates nobody ran) and `2026-08-29-l` (Gate 3 applied unevenly across four elements).
- **2026-09-14 — The external path admits `Unverified` and nothing else.** *Chose:* one guard and one parameterized refusal, [Party Not Admissible], naming the state found. *Over:* keeping the `party-closed` arm and adding a second arm for `Verified` and `Suspended`. *Because:* the prose guarded `Closed` alone, so a `Suspended` admit opened a case with an empty open-trigger set against a suspended party and a `Verified` admit passed the gate with no verification record of this composition's — a hole in the composition's own load-bearing guarantee, reachable from the ordinary external path. A second arm beside `party-closed` would have split one guard's answer across two codes; the fold gives the caller one code and the state it needs.
- **2026-09-14 — state-unavailable is mapped from the seam, not from a constituent arm.** *Chose:* an unanswered constituent read is the state-unavailable of the section titled Step 1 failure in `execution-contract.md`, and Party Identity's declared `invalid-query` arm maps to invalid-request as this composition's own defect. *Over:* continuing to map state-unavailable from Party Identity's `read`. *Because:* that atom's `read` declares two answers — the matching parties, or `invalid-query` — and neither is an unreadable store, so the mapping named a contract the constituent does not have. The gate's fail-closed behaviour is unchanged; what changed is where the page says it comes from.
- **2026-10-20 — The store's guarantees cited, not restated, and an onboarding action's writes one transaction.** *Chose:* Capability requirement 45 citing Execution Contract Store 1 through 4 for the store the three constituents and the four indexes keep their records in; the rules restating what that store guarantees tombstoned to it — the per-party serialization of a state-changing action, a losing transition's answer, the one-invocation hold on a case's open-trigger set, the reconciliation's exclusion from a held case and from a second reconciliation, and the invalid-credential at an outcome, which the one transaction's read of the actor registry forecloses (Concurrency 1, 5, 7, 8, Reconciliation 26, Audit arm 8); and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the reconciliation's run at every process restart and its lower edge, the owed post closure placement and the owed renewal a placement lost between its call and its record left, and the alert on a closed case carrying no post closure placement (Reconciliation 1, 4, 12, 13, 21); the arms for a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing (Audit arm 5, 6, 18); the invocation's own retry of an owed record, its yield and its hand-off (Audit arm 14 through 17); the in-invocation re-query of an indeterminate committing call, the escalation of an indeterminate enroll and the bar on retrying a committing call outside its invocation (Atomic writes 3 through 9, Action wiring 133); the outcome position a storage failure after a committed sibling call answered (Action wiring 18, 101, 126); the scoped retry inside [Clear Review] and a lost clearance's recovery (Action wiring 108 through 110); and the completing closure, whose earlier closure with no record is now only one whose record Audit Trail refused, which the reconciliation records (Action wiring 117, 118, Reconciliation 8). Rules 511 to 478. *Over:* intent, constituent writes and outcome committed one by one, ordered so that a crash between them left a state the composition could name — a committed act with no record, a closed party with no floor, a constituent call whose answer was lost — with a host that serialized each party's actions, an invocation that retried its own record up to the onboarding completion bound, and a reconciliation that waited out that bound, re-queried what the intent fixed, placed what a crash left owed and recorded or closed the rest. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal. Party Identity, Retention Window and Audit Trail each supply their store under Store 1 through 4, and no action here makes an act outside the store, so an action's intent, constituent writes and outcome commit together. The census's question is decided by the ruling's second clause: the intents stay, since an intent is where the caller's credential is validated before any constituent write (Audit arm 1, Invariant 8.1, Check 8.1) and the intent of an attempt a constituent refuses is the evidence the page keeps for the reconciliation to close (Audit arm 7, Reconciliation 7). An Audit Trail refusal at an outcome record still leaves the act committed and its record owed (Audit arm 9, 10, 12), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the per-action answers that report it, the reconciliation's selection of open markers, its re-query on the values the intent fixed, its traversal, recovery intent and recovery outcome under the service identity, its compensation window and the closure floor that window must exceed, the alerts, the escalations and the checks that read an owed or recovered record (Action wiring 34, 65, 74, 78, 92, 93, 103, 128, Audit arm 13, 19, 22 through 25, Composes 16, 17, Reconciliation 3, 5 through 11, 14 through 20, 24, 27 through 31, Capability requirement 24, 26 through 29, 42, Invariant 2.4, 7.3, Atomic writes 10 through 12, Check 2.3, 7.6, 8.3 through 8.6); the onboarding completion bound stays with them, since the closure floor still reads it (Capability requirement 23, 27), and so does Action wiring 51, the trigger path's Audit arm 1, which an Audit Trail refusal of the trigger record still reaches. The four indexes stay derived indexes outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps them, so their rebuild on a miss, their population after the landed record, a clearance's drop of exactly the triggers its record names, and [Close Party]'s not-active for a case whose closure an index has not yet recorded stay (Composition state 7, 9 through 14, 21, 35, Atomic writes 2, Action wiring 64, 75, 104 through 106, 119, 129 through 131, Check 6.3). A renewal Retention Window refuses keeps its answer and its advance, capped below the current placement's cover, so the next review renews the chain (Action wiring 71, 72, 76, Clock semantics 4); the owed renewal was the lost one's. The rebuilds and reproductions read the Event Log's insertion order (Invariant 3.3) and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.
- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 45, Execution Contract Read 1 through 3) and the four rules that restated it for a constituent read the host's I/O never completed deleted to it (Action wiring 41, Action wiring 139, Action wiring 141, Action wiring 154), Term unanswered read with them, and state-unavailable off the signatures of [Initiate Onboarding] and [Trigger Monitoring Review]; rules 478 to 474. *Over:* the page stating for itself what an action answers when a read it makes never answers. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once, and the mapping this page chose on 2026-09-14, an unanswered read answered state-unavailable from the seam, is what Read 1 now says for every specification. [Activity Permitted] keeps state-unavailable on its signature for a case of its own (Action wiring 140): a case entry whose party the database no longer answers for, an answered read the gate fails closed on, which no rule of the contract decides.

NOTE: End of Customer Onboarding.
