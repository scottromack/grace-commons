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

Tamper Evidence answers the question "how do I know these records weren't altered after the fact?" It works through seals — permanent records that attach a cryptographic proof to the records they cover. A proof is a mathematical fingerprint of a set of records as they stood at a moment in time. Sealing computes that fingerprint and stores it. Verifying re-computes the fingerprint over the original records and compares. If anything was changed, the fingerprint no longer matches, and the check fails. The crucial limit is that this detects tampering rather than preventing it. It cannot stop someone with full write access from altering both the records and the seal. But it makes any alteration visible to anyone holding the original records and the seal. The pattern is deliberately neutral about the cryptographic method used, as long as the guarantee holds: any change since sealing is detectable from the records alone. This is the mechanism behind sealing financial transaction journals, medical-record change logs, and payment-card access logs so auditors can confirm nothing was rewritten — and behind Git's commit history, the most widely deployed example. It does not, on its own, prevent tampering, prove who created the seal, or guarantee the seal's timestamp. Each of those is a separate pattern layered on top.

---

## Intent

WHY:
A regulated record set must answer one question from the records alone: *have these been altered since they were written?* Procedure cannot answer it — a runbook, an access-control list and a developer's word are all claims about the past made by the party under audit. A cryptographic commitment can: seal the record set, keep the proof, and any later modification is detectable by re-running the mechanism's own verification over the records the verifier holds. This atom is that commitment and nothing more. It is mechanism-neutral by design — a hash chain, a Merkle tree with a signed root, a timestamp token and a blockchain anchor satisfy one contract — and it is honest about its ceiling: it produces evidence of tampering, never prevention of it. An adversary with write access to both the records and the seals rewrites both. What defeats that is an anchor outside the adversary's reach, and that is a composing pattern's, named here and not overclaimed.

## Structure

### Identity model

```text
Identity 1: The atom MUST identify evidence by the evidence_id.
Identity 2: The host MUST allocate an evidence_id at the atom's seam.
Identity 3: The transition MUST NOT allocate an evidence_id.
Identity 4: The business caller MUST NOT supply an evidence_id.
Identity 5: The atom MUST NOT reuse an evidence_id.
Identity 6: The atom MUST NOT identify evidence by the record_set_ref.
Identity 7: The atom MUST NOT identify evidence by sealed_at.
Identity 8: Two seals over one record set MUST carry two evidence_ids.
```

Terms › `evidence`: one recorded commitment over a record set — an [Evidence]; carries the proof and nothing that changes.

Terms › `evidence_id`: the opaque value naming one evidence — an [Evidence Id].

Terms › `record_set_ref`: the opaque reference naming what was sealed — a [Record Set Ref]; the host owns what a record set is.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading, the evidence_id, the cryptographic material and record set match here.

Terms › `transition`: the atom's evaluation of one call against the seal store, as `execution-contract.md` §Logic confinement declares it.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

WHY:
Identity by record set would collapse a legitimate re-seal — a stronger mechanism after a deprecation, a second anchor over the same records — into an overwrite, and identity by time would lose two concurrent seals (Identity 6–8). Each evidence is its own audit record, so an auditor reconstructs a record set's integrity history as a sequence of them.

### State

```text
State 1: EVERY evidence MUST stand in sealed.
State 2: The atom MUST NOT offer a transition out of sealed.
State 3: EVERY evidence MUST carry evidence_id, record_set_ref, proof and sealed_at.
State 4: An evidence MAY carry anchored_at.
State 5: The atom MUST NOT store the mechanism_credential.
State 6: The atom MUST NOT offer a deletion surface.
State 7: The atom MUST NOT offer a revocation surface.
```

Terms › `sealed`: the atom's one state — recorded, and nothing further to become.

Terms › `proof`: the artifact the mechanism produced over the record set — a [Proof]: a hash chain, a Merkle root, a signed root, a timestamp token, a blockchain transaction id, or a composite.

Terms › `sealed_at`: the wall-time instant the evidence was recorded, stamped from the injected now — a [Sealed At].

Terms › `anchored_at`: the time an external anchor recorded at seal time — an [Anchored At]; absent where the mechanism anchors nothing.

Terms › `mechanism_credential`: the material the mechanism consumes to produce the proof — a [Mechanism Credential]; keying material for a keyed mechanism, and an empty value — present, carrying nothing — for an unkeyed one. Absent is not empty: Operation 7 refuses the argument that was never supplied, Operation 8 accepts the one supplied with no content.

Terms › `evidence field`: `evidence_id` | `record_set_ref` | `proof` | `sealed_at` | `anchored_at`.

