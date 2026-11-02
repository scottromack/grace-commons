---
title: Condition Register
parent: Atomic Concepts
has_toc: true
toc: true
---

# Condition Register

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Condition Register keeps the permanent record of what a background run observed. A composing pattern declares the conditions its runs look for, each in one of two shapes. A sighting is a condition seen about one subject — one act a sweep could not close — and is recorded once per subject. A standing condition is one seen across runs — an outage of a database or a service — and is recorded as a span: it opens on the first run that sees it, its last-seen instant advances on each run that still sees it, and it closes on the first run that no longer does; a recurrence opens a new record, so each outage has its own start and end. Every record names the run that saw it and the instant from the clock. The atom deletes nothing, and the only change it makes to a record is to a standing record: its last seen and last run advance, and it closes. The register holds no judgement: what a condition means, who is told and what is done belong to the pattern that composes it.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Background runs notice things. A sweep finds an act it cannot close; a reconciliation finds the database it reads unreachable for an hour; a scan finds two writers claiming one record. What a run notices has to outlive the run: an auditor asks months later which acts were escalated and when the outage began and ended, and the answer cannot be in a log that rotates.

Three compositions found this first, and each built its own register: Recoverable Invocation's findings, Audit Trail's outage record and Immutable Ledger's write-ownership findings. Each classifies its register as *extraction-pending against Condition Register* (Execution Contract, the section titled Composition state in `execution-contract.md`). This atom is that extraction, written once from what the three agree on.

They agree on two shapes. A sighting is about one subject and happens once: the act was found escalated, and finding it again adds nothing. A standing condition is about the instance and lasts: the database was down from first seen to last seen, and the span is the fact an auditor reads. The atom keeps both, keyed so that a sighting is never recorded twice and a standing condition never stands open twice for one scope, and it keeps them forever unless the composer's retention ends them. It decides nothing about them.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a sighting by the condition and the subject.
Identity 2: The atom MUST identify a standing record by the record id.
Identity 3: The host MUST allocate a record id at the seam.
Identity 4: The atom MUST NOT reuse a record id.
Identity 5: The atom MUST NOT interpret a subject.
Identity 6: The atom MUST NOT interpret a scope.
Identity 7: The atom MUST NOT interpret a run id.
```

Term condition: a name a composing pattern declares for one thing its runs look for, with its shape — a [Condition].

Term shape: sighting | standing — whether a condition is recorded once per subject or as a span across runs.

Term sighting: the record that a condition was seen about one subject — a [Sighting].

Term standing record: the record of one span of a standing condition, from the run that first saw the condition to the last run that still saw the condition — a [Standing Record].

Term subject: the opaque id of what a sighting is about, such as one act — a [Subject].

Term scope: the opaque value a standing condition is seen in, such as a kind or a dependency; blank where the condition holds of the whole instance, not of one kind or dependency — a [Scope].

Term run id: the opaque id of the run that reported — a [Run Id].

Term record id: the opaque id of one standing record — a [Record Id].

Term seam: the atom's I/O (input and output) boundary; the host injects the clock reading and the record id here.

### State

```
State 1: EVERY sighting MUST carry condition, subject, run id and seen instant.
State 2: EVERY standing record MUST carry record id, condition, scope, first run id, first seen, last run id, last seen and status.
State 3: EVERY standing record MUST stand in EXACTLY ONE OF open, closed.
State 4: A closed standing record MUST carry a closing run id and a closing instant.
State 5: An open standing record MUST NOT carry a closing run id.
State 6: The atom MUST NOT offer a transition out of closed.
State 7: The atom MUST NOT remove a record from the database.
State 8: An open standing record MUST NOT carry a closing instant.
```

Term status: open | closed — a standing record still seen, or no longer seen. A [Status] is an [Open] or [Closed] value.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the condition records PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 4, Execution Contract Refusal 1, Execution Contract Input 1 and Execution Contract Input 2.
Capability requirement 3: The deployment MUST declare EVERY condition a composing pattern declares, with the condition's shape.
Capability requirement 4: The deployment MAY override the name cap.
Capability requirement 5: The deployment MAY override the id cap.
Capability requirement 6: The deployment MAY override the page size.
Capability requirement 7: The deployment MAY override a bound ONLY IF the override EXCEEDS zero.
Capability requirement 8: IF a record of a declared condition EXISTS THEN the deployment MUST NOT remove the declared condition.
Capability requirement 9: IF a record of a declared condition EXISTS THEN the deployment MUST NOT change the condition's shape.
```

