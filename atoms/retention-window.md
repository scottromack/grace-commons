---
title: Retention Window
id: 56
audience: common
parent: Atomic Concepts
has_toc: true
toc: true
---

# Retention Window

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## Summary

Retention Window records each obligation to keep a record for a minimum period, under the retention policy that sets it, and refuses to end that obligation before the period is up. Two dates are fixed each time a record is placed under retention: the earliest date the retention may be purged, and the latest date the purge is expected. A purge ends the retention and removes the record from the database in the same step; where another pattern has taken on the destruction, as it must for a record kept outside the database, the purge only ends the retention and that pattern destroys the record. A purge is not refused for coming after the latest date, since refusing it would only keep the record longer; instead the lateness, and any record still kept past that date, can be read from the retention records by an auditor or a compliance dashboard. This is the mechanism behind multi-year retention of financial and medical records, rules that keep payment-card data no longer than it is needed, and contract retention that outlasts the deal. It does not handle where records physically live, litigation holds, or privacy-law erasure — those are separate patterns.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

A regulated record has two deadlines and they point opposite ways: keep it long enough, and do not keep it longer. Too-early destruction breaks a retention obligation; too-late destruction breaks data minimization. Both are auditable, and a system that holds the rule in a scheduler, a runbook or a cron comment cannot prove either. This atom makes the obligation a record: what is retained, under which policy, from when, until when, and by when it should be gone. It enforces the first deadline structurally — purge before the retention period elapses is refused — and it observes the second rather than enforcing it, because refusing a late purge would compound the very overshoot it detects. Everything else a retention regime needs — what a policy says, what a hold suspends, how a record kept outside the database or on immutable storage is destroyed, who authorized it — is a composing pattern's, and the atom names each limit rather than pretending to cover it.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a retention by the retention id.
Identity 2: The host MUST allocate a retention id at the atom's seam (Execution Contract Logic confinement 3).
Identity 4: The business caller MUST NOT supply a retention id at a placement.
Identity 6: The atom MUST NOT identify a retention by the record reference.
Identity 7: The atom MUST NOT identify a retention by the policy reference.
Identity 8: The atom MUST NOT identify a retention by retention instant.
Identity 10: The atom MUST compare two record references by exact value (Execution Contract Logic confinement 13).
```

Term retention: one recorded obligation over one record under one policy — a [Retention Window] instance's record.

Term retention id: the opaque value naming one retention — a [Retention Id].

Term record reference: the opaque reference naming what is retained, a string (Execution Contract Input 3) — a [Record Reference]; the host owns what a record is.

Term policy reference: the opaque reference naming which rules apply, a string (Execution Contract Input 3) — a [Policy Reference]; the policy registry is a separate concept.

Term seam: the atom's I/O boundary as Execution Contract Logic confinement 14 declares it; the host injects here the clock reading and, at a placement, the retention id, the policy registry's answer for the policy reference — that the host could not read the registry, that the registry holds no policy under the reference, or the policy's duration and max purge delay as the host resolved them (Operation 24a) — and the latest instant the database holds (Capability requirement 19).

Term transition: the atom's evaluation of one call against the retention records, as Execution Contract Logic confinement 14 declares it.

Term business caller: the party whose action the call carries, as Execution Contract Logic confinement 14 declares it; never the source of an injected value.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

### State

```
State 2: EVERY retention MUST carry retention id, record reference, policy reference, retention instant, retention deadline and purge deadline.
State 3: A purged retention MUST carry purge instant.
State 4: [Place Under Retention] MUST set retention instant from the injected now.
State 4a: [Place Under Retention] MUST round retention instant up to the time resolution.
State 5: [Place Under Retention] MUST set retention deadline from the policy's duration.
State 6: [Place Under Retention] MUST set purge deadline from the policy's max purge delay.
State 6a: [Place Under Retention] MUST round retention deadline and purge deadline up to the time resolution.
State 9: The atom MUST NOT offer a policy-change surface.
State 10: The atom MUST NOT hold a storage tier.
```

Term retention state: retained | purged — under obligation, or ended by a purge and terminal.

Term retention instant: the instant the retention was placed, stamped from the injected now — a [Retention Instant].

Term retention deadline: `(retention instant + duration)`, rounded up to the time resolution — a [Retention Deadline]; the instant the obligation ends.

Term purge deadline: `(retention deadline + max purge delay)`, rounded up to the time resolution — a [Purge Deadline]; the latest the regulator expects destruction.

Term purge instant: the instant the purge was recorded, stamped from the injected now — a [Purge Instant].

Term overshoot: `(purge instant - purge deadline)` where positive, for a purged retention — an [Overshoot]; a reader derives it, the atom does not store it and [Read] does not answer it.

Term active overdue: `(now - purge deadline)` where positive, for a retained retention — an [Active Overdue]; a reader derives it, the atom does not store it and [Read] does not answer it.

Term duration: the retention period the policy carries, resolved to an elapsed length at the seam (Operation 24a) — a [Duration]; positive. How a calendar period resolves to an elapsed length — the instant it counts from, the place whose calendar it counts in and where a month's end falls — is the policy's (Non-goal 7), and the host resolves it as the policy counts it (Operation 24a).

Term latest database instant: the last instant the deployment's database can hold, a multiple of the time resolution (Capability requirement 5, Capability requirement 19) — a deadline later than it is invalid-policy (Operation 8c).

Term zero duration: a duration of no length — the floor a policy's duration must exceed, and the floor a max purge delay must not fall below.

Term degenerate duration: the value the host injects in place of a duration it resolved to no elapsed length (Operation 24a).

Term degenerate max purge delay: the value the host injects in place of a max purge delay it resolved to no elapsed length (Operation 24a).

Term max purge delay: the lag the policy allows between retention-end and purge — a [Max Purge Delay]; not negative.

Term purge eligible: yes | no — a [Purge Eligible]; yes exactly when the retention state EQUALS retained AND the injected now does not precede retention deadline. Derived at the moment a question is asked, never written; the term entry's purge eligible is the projection of this answer.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 5: The deployment MUST declare the time resolution.
Capability requirement 6a: IF a composing pattern owns the destruction THEN the deployment MUST destroy a record a retention names through that pattern alone.
Capability requirement 7: The deployment MUST retain the instant of EVERY destruction of a record a retention names, read from the clock that supplies now, for the life of the instance.
Capability requirement 8: The deployment MUST supply EVERY placement a retention id naming no retention of the retention records.
Capability requirement 9: The deployment MUST supply EVERY retention id PER Execution Contract Logic confinement 16.
Capability requirement 10: The deployment MUST supply EXACTLY ONE record reference per record.
Capability requirement 11: The deployment MUST place EVERY retention over one record in one [Retention Window] instance.
Capability requirement 12: The deployment MUST supply the retention records PER Execution Contract Database 1 through 5, Execution Contract Database 8, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Query 1 through 5, Execution Contract Input 1, Execution Contract Input 3 and Execution Contract Conformance 9.
Capability requirement 13: The deployment MUST NOT reuse a record reference for another record.
Capability requirement 14: The deployment MUST supply a database that holds EVERY purge instant [Purge] stamps, for the life of the instance.
Capability requirement 15: The deployment MUST NOT supply a placement the record reference of a destroyed record.
Capability requirement 16: The deployment MUST supply a record reference that names EVERY version of the record in the database.
Capability requirement 17: The deployment MUST supply the policy registry the host resolves a policy reference against (Operation 24).
Capability requirement 18: IF the instance holds a retention THEN the deployment MUST NOT change whether a composing pattern owns the destruction.
Capability requirement 19: The deployment MUST declare the latest instant the database holds.
```