WHY:
One state, no transitions out, no deletion and no revocation: an evidence that could be withdrawn would prove nothing, since the party who wanted the records rewritten is the party who would withdraw it (State 2, State 6, State 7, Invariant 9.1). The credential is consumed and never stored — key storage, rotation and recovery are a separate concept, and an atom that kept the key would be the weakest place in the deployment to keep it (State 5).

### Operations

```
seal(record_set_ref, mechanism_credential) → evidence_id | rejected(invalid-request | mechanism-failure(unreadable-records | keying-precondition | anchor-unreachable) | storage-failure)
verify(evidence_id, original_record_set) → verified | failed-verification(proof-invalid | record-set-mismatch | mechanism-verification-unavailable) | not-known
```

```text
Operation 1: [Seal] MUST compute the proof over the record set from the mechanism_credential.
Operation 2: [Seal] MUST record EXACTLY ONE evidence per successful call.
Operation 3: [Seal] MUST stamp sealed_at from the injected now.
Operation 4: IF the mechanism anchors at seal time THEN [Seal] MUST carry anchored_at into the evidence.
Operation 5: [Seal] MUST consume the mechanism_credential.
Operation 6: IF record_set_ref is blank THEN [Seal] MUST answer invalid-request.
Operation 7: IF the mechanism_credential is absent THEN [Seal] MUST answer invalid-request.
Operation 8: [Seal] MUST accept an empty mechanism_credential for an unkeyed mechanism.
Operation 9: IF the mechanism cannot compute the proof THEN [Seal] MUST answer mechanism-failure.
Operation 10: IF the seal store refuses the write THEN [Seal] MUST answer storage-failure.
Operation 11: [Seal] MUST discard the proof on storage-failure.
Operation 12: [Seal] MUST NOT alter a recorded evidence.
Operation 13: [Verify] MUST take the original_record_set.
Operation 14: [Verify] MUST answer EXACTLY ONE OF verified, failed-verification, not-known.
Operation 15: IF the evidence NOT EXISTS THEN [Verify] MUST answer not-known.
Operation 16: IF the evidence EXISTS AND record set match = no THEN [Verify] MUST answer record-set-mismatch.
Operation 17: IF record set match = yes AND seal check = unavailable THEN [Verify] MUST answer mechanism-verification-unavailable.
Operation 18: IF record set match = yes AND seal check = failed THEN [Verify] MUST answer proof-invalid.
Operation 19: [Verify] MUST answer verified ONLY IF seal check = held.
Operation 20: [Verify] MUST NOT write.
Operation 21: The host MUST read the clock at the atom's seam.
Operation 22: The host MUST supply the cryptographic material at the atom's seam.
Operation 22a: The host MUST supply record set match at the atom's seam.
Operation 22b: The atom MUST NOT judge record set match.
Operation 23: The transition MUST NOT read a clock.
Operation 24: The transition MUST NOT mint entropy.
Operation 25: The business caller MUST NOT supply sealed_at.
Operation 26: The implementation MUST own the mechanism.
```

Terms › `record set match`: `yes` | `no` — the host's answer, injected at the seam, to whether the presented original_record_set is the record set the evidence's record_set_ref names. The atom cannot judge it: record_set_ref is opaque and Identity rules forbid interpreting it, so the party that resolved the reference at seal time is the party that answers here (CR-13).

Terms › `seal check`: `held` | `failed` | `unavailable` — the mechanism's verification function, run over the presented record set against the recorded proof. Named for the seal because [Actor Identity](./actor-identity.md) declares its own `proof check` over an attestation, and [Audit Trail](../compositions/audit-trail.md) wires both: one name for two judgments is a collision a composition cannot resolve (CR-13).

Terms › `original_record_set`: the record set a verifier presents at [Verify] — an [Original Record Set]; the proof commits to content, so the verifier holds the content.

Terms › `verification set`: the evidence's own fields together with the presented original_record_set — and, where the mechanism's verification function consults one, that mechanism's own external anchor; everything [Verify] is allowed to read, and nothing else.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the seal store |
|---|---|---|---|
| [Seal] | credential and reference well-formed, mechanism computes, store accepts | `evidence_id` | one evidence lands in [Sealed] (Operation 1, Operation 2) |
| [Seal] | blank reference, or absent credential | [Invalid Request] | none (Operation 6, Operation 7) |
| [Seal] | mechanism cannot compute the proof | [Mechanism Failure] | none (Operation 9) |
| [Seal] | store refuses the write | [Storage Failure] | none — the proof is discarded (Operation 10, Operation 11) |
| [Verify] | no evidence under that id | [Not Known] | none — the call reads (Operation 15, Operation 20) |
| [Verify] | evidence found, wrong records presented | [Record Set Mismatch] | none (Operation 16) |
| [Verify] | right records, verification service unreachable | [Mechanism Verification Unavailable] | none (Operation 17) |
| [Verify] | right records, proof does not hold | [Proof Invalid] | none (Operation 18) |
| [Verify] | right records, proof holds | [Verified] | none (Operation 19) |