Term declared conditions: EVERY condition the deployment declared, each with its shape.

Term name cap: 128 Unicode code points — the longest condition the atom accepts, unless the deployment overrides it.

Term id cap: 256 Unicode code points — the longest subject, scope or run id the atom accepts, unless the deployment overrides it.

Term page size: 1,000 records — the most [List Conditions] answers in one call, unless the deployment overrides it.

Term zero: the count of nothing — the floor an overriding bound must exceed.

### Operations

```
record_sighting(condition, subject, run_id)
  answers recorded
  refuses invalid-request | duplicate | storage-failure

report_standing(condition, optional scope, run_id)
  answers opened | advanced
  refuses invalid-request | storage-failure

report_clear(condition, optional scope, run_id)
  answers closed | none-open
  refuses invalid-request | storage-failure

list_conditions(condition, window_start, window_end, optional listed_status, optional continuation_key)
  answers the matching records
  refuses invalid-request
```

```
Operation 1: IF condition IS NOT IN the declared conditions THEN EVERY writing action MUST answer invalid-request.
Operation 2: IF the condition's shape DOES NOT EQUAL sighting THEN [Record Sighting] MUST answer invalid-request.
Operation 3: IF subject EQUALS blank OR run id EQUALS blank THEN [Record Sighting] MUST answer invalid-request.
Operation 4: IF a sighting EXISTS for the condition and the subject THEN [Record Sighting] MUST answer duplicate.
Operation 5: [Record Sighting] MUST record EXACTLY ONE sighting per successful call.
Operation 6: [Record Sighting] MUST stamp seen instant from the injected now.
Operation 7: [Record Sighting] MUST answer recorded.
Operation 8: IF the condition's shape DOES NOT EQUAL standing THEN [Report Standing] MUST answer invalid-request.
Operation 9: IF the condition's shape DOES NOT EQUAL standing THEN [Report Clear] MUST answer invalid-request.
Operation 10: IF run id EQUALS blank THEN [Report Standing] MUST answer invalid-request.
Operation 11: IF run id EQUALS blank THEN [Report Clear] MUST answer invalid-request.
Operation 12: IF an open standing record EXISTS for the condition and the scope THEN [Report Standing] MUST set last run id to the run id.
Operation 13: IF an open standing record EXISTS for the condition and the scope THEN [Report Standing] MUST stamp last seen from the injected now.
Operation 14: IF an open standing record EXISTS for the condition and the scope THEN [Report Standing] MUST answer advanced.
Operation 15: IF no open standing record EXISTS for the condition and the scope THEN [Report Standing] MUST record EXACTLY ONE standing record in open.
Operation 16: IF no open standing record EXISTS for the condition and the scope THEN [Report Standing] MUST set first run id and last run id to the run id.
Operation 17: IF no open standing record EXISTS for the condition and the scope THEN [Report Standing] MUST stamp first seen and last seen from the injected now.
Operation 18: IF no open standing record EXISTS for the condition and the scope THEN [Report Standing] MUST answer opened.
Operation 19: IF an open standing record EXISTS for the condition and the scope THEN [Report Clear] MUST stand the standing record in closed.
Operation 20: IF an open standing record EXISTS for the condition and the scope THEN [Report Clear] MUST record the run id as the closing run id.
Operation 21: IF an open standing record EXISTS for the condition and the scope THEN [Report Clear] MUST stamp closing instant from the injected now.
Operation 22: [Report Clear] MUST NOT change last seen.
Operation 23: IF an open standing record EXISTS for the condition and the scope THEN [Report Clear] MUST answer closed.
Operation 24: IF no open standing record EXISTS for the condition and the scope THEN [Report Clear] MUST answer none-open.
Operation 25: IF condition EXCEEDS the name cap THEN EVERY action MUST answer invalid-request.
Operation 26: IF subject EXCEEDS the id cap OR scope EXCEEDS the id cap OR run id EXCEEDS the id cap THEN EVERY writing action MUST answer invalid-request.
Operation 27: IF the database refuses the write THEN EVERY writing action MUST answer storage-failure.
Operation 28: [List Conditions] MUST answer the matching records with the earliest listing keys, up to the page size.
Operation 29: [List Conditions] MUST NOT answer a record that is not a matching record.
Deleted: Operation 30. Term matching record owns it.
Operation 31: [List Conditions] MUST order the answer by the listing key.
Deleted: Operation 32. Term matching record owns it.
Operation 33: IF window end PRECEDES window start THEN [List Conditions] MUST answer invalid-request.
Operation 34: IF condition IS NOT IN the declared conditions THEN [List Conditions] MUST answer invalid-request.
Operation 35: [List Conditions] MUST NOT write.
Operation 36: The atom MUST NOT offer a removal action.
Operation 37: The atom MUST NOT offer a reopen action.
Operation 38: [Record Sighting] MUST record the condition, the subject and the run id the call supplies.
Operation 39: IF no open standing record EXISTS for the condition and the scope THEN [Report Standing] MUST record the condition the call supplies and the record id the host allocated.
Operation 40: IF no open standing record EXISTS for the condition and the scope AND scope DOES NOT EQUAL blank THEN [Report Standing] MUST record the scope the call supplies.
Operation 41: IF no open standing record EXISTS for the condition and the scope AND scope EQUALS blank THEN [Report Standing] MUST record the scope as blank.
Operation 42: IF window start EQUALS blank OR window end EQUALS blank THEN [List Conditions] MUST answer invalid-request.
Operation 43: IF listed status DOES NOT EQUAL blank AND listed status DOES NOT EQUAL open AND listed status DOES NOT EQUAL closed THEN [List Conditions] MUST answer invalid-request.
```

