---
title: Legal Hold
id: 44
audience: common
---

# Legal Hold

<details open markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Legal Hold records a formal instruction to keep one record intact, overriding any normal deletion schedule, until the legal matter behind it ends. When a lawsuit is expected, a regulator opens an investigation, or a team must freeze evidence, someone places a hold that records who placed it, on which record, why and when, and, where one exists, the legal matter it belongs to. A hold stays in effect until someone releases it, recording who released it, why and when; a released hold can never be put back in effect, and nothing recorded about the placing or the releasing can be changed afterward, so the whole history of an obligation can be checked later from the hold records. Several holds can cover one record at once: a record wanted by both an internal investigation and a government inquiry carries two holds, and releasing one leaves the other in force. The pattern does not stop a deletion itself; it records that the obligation exists, and the system that deletes records must check for holds still in effect first. This is the mechanism behind managing the holds a lawsuit sets off, keeping the records of a data breach while it is investigated, and any setting where destroying a record during an active legal obligation exposes the organization to penalties.

<details markdown="block">
<summary>WHY</summary>

When litigation is filed or reasonably anticipated, the duty to preserve arrives before anyone knows what will matter, and it overrides every retention schedule the organization has. Destroying a held record is spoliation — sanctions, an adverse inference (the jury told it may presume the destroyed record was unfavorable), sometimes the case. So the obligation itself has to be a record: what is held, who decided, why, under which matter, from when, and — when it ends — who lifted it and on what grounds. That record is this atom. It does not stop a purge; it documents an obligation a composing pattern enforces at the purge surface. It does not know what a case is. And it never merges two holds over one record, because two authorities demanding preservation of one document is two obligations, each ending on its own day.

</details>

## What it keeps

### The holds

```
Identity 1: The atom MUST identify a hold by the hold id.
Identity 2: The host MUST allocate a hold id at the atom's seam.
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it: the host injects the hold id at the seam, and the transition allocates none.
Identity 4: The atom MUST NOT reuse a hold id within one database instance.
Identity 5: The atom MUST NOT reassign a hold id.
Identity 7: The atom MUST NOT identify a hold by the record reference.
Identity 8: Two holds over one record MUST carry two hold ids.
```

Term hold: one recorded preservation obligation over one record — a [Hold]; the record this atom writes.

Term hold id: the opaque value naming one hold — a [Hold Id]; not blank.

Term record reference: the opaque reference naming what is preserved — a [Record Reference]; the host owns whether the record exists.

```
State 2: EVERY hold MUST carry hold id, record reference, placing actor, hold reason, placement instant, entry instant and state.
State 3: A hold MAY carry case reference.
State 4: A released hold MUST carry releasing actor, release reason and release instant.
State 5: An active hold MUST NOT carry a release field.
State 8: The atom MUST NOT hold an aggregate for a record.
```

Term hold state: active | released — the obligation in effect, or documented as ended.

Term placing actor: the opaque reference naming who placed the hold — a [Placing Actor]; the attribution anchor for the preservation decision.

Term hold reason: the narrative ground the hold was placed on — a [Hold Reason].

Term placement instant: the instant the obligation was recorded — a [Placement Instant].

Term entry instant: the instant the atom stamped when it recorded the hold, from the injected now — an [Entry Instant]; no caller supplies it, and unlike the placement instant it is never a claim.

Term case reference: the opaque reference naming the matter the hold sits under — a [Case Reference]; absent where no formal matter exists yet.

Term releasing actor: the opaque reference naming who ended the obligation — a [Releasing Actor].

Term release reason: the ground the obligation ended on — a [Release Reason].

Term release instant: the instant the obligation was documented as ended — a [Release Instant].

Term release field: releasing actor | release reason | release instant — every field a release records.

#### Hold

The record this atom defines: one preservation obligation over one record, carrying its [Hold Id], [Record Reference], [Placing Actor], [Hold Reason], [Placement Instant], [Entry Instant], optional [Case Reference], [State] and, once released, [Releasing Actor], [Release Reason] and [Release Instant]. [Place] produces it and [Release] ends it; nothing recorded about its placing or its releasing changes afterward.

Kind: Type

#### Hold Id

The opaque, immutable, system-generated identity of a hold, assigned on [Place], never reused or reassigned within the database instance. A non-empty string. The record, actor, reason, and timestamps are properties of the hold, not its identity.

Kind:       Field
Field of:   Hold
Projection: hold_id

#### Record Reference

The opaque reference to the record being held. Set on [Place], immutable, never validated against any storage layer. Multiple holds may name the same [Record Reference]; each is an independent hold.

Kind:       Field
Field of:   Hold
Projection: record_ref

#### Placing Actor

The opaque reference to the actor placing the hold — the attribution anchor for the preservation decision. Set on [Place], immutable; empty or whitespace-only is rejected (Invariant 7).

Kind:       Field
Field of:   Hold
Projection: placed_by

#### Hold Reason

The required, non-empty narrative for the hold — written from the [Reason] parameter at [Place]. Set on [Place], immutable (Invariants 1 and 7). Carries the proportionality/scope explanation a court expects.

Kind:       Field
Field of:   Hold
Projection: hold_reason

#### Placement Instant

The instant the placer claims the obligation began — a supplied instant (Term supplied instant), or now where the call leaves it blank (Execution Contract Logic confinement 12); must not be future. Set on [Place], immutable. The lower bound for [Release Instant] (Invariant 6) and the ordering key for [Read].

