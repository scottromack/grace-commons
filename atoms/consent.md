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

The load-bearing operation is a check: before doing anything that depends on consent, a system asks whether valid consent exists for this person and this purpose. The check can ask about a past date, for an audit, or a future one, to confirm consent will still hold when a campaign goes out next month. Expiry is not an action anybody takes — it is a condition the check derives.

This is the mechanism behind privacy-law consent management, patient authorizations, and cookie opt-ins.

---

## Intent

WHY:
Every system that processes personal data must answer one question before it acts: does it have the data subject's agreement to do what it is about to do? Under GDPR (EU General Data Protection Regulation), CCPA/CPRA (California Consumer Privacy Act / Privacy Rights Act) and HIPAA (US Health Insurance Portability and Accountability Act), that agreement is a legal prerequisite for whole categories of processing, not a courtesy — and the record of it, its scope, its duration and its end is both an operational control and a legal artifact.

So the grant is scoped to one purpose per record. A system needing consent for three purposes holds three records, because a blanket authorization answers none of the questions a regulator asks. The grant ends in exactly two ways — the subject revokes, or a time bound elapses — and either way the ending state is permanent. A subject who revokes and later re-consents creates a new record; the prior one stays as evidence of the prior agreement and its termination. That is not a limitation, it is the evidentiary structure the regimes require.

The atom is structurally distinct from [Permissions](./permissions.md) in a way that matters. Permissions governs what an internal actor may do inside the system — authorization pointing inward. Consent governs what the system may do to a data subject's data — authorization pointing outward, held by the subject rather than the operator. They are composing peers, not alternatives: a deployment may need a subject's consent for `marketing:email` *and* an actor's permission to fire the campaign.

Revocation is a first-class action rather than a state flag, with its own timestamp, its own attribution and its own stated reason — GDPR Article 7(3) requires withdrawal to be as easy as granting, and [Revoke] is that requirement's specification. Expiry is the opposite: not an action but a condition. No actor triggers it and nothing polls for it; [Check] derives it from the record against the instant asked about.

## Structure

### Store instance model

```text
Instance 1: The deployment MUST route EVERY call to one store instance.
Instance 2: Two consent records in one store instance MUST NOT share a consent_id.
Instance 3: A store_name MUST name one store instance.
Instance 4: The atom MUST NOT accept a store_name as an argument.
Instance 5: A consent record MUST NOT carry a store_name.
```

Terms › `consent record`: one data subject's agreement to one named processing purpose — the record this atom holds.

Terms › `store instance`: one named consent store a call is routed to; `consent_id` uniqueness ranges over one instance.

Terms › `store_name`: the identifier naming one store instance — a [Store Name]; deployment routing, never an argument and never a stored field.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading and the consent_id here.

Terms › `transition`: the atom's evaluation of one call against the consent store, as `execution-contract.md` §Logic confinement declares it.

### Identity model

```text
Identity 1: The atom MUST identify a consent record by the consent_id.
Identity 2: The host MUST allocate a consent_id at the seam.
Identity 3: The transition MUST NOT allocate a consent_id.
Identity 4: The atom MUST NOT reuse a consent_id.
Identity 5: The atom MUST NOT change a consent_id.
Identity 6: The atom MUST NOT identify a consent record by the subject_ref and the purpose.
Identity 7: EVERY consent_id MUST carry a non-whitespace character.
Identity 8: The deployment MUST draw a consent_id that sorts in lexicographic byte-order.
Identity 9: The atom MUST NOT interpret a subject_ref.
Identity 10: The atom MUST NOT interpret a purpose.
Identity 11: The atom MUST NOT confirm that a subject_ref names a known data subject.
```

Terms › `consent_id`: the opaque value naming one consent record — a [Consent Id]; host-allocated at the seam, never reused.

Terms › `subject_ref`: the opaque reference naming the data subject whose agreement the record holds — a [Subject Ref].

Terms › `purpose`: the opaque value naming the processing purpose the agreement covers — a [Purpose]; caller-declared vocabulary, matched exactly.

Terms › `granted_by`: the opaque reference naming the actor that recorded the subject's affirmative signal — a [Granted By].

Terms › `blank`: a value that is absent, empty, or carries only whitespace — what every presence check in this atom refuses; a blank argument NOT EXISTS.

WHY:
Identity by subject and purpose would be the natural-looking choice and it is wrong here: the atom deliberately admits several records over one pair, because re-consent after expiry is a new agreement and not an edit of the old one, and a regulator asking *what did this person agree to, and when* needs both rows (Identity 6, Non-goal 12). The id is the only identity anchor.

The id carries a second job the other atoms' ids do not: it is the tiebreak key. Two records granted at the same instant are ordered by id, ascending in [Read] and descending in [Check], so the id must sort as bytes — a ULID (Universally Unique Lexicographically Sortable Identifier), a UUID v7 (version 7 of the Universally Unique Identifier, which is time-ordered), or a zero-padded integer string (Identity 8, Operation 50, Invariant 10.2).

### Operations

```
grant(subject_ref, purpose, granted_by, expires_at?, metadata?) → consent_id | rejected(invalid-request | storage-failure)
revoke(consent_id, revoked_by, reason, revoked_at?) → revoked | rejected(invalid-request | not-known | already-revoked | already-expired | storage-failure)
check(subject_ref, purpose, at_time?) → granted | revoked | expired | not-known
read(query) → consent_records | rejected(invalid-query)
```

