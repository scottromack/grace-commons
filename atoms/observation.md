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
Identity 1: The atom MUST identify an observation by the observation_id.
Identity 2: The host MUST allocate an observation_id at the seam.
Identity 3: The transition MUST NOT allocate an observation_id.
Identity 4: The atom MUST NOT change an observation_id.
Identity 5: Two observations in one store instance MUST NOT share an observation_id.
Identity 6: The deployment MUST route EVERY call to one store instance.
Identity 7: The atom MUST NOT identify an observation by the subject_ref.
Identity 8: The atom MUST admit a second observation carrying a recorded subject_ref.
Identity 9: A subject_ref MUST carry one meaning across EVERY store instance.
Identity 10: An observation_id MUST carry one meaning within one store instance.
Identity 11: The atom MUST compare a reference byte-exactly.
Identity 12: The atom MUST NOT normalize a reference.
Identity 13: The atom MUST NOT confirm that a subject_ref names a known subject.
Identity 14: The atom MUST NOT interpret an observation_type.
Identity 15: The atom MUST NOT interpret a unit.
Identity 16: An action MUST NOT accept a store_name.
```

Term observation: one recorded measurement about one subject — a value, a unit, a type, an observer and an instant; the record this atom holds.

Term observation_id: the opaque value naming one observation — an [Observation Id]; host-allocated at the seam.

Term subject_ref: the opaque reference naming what the measurement is about — a [Subject Ref]; a property of the observation, never the observation's identity.

Term recorded_by: the opaque reference naming the observer who took the measurement — a [Recorded By].

Term observation_type: the opaque string naming what was measured — an [Observation Type]; recorded and filtered on, never interpreted.

Term unit: the opaque string naming the measurement's unit — a [Unit].

Term reference: subject_ref, recorded_by, amended_by OR retracted_by — every opaque reference this atom records.

Term store instance: one named observation store a call is routed to; observation_id uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the observation_id here.

Term transition: the atom's evaluation of one call against the observation store, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

WHY:
Identity 9 and Identity 10 state the two scopes that a multi-site deployment gets wrong in opposite directions. subject_ref is portable by design — the same subject appears in one store and another — and observation_id is not, so a cross-instance query that treats two ids from two stores as comparable is reading coincidence. Identity 16 is what makes the boundary visible in the signature: no action takes a [Store Name], so a caller cannot address two instances in one call and a composition that needs to must do its own routing.

Identity 14 and Identity 15 are why vocabulary standardization sits outside. LOINC (Logical Observation Identifiers Names and Codes), SNOMED CT (Systematized Nomenclature of Medicine — Clinical Terms) and UCUM (Unified Code for Units of Measure) are controlled vocabularies a deployment maps into these two opaque strings, and an atom that knew any of them would be specified against one healthcare stack.

### State

```
State 1: EVERY observation MUST stand in EXACTLY ONE OF recorded, amended, retracted.
State 2: An observation whose state EQUALS retracted MUST NOT leave retracted.
State 3: An observation whose state EQUALS amended MUST NOT return to recorded.
State 4: The atom MUST NOT offer a purged state.
State 5: The atom MUST NOT offer a removal surface.
State 6: The atom MUST NOT offer an edit surface.
State 7: The atom MUST NOT offer an un-retract surface.
State 8: EVERY observation MUST carry observation_id, subject_ref, recorded_by, observation_type, value, unit, recorded_at and a state.
State 9: EVERY amended observation MUST carry a successor_id.
State 10: EVERY successor observation MUST carry predecessor_id, amended_by and amendment_reason.
State 11: EVERY retracted observation MUST carry retracted_by and retraction_reason.
State 12: The store instance's observation count MUST NOT fall.
State 13: The atom MUST store a resolved recorded_at standing within the future bound as the call supplied the value.
State 14: The atom MUST NOT normalize a recorded_at's timezone.
```

WHY:
State 4 is a deliberate absence. Clinical records are not deleted here, and destruction under a retention obligation or a legal hold belongs to the composing patterns that own those clocks — this atom retains everything and offers no surface that would let it do otherwise (Non-goal 15, Non-goal 16).

Invariant 3 is what makes the chain linear rather than a tree, and the `State` family does not restate it. An observation already carrying a successor_id is standing in amended, so a second [Amend] answers already-amended (Operation 14) and there is no path by which a branch could be written.

State 13 is the allowance's exact scope and the thing an implementer gets wrong: the margin widens the *refusal's* tolerance and never alters a *value*. A recorded_at inside the allowance is stored as supplied, not clamped to now.

The consequence is stated rather than hidden: a caller whose clock runs ahead of the seam by more than the allowance is refused as future-dated even though the measurement happened in the past. The width of that margin is the deployment's choice and the refusal is correct at whatever width they pick.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Capability requirement 5: The deployment MUST declare the clock_offset_allowance.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Capability requirement 5 owns it.
Deleted: Clock semantics 5. State 13 owns it.
Deleted: Clock semantics 6. State 14 owns it.
Deleted: Clock semantics 7. Non-goal 23 owns it.
```

WHY:
What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

