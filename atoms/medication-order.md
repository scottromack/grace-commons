---
title: Medication Order
domain: healthcare
parent: Atomic Concepts
has_toc: true
toc: true
---

# Medication Order

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Medication Order records the whole life of a prescription, from the moment a prescriber places it to its end. The order names the drug, the patient, the [Dose], the [Route], the [Frequency] and the [Duration], then moves through a regulated chain of custody: a pharmacist verifies it before anything is dispensed, a dispenser releases the medication, a nurse or the patient administers it, and the course completes or is stopped — with the actor at every step permanently recorded.

The guarantee is that the chain is unchangeable and complete: no step silently skipped, no actor silently omitted, no record altered afterwards. The drug, dose, route and frequency are fixed when the order is placed. A correction *before* dispensing creates a successor order, which must be verified afresh; a correction *after* dispensing requires stopping the order and placing a new one, because the physical medication has already left the pharmacy.

An order stands in exactly one of nine states, with a reversible hold for a surgical pause or an interaction review. The line between an order cancelled before any drug was dispensed and one discontinued after is enforced structurally, because it is the line controlled-substance accounting turns on.

---

## Intent

A prescriber — a physician, a nurse practitioner, a physician assistant, or an authorized clinical system — places an order specifying what drug to give, to whom, in what dose and form, by what route, on what schedule and for how long. That prescription drives a chain of custody, and at every step the actor who acts is permanently attributed.

Three clinical requirements run at once. The record must be faithful to what was ordered — medication, dose, route and frequency are fixed at order time, and errors are corrected by explicit amendment or explicit termination, never by silent edit. Every role in the chain must survive adversarial scrutiny: a DEA controlled-substance audit, a wrong-medication dispute, a diversion investigation. And the amendment boundary at dispensing is load-bearing, because a dose change before the pharmacy has acted is a correction, while a change after the medication has left is a new prescription.

This atom models the full lifecycle as one record rather than decomposing it the way HL7 FHIR does across MedicationRequest, MedicationDispense and MedicationAdministration. That decomposition serves interoperability between independently operated systems; this one prioritizes a single auditable chain of custody inside a deployment. Dispensing and administration here are transitions on the order, not freestanding entities — they carry no state machines of their own and are meaningful only against the order they act on. The case for separating them does not arise until a second pattern in the library needs generic material-issuance semantics — blood products, implants, durable equipment — independent of a prescription.

This is a freestanding atom in the EOS sense: its own state, its own ten writes and one read, and its own invariants. Access control, cryptographic non-repudiation, retention, tamper-evidence and DEA reporting are composing patterns. The atom imposes no clinical semantics on what the medication *is*; it imposes the structural guarantee that the record is faithful to what was prescribed, by whom, and how it was fulfilled.

---

## Structure

### Identity model

```
Identity 1: The atom MUST identify an order by the order_id.
Identity 2: The atom MUST assign the order_id from the id material the seam supplies.
Identity 3: The atom MUST NOT generate an order_id.
Identity 4: The atom MUST NOT change an order's order_id.
Identity 5: Two orders in one store instance MUST NOT share an order_id.
Identity 6: The atom MUST NOT reuse a resolved order's order_id.
Identity 7: The atom MUST NOT identify an order by a core field.
Identity 8: The atom MUST compare a reference byte-exactly.
Identity 9: The atom MUST NOT normalize a reference.
Identity 10: The atom MUST NOT confirm that a patient_ref names a known patient.
Identity 11: The atom MUST NOT confirm that a medication_ref names a known medication.
Identity 12: The atom MUST NOT confirm that an attribution reference names a known actor.
Identity 13: The atom MUST NOT read a medication_ref's clinical meaning.
Identity 14: The deployment MUST route EVERY call to one store instance.
Identity 15: The atom MUST NOT resolve an order_id across two store instances.
```

Term order: the record this atom holds — one prescription's whole life, from placement to its end.

Term order_id: the opaque value naming one order — an [Order Id]; assigned from the id material the seam supplies, unique within one store instance.

Term store instance: one named order store a call is routed to, named by a `store_name`; `order_id` uniqueness ranges over one instance, and a `patient_ref` may appear in several.

Term core field: `patient_ref` | `prescriber_ref` | `medication_ref` | `dose` | `dose_unit` | `route` | `frequency` | `duration` | `clinical_evidence_ref` | `ordered_at` — what an order carries from placement and never changes.

Term dosing parameter: `dose` | `dose_unit` | `route` | `frequency` | `duration` — the core fields an amendment may correct on a successor.

Term attribution reference: `prescriber_ref`, `amended_by`, `verifier_ref`, `held_by`, `reinstated_by`, `dispenser_ref`, `administerer_ref`, `completed_by`, `cancelled_by` OR `discontinued_by` — the reference each action records for who acted.

Term reference: `order_id`, `patient_ref`, `medication_ref`, `clinical_evidence_ref`, an attribution reference, `predecessor_id` OR `successor_id` — every opaque reference this atom records.

Term seam: the atom's I/O boundary as `execution-contract.md` Logic confinement declares it; the host injects the clock reading, the id material and the clock_offset_allowance here.

Term transition: the atom's evaluation of one call against the order store, as `execution-contract.md` Logic confinement declares it.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

WHY:
Identity 11 and Identity 13 are the atom's sharpest refusal, and the one a clinical reader expects to find broken. This spec never reads what a `medication_ref` *means* — not its schedule, not its interactions, not its formulary status — which is why it can be one atom rather than a pharmacopoeia. What it guarantees is that the reference recorded at placement is the reference on every record downstream, and Invariant 2.1 makes changing it structurally impossible rather than merely refused: [Amend] does not take a `medication_ref` at all.

Identity 15 is the store-instance boundary stated as a refusal. Instances exist per health system, facility, department or care team, and an `order_id` means nothing outside the one it was assigned in; a `patient_ref` is the thing that spans them, which is why it is not this atom's identity (Identity 7).

### State

```
State 1: EVERY order MUST carry order_id, EVERY core field the call supplied and a state.
State 2: EVERY verified order MUST carry verifier_ref and verified_at.
State 3: EVERY dispensed order MUST carry dispenser_ref, quantity and dispensed_at.
State 4: A dispensed order MAY carry a lot_number.
State 5: EVERY administered order MUST carry administerer_ref and administered_at.
State 6: EVERY completed order MUST carry completed_by and completed_at.
State 7: EVERY cancelled order MUST carry cancelled_by, cancellation_reason and cancelled_at.
State 8: EVERY discontinued order MUST carry discontinued_by, discontinuation_reason and discontinued_at.
State 9: EVERY amended order MUST carry a successor_id.
State 10: EVERY successor order MUST carry predecessor_id, amended_by and amendment_reason.
State 11: EVERY on-hold order MUST carry prior_state, held_by, hold_reason and held_at.
State 12: EVERY reinstated order MUST carry reinstated_by and reinstated_at.
State 13: An order MUST carry EVERY field group a prior transition wrote.
State 14: The atom MUST NOT offer a purged state.
State 15: The store instance's order count MUST NOT fall.
```

WHY:
State 13 is what makes a completed order legible. Field groups accumulate and never fall away, so a completed order carries its verification, its dispense and its administration alongside its completion, and an on-hold order carries everything the state under the hold had written. A [State] is the only field that moves; every group beneath it accumulates. An auditor reading one record reads the whole chain of custody without joining anything.

State 14 says the absence plainly. There is no purge here and no delete surface at all; retention and eventual destruction are [Retention Window](./retention-window.md)'s and [Legal Hold](./legal-hold.md)'s, and this atom's contract is that it never removes what it wrote (Invariant 14.1).

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the id material at the seam.
Capability requirement 3: The deployment MUST declare the clock_offset_allowance.
Capability requirement 4: The deployment MUST supply the clock_offset_allowance at the seam.
Capability requirement 5: The store instance MUST serialize two order actions naming one order_id.
Capability requirement 6: The store instance MUST NOT evaluate the state check BEFORE taking the section.
Capability requirement 7: The store instance MUST release the section on the caller's return.
Capability requirement 8: The store instance MUST release the section on the caller's death.
Capability requirement 9: The store MUST acknowledge a write ONLY IF the write commits.
Capability requirement 10: The store MUST commit an admitted amend's two writes together.
Capability requirement 11: The deployment MUST canonicalize an opaque reference.
Capability requirement 12: The deployment MUST declare the length bound.
Capability requirement 13: The deployment MUST own the clock's skew.
Capability requirement 14: The deployment MUST own the clock's monotonicity.
```

WHY:
Capability requirement 5 through 8 are the concurrency contract stated as the section it needs, not as an ambient hope. Two systems verifying one order, or a dispense racing a concurrent verification, resolve by serialization rather than by this atom detecting the race — and the section must be *taken before the state check*, because a check evaluated outside it reads a state another caller is already leaving.

Capability requirement 3 and Capability requirement 4 are one value declared and then injected. The future-dated refusal on a supplied `ordered_at` compares a caller's stamp against this node's reading, and those are two clocks; without a declared margin the refusal rests on their agreement, which is not something either side can promise (Decisions, 2026-08-30).

### Operations

```
order(patient_ref, prescriber_ref, medication_ref, dose, dose_unit, route, frequency, optional duration, optional clinical_evidence_ref, optional ordered_at)
  answers order_id
  refuses invalid-order | storage-failure

