-- capacity-constraint-enforcement-buggy-adjust-unlogged.als
-- DELIBERATELY WRONG twin of capacity-constraint-enforcement.als (unit: every check has a twin that breaks it).
--
-- INJECTED DEFECT: [Adjust Capacity] replaces the capacity without appending its adjustment event
-- (Operation 34).
--
-- BREAKS: A_Invariant_11_1.
-- Everything else is capacity-constraint-enforcement.als as written; read its comments there.

module capacity_constraint_enforcement_buggy_adjust_unlogged

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a string value a call carries or an event holds — an actor reference or a reason.
-- The atom stores a string as the call supplied it and never interprets it (String 9 to
-- 11), so a string here is an uninterpreted token.
sig Str {}

-- Blank: the strings that carry no code point outside the whitespace category, which
-- String 1 forbids in a required string field. Which strings these are is the world's,
-- not the atom's, so it is a subset with no rule on it.
sig Blank in Str {}

-- Id: an opaque id, a pool id or an event id (Term pool id, Term event id). It means
-- nothing by itself and is compared by identity only (Identity 10 to 12).
sig Id {}

-- State: the three pool states (Term pool state); closed is the terminal one. There is no
-- drained state (State 6).
abstract sig State {}
one sig Open, Suspended, Closed extends State {}

-- EventClass: the four kinds of entry a pool's audit log carries (Term event class).
abstract sig EventClass {}
one sig Allocation, Release, Adjustment, StateChange extends EventClass {}

-- Deployment: the deployment's integer width, the largest count its integers carry without
-- loss (Term integer width). The deployment owns it (Arithmetic 2); the atom only compares
-- against it.
one sig Deployment {
    width : one Int
}

-- Call: one call of a writing action, as it reaches the seam. Calls happen in one order,
-- the order Execution Contract Order 1 gives every commit. The host allocates an id for
-- every writing call at the seam: a pool id for [Declare Pool] (Identity 3), an event id
-- for every other (Identity 4).
abstract sig Call {
    allocatedId : one Id
}

-- DeclareCall: one [Declare Pool] call, declare_pool(capacity, ...). Its actor reference
-- and reason are not modeled (see NOT MODELED HERE).
sig DeclareCall extends Call {
    capacityIn : one Int        -- capacity
}

-- AddressedCall: a call naming a pool (Term addressed action), with the actor reference it
-- carries (allocating, releasing, adjusting, suspending, resuming or closing). The pool it
-- names is the version it finds (see `written`).
abstract sig AddressedCall extends Call {
    actorIn : lone Str
}

-- CountCall: [Allocate] or [Release], each carrying a count (Term count).
abstract sig CountCall extends AddressedCall {
    countIn : one Int
}
-- The two counting actions, allocate(pool_id, count, ...) and release(pool_id, count, ...).
sig AllocateCall, ReleaseCall extends CountCall {}

-- ReasonedCall: an addressed call that also carries a reason: [Adjust Capacity] and the
-- three state-changing actions (Term state-changing action).
abstract sig ReasonedCall extends AddressedCall {
    reasonIn : lone Str
}

-- AdjustCall: one [Adjust Capacity] call, adjust_capacity(pool_id, new_capacity, ...).
sig AdjustCall extends ReasonedCall {
    newCapacityIn : one Int     -- new_capacity
}

-- The three state-changing actions: suspend_pool, resume_pool, close_pool.
sig SuspendCall, ResumeCall, CloseCall extends ReasonedCall {}

-- Event: one audit event on a pool's log (Term audit event), as the call that appended it
-- wrote it. Every field the page names for any class is here and every one may be absent,
-- so a write that forgot one would show. `preceding` is the event before it on the log: the
-- log is kept in insertion order (State 11), so the model keeps it as a chain back to the
-- first event. `appendedBy` is the model's own: the call that appended it.
sig Event {
    eventId       : lone Id,          -- event id (Identity 2)
    poolRef       : lone Id,          -- the pool id (State 14)
    evClass       : lone EventClass,  -- event class (State 14)
    opening       : lone Int,         -- opening balance (State 15, 16)
    count         : lone Int,         -- count (State 15, 16)
    closing       : lone Int,         -- closing balance (State 15, 16)
    priorCapacity : lone Int,         -- prior capacity (State 17)
    newCapacity   : lone Int,         -- new capacity (State 17)
    priorState    : set State,        -- prior state (State 18)
    newState      : set State,        -- new state (State 18)
    actor         : lone Str,         -- the actor reference of the event's class
    reason        : lone Str,         -- reason (State 17, 18)
    preceding     : lone Event,       -- the event inserted just before it
    appendedBy    : one Call          -- the call that appended it
}

