---
title: Capacity Constraint Enforcement
parent: Atomic Concepts
has_toc: true
toc: true
---

# Capacity Constraint Enforcement

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Capacity Constraint Enforcement holds one number against another. A pool declares a maximum, tracks a running total, and refuses any allocation that would push the total past the bound. Units are fungible — five units allocated is one event carrying the count, not five records — so this atom owns the arithmetic and nothing else.

A pool is [Open], [Suspended] or [Closed]. Suspending halts new allocations without unwinding the existing ones; closing is terminal. [Release] is admitted in every state, including [Closed], so a composing pattern can unwind in-flight allocations after the pool is shut.

Every successful change appends an attributed event carrying before-and-after snapshots, so an auditor can verify the bound held at any point from a single event rather than replaying the whole log. Rejections write nothing, which is a deliberate boundary rather than an omission.

This is the mechanism behind seat inventory, credit headroom, ward beds, connection pools and warehouse stock. It does not decide who may allocate, what a unit means, or what happens when the pool runs dry.

---

## Intent

WHY:
A bounded resource needs one place that owns the bound. Without it, every caller defends the limit at its own call site, and the limit is then enforced in as many slightly different ways as there are callers — which is how an airline oversells a cabin, a credit line goes past its ceiling, and a connection pool exhausts a database.

So the atom owns exactly the arithmetic: a declared maximum, a running total, and the refusal that keeps one under the other. Everything that looks adjacent is deliberately outside. Which unit is which belongs to [Provisional Commitment](./provisional-commitment.md), because per-allocation identity is a different grain. Who may allocate belongs to [Permissions](./permissions.md). What happens when the pool drains belongs to whatever composes [Subscription](./subscription.md) and [Notification](./notification.md). Fairness under contention belongs to a queueing pattern. Each of those is a policy; this is the invariant they all rest on.

Two design commitments carry the rest. **Drained is not a state** — allocated reaching capacity is an arithmetic condition, observable through [Query] and enforced by the allocate guard, and promoting it to a state would conflate a policy decision (an operator halting allocations) with a number reaching another number. And **the atom never clamps.** A capacity adjustment below the running total is refused, not silently fitted; a release beyond the total is refused, not floored at zero. Clamping would keep the invariant true and destroy the caller's ability to know it was violated.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a pool by the pool_id.
Identity 2: The atom MUST identify an audit event by the event id.
Identity 3: The host MUST allocate a pool_id at the seam.
Identity 4: The host MUST allocate an event id at the seam.
Identity 5: The transition MUST NOT allocate a pool_id.
Identity 6: The transition MUST NOT allocate an event id.
Identity 7: The atom MUST NOT change a pool_id.
Identity 8: The atom MUST NOT change an event id.
Identity 9: The atom MUST NOT identify a pool by a pool's name.
Identity 10: The atom MUST match a pool_id exactly.
Identity 11: The atom MUST NOT normalize a pool_id.
Identity 12: The atom MUST NOT order a pool_id.
Identity 13: [Declare Pool] MUST NOT write over a pool the store already holds.
Identity 14: IF a colliding write EXISTS THEN the store MUST refuse the colliding write.
Identity 15: The deployment MUST draw a pool_id unique across the system's life.
Identity 16: The deployment MUST draw an event id unique across the system's life.
Identity 17: The deployment MUST NOT reuse an event id across the event classes.
Identity 18: The atom MUST NOT hold a per-unit identity.
```

Term pool: one bounded resource with a declared maximum and a running total — the record this atom holds.

Term pool_id: the opaque value naming one pool — a [Pool Id]; host-allocated at the seam, compared by exact byte identity.

Term colliding write: a [Declare Pool] write whose injected pool_id a live pool already carries.

Term event id: the opaque value naming one audit event — an [Allocation Event Id], a [Release Event Id], an [Adjustment Event Id] or a [State Change Id], by the event's class.

Term event class: allocation | release | adjustment | state change — the four kinds of entry the audit log carries.

Term seam: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading, the pool_id and the event ids here.

Term transition: the atom's evaluation of one call against the pool store, as `execution-contract.md` §Logic confinement declares it.

WHY:
A pool's *name* is a deployment concept — a flight, a ward, a primary connection pool — and names get re-tagged, re-categorized and reused across regions. Identity by name would silently merge two pools that share a label and split one that was renamed, and either mistake merges or splits arithmetic (Identity 9).

Units are fungible at this grain, and that is the whole reason the atom stays small. An allocate of five increments the total by five and writes one event; it does not mint five sub-records. A caller that needs *this seat* rather than *a seat* wants the per-allocation lifecycle [Provisional Commitment](./provisional-commitment.md) owns, and that pattern cross-references this atom's [Allocation Event Id] rather than duplicating the arithmetic (Identity 18, Non-goal 1, Non-goal 2).

Identity 13 and Identity 14 are the create-only discipline: an injected id that collides with a live pool surfaces as [Storage Failure] with nothing written, because the overwrite reading would destroy a pool's whole arithmetic history. Event-id uniqueness has no such guard and rests wholly on the generator the deployment declares (Identity 15 through 17, Invariant 13.2).

### State

```
State 1: EVERY pool MUST stand in EXACTLY ONE OF open, suspended, closed.
State 2: EVERY pool MUST carry pool_id, capacity, allocated, a pool state, declared_at, declaring_actor_ref and declaration_reason.
State 3: EVERY pool MUST carry an audit log.
State 4: A pool MUST NOT carry available.
State 5: The atom MUST NOT offer a transition out of closed.
State 6: The atom MUST NOT offer a drained state.
State 7: The atom MUST NOT remove a pool from the store.
State 8: The atom MUST NOT remove an audit event from a pool's audit log.
State 9: The atom MUST NOT re-order a pool's audit log.
State 10: The atom MUST NOT insert an audit event BEFORE a prior audit event.
State 11: The atom MUST order a pool's audit log by insertion.
State 12: A reader MUST read a pool's audit log by insertion order.
State 13: A reader MUST NOT read a pool's audit log by recorded_at order.
State 14: EVERY audit event MUST carry an event id, the pool_id, an event class and a recorded_at.
State 15: EVERY allocation event MUST carry count, allocated_before, allocated_after and allocating_actor_ref.
State 16: EVERY release event MUST carry count, allocated_before, allocated_after and releasing_actor_ref.
State 17: EVERY adjustment event MUST carry prior_capacity, new_capacity, adjusting_actor_ref and a reason.
State 18: EVERY state-change event MUST carry prior_state, new_state, acting_actor_ref and a reason.
State 19: The atom MUST NOT change a declaration field.
State 20: The atom MUST NOT change an audit event's audit-identifier surface.
State 21: The atom MUST NOT hold a per-allocation lifecycle.
State 22: The atom MUST NOT hold a cross-pool bound.
State 23: The atom MUST NOT interpret a unit.
```

Term declaration field: pool_id | declared_at | declaring_actor_ref | declaration_reason — set at [Declare Pool] and never changed.

Term allocated_before: the running total an audit event found — an [Allocated Before].

Term allocated_after: the running total an audit event left — an [Allocated After]; the requested total on an allocation event, the released total on a release event.

Term recorded_at: the instant an audit event was written — a [Recorded At]; stamped from the injected now, and advisory rather than authoritative for order.

Term audit-identifier surface: an audit event's event id, pool_id, event class, arithmetic fields, state fields and recorded_at — everything the atom never rewrites and the arithmetic chain rests on.

Term attribution surface: an audit event's actor reference and reason — what makes a record personally identifying, and what a composed erasure mechanism may scrub.

WHY:
Drained is not a state, and that is the sharpest boundary in the atom. allocated reaching capacity is a number reaching another number: observable through [Query], enforced by the allocate guard, and derivable at any moment. A state, by contrast, is something an actor decided — suspend, resume, close. Promoting an arithmetic condition to a state would put a policy name on a computation and invite a transition nobody performs (State 6).

Order is insertion order, not timestamp order. recorded_at comes from the seam's clock and under skew it is not monotonic, so every *after*, *between* and *most recent* in this spec means by insertion (State 11 through 13). A deployment that needs order bound to verifiable wall time composes a trusted-timestamping pattern; without it, timestamps are metadata and insertion is the truth.

An adjustment event names [Prior Capacity] against [New Capacity]; a state-change event names [Prior State] against [New State]; an allocation or release event names [Allocated Before] against [Allocated After] with the [Count] between them. Each is a before and an after on one row, which is what lets an auditor clear the bound at a single event.

An audit event has two surfaces with different lifetimes, and the split is structural. The audit-identifier surface is what makes the arithmetic chain verifiable from records alone, and no action of this atom rewrites it. The attribution surface — [Allocating Actor Ref] and [Releasing Actor Ref] on the arithmetic events, [Adjusting Actor Ref] and [Acting Actor Ref] with a [Reason] on the others — is what makes the record identify a person, and a deployment that encodes personal data there may have to erase it under GDPR (EU General Data Protection Regulation) Article 17 — through its own declared shredding-class mechanism, gated by a composed [Retention Window](./retention-window.md), which declares *when* a lifetime ends and carries no field-level scrub surface of its own. After such an erasure the records still verify the arithmetic and no longer name the actor, which is exactly the property the split exists to give (State 20, Invariant 8.1 through 8.4).

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST own the clock's monotonicity.
Capability requirement 3: The deployment MUST own the clock's timezone handling.
Capability requirement 4: The deployment MUST own the clock's honesty.
Deleted: Clock semantics 1. Capability requirement 2 owns it.
Deleted: Clock semantics 2. Capability requirement 3 owns it.
Deleted: Clock semantics 3. Capability requirement 1 and Capability requirement 4 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 4. Clock dependence 1 owns it.
Deleted: Clock semantics 5. Clock dependence 2 owns it.
Deleted: Clock semantics 6. Non-goal 29 owns it.
```

