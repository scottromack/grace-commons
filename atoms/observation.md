---
title: Observation
parent: Atomic Concepts
has_toc: true
toc: true
---

# Observation

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Observation records a single measurement about a subject — a vital sign, a lab value, a sensor reading, a financial mark — in a permanent, attributed form that cannot be silently edited.

It answers what an operator or a regulator must be able to ask: what was recorded, who recorded it, and when — and if there were corrections, what they were, who made them, and why.

Errors are never edited away. A correction is recorded as a new observation that supersedes the original, and the original stays in the record marked as amended. An observation logged against the wrong subject or the wrong type is instead retracted — formally withdrawn with a required explanation, the original still kept — and a fresh correct one recorded separately. That keeps the full history of the reasoning recoverable, so a later reviewer can tell a transcription fix apart from a real change in what was being measured.

Each observation is recorded (current), amended (superseded by a correction), or retracted (withdrawn as erroneous); retraction is final, and queries can return just the current observations or the full corrected history.

*Also known as: a reading, a charted measurement, a result record.*

---

## Intent

WHY:
An operator records a measurement about a subject — a blood pressure, a reactor temperature, a closing mark, an assay result — and the record must be trustworthy: what was recorded, who recorded it and when are permanently fixed. Errors are corrected by recording a successor that supersedes the original, and the original does not disappear; it is marked amended. An observation recorded against the wrong subject or under the wrong type is retracted, with the reason documented, rather than edited.

The requirement behind that is universal and recurring wherever a measurement carries consequences: the record must show both what was originally recorded *and* what the correction was, so the history of the reasoning is recoverable. A mutable record system fails it by definition — once someone edits the value, the original is gone and the reason for the edit is invisible. Append-and-supersede preserves both, and it is the only shape that does.

The atom is deliberately domain-neutral, and the neutrality is load-bearing rather than incidental. Strip the setting away and what remains is an amendable, attributed, retractable measurement record — equally a clinical vital sign, a laboratory assay, an instrument reading, or a financial mark. Every domain-specific commitment the concept appears to carry turns out to live somewhere else: what a valid value is, the deployment declares; what the measurement means, the reader decides; which vocabulary names the type, a composition maps. A healthcare deployment of this atom is a composition that supplies those three, not a different atom.

Two structural choices carry most of the atom's weight. The first is that a correction inherits its subject and its type *by construction* rather than by validation: [Amend] does not accept either as a parameter, so an amendment cannot silently move an observation to a different subject or a different measurement. Divergence is not caught, it is unrepresentable. An operator who recorded `temperature` meaning `oxygen_saturation` must retract and re-record, which is the right friction — those are two different measurements, not one measurement with a typo.

The second is that the atom refuses to validate what it has not been told how to validate. An observation type with no declared value constraint is rejected rather than accepted unchecked, which means a deployment adds a new measurement by first declaring what a valid value for it looks like. The atom never defines what a valid blood pressure is — that is domain knowledge and local — and it never records one it could not check.

The atom imposes no semantics on what a value means. It imposes the structural guarantee that the record is faithful to what was recorded and by whom.

## Structure

### Identity model

```
Identity 1: The atom MUST identify an observation by the observation id.
Identity 2: The host MUST allocate an observation id at the seam.
Identity 3: The transition MUST NOT allocate an observation id.
Identity 4: The atom MUST NOT change an observation id.
Identity 5: Two observations in one database instance MUST NOT share an observation id.
Deleted: Identity 6. Execution Contract Database 7 owns it.
Identity 7: The atom MUST NOT identify an observation by the subject reference.
Identity 8: The atom MUST admit a second observation carrying a recorded subject reference.
Identity 9: A subject reference MUST carry one meaning across EVERY database instance.
Identity 10: An observation id MUST carry one meaning within one database instance.
Identity 11: The atom MUST compare a reference byte-exactly.
Identity 12: The atom MUST NOT normalize a reference.
Identity 13: The atom MUST NOT confirm that a subject reference names a known subject.
Identity 14: The atom MUST NOT interpret an observation type.
Identity 15: The atom MUST NOT interpret a unit.
Identity 16: An action MUST NOT accept a database name.
```

Term observation: one recorded measurement about one subject — a value, a unit, a type, an observer and an instant; the record this atom holds.

Term observation id: the opaque value naming one observation — an [Observation Id]; host-allocated at the seam.

Term subject reference: the opaque reference naming what the measurement is about — a [Subject Reference]; a property of the observation, never the observation's identity.

Term recording actor: the opaque reference naming the observer who took the measurement — a [Recording Actor].

Term observation type: the opaque string naming what was measured — an [Observation Type]; recorded and filtered on, never interpreted.

Term unit: the opaque string naming the measurement's unit — a [Unit].

Term reference: subject reference, recording actor, amending actor OR retracting actor — every opaque reference this atom records.

Term database instance: one named database a call is routed to — a [Database Name] identifies it; observation id uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the observation id, the clock offset allowance and the value constraints here.

Term transition: the atom's evaluation of one call against the observation records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

