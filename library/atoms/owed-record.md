---
title: Owed Record
id: 49
audience: common
has_toc: true
toc: true
---

# Owed Record

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Owed Record keeps the durable record that something is owed. When a pattern does something that leaves a write still to be made — an audit record to land, an approval to be closed, a provisional entry to be replaced by a final one — it records an owed record in the same transaction (the one step that commits the cause whole or not at all), so the obligation exists exactly when its cause does. The owed record names the owing pattern, its own id, the cause that created it and the instant it falls due. It is met by a discharge, exactly once, naming the record that fulfilled it; if its due-by instant comes first, a sweep (a scheduled run that scans for owed records past due, owned by a composing pattern) flags it for a person, who may still discharge it later. The atom does not make the owed write, does not run the sweep and does not decide what a person does with a flag; those belong to the patterns that compose it. It carries no message and delivers nothing.

<details markdown="block">
<summary>WHY</summary>

A composition often does one thing now and owes another later. An audit pattern commits an act and owes the audit record of it; an approval chain opens and owes its close; a sharing pattern hands out a token and owes the sealed entry that replaces its pending mark. Between the two, the obligation has to live somewhere. If it lives in the process's memory, a crash forgets it. If each composition keeps its own pending list, the corpus holds the same idea in six places, and each list is a record no constituent can rebuild — the Execution Contract's *extraction-pending* debt (the section titled App state in `execution-contract.md`). Compositions already name that debt against this atom.

This atom is the one home for it. An owed record is written in the cause's own transaction (Execution Contract Database 1), so a cause never commits without its obligation and an obligation never stands for a cause that rolled back. It is discharged once, by naming what fulfilled it, so an auditor can match every obligation to its fulfilment. And an obligation that is not met in time does not vanish or retry forever: it is flagged, with the instant and the actor, for a person to settle.

The atom keeps the record and nothing else. It holds no body and reaches no outside system — a message to deliver belongs to a notification pattern — and the protocol that makes and recovers the owed write is the composing pattern's.

</details>

## What it keeps

### The owed records

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

#### Owed Record

The record this atom defines: one owed obligation, owed by one owing pattern, created by one cause, met by at most one discharge. Carries [Owing Pattern], [Owed Id], [Cause Id], [Recording Instant], [Due-By Instant], [Status], and the settlement fields of whichever write settled it.

Kind: Type

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

Term recording instant: the instant the owed record was recorded, stamped from the injected [Now] (Operation 3) — a [Recording Instant].

Term due-by instant: the instant the obligation falls due — a [Due-By Instant]; stamped at recording, never changed.

Term discharge instant: the instant the obligation was met — a [Discharge Instant].

Term flag instant: the instant the owed record was flagged for a person — a [Flag Instant].

## What people do

### Every action

```
Operation 37: The atom MUST NOT offer a removal action.
Operation 38: The atom MUST NOT offer a reopen action.
```

No writing action of this atom is undone, and none needs an undo: a [Record Owed] leaves an owed record that no action removes (State 9, Operation 37), a [Flag] leaves the flag instant and actor reference final and no action reopens the owed record (State 8, Operation 38, Invariant 1.2), and a [Discharge] stands the owed record in discharged for good (State 7), so no undo is owed (Execution Contract Undo 4).

NOTE: watch the blank id (Operation 12, Operation 21, Operation 46).

NOTE: watch the blank optional input (Term matching owed record).

NOTE: watch the untyped input (Operation 41, Term due-by window).

NOTE: watch the listing page (Operation 31, Operation 39, Term matching owed record).

Term due-by window: the whole number of seconds a [Record Owed] call allows for the obligation to be met, above zero and within the window cap — a [Due-By Window], malformed where it is not a whole number; consumed to compute the due-by deadline, never stored under this name.

Term due-by deadline: `(recording_instant + due_by_window)` — what [Record Owed] stores as due-by instant, computed once.

Term listed status: the status a [List Owed] call asks for, open, flagged or discharged — a [Listed Status].

Term listing key: an owed record's due-by instant paired with its owed id, compared first by instant, then by id in code point order (Execution Contract Logic confinement 10).

