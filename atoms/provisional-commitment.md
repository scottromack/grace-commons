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

Provisional Commitment is the business act of holding something for someone while they decide — a card authorization, a hospital bed, an item in a cart, a hotel room, an airline seat. A hold is placed, stays open for a fixed window, and resolves at most once, into one of three recorded end states: confirmed, released, or expired. The window is a promise in both directions: the resource stays reserved until it closes, and the requester must decide before it does.

Resolving at most once is the guarantee. A resolving call against an already-settled hold is refused. A confirm or release past the window is refused. An expire before the window closes is refused. Each hold carries a permanent id; its resource, requester and window are fixed at placement and never change. A settled hold is therefore an unambiguous and provable record of what happened.

Retry safety, the full transition history, and pool-wide capacity limits are deliberately outside the atom — each is a separate pattern that composes with it.

*Also known as: a hold, a reservation, a tentative reservation, a two-phase reservation.*

---

## Intent

A requester needs a resource whose allocation is not yet certain. The system holds it for a known period, during which the requester confirms (taking it into a binding allocation) or releases (returning it to availability). If neither happens before the period elapses, an [Expire] event moves the hold to its terminal [Expired] state and returns the resource.

Expiry is a written transition rather than a status inferred at read time because the lapse has a side effect — it returns the resource, and in a pool-backed composition a capacity slot. A side-effect-free lapse could be derived; this one releases something and so needs a write.

The shape is constant across regulated industries: credit-limit holds pending settlement, bed assignments pending admission, inventory reservations pending checkout, room bookings pending check-in, seat holds pending purchase. A resource is encumbered for a bounded window, the encumbrance resolves, and the record of it is itself a regulated asset.

This is a freestanding atom in the EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) sense — its own state, its own five actions, its own operational principles. It does not implement idempotency under retry, the full audit trail of every observation, or aggregate capacity constraints over a pool. Each is a separate composable atom; see Composition notes.

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
Identity 13: The deployment MUST route EVERY call to one database instance.
```

Term commitment: the record this atom holds — one resource held for one requester for a bounded window, then resolved to exactly one terminal state.

Term id: the opaque value naming one commitment — an [Id]; assigned from the id material the seam supplies and never reused.

Term property: resource | requester | placement instant | expiry instant — what a commitment carries that is not the commitment's identity.

Term reference: id, resource OR requester — every opaque reference this atom records.

Term registry: the deployment's owner of what a resource is and what availability means; outside this atom (Non-goal 11).

Term database instance: one named database a call is routed to; id uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the id material and the registry's availability verdict here.

Term transition: the atom's evaluation of one call against the commitment records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

### State

```
State 1: EVERY commitment MUST carry id, resource, requester, placement instant, expiry instant and a state.
State 2: EVERY confirmed commitment MUST carry confirmation instant.
State 3: EVERY released commitment MUST carry release instant.
State 4: EVERY expired commitment MUST carry lapse instant.
State 5: A held commitment MUST NOT carry a terminal instant.
State 6: The atom MUST NOT record the duration under the duration's own name.
State 7: The atom MUST NOT hold a state for a resource carrying no commitment.
State 8: The atom MUST NOT offer an unconfirm surface.
State 9: The atom MUST NOT offer a reactivate surface.
State 10: The atom MUST NOT offer a window extension surface.
State 11: The atom MUST NOT offer a commitment removal surface.
```

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the id material at the seam.
Capability requirement 3: The registry MUST run the availability read and the hold write for one resource as one critical section.
Capability requirement 4: The registry MUST release the critical section on the caller's return.
Capability requirement 5: The registry MUST release the critical section on the caller's death.
Deleted: Capability requirement 6. Execution Contract Database 3 owns it.
Capability requirement 7: A deployment firing [Expire] on a cadence MUST declare the cadence.
Capability requirement 8: A deployment firing [Expire] on a cadence MUST declare the reclamation window the cadence falls inside.
Capability requirement 9: The deployment MUST canonicalize an opaque reference.
Capability requirement 10: The registry MUST return the resource to availability on a releasing action.
Capability requirement 11: The registry MUST NOT return the resource to availability on an admitted confirm.
Capability requirement 12: A deployment firing [Expire] on a cadence MUST resolve EVERY lapsed commitment WITHIN the reclamation window.
Capability requirement 15: The deployment MUST supply the commitment records PER Execution Contract Database 1 through 4, Execution Contract Database 6, Execution Contract Read 4, Execution Contract Refusal 1 and Execution Contract Conformance 9.
Deleted: Capability requirement 13. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 14. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 6. Non-goal 26 owns it.
```

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

read()
  answers every commitment
