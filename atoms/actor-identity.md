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

Actor Identity answers one question: "who authorized this action, and can you prove it?" It works through attestations — permanent records that tie a specific person or system to a specific action by way of a proof. A proof is a tamper-resistant artifact, computed from the actor's private credential, that anyone can later check without needing the credential itself. Creating an attestation consumes the credential to produce the proof and then throws the credential away; only the proof is kept. Checking one is purely read-only. Given an attestation's identifier, the system re-checks the stored proof against the recorded action and actor, using only public information about the actor. The guarantee is non-repudiation. If the check passes, the named actor really did authorize the named action and cannot credibly deny it — short of claiming their credential was stolen. This is the mechanism behind supervisor sign-off on large wire transfers, doctors' electronic prescriptions for controlled drugs, chip-and-PIN (personal identification number) card payments, legally binding e-signatures, and signed code commits in regulated software. Attest when the action happens, verify at audit time, and the answer is provable.

---

## Intent

WHY:
A regulated action has to answer one question provably: *who authorized this?* A logged `actor` field answers it procedurally — it is the system's word about the past, written by the party under audit. A proof answers it structurally: the actor's own credential produced an artifact that binds that actor to that action, and anyone holding the record and the registry's public material can check it. This atom is that binding and nothing else. It does not authenticate the actor, does not decide whether the actor was permitted, does not manage the credential, and does not know what the action is; it records that this actor attested to this action at this time, in a form a verifier can re-check later. The contract it clears is non-repudiation, and it is conditional by construction — on the credential not being compromised, which is a fact the records cannot carry and a composing pattern must reinterpret.

## Structure

### Identity model

```
Identity 1: The atom MUST identify an attestation by the attestation id.
Identity 2: The host MUST allocate an attestation id at the atom's seam.
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
Identity 4: The business caller MUST NOT supply an attestation id.
Deleted: Identity 5. Invariant 5.1 owns it.
Identity 6: The atom MUST NOT identify an attestation by the action reference.
Identity 7: The atom MUST NOT identify an attestation by the actor reference.
Identity 8: The atom MUST NOT identify an attestation by attestation instant.
Deleted: Identity 9. Invariant 5.1 owns it.
```

Term attestation: one recorded binding of an actor to an action — an [Attestation].

Term attestation id: the opaque value naming one attestation — an [Attestation Id].

Term action reference: the opaque reference naming what was attested — an [Action Reference]; the host owns what an action is.

Term action content: what the action an action reference names says or carries; the host owns it.

Term actor reference: the opaque reference naming who attested — an [Actor Reference]; the actor registry is a separate concept.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the attestation id, the cryptographic material and the registry answer here.

Term transition: the atom's evaluation of one call against the attestation records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

NOTE: open 2026-10-22-a — Term seam, Term transition, Term business caller and Term now cite the section titled Logic Confinement Principle in `execution-contract.md`, which declares none of them, and State 2 reads a transition as a move out of a state.

### State

```
State 1: EVERY attestation MUST stand in attested.
State 2: The atom MUST NOT offer a transition out of attested.
State 3: EVERY attestation MUST carry attestation id, action reference, actor reference, proof and attestation instant.
State 4: The atom MUST NOT store the credential.
State 5: The atom MUST NOT offer a revocation surface.
State 6: The atom MUST NOT offer a deletion surface.
State 7: The atom MUST NOT hold the actor registry's public material.
```

Term attested: the atom's one state — recorded, and nothing further to become.

Term proof: the cryptographic artifact binding the actor reference to the action reference, checked under the public material and never under the credential — a [Proof]; a signature, a card-bound proof, a qualified electronic signature.

Term attestation instant: the wall-time instant the attestation was recorded, stamped from the injected now — an [Attestation Instant].

Term credential: the private material the actor uses to produce the proof — a [Credential]; consumed at [Attest] and never stored.

Term public material: what the actor registry holds for an actor reference and a verifier reads — the current material, and any historical material the registry keeps (Registry view 2).

Term current material: the public material in force for an actor reference now, historical material excluded — what the credential check runs a credential against.

Term attestation field: attestation id | action reference | actor reference | proof | attestation instant.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the attestation records PER Execution Contract Database 1, Execution Contract Database 3, Execution Contract Database 4, Execution Contract Database 6, Execution Contract Read 1 through 3, Execution Contract Refusal 1 and Execution Contract Conformance 9.
Capability requirement 3: The deployment MUST supply the registry answer at the seam.
Capability requirement 4: The deployment MUST supply the cryptographic material at the seam.
```

Term cryptographic material: what the deployment's credential mechanism computes at the seam and the host injects, never computed inside the transition (Execution Contract Logic confinement 1) — at [Attest], the proof, computed from the credential over the action reference and the actor reference, and the credential check; at [Verify], the proof check.

### Operations

```
attest(action_ref, actor_ref, credential)
  answers attestation_id
  refuses invalid-request | registry-unavailable | invalid-credential | storage-failure

verify(attestation_id)
  answers verified | failed-verification(verification failure) | not-known

read()
  answers every attestation
