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

The compliance framing is consistent across regimes. FATF (Financial Action Task Force — the international anti-money-laundering standard-setter) Recommendations 10–12 require customer due diligence before a business relationship begins. The BSA/AML (Bank Secrecy Act / Anti-Money Laundering) Customer Identification Program (31 CFR — the US Code of Federal Regulations — Part 1020) sets minimum attributes and five-year retention past the relationship's end. GDPR (General Data Protection Regulation — the European Union's data-protection law) Article 4(1) makes the attributes collected here personal data. HIPAA (the US Health Insurance Portability and Accountability Act) requires patient identity before clinical records exist. The domain varies; the structural obligation does not.

This atom is distinct from [Actor Identity](./actor-identity.md), and not cosmetically. Actor Identity models *internal actors who authorize actions* — an employee or service account producing a proof that binds identity to a specific action. Party Identity models *external parties whose identity must be established* — the subject of the system's activity rather than its operator. Different obligations, different state machines, and they compose when one natural person is both.

This is a freestanding atom in the EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) sense: its own state machine, its own five writes and one read, and its own invariants — the atom never removes a record, verification events are immutable and append-only, closed is absorbing, and verified rests on recorded evidence. It does not implement the verification workflow, the document check, the sanctions screen, the monitoring schedule, risk scoring or enhanced due diligence.

---

## Structure

### Identity model

```
Identity 1: The atom MUST identify a party by the party id.
Identity 2: The atom MUST identify a verification event by the verification id.
Identity 3: The atom MUST identify a state change event by the state change id.
Identity 4: The atom MUST take an assigned id from the id material the seam supplies.
Identity 5: The atom MUST NOT generate an assigned id.
Identity 6: The atom MUST NOT change an assigned id.
Identity 7: Two parties MUST NOT share a party id.
Identity 8: Two verification events MUST NOT share a verification id.
Identity 9: Two state change events MUST NOT share a state change id.
Identity 10: The atom MUST NOT identify a party by an enrollment field.
Identity 11: The atom MUST compare a reference byte-exactly.
Identity 12: The atom MUST NOT normalize a reference.
Identity 13: The atom MUST NOT confirm that a document reference names a known document.
Identity 14: The atom MUST NOT confirm that an evidence reference names a known evidence record.
Identity 15: The atom MUST NOT confirm that an acting reference names a known actor.
Identity 16: The atom MUST NOT match two parties as one natural person.
Deleted: Identity 17. Execution Contract Database 7 owns it.
```


Term party: the record this atom holds — one external party's enrollment, verification history and state history.

Term party id: the opaque value naming one party — a [Party Id]; assigned from the id material the seam supplies.

Term verification event: the record of one identity check — its method, result, evidence and acting reference — appended to a party and never changed.

Term state change event: the record of one transition — the prior state, the new state, the acting reference, the instant and, where the action carries one, the reason — appended to a party and never changed.

Term assigned id: party id, verification id OR state change id — every opaque name this atom assigns.

Term enrollment field: name | date of birth | document type | document reference | enrollment instant | enrolling actor reference — what a party carries from enrollment and the atom never changes.

Term acting reference: enrolling actor reference, verifying actor reference, suspending actor reference, reinstating actor reference OR closing actor reference — the reference an action records for who acted.

Term reference: an assigned id, an acting reference, document reference OR evidence reference — every opaque reference this atom records.

Term database instance: one named database a call is routed to; assigned id uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the id material here.

Term transition: the atom's evaluation of one call against the party records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

### State

```
State 1: EVERY party MUST carry party id, EVERY enrollment field and a state.
State 2: EVERY party MUST carry a state change log.
State 3: EVERY party MUST carry a verification event list.
State 4: EVERY verification event MUST carry verification id, verifying actor reference, verification method, verification result, evidence reference and verification instant.
State 5: EVERY state change event MUST carry state change id, the prior state, the new state, an acting reference and an instant.
State 6: A state change event MAY carry a reason.
State 7: EVERY state change event a reasoned action appended MUST carry a reason.
```

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the id material at the seam.
Deleted: Capability requirement 3. Execution Contract Database 2 owns it.
Deleted: Capability requirement 4. Execution Contract Database 3 owns it.
Deleted: Capability requirement 5. Execution Contract Database 1 owns it.
Capability requirement 6: The deployment MUST canonicalize an opaque reference at the seam.
Capability requirement 7: The deployment MUST declare the length bound.
Capability requirement 10: The deployment MUST supply the party records PER Execution Contract Database 1 through 4, Execution Contract Database 6, Execution Contract Database 7, Execution Contract Order 1, Execution Contract Read 4, Execution Contract Refusal 1 and Execution Contract Query 1 through 4.
Deleted: Capability requirement 8. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 9. Execution Contract Logic confinement 7 owns it.
```

NOTE: Capability requirement 6 reaches every reference (Term reference), the assigned ids the id material carries and a filter's party id among them; the deployment canonicalizes each at the seam, in a form the deployment owns, before the transition compares or records it, since Identity 12 keeps the atom from normalizing.

NOTE: watch the canonical form (Capability requirement 6).

### Operations

```
enroll(name, date_of_birth, document_type, document_ref, enrolling_actor_ref)
  answers party_id
  refuses invalid-request | storage-failure

