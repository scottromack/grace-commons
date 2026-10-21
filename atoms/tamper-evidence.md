---
title: Tamper Evidence
parent: Atomic Concepts
has_toc: true
toc: true
---

# Tamper Evidence

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Tamper Evidence answers the question "how do I know these records weren't altered after the fact?" It works through seals — permanent records that attach a cryptographic proof to the records they cover. A proof is a mathematical fingerprint of a set of records as they stood at a moment in time. Sealing computes that fingerprint and stores it. Verifying re-computes the fingerprint over the original records and compares. If anything was changed, the fingerprint no longer matches, and the check fails. The crucial limit is that this detects tampering rather than preventing it. It cannot stop someone with full write access from altering both the records and the seal. But it makes any alteration visible to anyone holding the original records and the seal. The pattern is deliberately neutral about the cryptographic method used, as long as the guarantee holds: any change since sealing is provable. This is the mechanism behind sealing financial transaction journals, medical-record change logs, and payment-card access logs so auditors can confirm nothing was rewritten — and behind Git's commit history, the most widely deployed example. It does not, on its own, prevent tampering, prove who created the seal, or guarantee the seal's timestamp. Each of those is a separate pattern layered on top.

---

## Intent

WHY:
A regulated record set must answer one question provably: *have these been altered since they were written?* Procedure cannot answer it — a runbook, an access-control list and a developer's word are all claims about the past made by the party under audit. A cryptographic commitment can: seal the record set, keep the proof, and any later modification is detectable by re-running the mechanism's own verification over the records the verifier holds. This atom is that commitment and nothing more. It is mechanism-neutral by design — a hash chain, a Merkle tree with a signed root, a timestamp token and a blockchain anchor satisfy one contract — and it is honest about its ceiling: it produces evidence of tampering, never prevention of it. An adversary with write access to both the records and the seals rewrites both. What defeats that is an anchor outside the adversary's reach, and that is a composing pattern's, named here and not overclaimed.

## Structure

### Identity model

```
Identity 1: The atom MUST identify evidence by the evidence id.
Identity 2: The host MUST allocate an evidence id at the atom's seam.
Identity 3: The transition MUST NOT allocate an evidence id.
Identity 4: The business caller MUST NOT supply an evidence id.
Identity 5: The atom MUST NOT reuse an evidence id.
Identity 6: The atom MUST NOT identify evidence by the record set reference.
Identity 7: The atom MUST NOT identify evidence by sealing instant.
Identity 8: Two seals over one record set MUST carry two evidence ids.
```

Term evidence: one recorded commitment over a record set — an [Evidence]; carries the proof and nothing that changes.

Term evidence id: the opaque value naming one evidence — an [Evidence Id].

Term record set reference: the opaque reference naming what was sealed — a [Record Set Reference]; the host owns what a record set is.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the evidence id, the cryptographic material and record set match here.

Term transition: the atom's evaluation of one call against the seal records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

### State

```
State 1: EVERY evidence MUST stand in sealed.
State 2: The atom MUST NOT offer a transition out of sealed.
State 3: EVERY evidence MUST carry evidence id, record set reference, proof and sealing instant.
State 4: An evidence MAY carry anchoring instant.
State 5: The atom MUST NOT store the mechanism credential.
State 6: The atom MUST NOT offer a deletion surface.
State 7: The atom MUST NOT offer a revocation surface.
```

Term sealed: the atom's one state — recorded, and nothing further to become.

Term proof: the artifact the mechanism produced over the record set — a [Proof]: a hash chain, a Merkle root, a signed root, a timestamp token, a blockchain transaction id, or a composite.

Term sealing instant: the wall-time instant the evidence was recorded, stamped from the injected now — a [Sealing Instant].

Term anchoring instant: the time an external anchor recorded at seal time — an [Anchoring Instant]; absent where the mechanism anchors nothing.

Term mechanism credential: the material the mechanism consumes to produce the proof — a [Mechanism Credential]; keying material for a keyed mechanism, and an empty value — present, carrying nothing — for an unkeyed one. Absent is not empty: Operation 7 refuses the input that was never supplied, Operation 8 accepts the one supplied with no content.

Term evidence field: evidence id | record set reference | proof | sealing instant | anchoring instant.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the seal records PER Execution Contract Database 1, Execution Contract Database 3 and Execution Contract Database 4.
Capability requirement 3: The deployment MUST declare the deployment's mechanism.
```

### Operations

```
seal(record_set_ref, mechanism_credential)
  answers evidence_id
  refuses invalid-request | mechanism-failure(mechanism failure reason) | state-unavailable | storage-failure

verify(evidence_id, original_record_set)
  answers verified | failed-verification(verification failure) | not-known
  refuses state-unavailable

read()
  answers every evidence
  refuses state-unavailable
