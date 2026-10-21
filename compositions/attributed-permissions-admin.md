---
title: Attributed Permissions Admin
parent: Conceptual Compositions
nav_order: 8
has_toc: true
toc: true
---

# Attributed Permissions Admin

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Attributed Permissions Admin makes sure every access grant and every revocation comes with verifiable proof of who authorized it. It combines two patterns: one that records access grants and answers *is this allowed?* (Permissions) and one that records a verifiable attestation binding a named actor to an action (Actor Identity). Neither knows about the other — Permissions records grants and not who issued them, and Actor Identity records who attested to an action and knows nothing about grants. The composition wires them so that issuing or revoking a grant always does both, in a fixed order, and records the pairing, so there is no way *through the composition* to create a grant without an attestation or revoke one without proof of authorization. That makes the regulator's question — *who granted this access, when, and under what credential?* — answerable from the records alone.

Combining the two produces guarantees neither has alone: no grant lacks attribution, every revocation is attributed, and given any grant you can recover who authorized it and the proof. One honest limit: someone with direct write access to the underlying grant records could still insert an unattributed grant, bypassing the composition entirely; closing that gap requires the separate Tamper Evidence pattern. A second: the composition administers grants and does not decide whether the grantor was *permitted* to issue one.

The composition also carries the action an administrative surface actually needs and a grant-keyed one cannot give it. Permissions answers *denied* only when **no** active grant matches a subject and a scope, and several active grants on one pair are lawful — two administrators may independently authorize the same access. Revoking one of them leaves the permission held. [Revoke Permission] is therefore pair-scoped: it revokes every active grant on the pair, each under its own attestation, and the caller's terminal signal is the evaluation query answering denied rather than a count of records removed.

The most common uses are administrative access-control panels in SOX (Sarbanes-Oxley Act)-scoped financial systems, HIPAA (Health Insurance Portability and Accountability Act)-regulated health-record systems where every access grant must be attributable to the granting administrator, PCI DSS (Payment Card Industry Data Security Standard)-scoped payment systems where Requirement 7 mandates attributed authorization, FDA (US Food and Drug Administration)-regulated pipelines under 21 CFR (Title 21 of the Code of Federal Regulations) Part 11 where branch-protection grants must carry a verifiable approver, and legal document systems where matter-level grants must be attributable to the responsible partner. In every case the mechanic is the same — attest first, record second, pair third — and the audit answer is structural.

---

## Intent

Permissions alone records *that* a grant exists. Actor Identity alone records *that* an actor attested to an action. Neither tells the auditor *who issued this specific grant*, and neither prevents an unattested grant from being inserted into the permission records directly — by a database administrator, a misconfigured automation, or an attacker with write access to the grant table. The audit question the regulator actually asks — *who authorized this access, and can you prove they did?* — has no structural answer at the bare-atom layer.

This composition addresses that gap. Every [Issue Grant] call walks two atoms in a fixed order: Actor Identity records the grantor's attestation over a proposal naming the subject, the scope and the intent to grant, and then Permissions records the grant. The two records are paired in the composition's own state — the grant's handle bound to the attestation's — and the pairing is recoverable from either side. Revocations follow the same shape: the revoker attests, Permissions revokes, the pairing is recorded against the grant.

The pattern matters because regulated systems consistently fail this audit question when the atoms are wired by hand at the calling layer. A developer who calls the grant surface without also calling the attest surface produces an unattributed grant — silent at the schema level, fatal at audit time. The composition makes the omission impossible through its exposed surface: there is no path through it that records a grant without attesting, or records a revocation without attesting. The bare atoms are unchanged; the composition is the wiring that turns *two separate records you can forget to coordinate* into *one administered action you cannot bypass through this surface*. An adversary with direct write access to the Permissions records can still insert unattributed grants, which is the exact tamper surface the breach-forensics scenario exposes and the Tamper Evidence composing pattern addresses.

There is a second gap, and it took two review rounds to name. The write surface is keyed by a grant's handle; the evaluation surface is keyed by the subject-and-scope pair; and nothing reconciled them. An administrator who meant *this actor should not have this permission* had no action to call, and an administrative surface that offered one grant's revocation as though it removed the permission misreported access. The repair is not to forbid several grants on one pair — that multiplicity is lawful and often intentional, and attributing exactly that case is why this composition exists — but to give the pair-scoped operation its own action.

This is not a Role-Based Access Control layer, not a delegation system, and not an attribute-based policy evaluator. Each is a separate composing pattern. This composition supplies only the bottom rung — every grant has a verifiable grantor, every revocation has a verifiable revoker — on top of which delegation, role management and policy reconciliation compose without re-inventing the attribution surface.

---

## Composes

- **[Permissions](../atoms/permissions.md)** — the grant records and the evaluation surface.
- **[Actor Identity](../atoms/actor-identity.md)** — the attestation surface the administration is attributed through.

```
Composes 1: EXACTLY ONE Permissions instance MUST serve the composition.
Composes 2: EXACTLY ONE Actor Identity instance MUST serve the composition.
Composes 3: The composition MUST NOT change a constituent's spec.
Composes 4: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 5: The composition MUST reach a constituent through the constituent's declared surface.
Composes 6: The composition MUST NOT read a constituent's records beside the constituent's declared read.
Composes 7: The composition MUST wrap Permissions' grant.
Composes 8: The composition MUST wrap Permissions' revoke.
Composes 9: The composition MUST pass Permissions' evaluation through unchanged.
Composes 10: The composition MUST NOT interpose on an evaluation.
Composes 11: The composition MUST wrap Actor Identity's attest.
Composes 12: The composition MUST surface Actor Identity's verify inside the attribution query.
Composes 13: The composition MUST NOT delete an attestation.
Composes 14: The composition MUST NOT reverse a committed constituent write.
Composes 15: The composition MUST attest an administrative act ONLY AFTER the boundary predicate.
Composes 16: The composition MUST record a grant ONLY AFTER the administrative act's landed attestation.
Composes 17: The composition MUST record a revocation ONLY AFTER the administrative act's landed attestation.
Composes 18: The composition MUST NOT record an administrative act carrying no attestation.
Composes 19: The composition MUST NOT claim coverage of a write made outside the composition's surface.
Composes 20: The composition MUST enumerate an attestation through Actor Identity's declared read.
Composes 21: The composition MUST filter an enumerated attestation in the composition's own code.
Composes 22: The composition MUST NOT query Actor Identity by an action reference.
Composes 23: The composition MUST mint one attestation PER administered grant.
Composes 24: The composition MUST NOT share one attestation across two administered grants.
```

Term composition: this pattern's wiring of [Permissions](../atoms/permissions.md) and [Actor Identity](../atoms/actor-identity.md) — the three administrative actions, the attribution query, the evaluation passthrough, the two pairing maps, the orphan log and the report-only leg.

Term constituents: [Permissions](../atoms/permissions.md), [Actor Identity](../atoms/actor-identity.md).

Term administered grant: a grant this composition's own surface issued or revoked, as against one a direct database write produced.