### State

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
State 11: EVERY retracted observation MUST carry retracting actor and retraction reason.
Deleted: State 12. Invariant 7.1 and Execution Contract Database 4 own it.
State 13: The atom MUST store a resolved recording instant standing within the future bound as the call supplied the value.
State 14: The atom MUST NOT normalize a recording instant's timezone.
```

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Capability requirement 5: The deployment MUST declare the clock offset allowance.
Capability requirement 6: The deployment MUST supply the observation records PER Execution Contract Database 1 through 4, Execution Contract Database 6, Execution Contract Database 7, Execution Contract Refusal 1 and Execution Contract Query 1 through 4.
Capability requirement 7: The deployment MUST declare a value constraint per observation type.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Capability requirement 5 owns it.
Deleted: Clock semantics 5. State 13 owns it.
Deleted: Clock semantics 6. State 14 owns it.
Deleted: Clock semantics 7. Non-goal 23 owns it.
```

### Operations

```
record(subject_ref, recorded_by, observation_type, value, unit, optional recorded_at)
  answers observation_id
  refuses invalid-observation | storage-failure

amend(observation_id, amended_by, value, unit, reason)
  answers observation_id
  refuses not-known | already-amended | already-retracted | invalid-request | invalid-observation | storage-failure

retract(observation_id, retracted_by, reason)
  answers retracted
  refuses not-known | already-retracted | invalid-request | storage-failure

read(query)
  answers the matching observations
  refuses invalid-query
```

```
Operation 1: IF subject reference EQUALS blank THEN [Record] MUST answer invalid-observation.
Operation 2: IF recording actor EQUALS blank THEN [Record] MUST answer invalid-observation.
Operation 3: IF observation type EQUALS blank THEN [Record] MUST answer invalid-observation.
Operation 4: IF unit EQUALS blank THEN a content-checking action MUST answer invalid-observation.
Operation 5: IF the observation type carries no value constraint THEN a content-checking action MUST answer invalid-observation.
Operation 6: IF value fails the observation type's value constraint THEN a content-checking action MUST answer invalid-observation.
Operation 7: IF the future bound PRECEDES the resolved recording instant THEN [Record] MUST answer invalid-observation.
Operation 8: An admitted record MUST record EXACTLY ONE observation.
Operation 9: An admitted record MUST stand the observation in recorded.
Operation 10: An admitted record MUST answer the observation id.
Operation 11: IF the observation id names no observation THEN a chain action MUST answer not-known.
Operation 12: A chain action MUST answer not-known ONLY IF the observation id names no observation.
Operation 13: IF the observation's state EQUALS retracted THEN a chain action MUST answer already-retracted.
Operation 14: IF the observation's state EQUALS amended THEN [Amend] MUST answer already-amended.
Deleted: Operation 15. Execution Contract Refusal 1 owns it.
Operation 16: IF amending actor EQUALS blank THEN [Amend] MUST answer invalid-request.
Operation 17: IF reason EQUALS blank THEN a chain action MUST answer invalid-request.
Operation 18: IF retracting actor EQUALS blank THEN [Retract] MUST answer invalid-request.
Deleted: Operation 19. Execution Contract Refusal 1 owns it.
Deleted: Operation 20. Execution Contract Refusal 1 owns it.
Operation 21: [Amend] MUST NOT accept a subject reference.
Operation 22: [Amend] MUST NOT accept an observation type.
Operation 23: [Amend] MUST NOT accept a recording instant.
Operation 24: An admitted amend MUST record EXACTLY ONE successor observation.
Operation 25: An admitted amend MUST take the successor's subject reference from the original.
Operation 26: An admitted amend MUST take the successor's observation type from the original.
Operation 27: An admitted amend MUST stamp the successor's recording instant from now.
Operation 28: An admitted amend MUST stand the successor in recorded.
Operation 29: An admitted amend MUST set the successor's predecessor id to the original's observation id.
Operation 30: An admitted amend MUST record amending actor and reason as amendment reason on the successor.
Operation 31: An admitted amend MUST stand the original in amended.
Operation 32: An admitted amend MUST set the original's successor id to the successor's observation id.
Deleted: Operation 33. Execution Contract Database 1 owns it.
Operation 34: An admitted amend MUST answer the successor's observation id.
Operation 35: An admitted retract MUST stand the observation in retracted.
Operation 36: An admitted retract MUST record retracting actor and reason as retraction reason.
Operation 37: An admitted retract MUST answer retracted.
Operation 38: [Retract] MUST NOT refuse an observation whose state EQUALS amended.
Operation 39: IF the database refuses the write THEN a writing action MUST answer storage-failure.
Deleted: Operation 40. Execution Contract Refusal 1 owns it.
Operation 41: A refused action MUST leave the database as the call found the database.
Operation 42: An admitted read MUST answer the matching observations in recording instant ascending order.
Operation 43: An admitted read MUST order two observations sharing a recording instant stably across two reads of one database state.
Operation 44: An admitted read MUST answer EVERY observation matching the supplied filters.
Operation 45: An admitted read MUST NOT answer an observation failing a supplied filter.
Operation 46: IF no observation matches THEN an admitted read MUST answer an empty observation sequence.
Operation 47: IF a filter's axis IS NOT IN the filter axes THEN [Read] MUST answer invalid-query.
Operation 48: IF a filter's value EQUALS blank THEN [Read] MUST answer invalid-query.
Operation 49: IF a state filter's value IS NOT IN the states THEN [Read] MUST answer invalid-query.
Operation 50: IF a range filter's end PRECEDES the range's start THEN [Read] MUST answer invalid-query.
Operation 51: [Read] MUST NOT write.
Deleted: Operation 52. Capability requirement 1 owns it.
Deleted: Operation 53. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 54. Execution Contract Logic confinement 3 owns it.
Operation 55: An ordering rule MUST NOT rest on a causal claim.
Operation 56: An admitted amend MUST take the successor's recording actor from the original.
Operation 57: An admitted amend MUST record value and unit on the successor.
Operation 58: IF the query is malformed THEN [Read] MUST answer invalid-query.
```

