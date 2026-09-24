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

The composition's defining emergent guarantee (a property that appears only when atoms are combined — no single atom carries it) has two halves. *Consent-gates-processing:* a single read-only query, `processing_permitted(subject_ref, purpose)`, returns permitted if and only if Consent reports valid consent (`check` → granted) for that subject and purpose at the current time. Processing systems consume this query rather than reading Consent directly, so the gate is implemented exactly once instead of re-implemented — or skipped — per processing system. *Revocation propagates:* [Withdraw Consent] revokes the consent and then records a `consent.revoked` Audit Trail event whose `affected_scopes` set is exactly the downstream processing scopes registered against that consent. These two writes cannot be made one — neither can be taken back once made, so no transaction spans them — so they are **ordered** instead: the revoke first, the propagation event second. That ordering gives the guarantee an auditor needs without qualification, since a propagation record always has a real revocation behind it, and it leaves exactly one gap — a revocation whose propagation record has not yet landed — which is always visible, always repaired within a declared window, and never a processing-suppression gap, because the gate reads the consent store directly and is honest the instant the revoke commits — given the single-active-grant rule [Record Consent] enforces (Invariant 1.3), which is what makes the record revoked the record the gate evaluates for its subject and purpose.

Beyond the gate and the propagation, the composition guarantees that every consent grant is attributed and tamper-evidently recorded, that consent records are held under a retention floor that survives revocation (a withdrawn consent is evidence, not garbage — it must outlive its own withdrawal for the regulator's proof period), that the complete consent lifecycle is reconstructable from the records alone, and that every consent-administration action passes a Permissions check before it touches the consent store.

 Its most common uses are advertising and marketing consent management under GDPR (the EU General Data Protection Regulation)/ePrivacy, health-app and research consent under HIPAA (the US Health Insurance Portability and Accountability Act) Authorization, cookie-consent backends under the ePrivacy Directive, and any system that must prove, from records alone, that consent-based processing was gated on valid consent and that every withdrawal's downstream impact was enumerated and sealed.

---

## Intent

Every system that processes personal data on the basis of consent faces the same regulated obligation, and it is the same whether the system is an advertising platform, a health app, an analytics pipeline, or a cookie-banner backend. Before processing for a consent-based purpose, the system must confirm a valid consent exists; the data subject must be able to withdraw that consent as easily as they gave it; and — the limb that defeats most real deployments — when consent is withdrawn, the systems that were relying on it must *stop*, which means the withdrawal cannot be a private fact buried in one consent store but must propagate to every downstream process that was acting on the basis now gone. GDPR Article 6(1)(a) names consent as a lawful basis; Article 7 fixes its conditions (freely given, specific, informed, demonstrable); Article 7(3) requires withdrawal be as easy as grant and, read with Article 17(1)(b), that withdrawal end the basis for future processing. The domain varies; the structural obligation is constant: gate processing on consent, and make withdrawal propagate provably.

No constituent, alone, enforces this arc. Consent owns the grant/revoke/expire lifecycle and the `check` query that answers *is there valid consent for this subject and purpose at this time?* — but it deliberately stops there: its own specification states *"the atom does not enforce processing suppression"* and names downstream propagation as out of scope, for a composing layer to handle — this one. Consent records that consent was withdrawn; it neither knows what downstream processing relied on it nor records which processes must now cease. Permissions owns inward authorization — *which internal actor may grant, revoke, or read a consent record on a data subject's behalf* — but it knows nothing of consent state. The Audit Trail substrate records attributed, tamper-evident, retention-bounded events but does not know which events constitute a consent's propagation history. The consent-record Retention Window instance holds each consent record for its proof period but knows nothing of consent semantics. The structure that makes the four coherent as a single consent-management surface — the gate that centralizes the consent precondition, the downstream-registration index that makes "what relied on this consent" a recorded fact, and the propagation event that follows revocation in a fixed order — belongs to no single constituent. It belongs to the composition, and this composition is that structure.

This is a composition, not a new primitive. Consent, Permissions, Audit Trail, and Retention Window are unchanged; the composition is the wiring that makes them coherent as a single consent-management surface. It introduces emergent actions — [Record Consent], [Register Processing], [Withdraw Consent], [Read Consent History], [Processing Permitted] — that belong to no single constituent and exist only because the constituents are wired together. The [Withdraw Consent] action, in particular, wraps a Consent `revoke`, an enumeration of the consent's registered downstream scopes, and the tamper-evident propagation event into one named surface, ordered revoke-then-event, so that withdrawing consent is one auditable act whose downstream impact is recorded — not a Consent `revoke` whose consequences leak silently into whatever processing systems happen to re-check, or fail to re-check, the consent store.

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

WHY:
**Consent owns the lifecycle and declines the rest by name.** Its specification states it does not enforce processing suppression, sends downstream propagation to a composing layer, and leaves single-active-grant — one Granted record per subject and purpose — to *the composing layer, not within this atom*. This composition is that layer for all three: the gate, the propagation and the uniqueness (Invariant 1 and 3). **Permissions is a peer made operational**: Consent is outward authorization, held by the data subject; Permissions is inward, held by the operator; the gate consults only the first and every administration action only the second (Invariant 7). **Audit Trail supplies attribution, seal and retention in one surface**, with Event Log, Actor Identity, Tamper Evidence and the audit-event Retention Window reached through it and never instanced here (Composes 7 and 8; the section titled Compositions of compositions in `spec-format.md`). **The consent retention instance is a second Retention Window**, over the consent records rather than the events (Retention asymmetry 1).

**The write surfaces are reserved** (Composes 11 through 14). A consent granted by a direct call passes the gate — the consent check knows the record — with no registration surface, no placement, no audit event and no withdrawal-with-propagation; a direct revoke is a withdrawal this composition never propagated. Reserving both writes and the namespace makes either a deployment's conformance failure, and the records report it as one: a revoke no withdrawal intent pairs is a write-ownership finding, never compensated (Reconciliation 11 and 12), and a grant no intent pairs is reported by Check 2.2. **Reads are reserved too, by route**: the consent check reaches processing systems only through [Processing Permitted] (Invariant 1.2), and the consent read reaches operators only through [Read Consent History], which gates it and records the access; the reconciliation's reads are the composition's own.

**The log read is declared, not assumed** (Composes 9 and 10). The rebuilds, the set derivation, the pre-checks, the reconciliation and the checks select by action reference and payload field, and the substrate serves no such read: Audit Trail passes a sequence-range read through to Event Log and routes every query by payload field to a Reverse Index pattern *(forthcoming)* it does not absorb. So the route is the pass-through range read with the selection in composition code; a deployment composing Reverse Index may accelerate it.

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
Composition state 11: The composition MUST NOT rebuild an index entry from a constituent store.
Composition state 12: The composition MUST read a constituent store's enumeration ONLY as a cross-check against a rebuild.
Composition state 13: The composition MUST classify a purged index entry as truth-bearing.
Composition state 14: A rebuild MUST NOT remove a purged index entry.
Composition state 15: The deployment MUST persist the indexes PER the index durability.
Composition state 16: The composition MUST classify a purged downstream entry as extraction-pending against Processing Register.
Composition state 17: The composition MUST classify a purged key entry as extraction-pending against Erasure Tombstone.
Composition state 18: The composition MUST decide a downstream entry's horizon by the record read on the entry's registration event.
Composition state 19: The composition MUST NOT decide a downstream entry's horizon by an instant.
Composition state 20: The composition MUST NOT store a consent validity flag.
Composition state 21: The composition MUST NOT duplicate a constituent's store.
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

WHY:
**Three indexes, each derived from the substrate and keyed by the consent id** (Composition state 1 through 12; the section titled Composition state in `execution-contract.md`). None holds truth the constituents lack while its source events retain their payloads: each sits outside the actions' atomicity surface, a missing entry is a rebuild trigger and not data loss, and none claims cross-constituent consistency. The downstream index is the auditor's first surface for *what must stop when this consent is withdrawn*: a binding is never pruned (Composition state 6), so a withdrawal enumerates everything the consent ever governed, not what was active at some moment; a repeat registration records its own event and leaves the binding's first instant and event id alone (Composition state 4 and 5). The subject index lets [Withdraw Consent], which takes a consent id, name the subject and purpose on the propagation event without a Consent read.

**The only rebuild source is the audit traversal, and the fallback is forbidden** (Composition state 11 and 12). Enumerating the Consent store or the consent retention instance and re-keying would resolve exactly the consent id a direct write or an unrecovered grant orphan created — handing it the registration and withdrawal surfaces that audit-first resolvability denies it (Action wiring 24). The disagreement between the traversal and the store's enumeration *is* the orphan-and-bypass detector, so the store is read only to cross-check. Elsewhere in the corpus a payload-sourced rebuild falls back to a second declared source past the horizon — [Defensible Retention](./defensible-retention.md)'s rebuild falls back to Retention Window's own records, which over-includes and so can only refuse a purge. **Here the fallback exists and would delete a security property**, so it is closed.

**The classification splits at the horizon, and the purged half is truth-bearing** (Composition state 13 through 19; the section titled *A derived index splits at the horizon* in `pressure-testing.md`). A lawful purge destroys an event's payload whole, leaving its event id, sequence number and recording instant and, through the destruction record, its action reference and actor. A purged registration is still *identifiable*; what it registered is gone, and no second source holds it — the pair is a composition-introduced registry. Consent's Invariant 8 keeps every consent record for the life of the store, so every long-lived consent eventually outlives the horizon of its own grant event, and past that point the index entry is the **only** carrier of how the consent was keyed. A lost subject entry there is not a rebuild trigger but an un-withdrawable consent — the Article 7(3) failure Capability requirement 4 exists to prevent. **Two atoms, because two kinds of fact** (Composition state 16 and 17): the key entries record how a destroyed record was keyed, the class an Erasure Tombstone *(forthcoming)* is named for; the downstream entry records content — a live register of what processes on which basis — which a tombstone records the destruction of and does not carry, so its home is a Processing Register *(forthcoming)*, the records-of-processing-activities register GDPR Article 30 requires. Until either lands the durability is the deployment's. **A downstream entry's horizon is the substrate's answer, never a timestamp** (Composition state 18 and 19): each binding carries its registration event id for exactly this read; the key entries carry no event id, and are purged exactly when the grant rebuild stops reproducing them, which it never treats as a reason to drop them (Composition state 14).

**No stored validity** (Composition state 20): consent validity is a read-time projection the consent check produces when asked, so nothing at this layer can lag the clock — the discipline of Retention Window Invariant 11. The Consent, Permissions, consent retention and Audit Trail stores are their instances'; the composition indexes into them (Composition state 21).

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
Capability requirement 11: A deployment MUST set the outcome retry attempts.
Capability requirement 12: The composition MUST start ONLY IF the retry span DOES NOT EXCEED the administration completion bound.
Capability requirement 13: A deployment MUST set the field length cap, the registrations cap, the intent candidates cap AND the event id width.
Capability requirement 14: The composition MUST start ONLY IF the maximal envelope DOES NOT EXCEED Audit Trail's payload cap.
Capability requirement 15: A deployment MUST set the clock offset allowance.
Capability requirement 16: The host MUST supply the consent exclusion keyed by consent id.
Capability requirement 17: The host MUST supply the pair exclusion keyed by subject reference AND purpose.
Capability requirement 18: The host MUST release an exclusion on the holder's return.
Capability requirement 19: The host MUST release an exclusion on the holder's death.
Capability requirement 20: IF the host holds an exclusion as a lease THEN the host MUST set the lease length to the administration completion bound.
Capability requirement 21: The composition MUST read a lease's expiry as the holder's terminus.
Capability requirement 22: IF the host supplies no exclusion THEN the composition MUST NOT run a state-changing action.
Capability requirement 23: A deployment MUST provision the recovery identity.
Capability requirement 24: A deployment MUST declare the index durability.
Capability requirement 25: The index durability MUST NOT fall below the Consent store's durability.
Capability requirement 26: The wired Audit Trail instance MUST expose the log read.
Capability requirement 27: The host MUST inject now at the seam once per invocation.
Capability requirement 28: The composition MUST stamp EVERY instant one invocation writes from the invocation's now.
Capability requirement 29: The host MUST inject the reconciliation's now at the reconciliation's own seam.
Capability requirement 30: A deployment MUST expose [Processing Permitted] ONLY to processing systems.
Capability requirement 31: A processing activity MUST NOT process on a consent basis BEFORE the activity's registration event lands.
```

Term retention policy reference: the consent-record policy a caller passes to [Record Consent] — retention_policy_ref, required, resolved in Retention Window's Policy Registry; the deployment's recommended value is configured as `consent_record_retention_policy_ref`.

Term consent retention period: the duration a retention policy reference assigns a consent record.

Term audit retention policy: the retention policy configured on the composition's single Audit Trail instance, governing every audit event it records — `audit_trail_retention_policy`.

Term audit horizon: the audit retention policy's horizon.

Term regulated deployment: a deployment under a regime fixing a proof period — GDPR (the EU General Data Protection Regulation) Article 7(1)'s demonstrability burden, or HIPAA (the US Health Insurance Portability and Accountability Act)'s six-year Authorization retention.

Term compensation window: the duration within which an orphan must reach its closure — `compensation_window`. It is this composition's own, distinct from Audit Trail's compensation-window qualifier, which bounds the substrate's repair of its own retention arm.

Term reconciliation cadence: the interval between the reconciliation's runs, beside the run at every process start — `reconciliation_cadence`, this composition's own and distinct from any cadence the substrate runs.

Term outcome write latency: the deployment's disclosed bound on one audit write landing.

Term administration completion bound: the longest a [Record Consent] or [Withdraw Consent] invocation may run from its seam reading to its last audit write, retries included — the reconciliation's lower edge, the lease length and the invocation's timed terminus.

Term liveness sum: `administration completion bound + reconciliation cadence + outcome write latency`.

Term outcome retry attempts: how many times an invocation re-attempts an outcome refused at a pre-append step before the invocation yields the orphan — the counted terminus.

Term retry span: `outcome retry attempts × outcome write latency`.

Term field length cap: the byte length no payload string may exceed.

Term registrations cap: the most distinct pairs one consent may hold.

Term intent candidates cap: the most intent candidates one compensating event may name.

Term event id width: the widest event id the wired Audit Trail instance mints, which the substrate does not itself disclose.

Term maximal envelope: the largest compensating propagation event the composition could write — the registrations cap's pairs at the field length cap, the intent candidates cap's candidates at the event id width, every reference and the reason at the field length cap, and the fixed fields — serialized as the substrate sizes it.

Term clock offset allowance: the declared bound on the difference between the composition's seam clock and the clocks at Consent's seam and the substrate's.

Term consent exclusion: the host-supplied mutual exclusion on a consent id, under which every state-changing action on a known consent and the reconciliation's every write for the consent run — named with the pair exclusion as `per_key_serialization` in configuration.

Term pair exclusion: the host-supplied mutual exclusion on a subject reference and a purpose, under which [Record Consent] runs from the consent check through the grant write.

Term exclusion: the consent exclusion or the pair exclusion.

Term holder: an invocation or a reconciliation run holding an exclusion.

Term recovery identity: the composition's registered actor reference and credential — `application_actor_ref` and `application_credential` — under which the reconciliation attests every write it makes.

Term index durability: the durability the deployment owes the three indexes, stated as an ordering against the Consent store's.

Term processing system: a system that processes personal data on a consent basis.

Term processing activity: one downstream processing a processing system runs under a [Processing Scope].

Term seam: the composition's input and output boundary — the one place the host reads the clock, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam, once per invocation.

WHY:
**The retention policy reference is the caller's and required** (Capability requirement 1): the configured value is the deployment's recommendation, which a single-policy deployment passes on every call, never a fallback the action applies. Multi-jurisdiction reconciliation — the longer of competing obligations — is a Policy Reconciliation composing pattern's, whose output this composition consumes.

**The audit horizon outlasts every consent retention period, and it is an obligation with a named consequence** (Capability requirement 2 through 4). Audit Trail's audit write takes no per-call retention input, so every event inherits the instance's policy. All three indexes rebuild from event payloads only (Composition state 11), so past the horizon a grant event's payload is gone, the subject index cannot be rebuilt, and [Withdraw Consent] answers not-known for a consent that exists and is still Granted — **a live consent made un-withdrawable because the record of its grant aged out before the consent's proof period did**, a GDPR Article 7(3) failure reached with no partial failure, bypass or bug. Litigation defensibility is a second, independent reason for the same ordering. It cannot reach past the consent record itself, which Consent keeps for the life of the store; past that point the index durability answers (Capability requirement 24 and 25).

**Liveness is arithmetic** (Capability requirement 6 through 12; the section titled *Liveness is arithmetic* in `pressure-testing.md`). An orphan created at *t* is invisible to the reconciliation until `t + bound`, the next run is at most a cadence later, and its compensation lands a latency after that — so the window must strictly exceed the sum, and *cadence no longer than the window* is satisfied by a deployment that breaches on every orphan. The invocation samples no clock after its seam, so its terminus is counted, and the count fits inside the bound by construction (Capability requirement 12): an invocation still retrying is still inside the bound, and the reconciliation never races a live writer. No default is prescribed for the window: under GDPR Article 7(3) how long the *record* of a withdrawal may lag is a compliance determination — the lag is never a processing-suppression gap, since the gate reads Consent.

**The caps size the largest record, not the intent** (Capability requirement 13 and 14; the section titled *An outcome is sized before the intent* in `pressure-testing.md`). The propagation set only grows for a consent that is never pruned, so without the registrations cap it has no upper bound and the claim that the substrate's payload cap is unreachable is false. The event id width is a deployment knob of the same shape as the substrate's attestation id width, since the substrate does not disclose its own. A deployment whose caps fail the inequality refuses to start; one that passes has made every outcome and every compensation fit by construction, which is what makes an invalid-request at an outcome a deployment fault and never a caller's. A digest in place of the enumeration is no escape: nothing that reads the set — Check 3.2, the investigator, the processors put on notice — can read a digest.

**Two exclusions, named because no constituent declares either** (Capability requirement 16 through 22; the section titled *Capability provenance* in `pressure-testing.md`). The consent exclusion spans calls of three constituents — a set derivation over the log, a Consent write and an audit append — and Consent's own Concurrency entry sends the question to the composing layer. The pair exclusion exists at grant, where no consent id does yet: single-active-grant is a look-then-grant, correct only under a serialization the composition names, and two unserialized [Record Consent] calls for one pair both read not-known and both grant. As a lease the length is exactly the bound — no shorter, so a conforming invocation never loses it mid-flight; no longer, so a stalled holder blocks the reconciliation for at most the bound the liveness sum already counts — and its expiry is the invocation's terminus. There is no degraded mode (Capability requirement 22): the one-writer rule is what Invariant 3's *exactly one* rests on.

**The recovery identity** (Capability requirement 23) attests every reconciliation write, because the operator's credential is not in hand when the reconciliation runs; the operator rides in the compensating event's payload, never as its attester. **The index durability** (Capability requirement 24 and 25) is owed until Erasure Tombstone and Processing Register land (Composition state 16 and 17).

**One clock authority** (Capability requirement 27 through 29; Execution Contract Logic confinement 7). The invocation's one reading stamps every instant it writes — the intent instant, the registration instant, and the revocation instant the withdrawal passes to Consent — so the withdrawal side needs no allowance. The grant side does: Consent stamps its grant instant at its own seam and takes no clock input, so the reconciliation's grant pairing compares two seams under the clock offset allowance (Capability requirement 15; Clock semantics 3).

**The gate and the registration surface are deployment obligations, paired** (Capability requirement 30 and 31; 2026-08-30-f). [Processing Permitted] accepts no credential and records nothing, so to any caller it is an oracle over who has consented to what; exposing it only to the processing systems that consume it is the caller-side access control the gate itself cannot supply. Registration completeness is its twin: nothing in the composition forces a processing activity to register before it processes, the gate checks consent and not registration, and an unregistered activity processes lawfully while **invisible to the propagation** — no withdrawal can name it. The composition proves what was registered, never that everything was; an activity found processing on a consent basis with no registration event is the registration-side bypass finding, and verifying none exists needs the deployment's own processing inventory (External check 1).

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

WHY:
**Blank and oversized are refused before any write** (Primitive policy 1 through 4, 8 and 9; 2026-08-26-b). Every string that reaches an audit payload is non-blank and within the cap; the actor reference and the credential are non-blank — the credential checked here so an empty one is refused without a substrate round-trip, and otherwise opaque. The semantic validation of the retention policy reference against the Policy Registry is Retention Window's, at the placement, and the residue differs by where it lands: refused here, nothing exists; refused at the placement, a grant intent and a Granted, unretained consent do (Action wiring 14). The constituents bound none of these strings; the cap is what lets the largest record any action writes be sized before its intent.

**Resolution is against the subject index, never the store** (Primitive policy 5; Composition state 11). Under a direct write or an unrecovered grant orphan the store may know a consent id the events do not, and audit-first resolvability — no resolution without the grant event — is the contract. **The miss has two causes and one is temporary** (2026-08-30-a): a wrong id, a consent recorded outside the composition, or a grant orphan whose grant event the reconciliation has not yet landed — which resolves once it lands, within the compensation window. And the answer precedes the credential check, which sits at the intent: to a caller who knows an actor reference the permission check admits, not-known against a found consent is an existence oracle over consent ids. The boundary is the same one the permission check draws (Action wiring 3) and the same reason holds — recording every unauthenticated probe would make its author the author of audit volume.

**The cap refuses a new pair, never a repeat** (Primitive policy 6): the registered set is derived exactly as the withdrawal derives it, and a repeat registration of an existing pair is never refused by it. **The propagation envelope is sized before the withdrawal intent** (Primitive policy 7): a set that nonetheless does not fit is a configuration fault, refused before anything commits — never discovered at the outcome with the revoke already terminal.

**Opaque and byte-exact** (Primitive policy 10 through 13): nothing is case-folded, trimmed or normalized; a deployment wanting normalization wires it above the composition. Consent validates the subject reference, the purpose, the expiry — strictly in the future — and the metadata at its grant write, and the composition relays its invalid-request (Action wiring 12).

### Audit arm

```
Audit arm 1: IF Audit Trail answers invalid-credential at an intent THEN the action MUST answer invalid-credential.
Audit arm 2: IF Audit Trail answers invalid-request at an intent THEN the action MUST answer invalid-request.
Audit arm 3: IF Audit Trail answers recording-failure at an intent THEN the action MUST answer recording-failure carrying intent.
Audit arm 4: The composition MUST NOT retry an invalid-request answer.
Audit arm 5: IF Audit Trail answers recording-failure carrying the retention step at a later write THEN the invocation MUST proceed as landed.
Audit arm 6: The deployment MUST alert on EVERY later write landed with the retention step failed.
Audit arm 7: IF Audit Trail answers invalid-credential at a later write THEN the action MUST answer invalid-credential.
Audit arm 8: IF Audit Trail answers invalid-request at a later write THEN the action MUST answer invalid-request.
Audit arm 9: The deployment MUST alert on EVERY invalid-request at a later write as a deployment fault.
Audit arm 10: IF Audit Trail answers recording-failure carrying a pre-append step at an outcome THEN the invocation MUST retry the outcome under the consent exclusion.
Audit arm 11: An invocation's retries of one outcome MUST NOT EXCEED the outcome retry attempts.
Audit arm 12: IF the invocation's retries find no outcome landed THEN the action MUST answer recording-failure carrying outcome.
Audit arm 13: IF Audit Trail answers recording-failure carrying a pre-append step at a single write THEN the action MUST answer recording-failure.
Audit arm 14: A caller MUST read recording-failure carrying intent as a committed nothing.
Audit arm 15: A caller MUST read recording-failure carrying outcome as a committed Consent record.
```

Term intent: a grant intent or a withdrawal intent — the audit write an action makes before its first Consent write, the one that verifies the caller's credential.

Term outcome: a grant event or a propagation event — the audit write an action owes after its Consent write.

Term single write: a registration event or an access event — the one audit write of an action that commits nothing before it.

Term later write: an outcome or a single write.

Term pre-append step: a recording-failure step naming a step before the substrate's append — step-2 or step-3; the event is not in the log.

Term retention step: the recording-failure step naming the substrate's retention placement — step-4; the event is appended and attested.

Term position: intent | outcome — where a recording-failure sat: intent, nothing committed and the whole action may be re-run; outcome, the Consent record committed and its audit event is owed.

WHY:
**Mapped by position relative to the commit, and by step** (the section titled *A transcribed rejection arm keeps its payload and its reachability* in `pressure-testing.md`). The substrate attests at its step 2, appends at step 3 and places retention at step 4: a pre-append step means the event is not in the log, the retention step means it is, and a retry from there would append a second one. The retention-arm gap is the substrate's own Invariant 2 reconciliation's, and the composition treats the event as landed (Audit arm 5 and 6). Its invalid-request has two faces — the envelope inequality forecloses the caller-input source, but the substrate routes its own retention-configuration faults onto the same token with the event already appended — so it is a deployment fault at every later write, alerted naming both causes, and the reconciliation's pre-check is what tells an appended event from an absent one (Audit arm 8 and 9).

**At an intent nothing has committed** (Audit arm 1 through 4): invalid-credential is the caller's, refused with nothing in any store; a recording-failure is the one retryable arm, as a fresh intent, leaving a standing intent where the retention step failed — expected residue either way. **At an outcome the Consent record is terminal or granted** (Audit arm 5 through 12): no arm can refuse the act, only report it. invalid-credential there survives only as a mid-flight revocation or key rotation, since the same credential validated at the intent, and is surfaced as itself so an operator does not go hunting for a malformed payload. **A single write is its action's credential check** (Audit arm 13): [Register Processing] and [Read Consent History] commit nothing before it, so they need no intent and export the bare token lawfully; on the retention step the event is appended, the binding is added or the records returned, with the alert.

**The position rides the exported code** (Audit arm 14 and 15; the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`): intent means re-run the whole action; outcome means the Consent record exists, the reconciliation owns its missing event, and a re-run would be a second act — refused, as it happens, by already-granted and by Consent's already-revoked, which is also what keeps the post-commit invalid-request landings retry-safe under a bare token.

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
Action wiring 6: An admitted grant MUST take the pair exclusion.
Action wiring 7: An admitted grant MUST call the consent check with the subject reference AND the purpose under the pair exclusion.
Action wiring 8: IF the consent check answers granted THEN [Record Consent] MUST answer already-granted.
Action wiring 9: A checked grant MUST call the grant write with the subject reference, the purpose, the actor reference as the grantor, the expiry AND the metadata under the pair exclusion.
Action wiring 10: The composition MUST NOT pass an instant to the grant write.
Action wiring 11: IF the grant write answers storage-failure THEN [Record Consent] MUST answer recording-failure carrying intent.
Action wiring 12: IF the grant write answers invalid-request THEN [Record Consent] MUST answer invalid-request.
Action wiring 13: A committed grant MUST call the retention placement with the consent id AND the retention policy reference.
Action wiring 14: IF the retention placement answers a placement refusal THEN [Record Consent] MUST answer invalid-request.
Action wiring 15: IF the retention placement answers storage-failure THEN [Record Consent] MUST answer recording-failure carrying outcome.
Action wiring 16: A placed grant MUST take the consent exclusion.
Action wiring 17: A placed grant MUST record the grant event carrying the intent event id, the consent id, the subject reference, the purpose, the expiry AND the retention id.
Action wiring 18: A landed grant MUST write the retention entry AND the subject entry.
Action wiring 19: A landed grant MUST answer the consent id.
Action wiring 20: A resolved registration MUST take the consent exclusion.
Action wiring 21: A validated registration MUST record the registration event carrying the consent id, the processing scope, the processor reference AND now as the registration instant.
Action wiring 22: A landed registration MUST add the binding carrying the registration event's registration instant AND event id.
Action wiring 23: A landed registration MUST answer registered.
Action wiring 24: The composition MUST write an index entry for a consent id ONLY AFTER the consent id's grant event lands.
Action wiring 25: The composition MUST add a binding ONLY AFTER the binding's registration event lands.
Action wiring 26: [Register Processing] MUST NOT call the consent check.
Action wiring 27: A resolved withdrawal MUST take the consent exclusion.
Action wiring 28: A resolved withdrawal MUST derive the propagation set under the consent exclusion.
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
Action wiring 43: An invocation MUST NOT append an outcome BEFORE re-reading the log for the owed outcome under the consent exclusion.
Action wiring 44: IF the re-read finds the owed outcome THEN the invocation MUST adopt the owed outcome as the invocation's own.
Action wiring 45: IF the invocation's lease expired THEN the invocation MUST NOT re-read BEFORE re-taking the exclusion.
Action wiring 46: An invocation whose lease expired MUST NOT append an outcome.
Action wiring 47: An invocation MUST release EVERY exclusion at EVERY answer.
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