```text
Operation 1: [Grant] MUST record EXACTLY ONE consent record per successful call.
Operation 2: [Grant] MUST stand the consent record in granted.
Operation 3: [Grant] MUST answer the consent_id.
Operation 4: IF subject_ref NOT EXISTS THEN [Grant] MUST answer invalid-request.
Operation 5: IF purpose NOT EXISTS THEN [Grant] MUST answer invalid-request.
Operation 6: IF granted_by NOT EXISTS THEN [Grant] MUST answer invalid-request.
Operation 7: [Grant] MAY record an expires_at ONLY IF expires_at EXCEEDS now.
Operation 8: IF now EXCEEDS expires_at THEN [Grant] MUST answer invalid-request.
Operation 9: IF expires_at = now THEN [Grant] MUST answer invalid-request.
Operation 10: [Grant] MUST stamp granted_at from the injected now.
Operation 11: [Grant] MUST record metadata the call supplied.
Operation 12: [Grant] MUST NOT interpret metadata.
Operation 13: IF the store refuses the write THEN [Grant] MUST answer storage-failure.
Operation 14: [Grant] MUST answer storage-failure ONLY IF EVERY grant guard passes.
Operation 15: IF consent_id NOT EXISTS THEN [Revoke] MUST answer invalid-request.
Operation 16: IF the consent_id names no consent record THEN [Revoke] MUST answer not-known.
Operation 17: [Revoke] MUST answer not-known ONLY IF consent_id EXISTS.
Operation 18: IF the consent record stands in revoked THEN [Revoke] MUST answer already-revoked.
Operation 19: IF the consent record stands in expired THEN [Revoke] MUST answer already-expired.
Operation 20: [Revoke] MUST resolve revoked_at from the call.
Operation 21: [Revoke] MUST resolve revoked_at from the injected now ONLY IF the call supplied a blank revoked_at.
Operation 22: IF the consent record stands in granted AND revoked_by NOT EXISTS THEN [Revoke] MUST answer invalid-request.
Operation 23: IF the consent record stands in granted AND reason NOT EXISTS THEN [Revoke] MUST answer invalid-request.
Operation 24: IF the consent record stands in granted AND the resolved revoked_at EXCEEDS now THEN [Revoke] MUST answer invalid-request.
Operation 25: IF the consent record stands in granted AND granted_at EXCEEDS the resolved revoked_at THEN [Revoke] MUST answer invalid-request.
Operation 26: [Revoke] MUST stand the consent record in revoked.
Operation 27: [Revoke] MUST record revoked_by on the consent record.
Operation 28: [Revoke] MUST record the reason as the revocation_reason.
Operation 29: [Revoke] MUST record the resolved revoked_at on the consent record.
Operation 30: [Revoke] MUST answer revoked.
Operation 31: IF the store refuses the write THEN [Revoke] MUST answer storage-failure.
Operation 32: A refused [Revoke] MUST leave the consent record in granted.
Operation 33: A refused write MUST leave the store as the call found the store.
Operation 34: [Check] MUST answer EXACTLY ONE OF granted, revoked, expired, not-known.
Operation 35: [Check] MUST NOT refuse a call.
Operation 36: [Check] MUST NOT write.
Operation 37: [Check] MUST resolve at_time from the call.
Operation 38: [Check] MUST resolve at_time from the injected now ONLY IF the call supplied a blank at_time.
Operation 39: [Check] MUST accept EVERY at_time.
Operation 40: IF no candidate record EXISTS THEN [Check] MUST answer not-known.
Operation 41: IF the candidate record is withdrawn THEN [Check] MUST answer revoked.
Operation 42: IF the candidate record is elapsed THEN [Check] MUST answer expired.
Operation 43: [Check] MUST answer expired ONLY IF the candidate record is not withdrawn.
Operation 44: [Check] MUST answer granted ONLY IF the candidate record EXISTS AND the candidate record is not withdrawn AND the candidate record is not elapsed.
Operation 45: [Check] MUST evaluate the candidate record alone.
Operation 46: IF at_time EXISTS THEN [Check] MUST NOT evaluate a consent record against now.
Operation 47: [Read] MUST answer EVERY consent record the query matches.
Operation 48: [Read] MUST order the answer by granted_at ascending.
Operation 49: [Read] MUST NOT write.
Operation 50: [Read] MUST order two consent records sharing a granted_at by consent_id ascending.
Operation 51: [Read] MUST answer an empty sequence for a well-formed query no consent record matches.
Operation 52: [Read] MUST accept EVERY combination of the supported filter axes.
Operation 53: [Read] MUST answer EVERY consent record for a query carrying no filter.
Operation 54: [Read] MUST NOT answer two consent records for a query carrying a consent_id filter.
Operation 55: IF the query carries a filter key outside the supported filter axes THEN [Read] MUST answer invalid-query.
Operation 56: [Read] MUST NOT ignore a filter key outside the supported filter axes.
Operation 57: IF a reference filter's value NOT EXISTS THEN [Read] MUST answer invalid-query.
Operation 58: IF a state filter's value NOT EXISTS in state THEN [Read] MUST answer invalid-query.
Operation 59: IF a time range's end precedes the time range's start THEN [Read] MUST answer invalid-query.
Operation 60: [Read] MUST exclude a consent record carrying no value for a time range's field.
Operation 61: The host MUST read the clock at the seam.
Operation 62: The transition MUST NOT read a clock.
Operation 63: The business caller MUST NOT supply now.
```

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition — a [Now], as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `at_time`: the instant a [Check] evaluates against — an [At Time]; a caller-supplied query input, resolving to `now` where the call supplies none.

Terms › `grant guard`: [Grant]'s preconditions — `subject_ref`, `purpose` and `granted_by` each present, and `expires_at`, where supplied, exceeding `now`.

Terms › `expires_at`: the optional instant a consent record's agreement runs out — an [Expires At]; set at [Grant], never stamped later.

Terms › `metadata`: the optional opaque payload the atom stores unchanged — a [Metadata]; consent-form version, signal type, jurisdiction.

Terms › `revoked_by`: the opaque reference naming the actor that recorded the withdrawal — a [Revoked By].

Terms › `revocation_reason`: the stated ground for the withdrawal — a [Revocation Reason], carried from the call's [Reason].

Terms › `reason`: the [Revoke] argument the record keeps as `revocation_reason` — a [Reason].

Terms › `revoked_at`: the instant the withdrawal takes effect — a [Revoked At]; caller-supplied or resolved from `now`.

Terms › `granted_at`: the instant the consent record was created — a [Granted At]; always stamped from `now`.

Terms › `evaluation instant`: the instant a consent record's state is read against — the resolved `at_time` in [Check], `now` everywhere else.

Terms › `withdrawn`: the consent record carries a `revoked_at` no later than the evaluation instant.

Terms › `elapsed`: the consent record carries an `expires_at` no later than the evaluation instant.

Terms › `candidate record`: among the consent records carrying the call's `subject_ref` and `purpose`, the one whose `granted_at` is the latest that the resolved `at_time` does not precede; a tie on `granted_at` resolves to the greatest `consent_id` in lexicographic byte-order.

Terms › `later write`: a consent record written with a `granted_at`, a `revoked_at` or an `expires_at` later than the resolved `at_time`.

Terms › `query`: the filter set [Read] accepts — a [Query]; any combination of the supported filter axes.

Terms › `supported filter axes`: `consent_id` | `subject_ref` | `purpose` | `granted_by` | `state` | a time range on `granted_at` | a time range on `revoked_at` | a time range on `expires_at`.