WHY:
recorded_at may not increase monotonically across a subject's observations under a skewed clock, and there is no sequence number here to fall back on. Ordering within a history is best-effort wall time, not causal order — which is what Operation 55 forbids a rule from resting on.

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
Operation 1: IF subject_ref EQUALS blank THEN [Record] MUST answer invalid-observation.
Operation 2: IF recorded_by EQUALS blank THEN [Record] MUST answer invalid-observation.
Operation 3: IF observation_type EQUALS blank THEN [Record] MUST answer invalid-observation.
Operation 4: IF unit EQUALS blank THEN [Record] MUST answer invalid-observation.
Operation 5: IF the observation_type carries no value constraint THEN a content-checking action MUST answer invalid-observation.
Operation 6: IF value fails the observation_type's value constraint THEN a content-checking action MUST answer invalid-observation.
Operation 7: IF the resolved recorded_at EXCEEDS the future bound THEN [Record] MUST answer invalid-observation.
Operation 8: An admitted record MUST record EXACTLY ONE observation.
Operation 9: An admitted record MUST stand the observation in recorded.
Operation 10: An admitted record MUST answer the observation_id.
Operation 11: IF the observation_id names no observation THEN a chain action MUST answer not-known.
Operation 12: A chain action MUST answer not-known ONLY IF the observation_id names no observation.
Operation 13: IF the observation's state EQUALS retracted THEN a chain action MUST answer already-retracted.
Operation 14: IF the observation's state EQUALS amended THEN [Amend] MUST answer already-amended.
Operation 15: A chain action MUST answer a state rejection ONLY IF the observation_id names an observation.
Operation 16: IF amended_by EQUALS blank THEN [Amend] MUST answer invalid-request.
Operation 17: IF reason EQUALS blank THEN a chain action MUST answer invalid-request.
Operation 18: IF retracted_by EQUALS blank THEN [Retract] MUST answer invalid-request.
Operation 19: A chain action MUST answer invalid-request ONLY IF EVERY state check passes.
Operation 20: [Amend] MUST answer invalid-observation ONLY IF EVERY request check passes.
Operation 21: [Amend] MUST NOT accept a subject_ref.
Operation 22: [Amend] MUST NOT accept an observation_type.
Operation 23: [Amend] MUST NOT accept a recorded_at.
Operation 24: An admitted amend MUST record EXACTLY ONE successor observation.
Operation 25: An admitted amend MUST take the successor's subject_ref from the original.
Operation 26: An admitted amend MUST take the successor's observation_type from the original.
Operation 27: An admitted amend MUST stamp the successor's recorded_at from now.
Operation 28: An admitted amend MUST stand the successor in recorded.
Operation 29: An admitted amend MUST set the successor's predecessor_id to the original's observation_id.
Operation 30: An admitted amend MUST record amended_by and reason as amendment_reason on the successor.
Operation 31: An admitted amend MUST stand the original in amended.
Operation 32: An admitted amend MUST set the original's successor_id to the successor's observation_id.
Operation 33: An admitted amend MUST commit the successor and the original's change in one operation.
Operation 34: An admitted amend MUST answer the successor's observation_id.
Operation 35: An admitted retract MUST stand the observation in retracted.
Operation 36: An admitted retract MUST record retracted_by and reason as retraction_reason.
Operation 37: An admitted retract MUST answer retracted.
Operation 38: An observation whose state EQUALS amended MUST NOT refuse [Retract].
Operation 39: IF the store refuses the write THEN a writing action MUST answer storage-failure.
Operation 40: An action MUST answer storage-failure ONLY IF EVERY precondition passes.
Operation 41: A refused action MUST leave the store as the call found the store.
Operation 42: An admitted read MUST answer the matching observations in recorded_at ascending order.
Operation 43: An admitted read MUST order two observations sharing a recorded_at stably across two reads of one store state.
Operation 44: An admitted read MUST answer EVERY observation matching the supplied filters.
Operation 45: An admitted read MUST NOT answer an observation failing a supplied filter.
Operation 46: IF no observation matches THEN an admitted read MUST answer an empty observation sequence.
Operation 47: IF a filter's axis IS NOT IN the filter axes THEN [Read] MUST answer invalid-query.
Operation 48: IF a reference filter's value EQUALS blank THEN [Read] MUST answer invalid-query.
Operation 49: IF a state filter's value IS NOT IN the states THEN [Read] MUST answer invalid-query.
Operation 50: IF a range filter's end precedes the range's start THEN [Read] MUST answer invalid-query.
Operation 51: [Read] MUST NOT write.
Deleted: Operation 52. Capability requirement 1 owns it.
Deleted: Operation 53. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 54. Execution Contract Logic confinement 3 owns it.
Operation 55: An ordering rule MUST NOT rest on a causal claim.
```

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term states: recorded | amended | retracted — a [State], and the whole state space.

Term chain action: [Amend] | [Retract] — the two actions that address a recorded observation.

Term content-checking action: [Record] | [Amend] — the two actions that carry a value and a unit.

Term writing action: [Record] | [Amend] | [Retract] — every action but [Read].

Term state rejection: already-amended OR already-retracted — the refusals that rest on the observation's state.

Term value constraint: the bound a deployment declares for one observation_type — what a valid value for that measurement is; declared by the deployment, applied by the atom, and defined by neither the atom nor this grammar.

Term clock_offset_allowance: the non-negative duration a deployment declares as the margin between a caller's clock and the seam's; `0` means no tolerance.

Term future bound: now raised by the clock_offset_allowance — the ceiling a resolved recorded_at is checked against (Operation 7).

Term resolved recorded_at: the recorded_at the observation carries — the supplied value where one exists, and now otherwise.

Term content field: observation_id, subject_ref, recorded_by, observation_type, value, unit OR recorded_at — every field [Record] sets and nothing changes.

Term transition metadata: successor_id, predecessor_id, amended_by, amendment_reason, retracted_by OR retraction_reason — every field a chain action writes.

Term amendment chain: the observations one predecessor_id and successor_id sequence links — one measurement's correction history for one subject.

Term filter axes: observation_id | subject_ref | observation_type | state | recorded_at — the five axes [Read] accepts, and no others.

Term admitted record: a [Record] call whose references, observation_type, unit, value constraint, value and resolved recorded_at the guards all admit.

Term admitted amend: an [Amend] call whose observation_id names an observation whose state EQUALS recorded, and whose amended_by, reason, value and unit the guards admit.

Term admitted retract: a [Retract] call whose observation_id names an observation whose state DOES NOT EQUAL retracted, and whose retracted_by and reason the guards admit.

Term admitted read: a [Read] call whose every filter axis and filter value the guards admit.

| # | Condition | a chain action answers |
|---|---|---|
| 1 | the observation_id names no observation | not-known |
| 2 | the observation exists, it stands in retracted | already-retracted |
| 3 | [Amend], the observation stands in amended | already-amended |
| 4 | the state admits the action, a request field is blank | invalid-request |
| 5 | [Amend], the request is well-formed, value or unit fails the constraint | invalid-observation |
| 6 | every precondition passes, the store refuses the write | storage-failure |
| 7 | every precondition passes, the store accepts the write | the success answer |

WHY:
The precedence runs cheapest and most structural first — [Not Known] before a state rejection, [Invalid Request] before [Invalid Observation], and [Storage Failure] last — and it is the same order across conforming implementations so a caller can write deterministic retry logic. A caller that fixes one rejection class and receives a different one on retry is seeing the next check fire, not a regression.

Operation 21 and Operation 22 are the atom's strongest structural claim and they are stated as *the action does not accept the parameter* rather than as a validation. A successor cannot diverge from its original's subject or type because there is no input through which it could — Invariant 4 and Invariant 5 hold by construction, not by a runtime check on values that cannot be supplied. Operation 23 is the same move for a different reason: an amendment's instant is its own audit provenance, so allowing a caller-supplied one would let a back-dated correction masquerade as contemporaneous.

Operation 5 is the refusal that surprises implementers. An observation_type carrying no declared value constraint is rejected rather than accepted unchecked, because accepting it would mean recording a measurement the atom had no way to validate — and a store that silently accepts unknown types has a per-type integrity guarantee in name only. A deployment adds a measurement by declaring its constraint first.

Operation 43 admits a limit rather than inventing an order. Two observations sharing a recorded_at — concurrent entries, a back-dated record colliding with a current one, a coarse clock — have no order this atom can derive, so the requirement is stability across reads of one store state rather than a prescribed tiebreak. A caller depending on a particular tiebreak establishes it as a deployment convention, and observation_id order is deterministic but arbitrary across implementations.

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
  Invariant 3.1: An observation MUST NOT carry two successor_ids.
  Invariant 3.2: An observation MUST NOT carry two predecessor_ids.
  ```
