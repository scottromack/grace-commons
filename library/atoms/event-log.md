---
title: Event Log
id: 40
audience: common
---

# Event Log

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Event Log is an append-only record: what is written to it stays in the order it arrived, and by design the log itself never changes or removes it. It is the foundation that audit trails, undo histories, activity feeds, transaction journals, and replay systems (which rebuild a past state by reading the events back in order) are all built on. It offers just two operations: one adds an event to the end and returns an identifier for it, and the other reads events back in order. Every event gets a strictly increasing sequence number (1 for the first event, 2 for the next, and so on) that fixes its place in line. That number is kept separate from the human-readable timestamp on purpose: clocks can drift or jump, but the sequence number never does, so the log can always be replayed faithfully even on a machine with a bad clock. The log itself takes no position on how long to keep events, how to prove they have not been tampered with, who wrote them, or how to search them; each is left to a separate pattern layered on top, which is why the same simple log can sit under a personal task history, a medical chart, a bank ledger, and a regulated audit trail.

<details markdown="block">
<summary>WHY</summary>

A composing pattern records facts about state changes, and the same need recurs under a dozen names: audit trails, undo histories, activity feeds, event sourcing, write-ahead logs, replication journals, version-control logs, replay buffers. The shape is constant — a stream of facts, recorded in order, never altered afterward, available for retrospective query. The atom declines every opinion about what an event means, how long to keep one, who wrote one, whether one has been tampered with and how to search by payload, because it is useful under a task list, a patient chart, a bank journal and a regulated audit trail only if it does. What it does carry is the structural guarantee the others rest on: the sequence is faithful to what was recorded.

</details>

## What it keeps

### The record

#### Event Log

The named append-only sequence this atom defines. Multiple instances coexist; this card describes one.

Kind: Type

Term event: one recorded fact in the log — an [Event]; fixed in place once landed.

#### Event

One entry in the sequence of an [Event Log]; it carries its [Event Id], [Sequence Number], [Recording Instant] and [Data].

Kind: Type

Term event id: the opaque value naming one event — an [Event Id]; allocated once, never again.

#### Event Id

Allocated by the host at the I/O seam on [Append]. It supports equality but carries no ordering — ordering is [Sequence Number]'s job.

Kind:       Field
Field of:   Event
Projection: event_id

Term seam: the atom's I/O (input and output) boundary as Execution Contract Logic confinement 14 declares it; the host injects the clock reading and the event id here.
Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term transition: the atom's evaluation of one call against the log, as Execution Contract Logic confinement 14 declares it.

Term business caller: the business caller per Execution Contract Logic confinement 14.

```
Identity 1: The atom MUST identify an event by the event id.
Identity 2: The host MUST allocate an event id at the atom's seam.
Identity 5: The atom MUST NOT reuse an event id.
Identity 6: The atom MUST NOT reassign an event id.
Identity 7: The atom MUST compare event ids by equality.
Identity 8: The atom MUST NOT order events by event id.
Identity 9: The atom MUST NOT identify an event by the event's data.
```

Term sequence number: the strictly rising integer an event carries — a [Sequence Number]; the log's order and nothing else.

#### Sequence Number

Assigned to each [Event] at [Append]; kept separate from [Recording Instant] on purpose, because a clock can drift but the sequence never does.

Kind:       Field
Field of:   Event
Projection: sequence_number

Term recording instant: the wall-time instant an event was appended, stamped from the injected clock — a [Recording Instant]; an annotation, never the order.

#### Recording Instant

It can fall along append order — under a clock that misbehaves, or where two appends land in the order opposite to their clock readings — and [Sequence Number] is authoritative.

Kind:       Field
Field of:   Event
Projection: recorded_at

Term data: the opaque sequence of bytes, empty or not, a composing pattern supplies — [Data]; the atom stores the bytes and reads nothing in them. A composing pattern holding a structured value encodes it to bytes before it appends, since it owns the payload's schema (Composition note 3).

#### Data

Supplied on [Append] and carried by the [Event]; stored and returned verbatim.

Kind:       Field
Field of:   Event
Projection: data

Term event field: event id | sequence number | recording instant | data.