NOTE: a retention id the retention records already hold, supplied at a placement, breaks Capability requirement 8; the atom has no refusal for it.

NOTE: the deployment's other obligations stand beside the rules that read them — the policy's duration and max purge delay resolved at the seam (Operation 24, Operation 24a, Operation 24b), the wiring of a pattern that owns the destruction (Record divergence 4, Composition note 1), the pattern that owns joint enforcement (Simultaneous retention 5 through 8; [Defensible Retention](../compositions/defensible-retention.md) holds it today, its Invariant 9) and a high-assurance deployment's alert (Purge persistence 3).

### Operations

```
place_under_retention(record_ref, policy_ref)
  answers retention_id
  refuses invalid-request | registry-unavailable | policy-not-found | invalid-policy | storage-failure

purge(retention_id)
  answers ok
  refuses not-known | not-retained | retention-period-not-elapsed | storage-failure

read(query)
  answers every matching retention
  refuses invalid-query
```

```
Operation 1: [Place Under Retention] MUST record EXACTLY ONE retention per successful call.
Operation 2: [Place Under Retention] MUST stand the retention in retained.
Operation 3: [Place Under Retention] MUST answer retention id.
Operation 4: IF record reference EQUALS blank THEN [Place Under Retention] MUST answer invalid-request.
Operation 5: IF policy reference EQUALS blank THEN [Place Under Retention] MUST answer invalid-request.
Operation 6: IF the policy reference IS NOT IN the policy registry THEN [Place Under Retention] MUST answer policy-not-found.
Operation 7: IF the policy's duration DOES NOT EXCEED the zero duration THEN [Place Under Retention] MUST answer invalid-policy.
Operation 7a: IF the policy's duration EQUALS degenerate duration THEN [Place Under Retention] MUST answer invalid-policy.
Operation 8: IF the zero duration EXCEEDS the policy's max purge delay THEN [Place Under Retention] MUST answer invalid-policy.
Operation 8b: IF the policy's max purge delay EQUALS degenerate max purge delay THEN [Place Under Retention] MUST answer invalid-policy.
Operation 8c: IF the latest instant the database holds PRECEDES retention deadline OR the latest instant the database holds PRECEDES purge deadline THEN [Place Under Retention] MUST answer invalid-policy.
Operation 9: IF the database refuses the write THEN [Place Under Retention] MUST answer storage-failure.
Operation 11: [Place Under Retention] MUST NOT read the host's records.
Operation 12: [Purge] MUST stand the retention in purged.
Operation 13: [Purge] MUST stamp purge instant from the injected now.
Operation 13a: [Purge] MUST round purge instant up to the time resolution.
Operation 13b: IF no composing pattern owns the destruction THEN [Purge] MUST remove EVERY version of the record the retention names from the database.
Operation 14: IF the retention id IS NOT IN the retention ids the retention records hold THEN [Purge] MUST answer not-known.
Operation 15: IF the retention state EQUALS purged THEN [Purge] MUST answer not-retained.
Operation 16: IF the retention state EQUALS retained AND purge eligible EQUALS no THEN [Purge] MUST answer retention-period-not-elapsed.
Operation 18: [Purge] MUST NOT answer retention-period-not-elapsed for a retention whose purge deadline has passed.
Operation 19: IF the database refuses the write THEN [Purge] MUST answer storage-failure.
Operation 20: [Purge] MUST leave the retention in retained on storage-failure.
Operation 21: [Purge] MUST judge against one injected now per call.
Operation 24: The host MUST resolve the policy at the seam of [Place Under Retention] alone.
Operation 24a: The host MUST resolve the policy's duration and the policy's max purge delay to elapsed lengths at the atom's seam.
Operation 24b: IF the host cannot read the policy registry at a placement THEN [Place Under Retention] MUST answer registry-unavailable.
Operation 26: The transition MUST NOT read the policy registry.
Operation 29: [Read] MUST answer EVERY matching retention, retained AND purged.
Operation 30: [Read] MUST answer a retention's stored fields.
Operation 31: [Read] MUST answer purge eligible PER retained retention.
Operation 32: [Read] MUST NOT write.
Operation 37: IF a filter axis IS NOT IN the query axes THEN [Read] MUST answer invalid-query.
Operation 38: IF a filter value IS NOT IN the axis's admitted values THEN [Read] MUST answer invalid-query.
Operation 39: [Read] MUST NOT answer a retention that is not a matching retention.
```