Term administrative act: an issuance, a revocation, OR a pair-scoped revocation — the three state changes this composition exposes.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store a grant attribution map.
Composition state 2: The composition MUST store a revocation attribution map.
Composition state 3: The composition MUST store an orphan log.
Composition state 4: The composition MUST NOT mint an identity of the composition's own.
Composition state 5: The composition MUST key the attribution maps by the grant's handle.
Composition state 6: The composition MUST classify the grant attribution map as extraction-pending.
Composition state 7: The composition MUST classify the revocation attribution map as extraction-pending.
Composition state 8: The composition MUST name the binding registry as the attribution maps' proposed atom.
Composition state 9: The composition MUST classify the orphan log as re-house-on-event-log.
Composition state 10: The composition MUST name the event log as the orphan log's proposed home.
Composition state 11: A grant attribution entry MUST name EXACTLY ONE attestation.
Composition state 12: A revocation attribution entry MUST name EXACTLY ONE attestation.
Composition state 13: A grant MUST NOT carry two revocation attribution entries.
Composition state 14: The composition MUST NOT change an attribution entry.
Composition state 15: The composition MUST NOT drop an attribution entry.
Composition state 16: The composition MUST NOT change an orphan log entry.
Composition state 17: The composition MUST NOT drop an orphan log entry.
Composition state 18: The composition MUST NOT derive an attribution entry from a constituent's records.
Composition state 19: An orphan log entry MUST carry the attestation, the proposal, the request instant AND the underlying reason.
Deleted: Composition state 20. Execution Contract Database 1 owns it.
Deleted: Composition state 21. Execution Contract Database 1 owns it.
Deleted: Composition state 22. Execution Contract Database 1 owns it: an administrative act's attestations, constituent writes and pairing entries commit together, and the composition names no unpaired grant for a stamp to join to an orphan log entry.
Composition state 23: The composition MUST NOT read the orphan log as the orphan detection surface.
Composition state 24: An auditor MUST detect an orphan against the constituents AND the attribution maps.
Composition state 25: The composition MUST write an attribution entry ONLY AFTER the entry's constituent write.
Composition state 26: An attribution entry MUST stand for the grant's lifetime in the Permissions records.
Composition state 27: A retention purge MUST cover a grant AND the grant's attestations AND the grant's attribution entries as one unit.
Composition state 28: A retention purge MUST cover an orphan attestation under the orphan attestation's own retention.
Composition state 29: The composition MUST NOT purge a record.
```

Term grant attribution map: grant_attribution — the composition's map from a grant's handle to the attestation that authorized the grant's issuance.

Term revocation attribution map: revocation_attribution — the composition's map from a grant's handle to the attestation that authorized the grant's revocation.

Term attribution entry: a grant attribution entry OR a revocation attribution entry.

Term orphan log: the composition's append-only operational record of an attestation that landed and whose administrative write did not — the composing system's retry and review surface, never the audit's orphan detection.

Term underlying reason: invalid-request | not-known | not-active.

Term orphan attestation: an attestation this composition minted that no attribution entry names.

Term binding registry: the proposed atom that would own a write-once, durable pairing of one key to another — the shape this composition's two maps carry and the composition-state audit also names for a principal-to-actor bijection.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The host MUST supply one nonce at the seam PER issuance.
Deleted: Capability requirement 3. Execution Contract Logic confinement 3 owns it.
Capability requirement 4: The transition MUST NOT mint a nonce.
Deleted: Capability requirement 5. Execution Contract Logic confinement 3 owns it.
Capability requirement 6: The composition MUST NOT mint a grant handle.
Capability requirement 7: The composition MUST NOT mint an attestation handle.
Capability requirement 8: The composition MUST NOT generate cryptographic material.
Capability requirement 9: A deployment MUST set the grant proposal format.
Capability requirement 10: The grant proposal format MUST carry a nonce.
Capability requirement 11: The grant proposal format MUST carry the namespace prefix.
Capability requirement 12: The revocation proposal format MUST stand fixed.
Capability requirement 13: The revocation proposal format MUST carry the namespace prefix.
Capability requirement 14: A deployment MUST NOT set the revocation proposal format.
Capability requirement 15: A deployment MUST serialize a proposal canonically.
Deleted: Capability requirement 16. Execution Contract Database 1 owns it.
Deleted: Capability requirement 17. Execution Contract Database 1 owns it.
Deleted: Capability requirement 18. Execution Contract Database 1 owns it.
Deleted: Capability requirement 19. Execution Contract Database 1 owns it.
Capability requirement 20: The deployment MUST declare the clock offset allowance.
Deleted: Capability requirement 21. Execution Contract Database 1 owns it.
Deleted: Capability requirement 22. Execution Contract Database 1 owns it.
Deleted: Capability requirement 23. Execution Contract Database 1 owns it.
Deleted: Capability requirement 24. Execution Contract Database 1 owns it.
Deleted: Capability requirement 25. Execution Contract Database 1 owns it: an administrative act's attestations, constituent writes and pairing entries commit together, and the composition names no pairing write atomicity for an instance to lack.
Deleted: Capability requirement 26. Execution Contract Database 3 owns it.
Capability requirement 27: A deployment MUST declare the retention scope.
Capability requirement 28: A deployment MUST serve a purge record PER purged attestation.
Capability requirement 29: The composition's length cap MUST NOT EXCEED the Permissions instance's length cap.
Capability requirement 30: A deployment MUST check the length caps at an instance's start.
Deleted: Capability requirement 31. Execution Contract Database 2 owns it: a pair-scoped revocation's enumeration and the revocations it decides are one transaction, and the composition names no race for a critical section keyed by the pair to close.
Capability requirement 32: The composition MUST NOT require a critical section keyed by the pair.
Capability requirement 33: A deployment MUST NOT gate a grantor's authority at this composition.
Capability requirement 34: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
```

Term seam: the composition's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects one clock reading and one nonce here.
Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term transition: the composition's evaluation of one call against the constituents, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term grant proposal format: grant_proposal_format — the deployment's canonical serialization of `{subject_ref, action_scope, nonce, requested_at}` behind the namespace prefix, which is what an issuance attestation binds the grantor's proof to.

Term revocation proposal format: the fixed canonical serialization of `{grant_id, requested_at}` behind the namespace prefix, which is what a revocation attestation binds the revoker's proof to.

Term namespace prefix: the deployment's marker on every proposal this composition issues, by which an auditor tells this composition's attestations from a foreign composing system's in a shared Actor Identity records.

Term retention scope: the deployment's declaration of what a purge covers — the pair as one unit, or each record on its own.

Term purge record: the retention layer's own record that a named attestation was lawfully destroyed.

Term clock offset allowance: clock offset allowance — the declared envelope within which the two constituents' stamps, each written at its own seam, may be compared.

Term length cap: the composition's declared maximum length of an opaque input.

### Primitive policy

```
Primitive policy 1: An action MUST call a constituent ONLY AFTER the boundary predicate.
Primitive policy 2: The boundary predicate MUST refuse a blank opaque input.
Primitive policy 3: The boundary predicate MUST refuse an opaque input exceeding the length cap.
Primitive policy 4: The boundary predicate MUST refuse a blank credential.
Primitive policy 5: An action MUST answer invalid-request for a boundary predicate refusal.
Primitive policy 6: The composition MUST trim an administered opaque input.
Primitive policy 7: The composition MUST trim an administered opaque input EXACTLY ONE time.
Primitive policy 8: The composition MUST pass the trimmed value to a constituent.
Primitive policy 9: The composition MUST compare an opaque input case-sensitively.
Primitive policy 10: The composition MUST NOT fold an opaque input's case.
Primitive policy 11: The composition MUST NOT trim an evaluation input.
Primitive policy 12: The composition MUST NOT inspect a credential.
Primitive policy 13: The composition MUST NOT persist a credential.
Primitive policy 14: The composition MUST propagate a constituent's invalid-request as invalid-request.
Primitive policy 15: The composition MUST NOT read a constituent's invalid-request at the attestation step as a caller fault.
Primitive policy 16: The composition MUST read a constituent's invalid-request at the attestation step as a deployment fault.
Primitive policy 17: The composition MUST NOT query Permissions BEFORE a revocation's attestation.
```


Term boundary predicate: the composition's own validation of an input at an action's boundary, judged before any constituent call.

Term opaque input: subject reference | action scope | grantor ref | grantor credential | grant id | revoker ref | revoker credential.

Term administered opaque input: an opaque input an administrative action carries, other than a credential — as against one the evaluation passthrough relays.

### Identity

```
Identity 1: The composition MUST identify a pairing by the grant's handle.
Identity 2: The composition MUST NOT mint a pairing identity.
Identity 3: The grant's handle MUST stand as Permissions' own.
Identity 4: An issuance MUST carry a nonce.
Identity 5: The seam MUST allocate a nonce.
Identity 6: The composition MUST NOT reuse a nonce.
Identity 7: A proposal MUST carry the request instant.
Identity 8: The request instant MUST stand as the invocation's seam reading.
Identity 9: EVERY attestation of one pair-scoped revocation MUST carry one request instant.
Identity 10: An auditor MUST group a pair-scoped revocation's attestations by the request instant.
Identity 11: An issuance proposal MUST carry the subject, the scope, the nonce AND the request instant.
Identity 12: A revocation proposal MUST carry the grant's handle AND the request instant.
Identity 13: A proposal MUST NOT carry the grant's handle at an issuance.
Identity 14: The composition MUST NOT pair an attestation to a grant by a stamp.
Identity 15: The composition MUST NOT pair an attestation to a grant by a proposal body.
```

### Action wiring