Term landed: an event a successful [Append] wrote.

Term log name: the name telling one log instance from another — a [Log Name].

#### Log Name

One per audited subsystem, one per user history, and so on.

Kind:       Field
Field of:   Event Log
Projection: name

```
Identity 10: A composing pattern MUST own how many log instances a deployment runs.
```

Term next sequence number: the sequence number the next landed event carries — a [Next Sequence Number]; part of the instance's persistent state.

#### Next Sequence Number

Begins at 1 for a fresh instance and rises by one on each [Append] that lands an [Event].

Kind:       Field
Field of:   Event Log
Projection: next_sequence_number

```
State 1: The log MUST hold events in EXACTLY ONE total order.
State 2: EVERY event MUST carry event id, sequence number, recording instant and data.
State 3: The log MUST carry log name.
State 4: The log MUST carry next sequence number.
State 5: A fresh log instance MUST begin next sequence number at one.
State 6: [Append] MUST raise next sequence number by one.
State 8: The atom MUST NOT offer a delete surface.
State 9: The atom MUST NOT offer an edit surface.
```

## What people do

### Every action

A read of the database that fails answers state-unavailable on either action instead (Execution Contract Read 1).

### Append

The behavior a composing pattern invokes to record a new [Event] at the end of the log. It carries the [Next Sequence Number] into the [Event] and raises it by one, stamps [Recording Instant], and returns the [Event Id] and the [Sequence Number] the event carries. It is the only way data enters the log.

Kind: Operation

```
append(data)
  answers appended(event_id, sequence_number)
  refuses invalid-payload | storage-failure
```

```
Operation 1: [Append] MUST write the event into the log.
Operation 2: [Append] MUST stamp recording instant from the injected clock.
Operation 3: [Append] MUST carry next sequence number into the event.
Operation 4: [Append] MUST answer event id.
Operation 5: IF data EXCEEDS the payload cap THEN [Append] MUST answer invalid-payload.
Operation 6: [Append] MUST accept empty data.
Operation 9: IF the database refuses the write THEN [Append] MUST answer storage-failure.
Operation 10: [Append] MUST NOT answer event id with storage-failure.
Operation 11: A caller MUST read storage-failure as the event not landing.
Operation 21: The business caller MUST NOT supply recording instant.
Operation 22: IF data is omitted OR data is not a sequence of bytes THEN [Append] MUST answer invalid-payload.
Operation 23: [Append] MUST answer the sequence number the event carries.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the log |
|---|---|---|---|
| [Append] | data within the cap, database accepts | event id and the sequence number the event carries | one event lands carrying next sequence number, and next sequence number rises; no field of the landed event changes afterward (Operation 1, Operation 3, Operation 23, State 6, Invariant 2.1) |
| [Append] | data over the cap | [Invalid Payload] | none — the precondition failed before the write (Operation 5, Execution Contract Read 4) |
| [Append] | data omitted, or not a sequence of bytes | [Invalid Payload] | none — the precondition failed before the write (Operation 22, Execution Contract Read 4) |
| [Append] | database refuses the write | [Storage Failure] | nothing lands; next sequence number is unchanged (Operation 9, Execution Contract Database 1) |

- `append(65_537_bytes_of_data)` → rejected invalid-payload (payload exceeds the default 65,536-byte cap; configurable per instance).
- `append(42)`, or an append that carries no data → rejected invalid-payload (Operation 22): the call carries no sequence of bytes, and an empty sequence of bytes is the call that is accepted (Operation 6).
- `append(the bytes encoding {type: "deposit", amount: 500})` → accepted; answers `event_id e1` and `sequence_number 1`.
- The database refuses the write. `append(the bytes encoding {type: "withdrawal", amount: 100})` → rejected storage-failure; event does not land; caller must treat the rejection as definitive. Nothing is written, so next sequence number stays at 2 (Operation 9, Execution Contract Database 1).
- Retried, the write commits. `append(the bytes encoding {type: "withdrawal", amount: 100})` → accepted; answers `event_id e2` and `sequence_number 2`.

#### Invalid Payload

The refusal [Append] returns when the [Data] the call supplies exceeds the payload cap, or the call omits data or supplies something that is not a sequence of bytes (Operation 5, Operation 22). The [Event] does not land.

Kind:       Member
Member of:  the Append rejection
Role:       Outcome
Projection: invalid-payload

#### Storage Failure

The refusal [Append] returns when the underlying database write fails after all preconditions pass. The caller must treat it as definitive — the [Event] did not land, and the [Next Sequence Number] is unchanged.

Kind:       Member
Member of:  the Append rejection
Role:       Outcome
Projection: storage-failure

### Read

The behavior a composing pattern invokes to retrieve events matching a [Query], returned in [Sequence Number] order. It only reads; the log is unchanged.

Kind: Operation

Term query: what a read asks for — a [Query]: a sequence number range, a wall-time range, or a combination of the two. A range carrying no upper end holds its lower end and everything above it, which Execution Contract Query 1 would read as malformed. A query is malformed where the query carries no range, where a range's lower end is above its upper end, where any end a sequence number range carries is below one, or where the query asks for anything beyond those ranges.

```
read(query)
  answers events
  refuses invalid-query