-- Pool: one version of a pool record (Term records), as the call that wrote it left it.
-- Every field the page names here may be absent, and the state is a set of state flags,
-- so a write that ADDED a state instead of replacing one would show: what the page
-- promises (exactly one state) is checked, never built into the type. `last` is the
-- latest event on its audit log (the log is `last` and every event before it). The last
-- two fields are the model's own: which call wrote this version and which version that
-- call found.
sig Pool {
    poolId     : lone Id,        -- pool id (Identity 1)
    capacity   : lone Int,       -- capacity
    allocated  : lone Int,       -- allocated, the running total
    state      : set State,      -- the pool state (State 1)
    last       : lone Event,     -- the latest event on the pool's audit log (State 3)
    writtenBy  : one Call,       -- the call whose write left this version
    found      : lone Pool       -- the version that call found (every action but [Declare Pool])
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The deployment draws a pool id unique across the system's life (Identity 15), and the
-- host injects it at the seam (Identity 3). The page does not say the host's id is the
-- deployment's draw (its own open finding 2026-11-03-f); the model takes it that it is.
-- This is where Invariant 13.1 comes from.
fact DeploymentDrawsUniquePoolIds {
    all disj a, b : DeclareCall | a.allocatedId != b.allocatedId
}

-- Likewise an event id, unique across the system's life and across the event classes
-- (Identity 16, 17), injected at the seam (Identity 4). This is where Invariant 13.2 and
-- 13.3 come from.
fact DeploymentDrawsUniqueEventIds {
    all disj a, b : AddressedCall | a.allocatedId != b.allocatedId
}

-- The deployment computes every total without loss (Arithmetic 1) within the width it owns
-- (Arithmetic 2), which Invariant 4.4 and 5.3 rest on. In the model: the width and every
-- integer a call carries lie between -4 and 3, so the model's integers (from -8 to 7)
-- hold every requested total and released total exactly.
fact NoLoss {
    Deployment.width >= -4 and Deployment.width <= 3
    all c : DeclareCall  | c.capacityIn >= -4 and c.capacityIn <= 3
    all c : CountCall    | c.countIn >= -4 and c.countIn <= 3
    all c : AdjustCall   | c.newCapacityIn >= -4 and c.newCapacityIn <= 3
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- nonBlank: a string is present and carries a code point outside the whitespace category
-- (String 1). An absent input reads as blank.
pred nonBlank[x : lone Str] {
    some x and x not in Blank
}

-- log: the pool's audit log, its latest event and every event before it.
fun log[p : Pool] : set Event {
    p.last.*preceding
}

-- earlier: event a was inserted before event b on the same log.
pred earlier[a, b : Event] {
    a in b.^preceding
}

-- latest: of a set of events on one log, the one inserted last.
fun latest[es : set Event] : set Event {
    { x : es | no y : es | earlier[x, y] }
}

-- ofClass: the events of a log that are of one class.
fun ofClass[es : set Event, k : EventClass] : set Event {
    { e : es | e.evClass = k }
}

-- closeEvents: the state-change events on the pool's log that stood it in closed.
fun closeEvents[p : Pool] : set Event {
    { e : ofClass[log[p], StateChange] | Closed in e.newState }
}

-- origin: the [Declare Pool] call that recorded the pool this version belongs to — the
-- writer of the first version along the chain of versions found.
fun origin[p : Pool] : set Call {
    { v : p.*found | no v.found }.writtenBy
}

-- stateBefore: the pool state the log holds just before event e: the new state of the
-- latest state-change event before it, or open, where [Declare Pool] stands a pool
-- (Operation 2).
fun stateBefore[e : Event] : set State {
    let sc = ofClass[e.^preceding, StateChange] |
        (some sc => latest[sc].newState else Open)
}

-- stateOnLog: the pool state the log holds after its last event.
fun stateOnLog[p : Pool] : set State {
    let sc = ofClass[log[p], StateChange] |
        (some sc => latest[sc].newState else Open)
}

-- capacityBefore: the capacity the log holds just before event e of pool p's log: the new
-- capacity of the latest adjustment event before it, or the capacity the pool was declared
-- with (Operation 4). No record holds that declared capacity (see `A_Invariant_11_1`), so
-- the model reads it off the [Declare Pool] call.
fun capacityBefore[p : Pool, e : Event] : set Int {
    let adj = ofClass[e.^preceding, Adjustment] |
        (some adj => latest[adj].newCapacity else origin[p].capacityIn)
}

-- capacityOnLog: the capacity the log holds after its last event.
fun capacityOnLog[p : Pool] : set Int {
    let adj = ofClass[log[p], Adjustment] |
        (some adj => latest[adj].newCapacity else origin[p].capacityIn)
}

-- keepsIdentity: the call leaves the pool id as it found it (Identity 7).
pred keepsIdentity[pre, post : Pool] {
    post.poolId = pre.poolId
}

-- appends: the version's log is the found version's log with one new event, e, which the
-- call appended, carrying the call's event id and the pool's id (State 14, Identity 4).
pred appends[pre : Pool, c : Call, post : Pool, e : Event] {
    post.last = e
    e.preceding = pre.last
    e.appendedBy = c
    e.eventId = c.allocatedId
    e.poolRef = pre.poolId
}

-- noCapacityFields / noStateFields / noCountFields: an event carries only its class's
-- fields (State 15 to 18).
pred noCountFields[e : Event] {
    no e.opening
    no e.count
    no e.closing
}
pred noCapacityFields[e : Event] {
    no e.priorCapacity
    no e.newCapacity
}
pred noStateFields[e : Event] {
    no e.priorState
    no e.newState
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- declareWrites: the pool an admitted [Declare Pool] records.
pred declareWrites[c : DeclareCall, p : Pool] {
    c.capacityIn >= 0                                  -- Operation 7, Invariant 6.2
    c.capacityIn <= Deployment.width                   -- Arithmetic 4
    p.poolId    = c.allocatedId                        -- Identity 3
    p.capacity  = c.capacityIn                         -- Operation 4
    p.allocated = 0                                    -- Operation 3
    p.state     = Open                                 -- Operation 2
    no p.last                                          -- no event until a change after the declaration
}

-- allocateWrites: the version an admitted [Allocate] leaves over the pool it found.
pred allocateWrites[pre : Pool, c : AllocateCall, p : Pool] {
    Suspended not in pre.state                         -- Operation 10
    Closed not in pre.state                            -- Operation 11, Invariant 3.2
    c.countIn > 0                                      -- Operation 12
    c.countIn <= Deployment.width                      -- the case table: count past the integer width
    plus[pre.allocated, c.countIn] <= Deployment.width -- Arithmetic 3
    plus[pre.allocated, c.countIn] <= pre.capacity     -- Operation 13, Invariant 4.2
    nonBlank[c.actorIn]                                -- String 2
    keepsIdentity[pre, p]
    p.capacity  = pre.capacity                         -- Operation 18
    p.state     = pre.state                            -- Operation 19
    p.allocated = plus[pre.allocated, c.countIn]       -- Operation 15
    some e : Event {
        appends[pre, c, p, e]                          -- Operation 16
        e.evClass = Allocation
        e.opening = pre.allocated                      -- Term opening balance
        e.count   = c.countIn
        e.closing = plus[pre.allocated, c.countIn]     -- Term closing balance
        e.actor   = c.actorIn                          -- State 15
        no e.reason
        noCapacityFields[e]
        noStateFields[e]
    }
}

-- releaseWrites: the version an admitted [Release] leaves, in any pool state (Operation 20).
pred releaseWrites[pre : Pool, c : ReleaseCall, p : Pool] {
    c.countIn > 0                                      -- Operation 21
    c.countIn <= Deployment.width                      -- the case table: count past the integer width
    c.countIn <= pre.allocated                         -- Operation 22, Invariant 5.2
    nonBlank[c.actorIn]                                -- String 2
    keepsIdentity[pre, p]
    p.capacity  = pre.capacity                         -- Operation 26
    p.state     = pre.state                            -- Operation 27
    p.allocated = minus[pre.allocated, c.countIn]      -- Operation 23
    some e : Event {
        appends[pre, c, p, e]                          -- Operation 24
        e.evClass = Release
        e.opening = pre.allocated
        e.count   = c.countIn
        e.closing = minus[pre.allocated, c.countIn]
        e.actor   = c.actorIn                          -- State 16
        no e.reason
        noCapacityFields[e]
        noStateFields[e]
    }
}

-- adjustWrites: the version an admitted [Adjust Capacity] leaves.
pred adjustWrites[pre : Pool, c : AdjustCall, p : Pool] {
    Closed not in pre.state                            -- Operation 29, Invariant 3.3
    c.newCapacityIn >= 0                               -- Operation 30, Invariant 6.3
    c.newCapacityIn <= Deployment.width                -- Arithmetic 5
    c.newCapacityIn != pre.capacity                    -- Operation 31
    not (pre.allocated > c.newCapacityIn)              -- Operation 32, Invariant 4.3
    nonBlank[c.actorIn]                                -- String 2
    nonBlank[c.reasonIn]                               -- String 2
    keepsIdentity[pre, p]
    p.capacity  = c.newCapacityIn                      -- Operation 33
    p.allocated = pre.allocated                        -- Operation 36
    p.state     = pre.state                            -- the pool state moves only by a state-changing action
    some e : Event {
        p.last = pre.last                              -- BUG: [Adjust Capacity] appends nothing
        e.evClass       = Adjustment
        e.priorCapacity = pre.capacity                 -- State 17
        e.newCapacity   = c.newCapacityIn
        e.actor         = c.actorIn
        e.reason        = c.reasonIn
        noCountFields[e]
        noStateFields[e]
    }
}

-- stateChangeAdmitted: the guards of the three state-changing actions on the pool found.
pred stateChangeAdmitted[pre : Pool, c : ReasonedCall] {
    c in SuspendCall implies (Suspended not in pre.state   -- Operation 39
                              and Closed not in pre.state) -- Operation 40
    c in ResumeCall  implies (Open not in pre.state        -- Operation 42
                              and Closed not in pre.state) -- Operation 43
    c in CloseCall   implies Closed not in pre.state       -- Operation 45
    nonBlank[c.actorIn]                                    -- String 2
    nonBlank[c.reasonIn]                                   -- String 2
}

-- target: the state a state-changing action stands the pool in.
fun target[c : ReasonedCall] : set State {
    (c in SuspendCall => Suspended else none)              -- Operation 41
    + (c in ResumeCall => Open else none)                  -- Operation 44
    + (c in CloseCall => Closed else none)                 -- Operation 46
}

-- stateChangeWrites: the version an admitted [Suspend Pool], [Resume Pool] or [Close Pool]
-- leaves.
pred stateChangeWrites[pre : Pool, c : ReasonedCall, p : Pool] {
    c in SuspendCall + ResumeCall + CloseCall
    stateChangeAdmitted[pre, c]
    keepsIdentity[pre, p]
    p.state     = target[c]
    p.allocated = pre.allocated                        -- Operation 49
    p.capacity  = pre.capacity                         -- Operation 50
    some e : Event {
        appends[pre, c, p, e]                          -- Operation 47, Invariant 10.1
        e.evClass    = StateChange
        e.priorState = pre.state                       -- State 18
        e.newState   = target[c]
        e.actor      = c.actorIn
        e.reason     = c.reasonIn
        noCountFields[e]
        noCapacityFields[e]
    }
}

-- written: the version is what its call's write left, over a version an earlier call wrote
-- (a call finds only what was committed before it, Execution Contract Database 2).
pred written[v : Pool] {
    let c = v.writtenBy, pre = v.found {
        (c in DeclareCall and no pre and declareWrites[c, v])
        or (c in AddressedCall and some pre and C/lt[pre.writtenBy, c] and (
               (c in AllocateCall and allocateWrites[pre, c, v])
            or (c in ReleaseCall and releaseWrites[pre, c, v])
            or (c in AdjustCall and adjustWrites[pre, c, v])
            or (c in SuspendCall + ResumeCall + CloseCall and stateChangeWrites[pre, c, v])))
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): it and every version it
-- was built from are what an admitted call wrote.
pred recorded[p : Pool] {
    all v : p.*found | written[v]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any record the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_2_1: every pool stands in exactly one state. [Declare Pool] stands it open
-- and each state-changing action replaces the state with its target.
assert A_Invariant_2_1 {
    all p : Pool | recorded[p] implies one p.state
}
check A_Invariant_2_1 for 4 but 4 Int, 3 Event

-- A_Invariant_3_1: a closed pool does not leave closed. Read off one record: a pool whose
-- own log records its close still stands in closed.
assert A_Invariant_3_1 {
    all p : Pool | (recorded[p] and some closeEvents[p]) implies p.state = Closed
}
check A_Invariant_3_1 for 4 but 4 Int, 3 Event

-- A_Invariant_3_2: [Allocate] answers closed against a closed pool, so no allocation event
-- is ever appended after the close on a pool's log.
assert A_Invariant_3_2 {
    all p : Pool | recorded[p] implies
        no x : closeEvents[p], e : ofClass[log[p], Allocation] | earlier[x, e]
}
check A_Invariant_3_2 for 4 but 4 Int, 3 Event

-- A_Invariant_3_3: [Adjust Capacity] answers closed against a closed pool, so no
-- adjustment event is ever appended after the close.
assert A_Invariant_3_3 {
    all p : Pool | recorded[p] implies
        no x : closeEvents[p], e : ofClass[log[p], Adjustment] | earlier[x, e]
}
check A_Invariant_3_3 for 4 but 4 Int, 3 Event

-- A_Invariant_3_4: [Release] is the one mutating action a closed pool admits, so every
-- event after the close on a pool's log is a release event (in-flight allocations unwind;
-- nothing else moves).
assert A_Invariant_3_4 {
    all p : Pool | recorded[p] implies
        all x : closeEvents[p], e : log[p] | earlier[x, e] implies e.evClass = Release
}
check A_Invariant_3_4 for 4 but 4 Int, 3 Event

-- A_Invariant_4_1: every pool's running total stays within its capacity, with capacity
-- adjustments in scope (the TLA+ model holds capacity fixed).
assert A_Invariant_4_1 {
    all p : Pool | recorded[p] implies p.allocated <= p.capacity
}
check A_Invariant_4_1 for 4 but 4 Int, 3 Event

-- A_Invariant_5_1: every pool's running total stays at zero or above.
assert A_Invariant_5_1 {
    all p : Pool | recorded[p] implies p.allocated >= 0
}
check A_Invariant_5_1 for 4 but 4 Int, 3 Event

-- A_Invariant_6_1: every pool's capacity is present and a whole count (zero or more).
assert A_Invariant_6_1 {
    all p : Pool | recorded[p] implies (one p.capacity and p.capacity >= 0)
}
check A_Invariant_6_1 for 4 but 4 Int, 3 Event

-- A_Invariant_10_1: every state change appends a state-change event, so the pool's
-- state-change events account for every state it has stood in: each event's prior state
-- is the state the log held just before it (open at the declaration), and the state the
-- log ends in is the pool's state now. A change made without its event breaks the chain.
assert A_Invariant_10_1 {
    all p : Pool | recorded[p] implies {
        all e : ofClass[log[p], StateChange] | e.priorState = stateBefore[e]
        p.state = stateOnLog[p]
    }
}
check A_Invariant_10_1 for 4 but 4 Int, 3 Event

-- A_Invariant_10_2: every state-change event carries its prior state, its new state, a
-- non-blank acting actor reference and a non-blank reason.
assert A_Invariant_10_2 {
    all p : Pool | recorded[p] implies all e : ofClass[log[p], StateChange] {
        some e.priorState
        some e.newState
        nonBlank[e.actor]
        nonBlank[e.reason]
    }
}
check A_Invariant_10_2 for 4 but 4 Int, 3 Event

-- A_Invariant_11_1: every capacity change appends an adjustment event, so the pool's
-- adjustment events account for every capacity it has held: each event's prior capacity
-- is the capacity just before it (the declared capacity before the first), and the
-- capacity the log ends in is the pool's capacity now. The declared capacity is read off
-- the [Declare Pool] call: no record holds it (it is not a declaration field and no event
-- carries it), so the records alone cannot show a change made before the first adjustment.
assert A_Invariant_11_1 {
    all p : Pool | recorded[p] implies {
        all e : ofClass[log[p], Adjustment] | e.priorCapacity = capacityBefore[p, e]
        p.capacity = capacityOnLog[p]
    }
}
check A_Invariant_11_1 for 4 but 4 Int, 3 Event

-- A_Invariant_11_2: every adjustment event carries its prior capacity, its new capacity,
-- a non-blank adjusting actor reference and a non-blank reason.
assert A_Invariant_11_2 {
    all p : Pool | recorded[p] implies all e : ofClass[log[p], Adjustment] {
        one e.priorCapacity
        one e.newCapacity
        nonBlank[e.actor]
        nonBlank[e.reason]
    }
}
check A_Invariant_11_2 for 4 but 4 Int, 3 Event

-- A_Invariant_13_1: two pools never share a pool id. Versions recorded by different
-- [Declare Pool] calls are different pools.
assert A_Invariant_13_1 {
    all p1, p2 : Pool | (recorded[p1] and recorded[p2] and origin[p1] != origin[p2])
        implies p1.poolId != p2.poolId
}
check A_Invariant_13_1 for 4 but 4 Int, 3 Event

-- A_Invariant_13_2: two audit events never share an event id, on one pool's log or on two.
-- Events appended by different calls are different events.
assert A_Invariant_13_2 {
    all p1, p2 : Pool | (recorded[p1] and recorded[p2]) implies
        all e1 : log[p1], e2 : log[p2] |
            e1.appendedBy != e2.appendedBy implies e1.eventId != e2.eventId
}
check A_Invariant_13_2 for 4 but 4 Int, 3 Event

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a record the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowDeclared: a pool just declared: open, allocated zero, an empty log (the airline's
-- cabin before its first booking).
run ShowDeclared {
    some p : Pool | recorded[p] and p.writtenBy in DeclareCall and p.capacity > 0
} for 4 but 4 Int, 3 Event

-- ShowZeroCapacity: a pool declared with capacity zero, a whole count the page admits.
run ShowZeroCapacity {
    some p : Pool | recorded[p] and p.capacity = 0
} for 4 but 4 Int, 3 Event

-- ShowDrained: an open pool whose running total has reached its capacity. Drained is an
-- arithmetic condition, not a state (State 6): the pool still stands open.
run ShowDrained {
    some p : Pool | recorded[p] and p.state = Open and p.allocated > 0
        and p.allocated = p.capacity
} for 4 but 4 Int, 3 Event

-- ShowReleasedWhileSuspended: a suspended pool whose latest event is a release (the ward
-- under an infection-control hold: admissions stop, discharges continue, Operation 20).
run ShowReleasedWhileSuspended {
    some p : Pool | recorded[p] and p.state = Suspended and p.last.evClass = Release
} for 4 but 4 Int, 3 Event

-- ShowAdjustedWhileSuspended: a suspended pool whose capacity was re-tuned while paused.
run ShowAdjustedWhileSuspended {
    some p : Pool | recorded[p] and p.state = Suspended and p.last.evClass = Adjustment
} for 4 but 4 Int, 3 Event

-- ShowLoweredToAllocated: a capacity lowered to exactly the running total, which covers
-- every unit allocated and so is admitted (the airline's swap to 174 seats with 174 sold).
run ShowLoweredToAllocated {
    some p : Pool | recorded[p] and p.last.evClass = Adjustment and p.allocated > 0
        and p.last.newCapacity = p.allocated and p.last.newCapacity < p.last.priorCapacity
} for 4 but 4 Int, 3 Event

-- ShowResumed: an open pool that was suspended and resumed.
run ShowResumed {
    some p : Pool | recorded[p] and p.state = Open
        and some e : ofClass[log[p], StateChange] | e.newState = Suspended
} for 4 but 4 Int, 3 Event

-- ShowClosedFromSuspended: a pool closed while suspended (Close Pool admits open or
-- suspended).
run ShowClosedFromSuspended {
    some p : Pool | recorded[p] and p.state = Closed
        and some e : closeEvents[p] | e.priorState = Suspended
} for 4 but 4 Int, 3 Event

-- ShowReleasedAfterClose: a closed pool whose log holds a release after the close: the
-- connection pool's last returns still land (Invariant 3.4).
run ShowReleasedAfterClose {
    some p : Pool | recorded[p]
        and some x : closeEvents[p], e : ofClass[log[p], Release] | earlier[x, e]
} for 4 but 4 Int, 3 Event

-- ShowTwoPools: two pools declared side by side, each under its own pool id; the atom holds
-- no cross-pool bound (Non-goal 20).
run ShowTwoPools {
    some disj p1, p2 : Pool | recorded[p1] and recorded[p2] and origin[p1] != origin[p2]
        and some p1.last and some p2.last
} for 4 but 4 Int, 3 Event