NOTE: watch the blank filter value (Operation 48).

NOTE: open 2026-10-22-a — which key orders two observations sharing a recording instant is not stated; Operation 43 and Check 6.1 ask only that the order be stable.

NOTE: open 2026-10-22-c — an admitted retract records no instant (Operation 36), where an admitted amend stamps the successor's (Operation 27).

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term states: recorded | amended | retracted — a [State], and the whole state space.

Term chain action: [Amend] | [Retract] — the two actions that address a recorded observation.

Term content-checking action: [Record] | [Amend] — the two actions that carry a value and a unit.

Term writing action: [Record] | [Amend] | [Retract] — every action but [Read].

Term value constraint: the bound a deployment declares for one observation type — what a valid value for that measurement is; declared by the deployment, applied by the atom, and defined by neither the atom nor this grammar.

Term clock offset allowance: the non-negative duration a deployment declares as the margin between a caller's clock and the seam's; `0` means no tolerance.

Term future bound: now raised by the clock offset allowance — the ceiling a resolved recording instant is checked against (Operation 7).

Term resolved recording instant: the recording instant the observation carries — the supplied value, as Execution Contract Logic confinement 12 resolves it.

Term content field: observation id, subject reference, recording actor, observation type, value, unit OR recording instant — every field an observation is recorded with but the state, and nothing changes.

Term transition metadata: successor id, predecessor id, amending actor, amendment reason, retracting actor OR retraction reason — every field a chain action writes.

Term amendment chain: the observations one predecessor id and successor id sequence links — one measurement's correction history for one subject.

Term filter axes: observation id | subject reference | observation type | state | recording instant — the five axes [Read] accepts, and no others, a filter on recording instant carrying a range.

Term admitted record: a [Record] call whose references, observation type, unit, value constraint, value and resolved recording instant the guards all admit.

Term admitted amend: an [Amend] call whose observation id names an observation whose state EQUALS recorded, and whose amending actor, reason, value and unit the guards admit.

Term admitted retract: a [Retract] call whose observation id names an observation whose state DOES NOT EQUAL retracted, and whose retracting actor and reason the guards admit.

Term admitted read: a [Read] call whose every filter axis and filter value the guards admit.

| # | Condition | a chain action answers |
|---|---|---|
| 1 | the observation id names no observation | [Not Known] |
| 2 | the observation exists, it stands in retracted | [Already Retracted] |
| 3 | [Amend], the observation stands in amended | [Already Amended] |
| 4 | the state admits the action, a request field is blank | [Invalid Request] |
| 5 | [Amend], the request is well-formed, the unit is blank or the value fails the constraint | [Invalid Observation] |
| 6 | every precondition passes, the database refuses the write | [Storage Failure] |
| 7 | every precondition passes, the database accepts the write | the success answer |

### Invariants

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
  Deleted: Invariant 7.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 7.3. Execution Contract Database 1 and Execution Contract Database 3 own it.
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

---

## Examples

### A vital sign, recorded and queried

A nurse charts a blood pressure: `record(subject_ref: "p42", recorded_by: "rn.okafor", observation_type: "blood_pressure_systolic", value: 128, unit: "mmHg")` → `obs-0441`, standing in recorded with recording instant from the injected reading (Operation 8 through 10). The clinical system later runs `read({subject_ref: "p42", observation_type: "blood_pressure_systolic", state: recorded})` and receives the current values in chronological order.

### Correcting a transcription error

The nurse notices the chart reads 128 where the monitor read 148: `amend("obs-0441", amended_by: "rn.okafor", value: 148, unit: "mmHg", reason: "Transcription error — monitor read 148")` → `obs-0442`. The original stands in amended carrying `successor_id: obs-0442`; the successor stands in recorded carrying the corrected value 148 mmHg, the original's recording actor, `predecessor_id: obs-0441`, the amending clinician and the reason (Operation 24 through 32, Operation 34, Operation 56, Operation 57). Both remain visible; a query for recorded observations answers only the successor.