NOTE: watch the unreadable registry (Operation 24b).

Term query axes: retention id and record reference — every filter axis [Read] admits, each axis admitting every string that DOES NOT EQUAL blank, whatever its length, since the atom caps no reference (Execution Contract Query 1, Execution Contract Query 5).

Term matching retention: a retention the query matches — one whose retention id EQUALS the filter's retention id where the query carries that filter, and whose record reference EQUALS the filter's record reference where it carries that filter (Identity 10, Execution Contract Query 3); a query carrying no filter matches every retention (Execution Contract Query 4).

Term time resolution: the smallest span the deployment's clock and the database tell apart (Capability requirement 5), and the epoch its multiples are measured from, fixed for the life of the instance.

Term restore surface: an action that stands a purged retention in retained again, or returns to the database a record [Purge] removed (Invariant 3.2).

Term well-formedness check: Operation 4 and Operation 5 — every check [Place Under Retention] makes on the call's own inputs.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the retention records |
|---|---|---|---|
| [Place Under Retention] | refs well-formed, policy resolves and is valid, database accepts | retention id | one retention lands in [Retained] with its two deadlines (Operation 1, State 4 through 6) |
| [Place Under Retention] | blank record reference or policy reference, or one that is not a string | [Invalid Request] | none (Operation 4, Operation 5, Execution Contract Input 3) |
| [Place Under Retention] | policy reference resolves to nothing | [Policy Not Found] | none (Operation 6) |
| [Place Under Retention] | the host cannot read the policy registry | [Registry Unavailable] | none — the well-formedness checks passed and no policy was read (Operation 24b, Execution Contract Refusal 1) |
| [Place Under Retention] | the registry was read, then duration not positive or unresolved, delay negative or unresolved, or a deadline later than the latest instant the database holds | [Invalid Policy] | none (Operation 7, Operation 7a, Operation 8, Operation 8b, Operation 8c) |
| [Place Under Retention] | database refuses the write | [Storage Failure] | none (Operation 9) |
| [Purge] | no retention under that id, or a blank or malformed one | [Not Known] | none (Operation 14, Execution Contract Input 3) |
| [Purge] | retention already purged | [Not Retained] | none (Operation 15) |
| [Purge] | retention period not elapsed | [Retention Period Not Elapsed] | none — the guard writes nothing (Operation 16, Execution Contract Read 4) |
| [Purge] | eligible, no composing pattern owns the destruction, database accepts | ok | [Retained] → [Purged], purge instant stamped, every version of the record removed from the database in the same write; the retention id, record reference, policy reference and the instants set earlier stand (Operation 12, Operation 13, Operation 13b, Invariant 4.2, Invariant 5.1, Invariant 5.2, Invariant 5.3) |
| [Purge] | eligible, past purge deadline | ok | the same — lateness is observable, never a ground for refusal (Operation 18) |
| [Purge] | eligible, database refuses the write | [Storage Failure] | none — the retention stays [Retained] (Operation 19, Operation 20) |
| [Purge] | eligible, a composing pattern owns the destruction, database accepts | ok | [Retained] → [Purged]; the record stands until the pattern confirms the destruction; the retention id, record reference, policy reference and the instants set earlier stand (Record divergence 4, Record divergence 5, Invariant 4.2, Invariant 5.1, Invariant 5.2, Invariant 5.3) |
| *a retention crossing retention deadline* | — | *nothing* | nothing is written; eligibility is read (Invariant 11.1, Invariant 11.2, Invariant 11.3) |
| [Read] | a query over the query axes, or none | every matching retention, with its stored fields and, while retained, purge eligible, in Execution Contract Read 5's order | none (Operation 29 through 32, Operation 39) |
| [Read] | a filter axis outside the query axes, or a blank filter value | [Invalid Query] | none (Operation 37, Operation 38) |

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
  Invariant 3.2: The atom MUST NOT offer a restore surface.
  ```
- **Invariant 4 — Id stability.**
  ```
  Invariant 4.1: EVERY version of a retention MUST carry the retention id the host allocated for the retention's placement.
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
  ```
- **Invariant 7 — No early purge.**
  ```
  Invariant 7.1: IF purge eligible EQUALS no THEN [Purge] MUST NOT stand the retention in purged.
  ```
- **Invariant 8 — Purge timestamp consistency.**
  ```
  Invariant 8.1: A purged retention's purge instant MUST NOT PRECEDE the retention's retention deadline.
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
  ```
- **Invariant 11 — Purge-eligibility is derived, never stored.**
  ```
  Invariant 11.1: The atom MUST NOT store purge eligibility.
  Invariant 11.2: A reader MUST NOT derive purge eligible from a value other than the retention's state, retention deadline and the injected now.
  Invariant 11.3: The atom MUST NOT write when a retention crosses retention deadline.
  ```

Membership exclusivity and terminal absorption give the *audit-friendly* property — once purged, the obligation is closed for good, with durable evidence that the purge was lawful. No early purge gives the *retention-honored* property. Timestamp consistency makes overshoot provable, as honest as the clock that stamped the records. Derived eligibility is what lets readiness be read without a scheduler and without a flag that drifts.

## Examples

The same atom, five regulated domains, identical mechanic.

### Banking — transaction-record retention under SOX

A bank places every settled transaction under retention with a 7-year policy (`policy_sox_settled_txn`: duration = 7 years, max purge delay = 30 days) via [Place Under Retention]. At the seven-year mark, the records' [Purge Eligible] projection flips to yes (derived from the injected clock, not written); the bank's records-management system lists those records and invokes [Purge] within the 30-day purge window. The bank's records-management system logs each purge for SOX (Sarbanes-Oxley Act — US financial reporting law) section 802 audit. An external auditor querying *"any transaction record purged before its 7-year obligation?"* gets the empty set — Invariant 7 guarantees it.

### Healthcare — medical-record retention under HIPAA and state law

A hospital places each patient encounter record under retention with the maximum of HIPAA's (US Health Insurance Portability and Accountability Act) federal 6-year baseline (45 CFR (Code of Federal Regulations) section 164.530(j)) and the state's longer requirement (often 10–25 years for adult records, longer for pediatric). The hospital's records system, which owns the policy each record is placed under (Composition note 4), picks the rule that applies to each patient before it calls [Place Under Retention]; the [Policy Reference] names that rule, and the retention's [Retention Deadline] is patient-specific because the policy is. Purges occur on a rolling schedule; the audit reads the retention records to demonstrate compliance with the longer of the applicable rules.

### Payments — cardholder-data retention under PCI DSS

A payment processor places cardholder-data records (PAN — Primary Account Number, the card number; expiration; CVV-substitute tokens — stand-ins for the CVV (card verification value), the card security code) under retention with the *shortest* viable policy — typically days for transient transaction data, never longer than business need requires. PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for handling cardholder data) Requirement 3.1 mandates data minimization. The atom's no-early-purge invariant becomes less relevant here (windows are short); the [Active Overdue] metric is what the audit primarily surfaces — any cardholder data still [Retained] past [Purge Deadline].

### Communications — broker-dealer communications under SEC Rule 17a-4

A registered broker-dealer places every business communication (email, chat, voice transcript) under retention with policies derived from SEC (US Securities and Exchange Commission — the federal securities regulator) Rule 17a-4 — generally 3 years, with the first 2 years in immediately-accessible storage. The atom carries the retention obligation; storage-tier transitions (immediately-accessible to less-accessible) belong to a Storage Tier composition. A FINRA (Financial Industry Regulatory Authority) examination reads the retention records to confirm that every required communication was retained for the full period and purged only after.

### Legal — contract retention beyond contract term

A company places each executed contract under retention with policy = max(contract duration + 6 years, statute-of-limitations for relevant claim types); its contract system, which owns the policy (Composition note 4), works that period out for each contract before it calls [Place Under Retention], since the atom never reads the contract (Operation 11). The retention extends past the operational life of the contract because the contract's audit obligations outlive its commercial life. Litigation hold composes by blocking the purge during pending litigation (Defensible Retention's gate over Legal Hold; out of scope for the atom).

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
- **Data minimization audit — "show me every record still Retained past its purge deadline."** Common under GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Article 5(1)(e) reviews. The auditor reads [Retained] with the injected [Now] and selects records where [Now] > [Purge Deadline] (the [Active Overdue] projection; these are necessarily [Purge Eligible] too, since [Purge Deadline] ≥ [Retention Deadline]). The atom does not refuse a purge for lateness (rejecting it would compound the [Overshoot]), so this query returns a non-empty set when the organization is behind on its purge schedule. The overdue set is the finding; the records themselves are the evidence; the remediation is to [Purge] the listed records and document the lateness.
- **Litigation discovery — "produce all records of type X from 2020-2022."** Counsel queries the host system, which keeps the records and says which of them still exist, since the atom never reads a record's existence (Record divergence 3); the retention records show, for each matching record, the policy each retention over it was placed under and whether that retention has been [Purged]. A [Purged] retention never returns to [Retained] — that is the atom's terminal-absorption invariant working as designed — and, where no composing pattern owns the destruction, the purge removed the record it named from the database; where a composing pattern owns the destruction, a standing record is not yet destroyed and is produced (Term standing record). A [Retained] retention does not show that its record still exists: once it is purge eligible, the purge of another retention over the same record may remove the record, or let the pattern that owns the destruction destroy it (Operation 13b, Simultaneous retention 4, Simultaneous retention 4a). The discovery response distinguishes *records retained and produced* from *records lawfully destroyed under the policy in effect at the time*, with the retention records themselves as the audit trail. Litigation hold should have been placed earlier — if it wasn't, that is a Legal Hold composition failure, not a retention failure.
- **Incident investigation — "the deployment's clock ran ahead for six hours; what was destroyed that should not have been?"** The investigator reads every [Purged] retention whose [Purge Instant] falls in the incident window and recomputes eligibility from [Retention Deadline] against a trusted clock. A purge whose stamped instant meets its deadline only because the injected clock ran fast is in that set, and the records hand it over: the retention, its policy, its deadline and its stamped instant all still stand (Invariant 10), so the finding is a list of early destructions with the evidence for each. The atom could not have prevented them — the clock's honesty is the deployment's (Execution Contract Logic confinement 7) — and it does not hide them.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the retention record set.

### Conformance checks

```
Check 1.1: An auditor MUST read the policy reference a record was placed under from the retention's policy reference (State 2).
Check 2.1: An auditor MUST find the set of purged retentions whose purge instant PRECEDES retention deadline empty (Invariant 7.1, Invariant 8.1).
Check 3.1: An auditor MUST confirm that the retention records store no purge eligibility (Invariant 11.1).
Check 3.2: An auditor MUST derive purge eligible from the retention state, retention deadline and the auditor's own clock (Invariant 11.2).
Check 4.1: An auditor MUST compute a purged retention's overshoot from purge instant and purge deadline (Invariant 8.3).
Check 4.2: An auditor MUST compute a retained retention's active overdue from purge deadline and the auditor's own clock (State 2).
Check 5.1: An auditor MUST reconstruct a record's policy history from the retentions sharing the record reference (Invariant 9.1).
Check 7.1: An auditor MUST find EVERY retention standing in EXACTLY ONE OF retained, purged (Invariant 1.1).
Check 7.2: An auditor MUST find EVERY retention carrying retention id, record reference, policy reference, retention instant, retention deadline and purge deadline (State 2, Invariant 4.1).
Check 7.3: An auditor MUST find EVERY purged retention carrying purge instant (State 3, Invariant 2.2).
Check 7.4: An auditor MUST find no retention standing in retained at a commit AFTER a commit at which the retention stood in purged (Invariant 2.1, Invariant 3.1).
Check 7.5: An auditor MUST find EVERY committed version of a retention carrying the retention id, record reference, policy reference, retention instant, retention deadline and purge deadline the retention's first version carries (Invariant 4.2, Invariant 5.1, Invariant 5.2, Invariant 5.3).
Check 7.6: An auditor MUST find EVERY committed version of a purged retention carrying the purge instant the retention's first purged version carries (Invariant 5.3).
Check 7.7: An auditor MUST find the set of retentions whose retention deadline PRECEDES retention instant empty (Invariant 6.1).
Check 7.8: An auditor MUST find the set of retentions whose purge deadline PRECEDES retention deadline empty (Invariant 6.2).
Check 7.9: An auditor MUST find the set of retention ids two retentions share empty (Invariant 9.1).
Check 7.10: An auditor MUST find EVERY retention an earlier commit holds in EVERY later commit (Invariant 10.1, Invariant 10.2).
```

NOTE: watch the comparator written in English (Check 2.1).

### External checks

```
External check 2: An auditor MUST read the composing pattern's joint-enforcement mechanism (Simultaneous retention 3, Simultaneous retention 5).
External check 3: An auditor MUST read the deployment's declared time resolution (Capability requirement 5, State 6a).
External check 4: An auditor MUST read EVERY standing record from the owning pattern's confirmations (Record divergence 5).
External check 5: An auditor MUST confirm from the deployment's own destruction records that no destruction instant PRECEDES the retention deadline of a retention in place at the destruction (Operation 13b, Capability requirement 6a, Capability requirement 7, Capability requirement 15, Simultaneous retention 4).
External check 7: An auditor MUST confirm from the deployment's own records that EVERY record reference a retention names has named EXACTLY ONE record (Capability requirement 13).
External check 8: An auditor MUST confirm from the deployment's own records that EVERY record a retention names has carried EXACTLY ONE record reference (Capability requirement 10).
External check 9: An auditor needing the policy a policy reference named when a retention was placed MUST read the policy registry's own record of that policy at the retention instant (Non-goal 8).
```

Term retention in place at the destruction: a retention over a destroyed record where the destruction instant, rounded up to the time resolution as State 4a rounds a retention instant, DOES NOT PRECEDE the retention's retention instant; every retention placed before the destruction is one, and so is a retention placed after the destruction whose retention instant rounds up to the same multiple of the time resolution, since the records cannot order the two.

NOTE: the atom cannot answer these from the retention records — Simultaneous retention 3 keeps [Purge] from reading a sibling, so the evidence that joint enforcement happened lives in the composing pattern's records, not here (council read 11).

NOTE: EVERY check names the rule the check tests. The bar is the regulator's question — *was every record's obligation honored, and what is overdue now?* — answered provably.

## Non-goals

```
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
Non-goal 17: The atom MUST NOT destroy a record outside the database.
Non-goal 18: A deployment that keeps a record a retention names outside the database MUST compose a pattern that owns the destruction.
```

NOTE: the owners — a Storage Tier *(forthcoming)* (State 10); [Legal Hold](./legal-hold.md) and [Defensible Retention](../compositions/defensible-retention.md) (Non-goal 2, Non-goal 3); Shred *(forthcoming)* (Non-goal 4); Erasure Coordination *(forthcoming)* (Non-goal 5, Non-goal 6); a Policy Registry *(forthcoming)* (Non-goal 7, Non-goal 8); [Actor Identity](./actor-identity.md) (Non-goal 10, Non-goal 11); the composing pattern that owns joint enforcement (Non-goal 12, Simultaneous retention 5); Trusted Timestamping *(forthcoming)* (Non-goal 13); [Duplicate Prevention](./duplicate-prevention.md) (Non-goal 14, Non-goal 15); the composing pattern that owns the destruction (Non-goal 16 through 18, Record divergence 6), which destroys, confirms and retries through Record Destruction *(forthcoming)*, as [Defensible Retention](../compositions/defensible-retention.md) names it — the destruction's lifecycle, a standing record, a withheld record and a confirmation, is that pattern's (Record divergence 4a through 6); [Erasure Tombstone](./erasure-tombstone.md) keeps the permanent record that a record was destroyed and confirms no destruction (Erasure Tombstone Non-goal 1).

Where the atom breaks down: when the obligation is a function of the record's content — records about a minor retained until majority, which needs a policy lookup against the record itself; when the regulatory clock and the deployment's clock are far apart, which breaks every wall-time deadline at once.

## Edge cases

### Clock semantics

```
Clock semantics 3: Two readers judging purge eligible under skewed clocks MAY disagree near retention deadline.
```

### Concurrency

### Purge persistence

```
Purge persistence 1: A caller MUST read storage-failure from [Purge] as the retention standing in retained.
Purge persistence 1a: A caller MUST NOT read storage-failure from [Purge] as the record standing undestroyed.
Purge persistence 2: IF neither Simultaneous retention 4a nor a gate of a composing pattern's own forbids the purge THEN a caller MUST retry a purge that answered storage-failure.
Purge persistence 2a: IF neither Simultaneous retention 4a nor a gate of a composing pattern's own forbids the purge THEN a caller MUST retry a purge that returned no answer.
Purge persistence 3: A high-assurance deployment MUST alert on storage-failure from [Purge].
```

Term high-assurance deployment: a deployment that declares itself so in the declaration of the composing patterns it wired in (Composition note 1).

### Record divergence

```
Record divergence 3: The atom MUST NOT read the record's existence.
Record divergence 4: A composing pattern MAY own the destruction ONLY IF the composing pattern declares the ownership as a capability requirement over the instance the composing pattern wires.
Record divergence 4a: A composing pattern that owns the destruction MUST destroy a record ONLY IF the record is a standing record.
Record divergence 5: A composing pattern that owns the destruction MUST retain the confirmation of EVERY destruction, by record reference, for the life of the instance.
Record divergence 6: A composing pattern that owns the destruction MUST retry the destruction of EVERY standing record that is not a withheld record.
```

Term owns the destruction: said of one [Retention Window] instance — a composing pattern owns the destruction of the records that instance's retentions name, and of no other instance's; a rule conditioned on it reads the instance the call is made on. The ownership is declared before the instance's first placement (Record divergence 4) and does not change for the life of the instance (Capability requirement 18).

Term standing record: the record a purged retention names, where a composing pattern owns the destruction and has recorded no confirmation of the destruction.

Term withheld record: a standing record whose destruction a rule forbids for as long as the rule forbids it — Simultaneous retention 4, or a gate of the composing pattern's own, a legal hold among them.

Term destruction: one act destroying a record a retention names — [Purge]'s removal of every version of the record from the database where no composing pattern owns the destruction (Operation 13b), or the act of the composing pattern that owns it (Record divergence 4a).

Term confirmation: what a composing pattern that owns the destruction records when one destruction it made is done (Record divergence 5); the destruction's instant is no part of it, and the deployment retains that instant beside it (Capability requirement 7).

Term undestroyed: said of a record a retention names — no destruction has ended it.

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
Composition note 4: A composing pattern MUST own the policy the pattern places a record under.
Composition note 5: This atom's invariant numbers MUST stand as a frozen contract surface.
```