Kind:       Field
Field of:   Hold
Projection: placed_at

#### Entry Instant

The instant the atom stamped when it recorded the hold, from the injected now (Execution Contract Logic confinement 11). Set on [Place], immutable; no caller supplies it. A composing pattern ages and orders holds by it, where the [Placement Instant] is the placer's claim; [Read] itself orders by the [Placement Instant] (Operation 24).

Kind:       Field
Field of:   Hold
Projection: entered_at

#### Case Reference

The optional opaque reference to the legal matter, investigation, or audit. Set on [Place] if supplied not blank (then immutable); a blank one is its absence, which is valid (Execution Contract Input 4). A [Case Reference] filter excludes holds without one (Execution Contract Query 3).

Kind:       Field
Field of:   Hold
Projection: case_ref

#### State

The hold's lifecycle state — [Active] or [Released]. Set to [Active] on [Place]; transitions once to [Released] via [Release]. Every hold is in exactly one state (Invariant 2).

Kind:       Field
Field of:   Hold
Projection: state

#### Releasing Actor

The opaque reference to the actor releasing the hold. Set at [Release], immutable; present on [Released] holds only. Non-null required (Invariant 5).

Kind:       Field
Field of:   Hold
Projection: released_by

#### Release Reason

The required, non-empty reason for the release — written from the [Reason] parameter at [Release]. Set at [Release], immutable; present on [Released] holds only (Invariant 5).

Kind:       Field
Field of:   Hold
Projection: release_reason

#### Release Instant

The instant the releaser claims the obligation ended — a supplied instant (Term supplied instant), or now where the call leaves it blank (Execution Contract Logic confinement 12); must not be future and must not precede [Placement Instant] (Invariant 6). Set at [Release], immutable; present on [Released] holds only.

Kind:       Field
Field of:   Hold
Projection: released_at

#### Database Instance

The named database one set of holds lives in: every hold stands under exactly one (Instance 1), no call reaches across two (Instance 3), and a [Database Name] identifies it. A deployment runs one per organization, jurisdiction or business unit.

Kind: Type

#### Database Name

The identifier of the database instance a hold belongs to. Multiple instances coexist; [Hold Id]s are unique within an instance, while [Record Reference] is host-scoped. No action accepts it as a parameter — instance selection is handled at the deployment-routing layer.

Kind:       Field
Field of:   Database Instance
Projection: store_name

#### Active

The non-terminal state of a hold whose preservation obligation is in effect. A composition wiring this atom to a purge surface treats an [Active] hold as blocking purge (Composition note 10). May be released or read.

Kind:       Member
Member of:  the hold state
Role:       Outcome
Projection: active

#### Released

The terminal state of a hold whose preservation obligation has ended. Carries [Releasing Actor], [Release Reason], and [Release Instant]; retained as audit evidence, no further transition (Invariant 3).

Kind:       Member
Member of:  the hold state
Role:       Outcome
Projection: released

### Database instance model

```
Instance 1: The atom MUST hold every hold under EXACTLY ONE database instance.
Instance 2: Two holds in one database instance MUST NOT share a hold id.
Instance 3: The atom MUST NOT reach across database instances.
Instance 4: The deployment MUST route a call to one database instance.
Instance 5: [Read] MUST answer the database name the read was routed to.
Instance 6: A composing pattern MUST match the answered database name against the record's own database instance.
Instance 7: IF the answered database name DOES NOT EQUAL the database name of the record's database instance THEN a composing pattern MUST NOT read the answer as deciding whether the record is held.
Instance 8: The deployment MUST route a call of [Place] to the record's own database instance.
Instance 9: The deployment MUST route a call of [Release] to the database instance the host allocated the hold id for.
Instance 10: IF the answered database name DOES NOT EQUAL the database name of the record's database instance THEN a composing pattern MUST NOT purge the record (Composition note 2).
Instance 11: The deployment MUST NOT change a record's database instance.
```

Term database instance: one named database — a [Database Instance]; a [Database Name] identifies it, and a deployment runs one per organization, jurisdiction or business unit.

Term database name: the identifier naming one database instance — a [Database Name]; deployment routing, never an input, and the one value [Read] answers beside the holds (Instance 5).

## What people do

### Every action

```
Operation 38: The business caller MAY supply placement instant.
Operation 39: The business caller MAY supply release instant.
```

NOTE: watch the blank id (Operation 13).

NOTE: watch the cap's refusal (Operation 13).

Term admitted axis: hold id | record reference | placing actor | case reference | hold state | a placement instant range | a release instant range — the filter axes [Read] accepts, and no others.

Term resolved release instant: the release instant the release records — the caller's value, as Execution Contract Logic confinement 12 resolves it.

Term supplied instant: a placement instant or release instant the business caller supplies — a point in time, as GRACE-lang Term instant declares it, written with the offset from UTC (Coordinated Universal Time) that places it, as `2026-02-14T09:30:00Z`; a bare date, and a date and time with no offset, name no one point in time, so neither is an instant and the call is malformed (Execution Contract Input 3).