The successor's subject reference, observation type and recording actor came from the original and could not have come from anywhere else — [Amend] accepts none of them (Operation 21, Operation 22, Operation 56, Invariant 4.1, Invariant 5.1). Its recording instant is the amendment's instant, not the measurement's (Operation 27, Invariant 8.2).

### Retracting a wrong-patient entry

A glucose result was charted against the wrong patient. It cannot be amended into the right one, because amendment cannot move a patient: `retract("obs-0450", retracted_by: "dr.mensah", reason: "Recorded against wrong patient — belongs to p77")` → retracted. The record stays, flagged (Operation 35 through 37). The correct observation is a fresh [Record] against `p77`.

An amended observation can still be retracted — retraction reaches any link in a chain, and retracting one link leaves its predecessor and successor untouched (Operation 38).

### Rejection paths

`record(..., observation_type: "cardiac_index")` where the deployment has declared no value constraint for that type → invalid-observation. The atom refuses to record a measurement it cannot check (Operation 5).

`amend("obs-0441", amended_by: "rn.okafor", value: 150, unit: "mmHg", reason: "…")` against the already-amended original → already-amended. A second amendment would branch the chain (Operation 14, Invariant 3.1).

`amend("obs-0450", …)` against the retracted observation → [Already Retracted] (Operation 13).

`amend("obs-9999", …)` → [Not Known] (Operation 11).

`retract("obs-0441", retracted_by: "dr.mensah", reason: "   ")` → invalid-request. A withdrawal with no stated reason is not an audit record (Operation 17).

`record(..., recorded_at: <an instant past the future bound>)` → invalid-observation. A measurement recorded as taken later than it could have been is a logical impossibility, and the allowance exists only because two clocks are being compared (Operation 7, Capability requirement 5).

`read({subject_ref: "p42", recorded_by: "rn.okafor"})` → invalid-query. The clinician axis is not among the five, and the key is refused rather than ignored (Operation 47).

### Regulated adversarial scenarios

- **Regulator audit.** A HIPAA (US Health Insurance Portability and Accountability Act) auditor queries every observation for a patient across all states. The result carries the recorded, amended and retracted alike, and the chain is walkable in both directions — Check 2.1 through 2.4 are what make the amendment trail verifiable from the database rather than from a narrative about it.
- **Disputed observation.** A patient disputes a glucose value. The original's value and clinician are immutable (Invariant 1.1); whether it was amended, by whom and why is on the successor (State 10); whether it was withdrawn and why is on the record itself (State 11). The dispute resolves against the chain, and what the chain cannot say is whether the measurement was *clinically* correct — that is a clinical judgment, not a record property.
- **Breach investigation.** An investigator cross-references each observation's recording actor against the authorized staff list at the time it was recorded. Invariant 1.1 is why the reference can be trusted — it cannot have been changed since — and Invariant 7.1 is why the set is complete, short of what a composed Retention Window purged, which its purge records name (External check 5). What the database cannot supply is whether the named clinician was *authorized*, which is a composing [Permissions](./permissions.md) record (Non-goal 13, External check 2).

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the observation records.

### Conformance checks

```
Check 1.1: An auditor MUST find a re-read observation's observation id, subject reference, recording actor, observation type, value, unit and recording instant unchanged from the prior read (Invariant 1.1).
Check 1.2: An auditor MUST find a re-read transition metadata field unchanged from the prior read (Invariant 9.1).
Check 2.1: An auditor MUST find a successor observation for EVERY amended observation's successor id (Invariant 2.1).
Check 2.2: An auditor MUST find EVERY successor observation's predecessor id equal to the original's observation id (Operation 29).
Check 2.3: An auditor MUST find EVERY observation in one amendment chain sharing one subject reference (Invariant 4.1).
Check 2.4: An auditor MUST find EVERY observation in one amendment chain sharing one observation type (Invariant 5.1).
Check 2.5: An auditor MUST find no observation carrying two successor ids (Invariant 3.1).
Check 2.6: An auditor MUST find no observation carrying two predecessor ids (Invariant 3.2).
Check 3.1: An auditor MUST find no observation whose state DOES NOT EQUAL retracted on a later read of an observation a prior read found retracted (Invariant 6.1).
Deleted: Check 4.1. Execution Contract Database 6 owns it.
Check 5.1: An auditor MUST find EVERY observation's recording actor non-blank (Operation 2, String 5).
Check 5.2: An auditor MUST find EVERY retracted observation's retracting actor and retraction reason non-blank (Operation 17, Operation 18).
Check 5.3: An auditor MUST find EVERY successor observation's amending actor and amendment reason non-blank (Operation 16, Operation 17).
Check 5.4: An auditor MUST find a predecessor id, an amending actor and an amendment reason on EVERY successor observation (State 10).
Check 6.1: An auditor MUST find two reads of one database state ordering two observations sharing a recording instant alike (Operation 43).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing EVERY issued observation id found in the database MUST capture the record answers (Invariant 7.1).
External check 2: A deployment needing a recording actor confirmed authorized MUST read the composing Permissions record (Non-goal 13).
External check 3: A deployment needing a reference bound to an actor MUST read the composing Actor Identity attestation (Non-goal 11).
External check 4: A deployment needing a value confirmed correct MUST read outside the observation records (Non-goal 5).
Deleted: External check 5. Execution Contract Database 6 owns it.
```

