-- retention-window-buggy-place-drops-policy.als
-- DELIBERATELY WRONG twin of retention-window.als (unit: `atoms/retention-window.md formal layer`).
--
-- INJECTED DEFECT: [Place Under Retention] records no policy reference (State 2).
--
-- BREAKS: A_State_2.
-- Everything else is retention-window.als as written; read its comments there.

module retention_window_buggy_place_drops_policy

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a reference a call carries or a retention holds: a record reference or a policy
-- reference. The atom never interprets one (Term record reference, Term policy reference)
-- and compares two by exact value (Identity 10), so a string is an uninterpreted token and
-- two different strings are two different atoms.
sig Str {}

-- Strings: which references the page's well-formedness checks refuse: the blank ones
-- (Operation 4, 5).
one sig Strings {
    blank : set Str
}

-- Rid: a retention id, the opaque value naming one retention (Term retention id). The
-- host allocates it at the seam (Identity 2); the atom only records and compares it.
sig Rid {}

-- RState: what a retention's state field could hold: retained or purged (Term retention
-- state). The field is a set in the record, so a write that left two states would show.
abstract sig RState {}

-- Retained, Purged: under obligation; ended by a purge and terminal.
one sig Retained, Purged extends RState {}

-- Eligible: a stored purge-eligibility value, yes or no. The page forbids storing it
-- (Invariant 11.1, State 7): purge eligible is derived when asked. It is in the type so a
-- write that stored one would show; that none does is checked, never built in.
abstract sig Eligible {}

-- EligYes, EligNo: the two values a stored flag could carry.
one sig EligYes, EligNo extends Eligible {}

-- Tier: a storage tier (immediately accessible, archive). The page forbids the atom to
-- hold one (State 10, Non-goal 1); it is in the type so a write that recorded one would
-- show.
sig Tier {}

-- Config: the deployment's declarations: the time resolution, in ticks (Capability
-- requirement 5, Term time resolution), and the last instant the database holds (the
-- instants Operation 8c and Capability requirement 14 name).
one sig Config {
    res   : one Int,
    dbMax : one Int
}

-- Call: one call of a writing action ([Place Under Retention], [Purge]). The host injects
-- the clock reading, now, at the seam (Capability requirement 1). Calls happen in one
-- order, the order Execution Contract Order 1 gives every commit.
abstract sig Call {
    now : one Int    -- the injected now
}

-- PlaceCall: one [Place Under Retention] call, place_under_retention(record_ref,
-- policy_ref), with what the host injects at the seam: the retention id it allocated
-- (Identity 2) and the policy's duration and max purge delay, resolved to elapsed lengths
-- (Operation 24, 24a), each absent where the host could not resolve it (a degenerate
-- duration, a degenerate max purge delay).
sig PlaceCall extends Call {
    recIn   : one Str,     -- record_ref
    polIn   : one Str,     -- policy_ref
    durIn   : lone Int,    -- the policy's duration, absent where degenerate
    delayIn : lone Int,    -- the policy's max purge delay, absent where degenerate
    hostRid : one Rid      -- the retention id the host allocated
}

-- PurgeCall: one [Purge] call, purge(retention_id).
sig PurgeCall extends Call {
    ridIn : one Rid        -- retention_id
}