```

Term mechanism failure reason: unreadable-records | keying-precondition | anchor-unreachable — the reasons [Seal] gives for a mechanism failure.

Term verification failure: proof-invalid | record-set-mismatch | mechanism-verification-unavailable — the reasons [Verify] gives for a failed verification.

```
Operation 1: [Seal] MUST compute the proof over the record set from the mechanism credential.
Operation 2: [Seal] MUST record EXACTLY ONE evidence per successful call.
Operation 3: [Seal] MUST stamp sealing instant from the injected now.
Operation 4: IF the mechanism anchors at seal time THEN [Seal] MUST carry anchoring instant into the evidence.
Operation 5: [Seal] MUST consume the mechanism credential.
Operation 6: IF record set reference EQUALS blank THEN [Seal] MUST answer invalid-request.
Operation 7: IF the mechanism credential is absent THEN [Seal] MUST answer invalid-request.
Operation 8: [Seal] MUST accept an empty mechanism credential for an unkeyed mechanism.
Operation 9: IF the mechanism cannot compute the proof THEN [Seal] MUST answer mechanism-failure.
Operation 10: IF the database refuses the write THEN [Seal] MUST answer storage-failure.
Operation 11: [Seal] MUST discard the proof on storage-failure.
Operation 12: [Seal] MUST NOT alter a recorded evidence.
Operation 13: [Verify] MUST take the original record set.
Operation 14: [Verify] MUST answer EXACTLY ONE OF verified, failed-verification, not-known, state-unavailable.
Operation 15: IF database read EQUALS answered AND no evidence EXISTS for the evidence id THEN [Verify] MUST answer not-known.
Operation 16: IF evidence EXISTS for the evidence id AND record set match EQUALS no THEN [Verify] MUST answer record-set-mismatch.
Operation 17: IF record set match EQUALS yes AND seal check EQUALS unavailable THEN [Verify] MUST answer mechanism-verification-unavailable.
Operation 18: IF record set match EQUALS yes AND seal check EQUALS failed THEN [Verify] MUST answer proof-invalid.
Operation 19: IF record set match EQUALS yes AND seal check EQUALS held THEN [Verify] MUST answer verified.
Operation 20: [Verify] MUST NOT write.
Deleted: Operation 21. Capability requirement 1 owns it.
Operation 22: The host MUST supply the cryptographic material at the atom's seam.
Operation 22a: The host MUST supply record set match at the atom's seam.
Operation 22b: The atom MUST NOT judge record set match.
Deleted: Operation 23. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 24. Execution Contract Logic confinement 3 owns it.
Operation 25: The business caller MUST NOT supply sealing instant.
Operation 26: The implementation MUST own the mechanism.
Operation 27: IF database read EQUALS answered THEN [Read] MUST answer EVERY evidence.
Operation 28: [Read] MUST answer an evidence's evidence id, record set reference, proof, sealing instant AND anchoring instant.
Operation 29: [Read] MUST NOT write.
Operation 30: [Read] MUST answer state-unavailable ONLY IF database read EQUALS failed.
Operation 31: IF database read EQUALS failed THEN the atom MUST answer state-unavailable.
Operation 32: [Seal] MUST NOT evaluate a rule of the seal refusal order BEFORE EVERY earlier rule of the seal refusal order has answered no refusal.
Operation 33: [Verify] MUST answer verified ONLY IF seal check EQUALS held.
```

Term record set match: yes | no — the host's answer, injected at the seam, to whether the presented original record set is the record set the evidence's record set reference names. A different record set answers no; the named record set answers yes even where its content differs, and the content difference is for seal check to decide. The atom cannot judge it: record set reference is opaque and Identity rules forbid interpreting it, so the party that resolved the reference at seal time is the party that answers here (council read 13).

Term seal check: held | failed | unavailable — the mechanism's verification function, run over the presented record set against the recorded proof. Named for the seal because [Actor Identity](./actor-identity.md) declares its own proof check over an attestation, and [Audit Trail](../compositions/audit-trail.md) wires both: one name for two judgments is a collision a composition cannot resolve (council read 13).

Term original record set: the record set a verifier presents at [Verify] — an [Original Record Set]; the proof commits to content, so the verifier holds the content.

Term verification set: the evidence's own fields, the presented original record set, the host-injected record set match, and, where the mechanism's verification function consults one, that mechanism's own external anchor; everything [Verify] is allowed to read, and nothing else.

Term database read: answered | failed — the outcome of the read a call makes of the seal records, failed being the failure the section titled Step 1 failure in `execution-contract.md` names.

Term seal refusal order: Operation 31, Operation 6 through 7, Operation 9 — [Seal]'s refusal rules, earliest first; Operation 10 answers only at the write, which no refused call reaches.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the seal records |
|---|---|---|---|
| [Seal] | credential and reference well-formed, mechanism computes, database accepts | evidence id | one evidence lands in [Sealed] (Operation 1, Operation 2) |
| [Seal] | the database read fails | [State Unavailable] | none (Operation 31) |
| [Seal] | blank reference, or absent credential | [Invalid Request] | none (Operation 6, Operation 7) |
| [Seal] | mechanism cannot compute the proof | [Mechanism Failure] | none (Operation 9) |
| [Seal] | database refuses the write | [Storage Failure] | none — the proof is discarded (Operation 10, Operation 11) |
| [Verify] | the database read fails | [State Unavailable] | none (Operation 31) |
| [Verify] | no evidence under that id | [Not Known] | none — the call reads (Operation 15, Operation 20) |
| [Verify] | evidence found, wrong records presented | [Record Set Mismatch] | none (Operation 16) |
| [Verify] | right records, verification service unreachable | [Mechanism Verification Unavailable] | none (Operation 17) |
| [Verify] | right records, proof does not hold | [Proof Invalid] | none (Operation 18) |
| [Verify] | right records, proof holds | [Verified] | none (Operation 19, Operation 33) |
| [Read] | the database read fails | [State Unavailable] | none (Operation 30, Operation 31) |
| [Read] | the database read answers | every evidence, with its stored fields | none (Operation 27 through 29) |

Where two [Seal] cases hold at once, the earlier rule of the seal refusal order answers (Operation 32).

### Invariants

- **Invariant 1 — Evidence immutability.**
  ```
  Invariant 1.1: EVERY evidence field of a recorded evidence MUST NOT change.
  ```
- **Invariant 2 — Detectability of tampering.**
  ```
  Invariant 2.1: IF record set match EQUALS yes AND seal check DOES NOT EQUAL unavailable AND the original record set differs from the record set presented at [Seal] THEN [Verify] MUST answer proof-invalid.
  Invariant 2.2: A deployment MUST NOT rest detectability on a deprecated mechanism.
  Invariant 2.3: A deployment MUST re-seal a record set under a sound mechanism.
  ```
- **Invariant 3 — Record-set binding.**
  ```
  Invariant 3.1: A recorded proof MUST verify against the record set presented at [Seal].
  Invariant 3.2: A recorded proof MUST NOT verify against another record set.
  ```
- **Invariant 4 — Verification self-containment given the originating records.**
  ```
  Invariant 4.1: [Verify] MUST consult the verification set.
  Invariant 4.2: [Verify] MUST NOT consult the host's state.
  Invariant 4.3: [Verify] MUST NOT consult a source outside the verification set.
  ```
- **Invariant 5 — Id stability.**
  ```
  Invariant 5.1: [Seal] MUST set the evidence id.
  Invariant 5.2: An evidence id MUST NOT change.
  ```
- **Invariant 6 — No id reuse.**
  ```
  Invariant 6.1: Two evidence records MUST NOT share an evidence id.
  ```
- **Invariant 7 — Verification consistency under a fixed record set.**
  ```
  Invariant 7.1: IF no verification answering mechanism-verification-unavailable EXISTS among two verifications of one evidence against one record set AND no verification answering state-unavailable EXISTS among the two verifications THEN the two verifications MUST answer alike.
  ```
- **Invariant 8 — Mechanism opacity.**
  ```
  Invariant 8.1: The atom's contract MUST hold for EVERY sound mechanism whose verification function consults no source outside the verification set.
  Invariant 8.2: The atom MUST NOT read the proof's internal structure.
  ```
- **Invariant 9 — Seal record durability.**
  ```
  Invariant 9.1: The atom MUST NOT delete an evidence.
  Invariant 9.2: The evidence set MUST NOT shrink.
  Deleted: Invariant 9.3. Execution Contract Database 1 owns it.
  ```

## Examples

The same atom, five regulated domains, identical mechanic.

### Financial — transaction-log anchoring under SOX

A bank's settlement system seals each day's transaction journal: `seal(journal_2026-05-10, hsm_signing_key) → evidence_a91`. The mechanism is a SHA-256 (Secure Hash Algorithm, 256-bit — a standard cryptographic hash function) hash chain over the day's transactions, with the chain's tail signed by an HSM-bound (Hardware Security Module — a dedicated tamper-resistant device for keys) key. Once per hour, the chain tail is anchored to an RFC 3161 qualified timestamp authority; the authority's timestamp token is recorded as [Anchoring Instant] on the seal. Seven years later, during a SOX (Sarbanes-Oxley Act — US financial reporting law) section 404 audit, the external auditor presents the journal and `verify(a91, journal_2026-05-10) → verified` — confirming the day's transactions were not altered after the seal, with the qualified timestamp giving an upper bound on when they could have been forged.

### Healthcare — EHR change-log integrity under HIPAA and 21 CFR Part 11

A hospital EHR (Electronic Health Record — the digital patient chart system) appends every record amendment (correction, addendum, redaction) to a per-patient change log. The change log is sealed on a rolling Merkle-tree basis — each commit produces a new root and a new seal. `verify(seal, patient_change_log) → verified` confirms the log has not been silently rewritten since the seal. A correction added today is a new event in the log, not a modification of yesterday's; if anyone retroactively edited yesterday's entry, today's seal would fail verification. 21 CFR Part 11's (the US Code of Federal Regulations rule on electronic records and signatures) and HIPAA's (US Health Insurance Portability and Accountability Act) electronic-record integrity bar is satisfied structurally.

### Source control — Git's commit DAG

A developer pushes a commit. Git computes the cryptographic hash (a fixed-length fingerprint computed from data — any change to the data produces a different fingerprint) of the commit object — which includes the hash of its parent commits — and stores the object under that hash. The hash *is* the [Proof]: the commit's content, its parents, and (transitively) the entire history are committed to in one chain. `git fsck` is the verification function; tampering anywhere in the history produces a hash mismatch detectable from the repository alone. The commit DAG is a worked open-source instance of this atom — [Evidence Id] = commit hash, [Record Set Reference] = the commit's tree and parents, [Proof] = the chained hashes, [Sealing Instant] = the commit timestamp. Linus Torvalds built the world's most widely-deployed Tamper Evidence implementation; the atom names what it does in domain-neutral terms.

### Legal — document notarization under RFC 3161 trusted timestamping

A law firm timestamps an executed contract via a qualified Time-Stamp Authority (TSA — a trusted third party that issues signed proofs that data existed at a given time). The mechanism is RFC 3161: a hash of the contract is submitted to the TSA; the TSA returns a signed TimeStampToken binding the hash to a trusted time. The token *is* the [Proof]; [Anchoring Instant] is set from the TSA's timestamp. Any future dispute — opposing counsel claims the contract was modified post-signing — is resolved by `verify(evidence, contract_pdf) → verified | failed-verification(proof-invalid)`. eIDAS Regulation (Electronic Identification, Authentication and Trust Services — the EU regulation governing electronic signatures and timestamps) gives qualified electronic timestamps presumed evidentiary effect across the EU.

### Payments — PAN-handling audit under PCI DSS

A payment processor seals each day's cardholder-data access log: `seal(pan_access_log_2026-05-10, processor_key) → evidence_p41`. The mechanism is a SHA-256 hash chain — each entry's hash includes the previous entry's hash and the entry's content — whose tail is signed each day under the processor's key, the [Proof] carrying the signature and the public key that checks it. A chain keyed by a shared secret, such as an HMAC (Hash-based Message Authentication Code) chain, is outside the contract: checking it needs the secret, which the verification set does not carry (Invariant 8.1). PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for cardholder data; here applied to PAN, the Primary Account Number) Requirement 10.5 mandates audit-log integrity; the seal is the structural form. A QSA's (Qualified Security Assessor — a PCI-certified auditor) annual assessment runs verify over the prior year's daily logs; any tampering — whether to hide a cardholder-data exfiltration or to forge access for a fraudulent dispute — is detected from the logs themselves.

The mechanic is identical across all five. What differs: the mechanism family (hash chain, Merkle tree, qualified timestamp), the frequency of sealing (per-commit, per-amendment, per-document, per-day), the anchoring story (none, RFC 3161 TSA, blockchain), and the composing patterns active around it (Actor Identity for authored seals, Trusted Timestamping for qualified anchors, External Anchoring for tamper-proof reach).

### Rejection and verification-failure paths

**Tampering detected — [Proof Invalid].** An incident response team queries a transaction journal seal and presents the journal as it exists now — after a discovered alteration:

```
verify(evidence_id: "evidence_a91", original_record_set: journal_2026-05-10_altered)
→ failed-verification(proof-invalid)
```

The [Proof] no longer matches the altered record set. The team then presents the prior day's backup copy of the journal:

```
verify(evidence_id: "evidence_a91", original_record_set: journal_2026-05-10_backup)
→ verified
```

verified confirms the backup matches what was sealed; proof-invalid on the altered version confirms the alteration occurred after [Sealing Instant]. The forensic window is bounded by the two seal timestamps.

**Wrong record set presented — [Record Set Mismatch].** A verifier accidentally presents the wrong day's journal to a seal:

```
verify(evidence_id: "evidence_a91", original_record_set: journal_2026-05-11)
→ failed-verification(record-set-mismatch)
```

The presented record set does not match the [Record Set Reference] the [Evidence] was made over. This is not a tampering signal — it is a caller error, structurally distinguishable from proof-invalid.

### Regulated adversarial scenarios

Three scenarios the atom must survive in regulated contexts:

- **Regulator integrity audit.** A regulator asks *"how do I know these records weren't rewritten after the fact?"* The auditor takes the original record set from the host, the [Evidence Id] from the seal records, and runs [Verify] — independently, with their own implementation of the mechanism's verification function. [Verified] is a structural guarantee, not a procedural promise. Where the [Evidence] carries [Anchoring Instant] from a qualified TSA outside the host's control, the audit additionally establishes an upper bound on the time the records could have been forged. Invariants 2 and 3 are the structural answer.
- **Breach forensics — "when was the record altered?"** An incident responder discovers anomalous data. They query the seal records for every [Evidence] whose [Record Set Reference] covers the suspect records, in [Sealing Instant] order. Running [Verify] on each, they identify the most recent [Evidence] that returns [Verified] (records intact at that time) and the next [Evidence] that returns [Failed Verification] (records altered between those two seal times). The forensic window is bounded by the seal cadence; tighter cadence narrows the window. The atom does not name *who* altered the records — that is a separate Forensic Attribution composition — but it names *when* with the resolution of the seal schedule.
- **False-tamper-claim disproof.** A counterparty claims *"you modified the contract after I signed."* The system presents the contract and the [Evidence]; `verify(evidence, contract) → verified`. The claim is structurally disproven against the unmodified record set the system retains; the counterparty's burden shifts to producing a different record set they claim is the authoritative one, at which point the dispute becomes about *which version is canonical* rather than *whether it was tampered with*. The atom answers the second question; the first belongs to the Content Lock or Document Versioning composing pattern.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the seal records and the originating record sets.

### Conformance checks

```
Check 1.1: An auditor MUST reconstruct EVERY seal from the evidence's stored fields (Invariant 1.1, State 3).
Check 1.2: An auditor MUST NOT need state beyond those fields and the originating record set (Invariant 4.1, Invariant 4.2).
Check 2.1: An auditor MUST verify an evidence with the auditor's own implementation of the mechanism's verification function (Invariant 4.1, Operation 13).
Check 2.2: An auditor MUST NOT need privileged access to the system to verify (Invariant 4.2).
Check 3.1: An auditor MUST confirm that a single-byte change to the record set yields proof-invalid (Invariant 2.1, Operation 18).
Check 4.1: An auditor MUST read verified, failed-verification, not-known and state-unavailable as four distinct answers (Operation 14).
Check 4.2: An auditor MUST read record-set-mismatch, proof-invalid and mechanism-verification-unavailable as three distinct reasons (Operation 16, Operation 17, Operation 18).
Check 5.1: IF the mechanism anchors at seal time THEN an auditor MUST bound a detected tampering between two adjacent anchoring instant times (Invariant 2.1, Identity 8).
Check 5.2: An auditor MUST read a bound between two adjacent sealing instant times as best-effort (Non-goal 8).
Deleted: Check 6.1. External check 3 owns it.
Deleted: Check 6.2. External check 4 owns it.
```

### External checks

```
External check 1: An auditor MUST read the mechanism's health from the Mechanism Registry's evidence (Invariant 2.2, Invariant 2.3).
External check 2: An auditor MUST read the anchor's trust from the anchoring authority's own records (Non-goal 1, Non-goal 2).
External check 3: An auditor MUST identify from the deployment's own declaration which composing patterns the deployment wired in (Composition note 1).
External check 4: An auditor MUST read the deployment's mechanism from the deployment's own declaration (Operation 26, Capability requirement 3).
```

NOTE: mechanism health, anchor trust, the composing patterns wired in and the mechanism itself are what the seal records do not carry — the External check family v0.35 declares exists for exactly this (council read 13).

NOTE: EVERY check names the rule the check tests. The bar is the regulator's question — *can you prove these records were not altered?* — answered provably.

## Non-goals

```
Non-goal 1: The atom MUST NOT prevent tampering.
Non-goal 2: A deployment needing reach beyond detection MUST compose an external-anchoring pattern.
Non-goal 3: The atom MUST NOT anchor a proof once the seal lands.
Non-goal 4: The atom MUST NOT choose the mechanism's hash function.
Non-goal 5: The atom MUST NOT choose the mechanism's signature scheme.
Non-goal 6: The atom MUST NOT bind a proof to a named actor.
Non-goal 7: A deployment needing an attributable seal MUST compose Actor Identity.
Non-goal 8: The atom MUST NOT vouch for the clock.
Non-goal 9: A deployment whose time of seal carries legal force MUST compose a trusted-timestamping pattern.
Non-goal 10: The atom MUST NOT purge an evidence alongside purged records.
Non-goal 11: The atom MUST NOT define a record set.
Non-goal 12: The host MUST present a record set alike at seal time and at verify time.
Non-goal 13: The atom MUST NOT deduplicate two seals over one record set.
Non-goal 14: A pattern needing one seal per record set per cadence MUST own that coordination.
```

Where the atom breaks down: when the host cannot supply a record set reference whose contents are reproducibly addressable at verify time; when the chosen mechanism commits to the records' identity and not their content; when the proof records and the sealed records share an adversary with write access to both and no external anchor exists.

## Edge cases

### Atomicity of a seal

```
Deleted: Seal atomicity 1. Execution Contract Database 1 owns it.
Deleted: Seal atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Seal atomicity 3. Execution Contract Database 3 owns it.
```

### Concurrent seals

```
Concurrent seal 1: Two seals over one record set MUST stand as independent evidence.
Concurrent seal 2: The atom MUST NOT order two seals over one record set.
```

### Retention coupling

```
Retention coupling 1: A purged record set MUST leave [Verify] unable to hold.
Retention coupling 2: A composing pattern MUST own the cascading purge of an evidence alongside the records.
Retention coupling 3: A deployment MUST NOT read a seal over destroyed records as proof of the records' content.
```

### Verification caching

```
Verification caching 1: An implementation MAY cache a verification result.
Verification caching 2: An implementation MUST NOT cache a verification result across two record-set states.
```

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: An integrity-relevant Event Log instance MUST compose this atom.
Composition note 3: A deployment needing an attributable seal MUST supply an actor's credential as the mechanism credential.
Composition note 4: A composing pattern MUST own the decision to purge an evidence alongside the records the evidence commits to.
Composition note 5: This atom's invariant numbers MUST stand as a frozen contract surface.
```