## Non-goals

```
Non-goal 1: The atom MUST NOT define a value constraint.
Deleted: Non-goal 2. Capability requirement 7 owns it.
Non-goal 3: The atom MUST NOT bound the look-back on a recording instant.
Non-goal 4: The atom MUST NOT interpret a value.
Non-goal 5: The atom MUST NOT confirm that a value stands correct.
Non-goal 6: The atom MUST NOT map an observation type to a controlled vocabulary.
Non-goal 7: The atom MUST NOT map a unit to a controlled vocabulary.
Non-goal 8: The atom MUST NOT offer an amendment that changes an observation type.
Non-goal 9: The atom MUST NOT offer an amendment that changes a subject reference.
Non-goal 10: The atom MUST NOT bind a reference to an actor.
Non-goal 11: A deployment needing a non-repudiable observer MUST compose Actor Identity.
Non-goal 12: The atom MUST NOT decide who may call an action.
Non-goal 13: A deployment needing an authorization decision MUST compose Permissions.
Non-goal 14: The atom MUST NOT bound an observation's retention.
Non-goal 15: A deployment needing a retention bound MUST compose Retention Window.
Non-goal 16: A deployment needing a preservation obligation MUST compose Legal Hold.
Non-goal 17: The atom MUST NOT detect a rewrite under the database.
Non-goal 18: A deployment needing a rewrite detected MUST compose Tamper Evidence.
Non-goal 19: The atom MUST NOT read two [Record] calls carrying one field set as one observation.
Non-goal 20: A deployment needing at-most-once recording MUST compose Duplicate Prevention.
Non-goal 21: The atom MUST NOT derive a trend across two observations.
Non-goal 22: The atom MUST NOT route a call across two database instances.
Non-goal 23: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

NOTE: the owners — [Actor Identity](./actor-identity.md) (Non-goal 10, Non-goal 11, External check 3); [Permissions](./permissions.md) (Non-goal 12, Non-goal 13, External check 2); [Retention Window](./retention-window.md) and [Legal Hold](./legal-hold.md) (Non-goal 14 through 16; State 4; External check 5); [Tamper Evidence](./tamper-evidence.md) (Non-goal 17, Non-goal 18); a composing pattern (Non-goal 21, Composition note 8; Non-goal 22, Composition note 9).

---

## Edge cases

### Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 2 owns it.
Deleted: Concurrency 5. Execution Contract Database 2 owns it: a chain action's state check and transition are one transaction, and the atom names no section to release.
Deleted: Concurrency 6. Execution Contract Database 2 owns it: a chain action's state check and transition are one transaction, and the atom names no section to lapse.
Deleted: Concurrency 7. Execution Contract Database 2 owns it.
Concurrency 8: The atom MUST admit two concurrent [Record] calls against one subject reference.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
Deleted: String 7. Execution Contract Logic confinement 13 owns it.
```

Term string input: a reference, observation type, unit, reason OR a filter's value — every caller-supplied string this atom accepts.