Term continuation key: the listing key of the last owed record a previous [List Owed] call answered — a [Continuation Key], malformed where it is not an instant paired with an owed id; its instant is compared only with listing keys, never with now.

Term matching owed record: an owed record of the owing pattern whose status EQUALS the listed status and, where continuation key DOES NOT EQUAL blank, whose listing key EXCEEDS the continuation key. Where no owed record matches, [List Owed] answers an empty page. An owing pattern that EXCEEDS the pattern name cap names no owed record, since [Record Owed] refuses one (Operation 9), so [List Owed] answers it an empty page and not invalid-request; this answer stands in place of the refusal Execution Contract Input 2 and Execution Contract Query 5 give a value over the cap.

#### Duplicate

The refusal [Record Owed] answers where an owed record already names the owing pattern and owed id.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: duplicate

#### Not Known

The refusal [Discharge], [Flag] or [Read Owed] answers where a pair within its caps names no owed record.

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

The refusal an action answers for a blank, malformed or over-long input, a [Due-By Window] of zero or less or past the window cap, or a [Listed Status] other than open, flagged or discharged. [List Owed] does not refuse an over-long owing pattern: it answers an empty page (Term matching owed record). Nothing is written.

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

### Record Owed

#### Record Owed

The behavior an owing pattern invokes, in the transaction that commits a cause, to record that a write is owed. It takes the [Owing Pattern], [Owed Id], [Cause Id] and [Due-By Window], stamps [Recording Instant] and [Due-By Instant], enters the [Owed Record] in [Open] and answers [Recorded].

Kind: Operation

```
record_owed(owing_pattern, owed_id, cause_id, due_by_window)
  answers recorded
  refuses duplicate | invalid-request | storage-failure
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
Operation 41: IF a due-by window is malformed THEN [Record Owed] MUST answer invalid-request (Execution Contract Input 1).
Operation 48: IF due-by window EXCEEDS the window cap THEN [Record Owed] MUST answer invalid-request.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Record Owed] | every id present and within its cap, a window above zero, no owed record for the pair, database accepts | recorded | one owed record lands in [Open], recording instant and due-by instant stamped (Operation 1 through 5) |
| [Record Owed] | an owed record already names the pair | [Duplicate] | none (Operation 6) |
| [Record Owed] | a blank or over-long id, a blank or malformed window, a window of zero or less, or a window past the window cap | [Invalid Request] | none (Operation 7 through 10, Operation 41, Operation 48) |
| [Record Owed], [Discharge], [Flag] | database refuses the write | [Storage Failure] | none, and the caller's transaction rolls back with it (Operation 11, Operation 20, Operation 30) |

`record_owed(..., due_by_window: 0)` → invalid-request (Operation 8).

`record_owed(...)` whose write the database refuses → storage-failure, and the act it rode with rolls back: there is no act without its obligation (Operation 11, Composition note 1).

#### Recorded

The answer [Record Owed] gives where the owed record landed in [Open]: the call's acknowledgement, never stored.

Kind:       Type
Projection: recorded

#### Due-By Window

How long a [Record Owed] call allows for the obligation to be met, in seconds; consumed to compute [Due-By Instant], never stored under this name.

Kind:         Parameter
Parameter of: Record Owed
Projection:   due_by_window

### Discharge

#### Discharge

The behavior that records an obligation met, naming the [Fulfilment Id]. It accepts an [Open] or [Flagged] owed record, moves it to [Discharged] and stamps [Discharge Instant]. It succeeds once per owed record.

Kind: Operation

```
discharge(owing_pattern, owed_id, fulfilment_id)
  answers discharged
  refuses not-known | already-discharged | invalid-request | storage-failure
