---
title: Propagate Consent Revocation Downstream
parent: Conceptual Compositions
nav_order: 17
has_toc: true
toc: true
---

# Propagate Consent Revocation Downstream

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

This composition is a regulated composition (a spec that wires two or more atoms — freestanding, self-contained pattern specs — together) that solves a problem none of its constituents solves alone: ensuring that a system processes personal data on a consent basis only while valid consent exists, that the people authorized to record and withdraw consent are themselves authorized to do so, that consent records survive for the regulator-mandated proof period, and — the property that defeats naive implementations — that withdrawing consent *propagates*: the act of revocation is followed, in a fixed order and tamper-evidently, by a record of the complete set of downstream processing activities that were relying on the now-withdrawn consent. It wires four constituents: Consent (the data subject's grant/revoke/expire lifecycle with its point-in-time `check`), Permissions (the inward authorization surface governing which internal actor may administer consent), the Audit Trail substrate (the shared regulated-audit layer the composition records on — tamper-evident, designed so unauthorized changes are detectable — which stamps every state-changing decision with the verified actor who made it and seals it, binding it into a hash a later change would break, and through which Event Log, Actor Identity, the audit-event Retention Window, and Tamper Evidence are reached transitively), and a consent-record Retention Window instance (the policy-bounded lifetime holding each consent record as demonstrability evidence, distinct from the substrate's audit-event instance).

The composition's defining emergent guarantee (a property that appears only when atoms are combined — no single atom carries it) has two halves. *Consent-gates-processing:* a single read-only query, `processing_permitted(subject_ref, purpose)`, returns permitted if and only if Consent reports valid consent (`check` → granted) for that subject and purpose at the current time. Processing systems consume this query rather than reading Consent directly, so the gate is implemented exactly once instead of re-implemented — or skipped — per processing system. *Revocation propagates:* [Withdraw Consent] revokes the consent and then records a `consent.revoked` Audit Trail event whose `affected_scopes` set is exactly the downstream processing scopes registered against that consent. These two writes commit together, the event ordered after the revoke, which gives the guarantee an auditor needs without qualification, since a propagation record always has a real revocation behind it. Where the event cannot be recorded, the revocation stands without it — the one gap left, which is always visible, always repaired within a declared window, and never a processing-suppression gap, because the gate reads the consent records directly and is honest the instant the revoke commits — given the single-active-grant rule [Record Consent] enforces (Invariant 1.3), which is what makes the record revoked the record the gate evaluates for its subject and purpose.