WHY:
The four verify outcomes are kept apart by their conditions rather than by the order the rules are written in (`GRACE-lang.md` Hard invariant 15): `not-known` is an id miss and nothing else; `record-set-mismatch` is a caller holding the wrong records; `mechanism-verification-unavailable` is transient and worth retrying; `proof-invalid` is the structural signal of tampering, and a deployment that collapses it into any of the other three has lost the only alarm this atom raises (Operation 15–19). [Verify] needs the records because the proof commits to content — the asymmetry from [Actor Identity](./actor-identity.md), whose verification needs only the attestation and the registry (Operation 13, Invariant 4.1).

### Invariants

- **Invariant 1 — Evidence immutability.**
  ```text
  Invariant 1.1: EVERY evidence field of a recorded evidence MUST NOT change.
  ```
- **Invariant 2 — Detectability of tampering.**
  ```text
  Invariant 2.1: IF the presented record set differs from the sealed record set THEN [Verify] MUST answer proof-invalid.
  Invariant 2.2: A deployment MUST NOT rest detectability on a deprecated mechanism.
  Invariant 2.3: A deployment MUST re-seal a record set under a sound mechanism.
  ```
  WHY: the contract is detectability from the records alone, given the proof and the originating records — and it holds exactly as far as the mechanism does. A mechanism with a practical collision admits crafted tampering that verifies, so mechanism health is a Mechanism Registry pattern's *(forthcoming)* and re-sealing is the deployment's (Invariant 2.2, Invariant 2.3).
- **Invariant 3 — Record-set binding.**
  ```text
  Invariant 3.1: A recorded proof MUST verify against the record set the evidence's record_set_ref names.
  Invariant 3.2: A recorded proof MUST NOT verify against another record set.
  ```
- **Invariant 4 — Verification self-containment given the originating records.**
  ```text
  Invariant 4.1: [Verify] MUST consult the verification set.
  Invariant 4.2: [Verify] MUST NOT consult the host's state.
  Invariant 4.3: [Verify] MUST NOT consult a source outside the verification set.
  ```
  WHY: an RFC 3161 verification reads the timestamp authority's published certificate, which is the mechanism's dependency rather than the atom's — and it is the only admitted one (Invariant 4.1).
- **Invariant 5 — Id stability.**
  ```text
  Invariant 5.1: [Seal] MUST set the evidence_id.
  Invariant 5.2: An evidence_id MUST NOT change.
  ```
- **Invariant 6 — No id reuse.**
  ```text
  Invariant 6.1: Two evidence records MUST NOT share an evidence_id.
  ```
- **Invariant 7 — Verification consistency under a fixed record set.**
  ```text
  Invariant 7.1: Two verifications of one evidence against one record set MUST answer alike.
  ```
  WHY: an answer that differs across record-set states is detectability working, not inconsistency.
- **Invariant 8 — Mechanism opacity.**
  ```text
  Invariant 8.1: The atom's contract MUST hold for EVERY sound mechanism.
  Invariant 8.2: The atom MUST NOT read the proof's internal structure.
  ```
- **Invariant 9 — Seal store durability.**
  ```text
  Invariant 9.1: The atom MUST NOT delete an evidence.
  Invariant 9.2: The evidence set MUST NOT shrink.
  Invariant 9.3: A storage-failure MUST NOT leave a partial evidence.
  ```
  WHY: an evidence that outlives the records it commits to still proves those records existed and were intact at seal time; deleting it destroys that. Cascading purge alongside the records is the composing pattern's (Composition note 4).

## Examples

The same atom, five regulated domains, identical mechanic.

### Financial — transaction-log anchoring under SOX

A bank's settlement system seals each day's transaction journal: `seal(journal_2026-05-10, hsm_signing_key) → evidence_a91`. The mechanism is a SHA-256 (Secure Hash Algorithm, 256-bit — a standard cryptographic hash function) hash chain over the day's transactions, with the chain's tail signed by an HSM-bound (Hardware Security Module — a dedicated tamper-resistant device for keys) key. Once per hour, the chain tail is anchored to an RFC 3161 qualified timestamp authority; the authority's timestamp token is recorded as [Anchored At] on the seal. Seven years later, during a SOX (Sarbanes-Oxley Act — US financial reporting law) §404 audit, the external auditor presents the journal and `verify(a91, journal_2026-05-10) → verified` — confirming the day's transactions were not altered after the seal, with the qualified timestamp giving an upper bound on when they could have been forged.

