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

Retention Window enforces the rule that a record must be kept for a minimum period and only then becomes eligible for destruction. For every managed record it stores which retention policy applies, when the keep-period ends, and the latest date by which destruction is expected. It blocks early deletion outright. Trying to destroy ("purge") a record before its period is up is refused. It also makes overdue records visible: anything still kept past its deadline shows up in the data as an "overshoot" that a compliance dashboard can spot, without anyone having to explain it. Two dates are fixed when a record is placed under retention: the earliest date destruction is allowed, and the latest date it is expected. The span between them is the window in which destruction is both permitted and expected. The pattern enforces the early boundary — no destruction before the period ends. It only observes the late one. A record destroyed past its deadline is flagged in the records as a finding, not refused, because refusing a late destruction would only make the overdue situation worse. This is the mechanism behind multi-year retention of financial and medical records, data-minimization rules for payment-card data, and contract retention that outlasts the deal. It does not handle where records physically live, litigation holds, or privacy-law erasure — those are separate patterns.

---

## Intent

WHY:
A regulated record has two deadlines and they point opposite ways: keep it long enough, and do not keep it longer. Too-early destruction breaks a retention obligation; too-late destruction breaks data minimization. Both are auditable, and a system that holds the rule in a scheduler, a runbook or a cron comment cannot prove either. This atom makes the obligation a record: what is retained, under which policy, from when, until when, and by when it should be gone. It enforces the first deadline structurally — purge before the retention period elapses is refused — and it observes the second rather than enforcing it, because refusing a late purge would compound the very overshoot it detects. Everything else a retention regime needs — what a policy says, what a hold suspends, what destruction means on immutable storage, who authorized it — is a composing pattern's, and the atom names each limit rather than pretending to cover it.

## Structure

### Identity model

```text
Identity 1: The atom MUST identify a retention by the retention_id.
Identity 2: The host MUST allocate a retention_id at the atom's seam.
Identity 3: The transition MUST NOT allocate a retention_id.
Identity 4: The business caller MUST NOT supply a retention_id.
Identity 5: The atom MUST NOT reuse a retention_id.
Identity 6: The atom MUST NOT identify a retention by the record_ref.
Identity 7: The atom MUST NOT identify a retention by the policy_ref.
Identity 8: The atom MUST NOT identify a retention by retained_at.
Identity 9: Two retentions over one record MUST carry two retention_ids.
```

Terms › `retention`: one recorded obligation over one record under one policy — a [Retention Window] instance's record.

Terms › `retention_id`: the opaque value naming one retention — a [Retention Id].

Terms › `record_ref`: the opaque reference naming what is retained — a [Record Ref]; the host owns what a record is.

Terms › `policy_ref`: the opaque reference naming which rules apply — a [Policy Ref]; the policy registry is a separate concept.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading, the retention_id and the resolved policy scalars here.

Terms › `transition`: the atom's evaluation of one call against the retention store, as `execution-contract.md` §Logic confinement declares it.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

WHY:
Identity by record and policy together would collapse the policy-transition case the regime actually produces — an old retention completing while a new one runs over the same record — and identity by time would lose two concurrent placements (Identity 6–9). One retention, one id, is what lets an auditor read a record's policy history as a sequence.

### State

```text
State 1: EVERY retention MUST stand in EXACTLY ONE OF retained, purged.
State 2: EVERY retention MUST carry retention_id, record_ref, policy_ref, retained_at, retention_until and purge_deadline.
State 3: A purged retention MUST carry purged_at.
State 4: [Place Under Retention] MUST set retained_at from the injected now.
State 5: [Place Under Retention] MUST set retention_until from the policy's duration.
State 6: [Place Under Retention] MUST set purge_deadline from the policy's max_purge_delay.
State 7: The atom MUST NOT store purge eligibility.
State 8: The atom MUST NOT offer a restore surface.
State 9: The atom MUST NOT offer a policy-change surface.
State 10: The atom MUST NOT hold a storage tier.
```

Terms › `retention state`: `retained` | `purged` — under obligation, or destroyed and terminal.

Terms › `retained_at`: the instant the retention was placed, stamped from the injected now — a [Retained At].

Terms › `retention_until`: `retained_at + duration` — a [Retention Until]; the instant the obligation ends.

Terms › `purge_deadline`: `retention_until + max_purge_delay` — a [Purge Deadline]; the latest the regulator expects destruction.

Terms › `purged_at`: the instant the purge was recorded, stamped from the injected now — a [Purged At].

Terms › `duration`: the retention period the policy carries — a [Duration]; positive.

Terms › `degenerate duration`: a duration that does not carry retention_until past retained_at at the deployment's time resolution — a positive number too small to make a deadline, or a number in a policy that names no unit.

Terms › `max_purge_delay`: the lag the policy allows between retention-end and purge — a [Max Purge Delay]; not negative.

Terms › `purge eligible`: `yes` | `no` — a [Purge Eligible]; `yes` exactly when the retention stands in retained AND retention_until has passed against the injected now. Derived at the moment a question is asked, never written; the card's `purge_eligible` is the projection of this answer.

