---
title: Capacity Constraint Enforcement
id: 33
audience: common
---

# Capacity Constraint Enforcement

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Capacity Constraint Enforcement holds one number against another. A pool declares a maximum, tracks a running total, and refuses any allocation that would push the total past the bound. Units are fungible (interchangeable: no unit is told apart from another) — five units allocated is one event carrying the count, not five records — so this atom (a small building-block pattern that owns one obligation) owns the arithmetic and nothing else.

A pool is [Open], [Suspended] or [Closed]. Suspending halts new allocations without unwinding the existing ones; closing is terminal. [Release] is admitted in every state, including [Closed], so a composing pattern (another pattern built on top of this one) can unwind in-flight allocations after the pool is shut.

Every successful change after the declaration appends an attributed event carrying before-and-after snapshots, so an auditor can check each event's arithmetic from that event alone rather than replaying the whole log, and the bound at an allocation against the capacity in force then, which the declaration and the adjustments before it set. Rejections write nothing, which is a deliberate boundary rather than an omission.

This is the mechanism behind seat inventory, credit headroom, ward beds, connection pools and warehouse stock. It does not decide who may allocate, what a unit means, or what happens when the pool runs dry.

<details markdown="block">
<summary>WHY</summary>

A bounded resource needs one place that owns the bound. Without it, every caller defends the limit at its own call site, and the limit is then enforced in as many slightly different ways as there are callers — which is how an airline oversells a cabin, a credit line goes past its ceiling, and a connection pool exhausts a database.

So the atom owns exactly the arithmetic: a declared maximum, a running total, and the refusal that keeps one under the other. Everything that looks adjacent is deliberately outside. Which unit is which belongs to a pattern that holds each allocation as a record of its own, because per-allocation identity is a different grain. Who may allocate belongs to the app's permission. What happens when the pool drains belongs to the app that subscribes readers and notifies them. Fairness under contention belongs to a queueing pattern. Each of those is a policy; this is the invariant they all rest on.

Two design commitments carry the rest. **Drained is not a state** — allocated reaching capacity is an arithmetic condition, observable through [Query] and enforced by the allocate guard, and promoting it to a state would conflate a policy decision (an operator halting allocations) with a number reaching another number. And **the atom never clamps.** A capacity adjustment below the running total is refused, not silently fitted; a release beyond the total is refused, not floored at zero. Clamping would keep the invariant true and destroy the caller's ability to know it was violated.

</details>

## What it keeps

### The pools

```
Identity 1: The atom MUST identify a pool by the pool id.
Identity 2: The atom MUST identify an audit event by the audit event id.
Identity 3: The deployment MUST allocate a pool id at the seam.
Identity 4: The deployment MUST allocate an audit event id at the seam.
Identity 7: The atom MUST NOT change a pool id.
Identity 8: The atom MUST NOT change an audit event id.
Identity 9: The atom MUST NOT identify a pool by a pool's name.
Identity 10: The atom MUST match a pool id byte for byte.
Identity 12: The atom MUST NOT order a pool id.
Identity 13: [Declare Pool] MUST NOT write over a pool the database already holds.
Identity 14: IF a colliding write EXISTS THEN the database MUST refuse the colliding write.
Identity 15: The deployment MUST draw a pool id unique across the system's life.
Identity 16: The deployment MUST draw an audit event id unique across the system's life.
Identity 17: The deployment MUST NOT reuse an audit event id across the event classes.
Identity 18: The atom MUST NOT hold a per-unit identity.
```

Term pool: one bounded resource with a declared maximum and a running total — the record this atom holds.

Term pool id: the opaque value naming one pool — a [Pool Id]; deployment-allocated at the seam, compared by exact byte identity.

Term audit event id: the opaque value naming one audit event — an [Allocation Event Id], a [Release Event Id], an [Adjustment Event Id] or a [State Change Id], by the event's class.

Term event class: allocation | release | adjustment | state change — the four kinds of entry the audit log carries.

```
State 1: EVERY pool MUST stand in EXACTLY ONE OF open, suspended, closed.
State 2: EVERY pool MUST carry pool id, capacity, allocated, a pool state, declaration instant, declaring actor reference and declaration reason.
State 3: EVERY pool MUST carry an audit log.
State 4: A pool MUST NOT carry available.
State 5: The atom MUST NOT offer a transition out of closed.
State 6: The atom MUST NOT offer a drained state.
State 7: The atom MUST NOT remove a pool from the database.
State 8: The atom MUST NOT remove an audit event from a pool's audit log.
State 9: The atom MUST NOT re-order a pool's audit log.
State 10: The atom MUST NOT insert an audit event BEFORE a prior audit event.
State 11: The atom MUST order a pool's audit log by insertion.
State 12: An audit-log read MUST read a pool's audit log by insertion order.
State 13: An audit-log read MUST NOT read a pool's audit log by recording instant order.
State 14: EVERY audit event MUST carry an audit event id, the pool id, an event class and a recording instant.
State 15: EVERY allocation event MUST carry count, opening balance, closing balance and allocating actor reference.
State 16: EVERY release event MUST carry count, opening balance, closing balance and releasing actor reference.
State 17: EVERY adjustment event MUST carry prior capacity, new capacity, adjusting actor reference and a reason.
State 18: EVERY state-change event MUST carry prior state, new state, acting actor reference and a reason.
State 19: The atom MUST NOT change a declaration field.
State 20: The atom MUST NOT change an audit event's audit-identifier surface.
State 21: The atom MUST NOT hold a per-allocation life cycle.
State 22: The atom MUST NOT hold a cross-pool bound.
State 23: The atom MUST NOT interpret a unit.
```

Term audit-log read: a read of a pool's audit log through the pool records the deployment supplies (Capability requirement 5) — the auditor's read for the checks below, and no action of the atom, since [Query] answers the pool snapshot and deliberately not the log.

Term declaration field: pool id | declaration instant | declaring actor reference | declaration reason — set at [Declare Pool] and never changed.

Term state change pair: open to suspended | suspended to open | open to closed | suspended to closed — the four moves a state-change event's prior state and new state may record (Operation 41, Operation 44, Operation 46).

Term opening balance: the running total an audit event found — an [Opening Balance].

Term closing balance: the running total an audit event left — an [Closing Balance]; the requested total on an allocation event, the released total on a release event.

Term recording instant: the instant an audit event was written — a [Recording Instant]; stamped from the injected now, and advisory rather than authoritative for order.

Term audit-identifier surface: an audit event's audit event id, pool id, event class, arithmetic fields ([Opening Balance], [Count], [Closing Balance], [Prior Capacity], [New Capacity]), state fields ([Prior State], [New State]) and recording instant — everything the atom never rewrites and the arithmetic chain rests on.

Term attribution surface: an audit event's actor reference ([Allocating Actor Reference], [Releasing Actor Reference], [Adjusting Actor Reference] or [Acting Actor Reference]) and [Reason], and a pool's [Declaring Actor Reference] and [Declaration Reason] — what makes a record personally identifying, and what a composed erasure mechanism may scrub; the pool id and the declaration instant are not on it.

Term suspending actor reference: the [Suspend Pool] input the state-change event keeps as acting actor reference — a [Suspending Actor Reference].

Term resuming actor reference: the [Resume Pool] input the state-change event keeps as acting actor reference — a [Resuming Actor Reference].

Term closing actor reference: the [Close Pool] input the state-change event keeps as acting actor reference — a [Closing Actor Reference].

Term declaration instant: the instant a pool was declared — a [Declaration Instant]; stamped from the injected now at [Declare Pool] (Operation 5).

Term declaring actor reference: the actor reference [Declare Pool] records on the pool — a [Declaring Actor Reference]; a declaration field, and on the attribution surface.

Term declaration reason: the reason [Declare Pool] records on the pool — a [Declaration Reason]; a declaration field, and on the attribution surface.

Term allocation event id: the audit event id an [Allocate] call answers — an [Allocation Event Id].

Term release event id: the audit event id a [Release] call answers — a [Release Event Id].

Term adjustment event id: the audit event id an [Adjust Capacity] call answers — an [Adjustment Event Id].

Term state change id: the audit event id a state-changing action answers — a [State Change Id].

Term prior capacity: the capacity an adjustment event found — a [Prior Capacity].

Term prior state: the pool state a state-change event found — a [Prior State].

