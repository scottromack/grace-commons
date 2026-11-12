---
title: Chain of Custody
id: 12
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

Chain of Custody is a regulated composition (a spec that wires two or more atoms — freestanding, self-contained pattern specs — together) that solves the chain-of-custody problem no single atom solves alone: making it provable that an artifact moved through an unbroken sequence of verified, non-repudiable (unable later to deny the act) custodians, that no entry was tampered with, and that the chain was kept for the required period. It wires two constituents: Provenance (the append-only custody chain with structural continuity — one current custodian at all times, hand-to-hand transfers) and the Audit Trail substrate (the tamper-evident — designed so unauthorized changes are detectable — regulated-audit substrate that attribution-stamps and seals every custody event via the Event Log, Actor Identity, Retention Window, and Tamper Evidence atoms it contains).

The composition's defining emergent guarantee is provable custody: a single query, `verify_custody(chain_id, original_event_payloads)`, returns the full ordered chain with, per entry, the verified attribution of the acting custodian (who authorized this step), the tamper-evident seal status (has the entry been altered), and the retention state (is the entry still held lawfully) — plus a continuity check confirming that every transfer's outgoing custodian equals the prior holder. This is the provable answer to the regulator's, judge's, or auditor's four questions — *who held it, was the transfer unbroken, was the record altered, was it kept long enough*. Neither Provenance alone nor Audit Trail alone produces this answer; the composition is what wires them into a single custody-proof surface. Each custody step follows [Recoverable Invocation](./recoverable-invocation.md)'s protocol around its Provenance write — an intent before it, the outcome after it — so a step whose audit record never landed, from a lost reply or a crash between the write and its record, is closed by that composition's sweep, its record attested as recovered, and the four answers hold for it too.

Its most common uses are pharmaceutical chain of custody under FDA (US Food and Drug Administration) 21 CFR (Code of Federal Regulations) Part 211 and DEA (US Drug Enforcement Administration) 21 CFR Part 1304 (controlled substance inventory), physical-evidence authentication under FRE (Federal Rules of Evidence) 901(b)(9), financial instrument custody records under SEC (US Securities and Exchange Commission) Rule 17a-4, and digital-file chain of custody under ISO (International Organization for Standardization) 23081 (records-management metadata). Any system that must make it provable that every step in an artifact's journey was attributed, sealed, and retention-governed is a candidate for this composition.

---

## Intent

Every domain that must account for an artifact's journey faces the same four-part requirement: the chain must be unbroken (no gap in custody, hand-to-hand transfers with no unattributed interval), the custodians must be verified (each hand-off attributed to a real actor, not just an opaque reference), the chain must be tamper-evident (any after-the-fact rewrite provable), and the chain must be retention-governed (retained for its regulatory lifetime and lawfully destroyable with a defensible record of destruction). No single atom satisfies all four. Provenance supplies the first. Audit Trail supplies the third and fourth, and transitively the second via Actor Identity. But neither provides the full custody-proof surface until they are wired together: Provenance does not verify its opaque custodian_ref values and does not seal its chain; Audit Trail does not know what a custody chain is or that its events need to be tied to custody entries. The wiring is this composition.

The cross-domain structural identity is the composition's thesis. Under FDA 21 CFR Part 211 (Current Good Manufacturing Practice for Finished Pharmaceuticals), a pharmaceutical manufacturer must demonstrate an unbroken, attributed, tamper-protected, retention-compliant chain of custody from manufacture through distribution to dispensing. Under FRE 901(b)(9) (Authentication by Process or System), an officer presenting physical evidence at trial must authenticate the exhibit via an unbroken custody chain in which every handler is identified. Under DEA 21 CFR Part 1304 (Controlled Substance Inventory Records), a complete, accurate record of every change of custody for a controlled substance is a legal obligation. The structural form is identical across all three domains: one artifact, one current custodian at all times, hand-to-hand transfers, each hand-off attributed and verifiable, the record sealed against tampering, and the record retained for its regulatory lifetime. One grounded composition satisfies all three.

This is a composition, not a new primitive. Provenance, Audit Trail (with its constituent atoms, Event Log, Actor Identity, Retention Window, and Tamper Evidence — reached transitively) and Recoverable Invocation are unchanged. The composition is the wiring that makes them coherent as a single chain-of-custody surface. It introduces emergent actions — [Originate Custody], [Transfer Custody], [Transform Custody], [Disclose Custody], [Archive Custody], [Verify Custody] — that belong to no single constituent and exist only because the two are wired together. [Verify Custody] in particular belongs to neither constituent alone: Provenance can verify structural continuity but cannot verify attribution or tamper-evidence; Audit Trail can verify attribution and tamper-evidence but does not know which events constitute a custody chain. The composition is the layer that answers: *is this custody chain complete, attributed, sealed, and within its retention horizon?*