Beyond the gate and the propagation, the composition guarantees that every consent grant is attributed and tamper-evidently recorded, that consent records are held under a retention floor that survives revocation (a withdrawn consent is evidence, not garbage — it must outlive its own withdrawal for the regulator's proof period), that the complete consent lifecycle is provable, and that every consent-administration action passes a Permissions check before it touches the consent records.

 Its most common uses are advertising and marketing consent management under GDPR (the EU General Data Protection Regulation)/ePrivacy, health-app and research consent under HIPAA (the US Health Insurance Portability and Accountability Act) Authorization, cookie-consent backends under the ePrivacy Directive, and any system that must make it provable that consent-based processing was gated on valid consent and that every withdrawal's downstream impact was enumerated and sealed.

---

## Intent

Every system that processes personal data on the basis of consent faces the same regulated obligation, and it is the same whether the system is an advertising platform, a health app, an analytics pipeline, or a cookie-banner backend. Before processing for a consent-based purpose, the system must confirm a valid consent exists; the data subject must be able to withdraw that consent as easily as they gave it; and — the limb that defeats most real deployments — when consent is withdrawn, the systems that were relying on it must *stop*, which means the withdrawal cannot be a private fact buried in the consent records but must propagate to every downstream process that was acting on the basis now gone. GDPR Article 6(1)(a) names consent as a lawful basis; Article 7 fixes its conditions (freely given, specific, informed, demonstrable); Article 7(3) requires withdrawal be as easy as grant and, read with Article 17(1)(b), that withdrawal end the basis for future processing. The domain varies; the structural obligation is constant: gate processing on consent, and make withdrawal propagate provably.

No constituent, alone, enforces this arc. Consent owns the grant/revoke/expire lifecycle and the `check` query that answers *is there valid consent for this subject and purpose at this time?* — but it deliberately stops there: its own specification states *"the atom does not enforce processing suppression"* and names downstream propagation as out of scope, for a composing layer to handle — this one. Consent records that consent was withdrawn; it neither knows what downstream processing relied on it nor records which processes must now cease. Permissions owns inward authorization — *which internal actor may grant, revoke, or read a consent record on a data subject's behalf* — but it knows nothing of consent state. The Audit Trail substrate records attributed, tamper-evident, retention-bounded events but does not know which events constitute a consent's propagation history. The consent-record Retention Window instance holds each consent record for its proof period but knows nothing of consent semantics. The structure that makes the four coherent as a single consent-management surface — the gate that centralizes the consent precondition, the downstream-registration index that makes "what relied on this consent" a recorded fact, and the propagation event that follows revocation in a fixed order — belongs to no single constituent. It belongs to the composition, and this composition is that structure.

This is a composition, not a new primitive. Consent, Permissions, Audit Trail, and Retention Window are unchanged; the composition is the wiring that makes them coherent as a single consent-management surface. It introduces emergent actions — [Record Consent], [Register Processing], [Withdraw Consent], [Read Consent History], [Processing Permitted] — that belong to no single constituent and exist only because the constituents are wired together. The [Withdraw Consent] action, in particular, wraps a Consent `revoke`, an enumeration of the consent's registered downstream scopes, and the tamper-evident propagation event into one named surface, ordered revoke-then-event, so that withdrawing consent is one auditable act whose downstream impact is recorded — not a Consent `revoke` whose consequences leak silently into whatever processing systems happen to re-check, or fail to re-check, the consent records.

What the composition is *not*: it is not the consent-collection UI (user interface — the banner, the form, the verbal-capture integration that produces the grant signal — that is upstream, producing the inputs [Record Consent] records); it is not the data-erasure engine (whether withdrawal triggers deletion of derived data under Article 17 is the downstream processor's obligation, signalled by the propagation event, not performed by this composition); it is not a lawful-basis adjudicator for non-consent bases (legitimate interest, contract necessity, legal obligation are GDPR Article 6 bases this composition does not model — a Customer Due Diligence obligation under Customer Onboarding rests on Article 6(1)(c), not consent, and is explicitly out of scope here); and it is not the access-control surface for internal operators beyond the consent-administration actions it gates. Each is named explicitly in Non-goals.

---

## Composes

- **[Consent](../atoms/consent.md)** — the data subject's grant, revoke and expire lifecycle, with the point-in-time check the gate delegates to.
- **[Permissions](../atoms/permissions.md)** — the inward authorization surface: which internal actor may administer a consent record.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate: every state-changing act of the composition is an attributed, sealed, retention-governed Audit Trail event.
- **[Retention Window](../atoms/retention-window.md)** — the consent retention instance: one placement over each consent record, marking how long the controller must be able to produce it.

```
Composes 1: EXACTLY ONE Consent instance MUST serve the composition.
Composes 2: EXACTLY ONE Permissions instance MUST serve the composition.
Composes 3: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 4: EXACTLY ONE Retention Window instance MUST serve the composition.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST NOT change a constituent's spec.
Composes 7: The composition MUST reach a transitive atom ONLY through Audit Trail.
Composes 8: The composition MUST NOT compose an instance of a transitive atom.
Composes 9: The composition MUST select audit events through the log read.
Composes 10: The composition MUST read an event by id ONLY through the record read.
Composes 11: A deployment MUST NOT call the grant write outside the composition.
Composes 12: A deployment MUST NOT call the revoke write outside the composition.
Composes 13: A deployment MUST NOT call the consent read outside the composition.
Composes 14: A deployment MUST NOT record an event under the consent namespace outside the composition.
```

Term composition: this pattern's wiring of [Consent](../atoms/consent.md), [Permissions](../atoms/permissions.md), [Audit Trail](./audit-trail.md) and a [Retention Window](../atoms/retention-window.md) instance — the gate, the registration surface, the withdrawal with its propagation, the history read, the three indexes and the reconciliation.

Term constituents: [Consent](../atoms/consent.md), [Permissions](../atoms/permissions.md), [Audit Trail](./audit-trail.md), [Retention Window](../atoms/retention-window.md).

Term transitive atoms: [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md), [Tamper Evidence](../atoms/tamper-evidence.md) and the audit-event [Retention Window](../atoms/retention-window.md), reached through Audit Trail.

Term consent retention instance: the composition's own Retention Window instance, holding one placement per consent record — distinct from the Retention Window instance inside Audit Trail, which governs the audit events.

Term log read: Event Log's read by sequence-number range, from one with an open upper bound, passed through Audit Trail unchanged, with every selection by action reference and payload field made in the composition's own code.

Term record read: Audit Trail's read_record on an event id.

Term audit write: Audit Trail's record_action.

Term verification: Audit Trail's verify_record on an event id and a presentation.

Term grant write: Consent's grant.

Term revoke write: Consent's revoke.

Term consent check: Consent's check on a subject reference and a purpose.

Term consent read: Consent's read.

Term permission check: Permissions' permitted on an actor reference and a scope.

Term retention placement: Retention Window's place_under_retention on the consent retention instance.

Term consent namespace: the action references consent.grant_intended, consent.granted, processing.registered, consent.withdrawal_intended, consent.revoked, consent.history-read, consent.recovery_intended and consent.propagation_escalated on the composition's Audit Trail instance.

Adjacent, **not** constituents: [Customer Onboarding](./customer-onboarding.md), whose basis is GDPR Article 6(1)(c) legal obligation where this composition governs the Article 6(1)(a) consent basis — the two coexist for one party; [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md), which takes this composition's history read and propagation events as inputs to access and erasure responses; [Preference-Aware Notification Fanout](./preference-aware-notification-fanout.md), which shapes processing already lawful (Non-goal 4); and a downstream-action engine or [Notification Fanout](./notification-fanout.md), which performs the cessation this composition signals (Non-goal 1).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the downstream index, the retention index AND the subject index.
Composition state 2: The composition MUST key EVERY index by consent id.
Composition state 3: The composition MUST identify a binding by the binding's pair.
Composition state 4: A binding MUST carry the registration instant AND the registration event id of the pair's first registration event.
Composition state 5: A repeat registration MUST NOT change a binding.
Composition state 6: The composition MUST NOT remove a binding.
Composition state 7: The composition MUST NOT change a key entry.
Composition state 8: The composition MUST classify a live index entry as a derived index.
Composition state 9: The composition MUST rebuild the live downstream entries PER the downstream rebuild.
Composition state 10: The composition MUST rebuild the live key entries PER the grant rebuild.
Composition state 11: The composition MUST NOT rebuild an index entry from a constituent's records.
Composition state 12: The composition MUST read the enumeration of a constituent's records ONLY as a cross-check against a rebuild.
Composition state 13: The composition MUST classify a purged index entry as truth-bearing.
Composition state 14: A rebuild MUST NOT remove a purged index entry.
Deleted: Composition state 15. Execution Contract Database 3 owns it.
Composition state 16: The composition MUST classify a purged downstream entry as extraction-pending against Processing Register.
Composition state 17: The composition MUST classify a purged key entry as extraction-pending against Erasure Tombstone.
Composition state 18: The composition MUST decide a downstream entry's horizon by the record read on the entry's registration event.
Composition state 19: The composition MUST NOT decide a downstream entry's horizon by an instant.
Composition state 20: The composition MUST NOT store a consent validity flag.
Composition state 21: The composition MUST NOT duplicate a constituent's records.
```

Term consent id: the opaque id Consent's grant mints for a consent record — consent_id.

Term downstream index: the map from a consent id to the consent's bindings — `consent_to_downstream` in an implementation.

Term retention index: the map from a consent id to the consent retention's id — `consent_to_retention` in an implementation.

Term subject index: the map from a consent id to the consent's subject reference and purpose — `consent_to_subject_purpose` in an implementation.

Term index entry: one consent id's value in one index.

Term downstream entry: an index entry of the downstream index.

Term retention entry: an index entry of the retention index.

Term subject entry: an index entry of the subject index.

Term binding: one registered downstream processing activity of a consent — a pair with the pair's first registration instant and registration event id.

Term pair: a [Processing Scope] with the processor reference that operates it.

Term repeat registration: a registration event whose pair the consent's downstream entry already holds.

Term registration event id: the event id of a registration event.

Term live index entry: a downstream entry whose registration event the record read answers Retained, or a key entry the grant rebuild reproduces.

Term purged index entry: a downstream entry whose registration event the record read answers Purged, or a key entry the grant rebuild no longer reproduces because the audit horizon destroyed the grant event's payload.

Term purged downstream entry: a downstream entry that is a purged index entry.

Term key entry: a retention entry or a subject entry.

Term purged key entry: a key entry that is a purged index entry.

Term live downstream entry: a downstream entry that is a live index entry.

Term live key entry: a key entry that is a live index entry.

Term downstream rebuild: the log read kept to the registration events, each recorded as its payload's pair and registration instant against its consent id and its own event id, the earliest registration instant kept where a pair repeats.

Term grant rebuild: the log read kept to the grant events, each recorded as its payload's retention id and its subject reference and purpose against its consent id.

Term consent validity flag: a stored granted, expired or still-consented value.

### Capability requirement

```
Capability requirement 1: The composition MUST NOT substitute a retention policy reference for the caller's.
Capability requirement 2: A deployment MUST set the audit retention policy on the Audit Trail instance.
Capability requirement 3: The composition MUST NOT pass a retention input to the audit write.
Capability requirement 4: EVERY consent retention period MUST NOT EXCEED the audit horizon.
Capability requirement 5: A regulated deployment MUST pass a retention policy reference encoding the regime's proof period.
Capability requirement 6: A deployment MUST set the compensation window.
Capability requirement 7: A deployment MUST set the reconciliation cadence.
Capability requirement 8: A deployment MUST disclose the outcome write latency.
Capability requirement 9: A deployment MUST set the administration completion bound.
Capability requirement 10: The composition MUST start ONLY IF the compensation window EXCEEDS the liveness sum.
Deleted: Capability requirement 11. Execution Contract Database 1 owns it.
Deleted: Capability requirement 12. Execution Contract Database 1 owns it: the composition names no retry span for the administration completion bound to cover.
Capability requirement 13: A deployment MUST set the field length cap, the registrations cap, the intent candidates cap AND the event id width.
Capability requirement 14: The composition MUST start ONLY IF the maximal envelope DOES NOT EXCEED Audit Trail's payload cap.
Capability requirement 15: A deployment MUST set the clock offset allowance.
Deleted: Capability requirement 16. Execution Contract Database 2 owns it.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it.
Deleted: Capability requirement 18. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 19. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to lease.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 22. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion for a host to lack.
Capability requirement 23: A deployment MUST provision the recovery identity.
Deleted: Capability requirement 24. Execution Contract Database 3 owns it.
Deleted: Capability requirement 25. Execution Contract Database 3 owns it.
Capability requirement 26: The wired Audit Trail instance MUST expose the log read.
Capability requirement 27: The host MUST inject now at the seam once per invocation.
Capability requirement 28: The composition MUST stamp EVERY instant one invocation writes from the invocation's now.
Capability requirement 29: The host MUST inject the reconciliation's now at the reconciliation's own seam.
Capability requirement 30: A deployment MUST expose [Processing Permitted] ONLY to processing systems.
Capability requirement 31: A processing activity MUST NOT process on a consent basis BEFORE the activity's registration event lands.
Capability requirement 32: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
```

Term retention policy reference: the consent-record policy a caller passes to [Record Consent] — retention_policy_ref, required, resolved in Retention Window's Policy Registry; the deployment's recommended value is configured as `consent_record_retention_policy_ref`.

Term consent retention period: the duration a retention policy reference assigns a consent record.

Term audit retention policy: the retention policy configured on the composition's single Audit Trail instance, governing every audit event it records — `audit_trail_retention_policy`.

Term audit horizon: the audit retention policy's horizon.

Term regulated deployment: a deployment under a regime fixing a proof period — GDPR (the EU General Data Protection Regulation) Article 7(1)'s demonstrability burden, or HIPAA (the US Health Insurance Portability and Accountability Act)'s six-year Authorization retention.

Term compensation window: the duration within which an orphan must reach its closure — `compensation_window`. It is this composition's own, distinct from Audit Trail's compensation-window qualifier, which bounds the substrate's repair of its own retention arm.

Term reconciliation cadence: the interval between the reconciliation's runs — `reconciliation_cadence`, this composition's own and distinct from any cadence the substrate runs.

Term outcome write latency: the deployment's disclosed bound on one audit write landing.

Term administration completion bound: the longest a [Record Consent] or [Withdraw Consent] invocation may run from its seam reading to its last audit write.

Term liveness sum: `administration completion bound + reconciliation cadence + outcome write latency`.

Term field length cap: the byte length no payload string may exceed.

Term registrations cap: the most distinct pairs one consent may hold.

Term intent candidates cap: the most intent candidates one compensating event may name.

Term event id width: the widest event id the wired Audit Trail instance mints, which the substrate does not itself disclose.

Term maximal envelope: the largest compensating propagation event the composition could write — the registrations cap's pairs at the field length cap, the intent candidates cap's candidates at the event id width, every reference and the reason at the field length cap, and the fixed fields — serialized as the substrate sizes it.

Term clock offset allowance: the declared bound on the difference between the composition's seam clock and the clocks at Consent's seam and the substrate's.

Term recovery identity: the composition's registered actor reference and credential — `application_actor_ref` and `application_credential` — under which the reconciliation attests every write it makes.

Term processing system: a system that processes personal data on a consent basis.

Term processing activity: one downstream processing a processing system runs under a [Processing Scope].

Term seam: the composition's input and output boundary — the one place the host reads the clock, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam, once per invocation.

### Primitive policy

```
Primitive policy 1: IF a payload string EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 2: IF a payload string's length EXCEEDS the field length cap THEN the action MUST answer invalid-request.
Primitive policy 3: IF the actor reference EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 4: IF the credential EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 5: IF the subject index misses the consent id THEN the action MUST answer not-known.
Primitive policy 6: IF the pair IS NOT IN the registered set AND the registered set's count EQUALS the registrations cap THEN [Register Processing] MUST answer registration-cap-exceeded.
Primitive policy 7: IF the propagation envelope EXCEEDS Audit Trail's payload cap THEN [Withdraw Consent] MUST answer invalid-request.
Primitive policy 8: An action refused under Primitive policy 1 through 7 MUST NOT write.
Primitive policy 9: The composition MUST NOT record an audit event for a call BEFORE Primitive policy 1 through 7 pass.
Primitive policy 10: The composition MUST compare a consent id, an event id AND a caller string byte-exact.
Primitive policy 11: The composition MUST NOT normalize a caller string.
Primitive policy 12: The composition MUST NOT inspect a credential.
Primitive policy 13: The composition MUST NOT interpret an opaque reference.
```

Term payload string: a caller string the composition writes into an audit payload — a subject reference, a purpose, a [Processing Scope], a processor reference, a reason or a retention policy reference.

Term caller string: a payload string, an actor reference, a credential or a consent id.

Term subject reference: the opaque reference to the data subject — subject_ref. Permissions' own spec uses the same words for the permission-holding actor; at this composition's boundary that role is always the actor reference, so the collision never crosses a signature.

Term purpose: the opaque processing purpose a consent covers — marketing:email, analytics:behavioral, hipaa:research; its taxonomy is the deployment's, inherited from Consent's purpose-vocabulary edge case.

Term processor reference: the opaque reference to the system or party operating a processing activity — processor_ref.

Term reason: the free-form reason a withdrawal passes to the revoke write.

Term actor reference: the operator performing an administration action — actor_ref, the subject of the permission check and the actor the audit write attests.

Term credential: the operator's authentication material, consumed only by the audit write.

Term opaque reference: a subject reference, a purpose, a [Processing Scope] or a processor reference.

Term registered set: the pairs of every registration event carrying the consent id, together with the purged downstream entries for the consent id.

Term propagation envelope: the propagation event and its compensating event as the withdrawal's propagation set would make them, every field and the intent candidates cap's candidates at their widths, serialized as the substrate sizes it.

### Audit arm

```
Audit arm 1: IF Audit Trail answers invalid-credential at an intent THEN the action MUST answer invalid-credential.
Audit arm 2: IF Audit Trail answers invalid-request carrying any step at an intent THEN the action MUST answer invalid-request.
Audit arm 3: IF Audit Trail answers recording-failure at an intent THEN the action MUST answer recording-failure carrying intent.
Audit arm 4: The composition MUST NOT retry an invalid-request answer.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Audit arm 6: The deployment MUST alert on EVERY later write landed with the retention step failed.
Audit arm 7: IF Audit Trail answers invalid-credential at a later write THEN the action MUST answer invalid-credential.
Audit arm 8: IF Audit Trail answers invalid-request carrying step-1, step-2 or step-3 at a single write THEN the action MUST answer invalid-request.
Audit arm 9: The deployment MUST alert on EVERY invalid-request at a later write as a deployment fault.
Deleted: Audit arm 10. Execution Contract Database 1 owns it.
Deleted: Audit arm 11. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an outcome.
Audit arm 12: IF Audit Trail answers recording-failure carrying a pre-append step at an outcome THEN the action MUST answer recording-failure carrying outcome.
Audit arm 13: IF Audit Trail answers recording-failure carrying a pre-append step at a single write THEN the action MUST answer recording-failure.
Audit arm 14: A caller MUST read recording-failure carrying intent as a committed nothing.
Audit arm 15: A caller MUST read recording-failure carrying outcome as a committed Consent record.
Audit arm 16: IF Audit Trail answers invalid-request carrying the retention step at a later write THEN the invocation MUST proceed as landed.
Audit arm 17: IF Audit Trail answers invalid-request carrying step-1, step-2 or step-3 at an outcome THEN the action MUST answer recording-failure carrying outcome.
```

Term intent: a grant intent or a withdrawal intent — the audit write an action makes before its first Consent write, the one that verifies the caller's credential.

Term outcome: a grant event or a propagation event — the audit write an action owes after its Consent write.

Term single write: a registration event or an access event — the one audit write of an action that commits nothing before it.

Term later write: an outcome or a single write.

Term pre-append step: a recording-failure step naming a step before the substrate's append — step-2 or step-3; the event is not in the log.

Term retention step: the step naming the substrate's retention placement on an invalid-request — step-4; the event is appended and attested.

Term position: intent | outcome — where a recording-failure sat: intent, nothing committed and the whole action may be re-run; outcome, the Consent record committed and its audit event is owed.

### Action wiring

```
record_consent(actor_ref, subject_ref, purpose, credential, retention_policy_ref, optional expires_at, optional metadata)
  answers consent id
  refuses permission-denied | already-granted | invalid-credential | invalid-request | recording-failure(position)

register_processing(actor_ref, consent_id, processing_scope, processor_ref, credential)
  answers registered
  refuses permission-denied | not-known | registration-cap-exceeded | invalid-credential | invalid-request | recording-failure

withdraw_consent(actor_ref, consent_id, credential, reason)
  answers withdrawn
  refuses permission-denied | not-known | already-revoked | already-expired | invalid-credential | invalid-request | recording-failure(position)

read_consent_history(actor_ref, subject_ref, credential)
  answers consent history
  refuses permission-denied | invalid-credential | invalid-request | recording-failure

processing_permitted(subject_ref, purpose)
  answers permitted
  refuses invalid-request | not-permitted(withheld state)
```

Term consent history: the subject's Consent records in Consent's order — by grant instant, then consent id.

Term withheld state: revoked | expired | not-known — the consent check's answers other than granted.

Term expiry: the optional expires_at a caller passes to Consent's grant unchanged.

Term metadata: the optional opaque metadata a caller passes to Consent's grant unchanged — a consent-form version, for one.

```
Action wiring 1: EVERY administration action MUST call the permission check with the actor reference AND the action's scope.
Action wiring 2: IF the permission check answers denied THEN the administration action MUST answer permission-denied.
Action wiring 3: An administration action MUST NOT write BEFORE the permission check answers permitted.
Action wiring 4: A validated grant MUST record the grant intent carrying the subject reference, the purpose, the retention policy reference, the expiry AND now as the intent instant.
Action wiring 5: A grant intent MUST NOT carry a consent id.
Deleted: Action wiring 6. Execution Contract Database 2 owns it.
Action wiring 7: An admitted grant MUST call the consent check with the subject reference AND the purpose.
Action wiring 8: IF the consent check answers granted THEN [Record Consent] MUST answer already-granted.
Action wiring 9: A checked grant MUST call the grant write with the subject reference, the purpose, the actor reference as the grantor, the expiry AND the metadata.
Action wiring 10: The composition MUST NOT pass an instant to the grant write.
Action wiring 11: IF the grant write answers storage-failure THEN [Record Consent] MUST answer recording-failure carrying intent.
Action wiring 12: IF the grant write answers invalid-request THEN [Record Consent] MUST answer invalid-request.
Action wiring 13: A committed grant MUST call the retention placement with the consent id AND the retention policy reference.
Action wiring 14: IF the retention placement answers a placement refusal THEN [Record Consent] MUST answer invalid-request.
Deleted: Action wiring 15. Execution Contract Database 1 owns it.
Deleted: Action wiring 16. Execution Contract Database 1 owns it.
Action wiring 17: A placed grant MUST record the grant event carrying the intent event id, the consent id, the subject reference, the purpose, the expiry AND the retention id.
Action wiring 18: A landed grant MUST write the retention entry AND the subject entry.
Action wiring 19: A landed grant MUST answer the consent id.
Deleted: Action wiring 20. Execution Contract Database 2 owns it.
Action wiring 21: A validated registration MUST record the registration event carrying the consent id, the processing scope, the processor reference AND now as the registration instant.
Action wiring 22: A landed registration MUST add the binding carrying the registration event's registration instant AND event id.
Action wiring 23: A landed registration MUST answer registered.
Action wiring 24: The composition MUST write an index entry for a consent id ONLY AFTER the consent id's grant event lands.
Action wiring 25: The composition MUST add a binding ONLY AFTER the binding's registration event lands.
Action wiring 26: [Register Processing] MUST NOT call the consent check.
Deleted: Action wiring 27. Execution Contract Database 2 owns it.
Action wiring 28: A resolved withdrawal MUST derive the propagation set.
Action wiring 29: The composition MUST derive a propagation set from the registration events AND the purged downstream entries.
Action wiring 30: The composition MUST NOT derive a propagation set from a live downstream entry.
Action wiring 31: IF a derivation finds a registration event whose pair the downstream index lacks THEN the derivation MUST add the binding.
Action wiring 32: A validated withdrawal MUST record the withdrawal intent carrying the consent id, the subject reference, the purpose, the reason AND now as the intent instant.
Action wiring 33: A withdrawal intent MUST NOT carry the propagation set.
Action wiring 34: An admitted withdrawal MUST call the revoke write with the consent id, the actor reference as the revoker, the reason AND now as the revocation instant.
Action wiring 35: IF the revoke write answers already-revoked THEN [Withdraw Consent] MUST answer already-revoked.
Action wiring 36: IF the revoke write answers already-expired THEN [Withdraw Consent] MUST answer already-expired.
Action wiring 37: IF the revoke write answers invalid-request THEN [Withdraw Consent] MUST answer invalid-request.
Action wiring 38: IF the revoke write answers storage-failure THEN [Withdraw Consent] MUST answer recording-failure carrying intent.
Action wiring 39: IF the revoke write answers not-known THEN [Withdraw Consent] MUST answer not-known.
Action wiring 40: IF the revoke write answers not-known THEN the composition MUST open an index-anomaly finding for the consent id.
Action wiring 41: A committed withdrawal MUST record the propagation event carrying the intent event id, the consent id, the subject reference, the purpose, the reason, the propagation set AND the revocation instant.
Action wiring 42: A landed withdrawal MUST answer withdrawn.
Deleted: Action wiring 43. Reconciliation 9 and Execution Contract Database 1 own it.
Deleted: Action wiring 44. Reconciliation 9 and Execution Contract Database 1 own it.
Deleted: Action wiring 45. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Action wiring 46. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Action wiring 47. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Action wiring 48: A validated history read MUST call the consent read with the subject reference.
Action wiring 49: IF the consent read answers invalid-query THEN [Read Consent History] MUST answer invalid-request.
Action wiring 50: A fetched history read MUST record the access event carrying the subject reference AND the record count.
Action wiring 51: [Read Consent History] MUST NOT answer the consent history BEFORE the access event lands.
Action wiring 52: A landed history read MUST answer the consent history.
Action wiring 53: A validated gate query MUST call the consent check with the subject reference AND the purpose.
Action wiring 54: [Processing Permitted] MUST NOT pass an instant to the consent check.
Action wiring 55: IF the consent check answers granted THEN [Processing Permitted] MUST answer permitted.
Action wiring 56: IF the consent check answers a withheld state THEN [Processing Permitted] MUST answer not-permitted carrying the withheld state.
Action wiring 57: [Processing Permitted] MUST NOT record an audit event.
```

Term administration action: [Record Consent], [Register Processing], [Withdraw Consent] or [Read Consent History].

Term action's scope: [Consent Grant] for [Record Consent], [Consent Register Processing] for [Register Processing], [Consent Revoke] for [Withdraw Consent], [Consent Read] for [Read Consent History].

Term grant intent: the consent.grant_intended event.

Term grant event: the consent.granted event — the grant's outcome, carrying the consent id.

Term registration event: the processing.registered event.

Term withdrawal intent: the consent.withdrawal_intended event.

Term propagation event: the consent.revoked event — the withdrawal's outcome, carrying the propagation set.

Term access event: the consent.history-read event.

Term intent event id: the event id of the intent an outcome pairs with — intent_event_id.

Term intent instant: the now an intent carries — intended_at.

Term registration instant: the now a registration event and its binding carry — registered_at.

Term revocation instant: the now a withdrawal passes to the revoke write and its propagation event carries — revoked_at.

Term grantor: the actor reference a grant write records — granted_by.

Term revoker: the actor reference a revoke write records — revoked_by.

Term retention id: the id the retention placement mints — consent_record_retention_id on the grant event.

Term placement refusal: invalid-policy | policy-not-found | invalid-request — Retention Window's refusals of the retention placement.

Term record count: how many Consent records a history read returned.

Term propagation set: [Affected Scopes] — the registered set as of the withdrawal intent: the pairs of the registration events carrying the consent id that PRECEDE the withdrawal intent in the Event Log, together with the purged downstream entries for the consent id.

Term validated grant: a [Record Consent] call whose permission check answered permitted and whose inputs cleared Primitive policy.

Term admitted grant: a validated grant whose grant intent landed.

Term checked grant: an admitted grant whose consent check answered a withheld state.

Term committed grant: a checked grant whose grant write answered a consent id.

Term placed grant: a committed grant whose retention placement answered a retention id.

Term landed grant: a placed grant whose grant event landed.

Term resolved registration: a [Register Processing] call whose permission check answered permitted and whose consent id the subject index resolves.

Term validated registration: a resolved registration whose inputs cleared Primitive policy.

Term landed registration: a validated registration whose registration event landed.

Term resolved withdrawal: a [Withdraw Consent] call whose permission check answered permitted and whose consent id the subject index resolves.

Term validated withdrawal: a resolved withdrawal whose inputs and propagation envelope cleared Primitive policy.

Term admitted withdrawal: a validated withdrawal whose withdrawal intent landed.

Term committed withdrawal: an admitted withdrawal whose revoke write answered revoked.

Term landed withdrawal: a committed withdrawal whose propagation event landed.

Term validated history read: a [Read Consent History] call whose permission check answered permitted and whose inputs cleared Primitive policy.

Term fetched history read: a validated history read whose consent read answered.

Term landed history read: a fetched history read whose access event landed.

Term validated gate query: a [Processing Permitted] call whose inputs cleared Primitive policy.

Term invocation: one call of a state-changing action, from its seam reading to its answer.

Term owed outcome: the outcome a consent's act owes — for a grant, or an ungranted record, a grant event carrying the consent id; for a withdrawal, or an unpropagated record, a propagation event carrying the consent id. A grant event and a propagation event carry one consent id, so a read keyed on the consent id alone would find the wrong one.

Term index-anomaly finding: a finding that the subject index resolves a consent id the Consent records do not know.

### Wiring decision

```
Wiring decision 1: The composition MUST append a propagation event ONLY AFTER the revoke write answers revoked.
Deleted: Wiring decision 2. Execution Contract Database 1 owns it.
Wiring decision 3: The composition MUST NOT expose a withdrawal surface other than [Withdraw Consent].
Wiring decision 4: The composition MUST NOT expose a consent gate other than [Processing Permitted].
```

WHY:
*Principle.* GDPR Articles 6 and 7 require a valid consent at processing time, and Article 7(3), read with Article 17(1)(b), requires that withdrawal end the basis for future processing — which, operationally, means the systems relying on the consent must learn of the withdrawal. The system must make both provable: that the gate was the single consent precondition, and that every withdrawal's downstream impact was enumerated and sealed at the moment of revocation.

*Likely objection.* Consent already owns the lifecycle and exposes its check. Why not let each processing system call it, and why a propagation event when the revocation is already in the Consent records?

*Mechanism.* Consent owns the state and exposes no gate and no propagation, by design. A check called per system is a gate re-implemented per system, and the first system that forgets it, caches a stale answer or treats expired as granted breaks the Article 6 basis silently (Wiring decision 4). And Consent records *that* a consent was revoked, never *what was relying on it* — importing downstream processing would break its freestanding status — so a revoke alone leaves the withdrawal's downstream impact unrecorded, and a system that never re-checks keeps processing with no record that it should have stopped. The composition closes this with the downstream index, populated by an audited act, and a propagation event carrying the complete set. The event follows the revoke (Wiring decision 1), so a propagation record always has a real revocation behind it — unconditionally, which is the direction an Article 7(3) dispute runs. The gap that remains runs the other way — a revocation whose propagation record has not landed — and it is a gap in the *accounting*, not the *suppression*: the gate reads Consent and answers not-permitted carrying revoked from the instant the revoke commits, given single-active-grant (Invariant 1.3). What would defeat the purpose is the mirror — an event asserting a withdrawal the database does not hold — and the order makes it unreachable.

*Result.* The gate is structural and single; the propagation is complete and sealed *over the registered set*. An auditor answers *when this person withdrew consent, what was supposed to stop, and is it recorded?* by reading one sealed event rather than interviewing every processing system. **What the records cannot prove is outward completeness**: the composition proves what was registered, never that every real processing activity registered — an unregistered one is invisible to the propagation exactly as a gate-bypassing one is invisible to the gate. The two single-surface obligations are paired and the deployment's (Capability requirement 30 and 31; Invariant 1.2).

### Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Reconciliation 2: The reconciliation MUST run every reconciliation cadence.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Reconciliation 4: The reconciliation MUST NOT triage an aged record.
Reconciliation 5: The reconciliation MUST report an aged unpropagated record as propagation history purged.
Reconciliation 6: The reconciliation MUST read EVERY revoked Consent record against the propagation events.
Deleted: Reconciliation 7. Execution Contract Database 2 owns it.
Deleted: Reconciliation 8. Execution Contract Database 2 owns it: the reconciliation's reads of a record and the writes they decide are one transaction, and the composition names no exclusion for another holder to hold.
Reconciliation 9: The reconciliation MUST NOT compensate a record whose owed outcome exists.
Reconciliation 10: The reconciliation MUST pair an unpropagated record to the withdrawal intents carrying the record's consent id whose intent instant EQUALS the record's revocation instant AND whose actor EQUALS the record's revoker.
Reconciliation 11: IF the withdrawal candidate count EQUALS zero THEN the reconciliation MUST open a write-ownership finding for the record.
Reconciliation 12: The reconciliation MUST NOT compensate an unpaired record.
Reconciliation 13: The reconciliation MUST derive a compensating propagation event's propagation set at the earliest candidate's boundary.
Reconciliation 14: The reconciliation MUST re-derive EVERY other field of a compensating event from the indexes, the Consent record AND the retention placement.
Reconciliation 15: The reconciliation MUST read EVERY Consent record against the grant events.
Reconciliation 16: The reconciliation MUST NOT read a zero-candidate ungranted record as a write-ownership finding.
Reconciliation 17: The reconciliation MUST pair an ungranted record to the grant intents carrying the record's grantor as the actor, the record's subject reference AND the record's purpose whose grant skew DOES NOT EXCEED the pairing window.
Deleted: Reconciliation 18. Execution Contract Database 1 owns it.
Deleted: Reconciliation 19. Execution Contract Database 1 owns it.
Reconciliation 20: The reconciliation MUST write a compensated grant's index entries ONLY AFTER the compensating grant event lands.
Reconciliation 21: IF the candidate count EXCEEDS one THEN the compensating event MUST carry the intent candidates.
Reconciliation 22: IF a registration event's pair IS NOT IN the downstream index THEN the reconciliation MUST add the binding from the event's payload.
Reconciliation 23: The reconciliation MUST NOT record an audit event for a binding repair.
Reconciliation 24: The reconciliation MUST NOT record a compensating event BEFORE the reconciliation's recovery intent lands.
Reconciliation 25: A recovery intent MUST carry the kind, the consent id, the intent reference AND the planned writes.
Reconciliation 26: The reconciliation MUST attest EVERY write the reconciliation makes under the recovery identity.
Reconciliation 27: A compensating event MUST carry the recovery flag, the operator AND the intent reference.
Reconciliation 28: The reconciliation MUST retry a compensating event refused with a pre-append step at the reconciliation's next run.
Reconciliation 29: IF an uncompensable cause holds for a record THEN the reconciliation MUST record an escalation carrying the cause.
Reconciliation 30: IF an orphan's escalation instant PRECEDES the reconciliation's now THEN the reconciliation MUST record an escalation carrying the last refusal the orphan's compensation met.
Reconciliation 31: An escalation MUST carry the kind, the consent id, the intent reference, the cause AND the attempt count.
Reconciliation 32: The reconciliation MUST NOT compensate an escalated record.
Reconciliation 33: The reconciliation MUST NOT record a second escalation for one record.
Reconciliation 34: IF an escalation fails to land THEN the reconciliation MUST retry the escalation at the reconciliation's next run.
Reconciliation 35: The reconciliation MUST report EVERY escalated record at EVERY run.
Reconciliation 36: The deployment MUST alert on EVERY orphan as a high-priority finding.
```

Term reconciliation: the leg the composition runs outside every invocation, whose output — a compensated orphan, an escalation or a finding — an auditor awaits within the compensation window.

Term aged record: a Consent record whose grant instant — or, revoked, whose revocation instant — plus the audit horizon PRECEDES the reconciliation's now.

Term unpropagated record: a revoked Consent record no propagation event names, not aged.

Term ungranted record: a Consent record no grant event names, not aged.

Term orphan: an unpropagated record or an ungranted record.

Term unpaired record: an unpropagated record whose withdrawal candidate count EQUALS zero.

Term withdrawal candidate count: how many withdrawal intents Reconciliation 10 pairs to one unpropagated record.

Term grant skew: the absolute difference between a grant intent's intent instant and the record's grant instant — two seams' stamps.

Term grant instant: the instant Consent stamps on a record at its grant write, at Consent's own seam — granted_at.

Term pairing window: `administration completion bound + clock offset allowance`.

Term candidate count: how many intents Reconciliation 10 or 17 pairs to one orphan.

Term intent candidates: the paired intents where more than one pairs — intent_event_candidates.

Term earliest candidate's boundary: the position in the Event Log of the intent candidate with the lowest sequence number, or of the one paired intent.

Term intent reference: the intent event id where one intent pairs, or the intent candidates.

Term recovery intent: the consent.recovery_intended event.

Term compensating event: a grant event or propagation event the reconciliation records under the recovery identity.

Term compensated grant: an ungranted record whose compensating grant event landed.

Term recovery flag: cascade_recovery set to true on a compensating event.

Term operator: the original caller's actor reference, carried in a compensating event's payload as the grantor or the revoker.

Term kind: propagation | grant — which outcome an orphan lacks.

Term planned writes: the event a grant recovery or a propagation recovery will make.

Term escalation: the consent.propagation_escalated event — the closed-state marker for an orphan the reconciliation will not compensate.

Term cause: recording-failure carrying a step | invalid-request carrying a step | no-candidate | candidates-over-cap — what the reconciliation observed.

Term uncompensable cause: an ungranted record's candidate count EQUALS zero — no-candidate; or an orphan's candidate count EXCEEDS the intent candidates cap — candidates-over-cap.

Term escalation instant: a Consent record's grant instant — or, for its withdrawal, its revocation instant — plus the compensation window.

Term attempt count: how many compensating writes the reconciliation made for the orphan.

Term binding repair: a binding the reconciliation adds from a registration event's payload.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent, and each needs two or more working together.

- **Invariant 1 — Consent gates processing.**
  ```
  Invariant 1.1: [Processing Permitted] MUST answer permitted ONLY IF the consent check answers granted at the query's instant.
  Invariant 1.2: A processing system MUST NOT call the consent check.
  Invariant 1.3: Two governed consents in Granted MUST NOT carry one subject reference AND one purpose.
  ```
  Term governed consent: a Consent record a [Record Consent] invocation's grant write created — every record of the composition's Consent instance, where the write surface is kept to the composition (Composes 11).

  Term query's instant: the reading injected at Consent's own seam for the consent check a gate query calls.

- **Invariant 2 — Grant audit coverage.**
  ```
  Invariant 2.1: IF a governed consent's escalation instant PRECEDES now THEN the governed consent MUST carry a grant closure.
  Invariant 2.2: EVERY grant event MUST carry an attestation AND a position in the Event Log sequence.
  ```
  Term grant closure: a grant event naming the consent, or an escalation of kind grant naming the consent.

- **Invariant 3 — Revocation propagation completeness.**
  ```
  Invariant 3.1: EVERY propagation event MUST name a consent the Consent records hold in Revoked.
  Invariant 3.2: Two propagation events MUST NOT carry one consent id.
  Invariant 3.3: A propagation event's propagation set MUST EQUAL the registered set at the event's boundary.
  Invariant 3.4: IF an unpropagated record's surfacing bound PRECEDES now THEN the composition MUST NOT leave the unpropagated record unsurfaced.
  Invariant 3.5: IF a paired unpropagated record's escalation instant PRECEDES now THEN the record MUST carry a propagation closure.
  Invariant 3.6: EVERY compensating event MUST carry the recovery flag.
  ```
  Term event's boundary: the position in the Event Log of the intent the event's intent reference names — the earliest where it names candidates.

  Term surfacing bound: `revocation instant + administration completion bound + reconciliation cadence`.

  Term paired unpropagated record: an unpropagated record that is not an unpaired record.

  Term propagation closure: a propagation event naming the consent, or an escalation of kind propagation naming the consent.

- **Invariant 4 — Downstream registration is recorded.**
  ```
  Invariant 4.1: EVERY binding MUST carry a registration event carrying the binding's pair AND consent id.
  ```
- **Invariant 5 — Provable consent lifecycle.**
  ```
  Invariant 5.1: EVERY governed consent's lifecycle MUST resolve provably from the Consent records, the Audit Trail instance AND the indexes.
  ```
  Term lifecycle: the grant intent and grant event with the Consent record; the registration events with the downstream entry; the withdrawal intent and propagation event with the Revoked record; and every access event.

- **Invariant 6 — Consent-record retention floor.**
  ```
  Invariant 6.1: EVERY consent retention MUST carry Retained.
  Invariant 6.2: IF a governed consent's escalation instant PRECEDES now THEN the governed consent MUST carry a retention closure.
  Invariant 6.3: The composition MUST read a consent retention's proof-period end ONLY from Purge Eligible.
  ```
  Term consent retention: the consent retention instance's record over one consent record.

  Term retention closure: a consent retention naming the consent, or an escalation of kind grant naming the consent.

- **Invariant 7 — Inward and outward authorization stay separate.**
  ```
  Invariant 7.1: An administration action MUST NOT commit a constituent write for an actor the permission check denied.
  Invariant 7.2: A validated gate query MUST call ONLY the consent check.
  ```
- **Invariant 8 — Authentication precedes commitment.**
  ```
  Invariant 8.1: The composition MUST NOT call the grant write BEFORE Audit Trail validates the caller's credential at the grant intent.
  Invariant 8.2: The composition MUST NOT call the revoke write BEFORE Audit Trail validates the caller's credential at the withdrawal intent.
  Invariant 8.3: The composition MUST NOT add a binding BEFORE Audit Trail validates the caller's credential at the registration event.
  Invariant 8.4: The composition MUST NOT answer a consent history BEFORE Audit Trail validates the caller's credential at the access event.
  ```

The gate plus grant coverage gives *substantiated processing* — every consent-based action gated on a recorded, attributed consent. Propagation completeness plus registration recording gives *propagated withdrawal* — every withdrawal's downstream impact enumerated and itself provable. The provable lifecycle and the retention floor close the lifecycle; Invariant 7 keeps the two authorization surfaces apart, and Invariant 8 makes Invariant 7's inward half a claim about a verified operator.

---

## Examples

### Walkthrough — marketing-consent management under GDPR

A retail platform uses this composition to manage marketing consent. Configuration: `consent_record_retention_policy_ref = gdpr_consent_proof_6yr`, `audit_trail_retention_policy = gdpr_audit_10yr`. Permission grants: the consent-service actor holds `consent:grant`, `consent:register-processing`, `consent:revoke`, `consent:read`; the data-subject-request officer `dsr_officer` holds `consent:read`.

1. **Record consent.** A user affirms a marketing-email consent banner; the consent service calls `record_consent(actor_ref="consent_svc", subject_ref="user-4491", purpose="marketing:email", credential=<consent_svc>, retention_policy_ref="gdpr_consent_proof_6yr", expires_at="2027-05-13T00:00:00Z") → consent_id = cns-7001`. Internally: `Permissions.permitted("consent_svc", "consent:grant") → permitted`; then — **before anything commits** — Audit Trail records `consent.grant_intended` → `ev_grant_int_01`, which is where the consent service's credential is checked against the actor registry (had it not validated, the call would have returned `rejected(invalid-credential)` with no consent granted and no retention placed); then `Consent.check("user-4491", "marketing:email") → not-known` — no Granted record for the pair, so single-active-grant holds and the grant proceeds; then `Consent.grant(...) → cns-7001` (Granted); `Retention Window.place_under_retention(cns-7001, gdpr_consent_proof_6yr) → ret_cns_7001`; Audit Trail records `consent.granted` carrying `intent_event_id: ev_grant_int_01`; maps populated. Note what the intent event does **not** carry: no `cns-7001`, which did not exist when it was written and which only `consent.granted` may make resolvable.

2. **Register downstream processing.** Two systems will rely on this consent. `register_processing(actor_ref="consent_svc", consent_id="cns-7001", processing_scope="email-campaign-engine", processor_ref="campaigns@platform", credential=<consent_svc>) → registered`, and again for `processing_scope="lookalike-audience-builder", processor_ref="adtech@platform"`. Each records a `processing.registered` event; `consent_to_downstream[cns-7001]` now holds two bindings.

3. **Gate check before processing.** Before sending a campaign, the email engine calls `processing_permitted("user-4491", "marketing:email") → permitted`. The campaign proceeds.

4. **Withdrawal with propagation.** The user clicks "unsubscribe / withdraw consent." The consent service calls `withdraw_consent(actor_ref="consent_svc", consent_id="cns-7001", credential=<consent_svc>, reason="user-withdrawal-via-preferences") → withdrawn`. Internally: `Permissions.permitted("consent_svc", "consent:revoke") → permitted`; `affected_scopes` derived from the two `processing.registered` events carrying `cns-7001` = `{email-campaign-engine@campaigns, lookalike-audience-builder@adtech}`; Audit Trail records `consent.withdrawal_intended` → `ev_wd_int_01`, verifying the credential before the terminal transition and carrying the consent_id but **not** the `affected_scopes` (one authoritative carrier, Invariant 3); `Consent.revoke(cns-7001, ...) → revoked`; Audit Trail records `consent.revoked` carrying `intent_event_id: ev_wd_int_01` and the complete `affected_scopes` set — *ordered after the revoke*. Invariant 3 holds: the revocation is committed and its complete downstream enumeration is sealed behind it, one propagation event per withdrawal. Invariant 8 holds and is checkable: `ev_wd_int_01` precedes the propagation event in the Event Log's order (their `intended_at` and `revoked_at` are the same injected instant, so the `sequence_number` is what settles it) and names the same operator.

5. **Gate check after withdrawal.** `processing_permitted("user-4491", "marketing:email") → rejected(not-permitted(revoked))`. The email engine and the audience builder, consuming the propagation event or re-querying the gate, cease processing; deleting the derived lookalike audience is the audience builder's own obligation, signalled by the `consent.revoked` event's `affected_scopes`.

6. **DSAR audit.** A data-subject access request calls `read_consent_history(actor_ref="dsr_officer", subject_ref="user-4491", credential=<dsr_officer>)` → the Granted-then-Revoked `cns-7001` record; a `consent.history-read` meta-event is recorded. The complete lifecycle — the grant and its intent, two registrations, the withdrawal-with-propagation and its intent, the access — is provable (Invariant 5), and each state-changing act's records show the operator was verified before it committed (Invariant 8).

### Re-consent path

Six months after withdrawal the user re-enables marketing email. `record_consent(...) → cns-7042` (the single-active-grant check answers revoked, so the grant proceeds; a fresh Granted record, `cns-7001` remaining Revoked as evidence). `processing_permitted("user-4491", "marketing:email") → permitted` (Consent's `check` evaluates the most-recent grant). Downstream processing is re-registered against the new consent_id; the prior consent's propagation record is untouched history.

### Rejection path — a second grant for a pair that already holds one

A retry of the walkthrough's first `record_consent(...)` after a timeout, or a second banner affirmation while `cns-7001` is Granted: the single-active-grant check `Consent.check("user-4491", "marketing:email") → granted` → `rejected(already-granted)`. No second Granted record is created for the pair (Invariant 1.3); the grant intent stands as ordinary residue. Where the first call had committed `cns-7001` and returned `rejected(recording-failure(outcome))`, the refusal is also the caller's signal that the record exists and the scan owns its event — the caller does not grant again.

### Rejection path — withdrawal by an unauthorized operator

An operator lacking `consent:revoke` attempts `withdraw_consent(...)`: the permission check `Permissions.permitted → denied` → `rejected(permission-denied)`. No consent state changes; no propagation event is recorded. (Invariant 7 — administration is permission-gated.)

### Rejection path — withdrawing an already-revoked consent

A retry after a timeout: `withdraw_consent(actor_ref="consent_svc", consent_id="cns-7001", credential=<consent_svc>, reason="retry")` → the withdrawal intent is written (the operator is real and their credential validates), then Consent's already-revoked is relayed as `rejected(already-revoked)`. No second propagation event is recorded; the single `consent.revoked` event from the first withdrawal stands. The retry therefore leaves a `consent.withdrawal_intended` event with no `consent.revoked` event carrying its `intent_event_id` — the expected residue of the authentication discipline, and the worked instance of the triage's other-invocation case (Check 6.4): the consent is Revoked, but by *another* invocation's propagation event, so nothing is owed and no compensating record may be written. (Consent Invariant 3 — terminal absorption — surfaced at the composition boundary.)

### Failure path — withdrawal whose propagation event fails to record

A [Withdraw Consent] call passes its checks and its intent, revokes, and its propagation event's `record_action` returns recording-failure — the Event Log append answered nothing, its reply lost, and the `(step)` payload names step-3 — so no outcome lands and the call returns `rejected(recording-failure(outcome))`: the position telling the consent service the consent **is** Revoked and the action must not be re-run (a re-run would be refused already-revoked in any case), with the Revoked-but-unpropagated consent surfaced on the compliance dashboard meanwhile — a surfacing, not the record: the record is the compensating event, or `consent.propagation_escalated` should the window elapse. The orphan is the scan's: at its next run it re-reads the log for a `consent.revoked` event carrying the consent id and finds none (had the lost append landed after all, it would compensate nothing), and the compensating `consent.revoked` event, when it lands, is attested under the composition's service identity behind a `consent.recovery_intended` record, carries `cascade_recovery = true`, names the operator as `revoked_by`, and points at the original `consent.withdrawal_intended` event as its `intent_event_id`, so an auditor distinguishes the recovered withdrawal from a clean one and still reads who withdrew (Reconciliation 24 through 27). Had the cause been permanent, the scan would instead have written `consent.propagation_escalated` within `compensation_window`, naming the arm it observed, and Check 3.5 reads that record rather than a dashboard. The gate is already honest during the gap: processing_permitted reads Consent, so it returns `rejected(not-permitted(revoked))` from the moment the revoke committed.

### Rejection path — gate query for a subject who never consented

`processing_permitted("user-9999", "marketing:email")` where no consent record exists → `Consent.check → not-known` → `rejected(not-permitted(not-known))`. The processing system distinguishes *never consented* from *withdrawn* and requests consent rather than honoring a withdrawal that never happened.

---

### Regulated adversarial scenarios

**Regulator audit — "prove every consent-based processing activity was gated on valid consent, and that withdrawals propagated."** A data protection authority examines the Audit Trail and the processing records. For every downstream processing activity *the deployment discloses* (the composition's records enumerate the registered set; whether that set is outwardly complete is the deployment's registration obligation, verified against the deployment's own processing inventory — an externally-clearable question), the examiner confirms a `processing.registered` event bound it to a consent_id (Invariant 4); for the consent governing it, the examiner confirms a `consent.granted` event (Invariant 2) and that `AuditTrail.verify_record` returns verified for both. For every withdrawn consent, the examiner confirms exactly one `consent.revoked` event whose `affected_scopes` enumerates every `processing.registered` binding for that consent_id (Invariant 3) — a withdrawal whose `affected_scopes` omits a registered binding, or a revoked Consent record with no `consent.revoked` event at all, is a conformance failure. Every claim is provable; the gate is the single processing precondition (Invariant 1) and the propagation event is the single record of downstream impact.

**Disputed withdrawal — data subject claims processing continued after they withdrew consent.** A data subject complains that marketing continued after withdrawal. The investigator retrieves the `consent.revoked` event for the subject's consent: it carries `revoked_at`, reason, and the complete `affected_scopes` set naming `email-campaign-engine@campaigns` and `lookalike-audience-builder@adtech`. The investigator can therefore name *exactly which processors were on notice* and when. Consent Invariant 9 (revocation non-retroactivity) and the Audit Trail seal establish the withdrawal record was not altered or back-dated. If a named processor continued after `revoked_at`, that is that processor's compliance failure — this composition's records prove the withdrawal was recorded, propagated, and enumerated; whether each named processor *acted* on it is the processor's obligation, signalled but not performed by this composition. The propagation event is the rebuttal to "we were never told."

**Breach or incident forensics — which subjects had withdrawn consent during the compromise window, and was any withdrawal record altered.** An incident investigator is given a window and must reconstruct which consents were Granted versus Revoked during it and whether any withdrawal or its propagation set was tampered with. The investigator replays each consent's `consent.granted`, `processing.registered`, and `consent.revoked` events in Event Log insertion order (reached transitively through Audit Trail), determining each consent's state and downstream-binding set at the window's bounds, then runs `AuditTrail.verify_record` against representative events in each seal's coverage to bound any tampering window. Invariant 3 is load-bearing: a `consent.revoked` event whose `affected_scopes` was silently shrunk to hide a processor that should have stopped is foreclosed by the append-only, sealed log — the propagation set is part of the hashed event payload, so an alteration breaks the seal. The newest events in the Audit Trail's unsealed tail carry Event Log per-event immutability but become seal-verifiable only after the next seal cadence; until then a tail event returns `failed-verification(unsealed)`, so the integrity bound on the most recent withdrawals is the substrate's unsealed-tail policy (a tighter `seal_cadence` narrows it).

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when the checks below are provable to an external auditor given the three indexes and the Consent, Permissions, consent retention and Audit Trail substrate's records. Every enumeration of audit events below runs through the log read, never through a query the substrate routes to Reverse Index.

### Conformance checks

```
Check 1.1: An auditor MUST find [Processing Permitted] AND the consent check agreeing over a sample of subject references AND purposes (Invariant 1.1).
Check 1.2: An auditor MUST find no two governed consents in Granted carrying one subject reference AND one purpose (Invariant 1.3).
Check 2.1: An auditor MUST find a grant closure for EVERY governed consent whose escalation instant PRECEDES the audit (Invariant 2.1).
Check 2.2: An auditor MUST resolve EVERY Consent record carrying no grant event to EXACTLY ONE OF an aged record, an orphan under compensation, an escalated grant orphan, a write-ownership finding (Invariant 2.1).
Check 2.3: An auditor MUST find a passing verification for EVERY grant event (Invariant 2.2).
Check 3.1: An auditor MUST find no consent id two propagation events carry (Invariant 3.2).
Check 3.2: An auditor MUST find EVERY propagation event's propagation set equal to the registered set at the event's boundary (Invariant 3.3).
Check 3.3: An auditor MUST find a passing verification for EVERY propagation event (Invariant 3.1).
Check 3.4: An auditor MUST resolve EVERY revoked Consent record carrying no propagation event to EXACTLY ONE OF propagation history purged, an orphan under compensation, an escalated orphan, a write-ownership finding, a conformance failure (Invariant 3.5).
Check 3.5: IF an unpropagated record's escalation instant PRECEDES the audit THEN an auditor MUST find the record's propagation closure within the widened window (Invariant 3.5).
Check 3.6: An auditor MUST find EVERY compensating event attested under the recovery identity AND preceded by a recovery intent carrying the same intent reference (Invariant 3.6).
Check 3.7: An auditor MUST find EVERY escalation carrying a cause (Reconciliation 31).
Check 3.8: An auditor MUST find the compensation window exceeding the liveness sum (Capability requirement 10).
Check 4.1: An auditor MUST find a registration event preceding the event's boundary for EVERY pair a propagation set carries (Invariant 4.1).
Check 4.2: IF the record read answers Purged for a pair's registration event THEN an auditor MUST compare the event's surviving sequence number with the event's boundary (Invariant 4.1).
Check 5.1: An auditor MUST find a consent retention in Retained for EVERY governed consent carrying a grant event (Invariant 6.1).
Check 5.2: An auditor MUST find no consent retention in Purged (Invariant 6.1).
Check 6.1: An auditor MUST resolve EVERY outcome's intent reference to an intent that PRECEDES the outcome in the Event Log AND names the same operator (Invariant 8.1).
Check 6.2: An auditor MUST NOT join an outcome to an intent by any key weaker than the intent event id (Invariant 8.1).
Check 6.3: An auditor MUST NOT order an intent AND the intent's outcome by instant (Clock semantics 1).
Check 6.4: An auditor MUST NOT read an intent carrying no outcome as a conformance failure (Reconciliation 10).
Check 7.1: An auditor MUST find the audit horizon exceeding EVERY consent retention period (Capability requirement 4).
Check 7.2: An auditor MUST find no consent id resolved from the Consent records on a subject index miss (Composition state 11).
Check 7.3: An auditor MUST read a payload-dependent clause on an event the verification answers purged as unverifiable (Composition state 13).
Check 7.4: An auditor MUST read failed-verification carrying unsealed as pending the next seal (Invariant 2.2).
Check 8.1: An auditor MUST clear Consent's Generation acceptance over the Consent instance (Composes 5).
Check 8.2: An auditor MUST clear Permissions' Generation acceptance over the Permissions instance (Composes 5).
Check 8.3: An auditor MUST clear Retention Window's Generation acceptance over the consent retention instance (Composes 5).
Check 8.4: An auditor MUST clear Audit Trail's Generation acceptance over the Audit Trail instance (Composes 5).
```

NOTE: EVERY check names the rule the check tests.

Term passing verification: verified | failed-verification carrying purged | failed-verification carrying unsealed.

Term orphan under compensation: an orphan younger than its escalation instant.

Term escalated grant orphan: a Consent record an escalation of kind grant names.

Term escalated orphan: a revoked Consent record an escalation of kind propagation names.

Term propagation history purged: an aged revoked Consent record carrying no propagation event — its event lawfully destroyed.

Term write-ownership finding: a Consent record no intent pairs — a direct write against a reserved surface (Composes 11 and 12).

Term widened window: `compensation window + clock offset allowance` from the record's revocation instant to the compensating event's recording instant — two seams' stamps.

### External checks

```
External check 1: An auditor needing the registered set's completeness confirmed MUST read the deployment's processing inventory (Capability requirement 31).
External check 2: An auditor needing a named processor's cessation confirmed MUST read the processing system's own records (Non-goal 1).
External check 3: An auditor needing a consent's quality under Article 7 of the General Data Protection Regulation confirmed MUST read the deployment's consent capture (Non-goal 2).
External check 4: An auditor needing a scope grant's organizational authority confirmed MUST read the Permissions-administration layer (Invariant 7.1).
External check 5: An auditor needing a retention policy reference's proof period confirmed MUST read the deployment's policy registry AND the regime's floor (Capability requirement 5).
External check 6: An auditor needing a purpose's lawful basis confirmed MUST read the deployment's basis selection (Non-goal 3).
```

Term processing inventory: the deployment's records-of-processing-activities register under GDPR Article 30.

Term consent capture: the collection surface that produces a grant — the banner, the form, the verbal-capture integration.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT perform downstream cessation.
Non-goal 2: The composition MUST NOT capture consent.
Non-goal 3: The composition MUST NOT gate processing that rests on a lawful basis other than consent.
Non-goal 4: The composition MUST NOT govern a delivery preference.
Non-goal 5: The composition MUST NOT record a propagation event for an expiry.
Non-goal 6: The composition MUST NOT model the data subject's withdrawal surface.
Non-goal 7: The composition MUST NOT authenticate the data subject.
Non-goal 8: The composition MUST NOT record a denied attempt.
Non-goal 9: The composition MUST NOT destroy a consent record.
```

Term downstream cessation: deleting derived data, halting a pipeline or notifying a third party on a withdrawal.

Term delivery preference: a channel, frequency cap or quiet-hours setting that shapes processing already lawful.

Term withdrawal surface: the unsubscribe link, preferences toggle or other data-subject-facing surface a withdrawal starts from.

Term denied attempt: an administration action refused permission-denied.

NOTE: the owners — [Message Preference / Personalization](../atoms/message-preference.md) under [Preference-Aware Notification Fanout](./preference-aware-notification-fanout.md) (Non-goal 4); the deployment (Non-goal 5, Non-goal 6); a failed-attempt pattern (Non-goal 8); [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md) (Non-goal 9).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the Event Log sequence as the order of an intent AND the intent's outcome.
Clock semantics 2: The composition MUST NOT compare an intent's instant with an outcome's instant.
Clock semantics 3: A comparison of the composition's instant with another seam's instant MUST NOT decide a write alone.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion for [Processing Permitted] to take.
```

### Retention asymmetry

```
Retention asymmetry 1: The consent retention instance MUST NOT EQUAL the Retention Window instance inside Audit Trail.
Retention asymmetry 2: The composition MUST NOT call the purge on the consent retention instance.
```

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are its five actions — the four administration actions [Record Consent], [Register Processing], [Withdraw Consent] and [Read Consent History], and the read-only gate [Processing Permitted]; the [Affected Scopes] a propagation event enumerates and the [Processing Scope] each binding names; the four scopes it defines for its Permissions instance, [Consent Grant], [Consent Revoke], [Consent Register Processing] and [Consent Read]; and the gate's refusal, [Not Permitted]. The propagation guarantee is a structural property, not a datum. The deployment settings keep their wire spellings in configuration — `consent_record_retention_policy_ref`, `audit_trail_retention_policy`, `compensation_window`, `reconciliation_cadence`, `outcome_write_latency`, `administration_completion_bound`, `application_actor_ref`, `application_credential`, `clock_offset_allowance`, `field_length_cap`, `registrations_cap`, `intent_candidates_cap`, `event_id_width` — and the indexes their own in an implementation, `consent_to_downstream`, `consent_to_retention`, `consent_to_subject_purpose`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the reconciliation; a deployment; a regulated deployment; an auditor; a caller; a processing system; a processing activity; an invocation; an administration action; a validated grant; an admitted grant; a checked grant; a committed grant; a placed grant; a landed grant; a validated registration; a landed registration; a resolved withdrawal; a validated withdrawal; an admitted withdrawal; a committed withdrawal; a landed withdrawal; a validated history read; a fetched history read; a landed history read; a validated gate query; a derivation; a rebuild.

Term records: the grant intents, grant events, registration events, withdrawal intents, propagation events, access events, recovery intents and escalations the composition records through the audit write — each an Event Log event carrying one action reference below — the Consent records it writes through the grant and revoke writes, the consent retentions it places, and the three indexes' entries.

Term record verbs: EQUAL, add, alert, answer, append, attest, authenticate, call, capture, carry, change, classify, clear, commit, compare, compensate, compose, decide, derive, destroy, disclose, duplicate, expose, find, gate, govern, identify, inherit, inject, inspect, interpret, join, key, leave, model, name, normalize, open, order, pair, pass, perform, proceed, process, provision, re-derive, reach, read, rebuild, record, remove, report, resolve, retry, run, select, serve, set, stamp, start, store, substitute, supply, triage, write.

Term value sets: action reference = consent.grant_intended | consent.granted | processing.registered | consent.withdrawal_intended | consent.revoked | consent.history-read | consent.recovery_intended | consent.propagation_escalated. The rest are declared where the section that owns each declares it: withheld state, placement refusal, position, kind, cause.

Term bounds: administration completion bound (administration_completion_bound), outcome write latency (outcome_write_latency), field length cap (field_length_cap), registrations cap (registrations_cap), intent candidates cap (intent_candidates_cap), event id width (event_id_width), clock offset allowance (clock_offset_allowance), compensation window (compensation_window), audit horizon (audit_trail_retention_policy).

Term cadences: reconciliation cadence (reconciliation_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive atoms, consent retention instance, log read, record read, audit write, verification, grant write, revoke write, consent check, consent read, permission check, retention placement, consent namespace, consent id, downstream index, retention index, subject index, index entry, downstream entry, retention entry, subject entry, binding, pair, repeat registration, registration event id, live index entry, purged index entry, purged downstream entry, key entry, purged key entry, live downstream entry, live key entry, downstream rebuild, grant rebuild, consent validity flag, retention policy reference, consent retention period, audit retention policy, audit horizon, regulated deployment, compensation window, reconciliation cadence, outcome write latency, administration completion bound, liveness sum, field length cap, registrations cap, intent candidates cap, event id width, maximal envelope, clock offset allowance, recovery identity, processing system, processing activity, seam, now, payload string, caller string, subject reference, purpose, processor reference, reason, actor reference, credential, opaque reference, registered set, propagation envelope, intent, outcome, single write, later write, pre-append step, retention step, position, consent history, withheld state, expiry, metadata, administration action, action's scope, grant intent, grant event, registration event, withdrawal intent, propagation event, access event, intent event id, intent instant, registration instant, revocation instant, grantor, revoker, retention id, placement refusal, record count, propagation set, validated grant, admitted grant, checked grant, committed grant, placed grant, landed grant, resolved registration, validated registration, landed registration, resolved withdrawal, validated withdrawal, admitted withdrawal, committed withdrawal, landed withdrawal, validated history read, fetched history read, landed history read, validated gate query, invocation, owed outcome, index-anomaly finding, reconciliation, aged record, unpropagated record, ungranted record, orphan, unpaired record, withdrawal candidate count, grant skew, grant instant, pairing window, candidate count, intent candidates, earliest candidate's boundary, intent reference, recovery intent, compensating event, compensated grant, recovery flag, operator, kind, planned writes, escalation, cause, uncompensable cause, escalation instant, attempt count, binding repair, governed consent, query's instant, grant closure, event's boundary, surfacing bound, paired unpropagated record, propagation closure, lifecycle, consent retention, retention closure, passing verification, orphan under compensation, escalated grant orphan, escalated orphan, propagation history purged, write-ownership finding, widened window, processing inventory, consent capture, downstream cessation, delivery preference, withdrawal surface, denied attempt.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index classification. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. record_action, read_record, verify_record, payload cap, attestation id width, unsealed tail, step-2, step-3, step-4, invalid-credential, invalid-request, recording-failure, verified, failed-verification, unsealed, purged, compensation-window, Retained, Purged, Erasure Tombstone, Reverse Index: Audit Trail. grant, revoke, check, read, granted, revoked, expired, not-known, already-revoked, already-expired, invalid-request, storage-failure, invalid-query, Granted, Revoked, Expired: Consent. permitted, denied: Permissions. place_under_retention, purge, invalid-policy, policy-not-found, storage-failure, Retained, Purged, Purge Eligible, Policy Registry: Retention Window. read: Event Log. Processing Register: forthcoming.

Term composing patterns: [Customer Onboarding](./customer-onboarding.md); [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md); [Preference-Aware Notification Fanout](./preference-aware-notification-fanout.md); [Notification Fanout](./notification-fanout.md); [Message Preference / Personalization](../atoms/message-preference.md); [Defensible Retention](./defensible-retention.md); [Capability-Backed Sharing](./capability-backed-sharing.md); [Attributed Permissions Admin](./attributed-permissions-admin.md).

#### Record Consent

The composition action that records a data subject's consent for a purpose under an authorized operator's authority: it checks the operator's [Consent Grant] permission, records a `consent.grant_intended` event — the write that verifies the operator's credential, before anything commits — then refuses already-granted where the subject already holds a Granted record for the purpose (single-active-grant, Invariant 1.3), calls `Consent.grant`, places the consent record under its retention floor, and audits the grant (`consent.granted`, carrying the intent event's id). Returns the consent_id.

Kind: Operation

#### Register Processing

The composition action that binds a downstream processing activity ([Processing Scope]) to a consent, making *what relied on this consent* a recorded fact rather than tribal knowledge. It does not check consent state — that is [Processing Permitted]'s job at processing time. Audit-first: the binding enters `consent_to_downstream` only after its `processing.registered` event lands. Refuses registration-cap-exceeded past `registrations_cap` distinct bindings per consent.

Kind: Operation

#### Withdraw Consent

The composition's structural reason to exist: revoke a consent **and propagate the withdrawal** — recording, in a propagation event ordered after the `Consent.revoke`, the complete [Affected Scopes] set (every downstream scope registered against the consent) on one tamper-evident `consent.revoked` event. A `consent.withdrawal_intended` event precedes the revoke and is where the revoker's credential is verified, so a terminal transition is never performed on an unverified claim (Invariant 8.2). Revoke, then propagation event, ordered; bijective at quiescence modulo compensation (Invariant 3).

Kind: Operation

#### Read Consent History

The permission-gated read surface for compliance dashboards, DSAR workflows, and regulatory reporting. Because access to consent records is itself a regulated act, it records a `consent.history-read` meta-event and refuses to return the records if that meta-event fails to land.

Kind: Operation

#### Processing Permitted

The read-only consent-gates-processing query every processing system consumes before acting on personal data (rather than reading Consent directly). Returns permitted exactly when `Consent.check` reports valid consent, else [Not Permitted] naming the actual state. Produces no audit event — it changes no state.

Kind: Operation

#### Affected Scopes

The complete set of downstream processing bindings ([Processing Scope] plus processor) registered against a consent, derived from the `processing.registered` events at withdrawal time (the map supplying only the entries whose named event the substrate reports Purged), bounded by `registrations_cap`, and recorded on the `consent.revoked` propagation event. Its completeness is Invariant 3.3: the enumeration is exactly what was registered against the consent, never silently shrunk — whether every real processing activity registered is the deployment's obligation, so a withdrawal's downstream impact is provable.

Kind:       Field
Field of:   the consent.revoked propagation event
Role:       the propagation enumeration
Projection: affected_scopes

#### Processing Scope

The opaque reference to one downstream processing activity bound to a consent (e.g. `ad-personalization`, `partner-share:acme`). The unit [Register Processing] records and [Affected Scopes] enumerates; the composition never interprets it.

Kind:         Parameter
Parameter of: [Register Processing]
Role:         the downstream-activity reference
Projection:   processing_scope

#### Consent Grant

The scope permitting [Record Consent] — administer a new consent grant on a data subject's behalf.

Kind:       Member
Member of:  the consent-administration scope vocabulary
Role:       Scope
Projection: consent:grant

#### Consent Revoke

The scope permitting [Withdraw Consent] — record (operator-side) a withdrawal on a data subject's behalf. (The subject's own right to withdraw is absolute and honored upstream; this scope gates the operator recording it.)

Kind:       Member
Member of:  the consent-administration scope vocabulary
Role:       Scope
Projection: consent:revoke

#### Consent Register Processing

The scope permitting [Register Processing] — bind a downstream processing activity to a consent.

Kind:       Member
Member of:  the consent-administration scope vocabulary
Role:       Scope
Projection: consent:register-processing

#### Consent Read

The scope permitting [Read Consent History] — read a data subject's consent history.

Kind:       Member
Member of:  the consent-administration scope vocabulary
Role:       Scope
Projection: consent:read

#### Not Permitted

The [Processing Permitted] gate's rejection when no valid consent exists, parameterized by the actual `Consent.check` result — revoked (withdrawn), expired (time bound elapsed), or not-known (no record) — so the calling system can distinguish *never consented* from *withdrawn* from *lapsed* and choose the right remediation.

Kind:       Member
Member of:  the processing-gate rejection
Role:       Rejection
Projection: not-permitted

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Record Consent]: #record-consent
[Register Processing]: #register-processing
[Withdraw Consent]: #withdraw-consent
[Read Consent History]: #read-consent-history
[Processing Permitted]: #processing-permitted
[Affected Scopes]: #affected-scopes
[Processing Scope]: #processing-scope
[Consent Grant]: #consent-grant
[Consent Revoke]: #consent-revoke
[Consent Register Processing]: #consent-register-processing
[Consent Read]: #consent-read
[Not Permitted]: #not-permitted

---

## Standards references

- **GDPR Article 6(1)(a)** — consent as a lawful basis for processing. This composition's [Processing Permitted] gate is the structural form of the before-processing basis check; a permitted result makes it provable that a valid consent existed at processing time.
- **GDPR Article 7(1)** — the controller bears the burden of demonstrating consent. This composition's `consent.granted` events plus the retained Consent records (held under the consent-record Retention Window — Invariant 6) are the demonstrability surface; a withdrawn consent is retained as proof the basis once existed.
- **GDPR Article 7(3)** — withdrawal must be as easy as grant, and withdrawal does not affect the lawfulness of prior processing. [Withdraw Consent] is the recording surface; the data-subject-facing ease is upstream (Non-goal 6); non-retroactivity is inherited from Consent Invariant 9.
- **GDPR Article 17(1)(b)** — right to erasure when consent is withdrawn and no other basis applies. The `consent.revoked` event's `affected_scopes` is the notice that triggers downstream erasure obligations; this composition signals, the downstream processor erases (Non-goal 1).
- **GDPR Article 30** — records of processing activities must name purposes and legal bases. This composition's Consent records (purpose, `granted_at`) plus the `processing.registered` bindings supply the Article 30 documentation surface for consent-based processing.
- **CCPA / CPRA** (the California Consumer Privacy Act and its amending California Privacy Rights Act) — right to opt out of sale/sharing and opt in for sensitive personal information. This composition's [Record Consent] / [Withdraw Consent] are the opt-in/opt-out recording surfaces; the propagation event names the processors a do-not-sell signal must reach.
- **HIPAA section 164.508 (Authorization)** — required Authorization elements (purpose, expiration, right to revoke) map to the Consent record fields; this composition adds the operator-authority gate (Permissions) and the tamper-evident audit the regulated context requires.
- **ePrivacy Directive (Cookie Law)** — consent for non-essential cookies and tracking. A cookie-consent backend records grant/`revoke` through this composition; the `consent.revoked` propagation names the tracking systems that must stop.
- **ISO/IEC (International Organization for Standardization / International Electrotechnical Commission) 29184 (Online privacy notices and consent)** — consent record content and lifecycle. This composition's grant/registration/withdrawal records are the lifecycle artifacts the standard describes.

The four constituents carry their own deep standards inheritance — see each constituent's Standards references.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation, 2026-08-30: propagate-consent-revocation-downstream.tla + 1 twin verified 2026-08-27 over a single-writer invocation with no terminus; re-derive over the invocation and the scan as two processes over one act, the bound as the yield point (2026-08-29-a, 2026-08-30-k)
last gate: 2026-08-30 — third gate, fresh reader, under the frozen rules — 8 foundational corrected in-round, 7 refining and 2 rhetorical routed (7 refining and 4 rhetorical also corrected in-round, one of them at the closure check)

open:
- 2026-08-29-a · refining · formal · the model's compensation action carries no identity, no intent record, and no age bound; the twin predates the scan's two edges → extend the model with the service-identity compensation behind `consent.recovery_intended` and the bounded scan
- 2026-08-30-k · refining · formal · the model has no second leg; single-active-grant, the third scan leg and the escalation record are unmodelled → extend it with the invocation and the scan as two processes over one act (with 2026-08-29-a)
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/propagate-consent-revocation-downstream.md`; the migration that got it here is in [its history](./propagate-consent-revocation-downstream.hist.md).

- **2026-10-21 — The consent lifecycle reads as provable.** *Chose:* *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where the page wrote *from the records alone*, *records-alone* or their like: Invariant 5.1, under which every governed consent's lifecycle resolves provably from the Consent records, the Audit Trail instance and the indexes, with Invariant 5's heading, and, by wording alone, the Summary, the Wiring decision's principle, the invariants' closing paragraph, the DSAR and regulator examples, the acceptance bar, the [Affected Scopes] term entry and the Article 6(1)(a) standard; every *grant* on the page names a consent grant, a live authorization a withdrawal ends, so none changed; rules 233 to 233. *Over:* the phrase restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Invariant 5.1 changed and no obligation did.
- **2026-10-21 — The store's guarantees cited, not restated, and a withdrawal's revoke and its propagation event one transaction.** *Chose:* Capability requirement 32 citing Execution Contract Store 1 through 4 for the store the Consent, Permissions, consent retention and Audit Trail instances and the three indexes keep their records in; to Store 3, the indexes' persistence and the index durability held at the Consent store's (Composition state 15, Capability requirement 24, 25); to Store 2, under which an action's reads and the writes they decide are one transaction, the consent exclusion and the pair exclusion with their supply, holding, release and lease and the refusal to run without them, every take of them, an invocation's release of them and the expiry of its lease, the reconciliation's take of the consent exclusion and its skip of a held record, and the bar on [Processing Permitted] taking one (Capability requirement 16 through 22, Action wiring 6, 20, 27, 45 through 47, Reconciliation 7, 8, Concurrency 1 through 4); to Store 1, under which an action's writes commit together, its constituents' included, the rule denying that the revoke and the propagation event form one atomic set, which Store 1 as ruled contradicts (Wiring decision 2), and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the outcome retry attempts with the retry span the administration completion bound had to cover, the in-invocation retries of an outcome with their pre-check and adoption, the proceed-as-landed reading of a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing, the outcome position for a placement's storage failure, the consent exclusion a grant took only to keep the reconciliation off it, the reconciliation's run at every process start and its lower edge, and the placement re-run for a Granted record whose placement was refused, with the rule holding a compensating grant event behind it (Capability requirement 11, 12, Audit arm 5, 10, 11, Action wiring 15, 16, 43, 44, Reconciliation 1, 3, 18, 19). By clause, the consent check, the grant write, the derivation and the binding repair no longer name an exclusion (Action wiring 7, 9, 28, Reconciliation 22), and a recording-failure at an outcome's pre-append step lands as recording-failure carrying outcome with no retry ahead of it (Audit arm 12). Rules 268 to 233. *Over:* a revoke and a propagation event no transaction could span, ordered instead, with a consent exclusion and a pair exclusion the host held across an invocation's retries as a lease, and a reconciliation bounded below that compensated what a crash between the writes left — the turns of 2026-08-27 and 2026-08-30, below. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, that a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal, and that Store 2 covers a guard decided across a lease check, the lease keeping its job only for an act outside the store. The revoke and the propagation event are store writes, Consent and Audit Trail each supplying theirs under Store 1 through 4, and downstream cessation is Non-goal 1, so the composition makes no act outside the store: a withdrawal's intent, revoke and propagation event commit together, as a grant's intent, grant write, placement and grant event do, and the two exclusions, host mutual exclusions over store-only work, are Store 2's. A placement refused after the grant write leaves only the grant intent standing, the refused attempt's evidence, so no Granted record waits unretained for a re-run. An Audit Trail refusal of an outcome still leaves the Consent record committed and its event owed (Audit arm 12, 15, 17), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the pairing on both sides with its candidates, the re-derived set, the pre-check, the recovery identity behind a recovery intent, the recovery flag, the compensation window, the cadence, the outcome write latency and the liveness sum the window must exceed, and the escalation (Capability requirement 6 through 8, 10, 23, Reconciliation 9 through 17, 20, 21, 24 through 35, Invariant 3.5, 3.6, Check 3.5, 3.6, 3.8, 6.4); the administration completion bound stays with them, since the liveness sum, the grant pairing window and the surfacing bound still read it (Capability requirement 9). Audit Trail's evidence rule leaves an invalid-request at its retention step with the event appended, so that answer still proceeds as landed, with the alert (Audit arm 6, 16). The three indexes stay derived indexes outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps them, so an index entry still follows the event it derives from and a lost binding is still repaired (Action wiring 24, 25, 31, Reconciliation 20, 22, 23). The propagation set's boundary and the order of an intent and its outcome are the Event Log's own sequence numbers (Clock semantics 1), and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.
- **2026-08-30 — One Granted record per pair, one writer per act, the set derived from the events, the escalation a record, the pairing honest about whose clock stamped each side.** *Chose:* single-active-grant enforced at [Record Consent] step 4 by `Consent.check` under a per-`(subject_ref, purpose)` section, refusing already-granted, stated as Invariant 1(c) and tested by check 4, with the suppression claim made conditional on it; an in-invocation retry bounded by `outcome_retry_attempts` and a scan that takes the per-consent_id section for every consent it touches, so the invocation and the scan never both land a propagation event; `affected_scopes` derived at [Withdraw Consent] step 4 from the `processing.registered` events (the map supplying only its past-horizon entries) with a third scan leg repairing lost bindings; the grant-side scan pairing by actor, subject and purpose inside a symmetric window under a declared `clock_offset_allowance`, narrowing to candidates and escalating a zero-match as an unresolved grant orphan rather than concluding a bypass; check 6's case (v) requiring a *paired* intent, exact by pass-through, so a zero-match on the withdrawal side is the bypass signature; `consent.propagation_escalated` as composition-written audit content under the service identity, carrying the observed cause, in place of "an open compliance finding"; `registrations_cap`, `field_length_cap` and `intent_candidates_cap` with an envelope inequality checked at instance start, the digest withdrawn; the liveness inequality written out with `outcome_write_latency`; `recording-failure(intent | outcome)` on the two signatures that straddle a commit; "atomically" and "together or not at all" replaced at every site by revoke-then-event, ordered, bijective at quiescence modulo compensation; the log read declared once as the substrate's sequence-range read filtered composition-side; the purged answer counted as consistent ahead of any composition-side comparison; and `consent_to_downstream`'s past-horizon half re-homed from Erasure Tombstone to a Processing Register atom *(forthcoming)*, the two key-shaped maps staying with the tombstone; at the closure check, each map element carrying its registration `event_id` so that *past the horizon* is decided by `read_record` answering Purged and never by a timestamp, with check 3 carved out for a purged registration whose surviving `sequence_number` still precedes the boundary; checks 1 and 7 reading `kind: grant` escalations as escalated orphans, never as bypasses; `event_id_width` declared rather than attributed to the substrate; `per_key_serialization` declared as the instance capability the sections rest on, with lease semantics — a lease exactly `administration_completion_bound` long whose expiry is the invocation's terminus, the invocation re-taking the section before any pre-check and writing nothing after it has yielded — and `outcome_retry_attempts × outcome_write_latency ≤ administration_completion_bound` so the counted terminus fits the bound; and the scan's tie-break withdrawn for candidates never chosen. *Over:* a gate keyed per pair over a propagation keyed per consent_id with nothing holding the two to one record; "retry until it lands" beside a scan starting at the bound; a map read as gate input with "rebuild where its integrity is in doubt"; a bypass verdict landed on a comparison of two seams' stamps; an intent's existence standing in for its pairing; an escape branch living in no store; a digest no consumer can read; a bare token on both sides of the commit; atomicity language over two irreversible writes; a tombstone asked to carry a register; a past-horizon membership with no clock-free test; an escalation with no reader; a critical section attributed to the host and named nowhere, and a lost lease that could resume between a scan's look and its append. *Because:* Consent evaluates the latest grant and declines uniqueness for itself, so a composition that keys its two halves differently must supply it or contradict its own suppression claim; two compensators over one act land two outcomes the seal then protects; a short list is not an observable miss; a stamp another seam wrote can differ from this one's by a sign the bound does not have; a check that cannot see the escalation cannot count it; a set that only grows has no unreachable cap; a caller who cannot tell intent from outcome re-runs a committed act; a retention state is the substrate's to answer and a timestamp is not that answer; and a section nobody declared, with a lease nobody bounded, is a second writer waiting for a stall (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen with its tells for uses — with §*A derived index is trustworthy only where a miss is observable*, §*Intents pair with outcomes*, §*Recovery commits under a declared service identity* and §*A derived index splits at the horizon*).
- **2026-08-29 — The scan is bounded at both edges, writes as the composition, and pairs by the records; the indexes are truth-bearing past the horizon.** *Chose:* a declared `administration_completion_bound` below which the reconciliation scan and checks 1 and 7 examine nothing, with the audit horizon as their upper edge; every compensating write attested under a declared service identity behind a `consent.recovery_intended` record, the operator carried in `data`, the intent paired on `intended_at = revoked_at` and `actor_ref = revoked_by` (candidates named where undecidable); both grant-side orphan shapes resolved, the unretained one by re-running the placement from the intent's own retention_policy_ref; every `record_action` transcription carrying `(step)`, the `step-4` arm proceeding as landed and invalid-request never unreachable; and each index's past-horizon half classified truth-bearing under a declared `index_durability`, extraction-pending against Erasure Tombstone. *Over:* an unbounded scan attesting compensations as the absent operator, and "the map is not rebuildable" as the last word on the horizon. *Because:* an unbounded scan compensates in-flight withdrawals beside their own propagation events and reads lawfully purged history as orphans; a compensation the operator did not make cannot be attested as theirs; and a consent record outlives any audit horizon by Consent's own Invariant 8, so the only thing that keeps an old consent withdrawable is the index entry, which must therefore be declared for what it is (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*, *A transcribed rejection arm keeps its payload*, *A derived index splits at the horizon*).
- **2026-08-27 — Authentication happens at this composition's boundary, before the consent state changes.** *Chose:* [Record Consent] and [Withdraw Consent] open with an intent record whose substrate attestation verifies the credential; invalid-credential is a clean pre-state refusal. *Over:* the Action wiring preamble's declaration that the check "cannot be pre-empted at this composition's boundary" and belongs to a deployment pre-check. *Because:* the declaration was false — the composition reaches the same Actor Identity surface at whatever point it chooses to write — and a declared deployment obligation is the answer the methodology refuses.
- **2026-08-27 — Invariant 3 is safety plus liveness, with the propagation-set boundary on the intent event.** *Chose:* the revoke precedes the propagation event; the reachable partial (Revoked, unpropagated) is an accountability gap surfaced and compensated within `compensation_window`; check 2's set boundary is the withdrawal's own `consent.withdrawal_intended` event. *Over:* "commit together or not at all" under a host transaction. *Because:* Consent's revocation is immutable once committed and the substrate's append cannot be withdrawn, so neither member was ever enlistable; what makes the pair sound is the order.
- **2026-08-27 — A consent record is never destroyed by this composition; its retention is Retained for life.** *Chose:* the consent-record Retention Window instance marks the proof-period floor and never reaches `Purged`; check 5 requires `Retained` unconditionally. *Over:* admitting a lawful purge here, or scoping Consent's Invariant 8 to the atom's own surface. *Because:* a composition may not weaken a constituent invariant by paraphrase, and Retention Window defines `Purged` as the destruction Consent forbids.

NOTE: End of Propagate Consent Revocation Downstream.
