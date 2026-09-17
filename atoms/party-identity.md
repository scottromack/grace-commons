---
title: Party Identity
parent: Atomic Concepts
has_toc: true
toc: true
---

# Party Identity

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Party Identity is a lasting, verifiable identity record for an external party — a customer, a patient, a counterparty, a beneficial owner. It answers the question every regulated system settles before doing business: *who is this party, and has their identity been checked?*

The record keeps the party's enrollment, the full history of identity checks — each one's method, result and supporting evidence — and every later change, with who did it and why. A party stands in one of four states: unverified, verified, suspended, or closed. Closed is permanent; a party who returns after closure needs a fresh enrollment.

The central guarantee is that a party cannot stand verified without a passing check recorded since the most recent suspension. The atom enforces that itself, so a downstream process can require *a verified party* and trust that the standing rests on recorded evidence rather than a flipped flag.

The atom records the results of identity checks; it does not perform them — no document scan, no biometric match, no sanctions screen — and it does not deduplicate parties. It is distinct from [Actor Identity](./actor-identity.md), and the distinction is the shortest way to say what this atom is: an actor signs, a party is verified.

---

## Intent

Every regulated system that deals with external parties — banks onboarding customers, hospitals enrolling patients, broker-dealers establishing counterparties, employers verifying staff — must establish *who* the party is before regulated activity begins, and must keep that record through the party's whole lifecycle. The shape is constant: attributes are collected, identity is verified against external evidence, the party becomes verified, and downstream activity relies on that. When circumstances change — a sanctions match, an expired document, an investigation — the party is suspended, re-verified, and either reinstated or permanently closed.

The compliance framing is consistent across regimes. FATF Recommendations 10–12 require customer due diligence before a business relationship begins. The BSA/AML Customer Identification Program (31 CFR Part 1020) sets minimum attributes and five-year retention past the relationship's end. GDPR Article 4(1) makes the attributes collected here personal data. HIPAA requires patient identity before clinical records exist. The domain varies; the structural obligation does not.

This atom is distinct from [Actor Identity](./actor-identity.md), and not cosmetically. Actor Identity models *internal actors who authorize actions* — an employee or service account producing a proof that binds identity to a specific action. Party Identity models *external parties whose identity must be established* — the subject of the system's activity rather than its operator. Different obligations, different state machines, and they compose when one natural person is both.

This is a freestanding atom in the EOS sense: its own state machine, its own five writes and one read, and its own invariants — records are never removed, verification events are immutable and append-only, closed is absorbing, and verified rests on recorded evidence. It does not implement the verification workflow, the document check, the sanctions screen, the monitoring schedule, risk scoring or enhanced due diligence.

---

## Structure

### Identity model

```
Identity 1: The atom MUST identify a party by the party_id.
Identity 2: The atom MUST identify a verification event by the verification_id.
Identity 3: The atom MUST identify a state change event by the state_change_id.
Identity 4: The atom MUST take an assigned id from the id material the seam supplies.
Identity 5: The atom MUST NOT generate an assigned id.
Identity 6: The atom MUST NOT change an assigned id.
Identity 7: Two parties MUST NOT share a party_id.
Identity 8: Two verification events MUST NOT share a verification_id.
Identity 9: Two state change events MUST NOT share a state_change_id.
Identity 10: The atom MUST NOT identify a party by an enrollment field.
Identity 11: The atom MUST compare a reference byte-exactly.
Identity 12: The atom MUST NOT normalize a reference.
Identity 13: The atom MUST NOT confirm that a document_ref names a known document.
Identity 14: The atom MUST NOT confirm that an evidence_ref names a known evidence record.
Identity 15: The atom MUST NOT confirm that an acting reference names a known actor.
Identity 16: The atom MUST NOT match two parties as one natural person.
Identity 17: The deployment MUST route EVERY call to one store instance.
```

Term party: the record this atom holds — one external party's enrollment, verification history and state history.

Term party_id: the opaque value naming one party — a [Party Id]; assigned from the id material the seam supplies.

Term verification event: the record of one identity check — its method, result, evidence and acting reference — appended to a party and never changed.

Term state change event: the record of one transition — the prior state, the new state, the acting reference, the instant and, where the action carries one, the reason — appended to a party and never changed.

Term assigned id: party_id, verification_id OR state_change_id — every opaque name this atom assigns.

Term enrollment field: name | date_of_birth | document_type | document_ref | enrolled_at | enrolling_actor_ref — what a party carries from enrollment and never changes.

Term acting reference: enrolling_actor_ref, verifying_actor_ref, suspending_actor_ref, reinstating_actor_ref OR closing_actor_ref — the reference an action records for who acted.

Term reference: an assigned id, an acting reference, document_ref OR evidence_ref — every opaque reference this atom records.

Term store instance: one named party store a call is routed to; assigned id uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the id material here.

Term transition: the atom's evaluation of one call against the party store, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

WHY:
Identity 10 is what an external party's life requires. A [Name] changes by law, a [Document Ref] is superseded when the document is renewed, a [Document Type] differs between two enrollments of one person, and none of that makes the party a different party — so identifying by a content field would collapse attribute change with distinct-party disambiguation. The opaque id is what lets a composition link a lifetime of activity to one durable reference.

Identity 16 is the atom's sharpest refusal and the one a reader most often mistakes for a gap. Two enrollments of the same natural person produce two parties with two ids, and this atom will never say they are one. Deciding that is identity resolution — a biometric match, a document comparison, an external resolver — and building it in would make the record primitive depend on the hardest judgment in the domain. Merging is then an explicit, auditable act in a composing pattern rather than a silent collision here (Non-goal 1, Non-goal 2).

### State

```
State 1: EVERY party MUST carry party_id, EVERY enrollment field and a state.
State 2: EVERY party MUST carry a state change log.
State 3: EVERY party MUST carry a verification event list.
State 4: EVERY verification event MUST carry verification_id, verifying_actor_ref, verification_method, verification_result, evidence_ref and verified_at.
State 5: EVERY state change event MUST carry state_change_id, the prior state, the new state, an acting reference and an instant.
State 6: A state change event MAY carry a reason.
State 7: EVERY state change event a reasoned action appended MUST carry a reason.
```

WHY:
State 2 and State 3 say something a reader can miss: the histories live *on* the party rather than in stores of their own, which is why one [Read] answers a whole biography and why every acceptance check below is runnable against one surface. Each event is still individually addressable by its own assigned id, so a composing attestation binds to one suspension rather than to a position in a list.