```

Term verification failure: proof-invalid | actor-unknown-in-registry | registry-unavailable — the reasons [Verify] gives for a failed verification.

```
Operation 1: [Attest] MUST record the proof the deployment supplies at the seam.
Operation 2: [Attest] MUST record EXACTLY ONE attestation per successful call.
Operation 3: [Attest] MUST stamp attestation instant from the injected now.
Operation 4: [Attest] MUST answer attestation id.
Operation 5: [Attest] MUST consume the credential.
Operation 6: IF action reference EQUALS blank THEN [Attest] MUST answer invalid-request.
Operation 7: IF actor reference EQUALS blank THEN [Attest] MUST answer invalid-request.
Operation 8: IF the credential EQUALS blank THEN [Attest] MUST answer invalid-request.
Operation 9: IF registry answer EQUALS material AND credential check EQUALS failed THEN [Attest] MUST answer invalid-credential.
Operation 10: IF the database refuses the write THEN [Attest] MUST answer storage-failure.
Deleted: Operation 11. Execution Contract Database 1 owns it.
Deleted: Operation 12. Invariant 1.1 owns it.
Operation 13: [Attest] MUST NOT read the action content.
Operation 14: [Verify] MUST answer EXACTLY ONE OF verified, failed-verification, not-known.
Operation 15: IF no attestation EXISTS for the attestation id THEN [Verify] MUST answer not-known.
Operation 16: IF an attestation EXISTS for the attestation id AND registry answer EQUALS unknown-actor THEN [Verify] MUST answer actor-unknown-in-registry.
Operation 17: IF an attestation EXISTS for the attestation id AND registry answer EQUALS unreachable THEN [Verify] MUST answer registry-unavailable.
Operation 18: IF registry answer EQUALS material AND proof check EQUALS failed THEN [Verify] MUST answer proof-invalid.
Operation 19: IF registry answer EQUALS material AND proof check EQUALS held THEN [Verify] MUST answer verified.
Operation 20: [Verify] MUST NOT write.
Operation 21: IF an attestation EXISTS for the attestation id AND registry answer EQUALS material THEN [Verify] MUST consult the public material the registry answer at the seam carries, for the attestation's actor reference.
Deleted: Operation 22. Capability requirement 1 owns it.
Deleted: Operation 23. Capability requirement 4 owns it.
Deleted: Operation 24. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 25. Execution Contract Logic confinement 3 owns it.
Operation 26: The business caller MUST NOT supply attestation instant.
Operation 27: [Read] MUST answer EVERY attestation.
Operation 28: [Read] MUST answer an attestation's attestation id, action reference, actor reference, proof AND attestation instant.
Operation 29: [Read] MUST NOT write.
Deleted: Operation 30. Operation 27 and Execution Contract Read 2 own it.
Operation 31: IF registry answer EQUALS unknown-actor THEN [Attest] MUST answer invalid-credential.
Operation 32: [Verify] MUST answer verified ONLY IF proof check EQUALS held.
Operation 33: IF registry answer EQUALS unreachable THEN [Attest] MUST answer registry-unavailable.
Deleted: Operation 34. Execution Contract Read 1 owns it.
Deleted: Operation 35. Execution Contract Refusal 1 owns it.
Operation 36: IF a revocation status the proof carries names the credential revoked THEN [Attest] MUST answer invalid-credential.
```

NOTE: watch host obligations — this atom sets no maximum length on a string input, where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one. Three postures, and the *host obligations* docket row carries the count — a watch flag states the pressure, never a census nothing reads.

Term registry answer: material | unknown-actor | unreachable — what the actor registry gives [Attest] or a verifier for an actor reference.

Term registry view: the registry answer for an actor reference and the public material the answer carries, taken together; a rotation, an outage or a removal from the registry changes the registry view.

Term credential check: held | failed — the supplied credential run against the current material the registry answer carries for the actor reference.

Term proof check: held | failed — the recorded proof run against the recorded action reference and actor reference under the public material; failed also where a revocation status the proof carries names the credential revoked (Revocation status 1).

Term verification set: the attestation's own fields together with the registry view for the actor reference and the proof check computed over them at the seam — and, where the credential mechanism embeds it, the revocation status the proof carries (Revocation status 1, Revocation status 2); everything [Verify] is allowed to read, and nothing else.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the attestation records |
|---|---|---|---|
| [Attest] | action reference, actor reference and credential not blank, registry answers material, credential validates, no revocation status the proof carries names the credential revoked, database accepts | attestation id | one attestation lands in [Attested] (Operation 1, Operation 2) |
| [Attest] | blank action reference, actor reference or credential | [Invalid Request] | none (Operation 6 through 8) |
| [Attest] | registry unreachable | [Registry Unavailable] | none (Operation 33) |
| [Attest] | registry holds no material for the actor | [Invalid Credential] | none (Operation 31) |
| [Attest] | credential fails against the actor's current material | [Invalid Credential] | none (Operation 9) |
| [Attest] | a revocation status the proof carries names the credential revoked | [Invalid Credential] | none (Operation 36) |
| [Attest] | database refuses the write | [Storage Failure] | none (Operation 10) |
| [Verify] | no attestation under that id | [Not Known] | none — the call reads (Operation 15, Operation 20) |
| [Verify] | attestation found, registry holds no material for the actor | [Actor Unknown In Registry] | none (Operation 16) |
| [Verify] | attestation found, registry unreachable | [Registry Unavailable] | none (Operation 17) |
| [Verify] | material in hand, proof does not hold, or a revocation status the proof carries names the credential revoked | [Proof Invalid] | none (Operation 18) |
| [Verify] | material in hand, proof holds | [Verified] | none (Operation 19, Operation 32) |
| [Read] | any call | every attestation, with its stored fields | none (Operation 27 through 29) |

Where two [Attest] cases hold at once, the refusal listed first on [Attest]'s refuses line answers (Execution Contract Refusal 1).

NOTE: open 2026-10-20-f — [Read] answers every attestation with no bound and no key (Operation 27, Term bounds).

### Invariants

- **Invariant 1 — Attestation immutability.**
  ```
  Invariant 1.1: EVERY attestation field of a recorded attestation MUST NOT change.
  ```
- **Invariant 2 — Action binding.**
  ```
  Invariant 2.1: A recorded proof MUST verify against the recorded action reference under the current material at attestation instant.
  Invariant 2.2: A proof produced for another action MUST NOT verify against the attestation.
  ```
- **Invariant 3 — Actor binding.**
  ```
  Invariant 3.1: A recorded proof MUST verify against the recorded actor reference under the current material at attestation instant.
  Invariant 3.2: A proof produced by another actor MUST NOT verify against the attestation.
  ```
- **Invariant 4 — Id stability.**
  ```
  Invariant 4.1: [Attest] MUST set the attestation id.
  Deleted: Invariant 4.2. Invariant 1.1 owns it.
  ```
- **Invariant 5 — No id reuse.**
  ```
  Invariant 5.1: Two attestations MUST NOT share an attestation id.
  ```
- **Invariant 6 — Self-containment.**
  ```
  Invariant 6.1: [Verify] MUST consult the verification set.
  Deleted: Invariant 6.2. Invariant 6.3 owns it.
  Invariant 6.3: [Verify] MUST NOT consult a source outside the verification set.
  ```
- **Invariant 7 — Verification consistency under fixed registry state.**
  ```
  Invariant 7.1: Two verifications of one attestation under one registry view MUST answer alike.
  ```
- **Invariant 8 — Non-repudiation contract.**
  ```
  Invariant 8.1: A verified attestation MUST bind the actor reference to the action reference at attestation instant ONLY IF the credential was uncompromised at attestation instant.
  Invariant 8.2: The atom MUST NOT reinterpret an attestation under a later compromise.
  ```
- **Invariant 9 — Attestation durability.**
  ```
  Invariant 9.1: The atom MUST NOT delete an attestation.
  Deleted: Invariant 9.2. Invariant 9.1 and Execution Contract Database 4 own it.
  Deleted: Invariant 9.3. Execution Contract Database 1 owns it.
  ```

NOTE: watch the external answer that moves (Invariant 2.1, Invariant 3.1, Invariant 7.1).

NOTE: watch the host's state (Invariant 6.2).

Action binding and actor binding give the *attribution* property — *who authorized this?* answered structurally. Immutability and self-containment give *survivability* — an attestation stays verifiable independent of the system that recorded it. The non-repudiation contract names the bar the atom is built to clear, and its condition.

## Examples

The same atom, five regulated domains, identical mechanic.

### Banking — wire transfer authorization

A teller initiates a $50,000 wire. Bank policy requires supervisor approval for wires over $10,000. The supervisor reviews and attests — `attest(wire_w91, supervisor_s12, supervisor_credential) → attestation_a44`. The attestation is stored alongside the wire record. Six months later, an internal auditor reviewing the day's high-value wires queries `verify(a44)` and receives verified — confirming supervisor s12 authorized wire w91 at the recorded time, without trusting the teller's account of the conversation that preceded it.

### Healthcare — electronic prescription for a controlled substance

A physician writes a Schedule II prescription. DEA (US Drug Enforcement Administration) Electronic Prescriptions for Controlled Substances (EPCS) regulations require two-factor cryptographic attestation. The physician's EHR (Electronic Health Record — the digital patient chart system) computes `attest(rx_r37, dr_park, dr_park_credential)` using the physician's smart-card-bound credential and a second factor. The prescription transmits to the pharmacy with `attestation_a91`. The pharmacy calls `verify(a91)` before dispensing; verified → fill. Two years later, during a DEA audit, the same verification proves Dr. Park authorized that specific prescription on that specific date.

### Payments — chip-and-PIN transaction

A cardholder taps a chip card at a terminal and enters their PIN. The card produces a cryptographic attestation: `attest(transaction_t883, card_c41, card_credential)`. The terminal forwards the attestation with the transaction. The issuer calls verify before authorizing the charge. Months later, the cardholder disputes the charge as unauthorized; the issuer produces attestation and re-verifies. verified → the card was physically present and the correct PIN was entered, shifting liability to the cardholder per scheme rules. failed-verification(proof-invalid) → the dispute is upheld.

### Legal — qualified electronic signature on a contract

Two parties sign a contract via a qualified electronic signature service. Each invokes `attest(contract_c12, party_ref, qualified_signature_credential)` using credentials issued by a qualified trust service provider. Two attestations are stored alongside the contract. Any future party — opposing counsel, mediator, court — invokes verify on either attestation. Under eIDAS Regulation (Electronic Identification, Authentication and Trust Services — the European Union (EU) regulation governing electronic signatures and identity), qualified electronic signatures carry the same legal effect as handwritten signatures, and the verification result is admissible evidence of authorship.

### Source control — signed commits in regulated software

A developer at an FDA-cleared (US Food and Drug Administration — the federal agency regulating drugs and medical devices) medical-device company pushes a commit signed with their hardware-key-backed credential. The version-control system records the attestation: `attest(commit_c44a, dev_smith, smith_credential) → attestation_a17`. CI (continuous integration — the automated build and test system) infrastructure calls `verify(a17)` before allowing merge into the release branch. During an FDA software-of-unknown-provenance audit, the auditor walks the release branch and re-verifies every commit's attestation. SOX (Sarbanes-Oxley Act — US financial reporting law)-scoped financial systems and products evaluated under the Common Criteria (the international standard for evaluating the security of information-technology products) follow the same pattern.

The mechanic is identical across all five. What differs: the credential mechanism (smart card, software key, qualified signature instrument, hardware token, chip-card secure element), the verification frequency (every action vs. on dispute vs. on audit), the regulatory consequence of [Failed Verification], and the composing patterns active around it (two-factor for prescriptions, witness signatures for some legal contracts, MFA — Multi-Factor Authentication, requiring two or more independent proofs of identity — for high-value wires).

### Rejection paths

**[Verify] → [Failed Verification] ([Proof Invalid]):** An auditor reviewing a batch of wire authorizations calls `verify(attestation_a44)`. The actor's key has been rotated since the [Attestation] was recorded, the registry kept no historical material, and the registry's current public material for `actor_ref: supervisor_s12` no longer matches the stored [Proof]. The atom returns `failed-verification(proof-invalid)`. The auditor notes the failure; the composing audit workflow escalates for manual review. The [Attestation] record is unchanged — Invariant 1 prevents modification; the failure is a verification-time result, not a record defect.

**[Verify] → [Not Known]:** A composing pattern references an [Attestation Id] that was never written (a partial-failure scenario where the host allocated the id at the seam (Identity 2), [Attest] answered [Storage Failure], and the composing pattern, whose call crossed that seam, cached the id before confirming success). `verify(attestation_a_unknown)` returns not-known — the id is not in the attestation records. This is structurally distinct from [Failed Verification]: the id does not reference any [Attestation]. The composing pattern must treat [Not Known] as a missing record (requiring re-attestation) rather than a verification failure.

**[Attest] → [Invalid Credential]:** A supervisor approves a high-value wire using a [Credential] that was rotated out earlier that day. `attest(wire_w55, supervisor_s12, rotated_credential)` → the [Credential] fails to validate against the registry's current public material for `supervisor_s12`; the atom returns invalid-credential. No [Attestation] is recorded — [Invalid Credential] is a guard rejection that fails before any database write (Operation 9); the composing workflow prompts re-attestation with the current [Credential].

### Regulated adversarial scenarios

Three scenarios the atom must survive in regulated contexts:

- **Regulator audit.** A regulator asks *"who confirmed commitment c41?"* The auditor follows the commitment record to its [Attestation Id], calls [Verify], and reads [Actor Reference] from the verified [Attestation]. The verification is performed against stored fields and registry public material, so the answer is provable. Invariants 2 and 3 are the structural answer.
- **Disputed transaction.** An actor claims they did not authorize an action. The investigator retrieves the [Attestation] and calls [Verify]. If [Verified], the [Proof] binds the named actor to the named action at [Attestation Instant] (Invariant 8). The actor cannot plausibly deny it without claiming credential compromise — an out-of-band investigation governed by a separate Compromise Disclosure pattern. If [Failed Verification] with [Proof Invalid] while the registry still holds the material in force at [Attestation Instant], the dispute is upheld and the system's record is corrected, the [Attestation] itself unchanged (Invariant 1.1); after a rotation the registry kept no history of, [Proof Invalid] says nothing about who authorized the action (Registry view 1).
- **Compromised credential discovered.** A [Credential] is later determined to have been compromised before some date. The atom does *not* retroactively invalidate attestations made with that [Credential] — Invariant 1 forbids modifying recorded attestations, and Invariant 8 is conditional on credential integrity. Reinterpretation of attestations made during the compromise window belongs to a Compromise Disclosure composing pattern, which produces *new* records that reframe the previously-verified attestations as untrustworthy. The atom's attestation records remain immutable; the meaning of its records changes via composition, not via mutation.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the attestation records and the actor registry's public material.

### Conformance checks

```
Check 1.1: An auditor MUST reconstruct EVERY attestation from the attestation's stored fields (Invariant 1.1, State 3).
Check 1.2: An auditor MUST NOT need state beyond those fields and the registry's public material (Invariant 6.1, Invariant 6.3).
Check 2.1: An auditor MUST verify an attestation without privileged access to the system (Invariant 6.1, Operation 21).
Check 3.1: IF the current material at attestation instant IS IN the public material THEN an auditor MUST confirm that the proof holds against the recorded action reference under the current material at attestation instant and against no other action (Invariant 2.1, Invariant 2.2).
Check 3.2: IF the current material at attestation instant IS IN the public material THEN an auditor MUST confirm that the proof holds against the recorded actor reference under the current material at attestation instant and against no other actor (Invariant 3.1, Invariant 3.2).
Check 4.1: An auditor MUST read verified, failed-verification and not-known as three distinct answers (Operation 14).
Check 4.2: An auditor MUST read proof-invalid, actor-unknown-in-registry and registry-unavailable as three distinct reasons (Operation 16, Operation 17, Operation 18).
Deleted: Check 5.1. Execution Contract Conformance 9 owns it.
```

NOTE: watch the external answer that moves (Check 3.1, Check 3.2).

NOTE: EVERY check names the rule the check tests. The bar is the regulator's question — *can you prove who authorized this action?* — never the developer's intuition.

### External checks

```
Deleted: External check 1. Execution Contract Conformance 9 owns it.
```

## Non-goals

```
Non-goal 1: The atom MUST NOT register an actor.
Non-goal 2: The atom MUST NOT retire an actor.
Non-goal 3: A deployment MUST compose an actor-registry pattern for the actor's lifecycle.
Non-goal 4: The atom MUST NOT authenticate an actor.
Non-goal 5: The atom MUST NOT decide whether an actor was permitted to take an action.
Non-goal 6: A deployment needing permission MUST compose Permissions.
Non-goal 7: The atom MUST NOT manage a credential.
Non-goal 8: The atom MUST NOT record two actors on one attestation.
Non-goal 9: The atom MUST NOT invalidate an attestation under a later compromise.
Non-goal 10: The atom MUST NOT detect a rewrite of the attestation records.
Non-goal 11: A deployment needing tamper-evident records MUST compose Tamper Evidence.
Non-goal 12: The atom MUST NOT vouch for the clock.
Non-goal 13: The atom MUST NOT bind the action content.
Non-goal 14: A host whose action content is mutable MUST bind an immutable reference.
Non-goal 15: The atom MUST NOT carry an actor reference across trust domains.
Non-goal 16: A deployment needing a retention bound MUST compose Retention Window.
```

WHY:
Binding a mutable action is the quiet failure: the proof stays valid while the content it was supposed to attest to changes underneath, which is why the host binds a content hash or composes a Content Lock pattern *(forthcoming)* (Non-goal 13, Non-goal 14).

NOTE: witness signatures, m-of-n approvals and dual control compose a Witness pattern *(forthcoming)* (Non-goal 8); tamper-evident records are what [Tamper Evidence](./tamper-evidence.md) supply (Non-goal 10, Non-goal 11); a retention bound is what [Retention Window](./retention-window.md) supplies, its purge included (Non-goal 16).

NOTE: open 2026-10-20-e — Non-goal 15 names no owner for carrying an actor reference across trust domains.

Where the atom breaks down: when authorization cannot be reduced to one actor — truly anonymous attestation in a regulated context is a contradiction; when the credential mechanism cannot produce a verifiable proof — a shared secret anyone holding it could forge with; when the deployment has no actor registry a verifier can consult.

## Edge cases

### Attestation record durability

```
Deleted: Attestation durability 1. Operation 2 owns it.
Deleted: Attestation durability 2. Execution Contract Database 3 owns it.
Deleted: Attestation durability 3. Execution Contract Database 3 owns it.
Deleted: Attestation durability 4. Execution Contract Database 3 owns it.
```

### Revocation status at verify time

```
Revocation status 1: A credential mechanism MAY carry the revocation status inside the proof.
Revocation status 2: A mechanism carrying the revocation status inside the proof MUST keep [Verify] self-contained.
Revocation status 3: A deployment MUST NOT read a mechanism resting on a live revocation service as self-contained.
Revocation status 4: The deployment MUST own the mechanism choice.
```

### The registry's view moves

```
Registry view 1: A rotation of an actor's public material MAY turn a verified attestation into a failing one.
Registry view 2: The actor registry MUST own whether historical public material is kept.
Registry view 3: A deployment whose old attestations must keep verifying MUST compose an actor registry holding the historical public material.
```

### Verification caching

```
Verification caching 1: An implementation MAY cache a verification result.
Verification caching 2: An implementation MUST NOT cache a verification result across two registry views.
```

NOTE: open 2026-10-20-b — a cached verification result is no part of the verification set, so whether a cache sits inside [Verify], against Invariant 6.3, or in front of it is not stated (Verification caching 1).

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST carry the attestation id alongside the record the attestation attributes.
Composition note 3: A composing pattern MUST trust a recorded actor field ONLY IF [Verify] answers verified.
Composition note 4: A composing pattern MUST own the retention of an attestation.
Composition note 5: This atom's invariant numbers MUST stand as a frozen contract surface.
```