Term landed grant: a placed grant whose grant event landed or was adopted.

Term resolved registration: a [Register Processing] call whose permission check answered permitted and whose consent id the subject index resolves.

Term validated registration: a resolved registration whose inputs cleared Primitive policy.

Term landed registration: a validated registration whose registration event landed.

Term resolved withdrawal: a [Withdraw Consent] call whose permission check answered permitted and whose consent id the subject index resolves.

Term validated withdrawal: a resolved withdrawal whose inputs and propagation envelope cleared Primitive policy.

Term admitted withdrawal: a validated withdrawal whose withdrawal intent landed.

Term committed withdrawal: an admitted withdrawal whose revoke write answered revoked.

Term landed withdrawal: a committed withdrawal whose propagation event landed or was adopted.

Term validated history read: a [Read Consent History] call whose permission check answered permitted and whose inputs cleared Primitive policy.

Term fetched history read: a validated history read whose consent read answered.

Term landed history read: a fetched history read whose access event landed.

Term validated gate query: a [Processing Permitted] call whose inputs cleared Primitive policy.

Term invocation: one call of a state-changing action, from its seam reading to its answer.

Term owed outcome: the outcome a consent's act owes — for a grant, or an ungranted record, a grant event carrying the consent id; for a withdrawal, or an unpropagated record, a propagation event carrying the consent id. A grant event and a propagation event carry one consent id, so a read keyed on the consent id alone would find the wrong one.

