---
title: Defensible Retention
parent: Conceptual Compositions
nav_order: 7
has_toc: true
toc: true
---

# Defensible Retention

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Defensible Retention makes record destruction provably lawful. It combines three patterns: Legal Hold, which records who ordered a record preserved and why; Retention Window, which records the minimum keep-period and blocks early deletion; and Audit Trail, the tamper-evident record that stamps and seals every decision.

The guarantee none of the three has alone is a gate that sits between checking for holds and actually deleting. Under the default strict mode, no record carrying an active hold is destroyed through this composition, however long ago its keep-period ended. A deployment may instead configure advisory mode, which records an externally-authorized override and proceeds; strict is the required posture for the regimes named below.

The gate is audited in both directions — an event when it allows a destruction, naming that no holds applied, and an event when it blocks one, naming which holds applied — so an auditor reads both halves of the gate's behaviour from the records rather than from a runbook.

Every destroyed record leaves three things behind: a destruction event naming what the hold store held at gate time, a retention record standing purged, and a tamper-evident seal once the seal cadence covers the event. Together they prove the destruction was lawful, attributed and unaltered — for as long as the audit records themselves are kept, which is the deployment's own ordering obligation rather than this composition's guarantee.

Its most common uses are financial records governance under SOX (Sarbanes-Oxley Act) §802, patient records under HIPAA (US Health Insurance Portability and Accountability Act) §164.530(j), electronically stored information subject to FRCP (Federal Rules of Civil Procedure) Rule 37(e) litigation holds, and broker-dealer communications under SEC (US Securities and Exchange Commission) Rule 17a-4. Any system that must prove it did not destroy records while a legal or regulatory hold was active — and that it did eventually destroy them once the hold was released and the retention window had closed — is a candidate for this composition.

---

## Intent

A record's life under a regulated system follows two governance tracks that must coexist without one silently overriding the other. The first is the *retention clock*: a record must be kept for a minimum period mandated by statute, regulation, or contract — seven years under SOX, six under HIPAA, three for some broker-dealer communications under SEC Rule 17a-4. The second is the *preservation directive*: when litigation is anticipated, when a regulator opens an investigation, when an audit freeze is ordered, the normal retention clock stops being the governing rule and the obligation shifts to *keep this record until the legal matter resolves, regardless of what the schedule says.*

Neither Retention Window nor Legal Hold alone enforces that coexistence. Retention Window enforces the clock — it prevents purge before retention until and records the eligibility transition. Legal Hold records the preservation obligation — who placed the hold, why, and when. Neither enforces the other's constraint: a retention whose window has elapsed is eligible for `RetentionWindow.purge` with no knowledge of any hold, and a record under an active hold is recorded as preserved while the Legal Hold atom intercepts nothing. The gate that enforces *no purge while any active hold covers a record* belongs to the composition, and this composition is that gate.

Audit Trail provides the third leg: every hold placement, every release, every retention placement and every purge decision is attribution-stamped, retention-bounded and tamper-evident. A destruction is defensible because the evidence trail — who held the record, who released the hold, who purged it, under what policy, at what time — is itself a regulated, integrity-protected record an auditor reads without developer narration.

This is a composition, not a new primitive. Legal Hold, Retention Window and Audit Trail are unchanged; the composition is the wiring that makes them coherent as one retention-governance surface. It wires the hold gate over the *business* record set. It does **not** wire the gate [Audit Trail](./audit-trail.md)'s edge case *Legal hold suspension of purge* names — a Legal Hold gate over the audit instance's own `purge_event` cascade, so that the events proving a hold are not destroyed while the hold is live — and an earlier revision's claim to have retired that debt is withdrawn (`Non-goal 20` through `Non-goal 23`).

---

## Composes

- **[Legal Hold](../atoms/legal-hold.md)** — the preservation directive over a record.
- **[Retention Window](../atoms/retention-window.md)** — the policy-bounded lifetime of a business record.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate every decision is recorded through.

```
Composes 1: EXACTLY ONE Legal Hold instance MUST serve the composition.
Composes 2: EXACTLY ONE Retention Window instance MUST serve the composition.
Composes 3: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 4: The composition MUST NOT change a constituent's spec.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST read Audit Trail as a substrate PER the section titled Substrate composition invocation in `execution-contract.md`.
Composes 7: The composition MUST NOT hold an instance of a constituent Audit Trail reaches.
Composes 8: The business retention instance MUST NOT govern an audit event.
Composes 9: The composition MUST reach a constituent through the constituent's declared surface.
Composes 10: The composition MUST NOT read a constituent's store beside the constituent's declared read.
Composes 11: The composition MUST NOT call Audit Trail's purge_event.
Composes 12: The composition MUST read the substrate's events by an open-ended sequence range.
Composes 13: The composition MUST select an event in the composition's own code.
Composes 14: The composition MUST NOT query the substrate by a payload predicate.
Composes 15: The composition MUST attest an invocation's audit record under the calling actor's credential.
Composes 16: The composition MUST attest a sweep's audit record under the service identity.
Composes 17: The composition MUST NOT attest a sweep's audit record under a calling actor's credential.
Composes 18: The composition MUST NOT supply the injected now to a constituent.
```

Term composition: this pattern's wiring of [Legal Hold](../atoms/legal-hold.md), [Retention Window](../atoms/retention-window.md) and the [Audit Trail](./audit-trail.md) substrate — the five actions, the hold gate, the two indexes and the sweep.

Term constituents: [Legal Hold](../atoms/legal-hold.md), [Retention Window](../atoms/retention-window.md), [Audit Trail](./audit-trail.md).

Term business retention instance: the one [Retention Window](../atoms/retention-window.md) instance this composition wires over business records — distinct from the instance [Audit Trail](./audit-trail.md) carries for the substrate's own events.

Term service identity: application_actor_ref and application_credential — the composition's own registered actor and credential, and the attested emitter of every record the sweep writes.

WHY:
Composes 6 and Composes 7 name the substrate relation. [Audit Trail](./audit-trail.md) is a composition, not an atom, so Event Log, Actor Identity, Tamper Evidence and the audit instance's own Retention Window are reached *through* it and this composition holds no instance of any of them — the section titled Substrate composition invocation in `execution-contract.md` is what makes that a declared topology rather than an accident. Composes 8 is the one place the corpus's *declared multi-instance topology* clause bites twice in one spec: two Retention Window instances exist here, one governing business records and one governing the audit events that record their governance, and the whole of this composition's evidence story turns on which of the two a sentence means.

Composes 15 through 17 split attestation by who is present. Every write an action makes inside its own invocation is attested by the calling operator, whose credential the substrate verifies inside the write. The sweep runs when that operator is gone and their credential was never persisted, so a sweep write attested as theirs would be a false attribution; it is attested under the service identity with the human named in the payload instead.

Composes 12 through 14 declare the read capability exactly, because the substrate declares no secondary index. Every selection this spec describes — the rebuilds, the sweep's comparisons, the acceptance checks — is enumerate-and-filter in composition code over an open-ended sequence range. A payload-predicate query is the forthcoming Reverse Index pattern's shape, and a deployment may compose one over the trail as an instance optimization without changing what any procedure here computes.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store a record-to-retentions index.
Composition state 2: The composition MUST store a retention-to-record index.
Composition state 3: An admitted placement MUST add the placement's retention to the record-to-retentions index.
Composition state 4: An admitted placement MUST add the placement's retention to the retention-to-record index.
Composition state 5: An admitted purge MUST remove a purged retention from the record-to-retentions index.
Composition state 6: An admitted purge MUST remove a purged retention from the retention-to-record index.
Composition state 7: An admitted purge MUST leave a pending sibling in the record-to-retentions index.
Composition state 8: The composition MUST remove a record ref carrying no retention from the record-to-retentions index.
Composition state 9: The record-to-retentions index MUST stand as a derived index PER the section titled Composition state in `execution-contract.md`.
Composition state 10: The retention-to-record index MUST stand as a derived index PER the section titled Composition state in `execution-contract.md`.
Composition state 11: The composition MUST NOT store a truth beside a constituent's store.
Composition state 12: The rebuild MUST read a surviving placement event for an index entry.
Composition state 13: The rebuild MUST read Retention Window's store for an entry a purged placement event covers.
Composition state 14: The rebuild MUST NOT read a purged placement event's payload.
Composition state 15: The rebuild MUST NOT read a trail miss as an absent retention.
Composition state 16: The store-sourced rebuild MUST admit a retention the composition did not place.
Composition state 17: A refusal resting on the store-sourced rebuild MUST NOT stand as a scope statement.
Composition state 18: The composition MUST NOT rest a purge admission on an index.
Composition state 19: The composition MUST read the sibling set from Retention Window's store.
Composition state 20: An index MUST stand outside an action's atomicity set.
Composition state 21: The composition MUST read a missing index entry as a rebuild trigger.
Composition state 22: The composition MUST NOT claim a cross-constituent consistency for an index.
Composition state 23: The rebuild MUST drop an index entry whose retention's retention state EQUALS purged.
Composition state 24: The composition MUST report a dropped entry carrying no record_purged event as a bypass finding.
Composition state 25: The composition MUST NOT read a stale index entry as a bypass alone.
Composition state 26: The record-to-retentions index AND the retention-to-record index MUST agree.
Composition state 27: EVERY retention MUST cover EXACTLY ONE record.
Composition state 28: A record MAY carry a retention beside another retention.
Composition state 29: EVERY hold MUST name EXACTLY ONE record.
Composition state 30: A record MAY carry a hold beside another hold.
Composition state 31: A record MAY carry no hold.
Composition state 32: A hold MUST NOT rest on a retention.
```

Term record-to-retentions index: record_to_retentions — the composition's index from a record ref to the retentions whose retention state EQUALS retained over the record — the auditor's first query surface and a read-path convenience, never the gate's input.

Term retention-to-record index: retention_to_record — the composition's index from a retention id to the record the retention covers, with the retention's retention until and purge deadline read back from Retention Window's declared Outputs.

Term audit horizon: the age past which the audit instance has destroyed an event's payload, set by the instance's audit_trail_retention_policy.

Term surviving placement event: a retention_placed event whose payload the audit instance has not destroyed.

Term purged placement event: a retention_placed event whose payload the audit instance has destroyed.

Term rebuild: the composition's named regeneration of an index — select this composition's placement events over an open-ended sequence range, take a surviving event's record ref and retention id, read Retention Window's store for an entry a purged placement event covers, and drop every retention the store reports purged.

Term sibling set: the retentions whose retention state EQUALS retained over one record beside the named retention, read from Retention Window's store.

Term pending sibling: a sibling set member whose own purge has not landed.

WHY:
The two indexes carry no truth of their own, and the rebuild is what makes that claim checkable rather than asserted. Every fact either holds lives in a constituent: the `{record_ref, retention_id}` binding is immutable audit content on a retention_placed event **and** a field of Retention Window's own retention record, and retention until and purge deadline are that record's declared Outputs.

**The rebuild's totality is bounded, and the bound has to be on the page because one of these indexes is read by an auditor and the other is not read by the gate at all.** The traversal reads retention_placed payloads, and the substrate destroys a payload in its entirety at the audit horizon. What survives a purged event is its `event_id`, `sequence_number` and `recorded_at`, plus the attestation's `action_ref`, actor_ref and `attested_at` — reachable through the destruction record's `(event_id, attestation_id)` pair the substrate's purge cascade captures before the delegation runs. What does **not** survive is this composition's binding: it lived only in Event Log's `data`, which the cascade destroys whole. So past the horizon the traversal can still recognize a purged event as this composition's, and cannot read the binding — and an index entry needs the binding, not the recognition (Composition state 12 through 14).

Composition state 13 is the second declared source and the reason the split costs nothing where it matters. Retention Window's store carries the same binding as constituent record content rather than as audit payload, and its retained and purged sets are queryable through the atom's declared read. What the store cannot supply is the *placed-through-this-composition* filter the audit traversal supplies, so the store-sourced rebuild **over-includes** — and over-inclusion on a destruction gate can only refuse (Composition state 16, Composition state 17). `Invariant 2`'s scope claim is what degrades; `Invariant 9`'s protection is not, because `Composition state 18` and `Composition state 19` keep the gate reading the store in every state rather than reading an index at all.

Composition state 24 and Composition state 25 name both causes of a stale entry rather than one. A direct atom-level `RetentionWindow.purge` leaves the index naming a retention the store has purged; so does a crash between this composition's own destruction and its index cleanup. The rebuild reaps both identically, and only the audit trail tells them apart — a drop carrying a record_purged event is this composition's own crash, a drop carrying none is the bypass signal `Check 3.4` reads.

Composition state 27 through 32 declare the two relations the gate actually evaluates, with their cardinality and their modality. The retention relation is one-to-one on the retention side and one-to-many on the record side, and both sides are mandatory — a retention with no record is not a retention. The hold relation is many-to-one and **optional on the record side**, which is the modality that matters: a record may carry no hold, which is the ordinary case the gate admits, and a hold may name a record no retention covers, which is the *hold placed after destruction* case `Invariant 6` answers. Composition state 32 states the independence the two atoms' freestanding status rests on — neither relation constrains the other, and the composition is the only place they meet.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The host MUST supply one invocation_id at the seam PER state-changing invocation.
Deleted: Capability requirement 3. Execution Contract Logic confinement 3 owns it.
Capability requirement 4: The transition MUST NOT mint an invocation_id.
Deleted: Capability requirement 5. Execution Contract Logic confinement 3 owns it.
Capability requirement 6: The composition MUST NOT accept an invocation_id as an input.
Capability requirement 7: The composition MUST NOT mint a retention id.
Capability requirement 8: The composition MUST NOT mint a hold id.
Capability requirement 9: The composition MUST NOT mint an event_id.
Capability requirement 10: A deployment MUST configure the audit instance with an audit retention policy.
Capability requirement 11: The evidence floor MUST NOT EXCEED the audit horizon.
Capability requirement 12: A deployment MUST declare the longest hold the deployment admits.
Capability requirement 13: IF a deployment admits an unbounded hold THEN the deployment MUST wire a horizon alert.
Capability requirement 14: A deployment MUST set a field cap PER payload field.
Capability requirement 15: A field cap MUST NOT EXCEED the audit instance's payload_cap.
Capability requirement 16: A deployment MUST set the hold ids cap.
Capability requirement 17: A deployment MUST provision the service identity as a registered actor.
Capability requirement 18: A deployment MUST rotate the service identity's credential.
Capability requirement 19: A deployment MUST set the retention completion bound.
Capability requirement 20: A deployment MUST set the compensation window.
Capability requirement 21: A deployment MUST set the reconciliation cadence.
Capability requirement 22: A deployment MUST disclose the audit write latency.
Capability requirement 23: A deployment MAY start an instance ONLY IF the compensation window EXCEEDS the closure floor.
Capability requirement 24: A deployment MUST set the hold check mode.
Capability requirement 25: The hold check mode MUST stand as one instance-wide value.
Capability requirement 26: An action MUST NOT read a per-record hold check mode.
Capability requirement 27: A deployment under Rule 37(e) of the Federal Rules of Civil Procedure MUST NOT set advisory.
Capability requirement 28: A deployment under Securities and Exchange Commission Rule 17a-4 MUST NOT set advisory.
Capability requirement 29: A deployment under the Sarbanes-Oxley Act MUST NOT set advisory.
Capability requirement 30: A deployment needing two hold check modes MUST run two instances over disjoint records.
Capability requirement 31: A deployment MUST resolve a policy ref at Retention Window's seam.
Capability requirement 32: The composition MUST NOT reconcile two policies.
Capability requirement 33: The composition MUST NOT store an override authorization.
Capability requirement 34: A deployment MUST serialize a hold check and a purge over one record ref.
Capability requirement 35: A deployment MUST serialize a hold placement and a purge over one record ref.
Capability requirement 36: The deployment MUST declare the clock offset allowance.
```