```

```
Operation 12: IF owing pattern DOES NOT EQUAL blank AND owed id DOES NOT EQUAL blank AND owing pattern DOES NOT EXCEED the pattern name cap AND owed id DOES NOT EXCEED the id cap AND no owed record EXISTS for the owing pattern and the owed id THEN [Discharge] MUST answer not-known.
Operation 13: IF the owed record's status EQUALS discharged THEN [Discharge] MUST answer already-discharged.
Operation 14: IF fulfilment id EQUALS blank OR fulfilment id EXCEEDS the id cap THEN [Discharge] MUST answer invalid-request.
Operation 15: [Discharge] MUST accept an owed record whose status IS IN open, flagged.
Operation 16: [Discharge] MUST stand the owed record in discharged.
Operation 17: [Discharge] MUST stamp discharge instant from the injected now.
Operation 18: [Discharge] MUST record the fulfilment id on the owed record.
Operation 19: [Discharge] MUST answer discharged.
Operation 20: IF the database refuses the write THEN [Discharge] MUST answer storage-failure.
Operation 42: IF owing pattern EQUALS blank OR owed id EQUALS blank OR owing pattern EXCEEDS the pattern name cap OR owed id EXCEEDS the id cap THEN [Discharge] MUST answer invalid-request.
Operation 49: [Discharge] MUST NOT write a flag instant.
Operation 50: [Discharge] MUST NOT write an actor reference.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Discharge] | the record is [Open] or [Flagged], a fulfilment id present | discharged | the record moves to [Discharged], fulfilment id and discharge instant written; the owing pattern, owed id, cause id, recording instant and due-by instant stand, and a flag instant and an actor reference stand as [Flag] left them or stay absent (Operation 15 through 19, Operation 49, Operation 50, Invariant 1.1) |
| [Discharge] | a pair that is not blank, within its caps, and names nothing | [Not Known] | none (Operation 12) |
| [Discharge], [Flag] | a blank or over-cap owing pattern or owed id | [Invalid Request] | none (Operation 42, Operation 43) |
| [Discharge] | a blank or over-long fulfilment id | [Invalid Request] | none (Operation 14) |
| [Discharge] | the record is [Discharged] | [Already Discharged] | none; the written settlement fields stand (Operation 13, Invariant 1.2) |

A second `discharge(..., owed_id: "aud_51c0", fulfilment_id: "evt_9a13")` → already-discharged; the first fulfilment stands (Operation 13).

### Flag

#### Flag

The behavior a sweep invokes on an [Open] owed record whose [Due-By Instant] has come, moving it to [Flagged] and recording [Flag Instant] and [Actor Reference]. A flagged record may still be discharged.

Kind: Operation

```
flag(owing_pattern, owed_id, actor_ref)
  answers flagged
  refuses not-known | already-discharged | already-flagged | not-due | invalid-request | storage-failure
```

```
Operation 21: IF owing pattern DOES NOT EQUAL blank AND owed id DOES NOT EQUAL blank AND owing pattern DOES NOT EXCEED the pattern name cap AND owed id DOES NOT EXCEED the id cap AND no owed record EXISTS for the owing pattern and the owed id THEN [Flag] MUST answer not-known.
Operation 22: IF the owed record's status EQUALS discharged THEN [Flag] MUST answer already-discharged.
Operation 23: IF the owed record's status EQUALS flagged THEN [Flag] MUST answer already-flagged.
Operation 24: IF now PRECEDES the owed record's due-by instant THEN [Flag] MUST answer not-due.
Operation 25: IF actor reference EQUALS blank OR actor reference EXCEEDS the id cap THEN [Flag] MUST answer invalid-request.
Operation 26: [Flag] MUST stand the owed record in flagged.
Operation 27: [Flag] MUST stamp flag instant from the injected now.
Operation 28: [Flag] MUST record the actor reference on the owed record.
Operation 29: [Flag] MUST answer flagged.
Operation 30: IF the database refuses the write THEN [Flag] MUST answer storage-failure.
Operation 43: IF owing pattern EQUALS blank OR owed id EQUALS blank OR owing pattern EXCEEDS the pattern name cap OR owed id EXCEEDS the id cap THEN [Flag] MUST answer invalid-request.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Flag] | the record is [Open], its due-by instant reached, an actor present | flagged | the record moves to [Flagged], flag instant and actor written; the owing pattern, owed id, cause id, recording instant and due-by instant stand (Operation 26 through 29, Invariant 1.1) |
| [Flag] | a pair that is not blank, within its caps, and names nothing | [Not Known] | none (Operation 21) |
| [Flag] | the record is [Open] and its due-by instant still ahead | [Not Due] | none (Operation 24) |
| [Flag] | a blank or over-long actor reference | [Invalid Request] | none (Operation 25) |
| [Flag] | the record is [Flagged] or [Discharged] | [Already Flagged] or [Already Discharged] | none (Operation 22, Operation 23) |

`flag(owing_pattern: "audit-trail", owed_id: "aud_8d14", actor_ref: "svc_sweep_s01")` at 13:01, the record `aud_8d14` recorded at 13:00 with a window of 300 → not-due: the obligation is not yet due (Operation 24).

### List Owed

#### List Owed

The behavior a sweep or an auditor invokes to list the owed records of one [Owing Pattern] in one [Listed Status], [Discharged] among them, ordered by due-by instant then owed id, a page at a time, continuing past a [Continuation Key]. It only reads.

Kind: Operation

```
list_owed(owing_pattern, listed_status, optional continuation_key)
  answers the matching owed records
  refuses invalid-request