Term index-anomaly finding: a finding that the subject index resolves a consent id the Consent store does not know.

WHY:
**Permission first, and a denied attempt leaves no trace** (Action wiring 1 through 3). A permission-denied refusal costs one store read and writes nothing, so any caller may probe whether an arbitrary actor reference holds a scope and leave no record. That is a deliberate boundary: recording every denied probe would make an unauthenticated caller the author of audit-trail volume, and failed-attempt logging, with its own retention and alerting, belongs to a failed-attempt pattern (Non-goal 8). What the composition guarantees is that no attempt which *changes anything* is unattributed.

**[Record Consent] writes in order, never atomically** (Action wiring 4 through 19). The intent first — where the operator's credential is verified — carrying no consent id, since none exists yet and the consent id is the key all three indexes are built on: an intent naming one would be exactly the resolvable-without-a-grant-event bypass audit-first forecloses (Action wiring 5 and 24). Then **single-active-grant, under the pair exclusion** (Action wiring 6 through 8): Consent declares that a subject and purpose *together do not form a unique key* and that its check *evaluates the most recently granted* record; this composition's gate is keyed by the pair and its propagation by the consent id, and the two speak of one record only while one Granted record per pair exists (Invariant 1.3). already-granted covers an earlier grant, a caller's retry after an outcome-position refusal whose orphan the reconciliation will land, and a direct write Check 2.2 reports; revoked, expired and not-known proceed — the re-consent path. Then the grant write, which takes no clock input: Consent stamps the grant instant at its own seam (Action wiring 10). Its storage-failure lands at the intent position, since the constituent refused and nothing landed. Then the placement, whose refusals land at the outcome position with a Granted, unretained record standing — the reconciliation's second grant shape (Reconciliation 18). **The consent exclusion is taken once the consent id exists** (Action wiring 16): the grant event is an outcome like the propagation event, and the reconciliation compensates it under the consent exclusion, so the invocation's pre-check and retries run under the same one — one writer per act. Only then the grant event, and only after it the index entries.

**[Register Processing] is one audited act, audit-first** (Action wiring 20 through 26). Its registration event is its credential check and its first commit; the binding follows it, so every binding traces to an immutable event (Invariant 4). A crash between the two leaves an event with no binding — the partial the derivation repairs as a side effect and the reconciliation's third leg repairs at cadence (Action wiring 31; Reconciliation 22). **It does not check consent state** (Action wiring 26): an activity registered against a Granted consent before processing begins is the case the propagation exists for, and registering against an already-Revoked consent is permitted — the binding records intent — and pointless, since the gate refuses; a deployment wanting to forbid it wires the check above the composition. A repeat registration records its own event, because the registration *act* is an auditable decision; the set membership, not the event count, is what the propagation enumerates.

**[Withdraw Consent] derives the set first, from the events, and pins its boundary with the intent** (Action wiring 27 through 33). The set is derived from the registration events — the one traversal the compensation and Check 3.2 also run, so the invocation, the reconciliation and the auditor share one definition — plus the index's purged entries, for which the index is the only carrier. A live index entry is never a source (Action wiring 30): a binding whose event landed and whose index write was lost is in the set because its event is, and **a short list is not an observable miss** (the section titled *A derived index is trustworthy only where a miss is observable* in `pressure-testing.md`). Nothing can be registered between the derivation and the intent — both inside one consent exclusion (Concurrency 1) — so the propagation set is exactly the registrations ordered before *this* intent. The intent carries that boundary and not a copy of the set (Action wiring 33): the set has one authoritative carrier, the propagation event, and a second copy would hand an auditor a set Check 3.2 is not stated against.

**Revoke, then the propagation event, ordered** (Action wiring 34 through 42; Wiring decision 1). The invocation's reading is passed to the revoke write as the revocation instant, so the Consent record and the event carry one instant — a pass-through, not an atomicity claim — which is the authoritative withdrawal time for an Article 7(3) dispute. already-revoked and already-expired relay Consent's terminal absorption; an invalid-request after the intent is a cross-seam skew between this seam's reading and Consent's future-guard (Capability requirement 15), nothing committed; a storage-failure leaves the record Granted by Consent's own contract. **not-known is relayed as itself** (Action wiring 39 and 40; 2026-08-26-g): the subject index resolved an id Consent does not know, which is an index anomaly and never a failed audit write — mapping it onto recording-failure invited a retry nothing addresses.

**The outcome is pre-checked under the exclusion and an existing one adopted** (Action wiring 43 through 47; the section titled *A compensator is exclusive* in `pressure-testing.md`). The reconciliation compensates an orphan while an invocation stalled past the bound, or an acknowledgment is lost; a second outcome for one consent is the duplicate Invariant 3.2 forbids and the seal would then protect. An invocation whose lease expired **has yielded**: it re-takes the exclusion before its pre-check, adopts what it finds or answers recording-failure carrying outcome, and appends nothing, so it can never resume between the reconciliation's pre-check and its append. The in-invocation retry is the invocation's own write under the operator's credential, never a compensation, and carries no recovery flag.

**[Read Consent History] gates the result on the access event** (Action wiring 48 through 52): under the regimes this composition serves, access to consent records is itself auditable, so an access that cannot be recorded is not returned. One write is reachable before authentication and is named: a Consent instance implementing expiry lazily writes the Expired transition inside the read that first evaluates a record past its expiry (Consent Invariant 6). It is outside Invariant 8 by the rule's own terms — it materializes a value already true of the record, carries no caller content and relies on no actor's authority. Where the substrate appends the access event and answers invalid-request, the trail records an access whose result was refused — the safe direction.

**[Processing Permitted] delegates the predicate and records nothing** (Action wiring 53 through 57). Its validation is load-bearing for the signal's honesty: the consent check never refuses, so a malformed subject reference would otherwise flow through to not-known — *this subject never consented* where the truth is *your input is malformed*. The point-in-time evaluation is Consent's, against the reading injected at Consent's own seam; the composition passes no instant and adds no predicate. The withheld state is named so the caller can tell *never consented* from *withdrawn* from *lapsed* — request consent, honor the withdrawal, request renewal. A read-only query recording an audit event would falsely populate the action record with non-actions.

**The pairing key is the intent event id, and the deviation is declared** (2026-08-30-e). The section titled *Intents pair with outcomes* in `pressure-testing.md` pairs by a per-invocation id; this composition mints none and pairs by the intent event id instead — substrate-minted, sealed, and carried by every outcome and every compensating event, which the reconciliation re-derives by exact equality on the withdrawal side and narrows by window on the grant side (Reconciliation 10 and 17). A refusal after the intent writes no outcome, and its intent stands as residue the checks triage (Check 6.4); a refusal outcome event is not added, since the Consent store already says which case each residue is.

### Wiring decision

```
Wiring decision 1: The composition MUST append a propagation event ONLY AFTER the revoke write answers revoked.
Wiring decision 2: The composition MUST NOT claim an atomic set spanning the revoke write AND the propagation event.
Wiring decision 3: The composition MUST NOT expose a withdrawal surface other than [Withdraw Consent].
Wiring decision 4: The composition MUST NOT expose a consent gate other than [Processing Permitted].
```

WHY:
*A system processes personal data on a consent basis only through [Processing Permitted], which answers permitted exactly when valid consent exists; and a withdrawal commits the Consent revocation and then a propagation event enumerating every downstream scope registered against the consent — revoke, then propagation event, ordered, bijective at quiescence modulo compensation* (Invariant 3).

*Principle.* GDPR Articles 6 and 7 require a valid consent at processing time, and Article 7(3), read with Article 17(1)(b), requires that withdrawal end the basis for future processing — which, operationally, means the systems relying on the consent must learn of the withdrawal. The system must prove, from the records alone, both that the gate was the single consent precondition and that every withdrawal's downstream impact was enumerated and sealed at the moment of revocation.