amend(order_id, amended_by, optional dose, optional dose_unit, optional route, optional frequency, optional duration, reason)
  answers new_order_id
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-dispensed | invalid-request | storage-failure

verify(order_id, verifier_ref)
  answers verified
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-in-ordered-state | invalid-request | storage-failure

hold(order_id, held_by, reason)
  answers held
  refuses not-known | already-on-hold | already-amended | already-cancelled | already-discontinued | already-completed | invalid-request | storage-failure

reinstate(order_id, reinstated_by)
  answers reinstated
  refuses not-known | not-on-hold | invalid-request | storage-failure

dispense(order_id, dispenser_ref, quantity, optional lot_number, optional dispensed_at)
  answers dispensed
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-verified | already-dispensed | invalid-request | storage-failure

administer(order_id, administerer_ref, optional administered_at)
  answers administered
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-dispensed | already-administered | invalid-request | storage-failure

complete(order_id, completed_by, optional completed_at)
  answers completed
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-administered | invalid-request | storage-failure

cancel(order_id, cancelled_by, reason)
  answers cancelled
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | already-dispensed | invalid-request | storage-failure

discontinue(order_id, discontinued_by, reason)
  answers discontinued
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-dispensed | invalid-request | storage-failure

read(query)
  answers the matching orders
  refuses invalid-query
