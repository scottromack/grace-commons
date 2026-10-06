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

Term transition: the atom's evaluation of one call against the retention store, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

WHY:
Identity by record and policy together would collapse the policy-transition case the regime actually produces — an old retention completing while a new one runs over the same record — and identity by time would lose two concurrent placements (Identity 6 through 9). One retention, one id, is what lets an auditor read a record's policy history as a sequence.

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

Term retention deadline: `retained_at + duration` — a [Retention Deadline]; the instant the obligation ends.

Term purge deadline: `retention_until + max_purge_delay` — a [Purge Deadline]; the latest the regulator expects destruction.

Term purge instant: the instant the purge was recorded, stamped from the injected now — a [Purge Instant].

Term overshoot: `purged_at - purge_deadline` where positive, for a purged retention — an [Overshoot]; a reader derives it, the atom does not store it and [Read] does not answer it.

Term active overdue: `now - purge_deadline` where positive, for a retained retention — an [Active Overdue]; a reader derives it, the atom does not store it and [Read] does not answer it.

Term duration: the retention period the policy carries, resolved to an elapsed length at the seam (Operation 24a) — a [Duration]; positive.

Term zero duration: a duration of no length — the floor a policy's duration must exceed, and the floor a max purge delay must not fall below.

Term degenerate duration: a duration the host could not resolve to an elapsed length (Operation 24a).

Term max purge delay: the lag the policy allows between retention-end and purge — a [Max Purge Delay]; not negative.

Term purge eligible: yes | no — a [Purge Eligible]; yes exactly when the retention state EQUALS retained AND the injected now does not precede retention deadline. Derived at the moment a question is asked, never written; the term entry's purge eligible is the projection of this answer.

