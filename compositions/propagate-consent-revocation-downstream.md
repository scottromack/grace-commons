---
title: Propagate Consent Revocation Downstream
id: 2
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

The composition's defining emergent guarantee (a property that appears only when atoms are combined — no single atom carries it) has two halves. *Consent-gates-processing:* a single read-only query, `processing_permitted(subject_ref, purpose)`, returns permitted if and only if Consent reports valid consent (`check` → granted) for that subject and purpose at the current time. Processing systems consume this query rather than calling Consent's check directly (Invariant 1.2), so the gate is implemented exactly once instead of re-implemented — or skipped — per processing system. *Revocation propagates:* [Withdraw Consent] records an intent, revokes the consent and then records a `consent.withdrawal.revoked` Audit Trail event whose `affected_scopes` set is exactly the downstream processing scopes registered against that consent before the withdrawal was intended, under Recoverable Invocation's protocol (an intent before the revoke, the outcome after it). The event is ordered after the revoke, which gives the guarantee an auditor needs, since a propagation record always has a real revocation behind it. Where the revoke commits and the event cannot be recorded, or its call never answers, the revocation stands without it — the one gap left, which Recoverable Invocation's sweep closes within its closure window, recovering the event or escalating, and which is never a processing-suppression gap, because the gate reads the consent records directly and is honest the instant the revoke commits — given the single-active-grant rule [Record Consent] enforces (Invariant 1.3), which is what makes the record revoked the record the gate evaluates for its subject and purpose.