```

```
Operation 1: IF resource EQUALS blank THEN [Place Hold] MUST answer invalid-request.
Operation 2: IF requester EQUALS blank THEN [Place Hold] MUST answer invalid-request.
Operation 3: IF duration EQUALS blank THEN [Place Hold] MUST answer invalid-request.
Operation 4: IF the duration falls outside the duration bounds THEN [Place Hold] MUST answer invalid-request.
Operation 5: IF the registry refuses the resource THEN [Place Hold] MUST answer resource-unavailable.
Deleted: Operation 6. Execution Contract Refusal 1 owns it.
Operation 7: [Place Hold] MUST NOT answer not-known.
Operation 8: An admitted place hold MUST assign a fresh id.
Operation 9: An admitted place hold MUST record resource and requester.
Operation 10: An admitted place hold MUST record now as placement instant.
Operation 11: An admitted place hold MUST record the window bound as expiry instant.
Operation 12: An admitted place hold MUST stand the commitment in held.
Operation 13: An admitted place hold MUST answer the id.
Operation 14: IF the id names no commitment THEN a resolving action MUST answer not-known.
Operation 15: IF the commitment's state IS IN the terminal states THEN a resolving action MUST answer not-held.
Deleted: Operation 16. Execution Contract Refusal 1 owns it.
Operation 17: IF the commitment reads lapsed THEN [Confirm] MUST answer window-elapsed.
Operation 18: IF the commitment reads lapsed THEN [Release] MUST answer window-elapsed.
Operation 19: IF the commitment reads open THEN [Expire] MUST answer window-not-elapsed.
Deleted: Operation 20. Execution Contract Refusal 1 owns it.
Operation 21: An admitted confirm MUST stand the commitment in confirmed.
Operation 22: An admitted release MUST stand the commitment in released.
Operation 23: An admitted expire MUST stand the commitment in expired.
Operation 24: An admitted confirm MUST record now as confirmation instant.
Operation 25: An admitted release MUST record now as release instant.
Operation 26: An admitted expire MUST record now as lapse instant.
Deleted: Operation 27. Execution Contract Database 1 owns it.
Operation 28: IF the database refuses the write THEN an action MUST answer storage-failure.
Deleted: Operation 29. Execution Contract Refusal 1 owns it.
Operation 30: A refused action MUST leave the commitment as the call found the commitment.
Operation 31: A refused [Place Hold] MUST NOT record a commitment.
Deleted: Operation 32. Operation 30 owns it.
Operation 33: A resolving action MUST NOT accept a resource.
Operation 34: A resolving action MUST NOT accept a requester.
Operation 35: A resolving action MUST NOT accept a duration.
Deleted: Operation 36. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 37. Execution Contract Logic confinement 3 owns it.
Operation 38: [Read] MUST answer EVERY commitment, held AND terminal.
Operation 39: [Read] MUST answer a commitment's stored fields.
Operation 40: [Read] MUST NOT write.
Operation 41: [Read] MUST NOT refuse a call.
```

NOTE: watch the state a refusal leaves (Operation 30).

Term resolving action: [Confirm] | [Release] | [Expire] — every action taking a held commitment to a terminal state.

Term duration bounds: the implementation's admitted range for a duration; every admitted value exceeds zero.

Term window bound: placement instant raised by the duration — the value an admitted place hold records as expiry instant.

Term window reading: open | lapsed — how a held commitment's window reads against now.

Term open: the window reading of a held commitment whose expiry instant exceeds now.

Term lapsed: the window reading of a held commitment whose expiry instant does not exceed now; the boundary instant — expiry instant equal to now — reads lapsed.

Term window rejection: window-elapsed | window-not-elapsed.

Term terminal state: confirmed | released | expired.

Term terminal instant: confirmation instant | release instant | lapse instant.

Term admitted place hold: a [Place Hold] call the action admits (Execution Contract Read 4).

Term admitted confirm: a [Confirm] call the action admits (Execution Contract Read 4).

Term admitted release: a [Release] call the action admits (Execution Contract Read 4).

Term admitted expire: a [Expire] call the action admits (Execution Contract Read 4).

Term admitted resolving action: an admitted confirm, an admitted release OR an admitted expire.

Term releasing action: an admitted release OR an admitted expire.

Term reclamation lag: the span between a commitment's expiry instant and the admitted expire that settles the commitment.

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
- **Invariant 3 — Terminal absorption.**
  ```
  Invariant 3.1: A commitment whose state IS IN the terminal states MUST NOT leave the terminal state.
  Deleted: Invariant 4. Identity 4 owns id stability.
  ```
- **Invariant 5 — Property immutability.**
  ```
  Invariant 5.1: An admitted resolving action MUST NOT change a property.
  Deleted: Invariant 5.2. Operation 8 owns it.
  ```
- **Invariant 6 — Hold window monotonicity.**
  ```
  Invariant 6.1: The database MUST NOT carry a degenerate window.
  ```
- **Invariant 7 — Honored window.**
  ```
  Invariant 7.1: The database MUST NOT carry a late resolution.
  Invariant 7.2: The database MUST NOT carry a premature expiry.
  Invariant 7.3: EVERY held commitment MUST read EXACTLY ONE OF open, lapsed.
  ```
- **Invariant 8 — Resolution instants follow placement.**
  ```
  Invariant 8.1: A commitment's confirmation instant MUST NOT PRECEDE the commitment's placement instant.
  Invariant 8.2: A commitment's release instant MUST NOT PRECEDE the commitment's placement instant.
  Deleted: Invariant 9. Identity 5 owns id reuse for every id, resolved or not.
  ```
- **Invariant 10 — Commitment record durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove a commitment from the database.
  Deleted: Invariant 10.2. Invariant 10.1 and Execution Contract Database 4 own it.
  Deleted: Invariant 10.3. Execution Contract Database 1 owns it.
  ```