WHY:
Two states and no third: a storage tier is an orthogonal axis a Storage Tier pattern *(forthcoming)* owns, and a record moves from active to cold storage without its obligation changing (State 10). Eligibility is derived rather than stored because a stored flag lags the clock — nothing fires when a retention crosses retention deadline, no scheduler runs, and the only write is the purge that actually happened (State 7, Invariant 11.1). There is no un-purge and no policy edit: extending an obligation means a new retention under a new policy, which is a new audit record rather than a quiet overwrite of an old one (State 8, State 9). An instant or a deadline the store cannot hold exactly is rounded up, the purge instant with them, so a coarse store never admits a purge a fraction of a unit early and never hides a late one (State 4a, State 6a, Operation 13a).

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 4: IF no composing pattern owns the destruction THEN the deployment MUST supply the storage layer, which destroys the record a retention names and confirms the destruction.
Capability requirement 4a: The storage layer the deployment supplies MUST NOT destroy a record under a request once the [Purge] that made the request has answered or has been abandoned.
Capability requirement 5: The deployment MUST declare the time resolution.
Capability requirement 6: IF no composing pattern owns the destruction THEN the deployment MUST destroy a record a retention names from [Purge] alone.
Capability requirement 6a: IF a composing pattern owns the destruction THEN the deployment MUST destroy a record a retention names through that pattern alone.
Capability requirement 7: The deployment MUST record the instant of EVERY destruction of a record a retention names, read from the clock that supplies now, AND MUST retain the record for the life of the instance.
Capability requirement 8: The deployment MUST supply EVERY placement a retention id naming no retention of the retention store.
Capability requirement 9: The deployment MUST NOT supply the same retention id to two placements.
Capability requirement 10: The deployment MUST supply EXACTLY ONE record reference per record AND MUST NOT reuse a record reference for another record.
Capability requirement 11: The deployment MUST place EVERY retention over one record in one [Retention Window] instance.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
```

WHY:
What the deployment supplies, which is what the family means: the clock reading, the storage layer where the instance destroys, the time resolution, the one path a record is destroyed by with the instant of each destruction, an id that names nothing already stored, and one reference per record, never reused, since the atom tells two records apart by reference alone (Capability requirement 1, Capability requirement 4 through 11, Identity 10). One record's retentions sit in one instance, because a sibling is read from one store and a second instance's obligation would be invisible to the purge that destroys the record (Capability requirement 11). The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

### Operations

```
place_under_retention(record_ref, policy_ref)
  answers retention_id
  refuses invalid-request | invalid-policy | policy-not-found | storage-failure

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
Operation 6a: [Place Under Retention] MUST answer policy-not-found ONLY IF EVERY well-formedness check passes.
Operation 7: IF the policy's duration DOES NOT EXCEED the zero duration THEN [Place Under Retention] MUST answer invalid-policy.
Operation 7a: IF the policy's duration EQUALS degenerate duration THEN [Place Under Retention] MUST answer invalid-policy.
Operation 8: IF the zero duration EXCEEDS the policy's max purge delay THEN [Place Under Retention] MUST answer invalid-policy.
Operation 8a: [Place Under Retention] MUST answer invalid-policy ONLY IF EVERY well-formedness check passes.
Operation 8b: IF the host could not resolve the policy's max purge delay to an elapsed length THEN [Place Under Retention] MUST answer invalid-policy.
Operation 8c: IF retention deadline OR purge deadline falls outside the instants the retention store holds THEN [Place Under Retention] MUST answer invalid-policy.
Operation 9: IF the retention store refuses the write THEN [Place Under Retention] MUST answer storage-failure.
Operation 9a: [Place Under Retention] MUST answer storage-failure ONLY IF no other refusal of [Place Under Retention] applies.
Operation 10: [Place Under Retention] MUST NOT record a partial retention.
Operation 11: [Place Under Retention] MUST NOT read the host's record store.
Operation 12: [Purge] MUST stand the retention in purged.
Operation 13: [Purge] MUST stamp purge instant from the injected now.
Operation 13a: [Purge] MUST round purge instant up to the time resolution.
Operation 14: IF no retention EXISTS for the retention id THEN [Purge] MUST answer not-known.
Operation 15: IF the retention state EQUALS purged THEN [Purge] MUST answer not-retained.
Operation 16: IF the retention state EQUALS retained AND purge eligible EQUALS no THEN [Purge] MUST answer retention-period-not-elapsed.
Operation 17: [Purge] MUST NOT write on retention-period-not-elapsed.
Operation 18: [Purge] MUST NOT refuse a call on the ground that purge deadline has passed.
Operation 19: IF the retention store refuses the write THEN [Purge] MUST answer storage-failure.
Operation 19a: [Purge] MUST answer storage-failure ONLY IF no other refusal of [Purge] applies.
Operation 20: [Purge] MUST leave the retention in retained on storage-failure.
Operation 21: [Purge] MUST judge against one injected now per call.
Operation 22: [Purge] MUST judge eligibility and stamp purge instant against that one now.
Deleted: Operation 23. Capability requirement 1 owns it.
Operation 24: The host MUST resolve the policy at the seam of [Place Under Retention] alone.
Operation 24a: The host MUST resolve the policy's duration and the policy's max purge delay to elapsed lengths at the atom's seam.
Operation 24b: IF the host cannot read the policy registry at a placement THEN the host MUST answer state-unavailable AND [Place Under Retention] MUST NOT answer policy-not-found.
Operation 24c: The host MUST answer state-unavailable under Operation 24b ONLY IF EVERY well-formedness check passes.
Deleted: Operation 25. Execution Contract Logic confinement 3 owns it.
Operation 26: The transition MUST NOT read the policy registry.
Deleted: Operation 27. Execution Contract Logic confinement 3 owns it.
Operation 28: A reader MUST derive purge eligible from the retention state, retention deadline and the injected now.
Operation 29: [Read] MUST answer EVERY retention, retained AND purged.
Operation 30: [Read] MUST answer a retention's stored fields.
Operation 31: [Read] MUST answer purge eligible PER retained retention.
Operation 32: [Read] MUST NOT write.
Operation 33: [Read] MUST NOT refuse a call.
```

Term time resolution: the smallest span the deployment's clock and retention store tell apart (Capability requirement 5); fixed for the life of the instance.

Term well-formedness check: Operation 4 and Operation 5 — every check [Place Under Retention] makes on the call's own inputs.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the retention store |
|---|---|---|---|
| [Place Under Retention] | refs well-formed, policy resolves and is valid, store accepts | retention id | one retention lands in [Retained] with its two deadlines (Operation 1, State 4 through 6) |
| [Place Under Retention] | blank record reference or policy reference | [Invalid Request] | none (Operation 4, Operation 5) |
| [Place Under Retention] | policy reference resolves to nothing | [Policy Not Found] | none (Operation 6) |
| [Place Under Retention] | the host cannot read the policy registry | `state-unavailable`, the Execution Contract's effect failure | none — the well-formedness checks passed and no policy was read (Operation 24b, Operation 24c) |
| [Place Under Retention] | duration not positive or unresolved, delay negative or unresolved, or a deadline outside the instants the store holds | [Invalid Policy] | none (Operation 7, Operation 7a, Operation 8, Operation 8b, Operation 8c) |
| [Place Under Retention] | store refuses the write | [Storage Failure] | none — no partial record (Operation 9, Operation 10) |
| [Purge] | no retention under that id | [Not Known] | none (Operation 14) |
| [Purge] | retention already purged | [Not Retained] | none (Operation 15) |
| [Purge] | retention period not elapsed | [Retention Period Not Elapsed] | none — the guard writes nothing (Operation 16, Operation 17) |
| [Purge] | eligible, store accepts | ok | [Retained] → [Purged], purge instant stamped (Operation 12, Operation 13) |
| [Purge] | eligible, past purge deadline | ok | the same — lateness is observable, never refused (Operation 18) |
| [Purge] | eligible, store refuses the write | [Storage Failure] | none — the retention stays [Retained] (Operation 19, Operation 20) |
| [Purge] | eligible, the storage layer does not confirm the destruction | [Storage Failure] | none — the retention stays [Retained] (Record divergence 2, Operation 20) |
| [Purge] | eligible, a composing pattern owns the destruction, store accepts | ok | [Retained] → [Purged]; the record stands until the pattern confirms the destruction (Record divergence 4, Record divergence 5) |
| *a retention crossing retention deadline* | — | *nothing* | nothing is written; eligibility is read (State 7, Operation 28) |
| [Read] | any | every retention, with its stored fields and, while retained, purge eligible | none (Operation 29 through 33) |

WHY:
The refusal order is carried by each rule's own condition rather than by the order the rules sit in (`GRACE-lang.md` Hard invariant 15): identity and state answer first, the time gate next, the store last. The gate writes nothing when it refuses, which is what makes *no early purge* a structural guarantee rather than a logged intention (Operation 16, Operation 17, Invariant 7.1). A purge past the deadline is accepted on purpose: the regulator already expects the record gone, and refusing would keep it (Operation 18). One clock reading per call closes the window two readings would open between the gate and the stamp — the residual risk is a dishonest clock, not an internal race (Operation 21, Operation 22, Execution Contract Logic confinement 7). A policy speaks in calendar terms — seven years, from which day, in which zone — and that reading is the policy's: the host resolves it to an elapsed length before the transition, so two implementations add the same span (Operation 24a). A registry the host cannot read is an infrastructure failure, the Execution Contract's `state-unavailable`, and never a policy that does not exist (Operation 24b).

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
  WHY: this is the regulator's structural guarantee that an obligation cannot be silently shortened, and it is gated per retention id — a retention's own retention deadline and nothing else (Simultaneous retention 1 through 4).
- **Invariant 8 — Purge timestamp consistency.**
  ```
  Invariant 8.1: A purged retention's retention deadline MUST NOT EXCEED the retention's purge instant.
  Deleted: Invariant 8.2. Execution Contract Logic confinement 7 owns it.
  Invariant 8.3: The atom MUST NOT bound purge instant by purge deadline.
  ```
  WHY: overshoot is observable and never forbidden, which is what lets an auditor measure it instead of watching a system refuse to record it (Invariant 8.3).
- **Invariant 9 — No id reuse.**
  ```
  Invariant 9.1: Two retentions MUST NOT share a retention id.
  ```
- **Invariant 10 — Retention store durability.**
  ```
  Invariant 10.1: The atom MUST NOT delete a retention record.
  Invariant 10.2: The retention set MUST NOT shrink.
  Invariant 10.3: A storage-failure MUST NOT leave a partial retention.
  ```
  WHY: the purged record is the audit evidence that the obligation ended lawfully; deleting it destroys the proof that the atom existed to produce.
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
Check 3.2: An auditor MUST reproduce the read surface's purge eligible from the retention state, retention deadline and the auditor's own clock (Invariant 11.2, Operation 28).
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

NOTE: the atom cannot answer these from the retention store — Simultaneous retention 3 forecloses reading a sibling, so the evidence that joint enforcement happened lives in the composing pattern's records, not here (council read 11).

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

WHY:
Each of these is a real obligation the atom deliberately declines, and each names the pattern that owns it: [Legal Hold](./legal-hold.md) records the hold and [Defensible Retention](../compositions/defensible-retention.md) gates the purge a hold forbids, since at retention deadline this atom would otherwise permit it (Non-goal 2, Non-goal 3); Cryptographic Shredding *(forthcoming)* is purge for records that cannot be deleted, and the atom treats deletion and key destruction as one transition (Non-goal 4); Erasure Coordination *(forthcoming)* adjudicates an Article 17 request against a retention obligation, with counsel, because Invariant 7.1 forbids the early purge such a request asks for (Non-goal 5, Non-goal 6); a Policy Registry *(forthcoming)* owns what a policy says and who attests to it (Non-goal 7, Non-goal 8). The atom places none of its own records under retention and does not loop on itself: a retention record stands for the life of the instance, and the atom offers no surface that removes one (Invariant 10, Non-goal 9). Who authorized a purge is [Actor Identity](./actor-identity.md)'s to record (Non-goal 10, Non-goal 11); a purge spanning two retentions is the joint enforcement a composing pattern owns (Non-goal 12, Composition note 3); and a deadline with legal force needs a time source the atom does not have, which Trusted Timestamping *(forthcoming)* owns (Non-goal 13). A placement whose answer was lost and is retried records a second retention over the same record, a sibling like any other (Operation 1, Simultaneous retention 5); at-most-once placement, inside the window it keeps, is [Duplicate Prevention](./duplicate-prevention.md)'s (Non-goal 14, Non-goal 15). Where a composing pattern owns the destruction, overshoot and active overdue stop at the purge: how long a standing record may stand, and the finding when it stands too long, are the owning pattern's (Non-goal 16, Record divergence 6).

Where the atom breaks down: when the obligation is a function of the record's content — records about a minor retained until majority, which needs a policy lookup against the record itself; when the storage layer cannot make a record irrecoverable after a purge — append-only logs, distributed replicas, backups with their own schedules; when the regulatory clock and the deployment's clock are far apart, which breaks every wall-time deadline at once.

## Edge cases

### Clock semantics

```
Clock semantics 3: Two readers judging purge eligible under skewed clocks MAY disagree near retention deadline.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Non-goal 13 owns it.
```

WHY:
Because eligibility is derived, a brief disagreement between two readers near the boundary costs nothing — no write is at stake, and the binding decision is made by the single now injected at the purge (Operation 21, Operation 22, Clock semantics 3).

### Concurrency and atomicity

```
Concurrency 1: The implementation MUST hold EVERY state transition atomic per retention id.
Concurrency 2: The implementation MUST serialize two purges of one retention id.
Concurrency 3: The second purge of one retention id MUST answer not-retained ONLY IF the first purge stood the retention in purged.
```

### Divergence between the retention and the record

```
Record divergence 1: IF no composing pattern owns the destruction THEN [Purge] MUST NOT stand the retention in purged BEFORE the storage layer confirms the destruction.
Record divergence 1a: The host MUST destroy a record through the storage layer ONLY IF [Purge] judged the purging retention purge eligible.
Record divergence 2: IF no composing pattern owns the destruction AND the storage layer cannot confirm the destruction THEN [Purge] MUST answer storage-failure.
Record divergence 2a: The storage layer MUST confirm the destruction of EVERY record of which the storage layer holds no copy.
Record divergence 2b: IF the storage layer does not confirm a destruction THEN the storage layer MUST NOT destroy the record under that request.
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

