---
title: Actor Identity
parent: Atomic Concepts
has_toc: true
toc: true
---

# Actor Identity

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>


## Summary

Actor Identity answers one question: "who authorized this action, and can you prove it?" It works through attestations — permanent records that tie a specific person or system to a specific action by way of a proof. A proof is a tamper-resistant artifact, computed from the actor's private credential, that anyone can later check without needing the credential itself. Creating an attestation consumes the credential to produce the proof and then throws the credential away; only the proof is kept. Checking one is purely read-only. Given an attestation's identifier, the system re-checks the stored proof against the recorded action and actor, using only public information about the actor. The guarantee is non-repudiation. If the check passes, the named actor really did authorize the named action and cannot credibly deny it — short of claiming their credential was stolen. This is the mechanism behind supervisor sign-off on large wire transfers, doctors' electronic prescriptions for controlled drugs, chip-and-PIN card payments, legally binding e-signatures, and signed code commits in regulated software. Attest when the action happens, verify at audit time, and the answer comes from the records rather than from anyone's word.

---

## Intent

WHY:
A regulated action has to answer one question from the records: *who authorized this?* A logged `actor` field answers it procedurally — it is the system's word about the past, written by the party under audit. A proof answers it structurally: the actor's own credential produced an artifact that binds that actor to that action, and anyone holding the record and the registry's public material can check it without asking the system to vouch for itself. This atom is that binding and nothing else. It does not authenticate the actor, does not decide whether the actor was permitted, does not manage the credential, and does not know what the action is; it records that this actor attested to this action at this time, in a form a verifier can re-check later. The contract it clears is non-repudiation, and it is conditional by construction — on the credential not being compromised, which is a fact the records cannot carry and a composing pattern must reinterpret.

## Structure

### Identity model

```text
Identity 1: The atom MUST identify an attestation by the attestation_id.
Identity 2: The host MUST allocate an attestation_id at the atom's seam.
Identity 3: The transition MUST NOT allocate an attestation_id.
Identity 4: The business caller MUST NOT supply an attestation_id.
Identity 5: The atom MUST NOT reuse an attestation_id.
Identity 6: The atom MUST NOT identify an attestation by the action_ref.
Identity 7: The atom MUST NOT identify an attestation by the actor_ref.
Identity 8: The atom MUST NOT identify an attestation by attested_at.
Identity 9: Two attestations over one action by one actor MUST carry two attestation_ids.
```

Terms › `attestation`: one recorded binding of an actor to an action — an [Attestation].

Terms › `attestation_id`: the opaque value naming one attestation — an [Attestation Id].

Terms › `action_ref`: the opaque reference naming what was attested — an [Action Ref]; the host owns what an action is.

Terms › `actor_ref`: the opaque reference naming who attested — an [Actor Ref]; the actor registry is a separate concept.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading, the attestation_id and the cryptographic material here.

Terms › `transition`: the atom's evaluation of one call against the attestation store, as `execution-contract.md` §Logic confinement declares it.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

WHY:
Identity by action and actor together would collapse the re-attestation the regime produces — a retry after a partial failure, a second proof after a key rotation, a step in a multi-action sequence — and identity by time would lose two concurrent attestations (Identity 6–9). One attestation, one id, is what makes per-event audit reconstruction tractable.

### State

```text
State 1: EVERY attestation MUST stand in attested.
State 2: The atom MUST NOT offer a transition out of attested.
State 3: EVERY attestation MUST carry attestation_id, action_ref, actor_ref, proof and attested_at.
State 4: The atom MUST NOT store the credential.
State 5: The atom MUST NOT offer a revocation surface.
State 6: The atom MUST NOT offer a deletion surface.
State 7: The atom MUST NOT hold the actor registry's public material.
```

Terms › `attested`: the atom's one state — recorded, and nothing further to become.

Terms › `proof`: the cryptographic or procedural artifact binding the actor_ref to the action_ref — a [Proof]; a signature, a message authentication code, a card-bound proof, a qualified electronic signature, a witnessed approval.

Terms › `attested_at`: the wall-time instant the attestation was recorded, stamped from the injected now — an [Attested At].

Terms › `credential`: the private material the actor uses to produce the proof — a [Credential]; consumed at [Attest] and never stored.

Terms › `public material`: what the actor registry holds for an actor_ref and a verifier reads.

Terms › `durability mechanism`: a write-ahead log, or another mechanism making a committed write survive a crash.

Terms › `attestation field`: `attestation_id` | `action_ref` | `actor_ref` | `proof` | `attested_at`.