Term held at an instant: placement instant at or before the instant, and either the hold state EQUALS active or the instant PRECEDES the hold's release instant, so a hold released at its own placement instant is held at no instant — the reconstruction an auditor runs over the stored fields of the committed version a read answered from, never over the hold state alone; a purge's check reads no instant, and Composition note 10 decides the check by the hold state, in commit order.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the hold records |
|---|---|---|---|
| either write | database refuses | [Storage Failure] | none — a release leaves the hold [Active] (Operation 11, Operation 21, Place persistence 4) |

Where two [Release] rows hold at once, the earlier row answers: the refuses line lists not-known and already-released ahead of invalid-request (Execution Contract Refusal 1), and not-known answers only a hold id that is not blank and does not exceed the string cap (Operation 13).

#### Invalid Request

The refusal [Place] or [Release] returns when request fields fail — an empty/whitespace [Record Reference], [Placing Actor], [Reason], [Releasing Actor], or [Hold Id]; a future [Placement Instant]; a [Release Instant] that is future or before [Placement Instant]; or a string input over the string cap (Execution Contract Input 2).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Storage Failure

The refusal any writing action returns when a durable write fails after preconditions pass. For [Release], the hold remains [Active] (Place persistence 4).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Place

#### Place

The behavior that records a new preservation hold against a record. It assigns a fresh [Hold Id], stamps [Placement Instant], records [Record Reference], [Placing Actor], [Hold Reason], and [Case Reference] (if supplied), and returns the [Hold Id] (or a rejection). The hold enters [Active].

Kind: Operation

```
place(record_ref, placed_by, reason, optional case_ref, optional placed_at)
  answers hold_id
  refuses invalid-request | storage-failure
```

```
Operation 1: [Place] MUST record EXACTLY ONE hold per successful call.
Operation 2: [Place] MUST stand the hold in active.
Operation 3: [Place] MUST answer hold id.
Operation 4: IF record reference EQUALS blank THEN [Place] MUST answer invalid-request.
Operation 5: IF placing actor EQUALS blank THEN [Place] MUST answer invalid-request.
Operation 6: IF hold reason EQUALS blank THEN [Place] MUST answer invalid-request.
Deleted: Operation 7. Execution Contract Input 4 owns it: a blank optional case reference is omitted, and the hold lands carrying none.
Operation 8: IF now PRECEDES a supplied placement instant THEN [Place] MUST answer invalid-request.
Operation 10: [Place] MUST accept a placement instant at or below now.
Operation 11: IF the database refuses the write THEN [Place] MUST answer storage-failure.
Operation 43: [Place] MUST stamp entry instant from the injected now.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the hold records |
|---|---|---|---|
| [Place] | refs and reason present, placement instant not future, database accepts | hold id | one hold lands in [Active], stamped with its entry instant (Operation 1, Operation 2, Operation 43) |
| [Place] | blank record reference, placing actor or reason, or a string input over the string cap, or a supplied placement instant that is not an instant | [Invalid Request] | none (Operation 4 through 6, Execution Contract Input 2, Execution Contract Input 3) |
| [Place] | supplied placement instant in the future | [Invalid Request] | none (Operation 8) |
| [Place] | supplied placement instant in the past, or equal to now | hold id | one hold lands, recorded as supplied (Operation 10) |

### Release

#### Release

The behavior that documents the end of a preservation obligation, transitioning an [Active] hold to [Released] and recording [Releasing Actor], [Release Reason], and [Release Instant]. A [Released] hold cannot be released again ([Already Released]); releasing one hold never affects another on the same record (Invariant 4).

Kind: Operation

```
release(hold_id, released_by, reason, optional released_at)
  answers released
  refuses not-known | already-released | invalid-request | storage-failure
```

```
Operation 12: IF hold id EQUALS blank THEN [Release] MUST answer invalid-request.
Operation 13: IF hold id DOES NOT EQUAL blank AND the hold id DOES NOT EXCEED the string cap AND no hold EXISTS for the hold id THEN [Release] MUST answer not-known.
Operation 14: IF the hold state EQUALS released THEN [Release] MUST answer already-released.
Operation 15: IF releasing actor EQUALS blank THEN [Release] MUST answer invalid-request.
Operation 16: IF release reason EQUALS blank THEN [Release] MUST answer invalid-request.
Operation 17: IF the resolved release instant PRECEDES the hold's placement instant THEN [Release] MUST answer invalid-request.
Operation 18: IF now PRECEDES a supplied release instant THEN [Release] MUST answer invalid-request.
Operation 19: [Release] MUST stand the hold in released.
Operation 21: IF the database refuses the write THEN [Release] MUST answer storage-failure.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the hold records |
|---|---|---|---|
| [Release] | hold active, attribution present, time in range | released | [Active] → [Released], release fields stamped; the hold's id, record reference, placing actor, reason, placement instant, entry instant and case reference stand, and no other hold's state changes (Operation 19, State 4, Invariant 1.1, Invariant 4.1) |
| [Release] | blank hold id | [Invalid Request] | none — the caller passed nothing, not a missing hold (Operation 12) |
| [Release] | id names nothing | [Not Known] | none (Operation 13) |
| [Release] | hold already released | [Already Released] | none; the release fields stand as stamped (Operation 14, Invariant 1.2) |
| [Release] | blank releasing actor or release reason, or a string input over the string cap, or a supplied release instant that is not an instant | [Invalid Request] | none (Operation 15, Operation 16, Execution Contract Input 2, Execution Contract Input 3) |
| [Release] | resolved release instant before placement instant, or supplied one in the future | [Invalid Request] | none (Operation 17, Operation 18) |

