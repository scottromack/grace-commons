---
title: Reserve from Pool
parent: Conceptual Compositions
nav_order: 18
has_toc: true
toc: true
---

# Reserve from Pool

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Reserve from Pool is a composition (a spec that wires two or more atoms — freestanding, self-contained pattern specs — together) that solves a problem none of its constituents solves alone: managing the full life of a reservation against a finite pool so that the pool's free count is always exactly right.

A request takes a provisional hold on one unit of a bounded pool; the hold is confirmed into a firm booking, cancelled, or allowed to time out; and at every instant the pool's `allocated` total equals the number of reservations still live against it.

It wires five constituents: Provisional Commitment (the per-reservation Held → Confirmed | Released | Expired state machine with its confirm-within-window guarantee), Capacity Constraint Enforcement (the bounded pool whose running total never exceeds its declared capacity), Duplicate Prevention (the retry guard that makes every reservation action safely repeatable), Event Log (the durable journal of every state change), and Actor Identity (the attestation — a record, checkable later, that the acting party presented a valid credential for this very act — that binds every act to a verifiable actor).

The composition's defining emergent guarantee (a property that appears only when atoms are combined — no single atom carries it) is **allocation coherence**: the pool's `allocated` count stays in exact lockstep with the set of reservations in a slot-holding state (Held or Confirmed). Three consequences follow. Confirmed reservations never exceed pool capacity — every [Reserve] gates on `Capacity Constraint.allocate`, which refuses past `capacity`. A cancelled or expired reservation returns its slot to the pool *exactly once* — the terminal transition, the pool `release` and the journal entry are written in one transaction, so no slot is leaked (a cancellation whose unit is never returned) and none is double-released (a unit returned twice, driving the count below the truth). And no reservation is confirmed unless its hold is still live at confirmation time — Provisional Commitment's confirm-within-window guarantee, surfaced at the composition layer, prevents confirming a slot that has already lapsed and been returned.

Beyond coherence, the composition makes every reservation action idempotent under retry (safe to repeat — a retried call returns the first call's outcome instead of acting twice) (the Idempotent Reservation precursor's contract, extended over the pool-aware surface), and records every state change as a durable, attributed Event Log entry. Its most common uses are airline and hospitality booking, event ticketing, hospital bed and resource allocation, and warehouse and supply-chain inventory reservation. Any system that must guarantee, from the pool count alone, that it never oversells and never strands inventory across the reserve/confirm/cancel/expire arc is a candidate for this composition.

---

## Intent

Every system that reserves a unit of a finite resource faces the same arc, and it is the same whether the resource is an airline seat, a hotel room, a hospital bed, an event ticket, or a unit of warehouse inventory: a request encumbers one unit of a bounded pool provisionally; the encumbrance resolves into a firm booking, a cancellation, or a timed-out lapse; and the pool's free count must reflect, at every instant, exactly how many units are spoken for. Get the binding between the per-reservation lifecycle and the pool arithmetic wrong and the system either oversells (two reservations confirmed against one slot) or strands inventory (a cancelled reservation whose slot is never returned). The arc is constant; the failure modes are constant; and they live precisely at the seam between *the reservation* and *the pool*.

Neither Provisional Commitment nor Capacity Constraint Enforcement, alone, closes that seam. Provisional Commitment owns the per-reservation state machine — Held → Confirmed | Released | Expired, with the confirm-within-window guarantee (Invariant 7) that a hold cannot be confirmed after its window has elapsed — but it holds *one* resource per commitment and, by its own specification, *"does not opine on pool-level rules"*; it has no notion of a bounded pool or a running total. Capacity Constraint Enforcement owns the pool arithmetic — `allocated ≤ capacity` (Invariant 4) enforced by precondition on `allocate`, and `allocated ≥ 0` (Invariant 5) enforced on `release` — but units are *fungible* at its grain: it tracks a running count, not per-allocation identities, and by its own specification *"the composing pattern supplies the per-allocation identity; this atom owns only the pool's arithmetic."* Capacity Constraint even admits `release` against a Closed pool *expressly so that a composing pattern like Provisional Commitment can return slots when its holds reach terminal states* — naming the seam, and naming this composition as the thing that lives there, without filling it. The binding that keeps `allocated` in lockstep with the live-reservation set — allocate-on-hold, hold-the-slot-through-confirm, release-on-terminal — belongs to no single constituent. It belongs to the composition, and this composition is that binding.

This is a composition, not a new primitive. The five constituents are unchanged; the composition is the wiring that makes them coherent as a single reservation surface. It introduces emergent actions — [Reserve], [Confirm Reservation], [Cancel Reservation], [Expire Reservation] — that bind a Provisional Commitment to a Capacity Constraint pool slot, deduplicate retries through Duplicate Prevention, attribute every act through Actor Identity, and journal every state change through Event Log. The [Reserve] action, in particular, wraps a capacity gate (`Capacity Constraint.allocate`), a provisional hold (`Provisional Commitment.place_hold`), a duplicate check, and a journaled, attributed event into one named surface, so that taking a slot is one ordered, recorded act whose pool effect is bound to the reservation — not a `place_hold` whose pool consequences leak into whatever code remembers to decrement the counter.

What the composition is *not*: it is not the resource-availability oracle (whether a *specific* seat or room is bookable belongs to Provisional Commitment's registry, upstream of the pool count); it is not the overbooking-policy engine (a deployment that deliberately oversells by N sets the pool's `capacity` above the physical count — that is a capacity the deployment declares, not a composition behavior); it is not the pricing, waitlist, or fulfillment surface; and it is not the audit-substrate composition (it journals to Event Log and attributes via Actor Identity directly, the lighter pairing, rather than composing the full tamper-evident Audit Trail — a deployment needing seals composes Audit Trail as a peer). Each is named in Non-goals.

---

## Composes

- **[Provisional Commitment](../atoms/provisional-commitment.md)** — the per-reservation hold lifecycle: Held, then Confirmed, Released or Expired, with the confirm-within-window guarantee and terminal absorption.
- **[Capacity Constraint Enforcement](../atoms/capacity-constraint-enforcement.md)** — the bounded pool whose running total never exceeds its declared capacity and never falls below zero.
- **[Duplicate Prevention](../atoms/duplicate-prevention.md)** — the time-bounded guard that makes every reservation action safe to repeat.
- **[Event Log](../atoms/event-log.md)** — the durable, append-only, totally ordered journal of every reservation act.
- **[Actor Identity](../atoms/actor-identity.md)** — the attestation that binds every act to a verifiable actor, and the composition's only credential check.

```
Composes 1: EXACTLY ONE Provisional Commitment instance MUST serve the composition.
Composes 2: EXACTLY ONE Capacity Constraint Enforcement instance MUST serve the composition.
Composes 3: EXACTLY ONE Duplicate Prevention instance MUST serve the composition.
Composes 4: EXACTLY ONE Event Log instance MUST serve the composition.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: EXACTLY ONE Actor Identity instance MUST serve the composition.
Composes 7: The composition MUST NOT change a constituent's spec.
Composes 8: The composition MUST make EVERY transition of the Provisional Commitment instance.
Composes 9: The composition MUST make EVERY allocate AND EVERY release against a pool the composition binds.
Composes 10: The composition MUST key a reservation by the reservation's commitment id.
Composes 11: The composition MUST configure the Duplicate Prevention instance with the idempotency window.
Composes 12: The composition MUST NOT verify a credential outside Actor Identity's attest.
Composes 13: The composition MUST read a pool's audit events through the pool event read.
Composes 14: The composition MUST NOT read a pool's audit events through Capacity Constraint Enforcement's query.
```

Term composition: this pattern's wiring of [Provisional Commitment](../atoms/provisional-commitment.md), [Capacity Constraint Enforcement](../atoms/capacity-constraint-enforcement.md), [Duplicate Prevention](../atoms/duplicate-prevention.md), [Event Log](../atoms/event-log.md) and [Actor Identity](../atoms/actor-identity.md) — the five actions, the reservation-to-pool binding and the token results map.

Term constituents: [Provisional Commitment](../atoms/provisional-commitment.md), [Capacity Constraint Enforcement](../atoms/capacity-constraint-enforcement.md), [Duplicate Prevention](../atoms/duplicate-prevention.md), [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md).

Term reservation: a Provisional Commitment the composition holds against one pool slot.

Term reservation id: the commitment id Provisional Commitment's place hold answers for a reservation.

Term journal: the Event Log instance's events, in sequence order, as the composition and an auditor read them.

Term journal entry: one event the composition appends to the journal.

