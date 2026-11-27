---
title: Observation
id: 48
audience: common
---

# Observation

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Observation records a single measurement about a subject — a vital sign, a lab value, a sensor reading, a financial mark — in a permanent, attributed form that cannot be silently edited.

It answers what an operator or a regulator must be able to ask: what was recorded, who recorded it, and when — and if there were corrections, what they were, who made them, and why.

Errors are never edited away. A correction is recorded as a new observation that supersedes the original, and the original stays in the record marked as amended. An observation logged against the wrong subject or the wrong type is instead retracted — formally withdrawn with a required explanation, the original still kept — and a fresh correct one recorded separately. That keeps the full history of the reasoning recoverable, so a later reviewer can tell a transcription fix apart from a real change in what was being measured.

Each observation is recorded (current), amended (superseded by a correction), or retracted (withdrawn as erroneous); retraction is final, and queries can return just the current observations or the full corrected history.

*Also known as: a reading, a charted measurement, a result record.*

<details markdown="block">
<summary>WHY</summary>

An operator records a measurement about a subject — a blood pressure, a reactor temperature, a closing mark, an assay result — and the record must be trustworthy: what was recorded, who recorded it and when are permanently fixed. Errors are corrected by recording a successor that supersedes the original, and the original does not disappear; it is marked amended. An observation recorded against the wrong subject or under the wrong type is retracted, with the reason documented, rather than edited.

The requirement behind that is universal and recurring wherever a measurement carries consequences: the record must show both what was originally recorded *and* what the correction was, so the history of the reasoning is recoverable. A mutable record system fails it by definition — once someone edits the value, the original is gone and the reason for the edit is invisible. Append-and-supersede preserves both.

The atom is deliberately domain-neutral, and the neutrality is load-bearing rather than incidental. Strip the setting away and what remains is an amendable, attributed, retractable measurement record — equally a clinical vital sign, a laboratory assay, an instrument reading, or a financial mark. Every domain-specific commitment the concept appears to carry turns out to live somewhere else: what a valid value is, the deployment declares; what the measurement means, the reader decides; which vocabulary names the type, a composition maps. A healthcare deployment of this atom is a composition that supplies those three, not a different atom.

Two structural choices carry most of the atom's weight. The first is that a correction inherits its subject and its type *by construction* rather than by validation: [Amend] does not accept either as a parameter, so an amendment cannot silently move an observation to a different subject or a different measurement. Divergence is not caught, it is unrepresentable. An operator who recorded `temperature` meaning `oxygen_saturation` must retract and re-record: those are two different measurements, not one measurement with a typo.

The second is that the atom refuses to validate what it has not been told how to validate. An observation type with no declared value constraint is rejected rather than accepted unchecked, which means a deployment adds a new measurement by first declaring what a valid value for it looks like. The atom never defines what a valid blood pressure is — that is domain knowledge and local — and it never records one it could not check.

The atom imposes no semantics on what a value means. It imposes the structural guarantee that the record is faithful to what was recorded and by whom.

</details>

## What it keeps

### The observations

```
Identity 1: The atom MUST identify an observation by the observation id.
Identity 2: The host MUST allocate an observation id at the seam that no observation in the database instance carries and that DOES NOT EXCEED the string cap (Execution Contract Logic confinement 16).
Identity 4: The atom MUST NOT change an observation id.
Identity 5: Two observations in one database instance MUST NOT share an observation id.
Identity 7: The atom MUST NOT identify an observation by the subject reference.
Identity 8: The atom MUST admit a second observation carrying a recorded subject reference.
Identity 9: A subject reference MUST carry one meaning across EVERY database instance (Execution Contract Logic confinement 13; Composition note 9; Composition note 11).
Identity 10: An observation id MUST carry one meaning within one database instance.
Identity 11: The atom MUST compare a reference byte-exactly.
Identity 12: The atom MUST NOT normalize a reference.
Identity 13: The atom MUST NOT confirm that a subject reference names a known subject.
Identity 14: The atom MUST NOT interpret an observation type.
Identity 15: The atom MUST NOT interpret a unit.
Identity 16: An action MUST NOT accept a database name.
```

NOTE: watch the id's length against the cap (Identity 2).

Term observation: one recorded measurement about one subject — a value, a unit, a type, an observer and an instant; the record this atom holds — an [Observation].

Term observation id: the opaque value naming one observation — an [Observation Id]; host-allocated at the seam.

Term subject reference: the opaque reference naming what the measurement is about — a [Subject Reference]; a property of the observation, never the observation's identity.

Term recording actor: the opaque reference naming the observer who took the measurement — a [Recording Actor].

Term unit: the opaque string naming the measurement's unit — a [Unit].

Term reference: observation id, subject reference, recording actor, amending actor OR retracting actor — every opaque reference this atom records.

Term database instance: one named database a call is routed to — a [Database Name] identifies it; observation id uniqueness ranges over one instance.

```
State 1: EVERY observation MUST stand in EXACTLY ONE OF recorded, amended, retracted.
State 2: An observation whose state EQUALS retracted MUST NOT leave retracted.
State 3: An observation whose state EQUALS amended MUST NOT return to recorded.
State 4: The atom MUST NOT offer a purged state.
State 5: The atom MUST NOT offer a removal surface.
State 6: The atom MUST NOT offer an edit surface.
State 7: The atom MUST NOT offer an un-retract surface.
State 8: EVERY observation MUST carry observation id, subject reference, recording actor, observation type, value, unit, recording instant and a state.
State 9: EVERY amended observation MUST carry a successor id.
State 10: EVERY successor observation MUST carry predecessor id, amending actor and amendment reason.
State 11: EVERY retracted observation MUST carry retracting actor, retraction reason and retraction instant.
State 13: The atom MUST store a resolved recording instant that the future bound DOES NOT PRECEDE, as the call supplied the value.
State 14: The atom MUST NOT normalize a recording instant's timezone.
```

