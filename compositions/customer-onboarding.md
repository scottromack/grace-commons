---
title: Customer Onboarding
id: 8
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

Customer Onboarding is a regulated composition (a spec that wires two or more atoms — freestanding, self-contained pattern specs — together) that solves a problem none of its constituents solves alone: ensuring that an external party (customer, counterparty, beneficial owner) reaches regulated activity only after their identity has been verified through an attributed, tamper-evident process, that the relationship is monitored on an ongoing basis with adverse triggers driving suspension, and that the identity record survives for the regulator-mandated period after the relationship ends. It wires three constituents: Party Identity (the persistent, verifiable identity record with its Unverified → Verified → Suspended → Closed lifecycle), Retention Window (the policy-bounded record lifetime, used in two distinct placements — one renewed through the relationship, one at relationship end), and the Audit Trail substrate (the tamper-evident — designed so unauthorized changes are detectable — regulated-audit substrate that attribution-stamps and seals every state-changing decision). Each action that changes a party or a case follows [Recoverable Invocation](./recoverable-invocation.md): an audit intent before the change, an audit outcome after it, and a sweep that recovers the outcome of a change whose record never landed — so a change is never left both made and unrecorded without that standing visible.

The composition's defining emergent guarantee (a property that appears only when atoms are combined — no single atom carries it) is verification-gates-activity: a single read-only query, [Activity Permitted], answers permitted if and only if the party has an onboarding case with Customer Onboarding **and** Party Identity reports the party in `Verified` state — a party verified outside the composition's own case surface does not pass. Activity systems consume this query rather than reading Party Identity directly, so the gate is implemented exactly once instead of re-implemented (or skipped) per activity system. Customer Onboarding is the layer that centralizes both that the `Verified` state was reached through an attributed, tamper-evident verification (recorded in the Audit Trail) and that the gate query is the single surface activity consumes. This is the structural form of the check-the-customer-before-business obligation that US banking law names Customer Due Diligence (CDD) under the Bank Secrecy Act / Anti-Money Laundering rules (BSA/AML).

Beyond the gate, the composition guarantees four further emergent properties. Every `Unverified → Verified` transition produces a tamper-evident Audit Trail event carrying the verification identifiers. Every adverse monitoring trigger produces an Audit Trail event ordered before any suspension it precipitates, so no trigger-driven suspension exists in the records without its precipitating trigger ordered ahead of it. A party reinstated after an adverse trigger has a passed verification recorded after the most recent suspend, and the clearing actor — whose credential this composition verifies — attests that the fresh evidence was recorded before the reinstatement. The party record is under a live Retention Window placement at every instant of the relationship — renewed at each periodic review, because a placement is fixed-duration and nothing else renews it — and a closed party's record cannot be purged before its post-closure floor (the BSA/AML five-year period under 31 CFR (Title 31 of the Code of Federal Regulations) section 1020.220) elapses.

Its most common uses are retail and commercial bank customer onboarding under BSA/AML, broker-dealer counterparty onboarding, payments-processor merchant onboarding, and crypto-exchange customer onboarding under the EU 5th Anti-Money Laundering Directive (AMLD5). Any system that must make it provable that every party with regulated activity was verified before that activity, that adverse triggers were acted on, and that closed-party records were retained for the mandated post-closure period, is a candidate for this composition.

---

## Intent

Every financial institution that admits an external customer faces the same regulated arc, and the arc is the same whether the institution is a retail bank, a broker-dealer, a payments processor, or a crypto exchange. The customer's identity must be established and verified before regulated activity begins; the verified status must be the precondition any account-opening, transaction, or service-provisioning system checks; the relationship must be monitored on an ongoing basis so that a sanctions match, a politically-exposed-person (PEP — Politically Exposed Person) status change, or adverse media triggers suspension and re-verification; and when the relationship ends, the identity record and its Customer Due Diligence (CDD) evidence must survive for a regulator-mandated period after closure. FATF (Financial Action Task Force — the international standard-setter for anti-money-laundering and counter-terrorist-financing rules) Recommendations 10–12 name the arc as Customer Due Diligence: identify, verify, conduct ongoing monitoring. BSA/AML (Bank Secrecy Act / Anti-Money Laundering) 31 CFR section 1020.220 fixes the record-retention floor at five years after the business relationship ends. The domain varies; the structural obligation is constant.

Neither Party Identity nor Retention Window, alone, enforces this arc. Party Identity owns the verification lifecycle — Unverified, Verified, Suspended, Closed — and refuses a reinstatement without a recorded passed verification after the most recent suspension (Party Identity Operation 18). But Party Identity exposes no gate: it records that a party is Verified, and it neither enforces that activity systems consult that state nor knows what regulated activity means. Retention Window owns the record-lifetime clock, and knows nothing of when a relationship begins or ends; it takes a `policy_ref` and a `record_ref` and enforces a no-early-purge guarantee, nothing more. The Audit Trail substrate records attributed, tamper-evident, retention-bounded events, and does not know which events constitute a verification chain or a monitoring history. The structure that makes the three coherent as a single Customer Due Diligence surface — the gate that centralizes the verification precondition, the monitoring schedule that drives re-verification, the placements that bracket the relationship — belongs to no single constituent. It belongs to the composition, and this composition is that structure.

This is a composition, not a new primitive. Party Identity, Retention Window, Audit Trail and the Recoverable Invocation protocol are unchanged; the composition is the wiring that makes them coherent as a single Customer Due Diligence surface. It introduces emergent actions — [Initiate Onboarding], [Clear Review], [Activity Permitted] — that belong to no single constituent and exist only because the three are wired together. [Clear Review], in particular, wraps a Party Identity `verify(passed)` and a Party Identity `reinstate` into one transaction, recorded by one audit intent and one audit outcome, so that clearing an adverse-trigger investigation is a single auditable act rather than a sequence of leaked atom internals an operator must orchestrate by hand.

What it waits on is narrow. Each of its five acting actions waits on calls it does not own — Party Identity's and Retention Window's writes, and Audit Trail's records of them — and composes Recoverable Invocation for that wait rather than recovering the act itself. The verification workflow's result, an adverse-trigger investigation and the review scheduler are not such a wait: the composition records a result the deployment's own workflow produced, a suspended party waits on a person's [Clear Review] and no rule ends a wait on a person, and the scheduler calls the composition rather than the reverse (Non-goal 1, Non-goal 6, Non-goal 24).

What the composition is *not*: it is not the verification workflow (document OCR (Optical Character Recognition), biometric check, sanctions-database query — those produce the verification result Party Identity records); it is not the risk-scoring or enhanced-due-diligence (EDD) engine; it is not the consent surface for downstream non-obligatory processing (the Customer Due Diligence processing basis is GDPR (General Data Protection Regulation) Article 6(1)(c) legal obligation, not consent); and it is not the scheduling engine (the composition holds schedule state and an external scheduler fires the monitoring triggers). Each is named explicitly in Non-goals.

---

## Composes

- **[Party Identity](../atoms/party-identity.md)** — the persistent, verifiable identity record and its lifecycle.
- **[Retention Window](../atoms/retention-window.md)** — the policy-bounded lifetime of the party record.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate every decision is recorded through.
- **[Recoverable Invocation](./recoverable-invocation.md)** — the protocol the five acting actions follow around their constituent writes: an intent before the commit, an outcome after it, and a sweep that closes the record of a commit whose outcome never landed; this page restates none of it.

```
Composes 1: EXACTLY ONE Party Identity instance MUST serve the composition.
Composes 2: EXACTLY ONE Retention Window instance MUST serve the composition over party records.
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
Composes 16: The composition MUST bind the recovery identity as the service identity of EVERY act kind.
Composes 17: The composition's own actions MUST NOT attest an invocation's audit record under the recovery identity.
Composes 18: The composition MUST call Party Identity's enroll ONLY IF the direct path stands.
Composes 19: The composition MUST own EVERY state transition on the Party Identity instance.
Composes 20: A deployment MUST NOT admit a second writer of a state transition on the Party Identity instance.
Composes 21: The composition MUST place a party retention through Retention Window's place_under_retention.
Composes 22: The composition MUST read a placement's policy reference, retention instant, retention deadline AND purge eligibility through Retention Window's declared read.
Composes 23: The composition MUST read a party's state through Party Identity's declared read.
Composes 24: The composition MUST read an audit record through Audit Trail's read_record.
Composes 25: The composition MUST verify an audit record through Audit Trail's verify_record.
Composes 26: The composition MUST NOT call Audit Trail's record_destruction.
Composes 27: EXACTLY ONE Recoverable Invocation instance MUST serve the composition.
Composes 28: The Recoverable Invocation instance MUST write to the composition's Audit Trail instance.
Composes 29: The composition MUST bind the act kinds PER the onboarding bindings.
Composes 30: The composition MUST NOT bind [Activity Permitted] as an act kind.
Composes 31: The composition MUST NOT hold an instance of Lease, which Recoverable Invocation reaches.
```

Term composition: this pattern's wiring of [Party Identity](../atoms/party-identity.md), [Retention Window](../atoms/retention-window.md), the [Audit Trail](./audit-trail.md) substrate and [Recoverable Invocation](./recoverable-invocation.md) — the six actions, the gate, the four indexes, the onboarding bindings and the reconciliation.

Term constituents: [Party Identity](../atoms/party-identity.md), [Retention Window](../atoms/retention-window.md), [Audit Trail](./audit-trail.md), [Recoverable Invocation](./recoverable-invocation.md).

Term transitive atoms: [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md), [Tamper Evidence](../atoms/tamper-evidence.md) and [Retention Window](../atoms/retention-window.md), reached through Audit Trail, and [Lease](../atoms/lease.md), reached through Recoverable Invocation.

Term party retention instance: the one [Retention Window](../atoms/retention-window.md) instance this composition wires over party records — distinct from the instance [Audit Trail](./audit-trail.md) carries for the substrate's own events.

Term recovery identity: application_actor_ref and application_credential — the composition's own registered actor and credential, the service identity of the seven act kinds, under which Recoverable Invocation's sweep attests every write it makes for them (Recoverable Invocation service identity 3); no write the composition's own actions make is attested under it.

Term direct path: an [Initiate Onboarding] call carrying no party id, on which the composition enrolls the party.

Term external path: an [Initiate Onboarding] call carrying a party id External Onboarding already enrolled.

Term acting action: [Initiate Onboarding], [Record Verification], [Trigger Monitoring Review], [Clear Review] or [Close Party] — the five actions that write, each binding one act kind or, at [Initiate Onboarding] and [Trigger Monitoring Review], one of two by the path or the trigger type.

Term act kind: customer-onboarding.enrollment, customer-onboarding.admission, customer-onboarding.verification, customer-onboarding.adverse-trigger, customer-onboarding.periodic-review, customer-onboarding.clearance or customer-onboarding.closure — the seven act kinds this composition binds on its Recoverable Invocation instance, split by the call each waits on: the direct path's initiation, which waits on a minting enroll, and the external path's, which does not; [Record Verification]; an adverse trigger, which waits on a suspend, and a periodic one, which waits on a placement; [Clear Review]; [Close Party].

Term onboarding namespace: the action references of the seven act kinds' vocabularies on the composition's Audit Trail instance — for each kind, the kind's intended record, its one outcome and its refused record: customer-onboarding.enrollment.intended, customer-onboarding.enrollment.initiated, customer-onboarding.enrollment.refused; customer-onboarding.admission.intended, customer-onboarding.admission.initiated, customer-onboarding.admission.refused; customer-onboarding.verification.intended, customer-onboarding.verification.recorded, customer-onboarding.verification.refused; customer-onboarding.adverse-trigger.intended, customer-onboarding.adverse-trigger.suspended, customer-onboarding.adverse-trigger.refused; customer-onboarding.periodic-review.intended, customer-onboarding.periodic-review.renewed, customer-onboarding.periodic-review.refused; customer-onboarding.clearance.intended, customer-onboarding.clearance.cleared, customer-onboarding.clearance.refused; customer-onboarding.closure.intended, customer-onboarding.closure.closed, customer-onboarding.closure.refused — with the recovery_intended, abandoned and escalated references Recoverable Invocation derives under each kind (Recoverable Invocation journal 3).

Term onboarding bindings: each act kind's bindings, under the name Recoverable Invocation gives each. For customer-onboarding.enrollment: act key — the enrollment key, under the minted-key deviation; commit — the enrollment transaction; act probe — the enrollment probe. For customer-onboarding.admission: act key — the party id; commit — the admission transaction; act probe — the admission probe. For customer-onboarding.verification: act key — the party id, resolved from the case through the case-to-monitoring index ahead of the open; commit — Party Identity's verify; act probe — the verification probe. For customer-onboarding.adverse-trigger: act key — the party id; commit — the suspension transaction; act probe — the suspension probe. For customer-onboarding.periodic-review: act key — the party id; commit — the renewal transaction; act probe — the renewal probe. For customer-onboarding.clearance: act key — the party id; commit — the clearance transaction; act probe — the clearance probe. For customer-onboarding.closure: act key — the party id; commit — the closure transaction; act probe — the closure probe. For all seven: journal events — the kind's intended record, the one outcome the onboarding namespace names for it, and the kind's refused record; pairing datum — the invocation's now, which the host injects into Party Identity's seam and Retention Window's seam (Capability requirement 48), so that Party Identity's enrollment instant, verification instant and state change instant, and Retention Window's retention instant, equal it, the retention instant rounded up to Retention Window's time resolution (Retention Window State 4a); repeatable — yes; invocation completion bound — the onboarding completion bound; commit round trip and probe round trip — the deployment's disclosed bounds; journal — the composition's Audit Trail instance; retention period — the audit horizon; settling period — the deployment's settling period; service identity — the recovery identity; actor at the open and the close — the calling actor; outcome envelope — the largest outcome payload at the field caps (Capability requirement 30, Capability requirement 31).

NOTE: open 2026-11-11-b — the enrollment key's separator is unnamed, so its byte form, and the length Capability requirement 54 bounds, are undetermined for a reader who reproduces the act key.

Term enrollment key: the document type, the document reference and the enrolling actor reference of a direct path initiation's enrollment fields, in that order — the act key of customer-onboarding.enrollment. The party id is minted by Party Identity's enroll, so it is not known at the open: the minted-key deviation (Recoverable Invocation Deviation 4), declared here as Chain of Custody and Immutable Ledger declare it; the party record carries all three fields, so the probe's committed answer carries every field of the key (Recoverable Invocation act probe 8). Its length is the sum of the three fields' lengths and two separators. Party Identity does not detect a duplicate party (Party Identity Non-goal 1), so two enrollments of one key are two acts, repeatable being yes.

Term enrollment transaction: Party Identity's enroll and Retention Window's place_under_retention over the party id enroll answers, committed together or not at all (Execution Contract Database 1) — the one commit Recoverable Invocation's bound commit stands for for customer-onboarding.enrollment (Composition notes).

Term admission transaction: the re-read of the party's state and the party's active case (Action wiring 159), then Retention Window's place_under_retention, committed together or not at all (Execution Contract Database 1, Execution Contract Database 2).

Term suspension transaction: the re-run of the adverse pre-check (Action wiring 162), then Party Identity's suspend with the composed suspend reason, committed together or not at all.

Term renewal transaction: the re-read of the party's state (Action wiring 168), then Retention Window's place_under_retention with the current placement's policy reference, committed together or not at all.

Term clearance transaction: the re-read of the case's open triggers and of its adverse trigger intents (Action wiring 164), Party Identity's verify with passed, then Party Identity's reinstate, committed together or not at all — a refused reinstate rolls the verify back with it.

Term closure transaction: the re-read of the case's open triggers (Action wiring 166), Party Identity's close, then Retention Window's place_under_retention with the post closure policy, committed together or not at all.

Term commit partition: committed where the commit answers its records — the enrollment transaction a party id and a retention id, the admission and renewal transactions a retention id, Party Identity's verify a verification id, the suspension transaction a state change id, the clearance transaction a verification id and a state change id, the closure transaction a state change id and a retention id; pre-commit where a constituent refuses a call inside the commit — every refusal Party Identity's enroll, verify, suspend, reinstate and close and Retention Window's place_under_retention declare, already-suspended among them (Party Identity Operation 15), storage-failure (Execution Contract Constituent failure 1) and registry-unavailable (Execution Contract Constituent failure 2) included — where a re-read inside the commit finds a state the action did not admit (Action wiring 160, 161, 163, 165, 167, 169), or where the database answers state-unavailable (Execution Contract Constituent failure 3); unknown where a call answers a code its constituent does not declare, or where its reply has not arrived when the commit round trip has elapsed since the call's issue (Recoverable Invocation commit 6, commit 7).

Term enrollment probe: the read that answers whether an open enrollment intent's enrollment transaction committed. Party Identity's read with an enrollment instant range from the intent's pairing datum to the same instant, kept in the composition's code to the parties whose document type, document reference and enrolling actor reference equal the enrollment key; then Retention Window's read, kept to a retention whose record reference is that party, whose policy reference is the intent's retention policy reference and whose retention instant equals the pairing datum rounded up to Retention Window's time resolution. One party and one retention answer committed carrying the party id, the retention id and the opening instant; none answers not-committed; more than one answers undecidable carrying them; a read that answers invalid-query or gives no answer answers unavailable (Recoverable Invocation act probe 2 through 5, Recoverable Invocation Deviation 4b), and an invalid-query is surfaced on the finding surface.

Term admission probe: the read that answers whether an open admission intent's placement committed — Retention Window's read, kept in the composition's code to a retention whose record reference is the act key's party id, whose policy reference is the intent's retention policy reference and whose retention instant equals the pairing datum rounded up. Exactly one answers committed carrying the party id, the retention id and the opening instant; none answers not-committed; more than one answers undecidable; a read that fails or gives no answer answers unavailable.

Term verification probe: the read that answers whether an open verification intent's verify committed — Party Identity's read by the act key's party id, kept in the composition's code to the verification event whose verification instant equals the pairing datum and whose verifying actor reference and evidence reference equal the intent's, and to the state change event at the same instant, if any. One verification event answers committed carrying the verification id, the state change id where one stands, and the verification result; none answers not-committed; more than one answers undecidable; a read that answers invalid-query or gives no answer answers unavailable.

Term suspension probe: the read that answers whether an open adverse trigger intent's suspend committed — Party Identity's read by the act key's party id, kept to the state change event whose instant equals the pairing datum, whose new state is suspended and whose reason is the intent's composed suspend reason. One answers committed carrying the state change id and the suspension instant; none answers not-committed; a read that answers invalid-query or gives no answer answers unavailable.

Term renewal probe: the read that answers whether an open periodic review intent's placement committed — Retention Window's read, kept to a retention whose record reference is the act key's party id, whose policy reference is the intent's policy reference and whose retention instant equals the pairing datum rounded up. One answers committed carrying the renewed placement and the renewal instant; none answers not-committed; more than one answers undecidable; a read that fails or gives no answer answers unavailable.

Term clearance probe: the read that answers whether an open clearance intent's clearance transaction committed — Party Identity's read by the act key's party id, kept to the passed verification event whose verification instant equals the pairing datum and whose verifying actor reference and evidence reference equal the intent's, and to the state change event at the same instant whose new state is verified. Both answer committed carrying the verification id, the state change id, the reason and the clearance instant; neither answers not-committed; one without the other is not met, the two committing together; a read that fails or gives no answer answers unavailable.

Term closure probe: the read that answers whether an open closure intent's closure transaction committed — Party Identity's read by the act key's party id, kept to the state change event whose instant equals the pairing datum and whose new state is closed, and Retention Window's read, kept to a retention over the party under the post closure policy whose retention instant equals the pairing datum rounded up. Both answer committed carrying the state change id, the post closure placement, the reason and the closure instant; neither answers not-committed; a read that fails or gives no answer answers unavailable.

