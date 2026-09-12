---
title: Legal Hold
parent: Atomic Concepts
has_toc: true
toc: true
---

# Legal Hold

<details open markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Legal Hold is a formal instruction to keep a specific record intact — overriding any normal deletion schedule — until the legal matter that triggered it is resolved. When a lawsuit is anticipated, a regulator opens an investigation, or a team needs to freeze evidence, the normal "delete after N years" rule stops applying. The hold records the shift: who issued it, against which record, why, and under what authority. A hold is either [Active] (preservation in effect) or [Released] (lifted, permanently — it cannot be reactivated). Both placing and releasing are attributed, timestamped, and never altered afterward, so the full arc of any preservation obligation can be reconstructed from the records alone. Multiple holds can cover the same record independently — a record under both an internal investigation and a government investigation has two separate obligations, and releasing one leaves the other in force, which is exactly what multi-party legal situations require. The pattern does not itself block deletion; it records that an obligation exists, and the system that actually deletes records is responsible for checking for [Active] holds first. This is the mechanism behind litigation-hold management, breach-response preservation, and any setting where destroying a record during an active legal obligation exposes the organization to penalties.

---

## Intent

WHY:
When litigation is filed or reasonably anticipated, the duty to preserve arrives before anyone knows what will matter, and it overrides every retention schedule the organization has. Destroying a held record is spoliation — sanctions, adverse inference, sometimes the case. So the obligation itself has to be a record: what is held, who decided, why, under which matter, from when, and — when it ends — who lifted it and on what grounds. That record is this atom. It does not stop a purge; it documents an obligation a composing pattern enforces at the purge surface. It does not know what a case is. And it never merges two holds over one record, because two authorities demanding preservation of one document is two obligations, each ending on its own day.

## Structure

### Store instance model

```text
Instance 1: The atom MUST hold every hold under EXACTLY ONE store instance.
Instance 2: Two holds in one store instance MUST NOT share a hold_id.
Instance 3: The atom MUST NOT reach across store instances.
Instance 4: The deployment MUST route a call to one store instance.
Instance 5: [Read] MUST answer the store_name the read was routed to.
Instance 6: A composing pattern MUST match the answered store_name against the record's own store instance.
Instance 7: A composing pattern MUST NOT read an empty answer as unheld WHILE the store_name does not match.
```

Terms › `store instance`: one named hold store — a [Store Name] identifies it; a deployment runs one per organization, jurisdiction or business unit.

### Identity model

```text
Identity 1: The atom MUST identify a hold by the hold_id.
Identity 2: The host MUST allocate a hold_id at the atom's seam.
Identity 3: The transition MUST NOT allocate a hold_id.
Identity 4: The atom MUST NOT reuse a hold_id.
Identity 5: The atom MUST NOT reassign a hold_id.
Identity 6: A hold_id MUST sort in lexicographic byte order.
Identity 7: The atom MUST NOT identify a hold by the record_ref.
Identity 8: Two holds over one record MUST carry two hold_ids.
```

Terms › `hold`: one recorded preservation obligation over one record — the record this atom writes.

Terms › `hold_id`: the opaque value naming one hold — a [Hold Id]; not blank, and sortable so [Read] can order deterministically.

Terms › `blank`: a value that is absent, empty, or carries only whitespace — what every presence check in this atom refuses.

Terms › `record_ref`: the opaque reference naming what is preserved — a [Record Ref]; the host owns whether the record exists.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading and the hold_id here.

Terms › `transition`: the atom's evaluation of one call against the hold store, as `execution-contract.md` §Logic confinement declares it.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, and never supplied by the business caller — `placed_at` and `released_at` are the caller's claims about when an obligation began and ended, judged against `now` and stored as claims (Operation 37–41).

WHY:
Two authorities can demand preservation of one document — a plaintiff's litigation hold and a regulator's investigative demand — and they end on different days. Merging them into one obligation would release the record the moment the first ends, which is the spoliation the atom exists to foreclose (Identity 7, Identity 8, Invariant 4.1). The id sorts because [Read]'s order is part of the contract, not a convenience (Identity 6, Operation 18).

### State

```text
State 1: EVERY hold MUST stand in EXACTLY ONE OF active, released.
State 2: EVERY hold MUST carry hold_id, record_ref, placed_by, hold_reason, placed_at and state.
State 3: A hold MAY carry case_ref.
State 4: A released hold MUST carry released_by, release_reason and released_at.
State 5: An active hold MUST NOT carry released_at.
State 7: The atom MUST NOT delete a hold.
State 8: The atom MUST NOT hold an aggregate for a record.
NOTE: State 6 deleted — Invariant 3.2 owns the absent re-activation.
NOTE: State 9 deleted — Non-goal 9 owns the case lifecycle.
```

Terms › `hold state`: `active` | `released` — the obligation in effect, or documented as ended.