Term seam: the composition's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects one clock reading and one invocation_id here.
Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term invocation_id: the id the seam allocates for one state-changing invocation; an intent and the outcome matched to it carry the same one (Capability requirement 2, Reconciliation 6).

Term intended_at: the instant an intent records (Action wiring 8).

Term transition: the composition's evaluation of one call against the constituents, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term evidence floor: the longest retention policy in use on the business retention instance taken with the longest hold the deployment admits — what audit_trail_retention_policy must outlast — the age a placement event's payload must survive to.

Term closure floor: the retention completion bound taken with the reconciliation_cadence and the audit write latency — the longest interval in which the sweep can close an open marker.

Term retention completion bound: retention_completion_bound — the deployment's declared maximum duration between an invocation's intent record and the invocation's outcome record, read against the injected now the intent carries.

Term hold check mode: hold_check_mode — strict | advisory.

WHY:
Capability requirement 11 is the ordering the whole evidence story rests on, and it is an obligation rather than the advice an earlier revision gave. The audit trail is not only the proof that a destruction was lawful; it is the **rebuild source** for the record ref binding, so an audit horizon shorter than a live business retention destroys the placement evidence of exactly the long retention the gate exists to honour, and destroys it *before* that retention elapses. That is the shorter-versus-longer failure `Invariant 9` forbids, reappearing one layer up in the records. The floor is stated over **record lifetime and not policy duration**, because a hold suspends purge indefinitely while the events proving the hold die at an age measured from their own `recorded_at` — which is why Capability requirement 12 and Capability requirement 13 exist at all, and why a deployment that cannot bound its holds owes the audit-side gate this composition declines to wire (`Non-goal 20` through `Non-goal 23`).

Capability requirement 23 is the liveness arithmetic written out rather than abbreviated. An open marker is invisible to the sweep until the retention completion bound has elapsed; the next run is at most a cadence later; the closure lands an audit write latency after that. *Cadence no longer than the window* — the form the corpus carried before the sweep gained a lower edge — is satisfied by a deployment that breaches the window on every marker, so the three terms are named and the comparison is strict.

Capability requirement 25 through 30 fix the mode's scope, which is the question every reader of an advisory-mode deployment asks. The knob is one instance-wide value set at deployment, so the mode governing any purge is decided by which instance was called and is observable from that instance's configuration record rather than from the call. A deployment needing both postures runs two instances over disjoint populations; there is no per-record mode to read and no call that carries one.

Capability requirement 33 is the honest limit of the advisory record. The composition records the override *fact* and owns no record of the authority behind it — a court order is a document, not a state machine this layer holds. A deployment needing in-system override-authorization records composes an **Override Authorization** pattern *(forthcoming)* ahead of an advisory-mode purge; until that lands, the bare marker is the honest record of everything this layer knew.

Capability requirement 34 and Capability requirement 35 are one serialization obligation seen from both ends. The gate reads the hold store and the destruction lands a step later, so a hold placed between the two leaves a record destroyed under a hold that existed — the race `Concurrency 1` and `Concurrency 2` name. Serializing the gate alone does not close it: the placement is the other writer, and a deployment that serializes only the purge path has left the hazard open on the path a hold arrives by.

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank record ref.
Primitive policy 2: The composition MUST answer invalid-request for a blank policy ref.
Primitive policy 3: The composition MUST answer invalid-request for a blank actor_ref.
Primitive policy 4: The composition MUST answer invalid-request for a blank placed by.
Primitive policy 5: The composition MUST answer invalid-request for a blank released by.
Primitive policy 6: The composition MUST answer invalid-request for a blank reason.
Primitive policy 7: The composition MUST answer invalid-request for a blank credential.
Primitive policy 8: The composition MUST answer invalid-request for a blank hold id.
Primitive policy 9: The composition MUST answer invalid-request for a supplied blank case ref.
Primitive policy 10: The composition MUST answer invalid-request for a malformed supplied placed at.
Primitive policy 11: The composition MUST answer invalid-request for a malformed supplied released at.
Primitive policy 12: IF a payload field EXCEEDS the field's cap THEN the composition MUST answer invalid-request.
Primitive policy 13: The composition MUST NOT call a constituent BEFORE judging the boundary predicate.
Primitive policy 14: The composition MUST size the largest record an invocation writes against the field caps.
Primitive policy 15: The composition MUST size a compensation record against the field caps.
Primitive policy 16: The composition MUST compare an opaque input byte-exact.
Primitive policy 17: The composition MUST NOT normalize an opaque input.
Primitive policy 18: The composition MUST NOT store a credential.
Primitive policy 19: The composition MUST NOT answer a credential.
Primitive policy 20: The composition MUST truncate an answered hold id list PER the hold ids cap.
Primitive policy 21: A truncated hold id list MUST carry the list's true count.
Primitive policy 22: The composition MUST NOT read a truncated hold id list as an empty hold check result.
```


Term boundary predicate: the composition's own validation of an input at an action's boundary, judged before any constituent call.

Term opaque input: record ref | policy ref | actor_ref | placed by | released by | hold id | retention id | case ref.

WHY:
Primitive policy 14 and Primitive policy 15 are why a substrate invalid-request over a payload is a deployment fault here and never a live arm. The composition sizes the **largest** record an invocation can write — the outcome, not the intent, and the compensation record a sweep would write for it, which is larger than either because it carries the acting human and the candidate list besides. Sizing the intent alone is the failure mode the corpus names: the intent fits, the constituent commits, and the outcome that would bind it cannot be written. The set-valued fields resolve to the same bound rather than to caps of their own — the sibling set is enumerated before the outcome is sized, and the hold id list is truncated with its count carried (Primitive policy 20, Primitive policy 21).

Primitive policy 18 and Primitive policy 19 inherit [Legal Hold](../atoms/legal-hold.md)'s and credential-handling discipline from the constituent side and restate it here only because this composition **holds** the material briefly on its way to the substrate. The constituent's guarantee is about the constituent's store; these two are about this composition's own hands.

### Identity

```
Identity 1: The composition MUST compare a record ref byte-exact.
Identity 2: The composition MUST NOT fold a record ref's case.
Identity 3: The composition MUST NOT normalize a record ref.
Identity 4: The composition MUST NOT trim a record ref.
Identity 5: A renamed record MUST NOT inherit the prior record ref's hold.
Identity 6: A deployment needing an identity continuity MUST discharge the continuity ahead of a call.
Identity 7: A deployment MAY place a hold again under a new record ref.
Identity 8: A deployment MAY canonicalize a record ref ahead of a call.
```

WHY:
The gate evaluates equality on record ref and nothing else, so record ref is byte-identity at this boundary. The consequence a deployment has to hear is Identity 5: a rename — a URI migration, a tenant move, a schema change — produces a new identity, and the holds do not follow it. Legal Hold's own validation requires a non-blank value and normalizes nothing, so there is no layer below this one where the rename could be absorbed.

### Audit arm

```
Audit arm 1: The composition MUST retry a recording-failure carrying step-2.
Audit arm 2: The composition MUST retry a recording-failure carrying step-3.
Audit arm 3: The composition MUST NOT retry a recording-failure carrying step-4.
Audit arm 4: The composition MUST read a recording-failure carrying step-4 as a landed record.
Audit arm 5: The composition MUST read a landed record back by the invocation_id.
Audit arm 6: The composition MUST alert on a landed record carrying no retention.
Audit arm 7: The composition MUST answer invalid-credential for an invocation record the substrate refuses on a credential.
Audit arm 8: The composition MUST read an invalid-credential on a sweep record as a deployment fault.
Audit arm 9: The composition MUST alert on an invalid-credential on a sweep record.
Audit arm 10: The composition MUST NOT retry an invalid-credential answer in a loop.
Audit arm 11: The composition MUST NOT read an invalid-request answer as unreachable.
Audit arm 12: The composition MUST read a retention-sourced invalid-request as a landed record.
Audit arm 13: The composition MUST read a cap-sourced invalid-request as an owed record.
Audit arm 14: The composition MUST alert on an invalid-request answer.
Audit arm 15: The composition MUST NOT retry an invalid-request answer in a loop.
```

Term landed record: an audit record the substrate has appended and attested, whatever the substrate then answered.

Term owed record: an audit record this composition must write and the substrate has not appended.

WHY:
One arm rule per answer the substrate can give, stated once and cited at every record_action site, because a site claiming an arm unreachable would be wrong about this substrate. The steps are [Audit Trail](./audit-trail.md)'s own: record_action fails at step 2 with nothing committed, at step 3 with an orphan attestation, and at step 4 with **the event already appended** — so the three arms are not one arm, and a composition that retried them alike would append a second destruction record under the failure the retry was written for.

invalid-request is the arm a reader most wants to call unreachable and cannot. The substrate raises it for an over-cap payload — which Primitive policy 14 forecloses for validated inputs — and for its own retention-configuration faults, which no caller input controls. **The two sources land on opposite sides of *is a record owed*** (Audit arm 12, Audit arm 13): on the retention source the event is already appended and attested, because the substrate places retention after the append, so nothing is owed and the unretained event belongs to the substrate's own reconciliation; on the cap source nothing was appended and the record stays owed until the deployment corrects the cap.

invalid-credential splits by who is writing, which is the one place this composition's arms differ from [Login](./login.md)'s over the same substrate. An invocation record is attested under the **caller's** credential, so a refusal is the caller's own pre-state answer and belongs to the caller (Audit arm 7). A sweep record is attested under the service identity, so a refusal there is the deployment's own credential fault — pageable, never a caller outcome and never a loop (Audit arm 8 through 10).

### Action wiring

```
place_record_under_retention(record_ref, policy_ref, actor_ref, credential)
  answers retention_id
  refuses invalid-request | invalid-credential | storage-failure | recording-failure(position)