Terms › `reference filter`: a `consent_id`, `subject_ref`, `purpose` or `granted_by` filter on a query.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the store |
|---|---|---|---|
| [Grant] | three references present, no `expires_at`, store accepts | the new `consent_id` | one record lands in [Granted] (Operation 1, Operation 2) |
| [Grant] | as above with an `expires_at` after [Now] | the new `consent_id` | as above, with [Expires At] recorded (Operation 7) |
| [Grant] | a blank reference, or an `expires_at` at or before [Now] | [Invalid Request] | none (Operation 4–6, Operation 8, Operation 9) |
| [Revoke] | id names a record in [Granted], attribution present, times ordered | `revoked` | [Granted] → [Revoked], three fields stamped (Operation 26–29) |
| [Revoke] | blank `consent_id` | [Invalid Request] | none — checked before the store is consulted (Operation 15, Operation 17) |
| [Revoke] | id names nothing | [Not Known] | none (Operation 16) |
| [Revoke] | id names a record in [Revoked] | [Already Revoked] | none (Operation 18) |
| [Revoke] | id names a record in [Expired] | [Already Expired] | none (Operation 19) |
| [Revoke] | record in [Granted], blank attribution or a time out of order | [Invalid Request] | none (Operation 22–25) |
| either write | store refuses | [Storage Failure] | none (Operation 13, Operation 31–33) |
| [Check] | the candidate record is withdrawn by [At Time] | `revoked` | none — the call reads (Operation 41, Operation 36) |
| [Check] | the candidate record is elapsed by [At Time], never withdrawn | `expired` | none (Operation 42, Operation 43) |
| [Check] | the candidate record is neither | `granted` | none (Operation 44) |
| [Check] | no record for the pair was granted by [At Time] | `not-known` | none (Operation 40) |
| [Read] | a well-formed query | the matching records, oldest first | none (Operation 47, Operation 48) |
| [Read] | a well-formed query matching nothing | an empty sequence | none (Operation 51) |
| [Read] | a blank filter value, a bad state, an inverted range, an unknown key | [Invalid Query] | none (Operation 55–59) |

WHY:
[Check] answers the question the caller asked — *what was the state at this instant* — and not *what is the stored state of the newest record*. That is the whole reason [At Time] exists, and why the evaluation runs against it rather than against [Now]: a regulator auditing whether processing on a past date was lawful and a system pre-flighting a campaign four weeks out depend on the same semantics (Operation 46, Invariant 10.1). A consent revoked or expired *later* than the instant asked about does not move the answer, which is what makes the store a faithful history rather than a current-state cache.

The two tiebreaks run in opposite directions on purpose. [Check] must select the *latest* record among `granted_at` ties, so it takes the greatest `consent_id`; [Read] enumerates oldest-first, so it takes them ascending. Both need the id to sort as bytes (Identity 8, Operation 50, Invariant 10.2).

[Check] refuses nothing, and [Read] refuses only a malformed query — the asymmetry the corpus keeps meeting. A query with an unrecognized key is the one case where refusing beats ignoring: silently dropping a filter returns a result set the caller did not ask for and cannot tell apart from the one it did (Operation 55, Operation 56). A time-range filter on a field a state's records do not carry is not malformed — it is well-formed and matches nothing, because [Revoked At] lives only on revoked records and [Expires At] only on records granted with a bound (Operation 60).

Rejection order on [Revoke] is carried by the guards rather than by a numbered priority: a blank `consent_id` is refused before the store is consulted, because a caller that passed garbage did not reference a missing record (Operation 15, Operation 17); the terminal-state answers are mutually exclusive by Invariant 2.1; and the attribution and temporal checks are conditioned on the record standing in [Granted], so a retry against an already-revoked record with a blank reason still answers [Already Revoked] (Operation 22–25).

### State

```text
State 1: EVERY consent record MUST stand in EXACTLY ONE OF granted, revoked, expired.
State 2: A consent record's state MUST rest on granted_at, revoked_at and expires_at against the evaluation instant.
State 3: EVERY consent record MUST carry consent_id, subject_ref, purpose, granted_by, granted_at and state.
State 4: A consent record MUST carry an expires_at the [Grant] call supplied.
State 5: A consent record MUST carry metadata the [Grant] call supplied.
State 6: A consent record MUST NOT carry an expires_at the [Grant] call omitted.
State 7: A revoked consent record MUST carry revoked_by, revocation_reason and revoked_at.
State 8: A granted consent record MUST NOT carry revoked_at.
State 9: An expired consent record MUST NOT carry revoked_at.
State 10: A revoked consent record MUST carry EVERY grant field.
State 11: The atom MUST NOT offer a transition out of revoked.
State 12: The atom MUST NOT offer a transition out of expired.
State 13: The atom MUST NOT suppress a processing act.
State 14: The atom MUST NOT hold a lawful basis outside consent.
State 15: The atom MUST NOT hold a purpose taxonomy.
```

Terms › `state`: `granted` | `revoked` | `expired` — in effect, withdrawn, or run out; a [State], derived per Expiry 1–4 against the evaluation instant.

Terms › `grant field`: `consent_id` | `subject_ref` | `purpose` | `granted_by` | `granted_at` | `expires_at` | `metadata` — what [Grant] writes and Invariant 1.1 freezes.

#### Expiry

```text
Expiry 1: IF a consent record is withdrawn THEN the consent record MUST stand in revoked.
Expiry 2: IF a consent record is elapsed THEN the consent record MUST stand in expired.
Expiry 3: A consent record MUST stand in expired ONLY IF the consent record is not withdrawn.
Expiry 4: A consent record MUST stand in granted ONLY IF the consent record is not withdrawn AND the consent record is not elapsed.
Expiry 5: The atom MUST NOT offer an action that stands a consent record in expired.
Expiry 6: The atom MUST NOT poll for an elapsed consent record.
Expiry 7: The composing pattern MUST NOT poll for an elapsed consent record.
```

WHY:
Expiry is a condition, not an act. Nothing triggers it, nothing polls for it, and there is no `expire` action to call — [Check] derives it from [Expires At] against the instant asked about (Expiry 5, Expiry 6). That is also why revocation wins a tie: a record revoked before its bound elapses is [Revoked], because the earlier terminal event is the one that happened (Expiry 3, Invariant 6.2).

#### Stored state

```text
Stored state 1: The implementation MAY write the stored state at the instant expires_at elapses.
Stored state 2: The implementation MAY write the stored state at the first evaluation past expires_at.
Stored state 3: The implementation MUST NOT answer a granted result for an elapsed consent record.
Stored state 4: The implementation MUST serialize a lazy stored state write for one consent record.
```