NOTE: watch the required input no rule records (Operation 38, Operation 39, Operation 40, Operation 41).

NOTE: watch the blank optional input (Operation 40, Operation 41).

NOTE: watch the listing page (Operation 28, Operation 29, Term matching record).

Term now: the deployment's clock reading at the call — a [Now], as Execution Contract Logic confinement 11 declares it.

Term writing action: [Record Sighting], [Report Standing] or [Report Clear].

Term seen instant: the instant a sighting was recorded — a [Seen Instant].

Term first seen: the instant a standing record opened — a [First Seen]; with first run id, the run that first saw the condition.

Term last seen: the instant of the last call that still saw the condition — a [Last Seen]; with last run id, that run.

Term closing instant: the instant the first run that no longer saw the condition closed the standing record — a [Closing Instant].

Term span: a standing record's first seen to the standing record's last seen — the condition's start and end as the register records them.

Term window: the half-open span from window start to window end, window start included and window end excluded.

Term window start: the earliest instant a [List Conditions] call asks for — a [Window Start].

Term window end: the instant the [List Conditions] window closes — a [Window End].

Term listed status: the status a [List Conditions] call asks for, open or closed, or blank for both — a [Listed Status].

Term listing key: a record's seen instant or first seen, paired with the record's subject or record id, compared first by instant, then by id in code point order (Execution Contract Logic confinement 10).

Term continuation key: the listing key of the last record a previous [List Conditions] call answered — a [Continuation Key].

Term matching record: a sighting of the condition whose seen instant falls in the window, or a standing record of the condition whose first seen falls in the window and whose status EQUALS the listed status where listed status DOES NOT EQUAL blank — in either case only where the listing key EXCEEDS the continuation key where continuation key DOES NOT EQUAL blank. A condition has one shape, so its records are of that shape alone, and where none match the answer is empty.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Record Sighting] | a declared sighting condition, subject and run present, no sighting for the pair | recorded | one sighting lands, seen instant stamped (Operation 5, Operation 6, Operation 7, Operation 38) |
| [Record Sighting] | the pair already sighted | [Duplicate] | none (Operation 4) |
| [Report Standing] | a declared standing condition, no open record for condition and scope | opened | one standing record lands in [Open], first and last seen stamped (Operation 15 through 18, Operation 39 through 41) |
| [Report Standing] | an open record for condition and scope | advanced | last run id and last seen move (Operation 12, Operation 13, Operation 14) |
| [Report Clear] | an open record for condition and scope | closed | the record moves to [Closed], closing run and instant written, last seen unchanged (Operation 19 through 23) |
| [Report Clear] | no open record for condition and scope | [None Open] | none (Operation 24) |
| any writing action | an undeclared condition, a condition of the other shape, a blank or over-long input | [Invalid Request] | none (Operation 1 through 3, Operation 8 through 11, Operation 25, Operation 26) |
| any writing action | database refuses the write | [Storage Failure] | none (Operation 27) |
| [Report Standing], [Report Clear] | an open record whose last seen follows now | [Storage Failure] | none (Invariant 4.2, Invariant 4.3, Operation 27; Execution Contract Read 4) |
| [List Conditions] | a declared condition, a window, an optional status and continuation key | the matching records with the earliest listing keys, up to the page size, in listing-key order; none where none match | none (Operation 28, Operation 29, Operation 31) |
| [List Conditions] | an undeclared condition, a window that ends before it starts or has a blank bound, or a listed status that is not open, closed or blank | [Invalid Request] | none (Operation 33, Operation 34, Operation 42, Operation 43) |