WHY:
Two states and no third: a storage tier is an orthogonal axis a Storage Tier pattern *(forthcoming)* owns, and a record moves from active to cold storage without its obligation changing (State 10). Eligibility is derived rather than stored because a stored flag lags the clock — nothing fires when a retention crosses `retention_until`, no scheduler runs, and the only write is the purge that actually happened (State 7, Invariant 11.1). There is no un-purge and no policy edit: extending an obligation means a new retention under a new policy, which is a new audit record rather than a quiet overwrite of an old one (State 8, State 9).

### Operations

```
place_under_retention(record_ref, policy_ref) → retention_id | rejected(invalid-request | invalid-policy | policy-not-found | storage-failure)
purge(retention_id) → ok | rejected(not-known | not-retained | retention-period-not-elapsed | storage-failure)
```

```text
Operation 1: [Place Under Retention] MUST record EXACTLY ONE retention per successful call.
Operation 2: [Place Under Retention] MUST stand the retention in retained.
Operation 3: [Place Under Retention] MUST answer retention_id.
Operation 4: IF record_ref is blank THEN [Place Under Retention] MUST answer invalid-request.
Operation 5: IF policy_ref is blank THEN [Place Under Retention] MUST answer invalid-request.
Operation 6: IF the policy_ref NOT EXISTS in the registry THEN [Place Under Retention] MUST answer policy-not-found.
Operation 7: IF the policy's duration is not positive THEN [Place Under Retention] MUST answer invalid-policy.
Operation 7a: IF the policy's duration = degenerate duration THEN [Place Under Retention] MUST answer invalid-policy.
Operation 8: IF the policy's max_purge_delay is negative THEN [Place Under Retention] MUST answer invalid-policy.
Operation 9: IF the retention store refuses the write THEN [Place Under Retention] MUST answer storage-failure.
Operation 10: [Place Under Retention] MUST NOT record a partial retention.
Operation 11: [Place Under Retention] MUST NOT read the host's record store.
Operation 12: [Purge] MUST stand the retention in purged.
Operation 13: [Purge] MUST stamp purged_at from the injected now.
Operation 14: IF the retention_id NOT EXISTS THEN [Purge] MUST answer not-known.
Operation 15: IF the retention stands in purged THEN [Purge] MUST answer not-retained.
Operation 16: IF purge eligible = no THEN [Purge] MUST answer retention-period-not-elapsed.
Operation 17: [Purge] MUST NOT write on retention-period-not-elapsed.
Operation 18: [Purge] MUST NOT refuse a call past purge_deadline.
Operation 19: IF the retention store refuses the write THEN [Purge] MUST answer storage-failure.
Operation 20: [Purge] MUST leave the retention in retained on storage-failure.
Operation 21: [Purge] MUST read one now per call.
Operation 22: [Purge] MUST judge eligibility and stamp purged_at against that one now.
Operation 23: The host MUST read the clock at the atom's seam.
Operation 24: The host MUST resolve the policy at the atom's seam.
Operation 25: The transition MUST NOT read a clock.
Operation 26: The transition MUST NOT read the policy registry.
Operation 27: The business caller MUST NOT supply now.
Operation 28: A reader MUST derive purge eligible from retention_until and the injected now.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the retention store |
|---|---|---|---|
| [Place Under Retention] | refs well-formed, policy resolves and is valid, store accepts | `retention_id` | one retention lands in [Retained] with its two deadlines (Operation 1, State 4–6) |
| [Place Under Retention] | blank `record_ref` or `policy_ref` | [Invalid Request] | none (Operation 4, Operation 5) |
| [Place Under Retention] | policy_ref resolves to nothing | [Policy Not Found] | none (Operation 6) |
| [Place Under Retention] | duration not positive, or delay negative | [Invalid Policy] | none (Operation 7, Operation 8) |
| [Place Under Retention] | store refuses the write | [Storage Failure] | none — no partial record (Operation 9, Operation 10) |
| [Purge] | no retention under that id | [Not Known] | none (Operation 14) |
| [Purge] | retention already purged | [Not Retained] | none (Operation 15) |
| [Purge] | retention period not elapsed | [Retention Period Not Elapsed] | none — the guard writes nothing (Operation 16, Operation 17) |
| [Purge] | eligible, store accepts | `ok` | [Retained] → [Purged], `purged_at` stamped (Operation 12, Operation 13) |
| [Purge] | eligible, past `purge_deadline` | `ok` | the same — lateness is observable, never refused (Operation 18) |
| [Purge] | eligible, store refuses the write | [Storage Failure] | none — the retention stays [Retained] (Operation 19, Operation 20) |
| *a retention crossing `retention_until`* | — | *nothing* | nothing is written; eligibility is read (State 7, Operation 28) |

WHY:
The refusal order is carried by each rule's own condition rather than by the order the rules sit in (`GRACE-lang.md` Hard invariant 15): identity and state answer first, the time gate next, the store last. The gate writes nothing when it refuses, which is what makes *no early purge* a structural guarantee rather than a logged intention (Operation 16, Operation 17, Invariant 7.1). A purge past the deadline is accepted on purpose: the regulator already expects the record gone, and refusing would keep it (Operation 18). One clock reading per call closes the window two readings would open between the gate and the stamp — the residual risk is a dishonest clock, not an internal race (Operation 21, Operation 22, Invariant 8.2).

### Invariants

- **Invariant 1 — Membership exclusivity.**
  ```text
  Invariant 1.1: EVERY retention MUST stand in EXACTLY ONE OF retained, purged.
  ```
- **Invariant 2 — Retain-then-Retained persistence.**
  ```text
  Invariant 2.1: A recorded retention MUST stand in retained ONLY IF [Purge] NOT EXISTS for the retention.
  ```
- **Invariant 3 — Terminal absorption.**
  ```text
  Invariant 3.1: A purged retention MUST NOT stand in retained again.
  Invariant 3.2: The atom MUST NOT offer an un-purge.
  ```
- **Invariant 4 — Id stability.**
  ```text
  Invariant 4.1: [Place Under Retention] MUST set the retention_id.
  Invariant 4.2: A retention_id MUST NOT change.
  ```
- **Invariant 5 — Record_ref and policy_ref immutability.**
  ```text
  Invariant 5.1: A retention's record_ref MUST NOT change.
  Invariant 5.2: A retention's policy_ref MUST NOT change.
  ```
- **Invariant 6 — Retention window monotonicity.**
  ```text
  Invariant 6.1: retained_at MUST NOT EXCEED retention_until.
  Invariant 6.2: retention_until MUST NOT EXCEED purge_deadline.
  NOTE: Invariant 6.3 deleted — Operation 7 and Operation 7a own a duration that does not advance the deadline, and an invariant restating a precondition is a second owner.
  ```
- **Invariant 7 — No early purge.**
  ```text
  Invariant 7.1: A retention MUST NOT stand in purged WHILE purge eligible = no.
  ```
  WHY: this is the regulator's structural guarantee that an obligation cannot be silently shortened, and it is gated per retention_id — a retention's own retention_until and nothing else (Simultaneous retention 1–4).
- **Invariant 8 — Purge timestamp consistency.**
  ```text
  Invariant 8.1: retention_until MUST NOT EXCEED purged_at.
  Invariant 8.2: The implementation MUST supply an honest now.
  Invariant 8.3: The atom MUST NOT bound purged_at by purge_deadline.
  ```
  WHY: overshoot is observable and never forbidden, which is what lets an auditor measure it instead of watching a system refuse to record it (Invariant 8.3).
- **Invariant 9 — No id reuse.**
  ```text
  Invariant 9.1: Two retentions MUST NOT share a retention_id.
  ```
- **Invariant 10 — Retention store durability.**
  ```text
  Invariant 10.1: The atom MUST NOT delete a retention record.
  Invariant 10.2: The retention set MUST NOT shrink.
  Invariant 10.3: A storage-failure MUST NOT leave a partial retention.
  ```
  WHY: the purged record is the audit evidence that destruction was lawful; deleting it destroys the proof that the atom existed to produce.
- **Invariant 11 — Purge-eligibility is derived, never stored.**
  ```text
  Invariant 11.1: A retention record MUST NOT carry an eligibility flag.
  Invariant 11.2: A reader MUST derive purge eligible from the retention's state, retention_until and the injected now.
  Invariant 11.3: The atom MUST NOT write when a retention crosses retention_until.
  ```

Membership exclusivity and terminal absorption give the *audit-friendly* property — once purged, irrecoverable, with durable evidence of the destruction. No early purge gives the *retention-honored* property. Timestamp consistency lets an auditor compute overshoot from the records without trusting an external clock. Derived eligibility is what lets readiness be read without a scheduler and without a flag that drifts.

## Examples

The same atom, five regulated domains, identical mechanic.

### Banking — transaction-record retention under SOX

A bank places every settled transaction under retention with a 7-year policy (`policy_sox_settled_txn`: duration = 7 years, max_purge_delay = 30 days) via [Place Under Retention]. At the seven-year mark, the records' [Purge Eligible] projection flips to `true` (derived from the injected clock, not written); the bank's records-management system lists those records and invokes [Purge] within the 30-day purge window. Each purge is logged for SOX (Sarbanes-Oxley Act — US financial reporting law) §802 audit. An external auditor querying *"any transaction record purged before its 7-year obligation?"* gets the empty set — Invariant 7 guarantees it.

### Healthcare — medical-record retention under HIPAA and state law

A hospital places each patient encounter record under retention with the maximum of HIPAA's (US Health Insurance Portability and Accountability Act) federal 6-year baseline (45 CFR (Code of Federal Regulations) §164.530(j)) and the state's longer requirement (often 10–25 years for adult records, longer for pediatric). The [Policy Ref] captures the applicable rule; the retention's [Retention Until] is the patient-specific deadline. Purges occur on a rolling schedule; the audit reads the retention records to demonstrate compliance with the longer of the applicable rules.

### Payments — cardholder-data retention under PCI DSS

A payment processor places cardholder-data records (PAN — Primary Account Number, the card number; expiration; CVV-substitute tokens — stand-ins for the card security code) under retention with the *shortest* viable policy — typically days for transient transaction data, never longer than business need requires. PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for handling cardholder data) Requirement 3.1 mandates data minimization. The atom's no-early-purge invariant becomes less relevant here (windows are short); the [Overshoot] metric is what the audit primarily surfaces — any cardholder data still [Retained] past [Purge Deadline].

### Communications — broker-dealer communications under SEC Rule 17a-4

A registered broker-dealer places every business communication (email, chat, voice transcript) under retention with policies derived from SEC Rule 17a-4 — generally 3 years, with the first 2 years in immediately-accessible storage. The atom carries the retention obligation; storage-tier transitions (immediately-accessible to less-accessible) belong to a Storage Tier composition. A FINRA (Financial Industry Regulatory Authority) examination reads the retention records to confirm that every required communication was retained for the full period and purged only after.

### Legal — contract retention beyond contract term

A company places each executed contract under retention with policy = max(contract duration + 6 years, statute-of-limitations for relevant claim types). The retention extends past the operational life of the contract because the contract's audit obligations outlive its commercial life. Litigation hold composes by suspending purge eligibility during pending litigation (a Legal Hold composition; out of scope for the atom).

### Rejection paths

**Premature purge attempt.** A records-management system attempts to purge a transaction record four years into a seven-year SOX retention period:

```
purge(retention_id: "ret-0047")          # seam injects now = 2026-06-22T00:00:00Z
→ rejected(retention-period-not-elapsed)
```

The pure eligibility guard evaluates [Now] ≥ [Retention Until] against the seam-injected [Now] and finds it false — [Retention Until] has not been reached; the atom rejects the purge outright and **writes nothing**. No state change occurs; the record remains in [Retained], and its [Purge Eligible] projection reads `false`. The rejection is the structural enforcement of Invariant 7 — early purge is not just refused, it is structurally impossible.

**Policy reference not resolvable.** A host system calls [Place Under Retention] with a policy reference that does not resolve to a known policy:

```
place_under_retention(record_ref: "txn-1188", policy_ref: "policy-obsolete-v1")
→ rejected(policy-not-found)
```

No retention is created. The host system must supply a valid, resolvable policy reference before any retention can be placed.

### Regulated adversarial scenarios

Three scenarios the atom must survive in regulated contexts:

- **Regulator audit — "show me every record purged before its retention period elapsed."** The auditor queries the [Purged] set for any record where [Purged At] < [Retention Until]. Invariant 7 makes this set structurally empty — the precondition on [Purge] prevents it. The auditor sees the empty result as a structural guarantee, not a procedural promise.
- **Data minimization audit — "show me every record still Retained past its purge deadline."** Common under GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Article 5(1)(e) reviews. The auditor reads [Retained] with the injected [Now] and selects records where [Now] > [Purge Deadline] (the [Active Overdue] projection; these are necessarily [Purge Eligible] too, since [Purge Deadline] ≥ [Retention Until]). The atom does not refuse late purges (rejecting them would compound the [Overshoot]), so this query returns a non-empty set when the organization is behind on its purge schedule. The [Overshoot] is the finding; the records themselves are the evidence; the remediation is to [Purge] the listed records and document the lateness.
- **Litigation discovery — "produce all records of type X from 2020-2022."** Counsel queries the host system; the host system reads the retention records to determine which matching records still exist ([Retained]) versus which have been [Purged]. [Purged] records are unrecoverable — that is the atom's terminal-absorption invariant working as designed. The discovery response distinguishes *records retained and produced* from *records lawfully destroyed under the policy in effect at the time*, with the retention records themselves as the audit trail. Litigation hold should have been placed earlier — if it wasn't, that is a Legal Hold composition failure, not a retention failure.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the retention record set, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```text
Check 1.1: An auditor MUST read the policy applied to a record from the retention's policy_ref (State 2).
Check 2.1: An auditor MUST find the set of purged retentions whose purged_at falls below retention_until empty (Invariant 7.1, Invariant 8.1).
Check 3.1: An auditor MUST confirm that no retention record carries an eligibility flag (Invariant 11.1).
Check 3.2: An auditor MUST reproduce the read surface's purge eligible from retention_until and the auditor's own clock (Invariant 11.2, Operation 28).
Check 4.1: An auditor MUST compute a purged retention's overshoot from purged_at and purge_deadline (Invariant 8.3).
Check 4.2: An auditor MUST compute a retained retention's overshoot from purge_deadline and the auditor's own clock (State 2).
Check 5.1: An auditor MUST reconstruct a record's policy history from the retentions sharing the record_ref (Identity 9).
Check 6.1: An auditor MUST identify which composing patterns a deployment wired in (Composition note 1).
```

### External checks

```text
External check 1: An auditor MUST confirm from the deployment's own destruction records that a destroyed record's retentions were EVERY ONE purged (Simultaneous retention 4).
External check 2: An auditor MUST read the composing pattern's joint-enforcement mechanism (Simultaneous retention 3, Composition note 3).
External check 3: An auditor MUST read the deployment's declared time resolution (Operation 7a).
```

NOTE: the atom cannot answer these from the retention store — Simultaneous retention 3 forecloses reading a sibling, so the evidence that joint enforcement happened lives in the composing pattern's records, not here (council read 11).

NOTE: EVERY check names the rule the check tests. The bar is the regulator's question — *was every record's obligation honored, and what is overdue now?* — answered from the records, never from a runtime claim.

## Non-goals

```text
Non-goal 1: The atom MUST NOT hold a record's storage tier.
Non-goal 2: The atom MUST NOT suspend a purge under a legal hold.
Non-goal 3: A deployment under litigation MUST compose a legal-hold pattern.
Non-goal 4: The atom MUST NOT choose the destruction technique.
Non-goal 5: The atom MUST NOT permit an early purge under an erasure request.
Non-goal 6: A deployment facing an erasure request MUST compose an erasure pattern.
Non-goal 7: The atom MUST NOT define a policy.
Non-goal 8: The atom MUST NOT version a policy.
Non-goal 9: The atom MUST NOT retain the atom's own records.
Non-goal 10: The atom MUST NOT record who authorized a purge.
Non-goal 11: A deployment needing an attributable purge MUST compose [Actor Identity](./actor-identity.md).
Non-goal 12: The atom MUST NOT purge two retentions as one write.
```

WHY:
Each of these is a real obligation the atom deliberately declines, and each names the pattern that owns it: a Legal Hold pattern *(forthcoming)* intercepts the purge a hold forbids, since at `retention_until` this atom would otherwise permit it (Non-goal 2, Non-goal 3); Cryptographic Shredding *(forthcoming)* is purge for records that cannot be deleted, and the atom treats deletion and key destruction as one transition (Non-goal 4); Erasure Coordination *(forthcoming)* adjudicates an Article 17 request against a retention obligation, with counsel, because Invariant 7.1 forbids the early purge such a request asks for (Non-goal 5, Non-goal 6); a Policy Registry *(forthcoming)* owns what a policy says and who attests to it (Non-goal 7, Non-goal 8). The atom's own records are subject to retention and the atom does not loop on itself — the host places them under a separate policy (Non-goal 9).

Where the atom breaks down: when the obligation is a function of the record's content — records about a minor retained until majority, which needs a policy lookup against the record itself; when the storage layer cannot make a record irrecoverable after a purge — append-only logs, distributed replicas, backups with their own schedules; when the regulatory clock and the deployment's clock are far apart, which breaks every wall-time deadline at once.

## Edge cases

### Simultaneous retentions over one record

```text
Simultaneous retention 1: The atom MUST admit two live retentions over one record_ref.
Simultaneous retention 2: The atom MUST gate a purge against the purging retention's own retention_until.
Simultaneous retention 3: The atom MUST NOT read a sibling retention over one record_ref.
Simultaneous retention 4: A composing pattern MUST destroy a record ONLY IF EVERY retention over the record is purge eligible.
```

WHY:
This is the atom's sharpest edge and the one a composition must close. Purging the shorter retention destroys the record while a longer obligation over the same record is still live — an obligation this atom never saw, because it lived on another retention_id. Per-retention enforcement is the atom's; joint enforcement across siblings is the composing pattern's, and [Defensible Retention](../compositions/defensible-retention.md) is where it is wired (Simultaneous retention 3, Simultaneous retention 4).

### Purge that does not persist

```text
Purge persistence 1: A caller MUST read storage-failure from [Purge] as the record standing undestroyed.
Purge persistence 2: A caller MUST retry a purge that answered storage-failure.
Purge persistence 3: A high-assurance deployment MUST alert on storage-failure from [Purge].
```

WHY:
A failed placement is a security-shaped failure — the obligation was never recorded. A failed purge is the opposite shape: the obligation was honored and the minimization was not, so the record that should be gone is still there and nothing about the retention looks wrong (Purge persistence 1).

### Divergence between the retention and the record

```text
Record divergence 1: The implementation MUST coordinate the destruction with the state transition.
Record divergence 2: IF the storage layer cannot confirm the destruction THEN [Purge] MUST answer storage-failure.
Record divergence 3: The atom MUST NOT read the record's existence.
```

WHY:
A retention that reads `purged` over a record that still exists is a compliance failure the audit cannot see — the evidence says destroyed and the data says otherwise. The atom signals the storage layer and cannot confirm the outcome itself, so the coordination is the implementation's and the honest answer on an unconfirmed destruction is a refusal (Record divergence 2).

### Concurrency and atomicity

```text
Concurrency 1: The implementation MUST hold EVERY state transition atomic per retention_id.
Concurrency 2: The implementation MUST serialize two purges of one retention_id.
Concurrency 3: The second purge of one retention_id MUST answer not-retained.
```

### Clock semantics

```text
Clock semantics 1: The deployment MUST own the clock's honesty.
Clock semantics 2: The deployment MUST own the clock's monotonicity.
Clock semantics 3: Two readers judging purge eligible under skewed clocks MAY disagree near retention_until.
Clock semantics 4: A deployment whose deadlines carry legal force MUST compose a trusted-timestamping pattern.
```

WHY:
Because eligibility is derived, a brief disagreement between two readers near the boundary costs nothing — no write is at stake, and the binding decision is made by the single `now` injected at the purge (Operation 21, Operation 22, Clock semantics 3).

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A regulated [Event Log](./event-log.md) instance MUST place an appended event under retention.
Composition note 3: A composing pattern MUST own joint enforcement across retentions over one record.
Composition note 4: A composing pattern MUST own the policy the pattern places a record under.
Composition note 5: This atom's invariant numbers MUST stand as a frozen contract surface.
```