```

```
Operation 31: [List Owed] MUST answer the matching owed records with the earliest listing keys, up to the page size, which stands in place of Execution Contract Read 6's whole match.
Operation 32: [List Owed] MUST order the answer by due-by instant, then by owed id.
Operation 34: IF owing pattern EQUALS blank THEN [List Owed] MUST answer invalid-request.
Operation 35: IF listed status IS NOT IN open, flagged, discharged THEN [List Owed] MUST answer invalid-request.
Operation 36: [List Owed] MUST NOT write.
Operation 39: [List Owed] MUST NOT answer an owed record that is not a matching owed record.
Operation 40: IF continuation key DOES NOT EQUAL blank AND the continuation key is malformed (Term continuation key) THEN [List Owed] MUST answer invalid-request.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [List Owed] | a pattern, within the pattern name cap or over it, open, flagged or discharged, an optional continuation key | the matching owed records with the earliest listing keys, up to the page size, in listing-key order; none where none match, an over-cap pattern among them (Term matching owed record) | none (Operation 31, Operation 32, Operation 39) |
| [List Owed] | a blank pattern, a status other than open, flagged or discharged, or a malformed continuation key | [Invalid Request] | none (Operation 34, Operation 35, Operation 40) |

#### Listed Status

The status a [List Owed] call asks for: [Open], [Flagged] or [Discharged].

Kind:         Parameter
Parameter of: List Owed
Projection:   listed_status

#### Continuation Key

The due-by instant and owed id of the last owed record a previous [List Owed] call answered.

Kind:         Parameter
Parameter of: List Owed
Projection:   continuation_key

### Read Owed

#### Read Owed

The behavior an auditor or a composing pattern invokes to read one owed record by its [Owing Pattern] and [Owed Id], whatever its [Status]. It only reads.

Kind: Operation

```
read_owed(owing_pattern, owed_id)
  answers the owed record
  refuses not-known | invalid-request
```