### Invariants

- **Invariant 1 — What was seen stays seen.**
  ```
  Invariant 1.1: A recorded sighting's fields MUST NOT change.
  Invariant 1.2: A standing record's record id, condition, scope, first run id and first seen MUST NOT change.
  Invariant 1.3: A closed standing record's fields MUST NOT change.
  Invariant 1.4: The atom MUST NOT remove a record.
  ```
- **Invariant 2 — One sighting per subject.**
  ```
  Invariant 2.1: Two sightings MUST NOT share a condition and a subject.
  Invariant 2.2: The database MUST refuse a write recording a second sighting for one condition and one subject.
  ```
- **Invariant 3 — One open span per condition and scope.**
  ```
  Invariant 3.1: Two open standing records MUST NOT share a condition and a scope.
  Invariant 3.2: The database MUST refuse a write opening a second standing record for one condition and one scope.
  ```
- **Invariant 4 — A span runs forward.**
  ```
  Invariant 4.1: IF a write's last seen PRECEDES the standing record's first seen THEN the database MUST refuse the write.
  Invariant 4.2: IF a write's closing instant PRECEDES the standing record's last seen THEN the database MUST refuse the write.
  Invariant 4.3: IF a write's last seen PRECEDES the standing record's stored last seen THEN the database MUST refuse the write.
  ```
- **Invariant 5 — Every record names its run.**
  ```
  Invariant 5.1: EVERY sighting's run id MUST stand non-blank.
  Invariant 5.2: EVERY standing record's first run id and last run id MUST stand non-blank.
  ```

Invariants 1 and 4 give *a faithful history*: what a run saw reads the same forever, and a span only grows forward until it closes. Invariant 2 gives *one sighting per subject*, however many runs find it. Invariant 3 gives *distinct spans*: an outage is one record while it lasts, and a recurrence is another. Invariant 5 gives *provenance*: every record names the run that saw it.

---

## Examples

### An outage, start to end

Recoverable Invocation declares `store-unavailable` as a standing condition. At 02:00 its sweep run `run_7101` finds the payments database unreachable and calls `report_standing(condition: "store-unavailable", scope: "payment", run_id: "run_7101")` → opened, first seen 02:00. Runs at 02:15 and 02:30 still find it down; each call answers advanced, and last seen moves to 02:30. At 02:45 run `run_7104` finds it back and calls `report_clear(condition: "store-unavailable", scope: "payment", run_id: "run_7104")` → closed. The span reads 02:00 to 02:30, the closing instant 02:45: down from the first run that saw it to the last.

The next week the database drops again; `report_standing(...)` → opened, a new record with its own span.

### A sighting

The same sweep finds act `act_88e1` past its window and closes it as escalated. It calls `record_sighting(condition: "escalated", subject: "act_88e1", run_id: "run_7102")` → recorded. Every later run that meets the same act calls again and gets duplicate; the sighting stands once, with the run and instant it was first seen.

### Rejection paths

`record_sighting(condition: "store-unavailable", ...)` → invalid-request: store-unavailable is declared standing (Operation 2).

`report_standing(condition: "disk-full", ...)` where no composing pattern declared disk-full → invalid-request (Operation 1).

`report_clear(condition: "store-unavailable", scope: "ledger", run_id: "run_7105")` with nothing open for ledger → none-open, not an error, so a run reports every condition it checked (Operation 24).

### Regulated adversarial scenarios

