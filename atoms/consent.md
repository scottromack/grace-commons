---
title: Consent
parent: Atomic Concepts
has_toc: true
toc: true
---

# Consent

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Consent records a person's agreement to have their personal data used for one named purpose — "marketing emails," "behavioural analytics." Each record captures when the agreement was given, who collected it, and what it covers, and it captures how the agreement ends: the person withdraws it, or it runs out because a time limit was set at grant.

Every record is in one of three states — [Granted], [Revoked], [Expired]. The two ending states are permanent. Consent that has ended is not revived; the person gives fresh agreement instead, and that is a new record. Records are kept unchanged forever, and a withdrawal is logged as its own dated, attributed event rather than by editing the grant — so the proof that earlier use was permitted is never lost. Withdrawing ends future use; it does not rewrite the past.

The load-bearing operation is a check: before doing anything that depends on consent, a system asks whether valid consent exists for this person and this purpose. The check can ask about a past date, for an audit, or a future one, to see whether consent recorded today still covers a campaign going out next month; a withdrawal recorded before then changes the answer. Expiry is not an action anybody takes — it is a condition the check derives.

This is the mechanism behind privacy-law consent management, patient authorizations, and cookie opt-ins.

---

## Intent

WHY:
Every system that processes personal data must answer one question before it acts: does it have the data subject's agreement to do what it is about to do? Under GDPR (EU General Data Protection Regulation), CCPA/CPRA (California Consumer Privacy Act / Privacy Rights Act) and HIPAA (US Health Insurance Portability and Accountability Act), that agreement is a legal prerequisite for whole categories of processing, not a courtesy — and the record of it, its scope, its duration and its end is both an operational control and a legal artifact.

So the grant is scoped to one purpose per record. A system needing consent for three purposes holds three records, because a blanket authorization answers none of the questions a regulator asks. The grant ends in exactly two ways — the subject revokes, or a time bound elapses — and either way the ending state is permanent. A subject who revokes and later re-consents creates a new record; the prior one stays as evidence of the prior agreement and its termination. That is not a limitation, it is the evidentiary structure the regimes require.

The atom is structurally distinct from [Permissions](./permissions.md) in a way that matters. Permissions governs what an internal actor may do inside the system — authorization pointing inward. Consent governs what the system may do to a data subject's data — authorization pointing outward, held by the subject rather than the operator. They are composing peers, not alternatives: a deployment may need a subject's consent for `marketing:email` *and* an actor's permission to fire the campaign.

Revocation is a first-class action rather than a state flag, with its own timestamp, its own attribution and its own stated reason — GDPR Article 7(3) requires withdrawal to be as easy as granting, and [Revoke] is that requirement's specification. Expiry is the opposite: not an action but a condition. No actor triggers it and nothing polls for it; [Check] derives it from the record against the instant asked about.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a consent record by the consent id.
Identity 2: The host MUST allocate a consent id at the seam.
Identity 3: The transition MUST NOT allocate a consent id.
Identity 4: The atom MUST NOT reuse a consent id.
Identity 5: The atom MUST NOT change a consent id.
Identity 6: The atom MUST NOT identify a consent record by the subject reference and the purpose.
Identity 7: EVERY consent id MUST stand non-blank.
Deleted: Identity 8. Execution Contract Logic confinement 10 owns it.
Identity 9: The atom MUST NOT interpret a subject reference.
Identity 10: The atom MUST NOT interpret a purpose.
Identity 11: The atom MUST NOT confirm that a subject reference names a known data subject.
```

Term consent id: the opaque value naming one consent record — a [Consent Id]; host-allocated at the seam, never reused.

Term subject reference: the opaque reference naming the data subject whose agreement the record holds — a [Subject Reference].

Term purpose: the opaque value naming the processing purpose the agreement covers — a [Purpose]; caller-declared vocabulary, matched exactly.

Term granting actor: the opaque reference naming the actor that recorded the subject's affirmative signal — a [Granting Actor].

### State

```
State 2: A consent record's state MUST rest on grant instant, revocation instant and expiry instant against the evaluation instant.
State 3: EVERY consent record MUST carry consent id, subject reference, purpose, granting actor, grant instant and state.
State 4: A consent record MUST carry an expiry instant the [Grant] call supplied.
State 5: A consent record MUST carry metadata the [Grant] call supplied.
State 6: A consent record MUST NOT carry an expiry instant the [Grant] call omitted.
State 7: A revoked consent record MUST carry revoking actor, revocation reason and revocation instant.
State 8: A granted consent record MUST NOT carry revocation instant.
State 9: An expired consent record MUST NOT carry revocation instant.
State 10: A revoked consent record MUST carry EVERY grant field.
State 11: The atom MUST NOT offer a transition out of revoked.
State 12: The atom MUST NOT offer a transition out of expired.
State 13: The atom MUST NOT suppress a processing act.
State 14: The atom MUST NOT hold a lawful basis outside consent.
State 15: The atom MUST NOT hold a purpose taxonomy.
Deleted: State 1. Invariant 2.1 owns it.
```

Term state: granted | revoked | expired — in effect, withdrawn, or run out; a [State], derived per Expiry 1 through 4 against the evaluation instant.

Term grant field: consent id | subject reference | purpose | granting actor | grant instant | expiry instant | metadata — what [Grant] writes and Invariant 1.1 freezes.

#### Expiry

```
Expiry 1: IF a consent record is withdrawn THEN the consent record MUST stand in revoked.
Expiry 2: IF a consent record is elapsed AND the consent record is not withdrawn THEN the consent record MUST stand in expired.
Expiry 3: A consent record MUST stand in expired ONLY IF the consent record is not withdrawn.
Expiry 4: A consent record MUST stand in granted ONLY IF the consent record is not withdrawn AND the consent record is not elapsed.
Expiry 5: The atom MUST NOT offer an action that stands a consent record in expired.
Expiry 6: The atom MUST NOT poll for an elapsed consent record.
Expiry 7: The composing pattern MUST NOT poll for an elapsed consent record.
```

#### Stored state

```
Deleted: Stored state 1. Expiry 5 and Execution Contract Database 4 own it.
Deleted: Stored state 2. Operation 36 and Operation 49 own it.
Stored state 3: The implementation MUST NOT answer a granted result for an elapsed consent record.
Deleted: Stored state 4. Execution Contract Database 2 owns it.
```

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 5: The deployment MUST supply the consent records PER Execution Contract Database 1 through 4, Execution Contract Database 6, Execution Contract Database 7, Execution Contract Refusal 1 and Execution Contract Query 1 through 4.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
```

