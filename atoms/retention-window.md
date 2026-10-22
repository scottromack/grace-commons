---
title: Retention Window
parent: Atomic Concepts
has_toc: true
toc: true
---

# Retention Window

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Retention Window enforces the rule that a record must be kept for a minimum period and only then becomes eligible for destruction. For every managed record it stores which retention policy applies, when the keep-period ends, and the latest date by which destruction is expected. It blocks early deletion outright. Trying to purge a record before its period is up is refused; a purge destroys the record or, where another pattern does the destroying, ends the retention and leaves the destruction to that pattern. It also makes overdue records visible: anything still kept past its deadline shows up in the data as overdue, which a compliance dashboard can spot from the records alone. Two dates are fixed each time a record is placed under retention: the earliest date destruction is allowed, and the latest date it is expected. The span between them is the window in which destruction is both permitted and expected. The pattern enforces the early boundary — no destruction before the period ends. It only observes the late one. A record purged past its deadline reads in the records as a finding, not a refusal, because refusing a late purge would only make the overdue situation worse. This is the mechanism behind multi-year retention of financial and medical records, rules that keep payment-card data no longer than it is needed, and contract retention that outlasts the deal. It does not handle where records physically live, litigation holds, or privacy-law erasure — those are separate patterns.

---

## Intent

WHY:
A regulated record has two deadlines and they point opposite ways: keep it long enough, and do not keep it longer. Too-early destruction breaks a retention obligation; too-late destruction breaks data minimization. Both are auditable, and a system that holds the rule in a scheduler, a runbook or a cron comment cannot prove either. This atom makes the obligation a record: what is retained, under which policy, from when, until when, and by when it should be gone. It enforces the first deadline structurally — purge before the retention period elapses is refused — and it observes the second rather than enforcing it, because refusing a late purge would compound the very overshoot it detects. Everything else a retention regime needs — what a policy says, what a hold suspends, what destruction means on immutable storage, who authorized it — is a composing pattern's, and the atom names each limit rather than pretending to cover it.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a retention by the retention id.
Identity 2: The host MUST allocate a retention id at the atom's seam.
Identity 3: The transition MUST NOT allocate a retention id.
Identity 4: The business caller MUST NOT supply a retention id at a placement.
Identity 5: The atom MUST NOT reuse a retention id.
Identity 6: The atom MUST NOT identify a retention by the record reference.
Identity 7: The atom MUST NOT identify a retention by the policy reference.
Identity 8: The atom MUST NOT identify a retention by retention instant.
Identity 9: Two retentions over one record MUST carry two retention ids.
Identity 10: The atom MUST compare two record references by exact value.
```

NOTE: open 2026-10-03-k — non-reuse of a retention id has two owners (Identity 5 and Invariant 9.1, beside Capability requirement 8 and Capability requirement 9), a colliding id has no refusal arm, and no action makes the comparison Identity 10 obliges.

Term retention: one recorded obligation over one record under one policy — a [Retention Window] instance's record.

Term retention id: the opaque value naming one retention — a [Retention Id].

Term record reference: the opaque reference naming what is retained — a [Record Reference]; the host owns what a record is.

Term policy reference: the opaque reference naming which rules apply — a [Policy Reference]; the policy registry is a separate concept.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the retention id and the resolved policy scalars here.

Term transition: the atom's evaluation of one call against the retention records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

NOTE: open 2026-10-03-j — Term seam, Term transition and Term business caller cite the section titled Logic Confinement Principle in `execution-contract.md`, which declares none of them.

### State

```
State 1: EVERY retention MUST stand in EXACTLY ONE OF retained, purged.
State 2: EVERY retention MUST carry retention id, record reference, policy reference, retention instant, retention deadline and purge deadline.
State 3: A purged retention MUST carry purge instant.
State 4: [Place Under Retention] MUST set retention instant from the injected now.
State 4a: [Place Under Retention] MUST round retention instant up to the time resolution.
State 5: [Place Under Retention] MUST set retention deadline from the policy's duration.
State 6: [Place Under Retention] MUST set purge deadline from the policy's max purge delay.
State 6a: [Place Under Retention] MUST round retention deadline and purge deadline up to the time resolution.
State 7: The atom MUST NOT store purge eligibility.
State 8: The atom MUST NOT offer a restore surface.
State 9: The atom MUST NOT offer a policy-change surface.
State 10: The atom MUST NOT hold a storage tier.
```

NOTE: open 2026-10-03-f — four propositions have two owners each: State 1 and Invariant 1.1, State 7 and Invariant 11.1, State 8 and Invariant 3.2, Operation 28 and Invariant 11.2.

Term retention state: retained | purged — under obligation, or ended by a purge and terminal.

Term retention instant: the instant the retention was placed, stamped from the injected now — a [Retention Instant].

Term retention deadline: `retained_at + duration`, rounded up to the time resolution — a [Retention Deadline]; the instant the obligation ends.

Term purge deadline: `retention_until + max_purge_delay`, rounded up to the time resolution — a [Purge Deadline]; the latest the regulator expects destruction.

Term purge instant: the instant the purge was recorded, stamped from the injected now — a [Purge Instant].

Term overshoot: `purged_at - purge_deadline` where positive, for a purged retention — an [Overshoot]; a reader derives it, the atom does not store it and [Read] does not answer it.

Term active overdue: `now - purge_deadline` where positive, for a retained retention — an [Active Overdue]; a reader derives it, the atom does not store it and [Read] does not answer it.

Term duration: the retention period the policy carries, resolved to an elapsed length at the seam (Operation 24a) — a [Duration]; positive.

Term zero duration: a duration of no length — the floor a policy's duration must exceed, and the floor a max purge delay must not fall below.

Term degenerate duration: a duration the host could not resolve to an elapsed length (Operation 24a).

Term max purge delay: the lag the policy allows between retention-end and purge — a [Max Purge Delay]; not negative.

Term purge eligible: yes | no — a [Purge Eligible]; yes exactly when the retention state EQUALS retained AND the injected now does not precede retention deadline. Derived at the moment a question is asked, never written; the term entry's purge eligible is the projection of this answer.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 4: IF no composing pattern owns the destruction THEN the deployment MUST supply the storage layer, which destroys the record a retention names and confirms the destruction.
Capability requirement 4a: The storage layer the deployment supplies MUST NOT destroy a record under a request once the [Purge] that made the request has answered or has been abandoned.
Capability requirement 5: The deployment MUST declare the time resolution.
Capability requirement 6: IF no composing pattern owns the destruction THEN the deployment MUST destroy a record a retention names from [Purge] alone.
Capability requirement 6a: IF a composing pattern owns the destruction THEN the deployment MUST destroy a record a retention names through that pattern alone.
Capability requirement 7: The deployment MUST retain the instant of EVERY destruction of a record a retention names, read from the clock that supplies now, for the life of the instance.
Capability requirement 8: The deployment MUST supply EVERY placement a retention id naming no retention of the retention records.
Capability requirement 9: The deployment MUST NOT supply the same retention id to two placements.
Capability requirement 10: The deployment MUST supply EXACTLY ONE record reference per record.
Capability requirement 11: The deployment MUST place EVERY retention over one record in one [Retention Window] instance.
Capability requirement 12: The deployment MUST supply the retention records PER Execution Contract Database 1 through 4, Execution Contract Read 1 through 3, Execution Contract Refusal 1 and Execution Contract Conformance 9.
Capability requirement 13: The deployment MUST NOT reuse a record reference for another record.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
```

NOTE: open 2026-10-03-b — the policy registry and the lengths the host resolves from it (Operation 24, Operation 24a), which composing pattern owns the destruction (Term owns the destruction), the joint-enforcement pattern (Simultaneous retention 5) and the alert (Purge persistence 3) are the deployment's, and no Capability requirement lists them.

NOTE: open 2026-10-20-b — *destruction*, the confirmation an owning pattern records, *undestroyed* and *abandoned* carry rules and are declared nowhere, Term storage layer declaring only the storage layer's confirmation; Capability requirement 4a bars a destruction once its [Purge] has been abandoned, and nothing says when a [Purge] that never answers is.

### Operations

```
place_under_retention(record_ref, policy_ref)
  answers retention_id
  refuses invalid-request | registry-unavailable | policy-not-found | invalid-policy | storage-failure

purge(retention_id)
  answers ok
  refuses not-known | not-retained | retention-period-not-elapsed | storage-failure

read()
  answers every retention
```

