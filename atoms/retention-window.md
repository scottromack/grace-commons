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

Retention Window enforces the rule that a record must be kept for a minimum period and only then becomes eligible for destruction. For every managed record it stores which retention policy applies, when the keep-period ends, and the latest date by which destruction is expected. It blocks early deletion outright. Trying to destroy ("purge") a record before its period is up is refused. It also makes overdue records visible: anything still kept past its deadline shows up in the data as overdue, which a compliance dashboard can spot, without anyone having to explain it. Two dates are fixed when a record is placed under retention: the earliest date destruction is allowed, and the latest date it is expected. The span between them is the window in which destruction is both permitted and expected. The pattern enforces the early boundary — no destruction before the period ends. It only observes the late one. A record destroyed past its deadline reads in the records as a finding, not a refusal, because refusing a late destruction would only make the overdue situation worse. This is the mechanism behind multi-year retention of financial and medical records, data-minimization rules for payment-card data, and contract retention that outlasts the deal. It does not handle where records physically live, litigation holds, or privacy-law erasure — those are separate patterns.

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

Term retention: one recorded obligation over one record under one policy — a [Retention Window] instance's record.

Term retention id: the opaque value naming one retention — a [Retention Id].

Term record reference: the opaque reference naming what is retained — a [Record Reference]; the host owns what a record is.

Term policy reference: the opaque reference naming which rules apply — a [Policy Reference]; the policy registry is a separate concept.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the retention id and the resolved policy scalars here.

Term transition: the atom's evaluation of one call against the retention records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

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
Capability requirement 7: The deployment MUST record the instant of EVERY destruction of a record a retention names, read from the clock that supplies now, AND MUST retain the recorded instant for the life of the instance.
Capability requirement 8: The deployment MUST supply EVERY placement a retention id naming no retention of the retention records.
Capability requirement 9: The deployment MUST NOT supply the same retention id to two placements.
Capability requirement 10: The deployment MUST supply EXACTLY ONE record reference per record AND MUST NOT reuse a record reference for another record.
Capability requirement 11: The deployment MUST place EVERY retention over one record in one [Retention Window] instance.
Capability requirement 12: The deployment MUST supply the retention records PER Execution Contract Database 1 through 4.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
```

### Operations

```
place_under_retention(record_ref, policy_ref)
  answers retention_id
  refuses invalid-request | invalid-policy | policy-not-found | registry-unavailable | state-unavailable | storage-failure

purge(retention_id)
  answers ok
  refuses not-known | not-retained | retention-period-not-elapsed | state-unavailable | storage-failure

read()
  answers every retention
  refuses state-unavailable