```

```
Operation 15: IF the query is malformed THEN [Read] MUST answer invalid-query.
Operation 16: [Read] MUST answer an empty sequence for a well-formed query matching nothing.
Operation 17: [Read] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the log |
|---|---|---|---|
| [Read] | query well-formed, events match | the events, ascending | none — the call reads (Invariant 5.1, Invariant 5.2, Operation 17) |
| [Read] | query well-formed, nothing matches | empty sequence | none (Operation 16) |
| [Read] | query malformed | [Invalid Query] | none (Operation 15) |

- `read({sequence_range: [-1, 5]})` → rejected invalid-query (negative sequence number is not a well-formed range parameter).
- `read({sequence_range: [1, 1]})` → returns `[e1]`; `sequence_number 1` matches, ordered ascending.

#### Query

Passed to [Read]; Term query says when a [Query] is malformed, and Operation 15 answers a malformed one.

Kind:         Parameter
Parameter of: Read
Projection:   query

#### Invalid Query

The refusal [Read] returns when the [Query] is malformed (Term query). No events are returned.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

## What is and what should never be (Invariants)

- **Invariant 3 — Total order.**
  ```
  Invariant 3.1: Two distinct landed events MUST NOT share a sequence number.
  Invariant 3.2: EVERY two distinct landed events MUST stand in EXACTLY ONE order.
  ```
- **Invariant 4 — Sequence-number monotonicity.**
  ```
  Invariant 4.1: A landed event MUST carry a sequence number above EVERY sequence number landed earlier.
  ```
- **Invariant 5 — Read consistency.**
  ```
  Invariant 5.1: A read MUST answer EVERY landed event the read's query matches.
  Invariant 5.2: A read MUST answer the events by sequence number, rising.
  ```
- **Invariant 6 — No id reuse.**
  ```
  Invariant 6.1: Two events one event log carries MUST NOT share an event id.
  ```
- **Invariant 7 — Wall-time best-effort monotonicity.**
  ```
  Invariant 7.2: sequence number IS AUTHORITATIVE FOR the log's order.
  ```
- **Invariant 1 — Append-only.**
  ```
  Invariant 1.1: An event in the log MUST remain in the log for the life of the log instance.
  Invariant 1.2: The atom MUST NOT remove an event.
  ```
- **Invariant 2 — Event immutability.**
  ```
  Invariant 2.1: EVERY event field of a landed event MUST NOT change.
  ```

Append-only and event immutability together give the *immutable journal* property, the one that tells an Event Log from a mutable record set. Total order and monotonicity give *replay*. Read consistency gives *durable visibility*. No id reuse forecloses identity collisions across time.

## When something happens

### Erasure where law requires it