WHY:
What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

WHY:
The clock has exactly one job here — stamping declared_at and each event's recorded_at — and no guard consults it. Every precondition is a state check, a field-format check or an arithmetic check on stored integers, so a skewed clock can make a timestamp advisory and can never admit or refuse a call (Clock dependence 1, Clock semantics 5).

### Operations

```
declare_pool(capacity, declaring_actor_ref, reason)
  answers pool_id
  refuses invalid-request | storage-failure

allocate(pool_id, count, allocating_actor_ref)
  answers allocation_event_id
  refuses not-known | over-capacity | suspended | closed | invalid-request | storage-failure

release(pool_id, count, releasing_actor_ref)
  answers release_event_id
  refuses not-known | over-release | invalid-request | storage-failure

adjust_capacity(pool_id, new_capacity, adjusting_actor_ref, reason)
  answers adjustment_event_id
  refuses not-known | closed | over-allocated | invalid-request | storage-failure

suspend_pool(pool_id, suspending_actor_ref, reason)
  answers state_change_id
  refuses not-known | not-open | already-closed | invalid-request | storage-failure

resume_pool(pool_id, resuming_actor_ref, reason)
  answers state_change_id
  refuses not-known | not-suspended | already-closed | invalid-request | storage-failure

close_pool(pool_id, closing_actor_ref, reason)
  answers state_change_id
  refuses not-known | already-closed | invalid-request | storage-failure

query(pool_id)
  answers pool_snapshot
  refuses not-known
```

```
Operation 1: [Declare Pool] MUST record EXACTLY ONE pool per successful call.
Operation 2: [Declare Pool] MUST stand the pool in open.
Operation 3: [Declare Pool] MUST set allocated to zero.
Operation 4: [Declare Pool] MUST set capacity to the supplied capacity.
Operation 5: [Declare Pool] MUST stamp declared_at from the injected now.
Operation 6: [Declare Pool] MUST answer the pool_id.
Operation 7: IF capacity NOT EXISTS in the whole counts THEN [Declare Pool] MUST answer invalid-request.
Operation 8: IF the pool_id names no pool THEN an addressed action MUST answer not-known.
Operation 9: An addressed action MUST answer not-known ONLY IF the pool_id names no pool.
Operation 10: IF the pool stands in suspended THEN [Allocate] MUST answer suspended.
Operation 11: IF the pool stands in closed THEN [Allocate] MUST answer closed.
Operation 12: IF count NOT EXISTS in the positive counts THEN [Allocate] MUST answer invalid-request.
Operation 13: IF the requested total EXCEEDS capacity THEN [Allocate] MUST answer over-capacity.
Operation 14: [Allocate] MUST answer over-capacity ONLY IF the pool stands in open.
Operation 15: [Allocate] MUST raise allocated to the requested total.
Operation 16: [Allocate] MUST append an allocation event.
Operation 17: [Allocate] MUST answer the allocation event id.
Operation 18: [Allocate] MUST NOT change capacity.
Operation 19: [Allocate] MUST NOT change the pool's state.
Operation 20: [Release] MUST admit a call in EVERY pool state.
Operation 21: IF count NOT EXISTS in the positive counts THEN [Release] MUST answer invalid-request.
Operation 22: IF count EXCEEDS allocated THEN [Release] MUST answer over-release.
Operation 23: [Release] MUST lower allocated to the released total.
Operation 24: [Release] MUST append a release event.
Operation 25: [Release] MUST answer the release event id.
Operation 26: [Release] MUST NOT change capacity.
Operation 27: [Release] MUST NOT change the pool's state.
Operation 28: [Release] MUST NOT match a count against a prior allocation's count.
Operation 29: IF the pool stands in closed THEN [Adjust Capacity] MUST answer closed.
Operation 30: IF new_capacity NOT EXISTS in the whole counts THEN [Adjust Capacity] MUST answer invalid-request.
Operation 31: IF new_capacity = capacity THEN [Adjust Capacity] MUST answer invalid-request.
Operation 32: IF allocated EXCEEDS new_capacity THEN [Adjust Capacity] MUST answer over-allocated.
Operation 33: [Adjust Capacity] MUST set capacity to new_capacity.
Operation 34: [Adjust Capacity] MUST append an adjustment event.
Operation 35: [Adjust Capacity] MUST answer the adjustment event id.
Operation 36: [Adjust Capacity] MUST NOT change allocated.
Operation 37: [Adjust Capacity] MUST NOT set capacity to allocated in place of answering over-allocated.
Operation 38: [Adjust Capacity] MUST NOT release a unit to fit a lower capacity.
Operation 39: IF the pool stands in suspended THEN [Suspend Pool] MUST answer not-open.
Operation 40: IF the pool stands in closed THEN [Suspend Pool] MUST answer already-closed.
Operation 41: [Suspend Pool] MUST stand the pool in suspended.
Operation 42: IF the pool stands in open THEN [Resume Pool] MUST answer not-suspended.
Operation 43: IF the pool stands in closed THEN [Resume Pool] MUST answer already-closed.
Operation 44: [Resume Pool] MUST stand the pool in open.
Operation 45: IF the pool stands in closed THEN [Close Pool] MUST answer already-closed.
Operation 46: [Close Pool] MUST stand the pool in closed.
Operation 47: A state-changing action MUST append a state-change event.
Operation 48: A state-changing action MUST answer the state change id.
Operation 49: A state-changing action MUST NOT change allocated.
Operation 50: A state-changing action MUST NOT change capacity.
Operation 51: [Query] MUST answer the pool snapshot.
Operation 52: [Query] MUST NOT write.
Operation 53: [Query] MUST NOT append an audit event.
Operation 54: [Query] MUST admit a call in EVERY pool state.
Operation 55: [Query] MUST NOT answer storage-failure.
Operation 56: IF the store refuses a read THEN [Query] MUST NOT answer a stale pool snapshot.
Operation 57: IF the store refuses a write THEN a writing action MUST answer storage-failure.
Operation 58: A refused action MUST leave the pool as the call found the pool.
Operation 59: A refused action MUST NOT append an audit event.
Operation 60: An action MUST answer storage-failure ONLY IF EVERY precondition passes.
Deleted: Operation 61. Capability requirement 1 owns it.
Deleted: Operation 62. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 63. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 64. Clock dependence 1 owns it.
```