NOTE: composing patterns — [Audit Trail](../compositions/audit-trail.md). Forthcoming: External Anchoring, Trusted Timestamping, Mechanism Registry.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern, a writer); a business caller; a verifier; an auditor; an adversary; the mechanism; the seal records; an evidence; a seal; a verification.

Term records: evidence — one commitment, carrying evidence id, record set reference, proof, sealing instant and, where the mechanism anchors, anchoring instant.

Term record verbs: judge, identify, allocate, supply, reuse, carry, stand, order, offer, store, compute, record, stamp, consume, accept, answer, discard, alter, take, read, own, write, change, verify, consult, set, share, hold, delete, shrink, leave, reconstruct, need, confirm, bound, prevent, compose, anchor, choose, bind, vouch, purge, define, present, deduplicate, rest, re-seal, cache, declare, renumber, add, refuse, evaluate.

Term value sets: record set match = yes | no. seal check = held | failed | unavailable. database read = answered | failed. evidence field = evidence id | record set reference | proof | sealing instant | anchoring instant. evidence state = sealed.

Term bounds: empty.

Term cadences: empty — a seal cadence is the composing pattern's (Composition note 1).

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11); sound — a mechanism with no known practical collision or forgery attack.

Term terms: now, evidence, evidence id, record set reference, seam, transition, business caller, sealed, proof, sealing instant, anchoring instant, mechanism credential, evidence field, record set match, seal check, original record set, verification set, database read, seal refusal order, mechanism failure reason, verification failure.