#### Observation

The record this atom defines: one measurement about one subject, carrying its [Observation Id], [Subject Reference], [Recording Actor], [Observation Type], [Value], [Unit], [Recording Instant] and [State], and the transition metadata a chain action writes. A correction is a new Observation, never an edit. [Record] is undone by [Retract]; [Amend] leaves the original kept (Invariant 2.2) and its successor is withdrawn by [Retract]; [Retract] is final (State 2, Invariant 6.1), and no action removes a record (State 5, Invariant 7.1), so no undo is owed beyond these (Execution Contract Undo 4).

Kind: Type

#### Observation Id

The opaque, immutable, system-generated identity of an observation, assigned on [Record], never reused or reassigned within the database instance. The clinical content is a property of the observation, not its identity.

Kind:       Field
Field of:   Observation
Projection: observation_id

#### Subject Reference

The opaque, globally-scoped reference to the subject the observation is about. Set on [Record], immutable, and inherited unchanged by any successor across an amendment chain (Invariant 4).

Kind:       Field
Field of:   Observation
Projection: subject_ref

#### Recording Actor

The opaque reference to the observer who performed the measurement. Set on [Record], inherited unchanged by any successor, and immutable; an amendment carries its own [Amending Actor] and never changes the original [Recording Actor].

Kind:       Field
Field of:   Observation
Projection: recorded_by

#### Observation Type

The opaque string naming what was measured (a vital sign, lab result, assessment score). Set on [Record], immutable, inherited across an amendment chain (Invariant 5). It must have a declared value constraint at the deployment.

Kind:       Field
Field of:   Observation
Projection: observation_type

#### Value

The measured value, validated against the declared per-[Observation Type] constraint at [Record] and [Amend] time. Set on [Record], immutable on the record it belongs to; a correction is a new successor [Value], not an edit.

Kind:       Field
Field of:   Observation
Projection: value

#### Unit

The unit of measure for the [Value], a non-empty opaque string. Set on [Record], or on a successor by the [Amend] that records it, and immutable on its record; terminology standardization to UCUM (Unified Code for Units of Measure) is a deployment convention.

Kind:       Field
Field of:   Observation
Projection: unit

#### Recording Instant

The wall-time the observation was recorded — supplied to [Record], or now, the clock reading the host injects at the seam, where none is supplied; it never stands past the future bound (Operation 7). Set once (Invariant 8), immutable. A successor carries its own [Recording Instant] (when the correction was entered), not the original measurement time.

Kind:       Field
Field of:   Observation
Projection: recorded_at

#### State

The observation's lifecycle state — [Recorded], [Amended], or [Retracted]. Set to [Recorded] on [Record]; transitions via [Amend] (original → [Amended]) and [Retract] (→ [Retracted]).

Kind:       Field
Field of:   Observation
Projection: state

#### Predecessor Id

The [Observation Id] of the record a successor corrects — set on the successor at [Amend] time, immutable thereafter (Invariant 9). At most one per observation (linear chains, Invariant 3).

Kind:       Field
Field of:   Observation
Projection: predecessor_id

#### Successor Id

The [Observation Id] of the correcting record — set on the original when it is [Amended], immutable thereafter (Invariant 9). At most one per observation (linear chains, Invariant 3).

Kind:       Field
Field of:   Observation
Projection: successor_id

#### Amending Actor

The opaque reference to the observer who made a correction — set on the successor at [Amend] time, immutable thereafter.

Kind:       Field
Field of:   Observation
Projection: amended_by

#### Amendment Reason

The required, non-empty reason for a correction — set on the successor at [Amend] time, immutable thereafter. A blank reason defeats the audit trail and is rejected.

Kind:       Field
Field of:   Observation
Projection: amendment_reason

#### Retracting Actor

The opaque reference to the observer who withdrew an observation — set at [Retract] time, immutable thereafter (Invariant 9).

Kind:       Field
Field of:   Observation
Projection: retracted_by

#### Retraction Reason

The required, non-empty reason for a retraction — set at [Retract] time, immutable thereafter. A blank reason is rejected.

Kind:       Field
Field of:   Observation
Projection: retraction_reason

#### Retraction Instant

The wall-time the observation was retracted — now, the clock reading the host injects at the seam, at the [Retract] call; never supplied by the caller. Set at [Retract] time, immutable thereafter (Invariant 9, Invariant 10).

Kind:       Field
Field of:   Observation
Projection: retracted_at

#### Database Name

The identifier of the database instance an observation belongs to. Multiple instances coexist; [Observation Id]s are unique within an instance, while [Subject Reference] is portable across instances. No action accepts it as a parameter — instance selection is handled at the deployment-routing layer.

Kind:       Field
Field of:   the database instance
Projection: store_name

#### Recorded

The state of a current, standing observation. A record enters [Recorded] on [Record] (or as the successor of an [Amend]); it may be amended or retracted.

Kind:      Member
Member of: the observation state
Role:      Outcome

#### Amended

The state of an observation that has been superseded by a correction. Retained and visible, carrying a [Successor Id]; it may still be retracted but not amended again (linear chains, Invariant 3).

Kind:      Member
Member of: the observation state
Role:      Outcome

#### Retracted

The terminal state of an observation withdrawn as erroneous. Retained and visible, withdrawn as erroneous, carrying [Retracting Actor], [Retraction Reason] and [Retraction Instant]; no further transition (Invariant 6).

Kind:      Member
Member of: the observation state
Role:      Outcome

Term observation type: the opaque string naming what was measured — an [Observation Type]; recorded and filtered on, never interpreted.