Term new state: the pool state a state-change event left — a [New State].

Term allocating actor reference: the [Allocate] input an allocation event keeps — an [Allocating Actor Reference].

Term releasing actor reference: the [Release] input a release event keeps — a [Releasing Actor Reference].

Term adjusting actor reference: the [Adjust Capacity] input an adjustment event keeps — an [Adjusting Actor Reference].

Term acting actor reference: the actor reference a state-change event keeps — an [Acting Actor Reference]; the suspending, resuming or closing actor reference by the action.

#### Pool

One bounded resource with a declared capacity and a running total, carrying the declaration fields and an audit log of [Audit Event]s.

Kind: Type

#### Pool Snapshot

What a query answers: the capacity, the allocated, the available and the pool state together.

Kind: Type

#### Pool Id

The opaque, immutable identity of a pool, deployment-allocated at the I/O seam on [Declare Pool] and never reused. The declaration metadata, [Capacity], [Allocated], and [State] are properties of the pool, not its identity.

Kind:       Field
Field of:   Pool
Projection: pool_id

#### Capacity

The current declared maximum total allocation a pool admits — a non-negative integer within the deployment's integer width (Arithmetic 4, Arithmetic 5). Set on [Declare Pool], modified only by [Adjust Capacity]. The load-bearing bound: [Allocated] ≤ [Capacity] always holds (Invariant 4).

Kind:       Field
Field of:   Pool
Projection: capacity

#### Allocated

The pool's current running total of consumed units — a non-negative integer. Modified only by [Allocate] (increment) and [Release] (decrement); never exceeds [Capacity] (Invariant 4) and never goes below 0 (Invariant 5).

Kind:       Field
Field of:   Pool
Projection: allocated

#### Available

The derived headroom, [Capacity] − [Allocated], of a [Pool] reported by [Query] in the [Pool Snapshot]. Recomputed from [Capacity] and [Allocated]; not stored independently.

Kind:       Field
Field of:   Pool Snapshot
Projection: available

#### State

The pool's lifecycle state — one of [Open], [Suspended], [Closed]. Set to [Open] on [Declare Pool]; modified only by [Suspend Pool], [Resume Pool], [Close Pool].

Kind:       Field
Field of:   Pool
Projection: state

#### Declaration Instant

The wall-time a pool was declared, stamped from the seam-injected [Now] on [Declare Pool]. Immutable thereafter.

Kind:       Field
Field of:   Pool
Projection: declared_at

#### Declaring Actor Reference

The opaque reference to the actor that declared the pool. Set on [Declare Pool], immutable thereafter. Attribution only; non-repudiable proof is an attestation pattern's.

Kind:       Field
Field of:   Pool
Projection: declaring_actor_ref

#### Declaration Reason

The caller-supplied reason recorded at [Declare Pool]. Immutable thereafter.

Kind:       Field
Field of:   Pool
Projection: declaration_reason

#### Open

The entry and operating state: the pool accepts [Allocate] calls subject to the bound. Reached on [Declare Pool] and on [Resume Pool]; left by [Suspend Pool] or [Close Pool].

Kind:      Member
Member of: the pool state
Role:      Outcome

#### Suspended

The paused state: new [Allocate] calls are refused regardless of headroom, while [Release] and [Adjust Capacity] remain admitted. Reached by [Suspend Pool]; left by [Resume Pool] (to [Open]) or [Close Pool]. Also the rejection reason [Allocate] returns against a suspended pool — the state's own name projected as the reason's wire form.

Kind:       Member
Member of:  the pool state
Role:       Outcome
Projection: suspended

#### Closed

The terminal state: [Allocate] and [Adjust Capacity] are refused, [Release] still admitted so in-flight allocations unwind. Reached by [Close Pool]; absorbing (Invariant 3). Also the rejection reason [Allocate]/[Adjust Capacity] return against a closed pool — the state's own name projected as the reason's wire form.

Kind:       Member
Member of:  the pool state
Role:       Outcome
Projection: closed

Term available: `(capacity - allocated)` — an [Available]; computed wherever it is reported and never stored, so it cannot lag its operands.

Term count: the units one [Allocate] or [Release] call operates on — a [Count]; a positive count.

Term new capacity: the maximum an [Adjust Capacity] call asks for — a [New Capacity]; a whole count, and refused where it equals the current capacity.

Term pool snapshot: capacity, allocated, available and the pool state together — what [Query] answers, and deliberately not the declaration fields or the audit log.

Term audit event: one entry on a pool's log — an allocation, a release, an adjustment or a state change, each carrying its own audit event id and a recording instant.

Term state: the pool state the pool holds as a field — a [State].

Term reason: the caller-supplied reason an adjustment event, a state-change event or the declaration keeps — a [Reason], and a [Declaration Reason] on the pool.

Term capacity: the declared maximum a pool admits — a [Capacity]; a whole count, set at declaration and changed only by [Adjust Capacity].

Term allocated: the pool's running total — an [Allocated]; changed only by [Allocate] and [Release].

### The audit events

#### Audit Event

One entry on a pool's audit log: an allocation, a release, an adjustment or a state change.

Kind: Type

#### Allocation Event Id

The opaque, immutable id of an allocation event, deployment-allocated at the I/O seam on each [Allocate] and individually addressable on the pool's audit log. Composing patterns key against it.

Kind:       Field
Field of:   Audit Event
Projection: allocation_event_id

#### Release Event Id

The opaque, immutable id of a release event, deployment-allocated at the I/O seam on each [Release].

Kind:       Field
Field of:   Audit Event
Projection: release_event_id

#### Adjustment Event Id

The opaque, immutable id of a capacity-adjustment event, deployment-allocated at the I/O seam on each [Adjust Capacity].

Kind:       Field
Field of:   Audit Event
Projection: adjustment_event_id

#### State Change Id

The opaque, immutable id of a state-change event, deployment-allocated at the I/O seam on each [Suspend Pool], [Resume Pool], or [Close Pool].

Kind:       Field
Field of:   Audit Event
Projection: state_change_id

#### Count

The positive-integer number of units an [Allocate] or [Release] operates on, within the deployment's integer width, recorded on the resulting event. Zero is not a legitimate count.

Kind:       Field
Field of:   Audit Event
Projection: count

#### Opening Balance

The pool's [Allocated] value immediately before an allocation or release event — the before half of the event's symmetric snapshot.

Kind:       Field
Field of:   Audit Event
Projection: allocated_before

#### Closing Balance

The pool's [Allocated] value immediately after an allocation or release event ([Opening Balance] + [Count] for allocate, − [Count] for release) — the witness that lets an auditor verify Invariant 5 per event, and Invariant 4 against the capacity in effect at the event (Check 3.2).

Kind:       Field
Field of:   Audit Event
Projection: allocated_after

#### Prior Capacity

The pool's [Capacity] immediately before a capacity-adjustment event.

Kind:       Field
Field of:   Audit Event
Projection: prior_capacity

#### New Capacity

The revised [Capacity] supplied to [Adjust Capacity] and recorded on the adjustment event. Must be non-negative and within the deployment's integer width, differ from the current [Capacity], and be ≥ [Allocated].

Kind:       Field
Field of:   Audit Event
Projection: new_capacity

#### Prior State

The pool's [State] immediately before a state-change event.

Kind:       Field
Field of:   Audit Event
Projection: prior_state

#### New State

The pool's [State] immediately after a state-change event.

Kind:       Field
Field of:   Audit Event
Projection: new_state

#### Recording Instant

The wall-time an event was appended to the audit log, stamped from the seam-injected [Now]. Best-effort metadata; insertion order, not timestamp order, is authoritative.

Kind:       Field
Field of:   Audit Event
Projection: recorded_at

#### Allocating Actor Reference

The opaque reference to the actor performing an [Allocate], recorded on the allocation event.

Kind:       Field
Field of:   Audit Event
Projection: allocating_actor_ref

#### Releasing Actor Reference

The opaque reference to the actor performing a [Release], recorded on the release event.

Kind:       Field
Field of:   Audit Event
Projection: releasing_actor_ref

#### Adjusting Actor Reference

The opaque reference to the actor performing an [Adjust Capacity], recorded on the adjustment event.

Kind:       Field
Field of:   Audit Event
Projection: adjusting_actor_ref

#### Acting Actor Reference

