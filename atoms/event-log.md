---
title: Event Log
parent: Atomic Concepts
has_toc: true
toc: true
---

# Event Log

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Event Log is an append-only record. Anything written to it stays, in the order it arrived, unchanged, for as long as the log exists. It is the foundation that audit trails, undo histories, activity feeds, transaction journals, and replay systems are all built on. It offers just two operations. One adds an event to the end and returns an identifier for it; the other reads events back in order. There is no way to edit or delete, by design. Every event gets a strictly increasing sequence number that fixes its place in line. That number is kept separate from the human-readable timestamp on purpose: clocks can drift or jump, but the sequence number never does, so the log can always be replayed faithfully even on a machine with a bad clock. The log itself takes no position on how long to keep events, how to prove they have not been tampered with, who wrote them, or how to search them. All of these are handled by separate patterns layered on top, which is why the same simple log can sit under a personal task history, a medical chart, a bank ledger, and a regulated audit trail.

---

## Intent

WHY:
A composing pattern records facts about state changes, and the same need recurs under a dozen names: audit trails, undo histories, activity feeds, event sourcing, write-ahead logs, replication journals, version-control logs, replay buffers. The shape is constant — a stream of facts, recorded in order, never altered afterward, available for retrospective query. This atom is that stream and nothing else. It carries no opinion about what an event means, how long to keep one, who wrote one, whether one has been tampered with, or how to search by payload; every one of those is a composing pattern's, and the atom is useful under a task list, a patient chart, a bank journal and a regulated audit trail precisely because it declines all of them. What it does carry is the structural guarantee the others rest on: the sequence is faithful to what was recorded.

## Structure

### Identity model

```
Identity 1: The atom MUST identify an event by the event id.
Identity 2: The host MUST allocate an event id at the atom's seam.
Identity 3: The transition MUST NOT allocate an event id.
Identity 4: The business caller MUST NOT supply an event id.
Identity 5: The atom MUST NOT reuse an event id.
Identity 6: The atom MUST NOT reassign an event id.
Identity 7: The atom MUST compare event ids by equality.
Identity 8: The atom MUST NOT order events by event id.
Identity 9: The atom MUST NOT identify an event by the event's data.
Identity 10: A composing pattern MUST own how many log instances a deployment runs.
```

Term event id: the opaque value naming one event — an [Event Id]; allocated once, never again.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the event id here.
Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term transition: the atom's evaluation of one call against the log, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

### State

```
State 1: The log MUST hold events in EXACTLY ONE total order.
State 2: EVERY event MUST carry event id, sequence number, recording instant and data.
State 3: The log MUST carry log name.
State 4: The log MUST carry next sequence number.
State 5: A fresh log instance MUST begin next sequence number at one.
State 6: IF [Append] answers event id THEN [Append] MUST raise next sequence number by one.
Deleted: State 7. Execution Contract Database 3 owns it.
State 8: The atom MUST NOT offer a delete surface.
State 9: The atom MUST NOT offer an edit surface.
```

NOTE: watch the admitted effect (State 6).

Term event: one recorded fact in the log — an [Event]; fixed in place once landed.

Term sequence number: the strictly rising integer an event carries — a [Sequence Number]; the log's order and nothing else.

Term recording instant: the wall-time instant an event was appended, stamped from the injected clock — a [Recording Instant]; an annotation, never the order.

Term data: the opaque payload a composing pattern supplies — [Data]; the atom stores the payload and reads nothing in it.

Term log name: the name telling one log instance from another — a [Log Name].

Term next sequence number: the sequence number the next landed event carries — a [Next Sequence Number]; part of the instance's persistent state.

Term landed: an event a successful [Append] wrote.

Term event field: event id | sequence number | recording instant | data.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
```

### Operations

```
append(data)
  answers event_id
  refuses invalid-payload | storage-failure

read(query)
  answers events
  refuses invalid-query