NOTE: open 2026-11-10-c — Retention Window rounds a retention instant up to its time resolution (Retention Window State 4a), so two placements over one party inside one resolution step match one probe's datum together and answer undecidable, which the sweep escalates for an operator; the kinds that pair on a Party Identity instant are not reached, and Check 10.1 reads a placement both intents carry as an arm of its own.

Term probed record: a party record, a verification event, a state change event or a retention — what an act probe of the seven kinds reads.

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
Composition state 23: The rebuild of the party-to-case index MUST select the initiation outcomes AND the periodic review intents.
Composition state 24: The rebuild of the party-to-case index MUST take the case id AND the enrollment path from the latest selected record PER party id in intent order.
Composition state 25: The rebuild of the party-to-case index MUST write the case's active flag set to true ONLY IF no closure outcome, selected PER case id, names the case id.
Composition state 26: The rebuild of the case-to-monitoring index MUST take the party id from the latest binding-bearing record PER case id in intent order.
Composition state 27: The rebuild of the case-to-monitoring index MUST take the opening instant from the initiation outcome.
Composition state 28: The rebuild of the case-to-monitoring index MUST take the next review due from the latest schedule-bearing record PER case id in intent order.
Composition state 29: The rebuild of the case-to-retentions index MUST take the current placement from the latest placement-bearing record PER case id in intent order.
Composition state 30: The rebuild of the case-to-retentions index MUST take the post closure placement from the closure outcome.
Composition state 31: The rebuild of the case-to-open-triggers index MUST select the adverse trigger intents PER case id.
Composition state 32: IF an adverse trigger intent stands abandoned OR the intent's refusal record carries a constituent code other than already-suspended THEN the rebuild of the case-to-open-triggers index MUST drop the intent's trigger.
Composition state 33: The rebuild of the case-to-open-triggers index MUST drop a trigger a closure intent's open triggers at close names ONLY IF the closure's outcome stands.
Composition state 34: The rebuild of the case-to-open-triggers index MUST drop a trigger a clearance intent's closed triggers names ONLY IF the clearance's outcome stands.
Composition state 35: The composition MUST populate an index ONLY AFTER the index's backing closing.
Composition state 36: EXACTLY ONE active case MUST stand PER party.
Composition state 37: A case MUST name EXACTLY ONE party.
Composition state 38: EXACTLY ONE current placement MUST stand PER active case.
Composition state 39: A case MUST NOT carry two post closure placements.
Composition state 40: A closed case MUST carry a post closure placement.
Composition state 41: An open trigger MUST name EXACTLY ONE case.
Composition state 42: A case MAY carry no open trigger.
Composition state 43: A case MAY carry two open triggers.
Composition state 44: A party-to-case entry of an active case MUST name a party the Party Identity instance holds.
Composition state 45: A case-to-retentions entry of an active case MUST name a retention the party retention instance holds.
Deleted: Composition state 46. Composition state 47 owns it: the entry of a closed case stands, since the composition never drops one.
Composition state 47: The composition MUST NOT drop a case-to-monitoring entry.
Composition state 48: The composition MUST NOT store a review due flag.
Composition state 49: The composition MUST NOT store an overdue flag.
Composition state 50: The composition MUST NOT duplicate a constituent's records.
Composition state 51: The composition MUST NOT store a record of the Recoverable Invocation instance.
Composition state 52: A rebuild MUST read a pre-switch record as the record's counterpart in the onboarding namespace.
```

NOTE: open 2026-11-04-b — Composition state 5 classifies every index as derived index, and an unrebuildable entry (Composition state 20 through 22) holds a case id, a party id and an enrollment path no rebuild reproduces once the binding-bearing events age out; Capability requirement 14 keeps those events for the binding floor.

Term case-to-monitoring index: case_to_monitoring — the composition's index from a case id to the case's party id, opening instant and [Next Review Due]; the auditor's first query surface for monitoring continuity.

Term party-to-case index: party_to_case — the composition's index from a party id to the party's case id, enrollment path and active flag; the gate's first read and the join an auditor makes from an activity record to an onboarding case.

Term active flag: true | false — whether a case is open: true from the case's initiation outcome, false once a closure outcome names the case (Composition state 25, Action wiring 130).

Term active case: a case whose active flag EQUALS true.

Term case-to-retentions index: case_to_retentions — the composition's index from a case id to the current placement and the post closure placement.

Term case-to-open-triggers index: case_to_open_triggers — the composition's index from a case id to the open adverse triggers standing against the case, each carrying a trigger id, a trigger type, a trigger ref and a trigger instant.

Term index: the case-to-monitoring index, the party-to-case index, the case-to-retentions index, OR the case-to-open-triggers index.

Term current placement: the latest active relationship retention the composition placed over a case's party — active_relationship_retention_id.

Term post closure placement: the retention [Close Party] places over the party record at the relationship's end — post_closure_retention_id.

Term audit horizon: the age past which the audit instance has destroyed an event's payload, set by the instance's audit_trail_retention_policy.

Term aged-out event: an event whose age exceeds the audit horizon.

Term rebuild: the composition's named regeneration of an index — select this composition's events over an open-ended sequence range, keep the events the index names by action reference, read each outcome and each refusal record beside the intent it carries the intent event id of (Recoverable Invocation Primitive policy 11a), and take the index's fields from their payloads in intent order.

Term intent order: the Event Log insertion order of the intents the selected records join to, an outcome or a refusal record read at its intent's place — not the order the outcomes landed in, since an outcome Recoverable Invocation's sweep recovers lands when the sweep writes it, possibly after a later act's own. Two acts of one kind on one party serialize under the act's critical section, and a renewal's intent follows the initiation's outcome (Action wiring 39), so for the placement chain the intent order is the act order (Clock semantics 7).

Term miss: an index read the composition answers by rebuilding rather than by the stored value.

Term unrebuildable entry: an index entry every one of whose binding-bearing events stands aged out.

Term binding-bearing record: an initiation outcome, read with its intent, OR a periodic review intent — the two that carry a case's case id, party id and enrollment path, the initiation's party id on the direct path from its outcome and every other field from the intent.

Term schedule-bearing record: an initiation intent whose initiation outcome stands, a verification intent whose verification outcome carries a state change id, a periodic review intent carrying a next review due whose renewal outcome stands, OR a clearance intent whose clearance outcome stands — the records a next review due rides.

Term placement-bearing record: an initiation outcome OR a renewal outcome.

Term pre-switch record: a record of the classes the composition wrote before it bound its act kinds — customer-onboarding.initiation-intended, customer-onboarding.initiated, customer-onboarding.verification-intended, customer-onboarding.verification-recorded, customer-onboarding.monitoring-triggered, customer-onboarding.party-suspended, customer-onboarding.trigger-on-suspended-party, customer-onboarding.trigger-voided, customer-onboarding.retention-renewed, customer-onboarding.clearance-intended, customer-onboarding.review-cleared, customer-onboarding.party-reinstated, customer-onboarding.closure-intended, customer-onboarding.party-closed and customer-onboarding.recovery-intended — read by the rebuild for a case that outlives the switch, its binding floor reaching back past it (Capability requirement 14).

Term counterpart: the record of the onboarding namespace a pre-switch record stands for — an initiated record for an initiation outcome joined to its intent; a verification recorded record for a verification outcome; a monitoring triggered record for an adverse trigger intent or a periodic review intent by its trigger type; a party suspended record for a suspension outcome; a trigger on suspended party record for a refusal record carrying already-suspended; a trigger voided record for a refusal record carrying the code it names; a retention renewed record for a periodic review intent and its renewal outcome; a review cleared record together with its clearance's party reinstated record for a clearance intent and its outcome, a review cleared record with no party reinstated record for an open clearance intent; a party closed record for a closure intent and its outcome.

NOTE: open 2026-11-10-e — a pre-switch record carries its own pairing (an intent event id on the outcome, no act key) and the counterpart reads it as joined; a pre-switch review cleared record with no party reinstated record keeps its triggers open, as Composition state 34 kept them, and the reconciliation's write-ownership reading starts at the cut-over instant (Reconciliation 41), so a pre-switch case's records are read by the rebuild and never by the leg.

### Capability requirement

```
Capability requirement 1: The host MUST inject now, the invocation id, the run id AND the operator run id at the seam once PER invocation.
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
Capability requirement 20: A deployment MUST configure the party retention instance's policy registry so that EVERY policy an [Initiate Onboarding] call MAY name has a duration that EXCEEDS the renewal floor.
Capability requirement 20a: A deployment MAY start an instance ONLY IF the active relationship policy's duration EXCEEDS the renewal floor.
Capability requirement 21: A deployment MUST set the adverse trigger types.
Capability requirement 22: The adverse trigger types MUST NOT carry the periodic trigger type.
Capability requirement 23: A deployment MUST set the onboarding completion bound as EVERY act kind's invocation completion bound.
Deleted: Capability requirement 24. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 25. Recoverable Invocation sweep cadence 2 and Recoverable Invocation sweep cadence 3 own it.
Deleted: Capability requirement 26. Recoverable Invocation run bound owns it: the sweep's own, and the reconciliation runs inside it.
Deleted: Capability requirement 27. Recoverable Invocation Instance start 4 owns it: the worst closure against the closure window, the sweep's run counted in it.
Capability requirement 28: A deployment MUST provision the recovery identity as a registered actor.
Capability requirement 29: A deployment MUST rotate the recovery identity's credential.
Capability requirement 30: A deployment MUST set a field cap PER payload field.
Capability requirement 31: A field cap MUST NOT EXCEED the audit instance's payload cap.
Deleted: Capability requirement 32. Primitive policy 20 went with its cap: the trigger sets ride the intents in full, bounded by Audit Trail's payload cap (Capability requirement 31).
Capability requirement 33: The audit instance MUST serve an open-ended sequence range read.
Capability requirement 34: The audit instance MUST serve read_record for an aged-out event.
Capability requirement 35: The party retention instance MUST serve a placement read carrying the policy reference, the retention instant, the retention deadline AND the purge eligibility.
Capability requirement 36: The Party Identity instance MUST serve a singleton read by party id.
Capability requirement 37: A deployment MUST resolve a policy reference at Retention Window's seam.
Capability requirement 38: The composition MUST NOT reconcile two policies.
Capability requirement 39: An activity system MUST NOT read the Party Identity instance.
Capability requirement 40: A deployment MUST run a review scheduler outside the composition.
Capability requirement 40a: A deployment's review scheduler MUST fire the periodic trigger type PER monitoring interval against an active case whose next review due PRECEDES the scheduler's clock reading, a suspended party's case included.
Capability requirement 41: The composition MUST NOT fire a review.
Capability requirement 42: A deployment under the Bank Secrecy Act and Anti-Money Laundering rules MUST treat EVERY open verification intent the sweep examines as a hard alerting condition.
Capability requirement 43: A deployment MUST NOT set the monitoring interval PER party at this composition.
Capability requirement 45: The deployment MUST supply the database PER Execution Contract Database 1 through 4 and Execution Contract Read 1 through 3, AND the act section PER Execution Contract Database 7 AND Execution Contract Refusal 1 (Recoverable Invocation Capability requirement 12).
Deleted: Capability requirement 44. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 46. Recoverable Invocation Instance start 5 owns it: the retention floor.
Deleted: Capability requirement 47. Recoverable Invocation clock allowance owns it: the pairing datum is injected into every constituent's seam (Capability requirement 48), so no recovery comparison reads two clocks.
Capability requirement 48: The host MUST inject the invocation's now into Party Identity's seam AND Retention Window's seam for the commit of an acting action.
Capability requirement 49: The host MUST NOT inject an equal now into two invocations of one act key on any node of the instance.
Capability requirement 50: A deployment MUST supply the act section Recoverable Invocation takes (Recoverable Invocation Capability requirement 11).
Capability requirement 51: A deployment MUST disclose the commit round trip, the probe round trip AND the settling period.
Capability requirement 52: A deployment MUST set the instance's bounds PER Recoverable Invocation Instance start 4 through 8.
Capability requirement 53: A deployment MUST NOT remove a probed record BEFORE the audit horizon destroys the payload of the record's outcome (Recoverable Invocation Binding 9).
Capability requirement 54: A deployment MUST set field caps under which the enrollment key's length DOES NOT EXCEED Audit Trail's reference length cap (Recoverable Invocation Primitive policy 1).
Capability requirement 55: A deployment MUST declare the cut-over instant.
Capability requirement 56: A deployment MUST set the suspension bound.
Capability requirement 57: The suspension floor MUST NOT EXCEED the audit horizon.
```

NOTE: open 2026-11-11-c — the open-ended sequence range read (Capability requirement 33), Party Identity's reason cap (Primitive policy 9, Primitive policy 17), Audit Trail's payload cap (Capability requirement 31) and Recoverable Invocation's critical section (Term intent order) are named here and carried by no constituent's declared surface or Term cited line.

Term seam: the composition's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects one clock reading, one case id, one trigger id, one invocation id, one run id and one operator run id here.
Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term transition: the composition's evaluation of one call against the constituents, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term monitoring interval: monitoring_interval — the deployment's declared duration between a party's periodic reviews.

Term scheduler tolerance: scheduler_tolerance — the deployment's declared allowance for how late the external scheduler may fire a due review.

Term renewal floor: `(monitoring_interval + scheduler_tolerance)` — the interval a placement's duration must outlast for the chain to stay continuous under a late review.

Term binding floor: the monitoring interval taken with the scheduler tolerance and the post closure policy's duration — the age a binding-bearing record's payload must survive to.

Term suspension bound: suspension_bound — the deployment's declared longest a case stands suspended before a person's [Clear Review] or [Close Party] settles it.

Term suspension floor: `(suspension_bound + (monitoring_interval + scheduler_tolerance))` — the age the payload of a suspended case's latest schedule-bearing record must survive to, so that the open triggers the clearance and the closure re-read stand readable.

NOTE: open 2026-11-11-e — the suspension floor ages a suspended case's latest schedule-bearing record for the open triggers the clearance and the closure re-read, which ride the adverse trigger intents (Composition state 31) and age from their own instants.

Term reconciliation run bound: Recoverable Invocation's run bound on this composition's instance, inside which the reconciliation runs.

Term clock offset allowance: Recoverable Invocation's clock allowance on this composition's instance.

Term invocation id: the fresh id the host injects at the seam per acting invocation, carried by every record Recoverable Invocation writes for the invocation (Recoverable Invocation Term invocation id).

Term commit round trip: the deployment's disclosed bound on one commit, from issue to reply — the longest of the seven kinds' commits.

Term probe round trip: the deployment's disclosed bound on one act probe, from issue to answer.

Term settling period: the time the deployment declares for an operator to settle an escalated act through the invocation resolve (Recoverable Invocation Term settling period).

Term cut-over instant: the instant the deployment declares from which the composition's acting actions bind the act kinds — before it, the composition wrote pre-switch records.

Term onboarding completion bound: onboarding_completion_bound — the deployment's declared maximum for an acting action's invocation, each act kind's invocation completion bound: the longest it takes from the invocation open's take of the critical section to the invocation close's last write (the invocation yield's return where the commit answers an unknown arm), sized for the largest commit — the enrollment, clearance and closure transactions, two constituent calls each.

Term active relationship policy: active_relationship_policy_ref — the deployment's recommended Retention Window policy for a live relationship's party record.

Term post closure policy: post_closure_retention_policy_ref — the Retention Window policy [Close Party] applies.

Term post closure minimum: the applicable regulatory floor on a closed party's record — five years after the relationship ends under BSA/AML 31 CFR section 1020.220.

Term adverse trigger types: adverse_trigger_types — the deployment's set of trigger_type values that drive suspension; canonically sanctions-match | pep-status-change | adverse-media.

Term periodic trigger type: periodic-review-due — the one non-adverse trigger type.

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
Primitive policy 18: The composition MUST truncate a payload field exceeding the field's cap ONLY IF the field IS NOT IN the probe-matched fields.
Primitive policy 19: A truncated payload field MUST carry the truncation marker.
Deleted: Primitive policy 20. Recoverable Invocation Primitive policy 12 and Primitive policy 13 own it: an intent whose data exceeds Audit Trail's payload cap, the trigger sets in full included, refuses invalid-request at the open.
Primitive policy 21: The boundary predicate MUST refuse a blank retention policy reference.
Primitive policy 22: The boundary predicate MUST refuse a probe-matched field exceeding the field's cap.
```

NOTE: open 2026-11-11-a — the closed triggers a clearance intent names and the open triggers at close a closure intent names ride the intent in full, since Invariant 7.5, Composition state 33 and Composition state 34 read their full trigger ids, so a case whose open triggers outnumber what one intent carries under Audit Trail's payload cap is refused invalid-request at the open by [Clear Review] and [Close Party] alike.


Term boundary predicate: the composition's own validation of an input at an action's boundary, judged before any constituent call.

Term opaque input: party id | case id | trigger id | trigger ref | actor reference | verifying actor reference | closing actor reference | credential | retention policy reference | evidence reference | method.

Term actor reference: actor reference | verifying actor reference | closing actor reference | enrolling actor reference.

Term trigger vocabulary: the periodic trigger type OR a member of the adverse trigger types.

Term verification results: passed | failed.

Term truncation marker: the marker a payload field carries when the composition has cut the field to the field's cap.

Term probe-matched fields: verifying actor reference | evidence reference | document type | document reference | enrolling actor reference | retention policy reference | trigger type | trigger ref — the fields an act probe compares with the intent's by byte identity (Primitive policy 13), the last two through the composed suspend reason the suspension probe compares.