Term now: the wall-time reading the host takes at the seam and hands to the transition — a [Now], as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

Term business caller: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Term capacity: the declared maximum a pool admits — a [Capacity]; a whole count, set at declaration and changed only by [Adjust Capacity].

Term allocated: the pool's running total — an [Allocated]; changed only by [Allocate] and [Release].

Term available: `capacity − allocated` — an [Available]; computed wherever it is reported and never stored, so it cannot lag its operands.

Term count: the units one [Allocate] or [Release] call operates on — a [Count]; a positive count.

Term whole count: a count of zero or more; what capacity and new_capacity must be.

Term positive count: a count of one or more; what count must be, which is why a zero-unit call is refused rather than admitted as a no-op.

Term requested total: `allocated + count` — the running total an [Allocate] call would reach, and the value the capacity guard compares.

Term released total: `allocated − count` — the running total a [Release] call would reach.

Term new_capacity: the maximum an [Adjust Capacity] call asks for — a [New Capacity]; a whole count, and refused where it equals the current capacity.

Term pool state: open | suspended | closed — accepting allocations, halted, or terminal. A [State].

Term addressed action: any action carrying a pool_id — every action but [Declare Pool].

Term state-changing action: [Suspend Pool] | [Resume Pool] | [Close Pool] — the three that move a pool's state.

Term writing action: every action but [Query].

Term pool snapshot: capacity, allocated, available and the pool state together — what [Query] answers, and deliberately not the declaration fields or the audit log.

Term audit event: one entry on a pool's log — an allocation, a release, an adjustment or a state change, each carrying its own event id and a recorded_at.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the pool |
|---|---|---|---|
| [Declare Pool] | capacity a whole count, fields valid, store accepts | the new pool_id | pool lands in [Open], allocated zero (Operation 1 through 5) |
| [Allocate] | [Open], count positive, requested total within capacity | the allocation_event_id | allocated rises, one event appended (Operation 15 through 17) |
| [Allocate] | [Open], requested total past capacity | [Over Capacity] | none (Operation 13) |
| [Allocate] | [Suspended] | [Suspended] | none (Operation 10) |
| [Allocate] | [Closed] | [Closed] | none (Operation 11) |
| [Release] | any state, count positive and within allocated | the release_event_id | allocated falls, one event appended (Operation 20, Operation 23) |
| [Release] | count past allocated | [Over Release] | none (Operation 22) |
| [Adjust Capacity] | [Open] or [Suspended], new value differs and covers allocated | the adjustment_event_id | capacity replaced, one event appended (Operation 33, Operation 34) |
| [Adjust Capacity] | new value equals current | [Invalid Request] | none (Operation 31) |
| [Adjust Capacity] | new value below allocated | [Over Allocated] | none (Operation 32) |
| [Adjust Capacity] | [Closed] | [Closed] | none (Operation 29) |
| [Suspend Pool] | [Open] | the state_change_id | → [Suspended] (Operation 41) |
| [Resume Pool] | [Suspended] | the state_change_id | → [Open] (Operation 44) |
| [Close Pool] | [Open] or [Suspended] | the state_change_id | → [Closed] (Operation 46) |
| any state change | already in the target state, or [Closed] | [Not Open], [Not Suspended], [Already Closed] | none (Operation 39 through 45) |
| any addressed action | id names nothing | [Not Known] | none (Operation 8) |
| any writing action | store refuses | [Storage Failure] | none (Operation 57 through 59) |
| [Query] | id names a pool, any state | the pool snapshot | none (Operation 51, Operation 54) |

WHY:
The rejection order is fixed and each step is defended. [Not Known] comes first because every later check presupposes a record to inspect — an unknown pool has no state, no total and no bound to compare against (Operation 8, Operation 9). State-validity comes before field-format because state is a property of the *target* and format is local to the *call*: a [Closed] pool does not accept the action at all, and saying so before validating per-call fields is the quieter path for the common case of an operator draining a decommissioned pool. The cost is real and accepted — a malformed count against a closed pool reads [Closed], and the caller learns about the count on retry. Field-format comes before the arithmetic because the arithmetic is meaningless on a malformed integer: `allocate(count = -5)` must answer [Invalid Request] and not slip past a bound check that a negative count satisfies by accident (Operation 12). The store write is last, so every in-memory check precedes any durable effect (Operation 60).

The three arithmetic guards are the atom, and all three are comparisons the grammar carries directly: the requested total against capacity, count against allocated, allocated against new_capacity (Operation 13, Operation 22, Operation 32). Only the sum needs a name, and it has one.

Nothing clamps. A downward adjustment below the running total is refused rather than fitted, and a release beyond the total is refused rather than floored — because clamping would keep the invariant true while destroying the caller's ability to learn it was about to be broken. Freeing units to fit a smaller bound is a policy decision the caller makes explicitly, with [Release] calls, before adjusting again (Operation 37, Operation 38).

[Query] is fail-stop and declares no storage-failure arm: its one rejection is semantic, and a store that cannot be read yields no conforming outcome rather than a stale snapshot, so any answer a caller holds is a complete one (Operation 55, Operation 56).

### Invariants

- **Invariant 1 — Pool record permanence under this atom's actions.**
  ```
  Invariant 1.1: The atom MUST NOT offer an action that removes a pool.
  Invariant 1.2: The pool count MUST NOT fall under the atom's actions.
  Invariant 1.3: A storage-failure rejection MUST leave no partial pool in the store.
  ```
  WHY: scoped to the atom's own surface. A deployment purging a long-closed pool under a composed [Retention Window](./retention-window.md) is that pattern's declared act, and the consequence is named rather than hidden — a regulator querying a stale id reads [Not Known] whether the pool was never declared or was purged, and distinguishes the two from the deployment's retention manifest (Non-goal 24, Non-goal 25).
- **Invariant 2 — State membership exclusivity.**
  ```
  Invariant 2.1: EVERY pool MUST stand in EXACTLY ONE OF open, suspended, closed.
  ```
- **Invariant 3 — Closed is absorbing for state and for new allocation.**
  ```
  Invariant 3.1: A closed pool MUST NOT leave closed.
  Invariant 3.2: [Allocate] MUST answer closed against a closed pool.
  Invariant 3.3: [Adjust Capacity] MUST answer closed against a closed pool.
  Invariant 3.4: [Release] MUST stand as the one mutating action a closed pool admits.
  ```
  WHY: a composing pattern's per-allocation records may still be unwinding when the pool closes. Refusing [Release] there would not block those records reaching their own terminal states — those transitions are internal to the composing pattern — it would strand the pool's total at its close-time value and leave a final figure matching no observable reality (Composition note 3).
- **Invariant 4 — Capacity constraint.**
  ```
  Invariant 4.1: EVERY pool's allocated MUST NOT EXCEED the capacity.
  Invariant 4.2: [Allocate] MUST refuse a call whose requested total EXCEEDS capacity.
  Invariant 4.3: [Adjust Capacity] MUST refuse a call whose allocated EXCEEDS the new_capacity.
  Invariant 4.4: Invariant 4.1 MUST rest on the host obligations Concurrency 1, Crash atomicity 1 and Arithmetic 1 name.
  ```
  WHY: the load-bearing arithmetic invariant, and the one a composing pattern may rely on without re-implementing the bound — contingent on three host obligations the atom names and cannot itself supply: serialized execution per pool, crash-atomic multi-record writes, and integer arithmetic that does not lose the sum. A deployment missing any of the three can observe the invariant fail despite every precondition holding; that is a deployment-side gap, and its audit posture must say so.
