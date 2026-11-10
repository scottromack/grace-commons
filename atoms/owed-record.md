---
title: Owed Record
id: 49
parent: Atomic Concepts
has_toc: true
toc: true
---

# Owed Record

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Owed Record keeps the durable record that something is owed. When a pattern does something that leaves a write still to be made — an audit record to land, an approval to be closed, a provisional entry to be replaced by a final one — it records an owed record in the same transaction (the one step that commits the cause whole or not at all), so the obligation exists exactly when its cause does. The owed record names the owing pattern, its own id, the cause that created it and the instant it falls due. It is met by a discharge, exactly once, naming the record that fulfilled it; if its due-by instant comes first, a sweep flags it for a person, who may still discharge it later. The atom does not make the owed write, does not run the sweep and does not decide what a person does with a flag; those belong to the patterns that compose it. It carries no message and delivers nothing.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

A composition often does one thing now and owes another later. Audit Trail commits an act and owes the audit record of it; Multi-Party Approval opens a chain and owes its close; Capability-Backed Sharing hands out a token and owes the sealed entry that replaces its pending mark. Between the two, the obligation has to live somewhere. If it lives in the process's memory, a crash forgets it. If each composition keeps its own pending list, the corpus holds the same idea in six places, and each list is a record no constituent can rebuild — the Execution Contract's *extraction-pending* debt (the section titled Composition state in `execution-contract.md`). Six compositions already name that debt against this atom.

This atom is the one home for it. An owed record is written in the cause's own transaction (Execution Contract Database 1), so a cause never commits without its obligation and an obligation never stands for a cause that rolled back. It is discharged once, by naming what fulfilled it, so an auditor can match every obligation to its fulfilment. And an obligation that is not met in time does not vanish or retry forever: it is flagged, with the instant and the actor, for a person to settle.

The atom keeps the record and nothing else. It holds no body and reaches no outside system — a message to deliver belongs to [Notification Fanout](../compositions/notification-fanout.md) — and the protocol that makes and recovers the owed write is the composing pattern's.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify an owed record by the owing pattern and the owed id.
Identity 2: The atom MUST NOT interpret an owed id.
Identity 3: The atom MUST NOT interpret a cause id.
Identity 4: The atom MUST NOT interpret a fulfilment id.
Identity 5: The atom MUST NOT interpret an actor reference.
```

Term owed record: the record that one write is owed — the record this atom holds.

Term owing pattern: the name of the pattern that owes the write — an [Owing Pattern].

Term owed id: the opaque id the owing pattern gives the obligation — an [Owed Id].

Term cause id: the opaque id of the record whose commit created the obligation — a [Cause Id].

Term fulfilment id: the opaque id of the record that met the obligation — a [Fulfilment Id].

Term actor reference: the opaque reference naming the actor or system identity that flagged the owed record — an [Actor Reference].

Term seam: the atom's I/O (input and output) boundary; the host injects the clock reading here.

### State

```
State 1: EVERY owed record MUST stand in EXACTLY ONE OF open, flagged, discharged.
State 2: EVERY owed record MUST carry owing pattern, owed id, cause id, recording instant, due-by instant and status.
State 3: A discharged owed record MUST carry a fulfilment id and a discharge instant.
State 4: A flagged owed record MUST carry a flag instant and an actor reference.
State 5: An open owed record MUST NOT carry a fulfilment id.
State 6: An open owed record MUST NOT carry a flag instant.
State 7: The atom MUST NOT offer a transition out of discharged.
State 8: The atom MUST NOT offer a transition from flagged to open.
State 9: The atom MUST NOT remove an owed record from the database.
```

Term status: open | flagged | discharged — owed and not yet flagged, owed and flagged for a person, met. A [Status] is an [Open], [Flagged] or [Discharged] value.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the owed records PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 4, Execution Contract Refusal 1 and Execution Contract Input 1.
Capability requirement 3: The deployment MAY override the id cap.
Capability requirement 4: The deployment MAY override the pattern name cap.
Capability requirement 5: The deployment MAY override the page size.
Capability requirement 6: The deployment MAY override a bound ONLY IF the override EXCEEDS zero.
```