State 6 and State 7 are the reason a reason is optional in the record and mandatory in three of four writers. A verify-driven transition carries no reason because [Verify] has no reason to carry — the evidence *is* the justification, and it is on the verification event. A suspension, a reinstatement and a closure are judgments, and a judgment with no stated basis is the thing an auditor came to read.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the id material at the seam.
Capability requirement 3: The store instance MUST serialize two party actions naming one party_id.
Capability requirement 4: The store MUST acknowledge a write ONLY IF the write commits.
Capability requirement 5: The store MUST commit an admitted verify's two records together.
Capability requirement 6: The deployment MUST canonicalize an opaque reference.
Capability requirement 7: The deployment MUST declare the length bound.
Capability requirement 8: The deployment MUST own the clock's skew.
Capability requirement 9: The deployment MUST own the clock's monotonicity.
```

WHY:
Every enrollment names an [Enrolling Actor Ref], and Capability requirement 3 is what makes the state checks mean anything under concurrency. Two calls naming one party — a suspend and a close arriving together — must resolve in some order, and the loser must see the winner's state and be refused accordingly. Without it both read *verified*, both pass their checks, and the party ends in whichever state committed last with a state change log that claims two prior states.

### Operations

```
enroll(name, date_of_birth, document_type, document_ref, enrolling_actor_ref)
  answers party_id
  refuses invalid-request | storage-failure

verify(party_id, verifying_actor_ref, verification_method, verification_result, evidence_ref)
  answers verification result
  refuses not-known | already-closed | invalid-request | storage-failure

suspend(party_id, suspending_actor_ref, reason)
  answers state_change_id
  refuses not-known | already-closed | not-verifiable | already-suspended | invalid-request | storage-failure

reinstate(party_id, reinstating_actor_ref, reason)
  answers state_change_id
  refuses not-known | already-closed | not-suspended | no-passed-verification-since-suspend | invalid-request | storage-failure

close(party_id, closing_actor_ref, reason)
  answers state_change_id
  refuses not-known | already-closed | invalid-request | storage-failure

read(query)
  answers the matching parties
  refuses invalid-query