WHY:
[Defensible Retention](../compositions/defensible-retention.md) is the composition that names this atom directly: Legal Hold plus Retention Window over an Audit Trail substrate, where purge is blocked while a hold covers the record — this atom supplies `retention_until` and the purge surface, the composition supplies the gate. The regulated-audit stack is [Event Log](./event-log.md), [Actor Identity](./actor-identity.md), this atom and [Tamper Evidence](./tamper-evidence.md), wired by [Audit Trail](../compositions/audit-trail.md), which cites this atom's Invariants 1, 3, 7 and 11 by number — the numbers are a frozen contract surface, additive growth is forward-compatible, and a renumber re-passes every composition that cites one (Composition note 5). That a writer must not renumber is the grammar's rule and stays there (`GRACE-lang.md` Hard invariant 26); what is local — and what this note owns — is that these particular numbers are cited from outside. Forthcoming: Storage Tier, Legal Hold, Cryptographic Shredding, Erasure Coordination, Policy Registry, Trusted Timestamping.

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment (also: a high-assurance deployment); a composing pattern (also: a pattern, a writer); a business caller; a caller; a reader; an auditor; the policy registry; the retention store; the storage layer; a retention; a record; a policy; a purge.

Terms › `records`: `retention` — one obligation, carrying `retention_id`, `record_ref`, `policy_ref`, `retained_at`, `retention_until`, `purge_deadline`, a retention state and, once purged, `purged_at`.