#### Evidence

The record this atom defines: a permanent, verifiable seal over a record set — cryptographic evidence that the set has not been altered since its authoritative creation. It is produced by [Seal] and carries its [Evidence Id], [Record Set Reference], [Proof], [Sealing Instant], and optional [Anchoring Instant]; nothing about it changes once recorded, and the atom offers no surface to revoke, modify, or re-anchor it.

Kind: Type

#### Seal

The behavior a composing pattern invokes at seal time to record a new [Evidence] over a record set. It consumes the supplied [Mechanism Credential] to compute the [Proof], stamps [Sealing Instant] (and [Anchoring Instant] if the mechanism anchors synchronously), and returns the [Evidence Id]. It always creates a new record — it never modifies an existing one — and never persists the [Mechanism Credential].

Kind: Operation

#### Verify

The read-only behavior an auditor or composing pattern invokes to confirm a recorded [Evidence], by id, against a presented record set. It re-runs the mechanism's verification function over the [Original Record Set] against the stored [Proof] and returns [Verified], [Failed Verification], or [Not Known], or refuses with [State Unavailable] when the seal records cannot be read. It changes nothing. Unlike Actor Identity's verify, it requires the originating record set as input, because the [Proof] commits to the records' content.

Kind: Operation

#### Read

The read-only query answering every evidence the database holds, each with its stored fields. It changes nothing, and refuses only with [State Unavailable], when the seal records cannot be read.