```

```
Operation 1: [Place Under Retention] MUST record EXACTLY ONE retention per successful call.
Operation 2: [Place Under Retention] MUST stand the retention in retained.
Operation 3: [Place Under Retention] MUST answer retention id.
Operation 4: IF record reference EQUALS blank THEN [Place Under Retention] MUST answer invalid-request.
Operation 5: IF policy reference EQUALS blank THEN [Place Under Retention] MUST answer invalid-request.
Operation 6: IF the policy reference IS NOT IN the policy registry THEN [Place Under Retention] MUST answer policy-not-found.
Operation 6a: [Place Under Retention] MUST answer policy-not-found ONLY IF EVERY well-formedness check passes.
Operation 7: IF the policy's duration DOES NOT EXCEED the zero duration THEN [Place Under Retention] MUST answer invalid-policy.
Operation 7a: IF the policy's duration EQUALS degenerate duration THEN [Place Under Retention] MUST answer invalid-policy.
Operation 8: IF the zero duration EXCEEDS the policy's max purge delay THEN [Place Under Retention] MUST answer invalid-policy.
Operation 8a: [Place Under Retention] MUST answer invalid-policy ONLY IF EVERY well-formedness check passes AND the host read the policy registry at the placement.
Operation 8b: IF the host could not resolve the policy's max purge delay to an elapsed length THEN [Place Under Retention] MUST answer invalid-policy.
Operation 8c: IF retention deadline OR purge deadline falls outside the instants the database holds THEN [Place Under Retention] MUST answer invalid-policy.
Operation 9: IF the database refuses the write THEN [Place Under Retention] MUST answer storage-failure.
Operation 9a: [Place Under Retention] MUST answer storage-failure ONLY IF no other refusal of [Place Under Retention] applies.
Deleted: Operation 10. Execution Contract Database 1 owns it.
Operation 11: [Place Under Retention] MUST NOT read the host's records.
Operation 12: [Purge] MUST stand the retention in purged.
Operation 13: [Purge] MUST stamp purge instant from the injected now.
Operation 13a: [Purge] MUST round purge instant up to the time resolution.
Operation 14: IF no retention EXISTS for the retention id THEN [Purge] MUST answer not-known.
Operation 15: IF the retention state EQUALS purged THEN [Purge] MUST answer not-retained.
Operation 16: IF the retention state EQUALS retained AND purge eligible EQUALS no THEN [Purge] MUST answer retention-period-not-elapsed.
Operation 17: [Purge] MUST NOT write on retention-period-not-elapsed.
Operation 18: [Purge] MUST NOT refuse a call on the ground that purge deadline has passed.
Operation 19: IF the database refuses the write THEN [Purge] MUST answer storage-failure.
Operation 19a: [Purge] MUST answer storage-failure ONLY IF no other refusal of [Purge] applies.
Operation 20: [Purge] MUST leave the retention in retained on storage-failure.
Operation 21: [Purge] MUST judge against one injected now per call.
Operation 22: [Purge] MUST judge eligibility and stamp purge instant against that one now.
Deleted: Operation 23. Capability requirement 1 owns it.
Operation 24: The host MUST resolve the policy at the seam of [Place Under Retention] alone.
Operation 24a: The host MUST resolve the policy's duration and the policy's max purge delay to elapsed lengths at the atom's seam.
Operation 24b: IF the host cannot read the policy registry at a placement THEN [Place Under Retention] MUST answer registry-unavailable.
Operation 24c: [Place Under Retention] MUST answer registry-unavailable ONLY IF EVERY well-formedness check passes.
Deleted: Operation 25. Execution Contract Logic confinement 3 owns it.
Operation 26: The transition MUST NOT read the policy registry.
Deleted: Operation 27. Execution Contract Logic confinement 3 owns it.
Operation 28: A reader MUST derive purge eligible from the retention state, retention deadline and the injected now.
Operation 29: IF database read EQUALS answered THEN [Read] MUST answer EVERY retention, retained AND purged.
Operation 30: [Read] MUST answer a retention's stored fields.
Operation 31: [Read] MUST answer purge eligible PER retained retention.
Operation 32: [Read] MUST NOT write.
Operation 33: [Read] MUST answer state-unavailable ONLY IF database read EQUALS failed.
Operation 34: IF database read EQUALS failed THEN the atom MUST answer state-unavailable.
Operation 35: [Place Under Retention] MUST NOT evaluate a rule of the placement refusal order BEFORE EVERY earlier rule of the placement refusal order has answered no refusal.
Operation 36: [Purge] MUST NOT evaluate a rule of the purge refusal order BEFORE EVERY earlier rule of the purge refusal order has answered no refusal.
```

Term time resolution: the smallest span the deployment's clock and the database tell apart (Capability requirement 5); fixed for the life of the instance.

Term well-formedness check: Operation 4 and Operation 5 — every check [Place Under Retention] makes on the call's own inputs.

Term database read: answered | failed — the outcome of the read a call makes of the retention records, failed being the failure the section titled Step 1 failure in `execution-contract.md` names.

Term placement refusal order: Operation 34, Operation 4, Operation 5, Operation 24b, Operation 6, Operation 7, Operation 7a, Operation 8, Operation 8b, Operation 8c — [Place Under Retention]'s refusal rules, earliest first; Operation 9 answers only at the write, which no refused call reaches.

Term purge refusal order: Operation 34, Operation 14, Operation 15, Operation 16 — [Purge]'s refusal rules, earliest first; Record divergence 2 answers only at the destruction and Operation 19 only at the write, which no refused call reaches.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the retention records |
|---|---|---|---|
| [Place Under Retention] | refs well-formed, policy resolves and is valid, database accepts | retention id | one retention lands in [Retained] with its two deadlines (Operation 1, State 4 through 6) |
| [Place Under Retention] | the database read fails | [State Unavailable] | none (Operation 34) |
| [Place Under Retention] | blank record reference or policy reference | [Invalid Request] | none (Operation 4, Operation 5) |
| [Place Under Retention] | policy reference resolves to nothing | [Policy Not Found] | none (Operation 6) |
| [Place Under Retention] | the host cannot read the policy registry | [Registry Unavailable] | none — the well-formedness checks passed and no policy was read (Operation 24b, Operation 24c) |
| [Place Under Retention] | the registry was read, then duration not positive or unresolved, delay negative or unresolved, or a deadline outside the instants the database holds | [Invalid Policy] | none (Operation 7, Operation 7a, Operation 8, Operation 8b, Operation 8c) |
| [Place Under Retention] | database refuses the write | [Storage Failure] | none (Operation 9) |
| [Purge] | the database read fails | [State Unavailable] | none (Operation 34) |
| [Purge] | no retention under that id | [Not Known] | none (Operation 14) |
| [Purge] | retention already purged | [Not Retained] | none (Operation 15) |
| [Purge] | retention period not elapsed | [Retention Period Not Elapsed] | none — the guard writes nothing (Operation 16, Operation 17) |
| [Purge] | eligible, database accepts | ok | [Retained] → [Purged], purge instant stamped (Operation 12, Operation 13) |
| [Purge] | eligible, past purge deadline | ok | the same — lateness is observable, never refused (Operation 18) |
| [Purge] | eligible, database refuses the write | [Storage Failure] | none — the retention stays [Retained] (Operation 19, Operation 20) |
| [Purge] | eligible, the storage layer does not confirm the destruction | [Storage Failure] | none — the retention stays [Retained] (Record divergence 2, Operation 20) |
| [Purge] | eligible, a composing pattern owns the destruction, database accepts | ok | [Retained] → [Purged]; the record stands until the pattern confirms the destruction (Record divergence 4, Record divergence 5) |
| *a retention crossing retention deadline* | — | *nothing* | nothing is written; eligibility is read (State 7, Operation 28) |
| [Read] | the database read fails | [State Unavailable] | none (Operation 33, Operation 34) |
| [Read] | the database read answers | every retention, with its stored fields and, while retained, purge eligible | none (Operation 29 through 32) |

Where two [Place Under Retention] cases hold at once, the earlier rule of the placement refusal order answers (Operation 35); where two [Purge] cases hold at once, the earlier rule of the purge refusal order answers (Operation 36).

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
  Invariant 6.1: retention instant MUST NOT EXCEED retention deadline.
  Invariant 6.2: retention deadline MUST NOT EXCEED purge deadline.
  Deleted: Invariant 6.3. Operation 7 and Operation 7a own a duration that does not advance the deadline, and an invariant restating a precondition is a second owner.
  ```