place_hold(record_ref, placed_by, credential, reason, optional case_ref, optional placed_at)
  answers hold_id
  refuses invalid-request | invalid-credential | storage-failure | recording-failure(position)

release_hold(hold_id, released_by, credential, reason, optional released_at)
  answers released
  refuses invalid-request | invalid-credential | not-known | already-released | storage-failure | recording-failure(position)

purge_eligible()
  answers the eligibility tuples

purge_record(retention_id, actor_ref, credential)
  answers ok
  refuses invalid-request | invalid-credential | not-known | not-eligible | under-active-retention | under-legal-hold(hold_ids, count) | hold-check-unavailable | storage-failure | recording-failure(position)
```

Term position: intent | outcome — the record a write lands: the intent or the outcome.

```
Action wiring 1: The composition MUST NOT record an intent BEFORE the boundary predicate passes.
Action wiring 2: The composition MUST NOT make a committing call BEFORE recording an intent.
Action wiring 3: An intent MUST carry the invocation_id.
Action wiring 4: An outcome MUST carry the invocation_id.
Action wiring 5: A gate record MUST carry the invocation_id.
Action wiring 6: An intent MUST carry the invocation's inputs.
Action wiring 7: An intent MUST NOT carry a constituent-minted id.
Action wiring 8: An intent MUST carry the injected now as intended_at.
Action wiring 9: An admitted placement MUST call Retention Window's place_under_retention with the record ref AND the policy ref.
Action wiring 10: An admitted placement MUST read the retention's retention until AND purge deadline from Retention Window's declared Outputs.
Action wiring 11: An admitted placement MUST record a retention placed outcome carrying the retention id, the record ref, the policy ref, the retention until AND the purge deadline.
Action wiring 12: An admitted placement MUST answer the retention id.
Action wiring 13: IF Retention Window answers invalid-policy THEN [Place Record Under Retention] MUST answer invalid-request.
Action wiring 14: IF Retention Window answers policy-not-found THEN [Place Record Under Retention] MUST answer invalid-request.
Action wiring 15: IF Retention Window answers invalid-request THEN [Place Record Under Retention] MUST answer invalid-request.
Action wiring 16: IF Retention Window answers storage-failure THEN [Place Record Under Retention] MUST answer storage-failure.
Action wiring 17: An admitted hold placement MUST call Legal Hold's place with the record ref, the placed by, the reason, the case ref AND the placed at.
Action wiring 18: An admitted hold placement MUST record a hold placed outcome carrying the hold id, the record ref, the reason, the case ref AND the placed at.
Action wiring 19: An admitted hold placement MUST answer the hold id.
Action wiring 20: IF Legal Hold answers invalid-request THEN [Place Hold] MUST answer invalid-request.
Action wiring 21: IF Legal Hold answers storage-failure THEN [Place Hold] MUST answer storage-failure.
Action wiring 22: The composition MUST NOT record a hold release intent BEFORE reading the hold through Legal Hold's read.
Action wiring 23: IF no hold EXISTS for the hold id THEN [Release Hold] MUST answer not-known.
Action wiring 24: IF the hold state EQUALS released THEN [Release Hold] MUST answer already-released.
Action wiring 25: An admitted hold release MUST call Legal Hold's release with the hold id, the released by, the reason AND the released at.
Action wiring 26: An admitted hold release MUST record a hold released outcome carrying the hold id, the reason AND the released at.
Action wiring 27: An admitted hold release MUST answer released.
Action wiring 28: IF Legal Hold answers not-known THEN [Release Hold] MUST answer not-known.
Action wiring 29: IF Legal Hold answers already-released THEN [Release Hold] MUST answer already-released.
Action wiring 30: IF Legal Hold answers invalid-request THEN [Release Hold] MUST answer invalid-request.
Action wiring 31: IF Legal Hold answers storage-failure THEN [Release Hold] MUST answer storage-failure.
Action wiring 32: [Purge Eligible] MUST read the retention-to-record index.
Action wiring 33: [Purge Eligible] MUST NOT answer a retention outside elapsed retention.
Action wiring 34: [Purge Eligible] MUST call Legal Hold's read with the record ref AND the active state PER answered retention.
Action wiring 35: [Purge Eligible] MUST answer the hold count PER answered retention.
Action wiring 36: IF Legal Hold refuses the read THEN [Purge Eligible] MUST carry the unavailable sentinel as the hold count.
Action wiring 37: [Purge Eligible] MUST NOT answer a zero hold count for an unreadable hold store.
Action wiring 38: [Purge Eligible] MUST answer the retention until AND the purge deadline PER answered retention.
Action wiring 39: [Purge Eligible] MUST order the answer by retention until, rising.
Action wiring 40: [Purge Eligible] MUST order two retentions sharing a retention until by retention id, rising.
Action wiring 41: [Purge Eligible] MUST NOT write.
Action wiring 42: [Purge Eligible] MUST NOT refuse a call.
Action wiring 43: A reader MUST NOT read [Purge Eligible]'s answer as a sibling statement.
Action wiring 44: The composition MUST NOT answer not-known for a purge BEFORE rebuilding the retention-to-record index.
Action wiring 45: IF the retention id IS NOT IN the retention-to-record index THEN [Purge Record] MUST answer not-known.
Action wiring 47: IF the sibling set carries a retention outside elapsed retention THEN [Purge Record] MUST answer under-active-retention.
Action wiring 48: A purge MUST call Legal Hold's read with the record ref AND the active state.
Action wiring 49: A purge MUST call Legal Hold's read whatever the named retention's eligibility.
Action wiring 50: IF Legal Hold refuses the read THEN [Purge Record] MUST answer hold-check-unavailable.
Action wiring 52: IF the hold check result stands non-empty AND the hold check mode EQUALS strict THEN a purge MUST record a purge blocked gate record carrying the hold check result.
Action wiring 53: IF the hold check result stands non-empty AND the hold check mode EQUALS strict THEN a purge MUST answer under-legal-hold carrying the hold ids AND the count.
Action wiring 54: IF the hold check result stands non-empty AND the hold check mode EQUALS strict THEN a purge MUST NOT call Retention Window's purge.
Action wiring 55: IF the hold check result stands non-empty AND the hold check mode EQUALS advisory THEN a purge MUST record the hold override.
Action wiring 56: IF the hold check result stands non-empty AND the hold check mode EQUALS advisory THEN a purge MUST NOT record a purge blocked gate record.
Action wiring 57: IF the named retention IS NOT IN the elapsed retentions THEN a purge MUST answer not-eligible.
Action wiring 58: An admitted purge MUST call Retention Window's purge with the retention id.
Action wiring 59: An admitted purge MUST call Retention Window's purge PER sibling set member.
Action wiring 60: An admitted purge MUST record a record purged outcome carrying the retention id, the record ref, the purged retention ids, the hold check result, the hold override AND the injected now as purged at.
Action wiring 61: An admitted purge MUST mark a purged sibling purged in the purged retention ids.
Action wiring 62: An admitted purge MUST mark a pending sibling pending in the purged retention ids.
Action wiring 63: An admitted purge MUST answer ok.
Action wiring 64: IF Retention Window answers not-retained for the named retention THEN a purge MUST answer not-known.
Action wiring 65: IF Retention Window answers not-known for the named retention THEN a purge MUST answer not-known.
Action wiring 66: IF Retention Window answers retention-period-not-elapsed for the named retention THEN a purge MUST answer not-eligible.
Action wiring 67: IF Retention Window answers storage-failure for the named retention THEN a purge MUST answer storage-failure.
Action wiring 68: IF Retention Window answers storage-failure for a sibling THEN a purge MUST mark the sibling pending.
Action wiring 69: The composition MUST remove a purged retention from an index whatever the outcome record's answer.
Action wiring 70: The composition MUST alert on a destroyed record carrying an owed record.
Action wiring 71: A yielded invocation MUST NOT retry an owed record.
Action wiring 72: The sweep MUST own a yielded invocation's owed record.
Action wiring 73: A caller MUST read a not-known on a re-invoked purge as a committed destruction.
Action wiring 74: The composition MUST read an invalid-query answer from Legal Hold's read as the composition's own defect.
Action wiring 75: The composition MUST answer hold-check-unavailable for a hold store fault outside Legal Hold's read contract.
Deleted: Action wiring 46. Composition state 19 owns it.
Deleted: Action wiring 51. Invariant 1.3 owns it.
```

Term intent: the record_action call naming what an invocation is about to do, written before any committing call — retention_placement_intended | hold_placement_intended | hold_release_intended | purge_intended.

Term outcome: the record_action call naming what an invocation did — retention_placed | hold_placed | hold_released | record_purged.

Term gate record: the purge_blocked_by_hold record a strict-mode refusal writes at the gate — a self-standing record, neither an intent nor an outcome.

Term committing call: `RetentionWindow.place_under_retention` | `RetentionWindow.purge` | `LegalHold.place` | `LegalHold.release` — a constituent call that writes outside the audit instance.

Term admitted placement: a [Place Record Under Retention] call whose boundary predicate passed and whose intent landed.

Term admitted hold placement: a [Place Hold] call whose boundary predicate passed and whose intent landed.

Term admitted hold release: a [Release Hold] call whose boundary predicate passed, whose named hold's hold state EQUALS active and whose intent landed.

Term admitted purge: a [Purge Record] call whose boundary predicate passed, whose sibling set carries no retention outside elapsed retention, whose hold check admitted the destruction and whose intent landed.

Term elapsed retention: a retention whose retention until does not exceed the injected now — the eligibility predicate, derived at read time and never stored.

Term hold check result: what Legal Hold's read answered at the gate — empty, or the blocking hold ids with the blocking count.

Term hold override: the marker a record purged outcome carries when the hold check result stands non-empty under advisory mode, and only then.

Term unavailable sentinel: unavailable — the one non-integer value a hold count admits — what [Purge Eligible] answers for a retention whose hold store could not be read, and what a reader treats as hold-blocked rather than as zero.

Term purged retention ids: the named retention and every sibling set member a record purged outcome names, each marked purged or pending.

Term sweep: the reconciliation leg `Reconciliation 1` through `Reconciliation 24` state.

WHY:
Action wiring 1 and Action wiring 2 are the whole authentication story, and they are two rules rather than one because they order three things, not two. The commit-free checks come first — a malformed argument, an unknown id, a released hold, a live sibling, an unreadable hold store — so a premature call leaves nothing in the trail at all. The intent comes next, and it is where the caller's credential is verified, because the substrate validates it inside record_action against the registry's material for the supplied actor. The committing call comes last. An invalid-credential is therefore always a pre-state refusal with nothing committed and nothing destroyed, which is `Invariant 10`, and the intent is simultaneously the recovery marker `Reconciliation 5` reads.

Action wiring 44 and Action wiring 45 keep a rebuild between an index miss and a refusal. The index is rebuild-on-miss by classification, and a not-known answered from a lost entry would report a live retention as absent — the one reading of a derived index the corpus forbids outright.

Action wiring 49 is the sentence a cheapest-compliant implementer would delete. The hold check runs whether or not the named retention's window has elapsed, so a record under an active hold cannot be destroyed through this composition even when every clock says it could be. Deleting the rule would leave a gate that only runs on the path where it is least needed.

Action wiring 52 through 56 are the four combinations stated as rules rather than as a table: strict with an empty result destroys and records the empty result; strict with a non-empty result refuses and records the gate firing; advisory with an empty result is strict's path exactly, hold override absent; advisory with a non-empty result destroys and records the override. The gate record is what makes the *firing* visible rather than only the passing, and `Check 1.5` reads it.

Action wiring 61, Action wiring 62 and Action wiring 68 carry the sibling discipline into the outcome. `RetentionWindow.purge` destroys the **record**, not the named retention alone, so a sibling left retained over a destroyed record would be listed purge-ready by [Purge Eligible] and blockable by a hold placed afterwards — one record reading as both destroyed and preserved. Every sibling is purged in the same invocation and the outcome names each with its own disposition; a sibling whose own write failed stands pending and belongs to `Reconciliation 19`.

Action wiring 71 and Action wiring 72 give the owed outcome record exactly one writer. The invocation retries until the retention completion bound and then yields; past the bound the record is the sweep's, and the sweep's own pre-check runs under the act's key. Two writers on one act was reachable while both the out-of-band retry and the sweep owed the same record with nothing between them, and a second record_purged for one destruction is a record the trail then protects forever.

The four refusals this composition mints are worth telling apart, because three of them look alike to a caller and mean different things. [Under Legal Hold] says a preservation obligation covers the record and no clock overrides it. [Not Eligible] says the **named** retention is still running. [Under Active Retention] says the named retention has elapsed and a **sibling** has not, which is the one a caller reasoning about a single retention id does not expect. And [Hold Check Unavailable] says the gate could not be evaluated at all — a refusal about the instrument rather than about the record, and the only one a retry may clear without anything changing in either store.

Action wiring 73 is the caller's disambiguation and it is structural rather than token-borne. Re-invoking [Purge Record] after an outcome-position failure is destruction-safe, because Retention Window's terminal purged state refuses a second destruction — so a not-known on re-invocation says the destruction committed and its audit is owed, where a repeat of the intent-position arm says nothing has been destroyed yet.

### Wiring decision

```
Wiring decision 1: The composition MUST NOT destroy a record covered by an active hold under strict mode.
Wiring decision 2: The composition MUST destroy a record ONLY AFTER the gate read.
Wiring decision 3: The composition MUST record the hold check result on a destruction.
Wiring decision 4: The composition MUST record the hold check result on a refusal the gate fires.
Wiring decision 5: Legal Hold MUST NOT intercept Retention Window's purge.
Wiring decision 6: The composition MUST NOT release a hold the composition overrode.
Wiring decision 7: The composition MUST NOT compose a release reason for an overridden hold.
```

WHY:
*Principle:* Retention Window's own precondition prevents a premature purge and knows nothing of any hold; Legal Hold records a preservation obligation and intercepts nothing. Without the composition wiring the two checks together, a system can lawfully — from each atom's own perspective — destroy a record under an active litigation hold, which is a spoliation exposure structurally invisible to either atom alone.

*Likely objection:* why not have Legal Hold intercept `RetentionWindow.purge` directly, and skip the composition?

*Mechanism that resolves it:* Wiring decision 5 is the answer and it is about freestanding status rather than convenience. An atom that intercepted purge calls would have to know about retention records, storage layers and destruction mechanisms — absorbing concepts that belong to the composing layer. The atom records the obligation; the composition enforces it. Both constituents were written for this: [Legal Hold](../atoms/legal-hold.md)'s `Composition note 2` obliges a composing pattern to check a record's active holds at the purge surface, and [Retention Window](../atoms/retention-window.md)'s `Composition note 3` obliges one to own joint enforcement across retentions over one record. Both name this composition in their own words, and [Audit Trail](./audit-trail.md)'s *Legal hold suspension of purge* edge case names it for the business-record half of the gate — the audit-event half stays open and is `Non-goal 20` through `Non-goal 23`.

*Result:* the gate is structural under strict mode rather than a runtime check an operator can talk past inside this composition's surface — though not a gate a direct atom-level call cannot route around, which `Composition state 24` detects rather than prevents. An auditor reads both halves of the gate's behaviour from the records: `hold_check_result: empty` on every non-override destruction, and a gate record naming the blocking holds on every refusal. On an advisory instance the [Hold Override] marker is the third reading — a destruction that proceeded past a hold the records still name.

Wiring decision 6 and Wiring decision 7 are the advisory path's honest residue. An override destroys the record and leaves the blocking holds standing, so the hold store afterwards asserts preservation over a record that no longer exists. The composition declines to auto-release, because the authority whose order permitted the override is the same authority that decides whether the underlying obligation has ended, and a release reason this layer composed would be a sentence no one wrote. The discrepancy is observable in any joined read and is a dashboard signal the deployment surfaces.

### Reconciliation

```
Reconciliation 1: The sweep MUST run at an instance's start.
Reconciliation 2: The sweep MUST run PER reconciliation cadence.
Reconciliation 3: The sweep MUST NOT store a record of the sweep's own.
Reconciliation 4: The sweep MUST NOT examine a young marker.
Reconciliation 5: The sweep MUST read an intent carrying no outcome as an open marker.
Reconciliation 6: The sweep MUST match an intent to an outcome by the invocation_id.
Reconciliation 7: The sweep MUST NOT match an intent to an outcome by an input.
Reconciliation 8: The sweep MUST read the constituent store for the act an open marker names.
Reconciliation 9: IF the act did not commit THEN the sweep MUST close the open marker as intent_abandoned.
Reconciliation 10: IF another intent over the act carries a matched outcome THEN the sweep MUST close the open marker as intent_abandoned.
Reconciliation 11: IF the act committed AND the open marker stands as the act's only open marker THEN the sweep MUST emit a recovery outcome.
Reconciliation 12: IF several open markers name one committed act THEN the sweep MUST emit EXACTLY ONE recovery outcome.
Reconciliation 13: A recovery outcome MUST carry the earliest open marker's invocation_id.
Reconciliation 14: A recovery outcome MUST carry every candidate marker's actor_ref as attributed to.
Reconciliation 15: A recovery outcome MUST carry the recovery marker.
Reconciliation 16: A recovery outcome MUST carry the acting human's actor_ref.
Reconciliation 17: The sweep MUST NOT emit a recovery outcome BEFORE recording a recovery intent.
Reconciliation 18: The sweep MUST NOT make a committing call BEFORE recording a recovery intent.
Reconciliation 19: The sweep MUST call Retention Window's purge PER pending sibling.
Reconciliation 20: The sweep MUST serialize a leg over the act's invocation_id.
Reconciliation 21: The sweep MUST read the act's outcome again under the serialization.
Reconciliation 22: The sweep MUST NOT emit a recovery outcome for an act already carrying an outcome.
Reconciliation 23: The sweep MUST NOT examine an aged-out event.
Reconciliation 24: The sweep MUST read a constituent store's own state for an act an aged-out event names.
Reconciliation 25: The sweep MUST escalate an open marker the compensation window did not close.
Reconciliation 26: The sweep MUST NOT emit a datum no constituent store carries.
Reconciliation 27: IF a constituent store carries no datum a recovery outcome needs THEN the sweep MUST close the open marker as intent_abandoned.
```

Term open marker: an intent carrying no outcome under the intent's own invocation_id — an invocation that committed nothing, committed and failed to record, or died between the two.

Term young marker: an open marker whose intended_at stands within the retention completion bound of the injected now.

Term aged-out event: an event whose age exceeds the audit horizon.

Term recovery intent: the `retention.recovery_intended` record the sweep writes before a leg commits or re-emits, naming the leg and the plan.

Term recovery marker: the marker a recovery outcome carries so a reader tells a clean act from a recovered one.

Term recovery outcome: the outcome the sweep emits for a committed act whose own invocation did not record one.

Term intent_abandoned: the closing the sweep writes over an open marker whose act it does not recover (Reconciliation 9, Reconciliation 10, Reconciliation 27).

Term attributed to: the actor_ref of every candidate marker, carried by a recovery outcome (Reconciliation 14).

WHY:
The sweep is four comparisons and two edges. **Intent against outcome** is the general one: an intent with no outcome names an invocation whose fate the records do not yet state, and the sweep decides it from durable constituent state rather than from anything the dead invocation remembered. **Retention against trail**, **hold against trail** and **pending sibling against store** are the three particular ones, and only the last commits anything — which is why it alone is preceded by a recovery intent as well as attested under the service identity.

Reconciliation 6 and Reconciliation 7 are the pairing, and the pairing has to be exact because every state-changing action here is repeatable with identical arguments. Two operators can issue the same purge concurrently, and the page's own advice on a transient arm is to retry — so two intents can describe one act, and a sweep pairing by argument resemblance would re-emit a destruction record for an invocation that committed nothing. Where the records genuinely cannot say which intent committed the act, Reconciliation 12 through 14 say so rather than guess: one outcome, the earliest marker's id, every candidate named.

Reconciliation 4 and Reconciliation 23 are the two edges. Below the retention completion bound an invocation may still be between its committing call and its outcome, and a re-emission fired there lands a second outcome for one act — which the invocation_id match cannot prevent, because the invocation has not written yet. Above the audit horizon the intent's payload is destroyed, so there is no marker to read and the constituent store's own state is the only answer.

Reconciliation 26 and Reconciliation 27 are the re-derivability test stated as an obligation. A re-emitted outcome is built from what the constituent stores and the surviving trail still carry; where a datum lived only in the outcome that never landed, the sweep does not invent it — the marker closes as abandoned and the liveness arm degrades to *surfaced*, which is what the records can actually support.

---

## Composition-level invariants

Each emerges from the composition; none belongs to one constituent.

- **Invariant 1 — Hold-blocks-purge.**
  ```
  Invariant 1.1: IF an active hold covers the record AND the hold check mode EQUALS strict THEN the composition MUST NOT call Retention Window's purge.
  Invariant 1.2: IF an active hold covers the record AND the hold check mode EQUALS strict THEN a purge MUST answer EXACTLY ONE OF under-legal-hold, recording-failure, invalid-credential, invalid-request.
  Invariant 1.3: The composition MUST NOT read an unreadable hold store as an empty hold check result.
  Invariant 1.4: IF an active hold covers the record AND the hold check mode EQUALS strict THEN the record MUST NOT stand destroyed through the composition.
  ```
  WHY: this is the composition's defining emergent claim and neither constituent can carry it — [Legal Hold](../atoms/legal-hold.md) intercepts no purge and [Retention Window](../atoms/retention-window.md) consults no hold store. Invariant 1.2 enumerates every answer a blocked purge can give rather than the one a reader expects: the gate record is itself a substrate write, so its own arms are live, and each of the three lands the refusal without reaching a destruction. Invariant 1.3 is the cheapest-compliant reading closed — *unreadable therefore zero* is exactly the spoliation hole the gate exists to fill.
- **Invariant 2 — Retention coverage.**
  ```
  Invariant 2.1: EVERY record an admitted placement covered MUST carry a retention whose retention state EQUALS EXACTLY ONE OF retained, purged.
  Invariant 2.2: The composition MUST NOT gate a record no admitted placement covered.
  ```
  WHY: the scope claim is what the store-sourced rebuild degrades (`Composition state 17`). A refusal citing a sibling this composition did not place is correct as a refusal and wrong as a statement about this composition's own coverage, and an implementation reading from the fallback says which of the two it is answering.
- **Invariant 3 — Hold audit coverage.**
  ```
  Invariant 3.1: EVERY admitted hold placement MUST carry a hold placed outcome.
  Invariant 3.2: EVERY admitted hold release MUST carry a hold released outcome.
  Invariant 3.3: A hold placed outcome MUST carry the hold id, the record ref AND the placed by.
  Invariant 3.4: The composition MUST NOT claim a hold lifecycle reconstructible from an aged-out event.
  Invariant 3.5: The composition MUST NOT claim a tamper-evidence over the substrate's unsealed tail.
  ```
  WHY: both bounds are the substrate's and both were once asserted away. A hold that outlives the audit horizon keeps its Legal Hold record and loses its placement event's payload, so *the full lifecycle is reconstructible* is true within the horizon and false past it. And the newest events sit in the substrate's unsealed tail until the seal cadence covers them, so tamper-evidence over the tail is pending rather than in force.
- **Invariant 4 — Retention-decision audit coverage.**
  ```
  Invariant 4.1: EVERY admitted placement MUST carry a retention placed outcome.
  Invariant 4.2: EVERY admitted purge MUST carry a record purged outcome.
  Invariant 4.3: EVERY purge the gate refused under strict mode MUST carry a gate record.
  Invariant 4.4: A record purged outcome MUST carry the hold check result.
  Invariant 4.5: A gate record MUST carry the blocking hold ids AND the blocking count.
  Invariant 4.6: The composition MUST NOT record an outcome for a refusal outside the gate.
  ```
  WHY: Invariant 4.3 is the half a reader forgets. Recording only the passings would leave an auditor unable to tell a gate that never fired from a gate that was never wired, and the two event classes together are what make the gate's behaviour readable in both directions.
- **Invariant 5 — Audit completeness modulo the substrate's partial-attestation contract.**
  ```
  Invariant 5.1: EVERY outcome MUST follow an intent carrying the outcome's invocation_id.
  Invariant 5.2: An intent carrying no outcome MUST stand as an open marker.
  Invariant 5.3: The composition MUST NOT read an open marker as a conformance failure.
  Invariant 5.4: A gate record MUST NOT follow an intent.
  Invariant 5.5: EVERY admitted invocation MUST record EXACTLY ONE intent.
  Invariant 5.6: EVERY admitted invocation MUST record EXACTLY ONE outcome at quiescence.
  ```
  WHY: the pairing is this composition's own; the atomicity it sits on is the substrate's and arrives by citation rather than by restatement (`Composes 5`, `Composes 6`). An orphan attestation with no event-log entry is [Audit Trail](./audit-trail.md)'s own partial-attestation contract, which this composition inherits and does not re-derive. What it adds is the quiescence reading: Invariant 5.6 holds once the owed record lands, and the window before it is a hard alerting condition rather than a tolerated steady state (`Action wiring 70`).
- **Invariant 6 — Non-retroactivity of holds.**
  ```
  Invariant 6.1: A post-destruction hold MUST NOT change the destroyed record's retention.
  Invariant 6.2: A post-destruction hold MUST NOT remove the record purged outcome.
  Invariant 6.3: A reader MUST decide a hold's order against a destruction by the hold placed outcome's log position.
  Invariant 6.4: A reader MUST NOT decide a hold's order against a destruction by placed at.
  ```
  WHY: Invariant 6.1 rests on Retention Window Invariant 3 — purged is terminal — and Invariant 6.2 on Event Log Invariant 2, which grants the event is unchangeable for as long as the event exists. Invariant 6.3 and Invariant 6.4 are the disambiguation the backdating case forces: placed at is the caller's assertion of when an obligation arose and may legitimately predate anything, so the log position is the only evidence of which came first.
- **Invariant 7 — Multi-hold independence.**
  ```
  Invariant 7.1: IF an active hold covers the record THEN a release MUST NOT make the record purge-eligible.
  Invariant 7.2: [Purge Eligible] MUST answer a record carrying an active hold as hold-blocked.
  Invariant 7.3: [Purge Eligible] MUST answer a record carrying the unavailable sentinel as hold-blocked.
  Invariant 7.4: IF an active hold covers the record AND the hold check mode EQUALS strict THEN a purge MUST answer under-legal-hold.
  ```
  WHY: Legal Hold Invariant 4 gives the constituent half — concurrent holds are independent, and a release reaches no other hold. What this invariant adds is the aggregate consequence over the record, including the sentinel's reading: a hold count that could not be taken is hold-blocked, never zero, so the degraded answer and the refusal agree.
- **Invariant 8 — Defensible destruction.**
  ```
  Invariant 8.1: EVERY destroyed record MUST carry a record purged outcome naming the hold check result.
  Invariant 8.2: EVERY destroyed record MUST carry a retention whose retention state EQUALS purged.
  Invariant 8.3: A destroyed record's retention until MUST NOT EXCEED the retention's purged at.
  Invariant 8.4: A record purged outcome MUST carry a seal ONLY AFTER the seal coverage.
  Invariant 8.5: A reader MUST read an unverifiable partially-purged-coverage answer as unknown.
  Invariant 8.6: The composition MUST NOT claim a defensibility resting on an aged-out event.
  ```
  WHY: Invariant 8.3 is Retention Window Invariant 8 read from this side. Invariant 8.5 names the substrate's non-transient degradation rather than leaving it out: once one member of a seal's covering range is purged, the surviving members answer `unverifiable(partially-purged-coverage)` for the rest of their retained lives — unknown, not bad, and a reader told otherwise would read a lawful purge as tampering. Invariant 8.6 is the honest end of the claim: after the audit records themselves lawfully age out, defensibility rests on the deployment's archival practice.
- **Invariant 9 — Cross-retention joint enforcement.**
  ```
  Invariant 9.1: IF the sibling set carries a retention outside elapsed retention THEN the composition MUST NOT destroy the record.
  Invariant 9.3: The composition MUST NOT leave a sibling retained over a destroyed record.
  Invariant 9.4: A pending sibling MUST stand named in the record purged outcome.
  Invariant 9.5: The gate MUST NOT rest on the audit horizon.
  Deleted: Invariant 9.2. Composition state 19 owns it.
  ```
  WHY: this discharges the obligation Retention Window's `Composition note 3` assigns to a composing layer, and it discharges it in both directions — no destruction while a sibling lives, and no sibling left retained once the record is gone. `Composition state 19` and Invariant 9.5 are the pair that keeps it sound where the evidence has lapsed: a sibling set rebuilt from the trail would omit exactly the long retention whose placement event died first, so the gate reads the store in every state and the audit traversal supplies `Invariant 2`'s scope claim and nothing the gate depends on.
- **Invariant 10 — Authentication precedes destruction and commitment.**
  ```
  Invariant 10.1: The composition MUST NOT make a committing call BEFORE the caller's credential validates.
  Invariant 10.2: The composition MUST NOT destroy a record BEFORE the caller's credential validates.
  Invariant 10.3: The composition MUST NOT claim a presenter stands as the actor.
  Invariant 10.4: The composition MUST NOT claim a presentation binds to a channel.
  Invariant 10.5: The composition MUST NOT claim a presentation resists a replay.
  ```
  WHY: the intent is the mechanism — it is a record_action call, the substrate validates the credential inside it, and it stands before every committing call including the destruction (`Action wiring 1`, `Action wiring 2`). Invariant 10.3 through 10.5 bound what a successful validation establishes: material matching the actor's registered verifier was presented at that instant, and nothing more. A stolen credential validates. Deployments needing channel binding or replay resistance compose the atoms that provide them; this composition claims exactly what the substrate's attestation grants. `Check 5.1` is what makes the claim verifiable from the records rather than asserted.

---

## Examples

### Walkthrough — regulated bank under SOX §802 and FRCP Rule 37(e)

A multinational bank governs its general-ledger transaction records with this instance. The deployment sets `hold_check_mode = strict` and configures the audit instance with a nine-year policy against a seven-year business policy, so the evidence floor sits inside the audit horizon.

1. **Retention placed.** `place_record_under_retention("txn-2026-0441", "sox_7_year", "records_system", credential)`. The boundary predicate passes; a retention_placement_intended record lands carrying `invocation_id: inv-a1`, the two references and intended_at; `RetentionWindow.place_under_retention` answers `ret-0441` with `retention_until = 2033-05-10`; a retention_placed outcome lands carrying `inv-a1`, the retention and both deadlines. Returns `ret-0441`.

2. **Litigation anticipated.** Three years later: `place_hold("txn-2026-0441", "counsel_morgan", credential, "Litigation hold — anticipated class action re Q3 2026 operations", "matter-2029-morgan")`. Intent, then `LegalHold.place` answering `hold-0441-a`, then the hold_placed outcome. Returns `hold-0441-a`.

3. **Retention window elapses.** In 2033 `purge_eligible()` answers `ret-0441` with `hold_count = 1` — hold-blocked, not purge-ready. A records-management job calls `purge_record("ret-0441", "records_system", credential)` anyway. The sibling set is empty; the gate reads one active hold; the mode is strict, so a purge_blocked_by_hold gate record lands carrying `inv-b7`, the retention, the record and `{hold_ids: ["hold-0441-a"], count: 1}`, and the call answers `under-legal-hold(["hold-0441-a"], 1)`. **No intent record is written on this path** — the gate record precedes it and verifies the same credential — and nothing is destroyed.

4. **Litigation settles.** `release_hold("hold-0441-a", "counsel_morgan", credential, "Class action settled — May 2033")`. The pre-intent read finds the hold active; intent, `LegalHold.release`, hold_released outcome. Returns released.

5. **Purge proceeds.** `purge_eligible()` now answers `ret-0441` with `hold_count = 0`. `purge_record("ret-0441", "records_system", credential)`: the sibling set is empty, the gate reads no active hold, the named retention is elapsed, a purge_intended record lands carrying `inv-c2`, `RetentionWindow.purge` destroys the record, and a record_purged outcome lands carrying `inv-c2`, `purged_retention_ids: [{ret-0441, purged}]`, `hold_check_result: empty`, `hold_override: false` and `purged_at: 2033-05-15`. The two index entries are removed. Returns ok.

6. **SOX §404 audit.** The auditor walks `Check 1.1` through `Check 5.6` over the trail and the two constituent stores. The full arc reads: placement intent, placement, hold intent, hold, blocked purge, release intent, release, purge intent, purge. `verify_record` answers `verified` on each outcome the seal cadence covers. The auditor confirms that no destruction occurred while the hold was active, that the destruction landed inside the allowable window — retention until at or before `purged_at`, and `purged_at` below purge deadline — and that every act was attributed to a named actor whose credential the substrate verified before the act committed.

### A sibling retention blocks, then travels with the destruction

The same record acquires a second retention in 2030 under a policy transition: `place_record_under_retention("txn-2026-0441", "sox_10_year", "records_system", credential)` → `ret-0441-b`, `retention_until = 2036-05-10`. In 2033, with the hold released, `purge_record("ret-0441", …)` reads the sibling set from Retention Window's store, finds `ret-0441-b` outside elapsed retention, and answers under-active-retention — nothing destroyed, no intent written. In 2036 the same call finds both elapsed, destroys the record once, purges `ret-0441-b` in the same invocation, and records `purged_retention_ids: [{ret-0441, purged}, {ret-0441-b, purged}]`. Had the second purge answered storage-failure, the outcome would name it pending, `Check 3.3` would read it as an open obligation rather than a finding, and `Reconciliation 19` would retry it until the store reports it purged.

### Banking — concurrent regulatory investigations under SOX

A bank faces simultaneous DOJ (US Department of Justice) criminal and SEC civil enforcement, and both demand preservation of the same trading records. Two independent hold sets are placed under `case_ref: "doj-crim-2026-0011"` and `case_ref: "sec-enf-2026-0087"`. When DOJ closes, every `hold-doj-*` hold is released; `purge_eligible()` still answers the records hold-blocked with `hold_count = 1`, because `Invariant 7.1` makes releasing a subset no release at all. Only when the SEC holds are released do the records become purge-ready.

### Healthcare — HIPAA §164.530(j) records under HHS OCR investigation

HHS (the US Department of Health and Human Services) and its OCR (Office for Civil Rights, which enforces HIPAA) open a breach investigation while a hospital's patient encounter records sit under a six-year retention policy. Compliance places holds under `case_ref: "ocr-hipaa-inv-2026-0334"`. The six-year windows elapse during the investigation and `purge_eligible()` answers the affected records hold-blocked throughout. After the investigation closes, the holds are released and the records are purged in the next run. Each record's trail reads placement, hold, release, destruction — the arc an OCR auditor reads to confirm the preservation obligation was honoured.

### Broker-dealer — SEC Rule 17a-4 non-erasable records under FINRA examination

A broker-dealer places all business communications under a seven-year policy per SEC Rule 17a-4. A FINRA (Financial Industry Regulatory Authority) examination is announced and holds are placed on every in-scope record under `case_ref: "finra-exam-2026-0112"`. No in-scope record is purged during the examination. Afterwards the holds are released and the elapsed records are destroyed. The Tamper Evidence seal reached through the substrate is the write-once-read-many equivalent the rule's integrity requirement asks for, and the gate is what satisfies its non-premature-destruction half.

### E-discovery — FRCP Rule 37(e) preservation duty, disputed destruction

Opposing counsel moves for sanctions under FRCP Rule 37(e), claiming ESI (electronically stored information) was destroyed after the preservation duty arose. The defence reads every record_purged outcome in the disputed scope. Each either carries a `purged_at` predating the duty's trigger date, or carries `hold_check_result: empty` with no hold_placed outcome for that record earlier in the log. Where a hold was placed before a destruction, the log carries hold_placed ahead of any record_purged, and `purge_eligible()` at that time would have answered the record hold-blocked. `Check 1.3` and `Check 1.4` are the two the defence runs, and the spoliation question is answered structurally rather than by developer testimony.

### Advisory-mode override — court-ordered destruction superseding a hold

A pharmaceutical company keeps its general email population under an FRCP-exposed instance configured strict, which is never reconfigured. A separate federal court orders destruction of records containing trade-secret formulations of a discontinued product line, superseding the preservation duty in an unrelated matter. Because the mode is one instance-wide value (`Capability requirement 25`), the scoped population is handled the way `Capability requirement 30` prescribes: a second, disjoint instance is deployed with `hold_check_mode = advisory`, and the records in scope are placed under it from the start.

For each in-scope record, `purge_record(retention_id, "counsel_walsh", credential)` reads a non-empty hold check result, proceeds under advisory mode, destroys the record, and records a record_purged outcome carrying `hold_check_result: {hold_ids: [...], count: 1}` and `hold_override: true`. The blocking hold stays active: the composition does not release it (`Wiring decision 6`), because the court order narrowed one record's fate without ending the underlying obligation. The dashboard surfaces the discrepancy — an active hold over a destroyed record — and counsel decides separately whether to release.

The override's authorization is not in these records. `hold_override: true` is the records-alone signal that an override happened; `External check 4` is where an auditor goes for the order behind it, because `Capability requirement 33` keeps this layer from holding a datum it cannot verify. That is the only configuration in which advisory mode is appropriate: a dedicated instance, a disjoint population, and an external authority that can produce written authorization per override.

### GDPR Article 17 collision — erasure request against a hold

A data subject in the EU invokes the GDPR (EU General Data Protection Regulation) Article 17 right to erasure. Before executing, the system asks this composition, and there are four answers rather than three.

If the hold check answers non-empty, the erasure is deferred: Article 17(3)(e) exempts data necessary for the establishment, exercise or defence of legal claims, and the active hold is the operational record establishing the exception. If no hold is active and the named retention is outside elapsed retention, the record is under a live retention obligation — Article 17(3)(b)'s legal-obligation ground — and purge_record answers not-eligible. If no hold is active, the named retention is elapsed and a **sibling** is not, purge_record answers under-active-retention: a longer obligation over the same record survives the shorter one, which is the branch a request scoped to one retention most easily misses. Only when no hold is active and every retention over the record is elapsed does the destruction proceed.

In all four branches the trail is the evidence of what the system decided and on what ground. The composition does not adjudicate the legal question; it records the state of the atoms at decision time.

### Regulated adversarial scenarios

**Regulator audit — *prove no record under hold was destroyed during the examination window*.** An SEC examiner reads every record_purged outcome in the period and confirms `hold_check_result: empty` on each (`Check 1.1`). The examiner then runs the historical hold predicate — Legal Hold's read unfiltered by state, so a hold released *after* an improper destruction is still visible — and confirms that no returned hold was held at the outcome's `purged_at` (`Check 1.3`), excluding any hold whose own hold_placed outcome sits later in the log (`Check 1.4`). A current-state read would not do: the release-after-destruction sequence is precisely the spoliating history the check exists to catch.

**Disputed destruction — the data subject challenges a deferral.** A subject's representative asks whether there was really a hold. Legal Hold's read answers the active hold with placed by, `hold_reason`, placed at and case ref, immutable under Legal Hold Invariant 1, and the deferral's trail entry names the hold id. `verify_record` confirms the entry is unaltered. Legal Hold Invariant 7 is why the hold cannot have been placed anonymously. Sustaining the challenge would require claiming the whole hold store was fabricated, at which point the seal reached through the substrate is the structural rebuttal.

**Breach forensics — *was a preservation-deferred record improperly destroyed?*** The team reads the trail for record_purged outcomes naming the suspect record. None means the record was not destroyed through this composition, and the investigation moves to direct atom-level or storage-layer access — the bypass case `Check 3.4` signals. One means the `hold_check_result` and the historical hold predicate answer the question directly. The forensic window is bounded by the seal cadence below and by the audit horizon above, and `Invariant 8.6` is where that bound is stated rather than assumed.

---

## Generation acceptance

An implementation is acceptable when an external auditor, given the two indexes, the hold store, the business retention instance and the substrate's trail, can clear the checks below without recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY record purged outcome carrying an empty hold check result under strict mode (Invariant 1.4).
Check 1.2: An auditor MUST find EVERY record purged outcome carrying a non-empty hold check result carrying the hold override (Action wiring 55).
Check 1.3: An auditor MUST find no hold held at a record purged outcome's purged at (Invariant 1.1).
Check 1.4: An auditor MUST read a hold whose hold placed outcome follows the record purged outcome as outside the historical hold set (Invariant 6.3).
Check 1.5: An auditor MUST find EVERY gate record carrying a non-empty hold check result (Invariant 4.5).
Check 1.6: An auditor MUST find a gate record's named hold whose hold state EQUALS active at the gate record's log position (Invariant 4.5).
Check 1.7: An auditor MUST read Legal Hold's read unfiltered by hold state for the historical hold set (Invariant 6.3).
Check 2.1: An auditor MUST find a hold placed outcome PER hold whose placement stands within the audit horizon (Invariant 3.1).
Check 2.2: An auditor MUST find a hold released outcome PER released hold whose release stands within the audit horizon (Invariant 3.2).
Check 2.3: An auditor MUST read a surviving attestation for a hold an aged-out event names (Invariant 3.4).
Check 2.4: An auditor MUST read a hold an aged-out event names as covered by the attestation's existence alone (Invariant 3.4).
Check 2.5: An auditor MUST find Audit Trail's verify_record answering verified PER outcome the seal cadence covers (Invariant 3.5).
Check 2.6: An auditor MUST read a failed-verification carrying purged as a lawful destruction (Invariant 3.4).
Check 3.1: An auditor MUST find a retention placed outcome PER retention whose placement stands within the audit horizon (Invariant 4.1).
Check 3.2: An auditor MUST find a record purged outcome naming EVERY purged retention (Invariant 4.2).
Check 3.3: An auditor MUST read a retained retention a record purged outcome names pending as an open obligation (Invariant 9.4).
Check 3.4: An auditor MUST read a purged retention carrying no record purged outcome AND no recovery marker as a bypass finding (Composition state 24).
Check 3.5: An auditor MUST read a retained retention over a destroyed record carrying no pending mark as a conformance failure (Invariant 9.3).
Check 3.6: An auditor MUST select a retention an admitted placement covered PER the rebuild (Composition state 12).
Check 3.7: An auditor MUST find no retention over a destroyed record carrying a retention until the destruction's purged at does not reach (Invariant 9.1).
Check 4.1: An auditor MUST reconstruct a retention's lifecycle from the retention placed outcome, the hold outcomes AND the record purged outcome (Invariant 8.1).
Check 4.2: An auditor MUST join a hold to a retention by the record ref (Composition state 29).
Check 5.1: An auditor MUST find an intent preceding EVERY outcome in the substrate's own sequence (Invariant 5.1).
Check 5.2: An auditor MUST find an outcome's intent carrying the outcome's invocation_id (Invariant 5.1).
Check 5.3: An auditor MUST find an outcome's intent carrying the outcome's actor_ref (Composes 15).
Check 5.4: An auditor MUST read an outcome carrying no intent as a conformance failure (Invariant 5.1).
Check 5.5: An auditor MUST read an intent carrying no outcome as an open marker (Invariant 5.2).
Check 5.6: An auditor MUST read a gate record carrying no intent as conformant (Invariant 5.4).
Check 5.7: An auditor MUST find no two outcomes sharing one invocation_id (Invariant 5.6).
Check 5.8: An auditor MUST read an outcome carrying the recovery marker as the sweep's own (Reconciliation 15).
Check 6.1: An auditor MUST find the evidence floor not exceeding the audit horizon (Capability requirement 11).
Check 6.2: An auditor MUST find the rebuild reading Retention Window's store for an entry a purged placement event covers (Composition state 13).
Check 6.3: An auditor MUST read an audit horizon below the evidence floor as a conformance failure (Capability requirement 11).
Check 7.1: An auditor MUST clear Legal Hold's own acceptance over the hold store (Composes 5).
Check 7.2: An auditor MUST clear Retention Window's own acceptance over the business retention instance (Composes 5).
Check 7.3: An auditor MUST clear Audit Trail's own acceptance over the audit instance (Composes 6).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the business retention durations confirmed MUST read the deployment's own policy register (Capability requirement 11).
External check 2: An auditor needing a retention policy's correctness confirmed MUST read the deployment's own regulatory obligations (Capability requirement 31).
External check 3: An auditor needing a hold's authority confirmed MUST read the deployment's own permissions surface (Non-goal 13).
External check 4: An auditor needing an override's authorization confirmed MUST read the deployment's own authorization documentation (Capability requirement 33).
External check 5: An auditor needing the service identity's provisioning confirmed MUST read the substrate's actor registry (Capability requirement 17).
External check 6: An auditor needing the retention completion bound confirmed MUST read the deployment's own declaration (Capability requirement 19).
External check 7: An auditor needing the serialization confirmed MUST read the deployment's own concurrency control (Capability requirement 34).
```

