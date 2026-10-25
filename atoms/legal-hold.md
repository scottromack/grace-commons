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

Legal Hold is a formal instruction to keep a specific record intact — overriding any normal deletion schedule — until the legal matter that triggered it is resolved. When a lawsuit is anticipated, a regulator opens an investigation, or a team needs to freeze evidence, the normal "delete after N years" rule stops applying. The hold records the shift: who issued it, against which record, why, and under what authority. A hold is either [Active] (preservation in effect) or [Released] (lifted, permanently — it cannot be reactivated). Both placing and releasing are attributed, timestamped, and never altered afterward, so the full arc of any preservation obligation is provable. Multiple holds can cover the same record independently — a record under both an internal investigation and a government investigation has two separate obligations, and releasing one leaves the other in force, which is exactly what multi-party legal situations require. The pattern does not itself block deletion; it records that an obligation exists, and the system that actually deletes records is responsible for checking for [Active] holds first. This is the mechanism behind managing the holds a lawsuit sets off, keeping the records of a data breach while it is investigated, and any setting where destroying a record during an active legal obligation exposes the organization to penalties.

---

## Intent

WHY:
When litigation is filed or reasonably anticipated, the duty to preserve arrives before anyone knows what will matter, and it overrides every retention schedule the organization has. Destroying a held record is spoliation — sanctions, an adverse inference (the jury told it may presume the destroyed record was unfavorable), sometimes the case. So the obligation itself has to be a record: what is held, who decided, why, under which matter, from when, and — when it ends — who lifted it and on what grounds. That record is this atom. It does not stop a purge; it documents an obligation a composing pattern enforces at the purge surface. It does not know what a case is. And it never merges two holds over one record, because two authorities demanding preservation of one document is two obligations, each ending on its own day.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a hold by the hold id.
Identity 2: The host MUST allocate a hold id at the atom's seam.
Identity 3: The transition MUST NOT allocate a hold id.
Identity 4: The atom MUST NOT reuse a hold id within one database instance.
Identity 5: The atom MUST NOT reassign a hold id.
Identity 6: A hold id MUST sort in lexicographic byte order.
Identity 7: The atom MUST NOT identify a hold by the record reference.
Identity 8: Two holds over one record MUST carry two hold ids.
```

Term hold: one recorded preservation obligation over one record — the record this atom writes.

Term hold id: the opaque value naming one hold — a [Hold Id]; not blank, and sortable so [Read] can order deterministically.


Term record reference: the opaque reference naming what is preserved — a [Record Reference]; the host owns whether the record exists.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the hold id here.

Term transition: the atom's evaluation of one call against the hold records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, and never supplied by the business caller — placement instant and release instant are the caller's claims about when an obligation began and ended, judged against now and stored as claims (Operation 38 through 41).

### State

```
State 1: EVERY hold MUST stand in EXACTLY ONE OF active, released.
State 2: EVERY hold MUST carry hold id, record reference, placing actor, hold reason, placement instant and state.
State 3: A hold MAY carry case reference.
State 4: A released hold MUST carry releasing actor, release reason and release instant.
State 5: An active hold MUST NOT carry release instant.
State 7: The atom MUST NOT delete a hold.
State 8: The atom MUST NOT hold an aggregate for a record.
Deleted: State 6. Invariant 3.2 owns the absent re-activation.
Deleted: State 9. Non-goal 9 owns the case lifecycle.
```

Term hold state: active | released — the obligation in effect, or documented as ended.

Term placing actor: the opaque reference naming who placed the hold — a [Placing Actor]; the attribution anchor for the preservation decision.

Term hold reason: the narrative ground the hold was placed on — a [Hold Reason].

Term placement instant: the instant the obligation was recorded — a [Placement Instant].

Term case reference: the opaque reference naming the matter the hold sits under — a [Case Reference]; absent where no formal matter exists yet.

Term releasing actor: the opaque reference naming who ended the obligation — a [Releasing Actor].

Term release reason: the ground the obligation ended on — a [Release Reason].

Term release instant: the instant the obligation was documented as ended — a [Release Instant].

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 7.
Capability requirement 4: The deployment MUST supply the hold records PER Execution Contract Database 1 through 4, Execution Contract Refusal 1 and Execution Contract Conformance 9.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Non-goal 17 owns it.
```

### Operations

```
place(record_ref, placed_by, reason, optional case_ref, optional placed_at)
  answers hold_id
  refuses invalid-request | storage-failure

release(hold_id, released_by, reason, optional released_at)
  answers released
  refuses not-known | already-released | invalid-request | storage-failure

read(query)
  answers holds(store_name)
  refuses invalid-query
```