Kind: Operation

#### Evidence Id

The opaque, immutable identity of an [Evidence], host-allocated at the I/O seam on [Seal] and never reused. The [Record Set Reference], [Proof], [Sealing Instant], and [Anchoring Instant] are properties of the [Evidence], not its identity.

Kind:       Field
Field of:   Evidence
Projection: evidence_id

#### Record Set Reference

The opaque reference to *what* the [Evidence] commits to — the record set the [Proof] is computed over. The atom does not interpret it; the host pattern defines what a record set is and how to present it to [Verify] later. Set on [Seal], immutable thereafter.

Kind:       Field
Field of:   Evidence
Projection: record_set_ref

#### Proof

The cryptographic artifact that commits to the record set's content — a hash chain, Merkle root, signed root, RFC 3161 timestamp token, blockchain transaction id, or composite. Computed by [Seal] from the [Mechanism Credential] and the injected cryptographic material, stored on the [Evidence], and the thing [Verify] re-checks. Set on [Seal], immutable thereafter.

Kind:       Field
Field of:   Evidence
Projection: proof

#### Sealing Instant

The wall-time the [Evidence] was recorded, stamped from the host-injected [Now] on [Seal]. Immutable thereafter; best-effort, since clock quality is a deployment concern.

Kind:       Field
Field of:   Evidence
Projection: sealed_at