```

Term verification result: verification_id and an optional state_change_id — what verify answers.

```
Operation 1: IF a required string input EQUALS blank THEN an action MUST answer invalid-request.
Operation 2: IF the date_of_birth parses as no calendar date THEN [Enroll] MUST answer invalid-request.
Operation 3: IF the date_of_birth EXCEEDS now THEN [Enroll] MUST answer invalid-request.
Operation 4: An admitted enroll MUST assign a fresh party_id.
Operation 5: An admitted enroll MUST record EVERY enrollment field.
Operation 6: An admitted enroll MUST record now as enrolled_at.
Operation 7: An admitted enroll MUST stand the party in unverified.
Operation 8: An admitted enroll MUST answer the party_id.
Operation 9: [Enroll] MUST NOT answer not-known.
Operation 10: IF party_id EQUALS blank THEN a party action MUST answer invalid-request.
Operation 11: IF the party_id names no party THEN a party action MUST answer not-known.
Operation 12: A party action MUST answer not-known ONLY IF party_id DOES NOT EQUAL blank.
Operation 13: IF the party's state EQUALS closed THEN a party action MUST answer already-closed.
Operation 14: IF the party's state EQUALS unverified THEN [Suspend] MUST answer not-verifiable.
Operation 15: IF the party's state EQUALS suspended THEN [Suspend] MUST answer already-suspended.
Operation 16: IF the party's state DOES NOT EQUAL suspended THEN [Reinstate] MUST answer not-suspended.
Operation 17: A party action MUST answer a state rejection ONLY IF the party_id names a party.
Operation 18: IF no fresh verification EXISTS THEN [Reinstate] MUST answer no-passed-verification-since-suspend.
Operation 19: [Reinstate] MUST answer no-passed-verification-since-suspend ONLY IF the party's state EQUALS suspended.
Operation 20: A party action MUST answer invalid-request on a field fault ONLY IF EVERY state check passes.
Operation 21: IF the verification_result differs from passed AND the verification_result differs from failed THEN [Verify] MUST answer invalid-request.
Operation 22: An admitted verify MUST append a verification event carrying a fresh verification_id.
Operation 23: An admitted verify MUST record verifying_actor_ref, verification_method, verification_result and evidence_ref on the verification event.
Operation 24: An admitted verify MUST record now as the verification event's verified_at.
Operation 25: IF the party's state EQUALS unverified AND the verification_result EQUALS passed THEN an admitted verify MUST stand the party in verified.
Operation 26: An admitted verify MUST NOT change the party's state outside the unverified-to-verified transition.
Operation 27: An admitted verify MUST answer the verification_id.
Operation 28: An admitted verify driving a transition MUST answer the state_change_id.
Operation 29: An admitted verify driving no transition MUST NOT answer a state_change_id.
Operation 30: An admitted suspend MUST stand the party in suspended.
Operation 31: An admitted reinstate MUST stand the party in verified.
Operation 32: An admitted close MUST stand the party in closed.
Operation 33: A transitioning action MUST append a state change event carrying a fresh state_change_id.
Operation 34: A transitioning action MUST record the prior state, the new state, the acting reference and now on the state change event.
Operation 35: A reasoned action MUST record reason on the state change event.
Operation 36: An admitted verify MUST NOT record a reason on a state change event.
Operation 37: A transitioning action MUST answer the state_change_id.
Operation 38: A transitioning action MUST commit EVERY record the action writes in one transition.
Operation 39: IF the store refuses the write THEN an action MUST answer storage-failure.
Operation 40: An action MUST answer storage-failure ONLY IF EVERY precondition passes.
Operation 41: A refused action MUST leave the party as the call found the party.
Operation 42: A refused [Enroll] MUST NOT record a party.
Operation 43: A refused action MUST NOT append an event.
Operation 44: The atom MUST NOT offer a party removal surface.
Operation 45: The atom MUST NOT offer an event removal surface.
Operation 46: The atom MUST NOT offer an enrollment field update surface.
Operation 47: The atom MUST NOT offer a reopen surface.
Operation 48: IF a filter axis falls outside the query axes THEN [Read] MUST answer invalid-query.
Operation 49: IF a filter value falls outside the axis's admitted values THEN [Read] MUST answer invalid-query.
Operation 50: [Read] MUST NOT ignore an unreadable filter.
Operation 51: An admitted read MUST answer EVERY matching party.
Operation 52: An admitted read MUST answer the state change log and the verification event list PER matching party.
Operation 53: An admitted read MUST answer the matching parties in insertion order.
Operation 54: An admitted read MUST answer an empty sequence where no party matches.
Operation 55: [Read] MUST NOT record a field.
Operation 56: [Read] MUST NOT answer storage-failure.
Deleted: Operation 57. The section titled Logic Confinement Principle in `execution-contract.md` owns it.
Deleted: Operation 58. The section titled Logic Confinement Principle in `execution-contract.md` owns it.
Operation 59: The atom MUST NOT accept a caller-supplied instant.
```

Term party action: [Verify] | [Suspend] | [Reinstate] | [Close] — every action naming a party by party_id, including a refused one.

Term transitioning action: a party action that changes the party's state — an admitted suspend, an admitted reinstate, an admitted close, OR an admitted verify driving the unverified-to-verified transition.

Term reasoned action: an admitted suspend, an admitted reinstate OR an admitted close — every transitioning action that carries a caller-supplied reason.

Term state: unverified | verified | suspended | closed.

Term state rejection: already-closed | not-verifiable | already-suspended | not-suspended.

Term state check: Operation 11, Operation 13, Operation 14, Operation 15, Operation 16 and Operation 18 — every check a party action makes on the party's own standing before reading the call's remaining inputs.

Term required string input: name, document_type, document_ref, verification_method, evidence_ref, reason, an acting reference OR party_id — every string an action refuses when blank.

Term fresh verification: a verification event whose verification_result EQUALS passed that follows the party's most recent suspend in insertion order, or that follows the enrollment where no suspend EXISTS.

Term evidence reference: document_ref OR evidence_ref — every pointer this atom records into the composing document store.

Term custody field: party_id | enrolled_at | enrolling_actor_ref — the fields an erasure scrub leaves, so the chain of custody outlives the personal data.

Term insertion order: the order a store instance appended its records; authoritative for this atom, where a recorded instant is advisory.

Term query axes: party_id, state and a range over enrolled_at — every filter axis [Read] admits.

Term admitted enroll: an [Enroll] call that passes every precondition and whose store write commits.

Term admitted verify: a [Verify] call that passes every precondition and whose store write commits.

Term admitted suspend: a [Suspend] call that passes every precondition and whose store write commits.

Term admitted reinstate: a [Reinstate] call that passes every precondition and whose store write commits.

Term admitted close: a [Close] call that passes every precondition and whose store write commits.

Term admitted read: a [Read] call that answers.

WHY:
Operation 10 and Operation 12 split one answer that most atoms leave joined, and the split is worth its cost. A blank party_id is the caller sending garbage; a well-formed party_id naming nothing is a reference to a party that is not there. The first is [Invalid Request] and is decided before the store is consulted at all; the second is [Not Known]. A caller that cannot tell them apart cannot tell a bug in its own code from a party that was never enrolled.

Operation 18 is the atom's central guarantee, and fresh verification is what makes it one rule rather than a paragraph. A suspension is revoked trust in the prior verification, so restoring trust needs evidence recorded *since* it — not a flag toggle, and not the passed verification that preceded the suspension. Operation 19 places it after the state checks, so a caller reinstating a closed party reads [Already Closed] rather than learning it lacks fresh evidence, and one reinstating a party that was never suspended reads [Not Suspended].

Operation 20 is why invalid-request appears twice in the priority order at two different heights. The party_id check runs first, because a malformed reference is not a claim about any party; every other field check runs last, after the state checks, because a caller suspending a closed party should learn the party is closed rather than be sent to fix a reason that would not have helped.

Operation 26 is the rule the transition table hides. A passed verification against a *suspended* party is recorded and does not reinstate: evidence gathered during an investigation must not implicitly clear the suspension, because the decision to restore trust is a separate act with its own actor and its own reason (Operation 35).

Operation 50 is a deliberate departure from the corpus's total-read shape. Silently dropping a [Query] filter the caller wrote returns a result set that answers a different question from the one asked, and a caller filtering on a misspelled axis would read *no parties match* as a fact about the store. Refusing is the honest answer, and it is why [Read] here carries a rejection where [Read] in [Invitation](./invitation.md) and [Credential](./credential.md) carries none.

Operation 59 is this atom's one departure from its siblings on instants. [Approval Step](./approval-step.md) accepts a caller-supplied decision time because the decision happened elsewhere and the record documents it; here a timestamp's only justification would be the call itself, so accepting one would let a caller write a history that did not happen.

### Invariants

- **Invariant 1 — Party record permanence.**
  ```
  Invariant 1.1: The atom MUST NOT remove a party from the store.
  Invariant 1.2: A storage-failure rejection MUST leave no partial party in the store.
  Invariant 1.3: The store instance's party count MUST NOT fall.
  ```
- **Invariant 2 — State membership exclusivity.**
  ```
  Invariant 2.1: EVERY party MUST stand in EXACTLY ONE OF unverified, verified, suspended, closed.
  ```
- **Invariant 3 — Closed is absorbing.**
  ```
  Invariant 3.1: A party whose state EQUALS closed MUST NOT leave closed.
  ```
- **Invariant 4 — Verified rests on recorded evidence.**
  ```
  Invariant 4.1: EVERY party whose state EQUALS verified MUST carry a fresh verification.
  ```
  WHY: the atom's reason for existing, and the one invariant a composing system leans on without reading this page. A downstream process that gates on *a verified party* is trusting that the standing was not asserted — and the atom owns that rather than delegating it, so every composition inherits it. There are exactly two paths into verified, and each records the required evidence as part of the transition: a passed verify against an unverified party, and a reinstate that Operation 18 will not admit without one.
- **Invariant 5 — Verification events are immutable.**
  ```
  Invariant 5.1: The atom MUST NOT change a verification event.
  ```
- **Invariant 6 — Verification events are append-only.**
  ```
  Invariant 6.1: The atom MUST NOT remove a verification event.
  Invariant 6.2: The atom MUST NOT append a verification event BEFORE a prior verification event.
  Invariant 6.3: A party's verification event list length MUST NOT fall.
  ```
- **Invariant 7 — Enrollment fields are immutable.**
  ```
  Invariant 7.1: An action MUST NOT change an enrollment field.
  ```
  WHY: the enrollment record is the auditable original — what was known and checked at onboarding — and a later truth does not overwrite it. A legal name change or a renewed document is an event that layers on top through a composing pattern (Non-goal 4). The one authorized exception is field-level scrubbing under an erasure obligation, which is a composing pattern's act and not an action here (External check 3); party_id, enrolled_at and enrolling_actor_ref survive a scrub so the chain of custody outlives the personal data.
- **Invariant 8 — No transition is silent.**
  ```
  Invariant 8.1: EVERY transitioning action MUST append a state change event.
  Invariant 8.2: A party's state change log length MUST NOT fall.
  Deleted: Invariant 9. Identity 6 owns assigned id stability.
  Deleted: Invariant 10. Identity 7, Identity 8 and Identity 9 own assigned id uniqueness.
  ```
- **Invariant 11 — Action atomicity.**
  ```
  Invariant 11.1: An action MUST commit EVERY record the action writes in one transition.
  Invariant 11.2: A storage-failure rejection MUST leave no record of the action in the store.
  ```
  WHY: the verify-driven transition is where this bites. One call writes a verification event and a state change event, and a store that landed the first without the second would leave a party carrying the evidence for a standing it does not hold — which is Invariant 4.1 satisfied in the store and violated in fact. Invariant 11.2 is the other direction: a refusal leaves nothing, so a caller reading storage-failure knows the store is as the call found it.

### Ordering

```
Ordering 1: The store instance MUST append a verification event in insertion order.
Ordering 2: The store instance MUST append a state change event in insertion order.
Ordering 3: The atom MUST read the most recent event from insertion order.
Ordering 4: The atom MUST NOT read an ordering from a recorded instant.
Ordering 5: A recorded instant MUST NOT bound a reconstruction.
Ordering 6: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