The opaque reference to the actor performing a state transition, recorded on the state-change event.

Kind:       Field
Field of:   Audit Event
Projection: acting_actor_ref

#### Reason

The caller-supplied reason string recorded on a capacity-adjustment or state-change event (and, as [Declaration Reason], on the pool). Required on [Declare Pool], [Adjust Capacity], [Suspend Pool], [Resume Pool], [Close Pool]; not required on the routine [Allocate]/[Release].

Kind:       Field
Field of:   Audit Event
Projection: reason

## What people do

### Every action

```
Operation 8: IF the pool id names no pool THEN an addressed action MUST answer not-known.
Operation 9: An addressed action MUST answer not-known ONLY IF the pool id names no pool.
Operation 47: A state-changing action MUST append a state-change event.
Operation 48: A state-changing action MUST answer the state change id.
Operation 49: A state-changing action MUST NOT change allocated.
Operation 50: A state-changing action MUST NOT change capacity.
Operation 57: IF the database refuses a write THEN a writing action MUST answer storage-failure.
Operation 58: A refused action MUST leave the pool as the call found the pool.
Operation 59: A refused action MUST NOT append an audit event.
```

Term whole count: a count of zero or more; what capacity and new capacity must be.

Term positive count: a count of one or more within the integer width; what count must be, which is why a zero-unit call is refused rather than admitted as a no-op.

Term requested total: `(allocated + count)` — the running total an [Allocate] call would reach, and the value the capacity guard compares.

Term released total: `(allocated - count)` — the running total a [Release] call would reach.

Term addressed action: any action carrying a pool id — every action but [Declare Pool] and [Read Audit Event].

Term state-changing action: [Suspend Pool] | [Resume Pool] | [Close Pool] — the three that move a pool's state.

Term writing action: every action but [Query] and [Read Audit Event].

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the pool |
|---|---|---|---|
| any state change | already in the target state, or [Closed] | [Not Open], [Not Suspended], [Already Closed] | none (Operation 39, Operation 40, Operation 42, Operation 43, Operation 45) |
| any addressed action | id names nothing | [Not Known] | none (Operation 8) |
| any writing action | database refuses | [Storage Failure] | none (Operation 57 through 59) |

#### Not Known

The refusal any [Pool Id]-taking action returns when the id references no recorded pool — a lookup miss, checked before every other precondition — and [Read Audit Event] returns when the audit event id names no audit event (Operation 67). After deployment-side purge it also subsumes once-declared-but-purged pools and purged audit events.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Already Closed

The refusal [Suspend Pool], [Resume Pool], or [Close Pool] returns when the pool is already [Closed] — terminal, no further state transitions.

Kind:       Member
Member of:  the lifecycle-action rejection
Role:       Outcome
Projection: already-closed

#### Invalid Request

The refusal any action returns when a required field is malformed — a null/empty/whitespace-only, over-long or control/zero-width/bidi-tainted string, a wrong-signed integer, or a capacity, a count or a requested total past the deployment's integer width, or a no-op [Adjust Capacity] whose [New Capacity] equals the current [Capacity]. A field-format rejection, answered after [Not Known] and the pool's state and before any bound refusal (over-capacity, over-release or over-allocated) or database write (Execution Contract Refusal 1).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Storage Failure

The refusal any action returns when the durable write fails after all preconditions pass. No partial record, no audit-log entry, no running-total change (Operation 58, Operation 59).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Declare Pool

#### Declare Pool

The behavior that creates a new bounded pool. It records the supplied [Capacity], [Declaring Actor Reference], and [Declaration Reason], enters the pool in [Open] with [Allocated] = 0, stamps [Declaration Instant], and returns the fresh [Pool Id].

Kind: Operation

```
declare_pool(capacity, declaring_actor_ref, reason)
  answers pool_id
  refuses invalid-request | storage-failure
```

```
Operation 1: [Declare Pool] MUST record EXACTLY ONE pool per successful call.
Operation 2: [Declare Pool] MUST stand the pool in open.
Operation 3: [Declare Pool] MUST set allocated to zero.
Operation 4: [Declare Pool] MUST set capacity to the supplied capacity.
Operation 5: [Declare Pool] MUST stamp declaration instant from the injected now.
Operation 6: [Declare Pool] MUST answer the pool id.
Operation 7: IF capacity IS NOT IN the whole counts THEN [Declare Pool] MUST answer invalid-request.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the pool |
|---|---|---|---|
| [Declare Pool] | capacity a whole count within the integer width, fields valid, database accepts | the new pool id | pool lands in [Open], allocated zero, and no declaration field changes afterward (Operation 1 through 5, Invariant 7.1) |
| [Declare Pool] | capacity not a whole count or past the integer width, or a field invalid | [Invalid Request] | none (Operation 7, Arithmetic 4, String 2) |

### Allocate

#### Allocate

The behavior that consumes units against a pool, incrementing [Allocated] by [Count] when the pool is [Open] and the bound admits it. Returns an [Allocation Event Id]. Rejected [Over Capacity] when [Allocated] + [Count] > [Capacity], [Suspended] or [Closed] when the pool is not [Open].

Kind: Operation

```
allocate(pool_id, count, allocating_actor_ref)
  answers allocation_event_id
  refuses not-known | suspended | closed | invalid-request | over-capacity | storage-failure
```

```
Operation 10: IF the pool state EQUALS suspended THEN [Allocate] MUST answer suspended.
Operation 11: IF the pool state EQUALS closed THEN [Allocate] MUST answer closed.
Operation 12: IF count IS NOT IN the positive counts THEN [Allocate] MUST answer invalid-request.
Operation 13: IF the requested total EXCEEDS capacity THEN [Allocate] MUST answer over-capacity.
Operation 15: [Allocate] MUST raise allocated to the requested total.
Operation 16: [Allocate] MUST append an allocation event.
Operation 17: [Allocate] MUST answer the allocation event id.
Operation 18: [Allocate] MUST NOT change capacity.
Operation 19: [Allocate] MUST NOT change the pool's state.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the pool |
|---|---|---|---|
| [Allocate] | [Open], count positive, requested total within capacity | the allocation event id | allocated rises, one event appended; the pool id and the audit event id stand once recorded (Operation 15 through 17, Invariant 12.1, Invariant 12.2) |
| [Allocate] | [Open], count not positive or past the integer width, or requested total past the integer width | [Invalid Request] | none (Operation 12, Arithmetic 3) |
| [Allocate] | [Open], requested total past capacity | [Over Capacity] | none (Operation 13) |
| [Allocate] | [Suspended] | [Suspended] | none (Operation 10) |
| [Allocate] | [Closed] | [Closed] | none (Operation 11) |

`allocate(pool_a1, count: 0, ...)` → invalid-request. A zero-unit allocation is not a use of the action (Operation 12).

`allocate(pool_x, count: 1, ...)` where `pool_x` names nothing → not-known — which covers both *never declared* and *declared, closed, and since purged under a composed retention pattern*. The atom cannot tell them apart and does not pretend to (Operation 8, Invariant 1.1).

`allocate(pool_closed, count: -5, ...)` against a closed pool → closed, not invalid-request. State precedes format on [Allocate]'s refuses line (Execution Contract Refusal 1), and the caller learns about the count on retry against a live pool.

#### Over Capacity

The refusal [Allocate] returns when [Allocated] + [Count] > [Capacity] — the allocation would breach the bound. No event is recorded; the pool remains [Open].

Kind:       Member
Member of:  the Allocate rejection
Role:       Outcome
Projection: over-capacity

### Release

#### Release

The behavior that returns units to a pool, decrementing [Allocated] by [Count]. Admitted in every state ([Open], [Suspended], [Closed]) so in-flight allocations can be unwound. Returns a [Release Event Id]; rejected [Over Release] when [Count] > [Allocated].

Kind: Operation

```
release(pool_id, count, releasing_actor_ref)
  answers release_event_id
  refuses not-known | invalid-request | over-release | storage-failure
```