```
issue_grant(subject_ref, action_scope, grantor_ref, grantor_credential)
  answers grant issuance result
  refuses invalid-request | invalid-credential | attribution-storage-failure | orphan-attestation(issuance orphan position)

revoke_grant(grant_id, revoker_ref, revoker_credential)
  answers grant revocation result
  refuses invalid-request | invalid-credential | not-known | not-active | attribution-storage-failure

revoke_permission(subject_ref, action_scope, revoker_ref, revoker_credential)
  answers permission revocation result
  refuses invalid-request | invalid-credential | not-permitted

verify_grant_attribution(grant_id)
  answers attribution record | not-known | attribution-inconsistency

permitted(subject_ref, action_scope)
  answers permitted | denied
```

Term grant issuance result: grant id and attestation id — what issue_grant answers.

Term grant revocation result: ok and attestation id — what revoke_grant answers.

Term permission revocation result: ok, revoked_grant_ids and attestation_ids — what revoke_permission answers.

Term attribution record: grant_record, issuance_attestation_id, issuance_verify_result, an optional revocation_attestation_id and an optional revocation_verify_result — what verify_grant_attribution answers.

Term issuance orphan position: pre-grant — where an issuance attestation was left without its grant: before the grant.

```
Action wiring 1: An issuance MUST assemble the proposal PER the grant proposal format.
Action wiring 2: An issuance MUST call Actor Identity's attest with the proposal, the grantor AND the grantor's credential.
Action wiring 3: IF Actor Identity answers invalid-credential THEN [Issue Grant] MUST answer invalid-credential.
Action wiring 4: IF Actor Identity answers invalid-request THEN [Issue Grant] MUST answer invalid-request.
Action wiring 5: IF Actor Identity answers storage-failure THEN [Issue Grant] MUST answer attribution-storage-failure.
Action wiring 6: IF Actor Identity refuses the attest THEN the invocation MUST NOT call Permissions' grant.
Action wiring 7: An admitted issuance MUST call Permissions' grant with the subject AND the scope.
Action wiring 8: IF Permissions answers invalid-request THEN [Issue Grant] MUST answer orphan-attestation carrying pre-grant.
Deleted: Action wiring 9. Execution Contract Database 1 owns it.
Action wiring 10: IF Permissions answers invalid-request THEN the invocation MUST log the orphan.
Deleted: Action wiring 11. Execution Contract Database 1 owns it.
Deleted: Action wiring 12. Execution Contract Database 3 owns it.
Deleted: Action wiring 13. Execution Contract Database 1 owns it.
Deleted: Action wiring 14. Execution Contract Database 1 owns it.
Action wiring 15: An admitted issuance MUST answer the grant's handle AND the attestation.
Action wiring 16: A revocation MUST assemble the proposal PER the revocation proposal format.
Action wiring 17: A revocation MUST call Actor Identity's attest with the proposal, the revoker AND the revoker's credential.
Action wiring 18: IF Actor Identity answers invalid-credential THEN [Revoke Grant] MUST answer invalid-credential.
Action wiring 19: IF Actor Identity answers invalid-request THEN [Revoke Grant] MUST answer invalid-request.
Action wiring 20: IF Actor Identity answers storage-failure THEN [Revoke Grant] MUST answer attribution-storage-failure.
Action wiring 21: IF Actor Identity refuses the attest THEN the invocation MUST NOT call Permissions' revoke.
Action wiring 22: An admitted revocation MUST call Permissions' revoke with the grant's handle.
Action wiring 23: IF Permissions answers not-known THEN [Revoke Grant] MUST answer not-known.
Action wiring 24: IF Permissions answers not-active THEN [Revoke Grant] MUST answer not-active.
Deleted: Action wiring 25. Execution Contract Database 1 owns it.
Action wiring 26: IF Permissions answers not-known OR not-active THEN the invocation MUST log the orphan.
Action wiring 27: A caller MUST read a not-known answer as a caller fault.
Action wiring 28: A caller MUST read a not-active answer as a caller fault.
Action wiring 29: A caller MUST read a not-known answer as an orphan the composition logged.
Action wiring 30: A caller MUST read a not-active answer as an orphan the composition logged.
Deleted: Action wiring 31. Execution Contract Database 1 owns it.
Deleted: Action wiring 32. Execution Contract Database 1 owns it.
Deleted: Action wiring 33. Execution Contract Database 1 owns it.
Deleted: Action wiring 34. Execution Contract Database 1 owns it.
Deleted: Action wiring 35. Execution Contract Database 1 owns it.
Deleted: Action wiring 36. Execution Contract Database 1 owns it.
Action wiring 37: A caller MAY retry a pre-grant landing.
Action wiring 38: A retry MUST stand as a fresh administrative act.
Action wiring 39: A retry MUST carry a fresh attestation.
Action wiring 40: A retry MUST carry a fresh nonce at an issuance.
Action wiring 41: An admitted revocation MUST answer the attestation.
Action wiring 42: A pair-scoped revocation MUST enumerate the pair's active grants through Permissions' declared read.
Action wiring 43: IF the enumerated set stands empty THEN [Revoke Permission] MUST answer not-permitted.
Action wiring 44: IF the enumerated set stands empty THEN the invocation MUST NOT call Actor Identity's attest.
Action wiring 45: The composition MUST NOT answer not-known for an empty enumerated set.
Action wiring 46: A pair-scoped revocation MUST perform a revocation PER enumerated grant.
Deleted: Action wiring 47. Execution Contract Database 2 owns it.
Action wiring 48: IF EVERY enumerated grant reached a committed revocation THEN [Revoke Permission] MUST answer the revoked grants AND the attestations.
Deleted: Action wiring 49. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 50. Execution Contract Database 1 and Execution Contract Database 2 own it.
Action wiring 51: A caller MUST read the evaluation answering denied as the terminal condition.
Action wiring 52: A caller MUST NOT read a revoked count as the terminal condition.
Deleted: Action wiring 53. Execution Contract Database 1 owns it.
Action wiring 54: A post-enumeration grant MUST stand outside the invocation.
Action wiring 55: The composition MUST read the grant through Permissions' declared read at [Verify Grant Attribution].
Action wiring 56: IF no grant EXISTS for the grant id THEN [Verify Grant Attribution] MUST answer not-known.
Action wiring 57: The composition MUST read the grant attribution entry at [Verify Grant Attribution].
Action wiring 58: IF no grant attribution entry EXISTS for the grant id THEN [Verify Grant Attribution] MUST answer attribution-inconsistency.
Action wiring 59: [Verify Grant Attribution] MUST read the revocation attribution entry ONLY IF the grant's status EQUALS revoked.
Action wiring 60: IF no revocation attribution entry EXISTS for a revoked grant THEN [Verify Grant Attribution] MUST answer attribution-inconsistency.
Action wiring 61: The composition MUST call Actor Identity's verify PER named attestation at [Verify Grant Attribution].
Action wiring 62: IF Actor Identity answers not-known THEN [Verify Grant Attribution] MUST read the purge record.
Action wiring 63: IF the purge record names the attestation THEN [Verify Grant Attribution] MUST answer not-applicable carrying purged.
Action wiring 64: IF the purge record names no attestation THEN [Verify Grant Attribution] MUST answer the tamper reading.
Action wiring 65: [Verify Grant Attribution] MUST NOT answer the tamper reading for a lawful destruction.
Action wiring 66: The composition MUST read the purge record ONLY AFTER an absent attestation.
Action wiring 67: [Verify Grant Attribution] MUST answer the tamper reading for an absent attestation under a pair-scoped retention scope.
Action wiring 68: A caller MUST read not-applicable carrying purged as consistent.
Action wiring 69: A caller MUST NOT read not-applicable carrying purged as a forensic finding.
Action wiring 70: A caller MUST read attribution-inconsistency as a forensic finding.
Action wiring 71: A caller MUST NOT read attribution-inconsistency as a miss.
Action wiring 72: A caller MUST NOT retry an administrative act against a grant answering attribution-inconsistency.
Action wiring 73: A caller MUST read the tamper reading as a forensic finding.
Action wiring 74: A caller MUST NOT read the tamper reading as a miss.
Action wiring 75: A caller MUST read a registry-unavailable verification as retryable.
Action wiring 76: A caller MUST NOT read a registry-unavailable verification as a forensic finding.
Action wiring 77: A caller MAY read a not-known answer over an absent grant as a miss.
Action wiring 78: [Verify Grant Attribution] MUST NOT write.
Action wiring 79: [Verify Grant Attribution] MUST answer the grant record, the issuance attestation AND the issuance verification.
Action wiring 80: [Verify Grant Attribution] MUST answer the revocation attestation AND the revocation verification ONLY IF the grant's status EQUALS revoked.
Action wiring 81: The composition MUST pass an evaluation to Permissions unchanged.
Action wiring 82: The composition MUST NOT record an evaluation.
Action wiring 83: The composition MUST NOT attribute an evaluation.
Action wiring 84: The composition MUST NOT project an enumerating read of a subject's permissions.
Action wiring 85: An administrative surface MUST project a permission list from the evaluation PER declared scope.
Action wiring 86: An administrative surface MUST NOT project a permission list from the grant records.
```