*Likely objection.* Consent already owns the lifecycle and exposes its check. Why not let each processing system call it, and why a propagation event when the revocation is already in the Consent store?

*Mechanism.* Consent owns the state and exposes no gate and no propagation, by design. A check called per system is a gate re-implemented per system, and the first system that forgets it, caches a stale answer or treats expired as granted breaks the Article 6 basis silently (Wiring decision 4). And the Consent store records *that* a consent was revoked, never *what was relying on it* — importing downstream processing would break its freestanding status — so a revoke alone leaves the withdrawal's downstream impact unrecorded, and a system that never re-checks keeps processing with no record that it should have stopped. The composition closes this with the downstream index, populated by an audited act, and a propagation event carrying the complete set. **What binds the revoke and the event is the order, not a transaction** (Wiring decision 1 and 2): Consent's revocation is terminal by its own invariant and the substrate's append cannot be withdrawn, so neither write is enlistable, and no host transaction can span them. The event follows the revoke, so a propagation record always has a real revocation behind it — unconditionally, which is the direction an Article 7(3) dispute runs. The gap that remains runs the other way — a revocation whose propagation record has not landed — and it is a gap in the *accounting*, not the *suppression*: the gate reads Consent and answers not-permitted carrying revoked from the instant the revoke commits, given single-active-grant (Invariant 1.3). What would defeat the purpose is the mirror — an event asserting a withdrawal the store does not hold — and the order makes it unreachable.

*Result.* The gate is structural and single; the propagation is complete and sealed *over the registered set*. An auditor answers *when this person withdrew consent, what was supposed to stop, and is it recorded?* by reading one sealed event rather than interviewing every processing system. **What the records cannot prove is outward completeness**: the composition proves what was registered, never that every real processing activity registered — an unregistered one is invisible to the propagation exactly as a gate-bypassing one is invisible to the gate. The two single-surface obligations are paired and the deployment's (Capability requirement 30 and 31; Invariant 1.2).

### Reconciliation

```
Reconciliation 1: The reconciliation MUST run at EVERY process start.
Reconciliation 2: The reconciliation MUST run every reconciliation cadence.
Reconciliation 3: The reconciliation MUST NOT examine a young record.
Reconciliation 4: The reconciliation MUST NOT triage an aged record.
Reconciliation 5: The reconciliation MUST report an aged unpropagated record as propagation history purged.
Reconciliation 6: The reconciliation MUST read EVERY revoked Consent record against the propagation events.
Reconciliation 7: The reconciliation MUST NOT pre-check a record BEFORE taking the record's consent exclusion.
Reconciliation 8: IF another holder holds the consent exclusion THEN the reconciliation MUST leave the record to the reconciliation's next run.
Reconciliation 9: The reconciliation MUST NOT compensate a record whose owed outcome exists.
Reconciliation 10: The reconciliation MUST pair an unpropagated record to the withdrawal intents carrying the record's consent id whose intent instant EQUALS the record's revocation instant AND whose actor EQUALS the record's revoker.
Reconciliation 11: IF the withdrawal candidate count EQUALS zero THEN the reconciliation MUST open a write-ownership finding for the record.
Reconciliation 12: The reconciliation MUST NOT compensate an unpaired record.
Reconciliation 13: The reconciliation MUST derive a compensating propagation event's propagation set at the earliest candidate's boundary.
Reconciliation 14: The reconciliation MUST re-derive EVERY other field of a compensating event from the indexes, the Consent record AND the retention placement.
Reconciliation 15: The reconciliation MUST read EVERY Consent record against the grant events.
Reconciliation 16: The reconciliation MUST NOT read a zero-candidate ungranted record as a write-ownership finding.
Reconciliation 17: The reconciliation MUST pair an ungranted record to the grant intents carrying the record's grantor as the actor, the record's subject reference AND the record's purpose whose grant skew DOES NOT EXCEED the pairing window.
Reconciliation 18: IF an ungranted record carries no consent retention THEN the reconciliation MUST call the retention placement with the paired intent's retention policy reference.
Reconciliation 19: The reconciliation MUST NOT record a compensating grant event BEFORE the record's consent retention exists.
Reconciliation 20: The reconciliation MUST write a compensated grant's index entries ONLY AFTER the compensating grant event lands.
Reconciliation 21: IF the candidate count EXCEEDS one THEN the compensating event MUST carry the intent candidates.
Reconciliation 22: IF a registration event's pair IS NOT IN the downstream index THEN the reconciliation MUST add the binding from the event's payload under the consent exclusion.
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

Term young record: a Consent record whose grant instant — or, revoked, whose revocation instant — plus the administration completion bound DOES NOT PRECEDE the reconciliation's now.

Term aged record: a Consent record whose grant instant — or, revoked, whose revocation instant — plus the audit horizon PRECEDES the reconciliation's now.

Term unpropagated record: a revoked Consent record no propagation event names, neither young nor aged.

Term ungranted record: a Consent record no grant event names, neither young nor aged.

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

Term planned writes: the placement and the event a grant recovery will make, or the event a propagation recovery will make.

Term escalation: the consent.propagation_escalated event — the closed-state marker for an orphan the reconciliation will not compensate.

Term cause: recording-failure carrying a step | invalid-request | no-candidate | candidates-over-cap | policy-unresolved — what the reconciliation observed.

Term uncompensable cause: an ungranted record's candidate count EQUALS zero — no-candidate; an orphan's candidate count EXCEEDS the intent candidates cap — candidates-over-cap; or an ungranted record lacking its consent retention whose candidates carry different retention policy references — policy-unresolved.

Term escalation instant: a Consent record's grant instant — or, for its withdrawal, its revocation instant — plus the compensation window.

Term attempt count: how many compensating writes the reconciliation made for the orphan.

Term binding repair: a binding the reconciliation adds from a registration event's payload.

WHY:
**Why the reconciliation is mandatory.** An orphan is reachable by a *return* — the action refuses and surfaces it in its own answer — and by a *crash*, where nothing returns. Only the first surfaces itself; the second is what Invariant 3.4 is about. It is **Reconciliation, not Housekeeping**: an auditor awaits its output.

**Bounded at both ends, exclusive, as the composition** (Reconciliation 3 through 9 and 24 through 27; the sections titled *A reconciliation is bounded at both ends*, *A compensator is exclusive* and *Recovery commits under a declared service identity* in `pressure-testing.md`). Below the bound a record may belong to an invocation still between its two writes, and a compensation there would append beside the event the invocation is about to write. Past the horizon an event's absence is lawful destruction, not a signature: an aged unpropagated record is reported as propagation history purged and never triaged, since the withdrawal intent the pairing would look for is destroyed with it. The pre-check is re-read *under* the consent exclusion, never before it, and a run that cannot take a consent's exclusion skips it; restart and cadence runs, on one node or two, never both land an outcome. The operator is absent when the reconciliation runs, so every write is attested under the recovery identity behind a recovery intent naming the invocation it repairs, and the operator rides in the payload — attesting as the operator would be a false attribution the substrate would refuse or a cached credential would let through.

**The withdrawal side pairs exactly** (Reconciliation 10 through 14). The revoking invocation passed its own reading to the revoke write and stamped the same reading on its intent, and named the operator as the revoker, so the stamp on the Consent record is this composition's and the pairing is by equality — a zero-match is a signature, not a skew (the section titled *A stamp from another seam never decides a write alone* in `pressure-testing.md`; the pass-through is its remedy). A direct revoke against the shared instance presents exactly as an orphan does — Revoked, a grant event, no propagation event — and has no paired intent, since it never entered the composition; compensating it would manufacture a propagation record for a withdrawal this composition never performed and attribute it to an operator who never called (Reconciliation 11 and 12). Existence of *an* intent is not the test: a stale intent from a refused retry names the same consent id and pairs with nothing. Where more than one matches — the clock's resolution admitting two invocations inside one reading, one of which may have died before its revoke and so *precede* the revoking one — the reconciliation **never chooses** (Reconciliation 21), and the set is derived at the earliest candidate's boundary (Reconciliation 13). **The compensation re-derives the set; it does not re-read the index** (Reconciliation 13 and 14): [Register Processing] is permitted against a Revoked consent, so the index may have grown since the withdrawal, and a compensation enumerating a scope registered after the subject withdrew would misstate what the withdrawal covered. Everything else is re-derived from the subject index, the Consent record and the placement; nothing is remembered from the process that died.

**The grant side pairs by window and concludes nothing from a miss** (Reconciliation 15 through 20). Two shapes: granted and retained with no event — a grant-event failure; granted and unretained with no event — a placement failure. The intent instant is this seam's and the grant instant Consent's, so they are compared only under the declared allowance, symmetrically, since skew has a sign the bound does not; the comparison **narrows** the candidates and decides nothing alone. A zero-match on a cross-seam window is what a skew beyond the allowance looks like as much as what a direct write looks like, so the reconciliation writes nothing and escalates it as no-candidate (Reconciliation 16 and 29); the direct-write bypass is *reported* by Check 2.2's store-side reading, which needs no pairing, and never *concluded* from this leg. For the unretained shape the placement is re-run from the intent's own retention policy reference — the reason the intent carries it — and where candidates carry different references the reconciliation cannot choose one and escalates as policy-unresolved. Surplus grant intents are the normal case, not the exception: every [Record Consent] refused after its intent leaves one with no record behind it.

**The third leg repairs the downstream index** (Reconciliation 22 and 23): a registration event whose binding write was lost is added from the event's own payload, an index repair that writes no audit record, which makes a lost binding an observable miss for every reader of the index and not only for the withdrawal's derivation.

**Every writer has a terminus, and escalation is a record** (Reconciliation 28 through 35). *Until it lands* is no discipline for a permanent cause, and a loop with no bound is indistinguishable, from the records, from an orphan nobody is working on. The invocation's terminus is its counted retries; the reconciliation's is the compensation window, past which it writes an escalation under the recovery identity naming the cause it observed — the closed-state marker for that act, reported every run and never followed by a second compensation or escalation. What resolves an escalated orphan is outside the composition. An escalation needs no recovery intent of its own, since it commits nothing it could fail between. The alert is a surfacing, never the record (Reconciliation 36): Check 3.5 reads the escalation, not a dashboard, and a deployment that surfaces findings to a dashboard the records cannot see has escalated nothing. Under GDPR exposure an orphan is a hard alerting condition.

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

  WHY: three claims, told apart by what enforces each. **The query result** (Invariant 1.1) is composition-enforced: permitted only on granted, and every other answer a refusal naming the state — the biconditional is exact. **The gating property** (Invariant 1.2) is deployment-conditional: a processing system reaches a consent-based action only through the gate exactly when it consumes [Processing Permitted] rather than reading Consent, and one that bypasses it is a composition-bypass finding, not a valid path; the "iff" is a property of the answer, and the gate guarantee also needs this obligation honored. **Single-active-grant** (Invariant 1.3) is composition-enforced by Action wiring 6 through 8 under the pair exclusion, and it is what makes Invariant 1.1 and Invariant 3 speak of one record: Consent allows several Granted records per pair, evaluates the latest, and leaves uniqueness to *the composing layer*, which would otherwise let a withdrawal of the older grant tell every registered processor to stop while the gate stays permitted, and a withdrawal of the newer flip the gate while the older's registrations are never named. *Rests on* the consent check's declared latest-grant selection and the pair exclusion (Capability requirement 17).
- **Invariant 2 — Grant audit coverage.**
  ```
  Invariant 2.1: IF a governed consent's escalation instant PRECEDES now THEN the governed consent MUST carry a grant closure.
  Invariant 2.2: EVERY grant event MUST carry an attestation AND a position in the Event Log sequence.
  ```
  Term grant closure: a grant event naming the consent, or an escalation of kind grant naming the consent.

  WHY: every grant is attributed and tamper-evident, and a governed consent with no grant event is an orphan under the reconciliation until its closure (2026-08-30-d). A Consent record with no grant event and no escalation past the window is not a silent orphan of this composition — an orphan of its own always has a pairable intent the reconciliation would compensate or escalate — so it is the direct-write signature Check 2.2 reports. *Rests on* the grant write's consent id, Action wiring 17, and Audit Trail Invariant 1 and 3.
- **Invariant 3 — Revocation propagation completeness.**
  ```
  Invariant 3.1: EVERY propagation event MUST name a consent the Consent store holds in Revoked.
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

  WHY: the load-bearing guarantee, and its two writes do not commit together — **neither half can be taken back, so no transaction can enlist them**, and a gap that arises wherever a host cannot provide atomicity is not an exception but the only case. The claim splits, and the order makes the split favourable. **Safety, unconditional** (Invariant 3.1 and 3.2): the event is appended only after the revoke answers revoked, and the revocation is terminal (Consent Invariant 3 and 9), so any propagation event is a real withdrawal. **Safety, never silent** (Invariant 3.4): the reverse partial — Revoked, unpropagated — is reachable and durable, surfaced in the answer when the failure returns and by the reconciliation when it cannot. **Liveness** (Invariant 3.5): the invocation's counted retries, then the reconciliation's runs, never both, each pre-checked; a compensated withdrawal is distinguishable from a clean one (Invariant 3.6); past the window the orphan closes as an escalation, and the liveness sum's inequality makes *within the window* arithmetic. An unpaired record is a write-ownership finding, outside the claim. **Not at risk during the gap**: suppression — the gate reads Consent and refuses from the instant the revoke commits, under Invariant 1.3. What is missing is the *record* of which scopes should stop — an accountability gap, not a lawfulness one, which is the discriminator that made this a restatement rather than the protocol repair [Capability-Backed Sharing](./capability-backed-sharing.md) needed. **The boundary is the intent, not the event** (Invariant 3.3): a compensating event lands in a later invocation than the derivation it reports, and [Register Processing] is permitted against a Revoked consent, so a registration landing in the recovery window sits before the compensating event and outside its correctly-derived set — the event's own position would convict a correct compensation. Nothing registers between the derivation and the intent, both inside one consent exclusion, so the intent fixes the point for clean and compensated withdrawals alike, at no new field and no second copy of the set. *At quiescence, with no open compensation, the binding is bijective: revoke ⇔ complete propagation record.* The quantifier runs over consents revoked, not withdrawals intended: an intent refused already-revoked leaves residue, not a violation. The formal model checks this invariant; its re-derivation over the invocation and the reconciliation as two processes over one act is open (2026-08-29-a, 2026-08-30-k). *Rests on* Consent's revoke (Consent Invariant 3 and 9); Audit Trail's append-only contract, which offers no rollback — the declared source of the boundary this invariant is organized around; the registration events as the set's one source (Invariant 4); the caps (Capability requirement 13 and 14); the counted terminus and the consent exclusion; and the window and cadence (Capability requirement 10).