```
Operation 20: [Release] MUST admit a call in EVERY pool state.
Operation 21: IF count IS NOT IN the positive counts THEN [Release] MUST answer invalid-request.
Operation 22: IF count EXCEEDS allocated THEN [Release] MUST answer over-release.
Operation 23: [Release] MUST lower allocated to the released total.
Operation 24: [Release] MUST append a release event.
Operation 25: [Release] MUST answer the release event id.
Operation 26: [Release] MUST NOT change capacity.
Operation 27: [Release] MUST NOT change the pool's state.
Operation 28: [Release] MUST NOT match a count against a prior allocation's count.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the pool |
|---|---|---|---|
| [Release] | any state, count positive and within allocated | the release event id | allocated falls, one event appended; the pool id and the audit event id stand once recorded (Operation 20, Operation 23, Invariant 12.1, Invariant 12.2) |
| [Release] | count not positive or past the integer width | [Invalid Request] | none (Operation 21) |
| [Release] | count past allocated | [Over Release] | none (Operation 22) |

#### Over Release

The refusal [Release] returns when [Count] > [Allocated] — releasing more than is allocated would drive the running total negative. No event is recorded.

Kind:       Member
Member of:  the Release rejection
Role:       Outcome
Projection: over-release

### Adjust Capacity

#### Adjust Capacity

The behavior that revises a pool's [Capacity] to a [New Capacity] without changing [Allocated]. Permitted while not [Closed], when [New Capacity] differs from the current [Capacity] and is ≥ [Allocated]. Returns an [Adjustment Event Id]; rejected [Over Allocated] when [New Capacity] < [Allocated], [Invalid Request] on a no-op, [Closed] when the pool is closed.

Kind: Operation

```
adjust_capacity(pool_id, new_capacity, adjusting_actor_ref, reason)
  answers adjustment_event_id
  refuses not-known | closed | invalid-request | over-allocated | storage-failure
```

```
Operation 29: IF the pool state EQUALS closed THEN [Adjust Capacity] MUST answer closed.
Operation 30: IF new capacity IS NOT IN the whole counts THEN [Adjust Capacity] MUST answer invalid-request.
Operation 31: IF new capacity EQUALS capacity THEN [Adjust Capacity] MUST answer invalid-request.
Operation 32: IF allocated EXCEEDS new capacity THEN [Adjust Capacity] MUST answer over-allocated.
Operation 33: [Adjust Capacity] MUST set capacity to new capacity.
Operation 34: [Adjust Capacity] MUST append an adjustment event.
Operation 35: [Adjust Capacity] MUST answer the adjustment event id.
Operation 36: [Adjust Capacity] MUST NOT change allocated.
Operation 37: [Adjust Capacity] MUST NOT set capacity to allocated in place of answering over-allocated.
Operation 38: [Adjust Capacity] MUST NOT release a unit to fit a lower capacity.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the pool |
|---|---|---|---|
| [Adjust Capacity] | [Open] or [Suspended], new value a whole count within the integer width that differs and covers allocated | the adjustment event id | capacity replaced, one event appended; the pool id and the audit event id stand once recorded (Operation 33, Operation 34, Invariant 12.1, Invariant 12.2) |
| [Adjust Capacity] | new value equals current | [Invalid Request] | none (Operation 31) |
| [Adjust Capacity] | new value not a whole count, or past the integer width | [Invalid Request] | none (Operation 30, Arithmetic 5) |
| [Adjust Capacity] | new value a whole count below allocated | [Over Allocated] | none (Operation 32) |
| [Adjust Capacity] | [Closed] | [Closed] | none (Operation 29) |

`adjust_capacity(pool_a1, new_capacity: 180, ...)` where capacity is already 180 → invalid-request. A no-op adjustment would append an event recording no change (Operation 31).

#### Over Allocated

The refusal [Adjust Capacity] returns when [New Capacity] < [Allocated] — the requested bound would put already-allocated units over capacity. No change, no event.

Kind:       Member
Member of:  the Adjust Capacity rejection
Role:       Outcome
Projection: over-allocated

### Suspend Pool

#### Suspend Pool

The behavior that moves a pool [Open] → [Suspended], halting new allocations while still admitting [Release] and [Adjust Capacity]. Returns a [State Change Id]; rejected [Not Open] if already suspended, [Already Closed] if closed.

Kind: Operation

```
suspend_pool(pool_id, suspending_actor_ref, reason)
  answers state_change_id
  refuses not-known | not-open | already-closed | invalid-request | storage-failure
```

```
Operation 39: IF the pool state EQUALS suspended THEN [Suspend Pool] MUST answer not-open.
Operation 40: IF the pool state EQUALS closed THEN [Suspend Pool] MUST answer already-closed.
Operation 41: [Suspend Pool] MUST stand the pool in suspended.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the pool |
|---|---|---|---|
| [Suspend Pool] | [Open] | the state change id | → [Suspended]; the pool id stands (Operation 41, Invariant 12.1) |

#### Suspending Actor Reference

The opaque reference to the actor performing a [Suspend Pool], the input the state-change event keeps as its [Acting Actor Reference].

Kind:         Parameter
Parameter of: Suspend Pool
Projection:   suspending_actor_ref

#### Not Open

The refusal [Suspend Pool] returns when the pool is already [Suspended]; a closed pool answers [Already Closed].

Kind:       Member
Member of:  the Suspend Pool rejection
Role:       Outcome
Projection: not-open

### Resume Pool

#### Resume Pool

The behavior that moves a pool [Suspended] → [Open], readmitting allocations. Returns a [State Change Id]; rejected [Not Suspended] if already open, [Already Closed] if closed.

Kind: Operation

```
resume_pool(pool_id, resuming_actor_ref, reason)
  answers state_change_id
  refuses not-known | not-suspended | already-closed | invalid-request | storage-failure
```

```
Operation 42: IF the pool state EQUALS open THEN [Resume Pool] MUST answer not-suspended.
Operation 43: IF the pool state EQUALS closed THEN [Resume Pool] MUST answer already-closed.
Operation 44: [Resume Pool] MUST stand the pool in open.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the pool |
|---|---|---|---|
| [Resume Pool] | [Suspended] | the state change id | → [Open]; the pool id stands (Operation 44, Invariant 12.1) |

#### Resuming Actor Reference

The opaque reference to the actor performing a [Resume Pool], the input the state-change event keeps as its [Acting Actor Reference].

Kind:         Parameter
Parameter of: Resume Pool
Projection:   resuming_actor_ref

#### Not Suspended

The refusal [Resume Pool] returns when the pool is [Open]; a closed pool answers [Already Closed].

Kind:       Member
Member of:  the Resume Pool rejection
Role:       Outcome
Projection: not-suspended

### Close Pool

#### Close Pool

The behavior that moves a pool to the terminal [Closed] state. New allocations and capacity adjustments are refused thereafter; [Release] is still admitted. Returns a [State Change Id]; rejected [Already Closed] if already closed.

Kind: Operation

```
close_pool(pool_id, closing_actor_ref, reason)
  answers state_change_id
  refuses not-known | already-closed | invalid-request | storage-failure
```

```
Operation 45: IF the pool state EQUALS closed THEN [Close Pool] MUST answer already-closed.
Operation 46: [Close Pool] MUST stand the pool in closed.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the pool |
|---|---|---|---|
| [Close Pool] | [Open] or [Suspended] | the state change id | → [Closed]; the pool id stands (Operation 46, Invariant 12.1) |

#### Closing Actor Reference

The opaque reference to the actor performing a [Close Pool], the input the state-change event keeps as its [Acting Actor Reference].

Kind:         Parameter
Parameter of: Close Pool
Projection:   closing_actor_ref

### Query

#### Query

The read-only behavior that returns a pool's current { [Capacity], [Allocated], [Available], [State] } snapshot. It changes nothing and writes no audit-log entry.

Kind: Operation

```
query(pool_id)
  answers pool_snapshot
  refuses not-known
```

```
Operation 51: [Query] MUST answer the pool snapshot.
Operation 52: [Query] MUST NOT write.
Operation 53: [Query] MUST NOT append an audit event.
Operation 54: [Query] MUST admit a call in EVERY pool state.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the pool |
|---|---|---|---|
| [Query] | id names a pool, any state | the pool snapshot | none (Operation 51, Operation 54) |

### Read Audit Event

#### Read Audit Event

Answers one audit event by its audit event id and changes nothing: the audit event id, the pool id, the event class, the recording instant and the fields the event's class carries. It is the read an app's key check makes on an audit event id (Bonds Key 26); the pool's audit log as a whole stays the audit-log read's, outside the atom.

Kind: Operation