WHY:
One state and no way out: an attestation that could be revoked would prove nothing, because the party who wanted the attribution undone is the party who would revoke it. Reinterpretation under a compromised credential is real and is a Compromise Disclosure pattern's *(forthcoming)* — it writes new records rather than editing old ones (State 2, State 5, Non-goal 9). The credential is consumed and never stored: an atom holding actors' private material would be the highest-value target in the deployment (State 4).

### Operations

```
attest(action_ref, actor_ref, credential) → attestation_id | rejected(invalid-request | invalid-credential | storage-failure)
verify(attestation_id) → verified | failed-verification(proof-invalid | actor-unknown-in-registry | registry-unavailable) | not-known
```

```text
Operation 1: [Attest] MUST compute the proof over the action_ref and the actor_ref from the credential.
Operation 2: [Attest] MUST record EXACTLY ONE attestation per successful call.
Operation 3: [Attest] MUST stamp attested_at from the injected now.
Operation 4: [Attest] MUST answer attestation_id.
Operation 5: [Attest] MUST consume the credential.
Operation 6: IF action_ref is blank THEN [Attest] MUST answer invalid-request.
Operation 7: IF actor_ref is blank THEN [Attest] MUST answer invalid-request.
Operation 8: IF the credential is blank THEN [Attest] MUST answer invalid-request.
Operation 9: IF the credential fails against the actor's public material THEN [Attest] MUST answer invalid-credential.
Operation 10: IF the attestation store refuses the write THEN [Attest] MUST answer storage-failure.
Operation 11: [Attest] MUST NOT record a partial attestation.
Operation 12: [Attest] MUST NOT alter a recorded attestation.
Operation 13: [Attest] MUST NOT read the action's content.
Operation 14: [Verify] MUST answer EXACTLY ONE OF verified, failed-verification, not-known.
Operation 15: IF the attestation NOT EXISTS THEN [Verify] MUST answer not-known.
Operation 16: IF the attestation EXISTS AND registry answer = unknown-actor THEN [Verify] MUST answer actor-unknown-in-registry.
Operation 17: IF the attestation EXISTS AND registry answer = unreachable THEN [Verify] MUST answer registry-unavailable.
Operation 18: IF registry answer = material AND proof check = failed THEN [Verify] MUST answer proof-invalid.
Operation 19: [Verify] MUST answer verified ONLY IF proof check = held.
Operation 20: [Verify] MUST NOT write.
Operation 21: [Verify] MUST read the actor registry's public material for the actor_ref.
Operation 22: The host MUST read the clock at the atom's seam.
Operation 23: The host MUST supply the cryptographic material at the atom's seam.
Operation 24: The transition MUST NOT read a clock.
Operation 25: The transition MUST NOT mint entropy.
Operation 26: The business caller MUST NOT supply attested_at.
```

Terms › `registry answer`: `material` | `unknown-actor` | `unreachable` — what the actor registry gives a verifier for an actor_ref.

Terms › `proof check`: `held` | `failed` — the recorded proof run against the recorded action_ref and actor_ref under the registry's current public material.

Terms › `verification set`: the attestation's own fields together with the registry's public material for the actor_ref — and, where the credential mechanism embeds it, the revocation status the proof carries (Revocation status 1, Revocation status 2); everything [Verify] is allowed to read, and nothing else.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the attestation store |
|---|---|---|---|
| [Attest] | refs and credential present, credential validates, store accepts | `attestation_id` | one attestation lands in [Attested] (Operation 1, Operation 2) |
| [Attest] | blank `action_ref`, `actor_ref` or credential | [Invalid Request] | none (Operation 6–8) |
| [Attest] | credential fails against the actor's public material | [Invalid Credential] | none (Operation 9) |
| [Attest] | store refuses the write | [Storage Failure] | none — no partial record (Operation 10, Operation 11) |
| [Verify] | no attestation under that id | [Not Known] | none — the call reads (Operation 15, Operation 20) |
| [Verify] | attestation found, registry holds no material for the actor | [Actor Unknown In Registry] | none (Operation 16) |
| [Verify] | attestation found, registry unreachable | [Registry Unavailable] | none (Operation 17) |
| [Verify] | material in hand, proof does not hold | [Proof Invalid] | none (Operation 18) |
| [Verify] | material in hand, proof holds | [Verified] | none (Operation 19) |

WHY:
The four verify outcomes are kept apart by their conditions, not by the order the rules sit in (`GRACE-lang.md` Hard invariant 15): `not-known` is an id miss; `actor-unknown-in-registry` is missing actor material and may be permanent; `registry-unavailable` is transient and worth retrying; `proof-invalid` is a proof that exists and fails — after a key rotation, or under forgery. A deployment that collapses these into a boolean has thrown away the difference between *we cannot check right now* and *this does not check out* (Operation 15–19). Verification reads the registry's view, which is why a rotation can turn a verified attestation into a failing one unless the registry keeps historical material — the registry's property, not the atom's (Non-goal 3, Registry view 1–3).