WHY:
Check 2.6, Check 3.7, Check 5.7 and Check 5.8 are the four the prose's own acceptance did not carry, and each tests a rule rather than a phrasing. `Invariant 9.1` — the cross-retention gate, this composition's second load-bearing claim — was named by no check at all, which is the shape `cites.py --unchecked` exists to find: the guarantee was expensive to state and trivial to test, since every retention over a destroyed record is in the constituent's store and the destruction's own instant is on the outcome. Check 2.6 is the substrate's own purged verdict read before absence: an outcome the audit instance lawfully destroyed answers `failed-verification(purged)`, and an auditor told only to look for `verified` would read a lawful destruction as tampering. Check 5.7 and Check 5.8 are what `Action wiring 71` and `Action wiring 72` earn — once an owed record has exactly one writer, *two outcomes under one invocation_id* is a records-alone failure and the recovery marker says which writer wrote the one that landed.

External check 1 is this composition's most consequential externally-clearable gap, and the reason is not reporting hygiene. `Check 6.1` states the ordering and can be run wherever both durations are readable; where a business duration sits behind a policy ref this composition does not resolve — the ordinary case, since policy reconciliation is out of scope — the comparison needs the host's policy register. A violation is not a defect in a report: it destroys the placement evidence for a long-lived retention *before* that retention elapses, which is the failure `Invariant 9` exists to forbid, arriving through the layer that records it. What is checkable here is the structural defence rather than the ordering — `Check 6.2` confirms the past-horizon rebuild falls back to the constituent's store, which over-includes and can therefore only refuse.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT reconcile two retention policies.
Non-goal 2: A deployment needing a reconciled policy MUST compose a Policy Reconciliation pattern.
Non-goal 3: The composition MUST NOT destroy a record set in one call.
Non-goal 4: A deployment needing an atomic batch destruction MUST compose a transaction wrapper.
Non-goal 5: The composition MUST NOT judge a record ref against the retention store at a hold placement.
Non-goal 6: The composition MUST NOT adjudicate an erasure request.
Non-goal 7: The composition MUST NOT adjudicate a hold's proportionality.
Non-goal 8: The composition MUST NOT refuse a backdated placed at.
Non-goal 9: The composition MUST NOT own who may place a hold.
Non-goal 10: The composition MUST NOT own who may release a hold.
Non-goal 11: The composition MUST NOT own who may destroy a record.
Non-goal 12: A deployment needing an authorization MUST compose Permissions.
Non-goal 13: The composition MUST NOT verify a hold's legal authority.
Non-goal 14: The composition MUST NOT resolve a case ref against a legal matter.
Non-goal 15: The composition MUST NOT own a destruction mechanism.
Non-goal 16: A deployment needing a cryptographic shredding MUST compose a shredding pattern.
Non-goal 17: The composition MUST NOT record an outcome for a rejection outside the gate.
Non-goal 18: A deployment needing an attempted-action record MUST compose a Failed-Attempt Log pattern.
Non-goal 19: The composition MUST NOT govern a Legal Hold record's own retention.
Non-goal 20: The composition MUST NOT gate the audit instance's cascade.
Non-goal 21: The composition MUST NOT keep an aged-out event.
Non-goal 22: A deployment whose hold outlives the audit horizon MUST compose a Hold-Aware Audit Retention pattern.
Non-goal 23: A deployment whose hold approaches the audit horizon MUST alert.
Non-goal 24: The composition MUST NOT resolve a record ref rename.
```

WHY:
Non-goal 17 bounds the coverage claim, and the bound is what the hoisted commit-free checks buy. The decisions this layer records are the state-changing ones and the gate's firing; a call that never advanced to a state change — a malformed argument, an unknown id, a retention still inside its window, a hold already released — is refused before the intent and leaves no trail entry at all. A dashboard purging nightly against in-window retentions would otherwise write two entries per premature call. A rejection only a constituent can raise after the intent — a policy the registry does not resolve, a race the pre-read did not see, a storage fault — leaves that intent standing, and `Reconciliation 9` closes it as an abandoned attempt rather than a silent one.

Non-goal 20 through 23 are the honest half of this composition's own forthcoming-link story. A live hold keeps its Legal Hold record and does **not**, on its own, keep the events that prove it: hold_placed and retention_placed are ordinary audit events and die at the audit horizon whether or not the hold is still in force. [Audit Trail](./audit-trail.md)'s *Legal hold suspension of purge* edge case names the closure — a Legal Hold gate over `purge_event`, keyed on the business record ref in the event's payload — and names this composition as the pattern that wires the gate over business records. This composition is that pattern for business records and explicitly not for audit events, so a deployment whose holds can outlive its audit horizon composes the audit-side gate itself, as a **Hold-Aware Audit Retention** pattern *(forthcoming)*, and until then treats a hold approaching the horizon as a hard alerting condition. Past the horizon the FRCP Rule 37(e) defence this composition exists to produce rests on the surviving attestations and the constituent records alone.

The other forthcoming patterns named above are **Policy Reconciliation** *(forthcoming)* for Non-goal 2, a **cryptographic shredding** pattern *(forthcoming)* for Non-goal 16, and a **Failed-Attempt Log** *(forthcoming)* for Non-goal 18; a **Reverse Index** *(forthcoming)* and an **Override Authorization** *(forthcoming)* are named where their absence bites, in `Composes` and in `Capability requirement` respectively.

## Edge cases

### Atomic writes

```
Atomic writes 1: The composition MUST NOT place an audit append inside a host transaction's atomic set.
Atomic writes 2: An admitted placement MUST record the outcome ONLY AFTER the constituent commit.
Atomic writes 3: An admitted hold placement MUST record the outcome ONLY AFTER the constituent commit.
Atomic writes 4: An admitted hold release MUST record the outcome ONLY AFTER the constituent commit.
Atomic writes 5: An admitted purge MUST record the outcome ONLY AFTER the constituent commit.
Atomic writes 6: The composition MUST NOT reverse Retention Window's purge.
Atomic writes 7: A destroyed record carrying an owed record MUST stand as the composition's own partial.
Atomic writes 8: The composition MUST NOT read a storage-failure from Retention Window's purge as a destruction.
```

WHY:
Atomic writes 1 is the durability boundary named rather than wished away. An audit append cannot be enlisted in a host transaction and cannot be withdrawn, so a set containing one does not commit together or not at all — and this composition does not claim it does. What it states instead is the ordering, the reachable partials and the recovery for each, which is what an all-or-nothing sentence over this substrate would have concealed.

The ordering is the load-bearing half. Every outcome follows its committing call, so the reachable partial is a **missing** record rather than a false one — a record the sweep can re-emit from durable state. The one case with no reverse is `Atomic writes 6`: the destruction has landed, the outcome has not, and nothing can put the record back. That window is this composition's most consequential atomicity hole, it is bounded by the completion bound and the compensation window rather than left to *eventually*, and `Action wiring 70` makes it a hard alerting condition rather than a tolerated state. Atomic writes 8 closes the mirror error: the constituent leaves a retention retained and the record intact on a failed purge write, so that arm is a genuine retry over intact state and not a partial at all.

### Clock semantics

```
Clock semantics 4: The composition MUST judge elapsed retention against the injected now.
Deleted: Clock semantics 2. Action wiring 8 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Action wiring 60 owns it.
Clock semantics 5: The composition MUST judge a sibling set member's eligibility against the injected now.
Deleted: Clock semantics 6. Composes 18 owns it.
Deleted: Clock semantics 7. Retention Window Operation 13 owns it.
Deleted: Clock semantics 8. Legal Hold Operation 9 owns it.
Deleted: Clock semantics 9. Legal Hold Operation 18a owns it.
Deleted: Clock semantics 10. Event Log Operation 2 owns it, reached through Audit Trail.
Clock semantics 11: A reader MUST read a record purged outcome's purged at as the authoritative destruction instant.
Clock semantics 12: A reader MUST NOT read a retention's purged at as the authoritative destruction instant.
Clock semantics 13: A reader MUST read a divergence exceeding the clock offset allowance as a clock finding.
Clock semantics 14: The composition MUST NOT read a supplied placed at as the entry instant.
Clock semantics 15: A reader MUST read a hold placed outcome's recorded_at as the entry instant.
Clock semantics 16: The gate MUST NOT read a clock.
Deleted: Clock semantics 17. Capability requirement 36 owns it.
```

Term clock offset allowance: clock_offset_allowance — the deployment's declared envelope between two seams' readings of one request — what a reader allows before reading a divergence as a clock finding.

Term constituent commit: the instant a committing call's write lands in the constituent's own store.

Term gate read: the composition's read of a record's active holds at [Purge Record], taken before any destruction.

Term seal coverage: the point at which the substrate's seal cadence covers an event.

Term yielded invocation: an invocation whose age exceeds the retention completion bound — past which the invocation stops retrying and the owed record is the sweep's.

Term post-destruction hold: a hold whose hold_placed outcome sits later in the log than the destroyed record's own destruction record.

Term late hold: a hold placed later than the gate read of an invocation destroying the record.

WHY:
Action wiring 8, Action wiring 60, Clock semantics 4 and Clock semantics 5 enumerate every use this layer makes of the injected reading, across all five actions, because an earlier revision announced three purposes and listed two. One reading serves all four: the intent's stamp, the destruction's stamp, the named retention's eligibility and every sibling's. Clock semantics 16 is the fifth thing a reader expects and does not find — the gate consults the hold store's current state and no timestamp at all.

Composes 18, Clock semantics 11 and Clock semantics 12 are the *two readings* discipline, over the constituents' own stamping rules (Retention Window Operation 13, Legal Hold Operation 9 and Operation 18a, Event Log Operation 2). `RetentionWindow.purge` takes no timestamp, so the atom stamps from the reading injected at its own seam while this composition stamps the outcome from the reading injected here. Under the pipeline the two are ordinarily microseconds apart and ordered, and nothing in the declared contracts makes them equal — a spec claiming otherwise would be promising what no constituent signature can deliver. So one of them is designated authoritative and the other is an internal consistency artifact, and `Check 1.3`'s hold-versus-destruction cross-reference reads the designated one.

Clock semantics 14 and Clock semantics 15 keep the two meanings of a hold's time apart. A caller-supplied placed at asserts when the obligation arose and may legitimately predate the system entry — oral counsel advice documented afterwards is the ordinary case — while the entry instant is the audit event's own stamp. The gap between them is observable in the records, which is the point; whether a backdated assertion needs elevated authorization is the deployment's question and not this layer's (`Non-goal 8`).

Clock semantics 4, Clock semantics 5 and Clock semantics 16 stay under this heading rather than under Clock dependence: the first two are this layer's uses of the reading and the third says the gate makes none — instances of that family's question, not statements of it (council read 75).

### Concurrency

```
Concurrency 1: A late hold MUST leave a destruction standing.
Concurrency 2: The composition MUST NOT claim a late hold blocks a destruction.
Concurrency 3: The composition MUST NOT close the residual race at the composition's own layer.
Concurrency 4: Two sweeps MUST NOT emit two outcomes for one act.
```

WHY:
The gate reads the hold store and the destruction lands a rule later, so a hold placed between the two leaves a record destroyed under a hold that existed — a structural exposure to `Invariant 1` that no ordering inside this composition can close, because the placement is a second writer on a second path. `Capability requirement 34` and `Capability requirement 35` are where the closure lives, and Concurrency 3 says plainly that it is not here: a deployment under FRCP Rule 37(e) exposure treats the pair as a hard serialization requirement rather than an optimization.

Concurrency 4 is the sweep's own version of the same hazard, and it is closed here rather than delegated: `Reconciliation 20` and `Reconciliation 21` serialize a leg over the act's invocation_id and re-read the act's outcome under that serialization, so the look-then-write a compensator performs cannot run twice over one act.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A deployment MUST own the policy a record is placed under.
Composition note 3: A deployment MUST own who may place a hold.
Composition note 4: A deployment MUST own who may release a hold.
Composition note 5: A deployment MUST own who may destroy a record.
Composition note 6: A deployment MUST act on the sweep's escalation.
Composition note 7: A deployment MUST act on a destroyed record carrying an owed record.
Composition note 8: A deployment MUST release a hold the deployment's own authority overrode.
Composition note 9: A deployment MUST surface an active hold over a destroyed record.
```