---
## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the reservation-to-pool binding.
Composition state 2: The composition MUST key the reservation-to-pool binding by reservation id.
Composition state 3: A binding entry MUST carry the pool id.
Composition state 4: The composition MUST write a binding entry ONLY AFTER the reservation's reserve outcome entry lands.
Deleted: Composition state 5. Execution Contract Database 1 owns it.
Composition state 6: The composition MUST NOT remove a binding entry.
Composition state 7: The composition MUST NOT change a binding entry's pool id.
Deleted: Composition state 8. Execution Contract Database 1 owns it.
Deleted: Composition state 9. Execution Contract Database 1 owns it.
Composition state 10: The composition MUST rebuild a missing binding entry from the journal.
Composition state 11: The rebuild MUST take a binding entry's pool id from the reservation's reserve outcome entry.
Deleted: Composition state 12. Execution Contract Database 1 owns it.
Deleted: Composition state 13. Execution Contract Database 1 owns it.
Deleted: Composition state 14. Execution Contract Database 1 owns it.
Composition state 15: The rebuild MUST leave standing a binding entry whose reserve outcome entry is an aged entry.
Composition state 16: The composition MUST store the token results map.
Composition state 17: The composition MUST key the token results map by idempotency token.
Composition state 18: A token results entry MUST carry an action type, a parameters digest AND a result.
Composition state 19: The composition MUST take the parameters digest from the seam (Execution Contract Logic confinement 8).
Composition state 20: The parameters digest MUST NOT take the actor reference.
Composition state 21: The parameters digest MUST NOT take the credential.
Composition state 22: The composition MUST NOT evict a token results entry BEFORE Duplicate Prevention's check answers not-seen for the entry's token.
```

Term reservation-to-pool binding: the composition's map from a reservation id to the pool whose slot the reservation holds — the binding the composition exists to keep.

Term binding entry: one reservation's entry in the reservation-to-pool binding.

Term aged entry: a journal entry whose `recording instant + audit horizon` PRECEDES now — past which the entry's payload may be lawfully destroyed.

Term token results map: the composition's own map from an idempotency token to the answer recorded against the token.

Term action type: reserve | confirm_reservation | cancel_reservation | expire_reservation.

Term parameters digest: the collision-resistant digest of a call's business parameters, computed at the seam by the digest function — a [Parameters Digest].

Term business parameter: the pool id, the resource, the requester and the duration at [Reserve]; the reservation id at a resolving action — the inputs that decide an answer.

NOTE: Contract classification, per the section titled Composition state in `execution-contract.md` — the reservation-to-pool binding: derived index over the journal's reserve outcome entries (Composition state 10, Composition state 11), its entries whose reserve outcome entry is an aged entry extraction-pending against Erasure Tombstone *(forthcoming)* (Composition state 15); the token results map: extraction-pending, the proposed atom an *Idempotency Result Memo* (token → result, write-once, window-governed eviction), opened as a roadmap proposal (Composition state 16).

### Capability requirement

```
Capability requirement 1: A deployment MUST set the idempotency window.
Capability requirement 2: A deployment MUST declare a pool's capacity through Capacity Constraint Enforcement's declare pool.
Capability requirement 3: A deployment MUST declare the expiry sweep.
Deleted: Capability requirement 4. Execution Contract Database 1 owns it.
Deleted: Capability requirement 5. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Capability requirement 6. Execution Contract Database 1 owns it.
Deleted: Capability requirement 7. Execution Contract Database 1 owns it.
Deleted: Capability requirement 8. Execution Contract Database 1 owns it.
Deleted: Capability requirement 9. Execution Contract Database 1 owns it: the composition names no liveness sum for the compensation window to exceed.
Deleted: Capability requirement 10. Execution Contract Database 1 owns it.
Deleted: Capability requirement 11. Execution Contract Database 1 owns it.
Deleted: Capability requirement 12. Execution Contract Database 3 owns it.
Deleted: Capability requirement 13. Execution Contract Database 3 owns it.
Deleted: Capability requirement 14. Execution Contract Database 3 owns it.
Capability requirement 15: The Event Log instance MUST answer a payload predicate on the idempotency token, the reservation id, the pool id AND the action.
Deleted: Capability requirement 16. Execution Contract Database 1 owns it.
Capability requirement 17: A deployment MUST supply the pool event read.
Deleted: Capability requirement 18. Execution Contract Database 1 owns it.
Capability requirement 19: The pool event read MUST address an audit event by the event id the call answered.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it.
Deleted: Capability requirement 22. Execution Contract Database 2 owns it.
Deleted: Capability requirement 23. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 24. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 25. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to lease.
Deleted: Capability requirement 26. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Capability requirement 27: A deployment MUST set the token max length.
Capability requirement 28: A deployment MUST set the digest function.
Capability requirement 29: The retention floor MUST NOT EXCEED the audit horizon.
Deleted: Capability requirement 30. Execution Contract Database 3 owns it.
Capability requirement 31: A deployment MUST set the digest function alike across EVERY instance sharing the token results map.
Deleted: Capability requirement 32. Execution Contract Database 3 owns it.
Deleted: Capability requirement 33. Execution Contract Database 3 owns it.
Deleted: Capability requirement 34. Execution Contract Database 3 owns it.
Capability requirement 35: A deployment MUST resolve Duplicate Prevention's check fail-closed.
Deleted: Capability requirement 36. Execution Contract Database 3 owns it.
Capability requirement 37: A deployment MUST retain the actor registry's historical public material.
Deleted: Capability requirement 38. Execution Contract Database 3 owns it.
Capability requirement 39: The host MUST inject now at the composition's seam once per invocation.
Capability requirement 40: The composition MUST NOT read the clock inside a transition.
Capability requirement 41: The composition MUST stamp EVERY journal entry an invocation writes from the invocation's now.
Capability requirement 42: The composition MUST NOT compare the composition's now with a constituent's stamp.
Capability requirement 43: The composition MUST NOT mint an id inside a transition.
Capability requirement 44: The composition MUST NOT store a clock-derived flag.
Capability requirement 45: The composition MUST NOT derive a hold's deadline.
Capability requirement 46: The composition MUST order reservation events by the journal's sequence numbers.
Capability requirement 47: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
```

Term idempotency window: the duration the Duplicate Prevention instance guards a token — chosen to cover the slowest legitimate retry of the most critical action.

Term expiry sweep: eager | lazy — the deployment's strategy for calling [Expire Reservation] on a lapsed hold: a scheduled call at the hold's expiry instant, or a call on the hold's next observation.

Term pool event read: the deployment-supplied read of a pool's persisted record — an audit event addressable by the event id a call answered.

Term token max length: the byte cap on an idempotency token, sized against the journal's payload cap.

Term digest function: the hash function and serialization convention computing the parameters digest.

Term audit horizon: the journal's retention horizon — where the journal is the Audit Trail substrate, the substrate's purge horizon.

Term retention floor: `longest reservation lifetime + coherence proof period`.

Term longest reservation lifetime: the longest a reservation stands from [Reserve] to a slot-returning outcome entry.

Term coherence proof period: the period over which allocation coherence must be provable from the journal.

Term seam: the composition's input and output boundary — the one place the host reads the clock and hands the reading to the composition, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam, once per invocation.

### Primitive policy

```
Primitive policy 1: IF the idempotency token EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 2: IF the idempotency token EXCEEDS the token max length THEN the action MUST answer invalid-request.
Primitive policy 3: The composition MUST compare an idempotency token byte-exact.
Primitive policy 4: The composition MUST NOT normalize an idempotency token.
Primitive policy 5: IF the credential EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 6: The composition MUST NOT read the credential's content.
Primitive policy 7: The composition MUST validate EVERY field an action passes to a constituent PER the constituent's own field rules.
Primitive policy 8: IF the action's envelope EXCEEDS the payload cap THEN the action MUST answer invalid-request.
Primitive policy 9: An action MUST NOT record the action's intent entry BEFORE validating the action's inputs.
Primitive policy 10: An action refused under Primitive policy 1 through 8 MUST NOT write.
```

Term envelope: the largest journal entry an act can cause.

### Action wiring

```
reserve(pool_id, resource, requester, duration, actor_ref, credential, idempotency_token)
  answers reservation_id
  refuses invalid-request | invalid-credential | token-collision | not-known | pool-closed | pool-capacity-exceeded | resource-unavailable | recording-failure(position)

confirm_reservation(reservation_id, actor_ref, credential, idempotency_token)
  answers ok
  refuses invalid-request | invalid-credential | token-collision | not-known | not-held | window-elapsed | recording-failure(position)

cancel_reservation(reservation_id, actor_ref, credential, idempotency_token)
  answers ok
  refuses invalid-request | invalid-credential | token-collision | not-known | not-held | window-elapsed | recording-failure(position)

expire_reservation(reservation_id, actor_ref, credential, idempotency_token)
  answers ok
  refuses invalid-request | invalid-credential | token-collision | not-known | not-held | window-not-elapsed | recording-failure(position)

query_reservation(reservation_id)
  answers reservation reading
  refuses not-known