### Invariants

- **Invariant 1 — Attestation immutability.**
  ```text
  Invariant 1.1: EVERY attestation field of a recorded attestation MUST NOT change.
  ```
- **Invariant 2 — Action binding.**
  ```text
  Invariant 2.1: A recorded proof MUST verify against the recorded action_ref.
  Invariant 2.2: A proof produced for another action MUST NOT verify against the attestation.
  ```
- **Invariant 3 — Actor binding.**
  ```text
  Invariant 3.1: A recorded proof MUST verify against the recorded actor_ref under the registry's public material.
  Invariant 3.2: A proof produced by another actor MUST NOT verify against the attestation.
  ```
- **Invariant 4 — Id stability.**
  ```text
  Invariant 4.1: [Attest] MUST set the attestation_id.
  Invariant 4.2: An attestation_id MUST NOT change.
  ```
- **Invariant 5 — No id reuse.**
  ```text
  Invariant 5.1: Two attestations MUST NOT share an attestation_id.
  ```
- **Invariant 6 — Self-containment.**
  ```text
  Invariant 6.1: [Verify] MUST consult the verification set.
  Invariant 6.2: [Verify] MUST NOT consult the host's state.
  Invariant 6.3: [Verify] MUST NOT consult a source outside the verification set.
  ```
  WHY: a mechanism that embeds revocation status in the proof keeps verification self-contained; one that sends the verifier to a live revocation service weakens the invariant, which is a mechanism choice the deployment makes (Revocation status 1–4).
- **Invariant 7 — Verification consistency under fixed registry state.**
  ```text
  Invariant 7.1: Two verifications of one attestation under one registry view MUST answer alike.
  ```
- **Invariant 8 — Non-repudiation contract.**
  ```text
  Invariant 8.1: A verified attestation MUST bind the actor_ref to the action_ref at attested_at ONLY IF the credential was uncompromised at attested_at.
  Invariant 8.2: The atom MUST NOT reinterpret an attestation under a later compromise.
  ```
  WHY: the contract is conditional on credential integrity, and the condition is a fact the records cannot carry. A compromise is disclosed by new records that reinterpret old ones — never by mutating an attestation, which would make the store itself unreliable (Invariant 8.2, Non-goal 9).
- **Invariant 9 — Attestation durability.**
  ```text
  Invariant 9.1: The atom MUST NOT delete an attestation.
  Invariant 9.2: The attestation set MUST NOT shrink.
  Invariant 9.3: A storage-failure MUST NOT leave a partial attestation.
  ```

Action binding and actor binding give the *attribution* property — *who authorized this?* answered structurally. Immutability and self-containment give *survivability* — an attestation stays verifiable independent of the system that recorded it. The non-repudiation contract names the bar the atom is built to clear, and its condition.

## Examples

The same atom, five regulated domains, identical mechanic.

### Banking — wire transfer authorization

A teller initiates a $50,000 wire. Bank policy requires supervisor approval for wires over $10,000. The supervisor reviews and attests — `attest(wire_w91, supervisor_s12, supervisor_credential) → attestation_a44`. The attestation is stored alongside the wire record. Six months later, an internal auditor reviewing the day's high-value wires queries `verify(a44)` and receives `verified` — confirming supervisor s12 authorized wire w91 at the recorded time, without trusting the teller's account of the conversation that preceded it.

### Healthcare — electronic prescription for a controlled substance

A physician writes a Schedule II prescription. DEA (US Drug Enforcement Administration) Electronic Prescriptions for Controlled Substances (EPCS) regulations require two-factor cryptographic attestation. The physician's EHR (Electronic Health Record — the digital patient chart system) computes `attest(rx_r37, dr_park, dr_park_credential)` using the physician's smart-card-bound credential and a second factor. The prescription transmits to the pharmacy with `attestation_a91`. The pharmacy calls `verify(a91)` before dispensing; `verified` → fill. Two years later, during a DEA audit, the same verification proves Dr. Park authorized that specific prescription on that specific date.

### Payments — chip-and-PIN transaction

A cardholder taps a chip card at a terminal and enters their PIN. The card produces a cryptographic attestation: `attest(transaction_t883, card_c41, card_credential)`. The terminal forwards the attestation with the transaction. The issuer calls `verify` before authorizing the charge. Months later, the cardholder disputes the charge as unauthorized; the issuer produces `attestation` and re-verifies. `verified` → the card was physically present and the correct PIN was entered, shifting liability to the cardholder per scheme rules. `failed-verification` → the dispute is upheld.