```

```
Operation 1: [Append] MUST write the event at the tail.
Operation 2: [Append] MUST stamp recording instant from the injected clock.
Operation 3: [Append] MUST carry next sequence number into the event.
Operation 4: [Append] MUST answer event id.
Operation 5: IF data EXCEEDS the payload cap THEN [Append] MUST answer invalid-payload.
Operation 6: [Append] MUST accept empty data.
Deleted: Operation 7. Execution Contract Database 2 owns it.
Deleted: Operation 8. Execution Contract Database 2 owns it.
Operation 9: IF the database refuses the write THEN [Append] MUST answer storage-failure.
Operation 10: [Append] MUST NOT answer event id with storage-failure.
Operation 11: A caller MUST read storage-failure as the event not landing.
Deleted: Operation 12. Execution Contract Database 2 owns it.
Deleted: Operation 13. Invariant 5.1 owns it.
Deleted: Operation 14. Invariant 5.2 owns it.
Operation 15: IF the query is malformed THEN [Read] MUST answer invalid-query.
Operation 16: [Read] MUST answer an empty sequence for a well-formed query matching nothing.
Operation 17: [Read] MUST NOT write.
Operation 18: The implementation MUST own the query's shape.
Deleted: Operation 19. Capability requirement 1 owns it.
Deleted: Operation 20. Execution Contract Logic confinement 3 owns it.
Operation 21: The business caller MUST NOT supply recording instant.
```

Term query: what a read asks for — a [Query]: a sequence number range, a wall-time range, or a combination of the two.

Term payload cap: the per-instance bound on data's size, in bytes; 65,536 bytes where a deployment declares none.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the log |
|---|---|---|---|
| [Append] | data within the cap, database accepts | event id | one event lands at the tail, next sequence number rises (Operation 1, Operation 3, State 6) |
| [Append] | data over the cap | [Invalid Payload] | none — the precondition failed before the write (Operation 5) |
| [Append] | database refuses the write | [Storage Failure] | nothing lands; next sequence number is unchanged (Operation 9, State 6) |
| [Read] | query well-formed, events match | the events, ascending | none — the call reads (Invariant 5.1, Operation 17) |
| [Read] | query well-formed, nothing matches | empty sequence | none (Operation 16) |
| [Read] | query malformed | [Invalid Query] | none (Operation 15) |

### Invariants

- **Invariant 1 — Append-only.**
  ```
  Invariant 1.1: An event in the log MUST remain in the log for the life of the log instance.
  Invariant 1.2: The atom MUST NOT remove an event.
  ```
- **Invariant 2 — Event immutability.**
  ```
  Invariant 2.1: EVERY event field of a landed event MUST NOT change.
  ```
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
  Deleted: Invariant 5.3. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
  ```
- **Invariant 6 — No id reuse.**
  ```
  Invariant 6.1: Two events in the log MUST NOT share an event id.
  ```
- **Invariant 7 — Wall-time best-effort monotonicity.**
  ```
  Deleted: Invariant 7.1. Invariant 7.2 owns it: two appends the database serializes can land in the order opposite to their clock readings, so recording instant can fall in append order under a non-decreasing clock.
  Invariant 7.2: sequence number IS AUTHORITATIVE FOR the log's order.
  ```

Append-only and event immutability together give the *immutable journal* property, the one that tells an Event Log from a mutable record set. Total order and monotonicity give *replay*. Read consistency gives *durable visibility*. No id reuse forecloses identity collisions across time.

## Examples

The same pattern, four domains, identical mechanic.

### Personal Todo activity log

A composing system wraps each Personal Todo action as an event: `{type: "add", id: "t1", description: "buy milk"}`, `{type: "complete", id: "t1"}`, `{type: "delete", id: "t1"}`. The log records them in order, never alters them. The user can later query the log to see what they did this week, restore deleted tasks (compose with Reverse Index + Restore), or reason about completion patterns. The Personal Todo pattern itself is unchanged; the log is a side stream the composing pattern maintains.

### Compliance audit log

A regulated system records every state-changing action: `{type: "patient_record_accessed", patient_id: "p123", actor: "dr_smith", reason: "treatment", at: "2026-05-07T14:32:11Z"}`. The log is append-only by definition. The [Audit Trail](../compositions/audit-trail.md) composition composes this atom with [Retention Window](./retention-window.md), [Tamper Evidence](./tamper-evidence.md), and [Actor Identity](./actor-identity.md) to add policy-bounded retention, integrity proof, and verifiable attribution. The Event Log itself doesn't know what compliance means; it preserves the sequence faithfully and lets compliance be layered on.

### Patient medical record (clinical history)