NOTE: composing patterns — [Attributed Permissions Admin](../compositions/attributed-permissions-admin.md), [Authenticated Actor](../compositions/authenticated-actor.md), [Audit Trail](../compositions/audit-trail.md). Forthcoming: Actor Registry, Compromise Disclosure, Witness, Trusted Timestamping.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern, a writer); a business caller; a verifier; an auditor; an actor; the actor registry; the attestation records; a credential mechanism (also: a mechanism); an attestation; a rotation; a proof.

Term records: attestation — one binding, carrying attestation id, action reference, actor reference, proof and attestation instant.

Term record verbs: identify, allocate, supply, reuse, carry, stand, offer, store, hold, compute, record, stamp, answer, consume, alter, read, mint, write, verify, consult, set, change, share, bind, reinterpret, delete, register, retire, compose, authenticate, decide, manage, invalidate, detect, vouch, turn, own, retain, keep, rest, cache, reconstruct, need, confirm, declare, trust, renumber, add, fail, refuse, evaluate.

Term value sets: registry answer = material | unknown-actor | unreachable. proof check = held | failed. credential check = held | failed. attestation field = attestation id | action reference | actor reference | proof | attestation instant.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12); uncompromised — a credential no disclosure names as compromised at or before the instant in question.

Term terms: now, verification set, attestation, attestation id, action reference, action content, actor reference, seam, transition, business caller, attested, proof, attestation instant, credential, public material, current material, attestation field, cryptographic material, registry answer, registry view, credential check, proof check, verification failure.

