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

Beyond the gate, the composition guarantees four further emergent properties. Every `Unverified → Verified` transition produces a tamper-evident Audit Trail event carrying the verification identifiers. Every adverse monitoring trigger produces an Audit Trail event ordered before any suspension it precipitates, so no trigger-driven suspension exists in the records without its precipitating trigger ordered ahead of it. A party reinstated after an adverse trigger has a passed verification recorded after the most recent suspend, and the clearing actor — whose credential this composition verifies — attests that the fresh evidence was recorded before the reinstatement. The party record is under a live Retention Window placement at every instant of the relationship — renewed at each periodic review, because a placement is fixed-duration and nothing else renews it — and a closed party's record cannot be purged before its post-closure floor (the BSA/AML five-year period under 31 CFR (Title 31 of the Code of Federal Regulations) §1020.220) elapses.

Its most common uses are retail and commercial bank customer onboarding under BSA/AML, broker-dealer counterparty onboarding, payments-processor merchant onboarding, and crypto-exchange customer onboarding under the EU 5th Anti-Money Laundering Directive (AMLD5). Any system that must prove, from records alone, that every party with regulated activity was verified before that activity, that adverse triggers were acted on, and that closed-party records were retained for the mandated post-closure period, is a candidate for this composition.

---

## Intent

Every financial institution that admits an external customer faces the same regulated arc, and the arc is the same whether the institution is a retail bank, a broker-dealer, a payments processor, or a crypto exchange. The customer's identity must be established and verified before regulated activity begins; the verified status must be the precondition any account-opening, transaction, or service-provisioning system checks; the relationship must be monitored on an ongoing basis so that a sanctions match, a politically-exposed-person (PEP — Politically Exposed Person) status change, or adverse media triggers suspension and re-verification; and when the relationship ends, the identity record and its Customer Due Diligence (CDD) evidence must survive for a regulator-mandated period after closure. FATF (Financial Action Task Force — the international standard-setter for anti-money-laundering and counter-terrorist-financing rules) Recommendations 10–12 name the arc as Customer Due Diligence: identify, verify, conduct ongoing monitoring. BSA/AML (Bank Secrecy Act / Anti-Money Laundering) 31 CFR §1020.220 fixes the record-retention floor at five years after the business relationship ends. The domain varies; the structural obligation is constant.

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
Composes 10: The composition MUST NOT read a constituent's store beside the constituent's declared read.
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
Composes 22: The composition MUST read a placement's policy ref, retained at, retention until AND purge eligibility through Retention Window's declared read.
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

WHY:
Composes 6 and Composes 7 name the substrate relation. [Audit Trail](./audit-trail.md) is a composition, not an atom, so Event Log, Actor Identity, Tamper Evidence and the audit instance's own Retention Window are reached *through* it and this composition holds no instance of any of them — the section titled Substrate composition invocation in `execution-contract.md` is what makes that a declared topology rather than an accident. Composes 8 is where the corpus's *declared multi-instance topology* clause bites twice in one spec: two Retention Window instances exist here, one governing party records and one governing the audit events that record their governance, and much of this composition's evidence story turns on which of the two a sentence means.

Composes 12 through 14 declare the read capability exactly, because the substrate declares no secondary index. Every selection this spec describes — the rebuilds, the reconciliation's comparisons, the acceptance checks — is enumerate-and-filter in composition code over an open-ended sequence range. That range read is one of the two query shapes the substrate passes through; the other is the singleton range the substrate builds from its own index, which no caller reaches. A payload-predicate query is the forthcoming Reverse Index pattern's shape, and a deployment may compose one over the trail as an instance optimization without changing what any procedure here computes.

Composes 15 through 17 split attestation by who is present. Every write an action makes inside its own invocation is attested by the calling operator, whose credential the substrate verifies inside the write. The reconciliation runs when that operator is gone and their credential was never persisted, so a reconciliation write attested as theirs would be a false attribution; it is attested under the service identity with the human named in the payload instead.

Composes 19 and Composes 20 are the write-side half of the gate. [Activity Permitted] reads Party Identity's state, so a party driven to `Verified` by a second writer on a shared instance would pass the gate with no verification record of this composition's — which is Invariant 2's coverage broken from outside, and the mirror of an activity system bypassing the gate. Composes 22 and Composes 23 name the two constituent reads this composition depends on, so a wired instance that does not expose them is a configuration fault an auditor can name rather than a surprise a rebuild discovers.

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
Composition state 16: A rebuild MUST select an event by the event's action_ref.
Composition state 17: A rebuild MUST read an event's action_ref through Audit Trail's read_record.
Composition state 18: A rebuild MUST NOT read an aged-out event's payload.
Composition state 19: A rebuild MUST recognize an aged-out event PER event.
Composition state 20: An entry whose binding-bearing events stand aged out MUST stand unrebuildable.
Composition state 21: An unrebuildable entry MUST NOT stand as a miss.
Composition state 22: The composition MUST alert on an unrebuildable entry.
Composition state 23: The rebuild of the party-to-case index MUST select the initiated events AND the retention renewed events.
Composition state 24: The rebuild of the party-to-case index MUST take the case_id AND the enrollment_path from the latest selected payload PER party id.
Composition state 25: The rebuild of the party-to-case index MUST write the case's active flag set to true ONLY IF no party closed event names the case_id.
Composition state 26: The rebuild of the case-to-monitoring index MUST take the party id from the latest binding-bearing payload PER case_id.
Composition state 27: The rebuild of the case-to-monitoring index MUST take the opened at from the initiated payload.
Composition state 28: The rebuild of the case-to-monitoring index MUST take the next review due from the latest schedule-bearing payload PER case_id.
Composition state 29: The rebuild of the case-to-retentions index MUST take the current placement from the latest placement-bearing payload PER case_id.
Composition state 30: The rebuild of the case-to-retentions index MUST take the post closure placement from the party closed payload.
Composition state 31: The rebuild of the case-to-open-triggers index MUST select the adverse monitoring triggered events PER case_id.
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
Composition state 50: The composition MUST NOT duplicate a constituent's store.
```

Term case-to-monitoring index: case_to_monitoring — the composition's index from a case_id to the case's party id, opened at and [Next Review Due]; the auditor's first query surface for monitoring continuity.

Term party-to-case index: party_to_case — the composition's index from a party id to the party's case_id, enrollment_path and active flag; the gate's first read and the join an auditor makes from an activity record to an onboarding case.

Term active flag: true | false — whether a case is open: true from the case's initiated record, false once a landed party closed record names the case (Composition state 25, Action wiring 130).

Term active case: a case whose active flag EQUALS true.

Term case-to-retentions index: case_to_retentions — the composition's index from a case_id to the current placement and the post closure placement.

Term case-to-open-triggers index: case_to_open_triggers — the composition's index from a case_id to the open adverse triggers standing against the case, each carrying a trigger_id, a trigger_type, a trigger_ref and a triggered at.

Term index: the case-to-monitoring index, the party-to-case index, the case-to-retentions index, OR the case-to-open-triggers index.

Term current placement: the latest active relationship retention the composition placed over a case's party — active_relationship_retention_id.

Term post closure placement: the retention [Close Party] places over the party record at the relationship's end — post_closure_retention_id.

Term audit horizon: the age past which the audit instance has destroyed an event's payload, set by the instance's audit_trail_retention_policy.

Term aged-out event: an event whose age exceeds the audit horizon.

Term rebuild: the composition's named regeneration of an index — select this composition's events over an open-ended sequence range, keep the events the index names by action_ref, and take the index's fields from their payloads in Event Log order.

Term miss: an index read the composition answers by rebuilding rather than by the stored value.

Term unrebuildable entry: an index entry every one of whose binding-bearing events stands aged out.

Term binding-bearing payload: an initiated payload OR a retention renewed payload — the two that carry a case's case_id, party id and enrollment_path.

Term schedule-bearing payload: an initiated payload, a verification recorded payload carrying a next review due, a monitoring triggered payload carrying a next review due, OR a party reinstated payload.

Term placement-bearing payload: an initiated payload OR a retention renewed payload.

Term landed record: an audit record the substrate has appended and attested, whatever the substrate then answered.

Term owed record: an audit record this composition must write and the substrate has not appended.

WHY:
**All four indexes are derived, and Composition state 5 is a correction the migration makes rather than a restatement.** The prose flagged the monitoring schedule's opened at and [Next Review Due] as *extraction-pending* against a proposed Review Schedule atom, and in the next breath stated that every schedule-writing action stamps its result into its own audit event and that the current deadline is the latest such payload in Event Log order. Those two sentences cannot both be the classification. The section titled Composition state in `execution-contract.md` asks one question — *is every fact in this element fully derivable, at any time, from the constituents' stores through their declared read surfaces?* — and the spec's own rebuild answers yes. So the schedule is a derived index on the Contract's own test, bounded by the horizon exactly as the case binding is, and the same reading settles the open-trigger set: its whole lifecycle — raised, voided, cleared, swept at closure — rides audit events, so it is derived too, and the three-elements-derived / one-element-pending split the page carried was an inconsistency rather than a distinction. A Review Schedule atom may still be worth extracting; that is a concept the corpus may take up, and it is named in Non-goals rather than asserted here as a classification the rebuild contradicts.

Composition state 10 through 14 define *miss* per index, which the prose left to a reader's judgment. The distinction that matters is between an entry that says nothing and an entry that says *nothing yet*: an empty open-trigger set is the answer *no investigation stands*, a false active flag is the answer *this case closed*, and an absent post closure placement is the answer *this case has not closed* — none of them a gap a rebuild should fill. A missing entry, or an entry carrying no value for the field being read, is the gap.

Composition state 18 through 22 are the horizon's edge, stated once for every index. Past the horizon the substrate has destroyed an event's `data` in its entirety while the attestation keeps action_ref, actor_ref and `attested_at` readable, so an enumeration still *recognizes* an aged-out customer-onboarding event by class and can no longer read the case_id, party id or ids its payload carried. Recognition is therefore per event through the substrate's own read, not a property of the range read. What that costs is the one-active-case relation: a party whose entry is unrebuildable reads as never onboarded, and [Initiate Onboarding] would open a second active case for a party that already has one, with both cases thereafter legitimate-looking. case_id has no second source — Party Identity holds the party, not the case — so the cure is the ordering obligation in Capability requirement rather than a fallback read, and Composition state 22's alert is what keeps the loss visible instead of silent.

Composition state 23 and Composition state 24 are why the loss is bounded by a *review cadence* rather than by the relationship. Every renewal re-carries the binding, so an active case always has a binding-bearing event younger than one monitoring interval, and a closed case needs its last renewal or its closure event to survive the post-closure floor. An earlier draft compared the horizon against one placement's duration, which bounds nothing: the relationship is a chain of placements as long as the customer stays, and the page's own walkthrough — a nine-year horizon over an eleven-year relationship — satisfied that comparison and still lost the binding two years before closure.

Composition state 35 is the map-population-after-event discipline stated once for all four indexes, where the prose stated it three times and broke it twice — case_to_retentions was populated at [Close Party] before the closure event landed, and the renewal repointed before its own event landed. An index populated ahead of its record is an index a rebuild disagrees with, and the rebuild is the thing an auditor runs.

Composition state 36 through 43 are the cardinality and modality the relations carry, which the prose declared for one relation and left implicit for three. Composition state 44 and Composition state 45 are the referential-integrity template of the section titled Structural-relation invariant templates in `spec-format.md`, applied to the two indexes that point into a constituent's store.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The host MUST supply a case_id at the seam PER admitted initiation.
Capability requirement 3: The host MUST supply a trigger_id at the seam PER admitted trigger.
Deleted: Capability requirement 4. Execution Contract Logic confinement 3 owns it.
Capability requirement 5: The transition MUST NOT mint an id.
Deleted: Capability requirement 6. Execution Contract Logic confinement 3 owns it.
Capability requirement 7: The composition MUST NOT mint a party id.
Capability requirement 8: The composition MUST NOT mint a verification id.
Capability requirement 9: The composition MUST NOT mint a state change id.
Capability requirement 10: The composition MUST NOT mint a retention id.
Capability requirement 11: The composition MUST NOT mint an event_id.
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
Capability requirement 35: The party retention instance MUST serve a placement read carrying the policy ref, the retained at, the retention until AND the purge eligibility.
Capability requirement 36: The Party Identity instance MUST serve a singleton read by party id.
Capability requirement 37: A deployment MUST resolve a policy ref at Retention Window's seam.
Capability requirement 38: The composition MUST NOT reconcile two policies.
Capability requirement 39: An activity system MUST NOT read the Party Identity instance.
Capability requirement 40: A deployment MUST run a review scheduler outside the composition.
Capability requirement 41: The composition MUST NOT fire a review.
Capability requirement 42: A deployment under the Bank Secrecy Act and Anti-Money Laundering rules MUST alert on an owed record.
Capability requirement 43: A deployment MUST NOT set the monitoring interval PER party at this composition.
Deleted: Capability requirement 44. Execution Contract Logic confinement 7 owns it.
```