Term cover-bound invocations: an invocation of customer-onboarding.verification | an invocation of customer-onboarding.clearance — the two that advance the next review due beside no placement of their own, so the sum of the injected now and the monitoring interval may stand past the current placement's cover (Clock semantics 4).

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
Deleted: Identity 10. Recoverable Invocation Primitive policy 9 owns it.
Deleted: Identity 11. Recoverable Invocation Primitive policy 10 owns it.
Identity 12: An intent MUST carry the injected now as the pairing datum.
Deleted: Identity 13. Recoverable Invocation Primitive policy 11a owns it.
Deleted: Identity 14. Recoverable Invocation Primitive policy 5 and Recoverable Invocation Invariant 3.2 own it: a journal join pairs on the invocation id.
Deleted: Identity 15. Recoverable Invocation Invariant 3.2 and Recoverable Invocation act probe 3a own it.
Deleted: Identity 16. Recoverable Invocation Primitive policy 5 owns it: a journal join pairs on the invocation id and no other field.
Deleted: Identity 17. Recoverable Invocation journal 2 owns it: a trigger's intent is the adverse trigger kind's or the periodic review kind's own intended record.
Identity 18: A case MUST NOT identify a party.
Identity 19: A party id MUST NOT identify a case.
```

Term intent instant: the pairing datum an intent carries (Identity 12) — the invocation's now, which the host injects into Party Identity's and Retention Window's seams for the commit.

Term opening instant: the initiation's pairing datum, carried on the initiation outcome as the kind's instant (Action wiring 146).

Term trigger instant: a trigger intent's pairing datum (Action wiring 147).

Term suspension instant: an adverse trigger's pairing datum, carried on the suspension outcome — the suspend's state change instant (Action wiring 146).

Term renewal instant: a periodic review's pairing datum, carried on the renewal outcome — the renewed placement's retention instant (Action wiring 146).

Term clearance instant: a clearance's pairing datum, carried on the clearance outcome — the fresh verification's verification instant and the reinstate's state change instant (Action wiring 146).

Term closure instant: a closure's pairing datum, carried on the closure outcome — the close's state change instant (Action wiring 146).

Term intent: the record the invocation open writes before the commit, the one that verifies the caller's credential (Recoverable Invocation Primitive policy 19), carrying the invocation's parameters other than the credential, the case id, the pairing datum and no constituent-minted id — an initiation intent, a verification intent, a trigger intent, a clearance intent or a closure intent.

Term outcome: the record the invocation close writes after the commit, one Recoverable Invocation's sweep recovered under the recovery identity, or one an operator wrote through the invocation resolve — an initiation outcome, a verification outcome, a suspension outcome, a renewal outcome, a clearance outcome or a closure outcome.

Term refusal record: the kind's refused record the invocation refuse writes for a pre-commit arm, carrying the constituent's code (Recoverable Invocation refuse step 3.1).

Term initiation intent: the customer-onboarding.enrollment.intended record or the customer-onboarding.admission.intended record, by the path.

Term initiation outcome: the customer-onboarding.enrollment.initiated record or the customer-onboarding.admission.initiated record.

Term verification intent: the customer-onboarding.verification.intended record.

Term verification outcome: the customer-onboarding.verification.recorded record.

Term trigger intent: an adverse trigger intent OR a periodic review intent.

Term adverse trigger intent: the customer-onboarding.adverse-trigger.intended record.

Term periodic review intent: the customer-onboarding.periodic-review.intended record.

Term suspension outcome: the customer-onboarding.adverse-trigger.suspended record.

Term renewal outcome: the customer-onboarding.periodic-review.renewed record.

Term clearance intent: the customer-onboarding.clearance.intended record.

Term clearance outcome: the customer-onboarding.clearance.cleared record.

Term closure intent: the customer-onboarding.closure.intended record.

Term closure outcome: the customer-onboarding.closure.closed record.

Term recovery flag: Recoverable Invocation's recovery set to true — carried by an outcome its sweep wrote under the recovery identity or an operator wrote through the invocation resolve, and by no other (Recoverable Invocation Term recovery).

Term committing call: `PartyIdentity.enroll` | `PartyIdentity.verify` | `PartyIdentity.suspend` | `PartyIdentity.reinstate` | `PartyIdentity.close` | `RetentionWindow.place_under_retention` — a constituent call that writes outside the audit instance.

### Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Action wiring 4 and Recoverable Invocation Invariant 1.1 own it for the intent of the seven act kinds.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 19 owns it.
Deleted: Audit arm 3. Recoverable Invocation Primitive policy 41 owns it.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 23 owns it.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Deleted: Audit arm 6. Execution Contract Database 1 owns it.
Deleted: Audit arm 7. Recoverable Invocation Invariant 4.1 owns it: an intent stands open until a closing names its invocation, and the sweep closes it.
Deleted: Audit arm 8. Execution Contract Database 2 owns it.
Deleted: Audit arm 9. Recoverable Invocation Primitive policy 42 owns it.
Deleted: Audit arm 10. Recoverable Invocation Primitive policy 29 through 31 own it: an outcome that does not land answers recording-failure(outcome).
Deleted: Audit arm 11. Recoverable Invocation Invariant 8.3 owns it: recording-failure(intent) is a committed nothing, and the caller may retry.
Deleted: Audit arm 12. Recoverable Invocation Invariant 8.4 owns it: recording-failure(outcome) is an act that may exist, whose record the sweep closes.
Deleted: Audit arm 13. Recoverable Invocation Invariant 8.4 owns it: the caller does not re-run an act whose invocation is unclosed.
Deleted: Audit arm 14. Execution Contract Database 1 owns it.
Deleted: Audit arm 15. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an owed record.
Deleted: Audit arm 16. Recoverable Invocation reconcile step 3.2 and Execution Contract Database 1 own it.
Deleted: Audit arm 17. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an owed record.
Deleted: Audit arm 18. Execution Contract Database 1 owns it.
Audit arm 19: The composition MUST alert on EVERY recording-failure carrying outcome an acting action answers.
Deleted: Audit arm 20. Recoverable Invocation Primitive policy 41 through 43 own it: an invalid-request at the intent is the caller's, at the outcome a hard alert.
Deleted: Audit arm 21. Recoverable Invocation Primitive policy 40 and Recoverable Invocation Primitive policy 42 own it: the hard alert.
Deleted: Audit arm 22. Recoverable Invocation Invariant 5.2 owns it: a recovered outcome carries the recovery flag.
Deleted: Audit arm 23. Recoverable Invocation Invariant 5.2 owns it: a recovered outcome names the caller in the acting actor reference.
Deleted: Audit arm 24. Recoverable Invocation Primitive policy 20 through 22 and Recoverable Invocation Primitive policy 41 own it: an intent's invalid-request(step-4) is read back by invocation id, a found record proceeding with a hard alert and none answering invalid-request.
Deleted: Audit arm 25. Recoverable Invocation Primitive policy 43 owns it.
```

Term position: intent | outcome | refusal — Recoverable Invocation's (Recoverable Invocation Primitive policy 19 through 31): where a recording-failure of an acting action sat.

### Action wiring

```
initiate_onboarding(optional party_id, optional enrollment_fields, actor_ref, credential, retention_policy_ref)
  answers case_id | recording-failure(outcome, case_id)
  refuses invalid-request | invalid-credential | party-not-known | party-not-admissible(state) | already-onboarded | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | enrollment-failed(enrollment failure) | storage-failure | registry-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

record_verification(case_id, verifying_actor_ref, method, verification_result, evidence_ref, credential)
  answers recorded | recording-failure(outcome)
  refuses invalid-request | invalid-credential | not-known | not-active | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | already-closed | storage-failure | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

trigger_monitoring_review(case_id, trigger_type, trigger_ref, actor_ref, credential)
  answers recorded | recording-failure(outcome)
  refuses invalid-request | invalid-credential | not-known | not-active | not-verified(state) | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | already-suspended | storage-failure | registry-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

clear_review(case_id, verifying_actor_ref, method, evidence_ref, actor_ref, credential, reason)
  answers cleared | recording-failure(outcome)
  refuses invalid-request | invalid-credential | not-known | no-open-trigger | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | triggers-changed | verification-failed | already-closed | storage-failure | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

close_party(case_id, closing_actor_ref, reason, credential)
  answers closed | recording-failure(outcome)
  refuses invalid-request | invalid-credential | not-known | not-active | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | triggers-changed | storage-failure | registry-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

activity_permitted(party_id)
  answers permitted
  refuses not-known | not-verified(state) | state-unavailable
```

Term enrollment failure: invalid-request | storage-failure — Party Identity's enroll codes an initiation passes through.

```
Action wiring 1: [Initiate Onboarding] MUST answer invalid-request for a call carrying a party id AND enrollment fields.
Action wiring 2: [Initiate Onboarding] MUST answer invalid-request for a call carrying no party id AND no enrollment fields.
Action wiring 3: [Initiate Onboarding] MUST answer invalid-request for an unset monitoring interval.
Action wiring 4: An external path call MUST read the party through Party Identity's declared read.
Action wiring 5: IF no party EXISTS for the party id THEN [Initiate Onboarding] MUST answer party-not-known.
Deleted: Action wiring 154. Execution Contract Read 1 owns it.
Action wiring 6: IF the party's state IS NOT IN the admissible states THEN [Initiate Onboarding] MUST answer party-not-admissible carrying the state.
Action wiring 7: IF an active case EXISTS for the party THEN [Initiate Onboarding] MUST answer already-onboarded.
Action wiring 8: A validated initiation MUST call the invocation open with the path's act kind, the act key, the actor reference, the credential AND the intent data carrying the case id, the invocation's inputs, the next review due AND now as the pairing datum (Recoverable Invocation Action wiring 4).
Action wiring 9: A direct path initiation MUST NOT carry a party id on the initiation intent.
Action wiring 10: A direct path initiation MUST call Party Identity's enroll with the enrollment fields.
Action wiring 11: IF Party Identity answers invalid-request for an enroll THEN [Initiate Onboarding] MUST answer enrollment-failed carrying invalid-request.
Action wiring 12: IF Party Identity answers storage-failure for an enroll THEN [Initiate Onboarding] MUST answer enrollment-failed carrying storage-failure (Execution Contract Constituent failure 1).
Action wiring 13: An admitted initiation MUST call Retention Window's place_under_retention with the party id AND the retention policy reference.
Action wiring 14: An admitted initiation MUST NOT substitute the active relationship policy for the retention policy reference.
Action wiring 15: IF Retention Window answers invalid-policy for an initiation THEN [Initiate Onboarding] MUST answer invalid-request.
Action wiring 16: IF Retention Window answers policy-not-found for an initiation THEN [Initiate Onboarding] MUST answer invalid-request.
Action wiring 17: IF Retention Window answers storage-failure for an initiation THEN [Initiate Onboarding] MUST answer storage-failure (Execution Contract Constituent failure 1).
Action wiring 17a: IF Retention Window answers registry-unavailable for an initiation THEN [Initiate Onboarding] MUST answer registry-unavailable (Execution Contract Constituent failure 2).
Deleted: Action wiring 18. Execution Contract Database 1 owns it.
Action wiring 19: [Initiate Onboarding] MUST close a committed initiation through the invocation close naming the path's initiation outcome, the outcome carrying the party id, the current placement AND the opening instant (Recoverable Invocation commit 4).
Action wiring 20: An admitted initiation MUST answer the case id.
Action wiring 21: The composition MUST read the case-to-monitoring index at [Record Verification].
Action wiring 22: IF no case EXISTS for the case id THEN [Record Verification] MUST answer not-known.
Action wiring 23: IF the case's active flag EQUALS false THEN [Record Verification] MUST answer not-active.
Action wiring 24: A validated verification MUST call the invocation open with customer-onboarding.verification, the party id as the act key, the verifying actor reference, the credential AND the intent data carrying the case id, the invocation's inputs, the next review due AND now as the pairing datum.
Action wiring 25: An admitted verification MUST call Party Identity's verify with the party id, the verifying actor reference, the method, the verification result AND the evidence reference.
Action wiring 26: IF Party Identity answers already-closed for a verify THEN [Record Verification] MUST answer already-closed.
Action wiring 27: IF Party Identity answers not-known for a verify THEN [Record Verification] MUST answer not-known.
Action wiring 28: IF Party Identity answers storage-failure for a verify THEN [Record Verification] MUST answer storage-failure (Execution Contract Constituent failure 1).
Action wiring 29: [Record Verification] MUST close a committed verification through the invocation close naming the verification outcome, the outcome carrying the verification id, the state change id where one stands AND the verification result.
Action wiring 30: A verification intent MUST carry the next review due the invocation derives (Action wiring 153a, Action wiring 153b).
Action wiring 31: A verification outcome MUST NOT carry a next review due.
Action wiring 32: A transitioning verification MUST advance the next review due.
Action wiring 33: A verification carrying no state change id MUST NOT advance the next review due.
Deleted: Action wiring 34. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it: a close that does not land answers recording-failure(outcome).
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
Action wiring 45: A periodic trigger MUST NOT refuse a party's state ahead of the open.
Action wiring 46: A validated trigger MUST call the invocation open with customer-onboarding.adverse-trigger for an adverse trigger type AND customer-onboarding.periodic-review for the periodic trigger type, the party id as the act key, the actor reference, the credential AND the intent data carrying the case id, the enrollment path, the trigger id, the trigger type, the trigger ref AND now as the trigger instant, beside the fields Action wiring 47 and Action wiring 170 add.
Action wiring 47: An admitted periodic trigger against an unsuspended party MUST carry the next review due on the periodic review intent.
Action wiring 48: An admitted trigger against a suspended party MUST NOT carry a next review due on the trigger intent.
Action wiring 49: An adverse trigger MUST NOT carry a next review due on the trigger intent.
Deleted: Action wiring 50. Recoverable Invocation Primitive policy 23 owns it: a trigger intent that does not land answers recording-failure(intent).
Deleted: Action wiring 51. Recoverable Invocation Invariant 1.1 and Recoverable Invocation Action wiring 4 own it: no commit is issued ahead of a landed intent.
Action wiring 52: An adverse trigger MUST call Party Identity's suspend with the party id, the actor reference AND the composed suspend reason.
Action wiring 53: IF Party Identity answers already-suspended for a suspend THEN [Trigger Monitoring Review] MUST answer already-suspended.
Action wiring 54: IF an adverse trigger intent's refusal record carries already-suspended THEN the composition MUST add the trigger to the open-trigger set.
Action wiring 55: IF Party Identity refuses a suspend THEN the suspension transaction MUST commit no write AND [Trigger Monitoring Review] MUST close the pre-commit arm through the invocation refuse carrying the constituent's code (Recoverable Invocation commit 2, commit 3).
Action wiring 56: IF Party Identity refuses a suspend outside already-suspended THEN the invocation MUST NOT add the trigger to the open-trigger set.
Action wiring 57: IF Party Identity answers not-verifiable for a suspend THEN [Trigger Monitoring Review] MUST answer not-verified carrying unverified.
Action wiring 58: IF Party Identity answers already-closed for a suspend THEN [Trigger Monitoring Review] MUST answer not-verified carrying closed.
Action wiring 59: IF Party Identity answers not-known for a suspend THEN [Trigger Monitoring Review] MUST answer not-known.
Action wiring 60: IF Party Identity answers invalid-request for a suspend THEN [Trigger Monitoring Review] MUST answer invalid-request.
Action wiring 61: IF Party Identity answers storage-failure for a suspend THEN [Trigger Monitoring Review] MUST answer storage-failure (Execution Contract Constituent failure 1).
Deleted: Action wiring 62. Recoverable Invocation's refuse owns it: a refusal record that does not land answers recording-failure(refusal, constituent_code), and the sweep records the attempt.
Action wiring 63: [Trigger Monitoring Review] MUST close a suspending trigger through the invocation close naming the suspension outcome, the outcome carrying the state change id AND the suspension instant.
Action wiring 64: A suspending trigger MUST add the trigger to the open-trigger set ONLY AFTER the suspension outcome lands (Atomic writes 2), a close that does not land leaving the trigger to the rebuild, which selects the trigger's open intent (Composition state 31).
Deleted: Action wiring 65. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Action wiring 66: A periodic trigger MUST read the current placement's policy reference through Retention Window's declared read.
Action wiring 67: A periodic trigger MUST call Retention Window's place_under_retention with the party id AND the current placement's policy reference.
Action wiring 68: A periodic trigger MUST renew the placement whatever the party's state.
Action wiring 69: A periodic trigger MUST renew the placement whatever the current placement's remaining cover.
Action wiring 70: IF Retention Window answers storage-failure for a renewal THEN [Trigger Monitoring Review] MUST answer storage-failure (Execution Contract Constituent failure 1).
Action wiring 70a: IF Retention Window answers registry-unavailable for a renewal THEN [Trigger Monitoring Review] MUST answer registry-unavailable (Execution Contract Constituent failure 2).
Action wiring 71: IF Retention Window answers invalid-policy for a renewal THEN [Trigger Monitoring Review] MUST answer invalid-request.
Action wiring 72: IF Retention Window answers policy-not-found for a renewal THEN [Trigger Monitoring Review] MUST answer invalid-request.
Action wiring 73: [Trigger Monitoring Review] MUST close a renewing trigger through the invocation close naming the renewal outcome, the outcome carrying the renewed placement AND the renewal instant.
Deleted: Action wiring 74. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Action wiring 75: A renewing trigger MUST repoint the case-to-retentions index ONLY AFTER the renewal outcome lands.
Action wiring 76: A renewing trigger against an unsuspended party MUST advance the next review due.
Action wiring 76a: A periodic trigger that IS NOT a renewing trigger MUST NOT advance the next review due.
Action wiring 77: A periodic trigger against a suspended party MUST NOT advance the next review due.
Deleted: Action wiring 78. Term renewal probe owns it: a renewal is recovered on the act key and the pairing datum.
Action wiring 79: An admitted trigger MUST answer recorded.
```

NOTE: open 2026-11-11-f — a refused renewal leaves the next review due where it stood (Action wiring 76, Action wiring 76a), so the scheduler fires the review again at its next pass (Capability requirement 40a), and no rule bounds how often a registry fault is retried.

