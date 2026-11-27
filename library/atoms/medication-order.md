---
title: Medication Order
id: 45
audience: common
domain: healthcare
---

# Medication Order

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Medication Order records the whole life of a prescription, from the moment a prescriber places it to its end. The order names the drug, the patient, the [Dose] (how much at a time), the [Route] (how it is given, such as by mouth), the [Frequency] (how often) and the [Duration] (for how long), then moves through a regulated chain of custody: a pharmacist verifies it before anything is dispensed, a dispenser releases the medication, a nurse or the patient administers it, and the course completes or is stopped — with the actor at every step permanently recorded.

The guarantee is that the chain is complete and that the atom offers no surface that alters it: no step silently skipped, no actor silently omitted, no field a past transition wrote altered afterwards beyond the order's state, a hold field and a reinstate field (Invariant 12.1); a rewrite beneath the atom is another pattern's to detect (Non-goal 18). The drug, dose, route and frequency are fixed when the order is placed. A correction *before* dispensing creates a successor order, which must be verified afresh; a correction *after* dispensing requires stopping the order and placing a new one, because the physical medication has already left the pharmacy.

An order stands in exactly one of nine states, with a reversible hold for a surgical pause or an interaction review. The line between an order cancelled before any drug was dispensed and one discontinued after is enforced structurally, because it is the line controlled-substance accounting turns on.

A prescriber — a physician, a nurse practitioner, a physician assistant, or an authorized clinical system — places an order specifying what drug to give, to whom, in what dose and form, by what route, on what schedule and for how long. That prescription drives a chain of custody, and at every step the actor who acts is permanently attributed.

Three clinical requirements run at once. The record must be faithful to what was ordered — medication, dose, route and frequency are fixed at order time, and errors are corrected by explicit amendment or explicit termination, never by silent edit. Every role in the chain must survive adversarial scrutiny: a DEA (US Drug Enforcement Administration) controlled-substance audit, a wrong-medication dispute, a diversion investigation. And the amendment boundary at dispensing is load-bearing, because a dose change before the pharmacy has acted is a correction, while a change after the medication has left is a new prescription.

This atom models the full lifecycle as one record rather than decomposing it the way HL7 (Health Level Seven) FHIR (Fast Healthcare Interoperability Resources) does across MedicationRequest, MedicationDispense and MedicationAdministration. That decomposition serves interoperability between independently operated systems; this one prioritizes a single auditable chain of custody inside a deployment. Dispensing and administration here are transitions on the order, not freestanding entities — they carry no state machines of their own and are meaningful only against the order they act on. The case for separating them does not arise until a second pattern in the library needs generic material-issuance semantics — blood products, implants, durable equipment — independent of a prescription.

This is a freestanding atom in the EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) sense: its own state, its own ten writes and one read, and its own invariants. Access control, cryptographic non-repudiation, retention and tamper-evidence are composing patterns, and DEA reporting is a pattern the library does not hold yet *(forthcoming)*. The atom imposes no clinical semantics on what the medication *is*; it imposes the structural guarantee that the record is faithful to what was prescribed, by whom, and how it was fulfilled.

## What it keeps

### The orders

```
Identity 1: The atom MUST identify an order by the order id.
Identity 2: The atom MUST assign the order id from the id material the seam supplies.
Identity 3: The atom MUST NOT generate an order id.
Identity 4: The atom MUST NOT change an order's order id.
Identity 5: Two orders in one database instance MUST NOT share an order id.
Identity 6: The atom MUST NOT reuse an order's order id.
Identity 7: The atom MUST NOT identify an order by a core field.
Identity 8: The atom MUST compare a reference byte for byte.
Identity 9: The atom MUST NOT normalize a reference.
Identity 10: The atom MUST NOT confirm that a patient reference names a known patient.
Identity 11: The atom MUST NOT confirm that a medication reference names a known medication.
Identity 12: The atom MUST NOT confirm that an attribution reference names a known actor.
Identity 13: The atom MUST NOT read a medication reference's clinical meaning.
Identity 15: The atom MUST NOT resolve an order id across two database instances.
```

Term order: the record this atom holds — one prescription's whole life, from placement to its end.

Term database instance: one named database a call is routed to, named by a store_name; order id uniqueness ranges over one instance, and a patient reference may appear in several.

Term core field: patient reference | prescriber reference | medication reference | dose | dose unit | route | frequency | duration | clinical evidence reference | order instant — what an order carries from placement and never changes.

Term dosing parameter: dose | dose unit | route | frequency | duration — the core fields an amendment may correct on a successor.

Term attribution reference: prescriber reference, amending actor, verifier reference, holding actor, reinstating actor, dispenser reference, administerer reference, completing actor, cancelling actor OR discontinuing actor — the reference each action records for who acted.

Term reference: order id, patient reference, medication reference, clinical evidence reference, an attribution reference, predecessor id OR successor id — every opaque reference this atom records.

```
State 1: EVERY order MUST carry order id, EVERY core field the call supplied and a state.
State 2: EVERY verified order MUST carry verifier reference and verification instant.
State 3: EVERY dispensed order MUST carry dispenser reference, quantity and dispensing instant.
State 4: A dispensed order MAY carry a lot number.
State 5: EVERY administered order MUST carry administerer reference and administration instant.
State 6: EVERY completed order MUST carry completing actor and completion instant.
State 7: EVERY cancelled order MUST carry cancelling actor, cancellation reason and cancellation instant.
State 8: EVERY discontinued order MUST carry discontinuing actor, discontinuation reason and discontinuation instant.
State 9: EVERY amended order MUST carry a successor id.
State 10: EVERY successor order MUST carry predecessor id, amending actor and amendment reason.
State 11: EVERY on-hold order MUST carry prior state, holding actor, hold reason and hold instant.
State 12: EVERY reinstated order MUST carry reinstating actor and reinstatement instant.
State 13: An order MUST carry EVERY field a prior transition wrote.
State 14: The atom MUST NOT offer a purged state.
```

#### Order Id

The opaque, immutable identity of an [Order], assigned from the id material the seam supplies and unique within one database instance. Never reused, and never the patient — two orders for one patient are two orders.

Kind:       Field
Field of:   Order
Projection: order_id

#### Patient Reference

The opaque reference naming whose prescription this is. Set at placement, immutable, inherited unchanged by every successor, and scoped globally rather than per database instance.

Kind:       Field
Field of:   Order
Projection: patient_ref

#### Prescriber Reference

The opaque reference naming who placed the order. Immutable and inherited by every successor — prescribing authorship belongs to the original prescriber, and [Amending Actor] records who corrected it.

Kind:       Field
Field of:   Order
Projection: prescriber_ref

#### Medication Reference

The opaque reference naming the drug and formulation — a formulary code, a National Drug Code. Never interpreted, never changed, and inherited by every successor: an order for the wrong medication is cancelled and re-placed, because [Amend] takes no medication.

Kind:       Field
Field of:   Order
Projection: medication_ref

#### Dose

The prescribed quantity per administration. A dosing parameter, so an amendment may correct it on a successor; a positive number, whole or fractional, and paired with a [Dose Unit].

Kind:       Field
Field of:   Order
Projection: dose

#### Dose Unit

The unit the [Dose] is expressed in — `mg`, `mL`, `unit`. A dosing parameter, opaque to the atom.

Kind:       Field
Field of:   Order
Projection: dose_unit

#### Route

How the medication is given — `oral`, `IV` (intravenous), `topical`. A dosing parameter, opaque to the atom.

Kind:       Field
Field of:   Order
Projection: route

#### Frequency

How often the medication is given — `QD` (once daily), `BID` (twice daily), `PRN` (as needed). A dosing parameter, opaque to the atom.

Kind:       Field
Field of:   Order
Projection: frequency

#### Duration

How long the course runs. Optional: an absent [Duration] is an open-ended order, which stands active until someone completes or discontinues it. A dosing parameter, opaque to the atom, so an amendment may add one or change one.

Kind:       Field
Field of:   Order
Projection: duration