Term value: the measurement's content — the opaque content of any value, a [Value]; what a valid value is, the observation type's value constraint says (Operation 6).

Term successor id: successor_id — the observation id of the one observation that succeeds this one.

Term predecessor id: predecessor_id — the observation id of the one observation this one succeeds.

## What people do

### Every action

```
Operation 4: IF unit EQUALS blank OR unit EXCEEDS the string cap THEN a content-checking action MUST answer invalid-observation.
Operation 5: IF the observation type carries no value constraint THEN a content-checking action MUST answer invalid-observation.
Operation 6: IF value fails the observation type's value constraint THEN a content-checking action MUST answer invalid-observation.
Operation 11: IF the observation id names no observation THEN a chain action MUST answer not-known.
Operation 12: A chain action MUST answer not-known ONLY IF the observation id names no observation.
Operation 13: IF the observation's state EQUALS retracted THEN a chain action MUST answer already-retracted.
Operation 17: IF reason EQUALS blank THEN a chain action MUST answer invalid-request.
Operation 55: The order of a read's answer (Operation 42, Operation 43) MUST NOT stand for the order the observed events happened in.
Operation 60: IF value carries a string that EXCEEDS the string cap THEN a content-checking action MUST answer invalid-observation.
```

NOTE: watch the blank filter value (Operation 48).

NOTE: watch the filter value over the cap (Operation 61).

NOTE: watch the required input no rule records (Operation 57).

Term states: recorded | amended | retracted — a [State], and the whole state space.

Term chain action: [Amend] | [Retract] — the two actions that address a recorded observation.

Term content-checking action: [Record] | [Amend] — the two actions that carry a value and a unit.

Term writing action: [Record] | [Amend] | [Retract] — every action but [Read].

Term future bound: (now + clock allowance) — the ceiling a resolved recording instant is checked against (Operation 7).
NOTE: watch the future bound — now plus the clock allowance, the ceiling a claimed or occurred instant is checked against, declared here beside Execution Contract Logic confinement 18 and Offline 1, as Communication, Medication Order, Observation and Selective Disclosure each declare it.

Term resolved recording instant: the recording instant the observation carries — the supplied value, as Execution Contract Logic confinement 12 resolves it.

Term content field: observation id, subject reference, recording actor, observation type, value, unit OR recording instant — every field an observation is recorded with but the state, and nothing changes.

Term transition metadata: successor id, predecessor id, amending actor, amendment reason, retracting actor, retraction reason OR retraction instant — every field a chain action writes.

Term amendment chain: the observations one predecessor id and successor id sequence links — one measurement's correction history for one subject; a link runs from an earlier observation to a later one and never back, so no observation is its own ancestor (Operation 29, Operation 32, Identity 2).

Term filter axes: observation id | subject reference | observation type | state | recording instant — the five axes [Read] accepts, and no others, each spelled as its field's projection, a filter on recording instant carrying a range with a start and an end.

Term admitted record: a [Record] call whose references, observation type, unit, value constraint, value and resolved recording instant the guards all admit.

Term admitted amend: an [Amend] call whose observation id names an observation whose state EQUALS recorded, and whose amending actor, reason, value and unit the guards admit.

Term admitted retract: a [Retract] call whose observation id names an observation whose state DOES NOT EQUAL retracted, and whose retracting actor and reason the guards admit.

Term admitted read: a [Read] call whose every filter axis and filter value the guards admit.

Term matching observations: the observations meeting EVERY supplied filter, each carrying every field it holds (State 8 through 11) — what [Read] answers, in the order Operation 42 and Operation 43 give; none where none meets them.

The case space, and the rule that owns each case:

| # | Condition | a chain action answers | owning rule |
|---|---|---|---|
| 1 | the observation id names no observation | [Not Known] | Operation 11 |
| 2 | the observation exists, it stands in retracted | [Already Retracted] | Operation 13 |
| 3 | [Amend], the observation stands in amended | [Already Amended] | Operation 14 |
| 4 | the state admits the action, a request field is blank or over the string cap | [Invalid Request] | Operation 16, Operation 17, Operation 18; Execution Contract Input 2, Capability requirement 8 |
| 5 | [Amend], the request is well-formed, the observation type carries no value constraint, the unit is blank or over the string cap, a string value is over the string cap, or the value fails the constraint | [Invalid Observation] | Operation 4, Operation 5, Operation 6, Operation 60 |
| 6 | every precondition passes, the database refuses the write | [Storage Failure] | Execution Contract Read 4 |
| 7 | every precondition passes, the database accepts the write | the success answer | Operation 34, Operation 37, Invariant 1.1, Invariant 2.2, Invariant 8.1, Invariant 9.1 |

Where two rows hold at once, the one whose refusal the action's refuses line lists first answers (Execution Contract Refusal 1); rows 2 and 3 never hold together, since one observation stands in one state.

#### Invalid Observation