```
Operation 44: IF owing pattern DOES NOT EQUAL blank AND owed id DOES NOT EQUAL blank AND an owed record EXISTS for the owing pattern and the owed id THEN [Read Owed] MUST answer the owed record.
Operation 45: IF owing pattern EQUALS blank OR owed id EQUALS blank OR owing pattern EXCEEDS the pattern name cap OR owed id EXCEEDS the id cap THEN [Read Owed] MUST answer invalid-request.
Operation 46: IF owing pattern DOES NOT EQUAL blank AND owed id DOES NOT EQUAL blank AND owing pattern DOES NOT EXCEED the pattern name cap AND owed id DOES NOT EXCEED the id cap AND no owed record EXISTS for the owing pattern and the owed id THEN [Read Owed] MUST answer not-known.
Operation 47: [Read Owed] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Read Owed] | a pattern and an id naming an owed record, whatever its status | the owed record | none (Operation 44, Operation 47) |
| [Read Owed] | a pair that is not blank, within its caps, and names nothing | [Not Known] | none (Operation 46) |
| [Read Owed] | a blank or over-cap owing pattern or owed id | [Invalid Request] | none (Operation 45) |

## What is and what should never be (Invariants)

- **Invariant 1 — What was owed never changes.**
  ```
  Invariant 1.1: A recorded owed record's owing pattern, owed id, cause id, recording instant and due-by instant MUST NOT change.
  Invariant 1.2: A written settlement field MUST NOT change.
  ```
- **Invariant 2 — One owed record per obligation.**
  ```
  Invariant 2.1: Two owed records MUST NOT share an owing pattern and an owed id.
  Invariant 2.2: A write MUST NOT record a second owed record for one owing pattern and one owed id (Operation 6, Execution Contract Database 2).
  ```
- **Invariant 3 — Discharged once.**
  ```
  Invariant 3.1: The successful [Discharge] calls on one owed record MUST NOT EXCEED one.
  Invariant 3.2: A discharged owed record MUST NOT leave discharged.
  ```
- **Invariant 4 — Flagged only when due.**
  ```
  Invariant 4.1: A flagged owed record's flag instant MUST NOT PRECEDE the owed record's due-by instant.
  ```
- **Invariant 5 — Nothing is lost.**
  ```
  Invariant 5.1: The atom MUST NOT offer a removal surface.
  ```

Term settlement field: fulfilment id | discharge instant | flag instant | actor reference — what [Discharge] and [Flag] write and nothing else does.

Invariants 1 and 2 give *a fixed obligation*: what was owed, by whom and for what cause reads the same forever, once. Invariant 3 gives *exactly-once fulfilment*. Invariant 4 gives *honest escalation*: no obligation is flagged before it is due. Invariant 5 gives *completeness*: the atom removes no obligation, so each one it recorded stays there to be matched against its fulfilment or its flag, until a composing retention pattern purges it (Non-goal 8).

---

## When something happens

### Concurrency

```
Concurrency 1: IF two [Discharge] calls name one owed record THEN EXACTLY ONE call MUST answer discharged.
Concurrency 2: IF a [Flag] call and a [Discharge] call name one owed record THEN the [Discharge] call MUST answer discharged.
```

## While something is so

### Clock dependence

```
Clock dependence 1: A guard MAY read now ONLY IF the guard compares now with a due-by instant.
Clock dependence 2: The atom MUST NOT accept a caller-supplied instant other than the instant of a continuation key.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
```

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the owed records PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 4, Execution Contract Refusal 1 and Execution Contract Input 1.
Capability requirement 3: The deployment MAY override the id cap.
Capability requirement 4: The deployment MAY override the pattern name cap.
Capability requirement 5: The deployment MAY override the page size.
Capability requirement 6: The deployment MAY override a bound ONLY IF the override EXCEEDS zero.
Capability requirement 7: The deployment MAY override the window cap.
```

Term id cap: 256 Unicode code points (Execution Contract Input 2) — the longest owed id, cause id, fulfilment id or actor reference the atom accepts, unless the deployment overrides it.

Term pattern name cap: 128 Unicode code points (Execution Contract Input 2) — the longest owing pattern a call may name, [List Owed] excepted (Term matching owed record), unless the deployment overrides it.

Term page size: 1,000 owed records — the most [List Owed] answers in one call, unless the deployment overrides it.

Term window cap: 31,536,000 seconds — the longest due-by window the atom accepts, unless the deployment overrides it.

Term zero: the count of nothing — the floor an overriding bound and a due-by window must exceed.

#### Now

The current clock reading every writing action consumes, injected at the seam, never a signature parameter.

Kind:         Parameter
Parameter of: Record Owed, Discharge and Flag
Projection:   now

Term seam: the atom's I/O (input and output) boundary; the host injects the clock reading here.

Term now: the deployment's clock reading at the call — a [Now], as Execution Contract Logic confinement 11 declares it; the atom spends no clock allowance, since it compares a call's reading only with a due-by instant an earlier call stamped from the deployment's one clock, whose agreement across nodes the deployment owns (Execution Contract Logic confinement 7 and Execution Contract Logic confinement 18).

## Left to others