- **Invariant 4 — Downstream registration is recorded.**
  ```
  Invariant 4.1: EVERY binding MUST carry a registration event carrying the binding's pair AND consent id.
  ```
  WHY: the binding is added only after its event lands (Action wiring 25), so every scope a propagation set names traces to a recorded registration act, and the set is not a free-floating assertion. The converse partial — an event with no binding — is not a violation and not silent: the derivation reads the events, and the reconciliation's third leg repairs the index. *Scope*: it grounds every **registered** binding and cannot assert that every real processing activity registered — that outward completeness is the deployment's (Capability requirement 31), the registration mirror of Invariant 1.2. *Rests on* Action wiring 25 and Audit Trail attribution.
- **Invariant 5 — Records-alone consent lifecycle.**
  ```
  Invariant 5.1: EVERY governed consent's lifecycle MUST resolve from the Consent store, the Audit Trail instance AND the indexes alone.
  ```
  Term lifecycle: the grant intent and grant event with the Consent record; the registration events with the downstream entry; the withdrawal intent and propagation event with the Revoked record; and every access event.

  WHY: reconstructable without source code or developer narration. *Rests on* Invariant 2 through 4, Consent Invariant 8 — terminal records retained — and Audit Trail's forensic completeness; past the horizon the key entries and purged downstream entries carry what the purge destroyed (Composition state 13).
- **Invariant 6 — Consent-record retention floor.**
  ```
  Invariant 6.1: EVERY consent retention MUST carry Retained.
  Invariant 6.2: IF a governed consent's escalation instant PRECEDES now THEN the governed consent MUST carry a retention closure.
  Invariant 6.3: The composition MUST read a consent retention's proof-period end ONLY from Purge Eligible.
  ```
  Term consent retention: the consent retention instance's record over one consent record.

  Term retention closure: a consent retention naming the consent, or an escalation of kind grant naming the consent.

  WHY: a withdrawn consent must outlive its own withdrawal — it is the proof, under GDPR Article 7(1), that the controller once had a valid basis and lawfully ended it. Two constituents say two things about one record and both hold: Retention Window Invariant 7 is the structural floor — nothing destroys the record before its retention ends, even in a deployment that wires purge — and Consent Invariant 8 is what holds past the floor. Retention Window defines Purged as the state of a retention whose record *has been destroyed*, which Consent forbids, so a consent retention **never lawfully reaches Purged** (Invariant 6.1); when the proof period elapses the observable fact is Retention Window's read-time Purge Eligible turning true — a derived value, not a transition (Invariant 6.3). **Split for liveness** (Invariant 6.2; 2026-08-30-d): the unretained grant shape is reachable, so the placement is owed within the window like any orphan's closure, not held at every instant. *Rests on* Consent Invariant 8, Retention Window Invariant 7, and the retention entry as records-alone evidence of the placement.
- **Invariant 7 — Inward and outward authorization stay separate.**
  ```
  Invariant 7.1: An administration action MUST NOT commit a constituent write for an actor the permission check denied.
  Invariant 7.2: A validated gate query MUST call ONLY the consent check.
  ```
  WHY: Consent is outward authorization — the subject authorizes the system to process their data; Permissions is inward — the organization authorizes an operator to administer records. Collapsing them, gating processing on an operator's permission or administration on the subject's consent, is the error Consent's Intent warns against; keeping them apart lets an auditor answer *was this operator authorized to record this withdrawal?* and *did this subject consent to this processing?* as separate, separately evidenced questions. *Rests on* Action wiring 1 through 3 and 53 through 57.
- **Invariant 8 — Authentication precedes commitment.**
  ```
  Invariant 8.1: The composition MUST NOT call the grant write BEFORE Audit Trail validates the caller's credential at the grant intent.
  Invariant 8.2: The composition MUST NOT call the revoke write BEFORE Audit Trail validates the caller's credential at the withdrawal intent.
  Invariant 8.3: The composition MUST NOT add a binding BEFORE Audit Trail validates the caller's credential at the registration event.
  Invariant 8.4: The composition MUST NOT answer a consent history BEFORE Audit Trail validates the caller's credential at the access event.
  ```
  WHY: at the four administration actions — the ones that take a credential and act on a named operator's authority — nothing that commits on the caller's authority, and no index write recording the invocation's own effect, is reached before the operator's credential validates. Two mechanisms, by where each action's first audit write sits: [Record Consent] and [Withdraw Consent] commit first at Consent, so each opens with an intent; [Register Processing] and [Read Consent History] commit nothing before their single write. Two things are outside the quantifier by the rule's own terms, not by exception: the derivation and its index repair, which reconstruct from committed events with no caller input; and the Expired transition a lazily-expiring Consent writes inside its read, which materializes a value already true of the record. [Processing Permitted] takes no credential, names no actor and commits nothing, so it has nothing to authenticate. **What it does for Invariant 7**: the permission check takes an actor reference and no credential, so without this ordering Invariant 7 asserted authorization over an identity nobody had verified — a caller who knew a privileged actor reference passed it. The intent does not move the permission check; it establishes that the caller **is** the actor the check consulted. **What it does not establish**: that the presenter is that actor — a stolen credential validates — nor channel binding or replay resistance, and nothing whatever about the data subject, whose reference is never authenticated here and whose consent's quality stays an external check (External check 3). *Rests on* the audit write and the Actor Identity attestation reached through it; Check 6.1 tests the order from the records.

The gate plus grant coverage gives *substantiated processing* — every consent-based action gated on a recorded, attributed consent. Propagation completeness plus registration recording gives *propagated withdrawal* — every withdrawal's downstream impact enumerated and itself records-grounded. The records-alone lifecycle and the retention floor close the lifecycle; Invariant 7 keeps the two authorization surfaces apart, and Invariant 8 makes Invariant 7's inward half a claim about a verified operator.

---

## Examples

### Walkthrough — marketing-consent management under GDPR

A retail platform uses this composition to manage marketing consent. Configuration: `consent_record_retention_policy_ref = gdpr_consent_proof_6yr`, `audit_trail_retention_policy = gdpr_audit_10yr`. Permission grants: the consent-service actor holds `consent:grant`, `consent:register-processing`, `consent:revoke`, `consent:read`; the data-subject-request officer `dsr_officer` holds `consent:read`.

1. **Record consent.** A user affirms a marketing-email consent banner; the consent service calls `record_consent(actor_ref="consent_svc", subject_ref="user-4491", purpose="marketing:email", credential=<consent_svc>, retention_policy_ref="gdpr_consent_proof_6yr", expires_at="2027-05-13T00:00:00Z") → consent_id = cns-7001`. Internally: `Permissions.permitted("consent_svc", "consent:grant") → permitted`; then — **before anything commits** — Audit Trail records `consent.grant_intended` → `ev_grant_int_01`, which is where the consent service's credential is checked against the actor registry (had it not validated, the call would have returned `rejected(invalid-credential)` with no consent granted and no retention placed); then `Consent.check("user-4491", "marketing:email") → not-known` — no Granted record for the pair, so single-active-grant holds and the grant proceeds; then `Consent.grant(...) → cns-7001` (Granted); `Retention Window.place_under_retention(cns-7001, gdpr_consent_proof_6yr) → ret_cns_7001`; Audit Trail records `consent.granted` carrying `intent_event_id: ev_grant_int_01`; maps populated. Note what the intent event does **not** carry: no `cns-7001`, which did not exist when it was written and which only `consent.granted` may make resolvable.

2. **Register downstream processing.** Two systems will rely on this consent. `register_processing(actor_ref="consent_svc", consent_id="cns-7001", processing_scope="email-campaign-engine", processor_ref="campaigns@platform", credential=<consent_svc>) → registered`, and again for `processing_scope="lookalike-audience-builder", processor_ref="adtech@platform"`. Each records a `processing.registered` event; `consent_to_downstream[cns-7001]` now holds two bindings.

3. **Gate check before processing.** Before sending a campaign, the email engine calls `processing_permitted("user-4491", "marketing:email") → permitted`. The campaign proceeds.

4. **Withdrawal with propagation.** The user clicks "unsubscribe / withdraw consent." The consent service calls `withdraw_consent(actor_ref="consent_svc", consent_id="cns-7001", credential=<consent_svc>, reason="user-withdrawal-via-preferences") → withdrawn`. Internally: `Permissions.permitted("consent_svc", "consent:revoke") → permitted`; `affected_scopes` derived from the two `processing.registered` events carrying `cns-7001` = `{email-campaign-engine@campaigns, lookalike-audience-builder@adtech}`; Audit Trail records `consent.withdrawal_intended` → `ev_wd_int_01`, verifying the credential before the terminal transition and carrying the consent_id but **not** the `affected_scopes` (one authoritative carrier, Invariant 3); `Consent.revoke(cns-7001, ...) → revoked`; Audit Trail records `consent.revoked` carrying `intent_event_id: ev_wd_int_01` and the complete `affected_scopes` set — *ordered after the revoke*. Invariant 3 holds: the revocation is committed and its complete downstream enumeration is sealed behind it, one propagation event per withdrawal. Invariant 8 holds and is checkable: `ev_wd_int_01` precedes the propagation event in the Event Log's order (their `intended_at` and `revoked_at` are the same injected instant, so the `sequence_number` is what settles it) and names the same operator.

5. **Gate check after withdrawal.** `processing_permitted("user-4491", "marketing:email") → rejected(not-permitted(revoked))`. The email engine and the audience builder, consuming the propagation event or re-querying the gate, cease processing; deleting the derived lookalike audience is the audience builder's own obligation, signalled by the `consent.revoked` event's `affected_scopes`.

6. **DSAR audit.** A data-subject access request calls `read_consent_history(actor_ref="dsr_officer", subject_ref="user-4491", credential=<dsr_officer>)` → the Granted-then-Revoked `cns-7001` record; a `consent.history-read` meta-event is recorded. The complete lifecycle — the grant and its intent, two registrations, the withdrawal-with-propagation and its intent, the access — is reconstructable from the records (Invariant 5), and each state-changing act's records show the operator was verified before it committed (Invariant 8).

### Re-consent path

