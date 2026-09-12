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

```text
Identity 1: The atom MUST identify an event by the event_id.
Identity 2: The host MUST allocate an event_id at the atom's seam.
Identity 3: The transition MUST NOT allocate an event_id.
Identity 4: The business caller MUST NOT supply an event_id.
Identity 5: The atom MUST NOT reuse an event_id.
Identity 6: The atom MUST NOT reassign an event_id.
Identity 7: The atom MUST compare event_ids by equality.
Identity 8: The atom MUST NOT order events by event_id.
Identity 9: The atom MUST NOT identify an event by the event's data.
Identity 10: A composing pattern MUST own how many log instances a deployment runs.
```

Terms › `event_id`: the opaque value naming one event — an [Event Id]; allocated once, never again.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading and the event_id here.

Terms › `transition`: the atom's evaluation of one call against the log, as `execution-contract.md` §Logic confinement declares it.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

WHY:
Identity is allocated at the seam and handed in, which forecloses a caller that supplies an id of the caller's choosing and a transition that answers two ways for one input (Identity 2–4). Ordering is `sequence_number`'s alone: an id that sorts invites a reader to sort by it, and the day the id source changes shape, the order changes with it (Identity 8).

### State

```text
State 1: The log MUST hold events in EXACTLY ONE total order.
State 2: EVERY event MUST carry event_id, sequence_number, recorded_at and data.
State 3: The log MUST carry log_name.
State 4: The log MUST carry next_sequence_number.
State 5: A fresh log instance MUST begin next_sequence_number at one.
State 6: [Append] MUST raise next_sequence_number by one.
State 7: A durable implementation MUST preserve next_sequence_number across a restart.
State 8: The atom MUST NOT offer a delete surface.
State 9: The atom MUST NOT offer an edit surface.
```

Terms › `event`: one recorded fact in the log — an [Event]; fixed in place once landed.

Terms › `sequence_number`: the strictly rising integer an event carries — a [Sequence Number]; the log's order and nothing else.

Terms › `recorded_at`: the wall-time instant an event was appended, stamped from the injected clock — a [Recorded At]; an annotation, never the order.

Terms › `data`: the opaque payload a composing pattern supplies — [Data]; the atom stores the payload and reads nothing in it.

Terms › `log_name`: the name telling one log instance from another — a [Log Name].

Terms › `next_sequence_number`: the sequence_number the next landed event carries — a [Next Sequence Number]; part of the instance's persistent state.

Terms › `durability mechanism`: a write-ahead log, or another mechanism making a committed write survive a crash.

Terms › `landed`: an event a successful [Append] wrote; a consumed sequence_number under which nothing was written is not landed.

Terms › `event field`: `event_id` | `sequence_number` | `recorded_at` | `data`.

WHY:
A volatile instance that restarts `next_sequence_number` at one has broken Invariant 4 for the life of the instance while every individual append looks correct — which is why durability of that one datum is stated here and not left to a deployment note (State 7). There is no delete and no edit, and their absence is a rule rather than an omission, because *the log only grows* is the property every composing pattern rests on (State 8, State 9).

### Operations

```
append(data) → event_id | rejected(invalid-payload | storage-failure)
read(query) → events | rejected(invalid-query)
```

```text
Operation 1: [Append] MUST write the event at the tail.
Operation 2: [Append] MUST stamp recorded_at from the injected clock.
Operation 3: [Append] MUST carry next_sequence_number into the event.
Operation 4: [Append] MUST answer event_id.
Operation 5: IF data EXCEEDS the payload cap THEN [Append] MUST answer invalid-payload.
Operation 6: [Append] MUST accept empty data.
Operation 7: [Append] MUST NOT refuse for contention.
Operation 8: [Append] MUST NOT refuse for ordering.
Operation 9: IF the store refuses the write THEN [Append] MUST answer storage-failure.
Operation 10: [Append] MUST NOT answer event_id with storage-failure.
Operation 11: A caller MUST read storage-failure as the event not landing.
Operation 12: The host MUST serialize EVERY append to one log instance.
Operation 13: [Read] MUST answer EVERY landed event the query matches.
Operation 14: [Read] MUST order the answer by sequence_number, rising.
Operation 15: IF the query is malformed THEN [Read] MUST answer invalid-query.
Operation 16: [Read] MUST answer an empty sequence for a well-formed query matching nothing.
Operation 17: [Read] MUST NOT write.
Operation 18: The implementation MUST own the query's shape.
Operation 19: The host MUST read the clock at the atom's seam.
Operation 20: The transition MUST NOT read a clock.
Operation 21: The business caller MUST NOT supply recorded_at.
```

