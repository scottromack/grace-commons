---
title: Provisional Commitment
parent: Atomic Concepts
has_toc: true
toc: true
---

# Provisional Commitment

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Provisional Commitment is the business act of holding something for someone while they decide — a card authorization, a hospital bed, an item in a cart, a hotel room, an airline seat. A hold is placed, stays open for a fixed window, and resolves into exactly one of three recorded end states: confirmed, released, or expired. The window is a promise in both directions: the resource stays reserved until it closes, and the requester must decide before it does.

Resolving exactly once is the guarantee. A resolving call against an already-settled hold is refused. A confirm or release past the window is refused. An expire before the window closes is refused. Each hold carries a permanent id; its resource, requester and window are fixed at placement and never change. A settled hold is therefore an unambiguous record of what happened, reconstructable from the records alone.

Retry safety, the full transition history, and pool-wide capacity limits are deliberately outside the atom — each is a separate pattern that composes with it.

*Also known as: a hold, a reservation, a tentative reservation, a two-phase reservation.*

---

## Intent

A requester needs a resource whose grant is not yet certain. The system holds it for a known period, during which the requester confirms (taking it into a binding allocation) or releases (returning it to availability). If neither happens before the period elapses, an [Expire] event moves the hold to its terminal [Expired] state and returns the resource.

Expiry is a written transition rather than a status inferred at read time because the lapse has a side effect — it returns the resource, and in a pool-backed composition a capacity slot. A side-effect-free lapse could be derived; this one releases something and so needs a write.

The shape is constant across regulated industries: credit-limit holds pending settlement, bed assignments pending admission, inventory reservations pending checkout, room bookings pending check-in, seat holds pending purchase. A resource is encumbered for a bounded window, the encumbrance resolves, and the record of it is itself a regulated asset.

This is a freestanding atom in the EOS sense — its own state, its own four actions, its own operational principles. It does not implement idempotency under retry, the full audit trail of every observation, or aggregate capacity constraints over a pool. Each is a separate composable atom; see Composition notes.

---

## Structure

### Identity model

```
Identity 1: The atom MUST identify a commitment by the id.
Identity 2: The atom MUST assign the id from the id material the seam supplies.
Identity 3: The atom MUST NOT generate an id.
Identity 4: The atom MUST NOT change a commitment's id.
Identity 5: Two commitments MUST NOT share an id.
Identity 6: The atom MUST NOT identify a commitment by a property.
Identity 7: An admitted place hold MUST record one commitment.
Identity 8: The atom MUST compare a reference byte-exactly.
Identity 9: The atom MUST NOT normalize a reference.
Identity 10: The atom MUST NOT confirm that a resource names a known registry entry.
Identity 11: The atom MUST NOT confirm that a requester names a known actor.
Identity 12: The atom MUST NOT hold the resource's content.
Identity 13: The deployment MUST route EVERY call to one store instance.
```

Term commitment: the record this atom holds — one resource held for one requester for a bounded window, then resolved to exactly one terminal state.

Term id: the opaque value naming one commitment — an [Id]; assigned from the id material the seam supplies and never reused.

Term property: `resource` | `requester` | `placed_at` | `expires_at` — what a commitment carries that is not the commitment's identity.

Term reference: `id`, `resource` OR `requester` — every opaque reference this atom records.

Term registry: the deployment's owner of what a resource is and what availability means; outside this atom (Non-goal 11).

Term store instance: one named commitment store a call is routed to; `id` uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading, the id material and the registry's availability verdict here.

Term transition: the atom's evaluation of one call against the commitment store, as `execution-contract.md` §Logic confinement declares it.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

WHY:
Identity 5 ranges over a store instance's whole lifetime, which is what makes id reuse a case of sharing rather than a rule of its own — the reason the shipped Invariant 9 is a tombstone below.

Identity 6 is the load-bearing one. Identifying a commitment by `(resource, requester)` would muddle a re-hold: a requester re-holding the same resource after an earlier release is a *different* commitment with its own trail. Identifying by `placed_at` loses precision under concurrent placement. Opaque ids keep one commitment to one id, which is what makes per-event audit reconstruction tractable.

Identity 10 and Identity 11 state the other boundary. The atom holds references it was handed and does not reach into stores it has no knowledge of; a commitment naming a resource the registry has never heard of is still a valid commitment here, and wrong at the deployment layer.

### State

```
State 1: EVERY commitment MUST carry id, resource, requester, placed_at, expires_at and a state.
State 2: EVERY confirmed commitment MUST carry confirmed_at.
State 3: EVERY released commitment MUST carry released_at.
State 4: EVERY expired commitment MUST carry expired_at.
State 5: A held commitment MUST NOT carry a terminal instant.
State 6: The atom MUST NOT record the duration under the duration's own name.
State 7: The atom MUST NOT hold a state for a resource carrying no commitment.
State 8: The atom MUST NOT offer an unconfirm surface.
State 9: The atom MUST NOT offer a reactivate surface.
State 10: The atom MUST NOT offer a window extension surface.
State 11: The atom MUST NOT offer a commitment removal surface.
```

WHY:
State 6 is a small thing worth stating. `duration` sizes the window and is then gone: what persists is `placed_at` and `expires_at`, both immutable. Keeping `duration` as a field would make the window recomputable, and a recomputable window is one a later edit can move without touching `expires_at`.

State 7 is the boundary a reader keeps looking for. There is no *unheld* state in this atom's record — unheld describes the resource, not the commitment, and it belongs to the registry. The lifecycle this atom holds begins at [Place Hold].