> **Clearly-marked residual (execution/render-time refactor — 2026-06-21).** The *authoritative* expiry determination is **derived** at read time: [Check] and [Read] both compute the state from [Expires At] and [Revoked At] against the evaluation instant, and [Check] is a pure query that never writes (Operation 36; there is no `expire` action — Expiry 5). The stored [State] field's [Expired] value is therefore a **materialized cache of the derived state, not the authority** — written for query convenience, and required by Invariant 2.2 to equal the derived state at the moment any result is returned. This stored write is the **residual** of this atom against the render-time target, which would carry no stored [Expired] write at all and derive the projection on every read, as Invitation does. It is *clearly marked here* rather than removed: dropping the stored [State] field is a structural change beyond this refactor, the eager/lazy design was introduced deliberately (Final Critique 4, to resolve the semantic-versus-stored contradiction), and because the cache must equal the derived value at read time it cannot serve as a flag that lags the clock in any conforming implementation. A future re-pass may collapse the stored [State] field to a pure read-time projection; that is an open design point, not done here.

### Invariants

- **Invariant 1 — Grant immutability.**
  ```text
  Invariant 1.1: A recorded consent record's grant fields MUST NOT change.
  Invariant 1.2: A grant field the [Grant] call omitted MUST NOT appear later.
  ```
- **Invariant 2 — Membership exclusivity.**
  ```text
  Invariant 2.1: EVERY consent record MUST stand in EXACTLY ONE OF granted, revoked, expired at the evaluation instant.
  Invariant 2.2: The stored state MUST equal the consent record's state at the instant a result reaches the caller.
  ```
- **Invariant 3 — Terminal absorption.**
  ```text
  Invariant 3.1: A revoked consent record MUST NOT leave revoked.
  Invariant 3.2: An expired consent record MUST NOT leave expired.
  Invariant 3.3: A composing pattern returning a data subject to agreement MUST call [Grant].
  ```
- **Invariant 4 — Revocation attribution is complete.**
  ```text
  Invariant 4.1: EVERY revoked consent record's revoked_by MUST carry a non-whitespace character.
  Invariant 4.2: EVERY revoked consent record's revocation_reason MUST carry a non-whitespace character.
  Invariant 4.3: EVERY revoked consent record MUST carry a revoked_at.
  ```
  WHY: an anonymous withdrawal, a whitespace-only ground, or a missing instant each defeats the one thing the record exists to demonstrate — that the data subject exercised the right, and that the system honoured it (Check 3.1).
- **Invariant 5 — Temporal ordering on revocation.**
  ```text
  Invariant 5.1: EVERY revoked consent record's granted_at MUST NOT EXCEED the revoked_at.
  ```
  WHY: the bound is on the value the record carries, so it holds whichever way the value was derived — a caller-supplied instant and a seam-resolved one meet the same floor, which is what makes it proof against clock-skew artifacts as well as backdating (Operation 25).
- **Invariant 6 — Expiry coherence.**
  ```text
  Invariant 6.1: IF the candidate record is elapsed THEN [Check] MUST answer expired.
  Invariant 6.2: IF the candidate record is withdrawn AND the candidate record is elapsed THEN [Check] MUST answer revoked.
  Invariant 6.3: The implementation MUST write the elapsed consent record's stored state within the operation that answers the caller.
  ```
  WHY: the bound on [Expires At] at grant time — strictly later than [Now] — is a [Grant] precondition and not part of this invariant (Operation 7–9). What this one holds is the reading: a record past its bound reads as [Expired], a record withdrawn first reads as [Revoked] because the earlier terminal event is the one that happened, and an implementation that answers a [Granted] result for a record whose state at the queried instant is [Expired] is non-conformant however it manages its cache.
- **Invariant 7 — Grant attribution is complete.**
  ```text
  Invariant 7.1: EVERY consent record's consent_id, subject_ref, purpose and granted_by MUST carry a non-whitespace character.
  Invariant 7.2: EVERY consent record MUST carry a granted_at.
  ```
  WHY: Invariant 1.1 holds these fields still; this one holds them non-blank. An anonymous grant, a whitespace-only purpose or a missing instant answers none of *who agreed to what, and when* — which is the whole regulatory question (Check 2.1).
- **Invariant 8 — Consent store durability.**
  ```text
  Invariant 8.1: The atom MUST NOT remove a consent record from the store.
  Invariant 8.2: The consent record count MUST NOT fall.
  Invariant 8.3: A storage-failure rejection MUST leave no partial consent record in the store.
  ```
- **Invariant 9 — Revocation non-retroactivity.**
  ```text
  Invariant 9.1: [Revoke] MUST NOT change a grant field.
  Invariant 9.2: [Revoke] MUST NOT change the lawfulness of a processing act the consent record covered.
  ```
  WHY: withdrawal terminates future reliance; it does not rewrite the past, which is GDPR Article 7(3)'s own construction and the reason the grant record survives the revocation intact.
- **Invariant 10 — Point-in-time faithfulness.**
  ```text
  Invariant 10.1: [Check] MUST answer from the candidate record alone.
  Invariant 10.2: A tie on granted_at MUST resolve to the greatest consent_id in lexicographic byte-order.
  Invariant 10.3: A later write MUST NOT change a [Check] answer for the at_time.
  Invariant 10.4: A repeated [Check] carrying one at_time MUST answer alike.
  ```
  WHY: this is the records-checkable form of the point-in-time claim — re-run the same [Check] after any strictly-later write and the answer is identical (Check 5.1). It is what lets a regulator ask about a past date and a scheduler ask about a future one through the same surface.

---

## Examples

### Grant, check, revoke, re-consent

A user onboarding to a health app affirms `analytics:behavioral`. The app calls `grant(subject_ref: user-4491, purpose: analytics:behavioral, granted_by: onboarding_service, expires_at: 2027-05-13T00:00:00Z)` → `cns-0001`. [Granted At] is stamped from the seam-injected [Now], here `2025-05-13T09:00:00Z`; the `expires_at` guard passes because the bound is later. The record enters [Granted].

Before emitting an analytics event the pipeline calls `check(subject_ref: user-4491, purpose: analytics:behavioral)` → `granted`, and processing proceeds.

The user withdraws through the app's privacy settings. The privacy service calls `revoke(cns-0001, revoked_by: privacy_service, reason: "User-initiated withdrawal via privacy settings")` → `revoked`. [Revoked At] is stamped from [Now], here `2026-05-13T14:30:00Z` — not later than [Now], not earlier than [Granted At]. The next gate check answers `revoked` and processing is suppressed.

Six months later the user re-enables analytics: `grant(...)` → `cns-0088`, a second record in [Granted]. `cns-0001` stays [Revoked] as evidence. [Check] now answers `granted`, because `cns-0088` is the candidate record. A later `read({subject_ref: user-4491})` returns both, with full attribution on each.