Term degenerate window: a commitment whose expiry instant does not exceed the commitment's placement instant.

Term late resolution: a commitment whose state EQUALS confirmed and whose expiry instant does not exceed the commitment's confirmation instant, OR one whose state EQUALS released and whose expiry instant does not exceed the commitment's release instant.

Term premature expiry: a commitment whose state EQUALS expired and whose lapse instant precedes the commitment's expiry instant.

Term capacity decision: a composing capacity constraint pattern's reading of the pool's capacity rule for one place hold.

---

## Examples

The same atom, five regulated domains, one mechanic.

### Banking — credit-limit hold

`place_hold(card, cardholder, 7-days)` → `auth_c41`; available credit drops by $250. The merchant captures within the window — `confirm(auth_c41)` — and the charge settles; or voids it — `release(auth_c41)` — and credit restores. If neither, the scheme's settlement sweep fires `expire(auth_c41)` on the eighth day and a late capture is refused window-elapsed. Each transition feeds liquidity reporting aligned with the BCBS (Basel Committee on Banking Supervision).

### Healthcare — bed assignment

`place_hold(bed, patient, 2-hours)` → `bed_h17`, placed 14:00, expiring 16:00. The patient arrives at 14:45 — `confirm(bed_h17)`; or is discharged from the emergency department — `release(bed_h17)`. If neither by 16:00 the bed-management sweep fires `expire(bed_h17)` and the bed returns to the pool. The Joint-Commission-aligned care-coordination audit reads the commitment record directly.

### Retail — inventory reservation

`place_hold(sku, shopper, 15-minutes)` → `inv_r93`, placed 19:14. The shopper checks out at 19:18 — `confirm(inv_r93)`; or empties the cart — `release(inv_r93)`. An abandoned cart is swept from 19:29 — `expire(inv_r93)` — and the unit returns to stock.

### Hospitality — room booking

`place_hold(room, guest, duration)` → `rm_b58`, expiring at the property's cancellation cutoff. Check-in confirms; cancellation by the cutoff releases; neither leaves the sweep to expire it, which is the transition the property's no-show fee policy — a separate composing pattern — triggers off.

### Airline — seat hold

`place_hold(seat, passenger, 15-minutes)` → `seat_a22`, the carrier's fare-lock per IATA (International Air Transport Association) practice. Payment confirms; backing out releases; abandonment expires. The attached fare quote is invalidated whenever the hold leaves availability, which a composing Fare Quote pattern observes from the terminal state.

What differs across the five: resource semantics, window length, the regulatory framing of the trail, and which patterns compose. What does not differ: an undecided hold ends in a recorded expire that returns the resource.

### Regulated adversarial scenarios

