-- owed-record-buggy-discharge-finds-by-owed-id.als
-- DELIBERATELY WRONG twin of owed-record.als (unit: `atoms/owed-record.md formal layer`).
--
-- INJECTED DEFECT: [Discharge] finds the record by its owed id alone, ignoring the owing
-- pattern, so one pattern's call can discharge another pattern's obligation (Identity 1).
--
-- BREAKS: A_Identity_1.
-- Everything else is owed-record.als as written; read its comments there.

module owed_record_buggy_discharge_finds_by_owed_id

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a string a call carries or a record holds: an owing pattern, an owed id, a cause
-- id, a fulfilment id or an actor reference. The atom never interprets one (Identity 2 to
-- 5) and compares them byte-exactly (String 1), so a string is an uninterpreted token and
-- two different strings are two different atoms.
sig Str {}

-- Strings: which strings the page's guards refuse: the blank ones, whitespace-only
-- included (String 5); the ones longer than the id cap (Term id cap, 256 characters
-- unless the deployment overrides it); the ones longer than the pattern name cap (Term
-- pattern name cap, 128 characters unless overridden).
one sig Strings {
    blank          : set Str,
    overIdCap      : set Str,
    overPatternCap : set Str
}

-- Status: the owed record's status (Term status): open, flagged or discharged.
abstract sig Status {}

-- Open, Flagged, Discharged: the three statuses: owed and not yet flagged; owed and
-- flagged for a person; met.
one sig Open, Flagged, Discharged extends Status {}

-- Call: one call of a writing action ([Record Owed], [Discharge], [Flag]). Every one names
-- an owing pattern and an owed id, and the host injects the clock reading, now, at the
-- seam (Capability requirement 1; Clock dependence 2: no caller supplies an instant).
-- Calls happen in one order, the order Execution Contract Order 1 gives every commit.
abstract sig Call {
    patIn : one Str,   -- owing_pattern
    idIn  : one Str,   -- owed_id
    now   : one Int    -- the injected now
}

-- RecordCall: one [Record Owed] call, record_owed(owing_pattern, owed_id, cause_id,
-- due_by_window).
sig RecordCall extends Call {
    causeIn  : one Str,   -- cause_id
    windowIn : one Int    -- due_by_window, in whole seconds
}

-- DischargeCall: one [Discharge] call, discharge(owing_pattern, owed_id, fulfilment_id).
sig DischargeCall extends Call {
    fulIn : one Str       -- fulfilment_id
}

-- FlagCall: one [Flag] call, flag(owing_pattern, owed_id, actor_ref).
sig FlagCall extends Call {
    actorIn : one Str     -- actor_ref
}