### Operations

```
grant(subject_ref, purpose, granted_by, optional expires_at, optional metadata)
  answers consent_id
  refuses invalid-request | storage-failure

revoke(consent_id, revoked_by, reason, optional revoked_at)
  answers revoked
  refuses invalid-request | not-known | already-revoked | already-expired | storage-failure

check(subject_ref, purpose, optional at_time)
  answers granted | revoked | expired | not-known

read(query)
  answers consent_records
  refuses invalid-query
```

```
Operation 1: [Grant] MUST record EXACTLY ONE consent record per successful call.
Operation 2: [Grant] MUST stand the consent record in granted.
Operation 3: [Grant] MUST answer the consent id.
Operation 4: IF subject reference EQUALS blank THEN [Grant] MUST answer invalid-request.
Operation 5: IF purpose EQUALS blank THEN [Grant] MUST answer invalid-request.
Operation 6: IF granting actor EQUALS blank THEN [Grant] MUST answer invalid-request.
Operation 7: [Grant] MAY record an expiry instant ONLY IF now PRECEDES expiry instant.
Operation 8: IF expiry instant PRECEDES now THEN [Grant] MUST answer invalid-request.
Operation 9: IF expiry instant EQUALS now THEN [Grant] MUST answer invalid-request.
Operation 10: [Grant] MUST stamp grant instant from the injected now.
Operation 11: [Grant] MUST record metadata the call supplied.
Operation 12: [Grant] MUST NOT interpret metadata.
Operation 13: IF the database refuses the write THEN [Grant] MUST answer storage-failure.
Deleted: Operation 14. Execution Contract Refusal 1 owns it.
Operation 15: IF consent id EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 16: IF the consent id names no consent record THEN [Revoke] MUST answer not-known.
Deleted: Operation 17. Execution Contract Refusal 1 owns it.
Operation 18: IF the consent record's state EQUALS revoked THEN [Revoke] MUST answer already-revoked.
Operation 19: IF the consent record's state EQUALS expired THEN [Revoke] MUST answer already-expired.
Operation 20: IF revocation instant DOES NOT EQUAL blank THEN [Revoke] MUST resolve revocation instant from the call.
Deleted: Operation 21. Execution Contract Logic confinement 12 owns it.
Operation 22: IF the consent record's state EQUALS granted AND revoking actor EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 23: IF the consent record's state EQUALS granted AND reason EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 24: IF the consent record's state EQUALS granted AND now PRECEDES the resolved revocation instant THEN [Revoke] MUST answer invalid-request.
Operation 25: IF the consent record's state EQUALS granted AND the resolved revocation instant PRECEDES grant instant THEN [Revoke] MUST answer invalid-request.
Operation 26: [Revoke] MUST stand the consent record in revoked.
Operation 27: [Revoke] MUST record revoking actor on the consent record.
Operation 28: [Revoke] MUST record the reason as the revocation reason.
Operation 29: [Revoke] MUST record the resolved revocation instant on the consent record.
Operation 30: [Revoke] MUST answer revoked.
Operation 31: IF the database refuses the write THEN [Revoke] MUST answer storage-failure.
Operation 32: IF the database refuses the [Revoke] write THEN the consent record MUST stand in granted.
Deleted: Operation 33. Execution Contract Database 3 owns it.
Operation 34: [Check] MUST answer EXACTLY ONE OF granted, revoked, expired, not-known.
Operation 35: [Check] MUST NOT refuse a call.
Operation 36: [Check] MUST NOT write.
Operation 37: IF at time DOES NOT EQUAL blank THEN [Check] MUST resolve at time from the call.
Deleted: Operation 38. Execution Contract Logic confinement 12 owns it.
Operation 39: [Check] MUST accept EVERY at time.
Operation 40: IF no candidate record EXISTS THEN [Check] MUST answer not-known.
Operation 41: IF the candidate record is withdrawn THEN [Check] MUST answer revoked.
Operation 42: IF the candidate record is elapsed AND the candidate record is not withdrawn THEN [Check] MUST answer expired.
Operation 43: [Check] MUST answer expired ONLY IF the candidate record is not withdrawn.
Operation 44: [Check] MUST answer granted ONLY IF a candidate record EXISTS AND the candidate record is not withdrawn AND the candidate record is not elapsed.
Operation 45: [Check] MUST evaluate the candidate record alone.
Operation 46: IF at time DOES NOT EQUAL blank THEN [Check] MUST NOT evaluate a consent record against now.
Operation 47: [Read] MUST answer EVERY consent record the query matches.
Operation 48: [Read] MUST order the answer by grant instant ascending.
Operation 49: [Read] MUST NOT write.
Operation 50: [Read] MUST order two consent records sharing a grant instant by consent id ascending (Execution Contract Logic confinement 10).
Operation 51: [Read] MUST answer an empty sequence for a well-formed query no consent record matches.
Operation 52: [Read] MUST accept EVERY combination of the supported filter axes.
Deleted: Operation 53. Execution Contract Query 4 and Operation 47 own it.
Operation 54: [Read] MUST NOT answer two consent records for a query carrying a consent id filter.
Operation 55: IF the query carries a filter key outside the supported filter axes THEN [Read] MUST answer invalid-query.
Operation 56: [Read] MUST NOT ignore a filter key outside the supported filter axes.
Operation 57: IF a reference filter's value EQUALS blank THEN [Read] MUST answer invalid-query.
Operation 58: IF a state filter's value IS NOT IN state THEN [Read] MUST answer invalid-query.
Operation 59: IF a time range's end PRECEDES the time range's start THEN [Read] MUST answer invalid-query.
Operation 60: [Read] MUST exclude a consent record carrying no value for a time range's field.
Deleted: Operation 61. Capability requirement 1 owns it.
Deleted: Operation 62. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 63. Execution Contract Logic confinement 3 owns it.
Operation 64: [Read] MUST evaluate a state filter against the consent record's state.
Operation 65: IF the query is malformed THEN [Read] MUST answer invalid-query.
```

NOTE: watch the state a refusal leaves (Operation 32).

Term now: the deployment's clock reading at the call — a [Now], as Execution Contract Logic confinement 11 declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term at time: the instant a [Check] evaluates against — an [At Time]; a caller-supplied query input, as Execution Contract Logic confinement 12 resolves it.

Term expiry instant: the optional instant a consent record's agreement runs out — an [Expiry Instant]; set at [Grant], never stamped later.

Term metadata: the optional opaque payload the atom stores unchanged — a [Metadata]; consent-form version, signal type, jurisdiction.