- **Invariant 4 — Subject ref is inherited across an amendment chain.**
  ```
  Invariant 4.1: EVERY observation in one amendment chain MUST share one subject_ref.
  ```
  WHY: by construction rather than by check (Operation 21). [Amend] takes no subject_ref, so a successor naming a different subject is not a violation the atom catches — it is a call the signature cannot express. A wrong-subject entry is retracted and re-recorded against the right one.
- **Invariant 5 — Observation type is inherited across an amendment chain.**
  ```
  Invariant 5.1: EVERY observation in one amendment chain MUST share one observation_type.
  ```
  WHY: the same construction (Operation 22), and the friction is the point. A chain models one measurement's corrections, so an observer who recorded the wrong measurement is not correcting a value — they recorded something that did not happen, which retraction says and amendment does not.
- **Invariant 6 — Retraction is terminal.**
  ```
  Invariant 6.1: An observation whose state EQUALS retracted MUST NOT admit a chain action.
  ```
- **Invariant 7 — Store durability.**
  ```
  Invariant 7.1: The atom MUST NOT remove an observation from the store.
  Invariant 7.2: A storage-failure rejection MUST leave no partial record in the store.
  Invariant 7.3: A reader MUST NOT observe a partial record once a crash has landed.
  ```
  WHY: Invariant 7.3 forbids the repair-later posture other stores are allowed. A crash-recovery scan that fixes a dangling amend after the fact is not a substitute here, because between the crash and the repair the partial record is *visible*, which is the state this invariant says never exists — and one of the two dangling shapes cannot be repaired at all without rewriting a write-once field (Atomic writes 4, Invariant 9.1).
- **Invariant 8 — Recorded at is set once.**
  ```
  Invariant 8.1: A recorded recorded_at MUST NOT change.
  Invariant 8.2: A successor observation's recorded_at MUST stand at the amendment's instant.
  ```
  WHY: the successor's instant says when the correction was entered, and the original's says when the measurement was taken. Conflating them would lose the distinction a reviewer needs most — whether a value changed because the subject changed or because the record was wrong.
- **Invariant 9 — Transition metadata is write-once.**
  ```
  Invariant 9.1: A recorded transition metadata field MUST NOT change.
  ```
  WHY: the protections come from elsewhere and meet here. A successor_id cannot be overwritten because a second [Amend] answers already-amended (Operation 14, Invariant 3.1); a retracted_by cannot be overwritten because retraction is terminal (Invariant 6.1); a successor's predecessor_id, amended_by and amendment_reason are covered as any observation's fields are (Invariant 1.1). Taken with Invariant 1 and Invariant 8, no field of any observation ever changes after it is first written.

---

## Examples

### A vital sign, recorded and queried

A nurse charts a blood pressure: `record(subject_ref: "p42", recorded_by: "rn.okafor", observation_type: "blood_pressure_systolic", value: 128, unit: "mmHg")` → `obs-0441`, standing in recorded with recorded_at from the injected reading (Operation 8 through 10). The clinical system later runs `read({subject_ref: "p42", observation_type: "blood_pressure_systolic", state: recorded})` and receives the current values in chronological order.