verify(party_id, verifying_actor_ref, verification_method, verification_result, evidence_ref)
  answers verify answer
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

Term verify answer: verification id and an optional state change id — what verify answers.

```
Operation 1: IF a required string input EQUALS blank THEN an action MUST answer invalid-request.
Operation 2: IF the date of birth parses as no calendar date THEN [Enroll] MUST answer invalid-request.
Operation 3: IF now PRECEDES the date of birth THEN [Enroll] MUST answer invalid-request.
Operation 4: An admitted enroll MUST assign a fresh party id.
Operation 5: An admitted enroll MUST record EVERY enrollment field.
Operation 6: An admitted enroll MUST record now as enrollment instant.
Operation 7: An admitted enroll MUST stand the party in unverified.
Operation 8: An admitted enroll MUST answer the party id.
Operation 9: [Enroll] MUST NOT answer not-known.
Operation 10: IF party id EQUALS blank THEN a party action MUST answer invalid-request.
Operation 11: IF the party id names no party THEN a party action MUST answer not-known.
Operation 12: A party action MUST answer not-known ONLY IF party id DOES NOT EQUAL blank.
Operation 13: IF the party's state EQUALS closed THEN a party action MUST answer already-closed.
Operation 14: IF the party's state EQUALS unverified THEN [Suspend] MUST answer not-verifiable.
Operation 15: IF the party's state EQUALS suspended THEN [Suspend] MUST answer already-suspended.
Operation 16: IF the party's state DOES NOT EQUAL suspended THEN [Reinstate] MUST answer not-suspended.
Deleted: Operation 17. Execution Contract Refusal 1 owns it.
Operation 18: IF no fresh verification EXISTS THEN [Reinstate] MUST answer no-passed-verification-since-suspend.
Deleted: Operation 19. Execution Contract Refusal 1 owns it.
Deleted: Operation 20. Execution Contract Refusal 1 owns it.
Operation 21: IF the verification result differs from passed AND the verification result differs from failed THEN [Verify] MUST answer invalid-request.
Operation 22: An admitted verify MUST append a verification event carrying a fresh verification id.
Operation 23: An admitted verify MUST record verifying actor reference, verification method, verification result and evidence reference on the verification event.
Operation 24: An admitted verify MUST record now as the verification event's verification instant.
Operation 25: IF the party's state EQUALS unverified AND the verification result EQUALS passed THEN an admitted verify MUST stand the party in verified.
Operation 26: An admitted verify MUST NOT change the party's state outside the unverified-to-verified transition.
Operation 27: An admitted verify MUST answer the verification id.
Operation 28: An admitted verify driving a transition MUST answer the state change id.
Operation 29: An admitted verify driving no transition MUST NOT answer a state change id.
Operation 30: An admitted suspend MUST stand the party in suspended.
Operation 31: An admitted reinstate MUST stand the party in verified.
Operation 32: An admitted close MUST stand the party in closed.
Operation 33: A transitioning action MUST append a state change event carrying a fresh state change id.
Operation 34: A transitioning action MUST record the prior state, the new state, the acting reference and now on the state change event.
Operation 35: A reasoned action MUST record reason on the state change event.
Operation 36: An admitted verify MUST NOT record a reason on a state change event.
Operation 37: A transitioning action MUST answer the state change id.
Deleted: Operation 38. Execution Contract Database 1 owns it.
Operation 39: IF the database refuses the write THEN an action MUST answer storage-failure.
Deleted: Operation 40. Execution Contract Refusal 1 owns it.
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
Deleted: Operation 57. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 58. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 59. Operation 6, Operation 24 and Operation 34 own it.
```

NOTE: watch the blank id (Operation 12).

NOTE: open 2026-10-21-f — the date of birth's format, and the instant of the day a date of birth stands for when Operation 3 compares the date with now, are not declared, so a date of birth of today can answer two ways (Operation 2, Operation 3).

Term party action: [Verify] | [Suspend] | [Reinstate] | [Close] — every action naming a party by party id, including a refused one.

Term transitioning action: a party action that changes the party's state — an admitted suspend, an admitted reinstate, an admitted close, OR an admitted verify driving the unverified-to-verified transition.

Term reasoned action: an admitted suspend, an admitted reinstate OR an admitted close — every transitioning action that carries a caller-supplied reason.

Term state: unverified | verified | suspended | closed.