State 8 through 10 are the three surfaces a reader keeps expecting to find. A confirmed commitment is not unconfirmed, an expired one is not reactivated, and a window is not extended — a longer hold is a new commitment with a new id, placed after the original is released. Mutating `expires_at` would retroactively change when [Expire] became legal, which breaks the honored window for a hold that has already settled.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the id material at the seam.
Capability requirement 3: The registry MUST run the availability read and the hold write for one resource as one section.
Capability requirement 4: The registry MUST release the section on the caller's return.
Capability requirement 5: The registry MUST release the section on the caller's death.
Capability requirement 6: The store MUST acknowledge a write ONLY IF the write commits.
Capability requirement 7: A deployment firing [Expire] on a cadence MUST declare the cadence.
Capability requirement 8: A deployment firing [Expire] on a cadence MUST declare the reclamation window the cadence falls inside.
Capability requirement 9: The deployment MUST canonicalize an opaque reference.
Capability requirement 10: The registry MUST return the resource to availability on a releasing action.
Capability requirement 11: The registry MUST NOT return the resource to availability on an admitted confirm.
Capability requirement 12: A deployment firing [Expire] on a cadence MUST resolve EVERY lapsed commitment WITHIN the reclamation window.
Capability requirement 13: The deployment MUST own the clock's skew.
Capability requirement 14: The deployment MUST own the clock's monotonicity.
Deleted: Clock semantics 4. Capability requirement 13 owns it.
Deleted: Clock semantics 1. `execution-contract.md` §Logic confinement owns it.
Deleted: Clock semantics 2. `execution-contract.md` §Logic confinement owns it.
Deleted: Clock semantics 3. `execution-contract.md` §Logic confinement owns it.
Deleted: Clock semantics 5. Capability requirement 14 owns it.
Deleted: Clock semantics 6. Non-goal 26 owns it.
```

WHY:
Capability requirement 3 through 5 are a declared obligation rather than an ambient host guarantee, and naming them is the point: a registry that cannot serialize the availability read against the hold write will hand two callers the same resource, and both commitments will satisfy every invariant above. Capability requirement 6 is what makes `storage-failure` definitive — a store that can acknowledge a write it did not commit turns every refusal into an in-doubt write, and a deployment with such a store routes retries through [Duplicate Prevention](./duplicate-prevention.md) rather than trusting the answer.

Capability requirement 10 and Capability requirement 11 are where the resource return lives, and the placement is the correction of a real defect: a draft of this migration carried the return as an `Operation`, obliging the atom to do something Non-goal 11 says it cannot see and External check 1's own WHY says it cannot check. The registry owns availability, so the registry carries the obligation, and External check 1 is the auditor's reading of it. The negative half is stated separately because a registry that frees the resource on a confirm has broken the atom's point as thoroughly as one that never frees it on an expire (council read 38).

Capability requirement 12 is the liveness half of resolution, and it is a deployment's to make true rather than this atom's. The atom decides nothing about when [Expire] fires (Non-goal 13) and licenses lazy expiry, under which a lapsed commitment stays held until something touches it; a deployment that wants every lapse resolved declares a cadence and a window, and this is the rule that binds them together.

WHY:
The single reading is what matters for the honored window. A call that read the window against one instant and stamped against a later one could record a resolution the guard would have refused; the Contract's one `now` per call closes that gap inside the transition and leaves clock quality — skew, monotonicity, timezone — where it belongs, at the deployment layer.

### Operations

```
place_hold(resource, requester, duration)
  answers id
  refuses invalid-request | resource-unavailable | storage-failure

confirm(id)
  answers ok
  refuses not-known | not-held | window-elapsed | storage-failure

release(id)
  answers ok
  refuses not-known | not-held | window-elapsed | storage-failure

expire(id)
  answers ok
  refuses not-known | not-held | window-not-elapsed | storage-failure