-- Rec: one version of an owed record (Term records), as the call that wrote it left it.
-- Every field the page names may be absent, and the status is a set, so a write that
-- forgot a field or left two statuses would show; what the page promises (State 1 to 6)
-- is checked, never built into the type. The last two fields are the model's own: which
-- call wrote this version, and which version a [Discharge] or a [Flag] found.
sig Rec {
    pattern      : lone Str,     -- owing pattern
    owedId       : lone Str,     -- owed id
    cause        : lone Str,     -- cause id
    recordedAt   : lone Int,     -- recording instant
    dueBy        : lone Int,     -- due-by instant
    status       : set Status,   -- status
    fulfilment   : lone Str,     -- fulfilment id
    dischargedAt : lone Int,     -- discharge instant
    flaggedAt    : lone Int,     -- flag instant
    actor        : lone Str,     -- actor reference
    writtenBy    : one Call,
    found        : lone Rec
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The host's clock reads an instant from 0 to 7 seconds into the model's span (Capability
-- requirement 1: the deployment supplies now). Kept small so a due-by deadline is an
-- instant the model can hold (see NOT MODELED HERE).
fact ClockReadsTheModelsSpan {
    all c : Call | c.now >= 0 and c.now <= 7
}

-- The composing pattern owns the due-by window (Composition note 4) and passes any whole
-- number of seconds, zero or below included, from -7 to 7 here. The page puts no upper
-- bound on it (open 2026-11-02-b); this bound is the model's, so a deadline stays in range.
fact WindowWithinTheModelsSpan {
    all c : RecordCall | c.windowIn >= -7 and c.windowIn <= 7
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- usable: a string the guards accept: not blank and not over the given cap.
pred usable[s : Str, over : set Str] {
    s not in Strings.blank + over
}

-- first: the first version of the owed record this version belongs to, the one
-- [Record Owed] wrote.
fun first[r : Rec] : set Rec {
    { v : r.*found | no v.found }
}

-- origin: the [Record Owed] call that recorded the owed record this version belongs to.
-- Two versions with one origin are one owed record; two origins are two owed records.
fun origin[r : Rec] : set RecordCall {
    first[r].writtenBy & RecordCall
}

-- names: the call names this record: its owing pattern and its owed id both, compared
-- byte-exactly (Identity 1, String 1).
pred names[c : Call, r : Rec] {
    r.pattern = c.patIn
    r.owedId  = c.idIn
}

-- keepsWhatWasOwed: the later version carries what the earlier one owed, as found: a call
-- writes only the fields its own rules name.
pred keepsWhatWasOwed[pre, post : Rec] {
    post.pattern    = pre.pattern
    post.owedId     = pre.owedId
    post.cause      = pre.cause
    post.recordedAt = pre.recordedAt
    post.dueBy      = pre.dueBy
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- recordWrites: the owed record an admitted [Record Owed] records, and the guards it
-- passes first: no id blank (Operation 7), a window above zero (Operation 8), the owing
-- pattern within the pattern name cap (Operation 9), the owed id and the cause id within
-- the id cap (Operation 10), and no owed record committed before it for the owing pattern
-- and the owed id (Operation 6, Invariant 2.2: the database refuses that write). The record
-- carries the call's pattern, owed id and cause id as the call carries them, the injected
-- now as its recording instant (Operation 3), the due-by deadline as its due-by instant
-- (Operation 4, Term due-by deadline), status open (Operation 2), and no settlement field.
pred recordWrites[c : RecordCall, r : Rec] {
    usable[c.patIn, Strings.overPatternCap]                           -- Operation 7, 9
    usable[c.idIn, Strings.overIdCap]                                 -- Operation 7, 10
    usable[c.causeIn, Strings.overIdCap]                              -- Operation 7, 10
    c.windowIn > 0                                                    -- Operation 8
    no v : Rec | C/lt[v.writtenBy, c] and names[c, v]                 -- Operation 6, Invariant 2.2
    r.pattern    = c.patIn                                            -- Operation 1
    r.owedId     = c.idIn                                             -- Operation 1
    r.cause      = c.causeIn                                          -- Operation 1
    r.recordedAt = c.now                                              -- Operation 3
    r.dueBy      = plus[c.now, c.windowIn]                            -- Operation 4
    r.status     = Open                                               -- Operation 2
    no r.fulfilment
    no r.dischargedAt
    no r.flaggedAt
    no r.actor
}

-- dischargeWrites: the version an admitted [Discharge] records over the version it found:
-- the pattern and the owed id are not blank (Operation 42), the fulfilment id is not blank
-- and within the id cap (Operation 14), the call names the record (Operation 12, Identity
-- 1), and the record stands in open or flagged (Operation 13, 15). The version stands in
-- discharged (Operation 16), carries the fulfilment id (Operation 18) and the injected now
-- as its discharge instant (Operation 17), and keeps what was owed and any flag instant and
-- actor reference a [Flag] wrote.
pred dischargeWrites[pre : Rec, c : DischargeCall, r : Rec] {
    usable[c.patIn, none]                                             -- Operation 42
    usable[c.idIn, none]                                              -- Operation 42
    usable[c.fulIn, Strings.overIdCap]                                -- Operation 14
    pre.owedId = c.idIn  -- BUG: the owing pattern is not compared
    pre.status = Open or pre.status = Flagged                         -- Operation 13, 15
    keepsWhatWasOwed[pre, r]
    r.flaggedAt    = pre.flaggedAt
    r.actor        = pre.actor
    r.status       = Discharged                                       -- Operation 16
    r.fulfilment   = c.fulIn                                          -- Operation 18
    r.dischargedAt = c.now                                            -- Operation 17
}

-- flagWrites: the version an admitted [Flag] records over the version it found: the
-- pattern and the owed id are not blank (Operation 43), the actor reference is not blank
-- and within the id cap (Operation 25), the call names the record (Operation 21, Identity
-- 1), the record stands in open (Operation 22, 23), and now does not precede its due-by
-- instant (Operation 24). The version stands in flagged (Operation 26), carries the
-- injected now as its flag instant (Operation 27) and the actor reference (Operation 28),
-- and keeps what was owed.
pred flagWrites[pre : Rec, c : FlagCall, r : Rec] {
    usable[c.patIn, none]                                             -- Operation 43
    usable[c.idIn, none]                                              -- Operation 43
    usable[c.actorIn, Strings.overIdCap]                              -- Operation 25
    names[c, pre]                                                     -- Operation 21, Identity 1
    pre.status = Open                                                 -- Operation 22, 23
    some pre.dueBy and c.now >= pre.dueBy                             -- Operation 24
    keepsWhatWasOwed[pre, r]
    r.fulfilment   = pre.fulfilment
    r.dischargedAt = pre.dischargedAt
    r.status       = Flagged                                          -- Operation 26
    r.flaggedAt    = c.now                                            -- Operation 27
    r.actor        = c.actorIn                                        -- Operation 28
}

-- written: the version is what its call's write left: a [Record Owed] writes a first
-- version; a [Discharge] or a [Flag] writes over a version an earlier call wrote (a call
-- finds only what was committed before it, Execution Contract Database 2).
pred written[v : Rec] {
    let c = v.writtenBy {
        (c in RecordCall and no v.found and recordWrites[c, v])
        or (c in DischargeCall and some v.found
            and C/lt[v.found.writtenBy, c] and dischargeWrites[v.found, c, v])
        or (c in FlagCall and some v.found
            and C/lt[v.found.writtenBy, c] and flagWrites[v.found, c, v])
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): it and every version it
-- was built from are what an admitted call wrote.
pred recorded[r : Rec] {
    all v : r.*found | written[v]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every owed record stands in exactly one of open, flagged and discharged
-- (State 1).
assert A_State_1 {
    all r : Rec | recorded[r] implies one r.status
}
check A_State_1 for 4 but 5 Int

-- A_State_2: every owed record carries its owing pattern, owed id, cause id, recording
-- instant, due-by instant and status, whichever call last wrote it (State 2, Check 1.1).
assert A_State_2 {
    all r : Rec | recorded[r] implies {
        some r.pattern
        some r.owedId
        some r.cause
        some r.recordedAt
        some r.dueBy
        some r.status
    }
}
check A_State_2 for 4 but 5 Int

-- A_State_3: a discharged owed record carries a fulfilment id and a discharge instant, so
-- an auditor can match the obligation to what met it (State 3, Check 3.1).
assert A_State_3 {
    all r : Rec | (recorded[r] and Discharged in r.status) implies {
        some r.fulfilment
        some r.dischargedAt
    }
}
check A_State_3 for 4 but 5 Int

-- A_State_4: a flagged owed record carries a flag instant and an actor reference: when it
-- was found late, and who found it (State 4, Check 3.2).
assert A_State_4 {
    all r : Rec | (recorded[r] and Flagged in r.status) implies {
        some r.flaggedAt
        some r.actor
    }
}
check A_State_4 for 4 but 5 Int

-- A_State_5: an open owed record carries no fulfilment id: nothing has met it yet
-- (State 5).
assert A_State_5 {
    all r : Rec | (recorded[r] and Open in r.status) implies no r.fulfilment
}
check A_State_5 for 4 but 5 Int

-- A_State_6: an open owed record carries no flag instant: nothing has flagged it yet
-- (State 6).
assert A_State_6 {
    all r : Rec | (recorded[r] and Open in r.status) implies no r.flaggedAt
}
check A_State_6 for 4 but 5 Int

-- A_Identity_1: a version a [Discharge] or a [Flag] wrote carries the owing pattern and
-- the owed id that call named, both: a record is found by the pair, never by its owed id
-- alone, so one pattern's call never settles another pattern's obligation (Identity 1).
assert A_Identity_1 {
    all r : Rec | (recorded[r] and r.writtenBy in DischargeCall + FlagCall) implies {
        r.pattern = r.writtenBy.patIn
        r.owedId  = r.writtenBy.idIn
    }
}
check A_Identity_1 for 4 but 5 Int

-- A_Invariant_2_1: no two owed records share an owing pattern and an owed id, so each
-- obligation has one record to match against its fulfilment (Invariant 2.1, Check 2.1).
assert A_Invariant_2_1 {
    all r1, r2 : Rec | (recorded[r1] and recorded[r2] and origin[r1] != origin[r2])
        implies (no (r1.pattern & r2.pattern) or no (r1.owedId & r2.owedId))
}
check A_Invariant_2_1 for 4 but 5 Int

-- A_Invariant_4_1: no flag instant falls below its record's due-by instant, a record
-- flagged and later discharged included: no obligation is flagged before it is due
-- (Invariant 4.1, Check 4.1).
assert A_Invariant_4_1 {
    all r : Rec | recorded[r] implies
        (all f : r.flaggedAt, d : r.dueBy | f >= d)
}
check A_Invariant_4_1 for 4 but 5 Int

-- A_Operation_4: every record's due-by instant is its recording instant plus the due-by
-- window its [Record Owed] call passed (Operation 4, Term due-by deadline): the window is
-- a length of time, not an instant.
assert A_Operation_4 {
    all r : Rec | recorded[r] implies
        (all o : origin[r] | r.dueBy = plus[r.recordedAt, o.windowIn])
}
check A_Operation_4 for 4 but 5 Int

-- A_Operation_7: no record carries a blank owing pattern, owed id or cause id
-- (Operation 7, String 5).
assert A_Operation_7 {
    all r : Rec | recorded[r] implies
        no ((r.pattern + r.owedId + r.cause) & Strings.blank)
}
check A_Operation_7 for 4 but 5 Int

-- A_Operation_8: every record falls due after it was recorded, since its due-by window is
-- above zero: no obligation is due the instant it is owed, or before (Operation 8).
assert A_Operation_8 {
    all r : Rec | recorded[r] implies
        (all d : r.dueBy, t : r.recordedAt | d > t)
}
check A_Operation_8 for 4 but 5 Int

-- A_Operation_9: no record carries an owing pattern longer than the pattern name cap
-- (Operation 9).
assert A_Operation_9 {
    all r : Rec | recorded[r] implies no (r.pattern & Strings.overPatternCap)
}
check A_Operation_9 for 4 but 5 Int

-- A_Operation_10: no record carries an owed id or a cause id longer than the id cap
-- (Operation 10).
assert A_Operation_10 {
    all r : Rec | recorded[r] implies no ((r.owedId + r.cause) & Strings.overIdCap)
}
check A_Operation_10 for 4 but 5 Int

-- A_Operation_14: no record carries a blank fulfilment id or one longer than the id cap
-- (Operation 14).
assert A_Operation_14 {
    all r : Rec | recorded[r] implies
        no (r.fulfilment & (Strings.blank + Strings.overIdCap))
}
check A_Operation_14 for 4 but 5 Int

-- A_Operation_25: no record carries a blank actor reference or one longer than the id cap
-- (Operation 25).
assert A_Operation_25 {
    all r : Rec | recorded[r] implies
        no (r.actor & (Strings.blank + Strings.overIdCap))
}
check A_Operation_25 for 4 but 5 Int

-- A_Operation_27: a record's flag instant is the now the host injected into the [Flag]
-- that flagged it, the instant the sweep found it late, not the instant it fell due
-- (Operation 27, Clock dependence 2).
assert A_Operation_27 {
    all r : Rec | recorded[r] implies
        (all f : r.flaggedAt | f in (r.*found.writtenBy & FlagCall).now)
}
check A_Operation_27 for 4 but 5 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowOpen: an obligation just recorded and not yet due, as aud_51c0 at 13:00:00, due at
-- 13:05:00.
run ShowOpen {
    some r : Rec | recorded[r] and r.status = Open
} for 4 but 5 Int

-- ShowDischargedOnTime: an obligation met before it fell due, never flagged, as aud_51c0
-- discharged with evt_9a12.
run ShowDischargedOnTime {
    some r : Rec | recorded[r] and r.status = Discharged and no r.flaggedAt
        and (all t : r.dischargedAt, d : r.dueBy | t < d)
} for 4 but 5 Int

-- ShowFlagged: an obligation flagged by a sweep once due and left for a person.
run ShowFlagged {
    some r : Rec | recorded[r] and r.status = Flagged
} for 4 but 5 Int

-- ShowFlaggedAtTheDueInstant: an obligation flagged at its due-by instant exactly, which
-- the page admits: not-due answers only where now precedes the due-by instant
-- (Operation 24).
run ShowFlaggedAtTheDueInstant {
    some r : Rec | recorded[r] and r.status = Flagged and r.flaggedAt = r.dueBy
} for 4 but 5 Int

-- ShowDischargedAfterFlag: an obligation flagged and then discharged, the flag instant and
-- the actor that set it kept on the record, as aud_6d33 discharged with evt_9b40 the
-- next morning.
run ShowDischargedAfterFlag {
    some r : Rec | recorded[r] and r.status = Discharged
        and some r.flaggedAt and some r.actor and some r.fulfilment
} for 4 but 5 Int

-- ShowOneOwedIdTwoPatterns: two owed records with one owed id under two owing patterns,
-- which the page admits, since a record is identified by the pair (Identity 1).
run ShowOneOwedIdTwoPatterns {
    some r1, r2 : Rec | recorded[r1] and recorded[r2] and origin[r1] != origin[r2]
        and r1.owedId = r2.owedId and r1.pattern != r2.pattern
} for 4 but 5 Int