```
Non-goal 1: The atom MUST NOT make the owed write.
Non-goal 2: The atom MUST NOT confirm a fulfilment id names a record.
Non-goal 3: The atom MUST NOT run a sweep.
Deleted: Non-goal 4. Non-goal 3 owns it: the atom runs no sweep, and which pattern recovers an owed write is the app's choice.
Non-goal 5: The atom MUST NOT decide what becomes of a flagged owed record.
Non-goal 6: The atom MUST NOT carry a message body.
Deleted: Non-goal 7. Non-goal 6 owns it: the atom delivers no message, and which pattern does is the app's choice.
Non-goal 8: The atom MUST NOT retain an owed record for a period.
Deleted: Non-goal 9. Non-goal 8 owns it: the atom bounds no lifetime, and which pattern does is the app's choice.
Non-goal 10: The atom MUST NOT attest an actor reference.
Deleted: Non-goal 11. Non-goal 10 owns it: the atom attests no actor, and which pattern does is the app's choice.
```

NOTE: the owners — a composing pattern, the owing pattern (Non-goal 1, Non-goal 2); a recoverable-invocation pattern (Non-goal 3, Non-goal 4); the deployment (Non-goal 5); a notification pattern (Non-goal 6, Non-goal 7); a retention pattern (Non-goal 8, Non-goal 9); an attestation pattern (Non-goal 10, Non-goal 11).

```
Composition note 1: A composing pattern MUST call [Record Owed] in the transaction that commits the cause (Execution Contract Database 1).
Composition note 2: A composing pattern MUST call [Discharge] in the transaction that writes the fulfilment (Execution Contract Database 1).
Composition note 3: A composing pattern MUST own the meaning of an owed id.
Composition note 4: A composing pattern MUST own the due-by window.
```

NOTE: composing patterns — the compositions whose Composition state names an extraction-pending fact against this atom, under its former name Outbox, and a recoverable-invocation pattern whose intent records are the same shape.

## Example

### An audit record owed

An audit pattern commits an act `act_51c0` and, in the same transaction, calls `record_owed(owing_pattern: "audit-trail", owed_id: "aud_51c0", cause_id: "act_51c0", due_by_window: 300)`, with the host injecting `now: 2026-11-02T13:00:00Z` → recorded. The owed record stands in [Open], due at 13:05:00.

At 13:00:02 the audit record `evt_9a12` lands, and the audit pattern calls `discharge(owing_pattern: "audit-trail", owed_id: "aud_51c0", fulfilment_id: "evt_9a12")` → discharged. An auditor can now match the act to its audit record through the owed record.

### An obligation that ages out

A process records `aud_6d33` at 12:50:00 with a due-by window of 300, so it falls due at 12:55:00, and crashes before writing its audit record. At 13:20 the composing sweep lists `list_owed(owing_pattern: "audit-trail", listed_status: open)`, finds `aud_6d33` past due, and calls `flag(owing_pattern: "audit-trail", owed_id: "aud_6d33", actor_ref: "svc_sweep_s01")` → flagged. The next morning an operator reconstructs the audit record `evt_9b40` and discharges the owed record with it; the flag instant and the sweep that set it stay on the record.

### Regulated adversarial scenarios