```

```
Operation 1: IF resource NOT EXISTS THEN [Place Hold] MUST answer invalid-request.
Operation 2: IF requester NOT EXISTS THEN [Place Hold] MUST answer invalid-request.
Operation 3: IF duration NOT EXISTS THEN [Place Hold] MUST answer invalid-request.
Operation 4: IF the duration falls outside the duration bounds THEN [Place Hold] MUST answer invalid-request.
Operation 5: IF the registry refuses the resource THEN [Place Hold] MUST answer resource-unavailable.
Operation 6: [Place Hold] MUST answer resource-unavailable ONLY IF EVERY well-formedness check passes.
Operation 7: [Place Hold] MUST NOT answer not-known.
Operation 8: An admitted place hold MUST assign a fresh id.
Operation 9: An admitted place hold MUST record resource and requester.
Operation 10: An admitted place hold MUST record now as placed_at.
Operation 11: An admitted place hold MUST record the window bound as expires_at.
Operation 12: An admitted place hold MUST stand the commitment in held.
Operation 13: An admitted place hold MUST answer the id.
Operation 14: IF the id names no commitment THEN a resolving action MUST answer not-known.
Operation 15: IF the commitment stands in a terminal state THEN a resolving action MUST answer not-held.
Operation 16: A resolving action MUST answer not-held ONLY IF the id names a commitment.
Operation 17: IF the commitment reads lapsed THEN [Confirm] MUST answer window-elapsed.
Operation 18: IF the commitment reads lapsed THEN [Release] MUST answer window-elapsed.
Operation 19: IF the commitment reads open THEN [Expire] MUST answer window-not-elapsed.
Operation 20: A resolving action MUST answer a window rejection ONLY IF the commitment stands in held.
Operation 21: An admitted confirm MUST stand the commitment in confirmed.
Operation 22: An admitted release MUST stand the commitment in released.
Operation 23: An admitted expire MUST stand the commitment in expired.
Operation 24: An admitted confirm MUST record now as confirmed_at.
Operation 25: An admitted release MUST record now as released_at.
Operation 26: An admitted expire MUST record now as expired_at.
Operation 27: A resolving action MUST commit the state change and the recorded instant in one transition.
Operation 28: IF the store refuses the write THEN an action MUST answer storage-failure.
Operation 29: An action MUST answer storage-failure ONLY IF EVERY precondition passes.
Operation 30: A refused action MUST leave the commitment as the call found the commitment.
Operation 31: A refused [Place Hold] MUST NOT record a commitment.
Operation 32: A refused resolving action MUST leave the commitment in held.
Operation 33: A resolving action MUST NOT accept a resource.
Operation 34: A resolving action MUST NOT accept a requester.
Operation 35: A resolving action MUST NOT accept a duration.
Deleted: Operation 36. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 37. `execution-contract.md` §Logic confinement owns it.
```

Term resolving action: [Confirm] | [Release] | [Expire] — every action taking a held commitment to a terminal state.

Term well-formedness check: Operation 1, Operation 2, Operation 3 and Operation 4 — every check [Place Hold] makes on the call's own arguments.

Term duration bounds: the implementation's admitted range for a `duration`; every admitted value exceeds zero.

Term window bound: `placed_at` raised by the `duration` — the value an admitted place hold records as `expires_at`.

Term window reading: `open` | `lapsed` — how a held commitment's window reads against `now`.

Term open: the window reading of a held commitment whose `expires_at` exceeds `now`.

Term lapsed: the window reading of a held commitment whose `expires_at` does not exceed `now`; the boundary instant — `expires_at` equal to `now` — reads lapsed.

Term window rejection: `window-elapsed` | `window-not-elapsed`.

Term terminal state: `confirmed` | `released` | `expired`.

Term terminal instant: `confirmed_at` | `released_at` | `expired_at`.

Term admitted place hold: a [Place Hold] call that passes every precondition and whose store write commits.

Term admitted confirm: a [Confirm] call that passes every precondition and whose store write commits.

Term admitted release: a [Release] call that passes every precondition and whose store write commits.

Term admitted expire: a [Expire] call that passes every precondition and whose store write commits.

Term admitted resolving action: an admitted confirm, an admitted release OR an admitted expire.

Term releasing action: an admitted release OR an admitted expire.

Term reclamation lag: the span between a commitment's `expires_at` and the admitted expire that settles the commitment.

WHY:
Operation 6, Operation 16, Operation 20 and Operation 29 are the rejection priority, written as guards rather than as an order — nothing may be inferred from rule order (GRACE-lang Timing 13). For a resolving action the effect is `not-known` before `not-held` before the window rejection before `storage-failure`; for [Place Hold] it is `invalid-request` before `resource-unavailable` before `storage-failure`. A caller who reads `not-held` therefore knows the id resolved, and one who reads `window-elapsed` knows the commitment is still held.

Operation 17 through 19 are the honored window, and the boundary is the whole of the disagreement they settle. The `lapsed` declaration puts the boundary instant on the closed side, so at `expires_at` equal to `now` a confirm is refused and an expire is admitted. One instant, one legal transition, no overlap.

[Release] and [Expire] are two actions rather than one because they differ in which side of the window they are legal on and in what the record then says happened. An auditor asking *did this requester give the resource back, or did the requester simply not answer* reads the terminal state and gets a different answer for each. The return of the resource itself is not here — it is Capability requirement 10, because this atom cannot see availability (Non-goal 11) and a MUST whose subject cannot evaluate it is decoration.

Logic confinement is the Contract's (`execution-contract.md` §Logic confinement), and the `now` declaration cites it rather than restating it. The clock is consumed twice per call — by the window reading and by the stamp — and both consumptions read the one `now` the seam supplied, so a transition is a pure function of the commitment, the inputs, `now` and the id material.

### Invariants

- **Invariant 1 — Membership exclusivity.**
  ```
  Invariant 1.1: EVERY commitment MUST stand in EXACTLY ONE OF held, confirmed, released, expired.
  ```
- **Invariant 2 — Single-resolution.**
  ```
  Invariant 2.1: A commitment MUST NOT reach two terminal states.
  Invariant 2.2: A commitment MUST NOT carry two terminal instants.
  ```
  WHY: the atom's central guarantee, and the one an implementation most often breaks under concurrency; Concurrency 1 states the mechanism that delivers it. Both rules are *at most one*, and that is deliberate. A draft of this migration carried a third — *EXACTLY ONE resolving action against one commitment MUST commit* — whose only content beyond these two was *at least one*, which is liveness this atom cannot deliver: it decides nothing about when [Expire] fires (Non-goal 13) and licenses lazy expiry, under which a never-touched lapsed commitment never resolves. Non-goal 25 states that limit and Capability requirement 12 is where a deployment may close it. The model agrees with the rules as they now stand rather than as the draft stated them: `provisional-commitment.cfg` declares `INVARIANT Safety` and no temporal property, and `Inv_SingleResolution` checks that a written resolution matches the state — the at-most-one half, silent on whether any resolution is ever written (council read 38).
- **Invariant 3 — Terminal absorption.**
  ```
  Invariant 3.1: A commitment standing in a terminal state MUST NOT leave the terminal state.
  Deleted: Invariant 4. Identity 4 owns id stability.
  ```
- **Invariant 5 — Property immutability.**
  ```
  Invariant 5.1: An admitted resolving action MUST NOT change a property.
  Invariant 5.2: A re-hold MUST produce a commitment carrying a fresh id.
  ```
  WHY: Operation 33 through 35 keep a resolving action from *accepting* a property, and Invariant 5.1 keeps one from changing a property by any other route. The two are separate claims: an implementation can change a stored field it was never handed.
- **Invariant 6 — Hold window monotonicity.**
  ```
  Invariant 6.1: The store MUST NOT carry a degenerate window.
  ```
- **Invariant 7 — Honored window.**
  ```
  Invariant 7.1: The store MUST NOT carry a late resolution.
  Invariant 7.2: The store MUST NOT carry a premature expiry.
  Invariant 7.3: EVERY held commitment MUST read EXACTLY ONE OF open, lapsed.
  ```
  WHY: this is what an auditor comes for, and it is structural rather than procedural. Invariant 7.1 and Invariant 7.2 are the two halves of one guarantee — no resolution recorded after the declared window, no expiry recorded before it — and together they make the query *show me every hold resolved outside its window* return the empty set by construction. Invariant 7.3 is what makes the pair total: every held commitment reads one way or the other at every instant, so there is no gap between the window closing and expiry becoming legal.
- **Invariant 8 — Resolution instants follow placement.**
  ```
  Invariant 8.1: A commitment's confirmed_at MUST NOT precede the commitment's placed_at.
  Invariant 8.2: A commitment's released_at MUST NOT precede the commitment's placed_at.
  Deleted: Invariant 9. Identity 5 owns id reuse for every id, resolved or not.
  ```
  WHY: the family floors the two *resolution* instants and not `expired_at`, whose floor is the stronger one Invariant 7.2 already carries — an expiry may not precede `expires_at`, which by Invariant 6.1 exceeds `placed_at`. The family was titled *Transition instants* in a draft, which promised a floor on all three and delivered two (council read 38).
- **Invariant 10 — Commitment store durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove a commitment from the store.
  Invariant 10.2: The store instance's commitment count MUST NOT fall.
  Invariant 10.3: A storage-failure rejection MUST leave no partial commitment in the store.
  ```