#### Attestation

The record this atom defines: a permanent, verifiable binding of one action to the actor who authorized it. It carries its [Attestation Id], [Action Reference], [Actor Reference], [Proof], and [Attestation Instant]; nothing about it changes once recorded, and the atom offers no surface to revoke or modify it.

Kind: Type

#### Attest

The behavior a composing pattern invokes at action time to record a new [Attestation]. It consumes the supplied [Credential], records the [Proof] the deployment's credential mechanism computed from it at the seam, binds the [Actor Reference] to the [Action Reference], stamps [Attestation Instant], and returns the [Attestation Id]. It always creates a new record — it never modifies an existing one — and never persists the [Credential].

Kind: Operation

#### Verify

The read-only behavior an auditor or composing pattern invokes to confirm a recorded [Attestation], by id. It reads the proof check the deployment's credential mechanism runs at the seam, the stored [Proof] against the recorded [Action Reference] and [Actor Reference] under the actor registry's public material, and returns [Verified], [Failed Verification], or [Not Known]. It changes nothing.

Kind: Operation

#### Read

The read-only query answering every attestation the database holds, each with its stored fields. It keys nothing by action reference: a composing pattern that wants its own attestations enumerates this read and filters in its own code. It changes nothing.

Kind: Operation

#### Action Reference