#### Clinical Evidence Reference

An optional opaque reference to the evidence that informed the prescribing decision — the id of a recorded clinical observation, for instance. Advisory metadata; the atom never reads a [Clinical Evidence Reference] it was given.

Kind:       Field
Field of:   Order
Projection: clinical_evidence_ref

#### Order Instant

The instant the order was placed — the caller's supplied value, or [Now]. Immutable, and the only timestamp bounded from above, because a prescription cannot be dated in the future.

Kind:       Field
Field of:   Order
Projection: ordered_at

#### State

The order's position in the chain — one of the nine. Changes only through an action, and never out of an inactive state.

Kind:       Field
Field of:   Order
Projection: state

#### Predecessor Id

The [Order Id] of the order this one corrects. Present only on a successor; written once, because a re-link would rewrite the amendment chain an auditor walks.

Kind:       Field
Field of:   Order
Projection: predecessor_id

#### Successor Id

The [Order Id] of the order that corrected this one. Present only on an [Amended] order; written once.

Kind:       Field
Field of:   Order
Projection: successor_id

#### Amending Actor

The opaque reference naming who made the correction. Recorded on the successor, distinct from the inherited [Prescriber Reference].

Kind:       Field
Field of:   Order
Projection: amended_by

#### Prior State

The state a [Hold] paused, recorded so [Reinstate] can return the order to it. Replaced by each new hold cycle.

Kind:       Field
Field of:   Order
Projection: prior_state

#### Verifier Reference

The opaque reference naming the pharmacist who cleared the order. Written once at [Verify] and carried on every later state.

Kind:       Field
Field of:   Order
Projection: verifier_ref

#### Dispenser Reference

The opaque reference naming who released the medication. Written once at [Dispense].

Kind:       Field
Field of:   Order
Projection: dispenser_ref

#### Quantity

How much was released at [Dispense]. A positive number, whole or fractional; written once.

Kind:       Field
Field of:   Order
Projection: quantity

#### Lot Number

The optional manufacturing lot of what was released — the field a recall is traced through. Written once at [Dispense] where supplied.

Kind:       Field
Field of:   Order
Projection: lot_number

#### Administerer Reference

The opaque reference naming who gave the medication to the patient. Written once at [Administer].

Kind:       Field
Field of:   Order
Projection: administerer_ref

#### Verification Instant

The instant the pharmacist's clearance was recorded, stamped from [Now] at [Verify]. Written once.

Kind:       Field
Field of:   Order
Projection: verified_at

#### Dispensing Instant

The instant the release was recorded — the caller's supplied value, or [Now]. Written once, and not bounded from above, because a release may be documented after the fact.

Kind:       Field
Field of:   Order
Projection: dispensed_at

#### Holding Actor

The opaque reference naming who suspended the order. Replaced by each new hold cycle.

Kind:       Field
Field of:   Order
Projection: held_by

#### Hold Reason

Why the order was suspended — a surgical pause, an interaction review. Never blank; replaced by each new hold cycle.

Kind:       Field
Field of:   Order
Projection: hold_reason

#### Hold Instant

The instant the suspension was recorded, stamped from [Now]. Replaced by each new hold cycle.

Kind:       Field
Field of:   Order
Projection: held_at

#### Completing Actor

The opaque reference naming who closed the order after the course was given. Written once.

Kind:       Field
Field of:   Order
Projection: completed_by

#### Completion Instant

The instant the closure was recorded — the caller's supplied value, or [Now]. Written once.

Kind:       Field
Field of:   Order
Projection: completed_at

#### Cancelling Actor

The opaque reference naming who terminated the order before any dispensing. Written once.

Kind:       Field
Field of:   Order
Projection: cancelled_by

#### Cancellation Reason

Why the order was terminated before dispensing. Never blank, and the field carrying the difference between a clinical decision and a clerical correction — which is why this atom needs no separate entered-in-error state.

Kind:       Field
Field of:   Order
Projection: cancellation_reason

#### Cancellation Instant

The instant the cancellation was recorded, stamped from [Now]. Written once.

Kind:       Field
Field of:   Order
Projection: cancelled_at

#### Discontinuing Actor

The opaque reference naming who stopped the order after dispensing had begun. Written once.

Kind:       Field
Field of:   Order
Projection: discontinued_by

#### Discontinuation Reason

Why the order was stopped after dispensing. Never blank — a stopped controlled substance with no stated basis is the record a diversion investigation cannot read.

Kind:       Field
Field of:   Order
Projection: discontinuation_reason

#### Discontinuation Instant

The instant the discontinuation was recorded, stamped from [Now]. Written once.

Kind:       Field
Field of:   Order
Projection: discontinued_at

#### Administration Instant

The instant the dose was given — the caller's supplied value, or [Now]. Written once at [Administer], and not bounded from above, because an administration at the bedside is often documented after it happened.

Kind:       Field
Field of:   Order
Projection: administered_at

#### Amendment Reason

Why the order was corrected. Recorded on the successor, never blank — an amendment with no stated basis leaves the chain walkable and unreadable.

Kind:       Field
Field of:   Order
Projection: amendment_reason

#### Reinstating Actor

The opaque reference naming who resumed a held order. Replaced by each new hold cycle.

Kind:       Field
Field of:   Order
Projection: reinstated_by

#### Reinstatement Instant

The instant the resumption was recorded, stamped from [Now]. Replaced by each new hold cycle.

Kind:       Field
Field of:   Order
Projection: reinstated_at

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

The order was superseded by a successor. Retained and readable, carrying a [Successor Id]; inactive, so clinical work continues on the successor. Every order action but [Reinstate] refuses it [Already Amended].

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

The course was administered in full. Terminal. Every order action but [Amend] and [Reinstate] refuses it [Already Completed].

Kind:      Member
Member of: the order state
Role:      Outcome

#### Cancelled

The order was terminated before any dispensing — the medication never reached the patient. Terminal, and distinct from [Discontinued] because pharmacy accounting and controlled-substance reconciliation turn on which of the two happened. Every order action but [Reinstate] refuses it [Already Cancelled].

Kind:      Member
Member of: the order state
Role:      Outcome

#### Discontinued

The order was terminated after dispensing had begun — the medication was released, and the course stopped. Terminal. Every order action but [Reinstate] refuses it [Already Discontinued].

Kind:      Member
Member of: the order state
Role:      Outcome

Term state: ordered | verified | amended | on-hold | dispensed | administered | completed | cancelled | discontinued.

Term order id: the opaque value naming one order — an [Order Id]; assigned from the id material the seam supplies, unique within one database instance.

## What people do

### Every action

```
Operation 1: IF a required string input EQUALS blank THEN an action MUST answer a blank-input rejection.
Operation 10: IF order id EQUALS blank THEN an order action MUST answer a blank-input rejection.
Operation 11: IF the order id names no order THEN an order action MUST answer not-known.
Operation 12: An order action MUST answer not-known ONLY IF order id DOES NOT EQUAL blank.
Operation 13: IF the order's state EQUALS on-hold THEN an order action other than [Hold] and [Reinstate] MUST answer on-hold.
Operation 14: IF the order's state IS IN the inactive states THEN a state-changing action MUST answer the inactive state's rejection.
Operation 62: IF the database refuses the write THEN an action MUST answer storage-failure.
Operation 88: [Order], [Amend], [Verify], [Hold], [Reinstate], [Dispense], [Administer], [Complete], [Cancel] AND [Discontinue] MUST append one order events record through the atom's journal need for EVERY admitted call.
Operation 90: An order events record an admitted hold appends MUST carry the order id, prior state, holding actor, hold reason and hold instant the hold recorded.
Operation 91: An order events record an admitted reinstate appends MUST carry the order id, reinstating actor and reinstatement instant the reinstate recorded.
Operation 64: A refused action MUST leave the order as the call found the order.
Operation 67: The atom MUST NOT offer an order removal surface.
Operation 68: The atom MUST NOT offer a core field update surface.
Operation 69: The atom MUST NOT offer a second dose event surface.
Operation 70: The atom MUST NOT offer a refill surface.
```