- **Regulator audit — was every act recorded?** The auditor reads every owed record of the audit pattern from the database, lists the open, flagged and discharged ones through [List Owed], reads any one by its pair through [Read Owed], and matches each discharged one to its fulfilment id (Check 3.1). Every flagged one is an act whose record was late, with the instant it was found and who found it; none can be missing, because the obligation was written with the act and a refused [Record Owed] refuses the act with it, and none is ever removed (Composition note 1, Invariant 5.1, Execution Contract Database 1, Execution Contract Read 4 and the section titled Mapping an atom's answers in `execution-contract.md`).
- **A sweep that runs early.** A misconfigured sweep tries to flag obligations the moment they are recorded. Each call answers not-due, and no record is escalated before its time (Invariant 4.1).
- **Two writers settle one obligation.** A recovering process and an operator discharge the same owed record at once. One lands; the other answers already-discharged, so the record names one fulfilment (Invariant 3.1).

---

## Source

- **Chris Richardson, *Microservices Patterns* — the Transactional Outbox** — the idea of writing an obligation in the same transaction as its cause. This atom keeps that one idea and none of the message delivery the textbook pattern carries; delivery is a notification pattern's.

Inherited from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture: one purpose, the record of an obligation, separate from the write that meets it and the sweep that chases it.

---

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the owed records, with their committed versions (Execution Contract Generation acceptance 1).

#### Conformance checks

```
Check 1.1: An auditor MUST find owing pattern, owed id, cause id, recording instant, due-by instant and status on EVERY owed record (State 2).
Check 1.2: An auditor MUST find one owing pattern, owed id, cause id, recording instant and due-by instant per owed record across the owed record's whole life (Invariant 1.1; Execution Contract Generation acceptance 1).
Check 1.3: An auditor MUST find, for EVERY settlement field an owed record holds in a committed version, the same value in EVERY later committed version (Invariant 1.2).
Check 2.1: An auditor MUST find no two owed records sharing an owing pattern and an owed id (Invariant 2.1).
Check 3.1: An auditor MUST find a fulfilment id and a discharge instant on EVERY discharged owed record (State 3).
Check 3.2: An auditor MUST find a flag instant and an actor reference on EVERY flagged owed record (State 4).
Check 3.3: An auditor MUST find, for EVERY owed record, no count of committed versions entering discharged that EXCEEDS one (Invariant 3.1).
Check 3.4: An auditor MUST find no owed record whose status IS IN open, flagged in a committed version later than a committed version in which the owed record's status EQUALS discharged (Invariant 3.2, State 7).
Check 4.1: An auditor MUST find no flag instant that PRECEDES the owed record's due-by instant (Invariant 4.1).
Check 5.1: An auditor MUST find EVERY owed record of one committed version in EVERY later committed version (Invariant 5.1, State 9).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: An auditor MUST read whether a fulfilment id names a real record from the owing pattern's records (Non-goal 2).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the deployment; a composing pattern; a caller; a guard; an auditor; the database; an owed record; a write; an action; a call; a string input; an opaque reference; an override; a bound; a sweep.

Term records: owed record — the record that one write is owed, carrying owing pattern, owed id, cause id, recording instant, due-by instant and status and, once settled, fulfilment id and discharge instant, or flag instant and actor reference, or all four where a flagged owed record is discharged.

Term record verbs: identify, interpret, stand, carry, offer, remove, supply, override, exceed, record, stamp, answer, accept, read, write, order, change, share, refuse, leave, fall, find, make, confirm, run, decide, retain, attest, compose, compare, trim, normalize, case-fold, call, own.

Term value sets: status = open | flagged | discharged. listed status = open | flagged | discharged. settlement field = fulfilment id | discharge instant | flag instant | actor reference.

Term bounds: id cap (the longest id the atom accepts); pattern name cap (the longest owing pattern the atom accepts); page size (the most owed records [List Owed] answers in one call); window cap (the longest due-by window the atom accepts); zero (the floor an overriding bound and a due-by window must exceed).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.69 (2026-11-01) through the Grace connector.

Term terms: owed record, owing pattern, owed id, cause id, fulfilment id, actor reference, seam, status, id cap, pattern name cap, page size, window cap, zero, now, due-by window, due-by deadline, recording instant, due-by instant, discharge instant, flag instant, listed status, listing key, continuation key, matching owed record, settlement field, committed version.

<!-- Term registry — shortcut-reference definitions. -->

[Record Owed]: #record-owed
[Discharge]: #discharge
[Flag]: #flag
[List Owed]: #list-owed
[Read Owed]: #read-owed
[Owed Record]: #owed-record
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
[Recorded]: #recorded
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

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — owed-record.als + 18 twins (the static data model: State 1 through 6, Identity 1, Invariant 2.1 and 4.1, Operation 4, 7, 8, 9, 10, 14, 25, 27 and 48 checked on every version an ordered sequence of admitted calls leaves); owed-record.tla + 14 twins (across steps, while the clock moves: Invariant 1.1, 1.2, 2.2, 3.1, 3.2 and 5.1, State 8, Concurrency 2, Operation 24, 35, 36, 44 through 47, with State 7, State 9 and Concurrency 1 checked through them); the vote no of 2026-11-02 superseded by the maintainer's ruling of 2026-11-09 (both models; only the writing vetoes one), and neither vetoed; 2026-11-11, re-derived 2026-11-20 after the cures of open lines 2026-11-02-a and 2026-11-02-b ([Read Owed], [List Owed] of discharged, the window cap: Operation 48 in Alloy, Operation 35 and 44 through 47 in TLA+, 5 twins added); owed rows: Operation 31, 32 and 39, Clock dependence 1, 2026-11-20; model redraw deferred to Lean: owed-record.tla, Operation 45, 2026-11-26; model redraw deferred to Lean: owed-record.tla, Operation 46, 2026-11-26
last gate: 2026-11-26 — Final Critique 5, a full round, three readers (GRID glm-5.3-flash, EOS minimax-m3, Linus mimo-v2.6-pro; the first GRID pass lapsed on a report with no Files read line and ran again), frozen at e5104028 — foundational count 2, cured, not clean, no sample; EOS's first-pass findings, placed foundational by Opus 5.5 (Kind A): an owing pattern or owed id over its cap on [Discharge], [Flag] or [Read Owed] met Operation 12, 21 and 46 (not-known) and Execution Contract Input 2 (invalid-request) with no rule between them, and Clock dependence 2 forbade the instant a continuation key carries; Linus's four foundational claims were refuted or refining (Concurrency 1 and 2 against the refusals, refuted by Execution Contract Read 4 as in Final Critique 3; Term listed status's malformation clause, not on that line; State 5 and 6 and the settlement fields, refuted by Invariant 1.2 with a narrower gap cured; the over-cap pattern on [List Owed], one reading only, refining) and the Claude reader's composing-pattern claims refuted by the Execution Contract's mapping of an atom's answers; cured: Operation 12, 21 and 46 and Operation 42, 43 and 45 answer an over-cap pattern or id invalid-request, with the case rows and the Flag table, Clock dependence 2 excepts a continuation key's instant, Term matching owed record states the empty page for an over-cap pattern on [List Owed], Operation 49 and 50 keep [Discharge] from writing a flag instant or an actor reference, Check 1.3, 3.3, 3.4 and 5.1 test Invariant 1.2, 3.1, 3.2 and 5.1, Invariant 4.1 reads PRECEDES, the undo sentence (Execution Contract Undo 4), the Recorded entry, and the wording items; the rest declined as the corpus's own forms (Role Outcome on a refusal member, the action rejection value set, a computed term beside its field); 2026-11-20 — Final Critique 4, a delta round, one reader (Linus beam-free), frozen at ff2e5d8 — foundational count 0 after the blind second triage, clean, one sample (Linus's report claimed two foundational: that [Record Owed] never rejects a blank owing pattern, owed id or cause id, refuted by both triages, Operation 7 answering invalid-request for each and String 5 reading a whitespace-only value as blank, the reach holding Operation 9 and 10 and not 7; and that Term matching owed record's closing sentence reads two ways for an over-cap owing pattern, refuted by both, the sentence stating the answer is empty and Operation 34 refusing only a blank pattern; its five refining lines were refuted or rhetorical, and the one wording cure, the Term's closing clause naming whose answer stands in place of Execution Contract Query 5's, is made); 2026-11-20 — Final Critique 3, frozen at 125fa86b — foundational count 2 after the first triage (no blind second triage, the count is not zero), cured in the round, not clean, one sample (the recording instant's Term against Operation 3, found by GRID and EOS; the clock allowance the atom spends none of, found by Linus; Concurrency 1 and 2 against the guards and the retry after a lost answer refuted by Execution Contract Read 4 and Error model 1; GRID's pass lapsed on a forbidden read); 2026-11-03 — Final Critique 2, delta, frozen at aeea14e — foundational count 0, clean, one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./owed-record.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/owed-record.md`.

</details>

NOTE: End of Owed Record.