```

Term position: intent | outcome | inconsistency — the retry bit a recording-failure carries: nothing committed and the act may run again; an act under the token reached or may have reached the act's commit and must not run again; or the composition's own records disagree with a constituent's, which no retry cures.

Term reservation reading: the reservation's state, the binding entry's pool id and the slot-held reading.

Term slot-held reading: true | false — whether the reservation holds a pool slot now.

```
Action wiring 1: EVERY state-changing action MUST take an idempotency token.
Deleted: Action wiring 2. Execution Contract Database 2 owns it.
Deleted: Action wiring 3. Execution Contract Database 2 owns it.
Deleted: Action wiring 4. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Action wiring 5: IF Duplicate Prevention's check answers seen AND a matching token results entry EXISTS THEN the action MUST answer the entry's result.
Action wiring 6: IF a token results entry's action type DOES NOT EQUAL the call's action type THEN the action MUST answer token-collision.
Action wiring 7: IF a token results entry's parameters digest DOES NOT EQUAL the call's parameters digest THEN the action MUST answer token-collision.
Action wiring 8: A replay MUST NOT call a constituent.
Action wiring 9: A replay MUST NOT write a journal entry.
Action wiring 10: IF Duplicate Prevention's check answers seen AND no token results entry EXISTS for the token THEN the action MUST answer recording-failure carrying outcome.
Action wiring 11: The composition MUST NOT settle an answer for a seen token carrying no token results entry.
Action wiring 12: IF Duplicate Prevention's check answers not-seen THEN the action MUST read the journal for the token.
Action wiring 13: An action MUST NOT call Actor Identity's attest BEFORE reading the journal for a not-seen token.
Action wiring 14: IF the journal holds the action's outcome entry for the token AND the journaled digest EQUALS the call's parameters digest THEN the action MUST settle the outcome entry's result.
Action wiring 15: IF the journal holds an entry for the token whose action DOES NOT EQUAL the call's action OR whose journaled digest DOES NOT EQUAL the call's parameters digest THEN the action MUST answer token-collision.
Deleted: Action wiring 16. Execution Contract Database 1 owns it.
Deleted: Action wiring 17. Execution Contract Database 1 owns it.
Action wiring 18: IF the journal holds a reserve outcome entry for the token AND no binding entry EXISTS for the entry's reservation id THEN [Reserve] MUST write the binding entry from the outcome entry.
Action wiring 19: IF the journal holds the action's intent entry for the token AND no resolving entry names the token THEN the action MUST settle recording-failure carrying outcome.
Action wiring 20: A state-changing action MUST call Actor Identity's attest with the action reference, the actor reference AND the credential.
Action wiring 21: A state-changing action MUST NOT call a constituent write BEFORE Actor Identity's attest answers the attestation id.
Action wiring 22: IF Actor Identity answers invalid-credential THEN the action MUST answer invalid-credential.
Action wiring 23: IF Actor Identity answers invalid-request THEN the action MUST answer invalid-request.
Action wiring 24: IF Actor Identity answers storage-failure THEN the action MUST answer recording-failure carrying intent.
Action wiring 25: The composition MUST NOT settle an attest refusal.
Action wiring 26: A state-changing action MUST record the action's intent entry ONLY AFTER Actor Identity answers the attestation id.
Action wiring 27: An intent entry MUST carry the action, the idempotency token, the attestation id, the actor reference, the now AND the action's business parameters.
Action wiring 28: A resolving action's intent entry MUST carry the binding entry's pool id.
Action wiring 29: IF Event Log answers storage-failure at an intent entry THEN the action MUST answer recording-failure carrying intent.
Action wiring 30: The composition MUST NOT settle a refused intent entry.
Action wiring 31: IF Event Log answers invalid-payload THEN the composition MUST answer recording-failure carrying the entry's position.
Action wiring 32: The deployment MUST alert on an invalid-payload as the composition's own defect.
Deleted: Action wiring 33. Execution Contract Database 2 owns it.
Deleted: Action wiring 34. Execution Contract Database 2 owns it.
Deleted: Action wiring 35. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion for a later write to hold.
Deleted: Action wiring 36. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to lose.
Deleted: Action wiring 37. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to take again.
Deleted: Action wiring 38. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 39. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 40. Execution Contract Database 1 owns it.
Deleted: Action wiring 41. Execution Contract Database 1 owns it.
Deleted: Action wiring 42. Execution Contract Database 1 owns it.
Deleted: Action wiring 43. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 44. Execution Contract Database 1 owns it.
Action wiring 45: An admitted reserve MUST call Capacity Constraint Enforcement's allocate with the pool id, a count of one AND the actor reference ONLY AFTER the intent entry lands.
Action wiring 46: IF Capacity Constraint Enforcement answers not-known for an allocate THEN [Reserve] MUST answer not-known.
Action wiring 47: IF Capacity Constraint Enforcement answers over-capacity THEN [Reserve] MUST answer pool-capacity-exceeded.
Action wiring 48: IF Capacity Constraint Enforcement answers suspended THEN [Reserve] MUST answer pool-closed.
Action wiring 49: IF Capacity Constraint Enforcement answers closed THEN [Reserve] MUST answer pool-closed.
Action wiring 50: IF Capacity Constraint Enforcement answers invalid-request for an allocate THEN [Reserve] MUST answer invalid-request.
Action wiring 51: IF Capacity Constraint Enforcement answers storage-failure for an allocate THEN [Reserve] MUST answer recording-failure carrying intent.
Action wiring 52: An admitted reserve MUST settle EVERY allocate refusal.
Action wiring 53: An admitted reserve MUST call Provisional Commitment's place hold with the resource, the requester AND the duration ONLY AFTER allocate answers the allocation event id.
Action wiring 54: IF Provisional Commitment answers invalid-request for a place hold THEN [Reserve] MUST answer invalid-request.
Action wiring 55: IF Provisional Commitment answers resource-unavailable THEN [Reserve] MUST answer resource-unavailable.
Action wiring 56: IF Provisional Commitment answers storage-failure for a place hold THEN [Reserve] MUST answer recording-failure carrying intent.
Deleted: Action wiring 57. Execution Contract Database 1 owns it.
Deleted: Action wiring 58. Execution Contract Database 1 owns it.
Deleted: Action wiring 59. Execution Contract Database 1 owns it.
Deleted: Action wiring 60. Execution Contract Database 1 owns it.
Action wiring 61: An admitted reserve MUST settle a place hold refusal.
Action wiring 62: An admitted reserve MUST record the reserve outcome entry ONLY AFTER place hold answers the reservation id.
Action wiring 63: A reserve outcome entry MUST carry the idempotency token, the reservation id, the pool id, Held as the new state, the pool event balances, the allocation event id, the attestation id AND the actor reference.
Action wiring 64: An outcome entry citing a pool event MUST copy the pool event balances from the pool event through the pool event read.
Deleted: Action wiring 65. Execution Contract Database 1 owns it.
Deleted: Action wiring 66. Execution Contract Database 1 owns it.
Deleted: Action wiring 67. Execution Contract Database 1 owns it.
Deleted: Action wiring 68. Execution Contract Database 1 owns it.
Deleted: Action wiring 69. Execution Contract Database 1 owns it.
Deleted: Action wiring 70. Execution Contract Database 1 owns it.
Deleted: Action wiring 71. Execution Contract Database 1 owns it.
Deleted: Action wiring 72. Execution Contract Database 1 owns it.
Deleted: Action wiring 73. Execution Contract Database 1 owns it.
Deleted: Action wiring 74. Execution Contract Database 1 owns it.
Deleted: Action wiring 75. Execution Contract Database 1 owns it.
Deleted: Action wiring 76. Execution Contract Database 1 owns it.
Deleted: Action wiring 77. Execution Contract Database 1 owns it.
Action wiring 78: An admitted reserve MUST write the binding entry carrying the pool id ONLY AFTER the reserve outcome entry lands.
Action wiring 79: An admitted reserve MUST settle the reservation id ONLY AFTER place hold answers the reservation id.
Action wiring 80: IF a resolving action's reservation id names no binding entry THEN the action MUST answer not-known.
Action wiring 81: A resolving action MUST NOT write for a reservation id naming no binding entry.
Action wiring 82: IF Provisional Commitment answers not-known to a resolving action's transition THEN the action MUST answer recording-failure carrying inconsistency.
Action wiring 83: The composition MUST settle EVERY recording-failure carrying inconsistency.
Action wiring 84: The deployment MUST alert on a recording-failure carrying inconsistency as the composition's own defect.
Action wiring 85: IF Provisional Commitment answers not-held to a resolving action's transition THEN the action MUST answer not-held.
Action wiring 86: IF Provisional Commitment answers window-elapsed to a resolving action's transition THEN the action MUST answer window-elapsed.
Action wiring 87: IF Provisional Commitment answers window-not-elapsed to a resolving action's transition THEN the action MUST answer window-not-elapsed.
Action wiring 88: IF Provisional Commitment answers storage-failure to a resolving action's transition THEN the action MUST answer recording-failure carrying intent.
Action wiring 89: The composition MUST settle EVERY guard refusal of a resolving action's transition.
Action wiring 90: [Confirm Reservation] MUST call Provisional Commitment's confirm with the reservation id ONLY AFTER the intent entry lands.
Action wiring 91: [Confirm Reservation] MUST NOT call a Capacity Constraint Enforcement write.
Action wiring 92: [Confirm Reservation] MUST record the confirm outcome entry ONLY AFTER confirm answers ok.
Action wiring 93: A confirm outcome entry MUST carry the idempotency token, the reservation id, the pool id, Held as the prior state, Confirmed as the new state, the witness balance, the attestation id AND the actor reference.
Deleted: Action wiring 94. Execution Contract Database 1 owns it.
Action wiring 95: The composition MUST NOT compensate a confirm.
Action wiring 96: [Confirm Reservation] MUST settle ok ONLY AFTER confirm answers ok.
Action wiring 97: [Cancel Reservation] MUST call Provisional Commitment's release with the reservation id ONLY AFTER the intent entry lands.
Action wiring 98: [Expire Reservation] MUST call Provisional Commitment's expire with the reservation id ONLY AFTER the intent entry lands.
Deleted: Action wiring 99. Execution Contract Database 1 owns it.
Deleted: Action wiring 100. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 101. Execution Contract Database 1 owns it.
Deleted: Action wiring 102. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 103. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 104. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 105. Execution Contract Database 1 and Execution Contract Database 2 own it.
Action wiring 106: A slot-returning action MUST call Capacity Constraint Enforcement's release with the pool id, a count of one AND the actor reference ONLY AFTER the action's transition answers ok.
Deleted: Action wiring 107. Execution Contract Database 1 owns it.
Deleted: Action wiring 108. Execution Contract Database 1 owns it.
Deleted: Action wiring 109. Execution Contract Database 1 owns it.
Action wiring 110: A slot-returning action MUST record the action's outcome entry ONLY AFTER Capacity Constraint Enforcement's release answers the release event id.
Action wiring 111: A slot-returning outcome entry MUST carry the idempotency token, the reservation id, the pool id, Held as the prior state, the terminal state, the pool event balances, the release event id, the attestation id AND the actor reference.
Deleted: Action wiring 112. Execution Contract Database 1 owns it.
Action wiring 113: A slot-returning action MUST settle ok ONLY AFTER Capacity Constraint Enforcement's release answers the release event id.
Action wiring 114: [Query Reservation] MUST NOT take an idempotency token.
Action wiring 115: [Query Reservation] MUST NOT write.
Action wiring 116: IF the reservation id names no binding entry THEN [Query Reservation] MUST answer not-known.
Action wiring 117: [Query Reservation] MUST answer the reservation's state from Provisional Commitment, the binding entry's pool id AND the slot-held reading.
Action wiring 118: The slot-held reading MUST read true ONLY IF the reservation's state IS IN the slot-holding states.
```

Term state-changing action: [Reserve] | [Confirm Reservation] | [Cancel Reservation] | [Expire Reservation].

Term resolving action: [Confirm Reservation] | [Cancel Reservation] | [Expire Reservation].

Term slot-returning action: [Cancel Reservation] | [Expire Reservation].

Term settling: writing an answer to the token results map against the token, calling Duplicate Prevention's record, and answering the caller — the cache-the-failure rule, which settles a rejection exactly as an answer.

Term replay: a call answered from a matching token results entry.

Term matching token results entry: a token results entry whose action type AND parameters digest equal the call's.

Term action reference: `<action type>:<idempotency token>` — the per-invocation reference Actor Identity binds an attestation to; an [Action Reference].

Term journaled digest: the parameters digest the seam recomputes from an intent entry's business parameters.

Term intent entry: a reserve intent, a confirm intent, a cancel intent or an expire intent — the journal entry an action appends before any constituent call that commits.

Term outcome entry: a reserve outcome entry, a confirm outcome entry or a slot-returning outcome entry — the journal entry an action appends after the action's act.

Term slot-returning outcome entry: a cancel outcome entry or an expire outcome entry.

Term resolving entry: an outcome entry naming a token.

Term admitted reserve: a [Reserve] call whose attest answered the attestation id and whose reserve intent landed.

Term pool event balances: the opening balance and closing balance of the pool event an outcome entry cites.

Term witness balance: one reading of the pool's allocated through Capacity Constraint Enforcement's query, carried as both balances on a confirm outcome entry — a witness that the slot stayed counted, never a chain link.

Term terminal state: Released for [Cancel Reservation]; Expired for [Expire Reservation].

### Wiring decision

```
Wiring decision 1: The composition MUST record the reservation holding a pool slot in the reservation-to-pool binding.
Wiring decision 2: The composition MUST NOT place a hold BEFORE allocating the hold's slot.
Wiring decision 3: The composition MUST NOT release a Confirmed reservation's slot.
Deleted: Wiring decision 4. Execution Contract Database 1 owns it.
Deleted: Wiring decision 5. Execution Contract Database 1 owns it.
Wiring decision 6: The composition MUST release a slot ONLY IF a slot-returning transition owes the slot.
```

Term slot-holding state: Held | Confirmed — a reservation in either state counts against the pool's allocated.

Term slot-returning state: Released | Expired — the two constituent-terminal states that give the slot back.

Term constituent-terminal state: Confirmed | Released | Expired — Provisional Commitment's absorbing states; Confirmed among them keeps the slot.

WHY:
*Principle.* A reservation system must, from the pool count alone, never confirm more reservations than capacity and never lose a freed slot. Structurally the pool's running total and the live-reservation set must move together: a reservation enters the live set exactly when it takes a slot and leaves exactly when its slot is returned.

*Likely objection.* Capacity Constraint Enforcement already bounds allocated by capacity, and Provisional Commitment already owns the reservation state machine. Why not let the caller allocate on place hold and release on the terminal transition?

*Mechanism.* Neither constituent knows the other, and the seam between them is exactly where coherence breaks. The pool keeps a fungible count with no per-allocation identity, so it cannot know that *this* release corresponds to *that* lapsed hold, or refuse a slot released twice for one reservation. The commitment has per-reservation identity and no notion of a pool — its release and expire decrement nothing. A caller wiring the two by hand re-implements the binding at every call site, and the first site that releases a slot for a reservation already lapsed (double release, count below the truth), transitions a hold terminal without releasing (leak, count above the truth), or confirms a hold whose slot an expiry sweep already returned (oversell) breaks coherence silently. The composition owns the binding (Wiring decision 1): [Reserve] allocates, then holds (Wiring decision 2); [Confirm Reservation] keeps the slot (Wiring decision 3); [Cancel Reservation] and [Expire Reservation] resolve the commitment and then release the slot. And the confirm-within-window guarantee — Provisional Commitment's, surfaced as window-elapsed — forecloses confirming a slot an expiry already returned.

*Result.* Allocation coherence is structural. An auditor, or the pool's own query, reads allocated and can trust it equals the live reservations against the pool. The three failure modes that define reservation bugs — oversell, leak, double release — are each foreclosed by a named mechanism: every [Reserve] gated on allocate, every slot-returning transition releasing exactly once, and the window guard. No other path releases a slot (Wiring decision 6).

### Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 2. Execution Contract Database 1 owns it.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Deleted: Reconciliation 4. Execution Contract Database 1 owns it.
Deleted: Reconciliation 5. Execution Contract Database 1 owns it.
Deleted: Reconciliation 6. Execution Contract Database 1 owns it.
Deleted: Reconciliation 7. Execution Contract Database 1 owns it.
Deleted: Reconciliation 8. Execution Contract Database 1 owns it.
Deleted: Reconciliation 9. Execution Contract Database 1 owns it.
Deleted: Reconciliation 10. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Reconciliation 11. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Reconciliation 12. Execution Contract Database 1 owns it.
Deleted: Reconciliation 13. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Reconciliation 14. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Reconciliation 15. Execution Contract Database 1 owns it.
Deleted: Reconciliation 16. Execution Contract Database 1 owns it.
Deleted: Reconciliation 17. Execution Contract Database 1 owns it.
Deleted: Reconciliation 18. Execution Contract Database 1 owns it.
Deleted: Reconciliation 19. Execution Contract Database 1 owns it.
Deleted: Reconciliation 20. Execution Contract Database 1 owns it.
Deleted: Reconciliation 21. Execution Contract Database 1 owns it.
Deleted: Reconciliation 22. Execution Contract Database 1 owns it.
Deleted: Reconciliation 23. Execution Contract Database 1 owns it.
Deleted: Reconciliation 24. Execution Contract Database 1 owns it.
Deleted: Reconciliation 25. Execution Contract Database 1 owns it.
Deleted: Reconciliation 26. Execution Contract Database 1 owns it.
Deleted: Reconciliation 27. Execution Contract Database 1 owns it.
Deleted: Reconciliation 28. Execution Contract Database 1 owns it.
Deleted: Reconciliation 29. Execution Contract Database 1 owns it.
Deleted: Reconciliation 30. Execution Contract Database 1 owns it.
Deleted: Reconciliation 31. Execution Contract Database 1 owns it.
Deleted: Reconciliation 32. Execution Contract Database 1 owns it.
Deleted: Reconciliation 33. Execution Contract Database 1 owns it.
Deleted: Reconciliation 34. Execution Contract Database 1 owns it.
Deleted: Reconciliation 35. Execution Contract Database 1 owns it.
Deleted: Reconciliation 36. Execution Contract Database 1 owns it.
Deleted: Reconciliation 37. Execution Contract Database 1 owns it.
Deleted: Reconciliation 38. Execution Contract Database 1 owns it.
Deleted: Reconciliation 39. Execution Contract Database 1 and Execution Contract Database 2 own it.
```