NOTE: watch the blank id (Operation 12).

NOTE: watch the blank filter value (Operation 85).

NOTE: watch the filter value over the cap (Operation 84).

NOTE: watch the untyped input (Operation 86, Term numeric input).

Term order action: [Amend] | [Verify] | [Hold] | [Reinstate] | [Dispense] | [Administer] | [Complete] | [Cancel] | [Discontinue] — every action naming an order by order id, including a refused one.

Term state-changing action: every order action, whether or not the call would change the order's state.

Term terminal state: completed | cancelled | discontinued.

Term inactive state: amended | completed | cancelled | discontinued — every state that admits no further transition.

Term pre-dispensing state: ordered | verified.

Term post-dispensing state: dispensed | administered.

Term actionable state: a pre-dispensing state OR a post-dispensing state — every state a hold may suspend.

Term inactive state's rejection: already-amended for amended, already-completed for completed, already-cancelled for cancelled, already-discontinued for discontinued.

Term state check: Operation 11, Operation 13, Operation 14, Operation 16 through 24 and Operation 26 — every check an order action makes on the order's own standing before reading the call's remaining inputs.

Term blank-input rejection: invalid-order for [Order], invalid-request for an order action.

Term required string input: patient reference, prescriber reference, medication reference, the dose unit, route and frequency of an [Order], reason, an attribution reference OR order id — every string an action refuses when blank.

Term future bound: (now + clock allowance).
NOTE: watch the future bound — now plus the clock allowance, the ceiling a supplied order instant is checked against (Clock semantics 4; Clock semantics 5 leaves a supplied event instant unbounded), declared here beside Execution Contract Logic confinement 18 and Offline 1, as Communication, Medication Order, Observation and Selective Disclosure each declare it.

Term query axes: order id, patient reference, medication reference, prescriber reference, state and a range over order instant — every filter axis [Read] admits.

Term query: the selection a [Read] call scopes the answer by — a filter value on any of the query axes, in any combination, or none; consumed per call, never stored.

Term string axes: order id | patient reference | medication reference | prescriber reference — the query axes whose filter value carries a string.

Term field group: the fields one transition writes, carried on the order from that transition onward.

Term hold field: prior state | holding actor | hold reason | hold instant — the fields an admitted hold writes, replaced by each new hold cycle.

Term reinstate field: reinstating actor | reinstatement instant — the fields an admitted reinstate writes, replaced by each new hold cycle.

Term reinstated order: an order an admitted reinstate returned to the order's prior state.

Term held: the answer an admitted hold returns — the order, now standing in on-hold.

Term reinstated: the answer an admitted reinstate returns — the order, back in the order's prior state.

Term new order id: the [Order Id] of the successor an admitted amend answers (Operation 42).

Term admitted order: an [Order] call the action admits (Execution Contract Read 4).

Term admitted amend: an [Amend] call the action admits (Execution Contract Read 4).

Term admitted verify: a [Verify] call the action admits (Execution Contract Read 4).

Term admitted hold: a [Hold] call the action admits (Execution Contract Read 4).

Term admitted reinstate: a [Reinstate] call the action admits (Execution Contract Read 4).

Term admitted dispense: a [Dispense] call the action admits (Execution Contract Read 4).

Term admitted administer: an [Administer] call the action admits (Execution Contract Read 4).

Term admitted complete: a [Complete] call the action admits (Execution Contract Read 4).

Term admitted cancel: a [Cancel] call the action admits (Execution Contract Read 4).

Term admitted discontinue: a [Discontinue] call the action admits (Execution Contract Read 4).

Term admitted read: a [Read] call that answers.

#### Invalid Request

The refusal an order action returns for a blank required string input, a string input over the length bound, a blank, non-positive or malformed [Quantity] or a non-positive or malformed [Dose] on an [Amend] (Execution Contract Input 1), or an [Amend] that supplies no dosing parameter or whose supplied dosing parameters all match the original. Reached only after every state check passes.

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: invalid-request

#### Not Known

The refusal an order action returns when the [Order Id] names no order in this database instance, where a blank one earns [Invalid Request].

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: not-known

#### On Hold Rejection

The refusal an order action whose signature carries it returns against an [On Hold] order. Answered before any rejection about the state underneath the hold, because the hold is what the caller must resolve first.

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: on-hold

#### Already Dispensed

The refusal [Amend] and [Cancel] return across the dispensing edge, and [Dispense] returns against an order already dispensed. One token, one fact: the medication has left the pharmacy.

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: already-dispensed

#### Not Dispensed

The refusal [Discontinue] returns on the near side of the dispensing edge, and [Administer] returns against an unreleased order. The mirror of [Already Dispensed], and the reason [Cancel] exists.

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: not-dispensed

#### Already Amended

The refusal returned against an order already [Amended] — inactive, so clinical work continues on the successor.

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: already-amended

#### Already Cancelled

The refusal returned against an order already [Cancelled] — terminal.

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: already-cancelled

#### Already Discontinued

The refusal returned against an order already [Discontinued] — terminal.

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: already-discontinued

#### Already Completed

The refusal returned against an order already [Completed] — terminal. [Amend] answers [Already Dispensed] there, the order having crossed the dispensing edge, and [Reinstate] answers [Not On Hold].

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: already-completed

#### Already On Hold

The refusal [Hold] returns against an order already [On Hold], where every other action but [Reinstate] answers the [On Hold Rejection].

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: already-on-hold

#### Already Administered

The refusal [Administer] returns against an order already [Administered]. A second dose event is a composing pattern's.

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: already-administered

#### Not In Ordered State

The refusal [Verify] returns against an order already [Verified], [Dispensed] or [Administered] — verified already, or past the verification stage.

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: not-in-ordered-state

#### Not Verified

The refusal [Dispense] returns against an order still [Ordered] — nothing is released on a prescription no pharmacist has read.

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: not-verified

#### Not Administered

The refusal [Complete] returns against an order not yet [Administered].

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: not-administered

#### Not On Hold

The refusal [Reinstate] returns against an order not [On Hold], an inactive order included.

Kind:       Member
Member of:  the order-action rejection
Role:       Outcome
Projection: not-on-hold

#### Storage Failure

The refusal any writing action returns when the database refuses the write, or the journal refuses the append of Operation 88 (Execution Contract Constituent failure 1, Execution Contract Database 1), after every precondition passes. No partial record is left.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Order

#### Order

The behavior that records a new [Order] — assigning a fresh [Order Id], recording every supplied core field, stamping [Order Instant], and standing the record in [Ordered]. Refused [Invalid Order] or [Storage Failure], never [Not Known]. Not idempotent: a retried call after a lost answer creates a second order.

Kind: Operation

```
order(patient_ref, prescriber_ref, medication_ref, dose, dose_unit, route, frequency, optional duration, optional clinical_evidence_ref, optional ordered_at)
  answers order_id
  refuses invalid-order | storage-failure
```

```
Operation 2: IF the dose EQUALS blank OR the dose DOES NOT EXCEED zero THEN [Order] MUST answer invalid-order.
Operation 3: IF the future bound PRECEDES a supplied order instant THEN [Order] MUST answer invalid-order.
Operation 86: IF the dose is malformed OR a supplied order instant is malformed THEN [Order] MUST answer invalid-order (Execution Contract Input 1).
Operation 5: An admitted order MUST assign a fresh order id.
Operation 6: An admitted order MUST record EVERY supplied core field.
Operation 87: An admitted order MUST record the resolved order instant.
Operation 7: An admitted order MUST stand the order in ordered.
Operation 8: An admitted order MUST answer the order id.
Operation 9: [Order] MUST NOT answer not-known.
Operation 65: A refused [Order] MUST NOT record an order.
```

#### Now

The wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it — never read inside the transition and never supplied by the business caller. It stamps every instant the caller did not supply, and raises the future bound the supplied [Order Instant] is checked against.

Kind:         Parameter
Parameter of: Order
Projection:   now

#### Invalid Order