### Healthcare — EHR change-log integrity under HIPAA and 21 CFR Part 11

A hospital EHR (Electronic Health Record — the digital patient chart system) appends every record amendment (correction, addendum, redaction) to a per-patient change log. The change log is sealed on a rolling Merkle-tree basis — each commit produces a new root and a new seal. `verify(seal, patient_change_log) → verified` confirms the log has not been silently rewritten since the seal. A correction added today is a new event in the log, not a modification of yesterday's; if anyone retroactively edited yesterday's entry, today's seal would fail verification. 21 CFR Part 11's (the US Code of Federal Regulations rule on electronic records and signatures) and HIPAA's (US Health Insurance Portability and Accountability Act) electronic-record integrity bar is satisfied structurally.

### Source control — Git's commit DAG

A developer pushes a commit. Git computes the cryptographic hash (a fixed-length fingerprint computed from data — any change to the data produces a different fingerprint) of the commit object — which includes the hash of its parent commits — and stores the object under that hash. The hash *is* the [Proof]: the commit's content, its parents, and (transitively) the entire history are committed to in one chain. `git fsck` is the verification function; tampering anywhere in the history produces a hash mismatch detectable from the repository alone. The commit DAG is a worked open-source instance of this atom — [Evidence Id] = commit hash, [Record Set Ref] = the commit's tree and parents, [Proof] = the chained hashes, [Sealed At] = the commit timestamp. Linus Torvalds built the world's most widely-deployed Tamper Evidence implementation; the atom names what it does in domain-neutral terms.

### Legal — document notarization under RFC 3161 trusted timestamping

A law firm timestamps an executed contract via a qualified Time-Stamp Authority (TSA — a trusted third party that issues signed proofs that data existed at a given time). The mechanism is RFC 3161: a hash of the contract is submitted to the TSA; the TSA returns a signed TimeStampToken binding the hash to a trusted time. The token *is* the [Proof]; [Anchored At] is set from the TSA's timestamp. Any future dispute — opposing counsel claims the contract was modified post-signing — is resolved by `verify(evidence, contract_pdf) → verified | failed-verification(proof-invalid)`. eIDAS Regulation (Electronic Identification, Authentication and Trust Services — the EU regulation governing electronic signatures and timestamps) gives qualified electronic timestamps presumed evidentiary effect across the EU.

### Payments — PAN-handling audit under PCI DSS

A payment processor seals each day's cardholder-data access log: `seal(pan_access_log_2026-05-10, processor_key) → evidence_p41`. The mechanism is an HMAC-SHA-256 chain — each entry's MAC (Message Authentication Code) includes the previous entry's MAC and the entry's content. PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for cardholder data; here applied to PAN, the Primary Account Number) Requirement 10.5 mandates audit-log integrity; the seal is the structural form. A QSA's (Qualified Security Assessor — a PCI-certified auditor) annual assessment runs `verify` over the prior year's daily logs; any tampering — whether to hide a cardholder-data exfiltration or to forge access for a fraudulent dispute — is detected from the logs themselves.

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

`verified` confirms the backup matches what was sealed; `proof-invalid` on the altered version confirms the alteration occurred after [Sealed At]. The forensic window is bounded by the two seal timestamps.

**Wrong record set presented — [Record Set Mismatch].** A verifier accidentally presents the wrong day's journal to a seal:

```
verify(evidence_id: "evidence_a91", original_record_set: journal_2026-05-11)
→ failed-verification(record-set-mismatch)
```

The presented record set does not match the [Record Set Ref] the [Evidence] was made over. This is not a tampering signal — it is a caller error, structurally distinguishable from `proof-invalid`.

### Regulated adversarial scenarios

Three scenarios the atom must survive in regulated contexts:

- **Regulator integrity audit.** A regulator asks *"how do I know these records weren't rewritten after the fact?"* The auditor takes the original record set from the host, the [Evidence Id] from the seal store, and runs [Verify] — independently, with their own implementation of the mechanism's verification function. [Verified] is a structural guarantee, not a procedural promise. Where the [Evidence] carries [Anchored At] from a qualified TSA outside the host's control, the audit additionally establishes an upper bound on the time the records could have been forged. Invariants 2 and 3 are the structural answer.
- **Breach forensics — "when was the record altered?"** An incident responder discovers anomalous data. They query the seal store for every [Evidence] whose [Record Set Ref] covers the suspect records, in [Sealed At] order. Running [Verify] on each, they identify the most recent [Evidence] that returns [Verified] (records intact at that time) and the next [Evidence] that returns [Failed Verification] (records altered between those two seal times). The forensic window is bounded by the seal cadence; tighter cadence narrows the window. The atom does not name *who* altered the records — that is a separate Forensic Attribution composition — but it names *when* with the resolution of the seal schedule.
- **False-tamper-claim disproof.** A counterparty claims *"you modified the contract after I signed."* The system presents the contract and the [Evidence]; `verify(evidence, contract) → verified`. The claim is structurally disproven against the unmodified record set the system retains; the counterparty's burden shifts to producing a different record set they claim is the authoritative one, at which point the dispute becomes about *which version is canonical* rather than *whether it was tampered with*. The atom answers the second question; the first belongs to the Content Lock or Document Versioning composing pattern.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the seal store and the originating record sets, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```text
Check 1.1: An auditor MUST reconstruct EVERY seal from the evidence's stored fields (Invariant 1.1, State 3).
Check 1.2: An auditor MUST NOT need state beyond those fields and the originating record set (Invariant 4.1, Invariant 4.2).
Check 2.1: An auditor MUST verify an evidence with the auditor's own implementation of the mechanism's verification function (Invariant 4.1, Operation 13).
Check 2.2: An auditor MUST NOT need privileged access to the system to verify (Invariant 4.2).
Check 3.1: An auditor MUST confirm that a single-byte change to the record set yields proof-invalid (Invariant 2.1, Operation 18).
Check 4.1: An auditor MUST read verified, failed-verification and not-known as three distinct answers (Operation 14).
Check 4.2: An auditor MUST read record-set-mismatch, proof-invalid and mechanism-verification-unavailable as three distinct reasons (Operation 16, Operation 17, Operation 18).
Check 5.1: An auditor MUST bound a detected tampering between two adjacent anchored_at times WHERE anchors EXIST (Invariant 2.1, Identity 8).
Check 5.2: An auditor MUST read a bound between two adjacent sealed_at times as best-effort (Non-goal 8).
Check 6.1: An auditor MUST identify which composing patterns a deployment wired in (Composition note 1).
Check 6.2: An auditor MUST read the deployment's mechanism (Operation 26).
```

### External checks

```text
External check 1: An auditor MUST read the mechanism's health from the Mechanism Registry's evidence (Invariant 2.2, Invariant 2.3).
External check 2: An auditor MUST read the anchor's trust from the anchoring authority's own records (Non-goal 1, Non-goal 2).
```

NOTE: mechanism health and anchor trust are what the seal store does not carry — the External check family v0.35 declares exists for exactly this (CR-13).

NOTE: EVERY check names the rule the check tests. The bar is the regulator's question — *can you prove these records were not altered?* — answered from the records and the proof, never from a runtime claim.

## Non-goals

```text
Non-goal 1: The atom MUST NOT prevent tampering.
Non-goal 2: A deployment needing reach beyond detection MUST compose an external-anchoring pattern.
Non-goal 3: The atom MUST NOT anchor a proof once the seal lands.
Non-goal 4: The atom MUST NOT choose the mechanism's hash function.
Non-goal 5: The atom MUST NOT choose the mechanism's signature scheme.
Non-goal 6: The atom MUST NOT bind a proof to a named actor.
Non-goal 7: A deployment needing an attributable seal MUST compose [Actor Identity](./actor-identity.md).
Non-goal 8: The atom MUST NOT vouch for the clock.
Non-goal 9: A deployment whose time of seal carries legal force MUST compose a trusted-timestamping pattern.
Non-goal 10: The atom MUST NOT purge an evidence alongside purged records.
Non-goal 11: The atom MUST NOT define a record set.
Non-goal 12: The host MUST present a record set alike at seal time and at verify time.
Non-goal 13: The atom MUST NOT deduplicate two seals over one record set.
Non-goal 14: A pattern needing one seal per record set per cadence MUST own that coordination.
```

WHY:
The ceiling is stated rather than implied: an adversary with write access to the records and to the seal store rewrites both and the atom cannot tell, which is why anchoring outside that adversary's reach is named here and owned elsewhere (Non-goal 1, Non-goal 2). Attribution is the same shape — where the credential is an actor's private key the proof itself carries the binding, and where it is a system key the evidence says only that the system asserted the proof (Non-goal 6, Non-goal 7). Clock access is confined to the seam; clock honesty is a deployment property, and the verifiable form of *when* is an anchor from a qualified authority (Non-goal 8, Non-goal 9).

Where the atom breaks down: when the host cannot supply a record_set_ref whose contents are reproducibly addressable at verify time; when the chosen mechanism commits to the records' identity and not their content; when the proof store and the record store share an adversary with write access to both and no external anchor exists.

## Edge cases

### Retention coupling

```text
Retention coupling 1: A purged record set MUST leave [Verify] unable to hold.
Retention coupling 2: A composing pattern MUST own the cascading purge of an evidence alongside the records.
Retention coupling 3: A deployment MUST NOT read a seal over destroyed records as proof of the records' content.
```

WHY:
Tamper-evidence outlives the records only as far as the records are retained. Once [Retention Window](./retention-window.md) purges them, verification has nothing to re-present and answers `record-set-mismatch`, or the host's lookup answers nothing at all — a seal in that state is structurally meaningless and should leave in step with what it sealed.

### Concurrent seals

```text
Concurrent seal 1: Two seals over one record set MUST stand as independent evidence.
Concurrent seal 2: The atom MUST NOT order two seals over one record set.
```

### Atomicity of a seal

```text
Seal atomicity 1: The implementation MUST make [Seal] atomic.
Seal atomicity 2: A crash inside [Seal] MUST NOT leave a recorded evidence with a proof the mechanism did not produce.
Seal atomicity 3: The deployment MUST own the durability of the seal store.
```

WHY:
The atom's contract assumes the evidence record is durable and the write is all-or-nothing; where the store can be silently rewritten, the evidence is only as strong as the store, which is the ceiling Non-goal 1 states.

### Verification caching

```text
Verification caching 1: An implementation MAY cache a verification result.
Verification caching 2: An implementation MUST NOT cache a verification result across two record-set states.
```

WHY:
[Verify] is read-only and deterministic under a fixed record set (Invariant 7.1), so a cache is sound exactly while the records do not move — and a cache that outlives a change reports *verified* over tampered records, which is the one answer this atom must never give wrongly.

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: An integrity-relevant [Event Log](./event-log.md) instance MUST compose this atom.
Composition note 3: A deployment needing an attributable seal MUST supply an actor's credential as the mechanism_credential.
Composition note 4: A composing pattern MUST own the decision to purge an evidence alongside the records the evidence commits to.
Composition note 5: This atom's invariant numbers MUST stand as a frozen contract surface.
```