- **Invariant 7 — No early purge.**
  ```
  Invariant 7.1: IF purge eligible EQUALS no THEN [Purge] MUST NOT stand the retention in purged.
  ```
- **Invariant 8 — Purge timestamp consistency.**
  ```
  Invariant 8.1: A purged retention's retention deadline MUST NOT EXCEED the retention's purge instant.
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

Membership exclusivity and terminal absorption give the *audit-friendly* property — once purged, the obligation is closed for good, with durable evidence that the destruction was lawful. No early purge gives the *retention-honored* property. Timestamp consistency lets an auditor compute overshoot from the records alone, as honest as the clock that stamped them. Derived eligibility is what lets readiness be read without a scheduler and without a flag that drifts.

## Examples

The same atom, five regulated domains, identical mechanic.

### Banking — transaction-record retention under SOX

A bank places every settled transaction under retention with a 7-year policy (`policy_sox_settled_txn`: duration = 7 years, max purge delay = 30 days) via [Place Under Retention]. At the seven-year mark, the records' [Purge Eligible] projection flips to yes (derived from the injected clock, not written); the bank's records-management system lists those records and invokes [Purge] within the 30-day purge window. Each purge is logged for SOX (Sarbanes-Oxley Act — US financial reporting law) section 802 audit. An external auditor querying *"any transaction record purged before its 7-year obligation?"* gets the empty set — Invariant 7 guarantees it.

### Healthcare — medical-record retention under HIPAA and state law

A hospital places each patient encounter record under retention with the maximum of HIPAA's (US Health Insurance Portability and Accountability Act) federal 6-year baseline (45 CFR (Code of Federal Regulations) section 164.530(j)) and the state's longer requirement (often 10–25 years for adult records, longer for pediatric). The [Policy Reference] captures the applicable rule; the retention's [Retention Deadline] is the patient-specific deadline. Purges occur on a rolling schedule; the audit reads the retention records to demonstrate compliance with the longer of the applicable rules.

### Payments — cardholder-data retention under PCI DSS

A payment processor places cardholder-data records (PAN — Primary Account Number, the card number; expiration; CVV-substitute tokens — stand-ins for the card security code) under retention with the *shortest* viable policy — typically days for transient transaction data, never longer than business need requires. PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for handling cardholder data) Requirement 3.1 mandates data minimization. The atom's no-early-purge invariant becomes less relevant here (windows are short); the [Active Overdue] metric is what the audit primarily surfaces — any cardholder data still [Retained] past [Purge Deadline].

### Communications — broker-dealer communications under SEC Rule 17a-4

A registered broker-dealer places every business communication (email, chat, voice transcript) under retention with policies derived from SEC Rule 17a-4 — generally 3 years, with the first 2 years in immediately-accessible storage. The atom carries the retention obligation; storage-tier transitions (immediately-accessible to less-accessible) belong to a Storage Tier composition. A FINRA (Financial Industry Regulatory Authority) examination reads the retention records to confirm that every required communication was retained for the full period and purged only after.

### Legal — contract retention beyond contract term

A company places each executed contract under retention with policy = max(contract duration + 6 years, statute-of-limitations for relevant claim types). The retention extends past the operational life of the contract because the contract's audit obligations outlive its commercial life. Litigation hold composes by blocking the purge during pending litigation (Defensible Retention's gate over Legal Hold; out of scope for the atom).

### Rejection paths

**Premature purge attempt.** A records-management system attempts to purge a transaction record four years into a seven-year SOX retention period:

```
purge(retention_id: "ret-0047")          # seam injects now = 2026-06-22T00:00:00Z
→ retention-period-not-elapsed
```

The pure eligibility guard evaluates [Now] ≥ [Retention Deadline] against the seam-injected [Now] and finds it false — [Retention Deadline] has not been reached; the atom rejects the purge outright and **writes nothing**. No state change occurs; the record remains in [Retained], and its [Purge Eligible] projection reads no. The rejection is the structural enforcement of Invariant 7 — early purge against the injected clock is not an outcome the atom has.

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

This atom's acceptance is what an external auditor can clear from the retention record set, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST read the policy applied to a record from the retention's policy reference (State 2).
Check 2.1: An auditor MUST find the set of purged retentions whose purge instant falls below retention deadline empty (Invariant 7.1, Invariant 8.1).
Check 3.1: An auditor MUST confirm that no retention record carries an eligibility flag (Invariant 11.1).
Check 3.2: An auditor MUST derive purge eligible from the retention state, retention deadline and the auditor's own clock (Invariant 11.2, Operation 28).
Check 4.1: An auditor MUST compute a purged retention's overshoot from purge instant and purge deadline (Invariant 8.3).
Check 4.2: An auditor MUST compute a retained retention's active overdue from purge deadline and the auditor's own clock (State 2).
Check 5.1: An auditor MUST reconstruct a record's policy history from the retentions sharing the record reference (Identity 9).
Deleted: Check 6.1. External check 6 owns it.
```

