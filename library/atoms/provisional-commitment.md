---
title: Provisional Commitment
id: 54
audience: common
---

# Provisional Commitment

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Provisional Commitment is the business act of holding something for someone while they decide — a card authorization, a hospital bed, an item in a cart, a hotel room, an airline seat. A hold is placed, stays open for a fixed window, and resolves at most once, into one of three recorded end states: confirmed, released, or expired. The window is a promise in both directions: the resource stays reserved until the hold resolves, a confirmed hold keeping it, and the requester must decide before the window closes.

Resolving at most once is the guarantee. A resolving call against an already-settled hold is refused. A confirm or release at or past the window's close is refused. An expire before the window closes is refused. Each hold carries a permanent commitment id; its resource, requester and window are fixed at placement and never change. A settled hold is therefore an unambiguous and provable record of what happened.

Retry safety, the full transition history, and pool-wide capacity limits are deliberately outside the atom — each is a separate pattern that composes with it.

*Also known as: a hold, a reservation, a tentative reservation, a two-phase reservation.*

A requester needs a resource whose allocation is not yet certain. The system holds it for a known period, during which the requester confirms (taking it into a binding allocation) or releases (so the registry returns it to availability). If neither happens before the period elapses, the hold awaits an [Expire], which the deployment fires on a cadence or when it next reads the commitment and which moves the hold to its terminal [Expired] state, so the registry returns the resource.

Expiry is a written transition rather than a status inferred at read time because the lapse has a side effect — on it the registry returns the resource, and in a pool-backed composition the capacity pattern returns a capacity slot. A side-effect-free lapse could be derived; this one releases something and so needs a write.

The shape is constant across regulated industries: credit-limit holds pending settlement, bed assignments pending admission, inventory reservations pending checkout, room bookings pending check-in, seat holds pending purchase. A resource is encumbered for a bounded window, the encumbrance resolves, and the record of it is itself a regulated asset.

This is a freestanding atom in the EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) sense — its own state, its own five actions, its own operational principles. It does not implement idempotency under retry, the full audit trail of every observation, or aggregate capacity constraints over a pool. Each is a separate composable atom; see Composition notes.

## What it keeps

### The commitments

```
Identity 1: The atom MUST identify a commitment by the commitment id.
Identity 2: The atom MUST assign the commitment id from the id material the seam supplies.
Identity 4: The atom MUST NOT change a commitment's commitment id.
Identity 5: Two commitments MUST NOT share a commitment id.
Identity 6: The atom MUST NOT identify a commitment by a property.
Identity 7: An admitted place hold MUST record EXACTLY ONE commitment.
Identity 8: The atom MUST compare a reference byte for byte.
Identity 9: The atom MUST NOT normalize a reference.
Identity 10: The atom MUST NOT confirm that a resource names a known registry entry.
Identity 11: The atom MUST NOT confirm that a requester names a known actor.
Identity 12: The atom MUST NOT hold the resource's content.
```

Term commitment: the record this atom holds — one resource held for one requester for a bounded window, then resolved to exactly one terminal state.

Term property: resource | requester | placement instant | expiry instant — what a commitment carries that is not the commitment's identity.

Term reference: commitment id, resource OR requester — every opaque reference this atom records, canonicalized at the seam before it is compared or recorded (Execution Contract Logic confinement 13).

```
State 1: EVERY commitment MUST carry commitment id, resource, requester, placement instant, expiry instant and a state.
State 2: EVERY confirmed commitment MUST carry confirmation instant.
State 3: EVERY released commitment MUST carry release instant.
State 4: EVERY expired commitment MUST carry lapse instant.
State 5: A held commitment MUST NOT carry a terminal instant.
State 6: The atom MUST NOT record the duration under the duration's own name.
State 7: The atom MUST NOT hold a state for a resource carrying no commitment.
State 8: The atom MUST NOT offer a surface that reverses a confirm.
State 9: The atom MUST NOT offer a reactivate surface.
State 10: The atom MUST NOT offer a window extension surface.
State 11: The atom MUST NOT offer a commitment removal surface.
```

#### Commitment

The record this atom defines: one resource held for one requester for a bounded window, resolved to exactly one terminal state. Carries [Commitment Id], [Resource], [Requester], [Placement Instant], [Expiry Instant], a state, and the terminal instant of the transition that settled it.

Kind: Type
Projection: state

#### Commitment Id

The opaque, immutable identity of a [Commitment], assigned on [Place Hold] from the id material the seam supplies and never shared with a second commitment. The [Resource], [Requester] and window are properties, not identity.

Kind:       Field
Field of:   Commitment
Projection: commitment_id

#### Resource

The reference naming what is held. Opaque to the atom — the registry owns what a resource is and what availability means. Set on [Place Hold], immutable thereafter.

Kind:       Field
Field of:   Commitment
Projection: resource

#### Requester

The reference naming who the hold is for. Set on [Place Hold], immutable thereafter. The atom names the requester and does not bind the call to a verifiable actor — that is a composing attestation pattern's.

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

The instant the [Commitment] expired, stamped from [Now] on [Expire]. Present only in [Expired]; immutable once set.

Kind:       Field
Field of:   Commitment
Projection: expired_at

#### Held

The one non-terminal state: the resource is encumbered for the requester and no resolution has occurred. Reads open or lapsed against [Now].

Kind:      Member
Member of: the commitment state
Role:      Outcome