### Correcting a transcription error

The nurse notices the chart reads 128 where the monitor read 148: `amend("obs-0441", amended_by: "rn.okafor", value: 148, unit: "mmHg", reason: "Transcription error — monitor read 148")` → `obs-0442`. The original stands in amended carrying `successor_id: obs-0442`; the successor stands in recorded carrying `predecessor_id: obs-0441`, the amending clinician and the reason (Operation 24 through 34). Both remain visible; a query for recorded observations answers only the successor.

The successor's subject_ref and observation_type came from the original and could not have come from anywhere else — [Amend] accepts neither (Operation 21, Operation 22, Invariant 4.1, Invariant 5.1). Its recorded_at is the amendment's instant, not the measurement's (Operation 27, Invariant 8.2).

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

- **Regulator audit.** A HIPAA (US Health Insurance Portability and Accountability Act) auditor queries every observation for a patient across all states. The result carries the recorded, amended and retracted alike, and the chain is walkable in both directions — Check 2.1 through 2.4 are what make the amendment trail verifiable from the store rather than from a narrative about it.
- **Disputed observation.** A patient disputes a glucose value. The original's value and clinician are immutable (Invariant 1.1); whether it was amended, by whom and why is on the successor (State 10); whether it was withdrawn and why is on the record itself (State 11). The dispute resolves against the chain, and what the chain cannot say is whether the measurement was *clinically* correct — that is a clinical judgment, not a record property.
- **Breach investigation.** An investigator cross-references each observation's recorded_by against the authorized staff list at the time it was recorded. Invariant 1.1 is why the reference can be trusted — it cannot have been changed since — and Invariant 7.1 is why the set is complete. What the store cannot supply is whether the named clinician was *authorized*, which is a composing [Permissions](./permissions.md) record (Non-goal 13, External check 2).

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the observation store alone, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find a re-read observation's observation_id, subject_ref, recorded_by, observation_type, value, unit and recorded_at unchanged from the prior read (Invariant 1.1).
Check 1.2: An auditor MUST find a re-read transition metadata field unchanged from the prior read (Invariant 9.1).
Check 2.1: An auditor MUST find a successor observation for EVERY amended observation's successor_id (Invariant 2.1).
Check 2.2: An auditor MUST find EVERY successor observation's predecessor_id equal to the original's observation_id (Operation 29).
Check 2.3: An auditor MUST find EVERY observation in one amendment chain sharing one subject_ref (Invariant 4.1).
Check 2.4: An auditor MUST find EVERY observation in one amendment chain sharing one observation_type (Invariant 5.1).
Check 2.5: An auditor MUST find no observation carrying two successor_ids (Invariant 3.1).
Check 2.6: An auditor MUST find no observation carrying two predecessor_ids (Invariant 3.2).
Check 3.1: An auditor MUST find no observation whose state DOES NOT EQUAL retracted on a later read of an observation a prior read found retracted (Invariant 6.1).
Check 4.1: An auditor MUST find no observation absent from a later read (Invariant 7.1).
Check 5.1: An auditor MUST find EVERY observation's recorded_by non-blank (Operation 2, String 5).
Check 5.2: An auditor MUST find EVERY retracted observation's retracted_by and retraction_reason non-blank (Operation 17, Operation 18).
Check 5.3: An auditor MUST find EVERY successor observation's amended_by and amendment_reason non-blank (Operation 16, Operation 17).
Check 5.4: An auditor MUST find a predecessor_id, an amended_by and an amendment_reason on EVERY successor observation (State 10).
Check 6.1: An auditor MUST find two reads of one store state ordering two observations sharing a recorded_at alike (Operation 43).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing EVERY issued observation_id found in the store MUST capture the record answers (Invariant 7.1).
External check 2: A deployment needing a recorded_by confirmed authorized MUST read the composing Permissions record (Non-goal 13).
External check 3: A deployment needing a reference bound to an actor MUST read the composing Actor Identity attestation (Non-goal 11).
External check 4: A deployment needing a value confirmed correct MUST read outside the observation store (Non-goal 5).
```

WHY:
External check 1 is the answer-capture split, which is a docket row rather than settled corpus law — four atoms have reached for it independently and nothing has ruled it. Enumerating every *issued* observation_id needs the record answers captured at call time, because a production auditor reading the store cannot know about an observation the store is missing. Check 4.1 is the store-alone substitute from the other direction.

External check 4 is the boundary a reader most wants the atom to cross and it cannot. The store says a value was recorded, by whom, when, and what it was corrected to. It does not say the measurement was taken correctly, that the cuff was the right size, or that 148 was the patient's actual pressure. That is clinical truth, and no record structure supplies it.

## Non-goals

```
Non-goal 1: The atom MUST NOT define a value constraint.
Non-goal 2: The deployment MUST declare a value constraint per observation_type.
Non-goal 3: The atom MUST NOT bound the look-back on a recorded_at.
Non-goal 4: The atom MUST NOT interpret a value.
Non-goal 5: The atom MUST NOT confirm that a value stands correct.
Non-goal 6: The atom MUST NOT map an observation_type to a controlled vocabulary.
Non-goal 7: The atom MUST NOT map a unit to a controlled vocabulary.
Non-goal 8: The atom MUST NOT offer an amendment that changes an observation_type.
Non-goal 9: The atom MUST NOT offer an amendment that changes a subject_ref.
Non-goal 10: The atom MUST NOT bind a reference to an actor.
Non-goal 11: A deployment needing a non-repudiable observer MUST compose Actor Identity.
Non-goal 12: The atom MUST NOT decide who may call an action.
Non-goal 13: A deployment needing an authorization decision MUST compose Permissions.
Non-goal 14: The atom MUST NOT bound an observation's retention.
Non-goal 15: A deployment needing a retention bound MUST compose Retention Window.
Non-goal 16: A deployment needing a preservation obligation MUST compose Legal Hold.
Non-goal 17: The atom MUST NOT detect a rewrite under the store.
Non-goal 18: A deployment needing a rewrite detected MUST compose Tamper Evidence.
Non-goal 19: The atom MUST NOT read two [Record] calls carrying one field set as one observation.
Non-goal 20: A deployment needing at-most-once recording MUST compose Duplicate Prevention.
Non-goal 21: The atom MUST NOT derive a trend across two observations.
Non-goal 22: The atom MUST NOT route a call across two store instances.
Non-goal 23: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