### External checks

```
External check 1: An auditor MUST confirm from the deployment's own destruction records that no retained retention over a destroyed record carried purge eligible EQUALS no at the destruction (Simultaneous retention 4).
External check 2: An auditor MUST read the composing pattern's joint-enforcement mechanism (Simultaneous retention 3, Composition note 3).
External check 3: An auditor MUST read the deployment's declared time resolution (Capability requirement 5, State 6a).
External check 4: An auditor MUST read EVERY standing record from the owning pattern's confirmations (Record divergence 5).
External check 5: An auditor MUST confirm from the deployment's own destruction records that no destruction instant PRECEDES the retention deadline of a retention over the destroyed record whose retention instant PRECEDES the destruction instant (Capability requirement 6, Capability requirement 6a, Capability requirement 7, Simultaneous retention 4).
External check 6: An auditor MUST identify from the deployment's own declaration which composing patterns the deployment wired in (Composition note 1).
```

NOTE: the atom cannot answer these from the retention records — Simultaneous retention 3 forecloses reading a sibling, so the evidence that joint enforcement happened lives in the composing pattern's records, not here (council read 11).

NOTE: EVERY check names the rule the check tests. The bar is the regulator's question — *was every record's obligation honored, and what is overdue now?* — answered from the records, never from a runtime claim.

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

NOTE: the owners — a Storage Tier pattern *(forthcoming)* (Non-goal 1); [Legal Hold](./legal-hold.md) and [Defensible Retention](../compositions/defensible-retention.md) (Non-goal 2, Non-goal 3); Cryptographic Shredding *(forthcoming)* (Non-goal 4); Erasure Coordination *(forthcoming)* (Non-goal 5, Non-goal 6); a Policy Registry *(forthcoming)* (Non-goal 7, Non-goal 8); [Actor Identity](./actor-identity.md) (Non-goal 10, Non-goal 11); the composing pattern that owns joint enforcement (Non-goal 12, Composition note 3); Trusted Timestamping *(forthcoming)* (Non-goal 13); [Duplicate Prevention](./duplicate-prevention.md) (Non-goal 14, Non-goal 15); the composing pattern that owns the destruction (Non-goal 16, Record divergence 6).

Where the atom breaks down: when the obligation is a function of the record's content — records about a minor retained until majority, which needs a policy lookup against the record itself; when the storage layer cannot make a record irrecoverable after a purge — append-only logs, distributed replicas, backups with their own schedules; when the regulatory clock and the deployment's clock are far apart, which breaks every wall-time deadline at once.

## Edge cases

### Clock semantics

```
Clock semantics 3: Two readers judging purge eligible under skewed clocks MAY disagree near retention deadline.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Non-goal 13 owns it.
```

### Concurrency and atomicity

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Divergence between the retention and the record