Terms › `placed_by`: the opaque reference naming who placed the hold — a [Placed By]; the attribution anchor for the preservation decision.

Terms › `hold_reason`: the narrative ground the hold was placed on — a [Hold Reason].

Terms › `placed_at`: the instant the obligation was recorded — a [Placed At].

Terms › `case_ref`: the opaque reference naming the matter the hold sits under — a [Case Ref]; absent where no formal matter exists yet.

Terms › `released_by`: the opaque reference naming who ended the obligation — a [Released By].

Terms › `release_reason`: the ground the obligation ended on — a [Release Reason].

Terms › `released_at`: the instant the obligation was documented as ended — a [Released At].

WHY:
There is no aggregate *is this record held* field, because an aggregate is a second copy of the truth that drifts the moment a hold is placed or released; the question is answered by reading the active holds over the record (State 9, Operation 20). A released hold stays in the store because it is the proof the obligation was honoured and lawfully lifted — the evidence a court asks for, deleted by nobody (State 7, Invariant 8.1).

### Operations

```
place(record_ref, placed_by, reason, case_ref?, placed_at?) → hold_id | rejected(invalid-request | storage-failure)
release(hold_id, released_by, reason, released_at?) → released | rejected(invalid-request | not-known | already-released | storage-failure)
read(query) → holds | rejected(invalid-query)
```

```text
Operation 1: [Place] MUST record EXACTLY ONE hold per successful call.
Operation 2: [Place] MUST stand the hold in active.
Operation 3: [Place] MUST answer hold_id.
Operation 4: IF record_ref is blank THEN [Place] MUST answer invalid-request.
Operation 5: IF placed_by is blank THEN [Place] MUST answer invalid-request.
Operation 6: IF hold_reason is blank THEN [Place] MUST answer invalid-request.
Operation 7: IF a supplied case_ref is blank THEN [Place] MUST answer invalid-request.
Operation 8: IF a supplied placed_at EXCEEDS now THEN [Place] MUST answer invalid-request.
Operation 9: IF the caller supplies no placed_at THEN [Place] MUST stamp placed_at from the injected now.
Operation 10: [Place] MUST accept a placed_at below now.
Operation 11: IF the store refuses the write THEN [Place] MUST answer storage-failure.
Operation 12: IF hold_id is blank THEN [Release] MUST answer invalid-request.
Operation 13: IF the hold NOT EXISTS THEN [Release] MUST answer not-known.
Operation 14: IF the hold stands in released THEN [Release] MUST answer already-released.
Operation 15: IF released_by is blank THEN [Release] MUST answer invalid-request.
Operation 16: IF release_reason is blank THEN [Release] MUST answer invalid-request.
Operation 17: IF the resolved released_at falls below the hold's placed_at THEN [Release] MUST answer invalid-request.
Operation 18: IF a supplied released_at EXCEEDS now THEN [Release] MUST answer invalid-request.
Operation 18a: IF the caller supplies no released_at THEN [Release] MUST stamp released_at from the injected now.
Operation 19: [Release] MUST stand the hold in released.
Operation 20: [Release] MUST NOT reach another hold over the record.
Operation 21: IF the store refuses the write THEN [Release] MUST answer storage-failure.
Operation 22: [Release] MUST leave the hold standing in active on storage-failure.
Operation 23: [Read] MUST answer the holds the query matches.
Operation 24: [Read] MUST order the answer by placed_at, rising.
Operation 25: [Read] MUST order two holds sharing a placed_at by hold_id, rising.
Operation 26: [Read] MUST accept a filter on EVERY admitted axis.
Operation 26a: [Read] MUST accept a query combining admitted axes.
Operation 27: IF the query carries an axis outside the admitted axes THEN [Read] MUST answer invalid-query.
Operation 28: IF a filter value is blank THEN [Read] MUST answer invalid-query.
Operation 29: IF a hold state filter value falls outside the hold state set THEN [Read] MUST answer invalid-query.
Operation 30: IF a range's end falls below the range's start THEN [Read] MUST answer invalid-query.
Operation 31: [Read] MUST answer an empty sequence for a well-formed query matching nothing.
Operation 32: [Read] MUST NOT answer an active hold under a released_at filter.
Operation 33: [Read] MUST NOT answer a hold carrying no case_ref under a case_ref filter.
Operation 34: [Read] MUST NOT write.
Operation 35: The host MUST read the clock at the atom's seam.
Operation 36: The transition MUST NOT read a clock.
Operation 37: The business caller MUST NOT supply now.
Operation 38: The business caller MAY supply placed_at.
Operation 39: The business caller MAY supply released_at.
Operation 40: The atom MUST judge a supplied placed_at against the injected now.
Operation 41: The atom MUST judge a supplied released_at against the injected now.
```

