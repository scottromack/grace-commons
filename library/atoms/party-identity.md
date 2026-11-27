---
title: Party Identity
id: 50
audience: common
---

# Party Identity

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Party Identity is a lasting, verifiable identity record for an external party — a customer, a patient, a counterparty or a beneficial owner (the person who ultimately owns or controls a company). It answers the question every regulated system settles before doing business: *who is this party, and has their identity been checked?*

The record keeps the party's enrollment, the full history of identity checks — each one's method, result and supporting evidence — and every later change, with who made it and why. A party stands in one of four states — unverified, verified, suspended or closed — and closed is permanent, so a party who returns after closure needs a fresh enrollment.

The central guarantee is that a party cannot stand verified without a passing check recorded since the most recent suspension, so a downstream process can require *a verified party* and trust that the standing rests on a recorded check rather than a flipped flag.

Party Identity records the results of identity checks and does not perform them — no document scan, no biometric match, no sanctions screen — and it does not deduplicate parties; it keeps parties apart from actors: an actor signs, a party is verified. Proving who took an action is the work of a pattern that attests actors; Party Identity keeps the recorded checks a party's verified standing rests on. It holds every party id it mints.

Every regulated system that deals with external parties — banks onboarding customers, hospitals enrolling patients, broker-dealers establishing counterparties, employers verifying staff — must establish *who* the party is before regulated activity begins, and must keep that record through the party's whole lifecycle. The shape is constant: attributes are collected, identity is verified against external evidence, the party becomes verified, and downstream activity relies on that. When circumstances change — a sanctions match, an expired document, an investigation — the party is suspended, re-verified, and either reinstated or permanently closed.

The compliance framing is consistent across regimes. FATF (Financial Action Task Force — the international anti-money-laundering standard-setter) Recommendation 10 requires customer due diligence before a business relationship begins. The BSA (Bank Secrecy Act) and AML (Anti-Money Laundering) Customer Identification Program (31 CFR — the US Code of Federal Regulations — Part 1020) sets minimum attributes and five-year retention past the relationship's end. GDPR (General Data Protection Regulation — the European Union's data-protection law) Article 4(1) makes the attributes collected here personal data. HIPAA (the US Health Insurance Portability and Accountability Act) requires patient identity before clinical records exist. The domain varies; the structural obligation does not.

## What it keeps

### The parties

```
Identity 1: The atom MUST identify a party by the party id.
Identity 2: The atom MUST identify a verification event by the verification id.
Identity 3: The atom MUST identify a state change event by the state change id.
Identity 4: The atom MUST take an assigned id from the id material the seam supplies.
Deleted: Identity 5. Execution Contract Logic confinement 3 owns it: the host injects every id the atom assigns.
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
```

Term party: the record this atom holds — one external party's enrollment, verification history and state history.

Term verification event: the record of one identity check — its method, result, evidence and acting reference — appended to a party and never changed.

Term state change event: the record of one transition — the prior state, the new state, the acting reference, the instant and, where the action carries one, the reason — appended to a party and never changed.

Term enrollment field: name | date of birth | document type | document reference | enrollment instant | enrolling actor reference — what a party carries from enrollment and the atom never changes.

Term acting reference: enrolling actor reference, verifying actor reference, suspending actor reference, reinstating actor reference OR closing actor reference — the one reference an action's call carries for who acted, which the action records. On a state change event an admitted verify appends, the acting reference is the verifying actor reference.

Term reference: an assigned id, an acting reference, document reference OR evidence reference — every opaque reference this atom records.

NOTE: watch the seam citation (Term seam, Term transition).

```
State 1: EVERY party MUST carry party id, EVERY enrollment field and a state.
State 2: EVERY party MUST carry a state change log.
State 3: EVERY party MUST carry a verification event list.
State 4: EVERY verification event MUST carry verification id, verifying actor reference, verification method, verification result, evidence reference and verification instant.
State 5: EVERY state change event MUST carry state change id, the prior state, the new state, an acting reference and an instant.
State 6: A state change event MAY carry a reason.
State 7: EVERY state change event a reasoned action appended MUST carry a reason.
```

### Ordering