WHY:
A retention that reads purged over a record that still exists is a compliance failure the audit cannot see — the evidence says destroyed and the data says otherwise. The atom cannot confirm the outcome itself, so the storage layer confirms the destruction before the retention is written purged, and the honest answer on an unconfirmed destruction is a refusal (Record divergence 1, Record divergence 2). A failure at either write then leaves the retention retained and the purge retried: a record destroyed under a retention still reading retained is overdue in plain sight and the retry closes it, the storage layer confirming again what it already destroyed, as it confirms a reference that never named a record it held (Record divergence 2a). A request the storage layer did not confirm is dead, and so is one whose [Purge] has answered or been abandoned, which a deadline or a fence on the request is the deployment's way to hold: a destruction that landed late would land outside any purge, after a sibling may have been placed (Record divergence 2b, Capability requirement 4a), and for the same reason the retry itself waits while a sibling placed since then is not yet eligible (Purge persistence 2, Purge persistence 2a, Simultaneous retention 4a). The host destroys nothing [Purge] did not judge eligible, and the deployment destroys a record a retention names by no path but [Purge], or the owning pattern where one owns the destruction, and records each destruction's instant, kept as long as the retentions they answer for, which is what lets an auditor tell a record gone early from one purged on time (Record divergence 1a, Capability requirement 6, Capability requirement 6a, Capability requirement 7, External check 5). A composing pattern may take the destruction instead (Record divergence 4): a pattern whose destruction has to follow the transition, as [Audit Trail](../compositions/audit-trail.md)'s cascade does, cannot have [Purge] wait on it. The purge is then the state transition alone and comes first — the pattern destroys nothing no purged retention names (Record divergence 4a) — and the failure the audit could not see becomes a record the audit reads: every purged retention with no recorded confirmation names a standing record, and the pattern retries each one nothing forbids destroying — a sibling's live obligation forbids it, and so may a gate the atom knows nothing of, a legal hold being a composing pattern's (Record divergence 5, Record divergence 6, Non-goal 2).