```
Record divergence 1: IF no composing pattern owns the destruction THEN [Purge] MUST NOT stand the retention in purged BEFORE the storage layer confirms the destruction.
Record divergence 1a: The host MUST destroy a record through the storage layer ONLY IF [Purge] judged the purging retention purge eligible.
Record divergence 2: IF no composing pattern owns the destruction AND the storage layer cannot confirm the destruction THEN [Purge] MUST answer storage-failure.
Record divergence 2a: The storage layer MUST confirm the destruction of EVERY record of which the storage layer holds no copy.
Deleted: Record divergence 2b. Capability requirement 4a owns it: a storage layer cannot know whether a confirmation reaches [Purge] before [Purge] answers, and no destruction lands once [Purge] has answered.
Record divergence 3: The atom MUST NOT read the record's existence.
Record divergence 4: A composing pattern MAY own the destruction ONLY IF the composing pattern declares the ownership as a capability requirement over the instance the composing pattern wires.
Record divergence 4a: A composing pattern that owns the destruction MUST destroy a record ONLY IF the record is a standing record.
Record divergence 5: A composing pattern that owns the destruction MUST record the confirmation of EVERY destruction, by record reference, AND MUST retain the confirmation for the life of the instance.
Record divergence 6: A composing pattern that owns the destruction MUST retry the destruction of EVERY standing record that is not a withheld record.
```

Term storage layer: the deployment-supplied component through which the host destroys a record, and which confirms the destruction, where no composing pattern owns the destruction (Capability requirement 4). A confirmation is the storage layer's answer received by the [Purge] that made the request before that [Purge] answers; an answer arriving later confirms nothing.

Term owns the destruction: said of one [Retention Window] instance — a composing pattern owns the destruction of the records that instance's retentions name, and of no other instance's; a rule conditioned on it reads the instance the call is made on. The ownership is set before the instance's first placement and does not change for the life of the instance.

Term standing record: the record a purged retention names, where a composing pattern owns the destruction and has recorded no confirmation of the destruction.

Term withheld record: a standing record whose destruction a rule forbids for as long as the rule forbids it — Simultaneous retention 4, or a gate of the composing pattern's own, a legal hold among them.

### Purge that does not persist

```
Purge persistence 1: A caller MUST read storage-failure from [Purge] as the retention standing in retained.
Purge persistence 1a: A caller MUST NOT read storage-failure from [Purge] as the record standing undestroyed.
Purge persistence 2: IF Simultaneous retention 4a does not forbid the purge THEN a caller MUST retry a purge that answered storage-failure.
Purge persistence 2a: IF Simultaneous retention 4a does not forbid the purge THEN a caller MUST retry a purge that returned no answer.
Purge persistence 3: A high-assurance deployment MUST alert on storage-failure from [Purge].
```

### Simultaneous retentions over one record

```
Simultaneous retention 1: The atom MUST admit two live retentions over one record reference.
Simultaneous retention 1a: A caller that retries a placement whose answer was lost MUST read the record as carrying two retentions.
Simultaneous retention 2: The atom MUST gate a purge against the purging retention's own retention deadline.
Simultaneous retention 3: The atom MUST NOT read a sibling retention over one record reference.
Simultaneous retention 4: IF a retained retention over the record EXISTS whose purge eligible EQUALS no THEN a composing pattern MUST NOT destroy the record.
Simultaneous retention 4a: IF no composing pattern owns the destruction AND a retained retention over the record EXISTS whose purge eligible EQUALS no THEN a composing pattern MUST NOT purge a retention over the record.
Simultaneous retention 5: A deployment that places two retentions over one record MUST compose a pattern that owns joint enforcement AND MUST place through that pattern alone AND MUST purge through that pattern alone (Composition note 3).
Simultaneous retention 6: The pattern that owns joint enforcement MUST serialize a placement, the sibling read, a purge and a destruction over one record reference.
Simultaneous retention 6a: IF a composing pattern owns the destruction THEN that pattern MUST own joint enforcement.
```

Term sibling retention: another retention over the same record reference.