WHY:
Sealing an Event Log periodically — or per append, for the strongest cadence — is what gives the bare log the integrity property it declines to carry ([Event Log](./event-log.md) declines tamper-evidence and names this atom; Composition note 2). This atom completes the regulated-audit stack: [Event Log](./event-log.md), [Actor Identity](./actor-identity.md), [Retention Window](./retention-window.md) and this one, wired by [Audit Trail](../compositions/audit-trail.md), which cites this atom's Invariants 1, 3, 4, 8 and 9 by number — so the numbers are a frozen contract surface, additive growth is forward-compatible, and a renumber re-passes every composition that cites one (Composition note 5). That a writer must not renumber is the grammar's rule and stays there (`GRACE-lang.md` Hard invariant 26); what is local — and what this note owns — is that these particular numbers are cited from outside. Forthcoming: External Anchoring, Trusted Timestamping, Mechanism Registry.

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern, a writer); a business caller; a verifier; an auditor; an adversary; the mechanism; the seal store; an evidence; a seal; a verification.

Terms › `records`: `evidence` — one commitment, carrying `evidence_id`, `record_set_ref`, `proof`, `sealed_at` and, where the mechanism anchors, `anchored_at`.

Terms › `record verbs`: judge, identify, allocate, supply, reuse, carry, stand, order, offer, store, compute, record, stamp, consume, accept, answer, discard, alter, take, read, mint, own, write, change, verify, consult, set, share, hold, delete, shrink, leave, reconstruct, need, confirm, bound, prevent, compose, anchor, choose, bind, vouch, purge, define, present, deduplicate, rest, re-seal, make, cache, declare, renumber, add, identify.

Terms › `value sets`: seal answers = evidence_id | rejected(invalid-request | mechanism-failure(unreadable-records | keying-precondition | anchor-unreachable) | storage-failure). verify answers = verified | failed-verification(proof-invalid | record-set-mismatch | mechanism-verification-unavailable) | not-known. `record set match` = yes | no. `seal check` = held | failed | unavailable. `evidence field` = evidence_id | record_set_ref | proof | sealed_at | anchored_at. evidence state = sealed.

Terms › `bounds`: empty.

Terms › `cadences`: empty — a seal cadence is the composing pattern's (Composition note 1).

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-11); `sound` — a mechanism with no known practical collision or forgery attack.