Beyond the gate and the propagation, the composition guarantees that every consent grant is attributed and tamper-evidently recorded, that consent records are held under a retention floor that survives revocation (a withdrawn consent is evidence, not garbage — it must outlive its own withdrawal for the regulator's proof period), that the complete consent lifecycle is provable, and that every consent-administration action passes a Permissions check before it touches the consent records.

 Its most common uses are advertising and marketing consent management under GDPR (the EU General Data Protection Regulation)/ePrivacy (the EU's Directive 2002/58/EC on privacy and electronic communications), health-app and research consent under HIPAA (the US Health Insurance Portability and Accountability Act) Authorization, cookie-consent backends under the ePrivacy Directive, and any system that must make it provable that consent-based processing was gated on valid consent and that every withdrawal's downstream impact was enumerated and sealed.

---

## Intent

Every system that processes personal data on the basis of consent faces the same regulated obligation, and it is the same whether the system is an advertising platform, a health app, an analytics pipeline, or a cookie-banner backend. Before processing for a consent-based purpose, the system must confirm a valid consent exists; the data subject must be able to withdraw that consent as easily as they gave it; and — the limb that defeats most real deployments — when consent is withdrawn, the systems that were relying on it must *stop*, which means the withdrawal cannot be a private fact buried in the consent records but must propagate to every downstream process that was acting on the basis now gone. GDPR Article 6(1)(a) names consent as a lawful basis; Article 7 fixes its conditions (freely given, specific, informed, demonstrable); Article 7(3) requires withdrawal be as easy as grant and, read with Article 17(1)(b), that withdrawal end the basis for future processing. The domain varies; the structural obligation is constant: gate processing on consent, and make withdrawal propagate provably.

No constituent, alone, enforces this arc. Consent owns the grant/revoke/expire lifecycle and the `check` query that answers *is there valid consent for this subject and purpose at this time?* — but it deliberately stops there: its own specification states *"the atom does not enforce processing suppression"* and names downstream propagation as out of scope, for a composing layer to handle — this one. Consent records that consent was withdrawn; it neither knows what downstream processing relied on it nor records which processes must now cease. Permissions owns inward authorization — *which internal actor may grant, revoke, or read a consent record on a data subject's behalf* — but it knows nothing of consent state. The Audit Trail substrate records attributed, tamper-evident, retention-bounded events but does not know which events constitute a consent's propagation history. The consent-record Retention Window instance holds each consent record for its proof period but knows nothing of consent semantics. The structure that makes the four coherent as a single consent-management surface — the gate that centralizes the consent precondition, the downstream-registration index that makes "what relied on this consent" a recorded fact, and the propagation event that follows revocation in a fixed order — belongs to no single constituent. It belongs to the composition, and this composition is that structure.

This is a composition, not a new primitive. Consent, Permissions, Audit Trail, Retention Window and Recoverable Invocation are unchanged; the composition is the wiring that makes them coherent as a single consent-management surface. It introduces emergent actions — [Record Consent], [Register Processing], [Withdraw Consent], [Read Consent History], [Processing Permitted] — that belong to no single constituent and exist only because the constituents are wired together. The [Withdraw Consent] action, in particular, wraps a Consent `revoke`, an enumeration of the consent's registered downstream scopes, and the tamper-evident propagation event into one named surface, ordered revoke-then-event under Recoverable Invocation's protocol, so that withdrawing consent is one auditable act whose downstream impact is recorded — not a Consent `revoke` whose consequences leak silently into whatever processing systems happen to re-check, or fail to re-check, the consent records.

What the composition is *not*: it is not the consent-collection UI (user interface — the banner, the form, the verbal-capture integration that produces the grant signal — that is upstream, producing the inputs [Record Consent] records); it is not the data-erasure engine (whether withdrawal triggers deletion of derived data under Article 17 is the downstream processor's obligation, signalled by the propagation event, not performed by this composition); it is not a lawful-basis adjudicator for non-consent bases (legitimate interest, contract necessity, legal obligation are GDPR Article 6 bases this composition does not model — a Customer Due Diligence obligation under Customer Onboarding rests on Article 6(1)(c), not consent, and is explicitly out of scope here); and it is not the access-control surface for internal operators beyond the consent-administration actions it gates. Each is named explicitly in Non-goals.

---

## Composes

- **[Consent](../atoms/consent.md)** — the data subject's grant, revoke and expire lifecycle, with the point-in-time check the gate delegates to.
- **[Permissions](../atoms/permissions.md)** — the inward authorization surface: which internal actor may administer a consent record.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate: every state-changing act of the composition is an attributed, sealed, retention-governed Audit Trail event.
- **[Retention Window](../atoms/retention-window.md)** — the consent retention instance: one placement over each consent record, marking how long the controller must be able to produce it.
- **[Recoverable Invocation](./recoverable-invocation.md)** — the protocol [Record Consent] and [Withdraw Consent] follow around the Consent write: an intent before it, an outcome after it, and a sweep that closes the record of a write whose outcome never landed; this page restates none of it.

```
Composes 1: EXACTLY ONE Consent instance MUST serve the composition.
Composes 2: EXACTLY ONE Permissions instance MUST serve the composition.
Composes 3: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 4: EXACTLY ONE Retention Window instance MUST serve the composition.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST NOT change a constituent's spec.
Composes 7: The composition MUST reach a transitive atom ONLY through the constituent that composes the atom.
Composes 8: The composition MUST NOT compose an instance of a transitive atom.
Composes 9: The composition MUST select audit events through the log read.
Composes 10: The composition MUST read an event by id ONLY through the record read.
Composes 11: A deployment MUST NOT call the grant write outside the composition.
Composes 12: A deployment MUST NOT call the revoke write outside the composition.
Composes 13: A deployment MUST NOT call the consent read outside the composition.
Composes 14: A deployment MUST NOT record an event under the consent namespace or under Recoverable Invocation's vocabulary for the consent kinds outside the composition.
Composes 15: EXACTLY ONE Recoverable Invocation instance MUST serve the composition.
Composes 16: The Recoverable Invocation instance MUST write to the composition's Audit Trail instance.
Composes 17: The composition MUST bind the act kinds PER the consent bindings.
Composes 18: The composition MUST NOT bind [Register Processing], [Read Consent History] or [Processing Permitted] as an act kind.
Composes 19: The composition MUST NOT hold an instance of Lease, which Recoverable Invocation reaches.
```

Term composition: this pattern's wiring of [Consent](../atoms/consent.md), [Permissions](../atoms/permissions.md), [Audit Trail](./audit-trail.md), a [Retention Window](../atoms/retention-window.md) instance and [Recoverable Invocation](./recoverable-invocation.md) — the gate, the registration surface, the withdrawal with its propagation, the history read, the three indexes, the consent bindings and the write-ownership leg.

Term constituents: [Consent](../atoms/consent.md), [Permissions](../atoms/permissions.md), [Audit Trail](./audit-trail.md), [Retention Window](../atoms/retention-window.md), [Recoverable Invocation](./recoverable-invocation.md).

Term transitive atoms: [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md), [Tamper Evidence](../atoms/tamper-evidence.md) and the audit-event [Retention Window](../atoms/retention-window.md), reached through Audit Trail, and [Lease](../atoms/lease.md), reached through Recoverable Invocation.

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

Term consent namespace: the action references consent.grant.intended, consent.grant.granted, consent.grant.refused, processing.registered, consent.withdrawal.intended, consent.withdrawal.revoked, consent.withdrawal.refused and consent.history-read on the composition's Audit Trail instance, with the references Recoverable Invocation derives from the two kinds (recovery_intended, abandoned, escalated) under each.

Term act kind: consent.grant or consent.withdrawal — the two act kinds this composition binds on its Recoverable Invocation instance, one per act the composition's Consent write stands for.

Term consent bindings: each act kind's bindings, under the name Recoverable Invocation gives each. For consent.withdrawal: act key — the consent id; commit — the revoke write; pairing datum — the revocation instant, passed into the revoke write; repeatable — yes; act probe — the withdrawal probe; journal events — consent.withdrawal.intended, the one outcome consent.withdrawal.revoked, consent.withdrawal.refused. For consent.grant: act key — the subject reference with the purpose; commit — the grant transaction; pairing datum — the grant instant, the host injecting the invocation's now into Consent's seam (Capability requirement 37); repeatable — yes; act probe — the grant probe; journal events — consent.grant.intended, the one outcome consent.grant.granted, consent.grant.refused. For both: invocation completion bound — the administration completion bound; commit round trip and probe round trip — the deployment's disclosed bounds; journal — the composition's Audit Trail instance; retention period — the audit horizon; settling period — the deployment's settling period; service identity — the recovery identity; outcome envelope — sized from the registrations cap, the field length cap and the event id width (Capability requirement 14).

Term withdrawal key: the consent id, known before the invocation's open, which the subject index resolves (Primitive policy 5). One consent has one terminal withdrawal: a second withdrawal is refused already-revoked by Consent itself, a pre-commit arm.

Term grant key: the subject reference with the purpose. The consent id is minted by the grant write, so it is not known at the open — the minted-key deviation Recoverable Invocation's Deviation 1 names, declared here as Immutable Ledger declares it. Two grants of one key are two acts, repeatable being yes: a second grant of a pair that holds a Granted record is refused already-granted inside the commit.

Term grant transaction: the consent check, Consent's grant write and the retention placement, called in that order and committed together or not at all (Execution Contract Database 1) — the one commit Recoverable Invocation's bound commit stands for for the grant kind (Composition notes, *Recoverable Invocation's commit is one call*).

Term commit partition: for the withdrawal, committed where the revoke write answers revoked; pre-commit where it answers already-revoked, already-expired, invalid-request, not-known or storage-failure, or the database answers state-unavailable (Execution Contract Constituent failure 3) — a refused write leaving the Consent record Granted (Consent Operation 31, 32); unknown where the write answers a code the constituent does not declare, or where its reply has not arrived when the commit round trip has elapsed since the call's issue. For the grant, committed where the grant transaction commits and answers the consent id and the retention id; pre-commit where the consent check answers granted, or the grant write or the retention placement refuses (invalid-request, storage-failure, invalid-policy, policy-not-found, registry-unavailable), or the database answers state-unavailable (Execution Contract Constituent failure 3), the transaction then rolling back every write it made; unknown as for the withdrawal (Recoverable Invocation commit 6, commit 7).

Term withdrawal probe: the read that answers whether an open withdrawal intent's revoke committed. Consent's read by the consent id with the revocation instant range of the intent's pairing datum answers committed where the record is Revoked at that instant by the intent's revoking actor reference, carrying the consent id, the subject reference, the purpose, the reason, the revocation instant and the propagation set the composition derives at the intent's own position (Recoverable Invocation act probe 6); not-committed where the record is Granted, Expired, or Revoked at another instant or by another actor; unavailable where the read is refused or gives no answer, a rejected query surfaced on the compliance surface (Recoverable Invocation act probe 4).

Term grant probe: the read that answers whether an open grant intent's grant committed. Consent's read by the subject reference, the purpose, the grantor and the grant instant range of the intent's pairing datum answers committed where exactly one record matches, carrying the consent id and, from Retention Window's read filtered in the composition's code by the consent id, the retention id; not-committed where none matches; undecidable carrying the matching records where more than one does; unavailable as for the withdrawal probe (Recoverable Invocation act probe 2, 3, 4).

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
Composition state 11: The composition MUST NOT rebuild an index entry from Consent's records.
Composition state 12: A rebuild MUST read the enumeration of Consent's records ONLY as a cross-check.
Composition state 13: The composition MUST classify a purged index entry as truth-bearing.
Composition state 14: A rebuild MUST NOT remove a purged index entry.
Composition state 16: The composition MUST classify a purged downstream entry as extraction-pending against Processing Register.
Composition state 17: The composition MUST classify a purged key entry as extraction-pending against Erasure Tombstone.
Composition state 18: The composition MUST decide a downstream entry's horizon by the record read on the entry's registration event.
Composition state 19: The composition MUST NOT decide a downstream entry's horizon by an instant.
Composition state 20: The composition MUST NOT store a consent validity flag.
Composition state 21: The composition MUST NOT duplicate a constituent's records.
Composition state 23: The composition MUST NOT store a record of the Recoverable Invocation instance.
```

NOTE: open 2026-11-04-b — Composition state 12 makes the enumeration of Consent's records a cross-check, and no rule says what the composition does where it and the log disagree.

NOTE: open 2026-11-11-c — a repeat registration changes no binding (Composition state 5), so a pair whose first registration event the audit horizon destroyed stays purged though a later registration of it stands Retained, and no rule says whether it re-binds.

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

Term grant rebuild: the log read kept to the grant events — a grant event the invocation wrote, one Recoverable Invocation's sweep recovered or an operator wrote through the invocation resolve — each recorded as its payload's retention id and its subject reference and purpose against its consent id.

Term consent validity flag: a stored granted, expired or still-consented value.

### Capability requirement

```
Capability requirement 1: The composition MUST NOT substitute a retention policy reference for the caller's.
Capability requirement 2: A deployment MUST set the audit retention policy on the Audit Trail instance.
Capability requirement 3: The composition MUST NOT pass a retention input to the audit write.
Capability requirement 4: EVERY consent retention period MUST NOT EXCEED the audit horizon.
Capability requirement 5: A regulated deployment MUST pass a retention policy reference encoding the regime's proof period.
Capability requirement 9: A deployment MUST set the administration completion bound.
Capability requirement 13: A deployment MUST set the field length cap, the registrations cap, the event id width AND the id width.
Capability requirement 14: The composition MUST start ONLY IF the maximal envelope DOES NOT EXCEED Audit Trail's payload cap.
Capability requirement 23: A deployment MUST provision the recovery identity.
Capability requirement 26: The wired Audit Trail instance MUST expose the log read.
Capability requirement 27: The host MUST inject now, the invocation id, the run id AND the operator run id at the seam once per invocation.
Capability requirement 28: The composition MUST stamp EVERY instant one invocation writes from the invocation's now.
Capability requirement 30: A deployment MUST expose [Processing Permitted] ONLY to processing systems.
Capability requirement 31: A processing activity MUST NOT process on a consent basis BEFORE a registration event carrying the activity's processing scope AND the consent id of the governed consent in Granted, at the instant the activity processes, for the subject reference AND purpose the activity processes under lands.
Capability requirement 32: The deployment MUST supply the database PER Execution Contract Database 1 through 4, AND the act section PER Execution Contract Database 7 AND Refusal 1 (Recoverable Invocation Capability requirement 12).
Capability requirement 35: A deployment MUST run the composition and the Consent instance against a single clock (Execution Contract Logic confinement 7, Consent Operation 24, 25).
Capability requirement 36: IF a required setting EQUALS blank THEN the composition MUST refuse to start.
NOTE: watch the unset setting (Capability requirement 36).
Capability requirement 37: The host MUST inject the invocation's now into Consent's seam for the grant write, so that the grant instant EQUALS the grant intent's pairing datum.
Capability requirement 38: The host MUST NOT inject an equal now into two invocations of one act key on any node of the instance.
Capability requirement 39: A deployment MUST supply the act section Recoverable Invocation takes (Recoverable Invocation Capability requirement 11).
Capability requirement 40: A deployment MUST disclose the commit round trip, the probe round trip AND the settling period.
Capability requirement 41: A deployment MUST set the instance's bounds PER Recoverable Invocation Instance start 4 through 8.
Capability requirement 42: A deployment MUST NOT remove a Consent record or a consent retention BEFORE the audit horizon has run past the record's outcome (Recoverable Invocation Binding 9).
```

NOTE: open 2026-11-04-a — no rule refuses a consent retention whose period exceeds the audit horizon at the placement (Capability requirement 4), and Check 7.1 finds the breach after the record stands.

Term retention policy reference: the consent-record policy a caller passes to [Record Consent] — retention_policy_ref, required, resolved in Retention Window's Policy Registry; the deployment's recommended value is configured as `consent_record_retention_policy_ref`.

Term consent retention period: the duration a retention policy reference assigns a consent record.

Term audit retention policy: the retention policy configured on the composition's single Audit Trail instance, governing every audit event it records — `audit_trail_retention_policy`.

Term audit horizon: the audit retention policy's horizon.

Term regulated deployment: a deployment under a regime fixing a proof period — GDPR (the EU General Data Protection Regulation) Article 7(1)'s demonstrability burden, or HIPAA (the US Health Insurance Portability and Accountability Act)'s six-year Authorization retention.



Term administration completion bound: the deployment's declared maximum for a [Record Consent] or [Withdraw Consent] invocation — the act kind's invocation completion bound: the longest it takes from the invocation open's take of the critical section to the invocation close's last write (the invocation yield's return where the commit answers an unknown arm), the constituent round trip included.

Term reconciliation run bound: Recoverable Invocation's run bound on this composition's instance, inside which the write-ownership leg runs.




Term field length cap: the byte length no payload string may exceed.

Term registrations cap: the most distinct pairs one consent may hold.


Term event id width: the widest event id, in bytes, the wired Audit Trail instance mints, which the substrate does not itself disclose.

Term id width: the widest consent id or retention id, in bytes, the host allocates at the seam of Consent or of Retention Window (Consent Identity 2, Retention Window Identity 2), whichever is wider.

Term maximal envelope: the largest outcome the composition could write — the registrations cap's pairs at the field length cap, every reference and the reason at the field length cap, the intent event id at the event id width, the consent id and the retention id at the id width, and the fixed fields — serialized as the substrate sizes it.

NOTE: open 2026-11-09-b — the maximal envelope names the fixed fields and enumerates none of them.


Term required setting: the administration completion bound, the field length cap, the registrations cap, the event id width, the id width, the commit round trip, the probe round trip, the settling period or the recovery identity.

Term recovery identity: the composition's registered actor reference and credential — `application_actor_ref` and `application_credential` — the service identity under which Recoverable Invocation's sweep attests every write it makes for the two act kinds.

Term clock offset allowance: Recoverable Invocation's clock allowance on this composition's instance.

Term invocation id: the fresh id the host injects at the seam per [Record Consent] or [Withdraw Consent], carried by every record the invocation writes (Recoverable Invocation Term invocation id).

Term commit round trip: the deployment's disclosed bound on one commit, from issue to reply — the revoke write for the withdrawal kind, the grant transaction for the grant kind.

Term probe round trip: the deployment's disclosed bound on one act probe, from issue to answer.

Term settling period: the time the deployment declares for an operator to settle an escalated act through the invocation resolve (Recoverable Invocation Term settling period).

Term processing system: a system that processes personal data on a consent basis.

Term processing activity: one downstream processing a processing system runs under a [Processing Scope].

Term seam: the composition's input and output boundary — the one place the host reads the clock, as Execution Contract Logic confinement 14 declares it.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

### Primitive policy

```
Primitive policy 1: IF a payload string EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 2: IF a payload string's length EXCEEDS the field length cap THEN the action MUST answer invalid-request.
Primitive policy 3: IF the actor reference EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 4: IF the credential EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 5: IF the subject index misses the consent id once rebuilt THEN the action MUST answer not-known.
Primitive policy 6: IF the pair IS NOT IN the registered set AND the registered set's count EQUALS the registrations cap THEN [Register Processing] MUST answer registration-cap-exceeded.
Primitive policy 8: An action refused under Primitive policy 1 through 6 MUST NOT write.
Primitive policy 9: The composition MUST NOT record an audit event for a call BEFORE Primitive policy 1 through 6 pass.
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

Term registered set: the pairs of every registration event carrying the consent id, together with the purged downstream entries for the consent id; at a boundary, those whose registration event PRECEDES the boundary in the Event Log.


### Audit arm

```
Audit arm 6: The deployment MUST alert on EVERY single write landed with the retention step failed.
Audit arm 7: IF Audit Trail answers invalid-credential at a single write THEN the action MUST answer invalid-credential.
Audit arm 8: IF Audit Trail answers invalid-request carrying step-1, step-2 or step-3 at a single write THEN the action MUST answer invalid-request.
Audit arm 9: The deployment MUST alert on EVERY invalid-request carrying step-1, step-2 or step-3 at a single write as a deployment fault.
Audit arm 13: IF Audit Trail answers recording-failure at a single write THEN the action MUST answer recording-failure.
Audit arm 16: IF Audit Trail answers invalid-request carrying the retention step at a single write THEN the invocation MUST proceed as landed.
Audit arm 18: [Record Consent] AND [Withdraw Consent] MUST answer PER Recoverable Invocation's Action wiring table, AND the Audit arm's rules MUST NOT answer for either, whose intent, outcome and refusal records Recoverable Invocation writes.
```


Term intent: a grant intent or a withdrawal intent — the record Recoverable Invocation's open writes before the Consent write, the one that verifies the caller's credential (Recoverable Invocation Primitive policy 19).

Term outcome: a grant event or a propagation event — the record Recoverable Invocation's close writes after the Consent write, or its sweep writes for it.

Term single write: a registration event or an access event — the one audit write of an action that commits nothing before it.

Term subsequent write: a single write.

Term retention step: the step naming the substrate's retention placement on an invalid-request — step-4; the event is appended and attested.

Term position: intent | outcome — Recoverable Invocation's (Recoverable Invocation Primitive policy 19 through 31): where a recording-failure of a bound action sat; a single write has none.


### Action wiring

```
record_consent(actor_ref, subject_ref, purpose, credential, retention_policy_ref, optional expires_at, optional metadata)
  answers consent id | recording-failure(outcome)
  refuses permission-denied | invalid-credential | invalid-request | registry-unavailable | already-granted | storage-failure | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | already-accounted | recording-failure(intent) | recording-failure(refusal, constituent_code)

register_processing(actor_ref, consent_id, processing_scope, processor_ref, credential)
  answers registered
  refuses permission-denied | not-known | registration-cap-exceeded | invalid-credential | invalid-request | recording-failure

withdraw_consent(actor_ref, consent_id, credential, reason)
  answers withdrawn | recording-failure(outcome)
  refuses permission-denied | not-known | invalid-credential | invalid-request | already-revoked | already-expired | storage-failure | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | already-accounted | recording-failure(intent) | recording-failure(refusal, constituent_code)

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

Term metadata: the optional opaque metadata a caller passes to Consent's grant unchanged — a consent-form version, for one. No field length cap reaches it: the invocation open sizes it with the rest of the grant intent's data against the payload cap and lands invalid-request, nothing written, for an intent that would not fit (Recoverable Invocation Primitive policy 12, Primitive policy 13, Action wiring 61).

```
Action wiring 1: EVERY administration action MUST call the permission check with the actor reference AND the action's scope.
Action wiring 2: IF the permission check answers denied THEN the administration action MUST answer permission-denied.
Action wiring 3: An administration action MUST NOT write BEFORE the permission check answers permitted.
Action wiring 4: A validated grant MUST call the invocation open with the act kind consent.grant, the subject reference with the purpose as the act key, the actor reference, the credential AND the intent data carrying the subject reference, the purpose, the retention policy reference, the expiry, the metadata AND now as the pairing datum (Recoverable Invocation Action wiring 4).
Action wiring 5: A grant intent MUST NOT carry a consent id.
Action wiring 7: An admitted grant MUST call the consent check with the subject reference AND the purpose, inside the grant transaction.
Action wiring 8: IF the consent check answers granted THEN the grant transaction MUST commit no write AND [Record Consent] MUST close the pre-commit arm through the invocation refuse AND answer already-granted (Recoverable Invocation commit 2, commit 3).
Action wiring 9: A checked grant MUST call the grant write with the subject reference, the purpose, the actor reference as the grantor, the expiry AND the metadata.
Action wiring 11: IF the grant write answers storage-failure THEN the grant transaction MUST commit no write AND [Record Consent] MUST close the pre-commit arm through the invocation refuse AND answer storage-failure.
Action wiring 12: IF the grant write answers invalid-request THEN the grant transaction MUST commit no write AND [Record Consent] MUST close the pre-commit arm through the invocation refuse AND answer invalid-request.
Action wiring 13: A committed grant MUST call the retention placement with the consent id AND the retention policy reference.
Action wiring 14: IF the retention placement answers a placement refusal THEN the grant transaction MUST commit no write AND [Record Consent] MUST close the pre-commit arm through the invocation refuse AND answer invalid-request.
Action wiring 17: [Record Consent] MUST close a committed grant transaction through the invocation close naming consent.grant.granted AND carrying the consent id, the subject reference, the purpose, the expiry AND the retention id (Recoverable Invocation commit 4).
Action wiring 18: A closed grant MUST write the retention entry AND the subject entry.
Action wiring 19: A closed grant MUST answer the consent id.
Action wiring 21: A validated registration MUST record the registration event carrying the consent id, the processing scope, the processor reference AND now as the registration instant.
Action wiring 22: A landed registration whose registration event is not a repeat registration MUST add the binding carrying the registration event's registration instant AND event id.
Action wiring 23: A landed registration MUST answer registered.
Action wiring 24: The composition MUST write an index entry for a consent id ONLY AFTER the consent id's grant event lands.
Action wiring 25: The composition MUST add a binding ONLY AFTER the binding's registration event lands.
Action wiring 26: [Register Processing] MUST NOT call the consent check.
Action wiring 28: An opened withdrawal MUST derive the propagation set.
Action wiring 29: The composition MUST derive a propagation set from the registration events AND the purged downstream entries.
Action wiring 30: The composition MUST NOT derive a propagation set from a live downstream entry.
Action wiring 31: IF a derivation finds a registration event whose pair the downstream index lacks THEN the derivation MUST add the binding.
Action wiring 32: A validated withdrawal MUST call the invocation open with the act kind consent.withdrawal, the consent id as the act key, the actor reference, the credential AND the intent data carrying the consent id, the subject reference, the purpose, the reason AND now as the revocation instant, the pairing datum (Recoverable Invocation Action wiring 4).
Action wiring 33: A withdrawal intent MUST NOT carry the propagation set.
Action wiring 34: An opened withdrawal MUST call the revoke write with the consent id, the actor reference as the revoker, the reason AND the intent's revocation instant.
Action wiring 35: IF the revoke write answers already-revoked THEN [Withdraw Consent] MUST close the pre-commit arm through the invocation refuse AND answer already-revoked.
Action wiring 36: IF the revoke write answers already-expired THEN [Withdraw Consent] MUST close the pre-commit arm through the invocation refuse AND answer already-expired.
Action wiring 37: IF the revoke write answers invalid-request THEN [Withdraw Consent] MUST close the pre-commit arm through the invocation refuse AND answer invalid-request.
Action wiring 38: IF the revoke write answers storage-failure THEN [Withdraw Consent] MUST close the pre-commit arm through the invocation refuse AND answer storage-failure.
Action wiring 39: IF the revoke write answers not-known THEN [Withdraw Consent] MUST close the pre-commit arm through the invocation refuse AND answer not-known.
Action wiring 40: IF the revoke write answers not-known THEN the composition MUST open an index-anomaly finding for the consent id.
Action wiring 40a: The deployment MUST alert on EVERY index-anomaly finding.
Action wiring 41: [Withdraw Consent] MUST close a committed revoke through the invocation close naming consent.withdrawal.revoked AND carrying the consent id, the subject reference, the purpose, the reason, the propagation set AND the revocation instant (Recoverable Invocation commit 4).
Action wiring 42: A closed withdrawal MUST answer withdrawn.
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
Action wiring 58: IF the retention placement answers storage-failure THEN the grant transaction MUST commit no write AND [Record Consent] MUST close the pre-commit arm through the invocation refuse AND answer storage-failure.
Action wiring 59: IF a call of the grant transaction answers an arm of the unknown partition THEN [Record Consent] MUST call the invocation yield AND answer recording-failure(outcome) (Recoverable Invocation commit 8).
Action wiring 60: IF a call of the revoke write answers an arm of the unknown partition THEN [Withdraw Consent] MUST call the invocation yield AND answer recording-failure(outcome) (Recoverable Invocation commit 8).
Action wiring 61: IF the invocation open, refuse or close answers a code of Recoverable Invocation's Action wiring table THEN the action MUST answer that code.
```

NOTE: open 2026-11-04-c — Action wiring 12 lands the constituent's invalid-request after the intent committed, so a caller cannot tell a malformed input from a clock-order refusal (Consent Operation 8, 9) on the grant side; the single clock (Capability requirement 35) makes the clock-order refusal of the revoke unreachable.

Term administration action: [Record Consent], [Register Processing], [Withdraw Consent] or [Read Consent History].

Term action's scope: [Consent Grant] for [Record Consent], [Consent Register Processing] for [Register Processing], [Consent Revoke] for [Withdraw Consent], [Consent Read] for [Read Consent History].

Term grant intent: the consent.grant.intended event.

Term grant event: the consent.grant.granted event — the grant's outcome, carrying the consent id: one the invocation's close wrote, one the sweep recovered under the recovery identity or one an operator wrote through the invocation resolve.

Term registration event: the processing.registered event.

Term withdrawal intent: the consent.withdrawal.intended event.

Term propagation event: the consent.withdrawal.revoked event — the withdrawal's outcome, carrying the propagation set: one the invocation's close wrote, one the sweep recovered or one an operator wrote through the invocation resolve.

Term access event: the consent.history-read event.

Term intent event id: the event id of the intent an outcome pairs with — intent_event_id.

Term intent instant: the now an intent carries — intended_at.

Term registration instant: the now a registration event and its binding carry — registered_at.

Term revocation instant: the now a withdrawal intent carries as its pairing datum, which the withdrawal passes to the revoke write and its propagation event carries — revoked_at.

Term grantor: the actor reference a grant write records — granted_by.

Term revoker: the actor reference a revoke write records — revoked_by.

Term retention id: the id the retention placement mints — consent_record_retention_id on the grant event.

Term placement refusal: invalid-policy | policy-not-found | invalid-request — Retention Window's refusals of the retention placement.

Term record count: how many Consent records a history read returned.

Term propagation set: [Affected Scopes] — the registered set at the event's boundary: the pairs of the registration events carrying the consent id that PRECEDE the event's boundary in the Event Log, together with the purged downstream entries for the consent id whose registration event PRECEDES the event's boundary in the Event Log. The boundary is the withdrawal intent's own position: an invocation derives the set after its open has landed the intent, and the sweep re-derives it at the same position (Recoverable Invocation act probe 6), so a registration landing between the intent and the revoke lies outside the set (Edge cases, Cross-record consistency).

Term validated grant: a [Record Consent] call whose permission check answered permitted and whose inputs cleared Primitive policy.

Term admitted grant: a validated grant whose invocation open landed the grant intent.

Term checked grant: an admitted grant whose consent check answered a withheld state.

Term committed grant: a checked grant whose grant write answered a consent id.

Term placed grant: a committed grant whose retention placement answered a retention id.

Term landed grant: a placed grant whose invocation close landed the grant event.

Term resolved registration: a [Register Processing] call whose permission check answered permitted and whose consent id the subject index resolves.

Term validated registration: a resolved registration whose inputs cleared Primitive policy.

Term landed registration: a validated registration whose registration event landed.

Term resolved withdrawal: a [Withdraw Consent] call whose permission check answered permitted and whose consent id the subject index resolves.

Term validated withdrawal: a resolved withdrawal whose inputs cleared Primitive policy 1 through 6 and whose largest record the invocation open sized against the payload cap (Recoverable Invocation Primitive policy 12 and Primitive policy 13).

Term admitted withdrawal: a validated withdrawal whose invocation open landed the withdrawal intent.

Term committed withdrawal: an admitted withdrawal whose revoke write answered revoked.

Term landed withdrawal: a committed withdrawal whose invocation close landed the propagation event.

Term validated history read: a [Read Consent History] call whose permission check answered permitted and whose inputs cleared Primitive policy.

Term fetched history read: a validated history read whose consent read answered.

Term landed history read: a fetched history read whose access event landed.

Term validated gate query: a [Processing Permitted] call whose inputs cleared Primitive policy.

Term invocation: one call of a state-changing action, from its seam reading to its answer — for a bound action, the invocation Recoverable Invocation's open, commit and close or refuse make.


Term index-anomaly finding: a finding that the subject index resolves a consent id the Consent records do not know.

#### Closure table

Every input an action takes, and every answer a call of the five actions and of the leg can meet — Permissions' permission check, Consent's consent check, grant write, revoke write and consent read, Retention Window's retention placement, Audit Trail's audit write, record read and log read, and Recoverable Invocation's open, close, refuse and yield — with where the call lands it and the rule that owns the landing. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here. [Register Processing], [Read Consent History] and [Processing Permitted] are one transaction each (Execution Contract Database 1), and the three indexes stay outside it (Composition state 8). [Record Consent] and [Withdraw Consent] are Recoverable Invocation's: the intent commits at the open, ahead of the Consent write (Execution Contract Constituent failure 1), the Consent write is the commit, and the outcome lands at the close, so open, commit and close are three commits and not one transaction (Recoverable Invocation Non-goal 1); an act whose outcome never lands is the sweep's, closed within its closure window (Recoverable Invocation reconcile). A refusal writes nothing, except that a pre-commit arm of a bound action keeps the authenticated attempt in a refusal record (Recoverable Invocation commit 3).

**Inputs.**

| Action | Input | Lands | Owner |
|---|---|---|---|
| an administration action | a blank credential, or a blank actor reference the permission check does not deny | invalid-request, nothing written | Primitive policy 3, 4, 8, Execution Contract Refusal 1 |
| an administration action | the credential | consumed by the audit write alone, never inspected | Primitive policy 12, Term credential |
| every action | a blank payload string, or one longer than the field length cap | invalid-request, nothing written | Primitive policy 1, 2, 8 |
| every action | a caller string or an opaque reference | compared byte-exact, never normalized or interpreted | Primitive policy 10, 11, 13 |
| an administration action | inputs Primitive policy refuses, from an actor the permission check denies | permission-denied | Action wiring 2, Execution Contract Refusal 1 |
| [Register Processing], [Withdraw Consent] | a consent id the subject index misses once rebuilt | not-known, nothing written | Primitive policy 5, 8, Execution Contract Derived index 1 |
| [Register Processing] | a pair outside the registered set, where the set holds the registrations cap's pairs | registration-cap-exceeded, nothing written | Primitive policy 6, 8 |
| [Register Processing] | a pair the consent's downstream entry already holds | the registration event recorded, the binding unchanged | Action wiring 21, 22, Composition state 5 |
| [Withdraw Consent] | an outcome over Audit Trail's payload cap | invalid-request at the open, nothing written | Recoverable Invocation Primitive policy 12, 13 |
| [Record Consent] | an expiry or metadata | passed to the grant write unchanged, the metadata never interpreted | Action wiring 9, Term expiry, Term metadata |

**Permissions: the permission check**, at every administration action (Action wiring 1).

| Answer | Lands | Owner |
|---|---|---|
| permitted | the action's Primitive policy, then its first audit write or its invocation open | Action wiring 3, Term validated grant, Term resolved registration, Term resolved withdrawal, Term validated history read |
| denied | permission-denied, nothing written and nothing recorded | Action wiring 2, 3, Non-goal 8 |
| state-unavailable | passed through unchanged, nothing written | Execution Contract Read 1 through 3 |
| no answer | no answer to give | Execution Contract Error model 1 |

**Recoverable Invocation: the open, the close, the refuse and the yield**, at [Record Consent] and [Withdraw Consent].

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the open | an intent event id | the commit | Action wiring 4, 32, Term admitted grant, Term admitted withdrawal |
| the open | invalid-credential, invalid-request, act-in-flight, section-unavailable, journal-unavailable, recording-failure(intent) | the same code, nothing committed | Action wiring 61, Recoverable Invocation Action wiring table |
| the open | act-landed | never: both kinds are repeatable | Recoverable Invocation open step 3.9, repeatable 1 |
| the open | recording-failure(outcome) | recording-failure(outcome), the intent standing and its record the sweep's | Action wiring 61, Recoverable Invocation Action wiring table |
| the close | an event id | the index writes where the action owes them, and the action's answer | Action wiring 17, 18, 19, 41, 42 |
| the close | recording-failure(outcome) | recording-failure(outcome), the act committed and its record the sweep's | Action wiring 61, Recoverable Invocation commit 4 |
| the refuse | an event id | the constituent's own code, the attempt recorded | Action wiring 8, 11, 12, 14, 35 through 39, 58 |
| the refuse | already-accounted or recording-failure(refusal, constituent_code) | that code; the sweep records the attempt where the refusal did not land | Action wiring 61, Recoverable Invocation Action wiring table |
| the yield | its return | recording-failure(outcome), the act possibly committed and its record the sweep's | Action wiring 59, 60 |

**Consent and Retention Window, inside an action.** A state-unavailable from any of these calls is a pre-commit arm for a bound action and passes through unchanged for the others, and writes nothing (Execution Contract Read 1 through 3, Constituent failure 3), and a call with no answer is the unknown partition (Term commit partition). The other answers:

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the consent check, at [Record Consent] | granted | already-granted, the transaction rolling back, the arm refused | Action wiring 8 |
| the consent check, at [Record Consent] | revoked, expired or not-known | the grant write | Action wiring 9, Term checked grant |
| the grant write | a consent id | the retention placement | Action wiring 13, Term committed grant |
| the grant write | invalid-request | invalid-request, rolled back, refused | Action wiring 12 |
| the grant write | storage-failure | storage-failure, rolled back, refused | Action wiring 11 |
| the retention placement | a retention id | the close | Action wiring 17, Term placed grant |
| the retention placement | a placement refusal | invalid-request, rolled back, refused | Action wiring 14, Term placement refusal |
| the retention placement | registry-unavailable | passed through unchanged, rolled back, refused | Execution Contract Constituent failure 2 |
| the retention placement | storage-failure | storage-failure, rolled back, refused | Action wiring 58 |
| the revoke write | revoked | the close | Action wiring 41, Term committed withdrawal |
| the revoke write | already-revoked or already-expired | the same code, refused | Action wiring 35, 36 |
| the revoke write | invalid-request | invalid-request, refused; Primitive policy 1, 3 and 5 and the injected now (Capability requirement 37) meet its other grounds, so only a clock-order refusal reaches it | Action wiring 37 |
| the revoke write | not-known | not-known, refused, and an index-anomaly finding opened and alerted | Action wiring 39, 40, 40a |
| the revoke write | storage-failure | storage-failure, refused | Action wiring 38 |
| the revoke write or the grant transaction | a code none of the constituents declares, or a reply not arrived when the commit round trip has elapsed | the yield | Action wiring 59, 60, Term commit partition |
| the consent read, at [Read Consent History] | the consent history | the access event | Action wiring 50, Term fetched history read |
| the consent read | invalid-query | invalid-request; not met, the query carrying one subject reference filter Primitive policy 1 has checked | Action wiring 49 |
| the consent check, at [Processing Permitted] | granted | permitted | Action wiring 55 |
| the consent check, at [Processing Permitted] | revoked, expired or not-known | not-permitted carrying it | Action wiring 56 |

**Audit Trail: the audit write**, for the two single writes only. The intent, outcome and refusal of the bound actions are Recoverable Invocation's writes (Audit arm 18).

| Answer | a single write |
|---|---|
| an event id | landed: the binding or the history, and the action's answer (Action wiring 22, 23, 51, 52) |
| invalid-credential | invalid-credential (Audit arm 7) |
| invalid-request carrying step-1, step-2 or step-3 | invalid-request, alerted as a deployment fault (Audit arm 8, 9) |
| invalid-request carrying the retention step | proceeds as landed, alerted (Audit arm 6, 16) |
| recording-failure | recording-failure (Audit arm 13) |

A state-unavailable at an audit write passes through unchanged and writes nothing (Execution Contract Read 1 through 3), and a write with no answer leaves the action none to give (Execution Contract Error model 1).

**Audit Trail: the record read and the log read.**

| Read | Answer | Lands | Owner |
|---|---|---|---|
| the record read, on a binding's registration event | an audit record, Retained or Purged | the downstream entry live, or purged | Composition state 18, Term live index entry, Term purged index entry |
| the record read | not-known | not met: a binding carries a landed registration event's id | Action wiring 22, 25, Composition state 4 |
| the log read, from one with an open upper bound | the events | the derivation, the two rebuilds, the registered set's count and the leg's reading of the intents | Primitive policy 6, Action wiring 29, Composition state 9, 10, Reconciliation 6, 15 |
| the log read | invalid-query | not met: the range has a start and no end | Term log read |

Inside an action, a read that fails passes through unchanged and writes nothing (Execution Contract Read 1 through 3), and a read with no answer leaves the action none to give (Execution Contract Error model 1).

**The composition's own records.** An index entry is written after the event it derives from lands, outside the action's transaction (Action wiring 24, 25, Composition state 8): a write of one that fails or never answers is a rebuild trigger, not data loss (the section titled Composition state in `execution-contract.md`; Composition state 9, 10), and no rule reads a consent id as carrying no entry before the rebuild (Execution Contract Derived index 1). A purged index entry is truth-bearing, and no rebuild removes it (Composition state 13, 14).

**The leg.** It answers no caller, and decides only on an answered read (Reconciliation 38): a log read, record read or consent read that fails or gives no answer decides nothing, and the record is examined again at the next run (Reconciliation 2). It writes a binding repair with no audit event (Reconciliation 23) and opens findings; it writes no outcome, which is the sweep's under the recovery identity.


### Wiring decision

```
Wiring decision 1: The composition MUST append a propagation event ONLY AFTER the revoke write answers revoked.
Wiring decision 3: The composition MUST NOT expose a withdrawal surface other than [Withdraw Consent].
Wiring decision 4: The composition MUST NOT expose a consent gate other than [Processing Permitted].
```

<details markdown="block">
<summary>WHY</summary>

*Principle.* GDPR Articles 6 and 7 require a valid consent at processing time, and Article 7(3), read with Article 17(1)(b), requires that withdrawal end the basis for future processing — which, operationally, means the systems relying on the consent must learn of the withdrawal. The system must make both provable: that the gate was the single consent precondition, and that every withdrawal's downstream impact was enumerated and sealed at the moment of revocation.

*Likely objection.* Consent already owns the lifecycle and exposes its check. Why not let each processing system call it, and why a propagation event when the revocation is already in the Consent records?

*Mechanism.* Consent owns the state and exposes no gate and no propagation, by design. A check called per system is a gate re-implemented per system, and the first system that forgets it, caches a stale answer or treats expired as granted breaks the Article 6 basis silently (Wiring decision 4). And Consent records *that* a consent was revoked, never *what was relying on it* — importing downstream processing would break its freestanding status — so a revoke alone leaves the withdrawal's downstream impact unrecorded, and a system that never re-checks keeps processing with no record that it should have stopped. The composition closes this with the downstream index, populated by an audited act, and a propagation event carrying the complete set. The event follows the revoke (Wiring decision 1), so a propagation record always has a real revocation behind it — unconditionally, which is the direction an Article 7(3) dispute runs. The gap that remains runs the other way — a revocation whose propagation record has not landed, from a lost reply or a crash between the revoke and the close — and it is a gap in the *accounting*, not the *suppression*, closed by Recoverable Invocation's sweep within its closure window, which writes the owed record from what the database holds or escalates, and never re-runs the revoke: the gate reads Consent and answers not-permitted carrying revoked from the instant the revoke commits, given single-active-grant (Invariant 1.3). What would defeat the purpose is the mirror — an event asserting a withdrawal the database does not hold — and the order makes it unreachable.

*Result.* The gate is structural and single; the propagation is complete and sealed *over the registered set*. An auditor answers *when this person withdrew consent, what was supposed to stop, and is it recorded?* by reading one sealed event rather than interviewing every processing system. **What the records cannot prove is outward completeness**: the composition proves what was registered, never that every real processing activity registered — an unregistered one is invisible to the propagation exactly as a gate-bypassing one is invisible to the gate. The two single-surface obligations are paired and the deployment's (Capability requirement 30 and 31; Invariant 1.2).

</details>

### Reconciliation

```
Reconciliation 2: The reconciliation MUST run every sweep cadence.
Reconciliation 4: IF a Consent record IS a young record OR IS an aged record THEN the reconciliation MUST NOT examine the record.
Reconciliation 6: The reconciliation MUST read EVERY revoked Consent record Reconciliation 4 admits against the withdrawal intents (Reconciliation 11 states the key).
Reconciliation 11: IF no withdrawal intent carries a revoked Consent record's consent id AND revocation instant THEN the reconciliation MUST open a write-ownership finding for the record.
Reconciliation 15: The reconciliation MUST read EVERY Consent record Reconciliation 4 admits against the grant intents.
Reconciliation 16: IF no grant intent carries a Consent record's subject reference AND purpose as the act key AND the record's grant instant as the pairing datum THEN the reconciliation MUST open a write-ownership finding for the record.
Reconciliation 22: IF a registration event's pair IS NOT IN the downstream index THEN the reconciliation MUST add the binding from the payload of the pair's first registration event.
Reconciliation 23: The reconciliation MUST NOT record an audit event for a binding repair.
Reconciliation 38: The reconciliation MUST decide ONLY on an answered read.
Reconciliation 39: The reconciliation MUST read the sweep's run reading of now AND MUST NOT read now at a seam of the reconciliation.
NOTE: watch the sweep's run reading (Reconciliation 39).
Reconciliation 40: IF an abandonment OR a refusal closes a withdrawal intent of a Consent record's consent id whose pairing datum EQUALS a revoked Consent record's revocation instant THEN the reconciliation MUST alert the finding surface carrying the consent id.
Reconciliation 41: IF an abandonment OR a refusal closes a grant intent of a Consent record's grant key whose pairing datum EQUALS a Consent record's grant instant THEN the reconciliation MUST alert the finding surface carrying the consent id.
```

Term reconciliation: the leg the composition runs outside every invocation, beside the sweep — the binding repair, and the reading of the Consent records against the intents, whose output, a write-ownership finding, an auditor awaits at the sweep cadence and within no window of its own.

Term young record: a Consent record whose grant instant — or, revoked, whose revocation instant — stands within the act kind's examine window end of the sweep's now — a record whose invocation the sweep may still be closing.

Term aged record: a Consent record for which the sweep's now DOES NOT PRECEDE `(((grant instant + audit horizon) - (2 * clock offset allowance)) - reconciliation run bound)`, or, revoked, the same from its revocation instant.

Term unpropagated record: a revoked Consent record no propagation event names, neither young nor aged.

Term ungranted record: a Consent record no grant event names, neither young, aged nor a purged grant.

Term purged grant: a Consent record whose consent id keys a purged key entry — its grant event's payload destroyed at the audit horizon.

Term grant instant: the instant Consent stamps on a record at its grant write — granted_at, which the host's injection of the invocation's now makes equal to the grant intent's pairing datum (Capability requirement 37).

Term binding repair: a binding the reconciliation adds from a registration event's payload.

Term finding surface: the deployment's compliance surface — the surface Recoverable Invocation's instance writes its register to. A write-ownership finding and this page's alerts are written beside that register and are no part of it (Recoverable Invocation findings 6).


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
  Invariant 2.2: EVERY grant event MUST carry an attestation AND a position in the Event Log sequence.
  ```
- **Invariant 3 — Revocation propagation completeness.**
  ```
  Invariant 3.1: EVERY propagation event MUST name a consent the Consent records hold in Revoked.
  Invariant 3.2: Two propagation events MUST NOT carry one consent id.
  Invariant 3.3: A propagation event's propagation set MUST EQUAL the registered set at the event's boundary.
  NOTE: the invocation resolve does not check an operator's outcome against the database (Recoverable Invocation resolve 28, Recoverable Invocation resolve 31), so Invariant 3.1, Invariant 3.2 and Invariant 3.3 are detected, not prevented, for an operator's closing: Check 3.1, Check 3.2 and Check 3.10 find it.
  ```
  Term event's boundary: the position in the Event Log of the intent the event's intent event id names.

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
  Invariant 6.3: The composition MUST read a consent retention's proof-period end ONLY as the consent retention's retention deadline.
  ```
  Term consent retention: the consent retention instance's record over one consent record.

- **Invariant 7 — Inward and outward authorization stay separate.**
  ```
  Invariant 7.1: An administration action MUST NOT commit a constituent write for an actor the permission check denied.
  Invariant 7.2: A validated gate query MUST call ONLY the consent check.
  ```
- **Invariant 8 — Authentication precedes commitment.**
  ```
  Invariant 8.3: The composition MUST NOT add a binding BEFORE Audit Trail validates the caller's credential at the registration event.
  Invariant 8.4: The composition MUST NOT answer a consent history BEFORE Audit Trail validates the caller's credential at the access event.
  ```

The gate plus grant coverage gives *substantiated processing* — every consent-based action gated on a recorded, attributed consent. Propagation completeness plus registration recording gives *propagated withdrawal* — every withdrawal's downstream impact, the scopes registered before its intent, enumerated and itself provable. The provable lifecycle and the retention floor close the lifecycle; Invariant 7 keeps the two authorization surfaces apart, and Invariant 8 makes Invariant 7's inward half a claim about a verified operator.

---

## Examples

### Walkthrough — marketing-consent management under GDPR

A retail platform uses this composition to manage marketing consent. Configuration: `consent_record_retention_policy_ref = gdpr_consent_proof_6yr`, `audit_trail_retention_policy = gdpr_audit_10yr`. Permission grants: the consent-service actor holds `consent:grant`, `consent:register-processing`, `consent:revoke`, `consent:read`; the data-subject-request officer `dsr_officer` holds `consent:read`.

1. **Record consent.** A user affirms a marketing-email consent banner; the consent service calls `record_consent(actor_ref="consent_svc", subject_ref="user-4491", purpose="marketing:email", credential=<consent_svc>, retention_policy_ref="gdpr_consent_proof_6yr", expires_at="2027-05-13T00:00:00Z") → consent_id = cns-7001`. Internally: `Permissions.permitted("consent_svc", "consent:grant") → permitted`; then — **before anything commits** — Audit Trail records `consent.grant.intended` → `ev_grant_int_01`, which is where the consent service's credential is checked against the actor registry (had it not validated, the call would have returned `rejected(invalid-credential)` with no consent granted and no retention placed); then `Consent.check("user-4491", "marketing:email") → not-known` — no Granted record for the pair, so single-active-grant holds and the grant proceeds; then `Consent.grant(...) → cns-7001` (Granted); `Retention Window.place_under_retention(cns-7001, gdpr_consent_proof_6yr) → ret_cns_7001`; Audit Trail records `consent.grant.granted` carrying `intent_event_id: ev_grant_int_01`; maps populated. Note what the intent event does **not** carry: no `cns-7001`, which did not exist when it was written and which only `consent.grant.granted` may make resolvable.

2. **Register downstream processing.** Two systems will rely on this consent. `register_processing(actor_ref="consent_svc", consent_id="cns-7001", processing_scope="email-campaign-engine", processor_ref="campaigns@platform", credential=<consent_svc>) → registered`, and again for `processing_scope="lookalike-audience-builder", processor_ref="adtech@platform"`. Each records a `processing.registered` event; `consent_to_downstream[cns-7001]` now holds two bindings.

3. **Gate check before processing.** Before sending a campaign, the email engine calls `processing_permitted("user-4491", "marketing:email") → permitted`. The campaign proceeds.

4. **Withdrawal with propagation.** The user clicks "unsubscribe / withdraw consent." The consent service calls `withdraw_consent(actor_ref="consent_svc", consent_id="cns-7001", credential=<consent_svc>, reason="user-withdrawal-via-preferences") → withdrawn`. Internally: `Permissions.permitted("consent_svc", "consent:revoke") → permitted`; Audit Trail records `consent.withdrawal.intended` → `ev_wd_int_01`, written at the invocation's open and verifying the credential before the terminal transition and carrying the consent_id but **not** the `affected_scopes` (one authoritative carrier, Invariant 3); `Consent.revoke(cns-7001, ...) → revoked`; the invocation's close derives `affected_scopes` from the two `processing.registered` events carrying `cns-7001` that precede the intent = `{email-campaign-engine@campaigns, lookalike-audience-builder@adtech}` and Audit Trail records `consent.withdrawal.revoked` carrying `intent_event_id: ev_wd_int_01` and the complete `affected_scopes` set — *ordered after the revoke*. Invariant 3 holds: the revocation is committed and its downstream enumeration, the scopes registered before the intent, is sealed behind it, one propagation event per withdrawal. The order is checkable: `ev_wd_int_01` precedes the propagation event in the Event Log's order (their `intended_at` and `revoked_at` are the same injected instant, so the `sequence_number` is what settles it) and names the same operator.

5. **Gate check after withdrawal.** `processing_permitted("user-4491", "marketing:email") → rejected(not-permitted(revoked))`. The email engine and the audience builder, consuming the propagation event or re-querying the gate, cease processing; deleting the derived lookalike audience is the audience builder's own obligation, signalled by the `consent.withdrawal.revoked` event's `affected_scopes`.

6. **Data subject access request (DSAR) audit.** A data-subject access request calls `read_consent_history(actor_ref="dsr_officer", subject_ref="user-4491", credential=<dsr_officer>)` → the Granted-then-Revoked `cns-7001` record; a `consent.history-read` meta-event is recorded. The complete lifecycle — the grant and its intent, two registrations, the withdrawal-with-propagation and its intent, the access — is provable (Invariant 5), and each state-changing act's records show the operator was verified before it committed (Invariant 8).

### Re-consent path

Six months after withdrawal the user re-enables marketing email. `record_consent(...) → cns-7042` (the single-active-grant check answers revoked, so the grant proceeds; a fresh Granted record, `cns-7001` remaining Revoked as evidence). `processing_permitted("user-4491", "marketing:email") → permitted` (Consent's `check` evaluates the most-recent grant). Downstream processing is re-registered against the new consent_id; the prior consent's propagation record is untouched history.

### Rejection path — a second grant for a pair that already holds one

A retry of the walkthrough's first `record_consent(...)` after a timeout, or a second banner affirmation while `cns-7001` is Granted: the single-active-grant check `Consent.check("user-4491", "marketing:email") → granted` → the answer already-granted, a pre-commit refusal: the grant transaction commits nothing, and the invocation's refuse records the attempt with a `consent.grant.refused` event carrying the constituent's code. No second Granted record is created for the pair (Invariant 1.3). Where the first call had committed `cns-7001` and answered `recording-failure(outcome)`, that answer is the caller's signal that the record exists and the sweep owns its event — the caller does not grant again.

### Rejection path — withdrawal by an unauthorized operator

An operator lacking `consent:revoke` attempts `withdraw_consent(...)`: the permission check `Permissions.permitted → denied` → `rejected(permission-denied)`. No consent state changes; no propagation event is recorded. (Invariant 7 — administration is permission-gated.)

### Rejection path — withdrawing an already-revoked consent

A retry after a timeout: `withdraw_consent(actor_ref="consent_svc", consent_id="cns-7001", credential=<consent_svc>, reason="retry")` → the withdrawal intent is written (the operator is real and their credential validates), then Consent's already-revoked, a pre-commit refusal, is relayed as the answer already-revoked and the invocation's refuse records the attempt with a `consent.withdrawal.refused` event. No second propagation event is recorded; the single `consent.withdrawal.revoked` event from the first withdrawal stands. The retry leaves a `consent.withdrawal.intended` event closed by a refusal, and the sweep's probe answers not-committed for its pairing datum, since the consent is Revoked at *another* invocation's instant (Check 6.4): nothing is owed and no recovered record may be written. (Consent Invariant 3 — terminal absorption — surfaced at the composition boundary.)

### Failure path — withdrawal whose propagation event fails to record

A [Withdraw Consent] call passes its checks, opens its invocation (the intent lands), revokes, and the close's `record_action` returns recording-failure — the Event Log append answered nothing, its reply lost — so no outcome lands and the call answers `recording-failure(outcome)`, an answer and not a refusal, its intent and revoke committed with it: the position telling the consent service the consent **is** Revoked and the action must not be re-run (a re-run would be refused already-revoked in any case). The record is the sweep's: at its next run it finds the intent open, runs the withdrawal probe — Consent's read by the consent id with the intent's `revoked_at` — and, the record standing Revoked at that instant, writes a `consent.withdrawal.recovery_intended` record and then the outcome `consent.withdrawal.revoked` under the composition's service identity, carrying the recovery flag, the original caller as the acting actor reference and the original `consent.withdrawal.intended` event as its `intent_event_id`, so an auditor distinguishes the recovered withdrawal from a clean one and still reads who withdrew (Recoverable Invocation Invariant 5.1, 5.2). Had the cause been permanent, or the probe undecidable, the sweep would have escalated the intent with its cause for an operator to settle through the invocation resolve. The gate is honest during the gap: processing_permitted reads Consent, so it returns `rejected(not-permitted(revoked))` from the moment the revoke committed.

### Rejection path — gate query for a subject who never consented

`processing_permitted("user-9999", "marketing:email")` where no consent record exists → `Consent.check → not-known` → `rejected(not-permitted(not-known))`. The processing system distinguishes *never consented* from *withdrawn* and requests consent rather than honoring a withdrawal that never happened.

---

### Regulated adversarial scenarios

**Regulator audit — "prove every consent-based processing activity was gated on valid consent, and that withdrawals propagated."** A data protection authority examines the Audit Trail and the processing records. For every downstream processing activity *the deployment discloses* (the composition's records enumerate the registered set; whether that set is outwardly complete is the deployment's registration obligation, verified against the deployment's own processing inventory — an externally-clearable question), the examiner confirms a `processing.registered` event bound it to a consent_id (Invariant 4); for the consent governing it, the examiner confirms a `consent.grant.granted` event (Invariant 2) and that `AuditTrail.verify_record` returns verified for both. For every withdrawn consent, the examiner confirms exactly one `consent.withdrawal.revoked` event whose `affected_scopes` enumerates every `processing.registered` binding for that consent_id whose event precedes the event's boundary (Invariant 3.3) — a withdrawal whose `affected_scopes` omits such a binding, or a revoked Consent record with no `consent.withdrawal.revoked` event and none of Check 3.4's other resolutions, is a conformance failure. Every claim is provable; the gate is the single processing precondition (Invariant 1) and the propagation event is the single record of downstream impact.

**Disputed withdrawal — data subject claims processing continued after they withdrew consent.** A data subject complains that marketing continued after withdrawal. The investigator retrieves the `consent.withdrawal.revoked` event for the subject's consent: it carries `revoked_at`, reason, and the complete `affected_scopes` set naming `email-campaign-engine@campaigns` and `lookalike-audience-builder@adtech`. The investigator can therefore name *exactly which processors were on notice* and when. Consent Invariant 9 (revocation non-retroactivity) and the Audit Trail seal establish the withdrawal record was not altered or back-dated. If a named processor continued after `revoked_at`, that is that processor's compliance failure — this composition's records prove the withdrawal was recorded, propagated, and enumerated; whether each named processor *acted* on it is the processor's obligation, signalled but not performed by this composition. The propagation event is the rebuttal to "we were never told."

**Breach or incident forensics — which subjects had withdrawn consent during the compromise window, and was any withdrawal record altered.** An incident investigator is given a window and must reconstruct which consents were Granted versus Revoked during it and whether any withdrawal or its propagation set was tampered with. The investigator replays each consent's `consent.grant.granted`, `processing.registered`, and `consent.withdrawal.revoked` events in Event Log insertion order (reached transitively through Audit Trail), determining each consent's state and downstream-binding set at the window's bounds, then runs `AuditTrail.verify_record` against representative events in each seal's coverage to bound any tampering window. Invariant 3 is load-bearing: a `consent.withdrawal.revoked` event whose `affected_scopes` was silently shrunk to hide a processor that should have stopped is foreclosed by the append-only, sealed log — the propagation set is part of the hashed event payload, so an alteration breaks the seal. The newest events in the Audit Trail's unsealed tail carry Event Log per-event immutability but become seal-verifiable only after the next seal cadence; until then a tail event returns `failed-verification(unsealed)`, so the integrity bound on the most recent withdrawals is the substrate's unsealed-tail policy (a tighter `seal_cadence` narrows it).

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when the checks below are provable to an external auditor given the three indexes and the Consent, Permissions, consent retention and Audit Trail substrate's records. Every enumeration of audit events below runs through the log read, never through a query the substrate routes to Reverse Index.

### Conformance checks

```
Check 1.1: An auditor MUST find [Processing Permitted] AND the consent check agreeing over a sample of subject references AND purposes (Invariant 1.1).
Check 1.2: An auditor MUST find no two governed consents in Granted carrying one subject reference AND one purpose (Invariant 1.3).
Check 2.2: An auditor MUST resolve EVERY ungranted record to EXACTLY ONE OF a record whose grant intent stands open, an escalated grant other than a false closing, a false closing, a write-ownership finding (Reconciliation 15, Reconciliation 16, Reconciliation 41).
Check 2.3: An auditor MUST find a passing verification for EVERY grant event (Invariant 2.2).
Check 3.1: An auditor MUST find no consent id two propagation events carry (Invariant 3.2).
Check 3.2: An auditor MUST find EVERY propagation event's propagation set equal to the registered set at the event's boundary (Invariant 3.3).
Check 3.3: An auditor MUST find a passing verification for EVERY propagation event (Invariant 5.1).
Check 3.4: An auditor MUST resolve EVERY revoked Consent record carrying no propagation event, other than a young record, to EXACTLY ONE OF propagation history purged other than a false closing, an unpropagated record whose withdrawal intent stands open, an escalated withdrawal other than a false closing AND other than propagation history purged, a false closing, an unpropagated record that is a write-ownership finding, a conformance failure (Reconciliation 6, Reconciliation 11, Reconciliation 40, Reconciliation 41).
Check 3.10: An auditor MUST find EVERY propagation event naming a consent the Consent records hold in Revoked (Invariant 3.1).
Check 4.1: An auditor MUST find a registration event preceding the event's boundary for EVERY pair a propagation set carries (Invariant 4.1).
Check 4.2: IF the record read answers Purged for a pair's registration event THEN an auditor MUST compare the event's surviving sequence number with the event's boundary (Invariant 4.1).
Check 5.1: An auditor MUST find a consent retention in Retained for EVERY governed consent carrying a grant event (Invariant 6.1).
Check 5.2: An auditor MUST find no consent retention in Purged (Invariant 6.1).
Check 6.1: An auditor MUST resolve EVERY outcome's intent event id to an intent that PRECEDES the outcome in the Event Log AND carries the outcome's invocation id, the actor of a recovered outcome being the acting actor reference the outcome carries (Recoverable Invocation Invariant 1.1, Recoverable Invocation Invariant 5.2).
Check 6.2: An auditor MUST NOT join an outcome to an intent by any key other than the invocation id (Recoverable Invocation Primitive policy 5).
Check 6.3: An auditor MUST NOT order an intent AND the intent's outcome by instant (Clock semantics 1).
Check 6.4: An auditor MUST read an intent carrying no outcome as open, awaiting the sweep, closed by the sweep or by an operator, never as a conformance failure (Recoverable Invocation Invariant 4.2).
Check 7.1: An auditor MUST find the audit horizon exceeding EVERY consent retention period (Capability requirement 4).
Check 7.2: An auditor MUST find no consent id resolved from the Consent records on a subject index miss (Composition state 11).
Check 7.3: An auditor MUST read a payload-dependent clause on an event the verification answers purged as unverifiable (Composition state 13).
Check 7.4: An auditor MUST read failed-verification carrying unsealed as pending the next seal (Invariant 2.2).
Check 8.1: An auditor MUST clear Consent's Generation acceptance over the Consent instance (Composes 5).
Check 8.2: An auditor MUST clear Permissions' Generation acceptance over the Permissions instance (Composes 5).
Check 8.3: An auditor MUST clear Retention Window's Generation acceptance over the consent retention instance (Composes 5).
Check 8.4: An auditor MUST clear Audit Trail's Generation acceptance over the Audit Trail instance (Composes 5).
Check 8.5: An auditor MUST clear Recoverable Invocation's Generation acceptance over the Recoverable Invocation instance (Composes 5).
```

NOTE: EVERY check names the rule the check tests.


Term passing verification: verified | failed-verification carrying purged | failed-verification carrying unsealed | unverifiable carrying partially-purged-coverage.

Term propagation history purged: an aged revoked Consent record carrying no propagation event, which no `consent.withdrawal.escalated` record names — its event lawfully destroyed.

Term write-ownership finding: the finding Reconciliation 11 opens for a revoked Consent record no withdrawal intent carries, or Reconciliation 16 for a Consent record no grant intent carries — a direct write against a reserved surface (Composes 11 and 12).

Term escalated grant: a Consent record whose grant intent the sweep escalated, or an operator settled through the invocation resolve.

Term escalated withdrawal: a revoked Consent record whose withdrawal intent the sweep escalated, or an operator settled through the invocation resolve.

Term false closing: a Consent record standing beside an intent of its act key and pairing datum closed by an abandonment or a refusal.

### External checks

```
External check 1: An auditor needing the registered set's completeness confirmed MUST read the deployment's processing inventory (Capability requirement 31).
External check 2: An auditor needing a named processor's cessation confirmed MUST read the processing system's own records (Non-goal 1).
External check 3: An auditor needing a consent's quality under Article 7 of the General Data Protection Regulation confirmed MUST read the deployment's consent capture (Non-goal 2).
External check 4: An auditor needing a scope grant's organizational authority confirmed MUST read the Permissions-administration layer (Invariant 7.1).
External check 5: An auditor needing a retention policy reference's proof period confirmed MUST read the deployment's policy registry AND the regime's floor (Capability requirement 5).
External check 6: An auditor needing a purpose's lawful basis confirmed MUST read the deployment's basis selection (Non-goal 3).
External check 7: An auditor needing the obligation of Capability requirement 37 and Capability requirement 38 confirmed MUST clear the obligation from external evidence (Recoverable Invocation External check 12).
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
Non-goal 10: The composition MUST NOT describe an act's open, commit and close as atomic (Recoverable Invocation Non-goal 1).
Non-goal 11: The composition MUST NOT own a re-entry arm for an already-granted or already-revoked answer beyond the constituent's own refusal (Recoverable Invocation Non-goal 4).
Non-goal 12: The composition MUST NOT bind the interval between a [Processing Permitted] answer and the processing activity the answer authorizes.
```

Term downstream cessation: deleting derived data, halting a pipeline or notifying a third party on a withdrawal.

Term delivery preference: a channel, frequency cap or quiet-hours setting that shapes processing already lawful.

Term withdrawal surface: the unsubscribe link, preferences toggle or other data-subject-facing surface a withdrawal starts from.

Term denied attempt: an administration action refused permission-denied.

NOTE: the owners — [Message Preference / Personalization](../atoms/message-preference.md) under [Preference-Aware Notification Fanout](./preference-aware-notification-fanout.md) (Non-goal 4); the deployment (Non-goal 5, Non-goal 6), and of each processing system the deployment runs (Non-goal 12); a failed-attempt pattern (Non-goal 8); [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md) (Non-goal 9).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the Event Log sequence as the order of an intent AND the intent's outcome.
```

### Concurrency


### Retention asymmetry

```
Retention asymmetry 1: The consent retention instance MUST NOT EQUAL the Retention Window instance inside Audit Trail.
Retention asymmetry 2: The composition MUST NOT call the purge on the consent retention instance.
```

### Cross-record consistency

```
Cross-record consistency 1: IF the revoke write commits AND the invocation's close does not land THEN the Consent record MUST carry an open withdrawal intent, closed by the sweep within the closure window.
Cross-record consistency 2: IF the grant transaction commits AND the invocation's close does not land THEN the Consent record MUST carry an open grant intent, closed by the sweep within the closure window.
Cross-record consistency 3: A propagation set MUST NOT carry a registration event that landed after the withdrawal intent.
```

The first two are Recoverable Invocation's Cross-record consistency for the two act kinds, which the sweep closes; the gate is honest throughout (Wiring decision WHY). The third is this page's own: the set is derived at the intent's position and the probe can re-derive it only there, so a registration made against a still-Granted consent, after the intent, is not named by the withdrawal.

---

## Composition notes

**Recoverable Invocation.** [Record Consent] and [Withdraw Consent] follow [Recoverable Invocation](./recoverable-invocation.md) around their acts (Composes 15 through 19): an intent before the commit, the one outcome as the close, a refusal record where the constituent refuses, the act's critical section over them, and a sweep and an operator's invocation resolve for what an invocation left open. The page binds the two act kinds once (Term consent bindings) and restates none of the protocol. [Register Processing], [Read Consent History] and [Processing Permitted] are not bound (Composes 18): a registration is one write and one record, a history read writes only its own access event, and the gate reads Consent alone.

**Recoverable Invocation's commit is one call.** Recoverable Invocation's bound commit is one constituent call whose arms the constituent partitions; the grant kind's is three calls in one database transaction (Term grant transaction), whose partition belongs to the transaction, the consent check's granted answer and a refusal of the grant write or the retention placement each rolling it back. Recoverable Invocation's closed list of deviations has no entry for it, and the page treats the transaction as the commit and records the mismatch as an open line (Recoverable Invocation Deviation 2), as External Onboarding does. The withdrawal's commit is one call, the revoke write, and needs no such reading.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are its five actions — the four administration actions [Record Consent], [Register Processing], [Withdraw Consent] and [Read Consent History], and the read-only gate [Processing Permitted]; the [Affected Scopes] a propagation event enumerates and the [Processing Scope] each binding names; the four scopes it defines for its Permissions instance, [Consent Grant], [Consent Revoke], [Consent Register Processing] and [Consent Read]; and the gate's refusal, [Not Permitted]. The propagation guarantee is a structural property, not a datum. The deployment settings keep their wire spellings in configuration — `consent_record_retention_policy_ref`, `audit_trail_retention_policy`, `administration_completion_bound`, `application_actor_ref`, `application_credential`, `field_length_cap`, `registrations_cap`, `event_id_width` — and the indexes their own in an implementation, `consent_to_downstream`, `consent_to_retention`, `consent_to_subject_purpose`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the reconciliation; a deployment; a regulated deployment; an auditor; a caller; a processing system; a processing activity; an invocation; an administration action; a validated grant; an admitted grant; a checked grant; a committed grant; a placed grant; a landed grant; a validated registration; a landed registration; a resolved withdrawal; a validated withdrawal; an admitted withdrawal; a committed withdrawal; a landed withdrawal; a validated history read; a fetched history read; a landed history read; a validated gate query; a derivation; a rebuild.

Term records: the grant intents, grant events, grant refusals, registration events, withdrawal intents, propagation events, withdrawal refusals and access events the composition records through the audit write and Recoverable Invocation — each an Event Log event carrying one action reference below, with the recovery intents, abandonments and escalations Recoverable Invocation derives from the two kinds — the Consent records it writes through the grant and revoke writes, the consent retentions it places, and the three indexes' entries.

Term record verbs: EQUAL, add, alert, answer, append, attest, authenticate, bind, call, capture, carry, change, classify, clear, close, commit, compare, compensate, compose, decide, derive, describe, destroy, disclose, duplicate, escalate, examine, expose, find, gate, govern, hold, identify, inherit, inject, inspect, interpret, join, key, leave, model, name, normalize, open, order, own, pair, pass, perform, proceed, process, provision, re-derive, reach, read, rebuild, record, refuse, remove, report, resolve, retry, run, select, serve, set, stamp, start, store, substitute, supply, write.

Term value sets: action reference = consent.grant.intended | consent.grant.granted | consent.grant.refused | processing.registered | consent.withdrawal.intended | consent.withdrawal.revoked | consent.withdrawal.refused | consent.history-read, with the references Recoverable Invocation derives under each kind. The rest are declared where the section that owns each declares it: withheld state, placement refusal, position, act kind.

Term bounds: administration completion bound (administration_completion_bound), reconciliation run bound (Recoverable Invocation's run bound), field length cap (field_length_cap), registrations cap (registrations_cap), event id width (event_id_width), id width (id_width), clock offset allowance (Recoverable Invocation's clock allowance), commit round trip, probe round trip, settling period, audit horizon (audit_trail_retention_policy).

Term cadences: Recoverable Invocation's sweep cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive atoms, consent retention instance, log read, record read, audit write, verification, grant write, revoke write, consent check, consent read, permission check, retention placement, consent namespace, consent id, downstream index, retention index, subject index, index entry, downstream entry, retention entry, subject entry, binding, pair, repeat registration, registration event id, live index entry, purged index entry, purged downstream entry, key entry, purged key entry, live downstream entry, live key entry, downstream rebuild, grant rebuild, consent validity flag, retention policy reference, consent retention period, audit retention policy, audit horizon, regulated deployment, reconciliation run bound, administration completion bound, required setting, field length cap, registrations cap, event id width, maximal envelope, clock offset allowance, recovery identity, processing system, processing activity, seam, now, payload string, caller string, subject reference, purpose, processor reference, reason, actor reference, credential, opaque reference, registered set, intent, outcome, single write, subsequent write, retention step, position, consent history, withheld state, expiry, metadata, administration action, action's scope, grant intent, grant event, registration event, withdrawal intent, propagation event, access event, intent event id, intent instant, registration instant, revocation instant, grantor, revoker, retention id, placement refusal, record count, propagation set, validated grant, admitted grant, checked grant, committed grant, placed grant, landed grant, resolved registration, validated registration, landed registration, resolved withdrawal, validated withdrawal, admitted withdrawal, committed withdrawal, landed withdrawal, validated history read, fetched history read, landed history read, validated gate query, invocation, index-anomaly finding, reconciliation, aged record, unpropagated record, ungranted record, purged grant, grant instant, binding repair, governed consent, query's instant, event's boundary, lifecycle, consent retention, passing verification, propagation history purged, write-ownership finding, processing inventory, consent capture, downstream cessation, delivery preference, withdrawal surface, denied attempt, act kind, consent bindings, withdrawal key, grant key, grant transaction, commit partition, withdrawal probe, grant probe, invocation id, commit round trip, probe round trip, settling period, young record, finding surface, escalated grant, escalated withdrawal, false closing.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index classification. Execution Contract Logic confinement 14 — the seam. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. record_action, read_record, verify_record, payload cap, attestation id width, unsealed tail, step-2, step-3, step-4, invalid-credential, invalid-request, recording-failure, verified, failed-verification, unverifiable, unsealed, purged, partially-purged-coverage, compensation-window, Retained, Purged, Erasure Tombstone, Reverse Index: Audit Trail. grant, revoke, check, read, granted, revoked, expired, not-known, already-revoked, already-expired, invalid-request, storage-failure, invalid-query, Granted, Revoked, Expired: Consent. permitted, denied: Permissions. place_under_retention, purge, invalid-policy, policy-not-found, storage-failure, Retained, Purged, retention deadline, Policy Registry: Retention Window. read: Event Log. Processing Register: forthcoming.

Term composing patterns: [Customer Onboarding](./customer-onboarding.md); [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md); [Preference-Aware Notification Fanout](./preference-aware-notification-fanout.md); [Notification Fanout](./notification-fanout.md); [Message Preference / Personalization](../atoms/message-preference.md); [Defensible Retention](./defensible-retention.md); [Capability-Backed Sharing](./capability-backed-sharing.md); [Attributed Permissions Admin](./attributed-permissions-admin.md).

#### Record Consent

The composition action that records a data subject's consent for a purpose under an authorized operator's authority: it checks the operator's [Consent Grant] permission, opens a Recoverable Invocation act of kind consent.grant — the `consent.grant.intended` record is the write that verifies the operator's credential, before anything commits — then, in the grant transaction, answers already-granted where the subject already holds a Granted record for the purpose (single-active-grant, Invariant 1.3), calls `Consent.grant` and places the consent record under its retention floor, and closes the act with the audit of the grant (`consent.grant.granted`, carrying the intent event's id). Returns the consent_id.

Kind: Operation

#### Register Processing

The composition action that binds a downstream processing activity ([Processing Scope]) to a consent, making *what relied on this consent* a recorded fact rather than tribal knowledge. It does not check consent state — that is [Processing Permitted]'s job at processing time. Audit-first: the binding enters `consent_to_downstream` only after its `processing.registered` event lands. Refuses registration-cap-exceeded past `registrations_cap` distinct bindings per consent.

Kind: Operation

#### Withdraw Consent

The composition's structural reason to exist: revoke a consent **and propagate the withdrawal** — recording, in a propagation event ordered after the `Consent.revoke`, the complete [Affected Scopes] set (every downstream scope registered against the consent before the withdrawal was intended) on one tamper-evident `consent.withdrawal.revoked` event. A `consent.withdrawal.intended` event, written at the invocation's open, precedes the revoke and is where the revoker's credential is verified, so a terminal transition is never performed on an unverified claim (Invariant 1.1 of Recoverable Invocation). Revoke, then propagation event, ordered; a revoke whose event has not landed is closed by the sweep (Cross-record consistency 1).

Kind: Operation

#### Read Consent History

The permission-gated read surface for compliance dashboards, DSAR workflows, and regulatory reporting. Because access to consent records is itself a regulated act, it records a `consent.history-read` meta-event and refuses to return the records if that meta-event fails to land.

Kind: Operation

#### Processing Permitted

The read-only consent-gates-processing query every processing system consumes before acting on personal data (rather than reading Consent directly). Returns permitted exactly when `Consent.check` reports valid consent, else [Not Permitted] naming the actual state. Produces no audit event — it changes no state.

Kind: Operation

#### Affected Scopes

The complete set of downstream processing bindings ([Processing Scope] plus processor) registered against a consent, derived from the `processing.registered` events preceding the withdrawal's intent (the map supplying only the entries whose named event the substrate reports Purged), bounded by `registrations_cap`, and recorded on the `consent.withdrawal.revoked` propagation event. Its completeness is Invariant 3.3: the enumeration is exactly what was registered against the consent, never silently shrunk — whether every real processing activity registered is the deployment's obligation, so a withdrawal's downstream impact is provable.

Kind:       Field
Field of:   the consent.withdrawal.revoked propagation event
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
- **GDPR Article 7(1)** — the controller bears the burden of demonstrating consent. This composition's `consent.grant.granted` events plus the retained Consent records (held under the consent-record Retention Window — Invariant 6) are the demonstrability surface; a withdrawn consent is retained as proof the basis once existed.
- **GDPR Article 7(3)** — withdrawal must be as easy as grant, and withdrawal does not affect the lawfulness of prior processing. [Withdraw Consent] is the recording surface; the data-subject-facing ease is upstream (Non-goal 6); non-retroactivity is inherited from Consent Invariant 9.
- **GDPR Article 17(1)(b)** — right to erasure when consent is withdrawn and no other basis applies. The `consent.withdrawal.revoked` event's `affected_scopes` is the notice that triggers downstream erasure obligations; this composition signals, the downstream processor erases (Non-goal 1).
- **GDPR Article 30** — records of processing activities must name purposes and legal bases. This composition's Consent records (purpose, `granted_at`) plus the `processing.registered` bindings supply the Article 30 documentation surface for consent-based processing.
- **CCPA / CPRA** (the California Consumer Privacy Act and its amending California Privacy Rights Act) — right to opt out of sale/sharing and opt in for sensitive personal information. This composition's [Record Consent] / [Withdraw Consent] are the opt-in/opt-out recording surfaces; the propagation event names the processors a do-not-sell signal must reach.
- **HIPAA section 164.508 (Authorization)** — required Authorization elements (purpose, expiration, right to revoke) map to the Consent record fields; this composition adds the operator-authority gate (Permissions) and the tamper-evident audit the regulated context requires.
- **ePrivacy Directive (Cookie Law)** — consent for non-essential cookies and tracking. A cookie-consent backend records grant/`revoke` through this composition; the `consent.withdrawal.revoked` propagation names the tracking systems that must stop.
- **ISO/IEC (International Organization for Standardization / International Electrotechnical Commission) 29184 (Online privacy notices and consent)** — consent record content and lifecycle. This composition's grant/registration/withdrawal records are the lifecycle artifacts the standard describes.

The four constituents carry their own deep standards inheritance — see each constituent's Standards references.

---

## Status

`done — 2026-11-11` — see the Ledger.

## Ledger

```
status: done — 2026-11-11
formal: verified — propagate-consent-revocation-downstream.tla + 22 twins + 15 reachability probes, re-derived 2026-11-10 over the split arc ([Record Consent] and [Withdraw Consent] each an open, a commit and a close; [Register Processing], the history read and the gate one transaction each), against Recoverable Invocation's contracts (the sweep's closing by this page's withdrawal and grant probes, the escalation, an operator's resolve unchecked against the records), with a write outside every invocation and the write-ownership leg; one model under TLC, 5,538,855 states (three invocations, two consents, two pairs, one direct write; two invocations hold at 140,285, and with a third pair at 1,852,805); Invariant 1.1, 1.3, 3.1 through 3.3 (over the invocation's and the sweep's events), 4.1, 5.1, 6.1, 7.1, 8.3, 8.4, Action wiring 24, Composition state 6 and 13, the owed outcome, the recovered set at the intent's position, the pairing datum's uniqueness (Capability requirement 37, 38), the write-ownership finding (Reconciliation 11, 16) and the false-closing alert (Reconciliation 40, 41), each broken by a twin alone; the reconciliation model and its twins retired to Recoverable Invocation (Invariant 2.1, 3.5, 3.6, 8.1, 8.2 inherited, Invariant 3.6 through Recoverable Invocation Invariant 5.1, 5.2, which Recoverable Invocation's model checks from v8); not modeled: Recoverable Invocation's mechanism and the clock (the young and aged record, the closure window, the sweep cadence, a commit landing after its invocation yielded), an operator's closing (Invariant 3.1 through 3.3 detected for it, not prevented: the model shows the second event reachable, Check 3.1, 3.2 and 3.10 find it), nows shared across act keys or with a write outside every invocation, the pre-commit arms other than already-granted and already-revoked, and a fourth invocation (not run: past the audit's 15-minute limit); propagate-consent-revocation-downstream.als + 15 twins (the static data model, 2026-11-12: Invariant 1.1, 3.1 through 3.3, 4.1, 5.1, 6.1, 7.1, 7.2, 8.3 and 8.4 and Recoverable Invocation Invariant 5.3 as this page's probes bind it, checked on every state of the Consent records, the consent retentions, the grant and withdrawal intents and what closed each, the registration events in the Event Log's order with the purged ones, the bindings, the subject index, the gate's answers and the history reads, at for 3 with two of each reference; nothing testable in Alloy for Invariant 1.3 (the consent check at the grant's commit, a sequence: the TLA+ model's) and 6.3 (no action, record or answer of the page reads a consent retention's proof-period end); the model found that a write outside every invocation at an open grant intent's subject reference, purpose, grantor and pairing datum is the grant probe's one match, so the sweep recovers a grant event for it carrying no retention id, where Action wiring 17 has every grant event carry one and no rule names that answer, and that Invariant 6.3 constrains a read no action makes); coverage 2026-11-10, 2026-11-12: owed rows: Action wiring 31 with Reconciliation 22, 23; Reconciliation 2, 4, 39; Reconciliation 38, 2026-11-12
last gate: 2026-11-11 — Final Critique 24, a delta round, frozen at 79168ca — foundational count 0 after the blind second triage, clean, one sample (Linus's one report claimed four, two refuted and two placed refining: the placement's registry-unavailable "without a rule" is refuted by Recoverable Invocation commit 2 and 3, which Term commit partition's pre-commit arm and Action wiring 8 invoke, and the closure row already lands it refused; the administration completion bound "owed to span the settling period" is refuted by Recoverable Invocation yield 1 and 4, the yield writing nothing and returning at once with the record the sweep's; a re-registration that cannot restore a purged pair is kept open as line 2026-11-11-c, every build doing the same; Composes 7 against Term transitive atoms, which names Lease, cured to the form the sibling compositions use); refining cured (Term grant key reads two acts, repeatable being yes, as Recoverable Invocation's Term act key does; open line 2026-11-04-c cites Consent Operation 8, 9, the grant's clock-order refusals, where it cited the revoke's), refused (the refuses line's order, inert under Execution Contract Refusal 1), rhetorical accepted; 2026-11-11 — Final Critique 23, a full round, frozen at ff40a14 — foundational count 3 (the two refuse lists of [Record Consent] and [Withdraw Consent] omitted already-accounted, which Action wiring 61 and the Closure table's refuse row land from Recoverable Invocation's refuse: cured, the code added to both signature blocks; Term write-ownership finding read "no intent carries" while Reconciliation 11 and 16 each open the finding for the record of one act, so a revoked record carried only by its grant intent met Check 3.4's write-ownership member by the rule and not by the term: cured, the term naming the two rules that open it, which closes open line 2026-11-11-a; Term maximal envelope sized the outcome without the consent id and the retention id it carries, so one build started and another refused to: cured, the ids sized at a new deployment-set id width, Capability requirement 13), not clean, no sample; refining cured (the Closure table's log-read row owns the registered set's count, and its open row names recording-failure(outcome); Term commit partition names state-unavailable on the grant kind, as the withdrawal's does); the registered set's count on the index (Term registered set already counts the registration events), the cross-check's disagreement (Composition state 11 forbids the enumeration's adoption, Execution Contract Derived index 1 has the action decide on the rebuilt entry), a deployment's removal of a consent retention after the audit horizon (Invariant 6.1 and the Decisions entry of 2026-08-27 keep it Retained for life, Scott 2026-11-10), the purged index entries' durability (Execution Contract Database 3, Composition state 13, 14), the expiry's validation at the seam (Consent owns it, Consent Operation 24, 25) and the event id width's owner (Capability requirement 13, the deployment) refuted or placed refining on text the page cites; open lines 2026-11-04-a, 2026-11-04-b, 2026-11-04-c re-found; Final Critique 22, a delta round, frozen at 83b9f8b — foundational count 1 (Check 3.4 resolved a revoked record to EXACTLY ONE OF six members, and an aged record whose withdrawal the sweep escalated and whose `consent.withdrawal.escalated` event the audit horizon later destroyed met both propagation history purged, which a surviving escalated record would exclude, and an escalated withdrawal, which Term escalated withdrawal words as a fact: cured, the escalated member made other than propagation history purged, so the record answers the purged member alone; the blind second triage placed it, the first triage having refuted the trace the finder wrote on Term propagation history purged), not clean, no sample; Linus, the round's one report, claimed one foundational, two refining and one rhetorical: the finder's own trace and the member 2 and 5 collision refuted on text the page cites (Term propagation history purged, Term unpropagated record, Term write-ownership finding), refining cured (Capability requirement 31 reads the governed consent in Granted at the instant the activity processes, so a registration against a consent re-granted since does not meet it) and kept open (open line 2026-11-11-a: Term write-ownership finding names no act), rhetorical accepted (Non-goal 12's owner stands in the Non-goals NOTE with the owners of Non-goal 4, 5, 6, 8 and 9); 2026-11-10 — Final Critique 21, a delta round, frozen at e8100a9 — foundational count 1 (Capability requirement 31 required "the activity's registration event" without saying which consent it carries, so after a re-grant a registration against the withdrawn consent met it and the new consent's `affected_scopes` omitted a scope that processed on it: cured, the registration event carries the consent id of the governed consent in Granted for the subject reference and purpose the activity processes under), not clean, no sample; Linus, the round's one report, claimed five: three refuted on text the page cites (the grant instant equals the pairing datum by Capability requirement 37, Term grant instant and Term consent bindings; two concurrent grants for one pair meet act-in-flight at the open by Recoverable Invocation open step 1.7 and 3.5, then already-granted by Action wiring 7 and 8; `affected_scopes` is bounded by the registrations cap, Primitive policy 6, Capability requirement 13 and 14, and sized at the open by Recoverable Invocation Primitive policy 12 and 13), one placed refining and cured (a gate answer's freshness at the act is each processing system's: Non-goal 12), Reconciliation 6 pointed at its key, Reconciliation 11; 2026-11-10 — Final Critique 20, a delta round, frozen at a71cff3 — foundational count 1 (Reconciliation 11 and 16 read an intent the audit horizon destroyed as no intent, so every aged Consent record opened a write-ownership finding: Reconciliation 4 now excludes an aged record as well as a young one, the reconciliation's upper edge, under pressure-testing.md *A reconciliation is bounded at both ends*; open line 2026-11-10-c closed), not clean, no sample; Linus, the round's one report, claimed five: four refuted or known (a registration landing between the intent and the revoke lies outside the set by Cross-record consistency 3, Term propagation set and Invariant 3.3; the gate's failed read answers state-unavailable by Execution Contract Read 1 through 3 and Constituent failure 3; an over-cap metadata refuses invalid-request at the open with nothing written by Recoverable Invocation Primitive policy 12, Primitive policy 13 and Action wiring 61; the maximal envelope's ids are open line 2026-11-09-b, re-found), refining cured (the Summary's claim of reading Consent directly and its "without qualification", the closing paragraph and the walkthrough's enumeration scoped to the scopes registered before the intent, Term metadata naming the payload cap, open line 2026-11-10-d closed); 2026-11-10 — Final Critique 19, a full round, frozen at 2ea5e6e — foundational count 1 (Check 2.2 and Check 3.4 resolved a record to EXACTLY ONE OF members that overlap on lawful states: cured, the members made disjoint inside the checks), not clean, no sample; the three readers reported 13 foundational, 12 distinct: five refuted on text the page cites (the consent check's instant by Execution Contract Logic confinement 11; a blank actor by Execution Contract Refusal 1; an unrecovered withdrawal by Recoverable Invocation Invariant 4.9, whose sweep escalates; a late already-expired refusal by Action wiring 36 and Non-goal 5; the retention floor against the 2026-08-27 Decision, put to Scott as open line 2026-11-10-b), four were open lines re-found (2026-11-04-a, -b, -c and 2026-11-09-b), and two refining (Primitive policy 5 cured, the envelope's ids kept open); refining cured or kept open (the Summary's gap clause scoped to a committed revoke, Term validated withdrawal, the closure table's first row, the NOTE of line 2026-11-04-c, the ePrivacy Directive expanded; open lines 2026-11-10-b to -d); 2026-11-09 — Final Critique 18, a delta round, frozen at c0f7c2a — foundational count 0 (Linus claimed 3: all refuted on text the page cites — Term unpropagated record, Term ungranted record and Term orphan exclude an aged record from Reconciliation 29 and 30; Execution Contract Database 1, Read 4 and Constituent failure 1 leave nothing committed by a crash before the retention placement; Database 1 and 2 keep a revoked record unread until its propagation event commits with it), refining cured or kept open (Invariant 3.4 deleted to Reconciliation 36 under Standard label 14; Term propagation set and Term escalation reach restated; open lines 2026-11-09-e and -f extended), clean, one sample, the blind second triage agreeing on all three and placing one standing open line (2026-11-09-f) foundational, which the settle placed refining against Audit Trail's kept refusal evidence; 2026-11-09 — Final Critique 17, a delta round, frozen at aea99e2 — foundational count 2, all cured, not clean, no sample; 2026-11-09 — Final Critique 16, a delta round, frozen at fa8b27b — foundational count 4, all cured, not clean, no sample; 2026-11-09 — Final Critique 15, a full round, frozen at 887b20e — foundational count 4 and one more the formal-layer unit found, all cured, not clean, no sample; 2026-11-06 — Final Critique 14, a delta round, frozen at 85bc8fe — foundational count 0, clean, one sample; 2026-11-06 — Final Critique 13 — delta, foundational count 1, not clean, no sample

open:
- 2026-11-04-a · refining · Capability requirement 4, Action wiring 13, 14 · no rule refuses a consent retention whose period exceeds the audit horizon at the placement, and Check 7.1 finds the breach only after the record stands → name the refusal the placement lands among the Action wiring, or name the policy registry the owner (External check 5); re-found by Final Critique 15, 19 and 23
- 2026-11-04-b · refining · Composition state 12 · a rebuild reads the enumeration of Consent's records as a cross-check, and no rule says what the composition does where the enumeration and the log disagree → name the finding the disagreement opens; re-found by Final Critique 15, 19 and 23
- 2026-11-04-c · refining · Action wiring 12 · a bare invalid-request lands after the grant intent committed, so a caller cannot tell a malformed input from a clock-order refusal on the grant side (Consent Operation 8, 9) → name the refusal's constituent code, which the invocation's refuse records; re-found by Final Critique 19, 23 and 24
- 2026-11-09-b · refining · Term maximal envelope · the envelope names the fixed fields and enumerates none of them (the ids and the event id width are sized, Final Critique 23) → list the fixed fields the substrate sizes; re-found by Final Critique 19, 20 and 23
- 2026-11-10-a · refining · Composition notes; Term grant transaction · Recoverable Invocation's bound commit is one constituent call and the grant kind's is three in one database transaction, a case Recoverable Invocation's closed deviation list does not name (Recoverable Invocation Deviation 2) → carry to Recoverable Invocation's next revision as evidence, or declare it there
- 2026-11-11-b · refining · Check 4.2, Check 3.3 · Check 4.2 compares the event's surviving sequence number with the event's boundary and states no conclusion, so no deployment can fail it, and Check 3.3 cites Invariant 5.1 where Check 2.3 cites Invariant 2.2 for a propagation event's passing verification → state the conclusion, and cite the invariant that answers the verification; found by Final Critique 23's GRID pass
- 2026-11-11-c · refining · Composition state 5, Action wiring 22, Term live index entry · a repeat registration of a pair whose first registration event the audit horizon destroyed changes no binding (Composition state 5), so the pair classifies purged and extraction-pending against Processing Register (Composition state 16) while an equal pair whose first event stands classifies live; every build does the same and no check fails, so the cure is a decision, not a gap → decide whether a later registration event the record read answers Retained re-binds a purged pair (an exception in Composition state 5 and a reading in Term live index entry, a cure whose reach is every rule that cites the term), or record the debt as a deployment obligation; found by Final Critique 24's Linus pass, placed refining by both triages
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/propagate-consent-revocation-downstream.md`; the migration that got it here is in [its history](./propagate-consent-revocation-downstream.hist.md).

- **2026-11-10 — The wait retired: grant and withdrawal are two Recoverable Invocation act kinds.** *Chose:* (Scott, 2026-11-09 9:17 PM Central, "A", and 2026-11-10 7:15 AM Central, the wait ruling, "simple DRY"; the map's D1 through D7 settled under A, 2026-11-10 7:55 AM Central) [Record Consent] and [Withdraw Consent] each bind one act kind, consent.grant keyed by the subject reference with the purpose and consent.withdrawal keyed by the consent id, with the grant transaction and the revoke write as their bound commits; the revoke and the propagation event no longer commit together, the propagation event being the invocation's close, so a withdrawal that crashes between them leaves a Revoked record with an open intent the sweep closes (D1); the grant's pairing datum the invocation's now, injected at Consent's seam, so a grant whose reply was lost closes automatically (D2, Capability requirement 37, 38); the propagation set bounded at the withdrawal intent, a registration landing between the intent and the revoke omitted and named as a window (D3, Cross-record consistency 3); already-granted, already-revoked and already-expired moved from answers to refusals with a refusal record, a Consent or placement storage failure the constituent's own code, and Recoverable Invocation's codes added (D4); an operator's closing of an act detected, not prevented (D5, Invariant 3.1 and 3.2, Check 3.1 and 3.10), with the false-closing alert in the sweep's leg (Reconciliation 40, 41); the events renamed consent.grant.granted and consent.withdrawal.revoked (D6); a Consent record no grant intent carries a write-ownership finding in place of an escalation (D7); the withdrawal repeatable, the grant transaction one commit on External Onboarding's precedent, and the leg on Recoverable Invocation's cadence and run (G9 through G11); Reconciliation 1, 3, 5, 7 through 10, 12 through 14, 17 through 21 and 24 through 37 tombstoned to what owns them, 2, 4, 6, 11, 15, 16, 22 and 23 kept or restated and 38 through 41 new, and Invariant 2.1, 3.4 through 3.6, 6.2, 8.1 and 8.2 tombstoned. *Over:* removing the wait by reversing 2026-11-04, which would let an Audit Trail fault block a withdrawal, and keeping the page's own reconciliation beside Recoverable Invocation, which would have covered the intent-and-outcome pairing twice. *Because:* the wait was self-made: the 2026-11-04 decision left a committed Consent record with its outcome owed so an audit fault never blocked a withdrawal, and the page then built the pairing, the compensation, the recovery identity and the escalation to close it, which Recoverable Invocation owns. *Costs:* a Lease host, the instance's bounds and a sweep; every caller-visible code of both actions that named an outcome or a Consent refusal changes; Invariant 3.1 and 3.2 fall from prevented to detected against an operator's resolve; the propagation set no longer names a registration made in the window between an intent and its revoke; the grant's pairing rests on a deployment obligation on Consent's seam.
- **2026-10-21 — The consent lifecycle reads as provable.** *Chose:* *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where the page wrote *from the records alone*, *records-alone* or their like: Invariant 5.1, under which every governed consent's lifecycle resolves provably from the Consent records, the Audit Trail instance and the indexes, with Invariant 5's heading, and, by wording alone, the Summary, the Wiring decision's principle, the invariants' closing paragraph, the DSAR and regulator examples, the acceptance bar, the [Affected Scopes] term entry and the Article 6(1)(a) standard; every *grant* on the page names a consent grant, a live authorization a withdrawal ends, so none changed; rules 233 to 233. *Over:* the phrase restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Invariant 5.1 changed and no obligation did.
- **2026-11-04 — A recording failure at an outcome is answered, not refused, so the Consent record it follows stays committed.** *Chose:* [Record Consent] and [Withdraw Consent] answering recording-failure carrying outcome beside the consent id and withdrawn, and refusing only recording-failure carrying intent, so a call whose grant event or propagation event Audit Trail refuses is admitted and its writes commit together, its Consent write among them (Execution Contract Database 1), the outcome owed to the reconciliation (Audit arm 12, 15, 17, Term position, Reconciliation 9 through 17, 24 through 27). *Over:* recording-failure carrying outcome on the refuses line, read as a committed Consent record while Execution Contract Read 4 has a refused call write nothing (open line 2026-10-30-a), and landing it carrying intent, which would have rolled the grant or the revoke back and left a caller's withdrawal lost. *Because:* the ruling of 2026-10-31 16:48Z answered the (b) shape for this page: keep, in the form Authenticated Actor and Login took, the outcome answered so Read 4 holds as written.
- **2026-10-21 — The store's guarantees cited, not restated, and a withdrawal's revoke and its propagation event one transaction.** *Chose:* Capability requirement 32 citing Execution Contract Store 1 through 4 for the store the Consent, Permissions, consent retention and Audit Trail instances and the three indexes keep their records in; to Store 3, the indexes' persistence and the index durability held at the Consent store's (Composition state 15, Capability requirement 24, 25); to Store 2, under which an action's reads and the writes they decide are one transaction, the consent exclusion and the pair exclusion with their supply, holding, release and lease and the refusal to run without them, every take of them, an invocation's release of them and the expiry of its lease, the reconciliation's take of the consent exclusion and its skip of a held record, and the bar on [Processing Permitted] taking one (Capability requirement 16 through 22, Action wiring 6, 20, 27, 45 through 47, Reconciliation 7, 8, Concurrency 1 through 4); to Store 1, under which an action's writes commit together, its constituents' included, the rule denying that the revoke and the propagation event form one atomic set, which Store 1 as ruled contradicts (Wiring decision 2), and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the outcome retry attempts with the retry span the administration completion bound had to cover, the in-invocation retries of an outcome with their pre-check and adoption, the proceed-as-landed reading of a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing, the outcome position for a placement's storage failure, the consent exclusion a grant took only to keep the reconciliation off it, the reconciliation's run at every process start and its lower edge, and the placement re-run for a Granted record whose placement was refused, with the rule holding a compensating grant event behind it (Capability requirement 11, 12, Audit arm 5, 10, 11, Action wiring 15, 16, 43, 44, Reconciliation 1, 3, 18, 19). By clause, the consent check, the grant write, the derivation and the binding repair no longer name an exclusion (Action wiring 7, 9, 28, Reconciliation 22), and a recording-failure at an outcome's pre-append step lands as recording-failure carrying outcome with no retry ahead of it (Audit arm 12). Rules 268 to 233. *Over:* a revoke and a propagation event no transaction could span, ordered instead, with a consent exclusion and a pair exclusion the host held across an invocation's retries as a lease, and a reconciliation bounded below that compensated what a crash between the writes left — the turns of 2026-08-27 and 2026-08-30, below. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, that a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal, and that Store 2 covers a guard decided across a lease check, the lease keeping its job only for an act outside the store. The revoke and the propagation event are store writes, Consent and Audit Trail each supplying theirs under Store 1 through 4, and downstream cessation is Non-goal 1, so the composition makes no act outside the store: a withdrawal's intent, revoke and propagation event commit together, as a grant's intent, grant write, placement and grant event do, and the two exclusions, host mutual exclusions over store-only work, are Store 2's. A placement refused after the grant write is refused and writes nothing (Execution Contract Read 4), so no Granted record waits unretained for a re-run. An Audit Trail refusal of an outcome still leaves the Consent record committed and its event owed (Audit arm 12, 15, 17), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the pairing on both sides with its candidates, the re-derived set, the pre-check, the recovery identity behind a recovery intent, the recovery flag, the compensation window, the cadence, the outcome write latency and the liveness sum the window must exceed, and the escalation (Capability requirement 6 through 8, 10, 23, Reconciliation 9 through 17, 20, 21, 24 through 35, Invariant 3.5, 3.6, Check 3.5, 3.6, 3.8, 6.4); the administration completion bound stays with them, since the liveness sum, the grant pairing window and the surfacing bound still read it (Capability requirement 9). Audit Trail's evidence rule leaves an invalid-request at its retention step with the event appended, so that answer still proceeds as landed, with the alert (Audit arm 6, 16). The three indexes stay derived indexes outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps them, so an index entry still follows the event it derives from and a lost binding is still repaired (Action wiring 24, 25, 31, Reconciliation 20, 22, 23). The propagation set's boundary and the order of an intent and its outcome are the Event Log's own sequence numbers (Clock semantics 1), and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.
- **2026-08-30 — One Granted record per pair, one writer per act, the set derived from the events, the escalation a record, the pairing honest about whose clock stamped each side.** *Chose:* single-active-grant enforced at [Record Consent] step 4 by `Consent.check` under a per-`(subject_ref, purpose)` section, refusing already-granted, stated as Invariant 1(c) and tested by check 4, with the suppression claim made conditional on it; an in-invocation retry bounded by `outcome_retry_attempts` and a scan that takes the per-consent_id section for every consent it touches, so the invocation and the scan never both land a propagation event; `affected_scopes` derived at [Withdraw Consent] step 4 from the `processing.registered` events (the map supplying only its past-horizon entries) with a third scan leg repairing lost bindings; the grant-side scan pairing by actor, subject and purpose inside a symmetric window under a declared `clock_offset_allowance`, narrowing to candidates and escalating a zero-match as an unresolved grant orphan rather than concluding a bypass; check 6's case (v) requiring a *paired* intent, exact by pass-through, so a zero-match on the withdrawal side is the bypass signature; `consent.propagation_escalated` as composition-written audit content under the service identity, carrying the observed cause, in place of "an open compliance finding"; `registrations_cap`, `field_length_cap` and `intent_candidates_cap` with an envelope inequality checked at instance start, the digest withdrawn; the liveness inequality written out with `outcome_write_latency`; `recording-failure(intent | outcome)` on the two signatures that straddle a commit; "atomically" and "together or not at all" replaced at every site by revoke-then-event, ordered, bijective at quiescence modulo compensation; the log read declared once as the substrate's sequence-range read filtered composition-side; the purged answer counted as consistent ahead of any composition-side comparison; and `consent_to_downstream`'s past-horizon half re-homed from Erasure Tombstone to a Processing Register atom *(forthcoming)*, the two key-shaped maps staying with the tombstone; at the closure check, each map element carrying its registration `event_id` so that *past the horizon* is decided by `read_record` answering Purged and never by a timestamp, with check 3 carved out for a purged registration whose surviving `sequence_number` still precedes the boundary; checks 1 and 7 reading `kind: grant` escalations as escalated orphans, never as bypasses; `event_id_width` declared rather than attributed to the substrate; `per_key_serialization` declared as the instance capability the sections rest on, with lease semantics — a lease exactly `administration_completion_bound` long whose expiry is the invocation's terminus, the invocation re-taking the section before any pre-check and writing nothing after it has yielded — and `outcome_retry_attempts × outcome_write_latency ≤ administration_completion_bound` so the counted terminus fits the bound; and the scan's tie-break withdrawn for candidates never chosen. *Over:* a gate keyed per pair over a propagation keyed per consent_id with nothing holding the two to one record; "retry until it lands" beside a scan starting at the bound; a map read as gate input with "rebuild where its integrity is in doubt"; a bypass verdict landed on a comparison of two seams' stamps; an intent's existence standing in for its pairing; an escape branch living in no store; a digest no consumer can read; a bare token on both sides of the commit; atomicity language over two irreversible writes; a tombstone asked to carry a register; a past-horizon membership with no clock-free test; an escalation with no reader; a critical section attributed to the host and named nowhere, and a lost lease that could resume between a scan's look and its append. *Because:* Consent evaluates the latest grant and declines uniqueness for itself, so a composition that keys its two halves differently must supply it or contradict its own suppression claim; two compensators over one act land two outcomes the seal then protects; a short list is not an observable miss; a stamp another seam wrote can differ from this one's by a sign the bound does not have; a check that cannot see the escalation cannot count it; a set that only grows has no unreachable cap; a caller who cannot tell intent from outcome re-runs a committed act; a retention state is the substrate's to answer and a timestamp is not that answer; and a section nobody declared, with a lease nobody bounded, is a second writer waiting for a stall (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen with its tells for uses — with §*A derived index is trustworthy only where a miss is observable*, §*Intents pair with outcomes*, §*Recovery commits under a declared service identity* and §*A derived index splits at the horizon*).
- **2026-08-29 — The scan is bounded at both edges, writes as the composition, and pairs by the records; the indexes are truth-bearing past the horizon.** *Chose:* a declared `administration_completion_bound` below which the reconciliation scan and checks 1 and 7 examine nothing, with the audit horizon as their upper edge; every compensating write attested under a declared service identity behind a `consent.recovery_intended` record, the operator carried in `data`, the intent paired on `intended_at = revoked_at` and `actor_ref = revoked_by` (candidates named where undecidable); both grant-side orphan shapes resolved, the unretained one by re-running the placement from the intent's own retention_policy_ref; every `record_action` transcription carrying `(step)`, the `step-4` arm proceeding as landed and invalid-request never unreachable; and each index's past-horizon half classified truth-bearing under a declared `index_durability`, extraction-pending against Erasure Tombstone. *Over:* an unbounded scan attesting compensations as the absent operator, and "the map is not rebuildable" as the last word on the horizon. *Because:* an unbounded scan compensates in-flight withdrawals beside their own propagation events and reads lawfully purged history as orphans; a compensation the operator did not make cannot be attested as theirs; and a consent record outlives any audit horizon by Consent's own Invariant 8, so the only thing that keeps an old consent withdrawable is the index entry, which must therefore be declared for what it is (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*, *A transcribed rejection arm keeps its payload*, *A derived index splits at the horizon*).
- **2026-08-27 — Authentication happens at this composition's boundary, before the consent state changes.** *Chose:* [Record Consent] and [Withdraw Consent] open with an intent record whose substrate attestation verifies the credential; invalid-credential is a clean pre-state refusal. *Over:* the Action wiring preamble's declaration that the check "cannot be pre-empted at this composition's boundary" and belongs to a deployment pre-check. *Because:* the declaration was false — the composition reaches the same Actor Identity surface at whatever point it chooses to write — and a declared deployment obligation is the answer the methodology refuses.
- **2026-08-27 — Invariant 3 is safety plus liveness, with the propagation-set boundary on the intent event.** *Chose:* the revoke precedes the propagation event; the reachable partial (Revoked, unpropagated) is an accountability gap surfaced and compensated within `compensation_window`; check 2's set boundary is the withdrawal's own `consent.withdrawal.intended` event. *Over:* "commit together or not at all" under a host transaction. *Because:* Consent's revocation is immutable once committed and the substrate's append cannot be withdrawn, so neither member was ever enlistable; what makes the pair sound is the order.
- **2026-08-27 — A consent record is never destroyed by this composition; its retention is Retained for life.** *Chose:* the consent-record Retention Window instance marks the proof-period floor and never reaches `Purged`; check 5 requires `Retained` unconditionally. *Over:* letting the retention reach `Purged` once the audit horizon has run past the record's outcome. *Because:* a consent record is the proof of a grant and of a withdrawal, and this composition has no obligation whose act is to destroy it; Scott ruled it kept on 2026-11-10 ("keep it. why not?"), after the round found the first reasons (Consent's Invariant 8 read against a composition, Retention Window's `Purged` as Consent's forbidden destruction) no longer hold. Where a record's lawful destruction comes, its owner is Defensible Retention, not this composition (Scott, 2026-11-01).

</details>

NOTE: End of Propagate Consent Revocation Downstream.