#### Not Known

The refusal [Release] returns when the named [Hold Id], within the string cap, references no hold in this database instance — a lookup miss (a common cause is cross-instance referencing).

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

### Read

#### Read

The read-only behavior that returns the [Holds] matching a [Query] together with the [Database Name] of the instance the read was routed to, ordered by [Placement Instant] ascending then [Hold Id] ascending. It changes nothing. Filters by [Hold Id], [Record Reference], [Placing Actor], [Case Reference], [State], or time range are combinable; the query `{record_ref: X, state: active}` is the operational "is this record held?" check.

Kind: Operation

```
read(query)
  answers holds(store_name)
  refuses invalid-query
```

```
Operation 23: [Read] MUST answer the holds the query matches.
Operation 24: [Read] MUST order the answer by placement instant, rising.
Operation 25: [Read] MUST order two holds sharing a placement instant by hold id, rising (Execution Contract Logic confinement 10).
Operation 26: [Read] MUST accept a filter on EVERY admitted axis.
Operation 26a: [Read] MUST accept a query combining admitted axes.
Operation 27: IF the query carries an axis outside the admitted axes THEN [Read] MUST answer invalid-query.
Operation 28: IF a filter value EQUALS blank THEN [Read] MUST answer invalid-query.
Deleted: Operation 29. Execution Contract Query 1 and Operation 46 own it: a hold state filter carrying no member of the hold state set is malformed, and the read answers the query invalid-query.
Operation 30: IF a range's end PRECEDES the range's start THEN [Read] MUST answer invalid-query.
Operation 31: [Read] MUST answer an empty sequence for a well-formed query matching nothing.
Deleted: Operation 44. Execution Contract Query 5 and Operation 46 own it: a filter value over the string cap is malformed, and the read answers the query invalid-query.
Deleted: Operation 45. Execution Contract Query 1 and Operation 46 own it: a range missing the range's start or the range's end is malformed, and the read answers the query invalid-query.
Operation 46: IF the query is malformed THEN [Read] MUST answer invalid-query (Execution Contract Query 1, Execution Contract Query 5).
Operation 34: [Read] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the hold records |
|---|---|---|---|
| [Read] | well-formed query | the matching holds, ordered | none — the call reads (Operation 23, Operation 34) |
| [Read] | unknown axis, blank value, value over the string cap, bad state, inverted range or range missing an end | [Invalid Query] | none — rejected rather than silently ignored (Operation 27, Operation 28, Operation 30, Operation 46) |
| [Read] | well-formed query matching nothing | empty sequence | none (Operation 31) |

#### Holds

The outcome [Read] returns: the holds the query matches, in order, with the [Database Name] of the instance the read was routed to.

Kind:       Member
Member of:  the Read outcome
Role:       Outcome
Projection: holds

#### Query

The selection [Read] consumes — a filter over [Hold Id], [Record Reference], [Placing Actor], [Case Reference], [State], and/or a time range on [Placement Instant] or [Release Instant]. Supplied per call, not stored; a malformed one is rejected [Invalid Query].

Kind:         Parameter
Parameter of: Read
Projection:   query

#### Invalid Query

The refusal [Read] returns when query parameters are malformed — a null/empty/whitespace filter value, a [State] value outside {[Active], [Released]}, a time range with end before start or missing an end, a filter value over the string cap (Execution Contract Query 1, Query 5), or an unrecognized filter key.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

## What is and what should never be (Invariants)

- **Invariant 1 — Hold immutability.**
  ```
  Invariant 1.1: A recorded hold's hold id, record reference, placing actor, hold reason, placement instant, entry instant and case reference MUST NOT change.
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
  Invariant 4.3: An auditor MUST read a record as held at an instant ONLY IF a hold over the record is held at the instant in the committed version of the hold the read answered from (Term held at an instant, Execution Contract Database 5).
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
  Invariant 7.4: EVERY hold MUST carry entry instant.
  ```
- **Invariant 8 — Hold record durability.**
  ```
  Invariant 8.1: The atom MUST NOT delete a hold record.
  Invariant 8.2: The hold set MUST NOT shrink.
  ```

Immutability and durability give the *preservation record* property — the full arc of an obligation, from recognition to lifting, provable. Independence gives the property a multi-authority matter needs: one record, many obligations, each ending on its own day.

## When something happens

### Concurrency

```
Concurrency 3: Two placements over one record MUST record two holds.
```

### Back-dating a placement or a release

```
Backdating 3: The deployment MUST own the evidentiary weight of a back-dated placement instant.
Backdating 4: The deployment MUST own the evidentiary weight of a back-dated release instant.
```

### Place persistence failure

```
Place persistence 1: A caller MUST read storage-failure from [Place] as the call leaving no hold.
Place persistence 2: A caller MUST retry a place that answered storage-failure.
Place persistence 3: A high-assurance deployment MUST raise an alert on storage-failure from [Place].
Place persistence 4: A caller MUST NOT read storage-failure from [Release] as the obligation standing ended.
```

### The aggregate question

```
Aggregate 1: A composing pattern MUST read a record's active holds to answer whether the record is held.
Aggregate 2: The atom MUST NOT carry a held flag on a record.
```

### What undoes a write

No writing action of this atom is undone: Invariant 1.1, Invariant 1.2, Invariant 3.1, Invariant 3.2 and Invariant 8.1 keep what [Place] and [Release] write, and an obligation that ends is documented by [Release] while a new one is a fresh [Place] (Execution Contract Undo 4).

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 7 and Execution Contract Logic confinement 11.
Capability requirement 4: The deployment MUST supply the hold records PER Execution Contract Database 1 through 4, Execution Contract Refusal 1, Execution Contract Query 1 through 4 and Execution Contract Conformance 9.
Capability requirement 5: The deployment MAY declare the string cap PER Execution Contract Input 2.
```