Term bound slot-holding count: the count of a pool's bound reservations in a slot-holding state.

---

## Composition-level invariants

These emerge from the composition; none belongs to one constituent.

- **Invariant 1 — Allocation coherence.**
  ```
  Invariant 1.1: At quiescence a pool's allocated MUST NOT EXCEED the pool's bound slot-holding count.
  Deleted: Invariant 1.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 1.3. Execution Contract Database 1 owns it.
  Deleted: Invariant 1.4. Execution Contract Database 1 owns it.
  Invariant 1.5: At quiescence a pool's bound slot-holding count MUST NOT EXCEED the pool's allocated.
  ```
  Term quiescence: a pool state in which no [Reserve] against the pool is in flight.

  Term divergence: `allocated − bound slot-holding count` for one pool.

- **Invariant 2 — Slot returned at most once.**
  ```
  Invariant 2.1: The composition MUST NOT commit two pool releases for one reservation.
  ```
- **Invariant 3 — Confirmed reservations never exceed capacity.**
  ```
  Invariant 3.1: A pool's Confirmed reservations MUST NOT EXCEED the pool's capacity.
  ```
- **Invariant 4 — No confirmation of a lapsed hold.**
  ```
  Invariant 4.1: The composition MUST NOT confirm a reservation whose window reading EQUALS lapsed.
  Invariant 4.2: A lapsed hold MUST resolve ONLY through [Expire Reservation].
  ```