Term id cap: 256 characters — the longest owed id, cause id, fulfilment id or actor reference the atom accepts, unless the deployment overrides it.

Term pattern name cap: 128 characters — the longest owing pattern the atom accepts, unless the deployment overrides it.

Term page size: 1,000 owed records — the most [List Owed] answers in one call, unless the deployment overrides it.

Term zero: the count of nothing — the floor an overriding bound and a due-by window must exceed.

### Operations

```
record_owed(owing_pattern, owed_id, cause_id, due_by_window)
  answers recorded
  refuses duplicate | invalid-request | storage-failure

discharge(owing_pattern, owed_id, fulfilment_id)
  answers discharged
  refuses not-known | already-discharged | invalid-request | storage-failure

flag(owing_pattern, owed_id, actor_ref)
  answers flagged
  refuses not-known | already-discharged | already-flagged | not-due | invalid-request | storage-failure

list_owed(owing_pattern, listed_status, optional continuation_key)
  answers the matching owed records
  refuses invalid-request
```

```
Operation 1: [Record Owed] MUST record EXACTLY ONE owed record per successful call.
Operation 2: [Record Owed] MUST stand the owed record in open.
Operation 3: [Record Owed] MUST stamp recording instant from the injected now.
Operation 4: [Record Owed] MUST stamp due-by instant from the due-by deadline.
Operation 5: [Record Owed] MUST answer recorded.
Operation 6: IF an owed record EXISTS for the owing pattern and the owed id THEN [Record Owed] MUST answer duplicate.
Operation 7: IF owing pattern EQUALS blank OR owed id EQUALS blank OR cause id EQUALS blank OR due-by window EQUALS blank THEN [Record Owed] MUST answer invalid-request.
Operation 8: IF due-by window DOES NOT EXCEED zero THEN [Record Owed] MUST answer invalid-request.
Operation 9: IF owing pattern EXCEEDS the pattern name cap THEN [Record Owed] MUST answer invalid-request.
Operation 10: IF owed id EXCEEDS the id cap OR cause id EXCEEDS the id cap THEN [Record Owed] MUST answer invalid-request.
Operation 11: IF the database refuses the write THEN [Record Owed] MUST answer storage-failure.
Operation 12: IF owing pattern DOES NOT EQUAL blank AND owed id DOES NOT EQUAL blank AND no owed record EXISTS for the owing pattern and the owed id THEN [Discharge] MUST answer not-known.
Operation 13: IF the owed record's status EQUALS discharged THEN [Discharge] MUST answer already-discharged.
Operation 14: IF fulfilment id EQUALS blank OR fulfilment id EXCEEDS the id cap THEN [Discharge] MUST answer invalid-request.
Operation 15: [Discharge] MUST accept an owed record whose status IS IN open, flagged.
Operation 16: [Discharge] MUST stand the owed record in discharged.
Operation 17: [Discharge] MUST stamp discharge instant from the injected now.
Operation 18: [Discharge] MUST record the fulfilment id on the owed record.
Operation 19: [Discharge] MUST answer discharged.
Operation 20: IF the database refuses the write THEN [Discharge] MUST answer storage-failure.
Operation 21: IF owing pattern DOES NOT EQUAL blank AND owed id DOES NOT EQUAL blank AND no owed record EXISTS for the owing pattern and the owed id THEN [Flag] MUST answer not-known.
Operation 22: IF the owed record's status EQUALS discharged THEN [Flag] MUST answer already-discharged.
Operation 23: IF the owed record's status EQUALS flagged THEN [Flag] MUST answer already-flagged.
Operation 24: IF now PRECEDES the owed record's due-by instant THEN [Flag] MUST answer not-due.
Operation 25: IF actor reference EQUALS blank OR actor reference EXCEEDS the id cap THEN [Flag] MUST answer invalid-request.
Operation 26: [Flag] MUST stand the owed record in flagged.
Operation 27: [Flag] MUST stamp flag instant from the injected now.
Operation 28: [Flag] MUST record the actor reference on the owed record.
Operation 29: [Flag] MUST answer flagged.
Operation 30: IF the database refuses the write THEN [Flag] MUST answer storage-failure.
Operation 31: [List Owed] MUST answer the matching owed records with the earliest listing keys, up to the page size.
Operation 32: [List Owed] MUST order the answer by due-by instant, then by owed id.
Deleted: Operation 33. Term matching owed record owns it.
Operation 34: IF owing pattern EQUALS blank THEN [List Owed] MUST answer invalid-request.
Operation 35: IF listed status IS NOT IN open, flagged THEN [List Owed] MUST answer invalid-request.
Operation 36: [List Owed] MUST NOT write.
Operation 37: The atom MUST NOT offer a removal action.
Operation 38: The atom MUST NOT offer a reopen action.
Operation 39: [List Owed] MUST NOT answer an owed record that is not a matching owed record.
Operation 40: IF continuation key DOES NOT EQUAL blank AND the continuation key is malformed THEN [List Owed] MUST answer invalid-request.
Operation 41: IF a due-by window is malformed THEN [Record Owed] MUST answer invalid-request (Execution Contract Input 1).
Operation 42: IF owing pattern EQUALS blank OR owed id EQUALS blank THEN [Discharge] MUST answer invalid-request.
Operation 43: IF owing pattern EQUALS blank OR owed id EQUALS blank THEN [Flag] MUST answer invalid-request.
```