Term state check: Operation 11, Operation 13, Operation 14, Operation 15, Operation 16 and Operation 18 — every check a party action makes on the party's own standing before reading the call's remaining inputs.

Term required string input: name, document type, document reference, verification method, evidence reference, reason, an acting reference OR party id — every string an action refuses when blank.

Term fresh verification: a verification event whose verification result EQUALS passed that follows the party's most recent suspend in insertion order, or that follows the enrollment where no suspend EXISTS.

Term custody field: party id | enrollment instant | enrolling actor reference — the fields an erasure scrub leaves, so the chain of custody outlives the personal data.

Term insertion order: the order a database instance appended its records; authoritative for this atom, where a recorded instant is advisory.

Term query axes: party id, state and a range over enrollment instant — every filter axis [Read] admits, the party id axis admitting every value that DOES NOT EQUAL blank, one naming no party among them.

NOTE: watch the blank filter value (Term query axes).

Term admitted enroll: an [Enroll] call the action admits (Execution Contract Read 4).

Term admitted verify: a [Verify] call the action admits (Execution Contract Read 4).

Term admitted suspend: a [Suspend] call the action admits (Execution Contract Read 4).

Term admitted reinstate: a [Reinstate] call the action admits (Execution Contract Read 4).

Term admitted close: a [Close] call the action admits (Execution Contract Read 4).

Term admitted read: a [Read] call whose every filter axis and filter value the guards admit.

### Invariants

- **Invariant 1 — Party record permanence.**
  ```
  Invariant 1.1: The atom MUST NOT remove a party from the database.
  Deleted: Invariant 1.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 1.3. Invariant 1.1 and Execution Contract Database 4 own it.
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
- **Invariant 7 — Enrollment fields are immutable under the atom's actions.**
  ```
  Deleted: Invariant 7.1. Non-goal 3 owns it.
  ```
- **Invariant 8 — No transition is silent.**
  ```
  Invariant 8.1: EVERY transitioning action MUST append a state change event.
  Invariant 8.2: A party's state change log length MUST NOT fall.
  Deleted: Invariant 9. Identity 6 owns assigned id stability.
  Deleted: Invariant 10. Identity 7, Identity 8 and Identity 9 own assigned id uniqueness.
  ```
- **Invariant 11 — Action atomicity.**
  ```
  Deleted: Invariant 11.1. Execution Contract Database 1 owns it.
  Deleted: Invariant 11.2. Execution Contract Database 1 and Execution Contract Database 3 own it.
  ```
### Ordering

```
Deleted: Ordering 1. Execution Contract Order 1 owns it.
Deleted: Ordering 2. Execution Contract Order 1 owns it.
Ordering 3: The atom MUST read the most recent event from insertion order.
Ordering 4: The atom MUST NOT read an ordering from a recorded instant.
Ordering 5: A recorded instant MUST NOT bound a reconstruction.
Ordering 6: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

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

`suspend(party_qh9, ...)` on the unverified party → not-verifiable — there is no verified standing to suspend. `reinstate(party_pk3, ...)` while verified → not-suspended. `verify(party_closed, ...)` → already-closed. `suspend("", ...)` → invalid-request, answered ahead of not-known (Operation 10, Operation 12); `suspend(party_unknown, ...)` → not-known. `close(party_zz1, officer_o7, "  ")` on the already-closed party → already-closed, not invalid-request: the state checks run first (Execution Contract Refusal 1).

### Regulated adversarial scenarios