- **Invariant 5 — Non-negativity.**
  ```
  Invariant 5.1: EVERY pool's allocated MUST NOT fall below zero.
  Invariant 5.2: [Release] MUST refuse a call whose count EXCEEDS allocated.
  Invariant 5.3: Invariant 5.1 MUST rest on the host obligations Invariant 4.4 names.
  ```
- **Invariant 6 — Capacity non-negativity.**
  ```
  Invariant 6.1: EVERY pool's capacity MUST stand as a whole count.
  Invariant 6.2: [Declare Pool] MUST refuse a capacity outside the whole counts.
  Invariant 6.3: [Adjust Capacity] MUST refuse a new_capacity outside the whole counts.
  ```
- **Invariant 7 — Declaration fields immutable.**
  ```
  Invariant 7.1: A recorded declaration field MUST NOT change.
  ```
- **Invariant 8 — An audit event has two surfaces with distinct lifetimes.**
  ```
  Invariant 8.1: The atom MUST NOT offer an action that changes an audit-identifier surface.
  Invariant 8.2: The atom MUST NOT offer an action that changes an attribution surface.
  Invariant 8.3: An audit-identifier surface MUST stand for as long as the audit event stands.
  Invariant 8.4: A composed erasure mechanism MAY scrub an attribution surface.
  Invariant 8.5: An arithmetic reconstruction MUST NOT rest on an attribution surface.
  ```
- **Invariant 9 — Audit log append-only under this atom's actions.**
  ```
  Invariant 9.1: The atom MUST NOT offer an action that removes an audit event.
  Invariant 9.2: The atom MUST NOT offer an action that re-orders an audit log.
  Invariant 9.3: An audit log's length MUST NOT fall under the atom's actions.
  Invariant 9.4: A composed retention pattern MAY purge an audit event.
  ```
  WHY: the *under this atom's actions* qualifier is load-bearing. A regulator reads the composed-system view, which this atom does not govern alone: append-only here is necessary for the audit chain and not sufficient, and the deployment's retention schedule is the other half of what a regulator sees. The arithmetic chain reconstructs within the active window; before it, reconstruction needs the archive or is bounded out (Check 2.2).
- **Invariant 10 — State changes are auditable.**
  ```
  Invariant 10.1: EVERY state change MUST append a state-change event.
  Invariant 10.2: EVERY state-change event MUST carry prior_state, new_state, acting_actor_ref and a reason.
  ```
- **Invariant 11 — Capacity adjustments are auditable.**
  ```
  Invariant 11.1: EVERY capacity change MUST append an adjustment event.
  Invariant 11.2: EVERY adjustment event MUST carry prior_capacity, new_capacity, adjusting_actor_ref and a reason.
  ```
- **Invariant 12 — Id stability.**
  ```
  Invariant 12.1: A recorded pool_id MUST NOT change.
  Invariant 12.2: A recorded event id MUST NOT change.
  ```
- **Invariant 13 — No id reuse.**
  ```
  Invariant 13.1: Two pools MUST NOT share a pool_id.
  Invariant 13.2: Two audit events MUST NOT share an event id.
  Invariant 13.3: Invariant 13.2 MUST rest on the generator the deployment declares.
  ```
  WHY: honest rather than decorative. Ids are seam-injected, so the atom cannot foreclose a colliding generator. Its one contribution is the create-only [Declare Pool] write, which surfaces an observable pool-id collision as [Storage Failure] (Identity 13, Identity 14); event-id uniqueness rests wholly on the deployment.
- **Invariant 14 — Action atomicity.**
  ```
  Invariant 14.1: A writing action MUST commit EVERY record the action writes in one operation.
  Invariant 14.2: A storage-failure rejection MUST leave no partial record in the store.
  Invariant 14.3: Invariant 14.1 MUST rest on the host obligation Crash atomicity 1 names.
  ```
  WHY: the rejection path and the crash path need separating. A [Storage Failure] answer is the host surfacing a failure as a return value, and nothing committed. A crash between the log append and the total update returns nothing at all, and only the crash-atomicity obligation extends all-or-none to that path.

Invariants 4 and 5 together give the *bounded-arithmetic* property — at every reachable state the running total sits between zero and the bound, under the host obligations Invariant 4.4 names. That is what a composing pattern may treat as a precondition; without it every caller defends the bound at its own call site. Invariant 8 through 11 give the *successful-change-audit* property — every successful change to a pool's capacity, total or state is an attributed event in insertion order whose identifier surface nothing rewrites. *Rejected* calls produce no event here, deliberately (Non-goal 26, Non-goal 27). Invariant 3 gives *terminal closure* — a closed pool cannot be quietly reopened, and post-close unwinding through [Release] is the only mutation that survives it.

---

## Examples

### Airline — non-overbooking seat pool

A carrier declares a cabin: `declare_pool(capacity: 180, declaring_actor_ref: inventory_svc, reason: "NK1234 2026-05-14 main cabin")` → `pool_a1`. Each booking calls `allocate(pool_a1, count: 1, allocating_actor_ref: booking_svc)`; the 181st answers over-capacity and the cabin is not oversold. A cancellation calls `release(pool_a1, count: 1, ...)` and the seat returns to the pool. An equipment swap to a smaller aircraft with 174 seats sold calls `adjust_capacity(pool_a1, new_capacity: 174, ...)` → accepted; the same call against 170 answers over-allocated, because four passengers are already holding seats the smaller bound would not cover, and the carrier must release before it can adjust (Operation 32).

### Banking — credit-limit headroom

A revolving line: `declare_pool(capacity: 25000, ...)` → `pool_c9`. Each draw allocates, each repayment releases, and a draw past the limit answers over-capacity. A credit review lowering the line to 10000 while 14000 is drawn answers over-allocated — the atom refuses to put the customer instantly over their new limit by arithmetic, and the reviewer must sequence the reduction against repayment explicitly (Operation 37).

### Healthcare — ward bed pool

A ward of 24 beds. An infection-control hold calls `suspend_pool(pool_w3, ...)`: admissions stop, discharges continue, because [Release] is admitted in every state (Operation 20). Capacity can still be re-tuned while paused. resume_pool reopens it.

### Database operations — connection pool

A primary pool of 200 connections, allocated on checkout and released on return. A failover calls suspend_pool; in-flight connections drain through [Release] while nothing new is admitted; close_pool retires it, and the last returns still land because closing forecloses allocation and not unwinding (Invariant 3.4).

### Rejection paths

`allocate(pool_a1, count: 0, ...)` → invalid-request. A zero-unit allocation is not a use of the action (Operation 12).

`adjust_capacity(pool_a1, new_capacity: 180, ...)` where capacity is already 180 → invalid-request. A no-op adjustment would append an event recording no change (Operation 31).

`allocate(pool_x, count: 1, ...)` where `pool_x` names nothing → not-known — which covers both *never declared* and *declared, closed, and since purged under a composed retention pattern*. The atom cannot tell them apart and does not pretend to (Operation 8, Invariant 1.1).

`allocate(pool_closed, count: -5, ...)` against a closed pool → closed, not invalid-request. State precedes format, and the caller learns about the count on retry against a live pool.

### Regulated adversarial scenarios