The refusal [Order] returns when a required string input is blank or over the length bound, a supplied [Order Instant] exceeds the future bound or is malformed, or a [Dose] is blank, does not exceed zero or is malformed (Execution Contract Input 1).

Kind:       Member
Member of:  the Order rejection
Role:       Outcome
Projection: invalid-order

Term resolved order instant: the order instant the order carries — the supplied value, as Execution Contract Logic confinement 12 resolves it.

### Amend

#### Amend

The behavior that corrects a pre-dispensing order by recording a *successor* rather than editing the original. The successor carries the corrected dosing parameters, the inherited patient, prescriber, medication and clinical evidence reference, and a [Predecessor Id]; the original stands in [Amended] carrying a [Successor Id]. Legal only from a pre-dispensing state.

Kind: Operation

```
amend(order_id, amended_by, optional dose, optional dose_unit, optional route, optional frequency, optional duration, reason)
  answers new_order_id
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-dispensed | invalid-request | storage-failure
```

```
Operation 17: IF the order's state IS NOT IN the pre-dispensing states THEN [Amend] MUST answer already-dispensed.
Operation 29: IF [Amend] supplies no dosing parameter OR EVERY supplied dosing parameter matches the order's dosing parameter THEN [Amend] MUST answer invalid-request.
Operation 89: IF the dose DOES NOT EQUAL blank AND the dose DOES NOT EXCEED zero THEN [Amend] MUST answer invalid-request.
Operation 30: [Amend] MUST NOT accept a medication reference.
Operation 31: [Amend] MUST NOT accept a patient reference.
Operation 32: [Amend] MUST NOT accept a prescriber reference.
Operation 33: An admitted amend MUST record a successor order carrying the original's patient reference, prescriber reference, medication reference and clinical evidence reference.
Operation 34: An admitted amend MUST record EVERY supplied dosing parameter on the successor.
Operation 35: An admitted amend MUST record the original's unamended dosing parameter on the successor.
Operation 36: An admitted amend MUST record amending actor and reason as amendment reason on the successor.
Operation 37: An admitted amend MUST record the original's order id as the successor's predecessor id.
Operation 81: An admitted amend MUST record now as the successor's order instant.
Operation 38: An admitted amend MUST stand the successor in ordered.
Operation 39: An admitted amend MUST stand the original in amended.
Operation 40: An admitted amend MUST record the successor's order id as the original's successor id.
Operation 42: An admitted amend MUST answer the successor's order id.
Operation 66: A refused [Amend] MUST NOT record a successor order.
```

### Verify

#### Verify

The behavior that records a pharmacist's review and clearance, standing the order in [Verified] and recording [Verifier Reference] and [Verification Instant]. Legal only from [Ordered] — nothing is dispensed against a prescription no pharmacist has read. Refused [Not In Ordered State] on an order already verified or past the verification stage.

Kind: Operation

```
verify(order_id, verifier_ref)
  answers verified
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-in-ordered-state | invalid-request | storage-failure
```

```
Operation 16: IF the order's state DOES NOT EQUAL ordered THEN [Verify] MUST answer not-in-ordered-state.
Operation 43: An admitted verify MUST record verifier reference and now as verification instant.
Operation 44: An admitted verify MUST stand the order in verified.
```

### Hold

#### Hold

The behavior that suspends an order from any actionable state, recording the [State] it paused as [Prior State] along with [Holding Actor], [Hold Reason] and [Hold Instant]. An on-hold order refuses every action but [Reinstate], and a [Hold] of an on-hold order is refused [Already On Hold]. It answers [Held].

Kind: Operation

```
hold(order_id, held_by, reason)
  answers held
  refuses not-known | already-on-hold | already-amended | already-cancelled | already-discontinued | already-completed | invalid-request | storage-failure
```

```
Operation 26: IF the order's state EQUALS on-hold THEN [Hold] MUST answer already-on-hold.
Operation 45: An admitted hold MUST record the order's state as prior state.
Operation 46: An admitted hold MUST record holding actor, reason as hold reason and now as hold instant.
Operation 47: An admitted hold MUST stand the order in on-hold.
```

#### Held

The answer [Hold] gives where the order now stands in on-hold: the order, with the state it paused, the holding actor, the reason and the instant.

Kind:       Type
Projection: held

### Reinstate

#### Reinstate

The behavior that resumes a held order, returning it to the state its hold recorded. Takes no target state, so it cannot return an order anywhere else. Refused [Not On Hold] on any order not on hold. It answers [Reinstated].

Kind: Operation

```
reinstate(order_id, reinstated_by)
  answers reinstated
  refuses not-known | not-on-hold | invalid-request | storage-failure
```

```
Operation 27: IF the order's state DOES NOT EQUAL on-hold THEN [Reinstate] MUST answer not-on-hold.
Operation 48: An admitted reinstate MUST record reinstating actor and now as reinstatement instant.
Operation 49: An admitted reinstate MUST stand the order in the order's prior state.
Operation 50: [Reinstate] MUST NOT accept a target state.
```

#### Reinstated

The answer [Reinstate] gives where the order is back in the state its hold recorded: the order, with the reinstating actor and the instant.

Kind:       Type
Projection: reinstated

### Dispense

#### Dispense

The behavior that records the pharmacy releasing the medication, standing the order in [Dispensed] and recording [Dispenser Reference], [Quantity], an optional [Lot Number] and [Dispensing Instant]. The edge this action crosses is the one amendment and cancellation stop at. Refused [Not Verified] before a pharmacist's clearance.

Kind: Operation

```
dispense(order_id, dispenser_ref, quantity, optional lot_number, optional dispensed_at)
  answers dispensed
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-verified | already-dispensed | invalid-request | storage-failure
```

```
Operation 19: IF the order's state EQUALS ordered THEN [Dispense] MUST answer not-verified.
Operation 20: IF the order's state IS IN the post-dispensing states THEN [Dispense] MUST answer already-dispensed.
Operation 80: IF the quantity EQUALS blank OR the quantity DOES NOT EXCEED zero THEN [Dispense] MUST answer invalid-request.
Operation 51: An admitted dispense MUST record dispenser reference, quantity, a supplied lot number and the resolved dispensing instant.
Operation 52: An admitted dispense MUST stand the order in dispensed.
```

`dispense(ord_new, …)` before verification → not-verified — nothing is released on a prescription no pharmacist has read. `amend(ord_held, …)` → the [On Hold Rejection], not already-dispensed: the hold is reported first, because the caller must resolve the hold before learning anything about what is underneath it. `amend(ord_d1, dr_osei, dose: 10, reason: "…")` on a verified order whose dose already is 10 → invalid-request, and so does an amend that supplies no dosing parameter — an amendment that changes nothing is not an amendment. `cancel(ord_e1, "  ", reason: "…")` on an already-cancelled order → already-cancelled, not invalid-request: the state checks run first (Execution Contract Refusal 1).

Term resolved dispensing instant: the dispensing instant the order carries — the supplied value, as Execution Contract Logic confinement 12 resolves it.

### Administer

#### Administer

The behavior that records the medication given to the patient, standing the order in [Administered]. Records the first administration only, refusing a second [Already Administered]; a second dose event against one order is a composing pattern's.

Kind: Operation

```
administer(order_id, administerer_ref, optional administered_at)
  answers administered
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-dispensed | already-administered | invalid-request | storage-failure
```

```
Operation 21: IF the order's state IS IN the pre-dispensing states THEN [Administer] MUST answer not-dispensed.
Operation 22: IF the order's state EQUALS administered THEN [Administer] MUST answer already-administered.
Operation 53: An admitted administer MUST record administerer reference and the resolved administration instant.
Operation 54: An admitted administer MUST stand the order in administered.
```

Term resolved administration instant: the administration instant the order carries — the supplied value, as Execution Contract Logic confinement 12 resolves it.

### Complete

#### Complete

The behavior that closes an order after the course has been administered, standing it in [Completed] and recording [Completing Actor] and [Completion Instant]. Terminal. Refused [Not Administered] before any administration.

Kind: Operation