Term revoking actor: the opaque reference naming the actor that recorded the withdrawal — a [Revoking Actor].

Term revocation reason: the stated ground for the withdrawal — a [Revocation Reason], carried from the call's [Reason].

Term reason: the [Revoke] input the record keeps as revocation reason — a [Reason].

Term revocation instant: the instant the withdrawal takes effect — a [Revocation Instant]; caller-supplied, as Execution Contract Logic confinement 12 resolves it.

Term grant instant: the instant the consent record was created — a [Grant Instant]; always stamped from now.

Term evaluation instant: the instant a consent record's state is read against — the resolved at time in [Check], now everywhere else.

Term withdrawn: the consent record carries a revocation instant no later than the evaluation instant.

Term elapsed: the consent record carries an expiry instant no later than the evaluation instant.

Term candidate record: among the consent records carrying the call's subject reference and purpose, the one whose grant instant is the latest that the resolved at time does not precede; a tie on grant instant resolves to the greatest consent id (Execution Contract Logic confinement 10).

Term later write: a consent record written with a grant instant or a revocation instant later than the resolved at time.

Term query: the filter set [Read] accepts — a [Query]; any combination of the supported filter axes.

Term supported filter axes: consent id | subject reference | purpose | granting actor | state | a time range on grant instant | a time range on revocation instant | a time range on expiry instant.

Term reference filter: a consent id, subject reference, purpose or granting actor filter on a query.

Term state filter: a query's filter on state, one of the supported filter axes.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Grant] | three references present, no expiry instant, database accepts | the new consent id | one record lands in [Granted] (Operation 1, Operation 2) |
| [Grant] | as above with an expiry instant after [Now] | the new consent id | as above, with [Expiry Instant] recorded (Operation 7) |
| [Grant] | a blank reference, or an expiry instant at or before [Now] | [Invalid Request] | none (Operation 4 through 6, Operation 8, Operation 9) |
| [Revoke] | id names a record in [Granted], attribution present, times ordered | revoked | [Granted] → [Revoked], three fields stamped (Operation 26 through 29) |
| [Revoke] | blank consent id | [Invalid Request] | none — answered ahead of not-known (Operation 15, Execution Contract Refusal 1) |
| [Revoke] | id names nothing | [Not Known] | none (Operation 16) |
| [Revoke] | id names a record in [Revoked] | [Already Revoked] | none (Operation 18) |
| [Revoke] | id names a record in [Expired] | [Already Expired] | none (Operation 19) |
| [Revoke] | record in [Granted], blank attribution or a time out of order | [Invalid Request] | none (Operation 22 through 25) |
| either write | database refuses | [Storage Failure] | none (Operation 13, Operation 31, Operation 32) |
| [Check] | the candidate record is withdrawn by [At Time] | revoked | none — the call reads (Operation 41, Operation 36) |
| [Check] | the candidate record is elapsed by [At Time], never withdrawn | expired | none (Operation 42, Operation 43) |
| [Check] | the candidate record is neither | granted | none (Operation 44) |
| [Check] | no record for the pair was granted by [At Time] | not-known | none (Operation 40) |
| [Read] | a well-formed query | the matching records, oldest first, each carrying its state at [Now] | none (Operation 47, Operation 48, Invariant 2.2) |
| [Read] | a well-formed query matching nothing | an empty sequence | none (Operation 51) |
| [Read] | a blank filter value, a bad state, an inverted range, a range missing an end, an unknown key | [Invalid Query] | none (Operation 55 through 59, Operation 65) |

### Invariants

- **Invariant 1 — Grant immutability.**
  ```
  Invariant 1.1: A recorded consent record's grant fields MUST NOT change.
  Invariant 1.2: A grant field the [Grant] call omitted MUST NOT appear later.
  ```
- **Invariant 2 — Membership exclusivity.**
  ```
  Invariant 2.1: EVERY consent record MUST stand in EXACTLY ONE OF granted, revoked, expired at the evaluation instant.
  Invariant 2.2: [Read] MUST carry the consent record's state on EVERY answered consent record.
  ```
- **Invariant 3 — Terminal absorption.**
  ```
  Invariant 3.1: A revoked consent record MUST NOT leave revoked.
  Invariant 3.2: An expired consent record MUST NOT leave expired.
  Invariant 3.3: A composing pattern returning a data subject to agreement MUST call [Grant].
  ```
- **Invariant 4 — Revocation attribution is complete.**
  ```
  Invariant 4.1: EVERY revoked consent record's revoking actor MUST stand non-blank.
  Invariant 4.2: EVERY revoked consent record's revocation reason MUST stand non-blank.
  Invariant 4.3: EVERY revoked consent record MUST carry a revocation instant.
  ```
- **Invariant 5 — Temporal ordering on revocation.**
  ```
  Invariant 5.1: EVERY revoked consent record's revocation instant MUST NOT PRECEDE the consent record's grant instant.
  ```
- **Invariant 6 — Expiry coherence.**
  ```
  Deleted: Invariant 6.1. Operation 42 and Invariant 6.2 own it.
  Invariant 6.2: IF the candidate record is withdrawn AND the candidate record is elapsed THEN [Check] MUST answer revoked.
  Deleted: Invariant 6.3. Operation 36 and Operation 49 own it.
  ```
- **Invariant 7 — Grant attribution is complete.**
  ```
  Invariant 7.1: EVERY consent record's consent id, subject reference, purpose and granting actor MUST stand non-blank.
  Invariant 7.2: EVERY consent record MUST carry a grant instant.
  ```
- **Invariant 8 — Consent record durability.**
  ```
  Invariant 8.1: The atom MUST NOT remove a consent record from the database.
  Deleted: Invariant 8.2. Invariant 8.1 and Execution Contract Database 6 own it.
  Deleted: Invariant 8.3. Execution Contract Database 1 owns it.
  ```
- **Invariant 9 — Revocation non-retroactivity.**
  ```
  Invariant 9.1: [Revoke] MUST NOT change a grant field.
  Invariant 9.2: [Revoke] MUST NOT change the lawfulness of a processing act the consent record covered.
  ```
- **Invariant 10 — Point-in-time faithfulness.**
  ```
  Invariant 10.1: [Check] MUST answer from the candidate record alone.
  Invariant 10.2: A tie on grant instant MUST resolve to the greatest consent id (Execution Contract Logic confinement 10).
  Invariant 10.3: A later write MUST NOT change a [Check] answer for the at time.
  Deleted: Invariant 10.4. Invariant 10.1 and Invariant 10.3 own it.
  ```