```
Operation 1: [Place] MUST record EXACTLY ONE hold per successful call.
Operation 2: [Place] MUST stand the hold in active.
Operation 3: [Place] MUST answer hold id.
Operation 4: IF record reference EQUALS blank THEN [Place] MUST answer invalid-request.
Operation 5: IF placing actor EQUALS blank THEN [Place] MUST answer invalid-request.
Operation 6: IF hold reason EQUALS blank THEN [Place] MUST answer invalid-request.
Operation 7: IF a supplied case reference EQUALS blank THEN [Place] MUST answer invalid-request.
Operation 8: IF now PRECEDES a supplied placement instant THEN [Place] MUST answer invalid-request.
Operation 9: IF placement instant EQUALS blank THEN [Place] MUST stamp placement instant from the injected now.
Operation 10: [Place] MUST accept a placement instant below now.
Operation 11: IF the database refuses the write THEN [Place] MUST answer storage-failure.
Operation 12: IF hold id EQUALS blank THEN [Release] MUST answer invalid-request.
Operation 13: IF hold id DOES NOT EQUAL blank AND no hold EXISTS for the hold id THEN [Release] MUST answer not-known.
Operation 14: IF the hold state EQUALS released THEN [Release] MUST answer already-released.
Operation 15: IF releasing actor EQUALS blank THEN [Release] MUST answer invalid-request.
Operation 16: IF release reason EQUALS blank THEN [Release] MUST answer invalid-request.
Operation 17: IF the resolved release instant PRECEDES the hold's placement instant THEN [Release] MUST answer invalid-request.
Operation 18: IF now PRECEDES a supplied release instant THEN [Release] MUST answer invalid-request.
Operation 18a: IF release instant EQUALS blank THEN [Release] MUST stamp release instant from the injected now.
Operation 19: [Release] MUST stand the hold in released.
Operation 20: [Release] MUST NOT reach another hold over the record.
Operation 21: IF the database refuses the write THEN [Release] MUST answer storage-failure.
Deleted: Operation 22. Execution Contract Database 3 owns it.
Operation 23: [Read] MUST answer the holds the query matches.
Operation 24: [Read] MUST order the answer by placement instant, rising.
Operation 25: [Read] MUST order two holds sharing a placement instant by hold id, rising.
Operation 26: [Read] MUST accept a filter on EVERY admitted axis.
Operation 26a: [Read] MUST accept a query combining admitted axes.
Operation 27: IF the query carries an axis outside the admitted axes THEN [Read] MUST answer invalid-query.
Operation 28: IF a filter value EQUALS blank THEN [Read] MUST answer invalid-query.
Operation 29: IF a hold state filter value falls outside the hold state set THEN [Read] MUST answer invalid-query.
Operation 30: IF a range's end PRECEDES the range's start THEN [Read] MUST answer invalid-query.
Operation 31: [Read] MUST answer an empty sequence for a well-formed query matching nothing.
Operation 32: [Read] MUST NOT answer an active hold under a release instant filter.
Operation 33: [Read] MUST NOT answer a hold carrying no case reference under a case reference filter.
Operation 34: [Read] MUST NOT write.
Deleted: Operation 35. Capability requirement 1 owns it.
Deleted: Operation 36. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 37. Execution Contract Logic confinement 3 owns it.
Operation 38: The business caller MAY supply placement instant.
Operation 39: The business caller MAY supply release instant.
Operation 40: The atom MUST judge a supplied placement instant against the injected now.
Operation 41: The atom MUST judge a supplied release instant against the injected now.
Deleted: Operation 42. Execution Contract Refusal 1 owns it.
```

NOTE: watch the blank id (Operation 13).

NOTE: watch the instant left blank (Operation 9, Operation 18a).

NOTE: watch host obligations — this atom sets no maximum length on a string input, where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one. Three postures, and the *host obligations* docket row carries the count — a watch flag states the pressure, never a census nothing reads.

Term query: what a read asks for — a [Query]; any combination of the admitted axes, and a query carrying none matches every hold. A range's filter values are its start and its end, and an instant at either end lies inside the range. A combination matches a hold that each of its filters matches.

NOTE: watch the range's ends (Term query).

Term admitted axis: hold id | record reference | placing actor | case reference | hold state | a placement instant range | a release instant range — the filter axes [Read] accepts, and no others.

Term resolved release instant: the release instant the release records — the caller's value where it is not blank, the injected now otherwise.

Term held at an instant: placement instant at or before the instant, and either the hold state EQUALS active or the hold carries a release instant after the instant — the reconstruction an auditor runs over stored fields, never over the hold's present state.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the hold records |
|---|---|---|---|
| [Place] | refs and reason present, placement instant not future, database accepts | hold id | one hold lands in [Active] (Operation 1, Operation 2) |
| [Place] | blank record reference, placing actor, reason, or supplied case reference | [Invalid Request] | none (Operation 4 through 7) |
| [Place] | supplied placement instant in the future | [Invalid Request] | none (Operation 8) |
| [Place] | supplied placement instant in the past | hold id | one hold lands, back-dated as supplied (Operation 10) |
| [Release] | hold active, attribution present, time in range | released | [Active] → [Released], release fields stamped (Operation 19, State 4) |
| [Release] | blank hold id | [Invalid Request] | none — the caller passed nothing, not a missing hold (Operation 12) |
| [Release] | id names nothing | [Not Known] | none (Operation 13) |
| [Release] | hold already released | [Already Released] | none (Operation 14) |
| [Release] | blank releasing actor or release reason | [Invalid Request] | none (Operation 15, Operation 16) |
| [Release] | resolved release instant before placement instant, or supplied one in the future | [Invalid Request] | none (Operation 17, Operation 18) |
| either write | database refuses | [Storage Failure] | none — a release leaves the hold [Active] (Operation 11, Operation 21, Place persistence 4) |
| [Read] | well-formed query | the matching holds, ordered | none — the call reads (Operation 23, Operation 34) |
| [Read] | unknown axis, blank value, bad state, inverted range | [Invalid Query] | none — rejected rather than silently ignored (Operation 27 through 30) |
| [Read] | well-formed query matching nothing | empty sequence | none (Operation 31) |