```
Erasure 1: The atom MUST NOT erase an event.
Erasure 2: A deployment under an erasure obligation MUST compose an erasure pattern.
Erasure 3: A deployment under an erasure obligation MUST NOT read this atom as satisfying the obligation.
```

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 3.
Capability requirement 2: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 4, Execution Contract Read 6 and Execution Contract Query 1 through 4.
Capability requirement 3: The deployment MUST supply EVERY event id PER Execution Contract Logic confinement 16.
Capability requirement 4: The deployment MAY declare the payload cap PER Execution Contract Input 2.
Capability requirement 5: The deployment MUST supply the log name of EVERY log instance the deployment runs PER Execution Contract Logic confinement 15.
Capability requirement 6: The deployment MUST begin a fresh log instance at the first start for EVERY log instance a composing pattern owns PER Identity 10 and Execution Contract Logic confinement 17.
```

Term payload cap: the per-instance bound on the number of bytes the composing pattern supplies as data, a whole number no less than 0; 65,536 bytes where a deployment declares none; a cap of 0 admits only empty data (Operation 5, Operation 6).

## Offers

The bonds this atom offers, each of a bond kind [Bonds](../bonds.md) states. Its own checks of whether a call may happen, data over the payload cap (Operation 5), data omitted or no sequence of bytes (Operation 22) and a malformed query (Operation 15), are rules of the offer, answered on its arms, and no need it declares (Bonds Direction 4). A read of one event is the read of the range that holds the event's sequence number, the place an append answers (Operation 23), and no other (Bonds journal 7). The atom keeps no seal of its own, so the app sets its tamper to the evidence of the needs it serves, as it sets its keep.

Term offer journal: calls append, read; arms append: event_id, sequence_number, invalid-payload / read: events, invalid-query; keep duration; tamper opaque; order sequence number.

## Left to others

```
Non-goal 1: The atom MUST NOT prune an event.
Non-goal 2: A pattern needing time-bounded retention MUST compose Retention Window.
Non-goal 3: The atom MUST NOT detect tampering.
Non-goal 4: A pattern needing integrity proof MUST compose Tamper Evidence.
Non-goal 5: The atom MUST NOT record who appended an event.
Non-goal 6: A pattern needing attribution MUST compose Actor Identity.
Non-goal 7: The atom MUST NOT index data.
Non-goal 8: A pattern needing look-up by payload field MUST compose a reverse-index pattern.
Non-goal 9: The atom MUST NOT order events across log instances.
Non-goal 10: A pattern needing an order across more than one host MUST compose a consensus pattern.
Non-goal 11: The atom MUST NOT read data, beyond counting the bytes of data for the payload cap (Operation 5).
Non-goal 12: A pattern needing schema validation MUST compose a schema-evolution pattern.
Non-goal 13: The atom MUST NOT collapse events into a snapshot.
Non-goal 14: The atom MUST NOT push an event to a subscriber.
Non-goal 15: The atom MUST NOT append two events in one transaction.
```

NOTE: the owners — [Retention Window](./retention-window.md) (Non-goal 1, Non-goal 2) and a Storage Tier *(forthcoming)* for cold events; [Tamper Evidence](./tamper-evidence.md) (Non-goal 3, Non-goal 4); [Actor Identity](./actor-identity.md) (Non-goal 5, Non-goal 6); a Reverse Index *(forthcoming)* (Non-goal 7, Non-goal 8); a Consensus pattern *(forthcoming)* (Non-goal 10); a Schema Evolution pattern *(forthcoming)* (Non-goal 12); a Snapshot pattern *(forthcoming)* (Non-goal 13); a Change Feed pattern *(forthcoming)* (Non-goal 14); Erasure Coordination *(forthcoming)* (Erasure 2, Erasure 3).

Where the pattern breaks down: when the host cannot supply atomic, serialized appends — most adversarially-distributed settings; when an event must be edited or deleted in place; when order must come from something other than append order.

```
Composition note 1: A composing pattern MUST append on every state change.
Composition note 1a: A composing pattern MAY derive state by replay.
Composition note 2: A composing pattern MUST own what an event means.
Composition note 3: A composing pattern MUST own the payload's schema.
Composition note 4: This atom's invariant numbers MUST stand as a frozen contract surface.
Composition note 5: A composing pattern MUST cite this atom's invariants by number.
```

NOTE: composing patterns — [Audit Trail](../compositions/audit-trail.md). Forthcoming: Activity Feed, Event-Sourced Reservation.

## Example

A composing system wraps each Task action as an event whose data is the encoding of `{type: "add", id: "t1", description: "buy milk"}`, `{type: "complete", id: "t1"}`, `{type: "delete", id: "t1"}`. The log records them in order and never alters them; the user can later query the log to see what they did this week, restore deleted tasks (compose with Reverse Index + Restore), or reason about completion patterns, and the Task pattern itself is unchanged. A regulated system, a clinical record and a bank journal run the same two calls over other payloads. A compliance log appends the encoding of `{type: "patient_record_accessed", patient_id: "p123", actor: "dr_smith", reason: "treatment", at: "2026-05-07T14:32:11Z"}` and gets policy-bounded retention, integrity proof and verifiable attribution from the [Audit Trail](../compositions/audit-trail.md) composition, which composes this atom with [Retention Window](./retention-window.md), [Tamper Evidence](./tamper-evidence.md) and [Actor Identity](./actor-identity.md). A clinical history appends each observation, prescription and lab result, the patient chart is a view over it, and a mistake is corrected by a later correction event, never by an edit. A bank journal appends each credit, debit and adjustment, derives balances by replaying it, and appends a refund event referencing the original charge instead of editing it. What differs is the payload schema, the query patterns, and the composing patterns that derive the views.

### Regulated adversarial scenarios

Three scenarios the atom must survive in regulated contexts, each answered from one log instance and its read surface:

- **Regulator audit.** A bank examiner asks *"show me every journal entry recorded in March, in the order it was recorded."* The auditor calls [Read] with a wall-time [Query] for March. The log answers every landed [Event] the query matches (Invariant 5.1), by [Sequence Number], rising (Invariant 5.2), the order in which a replay of the journal derives the balances the bank reported. The order is the sequence number's: a [Recording Instant] that falls between two events is a clock fault and not an order finding (Invariant 7.2, Check 5.2). What the log cannot answer from its own records is who wrote an entry and whether it is the entry first written; an examiner who needs those reads the composed Actor Identity and Tamper Evidence (External check 4, External check 5), as [Audit Trail](../compositions/audit-trail.md) wires them.
- **Disputed transaction, or a data-subject request.** A customer says *"I never withdrew 100."* The investigator reads the journal by sequence number range around the withdrawal: the event stands at its sequence number with the [Data] it landed with (Invariant 2.1), no event the log once held is gone from it (Invariant 1.1, 1.2), and a correction stands as a later event, a reversal referencing the charge, never as an edit (State 9). An append the database refused answered [Storage Failure] and never landed (Operation 9, Operation 11), so a withdrawal the customer was told failed is in no read. A patient asking that her chart entries be erased is a different request: the atom erases nothing (Erasure 1) and is not read as meeting the obligation (Erasure 3); the deployment composes an erasure pattern (Erasure 2), and the log keeps the order it recorded.
- **Breach or incident investigation.** After a database incident an investigator asks *"did the log lose or change anything?"* The investigator reads every committed version of the log instance against its reads now: an event with a committed version that a read whose query it matches no longer answers breaks Invariant 1.1 (Check 1.1); an event field that differs between two committed versions breaks Invariant 2.1 (Check 1.2); two events sharing a sequence number or an event id break Invariant 3.1 or 6.1 (Check 2.1, Check 2.2). The atom detects no tampering of its own (Non-goal 3): an adversary who rewrites every committed version the host keeps leaves nothing this log can show, and the investigation that must survive one reads a composed Tamper Evidence (Non-goal 4, External check 4).

## Source

Event Log is a foundational primitive, and these standards bear on it:

- **ISO/IEC 27001** (International Organization for Standardization / International Electrotechnical Commission — joint information-security management standard) — mandates event logging for security-relevant actions.
- **NIST SP 800-92** (Special Publication 800-92 of the National Institute of Standards and Technology — the US federal standards body) — *Guide to Computer Security Log Management*; describes log lifecycle, integrity, retention requirements.
- **GDPR (General Data Protection Regulation — the European Union's data-protection law) Article 17** — the right to erasure, which requires true deletion of recorded content; a composing erasure pattern's obligation, never met by an edit to this log (Erasure 2, Erasure 3).
- **W3C (World Wide Web Consortium — the web standards body) Activity Streams 2.0** — JSON (JavaScript Object Notation — a lightweight text format for structured data) format for activity feeds; treats activities as events with actor / verb / object structure.
- **Event Sourcing literature** — Greg Young's early write-ups; Martin Fowler's *Event Sourcing*; foundational pattern in domain-driven design.
- **Database write-ahead logging (WAL)** — the same primitive at the storage layer; ARIES (Algorithms for Recovery and Isolation Exploiting Semantics — a classic database crash-recovery method) recovery, PostgreSQL WAL, MySQL binlog.
- **Distributed-systems replication logs** — Kafka topics, Raft logs, Paxos value logs.
- **Version control** — Git's commit log is an Event Log with cryptographic tamper-evidence (a Merkle DAG — a directed acyclic graph whose nodes are linked by cryptographic hashes, so any change to history is detectable) layered on top.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the conception of a freestanding concept with state, actions, and operational principles.
- **Eiffel's design-by-contract** — preconditions on [Append] and [Read].
- **Linear temporal logic** (a formal notation for reasoning about sequences of states over time) — append-only, event immutability, and sequence-number monotonicity expressed as temporal properties (`always`, `until`).

## Proof

### Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given one log instance, with its events' committed versions (Execution Contract Generation acceptance 1), and the atom's own read surface. This atom claims append-only, total order and read consistency while the evidence for those claims has until now lived in a formal model, a twin suite and five independent renders, none of which a reader of this pattern has met. This section is the bridge: the same claims, provable from the log.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY event with a committed version answered by EVERY read of the event's log instance whose query the event matches (Invariant 1.1, Invariant 5.1; Execution Contract Generation acceptance 1).
Check 1.2: An auditor MUST find EVERY event field of EVERY event unchanged across EVERY committed version of the event (Invariant 2.1; Execution Contract Generation acceptance 1).
Check 2.1: An auditor MUST find no two landed events sharing a sequence number (Invariant 3.1).
Check 2.2: An auditor MUST find no two events sharing an event id (Invariant 6.1).
Check 2.3: An auditor MUST find a landed event's sequence number above EVERY sequence number an earlier landed event carries (Invariant 4.1).
Check 3.1: An auditor MUST find a read answering the events by sequence number, rising (Invariant 5.2).
Check 3.2: IF no event landing EXISTS between the two commits at which two reads of one query answer THEN an auditor MUST find the two reads, each as of the commit the read answers at, answering alike (Invariant 5.1, Invariant 5.2, Execution Contract Read 6, Execution Contract Generation acceptance 1).
Check 3.3: An auditor MUST find a read answering an empty sequence for a well-formed query matching nothing (Operation 16).
Check 3.4: An auditor MUST find a read answering invalid-query for a malformed query (Operation 15).
Check 4.1: An auditor MUST find EVERY event carrying event id, sequence number, recording instant AND data (State 2).
Check 4.2: An auditor MUST find a fresh log instance beginning next sequence number at one (State 5).
Check 5.2: An auditor MUST NOT read a falling recording instant as an order finding (Invariant 7.2).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes and Execution Contract Generation acceptance 1 has a check read.

#### External checks

```
External check 4: An auditor needing the log confirmed free of tampering MUST compose Tamper Evidence (Non-goal 4).
External check 5: An auditor needing an event's writer confirmed MUST compose Actor Identity (Non-goal 6).
External check 6: An auditor needing the payload cap confirmed MUST read the cap the instance holds PER Execution Contract Input 2 (Operation 5, Capability requirement 4).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the log (also: a log instance, a fresh log instance); the host; the transition; a composing pattern (also: a pattern, a writer); a business caller; a caller; an implementation; the deployment; the database; an event; a read; an append; an auditor.