WHY:
This family exists because two orders are available and only one of them is sound. A recorded instant comes from the injected clock, and under skew or adjustment a later event can carry an earlier instant — so *the most recent suspend*, which Operation 18 turns on, would be decidable differently by two readers. Insertion order is the store's own sequence and admits one reading. Ordering 4 and Ordering 5 are what stop a reconstruction from quietly depending on the weaker of the two, and Ordering 6 names what a deployment composes when it needs wall-time bounds it can defend.

---

## Examples

### Banking — onboarding under BSA/AML

`enroll("Ada Okafor", 1984-03-02, "passport", doc_p41, officer_o7)` → `party_pk3`, standing unverified. A document check runs elsewhere; its result lands here: `verify(party_pk3, officer_o7, "manual-document-review", passed, ev_c19)` → `(ver_v88, chg_s12)`. The party now stands verified, and both ids come back — one binds an attestation to the check, the other to the transition.

### Healthcare — patient enrollment

`enroll("Tomás Rivera", 1971-11-30, "national-id", doc_n07, clerk_c2)` → `party_qh9`. A failed check records and changes nothing: `verify(party_qh9, clerk_c2, "database-check", failed, ev_d21)` → `(ver_v91)` alone, party still unverified. The atom records that a check was attempted, by whom, how, and what it found; whether to retry, escalate or close is the composing system's.

### Sanctions match, suspension, and the evidence to come back

A screening pattern flags `party_pk3`. `suspend(party_pk3, compliance_c4, "sanctions-screen match pending review")` → `chg_s31`, standing suspended. A fresh document review runs during the investigation: `verify(party_pk3, analyst_a2, "manual-document-review", passed, ev_c44)` → `(ver_v96)` — recorded, and the party stays suspended, because evidence gathered during an investigation does not clear it. Then `reinstate(party_pk3, compliance_c4, "match resolved as false positive")` → `chg_s37`, standing verified. Had the reinstate been attempted before `ver_v96`, it would have answered no-passed-verification-since-suspend.

### Enrollment in error

`enroll(...)` → `party_zz1`, then immediately `close(party_zz1, officer_o7, "enrolled in error — duplicate of party_pk3")` → `chg_s44`. The record persists in closed with the stated reason. There is no way to retract the enrollment, and that absence is structural: an auditor reads the mistake and its correction rather than a gap.

### Rejection paths

`suspend(party_qh9, ...)` on the unverified party → not-verifiable — there is no verified standing to suspend. `reinstate(party_pk3, ...)` while verified → not-suspended. `verify(party_closed, ...)` → already-closed. `suspend("", ...)` → invalid-request, decided before the store is consulted; `suspend(party_unknown, ...)` → not-known, decided after. `close(party_zz1, officer_o7, "  ")` on the already-closed party → already-closed, not invalid-request: the state checks run first (Operation 20).

### Regulated adversarial scenarios