The opaque reference to *what* is being attested — the action the [Attestation] binds. The atom does not interpret it; the composing pattern defines what an action is and how to reference it. Set on [Attest], immutable thereafter.

Kind:       Field
Field of:   Attestation
Projection: action_ref

#### Actor Reference

The opaque reference to *who* is attesting — the actor the [Attestation] binds. The actor registry that holds the actor's public material is a separate concept. Set on [Attest], immutable thereafter.

Kind:       Field
Field of:   Attestation
Projection: actor_ref

#### Attestation Id

The opaque, immutable identity of an [Attestation], host-allocated at the I/O seam on [Attest] and never reused. The [Action Reference], [Actor Reference], [Proof], and [Attestation Instant] are properties of the [Attestation], not its identity.

Kind:       Field
Field of:   Attestation
Projection: attestation_id

#### Proof

The cryptographic artifact that binds the [Actor Reference] to the [Action Reference] — a signature, a smart-card-bound attestation, a qualified electronic signature — checked under the actor registry's public material and never under the [Credential]. Computed from the [Credential] at the seam by the deployment's credential mechanism, recorded by [Attest] on the [Attestation], and re-checked by the proof check at [Verify]. Set on [Attest], immutable thereafter.

Kind:       Field
Field of:   Attestation
Projection: proof