```
Ordering 3: The atom MUST read the most recent event from insertion order.
Ordering 4: The atom MUST NOT read an ordering from a recorded instant.
Ordering 5: A recorded instant MUST NOT bound a reconstruction.
Ordering 6: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

---

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

The party's date of birth at enrollment, as a calendar date in the date form, no later than the day of the party's [Enroll]. Immutable under the atom's actions.

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

The instant the party was enrolled, stamped from [Now]. Immutable.

Kind:       Field
Field of:   Party
Projection: enrolled_at

#### Enrolling Actor Reference

The opaque reference naming who enrolled the party. Attribution only — binding it to a verifiable actor is the work of a pattern that attests actors.

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

#### Fresh Verification

A [Verification Event] carrying `passed` that follows the party's most recent [Suspend] in insertion order — or the enrollment, where the party was never suspended. What [Reinstate] requires, and what every [Verified] party carries.

Kind: Type
Projection: fresh_verification

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

Term fresh verification: a verification event whose verification result EQUALS passed that follows the party's most recent suspend in insertion order, or that follows the enrollment where no suspend EXISTS.

Term state: unverified | verified | suspended | closed.

## What people do

### Every action

Term verify answer: verification id and an optional state change id — what verify answers, written `verify_answer(verification_id, state_change_id)` in the signature.

```
Operation 1: IF a required string input EQUALS blank THEN a writing action MUST answer invalid-request.
Operation 4: An admitted enroll MUST assign a fresh party id.
Operation 5: An admitted enroll MUST record EVERY enrollment field.
Operation 6: An admitted enroll MUST record now as enrollment instant.
Operation 7: An admitted enroll MUST stand the party in unverified.
Operation 8: An admitted enroll MUST answer the party id.
Operation 10: IF party id EQUALS blank THEN a party action MUST answer invalid-request.
Operation 11: IF the party id names no party THEN a party action MUST answer not-known.
Operation 12: A party action MUST answer not-known ONLY IF party id DOES NOT EQUAL blank.
Operation 13: IF the party's state EQUALS closed THEN a party action MUST answer already-closed.
Operation 22: An admitted verify MUST append a verification event carrying a fresh verification id.
Operation 23: An admitted verify MUST record verifying actor reference, verification method, verification result and evidence reference on the verification event.
Operation 24: An admitted verify MUST record now as the verification event's verification instant.
Operation 25: IF the party's state EQUALS unverified AND the verification result EQUALS passed THEN an admitted verify MUST stand the party in verified.
Operation 26: An admitted verify MUST NOT change the party's state outside the unverified-to-verified transition.
Operation 27: An admitted verify MUST answer the verification id.
Operation 29: An admitted verify driving no transition MUST NOT answer a state change id.
Operation 30: An admitted suspend MUST stand the party in suspended.
Operation 31: An admitted reinstate MUST stand the party in verified.
Operation 32: An admitted close MUST stand the party in closed.
Operation 33: A transitioning action MUST append a state change event carrying a fresh state change id.
Operation 34: A transitioning action MUST record the prior state, the new state, the acting reference and now on the state change event.
Operation 35: A reasoned action MUST record reason on the state change event.
Operation 36: An admitted verify MUST NOT record a reason on a state change event.
Operation 37: A transitioning action MUST answer the state change id.
Operation 41: A refused action MUST leave the party as the call found the party.
Operation 43: A refused action MUST NOT append an event.
Operation 62: EVERY admitted enroll, admitted verify, admitted suspend, admitted reinstate AND admitted close MUST append one party events record through the atom's journal need.
Operation 44: The atom MUST NOT offer a party removal surface.
Operation 45: The atom MUST NOT offer an event removal surface.
Operation 46: The atom MUST NOT offer an enrollment field update surface.
Operation 47: The atom MUST NOT offer a reopen surface.
Operation 51: An admitted read MUST answer EVERY matching party.
Operation 52: An admitted read MUST answer the state change log and the verification event list PER matching party, each in insertion order.
Operation 53: An admitted read MUST answer the matching parties in insertion order.
Operation 54: An admitted read MUST answer an empty sequence where no party matches.
Operation 61: An admitted read MUST NOT answer a party that is not a matching party.
```

NOTE: watch the blank id (Operation 12, Operation 16, Operation 18).

NOTE: watch read-order polarity (Operation 52).

NOTE: watch the listing page (Operation 51, Operation 61, Term matching party).

Term date form: four ASCII digits of year from 0001 to 9999, two ASCII digits of month and two of day, joined by hyphens, as `1984-03-02` — the calendar date form of ISO 8601 (the International Organization for Standardization's standard for writing dates and times).

Term date of birth start: the first instant of the calendar date the date of birth names, in the timezone the deployment takes its clock reading in (Execution Contract Logic confinement 7).

Term party action: [Verify] | [Suspend] | [Reinstate] | [Close] — every action naming a party by party id, including a refused one.

Term writing action: [Enroll] | [Verify] | [Suspend] | [Reinstate] | [Close] — every action that writes; [Read] is none of them (Operation 55).

Term transitioning action: a party action that changes the party's state — an admitted suspend, an admitted reinstate, an admitted close, OR an admitted verify driving the unverified-to-verified transition.

Term reasoned action: an admitted suspend, an admitted reinstate OR an admitted close — every transitioning action that carries a caller-supplied reason.

Term state check: Operation 11, Operation 13, Operation 14, Operation 15, Operation 16 and Operation 18 — every check a party action makes on the party's existence and standing before reading the call's remaining inputs.

Term required string input: name, document type, document reference, verification method, evidence reference, reason, an acting reference OR party id — every string an action refuses when blank.

Term insertion order: the order a database instance appended its records; authoritative for this atom, where a recorded instant is advisory.

Term query axes: party id, state and a range over enrollment instant — every filter axis [Read] admits, the party id axis admitting every value that DOES NOT EQUAL blank, one naming no party or exceeding the length bound among them, the state axis each state, and the range's start and end each an instant (Execution Contract Query 1).

NOTE: watch the blank filter value (Term query axes).

Term matching party: a party the query matches — one whose party id EQUALS the filter's party id where the query carries that filter, whose state EQUALS the filter's state where it carries that filter, and whose enrollment instant lies inside the range where it carries that filter (Execution Contract Query 3), every filter the query carries met (Execution Contract Query 4).

Term admitted enroll: an [Enroll] call the action admits (Execution Contract Read 4).

Term admitted verify: a [Verify] call the action admits (Execution Contract Read 4).

Term admitted suspend: a [Suspend] call the action admits (Execution Contract Read 4).

Term admitted reinstate: a [Reinstate] call the action admits (Execution Contract Read 4).

Term admitted close: a [Close] call the action admits (Execution Contract Read 4).

Term admitted read: a [Read] call that Operation 48 and Operation 49 admit.

#### Invalid Request

The refusal returned when a required string input is blank, a [Date Of Birth] parses as no calendar date in the date form or names a day that starts after [Now], a [Verification Result] is neither `passed` nor failed, or — on [Enroll] and a party action only — a string input exceeds the length bound. A blank [Party Id] earns it ahead of [Not Known], which a well-formed one naming no party earns (Operation 12); every other field fault earns it after every state check passes.

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

#### Storage Failure

The refusal any writing action returns when the database refuses the write after every precondition passes. No record the action would have written is persisted. [Read] never returns it.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Enroll

#### Enroll

The behavior that records a new [Party] — assigning a fresh [Party Id], recording every enrollment field, stamping [Enrollment Instant], and standing the record in [Unverified]. Refused [Invalid Request] or [Storage Failure]. It creates rather than transitions, which is why a lost answer must not be retried blind.

Kind: Operation

```
enroll(name, date_of_birth, document_type, document_ref, enrolling_actor_ref)
  answers party_id
  refuses invalid-request | storage-failure