```
Operation 1: [Place Under Retention] MUST record EXACTLY ONE retention per successful call.
Operation 2: [Place Under Retention] MUST stand the retention in retained.
Operation 3: [Place Under Retention] MUST answer retention id.
Operation 4: IF record reference EQUALS blank THEN [Place Under Retention] MUST answer invalid-request.
Operation 5: IF policy reference EQUALS blank THEN [Place Under Retention] MUST answer invalid-request.
Operation 6: IF the policy reference IS NOT IN the policy registry THEN [Place Under Retention] MUST answer policy-not-found.
Deleted: Operation 6a. Execution Contract Refusal 1 owns it.
Operation 7: IF the policy's duration DOES NOT EXCEED the zero duration THEN [Place Under Retention] MUST answer invalid-policy.
Operation 7a: IF the policy's duration EQUALS degenerate duration THEN [Place Under Retention] MUST answer invalid-policy.
Operation 8: IF the zero duration EXCEEDS the policy's max purge delay THEN [Place Under Retention] MUST answer invalid-policy.
Deleted: Operation 8a. Execution Contract Refusal 1 owns it.
Operation 8b: IF the host could not resolve the policy's max purge delay to an elapsed length THEN [Place Under Retention] MUST answer invalid-policy.
Operation 8c: IF retention deadline IS NOT IN the instants the database holds OR purge deadline IS NOT IN the instants the database holds THEN [Place Under Retention] MUST answer invalid-policy.
Operation 9: IF the database refuses the write THEN [Place Under Retention] MUST answer storage-failure.
Deleted: Operation 9a. Execution Contract Refusal 1 owns it.
Deleted: Operation 10. Execution Contract Database 1 owns it.
Operation 11: [Place Under Retention] MUST NOT read the host's records.
Operation 12: [Purge] MUST stand the retention in purged.
Operation 13: [Purge] MUST stamp purge instant from the injected now.
Operation 13a: [Purge] MUST round purge instant up to the time resolution.
Operation 14: IF no retention EXISTS for the retention id THEN [Purge] MUST answer not-known.
Operation 15: IF the retention state EQUALS purged THEN [Purge] MUST answer not-retained.
Operation 16: IF the retention state EQUALS retained AND purge eligible EQUALS no THEN [Purge] MUST answer retention-period-not-elapsed.
Operation 17: [Purge] MUST NOT write on retention-period-not-elapsed.
Operation 18: [Purge] MUST NOT refuse a retention whose purge deadline has passed.
Operation 19: IF the database refuses the write THEN [Purge] MUST answer storage-failure.
Deleted: Operation 19a. Execution Contract Refusal 1 owns it.
Operation 20: [Purge] MUST leave the retention in retained on storage-failure.
Operation 21: [Purge] MUST judge against one injected now per call.
Deleted: Operation 22. Operation 13 and Operation 21 own it: [Purge] judges against one injected now per call and stamps purge instant from the injected now.
Deleted: Operation 23. Capability requirement 1 owns it.
Operation 24: The host MUST resolve the policy at the seam of [Place Under Retention] alone.
Operation 24a: The host MUST resolve the policy's duration and the policy's max purge delay to elapsed lengths at the atom's seam.
Operation 24b: IF the host cannot read the policy registry at a placement THEN [Place Under Retention] MUST answer registry-unavailable.
Deleted: Operation 24c. Execution Contract Refusal 1 owns it.
Deleted: Operation 25. Execution Contract Logic confinement 3 owns it.
Operation 26: The transition MUST NOT read the policy registry.
Deleted: Operation 27. Execution Contract Logic confinement 3 owns it.
Operation 28: A reader MUST derive purge eligible from the retention state, retention deadline and the injected now.
Operation 29: [Read] MUST answer EVERY retention, retained AND purged.
Operation 30: [Read] MUST answer a retention's stored fields.
Operation 31: [Read] MUST answer purge eligible PER retained retention.
Operation 32: [Read] MUST NOT write.
Deleted: Operation 33. Operation 29 and Execution Contract Read 2 own it.
Deleted: Operation 34. Execution Contract Read 1 owns it.
Deleted: Operation 35. Execution Contract Refusal 1 owns it.
Deleted: Operation 36. Execution Contract Refusal 1 owns it.
```

NOTE: watch the comparator written in English (Operation 8c).

NOTE: open 2026-10-20-a — Operation 6, Operation 8b, Operation 8c and Operation 24b answer on the registry's reply, on a max purge delay the host could not resolve and on the instants the database holds, which the transition may not read (Operation 26) and Term seam does not list among the values the host injects; an unresolved delay has no term, as an unresolved duration has (Term degenerate duration).

NOTE: open 2026-10-20-d — Operation 8c holds a placement's deadlines inside the instants the database holds and nothing holds the purge instant there, so a purge past them destroys the record and then cannot write (Operation 19, Operation 20), and no retry settles it.

NOTE: open 2026-10-03-l — the day a calendar period counts from is stated for no policy (Operation 24a), a reference is checked for blank alone (Identity 6, Operation 4, Operation 5), and [Read] answers in no stated order and with no bound.

NOTE: open 2026-10-05-a — [Read] answers every retention of the instance with no key (Operation 29), so a composing pattern's read by retention id or by record is a whole-database enumeration under the pattern's lease.

Term time resolution: the smallest span the deployment's clock and the database tell apart (Capability requirement 5), and the epoch its multiples are measured from, fixed for the life of the instance.

Term well-formedness check: Operation 4 and Operation 5 — every check [Place Under Retention] makes on the call's own inputs.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the retention records |
|---|---|---|---|
| [Place Under Retention] | refs well-formed, policy resolves and is valid, database accepts | retention id | one retention lands in [Retained] with its two deadlines (Operation 1, State 4 through 6) |
| [Place Under Retention] | blank record reference or policy reference | [Invalid Request] | none (Operation 4, Operation 5) |
| [Place Under Retention] | policy reference resolves to nothing | [Policy Not Found] | none (Operation 6) |
| [Place Under Retention] | the host cannot read the policy registry | [Registry Unavailable] | none — the well-formedness checks passed and no policy was read (Operation 24b, Execution Contract Refusal 1) |
| [Place Under Retention] | the registry was read, then duration not positive or unresolved, delay negative or unresolved, or a deadline outside the instants the database holds | [Invalid Policy] | none (Operation 7, Operation 7a, Operation 8, Operation 8b, Operation 8c) |
| [Place Under Retention] | database refuses the write | [Storage Failure] | none (Operation 9) |
| [Purge] | no retention under that id | [Not Known] | none (Operation 14) |
| [Purge] | retention already purged | [Not Retained] | none (Operation 15) |
| [Purge] | retention period not elapsed | [Retention Period Not Elapsed] | none — the guard writes nothing (Operation 16, Operation 17) |
| [Purge] | eligible, database accepts | ok | [Retained] → [Purged], purge instant stamped (Operation 12, Operation 13) |
| [Purge] | eligible, past purge deadline | ok | the same — lateness is observable, never refused (Operation 18) |
| [Purge] | eligible, database refuses the write | [Storage Failure] | none — the retention stays [Retained] (Operation 19, Operation 20) |
| [Purge] | eligible, the storage layer does not confirm the destruction | [Storage Failure] | none — the retention stays [Retained] (Record divergence 2, Operation 20) |
| [Purge] | eligible, a composing pattern owns the destruction, database accepts | ok | [Retained] → [Purged]; the record stands until the pattern confirms the destruction (Record divergence 4, Record divergence 5) |
| *a retention crossing retention deadline* | — | *nothing* | nothing is written; eligibility is read (State 7, Operation 28) |
| [Read] | any call | every retention, with its stored fields and, while retained, purge eligible | none (Operation 29 through 32) |

Where two cases of one action hold at once, the refusal listed first on the action's refuses line answers (Execution Contract Refusal 1).

### Invariants

- **Invariant 1 — Membership exclusivity.**
  ```
  Invariant 1.1: EVERY retention MUST stand in EXACTLY ONE OF retained, purged.
  ```
- **Invariant 2 — Retain-then-Retained persistence.**
  ```
  Invariant 2.1: A recorded retention MUST stand in retained ONLY IF no successful [Purge] EXISTS for the retention.
  Invariant 2.2: A retention MUST stand in purged ONLY IF a successful [Purge] EXISTS for the retention.
  ```