Terms › `query`: what a read asks for — a [Query]: a sequence_number range, a wall-time range, a payload predicate, or a combination.

Terms › `payload cap`: the per-instance bound on data's size; 64 kilobytes where a deployment declares none.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the log |
|---|---|---|---|
| [Append] | data within the cap, store accepts | `event_id` | one event lands at the tail, `next_sequence_number` rises (Operation 1, Operation 3, State 6) |
| [Append] | data over the cap | [Invalid Payload] | none — the precondition failed before the write (Operation 5) |
| [Append] | store refuses the write | [Storage Failure] | nothing lands; a sequence_number may be consumed (Operation 9, Sequence gap 1) |
| [Read] | query well-formed, events match | the events, ascending | none — the call reads (Operation 13, Operation 17) |
| [Read] | query well-formed, nothing matches | empty sequence | none (Operation 16) |
| [Read] | query malformed | [Invalid Query] | none (Operation 15) |

WHY:
An append refuses for one reason before the write and one reason at it, and for nothing else: no contention arm, no ordering arm, no retry semantics (Operation 7, Operation 8). Serialization is the load-bearing precondition under Invariant 3 and Invariant 4 — neither holds without it, and it is the host's to supply, not the atom's to enforce (Operation 12). `storage-failure` is definitive on purpose: a caller that treats it as *maybe* writes the event twice (Operation 10, Operation 11).

### Invariants

- **Invariant 1 — Append-only.**
  ```text
  Invariant 1.1: An event in the log MUST remain in the log for the life of the log instance.
  Invariant 1.2: The atom MUST NOT remove an event.
  ```
- **Invariant 2 — Event immutability.**
  ```text
  Invariant 2.1: EVERY event field of a landed event MUST NOT change.
  ```
- **Invariant 3 — Total order.**
  ```text
  Invariant 3.1: Two distinct landed events MUST NOT share a sequence_number.
  Invariant 3.2: EVERY two distinct landed events MUST stand in EXACTLY ONE order.
  ```
- **Invariant 4 — Sequence-number monotonicity.**
  ```text
  Invariant 4.1: A landed event MUST carry a sequence_number above EVERY sequence_number landed earlier.
  ```
  WHY: the invariant is over landed events, which is what leaves room for the gap a storage failure consumes (Sequence gap 1–4).
- **Invariant 5 — Read consistency.**
  ```text
  Invariant 5.1: A read MUST answer EVERY landed event the read's query matches.
  Invariant 5.2: A read MUST answer the events by sequence_number, rising.
  Invariant 5.3: A read MUST NOT answer an event for a consumed sequence_number no event landed under.
  ```
- **Invariant 6 — No id reuse.**
  ```text
  Invariant 6.1: Two events in the log MUST NOT share an event_id.
  ```
- **Invariant 7 — Wall-time best-effort monotonicity.**
  ```text
  Invariant 7.1: IF the clock is non-decreasing THEN recorded_at MUST NOT fall in append order.
  Invariant 7.2: sequence_number IS AUTHORITATIVE FOR the log's order.
  ```
  WHY: under an unreliable or adversarial clock `recorded_at` is an annotation that may lie, and nothing in the atom rests on it — which is the whole reason the two data are separate (Invariant 7.2).

Append-only and event immutability together give the *immutable journal* property, the one that tells an Event Log from a mutable record set. Total order and monotonicity give *replay*. Read consistency gives *durable visibility*. No id reuse forecloses identity collisions across time.

## Examples

The same pattern, four domains, identical mechanic.

### Personal Todo activity log

A composing system wraps each Personal Todo action as an event: `{type: "add", id: "t1", description: "buy milk"}`, `{type: "complete", id: "t1"}`, `{type: "delete", id: "t1"}`. The log records them in order, never alters them. The user can later query the log to see what they did this week, restore deleted tasks (compose with Reverse Index + Restore — see Undo History), or reason about completion patterns. The Personal Todo pattern itself is unchanged; the log is a side stream the composing pattern maintains.

### Compliance audit log