Term seam: the composition's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects one clock reading, one case_id and one trigger_id here.
Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term transition: the composition's evaluation of one call against the constituents, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term monitoring interval: monitoring_interval — the deployment's declared duration between a party's periodic reviews.

Term scheduler tolerance: scheduler_tolerance — the deployment's declared allowance for how late the external scheduler may fire a due review.

Term renewal floor: `monitoring_interval + scheduler_tolerance` — the interval a placement's duration must outlast for the chain to stay continuous under a late review.

Term binding floor: the monitoring interval taken with the scheduler tolerance and the post closure policy's duration — the age a binding-bearing event's payload must survive to.

Term closure floor: `onboarding_completion_bound + reconciliation_cadence + audit write latency` — the longest interval in which the reconciliation can close an open marker.

Term onboarding completion bound: onboarding_completion_bound — the deployment's declared maximum duration between an invocation's intent and the invocation's outcome, read against the injected now the intent carries.

Term active relationship policy: active_relationship_policy_ref — the deployment's recommended Retention Window policy for a live relationship's party record.

Term post closure policy: post_closure_retention_policy_ref — the Retention Window policy [Close Party] applies.

Term post closure minimum: the applicable regulatory floor on a closed party's record — five years after the relationship ends under BSA/AML 31 CFR §1020.220.

Term adverse trigger types: adverse_trigger_types — the deployment's set of trigger_type values that drive suspension; canonically sanctions-match | pep-status-change | adverse-media.

Term periodic trigger type: periodic-review-due — the one non-adverse trigger_type.

Term trigger set cap: trigger_set_cap — the deployment's declared maximum number of open triggers a payload carries in full.

Term field cap: the deployment's declared maximum size of one audit payload field.

WHY:
Capability requirement 14 is the ordering the whole rebuild story rests on. The party-to-case binding is re-carried by every renewal, so the horizon must outlast one review cadence with the scheduler's lateness allowed for, and — for a closed case — the post-closure floor, because a closed case takes no further reviews and its last binding-bearing event is the closure. All three values are this composition's own configuration, so the comparison is one an auditor makes from the deployment's declared knobs rather than from a vendor's assurance.

Capability requirement 20 is the duration obligation stated as the strict lower bound it is. The placement is renewed only when a periodic review fires, so a policy no longer than the review interval lapses between reviews and a live customer's CDD record becomes purge-eligible while the relationship is active. The obligation is sufficient only because every schedule advance is capped below the current placement's cover (Clock semantics): an advance that ignored the placement — a verification pass months after intake, a clearance after a long suspension — would push the first renewal past the cover no matter how the two durations compared. This composition cannot read a policy's duration, so the obligation is cleared externally (External check 5) while the chain the obligation protects is records-alone checkable (Check 4.2).

Capability requirement 27 is the liveness arithmetic written out. An open marker is invisible to the reconciliation until the onboarding completion bound has passed, the reconciliation then sees it no sooner than the next cadence, and the record it writes takes the audit write latency to land — so a compensation window shorter than that sum is a promise the deployment cannot keep, and the rule refuses the instance rather than the finding.

Capability requirement 32 is the repair for a payload that had no bound. [Clear Review]'s clearance intent and clearance record and [Close Party]'s closure record each embed the case's open-trigger set verbatim, and nothing capped it — so a long investigation accumulating triggers could produce a closure event the substrate refuses with invalid-request, which is the one arm that cannot recur-and-clear. Past the cap the payload carries the trigger count and a digest of the set, and the full set stays reconstructable from the monitoring triggered events the range read returns.

Capability requirement 39 is the deployment half of the gate, and it is an obligation rather than advice. If each activity system reads Party Identity and applies its own `Verified` check, the gate is re-implemented per system, and the first system that forgets it, reads a stale state, or applies a subtly different predicate breaks the before-activity guarantee silently and per-system. Centralizing it at [Activity Permitted] makes the guarantee exist exactly once; a deployment that bypasses it is a composition-bypass finding, and Invariant 1.3 is where the property is quantified.

Capability requirement 40 and Capability requirement 41 keep the scheduler out. The composition holds the schedule *state* and is not the scheduling *engine* — it sets no timer, fires on no clock and owns no cadence policy. An external scheduler reads [Next Review Due] and the case's active flag and calls [Trigger Monitoring Review] when a review is due.

### Primitive policy

```
Primitive policy 1: An action MUST call a constituent ONLY AFTER the boundary predicate.
Primitive policy 2: The boundary predicate MUST refuse a blank opaque input.
Primitive policy 3: The boundary predicate MUST refuse a blank actor reference.
Primitive policy 4: The boundary predicate MUST refuse a blank method.
Primitive policy 5: The boundary predicate MUST refuse a blank evidence ref.
Primitive policy 6: The boundary predicate MUST refuse a blank reason.
Primitive policy 7: The boundary predicate MUST refuse a trigger_type outside the trigger vocabulary.
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
Primitive policy 21: The boundary predicate MUST refuse a blank retention_policy_ref.
```


Term boundary predicate: the composition's own validation of an input at an action's boundary, judged before any constituent call.

Term opaque input: party id | case_id | trigger_id | trigger_ref | actor_ref | verifying actor ref | closing_actor_ref | credential | retention_policy_ref.

Term actor reference: actor_ref | verifying actor ref | closing_actor_ref | enrolling actor ref.

Term trigger vocabulary: the periodic trigger type OR a member of the adverse trigger types.

Term verification results: passed | failed.

Term truncation marker: the marker a payload field carries when the composition has cut the field to the field's cap.

Term set digest: a content-derived summary of an open-trigger set, standing in the payload where the set itself exceeds the trigger set cap.

WHY:
Primitive policy 1 is the ordering the whole rejection story rests on, and it has an observable consequence the page states rather than leaves to be found: because the boundary predicate and the cheap index reads sit *before* the intent record, not-known, not-active, already-onboarded, party-not-known, party-not-admissible, no-open-trigger, the trigger pre-check's own arms and every shape failure are answered without the credential ever being verified. That is deliberate — it keeps an unknown case_id free of any audit event and avoids attributing events to cases that do not exist — and an auditor asking *was every refusal authenticated?* gets *no, by design*.

Primitive policy 9 is enforced before the trigger is recorded, so an over-long trigger_ref can never produce a recorded trigger whose suspend is doomed to reject. The cap it enforces is the constituent's, not a second one this composition invents; Primitive policy 17 says so, because two caps on one field is the shape that drifts.

Primitive policy 10 through 13 keep every identifier opaque. A deployment wanting normalization wires it at the calling layer, before it invokes an action here — normalizing at this boundary would make two callers' spellings of one reference resolve to one party in this composition and two in the constituent.

### Identity

```
Identity 1: A case MUST carry a case_id.
Identity 2: The seam MUST allocate a case_id.
Identity 3: A case_id MUST stand immutable.
Identity 4: The composition MUST NOT reuse a case_id.
Identity 5: A trigger MUST carry a trigger_id.
Identity 6: The seam MUST allocate a trigger_id.
Identity 7: A trigger_id MUST stand immutable.
Identity 8: The composition MUST NOT reuse a trigger_id.
Identity 9: An intent MUST carry the case_id.
Identity 10: An intent MUST carry the invocation's inputs.
Identity 11: An intent MUST NOT carry a constituent-minted id.
Identity 12: An intent MUST carry the injected now as intended at.
Identity 13: An outcome MUST carry the intent's event_id as intent event id.
Identity 14: The composition MUST pair an outcome to an intent by the intent event id.
Identity 15: The composition MUST NOT pair an outcome to an intent by a payload resemblance.
Identity 16: The composition MUST NOT pair an outcome to an intent by the case_id.
Identity 17: A trigger path's intent event id MUST name the monitoring triggered event.
Identity 18: A case MUST NOT identify a party.
Identity 19: A party id MUST NOT identify a case.
```

Term intended at: the instant an intent records (Identity 12).

Term intent event id: the event_id the substrate answers for an intent, carried by the outcome paired to it (Identity 13, Identity 14).

Term opened at: the instant an initiated outcome records (Action wiring 146).

Term triggered at: the instant a monitoring triggered outcome records (Action wiring 147).

Term suspended at: the instant a party suspended outcome records (Action wiring 148).

Term renewed at: the instant a retention renewed outcome records (Action wiring 149).

Term cleared at: the instant a review cleared outcome records (Action wiring 150).

Term reinstated at: the instant a party reinstated outcome records (Action wiring 151).

Term closed at: the instant a party closed outcome records — a committing closure's injected now, or the instant Party Identity's read answers for a completing closure (Action wiring 118, Action wiring 152).

Term intent: the record_action call naming what an invocation is about to do, written before any committing call — `customer-onboarding.initiation-intended` | `customer-onboarding.verification-intended` | `customer-onboarding.clearance-intended` | `customer-onboarding.closure-intended` | `customer-onboarding.monitoring-triggered` | `customer-onboarding.recovery-intended`.

Term outcome: the record_action call naming what an invocation did — `customer-onboarding.initiated` | `customer-onboarding.verification-recorded` | `customer-onboarding.party-suspended` | `customer-onboarding.trigger-on-suspended-party` | `customer-onboarding.trigger-voided` | `customer-onboarding.retention-renewed` | `customer-onboarding.review-cleared` | `customer-onboarding.party-reinstated` | `customer-onboarding.party-closed`.

Term committing call: `PartyIdentity.enroll` | `PartyIdentity.verify` | `PartyIdentity.suspend` | `PartyIdentity.reinstate` | `PartyIdentity.close` | `RetentionWindow.place_under_retention` — a constituent call that writes outside the audit instance.

WHY:
Identity 2 and Identity 6 put both of this composition's own ids at the seam, which is what lets an intent name its own case before any constituent id exists. Identity 13 through 16 are the pairing rule, and the distinction they draw was the first thing an earlier acceptance check got wrong: case_id is per-case and three of these actions are repeatable against one case, so a case_id-plus-actor match is satisfied by a single stale intent standing in front of an unbounded number of later outcomes, and an implementation emitting one intent per case and skipping it thereafter would pass. Matching on the id the intent record itself minted admits no such reading, and it is the frozen rule *Intents pair with outcomes by an invocation identity* applied at this seam.

Identity 17 is why [Trigger Monitoring Review] needs no separate intent: its monitoring-triggered write already precedes the adverse path's `suspend` and the periodic path's renewal, so that record *is* the invocation's intent and carries the intent arms.

### Audit arm

```
Audit arm 1: An invocation MUST make a committing call ONLY AFTER the landed intent.
Audit arm 2: IF Audit Trail answers invalid-credential at an intent THEN the action MUST answer invalid-credential.
Audit arm 3: IF Audit Trail answers invalid-request at an intent THEN the action MUST answer invalid-request.
Audit arm 4: IF Audit Trail answers recording-failure at an intent THEN the action MUST answer recording-failure carrying intent.
Audit arm 5: IF Audit Trail answers recording-failure carrying the retention step at an intent THEN the invocation MUST NOT make a committing call.
Audit arm 6: IF Audit Trail answers recording-failure carrying the retention step at an intent THEN the invocation MUST NOT retry the intent.
Audit arm 7: The composition MUST leave an appended intent standing as an open marker.
Audit arm 8: IF Audit Trail answers invalid-credential at an outcome THEN the action MUST answer recording-failure carrying outcome.
Audit arm 9: IF Audit Trail answers invalid-request at an outcome THEN the action MUST answer recording-failure carrying outcome.
Audit arm 10: IF Audit Trail answers recording-failure at an outcome THEN the action MUST answer recording-failure carrying outcome.
Audit arm 11: A caller MUST read recording-failure carrying intent as a committed nothing.
Audit arm 12: A caller MUST read recording-failure carrying outcome as a committed act.
Audit arm 13: A caller MUST NOT retry an action answering recording-failure carrying outcome.
Audit arm 14: An invocation MUST retry an owed record WITHIN the onboarding completion bound.
Audit arm 15: A yielded invocation MUST NOT retry an owed record.
Audit arm 16: The reconciliation MUST own a yielded invocation's owed record.
Audit arm 17: An invocation MUST NOT retry an owed record BEFORE the outcome traversal.
Audit arm 18: The composition MUST NOT retry Audit Trail's retention step arm.
Audit arm 19: The composition MUST alert on an owed record.
Audit arm 20: The composition MUST NOT read an invalid-request answer as a transient fault.
Audit arm 21: The composition MUST read an invalid-request answer as a deployment fault.
Audit arm 22: A recovery outcome MUST carry the recovery marker.
Audit arm 23: A recovery outcome MUST name the acting human in the outcome's data.
```