```
Action wiring 80: The composition MUST read the case-to-monitoring index at [Clear Review].
Action wiring 81: IF no case EXISTS for the case id THEN [Clear Review] MUST answer not-known.
Action wiring 82: IF the open-trigger set stands empty THEN [Clear Review] MUST answer no-open-trigger.
Action wiring 83: A validated clearance MUST call the invocation open with customer-onboarding.clearance, the party id as the act key, the actor reference, the credential AND the intent data carrying the case id, the invocation's inputs, the open-trigger set as the closed triggers, the next review due AND now as the pairing datum.
Action wiring 84: An admitted clearance MUST call Party Identity's verify with the party id, the verifying actor reference, the method, passed AND the evidence reference.
Action wiring 85: An admitted clearance MUST NOT call Party Identity's verify with failed.
Action wiring 86: IF Party Identity answers already-closed for a clearance verify THEN [Clear Review] MUST answer already-closed.
Action wiring 87: IF Party Identity answers not-known for a clearance verify THEN [Clear Review] MUST answer not-known.
Action wiring 88: IF Party Identity answers invalid-request for a clearance verify THEN [Clear Review] MUST answer invalid-request.
Action wiring 89: IF Party Identity answers storage-failure for a clearance verify THEN [Clear Review] MUST answer storage-failure (Execution Contract Constituent failure 1).
Action wiring 90: [Clear Review] MUST close a committed clearance through the invocation close naming the clearance outcome, the outcome carrying the verification id, the state change id, the reason AND the clearance instant.
Deleted: Action wiring 91. Action wiring 83 owns it: the next review due rides the clearance intent, and the clearance outcome carries none.
Deleted: Action wiring 92. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Deleted: Action wiring 93. Term clearance transaction owns it: the verify and the reinstate commit together, and no record stands between them (Recoverable Invocation Action wiring 6).
Deleted: Action wiring 94. Term clearance transaction owns it: the verify and the reinstate commit together, and no record stands between them (Recoverable Invocation Action wiring 6).
Action wiring 95: An admitted clearance MUST call Party Identity's reinstate with the party id, the actor reference AND the reason.
Action wiring 96: IF Party Identity answers no-passed-verification-since-suspend for a reinstate THEN [Clear Review] MUST answer verification-failed.
Action wiring 97: IF Party Identity answers not-suspended for a reinstate THEN [Clear Review] MUST answer verification-failed.
Action wiring 98: IF Party Identity answers already-closed for a reinstate THEN [Clear Review] MUST answer already-closed.
Action wiring 99: IF Party Identity answers not-known for a reinstate THEN [Clear Review] MUST answer not-known.
Action wiring 100: IF Party Identity answers invalid-request for a reinstate THEN [Clear Review] MUST answer invalid-request.
Deleted: Action wiring 101. Execution Contract Database 1 owns it.
Deleted: Action wiring 102. Action wiring 90 owns it: the clearance's one outcome carries the reinstate's state change id.
Deleted: Action wiring 103. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Action wiring 104: An admitted clearance MUST drop the closed triggers from the open-trigger set ONLY AFTER the clearance outcome lands.
Action wiring 105: An admitted clearance MUST drop exactly the closed triggers the clearance intent names.
Action wiring 106: An admitted clearance MUST NOT drop a trigger the clearance intent does not name.
Action wiring 107: An admitted clearance MUST advance the next review due to the clearance intent's next review due.
Deleted: Action wiring 108. Execution Contract Database 1 owns it.
Deleted: Action wiring 109. Execution Contract Database 1 owns it.
Deleted: Action wiring 110. Execution Contract Database 1 and Execution Contract Database 3 own it.
Action wiring 111: An admitted clearance MUST answer cleared.
Action wiring 112: The composition MUST read the case-to-monitoring index at [Close Party].
Action wiring 113: IF no case EXISTS for the case id THEN [Close Party] MUST answer not-known.
Action wiring 114: IF the case's active flag EQUALS false THEN [Close Party] MUST answer not-active.
Action wiring 115: A validated closure MUST call the invocation open with customer-onboarding.closure, the party id as the act key, the closing actor reference, the credential AND the intent data carrying the case id, the reason, the open-trigger set as the open triggers at close AND now as the pairing datum.
Action wiring 116: An admitted closure MUST call Party Identity's close with the party id, the closing actor reference AND the reason.
Deleted: Action wiring 117. Recoverable Invocation reconcile step 3.2 and Execution Contract Database 1 own it.
Deleted: Action wiring 118. Execution Contract Database 1 owns it: a closure's close, floor and record commit together, so no invocation completes an earlier closure.
Action wiring 119: IF Party Identity answers already-closed for a close THEN [Close Party] MUST answer not-active.
Deleted: Action wiring 119a. Recoverable Invocation open step 3.5 owns it: an earlier closure whose outcome has not landed is an open closure intent, so a second closure meets act-in-flight while the first is in flight, and the second's close answers already-closed once the first committed (Action wiring 119).
Action wiring 120: IF Party Identity answers not-known for a close THEN [Close Party] MUST answer not-known.
Action wiring 121: IF Party Identity answers invalid-request for a close THEN [Close Party] MUST answer invalid-request.
Action wiring 122: IF Party Identity answers storage-failure for a close THEN [Close Party] MUST answer storage-failure (Execution Contract Constituent failure 1).
Action wiring 123: An admitted closure MUST call Retention Window's place_under_retention with the party id AND the post closure policy.
Action wiring 124: IF Retention Window answers invalid-policy for a closure THEN [Close Party] MUST answer invalid-request.
Action wiring 125: IF Retention Window answers policy-not-found for a closure THEN [Close Party] MUST answer invalid-request.
Action wiring 125a: IF Retention Window answers storage-failure for a closure THEN [Close Party] MUST answer storage-failure (Execution Contract Constituent failure 1).
Action wiring 125b: IF Retention Window answers registry-unavailable for a closure THEN [Close Party] MUST answer registry-unavailable (Execution Contract Constituent failure 2).
Deleted: Action wiring 126. Execution Contract Database 1 owns it.
Action wiring 127: [Close Party] MUST close a committing closure through the invocation close naming the closure outcome, the outcome carrying the state change id, the post closure placement, the reason AND the closure instant.
Deleted: Action wiring 128. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Action wiring 129: An admitted closure MUST populate the case-to-retentions index's post closure placement ONLY AFTER the closure outcome lands.
Action wiring 130: An admitted closure MUST write the case's active flag set to false ONLY AFTER the closure outcome lands.
Action wiring 131: An admitted closure MUST empty the open-trigger set ONLY AFTER the closure outcome lands.
Action wiring 132: An admitted closure MUST answer closed.
Deleted: Action wiring 133. Execution Contract Database 1 owns it.
Action wiring 134: The composition MUST read the party-to-case index at [Activity Permitted].
Action wiring 135: IF the party id IS NOT IN the party-to-case index THEN [Activity Permitted] MUST answer not-known.
Action wiring 136: The composition MUST read the party through Party Identity's declared read at [Activity Permitted].
Action wiring 136a: IF Party Identity's read at [Activity Permitted] answers invalid-query THEN [Activity Permitted] MUST answer state-unavailable, read as the composition's own defect (Action wiring 43).
Action wiring 137: IF the party's state EQUALS verified THEN [Activity Permitted] MUST answer permitted.
Action wiring 138: IF the party's state DOES NOT EQUAL verified THEN [Activity Permitted] MUST answer not-verified carrying the state.
Deleted: Action wiring 139. Execution Contract Read 1 owns it.
Action wiring 140: IF the read answers no party THEN [Activity Permitted] MUST answer state-unavailable.
Deleted: Action wiring 141. Execution Contract Read 1 and Execution Contract Read 2 own it.
Action wiring 142: [Activity Permitted] MUST NOT write.
Action wiring 143: [Activity Permitted] MUST NOT record an audit event.
Action wiring 144: [Activity Permitted] MUST NOT read a clock.
Action wiring 145: [Activity Permitted] MUST NOT compare a timestamp.
Action wiring 155: IF a call of an acting action's commit answers an arm of the pre-commit partition THEN the commit MUST commit no write AND the action MUST close the pre-commit arm through the invocation refuse carrying the constituent's code (Recoverable Invocation commit 2, commit 3).
Action wiring 156: IF a call of an acting action's commit answers an arm of the unknown partition THEN the action MUST call the invocation yield AND answer recording-failure carrying outcome (Recoverable Invocation commit 8).
Action wiring 157: IF the invocation open, refuse OR close answers a code of Recoverable Invocation's Action wiring table THEN the action MUST answer that code.
Action wiring 158: IF [Initiate Onboarding] answers recording-failure carrying outcome THEN the answer MUST carry the case id.
Action wiring 159: An admission transaction MUST NOT call Retention Window's place_under_retention BEFORE re-reading the party's state AND the party's active case inside the transaction.
Action wiring 160: IF the re-read party's state IS NOT IN the admissible states THEN the admission transaction MUST commit no write AND [Initiate Onboarding] MUST close the pre-commit arm through the invocation refuse AND answer party-not-admissible carrying the state.
Action wiring 161: IF the re-read finds an active case for the party THEN the admission transaction MUST commit no write AND [Initiate Onboarding] MUST close the pre-commit arm through the invocation refuse AND answer already-onboarded.
Action wiring 162: A suspension transaction MUST NOT call Party Identity's suspend BEFORE re-reading the party's state inside the transaction.
Action wiring 163: IF the re-read party's state IS NOT IN the suspendable states THEN the suspension transaction MUST commit no write AND [Trigger Monitoring Review] MUST close the pre-commit arm through the invocation refuse AND answer not-verified carrying the state.
Action wiring 164: A clearance transaction MUST NOT call Party Identity's verify BEFORE re-reading the case's open triggers AND the case's adverse trigger intents inside the transaction.
Action wiring 165: IF the re-read open-trigger set DOES NOT EQUAL the clearance intent's closed triggers OR a re-read adverse trigger intent carries no closing THEN the clearance transaction MUST commit no write AND [Clear Review] MUST close the pre-commit arm through the invocation refuse AND answer triggers-changed.
Action wiring 166: A closure transaction MUST NOT call Party Identity's close BEFORE re-reading the case's open triggers inside the transaction.
Action wiring 167: IF the re-read open-trigger set DOES NOT EQUAL the closure intent's open triggers at close THEN the closure transaction MUST commit no write AND [Close Party] MUST close the pre-commit arm through the invocation refuse AND answer triggers-changed.
Action wiring 168: A renewal transaction MUST NOT call Retention Window's place_under_retention BEFORE re-reading the party's state inside the transaction.
Action wiring 169: IF the re-read party's state EQUALS closed THEN the renewal transaction MUST commit no write AND [Trigger Monitoring Review] MUST close the pre-commit arm through the invocation refuse AND answer not-active.
Action wiring 170: A periodic review intent MUST carry the prior placement AND the prior placement's policy reference.
Action wiring 171: The composition MUST read a re-read's active case AND open triggers from the composition's own Audit Trail events inside the commit's transaction (Execution Contract Database 2).
Action wiring 172: IF a read the action makes answers state-unavailable THEN the action MUST answer state-unavailable PER Execution Contract Read 1.
```

NOTE: open 2026-11-10-d — Action wiring 171 reads the trail inside an adopter's commit transaction, which the 2026-10-20 decision's one database permits under Execution Contract Database 2 and no other adopter of Recoverable Invocation has done; the alternative is the open-trigger index under rebuild on miss (Composition state 9), which stands outside every action's transaction (Composition state 7).

Term party state: [Party Identity](../atoms/party-identity.md)'s declared lifecycle states, cited rather than restated.

Term admissible states: unverified — the one party state an external path initiation admits.

Term suspendable states: verified | suspended — the party states an adverse trigger's suspend may reach.

Term validated initiation: an [Initiate Onboarding] call whose boundary predicate passed and whose party stands admissible.

Term admitted initiation: a validated initiation for which the invocation open returned an intent event id.

Term validated verification: a [Record Verification] call whose boundary predicate passed and whose case's active flag EQUALS true.

Term admitted verification: a validated verification for which the invocation open returned an intent event id.

Term validated trigger: a [Trigger Monitoring Review] call whose boundary predicate passed, whose case's active flag EQUALS true and whose pre-check admitted the trigger type against the party's state.

Term admitted trigger: a validated trigger for which the invocation open returned an intent event id.

Term validated clearance: a [Clear Review] call whose boundary predicate passed and whose case carries an open trigger.

Term admitted clearance: a validated clearance for which the invocation open returned an intent event id.

Term validated closure: a [Close Party] call whose boundary predicate passed and whose case's active flag EQUALS true.

Term admitted closure: a validated closure for which the invocation open returned an intent event id.

Term transitioning verification: an admitted verification Party Identity answered with a state change id.

Term adverse trigger: an admitted trigger whose trigger type belongs to the adverse trigger types.

Term periodic trigger: an admitted trigger whose trigger type EQUALS the periodic trigger type.

Term suspending trigger: an adverse trigger whose suspension transaction committed.

Term renewing trigger: a periodic trigger whose renewal transaction committed.

Term committing closure: an admitted closure whose closure transaction committed.

Term composed suspend reason: `"monitoring-trigger:" + trigger_type + ":" + trigger_ref` — the reason an adverse trigger passes to Party Identity's suspend.

Term closed triggers: the trigger ids a clearance intent names as resolved by the clearance.

Term open triggers at close: the trigger ids a closure intent names as closed-unresolved at the relationship's end.

Term prior placement: the current placement a renewal supersedes, carried on the periodic review intent (Action wiring 170).

Term kind's instant: the opening instant for an initiation outcome, the suspension instant for a suspension outcome, the renewal instant for a renewal outcome, the clearance instant for a clearance outcome, the closure instant for a closure outcome; a verification outcome carries none of its own, the verification instant being Party Identity's.

Term renewed placement: the placement a renewal makes, which becomes the case's current placement once the renewal outcome lands.

```
Action wiring 146: An outcome MUST carry the intent's pairing datum as the kind's instant.
Action wiring 147: A trigger intent MUST carry the injected now as the trigger instant AND as the pairing datum.
Deleted: Action wiring 148. Action wiring 146 owns it.
Deleted: Action wiring 149. Action wiring 146 owns it.
Deleted: Action wiring 150. Action wiring 146 owns it.
Deleted: Action wiring 151. Action wiring 146 and Action wiring 90 own it: the clearance's one outcome carries the clearance instant, the reinstate's state change instant.
Deleted: Action wiring 152. Action wiring 146 owns it.
Action wiring 153: IF an invocation that carries a next review due IS NOT IN the cover-bound invocations THEN the invocation MUST derive the next review due as the injected now plus the monitoring interval.
Action wiring 153a: IF an invocation IS IN the cover-bound invocations AND the injected now plus the monitoring interval PRECEDES the current placement's cover THEN the invocation MUST derive the next review due as that sum.
Action wiring 153b: IF an invocation IS IN the cover-bound invocations AND the injected now plus the monitoring interval DOES NOT PRECEDE the current placement's cover THEN the invocation MUST carry the entry's standing next review due.
```

#### Closure table

Every input an action takes, and every answer a call of the six actions and of the reconciliation can meet — Party Identity's enroll, verify, suspend, reinstate, close and read, Retention Window's place_under_retention and read, Audit Trail's read_record and range read, and Recoverable Invocation's open, close, refuse and yield — with where the call lands it and the rule that owns the landing. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here. The five acting actions are Recoverable Invocation's: the intent commits at the open, ahead of the commit (Execution Contract Constituent failure 1), the commit is the kind's transaction, and the outcome lands at the close, so open, commit and close are three commits and not one transaction (Non-goal 22; Recoverable Invocation Non-goal 1); an act whose outcome never lands is the sweep's, closed within its closure window (Recoverable Invocation reconcile). Inside a commit, every write commits together or not at all (Execution Contract Database 1), so a refusal inside it writes nothing but the refusal record the refuse lands (Recoverable Invocation commit 3); where two refusals of one action apply to one call, the one listed first on its refuses line answers (Execution Contract Refusal 1). The enumeration is exhaustive: an answer a constituent adds is a row this table lacks, and a cell no rule owns is a finding against the page.

**Inputs, ahead of the open.**

| Action | Input | Lands | Owner |
|---|---|---|---|
| every acting action | a blank opaque input, actor reference, method, evidence reference, reason or retention policy reference; a trigger type outside the trigger vocabulary; a verification result outside the verification results; a composed suspend reason over Party Identity's reason cap; a probe-matched field over its field cap | invalid-request, nothing written and no constituent called | Primitive policy 1 through 9, 14, 21, 22 |
| [Initiate Onboarding] | a party id and enrollment fields both, or neither; an unset monitoring interval | invalid-request, nothing written | Action wiring 1 through 3 |
| [Initiate Onboarding], external path | a party id Party Identity holds no party for; a party outside the admissible states; a party with an active case | party-not-known, party-not-admissible carrying the state, already-onboarded, ahead of the open | Action wiring 5 through 7 |
| [Record Verification], [Trigger Monitoring Review], [Clear Review], [Close Party] | a case id the case-to-monitoring index names no case for, a missing entry rebuilt first | not-known, ahead of the open | Action wiring 22, 38, 81, 113, Composition state 9 |
| [Record Verification], [Trigger Monitoring Review], [Close Party] | a case whose active flag is false | not-active, ahead of the open | Action wiring 23, 39, 114 |
| [Trigger Monitoring Review] | an adverse trigger type against a party outside the suspendable states; Party Identity's read answering invalid-query | not-verified carrying the state; invalid-request, read as the composition's defect | Action wiring 42 through 44 |
| [Clear Review] | a case whose open-trigger set is empty | no-open-trigger, ahead of the open, the credential never validated | Action wiring 82 |
| every acting action | an intent whose data exceeds Audit Trail's payload cap, the trigger sets in full included | invalid-request at the open, nothing written | Recoverable Invocation Primitive policy 12, 13 |
| every acting action | the credential | consumed by the invocation open's intent record alone | Composes 15, Recoverable Invocation Primitive policy 6 |

**Recoverable Invocation: the open, the close, the refuse and the yield**, at the five acting actions.

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the open | an intent event id | the commit | Action wiring 8, 24, 46, 83, 115 |
| the open | invalid-credential, invalid-request, act-in-flight, section-unavailable, journal-unavailable, recording-failure(intent) | the same code, nothing committed | Action wiring 157, Recoverable Invocation Action wiring table |
| the open | act-landed | never: every kind is repeatable | Recoverable Invocation repeatable 1, Term onboarding bindings |
| the open | recording-failure(outcome) | the same code, at [Initiate Onboarding] carrying the case id; the commit is never issued and the open intent is the sweep's, which finds nothing and escalates it | Action wiring 157, 158 |
| the close | an event id | the index population after it, then the action's answer | Action wiring 20, 35, 64, 75, 79, 104, 111, 129 through 132 |
| the close | recording-failure(outcome) | recording-failure(outcome), the act committed and its record the sweep's; at [Initiate Onboarding] carrying the case id; alerted | Action wiring 157, 158, Audit arm 19 |
| the refuse | an event id | the constituent's own code, or this page's name for it, the attempt recorded | Action wiring 11, 12, 15 through 17a, 26 through 28, 53, 55, 57 through 61, 70 through 72, 86 through 89, 96 through 100, 119 through 125b, 155, 160, 161, 163, 165, 167, 169 |
| the refuse | already-accounted or recording-failure(refusal, constituent_code) | that code; the sweep records the attempt where the refusal did not land | Action wiring 157 |
| the yield | its return | recording-failure(outcome), the act possibly committed and its record the sweep's; alerted | Action wiring 156, 158, Audit arm 19 |

**Party Identity and Retention Window, inside a commit.** A storage-failure or registry-unavailable from any of these calls, or a state-unavailable from the database, is a pre-commit arm: the commit writes nothing and the refuse lands the refusal record (Action wiring 155, Execution Contract Constituent failure 1 through 3). A call with no answer, or with an answer its constituent does not declare, is the unknown partition, closed through the yield (Action wiring 156, Term commit partition). The other answers:

| Call | Answer | Lands | Owner |
|---|---|---|---|
| enroll | a party id | the placement over it | Action wiring 10, 13 |
| enroll | invalid-request | enrollment-failed carrying invalid-request, refused | Action wiring 11, 155 |
| place_under_retention, at an initiation, a renewal or a closure | a retention id | the close | Action wiring 19, 73, 127 |
| place_under_retention | invalid-policy or policy-not-found | invalid-request, refused | Action wiring 15, 16, 71, 72, 124, 125, 155 |
| the admission transaction's re-read | an unverified party with no active case | the placement | Action wiring 159 |
| the admission transaction's re-read | another state, or an active case | party-not-admissible carrying the state, or already-onboarded, refused | Action wiring 160, 161 |
| verify, at [Record Verification] | a verification id, with or without a state change id | the close | Action wiring 29 |
| verify | already-closed, not-known or invalid-request | that code, refused | Action wiring 26, 27, 155, Primitive policy 15 |
| the suspension transaction's re-read | verified or suspended | the suspend | Action wiring 162 |
| the suspension transaction's re-read | unverified or closed | not-verified carrying the state, refused | Action wiring 163 |
| suspend | a state change id | the close | Action wiring 63 |
| suspend | already-suspended | already-suspended, refused; the trigger enters the open-trigger set | Action wiring 53, 54, 55 |
| suspend | not-verifiable, already-closed, not-known or invalid-request | not-verified carrying unverified or closed, not-known or invalid-request, refused; the trigger does not enter the set | Action wiring 55 through 60 |
| the renewal transaction's re-read | a state other than closed | the placement | Action wiring 168 |
| the renewal transaction's re-read | closed | not-active, refused | Action wiring 169 |
| the clearance or closure transaction's re-read | the intent's set | the verify, or the close | Action wiring 164, 166 |
| the clearance or closure transaction's re-read | another set, or at the clearance an adverse trigger intent carrying no closing | triggers-changed, refused | Action wiring 165, 167 |
| verify, at [Clear Review] | a verification id | the reinstate | Action wiring 95 |
| verify, at [Clear Review] | already-closed, not-known or invalid-request | that code, refused | Action wiring 86 through 88 |
| reinstate | a state change id | the close | Action wiring 90 |
| reinstate | no-passed-verification-since-suspend or not-suspended | verification-failed, refused, the verify rolled back with it | Action wiring 96, 97, 155 |
| reinstate | already-closed, not-known or invalid-request | that code, refused, the verify rolled back | Action wiring 98 through 100, 155 |
| close | a state change id | the post closure placement | Action wiring 123 |
| close | already-closed | not-active, refused | Action wiring 119 |
| close | not-known or invalid-request | that code, refused | Action wiring 120, 121 |

**Audit Trail and the database: the reads.** Inside an action, a read that fails passes through unchanged and writes nothing (Action wiring 172, Execution Contract Read 1 through 3), and a read with no answer leaves the action none to give (Execution Contract Error model 1). Party Identity's read at [Activity Permitted] answering no party lands state-unavailable (Action wiring 140). A rebuild's range read and read_record land as Composition state 15 through 22 say; an aged-out event is read by its action reference alone.