### Database instance model

```
Deleted: Instance 1. Execution Contract Database 7 owns it.
Instance 2: Two consent records in one database instance MUST NOT share a consent id.
Instance 3: A database name MUST name one database instance.
Instance 4: The atom MUST NOT accept a database name as an input.
Instance 5: A consent record MUST NOT carry a database name.
```

Term consent record: one data subject's agreement to one named processing purpose — the record this atom holds.

Term database instance: one named database a call is routed to; consent id uniqueness ranges over one instance.

Term database name: the identifier naming one database instance — a [Database Name]; deployment routing, never an input and never a stored field.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the consent id here.

Term transition: the atom's evaluation of one call against the consent records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

---

## Examples

### Grant, check, revoke, re-consent

A user onboarding to a health app affirms `analytics:behavioral`. The app calls `grant(subject_ref: user-4491, purpose: analytics:behavioral, granted_by: onboarding_service, expires_at: 2027-05-13T00:00:00Z)` → `cns-0001`. [Grant Instant] is stamped from the seam-injected [Now], here `2025-05-13T09:00:00Z`; the expiry instant guard passes because the bound is later. The record enters [Granted].

Before emitting an analytics event the pipeline calls `check(subject_ref: user-4491, purpose: analytics:behavioral)` → granted, and processing proceeds.

The user withdraws through the app's privacy settings. The privacy service calls `revoke(cns-0001, revoked_by: privacy_service, reason: "User-initiated withdrawal via privacy settings")` → revoked. [Revocation Instant] is stamped from [Now], here `2026-05-13T14:30:00Z` — not later than [Now], not earlier than [Grant Instant]. The next gate check answers revoked and processing is suppressed.

Six months later the user re-enables analytics: `grant(...)` → `cns-0088`, a second record in [Granted]. `cns-0001` stays [Revoked] as evidence. [Check] now answers granted, because `cns-0088` is the candidate record. A later `read({subject_ref: user-4491})` returns both, with full attribution on each.

### Rejection paths

`revoke(cns-0001, revoked_by: privacy_service, reason: "retry")` after the first revoke → already-revoked; the guard reads the stored record and writes nothing (Operation 18).

`grant(subject_ref: user-8823, purpose: "  ", granted_by: consent_ui)` → invalid-request. A whitespace-only purpose is blank (Operation 5).

`grant(subject_ref: user-9001, purpose: marketing:sms, granted_by: consent_ui, expires_at: 2020-01-01T00:00:00Z)` → invalid-request. A consent expiring in the past is already expired at the moment of grant, which is not a consent (Operation 8).

### Check against an instant

A consent for `analytics:behavioral` bounded at `2026-05-01T00:00:00Z`, checked on `2026-05-13` → expired, derived from the record and never from a stored flag (Operation 42).

Before queuing a 30-day campaign: `check(subject_ref: user-4491, purpose: marketing:email, at_time: 2026-06-13T00:00:00Z)` → granted, the consent running to `2027-01-01`. The campaign is scheduled on that answer (Operation 39); a [Revoke] recorded before delivery still ends the consent, so the sending system checks again before it sends (Composition note 2).

### Regulated adversarial scenarios