WHY:
Composition note 3 through 5 are the three obligations [Legal Hold](../atoms/legal-hold.md)'s `Composition note 3` and `Composition note 4` assign to a composing pattern, passed down with the receiver named rather than dropped. This composition takes an actor_ref and a credential at every boundary and the substrate verifies the credential, which establishes *who is calling* and never *who may call* — the second is a [Permissions](../atoms/permissions.md) question and the deployment wires it. Naming the receiver is the most a composition can do with an obligation it declines; leaving it unnamed is how an obligation falls between two layers with no rule anywhere holding it.

Composition note 8 and Composition note 9 are the advisory path's other end. The composition records the override and declines to release the hold (`Wiring decision 6`), so the deployment's own authority owns both the release and the dashboard signal until it lands.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**, and carries no obligation of its own.

### Vocabulary

Term actors: the composition; a deployment; the host; the transition; the seam; the sweep; a caller; an auditor; a reader; an implementation; an invocation; an action; an intent; an outcome; a gate record; an open marker; a young marker; a recovery intent; the gate; the rebuild; an index; the record-to-retentions index; the retention-to-record index; a record; a retention; a sibling; a pending sibling; a hold; a hold check result; a hold count; a placement; a hold placement; a hold release; a purge; a release; a destruction; a committing call; a landed record; an owed record; an aged-out event; a surviving placement event; a purged placement event; a field cap; the evidence floor; the closure floor; the audit horizon; a policy; Legal Hold; Retention Window; Audit Trail; Event Log; a presenter; a presentation; a hold id list; a truncated hold id list; a divergence; two sweeps; a renamed record.