Term admitted issuance: an [Issue Grant] call whose boundary predicate passed and whose attestation landed.

Term admitted revocation: a [Revoke Grant] call whose boundary predicate passed and whose attestation landed.

Term pair-scoped revocation: a [Revoke Permission] call whose boundary predicate passed and whose enumeration returned an active grant.

Term enumerated set: the pair's active grants a pair-scoped revocation read at one instant.

Term verify result: verified | `failed-verification(reason)` | not-known | `not-applicable(purged)`.

Term tamper reading: [Verify Grant Attribution]'s reading of an absent attestation as evidence that the attestation record or the attribution entry was rewritten — sound only where no lawful destruction explains the absence.

Term lawful destruction: a retention layer's purge of an attestation the purge record names.

Term forensic finding: an outcome a caller logs and hands to the forensic process rather than handling as a routine lookup.

### Wiring decision

```
Wiring decision 1: The composition MUST record an administrative act's state change ONLY AFTER the administrative act's landed attestation.
Wiring decision 2: The composition MUST NOT record a state change BEFORE the administrative act's landed attestation.
Deleted: Wiring decision 3. Execution Contract Database 1 owns it.
Wiring decision 4: The composition MUST NOT delete an orphan attestation.
Wiring decision 5: The composition MUST read an orphan attestation as evidence of an attempted act.
Wiring decision 6: The composition MUST expose a pair-scoped revocation.
Wiring decision 7: The composition MUST NOT serialize an administrative act over the pair.
Wiring decision 8: The composition MUST NOT forbid a second active grant on one pair.
```

WHY:
*Principle.* No grant exists in the Permissions records, through this composition's surface, without its attestation in Actor Identity. The attestation is a prerequisite and not a complement.

*Likely objection.* Attesting first creates an orphan-attestation risk if the grant write fails.

*Mechanism that resolves it.* What makes attest-first the correct *order* is the asymmetry of the two failure modes, not a preference. An orphan attestation is **recoverable**: Actor Identity's records are immutable and independently verifiable, the orphan stands as evidence of an attempted administrative action, and the retry is a fresh act under a fresh nonce and a fresh attestation. A grant with no attestation is **unrecoverable**: the composition has no way to know, after the fact, what credential should have attested it. One failure mode leaves evidence; the other destroys the possibility of evidence.

*Result.* Invariant 1 holds structurally over the administered set. Wiring decision 4 and Wiring decision 5 are the price and are paid openly: orphans accumulate, the composition never deletes one, and the audit's job is to enumerate them rather than to prevent them.

### Housekeeping

```
Housekeeping 1: The composition MAY compose a failed-grant leg.
Housekeeping 2: The failed-grant leg MUST enumerate an attestation through Actor Identity's declared read.
Housekeeping 3: The failed-grant leg MUST filter an enumerated attestation by the namespace prefix.
Housekeeping 4: The failed-grant leg MUST read an attestation no attribution entry names as an orphan.
Housekeeping 5: The failed-grant leg MUST report an orphan.
Housekeeping 6: The failed-grant leg MUST NOT write.
Housekeeping 7: The failed-grant leg MUST NOT repair an orphan.
Housekeeping 8: The failed-grant leg MUST NOT complete an orphan's administrative act.
Housekeeping 9: The failed-grant leg MUST NOT call a constituent's write.
Housekeeping 10: The failed-grant leg MUST NOT promise a closure window.
Deleted: Housekeeping 11. Execution Contract Database 1 owns it.
Deleted: Housekeeping 12. Execution Contract Database 1 owns it.
Housekeeping 13: The failed-grant leg MUST age an attestation by the request instant the attestation's proposal carries.
Housekeeping 14: The failed-grant leg MUST widen the bound by the clock offset allowance ONLY IF the leg ages an attestation by a constituent's stamp.
Housekeeping 15: The failed-grant leg MUST NOT report an aged-out attestation as an orphan.
Housekeeping 16: The failed-grant leg MUST report an aged-out unpaired attestation carrying an orphan log entry as a purge-pending orphan.
Housekeeping 17: The failed-grant leg MUST report an aged-out unpaired attestation carrying no orphan log entry as a non-conformant purge.
Housekeeping 18: The failed-grant leg MUST NOT read an aged-out unpaired attestation as benign.
Housekeeping 19: A caller MUST retry an orphan's act as a fresh administrative act.
Housekeeping 20: EXACTLY ONE writer MUST land an administrative act.
```

Term failed-grant leg: the leg the Housekeeping rules state — this composition's own, over the attestations no attribution entry names.

Term post-enumeration grant: a grant a concurrent issuance committed later than a pair-scoped revocation's enumeration.

Term aged-out attestation: an attestation whose age exceeds the retention horizon.

Term landed attestation: an attestation Actor Identity has recorded and answered.

Term retention horizon: the instant past which the composing retention layer has lawfully purged a grant, the grant's attestations and the grant's attribution entries.

Term purge-pending orphan: an aged-out unpaired attestation whose orphan log entry stands — a purge the retention layer still owes.

Term non-conformant purge: an aged-out unpaired attestation carrying no orphan log entry — a pairing purged without its attestation, or an attestation the log never recorded.

---

## Composition-level invariants

```
Invariant 1.1: An administered grant MUST carry a grant attribution entry.
Invariant 1.2: A grant attribution entry MUST name an attestation the Actor Identity records hold.
Deleted: Invariant 1.3. Execution Contract Database 1 owns it.
Invariant 1.4: The composition MUST NOT claim Invariant 1.1 over a grant a direct database write produced.
Invariant 2.1: An administered revoked grant MUST carry a revocation attribution entry.
Invariant 2.2: A revocation attribution entry MUST name an attestation the Actor Identity records hold.
Deleted: Invariant 2.3. Execution Contract Database 1 owns it.
Invariant 3.1: The composition MUST answer a grant's record, the grant's issuance attestation AND the issuance verification PER known grant.
Invariant 3.2: The composition MUST answer a revoked grant's revocation attestation AND revocation verification.
Invariant 3.3: The composition MUST answer a grant's attribution without a log.
Invariant 3.4: The composition MUST answer a grant's attribution without a narration.
Invariant 4.1: An attestation's stamp MUST NOT EXCEED the attestation's grant stamp taken with the clock offset allowance.
Invariant 4.2: A revocation attestation's stamp MUST NOT EXCEED the grant's revocation stamp taken with the clock offset allowance.
Invariant 4.3: Invariant 4.1 MUST stand best-effort under a non-monotonic clock.
Invariant 4.4: No write MUST rest on Invariant 4.1.
Invariant 5.1: EVERY Permissions invariant MUST hold over the Permissions instance.
Invariant 5.2: EVERY Actor Identity invariant MUST hold over the Actor Identity instance.
Invariant 5.3: The composition MUST NOT weaken a constituent invariant.
Invariant 5.4: The composition MUST NOT count a constituent's invariants.
Invariant 6.1: The composition MUST NOT change a written attribution entry.
Invariant 6.2: The composition MUST NOT delete a written attribution entry.
Invariant 6.3: The composition MUST NOT expose a surface that changes an attribution entry.
Invariant 6.4: The composition MUST NOT claim Invariant 6.1 against a direct database write.
Invariant 7.1: The grant attribution map MUST stand injective.
Invariant 7.2: The revocation attribution map MUST stand injective.
Invariant 7.3: The two attribution maps' attestations MUST stand disjoint.
Invariant 7.4: An attest call MUST mint a distinct attestation.
Invariant 7.5: A grant proposal MUST stand distinct from another grant proposal.
Invariant 7.6: A revocation proposal MUST stand distinct from a grant proposal.
Invariant 8.1: The composition MUST NOT change a written orphan log entry.
Invariant 8.2: The composition MUST NOT delete a written orphan log entry.
Invariant 8.3: The composition MUST NOT expose a surface that changes an orphan log entry.
Invariant 9.1: EVERY grant of an enumerated set a pair-scoped revocation answered ok for MUST stand revoked.
Invariant 9.2: EVERY grant of an enumerated set a pair-scoped revocation answered ok for MUST carry a revocation attribution entry.
Invariant 9.3: The composition MUST NOT state Invariant 9.1 over the pair.
Deleted: Invariant 9.4. Execution Contract Database 1 and Execution Contract Database 2 own it.
```

