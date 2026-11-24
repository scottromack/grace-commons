-- event-log-buggy-next-falls.als
-- DELIBERATELY WRONG twin of event-log.als (unit: atoms/event-log.md formal layer, 2026-11-12).
--
-- INJECTED DEFECT: [Append] lowers next sequence number by one instead of raising it (State 6), so each later event carries a lower, still distinct, number.
--
-- BREAKS: A_Invariant_4_1.
-- Everything else is event-log.als as written; read its comments there.

module event_log_buggy_next_falls

open util/ordering[Instant] as T
open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- EventId: an opaque event id (Term event id). It supports equality only (Identity 7).
sig EventId {}

-- LogName: the name telling one log instance from another (Term log name).
sig LogName {}

-- Instant: a moment on the deployment's clock (Term now, Term recording instant). Instants
-- are ordered only so a wall-time range can hold them; nothing orders events by them.
sig Instant {}

-- Size: how data stands against the payload cap (Term payload cap): empty, within the cap,
-- or over it.
abstract sig Size {}
one sig NoBytes, UpToCap, OverCap extends Size {}

-- Data: the opaque payload a composing pattern supplies (Term data). The atom reads nothing
-- in it (Non-goal 11); only its size against the cap matters to a rule (Operation 5, 6).
sig Data {
    size : one Size
}

-- Call: one call of [Append] or [Read] as it reaches the seam. Calls happen in one order,
-- the order of their commits (Execution Contract Order 1); `now` is the clock reading the
-- host injects for the call (Term now, Capability requirement 1).
abstract sig Call {
    now : one Instant
}

-- AppendCall: one [Append] call, append(data). The host allocates its event id at the seam
-- (Identity 2); the transition allocates none (Identity 3) and the caller supplies none
-- (Identity 4), nor the recording instant (Operation 21).
sig AppendCall extends Call {
    allocatedId : one EventId,
    dataIn      : one Data        -- data
}

-- SeqRange: a sequence number range of a query (Term query): its lower end, and its upper
-- end if it carries one.
sig SeqRange {
    seqLo : lone Int,
    seqHi : lone Int
}

-- TimeRange: a wall-time range of a query (Term query), its ends instants.
sig TimeRange {
    timeLo : lone Instant,
    timeHi : lone Instant
}

-- Query: what a read asks for (Term query): a sequence number range, a wall-time range,
-- or both; `onPayload` is a selection on the payload, one way a query asks for something
-- beyond those ranges.
sig Query {
    seqRange  : lone SeqRange,
    timeRange : lone TimeRange,
    onPayload : lone Data
}

-- ReadCall: one [Read] call, read(query), the log version it reads (written before it,
-- Execution Contract Database 2) and the events it answers, in the order it answers them.
sig ReadCall extends Call {
    query  : one Query,
    reads  : one Log,
    answer : seq Event
}

-- Event: one landed event (Term event) as the log holds it. Every field the page names may
-- be absent or doubled here, so a write that forgot or added one would show: what the page
-- promises (State 2) is checked, never built into the type. `landedBy` is the model's own:
-- the append call that landed it.
sig Event {
    eventId  : set EventId,       -- event id
    seqNo    : set Int,           -- sequence number
    at       : set Instant,       -- recording instant
    data     : set Data,          -- data
    landedBy : one AppendCall
}