```

```
Operation 1: IF a required string input NOT EXISTS THEN an action MUST answer a blank-input rejection.
Operation 2: IF the dose NOT EXCEEDS zero THEN [Order] MUST answer invalid-order.
Operation 3: IF a supplied ordered_at EXCEEDS the future bound THEN [Order] MUST answer invalid-order.
Operation 4: IF ordered_at NOT EXISTS THEN [Order] MUST record now as ordered_at.
Operation 5: An admitted order MUST assign a fresh order_id.
Operation 6: An admitted order MUST record EVERY supplied core field.
Operation 7: An admitted order MUST stand the order in ordered.
Operation 8: An admitted order MUST answer the order_id.
Operation 9: [Order] MUST NOT answer not-known.
Operation 10: IF order_id NOT EXISTS THEN an order action MUST answer a blank-input rejection.
Operation 11: IF the order_id names no order THEN an order action MUST answer not-known.
Operation 12: An order action MUST answer not-known ONLY IF order_id EXISTS.
Operation 13: IF the order stands in on-hold THEN a held-refusing action MUST answer on-hold.
Operation 14: IF the order stands in an inactive state THEN a state-changing action MUST answer the inactive state's rejection.
Operation 15: A state-changing action MUST answer an inactive-state rejection ONLY IF the order stands outside on-hold.
Operation 16: IF the order NOT EXISTS in ordered THEN [Verify] MUST answer not-in-ordered-state.
Operation 17: IF the order NOT EXISTS in a pre-dispensing state THEN [Amend] MUST answer already-dispensed.
Operation 18: IF the order NOT EXISTS in a pre-dispensing state THEN [Cancel] MUST answer already-dispensed.
Operation 19: IF the order NOT EXISTS in verified THEN [Dispense] MUST answer not-verified.
Operation 20: IF the order stands in dispensed THEN [Dispense] MUST answer already-dispensed.
Operation 21: IF the order NOT EXISTS in dispensed THEN [Administer] MUST answer not-dispensed.
Operation 22: IF the order stands in administered THEN [Administer] MUST answer already-administered.
Operation 23: IF the order NOT EXISTS in administered THEN [Complete] MUST answer not-administered.
Operation 24: IF the order NOT EXISTS in a post-dispensing state THEN [Discontinue] MUST answer not-dispensed.
Operation 25: IF the order NOT EXISTS in an actionable state THEN [Hold] MUST answer the order's state rejection.
Operation 26: IF the order stands in on-hold THEN [Hold] MUST answer already-on-hold.
Operation 27: IF the order NOT EXISTS in on-hold THEN [Reinstate] MUST answer not-on-hold.
Operation 28: A state-changing action MUST answer a blank-input rejection on a field fault ONLY IF EVERY state check passes.
Operation 29: IF EVERY supplied dosing parameter matches the order's dosing parameter THEN [Amend] MUST answer invalid-request.
Operation 30: [Amend] MUST NOT accept a medication_ref.
Operation 31: [Amend] MUST NOT accept a patient_ref.
Operation 32: [Amend] MUST NOT accept a prescriber_ref.
Operation 33: An admitted amend MUST record a successor order carrying the original's patient_ref, prescriber_ref and medication_ref.
Operation 34: An admitted amend MUST record EVERY supplied dosing parameter on the successor.
Operation 35: An admitted amend MUST record the original's unamended dosing parameter on the successor.
Operation 36: An admitted amend MUST record amended_by and reason as amendment_reason on the successor.
Operation 37: An admitted amend MUST record the original's order_id as the successor's predecessor_id.
Operation 38: An admitted amend MUST stand the successor in ordered.
Operation 39: An admitted amend MUST stand the original in amended.
Operation 40: An admitted amend MUST record the successor's order_id as the original's successor_id.
Operation 41: An admitted amend MUST commit the successor and the original's change in one transition.
Operation 42: An admitted amend MUST answer the successor's order_id.
Operation 43: An admitted verify MUST record verifier_ref and now as verified_at.
Operation 44: An admitted verify MUST stand the order in verified.
Operation 45: An admitted hold MUST record the order's state as prior_state.
Operation 46: An admitted hold MUST record held_by, reason as hold_reason and now as held_at.
Operation 47: An admitted hold MUST stand the order in on-hold.
Operation 48: An admitted reinstate MUST record reinstated_by and now as reinstated_at.
Operation 49: An admitted reinstate MUST stand the order in the order's prior_state.
Operation 50: [Reinstate] MUST NOT accept a target state.
Operation 51: An admitted dispense MUST record dispenser_ref, quantity, a supplied lot_number and the resolved dispensed_at.
Operation 52: An admitted dispense MUST stand the order in dispensed.
Operation 53: An admitted administer MUST record administerer_ref and the resolved administered_at.
Operation 54: An admitted administer MUST stand the order in administered.
Operation 55: An admitted complete MUST record completed_by and the resolved completed_at.
Operation 56: An admitted complete MUST stand the order in completed.
Operation 57: An admitted cancel MUST record cancelled_by, reason as cancellation_reason and now as cancelled_at.
Operation 58: An admitted cancel MUST stand the order in cancelled.
Operation 59: An admitted discontinue MUST record discontinued_by, reason as discontinuation_reason and now as discontinued_at.
Operation 60: An admitted discontinue MUST stand the order in discontinued.
Operation 61: A state-changing action MUST commit the state change and the recorded fields in one transition.
Operation 62: IF the store refuses the write THEN an action MUST answer storage-failure.
Operation 63: An action MUST answer storage-failure ONLY IF EVERY precondition passes.
Operation 64: A refused action MUST leave the order as the call found the order.
Operation 65: A refused [Order] MUST NOT record an order.
Operation 66: A refused [Amend] MUST NOT record a successor order.
Operation 67: The atom MUST NOT offer an order removal surface.
Operation 68: The atom MUST NOT offer a core field update surface.
Operation 69: The atom MUST NOT offer a second dose event surface.
Operation 70: The atom MUST NOT offer a refill surface.
Operation 71: IF a filter axis falls outside the query axes THEN [Read] MUST answer invalid-query.
Operation 72: IF a filter value falls outside the axis's admitted values THEN [Read] MUST answer invalid-query.
Operation 73: An admitted read MUST answer EVERY matching order.
Operation 74: An admitted read MUST answer the matching orders by ordered_at ascending.
Operation 75: An admitted read MUST answer EVERY field group the order carries.
Operation 76: An admitted read MUST answer an empty sequence where no order matches.
Operation 77: [Read] MUST NOT record a field.
Deleted: Operation 78. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 79. `execution-contract.md` §Logic confinement owns it.
```

Term order action: [Amend] | [Verify] | [Hold] | [Reinstate] | [Dispense] | [Administer] | [Complete] | [Cancel] | [Discontinue] — every action naming an order by `order_id`, including a refused one.

Term state-changing action: an order action that would change the order's state — every order action.

Term held-refusing action: an order action beside [Reinstate] — every action an on-hold order refuses.

Term state: `ordered` | `verified` | `amended` | `on-hold` | `dispensed` | `administered` | `completed` | `cancelled` | `discontinued`.

Term terminal state: `completed` | `cancelled` | `discontinued`.

Term inactive state: `amended` | `completed` | `cancelled` | `discontinued` — every state that admits no further transition.

Term pre-dispensing state: `ordered` | `verified`.

Term post-dispensing state: `dispensed` | `administered`.

Term actionable state: a pre-dispensing state OR a post-dispensing state — every state a hold may suspend.

Term inactive state's rejection: `already-amended` for amended, `already-completed` for completed, `already-cancelled` for cancelled, `already-discontinued` for discontinued.

Term state check: Operation 11, Operation 13, Operation 14 and Operation 15 through 26 — every check an order action makes on the order's own standing before reading the call's remaining arguments.

Term blank-input rejection: `invalid-order` for [Order], `invalid-request` for an order action.

Term field fault: a blank required string input beside `order_id`, a non-positive `dose`, a non-positive `quantity`, a supplied `ordered_at` exceeding the future bound, OR an [Amend] whose supplied dosing parameters all match the original.

Term required string input: `patient_ref`, `prescriber_ref`, `medication_ref`, `dose_unit`, `route`, `frequency`, a supplied `clinical_evidence_ref`, a supplied `lot_number`, `reason`, an attribution reference OR `order_id` — every string an action refuses when blank.

Term future bound: `now` raised by the `clock_offset_allowance`.

Term query axes: `order_id`, `patient_ref`, `medication_ref`, `prescriber_ref`, `state` and a range over `ordered_at` — every filter axis [Read] admits.

Term field group: the fields one transition writes, carried on the order from that transition onward.

Term admitted order: an [Order] call that passes every precondition and whose store write commits.

Term admitted amend: an [Amend] call that passes every precondition and whose store writes commit.

Term admitted verify: a [Verify] call that passes every precondition and whose store write commits.

Term admitted hold: a [Hold] call that passes every precondition and whose store write commits.

Term admitted reinstate: a [Reinstate] call that passes every precondition and whose store write commits.

Term admitted dispense: a [Dispense] call that passes every precondition and whose store write commits.

Term admitted administer: an [Administer] call that passes every precondition and whose store write commits.

Term admitted complete: a [Complete] call that passes every precondition and whose store write commits.

Term admitted cancel: a [Cancel] call that passes every precondition and whose store write commits.

Term admitted discontinue: a [Discontinue] call that passes every precondition and whose store write commits.

Term admitted read: a [Read] call that answers.

WHY:
Operation 12, Operation 15, Operation 28 and Operation 63 are the rejection priority, written as guards rather than as an order (GRACE-lang Timing 13): [Not Known] before the on-hold rejection before an inactive-state rejection before a state-specific one before [Invalid Request] before [Storage Failure]. The placement of `on-hold` second is the reason the family exists — a held order refuses everything but [Reinstate], and a caller must learn that the order is held rather than learn something about the state underneath the hold.

Operation 17 and Operation 18 are the atom's clinical boundary, and they are one proposition wearing two rejections. Both refuse across the dispensing edge and both answer `already-dispensed`, because the fact that ends the conversation is the same: the medication has left the pharmacy. What differs is the remedy — [Amend] gives way to a fresh order, [Cancel] gives way to [Discontinue] — and the mirror rule answers [Not Dispensed] when [Discontinue] is called on the near side.

Operation 30 through 32 make a class of error unrepresentable rather than refused. An amendment cannot change the drug, the patient or the prescriber, and the mechanism is that [Amend] has no parameter for any of them; a caller who needs a different medication cancels and re-orders. That is Invariant 2.1 by construction, which is a stronger guarantee than a runtime check and is why no rule refuses it.

Operation 50 is the same move on [Reinstate]. The action takes no target state, so a hold can only resume where it paused, and deviation from `prior_state` is structurally impossible rather than guarded.

Operation 69 and Operation 70 are the two absences a clinical reader arrives expecting. A second dose against one order and a refill against one prescription are both real, both common, and both outside this record — the first is a dose-event pattern composing on top, the second is a new order or a layer above. Modelling either here would put a regimen's bookkeeping inside the prescription primitive.

Logic confinement is the Contract's (`execution-contract.md` §Logic confinement), and the `now` declaration cites it rather than restating it.

### Invariants

- **Invariant 1 — Order immutability.**
  ```
  Invariant 1.1: An action MUST NOT change a core field.
  ```
- **Invariant 2 — The successor inherits the identity fields.**
  ```
  Invariant 2.1: EVERY successor order MUST carry the original's patient_ref, prescriber_ref and medication_ref.
  ```
  WHY: by construction rather than by guard — [Amend] takes none of the three (Operation 30 through 32), so divergence is unrepresentable. `amended_by` records who made the correction; prescribing authorship stays with the original prescriber, which is why `prescriber_ref` is inherited rather than replaced.
- **Invariant 3 — Amendment is pre-dispensing only.**
  ```
  Invariant 3.1: [Amend] MUST answer a rejection ONLY IF the order NOT EXISTS in a pre-dispensing state.
  ```
  WHY: one of the two rules that carry this atom's domain. An order that has crossed the dispensing edge is corrected by discontinuing and re-ordering, because the medication is in someone else's custody and a record that edited itself would describe a bottle that does not exist.
- **Invariant 4 — Amendment chains are linear.**
  ```
  Invariant 4.1: An order MUST NOT carry two successor_ids.
  Invariant 4.2: An order MUST NOT carry two predecessor_ids.
  ```
- **Invariant 5 — A hold resumes where it paused.**
  ```
  Invariant 5.1: An admitted reinstate MUST stand the order in the prior_state the hold recorded.
  ```
- **Invariant 6 — Cancel is pre-dispensing; discontinue is post-dispensing.**
  ```
  Invariant 6.1: [Cancel] MUST answer a rejection ONLY IF the order NOT EXISTS in a pre-dispensing state.
  Invariant 6.2: [Discontinue] MUST answer a rejection ONLY IF the order NOT EXISTS in a post-dispensing state.
  ```
  WHY: the second rule carrying the domain, and the reason the two terminals are named differently rather than folded into one *stopped*. A cancelled order means the medication never reached the patient; a discontinued one means it was dispensed or administered and then stopped. Those are different facts for pharmacy accounting, for DEA controlled-substance reconciliation and for an adverse-event investigation, and a single terminal would make them indistinguishable in exactly the record an investigator reads.
- **Invariant 7 — A terminal state is absorbing.**
  ```
  Invariant 7.1: An order standing in a terminal state MUST NOT leave the terminal state.
  ```
- **Invariant 8 — An amended order is inactive.**
  ```
  Invariant 8.1: An order standing in amended MUST NOT leave amended.
  ```
- **Invariant 9 — An on-hold order admits only a reinstate.**
  ```
  Invariant 9.1: A held-refusing action MUST answer on-hold against an order standing in on-hold.
  ```
- **Invariant 10 — Attribution is complete.**
  ```
  Invariant 10.1: EVERY attribution reference an order carries MUST carry a non-whitespace character.
  ```
  WHY: attribution is the non-repudiation property every adversarial scenario below turns on, and a blank actor reference defeats all of them at once. The rule is stated over what the order *carries* rather than over what an action accepts, so it holds of the record an auditor reads rather than of the call that made it.
- **Invariant 11 — A reason is complete.**
  ```
  Invariant 11.1: EVERY reason field an order carries MUST carry a non-whitespace character.
  ```
- **Invariant 12 — Transition metadata is write-once within its cycle.**
  ```
  Invariant 12.1: An action MUST NOT change a field group a prior transition wrote.
  Invariant 12.2: An admitted hold MUST replace EVERY hold field.
  Invariant 12.3: An admitted reinstate MUST replace EVERY reinstate field.
  ```
  WHY: the two exceptions are one fact — an order may be held and reinstated more than once, and the record carries the most recent cycle. Each individual hold writes its fields once and they stand until the next hold; the full history is a composing [Event Log](./event-log.md)'s (Non-goal 20). Calling that immutability would be a lie and calling it mutability would be a worse one, so the rules name the cycle.
- **Invariant 13 — The placement instant is set once.**
  ```
  Invariant 13.1: An action MUST NOT change an order's ordered_at.
  Invariant 13.2: EVERY successor order MUST carry the successor's own ordered_at.
  ```
- **Invariant 14 — Order store durability.**
  ```
  Invariant 14.1: The atom MUST NOT remove an order from the store.
  Invariant 14.2: A storage-failure rejection MUST leave no partial record in the store.
  Invariant 14.3: The implementation MUST NOT repair a partial record.
  ```
  WHY: Invariant 14.3 is a rejected remedy stated as a rule, and it was reached the hard way (Decisions, 2026-08-30). A crash-recovery scan that repairs dangling amendments is not an acceptable substitute for a transaction: between the crash and the repair the partial record is visible, which is the state Invariant 14.2 says never exists. And one of [Amend]'s two dangling shapes cannot be repaired at all — a successor written without the original's `successor_id` can be relinked, but an original marked `amended` whose successor never landed has nowhere to get the successor's dosing parameters, `amended_by` and `amendment_reason` from, and un-marking it would rewrite a write-once field.

---

## Examples

### Inpatient order through completion

`order(p77, dr_osei, med-lisinopril-10mg, 10, "mg", "oral", "QD", 30)` → `ord_a1`, standing ordered. `verify(ord_a1, rph_chen)` → verified. `dispense(ord_a1, tech_ruiz, 30, "LOT-4471")` → dispensed. `administer(ord_a1, rn_patel)` → administered, stamping [Administered At]. `complete(ord_a1, rn_patel)` → completed. The completed record carries all five field groups at once, and an auditor reads the whole chain — who prescribed, who verified, who released, who gave, who closed — from that one record.

### Amendment before dispensing

The dose is wrong. `amend(ord_a1, dr_osei, dose: 20, reason: "titration per 2026-05-02 BP readings")` → `ord_a2`, the reason recorded as the successor's [Amendment Reason]. Two writes commit together: `ord_a2` stands ordered carrying the corrected dose, the inherited patient, prescriber and medication, and `predecessor_id: ord_a1`; and `ord_a1` stands amended carrying `successor_id: ord_a2`. The successor starts in ordered rather than verified — the clinical content changed, so the pharmacist reviews it again.

### Hold and reinstate

`hold(ord_a1, rn_patel, "NPO for surgery 06:00")` → held, recording `prior_state: dispensed`. Every action but [Reinstate] now answers `on-hold`. `reinstate(ord_a1, rn_patel)` → reinstated, recording [Reinstated By] and [Reinstated At] and returning the order to dispensed — the action takes no target state, so it cannot return it anywhere else.

### The dispensing edge, from both sides

`amend(ord_disp, …)` on a dispensed order → `already-dispensed`; the remedy is [Discontinue] and a fresh order. `cancel(ord_disp, …)` → `already-dispensed`; the remedy is [Discontinue]. And from the near side, `discontinue(ord_new, …)` on an order still standing in ordered → `not-dispensed`; the remedy is [Cancel]. Three refusals, one edge, and the edge is where the medication left the pharmacy.

### Rejection paths

`dispense(ord_new, …)` before verification → `not-verified` — nothing is released on a prescription no pharmacist has read. `amend(ord_held, …)` → the [On Hold Rejection], not `already-dispensed`: the hold is reported first, because the caller must resolve the hold before learning anything about what is underneath it. `amend(ord_a1, dr_osei, dose: 10, reason: "…")` where the dose already is 10 → `invalid-request` — an amendment that changes nothing is not an amendment. `cancel(ord_a1, "  ", reason: "…")` on an already-cancelled order → `already-cancelled`, not `invalid-request`: the state checks run first (Operation 28).

### Regulated adversarial scenarios

- **DEA controlled-substance audit.** *Account for every unit of this schedule II drug.* Filter by [Medication Ref] and read each order's terminal: a cancelled order means nothing was released, a discontinued one means something was and the course stopped, a completed one means the full course was given. Invariant 6.1 and Invariant 6.2 are what make that distinction structural rather than a matter of how the reason was worded.
- **Wrong-medication dispute.** *The patient received the wrong drug.* `medication_ref` is fixed at placement and inherited unchanged by every successor (Invariant 2.1), and [Amend] cannot take one, so no order in the chain can name a drug the prescriber did not order. The dispute resolves to whether the right order was acted on, not to whether the record was edited.
- **Diversion investigation.** *Who touched this medication?* Every transition records its actor — the [Administerer Ref] on the dose, the [Dispenser Ref] on the release — no attribution may be blank (Invariant 10.1), and no record is removed (Invariant 14.1). The chain from prescriber to whoever closed the order is on one record, under one [Patient Ref]; what the atom cannot prove is that the store was not rewritten underneath it, which is [Tamper Evidence](./tamper-evidence.md)'s (External check 4).

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the order store alone, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY order standing in EXACTLY ONE OF the states (State 1).
Check 1.2: An auditor MUST find no order standing outside a terminal state on a later read of an order a prior read found in that terminal state (Invariant 7.1).
Check 1.3: An auditor MUST find no order standing outside amended on a later read of an order a prior read found amended (Invariant 8.1).
Check 2.1: An auditor MUST find a re-read order's core fields unchanged (Invariant 1.1).
Check 2.2: An auditor MUST find EVERY successor order carrying the original's patient_ref, prescriber_ref and medication_ref (Invariant 2.1).
Check 2.3: An auditor MUST find no order carrying two successor_ids (Invariant 4.1).
Check 2.4: An auditor MUST find no order carrying two predecessor_ids (Invariant 4.2).
Check 2.5: An auditor MUST find a successor_id naming an order on EVERY amended order (State 9).
Check 2.6: An auditor MUST find a predecessor_id naming an order on EVERY successor order (State 10).
Check 3.1: An auditor MUST find no amended order that was dispensed (Invariant 3.1).
Check 3.2: An auditor MUST find no cancelled order carrying a dispense field group (Invariant 6.1).
Check 3.3: An auditor MUST find a dispense field group on EVERY discontinued order (Invariant 6.2).
Check 4.1: An auditor MUST find a non-whitespace character in EVERY attribution reference an order carries (Invariant 10.1).
Check 4.2: An auditor MUST find a non-whitespace character in EVERY reason field an order carries (Invariant 11.1).
Check 5.1: An auditor MUST find verifier_ref and verified_at on EVERY dispensed order (State 2, State 13).
Check 5.2: An auditor MUST find a dispense field group on EVERY administered order (State 3, State 13).
Check 5.3: An auditor MUST find an administration field group on EVERY completed order (State 5, State 13).
Check 5.4: An auditor MUST find EVERY field group a prior transition wrote on a re-read order (State 13, Invariant 12.1).
Check 6.1: An auditor MUST find prior_state, held_by, hold_reason and held_at on EVERY on-hold order (State 11).
Check 7.1: An auditor MUST find no order absent from a later read (Invariant 14.1).
Check 7.2: An auditor MUST find the store instance's order count no lower on a later read (State 15).
Check 7.3: An auditor MUST find no partial record in the store (Invariant 14.2).
Check 8.1: An auditor MUST find no order_id on two orders of one store instance (Identity 5).
Check 8.2: An auditor MUST reconstruct EVERY order's chain of custody from one read (State 13).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing an amendment chain's full hold history MUST read the composing [Event Log](./event-log.md) (Invariant 12.2, Non-goal 20).
External check 2: A deployment needing a second dose event recorded MUST read the composing dose-event pattern (Operation 69, Non-goal 12).
External check 3: A deployment needing a caller authorized MUST read the composing [Permissions](./permissions.md) (Non-goal 15).
External check 4: A deployment needing the store confirmed free of a retroactive edit MUST read the composing [Tamper Evidence](./tamper-evidence.md) (Non-goal 18).
External check 5: A deployment needing a medication_ref's controlled-substance schedule MUST read the composing formulary (Identity 13, Non-goal 17).
External check 6: A deployment needing a duplicate order prevented MUST read the composing [Duplicate Prevention](./duplicate-prevention.md) (Non-goal 9).
External check 7: A deployment needing an order's retention bounded MUST read the composing [Retention Window](./retention-window.md) (Non-goal 22).
External check 8: A deployment needing an attribution reference bound to an actor MUST read the composing [Actor Identity](./actor-identity.md) attestation (Identity 12, Non-goal 13).
```