Term landed intent: the invocation's intent the substrate has appended and attested and answered.

Term open marker: an intent carrying no outcome under the intent's own intent event id — an invocation that committed nothing, committed and failed to record, or died between the two.

Term outcome traversal: the composition's read of the trail over an open-ended sequence range for an outcome carrying a named intent event id, taken before any compensating write.

Term yielded invocation: an invocation whose age exceeds the onboarding completion bound — past which the invocation stops retrying and the owed record is the reconciliation's.

Term recovery marker: recovery — the marker a recovery outcome carries so a reader tells a clean act from a recovered one.

Term recovery outcome: the outcome the reconciliation emits for a committed act whose own invocation did not record one.

WHY:
The substrate answers one taxonomy — invalid-credential, invalid-request, `recording-failure(step)` — and this composition maps it **by the call's position relative to the constituent write**, not uniformly. At an intent nothing has committed, so every arm is a clean pre-state rejection and the caller may retry the whole action. At an outcome a constituent write exists, so no arm can refuse the act, only report it, and a re-run would commit it a second time. Audit arm 11 through 13 are that distinction exported: intent tells the caller nothing committed, outcome tells the caller an act exists and the reconciliation owns the record — the frozen rule *A composition's own rejection arm carries the retry bit*.

Audit arm 5 through 7 are the one arm that is neither. The substrate's retention step refuses *after* the event is appended and attested, so the credential was verified and the call still failed: the invocation aborts with nothing committed, and the appended intent stands as an open marker the reconciliation will resolve. Re-recording it would double-append, which is why Audit arm 18 sends that arm to the substrate's own reconciliation rather than retrying it here.

Audit arm 14 through 17 bound the retry at both ends. Inside the completion bound the owed record is the invocation's, because the reconciliation cannot see an invocation that has not written yet and a re-emission fired at it would land a second outcome for one act. Past it the record is the reconciliation's, and every compensating write is preceded by a traversal for an outcome already carrying this intent event id — matched by equality, never by resemblance of payload.

The cost is stated rather than hidden: audit-event volume rises by roughly one event per state-changing invocation, so audit_trail_retention_policy governs proportionally more events and each seal covers proportionally more entries.

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
  refuses invalid-request | invalid-credential | not-known | not-active | not-verified(state) | state-unavailable | recording-failure(position)

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

Term position: intent | outcome — the record a write lands: the intent or the outcome.

```
Action wiring 1: [Initiate Onboarding] MUST answer invalid-request for a call carrying a party id AND enrollment fields.
Action wiring 2: [Initiate Onboarding] MUST answer invalid-request for a call carrying no party id AND no enrollment fields.
Action wiring 3: [Initiate Onboarding] MUST answer invalid-request for an unset monitoring interval.
Action wiring 4: An external path call MUST read the party through Party Identity's declared read.
Action wiring 5: IF no party EXISTS for the party id THEN [Initiate Onboarding] MUST answer party-not-known.
Action wiring 6: IF the party's state IS NOT IN the admissible states THEN [Initiate Onboarding] MUST answer party-not-admissible carrying the state.
Action wiring 7: IF an active case EXISTS for the party THEN [Initiate Onboarding] MUST answer already-onboarded.
Action wiring 8: An admitted initiation MUST record an initiation intent.
Action wiring 9: A direct path initiation MUST NOT carry a party id on the initiation intent.
Action wiring 10: A direct path initiation MUST call Party Identity's enroll with the enrollment fields.
Action wiring 11: IF Party Identity answers invalid-request for an enroll THEN [Initiate Onboarding] MUST answer enrollment-failed carrying invalid-request.
Action wiring 12: IF Party Identity answers storage-failure for an enroll THEN [Initiate Onboarding] MUST answer enrollment-failed carrying storage-failure.
Action wiring 13: An admitted initiation MUST call Retention Window's place_under_retention with the party id AND the retention_policy_ref.
Action wiring 14: An admitted initiation MUST NOT substitute the active relationship policy for the retention_policy_ref.
Action wiring 15: IF Retention Window answers invalid-policy for an initiation THEN [Initiate Onboarding] MUST answer invalid-request.
Action wiring 16: IF Retention Window answers policy-not-found for an initiation THEN [Initiate Onboarding] MUST answer invalid-request.
Action wiring 17: IF Retention Window answers storage-failure for an external path initiation THEN [Initiate Onboarding] MUST answer recording-failure carrying intent.
Action wiring 18: IF Retention Window answers storage-failure for a direct path initiation THEN [Initiate Onboarding] MUST answer recording-failure carrying outcome.
Action wiring 19: An admitted initiation MUST record an initiated outcome carrying the case_id, the party id, the enrollment_path, the current placement, the opened at AND the next review due.
Action wiring 20: An admitted initiation MUST answer the case_id.
Action wiring 21: The composition MUST read the case-to-monitoring index at [Record Verification].
Action wiring 22: IF no case EXISTS for the case_id THEN [Record Verification] MUST answer not-known.
Action wiring 23: IF the case's active flag EQUALS false THEN [Record Verification] MUST answer not-active.
Action wiring 24: An admitted verification MUST record a verification intent.
Action wiring 25: An admitted verification MUST call Party Identity's verify with the party id, the verifying actor ref, the method, the verification result AND the evidence ref.
Action wiring 26: IF Party Identity answers already-closed for a verify THEN [Record Verification] MUST answer already-closed.
Action wiring 27: IF Party Identity answers not-known for a verify THEN [Record Verification] MUST answer recording-failure carrying intent.
Action wiring 28: IF Party Identity answers storage-failure for a verify THEN [Record Verification] MUST answer recording-failure carrying intent.
Action wiring 29: An admitted verification MUST record a verification recorded outcome carrying the case_id, the party id, the verification id, the state change id AND the verification result.
Action wiring 30: A transitioning verification MUST carry the next review due on the verification recorded outcome.
Action wiring 31: A verification carrying no state change id MUST NOT carry a next review due on the verification recorded outcome.
Action wiring 32: A transitioning verification MUST advance the next review due.
Action wiring 33: A verification carrying no state change id MUST NOT advance the next review due.
Action wiring 34: IF the verification recorded record fails THEN [Record Verification] MUST answer recording-failure carrying outcome.
Action wiring 35: An admitted verification MUST answer recorded.
Action wiring 36: A reader MUST NOT read recorded as a verified state.
Action wiring 37: The composition MUST read the case-to-monitoring index at [Trigger Monitoring Review].
Action wiring 38: IF no case EXISTS for the case_id THEN [Trigger Monitoring Review] MUST answer not-known.
Action wiring 39: IF the case's active flag EQUALS false THEN [Trigger Monitoring Review] MUST answer not-active.
Action wiring 40: The composition MUST read the party through Party Identity's declared read at [Trigger Monitoring Review].
Action wiring 41: IF the read stands unanswered THEN [Trigger Monitoring Review] MUST answer state-unavailable.
Action wiring 42: IF Party Identity answers invalid-query THEN [Trigger Monitoring Review] MUST answer invalid-request.
Action wiring 43: The composition MUST read an invalid-query answer as the composition's own defect.
Action wiring 44: IF the trigger_type belongs to the adverse trigger types AND the party's state IS NOT IN the suspendable states THEN [Trigger Monitoring Review] MUST answer not-verified carrying the state.
Action wiring 45: A periodic trigger MUST NOT refuse a party's state.
Action wiring 46: An admitted trigger MUST record a monitoring triggered outcome carrying the case_id, the party id, the trigger_id, the trigger_type, the trigger_ref AND the triggered at.
Action wiring 47: An admitted periodic trigger against an unsuspended party MUST carry the next review due on the monitoring triggered record.
Action wiring 48: An admitted trigger against a suspended party MUST NOT carry a next review due on the monitoring triggered record.
Action wiring 49: An adverse trigger MUST NOT carry a next review due on the monitoring triggered record.
Action wiring 50: IF the monitoring triggered record fails THEN [Trigger Monitoring Review] MUST answer recording-failure carrying intent.
Action wiring 51: IF the monitoring triggered record fails THEN the invocation MUST NOT make a committing call.
Action wiring 52: An adverse trigger MUST call Party Identity's suspend with the party id, the actor_ref AND the composed suspend reason.
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
Action wiring 63: A suspending trigger MUST record a party suspended outcome carrying the case_id, the party id, the trigger_id, the trigger_type, the trigger_ref, the state change id AND the suspended at.
Action wiring 64: A suspending trigger MUST add the trigger to the open-trigger set whatever the party suspended record's answer.
Action wiring 65: IF the party suspended record fails THEN [Trigger Monitoring Review] MUST answer recording-failure carrying outcome.
Action wiring 66: A periodic trigger MUST read the current placement's policy ref through Retention Window's declared read.
Action wiring 67: A periodic trigger MUST call Retention Window's place_under_retention with the party id AND the current placement's policy ref.
Action wiring 68: A periodic trigger MUST renew the placement whatever the party's state.
Action wiring 69: A periodic trigger MUST renew the placement whatever the current placement's remaining cover.
Action wiring 70: IF Retention Window answers storage-failure for a renewal THEN [Trigger Monitoring Review] MUST answer recording-failure carrying intent.
Action wiring 71: IF Retention Window answers invalid-policy for a renewal THEN [Trigger Monitoring Review] MUST answer invalid-request.
Action wiring 72: IF Retention Window answers policy-not-found for a renewal THEN [Trigger Monitoring Review] MUST answer invalid-request.
Action wiring 73: A renewing trigger MUST record a retention renewed outcome carrying the case_id, the party id, the enrollment_path, the trigger_id, the prior placement, the renewed placement, the policy ref AND the renewed at.
Action wiring 74: IF the retention renewed record fails THEN [Trigger Monitoring Review] MUST answer recording-failure carrying outcome.
Action wiring 75: A renewing trigger MUST repoint the case-to-retentions index ONLY AFTER the landed retention renewed record.
Action wiring 76: A periodic trigger against an unsuspended party MUST advance the next review due whatever the renewal's answer.
Action wiring 77: A periodic trigger against a suspended party MUST NOT advance the next review due.
Action wiring 78: The reconciliation MUST match a renewal recovery on the trigger_id.
Action wiring 79: An admitted trigger MUST answer recorded.
```
```
Action wiring 80: The composition MUST read the case-to-monitoring index at [Clear Review].
Action wiring 81: IF no case EXISTS for the case_id THEN [Clear Review] MUST answer not-known.
Action wiring 82: IF the open-trigger set stands empty THEN [Clear Review] MUST answer no-open-trigger.
Action wiring 83: An admitted clearance MUST record a clearance intent carrying the open-trigger set.
Action wiring 84: An admitted clearance MUST call Party Identity's verify with the party id, the verifying actor ref, the method, passed AND the evidence ref.
Action wiring 85: An admitted clearance MUST NOT call Party Identity's verify with failed.
Action wiring 86: IF Party Identity answers already-closed for a clearance verify THEN [Clear Review] MUST answer already-closed.
Action wiring 87: IF Party Identity answers not-known for a clearance verify THEN [Clear Review] MUST answer not-known.
Action wiring 88: IF Party Identity answers invalid-request for a clearance verify THEN [Clear Review] MUST answer invalid-request.
Action wiring 89: IF Party Identity answers storage-failure for a clearance verify THEN [Clear Review] MUST answer recording-failure carrying intent.
Action wiring 90: An admitted clearance MUST record a review cleared outcome carrying the case_id, the party id, the verification id, the closed triggers, the reason AND the cleared at.
Action wiring 91: A review cleared outcome MUST NOT carry a next review due.
Action wiring 92: IF the review cleared record fails THEN [Clear Review] MUST answer recording-failure carrying outcome.
Action wiring 93: IF the review cleared record fails THEN the invocation MUST NOT call Party Identity's reinstate.
Action wiring 94: An admitted clearance MUST call Party Identity's reinstate ONLY AFTER the landed review cleared record.
Action wiring 95: An admitted clearance MUST call Party Identity's reinstate with the party id, the actor_ref AND the reason.
Action wiring 96: IF Party Identity answers no-passed-verification-since-suspend for a reinstate THEN [Clear Review] MUST answer verification-failed.
Action wiring 97: IF Party Identity answers not-suspended for a reinstate THEN [Clear Review] MUST answer verification-failed.
Action wiring 98: IF Party Identity answers already-closed for a reinstate THEN [Clear Review] MUST answer already-closed.
Action wiring 99: IF Party Identity answers not-known for a reinstate THEN [Clear Review] MUST answer not-known.
Action wiring 100: IF Party Identity answers invalid-request for a reinstate THEN [Clear Review] MUST answer invalid-request.
Action wiring 101: IF Party Identity answers storage-failure for a reinstate THEN [Clear Review] MUST answer recording-failure carrying outcome.
Action wiring 102: An admitted clearance MUST record a party reinstated outcome carrying the case_id, the party id, the state change id, the reinstated at AND the next review due.
Action wiring 103: IF the party reinstated record fails THEN [Clear Review] MUST answer recording-failure carrying outcome.
Action wiring 104: An admitted clearance MUST drop the closed triggers from the open-trigger set ONLY AFTER the landed party reinstated record.
Action wiring 105: An admitted clearance MUST drop exactly the closed triggers the review cleared record names.
Action wiring 106: An admitted clearance MUST NOT empty the open-trigger set.
Action wiring 107: An admitted clearance MUST advance the next review due to the party reinstated record's next review due.
Action wiring 108: A scoped retry MUST stand inside the retrying invocation.
Action wiring 109: A scoped retry MUST NOT cross a process boundary.
Action wiring 110: A lost invocation's recovery MUST stand as a fresh [Clear Review].
Action wiring 111: An admitted clearance MUST answer cleared.
Action wiring 112: The composition MUST read the case-to-monitoring index at [Close Party].
Action wiring 113: IF no case EXISTS for the case_id THEN [Close Party] MUST answer not-known.
Action wiring 114: IF the case's active flag EQUALS false THEN [Close Party] MUST answer not-active.
Action wiring 115: An admitted closure MUST record a closure intent.
Action wiring 116: An admitted closure MUST call Party Identity's close with the party id, the closing_actor_ref AND the reason.
Action wiring 117: IF Party Identity answers already-closed for a close AND no party closed event names the case THEN the invocation MUST complete the earlier closure.
Action wiring 118: A completing closure MUST read the state change id AND the closed at from Party Identity's declared read.
Action wiring 119: IF Party Identity answers already-closed for a close AND a party closed event names the case THEN [Close Party] MUST answer not-active.
Action wiring 120: IF Party Identity answers not-known for a close THEN [Close Party] MUST answer not-known.
Action wiring 121: IF Party Identity answers invalid-request for a close THEN [Close Party] MUST answer invalid-request.
Action wiring 122: IF Party Identity answers storage-failure for a close THEN [Close Party] MUST answer recording-failure carrying intent.
Action wiring 123: An admitted closure MUST call Retention Window's place_under_retention with the party id AND the post closure policy.
Action wiring 124: IF Retention Window answers invalid-policy for a closure THEN [Close Party] MUST answer invalid-request.
Action wiring 125: IF Retention Window answers policy-not-found for a closure THEN [Close Party] MUST answer invalid-request.
Action wiring 126: IF Retention Window answers storage-failure for a closure THEN [Close Party] MUST answer recording-failure carrying outcome.
Action wiring 127: An admitted closure MUST record a party closed outcome carrying the case_id, the party id, the state change id, the post closure placement, the reason, the closed at AND the open triggers at close.
Action wiring 128: IF the party closed record fails THEN [Close Party] MUST answer recording-failure carrying outcome.
Action wiring 129: An admitted closure MUST populate the case-to-retentions index's post closure placement ONLY AFTER the landed party closed record.
Action wiring 130: An admitted closure MUST write the case's active flag set to false ONLY AFTER the landed party closed record.
Action wiring 131: An admitted closure MUST empty the open-trigger set ONLY AFTER the landed party closed record.
Action wiring 132: An admitted closure MUST answer closed.
Action wiring 133: A caller MUST NOT retry a committing call across an invocation.
Action wiring 134: The composition MUST read the party-to-case index at [Activity Permitted].
Action wiring 135: IF the party id IS NOT IN the party-to-case index THEN [Activity Permitted] MUST answer not-known.
Action wiring 136: The composition MUST read the party through Party Identity's declared read at [Activity Permitted].
Action wiring 137: IF the party's state EQUALS verified THEN [Activity Permitted] MUST answer permitted.
Action wiring 138: IF the party's state DOES NOT EQUAL verified THEN [Activity Permitted] MUST answer not-verified carrying the state.
Action wiring 139: IF the read stands unanswered THEN [Activity Permitted] MUST answer state-unavailable.
Action wiring 140: IF the read answers no party THEN [Activity Permitted] MUST answer state-unavailable.
Action wiring 141: [Activity Permitted] MUST NOT answer permitted for an unanswered read.
Action wiring 142: [Activity Permitted] MUST NOT write.
Action wiring 143: [Activity Permitted] MUST NOT record an audit event.
Action wiring 144: [Activity Permitted] MUST NOT read a clock.
Action wiring 145: [Activity Permitted] MUST NOT compare a timestamp.
```