```
read_audit_event(audit_event_id)
  answers audit_event
  refuses not-known
```

```
Operation 65: [Read Audit Event] MUST answer the audit event the audit event id names, every field State 14 through 18 name included.
Operation 66: [Read Audit Event] MUST NOT write.
Operation 67: IF the audit event id names no audit event THEN [Read Audit Event] MUST answer not-known.
Operation 68: [Read Audit Event] MUST answer not-known ONLY IF the audit event id names no audit event.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the pool |
|---|---|---|---|
| [Read Audit Event] | an audit event carries the audit event id | the audit event, every field | none (Operation 65, Operation 66) |
| [Read Audit Event] | the audit event id names no audit event | [Not Known] | none (Operation 67, Operation 68) |

## What is and what should never be (Invariants)

- **Invariant 1 — Pool record permanence under this atom's actions.**
  ```
  Invariant 1.1: The atom MUST NOT offer an action that removes a pool.
  Invariant 1.2: The count of pools MUST NOT fall under the atom's actions.
  ```
- **Invariant 2 — State membership exclusivity.**
  ```
  Invariant 2.1: EVERY pool MUST stand in EXACTLY ONE OF open, suspended, closed.
  ```
- **Invariant 3 — Closed is absorbing for state and for new allocation.**
  ```
  Invariant 3.1: A closed pool MUST NOT leave closed.
  Invariant 3.2: A pool's audit log MUST NOT carry an allocation event later in insertion order than a state-change event whose new state EQUALS closed.
  Invariant 3.3: A pool's audit log MUST NOT carry an adjustment event later in insertion order than a state-change event whose new state EQUALS closed.
  Invariant 3.4: [Release] MUST stand as the one writing action a closed pool admits.
  ```
- **Invariant 4 — Capacity constraint.**
  ```
  Invariant 4.1: EVERY pool's allocated MUST NOT EXCEED the capacity.
  Invariant 4.4: Invariant 4.1 MUST rest on the deployment obligations Capability requirement 5 and Execution Contract Logic confinement 9 name.
  ```
- **Invariant 5 — Non-negativity.**
  ```
  Invariant 5.1: EVERY pool's allocated MUST NOT fall below zero.
  Invariant 5.3: Invariant 5.1 MUST rest on the deployment obligations Invariant 4.4 names.
  ```
- **Invariant 6 — Capacity non-negativity.**
  ```
  Invariant 6.1: EVERY pool's capacity MUST stand as a whole count.
  ```
- **Invariant 7 — Declaration fields immutable.**
  ```
  Invariant 7.1: The atom MUST NOT offer an action that changes a declaration field.
  ```
- **Invariant 8 — An audit event has two surfaces with distinct lifetimes.**
  ```
  Invariant 8.1: The atom MUST NOT offer an action that changes an audit-identifier surface.
  Invariant 8.2: The atom MUST NOT offer an action that changes an attribution surface.
  Invariant 8.3: An audit-identifier surface MUST stand for as long as the audit event stands.
  Invariant 8.4: A composed erasure mechanism MAY scrub an attribution surface.
  Invariant 8.5: An arithmetic reconstruction MUST NOT rest on an attribution surface.
  Invariant 8.6: An attribution surface a composed erasure mechanism scrubbed MUST stand as carried by EVERY rule that obliges a pool or an audit event to carry the attribution surface.
  ```
- **Invariant 9 — Audit log append-only under this atom's actions.**
  ```
  Invariant 9.1: The atom MUST NOT offer an action that removes an audit event.
  Invariant 9.2: The atom MUST NOT offer an action that re-orders an audit log.
  Invariant 9.3: An audit log's length MUST NOT fall under the atom's actions.
  Invariant 9.4: A composed retention pattern MAY purge an audit event.
  Invariant 9.5: An audit event a composed retention pattern purged MUST stand as carried by EVERY rule that obliges a pool's audit log to carry an audit event.
  ```
- **Invariant 10 — State changes are auditable.**
  ```
  Invariant 10.1: A pool's audit log MUST carry a state-change event for EVERY change of the pool's state.
  Invariant 10.2: EVERY state-change event MUST carry prior state, new state, acting actor reference and a reason.
  ```
- **Invariant 11 — Capacity adjustments are auditable.**
  ```
  Invariant 11.1: A pool's audit log MUST carry an adjustment event for EVERY change of the pool's capacity.
  Invariant 11.2: EVERY adjustment event MUST carry prior capacity, new capacity, adjusting actor reference and a reason.
  ```
- **Invariant 12 — Id stability.**
  ```
  Invariant 12.1: A recorded pool id MUST NOT change.
  Invariant 12.2: A recorded audit event id MUST NOT change.
  ```
- **Invariant 13 — No id reuse.**
  ```
  Invariant 13.1: Two pools MUST NOT share a pool id.
  Invariant 13.2: Two audit events MUST NOT share an audit event id.
  Invariant 13.3: Invariant 13.2 MUST rest on the deployment obligations Identity 16 and Identity 17 name.
  ```
- **Invariant 14 — Action atomicity.** Execution Contract Database 1 holds it, cited by Capability requirement 5.

Invariants 4 and 5 together give the *bounded-arithmetic* property — at every reachable state the running total sits between zero and the bound, under the deployment obligations Invariant 4.4 names. That is what a composing pattern may treat as a precondition; without it every caller defends the bound at its own call site. Invariant 8 through 11 give the *successful-change-audit* property — every successful change to a pool's capacity, total or state is an attributed event in insertion order whose identifier surface nothing rewrites, an event a composed retention pattern purged standing as carried (Invariant 9.5). *Rejected* calls produce no event here, deliberately (Non-goal 26). Invariant 3 gives *terminal closure* — a closed pool cannot be quietly reopened, and post-close unwinding through [Release] is the only mutation that survives it.

---

## When something happens

### Concurrency

```
Concurrency 4: The atom MUST NOT order two contending calls by fairness.
Concurrency 5: The atom MUST NOT offer a transaction of more than one action.
```

### Arithmetic

```
Arithmetic 2: The deployment MUST own the integer width.
Arithmetic 3: IF the requested total EXCEEDS the integer width THEN [Allocate] MUST answer invalid-request.
Arithmetic 4: IF capacity EXCEEDS the integer width THEN [Declare Pool] MUST answer invalid-request.
Arithmetic 5: IF new capacity EXCEEDS the integer width THEN [Adjust Capacity] MUST answer invalid-request.
```

## While something is so

### Clock dependence

```
Clock dependence 1: A guard MUST NOT read now.
Clock dependence 2: A rejection MUST NOT rest on now.
```

### String policy

```
String 1: EVERY required string field MUST stand as a value that DOES NOT EQUAL blank.
String 2: IF a required string field EQUALS blank THEN the action MUST answer invalid-request.
String 4: IF a reason EXCEEDS the reason cap THEN the action MUST answer invalid-request.
String 5: IF a string field EXCEEDS the field's maximum length THEN the action MUST answer invalid-request.
String 6: IF a string field carries a control character THEN the action MUST answer invalid-request.
String 7: IF a string field carries a zero-width character THEN the action MUST answer invalid-request.
String 8: IF a string field carries a bidi-override character THEN the action MUST answer invalid-request.
String 9: The atom MUST NOT normalize a string field.
String 10: The atom MUST NOT case-fold a string field.
String 11: The atom MUST store a string field PER Execution Contract Input 4.
```

Term integer width: the largest count the deployment's integers carry without loss.

Term control character: a codepoint in Unicode's `Cc` category.

Term zero-width character: a codepoint in `U+200B` to `U+200D`, or `U+FEFF`.

Term bidi-override character: a codepoint in `U+202A` to `U+202E`, or `U+2066` to `U+2069`.

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 5: The deployment MUST supply the pool records PER Execution Contract Database 1 through 6, Execution Contract Order 1, Execution Contract Read 1 through 3, Execution Contract Refusal 1 and Execution Contract Conformance 9.
Capability requirement 6: The deployment MAY declare the actor reference cap and the reason cap PER Execution Contract Input 2.
Capability requirement 7: IF a composed retention pattern purges an audit event THEN the deployment MUST retain an anchor carrying the capacity, the allocated and the pool state at the purge boundary (Invariant 9.4, Check 2.2).
Capability requirement 8: The deployment MUST supply the pool records refusing a colliding write (Identity 14, Operation 57).
```