Where two [Release] rows hold at once, the earlier row answers: the refuses line lists not-known and already-released ahead of invalid-request (Execution Contract Refusal 1), and not-known answers only a hold id that is not blank (Operation 13).

### Invariants

- **Invariant 1 — Hold immutability.**
  ```
  Invariant 1.1: A recorded hold's hold id, record reference, placing actor, hold reason, placement instant and case reference MUST NOT change.
  Invariant 1.2: A released hold's releasing actor, release reason and release instant MUST NOT change.
  ```
- **Invariant 2 — Membership exclusivity.**
  ```
  Invariant 2.1: EVERY hold MUST stand in EXACTLY ONE OF active, released.
  ```
- **Invariant 3 — Terminal absorption.**
  ```
  Invariant 3.1: A released hold MUST NOT stand in active again.
  Invariant 3.2: The atom MUST NOT offer a re-activation.
  ```
- **Invariant 4 — Concurrent holds are independent.**
  ```
  Invariant 4.1: A release MUST NOT change another hold's state.
  Invariant 4.2: A hold's state MUST rest on that hold's own release alone.
  Invariant 4.3: A record MUST read as held at an instant ONLY IF a hold over the record is held at an instant.
  ```
- **Invariant 5 — Release attribution is complete.**
  ```
  Invariant 5.1: A released hold MUST carry a releasing actor that is not blank.
  Invariant 5.2: A released hold MUST carry a release reason that is not blank.
  Invariant 5.3: A released hold MUST carry release instant.
  ```
- **Invariant 6 — Temporal ordering.**
  ```
  Invariant 6.1: A released hold's release instant MUST NOT PRECEDE the hold's placement instant.
  ```
- **Invariant 7 — Placement attribution is complete.**
  ```
  Invariant 7.1: EVERY hold MUST carry a placing actor that is not blank.
  Invariant 7.2: EVERY hold MUST carry a hold reason that is not blank.
  Invariant 7.3: EVERY hold MUST carry placement instant.
  ```
- **Invariant 8 — Hold record durability.**
  ```
  Invariant 8.1: The atom MUST NOT delete a hold record.
  Invariant 8.2: The hold set MUST NOT shrink.
  Deleted: Invariant 8.3. Execution Contract Database 1 owns it.
  ```

Immutability and durability give the *preservation record* property — the full arc of an obligation, from recognition to lifting, provable. Independence gives the property a multi-authority matter needs: one record, many obligations, each ending on its own day.

### Database instance model

```
Instance 1: The atom MUST hold every hold under EXACTLY ONE database instance.
Instance 2: Two holds in one database instance MUST NOT share a hold id.
Instance 3: The atom MUST NOT reach across database instances.
Instance 4: The deployment MUST route a call to one database instance.
Instance 5: [Read] MUST answer the database name the read was routed to.
Instance 6: A composing pattern MUST match the answered database name against the record's own database instance.
Instance 7: IF the answered database name DOES NOT EQUAL the record's database instance THEN a composing pattern MUST NOT read an empty answer as unheld.
```

Term database instance: one named database — a [Database Name] identifies it; a deployment runs one per organization, jurisdiction or business unit.

## Examples

### Happy path — litigation hold through release

A complete hold arc over one record, from placement to an audit read:

1. **Litigation trigger.** Counsel determines that the records of Project Alpha fall under a litigation hold and calls `place(record_ref: "doc-alpha-0012", placed_by: "counsel_morgan", reason: "Litigation hold — Smith v. Acme Corp. — all Project Alpha records", case_ref: "matter-2026-smith-acme")` → `hold-001`. The hold stands in [Active].
2. **Second independent hold.** A state attorney general separately demands preservation of the same record. Compliance calls `place(record_ref: "doc-alpha-0012", placed_by: "compliance_lee", reason: "State attorney general's civil investigative demand 2026-0089", case_ref: "state-inquiry-2026-0089")` → `hold-002`. Two independent [Active] holds now cover the record (Concurrency 3).
3. **The litigation settles.** Counsel calls `release("hold-001", released_by: "counsel_morgan", reason: "Matter settled with prejudice — May 10 2026")` → released. Hold-001 stands in [Released]; hold-002 stays [Active], so the record is still held (Invariant 4.1).
4. **The investigation closes.** Compliance calls `release("hold-002", released_by: "compliance_lee", reason: "Civil investigative demand withdrawn — May 28 2026")` → released. No [Active] hold remains over the record, so a composing pattern checking its active holds at the purge surface finds none (Composition note 2).
5. **Audit read.** A later audit calls `read({record_ref: "doc-alpha-0012"})` and receives both holds, each with its placement and release fields, and the database name the read was routed to (Instance 5). The record's whole hold history is provable from the hold records.

### Rejection path — release attempted twice

After hold-001 is [Released], counsel's paralegal system retries: `release("hold-001", released_by: "system_retry", reason: "automated retry")` → already-released. The hold record is unchanged. The paralegal system detects the rejection and suppresses the retry.

### Rejection path — place with empty reason

`place(record_ref: "doc-0099", placed_by: "compliance_chen", reason: "   ")` → invalid-request. Whitespace-only reason is treated as empty. No hold is created.

### Rejection path — release with future timestamp

`release("hold-007", released_by: "counsel_kim", reason: "case closed", released_at: "2027-01-01T00:00:00Z")` → invalid-request. A release documented as occurring in the future is not operationally meaningful; the atom records the present obligation, not a future intent.