Term joint enforcement: the rule over every retention on one record that Simultaneous retention 4 and Simultaneous retention 4a state; a composing pattern's.

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern over a regulated Event Log instance MUST place an appended event under retention.
Composition note 3: A composing pattern MUST own joint enforcement across retentions over one record.
Composition note 4: A composing pattern MUST own the policy the pattern places a record under.
Composition note 5: This atom's invariant numbers MUST stand as a frozen contract surface.
```

NOTE: composing patterns — [Defensible Retention](../compositions/defensible-retention.md), [Audit Trail](../compositions/audit-trail.md). Forthcoming: Storage Tier, Cryptographic Shredding, Erasure Coordination, Policy Registry, Trusted Timestamping.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the deployment (also: a high-assurance deployment); a composing pattern (also: a pattern, a writer); a business caller; a caller; a reader; an auditor; the policy registry; the retention records; the storage layer; a retention; a record; a policy; a purge.

Term records: retention — one obligation, carrying retention id, record reference, policy reference, retention instant, retention deadline, purge deadline, a retention state and, once purged, purge instant.

Term record verbs: identify, allocate, supply, reuse, compare, round, carry, stand, set, store, offer, hold, record, answer, read, resolve, stamp, judge, leave, refuse, write, derive, change, delete, shrink, share, admit, gate, destroy, retry, alert, coordinate, confirm, serialize, own, disagree, compose, place, define, version, retain, permit, purge, choose, suspend, renumber, add, find, compute, reconstruct, declare, exceed, bound, evaluate.

Term value sets: retention state = retained | purged. purge eligible = yes | no. database read = answered | failed.

Term bounds: duration (the policy's retention period); max purge delay (the lag the policy allows); retention deadline; purge deadline.

Term cadences: empty — a purge cadence is the composing pattern's.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: zero duration, degenerate duration, now, retention, retention id, record reference, policy reference, seam, transition, business caller, retention state, retention instant, retention deadline, purge deadline, purge instant, overshoot, active overdue, duration, max purge delay, purge eligible, time resolution, well-formedness check, storage layer, owns the destruction, standing record, withheld record, sibling retention, joint enforcement, database read, placement refusal order, purge refusal order.

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

The read-only query answering every retention the database holds, [Retained] and [Purged], each with its stored fields and, while [Retained], the [Purge Eligible] projection derived against the injected [Now]. It changes nothing, and refuses only a call whose read of the database fails, with [State Unavailable].

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

The wall-time the retention was purged, stamped from the injected [Now] on [Purge]. Present only in [Purged]. Its relation to [Purge Deadline] is what makes [Overshoot] computable from the record alone.

Kind:       Field
Field of:   Retention Window
Projection: purged_at

#### Purge Eligible

The derived read-surface projection that reads yes exactly when a retention is still [Retained] *and* its period has elapsed — `state = Retained ∧ [Now] ≥ [Retention Deadline]`. It is a pure function of the stored record and the injected [Now], computed at read time and **never stored** (Invariant 11). It is the same predicate the [Purge] guard evaluates.

Kind:       Field
Field of:   Retention Window
Projection: purge_eligible

#### Overshoot

The derived metric, for a [Purged] retention, of [Purge Instant] − [Purge Deadline] when positive — the amount by which purge ran late. Computable from the records alone; surfaced to compliance dashboards but never stored. It is the data-minimization finding the audit reads from the record itself.

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

The refusal either [Place Under Retention] or [Purge] returns when the database write fails after all preconditions pass, and the refusal [Purge] returns when the storage layer does not confirm the destruction (Record divergence 2). For [Purge] the retention remains in [Retained] — the record may or may not be gone, and the retry settles it. The caller must treat it as definitive; a purge is retried (Purge persistence 2).

Kind:       Member
Member of:  the Place Under Retention / Purge rejection
Role:       Outcome
Projection: storage-failure

#### State Unavailable

The refusal [Place Under Retention], [Purge] or [Read] returns when the read the call makes of the database fails — the Execution Contract's Step 1 failure (Operation 34). Nothing is decided or written, and the call may be retried.

Kind:       Member
Member of:  the Place Under Retention / Purge / Read rejection
Role:       Outcome
Projection: state-unavailable

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
[State Unavailable]: #state-unavailable

---

## Standards references

Retention Window is one of the most heavily standardized concepts in compliance; its standards inheritance is correspondingly rich:

- **ISO 15489-1 (Information and documentation — Records management)** — the International Organization for Standardization's standard for records-management practice. Defines retention as a managed lifecycle with policy-governed start, retention period, and disposition. The atom's two-state model is the operational core of ISO 15489's lifecycle framing.
- **GDPR Article 5(1)(e) — Storage limitation principle** — personal data must be kept *no longer than necessary*. The atom's [Overshoot] metric is the operational form of GDPR's data-minimization audit; persisting personal data past [Purge Deadline] is a violation surfaced by the record itself.
- **HIPAA section 164.530(j) — Documentation retention** — 6-year federal baseline for required HIPAA documentation; state law commonly extends this for clinical records. The atom's [Policy Reference] carries the applicable rule; the host system reconciles federal-state-policy overlap.
- **Sarbanes-Oxley section 802 — Retention of records relevant to audits and reviews** — 7-year retention for audit workpapers, with criminal penalties for early destruction. The atom's no-early-purge invariant is the structural fix for SOX section 802's anti-shredding mandate.
- **SEC Rule 17a-4 — Records to be preserved by certain exchange members, brokers, and dealers** — 3-to-7-year retention with specific access-tier requirements (first two years immediately accessible). Storage-tier sub-requirements compose with Storage Tier; the retention obligation itself is this atom.
- **FINRA Rule 4511 — General requirements for books and records** — incorporates SEC retention rules for FINRA-registered entities.
- **21 CFR Part 11 — FDA electronic records and electronic signatures** — records covered by Part 11 are retained for the longer of the predicate-rule period or 7 years; destruction must be authorized and audited. Composes with Actor Identity for the destruction-authorization attestation.
- **DoD 5015.02-STD — Design criteria standard for electronic records management software applications** — the U.S. government's records-management software baseline. The atom's separation of retention obligation from storage tier and from disposition mechanism matches DoD 5015's architecture.
- **PCI DSS Requirement 3 — Protect stored cardholder data** — including 3.1 (data retention and disposal). The atom carries the *as briefly as possible* posture by allowing very short policy durations.
- **IRS retention guidelines (Publication 583, etc.)** — generally 3-year retention for tax records, longer for specific circumstances (assessments, fraud, employment tax). [Policy Reference] encodes the rule.
- **NARA General Records Schedules (U.S. federal)** — government-wide retention schedules; the policy registry the atom composes with would normally derive from NARA for federal-agency deployments.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of composing storage tier, legal hold, cryptographic shredding, and policy registry as separate concepts.
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
last gate: 2026-10-20 — Final Critique 8, the council's first round on the page and the first on its Store-contract rewrite (c245201), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS MiniMax M3.1 Flash, Linus MiMo V2.6 Flash), each handed only the round's reading set, three passes on one text (frozen at 61d7b6b); the round rests on three counted passes — foundational count 7 after triage (13 reports, 3 sent down to refining, 1 rejected), all Kind A: a failed read of the retention store had no answer the page allowed, [Read] being forbidden to refuse and no signature naming state-unavailable; an unreadable policy registry answered state-unavailable, the Execution Contract's failed store read, on no refuses line, and co-fired with invalid-policy under Operation 7a and Operation 8b; Record divergence 2b forbade a destruction whose confirmation reaches [Purge] after [Purge] has answered, which no storage layer can foresee; Capability requirement 7 had the deployment retain the destroyed record itself; Check 3.2 failed a conforming deployment whenever the auditor's clock and the read's fell either side of a retention deadline; and Term retention deadline and Term purge deadline left out the rounding State 6a applies; 17 refining reports, 5 rhetorical reports; not clean; every foundational finding cured in place; 2026-10-03 — Final Critique 7, fresh reader, three passes — 0 foundational, 51 refining reports, 16 rhetorical reports

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
- 2026-10-03-m · refining · acronyms; edge-case labels · SEC, FDA, DoD, IRS, NARA and CVV are not spelled out, four label families do not name their headings, and five rules carry two obligations → mechanical
- 2026-10-05-a · refining · Operation 29; [Read] · the read answers every retention of the instance with no key, so a composing pattern's read by retention id or by record is a whole-database enumeration under its lease, and no answer on a read is left to the composer → a keyed read; an arm; reported by Defensible Retention's and Resolve a Person's Data Rights' gates
- 2026-10-20-a · refining · Term seam; Operation 6, 8b, 8c, 24b; Term degenerate duration · the rules answer on the registry's reply, on a max purge delay the host could not resolve and on the instants the database holds, which the transition may not read (Operation 26) and the seam does not list among the values the host injects, and an unresolved delay has no term as an unresolved duration does → list each injected value; a term for the delay
- 2026-10-20-b · refining · Record divergence; Simultaneous retention; Purge persistence 1a; Capability requirement 4 through 7 · destruction, the confirmation an owning pattern records and undestroyed carry rules and are declared nowhere, Term storage layer declaring only the storage layer's confirmation → declare each
- 2026-10-20-c · refining · Summary; Rejection paths · the Summary and the premature-purge example equate a purge with destroying the record, while a composing pattern that owns the destruction leaves the purge ending the obligation alone (Record divergence 4) → say so wherever the purge is described
- 2026-10-20-d · refining · Operation 8c, 19, 20; Storage Failure · Operation 8c holds a placement's deadlines inside the instants the database holds and nothing holds the purge instant there, so a purge past them destroys the record and then cannot write, and no retry settles it as the Storage Failure entry says → bound the purge instant or name the arm
- 2026-10-20-e · refining · External check 5; State 4a · the check selects retentions whose retention instant precedes the destruction instant, and State 4a rounds the retention instant up, so a retention placed before a destruction can round past it and fall outside the check → compare at the time resolution
- 2026-10-20-f · refining · Simultaneous retention 3; Operation 29; Check 5.1 · the atom may not read a sibling retention, while the read answers every retention and Check 5.1 groups them by record reference → bind Simultaneous retention 3 to the purge gate
- 2026-10-20-g · refining · Composition note 3; Simultaneous retention 5 · Composition note 3 has every composing pattern own joint enforcement, while Simultaneous retention 5 asks it only of a deployment that places two retentions over one record → one owner, one trigger
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/retention-window.md`; the rounds and the migration that got it here are in [its history](./retention-window.hist.md).