#### Confirmed

The terminal state reached when the requester confirmed while the commitment's window reading was open at the call's now — the resource is taken into a binding allocation. Absorbing.

Kind:      Member
Member of: the commitment state
Role:      Outcome

#### Released

The terminal state reached when the commitment was released while the commitment's window reading was open at the call's now — the registry returns the resource to availability (Capability requirement 10). Absorbing.

Kind:      Member
Member of: the commitment state
Role:      Outcome

#### Expired

The terminal state reached when the window lapsed with the commitment still [Held] and an [Expire] then fired, stamping [Lapse Instant] — the resource returns to availability. Absorbing.

Kind:      Member
Member of: the commitment state
Role:      Outcome

Term commitment id: the opaque value naming one commitment — a [Commitment Id]; assigned from the id material the seam supplies and never reused.

## What people do

### Every action

```
Operation 14: IF the commitment id names no commitment THEN a resolving action MUST answer not-known.
Operation 15: IF the commitment's state IS IN the terminal states THEN a resolving action MUST answer not-held.
Operation 30: A refused action MUST leave the commitment as the call found the commitment.
Operation 33: A resolving action MUST NOT accept a resource.
Operation 34: A resolving action MUST NOT accept a requester.
Operation 35: A resolving action MUST NOT accept a duration.
Operation 43: [Place Hold], [Confirm], [Release] AND [Expire] MUST append one commitment events record through the atom's journal need for EVERY admitted call.
```

NOTE: watch the state a refusal leaves (Operation 30).

Term resolving action: [Confirm] | [Release] | [Expire] — every action taking a held commitment to a terminal state.

Term window bound: (placement instant + duration) — the value an admitted place hold records as expiry instant (Execution Contract Logic confinement 9).

Term window reading: open | lapsed — how a held commitment's window reads against now.

Term open: the window reading of a held commitment whose expiry instant exceeds now.

Term window rejection: window-elapsed | window-not-elapsed.

Term terminal instant: confirmation instant | release instant | lapse instant.

Term admitted place hold: a [Place Hold] call the action admits (Execution Contract Read 4).

Term admitted release: a [Release] call the action admits (Execution Contract Read 4).

Term admitted expire: a [Expire] call the action admits (Execution Contract Read 4).

Term admitted resolving action: an admitted confirm, an admitted release OR an admitted expire.

Term reclamation lag: the span between a commitment's expiry instant and the admitted expire that settles the commitment.

NOTE: watch the reconciliation's own run (Term reclamation sum).

#### Not Known

The refusal a resolving action returns when the supplied [Commitment Id] names no commitment. A lookup miss, distinct from a state or window rejection.

Kind:       Member
Member of:  the resolving-action rejection
Role:       Outcome
Projection: not-known

#### Not Held

The refusal a resolving action returns when the commitment already stands in a terminal state — distinct from [Not Known], which says the commitment id resolved to nothing at all. The single-resolution guard; nothing is written.

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

#### Storage Failure

The refusal any action returns when the database refuses the write, or the journal refuses the append of Operation 43 (Execution Contract Database 1), after every precondition passes. No commitment is recorded, or the commitment remains [Held]. Definitive, which rests on Capability requirement 15.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Place Hold

#### Place Hold

The behavior that records a new [Commitment] — assigning a fresh [Commitment Id] from the id material the seam supplies, setting [Resource], [Requester], [Placement Instant] and [Expiry Instant], standing the record in [Held], and answering the [Commitment Id]. Rejected [Invalid Request], [Registry Unavailable], [Resource Unavailable] or [Storage Failure].

Kind: Operation

```
place_hold(resource, requester, duration)
  answers commitment_id
  refuses invalid-request | registry-unavailable | resource-unavailable | storage-failure
```

```
Operation 1: IF resource EQUALS blank THEN [Place Hold] MUST answer invalid-request.
Operation 2: IF requester EQUALS blank THEN [Place Hold] MUST answer invalid-request.
Operation 3: IF duration EQUALS blank THEN [Place Hold] MUST answer invalid-request.
Operation 4: IF the duration IS NOT IN the duration bounds THEN [Place Hold] MUST answer invalid-request.
Operation 5: IF the registry refuses the resource THEN [Place Hold] MUST answer resource-unavailable.
Operation 44: IF the availability verdict EQUALS blank THEN [Place Hold] MUST answer registry-unavailable.
Operation 7: [Place Hold] MUST NOT answer not-known.
Operation 8: An admitted place hold MUST assign a fresh commitment id.
Operation 9: An admitted place hold MUST record resource and requester.
Operation 10: An admitted place hold MUST record now as placement instant.
Operation 11: An admitted place hold MUST record the window bound as expiry instant.
Operation 12: An admitted place hold MUST stand the commitment in held.
Operation 13: An admitted place hold MUST answer the commitment id.
Operation 31: A refused [Place Hold] MUST NOT record a commitment.
```

#### Duration

The window length supplied to [Place Hold], a whole number of seconds. It sizes the window and is not stored under its own name; [Placement Instant] and [Expiry Instant] are what persist. Must be in the duration bounds.

Kind:         Parameter
Parameter of: Place Hold
Projection:   duration

#### Invalid Request

The refusal [Place Hold] returns when [Resource], [Requester] or [Duration] is absent, [Duration] is not a whole number of seconds (Execution Contract Input 1), [Duration] is not in the duration bounds, or a string input exceeds the string cap (Execution Contract Input 2). No commitment is recorded.