Term regulated Event Log instance: an Event Log instance the deployment declares regulated in the declaration of the composing patterns it wired in (Composition note 1).

NOTE: composing patterns — [Defensible Retention](../compositions/defensible-retention.md), [Audit Trail](../compositions/audit-trail.md). Forthcoming: Storage Tier, Shred, Erasure Coordination, Policy Registry, Trusted Timestamping, Record Destruction.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the deployment (also: a high-assurance deployment); a composing pattern (also: a pattern, a writer); a business caller; a caller; a reader; an auditor; the policy registry; the database; the retention records; a retention; a record; a policy; a purge.

Term records: retention — one obligation, carrying retention id, record reference, policy reference, retention instant, retention deadline, purge deadline, a retention state and, once purged, purge instant.

Term record verbs: identify, allocate, supply, reuse, compare, round, carry, stand, set, store, offer, hold, record, answer, read, resolve, stamp, judge, leave, refuse, write, derive, change, delete, remove, shrink, share, admit, gate, destroy, retry, alert, coordinate, confirm, serialize, own, disagree, compose, place, define, version, retain, permit, purge, choose, suspend, renumber, add, find, compute, reconstruct, declare, precede, bound, evaluate.

Term value sets: retention state = retained | purged. purge eligible = yes | no.

Term bounds: duration (the policy's retention period); max purge delay (the lag the policy allows); retention deadline; purge deadline.

Term cadences: empty — a purge cadence is the composing pattern's.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: latest database instant, high-assurance deployment, regulated Event Log instance, zero duration, degenerate duration, degenerate max purge delay, now, retention, retention id, record reference, policy reference, seam, transition, business caller, retention state, retention instant, retention deadline, purge deadline, purge instant, overshoot, active overdue, duration, max purge delay, purge eligible, time resolution, well-formedness check, owns the destruction, standing record, withheld record, sibling retention, joint enforcement, retention in place at the destruction, destruction, confirmation, undestroyed, query axes, matching retention, restore surface.

#### Retention Window

The compliance primitive this atom defines: a record is kept under retention for a known period, then becomes eligible for purge. Each retention is its own record with an opaque [Retention Id]; it carries a [Record Reference], [Policy Reference], the derived deadlines [Retention Deadline] and [Purge Deadline], and (once purged) [Purge Instant]. It occupies one of two states — [Retained] or [Purged].

Kind: Type

#### Place Under Retention

The behavior the host invokes to record a new retention over a [Record Reference] under a [Policy Reference]. The host resolves the policy at the seam (Operation 24); the action stamps [Retention Instant] from the injected [Now], computes [Retention Deadline] and [Purge Deadline] from the injected [Duration] and [Max Purge Delay], records the retention in [Retained], and returns the fresh [Retention Id].

Kind: Operation

#### Purge

The behavior the host invokes to transition a retention to [Purged], removing every version of the underlying record from the database in the same write — or, where a composing pattern owns the destruction (Record divergence 4), ending the obligation and leaving the destruction to that pattern. It destroys nothing outside the database (Non-goal 17). It is permitted only once the retention period has elapsed (the pure [Now] ≥ [Retention Deadline] guard, which writes nothing when it fails); on success it stamps [Purge Instant] from the same injected [Now] and answers [Ok]. It does not refuse a purge for lateness — the lateness is observed as [Overshoot], not rejected.

Kind: Operation

#### Read

The read-only query answering every retention the database holds that its [Query] matches, [Retained] and [Purged], each with its stored fields and, while [Retained], the [Purge Eligible] projection derived against the injected [Now]; a query carrying no filter matches every retention. It refuses a filter it cannot read ([Invalid Query]) rather than ignoring it, and it changes nothing.

Kind: Operation

#### Query

The filter a [Read] carries, over two axes: [Retention Id] and [Record Reference], so a composing pattern finds one retention, or every retention over one record, without reading the rest. An axis outside those, or a blank value, is [Invalid Query] rather than a silently dropped filter; a well-formed value naming no retention matches nothing. Supplied per call, not stored.

Kind:         Parameter
Parameter of: Read
Projection:   query

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

The terminal state of a retention whose underlying record has been removed from the database, or whose destruction a composing pattern owns, the record standing until that pattern records the confirmation (Record divergence 5, Term standing record). A retention enters [Purged] on a successful [Purge] and never leaves it — there is no un-purge or restore surface (Invariant 3). The [Purged] record is the audit evidence that the obligation ended lawfully.

Kind:      Member
Member of: the retention state
Role:      Outcome

#### Ok

The answer [Purge] returns on success: the retention stands in [Purged] and, where no composing pattern owns the destruction, every version of the record the retention names was removed from the database in the same write (Operation 12, Operation 13b).

Kind:       Member
Member of:  the Purge answer
Role:       Outcome
Projection: ok

#### Invalid Request

The refusal [Place Under Retention] returns when [Record Reference] or [Policy Reference] is blank, or is not a string (Execution Contract Input 3). A guard rejection that fails before any database write; no retention is recorded.

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

The refusal [Purge] returns when the supplied [Retention Id] references no recorded retention, a blank or malformed value among them — a lookup miss. An identity/state rejection, checked before the time gate.

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

The refusal either [Place Under Retention] or [Purge] returns when the database write fails after all preconditions pass. For [Purge] the retention remains in [Retained] and the failed write removed nothing, though the record may be gone under another retention's purge (Purge persistence 1a). The caller must treat it as definitive; a purge is retried (Purge persistence 2).

Kind:       Member
Member of:  the Place Under Retention / Purge rejection
Role:       Outcome
Projection: storage-failure

#### Invalid Query

The refusal [Read] returns for a filter axis outside the query axes or a filter value its axis does not admit, a blank one among them (Operation 37, Operation 38). Refusing rather than ignoring, because a silently dropped filter answers a different question from the one asked.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

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
[Ok]: #ok
[Invalid Request]: #invalid-request
[Policy Not Found]: #policy-not-found
[Invalid Policy]: #invalid-policy
[Registry Unavailable]: #registry-unavailable
[Not Retained]: #not-retained
[Not Known]: #not-known
[Retention Period Not Elapsed]: #retention-period-not-elapsed
[Storage Failure]: #storage-failure
[Query]: #query
[Invalid Query]: #invalid-query

---

## Standards references

Retention Window's standards inheritance:

- **ISO 15489-1 (Information and documentation — Records management)** — the International Organization for Standardization's standard for records-management practice. Defines retention as a managed lifecycle with policy-governed start, retention period, and disposition. The atom's two-state model is the operational core of ISO 15489's lifecycle framing.
- **GDPR Article 5(1)(e) — Storage limitation principle** — personal data must be kept *no longer than necessary*. The atom's [Overshoot] metric is the operational form of GDPR's data-minimization audit; persisting personal data past [Purge Deadline] is a violation surfaced by the record itself.
- **HIPAA section 164.530(j) — Documentation retention** — 6-year federal baseline for required HIPAA documentation; state law commonly extends this for clinical records. The atom's [Policy Reference] carries the applicable rule; the host system reconciles federal-state-policy overlap.
- **Sarbanes-Oxley section 802 — Retention of records relevant to audits and reviews** — 7-year retention for audit workpapers, with criminal penalties for early destruction. The atom's no-early-purge invariant keeps each retention from ending before its period is up, and where several retentions name one record the pattern that owns joint enforcement keeps the record while any of them is short of its deadline (Simultaneous retention 4, Simultaneous retention 4a); together they are the structural fix for SOX section 802's ban on early destruction.
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

---

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — retention-window.als + 18 twins (the static data model: Invariant 1.1, 4.1, 6.1, 6.2, 8.1, 9.1 and 11.1, State 2 through 6 with 4a and 6a, State 10, Identity 1, Operation 4, 5, 7, 8c and 13 checked on every version an ordered sequence of admitted calls leaves, with Identity 6 and Operation 8 checked through them); retention-window.tla + 23 twins (across steps, while the clock moves and [Read] carries a query: Invariant 2.1, 2.2, 3.1, 4.2, 5.1 through 5.3, 7.1, 8.3, 9.1, 10.2, 11.2 and 11.3, Identity 10, Capability requirement 8 and 9, Operation 1, 13b, 15, 20, 29, 32, 37, 38 and 39, Simultaneous retention 2, with Invariant 3.2 and 10.1, State 9 and Simultaneous retention 3 checked through them); the vote no of 2026-06-03 superseded by the maintainer's ruling of 2026-11-09 (both models; only the writing vetoes one), and neither vetoed; Operation 11, 21 and 26, Record divergence 3, Capability requirement 17 and Simultaneous retention 4 through 8 (joint enforcement, the composing pattern's) cannot be stated; owed rows: Operation 6, 8b, 14, 24b and 30, Capability requirement 18, 2026-11-12, re-derived 2026-11-21
last gate: 2026-11-21 — Final Critique 14, frozen at c523cd3c — foundational count 1 (a blank or malformed retention id had two owners, Execution Contract Input 3's invalid-request and Operation 14's not-known; cured: Operation 14 states not-known for any id the records do not hold), not clean, no sample; the round's refining findings cured with it, among them Operation 18, which named neither a refusal nor its ground and so barred none, now naming retention-period-not-elapsed; 2026-10-24 — Final Critique 13, frozen at 142a72a — foundational count 0, clean, one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./retention-window.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/retention-window.md`.

</details>

NOTE: End of Retention Window.