#### Attestation Instant

The wall-time the [Attestation] was recorded, stamped from the host-injected clock on [Attest]. Immutable thereafter. The non-repudiation contract binds the actor to the action *at* this time.

Kind:       Field
Field of:   Attestation
Projection: attested_at

#### Credential

The private material the actor supplies to [Attest] to produce the [Proof]. It is *consumed* per call — used to compute the [Proof] and then discarded — and never stored under this name (or any name) by the atom. It is the only caller-supplied secret.

Kind:         Parameter
Parameter of: Attest
Projection:   credential

#### Attested

The atom's single stable state: an [Attestation] that has been recorded. There are no transitions out of it — the atom has no surface to revoke, invalidate, or modify an [Attestation] once recorded.

Kind:      Member
Member of: the attestation state
Role:      Outcome

#### Verified

The outcome [Verify] returns when the stored [Proof] checks out against the recorded [Action Reference] and [Actor Reference] under the registry's public material. It is the [Verified] half of the non-repudiation contract: the named actor authorized the named action (conditional on credential integrity).

Kind:       Member
Member of:  the Verify outcome
Role:       Outcome
Projection: verified

#### Failed Verification

The outcome [Verify] returns when the [Attestation] exists but does not verify, carrying a reason — [Proof Invalid], [Actor Unknown In Registry], or [Registry Unavailable]. Distinct from [Not Known], which is a lookup miss.

Kind:       Member
Member of:  the Verify outcome
Role:       Outcome
Projection: failed-verification

#### Not Known

The outcome [Verify] returns when the supplied [Attestation Id] references no recorded [Attestation] — a lookup miss, not a verification failure. A composing pattern treats it as a missing record (requiring re-attestation), not as a denial of authorship.

Kind:       Member
Member of:  the Verify outcome
Role:       Outcome
Projection: not-known

#### Proof Invalid

The [Failed Verification] reason returned when the stored [Proof] does not check out against the recorded [Action Reference] and [Actor Reference] under the registry's public material — for example, after the actor's key was rotated and the registry kept no historical material — or when a revocation status the [Proof] carries names the [Credential] revoked.

Kind:       Member
Member of:  the Failed Verification reason
Role:       Outcome
Projection: proof-invalid

#### Actor Unknown In Registry

The [Failed Verification] reason returned when the actor registry cannot return public material for the recorded [Actor Reference] — because the actor has been deleted from the registry. May be permanent.

Kind:       Member
Member of:  the Failed Verification reason
Role:       Outcome
Projection: actor-unknown-in-registry

#### Registry Unavailable

The [Failed Verification] reason returned when the actor registry is unreachable at verify time, and the refusal [Attest] returns when the registry is unreachable at attest time — a transient, retryable condition, distinct from [Actor Unknown In Registry].

Kind:       Member
Member of:  the Failed Verification reason and the Attest rejection
Role:       Outcome
Projection: registry-unavailable

#### Invalid Request

The refusal [Attest] returns when [Action Reference], [Actor Reference], or [Credential] is null or empty. A guard rejection that fails before any database write; no [Attestation] is recorded.

Kind:       Member
Member of:  the Attest rejection
Role:       Outcome
Projection: invalid-request

#### Invalid Credential

The refusal [Attest] returns when the supplied [Credential] does not validate against the actor registry's current material for the [Actor Reference], when the registry holds no public material for the [Actor Reference], or when a revocation status the [Proof] carries names the [Credential] revoked. A guard rejection that fails before any database write; no [Attestation] is recorded.

Kind:       Member
Member of:  the Attest rejection
Role:       Outcome
Projection: invalid-credential

#### Storage Failure

The refusal [Attest] returns when the database write fails after the [Credential] validates; the caller may attest again.

Kind:       Member
Member of:  the Attest rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Attestation]: #attestation
[Attest]: #attest
[Verify]: #verify
[Read]: #read
[Action Reference]: #action-reference
[Actor Reference]: #actor-reference
[Attestation Id]: #attestation-id
[Proof]: #proof
[Attestation Instant]: #attestation-instant
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