Term party state: [Party Identity](../atoms/party-identity.md)'s declared lifecycle states, cited rather than restated.

Term admissible states: unverified — the one party state an external path initiation admits.

Term suspendable states: verified | suspended — the party states an adverse trigger's suspend may reach.

Term unanswered read: a constituent read the host's I/O did not complete, which the section titled Step 1 failure in `execution-contract.md` names state-unavailable.

Term admitted initiation: an [Initiate Onboarding] call whose boundary predicate passed, whose party stands admissible and whose intent landed.

Term admitted verification: a [Record Verification] call whose boundary predicate passed, whose case's active flag EQUALS true and whose intent landed.

Term admitted trigger: a [Trigger Monitoring Review] call whose boundary predicate passed, whose case's active flag EQUALS true and whose pre-check admitted the trigger_type against the party's state.

Term admitted clearance: a [Clear Review] call whose boundary predicate passed, whose case carries an open trigger and whose intent landed.

Term admitted closure: a [Close Party] call whose boundary predicate passed, whose case's active flag EQUALS true and whose intent landed.

Term transitioning verification: an admitted verification Party Identity answered with a state change id.

Term adverse trigger: an admitted trigger whose trigger_type belongs to the adverse trigger types.

Term periodic trigger: an admitted trigger whose trigger_type EQUALS the periodic trigger type.

Term suspending trigger: an adverse trigger whose suspend Party Identity admitted.

Term renewing trigger: a periodic trigger whose renewal Retention Window admitted.

Term completing closure: a [Close Party] invocation finishing an earlier closure Party Identity committed and no party closed event records.

Term committing closure: an admitted closure Party Identity answered with a state change id.

Term composed suspend reason: `"monitoring-trigger:" + trigger_type + ":" + trigger_ref` — the reason an adverse trigger passes to Party Identity's suspend.

Term closed triggers: the trigger ids a review cleared record names as resolved by the clearance.

Term open triggers at close: the trigger ids a party closed record names as closed-unresolved at the relationship's end.

Term scoped retry: the retrying invocation's own continuation of a step whose constituent call refused after a committed sibling call.

Term prior placement: the current placement a renewal supersedes.

Term renewed placement: the placement a renewal makes, which becomes the case's current placement once the renewal's record lands.

WHY:
**The rejection order is the action's shape.** Every action reads its index and runs its boundary predicate first, records an intent second, and calls a constituent third. Action wiring 1 through 7 are that first band for [Initiate Onboarding], [Already Onboarded] among them, and Action wiring 6 is a repair the prose owed: the external path guarded `Closed` alone, so a `Suspended` admit opened a case with an empty open-trigger set against a suspended party, and a `Verified` admit passed the gate with no verification record of this composition's at all. The admissible state is unverified and nothing else, and the one arm names the state it found rather than the three arms a reader would have to enumerate. The `party-closed` arm the prose exported folds into it: one guard, one arm, one meaning.

Action wiring 9 and Action wiring 18 are the direct path's asymmetry, stated rather than left to be inferred. On the direct path no party exists when the intent is written, so the intent carries no party id and the enrolment is the invocation's first commit; a storage-failure at the placement therefore reports an *outcome* position on that path and an *intent* position on the external one, where nothing has committed. Action wiring 11 and Action wiring 12 keep the enrolment's own failure under a composition-layer name — [Enrollment Failed] — rather than flattening it into a recording failure, precisely because it happens before any case or placement exists — there is no orphan to recover.

Action wiring 23, Action wiring 39 and Action wiring 114 are one guard in three places. A closed case reaching a constituent is the defect the prose carried at [Record Verification]: with no active-case guard, a closed case reached the intent record before Party Identity answered already-closed, so the trail carried an intent for an act that could never happen. The guard is cheap, it sits before the intent, and it makes [Not Active] an exported code on all three repeatable actions.

Action wiring 41 through 43 are the state-unavailable repair. Party Identity's `read` declares two answers — the matching parties, or `invalid-query` — and neither is an unreadable store, so mapping state-unavailable *from the constituent* named a contract the constituent does not have. It is mapped from the seam instead: an unanswered read is `execution-contract.md`'s own Step 1 failure, and `invalid-query` is this composition's own defect, because every query this composition builds is built from its own indexes and no caller input reaches it.

Action wiring 46 through 51 are the audit-first discipline, which is what Invariant 3 rests on. The trigger record precedes the suspend, so no suspension exists in the records without its precipitating trigger ordered ahead of it, and a failed trigger record aborts before any transition is attempted. Action wiring 55 and Action wiring 56 are the arm that repair costs: a rejected `suspend` leaves a landed trigger and no suspension, which — unvoided — rebuilds as an open investigation against a party still `Verified`, which [Clear Review] would then *clear*, recording a fresh verification, attempting a reinstate the constituent refuses, and never landing the record whose absence keeps the trigger open forever. Every non-idempotent rejection arm therefore writes the void first.

Action wiring 68 and Action wiring 69 are the renewal's unconditionality, and both halves matter. A suspended party's CDD record needs cover exactly as much as a verified one's, and the schedule freeze freezes the deadline rather than the renewal; and a placement is immutable per `retention_id`, so cover across a relationship longer than one duration is a chain of placements, continuous exactly when each link is placed before its predecessor's retention until. Action wiring 78 is the match key the recovery owed: a renewal recovery matches on the trigger_id the trigger event minted, never on *a placement this invocation already made*, which names no key at all.

Action wiring 91 is the ordering the clearance turns on. The clearance record lands before the reinstate commits, so it must not carry the advanced deadline: a failed reinstate would otherwise leave the trail asserting an advance the freeze rule forbids for a party still `Suspended`, and the rebuild — latest schedule-bearing payload — would convict a map entry that was correct. The advance rides the reinstatement record, which lands only after the reinstate has committed.

Action wiring 105 and Action wiring 106 are why a clearance drops a set rather than clearing one. Inside the window between the reinstate committing and its record landing, the party is already `Verified` and a new adverse trigger can lawfully land; a delayed completion that cleared the whole set would sweep that trigger while its own record stands and no clearance names it, leaving a `Suspended` party with an empty set and [Clear Review] unreachable.

Action wiring 117 and Action wiring 118 are the re-entry arm, and it is the alternative to a forbidden retry. A prior invocation that closed the party and died before placing the floor leaves a closure Party Identity committed and no record of; a fresh [Close Party] authenticates its own caller at its own intent and then completes the earlier act from the constituent's state-change record. Action wiring 133 is what that arm exists to avoid: a bare cross-invocation retry of a committing call would commit under an authentication performed in a prior invocation, which Invariant 8 forbids.

Action wiring 139 through 145 are the gate's fail-closed shape. The cheapest-compliant reading — unavailable implies permit — is exactly the before-activity hole the gate exists to close, so an unreadable store and a case entry whose party the store no longer answers for both answer state-unavailable and never permitted. The gate compares no timestamp and reads no clock, so it is clock-independent by construction, which is why it is excluded from the serialization obligation: its two reads need not be atomic, because the state read is authoritative and any skew yields a spurious not-known or a conservative not-verified, never a false permitted.

```
Action wiring 146: An initiated outcome MUST carry the injected now as opened at.
Action wiring 147: A monitoring triggered outcome MUST carry the injected now as triggered at.
Action wiring 148: A party suspended outcome MUST carry the injected now as suspended at.
Action wiring 149: A retention renewed outcome MUST carry the injected now as renewed at.
Action wiring 150: A review cleared outcome MUST carry the injected now as cleared at.
Action wiring 151: A party reinstated outcome MUST carry the injected now as reinstated at.
Action wiring 152: A committing closure MUST carry the injected now as closed at on the party closed outcome.
Action wiring 153: An invocation MUST derive the next review due from the injected now.
```