- **Invariant 3 — Terminal absorption.**
  ```
  Invariant 3.1: A purged retention MUST NOT stand in retained again.
  Invariant 3.2: The atom MUST NOT offer an un-purge.
  ```
- **Invariant 4 — Id stability.**
  ```
  Invariant 4.1: [Place Under Retention] MUST set the retention id.
  Invariant 4.2: A retention id MUST NOT change.
  ```
- **Invariant 5 — Record_ref and policy reference immutability.**
  ```
  Invariant 5.1: A retention's record reference MUST NOT change.
  Invariant 5.2: A retention's policy reference MUST NOT change.
  Invariant 5.3: A retention's retention instant, retention deadline, purge deadline and purge instant MUST NOT change once set.
  ```
- **Invariant 6 — Retention window monotonicity.**
  ```
  Invariant 6.1: retention deadline MUST NOT PRECEDE retention instant.
  Invariant 6.2: purge deadline MUST NOT PRECEDE retention deadline.
  Deleted: Invariant 6.3. Operation 7 and Operation 7a own a duration that does not advance the deadline, and an invariant restating a precondition is a second owner.
  ```
- **Invariant 7 — No early purge.**
  ```
  Invariant 7.1: IF purge eligible EQUALS no THEN [Purge] MUST NOT stand the retention in purged.
  ```
- **Invariant 8 — Purge timestamp consistency.**
  ```
  Invariant 8.1: A purged retention's purge instant MUST NOT PRECEDE the retention's retention deadline.
  Deleted: Invariant 8.2. Execution Contract Logic confinement 7 owns it.
  Invariant 8.3: The atom MUST NOT bound purge instant by purge deadline.
  ```
- **Invariant 9 — No id reuse.**
  ```
  Invariant 9.1: Two retentions MUST NOT share a retention id.
  ```
- **Invariant 10 — Retention record durability.**
  ```
  Invariant 10.1: The atom MUST NOT delete a retention record.
  Invariant 10.2: The retention set MUST NOT shrink.
  Deleted: Invariant 10.3. Execution Contract Database 1 owns it.
  ```
- **Invariant 11 — Purge-eligibility is derived, never stored.**
  ```
  Invariant 11.1: A retention record MUST NOT carry an eligibility flag.
  Invariant 11.2: A reader MUST derive purge eligible from the retention's state, retention deadline and the injected now.
  Invariant 11.3: The atom MUST NOT write when a retention crosses retention deadline.
  ```

Membership exclusivity and terminal absorption give the *audit-friendly* property — once purged, the obligation is closed for good, with durable evidence that the purge was lawful. No early purge gives the *retention-honored* property. Timestamp consistency makes overshoot provable, as honest as the clock that stamped the records. Derived eligibility is what lets readiness be read without a scheduler and without a flag that drifts.

## Examples

The same atom, five regulated domains, identical mechanic.

### Banking — transaction-record retention under SOX

A bank places every settled transaction under retention with a 7-year policy (`policy_sox_settled_txn`: duration = 7 years, max purge delay = 30 days) via [Place Under Retention]. At the seven-year mark, the records' [Purge Eligible] projection flips to yes (derived from the injected clock, not written); the bank's records-management system lists those records and invokes [Purge] within the 30-day purge window. Each purge is logged for SOX (Sarbanes-Oxley Act — US financial reporting law) section 802 audit. An external auditor querying *"any transaction record purged before its 7-year obligation?"* gets the empty set — Invariant 7 guarantees it.

### Healthcare — medical-record retention under HIPAA and state law

A hospital places each patient encounter record under retention with the maximum of HIPAA's (US Health Insurance Portability and Accountability Act) federal 6-year baseline (45 CFR (Code of Federal Regulations) section 164.530(j)) and the state's longer requirement (often 10–25 years for adult records, longer for pediatric). The [Policy Reference] captures the applicable rule; the retention's [Retention Deadline] is the patient-specific deadline. Purges occur on a rolling schedule; the audit reads the retention records to demonstrate compliance with the longer of the applicable rules.

### Payments — cardholder-data retention under PCI DSS

A payment processor places cardholder-data records (PAN — Primary Account Number, the card number; expiration; CVV-substitute tokens — stand-ins for the CVV (card verification value), the card security code) under retention with the *shortest* viable policy — typically days for transient transaction data, never longer than business need requires. PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for handling cardholder data) Requirement 3.1 mandates data minimization. The atom's no-early-purge invariant becomes less relevant here (windows are short); the [Active Overdue] metric is what the audit primarily surfaces — any cardholder data still [Retained] past [Purge Deadline].

### Communications — broker-dealer communications under SEC Rule 17a-4

A registered broker-dealer places every business communication (email, chat, voice transcript) under retention with policies derived from SEC (US Securities and Exchange Commission — the federal securities regulator) Rule 17a-4 — generally 3 years, with the first 2 years in immediately-accessible storage. The atom carries the retention obligation; storage-tier transitions (immediately-accessible to less-accessible) belong to a Storage Tier composition. A FINRA (Financial Industry Regulatory Authority) examination reads the retention records to confirm that every required communication was retained for the full period and purged only after.

### Legal — contract retention beyond contract term

A company places each executed contract under retention with policy = max(contract duration + 6 years, statute-of-limitations for relevant claim types). The retention extends past the operational life of the contract because the contract's audit obligations outlive its commercial life. Litigation hold composes by blocking the purge during pending litigation (Defensible Retention's gate over Legal Hold; out of scope for the atom).

NOTE: open 2026-10-03-i — the Summary's *blocks early deletion outright* holds per retention and not per record, the Healthcare and Legal examples use periods that depend on the record's content, and the litigation discovery scenario reads a record's existence from a retained retention.

### Rejection paths

**Premature purge attempt.** A records-management system attempts to purge the retention over a transaction record four years into a seven-year SOX retention period:

```
purge(retention_id: "ret-0047")          # seam injects now = 2026-06-22T00:00:00Z
→ retention-period-not-elapsed
```

The pure eligibility guard evaluates [Now] ≥ [Retention Deadline] against the seam-injected [Now] and finds it false — [Retention Deadline] has not been reached; the atom rejects the purge outright and **writes nothing**. No state change occurs and nothing is destroyed; the retention remains in [Retained], and its [Purge Eligible] projection reads no. The rejection is the structural enforcement of Invariant 7 — early purge against the injected clock is not an outcome the atom has.

**Policy reference not resolvable.** A host system calls [Place Under Retention] with a policy reference that does not resolve to a known policy:

```
place_under_retention(record_ref: "txn-1188", policy_ref: "policy-obsolete-v1")
→ policy-not-found
```

No retention is created. The host system must supply a valid, resolvable policy reference before any retention can be placed.

### Regulated adversarial scenarios

Four scenarios the atom must survive in regulated contexts:

- **Regulator audit — "show me every record purged before its retention period elapsed."** The auditor queries the [Purged] set for any record where [Purge Instant] < [Retention Deadline]. Invariant 7 makes this set structurally empty — the precondition on [Purge] prevents it. The auditor sees the empty result as a structural guarantee, not a procedural promise.
- **Data minimization audit — "show me every record still Retained past its purge deadline."** Common under GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Article 5(1)(e) reviews. The auditor reads [Retained] with the injected [Now] and selects records where [Now] > [Purge Deadline] (the [Active Overdue] projection; these are necessarily [Purge Eligible] too, since [Purge Deadline] ≥ [Retention Deadline]). The atom does not refuse late purges (rejecting them would compound the [Overshoot]), so this query returns a non-empty set when the organization is behind on its purge schedule. The overdue set is the finding; the records themselves are the evidence; the remediation is to [Purge] the listed records and document the lateness.
- **Litigation discovery — "produce all records of type X from 2020-2022."** Counsel queries the host system; the host system reads the retention records to determine which matching records still exist ([Retained]) versus which have been [Purged]. A [Purged] retention never returns to [Retained] — that is the atom's terminal-absorption invariant working as designed — and the record it named is gone once the destruction is confirmed; where a composing pattern owns the destruction, a standing record is not yet destroyed and is produced (Term standing record). The discovery response distinguishes *records retained and produced* from *records lawfully destroyed under the policy in effect at the time*, with the retention records themselves as the audit trail. Litigation hold should have been placed earlier — if it wasn't, that is a Legal Hold composition failure, not a retention failure.
- **Incident investigation — "the deployment's clock ran ahead for six hours; what was destroyed that should not have been?"** The investigator reads every [Purged] retention whose [Purge Instant] falls in the incident window and recomputes eligibility from [Retention Deadline] against a trusted clock. A purge whose stamped instant meets its deadline only because the injected clock ran fast is in that set, and the records hand it over: the retention, its policy, its deadline and its stamped instant all still stand (Invariant 10), so the finding is a list of early destructions with the evidence for each. The atom could not have prevented them — the clock's honesty is the deployment's (Execution Contract Logic confinement 7) — and it does not hide them.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the retention record set.