### Regulated adversarial scenarios

#### Regulator audit — HHS OCR HIPAA investigation

HHS (US Department of Health and Human Services — the federal agency that enforces HIPAA) Office for Civil Rights (OCR) opens an investigation into a reported breach of PHI (Protected Health Information — individually identifiable health data covered by HIPAA, the Health Insurance Portability and Accountability Act, the US federal law governing healthcare data privacy). It issues a preservation demand to the covered entity for all records relating to the incident. The compliance team calls [Place] for each record in scope; each placement carries `case_ref: "ocr-hipaa-inv-2026-0334"`. Two months later, OCR requests the preservation record: query `read({case_ref: "ocr-hipaa-inv-2026-0334", state: Active})` returns every [Active] hold placed under this investigation. Every hold carries [Placing Actor] and [Hold Reason] strings, neither blank, and a [Placement Instant] timestamp that is set — immutable by Invariants 1 and 7. OCR confirms that preservation was initiated and that each hold is still [Active]. The covered entity has a documentable, provable preservation response.

#### Spoliation challenge — federal litigation

Opposing counsel in federal litigation argues that the defendant destroyed documents after the duty to preserve was triggered under FRCP (Federal Rules of Civil Procedure — the rules governing civil lawsuits in US federal courts) Rule 37(e). Defendant's counsel queries `read({record_ref: "doc-contract-077"})` for all holds ever placed on the disputed document. The query returns the hold placed on the record, with `placed_at: 2026-02-14` — the date the preservation obligation was recognized. The opposing party claims the document was destroyed on `2026-02-10`. The hold record shows [Placement Instant] postdating the destruction. If a corresponding purge record from Retention Window shows `purged_at: 2026-02-10` and no [Active] hold existed at that time, the records faithfully document the chronology — the hold was placed after the purge. If the document was never purged and remains in the database, the hold records confirm ongoing preservation. Either way, the court has the complete record; the atom does not manufacture a defense but it does not hide the facts either.

#### Concurrent hold integrity — dual regulatory investigation

A financial institution is simultaneously under a DOJ (US Department of Justice) criminal investigation and an SEC (US Securities and Exchange Commission — the federal regulator of securities markets) civil enforcement action. Both issue preservation demands covering the same set of trading records. The compliance team places holds under both matters:

- `hold-doj-001` through `hold-doj-240`: `case_ref: "doj-crim-2026-0011"`
- `hold-sec-001` through `hold-sec-240`: `case_ref: "sec-enf-2026-0087"`

The DOJ investigation closes first. The compliance team releases all `hold-doj-*` holds. Query `read({record_ref: "trade-record-0042", state: Active})` returns `hold-sec-042` — the SEC hold remains [Active]. Invariant 4 guarantees that releasing the DOJ holds had no effect on the SEC holds. The institution correctly continues to preserve the records under SEC obligation. An auditor reviewing the hold records sees the full picture: two independent regulatory demands, one resolved, one active, no record destroyed while any [Active] hold covered it.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the hold records' stored fields.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY issued hold id in the database (Invariant 8.1, Invariant 8.2).
Check 2.1: An auditor MUST find placing actor and hold reason not blank on EVERY hold (Invariant 7.1, Invariant 7.2).
Check 2.2: An auditor MUST find placement instant set on EVERY hold (Invariant 7.3).
Check 2.3: An auditor MUST find record reference not blank on EVERY hold (Operation 4).
Check 2.4: An auditor MUST find hold id not blank on EVERY hold (Identity 2, Instance 2).
Check 3.1: An auditor MUST find releasing actor and release reason not blank on EVERY released hold (Invariant 5.1, Invariant 5.2).
Check 3.2: An auditor MUST find release instant set on EVERY released hold (Invariant 5.3).
Check 3.3: An auditor MUST find no released hold whose release instant PRECEDES the hold's placement instant (Invariant 6.1).
Check 4.1: An auditor MUST find a second hold over one record still active once the first hold is released (Invariant 4.1).
Check 5.1: An auditor MUST find already-released answered for a release against a released hold (Operation 14, Invariant 3.1).
Check 5.2: An auditor MUST find a released hold's fields unchanged by that refused release (Invariant 1.1, Invariant 1.2).
Check 6.1: An auditor MUST find the hold set never shrinking across two readings (Invariant 8.2).
Check 6.2: An auditor MUST find EVERY placement field unchanged across two readings (Invariant 1.1).
Check 6.3: An auditor MUST read an active-to-released move between two readings as conformant (Invariant 2.1).
Deleted: Check 7.1. Execution Contract Conformance 9 owns it.
```

### External checks

```
External check 1: An auditor MUST read whether a held record was purged from the composing pattern's purge records (Non-goal 1, Composition note 2).
External check 2: An auditor MUST read who was permitted to place a hold from the composing Permissions records (Non-goal 7).
External check 3: An auditor MUST read a hold record's integrity from the composing Tamper Evidence seals (Non-goal 11).
External check 4: An auditor MUST read the matter a case reference names from the deployment's case-management system (Non-goal 9).
Deleted: External check 5. Execution Contract Conformance 9 owns it.
```

NOTE: EVERY check names the rule the check tests. The hold records answer *what was preserved, by whom, and for how long*; whether the preservation was honoured at the purge surface is the composing pattern's record, because this atom deliberately enforces nothing (Non-goal 1).

## Non-goals

```
Non-goal 1: The atom MUST NOT block a purge.
Non-goal 2: A deployment needing an enforced hold MUST compose Defensible Retention.
Non-goal 3: The atom MUST NOT read the record a record reference names.
Non-goal 4: The atom MUST NOT refuse a hold over a destroyed record.
Non-goal 5: The atom MUST NOT deduplicate two holds.
Non-goal 6: A deployment needing at-most-once placement MUST compose Duplicate Prevention.
Non-goal 7: The atom MUST NOT gate who places a hold.
Non-goal 8: A deployment needing gated placement MUST compose Permissions.
Non-goal 9: The atom MUST NOT hold a matter's lifecycle.
Non-goal 10: The atom MUST NOT release every hold over a record in one call.
Non-goal 11: The atom MUST NOT detect tampering with a hold record.
Non-goal 12: A deployment needing court-admissible hold records MUST compose Tamper Evidence.
Non-goal 13: The atom MUST NOT place one hold over two records.
Non-goal 14: The atom MUST NOT import a retention policy.
Non-goal 15: The atom MUST NOT purge a hold record.
Deleted: Non-goal 16. Execution Contract Database 4 owns it.
Non-goal 17: A deployment needing a defensible timeline MUST compose a trusted timestamping pattern.
```

NOTE: the owners — [Retention Window](./retention-window.md) and [Defensible Retention](../compositions/defensible-retention.md) (Non-goal 1, Non-goal 2, Non-goal 14); [Tamper Evidence](./tamper-evidence.md) (Non-goal 11, Non-goal 12).

Where the atom breaks down: when the preservation duty is defined by a query rather than a record — *everything touching Project Alpha* — which needs a composing pattern to enumerate and place; when the hold must survive the database that holds it, which needs an external anchor; when who may lift a hold is part of the obligation, which is Permissions' and not a field here.

## Edge cases

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Concurrency 3: Two placements over one record MUST record two holds.
```