**The composition's own records.** The four indexes stand outside every action's transaction (Composition state 7) and populate after the closing that backs them (Composition state 35, Atomic writes 2); a record the sweep or an operator wrote reaches them only through a rebuild.

**The leg.** It answers no caller, and decides only on an answered read (Reconciliation 40): a Party Identity, Retention Window or Audit Trail read that fails or gives no answer decides nothing, and the record is examined again at the next run (Reconciliation 2). It opens findings and alerts; it writes no outcome, which is the sweep's under the recovery identity, and calls no constituent's write (Reconciliation 42).

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

<details markdown="block">
<summary>WHY</summary>

*Principle.* BSA/AML and FATF Recommendations 10–12 require that Customer Due Diligence be completed before a business relationship's regulated activity begins. Structurally that means no account opening, no transaction and no service provisioning proceeds for a party outside a substantiated `Verified` state, and the system makes both provable: that the party was verified, and that no activity preceded the verification.

*Likely objection.* Party Identity already owns the `Verified` state and already refuses a reinstatement without a passed verification after the most recent suspend. Why not have each activity system read Party Identity's state directly? The atom already enforces the substance of the gate.

*Mechanism that resolves it.* Party Identity owns the state and exposes no gate: it records that a party is Verified, does not enforce that activity systems consult it, and does not know what regulated activity means — importing that notion would break the atom's freestanding status, which is what Wiring decision 6 and Wiring decision 7 refuse. The Audit Trail substrate records attributed, tamper-evident events and does not know which of them constitute a verification chain. Neither can, alone, deliver both halves of the obligation. The composition wires them: every `Unverified → Verified` transition flows through [Record Verification], which records an event carrying both the `verification_id` and the `state_change_id`, so the verification is attributed and tamper-evident (Invariant 2.1); and [Activity Permitted] is the *single* gate query, so the precondition is implemented exactly once at the composition boundary rather than re-implemented — or quietly skipped — in each activity system. Wiring decision 2 is the half a reader most often misses: the gate consults this composition's own case index as well as the party's state, so a party driven to `Verified` outside this composition has no case entry and fails the gate. The attribution half is delivered by Invariant 2.1 together with the exclusive-ownership obligation of Composes 19 and Composes 20, not by the state read; the gate's own job is to confine permitted to the `Verified` parties this composition governs.

*Result.* The gate is structural and centralized. It is provable to an auditor that for every party with regulated activity a verification record carrying a `state_change_id` precedes the activity inside the audit horizon (Check 1.1), and that no activity system held its own copy of the gate logic to drift from. The single-surface discipline is what makes it provable: the verification precondition lives in one place, is exercised through one query, and produces one tamper-evident event class the auditor reads.

</details>

### Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Reconciliation 2: The reconciliation MUST run every sweep cadence.
Deleted: Reconciliation 3. Recoverable Invocation reconcile step 1.1 owns it: the sweep selects every open intent of the act kinds.
Deleted: Reconciliation 4. Execution Contract Database 1 owns it.
Reconciliation 5: The reconciliation MUST NOT examine an aged record.
Deleted: Reconciliation 6. Recoverable Invocation reconcile step 3.1 and the act probes own it: the sweep runs the kind's act probe against Party Identity's and Retention Window's declared reads (Recoverable Invocation Sweep never 3).
Deleted: Reconciliation 7. Recoverable Invocation reconcile step 3.5 owns it: an intent whose invocation died before its commit is escalated, and an operator who finds the constituents quiet abandons it through the invocation resolve (Recoverable Invocation Invariant 4.9).
Deleted: Reconciliation 8. Recoverable Invocation reconcile step 3.2 owns it: a committed probe answer is closed by the recovered outcome.
Deleted: Reconciliation 9. Recoverable Invocation Invariant 5.1 and Recoverable Invocation reconcile step 3.2a own it: the recovery intent before any recovered outcome.
Deleted: Reconciliation 10. Recoverable Invocation reconcile step 2.4 through 2.6 own it: the sweep re-reads the invocation's closings under the critical section before it writes.
Deleted: Reconciliation 11. Recoverable Invocation reconcile step 3.2a, Recoverable Invocation reconcile step 3.2b, Recoverable Invocation Invariant 5.2 and Recoverable Invocation service identity 3 own it: the sweep writes under the recovery identity.
Deleted: Reconciliation 12. Execution Contract Database 1 owns it.
Deleted: Reconciliation 13. Execution Contract Database 1 owns it.
Deleted: Reconciliation 14. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it: neither the sweep nor the reconciliation calls a constituent's write.
Deleted: Reconciliation 15. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it.
Deleted: Reconciliation 16. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it.
Deleted: Reconciliation 17. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it.
Deleted: Reconciliation 18. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it.
Deleted: Reconciliation 19. Recoverable Invocation Invariant 4.2 and Recoverable Invocation Instance start 4 own it: an open intent is closed within the closure window.
Deleted: Reconciliation 20. Recoverable Invocation reconcile step 3.5, Recoverable Invocation reconcile step 3.8 and Recoverable Invocation reconcile step 5.1 own it: an intent the sweep cannot close is escalated once and reported at risk.
Deleted: Reconciliation 21. Execution Contract Database 1 owns it.
Reconciliation 22: The reconciliation MUST alert on an active case carrying an elapsed placement.
Reconciliation 23: The reconciliation MUST alert on a suspended party under an active case carrying an empty open-trigger set.
Deleted: Reconciliation 24. Recoverable Invocation Invariant 4.1, Recoverable Invocation reconcile step 3.5 and Recoverable Invocation reconcile step 3.21 own it: a trigger intent carrying no closing stands open until the sweep closes or escalates it.
Reconciliation 25: The reconciliation MUST alert on a verified party under an active case carrying no transitioning verification standing an aged record, no verification outcome naming a state change id AND no open intent of customer-onboarding.verification.
Deleted: Reconciliation 26. Execution Contract Database 2 owns it.
Deleted: Reconciliation 27. Term verification probe and Recoverable Invocation Invariant 3.3 own it: the probe pairs on the act key and the pairing datum by equality.
Deleted: Reconciliation 28. Term admission probe, Term renewal probe and Recoverable Invocation Invariant 3.3 own it.
Deleted: Reconciliation 29. Term enrollment probe and Recoverable Invocation Deviation 4b own it, reversed: the probe finds the minted party through Party Identity's enrollment instant range.
Deleted: Reconciliation 30. Recoverable Invocation reconcile step 3.5 and Recoverable Invocation reconcile step 3.8 own it: what the enrollment probe cannot decide is escalated.
Deleted: Reconciliation 31. Recoverable Invocation Invariant 3.2 and Recoverable Invocation act probe 3a own it.
Deleted: Reconciliation 32. Term reconciliation owns it: the reconciliation runs inside the sweep's run, which answers its tally to its starter alone.
Deleted: Reconciliation 33. Execution Contract Scheduled leg 1 owns it.
Reconciliation 34: The reconciliation MUST NOT examine a young record.
Reconciliation 35: The reconciliation MUST read the sweep's run reading of now AND MUST NOT read now at a seam of the reconciliation.
NOTE: watch the sweep's run reading (Reconciliation 35).
Reconciliation 36: The reconciliation MUST take the enumeration of Reconciliation 37 once PER run, at the run's start.
Reconciliation 37: The reconciliation MUST read EVERY verification event, state change event AND placement over an active case's party that Reconciliation 5, Reconciliation 34 AND Reconciliation 41 admit, against the intents.
Reconciliation 38: IF a record Reconciliation 37 reads IS NOT a carried record THEN the reconciliation MUST open a write-ownership finding for the record.
Reconciliation 39: The reconciliation MUST alert the finding surface carrying the record's id for EVERY false closing Reconciliation 37 reads.
Reconciliation 40: The reconciliation MUST decide ONLY on an answered read.
Reconciliation 41: The reconciliation MUST NOT examine a record whose instant PRECEDES the cut-over instant.
Reconciliation 42: The reconciliation MUST NOT call a constituent's write.
Reconciliation 43: The reconciliation MUST alert on a quiescent verified party under an active case carrying a non-empty open-trigger set.
```

Term reconciliation: the leg the composition runs outside every invocation, beside Recoverable Invocation's sweep and inside its run — the reading of the placements and of Party Identity's verification and state change events over the active cases' parties against the intents, with the lapse and suspension alerts, whose output, an alert or a write-ownership finding, an auditor awaits at the sweep cadence and within no window of its own.

Term elapsed placement: a placement whose retention deadline does not exceed the injected now.

Term carried record: a verification event, a state change event or a placement over a case's party that an intent of a kind whose commit writes such a record carries — an intent whose act key is the party id, or for an enrollment the enrollment key whose fields the party record carries, and whose pairing datum EQUALS the record's verification instant or state change instant, or the record's retention instant rounded as Retention Window rounds it.

Term carrying intent: the intent that makes a record a carried record — one at most over a verification event or a state change event, an equal now never reaching two invocations of one act key (Capability requirement 49), and over a placement every intent that makes it one, of which one resolution step of Retention Window holding two placements over the party gives two.

Term young record: a record whose instant stands within the examine window end of the act kind that writes it, measured back from the sweep's now — a record whose invocation the sweep may still be closing (Recoverable Invocation Term examine window end).

Term aged record: a record for which the sweep's now DOES NOT PRECEDE `(((instant + audit horizon) - (2 * clock offset allowance)) - reconciliation run bound)` — a record whose intent the audit horizon may have destroyed, which the reconciliation would read as no intent.

Term write-ownership finding: a finding that a verification event, a state change event or a placement over a case's party is no carried record — a write against Party Identity or the party retention instance outside the composition's surface (Composes 20, Non-goal 20).

Term false closing: a carried record one intent carries whose carrying intent an abandonment or a refusal closed — an act that committed, read as one that did not.

Term finding surface: the deployment's compliance surface — the surface Recoverable Invocation's instance writes its register to. A write-ownership finding and this page's alerts are written beside that register and are no part of it (Recoverable Invocation findings 6).

---

## Composition-level invariants

```
Invariant 1.1: [Activity Permitted] MUST answer permitted ONLY IF the party-to-case index names the party AND Party Identity reports the party verified.
Invariant 1.2: [Activity Permitted] MUST answer permitted for a party the party-to-case index names AND Party Identity reports verified.
Invariant 1.3: A party MUST reach regulated activity ONLY IF [Activity Permitted] answers permitted.
Invariant 2.1: A transitioning verification MUST carry EXACTLY ONE OF a verification outcome naming the verification id and the state change id, an open carrying intent, an escalated carrying intent, a false closing alert, a write-ownership finding.
Invariant 2.2: A verification outcome MUST stand under a seal PER Audit Trail's seal cadence.
Invariant 2.3: A quiescent verified party MUST carry a verification outcome.
Deleted: Invariant 2.4. Recoverable Invocation Invariant 4.2 owns it: an open verification intent is closed within the closure window.
Invariant 3.1: A suspension outcome MUST stand later in the log than the outcome's adverse trigger intent.
Invariant 3.2: A refusal record carrying already-suspended MUST stand later in the log than the record's adverse trigger intent.
Invariant 3.3: A reader MUST read later in the log as the Event Log's insertion order.
Invariant 3.4: A reader MUST NOT read later in the log as a timestamp difference.
Invariant 4.1: A reinstated party MUST carry a passed verification standing later in the log than the party's most recent suspension.
Invariant 4.2: A reinstated party MUST carry a clearance outcome naming the verification id.
Invariant 4.3: A clearance intent MUST stand attested under the clearing actor's credential AND name the fresh evidence.
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
Deleted: Invariant 7.3. Term clearance transaction owns it: the verify and the reinstate commit together, so no clearance window stands for a verified party to carry a closed trigger inside.
Invariant 7.4: A quiescent closed case MUST carry an empty open-trigger set.
Invariant 7.5: A closure intent MUST name EVERY trigger the closure swept.
Deleted: Invariant 8.1. Recoverable Invocation Invariant 1.1 owns it: no commit stands ahead of the intent the caller's credential attested.
Invariant 8.2: An action MUST validate EXACTLY ONE actor's credential.
Invariant 8.3: The composition MUST NOT claim a recorded actor reference stands authenticated.
Invariant 8.4: A credential validation MUST NOT establish the presenter's identity.
Invariant 8.5: A credential validation MUST NOT establish a channel binding.
Invariant 8.6: A credential validation MUST NOT establish an authorization.
Invariant 8.7: A credential validation MUST NOT establish the customer's evidence.
```

NOTE: an operator's outcome through the invocation resolve is checked against no constituent record (Recoverable Invocation resolve 28, resolve 31), so Invariant 2.1, 4.2, 7.1, 7.2 and 7.5 are detected for an operator's closing, not prevented: Reconciliation 23, Reconciliation 25, Reconciliation 38, Reconciliation 39 and Reconciliation 43 find it, and Check 2.1, 4.1, 7.2, 7.3 and 7.5 read it. Invariant 1.1 through 1.3 are untouched, since the gate reads the party-to-case index and Party Identity and never an outcome; the 5 family is Retention Window's.

Term quiescent case: a case whose party carries no open intent of an act kind and no escalated one.

Term quiescent verified party: a party whose state EQUALS verified whose case stands quiescent.

Term quiescent suspended party: a party whose state EQUALS suspended whose case stands quiescent.

Term quiescent closed case: a closed case standing quiescent.

Term continuous chain: a sequence of placements over one party in which each link's retention instant does not exceed the predecessor's retention deadline.

Term post closure floor: the instant a closed case's post closure placement reaches the placement's retention deadline — the earliest lawful destruction of the party record on the post-closure side.

Term unelapsed placement: a placement whose retention deadline exceeds the injected now.

Term clearing actor: the actor reference a [Clear Review] call carries — the one actor whose credential the composition validates on that call.

---

## Examples

### Walkthrough — retail bank customer onboarding under BSA/AML (direct path)

A bank onboards a retail customer with no prior system identity. Configuration: `active_relationship_policy_ref = bsa_active_cdd`, `post_closure_retention_policy_ref = bsa_5yr_post_closure`, `audit_trail_retention_policy = bsa_audit_9yr`, `monitoring_interval = P1Y`, `adverse_trigger_types = {sanctions-match, pep-status-change, adverse-media}`.

1. **Initiate.** `initiate_onboarding(party_id=absent, enrollment_fields={name:"Amara Osei", date_of_birth:"1981-03-14", document_type:"passport", document_ref:"doc_p901", enrolling_actor_ref:"officer_r3"}, actor_ref="officer_r3", credential=<officer_r3>, retention_policy_ref="bsa_active_cdd") → case_5501`. The invocation open lands `customer-onboarding.enrollment.intended` first, keyed by the enrollment key `(passport, doc_p901, officer_r3)` and carrying `case_5501`, the next review due and no party id; inside the enrollment transaction `PartyIdentity.enroll` returns `party_9017` in `Unverified` and `RetentionWindow.place_under_retention(party_9017, bsa_active_cdd)` returns `ret_active_9017`, both stamped with the invocation's now; the invocation close lands `customer-onboarding.enrollment.initiated` carrying the party id, the placement and the opening instant; the three indexes are populated after it.

2. **Gate before verification.** `activity_permitted(party_9017) → not-verified(Unverified)`. The account is not opened.

3. **Verification.** `record_verification(case_5501, verifying_actor_ref="system_verification_auto", method="automated-ocr", verification_result="passed", evidence_ref="evidence_ocr_442", credential=<system_verification_auto>) → recorded`. `customer-onboarding.verification.intended` lands keyed by `party_9017`, carrying the case id and the next review due a transition sets; `PartyIdentity.verify` returns `{verif_1101, sc_4401}` — the `Unverified → Verified` transition — and `customer-onboarding.verification.recorded` lands carrying both ids; the deadline advances to the intent's.

4. **Gate after verification.** `activity_permitted(party_9017) → permitted`. `account_a883` is opened against `party_9017`.

5. **Periodic review.** A year later the external scheduler calls `trigger_monitoring_review(case_5501, trigger_type="periodic-review-due", trigger_ref="annual-review-2027", actor_ref="system_monitor", credential=<system_monitor>) → recorded`. `customer-onboarding.periodic-review.intended` lands, carrying the case binding, `ret_active_9017` as the prior placement and the advanced deadline; the renewal transaction re-reads the party (not closed) and `RetentionWindow.place_under_retention(party_9017, bsa_active_cdd)` returns `ret_active_9017_2`; `customer-onboarding.periodic-review.renewed` lands naming it; the case-to-retentions index repoints after it; the deadline advances.

6. **Closure.** Ten years later, `close_party(case_5501, closing_actor_ref="officer_r3", reason="account-closed-customer-request", credential=<officer_r3>) → closed`. `customer-onboarding.closure.intended` lands carrying an empty open-triggers-at-close set; the closure transaction re-reads the case's open triggers (still none), `PartyIdentity.close` returns `sc_9901` and `RetentionWindow.place_under_retention(party_9017, bsa_5yr_post_closure)` returns `ret_postclose_9017` — the five-year floor; `customer-onboarding.closure.closed` lands carrying the floor; the indexes follow it.

7. **Gate after closure.** `activity_permitted(party_9017) → not-verified(Closed)`.

### External path — upstream enrollment

A broker-dealer admits a counterparty through External Onboarding, which enrolls the party `Unverified` and registers a credential. `initiate_onboarding(party_id="party_4421", enrollment_fields=absent, actor_ref="onboard_svc", credential=<onboard_svc>, retention_policy_ref="bsa_active_cdd") → case_6602`. The read confirms `party_4421` is known **and `Unverified`**, `customer-onboarding.admission.intended` lands keyed by the party id, the admission transaction re-reads the party (still `Unverified`, no active case) and makes the placement, and `customer-onboarding.admission.initiated` lands — the kind itself recording `enrollment_path = external-onboarding`. A party the read showed `Verified`, `Suspended` or `Closed` answers `party-not-admissible(<state>)` and opens no case.

### Adverse trigger and clearance — sanctions match

An existing `Verified` party, `party_7732` (case `case_7700`), triggers a sanctions screening alert. The screening list is OFAC's SDN list (Office of Foreign Assets Control — the US Treasury office that administers sanctions — Specially Designated Nationals).

1. **Adverse trigger.** `trigger_monitoring_review(case_7700, trigger_type="sanctions-match", trigger_ref="ofac-sdn-12894", actor_ref="compliance_mgr_01", credential=<compliance_mgr_01>) → recorded`. The pre-check reads the party `Verified`; `customer-onboarding.adverse-trigger.intended` lands **first**, carrying the trigger id; the suspension transaction re-runs the pre-check and `PartyIdentity.suspend` returns `sc_7701`; `customer-onboarding.adverse-trigger.suspended` lands carrying it; the trigger enters the open set. Invariant 3 holds — the trigger record is the suspension's own intent, ordered before it by Recoverable Invocation Invariant 1.1 whoever writes the outcome. A second sanctions alert while the party stands suspended lands its own intent, Party Identity answers already-suspended, `customer-onboarding.adverse-trigger.refused` records that code, the caller is answered already-suspended, and the trigger joins the open set.

2. **Gate during investigation.** `activity_permitted(party_7732) → not-verified(Suspended)`.

3. **Clearance.** The match is a false positive. `clear_review(case_7700, verifying_actor_ref="compliance_analyst_02", method="database-check", evidence_ref="evidence_db_clearance_882", actor_ref="compliance_mgr_01", credential=<compliance_mgr_01>, reason="ofac-match-resolved-different-individual") → cleared`. `customer-onboarding.clearance.intended` lands carrying the open set as the closed triggers and the advanced deadline, attested under the clearing actor's credential; the clearance transaction re-reads the case's open triggers (unchanged), `PartyIdentity.verify(passed)` returns `verif_3901` with no `state_change_id` — a passed verification against a `Suspended` party records the event and changes no state — and `PartyIdentity.reinstate` returns `sc_7702`, the two committing together; `customer-onboarding.clearance.cleared` lands carrying `verif_3901` and `sc_7702`; the closed triggers are dropped and the deadline is taken from the intent. Had a new adverse trigger landed between the clearance's intent and its transaction, the re-read would have refused triggers-changed, the reinstate never made.

4. **Gate after clearance.** `activity_permitted(party_7732) → permitted`.

### Rejection path — clearing a review with no open trigger

A compliance officer calls `clear_review(case_5501, …)` for a party with no open adverse trigger: the open set is empty → no-open-trigger. No intent is recorded, no verification, no reinstatement — and, because the guard sits before the intent, the officer's credential is never validated.

### Rejection path — periodic trigger against an unknown case

`trigger_monitoring_review("case_bogus", …) → not-known` at the index read. No audit event is recorded: the case is unknown, so there is no party to attribute a trigger to.

### Rejection path — a credential that does not validate

An operator whose credential was revoked calls `record_verification(case_5501, verifying_actor_ref="officer_r7", method="manual-review", verification_result="passed", evidence_ref="evidence_manual_77", credential=<stale_officer_r7>)`. The index read passes, the boundary predicate passes, and the invocation open's `customer-onboarding.verification.intended` refuses with invalid-credential → invalid-credential. **Nothing committed**: `PartyIdentity.verify` was never called, so a mis-credentialed actor could not drive the transition and be discovered over it afterwards. This is the seam Recoverable Invocation Invariant 1.1 holds, and it is the path that makes invalid-credential a declared code on every state-changing signature rather than a theoretical arm.

### Failure path — the intent appended and the call still failed

`close_party(case_5501, …)` reaches the invocation open, and `AuditTrail.record_action` answers `invalid-request(step-4)` for `customer-onboarding.closure.intended`: the audit instance's Retention Window answered policy-not-found at the substrate's **retention** step, after the event was appended and attested. The open reads the intent back by invocation id (Recoverable Invocation Primitive policy 20): it finds the record, so the action proceeds with a hard alert on the audit instance's policy (Recoverable Invocation Primitive policy 21). Had the read-back found nothing, the open would have answered invalid-request and nothing would have committed (Recoverable Invocation Primitive policy 22). The caller's code is invalid-request, never recording-failure(intent), since the fault is the deployment's and a retry meets it again.

### Failure path — a lost verification outcome

A [Record Verification] invocation lands `customer-onboarding.verification.intended`, keyed by `party_9017` with its pairing datum, and calls `PartyIdentity.verify`, which commits `verif_2210` at the injected now; its close's append then answers nothing, the reply lost, and the action answers `recording-failure(outcome)`: the verification stands committed and its outcome is the sweep's. Past the intent's examine edge, Recoverable Invocation's sweep takes the act's critical section, re-reads the invocation's closings (had the lost append landed after all, it would find it and write nothing), and runs the verification probe: Party Identity's read by `party_9017`, kept to the verification event whose verification instant equals the pairing datum and whose verifying actor reference and evidence reference equal the intent's — `verif_2210`. It records `customer-onboarding.verification.recovery_intended` under the recovery identity, then `customer-onboarding.verification.recorded` carrying `recovery = true`, `verif_2210` and its state change id, with `officer_r3` as the acting actor reference. An auditor reading the trail sees a recovered verification rather than a clean one, and compares it against the acting actor reference rather than the attesting recovery identity (Recoverable Invocation Invariant 5.2).

### Failure path — a lost initiation reply on the direct path

An [Initiate Onboarding] invocation on the direct path lands `customer-onboarding.enrollment.intended`, keyed by `(passport, doc_p902, officer_r3)`, and dies after the enrollment transaction committed `party_9120` and its placement. The sweep's enrollment probe reads Party Identity with an enrollment instant range of the pairing datum alone, keeps the party whose document type, document reference and enrolling actor reference equal the key, and finds the retention over it at the datum rounded up: one of each, so it writes `customer-onboarding.enrollment.initiated` carrying `party_9120`, the retention and the opening instant, under the recovery identity. The case's indexes rebuild from that outcome and its intent. Before the composition bound its act kinds this intent could never be paired, and an operator settled it by hand.

### Failure path — verification committed, outcome open

A [Record Verification] call drives the `Unverified → Verified` transition and its close fails: `recording-failure(outcome)` — the code telling the caller the verification may be committed and the action must not be re-run. The party *is* `Verified`, so the gate answers permitted while Invariant 2.3's coverage waits on the open intent; Recoverable Invocation's sweep closes it within the closure window (Recoverable Invocation Invariant 4.2). The composition alerts on the answer (Audit arm 19), and a deployment under BSA/AML exposure treats the open intent past its examine edge as a hard alerting condition (Capability requirement 42), beside Recoverable Invocation's own closure-at-risk.

### Regulated adversarial scenarios

**Regulator audit — show me that every active customer was verified before regulated activity.** A FATF/BSA examiner queries the trail and the activity records. For every party with an activity record, the examiner confirms a `customer-onboarding.verification.recorded` event carrying a non-absent `state_change_id` exists, that `AuditTrail.verify_record` answers verified for it, and that it precedes the first activity record. The two halves of Invariant 1 answer two different questions and the examiner asks both: Invariant 1.1 and Invariant 1.2 are the composition's own biconditional — the gate answered permitted for exactly the parties this composition initiated and Party Identity reports `Verified` — while Invariant 1.3, that no activity path other than the gate exists, is the deployment's obligation and is cleared by the deployment's own evidence that its activity systems consume [Activity Permitted] (External check 7). Flattening the two loses the distinction between what the records prove and what the deployment must attest. Invariant 2 is the guarantee that the verifying transition is in the records, attributed and tamper-evident. A party with an activity record and no predating, verified verification record carrying a `state_change_id` is a conformance failure while the verification stands inside the audit horizon.

**Disputed onboarding — the party claims they were never properly verified.** Counsel challenges the bank's claim that the identity was verified before the account opened. The investigator retrieves the case's `customer-onboarding.verification.recorded` events; each carries `verification_id`, `result` and, for the transition, `state_change_id`. The Party Identity verification record for each `verification_id` names verifying actor reference, method, evidence reference and `verified_at`. Party Identity's immutability and append-only invariants establish that no verification event was altered or back-inserted; the substrate's seal establishes that the composition's own record was not altered. The evidence reference points to the document record that supported the verification. Invariant 2 with Party Identity's own invariants is the rebuttal.

**Breach or incident forensics — which parties were Verified during the compromise window, and were any verifications altered.** Given a window, the investigator replays each case's records of the onboarding namespace — the seven kinds' intents, outcomes and refusal records, with the recovery intents, escalations and abandonments Recoverable Invocation writes under them, and the pre-switch records for a case older than the switch — in Event Log insertion order to determine each party's state at the window's bounds — the intake and closure classes included, without which the replay cannot place a case's start or reconstruct a closure at all — then runs `AuditTrail.verify_record` against representative events in each seal's coverage to bound any tampering window. Invariant 3 is load-bearing here: every suspension in the window has a precipitating trigger intent ordered ahead of it, and a suspension with no precipitating trigger — or a trigger inserted *after* its suspension — is itself a finding, which the append-only sealed log forecloses an attacker doing silently. Invariant 6 lets the investigator confirm that every `Verified`, active party in the window had an open monitoring entry. Where the window has legal force as wall-time rather than event-index bounds, a Trusted Timestamping composition supplies the anchor; absent it the reconstruction is event-index-authoritative. The newest events — the substrate's unsealed tail — carry per-event immutability and become seal-verifiable only after the next seal cadence, so the integrity bound on the most recent events is the substrate's configured unsealed-tail policy.

---

## Generation acceptance

A derived implementation is *acceptable* — in the regulator-acceptance sense — when every check below is provable to an external auditor given the composition's indexes plus the Party Identity, Retention Window and Audit Trail records. Every selection is made composition-side over the declared open-ended sequence range, never by asking the substrate for a payload predicate it does not serve.

### Conformance checks

```
Check 1.1: An auditor MUST find a verification outcome carrying a state change id PER party carrying a regulated activity record AND no transitioning verification standing an aged record (Invariant 1.3).
Check 1.2: An auditor MUST confirm Audit Trail's verify_record answers verified for the found verification outcome (Invariant 2.2).
Check 1.3: An auditor MUST confirm the found verification outcome's intent stands earlier in the log than the party's first activity record (Invariant 1.3).
Check 1.4: An auditor MUST read Check 1.3 as a wall-time comparison ONLY IF the deployment composes Trusted Timestamping (Clock semantics 8).
Check 1.5: An auditor MUST read Check 1.3 against activity records carrying no log anchor as best-effort (Clock semantics 8).
Check 1.6: An auditor MUST confirm the party-to-case index names EVERY party the gate answered permitted for (Invariant 1.1).
Check 2.1: An auditor MUST resolve EVERY transitioning verification in Party Identity's records that IS NOT an aged record to EXACTLY ONE OF a verification outcome naming the verification id and the state change id, an open carrying intent, an escalated carrying intent, a false closing alert, a write-ownership finding (Invariant 2.1).
Check 2.2: An auditor MUST find a verification outcome PER quiescent verified party carrying no transitioning verification standing an aged record (Invariant 2.3).
Deleted: Check 2.3. Recoverable Invocation Check 3.1 owns it: an intent carrying no outcome is closed or escalated within the closure window.
Check 3.1: An auditor MUST find the adverse trigger intent the outcome carries the intent event id of earlier in the log PER suspension outcome (Invariant 3.1).
Check 3.2: An auditor MUST find the adverse trigger intent the record carries the intent event id of earlier in the log PER refusal record carrying already-suspended (Invariant 3.2).
Check 4.1: An auditor MUST find a clearance outcome naming a verification id AND the reinstate's state change id PER reinstatement in Party Identity's records (Invariant 4.2).
Check 4.2: An auditor MUST confirm the named verification stands passed in Party Identity's records (Invariant 4.1).
Check 4.3: An auditor MUST confirm the named verification stands later in the log than the party's most recent suspension (Invariant 4.1).
Deleted: Check 4.4. Invariant 4.3 and Recoverable Invocation Check 1.1 own it: the clearance writes one intent, attested under the clearing actor, and one outcome naming it.
Check 5.1: An auditor MUST find a post closure placement whose retention state EQUALS retained PER closed party outside lawful destruction (Invariant 5.3).
Check 5.2: An auditor MUST read a closed party's record destroyed inside the post closure floor as a conformance failure (Invariant 5.6).
Check 5.3: An auditor MUST find a current placement standing unelapsed PER quiescent active case (Invariant 5.1).
Check 5.4: An auditor MUST reproduce the chain of placements from the initiation outcome AND the renewal outcomes in intent order (Composition state 29).
Check 5.5: An auditor MUST confirm the reproduced chain stands as a continuous chain (Invariant 5.2).
Check 5.6: An auditor MUST read a party record destroyed under an unelapsed placement as a conformance failure (Invariant 5.4).
Check 6.1: An auditor MUST find a case-to-monitoring entry PER verified party under an active case (Invariant 6.1).
Check 6.2: An auditor MUST reproduce the next review due as the latest schedule-bearing record PER active case in intent order (Composition state 28).
Check 6.3: An auditor MUST read a reproduced next review due disagreeing with the index as a rebuild trigger (Composition state 9).
Check 6.4: An auditor MUST read an active case carrying no schedule-bearing record as a conformance failure (Invariant 6.2).
Check 7.1: An auditor MUST reproduce the open-trigger set PER active case from the adverse trigger intents AND the intents' closings (Composition state 31).
Check 7.2: An auditor MUST confirm the party's state EQUALS suspended PER active case carrying a non-empty reproduced set (Invariant 7.1).
Check 7.3: An auditor MUST confirm the reproduced set stands non-empty PER quiescent suspended party under an active case (Invariant 7.2).
Check 7.4: An auditor MUST find a closing PER adverse trigger intent of a quiescent case (Invariant 7.1).
Check 7.5: An auditor MUST confirm a closure intent's open triggers at close names EVERY trigger the reproduced set carried at the closure's commit (Invariant 7.5).
Deleted: Check 7.6. Term clearance transaction owns it: no clearance stands recorded beside a trigger it left open.
Deleted: Check 8.1. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 8.2. Recoverable Invocation Primitive policy 11 and Identity 9 own it: every record of an invocation carries the act key, and the intent the case id.
Deleted: Check 8.3. Recoverable Invocation Check 1.1 and Recoverable Invocation Invariant 5.2 own it: a recovered outcome is compared against the acting actor reference.
Deleted: Check 8.4. Recoverable Invocation Invariant 5.2 owns it.
Deleted: Check 8.5. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 8.6. Recoverable Invocation Check 6.1 owns it.
Check 9.1: An auditor MUST clear Party Identity's conformance checks over the Party Identity records (Composes 5).
Check 9.2: An auditor MUST clear Retention Window's conformance checks over the party retention instance (Composes 5).
Check 9.3: An auditor MUST clear Audit Trail's conformance checks over the audit instance (Composes 5).
Check 9.4: An auditor MUST recognize an aged-out event PER event through Audit Trail's read_record (Composition state 19).
Check 9.5: An auditor MUST NOT read an aged-out event's payload (Composition state 18).
Check 9.6: An auditor MUST clear Recoverable Invocation's Generation acceptance over the Recoverable Invocation instance (Composes 5).
Check 10.1: An auditor MUST resolve EVERY verification event, state change event AND placement over an active case's party that is neither a young record nor an aged record to EXACTLY ONE OF a carried record one intent carries whose carrying intent stands open, a carried record one intent carries whose carrying intent stands escalated, a carried record one intent carries that an outcome names, a false closing, a carried record two intents carry, a write-ownership finding (Reconciliation 38, Reconciliation 39).
```

NOTE: open 2026-11-11-d — Check 4.1, Check 5.4 and Check 5.5 read an outcome's payload past the audit horizon as Check 1.1, Check 2.1, Check 2.2 and Check 6.4 did before Final Critique 6, and a case closed while suspended cannot rebuild its next review due until its periodic review intents age out too (Composition state 28).

### External checks

```
External check 1: The deployment MUST establish the verification method's adequacy for the party's risk tier (Non-goal 3).
External check 2: The deployment MUST establish the screening list's currency at the screening's instant (Non-goal 1).
External check 3: The deployment MUST establish the verifying actor reference's identity (Invariant 8.3).
External check 4: The deployment MUST establish the enrolling actor reference's identity (Invariant 8.3).
External check 5: The deployment MUST establish an actor's authorization to record a verification (Invariant 8.6).
External check 6: The deployment MUST establish the lawful basis of a non-obligatory downstream processing (Non-goal 11).
External check 7: The deployment MUST establish that every activity system consumes [Activity Permitted] (Invariant 1.3).
External check 8: The deployment MUST establish that no second writer drives a state transition on the Party Identity instance (Composes 20).
External check 9: The deployment MUST establish that the active relationship policy's duration, and the duration of every policy an [Initiate Onboarding] call may name, exceeds the renewal floor (Capability requirement 20, Capability requirement 20a).
External check 10: The deployment MUST establish that the post closure policy's duration meets the post closure minimum (Capability requirement 17).
External check 11: The deployment MUST establish the scheduler's lateness against the scheduler tolerance (Capability requirement 19).
External check 12: The deployment MUST establish the obligation of Capability requirement 48 AND Capability requirement 49 from external evidence (Recoverable Invocation External check 12).
External check 13: The deployment MUST establish that the seven act probes read the database the act was made in (Recoverable Invocation External check 4).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT run a verification workflow.
Non-goal 1a: The composition MUST own the state transitions ONLY (Party Identity Composition note 2, Composes 19).
Non-goal 2: The composition MUST NOT judge an identity document.
Non-goal 3: The composition MUST NOT decide a risk tier.
Non-goal 4: The composition MUST NOT decide a verification method.
Non-goal 5: The composition MUST NOT decide a re-verification cadence PER party.
Non-goal 6: The composition MUST NOT schedule a review.
Non-goal 7: The composition MUST NOT model a pending verification.
Non-goal 7a: A deployment needing a pending verification MUST model the pending verification in the deployment's own verification workflow (Party Identity Non-goal 22).
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
Non-goal 22: The composition MUST NOT describe the three commits of an acting action as atomic (Recoverable Invocation Non-goal 1).
Non-goal 23: The composition MUST NOT own a re-entry arm beyond Party Identity's already-closed AND the external path's already-onboarded (Recoverable Invocation Non-goal 4).
Non-goal 24: The composition MUST NOT bind a suspended party's investigation as an act kind.
```

NOTE: the owners — Risk Tiering / EDD *(forthcoming)* (Non-goal 3 through 5); [Duplicate Prevention](../atoms/duplicate-prevention.md), wired by a deployment in front of [Record Verification] or [Trigger Monitoring Review] (Non-goal 9); the composing system (Non-goal 10); a composing [Permissions](../atoms/permissions.md) layer (Non-goal 16, External check 5); a Review Schedule *(forthcoming)* (Non-goal 17); a deployment's own verification workflow (Non-goal 1, Non-goal 1a, Non-goal 7, Non-goal 7a); a Reverse Index *(forthcoming)* a deployment composes over the trail (Non-goal 19, Composes 14). Non-goal 24 is the scope of the method rule *A wait composes, never hand-rolls* in `pressure-testing.md`: a suspended party waits on a person's [Clear Review], and no rule ends a wait on a person, so a suspension is no open act and no sweep reads it; the waits Recoverable Invocation closes are the five acting actions' own calls.

---

## Edge cases

### Atomic writes

```
Deleted: Atomic writes 1. Recoverable Invocation Action wiring 4 owns it: the close follows the commit.
Atomic writes 2: An invocation MUST populate an index ONLY AFTER the invocation's landed closing.
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

Term skewed gate read: a read of the gate whose two reads, the party-to-case index's and Party Identity's, stand at different instants (Concurrency 3).

Term closing: an outcome, a refusal record, or Recoverable Invocation's abandonment or escalation record — what an intent may be followed by under the intent's invocation id.

Term orphan: a committed act carrying an index the composition has not populated — the derived-index half; a committed act whose outcome has not landed stands as an open intent, which is Recoverable Invocation's (Recoverable Invocation Invariant 4.1).

### Clock semantics

```
Clock semantics 4: The next review due MUST PRECEDE the placement's cover.
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
Deleted: Concurrency 4. Invariant 1.1 owns it: a skewed gate read answers permitted only where Party Identity's read reports the party verified, so the skew fails safe.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Concurrency 6: The composition MUST read a state rejection the suspension transaction's re-read forecloses as a serialization breach.
Deleted: Concurrency 7. Execution Contract Database 2 owns it.
Deleted: Concurrency 8. Execution Contract Database 2 owns it.
```

### Cross-record consistency under partial failure

```
Cross-record consistency 1: IF an acting action's commit commits AND the invocation's close does not land THEN the committed records MUST stand beside an open intent, closed by the sweep within the closure window.
```

This is Recoverable Invocation's Cross-record consistency for the seven act kinds, which the sweep closes: the party's state, its verification event, its placement, are honest throughout, the gate reading Party Identity and the party-to-case index, never an outcome; an index whose backing closing has not landed reads as a miss and rebuilds once it lands. The records an action keeps as evidence of a refused call — its intent and its refusal record — stay committed (Recoverable Invocation commit 3).

---

## Composition notes