Terms › `record verbs`: identify, allocate, supply, reuse, carry, stand, set, store, offer, hold, record, answer, read, resolve, stamp, judge, leave, refuse, write, derive, change, delete, shrink, share, admit, gate, destroy, retry, alert, coordinate, confirm, serialize, own, disagree, compose, place, define, version, retain, permit, purge, choose, suspend, renumber, add, find, reproduce, compute, reconstruct, declare, exceed, bound.

Terms › `value sets`: place_under_retention answers = retention_id | rejected(invalid-request | invalid-policy | policy-not-found | storage-failure). purge answers = ok | rejected(not-known | not-retained | retention-period-not-elapsed | storage-failure). `retention state` = retained | purged. `purge eligible` = yes | no.

Terms › `bounds`: `duration` (the policy's retention period); `max_purge_delay` (the lag the policy allows); `retention_until`; `purge_deadline`.

Terms › `cadences`: empty — a purge cadence is the composing pattern's (Composition note 1).

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-12).

Terms › `terms`: `degenerate duration`, `now`, `retention`, `retention_id`, `record_ref`, `policy_ref`, `seam`, `transition`, `business caller`, `retention state`, `retained_at`, `retention_until`, `purge_deadline`, `purged_at`, `duration`, `max_purge_delay`, `purge eligible`.