- **Invariant 5 — Idempotent reservation actions.**
  ```
  Invariant 5.1: Two calls carrying one idempotency token AND one parameters digest MUST answer alike inside the idempotency window.
  Invariant 5.2: The composition MUST NOT call a constituent write twice for one idempotency token inside the idempotency window.
  Invariant 5.3: A call reusing an idempotency token across action types MUST answer token-collision.
  Invariant 5.4: The composition MUST make the idempotency claim ONLY IF the deployment declares Duplicate Prevention's database obligations.
  ```
- **Invariant 6 — Every state change is attributed and journaled.**
  ```
  Invariant 6.1: EVERY committed state change MUST carry EXACTLY ONE outcome entry at quiescence.
  Invariant 6.2: An outcome entry MUST carry the attestation id the invocation's attest answered.
  Invariant 6.3: The sequence number of the intent entry carrying an outcome entry's attestation id MUST NOT EXCEED the outcome entry's sequence number.
  Invariant 6.4: A read-only query MUST NOT write a journal entry.
  ```
- **Invariant 8 — Authentication precedes commitment.**
  ```
  Invariant 8.1: The composition MUST NOT reach a constituent call that commits BEFORE Actor Identity's attest answers the attestation id.
  Invariant 8.2: An attestation MUST bind the action reference of one invocation.
  Deleted: Invariant 7. Composes 5 owns it.
  ```

Allocation coherence with slot-returned-at-most-once gives the *no leak, no double release* property — the pool count is a faithful image of the live set. Never-exceed-capacity with no-confirmation-of-a-lapsed-hold gives the *no oversell* property across the confirm and expire race. Idempotency makes both hold under retry; attribution and journaling make the whole arc provable.

---

## Examples

### Walkthrough — event ticketing against a bounded pool

A venue sells a 2-seat VIP (very important person — premium) tier as a Capacity Constraint pool `pool_vip` with `capacity = 2`. The composition runs with a 5-minute idempotency window and an eager expiry sweep.

1. **Reserve (buyer A).** `reserve(pool_vip, resource="vip-tier", requester="buyer_a", duration=10m, actor_ref="checkout_svc", credential=<checkout_svc>, idempotency_token=tok_a1) → reservation_id = rsv_001`. Internally: `Capacity Constraint.allocate(pool_vip, 1, ...)` → `allocated: 0 → 1`; `Provisional Commitment.place_hold("vip-tier", "buyer_a", 10m)` → `rsv_001` (Held); Event Log records [Reserve]; `reservation_to_pool[rsv_001] = pool_vip`. `query(pool_vip).allocated = 1`.
2. **Reserve (buyer B).** `reserve(pool_vip, ..., requester="buyer_b", ..., idempotency_token=tok_b1) → rsv_002`. `allocated: 1 → 2`. The pool is now full.
3. **Reserve (buyer C) — capacity gate fires.** `reserve(pool_vip, ..., requester="buyer_c", ..., idempotency_token=tok_c1)` → `Capacity Constraint.allocate(pool_vip, 1, ...)` → `over-capacity` → `rejected(pool-capacity-exceeded)`. No hold is placed; `allocated` stays 2. Buyer C is not oversold. (Invariant 3.)
4. **Retry buyer A's reserve (network drop).** `reserve(pool_vip, ..., idempotency_token=tok_a1)` → `DuplicatePrevention.check(tok_a1) → seen`; cached `(reserve, digest_a, rsv_001)` replayed → returns `rsv_001`. No second `allocate`; `allocated` stays 2. (Invariant 5.)
5. **Confirm (buyer A).** `confirm_reservation(rsv_001, actor_ref="checkout_svc", credential=<…>, idempotency_token=tok_a2) → ok`. `Provisional Commitment.confirm(rsv_001)` → Confirmed (within window); the slot is *kept* — no pool `release`. `allocated` stays 2. (Confirmed consumes the unit.)
6. **Expiry (buyer B lets the hold lapse).** Ten minutes pass; the sweep fires `expire_reservation(rsv_002, actor_ref="sweeper", credential=<sweeper>, idempotency_token=tok_sweep_b) → ok`. `Provisional Commitment.expire(rsv_002)` → Expired; `Capacity Constraint.release(pool_vip, 1, ...)` → `allocated: 2 → 1`; Event Log records [Expire Reservation]. The slot is returned exactly once. (Invariants 1, 2.)
7. **Reserve (buyer C, retry with a fresh token).** Now `reserve(pool_vip, ..., requester="buyer_c", idempotency_token=tok_c2)` → `allocate` → `allocated: 1 → 2` → `rsv_003` Held. Buyer C gets the slot buyer B let lapse. The pool count tracked the truth throughout.

### Cancellation returns the slot

Buyer A cancels before confirming (in a variant where rsv_001 is still Held): `cancel_reservation(rsv_001, ..., idempotency_token=tok_cancel_a) → ok`. `Provisional Commitment.release(rsv_001)` → Released; `Capacity Constraint.release(pool_vip, 1, ...)` → `allocated` decrements. The slot returns to the pool in order with the cancellation. (Invariants 1, 2.)

### Refused hold after the capacity gate

A [Reserve] passes the capacity gate (`allocate` answers an allocation event id) but `Provisional Commitment.place_hold` then returns resource-unavailable (the specific resource was taken between the capacity gate and the hold). The allocate and the hold are written in one transaction, so the refused hold leaves the allocate uncommitted: `allocated` stays 1, the reserve intent stands as the record of the attempt, and the composition returns `rejected(resource-unavailable)` to the caller (cached against the token). Coherence is preserved across the failed reserve — no slot was taken. (Action wiring 55 and Action wiring 61.)

### Rejection path — confirming a lapsed hold

A buyer's checkout stalls; by the time `confirm_reservation(rsv_002, ...)` arrives, `rsv_002`'s 10-minute window has elapsed. `Provisional Commitment.confirm(rsv_002)` → window-elapsed → `rejected(window-elapsed)`. The reservation is not confirmed; its slot is the expiry sweeper's to return. The buyer must reserve afresh. (Invariant 4 — no confirmation of a lapsed hold; this is the confirm/expire race resolved in the pool's favor.)

### Regulated adversarial scenarios

**Regulator/operator audit — "prove you never oversold the pool."** An auditor reads the pool's `query(pool_id).allocated` and the Event Log and confirms that at no point did the count of Confirmed reservations exceed `capacity` (Invariant 3), and that `allocated` at every event equals the live-reservation set reconstructed from the Event Log (Invariant 1). The pool event balances on every reservation entry — the opening and closing balances copied from the pool's own events, whose ids the entries cite — make the arithmetic chain replayable against the pool's audit log (Check 7.1); a state in which Confirmed reservations outnumber `capacity`, or `allocated` diverges from the live set, is a conformance failure. The auditor consults no source code — the pool count and the journal are sufficient.