### Conformance checks

```
Check 1.1: An auditor MUST read the policy applied to a record from the retention's policy reference (State 2).
Check 2.1: An auditor MUST find the set of purged retentions whose purge instant PRECEDES retention deadline empty (Invariant 7.1, Invariant 8.1).
Check 3.1: An auditor MUST confirm that no retention record carries an eligibility flag (Invariant 11.1).
Check 3.2: An auditor MUST derive purge eligible from the retention state, retention deadline and the auditor's own clock (Invariant 11.2, Operation 28).
Check 4.1: An auditor MUST compute a purged retention's overshoot from purge instant and purge deadline (Invariant 8.3).
Check 4.2: An auditor MUST compute a retained retention's active overdue from purge deadline and the auditor's own clock (State 2).
Check 5.1: An auditor MUST reconstruct a record's policy history from the retentions sharing the record reference (Identity 9).
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
```

NOTE: watch the comparator written in English (Check 2.1).

### External checks

```
External check 1: An auditor MUST confirm from the deployment's own destruction records that no retained retention over a destroyed record carried purge eligible EQUALS no at the destruction (Simultaneous retention 4).
External check 2: An auditor MUST read the composing pattern's joint-enforcement mechanism (Simultaneous retention 3, Simultaneous retention 5).
External check 3: An auditor MUST read the deployment's declared time resolution (Capability requirement 5, State 6a).
External check 4: An auditor MUST read EVERY standing record from the owning pattern's confirmations (Record divergence 5).
External check 5: An auditor MUST confirm from the deployment's own destruction records that no destruction instant PRECEDES the retention deadline of a retention in place at the destruction (Capability requirement 6, Capability requirement 6a, Capability requirement 7, Simultaneous retention 4).
Deleted: External check 6. Execution Contract Conformance 9 owns it.
```

NOTE: open 2026-10-03-g — the checks cover Invariant 7, Invariant 8 and Invariant 11 alone, and External check 5 subsumes External check 1.

Term retention in place at the destruction: a retention over a destroyed record where the destruction instant, rounded up to the time resolution as State 4a rounds a retention instant, DOES NOT PRECEDE the retention's retention instant; every retention placed before the destruction is one, and so is a retention placed after the destruction whose retention instant rounds up to the same multiple of the time resolution, since the records cannot order the two.

NOTE: the atom cannot answer these from the retention records — Simultaneous retention 3 keeps [Purge] from reading a sibling, so the evidence that joint enforcement happened lives in the composing pattern's records, not here (council read 11).

NOTE: EVERY check names the rule the check tests. The bar is the regulator's question — *was every record's obligation honored, and what is overdue now?* — answered provably.

## Non-goals

```
Non-goal 1: The atom MUST NOT hold a record's storage tier.
Non-goal 2: The atom MUST NOT suspend a purge under a legal hold.
Non-goal 3: A deployment under litigation MUST compose a legal-hold pattern.
Non-goal 4: The atom MUST NOT choose the destruction technique.
Non-goal 5: The atom MUST NOT permit an early purge under an erasure request.
Non-goal 6: A deployment facing an erasure request MUST compose an erasure pattern.
Non-goal 7: The atom MUST NOT define a policy.
Non-goal 8: The atom MUST NOT version a policy.
Non-goal 9: The atom MUST NOT place the atom's own records under retention.
Non-goal 10: The atom MUST NOT record who authorized a purge.
Non-goal 11: A deployment needing an attributable purge MUST compose Actor Identity.
Non-goal 12: The atom MUST NOT purge two retentions as one write.
Non-goal 13: A deployment whose deadlines carry legal force MUST compose a trusted timestamping pattern.
Non-goal 14: The atom MUST NOT hold an idempotence key for a placement.
Non-goal 15: A deployment needing an at-most-once placement MUST compose Duplicate Prevention.
Non-goal 16: The atom MUST NOT bound the age of a standing record.
```

NOTE: the owners — a Storage Tier pattern *(forthcoming)* (Non-goal 1); [Legal Hold](./legal-hold.md) and [Defensible Retention](../compositions/defensible-retention.md) (Non-goal 2, Non-goal 3); Shred *(forthcoming)* (Non-goal 4); Erasure Coordination *(forthcoming)* (Non-goal 5, Non-goal 6); a Policy Registry *(forthcoming)* (Non-goal 7, Non-goal 8); [Actor Identity](./actor-identity.md) (Non-goal 10, Non-goal 11); the composing pattern that owns joint enforcement (Non-goal 12, Simultaneous retention 5); Trusted Timestamping *(forthcoming)* (Non-goal 13); [Duplicate Prevention](./duplicate-prevention.md) (Non-goal 14, Non-goal 15); the composing pattern that owns the destruction (Non-goal 16, Record divergence 6).

Where the atom breaks down: when the obligation is a function of the record's content — records about a minor retained until majority, which needs a policy lookup against the record itself; when the storage layer cannot make a record irrecoverable after a purge — append-only logs, distributed replicas, backups with their own schedules; when the regulatory clock and the deployment's clock are far apart, which breaks every wall-time deadline at once.

## Edge cases

### Clock semantics