### Back-dating a placement

```
Backdating 1: [Place] MUST accept a placement instant below now.
Backdating 2: [Place] MUST NOT accept a placement instant above now.
Backdating 3: The deployment MUST own the evidentiary weight of a back-dated placement instant.
```

### Place persistence failure

```
Place persistence 1: A caller MUST read storage-failure from [Place] as the record standing unheld.
Place persistence 2: A caller MUST retry a place that answered storage-failure.
Place persistence 3: A high-assurance deployment MUST raise an alert on storage-failure from [Place].
Place persistence 4: A caller MUST NOT read storage-failure from [Release] as the obligation standing ended.
```

### The aggregate question

```
Aggregate 1: A composing pattern MUST read a record's active holds to answer whether the record is held.
Aggregate 2: The atom MUST NOT carry a held flag on a record.
Aggregate 3: A composing pattern MUST read an empty active set as the record standing unheld ONLY IF the answered database name matches the record's database instance.
```

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST check a record's active holds at the purge surface.
Composition note 3: A composing pattern MUST own who may place a hold.
Composition note 4: A composing pattern MUST own who may release a hold.
Composition note 5: A composing pattern MUST own a bulk placement.
Composition note 6: A composing pattern MUST own a bulk release.
```

NOTE: composing patterns — [Defensible Retention](../compositions/defensible-retention.md), [Audit Trail](../compositions/audit-trail.md).

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the deployment; a composing pattern (also: a pattern); a business caller; a caller; an auditor; the database; a hold; a release; a placement; a query.

Term records: hold — one preservation obligation, carrying hold id, record reference, placing actor, hold reason, placement instant, a hold state and, where they exist, case reference, releasing actor, release reason and release instant.

Term record verbs: supply, judge, purge, retry, raise, match, share, hold, reach, route, identify, allocate, reuse, reassign, sort, carry, stand, offer, delete, record, answer, stamp, accept, read, order, write, change, rest, shrink, find, block, refuse, deduplicate, gate, release, detect, place, import, own, check, compose, declare, precede, fall.

Term value sets: hold state = active | released.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: database instance, hold, hold id, record reference, seam, transition, business caller, now, hold state, placing actor, hold reason, placement instant, case reference, releasing actor, release reason, release instant, query, resolved release instant, admitted axis, held at an instant.

#### Place

The behavior that records a new preservation hold against a record. It assigns a fresh [Hold Id], stamps [Placement Instant], records [Record Reference], [Placing Actor], [Hold Reason], and [Case Reference] (if supplied), and returns the [Hold Id] (or a rejection). The hold enters [Active].

Kind: Operation

#### Release

The behavior that documents the end of a preservation obligation, transitioning an [Active] hold to [Released] and recording [Releasing Actor], [Release Reason], and [Release Instant]. A [Released] hold cannot be released again ([Already Released]); releasing one hold never affects another on the same record (Invariant 4).

Kind: Operation

#### Read

The read-only behavior that returns the holds matching a [Query] together with the [Database Name] of the instance the read was routed to, ordered by [Placement Instant] ascending then [Hold Id] ascending. It changes nothing. Filters by [Hold Id], [Record Reference], [Placing Actor], [Case Reference], [State], or time range are combinable; the query `{record_ref: X, state: Active}` is the operational "is this record held?" check.

Kind: Operation

#### Hold Id

The opaque, immutable, system-generated identity of a hold, assigned on [Place], never reused or reassigned within the database instance. A non-empty string sortable in lexicographic byte-order — required for deterministic [Read] ordering. The record, actor, reason, and timestamps are properties of the hold, not its identity.

Kind:       Field
Field of:   the hold record
Projection: hold_id

#### Record Reference

The opaque reference to the record being held. Set on [Place], immutable, never validated against any storage layer. Multiple holds may name the same [Record Reference]; each is an independent hold.

Kind:       Field
Field of:   the hold record
Projection: record_ref

#### Placing Actor

The opaque reference to the actor placing the hold — the attribution anchor for the preservation decision. Set on [Place], immutable; empty or whitespace-only is rejected (Invariant 7).

Kind:       Field
Field of:   the hold record
Projection: placed_by

#### Hold Reason

The required, non-empty narrative for the hold — written from the [Reason] parameter at [Place]. Set on [Place], immutable (Invariants 1 and 7). Carries the proportionality/scope explanation a court expects.

Kind:       Field
Field of:   the hold record
Projection: hold_reason

#### Placement Instant

The timestamp the hold was placed — supplied or defaulted to the receiving node's wall clock; must not be future. Set on [Place], immutable. The lower bound for [Release Instant] (Invariant 6) and the ordering key for [Read].

Kind:       Field
Field of:   the hold record
Projection: placed_at

#### Case Reference

The optional opaque reference to the legal matter, investigation, or audit. Set on [Place] if supplied (then immutable); its absence is valid. A positive [Case Reference] filter excludes holds without one.

Kind:       Field
Field of:   the hold record
Projection: case_ref

#### State

The hold's lifecycle state — [Active] or [Released]. Set to [Active] on [Place]; transitions once to [Released] via [Release]. Every hold is in exactly one state (Invariant 2).

Kind:       Field
Field of:   the hold record
Projection: state

#### Releasing Actor

The opaque reference to the actor releasing the hold. Set at [Release], immutable; present on [Released] holds only. Non-null required (Invariant 5).

Kind:       Field
Field of:   the hold record
Projection: released_by

#### Release Reason

The required, non-empty reason for the release — written from the [Reason] parameter at [Release]. Set at [Release], immutable; present on [Released] holds only (Invariant 5).

Kind:       Field
Field of:   the hold record
Projection: release_reason

#### Release Instant

The timestamp the hold was released — supplied or defaulted to wall clock; must not be future and must be ≥ [Placement Instant] (Invariant 6). Set at [Release], immutable; present on [Released] holds only.

Kind:       Field
Field of:   the hold record
Projection: released_at

#### Database Name

The identifier of the database instance a hold belongs to. Multiple instances coexist; [Hold Id]s are unique within an instance, while [Record Reference] is host-scoped. No action accepts it as a parameter — instance selection is handled at the deployment-routing layer.

Kind:       Field
Field of:   the database instance
Projection: store_name

#### Reason

The required, non-empty reason string [Place] and [Release] consume — written into [Hold Reason] or [Release Reason] respectively. Not stored under this name; an empty or whitespace-only value is rejected [Invalid Request].

Kind:         Parameter
Parameter of: Place and Release
Projection:   reason

#### Query

The selection [Read] consumes — a filter over [Hold Id], [Record Reference], [Placing Actor], [Case Reference], [State], and/or a time range on [Placement Instant] or [Release Instant]. Each time range carries a start and an end, and an instant at either end lies inside it; a hold matches a combined query only where it matches each filter. Supplied per call, not stored; a malformed one is rejected [Invalid Query].

Kind:         Parameter
Parameter of: Read
Projection:   query

#### Active

The non-terminal state of a hold whose preservation obligation is in effect. A composition wiring this atom to a purge surface treats an [Active] hold as blocking purge. May be released or read.

Kind:      Member
Member of: the hold state
Role:      Outcome

#### Released

The terminal state of a hold whose preservation obligation has ended. Carries [Releasing Actor], [Release Reason], and [Release Instant]; retained as audit evidence, no further transition (Invariant 3).

Kind:      Member
Member of: the hold state
Role:      Outcome

#### Invalid Request

The refusal [Place] or [Release] returns when request fields fail — an empty/whitespace [Record Reference], [Placing Actor], [Reason], [Case Reference], [Releasing Actor], or [Hold Id]; a future [Placement Instant]; or a [Release Instant] that is future or before [Placement Instant].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Not Known

The refusal [Release] returns when the named [Hold Id] references no hold in this database instance — a lookup miss (a common cause is cross-instance referencing).

Kind:       Member
Member of:  the Release rejection
Role:       Outcome
Projection: not-known

#### Already Released

The refusal [Release] returns when the target is already [Released] — terminal absorption (Invariant 3); a pure guard that writes nothing.

Kind:       Member
Member of:  the Release rejection
Role:       Outcome
Projection: already-released

#### Storage Failure

The refusal any writing action returns when a durable write fails after preconditions pass. For [Release], the hold remains [Active] (Place persistence 4).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

#### Invalid Query

The refusal [Read] returns when query parameters are malformed — a null/empty/whitespace filter value, a [State] value outside {[Active], [Released]}, a time range with end before start, or an unrecognized filter key.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Place]: #place
[Release]: #release
[Read]: #read
[Hold Id]: #hold-id
[Record Reference]: #record-reference
[Placing Actor]: #placing-actor
[Hold Reason]: #hold-reason
[Placement Instant]: #placement-instant
[Case Reference]: #case-reference
[State]: #state
[Releasing Actor]: #releasing-actor
[Release Reason]: #release-reason
[Release Instant]: #release-instant
[Database Name]: #database-name
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

- **Federal Rules of Civil Procedure Rule 37(e)** — the primary U.S. federal standard for electronic discovery preservation. A party must take reasonable steps to preserve ESI (Electronically Stored Information — digital records subject to legal discovery) once litigation is reasonably anticipated; failure to preserve when an [Active] hold should have been in place exposes the party to sanctions including adverse inference instructions. The [Placement Instant] timestamp and [Hold Reason] field are the record of when and why the preservation obligation was recognized.
- **Federal Rules of Civil Procedure Rule 26(b)** — proportionality doctrine for discovery preservation; not all records must be held, only those reasonably expected to be relevant. [Hold Reason] and [Case Reference] are the scoping fields that document proportionality.
- **Sedona Conference Principles (3rd ed.)** — the leading authoritative guidance on electronic discovery preservation obligations. Principle 5: a party is not required to preserve every document; preservation must be proportionate. Principle 6: a party should consider adoption of a litigation hold policy. The [Hold Reason] field is the policy documentation surface.
- **SOX (Sarbanes-Oxley Act) section 802 (18 U.S.C. — the United States Code — section 1519)** — criminal obstruction-of-justice provision for destruction of documents subject to federal investigation or proceedings. An [Active] Legal Hold covering the relevant records is the structural defense against section 802 exposure.
- **SEC Rule 17a-4(f)** — requires broker-dealers to preserve records in non-rewriteable, non-erasable format, accessible to regulators on demand. Legal Hold composes with Tamper Evidence to meet this standard; the hold record itself is a regulated record under 17a-4.
- **HIPAA section 164.530(j)** — documentation retention requirements; HHS investigations trigger preservation obligations over the PHI and administrative records involved. Legal Hold is the preservation mechanism.
- **HIPAA Breach Notification Rule (45 CFR (Code of Federal Regulations) section 164.400–414)** — breach investigations generate preservation obligations over the records relating to the incident. [Case Reference] references the OCR investigation case identifier.
- **GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Article 17(3)(e)** — erasure right (right to be forgotten) does not apply when processing is necessary for the establishment, exercise, or defence of legal claims. An [Active] Legal Hold is the operational record that establishes the legal-claim exception to erasure. See [Resolve a Person's Data Rights](../compositions/resolve-a-persons-data-rights.md), whose `retained(legal-hold)` disposition is the provable form of this exception.
- **21 CFR Part 11** — electronic records and signatures in FDA-regulated (US Food and Drug Administration) contexts. Preservation holds on regulated records (clinical trial data, manufacturing batch records) must be attributable and non-alterable. Composes with Actor Identity and Tamper Evidence.
- **E-SIGN Act (Electronic Signatures in Global and National Commerce Act) / UETA (Uniform Electronic Transactions Act)** — electronic hold records carry the same legal force as paper hold notices where these acts apply.
- **ISO 15489-1 (Records management)** — the International Organization for Standardization's standard for records-management practice; hold is the operational mechanism for Section 9.7 (suspension of disposition). The two-state ([Active]/[Released]) model maps directly to ISO 15489's hold lifecycle.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — legal-hold.tla + 2 twins, 2026-06-04
last gate: 2026-10-24 — Final Critique 7 — foundational count 2, not clean, no sample

open:
- 2026-10-05-a · refining · State 2; Operation 10 · a hold carries a placement instant a caller may assert and no instant the system stamped at entry, so a composing pattern cannot age or order a hold whose audit record is gone → an entry instant; reported by Defensible Retention's gate
- 2026-10-05-b · refining · Place persistence 2; Operation 8, 17; Composition note 3 through 6 · a place or a release that answers no answer has no rule, a future placement instant and a release ahead of the placement are refused only at the atom's seam, after a composing pattern's intent, and the notes that give authority and bulk to a composing pattern admit no pass-down → state each; reported by the same gate
- 2026-10-21-a · refining · Operation 29; Active and Released entries · [Read]'s hold state filter is left to the build: the hold state members carry no Projection line while the examples query `state: Active` → give the members their wire spelling
- 2026-10-21-b · refining · Operation 8, 18; Placement Instant and Release Instant entries · a supplied placement or release instant has no declared form, and the examples write two (a zoned date and time, a bare date), so a zoneless value near now is placed by a build reading it as UTC and refused as future by one reading it in the deployment's zone → declare the form a supplied instant takes, or name the layer that turns a wire value into an instant
- 2026-10-21-c · refining · State 1, 7; Invariant 2.1, 4.1, 8.1; Operation 8, 10, 18, 20, 40, 41; Backdating 1, 2; Aggregate 3; Instance 7 · propositions owned twice: State 1 and Invariant 2.1 word for word, State 7 and Invariant 8.1, Operation 10 and Backdating 1, Operation 8 with Backdating 2 and Operation 40, Operation 18 with Operation 41, Operation 20 and Invariant 4.1, Aggregate 3 and Instance 7 → one owner each (GRACE-lang Authority 3), each tombstone checked against the pages that cite it
- 2026-10-21-e · refining · Examples · no breach or incident read is walked on its own: the regulator audit is a regulator's breach investigation, and the third scenario is a dual-regulator one → walk the three regulated reads spec-format asks for, the breach read on its own
- 2026-10-21-f · refining · Check 4.1, 5.1, 6.3 · each check presupposes a history the hold records may not hold (a second hold over one record, a refused second release, a move between two readings), so an auditor holding none finds nothing to test → state each check's antecedent, or say that the auditor makes the history
- 2026-10-21-h · refining · Composition note 2; Aggregate 1 · a composing pattern's check of a record's active holds at the purge surface can race a placement over the record, and no rule names who serializes them; the check and the purge are the composing pattern's one action, whose reads and writes Execution Contract Database 1 and Database 2 hold in one transaction → say so in the Composition notes
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/legal-hold.md`; the migration that got it here is in [its history](./legal-hold.hist.md).