Terms › `query`: what a read asks for — a [Query]; any combination of the admitted axes, and a query carrying none matches every hold.

Terms › `admitted axis`: `hold_id` | `record_ref` | `placed_by` | `case_ref` | `hold state` | a `placed_at` range | a `released_at` range — the filter axes [Read] accepts, and no others.

Terms › `resolved released_at`: the released_at the release records — the caller's value where one is supplied, the injected now otherwise.

Terms › `held at an instant`: `placed_at` at or before the instant, and the hold either standing active or carrying a `released_at` after the instant — the reconstruction an auditor runs over stored fields, never over the hold's present state.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the hold store |
|---|---|---|---|
| [Place] | refs and reason present, `placed_at` not future, store accepts | `hold_id` | one hold lands in [Active] (Operation 1, Operation 2) |
| [Place] | blank `record_ref`, `placed_by`, reason, or supplied `case_ref` | [Invalid Request] | none (Operation 4–7) |
| [Place] | supplied `placed_at` in the future | [Invalid Request] | none (Operation 8) |
| [Place] | supplied `placed_at` in the past | `hold_id` | one hold lands, back-dated as supplied (Operation 10) |
| [Release] | hold active, attribution present, time in range | `released` | [Active] → [Released], release fields stamped (Operation 19, State 4) |
| [Release] | blank `hold_id` | [Invalid Request] | none — the caller passed nothing, not a missing hold (Operation 12) |
| [Release] | id names nothing | [Not Known] | none (Operation 13) |
| [Release] | hold already released | [Already Released] | none (Operation 14) |
| [Release] | resolved `released_at` before `placed_at`, or supplied one in the future | [Invalid Request] | none (Operation 17, Operation 18) |
| either write | store refuses | [Storage Failure] | none — a release leaves the hold [Active] (Operation 11, Operation 21, Operation 22) |
| [Read] | well-formed query | the matching holds, ordered | none — the call reads (Operation 23, Operation 34) |
| [Read] | unknown axis, blank value, bad state, inverted range | [Invalid Query] | none — rejected rather than silently ignored (Operation 27–30) |
| [Read] | well-formed query matching nothing | empty sequence | none (Operation 31) |

WHY:
A blank `hold_id` is refused before the store is consulted, because *you passed garbage* and *no such hold* are different facts and a caller acts on them differently (Operation 12, Operation 13). An unrecognized filter axis is refused rather than ignored: a silently dropped filter returns a result set wider than the caller asked for, and in this atom a wider set means *this record is not held* answered from an incomplete read (Operation 27). Back-dating a placement is accepted on purpose — an obligation recognized late is still an obligation, and the record should say when it was recognized rather than pretend (Operation 10, Backdating 1–3).

### Invariants

- **Invariant 1 — Hold immutability.**
  ```text
  Invariant 1.1: A recorded hold's hold_id, record_ref, placed_by, hold_reason, placed_at and case_ref MUST NOT change.
  ```
- **Invariant 2 — Membership exclusivity.**
  ```text
  Invariant 2.1: EVERY hold MUST stand in EXACTLY ONE OF active, released.
  ```
- **Invariant 3 — Terminal absorption.**
  ```text
  Invariant 3.1: A released hold MUST NOT stand in active again.
  Invariant 3.2: The atom MUST NOT offer a re-activation.
  ```
- **Invariant 4 — Concurrent holds are independent.**
  ```text
  Invariant 4.1: A release MUST NOT change another hold's state.
  Invariant 4.2: A hold's state MUST rest on that hold's own release alone.
  Invariant 4.3: A record MUST read as held at an instant ONLY IF a hold over the record is held at an instant.
  ```
- **Invariant 5 — Release attribution is complete.**
  ```text
  Invariant 5.1: A released hold MUST carry a released_by that is not blank.
  Invariant 5.2: A released hold MUST carry a release_reason that is not blank.
  Invariant 5.3: A released hold MUST carry released_at.
  ```
  WHY: an anonymous or unexplained release defeats the audit trail a court reads — *who decided the duty had ended, and on what ground* is the question a spoliation dispute turns on.
- **Invariant 6 — Temporal ordering.**
  ```text
  Invariant 6.1: A released hold's placed_at MUST NOT EXCEED the hold's released_at.
  ```
- **Invariant 7 — Placement attribution is complete.**
  ```text
  Invariant 7.1: EVERY hold MUST carry a placed_by that is not blank.
  Invariant 7.2: EVERY hold MUST carry a hold_reason that is not blank.
  Invariant 7.3: EVERY hold MUST carry placed_at.
  ```
- **Invariant 8 — Hold store durability.**
  ```text
  Invariant 8.1: The atom MUST NOT delete a hold record.
  Invariant 8.2: The hold set MUST NOT shrink.
  Invariant 8.3: A storage-failure from [Place] MUST NOT leave a partial hold.
  ```