WHY:
Action wiring 146 through 153 are where each outcome's instant comes from, stated per outcome because one universal claim was false. The spec once said an invocation stamps *every* timestamp from its own reading, and a completing closure does not: it finishes a closure Party Identity already committed, so the closed at it records is the one Action wiring 118 reads back. Action wiring 152 is scoped to the committing closure for that reason.

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
*Principle.* BSA/AML and FATF Recommendations 10–12 require that Customer Due Diligence be completed before a business relationship's regulated activity begins. Structurally that means no account opening, no transaction and no service provisioning proceeds for a party outside a substantiated `Verified` state, and the system proves — from the records alone — both that the party was verified and that no activity preceded the verification.

*Likely objection.* Party Identity already owns the `Verified` state and already refuses a reinstatement without a passed verification after the most recent suspend. Why not have each activity system read Party Identity's state directly? The atom already enforces the substance of the gate.

*Mechanism that resolves it.* Party Identity owns the state and exposes no gate: it records that a party is Verified, does not enforce that activity systems consult it, and does not know what regulated activity means — importing that notion would break the atom's freestanding status, which is what Wiring decision 6 and Wiring decision 7 refuse. The Audit Trail substrate records attributed, tamper-evident events and does not know which of them constitute a verification chain. Neither can, alone, deliver both halves of the obligation. The composition wires them: every `Unverified → Verified` transition flows through [Record Verification], which records an event carrying both the `verification_id` and the `state_change_id`, so the verification is attributed and tamper-evident (Invariant 2.1); and [Activity Permitted] is the *single* gate query, so the precondition is implemented exactly once at the composition boundary rather than re-implemented — or quietly skipped — in each activity system. Wiring decision 2 is the half a reader most often misses: the gate consults this composition's own case index as well as the party's state, so a party driven to `Verified` outside this composition has no case entry and fails the gate. The attribution half is delivered by Invariant 2.1 together with the exclusive-ownership obligation of Composes 19 and Composes 20, not by the state read; the gate's own job is to confine permitted to the `Verified` parties this composition governs.

*Result.* The gate is structural and centralized. An auditor verifies from the records alone that for every party with regulated activity a verification record carrying a `state_change_id` precedes the activity (Check 1.1), and that no activity system held its own copy of the gate logic to drift from. The single-surface discipline is the records-alone-defensible signal: the verification precondition lives in one place, is exercised through one query, and produces one tamper-evident event class the auditor reads.

### Reconciliation

```
Reconciliation 1: The composition MUST run the reconciliation at process restart.
Reconciliation 2: The composition MUST run the reconciliation PER reconciliation cadence.
Reconciliation 3: The reconciliation MUST select an open marker over an open-ended sequence range.
Reconciliation 4: The reconciliation MUST NOT examine a young marker.
Reconciliation 5: The reconciliation MUST NOT examine an aged-out event.
Reconciliation 6: The reconciliation MUST resolve an open marker against the constituents' declared reads.
Reconciliation 7: IF no committing call EXISTS for the open marker THEN the reconciliation MUST close the marker.
Reconciliation 8: IF a committing call EXISTS for the open marker THEN the reconciliation MUST emit the owed outcome.
Reconciliation 9: The reconciliation MUST emit a recovery outcome ONLY AFTER the landed recovery intent.
Reconciliation 10: The reconciliation MUST record a recovery intent ONLY AFTER the outcome traversal.
Reconciliation 11: The reconciliation MUST attest a recovery record under the service identity.
Reconciliation 12: The reconciliation MUST place an owed post closure placement.
Reconciliation 13: The reconciliation MUST place an owed renewal.
Reconciliation 14: The reconciliation MUST NOT enroll a party.
Reconciliation 15: The reconciliation MUST NOT verify a party.
Reconciliation 16: The reconciliation MUST NOT suspend a party.
Reconciliation 17: The reconciliation MUST NOT reinstate a party.
Reconciliation 18: The reconciliation MUST NOT close a party.
Reconciliation 19: The reconciliation MUST close an open marker WITHIN the compensation window.
Reconciliation 20: The reconciliation MUST escalate an open marker outside the compensation window.
Reconciliation 21: The reconciliation MUST alert on a closed case carrying no post closure placement.
Reconciliation 22: The reconciliation MUST alert on an active case carrying an elapsed placement.
Reconciliation 23: The reconciliation MUST alert on a suspended party carrying an empty open-trigger set.
Reconciliation 24: The reconciliation MUST alert on a landed trigger carrying no outcome.
Reconciliation 25: The reconciliation MUST alert on a verified party carrying no verification record.
Reconciliation 26: Two reconciliations MUST NOT run against one case.
Reconciliation 27: The reconciliation MUST resolve a verification intent's commitment on the party id, the verifying actor ref, the evidence ref AND the intent's intended at.
Reconciliation 28: The reconciliation MUST resolve a placement intent's commitment on the party id, the policy ref AND the intent's intended at.
Reconciliation 29: The reconciliation MUST NOT resolve an enrolment intent's commitment.
Reconciliation 30: The reconciliation MUST escalate an unresolved enrolment intent as a finding.
Reconciliation 31: The reconciliation MUST NOT match a recovery on a payload resemblance.
Reconciliation 32: The reconciliation MUST answer nothing to a caller.
Reconciliation 33: A caller MUST NOT invoke the reconciliation.
```

Term reconciliation: the leg `Reconciliation 1` through `Reconciliation 33` state — this composition's own, over its open markers.

Term young marker: an open marker whose intended at stands within the onboarding completion bound of the injected now.

Term elapsed placement: a placement whose retention until does not exceed the injected now.

WHY:
The reconciliation is a **declared, bounded scan, not an implicit retry**, and both edges are load-bearing. Below the onboarding completion bound it examines nothing, because an intent younger than the bound may belong to an invocation still between its constituent commit and its outcome record, and a re-emission fired at it would land a second outcome — or a second placement — for one act, which no traversal can see because the invocation has not written yet. Above it, the audit horizon: past the horizon an intent's payload is destroyed, and a case whose events aged out is the unrebuildable class Composition state names, never an orphan. That is the frozen rule *A reconciliation is bounded at both ends*.

Reconciliation 11 through 18 fix what the leg may commit. It writes records freely under the service identity, and it commits exactly two constituent calls — a post-closure placement and a renewal — because those are the two whose loss leaves a record under no retention obligation at all and whose replacement is a fresh placement rather than a changed state. It never enrolls, verifies, suspends, reinstates or closes: each of those is a state change a human authorized, and the reconciliation carries no such authorization. The route for those is a fresh invocation, which authenticates its own caller at its own intent — [Close Party]'s re-entry arm is the worked form.

Reconciliation 27 through 31 are the indeterminacy the prose left unaddressed: a constituent call whose response was lost after the write committed. Party Identity and Retention Window carry no invocation identity of this composition's, so the question *did my call commit?* is answered by a re-query keyed on the values the intent already fixed, the invocation's own injected instant among them — one invocation has exactly one now, which is what makes the key exact rather than a resemblance. `enroll` is the one call that has no such key, because it mints the identity the key would need: a re-query cannot tell this invocation's party from another's, and a blind retry mints a second party for one customer. So it is never resolved and never retried; the unresolved enrolment intent is escalated, and its residue — an `Unverified` party with no case — is dispositioned administratively rather than joined by guesswork.

Reconciliation 32 and Reconciliation 33 place the leg: nothing awaits its answer inside an invocation, and a caller cannot drive it. What *does* await it is the compensation window Reconciliation 19 spends, which is why this leg is a `Reconciliation` rather than a `Housekeeping` — the question the grammar's own declaration of the family turns on, applied here by the one answer it takes.

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
Invariant 4.4: The composition MUST NOT claim the verifying actor ref stands authenticated.
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

Term continuous chain: a sequence of placements over one party in which each link's retained at does not exceed the predecessor's retention until.

Term post closure floor: the instant a closed case's post closure placement reaches the placement's retention until — the earliest lawful destruction of the party record on the post-closure side.

Term unelapsed placement: a placement whose retention until exceeds the injected now.

Term clearance window: the interval between a clearance's reinstate committing and the clearance's party reinstated record landing.

Term surfaced orphan: a state the composition has alerted on and the reconciliation owes a close.

Term clearing actor: the actor_ref a [Clear Review] call carries — the one actor whose credential the composition validates on that call.

WHY:
**Invariant 1 is two claims and the split is load-bearing.** Invariant 1.1 and Invariant 1.2 together are the biconditional, and the composition enforces both halves at the gate: step one refuses a party with no case, step three answers permitted only on verified, and every other state answers the parameterized refusal. Invariant 1.3 is the gating property, and it is the one structural obligation pushed to deployment — it holds exactly when activity systems consume [Activity Permitted] rather than reading Party Identity directly (Capability requirement 39). The *iff* is a property of the query's answer; the gate guarantee additionally requires the single-surface obligation to be honored, and a system that bypasses the gate is a composition-bypass finding rather than a valid path.

**Invariant 2 is conditioned at quiescence, which the prose asserted unconditionally.** The atomicity gap is real: [Record Verification]'s constituent write commits and its outcome record can fail, leaving a `Verified` party whose verification is unattested for as long as the recovery takes. Stating coverage as an always-true property makes every conformance run over a system mid-recovery report a violation of a rule the system is in the act of satisfying. Invariant 2.3 holds where no invocation is in flight; Invariant 2.4 names the window and bounds it by the compensation window the reconciliation spends. That is the same conditioning the substrate models for its own analogous invariants.

**Invariant 3's ordering is insertion order, not clock.** A trigger record and the suspension it precipitates are stamped from the *same* injected now and are expected to be identical rather than adjacent, so a timestamp difference between them would be a conformance failure — an implementation that read a clock twice instead of sharing the injected reading — and never the evidence of ordering. The Event Log's total order, reached transitively through Audit Trail, is what makes *later in the log* a records-alone fact.

**Invariant 4 is narrower than it reads, and the narrow statement is the true one.** The clearing actor — whose credential this composition validates at the clearance intent — attests that fresh evidence naming verifying actor ref was recorded before the reinstatement. It is not a claim that verifying actor ref was authenticated: that reference is caller-supplied and this composition never checks it, which is Invariant 4.4 and Invariant 8.3 stated where a reader of Invariant 4 will look. Requiring the two references equal would collapse a real separation of duties — an analyst gathers the evidence, a manager clears the review — so the composition keeps the separation and states the limit instead of pretending to a verification it does not perform. Whether the named evidence-producer was who they claimed is External check 3.

**Invariant 5's joint enforcement is declared rather than assumed.** Retention Window's no-early-purge is per-`retention_id`, and the atom explicitly does not jointly enforce overlapping retentions over one `record_ref` — its *Multiple simultaneous retentions* edge case hands exactly that to the composing layer. This composition exposes no purge surface (Invariant 5.5), so the obligation lands on the purging layer and Invariant 5.4 quantifies over *every* placement: the current one, every superseded link the renewal records name, and the post-closure one. Nothing structural forces the post-closure floor to end last — a long active-relationship policy can outlast a short post-closure one — which is exactly why the rule quantifies rather than naming which. A deployment purging through Defensible Retention discharges it structurally; a host purging directly against the Retention Window instance owes the same joint check itself.

**Invariant 7 is safety at quiescence and liveness across one named window.** Inside the clearance window the reinstate has committed and its record has not landed, so a `Verified` party still carries the not-yet-dropped closed triggers — a surfaced orphan that closes when the record lands and the clearance drops exactly that set. The correspondence is quantified over *active* cases, because [Close Party] sweeps the set administratively and records the swept triggers on its closure event; a closed case's set is empty by that sweep, and the party's `Closed` state rather than this index is what gates it thereafter. The correspondence is what makes [No Open Trigger] a faithful *nothing to clear* signal.

**Invariant 8's scope paragraph is the invariant, not a caveat on it.** Each action carries one credential and therefore validates one actor: actor_ref at [Initiate Onboarding], [Clear Review] and [Trigger Monitoring Review], verifying actor ref at [Record Verification], closing_actor_ref at [Close Party]. The other references an action carries — enrolling actor ref on the direct path, verifying actor ref at [Clear Review] — are recorded and not authenticated. Invariant 8.4 through 8.7 say what a validation does *not* establish, because each is a reading the rule invites and none of them is true: a stolen credential validates, nothing binds the presentation to a channel or forecloses a replay, authorization is a composing Permissions matter this composition does not gate, and whether the customer's identity evidence is genuine is Party Identity's and the deployment's question.