```
Clock semantics 3: Two readers judging purge eligible under skewed clocks MAY disagree near retention deadline.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Non-goal 13 owns it.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Purge persistence

```
Purge persistence 1: A caller MUST read storage-failure from [Purge] as the retention standing in retained.
Purge persistence 1a: A caller MUST NOT read storage-failure from [Purge] as the record standing undestroyed.
Purge persistence 2: IF Simultaneous retention 4a does not forbid the purge THEN a caller MUST retry a purge that answered storage-failure.
Purge persistence 2a: IF Simultaneous retention 4a does not forbid the purge THEN a caller MUST retry a purge that returned no answer.
Purge persistence 3: A high-assurance deployment MUST alert on storage-failure from [Purge].
```

NOTE: open 2026-10-03-d — the retry is excused by Simultaneous retention 4a alone (Purge persistence 2, Purge persistence 2a), and a composing pattern's own gate placed after a storage-failure is not excepted, as Term withheld record excepts it.

### Record divergence

```
Record divergence 1: IF no composing pattern owns the destruction THEN [Purge] MUST NOT stand the retention in purged BEFORE the storage layer confirms the destruction.
Record divergence 1a: The host MUST destroy a record through the storage layer ONLY IF [Purge] judged the purging retention purge eligible.
Record divergence 2: IF no composing pattern owns the destruction AND the storage layer cannot confirm the destruction THEN [Purge] MUST answer storage-failure.
Record divergence 2a: The storage layer MUST confirm the destruction of EVERY record of which the storage layer holds no copy.
Deleted: Record divergence 2b. Capability requirement 4a owns it: a storage layer cannot know whether a confirmation reaches [Purge] before [Purge] answers, and no destruction lands once [Purge] has answered.
Record divergence 3: The atom MUST NOT read the record's existence.
Record divergence 4: A composing pattern MAY own the destruction ONLY IF the composing pattern declares the ownership as a capability requirement over the instance the composing pattern wires.
Record divergence 4a: A composing pattern that owns the destruction MUST destroy a record ONLY IF the record is a standing record.
Record divergence 5: A composing pattern that owns the destruction MUST retain the confirmation of EVERY destruction, by record reference, for the life of the instance.
Record divergence 6: A composing pattern that owns the destruction MUST retry the destruction of EVERY standing record that is not a withheld record.
```

NOTE: open 2026-10-03-a — where the instance destroys (Record divergence 1, Record divergence 1a), the destruction is an external effect between the guard and the write, and the Execution Contract's pipeline has no step for it.

NOTE: open 2026-10-03-e — the destruction's lifecycle (standing, withheld, confirmed) has no owning atom (Record divergence 4a through 6), and the confirmation and the destruction instant are one fact with two owners (Record divergence 5, Capability requirement 7).

Term storage layer: the deployment-supplied component through which the host destroys a record, and which confirms the destruction, where no composing pattern owns the destruction (Capability requirement 4). A confirmation is the storage layer's answer received by the [Purge] that made the request before that [Purge] answers; an answer arriving later confirms nothing.

Term owns the destruction: said of one [Retention Window] instance — a composing pattern owns the destruction of the records that instance's retentions name, and of no other instance's; a rule conditioned on it reads the instance the call is made on. The ownership is set before the instance's first placement and does not change for the life of the instance.

Term standing record: the record a purged retention names, where a composing pattern owns the destruction and has recorded no confirmation of the destruction.

Term withheld record: a standing record whose destruction a rule forbids for as long as the rule forbids it — Simultaneous retention 4, or a gate of the composing pattern's own, a legal hold among them.

### Simultaneous retention

```
Simultaneous retention 1: The atom MUST admit two live retentions over one record reference.
Simultaneous retention 1a: A caller that retries a placement whose answer was lost MUST read the record as carrying two retentions.
Simultaneous retention 2: The atom MUST gate a purge against the purging retention's own retention deadline.
Simultaneous retention 3: [Purge] MUST NOT read a sibling retention over one record reference.
Simultaneous retention 4: IF a retained retention over the record EXISTS whose purge eligible EQUALS no THEN a composing pattern MUST NOT destroy the record.
Simultaneous retention 4a: IF no composing pattern owns the destruction AND a retained retention over the record EXISTS whose purge eligible EQUALS no THEN a composing pattern MUST NOT purge a retention over the record.
Simultaneous retention 5: A deployment that places two retentions over one record MUST compose a pattern that owns joint enforcement.
Simultaneous retention 6: The pattern that owns joint enforcement MUST serialize a placement, the sibling read, a purge and a destruction over one record reference.
Simultaneous retention 6a: IF a composing pattern owns the destruction THEN that pattern MUST own joint enforcement.
Simultaneous retention 7: A deployment that places two retentions over one record MUST place through the pattern that owns joint enforcement alone.
Simultaneous retention 8: A deployment that places two retentions over one record MUST purge through the pattern that owns joint enforcement alone.
```

Term sibling retention: another retention over the same record reference.

Term joint enforcement: the rule over every retention on one record that Simultaneous retention 4 and Simultaneous retention 4a state; a composing pattern's.

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern over a regulated Event Log instance MUST place an appended event under retention.
Deleted: Composition note 3. Simultaneous retention 5 and Simultaneous retention 6a own it: a deployment that places two retentions over one record composes the pattern that owns joint enforcement, and a pattern that owns the destruction owns joint enforcement.
Composition note 4: A composing pattern MUST own the policy the pattern places a record under.
Composition note 5: This atom's invariant numbers MUST stand as a frozen contract surface.
```

NOTE: composing patterns — [Defensible Retention](../compositions/defensible-retention.md), [Audit Trail](../compositions/audit-trail.md). Forthcoming: Storage Tier, Shred, Erasure Coordination, Policy Registry, Trusted Timestamping.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the deployment (also: a high-assurance deployment); a composing pattern (also: a pattern, a writer); a business caller; a caller; a reader; an auditor; the policy registry; the database; the retention records; the storage layer; a retention; a record; a policy; a purge.

Term records: retention — one obligation, carrying retention id, record reference, policy reference, retention instant, retention deadline, purge deadline, a retention state and, once purged, purge instant.

Term record verbs: identify, allocate, supply, reuse, compare, round, carry, stand, set, store, offer, hold, record, answer, read, resolve, stamp, judge, leave, refuse, write, derive, change, delete, shrink, share, admit, gate, destroy, retry, alert, coordinate, confirm, serialize, own, disagree, compose, place, define, version, retain, permit, purge, choose, suspend, renumber, add, find, compute, reconstruct, declare, precede, bound, evaluate.

Term value sets: retention state = retained | purged. purge eligible = yes | no.