Immutability and durability give the *preservation record* property — the full arc of an obligation, from recognition to lifting, recoverable from the store alone. Independence gives the property a multi-authority matter needs: one record, many obligations, each ending on its own day.

## Examples

### Happy path — litigation hold through release

See Flow section. A complete hold arc is walked there: placement by counsel, second independent hold by compliance, release of the first, continued preservation under the second, eventual release of the second, and a later audit query recovering the full history.

### Rejection path — release attempted twice

After hold-001 is [Released], counsel's paralegal system retries: `release("hold-001", released_by: "system_retry", reason: "automated retry")` → `rejected(already-released)`. The hold record is unchanged. The paralegal system detects the rejection and suppresses the retry.

### Rejection path — place with empty reason

`place(record_ref: "doc-0099", placed_by: "compliance_chen", reason: "   ")` → `rejected(invalid-request)`. Whitespace-only reason is treated as empty. No hold is created.

### Rejection path — release with future timestamp

`release("hold-007", released_by: "counsel_kim", reason: "case closed", released_at: "2027-01-01T00:00:00Z")` → `rejected(invalid-request)`. A release documented as occurring in the future is not operationally meaningful; the atom records the present obligation, not a future intent.

---

### Regulated adversarial scenarios

#### Regulator audit — HHS OCR HIPAA investigation

HHS (US Department of Health and Human Services — the federal agency that enforces HIPAA) Office for Civil Rights (OCR) opens an investigation into a reported breach of PHI (Protected Health Information — individually identifiable health data covered by HIPAA, the Health Insurance Portability and Accountability Act, the US federal law governing healthcare data privacy). It issues a preservation demand to the covered entity for all records relating to the incident. The compliance team calls [Place] for each record in scope; each placement carries `case_ref: "ocr-hipaa-inv-2026-0334"`. Two months later, OCR requests the preservation record: query `read({case_ref: "ocr-hipaa-inv-2026-0334", state: Active})` returns every [Active] hold placed under this investigation. Every hold carries [Placed By] and [Hold Reason] strings each with at least one non-whitespace character, and a [Placed At] timestamp that is set — immutable by Invariants 1 and 7. OCR confirms that preservation was initiated and that each hold is still [Active]. The covered entity has a documentable, auditable preservation response; no recourse to developer testimony is needed.

#### Spoliation challenge — federal litigation

Opposing counsel in federal litigation argues that the defendant destroyed documents after the duty to preserve was triggered under FRCP (Federal Rules of Civil Procedure — the rules governing civil lawsuits in US federal courts) Rule 37(e). Defendant's counsel queries `read({record_ref: "doc-contract-077"})` for all holds ever placed on the disputed document. The query returns the hold placed on the record, with `placed_at: 2026-02-14` — the date the preservation obligation was recognized. The opposing party claims the document was destroyed on `2026-02-10`. The hold record shows [Placed At] postdating the destruction. If a corresponding purge record from Retention Window shows `purged_at: 2026-02-10` and no [Active] hold existed at that time, the records faithfully document the chronology — the hold was placed after the purge. If the document was never purged and remains in the store, the hold records confirm ongoing preservation. Either way, the court has the complete record; the atom does not manufacture a defense but it does not hide the facts either.

#### Concurrent hold integrity — dual regulatory investigation

A financial institution is simultaneously under a DOJ (US Department of Justice) criminal investigation and an SEC (US Securities and Exchange Commission — the federal regulator of securities markets) civil enforcement action. Both issue preservation demands covering the same set of trading records. The compliance team places holds under both matters:

- `hold-doj-001` through `hold-doj-240`: `case_ref: "doj-crim-2026-0011"`
- `hold-sec-001` through `hold-sec-240`: `case_ref: "sec-enf-2026-0087"`