#### Reason

The required, non-empty reason string [Place] and [Release] consume — written into [Hold Reason] or [Release Reason] respectively. Not stored under this name; an empty or whitespace-only value is rejected [Invalid Request].

Kind:         Parameter
Parameter of: Place and Release
Projection:   reason

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the hold id here.

Term transition: the atom's evaluation of one call against the hold records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it — placement instant and release instant are the caller's claims about when an obligation began and ended, judged against now and stored as claims (Operation 8, Operation 10, Operation 17, Operation 18, Operation 38 and Operation 39).

Term string cap: the bound on a string input's length in Unicode code points; 1,024 code points where a deployment declares none.

Term query: what a read asks for — a [Query]; any combination of the admitted axes.

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice.

Term need key: key actor id; pairs holds.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key hold id; carried by holds; calls Read.

## Left to others

```
Non-goal 1: The atom MUST NOT block a purge.
Deleted: Non-goal 2. Non-goal 1 owns it: the atom enforces no hold against a purge, and which pattern does is the app's choice.
Non-goal 3: The atom MUST NOT read the record a record reference names.
Non-goal 4: The atom MUST NOT refuse a hold over a destroyed record.
Non-goal 5: The atom MUST NOT deduplicate two holds.
Deleted: Non-goal 6. Non-goal 5 owns it: the atom makes no placement at-most-once, and which pattern does is the app's choice.
Non-goal 7: The atom MUST NOT gate who places a hold.
Deleted: Non-goal 8. Non-goal 7 owns it: the atom gates no placement; the app's permission does.
Non-goal 9: The atom MUST NOT hold a matter's life cycle.
Non-goal 10: The atom MUST NOT release every hold over a record in one call.
Non-goal 11: The atom MUST NOT detect tampering with a hold record.
Deleted: Non-goal 12. Non-goal 11 owns it: the atom seals no hold record, and which pattern makes the records tamper-evident is the app's choice.
Non-goal 13: The atom MUST NOT place one hold over two records.
Non-goal 14: The atom MUST NOT import a retention policy.
Non-goal 15: The atom MUST NOT purge a hold record.
Non-goal 17: A deployment needing a defensible timeline MUST compose a trusted time-stamping pattern.
```

NOTE: the owners — a retention pattern and a lawful-disposal pattern (Non-goal 1, Non-goal 14); a tamper-evidence pattern (Non-goal 11); a trusted timestamping pattern *(forthcoming)* (Non-goal 17).

Where the atom breaks down: when the preservation duty is defined by a query rather than a record — *everything touching Project Alpha* — which needs a composing pattern to enumerate and place; when the hold must survive the database that holds it, which needs an external anchor; when who may lift a hold is part of the obligation, which is the app's permission's and not a field here.

```
Composition note 2: A composing pattern MUST check a record's active holds at the purge surface.
Composition note 3: A composing pattern MUST own who may place a hold.
Composition note 4: A composing pattern MUST own who may release a hold.
Composition note 5: A composing pattern MUST own a bulk placement.
Composition note 6: A composing pattern MUST own a bulk release.
Composition note 7: A composing pattern MUST commit the check of a record's active holds and the purge of the record together, the check read inside the transaction that writes the purge (Execution Contract Database 1, Execution Contract Database 2).
Composition note 8: A composing pattern MUST pass the placement instant and the release instant a business caller supplies down to [Place] and [Release] unchanged, in EVERY call that Composition note 3 through 6 give the composing pattern.
Composition note 9: A composing pattern MUST read an invalid-request that the atom answers on a supplied instant as no placement and no release, whatever authority the composing pattern granted for the call.
Composition note 10: IF the hold state of a hold over a record EQUALS active in the committed version the check of the record's active holds reads THEN a composing pattern MUST NOT purge the record (Composition note 7, Execution Contract Order 2).
```

NOTE: composing patterns — a lawful-disposal pattern, an audit pattern.

## Example

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

`place(record_ref: "doc-0099", placed_by: "compliance_chen", reason: "   ")` → invalid-request. Whitespace-only reason is treated as empty, as is whitespace-only input wherever a blank is refused (Operation 4 through 6, 12, 15 and 16). No hold is created.

### Rejection path — release with future timestamp

With hold-007 standing [Active], `release("hold-007", released_by: "counsel_kim", reason: "case closed", released_at: "2027-01-01T00:00:00Z")` → invalid-request. A release documented as occurring in the future is not operationally meaningful; the atom records the present obligation, not a future intent.

### Rejection path — place with an instant naming no point in time

`place(record_ref: "doc-0100", placed_by: "counsel_lee", reason: "Hold under matter 2026-0100", placed_at: "2026-02-14T09:30:00")` → invalid-request. The value carries no offset from UTC, so it names no one point in time and is not an instant (Term supplied instant); a bare date such as `2026-02-14` is refused the same way, and no hold is created.