```

```
Operation 2: IF the date of birth parses as no calendar date in the date form THEN [Enroll] MUST answer invalid-request.
Operation 3: IF now PRECEDES the date of birth start THEN [Enroll] MUST answer invalid-request.
Operation 9: [Enroll] MUST NOT answer not-known.
Operation 42: A refused [Enroll] MUST NOT record a party.
```

### Verify

#### Verify

The behavior that records one identity check as a [Verification Event] — its method, result, evidence and acting reference — and, where the party stands in [Unverified] and the result is `passed`, stands the party in [Verified] and appends a [State-Change Event] in the same transition. Records a check against a [Suspended] party without lifting the suspension.

Kind: Operation

```
verify(party_id, verifying_actor_ref, verification_method, verification_result, evidence_ref)
  answers verify_answer(verification_id, state_change_id)
  refuses not-known | already-closed | invalid-request | storage-failure
```

```
Operation 21: IF the verification result DOES NOT EQUAL passed AND the verification result DOES NOT EQUAL failed THEN [Verify] MUST answer invalid-request.
```

### Suspend

#### Suspend

The transitioning action that stands a [Verified] party in [Suspended], recording the acting reference and a required [Reason]. Refused [Not Verifiable] against an [Unverified] party — there is no verified standing to suspend — and [Already Suspended] against a suspended one.

Kind: Operation

```
suspend(party_id, suspending_actor_ref, reason)
  answers state_change_id
  refuses not-known | already-closed | not-verifiable | already-suspended | invalid-request | storage-failure
```

```
Operation 14: IF the party's state EQUALS unverified THEN [Suspend] MUST answer not-verifiable.
Operation 15: IF the party's state EQUALS suspended THEN [Suspend] MUST answer already-suspended.
```

`suspend(party_qh9, ...)` on the unverified party → not-verifiable — there is no verified standing to suspend. `reinstate(party_pk3, ...)` while verified → not-suspended. `verify(party_closed, ...)` → already-closed. `suspend("", ...)` → invalid-request, answered ahead of not-known (Operation 10, Operation 12); `suspend(party_unknown, ...)` → not-known. `close(party_zz1, officer_o7, "  ")` on the already-closed party → already-closed, not invalid-request: the state checks run first (Execution Contract Refusal 1).

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

### Reinstate

#### Reinstate

The transitioning action that returns a [Suspended] party to [Verified], refused [Not Suspended] against an [Unverified] or a [Verified] one. Admitted only where a [Fresh Verification] exists; otherwise [No Passed Verification Since Suspend]. The rule is the atom's central guarantee — a suspension is revoked trust, and restoring it takes evidence recorded since.

Kind: Operation

```
reinstate(party_id, reinstating_actor_ref, reason)
  answers state_change_id
  refuses not-known | already-closed | not-suspended | no-passed-verification-since-suspend | invalid-request | storage-failure