NOTE: watch host obligations — this atom sets no maximum length on a string input, where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one. Three postures, and the *host obligations* docket row carries the count — a watch flag states the pressure, never a census nothing reads.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the value constraint per observation type.
Composition note 3: A composing pattern MUST own the authorization of a call.
Composition note 4: A composing pattern MUST own the attestation binding a reference.
Composition note 5: A composing pattern MUST own the tamper seal over the observation records.
Composition note 6: A composing pattern MUST own the retention of the observation records.
Composition note 7: A composing pattern MUST own at-most-once recording.
Composition note 8: A composing pattern MUST own a trend across two observations.
Composition note 9: A composing pattern MUST own the routing across two database instances.
Composition note 10: A composing pattern reading the observation records MUST NOT write to the observation records.
```

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the deployment; a composing pattern; a business caller; a caller; a guard; an auditor; a regulator; an observer; a subject; an investigator; the database; an observation; a successor observation; an original; an amended observation; a retracted observation; a chain action; a content-checking action; a writing action; a refused action; an ordering rule; an action; a query; a filter; a state filter; a range filter; an amendment chain; a string input; an opaque reference.

Term records: observation — one recorded measurement, carrying observation id, subject reference, recording actor, observation type, value, unit, recording instant and a state, plus the transition metadata a chain action writes.

Term record verbs: identify, allocate, change, carry, stand, answer, record, set, take, stamp, leave, own, match, equal, normalize, interpret, confirm, admit, offer, detect, route, share, precede, follow, exceed, raise, compare, trim, case-fold, refuse, write, read, find, bound, decide, declare, compose, wire, supply, remove, order, sort, name, bind, derive, map, define, apply, return, store, fail, accept, rest, capture.

Term value sets: state = recorded | amended | retracted.

Term bounds: clock offset allowance (the margin a deployment declares between a caller's clock and the seam's); value constraint (the bound a deployment declares per observation type).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: observation, observation id, subject reference, recording actor, observation type, unit, reference, database instance, seam, transition, now, business caller, states, content field, chain action, content-checking action, writing action, value constraint, clock offset allowance, future bound, resolved recording instant, transition metadata, amendment chain, filter axes, admitted record, admitted amend, admitted retract, admitted read, string input, blank.

Term successor ids: successor_ids — the ids of the observations that succeed this one.

Term predecessor ids: predecessor_ids — the ids of the observations this one succeeds.

#### Record

The behavior an observer or a recording system invokes to create a new [Recorded] observation. It assigns an [Observation Id], sets [Subject Reference], [Recording Actor], [Observation Type], [Value], [Unit], and [Recording Instant], and returns the [Observation Id] (or a rejection). It validates [Value] against the declared per-type constraint and rejects an unknown [Observation Type].

Kind: Operation

#### Amend

The behavior that corrects a [Recorded] observation by creating a successor. The original transitions to [Amended] with a [Successor Id]; the successor is [Recorded] with a [Predecessor Id], [Amending Actor], [Amendment Reason] and the supplied [Value] and [Unit], inheriting [Subject Reference], [Recording Actor] and [Observation Type] by construction. It does not edit the original and does not accept [Subject Reference], [Observation Type], or [Recording Instant] as parameters.

Kind: Operation

#### Retract

The behavior that withdraws an erroneous observation, marking it [Retracted] with [Retracting Actor] and [Retraction Reason]. The record is retained, not destroyed. A [Recorded] or [Amended] observation may be retracted; a [Retracted] one may not (terminal).

Kind: Operation

#### Read

The read-only behavior that returns the observations matching a [Query], ordered by [Recording Instant] ascending. It changes nothing. Filters by [Observation Id], [Subject Reference], [Observation Type], time range, or [State] are combinable.

Kind: Operation

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

The wall-time the observation was recorded — supplied to [Record], or now, the reading the host injects at the seam, where none is supplied; it never stands past the future bound (Operation 7). Set once (Invariant 8), immutable. A successor carries its own [Recording Instant] (when the correction was entered), not the original measurement time.

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

#### Database Name

The identifier of the database instance an observation belongs to. Multiple instances coexist; [Observation Id]s are unique within an instance, while [Subject Reference] is portable across instances. No action accepts it as a parameter — instance selection is handled at the deployment-routing layer.

Kind:       Field
Field of:   the database instance
Projection: store_name

#### Reason

The required, non-empty reason string [Amend] and [Retract] consume — written into [Amendment Reason] or [Retraction Reason] respectively. Not stored under this name; an empty or whitespace-only value is rejected [Invalid Request].

Kind:         Parameter
Parameter of: Amend
Projection:   reason

#### Query

The selection [Read] consumes — a filter over [Observation Id], [Subject Reference], [Observation Type], time range, and/or [State]. Supplied per call, not stored; a malformed one is rejected [Invalid Query].

Kind:         Parameter
Parameter of: Read
Projection:   query

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

The terminal state of an observation withdrawn as erroneous. Retained and visible but flagged invalid, carrying [Retracting Actor] and [Retraction Reason]; no further transition (Invariant 6).

Kind:      Member
Member of: the observation state
Role:      Outcome

#### Invalid Observation

The refusal [Record] or [Amend] returns when observation content fails. Either answers it for an empty or whitespace-only [Unit], a [Value] failing the per-type constraint, or an [Observation Type] with no declared constraint; [Record] alone also answers it for an empty or whitespace-only [Subject Reference], [Recording Actor] or [Observation Type], or a [Recording Instant] past the future bound, since [Amend] accepts none of these.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-observation

#### Storage Failure

The refusal any writing action returns when a durable write fails after preconditions pass. No partial record is observable (Operation 41).

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

#### Already Amended

The refusal [Amend] returns when the target is already [Amended] — it has a successor, and amending it again would branch the chain, which Invariant 3 prohibits.

Kind:       Member
Member of:  the Amend rejection
Role:       Outcome
Projection: already-amended

#### Already Retracted

The refusal [Amend] or [Retract] returns when the target is already [Retracted] — retraction is terminal (Invariant 6).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: already-retracted

#### Invalid Request

The refusal [Amend] or [Retract] returns when request metadata fails — an empty or whitespace-only [Amending Actor], [Retracting Actor], or [Reason].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Invalid Query

The refusal [Read] returns when query parameters are malformed — a filter axis outside the five, a blank filter value, an unrecognized state value, a time range missing its start or its end, or a time range with end before start.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

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

## Standards references

- **HIPAA section 164.312(b)** — audit controls: covered entities must implement hardware, software, and procedural mechanisms to record and examine activity in information systems that contain ePHI (electronic Protected Health Information — individually identifiable health data in digital form). The observation record, with its immutable [Recording Actor] and [Recording Instant], is the primary audit surface.
- **HL7 FHIR (Health Level 7 Fast Healthcare Interoperability Resources — a standard for exchanging healthcare information) Observation resource** — the canonical interoperability representation of a clinical observation; this atom's core fields map to FHIR Observation's `subject` ([Subject Reference]), `performer` ([Recording Actor]), `value[x]` ([Value] + [Unit]), `issued` ([Recording Instant]), and `status` (final → [Recorded], amended → [Amended], cancelled → [Retracted]). FHIR's `code` field is a CodeableConcept (LOINC (Logical Observation Identifiers Names and Codes) or SNOMED CT (Systematized Nomenclature of Medicine — Clinical Terms)), not an opaque string — this atom deliberately defers terminology binding to deployment convention. FHIR carries many additional fields (category, encounter, bodySite, interpretation, referenceRange) not present here; those are composing-layer concepts.
- **21 CFR (Code of Federal Regulations — the codification of US federal agency rules) Part 11** — electronic records in FDA-regulated (US Food and Drug Administration) clinical trials; each observation is a regulated electronic record requiring attribution, timestamp, and amendment trail.
- **Joint Commission Record of Care standards** — require that corrections to medical records be dated, timed, and attributed; the amendment model satisfies this directly.
- **IHE PCC (Integrating the Healthcare Enterprise — Patient Care Coordination)** — the Clinical Document Architecture (CDA) and FHIR-based profiles that govern how observations are exchanged across care settings.
- **SNOMED CT / LOINC / UCUM** — controlled vocabularies for [Observation Type] and [Unit]; recommended deployment conventions, not atom-level obligations.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — observation.als + 1 twin, 2026-06-03
last gate: 2026-10-22 — Final Critique 5, the council's first round on the page and the first on its Store-contract rewrite (0adcb33) and the refusal-order sweep (c2f4e9a), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS MiniMax M3.1 Flash, Linus GLM-5.3 Flash), each handed only the round's reading set, three passes on one text (frozen at 78fe168); the round rests on three counted passes — foundational count 3 after triage (11 reports: 3 standing, merged into 2; 8 sent down; 0 rejected; 1 rhetorical report raised), all Kind A: a count that could never fall and a check that no observation goes missing broke at the first purge by the Retention Window the page composes; an admitted amend left the successor's recording actor, value and unit with no source; and a rule that an amended observation never refuses [Retract], read alone, kept [Retract] from every refusal on one; an outside read, not counted, found the first two again; 16 refining reports, 5 rhetorical reports; not clean; every foundational finding cured, every refining finding cured or routed; 2026-05-20 — Final Critique 4, fresh reader — clean

open:
- 2026-10-22-a · refining · Operation 43; Check 6.1 · two observations sharing a recording instant are ordered stably across two reads of one database state, with no key named, so one build orders them by observation id and another by commit, each stable → name the key, or say the order is the build's
- 2026-10-22-c · refining · Operation 36; State 11 · an admitted retract records the retracting actor and the reason and no instant, where an admitted amend stamps the successor's recording instant from now (Operation 27), so the records cannot say when an observation was withdrawn → stamp the retraction from now, or name the instant's owner in a non-goal
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/clinical-observation.md`; the migration, the rename, the critical section and the no-repair rule that got it here are in [its history](./observation.hist.md).