### Purge that does not persist

```
Purge persistence 1: A caller MUST read storage-failure from [Purge] as the retention standing in retained.
Purge persistence 1a: A caller MUST NOT read storage-failure from [Purge] as the record standing undestroyed.
Purge persistence 2: IF Simultaneous retention 4a does not forbid the purge THEN a caller MUST retry a purge that answered storage-failure.
Purge persistence 2a: IF Simultaneous retention 4a does not forbid the purge THEN a caller MUST retry a purge that returned no answer.
Purge persistence 3: A high-assurance deployment MUST alert on storage-failure from [Purge].
```

WHY:
A failed placement is a security-shaped failure — the obligation was never recorded. A failed purge is the opposite shape: the obligation was honored and the minimization was not confirmed, so the record that should be gone may still be there and nothing about the retention looks wrong (Purge persistence 1, Purge persistence 1a).

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

WHY:
This is the atom's sharpest edge and the one a composition must close. Purging the shorter retention destroys the record while a longer obligation over the same record is still live — an obligation this atom never saw, because it lived on another retention id. Per-retention enforcement is the atom's; joint enforcement across siblings is the composing pattern's, and [Defensible Retention](../compositions/defensible-retention.md) is where it is wired (Simultaneous retention 3, Simultaneous retention 4). Where [Purge] destroys, the gate sits on the purge call, which is Defensible Retention's shape; where a composing pattern owns the destruction, it sits on the destruction (Simultaneous retention 4, Simultaneous retention 4a). A deployment with no such pattern, or one that purges around it, would destroy the record at the first sibling's purge, so placing two retentions over one record obliges it to compose one and to place and purge through it (Simultaneous retention 5). The atom serializes per retention id and no wider, so a placement landing between the pattern's sibling read and its purge would put a live retention under a record about to be destroyed; the serialization over the record reference is the pattern's (Simultaneous retention 6).

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern over a regulated Event Log instance MUST place an appended event under retention.
Composition note 3: A composing pattern MUST own joint enforcement across retentions over one record.
Composition note 4: A composing pattern MUST own the policy the pattern places a record under.
Composition note 5: This atom's invariant numbers MUST stand as a frozen contract surface.
```

WHY:
[Defensible Retention](../compositions/defensible-retention.md) is the composition that names this atom directly: Legal Hold plus Retention Window over an Audit Trail substrate, where purge is blocked while a hold covers the record — this atom supplies retention deadline and the purge surface, the composition supplies the gate. The regulated-audit stack is [Event Log](./event-log.md), [Actor Identity](./actor-identity.md), this atom and [Tamper Evidence](./tamper-evidence.md), wired by [Audit Trail](../compositions/audit-trail.md), which cites this atom's Invariants 1, 3, 5, 7, 8, 10 and 11 by number — the numbers are a frozen contract surface, additive growth is forward-compatible, and a renumber re-passes every composition that cites one (Composition note 5). That a writer must not renumber is the grammar's rule and stays there (`GRACE-lang.md` Hard invariant 26); what is local — and what this note owns — is that these particular numbers are cited from outside. Forthcoming: Storage Tier, Cryptographic Shredding, Erasure Coordination, Policy Registry, Trusted Timestamping.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment (also: a high-assurance deployment); a composing pattern (also: a pattern, a writer); a business caller; a caller; a reader; an auditor; the policy registry; the retention store; the storage layer; a retention; a record; a policy; a purge.

Term records: retention — one obligation, carrying retention id, record reference, policy reference, retention instant, retention deadline, purge deadline, a retention state and, once purged, purge instant.

Term record verbs: identify, allocate, supply, reuse, compare, round, carry, stand, set, store, offer, hold, record, answer, read, resolve, stamp, judge, leave, refuse, write, derive, change, delete, shrink, share, admit, gate, destroy, retry, alert, coordinate, confirm, serialize, own, disagree, compose, place, define, version, retain, permit, purge, choose, suspend, renumber, add, find, reproduce, compute, reconstruct, declare, exceed, bound.

Term value sets: retention state = retained | purged. purge eligible = yes | no.

Term bounds: duration (the policy's retention period); max purge delay (the lag the policy allows); retention deadline; purge deadline.

Term cadences: empty — a purge cadence is the composing pattern's.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: zero duration, degenerate duration, now, retention, retention id, record reference, policy reference, seam, transition, business caller, retention state, retention instant, retention deadline, purge deadline, purge instant, overshoot, active overdue, duration, max purge delay, purge eligible, time resolution, well-formedness check, storage layer, owns the destruction, standing record, withheld record, sibling retention, joint enforcement.

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

The read-only query answering every retention the store holds, [Retained] and [Purged], each with its stored fields and, while [Retained], the [Purge Eligible] projection derived against the injected [Now]. It changes nothing and refuses nothing.

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

The earliest time purge is permitted — the end of the retention period, derived once as [Retention Instant] + [Duration] on [Place Under Retention] and immutable thereafter. The [Purge] guard admits a purge only while [Now] ≥ [Retention Deadline].

Kind:       Field
Field of:   Retention Window
Projection: retention_until

#### Purge Deadline

The latest time the regulator expects purge to occur, derived once as [Retention Deadline] + [Max Purge Delay] on [Place Under Retention] and immutable thereafter. Operating past it is observable [Overshoot]; the atom observes this bound but does not enforce it.

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

The terminal state of a retention whose underlying record has been destroyed, or whose destruction a composing pattern owns and confirms in its own records (Record divergence 5). A retention enters [Purged] on a successful [Purge] and never leaves it — there is no un-purge or restore surface (Invariant 3). The [Purged] record is the audit evidence that the obligation ended lawfully.

Kind:      Member
Member of: the retention state
Role:      Outcome

#### Invalid Request

The refusal [Place Under Retention] returns when [Record Reference] or [Policy Reference] is blank. A guard rejection that fails before any store write; no retention is recorded.

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

The refusal [Place Under Retention] returns when the resolved policy is invalid — its [Duration] is not positive or could not be resolved, its [Max Purge Delay] is negative or could not be resolved, or a deadline it would set falls outside the instants the store holds. Distinct from [Policy Not Found] (the policy could not be resolved at all). A guard rejection; no retention is recorded.

Kind:       Member
Member of:  the Place Under Retention rejection
Role:       Outcome
Projection: invalid-policy

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

The refusal either [Place Under Retention] or [Purge] returns when the store write fails after all preconditions pass, and the refusal [Purge] returns when the storage layer does not confirm the destruction (Record divergence 2). For [Place Under Retention] no retention is recorded; for [Purge] the retention remains in [Retained] — the record may or may not be gone, and the retry settles it. The caller must treat it as definitive; a purge is retried (Purge persistence 2).

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

`grounded on Final Critique 7 — 2026-10-03` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 7 — 2026-10-03
formal: not applicable — vote no 2026-06-03
last gate: 2026-10-03 — Final Critique 7, fresh reader, three passes — 0 foundational, 51 refining reports, 16 rhetorical reports

open:
- 2026-10-03-a · refining · Record divergence 1, 1a; Operation 24c · where the instance destroys, the destruction is an external effect between the guard and the write, and the Execution Contract's pipeline has no step for it → name the step or declare the deviation
- 2026-10-03-b · refining · Capability requirement; Operation 24, 24a; Term owns the destruction; Simultaneous retention 5; Purge persistence 3 · the policy registry and its resolved lengths, the ownership setting, the retention store's durability and the alert are the deployment's and sit outside the capability list → list them
- 2026-10-03-c · refining · Record divergence 2b; Term storage layer · a confirmation is an answer received, so a lost reply after a destruction breaks 2b with no way to comply, and Capability requirement 4a already carries the purpose → reword 2b or tombstone it
- 2026-10-03-d · refining · Purge persistence 2, 2a; Term withheld record · the retry is excused by Simultaneous retention 4a alone, and a composing pattern's own gate placed after a storage-failure is not excepted → except what Term withheld record excepts
- 2026-10-03-e · refining · Record divergence 4a through 6; Capability requirement 7 · the destruction's lifecycle (standing, withheld, confirmed) has no owning atom, and the confirmation and the destruction instant are one fact with two owners → Erasure Tombstone, when it lands
- 2026-10-03-f · refining · State 1, 7, 8; Operation 28; Invariant 1.1, 3.2, 11.1, 11.2 · four propositions have two owners each, against the ground Invariant 6.3 was tombstoned on → tombstone the second owner
- 2026-10-03-g · refining · Check 3.2; Clock semantics 3; External check 1, 5 · the auditor reproduces purge eligible on a clock the page lets disagree near the deadline, the checks cover Invariants 7, 8 and 11 alone, and External check 5 subsumes External check 1 → one check, a stated tolerance, a check per invariant
- 2026-10-03-h · refining · Operation 24b, 33; the signature block · `state-unavailable` is landed for a placement and is on no refuses line, and [Purge] and [Read] cite no arm for a store that cannot be read → cite the Execution Contract's effect failure at each
- 2026-10-03-i · refining · Summary; Examples; Standards references · "blocks early deletion outright" holds per retention and not per record, the Healthcare and Legal examples use periods that depend on the record's content, and the discovery scenario reads a record's existence from a retained retention → state each at the level the rules hold
- 2026-10-03-j · refining · Term seam, transition, business caller · each cites a section of the Execution Contract that does not use the term → corpus-wide; the contract's vocabulary, not this atom's
- 2026-10-03-k · refining · Identity 5, 10; Invariant 9.1; Capability requirement 8, 9 · non-reuse has two owners and a colliding id has no refusal arm, and no action performs the comparison Identity 10 obliges → one owner; an arm or a named non-goal
- 2026-10-03-l · refining · Operation 24a; Identity 6; [Read] · the day a calendar period counts from is in a WHY, a reference is checked for blank alone, and [Read] has no order or bound → pin each or name the owner
- 2026-10-03-m · refining · acronyms; edge-case labels · SEC, FDA, DoD, IRS, NARA and CVV are not spelled out, four label families do not name their headings, and five rules carry two obligations → mechanical
- 2026-10-05-a · refining · Operation 29, 33; [Read] · the read answers every retention of the instance with no key, so a composing pattern's read by retention id or by record is a whole-store enumeration under its lease, and state-unavailable or no answer on a read that must not refuse is left to the composer → a keyed read; an arm; reported by Defensible Retention's and Resolve a Person's Data Rights' gates
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/retention-window.md`.