```

```
Operation 16: IF the party's state EQUALS unverified OR the party's state EQUALS verified THEN [Reinstate] MUST answer not-suspended.
Operation 18: IF the party's state EQUALS suspended AND no fresh verification EXISTS THEN [Reinstate] MUST answer no-passed-verification-since-suspend.
```

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

### Close

#### Close

The transitioning action that stands any non-closed party in [Closed], recording the acting reference and a required [Reason]. Absorbing: a closed party is refused [Verify], [Suspend] and [Reinstate] thereafter with [Already Closed], and returning needs a fresh [Enroll].

Kind: Operation

```
close(party_id, closing_actor_ref, reason)
  answers state_change_id
  refuses not-known | already-closed | invalid-request | storage-failure
```

### Read

#### Read

The read-only query answering the [Party] records matching its [Query] in insertion order, each carrying its enrollment fields, its full [State-Change Log] and its full [Verification Event] list. Refuses a filter it cannot read ([Invalid Query]) rather than ignoring it.

Kind: Operation

```
read(query)
  answers the matching parties
  refuses invalid-query
```

```
Operation 48: IF a filter axis IS NOT IN the query axes THEN [Read] MUST answer invalid-query.
Operation 49: IF a filter value IS NOT IN the axis's admitted values THEN [Read] MUST answer invalid-query.
Operation 50: [Read] MUST NOT ignore an unreadable filter.
Operation 55: [Read] MUST NOT record a field.
Operation 56: [Read] MUST NOT answer storage-failure.
Operation 60: [Read] MUST NOT answer invalid-request.
```

#### Query

The filter a [Read] carries, over exactly three axes: [Party Id], [Current State], and a range on [Enrollment Instant]. An axis outside those, or a value its axis does not admit (a blank [Party Id] among them), is [Invalid Query] rather than a silently dropped filter; a well-formed [Party Id] naming no party, as every one over the length bound does (Execution Contract Input 2), matches nothing.

Kind:         Parameter
Parameter of: Read
Projection:   query

#### Invalid Query

The refusal [Read] returns for a filter axis outside the query axes or a filter value its axis does not admit. Refusing rather than ignoring, because a silently dropped filter answers a different question from the one asked.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

## What is and what should never be (Invariants)

- **Invariant 1 — Party record permanence.**
  ```
  Invariant 1.1: The atom MUST NOT remove a party from the database.
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
- **Invariant 8 — No transition is silent.**
  ```
  Invariant 8.1: EVERY party MUST stand in the state the party's state change log reaches from unverified in insertion order.
  Invariant 8.2: A party's state change log length MUST NOT fall.
  ```

## When something happens

### Indeterminate outcome

```
Indeterminate outcome 1: A caller MUST NOT retry an action whose answer the caller lost BEFORE reading the party (Execution Contract Error model 1).
Indeterminate outcome 3: A caller MUST NOT retry a lost [Enroll] BEFORE reading the database (Execution Contract Error model 1).
```

NOTE: a caller who lost an [Enroll]'s answer reads the parties without a party id filter (Indeterminate outcome 3): a query carrying no filter matches every party (Execution Contract Query 4), each party answered with its enrollment fields (Operation 51, State 1), among them the name, date of birth and document reference the lost call carried, so the read narrows to candidates. The enrolling actor reference narrows them further, and a range over enrollment instant does so only as far as the deployment's clock allows (Execution Contract Logic confinement 7). The atom detects no duplicate (Non-goal 1, Identity 16), so where two identical enrollments remain, the caller treats both as live or closes one with a reason, as the enrollment-in-error example does.

## While something is so

### Clock semantics

```
Clock semantics 5: A recorded instant MUST NOT carry an ordering.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: IF a string input EXCEEDS the length bound THEN a writing action MUST answer invalid-request.
```

Term string input: a required string input, date of birth, verification result OR a filter value — every caller-supplied string this atom accepts.