Invariant 1 with Invariant 2 gives the *substantiated-access* property — every party that can reach activity was verified through an attributed, tamper-evident process. Invariant 3 with Invariant 4 gives *defensible monitoring* — every suspension is caused-in-the-records and every reinstatement is evidenced-in-the-records. Invariant 5 with Invariant 6 closes the relationship lifecycle: the record is under retention throughout its active life and survives its mandated post-closure period, and was monitored throughout. Invariant 7 keeps the adverse-investigation index faithful to the constituent's state, and Invariant 8 is what makes every one of them an act a named, validated actor committed.

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

`close_party(case_5501, …)` reaches its closure intent, and `AuditTrail.record_action` answers `recording-failure(step)` naming the substrate's **retention** step: the event is appended and attested — so the credential *was* validated — and the call returned a failure. The invocation **aborts with nothing committed**: `PartyIdentity.close` is not called, the intent is not re-recorded (a blind re-record would double-append), and the appended `customer-onboarding.closure-intended` stands as an open marker. The reconciliation, past the completion bound, finds the marker, re-queries Party Identity, sees no closure, and closes the marker — nothing to compensate. The caller receives `recording-failure(intent)` and may retry the whole action.

### Failure path — an unmatched intent

A [Record Verification] invocation records its intent, calls `PartyIdentity.verify` — which commits `verif_2210` — and dies before its outcome record. The trail holds `customer-onboarding.verification-intended` with no outcome carrying its intent event id. Inside the completion bound the reconciliation does not examine it: the invocation may still be between its commit and its record. Past the bound the reconciliation traverses for an outcome carrying that intent event id, finds none, re-queries Party Identity on party id + verifying actor ref + evidence ref + the intent's intended at, finds `verif_2210`, records `customer-onboarding.recovery-intended` under the service identity, and emits `customer-onboarding.verification-recorded` carrying `recovery = true` with `officer_r3` named in the payload. An auditor reading the trail sees a recovered verification rather than a clean one — and Check 6.1 compares against the human in the payload rather than the attesting service actor, which is why a recovered action does not read as an authentication failure.

### Failure path — verification committed, outcome record fails

A [Record Verification] call drives the `Unverified → Verified` transition and its outcome record fails: `recording-failure(outcome)` — the position telling the caller the verification is committed and the action must not be re-run. The party *is* `Verified`, so the gate answers permitted while Invariant 2.3's coverage is temporarily broken; Invariant 2.4 is the window, bounded by the compensation window. The composition alerts on the owed record; the invocation retries it to the completion bound and then yields it to the reconciliation. Deployments under BSA/AML exposure treat the open window as a hard alerting condition.

### Regulated adversarial scenarios

**Regulator audit — show me that every active customer was verified before regulated activity.** A FATF/BSA examiner queries the trail and the activity records. For every party with an activity record, the examiner confirms a `customer-onboarding.verification-recorded` event carrying a non-absent `state_change_id` exists, that `AuditTrail.verify_record` answers verified for it, and that it precedes the first activity record. The two halves of Invariant 1 answer two different questions and the examiner asks both: Invariant 1.1 and Invariant 1.2 are the composition's own biconditional — the gate answered permitted for exactly the parties this composition initiated and Party Identity reports `Verified` — while Invariant 1.3, that no activity path other than the gate exists, is the deployment's obligation and is cleared by the deployment's own evidence that its activity systems consume [Activity Permitted] (External check 7). Flattening the two loses the distinction between what the records prove and what the deployment must attest. Invariant 2 is the guarantee that the verifying transition is in the records, attributed and tamper-evident. A party with an activity record and no predating, verified verification record carrying a `state_change_id` is a conformance failure.

**Disputed onboarding — the party claims they were never properly verified.** Counsel challenges the bank's claim that the identity was verified before the account opened. The investigator retrieves the case's `customer-onboarding.verification-recorded` events; each carries `verification_id`, `result` and, for the transition, `state_change_id`. The Party Identity verification record for each `verification_id` names verifying actor ref, method, evidence ref and `verified_at`. Party Identity's immutability and append-only invariants establish that no verification event was altered or back-inserted; the substrate's seal establishes that the composition's own record was not altered. The evidence ref points to the document record that supported the verification. Invariant 2 with Party Identity's own invariants is the rebuttal.

**Breach or incident forensics — which parties were Verified during the compromise window, and were any verifications altered.** Given a window, the investigator replays each case's `customer-onboarding.initiated`, `customer-onboarding.verification-recorded`, `customer-onboarding.monitoring-triggered`, `customer-onboarding.party-suspended`, `customer-onboarding.trigger-on-suspended-party`, `customer-onboarding.trigger-voided`, `customer-onboarding.review-cleared`, `customer-onboarding.party-reinstated` and `customer-onboarding.party-closed` events in Event Log insertion order to determine each party's state at the window's bounds — the intake and closure classes included, without which the replay cannot place a case's start or reconstruct a closure at all — then runs `AuditTrail.verify_record` against representative events in each seal's coverage to bound any tampering window. Invariant 3 is load-bearing here: every suspension in the window has a precipitating trigger ordered ahead of it, and a suspension with no precipitating trigger — or a trigger inserted *after* its suspension — is itself a finding, which the append-only sealed log forecloses an attacker doing silently. Invariant 6 lets the investigator confirm that every `Verified`, active party in the window had an open monitoring entry. Where the window has legal force as wall-time rather than event-index bounds, a Trusted Timestamping composition supplies the anchor; absent it the reconstruction is event-index-authoritative. The newest events — the substrate's unsealed tail — carry per-event immutability and become seal-verifiable only after the next seal cadence, so the integrity bound on the most recent events is the substrate's configured unsealed-tail policy.

---

## Generation acceptance

A derived implementation is *acceptable* — in the regulator-acceptance sense — when an external auditor, given the composition's indexes plus the Party Identity, Retention Window and Audit Trail stores, clears every check below without recourse to source code, runbooks or developer narration. Every selection is made composition-side over the declared open-ended sequence range, never by asking the substrate for a payload predicate it does not serve.

### Conformance checks

```
Check 1.1: An auditor MUST find a verification recorded record carrying a state change id PER party carrying a regulated activity record (Invariant 1.3).
Check 1.2: An auditor MUST confirm Audit Trail's verify_record answers verified for the found verification recorded record (Invariant 2.2).
Check 1.3: An auditor MUST confirm the found verification recorded record stands earlier in the log than the party's first activity record (Invariant 1.3).
Check 1.4: An auditor MUST read Check 1.3 as a wall-time comparison ONLY IF the deployment composes Trusted Timestamping (Clock semantics 8).
Check 1.5: An auditor MUST read Check 1.3 against an activity store carrying no log anchor as best-effort (Clock semantics 8).
Check 1.6: An auditor MUST confirm the party-to-case index names EVERY party the gate answered permitted for (Invariant 1.1).
Check 2.1: An auditor MUST find a verification recorded record naming the verification id AND the state change id PER transitioning verification in Party Identity's store (Invariant 2.1).
Check 2.2: An auditor MUST find a verification recorded record PER quiescent verified party (Invariant 2.3).
Check 2.3: An auditor MUST read a verified party carrying an owed verification recorded record inside the compensation window as a surfaced orphan (Invariant 2.4).
Check 3.1: An auditor MUST find a monitoring triggered record carrying the same trigger_id earlier in the log PER party suspended record (Invariant 3.1).
Check 3.2: An auditor MUST find a monitoring triggered record carrying the same trigger_id earlier in the log PER trigger on suspended party record (Invariant 3.2).
Check 4.1: An auditor MUST find a review cleared record naming a verification id earlier in the log PER party reinstated record (Invariant 4.2).
Check 4.2: An auditor MUST confirm the named verification stands passed in Party Identity's store (Invariant 4.1).
Check 4.3: An auditor MUST confirm the named verification stands later in the log than the party's most recent suspension (Invariant 4.1).
Check 4.4: An auditor MUST confirm the review cleared record's attested actor_ref matches the party reinstated record's attested actor_ref (Invariant 4.3).
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
Check 8.2: An auditor MUST confirm the found intent and the outcome name one case_id (Identity 9).
Check 8.3: An auditor MUST compare a recovery outcome against the human the outcome's data names (Audit arm 23).
Check 8.4: An auditor MUST NOT compare a recovery outcome against the outcome's attesting actor_ref (Audit arm 23).
Check 8.5: An auditor MUST NOT read an intent carrying no outcome as a conformance failure (Reconciliation 7).
Check 8.6: An auditor MUST resolve an intent carrying no outcome against the constituents' declared reads (Reconciliation 6).
Check 9.1: An auditor MUST clear Party Identity's conformance checks over the Party Identity store (Composes 5).
Check 9.2: An auditor MUST clear Retention Window's conformance checks over the party retention instance (Composes 5).
Check 9.3: An auditor MUST clear Audit Trail's conformance checks over the audit instance (Composes 5).
Check 9.4: An auditor MUST recognize an aged-out event PER event through Audit Trail's read_record (Composition state 19).
Check 9.5: An auditor MUST NOT read an aged-out event's payload (Composition state 18).
```

### External checks

```
External check 1: The deployment MUST establish the verification method's adequacy for the party's risk tier (Non-goal 3).
External check 2: The deployment MUST establish the screening list's currency at the screening's instant (Non-goal 1).
External check 3: The deployment MUST establish the verifying actor ref's identity (Invariant 8.3).
External check 4: The deployment MUST establish the enrolling actor ref's identity (Invariant 8.3).
External check 5: The deployment MUST establish an actor's authorization to record a verification (Invariant 8.6).
External check 6: The deployment MUST establish the lawful basis of a non-obligatory downstream processing (Non-goal 11).
External check 7: The deployment MUST establish that every activity system consumes [Activity Permitted] (Invariant 1.3).
External check 8: The deployment MUST establish that no second writer drives a verification transition on the Party Identity instance (Composes 20).
External check 9: The deployment MUST establish that the active relationship policy's duration exceeds the renewal floor (Capability requirement 20).
External check 10: The deployment MUST establish that the post closure policy's duration meets the post closure minimum (Capability requirement 17).
External check 11: The deployment MUST establish the scheduler's lateness against the scheduler tolerance (Capability requirement 19).
```

WHY:
**Check 1.4 and Check 1.5 are the hedge the check owed.** *The verification predates the activity* is a comparison across two stores, and this composition's own Clock semantics make timestamps advisory: insertion order is authoritative inside the audit log and the activity store is not in that log. So the comparison is a wall-time claim exactly where the deployment composes a time anchor, and best-effort otherwise — stated on the check rather than left for an auditor to discover when a clock skew turns a clean run into a finding.

**Check 2.2 and Check 2.3 carry Invariant 2's conditioning into the check.** An implementation mid-recovery has a `Verified` party whose record is owed and alerted; reading that as a conformance failure convicts a system in the act of satisfying the rule. The check reads it as a surfaced orphan and the compensation window is what bounds it.

**Check 4.1 through 4.4 are new, and Invariant 4's composition half had no check at all.** Party Identity's own invariant already forces a passed verification since the most recent suspend — that half is the constituent's and Check 9.1 inherits it. What no check reached was the *composition's* half: that the clearance record naming the verification exists, lands before the reinstatement, and is attested by the same actor whose credential the reinstatement was authorized under. That is the whole of what this composition adds to the constituent's guarantee, and it was clearable from the records the entire time.

**Check 5.1 is conditioned on lawful destruction, which the unconditional form got wrong.** *Every `Closed` party has a `Retained` post-closure placement* fails on a record whose floor has elapsed and which a purging layer has lawfully destroyed — the check convicted the correct end of a record's life. The condition is the record still standing, and Check 5.2 carries the part that has no exception: no closed party's record is destroyed before its floor elapses.

**Check 5.3 through 5.5 are the active chain, and they test the records rather than the schedule.** Invariant 5.1's active coverage is conditional on the periodic review firing, and a scheduler that stops fires no renewal — so the check reproduces the chain from the intake payload and the renewal payloads and tests continuity, rather than trusting that reviews happened. A gap in the chain, or a current placement purge-eligible while the case is active, is an interval in which a live customer's CDD record was lawfully destroyable.

**Check 7.1 through 7.5 are new.** Invariant 7 was named by no check, which is `cites.py --unchecked`'s class and is the third of this composition's own claims to have been unreachable from its acceptance section. It is also cheap: the set is rebuildable from the trail by the procedure Composition state already states, so the correspondence is one comparison against the party's state, and Check 7.4 is the trigger-lifecycle completeness the void arm exists to make true.

**Check 8.1 and Check 8.2 join by the intent's own id, and the distinction is load-bearing.** case_id is per-case and three actions are repeatable against one case, so a case_id-plus-actor match is satisfied by a single stale intent standing in front of an unbounded number of later outcomes — an implementation emitting one intent per case and skipping it thereafter would pass. Matching on the id the intent record minted admits no such reading. Because the substrate validates the caller's credential inside every record_action, the earlier intent *is* the records-alone proof that the acting actor was authenticated before the constituent write committed, which is what makes Invariant 8 verifiable rather than asserted.