- **Regulator audit.** *Show me every party you treat as verified, and the evidence.* Filter to `state = verified`; each record answers with its full verification event list and state change log, and Invariant 4.1 is what makes a passed check after the most recent suspend present on every one of them — structurally, rather than by policy.
- **Investigation of a reinstatement.** *Who restored this party, on what basis?* The state change log carries the reinstatement's actor, instant and reason; the verification event list carries the check that made it admissible. The two are separate records because they answer separate questions — what evidence arrived, and who decided it was enough.
- **Breach investigation.** *Which parties were enrolled in this window?* The enrollment instant range filter answers it, and Ordering 5 says what that answer is worth: instants are advisory, so a reconstruction that must be defensible uses insertion order and the composing trusted timestamping pattern for wall-time bounds.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the party records.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY party whose state EQUALS EXACTLY ONE OF unverified, verified, suspended, closed (Invariant 2.1).
Check 1.2: An auditor MUST find no party whose state DOES NOT EQUAL closed on a later read of a party a prior read found closed (Invariant 3.1).
Check 2.1: An auditor MUST find a fresh verification on EVERY party whose state EQUALS verified (Invariant 4.1).
Deleted: Check 2.2. Ordering 3 and Ordering 4 own it.
Check 3.1: An auditor MUST find verification id, verifying actor reference, verification method, verification result, evidence reference and verification instant on EVERY verification event (State 4).
Check 3.2: An auditor MUST find a re-read verification event unchanged (Invariant 5.1).
Check 3.3: An auditor MUST find a party's verification event list no shorter on a later read (Invariant 6.3).
Check 3.4: An auditor MUST find EVERY verification event whose verification result EQUALS EXACTLY ONE OF passed, failed (Operation 21).
Deleted: Check 4.1. Check 5.1 owns it.
Check 4.2: An auditor MUST find the prior state, the new state, an acting reference and an instant on EVERY state change event (State 5).
Check 4.3: An auditor MUST find a reason on EVERY state change event a reasoned action appended (State 7).
Check 4.4: An auditor MUST find a party's state change log no shorter on a later read (Invariant 8.2).
Check 5.1: An auditor MUST replay a party's state change log in insertion order from unverified to the party's state (Invariant 8.1, Ordering 3).
Check 5.2: An auditor MUST reconstruct EVERY party's enrollment, verification history and state history from one read (State 1, State 2, State 3).
Deleted: Check 6.1. Execution Contract Database 6 owns it.
Deleted: Check 6.2. Execution Contract Database 6 owns it.
Deleted: Check 6.3. Execution Contract Database 6 owns it.
Check 7.1: An auditor MUST find no party id on two parties (Identity 7).
Check 7.2: An auditor MUST find no verification id on two verification events (Identity 8).
Check 7.3: An auditor MUST find no state change id on two state change events (Identity 9).
Check 8.1: An auditor MUST partition the party records by state (State 1).
NOTE: watch the check no record answers (Check 2.2).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing an identity check performed MUST read the composing verification workflow (Non-goal 7).
External check 2: A deployment needing two parties resolved as one natural person MUST read the composing identity resolution (Identity 16, Non-goal 1).
External check 3: A deployment needing an enrollment field scrubbed MUST read the composing erasure coordination (Non-goal 3, Non-goal 12).
External check 4: A deployment needing an acting reference bound to an actor MUST read the composing Actor Identity attestation (Identity 15, Non-goal 15).
External check 5: A deployment needing a recorded instant anchored to wall time MUST read the composing trusted timestamping pattern (Ordering 5, Ordering 6).
External check 6: A deployment needing a document reference resolved MUST read the composing pattern's document records (Identity 13).
External check 7: A deployment needing a party's record retention bounded MUST read the composing Retention Window (Non-goal 13).
External check 8: A deployment needing an answer observed MUST read the composing Event Log (Non-goal 19).
Deleted: External check 9. Execution Contract Database 6 owns it.
Deleted: External check 10. Execution Contract Database 6 owns it.
External check 11: A deployment needing an evidence reference resolved MUST read the composing pattern's document records (Identity 14).

```

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
Non-goal 18: The atom MUST NOT link a party id across two trust domains.
Non-goal 19: The atom MUST NOT record an answer the atom gave.
Non-goal 20: The atom MUST NOT propagate a state change to a downstream system.
Non-goal 21: The atom MUST NOT terminate a party's open commitment.
Non-goal 22: The atom MUST NOT model a pending verification.
Non-goal 23: The atom MUST NOT guarantee that a party reaches verified.
```

NOTE: the owners — an identity resolution pattern (Non-goal 1, Non-goal 2); an attribute update pattern (Non-goal 3, Non-goal 4); an erasure coordination pattern (Non-goal 12, External check 3); [Retention Window](./retention-window.md) (Non-goal 13, Non-goal 14); the composing system (Non-goal 21); [Customer Onboarding](../compositions/customer-onboarding.md) (Non-goal 22, Composition note 2).

---

## Edge cases

### Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Clock semantics

```
Clock semantics 5: A recorded instant MUST NOT carry an ordering.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 7 owns it.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Indeterminate outcome

```
Indeterminate outcome 1: A caller MUST NOT retry an action whose answer the caller lost BEFORE reading the party (Execution Contract Error model 1).
Deleted: Indeterminate outcome 2. Execution Contract Error model 1 owns it.
Indeterminate outcome 3: A caller MUST NOT retry a lost [Enroll] BEFORE reading the database (Execution Contract Error model 1).
```

NOTE: open 2026-10-21-d — a caller who lost an [Enroll]'s answer reads the database before retrying (Indeterminate outcome 3), and how the caller finds the enrollment is not stated: no query axis matches a name, a date of birth or a document reference.

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: IF a string input EXCEEDS the length bound THEN an action MUST answer invalid-request.
Deleted: String 8. String 7 and GRACE-lang Closed vocabulary 29 own it.
```

Term string input: a required string input, date of birth OR a filter value — every caller-supplied string this atom accepts.

NOTE: open 2026-10-21-e — the verification result is no string input, so no string rule says how a verification result compares with passed and failed (Operation 21, Operation 25).

Term length bound: the maximum length the deployment declares for a string input.