Kind:       Member
Member of:  the Place Hold rejection
Role:       Outcome
Projection: invalid-request

#### Registry Unavailable

The refusal [Place Hold] returns when the host could not read the registry's availability verdict at the seam (Operation 44), so no verdict was read; the host's failure to read, which the registry never gave. Distinct from [Resource Unavailable], which the registry gives once read: the place hold may be retried. No commitment is recorded. The app action that makes the call answers it unchanged (Execution Contract Constituent failure 2).

Kind:       Member
Member of:  the Place Hold rejection
Role:       Outcome
Projection: registry-unavailable

#### Resource Unavailable

The refusal [Place Hold] returns when the registry refuses the resource. The loser of a concurrent place-hold race for one resource receives this. No commitment is recorded.

Kind:       Member
Member of:  the Place Hold rejection
Role:       Outcome
Projection: resource-unavailable

### Confirm

#### Confirm

The resolving behavior that takes a [Held] [Commitment] into a binding allocation, standing it in [Confirmed] and stamping [Confirmation Instant]. Legal only while the commitment reads open; rejected [Window Elapsed] once it reads lapsed, and [Not Held] on an already-terminal commitment.

Kind: Operation

```
confirm(commitment_id)
  answers ok
  refuses not-known | not-held | window-elapsed | storage-failure
```

```
Operation 17: IF the commitment reads lapsed THEN [Confirm] MUST answer window-elapsed.
Operation 21: An admitted confirm MUST stand the commitment in confirmed.
Operation 24: An admitted confirm MUST record now as confirmation instant.
```

### Release

#### Release

The resolving behavior that releases a [Held] [Commitment] before the window closes, standing it in [Released] and stamping [Release Instant]; on it the registry returns the resource to availability. Legal only while the commitment reads open; rejected [Window Elapsed] once it reads lapsed, and [Not Held] on an already-terminal commitment.

Kind: Operation

```
release(commitment_id)
  answers ok
  refuses not-known | not-held | window-elapsed | storage-failure
```

```
Operation 18: IF the commitment reads lapsed THEN [Release] MUST answer window-elapsed.
Operation 22: An admitted release MUST stand the commitment in released.
Operation 25: An admitted release MUST record now as release instant.
```

### Expire

#### Expire

The resolving behavior — the side-effecting lapse — that moves a lapsed [Held] [Commitment] to [Expired]; on it the registry returns the resource to availability, and in a pool-backed composition the capacity pattern returns a capacity slot. Legal only while the commitment reads lapsed; rejected [Window Not Elapsed] while it reads open. Fired by the deployment on a cadence or when it next reads the commitment; the atom does not decide which (Non-goal 13) and does not guarantee that it fires (Non-goal 25).

Kind: Operation

```
expire(commitment_id)
  answers ok
  refuses not-known | not-held | window-not-elapsed | storage-failure
```

```
Operation 19: IF the commitment reads open THEN [Expire] MUST answer window-not-elapsed.
Operation 23: An admitted expire MUST stand the commitment in expired.
Operation 26: An admitted expire MUST record now as lapse instant.
```

#### Window Not Elapsed

The refusal [Expire] returns when the commitment reads open. The symmetric counterpart to [Window Elapsed]; nothing is written, and the atom never expires a commitment before its window closes.

Kind:       Member
Member of:  the Expire rejection
Role:       Outcome
Projection: window-not-elapsed

### Read

#### Read

The read-only query answering every commitment the database holds, held and terminal, each with its stored fields. It changes nothing and refuses nothing; where the database cannot be read it answers state-unavailable, the family answer of Execution Contract Read 1, which is no refusal.

Kind: Operation

```
read()
  answers every commitment
```

```
Operation 38: [Read] MUST answer EVERY commitment, held AND terminal.
Operation 39: [Read] MUST answer a commitment's stored fields.
Operation 40: [Read] MUST NOT write.
Operation 41: [Read] MUST NOT refuse a call.
```

## What is and what should never be (Invariants)

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
  ```
- **Invariant 5 — Property immutability.**
  ```
  Invariant 5.1: An admitted resolving action MUST NOT change a property.
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
  ```
- **Invariant 10 — Commitment record durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove a commitment from the database.
  ```

A [Place Hold] is undone by a [Release], which returns the resource and stands the commitment in released. A [Confirm], a [Release] and an [Expire] are not undone by this atom: a terminal state is absorbing (Invariant 3.1), so a new [Place Hold] records afresh (Execution Contract Undo 4). The lapse instant follows the placement instant too, entailed by Invariant 7.2 with Invariant 6.1.

Term degenerate window: a commitment whose expiry instant does not exceed the commitment's placement instant.

Term late resolution: a commitment whose state EQUALS confirmed and whose expiry instant does not exceed the commitment's confirmation instant, OR one whose state EQUALS released and whose expiry instant does not exceed the commitment's release instant.

Term premature expiry: a commitment whose state EQUALS expired and whose lapse instant precedes the commitment's expiry instant.

Term capacity decision: a composing capacity constraint pattern's reading of the pool's capacity rule for one place hold.

---

## When something happens

### Concurrency

```
Concurrency 3: A losing [Place Hold] racing on one resource MUST answer resource-unavailable.
```

## While something is so

### String policy