```
complete(order_id, completed_by, optional completed_at)
  answers completed
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-administered | invalid-request | storage-failure
```

```
Operation 23: IF the order's state DOES NOT EQUAL administered THEN [Complete] MUST answer not-administered.
Operation 55: An admitted complete MUST record completing actor and the resolved completion instant.
Operation 56: An admitted complete MUST stand the order in completed.
```

Term resolved completion instant: the completion instant the order carries — the supplied value, as Execution Contract Logic confinement 12 resolves it.

### Cancel

#### Cancel

The behavior that terminates an order *before* any dispensing, standing it in [Cancelled] and recording [Cancelling Actor], [Cancellation Reason] and [Cancellation Instant]. Terminal. Refused across the dispensing edge, where [Discontinue] is the remedy.

Kind: Operation

```
cancel(order_id, cancelled_by, reason)
  answers cancelled
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | already-dispensed | invalid-request | storage-failure
```

```
Operation 18: IF the order's state IS NOT IN the pre-dispensing states THEN [Cancel] MUST answer already-dispensed.
Operation 57: An admitted cancel MUST record cancelling actor, reason as cancellation reason and now as cancellation instant.
Operation 58: An admitted cancel MUST stand the order in cancelled.
```

### Discontinue

#### Discontinue

The behavior that terminates an order *after* dispensing has begun, standing it in [Discontinued] and recording [Discontinuing Actor], [Discontinuation Reason] and [Discontinuation Instant]. Terminal. Refused [Not Dispensed] before the dispensing edge, where [Cancel] is the remedy.

Kind: Operation

```
discontinue(order_id, discontinued_by, reason)
  answers discontinued
  refuses not-known | on-hold | already-amended | already-cancelled | already-discontinued | already-completed | not-dispensed | invalid-request | storage-failure
```

```
Operation 24: IF the order's state IS NOT IN the post-dispensing states THEN [Discontinue] MUST answer not-dispensed.
Operation 59: An admitted discontinue MUST record discontinuing actor, reason as discontinuation reason and now as discontinuation instant.
Operation 60: An admitted discontinue MUST stand the order in discontinued.
```

### Read

#### Read

The read-only query answering the matching [Order] records by [Order Instant] ascending, each carrying every field group its transitions wrote. Refuses a filter it cannot read ([Invalid Query]).

Kind: Operation

```
read(query)
  answers the matching orders
  refuses invalid-query
```

```
Operation 71: IF a filter axis falls outside the query axes THEN [Read] MUST answer invalid-query.
Operation 72: IF a filter value falls outside the axis's admitted values THEN [Read] MUST answer invalid-query.
Operation 84: IF a filter value EXCEEDS the length bound THEN [Read] MUST answer invalid-query.
Operation 85: IF a filter axis IS IN the string axes AND the filter value EQUALS blank THEN [Read] MUST answer invalid-query.
Operation 73: An admitted read MUST answer EVERY matching order.
Operation 74: An admitted read MUST answer the matching orders by order instant ascending.
Operation 82: An admitted read MUST order two orders sharing an order instant by order id ascending (Execution Contract Logic confinement 10).
Operation 75: An admitted read MUST answer EVERY field group the order carries.
Operation 76: An admitted read MUST answer an empty sequence where no order matches.
Operation 77: [Read] MUST NOT record a field.
```

#### Invalid Query

The refusal [Read] returns for a filter axis or a filter value it cannot read: a blank one on a string axis, one over the length bound, or one outside the axis's admitted values.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

## What is and what should never be (Invariants)

- **Invariant 1 — Order immutability.**
  ```
  Invariant 1.1: An action MUST NOT change a core field.
  ```
- **Invariant 2 — The successor inherits the identity fields.**
  ```
  Invariant 2.1: EVERY successor order MUST carry the original's patient reference, prescriber reference and medication reference.
  ```
- **Invariant 3 — Amendment is pre-dispensing only.**
  ```
  Invariant 3.1: [Amend] MUST change an order ONLY IF the order's state IS IN the pre-dispensing states.
  ```
- **Invariant 4 — Amendment chains are linear.**
  ```
  Invariant 4.1: An order MUST NOT carry two successor ids.
  Invariant 4.2: An order MUST NOT carry two predecessor ids.
  Invariant 4.3: EVERY successor order's predecessor id MUST name an order the database held before the successor was recorded.
  ```
- **Invariant 5 — A hold resumes where it paused.**
  ```
  Deleted: Invariant 5.1. Operation 49 owns it.
  ```
- **Invariant 6 — Cancel is pre-dispensing; discontinue is post-dispensing.**
  ```
  Invariant 6.1: [Cancel] MUST change an order ONLY IF the order's state IS IN the pre-dispensing states.
  Invariant 6.2: [Discontinue] MUST change an order ONLY IF the order's state IS IN the post-dispensing states.
  ```
- **Invariant 7 — A terminal state is absorbing.**
  ```
  Invariant 7.1: An order whose state IS IN the terminal states MUST NOT leave the terminal state.
  ```
- **Invariant 8 — An amended order is inactive.**
  ```
  Invariant 8.1: An order whose state EQUALS amended MUST NOT leave amended.
  ```
- **Invariant 9 — An on-hold order admits only a reinstate.**
  ```
  Deleted: Invariant 9.1. Operation 13 owns it.
  ```
- **Invariant 10 — Attribution is complete.**
  ```
  Invariant 10.1: EVERY attribution reference an order carries MUST stand as a value that DOES NOT EQUAL blank.
  ```
- **Invariant 11 — A reason is complete.**
  ```
  Invariant 11.1: EVERY reason field an order carries MUST stand as a value that DOES NOT EQUAL blank.
  ```
- **Invariant 12 — Transition metadata is write-once within its cycle.**
  ```
  Invariant 12.1: An action MUST NOT change a field a prior transition wrote beside the order's state, a hold field and a reinstate field.
  Deleted: Invariant 12.2. Operation 45 and Operation 46 own it.
  Deleted: Invariant 12.3. Operation 48 owns it.
  ```
- **Invariant 13 — The placement instant is set once.**
  ```
  Invariant 13.1: An action MUST NOT change an order's order instant.
  Invariant 13.2: EVERY successor order MUST carry the successor's own order instant.
  ```
- **Invariant 14 — Order record durability.**
  ```
  Invariant 14.1: The atom MUST NOT remove an order from the database.
  ```

---

## When something happens

### Indeterminate outcome

```
Indeterminate outcome 1: A caller MUST NOT retry an order action whose answer the caller lost BEFORE reading the order (Execution Contract Error model 1).
Indeterminate outcome 3: A caller MUST retry a lost [Amend] ONLY IF the original's state IS IN the pre-dispensing states (Execution Contract Error model 1).
```

### What undoes a write

No writing action of this atom is undone: Invariant 1.1, Invariant 12.1 and Invariant 14.1 keep what the actions write, and a correction runs as [Amend], [Cancel] or [Discontinue] (Execution Contract Undo 4).

## While something is so

### Clock semantics

```
Clock semantics 4: The atom MUST bound a supplied order instant from above by the future bound.
Clock semantics 5: The atom MUST NOT bound a supplied event instant.
```

Term event instant: dispensing instant | administration instant | completion instant — every instant a caller may supply for something that happened away from the call.

### String policy

```
String 1: The atom MUST compare a string input byte for byte.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a string input carrying only white space as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: IF a required string input EXCEEDS the length bound THEN an action MUST answer a blank-input rejection.
```

Term string input: a required string input OR a filter value — every caller-supplied string this atom accepts.

Term numeric input: a [Dose] OR a [Quantity] — every caller-supplied number this atom accepts.