#### Now

The current wall-clock reading, pipeline-injected at the single I/O seam (the execution contract supplies `clock_t` there) before a transition runs — never a caller-supplied action parameter. Consumed only to stamp [Declaration Instant] and each event's [Recording Instant]; no guard consults it. Not stored under this name; the stored forms are the timestamps.

Kind:         Parameter
Parameter of: Declare Pool, Allocate, Release, Adjust Capacity, Suspend Pool, Resume Pool, Close Pool
Projection:   now

Term colliding write: a [Declare Pool] write whose injected pool id a live pool already carries.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the deployment injects the clock reading, the pool id and the audit event ids here.

Term transition: the atom's evaluation of one call against the pool records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term now: the deployment's clock reading at the call — a [Now], as Execution Contract Logic confinement 11 declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term pool state: open | suspended | closed — accepting allocations, halted, or terminal. A [State].

Term purge boundary: the place on a pool's audit log where an audit event a composed retention pattern purged stood — the replay's break (Check 2.2), where the anchor Capability requirement 7 names holds the capacity, the allocated and the pool state.

Term actor reference: the declaring, allocating, releasing, adjusting, suspending, resuming or closing actor reference a call carries — a reference the deployment canonicalizes at the seam (Execution Contract Logic confinement 13).

Term actor reference cap: 1000 codepoints where a deployment declares none — the ceiling an actor reference is measured against, counted as Execution Contract Input 2 counts a cap.

Term reason cap: 2000 codepoints where a deployment declares none — the ceiling a reason is measured against, counted in codepoints rather than bytes so a multi-byte script is not penalized against a single-byte one.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key pool id; carried by pools; calls Query.

Term offer key: key audit event id; carried by audit events; calls Read Audit Event.

## Left to others

```
Non-goal 1: The atom MUST NOT hold a per-allocation life cycle.
Deleted: Non-goal 2. Non-goal 1 owns it: the atom holds no allocation as a record of its own, and which pattern does is the app's choice.
Non-goal 3: The atom MUST NOT order two contending calls by fairness.
Non-goal 4: A deployment needing fairness MUST compose a queueing pattern.
Non-goal 5: The atom MUST NOT gate an action on a caller's authority.
Deleted: Non-goal 6. Non-goal 5 owns it: the atom decides no caller's authority; the app's permission does.
Non-goal 7: The atom MUST NOT evict an allocation to admit another.
Non-goal 8: The atom MUST NOT admit an allocation beyond capacity.
Non-goal 9: A deployment needing overcommit MUST compose a soft-limit pattern.
Non-goal 10: The atom MUST NOT expire an allocation.
Deleted: Non-goal 11. Non-goal 10 owns it: the atom bounds no allocation's lifetime, and which pattern does is the app's choice.
Non-goal 12: The atom MUST NOT attest an actor reference.
Deleted: Non-goal 13. Non-goal 12 owns it: the atom binds no acting actor, and which pattern attests one is the app's choice.
Non-goal 14: The atom MUST NOT interpret what a unit represents.
Non-goal 15: The atom MUST NOT move a unit between two pools.
Non-goal 16: The atom MUST NOT merge two pools.
Non-goal 17: The atom MUST NOT split a pool.
Non-goal 18: The atom MUST NOT notify a reader of a state change.
Deleted: Non-goal 19. Non-goal 18 owns it: the atom notifies no one, and which pattern does is the app's choice.
Non-goal 20: The atom MUST NOT hold a cross-pool bound.
Non-goal 21: The atom MUST NOT seal a pool against modification.
Deleted: Non-goal 22. Non-goal 21 owns it: the atom detects no rewrite, and which pattern makes the records tamper-evident is the app's choice.
Non-goal 23: The atom MUST NOT bound how long a pool is kept.
Deleted: Non-goal 24. Non-goal 23 owns it: the atom bounds no retention, and which pattern does is the app's choice.
Non-goal 25: The atom MUST NOT distinguish a purged pool id from an undeclared pool id.
Non-goal 26: The atom MUST NOT record a refused call.
Deleted: Non-goal 27. Non-goal 26 owns it: the atom records no refusal, and which pattern does is the app's choice.
Non-goal 28: The atom MUST NOT hold a capacity of more than one dimension.
Non-goal 29: A deployment needing verifiable wall-time order MUST compose a trusted time-stamping pattern.
Non-goal 30: The atom MUST NOT distinguish a call sent again from a new call.
Deleted: Non-goal 31. Non-goal 30 owns it: the atom answers a retried call as a new call, and which pattern answers a retry once is the app's choice.
```

NOTE: the owners — a composing pattern (Non-goal 7, Non-goal 14, Composition note 2, Composition note 3); a pattern that holds each allocation as a record of its own (Non-goal 1, External check 2; Identity 18); a soft-limit pattern (Non-goal 8, Non-goal 9); an attestation pattern (Non-goal 12, External check 3); a pattern that makes the records tamper-evident (Non-goal 21); a retention pattern (Non-goal 23); the deployment (Non-goal 25, Execution Contract Conformance 9, External check 6); an event log of refused calls (Non-goal 26, External check 1, Composition note 6); a composed erasure mechanism (Invariant 8.4, Execution Contract Database 6); a pattern that answers a retried call once (Non-goal 30).

NOTE: no pattern of the library owns Non-goal 15 through 17, Non-goal 20 or Non-goal 28. A composing pattern that moves units between pools, merges or splits pools, or bounds several pools together makes this atom's calls and owns the result (Composition note 2), and a capacity of several dimensions is a different atom (Non-goal 28).

Where the atom breaks down is worth naming. When the resource is not fungible at any grain — every seat distinct by legroom or fare class — per-unit identity belongs at this layer too, which is a sign the deployment wants a pattern that holds each allocation as a record of its own rather than this. When capacity is a vector rather than an integer — memory bytes *and* core count *and* disk — one running total cannot carry it, and a multi-dimensional pattern is a different atom (Non-goal 28).

```
Composition note 2: A composing pattern MUST own the per-unit life cycle.
Composition note 3: A composing pattern MUST call [Release] when the pattern's own allocation reaches a terminal state.
Composition note 4: A composing pattern MUST record the audit event id the atom answered.
Composition note 5: A composing pattern MUST own the authority to call an action.
Composition note 6: A composing pattern MUST own the refusal record.
Composition note 7: A composing pattern MUST own the retention of the pool records.
```

## Example

### Airline — non-overbooking seat pool

A carrier declares a cabin: `declare_pool(capacity: 180, declaring_actor_ref: inventory_svc, reason: "NK1234 2026-05-14 main cabin")` → `pool_a1`. Each booking calls `allocate(pool_a1, count: 1, allocating_actor_ref: booking_svc)`; the 181st answers over-capacity and the cabin is not oversold. A cancellation calls `release(pool_a1, count: 1, ...)` and the seat returns to the pool. An equipment swap to a smaller aircraft with 174 seats sold calls `adjust_capacity(pool_a1, new_capacity: 174, ...)` → accepted, because the new bound covers every seat sold; a swap to 170 seats calls `adjust_capacity(pool_a1, new_capacity: 170, ...)` and answers over-allocated, because four passengers are already holding seats the smaller bound would not cover, and the carrier must release before it can adjust (Operation 32).

### Banking — credit-limit headroom

A revolving line: `declare_pool(capacity: 25000, ...)` → `pool_c9`. Each draw allocates, each repayment releases, and a draw past the limit answers over-capacity. A credit review lowering the line to 10000 while 14000 is drawn answers over-allocated — the atom refuses to put the customer instantly over their new limit by arithmetic, and the reviewer must sequence the reduction against repayment explicitly (Operation 32, Operation 37).

### Healthcare — ward bed pool

A ward of 24 beds. An infection-control hold calls `suspend_pool(pool_w3, ...)`: admissions stop, discharges continue, because [Release] is admitted in every state (Operation 20). Capacity can still be re-tuned while paused. resume_pool reopens it.

### Database operations — connection pool

A primary pool of 200 connections, allocated on checkout and released on return. A failover calls suspend_pool; in-flight connections drain through [Release] while nothing new is admitted; close_pool retires it, and the last returns still land because closing forecloses allocation and not unwinding (Invariant 3.4).

### Regulated adversarial scenarios

