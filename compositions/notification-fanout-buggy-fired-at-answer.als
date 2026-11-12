-- notification-fanout-buggy-fired-at-answer.als
-- DELIBERATELY WRONG twin of notification-fanout.als (unit: `compositions/notification-fanout.md formal layer`).
--
-- INJECTED DEFECT: the firing instant is stamped when the fanout answers, after its creates, not from the
-- clock reading the call began under (Action wiring 2, Clock semantics 1).
--
-- BREAKS: A_Action_wiring_2, A_Clock_semantics_1.
-- Everything else is notification-fanout.als as written; read its comments there.

module notification_fanout_buggy_fired_at_answer

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Scope: an event scope a caller passes (Term event scope, Subscription's). The composition
-- compares it byte-exact and never normalizes it (Primitive policy 5, 6), so a scope is an
-- uninterpreted token and two different scopes are two different atoms.
sig Scope {}

-- Ref: a subscriber reference: what subscribers_for answers and what a create names as its
-- recipient reference. Also the business caller's own reference.
sig Ref {}

-- Payload: a payload a caller passes. An absent (null) payload is no payload at all; an
-- empty or whitespace-only one is a Payload in World.emptyPayload (Term boundary predicate).
sig Payload {}

-- FanoutId: a fanout id, the correlation handle the host supplies at the seam (Term Fanout
-- Id, Capability requirement 2).
sig FanoutId {}

-- Reason: why a create was refused: one of Notification's declared refusals
-- (invalid-request, storage-failure).
sig Reason {}

-- World: what the world holds beside the calls: which scopes are blank (empty or
-- whitespace-only), which payloads are empty or whitespace-only (present, not absent), and
-- three transformations the page forbids the composition, which the correct model never
-- applies and a twin may: a case folding of a scope (Primitive policy 6), a payload rewritten
-- for one recipient (Invariant 2.1), an id derived from a scope (Action wiring 3).
one sig World {
    blank        : set Scope,
    emptyPayload : set Payload,
    fold         : Scope -> one Scope,
    personalize  : Payload -> Ref -> one Payload,
    scopeId      : Scope -> one FanoutId
}

-- ReadOutcome: how the subscribers_for call came back: answered with the references,
-- answered state-unavailable, or answered nothing within the read latency bound (Action
-- wiring 4, the closure table's Subscription row).
abstract sig ReadOutcome {}

-- ReadAnswered, ReadUnavailable, ReadNoReply: the three ways a subscribers_for call ends.
one sig ReadAnswered, ReadUnavailable, ReadNoReply extends ReadOutcome {}

-- CreateOutcome: how one Notification create came back: a notification id, one of
-- Notification's declared refusals, the state-unavailable of a failed read, or nothing
-- within the create bound — an unrecordable create (the closure table's Notification row).
abstract sig CreateOutcome {}

-- AnsweredId, Refused, CreateUnavailable, NoAnswer: the four ways a create ends.
one sig AnsweredId, Refused, CreateUnavailable, NoAnswer extends CreateOutcome {}

-- Answer: what a [Fanout] call answered: invalid-request, subscribers-unavailable, a fanout
-- result, or nothing at all because the fanout crashed partway (Non-goal 3).
abstract sig Answer {}

-- InvalidRequest, SubscribersUnavailable, Result, Crashed: the four ends of a [Fanout] call.
one sig InvalidRequest, SubscribersUnavailable, Result, Crashed extends Answer {}

-- Notif: one notification record, Notification's, as its create wrote it. The atom stands for
-- its notification id. The recipient is a set and the payload may be absent, so a record
-- naming two recipients or none, or carrying the wrong payload, would show: what the page
-- promises is checked, never built into the type.
sig Notif {
    recipient : set Ref,       -- recipient reference
    payload   : lone Payload   -- payload
}

-- Create: one Notification create call a fanout made: the arguments it passed, how the call
-- came back, the reason a refusal named, and the record it committed, if any.
sig Create {
    by        : one Fanout,         -- the fanout that called it
    recipient : set Ref,            -- the recipient reference argument
    payload   : lone Payload,       -- the payload argument
    outcome   : one CreateOutcome,  -- how it came back
    why       : lone Reason,        -- the refusal's reason
    rec       : lone Notif          -- the record it committed
}

-- Fanout: one [Fanout] call: its inputs, what the host gave it at the seam, what it called,
-- and what it answered. The answer's fields are the fanout result's (Term fanout result):
-- the fanout id, the created list (the records, standing for their ids), the failed list,
-- the firing instant, and the create reasons a result must not carry (Action wiring 18).
sig Fanout {
    scopeIn    : one Scope,          -- event scope
    payloadIn  : lone Payload,       -- payload (none: absent)
    caller     : one Ref,            -- the business caller who fired the event
    now        : one Int,            -- the seam's clock reading at the call
    drawn      : one FanoutId,       -- the id the host draws at the seam for this call
    answeredAt : one Int,            -- the instant the call answered (the model's own)
    took       : lone FanoutId,      -- the fanout id the composition took
    asked      : lone Scope,         -- the scope subscribers_for was called with
    readOut    : lone ReadOutcome,   -- how that call came back
    answer     : set Ref,            -- the references it answered
    readAt     : lone Int,           -- the instant the database fixed the set
    ans        : one Answer,         -- what the fanout answered
    rid        : lone FanoutId,      -- the result's fanout id
    created    : set Notif,          -- the result's created list
    failed     : set Ref,            -- the result's failed list
    firedAt    : lone Int,           -- the result's firing instant
    reasons    : set Reason          -- any create reason the result carried
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The deployment's clock never goes back (Execution Contract Logic confinement 7): the
-- database fixes the subscriber set at or after the instant the call began, and the call
-- answers at or after both. Readings run 0 to 7, the model's span.
fact ClockNeverGoesBack {
    all f : Fanout {
        f.now >= 0 and f.now <= 7
        f.answeredAt >= f.now
        all t : f.readAt | t >= f.now and f.answeredAt >= t
    }
}

-- The host draws a distinct fanout id at the seam for every call, meeting the entropy floor
-- (Capability requirement 2, 3: the host's duty, not the composition's).
fact SeamDrawsFreshIds {
    all disj f, g : Fanout | f.drawn != g.drawn
}

-- A subscribers_for call has its scope, its outcome and its instant together; only an
-- answered call carries references (a failed read answers state-unavailable and nothing
-- else, Execution Contract Read 3, Constituent failure 3).
fact ReadComesBackWhole {
    all f : Fanout {
        some f.asked iff some f.readOut
        some f.readOut iff some f.readAt
        f.readOut != ReadAnswered implies no f.answer
    }
}

-- Notification's create, as its page states it: a create answering a notification id
-- committed exactly one record; a declared refusal or a failed read committed none
-- (Notification Operation 16, Execution Contract Read 3); a create answering nothing may or
-- may not have committed one (Execution Contract Error model 1). A declared refusal names
-- its reason. The record carries the recipient reference and the payload the call passed
-- (Notification State 2, Operation 1), and no two calls committed one record.
fact NotificationCreates {
    all c : Create {
        c.outcome = AnsweredId implies one c.rec
        c.outcome in Refused + CreateUnavailable implies no c.rec
        c.outcome = Refused iff one c.why
        c.outcome != Refused implies no c.why
        all n : c.rec | n.recipient = c.recipient and n.payload = c.payload
    }
    all n : Notif | lone rec.n
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- creates: the Notification create calls one fanout made.
fun creates[f : Fanout] : set Create {
    by.f
}

-- boundary: the call's inputs clear the boundary predicate (Term boundary predicate): an
-- event scope that is not blank and a payload that is not absent; an empty or a
-- whitespace-only payload is not absent. A call that clears it is an admitted fanout.
pred boundary[f : Fanout] {
    f.scopeIn not in World.blank
    some f.payloadIn
}

-- noResult: the call answered no fanout result's fields.
pred noResult[f : Fanout] {
    no f.rid
    no f.created
    no f.failed
    no f.firedAt
    no f.reasons
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The composition's wiring of one [Fanout] call
-- ─────────────────────────────────────────────────────────────────────────────

-- wired: the call did what the page's wiring says. A call whose event scope is blank or
-- whose payload is absent answers invalid-request, takes no fanout id and calls nothing
-- (Primitive policy 1 to 4). An admitted call takes the id the seam drew (Action wiring 3)
-- and calls subscribers_for with the event scope as the caller sent it (Action wiring 1,
-- Primitive policy 5, 6). A read that failed or did not answer answers
-- subscribers-unavailable, with no fanout id and no create (Action wiring 4, 5). An answered
-- read is followed by at most one create per reference it answered, with that reference as
-- the recipient and the payload (Action wiring 7 to 9); a fanout that crashed partway
-- answers nothing (Non-goal 3); one that ran to completion called create for every
-- reference, through any failure (Wiring decision 1, 2), and answers the id, the firing
-- instant from the seam's clock reading, the notification ids the creates answered as the
-- created list, the references whose create answered anything else as the failed list, and
-- no reason (Action wiring 2, 10, 11, 13, 18).
pred wired[f : Fanout] {
    (f.scopeIn in World.blank or no f.payloadIn) implies {          -- Primitive policy 1, 2
        f.ans = InvalidRequest
        no f.took                                                   -- Primitive policy 3
        no f.asked                                                  -- Primitive policy 4
        no creates[f]                                               -- Primitive policy 4
        noResult[f]
    } else {
        f.took = f.drawn                                            -- Action wiring 3
        f.asked = f.scopeIn                                         -- Action wiring 1, Primitive policy 5, 6
        f.readOut != ReadAnswered implies {                         -- Action wiring 4
            f.ans = SubscribersUnavailable
            no creates[f]
            noResult[f]                                             -- Action wiring 5
        } else {
            all c : creates[f] | one c.recipient                    -- Action wiring 8
                and c.recipient in f.answer                         -- Action wiring 9
                and c.payload = f.payloadIn                         -- Action wiring 8
            all r : f.answer | lone c : creates[f] | r in c.recipient    -- Action wiring 7
            f.ans in Result + Crashed
            f.ans = Result implies {
                all r : f.answer | some c : creates[f] | r in c.recipient   -- Action wiring 7, Wiring decision 1, 2
                f.rid = f.took                                      -- Action wiring 13
                f.firedAt = f.answeredAt   -- BUG: stamped at the answer
                f.created = (creates[f] & outcome.AnsweredId).rec   -- Action wiring 10
                f.failed = (creates[f] - outcome.AnsweredId).recipient   -- Action wiring 11
                no f.reasons                                        -- Action wiring 18
            } else noResult[f]                                      -- Non-goal 3
        }
    }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: an admitted fanout answering a result called Notification's create exactly
-- once for every subscriber reference the subscribers_for answer carried: no subscriber
-- skipped, none served twice (Invariant 1.1).
assert A_Invariant_1_1 {
    all f : Fanout | (wired[f] and boundary[f] and f.ans = Result) implies
        (all r : f.answer | one c : creates[f] | r in c.recipient)
}
check A_Invariant_1_1 for 3 but 4 Int, 2 Fanout

-- A_Invariant_1_2: every subscriber reference the answer carried stands in exactly one of the
-- created recipients (the recipients of the records the created list names) and the failed
-- list: each one is accounted for, as reached or as a named failure, never both and never
-- neither (Invariant 1.2, Wiring decision 3, Check 1.3).
assert A_Invariant_1_2 {
    all f : Fanout | (wired[f] and f.ans = Result) implies
        (all r : f.answer |
            (r in f.created.recipient and r not in f.failed)
            or (r not in f.created.recipient and r in f.failed))
}
check A_Invariant_1_2 for 3 but 4 Int, 2 Fanout

-- A_Invariant_1_3: no fanout called create for a reference outside its subscribers_for
-- answer: nobody who was not subscribed gets a record (Invariant 1.3, Action wiring 9,
-- Non-goal 6).
assert A_Invariant_1_3 {
    all f : Fanout | wired[f] implies creates[f].recipient in f.answer
}
check A_Invariant_1_3 for 3 but 4 Int, 2 Fanout

-- A_Invariant_2_1: every notification record one fanout's creates committed carries that
-- fanout's payload: all records from one event carry the same content (Invariant 2.1,
-- Check 2.1). A crashed fanout's records included.
assert A_Invariant_2_1 {
    all f : Fanout | wired[f] implies
        (all n : creates[f].rec | n.payload = f.payloadIn)
}
check A_Invariant_2_1 for 3 but 4 Int, 2 Fanout

-- A_Invariant_4_1: no two notification ids in one fanout's created list name one subscriber
-- reference (Invariant 4.1, Check 4.1).
assert A_Invariant_4_1 {
    all f : Fanout | (wired[f] and f.ans = Result) implies
        (all disj n1, n2 : f.created | no (n1.recipient & n2.recipient))
}
check A_Invariant_4_1 for 3 but 4 Int, 2 Fanout

-- A_Invariant_4_2: a fanout's created list names only records one of its own creates
-- answered to it: the composition never claims a record it did not observe, such as one an
-- unrecordable create may have committed, or one another fanout made (Invariant 4.2,
-- Indeterminate outcome 8).
assert A_Invariant_4_2 {
    all f : Fanout | (wired[f] and f.ans = Result) implies
        f.created in (creates[f] & outcome.AnsweredId).rec
}
check A_Invariant_4_2 for 3 but 4 Int, 2 Fanout

-- A_Invariant_8_1: two fanouts answering a result never share a fanout id, two fanouts of one
-- event scope included (Invariant 8.1). Rests on the fact SeamDrawsFreshIds.
assert A_Invariant_8_1 {
    all disj f, g : Fanout | (wired[f] and wired[g] and f.ans = Result and g.ans = Result)
        implies f.rid != g.rid
}
check A_Invariant_8_1 for 3 but 4 Int, 2 Fanout

-- A_Invariant_8_3: an admitted fanout answering a result answers a fanout id, the
-- empty-subscriber case included (Invariant 8.3, Term Fanout Id).
assert A_Invariant_8_3 {
    all f : Fanout | (wired[f] and boundary[f] and f.ans = Result) implies some f.rid
}
check A_Invariant_8_3 for 3 but 4 Int, 2 Fanout

-- A_Composition_state_6: every notification record a fanout's creates committed names
-- exactly one subscriber reference: one record per recipient, never one record for a group
-- (Composition state 6).
assert A_Composition_state_6 {
    all f : Fanout | wired[f] implies
        (all n : creates[f].rec | one n.recipient)
}
check A_Composition_state_6 for 3 but 4 Int, 2 Fanout

-- A_Action_wiring_1: an admitted fanout calls Subscription's subscribers_for: an empty or a
-- whitespace-only payload is admitted, since only an absent one is refused (Action wiring 1,
-- Term boundary predicate, Notification Operation 5).
assert A_Action_wiring_1 {
    all f : Fanout | (wired[f] and boundary[f]) implies some f.asked
}
check A_Action_wiring_1 for 3 but 4 Int, 2 Fanout

-- A_Action_wiring_2: a fanout result's firing instant is the seam's clock reading the call
-- began under (Action wiring 2).
assert A_Action_wiring_2 {
    all f : Fanout | (wired[f] and f.ans = Result) implies f.firedAt = f.now
}
check A_Action_wiring_2 for 3 but 4 Int, 2 Fanout

-- A_Clock_semantics_1: a fanout result's firing instant is no later than the instant the
-- database fixed the subscriber set, so an auditor's window opened at it misses no
-- subscribe or cancel that moved the set (Clock semantics 1).
assert A_Clock_semantics_1 {
    all f : Fanout | (wired[f] and f.ans = Result) implies
        (all t : f.firedAt, a : f.readAt | t <= a)
}
check A_Clock_semantics_1 for 3 but 4 Int, 2 Fanout

-- A_Action_wiring_4: a fanout whose subscribers_for call answered state-unavailable, or
-- nothing within the read latency bound, answers subscribers-unavailable and called no
-- create: a failed read is never read as nobody subscribed (Action wiring 4).
assert A_Action_wiring_4 {
    all f : Fanout | (wired[f] and some f.readOut and f.readOut != ReadAnswered) implies
        (f.ans = SubscribersUnavailable and no creates[f])
}
check A_Action_wiring_4 for 3 but 4 Int, 2 Fanout

-- A_Action_wiring_5: a subscribers-unavailable answer carries no fanout id: the id taken
-- after validation is discarded (Action wiring 5).
assert A_Action_wiring_5 {
    all f : Fanout | (wired[f] and f.ans = SubscribersUnavailable) implies no f.rid
}
check A_Action_wiring_5 for 3 but 4 Int, 2 Fanout

-- A_Action_wiring_13: a fanout result answers the fanout id and the firing instant beside its
-- two lists (Action wiring 13, Clock semantics 4).
assert A_Action_wiring_13 {
    all f : Fanout | (wired[f] and f.ans = Result) implies (some f.rid and some f.firedAt)
}
check A_Action_wiring_13 for 3 but 4 Int, 2 Fanout

-- A_Action_wiring_14: a fanout whose subscribers_for answer was empty answers an empty created
-- list and an empty failed list (Action wiring 14).
assert A_Action_wiring_14 {
    all f : Fanout | (wired[f] and f.ans = Result and no f.answer) implies
        (no f.created and no f.failed)
}
check A_Action_wiring_14 for 3 but 4 Int, 2 Fanout

-- A_Action_wiring_18: a fanout result carries no create's reason: the failed list names the
-- reference and nothing about why (Action wiring 18).
assert A_Action_wiring_18 {
    all f : Fanout | (wired[f] and f.ans = Result) implies no f.reasons
}
check A_Action_wiring_18 for 3 but 4 Int, 2 Fanout

-- A_Primitive_policy_1_2: a call with a blank event scope or an absent payload answers
-- invalid-request (Primitive policy 1, 2).
assert A_Primitive_policy_1_2 {
    all f : Fanout | (wired[f] and not boundary[f]) implies f.ans = InvalidRequest
}
check A_Primitive_policy_1_2 for 3 but 4 Int, 2 Fanout

-- A_Primitive_policy_3_4: a call the boundary predicate refuses takes no fanout id and calls
-- no constituent (Primitive policy 3, 4).
assert A_Primitive_policy_3_4 {
    all f : Fanout | (wired[f] and not boundary[f]) implies
        (no f.took and no f.asked and no creates[f])
}
check A_Primitive_policy_3_4 for 3 but 4 Int, 2 Fanout

-- A_Primitive_policy_5_6: subscribers_for is asked for the event scope exactly as the caller
-- sent it, compared byte-exact and never normalized (Primitive policy 5, 6, Non-goal 7, 8).
assert A_Primitive_policy_5_6 {
    all f : Fanout | wired[f] implies f.asked in f.scopeIn
}
check A_Primitive_policy_5_6 for 3 but 4 Int, 2 Fanout

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowEveryoneServed: the walkthrough's first fanout: two subscribers, a record each, nothing
-- failed.
run ShowEveryoneServed {
    some f : Fanout | wired[f] and f.ans = Result and #f.answer = 2
        and f.created.recipient = f.answer and no f.failed
} for 3 but 4 Int, 2 Fanout

-- ShowPartialFailure: the partial-failure example: one create answers nothing within the
-- bound and its record committed all the same, so the reference stands in the failed list
-- while a record exists the created list does not claim — the at-least-once residual the
-- page names (Indeterminate outcome 3).
run ShowPartialFailure {
    some f : Fanout, c : Create | wired[f] and f.ans = Result and c.by = f
        and c.outcome = NoAnswer and some c.rec and some f.created
        and c.recipient in f.failed
} for 3 but 4 Int, 2 Fanout

-- ShowRefusedCreate: a create Notification refused (storage-failure, say): the reference in
-- the failed list, no record, no reason in the result.
run ShowRefusedCreate {
    some f : Fanout, c : Create | wired[f] and f.ans = Result and c.by = f
        and c.outcome = Refused and some f.failed
} for 3 but 4 Int, 2 Fanout

-- ShowEmptyAnswer: nobody subscribed: a result with an id, a firing instant and two empty
-- lists (Action wiring 14).
run ShowEmptyAnswer {
    some f : Fanout | wired[f] and f.ans = Result and no f.answer and some f.rid
} for 3 but 4 Int, 2 Fanout

-- ShowSubscribersUnavailable: the subscription records are down: subscribers-unavailable,
-- no id, no record.
run ShowSubscribersUnavailable {
    some f : Fanout | wired[f] and f.ans = SubscribersUnavailable
} for 3 but 4 Int, 2 Fanout

-- ShowInvalidRequest: a null payload: invalid-request before any id or call.
run ShowInvalidRequest {
    some f : Fanout | wired[f] and f.ans = InvalidRequest and no f.payloadIn
} for 3 but 4 Int, 2 Fanout

-- ShowEmptyPayloadAdmitted: an empty payload is not absent: the fanout runs.
run ShowEmptyPayloadAdmitted {
    some f : Fanout | wired[f] and f.payloadIn in World.emptyPayload
        and f.ans = Result and some f.created
} for 3 but 4 Int, 2 Fanout

-- ShowCrashLeavesRecords: a fanout that crashed partway leaves records and answers nothing
-- (Non-goal 3).
run ShowCrashLeavesRecords {
    some f : Fanout | wired[f] and f.ans = Crashed and some creates[f].rec
} for 3 but 4 Int, 2 Fanout

-- ShowTwoFanoutsOneScope: two fanouts of one event scope, each answering its own id.
run ShowTwoFanoutsOneScope {
    some disj f, g : Fanout | wired[f] and wired[g] and f.ans = Result and g.ans = Result
        and f.scopeIn = g.scopeIn
} for 3 but 4 Int, 2 Fanout