WHY:
External check 4 is the boundary that most looks like this atom's central claim and is not it. Immutability here is a property of the specified surface: no action changes a core field, and no action removes a record. It is not a cryptographic guarantee, and a store administrator with write access can rewrite anything. The DEA's non-alteration requirement is met at the layer [Tamper Evidence](./tamper-evidence.md) provides, and saying so is the difference between a gap and a disclosed boundary.

External check 5 follows from Identity 13. This atom never reads what a `medication_ref` means, so it cannot know that an order is for a scheduled substance, and every obligation that attaches to one — registration, two-factor prescribing, refill limits, quantity caps — is outside it. An atom that knew would need a pharmacopoeia inside it and would stop being one atom.

---

## Non-goals

```
Non-goal 1: The atom MUST NOT change a medication_ref.
Non-goal 2: A deployment needing a different medication MUST place a new order.
Non-goal 3: The atom MUST NOT amend an order across the dispensing edge.
Non-goal 4: The atom MUST NOT read a dosing parameter's clinical safety.
Non-goal 5: The atom MUST NOT read a drug interaction.
Non-goal 6: The atom MUST NOT read an allergy.
Non-goal 7: A deployment needing clinical decision support MUST compose a decision-support pattern.
Non-goal 8: The atom MUST NOT answer a repeated [Order] with one order.
Non-goal 9: A deployment needing an idempotent order MUST compose [Duplicate Prevention](./duplicate-prevention.md).
Non-goal 10: The atom MUST NOT offer an entered-in-error state.
Non-goal 11: The atom MUST NOT record a second dose event.
Non-goal 12: A deployment needing a dose schedule MUST compose a dose-event pattern.
Non-goal 13: The atom MUST NOT bind an attribution reference to an actor.
Non-goal 14: A deployment needing a non-repudiable transition MUST compose [Actor Identity](./actor-identity.md).
Non-goal 15: The atom MUST NOT decide who may call an action.
Non-goal 16: A deployment needing an authorization decision MUST compose [Permissions](./permissions.md).
Non-goal 17: The atom MUST NOT read a medication_ref's regulatory schedule.
Non-goal 18: The atom MUST NOT detect a rewrite under the store.
Non-goal 19: The atom MUST NOT record a transition history.
Non-goal 20: A deployment needing the full hold history MUST compose [Event Log](./event-log.md).
Non-goal 21: The atom MUST NOT model a refill.
Non-goal 22: The atom MUST NOT bound an order's retention.
Non-goal 23: The atom MUST NOT record an answer the atom gave.
Non-goal 24: The atom MUST NOT guarantee that an order reaches a terminal state.
Non-goal 25: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

WHY:
Non-goal 4 through 7 are the refusal a clinical reader least expects and the one that keeps this atom small. Nothing here knows whether 10 mg is a reasonable dose, whether the drug interacts with another on the patient's list, or whether the patient is allergic to it. Every one of those is a judgment about a medication this atom holds only as an opaque reference, and building any of them in would require the atom to know what the drug *is*.

Non-goal 10 is worth stating because a clinical system usually has that state. An order placed by mistake — wrong patient, duplicate submission, system glitch — is cancelled with a reason that says so, and the `cancellation_reason` carries the difference between a clinical decision and a clerical one. A separate state would split the pre-dispensing terminal in two and make every downstream count ask which of the two it meant.

Non-goal 24 is the honest limit. An open-ended order — one placed with no `duration` — stands active until someone completes or discontinues it, and nothing here makes that happen.

---

## Edge cases

### Atomic writes

```
Atomic writes 1: The implementation MUST commit a transition whole.
Atomic writes 2: The implementation MUST discard an uncommitted transition whole.
Atomic writes 3: The implementation MUST own the transactional boundary.
Atomic writes 4: The implementation MUST commit an admitted amend's two writes in one transaction of the atom's own store.
Atomic writes 5: A refused amend MUST leave the original in the original's pre-call state.
```

WHY:
Atomic writes 4 names the store the transaction spans, and the words are load-bearing. [Amend] writes two records — a successor, and the original's transition to amended — and a crash between them leaves one of two shapes. A successor with no back-link can be relinked; an original marked amended whose successor never landed cannot be, because the successor's dosing parameters, `amended_by` and `amendment_reason` exist nowhere in the store to recover, and un-marking the original would rewrite a write-once field. That is why Invariant 14.3 forbids the repair rather than offering it as an alternative.

### Clock semantics

```
Clock semantics 4: The atom MUST bound a supplied ordered_at from above by the future bound.
Deleted: Clock semantics 3. Operation 4 owns it for ordered_at, and the `resolved dispensed_at`, `resolved administered_at` and `resolved completed_at` declarations own it for the event instants.
Deleted: Clock semantics 1. `execution-contract.md` §Logic confinement owns it.
Deleted: Clock semantics 2. `execution-contract.md` §Logic confinement owns it.
Clock semantics 5: The atom MUST NOT bound a supplied event instant.
Deleted: Clock semantics 6. Capability requirement 13 owns it.
Deleted: Clock semantics 7. Capability requirement 14 owns it.
Deleted: Clock semantics 8. Non-goal 25 owns it.
```

WHY:
Clock semantics 4 and Clock semantics 5 are asymmetric on purpose, and the asymmetry is clinical. A prescription cannot be dated in the future — there is no such thing as having prescribed something tomorrow — so `ordered_at` is bounded above. A dispense, an administration or a completion may legitimately be recorded late, because the event happened at the bedside or the counter and the record catches up; bounding those would refuse correct documentation. Both directions are backdatable, which is a real limit and the reason the `ordered_at` bound runs against a declared allowance rather than against a bare comparison of two clocks (Capability requirement 3).

### Concurrency

```
Concurrency 1: The implementation MUST evaluate the state check and the state change of an order action inside one section.
Concurrency 2: A losing order action MUST read the winner's state.
Concurrency 3: A losing order action MUST answer the rejection the winner's state earns.
Concurrency 4: The implementation MUST NOT detect a race outside the section.
```

WHY:
Concurrency 4 states what the atom does *not* do, because the alternative is tempting and wrong. This spec has no race detection, no compare-and-set token, no optimistic retry — it has a section, and a caller who loses one simply reads a state that has moved and receives the rejection that state earns. A stalled or re-issued invocation re-reads under the section and lands an existing rejection rather than a new kind of answer (Decisions, 2026-08-30).

### Indeterminate outcome

```
Indeterminate outcome 1: A caller MUST NOT retry an action whose answer the caller lost BEFORE reading the order.
Indeterminate outcome 2: A caller MUST NOT read a lost answer as a refusal.
Indeterminate outcome 3: A caller MUST retry a lost [Amend] ONLY IF the original stands in a pre-dispensing state.
```

WHY:
Every order action but [Amend] is self-detecting under a lost answer: a second verify against an order that verified answers `not-in-ordered-state`, a second dispense answers `already-dispensed`. [Amend] is the exception and the dangerous one, because on an original still standing in ordered a blind retry succeeds and creates a *second successor* — which Invariant 4.1 forbids the store to hold and which a caller has just caused. Indeterminate outcome 3 is the re-entry arm: read the original first, and retry only where it is still amendable.

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: IF a string input EXCEEDS the length bound THEN an action MUST answer a blank-input rejection.
```