**Check 9.4 and Check 9.5 state where recognition lives past the horizon.** The substrate destroys an event's payload in its entirety while the attestation keeps action_ref, actor_ref and `attested_at` readable, so an aged-out event is recognized *per event* through the substrate's own record read and not through the range read's payload — which is what bounds every reproduction above by the horizon rather than by the log's start.

External check 7 and External check 8 are the two obligations that make the gate a gate, and neither is records-alone: the read side is a property of every activity system the deployment runs, and the write side is a property of who else holds the Party Identity instance. Both are composition-bypass findings when they fail, and both are named here rather than assumed, because a spec that assumed them would be claiming a guarantee its own records cannot carry.

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

WHY:
Non-goal 1 and Non-goal 2 name the upstream boundary. What happens *during* verification — document OCR, biometric check, sanctions-database query, adverse-media search — produces the verification result, method and evidence ref this composition records. The composition is the lifecycle and the gate; the workflow is upstream, and Party Identity's own *Asynchronous verification workflows* edge case names the same seam from the constituent's side, which is why Non-goal 7 declines to model a pending state: the party simply stands `Unverified` until a passed result is recorded.

**Non-goal 3 through 5 decline a delegation rather than bouncing it back, and that is the point.** Party Identity's own edge case hands enhanced-due-diligence orchestration to its composing layer; this composition *is* that composing layer and does not absorb it either, which for one revision left the responsibility unowned with each side pointing at the other. The named owner is a **Risk Tiering / EDD** composing pattern *(forthcoming)* that reads this composition's verification lifecycle and monitoring schedule and decides tiering, method adequacy and cadence. Party Identity's own pointer needs the matching correction when that atom is next touched.

Non-goal 6 with Capability requirement 40 and Capability requirement 41 is the scheduler boundary: the composition holds the schedule *state* and is not the scheduling *engine*.

**Non-goal 17 is where the Review Schedule proposal lives, and it is a Non-goal rather than a classification.** The prose flagged the monitoring schedule as *extraction-pending* against a proposed **Review Schedule** atom *(forthcoming)* owning recurring-review deadlines — open, advance, freeze, read — while stating in the same subsection that every schedule write rides an audit payload and the deadline is rebuildable from the trail. On the Contract's own test that makes the schedule a derived index, so the extraction-pending flag was a misclassification rather than a declared debt (Composition state). The atom may still be worth extracting — a deadline that opens, advances and freezes is a shape more than one composition will want — and that is what this Non-goal records: a concept named as somebody else's to own, not a debt riding this composition's classification.

Non-goal 8 names the ownership graph's owner. Each beneficial owner of a legal-entity customer is a Party Identity record in their own right and is verified through its own onboarding case here; the ownership relation itself — percentage, control type, the FinCEN (Financial Crimes Enforcement Network — the US Treasury bureau administering the Bank Secrecy Act) Beneficial Ownership Rule's 25% threshold — belongs to an **Ownership Structure / Beneficial Owner** composing pattern *(forthcoming)*, of which this composition is a constituent rather than a replacement.

[Trigger On Suspended Party] and [Trigger Voided] are the two event classes the adverse path records where no transition occurred, and both exist so a rebuild reads the trigger's disposition rather than guessing it. Non-goal 9 is an enrichment declined as a constituent. Party Identity's `verify` is append-only and idempotent at the *state* level — a re-applied passed against an already-`Verified` party records a redundant event and drives no transition — so this composition needs no provisional-commitment semantics. A deployment wanting at-most-once semantics on retried verification jobs wires [Duplicate Prevention](../atoms/duplicate-prevention.md) in front of [Record Verification] or [Trigger Monitoring Review] as an optional enrichment.

Non-goal 11 and Non-goal 12 split the two data-protection questions this composition is asked and answers neither. Customer Due Diligence processing rests on GDPR Article 6(1)(c) — compliance with a legal obligation — not on Article 6(1)(a) consent, and the distinction is load-bearing: a customer cannot revoke the basis for Customer Due Diligence processing while the AML obligation stands. Consent governs *non-obligatory* downstream processing, which [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md) owns; an erasure request against a retained record is [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md)'s, and the tension that composition adjudicates is the legal-obligation exception at Article 17(3)(b).

Non-goal 13 and Non-goal 14 are why Invariant 5.4 quantifies over a purging layer rather than over an action here: this composition places retentions and destroys nothing, so the joint-enforcement obligation lands on whoever purges — [Defensible Retention](./defensible-retention.md) discharges it structurally, and a host purging directly against the Retention Window instance owes the same joint check itself.

Non-goal 10 is the closure's honest limit. [Close Party] gates *new* activity and unwinds no open account, position or contract; the composing system owns that policy, and this composition's contract is that the gate answers `not-verified(Closed)` after closure.

---

## Edge cases

### Atomic writes

```
Atomic writes 1: An invocation MUST record an outcome ONLY AFTER the invocation's committing call.
Atomic writes 2: An invocation MUST populate an index ONLY AFTER the invocation's landed outcome.
Atomic writes 3: An invocation MUST retry a committing call ONLY AFTER the constituent re-query.
Atomic writes 4: An invocation MUST NOT retry an enroll.
Atomic writes 5: An invocation MUST NOT retry a committing call outside the invocation.
Atomic writes 6: An invocation MUST read an indeterminate verify against Party Identity's declared read.
Atomic writes 7: An invocation MUST read an indeterminate placement against Retention Window's declared read.
Atomic writes 8: An invocation MUST read an indeterminate enroll as unresolvable.
Atomic writes 9: An invocation MUST escalate an unresolvable enroll.
Atomic writes 10: The composition MUST NOT reverse a committed constituent write.
Atomic writes 11: The composition MUST surface an orphan.
Atomic writes 12: A deployment MUST treat an orphan as an alerting condition.
```

Term trigger outcome: a party suspended record, a trigger on suspended party record, OR a trigger voided record — the three an adverse trigger's own record may be followed by.

Term orphan: a committed constituent write carrying an owed record, or a committed act carrying an index the composition has not populated.

Term indeterminate committing call: a committing call whose answer the invocation did not receive.

WHY:
Several actions write to two or three stores in sequence, and a failure between writes leaves partial state whose consequence differs by action. The sharpest is [Record Verification]'s: the constituent write commits and the outcome record fails, leaving a `Verified` party whose verification is unattested. Party Identity's verification events are immutable once committed, so synchronous reversal is unavailable (Atomic writes 10) and the repair is compensation rather than reversal: retry the record, surface the orphan, mark the compensating record as a recovery.

**Atomic writes 3 through 9 are the indeterminacy the page had not addressed.** A lost response after a commit is not a failure the invocation can tell from a failure before one, and the two demand opposite actions. `verify` and `place_under_retention` are re-queryable: the intent already fixed the values, the invocation's own injected instant is on it, and a read against the constituent's declared surface answers *did my call commit?* exactly. `enroll` is not, because it mints the identity a key would need — a re-query cannot tell this invocation's party from another's, and a blind retry mints a second party for one customer. So it is escalated rather than resolved, and its residue — an `Unverified` party with no case — is dispositioned administratively.

The ordering disciplines are what shrink the windows rather than close them: the trigger is recorded before any transition, the clearance before the reinstatement, and every index after its own record. Atomic writes 2 is why a lost index entry is never a lost fact — the record landed first, so the rebuild regenerates it — and it is the rule the prose stated three times and broke twice.

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
Clock semantics 9: A reader MUST read a divergence between a trigger's triggered at and the trigger's suspended at as a conformance failure.
Deleted: Clock semantics 10. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 11. Non-goal 21 owns it.
```

Term placement's cover: `the current placement's retention_until − scheduler_tolerance` — the instant past which a review would fire too late to renew the placement before the placement lapses.

WHY:
Action wiring 146 through 153 stamp from the one reading an invocation shares (the section titled Logic Confinement Principle in `execution-contract.md`), and the sharing is what several claims rest on. At [Initiate Onboarding] the opening instant and the first deadline derive from one reading, so the interval between them is exactly the monitoring interval rather than the interval plus an inter-read drift. At [Trigger Monitoring Review] the trigger's instant and the adverse path's suspension instant are the same value, which is why Clock semantics 9 reads a *divergence* between them as a conformance failure — an implementation that read a clock twice — rather than as clock granularity, and why Invariant 3 reads ordering from the log instead.

Clock semantics 4 is the cap that makes Capability requirement 20's duration obligation sufficient. Every schedule advance is capped below the current placement's cover, because an advance that ignored the placement — a verification pass months after intake, a clearance after a long suspension — would push the first renewal past the placement's end no matter how the interval and the duration compared. The composition stores the deadline and never a derived *review due* or *overdue* flag (Composition state 48, Composition state 49): whether a review is due is a read-time projection against an injected reading at the moment the question is asked, so nothing lags the clock.

Execution Contract Logic confinement 7 and Non-goal 21 name the residual honestly. Where review deadlines or onboarding timestamps have legal force — FATF and BSA/AML require recording when Customer Due Diligence was performed — the deployment injects a reading from a trustworthy clock, and a composed Trusted Timestamping pattern supplies the verifiable anchor that binds insertion order to wall time. Under injection the residual risk is a deployment that injects a dishonest reading, not an internal race, and this composition detects neither.

### Concurrency

```
Concurrency 1: A deployment MUST serialize a state-changing action over one party id.
Concurrency 2: A deployment MUST NOT serialize [Activity Permitted].
Concurrency 3: [Activity Permitted]'s two reads MUST NOT stand atomic.
Concurrency 4: A skewed gate read MUST NOT answer permitted.
Concurrency 5: The composition MUST answer a losing transition's constituent rejection.
Concurrency 6: The composition MUST read a state rejection the trigger pre-check forecloses as a serialization breach.
Concurrency 7: Two invocations MUST NOT hold one case's open-trigger set.
Concurrency 8: The reconciliation MUST NOT run against a case an invocation holds.
```

WHY:
Concurrency 1 is the obligation every state rejection behind a pre-check depends on. [Trigger Monitoring Review] reads the party's state before it records the trigger, so the suspend's own state arms are unreachable under the serialization; should one fire anyway, Concurrency 6 names it for what it is — a breach of the host's obligation, not a routine arm — and the trigger is voided so the rebuilt open set never carries an investigation against a party nobody suspended. [Clear Review]'s [Verification Failed] is the same shape: a concurrent suspend between the fresh verification and the reinstate, or a concurrent reinstate, re-arms a precondition the action had just satisfied.

Concurrency 2 through 4 exempt the gate, and the exemption is safe by construction rather than by luck. The gate reads its index and then the live state; between the two another writer may commit a transition, and every skew that read admits fails safe — a stale index yields a spurious [Party Not Known] and a stale state read yields a conservative [Not Verified], because the state read is authoritative and permitted requires it to answer verified at the instant it was read.

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

Term actors: the composition; a deployment; the host; the seam; the transition; the reconciliation; a caller; an auditor; an activity system; an implementation; a reader; a writer; an invocation; a yielded invocation; an action; an intent; an outcome; an open marker; a young marker; a recovery intent; a recovery outcome; the gate; a rebuild; an index; the case-to-monitoring index; the party-to-case index; the case-to-retentions index; the case-to-open-triggers index; an index entry; an unrebuildable entry; a case; a quiescent case; a quiescent closed case; an active case; a closed case; a party; a quiescent verified party; a quiescent suspended party; a reinstated party; a verified party; a suspended party; a case's party; a party state; an admissible state; a suspendable state; a trigger; an adverse trigger; a periodic trigger; a suspending trigger; a renewing trigger; an open trigger; a closed trigger; a trigger set; a verification; a transitioning verification; a clearance; an admitted initiation; an admitted verification; an admitted trigger; an admitted clearance; an admitted closure; a completing closure; a direct path initiation; an external path call; a placement; a current placement; a prior placement; a renewed placement; a post closure placement; an elapsed placement; an unelapsed placement; a continuous chain; a renewal; a purging layer; a scoped retry; a committing call; an indeterminate committing call; a landed record; a landed intent; an owed record; an aged-out event; an audit event; an orphan; a surfaced orphan; a boundary predicate; an opaque input; an actor reference; the clearing actor; a credential; a credential validation; a field cap; the trigger set cap; the binding floor; the closure floor; the renewal floor; the audit horizon; the monitoring interval; the scheduler tolerance; a policy; the active relationship policy; the post closure policy; the post closure minimum; the adverse trigger types; the periodic trigger type; a regulated activity; a review scheduler; Party Identity; Retention Window; Audit Trail; Event Log; the party retention instance; the audit instance; the service identity; a truncation marker; a set digest; a payload field; a timestamp; insertion order; a clock reading; a skewed gate read; a losing transition; a state rejection; a divergence; two reconciliations; two invocations.