```
String 1: The atom MUST compare a string input byte for byte.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a string input carrying only white space as blank.
String 6: The atom MUST read an absent string input as blank.
```

Term string input: resource, requester OR commitment id — every caller-supplied string this atom accepts; a commitment id over the string cap names no commitment.

---

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 3 and Execution Contract Logic confinement 7.
Capability requirement 2: The deployment MUST supply the id material at the seam.
Capability requirement 16: The deployment MUST supply the registry's availability verdict at the seam.
Capability requirement 29: The registry MUST NOT return the resource to availability BEFORE the database has written the releasing action's terminal state.
Capability requirement 7: A deployment firing [Expire] on a cadence MUST declare the expire cadence.
Capability requirement 8: A deployment firing [Expire] on a cadence MUST declare the reclamation window the expire cadence falls inside.
Capability requirement 10: The registry MUST return the resource to availability on a releasing action.
Capability requirement 11: The registry MUST NOT return the resource to availability on an admitted confirm.
Capability requirement 17: The registry MUST refuse a resource a held commitment carries.
Capability requirement 20: The registry MUST NOT remove the resource from availability on a refused [Place Hold].
Capability requirement 12: IF no [Expire] call answering storage-failure EXISTS for a lapsed commitment THEN a deployment firing [Expire] on a cadence MUST resolve the lapsed commitment WITHIN the reclamation window.
Capability requirement 33: The deployment MUST supply id material that is not blank and whose length DOES NOT EXCEED the string cap (Execution Contract Input 2).
Capability requirement 30: IF an [Expire] call answered storage-failure for a lapsed commitment THEN a deployment firing [Expire] on a cadence MUST call [Expire] on the lapsed commitment at the expire cadence's next firing.
Capability requirement 15: The deployment MUST supply the commitment records PER Execution Contract Database 1 through 7, Execution Contract Read 4, Execution Contract Refusal 1 and Execution Contract Conformance 9.
Capability requirement 21: The deployment MAY declare the string cap PER Execution Contract Input 2.
Capability requirement 22: The deployment MAY declare the duration bounds PER Execution Contract Input 2.
Capability requirement 27: The duration bounds a deployment declares MUST admit only durations exceeding zero.
Capability requirement 23: The deployment MUST supply id material naming no commitment of the database instance in the state the call's hold write commits against.
Capability requirement 24: A deployment firing [Expire] on a cadence MUST declare the expire run bound.
Capability requirement 25: IF the reclamation sum EXCEEDS the reclamation window THEN a deployment MUST NOT declare the reclamation window.
Capability requirement 26: A deployment firing [Expire] on a cadence MUST declare the restart delay bound.
```

Term hold write: the database write by which a [Place Hold] records a commitment.

#### Now

The wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it — never read inside the transition and never supplied by the business caller. Consumed twice per call: by the window reading and by the transition's stamp.

Kind:         Parameter
Parameter of: Place Hold, Confirm, Release and Expire
Projection:   now

Term id material: the value the seam supplies for [Place Hold] to assign as the commitment id (Capability requirement 2, Capability requirement 23).

Term registry: the deployment's owner of what a resource is and what availability means; outside this atom (Non-goal 11).

Term availability: whether the registry accepts a resource for a hold — the registry's own standing of the resource, which the atom never defines (Non-goal 11).

Term availability verdict: the registry's answer on one resource, accepts OR refuses, or blank where the host could not read the registry, which the host reads and injects at the seam (Capability requirement 16).

Term database instance: one named database a call is routed to; commitment id uniqueness ranges over one instance.

Term seam: the atom's I/O (input and output) boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the id material and the registry's availability verdict here.

Term transition: the atom's evaluation of one call against the commitment records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term duration: the window length a [Place Hold] call supplies — a whole number of seconds; consumed to compute the window bound, never stored under its own name (State 6).

Term duration bounds: the set of durations the deployment admits; where a deployment declares none, every duration exceeding zero IS IN the duration bounds (Capability requirement 22).

Term lapsed: the window reading of a held commitment whose expiry instant does not exceed now; the boundary instant — expiry instant equal to now — reads lapsed.

Term terminal state: confirmed | released | expired.

Term admitted confirm: a [Confirm] call the action admits (Execution Contract Read 4).

Term releasing action: an admitted release OR an admitted expire.

Term reclamation window: the span a deployment firing [Expire] on a cadence declares as the bound on the reclamation lag of a commitment no [Expire] call answering storage-failure EXISTS for (Capability requirement 8, Capability requirement 12).

Term expire cadence: the span between two firings of [Expire] a deployment firing [Expire] on a cadence declares (Capability requirement 7).

Term expire run bound: the span a deployment firing [Expire] on a cadence declares as the bound on one firing's run, from its start to its last write landing (Capability requirement 24).

Term restart delay bound: the span a deployment firing [Expire] on a cadence declares as the bound on how long after its cadence a charged firing starts (Capability requirement 26, Execution Contract Scheduled leg 1).

Term reclamation sum: (the expire cadence + (the expire run bound + the restart delay bound)).

Term string cap: the bound on a string input's length in Unicode code points; 256 code points where a deployment declares none.

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice.

Term need key: key actor id; pairs commitments.

Term need journal: records commitment events; calls append; arms event_id.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key commitment id; carried by commitments; calls Read.

## Left to others

```
Non-goal 1: The atom MUST NOT answer a repeated [Place Hold] with one commitment.
Deleted: Non-goal 2. Non-goal 1 owns it: the atom answers a repeated [Place Hold] with two commitments, and which pattern makes a hold idempotent is the app's choice.
Non-goal 3: The atom MUST NOT record a transition history.
Deleted: Non-goal 4. Non-goal 3 owns it: the atom records no transition history; the journal the atom appends to holds it (Operation 43).
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
Deleted: Non-goal 15. Non-goal 14 owns it: the atom binds no requester to an actor, and which pattern attests an actor is the app's choice.
Non-goal 16: The atom MUST NOT decide who may call an action.
Deleted: Non-goal 17. Non-goal 16 owns it: the atom decides no caller's authority; the app's permission does.
Non-goal 18: The atom MUST NOT decide what a confirmation means to the host.
Non-goal 19: The atom MUST NOT bound a commitment's retention.
Deleted: Non-goal 20. Non-goal 19 owns it: the atom bounds no retention, and which pattern does is the app's choice.
Non-goal 21: The atom MUST NOT pause a hold window.
Non-goal 22: The atom MUST NOT offer a transaction of more than one commitment.
Non-goal 23: The atom MUST NOT surface a rejection to an audit trail.
Non-goal 24: The atom MUST NOT hold a part of a resource.
Non-goal 25: The atom MUST NOT guarantee that a lapsed commitment resolves.
Non-goal 26: A deployment needing two racing transitions ordered MUST read the sequence number of the journal the atom appends to.
Non-goal 27: The atom MUST NOT remove a requester's personal data.
Deleted: Non-goal 28. Non-goal 27 owns it: the atom removes no personal data, and which pattern records a destruction is the app's choice.
Non-goal 29: The atom MUST NOT hold exclusive standing over a resource for the span of a call.
Deleted: Non-goal 30. Non-goal 29 owns it: the atom holds no exclusive standing over a resource, and which pattern makes the availability read and the hold write one critical section is the app's choice.
```

NOTE: the owners — an idempotency pattern (Non-goal 1, Non-goal 2); a capacity constraint pattern (Non-goal 5, Non-goal 6); a reversal pattern *(forthcoming)* (Non-goal 9, Non-goal 10); an erasure-record pattern (Non-goal 27, Non-goal 28); a lease pattern (Non-goal 29, Non-goal 30); the registry (Non-goal 11, Non-goal 12, External check 1); the deployment (Non-goal 13, Capability requirement 7; Non-goal 25 for a lapse awaiting the deployment's next read of the commitment OR met by an [Expire] call answering storage-failure, and Capability requirement 12 and Capability requirement 30 for a cadence's firings); a composition of two tiers of commitment (Non-goal 24).

---

```
Composition note 1: A composing pattern MUST map an idempotency token to the commitment id an admitted place hold answered.
Composition note 2: A composing pattern MUST answer a repeated token with the mapped commitment id.
Deleted: Composition note 3. Operation 43 owns it: the atom appends one commitment events record through its own journal need for every admitted call.
Composition note 4: A composing pattern MUST own the record of a refused action.
Composition note 5: A composing pattern MUST place a commitment under retention ONLY IF the commitment's state IS IN the terminal states.
Composition note 6: A composing capacity constraint pattern MUST read the pool's capacity rule PER place hold.
Composition note 7: A composing capacity constraint pattern MUST NOT call [Place Hold] BEFORE the capacity decision.
Composition note 8: A composing capacity constraint pattern MUST return the pool slot on a releasing action.
Composition note 9: A composing reversal pattern MUST produce a new commitment.
Composition note 10: A composing reversal pattern MUST NOT change the offset commitment.
Composition note 11: A composing pattern MUST own the attestation binding a requester to an actor.
```

---

Term composing pattern: a pattern an app composes beside this atom — one that makes a hold idempotent, bounds retention, attests an actor or decides who may call, a lease pattern, a capacity constraint pattern, a reversal pattern.

## Example

The same atom, five regulated domains, one mechanic.

### Banking — credit-limit hold

`place_hold(card, cardholder, 604800)` → `auth_c41`; available credit drops by $250. The merchant captures within the window — `confirm(auth_c41)` — and the charge settles; or voids it — `release(auth_c41)` — and credit restores. If neither, a capture after the window closes is refused window-elapsed, and the scheme's settlement sweep fires `expire(auth_c41)` once the seven days have passed, after which a capture is refused not-held. Each transition feeds liquidity reporting aligned with the BCBS (Basel Committee on Banking Supervision).

### Healthcare — bed assignment

`place_hold(bed, patient, 7200)` → `bed_h17`, placed 14:00, expiring 16:00. The patient arrives at 14:45 — `confirm(bed_h17)`; or is discharged from the emergency department — `release(bed_h17)`. If neither by 16:00 the bed-management sweep fires `expire(bed_h17)` and the bed returns to the pool. The Joint-Commission-aligned care-coordination audit reads the commitment record directly.

### Retail — inventory reservation

`place_hold(sku, shopper, 900)` → `inv_r93`, placed 19:14. The shopper checks out at 19:18 — `confirm(inv_r93)`; or empties the cart — `release(inv_r93)`. An abandoned cart is swept after 19:29 — `expire(inv_r93)` — and the unit returns to stock.

### Hospitality — room booking

`place_hold(room, guest, 172800)` → `rm_b58`, expiring at the property's cancellation cutoff, two days on. Check-in confirms; cancellation by the cutoff releases; neither leaves the sweep to expire it, which is the transition the property's no-show fee policy — a separate composing pattern — triggers off.

### Airline — seat hold

`place_hold(seat, passenger, 900)` → `seat_a22`, the carrier's fare-lock per IATA (International Air Transport Association) practice. Payment confirms; backing out releases; abandonment expires. The attached fare quote is invalidated whenever the hold leaves availability, which a composing fare-quote pattern *(forthcoming)* observes from the terminal state.

What differs across the five: resource semantics, window length, the regulatory framing of the trail, and which patterns compose. What does not differ: an undecided hold ends in a recorded expire, on which the registry returns the resource.

### Regulated adversarial scenarios

- **Regulator audit.** *Show me every hold confirmed or released after its declared window.* The query is Check 3.1 and returns the empty set by construction — Invariant 7.1 makes a late resolution unrecordable rather than merely unlikely.
- **Data subject request.** Erasure against the personal data behind requester. The atom alone cannot satisfy it while keeping the trail; a composing Shred pattern *(forthcoming)* redacts the reference and leaves commitment id, placement instant, expiry instant, the state and the terminal instant intact, so the lifecycle stays auditable and the personal data does not persist, and an erasure-record pattern keeps the permanent record that the destruction happened; a check over this atom's records does not answer the redaction (Execution Contract Database 6; Non-goal 27, Non-goal 28).
- **Breach investigation.** The universe of resources committed between 02:00 and 04:00 UTC (Coordinated Universal Time). Every commitment carries placement instant, so the answer is a filter over the database with no log replay behind it; the terminal state and its instant then say which holds resolved and which lapsed. [Read] answers every commitment the database holds (Operation 38), and ordering *within* the window needs the commitment events the atom appends through its journal need (External check 2).

---

## Source

- **ISO (International Organization for Standardization) 9001:2015 clause 8.5.2 (Identification and traceability)** — the minimum anchor. A resource under provisional commitment must be identifiable and traceable through every transition; the identity model and the per-commitment instants satisfy it directly.
- **ISO 9001:2015 clause 8.5.4 (Preservation)** — the resource is preserved in its committed state for the window's length; Capability requirement 17 is the operational form.
- **Basel III liquidity framework (BCBS 238 LCR — the Liquidity Coverage Ratio)** — credit-limit holds and intraday liquidity reservations follow this lifecycle. Terminal absorption matches Basel's expectation that settlement events are facts about the past.
- **The Joint Commission, *Provision of Care, Treatment, and Services*** — bed-management and capacity coordination require resource encumbrance to be auditable and time-bounded; Invariant 7 is the structural correlate.
- **IATA Resolution 830a and related ticketing-time-limit rules** — airline fare-lock and seat-hold semantics formalize the window contract this atom abstracts; the atom is vocabulary-neutral, IATA is one instantiation.
- **PCI DSS (Payment Card Industry Data Security Standard) Requirement 10 (logging and monitoring)** — for commitments touching cardholder data, every transition must be logged: the journal the atom appends to (Operation 43).
- **GDPR (General Data Protection Regulation — the European Union's data-protection law) Article 30 (records of processing activities)** — a commitment record carrying personal data is itself a processing activity; [Requester], [Placement Instant], [Expiry Instant] and the terminal instant supply the data points Art. 30 expects. What counts as a processing purpose is host policy (Non-goal 18).
- **Sarbanes-Oxley section 404 (internal control over financial reporting)** — where a confirmed commitment is material to reporting, the controls around the held-to-confirmed transition are section 404-scope. The journal the atom appends to holds the evidence an attestation requires (Operation 43).

For commitments touching protected health information, the audit-controls requirement of HIPAA (the US Health Insurance Portability and Accountability Act), 45 CFR (the US Code of Federal Regulations) section 164.312(b), applies to the journal the atom appends to rather than to the commitment record; the same separation applies to GDPR Art. 30 where the log carries the processing history.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture, and the discipline of composing capacity, idempotency, audit and reversal as separate concepts.
- **Eiffel's design-by-contract** — preconditions on each action; named rejection reasons.
- **Linear temporal logic** — terminal absorption, single-resolution and the honored window as temporal properties.
- **Two-phase commit and reservation protocols** — the prepare/commit shape this atom abstracts; here the prepare phase is visible business state rather than an implementation detail hidden under transactional semantics.

---

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the commitment records, with their committed versions (Execution Contract Generation acceptance 1). Every check but Check 2.2 and Check 5.1, which compare committed versions of a commitment, is a check of one state (Execution Contract Database 8).

#### Conformance checks

```
Check 1.1: An auditor MUST find a state that IS IN held, confirmed, released, expired on EVERY commitment (Invariant 1.1).
Check 1.2: An auditor MUST find a terminal instant on EVERY commitment whose state IS IN the terminal states (State 2, State 3, State 4).
Check 1.3: An auditor MUST find no terminal instant on a held commitment (State 5).
Check 2.1: An auditor MUST find no commitment carrying two terminal instants (Invariant 2.2).
Check 2.2: An auditor MUST find no commitment leaving a terminal state across two committed versions of the commitment (Invariant 2.1, Invariant 3.1; Execution Contract Generation acceptance 1).
Check 3.1: An auditor MUST find no late resolution in the database (Invariant 7.1).
Check 3.2: An auditor MUST find no premature expiry in the database (Invariant 7.2).
Check 3.3: An auditor MUST find no degenerate window in the database (Invariant 6.1).
Check 3.4: An auditor MUST find EVERY held commitment reading EXACTLY ONE OF open, lapsed against the read-time clock (Invariant 7.3).
Check 4.1: An auditor MUST find no commitment's confirmation instant preceding the commitment's placement instant (Invariant 8.1).
Check 4.2: An auditor MUST find no commitment's release instant preceding the commitment's placement instant (Invariant 8.2).
Check 5.1: An auditor MUST find EVERY commitment's properties unchanged across EVERY committed version of the commitment (Invariant 5.1; Execution Contract Database 6, Execution Contract Generation acceptance 1).
Check 5.2: An auditor MUST find no commitment id on two commitments (Identity 5).
Check 7.1: An auditor MUST find a resource and a requester on EVERY commitment (State 1; Execution Contract Database 6).
Check 7.2: An auditor MUST find a placement instant and an expiry instant on EVERY commitment (State 1).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: A deployment needing the resource of a confirmed commitment returned to availability MUST compose a reversal pattern (Non-goal 10).
External check 2: A deployment needing the transitions of one commitment ordered MUST read the commitment events the atom appends through the atom's journal need (Operation 43).
External check 3: A deployment needing a rejection observed MUST read the composing pattern that records a refused action (Non-goal 23).
External check 4: A deployment needing a requester bound to an actor MUST read the composing attestation pattern (Non-goal 14).
External check 5: A deployment needing the reclamation lag bounded MUST read the declared reclamation window AND find no reclamation lag of a commitment no [Expire] call answering storage-failure EXISTS for that EXCEEDS the reclamation window (Capability requirement 8, Capability requirement 12).
```

---

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the deployment; the host; the registry; the database; the seam; the transition; a composing pattern; a caller; an auditor; a regulator; a data subject; an investigator; a reader; a commitment; a held commitment; a confirmed commitment; a released commitment; an expired commitment; an action; a resolving action; a refused action; a losing [Place Hold]; a rejection; a crash; an opaque reference.

Term records: commitment — one resource held for one requester for a bounded window, carrying commitment id, resource, requester, placement instant, expiry instant, a state and, where set, confirmation instant, release instant or lapse instant.

Term record verbs: identify, assign, generate, change, share, carry, stand, read, answer, record, leave, admit, offer, hold, return, refuse, write, find, resolve, name, compare, normalize, confirm, append, place, produce, map, attest, fall, precede, supply, release, run, declare, compose, remove, bind, decide, define, bound, surface, reach, accept, pause, call, guarantee, trim, case-fold, own.

Term value sets: state = held | confirmed | released | expired. action rejection = storage-failure. resolving-action rejection = not-known | not-held | window-elapsed. Place Hold rejection = invalid-request | registry-unavailable | resource-unavailable. Expire rejection = window-not-elapsed. terminal state = confirmed | released | expired. terminal instant = confirmation instant | release instant | lapse instant. window reading = open | lapsed. window rejection = window-elapsed | window-not-elapsed. property = resource | requester | placement instant | expiry instant.

Term bounds: duration bounds, window bound, reclamation window, string cap, expire run bound, restart delay bound.

Term cadences: expire cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: commitment, commitment id, property, reference, registry, database instance, seam, transition, now, hold write, resolving action, duration bounds, window bound, window reading, open, lapsed, window rejection, terminal state, terminal instant, admitted place hold, admitted confirm, admitted release, admitted expire, admitted resolving action, releasing action, string input, reclamation lag, reclamation window, capacity decision, degenerate window, late resolution, premature expiry, committed version, string cap, duration, id material, availability, availability verdict, expire cadence, expire run bound, restart delay bound, reclamation sum.

Term cited: sequence number: Bonds. The section titled Logic Confinement Principle in `execution-contract.md` — the seam and the transition.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Place Hold]: #place-hold
[Confirm]: #confirm
[Release]: #release
[Expire]: #expire
[Read]: #read
[Commitment]: #commitment
[Commitment Id]: #commitment-id
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
[Registry Unavailable]: #registry-unavailable
[Resource Unavailable]: #resource-unavailable
[Not Known]: #not-known
[Not Held]: #not-held
[Window Elapsed]: #window-elapsed
[Window Not Elapsed]: #window-not-elapsed
[Storage Failure]: #storage-failure

---

## Status

`done — 2026-11-27` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-27
formal: verified — provisional-commitment.tla + 4 twins (2026-06-04); provisional-commitment.als + 13 twins (the static data model, 2026-11-11: Invariant 1.1, 2.2, 6.1, 7.1 through 7.3, 8.1 and 8.2, State 1 through 5 and Identity 5 checked on every commitment record an admitted [Place Hold], [Confirm], [Release] or [Expire] leaves, built from the version its call found; Invariant 7.1, 8.1 and 8.2 a cross-check with the TLA+ model; Invariant 8.1 and 8.2 resting on the deployment's clock never going backward (Execution Contract Logic confinement 7), Invariant 6.1 on Capability requirement 27 and Execution Contract Logic confinement 9, Identity 5 on fresh id material (Capability requirement 23); nothing testable in Alloy for Invariant 2.1, 3.1, 5.1 or 10.1: each compares a record with a later version of it, which a single state cannot show, so they are the TLA+ model's); coverage 2026-11-10 (unit formal: more coverage for the yes votes): owes TLA+ checks of Invariant 5.1, Invariant 10.1 and Identity 4 (across steps); owed rows: Invariant 5; Invariant 10; Identity 4; 2a: Capability requirement 12 — owed: an invariant under the model clock (a lapsed Held commitment is resolved within the window of a cadence); the confirm-within-window rule (Inv_ConfirmWithinWindow) is held, 2026-11-11
last gate: 2026-11-27 — Final Critique 21, a delta round, one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 23b75b78 — foundational count 0 after the blind second triage, clean, one sample (the diff base 4d017e95, the reach of the grammar batch on the page, 6 labels; Linus reported 1 foundational, String 1 against String 5 on a whitespace-only input, refuted on Term reference, which says every reference is canonicalized at the seam before it is compared or recorded (Execution Contract Logic confinement 13), and on GRACE-lang Term blank, which makes blank a predicate, with every blank resource or requester refused (Operation 1, Operation 2) and a blank commitment id meeting not-known (Execution Contract Refusal 2), so no blank input reaches a comparison; its four refining items refuted by Operation 15 (a second confirm answers not-held), Invariant 3.1, Term reference and Execution Contract Input 2, and its rhetorical item by Term commitment; the blind second triage, one cold Opus 5.5 subagent run on the frozen page, placed all six refuted, and the checker's two hits are false (Read's `answers every commitment`; the numeral in Basel III); no cure); 2026-11-27 — Final Critique 20, a delta round, one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 4d017e95 — foundational count 0 after the blind second triage, clean, one sample (the diff base bad327c5, the reach of Final Critique 19's cures and the later site commits on the page, 67 labels; Linus reported two foundational claims and the first triage and the blind second triage, one cold reader on Opus 5.5, placed both refuted on their premises: the terms Linus found undeclared, reclamation sum and reclamation lag, are declared on the page, which the delta set did not carry (Term reclamation lag, Term reclamation sum), and Capability requirement 30 obliges one call at the next firing, not every later one, on a commitment that reads lapsed, which only a held commitment does (Term lapsed, Term window reading), so a commitment an admitted expire has stood in expired owes none; no cure to a rule of the page); 2026-11-26 — Final Critique 19, a full round, three readers (GRID opencode-go/glm-5.3-flash, EOS opencode-go/minimax-m3, Linus opencode-go/mimo-v2.6-pro), frozen at bad327c5 — foundational count 2 after the first triage, not clean, three samples (no blind second triage: it is owed at a count of zero); the reclamation window bounded the lag of every lapsed commitment while Capability requirement 12 and 30 let a lapsed commitment an [Expire] call answered storage-failure for outlast it (Term reclamation window and External check 5 now name the commitments no storage-failure stands for, and Capability requirement 30 asks the next firing to call [Expire], which a refused write can fail again), and the registry's verdict had no arm where the host cannot read the registry (Operation 44, registry-unavailable); three foundational claims placed refuted or refining: two [Place Hold] calls racing on one resource (Non-goal 29 gives the critical section to the lease pattern, Scott's ruling of 2026-11-20), the atom's own sweep (Execution Contract Scheduled leg 1 gives a scheduled leg's cadence to the specification, and no wait on a call the atom does not own is in the page) and Check 5.1 and 7.1 against the erasure scenario (Execution Contract Database 6, now cited in both checks and the scenario); nine refining findings cured; 2026-11-25 — Final Critique 18, a delta round, one reader (Linus opencode-go/beam-free; GRID and EOS not run), frozen at 2a39051c — foundational count 0 after the blind second triage, clean, one sample (the diff base 66dc7f3c, the reach of the Execution Contract's app model cb98fa3c on the page, 1 label, Capability requirement 15, the page's own text unchanged; Linus reported no foundational finding and pressed three questions, that Capability requirement 15's citation of Conformance 9 could let two builds treat the wiring declaration as required or optional, that Storage Failure's "remains [Held]" could leave a commitment in another state, and that "Definitive" could forbid a retry; the blind second triage, one cold reader on Opus 5.5, held all three and refuted both of Linus's refining wording changes, on Conformance 9 (which binds every deployment and which a relying page cites by its label, as eight other atoms do), on Operation 14, Operation 15, Operation 31 and Refusal 1 (a failed write is reached only from held, and place hold's first arm records nothing), and on Error model 1 and Read 4 (a retry is a new call); no cure to a rule of the page); 2026-11-20 — Final Critique 17, a delta round, one reader (Linus nemotron-3.5-super-vl-free), frozen at 66dc7f3c — foundational count 0 after the blind second triage, clean, one sample; 2026-11-20 — Final Critique 16, a delta round, one reader (Linus minimax-m3), frozen at 02a1f4a6 — foundational count 0 after the blind second triage, clean, one sample; 2026-11-20 — Final Critique 15, a delta round, frozen at a579d088 — foundational count 1 after the blind second triage, cured by the settle, not clean, no sample; 2026-11-20 — Final Critique 14, frozen at 28ae7e6e — foundational count 3, cured by the settle, not clean, no sample; 2026-11-05 — Final Critique 13, a delta round, frozen at 8adbf07 — foundational count 0, clean, one sample; 2026-11-05 — Final Critique 12 — foundational count 3, not clean, no sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./provisional-commitment.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/provisional-commitment.md`.

</details>

NOTE: End of Provisional Commitment.