- **Regulator audit.** *Show me every party you treat as verified, and the evidence.* Filter to `state = verified`; each record answers with its full verification event list and state change log, and Invariant 4.1 is what makes a passed check after the most recent suspend present on every one of them — structurally, rather than by policy.
- **Investigation of a reinstatement.** *Who restored this party, on what basis?* The state change log carries the reinstatement's actor, instant and reason; the verification event list carries the check that made it admissible. The two are separate records because they answer separate questions — what evidence arrived, and who decided it was enough.
- **Breach investigation.** *Which parties were enrolled in this window?* The enrolled_at range filter answers it, and Ordering 5 says what that answer is worth: instants are advisory, so a reconstruction that must be defensible uses insertion order and the composing trusted timestamping pattern for wall-time bounds.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the party store alone, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY party whose state EQUALS EXACTLY ONE OF unverified, verified, suspended, closed (Invariant 2.1).
Check 1.2: An auditor MUST find no party whose state DOES NOT EQUAL closed on a later read of a party a prior read found closed (Invariant 3.1).
Check 2.1: An auditor MUST find a fresh verification on EVERY party whose state EQUALS verified (Invariant 4.1).
Check 2.2: An auditor MUST read most recent from insertion order (Ordering 3, Ordering 4).
Check 3.1: An auditor MUST find verifying_actor_ref, verification_method, evidence_ref and verified_at on EVERY verification event (State 4).
Check 3.2: An auditor MUST find a re-read verification event unchanged (Invariant 5.1).
Check 3.3: An auditor MUST find a party's verification event list no shorter on a later read (Invariant 6.3).
Check 4.1: An auditor MUST find a state change event for EVERY transition a party's state change log records (Invariant 8.1).
Check 4.2: An auditor MUST find the prior state, the new state, an acting reference and an instant on EVERY state change event (State 5).
Check 4.3: An auditor MUST find a reason on EVERY state change event a reasoned action appended (State 7).
Check 4.4: An auditor MUST find a party's state change log no shorter on a later read (Invariant 8.2).
Check 5.1: An auditor MUST replay a party's state change log in insertion order to the party's state (Invariant 8.1, Ordering 3).
Check 5.2: An auditor MUST reconstruct EVERY party's enrollment, verification history and state history from one read (State 1, State 2, State 3).
Check 6.1: An auditor MUST find a re-read party's enrollment fields unchanged (Invariant 7.1).
Check 6.2: An auditor MUST find no party absent from a later read (Invariant 1.1).
Check 6.3: An auditor MUST find the store instance's party count no lower on a later read (Invariant 1.3).
Check 7.1: An auditor MUST find no party_id on two parties (Identity 7).
Check 7.2: An auditor MUST find no verification_id on two verification events (Identity 8).
Check 7.3: An auditor MUST find no state_change_id on two state change events (Identity 9).
Check 8.1: An auditor MUST partition the party store by state (State 1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing an identity check performed MUST read the composing verification workflow (Non-goal 7).
External check 2: A deployment needing two parties resolved as one natural person MUST read the composing identity resolution (Identity 16, Non-goal 1).
External check 3: A deployment needing an enrollment field scrubbed MUST read the composing erasure coordination (Invariant 7.1, Non-goal 12).
External check 4: A deployment needing an acting reference bound to an actor MUST read the composing Actor Identity attestation (Identity 15, Non-goal 15).
External check 5: A deployment needing a recorded instant anchored to wall time MUST read the composing trusted timestamping pattern (Ordering 5, Ordering 6).
External check 6: A deployment needing an evidence reference resolved MUST read the composing document store (Identity 13, Identity 14).
External check 7: A deployment needing a party's record retention bounded MUST read the composing Retention Window (Non-goal 13).
External check 8: A deployment needing an answer observed MUST read the composing Event Log (Non-goal 19).

```

WHY:
External check 1 is the boundary a regulator's question runs straight into. This atom records that a check was performed, by whom, how, and what it found — and it cannot tell whether the check was actually run, whether the sanctions database was actually queried, or whether an actor simply wrote `passed`. Invariant 4.1 guarantees that a verified party has evidence *on record*; it guarantees nothing about what produced that record. Saying so is the difference between a gap and a disclosed boundary.

External check 3 follows from Invariant 7.1 and is the one an erasure obligation collides with. Nothing here scrubs a name, and a deployment under GDPR Article 17 needs something that does; the composing pattern removes the identifiable fields and records the removal as an attributed event, leaving party_id, enrolled_at and enrolling_actor_ref so the chain of custody survives the data.

---

## Non-goals

```
Non-goal 1: The atom MUST NOT detect a duplicate party.
Non-goal 2: A deployment needing duplicates resolved MUST compose an identity resolution pattern.
Non-goal 3: The atom MUST NOT change an enrollment field.
Non-goal 4: A deployment needing an attribute update MUST compose an attribute update pattern.
Non-goal 5: The atom MUST NOT perform an identity check.
Non-goal 6: The atom MUST NOT read a sanctions list.
Non-goal 7: A deployment needing the verification workflow MUST compose Customer Onboarding.
Non-goal 8: The atom MUST NOT schedule a re-verification.
Non-goal 9: The atom MUST NOT count a failed verification.
Non-goal 10: The atom MUST NOT score a party's risk.
Non-goal 11: The atom MUST NOT model an ownership relationship.
Non-goal 12: The atom MUST NOT scrub an enrollment field.
Non-goal 13: The atom MUST NOT bound a party's retention.
Non-goal 14: A deployment needing retention bounded MUST compose Retention Window.
Non-goal 15: The atom MUST NOT bind an acting reference to an actor.
Non-goal 16: A deployment needing a non-repudiable transition MUST compose Actor Identity.
Non-goal 17: The atom MUST NOT model a representative acting for a party.
Non-goal 18: The atom MUST NOT link a party_id across two trust domains.
Non-goal 19: The atom MUST NOT record an answer the atom gave.
Non-goal 20: The atom MUST NOT propagate a state change to a downstream system.
Non-goal 21: The atom MUST NOT terminate a party's open commitment.
Non-goal 22: The atom MUST NOT model a pending verification.
Non-goal 23: The atom MUST NOT guarantee that a party reaches verified.
```

WHY:
Non-goal 22 is the one every real deployment meets on day one. A document is submitted, an external service runs for seconds or days, and the result arrives later — and this atom has no *pending* state for that interval. The party simply stands unverified while the check runs, and the composing workflow owns the coordination. Adding a pending state would put a workflow's in-flight bookkeeping inside the record primitive, and every composition would inherit one workflow's shape.

Non-goal 21 is what *closed* does not mean. Closing a party stops new regulated activity here and terminates nothing: open accounts, positions and contracts are the composing system's to unwind, and this atom's whole contract on the matter is that verify, suspend and reinstate are refused.

---

## Edge cases

### Atomic writes

```
Atomic writes 1: The implementation MUST commit a transition whole.
Atomic writes 2: The implementation MUST discard an uncommitted transition whole.
Atomic writes 3: The implementation MUST own the transactional boundary.
Atomic writes 4: The implementation MUST NOT repair a dangling transition.
```

### Clock semantics

```
Clock semantics 5: A recorded instant MUST NOT carry an ordering.
Deleted: Clock semantics 3. Capability requirement 8 owns it.
Deleted: Clock semantics 1. The section titled Logic Confinement Principle in `execution-contract.md` owns it.
Deleted: Clock semantics 2. The section titled Logic Confinement Principle in `execution-contract.md` owns it.
Deleted: Clock semantics 4. Capability requirement 9 owns it.
```

WHY:
Clock semantics 5 is the Ordering family stated from the clock's side, and the pair is the reason this atom accepts no caller-supplied instant (Operation 59). A record whose only justification is the call itself takes the call's own clock reading; anything else lets a caller write a history that did not happen. [Approval Step](./approval-step.md) accepts a supplied instant for the opposite reason — its decisions happen elsewhere and the record documents them — so the two atoms differ on the same question because their records mean different things.

### Concurrency

```
Concurrency 1: The implementation MUST commit the state checks and the state change of a transitioning action as one atomic operation.
Concurrency 2: A losing party action MUST read the winner's state.
Concurrency 3: A losing party action MUST answer the state rejection the winner's state earns.
```

### Indeterminate outcome

```
Indeterminate outcome 1: A caller MUST NOT retry an action whose answer the caller lost BEFORE reading the party.
Indeterminate outcome 2: A caller MUST NOT read a lost answer as a refusal.
Indeterminate outcome 3: A caller MUST NOT retry a lost [Enroll] BEFORE reading the store.
```

WHY:
Invariant 11.1 is store-side and the caller's knowledge is weaker. A transport failure after the store committed leaves the caller unable to tell *refused, nothing written* from *succeeded, answer lost* — and the two have opposite remedies. Every party action is safe to re-read first because the state checks make a repeat self-detecting: a second suspend answers already-suspended. [Enroll] is the one that is not, because it creates rather than transitions, so a blind retry produces a second party that this atom will never resolve against the first (Identity 16).

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: IF a string input EXCEEDS the length bound THEN an action MUST answer invalid-request.
```

Term string input: a required string input, date_of_birth OR a filter value — every caller-supplied string this atom accepts.

Term length bound: the maximum length the deployment declares for a string input.


WHY:
The blank rule earns its keep on reason more than anywhere else. A suspension, a reinstatement and a closure each require a stated basis, and a whitespace placeholder would satisfy a naive presence check while leaving the audit surface exactly as empty as no reason at all. Storing a name as supplied — no normalization, no transliteration — is the other half: the enrollment record says what was presented, and how a deployment matches or displays it is the deployment's (Capability requirement 6).

---

## Composition notes

```
Composition note 1: A composing Customer Onboarding MUST gate regulated activity on the party whose state EQUALS verified.
Composition note 2: A composing Customer Onboarding MUST own the verification workflow.
Composition note 3: A composing External Onboarding MUST call [Enroll] ONLY AFTER an accepted invitation.
Composition note 4: A composing Actor Identity MUST attest the actor behind EVERY transitioning action.
Composition note 5: A composing Actor Identity MUST bind an attestation to a state_change_id.
Composition note 6: A composing Audit Trail MUST record EVERY verification event and EVERY state change event.
Composition note 7: A composing Consent MUST name the party_id as the data subject reference.
Composition note 8: A composing Retention Window MUST NOT scrub an enrollment field.
Composition note 9: A composing erasure coordination pattern MUST record a scrub as an attributed event.
Composition note 10: A composing erasure coordination pattern MUST NOT scrub a custody field.
Composition note 11: A composing Event Log MUST append an event on EVERY admitted action.
Composition note 12: A composing Event Log MUST append an event on EVERY refused action.
```

WHY:
Composition note 5 is why every transitioning action answers its state_change_id directly rather than leaving the caller to find it. An attestation binds to a specific suspension, not to *the most recent suspension at the time I looked* — and a follow-up query to discover the id opens exactly the window an attestation exists to close.

Composition note 8 and Composition note 10 divide one obligation two patterns keep reaching for. [Retention Window](./retention-window.md) owns *when* a record may be destroyed and performs no field-level scrubbing; the erasure pattern owns the scrub and must leave the three fields that carry the chain of custody. A deployment that lets either do the other's half ends with either a record it cannot lawfully keep or an audit trail it cannot read.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the deployment; the implementation; the store; the store instance; the seam; the transition; a composing pattern; a caller; an auditor; a regulator; an investigator; a party; a verification event; a state change event; an action; a party action; a transitioning action; a losing party action; a refused action; an assigned id; an opaque reference; a string input; a filter; a filter axis; a filter value; a query; the store instance's party count; a party's verification event list length; a party's state change log length.

Term records: party — one external party, carrying party_id, name, date_of_birth, document_type, document_ref, enrolled_at, enrolling_actor_ref, a state, a state change log and a verification event list. verification event — one identity check, carrying verification_id, verifying_actor_ref, verification_method, verification_result, evidence_ref and verified_at. state change event — one transition, carrying state_change_id, the prior state, the new state, an acting reference, an instant and, where the writer carries one, a reason.

Term record verbs: identify, assign, generate, change, share, carry, stand, read, answer, record, append, remove, leave, admit, offer, hold, commit, discard, repair, refuse, write, find, resolve, name, compare, normalize, confirm, match, differ, route, register, create, pass, attest, cover, call, fall, precede, follow, sample, consume, supply, acknowledge, canonicalize, declare, compose, bind, decide, define, bound, reach, accept, trim, case-fold, compute, reproduce, reconstruct, replay, verify, detect, guarantee, take, derive, expose, store, own, enumerate, distinguish, select, order, deduplicate, scrub, parse, gate, count, schedule, propagate, terminate, link, serialize, suspend, reinstate, close, enroll, ignore, partition, retry, exceed, perform, score, model.

Term value sets: state = unverified | verified | suspended | closed. verification_result = passed | failed. state rejection = already-closed | not-verifiable | already-suspended | not-suspended. enrollment field = name | date_of_birth | document_type | document_ref | enrolled_at | enrolling_actor_ref.

Term bounds: length bound.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: party, party_id, verification event, state change event, assigned id, enrollment field, acting reference, reference, store instance, seam, transition, now, party action, transitioning action, state, state rejection, state check, required string input, fresh verification, insertion order, length bound, reasoned action, custody field, evidence reference, query axes, admitted enroll, admitted verify, admitted suspend, admitted reinstate, admitted close, admitted read, string input, blank, verification result.

Term cited: the section titled Logic Confinement Principle in `execution-contract.md` — the seam and the transition.

Term composing pattern: [Actor Identity](./actor-identity.md), [Consent](./consent.md), [Retention Window](./retention-window.md), [Event Log](./event-log.md), [Audit Trail](../compositions/audit-trail.md), [Customer Onboarding](../compositions/customer-onboarding.md), [External Onboarding](../compositions/external-onboarding.md), an identity resolution pattern, an attribute update pattern, an erasure coordination pattern, a trusted timestamping pattern, a document store.

#### Enroll

The behavior that records a new [Party] — assigning a fresh [Party Id], recording every enrollment field, stamping [Enrolled At], and standing the record in [Unverified]. Refused [Invalid Request] or [Storage Failure]. It creates rather than transitions, which is why a lost answer must not be retried blind.

Kind: Operation

#### Verify

The behavior that records one identity check as a [Verification Event] — its method, result, evidence and acting reference — and, where the party stands in [Unverified] and the result is `passed`, stands the party in [Verified] and appends a [State-Change Event] in the same transition. Records a check against a [Suspended] party without lifting the suspension.

Kind: Operation

#### Suspend

The transitioning action that stands a [Verified] party in [Suspended], recording the acting reference and a required [Reason]. Refused [Not Verifiable] against an [Unverified] party — there is no verified standing to suspend — and [Already Suspended] against a suspended one.

Kind: Operation

#### Reinstate

The transitioning action that returns a [Suspended] party to [Verified]. Admitted only where a [Fresh Verification] exists; otherwise [No Passed Verification Since Suspend]. The rule is the atom's central guarantee — a suspension is revoked trust, and restoring it takes evidence recorded since.

Kind: Operation

#### Close

The transitioning action that stands any non-closed party in [Closed], recording the acting reference and a required [Reason]. Absorbing: a closed party is refused [Verify], [Suspend] and [Reinstate] thereafter, and returning needs a fresh [Enroll].

Kind: Operation

#### Read

The read-only query answering the matching [Party] records in insertion order, each carrying its enrollment fields, its full [State-Change Log] and its full [Verification Event] list. Refuses a filter it cannot read ([Invalid Query]) rather than ignoring it.

Kind: Operation

#### Party

The record this atom defines: one external party's enrollment, verification history and state history. Carries [Party Id], the enrollment fields, a [Current State], a [State-Change Log] and a [Verification Event] list.

Kind: Type
Projection: state

#### Verification Event

The record of one identity check, appended to a party and never changed. Carries [Verification Id], [Verifying Actor Ref], [Verification Method], [Verification Result], [Evidence Ref] and [Verified At]. It records that a check was made, by whom, how, and what it found — never that the check was in fact performed.

Kind: Type
Projection: verification_event

#### State-Change Event

The record of one transition, appended to a party and never changed. Carries [State Change Id], [Prior State], [New State], an acting reference, an instant and — for a suspend, a reinstate or a close — a [Reason].

Kind: Type
Projection: state_change_event

#### Party Id

The opaque, immutable identity of a [Party], assigned on [Enroll] from the id material the seam supplies. Never a content field, because a legal name changes and a document is renewed without the party becoming a different party.

Kind:       Field
Field of:   Party
Projection: party_id

#### Name

The party's legal name at enrollment, stored as supplied — no normalization, no case folding, no transliteration. Immutable; a later legal name change is a composing pattern's event, not an edit here.

Kind:       Field
Field of:   Party
Projection: name

#### Date Of Birth

The party's date of birth at enrollment, as a calendar date that does not exceed [Now]. Immutable.

Kind:       Field
Field of:   Party
Projection: date_of_birth

#### Document Type

The class of identity document presented — `passport`, `national-id`, `drivers-license`. Opaque to the atom; which values a regime admits is the composing system's.

Kind:       Field
Field of:   Party
Projection: document_type

#### Document Ref

The opaque pointer to the identity document record in the composing document store. Never resolved here.

Kind:       Field
Field of:   Party
Projection: document_ref

#### Enrolled At

The instant the party was enrolled, stamped from [Now]. Immutable, and one of the three fields an erasure scrub must leave.

Kind:       Field
Field of:   Party
Projection: enrolled_at

#### Enrolling Actor Ref

The opaque reference naming who enrolled the party. Attribution only — binding it to a verifiable actor is [Actor Identity](./actor-identity.md)'s. One of the three fields an erasure scrub must leave.

Kind:       Field
Field of:   Party
Projection: enrolling_actor_ref

#### Current State

The party's standing — [Unverified], [Verified], [Suspended] or [Closed]. Changes only through a [Verification Event]-driven transition, [Suspend], [Reinstate] or [Close], and never silently.

Kind:       Field
Field of:   Party
Projection: state

#### State-Change Log

The party's append-only, insertion-ordered list of [State-Change Event]s. It travels with the record on [Read], which is what makes a party's whole biography answerable from one surface.

Kind:       Field
Field of:   Party
Projection: state_change_log

#### Verification Id

The opaque, immutable identity of a [Verification Event]. Answered by [Verify] so a composing attestation binds to the check itself.

Kind:       Field
Field of:   Verification Event
Projection: verification_id

#### Verifying Actor Ref

The opaque reference naming who performed the check. Attribution only.

Kind:       Field
Field of:   Verification Event
Projection: verifying_actor_ref

#### Verification Method

The opaque label naming how the check was made — `manual-document-review`, `automated-ocr`, `biometric-match`, `database-check`. Recorded, never interpreted.

Kind:       Field
Field of:   Verification Event
Projection: verification_method

#### Verification Result

What the check found: `passed` or failed, and nothing else. A `passed` result against an [Unverified] party drives the transition to [Verified]; against a [Suspended] party it is recorded and lifts nothing.

Kind:       Field
Field of:   Verification Event
Projection: verification_result

#### Evidence Ref

The opaque pointer to the evidence record supporting the check. Never resolved here.

Kind:       Field
Field of:   Verification Event
Projection: evidence_ref

#### Verified At

The instant the check was recorded, stamped from [Now]. Advisory: insertion order, not this field, decides what *most recent* means.

Kind:       Field
Field of:   Verification Event
Projection: verified_at

#### State Change Id

The opaque, immutable identity of a [State-Change Event]. Answered directly by every transitioning action, so an attestation binds to one specific suspension rather than to whichever was most recent when the caller looked.

Kind:       Field
Field of:   State-Change Event
Projection: state_change_id

#### Prior State

The state the party left. Recorded on every [State-Change Event].

Kind:       Field
Field of:   State-Change Event
Projection: prior_state

#### New State

The state the party entered. Recorded on every [State-Change Event].

Kind:       Field
Field of:   State-Change Event
Projection: new_state

#### Reason

The caller-supplied basis for a suspension, a reinstatement or a closure. Required and never blank on those three; absent on a [Verify]-driven transition, where the [Verification Event] is the basis.

Kind:         Parameter
Parameter of: Suspend
Projection:   reason

#### Fresh Verification

A [Verification Event] carrying `passed` that follows the party's most recent [Suspend] in insertion order — or the enrollment, where the party was never suspended. What [Reinstate] requires, and what every [Verified] party carries.

Kind: Type
Projection: fresh_verification

#### Now

The wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it — never read inside the transition and never supplied by the business caller.

Kind:         Parameter
Parameter of: Enroll
Projection:   now

#### Query

The filter a [Read] carries, over exactly three axes: [Party Id], [Current State], and a range on [Enrolled At]. An axis or a value outside those is [Invalid Query] rather than a silently dropped filter.

Kind:         Parameter
Parameter of: Read
Projection:   query

#### Unverified

The entry state of every enrolled party: no passing check is on record. A party stays here while an asynchronous check runs, because this atom models no pending state.

Kind:      Member
Member of: the party state
Role:      Outcome

#### Verified

The state a party holds when a [Fresh Verification] is on record and no later suspension or closure has occurred. What a composing system gates regulated activity on.

Kind:      Member
Member of: the party state
Role:      Outcome

#### Suspended

The state a party holds while trust in the prior verification is revoked — pending investigation, re-verification, or a preservation order. Checks may still be recorded here; none of them lifts it.

Kind:      Member
Member of: the party state
Role:      Outcome

#### Closed

The terminal state. The record persists and the party may not be the subject of new regulated activity; returning takes a fresh [Enroll] under a new [Party Id].

Kind:      Member
Member of: the party state
Role:      Outcome

#### Invalid Request

The refusal returned when a required string input is blank, a [Date Of Birth] parses as no calendar date or exceeds [Now], a [Verification Result] is neither `passed` nor failed, or a string input exceeds the deployment's length bound. A blank [Party Id] earns it before the store is consulted; every other field fault earns it after every state check passes.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Not Known

The refusal a party action returns when a well-formed [Party Id] names no party. Distinct from [Invalid Request] on a blank one: the first says the party is not there, the second says the caller sent garbage.

Kind:       Member
Member of:  the party-action rejection
Role:       Outcome
Projection: not-known

#### Already Closed

The refusal a party action returns against a [Closed] party. Closure is absorbing, so this is final for that [Party Id].

Kind:       Member
Member of:  the party-action rejection
Role:       Outcome
Projection: already-closed

#### Not Verifiable

The refusal [Suspend] returns against an [Unverified] party — there is no verified standing to suspend. Distinct from [Already Suspended], because a caller reading this looks at the verification workflow while one reading that looks for a duplicate call.

Kind:       Member
Member of:  the Suspend rejection
Role:       Outcome
Projection: not-verifiable

#### Already Suspended

The refusal [Suspend] returns against a [Suspended] party — a duplicate or raced call.

Kind:       Member
Member of:  the Suspend rejection
Role:       Outcome
Projection: already-suspended

#### Not Suspended

The refusal [Reinstate] returns against an [Unverified] or a [Verified] party. One answer for two states, deliberately: both mean there is no suspension to lift, and the remedy is the same.

Kind:       Member
Member of:  the Reinstate rejection
Role:       Outcome
Projection: not-suspended

#### No Passed Verification Since Suspend

The refusal [Reinstate] returns against a [Suspended] party carrying no [Fresh Verification]. The atom's one purpose-built rejection arm, and the reason reinstatement cannot be a flag toggle.

Kind:       Member
Member of:  the Reinstate rejection
Role:       Outcome
Projection: no-passed-verification-since-suspend

#### Invalid Query

The refusal [Read] returns for a filter axis or a filter value it cannot read. Refusing rather than ignoring, because a silently dropped filter answers a different question from the one asked.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

#### Storage Failure

The refusal any writing action returns when the store refuses the write after every precondition passes. No record the action would have written is persisted. [Read] never returns it.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Enroll]: #enroll
[Verify]: #verify
[Suspend]: #suspend
[Reinstate]: #reinstate
[Close]: #close
[Read]: #read
[Party]: #party
[Verification Event]: #verification-event
[State-Change Event]: #state-change-event
[Party Id]: #party-id
[Name]: #name
[Date Of Birth]: #date-of-birth
[Document Type]: #document-type
[Document Ref]: #document-ref
[Enrolled At]: #enrolled-at
[Enrolling Actor Ref]: #enrolling-actor-ref
[Current State]: #current-state
[State-Change Log]: #state-change-log
[Verification Id]: #verification-id
[Verifying Actor Ref]: #verifying-actor-ref
[Verification Method]: #verification-method
[Verification Result]: #verification-result
[Evidence Ref]: #evidence-ref
[Verified At]: #verified-at
[State Change Id]: #state-change-id
[Prior State]: #prior-state
[New State]: #new-state
[Reason]: #reason
[Fresh Verification]: #fresh-verification
[Now]: #now
[Query]: #query
[Unverified]: #unverified
[Verified]: #verified
[Suspended]: #suspended
[Closed]: #closed
[Invalid Request]: #invalid-request
[Not Known]: #not-known
[Already Closed]: #already-closed
[Not Verifiable]: #not-verifiable
[Already Suspended]: #already-suspended
[Not Suspended]: #not-suspended
[No Passed Verification Since Suspend]: #no-passed-verification-since-suspend
[Invalid Query]: #invalid-query
[Storage Failure]: #storage-failure