Term record verbs: serve, change, inherit, read, hold, reach, call, select, query, attest, own, place, admit, drive, know, push, store, classify, carry, stand, claim, populate, name, alert, drop, take, rebuild, recognize, supply, mint, generate, accept, configure, set, provision, rotate, disclose, start, run, fire, serialize, resolve, reconcile, refuse, normalize, fold, trim, compare, judge, propagate, cap, truncate, allocate, reuse, pair, make, retry, leave, record, answer, substitute, add, complete, clear, empty, write, advance, repoint, renew, cross, find, confirm, reproduce, establish, match, escalate, close, emit, examine, expose, validate, commit, detect, inject, stamp, derive, deduplicate, model, schedule, adjudicate, purge, unwind, gate, index, anchor, surface, treat, sweep, spend, enroll, verify, suspend, reinstate, belong, elapse, substantiate, invoke, duplicate, block, govern, identify, decide, reverse, destroy.

Term records: empty.

Term bounds: onboarding completion bound (onboarding_completion_bound), compensation window (compensation window), audit horizon (audit_trail_retention_policy), monitoring interval (monitoring_interval), scheduler tolerance (scheduler_tolerance), renewal floor, binding floor, closure floor, field cap, trigger set cap (trigger_set_cap), `placement's cover`, post closure minimum, audit write latency.

Term cadences: reconciliation cadence (reconciliation cadence), seal cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.41 (2026-09-14).

Term value sets: admissible states = unverified. suspendable states = verified | suspended. verification results = passed | failed. trigger vocabulary = periodic-review-due | a member of the adverse trigger types. adverse trigger types = sanctions-match | pep-status-change | adverse-media, extended by the deployment. intent = customer-onboarding.initiation-intended | customer-onboarding.verification-intended | customer-onboarding.clearance-intended | customer-onboarding.closure-intended | customer-onboarding.monitoring-triggered | customer-onboarding.recovery-intended. outcome = customer-onboarding.initiated | customer-onboarding.verification-recorded | customer-onboarding.party-suspended | customer-onboarding.trigger-on-suspended-party | customer-onboarding.trigger-voided | customer-onboarding.retention-renewed | customer-onboarding.review-cleared | customer-onboarding.party-reinstated | customer-onboarding.party-closed. enrollment_path = direct | external-onboarding.

Term terms: composition, constituents, party retention instance, service identity, direct path, external path, case-to-monitoring index, party-to-case index, case-to-retentions index, case-to-open-triggers index, index, current placement, post closure placement, audit horizon, aged-out event, rebuild, miss, unrebuildable entry, binding-bearing payload, schedule-bearing payload, placement-bearing payload, landed record, owed record, seam, transition, monitoring interval, scheduler tolerance, renewal floor, binding floor, closure floor, onboarding completion bound, active relationship policy, post closure policy, post closure minimum, adverse trigger types, periodic trigger type, trigger set cap, field cap, blank, boundary predicate, opaque input, actor reference, trigger vocabulary, verification results, truncation marker, set digest, intent, outcome, committing call, landed intent, open marker, outcome traversal, yielded invocation, recovery marker, recovery outcome, party state, admissible states, suspendable states, unanswered read, admitted initiation, admitted verification, admitted trigger, admitted clearance, admitted closure, transitioning verification, adverse trigger, periodic trigger, suspending trigger, renewing trigger, completing closure, committing closure, composed suspend reason, closed triggers, open triggers at close, scoped retry, prior placement, renewed placement, regulated activity, reconciliation, young marker, elapsed placement, quiescent case, quiescent verified party, quiescent suspended party, quiescent closed case, continuous chain, unelapsed placement, post closure floor, clearance window, surfaced orphan, clearing actor, `placement's cover`, trigger outcome, orphan, indeterminate committing call, enrollment failure, position, intended at, intent event id, opened at, triggered at, suspended at, renewed at, cleared at, reinstated at, closed at, active flag, active case.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the derived-index classification and its obligations. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Step 1 failure in `execution-contract.md` — the name an unanswered constituent read takes. The section titled Structural-relation invariant templates in `spec-format.md` — referential integrity.

Term composing patterns: Risk Tiering / EDD *(forthcoming)*; Ownership Structure / Beneficial Owner *(forthcoming)*; Review Schedule *(forthcoming)*; Reverse Index *(forthcoming)*; Trusted Timestamping *(forthcoming)*; Policy Reconciliation *(forthcoming)*; [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md); [External Onboarding](./external-onboarding.md); [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md); [Defensible Retention](./defensible-retention.md); [Duplicate Prevention](../atoms/duplicate-prevention.md); [Permissions](../atoms/permissions.md).

#### Initiate Onboarding

The composition's intake action: open a Customer Due Diligence case for a party — enrolling the party on the direct path, or admitting one External Onboarding already enrolled in `Unverified` state on the external path, with enrollment_path recording which — placing the first active-relationship retention, opening the monitoring schedule, and recording the case. Answers the case_id.

Kind: Operation

#### Record Verification

The action that records a verification result against a case's party, driving the `Unverified → Verified` transition on a passed first verification, and recording the verification and state-change identifiers — the attribution-and-tamper-evidence half of verification-gates-activity (Invariant 2). Advances [Next Review Due] on a state-changing pass and on nothing else.

Kind: Operation

#### Trigger Monitoring Review

The audit-first entry point an external monitoring or screening system calls: it records the trigger *before* any resulting transition (Invariant 3), then — for an adverse trigger — suspends the party, or — for a periodic one — renews the active-relationship retention and advances [Next Review Due] unless the party stands suspended. No suspension exists in the records without its precipitating trigger ordered ahead of it.

Kind: Operation

#### Clear Review

The single emergent action that clears an adverse-trigger investigation and returns the party to Verified — wrapping a fresh passed verification, a `reinstate`, and two audit records into one act. Requires an open trigger ([No Open Trigger] otherwise) and closes exactly the triggers its clearance record names.

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

The [Activity Permitted] fail-closed refusal when the party's state read cannot be answered — an unanswered read at the seam, or a case entry whose party the store no longer answers for. The gate refuses rather than treating an unreadable identity store as `Verified`, because the cheapest-compliant reading — unavailable implies permit — is exactly the before-activity hole the gate exists to close. [Trigger Monitoring Review]'s pre-check mirrors it.

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

The [Clear Review] refusal when the reinstatement's precondition is unmet — a concurrent suspend re-armed it, or the party was not Suspended. A defence-in-depth code, reachable only where the host has not honored the per-party serialization obligation.

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
- **BSA/AML — 31 CFR §1020.220 (Customer Identification Program)** — minimum identity attributes, verification, and **record retention for five years after the business relationship ends**. [Close Party]'s post-closure placement is the structural form of that floor (Invariant 5.3), and Capability requirement 17 is where the deployment's configured duration is held to it.
- **FinCEN Beneficial Ownership Rule — 31 CFR §1010.230** — legal-entity customers must identify and verify beneficial owners owning at least 25% and a single control person. Each beneficial owner is a Party Identity record verified through an onboarding case of their own; the ownership graph belongs to the Ownership Structure composing pattern (Non-goal 8).
- **EU 5th Anti-Money Laundering Directive (AMLD5)** — enhanced CDD requirements, beneficial-ownership registries, and ongoing-monitoring obligations, aligned with FATF. This composition is the onboarding-and-monitoring surface an AMLD5 deployment builds on.
- **GDPR Article 6(1)(c) — legal obligation as processing basis.** Customer Due Diligence processing rests on Article 6(1)(c), **not** Article 6(1)(a) consent. The distinction is load-bearing: the customer cannot revoke the basis for Customer Due Diligence processing while the AML obligation stands, which is why Consent is not a constituent. Consent governs *non-obligatory* downstream processing (Non-goal 11).
- **HIPAA (Health Insurance Portability and Accountability Act) §164.312(a)(1) (Access control)** — in covered healthcare deployments where a verified party identity is the precondition to granting access to protected health information, the verification-gates-activity decision is the structural form of the access-granting event: access is provisioned only through a substantiated, audited verification. This composition is anchored in the BSA/AML/FATF cluster; the HIPAA mapping applies where a covered entity uses verification-based provisioning.

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

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/customer-onboarding.md`.

- **2026-08-26 — Invariant 4 is narrowed to the actor the composition authenticates.** *Chose:* the clearing actor, whose credential is verified, attests that fresh evidence naming the verifying actor was recorded before the reinstatement. *Over:* requiring `verifying_actor_ref == actor_ref`, or taking a second credential. *Because:* the first collapses a real separation of duties (an analyst gathers evidence, a manager clears the review) and the second is a signature change; the guarantee was narrowed to what the records can show.
- **2026-08-27 — The active-relationship retention is a renewed chain, not one placement.** *Chose:* the periodic path of [Trigger Monitoring Review] places a fresh active-relationship retention at every review, recorded as `customer-onboarding.retention-renewed`, with Configuration requiring the policy's duration to exceed the review interval. *Over:* a single placement at intake, or an active-case purge gate composed through Defensible Retention. *Because:* a Retention Window placement is fixed-duration and its policy immutable, so a single placement lawfully lapses under a relationship longer than its duration; a purge gate would protect the record but leave it under no retention obligation at all, and the composition exposes no purge surface to gate.
- **2026-08-29 — The reconciliation is a declared, bounded scan whose pre-check keys on the intent.** *Chose:* onboarding_completion_bound below and the audit horizon above; compensation window and reconciliation cadence declared; the pre-check traversal matched on intent event id rather than on "the same identifying payload". *Over:* a retry-until-lands with an undeclared cadence and a payload-resemblance pre-check. *Because:* the pre-check cannot see an invocation that has not written yet, so a re-emission inside the bound lands a second outcome for one act; and resemblance chooses where a key does not (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*).
- **2026-09-14 — The monitoring schedule and the open-trigger set are derived indexes, not extraction-pending state.** *Chose:* all four indexes classified as derived index, each with a named rebuild, a per-index definition of *miss*, and the same horizon bound; the proposed **Review Schedule** atom kept as `Non-goal 17` rather than as a classification. *Over:* keeping the schedule half flagged extraction-pending, or extending the flag to the open-trigger set for consistency. *Because:* the section titled Composition state in `execution-contract.md` asks one question — is every fact derivable from the constituents' stores through their declared reads — and the spec's own rebuild answered yes for both, in the same subsection that flagged one of them as non-derivable. Two sentences cannot both be the classification, and the Contract's test picks which. The extraction may still be worth making; it is a concept named for someone to own, not a debt riding this composition's classification. Closes the Ledger's `2026-08-26-k` (the flag asserted Pass 2 gates nobody ran) and `2026-08-29-l` (Gate 3 applied unevenly across four elements).
- **2026-09-14 — The external path admits `Unverified` and nothing else.** *Chose:* one guard and one parameterized refusal, [Party Not Admissible], naming the state found. *Over:* keeping the `party-closed` arm and adding a second arm for `Verified` and `Suspended`. *Because:* the prose guarded `Closed` alone, so a `Suspended` admit opened a case with an empty open-trigger set against a suspended party and a `Verified` admit passed the gate with no verification record of this composition's — a hole in the composition's own load-bearing guarantee, reachable from the ordinary external path. A second arm beside `party-closed` would have split one guard's answer across two codes; the fold gives the caller one code and the state it needs.
- **2026-09-14 — state-unavailable is mapped from the seam, not from a constituent arm.** *Chose:* an unanswered constituent read is the state-unavailable of the section titled Step 1 failure in `execution-contract.md`, and Party Identity's declared `invalid-query` arm maps to invalid-request as this composition's own defect. *Over:* continuing to map state-unavailable from Party Identity's `read`. *Because:* that atom's `read` declares two answers — the matching parties, or `invalid-query` — and neither is an unreadable store, so the mapping named a contract the constituent does not have. The gate's fail-closed behaviour is unchanged; what changed is where the page says it comes from.
- **2026-09-14 — Rewritten in GRACE lang v0.41.** *Chose:* 180.5 KB of prose replaced by labelled rules across fifteen families, eight invariant numbers unchanged, thirty-eight of thirty-nine Ledger lines closed by the rewrite. *Over:* a mechanical transliteration that would have carried the page's four internal contradictions into the rule surface. *Because:* a defect the rewrite finds is repaired in the pass that finds it; the repairs are named in the entries above and in the commit that lands this.

NOTE: End of Customer Onboarding.