### Legal — qualified electronic signature on a contract

Two parties sign a contract via a qualified electronic signature service. Each invokes `attest(contract_c12, party_ref, qualified_signature_credential)` using credentials issued by a qualified trust service provider. Two attestations are stored alongside the contract. Any future party — opposing counsel, mediator, court — invokes `verify` on either attestation. Under eIDAS Regulation (Electronic Identification, Authentication and Trust Services — the EU regulation governing electronic signatures and identity), qualified electronic signatures carry the same legal effect as handwritten signatures, and the verification result is admissible evidence of authorship.

### Source control — signed commits in regulated software

A developer at an FDA-cleared (US Food and Drug Administration — the federal agency regulating drugs and medical devices) medical-device company pushes a commit signed with their hardware-key-backed credential. The version-control system records the attestation: `attest(commit_c44a, dev_smith, smith_credential) → attestation_a17`. CI infrastructure calls `verify(a17)` before allowing merge into the release branch. During an FDA software-of-unknown-provenance audit, the auditor walks the release branch and re-verifies every commit's attestation. SOX (Sarbanes-Oxley Act — US financial reporting law)-scoped financial systems and Common Criteria evaluated products follow the same pattern.

The mechanic is identical across all five. What differs: the credential mechanism (smart card, software key, qualified signature instrument, hardware token, chip-card secure element), the verification frequency (every action vs. on dispute vs. on audit), the regulatory consequence of [Failed Verification], and the composing patterns active around it (two-factor for prescriptions, witness signatures for some legal contracts, MFA — Multi-Factor Authentication, requiring two or more independent proofs of identity — for high-value wires).

### Rejection paths

**[Verify] → [Failed Verification] ([Proof Invalid]):** An auditor reviewing a batch of wire authorizations calls `verify(attestation_a17)`. The actor's key has been rotated since the [Attestation] was recorded, and the registry's current public material for `actor_ref: supervisor_s12` no longer matches the stored [Proof]. The atom returns `failed-verification(proof-invalid)`. The auditor notes the failure; the composing audit workflow escalates for manual review. The [Attestation] record is unchanged — Invariant 1 prevents modification; the failure is a verification-time result, not a record defect.

**[Verify] → [Not Known]:** A composing pattern references an [Attestation Id] that was never written (a partial-failure scenario where [Attest] returned [Storage Failure] and the composing pattern cached the id before confirming success). `verify(attestation_a_unknown)` returns `not-known` — the id is not in the attestation store. This is structurally distinct from [Failed Verification]: the id does not reference any [Attestation]. The composing pattern must treat [Not Known] as a missing record (requiring re-attestation) rather than a verification failure.

**[Attest] → [Invalid Credential]:** A supervisor approves a high-value wire using a [Credential] that was rotated out earlier that day. `attest(wire_w55, supervisor_s12, rotated_credential)` → the [Credential] fails to validate against the registry's current public material for `supervisor_s12`; the atom returns `rejected(invalid-credential)`. No [Attestation] is recorded — [Invalid Credential] is a guard rejection that fails before any store write (see Decision points); the composing workflow prompts re-attestation with the current [Credential].

### Regulated adversarial scenarios

Three scenarios the atom must survive in regulated contexts:

- **Regulator audit.** A regulator asks *"who confirmed commitment c41?"* The auditor follows the commitment record to its [Attestation Id], calls [Verify], and reads [Actor Ref] from the verified [Attestation]. The verification is performed against stored fields and registry public material — not against developer testimony, log integrity, or system trust. Invariants 2 and 3 are the structural answer.
- **Disputed transaction.** An actor claims they did not authorize an action. The investigator retrieves the [Attestation] and calls [Verify]. If [Verified], the [Proof] binds the named actor to the named action at [Attested At] (Invariant 8). The actor cannot plausibly deny it without claiming credential compromise — an out-of-band investigation governed by a separate Compromise Disclosure pattern. If [Failed Verification], the dispute is upheld and the system's record is corrected.
- **Compromised credential discovered.** A [Credential] is later determined to have been compromised before some date. The atom does *not* retroactively invalidate attestations made with that [Credential] — Invariant 1 forbids modifying recorded attestations, and Invariant 8 is conditional on credential integrity. Reinterpretation of attestations made during the compromise window belongs to a Compromise Disclosure composing pattern, which produces *new* records that reframe the previously-verified attestations as untrustworthy. The atom's attestation store remains immutable; the meaning of its records changes via composition, not via mutation.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the attestation store and the actor registry's public material, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```text
Check 1.1: An auditor MUST reconstruct EVERY attestation from the attestation's stored fields (Invariant 1.1, State 3).
Check 1.2: An auditor MUST NOT need state beyond those fields and the registry's public material (Invariant 6.1, Invariant 6.2).
Check 2.1: An auditor MUST verify an attestation without privileged access to the system (Invariant 6.1, Operation 21).
Check 3.1: An auditor MUST confirm that the proof holds against the recorded action_ref and against no other action (Invariant 2.1, Invariant 2.2).
Check 3.2: An auditor MUST confirm that the proof holds against the recorded actor_ref and against no other actor (Invariant 3.1, Invariant 3.2).
Check 4.1: An auditor MUST read verified, failed-verification and not-known as three distinct answers (Operation 14).
Check 4.2: An auditor MUST read proof-invalid, actor-unknown-in-registry and registry-unavailable as three distinct reasons (Operation 16, Operation 17, Operation 18).
Check 5.1: An auditor MUST identify which composing patterns a deployment wired in (Composition note 1).
```