---

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the id material at the seam.
Capability requirement 3: The deployment MUST declare the clock allowance PER Execution Contract Logic confinement 18.
Capability requirement 4: The deployment MUST supply the clock allowance at the seam PER Execution Contract Logic confinement 18.
Capability requirement 12: The deployment MAY declare the length bound PER Execution Contract Input 2.
Capability requirement 15: The deployment MUST supply the order records PER Execution Contract Database 1 through 7, Execution Contract Read 4 and Execution Contract Refusal 1.
Capability requirement 16: The deployment MUST supply id material whose assigned order id DOES NOT EXCEED the length bound.
```

NOTE: watch the id's length against the cap (Capability requirement 16).

Term seam: the atom's I/O boundary as `execution-contract.md` Logic confinement declares it; the host injects the clock reading, the id material and the clock allowance here.

Term transition: the atom's evaluation of one call against the order records, as `execution-contract.md` Logic confinement declares it.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term length bound: the maximum length of a string input in Unicode code points; 1,024 code points where a deployment declares none.

Term clock allowance: the non-negative duration the deployment declares as the margin the future bound allows, as Execution Contract Logic confinement 18 names it; zero declares no tolerance.

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice.

Term need key: key actor id; pairs orders.

Term need journal: records order events; calls append; arms event_id.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key order id; carried by orders; calls Read.

## Left to others

```
Non-goal 1: The atom MUST NOT change a medication reference.
Non-goal 2: A deployment needing a different medication MUST place a new order.
Non-goal 3: The atom MUST NOT amend an order across the dispensing edge.
Non-goal 4: The atom MUST NOT read a dosing parameter's clinical safety.
Non-goal 5: The atom MUST NOT read a drug interaction.
Non-goal 6: The atom MUST NOT read an allergy.
Non-goal 7: A deployment needing clinical decision support MUST compose a decision-support pattern.
Non-goal 8: The atom MUST NOT answer a repeated [Order] with one order.
Deleted: Non-goal 9. Non-goal 8 owns it: the atom answers a repeated [Order] with two orders, and which pattern makes an order idempotent is the app's choice.
Non-goal 10: The atom MUST NOT offer an entered-in-error state.
Non-goal 11: The atom MUST NOT record a second dose event.
Non-goal 12: A deployment needing a dose schedule MUST compose a dose-event pattern.
Non-goal 13: The atom MUST NOT bind an attribution reference to an actor.
Deleted: Non-goal 14. Non-goal 13 owns it: the atom binds no attribution reference to an actor, and which pattern attests an actor is the app's choice.
Non-goal 15: The atom MUST NOT decide who may call an action.
Deleted: Non-goal 16. Non-goal 15 owns it: the atom decides no caller's authority; the app's permission does.
Non-goal 17: The atom MUST NOT read a medication reference's schedule under regulation.
Non-goal 18: The atom MUST NOT detect a rewrite under the database.
Non-goal 19: The atom MUST NOT record a transition history.
Deleted: Non-goal 20. Non-goal 19 owns it: the atom records no transition history, and the full hold history is in the order events the atom appends through its journal need (Operation 88, Operation 90, Operation 91).
Non-goal 21: The atom MUST NOT model a refill.
Non-goal 22: The atom MUST NOT bound an order's retention.
Non-goal 23: The atom MUST NOT record an answer the atom gave.
Non-goal 24: The atom MUST NOT guarantee that an order reaches a terminal state.
Non-goal 25: A deployment needing a verifiable time anchor MUST compose a trusted time-stamping pattern.
```

NOTE: the owners — a decision-support pattern *(forthcoming)* (Non-goal 4 through 7); a dose-event pattern *(forthcoming)* (Non-goal 11, Non-goal 12, External check 2; Operation 69); [Tamper Evidence](./tamper-evidence.md) (Non-goal 18, External check 4); the atom's journal need, met by [Event Log](./event-log.md) (Non-goal 19, External check 1; Operation 88, Operation 90, Operation 91); a new order or a layer above (Non-goal 21; Operation 70); an idempotency pattern such as [Duplicate Prevention](./duplicate-prevention.md) (Non-goal 8, Composition note 8, External check 6); [Retention Window](./retention-window.md) (Non-goal 22, External check 7); [Retention Window](./retention-window.md) and [Legal Hold](./legal-hold.md) (State 14); a trusted timestamping pattern *(forthcoming)* (Non-goal 25).

---

```
Composition note 1: A composing pattern MUST own the authorization of a call.
Composition note 2: A composing pattern MUST own the attestation binding an attribution reference to an actor.
Deleted: Composition note 3. Operation 88 owns it: the atom appends one order events record through its own journal need for every admitted call.
Composition note 4: A composing pattern MUST own the record of a refused action.
Composition note 5: A composing pattern MUST own the tamper seal over the order records.
Composition note 6: A composing pattern MUST place an order under retention ONLY IF the order's state IS IN the terminal states.
Composition note 7: A composing pattern MUST own the hold that blocks a retention's purge.
Composition note 8: A composing pattern MUST own the map from an idempotency token to the order id an admitted order answered.
Composition note 9: A composing dose-event pattern MUST name the order id on EVERY dose event.
Composition note 10: A composing dose-event pattern MUST NOT change the order.
Composition note 11: A composing decision-support pattern MUST NOT advise BEFORE reading a dosing parameter.
Composition note 12: A composing decision-support pattern MUST NOT change a core field.
```

---

## Example

### Inpatient order through completion

`order(p77, dr_osei, med-lisinopril-10mg, 10, "mg", "oral", "QD", 30)` → `ord_a1`, standing ordered. `verify(ord_a1, rph_chen)` → verified. `dispense(ord_a1, tech_ruiz, 30, "LOT-4471")` → dispensed. `administer(ord_a1, rn_patel)` → administered, stamping [Administration Instant]. `complete(ord_a1, rn_patel)` → completed. The completed record carries all five field groups at once, and an auditor reads the whole chain — who prescribed, who verified, who released, who gave, who closed — from that one record.

### Amendment before dispensing

The dose is wrong. `ord_b1` stands verified at a dose of 10. `amend(ord_b1, dr_osei, dose: 20, reason: "titration per 2026-05-02 BP readings")` → `ord_b2`, the reason — a titration against the patient's blood pressure (BP) readings — recorded as the successor's [Amendment Reason]. `ord_b2` stands ordered carrying the corrected dose, the inherited patient, prescriber and medication, and `predecessor_id: ord_b1`; and `ord_b1` stands amended carrying `successor_id: ord_b2`. The successor starts in ordered rather than verified — the clinical content changed, so the pharmacist reviews it again.

### Hold and reinstate

`ord_c1` stands dispensed. `hold(ord_c1, rn_patel, "NPO for surgery 06:00")` → held (NPO: nothing by mouth), recording `prior_state: dispensed`. Every action but [Hold] and [Reinstate] now answers on-hold, and [Hold] answers already-on-hold. `reinstate(ord_c1, rn_patel)` → reinstated, recording [Reinstating Actor] and [Reinstatement Instant] and returning the order to dispensed — the action takes no target state, so it cannot return it anywhere else.

### The dispensing edge, from both sides

`amend(ord_disp, …)` on a dispensed order → already-dispensed; the remedy is [Discontinue] and a fresh order. `cancel(ord_disp, …)` → already-dispensed; the remedy is [Discontinue]. And from the near side, `discontinue(ord_new, …)` on an order still standing in ordered → not-dispensed; the remedy is [Cancel]. Three refusals, one edge, and the edge is where the medication left the pharmacy.

### Regulated adversarial scenarios

- **DEA controlled-substance audit.** *Account for every unit of this schedule II drug.* Filter by [Medication Reference] and read each order's terminal: a cancelled order means nothing was released, a discontinued one means something was and the course stopped, a completed one means an administration was recorded and the order closed, a second dose event being a composing dose-event pattern's (External check 2). Invariant 6.1 and Invariant 6.2 are what make that distinction structural rather than a matter of how the reason was worded.
- **Wrong-medication dispute.** *The patient received the wrong drug.* medication reference is fixed at placement and inherited unchanged by every successor (Invariant 2.1), and [Amend] cannot take one, so no order in the chain can name a drug the prescriber did not order. The dispute resolves to whether the right order was acted on, not to whether the record was edited.
- **Diversion investigation.** *Who touched this medication?* Every transition records its actor — the [Administerer Reference] on the dose, the [Dispenser Reference] on the release — no attribution may be blank (Invariant 10.1), and the atom removes no record (Invariant 14.1), short of what a composing retention pattern purged, which its purge records name (Execution Contract Database 6). The chain from prescriber to whoever closed the order is on one record, under one [Patient Reference]; what the atom cannot prove is that the database was not rewritten underneath it, which is another pattern's (External check 4).

---

## Source

- **HL7 FHIR (MedicationRequest / MedicationDispense / MedicationAdministration)** — the interoperability decomposition this atom deliberately does not follow. FHIR splits the lifecycle across three resources so independently operated systems can own separate pieces; this atom keeps one auditable chain inside a deployment, and the case for splitting arrives when a second pattern needs generic material-issuance semantics independent of a prescription.
- **DEA controlled-substance requirements (21 CFR — the US Code of Federal Regulations — Part 1300 et seq.)** — the attribution chain and the cancel/discontinue boundary are what a reconciliation reads. What attaches to a *scheduled* substance — registration, EPCS (Electronic Prescriptions for Controlled Substances) two-factor prescribing, refill limits, quantity caps — is outside this atom, because medication reference is opaque to it (Identity 13, Non-goal 17).
- **DEA EPCS non-alteration requirements** — met at a tamper-evidence layer another pattern provides. This atom's immutability is a property of its specified surface, not a cryptographic guarantee against a database administrator (External check 4).
- **HIPAA (US Health Insurance Portability and Accountability Act; 45 CFR 164.312)** — the audit-controls requirement applies to the order events the atom appends through its journal need (Operation 88) and to the audit pattern an app composes, rather than to the order record; retention under HIPAA and state law is a retention pattern's (Non-goal 22).
- **ISMP (Institute for Safe Medication Practices) and Joint Commission medication-management standards** — the verification-gates-dispensing sequence and the requirement that every step be attributed are the structural correlates. What a pharmacist should look *for* at verification is clinical practice, not this atom's (Non-goal 4 through 7).

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture, and the discipline of composing access control, non-repudiation, retention, tamper-evidence and decision support as separate concepts.
- **Grace Commons regulated-atom conventions** — the adversarial scenarios and the acceptance section, from `pressure-testing.md`.

---

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the order records, with their committed versions (Execution Contract Generation acceptance 1).

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY order whose state EQUALS EXACTLY ONE OF the states (State 1).
Check 1.2: An auditor MUST find no order leaving a terminal state across two committed versions of the order (Invariant 7.1; Execution Contract Generation acceptance 1).
Check 1.3: An auditor MUST find no order leaving amended across two committed versions of the order (Invariant 8.1; Execution Contract Generation acceptance 1).
Check 2.1: An auditor MUST find EVERY order's core fields unchanged across EVERY committed version of the order (Invariant 1.1; Execution Contract Generation acceptance 1).
Check 2.2: An auditor MUST find EVERY successor order carrying the original's patient reference, prescriber reference and medication reference (Invariant 2.1).
Check 2.3: An auditor MUST find no order carrying two successor ids (Invariant 4.1).
Check 2.4: An auditor MUST find no order carrying two predecessor ids (Invariant 4.2).
Check 2.5: An auditor MUST find a successor id naming an order on EVERY amended order (State 9).
Check 2.6: An auditor MUST find a predecessor id naming an order on EVERY successor order (State 10).
Check 3.1: An auditor MUST find no amended order that was dispensed (Invariant 3.1).
Check 3.2: An auditor MUST find no cancelled order carrying a dispense field group (Invariant 6.1).
Check 3.3: An auditor MUST find a dispense field group on EVERY discontinued order (Invariant 6.2).
Check 4.1: An auditor MUST find no attribution reference an order carries that EQUALS blank (Invariant 10.1).
Check 4.2: An auditor MUST find no reason field an order carries that EQUALS blank (Invariant 11.1).
Check 5.1: An auditor MUST find verifier reference and verification instant on EVERY dispensed order (State 2, State 13).
Check 5.2: An auditor MUST find a dispense field group on EVERY administered order (State 3, State 13).
Check 5.3: An auditor MUST find an administration field group on EVERY completed order (State 5, State 13).
Check 5.4: An auditor MUST find EVERY field a committed version of an order carries on EVERY later committed version of the order, holding the same value beside the order's state, a hold field and a reinstate field (State 13, Invariant 12.1; Execution Contract Generation acceptance 1).
Check 6.1: An auditor MUST find prior state, holding actor, hold reason and hold instant on EVERY on-hold order (State 11).
Check 8.1: An auditor MUST find no order id on two orders of one database instance (Identity 5).
Check 8.2: An auditor MUST reconstruct EVERY order's chain of custody from one read (State 13).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: A deployment needing an amendment chain's full hold history MUST read the order events the atom appends through the atom's journal need (Operation 45, Operation 46, Operation 88, Operation 90, Operation 91).
External check 2: A deployment needing a second dose event recorded MUST read the composing dose-event pattern (Operation 69, Non-goal 12).
External check 3: A deployment needing a caller authorized MUST read the app's permission (Non-goal 15).
External check 4: A deployment needing the database confirmed free of a retroactive edit MUST read the composing tamper-evidence pattern (Non-goal 18).
External check 5: A deployment needing a medication reference's controlled-substance schedule MUST read the composing formulary (Identity 13, Non-goal 17).
External check 6: A deployment needing a duplicate order prevented MUST read the composing idempotency pattern (Non-goal 8).
External check 7: A deployment needing an order's retention bounded MUST read the composing retention pattern (Non-goal 22).
External check 8: A deployment needing an attribution reference bound to an actor MUST read the composing attestation pattern (Identity 12, Non-goal 13).
```