---

## Standards references

- **FATF Recommendations 10–12 (customer due diligence)** — identify the customer and verify identity using reliable independent sources; identify beneficial owners; conduct ongoing due diligence. The [Enroll] → [Verify] lifecycle is the structural form; the beneficial-ownership graph is a composing pattern's (Non-goal 11) and the monitoring schedule is too (Non-goal 8).
- **BSA/AML — 31 CFR Part 1020 (FinCEN Customer Identification Program)** — minimum identity attributes, verification by documentary or non-documentary method, and five-year retention past the relationship's end. The enrollment fields are the attributes; [Verification Method] records which kind was used; retention is [Retention Window](./retention-window.md)'s (Non-goal 13).
- **FinCEN Beneficial Ownership Rule — 31 CFR §1010.230** — each beneficial owner is a party record in their own right; the ownership relationship is not.
- **EU 5th Anti-Money Laundering Directive (AMLD5)** — enhanced due diligence and beneficial-ownership registries, aligned with FATF.
- **GDPR Article 4(1)** — the enrollment fields are personal data, and this atom is the corpus's clearest case of an atom that holds some rather than opaque references alone.
- **GDPR Articles 5–6** — lawful basis for processing, typically Article 6(1)(c) or 6(1)(b); processing *beyond* the regulatory obligation is [Consent](./consent.md)'s.
- **GDPR Article 17 (right to erasure)** — in direct tension with the retention obligations above. This atom does not resolve it: Invariant 7.1 forbids changing an enrollment field, and the composing erasure pattern is the authorized scrub (External check 3, Non-goal 12).
- **HIPAA 45 CFR §164.514** — patient identity must be established before protected health information records exist; the patient is a party here.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture, and the discipline of composing the verification workflow, deduplication, risk scoring and ownership structure as separate concepts.
- **Grace Commons regulated-atom conventions** — the adversarial scenarios and the acceptance section, from `pressure-testing.md`.