#### Retention Window

The compliance primitive this atom defines: a record is kept under retention for a known period, then becomes eligible for purge. Each retention is its own record with an opaque [Retention Id]; it carries a [Record Ref], [Policy Ref], the derived deadlines [Retention Until] and [Purge Deadline], and (once purged) [Purged At]. It occupies one of two states — [Retained] or [Purged].

Kind: Type

#### Place Under Retention

The behavior the host invokes to record a new retention over a [Record Ref] under a [Policy Ref]. It resolves the policy at the seam, stamps [Retained At] from the injected [Now], computes [Retention Until] and [Purge Deadline] from the injected [Duration] and [Max Purge Delay], records the retention in [Retained], and returns the fresh [Retention Id].

Kind: Operation

#### Purge

The behavior the host invokes to transition a retention to [Purged], destroying the underlying record. It is permitted only once the retention period has elapsed (the pure [Now] ≥ [Retention Until] guard, which writes nothing when it fails); on success it stamps [Purged At] from the same injected [Now]. It does not refuse late purges — the lateness is observed as [Overshoot], not rejected.

Kind: Operation

#### Retention Id

The opaque, immutable identity of a retention, host-allocated at the I/O seam on [Place Under Retention] and never reused. The [Record Ref], [Policy Ref], and the derived deadlines are properties of the retention, not its identity.