---

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the deployment; the database; the database instance; the seam; the transition; a composing pattern; a caller; a prescriber; a pharmacist; a dispenser; an auditor; a regulator; an investigator; an order; a successor order; an original; an amended order; an on-hold order; a verified order; a dispensed order; an administered order; a completed order; a cancelled order; a discontinued order; a reinstated order; an action; an order action; a state-changing action; a refused action; a rejection; an opaque reference; a string input; a filter; a filter axis; a filter value; a field group.

Term records: order — one prescription's whole life, carrying order id, patient reference, prescriber reference, medication reference, dose, dose unit, route, frequency, order instant, a state, and — where a transition wrote them — duration, clinical evidence reference, verifier reference, verification instant, predecessor id, successor id, amending actor, amendment reason, prior state, holding actor, hold reason, hold instant, reinstating actor, reinstatement instant, dispenser reference, quantity, lot number, dispensing instant, administerer reference, administration instant, completing actor, completion instant, cancelling actor, cancellation reason, cancellation instant, discontinuing actor, discontinuation reason and discontinuation instant.

Term record verbs: identify, assign, generate, change, share, reuse, carry, stand, read, answer, record, replace, leave, admit, offer, hold, refuse, write, find, resolve, name, compare, normalize, confirm, match, route, register, create, pass, attest, cover, call, fall, precede, follow, sample, consume, supply, declare, compose, bind, decide, define, bound, reach, accept, trim, case-fold, compute, reproduce, reconstruct, verify, detect, guarantee, take, derive, expose, store, enumerate, distinguish, select, order, block, place, cancel, exceed, retry, model, remove, amend, append, map, advise, own.

Term value sets: state = ordered | verified | amended | on-hold | dispensed | administered | completed | cancelled | discontinued. terminal state = completed | cancelled | discontinued. inactive state = amended | completed | cancelled | discontinued. pre-dispensing state = ordered | verified. post-dispensing state = dispensed | administered. core field = patient reference | prescriber reference | medication reference | dose | dose unit | route | frequency | duration | clinical evidence reference | order instant. dosing parameter = dose | dose unit | route | frequency | duration. blank-input rejection = invalid-order | invalid-request. hold field = prior state | holding actor | hold reason | hold instant. reinstate field = reinstating actor | reinstatement instant.