NOTE: watch host obligations — this atom refuses a string input over the length bound on every action whose signature carries invalid-request (String 7, GRACE-lang Closed vocabulary 29), [Read] meeting no length refusal, and obliges the deployment to declare the bound (Capability requirement 7), where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one; Final Critique 6 cured the bound's reach.

---

## Composition notes

```
Composition note 1: A composing Customer Onboarding MUST gate regulated activity on the party whose state EQUALS verified.
Composition note 2: A composing Customer Onboarding MUST own the verification workflow.
Composition note 3: A composing External Onboarding MUST call [Enroll] ONLY AFTER an accepted invitation.
Composition note 4: A composing Actor Identity MUST attest the actor behind EVERY transitioning action.
Composition note 5: A composing Actor Identity MUST bind an attestation to a state change id.
Composition note 6: A composing Audit Trail MUST record EVERY verification event and EVERY state change event.
Composition note 7: A composing Consent MUST name the party id as the data subject reference.
Composition note 8: A composing Retention Window MUST NOT scrub an enrollment field.
Composition note 9: A composing erasure coordination pattern MUST record a scrub as an attributed event.
Composition note 10: A composing erasure coordination pattern MUST NOT scrub a custody field.
Composition note 11: A composing Event Log MUST append an event on EVERY admitted action.
Composition note 12: A composing Event Log MUST append an event on EVERY refused action.
```

NOTE: open 2026-10-21-j — the enrolling and verifying actor references have no route to attestation: Composition note 4 binds a composing Actor Identity to the transitioning actions alone (External check 4).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the deployment; the database; the database instance; the seam; the transition; a composing pattern; a caller; an auditor; a regulator; an investigator; a party; a verification event; a state change event; an action; a party action; a transitioning action; a refused action; an assigned id; an opaque reference; a string input; a filter; a filter axis; a filter value; a query; a party's verification event list length; a party's state change log length.

Term records: party — one external party, carrying party id, name, date of birth, document type, document reference, enrollment instant, enrolling actor reference, a state, a state change log and a verification event list. verification event — one identity check, carrying verification id, verifying actor reference, verification method, verification result, evidence reference and verification instant. state change event — one transition, carrying state change id, the prior state, the new state, an acting reference, an instant and, where the writer carries one, a reason.

Term record verbs: identify, assign, generate, change, share, carry, stand, read, answer, record, append, remove, leave, admit, offer, hold, refuse, write, find, resolve, name, compare, normalize, confirm, match, differ, route, register, create, pass, attest, cover, call, fall, precede, follow, sample, consume, supply, canonicalize, declare, compose, bind, decide, define, bound, reach, accept, trim, case-fold, compute, reproduce, reconstruct, replay, verify, detect, guarantee, take, derive, expose, store, own, enumerate, distinguish, select, order, deduplicate, scrub, parse, gate, count, schedule, propagate, terminate, link, suspend, reinstate, close, enroll, ignore, partition, retry, exceed, perform, score, model.

Term value sets: state = unverified | verified | suspended | closed. verification result = passed | failed. enrollment field = name | date of birth | document type | document reference | enrollment instant | enrolling actor reference.

Term bounds: length bound.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: party, verify answer, party id, verification event, state change event, assigned id, enrollment field, acting reference, reference, database instance, seam, transition, now, party action, transitioning action, state, state check, required string input, fresh verification, insertion order, length bound, reasoned action, custody field, evidence reference, query axes, admitted enroll, admitted verify, admitted suspend, admitted reinstate, admitted close, admitted read, string input, blank, verification result.

Term cited: the section titled Logic Confinement Principle in `execution-contract.md` — the seam and the transition.

Term composing pattern: [Actor Identity](./actor-identity.md), [Consent](./consent.md), [Retention Window](./retention-window.md), [Event Log](./event-log.md), [Audit Trail](../compositions/audit-trail.md), [Customer Onboarding](../compositions/customer-onboarding.md), [External Onboarding](../compositions/external-onboarding.md), an identity resolution pattern, an attribute update pattern, an erasure coordination pattern, a trusted timestamping pattern, a document records pattern.

#### Enroll

The behavior that records a new [Party] — assigning a fresh [Party Id], recording every enrollment field, stamping [Enrollment Instant], and standing the record in [Unverified]. Refused [Invalid Request] or [Storage Failure]. It creates rather than transitions, which is why a lost answer must not be retried blind.

Kind: Operation

#### Verify

The behavior that records one identity check as a [Verification Event] — its method, result, evidence and acting reference — and, where the party stands in [Unverified] and the result is `passed`, stands the party in [Verified] and appends a [State-Change Event] in the same transition. Records a check against a [Suspended] party without lifting the suspension.

Kind: Operation

#### Suspend

The transitioning action that stands a [Verified] party in [Suspended], recording the acting reference and a required [Reason]. Refused [Not Verifiable] against an [Unverified] party — there is no verified standing to suspend — and [Already Suspended] against a suspended one.