#### Anchoring Instant

The wall-time of an external anchor, present only when the chosen mechanism produced one synchronously at seal time (for example, an RFC 3161 timestamp authority called during [Seal]). Set on [Seal] if produced, immutable thereafter, and absent otherwise. Later, asynchronous anchoring belongs to a separate External Anchoring composition.

Kind:       Field
Field of:   Evidence
Projection: anchored_at

#### Mechanism Credential

The opaque material the chosen mechanism supplies to [Seal] to produce the [Proof] — keying material for keyed mechanisms, possibly empty or a configuration handle for unkeyed ones. It is *consumed* per call — used to compute the [Proof] and then discarded — and never persisted under this name (or any name) by the atom. It is the only caller-supplied secret.

Kind:         Parameter
Parameter of: Seal
Projection:   mechanism_credential

#### Original Record Set

The originating record set the verifier presents to [Verify], re-checked against the stored [Proof] to detect modification. It is supplied per call and not stored under this name; the asymmetry from Actor Identity's verify is that this content must be re-presented, because the [Proof] commits to the records' content.

Kind:         Parameter
Parameter of: Verify
Projection:   original_record_set

#### Now

The current wall-time reading [Seal] stamps [Sealing Instant] from, supplied to the pure transition by the host at the I/O seam (never read inside the transition, never supplied by the business caller).

Kind:         Parameter
Parameter of: Seal
Projection:   now

#### Sealed

The atom's single stable state: an [Evidence] that has been recorded. There are no transitions out of it — the atom has no surface to revoke, invalidate, modify, or re-anchor an [Evidence] once recorded.

Kind:      Member
Member of: the evidence state
Role:      Outcome

#### Verified

The outcome [Verify] returns when the stored [Proof] checks out against the presented [Original Record Set] under the chosen mechanism's verification function. It is the structural confirmation that the records were not altered after [Sealing Instant] (conditional on a cryptographically sound mechanism).

Kind:       Member
Member of:  the Verify outcome
Role:       Outcome
Projection: verified

#### Failed Verification

The outcome [Verify] returns when the [Evidence] exists but does not verify, carrying a reason — [Proof Invalid], [Record Set Mismatch], or [Mechanism Verification Unavailable]. Distinct from [Not Known], which is a lookup miss.

Kind:       Member
Member of:  the Verify outcome
Role:       Outcome
Projection: failed-verification

#### Not Known

The outcome [Verify] returns when the supplied [Evidence Id] references no recorded [Evidence] — a lookup miss, not a verification failure. It is exclusively an [Evidence Id] lookup miss; an absent or wrong record set routes to [Failed Verification] for reason [Record Set Mismatch] instead.

Kind:       Member
Member of:  the Verify outcome
Role:       Outcome
Projection: not-known

#### Proof Invalid

The [Failed Verification] reason returned when the mechanism's verification function, run over the presented record set against the stored [Proof], does not check out — the structural signal of tampering.

Kind:       Member
Member of:  the Failed Verification reason
Role:       Outcome
Projection: proof-invalid

#### Record Set Mismatch

The [Failed Verification] reason returned when the presented [Original Record Set] does not refer to the record set the [Evidence] was made over — a caller error, structurally distinct from [Proof Invalid] (tampering) and from [Not Known] (lookup miss).

Kind:       Member
Member of:  the Failed Verification reason
Role:       Outcome
Projection: record-set-mismatch

#### Mechanism Verification Unavailable

The [Failed Verification] reason returned when the mechanism's verification function requires an external service (for example, an RFC 3161 TSA's published certificate chain) that is unavailable at verify time — a transient, retryable condition, distinct from [Proof Invalid] and [Record Set Mismatch].

Kind:       Member
Member of:  the Failed Verification reason
Role:       Outcome
Projection: mechanism-verification-unavailable

#### Invalid Request

The refusal [Seal] returns when [Record Set Reference] is blank, or [Mechanism Credential] is absent entirely. A guard rejection that fails before any database write; no [Evidence] is recorded.

Kind:       Member
Member of:  the Seal rejection
Role:       Outcome
Projection: invalid-request

#### Mechanism Failure

The refusal [Seal] returns when the mechanism cannot compute a [Proof] against the record set — the underlying records are unreadable, the keying material fails the mechanism's preconditions, or a required synchronous anchor service is unreachable. No [Evidence] is recorded.