### Rejection paths

`revoke(cns-0001, revoked_by: privacy_service, reason: "retry")` after the first revoke → `rejected(already-revoked)`; the guard reads the stored record and writes nothing (Operation 18).

`grant(subject_ref: user-8823, purpose: "  ", granted_by: consent_ui)` → `rejected(invalid-request)`. A whitespace-only purpose is blank (Operation 5).

`grant(subject_ref: user-9001, purpose: marketing:sms, granted_by: consent_ui, expires_at: 2020-01-01T00:00:00Z)` → `rejected(invalid-request)`. A consent expiring in the past is already expired at the moment of grant, which is not a consent (Operation 8).

### Check against an instant

A consent for `analytics:behavioral` bounded at `2026-05-01T00:00:00Z`, checked on `2026-05-13` → `expired`, derived from the record and never from a stored flag (Operation 42).

Before queuing a 30-day campaign: `check(subject_ref: user-4491, purpose: marketing:email, at_time: 2026-06-13T00:00:00Z)` → `granted`, the consent running to `2027-01-01`. The campaign is scheduled knowing consent holds at delivery (Operation 39).

### Regulated adversarial scenarios

- **Regulator audit — GDPR Article 7 validity challenge.** A data protection authority investigates whether a controller held valid consent for `analytics:behavioral` processing on a given date. The controller runs `read({subject_ref: user-4491, purpose: analytics:behavioral})` and the authority reads three things from the records alone: whether a [Granted] record was in effect on the date, from [Granted At] against [Revoked At] and [Expires At]; whether the agreement was specific and informed, from [Granted By] naming the collection point, [Purpose] naming the scope, and [Metadata] carrying the form version; and whether the grant is immutable, from Invariants 1.1 and 7.1. No witness testimony and no developer narration.
- **Disputed revocation — the data subject claims non-compliance.** A complaint says marketing continued after withdrawal. `read({subject_ref: user-4491, purpose: marketing:email})` shows `cns-0001` granted `2025-03-01` and revoked `2026-01-15` by `privacy_portal`, with the stated ground. The atom's records fix exactly when the withdrawal was recorded and by which system; whether the sending system called [Check] first is the composing layer's conformance question, not this atom's (State 13, Composition note 2).
- **Cross-purpose audit — HIPAA Authorization review.** An HHS (US Department of Health and Human Services — the federal agency that enforces HIPAA) inquiry asks whether patient `patient-7712` authorized disclosure of PHI (Protected Health Information — individually identifiable health data covered by HIPAA) under `hipaa:research:partner-univ-cardiology`. `read(...)` returns a [Granted] record with `granted_at: 2025-09-01`, `expires_at: 2026-09-01`, `granted_by: clinical_consent_kiosk`. The disclosure occurred `2026-01-10`, and `check(..., at_time: 2026-01-10T00:00:00Z)` → `granted` settles it from the records.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the consent store's stored fields and its query surface, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```text
Check 1.1: An auditor MUST find EVERY issued consent_id in the store through [Read] (Invariant 8.1, Invariant 8.2).
Check 2.1: An auditor MUST find a non-whitespace character in EVERY consent record's consent_id, subject_ref, purpose and granted_by (Invariant 7.1).
Check 2.2: An auditor MUST find a granted_at on EVERY consent record (Invariant 7.2).
Check 3.1: An auditor MUST find a non-whitespace character in EVERY revoked consent record's revoked_by and revocation_reason (Invariant 4.1, Invariant 4.2).
Check 3.2: An auditor MUST find EVERY revoked consent record's granted_at no later than the revoked_at (Invariant 5.1).
Check 4.1: An auditor MUST find [Check] answering granted, then revoked once a [Revoke] lands, then granted once a fresh [Grant] lands (Invariant 3.1, Operation 44).
Check 5.1: An auditor MUST find [Check] answering granted for an at_time the expires_at exceeds, and expired for an at_time no earlier than the expires_at (Invariant 6.1).
Check 5.2: An auditor MUST read the stored state as a cache rather than as the answer (Invariant 2.2, Invariant 6.3).
Check 6.1: An auditor MUST find [Revoke] answering already-revoked against a revoked consent record (Invariant 3.1).
Check 6.2: An auditor MUST find [Revoke] answering already-expired against an expired consent record (Invariant 3.2).
Check 6.3: An auditor MUST find no consent record field changed by a refused [Revoke] (Operation 32, Operation 33).
Check 7.1: An auditor MUST find EVERY revoked and expired consent record still answering to [Read] (Invariant 8.1).
```

NOTE: EVERY check names the rule the check tests.

WHY:
Check 5.1 asserts on [Check]'s answer and not on a stored [Expired] field, because the stored field is a cache that Stored state 1 constrains rather than the authority that decides — an auditor who tested the cache would be testing the implementation's write strategy instead of the atom's commitment (Check 5.2).

## Non-goals

```text
Non-goal 1: The atom MUST NOT merge two [Grant] calls carrying one subject_ref and one purpose.
Non-goal 2: A deployment needing at-most-once grant MUST compose [Duplicate Prevention](./duplicate-prevention.md).
Non-goal 3: The atom MUST NOT hold at most one granted consent record per subject_ref and purpose.
Non-goal 4: A deployment needing one live agreement per pair MUST enforce the bound at the composing layer.
Non-goal 5: The atom MUST NOT define a valid purpose.
Non-goal 6: The atom MUST NOT expand a purpose hierarchy.
Non-goal 7: The atom MUST NOT interpret metadata.
Non-goal 8: A deployment needing required metadata content MUST NOT call [Grant] BEFORE enforcing the content.
Non-goal 9: The atom MUST NOT propagate a withdrawal downstream.
Non-goal 10: A deployment needing propagation MUST compose a consent-revocation-propagation pattern.
Non-goal 11: The atom MUST NOT hold a lawful basis the data subject did not give.
Non-goal 12: The atom MUST NOT gate an action on a caller's authority.
Non-goal 13: A deployment needing access control MUST compose [Permissions](./permissions.md).
Non-goal 14: The atom MUST NOT establish that a granting actor may agree for the data subject.
Non-goal 15: A deployment needing proxy consent MUST compose a guardian-relationship pattern.
Non-goal 16: The atom MUST NOT seal a consent record against modification.
Non-goal 17: A deployment needing court-admissible records MUST compose [Tamper Evidence](./tamper-evidence.md).
Non-goal 18: The atom MUST NOT bound how long a consent record is kept.
Non-goal 19: A deployment needing a retention bound MUST compose [Retention Window](./retention-window.md).
Non-goal 20: The atom MUST NOT record who called an action.
Non-goal 21: A deployment needing attribution MUST compose [Actor Identity](./actor-identity.md).
Non-goal 22: The atom MUST NOT guarantee a consent_id unique across store instances.
```

WHY:
[Grant] is not idempotent and the atom does not police the pair, and both are the same decision: the data subject's most recent affirmative signal governs, and every prior signal stays as history (Non-goal 1, Non-goal 3). A collection surface that retries after a timeout creates a second valid record — which is why [Duplicate Prevention](./duplicate-prevention.md) sits in front of it where at-most-once matters, rather than uniqueness being built in here where it would delete the history the atom exists to hold.

Purpose is opaque and stays opaque: `marketing:email` and `42` are equally valid to the atom. Which scopes exist, how they nest, and which imply which is a taxonomy the deployment owns, because a hierarchy built in here would make every deployment inherit one system's naming (Non-goal 5, Non-goal 6).

Consent is one lawful basis among several. GDPR Article 6 names six; a deployment relying on legitimate interest or contract necessity for a processing act does not use this atom for that act, and the atom neither knows nor asks (Non-goal 11).

Who may grant on a subject's behalf, who may withdraw, and who may read the records are all outside — and the proxy case is the sharpest instance: a guardian consenting for a minor needs a relationship record establishing the authority, which this atom does not hold and does not check (Non-goal 12, Non-goal 14, Non-goal 15).

## Edge cases

### Clock semantics

```text
Clock semantics 1: The deployment MUST own the clock's monotonicity.
Clock semantics 2: The deployment MUST own the clock's timezone handling.
Clock semantics 3: The deployment MUST supply an honest now.
Clock semantics 4: A guard MAY read now ONLY IF the call carries an instant.
Clock semantics 5: [Grant] MUST guard a supplied expires_at against now.
Clock semantics 6: [Revoke] MUST guard a supplied revoked_at against now.
Clock semantics 7: The transition MUST NOT stamp granted_at from a caller-supplied instant.
Clock semantics 8: [Revoke] MAY record a revoked_at earlier than now.
```

WHY:
This atom accepts three caller-supplied instants — `expires_at`, `revoked_at` and `at_time` — and that is exactly why its guards read the clock where Message Preference's are forbidden to. A guard consults `now` to refuse a dishonest instant and for nothing else: a bound already in the past, a withdrawal dated in the future (Clock semantics 4–6). A backdated `revoked_at` is accepted on purpose — documenting a withdrawal recognized or communicated earlier is valid, and the floor is [Granted At] rather than [Now] (Clock semantics 8, Invariant 5.1).

Nothing else consults it. [Granted At] is always the seam's reading and never the caller's, because the moment of agreement is the system's observation rather than the caller's claim (Clock semantics 7).

### Concurrency

```text
Concurrency 1: The implementation MUST serialize a state transition on one consent_id.
Concurrency 2: Two concurrent [Revoke] calls on one consent_id MUST answer revoked once.
Concurrency 3: The later concurrent [Revoke] call on one consent_id MUST answer already-revoked.
Concurrency 4: Two concurrent [Grant] calls carrying one subject_ref and one purpose MUST record two consent records.
```

WHY:
Concurrent grants for one pair are not a race, because the atom admits several records over the pair by design — each call gets its own id and its own history (Concurrency 4, Non-goal 3). The races that are real are both on one record: two withdrawals, where Invariant 3.1 does the work once the transitions serialize; and two readers triggering a lazy cache write, where the write must land once and both readers must see the same state after it.

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST NOT run a processing act BEFORE calling [Check].
Composition note 3: A composing pattern MUST own the suppression of a processing act.
Composition note 4: A composing pattern MUST own the propagation of a withdrawal.
Composition note 5: A composing pattern MUST own the purpose taxonomy.
Composition note 6: A composing pattern MUST own the retention of the consent store.
Composition note 7: A composing pattern MUST own the authority to grant for a data subject.
Composition note 8: A composing pattern MUST NOT stand a consent record in any state.
```