NOTE: watch the blank id (Operation 12, Operation 21).

NOTE: watch the blank optional input (Term matching owed record).

NOTE: watch the untyped input (Operation 41, Term due-by window).

NOTE: watch the listing page (Operation 31, Operation 39, Term matching owed record).

NOTE: open 2026-11-02-a — the atom answers no read of a discharged owed record or of one record by its ids, so a discharged record is reached only by an auditor's read of the database (Check 3.1).

NOTE: open 2026-11-02-b — a due-by window has no upper bound, so a window past the instant range [Record Owed] stamps has no rule.

Term now: the deployment's clock reading at the call — a [Now], as Execution Contract Logic confinement 11 declares it.

Term due-by window: the whole number of seconds a [Record Owed] call allows for the obligation to be met — a [Due-By Window], malformed where it is not a whole number; consumed to compute the due-by deadline, never stored under this name.

Term due-by deadline: `(recording_instant + due_by_window)` — what [Record Owed] stores as due-by instant, computed once.

Term recording instant: the instant the owed record was recorded, which is the instant its cause committed — a [Recording Instant].

Term due-by instant: the instant the obligation falls due — a [Due-By Instant]; stamped at recording, never changed.

Term discharge instant: the instant the obligation was met — a [Discharge Instant].

Term flag instant: the instant the owed record was flagged for a person — a [Flag Instant].

Term listed status: the status a [List Owed] call asks for, open or flagged — a [Listed Status].

Term listing key: an owed record's due-by instant paired with its owed id, compared first by instant, then by id in code point order (Execution Contract Logic confinement 10).

Term continuation key: the listing key of the last owed record a previous [List Owed] call answered — a [Continuation Key], malformed where it is not an instant paired with an owed id.