- **2026-09-13 — The value constraint is the deployment's, and the refusal is the atom's.** *Chose:* `Operation 5` — an observation type carrying no declared value constraint is refused — with `Non-goal 1` and `Non-goal 2` stating the division from both ends. *Over:* accepting an unknown type unchecked, which is what most record stores do. *Because:* what counts as a valid systolic pressure or pain score is clinical and local, so an atom that defined one would be specified against a single care setting, and an atom that accepted a type it could not check would have a per-type integrity guarantee in name only. A deployment adds a measurement by declaring what a valid value for it looks like first. This is the corpus's first bounds entry whose *value* is entirely the deployment's while its *existence* is normative.

- **2026-09-13 — Inheritance by construction, stated as the absence of a parameter.** *Chose:* `Operation 21`, `Operation 22` and `Operation 23` — [Amend] accepts no subject reference, no observation type and no recording instant — with `Invariant 4` and `Invariant 5` resting on them. *Over:* runtime checks that a successor matches its original. *Because:* a check catches divergence and a missing parameter makes it unrepresentable, and the second is the stronger guarantee. The consequence is the atom's most-questioned friction and it is deliberate: a clinician who charted the wrong measurement type is not correcting a value, they recorded something that did not happen, which retraction says and amendment does not.

- **2026-10-20 — The store's guarantees cited, not restated, the observation's critical section among them.** *Chose:* the observation store supplied under Execution Contract Store 1 through 4 (Capability requirement 6), and the fourteen rules that restated them, ran the atom's own critical section over an observation, or existed only for a store that could split an amend, tombstoned to their owner — Operation 33, an admitted amend's successor and the original's change committed in one operation, Invariant 7.2, no partial record left by a storage-failure rejection, Atomic writes 1 and 2, no reader observing either half of an amend without the other, and Atomic writes 4, no repair of a dangling amend, to Store 1, under which no amend stands half-written; Invariant 7.3, no partial record observed once a crash has landed, and Atomic writes 3, an uncommitted crash leaving the store as the call found it, to Store 1 and Store 3; Concurrency 1 through 4 and Concurrency 7, two chain actions on one observation serialized, the state precondition read and held inside the critical section across the check and the transition, a second serialized [Amend] answering already-amended, and no reconciliation leg, to Store 2, and with them the section's release on the invocation's return (Concurrency 5) and its lapse answered as storage-failure (Concurrency 6), since the atom names no section any more; rules 169 to 156. *Over:* the atom running its own critical section over an observation, released on return and lapsing to a storage failure, and forbidding a repair leg for a dangling amend and a reconciliation leg for a second writer that no conforming store leaves — the turns of 2026-08-30 and 2026-09-13, now in the history. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract: Store 2 reads the state a chain action's guards decide on inside the transaction that writes the action's effects, which is what the section was for, and Store 1 commits [Amend]'s successor and the original's change together or not at all, so no partial record is left to repair and no second writer to reconcile. A refused action leaving the store as the call found it stays the atom's own (Operation 41), as do the rules that keep an observation once it exists (State 5, State 12, Invariant 7.1, Check 4.1), since Store 4 alone neither keeps the atom from removing an observation nor bars a purge another specification declares, and the external check that holds Invariant 7.1 against the captured record answers (External check 1). Amendment chains are the atom's own records, linked by predecessor and successor ids, [Read] answers by recording instant, and the atom's checks compare an auditor's own reads, so it cites neither History 1 nor Order 1; what the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the page's order — a chain action answering not-known, its state rejections, then invalid-request once every state check passes, [Amend] invalid-observation after that, and storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 6, Execution Contract Refusal 1); the pairs that only stated it deleted to Refusal 1: Operation 15 (a state rejection only for an observation id naming an observation), Operation 19 (invalid-request only once every state check passes), Operation 20 (invalid-observation only once every request check passes) and Operation 40 (storage-failure behind every precondition), with Term state rejection, which only Operation 15 read; rules 156 to 152. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-22 — A composed retention may purge what the atom never removes; every field of a successor has a source; a refusal ban names its ground.** *Chose:* State 12 deleted to Invariant 7.1 and Execution Contract Database 4, and Check 4.1 to External check 5, which reads the composing Retention Window's purge records beside two unfiltered reads; Operation 56 and Operation 57, an admitted amend taking the successor's recording actor from the original and recording the call's value and unit on the successor; Operation 38 narrowed to the ground it meant, [Retract] refusing no call on the ground that the observation stands in amended; Non-goal 2 moved to Capability requirement 7, and Term seam naming the clock offset allowance and the value constraints the host injects; Operation 4 refusing a blank unit on [Amend] as on [Record], and Operation 48 a blank value on every filter. *Over:* the reading the 2026-10-20 entry recorded for the maintainer to overrule, under which State 12 and Check 4.1 also barred a purge another specification declares; a successor whose recording actor, value and unit no rule sourced; a ban that, read alone, kept [Retract] from every refusal on an amended observation; and the migration's narrowing of Final Critique 4's refusals to [Record]'s unit and a reference filter's value. *Because:* Final Critique 5 found each, and Final Critique 4's text decided the direction: the atom retains every observation indefinitely, and eventual destruction belongs to Retention Window and Legal Hold as composing patterns, as four Final Critiques read the same shape on their own pages; Medication Order carries the original's prescriber reference onto its successor beside the amending actor; Execution Contract Refusal 1 lets no refusal apply where a rule keeps the action from answering it, so a ban names its ground, as Retention Window, Permissions and Duplicate Prevention write theirs; and Final Critique 4 refused a blank unit on [Amend] and a blank observation id on [Read]. Smaller fixes rode with it, none changing what a rule means: Term content field, the Invalid Observation, Invalid Query, Recording Instant, Recording Actor, Unit and Amend entries, and the transcription example say what the rules say. What each action answers on a well-formed call is unchanged, and a successor now carries a stated recording actor, value and unit.

- **2026-10-22 — A composed purge is answered by the purging pattern's records, and a ban on refusing names its ground, as the Execution Contract says.** *Chose:* External check 5, a composing Retention Window's purge records read beside two unfiltered reads of the observation records, deleted to Execution Contract Database 6, with Check 4.1's tombstone, which named it, now naming the contract, and the label cited on Capability requirement 6; Operation 38's ground clause retired, the rule written as *[Retract] MUST NOT refuse an observation whose state EQUALS amended*, which Execution Contract Refusal 1's second sentence reads as naming the ground, so a blank retracting actor on an amended observation still answers invalid-request; rules 153 to 152. *Over:* the page stating for itself that a purge another specification declares is answered outside the observation records, and Operation 38 carrying the ground clause its fifth Final Critique wrote. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the composed erasure and the refusal ban among them; this page's fifth Final Critique had made both cures one specification at a time. What each action does and answers is unchanged.

NOTE: End of Observation.