- **2026-10-24 — [Release]'s refusal order is the Execution Contract's.** *Chose:* the refuses line listing not-known, already-released, invalid-request, then storage-failure, which answers only at the write, and Operation 13 answering not-known only for a hold id that is not blank, so Execution Contract Refusal 1 answers the order the page kept as its own: a blank hold id first, then an unknown hold, a released hold, a blank attribution and the two time guards; Operation 42 deleted to Refusal 1, and Term release refusal order with it. *Over:* Operation 42 kept, which names neither a refusal nor the ground one answers on, so Refusal 1's second sentence reads it as keeping [Release] from no refusal and the line's invalid-request answers ahead of not-known and already-released. *Because:* Final Critique 6 found two builds answering one call differently, one by Operation 42 and one by the refuses line; the maintainer ruled on 2026-10-21 that a page keeps its own order only where a fixed line cannot express it, and with not-known held to a hold id that is not blank, one fixed line expresses this one. What [Release] answers on every call is unchanged.

- **2026-10-22 — The wiring is read outside the records, and a ban on refusing names its ground, as the Execution Contract says.** *Chose:* External check 5, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 7.1's tombstone, which named it, now naming the contract; Non-goal 4 kept as written and read by Execution Contract Refusal 1's second sentence, so the ban names its ground, a hold over a destroyed record, and keeps [Place] from no refusal its line declares, a blank or malformed input still answering invalid-request; both labels cited on Capability requirement 4; rules 132 to 131. *Over:* the page stating for itself that the wiring is an external check; Non-goal 4 read alone, keeping [Place] from every refusal on a hold over a destroyed record. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration and the refusal ban among them; this page's fifth Final Critique had made the first cure one specification at a time, and the 12:03Z escalation named Non-goal 4 among the refusal ban's uncured sites. What each action does and answers is unchanged.