NOTE: EVERY check names the rule the check tests. The bar is the regulator's question — *can you prove who authorized this action?* — never the developer's intuition.

## Non-goals

```text
Non-goal 1: The atom MUST NOT register an actor.
Non-goal 2: The atom MUST NOT retire an actor.
Non-goal 3: A deployment MUST compose an actor-registry pattern for the actor's lifecycle.
Non-goal 4: The atom MUST NOT authenticate an actor.
Non-goal 5: The atom MUST NOT decide whether an actor was permitted to take an action.
Non-goal 6: A deployment needing permission MUST compose [Permissions](./permissions.md).
Non-goal 7: The atom MUST NOT manage a credential.
Non-goal 8: The atom MUST NOT record two actors on one attestation.
Non-goal 9: The atom MUST NOT invalidate an attestation under a later compromise.
Non-goal 10: The atom MUST NOT detect a rewrite of the attestation store.
Non-goal 11: A deployment needing a tamper-evident store MUST compose [Tamper Evidence](./tamper-evidence.md).
Non-goal 12: The atom MUST NOT vouch for the clock.
Non-goal 13: The atom MUST NOT bind the action's content.
Non-goal 14: A host whose action content is mutable MUST bind an immutable reference.
Non-goal 15: The atom MUST NOT carry an actor_ref across trust domains.
```

WHY:
Authentication produces the credential this atom consumes, and authorization asks a different question entirely — *could* they, rather than *did* they; the atom answers the second and composes for the first (Non-goal 4–6). One attestation is one actor's binding: witness signatures, m-of-n approvals and dual control compose a Witness pattern *(forthcoming)*, which is a pattern over attestations rather than a bigger attestation (Non-goal 8). The store is assumed unrewritten, which is exactly what [Tamper Evidence](./tamper-evidence.md) supplies; many credential mechanisms give it as a side effect and the atom requires none of them (Non-goal 10, Non-goal 11). Binding a mutable action is the quiet failure: the proof stays valid while the content it was supposed to attest to changes underneath, which is why the host binds a content hash or composes a Content Lock pattern *(forthcoming)* (Non-goal 13, Non-goal 14).

Where the atom breaks down: when authorization cannot be reduced to one actor — truly anonymous attestation in a regulated context is a contradiction; when the credential mechanism cannot produce a verifiable proof — a shared secret anyone holding it could forge with; when the deployment has no actor registry a verifier can consult.

## Edge cases

### The registry's view moves

```text
Registry view 1: A rotation of an actor's public material MAY turn a verified attestation into a failing one.
Registry view 2: The actor registry MUST own whether historical public material is kept.
Registry view 3: A deployment whose old attestations must keep verifying MUST retain the historical public material.
```

WHY:
Audit Trail's long-lived attestations are the case: an attestation made years ago verifies under the key of its day, and a registry that keeps only current material silently converts every one of them into `proof-invalid` — indistinguishable, to a reader, from tampering (Registry view 3).

### Revocation status at verify time

```text
Revocation status 1: A credential mechanism MAY carry the revocation status inside the proof.
Revocation status 2: A mechanism carrying the revocation status inside the proof MUST keep [Verify] self-contained.
Revocation status 3: A deployment MUST NOT read a mechanism resting on a live revocation service as self-contained.
Revocation status 4: The deployment MUST own the mechanism choice.
```

WHY:
Stapled status and short-lived credentials both satisfy Invariant 6.1; a live status query at verify time introduces the out-of-band dependency the invariant exists to exclude, and the honest thing is to say so in the deployment's own record rather than to claim the invariant anyway (Revocation status 3).