-- Log: one version of a log instance (Term records: the log carries log name and next
-- sequence number) and the events it holds. `writtenBy` and `found` are the model's own:
-- the append whose write left this version, and the version that append found. A version
-- no call wrote is a fresh log instance.
sig Log {
    name      : set LogName,      -- log name (State 3)
    next      : set Int,          -- next sequence number (State 4)
    events    : set Event,
    writtenBy : lone AppendCall,
    found     : lone Log
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The host supplies an id it allocates to one call only (Execution Contract Logic
-- confinement 16). The page's own rules say only that the host allocates the id
-- (Identity 2), the transition does not (Identity 3) and the atom reuses none (Identity 5),
-- so this is where Invariant 6.1 comes from.
fact HostSuppliesAnIdToOneCall {
    all disj a, b : AppendCall | a.allocatedId != b.allocatedId
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- notBefore: one instant does not precede another (Execution Contract Query 2's "does not
-- precede").
pred notBefore[a, b : Instant] {
    not T/lt[a, b]
}

-- wellFormed: a query [Read] admits (Term query, Operation 15): it carries a range; each
-- range carries its lower end; a range's lower end is not above its upper end; a sequence
-- number range's ends are not below one; and it asks for nothing beyond the ranges.
pred wellFormed[q : Query] {
    some q.seqRange or some q.timeRange
    no q.onPayload
    all r : q.seqRange {
        one r.seqLo
        r.seqLo >= 1
        lone r.seqHi
        some r.seqHi implies (r.seqHi >= 1 and r.seqLo <= r.seqHi)
    }
    all r : q.timeRange {
        one r.timeLo
        lone r.timeHi
        some r.timeHi implies notBefore[r.timeHi, r.timeLo]
    }
}

-- matches: an event matches a query where it matches every range the query carries
-- (Execution Contract Query 4); a range holds both its ends (Query 2), and one carrying no
-- upper end holds its lower end and everything above it (Term query); an event carrying no
-- value on a range's axis fails it (Query 3).
pred matches[e : Event, q : Query] {
    all r : q.seqRange {
        some e.seqNo
        e.seqNo >= r.seqLo
        some r.seqHi implies e.seqNo <= r.seqHi
    }
    all r : q.timeRange {
        some e.at
        notBefore[e.at, r.timeLo]
        some r.timeHi implies notBefore[r.timeHi, e.at]
    }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- begun: a fresh log instance, as whoever starts it leaves it (the page names no starter,
-- open line 2026-10-20-d): a name, no event, next sequence number one (State 5).
pred begun[l : Log] {
    no l.writtenBy
    no l.found
    no l.events
    one l.name
    l.next = 1                                     -- State 5
}

-- appendWrites: the version an admitted [Append] leaves over the version it found, and the
-- event it lands.
pred appendWrites[pre : Log, c : AppendCall, post : Log, e : Event] {
    c.dataIn.size != OverCap                       -- Operation 5
    e.landedBy = c
    e.eventId  = c.allocatedId                     -- Identity 2, Operation 4
    e.seqNo    = pre.next                          -- Operation 3
    e.at       = c.now                             -- Operation 2
    e.data     = c.dataIn                          -- Term Append
    e not in pre.events
    post.events = pre.events + e                   -- Operation 1
    post.next   = pre.next.minus[1]                -- BUG: lowered
    post.name   = pre.name                         -- the call writes only what its rules name
}

-- written: the version is a fresh log instance, or what its append's write left over a
-- version written before that append (a call finds only what was committed before it,
-- Execution Contract Database 2).
pred written[l : Log] {
    begun[l]
    or (some l.writtenBy and some l.found
        and (no l.found.writtenBy or C/lt[l.found.writtenBy, l.writtenBy])
        and (some e : Event | appendWrites[l.found, l.writtenBy, l, e]))
}

-- recorded: a log version the page lets a state hold (see SCOPE): it and every version it
-- was built from are fresh or what an admitted append wrote.
pred recorded[l : Log] {
    all v : l.*found | written[v]
}

-- readAnswers: the answer an admitted [Read] gives over the version it reads: its query is
-- well-formed (Operation 15), the version was written before it (Database 2), it answers
-- the events of that version its query matches ([Read]: "retrieve events matching a
-- Query"), each once, the n-th in the answer having n-1 answered events below it by
-- sequence number ([Read]: "returned in Sequence Number order").
pred readAnswers[r : ReadCall] {
    wellFormed[r.query]
    recorded[r.reads]
    no r.reads.writtenBy or C/lt[r.reads.writtenBy, r]
    r.answer.elems = { e : r.reads.events | matches[e, r.query] }
    not r.answer.hasDups
    all i : r.answer.inds |
        #{ e : r.answer.elems | e.seqNo < r.answer[i].seqNo } = i
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any log, or any read over one, the page's calls can leave
-- that violates this assertion? No counterexample (UNSAT) = the guarantee holds in scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_2: every event in the log carries its event id, sequence number, recording
-- instant and data, whichever append landed it (Check 4.1).
assert A_State_2 {
    all l : Log | recorded[l] implies all e : l.events {
        some e.eventId
        some e.seqNo
        some e.at
        some e.data
    }
}
check A_State_2 for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- A_State_3: every version of a log carries its log name, so the instance is still told
-- from the others after any number of appends.
assert A_State_3 {
    all l : Log | recorded[l] implies some l.name
}
check A_State_3 for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- A_State_4: every version of a log carries its next sequence number, the number the next
-- event to land will carry.
assert A_State_4 {
    all l : Log | recorded[l] implies some l.next
}
check A_State_4 for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- A_State_5: a fresh log instance carries next sequence number one, so the first event to
-- land in a log carries sequence number one (Check 4.2; the Rejection paths' e1).
assert A_State_5 {
    all l : Log | recorded[l] implies {
        no l.writtenBy implies l.next = 1
        all e : l.events |
            (no e2 : l.events | C/lt[e2.landedBy, e.landedBy]) implies e.seqNo = 1
    }
}
check A_State_5 for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- A_Invariant_3_1: two distinct events in a log never share a sequence number, so the
-- number names one place in line.
assert A_Invariant_3_1 {
    all l : Log | recorded[l] implies
        all disj e1, e2 : l.events | no (e1.seqNo & e2.seqNo)
}
check A_Invariant_3_1 for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- A_Invariant_3_2: every two distinct events in a log stand in exactly one order: each
-- carries one sequence number and one of the two is the lower. This is also State 1, the
-- log's one total order.
assert A_Invariant_3_2 {
    all l : Log | recorded[l] implies
        all disj e1, e2 : l.events {
            one e1.seqNo
            one e2.seqNo
            e1.seqNo < e2.seqNo or e2.seqNo < e1.seqNo
        }
}
check A_Invariant_3_2 for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- A_Invariant_4_1: an event that landed later carries a higher sequence number than every
-- event that landed earlier in the same log, so replaying by sequence number replays in
-- landing order.
assert A_Invariant_4_1 {
    all l : Log | recorded[l] implies
        all e1, e2 : l.events |
            C/lt[e1.landedBy, e2.landedBy] implies e1.seqNo < e2.seqNo
}
check A_Invariant_4_1 for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- A_Invariant_5_1: a read answers every event of the log it reads that its query matches:
-- nothing landed and matching is left out.
assert A_Invariant_5_1 {
    all r : ReadCall | readAnswers[r] implies
        all e : r.reads.events | matches[e, r.query] implies e in r.answer.elems
}
check A_Invariant_5_1 for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- A_Invariant_5_2: a read answers its events by sequence number, rising: an event earlier
-- in the answer carries a lower sequence number than every event after it.
assert A_Invariant_5_2 {
    all r : ReadCall | readAnswers[r] implies
        all i, j : r.answer.inds |
            i < j implies r.answer[i].seqNo < r.answer[j].seqNo
}
check A_Invariant_5_2 for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- A_Invariant_6_1: two events in a log never share an event id, so an id names one event
-- for the life of the log.
assert A_Invariant_6_1 {
    all l : Log | recorded[l] implies
        all disj e1, e2 : l.events | no (e1.eventId & e2.eventId)
}
check A_Invariant_6_1 for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- A_Operation_5: no event in a log carries data over the payload cap: an append of such
-- data answers invalid-payload (Operation 5) and a refused call writes nothing (Execution
-- Contract Read 4).
assert A_Operation_5 {
    all l : Log | recorded[l] implies all e : l.events | e.data.size != OverCap
}
check A_Operation_5 for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- A_Operation_16: a read whose well-formed query matches no event of the log it reads
-- answers an empty sequence (Check 3.3).
assert A_Operation_16 {
    all r : ReadCall | (readAnswers[r] and no e : r.reads.events | matches[e, r.query])
        implies r.answer.isEmpty
}
check A_Operation_16 for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a log or a read the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowFreshLog: a fresh log instance, holding no event, its next sequence number one.
run ShowFreshLog {
    some l : Log | recorded[l] and no l.writtenBy
} for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- ShowThreeLanded: a log three appends deep (the bank journal's credits and debits).
run ShowThreeLanded {
    some l : Log | recorded[l] and #l.events = 3
} for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- ShowEmptyData: an event carrying empty data lands (Operation 6).
run ShowEmptyData {
    some l : Log, e : Event | recorded[l] and e in l.events and e.data.size = NoBytes
} for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- ShowFallingInstant: an event with the higher sequence number carries the earlier
-- recording instant: two appends landed in the order opposite to their clock readings,
-- which the page admits (Invariant 7.2, Check 5.2).
run ShowFallingInstant {
    some l : Log, disj e1, e2 : l.events |
        recorded[l] and e1.seqNo < e2.seqNo and T/lt[e2.at, e1.at]
} for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- ShowTwoInstances: two log instances, each with its first event at sequence number one:
-- the atom orders no events across instances (Non-goal 9, Identity 10).
run ShowTwoInstances {
    some disj l1, l2 : Log | recorded[l1] and recorded[l2]
        and no (l1.*found & l2.*found) and some l1.events and some l2.events
} for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- ShowReadOfOne: a read of the sequence number range one to one answers the first event
-- (the Rejection paths' read({sequence_range: [1, 1]}) answering [e1]).
run ShowReadOfOne {
    some r : ReadCall | readAnswers[r] and #r.answer = 1
        and r.query.seqRange.seqLo = 1 and r.query.seqRange.seqHi = 1
} for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- ShowReadOfTwoInOrder: a read answering two events, rising by sequence number.
run ShowReadOfTwoInOrder {
    some r : ReadCall | readAnswers[r] and #r.answer = 2
} for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- ShowReadMatchingNothing: a well-formed query matching no event answers an empty
-- sequence (Operation 16), over a log that holds events.
run ShowReadMatchingNothing {
    some r : ReadCall | readAnswers[r] and r.answer.isEmpty and some r.reads.events
} for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- ShowOpenRange: a sequence number range carrying no upper end answers an event above its
-- lower end (Term query).
run ShowOpenRange {
    some r : ReadCall | readAnswers[r] and no r.query.seqRange.seqHi
        and some i : r.answer.inds | r.answer[i].seqNo > r.query.seqRange.seqLo
} for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- ShowWallTimeRead: a read by a wall-time range alone answers an event.
run ShowWallTimeRead {
    some r : ReadCall | readAnswers[r] and no r.query.seqRange
        and some r.query.timeRange and not r.answer.isEmpty
} for 3 but 4 Log, 4 Call, 4 Int, 3 seq

-- ShowCombinedRead: a query carrying both ranges answers the events matching both, leaving
-- out an event that matches the sequence number range only (Execution Contract Query 4).
run ShowCombinedRead {
    some r : ReadCall, e : Event | readAnswers[r] and some r.query.seqRange
        and some r.query.timeRange and not r.answer.isEmpty
        and e in r.reads.events and e not in r.answer.elems
        and (all s : r.query.seqRange | e.seqNo >= s.seqLo
                and (some s.seqHi implies e.seqNo <= s.seqHi))
} for 3 but 4 Log, 4 Call, 4 Int, 3 seq
