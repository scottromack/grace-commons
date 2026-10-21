---
title: Chain of Custody
parent: Conceptual Compositions
nav_order: 17
has_toc: true
toc: true
---

# Chain of Custody

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>


## Summary

Chain of Custody is a regulated composition (a spec that wires two or more atoms — freestanding, self-contained pattern specs — together) that solves the chain-of-custody problem no single atom solves alone: proving, from the records alone, that an artifact moved through an unbroken sequence of verified, non-repudiable (unable later to deny the act) custodians, that no entry was tampered with, and that the chain was kept for the required period. It wires two constituents: Provenance (the append-only custody chain with structural continuity — one current custodian at all times, hand-to-hand transfers) and the Audit Trail substrate (the tamper-evident — designed so unauthorized changes are detectable — regulated-audit substrate that attribution-stamps and seals every custody event via the Event Log, Actor Identity, Retention Window, and Tamper Evidence atoms it contains).

The composition's defining emergent guarantee is records-alone custody proof: a single query, `verify_custody(chain_id, original_event_payloads)`, returns the full ordered chain with, per entry, the verified attribution of the acting custodian (who authorized this step), the tamper-evident seal status (has the entry been altered), and the retention state (is the entry still held lawfully) — plus a continuity check confirming that every transfer's outgoing custodian equals the prior holder. This is the structural answer to the regulator's, judge's, or auditor's four questions — *who held it, was the transfer unbroken, was the record altered, was it kept long enough* — from the records alone, without developer narration. Neither Provenance alone nor Audit Trail alone produces this answer; the composition is what wires them into a single custody-proof surface.

Its most common uses are pharmaceutical chain of custody under FDA (US Food and Drug Administration) 21 CFR (Code of Federal Regulations) Part 211 and DEA (US Drug Enforcement Administration) 21 CFR Part 1304 (controlled substance inventory), physical-evidence authentication under FRE (Federal Rules of Evidence) 901(b)(9), financial instrument custody records under SEC (US Securities and Exchange Commission) Rule 17a-4, and digital-file chain of custody under ISO (International Organization for Standardization) 23081 (records-management metadata). Any system that must prove, from records alone, that every step in an artifact's journey was attributed, sealed, and retention-governed is a candidate for this composition.

---

## Intent

Every domain that must account for an artifact's journey faces the same four-part requirement: the chain must be unbroken (no gap in custody, hand-to-hand transfers with no unattributed interval), the custodians must be verified (each hand-off attributed to a real actor, not just an opaque reference), the chain must be tamper-evident (any after-the-fact rewrite detectable from the records alone), and the chain must be retention-governed (retained for its regulatory lifetime and lawfully destroyable with a defensible record of destruction). No single atom satisfies all four. Provenance supplies the first. Audit Trail supplies the third and fourth, and transitively the second via Actor Identity. But neither provides the full custody-proof surface until they are wired together: Provenance does not verify its opaque custodian_ref values and does not seal its chain; Audit Trail does not know what a custody chain is or that its events need to be tied to custody entries. The wiring is this composition.

The cross-domain structural identity is the composition's thesis. Under FDA 21 CFR Part 211 (Current Good Manufacturing Practice for Finished Pharmaceuticals), a pharmaceutical manufacturer must demonstrate an unbroken, attributed, tamper-protected, retention-compliant chain of custody from manufacture through distribution to dispensing. Under FRE 901(b)(9) (Authentication by Process or System), an officer presenting physical evidence at trial must authenticate the exhibit via an unbroken custody chain in which every handler is identified. Under DEA 21 CFR Part 1304 (Controlled Substance Inventory Records), a complete, accurate record of every change of custody for a controlled substance is a legal obligation. The structural form is identical across all three domains: one artifact, one current custodian at all times, hand-to-hand transfers, each hand-off attributed and verifiable, the record sealed against tampering, and the record retained for its regulatory lifetime. One grounded composition satisfies all three.

This is a composition, not a new primitive. Provenance and Audit Trail (with its constituent atoms, Event Log, Actor Identity, Retention Window, and Tamper Evidence — reached transitively) are unchanged. The composition is the wiring that makes them coherent as a single chain-of-custody surface. It introduces emergent actions — [Originate Custody], [Transfer Custody], [Transform Custody], [Disclose Custody], [Archive Custody], [Verify Custody] — that belong to no single constituent and exist only because the two are wired together. [Verify Custody] in particular belongs to neither constituent alone: Provenance can verify structural continuity but cannot verify attribution or tamper-evidence; Audit Trail can verify attribution and tamper-evidence but does not know which events constitute a custody chain. The composition is the layer that answers: *is this custody chain complete, attributed, sealed, and within its retention horizon?*