Term record verbs: serve, change, inherit, read, hold, reach, call, gate, select, query, attest, govern, store, add, remove, leave, stand, rest, admit, drop, report, agree, cover, name, carry, claim, supply, mint, accept, configure, declare, wire, set, provision, rotate, disclose, start, run, resolve, reconcile, serialize, answer, judge, size, compare, normalize, truncate, fold, trim, discharge, place, canonicalize, retry, alert, record, make, pass, write, order, refuse, own, destroy, intercept, compose, release, match, close, emit, escalate, examine, derive, follow, decide, purge, validate, bind, resist, find, join, reconstruct, clear, act, surface, keep, adjudicate, verify, stamp, block, commit, reverse, mark, need.

Term records: empty.

Term bounds: retention completion bound (retention_completion_bound), compensation window (compensation_window), audit horizon (audit_trail_retention_policy), evidence floor, closure floor, clock offset allowance (clock_offset_allowance), field cap, hold ids cap (hold_ids_cap), audit write latency.

Term cadences: reconciliation cadence (reconciliation_cadence), seal cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term value sets: hold check mode = strict | advisory. hold check result = empty | the blocking hold ids with the blocking count. intent = retention_placement_intended | hold_placement_intended | hold_release_intended | purge_intended. outcome = retention_placed | hold_placed | hold_released | record_purged. sibling disposition = purged | pending.