The refusal [Record] or [Amend] returns when observation content fails. Either answers it for an empty or whitespace-only [Unit], a [Value] failing the per-type constraint, an [Observation Type] with no declared constraint, or a [Unit] or string [Value] over the string cap (Operation 4, Operation 60: the pattern's own answer, which stands in place of Execution Contract Input 2); [Record] alone also answers it for an empty, whitespace-only or over-cap [Subject Reference], [Recording Actor] or [Observation Type], or a supplied [Recording Instant] that is malformed (Operation 63) or past the future bound, since [Amend] accepts none of these (Operation 1 through 3, Operation 7, Operation 59, Operation 63).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-observation

#### Storage Failure

The refusal any writing action returns when a durable write fails after preconditions pass. No partial record is observable (Execution Contract Database 1).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

#### Not Known

The refusal [Amend] or [Retract] returns when the named [Observation Id] references no record in this database instance — a lookup miss (a common cause is cross-instance referencing).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Already Retracted

The refusal [Amend] or [Retract] returns when the target is already [Retracted] — retraction is terminal (Invariant 6).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: already-retracted

#### Invalid Request

The refusal [Amend] or [Retract] returns when request metadata fails — an empty or whitespace-only [Amending Actor], [Retracting Actor], or [Reason], or any of them over the string cap (Execution Contract Input 2).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

### Record

#### Record

The behavior an observer or a recording system invokes to create a new [Recorded] observation. It assigns an [Observation Id], sets [Subject Reference], [Recording Actor], [Observation Type], [Value], [Unit], and [Recording Instant], and returns the [Observation Id] (or a rejection). It validates [Value] against the declared per-type constraint and rejects an unknown [Observation Type].

Kind: Operation

```
record(subject_ref, recorded_by, observation_type, value, unit, optional recorded_at)
  answers observation_id
  refuses invalid-observation | storage-failure
```

```
Operation 1: IF subject reference EQUALS blank THEN [Record] MUST answer invalid-observation.
Operation 2: IF recording actor EQUALS blank THEN [Record] MUST answer invalid-observation.
Operation 3: IF observation type EQUALS blank THEN [Record] MUST answer invalid-observation.
Operation 7: IF the future bound PRECEDES the resolved recording instant THEN [Record] MUST answer invalid-observation.
Operation 8: An admitted record MUST record EXACTLY ONE observation.
Operation 9: An admitted record MUST stand the observation in recorded.
Operation 10: An admitted record MUST answer the observation id.
Operation 59: IF the subject reference, the recording actor OR the observation type EXCEEDS the string cap THEN [Record] MUST answer invalid-observation.
Operation 62: An admitted record MUST record EVERY required input PER Execution Contract Input 4.
Operation 63: IF a supplied recording instant is malformed THEN [Record] MUST answer invalid-observation (Execution Contract Input 1).
```

`record(..., observation_type: "cardiac_index")` where the deployment has declared no value constraint for that type → invalid-observation. The atom refuses to record a measurement it cannot check (Operation 5).

`record(..., recorded_at: <an instant past the future bound>)` → invalid-observation. A measurement recorded as taken later than it could have been is a logical impossibility, and the allowance exists only because two clocks are being compared (Operation 7, Capability requirement 5).

`record(..., recorded_at: "next tuesday")` → invalid-observation. A supplied instant that is not an instant is no measurement time, and [Record] answers it as it answers a content field that fails (Operation 63, Execution Contract Input 1).

### Amend

#### Amend

The behavior that corrects a [Recorded] observation by creating a successor. The original transitions to [Amended] with a [Successor Id]; the successor is [Recorded] with a [Predecessor Id], [Amending Actor], [Amendment Reason] and the supplied [Value] and [Unit], inheriting [Subject Reference], [Recording Actor] and [Observation Type] by construction. It does not edit the original and does not accept [Subject Reference], [Observation Type], or [Recording Instant] as parameters.

Kind: Operation

```
amend(observation_id, amended_by, value, unit, reason)
  answers observation_id
  refuses not-known | already-amended | already-retracted | invalid-request | invalid-observation | storage-failure
```

```
Operation 14: IF the observation's state EQUALS amended THEN [Amend] MUST answer already-amended.
Operation 16: IF amending actor EQUALS blank THEN [Amend] MUST answer invalid-request.
Operation 21: [Amend] MUST NOT accept a subject reference.
Operation 22: [Amend] MUST NOT accept an observation type.
Operation 23: [Amend] MUST NOT accept a recording instant.
Operation 24: An admitted amend MUST record EXACTLY ONE successor observation.
Operation 25: An admitted amend MUST take the successor's subject reference from the original.
Operation 26: An admitted amend MUST take the successor's observation type from the original.
Operation 27: An admitted amend MUST stamp the successor's recording instant from now.
Operation 28: An admitted amend MUST stand the successor in recorded.
Operation 29: An admitted amend MUST set the successor's predecessor id to the original's observation id.
Operation 30: An admitted amend MUST record amending actor as amending actor and reason as amendment reason on the successor.
Operation 31: An admitted amend MUST stand the original in amended.
Operation 32: An admitted amend MUST set the original's successor id to the successor's observation id.
Operation 34: An admitted amend MUST answer the successor's observation id.
Operation 56: An admitted amend MUST take the successor's recording actor from the original.
Operation 57: An admitted amend MUST record value and unit on the successor.
```

`amend("obs-0441", amended_by: "rn.okafor", value: 150, unit: "mmHg", reason: "…")` against the already-amended original → already-amended. A second amendment would branch the chain (Operation 14, Invariant 3.1).

`amend("obs-0450", …)` against the retracted observation → [Already Retracted] (Operation 13).

`amend("obs-9999", …)` → [Not Known] (Operation 11).

#### Already Amended

The refusal [Amend] returns when the target is already [Amended] — it has a successor, and amending it again would branch the chain, which Invariant 3 prohibits. A caller whose [Amend] answer was lost and who retries, where no other call changed the observation in between, receives this refusal; the successor id stands on the original, which `read({observation_id: …})` answers carrying it (State 9, Operation 44).

Kind:       Member
Member of:  the Amend rejection
Role:       Outcome
Projection: already-amended

### Retract

#### Retract

The behavior that withdraws an erroneous observation, marking it [Retracted] with [Retracting Actor], [Retraction Reason] and [Retraction Instant]. The record is retained, not destroyed. A [Recorded] or [Amended] observation may be retracted; a [Retracted] one may not (terminal). A retraction withdraws that record alone: the successor of a retracted original stands [Recorded], and an operator who must withdraw the whole chain retracts each link (Operation 38).

Kind: Operation

```
retract(observation_id, retracted_by, reason)
  answers retracted
  refuses not-known | already-retracted | invalid-request | storage-failure
```

```
Operation 18: IF retracting actor EQUALS blank THEN [Retract] MUST answer invalid-request.
Operation 35: An admitted retract MUST stand the observation in retracted.
Operation 36: An admitted retract MUST record retracting actor as retracting actor and reason as retraction reason.
Operation 37: An admitted retract MUST answer retracted.
Operation 38: [Retract] MUST NOT refuse an observation whose state EQUALS amended.
Operation 64: An admitted retract MUST stamp the observation's retraction instant from now.
```

`retract("obs-0441", retracted_by: "dr.mensah", reason: "   ")` → invalid-request. A withdrawal with no stated reason is not an audit record (Operation 17).

### Read

#### Read

The read-only behavior that returns the observations matching a [Query], ordered by [Recording Instant] ascending. It changes nothing. Filters by [Observation Id], [Subject Reference], [Observation Type], time range, or [State] are combinable.

Kind: Operation

```
read(query)
  answers the matching observations
  refuses invalid-query
```

```
Operation 42: An admitted read MUST answer the matching observations in recording instant ascending order.
Operation 43: An admitted read MUST order two observations sharing a recording instant in observation id order, each id compared as a string PER Execution Contract Logic confinement 10.
Operation 44: An admitted read MUST answer EVERY observation matching the supplied filters.
Operation 45: An admitted read MUST NOT answer an observation failing a supplied filter.
Operation 46: IF no observation matches THEN an admitted read MUST answer no matching observations.
Operation 47: IF a filter's axis IS NOT IN the filter axes THEN [Read] MUST answer invalid-query.
Operation 48: IF a filter's value EQUALS blank THEN [Read] MUST answer invalid-query.
Operation 49: IF a state filter's value IS NOT IN the states THEN [Read] MUST answer invalid-query.
Operation 50: IF a range filter's end PRECEDES the range's start THEN [Read] MUST answer invalid-query.
Operation 51: [Read] MUST NOT write.
Operation 58: IF the query is malformed THEN [Read] MUST answer invalid-query (Execution Contract Query 1).
Operation 61: IF a filter's value EXCEEDS the string cap THEN [Read] MUST answer invalid-query.
```

`read({subject_ref: "p42", recorded_by: "rn.okafor"})` → invalid-query. The clinician axis is not among the five, and the key is refused rather than ignored (Operation 47).

#### Query

The selection [Read] consumes — a filter over [Observation Id], [Subject Reference], [Observation Type], time range, and/or [State]. Supplied per call, not stored; a malformed one is rejected [Invalid Query].

Kind:         Parameter
Parameter of: Read
Projection:   query

#### Invalid Query

The refusal [Read] returns when query parameters are malformed — a filter axis outside the five, a blank filter value, a filter value over the string cap, an unrecognized state value, a time range missing its start or its end, or a time range with end before start.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

## What is and what should never be (Invariants)

- **Invariant 1 — Observation immutability.**
  ```
  Invariant 1.1: A recorded content field MUST NOT change.
  ```
- **Invariant 2 — Amendment produces a successor.**
  ```
  Invariant 2.1: An admitted amend MUST record a successor observation.
  Invariant 2.2: An admitted amend MUST NOT change the original's content field.
  ```
- **Invariant 3 — Amendment chains are linear.**
  ```
  Invariant 3.1: An observation MUST NOT carry two successor ids.
  Invariant 3.2: An observation MUST NOT carry two predecessor ids.
  ```
- **Invariant 4 — Subject Reference is inherited across an amendment chain.**
  ```
  Invariant 4.1: EVERY observation in one amendment chain MUST share one subject reference.
  ```
- **Invariant 5 — Observation type is inherited across an amendment chain.**
  ```
  Invariant 5.1: EVERY observation in one amendment chain MUST share one observation type.
  ```
- **Invariant 6 — Retraction is terminal.**
  ```
  Invariant 6.1: An observation whose state EQUALS retracted MUST NOT admit a chain action.
  ```
- **Invariant 7 — Record durability.**
  ```
  Invariant 7.1: The atom MUST NOT remove an observation from the database.
  ```
- **Invariant 8 — Recording Instant is set once.**
  ```
  Invariant 8.1: A recorded recording instant MUST NOT change.
  Invariant 8.2: A successor observation's recording instant MUST stand at the amendment's instant.
  ```
- **Invariant 9 — Transition metadata is write-once.**
  ```
  Invariant 9.1: A recorded transition metadata field MUST NOT change.
  ```
- **Invariant 10 — Retraction Instant is the retraction's.**
  ```
  Invariant 10.1: A retracted observation's retraction instant MUST stand at the retraction's instant.
  ```

---

## When something happens

### Concurrency

```
Concurrency 8: The atom MUST admit two concurrent [Record] calls against one subject reference.
```

## While something is so

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
```

Term string input: a reference, observation type, unit, reason OR a filter's value — every caller-supplied string this atom accepts.

---

## Optional

```
Capability requirement 5: The deployment MUST declare the clock allowance (Execution Contract Logic confinement 18).
Capability requirement 6: The deployment MUST supply the observation records PER Execution Contract Database 1 through 7, Execution Contract Read 4, Execution Contract Refusal 1 and Execution Contract Query 1 through 5.
Capability requirement 7: The deployment MUST declare a value constraint per observation type.
Capability requirement 8: The deployment MAY declare the string cap PER Execution Contract Input 2.
```

#### Reason

The required, non-empty reason string [Amend] and [Retract] consume — written into [Amendment Reason] or [Retraction Reason] respectively. Not stored under this name; an empty or whitespace-only value is rejected [Invalid Request].

Kind:         Parameter
Parameter of: Amend and Retract
Projection:   reason

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the observation id, the clock allowance and the value constraints here.

Term transition: the atom's evaluation of one call against the observation records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term value constraint: the bound a deployment declares for one observation type — what a valid value for that measurement is; declared by the deployment, applied by the atom, and defined by neither the atom nor this grammar; the mechanism that judges a value against it computes at the seam and the host injects the answer (Execution Contract Logic confinement 8).

Term clock allowance: the non-negative duration a deployment declares as the margin between a caller's clock and the seam's; `0` means no tolerance.

Term string cap: the bound on a string input's length in Unicode code points; 1,024 code points where a deployment declares none.

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice.

Term need key: key actor id; pairs observations.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key observation id; carried by observations; calls Read.

## Left to others

```
Non-goal 1: The atom MUST NOT define a value constraint.
Non-goal 3: The atom MUST NOT bound the look-back on a recording instant.
Non-goal 4: The atom MUST NOT interpret a value.
Non-goal 5: The atom MUST NOT confirm that a value stands correct.
Non-goal 6: The atom MUST NOT map an observation type to a controlled vocabulary.
Non-goal 7: The atom MUST NOT map a unit to a controlled vocabulary.
Non-goal 8: The atom MUST NOT offer an amendment that changes an observation type.
Non-goal 9: The atom MUST NOT offer an amendment that changes a subject reference.
Non-goal 10: The atom MUST NOT bind a reference to an actor.
Deleted: Non-goal 11. Non-goal 10 owns it: the atom binds no reference to an actor, and which pattern attests an observer is the app's choice.
Non-goal 12: The atom MUST NOT decide who may call an action.
Deleted: Non-goal 13. Non-goal 12 owns it: the atom decides no caller's authority; the app's permission does.
Non-goal 14: The atom MUST NOT bound an observation's retention.
Deleted: Non-goal 15. Non-goal 14 owns it: the atom bounds no retention, and which pattern does is the app's choice.
Deleted: Non-goal 16. Non-goal 14 owns it: the atom bounds no retention and holds no record against a purge, and which pattern preserves a record is the app's choice.
Non-goal 17: The atom MUST NOT detect a rewrite under the database.
Deleted: Non-goal 18. Non-goal 17 owns it: the atom detects no rewrite, and which pattern makes the records tamper-evident is the app's choice.
Non-goal 19: The atom MUST NOT read two [Record] calls carrying one field set as one observation.
Deleted: Non-goal 20. Non-goal 19 owns it: the atom reads two records of one field set as two observations, and which pattern makes recording at-most-once is the app's choice.
Non-goal 21: The atom MUST NOT derive a trend across two observations.
Non-goal 22: The atom MUST NOT route a call across two database instances.
Non-goal 23: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

NOTE: the owners — an attestation pattern (Non-goal 10, Non-goal 11, External check 3); the app's permission (Non-goal 12, Non-goal 13, External check 2); a retention pattern and a legal-hold pattern (Non-goal 14 through 16; State 4; Execution Contract Database 6); a tamper-evidence pattern (Non-goal 17, Non-goal 18); a composing pattern (Non-goal 21, Composition note 8; Non-goal 22, Composition note 9; Identity 9, Composition note 11).

---

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns it: every deployment declares which composing patterns it wired in.
Composition note 2: A composing pattern owning the value constraint per observation type MUST supply the value constraint to the deployment, which declares the value constraint PER Capability requirement 7.
Composition note 3: A composing pattern MUST own the authorization of a call.
Composition note 4: A composing pattern MUST own the attestation binding a reference.
Composition note 5: A composing pattern MUST own the tamper seal over the observation records.
Composition note 6: A composing pattern MUST own the retention of the observation records.
Composition note 7: A composing pattern MUST own at-most-once recording.
Composition note 8: A composing pattern MUST own a trend across two observations.
Composition note 9: A composing pattern MUST own the routing across two database instances.
Composition note 11: A composing pattern MUST own the meaning of a subject reference across database instances.
```

---

## Example

### A vital sign, recorded and queried

A nurse charts a blood pressure: `record(subject_ref: "p42", recorded_by: "rn.okafor", observation_type: "blood_pressure_systolic", value: 128, unit: "mmHg")` → `obs-0441`, standing in recorded with recording instant from the injected reading (Operation 8 through 10). The clinical system later runs `read({subject_ref: "p42", observation_type: "blood_pressure_systolic", state: recorded})` and receives the current values in recording instant order.

### Correcting a transcription error

The nurse notices the chart reads 128 where the monitor read 148: `amend("obs-0441", amended_by: "rn.okafor", value: 148, unit: "mmHg", reason: "Transcription error — monitor read 148")` → `obs-0442`. The original stands in amended carrying `successor_id: obs-0442`; the successor stands in recorded carrying the corrected value 148 mmHg, the original's recording actor, `predecessor_id: obs-0441`, the amending clinician and the reason (Operation 24 through 32, Operation 34, Operation 56, Operation 57). Both remain visible; a query for recorded observations answers only the successor.

The successor's subject reference, observation type and recording actor came from the original and could not have come from anywhere else — [Amend] accepts none of them (Operation 21, Operation 22, Operation 56, Invariant 4.1, Invariant 5.1). Its recording instant is the amendment's instant, not the measurement's (Operation 27, Invariant 8.2).

### Retracting a wrong-patient entry

A glucose result was charted against the wrong patient. It cannot be amended into the right one, because amendment cannot move a patient: `retract("obs-0450", retracted_by: "dr.mensah", reason: "Recorded against wrong patient — belongs to p77")` → retracted. The record stays, flagged, carrying the retracting clinician, the reason and the instant of the retraction, the reading of the clock at the call (Operation 35 through 37, Operation 64, Invariant 10.1). The correct observation is a fresh [Record] against `p77`.

An amended observation can still be retracted — retraction reaches any link in a chain, and retracting one link leaves its predecessor and successor untouched (Operation 38).

### Regulated adversarial scenarios

- **Regulator audit.** A HIPAA (US Health Insurance Portability and Accountability Act) auditor queries every observation for a patient across all states. The result carries the recorded, amended and retracted alike, and the chain is walkable in both directions — Check 2.1 through 2.4 are what make the amendment trail verifiable from the database rather than from a narrative about it.
- **Disputed observation.** A patient disputes a glucose value. The original's value and clinician are immutable (Invariant 1.1); whether it was amended, by whom and why is on the successor (State 10); whether it was withdrawn, by whom, why and when is on the record itself (State 11). The dispute resolves against the chain, and what the chain cannot say is whether the measurement was *clinically* correct — that is a clinical judgment, not a record property.
- **Breach investigation.** An investigator cross-references each observation's recording actor against the authorized staff list at the time it was recorded. Invariant 1.1 is why the reference can be trusted — it cannot have been changed since — and Invariant 7.1 is why the set is complete, short of what a composing retention pattern purged, which its purge records name (Execution Contract Database 6). What the database cannot supply is whether the named clinician was *authorized*, which is the app's permission's to answer (Non-goal 12, External check 2).

---

## Source

- **HIPAA section 164.312(b)** — audit controls: covered entities must implement hardware, software, and procedural mechanisms to record and examine activity in information systems that contain ePHI (electronic Protected Health Information — individually identifiable health data in digital form). The observation record, with its immutable [Recording Actor] and [Recording Instant], is the primary audit surface.
- **HL7 FHIR (Health Level 7 Fast Healthcare Interoperability Resources — a standard for exchanging healthcare information) Observation resource** — the canonical interoperability representation of a clinical observation; this atom's core fields map to FHIR Observation's `subject` ([Subject Reference]), `performer` ([Recording Actor]), `value[x]` ([Value] + [Unit]), `issued` ([Recording Instant]), and `status` (final → [Recorded]; entered-in-error → [Retracted]; and where FHIR marks the correcting version amended, this atom marks the superseded original [Amended] and leaves its correction [Recorded]). FHIR's `code` field is a CodeableConcept (LOINC (Logical Observation Identifiers Names and Codes) or SNOMED CT (Systematized Nomenclature of Medicine — Clinical Terms)), not an opaque string — this atom deliberately defers terminology binding to deployment convention. FHIR carries many additional fields (category, encounter, bodySite, interpretation, referenceRange) not present here; those are composing-layer concepts.
- **21 CFR (Code of Federal Regulations — the codification of US federal agency rules) Part 11** — electronic records in clinical trials regulated by the FDA (US Food and Drug Administration); each observation is a regulated electronic record requiring attribution, timestamp, and amendment trail.
- **Joint Commission Record of Care standards** — require that corrections to medical records be dated, timed, and attributed; the amendment model satisfies this directly.
- **IHE PCC (Integrating the Healthcare Enterprise — Patient Care Coordination)** — the Clinical Document Architecture (CDA) and FHIR-based profiles that govern how observations are exchanged across care settings.
- **SNOMED CT / LOINC / UCUM** — controlled vocabularies for [Observation Type] and [Unit]; recommended deployment conventions, not atom-level obligations.

---

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the observation records, with their committed versions (Execution Contract Generation acceptance 1).

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY observation's observation id, subject reference, recording actor, observation type, value, unit and recording instant unchanged across EVERY committed version of the observation (Invariant 1.1; Execution Contract Generation acceptance 1).
Check 1.2: An auditor MUST find EVERY transition metadata field an observation carries unchanged across EVERY committed version of the observation carrying the field (Invariant 9.1; Execution Contract Generation acceptance 1).
Check 2.1: An auditor MUST find a successor observation for EVERY amended observation's successor id (Invariant 2.1).
Check 2.2: An auditor MUST find EVERY successor observation's predecessor id equal to the original's observation id (Operation 29).
Check 2.3: An auditor MUST find EVERY observation in one amendment chain sharing one subject reference (Invariant 4.1).
Check 2.4: An auditor MUST find EVERY observation in one amendment chain sharing one observation type (Invariant 5.1).
Check 2.5: An auditor MUST find no observation carrying two successor ids (Invariant 3.1).
Check 2.6: An auditor MUST find no observation carrying two predecessor ids (Invariant 3.2).
Check 3.1: An auditor MUST find no observation leaving retracted across two committed versions of the observation (Invariant 6.1; Execution Contract Generation acceptance 1).
Check 5.1: An auditor MUST find EVERY observation's recording actor non-blank (Operation 2, String 5).
Check 5.2: An auditor MUST find EVERY retracted observation's retracting actor and retraction reason non-blank (Operation 17, Operation 18).
Check 5.3: An auditor MUST find EVERY successor observation's amending actor and amendment reason non-blank (Operation 16, Operation 17).
Check 5.4: An auditor MUST find a predecessor id, an amending actor and an amendment reason on EVERY successor observation (State 10).
Check 5.5: An auditor MUST find a retraction instant on EVERY retracted observation (State 11, Operation 64, Invariant 10.1).
Check 6.1: An auditor MUST find two reads of one database state ordering two observations sharing a recording instant by observation id (Operation 43).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: A deployment needing EVERY issued observation id found in the database MUST capture the record answers (Invariant 7.1).
External check 2: A deployment needing a recording actor confirmed authorized MUST read the app's permission (Non-goal 12).
External check 3: A deployment needing a reference bound to an actor MUST read the composing attestation pattern (Non-goal 10).
External check 4: A deployment needing a value confirmed correct MUST read outside the observation records (Non-goal 5).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the transition; the deployment; a composing pattern; a business caller; a caller; a guard; an auditor; a regulator; an observer; a subject; an investigator; the database; an observation; a successor observation; an original; an amended observation; a retracted observation; a chain action; a content-checking action; a writing action; a refused action; an action; a query; a filter; a state filter; a range filter; an amendment chain; a string input; an opaque reference.

Term records: observation — one recorded measurement, carrying observation id, subject reference, recording actor, observation type, value, unit, recording instant and a state, plus the transition metadata a chain action writes.

Term record verbs: identify, allocate, change, carry, stand, answer, record, set, take, stamp, leave, own, match, equal, normalize, interpret, confirm, admit, offer, detect, route, share, precede, follow, exceed, raise, compare, trim, case-fold, refuse, write, read, find, bound, decide, declare, compose, wire, supply, remove, order, sort, name, bind, derive, map, define, apply, return, store, fail, accept, rest, capture.

Term value sets: state = recorded | amended | retracted.

Term bounds: clock allowance (the margin a deployment declares between a caller's clock and the seam's); value constraint (the bound a deployment declares per observation type); string cap (the bound on a string input's length in Unicode code points, 1,024 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: observation, observation id, subject reference, recording actor, observation type, unit, reference, database instance, seam, transition, now, business caller, states, content field, chain action, content-checking action, writing action, value constraint, clock allowance, future bound, resolved recording instant, transition metadata, amendment chain, filter axes, admitted record, admitted amend, admitted retract, admitted read, string input, blank, committed version, string cap.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Observation]: #observation
[Record]: #record
[Amend]: #amend
[Retract]: #retract
[Read]: #read
[Observation Id]: #observation-id
[Subject Reference]: #subject-reference
[Recording Actor]: #recording-actor
[Observation Type]: #observation-type
[Value]: #value
[Unit]: #unit
[Recording Instant]: #recording-instant
[State]: #state
[Predecessor Id]: #predecessor-id
[Successor Id]: #successor-id
[Amending Actor]: #amending-actor
[Amendment Reason]: #amendment-reason
[Retracting Actor]: #retracting-actor
[Retraction Reason]: #retraction-reason
[Retraction Instant]: #retraction-instant
[Database Name]: #database-name
[Reason]: #reason
[Query]: #query
[Recorded]: #recorded
[Amended]: #amended
[Retracted]: #retracted
[Invalid Observation]: #invalid-observation
[Storage Failure]: #storage-failure
[Not Known]: #not-known
[Already Amended]: #already-amended
[Already Retracted]: #already-retracted
[Invalid Request]: #invalid-request
[Invalid Query]: #invalid-query

---

## Status

`done — 2026-11-27` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-27
formal: verified — observation.als + 3 twins (the static data model: the amendment chain's shape, Invariant 2 through 6 in one state, 2026-06-03; coverage 2026-11-10, unit formal: more coverage for the yes votes); observation.tla + 14 twins (across steps, 2026-11-11, the retraction instant 2026-11-20: one observation's amendment chain under [Record], [Amend] and [Retract], refusals in each refuses line's order, while the clock moves: Invariant 1.1, 2.1, 2.2, 3.1, 3.2, 4.1, 5.1, 6.1, 7.1, 8.1, 8.2, 9.1 and 10.1, Invariant 3.1, 3.2, 4.1 and 5.1 a cross-check with the Alloy model); nothing testable in Alloy for Invariant 1, 7, 8, 9 and 10: each compares an observation with a later version of it, which a single state cannot show, so they are the TLA+ model's; coverage 2026-11-11 (unit `atoms/observation.md formal layer`): no owed rows, 2026-11-11
last gate: 2026-11-27 — Final Critique 11, a delta round, one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 00ef299b — foundational count 0 after the blind second triage, clean, one sample; Linus's report counted foundational 0 with three refining items and one rhetorical, and the blind second triage (one cold Opus 5.5 subagent, run on the frozen page before any cure, which also pressed the delta set for itself) found none of its own; placed refining and cured: Capability requirement 6 cites Execution Contract Query 5 (the page's own invalid-query answers stand in place of its default), and the Already Amended retry sentence says where no other call changed the observation in between; the Example's happy path (no defect: the refusal paths stand in the action examples), the amending actor's attribution (a design the page states) and State 13's reference to Logic confinement 12 (the contract asks it be cited) stand; 2026-11-26 — Final Critique 10, frozen at da9bc143 — foundational count 2, cured, not clean, no sample (Capability requirement 6 omitted Execution Contract Database 5, the rule that keeps every committed version readable, which Check 1.1, 1.2 and 3.1 read; Term reference omitted the observation id, so no rule pinned how a call's id is compared with the stored one; the other reports were placed refining or refuted and their wording cures are in the same commit; Linus's pass lapsed for want of a `Files read:` line, and its findings stand); 2026-11-20 — Final Critique 9, a delta round, one reader (Linus nemotron-3.5-super-vl-free), frozen at 1e8567a9 — foundational count 0 after the blind second triage, clean, one sample (Linus's two foundational reports were refuted by both triages, since Operation 7's future bound refuses the future recording instant it named and no two conforming deployments differ on Identity 9, whose meaning across instances a deployment that gives one reference two meanings breaks; the blind second triage placed the second finding refining, Kind C: Identity 9 named no owner for the meaning of a subject reference across instances, cured by Composition note 11); 2026-11-05 — Final Critique 8, a delta round, frozen at 917cc95 — foundational count 0, clean, no sample; 2026-11-04 — Final Critique 7, a delta round, frozen at 83cd9e0 — foundational count 1, cured, not clean, no sample; 2026-11-04 — Final Critique 6 — foundational count 7, not clean, one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./observation.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/observation.md`.

</details>

NOTE: End of Observation.