Terms › `terms`: `now`, `evidence`, `evidence_id`, `record_set_ref`, `seam`, `transition`, `business caller`, `sealed`, `proof`, `sealed_at`, `anchored_at`, `mechanism_credential`, `evidence field`, `record set match`, `seal check`, `original_record_set`.

#### Evidence

The record this atom defines: a permanent, verifiable seal over a record set — cryptographic evidence that the set has not been altered since its authoritative creation. It is produced by [Seal] and carries its [Evidence Id], [Record Set Ref], [Proof], [Sealed At], and optional [Anchored At]; nothing about it changes once recorded, and the atom offers no surface to revoke, modify, or re-anchor it.

Kind: Type

#### Seal

The behavior a composing pattern invokes at seal time to record a new [Evidence] over a record set. It consumes the supplied [Mechanism Credential] to compute the [Proof], stamps [Sealed At] (and [Anchored At] if the mechanism anchors synchronously), and returns the [Evidence Id]. It always creates a new record — it never modifies an existing one — and never persists the [Mechanism Credential].

Kind: Operation

#### Verify

The read-only behavior an auditor or composing pattern invokes to confirm a recorded [Evidence], by id, against a presented record set. It re-runs the mechanism's verification function over the [Original Record Set] against the stored [Proof] and returns [Verified], [Failed Verification], or [Not Known]. It changes nothing. Unlike Actor Identity's verify, it requires the originating record set as input, because the [Proof] commits to the records' content.

Kind: Operation

#### Evidence Id

The opaque, immutable identity of an [Evidence], host-allocated at the I/O seam on [Seal] and never reused. The [Record Set Ref], [Proof], [Sealed At], and [Anchored At] are properties of the [Evidence], not its identity.

Kind:     Field
Field of: Evidence
Projects: evidence_id

#### Record Set Ref

The opaque reference to *what* the [Evidence] commits to — the record set the [Proof] is computed over. The atom does not interpret it; the host pattern defines what a record set is and how to present it to [Verify] later. Set on [Seal], immutable thereafter.

Kind:     Field
Field of: Evidence
Projects: record_set_ref

#### Proof

The cryptographic artifact that commits to the record set's content — a hash chain, Merkle root, signed root, RFC 3161 timestamp token, blockchain transaction id, or composite. Computed by [Seal] from the [Mechanism Credential] and the injected cryptographic material, stored on the [Evidence], and the thing [Verify] re-checks. Set on [Seal], immutable thereafter.

Kind:     Field
Field of: Evidence
Projects: proof

#### Sealed At

The wall-time the [Evidence] was recorded, stamped from the host-injected [Now] on [Seal]. Immutable thereafter; best-effort, since clock quality is a deployment concern.

Kind:     Field
Field of: Evidence
Projects: sealed_at

#### Anchored At

The wall-time of an external anchor, present only when the chosen mechanism produced one synchronously at seal time (for example, an RFC 3161 timestamp authority called during [Seal]). Set on [Seal] if produced, immutable thereafter, and absent otherwise. Later, asynchronous anchoring belongs to a separate External Anchoring composition.

Kind:     Field
Field of: Evidence
Projects: anchored_at

#### Mechanism Credential

The opaque material the chosen mechanism supplies to [Seal] to produce the [Proof] — keying material for keyed mechanisms, possibly empty or a configuration handle for unkeyed ones. It is *consumed* per call — used to compute the [Proof] and then discarded — and never persisted under this name (or any name) by the atom. It is the only caller-supplied secret.

Kind:         Parameter
Parameter of: Seal
Projects:     mechanism_credential

#### Original Record Set

The originating record set the verifier presents to [Verify], re-checked against the stored [Proof] to detect modification. It is supplied per call and not stored under this name; the asymmetry from Actor Identity's verify is that this content must be re-presented, because the [Proof] commits to the records' content.

Kind:         Parameter
Parameter of: Verify
Projects:     original_record_set

#### Now

The current wall-time reading [Seal] stamps [Sealed At] from, supplied to the pure transition by the host at the I/O seam (never read inside the transition, never supplied by the business caller).

Kind:         Parameter
Parameter of: Seal
Projects:     now

#### Sealed

The atom's single stable state: an [Evidence] that has been recorded. There are no transitions out of it — the atom has no surface to revoke, invalidate, modify, or re-anchor an [Evidence] once recorded.

Kind:      Member
Member of: the evidence state
Role:      Outcome

#### Verified

The outcome [Verify] returns when the stored [Proof] checks out against the presented [Original Record Set] under the chosen mechanism's verification function. It is the structural confirmation that the records were not altered after [Sealed At] (conditional on a cryptographically sound mechanism).

Kind:      Member
Member of: the Verify outcome
Role:      Outcome
Projects:  verified