- **Regulator audit — GDPR Article 7 validity challenge.** A data protection authority investigates whether a controller held valid consent for `analytics:behavioral` processing on a given date. The controller runs `read({subject_ref: user-4491, purpose: analytics:behavioral})` and three things are provable to the authority: whether a [Granted] record was in effect on the date, from [Grant Instant] against [Revocation Instant] and [Expiry Instant]; whether the agreement was specific and informed, from [Granting Actor] naming the collection point, [Purpose] naming the scope, and [Metadata] carrying the form version; and whether the [Granted] record is immutable, from Invariants 1.1 and 7.1.
- **Disputed revocation — the data subject claims non-compliance.** A complaint says marketing continued after withdrawal. `read({subject_ref: user-4491, purpose: marketing:email})` shows `cns-0001` granted `2025-03-01` and revoked `2026-01-15` by `privacy_portal`, with the stated ground. The atom's records fix exactly when the withdrawal was recorded and by which system; whether the sending system called [Check] first is the composing layer's conformance question, not this atom's (State 13, Composition note 2).
- **Cross-purpose audit — HIPAA Authorization review.** An HHS (US Department of Health and Human Services — the federal agency that enforces HIPAA) inquiry asks whether patient `patient-7712` authorized disclosure of PHI (Protected Health Information — individually identifiable health data covered by HIPAA) under `hipaa:research:partner-univ-cardiology`. `read(...)` returns a [Granted] record with `granted_at: 2025-09-01`, `expires_at: 2026-09-01`, `granted_by: clinical_consent_kiosk`. The disclosure occurred `2026-01-10`, and `check(..., at_time: 2026-01-10T00:00:00Z)` → granted settles it provably.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the consent records' stored fields and the atom's query surface.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY issued consent id in the database through [Read] (Invariant 8.1).
Check 2.1: An auditor MUST find EVERY consent record's consent id, subject reference, purpose and granting actor non-blank (Invariant 7.1).
Check 2.2: An auditor MUST find a grant instant on EVERY consent record (Invariant 7.2).
Check 3.1: An auditor MUST find EVERY revoked consent record's revoking actor and revocation reason non-blank (Invariant 4.1, Invariant 4.2).
Check 3.2: An auditor MUST find EVERY revoked consent record's grant instant no later than the revocation instant (Invariant 5.1).
Check 4.1: An auditor MUST find [Check] answering granted, then revoked once a [Revoke] lands, then granted once a fresh [Grant] lands (Invariant 3.1, Operation 44).
Check 5.1: An auditor MUST find [Check] answering granted for an at time the expiry instant exceeds, and expired for an at time no earlier than the expiry instant, on a consent record carrying no revocation instant (Operation 42, Operation 44).
Check 5.2: An auditor MUST read the stored state as a cache rather than as the answer (Invariant 2.2, Stored state 3).
Check 6.1: An auditor MUST find [Revoke] answering already-revoked against a revoked consent record (Invariant 3.1).
Check 6.2: An auditor MUST find [Revoke] answering already-expired against an expired consent record (Invariant 3.2).
Check 6.3: An auditor MUST find no consent record field changed by a refused [Revoke] (Operation 32).
Check 7.1: An auditor MUST find EVERY revoked and expired consent record still answering to [Read] (Invariant 8.1).
Deleted: Check 8.1. Check 8.2 through 8.4 own it.
Check 8.2: An auditor MUST find a [Check] carrying an at time answering alike across a later [Grant] for the pair, where the at time PRECEDES the later consent record's grant instant (Invariant 10.3).
Check 8.3: An auditor MUST find a [Check] carrying an at time answering alike across a later [Revoke] for the pair, where the at time PRECEDES the revocation instant (Invariant 10.3).
Check 8.4: An auditor MUST find [Check] answering from the latest consent record the at time DOES NOT PRECEDE (Invariant 10.1).
Check 8.5: An auditor MUST find [Check] answering from the greatest consent id of two consent records sharing a subject reference, a purpose and a grant instant (Invariant 10.2).
```

NOTE: EVERY check names the rule the check tests.

## Non-goals

```
Non-goal 1: The atom MUST NOT merge two [Grant] calls carrying one subject reference and one purpose.
Non-goal 2: A deployment needing at-most-once grant MUST compose Duplicate Prevention.
Non-goal 3: The atom MUST NOT hold at most one granted consent record per subject reference and purpose.
Non-goal 4: A deployment needing one live agreement per pair MUST enforce the bound at the composing layer.
Non-goal 5: The atom MUST NOT define a valid purpose.
Non-goal 6: The atom MUST NOT expand a purpose hierarchy.
Non-goal 7: The atom MUST NOT interpret metadata.
Non-goal 8: A deployment needing required metadata content MUST NOT call [Grant] BEFORE enforcing the content.
Non-goal 9: The atom MUST NOT propagate a withdrawal downstream.
Non-goal 10: A deployment needing propagation MUST compose a consent-revocation-propagation pattern.
Non-goal 11: The atom MUST NOT hold a lawful basis the data subject did not give.
Non-goal 12: The atom MUST NOT gate an action on a caller's authority.
Non-goal 13: A deployment needing access control MUST compose Permissions.
Non-goal 14: The atom MUST NOT establish that a granting actor may agree for the data subject.
Non-goal 15: A deployment needing proxy consent MUST compose a guardian-relationship pattern.
Non-goal 16: The atom MUST NOT seal a consent record against modification.
Non-goal 17: A deployment needing court-admissible records MUST compose Tamper Evidence.
Non-goal 18: The atom MUST NOT bound how long a consent record is kept.
Non-goal 19: A deployment needing a retention bound MUST compose Retention Window.
Non-goal 20: The atom MUST NOT record who called an action.
Non-goal 21: A deployment needing attribution MUST compose Actor Identity.
Non-goal 22: The atom MUST NOT guarantee a consent id unique across database instances.
```

NOTE: the owners — [Duplicate Prevention](./duplicate-prevention.md) (Non-goal 1, Non-goal 2); the deployment (Non-goal 5, Non-goal 6, Non-goal 11); [Propagate Consent Revocation Downstream](../compositions/propagate-consent-revocation-downstream.md) (Non-goal 9, Non-goal 10); [Permissions](./permissions.md) (Non-goal 12, Non-goal 13); a guardian-relationship pattern *(forthcoming)* (Non-goal 14, Non-goal 15); [Tamper Evidence](./tamper-evidence.md) (Non-goal 16, Non-goal 17); [Retention Window](./retention-window.md) (Non-goal 18, Non-goal 19); [Legal Hold](./legal-hold.md) (Non-goal 18); [Audit Trail](../compositions/audit-trail.md) (Non-goal 20); [Actor Identity](./actor-identity.md) (Non-goal 20, Non-goal 21).

## Edge cases

### Clock dependence

```
Clock dependence 1: A guard MAY read now ONLY IF the call carries an instant.
```

### Clock semantics

```
Clock semantics 5: [Grant] MUST guard a supplied expiry instant against now.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 4. Clock dependence 1 owns it.
Deleted: Clock semantics 7. Operation 10 owns it: `now` is never supplied by the business caller, so a grant instant stamped from the injected now is never a caller-supplied instant.
Clock semantics 6: [Revoke] MUST guard a supplied revocation instant against now.
Clock semantics 8: [Revoke] MAY record a revocation instant earlier than now.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Concurrency 4: Two concurrent [Grant] calls carrying one subject reference and one purpose MUST record two consent records.
```

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST NOT run a processing act BEFORE calling [Check].
Composition note 3: A composing pattern MUST own the suppression of a processing act.
Composition note 4: A composing pattern MUST own the propagation of a withdrawal.
Composition note 5: A composing pattern MUST own the purpose taxonomy.
Composition note 6: A composing pattern MUST own the retention of the consent records.
Composition note 7: A composing pattern MUST own the authority to grant for a data subject.
Composition note 8: A composing pattern MUST NOT stand a consent record in any state.
```