- **Regulator audit.** *Show me every hold confirmed or released after its declared window.* The query is Check 3.1 and returns the empty set by construction — Invariant 7.1 makes a late resolution unrecordable rather than merely unlikely.
- **Data subject request.** Erasure against the personal data behind requester. The atom alone cannot satisfy it while keeping the trail; a composing Shred or Erasure Tombstone pattern redacts the reference and leaves id, placement instant, expiry instant, the state and the terminal instant intact, so the lifecycle stays auditable and the personal data does not persist.
- **Breach investigation.** The universe of resources committed between 02:00 and 04:00 UTC. Every commitment carries placement instant, so the answer is a filter over the database with no log replay behind it; the terminal state and its instant then say which holds resolved and which lapsed. [Read] answers every commitment the database holds (Operation 38), and ordering *within* the window needs the composing [Event Log](./event-log.md) (External check 2).

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the commitment records.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY commitment whose state EQUALS EXACTLY ONE OF held, confirmed, released, expired (Invariant 1.1).
Check 1.2: An auditor MUST find a terminal instant on EVERY commitment whose state IS IN the terminal states (State 2, State 3, State 4).
Check 1.3: An auditor MUST find no terminal instant on a held commitment (State 5).
Check 2.1: An auditor MUST find no commitment carrying two terminal instants (Invariant 2.2).
Check 2.2: An auditor MUST find no commitment whose state IS NOT IN the terminal states on a later read of a commitment a prior read found in that terminal state (Invariant 3.1).
Check 3.1: An auditor MUST find no late resolution in the database (Invariant 7.1).
Check 3.2: An auditor MUST find no premature expiry in the database (Invariant 7.2).
Check 3.3: An auditor MUST find no degenerate window in the database (Invariant 6.1).
Check 4.1: An auditor MUST find no commitment's confirmation instant preceding the commitment's placement instant (Invariant 8.1).
Check 4.2: An auditor MUST find no commitment's release instant preceding the commitment's placement instant (Invariant 8.2).
Check 5.1: An auditor MUST find a re-read commitment's properties unchanged across an admitted resolving action (Invariant 5.1).
Check 5.2: An auditor MUST find no id on two commitments (Identity 5).
Deleted: Check 6.1. Execution Contract Database 6 owns it.
Deleted: Check 6.2. Execution Contract Database 6 owns it.
Check 7.1: An auditor MUST find a resource and a requester on EVERY commitment (State 1).
Check 7.2: An auditor MUST find a placement instant and an expiry instant on EVERY commitment (State 1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing the resource confirmed returned to availability MUST read the registry (Non-goal 11, Non-goal 12).
External check 2: A deployment needing the transitions of one commitment ordered MUST read the composing Event Log (Non-goal 3).
External check 3: A deployment needing a rejection observed MUST read the composing Event Log (Non-goal 23).
External check 4: A deployment needing a requester bound to an actor MUST read the composing Actor Identity attestation (Non-goal 14).
External check 5: A deployment needing the reclamation lag bounded MUST read the sweep's declared cadence (Capability requirement 7).
Deleted: External check 6. Execution Contract Conformance 9 owns it.
Deleted: External check 7. Execution Contract Database 6 owns it.
```

---

## Non-goals

```
Non-goal 1: The atom MUST NOT answer a repeated [Place Hold] with one commitment.
Non-goal 2: A deployment needing an idempotent place hold MUST compose Duplicate Prevention.
Non-goal 3: The atom MUST NOT record a transition history.
Non-goal 4: A deployment needing the full transition history MUST compose Event Log.
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
Non-goal 15: A deployment needing a non-repudiable commitment MUST compose Actor Identity.
Non-goal 16: The atom MUST NOT decide who may call an action.
Non-goal 17: A deployment needing an authorization decision MUST compose Permissions.
Non-goal 18: The atom MUST NOT decide what a confirmation means to the host.
Non-goal 19: The atom MUST NOT bound a commitment's retention.
Non-goal 20: A deployment needing retention MUST compose Retention Window.
Non-goal 21: The atom MUST NOT pause a hold window.
Non-goal 22: The atom MUST NOT offer a multi-commitment transaction.
Non-goal 23: The atom MUST NOT surface a rejection to an audit trail.
Non-goal 24: The atom MUST NOT hold a resource fungible below the commitment's grain.
Non-goal 25: The atom MUST NOT guarantee that a lapsed commitment resolves.
Non-goal 26: A deployment needing two racing transitions ordered MUST read the composing Event Log sequence number.
```

NOTE: the owners — [Idempotent Reservation](../compositions/idempotent-reservation.md) (Non-goal 1, Non-goal 2); the registry (Non-goal 11, Non-goal 12, External check 1); the deployment (Non-goal 13, Capability requirement 7; Non-goal 25, Capability requirement 12); a composition of two tiers of commitment (Non-goal 24).

---

## Edge cases

### Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
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

Term string input: resource OR requester — every caller-supplied string this atom accepts.

NOTE: watch host obligations — this atom sets no maximum length on a string input and does not oblige the deployment to set one either, which is a fourth posture beside the three the *input-handling regime* docket row already counts: a declared cap, a delegated cap, and silence. duration is bounded by declaration (duration bounds) and the strings are bounded by nothing.

---

## Composition notes

```
Composition note 1: A composing Duplicate Prevention MUST map an idempotency token to the id an admitted place hold answered.
Composition note 2: A composing Duplicate Prevention MUST answer a repeated token with the mapped id.
Composition note 3: A composing Event Log MUST append an event on EVERY admitted action.
Composition note 4: A composing Event Log MUST append an event on EVERY refused action.
Composition note 5: A composing Retention Window MUST place a commitment under retention ONLY IF the commitment's state IS IN the terminal states.
Composition note 6: A composing capacity constraint pattern MUST read the pool's capacity rule PER place hold.
Composition note 7: A composing capacity constraint pattern MUST NOT call [Place Hold] BEFORE the capacity decision.
Composition note 8: A composing capacity constraint pattern MUST return the pool slot on a releasing action.
Composition note 9: A composing reversal pattern MUST produce a new commitment.
Composition note 10: A composing reversal pattern MUST NOT change the offset commitment.
Composition note 11: A composing Actor Identity MUST attest the actor behind EVERY call.
```

NOTE: composing patterns — [Reserve from Pool](../compositions/reserve-from-pool.md).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the deployment; the registry; the database; the seam; the transition; a composing pattern; a caller; an auditor; a regulator; a data subject; an investigator; a reader; a commitment; a held commitment; a confirmed commitment; a released commitment; an expired commitment; an action; a resolving action; a refused action; a losing [Place Hold]; a rejection; a crash; an opaque reference.

Term records: commitment — one resource held for one requester for a bounded window, carrying id, resource, requester, placement instant, expiry instant, a state and, where set, confirmation instant, release instant or lapse instant.

Term record verbs: identify, assign, generate, change, share, carry, stand, read, answer, record, leave, admit, offer, hold, return, refuse, write, find, resolve, name, compare, normalize, confirm, route, consult, append, place, produce, map, attest, fall, precede, sample, consume, supply, release, run, canonicalize, declare, compose, wire, remove, bind, decide, define, bound, surface, pass, reach, accept, pause, call, guarantee, trim, case-fold.

Term value sets: state = held | confirmed | released | expired. terminal state = confirmed | released | expired. terminal instant = confirmation instant | release instant | lapse instant. window reading = open | lapsed. window rejection = window-elapsed | window-not-elapsed. property = resource | requester | placement instant | expiry instant.

Term bounds: duration bounds, window bound.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: commitment, id, property, reference, registry, database instance, seam, transition, now, resolving action, duration bounds, window bound, window reading, open, lapsed, window rejection, terminal state, terminal instant, admitted place hold, admitted confirm, admitted release, admitted expire, admitted resolving action, releasing action, string input, blank, reclamation lag, capacity decision, degenerate window, late resolution, premature expiry.

Term cited: sequence number: Event Log. The section titled Logic Confinement Principle in `execution-contract.md` — the seam and the transition.

Term composing pattern: [Duplicate Prevention](./duplicate-prevention.md), [Event Log](./event-log.md), [Retention Window](./retention-window.md), [Actor Identity](./actor-identity.md), [Permissions](./permissions.md), a capacity constraint pattern, a reversal pattern.

#### Place Hold

The behavior that records a new [Commitment] — assigning a fresh [Id] from the id material the seam supplies, setting [Resource], [Requester], [Placement Instant] and [Expiry Instant], standing the record in [Held], and answering the [Id]. Rejected [Invalid Request], [Resource Unavailable] or [Storage Failure].

Kind: Operation

#### Confirm

The resolving behavior that takes a [Held] [Commitment] into a binding allocation, standing it in [Confirmed] and stamping [Confirmation Instant]. Legal only while the commitment reads open; rejected [Window Elapsed] once it reads lapsed, and [Not Held] on an already-terminal commitment.

Kind: Operation

#### Release

The resolving behavior that returns a [Held] [Commitment]'s resource to availability before the window closes, standing it in [Released] and stamping [Release Instant]. Legal only while the commitment reads open; rejected [Window Elapsed] once it reads lapsed, and [Not Held] on an already-terminal commitment.

Kind: Operation

#### Expire

The resolving behavior — the side-effecting lapse — that moves a lapsed [Held] [Commitment] to [Expired] and returns its resource, and in a pool-backed composition a capacity slot, to availability. Legal only while the commitment reads lapsed; rejected [Window Not Elapsed] while it reads open. Fired on a cadence or on the next access; the atom does not decide which.

Kind: Operation

#### Read

The read-only query answering every commitment the database holds, held and terminal, each with its stored fields. It changes nothing and refuses nothing.

Kind: Operation

#### Commitment

The record this atom defines: one resource held for one requester for a bounded window, resolved to exactly one terminal state. Carries [Id], [Resource], [Requester], [Placement Instant], [Expiry Instant], a state, and the terminal instant of the transition that settled it.

Kind: Type
Projection: state

#### Id

The opaque, immutable identity of a [Commitment], assigned on [Place Hold] from the id material the seam supplies and never shared with a second commitment. The [Resource], [Requester] and window are properties, not identity.

Kind:       Field
Field of:   Commitment
Projection: id

#### Resource

The reference naming what is held. Opaque to the atom — the registry owns what a resource is and what availability means. Set on [Place Hold], immutable thereafter.

Kind:       Field
Field of:   Commitment
Projection: resource

#### Requester

The reference naming who the hold is for. Set on [Place Hold], immutable thereafter. The atom names the requester and does not bind the call to a verifiable actor — that is an [Actor Identity](./actor-identity.md) composition.

Kind:       Field
Field of:   Commitment
Projection: requester

#### Placement Instant

The instant the [Commitment] was placed, stamped from [Now] on [Place Hold]. Immutable. The window opens here.

Kind:       Field
Field of:   Commitment
Projection: placed_at

#### Expiry Instant

The instant the window closes, recorded on [Place Hold] as the window bound. Immutable. The boundary the window reading is taken against: open above it, lapsed at it and below.

Kind:       Field
Field of:   Commitment
Projection: expires_at

#### Confirmation Instant

The instant the [Commitment] was confirmed, stamped from [Now] on [Confirm]. Present only in [Confirmed]; immutable once set.

Kind:       Field
Field of:   Commitment
Projection: confirmed_at

#### Release Instant

The instant the [Commitment] was released, stamped from [Now] on [Release]. Present only in [Released]; immutable once set.

Kind:       Field
Field of:   Commitment
Projection: released_at

#### Lapse Instant

The instant the [Commitment] expired, stamped from [Now] on [Expire]. Present only in [Expired]; immutable once set, and never earlier than [Expiry Instant].

Kind:       Field
Field of:   Commitment
Projection: expired_at

#### Duration

The window length supplied to [Place Hold]. It sizes the window and is not stored under its own name; [Placement Instant] and [Expiry Instant] are what persist. Must fall inside the duration bounds.

Kind:         Parameter
Parameter of: Place Hold
Projection:   duration

#### Now

The wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it — never read inside the transition and never supplied by the business caller. Consumed twice per call: by the window reading and by the transition's stamp.

Kind:         Parameter
Parameter of: Place Hold
Projection:   now

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

The terminal state reached when the window lapsed with the commitment still [Held] and an [Expire] then fired, stamping [Lapse Instant] — the resource returns to availability. Absorbing.

Kind:      Member
Member of: the commitment state
Role:      Outcome

#### Invalid Request

The refusal [Place Hold] returns when [Resource], [Requester] or [Duration] is absent, or [Duration] falls outside the duration bounds. No commitment is recorded.

Kind:       Member
Member of:  the Place Hold rejection
Role:       Outcome
Projection: invalid-request

#### Resource Unavailable

The refusal [Place Hold] returns when the registry refuses the resource. The loser of a concurrent place-hold race for one resource receives this. No commitment is recorded.

Kind:       Member
Member of:  the Place Hold rejection
Role:       Outcome
Projection: resource-unavailable

#### Not Known

The refusal a resolving action returns when the supplied [Id] names no commitment. A lookup miss, distinct from a state or window rejection.

Kind:       Member
Member of:  the resolving-action rejection
Role:       Outcome
Projection: not-known

#### Not Held

The refusal a resolving action returns when the commitment already stands in a terminal state — distinct from [Not Known], which says the id resolved to nothing at all. The single-resolution guard; nothing is written.

Kind:       Member
Member of:  the resolving-action rejection
Role:       Outcome
Projection: not-held

#### Window Elapsed

The refusal [Confirm] or [Release] returns when the still-[Held] commitment reads lapsed. Nothing is written; the atom never records a resolution after the window closes.

Kind:       Member
Member of:  the resolving-action rejection
Role:       Outcome
Projection: window-elapsed

#### Window Not Elapsed

The refusal [Expire] returns when the commitment reads open. The symmetric counterpart to [Window Elapsed]; nothing is written, and the atom never expires a commitment before its window closes.

Kind:       Member
Member of:  the Expire rejection
Role:       Outcome
Projection: window-not-elapsed

#### Storage Failure

The refusal any action returns when the database refuses the write after every precondition passes. No commitment is recorded, or the commitment remains [Held]. Definitive, which rests on Capability requirement 15.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Place Hold]: #place-hold
[Confirm]: #confirm
[Release]: #release
[Expire]: #expire
[Read]: #read
[Commitment]: #commitment
[Id]: #id
[Resource]: #resource
[Requester]: #requester
[Placement Instant]: #placement-instant
[Expiry Instant]: #expiry-instant
[Confirmation Instant]: #confirmation-instant
[Release Instant]: #release-instant
[Lapse Instant]: #lapse-instant
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

- **ISO (International Organization for Standardization) 9001:2015 clause 8.5.2 (Identification and traceability)** — the minimum anchor. A resource under provisional commitment must be identifiable and traceable through every transition; the identity model and the per-commitment instants satisfy it directly.
- **ISO 9001:2015 clause 8.5.4 (Preservation)** — the resource is preserved in its committed state for the window's length; Invariant 6.1 is the operational form.
- **Basel III liquidity framework (BCBS 238 LCR — the Liquidity Coverage Ratio)** — credit-limit holds and intraday liquidity reservations follow this lifecycle. Terminal absorption matches Basel's expectation that settlement events are facts about the past.
- **The Joint Commission, *Provision of Care, Treatment, and Services*** — bed-management and capacity coordination require resource encumbrance to be auditable and time-bounded; Invariant 7 is the structural correlate.
- **IATA Resolution 830a and related ticketing-time-limit rules** — airline fare-lock and seat-hold semantics formalize the window contract this atom abstracts; the atom is vocabulary-neutral, IATA is one instantiation.
- **PCI DSS (Payment Card Industry Data Security Standard) Requirement 10 (logging and monitoring)** — for commitments touching cardholder data, every transition must be logged. Composes with [Event Log](./event-log.md) (Non-goal 4).
- **GDPR (General Data Protection Regulation — the European Union's data-protection law) Article 30 (records of processing activities)** — a commitment record carrying personal data is itself a processing activity; [Requester], [Placement Instant], [Expiry Instant] and the terminal instant supply the data points Art. 30 expects. What counts as a processing purpose is host policy (Non-goal 18).
- **Sarbanes-Oxley section 404 (internal control over financial reporting)** — where a confirmed commitment is material to reporting, the controls around the held-to-confirmed transition are section 404-scope. Composes with [Event Log](./event-log.md) for the evidence an attestation requires.

For commitments touching protected health information, the audit-controls requirement of HIPAA (the US Health Insurance Portability and Accountability Act), 45 CFR (the US Code of Federal Regulations) section 164.312(b), applies to the composing [Event Log](./event-log.md) instance rather than to the commitment record; the same separation applies to GDPR Art. 30 where the log carries the processing history.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture, and the discipline of composing capacity, idempotency, audit and reversal as separate concepts.
- **Eiffel's design-by-contract** — preconditions on each action; named rejection reasons.
- **Linear temporal logic** — terminal absorption, single-resolution and the honored window as temporal properties.
- **Two-phase commit and reservation protocols** — the prepare/commit shape this atom abstracts; here the prepare phase is visible business state rather than an implementation detail hidden under transactional semantics.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — provisional-commitment.tla + 2 twins, 2026-06-04
last gate: 2026-10-21 — Final Critique 5, the council's first round on the page and the first on its Store-contract rewrite (bb2ab31) and the refusal-order sweep (c2f4e9a), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS MiniMax M3.1 Flash, Linus GLM-5.3 Flash), each handed only the round's reading set, three passes on one text (frozen at 4ead2cd); the round rests on three counted passes — foundational count 3 after triage (8 reports: 5 standing, merged into 3; 3 sent down; 0 rejected), all Kind A: a commitment count that could never fall broke at the first purge by the Retention Window the page composes, failing two checks; a refused resolving action was obliged to leave the commitment in held where the not-held refusal answers on a terminal commitment and the not-known refusal on none; and a re-hold was obliged to produce a commitment where a refused [Place Hold] records none; 20 refining reports, 3 rhetorical reports; not clean; every foundational finding cured in place; 2026-06-18 — Final Critique 4, fresh reader — clean

open:
- 2026-10-21-a · refining · Term seam; Capability requirement 1, 2; Operation 5 · the host injects the registry's availability verdict at the seam (Term seam), yet no Capability requirement names its supply, as Capability requirement 1 and 2 name now's and the id material's → name the deployment's supply of the verdict beside them
- 2026-10-21-b · refining · Capability requirement 3 through 5, 10, 11 · the registry's critical section and its return on a releasing action are bound, but not whether its own record of availability follows the commitment records' commit, so a registry writing that record outside the database transaction keeps a resource unavailable after a [Place Hold] the database refused, or makes one available on a [Release] the database refused while the commitment stands held → say whether the registry's availability follows the commit
- 2026-10-21-c · refining · Capability requirement 9 · the deployment canonicalizes an opaque reference by a form the page never names, over references it never lists, so two deployments resolve one spelling two ways while each agrees with itself → name the form the deployment declares and the references it covers
- 2026-10-21-d · refining · Term duration bounds; Operation 4 · the bounds are the implementation's admitted range, an owner Term actors does not name, and no Capability requirement has the deployment declare them → name who declares the bounds
- 2026-10-21-e · refining · Capability requirement 8, 12; Term reclamation lag · the reclamation window is declared with no anchor, so whether a deployment meets Capability requirement 12 cannot be read from its declaration, while Term reclamation lag runs from the expiry instant → anchor the reclamation window at the expiry instant
- 2026-10-21-f · refining · Intent; Examples; Release and Expire entries · the Intent, the Examples' closing line and the Release and Expire term entries credit the atom's actions with returning the resource, which Capability requirement 10 gives the registry (the 2026-09-13 entry) → say that the registry returns the resource on a releasing action
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/provisional-commitment.md`; the rounds and the migration that got it here are in [its history](./provisional-commitment.hist.md).

- **2026-09-13 — The resource return is the registry's obligation, not the atom's.** *Chose:* Capability requirement 10 and Capability requirement 11. *Over:* an `Operation` obliging the atom to return the resource, which a draft of this migration carried. *Because:* the atom cannot see availability (Non-goal 11) and External check 1's own WHY says so, which made the rule either false or unfalsifiable — a MUST whose subject cannot evaluate it is decoration. The asymmetry was the tell: the negative half (*an admitted confirm MUST NOT return it*) was specifiable and the positive half was not.
- **2026-09-13 — Single-resolution is stated as at-most-one, and the at-least-one half is a non-goal.** *Chose:* `Invariant 2.1` and `Invariant 2.2` alone, with `Non-goal 25` naming the limit and `Capability requirement 12` where a deployment may close it. *Over:* a third rule reading *EXACTLY ONE resolving action MUST commit*. *Because:* its marginal content over the other two was liveness, which an atom that licenses lazy expiry cannot deliver — and the model says the same: `INVARIANT Safety` with no temporal property, and `Inv_SingleResolution` checking only that a written resolution matches the state. The spec claimed *exactly*; the model checked *at most*. GRACE's `MUST` has no temporal scope to tell them apart, which is now a docket row.
- **2026-06-23 — Expiry stays a stored terminal reached by an explicit expire event; the derived-expiry refactor is withdrawn for this atom.** *Chose:* stored `Expired` with lapse instant, the window-not-elapsed rejection and confirm's window-elapsed guard restored. *Over:* the corpus-wide derive-expiry-at-read-time move applied two days earlier. *Because:* this atom's lapse has a side effect — expire releases the resource, and in a pool-backed composition returns a capacity slot — which Reserve from Pool and Idempotent Reservation call and map; derived expiry is for side-effect-free lapses only.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the commitment store supplied under Execution Contract Store 1 through 4 (Capability requirement 15), and the nine rules that restated them tombstoned to their owner — Operation 27, a resolving action's state change and recorded instant in one transition, Invariant 10.3, no partial commitment on storage-failure, and Atomic writes 1, 3 and 4, a transition committed whole inside the implementation's transactional boundary and no repair of a dangling one, to Store 1; Atomic writes 2, an uncommitted transition discarded whole, to Store 1 and Store 3; Capability requirement 6, a write acknowledged only once it commits, to Store 3; Concurrency 1, the state check and the state change of a resolving action as one operation, to Store 1 and Store 2; Concurrency 2, the losing resolving action answering not-held from what the winner committed, to Store 2; rules 162 to 154. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The registry's critical section over the availability read and the hold write stays the registry's (Capability requirement 3 through 5, Concurrency 3): the registry is the deployment's, outside the atom and its store, and its verdict reaches the transition at the seam, so no Store rule reaches it. A refused action leaving the commitment as the call found it stays the atom's own (Operation 30 through 32), as do the id and properties that never change (Identity 4, Invariant 5.1) and the atom's no-removal rules (State 11, Invariant 10.1, Invariant 10.2). The window reading is taken against the expiry instant each commitment carries, and ordering one commitment's transitions is the composing Event Log's (Non-goal 26), so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the page's order — [Place Hold] invalid-request ahead of resource-unavailable; a resolving action not-known ahead of not-held, and not-held ahead of a window rejection; storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 15, Execution Contract Refusal 1); the pairs that only stated it deleted to Refusal 1: Operation 6 (resource-unavailable only once every well-formedness check passes), Operation 16 (not-held only for an id naming a commitment), Operation 20 (a window rejection only on a held commitment) and Operation 29 (storage-failure behind every precondition), with Term well-formedness check, which only Operation 6 read; rules 154 to 150. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-21 — A composed retention may purge what the atom never removes; a refusal leaves what it found; a refused re-hold records nothing.** *Chose:* Invariant 10.2 deleted to Invariant 10.1 and Execution Contract Database 4, so the atom never removes a commitment and a composed Retention Window destroys a terminal one only as its own page says (Composition note 5); Check 6.1 and Check 6.2, which cannot tell a purge from a removal from the commitment records alone, moved to External check 7, which reads the Retention Window's purge records beside two reads; Operation 32 deleted to Operation 30, so a refused resolving action leaves the commitment as the call found it, terminal or held, and a call naming no commitment leaves nothing; and Invariant 5.2 deleted to Operation 8, with Term re-hold, which only it read. *Over:* a commitment count that may never fall beside the retention the page sends to Retention Window; a refused resolving action left in held where the not-held refusal answers on a terminal commitment and the not-known refusal on none; and a re-hold obliged to produce a commitment where a refused [Place Hold] records none. *Because:* Final Critique 5 found each a reachable state that breaks a rule of the page or fails one of its checks, and the page's earlier text held each cure: Final Critique 4 kept the record indefinitely from the atom's perspective with retention, archival and purge left to composing patterns, left the commitment in Held only where the store write failed, and made a re-hold a new commitment with a new id. What each action answers on every call is unchanged.

- **2026-10-22 — An admitted call, a composed purge and the wiring are the Execution Contract's.** *Chose:* the four admitted terms (place hold, confirm, release, expire) citing Execution Contract Read 4 for what an action admits, in place of the commit clause this page's fifth Final Critique wrote into each; External check 7, a composing Retention Window's purge records read beside the commitment records, deleted to Execution Contract Database 6, with the tombstones of Check 6.1 and Check 6.2, which named it, now naming the contract; External check 6, the composing patterns read from the deployment's own wiring, deleted to Execution Contract Conformance 9; the three labels cited on Capability requirement 15; rules 146 to 144. *Over:* the page stating for itself which calls its effect rules reach, that a purge another specification declares is answered outside the commitment records, and that the wiring is an external check. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect, the composed erasure and the wiring declaration among them; this page's fifth Final Critique had made the first two cures one specification at a time. What each action does and answers is unchanged.

NOTE: End of Provisional Commitment.