### Regulated adversarial scenarios

#### Regulator audit — dual regulatory investigation

A financial institution is simultaneously under a DOJ (US Department of Justice) criminal investigation and an SEC (US Securities and Exchange Commission — the federal regulator of securities markets) civil enforcement action. Both issue preservation demands covering the same set of trading records. The compliance team places holds under both matters:

- `hold-doj-001` through `hold-doj-240`: `case_ref: "doj-crim-2026-0011"`
- `hold-sec-001` through `hold-sec-240`: `case_ref: "sec-enf-2026-0087"`

The DOJ investigation closes first. The compliance team releases all `hold-doj-*` holds. Query `read({record_ref: "trade-record-0042", state: active})` returns `hold-sec-042` — the SEC hold remains [Active]. Invariant 4 guarantees that releasing the DOJ holds had no effect on the SEC holds. The institution correctly continues to preserve the records under SEC obligation. A regulator's auditor reading the hold records for the trading records sees the full picture: two independent regulatory demands, one resolved, one active, no record destroyed while any [Active] hold covered it.

#### Spoliation challenge — federal litigation

Opposing counsel in federal litigation argues that the defendant destroyed documents after the duty to preserve was triggered under FRCP (Federal Rules of Civil Procedure — the rules governing civil lawsuits in US federal courts) Rule 37(e). Defendant's counsel queries `read({record_ref: "doc-contract-077"})` for all holds ever placed on the disputed document. The query returns the hold placed on the record, with `placed_at: 2026-02-14T09:30:00Z` — the date the placer claims the preservation obligation was recognized. The opposing party claims the document was destroyed on `2026-02-10`. The hold record shows [Placement Instant] postdating the destruction. If a corresponding purge record from the retention pattern shows `purged_at: 2026-02-10` and no [Active] hold existed at that time, the records faithfully document the chronology — the hold was placed after the purge. If the document was never purged and remains in the database, the hold records confirm ongoing preservation. The entry instant the system stamped shows when the hold was recorded, so a back-dated placement instant cannot pass for the date the hold was entered. Either way, the court has the complete record; the atom does not manufacture a defense but it does not hide the facts either.

#### Breach investigation — HHS Office for Civil Rights HIPAA investigation

HHS (US Department of Health and Human Services — the federal agency that enforces HIPAA) Office for Civil Rights (OCR) opens an investigation into a reported breach of PHI (Protected Health Information — individually identifiable health data covered by HIPAA, the Health Insurance Portability and Accountability Act, the US federal law governing healthcare data privacy). It issues a preservation demand to the covered entity for all records relating to the incident. The compliance team calls [Place] for each record in scope; each placement carries `case_ref: "ocr-hipaa-inv-2026-0334"`. Two months later, OCR requests the preservation record: query `read({case_ref: "ocr-hipaa-inv-2026-0334", state: active})` returns every [Active] hold placed under this investigation. Every hold carries [Placing Actor] and [Hold Reason] strings, neither blank, and a [Placement Instant] timestamp that is set — immutable by Invariants 1 and 7. The investigator also reads each hold's entry instant, which the system stamped and no placer supplied, and so reads when each hold was recorded whatever placement instant the placer claimed. OCR confirms that preservation was initiated and that each hold is still [Active]. The covered entity has a documentable, provable preservation response.

---

## Source

- **Federal Rules of Civil Procedure Rule 37(e)** — the primary U.S. federal standard for electronic discovery preservation. A party must take reasonable steps to preserve ESI (Electronically Stored Information — digital records subject to legal discovery) once litigation is reasonably anticipated; failure to preserve when an [Active] hold should have been in place exposes the party to sanctions including adverse inference instructions. The [Placement Instant] timestamp and [Hold Reason] field are the record of when and why the preservation obligation was recognized.
- **Federal Rules of Civil Procedure Rule 26(b)** — proportionality doctrine for discovery preservation; not all records must be held, only those reasonably expected to be relevant. [Hold Reason] and [Case Reference] are the scoping fields that document proportionality.
- **Sedona Conference Principles (3rd ed.)** — the leading authoritative guidance on electronic discovery preservation obligations. Principle 5: a party is not required to preserve every document; preservation must be proportionate. Principle 6: a party should consider adoption of a litigation hold policy. The [Hold Reason] field is the policy documentation surface.
- **SOX (Sarbanes-Oxley Act) section 802 (18 U.S.C. — the United States Code — section 1519)** — criminal obstruction-of-justice provision for destruction of documents subject to federal investigation or proceedings. An [Active] Legal Hold covering the relevant records is the structural defense against section 802 exposure.
- **SEC Rule 17a-4(f)** — requires broker-dealers to preserve records in non-rewriteable, non-erasable format, accessible to regulators on demand. Legal Hold composes with a tamper-evidence pattern to meet this standard; the hold record itself is a regulated record under 17a-4.
- **HIPAA section 164.530(j)** — documentation retention requirements; HHS investigations trigger preservation obligations over the PHI and administrative records involved. Legal Hold is the preservation mechanism.
- **HIPAA Breach Notification Rule (45 CFR (Code of Federal Regulations) section 164.400–414)** — breach investigations generate preservation obligations over the records relating to the incident. [Case Reference] references the OCR investigation case identifier.
- **GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Article 17(3)(e)** — erasure right (right to be forgotten) does not apply when processing is necessary for the establishment, exercise, or defence of legal claims. An [Active] Legal Hold is the operational record that establishes the legal-claim exception to erasure. A data-rights pattern's `retained(legal-hold)` disposition is the provable form of this exception.
- **21 CFR Part 11** — electronic records and signatures in FDA-regulated (US Food and Drug Administration) contexts. Preservation holds on regulated records (clinical trial data, manufacturing batch records) must be attributable and non-alterable. Composes with an attestation pattern and a tamper-evidence pattern.
- **E-SIGN Act (Electronic Signatures in Global and National Commerce Act) / UETA (Uniform Electronic Transactions Act)** — electronic hold records carry the same legal force as paper hold notices where these acts apply.
- **ISO 15489-1 (Records management)** — the International Organization for Standardization's standard for records-management practice; hold is the operational mechanism for Section 9.7 (suspension of disposition). The two-state ([Active]/[Released]) model maps directly to ISO 15489's hold lifecycle.