Kind:     Field
Field of: Retention Window
Projects: retention_id

#### Record Ref

The opaque reference to *what* is being retained — the record the retention covers. The atom does not interpret it; the host defines what counts as a record and how to reference it. Set on [Place Under Retention], immutable thereafter.

Kind:     Field
Field of: Retention Window
Projects: record_ref

#### Policy Ref

The opaque reference to *which* retention rules apply. The policy registry is a separate concept; the atom requires only that the policy expose a [Duration] and a [Max Purge Delay]. Set on [Place Under Retention], immutable thereafter.

Kind:     Field
Field of: Retention Window
Projects: policy_ref

#### Retained At

The wall-time the retention was placed under retention, stamped from the injected [Now] on [Place Under Retention]. Immutable thereafter. It is the anchor from which [Retention Until] is derived.

Kind:     Field
Field of: Retention Window
Projects: retained_at

#### Retention Until

The earliest time purge is permitted — the end of the retention period, derived once as [Retained At] + [Duration] on [Place Under Retention] and immutable thereafter. The [Purge] guard admits a purge only while [Now] ≥ [Retention Until].

Kind:     Field
Field of: Retention Window
Projects: retention_until

#### Purge Deadline

The latest time the regulator expects purge to occur, derived once as [Retention Until] + [Max Purge Delay] on [Place Under Retention] and immutable thereafter. Operating past it is observable [Overshoot]; the atom observes this bound but does not enforce it.