---

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the id material at the seam.
Capability requirement 7: The deployment MAY declare the length bound PER Execution Contract Input 2.
Capability requirement 10: The deployment MUST supply the party records PER Execution Contract Database 1 through 7, Execution Contract Order 1, Execution Contract Read 4, Execution Contract Refusal 1 and Execution Contract Query 1 through 4.
Capability requirement 11: The deployment MUST supply id material naming no record of the database instance.
Deleted: Capability requirement 12. Execution Contract Logic confinement 16 owns it: the host supplies one id it allocates to one call.
Deleted: Capability requirement 13. Execution Contract Input 2 owns it: the host allocates an id that is not blank.
Deleted: Capability requirement 14. Execution Contract Input 2 owns it: the host allocates an id that does not exceed the cap.
Capability requirement 15: The deployment MUST supply id material whose verification id DOES NOT EQUAL the state change id.
```

#### Reason

The caller-supplied basis for a suspension, a reinstatement or a closure. Required and never blank on those three; absent on a [Verify]-driven transition, where the [Verification Event] is the basis.

Kind:         Parameter
Parameter of: Suspend, Reinstate and Close
Projection:   reason

#### Now

The wall-time reading the host takes at the seam and hands to the transition (Execution Contract Logic confinement 11) — never read inside the transition and never supplied by the business caller.

Kind:         Parameter
Parameter of: Enroll, Verify, Suspend, Reinstate and Close
Projection:   now

Term assigned id: party id, verification id OR state change id — every opaque name this atom assigns, each fresh: carried by no record of the database instance when the atom assigns it (Capability requirement 11), supplied to one call (Execution Contract Logic confinement 16), and not blank and within the length bound (Execution Contract Input 2).

Term database instance: one named database a call is routed to; assigned id uniqueness ranges over one instance.

Term seam: the atom's I/O (input and output) boundary; the host injects the clock reading and the id material here.

Term id material: what the seam supplies to one call for the ids it assigns — the party id on an admitted enroll, the verification id and the state change id on an admitted verify, the state change id unused where the verify drives no transition (Operation 29), and the state change id on every other transitioning action (Operation 4, Operation 22, Operation 33).

Term transition: the atom's evaluation of one call against the party records.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term length bound: the maximum length of a string input and of an assigned id in Unicode code points; 1,024 code points where a deployment declares none.

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice.

Term need key: key actor id; pairs acting references.

Term need journal: records party events; calls append; arms event_id.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key party id; carried by parties; calls Read.

## Left to others

```
Non-goal 1: The atom MUST NOT detect a duplicate party.
Non-goal 2: A deployment needing duplicates resolved MUST compose an identity resolution pattern.
Non-goal 3: The atom MUST NOT change an enrollment field.
Non-goal 4: A deployment needing an attribute update MUST compose an attribute update pattern.
Non-goal 5: The atom MUST NOT perform an identity check.
Non-goal 6: The atom MUST NOT read a sanctions list.
Deleted: Non-goal 7. Non-goal 5 and Composition note 2 own it: the atom runs no verification workflow, and which pattern does is the app's choice.
Non-goal 8: The atom MUST NOT schedule a re-verification.
Non-goal 9: The atom MUST NOT count a failed verification.
Non-goal 10: The atom MUST NOT score a party's risk.
Non-goal 11: The atom MUST NOT model an ownership relationship.
Non-goal 12: The atom MUST NOT scrub an enrollment field.
Non-goal 13: The atom MUST NOT bound a party's retention.
Deleted: Non-goal 14. Non-goal 13 owns it: the atom bounds no retention, and which pattern does is the app's choice.
Non-goal 15: The atom MUST NOT bind an acting reference to an actor.
Deleted: Non-goal 16. Non-goal 15 owns it: the atom binds no acting reference to an actor, and which pattern attests an actor is the app's choice.
Non-goal 17: The atom MUST NOT model a representative acting for a party.
Non-goal 18: The atom MUST NOT link a party id across two trust domains.
Non-goal 19: The atom MUST NOT record an answer the atom gave.
Non-goal 20: The atom MUST NOT propagate a state change to a downstream system.
Non-goal 21: The atom MUST NOT terminate a party's open commitment.
Non-goal 22: The atom MUST NOT model a pending verification.
Non-goal 23: The atom MUST NOT guarantee that a party reaches verified.
```

NOTE: the owners — an identity resolution pattern (Non-goal 1, Non-goal 2); an attribute update pattern (Non-goal 3, Non-goal 4); a pattern that bounds retention (Non-goal 12, Non-goal 13); the composing system (Non-goal 21); the pattern that runs the verification workflow (Non-goal 5, Non-goal 22, Composition note 2).

---

```
Composition note 1: A composing pattern that opens activity to a party MUST gate the activity opened to a party on the party whose state EQUALS verified.
Composition note 2: A composing pattern that runs the verification workflow MUST own the verification workflow.
Composition note 3: A composing pattern that invites a party MUST call [Enroll] ONLY AFTER the invited party accepts.
Composition note 4: A composing pattern that attests actors MUST attest the actor behind EVERY admitted enroll, EVERY admitted verify, EVERY admitted suspend, EVERY admitted reinstate AND EVERY admitted close.
Composition note 5: A composing pattern that attests actors MUST bind an attestation to EVERY assigned id a writing action answers.
Composition note 6: A composing pattern that keeps an audit trail MUST record EVERY verification event and EVERY state change event.
Composition note 7: A composing pattern that records consent MUST name the party id as the data subject.
Composition note 8: A composing pattern MUST NOT scrub an enrollment field.
Deleted: Composition note 11. Operation 62 owns it: the atom appends through its own journal need, and which atom serves the need is the app's choice.
Deleted: Composition note 12. Operation 43 owns it: a refused action commits nothing, so no journal holds it.
```

---

Term composing pattern: a pattern an app wires beside this atom — one that attests actors, records consent, bounds retention, keeps an audit trail, runs the verification workflow or invites a party; an identity resolution pattern, an attribute update pattern, a trusted timestamping pattern or a document records pattern.

## Example

### Banking — onboarding under BSA/AML

`enroll("Ada Okafor", 1984-03-02, "passport", doc_p41, officer_o7)` → `party_pk3`, standing unverified. A document check runs elsewhere; its result lands here: `verify(party_pk3, officer_o7, "manual-document-review", passed, ev_c19)` → `(ver_v88, chg_s12)`. The party now stands verified, and both ids come back — one binds an attestation to the check, the other to the transition.

### Healthcare — patient enrollment

`enroll("Tomás Rivera", 1971-11-30, "national-id", doc_n07, clerk_c2)` → `party_qh9`. A failed check records and changes nothing: `verify(party_qh9, clerk_c2, "database-check", failed, ev_d21)` → `(ver_v91)` alone, party still unverified. The atom records that a check was attempted, by whom, how, and what it found; whether to retry, escalate or close is the composing system's.

### Sanctions match, suspension, and the evidence to come back

A screening pattern flags `party_pk3`. `suspend(party_pk3, compliance_c4, "sanctions-screen match pending review")` → `chg_s31`, standing suspended. A fresh document review runs during the investigation: `verify(party_pk3, analyst_a2, "manual-document-review", passed, ev_c44)` → `(ver_v96)` — recorded, and the party stays suspended, because evidence gathered during an investigation does not clear it. Then `reinstate(party_pk3, compliance_c4, "match resolved as false positive")` → `chg_s37`, standing verified. Had the reinstate been attempted before `ver_v96`, it would have answered no-passed-verification-since-suspend.

### Enrollment in error

`enroll(...)` → `party_zz1`, then immediately `close(party_zz1, officer_o7, "enrolled in error — duplicate of party_pk3")` → `chg_s44`. The record persists in closed with the stated reason. There is no way to retract the enrollment, and that absence is structural: an auditor reads the mistake and its correction rather than a gap.

### Regulated adversarial scenarios

- **Regulator audit.** *Show me every party you treat as verified, and the evidence.* Filter to `state = verified`; each record answers with its full verification event list and state change log, and Invariant 4.1 is what makes a passed check after the most recent suspend present on every one of them — structurally, rather than by policy.
- **Investigation of a reinstatement.** *Who restored this party, on what basis?* The state change log carries the reinstatement's actor, instant and reason; the verification event list carries the check that made it admissible. The two are separate records because they answer separate questions — what evidence arrived, and who decided it was enough.
- **Breach investigation.** *Which parties were enrolled in this window?* The enrollment instant range filter answers it, and Ordering 5 says what that answer is worth: instants are advisory, so a reconstruction that must be defensible uses insertion order and the composing trusted timestamping pattern for wall-time bounds.

---

## Source

- **FATF Recommendations 10–12 (customer due diligence, record-keeping and politically exposed persons)** — identify the customer and verify identity using reliable independent sources; identify beneficial owners; conduct ongoing due diligence. The [Enroll] → [Verify] lifecycle is the structural form; the beneficial-ownership graph is a composing pattern's (Non-goal 11) and the monitoring schedule is too (Non-goal 8).
- **BSA/AML — 31 CFR Part 1020 (FinCEN — the Financial Crimes Enforcement Network — Customer Identification Program)** — minimum identity attributes, verification by documentary or non-documentary method, and five-year retention past the relationship's end. The enrollment fields are the attributes; [Verification Method] records which kind was used; retention is the work of a pattern that bounds it (Non-goal 13).
- **FinCEN Beneficial Ownership Rule — 31 CFR section 1010.230** — each beneficial owner is a party record in their own right; the ownership relationship is not.
- **EU (European Union) 5th Anti-Money Laundering Directive (AMLD5)** — enhanced due diligence and beneficial-ownership registries, aligned with FATF.
- **GDPR Article 4(1)** — the enrollment fields are personal data, and this atom holds some rather than opaque references alone.
- **GDPR Articles 5–6** — lawful basis for processing, typically Article 6(1)(c) or 6(1)(b); processing *beyond* the regulatory obligation is a pattern that records consent's.
- **GDPR Article 17 (right to erasure)** — in direct tension with the retention obligations above. This atom does not resolve it: no pattern scrubs an enrollment field (Non-goal 3, Non-goal 12, Composition note 8), an erasure lands in the records the document reference and the evidence reference name, and the party record leaves whole through the purge of a pattern that bounds retention, once its retention allows (Execution Contract Database 4).
- **HIPAA 45 CFR section 164.514** — paragraph (h) requires a covered entity to verify the identity and authority of a person requesting protected health information before disclosing it, and a patient whose identity a recorded check established is a party here; paragraphs (a) and (b), the de-identification standards, are not this atom's, which holds identifying fields and de-identifies none.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture, and the discipline of composing the verification workflow, deduplication, risk scoring and ownership structure as separate concepts.
- **Grace Commons regulated-atom conventions** — the adversarial scenarios and the acceptance section, from `pressure-testing.md`.

---

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the party records, with their committed versions (Execution Contract Generation acceptance 1).

#### Conformance checks

```
Check 1.1: An auditor MUST find no party whose state DOES NOT EQUAL unverified AND DOES NOT EQUAL verified AND DOES NOT EQUAL suspended AND DOES NOT EQUAL closed (Invariant 2.1, State 1).
Check 1.2: An auditor MUST find no party leaving closed across two committed versions of the party (Invariant 3.1; Execution Contract Generation acceptance 1).
Check 2.1: An auditor MUST find a fresh verification on EVERY party whose state EQUALS verified (Invariant 4.1).
Check 3.1: An auditor MUST find verification id, verifying actor reference, verification method, verification result, evidence reference and verification instant on EVERY verification event (State 4).
Check 3.2: An auditor MUST find EVERY verification event unchanged across EVERY committed version of the party carrying the verification event (Invariant 5.1; Execution Contract Generation acceptance 1).
Check 3.3: An auditor MUST find no fall in a party's verification event list length across two committed versions of the party (Invariant 6.3; Execution Contract Generation acceptance 1).
Check 3.4: An auditor MUST find no verification event whose verification result DOES NOT EQUAL passed AND DOES NOT EQUAL failed (Operation 21).
Check 3.5: An auditor MUST find EVERY verification event in the same place in the party's verification event list across EVERY committed version of the party carrying the verification event (Invariant 6.2; Execution Contract Generation acceptance 1).
Check 4.2: An auditor MUST find the state change id, the prior state, the new state, an acting reference and an instant on EVERY state change event (State 5).
Check 4.3: An auditor MUST find a reason on EVERY state change event a reasoned action appended (State 7).
Check 4.4: An auditor MUST find no fall in a party's state change log length across two committed versions of the party (Invariant 8.2; Execution Contract Generation acceptance 1).
Check 4.5: An auditor MUST find no reason on a state change event an admitted verify appended (Operation 36).
Check 4.6: An auditor MUST find no state change event recording a transition outside the permitted transitions (Operation 14, Operation 15, Operation 16, Operation 25, Operation 26, Operation 30, Operation 31, Operation 32).
Check 5.1: An auditor MUST replay a party's state change log in insertion order from unverified to the party's state (Invariant 8.1, Ordering 3, Operation 7).
Check 5.2: An auditor MUST reconstruct EVERY party's enrollment, verification history and state history from one read (State 1, State 2, State 3).
Check 6.4: An auditor MUST find EVERY enrollment field unchanged across EVERY committed version of the party carrying the enrollment field (Non-goal 3; Execution Contract Generation acceptance 1).
Check 7.1: An auditor MUST find no party id on two parties (Identity 7).
Check 7.2: An auditor MUST find no verification id on two verification events (Identity 8).
Check 7.3: An auditor MUST find no state change id on two state change events (Identity 9).
```

NOTE: Invariant 1.1 owes no check here: Execution Contract Database 6 binds the atom's own actions, and a purge another specification declares, as a pattern that bounds retention does under Execution Contract Database 4, is answered by that specification's records (Capability requirement 10, Non-goal 13).

Term permitted transition: unverified-to-verified | verified-to-suspended | suspended-to-verified | unverified-to-closed | verified-to-closed | suspended-to-closed — every transition a state change event may record.

Term cited: party id, actor id, party events: Declarations.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: A deployment needing an identity check performed MUST read the composing verification workflow (Non-goal 5).
External check 2: A deployment needing two parties resolved as one natural person MUST read the composing identity resolution (Identity 16, Non-goal 1).
External check 4: A deployment needing an acting reference bound to an actor MUST read the composing pattern's attestation (Identity 15, Non-goal 15, Composition note 4, Composition note 5).
External check 5: A deployment needing a recorded instant anchored to wall time MUST read the composing trusted timestamping pattern (Ordering 5, Ordering 6).
External check 6: A deployment needing a document reference resolved MUST read the composing pattern's document records (Identity 13).
External check 7: A deployment needing a party's record retention bounded MUST read the composing pattern that bounds retention (Non-goal 13).
External check 8: A deployment needing an answer observed MUST read the app's journal (Non-goal 19).
External check 11: A deployment needing an evidence reference resolved MUST read the composing pattern's document records (Identity 14).
```