Kind: Operation

#### Reinstate

The transitioning action that returns a [Suspended] party to [Verified], refused [Not Suspended] against an [Unverified] or a [Verified] one. Admitted only where a [Fresh Verification] exists; otherwise [No Passed Verification Since Suspend]. The rule is the atom's central guarantee — a suspension is revoked trust, and restoring it takes evidence recorded since.

Kind: Operation

#### Close

The transitioning action that stands any non-closed party in [Closed], recording the acting reference and a required [Reason]. Absorbing: a closed party is refused [Verify], [Suspend] and [Reinstate] thereafter with [Already Closed], and returning needs a fresh [Enroll].

Kind: Operation

#### Read

The read-only query answering the [Party] records matching its [Query] in insertion order, each carrying its enrollment fields, its full [State-Change Log] and its full [Verification Event] list. Refuses a filter it cannot read ([Invalid Query]) rather than ignoring it.

Kind: Operation

#### Party

The record this atom defines: one external party's enrollment, verification history and state history. Carries [Party Id], [Name], [Date Of Birth], [Document Type], [Document Reference], [Enrollment Instant], [Enrolling Actor Reference], a [Current State], a [State-Change Log] and a [Verification Event] list.

Kind: Type
Projection: state

#### Verification Event

The record of one identity check, appended to a party and never changed. Carries [Verification Id], [Verifying Actor Reference], [Verification Method], [Verification Result], [Evidence Reference] and [Verification Instant]. It records that a check was made, by whom, how, and what it found — never that the check was in fact performed.

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

The party's legal name at enrollment, stored as supplied — no normalization, no case folding, no transliteration. Immutable under the atom's actions; a later legal name change is a composing pattern's event, not an edit here.

Kind:       Field
Field of:   Party
Projection: name

#### Date Of Birth

The party's date of birth at enrollment, as a calendar date that does not exceed [Now]. Immutable under the atom's actions.

Kind:       Field
Field of:   Party
Projection: date_of_birth

#### Document Type

The class of identity document presented — `passport`, `national-id`, `drivers-license`. Opaque to the atom; which values a regime admits is the composing system's.

Kind:       Field
Field of:   Party
Projection: document_type

#### Document Reference

The opaque pointer to the identity document record in the composing pattern's document records. Never resolved here.

Kind:       Field
Field of:   Party
Projection: document_ref

#### Enrollment Instant

The instant the party was enrolled, stamped from [Now]. Immutable, and one of the three fields an erasure scrub must leave.

Kind:       Field
Field of:   Party
Projection: enrolled_at

#### Enrolling Actor Reference

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

#### Verifying Actor Reference

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

#### Evidence Reference

The opaque pointer to the evidence record supporting the check. Never resolved here.

Kind:       Field
Field of:   Verification Event
Projection: evidence_ref

#### Verification Instant

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
Parameter of: Suspend, Reinstate and Close
Projection:   reason

#### Fresh Verification

A [Verification Event] carrying `passed` that follows the party's most recent [Suspend] in insertion order — or the enrollment, where the party was never suspended. What [Reinstate] requires, and what every [Verified] party carries.

Kind: Type
Projection: fresh_verification

#### Now

The wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it — never read inside the transition and never supplied by the business caller.

Kind:         Parameter
Parameter of: Enroll, Verify, Suspend, Reinstate and Close
Projection:   now

#### Query

The filter a [Read] carries, over exactly three axes: [Party Id], [Current State], and a range on [Enrollment Instant]. An axis outside those, or a value its axis does not admit (a blank [Party Id] among them), is [Invalid Query] rather than a silently dropped filter; a well-formed [Party Id] naming no party matches nothing.

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

The refusal returned when a required string input is blank, a [Date Of Birth] parses as no calendar date or exceeds [Now], a [Verification Result] is neither `passed` nor failed, or — on [Enroll] and a party action only — a string input exceeds the deployment's length bound. A blank [Party Id] earns it ahead of [Not Known], which a well-formed one naming no party earns (Operation 12); every other field fault earns it after every state check passes.

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

The refusal [Read] returns for a filter axis outside the query axes or a filter value its axis does not admit. Refusing rather than ignoring, because a silently dropped filter answers a different question from the one asked.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

#### Storage Failure