- **Regulator audit — when did the outage begin and end?** The auditor lists the standing records of store-unavailable that opened in the quarter. Each outage is one record whose span is the first and last run that saw it, with both runs named; none can have been shortened, because first seen never changes and last seen only advances (Invariant 1.2, Invariant 4.3).
- **A run that crashes mid-outage.** The sweep dies with an outage open. The next run still sees it and advances the same record; there is no second open record (Invariant 3.1).
- **Two sweeps on one instance.** Two runs report the same outage at once. One opens the record and the other advances it, because the database serializes the two calls and the later reads the record the earlier opened (Execution Contract Database 2), with the refusal of a second open record behind it (Invariant 3.2).

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the condition records, with their committed versions (Execution Contract Generation acceptance 1).

### Conformance checks

```
Check 1.1: An auditor MUST find condition, subject, run id and seen instant on EVERY sighting (State 1).
Check 1.2: An auditor MUST find record id, condition, scope, first run id, first seen, last run id, last seen and status on EVERY standing record (State 2).
Check 1.3: An auditor MUST find EVERY sighting's fields unchanged across EVERY committed version of the sighting (Invariant 1.1; Execution Contract Generation acceptance 1).
Check 1.4: An auditor MUST find EVERY closed standing record's fields unchanged across EVERY committed version of the standing record from the commit that closed the standing record (Invariant 1.3; Execution Contract Generation acceptance 1).
Check 2.1: An auditor MUST find no two sightings sharing a condition and a subject (Invariant 2.1).
Check 3.1: An auditor MUST find no commit leaving two standing records open sharing a condition and a scope (Invariant 3.1; Execution Contract Generation acceptance 1).
Check 4.1: IF a standing record's last seen PRECEDES the standing record's first seen THEN an auditor MUST report the standing record (Invariant 4.1).
Check 4.2: An auditor MUST find EVERY standing record's record id, condition, scope, first run id and first seen unchanged across EVERY committed version of the standing record (Invariant 1.2; Execution Contract Generation acceptance 1).
Check 4.3: IF a standing record's last seen PRECEDES the standing record's last seen in an earlier committed version THEN an auditor MUST report the standing record (Invariant 4.3; Execution Contract Generation acceptance 1).
Check 4.4: IF a closed standing record's closing instant PRECEDES the standing record's last seen THEN an auditor MUST report the standing record (Invariant 4.2).
Deleted: Check 5.1. Execution Contract Database 6 owns it.
Check 5.2: An auditor MUST find a non-blank run id on EVERY sighting and a non-blank first run id and last run id on EVERY standing record (Invariant 5.1, Invariant 5.2).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: An auditor MUST read what a condition means from the composing pattern's declaration (Non-goal 1).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT give a condition a meaning.
Non-goal 2: The atom MUST NOT act on a condition.
Non-goal 3: The atom MUST NOT alert a person.
Non-goal 4: A deployment alerting on a condition MUST compose Notification Fanout.
Non-goal 5: The atom MUST NOT bound a record's lifetime.
Non-goal 6: A deployment bounding the condition records' lifetime MUST compose Retention Window.
Non-goal 7: The atom MUST NOT run a run.
Non-goal 8: A deployment needing a sweep MUST compose Recoverable Invocation.
Non-goal 9: The atom MUST NOT seal a record against modification.
Non-goal 10: A deployment needing court-admissible condition records MUST compose Tamper Evidence.
```

NOTE: the owners — the composing pattern (Non-goal 1, Non-goal 2); [Notification Fanout](../compositions/notification-fanout.md) (Non-goal 3, Non-goal 4); [Retention Window](./retention-window.md) (Non-goal 5, Non-goal 6); [Recoverable Invocation](../compositions/recoverable-invocation.md) (Non-goal 7, Non-goal 8); [Tamper Evidence](./tamper-evidence.md) (Non-goal 9, Non-goal 10).

## Edge cases

### Clock dependence

```
Clock dependence 1: A guard MUST NOT read now.
Clock dependence 2: A writing action MUST NOT accept a caller-supplied instant.
```

### Concurrency

```
Concurrency 1: IF two [Report Standing] calls name one condition and one scope and no open standing record EXISTS THEN EXACTLY ONE call MUST answer opened.
Concurrency 2: IF two [Record Sighting] calls name one condition and one subject THEN EXACTLY ONE call MUST answer recorded.
Concurrency 3: IF two [Report Clear] calls name one condition and one scope and an open standing record EXISTS THEN EXACTLY ONE call MUST answer closed.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read EVERY blank scope as one scope.
```