Term known grant: a grant the Permissions records hold.

---

## Examples

### Walkthrough — issuing an attributed grant

A hospital's administration console grants a nurse read access to a patient record. The deployment's namespace prefix is `apa:grant:` and the retention scope covers the pair as one unit.

1. **Boundary.** `issue_grant(subject_ref = "nurse_4471", action_scope = "patient:88213:read", grantor_ref = "records_mgr_02", grantor_credential = <cred>)`. Each reference is non-blank and inside the length cap; the subject and the scope are trimmed once here, and the trimmed values are what the constituent stores.
2. **Proposal.** The seam injects one clock reading and one nonce. The proposal is `apa:grant:{nurse_4471, patient:88213:read, <nonce>, <requested_at>}`, serialized canonically.
3. **Attest.** `ActorIdentity.attest(proposal, "records_mgr_02", <cred>)` answers an attestation handle. **The grant does not exist yet, and cannot** — which is exactly why the grant map is not derivable: no attestation payload can name a handle that has not been minted.
4. **Grant.** `Permissions.grant("nurse_4471", "patient:88213:read")` answers a grant handle.
5. **Pair.** The grant attribution entry is written, and the call answers the pair. An auditor asking *who authorized this access* now reads the grant, the attestation and the verification from one query.

### Walkthrough — the permission, not the grant

Two managers have independently granted `"analyst_9"` the scope `"ledger:export"`. Both grants are active and both are lawful. An administrator means *this analyst should not have this permission*.

- `revoke_grant(<one handle>, …)` answers ok — and `permitted("analyst_9", "ledger:export")` still answers **permitted**. One record is gone; the permission is not. An administrative surface that offered that button as *remove permission* misreported access.
- `revoke_permission("analyst_9", "ledger:export", "security_lead", <cred>)` enumerates both grants, attests **twice** under one request instant, revokes both, and pairs both. It answers the two handles and the two attestations. permitted now answers denied, which is the caller's terminal signal — not the count of two.
- The auditor reads the two revocation attestations, same revoker, same instant, two grants of one pair, and sees **one administrative act** without the composition minting a field to say so.

### Rejection path — nothing to revoke

`revoke_permission("analyst_9", "ledger:export", …)` run a second time enumerates an empty set and answers [Not Permitted]: nothing is attested and nothing is written. [Not Permitted] is a first-class *there was nothing to do* answer, deliberately not the handle-absent code, which this composition reserves for a grant handle Permissions does not hold.

### Rejection path — a credential that does not validate

`issue_grant(…, grantor_credential = <stale>)` reaches the attest step and Actor Identity refuses. The call answers invalid-credential and **no grant is recorded** — the ordering's whole point. Nothing is logged as an orphan, because nothing was attested.

### Failure path — the orphan the ordering accepts

The deployment's Permissions instance was reconfigured to a length cap below the composition's own, a deployment fault (Capability requirement 29). `issue_grant(…)` attests successfully and `Permissions.grant` answers invalid-request on the over-length scope. An attestation now stands with no grant. The call answers `orphan-attestation(pre-grant)` and logs the orphan in the [Orphan Log]. The composition does **not** delete the [Orphan Attestation] — the constituent's durability invariant forbids it — and does not complete the grant behind it. The deployment rewires the cap, and the caller retries as a fresh issuance under a fresh nonce and a fresh attestation; the orphan stands as evidence that an administrative action was attempted and did not complete.

### Failure path — a grant written around the composition

A database administrator writes a grant straight into the Permissions records, outside this composition's surface, so no attestation and no grant attribution entry exist for it. [Verify Grant Attribution] on the grant's handle answers attribution-inconsistency, and the caller reads it as a forensic finding — never as a miss, and never as a cue to retry an administrative act against the grant — with the finding standing in the records.

### Failure path — a lawfully purged attestation

A deployment declares a **per-store** retention scope rather than the pair-scoped one. A grant's issuance attestation reaches its retention end and is purged; the grant is still standing. [Verify Grant Attribution] finds the attribution entry, calls verify, and gets an absent attestation — which under the pair-scoped scope would be a tamper signal. It reads the retention layer's purge record first, finds the attestation named there, and answers `not-applicable(purged)`. The caller counts that as **consistent**. Without this branch the query handed an auditor a forensic finding for a correctly-executed retention policy, which is the one class of false finding an attribution composition can least afford.

### Regulated adversarial scenarios

**Regulator audit — *who authorized this access, and can you prove it?*** For each grant in scope the examiner reads the grant record, follows the attribution entry to the attestation, and runs the constituent's verification. Invariant 1 makes the lookup succeed for every administered grant; Invariant 3 makes the answer complete without a log or a developer's narration. The examiner consults no source code.

**Disputed grant — *I never authorized that.*** The named grantor disputes an issuance. The attestation binds that grantor to a proposal naming this subject, this scope and this request instant, and the verification either stands or does not. An [Attribution Storage Failure] is the other shape a constituent fault takes here, and it names the attestation write rather than the caller. A failed-verification under a rotated credential is a credential-history question rather than a forgery finding — the attribution record is stable, and what moves is whether the registry still holds the material that signed it. That is the Compromise Disclosure pattern's and External check 2's.

**Breach forensics — *were any grants inserted without attribution?*** The investigator enumerates the Permissions records and, for each grant, looks for its attribution entry. A grant with none is **a write that bypassed this composition entirely**, the honest limit Intent states and Composes 19 makes a rule; closing that gap needs Tamper Evidence over the emergent state and over the grant records. What the composition *does* give the investigator is the complete orphan population from the other direction: every attestation this composition issued that no entry names.

---

## Generation acceptance