Term string input: a required string input OR a filter value — every caller-supplied string this atom accepts.

Term blank: a value that is absent, empty, or carries only whitespace — what every presence check in this atom refuses; a blank argument NOT EXISTS.

Term length bound: the maximum length the deployment declares for a `string input`.

WHY:
Blankness carries more weight here than in most atoms because two whole invariant families rest on it. A whitespace-only `dispenser_ref` would satisfy a naive presence check and leave a dispensing event with nobody's name on it; a whitespace-only `discontinuation_reason` would leave a stopped controlled substance with no stated basis. Invariant 10.1 and Invariant 11.1 are stated over what the *order carries* for that reason — the guarantee has to hold of the record an investigator reads.

---

## Composition notes

```
Composition note 1: A composing [Permissions](./permissions.md) MUST decide who may call an order action.
Composition note 2: A composing [Actor Identity](./actor-identity.md) MUST attest the actor behind EVERY state-changing action.
Composition note 3: A composing [Event Log](./event-log.md) MUST append an event on EVERY admitted action.
Composition note 4: A composing [Event Log](./event-log.md) MUST append an event on EVERY refused action.
Composition note 5: A composing [Tamper Evidence](./tamper-evidence.md) MUST cover EVERY order the store holds.
Composition note 6: A composing [Retention Window](./retention-window.md) MUST place an order under retention ONLY IF the order stands in a terminal state.
Composition note 7: A composing [Legal Hold](./legal-hold.md) MUST block a composing retention's purge.
Composition note 8: A composing [Duplicate Prevention](./duplicate-prevention.md) MUST map an idempotency token to the order_id an admitted order answered.
Composition note 9: A composing dose-event pattern MUST name the order_id on EVERY dose event.
Composition note 10: A composing dose-event pattern MUST NOT change the order.
Composition note 11: A composing decision-support pattern MUST NOT advise BEFORE reading a dosing parameter.
Composition note 12: A composing decision-support pattern MUST NOT change a core field.
```

WHY:
Composition note 6 is the retention seam and it turns on a state rather than an age. An order still moving through its chain has no retention clock to run, and a composition that placed an active order under one would be counting down against a record still being written. The terminal states are the ones that stop.

Composition note 10 and Composition note 12 say the same thing to two different composers. A dose-event pattern records what happened after the first administration and a decision-support pattern advises before the order is placed; neither writes to this record, because a composition that edited an order would defeat the immutability every invariant here rests on. They compose *around* the record, which is what keeps the chain of custody one chain.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the deployment; the implementation; the store; the store instance; the seam; the transition; a composing pattern; a caller; a prescriber; a pharmacist; a dispenser; an auditor; a regulator; an investigator; an order; a successor order; an original; an amended order; an on-hold order; a verified order; a dispensed order; an administered order; a completed order; a cancelled order; a discontinued order; a reinstated order; an action; an order action; a state-changing action; a held-refusing action; a losing order action; a refused action; a refused amend; a rejection; an opaque reference; a string input; a filter; a filter axis; a filter value; a field group; the store instance's order count.