The refusal any writing action returns when the database refuses the write after every precondition passes. No record the action would have written is persisted. [Read] never returns it.

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
[Document Reference]: #document-reference
[Enrollment Instant]: #enrollment-instant
[Enrolling Actor Reference]: #enrolling-actor-reference
[Current State]: #current-state
[State-Change Log]: #state-change-log
[Verification Id]: #verification-id
[Verifying Actor Reference]: #verifying-actor-reference
[Verification Method]: #verification-method
[Verification Result]: #verification-result
[Evidence Reference]: #evidence-reference
[Verification Instant]: #verification-instant
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
- **BSA/AML — 31 CFR Part 1020 (FinCEN — the Financial Crimes Enforcement Network — Customer Identification Program)** — minimum identity attributes, verification by documentary or non-documentary method, and five-year retention past the relationship's end. The enrollment fields are the attributes; [Verification Method] records which kind was used; retention is [Retention Window](./retention-window.md)'s (Non-goal 13).
- **FinCEN Beneficial Ownership Rule — 31 CFR section 1010.230** — each beneficial owner is a party record in their own right; the ownership relationship is not.
- **EU (European Union) 5th Anti-Money Laundering Directive (AMLD5)** — enhanced due diligence and beneficial-ownership registries, aligned with FATF.
- **GDPR Article 4(1)** — the enrollment fields are personal data, and this atom is the corpus's clearest case of an atom that holds some rather than opaque references alone.
- **GDPR Articles 5–6** — lawful basis for processing, typically Article 6(1)(c) or 6(1)(b); processing *beyond* the regulatory obligation is [Consent](./consent.md)'s.
- **GDPR Article 17 (right to erasure)** — in direct tension with the retention obligations above. This atom does not resolve it: Non-goal 3 forbids the atom to change an enrollment field, and the composing erasure pattern is the authorized scrub (External check 3, Non-goal 12).
- **HIPAA 45 CFR section 164.514** — patient identity must be established before protected health information records exist; the patient is a party here.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture, and the discipline of composing the verification workflow, deduplication, risk scoring and ownership structure as separate concepts.
- **Grace Commons regulated-atom conventions** — the adversarial scenarios and the acceptance section, from `pressure-testing.md`.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — party-identity.tla + 1 twin, 2026-06-03
last gate: 2026-10-27 — Final Critique 7 — foundational count 2, not clean, no sample