- **2026-10-03 — A composing pattern may own the destruction, and where none does the destruction is confirmed before the retention reads purged.** *Chose:* destruction ownership per instance, declared by the pattern as a capability requirement and fixed for the instance's life; an owner that destroys only what a purged retention names, records each confirmation and retries every standing record nothing withholds (Record divergence 4 through 6, Term standing record, Term withheld record, External check 4); and, where the instance destroys, the storage layer confirming before the write, a dead request once the purge has answered, and one path by which a record is destroyed, its instant recorded (Record divergence 1 through 2b, Capability requirement 4 through 7, External check 5). *Over:* the three rules that bound every instance to coordinate and confirm a destruction and gave neither an order nor a failure reading; and over making every purge the transition alone, which would have rewritten what purge means for Defensible Retention. *Because:* Audit Trail's cascade must write its destruction record after the transition and cannot have purge wait on a mechanism purge has no view of (its Capability requirement 9, Ledger line 2026-10-03-a there), and a fresh reader of the first round found the unordered rule admitted a retention reading purged over a standing record with nobody retrying. Compositions affected: Audit Trail takes the ownership; Defensible Retention keeps a purge that destroys.

- **2026-10-03 — Joint enforcement is one pattern's, on the purge call where purge destroys and on the destruction where a pattern owns it.** *Chose:* a destruction forbidden while a retained sibling is not yet eligible, a purge forbidden under the same condition where purge destroys, a deployment with two retentions over one record obliged to compose the pattern and to place and purge through it, the pattern serializing placement, sibling read, purge and destruction per record reference, one record's retentions in one instance, and a retried placement read as a second retention (Simultaneous retention 1a, 4, 4a, 5, 6, 6a, Capability requirement 10, 11, Non-goal 14, 15). *Over:* a rule that let a record be destroyed only if every retention over it was purge eligible, which a purged retention can never be. *Because:* three passes each reached a record destroyed under a live sibling by a different route — a bare deployment, a placement racing the sibling read, a second instance. Compositions affected: Defensible Retention serializes holds against the purge and not placements (its Ledger line 2026-10-03-a).

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the retention store supplied under Execution Contract Store 1 through 4 (Capability requirement 12), and the five rules that restated them tombstoned to their owner — Operation 10 and Invariant 10.3, no partial retention, to Store 1; Concurrency 1, every state transition atomic per retention id, to Store 1 and Store 2; Concurrency 2 and 3, two purges of one retention serialized and the second answering on what the first committed, to Store 2; rules 158 to 154. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The destruction, its confirmation, a caller's retry and the serialization over one record reference stay as they were (Record divergence, Purge persistence, Simultaneous retention 6): each reaches past one action's write to the retention store. What the atom does for its domain is unchanged.