- **2026-10-21 — [Release]'s refusal order stays the page's own.** *Chose:* Operation 42 and Term release refusal order kept, and only their watch flag removed: [Release] answers invalid-request on a blank hold id ahead of not-known, and on a blank attribution or a time fault after not-known and already-released, so invalid-request holds two places in the order and no fixed refuses line can carry both; the Execution Contract reads a refusal Operation 42 keeps [Release] from answering as not applying to the call (Execution Contract Refusal 1). [Place] and [Read] each answer one refusal before the write, so the page cites nothing new; rules 132 unchanged. *Over:* deleting the order to the contract's rule, which would answer invalid-request ahead of not-known on every call. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers, and that a page keeps its own rule only where its order depends on a condition a fixed line cannot express.

- **2026-10-21 — [Release]'s refusals answer in one stated order; [Read]'s answer carries the database name; the wiring declaration is an external check.** *Chose:* [Release]'s refusal rules evaluated in one order — a blank hold id first, then an unknown hold, a released hold, a blank attribution and the two time guards (Operation 42, Term release refusal order) — the priority Final Critique 4 stated and the GRACE-lang migration dropped; [Read]'s answers arm carrying the database name the read was routed to (`holds(store_name)`), so the name Instance 5 obliges is answered on every answered read, an empty one included; Check 7.1 deleted to External check 5, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration. *Over:* seven refusal rules any two of which could oblige different answers on one call; a database name obliged by a rule and carried by no declared answer, which a build could put on each hold, leaving an empty answer with nothing for a composing pattern to match (Instance 7, Aggregate 3); and a conformance check no hold record can answer. *Because:* Final Critique 5 found each a divergence between conforming builds, two rules no build can both obey, or a check a conforming deployment fails, and the corpus held each cure: the refusal order Approval Step, Retention Window and Selective Disclosure carry, in this page's own Final Critique 4 priority; the signature form, whose arm carries the names an answer holds; and the external check to which Actor Identity, Tamper Evidence, Retention Window, Permissions and Assignment moved the same check. What each action does on a call it admits is unchanged.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the hold store supplied under Execution Contract Store 1 through 4 (Capability requirement 4), and the five rules that restated them tombstoned to their owner — Invariant 8.3, no partial hold left by a storage-failure from [Place], to Store 1; Concurrency 1 and 2, two releases of one hold id serialized and the later one answering already-released, to Store 2; Operation 22, a release the store refused leaving the hold active, to Store 3; Non-goal 16, a deployment's sweep of the hold store leaving every stored field as written, to Store 4; rules 135 to 131. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The caller's reading of a refused place or release stays the atom's own (Place persistence 1 through 4), as do two placements over one record recording two holds (Concurrency 3), the placement fields that never change (Invariant 1.1) and the atom's no-removal rules (State 7, Invariant 8.1, Invariant 8.2, Non-goal 15). Held at an instant is read from the placement and release instants each hold carries, and [Read] orders by placement instant and hold id, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

NOTE: End of Legal Hold.