Term matching owed record: an owed record of the owing pattern whose status EQUALS the listed status, only where the listing key EXCEEDS the continuation key where continuation key DOES NOT EQUAL blank. Where none match the answer is empty.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Record Owed] | every id present and within its cap, a window above zero, no owed record for the pair, database accepts | recorded | one owed record lands in [Open], recording instant and due-by instant stamped (Operation 1 through 5) |
| [Record Owed] | an owed record already names the pair | [Duplicate] | none (Operation 6) |
| [Record Owed] | a blank or over-long id, a blank or malformed window, or a window of zero or less | [Invalid Request] | none (Operation 7 through 10, Operation 41) |
| [Discharge] | the record is [Open] or [Flagged], a fulfilment id present | discharged | the record moves to [Discharged], fulfilment id and discharge instant written (Operation 15 through 19) |
| [Discharge] | a pair that is not blank and names nothing | [Not Known] | none (Operation 12) |
| [Discharge], [Flag] | a blank owing pattern or a blank owed id | [Invalid Request] | none (Operation 42, Operation 43) |
| [Discharge] | the record is [Discharged] | [Already Discharged] | none (Operation 13) |
| [Flag] | the record is [Open], its due-by instant reached, an actor present | flagged | the record moves to [Flagged], flag instant and actor written (Operation 26 through 29) |
| [Flag] | the record is [Open] and its due-by instant still ahead | [Not Due] | none (Operation 24) |
| [Flag] | the record is [Flagged] or [Discharged] | [Already Flagged] or [Already Discharged] | none (Operation 22, Operation 23) |
| [Record Owed], [Discharge], [Flag] | database refuses the write | [Storage Failure] | none, and the caller's transaction rolls back with it (Operation 11, Operation 20, Operation 30) |
| [List Owed] | a pattern, open or flagged, an optional continuation key | the matching owed records with the earliest listing keys, up to the page size, in listing-key order; none where none match | none (Operation 31, Operation 32, Operation 39) |
| [List Owed] | a blank pattern, a status other than open or flagged, or a malformed continuation key | [Invalid Request] | none (Operation 34, Operation 35, Operation 40) |

### Invariants

- **Invariant 1 — What was owed never changes.**
  ```
  Invariant 1.1: A recorded owed record's owing pattern, owed id, cause id, recording instant and due-by instant MUST NOT change.
  Invariant 1.2: A written settlement field MUST NOT change.
  ```
- **Invariant 2 — One owed record per obligation.**
  ```
  Invariant 2.1: Two owed records MUST NOT share an owing pattern and an owed id.
  Invariant 2.2: The database MUST refuse a write recording a second owed record for one owing pattern and one owed id.
  ```
- **Invariant 3 — Discharged once.**
  ```
  Invariant 3.1: The successful [Discharge] calls on one owed record MUST NOT EXCEED one.
  Invariant 3.2: A discharged owed record MUST NOT leave discharged.
  ```
- **Invariant 4 — Flagged only when due.**
  ```
  Invariant 4.1: A flagged owed record's flag instant MUST NOT fall below the owed record's due-by instant.
  ```
- **Invariant 5 — Nothing is lost.**
  ```
  Invariant 5.1: The atom MUST NOT offer a removal surface.
  ```

Term settlement field: fulfilment id | discharge instant | flag instant | actor reference — what [Discharge] and [Flag] write and nothing else does.

Invariants 1 and 2 give *a fixed obligation*: what was owed, by whom and for what cause reads the same forever, once. Invariant 3 gives *exactly-once fulfilment*. Invariant 4 gives *honest escalation*: no obligation is flagged before it is due. Invariant 5 gives *completeness*: the atom removes no obligation, so each one it recorded stays there to be matched against its fulfilment or its flag, until a composed Retention Window purges it (Non-goal 9).

---

## Examples

### An audit record owed

Audit Trail commits an act `act_51c0` and, in the same transaction, calls `record_owed(owing_pattern: "audit-trail", owed_id: "aud_51c0", cause_id: "act_51c0", due_by_window: 300)`, with the host injecting `now: 2026-11-02T13:00:00Z` → recorded. The owed record stands in [Open], due at 13:05:00.

At 13:00:02 the audit record `evt_9a12` lands, and Audit Trail calls `discharge(owing_pattern: "audit-trail", owed_id: "aud_51c0", fulfilment_id: "evt_9a12")` → discharged. An auditor can now match the act to its audit record through the owed record.

### An obligation that ages out