What the composition is *not*: it is not a DAG-model (DAG — directed acyclic graph) provenance tracker (the linear single-artifact constraint is inherited from Provenance); it is not a multi-party simultaneous custody surface; it is not the legal-hold suspension layer over custody chains (that is Legal Hold / Defensible Retention); it is not the artifact-registry layer (validating that artifact_ref names a real artifact in the host system is the host's obligation); and it is not the clock-authority layer (inherited from Audit Trail). Each is named explicitly in Non-goals.

---

## Composes

- **[Provenance](../atoms/provenance.md)** — the structural custody chain: one current custodian at all times, hand-to-hand transfers, the outgoing custodian read from chain state.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate: every custody action records through it, and each record is appended to Event Log, attested by Actor Identity, placed under Retention Window and sealed by Tamper Evidence at the configured cadence.

```
Composes 1: EXACTLY ONE Provenance instance MUST serve the composition.
Composes 2: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 3: The composition MUST reach a transitive atom ONLY through Audit Trail.
Composes 4: The composition MUST NOT compose an instance of a transitive atom.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST NOT change a constituent's spec.
Composes 7: The composition MUST select the custody events through the custody enumeration.
Composes 8: The composition MUST read an event's metadata ONLY through the record read.
Composes 9: The composition MUST NOT read Audit Trail records directly.
Composes 10: IF the custody enumeration answers invalid-query THEN the deployment MUST alert on a configuration fault.
Composes 11: The composition MUST record two audit writes PER custody action.
```

Term composition: this pattern's wiring of [Provenance](../atoms/provenance.md) and [Audit Trail](./audit-trail.md) — the five custody actions, the verification, the binding index and the reconciliation.

Term constituents: [Provenance](../atoms/provenance.md), [Audit Trail](./audit-trail.md).

Term transitive atoms: [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md), [Retention Window](../atoms/retention-window.md) and [Tamper Evidence](../atoms/tamper-evidence.md), reached through Audit Trail.

Term custody enumeration: Event Log's read by sequence-number range with an open upper bound, passed through Audit Trail unchanged, with every selection by action reference and payload field made in the composition's own code.

Term record read: Audit Trail's read_record on an event id — the substrate's declared consolidated read surface.

Term audit write: Audit Trail's record_action.

Term verification: Audit Trail's verify_record on an event id and a presentation.

Term custody action: [Originate Custody], [Transfer Custody], [Transform Custody], [Disclose Custody] or [Archive Custody].

Adjacent, **not** constituents: [Defensible Retention](./defensible-retention.md) (hold-blocks-purge over the custody events); [Selective Disclosure](../atoms/selective-disclosure.md) (what subset was disclosed); [Permissions](../atoms/permissions.md) (custody-transfer authority).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the binding index.
Composition state 2: The composition MUST key the binding index by entry id.
Composition state 3: A binding MUST carry the outcome event id of the entry's outcome event.
Composition state 4: The composition MUST write a binding ONLY AFTER the entry's outcome event lands.
Composition state 5: The composition MUST NOT change a binding.
Composition state 6: The composition MUST classify a live binding as a derived index.
Composition state 7: The composition MUST rebuild a missing live binding PER the binding rebuild.
Composition state 8: IF the binding rebuild finds two outcome events carrying one entry id THEN the rebuild MUST bind the first by sequence number.
Composition state 9: IF the binding rebuild finds two outcome events carrying one entry id THEN the rebuild MUST open a binding-duplicate finding.
Composition state 10: IF the binding rebuild finds no outcome event for an entry THEN the composition MUST read the entry as an orphan.
Composition state 11: The composition MUST classify a purged binding as extraction-pending against Erasure Tombstone.
Deleted: Composition state 12. Execution Contract Database 3 owns it.
Composition state 13: The composition MUST NOT read an intent as a binding.
Composition state 14: The composition MUST NOT duplicate a constituent's records.
```

Term entry id: the opaque id Provenance mints for a custody entry.

Term chain id: the opaque id Provenance mints for a custody chain.

Term binding index: the composition's map from a custody entry to the outcome event that attributes, seals and retention-governs it — `entry_to_event` in an implementation.

Term binding: one entry id with its outcome event id.

Term outcome event: the custody.originated, custody.received, custody.transferred, custody.transformed, custody.disclosed or custody.archived event — carrying the entry id.

Term live binding: a binding whose outcome event's payload the audit horizon has not reached.

Term purged binding: a binding whose outcome event's payload the audit horizon has destroyed.

Term binding rebuild: the custody enumeration from the log's start, kept to the outcome events carrying an entry id of the chain, re-keyed by that entry id.

### Capability requirement

```
Capability requirement 1: A deployment MUST set the audit retention policy on the Audit Trail instance.
Capability requirement 2: The composition MUST NOT pass a retention input to the audit write.
Capability requirement 3: A regulated deployment MUST set an audit retention policy encoding the regime's minimum custody-record retention.
Capability requirement 4: A deployment MUST set the seal cadence on the Audit Trail instance.
Capability requirement 5: The composition MUST NOT override the seal cadence.
Capability requirement 6: A deployment MUST set the custody completion bound.
Capability requirement 7: IF the custody completion bound EQUALS blank THEN the composition MUST refuse to start.
Deleted: Capability requirement 8. Execution Contract Database 1 owns it.
Capability requirement 9: A deployment MUST set the custody compensation window.
Capability requirement 10: A deployment MUST set the custody reconciliation cadence.
Capability requirement 11: A deployment MUST disclose the outcome write latency.
Capability requirement 12: The composition MUST start ONLY IF the custody compensation window EXCEEDS the liveness sum.
Deleted: Capability requirement 13. Execution Contract Database 3 owns it.
Deleted: Capability requirement 14. Execution Contract Database 3 owns it.
Capability requirement 15: A deployment MUST provision the recovery identity.
Deleted: Capability requirement 16. Execution Contract Database 2 owns it.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 18. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 19. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to lease.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for a host to lack.
Capability requirement 22: A deployment MAY supply the genesis lookup.
Capability requirement 23: A deployment MUST set the intent candidates cap.
Capability requirement 24: A deployment MUST set the input caps so the largest outcome payload built from capped inputs fits Audit Trail's payload cap.
Capability requirement 25: The wired Audit Trail instance MUST expose the custody enumeration.
Capability requirement 26: The composition MUST NOT read a clock inside a custody action.
Capability requirement 27: The host MUST inject the reconciliation's now at the reconciliation's own seam.
Capability requirement 28: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
```

Term audit retention policy: the policy reference configured on the composition's single Audit Trail instance, governing the lifetime of every custody event — never the Provenance chain itself.

Term audit horizon: the audit retention policy's horizon, past which a custody event's payload is lawfully destroyed.

Term seal cadence: Audit Trail's per-event | interval-based | on-demand setting, which fixes each custody event's covering range.

Term custody completion bound: the longest a custody action may run from its intent to its outcome.

Term custody compensation window: the duration within which an orphan's outcome event lands or the orphan is escalated — `custody_compensation_window` in configuration, distinct from the substrate's own compensation window.

Term custody reconciliation cadence: the interval between the reconciliation's runs, beside the run at every restart — `custody_reconciliation_cadence` in configuration, distinct from the substrate's own cadence.

Term outcome write latency: the deployment's disclosed bound on one audit write landing.

Term liveness sum: `custody completion bound + custody reconciliation cadence + outcome write latency`.

Term recovery identity: a deployment-provisioned actor reference and credential under which the reconciliation attests every write it makes.

Term genesis lookup: the deployment-supplied lookup from an artifact reference to the chains originated for it.

Term intent candidates cap: the most intent candidates one compensating event may name.

Term input caps: the composition-layer byte caps on the artifact reference, the custodian references, the recipient reference and the transformation descriptor.

### Primitive policy

```
Primitive policy 1: IF the artifact reference EQUALS blank THEN [Originate Custody] MUST answer invalid-ref.
Primitive policy 2: IF a custodian reference EQUALS blank THEN the custody action MUST answer invalid-ref.
Primitive policy 3: IF the recipient reference EQUALS blank THEN [Disclose Custody] MUST answer invalid-ref.
Primitive policy 4: IF the transformation descriptor EQUALS blank THEN [Transform Custody] MUST answer invalid-descriptor.
Primitive policy 5: IF the genesis type IS NOT IN originated and received THEN [Originate Custody] MUST answer invalid-genesis-type.
Primitive policy 6: IF the credential EQUALS blank THEN the custody action MUST answer invalid-credential.
Primitive policy 7: IF a reference EXCEEDS the reference's input cap THEN the custody action MUST answer invalid-ref.
Primitive policy 8: IF the transformation descriptor EXCEEDS the descriptor's input cap THEN [Transform Custody] MUST answer invalid-descriptor.
Primitive policy 9: An action refused under Primitive policy 1 through 8 MUST NOT write.
Primitive policy 10: A custody action MUST NOT call a constituent BEFORE Primitive policy 1 through 8 pass.
Primitive policy 11: The composition MUST compare a chain id, an entry id AND an event id byte-exact.
Primitive policy 12: The composition MUST NOT normalize a caller string.
Primitive policy 13: The composition MUST NOT inspect a credential beyond Primitive policy 6.
Primitive policy 14: The composition MUST pass a custody action's acting custodian to the audit write as the actor reference.
Primitive policy 15: The composition MUST NOT carry the metadata in an audit write.
```

Term artifact reference: the opaque reference to the artifact whose custody a chain tracks — never validated against a registry here.

Term custodian reference: the opaque reference to the custodian performing or receiving a custody step.

Term recipient reference: the opaque reference to the party a disclosure names.

Term transformation descriptor: the non-blank description of a transformation the current custodian applied.

Term genesis type: originated | received — Provenance's.

Term metadata: the optional opaque payload [Originate Custody] passes to Provenance unchanged.

Term credential: the acting custodian's opaque credential material, validated by the substrate inside the audit write.

Term caller string: an artifact reference, a custodian reference, a recipient reference or a transformation descriptor.

Term acting custodian: the genesis custodian for [Originate Custody]; the outgoing custodian for [Transfer Custody]; the current custodian for [Transform Custody], [Disclose Custody] and [Archive Custody].

### Audit arm

```
Audit arm 1: IF Audit Trail answers invalid-credential at an intent THEN the custody action MUST answer invalid-credential.
Audit arm 2: IF Audit Trail answers invalid-request carrying a step below step-3 at an intent THEN the custody action MUST answer invalid-request.
Audit arm 3: IF Audit Trail answers recording-failure at an intent THEN the custody action MUST answer recording-failure carrying intent.
Audit arm 4: The composition MUST NOT retry an invalid-request answer.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Audit arm 6: IF Audit Trail answers invalid-request(step-4) at an outcome THEN the invocation MUST read the outcome event back.
Audit arm 7: The read-back MUST match the outcome event carrying the custody action's action reference AND the intent event id.
Audit arm 8: The read-back MUST read the custody enumeration from the log's start.
Audit arm 9: IF the read-back finds the outcome event THEN the invocation MUST proceed as landed.
Audit arm 10: The deployment MUST alert on an outcome event read back as landed.
Deleted: Audit arm 11. Execution Contract Database 1 owns it.
Deleted: Audit arm 12. Execution Contract Database 1 owns it.
Deleted: Audit arm 13. Execution Contract Database 1 owns it.
Deleted: Audit arm 14. Reconciliation 25 and Execution Contract Database 1 own it.
Deleted: Audit arm 15. Reconciliation 26 and Execution Contract Database 1 own it.
Deleted: Audit arm 16. Execution Contract Database 2 owns it.
Deleted: Audit arm 17. Execution Contract Database 2 owns it: a custody action's attestations read the actor registry inside one transaction, so no invocation re-attests an outcome.
Deleted: Audit arm 18. Execution Contract Database 1 owns it: a custody action's writes commit together, so no invocation retries an outcome.
Audit arm 19: IF no outcome lands THEN the custody action MUST answer recording-failure carrying outcome.
Deleted: Audit arm 20. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Audit arm 21. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Audit arm 22. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no lease to expire.
Audit arm 23: A caller MUST read recording-failure carrying intent as a committed nothing.
Audit arm 24: A caller MUST read recording-failure carrying outcome as a committed custody entry.
Audit arm 25: IF Audit Trail answers invalid-request carrying a step above step-2 at an intent THEN the custody action MUST answer recording-failure carrying intent.
Audit arm 26: IF Audit Trail answers invalid-request carrying a step below step-4 at an outcome THEN the invocation MUST escalate the orphan as a deployment fault.
```

Term intent: the custody action's record before its Provenance write — custody.originate_intended, custody.transfer_intended, custody.transform_intended, custody.disclose_intended or custody.archive_intended; carrying the invocation's parameters and no constituent-minted id.

Term position: intent | outcome — where a recording-failure sat: intent, nothing committed and the whole action may be retried; outcome, the custody entry exists and a re-run commits a second one.

Term recovery intent: the custody.recovery_intended event — naming the chain id, the entry id and the intent reference an outcome under the recovery identity is about to bind.

Term recovery flag: cascade_recovery set to true — carried by an outcome attested under the recovery identity, and by no other.

### Action wiring

```
originate_custody(artifact_ref, custodian_ref, genesis_type, credential, optional metadata)
  answers custody result
  refuses invalid-ref | invalid-genesis-type | invalid-credential | invalid-request | recording-failure(position)

transfer_custody(chain_id, to_custodian_ref, credential)
  answers custody result
  refuses not-known | archived | invalid-ref | invalid-credential | invalid-request | recording-failure(position)

transform_custody(chain_id, custodian_ref, transformation_descriptor, credential)
  answers custody result
  refuses not-known | archived | not-current-custodian | invalid-ref | invalid-descriptor | invalid-credential | invalid-request | recording-failure(position)

disclose_custody(chain_id, custodian_ref, recipient_ref, credential)
  answers custody result
  refuses not-known | archived | not-current-custodian | invalid-ref | invalid-credential | invalid-request | recording-failure(position)

archive_custody(chain_id, custodian_ref, credential)
  answers custody result
  refuses not-known | already-archived | not-current-custodian | invalid-ref | invalid-credential | invalid-request | recording-failure(position)

verify_custody(chain_id, original_event_payloads)
  answers custody proof
  refuses not-known

read(chain_id, query)
  answers entry sequence
  refuses not-known | invalid-query
```

Term custody result: the entry id and the outcome event id, and for [Originate Custody] the chain id.

Term original event payloads: the caller's map from an audit-log sequence number to the byte-exact payload Event Log holds at that position.

Term entry sequence: the chain's entries in sequence order — Provenance's read answer.

Term custody proof: what [Verify Custody] answers — a [Custody Proof].

```
Action wiring 1: A validated custody action MUST NOT call a Provenance write BEFORE the action's intent lands.
Action wiring 2: An intent MUST carry the invocation's parameters under the acting custodian as the actor reference.
Action wiring 3: An intent MUST NOT carry a constituent-minted id.
Action wiring 4: An audit write of the composition MUST NOT carry a timestamp.
Action wiring 5: An outcome event MUST carry the chain id, the entry id, the intent event id AND the acting custodian.
Deleted: Action wiring 6. Execution Contract Database 2 owns it.
Action wiring 7: IF Provenance answers storage-failure THEN the custody action MUST answer recording-failure carrying intent.
Action wiring 8: IF Provenance answers a Provenance refusal THEN the custody action MUST answer the Provenance refusal.
Action wiring 9: A refused Provenance write MUST NOT write beyond the intent.
Deleted: Action wiring 10. Execution Contract Database 1 owns it.
Action wiring 11: A bound custody action MUST write the binding AND answer the custody result.
Action wiring 12: A validated origination MUST record the originate intent carrying the artifact reference, the custodian reference AND the genesis type.
Action wiring 13: An admitted origination MUST call Provenance's originate with the artifact reference, the custodian reference, the genesis type AND the metadata.
Action wiring 14: A committed origination MUST read the genesis entry at sequence number one through Provenance's read.
Action wiring 15: A committed origination MUST record custody.originated for originated AND custody.received for received.
Action wiring 16: A validated transfer MUST NOT record the transfer intent BEFORE resolving the outgoing custodian through Provenance's read.
Action wiring 17: IF Provenance's read answers not-known THEN [Transfer Custody] MUST answer not-known.
Action wiring 18: IF the chain's latest entry carries archived THEN [Transfer Custody] MUST answer archived.
Action wiring 19: A transfer refused ahead of the transfer intent MUST NOT write.
Action wiring 20: A resolved transfer MUST record the transfer intent carrying the chain id, the resolved custodian as the outgoing custodian AND the incoming custodian under the resolved custodian as the actor reference.
Action wiring 21: An admitted transfer MUST call Provenance's transfer with the chain id AND the incoming custodian.
Action wiring 22: A committed transfer MUST read the committed entry's outgoing custodian through Provenance's read.
Deleted: Action wiring 23. Execution Contract Database 2 owns it.
Deleted: Action wiring 24. Execution Contract Database 2 owns it: a transfer's resolution read and its write are one transaction, so no transfer answers principal-divergence.
Deleted: Action wiring 25. Execution Contract Database 2 owns it: a transfer's resolution read and its write are one transaction, so no transfer answers principal-divergence.
Action wiring 26: A confirmed transfer MUST record custody.transferred under the committed entry's outgoing custodian as the actor reference.
Action wiring 27: A validated transformation MUST record the transform intent carrying the chain id, the custodian reference AND the transformation descriptor.
Action wiring 28: An admitted transformation MUST call Provenance's transform with the chain id, the custodian reference AND the transformation descriptor.
Action wiring 29: A validated disclosure MUST record the disclose intent carrying the chain id, the custodian reference AND the recipient reference.
Action wiring 30: An admitted disclosure MUST call Provenance's disclose with the chain id, the custodian reference AND the recipient reference.
Action wiring 31: A validated archival MUST record the archive intent carrying the chain id AND the custodian reference.
Action wiring 32: An admitted archival MUST call Provenance's archive with the chain id AND the custodian reference.
Action wiring 33: IF Provenance's read answers not-known THEN [Verify Custody] MUST answer not-known.
Action wiring 34: A found verification MUST replay the chain's entries in sequence order as the continuity check.
Action wiring 35: A found verification MUST resolve EVERY entry's binding through the binding index.
Action wiring 36: IF an entry carries no binding after the rebuild AND a purged later entry EXISTS THEN the entry MUST carry binding-unknown.
Action wiring 37: IF an entry carries no binding after the rebuild AND no purged later entry EXISTS THEN the entry MUST carry binding-gap.
Action wiring 38: A found verification MUST read EVERY bound event through the record read.
Action wiring 39: IF the record read answers Purged THEN [Verify Custody] MUST call the verification with the covering range's members the original event payloads carry.
Action wiring 40: [Verify Custody] MUST NOT check the original event payloads for an event the record read answers Purged for.
Action wiring 41: IF a member of a live event's covering range IS NOT IN the original event payloads THEN the entry MUST carry payload-not-supplied AND the missing sequence numbers as the attestation verification.
Action wiring 42: IF EVERY member of a live event's covering range IS IN the original event payloads THEN [Verify Custody] MUST call the verification with the covering range's payloads in ascending sequence order.
Action wiring 43: A found verification MUST carry the verification's outcome AND reason unchanged as the attestation verification.
Action wiring 44: A found verification MUST carry the verification's compensation-window qualifier beside the attestation verification.
Action wiring 45: A found verification MUST compare the entry's stored fields with the payload at the bound event's own position as the entry payload match.
Action wiring 46: IF the attestation verification DOES NOT EQUAL verified THEN the entry payload match MUST carry unanchored.
Action wiring 47: A found verification MUST compare the bound event's attesting actor with the entry's custodian as the actor match.
Action wiring 48: A found verification MUST carry the bound event's recovery flag as the recovery attestation.
Action wiring 49: IF the record read answers Purged THEN the recovery attestation MUST carry unknown carrying purged.
Action wiring 50: A found verification MUST carry the record read's retention state unchanged.
Action wiring 51: The composition MUST NOT fetch a payload for the verification.
Action wiring 52: [Verify Custody] MUST NOT change a presented payload.
Action wiring 53: [Verify Custody] MUST NOT record an audit event.
Action wiring 54: The read passthrough MUST answer Provenance's read for the chain id AND the query unchanged.
Action wiring 55: The read passthrough MUST NOT record an audit event.
```

Term validated custody action: a custody action whose inputs cleared Primitive policy.

Term Provenance refusal: invalid-ref | invalid-genesis-type | not-known | archived | already-archived | not-current-custodian | invalid-descriptor — Provenance's refusals of a write, relayed by name.

Term bound custody action: a custody action whose outcome event landed.

Term validated origination: a validated custody action of [Originate Custody].

Term admitted origination: a validated origination whose originate intent landed.

Term committed origination: an admitted origination whose Provenance originate answered the chain id.

Term validated transfer: a validated custody action of [Transfer Custody].

Term resolved custodian: the incoming custodian of the chain's latest transferred entry, or the genesis custodian where none — the holder the chain shows.

Term resolved transfer: a validated transfer Action wiring 17 and 18 did not refuse.

Term admitted transfer: a resolved transfer whose transfer intent landed.

Term committed transfer: an admitted transfer whose Provenance transfer answered the entry id.

Term confirmed transfer: a committed transfer whose committed outgoing custodian equals the resolved custodian.

Term validated transformation: a validated custody action of [Transform Custody].

Term admitted transformation: a validated transformation whose transform intent landed.

Term validated disclosure: a validated custody action of [Disclose Custody].

Term admitted disclosure: a validated disclosure whose disclose intent landed.

Term validated archival: a validated custody action of [Archive Custody].

Term admitted archival: a validated archival whose archive intent landed.

Term purged later entry: an entry later in the chain, by sequence number, whose bound outcome event the record read answers Purged.

Term pre-horizon entry: an entry for which a purged later entry exists.

Term found verification: a [Verify Custody] call whose chain Provenance's read found.

Term covering range: the sequence range the record read names for an event's covering seal, or the event's own sequence number in the unsealed tail.

Term live event: a bound event the record read answers Retained or unresolved in its compensation window.

Term entry payload match: match | entry-payload-mismatch carrying the field | unanchored | not-applicable carrying purged | payload-not-supplied.

Term actor match: match | match carrying recovery | attribution-mismatch carrying the actor reference | unknown carrying purged — match carrying recovery where the attesting actor is the recovery identity, the event carries the recovery flag and the payload names the entry's custodian.

Term recovery attestation: true | false | unknown carrying purged — whether the bound event carries the recovery flag.

Term read passthrough: Provenance's read, passed through unchanged — the composition's read.

### Wiring decision

```
Wiring decision 1: The composition MUST follow EVERY Provenance custody entry with EXACTLY ONE outcome event naming the entry id.
Deleted: Wiring decision 2. Execution Contract Database 1 owns it.
Wiring decision 3: A validated origination MUST attest under the genesis custodian.
Wiring decision 4: A validated transfer MUST attest under the outgoing custodian.
Wiring decision 5: [Transform Custody], [Disclose Custody] AND [Archive Custody] MUST attest under the current custodian.
Wiring decision 6: The composition MUST NOT attest a transfer under the incoming custodian.
```

WHY:
*Principle.* A court-admissible or regulator-acceptable chain of custody needs four properties at once: continuity (no gap, hand to hand), verified attribution (each custodian non-repudiably identified), tamper evidence (any rewrite detectable from the records alone), and retention governance (kept for its regulatory lifetime, lawfully destroyable with a defensible record). Provenance supplies continuity; Audit Trail supplies the other three. Without a per-entry link the two record sets are parallel and unjoined — an auditor can verify continuity separately and attribution separately, but cannot prove all four *together for the same entry*.

*Likely objection.* Why not fold attribution, tamper evidence and retention into Provenance, so the chain itself carries all four?

*Mechanism.* Those are exactly the concepts Provenance extracted in its EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) pass to stay freestanding, naming each composing home in its own edge cases. The composition is where they re-converge, and efficiently: Audit Trail already wires all three into one substrate, so one binding — entry to event — carries the whole surface (Wiring decision 1). Absorbing the three into Provenance would end its freestanding status and make every unregulated chain carry the regulated overhead.

*Result.* A records-alone custody proof neither constituent gives alone: an auditor holding the binding index, the chain and the substrate answers the four questions — who held it, was the transfer unbroken, was the record altered, was it kept long enough — without narration, source code or runbooks.

### Reconciliation

```
Reconciliation 1: The reconciliation MUST run at EVERY process start.
Reconciliation 2: The reconciliation MUST run every custody reconciliation cadence.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Reconciliation 4: The reconciliation MUST NOT write for an aged intent.
Deleted: Reconciliation 5. Execution Contract Database 2 owns it.
Deleted: Reconciliation 6. Execution Contract Database 2 owns it: the reconciliation's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for another holder to hold.
Reconciliation 7: The reconciliation MUST read EVERY Provenance entry against the outcome events.
Reconciliation 8: The reconciliation MUST read EVERY unmatched intent against the Provenance chain.
Reconciliation 9: IF an unmatched intent realizes no committed entry THEN the reconciliation MUST read the intent as a refused attempt.
Reconciliation 10: The reconciliation MUST pair an orphan entry to the unmatched intents realizing the entry.
Reconciliation 11: IF the candidate count EQUALS zero THEN the reconciliation MUST open an orphan-unpaired finding.
Reconciliation 12: IF the candidate count EQUALS zero THEN the reconciliation MUST NOT compensate the orphan.
Reconciliation 13: IF the candidate count EXCEEDS one THEN the compensating event MUST carry the intent candidates.
Reconciliation 14: IF the candidate count EXCEEDS the intent candidates cap THEN the reconciliation MUST escalate the orphan.
Reconciliation 15: IF the candidate count EXCEEDS the intent candidates cap THEN the reconciliation MUST NOT compensate the orphan.
Reconciliation 16: The reconciliation MUST pair an orphan transferred entry by the chain id, the incoming custodian AND the bound.
Reconciliation 17: IF the genesis lookup EXISTS THEN the reconciliation MUST pair a genesis intent to the chains the lookup answers by the custodian, the artifact reference, the genesis type AND the bound.
Reconciliation 18: IF the genesis lookup EQUALS blank THEN the reconciliation MUST open a genesis-unresolved finding for an unmatched genesis intent.
Reconciliation 19: IF the paired intent's actor DOES NOT EQUAL a transferred entry's outgoing custodian THEN the reconciliation MUST open a principal-divergence finding.
Reconciliation 20: The reconciliation MUST NOT compensate a principal divergence.
Reconciliation 21: The reconciliation MUST NOT record a compensating event BEFORE the reconciliation's recovery intent lands.
Reconciliation 22: The reconciliation MUST attest EVERY write the reconciliation makes under the recovery identity.
Reconciliation 23: A compensating event MUST carry the recovery flag, the acting custodian AND the intent reference.
Reconciliation 24: The reconciliation MUST re-derive a compensating event from the Provenance entry AND the intent's payload.
Reconciliation 25: The reconciliation MUST NOT record a compensating event BEFORE re-reading the custody enumeration for an outcome carrying the entry id.
Reconciliation 26: IF the re-read finds an outcome carrying the entry id THEN the reconciliation MUST bind the entry to the found outcome.
Reconciliation 27: The reconciliation MUST write the binding ONLY AFTER the compensating event lands.
Reconciliation 28: The reconciliation MUST escalate EVERY overdue orphan as an unresolved finding.
```

Term reconciliation: the leg the composition runs outside every invocation, whose output — a bound orphan or an escalation — an auditor awaits within the custody compensation window.

Term aged intent: an intent whose `recording instant + audit horizon` PRECEDES the reconciliation's now.

Term unmatched intent: an intent no outcome event names by intent event id or among its intent candidates.

Term refused attempt: an unmatched intent whose invocation committed nothing — the chain refused it.

Term orphan entry: a Provenance entry carrying no outcome event.

Term realize: an entry realizes an intent when the entry carries the intent's chain id, event type and parameters — the incoming custodian of a transfer, the descriptor of a transformation, the recipient of a disclosure — from the custodian the intent authenticated.

Term candidate count: how many unmatched intents realize one orphan entry.

Term intent candidates: the unmatched intents realizing one orphan entry where more than one does — intent_event_candidates.

Term intent reference: the intent event id where one intent realizes the entry, or the intent candidates.

Term compensating event: an outcome event the reconciliation records under the recovery identity.

Term overdue orphan: an orphan entry whose intent's `recording instant + custody compensation window` PRECEDES the reconciliation's now.

### Verdict

```
Verdict 1: The overall verdict MUST carry custody-proof-complete ONLY IF no class applies AND no entry carries a recovery attestation.
Verdict 2: IF no class applies AND an entry carries a recovery attestation THEN the overall verdict MUST carry custody-proof-complete-with-recovered-attestations naming the entries.
Verdict 3: IF a class applies THEN the overall verdict MUST carry custody-proof-incomplete naming EVERY class that applies.
Verdict 4: IF the continuity check answers gap-detected THEN gap-detected MUST apply.
Verdict 5: IF an entry carries binding-gap THEN binding-gap MUST apply.
Verdict 6: IF an entry carries binding-unknown THEN binding-unknown MUST apply.
Verdict 7: IF the binding rebuild opens a binding-duplicate finding for the chain THEN binding-duplicate MUST apply.
Verdict 8: IF an entry payload match carries entry-payload-mismatch THEN entry-payload-mismatch MUST apply.
Verdict 9: IF an actor match carries attribution-mismatch THEN attribution-mismatch MUST apply.
Verdict 10: IF an attestation verification carries a failed attestation THEN attestation-failed MUST apply.
Verdict 11: IF an attestation verification carries a failed seal THEN seal-failed MUST apply.
Verdict 12: IF an attestation verification carries unsealed THEN unsealed MUST apply.
Verdict 13: IF the verification answers not-known THEN binding-gap MUST apply.
Verdict 14: IF an attestation verification carries payload-not-supplied THEN payload-not-supplied MUST apply.
Verdict 15: IF an attestation verification carries an unavailable surface THEN availability MUST apply.
Verdict 16: IF an attestation verification carries partially-purged-coverage THEN partially-purged-coverage MUST apply.
Verdict 17: An attestation verification carrying purged MUST NOT apply as a class.
Verdict 18: A compensation-window qualifier MUST NOT apply as a class.
Verdict 19: An unknown carrying purged MUST NOT apply as a class.
```

Term continuity check: the replay of the chain's entries in sequence order with a running current-custodian cursor, answering continuous or gap-detected carrying the entry, the clause, the expected and the actual — a [Continuity Check].

Term class: a failure class, an incomplete-input class or the standing class — each blocks [Custody Proof Complete].

Term failure class: gap-detected | binding-gap | binding-unknown | binding-duplicate | entry-payload-mismatch | attribution-mismatch | attestation-failed | seal-failed | unsealed.

Term incomplete-input class: payload-not-supplied | availability.

Term standing class: partially-purged-coverage.

Term failed attestation: failed-verification carrying an attestation reason.

Term failed seal: failed-verification carrying seal-proof-invalid, seal-record-set-mismatch or seal-not-known.

Term unavailable surface: unverifiable carrying attestation-registry-unavailable or seal-mechanism-verification-unavailable.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent, and each needs Provenance and the Audit Trail substrate together.

- **Invariant 1 — Attributed custody.**
  ```
  Invariant 1.1: IF a settled entry carries no escalation THEN the entry MUST carry EXACTLY ONE outcome event whose action reference matches the entry's event type.
  Invariant 1.2: IF an outcome event carries no recovery flag THEN the event MUST carry an attestation of the acting custodian.
  Invariant 1.3: IF an outcome event carries the recovery flag THEN the event MUST carry an attestation of the recovery identity AND the acting custodian in the payload.
  Invariant 1.4: EVERY outcome event MUST name an intent of the matching kind attested under the acting custodian.
  ```
  Term settled entry: a Provenance entry whose outcome is past the custody compensation window of the entry's intent.

- **Invariant 2 — Tamper-evident custody chain.**
  ```
  Invariant 2.1: IF an outcome event's sequence number DOES NOT EXCEED sealed through THEN EXACTLY ONE seal MUST cover the event.
  Invariant 2.2: [Verify Custody] MUST answer failed-verification for a rewritten outcome event.
  ```
- **Invariant 3 — Retention-governed custody and honest disposal.**
  ```
  Invariant 3.1: EVERY custody event MUST carry a retention record from the audit write.
  Invariant 3.2: [Verify Custody] MUST answer failed-verification carrying purged for a lawfully destroyed event.
  ```
- **Invariant 4 — Binding bijection.**
  ```
  Invariant 4.1: The composition MUST NOT leave an orphan entry unsurfaced.
  Invariant 4.2: EVERY compensable orphan MUST land an outcome event WITHIN the custody compensation window.
  Invariant 4.3: Two outcome events MUST NOT name one entry id.
  Invariant 4.4: EVERY outcome event MUST name an entry the Provenance chain carries.
  Invariant 4.5: The reconciliation MUST escalate EVERY uncompensable orphan.
  Invariant 4.6: A principal divergence MUST NOT carry an outcome event.
  ```
  Term compensable orphan: an orphan entry paired to at most the intent candidates cap of realizing intents, whose outcome was not refused invalid-request(step-1 | step-2 | step-3), and — for a genesis orphan — in a deployment supplying the genesis lookup.

  Term uncompensable orphan: an orphan entry that is not compensable.

- **Invariant 5 — Records-alone custody proof.**
  ```
  Invariant 5.1: [Verify Custody] MUST answer the continuity, the attestation, the seal AND the retention of EVERY entry of the chain.
  ```
- **Invariant 7 — Authentication precedes commitment.**
  ```
  Invariant 7.1: The composition MUST NOT call a Provenance write BEFORE Audit Trail validates the acting custodian's credential at the intent.
  Invariant 7.2: A validated transfer MUST authenticate the outgoing custodian.
  Deleted: Invariant 6. Composes 5 owns it.
  ```

Continuity, attribution, seal and retention for the same entry give the *records-alone custody proof*; the bijection makes it total; authentication before commitment makes the attribution exact.

---

## Examples

### Walkthrough — pharmaceutical chain of custody under 21 CFR Part 211

A pharmaceutical manufacturer uses this composition to track batch X-91 from manufacturing through distribution to dispensing. Configuration: `audit_trail_retention_policy = pharma_7yr_predicate_rule` (encoding the applicable predicate-rule retention minimum), `seal_cadence = per-event` (ALCOA — Attributable, Legible, Contemporaneous, Original, Accurate — requires contemporaneous, tamper-evident records; per-event sealing satisfies this at the strongest cadence).

1. **Manufacturer originates the batch.** The quality-release officer calls `originate_custody(artifact_ref="batch-x91", custodian_ref="manuf-lab-7", genesis_type=originated, credential=<qro_credential>)` → `{chain_id="chain-0041", entry_id="e1", event_id="ev_1001"}`. Provenance opens the chain; `AuditTrail.record_action(custody.originated, actor_ref="manuf-lab-7", qro_credential, ...)` → `ev_1001`; `entry_to_event["e1"] = "ev_1001"`. The genesis is attributed and sealed.

2. **Transfer to regional distributor.** `transfer_custody(chain_id="chain-0041", to_custodian_ref="dist-region-3", credential=<lab7_credential>)` → `{entry_id="e2", event_id="ev_1002"}`. Provenance writes the transferred entry (`from_custodian_ref="manuf-lab-7"`, `to_custodian_ref="dist-region-3"`); the composition reads `from_custodian_ref = "manuf-lab-7"` and passes it as `actor_ref` to Audit Trail. The outgoing custodian's credential attests the release. `entry_to_event["e2"] = "ev_1002"`.

3. **Distributor transfers to hospital pharmacy.** `transfer_custody("chain-0041", "pharm-hosp-9", <dist_credential>)` → `{entry_id="e3", event_id="ev_1003"}`. `entry_to_event["e3"] = "ev_1003"`.

4. **Pharmacist transforms (dispenses dose).** `transform_custody("chain-0041", "pharm-hosp-9", "dispensed 10mg dose into dispensing unit D44", <pharm_credential>)` → `{entry_id="e4", event_id="ev_1004"}`. `entry_to_event["e4"] = "ev_1004"`.

5. **Archive at terminal disposition.** `archive_custody("chain-0041", "pharm-hosp-9", <pharm_credential>)` → `{entry_id="e5", event_id="ev_1005"}`. `entry_to_event["e5"] = "ev_1005"`. The Provenance chain is now Archived.

6. **FDA inspection.** The FDA inspector asks: *"Prove unbroken, attributed, tamper-evident, retention-compliant custody of batch X-91 under 21 CFR Part 211."* The system calls `verify_custody("chain-0041", original_event_payloads)` — the payload map retrieved from cold storage, keyed by audit-log `sequence_number` and covering every seal range the chain's events fall in; the two-argument form is the signature. The result:
   - `continuity_check = continuous` (every `from_custodian_ref` matches the prior holder).
   - For each of `e1`–`e5`: `attestation_verification = verified` (each attributed, each seal valid, each in `Retained` retention state).
   - `overall_verdict = custody-proof-complete`.
   The inspector sees a single structural answer to all four questions. Invariant 1 through 5 are the structural guarantees behind each field. The inspector consults no source code, no runbooks, no developer narration.

### Legal evidence — physical exhibit at trial under FRE 901(b)(9)

A detective collects exhibit-A at a crime scene, handled through forensic lab, evidence room, and courtroom. Each step uses this composition with credential bound to the individual officer's or lab's verified identity via the Audit Trail's Actor Identity. At trial, defense counsel challenges authentication under FRE 901(b)(9).

The prosecution calls `verify_custody(chain_id_of_exhibit_A, original_event_payloads)` — the payload map assembled from the evidence-room records, keyed by audit-log `sequence_number` over the covering ranges `read_record` names. The returned `custody-proof`:
- `continuity_check = continuous` — every transfer's `from_custodian_ref` matches the prior holder; no unattributed handler appears.
- Every entry's `attestation_verification = verified` — each custodian's credential was valid at the time of their action.
- `overall_verdict = custody-proof-complete`.

Defense counsel's claim — that the exhibit passed through an unrecorded, unverified handler — has no structural basis. Invariant 1 (attributed custody) and Provenance Invariant 4 (custody continuity) are the structural rebuttal. The exhibit is authenticated under FRE 901(b)(9)'s process-or-system standard.

### Rejection path — transfer by non-current custodian

A prior custodian, `"manuf-lab-7"`, attempts to record a transformation after having transferred to `"dist-region-3"`: `transform_custody("chain-0041", "manuf-lab-7", "added label update", <lab7_credential>)` → `rejected(not-current-custodian)`. The action writes the intent record `custody.transform_intended` first — `lab7_credential` validates, so the attempt is authenticated and durable — and Provenance's not-current-custodian guard then then catches the call: no Provenance entry is written, no **outcome** event is recorded, no `entry_to_event` binding is created, and the binding bijection (Invariant 4) is preserved, because it is over entries and outcome events and an intent record is neither. The chain's integrity is unchanged. **The intent record stands, and that is the point:** a former custodian attempting to alter a chain they no longer hold is precisely what a chain-of-custody trail should retain, and before the intent record existed the attempt left no trace anywhere. It surfaces among the unmatched intents Check 6.2 reads and is adjudicated against the Provenance chain, which shows the attempt was refused.

### Rejection path — custody action on an Archived chain

After the pharmaceutical chain is Archived (example step 5), a downstream system attempts another transfer: `transfer_custody("chain-0041", "disposal-unit-1", <credential>)` → `rejected(archived)`. Derived at the read-only resolution — which reads the terminal archived entry from chain state — and confirmed by Provenance's own guard had the call proceeded. **No state is written anywhere, and here that includes no intent record** — because the archive preceded the call: [Transfer Custody] alone resolves existence and archival state before its intent record, so its not-known and archived arms are refused earlier than the other three chain-addressed actions' constituent guards, which fire after theirs.

### Failure path — custody step whose audit write fails, recovered

A hospital pharmacist transfers a controlled-substance tote: `transfer_custody("chain-0107", "pharm-hosp-9", credential=<evid_room>)`. The intent `custody.transfer_intended` lands first — the evidence-room custodian's credential validates, so what follows is an authenticated attempt on the record. `Provenance.transfer` writes the entry (`entry_id = e5`); the outcome's `AuditTrail.record_action` returns recording-failure (the Event Log append answered nothing, its reply lost, and the `(step)` payload names step-3). The call returns `rejected(recording-failure(outcome))` — the position telling the pharmacist the entry exists and the action must not be re-run — and in the same outcome the orphan — a committed custody entry with no audit event — surfaces to the compliance dashboard as a high-priority finding. Recovery is the reconciliation's: at its next run it re-reads the log for an event carrying `data.entry_id = e5` and finds none (had the lost append landed after all, it would bind `e5` to that event instead), pairs `e5` to the transfer intent (chain, to_custodian_ref, the bound; the intent's actor equals the entry's `from_custodian_ref`, so this is the ordinary orphan), writes `custody.recovery_intended`, and lands the outcome under `recovery_identity` with `cascade_recovery = true` and the pharmacist named in `data.custodian_ref`. A later [Verify Custody] reports `e5` with `recovery_attested = true`, `actor_match = match(recovery)`, and an [Overall Verdict] of `custody-proof-complete-with-recovered-attestations([e5])` — structurally sound, surfaced for the auditor's judgment. Had the credential been bad, this path would never have been reached: it is refused at the intent with nothing committed.

### DEA controlled substance — 21 CFR Part 1304 inventory custody

A DEA-licensed pharmacy tracks each controlled substance dispensing as a separate artifact with its own chain under this composition. Each [Originate Custody] (pharmacy receives from supplier) → [Transfer Custody] (to dispensing cabinet) → [Transform Custody] (patient dispensing recorded) → [Archive Custody] sequence produces a complete attributed, sealed, retention-governed custody record per substance unit. A DEA compliance inspection calls [Verify Custody] for each in-scope chain and verifies the returned `custody-proof-complete` verdict. Every change of custody is attribution-stamped; every record is sealed; every record is retained per the applicable predicate rule.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts:

**Regulator audit — pharma: prove unbroken, attributed, tamper-evident, retention-honored custody of batch X-91 under 21 CFR Part 211.**

An FDA inspector runs `verify_custody("chain-0041", original_event_payloads)`. The returned `custody-proof`:
- `continuity_check = continuous`: by Provenance Invariant 4, every `from_custodian_ref` equals the prior to_custodian_ref (or genesis custodian_ref). The chain cannot have a gap because Provenance reads `from_custodian_ref` from chain state — no forged predecessor is possible.
- Per-entry `attestation_verification = verified`: by Invariant 1 (attributed custody), each entry has an outcome Audit Trail event whose Actor Identity attestation binds the custodian_ref to a credential — and, by Invariant 7, an intent event preceding the entry's commit under that same custodian, which is the stronger claim under Part 11's *Attributable* limb: the identity was checked before the custody step, not merely recorded after it. The Tamper Evidence seal (via Audit Trail Invariant 3) confirms no entry was rewritten.
- Per-entry `retention_state = Retained`: by Invariant 3, every entry is under active retention per the configured predicate-rule policy; none has elapsed.
- `overall_verdict = custody-proof-complete`.
The inspector's four questions — unbroken custody, verified attribution, tamper-evidence, retention honored — are answered from the records alone. No developer narration is required. Invariant 1 through 5 are the structural basis for each answer.

**Disputed transaction — legal evidence: defense claims tampering or an unattributed handler under FRE 901(b)(9).**

Defense counsel claims: (a) custody was broken (an unrecorded handler existed), or (b) a custodian was unverified (their identity was not attributable), or (c) the chain was tampered with (an entry was altered after the fact). The prosecution's [Verify Custody] result addresses each:
- Claim (a): `continuity_check = continuous`, resting on Provenance Invariant 4. If there were a gap, a transfer would have been recorded with a `from_custodian_ref` that did not match the prior holder — structurally impossible because Provenance reads `from_custodian_ref` from chain state.
- Claim (b): per-entry `attestation_verification = verified`, resting on Invariant 1 and Audit Trail Invariant 1. Each custodian's credential was verified by Actor Identity **before their custody step committed** — the intent record is the records-alone proof, and the outcome record's `intent_event_id` names it — so the claim is exact rather than approximate; the attestation is in the record.
- Claim (c): per-entry `attestation_verification` seal check (Invariant 2, Audit Trail Invariant 3). Any rewrite of an audit event produces a `failed-verification(seal-proof-invalid)` result. A rewrite of the Provenance chain itself is caught by the per-entry field-match clause (`entry_payload_match`): the sealed audit payload's copies are the anchored values, so a rewritten transformation_descriptor or a consistently rewritten from/to pair reports entry-payload-mismatch, while a removed binding reports binding-gap. Direct cryptographic sealing of the chain records themselves remains the composing Tamper-Evidence-on-Provenance concept the constituent's own edge case names.

**Breach or incident investigation: reconstruct custody during an anomaly window and bound the time of tampering via the Audit Trail seal cadence.**

An incident responder suspects a custody record was tampered with between two dates. The responder calls `verify_custody(chain_id, original_event_payloads)` with payloads from the suspect window. For each entry in the window:
- `attestation_verification = verified` for entries whose covering seal predates the anomaly: the seal is intact.
- `attestation_verification = failed-verification(seal-proof-invalid)` for entries whose seal was tampered with: the first such entry, and its seal's `sealed_at` and `anchored_at` (from the Tamper Evidence atom via Audit Trail), bound the window. The most recent seal that returns verified end-to-end and the first that returns `failed-verification(seal-proof-invalid)` define the forensic window — a bound that holds when the deployment **chains its seals** (each seal covering its predecessor's proof, a property of the substrate's seal mechanism, not of its cadence); without seal chaining the tampering bound is per-seal, not global. The `seal_cadence` governs the window's resolution.
- `attestation_verification = failed-verification(unsealed)` for entries in the unsealed tail: these are covered by Event Log per-event immutability but not yet seal-verified; a tighter `seal_cadence` would have narrowed this window.
Where seals carry `anchored_at` from a TSA (Time-Stamp Authority — a trusted third party that signs proofs of when data existed) outside the adversary's reach, the upper bound on tampering time is independently established. The forensic picture comes from the records alone.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when an external auditor, given the binding index, the Provenance chain records and the Audit Trail substrate's records, can clear the checks below without recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find a binding for EVERY entry of the chain that is no pre-horizon entry (Invariant 1.1).
Check 1.2: An auditor MUST find a passing verification for EVERY bound event whose covering range the auditor presents (Invariant 1.1).
Check 1.3: IF a bound event carries no recovery flag THEN an auditor MUST find the event's attesting actor matching the entry's custodian (Invariant 1.2).
Check 1.4: An auditor MUST find no event carrying the recovery flag attested under a custodian (Invariant 1.3).
Check 1.5: An auditor MUST find no event attested under the recovery identity carrying no recovery flag (Invariant 1.3).
Check 2.1: An auditor MUST find EVERY outcome event the sealed-through position covers carrying EXACTLY ONE verifying seal (Invariant 2.1).
Check 2.2: An auditor MUST report an outcome event in the unsealed tail as a seal-cadence finding (Invariant 2.1).
Check 3.1: An auditor MUST replay the chain's entries AND find the continuity check continuous (Invariant 5.1).
Check 4.1: An auditor MUST find EVERY outcome event's retention state IS IN Retained and Purged through the record read (Invariant 3.1).
Check 4.2: An auditor MUST find EVERY Purged outcome event carrying a Purged retention record whose purge instant DOES NOT PRECEDE the retention deadline (Invariant 3.2).
Check 5.1: An auditor MUST enumerate the chain's outcome events through the custody enumeration AND find EXACTLY ONE outcome event naming each entry (Invariant 4.3).
Check 5.2: An auditor MUST find EVERY outcome event naming an entry the chain carries (Invariant 4.4).
Check 5.3: An auditor MUST find the binding index agreeing with the enumerated outcome events (Composition state 3).
Deleted: Check 5.4. Execution Contract Database 3 and Execution Contract Database 4 own it.
Check 5.5: An auditor MUST report a principal divergence under the class's own finding (Invariant 4.6).
Check 5.6: An auditor MUST find the custody compensation window exceeding the liveness sum (Capability requirement 12).
Check 5.7: IF an orphan entry realizing no aged intent carries no open finding THEN an auditor MUST find the orphan's compensating event WITHIN the custody compensation window (Invariant 4.2).
Check 6.1: An auditor MUST find EVERY outcome event preceded by the intent the outcome's intent event id names, of the matching kind, on the same chain, under the acting custodian (Invariant 7.1).
Check 6.2: An auditor MUST NOT read an unmatched intent as a conformance failure (Reconciliation 9).
Check 6.3: An auditor MUST read a precedence check across the audit horizon as unverifiable carrying purged-horizon (Invariant 3.1).
Check 7.1: An auditor MUST clear Provenance's Generation acceptance over the Provenance instance (Composes 5).
Check 7.2: An auditor MUST clear Audit Trail's Generation acceptance over the Audit Trail instance (Composes 5).
```

NOTE: EVERY check names the rule the check tests.

Term passing verification: verified | failed-verification carrying purged.

### External checks

```
External check 1: An auditor needing a custodian's authority confirmed MUST read the deployment's Permissions records (Non-goal 5).
External check 2: An auditor needing an artifact reference's meaning confirmed MUST read the host's artifact registry (Non-goal 6).
External check 3: An auditor needing a jurisdiction's substantive standard confirmed MUST read the evaluating authority's own determination (Non-goal 7).
Deleted: External check 4. Execution Contract Database 2 owns it.
Deleted: External check 5. Execution Contract Database 3 owns it.
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT track a custody graph.
Non-goal 2: The composition MUST NOT hold two custodians of one chain at once.
Non-goal 3: The composition MUST NOT suspend a purge of the custody events.
Non-goal 4: The composition MUST NOT adjudicate an erasure request against a retention obligation.
Non-goal 5: The composition MUST NOT gate a custody action on the custodian's authority.
Non-goal 6: The composition MUST NOT validate an artifact reference against a registry.
Non-goal 7: The composition MUST NOT assess a jurisdiction's substantive standard.
Non-goal 8: The composition MUST NOT record an attempt the intent refused.
Non-goal 9: The composition MUST NOT record an audit event for a query.
Non-goal 10: The composition MUST NOT dispose of the Provenance chain.
Non-goal 11: The composition MUST NOT account for a disclosure's scope.
```

NOTE: the owners — a chain per sub-sample, each opened with a received genesis (Non-goal 1); a composing pattern (Non-goal 2); Erasure Coordination *(forthcoming)* (Non-goal 4); [Permissions](../atoms/permissions.md) (Non-goal 5, External check 1); the evaluating authority (Non-goal 7, External check 3); a Failed-Attempt Log *(forthcoming)* (Non-goal 8); an access-logging wrapper (Non-goal 9); a Retention Window or Defensible Retention instance applied to the chain directly (Non-goal 10, Retention asymmetry 1); [Selective Disclosure](../atoms/selective-disclosure.md) (Non-goal 11).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the Event Log sequence AND the Provenance sequence as the order of the composition's records.
Clock semantics 2: The composition MUST NOT claim a Provenance entry's recording instant AND the entry's event's recording instant equal.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```

### Retention asymmetry

```
Retention asymmetry 1: The composition MUST report an entry whose outcome event was lawfully purged as failed-verification carrying purged.
```

### Pre-genesis custody

```
Pre-genesis custody 1: The composition MUST NOT claim custody ahead of a chain's genesis entry.
```

### Rename

```
Rename 1: The composition MUST NOT change a recorded custodian reference for a rename.
```

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the five custody actions it wraps ([Originate Custody], [Transfer Custody], [Transform Custody], [Disclose Custody], [Archive Custody]) and the emergent verification ([Verify Custody]); the structure that verification answers ([Custody Proof]) with its [Continuity Check] and [Overall Verdict]; and the verdict's three values — [Custody Proof Complete], `custody-proof-complete-with-recovered-attestations` and [Custody Proof Incomplete]. The constituents' refusals are relayed by name. Attributed custody, the binding bijection and authentication before commitment are structural properties, not data. The deployment settings keep their wire spellings in configuration — `audit_trail_retention_policy`, `seal_cadence`, `custody_completion_bound`, `custody_compensation_window`, `custody_reconciliation_cadence`, `outcome_write_latency`, `recovery_identity`, `genesis_lookup`, `intent_candidates_cap` — and the binding index its own in an implementation, `entry_to_event`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the reconciliation; a deployment; a regulated deployment; an auditor; a caller; a custodian; an invocation; a custody action; a validated custody action; a bound custody action; a validated origination; an admitted origination; a committed origination; a validated transfer; a resolved transfer; an admitted transfer; a committed transfer; a confirmed transfer; a validated transformation; an admitted transformation; a validated disclosure; an admitted disclosure; a validated archival; an admitted archival.

Term records: the intents, outcome events and recovery intents the composition records through the audit write — each an Event Log event carrying one action reference below — and the binding index's entries.

Term record verbs: account, adjudicate, alert, answer, apply, assess, attest, authenticate, bind, call, carry, change, check, claim, classify, clear, compare, compensate, compose, cover, disclose, dispose, duplicate, enumerate, escalate, expose, fetch, find, follow, gate, hold, inherit, inject, inspect, key, land, leave, match, name, normalize, open, override, pair, pass, proceed, provision, re-derive, re-read, reach, read, rebuild, record, refuse, replay, report, resolve, retry, run, select, serve, set, start, store, supply, suspend, track, validate, write.

Term value sets: action reference = custody.originate_intended | custody.transfer_intended | custody.transform_intended | custody.disclose_intended | custody.archive_intended | custody.originated | custody.received | custody.transferred | custody.transformed | custody.disclosed | custody.archived | custody.recovery_intended. finding = binding-duplicate | principal-divergence | orphan-unpaired | genesis-unresolved. The rest are declared where the section that owns each declares it: genesis type, position, entry payload match, actor match, recovery attestation, class, failure class, incomplete-input class, standing class, Provenance refusal.

Term bounds: custody completion bound (custody_completion_bound), custody compensation window (custody_compensation_window), outcome write latency (outcome_write_latency), intent candidates cap (intent_candidates_cap), input caps, audit horizon (audit_trail_retention_policy).

Term cadences: custody reconciliation cadence (custody_reconciliation_cadence), seal cadence (seal_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive atoms, custody enumeration, record read, audit write, verification, custody action, entry id, chain id, binding index, binding, outcome event, live binding, purged binding, binding rebuild, audit retention policy, audit horizon, seal cadence, custody completion bound, custody compensation window, custody reconciliation cadence, outcome write latency, liveness sum, recovery identity, genesis lookup, intent candidates cap, input caps, artifact reference, custodian reference, recipient reference, transformation descriptor, genesis type, metadata, credential, caller string, acting custodian, intent, position, recovery intent, recovery flag, custody result, original event payloads, entry sequence, custody proof, validated custody action, Provenance refusal, bound custody action, validated origination, admitted origination, committed origination, validated transfer, resolved custodian, resolved transfer, admitted transfer, committed transfer, confirmed transfer, validated transformation, admitted transformation, validated disclosure, admitted disclosure, validated archival, admitted archival, purged later entry, pre-horizon entry, found verification, covering range, live event, entry payload match, actor match, recovery attestation, read passthrough, reconciliation, aged intent, unmatched intent, refused attempt, orphan entry, realize, candidate count, intent candidates, intent reference, compensating event, overdue orphan, continuity check, class, failure class, incomplete-input class, standing class, failed attestation, failed seal, unavailable surface, settled entry, compensable orphan, uncompensable orphan, passing verification.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. originate, transfer, transform, disclose, archive, read, entry, event type, outgoing custodian, incoming custodian, genesis custodian, sequence number, Archived, Open, invalid-ref, invalid-genesis-type, invalid-descriptor, not-known, archived, already-archived, not-current-custodian, storage-failure, invalid-query: Provenance. record_action, read_record, verify_record, payload cap, sealed through, unsealed tail, step-2, step-3, step-4, invalid-credential, invalid-request, recording-failure, verified, failed-verification, unverifiable, purged, compensation-window, Retained, Purged, Erasure Tombstone: Audit Trail. append, recording instant: Event Log.

Term composing patterns: [Defensible Retention](./defensible-retention.md); [Selective Disclosure](../atoms/selective-disclosure.md); [Permissions](../atoms/permissions.md); [Multi-Party Approval](./multi-party-approval.md).

#### Originate Custody

The composition action that opens a new Provenance custody chain for an artifact under a genesis custodian, binding the genesis entry to an attributed Audit Trail event (`custody.originated`). Returns `{chain_id, entry_id, event_id}`; the genesis custodian's credential attests the artifact entered custody under their hand.

Kind: Operation

#### Transfer Custody

The composition action that records a hand-to-hand transfer to a new custodian. The **outgoing** custodian attests the release — `from_custodian_ref` is read from Provenance's chain state (unforgeable, Provenance Invariant 4) and bound as the actor on the `custody.transferred` event; the incoming custodian attests their own later actions.

Kind: Operation

#### Transform Custody

The composition action recording a transformation of the artifact by the *current* custodian (Provenance enforces holder-only), bound to an attributed `custody.transformed` event.

Kind: Operation

#### Disclose Custody

The composition action recording a disclosure of the artifact by the current custodian to a named recipient — custody is *not* transferred — bound to an attributed `custody.disclosed` event.

Kind: Operation

#### Archive Custody

The composition action recording the terminal disposition by the current custodian and transitioning the chain to Archived — no further entries are accepted — bound to an attributed `custody.archived` event.

Kind: Operation

#### Verify Custody

The composition's emergent verification: construct the records-alone [Custody Proof] for a chain by replaying Provenance continuity ([Continuity Check]) and, for each entry, verifying its bound Audit Trail event's attestation, seal, and retention. Neither constituent can answer it alone; the caller presents the original event payloads (Audit Trail's verification asymmetry).

Kind: Operation

#### Custody Proof

The structured artifact [Verify Custody] returns: the chain's state, its [Continuity Check] result, an ordered per-entry sequence of attestation / seal / retention verifications, and a summary [Overall Verdict]. The records-alone proof of unbroken + attributed + tamper-evident + retention-governed custody that neither Provenance nor Audit Trail provides alone.

Kind: Type
Role: the records-alone custody proof

#### Continuity Check

The [Custody Proof] field carrying the result of replaying the Provenance entries in order and confirming every transfer's `from_custodian_ref` equals the custodian in effect immediately before it (Provenance Invariant 4, replayed on demand): `continuous`, or gap-detected naming the entry and the mismatch.

Kind:       Field
Field of:   the custody proof
Role:       the custody-continuity result
Projection: continuity_check

#### Overall Verdict

The [Custody Proof]'s summary field, with three values: [Custody Proof Complete] when continuity holds, every entry is bound, every supplied verification passes (or is lawful destruction), and no entry is recovery-attested; `custody-proof-complete-with-recovered-attestations(entry_ids)` — the same, except the named entries carry recovery attestations in place of the custodian's own, surfaced for the auditor's judgment; else [Custody Proof Incomplete] naming the specific failure, incomplete-input, and standing-coverage classes.

Kind:       Field
Field of:   the custody proof
Role:       the summary verdict
Projection: overall_verdict

#### Custody Proof Complete

The [Overall Verdict] value when the chain's continuity is unbroken, every entry has its audit-event binding, and every supplied attestation verifies (or is a lawful `failed-verification(purged)`) — the full custody is proven from the records alone.

Kind:       Member
Member of:  the overall verdict
Role:       Verdict
Projection: custody-proof-complete

#### Custody Proof Incomplete

The [Overall Verdict] value when at least one failure, incomplete-input, or standing-coverage class applies (a continuity gap, a binding gap or duplicate, an entry–payload mismatch, an attribution mismatch, a failed attestation, a seal failure, a not-supplied payload, an availability condition, or partially-purged seal coverage) — the proof is not fully self-proving, and the verdict names why per class.

Kind:       Member
Member of:  the overall verdict
Role:       Verdict
Projection: custody-proof-incomplete

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Originate Custody]: #originate-custody
[Transfer Custody]: #transfer-custody
[Transform Custody]: #transform-custody
[Disclose Custody]: #disclose-custody
[Archive Custody]: #archive-custody
[Verify Custody]: #verify-custody
[Custody Proof]: #custody-proof
[Continuity Check]: #continuity-check
[Overall Verdict]: #overall-verdict
[Custody Proof Complete]: #custody-proof-complete
[Custody Proof Incomplete]: #custody-proof-incomplete


## Standards references

This composition is the structural form of the chain-of-custody requirement across its canonical domains:

- **FDA 21 CFR Part 211 (Current Good Manufacturing Practice — Finished Pharmaceuticals)** — requires an unbroken, attributed, tamper-protected, retention-compliant chain of custody from manufacture through distribution for drug substances and products. The composition's [Originate Custody] → [Transfer Custody] → [Archive Custody] sequence, with per-entry attribution and seal via the Audit Trail substrate, is the operational form of Part 211's custodial recording requirement. The ALCOA / ALCOA+ (Attributable, Contemporaneous, Original, Accurate, plus Complete, Consistent, Enduring, Available) principles are all satisfied simultaneously by the four-atom stack inside the Audit Trail substrate, applied to every custody entry.

- **DEA 21 CFR Part 1304 (Controlled Substance Inventory Records)** — requires complete, accurate records of every change of custody of a controlled substance. Invariant 1 (attributed custody) and Invariant 5 (records-alone custody proof) are the structural implementation of this requirement at every transfer step.

- **Federal Rules of Evidence 901(b)(9) (Authenticating or Identifying Evidence — Process or System)** — the US evidentiary rule for authenticating physical or electronic evidence via chain-of-custody records. The composition's [Verify Custody] result — `continuity_check = continuous` plus per-entry `attestation_verification = verified` — is the structural form of the unbroken, attributed chain courts require for authentication. Invariant 4 (custody continuity) and Invariant 1 (attributed custody) are the rebuttal to authentication challenges.

- **ISO 23081 (Information and documentation — Managing metadata for records)** — the ISO (International Organization for Standardization) standard on records-management metadata. The composition's custody entries map directly to the origin, transfer, transformation, and disclosure metadata elements ISO 23081 specifies; the Audit Trail attribution and retention satisfy ISO 23081's authenticity and retention obligations.

- **W3C (the World Wide Web Consortium) PROV (Provenance Data Model — W3C's RDF (Resource Description Framework)-based standard for representing provenance as a directed acyclic graph)** — this composition implements the linear single-entity spine of a W3C PROV graph: the `wasGeneratedBy`, `used`, and `wasAttributedTo` relationships along a single entity's chain. The deliberate non-goal of `wasDerivedFrom` (DAG derivation) and artifact splitting are explicitly out of scope relative to the full PROV model.

- **SEC Rule 17a-4 (Records to be preserved by certain exchange members, brokers, and dealers)** — requires broker-dealer records (including custody records for financial instruments) to be preserved in a non-rewriteable, non-erasable format. The Audit Trail substrate's Tamper Evidence (Invariant 2) satisfies the integrity requirement; the configured `audit_trail_retention_policy` satisfies the lifetime requirement.

- **GDPR (EU General Data Protection Regulation) Article 17** — the right to erasure. An erasure request colliding with an FDA, DEA or court retention obligation over the custody events is a composed Erasure Coordination pattern's decision, not this composition's (Non-goal 4).

this composition inherits the broader standards compliance of its constituents:

- Through **Audit Trail** (and its transitive atoms): SOX (Sarbanes-Oxley Act) section 802 record retention, HIPAA (Health Insurance Portability and Accountability Act) section 164.312(b) audit controls, PCI DSS (Payment Card Industry Data Security Standard) Requirement 10, 21 CFR Part 11 electronic records, ISO/IEC (International Electrotechnical Commission) 27001 clause A.12.4 logging and monitoring, GDPR Articles 30 and 32, and the full Audit Trail standards inheritance. Deployments composing this composition for pharmaceutical or legal-evidence purposes receive these as the substrate's contribution; they are framed as inherited, not as this composition's own primary standards anchors.

- Through **Provenance**: ISO 23081, W3C PROV, FDA 21 CFR Part 211, DEA 21 CFR Part 1304, FRE 901(b)(9), and SEC Rule 17a-4 at the structural custody-chain layer. This composition lifts these to the full attributed+sealed+retention-governed form those standards actually require but that Provenance alone cannot satisfy.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation, 2026-08-30: the one-writer protocol (bounded in-invocation retry, scan under the per-chain section), the principal-divergence landing, and the genesis downgrade; was verified — chain-of-custody.tla + 2 twins; Invariant 7 not yet modelled, obligation open; 2026-06-11
last gate: 2026-08-30 — third gate, fresh reader, under the frozen rules — 5 foundational corrected in-round, 14 refining and 5 rhetorical routed (2 refining and the closure check's 3 residues and 7 consistency items also corrected in-round)

open:
- 2026-08-29-a · refining · formal · the model's compensation action carries no identity, no recovery record, and no age bound → extend the model with the bounded scan under `recovery_identity`
- 2026-08-30-v · refining · formal · the model has no `principal-divergence` landing outside the bijection → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/chain-of-custody.md`; the migration and the earlier gate records that got it here are in [its history](./chain-of-custody.hist.md).

- **2026-10-20 — The store's guarantees cited, not restated, and a custody action's writes one transaction.** *Chose:* Capability requirement 28 citing Execution Contract Store 1 through 4 for the store the chain, the substrate and the binding index keep their records in; the rules restating what that store guarantees tombstoned to it — the binding index's durability and the auditor's reading of it, the chain exclusion with its supply, holding, release, lease and the refusal to start without it, an invocation's release of it and the expiry of its lease, the reconciliation's take of it and the host's declaration an auditor read (Composition state 12, Capability requirement 13, 14, 16 through 21, Action wiring 6, Audit arm 20 through 22, Reconciliation 5, 6, Concurrency 1, 2, External check 4, 5); the rule denying that a Provenance entry and its outcome event commit together, which Store 1 as ruled contradicts (Wiring decision 2); and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the reconciliation's lower edge, the outcome retry attempts and the in-invocation retries with their pre-check and adoption, the read-back of a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing, the escalation of an invalid-request(step-4) whose event the read-back cannot find, which Audit Trail's evidence rule leaves appended, a recording-failure carrying outcome for a Provenance read that fails after the write, the mid-flight revocation and its re-attestation, which the one transaction's read of the actor registry forecloses, the principal divergence at [Transfer Custody], which the one transaction's resolution read forecloses, and the auditor's durability reading of an unbound pre-horizon entry (Reconciliation 3, Capability requirement 8, Audit arm 5, 11 through 18, Action wiring 10, 23 through 25, Check 5.4). Rules 263 to 228. *Over:* a Provenance write and an outcome append no transaction could span, so that each custody action was ordered across a durability boundary — the entry committed first, its outcome appended second — with a chain exclusion the host held across the invocation's retries as a lease, and a reconciliation that took the exclusion and paired what a crash between the writes left. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal. The Provenance write and the audit append are store writes, Provenance and Audit Trail each supplying theirs under Store 1 through 4, so a custody action's intent, entry and outcome commit together; and the chain exclusion, a host mutual exclusion over store-only work, is Store 2's, under which a custody action's reads of a chain and the writes they decide are one transaction. An Audit Trail refusal at an outcome still leaves the custody entry committed and its record owed (Audit arm 19, 24, 26), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the reconciliation's pairing, its candidates and their cap, the genesis lookup, the recovery identity behind a recovery intent, the re-read before a compensating event, the custody compensation window and the liveness sum it must exceed, and the escalation; the custody completion bound stays with them, since the liveness sum and the pairing still read it (Capability requirement 12, Reconciliation 16, 17). The binding index stays a derived index outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps it, so its rebuild on a miss and the binding-unknown reading of an entry no rebuild can reach stay (Composition state 7, Action wiring 36). Custody records are ordered by the Event Log's and Provenance's own sequence numbers (Clock semantics 1) and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.
- **2026-08-30 — One writer per entry, the purged answer first, the attestor named, the divergence landed, the genesis leg honest about what it can find.** *Chose:* an in-invocation retry bounded by `outcome_retry_attempts` and a scan that takes the per-chain section for every chain it touches, so the invocation and the scan never both land an outcome for one entry, with a binding-duplicate collision rule on the rebuild and check 5 quantified over the log; [Verify Custody] branching on retention state before any composition-side membership check, so a purged entry lands `failed-verification(purged)` and [Custody Proof Complete] stays reachable after a purge; an `actor_match` field and check-1 clause comparing the attestation's surviving `actor_ref` to the entry's custodian; `rejected(principal-divergence)` at [Transfer Custody] step 5 with no outcome written and a scan that never compensates it; `genesis_lookup` declared as an instance capability requirement, the genesis leg downgraded to *surfaced* without it; `recording-failure(intent | outcome)` on every signature; the liveness inequality written out with `outcome_write_latency`; `intent_candidates_cap` sizing the compensation envelope; and, on the closure check, `chain_serialization` declared as the instance capability the one-writer rule rests on, with a lease exactly the bound long whose expiry is the invocation's terminus, the transfer leg pairing by chain and recipient before it compares actors so a divergence is reachable at the scan, the zero-match landing (escalate, never compensate), and checks 2 and 4 quantified over the log. *Over:* "retry until it lands" beside a scan starting at the bound; a membership check ahead of the constituent's purged short-circuit; a check that confirmed the credential was valid and not whose it was; a code in the signature with no landing; a genesis leg that presumed a lookup Provenance declines; a bare token on both sides of the commit. *Because:* two compensators over one act land two outcomes the seal then protects; a lawfully destroyed payload is not one the caller failed to supply; a valid credential attesting a step its holder did not perform is the forgery the proof exists to catch; a committed entry nobody authenticated cannot be attested later without inventing an attribution; and a caller who cannot tell intent from outcome re-runs a committed act (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *A composition's own rejection arm carries the retry bit*, *Liveness is arithmetic*, *An outcome is sized before the intent*, and *Capability provenance* frozen — with §*Authentication precedence*'s binding half and §*A transcribed rejection arm*'s fourth tell).
- **2026-08-29 — The scan is bounded at both edges, pairs by parameters and names candidates, and writes as the recovery identity behind a recovery record; the outcome's step decides its landing.** *Chose:* `custody_completion_bound` below and the audit horizon above for the reconciliation scan; an orphan entry paired to its intent by chain, custodian, and the parameters the entry realizes, with `intent_event_candidates` where more than one unmatched intent matches; every scan write under `recovery_identity` behind `custody.recovery_intended` (the in-invocation retry keeping the custodian's credential and no marker); `recording-failure(step-4)` and the retention-source invalid-request at an outcome record read back and treated as landed at all five actions; `compensation_window`, `reconciliation_cadence` and `index_durability` declared; Invariant 4's "committed atomically or" restated as ordered. *Over:* an unbounded scan whose crash-side retry had no identity it could honestly use, and "all three arms surface as recording-failure" at the outcome. *Because:* an unbounded scan mints a second outcome beside an in-flight invocation's and re-emits lawful destruction as orphans; the custodian's credential is never persisted; and the substrate's step-4 arm means the event exists (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*, *Recovery commits under a declared service identity*, *A transcribed rejection arm keeps its payload*).

- **2026-08-27 — The verification presentation is keyed by audit-log position, not by custody entry.** *Chose:* original_event_payloads keyed by `sequence_number`, with [Verify Custody] assembling each entry's presentation from the covering range `read_record` names. *Over:* a map keyed by `entry_id` holding one payload per entry, or a wiring rule requiring per-event cadence. *Because:* the substrate's rule is that a seal commits to a sequence range whose members include intent records and unrelated actions carrying no `entry_id`; an entry-keyed map cannot present that set under any cadence but per-event, and pinning the cadence would trade a representational fix for a deployment constraint.
- **2026-06-11 — Invariant 4's compensated arm is in the model, not idealized away.** *Chose:* re-derive the model over sequential sub-writes with compensation. *Over:* the original model, which committed the sub-writes as one atomic action. *Because:* the Provenance write is irreversible and the audit append cannot be withdrawn, so the compensated path is the design.
- **2026-08-26 — [Transfer Custody] resolves the outgoing custodian before it authenticates, and authenticates before it commits.** *Chose:* a read-only resolution step, then the intent record under the outgoing custodian's credential, then the Provenance call; invalid-credential restored to all five signatures, reversing Final Critique 5's F2 on new grounds. *Over:* declaring the pre-check "a deployment obligation" (Final Critique 5's F-6 closure), or authenticating the incoming caller, the only principal available earlier. *Because:* a declaration discharges nothing the records can show, and the guarantee names the outgoing custodian, a principal produced by the commit.

NOTE: End of Chain of Custody.