- **Regulator audit — was the cabin ever oversold?** The auditor walks the pool's allocation events and checks each one's own snapshot, closing balance equal to opening balance plus count, and checks its closing balance against the capacity in effect at that index, which the declaration and the adjustment events before it set. Each event's arithmetic needs no replay from the beginning, because every event carries its own before and after — which is the reason the snapshots are on the record (Check 3.1, Check 3.2); that the events chain, each opening balance the allocated the one before left, is the replay's to show (Check 2.4, Check 2.5).
- **Disputed drawdown — the customer says the line was cut without notice.** Every capacity change is an adjustment event naming prior capacity, new capacity, the acting reference and a stated reason (Invariant 11.2). What the database cannot show is the *rejected* draws the customer attempted, because rejections write nothing here; a deployment under PCI DSS (Payment Card Industry Data Security Standard) Requirement 10.2.4 wires an event log around the call surface for that (External check 1, Non-goal 26).
- **Breach investigation — which pools were manipulated during the window?** The auditor filters audit events by recording instant inside the window and reads each one's actor reference. Two limits are stated rather than discovered: recording instant is advisory under clock skew and insertion order is authoritative (State 13), and where the deployment has scrubbed the attribution surface under a composed erasure the arithmetic still verifies while the actor no longer resolves (Invariant 8.4, Invariant 8.5).

---

## Source

Capacity Constraint Enforcement is a utility primitive; no single regulator owns capacity enforcement directly. Its standards relevance comes through composition with regulated patterns whose audit surface relies on the running-total invariant.

- **ISO (the International Organization for Standardization) 9001:2015 clause 8.1 (Operational planning and control)** — the International Organization for Standardization's quality-management standard; production systems must operate within declared capacity boundaries; the atom is the structural enforcement for that obligation when the constrained resource is a production asset (manufacturing-line slots, certified-operator headroom, equipment utilization).
- **Basel III (the third Basel accord) Liquidity Coverage Ratio (BCBS 238 — Basel Committee on Banking Supervision, the international body that sets bank-capital and liquidity standards)** — bank credit-line and counterparty-limit pools must be enforced as hard constraints with auditable adjustments; the atom is the operational form of a regulator-facing credit-limit headroom pool.
- **Sarbanes-Oxley Act (SOX) section 404 (Internal Control over Financial Reporting)** — where confirmed allocations against a pool are material to the books (credit-limit consumption flowing to the balance sheet, inventory allocation flowing to cost-of-goods-sold), the controls around pool adjustments and the audit trail of who-allocated-what-when become SOX-scope. Composed with an audit trail, it produces the provable evidence section 404 attestations require.
- **Payment Card Industry Data Security Standard (PCI DSS) Requirement 10 (Logging and monitoring)** — when the pool governs payment-related capacity (a payment-gateway connection pool, a card-authorization headroom pool), every successful allocation and state change must be logged with attribution; this atom's audit-log invariants supply the structural form for the successful-change surface. Req. 10.2.4 specifically requires logging of *invalid logical access attempts* (rejected calls), which this atom does not produce events for; a composing event log around the atom's call surface (see Non-goal 26 and Composition note 6) records the rejection journal. The full PCI DSS Req. 10 obligation is met by the atom and that event log together, not by the atom alone.
- **The Joint Commission, *Provision of Care, Treatment, and Services*** — healthcare bed-management and ward-capacity standards require capacity changes (closures for renovation, surge expansions) to be auditable with attribution and reason. The atom's adjust_capacity event-recording discipline is the operational form.
- **GDPR (EU General Data Protection Regulation) Article 17** — the right to erasure: where an actor reference or a reason carries personal data, a deployment may have to erase it. The attribution surface is what a composed erasure mechanism scrubs, and the audit-identifier surface still verifies the arithmetic once the actor no longer resolves (Invariant 8.4, Invariant 8.5).
- **GDPR Article 30 (Records of processing)** — where the pool's allocation events touch personal data (per-customer credit-line pools, per-patient bed allocations referencing the patient by id), the audit log is itself a processing activity subject to controller-records obligations. Composed with an audit trail and a retention bound, it meets the full obligation surface.
- **Authorization-related standards (SOX section 404 segregation-of-duties, Health Insurance Portability and Accountability Act (HIPAA) Privacy Rule section 164.508 minimum-necessary, PCI DSS Requirement 7 restrict access by business need-to-know)** — these regimes require enforcement of *who may act*, not merely attribution of *who did act*. This atom records the attribution surface (`*_actor_ref`) for every successful action but does not constrain who may invoke which action; the authorization decision is the app's permission (see Non-goal 5 and Composition note 5). A permission and an attestation pattern together produce the *was-permitted-and-was-attested* surface these standards require — the permission for the decision that admitted the call, the attestation for the non-repudiable record of who the decision admitted.

The atom inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture and the explicit refusal to absorb per-allocation identity, fairness policy, preemption, and overcommit.
- **Eiffel's design-by-contract** — preconditions on each action, named rejection reasons, and the *preserve-by-precondition* discipline (rejecting actions that would violate an invariant rather than silently clamping).
- **Database connection pooling and operating-system semaphore conventions** — the count-up / count-down arithmetic the atom abstracts; here exposed as visible business state rather than hidden inside a transactional or kernel primitive.
- **Token-bucket and leaky-bucket rate-limiter constructions** — for the kinship the atom has with rate-limit enforcement; the rate-limit pattern is a sibling primitive with time-varying capacity rather than a fixed bound.

---

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the pool record set, with its earlier versions (Execution Contract Database 5), and its audit log.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY pool's pool id, capacity, allocated, pool state and declaration fields present (State 2).
Check 2.1: IF no purged audit event EXISTS THEN an auditor MUST reconstruct a pool's capacity, allocated and pool state at an audit event by replaying the pool's audit log forward from the pool's first committed version (Execution Contract Database 5, Invariant 9.1, State 11).
Check 2.2: An auditor MUST read a purged audit event as a break in the replay (Invariant 9.4).
Check 2.4: IF no purged audit event EXISTS THEN an auditor MUST find EVERY allocation event's opening balance AND EVERY release event's opening balance equal to the allocated the replay holds on reaching the audit event (Check 2.1, State 15, State 16, Operation 3).
Check 2.5: IF no purged audit event EXISTS THEN an auditor MUST find EVERY pool's capacity, allocated and pool state equal to what the replay holds at the end of the pool's audit log (Check 2.1, Invariant 10.1, Invariant 11.1).
Check 3.1: An auditor MUST find EVERY allocation event's closing balance equal to the requested total (Operation 15).
Check 3.2: An auditor MUST find the closing balance of EVERY allocation event the replay reaches no higher than the capacity the replay holds at the audit event (Invariant 4.1, Check 2.1).
Check 3.3: An auditor MUST find no allocation event later in insertion order than a state-change event whose new state EQUALS closed on a pool's audit log (State 11, Invariant 3.2, Operation 11).
Check 3.4: IF no purged audit event EXISTS THEN an auditor MUST find the pool state the replay holds on reaching EVERY allocation event equal to open (Check 2.1, Operation 10, Operation 11).
Check 4.1: An auditor MUST find EVERY release event's closing balance equal to the released total (Operation 23).
Check 4.2: An auditor MUST find no release event's closing balance below zero (Invariant 5.1).
Check 7.1: An auditor MUST find prior capacity, new capacity, adjusting actor reference and a reason on EVERY adjustment event, AND a new capacity that DOES NOT EQUAL the prior capacity (State 17, Operation 31).
Check 7.2: IF no purged audit event EXISTS THEN an auditor MUST find EVERY adjustment event's prior capacity equal to the capacity the replay holds on reaching the audit event (Check 2.1, Operation 33).
Check 7.3: IF no purged audit event EXISTS THEN an auditor MUST find the allocated the replay holds at EVERY adjustment event no higher than the new capacity (Check 2.1, Operation 32).
Check 7.4: An auditor MUST find no adjustment event later in insertion order than a state-change event whose new state EQUALS closed on a pool's audit log (State 11, Invariant 3.3, Operation 29).
Check 8.1: An auditor MUST find prior state, new state, acting actor reference and a reason on EVERY state-change event, the prior state and the new state standing as a state change pair (State 18).
Check 8.2: IF no purged audit event EXISTS THEN an auditor MUST find EVERY state-change event's prior state equal to the pool state the replay holds on reaching the audit event (Check 2.1, Operation 41, Operation 44, Operation 46).
```

NOTE: EVERY check names the rule the check tests. A check reads an attribution surface a composed erasure mechanism scrubbed as carried (Invariant 8.6, Execution Contract Database 6). The capacity at a purge boundary is read beside the pool records, from the deployment's anchor (External check 6).

NOTE: Check 3.1, Check 4.1 and Check 4.2 read one event, as the Summary says; Check 2.4, Check 2.5, Check 3.2, Check 3.4, Check 7.2, Check 7.3 and Check 8.2 chain an event to the replay, which costs a walk of the pool's audit log from the declaration, and a record set written by a store that broke Execution Contract Database 2 fails one of them (a chain check and a per-event check fail in different directions: a lost or reordered event breaks the chain, an altered event breaks its own arithmetic).

#### External checks

```
External check 1: An auditor needing a refused call MUST read the refusal from a composing event log (Non-goal 26).
External check 2: An auditor needing a per-unit history MUST read the history from a composing per-allocation pattern (Non-goal 1).
External check 3: An auditor needing an attested actor MUST read the attestation from a composing attestation pattern (Non-goal 12).
External check 6: An auditor needing Invariant 4.1 cleared across a purge MUST read the capacity at the purge boundary from the anchor Capability requirement 7 names (Invariant 9.4).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the transition; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a guard; an operator; an auditor; a reader; the database; a pool; a pool state; an audit event; an audit log; a write; an action; a rejection; a string field; the count of pools.