A process crashes after recording `aud_6d33` and before writing its audit record. At 13:20 the composing sweep lists `list_owed(owing_pattern: "audit-trail", listed_status: open)`, finds `aud_6d33` past due, and calls `flag(owing_pattern: "audit-trail", owed_id: "aud_6d33", actor_ref: "svc_sweep_s01")` → flagged. The next morning an operator reconstructs the audit record `evt_9b40` and discharges the owed record with it; the flag instant and the sweep that set it stay on the record.

### Rejection paths

`flag(owing_pattern: "audit-trail", owed_id: "aud_51c0", actor_ref: "svc_sweep_s01")` at 13:01 → not-due: the obligation is not yet due (Operation 24).

A second `discharge(..., owed_id: "aud_51c0", fulfilment_id: "evt_9a13")` → already-discharged; the first fulfilment stands (Operation 13).

`record_owed(..., due_by_window: 0)` → invalid-request (Operation 8).

`record_owed(...)` whose write the database refuses → storage-failure, and the act it rode with rolls back: there is no act without its obligation (Operation 11, Composition note 1).

### Regulated adversarial scenarios

- **Regulator audit — was every act recorded?** The auditor reads every owed record of Audit Trail from the database, lists the open and flagged ones through [List Owed], and matches each discharged one to its fulfilment id (Check 3.1). Every flagged one is an act whose record was late, with the instant it was found and who found it; none can be missing, because the obligation was written with the act (Invariant 5.1, Composition note 1).
- **A sweep that runs early.** A misconfigured sweep tries to flag obligations the moment they are recorded. Each call answers not-due, and no record is escalated before its time (Invariant 4.1).
- **Two writers settle one obligation.** A recovering process and an operator discharge the same owed record at once. One lands; the other answers already-discharged, so the record names one fulfilment (Invariant 3.1).

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the owed records, with their committed versions (Execution Contract Generation acceptance 1).

### Conformance checks

```
Check 1.1: An auditor MUST find owing pattern, owed id, cause id, recording instant, due-by instant and status on EVERY owed record (State 2).
Check 1.2: An auditor MUST find one owing pattern, owed id, cause id, recording instant and due-by instant per owed record across the owed record's whole life (Invariant 1.1; Execution Contract Generation acceptance 1).
Check 2.1: An auditor MUST find no two owed records sharing an owing pattern and an owed id (Invariant 2.1).
Check 3.1: An auditor MUST find a fulfilment id and a discharge instant on EVERY discharged owed record (State 3).
Check 3.2: An auditor MUST find a flag instant and an actor reference on EVERY flagged owed record (State 4).
Check 4.1: An auditor MUST find no flag instant below the owed record's due-by instant (Invariant 4.1).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: An auditor MUST read whether a fulfilment id names a real record from the owing pattern's records (Non-goal 2).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT make the owed write.
Non-goal 2: The atom MUST NOT confirm a fulfilment id names a record.
Non-goal 3: The atom MUST NOT run a sweep.
Non-goal 4: A deployment needing a sweep MUST compose Recoverable Invocation.
Non-goal 5: The atom MUST NOT decide what becomes of a flagged owed record.
Non-goal 6: The atom MUST NOT carry a message body.
Non-goal 7: A deployment delivering a message MUST compose Notification Fanout.
Non-goal 8: The atom MUST NOT retain an owed record for a period.
Non-goal 9: A deployment bounding the owed records' lifetime MUST compose Retention Window.
Non-goal 10: The atom MUST NOT attest an actor reference.
Non-goal 11: A deployment needing an attested actor MUST compose Actor Identity.
```

NOTE: the owners — the owing pattern (Non-goal 1, Non-goal 2); [Recoverable Invocation](../compositions/recoverable-invocation.md) (Non-goal 3, Non-goal 4); the deployment's operator (Non-goal 5); [Notification Fanout](../compositions/notification-fanout.md) (Non-goal 6, Non-goal 7); [Retention Window](./retention-window.md) (Non-goal 8, Non-goal 9); [Actor Identity](./actor-identity.md) (Non-goal 10, Non-goal 11).