WHY:
[Permissions](./permissions.md) is the composing peer, not the substitute: it governs what an internal actor may do, this governs what the system may do to the subject's data, and an action may need both. [Actor Identity](./actor-identity.md) turns the opaque `granted_by` and `revoked_by` into credentialed, attested actors — which HIPAA and 21 CFR (Code of Federal Regulations) Part 11 require of consent collection and withdrawal as electronic records. [Audit Trail](../compositions/audit-trail.md) records each grant and revoke as an attributed, retention-governed event. [Retention Window](./retention-window.md) bounds how long the store is kept, against GDPR's *as long as necessary* and HIPAA's six years. [Tamper Evidence](./tamper-evidence.md) seals the records for court and regulator admissibility beyond this atom's spec-level immutability. [Legal Hold](./legal-hold.md) overrides that retention where a consent record is itself under litigation.

Two compositions own what the atom deliberately does not. [Propagate Consent Revocation Downstream](../compositions/propagate-consent-revocation-downstream.md) records, atomically with each withdrawal, the complete set of downstream processing scopes the consent governed — the propagation Non-goal 9 excludes. [Resolve a Person's Data Rights](../compositions/resolve-a-persons-data-rights.md) composes this atom as a read-only authority oracle: an erasure request calls [Check] to make the Article 17(1)(b) determination, mapping all four answers — `granted` means a ground persists, `revoked` and `expired` mean the consent basis is gone, `not-known` is a registry anomaly — and never grants, revokes or expires anything, which is why Composition note 8 exists.

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a guard; a data subject; an auditor; a reader; the store; a consent record; a state; a store_name; a query; a time range; a reference filter; a later write; the consent record count; the stored state.

Terms › `records`: `consent record` — one agreement to one purpose, carrying `consent_id`, `subject_ref`, `purpose`, `granted_by`, `granted_at`, `state`, the `expires_at` and `metadata` supplied at grant, and, once withdrawn, `revoked_by`, `revocation_reason` and `revoked_at`.

Terms › `record verbs`: route, share, name, accept, carry, identify, allocate, reuse, change, draw, interpret, confirm, record, stand, answer, stamp, resolve, refuse, write, evaluate, order, exclude, ignore, leave, read, supply, rest, offer, remove, suppress, hold, poll, equal, serialize, appear, meet, fall, find, compose, define, expand, enforce, propagate, gate, establish, seal, bound, guarantee, own, guard, declare, call, run, merge, precede.

Terms › `value sets`: grant answers = consent_id | rejected(invalid-request | storage-failure). revoke answers = revoked | rejected(invalid-request | not-known | already-revoked | already-expired | storage-failure). check answers = granted | revoked | expired | not-known. read answers = an ordered sequence of consent records, empty where nothing matches | rejected(invalid-query). `state` = granted | revoked | expired. `supported filter axes` and `grant field` are declared above and cited here (Closed vocabulary 15).

Terms › `bounds`: empty.

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-12).