-- Ret: one version of a retention record (Term records), as the call that wrote it left
-- it. Every field the page names may be absent, and the state is a set, so a write that
-- forgot a field or left two states would show; what the page promises (State 2 to 6a,
-- Invariant 1.1) is checked, never built into the type. `eligible` and `tier` are the
-- fields State 7, Invariant 11.1 and State 10 forbid, in the type so a write that stored
-- one would show. The last two fields are the model's own: which call wrote this version,
-- and which version a [Purge] found.
sig Ret {
    rid            : lone Rid,      -- retention id
    rec            : lone Str,      -- record reference
    pol            : lone Str,      -- policy reference
    retainedAt     : lone Int,      -- retention instant
    retentionUntil : lone Int,      -- retention deadline
    purgeDeadline  : lone Int,      -- purge deadline
    state          : set RState,    -- retention state
    purgedAt       : lone Int,      -- purge instant
    eligible       : lone Eligible, -- a stored purge eligibility (forbidden)
    tier           : lone Tier,     -- a storage tier (forbidden)
    writtenBy      : one Call,
    found          : lone Ret
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The host's clock reads an instant from 0 to 3 ticks into the model's span (Capability
-- requirement 1: the deployment supplies now). Kept small so every deadline is an instant
-- the model can hold (see NOT MODELED HERE).
fact ClockReadsTheModelsSpan {
    all c : Call | c.now >= 0 and c.now <= 3
}

-- A resolved duration and a resolved max purge delay are any whole number of ticks from
-- -2 to 2, zero and below included: the policy is the registry's (Non-goal 7), and the
-- page's guards, not this fact, refuse the ones it refuses (Operation 7, 8). The bound is
-- the model's, so a sum stays in range.
fact PolicyLengthsWithinTheModelsSpan {
    all c : PlaceCall, d : c.durIn | d >= -2 and d <= 2
    all c : PlaceCall, d : c.delayIn | d >= -2 and d <= 2
}

-- The deployment declares a time resolution of one or two ticks (Capability
-- requirement 5), and a database that holds the instants from 0 to some last instant,
-- every purge instant [Purge] stamps among them (Capability requirement 14).
fact DeploymentDeclarations {
    Config.res >= 1 and Config.res <= 2
    Config.dbMax >= 0 and Config.dbMax <= 9
    all c : PurgeCall | roundUp[c.now] <= Config.dbMax
}

-- The host supplies each placement a retention id that names no retention of the records
-- before it (Capability requirement 8). The atom takes the id from outside; whether the
-- host keeps the duty across steps is checked in the TLA+ model (Id5_IdNeverReused).
fact HostAllocatesAnUnusedId {
    all c : PlaceCall | no v : Ret |
        recorded[v] and C/lt[v.writtenBy, c] and v.rid = c.hostRid
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- usable: a reference the well-formedness checks accept: not blank (Operation 4, 5).
pred usable[s : Str] {
    s not in Strings.blank
}

-- roundUp: the instant rounded up to the time resolution: the least multiple of it,
-- counted from the epoch, that the instant does not exceed (State 4a, 6a, Operation 13a,
-- Term time resolution). At a resolution of one tick every instant is a multiple; at two,
-- an odd instant rounds up to the next even one.
fun roundUp[x : Int] : Int {
    (Config.res = 1 or rem[x, 2] = 0) implies x else plus[x, 1]
}

-- first: the first version of the retention this version belongs to, the one
-- [Place Under Retention] wrote.
fun first[r : Ret] : set Ret {
    { v : r.*found | no v.found }
}

-- origin: the [Place Under Retention] call that recorded the retention this version
-- belongs to. Two versions with one origin are one retention; two origins are two.
fun origin[r : Ret] : set PlaceCall {
    first[r].writtenBy & PlaceCall
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- placeWrites: the retention an admitted [Place Under Retention] records, and the guards
-- it passes first: both references non-blank (Operation 4, 5), the duration resolved and
-- above the zero duration (Operation 7a, 7), the max purge delay resolved and not below
-- it (Operation 8b, 8), and both deadlines instants the database holds (Operation 8c).
-- The retention carries the id the host allocated (Invariant 4.1, Identity 3), the call's
-- references, the injected now rounded up as its retention instant (State 4, 4a), the two
-- deadlines (State 5, 6, 6a), state retained (Operation 2), and no purge instant, no
-- stored eligibility and no storage tier.
pred placeWrites[c : PlaceCall, r : Ret] {
    usable[c.recIn]                                                   -- Operation 4
    usable[c.polIn]                                                   -- Operation 5
    some c.durIn                                                      -- Operation 7a
    all d : c.durIn | d > 0                                           -- Operation 7
    some c.delayIn                                                    -- Operation 8b
    all d : c.delayIn | d >= 0                                        -- Operation 8
    r.rid            = c.hostRid                                      -- Invariant 4.1
    r.rec            = c.recIn                                        -- State 2
    no r.pol  -- BUG: the policy reference not recorded
    r.retainedAt     = roundUp[c.now]                                 -- State 4, 4a
    r.retentionUntil = roundUp[plus[r.retainedAt, c.durIn]]           -- State 5, 6a
    r.purgeDeadline  = roundUp[plus[r.retentionUntil, c.delayIn]]     -- State 6, 6a
    r.retentionUntil <= Config.dbMax                                  -- Operation 8c
    r.purgeDeadline <= Config.dbMax                                   -- Operation 8c
    r.state          = Retained                                       -- Operation 2
    no r.purgedAt
    no r.eligible
    no r.tier
}

-- purgeWrites: the version an admitted [Purge] records over the version it found: the
-- call's id names the retention (Identity 1, Operation 14), it stands retained (Operation
-- 15), and the injected now does not precede its retention deadline (Operation 16, Term
-- purge eligible); the purge deadline is not read (Operation 18). The version stands
-- purged (Operation 12), carries the injected now rounded up as its purge instant
-- (Operation 13, 13a), and keeps every field the placement wrote.
pred purgeWrites[pre : Ret, c : PurgeCall, r : Ret] {
    pre.rid = c.ridIn                                                 -- Identity 1, Operation 14
    pre.state = Retained                                              -- Operation 15
    c.now >= pre.retentionUntil                                       -- Operation 16
    r.rid            = pre.rid
    r.rec            = pre.rec
    r.pol            = pre.pol
    r.retainedAt     = pre.retainedAt
    r.retentionUntil = pre.retentionUntil
    r.purgeDeadline  = pre.purgeDeadline
    r.state          = Purged                                         -- Operation 12
    r.purgedAt       = roundUp[c.now]                                 -- Operation 13, 13a
    r.eligible       = pre.eligible
    r.tier           = pre.tier
}

-- written: the version is what its call's write left: a placement writes a first
-- version; a [Purge] writes over a version an earlier call wrote (a call finds only what
-- was committed before it, Execution Contract Database 2).
pred written[v : Ret] {
    let c = v.writtenBy {
        (c in PlaceCall and no v.found and placeWrites[c, v])
        or (c in PurgeCall and some v.found
            and C/lt[v.found.writtenBy, c] and purgeWrites[v.found, c, v])
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): it and every version it
-- was built from are what an admitted call wrote.
pred recorded[r : Ret] {
    all v : r.*found | written[v]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: every retention stands in exactly one of retained and purged
-- (Invariant 1.1).
assert A_Invariant_1_1 {
    all r : Ret | recorded[r] implies one r.state
}
check A_Invariant_1_1 for 3 but 5 Int

-- A_State_2: every retention carries its retention id, record reference, policy
-- reference, retention instant, retention deadline and purge deadline, whichever call
-- last wrote it (State 2; Check 1.1 reads the policy reference).
assert A_State_2 {
    all r : Ret | recorded[r] implies {
        some r.rid
        some r.rec
        some r.pol
        some r.retainedAt
        some r.retentionUntil
        some r.purgeDeadline
    }
}
check A_State_2 for 3 but 5 Int

-- A_State_3: a purged retention carries its purge instant, so its overshoot can be
-- computed (State 3, Check 4.1).
assert A_State_3 {
    all r : Ret | (recorded[r] and Purged in r.state) implies some r.purgedAt
}
check A_State_3 for 3 but 5 Int

-- A_State_4: every retention instant is its placement's injected now, rounded up to the
-- time resolution (State 4, State 4a).
assert A_State_4 {
    all r : Ret | recorded[r] implies r.retainedAt = roundUp[origin[r].now]
}
check A_State_4 for 3 but 5 Int

-- A_State_5: every retention deadline is the retention instant plus the policy's
-- duration, rounded up to the time resolution (State 5, State 6a, Term retention
-- deadline).
assert A_State_5 {
    all r : Ret | recorded[r] implies
        r.retentionUntil = roundUp[plus[r.retainedAt, origin[r].durIn]]
}
check A_State_5 for 3 but 5 Int

-- A_State_6: every purge deadline is the retention deadline plus the policy's max purge
-- delay, rounded up to the time resolution (State 6, State 6a, Term purge deadline).
assert A_State_6 {
    all r : Ret | recorded[r] implies
        r.purgeDeadline = roundUp[plus[r.retentionUntil, origin[r].delayIn]]
}
check A_State_6 for 3 but 5 Int

-- A_State_10: no retention holds a storage tier: where a record lives is a Storage Tier
-- pattern's (State 10, Non-goal 1).
assert A_State_10 {
    all r : Ret | recorded[r] implies no r.tier
}
check A_State_10 for 3 but 5 Int

-- A_Identity_1: a version a [Purge] wrote carries the retention id that call named: a
-- retention is found by its id, never by its record reference, so a purge of one
-- retention never ends a sibling over the same record (Identity 1, Identity 6,
-- Simultaneous retention 3).
assert A_Identity_1 {
    all r : Ret | (recorded[r] and r.writtenBy in PurgeCall)
        implies r.rid = r.writtenBy.ridIn
}
check A_Identity_1 for 3 but 5 Int

-- A_Invariant_4_1: every version of a retention carries the retention id the host
-- allocated for the placement that recorded it: the transition allocates none of its own
-- (Invariant 4.1, Identity 2, Identity 3).
assert A_Invariant_4_1 {
    all r : Ret | recorded[r] implies r.rid = origin[r].hostRid
}
check A_Invariant_4_1 for 3 but 5 Int

-- A_Invariant_6_1: no retention deadline precedes its retention instant (Invariant 6.1).
assert A_Invariant_6_1 {
    all r : Ret | recorded[r] implies
        (all i : r.retainedAt, u : r.retentionUntil | u >= i)
}
check A_Invariant_6_1 for 3 but 5 Int

-- A_Invariant_6_2: no purge deadline precedes its retention deadline, so a retention
-- overdue for purge is purge eligible too (Invariant 6.2).
assert A_Invariant_6_2 {
    all r : Ret | recorded[r] implies
        (all u : r.retentionUntil, p : r.purgeDeadline | p >= u)
}
check A_Invariant_6_2 for 3 but 5 Int

-- A_Invariant_8_1: no purged retention's purge instant precedes its retention deadline:
-- the auditor's set of early purges is empty (Invariant 8.1, Check 2.1).
assert A_Invariant_8_1 {
    all r : Ret | (recorded[r] and Purged in r.state) implies
        (all p : r.purgedAt, u : r.retentionUntil | p >= u)
}
check A_Invariant_8_1 for 3 but 5 Int

-- A_Invariant_9_1: no two retentions share a retention id, so an id names one retention
-- and [Purge] has one record to judge (Invariant 9.1, Identity 9).
assert A_Invariant_9_1 {
    all r1, r2 : Ret | (recorded[r1] and recorded[r2] and origin[r1] != origin[r2])
        implies no (r1.rid & r2.rid)
}
check A_Invariant_9_1 for 3 but 5 Int

-- A_Invariant_11_1: no retention record carries an eligibility flag: purge eligible is
-- derived when asked, never stored (Invariant 11.1, State 7, Check 3.1).
assert A_Invariant_11_1 {
    all r : Ret | recorded[r] implies no r.eligible
}
check A_Invariant_11_1 for 3 but 5 Int

-- A_Operation_4: no retention carries a blank record reference (Operation 4).
assert A_Operation_4 {
    all r : Ret | recorded[r] implies no (r.rec & Strings.blank)
}
check A_Operation_4 for 3 but 5 Int

-- A_Operation_5: no retention carries a blank policy reference (Operation 5).
assert A_Operation_5 {
    all r : Ret | recorded[r] implies no (r.pol & Strings.blank)
}
check A_Operation_5 for 3 but 5 Int

-- A_Operation_7: every retention deadline is later than its retention instant: a
-- placement whose duration is not above the zero duration, or could not be resolved,
-- records nothing (Operation 7, Operation 7a).
assert A_Operation_7 {
    all r : Ret | recorded[r] implies
        (all i : r.retainedAt, u : r.retentionUntil | u > i)
}
check A_Operation_7 for 3 but 5 Int

-- A_Operation_8c: both deadlines of every retention are instants the database holds
-- (Operation 8c).
assert A_Operation_8c {
    all r : Ret | recorded[r] implies
        (r.retentionUntil <= Config.dbMax and r.purgeDeadline <= Config.dbMax)
}
check A_Operation_8c for 3 but 5 Int

-- A_Operation_13: every purge instant is the injected now of the [Purge] that wrote it,
-- rounded up to the time resolution (Operation 13, Operation 13a).
assert A_Operation_13 {
    all r : Ret | (recorded[r] and r.writtenBy in PurgeCall) implies
        r.purgedAt = roundUp[r.writtenBy.now]
}
check A_Operation_13 for 3 but 5 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowRetained: a retention just placed, as a settled transaction placed under a
-- seven-year policy with a thirty-day purge window.
run ShowRetained {
    some r : Ret | recorded[r] and r.state = Retained
} for 3 but 5 Int

-- ShowPurgedInWindow: a retention purged between its retention deadline and its purge
-- deadline, on time.
run ShowPurgedInWindow {
    some r : Ret | recorded[r] and r.state = Purged
        and (all p : r.purgedAt, d : r.purgeDeadline | p <= d)
} for 3 but 5 Int

-- ShowPurgeAtDeadline: a retention purged at the very instant its retention deadline
-- falls on, which the gate admits (Term purge eligible: now does not precede it).
run ShowPurgeAtDeadline {
    some r : Ret | recorded[r] and r.state = Purged and r.purgedAt = r.retentionUntil
} for 3 but 5 Int

-- ShowOvershoot: a retention purged after its purge deadline, which the page admits and
-- an auditor reads as overshoot (Invariant 8.3, Operation 18, Check 4.1).
run ShowOvershoot {
    some r : Ret | recorded[r] and r.state = Purged
        and (all p : r.purgedAt, d : r.purgeDeadline | p > d)
} for 3 but 5 Int

-- ShowZeroDelay: a policy whose max purge delay is the zero duration, which Operation 8
-- admits: the purge deadline falls on the retention deadline.
run ShowZeroDelay {
    some r : Ret | recorded[r] and r.purgeDeadline = r.retentionUntil
} for 3 but 5 Int

-- ShowTwoRetentionsOneRecord: two retentions over one record reference under two
-- policies, each with its own id, which the page admits (Simultaneous retention 1,
-- Identity 9, Check 5.1).
run ShowTwoRetentionsOneRecord {
    some r1, r2 : Ret | recorded[r1] and recorded[r2] and origin[r1] != origin[r2]
        and r1.rec = r2.rec and r1.pol != r2.pol
} for 3 but 5 Int