**Recoverable Invocation.** The five acting actions follow [Recoverable Invocation](./recoverable-invocation.md) around their constituent writes (Composes 27 through 31): an intent before the commit, the one outcome as the close, a refusal record where a constituent or a re-read refuses, the act's critical section over them, and a sweep and an operator's invocation resolve for what an invocation left open. The page binds the seven act kinds once (Term onboarding bindings) and restates none of the protocol. [Activity Permitted] is not bound (Composes 30): it writes nothing, so nothing outlives the invocation. The composition held no critical section of its own before, the database serializing a party's actions (Execution Contract Database 2), so the act section Recoverable Invocation takes is a new capability a deployment supplies (Capability requirement 50).

**The investigation is not a wait.** A suspended party waits for a person to clear the review, for as long as that takes inside the suspension bound (Capability requirement 57), and no rule of the composition ends that wait (Non-goal 24); the verification workflow's result is the deployment's, recorded here and not awaited (Non-goal 1, Non-goal 7); and the review scheduler calls the composition, never the reverse (Non-goal 6). What the composition waits on is its own calls — an enroll, a verify, a suspend, a reinstate, a close, a placement and the audit records around them — and those are Recoverable Invocation's.

**Recoverable Invocation's commit is one call.** Recoverable Invocation's bound commit is one constituent call whose arms the constituent partitions; the enrollment, clearance and closure transactions are two constituent calls each, and the admission, suspension, clearance, closure and renewal transactions each a re-read and the call it guards, in one database transaction (Term enrollment transaction through Term closure transaction), whose partition belongs to the transaction. Recoverable Invocation's closed list of deviations has no entry for it, and the page treats the transaction as the commit and records the mismatch as an open line (Recoverable Invocation Deviation 2), as Multi-Party Approval, Chain of Custody, Capability-Backed Sharing and Propagate Consent Revocation Downstream do.

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

Term actors: the composition; a deployment; the host; the seam; the transition; the reconciliation; a caller; an auditor; an activity system; an implementation; a reader; a writer; an invocation; an action; an intent; an outcome; the gate; a rebuild; an index; the case-to-monitoring index; the party-to-case index; the case-to-retentions index; the case-to-open-triggers index; an index entry; an unrebuildable entry; a case; a quiescent case; a quiescent closed case; an active case; a closed case; a party; a quiescent verified party; a quiescent suspended party; a reinstated party; a verified party; a suspended party; a case's party; a party state; an admissible state; a suspendable state; a trigger; an adverse trigger; a periodic trigger; a suspending trigger; a renewing trigger; an open trigger; a closed trigger; a trigger set; a verification; a transitioning verification; a clearance; an admitted initiation; an admitted verification; an admitted trigger; an admitted clearance; an admitted closure; a direct path initiation; an external path call; a placement; a current placement; a prior placement; a renewed placement; a post closure placement; an elapsed placement; an unelapsed placement; a continuous chain; a renewal; a purging layer; a committing call; an aged-out event; an audit event; an orphan; a boundary predicate; an opaque input; an actor reference; the clearing actor; a credential; a credential validation; a field cap; the binding floor; the suspension bound; the suspension floor; the reconciliation run bound; the renewal floor; the audit horizon; the monitoring interval; the scheduler tolerance; a policy; the active relationship policy; the post closure policy; the post closure minimum; the adverse trigger types; the periodic trigger type; a regulated activity; a review scheduler; Party Identity; Retention Window; Audit Trail; Event Log; the party retention instance; the audit instance; a truncation marker; a payload field; a timestamp; insertion order; a clock reading; a skewed gate read; a state rejection; a divergence; Recoverable Invocation; the Recoverable Invocation instance; the recovery identity; the sweep; an operator; an act kind; an act key; the enrollment key; a pairing datum; an act probe; a refusal record; a closing; a carried record; a carrying intent; a young record; an aged record; a write-ownership finding; a false closing; the finding surface; a pre-switch record; the cut-over instant; a validated initiation; a validated verification; a validated trigger; a validated clearance; a validated closure; a probed record; Lease.

Term record verbs: serve, change, inherit, read, hold, reach, call, select, query, attest, own, place, admit, drive, know, push, store, classify, carry, stand, claim, populate, name, alert, drop, take, rebuild, recognize, supply, mint, generate, accept, configure, set, provision, rotate, disclose, start, run, fire, serialize, resolve, reconcile, refuse, normalize, fold, trim, compare, judge, propagate, cap, truncate, allocate, reuse, pair, make, retry, leave, record, answer, substitute, add, clear, empty, write, advance, repoint, renew, find, confirm, reproduce, establish, match, escalate, close, emit, examine, expose, validate, commit, detect, inject, stamp, derive, deduplicate, model, schedule, adjudicate, purge, unwind, gate, index, anchor, surface, treat, sweep, spend, enroll, verify, suspend, reinstate, belong, elapse, substantiate, invoke, duplicate, block, govern, identify, decide, reverse, destroy, bind, remove, declare, open, describe.

Term records: empty.

Term bounds: onboarding completion bound (onboarding_completion_bound), reconciliation run bound (Recoverable Invocation's run bound), clock offset allowance (Recoverable Invocation's clock allowance), commit round trip, probe round trip, settling period, audit horizon (audit_trail_retention_policy), monitoring interval (monitoring_interval), scheduler tolerance (scheduler_tolerance), renewal floor, binding floor, suspension bound (suspension_bound), suspension floor, field cap, `placement's cover`, post closure minimum.