The DOJ investigation closes first. The compliance team releases all `hold-doj-*` holds. Query `read({record_ref: "trade-record-0042", state: Active})` returns `hold-sec-042` — the SEC hold remains [Active]. Invariant 4 guarantees that releasing the DOJ holds had no effect on the SEC holds. The institution correctly continues to preserve the records under SEC obligation. An auditor reviewing the hold records sees the full picture: two independent regulatory demands, one resolved, one active, no record destroyed while any [Active] hold covered it.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the hold store's stored fields, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```text
Check 1.1: An auditor MUST find EVERY issued hold_id in the store (Invariant 8.1, Invariant 8.2).
Check 2.1: An auditor MUST find placed_by and hold_reason not blank on EVERY hold (Invariant 7.1, Invariant 7.2).
Check 2.3: An auditor MUST find record_ref not blank on EVERY hold (Operation 4).
Check 2.4: An auditor MUST find hold_id not blank on EVERY hold (Identity 2, Instance 2).
Check 2.2: An auditor MUST find placed_at set on EVERY hold (Invariant 7.3).
Check 3.1: An auditor MUST find released_by and release_reason not blank on EVERY released hold (Invariant 5.1, Invariant 5.2).
Check 3.2: An auditor MUST find released_at set on EVERY released hold (Invariant 5.3).
Check 3.3: An auditor MUST find no released hold whose placed_at EXCEEDS the hold's released_at (Invariant 6.1).
Check 4.1: An auditor MUST find a second hold over one record still active once the first hold is released (Invariant 4.1).
Check 5.1: An auditor MUST find already-released answered for a release against a released hold (Operation 14, Invariant 3.1).
Check 5.2: An auditor MUST find a released hold's fields unchanged by that refused release (Invariant 1.1).
Check 6.1: An auditor MUST find the hold set never shrinking across two readings (Invariant 8.2).
Check 6.2: An auditor MUST find EVERY placement field unchanged across two readings (Invariant 1.1).
Check 6.3: An auditor MUST read an active-to-released move between two readings as conformant (Invariant 2.1).
Check 7.1: An auditor MUST identify which composing patterns a deployment wired in (Composition note 1).
```

### External checks

```text
External check 1: An auditor MUST read whether a held record was purged from the composing pattern's purge records (Non-goal 1, Composition note 2).
External check 2: An auditor MUST read who was permitted to place a hold from the composing [Permissions](./permissions.md) records (Non-goal 7).
External check 3: An auditor MUST read a hold record's integrity from the composing [Tamper Evidence](./tamper-evidence.md) seals (Non-goal 11).
External check 4: An auditor MUST read the matter a case_ref names from the deployment's case-management system (Non-goal 9).
```

NOTE: EVERY check names the rule the check tests. The hold store answers *what was preserved, by whom, and for how long*; whether the preservation was honoured at the purge surface is the composing pattern's record, because this atom deliberately enforces nothing (Non-goal 1).

## Non-goals

```text
Non-goal 1: The atom MUST NOT block a purge.
Non-goal 2: A deployment needing an enforced hold MUST compose [Defensible Retention](../compositions/defensible-retention.md).
Non-goal 3: The atom MUST NOT read the record a record_ref names.
Non-goal 4: The atom MUST NOT refuse a hold over a destroyed record.
Non-goal 5: The atom MUST NOT deduplicate two holds.
Non-goal 6: A deployment needing at-most-once placement MUST compose [Duplicate Prevention](./duplicate-prevention.md).
Non-goal 7: The atom MUST NOT gate who places a hold.
Non-goal 8: A deployment needing gated placement MUST compose [Permissions](./permissions.md).
Non-goal 9: The atom MUST NOT hold a matter's lifecycle.
Non-goal 10: The atom MUST NOT release every hold over a record in one call.
Non-goal 11: The atom MUST NOT detect tampering with a hold record.
Non-goal 12: A deployment needing court-admissible hold records MUST compose [Tamper Evidence](./tamper-evidence.md).
Non-goal 13: The atom MUST NOT place one hold over two records.
Non-goal 14: The atom MUST NOT import a retention policy.
Non-goal 15: The atom MUST NOT purge a hold record.
Non-goal 16: A deployment sweeping the hold store MUST leave EVERY stored field as written.
```

WHY:
The atom documents an obligation and enforces nothing, which is the seam that matters most here: enforcement needs the purge surface, and the purge surface belongs to [Retention Window](./retention-window.md) and the composition that gates it — [Defensible Retention](../compositions/defensible-retention.md) checks both *not before `retention_until`* and *not while a hold is active* (Non-goal 1, Non-goal 2, Non-goal 14). A hold over a record that was already destroyed still records that somebody recognized the duty, which is evidence in a spoliation dispute rather than an error to refuse (Non-goal 4). There is no bulk release and no batch placement: N obligations take N calls, each individually attributable, because a bulk lift with one reason is exactly the record a court will not accept (Non-goal 10, Non-goal 13).

Where the atom breaks down: when the preservation duty is defined by a query rather than a record — *everything touching Project Alpha* — which needs a composing pattern to enumerate and place; when the hold must survive the store that holds it, which needs an external anchor; when who may lift a hold is part of the obligation, which is Permissions' and not a field here.

## Edge cases

### Place persistence failure

```text
Place persistence 1: A caller MUST read storage-failure from [Place] as the record standing unheld.
Place persistence 2: A caller MUST retry a place that answered storage-failure.
Place persistence 3: A high-assurance deployment MUST raise an alert on storage-failure from [Place].
Place persistence 4: A caller MUST NOT read storage-failure from [Release] as the obligation standing ended.
```

WHY:
The two storage failures have opposite polarity, and this atom's dangerous side is the placement. A failed release leaves an obligation standing, which over-preserves — costly and safe. A failed place leaves a record unprotected while litigation pends, which is the spoliation the atom exists to document, and it surfaces as nothing at all unless the caller retries ([Permissions](./permissions.md) states the mirrored polarity for its own revoke; Council read 17).

### Back-dating a placement

```text
Backdating 1: [Place] MUST accept a placed_at below now.
Backdating 2: [Place] MUST NOT accept a placed_at above now.
Backdating 3: The deployment MUST own the evidentiary weight of a back-dated placed_at.
```

WHY:
An obligation recognized on Tuesday and recorded on Friday is honestly recorded as Tuesday's; a hold placed in the future is not a fact about anything. Courts scrutinize back-dated placements in spoliation disputes, which is the deployment's problem to defend and the atom's to record faithfully rather than to prevent (Backdating 3).

WHY:
An empty answer and a misrouted answer read alike, and this atom's empty answer licenses a purge — so the deepest failure available here is a routing mistake wearing the shape of *no holds* (Instance 5–7, Aggregate 3; Council read 17). The atom cannot detect the misrouting, so it names the store it answered from and obliges the reader to check.

### The aggregate question

```text
Aggregate 1: A composing pattern MUST read a record's active holds to answer whether the record is held.
Aggregate 2: The atom MUST NOT carry a held flag on a record.
Aggregate 3: A composing pattern MUST read an empty active set as the record standing unheld ONLY IF the answered store_name matches the record's store instance.
```

### Concurrency

```text
Concurrency 1: The implementation MUST serialize two releases of one hold_id.
Concurrency 2: The second concurrent release MUST answer already-released.
Concurrency 3: Two placements over one record MUST record two holds.
```

### Clock semantics

```text
Clock semantics 1: The deployment MUST own the clock's monotonicity.
Clock semantics 2: The deployment MUST own the clock's timezone handling.
Clock semantics 3: A deployment needing a defensible timeline MUST compose a trusted-timestamping pattern.
```

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST check a record's active holds at the purge surface.
Composition note 3: A composing pattern MUST own who may place a hold.
Composition note 4: A composing pattern MUST own who may release a hold.
Composition note 5: A composing pattern MUST own a bulk placement.
Composition note 6: A composing pattern MUST own a bulk release.
```