---

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the deployment; the database; the database instance; the seam; the transition; a composing pattern; a caller; an auditor; a regulator; an investigator; a party; a verification event; a state change event; an action; a party action; a transitioning action; a reasoned action; an admitted enroll; an admitted verify; an admitted suspend; an admitted reinstate; an admitted close; an admitted read; a writing action; a refused action; a required string input; an assigned id; an opaque reference; a string input; a filter; a filter axis; a filter value; a query; a party's verification event list length; a party's state change log length.

Term records: party — one external party, carrying party id, name, date of birth, document type, document reference, enrollment instant, enrolling actor reference, a state, a state change log and a verification event list. verification event — one identity check, carrying verification id, verifying actor reference, verification method, verification result, evidence reference and verification instant. state change event — one transition, carrying state change id, the prior state, the new state, an acting reference, an instant and, where the writer carries one, a reason.

Term record verbs: identify, assign, generate, change, share, carry, stand, read, answer, record, append, remove, leave, admit, offer, hold, refuse, write, find, resolve, name, compare, normalize, confirm, match, route, register, create, pass, attest, cover, call, fall, precede, follow, sample, consume, supply, declare, compose, bind, decide, define, bound, reach, accept, trim, case-fold, compute, reproduce, reconstruct, replay, verify, detect, guarantee, take, derive, expose, store, own, enumerate, distinguish, select, order, deduplicate, scrub, parse, gate, count, schedule, propagate, terminate, link, suspend, reinstate, close, enroll, ignore, partition, retry, exceed, perform, score, model.