Term records: `order` — one prescription's whole life, carrying `order_id`, `patient_ref`, `prescriber_ref`, `medication_ref`, `dose`, `dose_unit`, `route`, `frequency`, `ordered_at`, a `state`, and — where a transition wrote them — `duration`, `clinical_evidence_ref`, `verifier_ref`, `verified_at`, `predecessor_id`, `successor_id`, `amended_by`, `amendment_reason`, `prior_state`, `held_by`, `hold_reason`, `held_at`, `reinstated_by`, `reinstated_at`, `dispenser_ref`, `quantity`, `lot_number`, `dispensed_at`, `administerer_ref`, `administered_at`, `completed_by`, `completed_at`, `cancelled_by`, `cancellation_reason`, `cancelled_at`, `discontinued_by`, `discontinuation_reason` and `discontinued_at`.

Term record verbs: identify, assign, generate, change, share, reuse, carry, stand, read, answer, record, replace, leave, admit, offer, hold, commit, discard, repair, refuse, write, find, resolve, name, compare, normalize, confirm, match, route, register, create, pass, attest, cover, call, fall, precede, follow, sample, consume, supply, acknowledge, canonicalize, declare, compose, bind, decide, define, bound, reach, accept, trim, case-fold, compute, reproduce, reconstruct, verify, detect, guarantee, take, derive, expose, store, own, enumerate, distinguish, select, order, serialize, evaluate, block, place, cancel, exceed, retry, model, remove, release, amend, append, map, advise.

Term value sets: order answers order_id and refuses invalid-order | storage-failure. amend answers new_order_id and refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-dispensed | invalid-request | storage-failure. verify answers verified and refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-in-ordered-state | invalid-request | storage-failure. hold answers held and refuses not-known | already-on-hold | already-amended | already-cancelled | already-discontinued | already-completed | invalid-request | storage-failure. reinstate answers reinstated and refuses not-known | not-on-hold | invalid-request | storage-failure. dispense answers dispensed and refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-verified | already-dispensed | invalid-request | storage-failure. administer answers administered and refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-dispensed | already-administered | invalid-request | storage-failure. complete answers completed and refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-administered | invalid-request | storage-failure. cancel answers cancelled and refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | already-dispensed | invalid-request | storage-failure. discontinue answers discontinued and refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-dispensed | invalid-request | storage-failure. read answers the matching orders and refuses invalid-query. `state` = ordered | verified | amended | on-hold | dispensed | administered | completed | cancelled | discontinued. `terminal state` = completed | cancelled | discontinued. `inactive state` = amended | completed | cancelled | discontinued. `pre-dispensing state` = ordered | verified. `post-dispensing state` = dispensed | administered. `core field` = patient_ref | prescriber_ref | medication_ref | dose | dose_unit | route | frequency | duration | clinical_evidence_ref | ordered_at. `dosing parameter` = dose | dose_unit | route | frequency | duration. `blank-input rejection` = invalid-order | invalid-request.

Term bounds: `future bound`, `length bound`, `clock_offset_allowance`.

Term cadences: empty.

Term qualifiers: `migrated` — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: `order`, `order_id`, `store instance`, `core field`, `dosing parameter`, `attribution reference`, `reference`, `seam`, `transition`, `now`, `order action`, `state-changing action`, `held-refusing action`, `state`, `terminal state`, `inactive state`, `pre-dispensing state`, `post-dispensing state`, `actionable state`, `inactive state's rejection`, `state check`, `blank-input rejection`, `field fault`, `required string input`, `future bound`, `clock_offset_allowance`, `event instant`, `query axes`, `field group`, `reason field`, `admitted order`, `admitted amend`, `admitted verify`, `admitted hold`, `admitted reinstate`, `admitted dispense`, `admitted administer`, `admitted complete`, `admitted cancel`, `admitted discontinue`, `admitted read`, `string input`, `blank`, `length bound`, `resolved dispensed_at`, `resolved administered_at`, `resolved completed_at`.

Term cited: `execution-contract.md` Logic confinement — the seam and the transition.

Term composing pattern: [Permissions](./permissions.md), [Actor Identity](./actor-identity.md), [Event Log](./event-log.md), [Tamper Evidence](./tamper-evidence.md), [Retention Window](./retention-window.md), [Legal Hold](./legal-hold.md), [Duplicate Prevention](./duplicate-prevention.md), a dose-event pattern, a decision-support pattern, a trusted timestamping pattern, a formulary.

Term event instant: `dispensed_at` | `administered_at` | `completed_at` — every instant a caller may supply for something that happened away from the call.

Term resolved dispensed_at: the `dispensed_at` the order carries — the supplied value where one exists, and `now` otherwise.

Term resolved administered_at: the `administered_at` the order carries — the supplied value where one exists, and `now` otherwise.

Term resolved completed_at: the `completed_at` the order carries — the supplied value where one exists, and `now` otherwise.

Term clock_offset_allowance: the non-negative duration the deployment declares as the margin the future bound allows; zero declares no tolerance.

Term reason field: `amendment_reason` | `hold_reason` | `cancellation_reason` | `discontinuation_reason` — every field recording why an action was taken.

#### Order

The behavior that records a new [Order] — assigning a fresh [Order Id], recording every supplied core field, stamping [Ordered At], and standing the record in [Ordered]. Refused [Invalid Order] or [Storage Failure]. Not idempotent: a retried call after a lost answer creates a second order.

Kind: Operation

#### Amend

The behavior that corrects a pre-dispensing order by recording a *successor* rather than editing the original. The successor carries the corrected dosing parameters, the inherited patient, prescriber and medication, and a [Predecessor Id]; the original stands in [Amended] carrying a [Successor Id]. Both writes commit together. Legal only from a pre-dispensing state.

Kind: Operation

#### Verify

The behavior that records a pharmacist's review and clearance, standing the order in [Verified] and recording [Verifier Ref] and [Verified At]. Legal only from [Ordered] — nothing is dispensed against a prescription no pharmacist has read.

Kind: Operation

#### Hold

The behavior that suspends an order from any actionable state, recording the state it paused as [Prior State] along with [Held By], [Hold Reason] and [Held At]. An on-hold order refuses every action but [Reinstate].

Kind: Operation

#### Reinstate

The behavior that resumes a held order, returning it to the state its hold recorded. Takes no target state, so it cannot return an order anywhere else.

Kind: Operation

#### Dispense

The behavior that records the pharmacy releasing the medication, standing the order in [Dispensed] and recording [Dispenser Ref], [Quantity], an optional [Lot Number] and [Dispensed At]. The edge this action crosses is the one amendment and cancellation stop at.

Kind: Operation

#### Administer

The behavior that records the medication given to the patient, standing the order in [Administered]. Records the first administration only; a second dose event against one order is a composing pattern's.

Kind: Operation

#### Complete

The behavior that closes an order after the course has been administered, standing it in [Completed] and recording [Completed By] and [Completed At]. Terminal.

Kind: Operation

#### Cancel

The behavior that terminates an order *before* any dispensing, standing it in [Cancelled] and recording [Cancelled By], [Cancellation Reason] and [Cancelled At]. Terminal. Refused across the dispensing edge, where [Discontinue] is the remedy.

Kind: Operation

#### Discontinue

The behavior that terminates an order *after* dispensing has begun, standing it in [Discontinued] and recording [Discontinued By], [Discontinuation Reason] and [Discontinued At]. Terminal. Refused before the dispensing edge, where [Cancel] is the remedy.

Kind: Operation

#### Read

The read-only query answering the matching [Order] records by [Ordered At] ascending, each carrying every field group its transitions wrote. Refuses a filter it cannot read ([Invalid Query]).

Kind: Operation

#### Order Id

The opaque, immutable identity of an [Order], assigned from the id material the seam supplies and unique within one store instance. Never reused, and never the patient — two orders for one patient are two orders.

Kind:     Field
Field of: Order
Projects: order_id

#### Patient Ref

The opaque reference naming whose prescription this is. Set at placement, immutable, inherited unchanged by every successor, and scoped globally rather than per store instance.

Kind:     Field
Field of: Order
Projects: patient_ref

#### Prescriber Ref

The opaque reference naming who placed the order. Immutable and inherited by every successor — prescribing authorship belongs to the original prescriber, and [Amended By] records who corrected it.

Kind:     Field
Field of: Order
Projects: prescriber_ref

#### Medication Ref