- **Regulator audit — was the cabin ever oversold?** The auditor walks the pool's allocation events and checks each one's own snapshot: allocated_after equals allocated_before plus count, and allocated_after does not exceed the capacity in effect at that index. No replay from the beginning is required, because every event carries its own before and after — which is the whole reason the snapshots are on the record (Check 3.1, Check 3.2).
- **Disputed drawdown — the customer says the line was cut without notice.** Every capacity change is an adjustment event naming prior capacity, new capacity, the acting reference and a stated reason (Invariant 11.2). What the store cannot show is the *rejected* draws the customer attempted, because rejections write nothing here; a deployment under PCI DSS (Payment Card Industry Data Security Standard) Requirement 10.2.4 wires [Event Log](./event-log.md) around the call surface for that (External check 1, Non-goal 26).
- **Breach investigation — which pools were manipulated during the window?** The auditor filters audit events by recorded_at inside the window and reads each one's actor reference. Two limits are stated rather than discovered: recorded_at is advisory under clock skew and insertion order is authoritative (State 13), and where the deployment has scrubbed the attribution surface under a composed erasure the arithmetic still verifies while the actor no longer resolves (Invariant 8.4, Invariant 8.5).

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the pool record set and its audit log, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY pool's pool_id, capacity, allocated, pool state and declaration fields present (Invariant 7.1, State 2).
Check 2.1: An auditor MUST reconstruct a pool's capacity, allocated and pool state at an audit event by replaying an unbroken audit log forward from the declaration (Invariant 9.1, State 11).
Check 2.2: An auditor MUST read a purged audit event as a break in the replay (Invariant 9.4).
Check 2.3: A deployment needing a replay across a purge MUST retain an anchor carrying the capacity, the allocated and the pool state at the purge boundary (Invariant 9.4).
Check 3.1: An auditor MUST find EVERY allocation event's allocated_after equal to the requested total (Invariant 4.2).
Check 3.2: An auditor MUST find EVERY allocation event's allocated_after no higher than the capacity the replay holds at the audit event (Invariant 4.1, Check 2.1).
Check 4.1: An auditor MUST find EVERY release event's allocated_after equal to the released total (Invariant 5.2).
Check 4.2: An auditor MUST find no release event's allocated_after below zero (Invariant 5.1).
Check 5.1: An auditor MUST find an acting_actor_ref and a reason on EVERY state-change event (Invariant 10.2).
Check 5.2: An auditor MUST find an adjusting_actor_ref and a reason on EVERY adjustment event (Invariant 11.2).
Check 5.3: An auditor MUST find an allocating_actor_ref on EVERY allocation event (State 15).
Check 5.4: An auditor MUST find a releasing_actor_ref on EVERY release event (State 16).
Check 6.1: An auditor MUST identify which composing patterns a deployment wired in (Composition note 1).
```

NOTE: EVERY check names the rule the check tests.

#### External checks

```
External check 1: An auditor needing a refused call MUST read the refusal from a composing Event Log (Non-goal 26).
External check 2: An auditor needing a per-unit history MUST read the history from a composing Provisional Commitment (Non-goal 1).
External check 3: An auditor needing an attested actor MUST read the attestation from a composing Actor Identity (Non-goal 12).
```

WHY:
Check 3.1 and Check 3.2 are per-event and that is the point of carrying before-and-after on every entry: an auditor clears the bound at a single event without replaying the log to that index. Replay stays authoritative under Check 2.1 — the snapshots witness the arithmetic rather than replace it — and Check 2.2 states the honest scope, because a composed purge bounds what any replay can reach.

The three External checks name what this store cannot answer. Refused calls leave no trace here at all; per-unit history is a different grain; an actor reference is the caller's claim until something attests it.

## Non-goals

```
Non-goal 1: The atom MUST NOT hold a per-allocation lifecycle.
Non-goal 2: A deployment needing per-unit identity MUST compose Provisional Commitment.
Non-goal 3: The atom MUST NOT order two contending calls fairly.
Non-goal 4: A deployment needing fairness MUST compose a queueing pattern.
Non-goal 5: The atom MUST NOT gate an action on a caller's authority.
Non-goal 6: A deployment needing authorization MUST compose Permissions.
Non-goal 7: The atom MUST NOT evict an allocation to admit another.
Non-goal 8: The atom MUST NOT admit an allocation beyond capacity.
Non-goal 9: A deployment needing overcommit MUST compose a soft-limit pattern.
Non-goal 10: The atom MUST NOT expire an allocation.
Non-goal 11: A deployment needing a bounded allocation lifetime MUST compose Lease.
Non-goal 12: The atom MUST NOT attest an actor reference.
Non-goal 13: A deployment needing an attested actor MUST compose Actor Identity.
Non-goal 14: The atom MUST NOT interpret what a unit represents.
Non-goal 15: The atom MUST NOT move a unit between two pools.
Non-goal 16: The atom MUST NOT merge two pools.
Non-goal 17: The atom MUST NOT split a pool.
Non-goal 18: The atom MUST NOT notify a reader of a state change.
Non-goal 19: A deployment needing notification MUST compose Subscription.
Non-goal 20: The atom MUST NOT hold a cross-pool bound.
Non-goal 21: The atom MUST NOT seal a pool against modification.
Non-goal 22: A deployment needing court-admissible records MUST compose Tamper Evidence.
Non-goal 23: The atom MUST NOT bound how long a pool is kept.
Non-goal 24: A deployment needing a retention bound MUST compose Retention Window.
Non-goal 25: The atom MUST NOT distinguish a purged pool_id from an undeclared pool_id.
Non-goal 26: The atom MUST NOT record a refused call.
Non-goal 27: A deployment needing refusal visibility MUST compose Event Log.
Non-goal 28: The atom MUST NOT hold a multi-dimensional capacity.
Non-goal 29: A deployment needing verifiable wall-time order MUST compose a trusted timestamping pattern.
```

WHY:
The audit log here is the pool's own arithmetic history and not an absorbed [Event Log](./event-log.md). The likely objection is fair — an append-only, attributed, insertion-ordered log is exactly what that atom provides. What resolves it is that these entries are not a content-agnostic stream: every one is a snapshot of *this* pool's capacity and total, and the invariants that make the bound verifiable range over those fields. A deployment that wants a deployment-grain journal composes Event Log around the call surface, and gets the refusals this log does not carry (Non-goal 26, Non-goal 27, External check 1).

Overcommit is refused as a shape, not as a preference. Airlines overbook and connection pools burst, and both are real; both are also a *tolerance margin*, which is a second bound with its own policy. This atom enforces one hard bound, and a soft-limit pattern that carries a margin composes in front of it (Non-goal 8, Non-goal 9).

Where the atom breaks down is worth naming. When the resource is not fungible at any grain — every seat distinct by legroom or fare class — per-unit identity belongs at this layer too, which is a sign the deployment wants Provisional Commitment rather than this. When capacity is a vector rather than an integer — memory bytes *and* core count *and* disk — one running total cannot carry it, and a multi-dimensional pattern is a different atom (Non-goal 28).

## Edge cases

### Clock dependence

```
Clock dependence 1: A guard MUST NOT read now.
Clock dependence 2: A rejection MUST NOT rest on now.
```

WHY:
Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated here rather than among the rules about what the clock is and what a transition stamps from it. Every rule below keeps the words it carried under `Clock semantics`; only the heading changed.

### Concurrency

```
Concurrency 1: The host MUST serialize concurrent calls on one pool_id.
Concurrency 2: The implementation MUST make the arithmetic guard and the write one transition.
Concurrency 3: A store enforcing a compare-and-set on allocated MAY discharge Concurrency 2.
Concurrency 4: The atom MUST NOT order two contending calls fairly.
Concurrency 5: The atom MUST NOT offer a multi-action transaction.
```

WHY:
The guard reads allocated and the write changes it; two concurrent allocates against one unit of headroom both read *room* and both write, and Invariant 4.1 — the reason this atom exists — breaks by the very sequence it forbids. Check-then-act, and the fix is the implementation's: one transition, or a compare-and-set that does the same work (Concurrency 2, Concurrency 3).

### String policy

```
String 1: EVERY required string field MUST carry a codepoint outside the whitespace category.
String 2: IF a required string field NOT EXISTS THEN the action MUST answer invalid-request.
String 3: The deployment MUST set a maximum length for an actor reference.
String 4: A reason MUST NOT EXCEED the reason cap.
String 5: IF a string field EXCEEDS the field's maximum length THEN the action MUST answer invalid-request.
String 6: IF a string field carries a control character THEN the action MUST answer invalid-request.
String 7: IF a string field carries a zero-width character THEN the action MUST answer invalid-request.
String 8: IF a string field carries a bidi-override character THEN the action MUST answer invalid-request.
String 9: The atom MUST NOT normalize a string field.
String 10: The atom MUST NOT case-fold a string field.
String 11: The atom MUST store a string field as the call supplied the string field.
String 12: The deployment MUST normalize a string field the deployment compares.
```

Term integer width: the largest count the deployment's integers carry without loss.

Term reason cap: 2000 codepoints — the ceiling a reason is measured against, counted in codepoints rather than bytes so a multi-byte script is not penalized against a single-byte one.

Term control character: a codepoint in Unicode's `Cc` category.

Term zero-width character: a codepoint in `U+200B` to `U+200D`, or `U+FEFF`.

Term bidi-override character: a codepoint in `U+202A` to `U+202E`, or `U+2066` to `U+2069`.

WHY:
String 6 through 8 are audit-surface rules wearing validation clothes. A reason made of control bytes, of zero-width characters, or spoofed with bidi overrides passes every syntactic check and is invisibly empty or deceptively rendered to the human auditor the field exists to serve — so admitting it would satisfy the format and defeat the purpose.

The cap's *value* is the deployment's; its *existence* is the contract. An uncapped opaque field on an append-only log is an unbounded payload sink (String 3, String 4).

### Arithmetic

```
Arithmetic 1: The deployment MUST compute the requested total without loss.
Arithmetic 2: The deployment MUST own the integer width.
Arithmetic 3: IF the requested total EXCEEDS the integer width THEN the deployment MUST NOT admit the call.
```

WHY:
Invariant 4.1 rests on the sum being computable. A deployment on fixed-width signed integers that admits a requested total past the width produces a wrapped value that satisfies the guard and breaks the bound — the one way this atom's central invariant fails while every precondition reads as holding.

### Crash atomicity

```
Crash atomicity 1: The host MUST commit an action's pool change and the action's audit event in one operation.
Crash atomicity 2: A crash inside a writing action MUST NOT leave an audit event without the matching pool change.
Crash atomicity 3: A crash inside a writing action MUST NOT leave a pool change without the matching audit event.
Crash atomicity 5: A crash inside [Declare Pool] MUST NOT leave a pool the declaration did not finish.
Crash atomicity 4: A recovered store MUST NOT stand in a violation of Invariant 4.1.
```

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the per-unit lifecycle.
Composition note 3: A composing pattern MUST call [Release] when the pattern's own allocation reaches a terminal state.
Composition note 4: A composing pattern MUST record the event id the atom answered.
Composition note 5: A composing pattern MUST own the authority to call an action.
Composition note 6: A composing pattern MUST own the refusal record.
Composition note 7: A composing pattern MUST own the retention of the pool store.
Composition note 8: A composing pattern reading the pool store MUST NOT write to the pool store.
```