WHY:
Non-goal 1 and Non-goal 2 are one decision read from both ends, and it is the atom's sharpest division of labour. What counts as a valid systolic pressure, a valid pain score, a valid glucose reading is clinical and local — an adult ICU and a neonatal unit disagree, and an atom that picked either would be specified against one care setting. So the atom defines no constraint and refuses to record a type that has none (Operation 5). The deployment supplies the clinical knowledge; the atom supplies the guarantee that the knowledge was applied.

Non-goal 3 leaves recorded_at unbounded below on purpose. A nurse charting a bedside observation taken thirty minutes ago is normal workflow; an observation charted two years late is unusual and may warrant scrutiny, and the difference between *unusual* and *invalid* is a clinical judgment the atom declines to make. The future bound refuses the one direction that is always impossible.

Non-goal 8 and Non-goal 9 restate as refusals what Operation 21 and Operation 22 make unrepresentable. Both are worth stating twice in different registers: a reader looking for *can I fix the type with an amendment* finds the answer in the Non-goals, and an implementer looking at the signature finds that the question does not arise.

Non-goal 21 draws the analytics line. Trend, delta-from-prior and reference-range comparison are readers of this store rather than features of it, and folding any of them in would put clinical interpretation inside a record that exists to be interpretation-free.

---

## Edge cases

### Atomic writes

```
Atomic writes 1: A reader MUST NOT observe a successor observation without the original's successor_id.
Atomic writes 2: A reader MUST NOT observe an amended original without the successor observation.
Atomic writes 3: An uncommitted crash MUST leave the store as the call found the store.
Atomic writes 4: The implementation MUST NOT repair a dangling amend.
```

Term uncommitted crash: a crash BEFORE an admitted amend's commit lands.

Term dangling amend: an admitted amend's two writes standing partly applied once a crash has landed.

WHY:
This atom forbids outright the repair-later posture the corpus's other append-only stores are permitted, and the argument is worth keeping. [Amend] makes two durable writes — the successor, and the original's move to amended with its successor_id — and both are writes to this atom's own store, so one transaction covers them and an abort takes both back (Operation 33).

A crash-recovery scan is not an acceptable substitute for two reasons. The partial record is *visible* between the crash and the repair, which is the state Invariant 7.3 says never exists. And one of the two dangling shapes cannot be repaired at all: an orphan successor could be relinked from its predecessor_id, but an original marked amended with a successor_id naming no record cannot — the successor's value, unit, amending observer and reason exist nowhere in the store, and un-marking the original would rewrite a write-once field (Invariant 9.1).

A caller whose [Amend] timed out recovers by reading the original: standing in amended with a successor_id means the transaction committed, and standing in recorded means it did not and a retry is safe under Concurrency 1.

### Concurrency

```
Concurrency 1: The implementation MUST serialize two chain actions against one observation.
Concurrency 2: The implementation MUST NOT read the state precondition BEFORE the implementation takes the per-observation critical section.
Concurrency 3: The implementation MUST hold the per-observation critical section across the state check and the transition the check guards.
Concurrency 4: A second serialized [Amend] against one observation MUST answer already-amended.
Concurrency 5: The implementation MUST release the per-observation critical section on the invocation's return.
Concurrency 6: IF the per-observation critical section lapses mid-invocation THEN the implementation MUST answer storage-failure.
Concurrency 7: The atom MUST NOT offer a reconciliation leg.
Concurrency 8: The atom MUST admit two concurrent [Record] calls against one subject_ref.
```

Term per-observation critical section: the mutual exclusion an implementation holds over one observation_id while a chain action's state check and transition run.

WHY:
Concurrency 2 and Concurrency 3 close the window that makes the state checks meaningful. A state check read outside the critical section is a fact about the past by the time the transition runs, and two amends that both read *recorded* would both write — producing the branch Invariant 3.1 forbids. Taking the critical section first makes the check and the transition one step, so a second amend that waited re-reads under the critical section and lands already-amended.

Concurrency 6 and Concurrency 7 together say what happens when the critical section is a lease and the lease expires: the invocation's terminus is the expiry, the transaction aborts, and the call answers storage-failure rather than continuing outside the critical section. There is exactly one writer per transition and no leg that reconciles two.