The opaque reference naming the drug and formulation — a formulary code, a National Drug Code. Never interpreted, never changed, and inherited by every successor: an order for the wrong medication is cancelled and re-placed, because [Amend] takes no medication.

Kind:     Field
Field of: Order
Projects: medication_ref

#### Dose

The prescribed quantity per administration. A dosing parameter, so an amendment may correct it on a successor; positive, and paired with a [Dose Unit].

Kind:     Field
Field of: Order
Projects: dose

#### Dose Unit

The unit the [Dose] is expressed in — `mg`, `mL`, `unit`. A dosing parameter, opaque to the atom.

Kind:     Field
Field of: Order
Projects: dose_unit

#### Route

How the medication is given — `oral`, `IV`, `topical`. A dosing parameter, opaque to the atom.

Kind:     Field
Field of: Order
Projects: route

#### Frequency

How often the medication is given — `QD`, `BID`, `PRN`. A dosing parameter, opaque to the atom.

Kind:     Field
Field of: Order
Projects: frequency

#### Duration

How long the course runs. Optional: an absent [Duration] is an open-ended order, which stands active until someone completes or discontinues it. A dosing parameter, so an amendment may add one, change one, or remove one.

Kind:     Field
Field of: Order
Projects: duration

#### Clinical Evidence Ref

An optional opaque reference to the evidence that informed the prescribing decision — an [Observation](./observation.md)'s id, for instance. Advisory metadata; the atom never reads a [Clinical Evidence Ref] it was given.

Kind:     Field
Field of: Order
Projects: clinical_evidence_ref

#### Ordered At

The instant the order was placed — the caller's supplied value, or [Now]. Immutable, and the only timestamp bounded from above, because a prescription cannot be dated in the future.

Kind:     Field
Field of: Order
Projects: ordered_at

#### State

The order's position in the chain — one of the nine. Changes only through an action, and never out of an inactive state.

Kind:     Field
Field of: Order
Projects: state

#### Predecessor Id

The [Order Id] of the order this one corrects. Present only on a successor; written once, because a re-link would rewrite the amendment chain an auditor walks.

Kind:     Field
Field of: Order
Projects: predecessor_id

#### Successor Id

The [Order Id] of the order that corrected this one. Present only on an [Amended] order; written once.

Kind:     Field
Field of: Order
Projects: successor_id

#### Amended By

The opaque reference naming who made the correction. Recorded on the successor, distinct from the inherited [Prescriber Ref].

Kind:     Field
Field of: Order
Projects: amended_by

#### Prior State

The state a [Hold] paused, recorded so [Reinstate] can return the order to it. Replaced by each new hold cycle.

Kind:     Field
Field of: Order
Projects: prior_state

#### Verifier Ref

The opaque reference naming the pharmacist who cleared the order. Written once at [Verify] and carried on every later state.

Kind:     Field
Field of: Order
Projects: verifier_ref

#### Dispenser Ref

The opaque reference naming who released the medication. Written once at [Dispense].

Kind:     Field
Field of: Order
Projects: dispenser_ref

#### Quantity

How much was released at [Dispense]. Positive; written once.

Kind:     Field
Field of: Order
Projects: quantity

#### Lot Number

The optional manufacturing lot of what was released — the field a recall is traced through. Written once at [Dispense] where supplied.

Kind:     Field
Field of: Order
Projects: lot_number

#### Administerer Ref

The opaque reference naming who gave the medication to the patient. Written once at [Administer].

Kind:     Field
Field of: Order
Projects: administerer_ref

#### Verified At

The instant the pharmacist's clearance was recorded, stamped from [Now] at [Verify]. Written once.

Kind:     Field
Field of: Order
Projects: verified_at

#### Dispensed At

The instant the release was recorded — the caller's supplied value, or [Now]. Written once, and not bounded from above, because a release may be documented after the fact.

Kind:     Field
Field of: Order
Projects: dispensed_at

#### Held By

The opaque reference naming who suspended the order. Replaced by each new hold cycle.

Kind:     Field
Field of: Order
Projects: held_by

#### Hold Reason

Why the order was suspended — a surgical pause, an interaction review. Never blank; replaced by each new hold cycle.

Kind:     Field
Field of: Order
Projects: hold_reason

#### Held At

The instant the suspension was recorded, stamped from [Now]. Replaced by each new hold cycle.

Kind:     Field
Field of: Order
Projects: held_at

#### Completed By

The opaque reference naming who closed the order after the course was given. Written once.

Kind:     Field
Field of: Order
Projects: completed_by

#### Completed At

The instant the closure was recorded — the caller's supplied value, or [Now]. Written once.

Kind:     Field
Field of: Order
Projects: completed_at

#### Cancelled By

The opaque reference naming who terminated the order before any dispensing. Written once.

Kind:     Field
Field of: Order
Projects: cancelled_by

#### Cancellation Reason

Why the order was terminated before dispensing. Never blank, and the field carrying the difference between a clinical decision and a clerical correction — which is why this atom needs no separate entered-in-error state.

Kind:     Field
Field of: Order
Projects: cancellation_reason

#### Cancelled At

The instant the cancellation was recorded, stamped from [Now]. Written once.

Kind:     Field
Field of: Order
Projects: cancelled_at

#### Discontinued By

The opaque reference naming who stopped the order after dispensing had begun. Written once.

Kind:     Field
Field of: Order
Projects: discontinued_by

#### Discontinuation Reason

Why the order was stopped after dispensing. Never blank — a stopped controlled substance with no stated basis is the record a diversion investigation cannot read.

Kind:     Field
Field of: Order
Projects: discontinuation_reason

#### Discontinued At

The instant the discontinuation was recorded, stamped from [Now]. Written once.

Kind:     Field
Field of: Order
Projects: discontinued_at

#### Now

The wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it — never read inside the transition and never supplied by the business caller. It stamps every instant the caller did not supply, and raises the future bound the supplied [Ordered At] is checked against.

Kind:         Parameter
Parameter of: Order
Projects:     now

#### Administered At

The instant the dose was given — the caller's supplied value, or [Now]. Written once at [Administer], and not bounded from above, because an administration at the bedside is often documented after it happened.

Kind:     Field
Field of: Order
Projects: administered_at

#### Amendment Reason

Why the order was corrected. Recorded on the successor, never blank — an amendment with no stated basis leaves the chain walkable and unreadable.

Kind:     Field
Field of: Order
Projects: amendment_reason

#### Reinstated By

The opaque reference naming who resumed a held order. Replaced by each new hold cycle.

Kind:     Field
Field of: Order
Projects: reinstated_by

#### Reinstated At

The instant the resumption was recorded, stamped from [Now]. Replaced by each new hold cycle.

Kind:     Field
Field of: Order
Projects: reinstated_at

#### Ordered

The entry state of every placed order: awaiting a pharmacist's review. May be verified, amended, held or cancelled.

Kind:      Member
Member of: the order state
Role:      Outcome

#### Verified

A pharmacist has reviewed and cleared the order. May be dispensed, amended, held or cancelled — the last state on the near side of the dispensing edge.

Kind:      Member
Member of: the order state
Role:      Outcome

#### Amended

The order was superseded by a successor. Retained and readable, carrying a [Successor Id]; inactive, so clinical work continues on the successor.

Kind:      Member
Member of: the order state
Role:      Outcome

#### On Hold

The order is temporarily suspended — a surgical pause, an interaction review. Carries the state it paused, and admits only [Reinstate].

Kind:      Member
Member of: the order state
Role:      Outcome

#### Dispensed

The pharmacy has released the medication. The first state on the far side of the dispensing edge: amendment and cancellation are closed, [Discontinue] is open.

Kind:      Member
Member of: the order state
Role:      Outcome

#### Administered

At least one dose has been given. May be completed, held or discontinued.

Kind:      Member
Member of: the order state
Role:      Outcome

#### Completed

The course was administered in full. Terminal.

Kind:      Member
Member of: the order state
Role:      Outcome

#### Cancelled

The order was terminated before any dispensing — the medication never reached the patient. Terminal, and distinct from [Discontinued] because pharmacy accounting and controlled-substance reconciliation turn on which of the two happened.

Kind:      Member
Member of: the order state
Role:      Outcome

#### Discontinued

The order was terminated after dispensing had begun — the medication was released, and the course stopped. Terminal.

Kind:      Member
Member of: the order state
Role:      Outcome

#### Invalid Order

The refusal [Order] returns when a required string input is blank, a supplied [Ordered At] exceeds the future bound, or a [Dose] does not exceed zero.

Kind:      Member
Member of: the Order rejection
Role:      Outcome
Projects:  invalid-order

#### Invalid Request

The refusal an order action returns for a blank input, a non-positive [Quantity], or an [Amend] whose supplied dosing parameters all match the original. Reached only after every state check passes.