Term bounds: future bound, length bound, clock allowance.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: order, order id, database instance, core field, dosing parameter, attribution reference, reference, seam, transition, now, order action, state-changing action, state, terminal state, inactive state, pre-dispensing state, post-dispensing state, actionable state, `inactive state's rejection`, state check, blank-input rejection, required string input, future bound, clock offset allowance, event instant, query, query axes, string axes, field group, hold field, reinstate field, reinstated order, held, reinstated, new order id, reason field, admitted order, admitted amend, admitted verify, admitted hold, admitted reinstate, admitted dispense, admitted administer, admitted complete, admitted cancel, admitted discontinue, admitted read, string input, numeric input, blank, length bound, resolved order instant, resolved dispensing instant, resolved administration instant, resolved completion instant, committed version.

Term reason field: amendment reason | hold reason | cancellation reason | discontinuation reason — every field recording why an action was taken.

Term composing pattern: a pattern an app composes beside this atom — one that decides who may call, attests an actor, seals the records against a rewrite, bounds retention, holds records against a purge or makes an order idempotent; a dose-event pattern, a decision-support pattern, a trusted timestamping pattern, a formulary.

Term cited: `execution-contract.md` Logic confinement — the seam and the transition.

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
[Held]: #held
[Reinstated]: #reinstated
[Patient Reference]: #patient-reference
[Prescriber Reference]: #prescriber-reference
[Medication Reference]: #medication-reference
[Dose]: #dose
[Dose Unit]: #dose-unit
[Route]: #route
[Frequency]: #frequency
[Duration]: #duration
[Clinical Evidence Reference]: #clinical-evidence-reference
[Order Instant]: #order-instant
[State]: #state
[Predecessor Id]: #predecessor-id
[Successor Id]: #successor-id
[Amending Actor]: #amending-actor
[Prior State]: #prior-state
[Verifier Reference]: #verifier-reference
[Verification Instant]: #verification-instant
[Dispenser Reference]: #dispenser-reference
[Quantity]: #quantity
[Lot Number]: #lot-number
[Dispensing Instant]: #dispensing-instant
[Administerer Reference]: #administerer-reference
[Holding Actor]: #holding-actor
[Hold Reason]: #hold-reason
[Hold Instant]: #hold-instant
[Completing Actor]: #completing-actor
[Completion Instant]: #completion-instant
[Cancelling Actor]: #cancelling-actor
[Cancellation Reason]: #cancellation-reason
[Cancellation Instant]: #cancellation-instant
[Discontinuing Actor]: #discontinuing-actor
[Discontinuation Reason]: #discontinuation-reason
[Discontinuation Instant]: #discontinuation-instant
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
[Administration Instant]: #administration-instant
[Amendment Reason]: #amendment-reason
[Reinstating Actor]: #reinstating-actor
[Reinstatement Instant]: #reinstatement-instant
[On Hold Rejection]: #on-hold-rejection
[Already Amended]: #already-amended
[Already Cancelled]: #already-cancelled
[Already Discontinued]: #already-discontinued
[Already Completed]: #already-completed
[Already On Hold]: #already-on-hold
[Already Administered]: #already-administered
[Not In Ordered State]: #not-in-ordered-state
[Not Verified]: #not-verified
[Not Administered]: #not-administered
[Not On Hold]: #not-on-hold

---

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — medication-order.als + 3 twins (the static data model: the amendment chain's shape, Invariant 2, 3 and 4 in one state, 2026-06-04); medication-order.tla + 17 twins (re-derived 2026-11-11 over one order's amendment chain under every order action, refusals in each refuses line's order, while the clock moves: Invariant 1.1, 2.1, 3.1, 4.1, 5.1, 6.1, 6.2, 7.1, 8.1, 9.1, 12.1 through 12.3, 13.1, 13.2 and 14.1, Invariant 2.1, 3.1 and 4.1 a cross-check with the Alloy model); nothing testable in Alloy for Invariant 1, 5 through 9 and 12 through 14: each compares an order with a later version of it or reads what a call answers, which a single state cannot show, so they are the TLA+ model's; coverage 2026-11-11 (unit `atoms/medication-order.md formal layer`): no owed rows, Invariant 10 and 11 unstatable (blank strings not modeled), 2026-11-11; model redraw deferred to Lean: medication-order.tla and its twins, Invariant 4.3, 5.1, 9.1, 12.2 and 12.3 (now Operation 49, 13, 45 through 46 and 48), State 13, Check 5.4, Operation 2, 80, 88, 90 and 91, 2026-11-26; model redraw deferred to Lean: medication-order.tla and its twins, Operation 13 (its subject now leaves out [Hold] and [Reinstate]), 2026-11-27
last gate: 2026-11-27 — Final Critique 9, a delta round, one reader (Linus opencode-go/mimo-v2.6-flash), frozen at 2f287cf7 — foundational count 1, cured, not clean, no sample (Operation 13 bound every order action, [Hold] and [Reinstate] included, so a held order's reinstate was refused on-hold and no transition left on-hold; the rule now names the two actions it leaves out, and Operation 26 and Operation 27 stand as their refusals; Linus's other foundational, Operation 82 against Execution Contract Read 5, was refuted since Operation 74 names the primary order, the order instant; refining cured: the future bound NOTE names the supplied order instant it checks, String 7 binds a required string input, the answers held and reinstated have entries; rhetorical: the state-changing action gloss is the definition); 2026-11-26 — Final Critique 8, a full round (GRID, EOS and Linus on opencode-go/glm-5.3-flash, opencode-go/minimax-m3 and opencode-go/mimo-v2.6-pro), frozen at f6b08fd4 — foundational count 6, cured, not clean, no sample (EOS's one foundational: Operation 88 fixed that one order events record is appended and what it carries nowhere, while External check 1 and the Non-goal 20 tombstone rest the full hold history on those records, and Invariant 12.2 overwrites the hold fields each cycle; cured by Operation 90 and Operation 91, which name what a hold's and a reinstate's record carry. Linus's first and second, that Invariant 12.1 forbade changing any field a prior transition wrote beside a hold field and a reinstate field, which the Order transition's state breaks at every later action, and that State 13 and Check 5.4 read a field group by value or by presence across a hold cycle; cured together: Invariant 12.1 excepts the order's state, State 13 owns presence (an order carries every field a prior transition wrote) and Check 5.4 tests the same value beside state, hold and reinstate fields. His third, that no rule refused a non-positive dose on an [Amend], cured by Operation 89. His fourth, that Term required string input named dose unit, route and frequency without the qualifier an [Amend] needs, so Operation 1 refused the worked example's amend, cured by naming them as an [Order]'s and dropping the two members no supplied string can fire. His sixth, that Indeterminate outcome 1 forbade retrying a lost [Order] before reading an order the caller cannot name, cured by scoping it to an order action, so a lost [Order] is the app's (Error model 1; Non-goal 8, Composition note 8, External check 6). His fifth, that Operation 13 and Invariant 9.1 oblige [Hold] and [Reinstate] to answer on-hold, placed rhetorical: Closed vocabulary 29 binds them only where the signature carries the outcome. The refining findings cured in the round: the four Invariants that obliged an act tombstoned to their Operations (Standard label 14), the answers held, reinstated and new_order_id declared as terms, clock offset allowance renamed clock allowance with Logic confinement 18 cited, an unused field fault term cut, the Read's query declared, a blank dose and quantity refused by name, a fractional dose admitted by name, Invariant 4.3 for the amendment chain's well-foundedness, the owners linked or marked forthcoming, and the undo sentence of Undo 4; the checker's thirty-two code-source hits placed none (the inactive states' codes are named by Term inactive state's rejection and their entries), its two code-entry hits (held, reinstated) are GRID's second refining finding, cured, and its acronym hit (II, the Roman numeral of a DEA schedule) placed none; model redraw deferred to Lean: see the formal line); 2026-11-05 — Final Critique 7, a delta round, frozen at ec26ba5 — foundational count 0, clean, one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./medication-order.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/medication-order.md`.

</details>

NOTE: End of Medication Order.