Term degenerate window: a commitment whose `expires_at` does not exceed the commitment's `placed_at`.

Term late resolution: a commitment standing in confirmed whose `expires_at` does not exceed the commitment's `confirmed_at`, OR one standing in released whose `expires_at` does not exceed the commitment's `released_at`.

Term premature expiry: a commitment standing in expired whose `expired_at` precedes the commitment's `expires_at`.

Term re-hold: a [Place Hold] naming a resource and a requester a resolved commitment already names.

Term capacity decision: a composing capacity constraint pattern's reading of the pool's capacity rule for one place hold.

WHY:
Membership exclusivity, single-resolution and terminal absorption together give the *audit-friendly* property: once a commitment settles, its record is a fact about the past rather than a candidate for revision. Invariant 7 gives the *honored-window* property. Identity 5 and Invariant 5 give the *one-commitment-one-id* property that makes per-event reconstruction tractable. Invariant 10 gives the *irrevocable-record* property — the audit surface cannot be silently reduced by deletion.

Invariant 4 and Invariant 9 are tombstones rather than deletions because a label never moves and never comes back (GRACE-lang Hard invariant 25, Hard invariant 27): a reader following an old citation lands on the note and finds the owner.

---

## Examples

The same atom, five regulated domains, one mechanic.

### Banking — credit-limit hold

`place_hold(card, cardholder, 7-days)` → `auth_c41`; available credit drops by $250. The merchant captures within the window — `confirm(auth_c41)` — and the charge settles; or voids it — `release(auth_c41)` — and credit restores. If neither, the scheme's settlement sweep fires `expire(auth_c41)` on the eighth day and a late capture is refused `window-elapsed`. Each transition feeds BCBS-aligned liquidity reporting.

### Healthcare — bed assignment

`place_hold(bed, patient, 2-hours)` → `bed_h17`, placed 14:00, expiring 16:00. The patient arrives at 14:45 — `confirm(bed_h17)`; or is discharged from the ED — `release(bed_h17)`. If neither by 16:00 the bed-management sweep fires `expire(bed_h17)` and the bed returns to the pool. The Joint-Commission-aligned care-coordination audit reads the commitment record directly.

### Retail — inventory reservation

`place_hold(sku, shopper, 15-minutes)` → `inv_r93`, placed 19:14. The shopper checks out at 19:18 — `confirm(inv_r93)`; or empties the cart — `release(inv_r93)`. An abandoned cart is swept from 19:29 — `expire(inv_r93)` — and the unit returns to stock.

### Hospitality — room booking

`place_hold(room, guest, duration)` → `rm_b58`, expiring at the property's cancellation cutoff. Check-in confirms; cancellation by the cutoff releases; neither leaves the sweep to expire it, which is the transition the property's no-show fee policy — a separate composing pattern — triggers off.

### Airline — seat hold

`place_hold(seat, passenger, 15-minutes)` → `seat_a22`, the carrier's fare-lock per IATA practice. Payment confirms; backing out releases; abandonment expires. The attached fare quote is invalidated whenever the hold leaves availability, which a composing Fare Quote pattern observes from the terminal state.

What differs across the five: resource semantics, window length, the regulatory framing of the trail, and which patterns compose. What does not differ: an undecided hold ends in a recorded `expire` that returns the resource.

### Regulated adversarial scenarios