Term value sets: state = unverified | verified | suspended | closed. verification result = passed | failed. enrollment field = name | date of birth | document type | document reference | enrollment instant | enrolling actor reference. action rejection = invalid-request | storage-failure — the codes every writing action's refuses line carries. party-action rejection = not-known | already-closed — the codes every party action's refuses line carries.

Term bounds: length bound.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: party, verify answer, verification event, state change event, assigned id, enrollment field, acting reference, reference, database instance, seam, transition, now, date form, date of birth start, party action, transitioning action, state, state check, required string input, fresh verification, insertion order, length bound, reasoned action, evidence reference, query axes, admitted enroll, admitted verify, admitted suspend, admitted reinstate, admitted close, admitted read, string input, blank, verification result, committed version.

Term cited: Execution Contract Database 1 through 7 — one transaction per action, guards read inside it, committed means kept, the database never edits, every committed version stays readable, an atom's no-removal rules bind its own actions, every call goes to one database instance. Execution Contract Error model 1 — a lost answer is none of the three. Execution Contract Generation acceptance 1 — a check comparing a record with an earlier state reads its committed versions. Execution Contract Input 2 — a bound is a default cap. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. Execution Contract Logic confinement 11 — now is the clock reading at the call. Execution Contract Order 1 — commits have one order. Execution Contract Query 1 through 4 — a filter carries one value of its axis or a range, a range holds both its ends, a record without the filtered value fails the filter, filters combine as all-of. Execution Contract Read 4 — a rule saying what an action does holds only for a call the action admits. Execution Contract Refusal 1 — the refusal listed first answers.

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