## Composition notes

```
Composition note 1: A composing pattern MUST declare EVERY condition the composing pattern reports, with the condition's shape.
Composition note 2: A run MUST call [Report Clear] for EVERY standing condition and scope the run checked and did not see.
Composition note 3: A failed report MUST NOT fail the rest of the run's work.
Composition note 4: A composing pattern MUST own the meaning of a scope and a subject.
```

NOTE: composing patterns — the three compositions that name an extraction-pending register against this atom: [Recoverable Invocation](../compositions/recoverable-invocation.md) (its findings, the conditions its sweep declares), [Audit Trail](../compositions/audit-trail.md) (its outage record) and [Immutable Ledger](../compositions/immutable-ledger.md) (its write-ownership findings).

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment; a composing pattern; a run; a caller; a guard; an auditor; the database; a sighting; a standing record; a record; a write; an action; a writing action; a call; a string input; an opaque reference; an override; a bound; a report.

Term records: sighting — a condition seen about one subject, carrying condition, subject, run id and seen instant. standing record — one span of a standing condition, carrying record id, condition, scope, first run id, first seen, last run id, last seen and status and, once closed, closing run id and closing instant.

Term record verbs: identify, allocate, reuse, interpret, carry, stand, offer, remove, supply, declare, override, exceed, answer, record, stamp, set, change, order, write, share, refuse, report, move, give, act, alert, bound, compose, run, seal, accept, compare, trim, normalize, case-fold, read, find, call, fail, own.

Term value sets: shape = sighting | standing. status = open | closed.

Term bounds: name cap (the longest condition the atom accepts); id cap (the longest subject, scope or run id the atom accepts); page size (the most records [List Conditions] answers in one call); zero (the floor an overriding bound must exceed).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.69 (2026-11-02) through the Grace connector.

Term terms: condition, shape, sighting, standing record, subject, scope, run id, record id, seam, status, declared conditions, name cap, id cap, page size, zero, now, writing action, seen instant, first seen, last seen, closing instant, span, window, window start, window end, listed status, listing key, continuation key, matching record, committed version.

#### Record Sighting

The behavior a run invokes to record that a declared sighting condition was seen about one [Subject]. It records once per condition and subject, stamps [Seen Instant], and answers recorded; a repeat answers [Duplicate].

Kind: Operation

#### Report Standing

The behavior a run invokes each time it sees a declared standing condition in a [Scope]. Where a record stands [Open] for the condition and scope, it advances [Last Seen] and answers advanced; where none does, it opens a [Standing Record] and answers opened.

Kind: Operation

#### Report Clear

The behavior a run invokes for a standing condition and scope it checked and did not see. It closes the open record, keeping [Last Seen], and answers closed; with nothing open it answers [None Open].

Kind: Operation

#### List Conditions

The behavior an auditor or a composing pattern invokes to list one [Condition]'s records in a window, in listing-key order, a page at a time. It only reads.

Kind: Operation

#### Condition

The declared name of what a run looked for; the deployment declares each with its shape.

Kind:       Field
Field of:   Sighting and Standing Record
Projection: condition

#### Subject

The opaque id of what a [Sighting] is about.

Kind:       Field
Field of:   Sighting
Projection: subject

#### Scope

The opaque value a standing condition was seen in; blank for a condition that holds of the whole instance.

Kind:       Field
Field of:   Standing Record
Projection: scope

#### Run Id

The opaque id of the run that reported.

Kind:       Field
Field of:   Sighting
Projection: run_id

#### Record Id

The host-allocated id of one [Standing Record].

Kind:       Field
Field of:   Standing Record
Projection: record_id

#### Seen Instant

The instant a [Sighting] was recorded, stamped from the injected [Now].

Kind:       Field
Field of:   Sighting
Projection: seen_at

#### First Seen

The instant a [Standing Record] opened, stamped from the injected [Now]; never changed.

Kind:       Field
Field of:   Standing Record
Projection: first_seen

#### Last Seen

The instant of the last call that still saw the condition, stamped from the injected [Now]; it only moves forward, and closing leaves it as it was.

Kind:       Field
Field of:   Standing Record
Projection: last_seen

#### Closing Instant

The instant the [Standing Record] closed, stamped from the injected [Now].