**Disputed double-booking — two customers claim the same unit.** An investigator inspects the Event Log for the pool: every [Reserve] carries the allocation event id and the pool event balances; every terminal action carries the `release_event_id`. If two Confirmed reservations exist against a 1-capacity pool, either `capacity` was raised by an `adjust_capacity` (an overbooking choice the pool's audit log records) or coherence was violated — and the Event Log shows which. Idempotency (Invariant 5) forecloses the retry-induced double-reserve; the dispute resolves to a recorded `adjust_capacity`, a client token-discipline failure, or a genuine finding, each provably distinct.

**Inventory-leak forensics — "free count is wrong; find the stranded slot."** An operator observes `allocated` higher than the visible live reservations. The investigator replays the Event Log: every [Reserve] (slot taken) must have either a matching terminal [Cancel Reservation]/[Expire Reservation] (slot returned) or a live Held/Confirmed reservation — and a pool allocation with no [Reserve] entry at all is the stranded slot, a leak whose precise pool and allocation event the records name. Invariant 2 (slot returned at most once) and Invariant 6 (every change journaled) are what make the leak locatable rather than a mystery in an aggregate counter.

---

## Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given the reservation-to-pool binding and the token results map plus the Provisional Commitment, Capacity Constraint Enforcement, Duplicate Prevention, Event Log and Actor Identity instances.

### Conformance checks

```
Check 1.1: An auditor MUST count a pool's slot-holding reservations by traversing the journal's reserve outcome entries for the pool (Invariant 1.1).
Check 1.2: An auditor MUST resolve EVERY traversed reservation id through the binding as a keyed lookup, rebuilding on a miss (Composition state 10).
Check 1.3: An auditor MUST NOT count binding entries in place of the traversal (Invariant 1.1).
Check 1.4: An auditor MUST report a divergence the rebuild closes as an index gap (Composition state 10).
Deleted: Check 1.5. Execution Contract Database 1 owns it.
Check 1.6: An auditor MUST report a divergence the rebuild does not close as a coherence finding (Invariant 1.1).
Deleted: Check 1.7. Execution Contract Database 1 owns it.
Check 2.1: An auditor MUST find a pool's Confirmed reservations not exceeding the pool's allocated at quiescence (Invariant 3.1).
Check 2.2: An auditor MUST take a pool's allocated not exceeding the pool's capacity from Capacity Constraint Enforcement's own acceptance (Composes 5).
Check 3.1: An auditor MUST NOT find two slot-returning outcome entries naming one reservation (Invariant 2.1).
Deleted: Check 3.2. Execution Contract Database 1 owns it.
Deleted: Check 3.3. Execution Contract Database 1 owns it.
Deleted: Check 3.4. Execution Contract Database 1 owns it.
Deleted: Check 3.5. Execution Contract Database 1 owns it.
Deleted: Check 3.6. Execution Contract Database 1 owns it.
Deleted: Check 3.7. Execution Contract Database 1 owns it.
Deleted: Check 3.8. Execution Contract Database 1 owns it.
Check 4.1: An auditor MUST read a Confirmed reservation's in-window admission from the Provisional Commitment record (Invariant 4.1).
Check 4.2: An auditor MUST NOT report a skew between a confirm outcome entry's now AND the hold's expiry instant (Capability requirement 42).
Check 5.1: An auditor MUST find EVERY idempotency token inside the idempotency window bound to one answer (Invariant 5.1).
Check 5.2: An auditor MUST find no two reservations sharing one idempotency token (Invariant 5.2).
Check 5.3: An auditor MUST report a window miss traceable to a violated obligation against the obligation (Invariant 5.4).
Check 6.1: An auditor MUST call Actor Identity's verify on EVERY outcome entry's attestation id (Invariant 6.2).
Check 6.2: An auditor MUST recompose the action reference from the entry's own action AND idempotency token (Invariant 8.2).
Check 6.3: An auditor MUST read verified against the recomposed action reference as the passing answer (Invariant 6.2).
Check 6.4: An auditor MUST re-run a verification answering a registry condition (Capability requirement 37).
Check 6.5: An auditor MUST report an attestation verifying against another action reference as a conformance failure (Invariant 8.2).
Check 6.6: An auditor MUST report an outcome entry carrying no attestation id as a conformance failure (Invariant 6.2).
Check 6.7: An auditor MUST report an attestation id Actor Identity answers not-known for as a conformance failure (Invariant 6.2).
Check 6.8: An auditor MUST find the intent entry carrying an outcome entry's attestation id earlier in sequence order than the outcome entry (Invariant 6.3).
Check 6.9: An auditor MUST NOT report an intent entry carrying no outcome entry as a failure (Invariant 6.1).
Check 7.1: An auditor MUST chain ONLY outcome entries citing a pool event (Action wiring 64).
Check 7.2: An auditor MUST find EVERY chained entry's pool event balances equal to the cited pool event's (Action wiring 64).
```

NOTE: EVERY check names the rule the check tests.

Term registry condition: actor-unknown-in-registry | registry-unavailable — a verification answer that is the registry's state, not the composition's conformance.

### External checks

```
External check 1: An auditor needing whether a pool's capacity reflects the physical unit count MUST read the pool's declaration AND adjustment history (Capability requirement 2).
External check 2: An auditor needing the resource-availability determination confirmed MUST read Provisional Commitment's registry (Non-goal 1).
Deleted: External check 3. Execution Contract Database 1 owns it.
Deleted: External check 4. Execution Contract Database 2 owns it.
Deleted: External check 5. Execution Contract Database 3 owns it.
External check 6: An auditor needing Duplicate Prevention's obligations confirmed MUST read the deployment's own configuration (Capability requirement 35).
External check 7: An auditor needing the actor registry's historical material confirmed MUST read the registry (Capability requirement 37).
External check 8: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 5).
External check 9: An auditor needing the idempotency window confirmed MUST read the deployment's own configuration (Capability requirement 1).
External check 10: An auditor needing the token max length confirmed MUST read the deployment's own configuration (Capability requirement 27).
External check 11: An auditor needing the digest function confirmed MUST read the deployment's own configuration (Capability requirement 28).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT decide whether a specific resource is bookable.
Non-goal 2: The composition MUST NOT model overbooking.
Non-goal 3: A deployment overbooking a pool MUST declare the pool's capacity above the physical unit count.
Non-goal 4: The composition MUST NOT seal a journal entry.
Non-goal 5: A deployment needing sealed reservation events MUST compose Audit Trail as a peer.
Non-goal 6: The composition MUST NOT schedule the expiry sweep.
Non-goal 7: The composition MUST NOT cancel a Confirmed reservation.
Non-goal 8: A deployment needing a Confirmed reservation undone MUST compose Reversal.
Non-goal 9: The composition MUST hold EXACTLY ONE slot per reservation.
Non-goal 10: The composition MUST NOT gate a reservation on authorization.
Non-goal 11: A deployment needing an authorized reservation MUST compose Permissions.
Non-goal 12: The composition MUST NOT record who replayed an idempotency token.
Non-goal 13: The composition MUST NOT authenticate a replay.
Non-goal 14: The composition MUST NOT journal a pre-attest refusal.
Non-goal 15: A deployment needing attempt-level visibility MUST compose Event Log around the call surface.
Non-goal 16: The composition MUST NOT own a downstream surface.
```

Term pre-attest refusal: a refusal answered ahead of the attestation — a malformed input, a token collision, a replay.

Term downstream surface: pricing, waitlisting or fulfilment of a reservation.

NOTE: the owners — an expiry sweep outside the composition (Non-goal 6, Expiry sweep 1); a group-booking composing extension (Non-goal 9).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: A deployment MUST own the honesty AND the monotonicity of the injected now.
Clock semantics 2: A deployment needing a verifiable wall-time anchor MUST compose Trusted Timestamping.
Clock semantics 3: IF no Trusted Timestamping anchor EXISTS THEN the composition MUST read Event Log insertion order as authoritative.
```

### Concurrency

```
Concurrency 1: The composition MUST rest a race between two resolving actions on one reservation on Provisional Commitment's single resolution.
Deleted: Concurrency 2. Execution Contract Database 1 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Concurrency 4: The composition MUST NOT serialize a single pool call of the composition's own.
```

### Expiry sweep

```
Expiry sweep 1: An expiry sweep MUST call [Expire Reservation] for a reservation whose window reading EQUALS lapsed.
Deleted: Expiry sweep 2. Execution Contract Database 1 owns it.
Deleted: Expiry sweep 3. Execution Contract Database 1 owns it.
Expiry sweep 4: A deployment needing a tight free count MUST declare the eager expiry sweep.
```

---

## Composition notes

These are adjacent compositions, **not** constituents of this composition:

- **[Idempotent Reservation](./idempotent-reservation.md)** — the precursor: Provisional Commitment and Duplicate Prevention, the idempotency surface without pool arithmetic. This composition is its pool-aware superset; a deployment that needs retry-safe holds but no bounded pool uses Idempotent Reservation directly.
- **[Audit Trail](./audit-trail.md)** (substrate, peer) — a deployment whose reservation events require tamper-evident seals composes Audit Trail in place of the bare Event Log and Actor Identity pairing (Non-goal 4 and 5).
- **Reversal** *(forthcoming)* — produces a compensating action that un-books a Confirmed reservation and, where the slot should re-open, returns it to the pool. This composition deliberately excludes un-booking a firm reservation; Reversal is the composing pattern that adds it.
- **Trusted Timestamping** *(forthcoming)* — binds Event Log insertion order to verifiable wall-time where reservation or settlement timestamps have legal force.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the four state-changing actions it exposes and the read-only query, the per-invocation action reference, the parameters digest it keys retries by, and its own pool refusals. Allocation coherence itself (Invariant 1) is a structural property, not a datum. The deployment settings keep their wire spellings in configuration — `idempotency_window`, `expiry_sweep`, `journal_query_shape`, `pool_event_read`, `journal_retention_ordering`, `token_max_length`, `digest_function` — and the two maps theirs in an implementation, `reservation_to_pool` and `token_results`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the transition; a deployment; an auditor; a caller; an operator; an investigator; an invocation; an action; a state-changing action; a resolving action; a slot-returning action; a read-only query; a replay; an expiry sweep; the rebuild; a reservation; a hold; a pool; a slot; a binding entry; a token results entry; an intent entry; an outcome entry.

Term records: the intent entries and outcome entries the composition appends to the journal — each an Event Log event carrying one action below — and the binding and token results entries.

Term record verbs: address, alert, allocate, answer, authenticate, bind, call, cancel, carry, chain, change, close, commit, compare, compensate, compose, configure, confirm, copy, count, decide, declare, derive, evict, find, gate, hold, inherit, inject, journal, key, leave, make, mint, model, name, normalize, order, own, place, re-run, reach, read, rebuild, recompose, record, release, remove, report, resolve, rest, retain, schedule, seal, serialize, serve, set, settle, stamp, store, supply, take, validate, verify, write.

Term value sets: action = reserve_intended | reserve | confirm_intended | confirm_reservation | cancel_intended | cancel_reservation | expire_intended | expire_reservation. The rest are declared where the section that owns each declares it: action type, position, slot-holding state, slot-returning state, constituent-terminal state, expiry sweep.

Term bounds: audit horizon (journal_retention_ordering), token max length (token_max_length), idempotency window (idempotency_window).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-23).

Term terms: composition, constituents, reservation, reservation id, journal, journal entry, reservation-to-pool binding, binding entry, aged entry, token results map, action type, parameters digest, business parameter, idempotency window, expiry sweep, pool event read, token max length, digest function, audit horizon, retention floor, longest reservation lifetime, coherence proof period, seam, now, envelope, position, reservation reading, slot-held reading, state-changing action, resolving action, slot-returning action, settling, replay, matching token results entry, action reference, journaled digest, intent entry, outcome entry, slot-returning outcome entry, resolving entry, admitted reserve, pool event balances, witness balance, terminal state, slot-holding state, slot-returning state, constituent-terminal state, bound slot-holding count, quiescence, divergence, registry condition, pre-attest refusal, downstream surface, reserve intent, reserve outcome entry, confirm intent, confirm outcome entry, cancel intent, cancel outcome entry, expire intent, expire outcome entry.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Composition state in `execution-contract.md` — the derived-index, truth-bearing and extraction-pending classifications. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. commitment id, place hold, confirm, release, expire, resource, requester, duration, window reading, open, lapsed, Held, Confirmed, Released, Expired, not-held, window-elapsed, window-not-elapsed, resource-unavailable: Provisional Commitment. pool id, capacity, allocated, allocate, declare pool, query, audit log, audit event, allocation event, release event, allocation event id, release event id, opening balance, closing balance, over-capacity, suspended, closed: Capacity Constraint Enforcement. check, record, seen, not-seen: Duplicate Prevention. append, event id, sequence number, recording instant, payload cap, invalid-payload: Event Log. attest, verify, attestation id, actor reference, credential, actor registry, invalid-credential, actor-unknown-in-registry, registry-unavailable: Actor Identity.

Term composing patterns: [Idempotent Reservation](./idempotent-reservation.md); [Audit Trail](./audit-trail.md); Reversal *(forthcoming)*; Trusted Timestamping *(forthcoming)*; Erasure Tombstone *(forthcoming)*; [Permissions](../atoms/permissions.md).

Term reserve intent: the reserve_intended entry.

Term reserve outcome entry: the reserve entry — the [Reserve] outcome.

Term confirm intent: the confirm_intended entry.

Term confirm outcome entry: the confirm_reservation entry — the [Confirm Reservation] outcome.

Term cancel intent: the cancel_intended entry.

Term cancel outcome entry: the cancel_reservation entry — the [Cancel Reservation] outcome.

Term expire intent: the expire_intended entry.

Term expire outcome entry: the expire_reservation entry — the [Expire Reservation] outcome.

#### Reserve

The composition's core action: it takes one slot of a pool and opens a provisional hold bound to it — the capacity gate and the hold are bound, so the slot is allocated only if the hold is taken (Action wiring 45 through 56, Action wiring 61 through 64, Action wiring 78 and Action wiring 79). Answers the reservation id, [Pool Closed], [Pool Capacity Exceeded] or a relayed refusal. Idempotent under retry.

Kind: Operation

#### Confirm Reservation

The action that confirms a held reservation into a firm booking. **The slot is not released** — a Confirmed reservation keeps its unit, so allocated is unchanged. Answers window-elapsed for a lapsed hold, the *no confirmation of a lapsed hold* guarantee (Invariant 4).

Kind: Operation

#### Cancel Reservation

The action that cancels a held reservation and **returns its slot to the pool, in order, exactly once** — Provisional Commitment's release, the pool release and the outcome entry, written in one transaction (Invariant 1 and 2).

Kind: Operation

#### Expire Reservation

The action an expiry sweep calls on a held reservation whose window has lapsed: it drives Provisional Commitment's expire and returns the slot in the same order and under the same exactly-once discipline as [Cancel Reservation], differing only in the transition and the window-not-elapsed guard.

Kind: Operation

#### Query Reservation

The read-only query answering a reservation's state, its pool and whether it holds a slot now (Action wiring 114 through 118). Writes no journal entry.

Kind: Operation

#### Action Reference

The per-invocation reference an attestation binds to: the action type and the idempotency token joined by a colon, `reserve:tok_a1`. Actor Identity verifies a proof against its recorded action reference, so a reference shared by every act of a kind would make every such attestation substitutable; this one binds the proof to one act, and an auditor recomposes it from the entry's own fields (Check 6.2).

Kind:       Field
Field of:   the attestation
Role:       the act the proof binds to
Projection: action_ref

#### Parameters Digest

The collision-resistant digest of a call's business parameters, computed at the seam by the digest function and injected — never the actor reference, never the credential, so a retry presenting freshly minted credential material still matches and no secret persists in digest form (Composition state 19 through 21).

Kind:       Field
Field of:   the token results entry
Role:       the retry key's parameter check
Projection: parameters_digest

#### Pool Closed

The composition's own refusal from [Reserve] when the pool is Closed or Suspended to new reservations. It maps Capacity Constraint Enforcement's closed and suspended allocate refusals to one code — a deliberate collapse that discards the retry-once-resumed signal suspended carries; a caller needing the distinction reads the pool's own query, and this boundary reports only that no new reservation is admitted now.

Kind:       Member
Member of:  the reserve refusal
Role:       Rejection
Projection: pool-closed

#### Pool Capacity Exceeded

The composition's own refusal from [Reserve] when the pool is full: Capacity Constraint Enforcement's allocate refuses past capacity. The observable form of the *no oversell* guarantee (Invariant 3) at the capacity gate.

Kind:       Member
Member of:  the reserve refusal
Role:       Rejection
Projection: pool-capacity-exceeded

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Reserve]: #reserve
[Confirm Reservation]: #confirm-reservation
[Cancel Reservation]: #cancel-reservation
[Expire Reservation]: #expire-reservation
[Query Reservation]: #query-reservation
[Action Reference]: #action-reference
[Parameters Digest]: #parameters-digest
[Pool Closed]: #pool-closed
[Pool Capacity Exceeded]: #pool-capacity-exceeded

---


## Standards references

- **ISO (International Organization for Standardization) 9001 clause 8.5.2 / clause 8.5.4 (identification, traceability, preservation of outputs)** — the reservation lifecycle's traceable per-unit arc inherits from Provisional Commitment.
- **PCI DSS (Payment Card Industry Data Security Standard) Requirement 10 (logging and monitoring)** — the Event Log journal plus Actor Identity attribution on every reservation event produce the audit evidence for payment-adjacent holds (credit-limit and authorization holds are Provisional Commitments against a credit pool).
- **IATA (International Air Transport Association) Resolution 830a / NDC (New Distribution Capability — IATA's airline retailing standard) (airline reservation and distribution)** — seat-inventory holds against a bounded cabin are the canonical Reserve from Pool case: a pool per cabin class, a hold per booking, confirm/cancel/expire returning inventory.
- **Joint Commission care-coordination standards** — hospital bed and resource allocation as a bounded pool with attributed, journaled holds; the no-oversell guarantee is the patient-safety form of allocation coherence.
- **GS1 (the global supply-chain standards organization) / supply-chain inventory-reservation conventions** — warehouse unit reservation against available-to-promise pools; allocation coherence is the available-to-promise accuracy guarantee.
- **IETF (Internet Engineering Task Force) draft-ietf-httpapi-idempotency-key-header; ISO 20022 (the financial-industry messaging standard) message uniqueness** — the idempotency surface inherited from the Idempotent Reservation precursor.

The five constituents carry their own deep standards inheritance — see each constituent's Standards references.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — reserve-from-pool.tla + 1 twin verified 2026-06-04 over the retired atomic trio; re-derive over the ordered slot-returning pair and the pool reconciliation (2026-08-29-a)
last gate: 2026-08-30 — third gate, fresh reader, under the frozen rules — 6 foundational corrected in-round, 6 refining and 1 rhetorical routed (5 refining and 3 rhetorical also corrected in-round; closure check's 4 residues corrected in-round)

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/reserve-from-pool.md`; the migration that got it here is in [its history](./reserve-from-pool.hist.md).

- **2026-10-21 — The store's guarantees cited, not restated, and each action's intent, constituent writes and outcome one transaction.** *Chose:* Capability requirement 47 citing Execution Contract Store 1 through 4 for the store the five constituents, the binding and the token results map keep their records in; to Store 3, the durability of the journal, of the commitment and pool stores held at the journal's, of the binding, the token results map, the recorded set and the attestation store, the answer held until the token results entry and the record are durable, and the auditor's check of the journal's durability (Capability requirement 12 through 14, 30, 32 through 34, 36, 38, External check 5); to Store 2, under which an action's reads and the writes they decide are one transaction, the token, reservation and pool exclusions with their supply, release, lease and expiry, every take of them, the fence on later writes and the re-take after a lost one, the reliance on the pool's per-call serialization for concurrent allocates and the auditor's check of the exclusions (Capability requirement 20 through 26, Action wiring 2 through 4, 33 through 37, Concurrency 3, External check 4); to Store 1, under which an action's writes commit together, its constituents' included, the rule refusing a host transaction, which Store 1 as ruled contradicts (Wiring decision 4), and the machinery that existed only because a crash or a refusal between two of an action's writes could leave a partial: the compensating release and compensation entry for a refused place hold and the replay from one, the hold compensation for a refused reserve outcome entry, the outcome-position settles after a committed half with their stages, the release marker with its pending and released values and the pre-check that read it, the in-invocation retries of a post-commit write with their attempts and the late outcome entries, the adoption of a resolving entry found on a re-take, the whole reconciliation with its service identity, completion bound, compensation window, cadence, write latency, liveness sum, candidates cap, consistent pool read and candidate-set test, the divergence windows it closed, the checks of the windows, the marker and the compensation, and the expiry sweep's reading of an orphan hold (Capability requirement 4 through 11, 16, 18, Composition state 5, 8, 9, 12 through 14, Action wiring 16, 17, 38 through 44, 57 through 60, 65 through 77, 94, 99 through 105, 107 through 109, 112, Wiring decision 5, Reconciliation 1 through 39, Invariant 1.2 through 1.4, Check 1.5, 1.7, 3.2 through 3.8, External check 3, Concurrency 2, Expiry sweep 2, 3). By clause, a binding entry carries its pool id alone, the slot-held reading reads the state alone, a slot is released only for a slot-returning transition, a place hold refusal is settled with no compensation ahead of it, the idempotency claim rests on Duplicate Prevention's store obligations alone, a divergence the rebuild does not close is a coherence finding and the replay chain takes every outcome entry citing a pool event (Composition state 3, Action wiring 61, 118, Wiring decision 6, Invariant 5.4, Check 1.6, 7.1); the binding write loses its marker, and the success settles, the slot release and the slot-returning outcome entry follow the answer each needs rather than a marker or an entry written in an earlier commit (Action wiring 78, 79, 96, 106, 110, 113). Rules 345 to 208. *Over:* a transition, a pool release and a journal entry no transaction could span, ordered and returned exactly once by a release marker and a reconciliation that decided from the pool's own count, a [Reserve] partial compensated in line or by the reconciliation, a confirm pair completed by a late write, and three exclusions the host held as leases whose expiry ended an invocation — the turns of 2026-08-30, 2026-08-29 and 2026-08-27, below. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, that a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal, and that Store 2 covers a guard decided across a lease check, the lease keeping its job only for an act outside the store. Nothing in the reservation arc is an act outside the store: the attestation, the journal entries, the allocate and the pool release, the hold and its transitions, the recorded token and the token results entry are store writes, so each action's intent, constituent writes, outcome and settled answer commit together, and the three exclusions, host mutual exclusions over store-only work, are Store 2's. A place hold refused after the allocate leaves only the reserve intent, the refused attempt's evidence, so no slot is taken for it and none is returned (Action wiring 61), and a pool release refused after the transition leaves the reservation Held; a refused append writes nothing, Duplicate Prevention's record never refuses and a constituent's storage failure fails the whole action, so no answer a kept rule gives reaches a partial and nothing is owed once an action returns. The binding stays a derived index outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps it, so it is still written after the reserve outcome entry and rebuilt on a miss, and its entries past the audit horizon stay truth-bearing (Composition state 4, 10, 11, 15, Action wiring 18, Check 1.2 through 1.4). Order rests on the journal's own sequence numbers (Capability requirement 46), and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.
- **2026-08-30 — One writer per act, the windows keyed on the pool's own events, the retry reading the journal before it delegates, and the obligations the constituents decline declared as the deployment's.** *Chose:* a retry terminus, `outcome_retry_attempts`, after which every post-commit write is the sweep's, with the sweep's runs and the invocation serialized on the deployment's declared `host_exclusion` sections and every look-then-write pre-check re-read under them; the reconciliation's unjournaled-return set keyed per reservation — an intent enters only where no slot-returning outcome names the reservation and the terminal state is the one its action writes, outcome over intent on the rebuild — with one recovery entry per reservation and the rest as `intent_candidates`; Invariant 1's windows and check 1 keyed on allocation events of the pool's audit log, an unmatched `reserve_intended` explaining zero slots; [Reserve] step 2 reading the journal for its token on `not-seen` before it delegates — replay on an outcome, defer on a bare intent — and the sweep caching and recording the deferred tokens; `allocated_before` / `allocated_after` copied from the pool's own allocation or release event through `pool_event_read`, the three-call `query`-`allocate`-`query` section dropped; `journal_durability`, `journal_query_shape`, `pool_event_read` and `host_exclusion` declared as inherited obligations and instance capabilities; `recording-failure(intent | outcome)` and invalid-credential on every signature, the intent position uncached and the outcome position cached; the liveness inequality written out with `recovery_write_latency`; `journal_payload_cap` and `recovery_candidates_cap` sizing the largest record at step 1; and, from the closure check, `host_exclusion` as an instance capability with lease semantics — taken at the invocation's first write, exactly `reservation_completion_bound` long, its expiry the invocation's terminus, every later write made only under it — with the pool call of every action pre-checked under the sections and adopting a landed return or compensation (*proceed as landed*), the sweep taking a reservation's section before counting it, the three other actions reading the journal on `not-seen` as [Reserve] does, replay from a compensation populating no binding, and the tri-state `release` marker (`Projects: release`) written into every sentence that still spoke of a boolean or a trio. *Over:* "retry until it lands" beside a sweep starting at the bound; a leg that paired per reservation and wrote per intent; a divergence window keyed on an intent that had taken nothing; a `not-seen` treated as proof that nothing ran; a critical section, a durability and a query shape attributed to constituents whose own text declines them; a bare token on both sides of the commit; *cadence no longer than the window*; *foreclosed by construction*; a section named in no Configuration entry, with no lease and no terminus, under which a stalled invocation could wake between the sweep's pre-check and its append and release twice. *Because:* two compensators over one act land two outcomes and a second release; a refused cancel against a reservation another token returned is not a return begun; a refused intent never receives an outcome, so a window keyed on it never closes; a crash between the outcome and the `record` leaves a completed reservation the retry would duplicate; Capacity Constraint serializes each call and sends the rest to a Transaction composition, Event Log leaves persistence to the deployment, and a capability the constituent declines is the deployment's to declare or nobody's; a caller who cannot tell intent from outcome re-runs a committed act; and a section that is not a declared capability with a bound on its hold is either an undeclared dependency or an unbounded block on the sweep (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen with its tells for uses — with §*Intents pair with outcomes*' third tell and §*Recovery commits under a declared service identity*'s re-entry tell; *Lawful destruction is answered before absence* and *A stamp from another seam never decides a write alone* were swept and found no shape here — no constituent answers `purged`, and no write rests on a cross-seam comparison).
- **2026-08-29 — The slot-returning pair is ordered and reconciled by the pool's count, not made atomic; the sweep is bounded and acts as the composition.** *Chose:* [Cancel Reservation] and [Expire Reservation] run transition → pending marker → pool release → `released(…)` marker → outcome entry, none inside a transaction; a pool reconciliation leg that, under the per-pool serialization, computes the pool's deficit from the journaled live set and releases exactly that many slots, naming candidates where several returns were open at once; every sweep leg bounded below by `reservation_completion_bound` and above by the journal horizon, run as a declared service identity behind recovery_intended; the [Reserve] compensation appended after its release rather than "in one host transaction"; the compensation's constituent arms partitioned; `journal_retention_ordering` and `index_durability` declared, the binding's purged half and the pending markers classified truth-bearing with their atoms named. *Over:* the terminal trio as "one atomic commit, a hard conformance requirement". *Because:* the transition is absorbing, the pool release is an append on the pool's own audit log, and the journal entry is an append — no store declares the rollback the trio required, and a journal entry rolled back after landing was a false record; the ambiguity the trio was meant to remove (a lost release versus a lost record of one) is resolved instead by the second source the stores do supply, the pool's own count against the journal (the frozen rules of 2026-08-29 — *Durability boundaries*, *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*, *A derived index splits at the horizon*).
- **2026-08-27 — The confirm pair is completed by a late journal write, not made atomic and not compensated.** *Chose:* on a post-commit journal failure at [Confirm Reservation], return `recording-failure(post-commit)`, cache and record the token, and owe the outcome entry as a `recovery = true` write carrying the invocation's own attestation, detected from an unmatched confirm_intended against a Confirmed record. *Over:* extending the terminal trio's hard atomic-commit requirement to the pair. *Because:* the trio is atomic because a lost pool release and a lost record of one cannot be told apart; the confirm pair has no pool call and the constituent store answers the question directly, so a late write is safe and a transaction would buy nothing.
- **2026-08-25 — Invariant 5's at-most-once is conditioned on Duplicate Prevention's host obligations.** *Chose:* inherit the constituent's declared failure modes as named host obligations (durable, highly available recorded-set store; fail-closed `check`; `token_results` plus `record` durable before the result returns) and condition Invariant 5 and check 5 on them. *Over:* the unconditional at-most-once claim. *Because:* a silent window miss or a fail-open `check` lets a retried [Reserve] take a second slot, and an obligation-traceable miss is a deployment finding, not a coherence disproof.
- **2026-08-26 — Attribution is an `attest` call committed with the journal entry, keyed per invocation.** *Chose:* every state-changing action opens with `Actor Identity.attest(action_ref = "<action>:<idempotency_token>", …)` and carries the `attestation_id` on every journal schema; at the terminal trios the attestation stands outside and before the atomic trio. *Over:* attribution as prose ("attributed via Actor Identity") with a caller-supplied actor_ref. *Because:* the attribution guarantee was neither buildable nor witnessable as written, a shared `action_ref` would bind the proof to a category of act rather than the act, and an attestation inside the trio could not refuse the act it exists to gate.

NOTE: End of Reserve from Pool.