What the composition is *not*: it is not a DAG-model (DAG — directed acyclic graph) provenance tracker (the linear single-artifact constraint is inherited from Provenance); it is not a multi-party simultaneous custody surface; it is not the legal-hold suspension layer over custody chains (that is Legal Hold / Defensible Retention); it is not the artifact-registry layer (validating that artifact_ref names a real artifact in the host system is the host's obligation); and it is not the clock-authority layer (inherited from Audit Trail). Each is named explicitly in Non-goals.

---

## Composes

- **[Provenance](../atoms/provenance.md)** — the structural custody chain: one current custodian at all times, hand-to-hand transfers, the outgoing custodian read from chain state.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate: every custody action records through it, and each record is appended to Event Log, attested by Actor Identity, placed under Retention Window and sealed by Tamper Evidence at the configured cadence.
- **[Recoverable Invocation](./recoverable-invocation.md)** — the protocol the five custody actions follow around the Provenance write: an intent before it, an outcome after it, and a sweep that closes the record of a write whose outcome never landed; this page restates none of it.

```
Composes 1: EXACTLY ONE Provenance instance MUST serve the composition.
Composes 2: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 3: The composition MUST reach a transitive atom ONLY through the constituent that composes the atom.
Composes 4: The composition MUST NOT compose an instance of a transitive atom.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST NOT change a constituent's spec.
Composes 7: The composition MUST select the custody events through the custody enumeration.
Deleted: Composes 8. Composes 9 owns it.
Composes 9: The composition MUST NOT read Audit Trail records directly.
Composes 10: IF the custody enumeration answers invalid-query THEN the deployment MUST alert on a deployment fault AND [Verify Custody], whose binding rebuild reads the enumeration, MUST answer state-unavailable.
NOTE: open 2026-11-11-e — the rule answers state-unavailable at [Verify Custody] alone, while Composition state 7 obliges the composition to rebuild a missing binding without naming the actions that run the rebuild.
Deleted: Composes 11. Recoverable Invocation Action wiring 4 and Action wiring 6 own it: a bound custody action writes its intent, outcome and refusal records through the invocation open, close and refuse.
Composes 12: EXACTLY ONE Recoverable Invocation instance MUST serve the composition.
Composes 13: The Recoverable Invocation instance MUST write to the composition's Audit Trail instance.
Composes 14: The composition MUST bind the act kinds PER the custody bindings.
Composes 15: The composition MUST NOT bind an action other than a custody action as an act kind.
Composes 16: The composition MUST NOT hold an instance of Lease, which Recoverable Invocation reaches.
```

Term composition: this pattern's wiring of [Provenance](../atoms/provenance.md), [Audit Trail](./audit-trail.md) and [Recoverable Invocation](./recoverable-invocation.md) — the five custody actions, the verification, the binding index, the custody bindings and the write-ownership leg.

Term constituents: [Provenance](../atoms/provenance.md), [Audit Trail](./audit-trail.md), [Recoverable Invocation](./recoverable-invocation.md).

Term transitive atoms: [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md), [Retention Window](../atoms/retention-window.md) and [Tamper Evidence](../atoms/tamper-evidence.md), reached through Audit Trail, and [Lease](../atoms/lease.md), reached through Recoverable Invocation.

Term custody enumeration: Event Log's read by sequence-number range with an open upper bound, passed through Audit Trail unchanged, with every selection by action reference and payload field made in the composition's own code.
NOTE: open 2026-11-10-c — Audit Trail's declared surfaces list no enumeration, so the passthrough this term and Capability requirement 25 name has no declared provider; Audit Trail Action wiring 1 is its only home, and the same form stands on four other pages.

Term record read: Audit Trail's read_record on an event id — the substrate's declared consolidated read surface.

Term audit write: Audit Trail's record_action.

Term verification: Audit Trail's verify_record on an event id and a presentation.

Term attestation verification: what a found verification carries for an entry in place of Audit Trail's answer — the verification's outcome and, where the outcome carries one, its reason, with the verification's compensation-window qualifier, where the outcome carries one, riding beside it (Action wiring 43, 44), or payload-not-supplied with the missing sequence numbers where the verification is not called (Action wiring 41), or unknown carrying not-known where the record read answers not-known (Action wiring 62).

Term custody action: [Originate Custody], [Transfer Custody], [Transform Custody], [Disclose Custody] or [Archive Custody].

Term act kind: custody.originate, custody.transfer, custody.transform, custody.disclose or custody.archive — the five act kinds this composition binds on its Recoverable Invocation instance, one per custody action, each with its own commit and probe and the outcome references Term custody bindings names.

Term custody bindings: each act kind's bindings, under the name Recoverable Invocation gives each. For custody.originate: act key — the origination key; commit — the origination transaction; journal events — custody.originate.intended, the outcomes custody.originate.originated and custody.originate.received, custody.originate.refused; act probe — the originate probe. For custody.transfer: act key — the chain id; commit — the transfer transaction; journal events — custody.transfer.intended, the one outcome custody.transfer.transferred, custody.transfer.refused; act probe — the step probe. For custody.transform, custody.disclose and custody.archive: act key — the chain id; commit — Provenance's transform, disclose or archive; journal events — the kind's intended record, the one outcome custody.transform.transformed, custody.disclose.disclosed or custody.archive.archived, the kind's refused record; act probe — the step probe. For all five: pairing datum — the invocation's now, which the host injects into Provenance's seam so that the entry's recording instant equals it (Capability requirement 34); repeatable — yes; invocation completion bound — the custody completion bound; commit round trip and probe round trip — the deployment's disclosed bounds; journal — the composition's Audit Trail instance; retention period — the audit horizon; settling period — the deployment's settling period; service identity — the recovery identity; outcome envelope — sized from the input caps and the minted ids (Capability requirement 24).

Term origination key: the artifact reference, the custodian reference and the genesis type. The chain id is minted by the origination, so it is not known at the open — the minted-key deviation (Recoverable Invocation Deviation 4), declared here as Immutable Ledger declares it. Provenance admits a second chain for one artifact and never refuses a second origination (Provenance Identity 10), so two originations of one key are two acts, repeatable being yes.

Term origination transaction: Provenance's originate, then Provenance's read of the genesis entry at sequence number one, committed together or not at all (Execution Contract Database 1) — the one commit Recoverable Invocation's bound commit stands for for custody.originate (Composition notes).

Term transfer transaction: Provenance's read of the chain's latest entry, the comparison of the holder it shows with the transfer intent's outgoing custodian, and Provenance's transfer, committed together or not at all (Execution Contract Database 1, Database 2) — the one commit for custody.transfer (Composition notes).

Term commit partition: committed where the commit answers an entry id, the origination its chain id and its genesis entry's id; pre-commit where Provenance refuses the write — a Provenance refusal or storage-failure, a refused write taking no sequence number (Provenance Operation 41 through 44) — where the transfer transaction's re-read finds the chain archived or held by another custodian (Action wiring 64, 65), or where the database answers state-unavailable (Execution Contract Constituent failure 3); unknown where a call answers a code Provenance does not declare, or where its reply has not arrived when the commit round trip has elapsed since the call's issue (Recoverable Invocation commit 6, commit 7).

Term originate probe: the read that answers whether an open origination intent's chain committed. Through the genesis lookup, the chains originated for the intent's artifact reference; for each, Provenance's read at sequence number one, filtered by the intent's genesis type as event type and the intent's pairing datum as the recording instant range, kept in the composition's code to an entry carrying the intent's custodian reference. Exactly one entry answers committed carrying the chain id, the entry id, the custodian reference and the genesis type; none answers not-committed; more than one answers undecidable carrying them; a lookup or read refused or unanswered answers unavailable (Recoverable Invocation act probe 2 through 4). Where the deployment supplies no genesis lookup, the probe is set to undecidable for the kind (Recoverable Invocation Deviation 4c), and the sweep escalates every open origination intent it examines.

Term step probe: the read that answers whether an open intent of custody.transfer, custody.transform, custody.disclose or custody.archive committed. Provenance's read of the intent's chain id, filtered by the kind's event type and the intent's pairing datum as the recording instant range, kept in the composition's code to an entry carrying the intent's parameters — the outgoing and incoming custodians of a transfer, the custodian reference and descriptor of a transformation, the custodian and recipient references of a disclosure, the custodian reference of an archival. Exactly one entry answers committed carrying the chain id, the entry id and the entry's compared fields, each re-derived from the entry (Recoverable Invocation act probe 6); none answers not-committed; more than one answers undecidable carrying them; a read refused (not-known, invalid-query) or unanswered answers unavailable (Recoverable Invocation act probe 4).

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
Composition state 15: The composition MUST NOT store a record of the Recoverable Invocation instance.
```

Term entry id: the opaque id Provenance mints for a custody entry.

Term chain id: the opaque id Provenance mints for a custody chain.

Term binding index: the composition's map from a custody entry to the outcome event that attributes, seals and retention-governs it — `entry_to_event` in an implementation.

Term binding: one entry id with its outcome event id.

Term outcome event: the custody.originate.originated, custody.originate.received, custody.transfer.transferred, custody.transform.transformed, custody.disclose.disclosed or custody.archive.archived event, carrying the entry id — one the invocation close wrote, one Recoverable Invocation's sweep recovered under the recovery identity, or one an operator wrote through the invocation resolve.

Term invocation-written outcome event: an outcome event the invocation close wrote or one Recoverable Invocation's sweep wrote under the recovery identity — never one an operator wrote through the invocation resolve.

Term live binding: a binding whose outcome event's payload the audit horizon has not reached.

Term purged binding: a binding whose outcome event's payload the audit horizon has destroyed.

Term binding rebuild: the custody enumeration from the log's start, kept to the outcome events whose entry id the chain's Provenance entries carry, re-keyed by that entry id.

### Capability requirement

```
Capability requirement 1: A deployment MUST set the audit retention policy on the Audit Trail instance.
Capability requirement 2: The composition MUST NOT pass a retention input to the audit write.
Capability requirement 3: A regulated deployment MUST set an audit retention policy encoding the regime's minimum custody-record retention.
Capability requirement 4: A deployment MUST set the seal cadence on the Audit Trail instance.
Capability requirement 5: The composition MUST NOT override the seal cadence.
Capability requirement 6: A deployment MUST set the custody completion bound.
Deleted: Capability requirement 7. Execution Contract Logic confinement 15 owns it: a required setting blank keeps the instance from starting.
Deleted: Capability requirement 8. Execution Contract Database 1 owns it.
Deleted: Capability requirement 9. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 10. Recoverable Invocation sweep cadence 2 and sweep cadence 3 own it.
Deleted: Capability requirement 11. Recoverable Invocation run bound owns it: the sweep's own, and the write-ownership leg runs inside it.
Deleted: Capability requirement 12. Recoverable Invocation Instance start 4 owns it: the worst closure against the closure window.
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
NOTE: open 2026-11-04-e — the minted ids' width is no bound Provenance declares, so the payload cap is summed over capped inputs alone.
Capability requirement 25: The wired Audit Trail instance MUST expose the custody enumeration.
Capability requirement 26: The host MUST inject now, the invocation id, the run id AND the operator run id at the seam once PER invocation.
Deleted: Capability requirement 27. Recoverable Invocation Primitive policy 18 owns it for the sweep, and the write-ownership leg reads the sweep's run reading (Reconciliation 31).
Capability requirement 28: The deployment MUST supply the database PER Execution Contract Database 1 through 4, AND the act section PER Execution Contract Database 7 AND Execution Contract Refusal 1 (Recoverable Invocation Capability requirement 12).
Deleted: Capability requirement 29. Recoverable Invocation Instance start 5 owns it: the retention floor.
Deleted: Capability requirement 30. Recoverable Invocation clock allowance owns it: one allowance, set at the instance, covering the widest pair of the clocks.
Deleted: Capability requirement 31. Recoverable Invocation clock allowance and Recoverable Invocation Instance start 4 own it: the allowance is the instance's setting, and a start condition reading a blank one does not pass.
Deleted: Capability requirement 32. Recoverable Invocation run bound owns it: the sweep's own, and the write-ownership leg runs inside it.
Capability requirement 33: A deployment MUST supply an enumeration of EVERY chain id Provenance holds.
Capability requirement 34: The host MUST inject the invocation's now into Provenance's seam for the appending write of a custody action, so that the entry's recording instant EQUALS the intent's pairing datum.
Capability requirement 35: The host MUST NOT inject an equal now into two invocations of one act key AND MUST NOT inject an equal now into two invocations of custody.originate carrying an equal custodian reference AND an equal genesis type, on any node of the instance.
Capability requirement 36: A deployment MUST supply the act section Recoverable Invocation takes (Recoverable Invocation Capability requirement 11).
Capability requirement 37: A deployment MUST disclose the commit round trip, the probe round trip AND the settling period.
Capability requirement 38: A deployment MUST set the instance's bounds PER Recoverable Invocation Instance start 4 through 8.
Capability requirement 39: A deployment MUST NOT remove a Provenance entry BEFORE the audit horizon destroys the payload of the entry's outcome (Recoverable Invocation Binding 9).
Capability requirement 40: A deployment MUST NOT set the unsealed tail mode to lenient on the Audit Trail instance.
```

Term audit retention policy: the policy reference configured on the composition's single Audit Trail instance, governing the lifetime of every custody event — never the Provenance chain itself.

Term audit horizon: the audit retention policy's horizon, past which a custody event's payload is lawfully destroyed.

Term seal cadence: Audit Trail's per-event | interval-based | on-demand setting, which fixes each custody event's covering range.

Term custody completion bound: the deployment's declared maximum for a custody action's invocation — each act kind's invocation completion bound: the longest it takes from the invocation open's take of the critical section to the invocation close's last write (the invocation yield's return where the commit answers an unknown arm), the Provenance round trip included.

Term required setting: the custody completion bound, the input caps, the intent candidates cap, the commit round trip, the probe round trip, the settling period or the recovery identity.

Term reconciliation run bound: Recoverable Invocation's run bound on this composition's instance, inside which the write-ownership leg runs.

Term recovery identity: a deployment-provisioned actor reference and credential — the service identity under which Recoverable Invocation's sweep attests every write it makes for the five act kinds.

Term genesis lookup: the deployment-supplied lookup from an artifact reference to the chains originated for it.

Term intent candidates cap: Recoverable Invocation's intent candidates cap on this composition's instance — the most database candidates an escalation names.

Term input caps: the composition-layer byte caps on the artifact reference, the custodian references, the recipient reference and the transformation descriptor.

Term clock offset allowance: Recoverable Invocation's clock allowance on this composition's instance.

Term invocation id: the fresh id the host injects at the seam per custody action, carried by every record the invocation writes (Recoverable Invocation Term invocation id).

Term commit round trip: the deployment's disclosed bound on one commit, from issue to reply — the origination transaction, the transfer transaction, or Provenance's transform, disclose or archive.

Term probe round trip: the deployment's disclosed bound on one act probe, from issue to answer.

Term settling period: the time the deployment declares for an operator to settle an escalated act through the invocation resolve (Recoverable Invocation Term settling period).

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

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
Primitive policy 10: A custody action MUST NOT call a constituent BEFORE Primitive policy 1 through 8 pass (Recoverable Invocation Action wiring 4).
Primitive policy 11: The composition MUST compare a chain id, an entry id, an event id AND a caller string byte-exact.
Primitive policy 12: The composition MUST NOT normalize a caller string.
Primitive policy 13: The composition MUST NOT inspect a credential beyond Primitive policy 6.
Deleted: Primitive policy 14. Recoverable Invocation Term outcome shape and Recoverable Invocation Check 2.5 own it: the invocation close writes the outcome under the intent's actor reference, which Primitive policy 16 and Action wiring 20 make the acting custodian.
Primitive policy 15: The composition MUST NOT pass the metadata to Recoverable Invocation.
Primitive policy 16: The composition MUST pass the custodian reference of EVERY custody action to the invocation open as the actor reference, [Transfer Custody] excepted (Action wiring 20).
```

Term artifact reference: the opaque reference to the artifact whose custody a chain tracks — never validated against a registry here.

Term custodian reference: the opaque reference to the custodian performing or receiving a custody step.

Term recipient reference: the opaque reference to the party a disclosure names.

Term transformation descriptor: the non-blank description of a transformation the current custodian applied.

Term genesis type: originated | received — Provenance's.

Term metadata: the optional opaque payload [Originate Custody] passes to Provenance unchanged.

Term credential: the acting custodian's opaque credential material, validated by the substrate inside the intent record the invocation open writes (Recoverable Invocation Invariant 1.1).

Term caller string: an artifact reference, a custodian reference, a recipient reference or a transformation descriptor.

Term acting custodian: the genesis custodian for [Originate Custody]; the outgoing custodian for [Transfer Custody]; the current custodian for [Transform Custody], [Disclose Custody] and [Archive Custody].

### Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Primitive policy 19 owns it for the intent of the five bound actions.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 41 owns it for the intent of the five bound actions.
Deleted: Audit arm 3. Recoverable Invocation Primitive policy 23 owns it for the intent of the five bound actions.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 43 owns it for the five bound actions.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Deleted: Audit arm 6. Recoverable Invocation Primitive policy 27 owns it: the outcome's invalid-request(step-4) is read back by invocation id.
Deleted: Audit arm 7. Recoverable Invocation Primitive policy 35 owns it: the read-back matches by invocation id over the delta range, not by action reference and intent event id over the log.
Deleted: Audit arm 8. Recoverable Invocation Primitive policy 35 owns it.
Deleted: Audit arm 9. Recoverable Invocation Primitive policy 28 owns it.
Deleted: Audit arm 10. Recoverable Invocation Primitive policy 28 owns it: a found read-back returns success with a hard alert.
Deleted: Audit arm 11. Execution Contract Database 1 owns it.
Deleted: Audit arm 12. Execution Contract Database 1 owns it.
Deleted: Audit arm 13. Execution Contract Database 1 owns it.
Deleted: Audit arm 14. Recoverable Invocation reconcile step 2.4 through 2.6 and Execution Contract Database 1 own it.
Deleted: Audit arm 15. Recoverable Invocation reconcile step 2.4 through 2.6 and Execution Contract Database 1 own it.
Deleted: Audit arm 16. Execution Contract Database 2 owns it.
Deleted: Audit arm 17. Execution Contract Database 2 owns it: a custody action's attestations read the actor registry inside one transaction, so no invocation re-attests an outcome.
Deleted: Audit arm 18. Execution Contract Database 1 owns it: a custody action's writes commit together, so no invocation retries an outcome.
Deleted: Audit arm 19. Recoverable Invocation commit 8d, Recoverable Invocation Primitive policy 30 and Recoverable Invocation Primitive policy 31 own it: an outcome that does not land answers recording-failure(outcome).
Deleted: Audit arm 20. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Audit arm 21. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Audit arm 22. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Audit arm 23. Recoverable Invocation Invariant 8.3 owns it: recording-failure(intent) is a committed nothing.
Deleted: Audit arm 24. Recoverable Invocation Invariant 8.4 owns it: recording-failure(outcome) is an act that may exist, whose record the sweep closes.
Deleted: Audit arm 25. Recoverable Invocation Primitive policy 41 owns it for the intent of the five bound actions.
Deleted: Audit arm 26. Recoverable Invocation Primitive policy 42 owns it: the hard alert on the outcome's invalid-request below step-4.
Deleted: Audit arm 27. Recoverable Invocation Primitive policy 31 owns it.
Deleted: Audit arm 28. Recoverable Invocation Primitive policy 42 owns it.
Audit arm 29: A custody action MUST answer the arms of the records Recoverable Invocation writes for the action PER Recoverable Invocation's Action wiring table.
```

Term intent: a custody action's record before its Provenance write — the custody.originate.intended, custody.transfer.intended, custody.transform.intended, custody.disclose.intended or custody.archive.intended record the invocation open writes, the one that verifies the caller's credential (Recoverable Invocation Primitive policy 19); carrying the invocation's parameters other than the credential and the metadata, the pairing datum, and no constituent-minted id.

Term position: intent | outcome — Recoverable Invocation's (Recoverable Invocation Primitive policy 19 through 31): where a recording-failure of a custody action sat.

Term recovery flag: Recoverable Invocation's recovery set to true — carried by an outcome its sweep wrote under the recovery identity or an operator wrote through the invocation resolve, and by no other (Recoverable Invocation Term recovery).

### Action wiring

```
originate_custody(artifact_ref, custodian_ref, genesis_type, credential, optional metadata)
  answers custody result | recording-failure(outcome)
  refuses invalid-ref | invalid-genesis-type | invalid-credential | invalid-request | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

transfer_custody(chain_id, to_custodian_ref, credential)
  answers custody result | recording-failure(outcome)
  refuses invalid-ref | invalid-credential | not-known | archived | state-unavailable | invalid-request | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | not-current-custodian | storage-failure | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

transform_custody(chain_id, custodian_ref, transformation_descriptor, credential)
  answers custody result | recording-failure(outcome)
  refuses invalid-ref | invalid-descriptor | invalid-credential | invalid-request | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | not-known | archived | not-current-custodian | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

disclose_custody(chain_id, custodian_ref, recipient_ref, credential)
  answers custody result | recording-failure(outcome)
  refuses invalid-ref | invalid-credential | invalid-request | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | not-known | archived | not-current-custodian | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

archive_custody(chain_id, custodian_ref, credential)
  answers custody result | recording-failure(outcome)
  refuses invalid-ref | invalid-credential | invalid-request | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | not-known | already-archived | not-current-custodian | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

verify_custody(chain_id, original_event_payloads)
  answers custody proof
  refuses not-known | state-unavailable

read(chain_id, optional query)
  answers entry sequence
  refuses not-known | invalid-query | state-unavailable
```

Term custody result: the entry id and the outcome event id, and for [Originate Custody] the chain id.

Term original event payloads: the caller's map from an audit-log sequence number to the byte-exact payload Event Log holds at that position.
NOTE: open 2026-11-06-i — the map has no cardinality cap.

Term entry sequence: the chain's entries in sequence order — Provenance's read answer.

Term custody proof: what [Verify Custody] answers — a [Custody Proof].

```
Deleted: Action wiring 1. Recoverable Invocation Action wiring 4 and Recoverable Invocation Invariant 1.1 own it: the commit follows the invocation open, whose intent record verified the credential.
Deleted: Action wiring 2. Primitive policy 16 and Action wiring 12, 20, 27, 29 and 31 own it.
Deleted: Action wiring 3. Recoverable Invocation Primitive policy 10 owns it.
Deleted: Action wiring 4. Recoverable Invocation Composes 1 owns it: a record carries only the substrate's stamps, and the pairing datum an intent carries is the adopter's parameter, no stamp.
Action wiring 5: An outcome event MUST carry the chain id AND the entry id.
Deleted: Action wiring 6. Execution Contract Database 2 owns it.
Deleted: Action wiring 7. Action wiring 8 and Execution Contract Constituent failure 1 own it: a Provenance storage-failure is a pre-commit arm, closed through the invocation refuse and answered storage-failure.
Action wiring 8: IF Provenance answers a Provenance refusal, storage-failure OR state-unavailable inside a custody action's commit THEN the custody action MUST close the pre-commit arm through the invocation refuse AND answer that code (Recoverable Invocation commit 2, commit 3).
Action wiring 9: A pre-commit arm MUST NOT write beyond the intent AND the refusal record.
Deleted: Action wiring 10. Execution Contract Database 1 owns it.
Action wiring 11: A closed custody action MUST write the binding AND answer the custody result.
Action wiring 12: A validated origination MUST call the invocation open with the act kind custody.originate, the origination key as the act key, the custodian reference as the actor reference, the credential AND the intent data carrying the artifact reference, the custodian reference, the genesis type AND now as the pairing datum (Recoverable Invocation Action wiring 4).
Action wiring 13: An admitted origination MUST call Provenance's originate with the artifact reference, the custodian reference, the genesis type AND the metadata, inside the origination transaction.
Action wiring 14: A committed origination MUST read the genesis entry at sequence number one through Provenance's read, inside the origination transaction.
Action wiring 15: [Originate Custody] MUST close a committed origination transaction through the invocation close naming custody.originate.originated for originated AND custody.originate.received for received (Recoverable Invocation commit 4).
Action wiring 16: A validated transfer MUST NOT call the invocation open BEFORE resolving the outgoing custodian through Provenance's read.
Action wiring 17: IF Provenance's read answers not-known THEN [Transfer Custody] MUST answer not-known.
Action wiring 18: IF the chain's latest entry carries archived THEN [Transfer Custody] MUST answer archived.
Action wiring 69: IF Provenance's read answers not-known OR state-unavailable OR the chain's latest entry carries archived THEN a validated transfer MUST NOT answer invalid-credential (Execution Contract Refusal 1).
Action wiring 19: A transfer refused ahead of the transfer intent MUST NOT write.
Action wiring 20: A resolved transfer MUST call the invocation open with the act kind custody.transfer, the chain id as the act key, the resolved custodian as the actor reference, the credential AND the intent data carrying the chain id, the resolved custodian as the outgoing custodian, the incoming custodian AND now as the pairing datum.
Action wiring 21: An admitted transfer MUST call Provenance's transfer with the chain id AND the incoming custodian, inside the transfer transaction.
NOTE: open 2026-11-10-g — an incoming custodian equal to the resolved custodian is neither refused nor named permitted.
Deleted: Action wiring 22. Action wiring 63 and Action wiring 65 own it: the transfer transaction re-reads the holder and refuses a holder other than the resolved custodian, so the committed entry's outgoing custodian is the resolved custodian.
Deleted: Action wiring 23. Execution Contract Database 2 owns it.
Deleted: Action wiring 24. Action wiring 65 owns it: a holder changed since the resolution is refused not-current-custodian inside the transfer transaction, so no transfer answers principal-divergence.
Deleted: Action wiring 25. Action wiring 65 owns it: a holder changed since the resolution is refused not-current-custodian inside the transfer transaction, so no transfer answers principal-divergence.
Action wiring 26: [Transfer Custody] MUST close a committed transfer transaction through the invocation close naming custody.transfer.transferred (Recoverable Invocation commit 4).
Action wiring 27: A validated transformation MUST call the invocation open with the act kind custody.transform, the chain id as the act key, the custodian reference as the actor reference, the credential AND the intent data carrying the chain id, the custodian reference, the transformation descriptor AND now as the pairing datum.
Action wiring 28: An admitted transformation MUST call Provenance's transform with the chain id, the custodian reference AND the transformation descriptor.
Action wiring 29: A validated disclosure MUST call the invocation open with the act kind custody.disclose, the chain id as the act key, the custodian reference as the actor reference, the credential AND the intent data carrying the chain id, the custodian reference, the recipient reference AND now as the pairing datum.
Action wiring 30: An admitted disclosure MUST call Provenance's disclose with the chain id, the custodian reference AND the recipient reference.
Action wiring 31: A validated archival MUST call the invocation open with the act kind custody.archive, the chain id as the act key, the custodian reference as the actor reference, the credential AND the intent data carrying the chain id, the custodian reference AND now as the pairing datum.
Action wiring 32: An admitted archival MUST call Provenance's archive with the chain id AND the custodian reference.
Action wiring 33: IF Provenance's read answers not-known THEN [Verify Custody] MUST answer not-known.
Action wiring 34: A found verification MUST replay the chain's entries in sequence order as the continuity check.
Action wiring 35: A found verification MUST resolve EVERY entry's binding through the binding index.
Action wiring 36: IF an entry carries no binding after the rebuild AND a purged later entry EXISTS THEN the entry MUST carry binding-unknown.
Action wiring 37: IF an entry carries no binding after the rebuild AND no purged later entry EXISTS THEN the entry MUST carry binding-gap.
NOTE: open 2026-11-10-e — Action wiring 36 and 37 land binding-gap on a young entry whose close has not landed, the state Cross-record consistency 1 names and Check 1.1 excuses.
Action wiring 38: A found verification MUST read EVERY bound event through the record read.
Action wiring 39: IF the record read answers Purged THEN [Verify Custody] MUST call the verification with the covering range's members the original event payloads carry.
NOTE: open 2026-11-04-d — the call may present an empty payload, which Audit Trail Primitive policy 27 forbids a caller without exemption; Audit Trail never reads it here (Verify Record step 1.2, 1.3 for Purged; step 4.2, 4.3 for partially-purged coverage), and withholding the call would drop step 3's attestation outcome (Action wiring 43).
Action wiring 40: [Verify Custody] MUST NOT check the original event payloads for an event the record read answers Purged for.
Action wiring 56: IF the record read answers partially-purged coverage THEN [Verify Custody] MUST call the verification with the covering range's members the original event payloads carry.
Action wiring 41: IF a member of a live event's whole covering range IS NOT IN the original event payloads THEN the entry MUST carry payload-not-supplied AND the missing sequence numbers as the attestation verification.
Action wiring 42: IF EVERY member of a live event's whole covering range IS IN the original event payloads THEN [Verify Custody] MUST call the verification with the covering range's payloads in ascending sequence order.
NOTE: watch the purged co-member (Action wiring 41, Action wiring 56).
NOTE: open 2026-11-04-f — Action wiring 41's missing sequence numbers and Verdict 2's named entries carry no stated cardinality cap.
Action wiring 43: A found verification MUST carry the verification's outcome AND, where the outcome carries one, the outcome's reason unchanged as the attestation verification.
Action wiring 44: A found verification MUST carry the verification's compensation-window qualifier, where the outcome carries one, beside the attestation verification.
NOTE: watch the side-channel qualifier (Term attestation verification, Action wiring 44).
Action wiring 45: IF the attestation verification EQUALS verified THEN a found verification MUST compare the entry's compared fields with the payload at the bound event's own position as the entry payload match.
Action wiring 46: IF the attestation verification IS NOT IN verified and failed-verification carrying purged THEN the entry payload match MUST carry unanchored.
Action wiring 57: IF the attestation verification EQUALS failed-verification carrying purged THEN the entry payload match MUST carry not-applicable carrying purged.
Action wiring 47: IF the record read answers neither Purged nor not-known THEN a found verification MUST decide the entry's actor match PER the actor match.
Action wiring 48: IF the record read answers neither Purged nor not-known THEN a found verification MUST carry the bound event's recovery flag as the recovery attestation.
Action wiring 49: IF the record read answers Purged THEN the recovery attestation MUST carry unknown carrying purged.
Action wiring 58: IF the record read answers Purged THEN the actor match MUST carry unknown carrying purged.
Action wiring 50: A found verification MUST carry the record read's retention state unchanged.
Action wiring 51: The composition MUST NOT fetch a payload for the verification.
Action wiring 52: [Verify Custody] MUST NOT change a presented payload.
Action wiring 53: [Verify Custody] MUST NOT record an audit event.
Action wiring 54: The read passthrough MUST answer Provenance's read for the chain id AND the query unchanged.
Action wiring 55: The read passthrough MUST NOT record an audit event.
Action wiring 59: IF a read the action makes answers state-unavailable THEN the action MUST answer state-unavailable PER Execution Contract Read 1.
Deleted: Action wiring 60. Recoverable Invocation Invariant 8.3 and Recoverable Invocation Invariant 8.4 own it: a refusal commits no custody entry, and recording-failure(outcome) is an answer whose act may exist.
Action wiring 61: An outcome event MUST carry EVERY compared field of the entry.
Action wiring 62: IF the record read answers not-known THEN the actor match, the recovery attestation AND the attestation verification MUST carry unknown carrying not-known AND the entry payload match MUST carry unanchored.
Action wiring 63: An admitted transfer MUST NOT call Provenance's transfer BEFORE re-reading the chain's latest entry through Provenance's read inside the transfer transaction.
Action wiring 64: IF the re-read finds the chain's latest entry carrying archived THEN the transfer transaction MUST commit no write AND [Transfer Custody] MUST close the pre-commit arm through the invocation refuse AND answer archived.
Action wiring 65: IF the re-read finds a holder that DOES NOT EQUAL the transfer intent's outgoing custodian THEN the transfer transaction MUST commit no write AND [Transfer Custody] MUST close the pre-commit arm through the invocation refuse AND answer not-current-custodian.
Action wiring 66: [Transform Custody], [Disclose Custody] AND [Archive Custody] MUST close a committed Provenance write through the invocation close naming the act kind's one outcome reference (Term custody bindings, Recoverable Invocation commit 4).
Action wiring 67: IF a call of a custody action's commit answers an arm of the unknown partition THEN the custody action MUST call the invocation yield AND answer recording-failure(outcome) (Recoverable Invocation commit 8).
Action wiring 68: IF the invocation open, refuse OR close answers a code of Recoverable Invocation's Action wiring table THEN the custody action MUST answer that code.
```

Term validated custody action: a custody action whose inputs cleared Primitive policy.

Term Provenance refusal: invalid-ref | invalid-genesis-type | not-known | archived | already-archived | not-current-custodian | invalid-descriptor — Provenance's refusals of a write, relayed by name.

Term closed custody action: a custody action whose invocation close landed its outcome event.

Term validated origination: a validated custody action of [Originate Custody].

Term admitted origination: a validated origination whose invocation open landed the originate intent.

Term committed origination: an admitted origination whose Provenance originate answered the chain id.

Term validated transfer: a validated custody action of [Transfer Custody].

Term resolved custodian: the incoming custodian of the chain's latest transferred entry, or the genesis custodian where none — the holder the chain shows.

Term resolved transfer: a validated transfer Action wiring 17 and 18 did not refuse.

Term admitted transfer: a resolved transfer whose invocation open landed the transfer intent.

Term committed transfer: an admitted transfer whose transfer transaction answered the entry id.

Term validated transformation: a validated custody action of [Transform Custody].

Term admitted transformation: a validated transformation whose invocation open landed the transform intent.

Term validated disclosure: a validated custody action of [Disclose Custody].

Term admitted disclosure: a validated disclosure whose invocation open landed the disclose intent.

Term validated archival: a validated custody action of [Archive Custody].

Term admitted archival: a validated archival whose invocation open landed the archive intent.

Term purged later entry: an entry later in the chain, by sequence number, whose bound outcome event the record read answers Purged.

Term pre-horizon entry: an entry for which a purged later entry exists.

Term found verification: a [Verify Custody] call whose chain Provenance's read found.

Term covering range: the sequence range the record read names for an event's covering seal, or the event's own sequence number in the unsealed tail.

Term whole covering range: a covering range the record read does not answer partially-purged coverage for.

Term live event: a bound event the record read answers Retained or unresolved in its compensation window.

Term entry payload match: match | entry-payload-mismatch carrying the field | unanchored | not-applicable carrying purged.

Term compared fields: the custodian reference of an originated, received, transformed, disclosed or archived entry; the outgoing and incoming custodians of a transferred entry; the transformation descriptor of a transformed entry; the recipient reference of a disclosed entry — never the metadata, which no outcome payload carries (Primitive policy 15).

Term attested custodian: a transferred entry's outgoing custodian, or another entry's custodian reference — the acting custodian of the action that appended the entry.

Term actor match: match | match carrying recovery | attribution-mismatch carrying the actor references | unknown carrying purged | unknown carrying not-known — match where the event carries no recovery flag and the event's attesting actor names the entry's attested custodian; match carrying recovery where the event carries the recovery flag, its acting actor reference names the entry's attested custodian, and its attesting actor is the recovery identity or the resolving actor the event names (Recoverable Invocation reconcile, Recoverable Invocation resolve); attribution-mismatch carrying the event's attesting actor, together with its acting actor reference where the event carries the recovery flag, where neither clause holds.

Term recovery attestation: true | false | unknown carrying purged | unknown carrying not-known — whether the bound event carries the recovery flag.

Term read passthrough: Provenance's read, passed through unchanged — the composition's read.

#### Closure table

Every input an action takes, and every answer a call of the seven actions and of the leg can meet — Provenance's originate, transfer, transform, disclose, archive and read, the genesis lookup, Audit Trail's custody enumeration, record read and verification, and Recoverable Invocation's open, close, refuse and yield — with where the call lands it and the rule that owns the landing. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here. The five custody actions are Recoverable Invocation's: the intent commits at the open, ahead of the Provenance write (Execution Contract Constituent failure 1), the commit is the origination transaction, the transfer transaction or the one Provenance write, and the outcome lands at the close, so open, commit and close are three commits and not one transaction (Recoverable Invocation Non-goal 1); an act whose outcome never lands is the sweep's, closed within its closure window (Recoverable Invocation reconcile). [Verify Custody] and the read passthrough write nothing (Action wiring 53, 55), and the binding index stays outside every transaction (Composition state 6). A refusal writes nothing, except that a pre-commit arm of a custody action keeps the authenticated attempt in a refusal record (Recoverable Invocation commit 3).

**Inputs.**

| Action | Input | Lands | Owner |
|---|---|---|---|
| a custody action | a blank or over-cap artifact, custodian or recipient reference | invalid-ref, nothing written | Primitive policy 1, 2, 3, 7, 9 |
| [Transform Custody] | a blank or over-cap transformation descriptor | invalid-descriptor, nothing written | Primitive policy 4, 8, 9 |
| [Originate Custody] | a genesis type other than originated and received | invalid-genesis-type, nothing written | Primitive policy 5, 9 |
| a custody action | a blank credential | invalid-credential, nothing written | Primitive policy 6, 9 |
| a custody action | the credential | consumed by the intent record alone, never inspected | Primitive policy 13, Term credential |
| every action | a caller string | compared byte-exact, never normalized | Primitive policy 11, 12 |
| [Originate Custody] | the metadata | passed to Provenance's originate unchanged, and to no Recoverable Invocation call | Action wiring 13, Primitive policy 15 |
| a custody action | inputs whose outcome would exceed Audit Trail's payload cap | invalid-request at the open, nothing written | Recoverable Invocation Primitive policy 12, 13 |
| [Verify Custody] | the original event payloads | read by sequence number, never changed | Action wiring 41, 42, 52 |

**Provenance: the resolution read**, at [Transfer Custody], ahead of the open (Action wiring 16).

| Answer | Lands | Owner |
|---|---|---|
| the chain's entries, the latest not archived | the resolved custodian, then the open | Action wiring 20, Term resolved custodian |
| the chain's entries, the latest archived | archived, nothing written | Action wiring 18, 19 |
| not-known | not-known, nothing written | Action wiring 17, 19 |
| invalid-query | not met: the read carries no query | Action wiring 16 |
| state-unavailable | passed through unchanged, nothing written | Action wiring 59, Execution Contract Read 1 |
| no answer | no answer to give | Execution Contract Error model 1 |

**Recoverable Invocation: the open, the close, the refuse and the yield**, at the five custody actions.

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the open | an intent event id | the commit | Action wiring 12, 20, 27, 29, 31, Term admitted origination, Term admitted transfer |
| the open | invalid-credential, invalid-request, act-in-flight, section-unavailable, journal-unavailable, recording-failure(intent) | the same code, nothing committed | Action wiring 68, Recoverable Invocation Action wiring table |
| the open | recording-failure(outcome) | recording-failure(outcome), the intent standing open, the commit never issued and the record the sweep's | Action wiring 68, Recoverable Invocation Action wiring table |
| the open | act-landed | never: every kind is repeatable | Recoverable Invocation repeatable 1, Term custody bindings |
| the close | an event id | the binding, and the custody result | Action wiring 11, 15, 26, 66 |
| the close | recording-failure(outcome) | recording-failure(outcome), the act committed and its record the sweep's | Action wiring 68, Recoverable Invocation commit 4 |
| the refuse | an event id | the constituent's own code, the attempt recorded | Action wiring 8, 64, 65 |
| the refuse | already-accounted or recording-failure(refusal, constituent_code) | that code; the sweep records the attempt where the refusal did not land | Action wiring 68, Recoverable Invocation Action wiring table |
| the yield | its return | recording-failure(outcome), the act possibly committed and its record the sweep's | Action wiring 67 |

**Provenance inside a commit.** A state-unavailable from any of these calls is a pre-commit arm (Execution Contract Constituent failure 3) closed through the refuse (Action wiring 8), and a call with no answer, or with an answer Provenance does not declare, is the unknown partition, closed through the yield (Action wiring 67, Term commit partition). The other answers:

| Call | Answer | Lands | Owner |
|---|---|---|---|
| originate, in the origination transaction | a chain id | the genesis read | Action wiring 14, Term committed origination |
| originate | invalid-genesis-type | not met: Primitive policy 5 refuses it first | Primitive policy 9, 10 |
| originate | invalid-ref | for an artifact or custodian reference blank or over its cap, not met: Primitive policy 1, 2 and 7 refuse it first; for a metadata over Provenance's maximum length, invalid-ref, the transaction rolled back, refused | Action wiring 8, Primitive policy 9, 10 |
| originate | storage-failure | storage-failure, the transaction rolled back, refused | Action wiring 8 |
| the genesis read, in the origination transaction | the genesis entry | the close | Action wiring 15 |
| the genesis read | not-known or invalid-query | not met: the chain was minted in the same transaction, and the read carries sequence number one alone | Action wiring 14 |
| the re-read, in the transfer transaction | the latest entry, not archived, its holder the intent's outgoing custodian | Provenance's transfer | Action wiring 21, 63 |
| the re-read | the latest entry archived | archived, the transaction committing no write, refused | Action wiring 64 |
| the re-read | the latest entry held by another custodian | not-current-custodian, the transaction committing no write, refused | Action wiring 65 |
| the re-read | not-known | not met: the resolution read found the chain, and the composition disposes of no chain (Non-goal 10) | Action wiring 17 |
| transfer, in the transfer transaction | an entry id | the close | Action wiring 26, Term committed transfer |
| transfer | not-known, archived or invalid-ref | not met: the re-read in the same transaction found the chain open, and Primitive policy 2 and 7 refuse the reference first | Action wiring 63, 64, Primitive policy 9 |
| transfer | storage-failure | storage-failure, the transaction rolled back, refused | Action wiring 8 |
| transform, disclose or archive | an entry id | the close | Action wiring 66 |
| transform, disclose or archive | not-known or not-current-custodian, archived (transform, disclose) or already-archived (archive) | the same code, refused | Action wiring 8, Term Provenance refusal |
| transform, disclose or archive | invalid-ref or invalid-descriptor | not met: Primitive policy 2, 3, 4, 7 and 8 refuse them first | Primitive policy 9, 10 |
| transform, disclose or archive | storage-failure | storage-failure, refused | Action wiring 8 |

**Provenance and Audit Trail at [Verify Custody] and the read passthrough.**

| Call | Answer | Lands | Owner |
|---|---|---|---|
| Provenance's read, at [Verify Custody] | the chain's entries | the continuity check and the bindings | Action wiring 34, 35 |
| Provenance's read, at [Verify Custody] | not-known | not-known | Action wiring 33 |
| Provenance's read, at [Verify Custody] | invalid-query | not met: the read carries no query | Action wiring 34 |
| the custody enumeration, in the binding rebuild | the events | the rebuilt bindings, a duplicate opening a binding-duplicate finding | Composition state 7 through 10, Term binding rebuild |
| the custody enumeration | invalid-query | a deployment fault, alerted, and state-unavailable at [Verify Custody], nothing written | Composes 10, Action wiring 53 |
| the record read, on a bound event | Retained, unresolved in its compensation window, Purged, or partially-purged coverage | the verification, or none, as Action wiring 39 through 42 and 56 decide | Action wiring 38 through 42, 56 |
| the record read | not-known | binding-gap, the actor match, the recovery attestation and the attestation verification unknown, the entry payload match unanchored | Action wiring 62, Verdict 13 |
| the verification | its outcome and, where it carries one, its reason | the attestation verification, unchanged, with its compensation-window qualifier, where it carries one, riding beside it | Action wiring 43, 44 |
| the read passthrough | Provenance's answer | the same answer, unchanged | Action wiring 54 |

Inside every action, a read that fails answers state-unavailable and writes nothing (Action wiring 59, Execution Contract Read 1 through 3), and a read with no answer leaves the action none to give (Execution Contract Error model 1).

**The composition's own records.** A binding is written after its outcome event lands, outside the action's transaction (Composition state 4, Action wiring 11): a write of one that fails or never answers is a rebuild trigger, not data loss (the section titled Composition state in `execution-contract.md`; Composition state 7), and an outcome the sweep or an operator wrote is bound by the rebuild (Term binding rebuild).

**The leg.** It answers no caller, and decides only on an answered read (Reconciliation 30): a log read, an enumeration or a Provenance read that fails or gives no answer decides nothing, and the entry is examined again at the next run (Reconciliation 2). It opens findings and alerts; it writes no outcome, which is the sweep's under the recovery identity.

### Wiring decision

```
Deleted: Wiring decision 1. Invariant 1.1 and Invariant 4.3 own it: the outcome event of a settled carried entry whose carrying intent stands neither open, escalated, abandoned nor refused, and no second invocation-written one.
Deleted: Wiring decision 2. Execution Contract Database 1 owns it.
Wiring decision 3: A validated origination MUST attest under the genesis custodian.
Wiring decision 4: A validated transfer MUST attest under the outgoing custodian.
Wiring decision 5: The outcome of [Transform Custody], [Disclose Custody] AND [Archive Custody] MUST attest under the current custodian.
Wiring decision 6: The composition MUST NOT attest a transfer under the incoming custodian.
```

<details markdown="block">
<summary>WHY</summary>

*Principle.* A court-admissible or regulator-acceptable chain of custody needs four properties at once: continuity (no gap, hand to hand), verified attribution (each custodian non-repudiably identified), tamper evidence (any rewrite provable), and retention governance (kept for its regulatory lifetime, lawfully destroyable with a defensible record). Provenance supplies continuity; Audit Trail supplies the other three. Without a per-entry link the two record sets are parallel and unjoined — an auditor can verify continuity separately and attribution separately, but cannot prove all four *together for the same entry*.

*Likely objection.* Why not fold attribution, tamper evidence and retention into Provenance, so the chain itself carries all four?

*Mechanism.* Those are exactly the concepts Provenance extracted in its EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) pass to stay freestanding, naming each composing home in its own edge cases. The composition is where they re-converge, and efficiently: Audit Trail already wires all three into one substrate, so one binding — entry to event — carries the whole surface (Invariant 1.1). A step whose event never landed — a lost reply, or a crash between the Provenance write and its close — is closed by Recoverable Invocation's sweep, which writes the owed event from what the chain holds or escalates and never re-runs the write, so the four properties hold for it too, attested as recovered. Absorbing the three into Provenance would end its freestanding status and make every unregulated chain carry the regulated overhead.

*Result.* Provable custody, which neither constituent gives alone: an auditor holding the binding index, the chain and the substrate answers the four questions — who held it, was the transfer unbroken, was the record altered, was it kept long enough.

</details>

### Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Scheduled leg 1 and Recoverable Invocation sweep cadence 2 own it: the sweep runs at every process start, and the reconciliation runs beside it (Reconciliation 2, Reconciliation 31).
Reconciliation 2: The reconciliation MUST run every sweep cadence.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Reconciliation 4: The reconciliation MUST NOT examine a young entry.
Deleted: Reconciliation 5. Execution Contract Database 2 owns it.
Deleted: Reconciliation 6. Execution Contract Database 2 owns it: the reconciliation's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for another holder to hold.
Reconciliation 7: The reconciliation MUST read EVERY Provenance entry that is neither a young entry nor an aged entry against the intents, through Provenance's read of EVERY chain id Capability requirement 33 supplies.
Deleted: Reconciliation 8. Recoverable Invocation reconcile step 1.1, step 1.2 and step 3.1 own it: the sweep runs the act probe for every open intent.
Deleted: Reconciliation 9. Recoverable Invocation commit 2 and Recoverable Invocation reconcile step 3.5 own it: a pre-commit arm closes through the invocation refuse, and an intent whose invocation died before its commit is escalated for an operator to abandon.
Deleted: Reconciliation 10. Recoverable Invocation Invariant 3.3 owns it, through the originate probe and the step probe: the pairing datum, the entry's recording instant, joins an intent to its entry by equality.
Reconciliation 11: IF an entry that is neither a young entry nor an aged entry IS NOT a carried entry THEN the reconciliation MUST open a write-ownership finding for the entry.
Deleted: Reconciliation 12. Recoverable Invocation reconcile step 1.2 and Recoverable Invocation reconcile step 3.12 own it: the sweep writes only for an intent, and only what it read.
Deleted: Reconciliation 13. Recoverable Invocation Invariant 3.5a and Recoverable Invocation reconcile step 3.8 through 3.10 own it: an escalation carries the database candidates, and an outcome never does.
Deleted: Reconciliation 14. Recoverable Invocation reconcile step 3.8 through 3.10 own it.
Deleted: Reconciliation 15. Recoverable Invocation Invariant 3.5a owns it.
Deleted: Reconciliation 16. Term step probe and Recoverable Invocation Invariant 3.3 own it: a transferred entry pairs to its intent by the pairing datum, as every other entry does.
Deleted: Reconciliation 17. Term originate probe and Recoverable Invocation Deviation 4b own it: the genesis lookup is the originate probe's read.
Deleted: Reconciliation 18. Recoverable Invocation Deviation 4c and Recoverable Invocation reconcile step 3.8 own it: with no genesis lookup the originate probe answers undecidable, and the sweep escalates the intent.
Deleted: Reconciliation 19. Action wiring 65 and Reconciliation 11 own it: the transfer transaction refuses a holder changed since the resolution, so no committed transfer's outgoing custodian differs from its intent's, and a transferred entry no intent carries opens a write-ownership finding.
Deleted: Reconciliation 20. Recoverable Invocation reconcile step 1.2 owns it: a transferred entry no intent carries is never closed by the sweep.
Deleted: Reconciliation 21. Recoverable Invocation Invariant 5.1 and Recoverable Invocation reconcile step 3.2a own it: the recovery intent before any recovered outcome.
Deleted: Reconciliation 22. Recoverable Invocation Invariant 5.2 and the service identity own it: the recovery identity is the bindings' service identity.
Deleted: Reconciliation 23. Recoverable Invocation Invariant 5.2, Recoverable Invocation Primitive policy 11a and Recoverable Invocation Term outcome shape own it: the recovered outcome carries the recovery flag, the acting actor reference and the intent event id.
Deleted: Reconciliation 24. Term step probe, Recoverable Invocation act probe 6 and Recoverable Invocation Invariant 5.3 own it: the probe re-derives the outcome's fields from the entry.
Deleted: Reconciliation 25. Recoverable Invocation reconcile step 2.4 through 2.6 own it: the sweep re-reads the invocation's closings under the critical section before it writes.
Deleted: Reconciliation 26. Recoverable Invocation reconcile step 2.5 and step 2.6 own it: an invocation already closed is not written for again, and the binding rebuild binds its outcome (Composition state 7).
Deleted: Reconciliation 27. Recoverable Invocation Sweep never 1 and Recoverable Invocation Invariant 9.2 own it: the sweep writes no adopter state, and the binding rebuild reads a recovered outcome event (Term binding rebuild).
Deleted: Reconciliation 28. Recoverable Invocation reconcile step 3.5, step 3.8 and step 5.1 own it: an intent the sweep cannot close is escalated once and reported at risk.
Deleted: Reconciliation 29. Recoverable Invocation Invariant 2.1 and Recoverable Invocation journal 3 own it: one escalation record per invocation, of the kind's own vocabulary.
Reconciliation 30: The reconciliation MUST decide ONLY on an answered read.
Reconciliation 31: The reconciliation MUST read the sweep's run reading of now, which Recoverable Invocation's run takes once at the sweep's own seam, AND MUST NOT read now at a seam of the reconciliation.
NOTE: watch the sweep's run reading (Reconciliation 31).
Reconciliation 32: The reconciliation MUST alert the finding surface carrying the entry id for EVERY false closing that is neither a young entry nor an aged entry.
Reconciliation 33: The reconciliation MUST read the chain ids Capability requirement 33 supplies once PER run, at the run's start.
Reconciliation 34: The reconciliation MUST NOT examine an aged entry.
```

Term reconciliation: the leg the composition runs outside every invocation, beside Recoverable Invocation's sweep — the reading of the Provenance entries against the intents, whose output, a write-ownership finding or a false-closing alert, an auditor awaits at the sweep cadence and within no window of its own.

Term carried entry: a Provenance entry an intent of the act kind its event type names carries — for a genesis entry, an origination intent whose act key carries the entry's custodian reference and genesis type; for any other entry, an intent whose act key is the entry's chain id; in either case an intent whose pairing datum EQUALS the entry's recording instant.

Term carrying intent: the intent that makes an entry a carried entry — one at most, an equal now never reaching two invocations of one act key (Capability requirement 35).

Term young entry: a Provenance entry whose recording instant stands within the examine window end of the act kind its event type names, measured back from the sweep's now — an entry whose invocation the sweep may still be closing (Recoverable Invocation Term examine window end).

Term aged entry: a Provenance entry for which the sweep's now DOES NOT PRECEDE `(((recording instant + audit horizon) - (2 * clock offset allowance)) - reconciliation run bound)` — an entry whose intent the audit horizon may have destroyed, which the reconciliation would read as no intent.

Term orphan entry: a Provenance entry carrying no outcome event.

Term write-ownership finding: a finding that a Provenance entry is no carried entry — a write against Provenance outside the composition's surface.

Term false closing: a carried entry whose carrying intent an abandonment or a refusal closed — an act that committed, read as one that did not.

Term finding surface: the deployment's compliance surface — the surface Recoverable Invocation's instance writes its register to. A write-ownership finding and this page's alerts are written beside that register and are no part of it (Recoverable Invocation findings 6).

### Verdict

```
Verdict 1: The overall verdict MUST carry custody-proof-complete ONLY IF no class applies AND no entry's recovery attestation EQUALS true.
NOTE: open 2026-11-06-h — a chain whose every bound event is purged completes, and an omitted live member of a partially-purged range is never reported (Action wiring 41, 56).
Verdict 2: IF no class applies AND an entry's recovery attestation EQUALS true THEN the overall verdict MUST carry custody-proof-complete-with-recovered-attestations naming the entries whose recovery attestation EQUALS true.
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
Verdict 13: IF the record read answers not-known for a bound event THEN binding-gap MUST apply.
Verdict 14: IF an attestation verification carries payload-not-supplied THEN payload-not-supplied MUST apply.
Verdict 15: IF an attestation verification carries an unavailable surface THEN availability MUST apply.
Verdict 16: IF an attestation verification carries partially-purged-coverage THEN partially-purged-coverage MUST apply.
Verdict 17: An attestation verification carrying purged MUST NOT apply as a class.
Verdict 18: A compensation-window qualifier MUST NOT apply as a class.
Verdict 19: An unknown MUST NOT apply as a class.
```

Term continuity check: the replay of the chain's entries in sequence order with a running current-custodian cursor, answering continuous or gap-detected carrying the entry, the clause, the expected and the actual — a [Continuity Check].

Term class: a failure class, an incomplete-input class or the standing class — each blocks [Custody Proof Complete].

Term failure class: gap-detected | binding-gap | binding-unknown | binding-duplicate | entry-payload-mismatch | attribution-mismatch | attestation-failed | seal-failed | unsealed.

Term incomplete-input class: payload-not-supplied | availability.

Term standing class: partially-purged-coverage.

Term attestation reason: a failed-verification reason IS NOT IN purged, unsealed, seal-proof-invalid, seal-record-set-mismatch and seal-not-known.
NOTE: open 2026-11-11-a — the term defines the base set by exclusion, and no declared surface of Audit Trail enumerates the reasons its attestation step returns.

Term failed attestation: failed-verification carrying an attestation reason.

Term failed seal: failed-verification carrying seal-proof-invalid, seal-record-set-mismatch or seal-not-known.

Term unavailable surface: unverifiable carrying attestation-registry-unavailable or seal-mechanism-verification-unavailable.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent, and each needs Provenance and the Audit Trail substrate together.

- **Invariant 1 — Attributed custody.**
  ```
  Invariant 1.1: IF a settled entry IS a carried entry AND the state of the entry's carrying intent IS NOT IN open, escalated, abandoned and refused THEN the entry MUST carry an outcome event whose action reference matches the entry's event type.
  NOTE: open 2026-11-11-d — the carrying intent's states are named inside conditions only, and no Term declares the set.
  Invariant 1.2: IF an outcome event carries no recovery flag THEN the event MUST carry an attestation of the acting custodian.
  Deleted: Invariant 1.3. Recoverable Invocation Invariant 5.2, Recoverable Invocation Invariant 5.4 and Recoverable Invocation Term outcome shape own it: an outcome the sweep wrote carries the service identity's attestation and one an operator wrote the operator's, each with the recovery flag and the acting custodian as the acting actor reference.
  Deleted: Invariant 1.4. Recoverable Invocation Invariant 3.1, Recoverable Invocation Check 1.1 and Recoverable Invocation Primitive policy 11a own it: every outcome names its intent by the invocation id and the intent event id, the intent attested under the actor the outcome names.
  ```
  Term settled entry: a Provenance entry whose recording instant plus the examine window end of the act kind its event type names PRECEDES the instant of the auditor's read (Recoverable Invocation Term examine window end).

- **Invariant 2 — Tamper-evident custody chain.**
  ```
  Invariant 2.1: IF an outcome event's sequence number DOES NOT EXCEED sealed through THEN EXACTLY ONE seal MUST cover the event.
  Invariant 2.2: IF a live outcome event is rewritten AND EVERY member of the event's whole covering range IS IN the original event payloads AND the verification DOES NOT answer an unavailable surface THEN [Verify Custody] MUST carry failed-verification as the attestation verification.
  ```
- **Invariant 3 — Retention-governed custody and honest disposal.**
  ```
  Invariant 3.1: IF no invalid-request(step-4) refusal kept a custody event THEN the event MUST carry a retention record from the audit write.
  Invariant 3.2: [Verify Custody] MUST carry failed-verification carrying purged as the attestation verification of a lawfully destroyed event.
  ```
- **Invariant 4 — Binding bijection.**
  ```
  Invariant 4.1: The composition MUST NOT leave an orphan entry unsurfaced.
  Deleted: Invariant 4.2. Recoverable Invocation Invariant 4.2 and Recoverable Invocation Check 3.1 own it: an intent whose invocation died is closed within the closure window, by an outcome on a committed probe (Recoverable Invocation reconcile step 3.2), or escalated.
  Invariant 4.3: Two invocation-written outcome events MUST NOT name one entry id.
  Invariant 4.4: EVERY invocation-written outcome event MUST name an entry the Provenance chain carries.
  Deleted: Invariant 4.5. Recoverable Invocation reconcile step 3.5, Recoverable Invocation reconcile step 3.8 and Reconciliation 11 own it: an intent the sweep cannot close is escalated, and an entry no intent carries opens a write-ownership finding.
  Deleted: Invariant 4.6. Reconciliation 11 owns it: a transferred entry no intent carries opens a write-ownership finding, and the sweep never closes it.
  NOTE: the invocation resolve does not check an operator's outcome against Provenance (Recoverable Invocation resolve 28, Recoverable Invocation resolve 31), so Invariant 4.3 and Invariant 4.4 claim only the invocation-written outcome events, and an operator's closing is detected, not prevented: Composition state 9, Check 5.1 and Check 5.2 find it.
  ```

- **Invariant 5 — Provable custody.**
  ```
  Invariant 5.1: [Verify Custody] MUST answer the continuity, the attestation, the seal AND the retention of EVERY entry of the chain.
  ```
- **Invariant 7 — Authentication precedes commitment.**
  ```
  Deleted: Invariant 7.1. Recoverable Invocation Invariant 1.1 owns it: the commit follows the invocation open, whose intent record verified the acting custodian's credential.
  Invariant 7.2: A validated transfer MUST authenticate the outgoing custodian.
  Deleted: Invariant 6. Composes 5 owns it.
  ```

Continuity, attribution, seal and retention for the same entry give *provable custody*; the bijection makes it total; authentication before commitment makes the attribution exact.

---

## Examples

### Walkthrough — pharmaceutical chain of custody under 21 CFR Part 211

A pharmaceutical manufacturer uses this composition to track batch X-91 from manufacturing through distribution to dispensing. Configuration: `audit_trail_retention_policy = pharma_7yr_predicate_rule` (encoding the applicable predicate-rule retention minimum), `seal_cadence = per-event` (ALCOA — Attributable, Legible, Contemporaneous, Original, Accurate — requires contemporaneous, tamper-evident records; per-event sealing satisfies this at the strongest cadence).

1. **Manufacturer originates the batch.** The quality-release officer calls `originate_custody(artifact_ref="batch-x91", custodian_ref="manuf-lab-7", genesis_type=originated, credential=<qro_credential>)` → `{chain_id="chain-0041", entry_id="e1", event_id="ev_1001"}`. Recoverable Invocation's open records `custody.originate.intended` under `manuf-lab-7`, the officer's credential validating there; Provenance opens the chain inside the origination transaction; the invocation close records `custody.originate.originated` → `ev_1001`; `entry_to_event["e1"] = "ev_1001"`. The genesis is attributed and sealed.

2. **Transfer to regional distributor.** `transfer_custody(chain_id="chain-0041", to_custodian_ref="dist-region-3", credential=<lab7_credential>)` → `{entry_id="e2", event_id="ev_1002"}`. The composition resolves the holder, `manuf-lab-7`, and opens `custody.transfer.intended` under it; inside the transfer transaction it re-reads the holder, finds it unchanged, and Provenance writes the transferred entry (`from_custodian_ref="manuf-lab-7"`, `to_custodian_ref="dist-region-3"`); the invocation close records `custody.transfer.transferred`. The outgoing custodian's credential attests the release. `entry_to_event["e2"] = "ev_1002"`.

3. **Distributor transfers to hospital pharmacy.** `transfer_custody("chain-0041", "pharm-hosp-9", <dist_credential>)` → `{entry_id="e3", event_id="ev_1003"}`. `entry_to_event["e3"] = "ev_1003"`.

4. **Pharmacist transforms (dispenses dose).** `transform_custody("chain-0041", "pharm-hosp-9", "dispensed 10mg dose into dispensing unit D44", <pharm_credential>)` → `{entry_id="e4", event_id="ev_1004"}`. `entry_to_event["e4"] = "ev_1004"`.

5. **Archive at terminal disposition.** `archive_custody("chain-0041", "pharm-hosp-9", <pharm_credential>)` → `{entry_id="e5", event_id="ev_1005"}`. `entry_to_event["e5"] = "ev_1005"`. The Provenance chain is now Archived.

6. **FDA inspection.** The FDA inspector asks: *"Prove unbroken, attributed, tamper-evident, retention-compliant custody of batch X-91 under 21 CFR Part 211."* The system calls `verify_custody("chain-0041", original_event_payloads)` — the payload map retrieved from cold storage, keyed by audit-log `sequence_number` and covering every seal range the chain's events fall in; the two-argument form is the signature. The result:
   - `continuity_check = continuous` (every `from_custodian_ref` matches the prior holder).
   - For each of `e1`–`e5`: `attestation_verification = verified` (each attributed, each seal valid, each in `Retained` retention state).
   - `overall_verdict = custody-proof-complete`.
   The inspector sees a single provable answer to all four questions. Invariant 1 through 5 and Invariant 7 are the structural guarantees behind each field.

### Legal evidence — physical exhibit at trial under FRE 901(b)(9)

A detective collects exhibit-A at a crime scene, handled through forensic lab, evidence room, and courtroom. Each step uses this composition with credential bound to the individual officer's or lab's verified identity via the Audit Trail's Actor Identity. At trial, defense counsel challenges authentication under FRE 901(b)(9).

The prosecution calls `verify_custody(chain_id_of_exhibit_A, original_event_payloads)` — the payload map assembled from the evidence-room records, keyed by audit-log `sequence_number` over the covering ranges `read_record` names. The returned `custody-proof`:
- `continuity_check = continuous` — every transfer's `from_custodian_ref` matches the prior holder; no unattributed handler appears.
- Every entry's `attestation_verification = verified` — each custodian's credential was valid at the time of their action.
- `overall_verdict = custody-proof-complete`.

Defense counsel's claim — that the exhibit passed through an unrecorded, unverified handler — has no structural basis. Invariant 1 (attributed custody) and Provenance Invariant 4 (custody continuity) are the structural rebuttal. The exhibit is authenticated under FRE 901(b)(9)'s process-or-system standard.

### Rejection path — transfer by non-current custodian

A prior custodian, `"manuf-lab-7"`, attempts to record a transformation after having transferred to `"dist-region-3"`: `transform_custody("chain-0041", "manuf-lab-7", "added label update", <lab7_credential>)` → `rejected(not-current-custodian)`. The action's invocation open writes the intent record `custody.transform.intended` first — `lab7_credential` validates, so the attempt is authenticated and durable — and Provenance's not-current-custodian guard then catches the call, a pre-commit arm: the invocation refuse records `custody.transform.refused`, no Provenance entry is written, no **outcome** event is recorded, no `entry_to_event` binding is created, and the binding bijection (Invariant 4) is preserved, because it is over entries and outcome events and neither the intent nor its refusal record is one. The chain's integrity is unchanged. **The intent and its refusal record stand, and that is the point:** a former custodian attempting to alter a chain they no longer hold is precisely what a chain-of-custody trail should retain, and before the intent record existed the attempt left no trace anywhere. The refusal record closes the attempt on the record, so no sweep or auditor has to adjudicate it against the chain.

### Rejection path — custody action on an Archived chain

After the pharmaceutical chain is Archived (example step 5), a downstream system attempts another transfer: `transfer_custody("chain-0041", "disposal-unit-1", <credential>)` → `rejected(archived)`. Derived at the read-only resolution — which reads the terminal archived entry from chain state — and confirmed by Provenance's own guard had the call proceeded. **No state is written anywhere, and here that includes no intent record** — because the archive preceded the call: [Transfer Custody] alone resolves existence and archival state before its intent record, so its not-known and archived arms are refused earlier than the other three chain-addressed actions' constituent guards, which fire after theirs.

### Failure path — custody step whose outcome is lost, recovered

The evidence room releases a controlled-substance tote to the hospital pharmacy: `transfer_custody("chain-0107", "pharm-hosp-9", credential=<evid_room>)`. The resolution read shows the evidence room, `evid-room-2`, as the holder; the invocation open lands `custody.transfer.intended` under `evid-room-2` carrying the invocation's now as its pairing datum — the evidence-room custodian's credential validates, so what follows is an authenticated attempt on the record. Inside the transfer transaction the holder is re-read and unchanged, and `Provenance.transfer` writes the entry (`entry_id = e5`), its recording instant the same injected now. The invocation close's write of `custody.transfer.transferred` answers recording-failure carrying step-3 — the Event Log append answered nothing, its reply lost (Recoverable Invocation Primitive policy 32a) — and the read-back by invocation id finds nothing, so the call returns `recording-failure(outcome)`, telling the evidence room the act may exist, its record is the sweep's, and the action must not be re-run. Recovery is Recoverable Invocation's: once the intent ages past its examine edge, the sweep runs the step probe — Provenance's read of `chain-0107` for a transferred entry at the intent's pairing datum, from `evid-room-2` to `pharm-hosp-9` — finds `e5`, writes `custody.transfer.recovery_intended`, and lands `custody.transfer.transferred` under `recovery_identity` with `recovery = true` and `evid-room-2` as the acting actor reference (had the lost append landed after all, the sweep's re-read would have found it and written nothing). The binding rebuild binds `e5` to the recovered event. A later [Verify Custody] reports `e5` with recovery attestation true, actor match match carrying recovery, and an [Overall Verdict] of `custody-proof-complete-with-recovered-attestations([e5])` — structurally sound, surfaced for the auditor's judgment. Had the credential been bad, this path would never have been reached: it is refused at the intent with nothing committed.