NOTE: composing patterns — [Propagate Consent Revocation Downstream](../compositions/propagate-consent-revocation-downstream.md), [Resolve a Person's Data Rights](../compositions/resolve-a-persons-data-rights.md).

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a guard; a data subject; an auditor; a reader; the database; a consent record; a state; a database name; a query; a time range; a reference filter; a later write; the consent record count; the stored state.

Term records: consent record — one agreement to one purpose, carrying consent id, subject reference, purpose, granting actor, grant instant, state, the expiry instant and metadata supplied at grant, and, once withdrawn, revoking actor, revocation reason and revocation instant.

Term record verbs: route, share, name, accept, carry, identify, allocate, reuse, change, interpret, confirm, record, stand, answer, stamp, resolve, refuse, write, evaluate, order, exclude, ignore, leave, read, supply, rest, offer, remove, suppress, hold, poll, equal, appear, meet, fall, find, compose, define, expand, enforce, propagate, gate, establish, seal, bound, guarantee, own, guard, declare, call, run, merge, precede.

Term value sets: state = granted | revoked | expired. supported filter axes and grant field are declared above and cited here (Closed vocabulary 15).

Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: consent record, database instance, database name, seam, transition, consent id, subject reference, purpose, granting actor, blank, now, business caller, at time, expiry instant, metadata, revoking actor, revocation reason, reason, revocation instant, grant instant, evaluation instant, withdrawn, elapsed, candidate record, later write, query, supported filter axes, reference filter, state filter, state, grant field.

#### Grant

The behavior a consent collection surface invokes to record a data subject's affirmative agreement to a named [Purpose]. It assigns a fresh [Consent Id], stamps [Grant Instant] from the injected [Now], records [Subject Reference], [Purpose], [Granting Actor], and [Expiry Instant] / [Metadata] if supplied, and returns the [Consent Id] (or a rejection). The consent enters [Granted].

Kind: Operation

#### Revoke

The behavior that documents a data subject's withdrawal of consent, transitioning a [Granted] record to [Revoked]. It records [Revoking Actor], [Revocation Reason], and [Revocation Instant], all immutable thereafter. A [Revoked] or [Expired] record cannot be revoked ([Already Revoked] / [Already Expired]) — terminal absorption (Invariant 3).

Kind: Operation

#### Check

The pure point-in-time query that evaluates the consent state for a (subject, [Purpose]) as of [At Time], returning one of `granted | revoked | expired | not-known`. It selects the record with the greatest [Grant Instant] ≤ [At Time], evaluates that record's [Revocation Instant] / [Expiry Instant] against [At Time], and never writes and never rejects (Invariant 10).

Kind: Operation

#### Read

The read-only behavior that returns the consent records matching a [Query], ordered by [Grant Instant] ascending then [Consent Id] ascending. It changes nothing. Each record it returns carries its [State] derived at [Now], and a [State] filter is evaluated against that derived state (Invariant 2.2, Operation 64). Filters by [Consent Id], [Subject Reference], [Purpose], [Granting Actor], [State], or time range are combinable; a malformed one is rejected [Invalid Query].

Kind: Operation

#### Consent Id

The opaque, immutable, system-generated identity of a consent record, assigned on [Grant], never reused or reassigned within the database instance. A non-empty string. The subject, purpose, actor, and timestamps are properties of the record, not its identity.

Kind:       Field
Field of:   the consent record
Projection: consent_id

#### Subject Reference

The opaque reference to the data subject whose consent is recorded. Set on [Grant], immutable. The atom does not validate that the subject exists elsewhere; it is the caller's responsibility.

Kind:       Field
Field of:   the consent record
Projection: subject_ref

#### Purpose

The opaque string naming the processing-purpose scope the consent covers (e.g., `marketing:email`). Set on [Grant], immutable, caller-declared vocabulary the atom does not interpret. Two records with the same [Subject Reference] and [Purpose] are distinct records.

Kind:       Field
Field of:   the consent record
Projection: purpose

#### Granting Actor

The opaque reference to the actor who recorded the data subject's affirmative agreement — the attribution anchor for the consent event. Set on [Grant], immutable; empty or whitespace-only is rejected.

Kind:       Field
Field of:   the consent record
Projection: granted_by

#### Grant Instant

The timestamp the consent was granted, stamped from the injected [Now] at [Grant]. Set once, immutable (Invariant 1). The lower temporal bound for [Revocation Instant] (Invariant 5) and the selection key for [Check] / ordering key for [Read].

Kind:       Field
Field of:   the consent record
Projection: granted_at

#### Expiry Instant

The optional timestamp at which the consent expires. Set on [Grant] (must be strictly in the future relative to the injected [Now]); immutable. When [Expiry Instant] ≤ the evaluating clock and no revocation precedes it, the semantic state is [Expired]. Absent ⇒ the consent never expires by time.

Kind:       Field
Field of:   the consent record
Projection: expires_at

#### Metadata

The optional opaque payload supplied at [Grant] — consent form version, signal type, jurisdiction. Stored as-is, never parsed or validated; immutable after grant (Invariant 1). Deployment-specific content rules belong to the composing layer.

Kind:       Field
Field of:   the consent record
Projection: metadata

#### Revoking Actor

The opaque reference to the actor who recorded the withdrawal. Set at [Revoke], immutable thereafter; present on [Revoked] records only. Empty or whitespace-only is rejected [Invalid Request].

Kind:       Field
Field of:   the consent record
Projection: revoked_by

#### Revocation Reason

The required, non-empty reason for the withdrawal — written from the [Reason] parameter. Set at [Revoke], immutable thereafter; present on [Revoked] records only. A blank reason defeats the audit trail and is rejected.

Kind:       Field
Field of:   the consent record
Projection: revocation_reason

#### Revocation Instant

The timestamp the consent was revoked — supplied or defaulted to the injected [Now]. Must not be future and must be ≥ [Grant Instant] (Invariant 5). Set at [Revoke], immutable; present on [Revoked] records only.

Kind:       Field
Field of:   the consent record
Projection: revoked_at

#### State

The consent record's lifecycle state — [Granted], [Revoked], or [Expired] — derived from the record's instants against the evaluation instant (Expiry 1 through 4). The stored [State] field holds what [Grant] or [Revoke] last wrote; no action writes [Expired] to it (Expiry 5), and no answer reads it: [Read] carries the derived state on every record it answers and evaluates a [State] filter against that state (Invariant 2.2, Operation 64).

Kind:       Field
Field of:   the consent record
Projection: state

#### Database Name

The identifier of the database instance a consent record belongs to. Multiple instances coexist; [Consent Id]s are unique within an instance. No action accepts it as a parameter — instance selection is handled at the deployment-routing layer.

Kind:       Field
Field of:   the database instance
Projection: store_name

#### Now

The current clock reading the pipeline consumes — the injected `clock_t`, supplied at the I/O seam, never read inside a transition and never a signature parameter. It stamps the immutable write timestamps ([Grant Instant], [Revocation Instant]) and drives the pure expiry guard / derivation (no write); [At Time] defaults to it when omitted.

Kind:         Parameter
Parameter of: Grant
Projection:   now

#### At Time

The point-in-time the caller is asking [Check] about — a caller-supplied query input, past, present, or future. Not the injected clock (it defaults to the seam-injected [Now] when omitted) and not stored. [Check] evaluates the selected record's fields against [At Time].

Kind:         Parameter
Parameter of: Check
Projection:   at_time

#### Reason

The required, non-empty reason string [Revoke] consumes — written into [Revocation Reason]. Not stored under this name; an empty or whitespace-only value is rejected [Invalid Request].

Kind:         Parameter
Parameter of: Revoke
Projection:   reason

#### Query

The selection [Read] consumes — a filter over [Consent Id], [Subject Reference], [Purpose], [Granting Actor], [State], and/or a time range. Supplied per call, not stored; a malformed one is rejected [Invalid Query].

Kind:         Parameter
Parameter of: Read
Projection:   query

#### Granted

The state of a consent in effect for its [Purpose]. A record enters [Granted] on [Grant]; it may be revoked or evaluated, and its semantic state becomes [Expired] passively when [Expiry Instant] elapses.

Kind:      Member
Member of: the consent state
Role:      Outcome

#### Revoked

The terminal state of a consent the data subject has withdrawn. Carries [Revoking Actor], [Revocation Reason], and [Revocation Instant]; retained as audit evidence, no further transition (Invariant 3).

Kind:      Member
Member of: the consent state
Role:      Outcome

#### Expired

The terminal state of a consent whose [Expiry Instant] has elapsed with no prior revocation. Derived from [Expiry Instant] vs the evaluating clock and never written: no action writes [Expired] to the stored [State] field (Expiry 5). Retained, no further transition (Invariant 3).

Kind:      Member
Member of: the consent state
Role:      Outcome

#### Not Known

The outcome [Check] returns — and the refusal [Revoke] returns — when no record exists for the queried (subject, [Purpose]) pair, or when the named [Consent Id] references no record in this database instance. A first-class [Check] result, never an error there.

Kind:       Member
Member of:  the action outcome
Role:       Outcome
Projection: not-known

#### Invalid Request

The refusal [Grant] or [Revoke] returns when request fields fail — an empty or whitespace-only [Subject Reference], [Purpose], [Granting Actor], [Revoking Actor], or [Reason]; an [Expiry Instant] not in the future at [Grant]; a malformed [Consent Id]; or a [Revocation Instant] that is future or before [Grant Instant].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Storage Failure

The refusal any writing action returns when a durable write fails after preconditions pass. For [Revoke], the consent record remains [Granted] (Operation 32).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

#### Already Revoked

The refusal [Revoke] returns when the target is already [Revoked] — terminal absorption (Invariant 3); a pure guard that writes nothing.

Kind:       Member
Member of:  the Revoke rejection
Role:       Outcome
Projection: already-revoked

#### Already Expired

The refusal [Revoke] returns when the target is already [Expired] — terminal absorption (Invariant 3); a pure guard, evaluated as the derived semantic state, that writes nothing.

Kind:       Member
Member of:  the Revoke rejection
Role:       Outcome
Projection: already-expired

#### Invalid Query

The refusal [Read] returns when query parameters are malformed — a null/empty/whitespace filter value, a [State] value outside {[Granted], [Revoked], [Expired]}, a time range missing its start or its end, a time range with end before start, or an unrecognized filter key.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Grant]: #grant
[Revoke]: #revoke
[Check]: #check
[Read]: #read
[Consent Id]: #consent-id
[Subject Reference]: #subject-reference
[Purpose]: #purpose
[Granting Actor]: #granting-actor
[Grant Instant]: #grant-instant
[Expiry Instant]: #expiry-instant
[Metadata]: #metadata
[Revoking Actor]: #revoking-actor
[Revocation Reason]: #revocation-reason
[Revocation Instant]: #revocation-instant
[State]: #state
[Database Name]: #database-name
[Now]: #now
[At Time]: #at-time
[Reason]: #reason
[Query]: #query
[Granted]: #granted
[Revoked]: #revoked
[Expired]: #expired
[Not Known]: #not-known
[Invalid Request]: #invalid-request
[Storage Failure]: #storage-failure
[Already Revoked]: #already-revoked
[Already Expired]: #already-expired
[Invalid Query]: #invalid-query