Kind:     Field
Field of: Retention Window
Projects: purge_deadline

#### Purged At

The wall-time the retention was purged, stamped from the injected [Now] on [Purge]. Present only in [Purged]. Its relation to [Purge Deadline] is what makes [Overshoot] computable from the record alone.

Kind:     Field
Field of: Retention Window
Projects: purged_at

#### Purge Eligible

The derived read-surface projection that reads `true` exactly when a retention is still [Retained] *and* its period has elapsed — `state = Retained ∧ [Now] ≥ [Retention Until]`. It is a pure function of the stored record and the injected [Now], computed at read time and **never stored** (Invariant 11). It is the same predicate the [Purge] guard evaluates.

Kind:     Field
Field of: Retention Window
Projects: purge_eligible

#### Overshoot

The derived metric, for a [Purged] retention, of [Purged At] − [Purge Deadline] when positive — the amount by which purge ran late. Computable from the records alone; surfaced to compliance dashboards but never stored. It is the data-minimization finding the audit reads from the record itself.

Kind:     Field
Field of: Retention Window
Projects: overshoot

#### Active Overdue

The derived metric, for a still-[Retained] retention, of [Now] − [Purge Deadline] when positive — a record overdue for purge that has not yet been purged. Computable from the record and the injected [Now] alone; surfaced as a derived view, never stored.

Kind:     Field
Field of: Retention Window
Projects: active_overdue

#### Now

The current wall-clock reading, pipeline-injected at the single I/O seam (the execution contract supplies `clock_t` there) before a transition runs — never a caller-supplied action parameter. It is consumed to stamp [Retained At] / [Purged At] on a write and to evaluate the pure [Purge] eligibility guard, and it drives the read-time [Purge Eligible] projection; it is never stored under this name.

Kind:         Parameter
Parameter of: Place Under Retention and Purge
Projects:     now

#### Duration

The retention period the policy exposes — the injected scalar from which [Retention Until] is computed. The atom requires it to be positive (Invariant 6). It is resolved from the [Policy Ref] at the seam and consumed by [Place Under Retention]; it is never stored under this name (the stored result is [Retention Until]).

Kind:         Parameter
Parameter of: Place Under Retention
Projects:     duration

#### Max Purge Delay

The maximum allowed lag between retention-end and purge the policy exposes — the injected scalar from which [Purge Deadline] is computed. The atom requires it to be non-negative (Invariant 6). It is resolved from the [Policy Ref] at the seam and consumed by [Place Under Retention]; it is never stored under this name (the stored result is [Purge Deadline]).

Kind:         Parameter
Parameter of: Place Under Retention
Projects:     max_purge_delay

#### Retained

The state of a retention under active retention obligation — placed but not yet purged. A retention enters [Retained] on [Place Under Retention] and leaves it only on [Purge] (to [Purged]). Its retention period may or may not have elapsed.

Kind:      Member
Member of: the retention state
Role:      Outcome

#### Purged

The terminal state of a retention whose underlying record has been destroyed. A retention enters [Purged] on a successful [Purge] and never leaves it — there is no un-purge or restore surface (Invariant 3). The [Purged] record is the audit evidence that the record was lawfully destroyed.

Kind:      Member
Member of: the retention state
Role:      Outcome

#### Invalid Request

The refusal [Place Under Retention] returns when [Record Ref] or [Policy Ref] is malformed — neither contains a non-whitespace character. A guard rejection that fails before any store write; no retention is recorded.

Kind:      Member
Member of: the Place Under Retention rejection
Role:      Outcome
Projects:  invalid-request

#### Policy Not Found