Term cadences: sweep cadence (Recoverable Invocation's), seal cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.41 (2026-09-14).

Term value sets: admissible states = unverified. suspendable states = verified | suspended. verification results = passed | failed. trigger vocabulary = periodic-review-due | a member of the adverse trigger types. adverse trigger types = sanctions-match | pep-status-change | adverse-media, extended by the deployment. act kind = customer-onboarding.enrollment | customer-onboarding.admission | customer-onboarding.verification | customer-onboarding.adverse-trigger | customer-onboarding.periodic-review | customer-onboarding.clearance | customer-onboarding.closure. intent = customer-onboarding.enrollment.intended | customer-onboarding.admission.intended | customer-onboarding.verification.intended | customer-onboarding.adverse-trigger.intended | customer-onboarding.periodic-review.intended | customer-onboarding.clearance.intended | customer-onboarding.closure.intended. outcome = customer-onboarding.enrollment.initiated | customer-onboarding.admission.initiated | customer-onboarding.verification.recorded | customer-onboarding.adverse-trigger.suspended | customer-onboarding.periodic-review.renewed | customer-onboarding.clearance.cleared | customer-onboarding.closure.closed. position = intent | outcome | refusal. enrollment path = direct | external-onboarding.

Term terms: composition, constituents, transitive atoms, party retention instance, recovery identity, direct path, external path, acting action, act kind, onboarding namespace, onboarding bindings, enrollment key, enrollment transaction, admission transaction, suspension transaction, renewal transaction, clearance transaction, closure transaction, commit partition, enrollment probe, admission probe, verification probe, suspension probe, renewal probe, clearance probe, closure probe, probed record, case-to-monitoring index, party-to-case index, active flag, active case, case-to-retentions index, case-to-open-triggers index, index, current placement, post closure placement, audit horizon, aged-out event, rebuild, intent order, miss, unrebuildable entry, binding-bearing record, schedule-bearing record, placement-bearing record, pre-switch record, counterpart, seam, now, transition, monitoring interval, scheduler tolerance, renewal floor, binding floor, suspension bound, suspension floor, reconciliation run bound, clock offset allowance, invocation id, commit round trip, probe round trip, settling period, cut-over instant, onboarding completion bound, active relationship policy, post closure policy, post closure minimum, adverse trigger types, periodic trigger type, field cap, blank, boundary predicate, opaque input, actor reference, trigger vocabulary, verification results, truncation marker, probe-matched fields, cover-bound invocations, intent instant, opening instant, trigger instant, suspension instant, renewal instant, clearance instant, closure instant, intent, outcome, refusal record, initiation intent, initiation outcome, verification intent, verification outcome, trigger intent, adverse trigger intent, periodic review intent, suspension outcome, renewal outcome, clearance intent, clearance outcome, closure intent, closure outcome, recovery flag, committing call, position, enrollment failure, party state, admissible states, suspendable states, validated initiation, admitted initiation, validated verification, admitted verification, validated trigger, admitted trigger, validated clearance, admitted clearance, validated closure, admitted closure, transitioning verification, adverse trigger, periodic trigger, suspending trigger, renewing trigger, committing closure, composed suspend reason, closed triggers, open triggers at close, prior placement, kind's instant, renewed placement, regulated activity, reconciliation, elapsed placement, carried record, carrying intent, young record, aged record, write-ownership finding, false closing, finding surface, quiescent case, quiescent verified party, quiescent suspended party, quiescent closed case, continuous chain, post closure floor, unelapsed placement, clearing actor, skewed gate read, closing, orphan, `placement's cover`.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the derived-index classification and its obligations. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Structural-relation invariant templates in `spec-format.md` — referential integrity. read_record, verify_record, record_destruction, action reference, event id: Audit Trail. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. Execution Contract Database 7, Execution Contract Refusal 1 and Execution Contract Scheduled leg 1 — the act section, the refusal order, the sweep's run. open, close, refuse, yield, resolve, sweep, act key, pairing datum, act probe, commit, repeatable, journal, service identity, outcome envelope, invocation completion bound, closure window, sweep cadence, run bound, clock allowance, examine edge, examine window end, reference length cap, act-in-flight, section-unavailable, journal-unavailable, already-accounted, act-landed, recovery, acting actor reference, act section, compliance surface, run id, operator run id: Recoverable Invocation. Lease: reached through Recoverable Invocation. already-suspended, not-verifiable, enrollment instant, verification instant: Party Identity. retention instant, time resolution: Retention Window.

Term composing patterns: Risk Tiering / EDD *(forthcoming)*; Ownership Structure / Beneficial Owner *(forthcoming)*; Review Schedule *(forthcoming)*; Reverse Index *(forthcoming)*; Trusted Timestamping *(forthcoming)*; Policy Reconciliation *(forthcoming)*; [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md); [External Onboarding](./external-onboarding.md); [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md); [Defensible Retention](./defensible-retention.md); [Duplicate Prevention](../atoms/duplicate-prevention.md); [Permissions](../atoms/permissions.md).

Term trigger type: trigger_type — which kind of adverse trigger a record carries.

Term enrollment path: enrollment_path — the path a case was enrolled by.

#### Initiate Onboarding

The composition's intake action: open a Customer Due Diligence case for a party — enrolling the party on the direct path, or admitting one External Onboarding already enrolled in `Unverified` state on the external path, with enrollment path recording which — placing the first active-relationship retention, opening the monitoring schedule, and recording the case. Answers the case id; refuses [Already Onboarded] for a party that already has an active case (Action wiring 7, Action wiring 161) and [Enrollment Failed] for a direct path enroll Party Identity refuses (Action wiring 11, Action wiring 12). The direct path binds customer-onboarding.enrollment, keyed by the enrollment key since the party id does not yet exist; the external path binds customer-onboarding.admission, keyed by the party id.

Kind: Operation

#### Record Verification

The action that records a verification result against a case's party, driving the `Unverified → Verified` transition on a passed first verification, and recording the verification and state-change identifiers — the attribution-and-tamper-evidence half of verification-gates-activity (Invariant 2). Advances [Next Review Due] on a state-changing pass and on nothing else. A case whose active flag is false is refused [Not Active] here and at [Trigger Monitoring Review] and [Close Party] (Action wiring 23, Action wiring 39, Action wiring 114).

Kind: Operation

#### Trigger Monitoring Review

The audit-first entry point an external monitoring or screening system calls: its intent is the trigger's record, landed *before* any resulting transition (Invariant 3), then — for an adverse trigger — the suspension transaction suspends the party, or — for a periodic one — the renewal transaction renews the active-relationship retention, and [Next Review Due] advances once the renewal lands, unless the party stands suspended. No suspension exists in the records without its precipitating trigger ordered ahead of it, a recovered or an operator's included (Recoverable Invocation Invariant 1.1). An adverse trigger against a party already suspended is refused already-suspended, its refusal record read as [Trigger On Suspended Party]; one whose suspend Party Identity refuses otherwise is read as [Trigger Voided] (Action wiring 53 through 56).

Kind: Operation

#### Clear Review

The single emergent action that clears an adverse-trigger investigation and returns the party to Verified — a fresh passed verification and a `reinstate` in one transaction, recorded by one intent and one outcome. Requires an open trigger ([No Open Trigger] otherwise), answers [Verification Failed] where Party Identity refuses the reinstate as not-suspended or for no passed verification since the suspend (Action wiring 96, Action wiring 97) — the verify rolled back with it — answers [Triggers Changed] where a trigger landed since its intent named the set (Action wiring 165), and closes exactly the triggers its clearance intent names.

Kind: Operation

#### Close Party

The action that ends the relationship and places the *post-closure* retention — the placement that sets the BSA/AML five-year-after-relationship-end floor — then records the closure with the disposition of any investigation still open at closure.

Kind: Operation

#### Activity Permitted

The read-only verification-gates-activity query every activity system consumes rather than reading Party Identity directly: answers permitted only for a party this composition itself initiated and Party Identity reports Verified, else [Not Verified] naming the actual state, [Party Not Known], or [State Unavailable]. Produces no audit event — it changes no state.

Kind: Operation

#### Next Review Due

The monitoring-schedule datum in each case's entry: the instant by which the party's next periodic review is due, advanced on a state-changing verification pass, a renewing periodic review against an unsuspended party, or a review clearance — carried on the act's intent and taking effect once the act's outcome stands, a refused renewal leaving it where it stood — and capped below the current placement's cover (Clock semantics 4) so the review that renews the placement always fires before the placement lapses. It deliberately does not roll forward while a party is Suspended. A Verified party with no monitoring entry is a structural finding (Invariant 6.1).

Kind:       Field
Field of:   the monitoring-schedule entry
Role:       the next-periodic-review deadline
Projection: next_review_due

#### Not Verified

The load-bearing [Activity Permitted] refusal, parameterized by the party's actual state (`Unverified`, `Suspended` or `Closed`), so an activity system distinguishes *not yet verified* from *under investigation* from *relationship ended* and knows whether to retry, wait or stop. [Trigger Monitoring Review] answers it too, on the adverse pre-check and on the suspend refusals behind it (Action wiring 57, Action wiring 58); the gate is the ordinary producer.

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

The [Clear Review] refusal when the reinstatement's precondition is unmet — a concurrent suspend re-armed it (Action wiring 96), or the party was not Suspended (Action wiring 97).

Kind:       Member
Member of:  the clear-review rejection
Role:       Rejection
Projection: verification-failed

#### Not Active

The refusal the three repeatable actions answer for a case whose relationship has ended. Monitoring does not fire against a closed relationship, a closed case takes no further verification, and a second closure has nothing to close; the guard sits before the intent, so a closed case never reaches a constituent and never leaves an intent for an act that could not happen. A periodic review whose party closed between its guard and its commit is refused here too, by the renewal transaction's re-read (Action wiring 169), and a second closure whose first committed answers it from Party Identity's already-closed (Action wiring 119).

Kind:       Member
Member of:  the case-guard rejection
Role:       Rejection
Projection: not-active

#### Trigger On Suspended Party

The reading of an adverse trigger's refusal record that carries already-suspended — a real trigger against a party already suspended, no new transition. Read apart from the suspension outcome so a second adverse alert is not read as a second suspension and an auditor does not miscount transitions; the trigger still enters the open set (Action wiring 54, Composition state 32), and one clearance closes every trigger it names. Before the composition bound its act kinds it was its own audit event class.

Kind:       Member
Member of:  the adverse trigger refusal readings
Role:       Audit event
Projection: trigger-on-suspended-party

#### Trigger Voided

The reading of an adverse trigger's refusal record that carries any code other than already-suspended — a trigger whose intent landed and whose `suspend` was refused, naming the constituent's answer. Read apart so the landed trigger does not rebuild as an open investigation against a party nobody suspended, which [Clear Review] would then *clear* — recording a fresh verification, attempting a reinstate the constituent refuses — and so the rebuild drops it (Composition state 32). Before the composition bound its act kinds it was its own audit event class.

Kind:       Member
Member of:  the adverse trigger refusal readings
Role:       Audit event
Projection: trigger-voided

#### Triggers Changed

The [Clear Review] and [Close Party] refusal when the case's open triggers, re-read inside the commit's transaction, are not the set the action's intent named — an adverse trigger landed between the intent and the commit — or, at [Clear Review], when an adverse trigger intent of the case carries no closing yet. Without it a clearance would reinstate a party over a trigger it never examined — or over one whose intent it named while the trigger's suspend had not yet committed, which then suspends the party again with no open trigger left to clear (Invariant 7.2) — and a closure would leave a trigger open on a closed case (Invariant 7.1, Invariant 7.4, Invariant 7.5). The caller retries, and the retry names the set as it now stands.

Kind:       Member
Member of:  the trigger-set rejection
Role:       Rejection
Projection: triggers-changed

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
[Triggers Changed]: #triggers-changed

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

`grounded on Final Critique 8 — 2026-11-11 at 1537770` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 8 — 2026-11-11 at 1537770
formal: verified — customer-onboarding.tla + 10 twins + 7 reachability probes, re-derived 2026-11-10 over the split arc (each acting action an open, a commit and a close; the suspension, clearance and closure transactions one commit each with the re-read the page puts inside it, a refusal inside one writing nothing), against Recoverable Invocation's contracts (the sweep's closing by this page's suspension, clearance and closure probes on the pairing datum, the escalation, an operator's resolve unchecked against the records), with a state change written on Party Identity outside every invocation and the reconciliation's write-ownership finding and false-closing alert; one model under TLC, 64,020 states (one party verified under an active case, two adverse triggers, three invocations, one outside write); Invariant 7.1 and 7.2 at the restated quiescence, the trigger set's rebuild (Composition state 31 through 34), the clearance's and the closure's re-reads (Action wiring 164 through 167, the in-flight adverse intent among them), Invariant 7.4 and 7.5, the owed outcome (Cross-record consistency 1), the pairing datum (Capability requirement 48, 49), the write-ownership finding (Reconciliation 38) and the false-closing alert (Reconciliation 39), each broken by a twin alone; Invariant 3.1's order inherited from Recoverable Invocation Invariant 1.1, the closure window from Recoverable Invocation Invariant 4.2; not modelled: Recoverable Invocation's mechanism, the clock (the young and aged records, the cut-over instant, the horizon), the enrollment, admission, verification and periodic review kinds, Retention Window, the gate, validation ahead of the open, the derived indexes other than the open-trigger set; coverage 2026-11-10: owes Alloy (the static data model); owed rows: Invariant 1.1 through 1.3; Invariant 2.1, 2.3; Invariant 4.1 through 4.3; Invariant 5.1 through 5.4, 5.6; Invariant 6.1; Reconciliation 22, 23, 25, 43 and the leg's edges, 2026-11-10
last gate: 2026-11-11 — Final Critique 8, a delta round, frozen at 1537770 — foundational count 0 after the blind second triage, clean, one fresh pass (Linus's one report claimed one, an operator's resolve through Composition state 34 leaving a suspended party with an empty open-trigger set; both triages refuted it: the NOTE after Invariant 8.7 and the 2026-11-10 decision record that an operator's closing is detected, not prevented, by Reconciliation 23 and Check 7.3)

open:
- 2026-11-11-a · refining · Invariant 7.5; Composition state 33, 34; Action wiring 83 · the closed triggers and the open triggers at close ride the intent in full, so a case whose open triggers outnumber what one intent carries under Audit Trail's payload cap can be neither cleared nor closed by an action; the refusal at the open is the answer for a payload past the cap, and Final Critique 6 deleted Primitive policy 20's digest for it → decide whether an operator's resolve is the way out of such a case, or the sets split across more than one intent
- 2026-11-11-b · refining · Term enrollment key; Capability requirement 54 · the enrollment key's separator is unnamed, so its byte form, and the length Capability requirement 54 bounds, are undetermined for a reader who reproduces the act key → decide whether the separator is named here, or the key's byte form is the deployment's
- 2026-11-11-c · refining · Composes 12; Composition state 15; Capability requirement 31, 33; Primitive policy 9, 17; Term intent order · the open-ended sequence range read, Party Identity's reason cap, Audit Trail's payload cap and Recoverable Invocation's critical section are named here and carried by no constituent's declared surface or Term cited line → carry to the constituents' next revisions as evidence, or declare each in the Term cited line
- 2026-11-11-d · refining · Check 4.1, 5.4, 5.5; Composition state 28 · the audit-horizon expiry Final Critique 6 cured at Check 1.1, 2.1, 2.2 and 6.4 fails Check 4.1 (the clearance outcome per reinstatement) and Checks 5.4 and 5.5 (the placement chain from the initiation outcome) past the horizon, and a case closed while suspended cannot rebuild its next review due until its periodic review intents age out too → decide whether each check takes the aged-record clause, or one rule reads an aged-out payload's absence as no failure of any check
- 2026-11-11-e · refining · Term suspension floor; Capability requirement 57; Composition state 31 · the floor ages a suspended case's latest schedule-bearing record for the open triggers the clearance and the closure re-read, which ride the adverse trigger intents and age from their own instants → decide whether the floor binds the adverse trigger intents' payloads, or the latest schedule-bearing record's alone
- 2026-11-11-f · refining · Action wiring 76, 76a; Capability requirement 40a · a refused renewal leaves the next review due where it stood, so the scheduler fires the review again at its next pass and no rule bounds how often a registry fault is retried → decide whether the retry at every pass is the answer, or a refused renewal waits a stated delay
- 2026-11-04-b · refining · Composition state 5, 20, 21, 22 · an unrebuildable entry outlives the events that carried its case id, party id and enrollment path, and no rebuild reproduces it, where the Execution Contract counts an unflagged truth-bearing composition record a conformance finding; the binding now rides the initiation and periodic review intents, which age out alike → decide whether the entry is flagged extraction-pending against a named atom or the horizon bound (Capability requirement 14) is the answer
- 2026-11-10-a · refining · Composition notes; Term enrollment transaction through Term closure transaction · Recoverable Invocation's bound commit is one constituent call, and the enrollment, clearance and closure transactions are two calls each, and the admission, suspension, renewal, clearance and closure transactions a re-read and the call it guards, in one database transaction, a case Recoverable Invocation's closed deviation list does not name (Recoverable Invocation Deviation 2) → carry to Recoverable Invocation's next revision as evidence, with Multi-Party Approval 2026-11-10-a, Chain of Custody, Capability-Backed Sharing and Propagate Consent Revocation Downstream, or declare it there
- 2026-11-10-b · refining · Reconciliation 37; Term carried record · Party Identity's read has no instant axis for verification and state change events, so the reconciliation reads every active case's party by party id and keeps the events in its own code, one read per active party per run inside the run bound → decide whether the leg reads only the parties with a record newer than the previous run's start, or the run bound is sized for the whole book
- 2026-11-10-c · refining · Term enrollment probe; Term admission probe; Term renewal probe; Term closure probe · Retention Window rounds a retention instant up to its time resolution, so two placements over one party inside one resolution step match one datum and answer undecidable, escalated for an operator → decide whether the probes also pair on the policy reference's placement order, or the escalation is the answer
- 2026-11-10-d · refining · Action wiring 159 through 167, 171 · the admission, clearance and closure transactions read the composition's own Audit Trail events inside the commit's transaction, which the 2026-10-20 one database permits under Execution Contract Database 2 and no other adopter of Recoverable Invocation has done → confirm the reading, or read the open-trigger and party-to-case indexes under rebuild on miss instead, which stand outside every transaction (Composition state 7)
- 2026-11-10-e · refining · Composition state 52; Term pre-switch record; Term counterpart; Reconciliation 41 · a case older than the switch rebuilds from records of the old classes, which carry an intent event id and no act key, read as their counterparts, and the reconciliation reads no record before the cut-over instant → decide whether the counterpart reading is a rule of its own with a check, or a deployment's migration owns it
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/customer-onboarding.md`; the migration and the regeneration that got it here are in [its history](./customer-onboarding.hist.md).

- **2026-08-26 — Invariant 4 is narrowed to the actor the composition authenticates.** *Chose:* the clearing actor, whose credential is verified, attests that fresh evidence naming the verifying actor was recorded before the reinstatement. *Over:* requiring `verifying_actor_ref == actor_ref`, or taking a second credential. *Because:* the first collapses a real separation of duties (an analyst gathers evidence, a manager clears the review) and the second is a signature change; the guarantee was narrowed to what the records can show.
- **2026-08-27 — The active-relationship retention is a renewed chain, not one placement.** *Chose:* the periodic path of [Trigger Monitoring Review] places a fresh active-relationship retention at every review, recorded as `customer-onboarding.retention-renewed`, with Configuration requiring the policy's duration to exceed the review interval. *Over:* a single placement at intake, or an active-case purge gate composed through Defensible Retention. *Because:* a Retention Window placement is fixed-duration and its policy immutable, so a single placement lawfully lapses under a relationship longer than its duration; a purge gate would protect the record but leave it under no retention obligation at all, and the composition exposes no purge surface to gate.
- **2026-08-29 — The reconciliation is a declared, bounded scan whose pre-check keys on the intent.** *Chose:* onboarding_completion_bound below and the audit horizon above; compensation window and reconciliation cadence declared; the pre-check traversal matched on intent event id rather than on "the same identifying payload". *Over:* a retry-until-lands with an undeclared cadence and a payload-resemblance pre-check. *Because:* the pre-check cannot see an invocation that has not written yet, so a re-emission inside the bound lands a second outcome for one act; and resemblance chooses where a key does not (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*).
- **2026-09-14 — The monitoring schedule and the open-trigger set are derived indexes, not extraction-pending state.** *Chose:* all four indexes classified as derived index, each with a named rebuild, a per-index definition of *miss*, and the same horizon bound; the proposed **Review Schedule** atom kept as `Non-goal 17` rather than as a classification. *Over:* keeping the schedule half flagged extraction-pending, or extending the flag to the open-trigger set for consistency. *Because:* the section titled Composition state in `execution-contract.md` asks one question — is every fact derivable from the constituents' stores through their declared reads — and the spec's own rebuild answered yes for both, in the same subsection that flagged one of them as non-derivable. Two sentences cannot both be the classification, and the Contract's test picks which. The extraction may still be worth making; it is a concept named for someone to own, not a debt riding this composition's classification. Closes the Ledger's `2026-08-26-k` (the flag asserted Pass 2 gates nobody ran) and `2026-08-29-l` (Gate 3 applied unevenly across four elements).
- **2026-09-14 — The external path admits `Unverified` and nothing else.** *Chose:* one guard and one parameterized refusal, [Party Not Admissible], naming the state found. *Over:* keeping the `party-closed` arm and adding a second arm for `Verified` and `Suspended`. *Because:* the prose guarded `Closed` alone, so a `Suspended` admit opened a case with an empty open-trigger set against a suspended party and a `Verified` admit passed the gate with no verification record of this composition's — a hole in the composition's own load-bearing guarantee, reachable from the ordinary external path. A second arm beside `party-closed` would have split one guard's answer across two codes; the fold gives the caller one code and the state it needs.
- **2026-09-14 — state-unavailable is mapped from the seam, not from a constituent arm.** *Chose:* an unanswered constituent read is the state-unavailable of the section titled Step 1 failure in `execution-contract.md`, and Party Identity's declared `invalid-query` arm maps to invalid-request as this composition's own defect. *Over:* continuing to map state-unavailable from Party Identity's `read`. *Because:* that atom's `read` declares two answers — the matching parties, or `invalid-query` — and neither is an unreadable store, so the mapping named a contract the constituent does not have. The gate's fail-closed behaviour is unchanged; what changed is where the page says it comes from.
- **2026-10-20 — The store's guarantees cited, not restated, and an onboarding action's writes one transaction.** *Chose:* Capability requirement 45 citing Execution Contract Store 1 through 4 for the store the three constituents and the four indexes keep their records in; the rules restating what that store guarantees tombstoned to it — the per-party serialization of a state-changing action, a losing transition's answer, the one-invocation hold on a case's open-trigger set, the reconciliation's exclusion from a held case and from a second reconciliation, and the invalid-credential at an outcome, which the one transaction's read of the actor registry forecloses (Concurrency 1, 5, 7, 8, Reconciliation 26, Audit arm 8); and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the reconciliation's run at every process restart and its lower edge, the owed post closure placement and the owed renewal a placement lost between its call and its record left, and the alert on a closed case carrying no post closure placement (Reconciliation 1, 4, 12, 13, 21); the arms for a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing (Audit arm 5, 6, 18); the invocation's own retry of an owed record, its yield and its hand-off (Audit arm 14 through 17); the in-invocation re-query of an indeterminate committing call, the escalation of an indeterminate enroll and the bar on retrying a committing call outside its invocation (Atomic writes 3 through 9, Action wiring 133); the outcome position a storage failure after a committed sibling call answered (Action wiring 18, 101, 126); the scoped retry inside [Clear Review] and a lost clearance's recovery (Action wiring 108 through 110); and the completing closure, whose earlier closure with no record is now only one whose record Audit Trail refused, which the reconciliation records (Action wiring 117, 118, Reconciliation 8). Rules 511 to 478. *Over:* intent, constituent writes and outcome committed one by one, ordered so that a crash between them left a state the composition could name — a committed act with no record, a closed party with no floor, a constituent call whose answer was lost — with a host that serialized each party's actions, an invocation that retried its own record up to the onboarding completion bound, and a reconciliation that waited out that bound, re-queried what the intent fixed, placed what a crash left owed and recorded or closed the rest. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal. Party Identity, Retention Window and Audit Trail each supply their store under Store 1 through 4, and no action here makes an act outside the store, so an action's intent, constituent writes and outcome commit together. The census's question is decided by the ruling's second clause: the intents stay, since an intent is where the caller's credential is validated before any constituent write (Audit arm 1, Invariant 8.1, Check 8.1) and the intent of an attempt a constituent refuses is the evidence the page keeps for the reconciliation to close (Audit arm 7, Reconciliation 7). An Audit Trail refusal at an outcome record still leaves the act committed and its record owed (Audit arm 9, 10, 12), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the per-action answers that report it, the reconciliation's selection of open markers, its re-query on the values the intent fixed, its traversal, recovery intent and recovery outcome under the service identity, its compensation window and the closure floor that window must exceed, the alerts, the escalations and the checks that read an owed or recovered record (Action wiring 34, 65, 74, 78, 92, 93, 103, 128, Audit arm 13, 19, 22 through 25, Composes 16, 17, Reconciliation 3, 5 through 11, 14 through 20, 24, 27 through 31, Capability requirement 24, 26 through 29, 42, Invariant 2.4, 7.3, Atomic writes 10 through 12, Check 2.3, 7.6, 8.3 through 8.6); the onboarding completion bound stays with them, since the closure floor still reads it (Capability requirement 23, 27), and so does Action wiring 51, the trigger path's Audit arm 1, which an Audit Trail refusal of the trigger record still reaches. The four indexes stay derived indexes outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps them, so their rebuild on a miss, their population after the landed record, a clearance's drop of exactly the triggers its record names, and [Close Party]'s not-active for a case whose closure an index has not yet recorded stay (Composition state 7, 9 through 14, 21, 35, Atomic writes 2, Action wiring 64, 75, 104 through 106, 119, 129 through 131, Check 6.3). A renewal Retention Window refuses keeps its answer and its advance, capped below the current placement's cover, so the next review renews the chain (Action wiring 71, 72, 76, Clock semantics 4); the owed renewal was the lost one's. The rebuilds and reproductions read the Event Log's insertion order (Invariant 3.3) and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.
- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 45, Execution Contract Read 1 through 3) and the four rules that restated it for a constituent read the host's I/O never completed deleted to it (Action wiring 41, Action wiring 139, Action wiring 141, Action wiring 154), Term unanswered read with them, and state-unavailable off the signatures of [Initiate Onboarding] and [Trigger Monitoring Review]; rules 478 to 474. *Over:* the page stating for itself what an action answers when a read it makes never answers. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once, and the mapping this page chose on 2026-09-14, an unanswered read answered state-unavailable from the seam, is what Read 1 now says for every specification. [Activity Permitted] keeps state-unavailable on its signature for a case of its own (Action wiring 140): a case entry whose party the database no longer answers for, an answered read the gate fails closed on, which no rule of the contract decides.
- **2026-11-10 — The waits retired: the five acting actions bind seven Recoverable Invocation act kinds.** *Chose:* (Scott, 2026-11-09 9:17 PM Central, "A", and 2026-11-10 7:15 AM Central, the wait ruling, "simple DRY"; the map rounds/co-ri-map-2026-11-10.md, its directions settled under A, 2026-11-10 7:55 AM Central) the five acting actions bind seven act kinds split by the call each waits on — customer-onboarding.enrollment keyed by the enrollment key under the minted-key deviation, customer-onboarding.admission, customer-onboarding.verification, customer-onboarding.adverse-trigger, customer-onboarding.periodic-review, customer-onboarding.clearance and customer-onboarding.closure keyed by the party id, since no constituent record carries the case id, every kind repeatable (A: act kinds split by the wait, G1, G2); what only the trail knows — the case id, the trigger id, the clearance's closed triggers, the closure's open triggers at close, the periodic review's prior placement and every next review due — rides the intent, the outcome carrying only what Party Identity and Retention Window re-derive, and the rebuilds read each closing beside its intent in intent order (G3, G9); the invocation's now injected into Party Identity's and Retention Window's seams as every kind's pairing datum, so the commitment window, the clock offset allowance and Reconciliation 29's bar go and a lost direct-path initiation is recovered through Party Identity's enrollment instant range (G4); the clearance one act, verify and reinstate in one transaction with one outcome, so review-cleared and party-reinstated fold into customer-onboarding.clearance.cleared, the half-clearance and its window, orphan and checks go, and a refused reinstate rolls the verify back (A: kinds split by the wait, G5); every suspend refusal pre-commit, already-suspended among them, closed through the refuse, the trigger records folded into the kind's refused record read by its code, and the caller answered already-suspended (A: codes change to Recoverable Invocation's, G6); an intent whose invocation died before its commit escalated for an operator (A, G7); five collisions the split exposes refused inside the commit by a re-read — already-onboarded and party-not-admissible at the admission, not-verified at the suspension, not-active at the renewal, triggers-changed at the clearance and the closure (A: a collision becomes a refusal, G8; Action wiring 159 through 169) — and the clearance's re-read refusing too while an adverse trigger intent of the case carries no closing, which the re-derived model found: without it a trigger whose intent the clearance named and whose suspend committed after it re-suspends a reinstated party with no open trigger left (Action wiring 165); quiescence restated as no open intent and no standing escalation, an escalated trigger kept open, and an operator's closing detected, not prevented, by Reconciliation 23, 25, 39 and the new 43 (A: detected, not prevented, with an alert, G10); a verification event, state change event or placement no intent carries a write-ownership finding, Composes 20's second writer given a detector (A: a record with no intent becomes a finding, G11); every acting action's caller-visible codes Recoverable Invocation's, storage-failure and registry-unavailable answered as the constituent's, [Initiate Onboarding]'s recording-failure(outcome) carrying the case id (A, G7, G12); the mayor's derivable calls taken as the map recommends: one completion bound re-anchored to Recoverable Invocation's span (G13); `application_actor_ref` renamed the recovery identity (G14); the Bank Secrecy Act alert kept as the page's own, on an open verification intent the sweep examines (G15); the multi-call commit, the in-transaction trail read and the pre-switch cut-over carried as open lines (G16, G8, G21); a new act section host (G17); the model re-derived over the split arc (G18). Capability requirement 24 through 27, 46, 47, Identity 10, 11, 13 through 17, every live Audit arm rule but 19, Action wiring 34, 50, 51, 62, 65, 74, 78, 91 through 94, 102, 103, 119a, 128, 148 through 152, Reconciliation 3, 6 through 11, 14 through 20, 24, 27 through 33, Invariant 2.4, 7.3, 8.1, Check 2.3, 4.4, 7.6, 8.1 through 8.6 and Atomic writes 1 tombstoned to what owns them; Composes 27 through 31, Composition state 51, 52, Capability requirement 48 through 55, Action wiring 155 through 172, Reconciliation 34 through 43, Check 9.6, 10.1, External check 12, 13, Non-goal 22 through 24 and Cross-record consistency 1 new; the closure table drafted. Rules 482 to 449 (84 tombstoned, 91 restated, 51 new). Open lines 2026-11-06-a and 2026-08-29-s dissolve with the rules and the model they named; 2026-11-04-a is carried, sharpened, and 2026-11-04-b carried; 2026-11-10-a through 2026-11-10-e are opened. *Over:* removing the wait by reversing 2026-10-20 at its other end, so that an Audit Trail refusal of any outcome fails the whole action, which every write here being a database write allows, but which would make Audit Trail's health a precondition of every suspension — a deterministic outcome refusal would leave a sanctions-matched party verified and passing the gate; one per-party act kind for every action, which would make a crashed act block the party's every action, a sanctions trigger included, until the sweep closed it; and keeping the page's own reconciliation beside Recoverable Invocation, which would have covered the intent-and-outcome pairing twice. *Because:* the waits were self-made: the 2026-10-20 decision kept an act committed when its outcome record was refused, and the page then built the open markers, the commitment window, the recovery intent and outcome, the compensation window, its cadence, run bound, closure floor and escalation reach to close them, which Recoverable Invocation owns; four of the seven foundational findings of Final Critique 3 through 5 sat in that machinery or in the audit-arm positions Recoverable Invocation's open, close and refuse own, and the one refuted report of Final Critique 5 too. It turns the 2026-08-29 entry (the bounded scan and its intent-keyed pre-check are Recoverable Invocation's) and the 2026-10-20 entry's "so what closes it stays", rule by rule. *Costs:* seven bindings, the instance's bounds and sweep, and a Lease host the page did not have, the database having serialized a party's actions; every acting action's caller-visible codes, already-suspended among them where a second adverse alert was answered recorded; the auditor-visible vocabulary, with the clearance one record and the trigger-on-suspended-party and trigger-voided records folded into a refused record; five re-reads inside the commits, and a clearance refused while an adverse trigger is in flight; operator work for an intent whose invocation died before its commit, which Database 1 had rolled back unseen; a rebuild that reads two vocabularies for a case older than the switch; Invariant 2.1, 4.2, 7.1, 7.2 and 7.5 fall from prevented to detected against an operator's resolve.
- **2026-11-11 — A refused renewal leaves the next review due where it stood.** *Chose:* the periodic review's next review due takes effect once its renewal outcome stands (Action wiring 76, Action wiring 76a, Term schedule-bearing record), as a verification's and a clearance's do. *Over:* advancing it whatever the renewal answered, the earlier wording. *Because:* the intent is written before the renewal and cannot know the cover the renewal will leave, so on a refused renewal, which moves no cover, the derived due could stand past the placement's cover, which Clock semantics 4 forbids; the cost is the scheduler firing the review again at its next pass (open line 2026-11-11-f).

</details>

NOTE: End of Customer Onboarding.