Terms › `terms`: `consent record`, `store instance`, `store_name`, `seam`, `transition`, `consent_id`, `subject_ref`, `purpose`, `granted_by`, `blank`, `now`, `business caller`, `at_time`, `grant guard`, `expires_at`, `metadata`, `revoked_by`, `revocation_reason`, `reason`, `revoked_at`, `granted_at`, `evaluation instant`, `withdrawn`, `elapsed`, `candidate record`, `later write`, `query`, `supported filter axes`, `reference filter`, `state`, `grant field`.

#### Grant

The behavior a consent collection surface invokes to record a data subject's affirmative agreement to a named [Purpose]. It assigns a fresh [Consent Id], stamps [Granted At] from the injected [Now], records [Subject Ref], [Purpose], [Granted By], and [Expires At] / [Metadata] if supplied, and returns the [Consent Id] (or a rejection). The consent enters [Granted].

Kind: Operation

#### Revoke

The behavior that documents a data subject's withdrawal of consent, transitioning a [Granted] record to [Revoked]. It records [Revoked By], [Revocation Reason], and [Revoked At], all immutable thereafter. A [Revoked] or [Expired] record cannot be revoked ([Already Revoked] / [Already Expired]) — terminal absorption (Invariant 3).

Kind: Operation

#### Check

The pure point-in-time query that evaluates the consent state for a (subject, [Purpose]) as of [At Time], returning one of `granted | revoked | expired | not-known`. It selects the record with the greatest [Granted At] ≤ [At Time], evaluates that record's [Revoked At] / [Expires At] against [At Time], and never writes and never rejects (Invariant 10).

Kind: Operation

#### Read

The read-only behavior that returns the consent records matching a [Query], ordered by [Granted At] ascending then [Consent Id] ascending. It changes nothing. Filters by [Consent Id], [Subject Ref], [Purpose], [Granted By], [State], or time range are combinable; a malformed one is rejected [Invalid Query].

Kind: Operation

#### Consent Id

The opaque, immutable, system-generated identity of a consent record, assigned on [Grant], never reused or reassigned within the store instance. A non-empty string sortable in lexicographic byte-order — required for deterministic [Read] ordering and [Check] tiebreaking. The subject, purpose, actor, and timestamps are properties of the record, not its identity.

Kind:     Field
Field of: the consent record
Projects: consent_id

#### Subject Ref

The opaque reference to the data subject whose consent is recorded. Set on [Grant], immutable. The atom does not validate that the subject exists elsewhere; it is the caller's responsibility.

Kind:     Field
Field of: the consent record
Projects: subject_ref

#### Purpose

The opaque string naming the processing-purpose scope the consent covers (e.g., `marketing:email`). Set on [Grant], immutable, caller-declared vocabulary the atom does not interpret. Two records with the same [Subject Ref] and [Purpose] are distinct records.

Kind:     Field
Field of: the consent record
Projects: purpose

#### Granted By

The opaque reference to the actor who recorded the data subject's affirmative agreement — the attribution anchor for the consent event. Set on [Grant], immutable; empty or whitespace-only is rejected.

Kind:     Field
Field of: the consent record
Projects: granted_by

#### Granted At

The timestamp the consent was granted, stamped from the injected [Now] at [Grant]. Set once, immutable (Invariant 1). The lower temporal bound for [Revoked At] (Invariant 5) and the selection key for [Check] / ordering key for [Read].

Kind:     Field
Field of: the consent record
Projects: granted_at

#### Expires At

The optional timestamp at which the consent expires. Set on [Grant] (must be strictly in the future relative to the injected [Now]); immutable. When [Expires At] ≤ the evaluating clock and no revocation precedes it, the semantic state is [Expired]. Absent ⇒ the consent never expires by time.

Kind:     Field
Field of: the consent record
Projects: expires_at

#### Metadata

The optional opaque payload supplied at [Grant] — consent form version, signal type, jurisdiction. Stored as-is, never parsed or validated; immutable after grant (Invariant 1). Deployment-specific content rules belong to the composing layer.

Kind:     Field
Field of: the consent record
Projects: metadata

#### Revoked By

The opaque reference to the actor who recorded the withdrawal. Set at [Revoke], immutable thereafter; present on [Revoked] records only. Empty or whitespace-only is rejected [Invalid Request].

Kind:     Field
Field of: the consent record
Projects: revoked_by

#### Revocation Reason

The required, non-empty reason for the withdrawal — written from the [Reason] parameter. Set at [Revoke], immutable thereafter; present on [Revoked] records only. A blank reason defeats the audit trail and is rejected.

Kind:     Field
Field of: the consent record
Projects: revocation_reason

#### Revoked At

The timestamp the consent was revoked — supplied or defaulted to the injected [Now]. Must not be future and must be ≥ [Granted At] (Invariant 5). Set at [Revoke], immutable; present on [Revoked] records only.

Kind:     Field
Field of: the consent record
Projects: revoked_at

#### State

The consent record's lifecycle state — [Granted], [Revoked], or [Expired]. The stored [State] field is a materialized cache of the derived semantic state, constrained to equal it at read time (Invariants 2 and 6) — not the authority for expiry, which is derived.

Kind:     Field
Field of: the consent record
Projects: state

#### Store Name

The identifier of the store instance a consent record belongs to. Multiple instances coexist; [Consent Id]s are unique within an instance. No action accepts it as a parameter — instance selection is handled at the deployment-routing layer.

Kind:     Field
Field of: the store instance
Projects: store_name

#### Now

The current clock reading the pipeline consumes — the injected `clock_t`, supplied at the I/O seam, never read inside a transition and never a signature parameter. It stamps the immutable write timestamps ([Granted At], [Revoked At]) and drives the pure expiry guard / derivation (no write); [At Time] defaults to it when omitted.

Kind:         Parameter
Parameter of: Grant
Projects:     now

#### At Time

The point-in-time the caller is asking [Check] about — a caller-supplied query input, past, present, or future. Not the injected clock (it defaults to the seam-injected [Now] when omitted) and not stored. [Check] evaluates the selected record's fields against [At Time].

Kind:         Parameter
Parameter of: Check
Projects:     at_time

#### Reason

The required, non-empty reason string [Revoke] consumes — written into [Revocation Reason]. Not stored under this name; an empty or whitespace-only value is rejected [Invalid Request].