---

## Standards references

- **GDPR Article 6(1)(a)** — consent as a lawful basis for processing personal data. A [Granted] consent record in effect at processing time is the legal basis documentation.
- **GDPR Article 7** — conditions for consent: must be freely given, specific, informed, and unambiguous; burden of proof on the controller (Invariant 7, Generation acceptance check 2); withdrawal must be as easy as giving (the [Revoke] action, same surface as [Grant]); withdrawal does not affect lawfulness of prior processing (Invariant 9, revocation non-retroactivity).
- **GDPR Article 17(1)(b)** — right to erasure applies when the data subject withdraws consent and there is no other lawful basis for processing. The [Revoke] action is the trigger; whether erasure follows is a composing-layer decision.
- **GDPR Article 30** — record of processing activities must include the purpose of processing and the legal basis. Consent records with [Purpose] and [Grant Instant] supply the Article 30 documentation surface.
- **CCPA / CPRA** — right to opt-out of sale or sharing of personal information; right to opt-in for sensitive personal information. The [Grant] and [Revoke] actions are the opt-in and opt-out mechanisms. CPRA extends consent requirements to sensitive personal information categories.
- **HIPAA section 164.508 (Authorization)** — required elements for a valid authorization include: a description of the information to be used or disclosed ([Purpose]), the name of the person authorized to make the disclosure ([Granting Actor] + composing Actor Identity), an expiration date or event ([Expiry Instant]), and the right to revoke ([Revoke] action). The consent record's fields map directly to the required Authorization elements.
- **HIPAA section 164.522** — right of an individual to request restrictions on certain uses and disclosures of PHI. Consent records with granular [Purpose] scoping are the mechanism.
- **21 CFR (Code of Federal Regulations) Part 11** — electronic records and signatures in FDA-regulated (US Food and Drug Administration) contexts. Consent records for clinical trial participation are regulated records under Part 11; [Granting Actor] and [Revoking Actor] map to electronic signature requirements when composed with Actor Identity.
- **ICH E6 Good Clinical Practice section 4.8** — the International Council for Harmonisation's E6 guideline; informed consent requirements for clinical trial subjects, including documentation, right of withdrawal, and retention of consent records. The consent record lifecycle (grant, revoke, retain) is the Part 4.8 compliance mechanism.
- **Children's Online Privacy Protection Act (COPPA)** — verifiable parental consent required for data collection from children under 13. Proxy consent (guardian granting on behalf of minor subject) is handled at the composing layer; the atom records the grant faithfully.
- **ePrivacy Directive (Cookie Law)** — consent required for non-essential cookies and tracking. Web consent banners produce [Grant] calls; user withdrawal produces [Revoke] calls. The consent record is the ePrivacy audit artifact.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: not applicable — vote no 2026-06-03
last gate: 2026-10-21 — Final Critique 6, the council's first round on the page and the first on its Store-contract rewrite (5842367), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS MiniMax M3.1 Flash, Linus GLM-5.3 Flash), each handed only the round's reading set, three passes on one text (frozen at 3f053f9); the round rests on three counted passes — foundational count 6 after triage (10 reports: 8 standing, merged into 5; 1 sent down; 1 rejected; 1 refining report raised), all Kind A: the stored state was a cache no conforming build could write, so an answered record's state could not equal it and a state filter read two ways; a refused [Revoke] was obliged to leave a revoked or expired record in granted; a record withdrawn and elapsed at once was obliged to stand, and to answer, both revoked and expired; a repeated [Check] was said to answer alike across a [Revoke] whose instant the at time does not precede; Term later write counted the expiry instant, so the record a [Check] answers from was a later write that must not change its answer; and an omitted revocation instant or at time resolved from the call, blank, with now named only by an ONLY IF; 16 refining reports, 5 rhetorical reports; not clean; every foundational finding cured in place; 2026-06-23 — Final Critique 5, fresh reader — clean