## Status

`done — 2026-11-26` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-26
formal: verified — party-identity.tla + 4 twins (2026-06-03); party-identity.als + 14 twins (the static data model, 2026-11-11: State 1, 4, 5 and 7, Operation 21 and 36, Invariant 2.1, 3.1, 4.1 and 8.1 and Identity 7, 8 and 9 checked (Identity 5 left the page to Execution Contract Logic confinement 3 at Final Critique 14; the model still checks that every assigned id a record carries is the id material the seam supplied) on every party record an admitted [Enroll], [Verify], [Suspend], [Reinstate] or [Close] leaves, with its verification event list and state change log, insertion order read as the calls' commit order and a recorded instant free of it; Invariant 3.1 and 8.1 read off one record's state change log, Invariant 2.1, 3.1 and 4.1 a cross-check with the TLA+ model, Identity 7 through 9 resting on the deployment's id material, never supplied to two calls (Execution Contract Logic confinement 16, Capability requirement 15); nothing testable in Alloy for Invariant 1.1, 5.1, 6.1 through 6.3 and 8.2, Identity 6 or Non-goal 3: each compares a record with a later version of it, which a single state cannot show, so they are the TLA+ model's); coverage 2026-11-10 (unit formal: more coverage for the yes votes): owes TLA+ checks of Invariant 1.1, 5.1, 6.2, 6.3 and 8.2 and Identity 6 (across steps); owed rows: Invariant 1.1; Invariant 5.1; Invariant 6.2; Invariant 6.3; Invariant 8.2; Identity 6, 2026-11-11
last gate: 2026-11-26 — Final Critique 15, a delta round, frozen at 0f3a7969 — foundational count 0 after the blind second triage, clean, one sample (Linus reported 2 foundational, both refuted on the page's text: Operation 25 stands the party in verified on a passed verify of an unverified party, which Operation 26 only bounds, and Operation 49 answers invalid-query for a filter value outside an axis's admitted values, a blank party id among them; the refining item refuted by Operation 3 and the rhetorical item refuted by Term query axes and the Query entry, which state that an over-bound party id is admitted and matches nothing; the blind second triage placed none; the checker said nothing); 2026-11-26 — Final Critique 14, a delta round, frozen at 7058080c — foundational count 1, not clean, no sample (Linus reported 1 foundational, Check 1.1 and Check 3.4 selecting rather than demanding, cured; 12 refining and 3 rhetorical placed: 6 refining cured, 4 refuted on the page's text or the corpus's rules, 2 filed to Scott; the checker's one hit and one rhetorical cured); 2026-11-22 — Final Critique 13, a delta round, frozen at 5aa9eb62 — foundational count 0, clean, one sample (Linus reported 2 foundational, both refuted on the page's text: Term invalid request and Operation 12 order not-known ahead of invalid-request for an over-bound party id, and Term query axes states the page's own answer for a filter value, which Query 5 keeps; the blind second triage placed none foundational); 2026-11-05 — Final Critique 12, a delta round, frozen at 29399d0 — foundational count 0, clean, no sample; 2026-11-04 — Final Critique 11 — foundational count 1, not clean, no sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./party-identity.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/party-identity.md`.

</details>

NOTE: End of Party Identity.