A derived implementation is *acceptable* — in the regulator-acceptance sense — when an external auditor, given the composition's two attribution maps plus the Permissions and Actor Identity records, clears every check below without recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find a grant attribution entry PER administered grant (Invariant 1.1).
Check 1.2: An auditor MUST call Actor Identity's verify for the named attestation (Invariant 3.1).
Deleted: Check 1.3. Execution Contract Database 1 owns it.
Check 1.4: An auditor MUST read an unpaired grant as an attribution inconsistency (Invariant 1.1).
Check 1.5: An auditor MUST NOT read a purged grant as a population member (Composition state 27).
Check 2.1: An auditor MUST find a revocation attribution entry PER administered revoked grant (Invariant 2.1).
Check 2.2: An auditor MUST call Actor Identity's verify for the named revocation attestation (Invariant 3.2).
Check 2.3: An auditor MUST read an unpaired revoked grant as an attribution inconsistency (Invariant 2.1).
Check 3.1: An auditor MUST compare an attestation's stamp against the attestation's grant stamp PER administered grant (Invariant 4.1).
Check 3.2: An auditor MUST run the comparison under the clock offset allowance (Invariant 4.1).
Check 3.3: An auditor MUST NOT read an inversion inside the clock offset allowance as a finding (Invariant 4.3).
Check 4.1: An auditor MUST clear Permissions' conformance checks over the Permissions instance (Invariant 5.1).
Check 4.2: An auditor MUST clear Actor Identity's conformance checks over the Actor Identity instance (Invariant 5.2).
Check 4.3: An auditor MUST NOT count a constituent's conformance checks (Invariant 5.4).
Check 5.1: An auditor MUST enumerate Actor Identity's declared read (Composes 20).
Check 5.2: An auditor MUST filter the enumeration by the namespace prefix (Capability requirement 11).
Check 5.3: An auditor MUST read a filtered attestation no attribution entry names as an orphan (Housekeeping 4).
Deleted: Check 5.4. Execution Contract Database 1 owns it.
Deleted: Check 5.5. Execution Contract Database 1 owns it.
Check 5.6: An auditor MUST read an aged-out unpaired attestation carrying an orphan log entry as a purge-pending orphan (Housekeeping 16).
Check 5.7: An auditor MUST read an aged-out unpaired attestation carrying no orphan log entry as a non-conformant purge (Housekeeping 17).
Check 5.8: An auditor MUST NOT read an aged-out unpaired attestation as benign (Housekeeping 18).
Check 5.9: An auditor MUST NOT read the orphan log as the orphan population (Composition state 23).
Check 6.1: An auditor MUST confirm no attestation appears twice in the grant attribution map (Invariant 7.1).
Check 6.2: An auditor MUST confirm no attestation appears twice in the revocation attribution map (Invariant 7.2).
Check 6.3: An auditor MUST confirm no attestation appears in both attribution maps (Invariant 7.3).
Check 6.4: An auditor MUST read a repeated attestation as a structural breach (Invariant 7.1).
Check 7.1: An auditor MUST find no grant a pair-scoped revocation answered ok for whose status DOES NOT EQUAL revoked (Invariant 9.1).
Check 7.2: An auditor MUST confirm EVERY grant a pair-scoped revocation answered ok for carries a revocation attribution entry (Invariant 9.2).
Check 7.3: An auditor MUST NOT read a post-enumeration grant as the enumeration's member (Invariant 9.3).
```

### External checks

```
External check 1: The deployment MUST establish the grantor's authority to issue the grant (Capability requirement 33).
External check 2: The deployment MUST establish the grantor's credential integrity since the attestation (Invariant 3.1).
Deleted: External check 3. Execution Contract Database 1 owns it.
Deleted: External check 4. Execution Contract Database 3 owns it.
External check 5: The deployment MUST establish tamper-evidence over the composition's own state (Invariant 6.4).
External check 6: The deployment MUST establish that a grant's scope stood in the deployment's scope vocabulary (Capability requirement 9).
External check 7: The deployment MUST establish the retention scope the purge ran under (Capability requirement 27).
External check 8: The deployment MUST establish that the namespace prefix stands on EVERY proposal (Capability requirement 11).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT gate a grantor's authority.
Non-goal 2: The composition MUST NOT manage a role.
Non-goal 3: The composition MUST NOT evaluate an attribute-based policy.
Non-goal 4: The composition MUST NOT model a scope hierarchy.
Non-goal 5: The composition MUST NOT model an explicit denial.
Non-goal 6: The composition MUST NOT model a delegation.
Non-goal 7: The composition MUST NOT bound a grant by time.
Non-goal 8: The composition MUST NOT revoke a grantor's issued grants on the grantor's deprovisioning.
Non-goal 9: The composition MUST NOT modify a grant.
Non-goal 10: The composition MUST NOT deduplicate a concurrent issuance.
Non-goal 11: The composition MUST NOT own pairing records as an atom.
Non-goal 12: The composition MUST NOT own an operational journal as an atom.
Non-goal 13: The composition MUST NOT seal the composition's own state.
Non-goal 14: The composition MUST NOT set a retention policy.
Non-goal 15: The composition MUST NOT aggregate two attestations for one grant.
Non-goal 16: The composition MUST NOT validate a scope vocabulary.
Non-goal 17: The composition MUST NOT anchor a stamp to a trusted time source.
```

NOTE: the owners — the organization (Non-goal 8); a deduplication layer (Non-goal 10); a witness or approval pattern (Non-goal 15).

---

## Edge cases

### Atomic writes

```
Atomic writes 1: An invocation MUST attest ONLY AFTER the boundary predicate.
Atomic writes 2: An invocation MUST call a constituent's write ONLY AFTER the invocation's landed attestation.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Atomic writes 4: The composition MUST NOT withdraw a landed attestation.
Atomic writes 5: An invocation MUST NOT retry a constituent write.
Atomic writes 6: An invocation MUST answer on a constituent's first refusal.
Atomic writes 7: A retry MUST stand outside the refused invocation.
Atomic writes 8: The composition MUST log an orphan PER refused administrative act carrying a landed attestation.
Deleted: Atomic writes 9. Execution Contract Database 1 owns it.
Deleted: Atomic writes 10. Execution Contract Database 1 owns it.
Deleted: Atomic writes 11. Execution Contract Database 1 owns it.
```

### Clock dependence

```
Clock dependence 1: A guard MUST NOT rest on now at this composition.
```

### Clock semantics

```
Clock semantics 5: The request instant MUST stand informational within a proposal.
Deleted: Clock semantics 2. Identity 8 owns it: a proposal carries the request instant (Identity 7), and the request instant is the invocation's seam reading.
Deleted: Clock semantics 1. Capability requirement 1 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 3 owns it.
Clock semantics 6: The nonce MUST carry a proposal's uniqueness.
Clock semantics 7: The request instant MUST NOT carry a proposal's uniqueness.
Deleted: Clock semantics 8. Clock dependence 1 owns it.
Clock semantics 9: A reader MUST read a constituent's stamp as that constituent's own seam reading.
Clock semantics 10: A reader MUST NOT read two constituents' stamps as one clock.
Clock semantics 11: A check comparing two seams' stamps MUST run under the clock offset allowance.
```

### Concurrency

```
Concurrency 1: Two issuances over one pair MUST produce two grants.
Concurrency 2: Two issuances over one pair MUST produce two attestations.
Concurrency 3: The composition MUST NOT read a second grant on one pair as a defect.
Deleted: Concurrency 4. Execution Contract Database 2 owns it.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Concurrency 6: A pair-scoped revocation MUST NOT serialize over the pair.
Concurrency 7: A post-enumeration grant MUST survive the enumeration's invocation.
Concurrency 8: A caller MUST call a pair-scoped revocation again ONLY IF the evaluation answers permitted.
Deleted: Concurrency 9. Execution Contract Database 2 owns it: a pair-scoped revocation's enumeration and the revocations it decides are one transaction, so no issuance commits inside the sweep for a critical section to keep out.
```

---

## Composition notes

These are adjacent patterns, **not** constituents of Attributed Permissions Admin:

- **Binding Registry** *(forthcoming)* — the write-once key-to-key pairing records the two attribution maps are extraction-pending against (Non-goal 12). The same shape recurs for a principal-to-actor bijection elsewhere in the corpus, which is the recurrence argument for the extraction.
- **Event Log** — the home the orphan log is re-house-pending against (Non-goal 13). This composition's cut has no Event Log constituent, so the log is composition-held under Invariant 8 until the re-housing lands.
- **[Tamper Evidence](../atoms/tamper-evidence.md)** — what elevates the composition's own emergent state from trusted storage to a verifiable claim, and what closes the direct-database-write gap Composes 19 declares open.
- **[Retention Window](../atoms/retention-window.md)** — the retention discipline Composition state 27 depends on and Capability requirement 27 makes the deployment declare. A per-store scope is what the query's purge branch exists for; a pair-scoped one is what makes an absent attestation evidence.
- **Delegation** *(forthcoming)* — the meta-grant layer that answers whether a grantor was permitted to issue a scope (Non-goal 1, External check 1).
- **Compromise Disclosure** *(forthcoming)* — what reinterprets an attestation whose credential was later compromised (External check 2).
- **Trusted Timestamping** *(forthcoming)* — the adversarially-defensible time anchor Invariant 4 does not supply (Non-goal 17).

---

## Terms

The canonical concepts this spec refers to. Each `[Term]` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind**, the Type it is a **Member of** or **Field of**, the Operation it is a **Parameter of**, its **Role** where the domain assigns one, and one **Projection** line — the concept's single canonical lowering token. The composition's own concepts are the three administrative actions, the attribution query, the orphan surfaces and its own rejections; the evaluation passthrough is Permissions' and is not carded here. The emergent maps, the constituent calls and their answers, the relayed tokens and the deployment knobs stay backticked as wire values.

### Vocabulary

Term actors: the composition; a deployment; the host; the seam; the transition; a caller; an auditor; an administrative surface; a reader; an implementation; an invocation; an action; an administrative act; an issuance; a revocation; a pair-scoped revocation; an admitted issuance; an admitted revocation; an evaluation; an attestation; a landed attestation; an orphan attestation; a proposal; a grant; an administered grant; a known grant; a revoked grant; a grantor; a revoker; a subject; a scope; a credential; a grant's handle; a nonce; a request instant; an attribution entry; a grant attribution entry; a revocation attribution entry; the grant attribution map; the revocation attribution map; an index; the orphan log; an orphan log entry; the failed-grant leg; an enumerated set; a critical section; a purge; a purge record; a lawful destruction; the tamper reading; a forensic finding; a verify result; a retention scope; the retention horizon; a purge-pending orphan; a non-conformant purge; the namespace prefix; the grant proposal format; the revocation proposal format; the clock offset allowance; the length cap; the binding registry; Permissions; Actor Identity; a constituent; a constituent's stamp; a clock reading; two issuances; two seams.

Term record verbs: serve, change, inherit, read, hold, reach, call, select, query, attest, own, place, admit, drive, know, push, store, classify, carry, stand, claim, populate, name, alert, drop, take, rebuild, recognize, supply, mint, generate, accept, configure, set, provision, rotate, disclose, run, fire, serialize, resolve, reconcile, refuse, normalize, fold, trim, compare, judge, propagate, cap, truncate, allocate, reuse, pair, make, retry, leave, record, answer, substitute, add, complete, clear, empty, write, advance, repoint, renew, cross, find, confirm, reproduce, establish, match, escalate, emit, expose, validate, commit, detect, inject, stamp, derive, deduplicate, model, schedule, adjudicate, purge, unwind, gate, index, anchor, surface, treat, sweep, spend, enroll, verify, suspend, reinstate, belong, elapse, invoke, duplicate, block, govern, identify, decide, reverse, destroy, revoke, enlist, snapshot, size, adopt, yield, release, count, abort, log, prove, weaken, lapse, deactivate, restore, issue, terminate, enumerate, declare, diverge, persist, inspect, digest, proceed, open, continue, append, compute, transition, produce, sample, repair, resume, restart, retake, assemble, filter, grant, project, aggregate, withdraw, survive, manage, evaluate, bound, seal, age, attribute, check, compose, cover, delete, forbid, group, interpose, key, land, modify, pass, perform, promise, report, require, rest, share, state, widen, wrap.

Term records: empty.

Term bounds: clock offset allowance, length cap, retention horizon.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.42 (2026-09-15).

Term value sets: verify result = verified | failed-verification(reason) | not-known | not-applicable(purged). underlying reason = invalid-request | not-known | not-active. retention scope = pair-scoped | per-store.

Term terms: composition, constituents, administered grant, administrative act, grant attribution map, revocation attribution map, attribution entry, orphan log, underlying reason, orphan attestation, binding registry, seam, transition, grant proposal format, revocation proposal format, namespace prefix, retention scope, purge record, clock offset allowance, length cap, blank, boundary predicate, opaque input, administered opaque input, admitted issuance, admitted revocation, pair-scoped revocation, enumerated set, verify result, tamper reading, lawful destruction, forensic finding, failed-grant leg, post-enumeration grant, aged-out attestation, landed attestation, retention horizon, purge-pending orphan, non-conformant purge, known grant, issuance orphan position, grant issuance result, grant revocation result, permission revocation result, attribution record.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Logic Confinement Principle in `execution-contract.md` — the seam.

Term composing patterns: Binding Registry *(forthcoming)*; Delegation *(forthcoming)*; Compromise Disclosure *(forthcoming)*; Trusted Timestamping *(forthcoming)*; Scope Registry *(forthcoming)*; [Event Log](../atoms/event-log.md); [Tamper Evidence](../atoms/tamper-evidence.md); [Retention Window](../atoms/retention-window.md); [Idempotent Reservation](./idempotent-reservation.md); [Multi-Party Approval](./multi-party-approval.md).

#### Issue Grant

The composition's attributed issuance: assemble a proposal naming the subject, the scope, a fresh nonce and the invocation's request instant; attest it under the grantor's credential; record the grant; and pair the two. The order is the composition's whole point — the grant's handle does not exist when the attestation is written, which is why the pairing is truth no constituent's records replay.

Kind: Operation

#### Revoke Grant

The composition's attributed revocation of one grant, keyed by the grant's handle: attest under the revoker's credential over the fixed `{grant_id, requested_at}` proposal, revoke, and pair. Answers the constituent's own not-known and not-active as caller faults — each of which still leaves an orphan attestation standing, because the attestation was written before the constituent was asked.

Kind: Operation

#### Revoke Permission

The pair-scoped action an administrative surface actually needs: enumerate every active grant on the subject-and-scope pair and perform [Revoke Grant]'s three steps on each, under the one request instant this invocation carries. The caller's terminal signal is the evaluation answering denied rather than the count of grants revoked, and a grant committed after the enumeration survives the sweep by declared degradation.

Kind: Operation

#### Verify Grant Attribution

The composition's read-only attribution query: the grant's record, its issuance attestation and verification, and — where the grant is revoked — its revocation attestation and verification. Answers [Attribution Inconsistency] where the grant stands and its attribution entry does not, and routes an absent attestation through the retention layer's purge record before reaching for the tamper reading, so a lawful destruction answers `not-applicable(purged)` rather than a forensic finding.

Kind: Operation

#### Orphan Log

The composition's append-only operational record of an attestation that landed while its administrative write did not — the composing system's retry and review surface. Never modified after a write (Invariant 8). Distinct from the audit's orphan detection, which runs structurally against the constituents and the maps and holds whether or not this log was populated or retained.

Kind: Type
Role: the append-only orphan record

#### Orphan Attestation

The composition's rejection when an administrative write fails after its attestation landed, leaving an unmatched attestation. **Its payload carries the position:** pre-grant means nothing administrative committed and the caller may retry.

Kind:       Member
Member of:  the administration rejection
Role:       Rejection
Projection: orphan-attestation

#### Attribution Storage Failure

The composition's rejection wrapping a constituent storage failure at the attestation step, surfaced under a composition-layer name so its origin — the attribution write, the first half of the act — is distinguishable from a caller error.

Kind:       Member
Member of:  the administration rejection
Role:       Rejection
Projection: attribution-storage-failure

#### Attribution Inconsistency

The [Verify Grant Attribution] forensic finding: the grant exists in Permissions and its attribution entry is unpopulated. A distinct condition from a grant that does not exist, never to be silently coerced to it, and never to be answered by retrying the original act.

Kind:       Member
Member of:  the verify result
Role:       Forensic finding
Projection: attribution-inconsistency

#### Not Permitted

The [Revoke Permission] answer when the pair holds no active grant: nothing is attested and nothing is written. A first-class *there was nothing to do* result, deliberately not the handle-absent answer, which this composition reserves for a grant handle Permissions does not hold.

Kind:       Member
Member of:  the administration rejection
Role:       Rejection
Projection: not-permitted

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Issue Grant]: #issue-grant
[Revoke Grant]: #revoke-grant
[Revoke Permission]: #revoke-permission
[Verify Grant Attribution]: #verify-grant-attribution
[Orphan Log]: #orphan-log
[Orphan Attestation]: #orphan-attestation
[Attribution Storage Failure]: #attribution-storage-failure
[Attribution Inconsistency]: #attribution-inconsistency
[Not Permitted]: #not-permitted

---

## Standards references

- **NIST (National Institute of Standards and Technology — the US federal standards body) SP 800-53 Rev. 5, AC-3 (Access Enforcement), AU-2 (Event Logging) and IA-2 (Identification and Authentication)** — the three controls this composition sits across: access is enforced by the constituent, the administrative act is recorded, and the actor performing it is identified and bound to the act.
- **SOX (Sarbanes-Oxley Act) section 404 (Internal Control over Financial Reporting)** — segregation-of-duties controls over access provisioning; the composition produces the records section 404 examines, and declines the control section 404 also wants — whether the grantor was authorized — to the layer that owns it.
- **HIPAA (Health Insurance Portability and Accountability Act) section 164.312(a)(1) and section 164.312(b) (Technical Safeguards — Access Control and Audit Controls)** — the combined access-control-with-audit-controls bar the two paragraphs together establish. Neither constituent clears it alone; the pairing is what does.
- **PCI DSS (Payment Card Industry Data Security Standard) Requirement 7 and Requirement 10** — Requirement 7 mandates that access authorization be documented and Requirement 10 that the administrative act be tracked; the attestation and the pairing are the structural form of both.
- **21 CFR (Title 21 of the US Code of Federal Regulations) Part 11 section 11.10 and section 11.50** — the electronic-signature regime applied to the grantor's attestation on an administrative action, including the signature manifestation the proposal body carries.
- **GDPR (the EU General Data Protection Regulation) Article 25 and Article 30** — data protection by design, and the records-of-processing obligation for access-administration events.
- **ISO/IEC 27001 clause A.9.2 (User access management)** — the International Organization for Standardization / International Electrotechnical Commission control requiring a formal user-access-management procedure with recorded authorization.

The two atoms carry their own standards inheritance — see each constituent's Standards references.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the composition discipline: a composition is the wiring of freestanding concepts, not a new primitive. Attribution and authorization are separate concepts; this composition wires them and invents neither.
- **The principle of attributable administrative action** — the structural form of what professional-responsibility codes, regulatory regimes and security frameworks all require by different names: an administrative act carries the identity of whoever performed it, provably, from the records.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation, 2026-08-30: the Failed-Grant Reconciliation leg is now a second, report-only process over each attestation with completion bounds below which it examines nothing, and Invariants 1 and 2 rest on a declared pairing-write atomicity the model takes as given rather than as a capability; and, 2026-09-10, [Revoke Permission] and Invariant 9 are prose repairs the model does not confirm — it carries one grant per pair and so cannot express an enumerated set, a partial sweep, or a grant landing mid-sweep (NOT MODELED); was verified — attributed-permissions-admin.als + attributed-permissions-admin.tla + 1 twin, 2026-06-12
last gate: 2026-08-26 — Final Critique 7, fresh reader — clean

open:
- 2026-08-30-b · refining · formal · the model has no report-only leg as a second process over an attestation and no [Revoke Permission] — a pair-scoped invocation over an Active set of several, with the concurrent-issue race Invariant 9 is deliberately not stated over → extend it, and check Invariant 9 and the race against a second writer rather than asserting either from the prose
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/attributed-permissions-admin.md`; the migration, the editorial rule and the family placement that got it here are in [its history](./attributed-permissions-admin.hist.md).