Kind:         Parameter
Parameter of: Revoke
Projects:     reason

#### Query

The selection [Read] consumes — a filter over [Consent Id], [Subject Ref], [Purpose], [Granted By], [State], and/or a time range. Supplied per call, not stored; a malformed one is rejected [Invalid Query].

Kind:         Parameter
Parameter of: Read
Projects:     query

#### Granted

The state of a consent in effect for its [Purpose]. A record enters [Granted] on [Grant]; it may be revoked or evaluated, and its semantic state becomes [Expired] passively when [Expires At] elapses.

Kind:      Member
Member of: the consent state
Role:      Outcome

#### Revoked

The terminal state of a consent the data subject has withdrawn. Carries [Revoked By], [Revocation Reason], and [Revoked At]; retained as audit evidence, no further transition (Invariant 3).

Kind:      Member
Member of: the consent state
Role:      Outcome

#### Expired

The terminal state of a consent whose [Expires At] has elapsed with no prior revocation. Derived from [Expires At] vs the evaluating clock; the stored [State] cache is written eager/lazy. Retained, no further transition (Invariant 3).

Kind:      Member
Member of: the consent state
Role:      Outcome

#### Not Known

The outcome [Check] returns — and the refusal [Revoke] returns — when no record exists for the queried (subject, [Purpose]) pair, or when the named [Consent Id] references no record in this store instance. A first-class [Check] result, never an error there.

Kind:      Member
Member of: the action outcome
Role:      Outcome
Projects:  not-known

#### Invalid Request

The refusal [Grant] or [Revoke] returns when request fields fail — an empty or whitespace-only [Subject Ref], [Purpose], [Granted By], [Revoked By], or [Reason]; an [Expires At] not in the future at [Grant]; a malformed [Consent Id]; or a [Revoked At] that is future or before [Granted At].

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  invalid-request

#### Storage Failure

The refusal any writing action returns when a durable write fails after preconditions pass. All-or-none: no partial record is observable, and the prior state is unchanged (Invariant 8).

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

#### Already Revoked

The refusal [Revoke] returns when the target is already [Revoked] — terminal absorption (Invariant 3); a pure guard that writes nothing.

Kind:      Member
Member of: the Revoke rejection
Role:      Outcome
Projects:  already-revoked

#### Already Expired

The refusal [Revoke] returns when the target is already [Expired] — terminal absorption (Invariant 3); a pure guard, evaluated as the derived semantic state, that writes nothing.

Kind:      Member
Member of: the Revoke rejection
Role:      Outcome
Projects:  already-expired

#### Invalid Query

The refusal [Read] returns when query parameters are malformed — a null/empty/whitespace filter value, a [State] value outside {[Granted], [Revoked], [Expired]}, a time range with end before start, or an unrecognized filter key.

Kind:      Member
Member of: the Read rejection
Role:      Outcome
Projects:  invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Grant]: #grant
[Revoke]: #revoke
[Check]: #check
[Read]: #read
[Consent Id]: #consent-id
[Subject Ref]: #subject-ref
[Purpose]: #purpose
[Granted By]: #granted-by
[Granted At]: #granted-at
[Expires At]: #expires-at
[Metadata]: #metadata
[Revoked By]: #revoked-by
[Revocation Reason]: #revocation-reason
[Revoked At]: #revoked-at
[State]: #state
[Store Name]: #store-name
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
- **GDPR Article 30** — record of processing activities must include the purpose of processing and the legal basis. Consent records with [Purpose] and [Granted At] supply the Article 30 documentation surface.
- **CCPA / CPRA** — right to opt-out of sale or sharing of personal information; right to opt-in for sensitive personal information. The [Grant] and [Revoke] actions are the opt-in and opt-out mechanisms. CPRA extends consent requirements to sensitive personal information categories.
- **HIPAA §164.508 (Authorization)** — required elements for a valid authorization include: a description of the information to be used or disclosed ([Purpose]), the name of the person authorized to make the disclosure ([Granted By] + composing Actor Identity), an expiration date or event ([Expires At]), and the right to revoke ([Revoke] action). The consent record's fields map directly to the required Authorization elements.
- **HIPAA §164.522** — right of an individual to request restrictions on certain uses and disclosures of PHI. Consent records with granular [Purpose] scoping are the mechanism.
- **21 CFR Part 11** — electronic records and signatures in FDA-regulated contexts. Consent records for clinical trial participation are regulated records under Part 11; [Granted By] and [Revoked By] map to electronic signature requirements when composed with Actor Identity.
- **ICH E6 Good Clinical Practice §4.8** — the International Council for Harmonisation's E6 guideline; informed consent requirements for clinical trial subjects, including documentation, right of withdrawal, and retention of consent records. The consent record lifecycle (grant, revoke, retain) is the Part 4.8 compliance mechanism.
- **Children's Online Privacy Protection Act (COPPA)** — verifiable parental consent required for data collection from children under 13. Proxy consent (guardian granting on behalf of minor subject) is handled at the composing layer; the atom records the grant faithfully.
- **ePrivacy Directive (Cookie Law)** — consent required for non-essential cookies and tracking. Web consent banners produce [Grant] calls; user withdrawal produces [Revoke] calls. The consent record is the ePrivacy audit artifact.

---

## Status

`grounded on Final Critique 5 — 2026-06-23` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 5 — 2026-06-23
formal: not applicable — vote no 2026-06-03
last gate: 2026-06-23 — Final Critique 5, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/consent.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the ten invariant numbers and the seven acceptance-check numbers unchanged, the [Check] selection routed through a declared `candidate record` and the two comparisons through `withdrawn` and `elapsed`, the semantic/stored split kept as two rule families with the dated residual note carried over verbatim, the case space kept beside the rules as a table, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk. The rejection priority [Revoke] carried as an arrow diagram is now carried by the guards — a blank `consent_id` is refused before the store is consulted, the terminal answers are exclusive by Invariant 2.1, and the attribution and temporal checks are conditioned on the record standing in [Granted].

- **2026-06-23 — Expiry is derived at `check`, with the stored `Expired` cache marked as a residual; `now` is not a signature parameter.** *Chose:* `check` evaluates expiry against the injected clock (or a caller-supplied `at_time?`, a query parameter, not the clock); the stored-Expired transition an implementation may write is a cache and is marked so. *Over:* threading `now` into `grant` / `revoke`, or treating stored `Expired` as the truth. *Because:* the execution contract injects the clock at the seam, and a stored flag that lags the clock is a cache, not a fact.

NOTE: End of Consent.