Six months after withdrawal the user re-enables marketing email. `record_consent(...) → cns-7042` (the single-active-grant check answers revoked, so the grant proceeds; a fresh Granted record, `cns-7001` remaining Revoked as evidence). `processing_permitted("user-4491", "marketing:email") → permitted` (Consent's `check` evaluates the most-recent grant). Downstream processing is re-registered against the new consent_id; the prior consent's propagation record is untouched history.

### Rejection path — a second grant for a pair that already holds one

A retry of the walkthrough's first `record_consent(...)` after a timeout, or a second banner affirmation while `cns-7001` is Granted: the single-active-grant check `Consent.check("user-4491", "marketing:email") → granted` → `rejected(already-granted)`. No second Granted record is created for the pair (Invariant 1.3); the grant intent stands as ordinary residue. Where the first call had committed `cns-7001` and returned `rejected(recording-failure(outcome))`, the refusal is also the caller's signal that the record exists and the scan owns its event — the caller does not grant again.

### Rejection path — withdrawal by an unauthorized operator

An operator lacking `consent:revoke` attempts `withdraw_consent(...)`: the permission check `Permissions.permitted → denied` → `rejected(permission-denied)`. No consent state changes; no propagation event is recorded. (Invariant 7 — administration is permission-gated.)

### Rejection path — withdrawing an already-revoked consent

A retry after a timeout: `withdraw_consent(actor_ref="consent_svc", consent_id="cns-7001", credential=<consent_svc>, reason="retry")` → the withdrawal intent is written (the operator is real and their credential validates), then Consent's already-revoked is relayed as `rejected(already-revoked)`. No second propagation event is recorded; the single `consent.revoked` event from the first withdrawal stands. The retry therefore leaves a `consent.withdrawal_intended` event with no `consent.revoked` event carrying its `intent_event_id` — the expected residue of the authentication discipline, and the worked instance of the triage's other-invocation case (Check 6.4): the consent is Revoked, but by *another* invocation's propagation event, so nothing is owed and no compensating record may be written. (Consent Invariant 3 — terminal absorption — surfaced at the composition boundary.)

### Failure path — withdrawal whose propagation event fails to record

A [Withdraw Consent] call passes its checks and its intent, revokes, and its propagation event's `record_action` fails (recording-failure at a pre-append step): the invocation re-attempts the append up to `outcome_retry_attempts` times under the operator's credential — a pre-append failure means no event landed, so each attempt's pre-check finds none (a step-4 retention-arm failure would instead leave the event appended, and the pre-check would find it and re-append nothing) — and, the attempts spent, returns `rejected(recording-failure(outcome))`: the position telling the consent service the consent **is** Revoked and the action must not be re-run (a re-run would be refused already-revoked in any case), with the Revoked-but-unpropagated consent surfaced on the compliance dashboard meanwhile — a surfacing, not the record: the record is the compensating event, or `consent.propagation_escalated` should the window elapse. The orphan is now the scan's alone; the compensating `consent.revoked` event, when it lands, is attested under the composition's service identity behind a `consent.recovery_intended` record, carries `cascade_recovery = true`, names the operator as `revoked_by`, and points at the original `consent.withdrawal_intended` event as its `intent_event_id`, so an auditor distinguishes the recovered withdrawal from a clean one and still reads who withdrew (Reconciliation 24 through 27). Had the cause been permanent, the scan would instead have written `consent.propagation_escalated` within `compensation_window`, naming the arm it observed, and Check 3.5 reads that record rather than a dashboard. The gate is already honest during the gap: processing_permitted reads Consent, so it returns `rejected(not-permitted(revoked))` from the moment the revoke committed.

### Rejection path — gate query for a subject who never consented

`processing_permitted("user-9999", "marketing:email")` where no consent record exists → `Consent.check → not-known` → `rejected(not-permitted(not-known))`. The processing system distinguishes *never consented* from *withdrawn* and requests consent rather than honoring a withdrawal that never happened.

---

### Regulated adversarial scenarios

**Regulator audit — "prove every consent-based processing activity was gated on valid consent, and that withdrawals propagated."** A data protection authority examines the Audit Trail and the processing records. For every downstream processing activity *the deployment discloses* (the composition's records enumerate the registered set; whether that set is outwardly complete is the deployment's registration obligation, verified against the deployment's own processing inventory — an externally-clearable question), the examiner confirms a `processing.registered` event bound it to a consent_id (Invariant 4); for the consent governing it, the examiner confirms a `consent.granted` event (Invariant 2) and that `AuditTrail.verify_record` returns verified for both. For every withdrawn consent, the examiner confirms exactly one `consent.revoked` event whose `affected_scopes` enumerates every `processing.registered` binding for that consent_id (Invariant 3) — a withdrawal whose `affected_scopes` omits a registered binding, or a revoked Consent record with no `consent.revoked` event at all, is a conformance failure. The examiner consults no source code or runbooks; the gate is the single processing precondition (Invariant 1) and the propagation event is the single record of downstream impact.

**Disputed withdrawal — data subject claims processing continued after they withdrew consent.** A data subject complains that marketing continued after withdrawal. The investigator retrieves the `consent.revoked` event for the subject's consent: it carries `revoked_at`, reason, and the complete `affected_scopes` set naming `email-campaign-engine@campaigns` and `lookalike-audience-builder@adtech`. The investigator can therefore name *exactly which processors were on notice* and when. Consent Invariant 9 (revocation non-retroactivity) and the Audit Trail seal establish the withdrawal record was not altered or back-dated. If a named processor continued after `revoked_at`, that is that processor's compliance failure — this composition's records prove the withdrawal was recorded, propagated, and enumerated; whether each named processor *acted* on it is the processor's obligation, signalled but not performed by this composition. The propagation event is the rebuttal to "we were never told."

**Breach or incident forensics — which subjects had withdrawn consent during the compromise window, and was any withdrawal record altered.** An incident investigator is given a window and must reconstruct which consents were Granted versus Revoked during it and whether any withdrawal or its propagation set was tampered with. The investigator replays each consent's `consent.granted`, `processing.registered`, and `consent.revoked` events in Event Log insertion order (reached transitively through Audit Trail), determining each consent's state and downstream-binding set at the window's bounds, then runs `AuditTrail.verify_record` against representative events in each seal's coverage to bound any tampering window. Invariant 3 is load-bearing: a `consent.revoked` event whose `affected_scopes` was silently shrunk to hide a processor that should have stopped is foreclosed by the append-only, sealed log — the propagation set is part of the hashed event payload, so an alteration breaks the seal. The newest events in the Audit Trail's unsealed tail carry Event Log per-event immutability but become seal-verifiable only after the next seal cadence; until then a tail event returns `failed-verification(unsealed)`, so the integrity bound on the most recent withdrawals is the substrate's unsealed-tail policy (a tighter `seal_cadence` narrows it).

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when an external auditor, given the three indexes and the Consent, Permissions, consent retention and Audit Trail substrate stores, can clear the checks below without recourse to source code, runbooks or developer narration. Every enumeration of audit events below runs through the log read, never through a query the substrate routes to Reverse Index.

### Conformance checks

```
Check 1.1: An auditor MUST find [Processing Permitted] AND the consent check agreeing over a sample of subject references AND purposes (Invariant 1.1).
Check 1.2: An auditor MUST find no two governed consents in Granted carrying one subject reference AND one purpose (Invariant 1.3).
Check 2.1: An auditor MUST find a grant closure for EVERY governed consent whose escalation instant PRECEDES the audit (Invariant 2.1).
Check 2.2: An auditor MUST resolve EVERY Consent record carrying no grant event to EXACTLY ONE OF a young record, an aged record, an orphan under compensation, an escalated grant orphan, a write-ownership finding (Invariant 2.1).
Check 2.3: An auditor MUST find a passing verification for EVERY grant event (Invariant 2.2).
Check 3.1: An auditor MUST find no consent id two propagation events carry (Invariant 3.2).
Check 3.2: An auditor MUST find EVERY propagation event's propagation set equal to the registered set at the event's boundary (Invariant 3.3).
Check 3.3: An auditor MUST find a passing verification for EVERY propagation event (Invariant 3.1).
Check 3.4: An auditor MUST resolve EVERY revoked Consent record carrying no propagation event to EXACTLY ONE OF a young record, propagation history purged, an orphan under compensation, an escalated orphan, a write-ownership finding, a conformance failure (Invariant 3.5).
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
Check 7.2: An auditor MUST find no consent id resolved from the Consent store on a subject index miss (Composition state 11).
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

WHY:
**The gate agrees, and one Granted record per pair** (Check 1.1 and 1.2): the auditor re-runs both reads over a sample and confirms agreement, and a second Granted record for a pair among governed consents is a failure against the pair exclusion — a Granted record with *no* grant event is Check 2.2's, not this.

**Every Consent record is read, and the one with no grant event is named** (Check 2.1 and 2.2; 2026-08-30-d). *Governed* is the record the composition's grant write made, and with the write surface reserved it is every record of the instance, so the store is enumerated rather than quantified over an undeclared field. A record with no grant event resolves to exactly one class, **between the reconciliation's two edges**: below the bound it may belong to an invocation still between its writes; past the horizon its grant event was lawfully destroyed and its absence is destruction, never a bypass — the key entries answer for it; an escalation of kind grant makes it an escalated orphan, never a bypass; otherwise, past the window, it is the write-ownership finding. A grant intent carries no consent id and cannot be joined to a record; it narrows the class by actor and window as a signal available at once, never a proof — surplus grant intents from ordinary refusals are the normal case.

**The propagation set is checked at the intent's boundary** (Check 3.1, 3.2 and 4.1; 2026-08-26-a, 2026-08-30-b). At the event's own position the check would brand a correct compensation a failure, since a registration permitted against the Revoked consent may land in the recovery window; at the intent it is one point for clean and compensated withdrawals, and where the event names candidates the boundary is the earliest. **A Revoked record with no event is not a failure by itself** (Check 3.4): Invariant 3 admits it as a reachable partial, so the class list carries the at-quiescence and recovery-window qualifier Check 2.2 carries, and a record no withdrawal intent pairs is the direct revoke — reported, never compensated. **The closure is bounded** (Check 3.5 through 3.8): a compensating event within the widened window — its recording instant is the substrate's and the revocation instant this seam's, so the allowance widens the window and the comparison bounds the closure rather than deciding it — or an escalation naming an observed cause; an escalation naming none fails, and a deployment that escalates every orphan and compensates none fails there. The compensating event's set is checked at the intent's boundary exactly like a clean one's — the reason a compensation can be verified rather than merely accepted. The inequality is read from the configuration: an undeclared window leaves the reconciliation no terminus, and a failing sum breaches on every orphan.

**A purged registration is never a missing one** (Check 4.2; the section titled *Lawful destruction is answered before absence* in `pressure-testing.md`): its payload is gone and its sequence number survives, so the auditor confirms the position precedes the boundary and counts the pair consistent, its payload unverifiable rather than failed; the purged downstream entry answers for the pair.

**The retention exists and is never Purged** (Check 5.1 and 5.2), including where Purge Eligible reads true; a deployment reading Purge Eligible as permission to purge fails both. Whether the configured policy meets the regime's proof period is External check 5.

**The join is the intent event id and the order is the sequence** (Check 6.1 through 6.4). The re-consent path makes one operator granting one subject one purpose repeatedly ordinary use, so a join by actor, subject and purpose would let one stale intent satisfy the check for any number of later grants. A compensating event compares the intent's actor with the operator its payload carries, never its attesting recovery identity, against each candidate where it names several. The order is read from the sequence number: on a withdrawal the two instants are equal by construction, and on a grant the outcome carries none. **An intent with no outcome is not a failure** — the Consent store says which case: the orphan, another invocation's withdrawal, a revoke that never landed, the index anomaly, or no pairing at all.

**The horizon and its limits** (Check 7.1 through 7.4). The horizon must be the longer because the traversal is the only permitted rebuild source; a violation is a conformance failure whose admitted failure is the live one — a Granted consent un-withdrawable. The check cannot run for consents whose grant events already aged out, whose absence is indistinguishable from a bypass — the detector's own convergence past the horizon; where the consent retention period sits behind a host policy this composition does not resolve, the comparison is external and what stays checkable here is the absent fallback (Check 7.2). Every verification clause is qualified twice (2026-08-26-d): a purged event is lawfully destroyed and its payload-dependent clauses unverifiable, answered before any composition-side comparison; an event in the substrate's unsealed tail is pending, not failed, and a tighter seal cadence narrows the window.

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

WHY:
None of these is clearable from the composition's records. **Completeness of the registered set** (External check 1) needs the deployment's own inventory — the registration-completeness obligation. **Cessation** (External check 2): the propagation event is notice, not enforcement; that a named processor deleted a derived audience is the processor's record. **Quality of consent** (External check 3): the grant, the grantor, the purpose and — through the metadata — the consent-form version are recorded; whether the banner was non-deceptive and the consent unbundled is a UX (user experience) and legal question. **The authority behind a permission** (External check 4) is the Permissions-administration layer's — [Attributed Permissions Admin](./attributed-permissions-admin.md). **The proof period** (External check 5) needs the policy registry and the regulatory floor. **Basis selection** (External check 6): whether an activity should have rested on a different basis — a Customer Due Diligence obligation under [Customer Onboarding](./customer-onboarding.md) rests on Article 6(1)(c) — is outside this composition.

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

WHY:
**The composition signals; processors act** (Non-goal 1). [Withdraw Consent] records that a withdrawal occurred and names what relied on the consent; whether withdrawal triggers deletion of derived data under GDPR Article 17(1)(b) is the downstream processor's obligation, signalled by the propagation event. A deployment needing guaranteed cessation wires a downstream-action engine or a [Notification Fanout](./notification-fanout.md) to the named processors — a composing peer, not a constituent.

**Collection and basis are upstream** (Non-goal 2 and 3). The banner, form or verbal capture produces the inputs [Record Consent] records. GDPR Article 6 names six lawful bases and this composition governs only consent, 6(1)(a): processing resting on legitimate interest, contract necessity or legal obligation is not gated here and must not be — a customer cannot withdraw the basis for anti-money-laundering processing under [Customer Onboarding](./customer-onboarding.md), which rests on 6(1)(c). **Preference is not consent** (Non-goal 4): communication preferences that are not a lawful basis belong to [Message Preference / Personalization](../atoms/message-preference.md) under [Preference-Aware Notification Fanout](./preference-aware-notification-fanout.md); where a toggle *is* the basis — an opt-in to a marketing channel — it is this composition's. The boundary is whether the toggle is the lawful basis for processing or the shape of processing already lawful.

**Expiry does not propagate, and the asymmetry is designed and bounded** (Non-goal 5; 2026-08-27-c). Expired ends the lawful basis exactly as revocation does, but revocation is an *act* — an attributed transition at a commit instant, giving the propagation event a moment, an actor and an invocation to follow — while expiry is a stored deadline lapsing. Consent derives it at read time, and its own edge case admits either a lazy write inside the read or an eager background writer; neither is a transition this composition invokes or observes, so there is nothing for a propagation event to follow in order, and an expiry event here would need a scheduler the composition does not own and a clock guard its seam forbids. The basis still ends enforceably: the gate refuses expired from the first check past the deadline, so a gate-consuming processor stops at its next check — the freshness the single-surface obligation already carries for every answer. A deployment needing affirmative expiry notice wires a scheduled sweep above the composition — reading expiring consents, joining the downstream index for the registered processors, notifying them — whose records, not this composition's, carry that trail.

**The subject's surface is upstream** (Non-goal 6 and 7). Article 7(3) requires withdrawal be as easy as grant, which is a property of the data-subject-facing surface; [Withdraw Consent] is the operator-side recording, permission-gated, and a self-service deployment wires the subject's own request to an actor holding [Consent Revoke] above the composition, so the subject's absolute right is honored without granting the subject internal permissions. The subject reference is never authenticated here. **Denied attempts are unrecorded** (Non-goal 8; Action wiring 3). **Destruction is another composition's** (Non-goal 9): whether a consent record may ever be destroyed after its floor — under storage limitation, or an erasure request — is for a composition that performs destruction, [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md) being the one that would, and answering it is a touch to Consent, not to this pattern.

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the Event Log sequence as the order of an intent AND the intent's outcome.
Clock semantics 2: The composition MUST NOT compare an intent's instant with an outcome's instant.
Clock semantics 3: A comparison of the composition's instant with another seam's instant MUST NOT decide a write alone.
```

WHY:
The invocation's one reading stamps every instant it writes (Capability requirement 28), so on a withdrawal the intent instant, the revocation instant passed to Consent and the propagation event's instant are equal by construction, and their order cannot be read off the stamps. On a grant the grant event carries no instant of its own and the grant instant is Consent's, taken at its own seam — the atom takes no clock input, so the composition cannot make those two readings one and does not claim to. Either way the sequence number is the only order that spans an intent and its outcome (Clock semantics 1 and 2). The composition compares its own instant with another seam's in two places — the grant pairing window and the widened window of Check 3.5 — and each narrows a candidate set or bounds a closure; neither decides a pairing, a finding, a compensation or a refusal alone (Clock semantics 3). The gate reads no clock at all. Clock quality — honesty, monotonicity, skew against the constituents' seams — is the deployment's, bounded where the composition compares by the clock offset allowance. Where withdrawal instants carry legal force, as Article 7(3) disputes do, a Trusted Timestamping pattern binds Event Log insertion order to wall time; absent it insertion order is authoritative and instants advisory, so a revocation instant earlier than a registration instant it succeeds in the log is a skew signal in the injected readings, not a reordering of the record. Ids are minted at the constituents' seams — the consent id by Consent, the retention id by Retention Window, the event id by Audit Trail — and the composition introduces none of its own.

### Concurrency

```
Concurrency 1: The consent exclusion MUST span a withdrawal's set derivation through the withdrawal's outcome AND retries.
Concurrency 2: The consent exclusion MUST bind EVERY registration, withdrawal AND reconciliation write on one consent.
Concurrency 3: The pair exclusion MUST span a grant's consent check through the grant write.
Concurrency 4: [Processing Permitted] MUST NOT take an exclusion.
```

WHY:
Two withdrawals of one consent, or a registration racing a withdrawal, resolve under the consent exclusion; at the constituent the first revoke wins and the second observes already-revoked. A registration landing between a withdrawal's derivation and its intent would sit before the intent in the log and outside the set — the exact state Check 3.2 flags — so the span is a hard conformance requirement and an implementation that cannot hold it does not conform (Concurrency 1 and 2). The pair exclusion is the grant-side mirror, needed because Consent's own Concurrency entry says concurrent grants for one pair *are not a race* in the atom and produce independent records (Concurrency 3). The gate is read-only and excluded: its one read is authoritative and a stale one fails safe — it can yield a spurious refusal, never a false permitted (Concurrency 4).

### Retention asymmetry

```
Retention asymmetry 1: The consent retention instance MUST NOT EQUAL the Retention Window instance inside Audit Trail.
Retention asymmetry 2: The composition MUST NOT call the purge on the consent retention instance.
```

WHY:
Two Retention Window instances govern two different things, and conflating them is a reference ambiguity: the consent retention instance holds one placement per consent record — how long the controller must be able to produce it — and the instance inside the substrate governs the audit events under the audit retention policy (Retention asymmetry 1). The composition calls only the placement, so Retention Window's purge-family refusals never surface at this boundary (Retention asymmetry 2). **The asymmetry runs one way**: consent records are never removed (Consent Invariant 8) while their events purge at the audit horizon, and the placement is not wasted — it puts the proof period on the record as a records-checkable value, makes the floor structural rather than procedural, and is the hook a composition that *does* perform destruction would need. The wording is deliberate throughout: a consent retention is *purge-eligible* when its proof period elapses, never purged, and the consent record is never removed.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are its five actions — the four administration actions [Record Consent], [Register Processing], [Withdraw Consent] and [Read Consent History], and the read-only gate [Processing Permitted]; the [Affected Scopes] a propagation event enumerates and the [Processing Scope] each binding names; the four scopes it defines for its Permissions instance, [Consent Grant], [Consent Revoke], [Consent Register Processing] and [Consent Read]; and the gate's refusal, [Not Permitted]. The propagation guarantee is a structural property, not a datum. The deployment settings keep their wire spellings in configuration — `consent_record_retention_policy_ref`, `audit_trail_retention_policy`, `compensation_window`, `reconciliation_cadence`, `outcome_write_latency`, `administration_completion_bound`, `application_actor_ref`, `application_credential`, `index_durability`, `outcome_retry_attempts`, `per_key_serialization`, `clock_offset_allowance`, `field_length_cap`, `registrations_cap`, `intent_candidates_cap`, `event_id_width` — and the indexes their own in an implementation, `consent_to_downstream`, `consent_to_retention`, `consent_to_subject_purpose`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the reconciliation; a deployment; a regulated deployment; an auditor; a caller; a processing system; a processing activity; an invocation; a holder; an administration action; a validated grant; an admitted grant; a checked grant; a committed grant; a placed grant; a landed grant; a resolved registration; a validated registration; a landed registration; a resolved withdrawal; a validated withdrawal; an admitted withdrawal; a committed withdrawal; a landed withdrawal; a validated history read; a fetched history read; a landed history read; a validated gate query; a derivation; a rebuild.

Term records: the grant intents, grant events, registration events, withdrawal intents, propagation events, access events, recovery intents and escalations the composition records through the audit write — each an Event Log event carrying one action reference below — the Consent records it writes through the grant and revoke writes, the consent retentions it places, and the three indexes' entries.

Term record verbs: EQUAL, add, adopt, alert, answer, append, attest, authenticate, bind, call, capture, carry, change, claim, classify, clear, commit, compare, compensate, compose, decide, declare, derive, destroy, disclose, duplicate, examine, expose, fall, find, gate, govern, identify, inherit, inject, inspect, interpret, join, key, leave, model, name, normalize, open, order, pair, pass, perform, persist, pre-check, proceed, process, provision, re-derive, re-read, reach, read, rebuild, record, release, remove, report, resolve, retry, run, select, serve, set, span, stamp, start, store, substitute, supply, take, triage, write.

Term value sets: action reference = consent.grant_intended | consent.granted | processing.registered | consent.withdrawal_intended | consent.revoked | consent.history-read | consent.recovery_intended | consent.propagation_escalated. The rest are declared where the section that owns each declares it: withheld state, placement refusal, position, kind, cause.

Term bounds: administration completion bound (administration_completion_bound), outcome retry attempts (outcome_retry_attempts), outcome write latency (outcome_write_latency), field length cap (field_length_cap), registrations cap (registrations_cap), intent candidates cap (intent_candidates_cap), event id width (event_id_width), clock offset allowance (clock_offset_allowance), compensation window (compensation_window), audit horizon (audit_trail_retention_policy).

Term cadences: reconciliation cadence (reconciliation_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive atoms, consent retention instance, log read, record read, audit write, verification, grant write, revoke write, consent check, consent read, permission check, retention placement, consent namespace, consent id, downstream index, retention index, subject index, index entry, downstream entry, retention entry, subject entry, binding, pair, repeat registration, registration event id, live index entry, purged index entry, purged downstream entry, key entry, purged key entry, live downstream entry, live key entry, downstream rebuild, grant rebuild, consent validity flag, retention policy reference, consent retention period, audit retention policy, audit horizon, regulated deployment, compensation window, reconciliation cadence, outcome write latency, administration completion bound, liveness sum, outcome retry attempts, retry span, field length cap, registrations cap, intent candidates cap, event id width, maximal envelope, clock offset allowance, consent exclusion, pair exclusion, exclusion, holder, recovery identity, index durability, processing system, processing activity, seam, now, payload string, caller string, subject reference, purpose, processor reference, reason, actor reference, credential, opaque reference, registered set, propagation envelope, intent, outcome, single write, later write, pre-append step, retention step, position, consent history, withheld state, expiry, metadata, administration action, action's scope, grant intent, grant event, registration event, withdrawal intent, propagation event, access event, intent event id, intent instant, registration instant, revocation instant, grantor, revoker, retention id, placement refusal, record count, propagation set, validated grant, admitted grant, checked grant, committed grant, placed grant, landed grant, resolved registration, validated registration, landed registration, resolved withdrawal, validated withdrawal, admitted withdrawal, committed withdrawal, landed withdrawal, validated history read, fetched history read, landed history read, validated gate query, invocation, owed outcome, index-anomaly finding, reconciliation, young record, aged record, unpropagated record, ungranted record, orphan, unpaired record, withdrawal candidate count, grant skew, grant instant, pairing window, candidate count, intent candidates, earliest candidate's boundary, intent reference, recovery intent, compensating event, compensated grant, recovery flag, operator, kind, planned writes, escalation, cause, uncompensable cause, escalation instant, attempt count, binding repair, governed consent, query's instant, grant closure, event's boundary, surfacing bound, paired unpropagated record, propagation closure, lifecycle, consent retention, retention closure, passing verification, orphan under compensation, escalated grant orphan, escalated orphan, propagation history purged, write-ownership finding, widened window, processing inventory, consent capture, downstream cessation, delivery preference, withdrawal surface, denied attempt.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index classification. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. record_action, read_record, verify_record, payload cap, attestation id width, unsealed tail, step-2, step-3, step-4, invalid-credential, invalid-request, recording-failure, verified, failed-verification, unsealed, purged, compensation-window, Retained, Purged, Erasure Tombstone, Reverse Index: Audit Trail. grant, revoke, check, read, granted, revoked, expired, not-known, already-revoked, already-expired, invalid-request, storage-failure, invalid-query, Granted, Revoked, Expired: Consent. permitted, denied: Permissions. place_under_retention, purge, invalid-policy, policy-not-found, storage-failure, Retained, Purged, Purge Eligible, Policy Registry: Retention Window. read: Event Log. Processing Register: forthcoming.

Term composing patterns: [Customer Onboarding](./customer-onboarding.md); [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md); [Preference-Aware Notification Fanout](./preference-aware-notification-fanout.md); [Notification Fanout](./notification-fanout.md); [Message Preference / Personalization](../atoms/message-preference.md); [Defensible Retention](./defensible-retention.md); [Capability-Backed Sharing](./capability-backed-sharing.md); [Attributed Permissions Admin](./attributed-permissions-admin.md).

#### Record Consent

The composition action that records a data subject's consent for a purpose under an authorized operator's authority: it checks the operator's [Consent Grant] permission, records a `consent.grant_intended` event — the write that verifies the operator's credential, before anything commits — then, under per-pair serialization, refuses already-granted where the subject already holds a Granted record for the purpose (single-active-grant, Invariant 1.3), calls `Consent.grant`, places the consent record under its retention floor, and audits the grant (`consent.granted`, carrying the intent event's id). Returns the consent_id.

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

The complete set of downstream processing bindings ([Processing Scope] plus processor) registered against a consent, derived from the `processing.registered` events at withdrawal time (the map supplying only the entries whose named event the substrate reports Purged), bounded by `registrations_cap`, and recorded on the `consent.revoked` propagation event. Its completeness is Invariant 3.3: the enumeration is exactly what was registered against the consent, never silently shrunk — whether every real processing activity registered is the deployment's obligation, so a withdrawal's downstream impact is a records-alone fact.

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

- **GDPR Article 6(1)(a)** — consent as a lawful basis for processing. This composition's [Processing Permitted] gate is the structural form of the before-processing basis check; a permitted result is the records-alone evidence that a valid consent existed at processing time.
- **GDPR Article 7(1)** — the controller bears the burden of demonstrating consent. This composition's `consent.granted` events plus the retained Consent records (held under the consent-record Retention Window — Invariant 6) are the demonstrability surface; a withdrawn consent is retained as proof the basis once existed.
- **GDPR Article 7(3)** — withdrawal must be as easy as grant, and withdrawal does not affect the lawfulness of prior processing. [Withdraw Consent] is the recording surface; the data-subject-facing ease is upstream (Non-goal 6); non-retroactivity is inherited from Consent Invariant 9.
- **GDPR Article 17(1)(b)** — right to erasure when consent is withdrawn and no other basis applies. The `consent.revoked` event's `affected_scopes` is the notice that triggers downstream erasure obligations; this composition signals, the downstream processor erases (Non-goal 1).
- **GDPR Article 30** — records of processing activities must name purposes and legal bases. This composition's Consent records (purpose, `granted_at`) plus the `processing.registered` bindings supply the Article 30 documentation surface for consent-based processing.
- **CCPA / CPRA** (the California Consumer Privacy Act and its amending California Privacy Rights Act) — right to opt out of sale/sharing and opt in for sensitive personal information. This composition's [Record Consent] / [Withdraw Consent] are the opt-in/opt-out recording surfaces; the propagation event names the processors a do-not-sell signal must reach.
- **HIPAA §164.508 (Authorization)** — required Authorization elements (purpose, expiration, right to revoke) map to the Consent record fields; this composition adds the operator-authority gate (Permissions) and the tamper-evident audit the regulated context requires.
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
last gate: 2026-08-30 — third gate, fresh reader, under the frozen rules — 8 foundational corrected in-round, 7 refining and 2 rhetorical routed (7 refining and 4 rhetorical also corrected in-round, one of them at the closure check); 2026-08-27 — authentication-precedence gate, fresh reader — 5 foundational (3 corrected in-round, 2 routed and since closed), 9 refining/rhetorical routed (2 since closed); Final Critique 7's 7 refining and 3 rhetorical partly still open

open:
- 2026-08-29-a · refining · formal · the model's compensation action carries no identity, no intent record, and no age bound; the twin predates the scan's two edges → extend the model with the service-identity compensation behind `consent.recovery_intended` and the bounded scan
- 2026-08-30-k · refining · formal · the model has the invocation as one atomic writer with no terminus and no second leg; single-active-grant, the third scan leg and the escalation record are unmodelled → extend it with the invocation and the scan as two processes over one act, the bound as the yield point (with 2026-08-29-a)
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/propagate-consent-revocation-downstream.md`.

- **2026-09-24 — Rewritten in GRACE lang v0.61; nineteen of twenty-one open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole, its per-key serialization split into the consent exclusion and the pair exclusion because the grammar owns the noun *section* — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces; invariant numbers 1 through 8 unchanged; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and three Edge cases families, the two-instance retention entries joining `Retention asymmetry` as its fourth spec. Choices the page left open, each decided by a standing rule: *governed* defined as the record the composition's grant write made — every record of the instance under the reserved write surface — and Invariant 6 split into a floor and a liveness closure (2026-08-30-d); Consent's not-known at the revoke relayed as not-known with an index-anomaly finding rather than as a recording failure (2026-08-26-g — *make all things mean one thing*: recording-failure is a write that did not land); the gate's exposure and the retention policy reference's validation stated as rules (2026-08-30-f, 2026-08-26-b); the bound measured from the seam reading (2026-08-30-h); the knob collisions stated in the terms (2026-08-30-g); the pairing-key deviation declared and no refusal outcome added (2026-08-30-e — *as simple as possible without losing fidelity*); the expiry asymmetry restated on what this composition observes, not on how Consent expires (2026-08-27-c). **One defect fixed in this pass**: the invocation retried its grant event under the pair exclusion while the reconciliation compensated grant orphans under the consent exclusion, so the two could both land a grant event for one consent; the invocation now takes the consent exclusion once the consent id exists, and a grant candidate set whose retention policy references disagree is escalated rather than chosen (Action wiring 16; Reconciliation 29). *Over:* the prose's step lists, a lettered case list, and revision-history prose. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.
- **2026-08-30 — One Granted record per pair, one writer per act, the set derived from the events, the escalation a record, the pairing honest about whose clock stamped each side.** *Chose:* single-active-grant enforced at [Record Consent] step 4 by `Consent.check` under a per-`(subject_ref, purpose)` section, refusing already-granted, stated as Invariant 1(c) and tested by check 4, with the suppression claim made conditional on it; an in-invocation retry bounded by `outcome_retry_attempts` and a scan that takes the per-consent_id section for every consent it touches, so the invocation and the scan never both land a propagation event; `affected_scopes` derived at [Withdraw Consent] step 4 from the `processing.registered` events (the map supplying only its past-horizon entries) with a third scan leg repairing lost bindings; the grant-side scan pairing by actor, subject and purpose inside a symmetric window under a declared `clock_offset_allowance`, narrowing to candidates and escalating a zero-match as an unresolved grant orphan rather than concluding a bypass; check 6's case (v) requiring a *paired* intent, exact by pass-through, so a zero-match on the withdrawal side is the bypass signature; `consent.propagation_escalated` as composition-written audit content under the service identity, carrying the observed cause, in place of "an open compliance finding"; `registrations_cap`, `field_length_cap` and `intent_candidates_cap` with an envelope inequality checked at instance start, the digest withdrawn; the liveness inequality written out with `outcome_write_latency`; `recording-failure(intent | outcome)` on the two signatures that straddle a commit; "atomically" and "together or not at all" replaced at every site by revoke-then-event, ordered, bijective at quiescence modulo compensation; the log read declared once as the substrate's sequence-range read filtered composition-side; the purged answer counted as consistent ahead of any composition-side comparison; and `consent_to_downstream`'s past-horizon half re-homed from Erasure Tombstone to a Processing Register atom *(forthcoming)*, the two key-shaped maps staying with the tombstone; at the closure check, each map element carrying its registration `event_id` so that *past the horizon* is decided by `read_record` answering Purged and never by a timestamp, with check 3 carved out for a purged registration whose surviving `sequence_number` still precedes the boundary; checks 1 and 7 reading `kind: grant` escalations as escalated orphans, never as bypasses; `event_id_width` declared rather than attributed to the substrate; `per_key_serialization` declared as the instance capability the sections rest on, with lease semantics — a lease exactly `administration_completion_bound` long whose expiry is the invocation's terminus, the invocation re-taking the section before any pre-check and writing nothing after it has yielded — and `outcome_retry_attempts × outcome_write_latency ≤ administration_completion_bound` so the counted terminus fits the bound; and the scan's tie-break withdrawn for candidates never chosen. *Over:* a gate keyed per pair over a propagation keyed per consent_id with nothing holding the two to one record; "retry until it lands" beside a scan starting at the bound; a map read as gate input with "rebuild where its integrity is in doubt"; a bypass verdict landed on a comparison of two seams' stamps; an intent's existence standing in for its pairing; an escape branch living in no store; a digest no consumer can read; a bare token on both sides of the commit; atomicity language over two irreversible writes; a tombstone asked to carry a register; a past-horizon membership with no clock-free test; an escalation with no reader; a critical section attributed to the host and named nowhere, and a lost lease that could resume between a scan's look and its append. *Because:* Consent evaluates the latest grant and declines uniqueness for itself, so a composition that keys its two halves differently must supply it or contradict its own suppression claim; two compensators over one act land two outcomes the seal then protects; a short list is not an observable miss; a stamp another seam wrote can differ from this one's by a sign the bound does not have; a check that cannot see the escalation cannot count it; a set that only grows has no unreachable cap; a caller who cannot tell intent from outcome re-runs a committed act; a retention state is the substrate's to answer and a timestamp is not that answer; and a section nobody declared, with a lease nobody bounded, is a second writer waiting for a stall (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen with its tells for uses — with §*A derived index is trustworthy only where a miss is observable*, §*Intents pair with outcomes*, §*Recovery commits under a declared service identity* and §*A derived index splits at the horizon*).
- **2026-08-29 — The scan is bounded at both edges, writes as the composition, and pairs by the records; the indexes are truth-bearing past the horizon.** *Chose:* a declared `administration_completion_bound` below which the reconciliation scan and checks 1 and 7 examine nothing, with the audit horizon as their upper edge; every compensating write attested under a declared service identity behind a `consent.recovery_intended` record, the operator carried in `data`, the intent paired on `intended_at = revoked_at` and `actor_ref = revoked_by` (candidates named where undecidable); both grant-side orphan shapes resolved, the unretained one by re-running the placement from the intent's own retention_policy_ref; every `record_action` transcription carrying `(step)`, the `step-4` arm proceeding as landed and invalid-request never unreachable; and each index's past-horizon half classified truth-bearing under a declared `index_durability`, extraction-pending against Erasure Tombstone. *Over:* an unbounded scan attesting compensations as the absent operator, and "the map is not rebuildable" as the last word on the horizon. *Because:* an unbounded scan compensates in-flight withdrawals beside their own propagation events and reads lawfully purged history as orphans; a compensation the operator did not make cannot be attested as theirs; and a consent record outlives any audit horizon by Consent's own Invariant 8, so the only thing that keeps an old consent withdrawable is the index entry, which must therefore be declared for what it is (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*, *A transcribed rejection arm keeps its payload*, *A derived index splits at the horizon*).
- **2026-08-27 — Authentication happens at this composition's boundary, before the consent state changes.** *Chose:* [Record Consent] and [Withdraw Consent] open with an intent record whose substrate attestation verifies the credential; invalid-credential is a clean pre-state refusal. *Over:* the Action wiring preamble's declaration that the check "cannot be pre-empted at this composition's boundary" and belongs to a deployment pre-check. *Because:* the declaration was false — the composition reaches the same Actor Identity surface at whatever point it chooses to write — and a declared deployment obligation is the answer the methodology refuses.
- **2026-08-27 — Invariant 3 is safety plus liveness, with the propagation-set boundary on the intent event.** *Chose:* the revoke precedes the propagation event; the reachable partial (Revoked, unpropagated) is an accountability gap surfaced and compensated within `compensation_window`; check 2's set boundary is the withdrawal's own `consent.withdrawal_intended` event. *Over:* "commit together or not at all" under a host transaction. *Because:* Consent's revocation is immutable once committed and the substrate's append cannot be withdrawn, so neither member was ever enlistable; what makes the pair sound is the order.
- **2026-08-27 — A consent record is never destroyed by this composition; its retention is Retained for life.** *Chose:* the consent-record Retention Window instance marks the proof-period floor and never reaches `Purged`; check 5 requires `Retained` unconditionally. *Over:* admitting a lawful purge here, or scoping Consent's Invariant 8 to the atom's own surface. *Because:* a composition may not weaken a constituent invariant by paraphrase, and Retention Window defines `Purged` as the destruction Consent forbids.

NOTE: End of Propagate Consent Revocation Downstream.