- **2026-10-03 — A composing pattern may own the destruction, and where none does the destruction is confirmed before the retention reads purged.** *Chose:* destruction ownership per instance, declared by the pattern as a capability requirement and fixed for the instance's life; an owner that destroys only what a purged retention names, records each confirmation and retries every standing record nothing withholds (Record divergence 4 through 6, Term standing record, Term withheld record, External check 4); and, where the instance destroys, the storage layer confirming before the write, a dead request once the purge has answered, and one path by which a record is destroyed, its instant recorded (Record divergence 1 through 2b, Capability requirement 4 through 7, External check 5). *Over:* the three rules that bound every instance to coordinate and confirm a destruction and gave neither an order nor a failure reading; and over making every purge the transition alone, which would have rewritten what purge means for Defensible Retention. *Because:* Audit Trail's cascade must write its destruction record after the transition and cannot have purge wait on a mechanism purge has no view of (its Capability requirement 9, Ledger line 2026-10-03-a there), and a fresh reader of the first round found the unordered rule admitted a retention reading purged over a standing record with nobody retrying. Compositions affected: Audit Trail takes the ownership; Defensible Retention keeps a purge that destroys.

- **2026-10-03 — Joint enforcement is one pattern's, on the purge call where purge destroys and on the destruction where a pattern owns it.** *Chose:* a destruction forbidden while a retained sibling is not yet eligible, a purge forbidden under the same condition where purge destroys, a deployment with two retentions over one record obliged to compose the pattern and to place and purge through it, the pattern serializing placement, sibling read, purge and destruction per record reference, one record's retentions in one instance, and a retried placement read as a second retention (Simultaneous retention 1a, 4, 4a, 5, 6, 6a, Capability requirement 10, 11, Non-goal 14, 15). *Over:* a rule that let a record be destroyed only if every retention over it was purge eligible, which a purged retention can never be. *Because:* three passes each reached a record destroyed under a live sibling by a different route — a bare deployment, a placement racing the sibling read, a second instance. Compositions affected: Defensible Retention serializes holds against the purge and not placements (its Ledger line 2026-10-03-a).

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, the refusal order carried by each rule's own condition rather than by the order the rules sit in, the eleven invariant numbers frozen exactly as Audit Trail cites them, Generation acceptance moved ahead of Non-goals as `spec-format.md` requires, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail cites this atom's Invariants 1, 3, 7 and 11 (`tools/grace/cites.py --into retention-window`).

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every retention with its stored fields and, while retained, purge eligible (Operation 29 through 33). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — the retained and purged sets, each retention with its fields, and purge eligibility derived at read time — and the migration dropped it with the section, while Operation 28, Customer Onboarding and Defensible Retention all read the store through it. Restored as the prose had it, not widened. Found beside the same loss in Permissions and Actor Identity, which the cold regeneration of the Attributed Permissions Admin demo surfaced (council read 228).

NOTE: End of Retention Window.