open:
- 2026-10-21-d · refining · Indeterminate outcome 3; Term query axes · a caller who lost an [Enroll]'s answer must read the database before retrying, and no axis finds a party by its enrollment fields, so only an unfiltered read finds the enrollment → name how the caller finds it
- 2026-10-21-e · refining · Term string input; String 1 through 6; Operation 21, 25 · the verification result is outside the string inputs, so no string rule says how it compares with passed and failed → bring it into the string policy, or say its comparison
- 2026-10-21-f · refining · Operation 2, 3; Date Of Birth entry · the date of birth's format, and the instant of the day it stands for when Operation 3 compares it with now, are undeclared, so a date of birth of today can answer two ways → declare both
- 2026-10-21-j · refining · Composition note 4; External check 4 · the enrolling and verifying actor references have no route to attestation, Composition note 4 binding Actor Identity only to transitioning actions → say whether an enrollment and a check are attested, and by whom
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/party-identity.md`; the migration that got it here is in [its history](./party-identity.hist.md).

- **2026-09-13 — The EOS strip test: no domain tag, no rename, and the coupling is in the attributes rather than the name.** *Chose:* leave the atom untagged and unrenamed, and record where the domain actually touches it. *Over:* a `domain:` tag, or a reframe of the kind [Observation](./observation.md) took. *Because:* the test asks whether stripping the domain leaves a freestanding neutral primitive, and here it does. Every invariant is neutral — records are never removed, a terminal absorbs, events are append-only and immutable, a standing rests on recorded evidence since the last revocation. None of them is derivable only from banking or healthcare; the same shape governs a licence, an accreditation, a calibration status. The *name* is already the stripped form: party is legal and commercial vocabulary rather than one industry's, which is why the atom is not called Customer Identity or Patient Identity. What is domain-flavoured is the enrollment attribute set — name, date of birth, document type, document reference — which is natural-person identity-document vocabulary, and the atom already treats two of the four as opaque strings it never interprets. The honest boundary is that this atom is a neutral standing-and-evidence primitive carrying one concrete attribute schema, and the question of whether that schema should be an opaque attribute bag belongs on the docket rather than in a rename.
- **2026-09-13 — no-passed-verification-since-suspend stays a purpose-built rejection arm.** *Chose:* the arm the prose already carried. *Over:* folding it into not-suspended or invalid-request, which is what the corpus's closed answer set usually pressures a rare condition into. *Because:* this one is not rare and not adjacent to anything — it is the atom's central guarantee failing, and a caller receiving it knows exactly what to do next, which is to record a check. It is worth naming as the corpus's counter-example: the docket row on answers charged to the nearest arm is about conditions that could not justify the cost of their own name, and this is what paying that cost looks like.
- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the party store supplied under Execution Contract Store 1 through 4 and Execution Contract Order 1 (Capability requirement 10), and the sixteen rules that restated them tombstoned to their owner — Capability requirement 5, Operation 38, Invariant 11.1 and Atomic writes 1, 3 and 4, an action's records committed whole in one transition, and Invariant 1.2, no partial party on storage-failure, to Store 1; Invariant 11.2, no record of a refused action on storage-failure, and Atomic writes 2, an uncommitted transition discarded whole, to Store 1 and Store 3; Capability requirement 4, a write acknowledged only once it commits, to Store 3; Concurrency 1, the state checks and the state change as one operation, to Store 1 and Store 2; Capability requirement 3 and Concurrency 2 and 3, two party actions on one party serialized and the later answering from what the earlier committed, to Store 2; Ordering 1 and 2, the store instance appending each event in its own insertion order, to Order 1; rules 190 to 175. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. Insertion order stays the atom's authority and a recorded instant advisory (Ordering 3 through 6): a fresh verification is a passed verification event that follows the most recent suspend, a position across a party's two event lists, and [Read] answers parties in insertion order, and the atom carries no sequence of its own to order either, so it cites Order 1, the first specification to. Every check that compares reads compares the auditor's own reads, or reconstructs from one read (Check 5.2), so it cites no History 1. A refused action leaving the party as the call found it and writing nothing stays the atom's own (Operation 41 through 43), as do the records it never removes or changes and the counts and lengths that never fall (Invariant 1.1, 1.3, 5.1, 6.1 through 6.3, 8.2); what the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the page's order — a party action answering not-known, then its state rejections, [Reinstate]'s not-suspended ahead of no-passed-verification-since-suspend, then invalid-request on a field fault, and storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 10, Execution Contract Refusal 1); the pairs that only stated it deleted to Refusal 1: Operation 17 (a state rejection only for a party id naming a party), Operation 19 (no-passed-verification-since-suspend only on a suspended party), Operation 20 (a field fault only once every state check passes) and Operation 40 (storage-failure behind every precondition), with Term state rejection, which only Operation 17 read; rules 175 to 171. Operation 12 stays the page's own: a blank party id answers invalid-request ahead of not-known, while every other field fault answers after the state checks, so invalid-request holds two places in the order and no fixed line can carry both; Refusal 1 reads a refusal Operation 12 keeps from a call as not applying to it. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-21 — The length bound refuses on the writes alone; the scrub and the purge belong to composing patterns; a range's bounds are no forbidden input.** *Chose:* String 7 and String 8 refusing an over-long string input on [Enroll] and the party actions, and [Read] meeting no length refusal; Invariant 7.1 deleted to Non-goal 3, so the atom never changes an enrollment field and a composing erasure coordination scrubs the fields the custody fields leave; Invariant 1.3 deleted to Invariant 1.1 and Execution Contract Database 4, so the atom never removes a party record and a composed Retention Window destroys one only as its own page says; Check 6.1 through 6.3, which cannot tell either act from a violation from the party records alone, moved to External check 9 and External check 10; and Operation 59 deleted to the rules that stamp every recorded instant from now (Operation 6, Operation 24, Operation 34). *Over:* a length rule on every action, which [Read]'s signature cannot answer; an immutability with no actor and a party count that may never fall, which break at the first scrub and the first purge the page itself sends to composing patterns; and a rule against every caller-supplied instant, which forbids the range [Read] admits. *Because:* Final Critique 6 found each a divergence between conforming builds, two rules no build can both obey, or a check a conforming deployment fails, and the page's own earlier text held each cure: Final Critique 5 capped write inputs alone, held the enrollment fields immutable under the atom's action contract with the scrub a composing Erasure Coordination pattern's, kept party records permanent from the atom's perspective while Retention Window decides when destruction becomes permitted, and refused caller timestamps only for the instants the atom stamps, beside a timestamp range filter. What each action answers on a call the guards admit is unchanged, save that [Read] no longer measures a filter value against the length bound.

- **2026-10-22 — An admitted call, a composed scrub or purge, and the reach of a length refusal are stated once.** *Chose:* the five admitted terms (enroll, verify, suspend, reinstate, close) citing Execution Contract Read 4 for what an action admits, in place of the commit clause each carried; External check 9 and External check 10, a composing erasure coordination's scrub events and a composing Retention Window's purge records read beside the party records, deleted to Execution Contract Database 6, with the tombstones of Check 6.1 through 6.3, which named them, now naming the contract; String 7 written again as the page first had it, an over-long string input answering invalid-request on an action, and String 8, the per-action split this page's sixth Final Critique wrote, deleted to String 7 and GRACE-lang Closed vocabulary 29, under which the rule binds [Enroll] and the four party actions, whose signatures carry invalid-request, and not [Read], whose signature carries invalid-query alone; Database 6 and Read 4 cited on Capability requirement 10; rules 168 to 165. *Over:* the page stating for itself which calls its effect rules reach, that a scrub or purge another specification declares is answered outside the party records, and which actions the length refusal reaches. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect, the composed erasure and the category reach among them; this page's sixth Final Critique had made them one specification at a time. What each action does and answers is unchanged.

NOTE: End of Party Identity.