- **2026-08-30 — The reconciliation leg reports and never writes, bounded at both edges; the pairing-write atomicity is a declared capability, not an implementation note.** *Chose:* one writer per act — the invocation lands every grant, revocation and pairing, a retry is always a fresh administrative act under a fresh nonce and a fresh attestation, and the leg only surfaces orphans; the completion bounds as the leg's and the orphan check's lower edge and the pair-scoped retention purge as their horizon, with an unpaired attestation past the horizon reported rather than repaired; the pairing-write atomicity and the constituent-store durability declared as instance capability requirements with externally-clearable checks, the former the antecedent Invariants 1 and 2 carry; the orphan rejection carrying its position so a caller knows whether a grant exists before retrying; the orphan log entry carrying the grant's handle so the join is by key. *Over:* a leg that attempts the corresponding grant on retry beside a stalled invocation that could wake and pair the same attestation to a second grant; a leg with no lower edge and a check with no horizon; a horizon arm that read every unpaired attestation past the horizon as benign when the pair-scoped purge can never have purged an orphan's pair. *Because:* two writers over one attestation break Invariant 7's injectivity with no arm to catch it, a leg with no lower edge reads an invocation mid-flight as an orphan, and an antecedent an invariant rests on must be declared where the deployment can see and clear it (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, *An outcome is sized before the intent*, *Capability provenance*; with the section titled *A reconciliation is bounded at both ends* in `pressure-testing.md`).
- **2026-09-10 — The pair gets its own action; the multiplicity stays.** *Chose:* [Revoke Permission] over the subject-and-scope pair, revoking every active grant, each under its own attestation. *Over:* an issuance precondition refusing a second grant on a pair. *Because:* several active grants on one pair are lawful and often intentional — the constituent permits them by construction, and two grantors independently authorizing the same access is exactly the case an attributed-permissions composition exists to record. A precondition would have deleted that case to fix a surface problem and would have done nothing for the grants already standing. The defect was never the multiplicity; it was that the write surface is keyed by a grant's handle while the evaluation surface is keyed by the pair, with nothing reconciling them. **One attestation per grant rather than one shared across the set** is forced rather than chosen: Invariant 7 requires the revocation map to be injective and a check tests it, so a shared attestation would have broken a checked invariant to save an attest call. The auditor's grouping key is the shared request instant instead.
- **2026-09-10 — The concurrent-issue race is declared, not foreclosed.** *Chose:* a grant committed between the enumeration and the last revocation survives the sweep; the caller's terminal condition is the evaluation answering denied; Invariant 9 is stated over the **enumerated set** rather than over the pair. *Over:* requiring per-pair serialization as a further instance capability. *Because:* this composition declares the capabilities it actually needs and no others, and a critical section held across an administrative sweep is a real cost on every deployment to close a race a re-check closes for free. The deployment that needs the stronger form is told exactly what to supply and what it buys. **What this costs is stated where it lands** — Invariant 9 promises less than a reader would assume from its name, and says so in its own text.
- **2026-09-15 — A lawful destruction is answered before absence.** *Chose:* [Verify Grant Attribution] reads the retention layer's purge record when an attestation is absent, answers `not-applicable(purged)` where the purge record names it, and reaches the tamper reading only where nothing lawful explains the absence; the retention scope is a declared capability and the purge record a served surface. *Over:* leaving the tamper reading to rest on the pair-scoped purge requirement stated three sections away. *Because:* the strong reading is sound only under a pair-scoped retention scope — where nothing lawful can destroy an attestation while its grant stands. A deployment that composes a per-store retention instead reaches the state the requirement was meant to exclude, and the query then hands an auditor a **forensic finding for a correctly-executed retention policy**, which is the one class of false finding an attribution composition can least afford. Closes the Ledger's `2026-08-30-a`.
- **2026-10-20 — The store's guarantees cited, not restated, the pairing write atomicity among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 34), and the forty-eight rules that restated it, or existed only for a store that could lose or split a write, tombstoned to their owner — to Store 1, under which an administrative act's attestations, constituent writes and pairing entries commit together: the pairing write atomicity the deployment supplied, its one transaction over a constituent write and the write's pairing entry, and the antecedent Invariants 1 and 2 carried on it (Capability requirement 21 through 25, Action wiring 11, 31, Atomic writes 3, Invariant 1.3, 2.3, External check 3), the bar on enclosing an attestation and a constituent write in one transaction (Wiring decision 3), the orphan a constituent's storage failure or a refused commit left behind a landed attestation, and the caller's retry of it on the revoke side (Action wiring 9, 13, 25, 32, 34), the unpaired grant a failed pairing left, with its post-grant and post-revoke landings, the bar on retrying either, its join by the grant's handle and its disposal (Action wiring 14, 33, 35, 36, Composition state 20 through 22, Atomic writes 9 through 11), the completion bounds and the edges and checks that aged an invocation in flight (Capability requirement 16 through 19, Housekeeping 11, 12, Check 1.3, 5.4, 5.5), and the bar on claiming an atomicity across the enumerated set (Action wiring 53); to Store 1 and Store 2, the partially-revoked answer, the call again it alone admitted and the bound on what it asserts (Action wiring 49, 50, Invariant 9.4); to Store 2, a second revocation's not-active, the enclosing transaction's serialization, the sweep's skip of a grant a racing revocation took, and the optional critical section keyed by the pair with the race it closed (Concurrency 4, 5, 9, Action wiring 47, Capability requirement 31); and to Store 3, the answer only after the committed entry and the constituent stores' durability (Action wiring 12, Capability requirement 26, External check 4); with them [Revoke Grant]'s signature loses orphan-attestation and [Revoke Permission]'s loses partially-revoked, no kept rule answering either; rules 348 to 301. *Over:* the attestation committed in a transaction of its own, and a declared capability enclosing only the constituent write and its pairing entry; positioned orphans for a storage failure, a refused commit and a host that did not honour the capability; completion bounds below which the report-only leg examined nothing; and a pair-scoped revocation that claimed no atomicity across its set — the declared atomicity and the leg's lower edge are the turn of 2026-08-30, and the declared race the turn of 2026-09-10, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice: an attestation, the grant or revocation it authorizes and the pairing entry are store writes of one act, so a storage failure anywhere in it commits nothing, and Store 2 reads a pair-scoped revocation's enumeration inside the transaction that revokes, so no racing revocation or issuance lands inside the sweep. The attestation a constituent's refusal leaves (invalid-request at the grant, not-known or not-active at the revoke) stays as evidence of an attempted act, written with its orphan log entry in the refusal's transaction (Wiring decision 4, 5), and with it the orphan log, the report-only leg and its horizon arm; a grant committed after the enumeration stays outside the invocation, told from the records by the revocation attestations' shared request instant (Identity 9, 10) rather than by a commit order, so Order 1 is not cited. What the composition does for its domain is otherwise unchanged.

NOTE: End of Attributed Permissions Admin.