Concurrency 8 states the other half — [Record] contends over nothing, so two clinicians charting the same patient at once is ordinary and each gets its own observation.

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: The deployment MUST canonicalize an opaque reference.
```

Term string input: a reference, observation_type, unit, reason OR a filter's value — every caller-supplied string this atom accepts.


WHY:
A whitespace-only observer reference, reason or type is blank and refused exactly as an empty one is (String 5). The alternative — accepting a space as an observer identity — produces a record that satisfies a presence check and attributes nothing, which is the failure the attribution invariants exist to prevent.

Byte-exactness also decides which observations share a chain and which subject a query answers about. A deployment writing `P42` on one call and `p42` on the next has two subjects here (Identity 11, Identity 12).

NOTE: watch host obligations — this atom sets no maximum length on a string input, where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one. Three postures, and the *host obligations* docket row carries the count — a watch flag states the pressure, never a census nothing reads.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the value constraint per observation_type.
Composition note 3: A composing pattern MUST own the authorization of a call.
Composition note 4: A composing pattern MUST own the attestation binding a reference.
Composition note 5: A composing pattern MUST own the tamper seal over the observation store.
Composition note 6: A composing pattern MUST own the retention of the observation store.
Composition note 7: A composing pattern MUST own at-most-once recording.
Composition note 8: A composing pattern MUST own a trend across two observations.
Composition note 9: A composing pattern MUST own the routing across two store instances.
Composition note 10: A composing pattern reading the observation store MUST NOT write to the observation store.
```

WHY:
[Event Log](./event-log.md) is the structural cousin and not a constituent: this store is append-only with immutable entries ordered by an instant, which is an event log's shape, and it carries amendment and retraction semantics an event log has none of. A deployment may layer one as the persistence substrate; that is an implementation choice rather than a composition this atom names.

[Actor Identity](./actor-identity.md) is what makes recorded_by, amended_by and retracted_by more than opaque strings — the attestation that the reference names a real, credentialed observer at the time of recording, which a disputed-authorship challenge needs and this atom cannot supply. [Permissions](./permissions.md) answers the different question of whether that observer was *allowed* to record, and the two are often confused: the atom records who, the attestation proves who, the permission proves may.

[Tamper Evidence](./tamper-evidence.md) lifts immutability from a specification guarantee to a cryptographic one. [Retention Window](./retention-window.md) and [Legal Hold](./legal-hold.md) own the clocks this atom refuses to hold (State 4, Non-goal 14 through 16), and [Audit Trail](../compositions/audit-trail.md) is the regulated record-keeping stack this store feeds. [Medication Order](./medication-order.md) carries an opaque reference to the observations that informed a prescribing decision — advisory, unidirectional, and no dependency in this direction: this atom is the upstream evidence and does not know what was done with it.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern; a business caller; a caller; a guard; an auditor; a regulator; an observer; a subject; an investigator; the store; an observation; a successor observation; an original; an amended observation; a retracted observation; a chain action; a content-checking action; a writing action; a refused action; an ordering rule; an action; a query; a filter; a reference filter; a state filter; a range filter; a state rejection; an amendment chain; a rejection; a crash; a reader; a string input; an opaque reference; the store instance's observation count.

Term records: observation — one recorded measurement, carrying observation_id, subject_ref, recorded_by, observation_type, value, unit, recorded_at and a state, plus the transition metadata a chain action writes.

Term record verbs: identify, allocate, change, carry, stand, answer, record, set, take, stamp, leave, own, match, equal, normalize, interpret, confirm, admit, offer, detect, route, share, precede, follow, exceed, raise, compare, trim, case-fold, refuse, write, read, find, observe, repair, commit, fall, bound, decide, declare, compose, wire, supply, remove, order, sort, name, bind, derive, map, define, apply, hold, release, serialize, lapse, return, canonicalize, store, fail, accept, rest, capture.

Term value sets: state = recorded | amended | retracted.

Term bounds: clock_offset_allowance (the margin a deployment declares between a caller's clock and the seam's); value constraint (the bound a deployment declares per observation_type).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: observation, observation_id, subject_ref, recorded_by, observation_type, unit, reference, store instance, seam, transition, now, business caller, states, content field, chain action, content-checking action, writing action, state rejection, value constraint, clock_offset_allowance, future bound, resolved recorded_at, transition metadata, amendment chain, filter axes, admitted record, admitted amend, admitted retract, admitted read, per-observation critical section, string input, blank, uncommitted crash, dangling amend.

#### Record

The behavior an observer or a recording system invokes to create a new [Recorded] observation. It assigns an [Observation Id], sets [Subject Ref], [Recorded By], [Observation Type], [Value], [Unit], and [Recorded At], and returns the [Observation Id] (or a rejection). It validates [Value] against the declared per-type constraint and rejects an unknown [Observation Type].

Kind: Operation

#### Amend

The behavior that corrects a [Recorded] observation by creating a successor. The original transitions to [Amended] with a [Successor Id]; the successor is [Recorded] with a [Predecessor Id], [Amended By], and [Amendment Reason], inheriting [Subject Ref] and [Observation Type] by construction. It does not edit the original and does not accept [Subject Ref], [Observation Type], or [Recorded At] as parameters.

Kind: Operation

#### Retract

The behavior that withdraws an erroneous observation, marking it [Retracted] with [Retracted By] and [Retraction Reason]. The record is retained, not destroyed. A [Recorded] or [Amended] observation may be retracted; a [Retracted] one may not (terminal).

Kind: Operation

#### Read

The read-only behavior that returns the observations matching a [Query], ordered by [Recorded At] ascending. It changes nothing. Filters by [Observation Id], [Subject Ref], [Observation Type], time range, or [State] are combinable.

Kind: Operation

#### Observation Id

The opaque, immutable, system-generated identity of an observation, assigned on [Record], never reused or reassigned within the store instance. The clinical content is a property of the observation, not its identity.

Kind:       Field
Field of:   Observation
Projection: observation_id

#### Subject Ref

The opaque, globally-scoped reference to the subject the observation is about. Set on [Record], immutable, and inherited unchanged by any successor across an amendment chain (Invariant 4).

Kind:       Field
Field of:   Observation
Projection: subject_ref

#### Recorded By