---

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the hold records' stored fields, with their committed versions (Execution Contract Generation acceptance 1).

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY hold id [Place] answered in the database (Invariant 8.1, Invariant 8.2).
Check 2.1: An auditor MUST find placing actor and hold reason not blank on EVERY hold (Invariant 7.1, Invariant 7.2).
Check 2.2: An auditor MUST find placement instant set on EVERY hold (Invariant 7.3).
Check 2.3: An auditor MUST find record reference not blank on EVERY hold (Operation 4).
Check 2.4: An auditor MUST find hold id not blank on EVERY hold (Identity 2).
Check 2.5: An auditor MUST find entry instant set on EVERY hold (Invariant 7.4).
Check 2.6: An auditor MUST find no two holds of one database instance sharing a hold id in any committed version of the hold set (Identity 4, Instance 2, Execution Contract Database 8).
Check 3.1: An auditor MUST find releasing actor and release reason not blank on EVERY released hold (Invariant 5.1, Invariant 5.2).
Check 3.2: An auditor MUST find release instant set on EVERY released hold (Invariant 5.3).
Check 3.3: An auditor MUST find no released hold whose release instant PRECEDES the hold's placement instant (Invariant 6.1).
Check 4.1: IF a hold over a record was released while a second hold over the record stood active THEN an auditor MUST find the second hold active in the committed version the release wrote (Invariant 4.1, Execution Contract Generation acceptance 1).
Check 5.1: IF a hold state EQUALS released in one committed version THEN an auditor MUST find the hold state EQUALS released in every later committed version (Invariant 3.1, Execution Contract Generation acceptance 1).
Check 5.2: IF a call of [Release] named a released hold and answered already-released THEN an auditor MUST find the hold's committed versions unchanged by that call (Invariant 1.1, Invariant 1.2, Execution Contract Generation acceptance 1).
Check 6.1: An auditor MUST find every hold id of one committed version of the hold set in every later committed version (Invariant 8.2, Execution Contract Generation acceptance 1).
Check 6.2: An auditor MUST find EVERY field Invariant 1.1 names equal in every committed version of the hold (Invariant 1.1, Execution Contract Generation acceptance 1).
Check 6.3: IF a hold state EQUALS active in one committed version AND the hold state EQUALS released in a later one THEN an auditor MUST find each committed version of the hold standing in EXACTLY ONE OF active, released (Invariant 2.1, Execution Contract Generation acceptance 1).
Check 6.4: An auditor MUST find EVERY release field of a released hold equal in every later committed version of the hold (Invariant 1.2, Execution Contract Generation acceptance 1).
```

#### External checks

```
External check 1: An auditor MUST read whether a held record was purged from the composing pattern's purge records (Non-goal 1, Composition note 2, Composition note 10).
External check 2: An auditor MUST read who was permitted to place a hold from the app's permission (Non-goal 7).
External check 3: An auditor MUST read a hold record's integrity from the composing tamper-evidence pattern's seals (Non-goal 11).
External check 4: An auditor MUST read the matter a case reference names from the deployment's case-management system (Non-goal 9).
External check 6: An auditor MUST read the evidentiary weight of a back-dated supplied instant from the deployment's own records (Backdating 3, Backdating 4, Non-goal 17).
```

NOTE: EVERY check names the rule the check tests. The hold records answer *what was preserved, by whom, and for how long*; whether the preservation was honoured at the purge surface is the composing pattern's record, because this atom deliberately enforces nothing (Non-goal 1).

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the transition; the deployment; a composing pattern (also: a pattern); a business caller; a caller; an auditor; the database; a hold; a release; a placement; a query.

Term records: hold — one preservation obligation, carrying hold id, record reference, placing actor, hold reason, placement instant, entry instant, a hold state and, where they exist, case reference, releasing actor, release reason and release instant.

Term record verbs: supply, judge, purge, retry, raise, match, share, hold, reach, route, identify, allocate, reuse, reassign, carry, stand, offer, delete, record, answer, accept, read, order, write, change, rest, shrink, stamp, commit, pass, find, block, refuse, deduplicate, gate, release, detect, place, import, own, check, compose, declare, precede, fall.

Term value sets: hold state = active | released.

Term bounds: string cap (the bound on a string input's length in Unicode code points, 1,024 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: database instance, database name, hold, hold id, record reference, seam, transition, business caller, now, hold state, placing actor, hold reason, placement instant, entry instant, case reference, releasing actor, release reason, release instant, release field, query, resolved release instant, supplied instant, admitted axis, held at an instant, string cap.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Place]: #place
[Release]: #release
[Read]: #read
[Hold]: #hold
[Holds]: #holds
[Database Instance]: #database-instance
[Hold Id]: #hold-id
[Record Reference]: #record-reference
[Placing Actor]: #placing-actor
[Hold Reason]: #hold-reason
[Placement Instant]: #placement-instant
[Entry Instant]: #entry-instant
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

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — legal-hold.tla + 4 twins (2026-06-04; 2026-11-21: the entry instant, and Invariant 1.1 and 8.2 checked across steps, Check 6.1 and 6.2 read over committed versions, Invariant 2.1 across steps by construction); legal-hold.als + 19 twins (the static data model, 2026-11-11, the entry instant 2026-11-21: Invariant 1.1, 1.2, 2.1, 3.1, 4.2, 5.1, 5.2, 5.3, 6.1, 7.1, 7.2, 7.3 and 7.4, State 5, Operation 4 and 43 and Instance 2 checked on every hold record an admitted [Place] or [Release] leaves, Invariant 1 and 3.1 read against the versions that built the record, Invariant 4.2 and 6.1 a cross-check with the TLA+ model; nothing testable in Alloy for Invariant 3.2, 4.1, 4.3 and 8: 3.2 names what the signature offers, not a state, and its twin is caught by 3.1; 4.1 and 8 compare two readings, a deleted hold leaving nothing in one state; 4.3 defines a reading over stored fields with no stored aggregate to hold it to); nothing testable in the models for Term supplied instant: the form a supplied instant takes is the wire's (Execution Contract Input 3), and a model's instant is already one point in time; Composition note 7 through 9 and Instance 8 through 10 are the deployment's and the composing patterns' duties, outside the atom's models; model redraw deferred to Lean: legal-hold.als, Operation 7; coverage 2026-11-10 (unit formal: more coverage for the yes votes), 2026-11-11, 2026-11-21
last gate: 2026-11-27 — Final Critique 13, a delta round (diff base e5104028, 111 labels), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 77e6708a — foundational count 2 after the blind second triage, cured, not clean, no sample (Linus held his three questions and raised two refining lines, both refuted; the blind second triage placed his third question foundational, Kind A: Aggregate 1 read a record held on the hold state alone while Invariant 4.3 asked for a placement instant at or before the instant, so under clock skew the deployment owns a composing pattern could read the record held or purge it, cured by Invariant 4.3 binding the auditor's reconstruction and Composition note 10 deciding the purge check by the hold state in commit order; and found one of its own, Kind A: nothing fixed a record's database instance over its life, so a record moved between instances escapes Instance 7 and 10, cured by Instance 11; its two refining lines, Identity 3 restating Execution Contract Logic confinement 3 and Operations 29, 44 and 45 restating Query 1 and Query 5, are cured by tombstones and Operation 46); 2026-11-26 — Final Critique 12, a full round (GRID opencode-go/glm-5.3-flash, EOS opencode-go/minimax-m3, Linus opencode-go/mimo-v2.6-pro; the Claude reader read beside them), frozen at e5104028 — foundational count 3, cured, not clean, no sample; 2026-11-25 — Final Critique 11, a delta round, one reader (Linus Claude Sonnet 5.5; GRID and EOS not run), frozen at c00e24f8 — foundational count 0 after the blind second triage, clean, one sample (the diff base 35745b6a, the reach of the page's seven labels changed or citing a change since Final Critique 10; Linus rated one finding foundational, that Invariant 4.3's second "an instant" is not bound to its first, so a read at a past instant could answer held; the blind second triage, one cold reader on Opus 5.5, placed it refining, Kind A: the atom answers no "held" (Operation 23 answers holds, State 8 and Aggregate 2 hold no record-level reading), so no two builds differ, and the only reader at a past instant is an auditor; five refining and one rhetorical report placed, one refuted on Backdating 3; cured as refining in the round: Invariant 4.3 now binds the instant by the Term, the Term's closing phrase reads over the stored fields as they stand, Instance 7 compares names with a name, External check 6 reads the weight of a back-dated supplied instant from outside the records, and the OCR heading is spelled out; the next round is a delta round on those cures); 2026-11-21 — Final Critique 10, a full round, frozen at 35745b6a — foundational count 0 after the blind second triage, clean, one sample; Grid's one foundational claim (a placement instant equal to now) refuted, since Operation 8 refuses only a future instant, the case table admits one that is not future and a blank one resolves to exactly now (Execution Contract Logic confinement 12), and Linus's five placed refining or refuted (a released hold's storage-failure leaves it active, Place persistence 4; Database 5 binds every deployment and the checks cite Generation acceptance 1); the settle's own refining cures: Operation 10 admits a placement instant at or below now, Instance 7 reads a mismatched answer as deciding nothing, Backdating 4 gives a back-dated release instant its owner, Composition note 1 deleted to Execution Contract Conformance 9, Term held at an instant states its boundary, Non-goal 17's pattern marked forthcoming; 2026-11-02 — Final Critique 9, a delta round, frozen at d1e9f55 — foundational count 0, clean, no sample; 2026-10-24 — Final Critique 8, frozen at c39a73f — foundational count 0, clean, one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./legal-hold.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/legal-hold.md`.

</details>

NOTE: End of Legal Hold.