WHY:
[Defensible Retention](../compositions/defensible-retention.md) is the composition this atom was extracted for: [Retention Window](./retention-window.md) says when a record may be destroyed, this atom says when it may not, and the composition is the gate that reads both at the purge surface — neither atom enforcing anything alone is the design, not an omission (Composition note 2). Attribution of the placement itself composes [Actor Identity](./actor-identity.md); integrity of the hold records composes [Tamper Evidence](./tamper-evidence.md); the audit surface both write through is [Audit Trail](../compositions/audit-trail.md).

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a caller; an auditor; the store; a hold; a release; a placement; a query.

Terms › `records`: `hold` — one preservation obligation, carrying `hold_id`, `record_ref`, `placed_by`, `hold_reason`, `placed_at`, a hold state and, where they exist, `case_ref`, `released_by`, `release_reason` and `released_at`.

Terms › `record verbs`: supply, judge, purge, retry, raise, match, share, hold, reach, route, identify, allocate, reuse, reassign, sort, carry, stand, offer, delete, record, answer, stamp, accept, leave, read, order, write, change, rest, shrink, find, serialize, block, refuse, deduplicate, gate, release, detect, place, import, own, check, compose, declare, exceed, fall.

Terms › `value sets`: place answers = hold_id | rejected(invalid-request | storage-failure). release answers = released | rejected(invalid-request | not-known | already-released | storage-failure). read answers = the matching holds, ordered | rejected(invalid-query). `hold state` = active | released.

Terms › `bounds`: empty.

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-12).

Terms › `terms`: `store instance`, `hold`, `hold_id`, `record_ref`, `seam`, `transition`, `business caller`, `now`, `hold state`, `placed_by`, `hold_reason`, `placed_at`, `case_ref`, `released_by`, `release_reason`, `released_at`, `query`, `resolved released_at`.

#### Place

The behavior that records a new preservation hold against a record. It assigns a fresh [Hold Id], stamps [Placed At], records [Record Ref], [Placed By], [Hold Reason], and [Case Ref] (if supplied), and returns the [Hold Id] (or a rejection). The hold enters [Active].

Kind: Operation

#### Release

The behavior that documents the end of a preservation obligation, transitioning an [Active] hold to [Released] and recording [Released By], [Release Reason], and [Released At]. A [Released] hold cannot be released again ([Already Released]); releasing one hold never affects another on the same record (Invariant 4).

Kind: Operation

#### Read