The opaque reference to the observer who performed the measurement. Set on [Record], immutable; an amendment carries its own [Amended By] and never changes the original [Recorded By].

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

The unit of measure for the [Value], a non-empty opaque string. Set on [Record], immutable on its record; terminology standardization (UCUM) is a deployment convention.

Kind:       Field
Field of:   Observation
Projection: unit

#### Recorded At

The wall-time the observation was recorded — supplied to [Record] or defaulted from the receiving node's wall clock; must not be future-dated. Set once (Invariant 8), immutable. A successor carries its own [Recorded At] (when the correction was entered), not the original measurement time.

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

#### Amended By

The opaque reference to the observer who made a correction — set on the successor at [Amend] time, immutable thereafter.

Kind:       Field
Field of:   Observation
Projection: amended_by

#### Amendment Reason

The required, non-empty reason for a correction — set on the successor at [Amend] time, immutable thereafter. A blank reason defeats the audit trail and is rejected.

Kind:       Field
Field of:   Observation
Projection: amendment_reason

#### Retracted By

The opaque reference to the observer who withdrew an observation — set at [Retract] time, immutable thereafter (Invariant 9).

Kind:       Field
Field of:   Observation
Projection: retracted_by

#### Retraction Reason

The required, non-empty reason for a retraction — set at [Retract] time, immutable thereafter. A blank reason is rejected.

Kind:       Field
Field of:   Observation
Projection: retraction_reason

#### Store Name

The identifier of the store instance an observation belongs to. Multiple instances coexist; [Observation Id]s are unique within an instance, while [Subject Ref] is portable across instances. No action accepts it as a parameter — instance selection is handled at the deployment-routing layer.

Kind:       Field
Field of:   the store instance
Projection: store_name

#### Reason

The required, non-empty reason string [Amend] and [Retract] consume — written into [Amendment Reason] or [Retraction Reason] respectively. Not stored under this name; an empty or whitespace-only value is rejected [Invalid Request].

Kind:         Parameter
Parameter of: Amend
Projection:   reason

#### Query

The selection [Read] consumes — a filter over [Observation Id], [Subject Ref], [Observation Type], time range, and/or [State]. Supplied per call, not stored; a malformed one is rejected [Invalid Query].

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

The terminal state of an observation withdrawn as erroneous. Retained and visible but flagged invalid, carrying [Retracted By] and [Retraction Reason]; no further transition (Invariant 6).

Kind:      Member
Member of: the observation state
Role:      Outcome

#### Invalid Observation

The refusal [Record] (or [Amend]) returns when observation content fails — an empty/whitespace [Subject Ref], [Recorded By], [Observation Type], or [Unit]; a [Value] failing the per-type constraint; an [Observation Type] with no declared constraint; or a future-dated [Recorded At].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-observation

#### Storage Failure

The refusal any writing action returns when a durable write fails after preconditions pass. All-or-none: no partial record is observable (Invariant 7).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

#### Not Known

The refusal [Amend] or [Retract] returns when the named [Observation Id] references no record in this store instance — a lookup miss (a common cause is cross-instance referencing).

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

The refusal [Amend] or [Retract] returns when request metadata fails — an empty or whitespace-only [Amended By], [Retracted By], or [Reason].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Invalid Query

The refusal [Read] returns when query parameters are malformed — a time range with end before start, an unrecognized state value, or a syntactically invalid [Observation Id].

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
[Subject Ref]: #subject-ref
[Recorded By]: #recorded-by
[Observation Type]: #observation-type
[Value]: #value
[Unit]: #unit
[Recorded At]: #recorded-at
[State]: #state
[Predecessor Id]: #predecessor-id
[Successor Id]: #successor-id
[Amended By]: #amended-by
[Amendment Reason]: #amendment-reason
[Retracted By]: #retracted-by
[Retraction Reason]: #retraction-reason
[Store Name]: #store-name
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

- **HIPAA §164.312(b)** — audit controls: covered entities must implement hardware, software, and procedural mechanisms to record and examine activity in information systems that contain ePHI (electronic Protected Health Information — individually identifiable health data in digital form). The observation record, with its immutable [Recorded By] and [Recorded At], is the primary audit surface.
- **HL7 FHIR (Health Level 7 Fast Healthcare Interoperability Resources — a standard for exchanging healthcare information) Observation resource** — the canonical interoperability representation of a clinical observation; this atom's core fields map to FHIR Observation's `subject` ([Subject Ref]), `performer` ([Recorded By]), `value[x]` ([Value] + [Unit]), `issued` ([Recorded At]), and `status` (final → [Recorded], amended → [Amended], cancelled → [Retracted]). FHIR's `code` field is a CodeableConcept (LOINC or SNOMED CT), not an opaque string — this atom deliberately defers terminology binding to deployment convention. FHIR carries many additional fields (category, encounter, bodySite, interpretation, referenceRange) not present here; those are composing-layer concepts.
- **21 CFR (Code of Federal Regulations — the codification of US federal agency rules) Part 11** — electronic records in FDA-regulated (US Food and Drug Administration) clinical trials; each observation is a regulated electronic record requiring attribution, timestamp, and amendment trail.
- **Joint Commission Record of Care standards** — require that corrections to medical records be dated, timed, and attributed; the amendment model satisfies this directly.
- **IHE PCC (Integrating the Healthcare Enterprise — Patient Care Coordination)** — the Clinical Document Architecture (CDA) and FHIR-based profiles that govern how observations are exchanged across care settings.
- **SNOMED CT / LOINC / UCUM** — controlled vocabularies for [Observation Type] and [Unit]; recommended deployment conventions, not atom-level obligations.

---

## Status