- **2026-10-20 — A failed read answers on every action, each writing action's refusals answer in one stated order, and a late confirmation breaks no rule.** *Chose:* state-unavailable on all three actions where the read of the retention store fails, the Execution Contract's Step 1 failure (Operation 34, Term store read), [Read] refusing nothing else and answering every retention only on an answered read (Operation 29, Operation 33); an unreadable policy registry answered by its own refusal, registry-unavailable, on [Place Under Retention]'s refuses line (Operation 24b, Operation 24c), and invalid-policy answered only on a registry the host read (Operation 8a); one stated order over the refusals of [Place Under Retention] and of [Purge], the store read first (Operation 35, Operation 36, Term placement refusal order, Term purge refusal order); Record divergence 2b deleted to Capability requirement 4a; the deployment retaining each destruction's recorded instant, not the destroyed record (Capability requirement 7); the auditor deriving purge eligible on the auditor's own clock (Check 3.2); both deadlines declared as State 6a rounds them. *Over:* a read forbidden to refuse a store it cannot read; a registry outage reported as the store's own failure, on no signature and beside invalid-policy; a storage layer forbidden a destruction whose confirmation it cannot know will arrive in time; an auditor's reproduction that the skewed clocks Clock semantics 3 allows make fail. *Because:* Final Critique 8 found each a divergence between conforming builds or a rule no conforming build could keep, and the corpus already held the cure for the first three: Actor Identity's fifth round answers a failed store read with state-unavailable on every action and an unreachable registry with its own refusal, and the maintainer's ruling of 2026-10-19 on Verified Repair answers each action's refusals in one stated order. Compositions affected: the pages that compose this atom route registry-unavailable and state-unavailable when their rounds read them.

NOTE: End of Retention Window.