The refusal [Place Under Retention] returns when [Policy Ref] does not resolve to a known policy in the policy registry. Distinct from [Invalid Policy] (a policy that resolves but is invalid). A guard rejection; no retention is recorded.

Kind:      Member
Member of: the Place Under Retention rejection
Role:      Outcome
Projects:  policy-not-found

#### Invalid Policy

The refusal [Place Under Retention] returns when the resolved policy is invalid — its [Duration] is not positive or its [Max Purge Delay] is negative. Distinct from [Policy Not Found] (the policy could not be resolved at all). A guard rejection; no retention is recorded.

Kind:      Member
Member of: the Place Under Retention rejection
Role:      Outcome
Projects:  invalid-policy

#### Not Retained

The refusal [Purge] returns when the [Retention Id] references a retention not currently in [Retained] — it is already [Purged]. An identity/state rejection, checked before the time gate.

Kind:      Member
Member of: the Purge rejection
Role:      Outcome
Projects:  not-retained

#### Not Known

The refusal [Purge] returns when the supplied [Retention Id] references no recorded retention — a lookup miss. An identity/state rejection, checked before the time gate.

Kind:      Member
Member of: the Purge rejection
Role:      Outcome
Projects:  not-known

#### Retention Period Not Elapsed

The refusal [Purge] returns when the eligibility guard finds [Now] < [Retention Until] — the retention period has not yet elapsed. The pure no-early-purge gate (Invariant 7); it writes nothing when it fails.

Kind:      Member
Member of: the Purge rejection
Role:      Outcome
Projects:  retention-period-not-elapsed

#### Storage Failure

The refusal either [Place Under Retention] or [Purge] returns when the store write fails after all preconditions pass. For [Place Under Retention] no retention is recorded; for [Purge] the retention remains in [Retained] and the underlying record is not destroyed. The caller must treat it as definitive and retry.

Kind:      Member
Member of: the Place Under Retention / Purge rejection
Role:      Outcome
Projects:  storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Retention Window]: #retention-window
[Place Under Retention]: #place-under-retention
[Purge]: #purge
[Retention Id]: #retention-id
[Record Ref]: #record-ref
[Policy Ref]: #policy-ref
[Retained At]: #retained-at
[Retention Until]: #retention-until
[Purge Deadline]: #purge-deadline
[Purged At]: #purged-at
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
- **HIPAA §164.530(j) — Documentation retention** — 6-year federal baseline for required HIPAA documentation; state law commonly extends this for clinical records. The atom's [Policy Ref] carries the applicable rule; the host system reconciles federal-state-policy overlap.
- **Sarbanes-Oxley §802 — Retention of records relevant to audits and reviews** — 7-year retention for audit workpapers, with criminal penalties for early destruction. The atom's no-early-purge invariant is the structural fix for SOX §802's anti-shredding mandate.
- **SEC Rule 17a-4 — Records to be preserved by certain exchange members, brokers, and dealers** — 3-to-7-year retention with specific access-tier requirements (first two years immediately accessible). Storage-tier sub-requirements compose with Storage Tier; the retention obligation itself is this atom.
- **FINRA Rule 4511 — General requirements for books and records** — incorporates SEC retention rules for FINRA-registered entities.
- **21 CFR Part 11 — FDA electronic records and electronic signatures** — records covered by Part 11 are retained for the longer of the predicate-rule period or 7 years; destruction must be authorized and audited. Composes with Actor Identity for the destruction-authorization attestation.
- **DoD 5015.02-STD — Design criteria standard for electronic records management software applications** — the U.S. government's records-management software baseline. The atom's separation of retention obligation from storage tier and from disposition mechanism matches DoD 5015's architecture.
- **PCI DSS Requirement 3 — Protect stored cardholder data** — including 3.1 (data retention and disposal). The atom carries the *as briefly as possible* posture by allowing very short policy durations.
- **IRS retention guidelines (Publication 583, etc.)** — generally 3-year retention for tax records, longer for specific circumstances (assessments, fraud, employment tax). [Policy Ref] encodes the rule.
- **NARA General Records Schedules (U.S. federal)** — government-wide retention schedules; the policy registry the atom composes with would normally derive from NARA for federal-agency deployments.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of composing storage tier, legal hold, cryptographic shredding, and policy registry as separate concepts.
- **Eiffel's design-by-contract** — preconditions on [Purge]; named rejection reasons.
- **Linear temporal logic** — retain-then-Retained persistence, terminal absorption, and the no-early-purge precondition expressed as temporal properties.
- **Records management literature** — Ranganathan's principles applied to organizational records; Schellenberg's appraisal theory of which records merit which retention.

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

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/retention-window.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, the refusal order carried by each rule's own condition rather than by the order the rules sit in, the eleven invariant numbers frozen exactly as Audit Trail cites them, Generation acceptance moved ahead of Non-goals as `spec-format.md` requires, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail cites this atom's Invariants 1, 3, 7 and 11 (`tools/grace/cites.py --into retention-window`).

NOTE: End of Retention Window.