Kind:      Member
Member of: the order-action rejection
Role:      Outcome
Projects:  invalid-request

#### Not Known

The refusal an order action returns when the [Order Id] names no order in this store instance.

Kind:      Member
Member of: the order-action rejection
Role:      Outcome
Projects:  not-known

#### On Hold Rejection

The refusal a held-refusing action returns against an [On Hold] order. Answered before any rejection about the state underneath the hold, because the hold is what the caller must resolve first.

Kind:      Member
Member of: the order-action rejection
Role:      Outcome
Projects:  on-hold

#### Already Dispensed

The refusal [Amend] and [Cancel] return across the dispensing edge, and [Dispense] returns against an order already dispensed. One token, one fact: the medication has left the pharmacy.

Kind:      Member
Member of: the order-action rejection
Role:      Outcome
Projects:  already-dispensed

#### Not Dispensed

The refusal [Discontinue] returns on the near side of the dispensing edge, and [Administer] returns against an unreleased order. The mirror of [Already Dispensed], and the reason [Cancel] exists.

Kind:      Member
Member of: the order-action rejection
Role:      Outcome
Projects:  not-dispensed

#### Storage Failure

The refusal any writing action returns when the store refuses the write after every precondition passes. No partial record is left, and none is repaired afterwards.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

#### Invalid Query

The refusal [Read] returns for a filter axis or a filter value it cannot read.

Kind:      Member
Member of: the Read rejection
Role:      Outcome
Projects:  invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Order]: #order
[Amend]: #amend
[Verify]: #verify
[Hold]: #hold
[Reinstate]: #reinstate
[Dispense]: #dispense
[Administer]: #administer
[Complete]: #complete
[Cancel]: #cancel
[Discontinue]: #discontinue
[Read]: #read
[Order Id]: #order-id
[Patient Ref]: #patient-ref
[Prescriber Ref]: #prescriber-ref
[Medication Ref]: #medication-ref
[Dose]: #dose
[Dose Unit]: #dose-unit
[Route]: #route
[Frequency]: #frequency
[Duration]: #duration
[Clinical Evidence Ref]: #clinical-evidence-ref
[Ordered At]: #ordered-at
[State]: #state
[Predecessor Id]: #predecessor-id
[Successor Id]: #successor-id
[Amended By]: #amended-by
[Prior State]: #prior-state
[Verifier Ref]: #verifier-ref
[Verified At]: #verified-at
[Dispenser Ref]: #dispenser-ref
[Quantity]: #quantity
[Lot Number]: #lot-number
[Dispensed At]: #dispensed-at
[Administerer Ref]: #administerer-ref
[Held By]: #held-by
[Hold Reason]: #hold-reason
[Held At]: #held-at
[Completed By]: #completed-by
[Completed At]: #completed-at
[Cancelled By]: #cancelled-by
[Cancellation Reason]: #cancellation-reason
[Cancelled At]: #cancelled-at
[Discontinued By]: #discontinued-by
[Discontinuation Reason]: #discontinuation-reason
[Discontinued At]: #discontinued-at
[Ordered]: #ordered
[Verified]: #verified
[Amended]: #amended
[On Hold]: #on-hold
[Dispensed]: #dispensed
[Administered]: #administered
[Completed]: #completed
[Cancelled]: #cancelled
[Discontinued]: #discontinued
[Invalid Order]: #invalid-order
[Invalid Request]: #invalid-request
[Not Known]: #not-known
[Already Dispensed]: #already-dispensed
[Not Dispensed]: #not-dispensed
[Storage Failure]: #storage-failure
[Invalid Query]: #invalid-query
[Now]: #now
[Administered At]: #administered-at
[Amendment Reason]: #amendment-reason
[Reinstated By]: #reinstated-by
[Reinstated At]: #reinstated-at
[On Hold Rejection]: #on-hold-rejection

---

## Standards references

- **HL7 FHIR (MedicationRequest / MedicationDispense / MedicationAdministration)** — the interoperability decomposition this atom deliberately does not follow. FHIR splits the lifecycle across three resources so independently operated systems can own separate pieces; this atom keeps one auditable chain inside a deployment, and the case for splitting arrives when a second pattern needs generic material-issuance semantics independent of a prescription.
- **DEA controlled-substance requirements (21 CFR Part 1300 et seq.)** — the attribution chain and the cancel/discontinue boundary are what a reconciliation reads. What attaches to a *scheduled* substance — registration, EPCS two-factor prescribing, refill limits, quantity caps — is outside this atom, because `medication_ref` is opaque to it (Identity 13, Non-goal 17).
- **DEA EPCS non-alteration requirements** — met at the layer [Tamper Evidence](./tamper-evidence.md) provides. This atom's immutability is a property of its specified surface, not a cryptographic guarantee against a store administrator (External check 4).
- **HIPAA (45 CFR 164.312)** — the audit-controls requirement applies to the composing [Event Log](./event-log.md) and [Audit Trail](../compositions/audit-trail.md) instances rather than to the order record; retention under HIPAA and state law is [Retention Window](./retention-window.md)'s (Non-goal 22).
- **ISMP and Joint Commission medication-management standards** — the verification-gates-dispensing sequence and the requirement that every step be attributed are the structural correlates. What a pharmacist should look *for* at verification is clinical practice, not this atom's (Non-goal 4 through 7).

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture, and the discipline of composing access control, non-repudiation, retention, tamper-evidence and decision support as separate concepts.
- **Grace Commons regulated-atom conventions** — the adversarial scenarios and the acceptance section, from `pressure-testing.md`.

---

## Status

`grounded on Final Critique 4 — 2026-05-20` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-05-20
formal: verified — medication-order.als + medication-order.tla + 2 twins, 2026-06-04
last gate: 2026-05-20 — Final Critique 4, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/medication-order.md`.

- **2026-09-13 — The EOS strip test: the tag is earned, and it is earned by the graph rather than by the guards.** *Chose:* keep `domain: healthcare`, and correct the reason `atoms/TAXONOMY.md` records for it. *Over:* the standing justification, which names the *guards* as irreducibly clinical — verification gating dispensing, the verified-dispensed-administered pipeline, controlled-substance attestation. *Because:* each of those guards is individually derivable from a neutral primitive the corpus already holds. One actor authorizing and a different actor releasing is [Approval Step](./approval-step.md)'s shape. A three-stage custody pipeline is [Chain of Custody](../compositions/chain-of-custody.md)'s. Attributed actions are [Actor Identity](./actor-identity.md)'s. Twelve of the fourteen invariants here strip clean, and the two that do not — Invariant 3.1 and Invariant 6.1 with Invariant 6.2 — both pivot on one thing: an irreversible release, after which the record describes something in another party's custody. That pivot is not clinical either; a warehouse has it.

  What does not strip is the *graph*. Nine states in this topology, with the amendment boundary and the cancel/discontinue split landing on exactly the dispensing edge, is not derivable from neutral primitives — a generic state machine plus a supplied graph is just this atom with the domain moved into a parameter, and the parameter would carry every clinical judgment the graph encodes. The domain hides in the shape, not in the words and not in the rules. The formal layer corroborates: this is the only atom in the migrated set carrying both an Alloy model and a TLA model, and the Alloy model exists because the *structure* needed checking rather than the timing.

  Three specimens now, three hiding places: [Observation](./observation.md) hid nothing and was renamed; [Party Identity](./party-identity.md) hid it in the field schema and kept both name and no tag; this one hides it in the graph and keeps the tag. The test's site-census grows by one per specimen, which is the argument for running it on every atom rather than on the ones that look domain-shaped.
- **2026-08-30 — One writer per transition, and no repair leg.** *Chose:* transactional atomicity of the atom's own store as the only conforming implementation of [Amend]'s two writes, the crash-recovery scan withdrawn; the per-id serialization stated as a critical section — taken before the state check, released on return or death — with a stalled or re-issued invocation re-reading under the section and landing an existing rejection; a re-entry arm for a caller whose [Amend] lost its response, retrying only where the original is still amendable; and a deployment-declared `clock_offset_allowance` under which the future-dated check on a supplied [Ordered At] runs. *Over:* a scan "that detects and repairs dangling amendment links on restart" offered as an equal alternative to a transaction; a caller left to retry [Amend] blind, which on an original still [Ordered] creates a second successor; a future-dated refusal decided by comparing the caller's stamp to the node's clock with no margin. *Because:* the scan presumed a visible partial record that Invariant 14.2 says never exists, could relink one dangling shape but not the other — the successor's dosing parameters, [Amended By] and its amendment reason are nowhere in the store, and un-marking the original rewrites a write-once field — and made a second writer for an amendment the caller's retry could already have landed, branching a chain Invariant 4.1 keeps linear; and a caller's stamp and the node's reading are two clocks, so a refusal resting on their comparison needs the margin on the page.

NOTE: End of Medication Order.