Term terms: composition, constituents, business retention instance, service identity, record, record-to-retentions index, retention-to-record index, audit horizon, surviving placement event, purged placement event, rebuild, sibling set, pending sibling, seam, transition, evidence floor, closure floor, retention completion bound, hold check mode, blank, boundary predicate, opaque input, landed record, owed record, intent, outcome, gate record, committing call, admitted placement, admitted hold placement, admitted hold release, admitted purge, elapsed retention, hold check result, hold override, unavailable sentinel, purged retention ids, sweep, open marker, young marker, aged-out event, recovery intent, recovery marker, recovery outcome, clock offset allowance, constituent commit, gate read, seal coverage, yielded invocation, post-destruction hold, late hold, position, invocation_id, intended_at, intent_abandoned, attributed to.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the derived-index classification and its obligations. The section titled Logic Confinement Principle in `execution-contract.md` — the seam.

Term composing patterns: Policy Reconciliation *(forthcoming)*; Hold-Aware Audit Retention *(forthcoming)*; Override Authorization *(forthcoming)*; Reverse Index *(forthcoming)*; Failed-Attempt Log *(forthcoming)*; a cryptographic shredding pattern *(forthcoming)*; [Permissions](../atoms/permissions.md).

Term record: the host's business record this composition governs — named by a record ref, held in the host's own store, and destroyed by `RetentionWindow.purge`.