The read-only behavior that returns the holds matching a [Query], ordered by [Placed At] ascending then [Hold Id] ascending. It changes nothing. Filters by [Hold Id], [Record Ref], [Placed By], [Case Ref], [State], or time range are combinable; the query `{record_ref: X, state: Active}` is the operational "is this record held?" check.

Kind: Operation

#### Hold Id

The opaque, immutable, system-generated identity of a hold, assigned on [Place], never reused or reassigned within the store instance. A non-empty string sortable in lexicographic byte-order — required for deterministic [Read] ordering. The record, actor, reason, and timestamps are properties of the hold, not its identity.

Kind:     Field
Field of: the hold record
Projects: hold_id

#### Record Ref

The opaque reference to the record being held. Set on [Place], immutable, never validated against any storage layer. Multiple holds may name the same [Record Ref]; each is an independent hold.

Kind:     Field
Field of: the hold record
Projects: record_ref

#### Placed By

The opaque reference to the actor placing the hold — the attribution anchor for the preservation decision. Set on [Place], immutable; empty or whitespace-only is rejected (Invariant 7).

Kind:     Field
Field of: the hold record
Projects: placed_by

#### Hold Reason

The required, non-empty narrative for the hold — written from the [Reason] parameter at [Place]. Set on [Place], immutable (Invariants 1 and 7). Carries the proportionality/scope explanation a court expects.

Kind:     Field
Field of: the hold record
Projects: hold_reason

#### Placed At

The timestamp the hold was placed — supplied or defaulted to the receiving node's wall clock; must not be future. Set on [Place], immutable. The lower bound for [Released At] (Invariant 6) and the ordering key for [Read].

Kind:     Field
Field of: the hold record
Projects: placed_at

#### Case Ref

The optional opaque reference to the legal matter, investigation, or audit. Set on [Place] if supplied (then immutable); its absence is valid. A positive [Case Ref] filter excludes holds without one.

Kind:     Field
Field of: the hold record
Projects: case_ref

#### State

The hold's lifecycle state — [Active] or [Released]. Set to [Active] on [Place]; transitions once to [Released] via [Release]. Every hold is in exactly one state (Invariant 2).

Kind:     Field
Field of: the hold record
Projects: state

#### Released By

The opaque reference to the actor releasing the hold. Set at [Release], immutable; present on [Released] holds only. Non-null required (Invariant 5).

Kind:     Field
Field of: the hold record
Projects: released_by

#### Release Reason

The required, non-empty reason for the release — written from the [Reason] parameter at [Release]. Set at [Release], immutable; present on [Released] holds only (Invariant 5).

Kind:     Field
Field of: the hold record
Projects: release_reason

#### Released At

The timestamp the hold was released — supplied or defaulted to wall clock; must not be future and must be ≥ [Placed At] (Invariant 6). Set at [Release], immutable; present on [Released] holds only.

Kind:     Field
Field of: the hold record
Projects: released_at

#### Store Name

The identifier of the store instance a hold belongs to. Multiple instances coexist; [Hold Id]s are unique within an instance, while [Record Ref] is host-scoped. No action accepts it as a parameter — instance selection is handled at the deployment-routing layer.

Kind:     Field
Field of: the store instance
Projects: store_name

#### Reason

The required, non-empty reason string [Place] and [Release] consume — written into [Hold Reason] or [Release Reason] respectively. Not stored under this name; an empty or whitespace-only value is rejected [Invalid Request].

Kind:         Parameter
Parameter of: Place
Projects:     reason

#### Query

The selection [Read] consumes — a filter over [Hold Id], [Record Ref], [Placed By], [Case Ref], [State], and/or a time range on [Placed At] or [Released At]. Supplied per call, not stored; a malformed one is rejected [Invalid Query].

Kind:         Parameter
Parameter of: Read
Projects:     query

#### Active

The non-terminal state of a hold whose preservation obligation is in effect. A composition wiring this atom to a purge surface treats an [Active] hold as blocking purge. May be released or read.

Kind:      Member
Member of: the hold state
Role:      Outcome

#### Released

The terminal state of a hold whose preservation obligation has ended. Carries [Released By], [Release Reason], and [Released At]; retained as audit evidence, no further transition (Invariant 3).

Kind:      Member
Member of: the hold state
Role:      Outcome

#### Invalid Request

The refusal [Place] or [Release] returns when request fields fail — an empty/whitespace [Record Ref], [Placed By], [Reason], [Case Ref], [Released By], or [Hold Id]; a future [Placed At]; or a [Released At] that is future or before [Placed At].

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  invalid-request

#### Not Known

The refusal [Release] returns when the named [Hold Id] references no hold in this store instance — a lookup miss (a common cause is cross-instance referencing).

Kind:      Member
Member of: the Release rejection
Role:      Outcome
Projects:  not-known

#### Already Released

The refusal [Release] returns when the target is already [Released] — terminal absorption (Invariant 3); a pure guard that writes nothing.