Term bounds: duration (the policy's retention period); max purge delay (the lag the policy allows); retention deadline; purge deadline.

Term cadences: empty — a purge cadence is the composing pattern's.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: zero duration, degenerate duration, now, retention, retention id, record reference, policy reference, seam, transition, business caller, retention state, retention instant, retention deadline, purge deadline, purge instant, overshoot, active overdue, duration, max purge delay, purge eligible, time resolution, well-formedness check, storage layer, owns the destruction, standing record, withheld record, sibling retention, joint enforcement, retention in place at the destruction.

#### Retention Window

The compliance primitive this atom defines: a record is kept under retention for a known period, then becomes eligible for purge. Each retention is its own record with an opaque [Retention Id]; it carries a [Record Reference], [Policy Reference], the derived deadlines [Retention Deadline] and [Purge Deadline], and (once purged) [Purge Instant]. It occupies one of two states — [Retained] or [Purged].

Kind: Type

#### Place Under Retention

The behavior the host invokes to record a new retention over a [Record Reference] under a [Policy Reference]. The host resolves the policy at the seam (Operation 24); the action stamps [Retention Instant] from the injected [Now], computes [Retention Deadline] and [Purge Deadline] from the injected [Duration] and [Max Purge Delay], records the retention in [Retained], and returns the fresh [Retention Id].

Kind: Operation

#### Purge

The behavior the host invokes to transition a retention to [Purged], destroying the underlying record — or, where a composing pattern owns the destruction (Record divergence 4), ending the obligation and leaving the destruction to that pattern. It is permitted only once the retention period has elapsed (the pure [Now] ≥ [Retention Deadline] guard, which writes nothing when it fails); on success it stamps [Purge Instant] from the same injected [Now]. It does not refuse late purges — the lateness is observed as [Overshoot], not rejected.

Kind: Operation

#### Read

The read-only query answering every retention the database holds, [Retained] and [Purged], each with its stored fields and, while [Retained], the [Purge Eligible] projection derived against the injected [Now]. It changes nothing.

Kind: Operation

#### Retention Id

The opaque, immutable identity of a retention, host-allocated at the I/O seam on [Place Under Retention] and never reused. The [Record Reference], [Policy Reference], and the derived deadlines are properties of the retention, not its identity.

Kind:       Field
Field of:   Retention Window
Projection: retention_id

#### Record Reference

The opaque reference to *what* is being retained — the record the retention covers. The atom does not interpret it; the host defines what counts as a record and how to reference it. Set on [Place Under Retention], immutable thereafter.

Kind:       Field
Field of:   Retention Window
Projection: record_ref

#### Policy Reference

The opaque reference to *which* retention rules apply. The policy registry is a separate concept; the atom requires only that the policy expose a [Duration] and a [Max Purge Delay]. Set on [Place Under Retention], immutable thereafter.

Kind:       Field
Field of:   Retention Window
Projection: policy_ref

#### Retention Instant

The wall-time the retention was placed under retention, stamped from the injected [Now] on [Place Under Retention]. Immutable thereafter. It is the anchor from which [Retention Deadline] is derived.

Kind:       Field
Field of:   Retention Window
Projection: retained_at

#### Retention Deadline

The earliest time purge is permitted — the end of the retention period, derived once as [Retention Instant] + [Duration], rounded up to the time resolution, on [Place Under Retention] and immutable thereafter. The [Purge] guard admits a purge only while [Now] ≥ [Retention Deadline].

Kind:       Field
Field of:   Retention Window
Projection: retention_until

#### Purge Deadline

The latest time the regulator expects purge to occur, derived once as [Retention Deadline] + [Max Purge Delay], rounded up to the time resolution, on [Place Under Retention] and immutable thereafter. Operating past it is observable [Overshoot]; the atom observes this bound but does not enforce it.

Kind:       Field
Field of:   Retention Window
Projection: purge_deadline

#### Purge Instant

The wall-time the retention was purged, stamped from the injected [Now] on [Purge]. Present only in [Purged]. Its relation to [Purge Deadline] is what makes [Overshoot] provable.

Kind:       Field
Field of:   Retention Window
Projection: purged_at

#### Purge Eligible

The derived read-surface projection that reads yes exactly when a retention is still [Retained] *and* its period has elapsed — `state = Retained ∧ [Now] ≥ [Retention Deadline]`. It is a pure function of the stored record and the injected [Now], computed at read time and **never stored** (Invariant 11). It is the same predicate the [Purge] guard evaluates.

Kind:       Field
Field of:   Retention Window
Projection: purge_eligible

#### Overshoot

The derived metric, for a [Purged] retention, of [Purge Instant] − [Purge Deadline] when positive — the amount by which purge ran late. Provable; surfaced to compliance dashboards but never stored. It is the data-minimization finding the audit reads from the record itself.

Kind:       Field
Field of:   Retention Window
Projection: overshoot

#### Active Overdue

The derived metric, for a still-[Retained] retention, of [Now] − [Purge Deadline] when positive — a record overdue for purge that has not yet been purged. Computable from the record and the injected [Now] alone; surfaced as a derived view, never stored.

Kind:       Field
Field of:   Retention Window
Projection: active_overdue

#### Now

The current wall-clock reading, pipeline-injected at the single I/O seam (the execution contract supplies `clock_t` there) before a transition runs — never a caller-supplied action parameter. It is consumed to stamp [Retention Instant] / [Purge Instant] on a write and to evaluate the pure [Purge] eligibility guard, and it drives the read-time [Purge Eligible] projection; it is never stored under this name.

Kind:         Parameter
Parameter of: Place Under Retention, Purge and Read
Projection:   now

#### Duration

The retention period the policy exposes — the injected scalar from which [Retention Deadline] is computed. The atom requires it to be positive and resolved to an elapsed length (Operation 7, Operation 7a). It is resolved from the [Policy Reference] at the seam and consumed by [Place Under Retention]; it is never stored under this name (the stored result is [Retention Deadline]).

Kind:         Parameter
Parameter of: Place Under Retention
Projection:   duration

#### Max Purge Delay

The maximum allowed lag between retention-end and purge the policy exposes — the injected scalar from which [Purge Deadline] is computed. The atom requires it to be non-negative (Operation 8). It is resolved from the [Policy Reference] at the seam and consumed by [Place Under Retention]; it is never stored under this name (the stored result is [Purge Deadline]).

Kind:         Parameter
Parameter of: Place Under Retention
Projection:   max_purge_delay

#### Retained

The state of a retention under active retention obligation — placed but not yet purged. A retention enters [Retained] on [Place Under Retention] and leaves it only on [Purge] (to [Purged]). Its retention period may or may not have elapsed.

Kind:      Member
Member of: the retention state
Role:      Outcome

#### Purged

The terminal state of a retention whose underlying record has been destroyed, or whose destruction a composing pattern owns, the record standing until that pattern records the confirmation (Record divergence 5, Term standing record). A retention enters [Purged] on a successful [Purge] and never leaves it — there is no un-purge or restore surface (Invariant 3). The [Purged] record is the audit evidence that the obligation ended lawfully.

Kind:      Member
Member of: the retention state
Role:      Outcome

#### Invalid Request

The refusal [Place Under Retention] returns when [Record Reference] or [Policy Reference] is blank. A guard rejection that fails before any database write; no retention is recorded.

Kind:       Member
Member of:  the Place Under Retention rejection
Role:       Outcome
Projection: invalid-request

#### Policy Not Found

The refusal [Place Under Retention] returns when [Policy Reference] does not resolve to a known policy in the policy registry. Distinct from [Invalid Policy] (a policy that resolves but is invalid). A guard rejection; no retention is recorded.

Kind:       Member
Member of:  the Place Under Retention rejection
Role:       Outcome
Projection: policy-not-found

#### Invalid Policy

The refusal [Place Under Retention] returns when the resolved policy is invalid — its [Duration] is not positive or could not be resolved, its [Max Purge Delay] is negative or could not be resolved, or a deadline it would set falls outside the instants the database holds. Distinct from [Policy Not Found] (the policy could not be resolved at all). A guard rejection; no retention is recorded.

Kind:       Member
Member of:  the Place Under Retention rejection
Role:       Outcome
Projection: invalid-policy

#### Registry Unavailable

The refusal [Place Under Retention] returns when the host cannot read the policy registry at the placement (Operation 24b). Distinct from [Policy Not Found] (the registry was read and holds no policy under the reference): the condition is transient, and the placement may be retried. A guard rejection; no retention is recorded.

Kind:       Member
Member of:  the Place Under Retention rejection
Role:       Outcome
Projection: registry-unavailable

#### Not Retained

The refusal [Purge] returns when the [Retention Id] references a retention not currently in [Retained] — it is already [Purged]. An identity/state rejection, checked before the time gate.

Kind:       Member
Member of:  the Purge rejection
Role:       Outcome
Projection: not-retained

#### Not Known

The refusal [Purge] returns when the supplied [Retention Id] references no recorded retention — a lookup miss. An identity/state rejection, checked before the time gate.

Kind:       Member
Member of:  the Purge rejection
Role:       Outcome
Projection: not-known

#### Retention Period Not Elapsed

The refusal [Purge] returns when the eligibility guard finds [Now] < [Retention Deadline] — the retention period has not yet elapsed. The pure no-early-purge gate (Invariant 7); it writes nothing when it fails.

Kind:       Member
Member of:  the Purge rejection
Role:       Outcome
Projection: retention-period-not-elapsed

#### Storage Failure

The refusal either [Place Under Retention] or [Purge] returns when the database write fails after all preconditions pass, and the refusal [Purge] returns when the storage layer does not confirm the destruction (Record divergence 2). For [Purge] the retention remains in [Retained] — the record may or may not be gone, and a retry settles it only where the retry's write can commit. The caller must treat it as definitive; a purge is retried (Purge persistence 2).

Kind:       Member
Member of:  the Place Under Retention / Purge rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Retention Window]: #retention-window
[Place Under Retention]: #place-under-retention
[Purge]: #purge
[Read]: #read
[Retention Id]: #retention-id
[Record Reference]: #record-reference
[Policy Reference]: #policy-reference
[Retention Instant]: #retention-instant
[Retention Deadline]: #retention-deadline
[Purge Deadline]: #purge-deadline
[Purge Instant]: #purge-instant
[Purge Eligible]: #purge-eligible
[Overshoot]: #overshoot
[Active Overdue]: #active-overdue
[Now]: #now
[Duration]: #duration
[Max Purge Delay]: #max-purge-delay
[Retained]: #retained
[Purged]: #purged
[Invalid Request]: #invalid-request
[Policy Not Found]: #policy-not-found
[Invalid Policy]: #invalid-policy
[Registry Unavailable]: #registry-unavailable
[Not Retained]: #not-retained
[Not Known]: #not-known
[Retention Period Not Elapsed]: #retention-period-not-elapsed
[Storage Failure]: #storage-failure

---

## Standards references

Retention Window is one of the most heavily standardized concepts in compliance; its standards inheritance is correspondingly rich:

- **ISO 15489-1 (Information and documentation — Records management)** — the International Organization for Standardization's standard for records-management practice. Defines retention as a managed lifecycle with policy-governed start, retention period, and disposition. The atom's two-state model is the operational core of ISO 15489's lifecycle framing.
- **GDPR Article 5(1)(e) — Storage limitation principle** — personal data must be kept *no longer than necessary*. The atom's [Overshoot] metric is the operational form of GDPR's data-minimization audit; persisting personal data past [Purge Deadline] is a violation surfaced by the record itself.
- **HIPAA section 164.530(j) — Documentation retention** — 6-year federal baseline for required HIPAA documentation; state law commonly extends this for clinical records. The atom's [Policy Reference] carries the applicable rule; the host system reconciles federal-state-policy overlap.
- **Sarbanes-Oxley section 802 — Retention of records relevant to audits and reviews** — 7-year retention for audit workpapers, with criminal penalties for early destruction. The atom's no-early-purge invariant is the structural fix for SOX section 802's ban on early destruction.
- **SEC Rule 17a-4 — Records to be preserved by certain exchange members, brokers, and dealers** — 3-to-7-year retention with specific access-tier requirements (first two years immediately accessible). Storage-tier sub-requirements compose with Storage Tier; the retention obligation itself is this atom.
- **FINRA Rule 4511 — General requirements for books and records** — incorporates SEC retention rules for FINRA-registered entities.
- **21 CFR Part 11 — FDA (US Food and Drug Administration) electronic records and electronic signatures** — records covered by Part 11 are retained for the longer of the predicate-rule period or 7 years; destruction must be authorized and audited. Composes with Actor Identity for the destruction-authorization attestation.
- **DoD (US Department of Defense) 5015.02-STD — Design criteria standard for electronic records management software applications** — the U.S. government's records-management software baseline. The atom's separation of retention obligation from storage tier and from disposition mechanism matches DoD 5015's architecture.
- **PCI DSS Requirement 3 — Protect stored cardholder data** — including 3.1 (data retention and disposal). The atom carries the *as briefly as possible* posture by allowing very short policy durations.
- **IRS (US Internal Revenue Service — the federal tax authority) retention guidelines (Publication 583, etc.)** — generally 3-year retention for tax records, longer for specific circumstances (assessments, fraud, employment tax). [Policy Reference] encodes the rule.
- **NARA (US National Archives and Records Administration) General Records Schedules (U.S. federal)** — government-wide retention schedules; the policy registry the atom composes with would normally derive from NARA for federal-agency deployments.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of composing storage tier, legal hold, shred, and policy registry as separate concepts.
- **Eiffel's design-by-contract** — preconditions on [Purge]; named rejection reasons.
- **Linear temporal logic** — retain-then-Retained persistence, terminal absorption, and the no-early-purge precondition expressed as temporal properties.
- **Records management literature** — Ranganathan's principles applied to organizational records; Schellenberg's appraisal theory of which records merit which retention.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: not applicable — vote no 2026-06-03
last gate: 2026-10-22 — Final Critique 11, the council's fourth round on the page and the first on its text since Final Critique 10's settle (c5e3290), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS Beam, Linus GLM-5.3 Flash), each handed only the round's reading set, three passes on one text (frozen at de6bc76); the round rests on three counted passes — foundational count 0 after the settle's triage (23 reports: 21 sent down onto twelve of the page's fourteen flagged open lines; 2 rejected); 17 refining reports, 6 rhetorical reports; not recorded clean: a count that decides a clean round is triaged a second time, blind to the threshold, and that triage has not run (escalated 2026-10-22); every refining finding cured, routed or answered; 2026-10-22 — Final Critique 10, the council's third round on the page — foundational count 1, cured, not clean; 2026-10-22 — Final Critique 9, the council's second round on the page — foundational count 1, cured, not clean; 2026-10-20 — Final Critique 8, the council's first round on the page — foundational count 7, all cured, not clean; 2026-10-03 — Final Critique 7, fresh reader, three passes — 0 foundational, 51 refining reports, 16 rhetorical reports

open:
- 2026-10-03-a · refining · Record divergence 1, 1a; Operation 24c · where the instance destroys, the destruction is an external effect between the guard and the write, and the Execution Contract's pipeline has no step for it → name the step or declare the deviation
- 2026-10-03-b · refining · Capability requirement; Operation 24, 24a; Term owns the destruction; Simultaneous retention 5; Purge persistence 3 · the policy registry and its resolved lengths, the ownership setting and the alert are the deployment's and sit outside the capability list → list them
- 2026-10-03-d · refining · Purge persistence 2, 2a; Term withheld record · the retry is excused by Simultaneous retention 4a alone, and a composing pattern's own gate placed after a storage-failure is not excepted → except what Term withheld record excepts
- 2026-10-03-e · refining · Record divergence 4a through 6; Capability requirement 7 · the destruction's lifecycle (standing, withheld, confirmed) has no owning atom, and the confirmation and the destruction instant are one fact with two owners → Erasure Tombstone, when it lands
- 2026-10-03-f · refining · State 1, 7, 8; Operation 28; Invariant 1.1, 3.2, 11.1, 11.2 · four propositions have two owners each, against the ground Invariant 6.3 was tombstoned on → tombstone the second owner
- 2026-10-03-g · refining · Conformance checks; External check 1, 5 · the checks cover Invariants 7, 8 and 11 alone, and External check 5 subsumes External check 1 → one check, a check per invariant
- 2026-10-03-i · refining · Summary; Examples; Standards references · "blocks early deletion outright" holds per retention and not per record, the Healthcare and Legal examples use periods that depend on the record's content, and the discovery scenario reads a record's existence from a retained retention → state each at the level the rules hold
- 2026-10-03-j · refining · Term seam, transition, business caller · each cites a section of the Execution Contract that does not use the term → corpus-wide; the contract's vocabulary, not this atom's
- 2026-10-03-k · refining · Identity 5, 10; Invariant 9.1; Capability requirement 8, 9 · non-reuse has two owners and a colliding id has no refusal arm, and no action performs the comparison Identity 10 obliges → one owner; an arm or a named non-goal
- 2026-10-03-l · refining · Operation 24a; Identity 6; [Read] · the day a calendar period counts from is in a WHY, a reference is checked for blank alone, and [Read] has no order or bound → pin each or name the owner
- 2026-10-05-a · refining · Operation 29; [Read] · the read answers every retention of the instance with no key, so a composing pattern's read by retention id or by record is a whole-database enumeration under its lease, and no answer on a read is left to the composer → a keyed read; an arm; reported by Defensible Retention's and Resolve a Person's Data Rights' gates
- 2026-10-20-a · refining · Term seam; Operation 6, 8b, 8c, 24b; Term degenerate duration · the rules answer on the registry's reply, on a max purge delay the host could not resolve and on the instants the database holds, which the transition may not read (Operation 26) and the seam does not list among the values the host injects, and an unresolved delay has no term as an unresolved duration does → list each injected value; a term for the delay
- 2026-10-20-b · refining · Record divergence; Simultaneous retention; Purge persistence 1a; Capability requirement 4 through 7 · destruction, the confirmation an owning pattern records, undestroyed and abandoned carry rules and are declared nowhere, Term storage layer declaring only the storage layer's confirmation; Capability requirement 4a bars a destruction once its [Purge] has been abandoned, and nothing says when a [Purge] that never answers is → declare each, and when a request dies
- 2026-10-20-d · refining · Operation 8c, 19, 20; Storage Failure · Operation 8c holds a placement's deadlines inside the instants the database holds and nothing holds the purge instant there, so a purge past them destroys the record and then cannot write, and no retry settles it → bound the purge instant or name the arm
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/retention-window.md`; the rounds and the migration that got it here are in [its history](./retention-window.hist.md).

- **2026-10-03 — A composing pattern may own the destruction, and where none does the destruction is confirmed before the retention reads purged.** *Chose:* destruction ownership per instance, declared by the pattern as a capability requirement and fixed for the instance's life; an owner that destroys only what a purged retention names, records each confirmation and retries every standing record nothing withholds (Record divergence 4 through 6, Term standing record, Term withheld record, External check 4); and, where the instance destroys, the storage layer confirming before the write, a dead request once the purge has answered, and one path by which a record is destroyed, its instant recorded (Record divergence 1 through 2b, Capability requirement 4 through 7, External check 5). *Over:* the three rules that bound every instance to coordinate and confirm a destruction and gave neither an order nor a failure reading; and over making every purge the transition alone, which would have rewritten what purge means for Defensible Retention. *Because:* Audit Trail's cascade must write its destruction record after the transition and cannot have purge wait on a mechanism purge has no view of (its Capability requirement 9, Ledger line 2026-10-03-a there), and a fresh reader of the first round found the unordered rule admitted a retention reading purged over a standing record with nobody retrying. Compositions affected: Audit Trail takes the ownership; Defensible Retention keeps a purge that destroys.

- **2026-10-03 — Joint enforcement is one pattern's, on the purge call where purge destroys and on the destruction where a pattern owns it.** *Chose:* a destruction forbidden while a retained sibling is not yet eligible, a purge forbidden under the same condition where purge destroys, a deployment with two retentions over one record obliged to compose the pattern and to place and purge through it, the pattern serializing placement, sibling read, purge and destruction per record reference, one record's retentions in one instance, and a retried placement read as a second retention (Simultaneous retention 1a, 4, 4a, 5, 6, 6a, Capability requirement 10, 11, Non-goal 14, 15). *Over:* a rule that let a record be destroyed only if every retention over it was purge eligible, which a purged retention can never be. *Because:* three passes each reached a record destroyed under a live sibling by a different route — a bare deployment, a placement racing the sibling read, a second instance. Compositions affected: Defensible Retention serializes holds against the purge and not placements (its Ledger line 2026-10-03-a).

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the retention store supplied under Execution Contract Store 1 through 4 (Capability requirement 12), and the five rules that restated them tombstoned to their owner — Operation 10 and Invariant 10.3, no partial retention, to Store 1; Concurrency 1, every state transition atomic per retention id, to Store 1 and Store 2; Concurrency 2 and 3, two purges of one retention serialized and the second answering on what the first committed, to Store 2; rules 158 to 154. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The destruction, its confirmation, a caller's retry and the serialization over one record reference stay as they were (Record divergence, Purge persistence, Simultaneous retention 6): each reaches past one action's write to the retention store. What the atom does for its domain is unchanged.

- **2026-10-20 — A failed read answers on every action, each writing action's refusals answer in one stated order, and a late confirmation breaks no rule.** *Chose:* state-unavailable on all three actions where the read of the retention store fails, the Execution Contract's Step 1 failure (Operation 34, Term store read), [Read] refusing nothing else and answering every retention only on an answered read (Operation 29, Operation 33); an unreadable policy registry answered by its own refusal, registry-unavailable, on [Place Under Retention]'s refuses line (Operation 24b, Operation 24c), and invalid-policy answered only on a registry the host read (Operation 8a); one stated order over the refusals of [Place Under Retention] and of [Purge], the store read first (Operation 35, Operation 36, Term placement refusal order, Term purge refusal order); Record divergence 2b deleted to Capability requirement 4a; the deployment retaining each destruction's recorded instant, not the destroyed record (Capability requirement 7); the auditor deriving purge eligible on the auditor's own clock (Check 3.2); both deadlines declared as State 6a rounds them. *Over:* a read forbidden to refuse a store it cannot read; a registry outage reported as the store's own failure, on no signature and beside invalid-policy; a storage layer forbidden a destruction whose confirmation it cannot know will arrive in time; an auditor's reproduction that the skewed clocks Clock semantics 3 allows make fail. *Because:* Final Critique 8 found each a divergence between conforming builds or a rule no conforming build could keep, and the corpus already held the cure for the first three: Actor Identity's fifth round answers a failed store read with state-unavailable on every action and an unreachable registry with its own refusal, and the maintainer's ruling of 2026-10-19 on Verified Repair answers each action's refusals in one stated order. Compositions affected: the pages that compose this atom route registry-unavailable and state-unavailable when their rounds read them.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 12, Execution Contract Read 1 through 3) and the two rules that restated it deleted to it: the atom-wide state-unavailable (Operation 34) to Read 1, and [Read]'s state-unavailable on a failed read alone (Operation 33) to Read 2 beside Operation 29; the read's condition off Operation 29, the read off the placement and purge refusal orders, Term database read deleted, and state-unavailable off every signature; rules 156 to 154. *Over:* the page stating for itself what every action answers when the retention records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's eighth Final Critique had made one of the cures the contract's Read family is written from. An unreadable policy registry keeps its own refusal, registry-unavailable: the registry is read at the seam, not from the database. What each action answers on an answered read is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Place Under Retention]'s refuses line listing its refusals in the order the placement refusal order gave them — invalid-request, registry-unavailable, policy-not-found, invalid-policy, then storage-failure, which answers only at the write — [Purge]'s kept as the page wrote it, already in the purge refusal order's order, and the order cited from the Execution Contract (Capability requirement 12, Execution Contract Refusal 1); the rules that only stated it deleted to Refusal 1: Operation 35 and Operation 36, which evaluated the two refusal orders, with Term placement refusal order and Term purge refusal order, and the pairs Operation 6a (policy-not-found only once every well-formedness check passes), Operation 8a (invalid-policy only once they pass and the host read the policy registry), Operation 24c (registry-unavailable only once they pass), Operation 9a and Operation 19a (storage-failure only where no other refusal applies); rules 154 to 147. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's eighth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-22 — The wiring is read outside the records, and a ban on refusing names its ground, as the Execution Contract says.** *Chose:* External check 6, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 6.1's tombstone, which named it, now naming the contract, and the label cited on Capability requirement 12; Operation 18's ground clause retired, the rule written as *[Purge] MUST NOT refuse a retention whose purge deadline has passed*, which Execution Contract Refusal 1's second sentence reads as naming the ground, so an unknown, purged or ineligible retention still answers its refusal; rules 147 to 146. *Over:* the page stating for itself that the wiring is an external check, and Operation 18 carrying the ground clause a Final Critique wrote. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration and the refusal ban among them; this page's Final Critiques had made both cures one specification at a time. What each action does and answers is unchanged.

- **2026-10-22 — The time resolution names the instant its multiples count from.** *Chose:* Term time resolution as the smallest span the deployment's clock and the database tell apart and the epoch its multiples are measured from, both the deployment's declaration (Capability requirement 5, read by External check 3) and fixed for the life of the instance, so every rounding State 4a, State 6a and Operation 13a make lands on one grid in every build; every open line flagged beside its rule; rules 146 to 148. *Over:* a span with no origin, on which one build counting whole resolutions from the Unix epoch and another from the database's own stamp different deadlines for one injected now and answer one [Purge] near a deadline differently. *Because:* Final Critique 9 found it, and the page's own declaration was the place for it: Capability requirement 5 already makes the deployment declare the time resolution. Smaller fixes rode with it, none changing what a rule means: Invariant 6.1, 6.2 and 8.1 and Check 2.1 compare instants with PRECEDES, Operation 8c writes IS NOT IN, and Term actors names the database; the five rules that carried two obligations carry one each, Capability requirement 7 and Record divergence 5 written as one *retain*, Capability requirement 13 split from Capability requirement 10 and Simultaneous retention 7 and 8 from Simultaneous retention 5, Operation 22 deleted to Operation 13 and Operation 21; SEC, FDA, DoD, IRS, NARA and CVV are spelled out; the invariants' closing paragraph calls a purge, not a destruction, what a purged retention shows was lawful. What each action does and answers is unchanged, except that the grid its roundings land on is now declared.

- **2026-10-22 — A destruction is read against every retention in place at it, at the time resolution.** *Chose:* External check 5 reading each destruction against the retentions in place at the destruction (Term retention in place at the destruction): those over the destroyed record whose retention instant the destruction instant, rounded up to the time resolution as State 4a rounds a retention instant, does not precede, so a placement and a destruction that round up to one multiple read as the placement first. *Over:* the selection by a retention instant preceding the destruction instant, which set an instant State 4a had rounded up against one read from the clock as it stood, so a destruction in the span after a placement fell outside the check and a deployment that destroyed a record within that span, years early, passed it; and over deleting State 4a, which would leave the database a retention instant finer than it tells apart. *Because:* Final Critique 10 found it, and the page's open line 2026-10-20-e had named the cure, comparing at the time resolution; within one multiple the records cannot order a placement and a destruction, so the check takes the reading that reports a destruction over the one that hides it, at the cost of reporting a destruction against a retention placed over the record after it inside that multiple. Smaller fixes rode with it: the Summary and the premature-purge example say a purge destroys the record or, where another pattern does the destroying, ends the retention, and the Summary fixes two dates per placement; Simultaneous retention 3 bars [Purge], not every action, from reading a sibling retention, so [Read] answers every retention as Operation 29 says; Composition note 3 is deleted to Simultaneous retention 5 and 6a, which say who owns joint enforcement and when; the four edge-case headings take their families' names; the Storage Failure entry says a retry settles a purge only where its write can commit. Open lines 2026-10-20-c, e, f and g and 2026-10-03-m are closed and 2026-10-20-d narrowed; rules 148 to 147. What each action does and answers is unchanged.

- **2026-10-22 — The flagged lines stand, and a destruction is still read against every retention in place at it.** *Chose:* the page as Final Critique 10 left it: External check 5 and Term retention in place at the destruction reading a placement that races a purge as Simultaneous retention 5 through 8 order the two, through the pattern that owns joint enforcement; the fourteen open lines kept as they stand, each flagged beside its rule; the Summary's *data-minimization rules* and *without anyone having to explain it* said in plain words; the rule count stays at 147. *Over:* the atom serializing a placement against a purge over one record reference, which would take joint enforcement from the composing pattern this page's 2026-10-03 entry on joint enforcement gave it to; and a Capability requirement or a refusal for each value the seam carries, for the range of the purge instant and for a colliding retention id, each deciding an open line's question on this page alone. *Because:* Final Critique 11's readers reported the flagged lines again, twenty-one of twenty-three foundational reports on twelve of the fourteen lines, and none stood on the method's test; the one report on Final Critique 10's cure found a race that Simultaneous retention 6 already serializes, and a placement and a destruction within one multiple of the time resolution read as the placement first, the cost the term states. What each action does and answers is unchanged.

NOTE: End of Retention Window.