NOTE: open 2026-11-03-a — Non-goal 1, Non-goal 2 and Non-goal 5 name their owners (the owing pattern, the deployment's operator) with no page to link, which the Non-goals form asks for.

## Edge cases

### Clock dependence

```
Clock dependence 1: A guard MAY read now ONLY IF the guard compares now with a due-by instant.
Clock dependence 2: The atom MUST NOT accept a caller-supplied instant.
```

### Concurrency

```
Concurrency 1: IF two [Discharge] calls name one owed record THEN EXACTLY ONE call MUST answer discharged.
Concurrency 2: IF a [Flag] call and a [Discharge] call name one owed record THEN the [Discharge] call MUST answer discharged.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
```

## Composition notes

```
Composition note 1: A composing pattern MUST call [Record Owed] in the transaction that commits the cause (Execution Contract Database 1).
Composition note 2: A composing pattern MUST call [Discharge] in the transaction that writes the fulfilment.
Composition note 3: A composing pattern MUST own the meaning of an owed id.
Composition note 4: A composing pattern MUST own the due-by window.
```

NOTE: composing patterns — the compositions whose Composition state names an extraction-pending fact against this atom, under its former name Outbox: [Privileged Access Provisioning](../compositions/privileged-access-provisioning.md), [Resolve a Person's Data Rights](../compositions/resolve-a-persons-data-rights.md), [Execute Gated Workflow](../compositions/execute-gated-workflow.md), [Capability-Backed Sharing](../compositions/capability-backed-sharing.md), [Multi-Party Approval](../compositions/multi-party-approval.md); and [Recoverable Invocation](../compositions/recoverable-invocation.md), whose intent records are the same shape.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment; a composing pattern; a caller; a guard; an auditor; the database; an owed record; a write; an action; a call; a string input; an opaque reference; an override; a bound; a sweep.

Term records: owed record — the record that one write is owed, carrying owing pattern, owed id, cause id, recording instant, due-by instant and status and, once settled, fulfilment id and discharge instant, or flag instant and actor reference.

Term record verbs: identify, interpret, stand, carry, offer, remove, supply, override, exceed, record, stamp, answer, accept, read, write, order, change, share, refuse, leave, fall, find, make, confirm, run, decide, retain, attest, compose, compare, trim, normalize, case-fold, call, own.

Term value sets: status = open | flagged | discharged. listed status = open | flagged. settlement field = fulfilment id | discharge instant | flag instant | actor reference.

Term bounds: id cap (the longest id the atom accepts); pattern name cap (the longest owing pattern the atom accepts); page size (the most owed records [List Owed] answers in one call); zero (the floor an overriding bound and a due-by window must exceed).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.69 (2026-11-01) through the Grace connector.

Term terms: owed record, owing pattern, owed id, cause id, fulfilment id, actor reference, seam, status, id cap, pattern name cap, page size, zero, now, due-by window, due-by deadline, recording instant, due-by instant, discharge instant, flag instant, listed status, listing key, continuation key, matching owed record, settlement field, committed version.

#### Record Owed

The behavior an owing pattern invokes, in the transaction that commits a cause, to record that a write is owed. It takes the [Owing Pattern], [Owed Id], [Cause Id] and [Due-By Window], stamps [Recording Instant] and [Due-By Instant], and enters the record in [Open].

Kind: Operation

#### Discharge

The behavior that records an obligation met, naming the [Fulfilment Id]. It accepts an [Open] or [Flagged] owed record, moves it to [Discharged] and stamps [Discharge Instant]. It succeeds once per owed record.

Kind: Operation

#### Flag

The behavior a sweep invokes on an [Open] owed record whose [Due-By Instant] has come, moving it to [Flagged] and recording [Flag Instant] and [Actor Reference]. A flagged record may still be discharged.

Kind: Operation

#### List Owed

The behavior a sweep or an auditor invokes to list the owed records of one [Owing Pattern] in one [Listed Status], ordered by due-by instant then owed id, a page at a time, continuing past a [Continuation Key]. It only reads.

Kind: Operation

#### Owing Pattern

The name of the pattern that owes the write; with the [Owed Id], it identifies the owed record.

Kind:       Field
Field of:   Owed Record
Projection: owing_pattern

#### Owed Id

The opaque id the owing pattern gives the obligation.

Kind:       Field
Field of:   Owed Record
Projection: owed_id

#### Cause Id

The opaque id of the record whose commit created the obligation.

Kind:       Field
Field of:   Owed Record
Projection: cause_id

#### Fulfilment Id

The opaque id of the record that met the obligation; written by [Discharge], never changed.

Kind:       Field
Field of:   Owed Record
Projection: fulfilment_id

#### Actor Reference

The opaque reference to the actor or system identity that flagged the owed record; written by [Flag], never changed.

Kind:       Field
Field of:   Owed Record
Projection: actor_ref

#### Recording Instant

The instant [Record Owed] was called, stamped from the injected [Now].

Kind:       Field
Field of:   Owed Record
Projection: recorded_at

#### Due-By Instant

The instant the obligation falls due: [Recording Instant] plus the [Due-By Window]. Never changed.

Kind:       Field
Field of:   Owed Record
Projection: due_by

#### Discharge Instant

The instant [Discharge] was called, stamped from the injected [Now].

Kind:       Field
Field of:   Owed Record
Projection: discharged_at

#### Flag Instant

The instant [Flag] was called, stamped from the injected [Now].

Kind:       Field
Field of:   Owed Record
Projection: flagged_at

#### Status

The owed record's status: [Open], [Flagged] or [Discharged].

Kind:       Field
Field of:   Owed Record
Projection: status

#### Due-By Window

The whole number of seconds a [Record Owed] call allows, above zero; consumed to compute [Due-By Instant], never stored under this name.

Kind:         Parameter
Parameter of: Record Owed
Projection:   due_by_window

#### Listed Status

The status a [List Owed] call asks for: [Open] or [Flagged].

Kind:         Parameter
Parameter of: List Owed
Projection:   listed_status

#### Continuation Key

The due-by instant and owed id of the last owed record a previous [List Owed] call answered.

Kind:         Parameter
Parameter of: List Owed
Projection:   continuation_key

#### Now

The current clock reading every writing action consumes, injected at the seam, never a signature parameter.

Kind:         Parameter
Parameter of: Record Owed, Discharge and Flag
Projection:   now

#### Open

The status of an owed record not yet met and not yet flagged.

Kind:      Member
Member of: the owed record status
Role:      Outcome

#### Flagged

The status of an owed record a sweep found due and left for a person; it may still be discharged.

Kind:      Member
Member of: the owed record status
Role:      Outcome

#### Discharged

The final status of an owed record whose obligation was met. Absorbing.

Kind:      Member
Member of: the owed record status
Role:      Outcome

#### Duplicate

The refusal [Record Owed] answers where an owed record already names the owing pattern and owed id.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: duplicate

#### Not Known

The refusal [Discharge] or [Flag] answers where no owed record names the owing pattern and owed id.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Already Discharged

The refusal [Discharge] or [Flag] answers on a [Discharged] owed record.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: already-discharged

#### Already Flagged

The refusal [Flag] answers on a [Flagged] owed record.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: already-flagged

#### Not Due

The refusal [Flag] answers on an [Open] owed record whose [Due-By Instant] has not come.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-due

#### Invalid Request

The refusal an action answers for a blank, malformed or over-long input, a [Due-By Window] of zero or less, or a [Listed Status] other than open or flagged. Nothing is written.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Storage Failure

The refusal a writing action answers where the database refuses its write. Nothing is written, and the caller's transaction rolls back with it.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. -->

[Record Owed]: #record-owed
[Discharge]: #discharge
[Flag]: #flag
[List Owed]: #list-owed
[Owing Pattern]: #owing-pattern
[Owed Id]: #owed-id
[Cause Id]: #cause-id
[Fulfilment Id]: #fulfilment-id
[Actor Reference]: #actor-reference
[Recording Instant]: #recording-instant
[Due-By Instant]: #due-by-instant
[Discharge Instant]: #discharge-instant
[Flag Instant]: #flag-instant
[Status]: #status
[Due-By Window]: #due-by-window
[Listed Status]: #listed-status
[Continuation Key]: #continuation-key
[Now]: #now
[Open]: #open
[Flagged]: #flagged
[Discharged]: #discharged
[Duplicate]: #duplicate
[Not Known]: #not-known
[Already Discharged]: #already-discharged
[Already Flagged]: #already-flagged
[Not Due]: #not-due
[Invalid Request]: #invalid-request
[Storage Failure]: #storage-failure

## Standards references

- **Chris Richardson, *Microservices Patterns* — the Transactional Outbox** — the idea of writing an obligation in the same transaction as its cause. This atom keeps that one idea and none of the message delivery the textbook pattern carries; the corpus's delivery pattern is [Notification Fanout](../compositions/notification-fanout.md).

Inherited from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture: one purpose, the record of an obligation, separate from the write that meets it and the sweep that chases it.

---

## Status

`grounded on Final Critique 2 — 2026-11-03 at aeea14e` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 2 — 2026-11-03 at aeea14e
formal: not applicable — vote no 2026-11-02: the one guard that reads the clock, [Flag]'s not-due refusal, compares now with a due-by instant stamped once and never changed, and the atom claims no commit order of its own; its flagged-only-when-due, discharged-once and one-record-per-obligation claims are single-state properties each action's rules hold, its listing order is a sort over stored fields, and its concurrency is Execution Contract Database 2's Coverage 2026-11-10 (unit formal: more coverage for the yes votes): the page states Invariant 1 (what was owed never changes), 2 (one record per obligation), 3 (discharged once), 4 (flagged only when due), 5 (nothing is lost) (both: one record per obligation is static; discharged once and flagged only when due are steps under the clock).
last gate: 2026-11-03 — Final Critique 2, delta, frozen at aeea14e — foundational count 0, clean, one sample

open:
- 2026-11-03-a · refining · Non-goal 1; Non-goal 2; Non-goal 5 · the owners of three non-goals are the owing pattern and the deployment's operator, neither a page, so the form's link to the owner has no target → decide whether the atom names a composing pattern as owner or the form excuses a non-goal whose owner is a caller
- 2026-11-02-a · refining · List Owed; Operation 35; Check 3.1 · the atom answers no read of a discharged owed record or of one owed record by its owing pattern and owed id, so a discharged record is reached only by an auditor's read of the database, and a single record only through the pagination of its status → decide whether the atom offers a read by id and a listed status of discharged
- 2026-11-02-b · refining · Operation 8; Term due-by window · a due-by window has no upper bound, so a window past the instant range the due-by deadline can hold (or one that makes the obligation never fall due in practice) has no rule, and Execution Contract Input 2 asks a bounded input for a cap → decide whether the atom caps the window and what a call past the cap answers
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why.

- **2026-11-01 — Drafted as the owed record, under that name.** *Chose:* one record per obligation — owing pattern, owed id, cause id, recording and due-by instants — recorded in the cause's transaction, discharged once naming its fulfilment, or flagged once past due for a person, who may still discharge it; four actions; no message body and no delivery. The name is *Owed Record*, not the *Outbox* six compositions used for it. *Over:* the textbook outbox, a message queue with delivery status. *Because:* Scott ruled 2026-11-01 that the atom is the single home of an owed item, matching every citation and the shape Recoverable Invocation's intent records carry; Notification Fanout already uses *Outbox* in the textbook sense, so the name follows his rule that all things mean one thing, and the corpus already says *owed record* for this.

</details>

NOTE: End of Owed Record.