---

## Status

`grounded on Final Critique 5 — 2026-07-12` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 5 — 2026-07-12
formal: verified — party-identity.tla + 1 twin, 2026-06-03
last gate: 2026-07-12 — Final Critique 5, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/party-identity.md`.

- **2026-09-13 — The EOS strip test: no domain tag, no rename, and the coupling is in the attributes rather than the name.** *Chose:* leave the atom untagged and unrenamed, and record where the domain actually touches it. *Over:* a `domain:` tag, or a reframe of the kind [Observation](./observation.md) took. *Because:* the test asks whether stripping the domain leaves a freestanding neutral primitive, and here it does. Every invariant is neutral — records are never removed, a terminal absorbs, events are append-only and immutable, a standing rests on recorded evidence since the last revocation. None of them is derivable only from banking or healthcare; the same shape governs a licence, an accreditation, a calibration status. The *name* is already the stripped form: party is legal and commercial vocabulary rather than one industry's, which is why the atom is not called Customer Identity or Patient Identity. What is domain-flavoured is the enrollment attribute set — name, date_of_birth, document_type, document_ref — which is natural-person identity-document vocabulary, and the atom already treats two of the four as opaque strings it never interprets. The honest boundary is that this atom is a neutral standing-and-evidence primitive carrying one concrete attribute schema, and the question of whether that schema should be an opaque attribute bag belongs on the docket rather than in a rename.
- **2026-09-13 — Insertion order is authoritative and a recorded instant is advisory, stated as its own rule family.** *Chose:* an `Ordering` family, with Ordering 4 and Ordering 5 forbidding a reading or a reconstruction from turning on an instant. *Over:* the prose's paragraph saying the same thing beside the state machine. *Because:* Operation 18's *most recent suspend* is the atom's central guarantee and it is decidable two ways, one of which is unsound — under clock skew a later event can carry an earlier instant, and two readers would then disagree about whether a party may be reinstated. A rule family is what makes the sound reading the one a generator implements.
- **2026-09-13 — Invariant 9 and Invariant 10 are tombstoned; Identity owns assigned id stability and uniqueness.** *Chose:* Identity 6 through 9 as the single owners. *Over:* keeping the invariants, which restated them. *Because:* Authority 3. Checked before removing: the corpus cites Party Identity Invariants 1, 4, 5 and 11 — from [Customer Onboarding](../compositions/customer-onboarding.md) and the coverage matrix — and cites neither 9 nor 10, so the tombstones break no citation.
- **2026-09-13 — no-passed-verification-since-suspend stays a purpose-built rejection arm.** *Chose:* the arm the prose already carried. *Over:* folding it into not-suspended or invalid-request, which is what the corpus's closed answer set usually pressures a rare condition into. *Because:* this one is not rare and not adjacent to anything — it is the atom's central guarantee failing, and a caller receiving it knows exactly what to do next, which is to record a check. It is worth naming as the corpus's counter-example: the docket row on answers charged to the nearest arm is about conditions that could not justify the cost of their own name, and this is what paying that cost looks like.

NOTE: End of Party Identity.