Kind:       Member
Member of:  the Seal rejection
Role:       Outcome
Projection: mechanism-failure

#### Storage Failure

The refusal [Seal] returns when the database write fails after the [Proof] is computed. The computed [Proof] is discarded — the caller must treat it as definitive.

Kind:       Member
Member of:  the Seal rejection
Role:       Outcome
Projection: storage-failure

#### State Unavailable

The refusal [Seal], [Verify] or [Read] returns when the read the call makes of the database fails — the Execution Contract's Step 1 failure. Nothing is decided or written, the call may be retried, and the answer says nothing about whether an [Evidence] exists.

Kind:       Member
Member of:  the Seal, Verify and Read rejections
Role:       Outcome
Projection: state-unavailable

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Evidence]: #evidence
[Seal]: #seal
[Verify]: #verify
[Read]: #read
[Evidence Id]: #evidence-id
[Record Set Reference]: #record-set-reference
[Proof]: #proof
[Sealing Instant]: #sealing-instant
[Anchoring Instant]: #anchoring-instant
[Mechanism Credential]: #mechanism-credential
[Original Record Set]: #original-record-set
[Now]: #now
[Sealed]: #sealed
[Verified]: #verified
[Failed Verification]: #failed-verification
[Not Known]: #not-known
[Proof Invalid]: #proof-invalid
[Record Set Mismatch]: #record-set-mismatch
[Mechanism Verification Unavailable]: #mechanism-verification-unavailable
[Invalid Request]: #invalid-request
[Mechanism Failure]: #mechanism-failure
[Storage Failure]: #storage-failure
[State Unavailable]: #state-unavailable

---

## Standards references

Tamper Evidence is a foundational compliance primitive with deep cryptographic and regulatory anchoring:

- **ISO/IEC 27001 clause A.12.4 (Logging and Monitoring)** — the International Organization for Standardization / International Electrotechnical Commission information-security baseline for log integrity. The atom's no-silent-rewrite guarantee is the structural form.
- **FIPS 180-4 (Secure Hash Standard)** — a Federal Information Processing Standard (mandatory US government computing standard); the cryptographic foundation for hash-chain and Merkle-tree mechanisms. The atom is hash-function-neutral; FIPS 180-4 is the canonical family anchor.
- **RFC 3161 (Time-Stamp Protocol)** — the IETF standard for trusted timestamping. Qualified RFC 3161 timestamps are the canonical external-anchoring mechanism for time-of-seal verifiability under eIDAS and elsewhere.
- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-92 (Guide to Computer Security Log Management)** — names log-integrity protection as a baseline requirement; tamper-evidence is the structural mechanism.
- **21 CFR Part 11 — FDA electronic records and electronic signatures** — requires electronic records to be protected against unauthorized modification and to bear evidence of any change. Composes with Actor Identity for the attribution of any modification (which Part 11 also requires).
- **DoD 5015.02-STD — Design criteria for electronic records management software** — requires records-management systems to protect against unauthorized alteration of records and audit data.
- **GDPR (EU General Data Protection Regulation) Article 32 (Security of Processing)** — names integrity as a property of processing that controllers must ensure with appropriate technical measures.
- **W3C Verifiable Credentials Data Model** — a standards-track format for tamper-evident attestations, with cryptographic proofs that travel with the data.
- **Certificate Transparency (RFC 9162)** — a worked public Merkle-tree append-only (records can be added but never changed or deleted) log; the canonical real-world deployment of public, verifiable, externally-anchored tamper-evidence at internet scale.
- **Git's commit DAG** — the most widely-deployed open-source reference for hash-chain tamper-evidence. Every modern source-control system inherits the design.
- **PCI DSS Requirement 10 (Track and monitor all access to network resources and cardholder data)** — including 10.5 (secure audit trails so they cannot be altered). The atom is the structural form.
- **eIDAS Regulation (EU 910/2014)** — qualified electronic timestamps carry presumed evidentiary effect; the atom's [Anchoring Instant] is the operational anchor.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of composing external anchoring, actor attribution, time-anchor, and mechanism-registry concepts as separate atoms.
- **Eiffel's design-by-contract** — preconditions on seal; named rejection and verification reasons.
- **Cryptographic hash-function literature** (Merkle's tree commitments, the Merkle-Damgård construction, the SHA family) — the foundational mechanism for tamper-evident commitments.
- **Tamper-evident logging literature** (Schneier and Kelsey, *Secure Audit Logs to Support Computer Forensics*, 1999) — the formal framing of hash-chain audit logs as forensically-useful primitives.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: not applicable — vote no 2026-06-03
last gate: 2026-10-21 — Final Critique 5, the council's first round on the page and the first on its Store-contract rewrite (32e8a98), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS MiniMax M3.1 Flash, Linus MiMo V2.6 Flash), each handed only the round's reading set, three passes on one text (frozen at 97a873e); the round rests on three counted passes — foundational count 8 after triage (20 reports, 12 sent down to refining; 3 refining reports raised), all Kind A: Invariant 2.1 obliged proof-invalid for the wrong record set Operation 16 answers record-set-mismatch, and for an altered one the mechanism could not check; record set match left identity or content to the host, so a host comparing content reported tampering as a caller error, and Invariant 3.1 was false of every tampered record set; Invariant 7.1 forbade the transient mechanism-verification-unavailable beside an earlier verified; the verification set left out the record set match the verdict rules read; a failed read of the seal store had no answer the page allowed; the contract claimed every sound mechanism, a chain keyed by a shared secret among them, which no auditor can check from the records; no rule obliged verified for a proof that holds; and two conformance checks read deployment declarations the records do not carry; 27 refining reports, 7 rhetorical reports; not clean; every foundational finding cured in place; 2026-06-18 — Final Critique 4, fresh reader — clean

open:
- 2026-10-21-a · refining · Term seam; Operation 1, 9, 22 · the cryptographic material the host injects is declared nowhere (GRACE-lang Closed vocabulary 4), the seam names neither the record set [Seal] computes over nor the proof and the mechanism's answer the transition records, and whether the host computes the proof and runs the seal check at the seam or hands the transition a primitive the transition calls is unstated against Execution Contract Logic confinement 1 and 3 → declare the cryptographic material; name each value the host injects; say where each computation runs, as Actor Identity's 2026-10-20-a asks of its own
- 2026-10-21-b · refining · Operation 7, 8; Term mechanism credential · Operation 7 tests "the mechanism credential is absent" in no admitted condition form, while the admitted form, EQUALS blank, takes in the empty credential Operation 8 accepts (GRACE-lang Term blank, Earned vocabulary 7), and a credential carrying only whitespace has no rule → one declared term for the credential's three blank states, each with its answer
- 2026-10-21-c · refining · Invariant 2.2, 2.3; Term qualifiers · deprecated is declared nowhere, Term qualifiers declaring sound alone, and Invariant 2.3 obliges a re-seal with no trigger, bound or owner → declare deprecated or write the rule in sound; name the re-seal's trigger and owner
- 2026-10-21-d · refining · State 6, 7; Operation 8; Invariant 3.2, 4.2, 8.1, 9.2 · deletion surface, revocation surface, unkeyed mechanism, another record set, the host's state, the atom's contract and the evidence set carry rules and are declared nowhere → declare each, or write each rule in declared names
- 2026-10-21-e · refining · Examples, source control; Identity 2, 3 · the Git example names a content-derived commit hash as [Evidence Id], which the host does not allocate, and a content-addressed tree as [Record Set Reference], which a tampered tree no longer names, so tampering would read as a different record set → say what the analogy keeps and what it does not
- 2026-10-21-f · refining · Summary; Identity 8; Concurrent seal 1 · seal names both the action [Seal] and the evidence it records → one name each
- 2026-10-21-g · refining · Operation 28; State 4 · [Read] answers anchoring instant for every evidence, while State 4 lets an evidence carry none → answer it where the evidence carries one
- 2026-10-21-h · refining · Examples, financial; Operation 4; Non-goal 3 · the chain tail is anchored hourly and the token recorded on a daily seal, while Operation 4 carries only an anchor made at seal time and Non-goal 3 forbids anchoring once the seal lands → anchor at seal time, or leave the hourly anchors to External Anchoring
- 2026-10-21-i · refining · Verification caching 2 · what a cached result is keyed by is unstated, so two conforming caches drop a result at different moments → name the key
- 2026-10-21-j · refining · acronyms · W3C, DAG, RFC, IETF, FDA and DoD are not spelled out at first use (Pass 1's acronym check) → spell each out
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/tamper-evidence.md`; the rounds and the migration that got it here are in [its history](./tamper-evidence.hist.md).

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the seal store supplied under Execution Contract Store 1, Store 3 and Store 4 (Capability requirement 2), and the four rules that restated them tombstoned to their owner — Invariant 9.3, no partial evidence on a storage-failure, and Seal atomicity 1, a seal atomic, to Store 1; Seal atomicity 2, no evidence left by a crash with a proof the mechanism did not produce, to Store 1 and Store 3; Seal atomicity 3, the deployment owning the seal store's durability, to Store 3; rules 106 to 103. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. Discarding the proof on a storage-failure stays (Operation 11): it binds the proof outside the store as well. What the atom does for its domain is unchanged.

- **2026-10-21 — Record set match decides which record set and the seal check its content; the contract covers mechanisms checkable from the verification set; a failed read answers on every action.** *Chose:* record set match answering yes for the named record set whatever its content, the content left to the seal check (Term record set match), so a change is detected where the right records are presented and the check can run (Invariant 2.1), the proof is bound to the record set presented at [Seal] (Invariant 3.1), two verifications answer alike unless one answers mechanism-verification-unavailable or state-unavailable (Invariant 7.1), and the verification set names the record set match the verdict rules read; verified obliged for the right records under a seal check that holds (Operation 19, Operation 33); the contract held for every sound mechanism whose verification function consults no source outside the verification set, so a chain keyed by a shared secret is outside it and the payments example is a signed hash chain (Invariant 8.1); state-unavailable on all three actions where the read of the seal store fails, the Execution Contract's Step 1 failure (Operation 31, Term store read), with [Seal]'s refusals in one stated order, the store read first (Operation 32, Term seal refusal order); the composing patterns and the mechanism read from the deployment's own declaration (External check 3, External check 4, Capability requirement 3). *Over:* a match a host could decide by content, which reports tampering as a caller error; detectability and binding rules that the page's own wrong-record and altered-record examples break; no answer obliged for a proof that holds; a neutrality claim taking in mechanisms no auditor can check from the records; a read forbidden to refuse a store it cannot read; conformance checks reading what the records do not carry. *Because:* Final Critique 5 found each a divergence between conforming builds or a rule no conforming build could keep, and the page already held the line: its Summary rests the guarantee on what is detectable from the records alone, and its Intent names only mechanisms a verifier checks without a secret; Actor Identity's fifth round cured a failed store read, a one-way verified rule and a declaration-reading check the same way. Compositions affected: Audit Trail, which presents its seals to this atom, routes state-unavailable from [Verify] and [Read] when its round reads them.

NOTE: End of Tamper Evidence.