#### Failed Verification

The outcome [Verify] returns when the [Evidence] exists but does not verify, carrying a reason — [Proof Invalid], [Record Set Mismatch], or [Mechanism Verification Unavailable]. Distinct from [Not Known], which is a lookup miss.

Kind:      Member
Member of: the Verify outcome
Role:      Outcome
Projects:  failed-verification

#### Not Known

The outcome [Verify] returns when the supplied [Evidence Id] references no recorded [Evidence] — a lookup miss, not a verification failure. It is exclusively an [Evidence Id] lookup miss; an absent or wrong record set routes to [Failed Verification] for reason [Record Set Mismatch] instead.

Kind:      Member
Member of: the Verify outcome
Role:      Outcome
Projects:  not-known

#### Proof Invalid

The [Failed Verification] reason returned when the mechanism's verification function, run over the presented record set against the stored [Proof], does not check out — the structural signal of tampering.

Kind:      Member
Member of: the Failed Verification reason
Role:      Outcome
Projects:  proof-invalid

#### Record Set Mismatch

The [Failed Verification] reason returned when the presented [Original Record Set] does not refer to the record set the [Evidence] was made over — a caller error, structurally distinct from [Proof Invalid] (tampering) and from [Not Known] (lookup miss).

Kind:      Member
Member of: the Failed Verification reason
Role:      Outcome
Projects:  record-set-mismatch

#### Mechanism Verification Unavailable

The [Failed Verification] reason returned when the mechanism's verification function requires an external service (for example, an RFC 3161 TSA's published certificate chain) that is unavailable at verify time — a transient, retryable condition, distinct from [Proof Invalid] and [Record Set Mismatch].

Kind:      Member
Member of: the Failed Verification reason
Role:      Outcome
Projects:  mechanism-verification-unavailable

#### Invalid Request

The refusal [Seal] returns when [Record Set Ref] contains no non-whitespace character, or [Mechanism Credential] is absent entirely. A guard rejection that fails before any store write; no [Evidence] is recorded.

Kind:      Member
Member of: the Seal rejection
Role:      Outcome
Projects:  invalid-request

#### Mechanism Failure

The refusal [Seal] returns when the mechanism cannot compute a [Proof] against the record set — the underlying records are unreadable, the keying material fails the mechanism's preconditions, or a required synchronous anchor service is unreachable. No [Evidence] is recorded.

Kind:      Member
Member of: the Seal rejection
Role:      Outcome
Projects:  mechanism-failure

#### Storage Failure

The refusal [Seal] returns when the seal store write fails after the [Proof] is computed. No partial [Evidence] is recorded and the computed [Proof] is discarded — the caller must treat it as definitive.

Kind:      Member
Member of: the Seal rejection
Role:      Outcome
Projects:  storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Evidence]: #evidence
[Seal]: #seal
[Verify]: #verify
[Evidence Id]: #evidence-id
[Record Set Ref]: #record-set-ref
[Proof]: #proof
[Sealed At]: #sealed-at
[Anchored At]: #anchored-at
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

---

## Standards references

Tamper Evidence is a foundational compliance primitive with deep cryptographic and regulatory anchoring:

- **ISO/IEC 27001 §A.12.4 (Logging and Monitoring)** — the International Organization for Standardization / International Electrotechnical Commission information-security baseline for log integrity. The atom's no-silent-rewrite guarantee is the structural form.
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
- **eIDAS Regulation (EU 910/2014)** — qualified electronic timestamps carry presumed evidentiary effect; the atom's [Anchored At] is the operational anchor.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of composing external anchoring, actor attribution, time-anchor, and mechanism-registry concepts as separate atoms.
- **Eiffel's design-by-contract** — preconditions on `seal`; named rejection and verification reasons.
- **Cryptographic hash-function literature** (Merkle's tree commitments, the Merkle-Damgård construction, the SHA family) — the foundational mechanism for tamper-evident commitments.
- **Tamper-evident logging literature** (Schneier and Kelsey, *Secure Audit Logs to Support Computer Forensics*, 1999) — the formal framing of hash-chain audit logs as forensically-useful primitives.

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

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/tamper-evidence.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, the verify precedence carried by each rule's own condition rather than by the order the rules sit in, the nine invariant numbers frozen exactly as Audit Trail cites them, Generation acceptance moved ahead of Non-goals as `spec-format.md` requires, Non-goals and Edge cases as two sections, the case table kept beside the rules. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail cites this atom's Invariants 1, 3, 4, 8 and 9 (`tools/grace/cites.py --into tamper-evidence`).

NOTE: End of Tamper Evidence.