Kind:      Member
Member of: the Release rejection
Role:      Outcome
Projects:  already-released

#### Storage Failure

The refusal any writing action returns when a durable write fails after preconditions pass. All-or-none: no partial record is observable, and the prior state is unchanged (Invariant 8).

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

#### Invalid Query

The refusal [Read] returns when query parameters are malformed — a null/empty/whitespace filter value, a [State] value outside {[Active], [Released]}, a time range with end before start, or an unrecognized filter key.

Kind:      Member
Member of: the Read rejection
Role:      Outcome
Projects:  invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Place]: #place
[Release]: #release
[Read]: #read
[Hold Id]: #hold-id
[Record Ref]: #record-ref
[Placed By]: #placed-by
[Hold Reason]: #hold-reason
[Placed At]: #placed-at
[Case Ref]: #case-ref
[State]: #state
[Released By]: #released-by
[Release Reason]: #release-reason
[Released At]: #released-at
[Store Name]: #store-name
[Reason]: #reason
[Query]: #query
[Active]: #active
[Released]: #released
[Invalid Request]: #invalid-request
[Not Known]: #not-known
[Already Released]: #already-released
[Storage Failure]: #storage-failure
[Invalid Query]: #invalid-query

---

## Standards references

- **Federal Rules of Civil Procedure Rule 37(e)** — the primary U.S. federal standard for electronic discovery preservation. A party must take reasonable steps to preserve ESI (Electronically Stored Information — digital records subject to legal discovery) once litigation is reasonably anticipated; failure to preserve when an [Active] hold should have been in place exposes the party to sanctions including adverse inference instructions. The [Placed At] timestamp and [Hold Reason] field are the record of when and why the preservation obligation was recognized.
- **Federal Rules of Civil Procedure Rule 26(b)** — proportionality doctrine for discovery preservation; not all records must be held, only those reasonably expected to be relevant. [Hold Reason] and [Case Ref] are the scoping fields that document proportionality.
- **Sedona Conference Principles (3rd ed.)** — the leading authoritative guidance on electronic discovery preservation obligations. Principle 5: a party is not required to preserve every document; preservation must be proportionate. Principle 6: a party should consider adoption of a litigation hold policy. The [Hold Reason] field is the policy documentation surface.
- **SOX §802 (18 U.S.C. §1519)** — criminal obstruction-of-justice provision for destruction of documents subject to federal investigation or proceedings. An [Active] Legal Hold covering the relevant records is the structural defense against §802 exposure.
- **SEC Rule 17a-4(f)** — requires broker-dealers to preserve records in non-rewriteable, non-erasable format, accessible to regulators on demand. Legal Hold composes with Tamper Evidence to meet this standard; the hold record itself is a regulated record under 17a-4.
- **HIPAA §164.530(j)** — documentation retention requirements; HHS investigations trigger preservation obligations over the PHI and administrative records involved. Legal Hold is the preservation mechanism.
- **HIPAA Breach Notification Rule (45 CFR §164.400–414)** — breach investigations generate preservation obligations over the records relating to the incident. [Case Ref] references the OCR investigation case identifier.
- **GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Article 17(3)(e)** — erasure right (right to be forgotten) does not apply when processing is necessary for the establishment, exercise, or defence of legal claims. An [Active] Legal Hold is the operational record that establishes the legal-claim exception to erasure. See [Resolve a Person's Data Rights](../compositions/resolve-a-persons-data-rights.md), whose `retained(legal-hold)` disposition is the records-alone form of this exception.
- **21 CFR Part 11** — electronic records and signatures in FDA-regulated contexts. Preservation holds on regulated records (clinical trial data, manufacturing batch records) must be attributable and non-alterable. Composes with Actor Identity and Tamper Evidence.
- **E-SIGN Act (Electronic Signatures in Global and National Commerce Act) / UETA (Uniform Electronic Transactions Act)** — electronic hold records carry the same legal force as paper hold notices where these acts apply.
- **ISO 15489-1 (Records management)** — the International Organization for Standardization's standard for records-management practice; hold is the operational mechanism for Section 9.7 (suspension of disposition). The two-state ([Active]/[Released]) model maps directly to ISO 15489's hold lifecycle.

---


## Status

`grounded on Final Critique 4 — 2026-05-20` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-05-20
formal: verified — legal-hold.tla + 2 twins, 2026-06-04
last gate: 2026-05-20 — Final Critique 4, fresh reader — clean

open: none
```


## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/legal-hold.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the three actions as a signature block, the read's filter axes and malformed-query grounds as rules rather than a paragraph, the eight invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan, and this atom completes [Defensible Retention](../compositions/defensible-retention.md)'s constituent set with [Retention Window](./retention-window.md) and [Audit Trail](../compositions/audit-trail.md).

NOTE: End of Legal Hold.