Term records: event — one recorded fact, carrying event id, sequence number, recording instant and data; the log carries log name and next sequence number.

Term record verbs: derive, identify, allocate, supply, reuse, reassign, compare, order, own, hold, carry, begin, raise, offer, write, stamp, answer, accept, refuse, read, remain, remove, change, share, stand, fall, land, prune, detect, record, index, collapse, push, append, compose, cite, renumber, add, erase, match, find, declare.

Term value sets: event field (declared once, at `Term event field`; cited here by GRACE-lang Closed vocabulary 15).

Term bounds: payload cap (the per-instance bound on data's size).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11); landed (declared once, at `Term landed`; cited here by GRACE-lang Closed vocabulary 15).

Term terms: event id, seam, now, transition, business caller, event, sequence number, recording instant, data, log name, next sequence number, landed, event field, query, payload cap, committed version.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Event Log]: #event-log
[Event]: #event
[Append]: #append
[Read]: #read
[Event Id]: #event-id
[Sequence Number]: #sequence-number
[Recording Instant]: #recording-instant
[Data]: #data
[Log Name]: #log-name
[Next Sequence Number]: #next-sequence-number
[Query]: #query
[Invalid Payload]: #invalid-payload
[Invalid Query]: #invalid-query
[Storage Failure]: #storage-failure