### DEA controlled substance — 21 CFR Part 1304 inventory custody

A DEA-licensed pharmacy tracks each controlled substance dispensing as a separate artifact with its own chain under this composition. Each [Originate Custody] (pharmacy receives from supplier) → [Transfer Custody] (to dispensing cabinet) → [Transform Custody] (patient dispensing recorded) → [Archive Custody] sequence produces a complete attributed, sealed, retention-governed custody record per substance unit. A DEA compliance inspection calls [Verify Custody] for each in-scope chain and verifies the returned `custody-proof-complete` verdict. Every change of custody is attribution-stamped; every record is sealed; every record is retained per the applicable predicate rule.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts:

**Regulator audit — pharma: prove unbroken, attributed, tamper-evident, retention-honored custody of batch X-91 under 21 CFR Part 211.**

An FDA inspector runs `verify_custody("chain-0041", original_event_payloads)`. The returned `custody-proof`:
- `continuity_check = continuous`: by Provenance Invariant 4, every `from_custodian_ref` equals the prior to_custodian_ref (or genesis custodian_ref). The chain cannot have a gap because Provenance reads `from_custodian_ref` from chain state — no forged predecessor is possible.
- Per-entry `attestation_verification = verified`: by Invariant 1 (attributed custody), each entry has an outcome Audit Trail event whose Actor Identity attestation binds the custodian_ref to a credential — and, by Invariant 7, an intent event preceding the entry's commit under that same custodian, which is the stronger claim under Part 11's (FDA's electronic-records rule, 21 CFR Part 11) *Attributable* limb: the identity was checked before the custody step, not merely recorded after it. The Tamper Evidence seal (via Audit Trail Invariant 3) confirms no entry was rewritten.
- Per-entry `retention_state = Retained`: by Invariant 3, every entry is under active retention per the configured predicate-rule policy; none has elapsed.
- `overall_verdict = custody-proof-complete`.
The inspector's four questions — unbroken custody, verified attribution, tamper-evidence, retention honored — have provable answers. Invariant 1 through 5 and Invariant 7 are the structural basis for each answer.

**Disputed transaction — legal evidence: defense claims tampering or an unattributed handler under FRE 901(b)(9).**

Defense counsel claims: (a) custody was broken (an unrecorded handler existed), or (b) a custodian was unverified (their identity was not attributable), or (c) the chain was tampered with (an entry was altered after the fact). The prosecution's [Verify Custody] result addresses each:
- Claim (a): `continuity_check = continuous`, resting on Provenance Invariant 4. If there were a gap, a transfer would have been recorded with a `from_custodian_ref` that did not match the prior holder — structurally impossible because Provenance reads `from_custodian_ref` from chain state.
- Claim (b): per-entry `attestation_verification = verified`, resting on Invariant 1 and Audit Trail Invariant 1. Each custodian's credential was verified by Actor Identity **before their custody step committed** — the intent record makes it provable, and the outcome record's `intent_event_id` names it — so the claim is exact rather than approximate; the attestation is in the record.
- Claim (c): per-entry `attestation_verification` seal check (Invariant 2, Audit Trail Invariant 3). Any rewrite of an audit event whose covering range the auditor presents produces a `failed-verification` result, `failed-verification(seal-proof-invalid)` where a seal covers the event and `failed-verification(unsealed)` in the unsealed tail (Capability requirement 40). A rewrite of the Provenance chain itself is caught by the per-entry field-match clause (`entry_payload_match`): the sealed audit payload's copies are the anchored values, so a rewritten transformation_descriptor or a consistently rewritten from/to pair reports entry-payload-mismatch, while a removed binding reports binding-gap. Direct cryptographic sealing of the chain records themselves remains the composing Tamper-Evidence-on-Provenance concept the constituent's own edge case names.

**Breach or incident investigation: reconstruct custody during an anomaly window and bound the time of tampering via the Audit Trail seal cadence.**

An incident responder suspects a custody record was tampered with between two dates. The responder calls `verify_custody(chain_id, original_event_payloads)` with payloads from the suspect window. For each entry in the window:
- `attestation_verification = verified` for entries whose covering seal predates the anomaly: the seal is intact.
- `attestation_verification = failed-verification(seal-proof-invalid)` for entries whose seal was tampered with: the first such entry, and its seal's `sealed_at` and `anchored_at` (from the Tamper Evidence atom via Audit Trail), bound the window. The most recent seal that returns verified end-to-end and the first that returns `failed-verification(seal-proof-invalid)` define the forensic window — a bound that holds when the deployment **chains its seals** (each seal covering its predecessor's proof, a property of the substrate's seal mechanism, not of its cadence); without seal chaining the tampering bound is per-seal, not global. The `seal_cadence` governs the window's resolution.
- `attestation_verification = failed-verification(unsealed)` for entries in the unsealed tail: these are covered by Event Log per-event immutability but not yet seal-verified; a tighter `seal_cadence` would have narrowed this window.
Where seals carry `anchored_at` from a TSA (Time-Stamp Authority — a trusted third party that signs proofs of when data existed) outside the adversary's reach, the upper bound on tampering time is independently established. The forensic picture is provable.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when the checks below are provable to an external auditor given the binding index, the Provenance chain records and the Audit Trail substrate's records.

### Conformance checks

```
Check 1.1: An auditor MUST find a binding for EVERY carried entry of the chain that is no pre-horizon entry AND that is a settled entry whose carrying intent stands neither open, escalated, abandoned nor refused, resolving a missing live binding through the binding rebuild (Invariant 1.1).
Check 1.2: An auditor MUST find a passing verification for EVERY bound event whose covering range the auditor presents (Invariant 1.1).
NOTE: open 2026-11-06-e — the check cites Invariant 1.1 but tests the attestation, Term passing verification admits unsealed and partially-purged-coverage, and "presents the covering range" does not say whether a partial presentation is one.
Check 1.3: IF a bound event carries no recovery flag THEN an auditor MUST find the event's attesting actor matching the entry's attested custodian (Invariant 1.2).
Deleted: Check 1.4. Recoverable Invocation Check 2.5 owns it: an outcome carrying the recovery flag is the sweep's or an operator's shape.
Deleted: Check 1.5. Recoverable Invocation service identity 3 and Recoverable Invocation Check 2.5 own it.
Check 2.1: An auditor MUST find EVERY outcome event the sealed-through position covers carrying EXACTLY ONE verifying seal (Invariant 2.1).
Deleted: Check 2.2. Verdict 12 owns it.
Check 3.1: An auditor MUST replay the chain's entries AND find the continuity check continuous (Invariant 5.1).
Check 4.1: IF no invalid-request(step-4) refusal kept a custody event THEN an auditor MUST find the custody event's retention state IS IN Retained and Purged through the record read (Invariant 3.1).
NOTE: open 2026-11-06-f — the check names Retained and Purged, while Term live event adds unresolved in its compensation window.
Check 4.2: An auditor MUST find EVERY Purged outcome event carrying a Purged retention record whose purge instant DOES NOT PRECEDE the retention deadline (Invariant 3.2).
Check 5.1: An auditor MUST enumerate the chain's outcome events through the custody enumeration AND find no two outcome events carrying one entry id (Invariant 4.3).
Check 5.2: An auditor MUST find EVERY outcome event naming an entry the Provenance chain carries (Invariant 4.4).
NOTE: open 2026-11-11-c — Check 5.1 and Check 5.2 test every outcome event while Invariant 4.3 and Invariant 4.4 claim only the invocation-written ones.
Check 5.3: An auditor MUST find EVERY live binding's outcome event carrying the binding's entry id AND an action reference matching the bound entry's event type (Composition state 3, Invariant 1.1).
NOTE: open 2026-11-10-f — [Verify Custody] never checks this property, and the compared fields exclude the metadata (Primitive policy 15), so the anchor the Summary names stops short of it.
NOTE: watch the check over a derived index (Check 1.1, Check 5.3).
Deleted: Check 5.4. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Check 5.5. Reconciliation 11 owns it.
Deleted: Check 5.6. Recoverable Invocation Check 4.1 owns it.
Deleted: Check 5.7. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 5.8. Recoverable Invocation Check 4.1 owns it.
Check 5.9: An auditor MUST resolve EVERY orphan entry that is neither a young entry nor an aged entry to EXACTLY ONE OF a carried entry whose carrying intent stands open, a carried entry whose carrying intent stands escalated, a false closing, a write-ownership finding, a conformance failure (Invariant 4.1, Reconciliation 11, Reconciliation 32).
Deleted: Check 6.1. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 6.2. Reconciliation 9 owns it.
Deleted: Check 6.3. Check 6.1 owns it.
Check 7.1: An auditor MUST clear Provenance's Generation acceptance over the Provenance instance (Composes 5).
Check 7.2: An auditor MUST clear Audit Trail's Generation acceptance over the Audit Trail instance (Composes 5).
Check 7.3: An auditor MUST clear Recoverable Invocation's Generation acceptance over the Recoverable Invocation instance (Composes 5).
```

NOTE: EVERY check names the rule the check tests.

Term passing verification: verified | failed-verification carrying purged | failed-verification carrying unsealed | unverifiable carrying partially-purged-coverage — the outcome alone, a compensation-window qualifier riding beside it changing none of the four (Verdict 18).

### External checks

```
External check 1: An auditor needing a custodian's authority confirmed MUST read the deployment's Permissions records (Non-goal 5).
External check 2: An auditor needing an artifact reference's meaning confirmed MUST read the host's artifact registry (Non-goal 6).
External check 3: An auditor needing a jurisdiction's substantive standard confirmed MUST read the evaluating authority's own determination (Non-goal 7).
Deleted: External check 4. Execution Contract Database 2 owns it.
Deleted: External check 5. Execution Contract Database 3 owns it.
External check 6: An auditor needing the obligation of Capability requirement 34 and Capability requirement 35 confirmed MUST clear the obligation from external evidence (Recoverable Invocation External check 12).
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
Non-goal 12: The composition MUST NOT describe the three commits of a custody action as atomic (Recoverable Invocation Non-goal 1).
Non-goal 13: The composition MUST NOT own a re-entry arm beyond Provenance's own refusal (Recoverable Invocation Non-goal 4).
```

NOTE: the owners — a chain per sub-sample, each opened with a received genesis (Non-goal 1); a composing pattern (Non-goal 2); Erasure Coordination *(forthcoming)* (Non-goal 4); [Permissions](../atoms/permissions.md) (Non-goal 5, External check 1); the evaluating authority (Non-goal 7, External check 3); a Failed-Attempt Log *(forthcoming)* (Non-goal 8); an access-logging wrapper (Non-goal 9); a Retention Window or Defensible Retention instance applied to the chain directly (Non-goal 10, Retention asymmetry 1); [Selective Disclosure](../atoms/selective-disclosure.md) (Non-goal 11).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the Event Log sequence AND the Provenance sequence as the order of the composition's records.
NOTE: open 2026-11-06-c — the two sequences have no cross comparison, so the binding rebuild's order across them is the build's.
Clock semantics 2: The composition MUST NOT claim a Provenance entry's recording instant AND the entry's event's recording instant equal.
Deleted: Clock semantics 3. Recoverable Invocation Allowance 4 and Recoverable Invocation Allowance 6 own it.
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

### Cross-record consistency

```
Cross-record consistency 1: IF a custody action's commit commits AND the invocation's close does not land THEN the entry MUST carry an open intent, closed by the sweep within the closure window.
```

This is Recoverable Invocation's Cross-record consistency for the five act kinds, which the sweep closes: the entry is a carried entry, its carrying intent open until the sweep's committed probe writes the outcome, and the chain is honest throughout, since a later custody action reads the holder from the chain and not from the record.

### Pre-genesis custody

```
Pre-genesis custody 1: The composition MUST NOT claim custody ahead of a chain's genesis entry.
```

### Rename

```
Rename 1: The composition MUST NOT change a recorded custodian reference for a rename.
```

---

## Composition notes

**Recoverable Invocation.** The five custody actions follow [Recoverable Invocation](./recoverable-invocation.md) around their Provenance writes (Composes 12 through 16): an intent before the commit, the one outcome as the close, a refusal record where Provenance or the transfer transaction refuses, the act's critical section over them, and a sweep and an operator's invocation resolve for what an invocation left open. The page binds the five act kinds once (Term custody bindings) and restates none of the protocol. [Verify Custody] and the read passthrough are not bound (Composes 15): each writes nothing, so nothing outlives the invocation.

**Recoverable Invocation's commit is one call.** Recoverable Invocation's bound commit is one constituent call whose arms the constituent partitions; the origination's is two calls in one database transaction and the transfer's a read, a comparison and a write in one (Term origination transaction, Term transfer transaction), whose partition belongs to the transaction. Recoverable Invocation's closed list of deviations has no entry for it, and the page treats the transaction as the commit and records the mismatch as an open line (Recoverable Invocation Deviation 2), as External Onboarding and Propagate Consent Revocation Downstream do. Two more readings are carried to Recoverable Invocation's next revision as evidence, not as findings against this page: its Term pairing datum reads a seam-injected now as passed into the commit, while Provenance's writes take no instant and the host injects it at Provenance's seam (Capability requirement 34); and its own example names a genesis non-repeatable, which a key Provenance never refuses twice cannot be (Provenance Identity 10, Term origination key).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the five custody actions it wraps ([Originate Custody], [Transfer Custody], [Transform Custody], [Disclose Custody], [Archive Custody]) and the emergent verification ([Verify Custody]); the structure that verification answers ([Custody Proof]) with its [Continuity Check] and [Overall Verdict]; and the verdict's three values — [Custody Proof Complete], `custody-proof-complete-with-recovered-attestations` and [Custody Proof Incomplete]. The constituents' refusals are relayed by name. Attributed custody, the binding bijection and authentication before commitment are structural properties, not data. The deployment settings keep their wire spellings in configuration — `audit_trail_retention_policy`, `seal_cadence`, `custody_completion_bound`, `recovery_identity`, `genesis_lookup`, and the Recoverable Invocation instance's own settings under the names that page gives them — and the binding index its own in an implementation, `entry_to_event`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the reconciliation; Recoverable Invocation's sweep; an operator; a deployment; a regulated deployment; an auditor; a caller; a custodian; an invocation; a custody action; a validated custody action; a closed custody action; a validated origination; an admitted origination; a committed origination; a validated transfer; a resolved transfer; an admitted transfer; a committed transfer; a validated transformation; an admitted transformation; a validated disclosure; an admitted disclosure; a validated archival; an admitted archival.

Term records: the intents, outcome events and refusal records Recoverable Invocation writes for the five custody actions through the audit write — each an Event Log event carrying one action reference below, with the recovery intents, abandonments and escalations Recoverable Invocation derives from the five kinds — the Provenance entries the custody actions write, and the binding index's bindings.

Term record verbs: account, adjudicate, alert, answer, apply, assess, attest, authenticate, bind, call, carry, change, check, claim, classify, clear, close, commit, compare, compose, cover, decide, describe, disclose, dispose, duplicate, enumerate, escalate, examine, expose, fetch, find, follow, gate, hold, inherit, inject, inspect, key, land, leave, match, name, normalize, open, override, own, pair, pass, proceed, provision, re-derive, re-read, reach, read, rebuild, record, refuse, remove, replay, report, resolve, retry, run, select, serve, set, start, store, supply, suspend, track, validate, write.

Term value sets: action reference = custody.originate.intended | custody.originate.originated | custody.originate.received | custody.originate.refused | custody.transfer.intended | custody.transfer.transferred | custody.transfer.refused | custody.transform.intended | custody.transform.transformed | custody.transform.refused | custody.disclose.intended | custody.disclose.disclosed | custody.disclose.refused | custody.archive.intended | custody.archive.archived | custody.archive.refused, with the references Recoverable Invocation derives under each kind. finding = binding-duplicate | write-ownership. The rest are declared where the section that owns each declares it: act kind, genesis type, position, entry payload match, actor match, recovery attestation, class, failure class, incomplete-input class, standing class, Provenance refusal.

Term bounds: custody completion bound (custody_completion_bound), reconciliation run bound (Recoverable Invocation's run bound), clock offset allowance (Recoverable Invocation's clock allowance), intent candidates cap (Recoverable Invocation's intent candidates cap), input caps, commit round trip, probe round trip, settling period, audit horizon (audit_trail_retention_policy).

Term cadences: Recoverable Invocation's sweep cadence, seal cadence (seal_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive atoms, custody enumeration, record read, audit write, verification, custody action, act kind, custody bindings, origination key, origination transaction, transfer transaction, commit partition, originate probe, step probe, entry id, chain id, binding index, binding, outcome event, live binding, purged binding, binding rebuild, audit retention policy, audit horizon, seal cadence, custody completion bound, required setting, reconciliation run bound, clock offset allowance, invocation id, commit round trip, probe round trip, settling period, now, recovery identity, genesis lookup, intent candidates cap, input caps, artifact reference, custodian reference, recipient reference, transformation descriptor, genesis type, metadata, credential, caller string, acting custodian, intent, position, recovery flag, custody result, original event payloads, entry sequence, custody proof, validated custody action, Provenance refusal, closed custody action, validated origination, admitted origination, committed origination, validated transfer, resolved custodian, resolved transfer, admitted transfer, committed transfer, validated transformation, admitted transformation, validated disclosure, admitted disclosure, validated archival, admitted archival, purged later entry, pre-horizon entry, found verification, covering range, whole covering range, live event, entry payload match, compared fields, attested custodian, actor match, recovery attestation, read passthrough, reconciliation, orphan entry, carried entry, carrying intent, young entry, aged entry, write-ownership finding, false closing, finding surface, continuity check, class, failure class, incomplete-input class, standing class, failed attestation, failed seal, unavailable surface, settled entry, passing verification.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. Execution Contract Logic confinement 11 — the clock reading at the call. Execution Contract Read 1 — a failed read answers state-unavailable. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. originate, transfer, transform, disclose, archive, read, entry, event type, outgoing custodian, incoming custodian, genesis custodian, sequence number, Archived, Open, invalid-ref, invalid-genesis-type, invalid-descriptor, not-known, archived, already-archived, not-current-custodian, storage-failure, invalid-query: Provenance. record_action, read_record, verify_record, payload cap, sealed through, unsealed tail, unsealed tail mode, lenient, step-2, step-3, step-4, invalid-credential, invalid-request, recording-failure, verified, failed-verification, unverifiable, purged, partially-purged coverage, compensation-window, Retained, Purged, Erasure Tombstone: Audit Trail. append, recording instant: Event Log. open, close, refuse, yield, resolve, sweep, act key, pairing datum, act probe, commit, repeatable, journal, service identity, outcome envelope, invocation completion bound, closure window, sweep cadence, run bound, clock allowance, examine window end, act-in-flight, section-unavailable, journal-unavailable, already-accounted, act-landed, recovery, acting actor reference, resolving actor, act section, compliance surface: Recoverable Invocation. Lease: reached through Recoverable Invocation.

Term composing patterns: [Defensible Retention](./defensible-retention.md); [Selective Disclosure](../atoms/selective-disclosure.md); [Permissions](../atoms/permissions.md); [Multi-Party Approval](./multi-party-approval.md).

#### Originate Custody

The composition action that opens a new Provenance custody chain for an artifact under a genesis custodian, binding the genesis entry to an attributed Audit Trail event (`custody.originate.originated`, or `custody.originate.received` for a received genesis). Returns `{chain_id, entry_id, event_id}`; the genesis custodian's credential attests the artifact entered custody under their hand.

Kind: Operation

#### Transfer Custody

The composition action that records a hand-to-hand transfer to a new custodian. The **outgoing** custodian attests the release — `from_custodian_ref` is read from Provenance's chain state (unforgeable, Provenance Invariant 4) and bound as the actor on the `custody.transfer.intended` record and its `custody.transfer.transferred` outcome; the incoming custodian attests their own later actions.

Kind: Operation

#### Transform Custody

The composition action recording a transformation of the artifact by the *current* custodian (Provenance enforces holder-only), bound to an attributed `custody.transform.transformed` event.

Kind: Operation

#### Disclose Custody

The composition action recording a disclosure of the artifact by the current custodian to a named recipient — custody is *not* transferred — bound to an attributed `custody.disclose.disclosed` event.

Kind: Operation

#### Archive Custody

The composition action recording the terminal disposition by the current custodian and transitioning the chain to Archived — no further entries are accepted — bound to an attributed `custody.archive.archived` event.

Kind: Operation

#### Verify Custody

The composition's emergent verification: construct the provable [Custody Proof] for a chain by replaying Provenance continuity ([Continuity Check]) and, for each entry, verifying its bound Audit Trail event's attestation, seal, and retention. Neither constituent can answer it alone; the caller presents the original event payloads (Audit Trail's verification asymmetry).

Kind: Operation

#### Custody Proof

The structured artifact [Verify Custody] returns: the chain's state, its [Continuity Check] result, an ordered per-entry sequence of attestation / seal / retention verifications, and a summary [Overall Verdict]. What makes unbroken + attributed + tamper-evident + retention-governed custody provable, which neither Provenance nor Audit Trail provides alone.

Kind: Type
Role: provable custody

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

The [Overall Verdict] value when the chain's continuity is unbroken, every entry has its audit-event binding, and every supplied attestation verifies (or is a lawful `failed-verification(purged)`) — the full custody is provable.

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

- **DEA 21 CFR Part 1304 (Controlled Substance Inventory Records)** — requires complete, accurate records of every change of custody of a controlled substance. Invariant 1 (attributed custody) and Invariant 5 (provable custody) are the structural implementation of this requirement at every transfer step.

- **Federal Rules of Evidence 901(b)(9) (Authenticating or Identifying Evidence — Process or System)** — the US evidentiary rule for authenticating physical or electronic evidence via chain-of-custody records. The composition's [Verify Custody] result — `continuity_check = continuous` plus per-entry `attestation_verification = verified` — is the structural form of the unbroken, attributed chain courts require for authentication. Provenance Invariant 4 (custody continuity) and Invariant 1 (attributed custody) are the rebuttal to authentication challenges.

- **ISO 23081 (Information and documentation — Managing metadata for records)** — the ISO (International Organization for Standardization) standard on records-management metadata. The composition's custody entries map directly to the origin, transfer, transformation, and disclosure metadata elements ISO 23081 specifies; the Audit Trail attribution and retention satisfy ISO 23081's authenticity and retention obligations.

- **W3C (the World Wide Web Consortium) PROV (Provenance Data Model — W3C's RDF (Resource Description Framework)-based standard for representing provenance as a directed acyclic graph)** — this composition implements the linear single-entity spine of a W3C PROV graph: the `wasGeneratedBy`, `used`, and `wasAttributedTo` relationships along a single entity's chain. The deliberate non-goal of `wasDerivedFrom` (DAG derivation) and artifact splitting are explicitly out of scope relative to the full PROV model.

- **SEC Rule 17a-4 (Records to be preserved by certain exchange members, brokers, and dealers)** — requires broker-dealer records (including custody records for financial instruments) to be preserved in a non-rewriteable, non-erasable format. The Audit Trail substrate's Tamper Evidence (Invariant 2) satisfies the integrity requirement; the configured `audit_trail_retention_policy` satisfies the lifetime requirement.

- **GDPR (EU General Data Protection Regulation) Article 17** — the right to erasure. An erasure request colliding with an FDA, DEA or court retention obligation over the custody events is a composed Erasure Coordination pattern's decision, not this composition's (Non-goal 4).

this composition inherits the broader standards compliance of its constituents:

- Through **Audit Trail** (and its transitive atoms): SOX (Sarbanes-Oxley Act) section 802 record retention, HIPAA (Health Insurance Portability and Accountability Act) section 164.312(b) audit controls, PCI DSS (Payment Card Industry Data Security Standard) Requirement 10, 21 CFR Part 11 electronic records, ISO/IEC (International Electrotechnical Commission) 27001 clause A.12.4 logging and monitoring, GDPR Articles 30 and 32, and the full Audit Trail standards inheritance. Deployments composing this composition for pharmaceutical or legal-evidence purposes receive these as the substrate's contribution; they are framed as inherited, not as this composition's own primary standards anchors.

- Through **Provenance**: ISO 23081, W3C PROV, FDA 21 CFR Part 211, DEA 21 CFR Part 1304, FRE 901(b)(9), and SEC Rule 17a-4 at the structural custody-chain layer. This composition lifts these to the full attributed+sealed+retention-governed form those standards actually require but that Provenance alone cannot satisfy.

---

## Status

`grounded on Final Critique 23 — 2026-11-11 at 42f1cff` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 23 — 2026-11-11 at 42f1cff
formal: verified — chain-of-custody.tla + 11 twins + 7 reachability probes, re-derived 2026-11-10 over the split arc (each custody action an open, a commit and a close; [Transfer Custody]'s resolution read ahead of the open and its re-read inside the transfer transaction), against Recoverable Invocation's contracts (the sweep's closing by this page's originate and step probes, the escalation, an operator's resolve unchecked against Provenance), with a transfer written outside every invocation, the write-ownership leg and the binding rebuild's duplicate finding; one model under TLC, 478,490 states (one chain, two custodians, three invocations, one outside write, the genesis lookup chosen at the start); Invariant 1.2, 4.1, 4.3, 4.4, 7.2, Wiring decision 4, Action wiring 12 through 31 (the open before the commit), Composition state 9, the probes' pairing datum (Capability requirement 34, 35), the originate probe without a lookup (Term originate probe), the write-ownership finding (Reconciliation 11) and the false-closing alert (Reconciliation 32), each broken by a twin alone; the reconciliation's twins and probes retired to Recoverable Invocation (Invariant 1.3, 1.4, 4.2, 4.5 and 7.1 inherited: Invariant 1.3 through Recoverable Invocation Invariant 5.1, 5.2, which recoverable-invocation.tla checks from v8; Reconciliation 4's aged edge and Reconciliation 14, 15's cap move onto Recoverable Invocation Invariant 7.2 and 3.5a, which its model does not check — owed there, not paid in this unit, as Propagate Consent Revocation Downstream's unit paid none of its equivalents, and recorded in its coverage); not modeled: Recoverable Invocation's mechanism and the clock (the young, aged and settled entry, the closure window, the sweep cadence), disclosure and archival (the transformation stands for the three custodian-guarded steps) and the archived refusals, Provenance's other pre-commit refusals, [Verify Custody] and the binding index's content, a second chain; chain-of-custody.als + 10 twins (the static data model, 2026-11-11: Invariant 1.1, 1.2, 4.1, 4.3, 4.4 and 7.2 checked on every state the admitted writes leave, 1.1 and 4.1 under two premises the page relies on and does not state — an operator's closing names the entry its intent carries, and a write outside the composition's surface never takes the pairing datum of an intent of its act key — and Invariant 3.2 and 5.1 on what [Verify Custody] lands over one state, Invariant 1.2, 4.3, 4.4 and 7.2 a cross-check with the TLA+ model; nothing testable in Alloy for Invariant 2.1 and 3.1, Audit Trail's own (audit-trail.als), and 2.2, which compares two readings); coverage 2026-11-10, 2026-11-11: owed rows: none new, 2026-11-10
last gate: 2026-11-11 — Final Critique 23, a delta round, frozen at 42f1cff — foundational count 0 after the blind second triage, clean, no sample (Linus's one report filed two foundational items, both refuted on the text: Term carried entry's act key carries the custodian reference and genesis type because Term origination key, which delta.md did not hold, is those two and the artifact reference, and Action wiring 12 passes that key as the act key; the transfer refuses line's order (open line 2026-11-10-h) leaves no call with invalid-credential and the read's refusal both applying, since Execution Contract Refusal 1 applies a refusal only where a rule obliges it on the call; refining cured: Action wiring 69 names the ban on invalid-credential on the read's ground, the form Refusal 1 gives (open line 2026-11-10-h closed), Capability requirement 7 deleted to Execution Contract Logic confinement 15, the Originate Custody metadata row's "no record" reads "no Recoverable Invocation call", Reconciliation 33's genitive; new open line 2026-11-11-e; open lines 2026-11-06-h, 2026-11-10-c, -e, -g and 2026-11-11-d re-found); 2026-11-11 — Final Critique 22, a full round, frozen at f60cdf2 — foundational count 7 (Reconciliation 7, 11 and 32 acted on every entry Reconciliation 4 admits while Reconciliation 34 forbade an aged entry, so one build read an aged entry against intents the horizon may have destroyed and opened a write-ownership finding against a legitimate write; Reconciliation 31's run reading of now had no owner; two originations of one custodian and genesis type could share a now, so one genesis entry matched two intents; Invariant 1.1 and Check 1.1 demanded an outcome of a settled entry whose carrying intent stands open, which Check 5.9 resolves; Invariant 1.1's action reference was tested by no check; Composes 10's invalid-query had no answer at [Verify Custody]; Term actor match's mismatch carried one of two references: cured), not clean, no sample (GRID claimed seven foundational and two stand (Composes 10, Term actor match); the other five (the custody enumeration's provider, the young entry's binding-gap, an omitted live member of a partially-purged range, the transfer refuses line's order, Check 4.1's retention states) are placed refining and stay on open lines, each finder's cure failing on the text; EOS's three and Linus's two stand; refining cured: the closure row for an over-limit metadata, Term act kind's outcome references, Primitive policy 11's caller strings; new open lines 2026-11-11-c and 2026-11-11-d); 2026-11-11 — Final Critique 21, a delta round, frozen at cb1e424 — foundational count 1 (Invariant 2.2 demanded failed-verification of a rewritten live outcome event while Action wiring 43 carries Audit Trail's own answer, and a deployment may set Audit Trail's unsealed tail mode to lenient, which Verify Record step 4.5 reads as covered and so skips the seal check, so a rewritten unsealed event answered verified and the two rules obliged two values; the reader's three traces were refuted on the text (the strict mode answers failed-verification carrying unsealed, a partially purged range has no whole covering range, a sealed rewrite answers a failed-verification) and the collision was found on this input by the triage: cured, Capability requirement 40 forbids lenient, as Verdict 12, Term passing verification and the unsealed-tail example already presuppose strict), not clean, no sample (one refining cured: Term attestation verification and the closure row for the verification's answer stated the reason and the qualifier unconditionally where Action wiring 43 and 44 carry them where the outcome carries one; the settle's own: Claim (c)'s sentence named seal-proof-invalid for every rewrite); 2026-11-11 — Final Critique 20, a delta round, frozen at 9c492b3 — foundational count 1 (a record read answering not-known landed the actor match, the recovery attestation and the entry payload match and left the attestation verification, which Invariant 5.1 obliges for every entry, with no landing, so one build carried none and another read Term attestation verification's not-called clause and carried payload-not-supplied, which Verdict 14 makes a class: cured, the attestation verification landing as unknown carrying not-known beside its two siblings, in Action wiring 62, Term attestation verification and the closure row; the blind second triage placed it, the first triage having read the arm as one conforming reading), not clean, no sample; Linus, the round's one report, claimed six foundational, five refining and one rhetorical: Invariant 2.2 read two ways on an unanswered verification refuted (Term live event excludes a record read answering not-known, and Audit Trail's verify_record declares no refusal), the actor match without an owner refuted (Term found verification is a [Verify Custody] call on a found chain, not an answer of the verification), a blank payload landing nowhere refuted (the verification answers an outcome, failed-verification(seal-record-set-mismatch), which Action wiring 43 carries and Verdict 11 applies), Check 1.2's "presents the covering range" and an omitted live member of a partially-purged range placed refining and kept on open lines 2026-11-06-e and 2026-11-06-h; refining cured (Action wiring 43 and 44 carry the reason and the qualifier where the outcome carries one) and kept open (Term actor match's "the actor reference": open line 2026-11-11-b) and refuted (Action wiring 46's reading of the outcome alone: Term attestation verification keeps the qualifier beside it); 2026-11-11 — Final Critique 19, a delta round, frozen at f10d9ab — foundational count 1, not clean, no sample; 2026-11-10 — Final Critique 18, a full round, frozen at 234409b — foundational count 5, not clean, no sample; 2026-11-06 — Final Critique 17, a delta round, frozen at dbb9804 — foundational count 0, clean, one sample; 2026-11-06 — Final Critique 16, delta — foundational count 1, not clean, no sample

open:
- 2026-11-04-d · refining · Action wiring 39, 56 · the verification call may present an empty payload, which Audit Trail Primitive policy 27 forbids a caller with no exemption, though Audit Trail never reads it there (Verify Record step 1.2, 1.3 for Purged; step 4.2, 4.3 for partially-purged coverage) and answers an empty one only where step 5 runs; withholding the call instead would drop step 3's attestation outcome on partially-purged coverage (Action wiring 43, Verdict 10, 15) → decide whether Audit Trail scopes Audit Trail Primitive policy 27 to a call that reaches step 5, as a caller exemption
- 2026-11-04-e · refining · Capability requirement 24 · the minted ids' width is no bound Provenance declares, so the payload cap sums capped inputs alone → decide whether Provenance declares an id width; sharper under Recoverable Invocation's outcome envelope, which wants every reference under its reference length cap (Recoverable Invocation Invariant 6)
- 2026-11-04-f · refining · Action wiring 41, Verdict 2 · the missing sequence numbers and the named entries are set-valued outcomes with no stated cardinality cap (the sizing check) → state each as at most the covering range's size and the chain's entries; re-found by Final Critique 20 and 22
- 2026-11-06-c · refining · Clock semantics 1 · the Event Log sequence and the Provenance sequence have no cross comparison, so the binding rebuild's order across them is the build's → decide the ordering key a rebuild across both sequences uses
- 2026-11-06-e · refining · Check 1.2 · it cites Invariant 1.1 but tests the attestation, and Term passing verification admits unsealed and partially-purged-coverage, which Verdict 12 and 16 make classes → decide which invariant the check tests and whether a passing verification excludes the two; Final Critique 20 adds that "presents the covering range" reads a whole or a partial presentation, a partial one answering payload-not-supplied, which no passing verification admits, and that the check passes an unverifiable carrying partially-purged-coverage while a live member's payload was withheld (open line 2026-11-06-h); re-found by Final Critique 20 and 22
- 2026-11-06-f · refining · Check 4.1 · it names the states Retained and Purged, while Term live event adds unresolved in its compensation window → decide the retention states the check admits; re-found by Final Critique 22
- 2026-11-06-h · refining · Verdict 1, Action wiring 41, 56 · a chain whose every bound event is purged completes, and an omitted live member of a partially-purged range is never reported as payload-not-supplied → decide whether a standing class names an all-purged chain and whether Action wiring 41 reaches a partially-purged range; re-found by Final Critique 20, 22 and 23
- 2026-11-06-i · refining · Term original event payloads · the caller's map has no cardinality cap, so the verification input's size is unbounded for a large covering range → state the cap; re-found by Final Critique 22
- 2026-11-10-a · refining · Composition notes; Term origination transaction, Term transfer transaction · Recoverable Invocation's bound commit is one constituent call, and the origination's is two calls and the transfer's a read, a comparison and a write, each in one database transaction, a case Recoverable Invocation's closed deviation list does not name (Recoverable Invocation Deviation 2) → carry to Recoverable Invocation's next revision as evidence, or declare it there
- 2026-11-10-b · refining · Term originate probe, Term carried entry · a genesis entry does not carry the artifact reference, which only the genesis lookup ties to its chain, so whether the originate probe meets Recoverable Invocation act probe 8 (the matching record carries every field of the act key) is unsettled → decide whether the lookup's answer counts as the record carrying the artifact reference, or declare the originate probe undecidable for the kind
- 2026-11-10-c · refining · Term custody enumeration, Capability requirement 25 · Audit Trail's declared surfaces list no enumeration, so the Event Log range read the term names as passed through Audit Trail has no declared provider (Audit Trail Action wiring 1 is its only home, and Audit Trail's own open line 2026-10-05-a records that the surface carries no entry for it); Immutable Ledger, Execute Gated Workflow, Multi-Party Approval and Propagate Consent Revocation Downstream carry the same form → decide whether Audit Trail declares the passthrough in its surface, or the four pages and this one read Event Log under the Execution Contract's direct-invocation rule; re-found by Final Critique 22 and 23
- 2026-11-10-e · refining · Action wiring 36, 37 · an entry whose close has not landed is a young entry (Cross-record consistency 1, Check 1.1 excuses it) and lands binding-gap, so a proof taken inside the closure window reads custody-proof-incomplete for a transient state → decide whether a young entry is exempt or a class of its own; re-found by Final Critique 22 and 23
- 2026-11-10-f · refining · Check 5.3, Summary · [Verify Custody] never checks that a bound event carries the binding's entry id (the auditor's Check 5.3 does), and the Summary's "no entry was tampered with" reads past the compared fields, which exclude the metadata (Primitive policy 15) → decide whether [Verify Custody] checks the binding's entry id and whether the anchor's metadata carve-out is a Non-goal; re-found by Final Critique 22
- 2026-11-10-g · refining · Action wiring 21, Term transfer · a retry of [Transfer Custody] after a lost answer lands a second entry transferring the holder to itself, which the continuity check reads continuous while Term Transfer says a transfer is a hand-to-hand change → decide whether an incoming custodian equal to the resolved custodian is refused or a permitted entry; re-found by Final Critique 23
- 2026-11-11-a · refining · Term attestation reason · the term defines a failed-verification reason by exclusion from the five seal and retention reasons, a base set Audit Trail's declared surfaces do not enumerate, so if those five are the substrate's whole reason set Verdict 10 never applies → carry to Audit Trail: declare the reasons its attestation step returns, then name them here
- 2026-11-11-c · refining · Check 5.1, Check 5.2, Invariant 4.3, Invariant 4.4 · the checks test every outcome event, and the invariants they name claim only the invocation-written ones (the NOTE under Invariant 4 says an operator's closing is found by the checks), so the rule an operator-written duplicate or an operator-written outcome naming an absent entry violates is named by none → decide whether Invariant 4.3 and 4.4 cover every outcome event or the checks name Composition state 9 and scope themselves to the invocation-written ones
- 2026-11-11-d · refining · Invariant 1.1, Check 1.1, Check 5.9 · the carrying intent's states (open, escalated, abandoned, refused) are named inside conditions and no Term declares the set Value set 1 asks for, and Recoverable Invocation declares no term for an intent's states → carry to Recoverable Invocation: declare the intent's states, then cite them here; re-found by Final Critique 23
- 2026-11-11-e · refining · Composes 10, Composition state 7 · the invalid-query rule answers state-unavailable at [Verify Custody] alone, and the binding rebuild Composition state 7 obliges names no action that runs it, while Check 5.1 reads the enumeration too → decide whether the rebuild runs at [Verify Custody] alone or the rule names each action that reads the enumeration
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/chain-of-custody.md`; the migration and the earlier gate records that got it here are in [its history](./chain-of-custody.hist.md).

- **2026-11-10 — The wait retired: the five custody actions are five Recoverable Invocation act kinds.** *Chose:* (Scott, 2026-11-09 9:17 PM Central, "A", and 2026-11-10 7:15 AM Central, the wait ruling, "simple DRY"; the map rounds/coc-ri-map-2026-11-10.md, its directions settled under A, 2026-11-10 7:55 AM Central) the five custody actions each bind one act kind, custody.originate keyed by the artifact reference, the custodian reference and the genesis type under the minted-key deviation, with the origination transaction its commit, custody.transfer, custody.transform, custody.disclose and custody.archive keyed by the chain id, every kind repeatable (A: act kinds split by the wait, G4); the intent commits at the open and the outcome at the close, so an Audit Trail fault at the outcome leaves an open intent the sweep closes, and Provenance's storage-failure is a pre-commit refusal (A: an audit failure composes rather than committing a partial); the transfer's resolution read left ahead of the open, and the transfer transaction re-reading the holder and refusing not-current-custodian where it changed, so the attribution the one transaction gave is kept by a refusal (A: a collision becomes a refusal, G1; Action wiring 63 through 65); the invocation's now injected into Provenance's seam as every kind's pairing datum, so a lost reply closes itself (G2, Capability requirement 34, 35); every custody action's caller-visible codes Recoverable Invocation's, recording-failure(outcome) answered and not refused, every Provenance refusal leaving a refusal record, and the events renamed custody.<kind>.* with `recovery` for `cascade_recovery` (A: codes change to Recoverable Invocation's, G5); an operator's outcome detected, not prevented, by the binding-duplicate finding and Check 5.1, 5.2, with the false-closing alert in the leg (A: detected, not prevented, with an alert, G6; Reconciliation 32); an intent whose invocation died before its commit escalated for an operator in place of being read silently as a refused attempt (G8); an entry no intent carries a write-ownership finding in place of orphan-unpaired and its escalation (A: a record with no intent becomes a finding, G9); the leg on Recoverable Invocation's cadence, run and run reading, its enumeration taken at the run's start and its aged edge excluding an entry whose intent the horizon may have destroyed (G10); Term actor match reading an operator's outcome as match carrying recovery (G7). Composes 11, Capability requirement 9 through 12, 27, 29 through 32, Primitive policy 14, every live Audit arm rule, Action wiring 1, 3, 4, 7, 60, Reconciliation 1, 8 through 10, 12 through 15, 17, 18, 21 through 29, Invariant 1.3, 1.4, 4.2, 4.5, 7.1, Check 1.4, 1.5, 5.6 through 5.8, 6.1 and Clock semantics 3 tombstoned to what owns them; Composes 12 through 16, Capability requirement 34 through 39, Audit arm 29, Action wiring 63 through 68, Reconciliation 30 through 34, Check 5.9, 7.3, External check 6, Non-goal 12, 13 and Cross-record consistency 1 new; the closure table drafted. Rules 235 to 202. *Over:* removing the wait by reversing 2026-10-20, so that an Audit Trail refusal of the outcome fails the whole custody action, which would make the substrate's health a precondition of recording a step whose artifact has already changed hands — the gap in custody the pattern exists to prevent — and keeping the page's own reconciliation beside Recoverable Invocation, which would have covered the intent-and-outcome pairing twice. *Because:* the wait was self-made: the 2026-10-20 decision left a committed custody entry with its record owed so an Audit Trail fault never undid an irreversible Provenance write, and the page then built the pairing, the candidates and their cap, the recovery identity, the compensation window, the liveness sum and the escalation to close it, which Recoverable Invocation owns; nineteen of the thirty-three foundational findings of Final Critique 10 through 17 sat in that machinery. It turns the 2026-10-20 entry's "what closes it stays" and, in part, the 2026-10-27 entry: the one transaction no longer spans the transfer's resolution and its write, and the re-check restores the foreclosure. *Costs:* a Lease host, the instance's bounds and a sweep; every custody action's caller-visible codes; a new refusal at [Transfer Custody] for a holder that changed between the resolution and the commit; the pairing rests on a deployment obligation on Provenance's seam; operator work for an intent whose invocation died before its commit; Invariant 4.3 and 4.4 fall from prevented to detected against an operator's resolve.
- **2026-10-27 — The principal divergence retired: the one transaction forecloses it.** *Chose:* the transfer leg paired by Term realize, like every other leg, so an orphan transferred entry pairs to the unmatched intents it realizes, from the custodian each authenticated, and a transfer written outside the composition's surface that no intent realizes lands orphan-unpaired, surfaced and escalated (Reconciliation 10 through 12, Invariant 4.5); Reconciliation 16, 19 and 20, Invariant 4.6, the principal-divergence finding, Term confirmed transfer and Action wiring 22's confirmation read deleted, each tombstoned to its owner, with Action wiring 26 recording custody.transferred under the resolved custodian; Term compensable orphan paired to at least one intent, so the zero-candidate orphan Reconciliation 12 never compensates is one Invariant 4.5 escalates; and the formal model re-derived for this protocol, its in-invocation retry gone (chain-of-custody.tla, 8 twins, 6 probes). Rules 224 to 219. *Over:* keeping the divergence at the reconciliation and opening it only where no paired intent realizes the entry, the first cure open line 2026-10-27-a named. *Because:* the maintainer ruled 2026-10-27 that the one transaction already forecloses a divergence at the invocation: a transfer's resolution read and its write are one transaction (Execution Contract Database 2), so a committed transfer's outgoing custodian is its intent's, and what the reconciliation's comparison still caught was a write outside the composition's surface, which orphan-unpaired lands, and a false divergence between two orphans of one chain (2026-10-27-a). It turns the 2026-08-30 entry's divergence landing, which the 2026-10-20 rewrite kept. Open lines 2026-08-30-v and 2026-10-27-a close as dissolved, and 2026-08-29-a closes: the re-derived model carries the recovery identity, the recovery intent and the aged-intent edge.
- **2026-10-20 — The store's guarantees cited, not restated, and a custody action's writes one transaction.** *Chose:* Capability requirement 28 citing Execution Contract Store 1 through 4 for the store the chain, the substrate and the binding index keep their records in; the rules restating what that store guarantees tombstoned to it — the binding index's durability and the auditor's reading of it, the chain exclusion with its supply, holding, release, lease and the refusal to start without it, an invocation's release of it and the expiry of its lease, the reconciliation's take of it and the host's declaration an auditor read (Composition state 12, Capability requirement 13, 14, 16 through 21, Action wiring 6, Audit arm 20 through 22, Reconciliation 5, 6, Concurrency 1, 2, External check 4, 5); the rule denying that a Provenance entry and its outcome event commit together, which Store 1 as ruled contradicts (Wiring decision 2); and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the reconciliation's lower edge, the outcome retry attempts and the in-invocation retries with their pre-check and adoption, the read-back of a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing, the escalation of an invalid-request(step-4) whose event the read-back cannot find, which Audit Trail's evidence rule leaves appended, a recording-failure carrying outcome for a Provenance read that fails after the write, the mid-flight revocation and its re-attestation, which the one transaction's read of the actor registry forecloses, the principal divergence at [Transfer Custody], which the one transaction's resolution read forecloses, and the auditor's durability reading of an unbound pre-horizon entry (Reconciliation 3, Capability requirement 8, Audit arm 5, 11 through 18, Action wiring 10, 23 through 25, Check 5.4). Rules 263 to 228. *Over:* a Provenance write and an outcome append no transaction could span, so that each custody action was ordered across a durability boundary — the entry committed first, its outcome appended second — with a chain exclusion the host held across the invocation's retries as a lease, and a reconciliation that took the exclusion and paired what a crash between the writes left. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal. The Provenance write and the audit append are store writes, Provenance and Audit Trail each supplying theirs under Store 1 through 4, so a custody action's intent, entry and outcome commit together; and the chain exclusion, a host mutual exclusion over store-only work, is Store 2's, under which a custody action's reads of a chain and the writes they decide are one transaction. An Audit Trail refusal at an outcome still leaves the custody entry committed and its record owed (Audit arm 19, 24, 26), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the reconciliation's pairing, its candidates and their cap, the genesis lookup, the recovery identity behind a recovery intent, the re-read before a compensating event, the custody compensation window and the liveness sum it must exceed, and the escalation; the custody completion bound stays with them, since the liveness sum and the pairing still read it (Capability requirement 12, Reconciliation 16, 17). The binding index stays a derived index outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps it, so its rebuild on a miss and the binding-unknown reading of an entry no rebuild can reach stay (Composition state 7, Action wiring 36). Custody records are ordered by the Event Log's and Provenance's own sequence numbers (Clock semantics 1) and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.
- **2026-08-30 — One writer per entry, the purged answer first, the attestor named, the divergence landed, the genesis leg honest about what it can find.** *Chose:* an in-invocation retry bounded by `outcome_retry_attempts` and a scan that takes the per-chain section for every chain it touches, so the invocation and the scan never both land an outcome for one entry, with a binding-duplicate collision rule on the rebuild and check 5 quantified over the log; [Verify Custody] branching on retention state before any composition-side membership check, so a purged entry lands `failed-verification(purged)` and [Custody Proof Complete] stays reachable after a purge; an `actor_match` field and check-1 clause comparing the attestation's surviving `actor_ref` to the entry's custodian; `rejected(principal-divergence)` at [Transfer Custody] step 5 with no outcome written and a scan that never compensates it; `genesis_lookup` declared as an instance capability requirement, the genesis leg downgraded to *surfaced* without it; `recording-failure(intent | outcome)` on every signature; the liveness inequality written out with `outcome_write_latency`; `intent_candidates_cap` sizing the compensation envelope; and, on the closure check, `chain_serialization` declared as the instance capability the one-writer rule rests on, with a lease exactly the bound long whose expiry is the invocation's terminus, the transfer leg pairing by chain and recipient before it compares actors so a divergence is reachable at the scan, the zero-match landing (escalate, never compensate), and checks 2 and 4 quantified over the log. *Over:* "retry until it lands" beside a scan starting at the bound; a membership check ahead of the constituent's purged short-circuit; a check that confirmed the credential was valid and not whose it was; a code in the signature with no landing; a genesis leg that presumed a lookup Provenance declines; a bare token on both sides of the commit. *Because:* two compensators over one act land two outcomes the seal then protects; a lawfully destroyed payload is not one the caller failed to supply; a valid credential attesting a step its holder did not perform is the forgery the proof exists to catch; a committed entry nobody authenticated cannot be attested later without inventing an attribution; and a caller who cannot tell intent from outcome re-runs a committed act (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *A composition's own rejection arm carries the retry bit*, *Liveness is arithmetic*, *An outcome is sized before the intent*, and *Capability provenance* frozen — with §*Authentication precedence*'s binding half and §*A transcribed rejection arm*'s fourth tell).
- **2026-08-29 — The scan is bounded at both edges, pairs by parameters and names candidates, and writes as the recovery identity behind a recovery record; the outcome's step decides its landing.** *Chose:* `custody_completion_bound` below and the audit horizon above for the reconciliation scan; an orphan entry paired to its intent by chain, custodian, and the parameters the entry realizes, with `intent_event_candidates` where more than one unmatched intent matches; every scan write under `recovery_identity` behind `custody.recovery_intended` (the in-invocation retry keeping the custodian's credential and no marker); `recording-failure(step-4)` and the retention-source invalid-request at an outcome record read back and treated as landed at all five actions; `compensation_window`, `reconciliation_cadence` and `index_durability` declared; Invariant 4's "committed atomically or" restated as ordered. *Over:* an unbounded scan whose crash-side retry had no identity it could honestly use, and "all three arms surface as recording-failure" at the outcome. *Because:* an unbounded scan mints a second outcome beside an in-flight invocation's and re-emits lawful destruction as orphans; the custodian's credential is never persisted; and the substrate's step-4 arm means the event exists (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*, *Recovery commits under a declared service identity*, *A transcribed rejection arm keeps its payload*).

- **2026-08-27 — The verification presentation is keyed by audit-log position, not by custody entry.** *Chose:* original_event_payloads keyed by `sequence_number`, with [Verify Custody] assembling each entry's presentation from the covering range `read_record` names. *Over:* a map keyed by `entry_id` holding one payload per entry, or a wiring rule requiring per-event cadence. *Because:* the substrate's rule is that a seal commits to a sequence range whose members include intent records and unrelated actions carrying no `entry_id`; an entry-keyed map cannot present that set under any cadence but per-event, and pinning the cadence would trade a representational fix for a deployment constraint.
- **2026-06-11 — Invariant 4's compensated arm is in the model, not idealized away.** *Chose:* re-derive the model over sequential sub-writes with compensation. *Over:* the original model, which committed the sub-writes as one atomic action. *Because:* the Provenance write is irreversible and the audit append cannot be withdrawn, so the compensated path is the design.
- **2026-08-26 — [Transfer Custody] resolves the outgoing custodian before it authenticates, and authenticates before it commits.** *Chose:* a read-only resolution step, then the intent record under the outgoing custodian's credential, then the Provenance call; invalid-credential restored to all five signatures, reversing Final Critique 5's F2 on new grounds. *Over:* declaring the pre-check "a deployment obligation" (Final Critique 5's F-6 closure), or authenticating the incoming caller, the only principal available earlier. *Because:* a declaration discharges nothing the records can show, and the guarantee names the outgoing custodian, a principal produced by the commit.

</details>

NOTE: End of Chain of Custody.