Each clinical observation, prescription, lab result, and vital sign is appended as an event with structured data. The clinical record *is* an Event Log; the patient chart is a *view* over it (latest values per field). Mistakes are corrected by appending a *correction event*, never by editing the original — the record must show what was originally recorded and when it was corrected. ICD (International Classification of Diseases — the World Health Organization's standard diagnostic coding system) coding, billing extraction, and longitudinal analytics all read the same log.

### Bank transaction journal

Every credit, debit, transfer, and adjustment is appended as an event in the journal. Account balances are derived by replaying the journal up to a point in time. Reversals are appended as new events (a refund event referencing the original charge), never as edits. The journal is the source of truth; the balance display is a projection. Reconciliation, fraud detection, and regulatory reporting all read the same log.

The mechanic is identical across all four. What differs: payload schema, query patterns, and the composing patterns that derive views (current todo list, audit report, current chart, current balance) from the underlying log.

### Rejection paths

A single sequence exercising all three rejection reasons:

- `append(65_537_bytes_of_data)` → rejected invalid-payload (payload exceeds the default 65,536-byte cap; configurable per instance).
- `append({type: "deposit", amount: 500})` → accepted; returns `event_id e1` with `sequence_number 1`.
- `read({sequence_range: [-1, 5]})` → rejected invalid-query (negative sequence number is not a well-formed range parameter).
- `read({sequence_range: [1, 1]})` → returns `[e1]`; `sequence_number 1` matches, ordered ascending.
- Underlying database becomes temporarily unavailable. `append({type: "withdrawal", amount: 100})` → rejected storage-failure; event does not land; caller must treat the rejection as definitive. Nothing is written, so next sequence number stays at 2 (Operation 9, State 6).
- Database recovers. `append({type: "withdrawal", amount: 100})` → accepted; returns `event_id e2` with `sequence_number 2`.

All three rejection reasons ([Invalid Payload], [Invalid Query], [Storage Failure]) exercised in one thread.

---

## Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given one log instance and the atom's own read surface. This atom is the corpus's Start Here — the first pattern most readers meet — and it claims append-only, total order and read consistency while the evidence for those claims has until now lived in a formal model, a twin suite and five independent renders, none of which a first reader has met. This section is the bridge: the same claims, provable from the log.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY event of an earlier read in a later read of one log instance (Invariant 1.1).
Check 1.2: An auditor MUST find a re-read event's EVERY event field unchanged (Invariant 2.1).
Check 2.1: An auditor MUST find no two landed events sharing a sequence number (Invariant 3.1).
Check 2.2: An auditor MUST find no two events sharing an event id (Invariant 6.1).
Check 2.3: An auditor MUST find a landed event's sequence number above EVERY sequence number an earlier landed event carries (Invariant 4.1).
Deleted: Check 2.4. Execution Contract Database 1 owns it: a refused append writes nothing, so the sequence numbers carry no gap.
Check 3.1: An auditor MUST find a read answering the events by sequence number, rising (Invariant 5.2).
Check 3.2: IF no event landing between two reads of one query EXISTS THEN an auditor MUST find the two reads answering alike (Invariant 5.1).
Check 3.3: An auditor MUST find a read answering an empty sequence for a well-formed query matching nothing (Operation 16).
Check 3.4: An auditor MUST find a read answering invalid-query for a malformed query (Operation 15).
Deleted: Check 3.5. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
Check 4.1: An auditor MUST find EVERY event carrying event id, sequence number, recording instant AND data (State 2).
Check 4.2: An auditor MUST find a fresh log instance beginning next sequence number at one (State 5).
Deleted: Check 5.1. Check 5.2 owns it: a falling recording instant is no clock finding either, since two appends the database serializes can land in the order opposite to their clock readings.
Check 5.2: An auditor MUST NOT read a falling recording instant as an order finding (Invariant 7.2).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
Deleted: External check 1. Execution Contract Database 3 owns it.
Deleted: External check 2. Execution Contract Database 2 owns it.
Deleted: External check 3. Execution Contract Logic confinement 7 owns it: the page relies on no guarantee of the clock.
External check 4: An auditor needing the log untampered confirmed MUST compose Tamper Evidence (Non-goal 4).
External check 5: An auditor needing an event's writer confirmed MUST compose Actor Identity (Non-goal 6).
External check 6: An auditor needing the payload cap confirmed MUST read the deployment's own declaration (Operation 5).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT prune an event.
Non-goal 2: A pattern needing time-bounded retention MUST compose Retention Window.
Non-goal 3: The atom MUST NOT detect tampering.
Non-goal 4: A pattern needing integrity proof MUST compose Tamper Evidence.
Non-goal 5: The atom MUST NOT record who appended an event.
Non-goal 6: A pattern needing attribution MUST compose Actor Identity.
Non-goal 7: The atom MUST NOT index data.
Non-goal 8: A pattern needing lookup by payload field MUST compose a reverse-index pattern.
Non-goal 9: The atom MUST NOT order events across log instances.
Non-goal 10: A pattern needing multi-host order MUST compose a consensus pattern.
Non-goal 11: The atom MUST NOT read data.
Non-goal 12: A pattern needing schema validation MUST compose a schema-evolution pattern.
Non-goal 13: The atom MUST NOT collapse events into a snapshot.
Non-goal 14: The atom MUST NOT push an event to a subscriber.
Non-goal 15: The atom MUST NOT append two events atomically.
Deleted: Non-goal 16. Execution Contract Database 1 owns it.
```

NOTE: the owners — [Retention Window](./retention-window.md) (Non-goal 1, Non-goal 2) and a Storage Tier pattern *(forthcoming)* for cold events; [Tamper Evidence](./tamper-evidence.md) (Non-goal 3, Non-goal 4); [Actor Identity](./actor-identity.md) (Non-goal 5, Non-goal 6); a Reverse Index pattern *(forthcoming)* (Non-goal 7, Non-goal 8); a Snapshot pattern *(forthcoming)* (Non-goal 13); a Change Feed pattern *(forthcoming)* (Non-goal 14).

Where the pattern breaks down: when the host cannot supply atomic, serialized appends — most adversarially-distributed settings; when an event must be edited or deleted in place; when order must come from something other than append order.

## Edge cases

### Durability across crashes

```
Deleted: Durability 1. Execution Contract Database 3 owns it.
Deleted: Durability 2. Execution Contract Database 3 owns it.
Deleted: Durability 3. Execution Contract Database 3 owns it.
Deleted: Durability 4. Execution Contract Database 3 owns it.
```

### Erasure where law requires it

```
Erasure 1: The atom MUST NOT erase an event.
Erasure 2: A deployment under an erasure obligation MUST compose an erasure pattern.
Erasure 3: A deployment under an erasure obligation MUST NOT read this atom as satisfying the obligation.
```

### Sequence-number gaps on storage failure

```
Deleted: Sequence gap 1. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
Deleted: Sequence gap 2. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
Deleted: Sequence gap 3. Execution Contract Database 1 owns it: a refused append writes nothing, so the sequence numbers carry no gap.
Deleted: Sequence gap 4. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
```

## Composition notes

```
Composition note 1: A composing pattern MUST append on every state change.
Composition note 1a: A composing pattern MAY derive state by replay.
Composition note 2: A composing pattern MUST own what an event means.
Composition note 3: A composing pattern MUST own the payload's schema.
Composition note 4: This atom's invariant numbers MUST stand as a frozen contract surface.
Composition note 5: A composing pattern MUST cite this atom's invariants by number.
```

NOTE: composing patterns — [Audit Trail](../compositions/audit-trail.md). Forthcoming: Activity Feed, Event-Sourced Reservation.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the log (also: a log instance, a fresh log instance); the host; the transition; a composing pattern (also: a pattern, a writer); a business caller; a caller; an implementation; the deployment; the database; an event; a read; an append; an auditor.

Term records: event — one recorded fact, carrying event id, sequence number, recording instant and data; the log carries log name and next sequence number.

Term record verbs: derive, identify, allocate, supply, reuse, reassign, compare, order, own, hold, carry, begin, raise, offer, write, stamp, answer, accept, refuse, read, remain, remove, change, share, stand, fall, land, prune, detect, record, index, collapse, push, append, compose, cite, renumber, add, erase, match, find.

Term value sets: event field = event id | sequence number | recording instant | data.

Term bounds: payload cap (the per-instance bound on data's size).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11); landed — written by a successful append.

Term terms: event id, seam, transition, business caller, event, sequence number, recording instant, data, log name, next sequence number, landed, event field, query, payload cap.

#### Event Log

The named append-only sequence this atom defines: anything appended stays, in append order, unchanged, for the lifetime of the instance. It is the substrate audit trails, undo histories, activity feeds, and event-sourced systems compose on top of. Multiple instances coexist; this card describes one.

Kind: Type

#### Event

A single recorded fact in an [Event Log] — one entry in the sequence, fixed in place once appended. It carries its [Event Id], [Sequence Number], [Recording Instant], and [Data]; nothing about it changes after [Append].

Kind: Type

#### Append

The behavior a composing pattern invokes to record a new [Event] at the tail of the log. It allocates the next [Sequence Number], stamps [Recording Instant], and returns the [Event Id]. It is the only way data enters the log.

Kind: Operation

#### Read

The behavior a composing pattern invokes to retrieve events matching a [Query], returned in [Sequence Number] order. It only reads; the log is unchanged.

Kind: Operation

#### Event Id

The opaque, immutable identity of an [Event], allocated by the host at the I/O seam on [Append], never reused. It supports equality but carries no ordering — ordering is [Sequence Number]'s job.

Kind:       Field
Field of:   Event
Projection: event_id

#### Sequence Number

The strictly increasing integer assigned to each [Event] at [Append]. It fixes the [Event]'s place in the total order and is the authoritative basis for ordering — kept separate from [Recording Instant] on purpose, because a clock can drift but the sequence never does.

Kind:       Field
Field of:   Event
Projection: sequence_number

#### Recording Instant

The wall-time at which an [Event] was appended — an annotation of when, not the basis of order. Stamped from the host-injected clock on [Append], it can fall in append order — under a clock that misbehaves, or where two appends land in the order opposite to their clock readings — and [Sequence Number] is authoritative.

Kind:       Field
Field of:   Event
Projection: recorded_at

#### Data

The opaque payload a composing pattern supplies on [Append] and the [Event] then carries. The Event Log stores and returns it verbatim and never interprets it.

Kind:       Field
Field of:   Event
Projection: data

#### Log Name

The identifier that distinguishes one [Event Log] instance from the others co-existing in a system (one per audited subsystem, one per user history, and so on).

Kind:       Field
Field of:   Event Log
Projection: name

#### Next Sequence Number

The [Sequence Number] the next appended [Event] will receive. It begins at 1 for a fresh instance and rises by one on each [Append] that lands an [Event].

Kind:       Field
Field of:   Event Log
Projection: next_sequence_number

#### Query

The selection a caller passes to [Read] — a sequence-number range, a wall-time range, or a combination of the two. Its exact shape is implementation policy; the only requirement is that a valid [Query] returns events in [Sequence Number] order.

Kind:         Parameter
Parameter of: Read
Projection:   query

#### Invalid Payload

The refusal [Append] returns when the supplied [Data] violates the configured payload constraints (for example, exceeding the size cap). The [Event] does not land.

Kind:       Member
Member of:  the Append rejection
Role:       Outcome
Projection: invalid-payload

#### Invalid Query

The refusal [Read] returns when the [Query] is malformed — an invalid range, or a selection on the payload. No events are returned.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

#### Storage Failure

The refusal [Append] returns when the underlying database write fails after all preconditions pass. The caller must treat it as definitive — the [Event] did not land, and the [Next Sequence Number] is unchanged.

Kind:       Member
Member of:  the Append rejection
Role:       Outcome
Projection: storage-failure

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

---

## Standards references

Event Log is a foundational primitive with deep standards backing:

- **ISO/IEC 27001** (International Organization for Standardization / International Electrotechnical Commission — joint information-security management standard) — mandates event logging for security-relevant actions.
- **NIST SP 800-92** (National Institute of Standards and Technology — US federal standards body) — *Guide to Computer Security Log Management*; describes log lifecycle, integrity, retention requirements.
- **GDPR (EU General Data Protection Regulation) Article 17** — the right to erasure, which requires true deletion of recorded content; a composing erasure pattern's obligation, never met by an edit to this log (Erasure 2, Erasure 3).
- **W3C (World Wide Web Consortium — the web standards body) Activity Streams 2.0** — JSON (JavaScript Object Notation — a lightweight text format for structured data) format for activity feeds; treats activities as events with actor / verb / object structure.
- **Event Sourcing literature** — Greg Young's early write-ups; Martin Fowler's *Event Sourcing*; foundational pattern in domain-driven design.
- **Database write-ahead logging (WAL)** — the same primitive at the storage layer; ARIES (Algorithms for Recovery and Isolation Exploiting Semantics — a classic database crash-recovery method) recovery, PostgreSQL WAL, MySQL binlog.
- **Distributed-systems replication logs** — Kafka topics, Raft logs, Paxos value logs.
- **Version control** — Git's commit log is an Event Log with cryptographic tamper-evidence (a Merkle DAG — a directed acyclic graph whose nodes are linked by cryptographic hashes, so any change to history is detectable) layered on top.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the conception of a freestanding concept with state, actions, and operational principles.
- **Eiffel's design-by-contract** — preconditions on [Append] and [Read].
- **Linear temporal logic** (a formal notation for reasoning about sequences of states over time) — append-only, event immutability, and sequence-number monotonicity expressed as temporal properties (`always`, `until`).

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — event-log.tla + 1 twin, 2026-06-03
last gate: 2026-10-20 — Final Critique 5, the council's first round on the page and the first on its GRACE-lang text (453bde3) and the Store-contract rewrite (4abad76), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS MiniMax M3.1 Flash, Linus MiMo V2.6 Flash), each handed only the round's reading set, three passes on one text (frozen at 6ed25d6); the round rests on three counted passes — foundational count 5 after triage (12 reports, 2 sent down to refining, 1 rejected), all Kind A: the default payload cap read as 64,000 bytes or 65,536, and the Rejection-paths example held under the first reading alone; a query carried a payload predicate the atom may not read; Check 3.2 failed a conforming log when an event landed between two reads; State 6 raised next sequence number on a refused append and the gap rules let a failed write consume a sequence number, which the Store contract rules out; and Invariant 7.1's recording instant fell under a non-decreasing clock when the store serialized two appends in the order opposite to their clock readings; 17 refining reports, 5 rhetorical reports; not clean; every foundational finding cured in place; 2026-06-18 — Final Critique 4, fresh reader — clean

open:
- 2026-10-20-a · refining · Term payload cap; External check 6 · the deployment's declaration of the payload cap is named (Term payload cap, External check 6) and declared by no Capability requirement → a Capability requirement naming the declaration and the default it falls back to
- 2026-10-20-b · refining · Operation 18; Term query; Examples · the query's shape is the implementation's (Operation 18), while the Examples, which compile into tests, write queries in one shape and pin that shape's verdict on a range bound below one, and whether a deployment may decline a query kind Term query names is unsaid → fix a portable query shape, or write the Examples' queries in one declared shape
- 2026-10-20-c · refining · Term seam; Term now; Term transition; Term business caller · each says the Execution Contract's Logic Confinement Principle declares it, and that section declares none of the four → declare the four there, the corpus's one seam wording, or point each at its declaration
- 2026-10-20-d · refining · State 3; State 5 · log name and a fresh log instance have no declared supplier → name who supplies each, a composing pattern (Identity 10) or the deployment
- 2026-10-20-e · refining · Examples · the Examples invoke regulated domains (a patient chart, a bank journal), and the method's When the conventions apply requires Regulated adversarial scenarios of such a page → write the subsection
- 2026-10-20-f · refining · Operation 1 · the tail is declared nowhere (GRACE-lang Closed vocabulary 4), where the grammar's own tail is a statement part → say in declared words where an append writes the event
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/event-log.md`; the rounds and the migration that got it here are in [its history](./event-log.hist.md).

- **2026-10-20 — A refused append leaves the counter, a query never reads the payload, and wall time promises no order.** *Chose:* next sequence number raised only by an append that answers event id (State 6), so a refused append consumes no sequence number and the gap rules go to Execution Contract Store 1 (Sequence gap 1 through 4, Check 2.4, Invariant 5.3, Check 3.5); a query of sequence number and wall-time ranges alone (Term query), so a selection on the payload is malformed (Operation 15); recording instant an annotation that can fall in append order, its promise under a non-decreasing clock withdrawn to the sequence number's authority (Invariant 7.1 to Invariant 7.2, Check 5.1 to Check 5.2, External check 3 to Execution Contract Logic confinement 7). *Over:* a gap the store's one transaction per action rules out; a payload predicate the atom may not evaluate (Non-goal 11); a clock guarantee the store does not give, since two appends it serializes can land in the order opposite to their clock readings (Execution Contract Store 2, Logic confinement 3). *Because:* Final Critique 5 found each a divergence between conforming builds or a conforming run breaking a stated rule, and in each the page already held the answer — the store it cites, its own non-goals, and the sequence number it makes authoritative.

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 2), and the eleven rules that restated them tombstoned to their owner — Non-goal 16, one write across two events, to Store 1; Operation 7, 8 and 12 and External check 2, appends to one log serialized and never refused for contention or ordering, to Store 2; State 7, Durability 1 through 4 and External check 1, the log and its next sequence number kept across a restart, to Store 3; rules 105 to 95. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The log's order stays the atom's own, carried by the sequence number (State 1, Invariant 3, Invariant 7.2) — two appends one action makes share one commit — so the atom cites no Order 1; what the atom does for its domain is unchanged.

NOTE: End of Event Log.