Kind:       Field
Field of:   Standing Record
Projection: closed_at

#### Status

A standing record's status: [Open] or [Closed].

Kind:       Field
Field of:   Standing Record
Projection: status

#### Window Start

The earliest instant a [List Conditions] call asks for, included in the window.

Kind:         Parameter
Parameter of: List Conditions
Projection:   window_start

#### Window End

The instant the [List Conditions] window closes, excluded from the window.

Kind:         Parameter
Parameter of: List Conditions
Projection:   window_end

#### Listed Status

The status a [List Conditions] call asks for among standing records, or blank for both.

Kind:         Parameter
Parameter of: List Conditions
Projection:   listed_status

#### Continuation Key

The listing key of the last record a previous [List Conditions] call answered.

Kind:         Parameter
Parameter of: List Conditions
Projection:   continuation_key

#### Now

The current clock reading every writing action consumes, injected at the seam, never a signature parameter.

Kind:         Parameter
Parameter of: Record Sighting, Report Standing and Report Clear
Projection:   now

#### Sighting

A record of one condition seen about one subject.

Kind:      Member
Member of: the shape
Role:      Outcome

#### Standing Record

A record of one span of a standing condition.

Kind:      Member
Member of: the shape
Role:      Outcome

#### Open

The status of a standing record whose condition the last run still saw.

Kind:      Member
Member of: the standing record status
Role:      Outcome

#### Closed

The status of a standing record a run found clear. Absorbing.

Kind:      Member
Member of: the standing record status
Role:      Outcome

#### None Open

The answer [Report Clear] gives where no record stands open for the condition and scope. Not an error; nothing is written.

Kind:       Member
Member of:  the Report Clear outcome
Role:       Outcome
Projection: none-open

#### Duplicate

The refusal [Record Sighting] answers where the condition and subject are already sighted.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: duplicate

#### Invalid Request

The refusal an action answers for an undeclared condition, a condition of the other shape, a blank or over-long input, a window that ends before it starts or has a blank bound, or a listed status that is not open, closed or blank. Nothing is written.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Storage Failure

The refusal a writing action answers where the database refuses its write. Nothing is written.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. -->

[Record Sighting]: #record-sighting
[Report Standing]: #report-standing
[Report Clear]: #report-clear
[List Conditions]: #list-conditions
[Condition]: #condition
[Subject]: #subject
[Scope]: #scope
[Run Id]: #run-id
[Record Id]: #record-id
[Seen Instant]: #seen-instant
[First Seen]: #first-seen
[Last Seen]: #last-seen
[Closing Instant]: #closing-instant
[Status]: #status
[Window Start]: #window-start
[Window End]: #window-end
[Listed Status]: #listed-status
[Continuation Key]: #continuation-key
[Now]: #now
[Sighting]: #sighting
[Standing Record]: #standing-record
[Open]: #open
[Closed]: #closed
[None Open]: #none-open
[Duplicate]: #duplicate
[Invalid Request]: #invalid-request
[Storage Failure]: #storage-failure

## Standards references

Inherited from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture: one purpose, the record of what a run observed, separate from the run that observes and from what is done about it.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: not applicable — vote no 2026-11-02: no guard reads the clock, which only stamps the instants (Clock dependence 1), and the atom claims no commit order of its own; its one-sighting-per-subject, one-open-span and forward-running-span claims are single-record properties the database refuses (Invariant 2.2, 3.2, 4) and each action's rules hold, its listing order is a sort over stored fields, and its concurrency is Execution Contract Database 2's
last gate: 2026-11-02 — Final Critique 1, frozen at ebdfc8e — foundational count 7, all cured, not clean, no sample

open: none
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why.

- **2026-11-02 — Drafted as the register three compositions name.** *Chose:* two shapes declared per condition — a sighting, once per condition and subject, and a standing record, one open span per condition and scope, opened, advanced and closed by runs, a recurrence opening a new record; closing keeps last seen at the last run that saw the condition; Report Clear on nothing open answers none-open, not an error; four actions; nothing deleted. *Over:* a standing condition keyed by its name alone. *Because:* Scott's interview of 2026-11-02; Recoverable Invocation keeps one store-unavailable record per kind and Audit Trail one outage per dependency, so a standing condition is keyed by condition and scope, and Recoverable Invocation's span already closes at its last sighting.

</details>

NOTE: End of Condition Register.