A regulated system records every state-changing action: `{type: "patient_record_accessed", patient_id: "p123", actor: "dr_smith", reason: "treatment", at: "2026-05-07T14:32:11Z"}`. The log is append-only by definition. The [Audit Trail](../compositions/audit-trail.md) composition composes this atom with [Retention Window](./retention-window.md), [Tamper Evidence](./tamper-evidence.md), and [Actor Identity](./actor-identity.md) to add policy-bounded retention, integrity proof, and verifiable attribution. The Event Log itself doesn't know what compliance means; it preserves the sequence faithfully and lets compliance be layered on.

### Patient medical record (clinical history)

Each clinical observation, prescription, lab result, and vital sign is appended as an event with structured data. The clinical record *is* an Event Log; the patient chart is a *view* over it (latest values per field). Mistakes are corrected by appending a *correction event*, never by editing the original — the record must show what was originally recorded and when it was corrected. ICD (International Classification of Diseases — the World Health Organization's standard diagnostic coding system) coding, billing extraction, and longitudinal analytics all read the same log.

### Bank transaction journal

Every credit, debit, transfer, and adjustment is appended as an event in the journal. Account balances are derived by replaying the journal up to a point in time. Reversals are appended as new events (a refund event referencing the original charge), never as edits. The journal is the source of truth; the balance display is a projection. Reconciliation, fraud detection, and regulatory reporting all read the same log.

The mechanic is identical across all four. What differs: payload schema, query patterns, and the composing patterns that derive views (current todo list, audit report, current chart, current balance) from the underlying log.

### Rejection paths

A single sequence exercising all three rejection reasons:

- `append(65_000_bytes_of_data)` → rejected `invalid-payload` (payload exceeds the default 64 KB cap; configurable per instance).
- `append({type: "deposit", amount: 500})` → accepted; returns `event_id e1` with `sequence_number 1`.
- `read({sequence_range: [-1, 5]})` → rejected `invalid-query` (negative sequence number is not a well-formed range parameter).
- `read({sequence_range: [1, 1]})` → returns `[e1]`; `sequence_number 1` matches, ordered ascending.
- Underlying store becomes temporarily unavailable. `append({type: "withdrawal", amount: 100})` → rejected `storage-failure`; event does not land; caller must treat the rejection as definitive. A sequence number may have been consumed; subsequent successful appends receive a strictly higher number, producing a gap in the dense sequence (see Edge cases — *Sequence-number gaps on storage failure*).
- Store recovers. `append({type: "withdrawal", amount: 100})` → accepted; returns `event_id e2` with a sequence number strictly greater than 1.

All three rejection reasons ([Invalid Payload], [Invalid Query], [Storage Failure]) exercised in one thread.

---

## Non-goals

```text
Non-goal 1: The atom MUST NOT prune an event.
Non-goal 2: A pattern needing time-bounded retention MUST compose [Retention Window](./retention-window.md).
Non-goal 3: The atom MUST NOT detect tampering.
Non-goal 4: A pattern needing integrity proof MUST compose [Tamper Evidence](./tamper-evidence.md).
Non-goal 5: The atom MUST NOT record who appended an event.
Non-goal 6: A pattern needing attribution MUST compose [Actor Identity](./actor-identity.md).
Non-goal 7: The atom MUST NOT index data.
Non-goal 8: A pattern needing lookup by payload field MUST compose a reverse-index pattern.
Non-goal 9: The atom MUST NOT order events across log instances.
Non-goal 10: A pattern needing multi-host order MUST compose a consensus pattern.
Non-goal 11: The atom MUST NOT read data.
Non-goal 12: A pattern needing schema validation MUST compose a schema-evolution pattern.
Non-goal 13: The atom MUST NOT collapse events into a snapshot.
Non-goal 14: The atom MUST NOT push an event to a subscriber.
Non-goal 15: The atom MUST NOT append two events atomically.
Non-goal 16: A pattern needing one write across two events MUST compose a transaction pattern.
```

WHY:
The bare log keeps everything, knows nothing about the payload, and serves one instance — and each of those is a seam a composing pattern fills: Retention Window prunes under an obligation, a Storage Tier pattern *(forthcoming)* moves cold events, Tamper Evidence proves nothing was rewritten, Actor Identity binds the writer, a Reverse Index pattern *(forthcoming)* finds an event by what is inside the payload, a Snapshot pattern *(forthcoming)* collapses a prefix, a Change Feed pattern *(forthcoming)* pushes. Events are immutable by this spec, which is not the same as tamper-evident: an adversary with write access to the store rewrites the log and the atom cannot tell (Non-goal 3, Non-goal 4). Each append is atomic and two appends are two writes; *both or neither* is a Transaction pattern's promise, over a store that offers one (Non-goal 15, Non-goal 16).

Where the pattern breaks down: when the host cannot supply atomic, serialized appends — most adversarially-distributed settings; when an event must be edited or deleted in place; when order must come from something other than append order.

## Edge cases

### Durability across crashes

```text
Durability 1: The atom MUST specify in-memory semantics.
Durability 2: The deployment MUST own persistence across a process restart.
Durability 3: A durable implementation MUST supply a durability mechanism.
Durability 4: A composing pattern MUST declare the log instance's durability as an instance capability requirement.
```

WHY:
Append-only and event immutability are best-effort across a crash unless the implementation supplies durability, and a composition whose rebuilds and scans assume the log survived a restart is resting on something no constituent promised — the obligation is declared, in the composition, or it is assumed (Durability 4; Audit Trail's open line of 2026-08-30).

### Sequence-number gaps on storage failure

```text
Sequence gap 1: An implementation MAY consume a sequence_number on a failed write.
Sequence gap 2: The next landed event MUST carry a sequence_number above a consumed sequence_number.
Sequence gap 3: A consumer MUST NOT read a gap as a lost event.
Sequence gap 4: An implementation avoiding a gap MUST take EXACTLY ONE OF allocating a sequence_number ONLY AFTER the write lands, returning a consumed sequence_number to the pool.
```

WHY:
Invariant 4 holds over landed events, so a gap violates nothing — but a consumer counting rows against sequence numbers reads the gap as a missing event and files a finding against a log that is correct (Sequence gap 3).

### Erasure where law requires it

```text
Erasure 1: The atom MUST NOT erase an event.
Erasure 2: A deployment under an erasure obligation MUST compose an erasure pattern.
Erasure 3: A deployment under an erasure obligation MUST NOT read this atom as satisfying the obligation.
```

WHY:
*Append corrections, never edit history* is the architecture, and it is the one place law overrides architecture: GDPR (EU General Data Protection Regulation) Article 17 and some healthcare regimes require true deletion of recorded content. The answer is a composing pattern designed with counsel — Erasure Tombstone or cryptographic shredding *(forthcoming)* — never a quiet edit to the log.

## Composition notes

```text
Composition note 1: A composing pattern MUST take EXACTLY ONE OF appending on every state change, deriving state by replay, both.
Composition note 2: A composing pattern MUST own what an event means.
Composition note 3: A composing pattern MUST own the payload's schema.
Composition note 4: This atom's invariant numbers MUST stand as a frozen contract surface.
Composition note 5: A composing pattern MUST cite this atom's invariants by number.
```

WHY:
The two contracts are append-on-change (the log is the durable record the pattern's history is reconstructed from) and replay (the log is the source of truth and current state is a projection); most patterns take both. The invariant numbers are a frozen contract surface: Undo History, Audit Trail, Compensable Workflow and Reserve from Pool cite them wholesale, so adding one is forward-compatible and renumbering one re-passes every composition that cites it (Composition note 4). That a writer must not renumber is the grammar's rule and stays there (`GRACE-lang.md` Hard invariant 26); what this note owns is the local fact that these numbers are cited from outside. Landed compositions over this atom: [Audit Trail](../compositions/audit-trail.md). Forthcoming: Undo History, Activity Feed, Event-Sourced Reservation.

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the log (also: a log instance, a fresh log instance); the host; the transition; a composing pattern (also: a pattern, a writer); a business caller; a caller; a consumer; an implementation (also: a durable implementation); the deployment; the store; an event; a read; an append.

Terms › `records`: `event` — one recorded fact, carrying `event_id`, `sequence_number`, `recorded_at` and `data`; the log carries `log_name` and `next_sequence_number`.

Terms › `record verbs`: identify, allocate, supply, reuse, reassign, compare, order, own, hold, carry, begin, raise, preserve, offer, write, stamp, answer, accept, refuse, read, serialize, remain, remove, change, share, stand, fall, land, prune, detect, record, index, collapse, push, append, specify, compose, declare, consume, take, cite, renumber, add, erase, match.

Terms › `value sets`: append answers = event_id | rejected(invalid-payload | storage-failure). read answers = events | rejected(invalid-query). `event field` = event_id | sequence_number | recorded_at | data.

Terms › `bounds`: `payload cap` (the per-instance bound on data's size).

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-11); `landed` — written by a successful append.

Terms › `terms`: `durability mechanism`, `event_id`, `seam`, `transition`, `business caller`, `event`, `sequence_number`, `recorded_at`, `data`, `log_name`, `next_sequence_number`, `landed`, `event field`, `query`, `payload cap`.

#### Event Log

The named append-only sequence this atom defines: anything appended stays, in append order, unchanged, for the lifetime of the instance. It is the substrate audit trails, undo histories, activity feeds, and event-sourced systems compose on top of. Multiple instances coexist; this card describes one.

Kind: Type

#### Event

A single recorded fact in an [Event Log] — one entry in the sequence, fixed in place once appended. It carries its [Event Id], [Sequence Number], [Recorded At], and [Data]; nothing about it changes after [Append].

Kind: Type

#### Append

The behavior a composing pattern invokes to record a new [Event] at the tail of the log. It allocates the next [Sequence Number], stamps [Recorded At], and returns the [Event Id]. It is the only way data enters the log.

Kind: Operation

#### Read

The behavior a composing pattern invokes to retrieve events matching a [Query], returned in [Sequence Number] order. It only reads; the log is unchanged.

Kind: Operation

#### Event Id

The opaque, immutable identity of an [Event], allocated by the host at the I/O seam on [Append], never reused. It supports equality but carries no ordering — ordering is [Sequence Number]'s job.

Kind:     Field
Field of: Event
Projects: event_id

#### Sequence Number

The strictly increasing integer assigned to each [Event] at [Append]. It fixes the [Event]'s place in the total order and is the authoritative basis for ordering — kept separate from [Recorded At] on purpose, because a clock can drift but the sequence never does.

Kind:     Field
Field of: Event
Projects: sequence_number

#### Recorded At

The wall-time at which an [Event] was appended — an annotation of when, not the basis of order. Stamped from the host-injected clock on [Append]; best-effort monotonic, with [Sequence Number] authoritative if the clock misbehaves.

Kind:     Field
Field of: Event
Projects: recorded_at

#### Data

The opaque payload a composing pattern supplies on [Append] and the [Event] then carries. The Event Log stores and returns it verbatim and never interprets it.

Kind:     Field
Field of: Event
Projects: data

#### Log Name

The identifier that distinguishes one [Event Log] instance from the others co-existing in a system (one per audited subsystem, one per user history, and so on).

Kind:     Field
Field of: Event Log
Projects: name

#### Next Sequence Number

The [Sequence Number] the next appended [Event] will receive. It begins at 1 for a fresh instance and increments on each [Append]; durable implementations preserve it across restarts, or sequence-number monotonicity breaks over the instance's lifetime.

Kind:     Field
Field of: Event Log
Projects: next_sequence_number

#### Query

The selection a caller passes to [Read] — a sequence-number range, a wall-time range, a payload predicate, or a combination. Its exact shape is implementation policy; the only requirement is that a valid [Query] returns events in [Sequence Number] order.

Kind:         Parameter
Parameter of: Read
Projects:     query

#### Invalid Payload

The refusal [Append] returns when the supplied [Data] violates the configured payload constraints (for example, exceeding the size cap). The [Event] does not land.

Kind:      Member
Member of: the Append rejection
Role:      Outcome
Projects:  invalid-payload

#### Invalid Query

The refusal [Read] returns when the [Query] is malformed — an invalid range, an unparseable predicate. No events are returned.

Kind:      Member
Member of: the Read rejection
Role:      Outcome
Projects:  invalid-query

#### Storage Failure

The refusal [Append] returns when the underlying store write fails after all preconditions pass. The caller must treat it as definitive — the [Event] did not land — though a [Sequence Number] may have been consumed (see Edge cases).

Kind:      Member
Member of: the Append rejection
Role:      Outcome
Projects:  storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Event Log]: #event-log
[Event]: #event
[Append]: #append
[Read]: #read
[Event Id]: #event-id
[Sequence Number]: #sequence-number
[Recorded At]: #recorded-at
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

`grounded on Final Critique 4 — 2026-06-18` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-06-18
formal: verified — event-log.tla + 1 twin, 2026-06-03
last gate: 2026-06-18 — Final Critique 4, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/event-log.md`.

- **2026-09-11 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, rationale under `WHY:`, terms declared where they are used, the invariant numbers frozen exactly as the compositions cite them, Non-goals and Edge cases as two sections, the case table kept beside the rules. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail and Recoverable Invocation cite this atom's Invariants 1, 2, 3, 5 and 7, and a rewrite that moved a number would break those citations silently (`tools/grace/cites.py --into event-log`).

NOTE: End of Event Log.