`grounded on Final Critique 4 — 2026-05-20` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-05-20
formal: verified — observation.als + 1 twin, 2026-06-03
last gate: 2026-05-20 — Final Critique 4, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/clinical-observation.md`.

- **2026-08-30 — One writer per transition, and no repair leg.** *Chose:* transactional atomicity as the only conforming implementation of [Amend]'s two writes, the crash-recovery scan withdrawn; the per-id serialization stated as a critical section with its semantics — taken before the state check, released on return or death, a lease's expiry the invocation's terminus, a stalled invocation re-reading the state under the critical section and landing [Already Amended]; a deployment-declared clock_offset_allowance under which the future-dated check on a caller-supplied [Recorded At] runs. *Over:* a scan "that detects and repairs dangling amendment links on restart" offered as an equal alternative to a transaction, beside a caller told to read the original and retry; a future-dated refusal decided by comparing the caller's stamp to the node's clock with no margin. *Because:* the scan presumed a visible partial record that Invariant 7 says never exists, could relink one dangling shape but not the other — the successor's content is nowhere in the store, and un-marking the original rewrites a write-once field — and made a second writer for an act the caller's retry could already have landed; and a caller's stamp and the node's reading are two clocks, so a refusal resting on their comparison needs the margin on the page (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *A stamp from another seam never decides a write alone* — with *Recovery commits under a declared service identity … and what cannot be re-derived is re-run*, frozen 2026-08-29).

- **2026-09-13 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the four actions as a signature block, Invariant 1 through 9 keeping their numbers, every success effect conditioned on a declared admitted record, admitted amend, admitted retract or admitted read (Hard invariant 16), [Amend] and [Retract] unified under a declared chain action so their shared guards are stated once, the per-action *rejection priority* paragraph collapsed to one seven-row case space, the arithmetic in `recorded_at ≤ now + clock_offset_allowance` routed through a declared future bound so no rule carries a sum (Closed vocabulary 9), the five acceptance areas opened into `Check 1.1 through 6.1` with four `External check`s, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 22` family and four edge-case families. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into clinical-observation` found nothing citing this atom by label. 61.2 KB → 60.7 KB, the smallest reduction of the migration — this atom's prose carried almost no restatement, and what came out was one repeated precedence paragraph.

- **2026-09-13 — The value constraint is the deployment's, and the refusal is the atom's.** *Chose:* `Operation 5` — an observation_type carrying no declared value constraint is refused — with `Non-goal 1` and `Non-goal 2` stating the division from both ends. *Over:* accepting an unknown type unchecked, which is what most record stores do. *Because:* what counts as a valid systolic pressure or pain score is clinical and local, so an atom that defined one would be specified against a single care setting, and an atom that accepted a type it could not check would have a per-type integrity guarantee in name only. A deployment adds a measurement by declaring what a valid value for it looks like first. This is the corpus's first bounds entry whose *value* is entirely the deployment's while its *existence* is normative.

- **2026-09-13 — Inheritance by construction, stated as the absence of a parameter.** *Chose:* `Operation 21`, `Operation 22` and `Operation 23` — [Amend] accepts no subject_ref, no observation_type and no recorded_at — with `Invariant 4` and `Invariant 5` resting on them. *Over:* runtime checks that a successor matches its original. *Because:* a check catches divergence and a missing parameter makes it unrepresentable, and the second is the stronger guarantee. The consequence is the atom's most-questioned friction and it is deliberate: a clinician who charted the wrong measurement type is not correcting a value, they recorded something that did not happen, which retraction says and amendment does not.

- **2026-09-13 — The only atom that forbids repair-later.** *Chose:* `Invariant 7.3` and `Atomic writes 4` — no reader may observe a partial record once a crash has landed, and the implementation MUST NOT repair a dangling amend. *Over:* the crash-recovery scan every other store in the corpus is permitted. *Because:* the partial record is visible between the crash and the repair, which is the state Invariant 7.3 says never exists — and one of the two dangling shapes cannot be repaired at all, because an original marked amended with a successor_id naming no record has lost the successor's value, unit, clinician and reason entirely, and un-marking it would rewrite a write-once field (`Invariant 9.1`).

- **2026-09-13 — Renamed from Clinical Observation; the domain was in the name, not the concept.** *Chose:* `Observation`, with `patient_ref` renamed subject_ref and the clinician vocabulary neutralized wherever it was definitional. *Over:* holding the name, and over `Superseding Record` and `Amendment Chain`, which name the invariant more precisely and read less naturally. *Because:* `atoms/TAXONOMY.md` had flagged this atom as the corpus's masquerade candidate since 2026-06-08 — a neutral concept dressed in domain clothes — and gated the judgment on the EOS strip test rather than on taste. The GRACE migration made the test decidable. Of 173 labelled rules, **not one carries a clinical semantic**: value, unit and observation_type are opaque (Identity 14, Identity 15), the atom is forbidden to interpret a value (Non-goal 4) or confirm one correct (Non-goal 5), and what counts as valid is entirely the deployment's (Non-goal 1, Operation 5). Strip the setting and what remains is an amendable, attributed, retractable measurement record — equally a vital sign, an assay, an instrument reading, a financial mark. The two domain-flavoured identifiers were opaque references, and renaming one of them removed the last of it. `Medication Order` stays tagged `domain: healthcare` and earned it — its guards are irreducibly clinical and no census can count them away. The calibration the maintainer set is visible in what did *not* change: the worked example keeps its nurse and its blood pressure, and the Standards references keep their healthcare anchors, because those are illustration and evidence rather than framing. Neutral where the text is definitional, concrete where it is illustrative.

NOTE: End of Observation.