WHY:
[Provisional Commitment](./provisional-commitment.md) is the pattern this atom was extracted from under: it owns Held, Confirmed, Released and Expired per commitment, cross-references the [Allocation Event Id] this atom answers, and calls [Release] when a commitment reaches its own terminal state — which is why Invariant 3.4 admits release into a closed pool (Composition note 3, Composition note 4).

[Actor Identity](./actor-identity.md) attests the reference each action carries, turning *the caller supplied this reference* into *this actor acted*. [Audit Trail](../compositions/audit-trail.md) records the lifecycle events tamper-evidently and is where a refusal would live if the deployment journals one. [Event Log](./event-log.md) wraps the call surface where refusal visibility is required. [Retention Window](./retention-window.md) bounds how long pool records and audit events stay queryable, and [Tamper Evidence](./tamper-evidence.md) seals them where the records must survive a challenge. [Duplicate Prevention](./duplicate-prevention.md) gives at-most-once on [Allocate] under retry, so a network timeout does not consume the pool twice.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a guard; an operator; an auditor; a reader; the store; a pool; a pool state; an audit event; an audit log; a crash; a write; an action; a rejection; a string field; the pool count.

Term records: pool — one bounded resource, carrying pool_id, capacity, allocated, a pool state, the declaration fields and an audit log; audit event — one entry on that log, carrying an event id, the pool_id, an event class, a recorded_at and the fields the event's class names.

Term record verbs: identify, offer, share, re-order, retain, allocate, change, match, normalize, order, write, refuse, draw, reuse, hold, record, stand, set, stamp, answer, append, raise, lower, admit, release, fit, interpret, leave, insert, remove, carry, read, supply, rest, fall, commit, scrub, reconstruct, replay, bound, find, equal, purge, evict, expire, attest, move, merge, split, notify, seal, compose, gate, distinguish, serialize, make, discharge, compute, own, declare, call, name, store, case-fold, exceed.

Term value sets: declare_pool answers pool_id and refuses invalid-request | storage-failure. allocate answers allocation_event_id and refuses not-known | over-capacity | suspended | closed | invalid-request | storage-failure. release answers release_event_id and refuses not-known | over-release | invalid-request | storage-failure. adjust_capacity answers adjustment_event_id and refuses not-known | closed | over-allocated | invalid-request | storage-failure. suspend_pool, resume_pool and close_pool answers state_change_id and refuses not-known | already-closed | invalid-request | storage-failure. query answers pool_snapshot and refuses not-known. pool state and event class are declared above and cited here (Closed vocabulary 15).

Term bounds: reason cap (2000 codepoints); maximum length (the deployment's cap per string field); whole count and positive count (the integer floors); capacity (the pool's own declared bound).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.36 (2026-09-12).

Term terms: pool, pool_id, event id, event class, seam, transition, now, business caller, capacity, allocated, available, count, whole count, positive count, requested total, released total, new_capacity, pool state, addressed action, state-changing action, writing action, pool snapshot, audit event, declaration field, allocated_before, allocated_after, recorded_at, colliding write, integer width, audit-identifier surface, attribution surface, reason cap, control character, zero-width character, bidi-override character, maximum length.

#### Declare Pool

The behavior that creates a new bounded pool. It records the supplied [Capacity], [Declaring Actor Ref], and [Declaration Reason], enters the pool in [Open] with [Allocated] = 0, stamps [Declared At], and returns the fresh [Pool Id].

Kind: Operation

#### Allocate

The behavior that consumes units against a pool, incrementing [Allocated] by [Count] when the pool is [Open] and the bound admits it. Returns an [Allocation Event Id]. Rejected [Over Capacity] when [Allocated] + [Count] > [Capacity], [Suspended] or [Closed] when the pool is not [Open].

Kind: Operation

#### Release

The behavior that returns units to a pool, decrementing [Allocated] by [Count]. Admitted in every state ([Open], [Suspended], [Closed]) so in-flight allocations can be unwound. Returns a [Release Event Id]; rejected [Over Release] when [Count] > [Allocated].

Kind: Operation

#### Adjust Capacity

The behavior that revises a pool's [Capacity] to a [New Capacity] without changing [Allocated]. Permitted while not [Closed], when [New Capacity] differs from the current [Capacity] and is ≥ [Allocated]. Returns an [Adjustment Event Id]; rejected [Over Allocated] when [New Capacity] < [Allocated], [Invalid Request] on a no-op, [Closed] when the pool is closed.

Kind: Operation

#### Suspend Pool

The behavior that moves a pool [Open] → [Suspended], halting new allocations while still admitting [Release] and [Adjust Capacity]. Returns a [State Change Id]; rejected [Not Open] if already suspended, [Already Closed] if closed.

Kind: Operation

#### Resume Pool

The behavior that moves a pool [Suspended] → [Open], readmitting allocations. Returns a [State Change Id]; rejected [Not Suspended] if already open, [Already Closed] if closed.

Kind: Operation

#### Close Pool

The behavior that moves a pool to the terminal [Closed] state. New allocations and capacity adjustments are refused thereafter; [Release] is still admitted. Returns a [State Change Id]; rejected [Already Closed] if already closed.

Kind: Operation

#### Query