Term records: pool — one bounded resource, carrying pool id, capacity, allocated, a pool state, the declaration fields and an audit log; audit event — one entry on that log, carrying an audit event id, the pool id, an event class, a recording instant and the fields the event's class names.

Term record verbs: identify, offer, share, re-order, retain, allocate, change, match, normalize, order, write, refuse, draw, reuse, hold, record, stand, set, stamp, answer, append, raise, lower, admit, release, fit, interpret, leave, insert, remove, carry, read, supply, rest, fall, scrub, reconstruct, replay, bound, find, equal, purge, evict, expire, attest, move, merge, split, notify, seal, compose, gate, distinguish, compute, own, declare, call, name, store, case-fold, exceed.

Term value sets: pool state and event class are declared above and cited here (Closed vocabulary 15).

Term bounds: reason cap (2000 codepoints where a deployment declares none); actor reference cap (1000 codepoints where a deployment declares none); maximum length (the cap a string field is measured against: the reason cap for a reason, the actor reference cap for an actor reference); whole count and positive count (the integer floors); integer width (the deployment's ceiling on capacity, new capacity, count and the requested total); capacity (the pool's own declared bound).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.36 (2026-09-12).

Term terms: actor reference, state, declaration instant, declaring actor reference, declaration reason, allocation event id, release event id, adjustment event id, state change id, prior capacity, prior state, new state, allocating actor reference, releasing actor reference, adjusting actor reference, acting actor reference, suspending actor reference, resuming actor reference, closing actor reference, reason, purge boundary, state change pair, audit-log read, pool, pool id, audit event id, event class, seam, transition, now, business caller, capacity, allocated, available, count, whole count, positive count, requested total, released total, new capacity, pool state, addressed action, state-changing action, writing action, pool snapshot, audit event, declaration field, opening balance, closing balance, recording instant, colliding write, integer width, audit-identifier surface, attribution surface, reason cap, actor reference cap, control character, zero-width character, bidi-override character, maximum length.

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
[Read Audit Event]: #read-audit-event
[Pool]: #pool
[Pool Id]: #pool-id
[Audit Event]: #audit-event
[Pool Snapshot]: #pool-snapshot
[Capacity]: #capacity
[Allocated]: #allocated
[Available]: #available
[State]: #state
[Declaration Instant]: #declaration-instant
[Declaring Actor Reference]: #declaring-actor-reference
[Declaration Reason]: #declaration-reason
[Allocation Event Id]: #allocation-event-id
[Release Event Id]: #release-event-id
[Adjustment Event Id]: #adjustment-event-id
[State Change Id]: #state-change-id
[Count]: #count
[Opening Balance]: #opening-balance
[Closing Balance]: #closing-balance
[Prior Capacity]: #prior-capacity
[New Capacity]: #new-capacity
[Prior State]: #prior-state
[New State]: #new-state
[Recording Instant]: #recording-instant
[Allocating Actor Reference]: #allocating-actor-reference
[Releasing Actor Reference]: #releasing-actor-reference
[Adjusting Actor Reference]: #adjusting-actor-reference
[Acting Actor Reference]: #acting-actor-reference
[Suspending Actor Reference]: #suspending-actor-reference
[Resuming Actor Reference]: #resuming-actor-reference
[Closing Actor Reference]: #closing-actor-reference
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

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — capacity-constraint-enforcement.tla + 2 twins (2026-06-04); capacity-constraint-enforcement.als + 14 twins (the static data model, 2026-11-11: Invariant 2.1, 3.1 through 3.4, 4.1, 5.1, 6.1, 10.1, 10.2, 11.1, 11.2, 13.1 and 13.2 checked on every pool record and audit log an admitted action leaves, Invariant 4.1 and 5.1 a cross-check with the TLA+ model; nothing testable in Alloy for Invariant 1, 7, 8, 9 and 12: each compares a record or a log with a later version of it and the change appends no event, so a single state cannot show it, and 8.4, 8.5 and 9.4 are a permission or an auditor's procedure, so they are the TLA+ model's); coverage 2026-11-10 (unit formal: more coverage for the yes votes): owes TLA+ checks of Invariant 1, 7, 8, 9 and 12 (across steps); owed rows: Invariant 1; Invariant 7; Invariant 8; Invariant 9; Invariant 12, 2026-11-11; model redraw deferred to Lean: capacity-constraint-enforcement.tla, Operation 65 through 68 ([Read Audit Event]), 2026-11-26
last gate: 2026-11-27 — Final Critique 13, a full round, three readers (GRID opencode-go/glm-5.3-flash, EOS opencode-go/claude-haiku-5-5, Linus opencode-go/mimo-v2.6-pro), frozen at c3c7c1b0 — foundational count 1, not clean, one sample (Invariant 10.1 and 11.1 oblige the audit log to carry an event for every change while Invariant 9.4 lets a composed retention pattern purge one, so an invariant broke in a state the page permits: Invariant 9.5 has a purged event stand as carried, the form Invariant 8.6 gave the scrub; the blank pool id answers not-known by Refusal 1 and 2, and the pool id's and audit event id's missing cap changes no answer, both refuted); 2026-11-22 — Final Critique 12, a full round, frozen at 3fb2f381 — foundational count 3 (a scrubbed attribution surface against the rules that oblige a pool or an audit event to carry it; String 11's stored form against the seam's canonical form; Invariant 3.2 and Invariant 3.3 forbidding the close of a pool no allocation or adjustment had touched, which Operation 46 admits), not clean, no sample; GRID's three foundational claims (an id source, a released total, an empty Invariant 14) and EOS's declared-capacity claim were placed refining or false, and their tombstoned labels read as absent were refuted; 2026-11-04 — Final Critique 11, a delta round, frozen at 5506e77 — foundational count 0, clean, no sample; 2026-11-03 — Final Critique 10, a full round, frozen at 383178a — foundational count 3, cured, not clean, no sample; 2026-10-22 — Final Critique 9, the council's first round on the page and the first on its Store-contract rewrite (ec7ffec) and the refusal-order sweep (c2f4e9a), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS MiniMax M3.1 Flash, Linus GLM-5.3 Flash), each handed only the round's reading set, three passes on one text (frozen at 973e2e3); the round rests on three counted passes — foundational count 5 after triage (9 reports: 5 standing; 3 sent down; 1 rejected), Kind A: conformance checks no pool record could clear once a deployment wired in, scrubbed or purged what the page admits, and a capacity past the integer width and a reason past its cap, which every build had to refuse with no refusal named; 12 refining reports, 5 rhetorical reports; not clean; every foundational and refining finding cured in place; 2026-08-26 — Final Critique 8, fresh reader — clean

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./capacity-constraint-enforcement.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/capacity-constraint-enforcement.md`.

</details>

NOTE: End of Capacity Constraint Enforcement.