- **NIST (National Institute of Standards and Technology — US federal standards body) SP (Special Publication) 800-63-3 (Digital Identity Guidelines)** — Identity Assurance Levels (IAL), Authenticator Assurance Levels (AAL), Federation Assurance Levels (FAL) — graded measures of how strongly identity, authentication, and federation are established. The atom's credential-consumed-not-stored discipline and verification self-containment correspond to NIST's authenticator and verifier requirements.
- **eIDAS Regulation (EU 910/2014)** — qualified, advanced, and basic electronic signatures. Qualified electronic signatures carry the same legal effect as handwritten signatures across the EU; the atom's non-repudiation contract is the operational form.
- **FIPS 186-4 / FIPS 186-5 (Federal Information Processing Standards — mandatory US government computing standards; here the Digital Signature Standard)** — cryptographic foundation for asymmetric attestation. The atom is mechanism-neutral but FIPS 186 is the canonical credential-mechanism anchor.
- **ISO/IEC 27001 clause A.9 (Access Control) and clause A.12.4 (Logging and Monitoring)** — the International Organization for Standardization / International Electrotechnical Commission information-security standard; actor attribution as an access-control and audit requirement.
- **21 CFR (Code of Federal Regulations — the codification of US federal agency rules) Part 11 (FDA Electronic Records and Electronic Signatures)** — for healthcare, pharmaceuticals, and medical devices: requires electronic signatures to be uniquely attributable to one individual, with cryptographic or procedural binding that resists repudiation.
- **HIPAA (US Health Insurance Portability and Accountability Act) section 164.312(d) (Person or Entity Authentication)** — verification that a person or entity seeking access is the one claimed.
- **DEA EPCS (21 CFR section 1311)** — Electronic Prescriptions for Controlled Substances: two-factor cryptographic attestation requirements.
- **GDPR (EU General Data Protection Regulation) Article 32 (Security of Processing)** — names "ensuring the ongoing confidentiality, integrity, availability and resilience of processing systems and services"; non-repudiation is a recognized security property under Article 32's scope.
- **Sarbanes-Oxley section 302 and section 404** — officer certifications and internal control over financial reporting. Authenticated attestations on financial-system changes are section 302 / section 404 evidence.
- **PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for handling cardholder data) Requirement 8 (Identify and Authenticate Access)** — for payment systems handling cardholder data.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of composing authentication, authorization, registry, witness, and compromise concepts as separate atoms.
- **Eiffel's design-by-contract** — preconditions on attest; named rejection and verification reasons.
- **Public-key cryptography literature** (Diffie-Hellman, RSA — Rivest-Shamir-Adleman, ECDSA — Elliptic Curve Digital Signature Algorithm, EdDSA — Edwards-curve Digital Signature Algorithm; standard digital-signature schemes) — the foundational mechanism for verifiable proofs of authorship.
- **Non-repudiation literature in computer security** (Zhou and Gollmann, ISO/IEC 13888) — the formal framing of non-repudiation services as distinct from authentication.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: not applicable — vote no 2026-06-03
last gate: 2026-10-23 — Final Critique 9, the council's fifth round on the page and the first on its text since Final Critique 8's settle (db94a93), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS Beam, Linus GLM-5.3 Flash), each handed only the round's reading set, three passes on one text (frozen at bd22085); the round rests on three counted passes — foundational count 1 after the blind second triage (2026-10-23, one cold reader given the round's 25 reports, the method's test and the placement rule, and neither the threshold nor what the count decides), Kind A: Operation 9 and Operation 36 decided [Attest]'s refusals on a credential check and a proof that need cryptography no pure guard may run, while the cryptographic material the seam injects was declared nowhere (linus F2, with eos F2 and grid F1; open line 2026-10-20-a), cured; the settle's own triage had counted 0 (13 reports: 10 sent down onto the page's five flagged open lines; 3 rejected); 7 refining reports, 5 rhetorical reports; not clean; every refining finding cured, routed or answered, open line 2026-10-20-a closed; 2026-10-22 — Final Critique 8, the council's fourth round on the page — foundational count 1, cured, not clean; 2026-10-22 — Final Critique 7, the council's third round on the page — foundational count 2, both cured, not clean; 2026-10-22 — Final Critique 6, the council's second round on the page — foundational count 3, all cured, not clean; 2026-10-20 — Final Critique 5, the council's first round on the page — foundational count 7, all cured, not clean