open:
- 2026-10-21-a · refining · State 13; State 14; Expiry 7 · State 13 and State 14 say what the atom will not do, the Non-goals' kind, and Expiry 7 obliges a composing pattern from the Expiry family → move each to the section that holds its kind
- 2026-10-21-b · refining · Non-goal 20; Non-goal 21; Operation 27; State 7 · Non-goal 20 says the atom records no caller and Non-goal 21 sends attribution to Actor Identity, while [Grant] and [Revoke] record a granting and a revoking actor → say the recorded actors are caller-declared references, not the authenticated caller
- 2026-10-21-c · refining · Operation 7; State 4 · Operation 7 permits recording a supplied expiry instant that State 4 obliges → one form: the obligation alone
- 2026-10-21-e · refining · Summary; Examples; Regulated adversarial scenarios · the Summary's whether valid consent exists reads as any record of the pair, while [Check] answers the latest candidate record's state, so a revoked latest record answers revoked beside an older granted one (Concurrency 4); and cns-0001 is a behavioural analytics consent granted 2025-05-13 in the walkthrough and a marketing-email consent granted 2025-03-01 in the disputed-revocation scenario → say the check answers the latest agreement, and give each record one id across the page
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/consent.md`; the migrations that got it here are in [its history](./consent.hist.md).

- **2026-10-22 — A composed retention may dispose of what the atom never removes.** *Chose:* Invariant 8.2, the consent record count that never falls, written with no actor, deleted to Invariant 8.1 and Execution Contract Database 6, so the atom removes no consent record and a purge a composing Retention Window declares (Non-goal 19) is answered by that pattern's records, with Check 1.1 citing Invariant 8.1 alone and Database 6 cited on Capability requirement 5; open line 2026-10-06-a, which asked who guarantees persistence beside a composed retention bound, closed as dissolved by the maintainer's 2026-10-22 ruling: Database 6 says the atom's no-removal rule binds the atom's own actions; rules 170 to 169. *Over:* a count that never falls beside a non-goal sending the retention bound to a composing pattern, which read alone forbids that pattern's purge. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the composed erasure among them; the 06:36Z escalation named this rule among the composed erasure's uncured sites, and Message Preference's ninth Final Critique had made the same cure on its twin. What each action does and answers is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the page's order — [Revoke] answering invalid-request on a blank consent id ahead of not-known, then already-revoked or already-expired, with its attribution and instant faults held to a granted record; storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 5, Execution Contract Refusal 1); Operation 14 (a [Grant] storage-failure only once every grant guard passes) and Operation 17 (not-known only for a consent id that is not blank), which only stated the order, deleted to Refusal 1, and Term grant guard, which only Operation 14 read, deleted with it; rules 172 to 170. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-21 — The state is derived on every answer and never written; withdrawal outranks expiry everywhere; a refused write leaves a granted record granted; an omitted instant resolves from now; a later write is the write's own instants.** *Chose:* the stored state's cache writes deleted — Stored state 1 to Expiry 5 and Execution Contract Database 4, Stored state 2 and Invariant 6.3 to Operation 36 and Operation 49 — with [Read] carrying the consent record's state on every record it answers (Invariant 2.2) and evaluating a state filter against it (Operation 64, Term state filter), so the stored field holds what [Grant] or [Revoke] last wrote and no answer reads it; Expiry 2 and Operation 42 held to a record that is not withdrawn, Invariant 6.1 deleted to Operation 42 and Invariant 6.2, and Check 5.1 held to a record carrying no revocation instant; Operation 32 held to the refused [Revoke] write; Operation 20, 21, 37 and 38 in the corpus's default form, the call's instant where it supplies one and now where it supplies none; Invariant 10.4 deleted to Invariant 10.1 and 10.3, and Check 8.1 to Check 8.2 through 8.4, which now say which later writes they cross; Term later write without its expiry clause. *Over:* a residual cache the 2026-06-23 entry kept and no conforming build can write — [Check] and [Read] are the contract's query surface and never write, and the Database contract runs no expiry — so the page obliged a write it forbade and an equality nothing could keep; a record revoked before its expiry obliged to stand, and to answer, both revoked and expired; a refused [Revoke] obliged to leave a revoked record in granted; a blank instant resolved from the call; a repeated check said to answer alike across a [Revoke] whose instant the at time does not precede; and the record a check answers from counted as a later write whenever its expiry falls after the at time. *Because:* Final Critique 6 found each a divergence between conforming builds or two rules no build can both obey, and the corpus already held each cure: Invitation and Session derive expiry at read time and carry the derived status on every read, the method's entry of 2026-10-08 deletes a broken rule to the rules that already hold its states, and Final Critique 5's own text had scoped the refused write, put withdrawal ahead of expiry, defaulted both instants to now and named only strictly-later writes. What the atom records is unchanged, and each answer is the one the page's other rules already gave.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the consent store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the six rules that restated them tombstoned to their owner — Invariant 8.3, no partial consent record left by a storage-failure, to Store 1; Operation 33, a write the store refused leaving the store as the call found it, to Store 3; Stored state 4, a lazy stored-state write on one consent record serialized, Concurrency 1, a state transition on one consent id serialized, and Concurrency 2 and 3, two concurrent revokes on one consent id answering revoked once and the later one already-revoked, to Store 2; rules 182 to 177. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. A refused [Revoke] leaving the consent record in [Granted] stays the atom's own (Operation 32), as do two concurrent grants recording two consent records (Concurrency 4), the stored state as a cache of the derived state (Stored state 1 through 3, Invariant 2.2 and 6.3) and the atom's no-removal rules (Invariant 8.1 and 8.2). [Check]'s point-in-time answer reads the record's own grant, revocation and expiry instants, and [Read] orders by grant instant and consent id, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-06-23 — Expiry is derived at check, with the stored `Expired` cache marked as a residual; now is not a signature parameter.** *Chose:* check evaluates expiry against the injected clock (or a caller-supplied `at_time?`, a query parameter, not the clock); the stored-Expired transition an implementation may write is a cache and is marked so. *Over:* threading now into grant / revoke, or treating stored `Expired` as the truth. *Because:* the execution contract injects the clock at the seam, and a stored flag that lags the clock is a cache, not a fact.

NOTE: End of Consent.