The read-only behavior that returns a pool's current { [Capacity], [Allocated], [Available], [State] } snapshot. It changes nothing and writes no audit-log entry.

Kind: Operation

#### Pool Id

The opaque, immutable identity of a pool, host-allocated at the I/O seam on [Declare Pool] and never reused. The declaration metadata, [Capacity], [Allocated], and [State] are properties of the pool, not its identity.

Kind:     Field
Field of: Pool
Projects: pool_id

#### Capacity

The current declared maximum total allocation a pool admits — a non-negative integer. Set on [Declare Pool], modified only by [Adjust Capacity]. The load-bearing bound: [Allocated] ≤ [Capacity] always holds (Invariant 4).

Kind:     Field
Field of: Pool
Projects: capacity

#### Allocated

The pool's current running total of consumed units — a non-negative integer. Modified only by [Allocate] (increment) and [Release] (decrement); never exceeds [Capacity] (Invariant 4) and never goes below 0 (Invariant 5).

Kind:     Field
Field of: Pool
Projects: allocated

#### Available

The derived headroom, [Capacity] − [Allocated], reported by [Query]. Recomputed from [Capacity] and [Allocated]; not stored independently.

Kind:     Field
Field of: Pool
Projects: available

#### State

The pool's lifecycle state — one of [Open], [Suspended], [Closed]. Set to [Open] on [Declare Pool]; modified only by [Suspend Pool], [Resume Pool], [Close Pool].

Kind:     Field
Field of: Pool
Projects: state

#### Declared At

The wall-time a pool was declared, stamped from the seam-injected [Now] on [Declare Pool]. Immutable thereafter.

Kind:     Field
Field of: Pool
Projects: declared_at

#### Declaring Actor Ref

The opaque reference to the actor that declared the pool. Set on [Declare Pool], immutable thereafter. Attribution only; non-repudiable proof composes with Actor Identity.

Kind:     Field
Field of: Pool
Projects: declaring_actor_ref

#### Declaration Reason

The caller-supplied reason recorded at [Declare Pool]. Immutable thereafter.

Kind:     Field
Field of: Pool
Projects: declaration_reason

#### Allocation Event Id

The opaque, immutable id of an allocation event, host-allocated at the I/O seam on each [Allocate] and individually addressable on the pool's audit log. Composing patterns key against it.

Kind:     Field
Field of: the allocation event
Projects: allocation_event_id

#### Release Event Id

The opaque, immutable id of a release event, host-allocated at the I/O seam on each [Release].

Kind:     Field
Field of: the release event
Projects: release_event_id

#### Adjustment Event Id

The opaque, immutable id of a capacity-adjustment event, host-allocated at the I/O seam on each [Adjust Capacity].

Kind:     Field
Field of: the capacity-adjustment event
Projects: adjustment_event_id

#### State Change Id

The opaque, immutable id of a state-change event, host-allocated at the I/O seam on each [Suspend Pool], [Resume Pool], or [Close Pool].

Kind:     Field
Field of: the state-change event
Projects: state_change_id

#### Count

The positive-integer number of units an [Allocate] or [Release] operates on, recorded on the resulting event. Zero is not a legitimate count.

Kind:     Field
Field of: the allocation/release event
Projects: count

#### Allocated Before

The pool's [Allocated] value immediately before an allocation or release event — the before half of the event's symmetric snapshot.

Kind:     Field
Field of: the allocation/release event
Projects: allocated_before

#### Allocated After

The pool's [Allocated] value immediately after an allocation or release event ([Allocated Before] + [Count] for allocate, − [Count] for release) — the witness that lets an auditor verify Invariant 4 or 5 per-event.

Kind:     Field
Field of: the allocation/release event
Projects: allocated_after

#### Prior Capacity

The pool's [Capacity] immediately before a capacity-adjustment event.

Kind:     Field
Field of: the capacity-adjustment event
Projects: prior_capacity

#### New Capacity

The revised [Capacity] supplied to [Adjust Capacity] and recorded on the adjustment event. Must be non-negative, differ from the current [Capacity], and be ≥ [Allocated].

Kind:     Field
Field of: the capacity-adjustment event
Projects: new_capacity

#### Prior State

The pool's [State] immediately before a state-change event.

Kind:     Field
Field of: the state-change event
Projects: prior_state

#### New State

The pool's [State] immediately after a state-change event.

Kind:     Field
Field of: the state-change event
Projects: new_state

#### Recorded At

The wall-time an event was appended to the audit log, stamped from the seam-injected [Now]. Best-effort metadata; insertion order, not timestamp order, is authoritative.

Kind:     Field
Field of: the audit-log event
Projects: recorded_at

#### Allocating Actor Ref

The opaque reference to the actor performing an [Allocate], recorded on the allocation event.

Kind:     Field
Field of: the allocation event
Projects: allocating_actor_ref

#### Releasing Actor Ref

The opaque reference to the actor performing a [Release], recorded on the release event.

Kind:     Field
Field of: the release event
Projects: releasing_actor_ref

#### Adjusting Actor Ref

The opaque reference to the actor performing an [Adjust Capacity], recorded on the adjustment event.

Kind:     Field
Field of: the capacity-adjustment event
Projects: adjusting_actor_ref

#### Acting Actor Ref

The opaque reference to the actor performing a state transition, recorded on the state-change event.

Kind:     Field
Field of: the state-change event
Projects: acting_actor_ref

#### Reason

The caller-supplied reason string recorded on a capacity-adjustment or state-change event (and, as [Declaration Reason], on the pool). Required on [Declare Pool], [Adjust Capacity], [Suspend Pool], [Resume Pool], [Close Pool]; not required on the routine [Allocate]/[Release].

Kind:     Field
Field of: the audit-log event
Projects: reason

#### Now

The current wall-clock reading, pipeline-injected at the single I/O seam (the execution contract supplies `clock_t` there) before a transition runs — never a caller-supplied action parameter. Consumed only to stamp [Declared At] and each event's [Recorded At]; no guard consults it. Not stored under this name; the stored forms are the timestamps.

Kind:         Parameter
Parameter of: Declare Pool, Allocate, Release, Adjust Capacity, Suspend Pool, Resume Pool, Close Pool
Projects:     now

#### Open

The entry and operating state: the pool accepts [Allocate] calls subject to the bound. Reached on [Declare Pool] and on [Resume Pool]; left by [Suspend Pool] or [Close Pool].

Kind:      Member
Member of: the pool state
Role:      Outcome

#### Suspended

The paused state: new [Allocate] calls are refused regardless of headroom, while [Release] and [Adjust Capacity] remain admitted. Reached by [Suspend Pool]; left by [Resume Pool] (to [Open]) or [Close Pool]. Also the rejection reason [Allocate] returns against a suspended pool — the state's own name projected as the reason's wire form.

Kind:      Member
Member of: the pool state
Role:      Outcome
Projects:  suspended

#### Closed

The terminal state: [Allocate] and [Adjust Capacity] are refused, [Release] still admitted so in-flight allocations unwind. Reached by [Close Pool]; absorbing (Invariant 3). Also the rejection reason [Allocate]/[Adjust Capacity] return against a closed pool — the state's own name projected as the reason's wire form.

Kind:      Member
Member of: the pool state
Role:      Outcome
Projects:  closed

#### Over Capacity

The refusal [Allocate] returns when [Allocated] + [Count] > [Capacity] — the allocation would breach the bound. No event is recorded; the pool remains [Open].

Kind:      Member
Member of: the Allocate rejection
Role:      Outcome
Projects:  over-capacity

#### Over Release

The refusal [Release] returns when [Count] > [Allocated] — releasing more than is allocated would drive the running total negative. No event is recorded.

Kind:      Member
Member of: the Release rejection
Role:      Outcome
Projects:  over-release

#### Over Allocated

The refusal [Adjust Capacity] returns when [New Capacity] < [Allocated] — the requested bound would put already-allocated units over capacity. No change, no event.