open:
- 2026-10-20-b · refining · Invariant 6.3; Verification caching 1 · a cached verification result is no part of the verification set, so a cache inside [Verify] consults a source Invariant 6.3 bounds, though a cached and a fresh answer agree under one registry view → name the cache in the verification set, or place the cache in front of [Verify]
- 2026-10-20-e · refining · Non-goal 15 · carrying an actor reference across trust domains is forbidden with no owner named, where the Non-goal family names who owns what the atom does not do → name the owner, or a forthcoming pattern
- 2026-10-20-f · refining · [Read]; Term bounds · [Read] answers every attestation with no bound and no key → a bound, or a keyed read
- 2026-10-22-a · refining · Term seam; Term transition; Term business caller; Term now; State 2 · each term cites the section titled Logic Confinement Principle in `execution-contract.md`, which declares none of them, and State 2 reads a transition as the contract's move out of a state where Term transition declares the evaluation of one call → settle the corpus's one seam wording where every specification carrying it can take the cure
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/actor-identity.md`; the rounds and the migration that got it here are in [its history](./actor-identity.hist.md).

- **2026-10-23 — The credential mechanism computes at the seam, and the atom decides on what the seam injects.** *Chose:* Term cryptographic material declared as what the deployment's credential mechanism computes at the seam and the host injects, never inside the transition — at [Attest], the proof and the credential check; at [Verify], the proof check — so Capability requirement 4's supply names something; Operation 9 deciding invalid-credential on the credential check, Operation 1 recording the proof the deployment supplies at the seam, and the verification set taking in the proof check computed over its fields and registry view; Invariant 4.2 deleted to Invariant 1.1, which already binds every attestation field; open line 2026-10-20-a closed; rules 95 to 94. *Over:* an [Attest] that computed the proof itself and refused on a credential check and a revocation status its pure guard could not reach without cryptography (Execution Contract Logic confinement 1), beside a seam injecting cryptographic material declared nowhere. *Because:* Final Critique 9's blind second triage placed the open line foundational, where the settle's own triage and Final Critique 5 through 8 had sent it down on the reading that every conforming build computes at the seam: a rule no implementation can discharge from what the page names rests on an undeclared capability. The Execution Contract already gives the form: cryptographic material is an injected input (Logic confinement 3), and a mechanism is configured material invoked at a named step, never cryptography inside core logic. What each action answers is unchanged.

- **2026-10-22 — The binding is audited where the registry still holds the material the proof was made under.** *Chose:* Check 3.1 and Check 3.2 asking an auditor to confirm the binding under the current material at attestation instant, and only where that material IS IN the public material, so the auditor's two sources, the attestation records and the registry's public material, carry what each check reads; the Disputed transaction scenario upholding a dispute on proof-invalid only while the registry holds that material; rules 95 to 95. *Over:* two checks that a conforming deployment whose registry keeps no history fails on every attestation a later rotation reaches, a rotation Registry view 1 calls lawful and the Rejection paths walk through. *Because:* Final Critique 8 found two conforming registries, one keeping history and one not, clearing Check 3.1 differently on one attestation; Final Critique 6 held the binding invariants to the material in force at attestation instant and read the checks the same way without writing it, and a deployment whose old attestations must stay verifiable composes a registry that keeps their material (Registry view 3). What each action answers is unchanged.

- **2026-10-22 — A proof is what the public material checks without the credential, and a credential its own proof names revoked does not attest.** *Chose:* Term proof held to the cryptographic artifact checked under the public material and never under the credential — a signature, a card-bound proof, a qualified electronic signature — so a message authentication code and a witnessed approval are no proof the atom records; Operation 36, [Attest] answering invalid-credential where a revocation status the proof carries names the credential revoked; Invariant 6.2 deleted to Invariant 6.3, which already bars every source outside the verification set, and the verification set naming the registry view [Verify] decides on; rules 95 to 95. *Over:* a declared proof kind checked under the shared secret it was made with, or under nothing, beside a check an auditor runs without privileged access and an invariant that no other actor's proof verifies; an attestation recorded under a credential whose own proof names it revoked, which then never verifies. *Because:* Final Critique 7 found each a divergence between conforming builds or a lawful state breaking a stated invariant or check, and the page says the first itself: a proof is what anyone can later check without needing the credential, and the atom breaks down where the mechanism is a shared secret anyone holding it could forge with. What each action answers on every other call is unchanged.

- **2026-10-22 — The wiring and a composed purge are the Execution Contract's.** *Chose:* External check 1, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 5.1's tombstone, which named it, now naming the contract; Invariant 9.1 read by Execution Contract Database 6, so the atom deletes no attestation and a purge a composing Retention Window declares is answered by that pattern's records; both labels cited on Capability requirement 2; rules 96 to 95. *Over:* the page stating for itself that the wiring is read outside the records and that its no-removal rule binds the atom alone. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration and the composed erasure among them; this page's fifth and sixth Final Critiques had made those two cures one specification at a time. What each action does and answers is unchanged.

- **2026-10-22 — A composed retention may purge an attestation, the binding holds under the material the proof was made under, and one registry answer decides a verification.** *Chose:* Invariant 9.2, the attestation set never shrinking, written with no actor, deleted to Invariant 9.1 and Execution Contract Database 4, with Non-goal 16 sending a retention bound to Retention Window, so the atom deletes no attestation and a composing pattern's retention may purge one; Invariant 2.1 and Invariant 3.1 held to the current material at attestation instant; Operation 21 consulting the public material the registry answer at the seam carries (Capability requirement 3); the cryptographic material supplied under Capability requirement 4, Operation 23 deleted to it, as the seam's other supplies are; rules 97 to 96. *Over:* a count that could never fall beside the composing pattern that owns retention; binding invariants that a rotation the registry keeps no history of, lawful under Registry view 1 and 2, breaks; a registry read beside the answer the seam supplies, which can decide one call under two registry views. *Because:* Final Critique 6 found each a divergence between conforming builds or a lawful state breaking an invariant, and the prose this page was migrated from said the first two: cascading deletion under a retention policy is the composing pattern's responsibility, and verification fails after a rotation unless the registry keeps historical material.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Attest]'s refuses line listing its refusals in the order the attest refusal order gave them — invalid-request, registry-unavailable, invalid-credential, then storage-failure, which answers only at the write — with the order cited from the Execution Contract (Capability requirement 2, Execution Contract Refusal 1); Operation 35, the rule evaluating the order, deleted to Refusal 1, and Term attest refusal order deleted with it; rules 98 to 97. *Over:* the page stating for itself which of [Attest]'s refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's fifth Final Critique had made the cure one specification at a time. What [Attest] answers on every call is unchanged.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 2, Execution Contract Read 1 through 3) and the two rules that restated it deleted to it: the atom-wide state-unavailable (Operation 34) to Read 1, and [Read]'s state-unavailable on a failed read alone (Operation 30) to Read 2 beside Operation 27; the read's condition off the rules it held to an answered read (Operation 14, Operation 15, Operation 27), the read off the attest refusal order, Term database read deleted, state-unavailable off every signature and off the answers Check 4.1 tells apart; rules 100 to 98. *Over:* the page stating for itself what every action answers when the attestation records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's fifth Final Critique had made the first of the cures the contract's Read family is written from. What each action answers on an answered read is unchanged.

- **2026-10-20 — Verification follows the registry's own history, and the registry answer decides [Attest] as it decides [Verify].** *Chose:* the proof check run under the public material the actor registry holds, any historical material the registry keeps included, so a deployment whose old attestations must keep verifying composes a registry that keeps that history (Registry view 3); [Attest] reading the registry answer at the seam (Capability requirement 3), checking a credential against the current material alone, and refusing an unreachable registry with registry-unavailable and an actor the registry does not know with invalid-credential, under one stated order over [Attest]'s refusals (Operation 35); a failed read of the attestation store answering state-unavailable on every action (Operation 34). *Over:* a proof check pinned to the registry's current material beside a rule promising that retained history keeps old attestations verifying; the material in force at the attestation instant, which the registry answer does not carry; an [Attest] with no answer for the registry it reads. *Because:* Final Critique 5 found each a divergence between conforming builds, and the prose this page was migrated from had said it: verification follows the registry's current view, old attestations keep verifying exactly when the registry maintains historical material, and whether the registry does is the registry's.

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the attestation store supplied under Execution Contract Store 1, Store 3 and Store 4 (Capability requirement 2), and the five rules that restated them tombstoned to their owner — Operation 11 and Invariant 9.3, no partial attestation, to Store 1; Attestation durability 2 through 4, durability across a crash, a high-assurance deployment's durability mechanism and a storage-failure agreeing with an absent record, to Store 3; rules 103 to 99. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract; what the atom does for its domain is unchanged.

NOTE: End of Actor Identity.