### Attestation store durability

```text
Attestation durability 1: [Attest] MUST write EXACTLY ONE record per successful call.
Attestation durability 2: The implementation MUST own durability across a crash.
Attestation durability 3: A high-assurance deployment MUST compose a durability mechanism.
Attestation durability 4: A storage-failure MUST agree with the absence of a persisted record.
```

### Verification caching

```text
Verification caching 1: An implementation MAY cache a verification result.
Verification caching 2: An implementation MUST NOT cache a verification result across two registry views.
```

WHY:
[Verify] is deterministic under a fixed registry view (Invariant 7.1), so a cache is sound exactly while the registry does not move — and a cache that outlives a rotation or a revocation reports *verified* for an attestation the registry would now fail.

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST carry the attestation_id alongside the record the attestation attributes.
Composition note 3: A composing pattern MUST trust a recorded actor field ONLY IF [Verify] answers verified.
Composition note 4: A composing pattern MUST own the retention of an attestation.
Composition note 5: This atom's invariant numbers MUST stand as a frozen contract surface.
```

WHY:
This atom is the attribution surface the rest of the corpus rests on rather than re-inventing: [Provisional Commitment](./provisional-commitment.md) attests each transition, [Event Log](./event-log.md) carries an attestation_id in the payload, [Permissions](./permissions.md) pairs every grant and revoke with one — formalized as [Attributed Permissions Admin](../compositions/attributed-permissions-admin.md) — and [Authenticated Actor](../compositions/authenticated-actor.md) wires this atom to [Credential](./credential.md) under one principal, owning the revocation cascade and the namespace binding neither atom specifies alone. The regulated-audit stack is [Event Log](./event-log.md), this atom, [Retention Window](./retention-window.md) and [Tamper Evidence](./tamper-evidence.md), wired by [Audit Trail](../compositions/audit-trail.md), which cites this atom's Invariants 1, 6 and 9 by number — so these numbers are a frozen contract surface (Composition note 5), additive growth is forward-compatible, and the rule against renumbering is the grammar's (`GRACE-lang.md` Hard invariant 26). Forthcoming: Actor Registry, Compromise Disclosure, Witness, Trusted Timestamping.

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment (also: a high-assurance deployment); a composing pattern (also: a pattern, a writer); a business caller; a verifier; an auditor; an actor; the actor registry; the attestation store; a credential mechanism (also: a mechanism); an attestation; a rotation; a proof.

Terms › `records`: `attestation` — one binding, carrying `attestation_id`, `action_ref`, `actor_ref`, `proof` and `attested_at`.

Terms › `record verbs`: identify, allocate, supply, reuse, carry, stand, offer, store, hold, compute, record, stamp, answer, consume, alter, read, mint, write, verify, consult, set, change, share, bind, reinterpret, delete, shrink, leave, register, retire, compose, authenticate, decide, manage, invalidate, detect, vouch, turn, own, retain, keep, rest, cache, reconstruct, need, confirm, declare, trust, renumber, add, agree, fail.

Terms › `value sets`: attest answers = attestation_id | rejected(invalid-request | invalid-credential | storage-failure). verify answers = verified | failed-verification(proof-invalid | actor-unknown-in-registry | registry-unavailable) | not-known. `registry answer` = material | unknown-actor | unreachable. `proof check` = held | failed. `attestation field` = attestation_id | action_ref | actor_ref | proof | attested_at.

Terms › `bounds`: empty.

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-12); `uncompromised` — a credential no disclosure names as compromised at or before the instant in question.

Terms › `terms`: `now`, `verification set`, `durability mechanism`, `attestation`, `attestation_id`, `action_ref`, `actor_ref`, `seam`, `transition`, `business caller`, `attested`, `proof`, `attested_at`, `credential`, `public material`, `attestation field`, `registry answer`, `proof check`.

#### Attestation

The record this atom defines: a permanent, verifiable binding of one action to the actor who authorized it. It carries its [Attestation Id], [Action Ref], [Actor Ref], [Proof], and [Attested At]; nothing about it changes once recorded, and the atom offers no surface to revoke or modify it.

Kind: Type

#### Attest

The behavior a composing pattern invokes at action time to record a new [Attestation]. It consumes the supplied [Credential] to compute the [Proof], binds the [Actor Ref] to the [Action Ref], stamps [Attested At], and returns the [Attestation Id]. It always creates a new record — it never modifies an existing one — and never persists the [Credential].

Kind: Operation

#### Verify

The read-only behavior an auditor or composing pattern invokes to confirm a recorded [Attestation], by id. It re-checks the stored [Proof] against the recorded [Action Ref] and [Actor Ref] using the actor registry's public material, and returns [Verified], [Failed Verification], or [Not Known]. It changes nothing.

Kind: Operation

#### Action Ref

The opaque reference to *what* is being attested — the action the [Attestation] binds. The atom does not interpret it; the composing pattern defines what an action is and how to reference it. Set on [Attest], immutable thereafter.

Kind:     Field
Field of: Attestation
Projects: action_ref

#### Actor Ref

The opaque reference to *who* is attesting — the actor the [Attestation] binds. The actor registry that holds the actor's public material is a separate concept. Set on [Attest], immutable thereafter.

Kind:     Field
Field of: Attestation
Projects: actor_ref

#### Attestation Id

The opaque, immutable identity of an [Attestation], host-allocated at the I/O seam on [Attest] and never reused. The [Action Ref], [Actor Ref], [Proof], and [Attested At] are properties of the [Attestation], not its identity.

Kind:     Field
Field of: Attestation
Projects: attestation_id

#### Proof

The cryptographic or procedural artifact that binds the [Actor Ref] to the [Action Ref] — a signature, a MAC, a smart-card-bound attestation, a qualified electronic signature. Computed by [Attest] from the [Credential] and the injected cryptographic material, stored on the [Attestation], and the thing [Verify] re-checks. Set on [Attest], immutable thereafter.

Kind:     Field
Field of: Attestation
Projects: proof

#### Attested At

The wall-time the [Attestation] was recorded, stamped from the host-injected clock on [Attest]. Immutable thereafter. The non-repudiation contract binds the actor to the action *at* this time.

Kind:     Field
Field of: Attestation
Projects: attested_at

#### Credential

The private material the actor supplies to [Attest] to produce the [Proof]. It is *consumed* per call — used to compute the [Proof] and then discarded — and never stored under this name (or any name) by the atom. It is the only caller-supplied secret.

Kind:         Parameter
Parameter of: Attest
Projects:     credential

#### Attested

The atom's single stable state: an [Attestation] that has been recorded. There are no transitions out of it — the atom has no surface to revoke, invalidate, or modify an [Attestation] once recorded.

Kind:      Member
Member of: the attestation state
Role:      Outcome

#### Verified

The outcome [Verify] returns when the stored [Proof] checks out against the recorded [Action Ref] and [Actor Ref] under the registry's current public material. It is the [Verified] half of the non-repudiation contract: the named actor authorized the named action (conditional on credential integrity).

Kind:      Member
Member of: the Verify outcome
Role:      Outcome
Projects:  verified

#### Failed Verification

The outcome [Verify] returns when the [Attestation] exists but does not verify, carrying a reason — [Proof Invalid], [Actor Unknown In Registry], or [Registry Unavailable]. Distinct from [Not Known], which is a lookup miss.

Kind:      Member
Member of: the Verify outcome
Role:      Outcome
Projects:  failed-verification

#### Not Known

The outcome [Verify] returns when the supplied [Attestation Id] references no recorded [Attestation] — a lookup miss, not a verification failure. A composing pattern treats it as a missing record (requiring re-attestation), not as a denial of authorship.

Kind:      Member
Member of: the Verify outcome
Role:      Outcome
Projects:  not-known

#### Proof Invalid

The [Failed Verification] reason returned when the stored [Proof] does not check out against the recorded [Action Ref] and [Actor Ref] under the registry's current public material — for example, after the actor's key was rotated.

Kind:      Member
Member of: the Failed Verification reason
Role:      Outcome
Projects:  proof-invalid

#### Actor Unknown In Registry

The [Failed Verification] reason returned when the actor registry cannot return public material for the recorded [Actor Ref] — because the actor has been deleted from the registry. May be permanent.

Kind:      Member
Member of: the Failed Verification reason
Role:      Outcome
Projects:  actor-unknown-in-registry

#### Registry Unavailable

The [Failed Verification] reason returned when the actor registry is unreachable at verify time — a transient, retryable condition, distinct from [Actor Unknown In Registry].

Kind:      Member
Member of: the Failed Verification reason
Role:      Outcome
Projects:  registry-unavailable

#### Invalid Request

The refusal [Attest] returns when [Action Ref], [Actor Ref], or [Credential] is null or empty. A guard rejection that fails before any store write; no [Attestation] is recorded.

Kind:      Member
Member of: the Attest rejection
Role:      Outcome
Projects:  invalid-request

#### Invalid Credential

The refusal [Attest] returns when the supplied [Credential] does not validate against the actor registry's public material for the [Actor Ref]. A guard rejection that fails before any store write; no [Attestation] is recorded.

Kind:      Member
Member of: the Attest rejection
Role:      Outcome
Projects:  invalid-credential

#### Storage Failure

The refusal [Attest] returns when the store write fails after the [Credential] validates. No partial [Attestation] is recorded — the caller must treat it as definitive and re-attest with a fresh [Credential].

Kind:      Member
Member of: the Attest rejection
Role:      Outcome
Projects:  storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Attestation]: #attestation
[Attest]: #attest
[Verify]: #verify
[Action Ref]: #action-ref
[Actor Ref]: #actor-ref
[Attestation Id]: #attestation-id
[Proof]: #proof
[Attested At]: #attested-at
[Credential]: #credential
[Attested]: #attested
[Verified]: #verified
[Failed Verification]: #failed-verification
[Not Known]: #not-known
[Proof Invalid]: #proof-invalid
[Actor Unknown In Registry]: #actor-unknown-in-registry
[Registry Unavailable]: #registry-unavailable
[Invalid Request]: #invalid-request
[Invalid Credential]: #invalid-credential
[Storage Failure]: #storage-failure

---

## Standards references

Actor Identity is a foundational compliance primitive with deep regulatory anchoring:

- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-63-3 (Digital Identity Guidelines)** — Identity Assurance Levels (IAL), Authenticator Assurance Levels (AAL), Federation Assurance Levels (FAL) — graded measures of how strongly identity, authentication, and federation are established. The atom's credential-consumed-not-stored discipline and verification self-containment correspond to NIST's authenticator and verifier requirements.
- **eIDAS Regulation (EU 910/2014)** — qualified, advanced, and basic electronic signatures. Qualified electronic signatures carry the same legal effect as handwritten signatures across the EU; the atom's non-repudiation contract is the operational form.
- **FIPS 186-4 / FIPS 186-5 (Federal Information Processing Standards — mandatory US government computing standards; here the Digital Signature Standard)** — cryptographic foundation for asymmetric attestation. The atom is mechanism-neutral but FIPS 186 is the canonical credential-mechanism anchor.
- **ISO/IEC 27001 §A.9 (Access Control) and §A.12.4 (Logging and Monitoring)** — the International Organization for Standardization / International Electrotechnical Commission information-security standard; actor attribution as an access-control and audit requirement.
- **21 CFR (Code of Federal Regulations — the codification of US federal agency rules) Part 11 (FDA Electronic Records and Electronic Signatures)** — for healthcare, pharmaceuticals, and medical devices: requires electronic signatures to be uniquely attributable to one individual, with cryptographic or procedural binding that resists repudiation.
- **HIPAA (US Health Insurance Portability and Accountability Act) §164.312(d) (Person or Entity Authentication)** — verification that a person or entity seeking access is the one claimed.
- **DEA EPCS (21 CFR §1311)** — Electronic Prescriptions for Controlled Substances: two-factor cryptographic attestation requirements.
- **GDPR (EU General Data Protection Regulation) Article 32 (Security of Processing)** — names "ensuring the ongoing confidentiality, integrity, availability and resilience of processing systems and services"; non-repudiation is a recognized security property under Article 32's scope.
- **Sarbanes-Oxley §302 and §404** — officer certifications and internal control over financial reporting. Authenticated attestations on financial-system changes are §302 / §404 evidence.
- **PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for handling cardholder data) Requirement 8 (Identify and Authenticate Access)** — for payment systems handling cardholder data.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of composing authentication, authorization, registry, witness, and compromise concepts as separate atoms.
- **Eiffel's design-by-contract** — preconditions on `attest`; named rejection and verification reasons.
- **Public-key cryptography literature** (Diffie-Hellman, RSA — Rivest-Shamir-Adleman, ECDSA — Elliptic Curve Digital Signature Algorithm, EdDSA — Edwards-curve Digital Signature Algorithm; standard digital-signature schemes) — the foundational mechanism for verifiable proofs of authorship.
- **Non-repudiation literature in computer security** (Zhou and Gollmann, ISO/IEC 13888) — the formal framing of non-repudiation services as distinct from authentication.

---

## Status

`grounded on Final Critique 4 — 2026-06-18` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-06-18
formal: not applicable — vote no 2026-06-03
last gate: 2026-06-18 — Final Critique 4, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/actor-identity.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, the verify precedence carried by each rule's own condition rather than by the order the rules sit in, the nine invariant numbers frozen exactly as Audit Trail cites them, Generation acceptance moved ahead of Non-goals as `spec-format.md` requires, Non-goals and Edge cases as two sections, the case table kept beside the rules. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail cites this atom's Invariants 1, 6 and 9 (`tools/grace/cites.py --into actor-identity`).

NOTE: End of Actor Identity.