- **Regulator audit.** *Show me every hold confirmed or released after its declared window.* The query is Check 3.1 and returns the empty set by construction — Invariant 7.1 makes a late resolution unrecordable rather than merely unlikely.
- **Data subject request.** Erasure against the personal data behind `requester`. The atom alone cannot satisfy it while keeping the trail; a composing Cryptographic Shredding or Erasure Tombstone pattern redacts the reference and leaves `id`, `placed_at`, `expires_at`, the state and the terminal instant intact, so the lifecycle stays auditable and the personal data does not persist.
- **Breach investigation.** The universe of resources committed between 02:00 and 04:00 UTC. Every commitment carries `placed_at`, so the answer is a filter over the store with no log replay behind it; the terminal state and its instant then say which holds resolved and which lapsed. This atom offers no read action of its own — the store is read by the deployment or by an auditor, not through a surface here — and ordering *within* the window needs the composing [Event Log](./event-log.md) (External check 2).

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the commitment store alone, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY commitment standing in EXACTLY ONE OF held, confirmed, released, expired (Invariant 1.1).
Check 1.2: An auditor MUST find a terminal instant on EVERY commitment standing in a terminal state (State 2, State 3, State 4).
Check 1.3: An auditor MUST find no terminal instant on a held commitment (State 5).
Check 2.1: An auditor MUST find no commitment carrying two terminal instants (Invariant 2.2).
Check 2.2: An auditor MUST find no commitment standing outside a terminal state on a later read of a commitment a prior read found in that terminal state (Invariant 3.1).
Check 3.1: An auditor MUST find no late resolution in the store (Invariant 7.1).
Check 3.2: An auditor MUST find no premature expiry in the store (Invariant 7.2).
Check 3.3: An auditor MUST find no degenerate window in the store (Invariant 6.1).
Check 4.1: An auditor MUST find no commitment's confirmed_at preceding the commitment's placed_at (Invariant 8.1).
Check 4.2: An auditor MUST find no commitment's released_at preceding the commitment's placed_at (Invariant 8.2).
Check 5.1: An auditor MUST find a re-read commitment's properties unchanged across an admitted resolving action (Invariant 5.1).
Check 5.2: An auditor MUST find no id on two commitments (Identity 5).
Check 6.1: An auditor MUST find no commitment absent from a later read (Invariant 10.1).
Check 6.2: An auditor MUST find the store instance's commitment count no lower on a later read (Invariant 10.2).
Check 7.1: An auditor MUST find a resource and a requester on EVERY commitment (State 1).
Check 7.2: An auditor MUST find a placed_at and an expires_at on EVERY commitment (State 1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing the resource confirmed returned to availability MUST read the registry (Non-goal 11, Non-goal 12).
External check 2: A deployment needing the transitions of one commitment ordered MUST read the composing [Event Log](./event-log.md) (Non-goal 3).
External check 3: A deployment needing a rejection observed MUST read the composing [Event Log](./event-log.md) (Non-goal 23).
External check 4: A deployment needing a requester bound to an actor MUST read the composing [Actor Identity](./actor-identity.md) attestation (Non-goal 14).
External check 5: A deployment needing the reclamation lag bounded MUST read the sweep's declared cadence (Capability requirement 7).
External check 6: A deployment needing the composing patterns named MUST read the deployment's own wiring (Non-goal 2, Non-goal 4, Non-goal 6, Non-goal 10, Non-goal 15, Non-goal 17, Non-goal 20).
```

WHY:
External check 1 is the sharpest boundary here and the one a deployment can quietly fail. An expired commitment attests that an expiry was *recorded*; whether the registry then made the resource available again is the registry's fact, and a deployment that writes the terminal state without freeing the resource conforms to every rule above and defeats the point. The atom cannot see availability and so cannot check it, which is exactly why this is stated rather than assumed.

External check 5 is the audit consequence of the eager-or-lazy choice (Non-goal 13). Under lazy expiry a lapsed commitment stays held until something touches it, so the resource is reclaimed at access time rather than at `expires_at`; the record is correct either way, and only the deployment's own declaration says how long the gap may be.

---

## Non-goals

```
Non-goal 1: The atom MUST NOT answer a repeated [Place Hold] with one commitment.
Non-goal 2: A deployment needing an idempotent place hold MUST compose [Duplicate Prevention](./duplicate-prevention.md).
Non-goal 3: The atom MUST NOT record a transition history.
Non-goal 4: A deployment needing the full transition history MUST compose [Event Log](./event-log.md).
Non-goal 5: The atom MUST NOT read a pool's capacity rule.
Non-goal 6: A deployment needing an aggregate capacity rule MUST compose a capacity constraint pattern.
Non-goal 7: The atom MUST NOT hold two resources on one commitment.
Non-goal 8: The atom MUST NOT offer a partial release.
Non-goal 9: The atom MUST NOT offer a compensating action against a confirmed commitment.
Non-goal 10: A deployment needing a confirmed commitment offset MUST compose a reversal pattern.
Non-goal 11: The atom MUST NOT define availability.
Non-goal 12: The atom MUST NOT decide whether a resource is hold-able.
Non-goal 13: The atom MUST NOT decide when [Expire] fires.
Non-goal 14: The atom MUST NOT bind a requester to an actor.
Non-goal 15: A deployment needing a non-repudiable commitment MUST compose [Actor Identity](./actor-identity.md).
Non-goal 16: The atom MUST NOT decide who may call an action.
Non-goal 17: A deployment needing an authorization decision MUST compose [Permissions](./permissions.md).
Non-goal 18: The atom MUST NOT decide what a confirmation means to the host.
Non-goal 19: The atom MUST NOT bound a commitment's retention.
Non-goal 20: A deployment needing retention MUST compose [Retention Window](./retention-window.md).
Non-goal 21: The atom MUST NOT pause a hold window.
Non-goal 22: The atom MUST NOT offer a multi-commitment transaction.
Non-goal 23: The atom MUST NOT surface a rejection to an audit trail.
Non-goal 24: The atom MUST NOT hold a resource fungible below the commitment's grain.
Non-goal 25: The atom MUST NOT guarantee that a lapsed commitment resolves.
Non-goal 26: A deployment needing two racing transitions ordered MUST read the composing [Event Log](./event-log.md) sequence_number.
```

WHY:
Non-goal 11 through 13 are the factoring decision that most looks like a hole. This atom refuses a [Place Hold] when the registry says the resource is not hold-able and never asks what hold-able means; it fires [Expire] when called and never decides when to call. Building either in would make the hold primitive depend on the two things most often wired around it, and would put the policy inside the mechanism.

Non-goal 1 is worth stating because the alternative is tempting. Two [Place Hold] calls for one logical intent produce two commitments, because the atom cannot tell a retry from a second genuine hold — that is exactly what an idempotency token is for, and [Idempotent Reservation](../compositions/idempotent-reservation.md) is the composition that wires it.

Non-goal 24 names where the atom breaks down rather than where it declines. A block of 100 seats sold to an agent who sub-allocates to passengers is not one commitment with a partial release; it is two tiers of commitment, and that is a composition rather than a bigger atom.

---

## Edge cases

### Atomic writes

```
Atomic writes 1: The implementation MUST commit a transition whole.
Atomic writes 2: The implementation MUST discard an uncommitted transition whole.
Atomic writes 3: The implementation MUST own the transactional boundary.
Atomic writes 4: The implementation MUST NOT repair a dangling transition.
```

WHY:
Atomic writes 4 is the honest limit. A crash between the state change and the instant's write leaves a commitment this atom has no rule for, and no rule here recovers it: the transactional boundary is the implementation's (Atomic writes 3), and a repair written here would be this atom guessing at a host's storage semantics.

### Concurrency

```
Concurrency 1: The implementation MUST commit the state check and the state change of a resolving action as one atomic operation.
Concurrency 2: A losing resolving action MUST answer not-held.
Concurrency 3: A losing [Place Hold] racing on one resource MUST answer resource-unavailable.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
```

Term string input: `resource` OR `requester` — every caller-supplied string this atom accepts.

Term blank: a value that is absent, empty, or carries only whitespace — what every presence check in this atom refuses; a blank argument NOT EXISTS.

WHY:
This family was missing from a draft of this migration, and its absence was invisible rather than benign: Operation 1 and Operation 2 read `NOT EXISTS` on caller-supplied strings, so without String 5 and String 6 a whitespace-only `resource` had no declared reading at all and two implementations could disagree about whether it is a hold (council read 38). The `blank` declaration is the corpus's, word for word across eleven specs, which is the point — the reading is shared and nobody owns it, and the *absence-as-nonexistence* watch entry counts it.

Byte-exactness matters here for the same reason it does wherever an identifier comes from outside: `resource` and `requester` are the caller's references, not values this atom issued, so `Room-14` and `room-14` are two resources and a deployment that means them as one canonicalizes before calling (Capability requirement 9, Identity 9).

NOTE: watch host obligations — this atom sets no maximum length on a string input and does not oblige the deployment to set one either, which is a fourth posture beside the three the *input-handling regime* docket row already counts: a declared cap, a delegated cap, and silence. `duration` is bounded by declaration (`duration bounds`) and the strings are bounded by nothing.

---

## Composition notes

```
Composition note 1: A composing [Duplicate Prevention](./duplicate-prevention.md) MUST map an idempotency token to the id an admitted place hold answered.
Composition note 2: A composing [Duplicate Prevention](./duplicate-prevention.md) MUST answer a repeated token with the mapped id.
Composition note 3: A composing [Event Log](./event-log.md) MUST append an event on EVERY admitted action.
Composition note 4: A composing [Event Log](./event-log.md) MUST append an event on EVERY refused action.
Composition note 5: A composing [Retention Window](./retention-window.md) MUST place a commitment under retention ONLY IF the commitment stands in a terminal state.
Composition note 6: A composing capacity constraint pattern MUST read the pool's capacity rule PER place hold.
Composition note 7: A composing capacity constraint pattern MUST NOT call [Place Hold] BEFORE the capacity decision.
Composition note 8: A composing capacity constraint pattern MUST return the pool slot on a releasing action.
Composition note 9: A composing reversal pattern MUST produce a new commitment.
Composition note 10: A composing reversal pattern MUST NOT change the offset commitment.
Composition note 11: A composing [Actor Identity](./actor-identity.md) MUST attest the actor behind EVERY call.
```

WHY:
Composition note 8 is the one [Reserve from Pool](../compositions/reserve-from-pool.md) rests on, and it is why expiry is a written transition at all. The pool slot comes back on the same event that returns the resource; a derived expiry would give the composition nothing to hang the return on.

Composition note 10 is the shape of every reversal in this library. A refund does not unconfirm a charge, an admission reversal does not un-admit, a return-to-stock does not un-ship — each produces a new record that offsets the old one, and terminal absorption (Invariant 3.1) is what makes that the only available move.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the deployment; the implementation; the registry; the store; the seam; the transition; a composing pattern; a caller; an auditor; a regulator; a data subject; an investigator; a reader; a commitment; a held commitment; a confirmed commitment; a released commitment; an expired commitment; an action; a resolving action; a refused action; a losing resolving action; a losing [Place Hold]; a rejection; a crash; a re-hold; an opaque reference; the store instance's commitment count.

Term records: `commitment` — one resource held for one requester for a bounded window, carrying `id`, `resource`, `requester`, `placed_at`, `expires_at`, a state and, where set, `confirmed_at`, `released_at` or `expired_at`.

Term record verbs: identify, assign, generate, change, share, carry, stand, read, answer, record, leave, own, admit, offer, hold, return, commit, discard, repair, refuse, write, find, resolve, name, compare, normalize, confirm, route, consult, append, place, produce, map, attest, fall, precede, sample, consume, supply, release, run, acknowledge, canonicalize, declare, compose, wire, remove, bind, decide, define, bound, surface, pass, reach, accept, pause, call, guarantee, trim, case-fold.

Term value sets: place_hold answers id and refuses invalid-request | resource-unavailable | storage-failure. confirm answers ok and refuses not-known | not-held | window-elapsed | storage-failure. release answers ok and refuses not-known | not-held | window-elapsed | storage-failure. expire answers ok and refuses not-known | not-held | window-not-elapsed | storage-failure. `state` = held | confirmed | released | expired. `terminal state` = confirmed | released | expired. `terminal instant` = confirmed_at | released_at | expired_at. `window reading` = open | lapsed. `window rejection` = window-elapsed | window-not-elapsed. `property` = resource | requester | placed_at | expires_at.

Term bounds: `duration bounds`, `window bound`.

Term cadences: empty.

Term qualifiers: `migrated` — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: `commitment`, `id`, `property`, `reference`, `registry`, `store instance`, `seam`, `transition`, `now`, `resolving action`, `well-formedness check`, `duration bounds`, `window bound`, `window reading`, `open`, `lapsed`, `window rejection`, `terminal state`, `terminal instant`, `admitted place hold`, `admitted confirm`, `admitted release`, `admitted expire`, `admitted resolving action`, `releasing action`, `string input`, `blank`, `reclamation lag`, `capacity decision`, `degenerate window`, `late resolution`, `premature expiry`, `re-hold`.

Term cited: `execution-contract.md` §Logic confinement — the seam and the transition.

Term composing pattern: [Duplicate Prevention](./duplicate-prevention.md), [Event Log](./event-log.md), [Retention Window](./retention-window.md), [Actor Identity](./actor-identity.md), [Permissions](./permissions.md), a capacity constraint pattern, a reversal pattern.

#### Place Hold

The behavior that records a new [Commitment] — assigning a fresh [Id] from the id material the seam supplies, setting [Resource], [Requester], [Placed At] and [Expires At], standing the record in [Held], and answering the [Id]. Rejected [Invalid Request], [Resource Unavailable] or [Storage Failure].

Kind: Operation

#### Confirm

The resolving behavior that takes a [Held] [Commitment] into a binding allocation, standing it in [Confirmed] and stamping [Confirmed At]. Legal only while the commitment reads open; rejected [Window Elapsed] once it reads lapsed, and [Not Held] on an already-terminal commitment.

Kind: Operation

#### Release

The resolving behavior that returns a [Held] [Commitment]'s resource to availability before the window closes, standing it in [Released] and stamping [Released At]. Legal only while the commitment reads open; rejected [Window Elapsed] once it reads lapsed, and [Not Held] on an already-terminal commitment.

Kind: Operation

#### Expire

The resolving behavior — the side-effecting lapse — that moves a lapsed [Held] [Commitment] to [Expired] and returns its resource, and in a pool-backed composition a capacity slot, to availability. Legal only while the commitment reads lapsed; rejected [Window Not Elapsed] while it reads open. Fired on a cadence or on the next access; the atom does not decide which.

Kind: Operation

#### Commitment

The record this atom defines: one resource held for one requester for a bounded window, resolved to exactly one terminal state. Carries [Id], [Resource], [Requester], [Placed At], [Expires At], a state, and the terminal instant of the transition that settled it.

Kind: Type
Projects: state

#### Id

The opaque, immutable identity of a [Commitment], assigned on [Place Hold] from the id material the seam supplies and never shared with a second commitment. The [Resource], [Requester] and window are properties, not identity.

Kind:     Field
Field of: Commitment
Projects: id

#### Resource

The reference naming what is held. Opaque to the atom — the registry owns what a resource is and what availability means. Set on [Place Hold], immutable thereafter.

Kind:     Field
Field of: Commitment
Projects: resource

#### Requester

The reference naming who the hold is for. Set on [Place Hold], immutable thereafter. The atom names the requester and does not bind the call to a verifiable actor — that is an [Actor Identity](./actor-identity.md) composition.

Kind:     Field
Field of: Commitment
Projects: requester

#### Placed At

The instant the [Commitment] was placed, stamped from [Now] on [Place Hold]. Immutable. The window opens here.

Kind:     Field
Field of: Commitment
Projects: placed_at

#### Expires At

The instant the window closes, recorded on [Place Hold] as the window bound. Immutable. The boundary the window reading is taken against: open above it, lapsed at it and below.

Kind:     Field
Field of: Commitment
Projects: expires_at

#### Confirmed At

The instant the [Commitment] was confirmed, stamped from [Now] on [Confirm]. Present only in [Confirmed]; immutable once set.

Kind:     Field
Field of: Commitment
Projects: confirmed_at

#### Released At

The instant the [Commitment] was released, stamped from [Now] on [Release]. Present only in [Released]; immutable once set.

Kind:     Field
Field of: Commitment
Projects: released_at

#### Expired At

The instant the [Commitment] expired, stamped from [Now] on [Expire]. Present only in [Expired]; immutable once set, and never earlier than [Expires At].

Kind:     Field
Field of: Commitment
Projects: expired_at

#### Duration

The window length supplied to [Place Hold]. It sizes the window and is not stored under its own name; [Placed At] and [Expires At] are what persist. Must fall inside the duration bounds.

Kind:         Parameter
Parameter of: Place Hold
Projects:     duration

#### Now

The wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it — never read inside the transition and never supplied by the business caller. Consumed twice per call: by the window reading and by the transition's stamp.

Kind:         Parameter
Parameter of: Place Hold
Projects:     now

#### Held

The one non-terminal state: the resource is encumbered for the requester and no resolution has occurred. Reads open or lapsed against [Now].

Kind:      Member
Member of: the commitment state
Role:      Outcome

#### Confirmed

The terminal state reached when the requester confirmed inside the window — the resource is taken into a binding allocation. Absorbing.

Kind:      Member
Member of: the commitment state
Role:      Outcome

#### Released

The terminal state reached when the commitment was released inside the window — the resource returns to availability. Absorbing.

Kind:      Member
Member of: the commitment state
Role:      Outcome

#### Expired

The terminal state reached when the window lapsed with the commitment still [Held] and an [Expire] then fired, stamping [Expired At] — the resource returns to availability. Absorbing.

Kind:      Member
Member of: the commitment state
Role:      Outcome

#### Invalid Request

The refusal [Place Hold] returns when [Resource], [Requester] or [Duration] is absent, or [Duration] falls outside the duration bounds. No commitment is recorded.

Kind:      Member
Member of: the Place Hold rejection
Role:      Outcome
Projects:  invalid-request

#### Resource Unavailable

The refusal [Place Hold] returns when the registry refuses the resource. The loser of a concurrent place-hold race for one resource receives this. No commitment is recorded.

Kind:      Member
Member of: the Place Hold rejection
Role:      Outcome
Projects:  resource-unavailable

#### Not Known

The refusal a resolving action returns when the supplied [Id] names no commitment. A lookup miss, distinct from a state or window rejection.

Kind:      Member
Member of: the resolving-action rejection
Role:      Outcome
Projects:  not-known

#### Not Held

The refusal a resolving action returns when the commitment already stands in a terminal state — distinct from [Not Known], which says the id resolved to nothing at all. The single-resolution guard; nothing is written.

Kind:      Member
Member of: the resolving-action rejection
Role:      Outcome
Projects:  not-held

#### Window Elapsed

The refusal [Confirm] or [Release] returns when the still-[Held] commitment reads lapsed. Nothing is written; the atom never records a resolution after the window closes.

Kind:      Member
Member of: the resolving-action rejection
Role:      Outcome
Projects:  window-elapsed

#### Window Not Elapsed

The refusal [Expire] returns when the commitment reads open. The symmetric counterpart to [Window Elapsed]; nothing is written, and the atom never expires a commitment before its window closes.

Kind:      Member
Member of: the Expire rejection
Role:      Outcome
Projects:  window-not-elapsed

#### Storage Failure

The refusal any action returns when the store refuses the write after every precondition passes. No commitment is recorded, or the commitment remains [Held]. Definitive, which rests on Capability requirement 6.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Place Hold]: #place-hold
[Confirm]: #confirm
[Release]: #release
[Expire]: #expire
[Commitment]: #commitment
[Id]: #id
[Resource]: #resource
[Requester]: #requester
[Placed At]: #placed-at
[Expires At]: #expires-at
[Confirmed At]: #confirmed-at
[Released At]: #released-at
[Expired At]: #expired-at
[Duration]: #duration
[Now]: #now
[Held]: #held
[Confirmed]: #confirmed
[Released]: #released
[Expired]: #expired
[Invalid Request]: #invalid-request
[Resource Unavailable]: #resource-unavailable
[Not Known]: #not-known
[Not Held]: #not-held
[Window Elapsed]: #window-elapsed
[Window Not Elapsed]: #window-not-elapsed
[Storage Failure]: #storage-failure

---

## Standards references

- **ISO 9001:2015 §8.5.2 (Identification and traceability)** — the minimum anchor. A resource under provisional commitment must be identifiable and traceable through every transition; the identity model and the per-commitment instants satisfy it directly.
- **ISO 9001:2015 §8.5.4 (Preservation)** — the resource is preserved in its committed state for the window's length; Invariant 6.1 is the operational form.
- **Basel III liquidity framework (BCBS 238 LCR)** — credit-limit holds and intraday liquidity reservations follow this lifecycle. Terminal absorption matches Basel's expectation that settlement events are facts about the past.
- **The Joint Commission, *Provision of Care, Treatment, and Services*** — bed-management and capacity coordination require resource encumbrance to be auditable and time-bounded; Invariant 7 is the structural correlate.
- **IATA Resolution 830a and related ticketing-time-limit rules** — airline fare-lock and seat-hold semantics formalize the window contract this atom abstracts; the atom is vocabulary-neutral, IATA is one instantiation.
- **PCI DSS Requirement 10 (logging and monitoring)** — for commitments touching cardholder data, every transition must be logged. Composes with [Event Log](./event-log.md) (Non-goal 4).
- **GDPR Article 30 (records of processing activities)** — a commitment record carrying personal data is itself a processing activity; [Requester], [Placed At], [Expires At] and the terminal instant supply the data points Art. 30 expects. What counts as a processing purpose is host policy (Non-goal 18).
- **Sarbanes-Oxley §404 (internal control over financial reporting)** — where a confirmed commitment is material to reporting, the controls around the held-to-confirmed transition are §404-scope. Composes with [Event Log](./event-log.md) for the evidence an attestation requires.

For commitments touching protected health information, HIPAA's audit-controls requirement (45 CFR §164.312(b)) applies to the composing [Event Log](./event-log.md) instance rather than to the commitment record; the same separation applies to GDPR Art. 30 where the log carries the processing history.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture, and the discipline of composing capacity, idempotency, audit and reversal as separate concepts.
- **Eiffel's design-by-contract** — preconditions on each action; named rejection reasons.
- **Linear temporal logic** — terminal absorption, single-resolution and the honored window as temporal properties.
- **Two-phase commit and reservation protocols** — the prepare/commit shape this atom abstracts; here the prepare phase is visible business state rather than an implementation detail hidden under transactional semantics.

---

## Status

`grounded on Final Critique 4 — 2026-06-18` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-06-18
formal: verified — provisional-commitment.tla + 2 twins, 2026-06-04
last gate: 2026-06-18 — Final Critique 4, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/provisional-commitment.md`.

- **2026-09-13 — The window boundary is declared once, as a term, instead of being restated at four guard sites.** *Chose:* `open` and `lapsed` as a two-member window reading, with the boundary instant declared onto the lapsed side. *Over:* repeating `now < expires_at` and `now ≥ expires_at` in each guard, which is how the prose carried it. *Because:* the boundary is one proposition and a spec pays for a proposition once (GRACE-lang Authority 3); four copies are four chances for an edit to move three of them. It also routes the comparison out of the rules, which carry no arithmetic (GRACE-lang Hard invariant 24).
- **2026-09-13 — The resource return is the registry's obligation, not the atom's.** *Chose:* Capability requirement 10 and Capability requirement 11. *Over:* an `Operation` obliging the atom to return the resource, which a draft of this migration carried. *Because:* the atom cannot see availability (Non-goal 11) and External check 1's own WHY says so, which made the rule either false or unfalsifiable — a MUST whose subject cannot evaluate it is decoration. The asymmetry was the tell: the negative half (*an admitted confirm MUST NOT return it*) was specifiable and the positive half was not.
- **2026-09-13 — Single-resolution is stated as at-most-one, and the at-least-one half is a non-goal.** *Chose:* `Invariant 2.1` and `Invariant 2.2` alone, with `Non-goal 25` naming the limit and `Capability requirement 12` where a deployment may close it. *Over:* a third rule reading *EXACTLY ONE resolving action MUST commit*. *Because:* its marginal content over the other two was liveness, which an atom that licenses lazy expiry cannot deliver — and the model says the same: `INVARIANT Safety` with no temporal property, and `Inv_SingleResolution` checking only that a written resolution matches the state. The spec claimed *exactly*; the model checked *at most*. GRACE's `MUST` has no temporal scope to tell them apart, which is now a docket row.
- **2026-09-13 — Invariant 4 and Invariant 9 are tombstoned; Identity owns id stability and id reuse.** *Chose:* Identity 4 and Identity 5 as the single owners. *Over:* keeping the invariants, which restated them. *Because:* Authority 3 — and Identity 5 is the stronger claim, since two commitments never share an id whether or not either has resolved.
- **2026-06-23 — Expiry stays a stored terminal reached by an explicit `expire` event; the derived-expiry refactor is withdrawn for this atom.** *Chose:* stored `Expired` with `expired_at`, the `window-not-elapsed` rejection and `confirm`'s `window-elapsed` guard restored. *Over:* the corpus-wide derive-expiry-at-read-time move applied two days earlier. *Because:* this atom's lapse has a side effect — `expire` releases the resource, and in a pool-backed composition returns a capacity slot — which Reserve from Pool and Idempotent Reservation call and map; derived expiry is for side-effect-free lapses only.

NOTE: End of Provisional Commitment.