#### Place Record Under Retention

The action that starts a business record's retention clock: it validates, records a placement intent, calls `RetentionWindow.place_under_retention`, indexes the new retention and records the placement. Answers the retention id.

Kind: Operation

#### Place Hold

The action that places a named, actor-issued hold on a record — suspending destruction regardless of the retention clock — and records the placement. Answers the hold id.

Kind: Operation

#### Release Hold

The action that releases a hold and records the release. A record becomes purge-eligible only when no active hold remains (`Invariant 7.1`); releasing one of several is not a release of the obligation.

Kind: Operation

#### Purge Eligible

The read-only query answering every retention past its retention until, each with its active-hold count, so a dashboard tells *purge-ready* from *hold-blocked*. It writes nothing, refuses nothing, and states no sibling liveness — a tuple can look ready while an in-window sibling, excluded by construction, still covers its record (`Action wiring 43`).

Kind: Operation

#### Purge Record

The composition's load-bearing action: destroy a record only after the gate passes. It reads the sibling set from the constituent's store, reads the record's active holds, refuses with [Under Legal Hold] and records the gate's firing under strict mode, and otherwise records the intent, destroys the record with every eligible sibling, and records the destruction with the [Hold Check Result].

Kind: Operation

#### Hold Check Result

What Legal Hold's read answered at the gate, carried on the destruction record and on the gate record alike: empty when no active hold covered the record, and the blocking hold ids with the blocking count when one did. It is the records-alone proof that the gate passed or fired.

Kind:       Field
Field of:   the destruction record
Role:       the auditable gate result
Projection: hold_check_result

#### Hold Override

The marker a destruction record carries when the [Hold Check Result] stands non-empty under advisory mode, and only then — the records-alone signal that a destruction proceeded past an active hold under an authority this layer does not hold.

Kind:       Field
Field of:   the destruction record
Role:       the advisory-override marker
Projection: hold_override

#### Under Legal Hold

The load-bearing refusal: under strict mode a destruction is refused while any active hold covers the record, whatever the retention clock says (`Invariant 1.4`). The refusal carries the blocking hold ids and count, and the gate's firing is itself recorded, so the refusal is a record rather than a silence.

Kind:       Member
Member of:  the purge rejection
Role:       Rejection
Projection: under-legal-hold

#### Not Eligible

The refusal for a record whose **named** retention has not yet elapsed — the window is still running, so the record may not be destroyed even with no hold over it.

Kind:       Member
Member of:  the purge rejection
Role:       Rejection
Projection: not-eligible

#### Under Active Retention

The refusal from the cross-retention gate (`Invariant 9.1`): a *sibling* retention over the same record is still inside its window, and `RetentionWindow.purge` destroys the record rather than closing the named retention alone, so the longer live obligation refuses the shorter one's destruction.

Kind:       Member
Member of:  the purge rejection
Role:       Rejection
Projection: under-active-retention

#### Hold Check Unavailable

The fail-closed refusal when the hold store cannot answer the gate's read. An unreadable hold store is never read as no holds (`Invariant 1.3`), and nothing is destroyed on this arm.

Kind:       Member
Member of:  the purge rejection
Role:       Rejection
Projection: hold-check-unavailable

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Place Record Under Retention]: #place-record-under-retention
[Place Hold]: #place-hold
[Release Hold]: #release-hold
[Purge Eligible]: #purge-eligible
[Purge Record]: #purge-record
[Hold Check Result]: #hold-check-result
[Hold Override]: #hold-override
[Under Legal Hold]: #under-legal-hold
[Not Eligible]: #not-eligible
[Under Active Retention]: #under-active-retention
[Hold Check Unavailable]: #hold-check-unavailable

---

## Standards references

- **Federal Rules of Civil Procedure Rule 37(e)** — the preservation duty for ESI (electronically stored information). A party that fails to preserve when a hold should have been in place faces sanctions including adverse inference. `Invariant 1` and `Invariant 8` are the structural forms of the reasonable-steps obligation; the trail is the evidence.
- **Sarbanes-Oxley §802 (18 U.S.C. — the United States Code — §1519)** — criminal obstruction for destroying records subject to a federal investigation. The gate is the structural defence and the destruction record carrying an empty [Hold Check Result] is the evidence that a destruction was not obstruction.
- **Sarbanes-Oxley §404** — internal controls over financial reporting, retention and destruction controls included. The composition is the structural form of those controls.
- **HIPAA §164.530(j)** — documentation retention, a six-year federal baseline and longer under state law. The composition governs the PHI (protected health information) retention and hold-during-investigation lifecycle; the substrate provides the attribution trail HIPAA's audit controls require.
- **SEC Rule 17a-4(f)** — broker-dealer preservation in non-rewriteable, non-erasable form. The substrate's Tamper Evidence satisfies the integrity half and the gate the non-premature-destruction half.
- **GDPR Article 17 (right to erasure)** — the composition answers whether an erasure is permissible: an active hold establishes the legal-claims exception under Article 17(3)(e), a live retention the legal-obligation ground under Article 17(3)(b).
- **GDPR Article 5(1)(e) (storage limitation)** — personal data must not be kept longer than necessary. [Purge Eligible] surfaces every retention past retention until with its purge deadline, so a caller identifies overshoot; the destruction record proves timely destruction.
- **Federal Rules of Civil Procedure Rule 26(b)** — proportionality in preservation. Legal Hold's `hold_reason` and case ref document each hold's proportionality; the composition preserves the record without adjudicating it (`Non-goal 7`).
- **ISO 15489-1 (records management)** — §9.7, suspension of disposition, maps to the gate; the two-state hold lifecycle maps to the standard's hold lifecycle.

The three constituents carry their own standards inheritance — see each constituent's own Standards references.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — defensible-retention.tla + 1 twin, 2026-06-03
last gate: 2026-08-28 — second gate after closure, fresh reader — 4 foundational (all since closed), 16 refining, 5 rhetorical

open:
- 2026-08-29-a · refining · formal · the model's sweep carries no age bound, no identity, and no recovery record → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/defensible-retention.md`.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except two rejection surfaces the prose misnamed.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Identity`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the wiring surfaces, with `Concurrency`, `Clock semantics` and `Atomic writes` as the edge-case families; the ten invariant numbers unchanged; the acceptance section's own two tiers carried across as `Check` and `External check`. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into defensible-retention` finds nothing in the corpus citing this composition by label, so the rewrite carried no frozen-number risk. **No family was minted.** Every one of the sixteen is standard or already recurring, and two of them move: `Audit arm`, which [Login](./login.md) minted one migration earlier, reaches two specs and so meets Principle 2's recurrence half; `Reconciliation` reaches three and so stands as a promotion candidate under `GRACE-lang.md` Standard label 4. `Identity` is the grammar's own standard family taken for the first time by a composition — thirty specs carry it, all of them atoms that mint ids, and this composition mints none: what it owns is an equality the gate evaluates, which is the same question one layer out.
- **2026-09-14 — A constituent's storage failure surfaces as itself, and this composition's own recording failure carries its position.** *Chose:* storage-failure exported unchanged from all four state-changing actions, and `recording-failure(intent | outcome)` on every one of them. *Over:* the prose's mapping of a constituent storage-failure onto recording-failure, and a bare recording-failure on the three non-destructive actions. *Because:* the first renamed a failure to *write a record* into a failure to *record it*, which is a different fact and a different repair; the second put one token on both sides of the commit, so a caller who retried on it could not know whether anything had committed — which the corpus's own rule requires the exported code to answer.
- **2026-09-14 — The owed destruction record has exactly one writer.** *Chose:* an invocation retries its outcome until the retention completion bound and then yields; past the bound the record belongs to the sweep, which serializes its leg on the act's invocation_id and re-reads the act's outcome under that serialization. *Over:* an out-of-band retry and a sweep both owing the same record with nothing between them. *Because:* two writers over one destruction land two record_purged events for one act, and the trail then protects both — the one failure a compensating write cannot undo.

NOTE: End of Defensible Retention.