## Status

`done — 2026-11-24` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-24
formal: verified — event-log.tla + 3 twins (2026-06-03); event-log.als + 11 twins (the static data model, 2026-11-12: State 2 through 5, Invariant 3.1, 3.2, 4.1, 5.1, 5.2 and 6.1 and Operation 5 and 16 checked on every log a fresh instance and admitted [Append] calls leave and on every answer an admitted [Read] gives over such a log, Invariant 3.1, 4.1 and 6.1 a cross-check with the TLA+ model; nothing testable in Alloy for Invariant 1.1, 1.2 and 2.1: each compares the log or an event with a later version of it, which a single state cannot show, so they are the TLA+ model's; nor for Invariant 7.2, which names the field that is the order, a definition no state can break, the Invariant 5.2 check holding a read to it); coverage 2026-11-10 (unit formal: more coverage for the yes votes): owes a TLA+ check of Invariant 2 (across steps); owed rows: Invariant 2, 2026-11-12
last gate: 2026-11-24 — Final Critique 21, a delta round (the reach of Final Critique 20's settle, 7 rules and terms and 7 changed lines), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at e4a04ffc — foundational count 0 after the blind second triage, clean, one sample; Linus's one foundational claim, that Operation 23 (the append answers the sequence number the event carries) cannot hold beside Operation 5 and Operation 22, whose refused calls land no event, was refuted by both triages: Execution Contract Read 4 holds a rule of what an action answers other than a refusal for a call the action admits alone, so an invalid-payload call answers its refusal and no sequence number, as Operation 4 has stood beside the same two refusals since Final Critique 13, and the finder's cure restates Read 4; the blind second triage (an Opus subagent) found nothing of its own, and no cure was made; 2026-11-24 — Final Critique 20, a delta round (the reach of Final Critique 19's settle and the bonds wording commit 594d216a, 6 rules and terms and 3 changed lines), one reader (Linus opencode/beam-free), frozen at 594d216a — foundational count 1, not clean, no sample; Linus's report counted 0 foundational, 3 refining and 1 rhetorical, and the blind second triage (an Opus subagent) refuted its three pressed questions and two of the three refining claims (Operation 5 and Operation 22 answer one refusal, and Execution Contract Refusal 1 orders it; Input 2's zero ban is on a string's length; Operation 5 has the corpus form of a cap rule, and Term payload cap already counts bytes) and placed the Invalid Payload entry's wording rhetorical, and found one foundational finding of its own, Kind A: the offer's append arm answered only the event id, while Bonds Term append says an append answers the record's place and Bonds journal 7 reads one record by the place an append answered, so no caller could name the one-event range the Offers sentence promises; cured by Operation 23, the append answering the sequence number the event carries (the offer's place, its order), the signature, the Append card, the case-space row, the examples and the offer's arms saying so; the settle's own refining cures: the Invalid Payload entry names the call's data, not data supplied and omitted, and Term payload cap leaves the count to Execution Contract Input 2 instead of stating one; 2026-11-24 — Final Critique 19, a delta round (the reach of Final Critique 18's settle and the journal commits 0ea88b89 and 097687f5, 15 rules and terms), one reader (Linus opencode/beam-free), frozen at 097687f5 — foundational count 2, not clean, no sample; Linus's two foundational claims both stood: a negative payload cap made Operation 5 (data over the cap is refused) and Operation 6 (empty data is accepted) impossible together, which Term payload cap now closes by naming the cap a whole number no less than 0, and a call that omits data or carries no sequence of bytes had no stated answer (Execution Contract Input 1 hands a blank input to the specification, and Input 3's default invalid-request is not on the page's refuses line), which Operation 22 answers with invalid-payload, the Invalid Payload entry, the case-space row and the example saying so (an Opus subagent placed the second finding foundational, Kind C); the three refining claims and the rhetorical one were refuted or answered by text the page holds (Term query already makes a range whose lower end is above its upper end malformed; Bonds Term journal offer fields and this page's Offers section say the app sets the keep; Term payload cap already counts bytes, and Execution Contract Input 2's zero ban is on a string's length); 2026-11-22 — Final Critique 18, a delta round (the reach of Final Critique 17's cure, 14 rules and terms), one reader (Linus opencode-go/beam-free), frozen at 330ca0d0 — foundational count 0 after the blind second triage, clean, one sample; Linus's two foundational claims were placed refining B by the first triage and refuted D and refining B by the blind second: an empty byte sequence is data by Term data and Operation 6 (the empty sequence is a sequence of bytes, stored verbatim per Execution Contract Input 4), and counting data's bytes for the payload cap is no reading of them, so Non-goal 11 now says the one use; the settle's own refining cures: Term data reads empty or not, Term payload cap says a cap of 0 admits only empty data, and Identity 4 deleted (Logic confinement 14 owns it); 2026-11-21 — Final Critique 17, a delta round (the reach of the reorganisation, 87 rules and terms), one reader (Linus beam-free), frozen at 032ca56d — foundational count 1 after the blind second triage, not clean, no sample; Linus's report counted 0 foundational, 3 refining and 3 held questions, and the blind second triage refuted all six (Term payload cap counts per Input 2's own-answer clause, Read 5 and Query 5 do not reach a log that names its order and has no string axis, State 5 and Identity 10 own the fresh instance whoever starts it) and placed one finding of its own foundational: the page called data an opaque payload and capped it in bytes with no encoding named, so a 40,000-character string was within the cap on a build counting UTF-8 and over it on one counting UTF-16; cured by Term data, now an opaque sequence of bytes a composing pattern encodes its structured value into (Composition note 3), the examples saying so; the settle's own cures: Identity 3 deleted (Logic confinement 3 owns it) and three empty headings removed; 2026-11-20 — Final Critique 16, a delta round, one reader (Linus claude-haiku-5-5), frozen at 61ab031f — foundational count 0 after the blind second triage, clean, one sample; Linus's two foundational claims (a purge between the two reads of Check 3.2, and the auditor's own reads against Execution Contract Generation acceptance 1) placed refining B by the first triage and refuted C by the blind second: the check reads each query as of a committed version, Database 5 removes every version of what a purge erases, so both reads lack the purged event and the check holds, and Check 3.2 now cites Generation acceptance 1; 2026-11-19 — Final Critique 15, a delta round, one reader (Linus minimax-m3), frozen at e4c5745 — foundational count 0 after the blind second triage, clean, one sample; Linus's report claimed 2 foundational, 8 refining and 3 rhetorical, and neither foundational held (refuted: the lowered payload cap starts from a deployment declaring a cap a landed value exceeds, which Execution Contract Input 2 forbids, and its cure restates Input 2's carve-out; a range carrying no lower end stays malformed under Execution Contract Query 1, which Term query displaces only for the upper end, and the entry for [Invalid Query] names it); the settle's own refining cures: External check 6 reads the cap the instance holds per Input 2, Capability requirement 2 cites Read 6, Check 3.2 reads between the commits two reads answer at, the entry for [Query] cites Operation 15 for the answer; 2026-11-19 — Final Critique 14, a delta round, frozen at c649138 — foundational count 1, not clean, no sample; 2026-10-25 — Final Critique 13, frozen at bae1f12 — foundational count 0, clean, one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./event-log.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/event-log.md`.

</details>

NOTE: End of Event Log.