Kind:      Member
Member of: the Adjust Capacity rejection
Role:      Outcome
Projects:  over-allocated

#### Not Known

The refusal any [Pool Id]-taking action returns when the id references no recorded pool — a lookup miss, checked before every other precondition. After deployment-side purge it also subsumes once-declared-but-purged pools.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  not-known

#### Not Open

The refusal [Suspend Pool] returns when the pool is not in [Open] state (it is already [Suspended]).

Kind:      Member
Member of: the Suspend Pool rejection
Role:      Outcome
Projects:  not-open

#### Not Suspended

The refusal [Resume Pool] returns when the pool is not in [Suspended] state (it is [Open]).

Kind:      Member
Member of: the Resume Pool rejection
Role:      Outcome
Projects:  not-suspended

#### Already Closed

The refusal [Suspend Pool], [Resume Pool], or [Close Pool] returns when the pool is already [Closed] — terminal, no further state transitions.

Kind:      Member
Member of: the lifecycle-action rejection
Role:      Outcome
Projects:  already-closed

#### Invalid Request

The refusal any action returns when a required field is malformed — a null/empty/whitespace-only or control/zero-width/bidi-tainted string, a wrong-signed integer, or a no-op [Adjust Capacity] whose [New Capacity] equals the current [Capacity]. A field-format rejection before any arithmetic check or store write.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  invalid-request

#### Storage Failure

The refusal any action returns when the durable write fails after all preconditions pass. All-or-none: no partial record, no audit-log entry, no running-total change (Invariant 14).

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Declare Pool]: #declare-pool
[Allocate]: #allocate
[Release]: #release
[Adjust Capacity]: #adjust-capacity
[Suspend Pool]: #suspend-pool
[Resume Pool]: #resume-pool
[Close Pool]: #close-pool
[Query]: #query
[Pool Id]: #pool-id
[Capacity]: #capacity
[Allocated]: #allocated
[Available]: #available
[State]: #state
[Declared At]: #declared-at
[Declaring Actor Ref]: #declaring-actor-ref
[Declaration Reason]: #declaration-reason
[Allocation Event Id]: #allocation-event-id
[Release Event Id]: #release-event-id
[Adjustment Event Id]: #adjustment-event-id
[State Change Id]: #state-change-id
[Count]: #count
[Allocated Before]: #allocated-before
[Allocated After]: #allocated-after
[Prior Capacity]: #prior-capacity
[New Capacity]: #new-capacity
[Prior State]: #prior-state
[New State]: #new-state
[Recorded At]: #recorded-at
[Allocating Actor Ref]: #allocating-actor-ref
[Releasing Actor Ref]: #releasing-actor-ref
[Adjusting Actor Ref]: #adjusting-actor-ref
[Acting Actor Ref]: #acting-actor-ref
[Reason]: #reason
[Now]: #now
[Open]: #open
[Suspended]: #suspended
[Closed]: #closed
[Over Capacity]: #over-capacity
[Over Release]: #over-release
[Over Allocated]: #over-allocated
[Not Known]: #not-known
[Not Open]: #not-open
[Not Suspended]: #not-suspended
[Already Closed]: #already-closed
[Invalid Request]: #invalid-request
[Storage Failure]: #storage-failure

---

## Standards references

Capacity Constraint Enforcement is a utility primitive; no single regulator owns capacity enforcement directly. Its standards relevance comes through composition with regulated patterns whose audit surface relies on the running-total invariant.

- **ISO 9001:2015 §8.1 (Operational planning and control)** — the International Organization for Standardization's quality-management standard; production systems must operate within declared capacity boundaries; the atom is the structural enforcement for that obligation when the constrained resource is a production asset (manufacturing-line slots, certified-operator headroom, equipment utilization).
- **Basel III Liquidity Coverage Ratio (BCBS 238 — Basel Committee on Banking Supervision, the international body that sets bank-capital and liquidity standards)** — bank credit-line and counterparty-limit pools must be enforced as hard constraints with auditable adjustments; the atom is the operational form of a regulator-facing credit-limit headroom pool.
- **Sarbanes-Oxley §404 (Internal Control over Financial Reporting)** — where confirmed allocations against a pool are material to the books (credit-limit consumption flowing to the balance sheet, inventory allocation flowing to cost-of-goods-sold), the controls around pool adjustments and the audit trail of who-allocated-what-when become SOX-scope. Composes with Audit Trail to produce the records-alone-defensible evidence §404 attestations require.
- **PCI DSS Requirement 10 (Logging and monitoring)** — when the pool governs payment-related capacity (a payment-gateway connection pool, a card-authorization headroom pool), every successful allocation and state change must be logged with attribution; this atom's audit-log invariants supply the structural form for the successful-change surface. Req. 10.2.4 specifically requires logging of *invalid logical access attempts* (rejected calls), which this atom does not produce events for; the composing Event Log around the atom's call surface (see Composition notes → Event Log) records the rejection journal. The full PCI DSS Req. 10 obligation is satisfied by the atom + Event Log composition, not by the atom alone.
- **The Joint Commission, *Provision of Care, Treatment, and Services*** — healthcare bed-management and ward-capacity standards require capacity changes (closures for renovation, surge expansions) to be auditable with attribution and reason. The atom's adjust_capacity event-recording discipline is the operational form.
- **GDPR Article 30 (Records of processing)** — where the pool's allocation events touch personal data (per-customer credit-line pools, per-patient bed allocations referencing the patient by id), the audit log is itself a processing activity subject to controller-records obligations. Composes with Audit Trail and Retention Window for the full obligation surface.
- **Authorization-related standards (SOX §404 segregation-of-duties, HIPAA Privacy Rule §164.508 minimum-necessary, PCI DSS Requirement 7 restrict access by business need-to-know)** — these regimes require enforcement of *who may act*, not merely attribution of *who did act*. This atom records the attribution surface (`*_actor_ref`) for every successful action but does not constrain who may invoke which action; the authorization decision composes with Permissions (see *Edge cases → Authorization* and the Permissions Composition note). Composing with Permissions and Actor Identity together produces the *was-permitted-and-was-attested* surface these standards require — Permissions for the decision that admitted the call, Actor Identity for the non-repudiable record of who the decision admitted.

The atom inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture and the explicit refusal to absorb per-allocation identity, fairness policy, preemption, and overcommit.
- **Eiffel's design-by-contract** — preconditions on each action, named rejection reasons, and the *preserve-by-precondition* discipline (rejecting actions that would violate an invariant rather than silently clamping).
- **Database connection pooling and operating-system semaphore conventions** — the count-up / count-down arithmetic the atom abstracts; here exposed as visible business state rather than hidden inside a transactional or kernel primitive.
- **Token-bucket and leaky-bucket rate-limiter constructions** — for the kinship the atom has with rate-limit enforcement; the rate-limit pattern is a sibling primitive with time-varying capacity rather than a fixed bound.

---

## Status

`grounded on Final Critique 8 — 2026-08-26` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 8 — 2026-08-26
formal: verified — capacity-constraint-enforcement.tla + 2 twins, 2026-06-04
last gate: 2026-08-26 — Final Critique 8, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/capacity-constraint-enforcement.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.36; nothing but language changed.** *Chose:* the eight actions as a signature block, the fourteen invariant numbers unchanged, the six acceptance areas opened into `Check 1.1 through 6.1` with three External checks for what the store cannot answer, the arithmetic routed through declared requested total and released total so no rule carries a sum, the three host obligations Invariant 4 rests on given their own families (`Concurrency`, `Crash atomicity`, `Arithmetic`). *Over:* the prose spec. *Because:* the migration plan; nothing cites this atom by label. The open question this atom was picked to answer — whether a domain whose logic *is* arithmetic survives Hard invariant 24 — answers yes: `MUST NOT EXCEED` and `EXCEEDS` carry every comparison directly, and only the two sums needed names.

NOTE: End of Capacity Constraint Enforcement.
