-- session-buggy-issue-zero-window.als
-- DELIBERATELY WRONG twin of session.als (unit: `atoms/session.md formal layer`).
--
-- INJECTED DEFECT: [Issue] admits a supplied session duration of zero (Operation 8: it must
-- exceed the zero duration), so a window closes the instant it opens.
--
-- BREAKS: A_Check_1_3.
-- Everything else is session.als as written; read its comments there.

module session_buggy_issue_zero_window

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a string a call carries or a session holds: a principal reference, an issued by
-- reference, a revoked by reference or a reason. The atom never interprets an opaque
-- reference (Identity 11, 12) and compares strings byte-exactly (String 1), so a string
-- is an uninterpreted token and two different strings are two different atoms.
sig Str {}

-- Strings: which strings the page's guards refuse: the blank ones, whitespace-only
-- included (String 5).
one sig Strings {
    blank : set Str
}

-- Token: a session token, the opaque value naming one session (Term session token). The
-- host allocates it at the seam (Identity 3); the atom only records and compares it.
sig Token {}

-- Status: what a session's stored status field could hold. The page's stored status is
-- active or revoked (Term status); Expired is the derived effective status's member,
-- which the page forbids storing (Invariant 12.1). It is in the type so a write that
-- stored it would show; that none does is checked, never built in.
abstract sig Status {}

-- Active, Revoked, Expired: in force; cancelled and terminal; the derived lapse.
one sig Active, Revoked, Expired extends Status {}

-- Config: the deployment's configuration (Capability requirement 2): the default session
-- duration, absent where none is configured. Any value may stand, zero and negative
-- included; Operation 48 and 56 refuse every [Issue] while it is absent or not positive.
one sig Config {
    defaultDuration : lone Int
}

-- Call: one call of a writing action ([Issue], [Revoke]). The host injects the clock
-- reading, now, at the seam (Capability requirement 1). Calls happen in one order, the
-- order Execution Contract Order 1 gives every commit.
abstract sig Call {
    now : one Int    -- the injected now
}

-- IssueCall: one [Issue] call, issue(principal_ref, issued_by_ref, optional
-- session_duration), with the session token the host allocated at the seam for it
-- (Identity 3, Capability requirement 3).
sig IssueCall extends Call {
    prinIn  : one Str,     -- principal_ref
    issIn   : one Str,     -- issued_by_ref
    durIn   : lone Int,    -- session_duration, absent where the call supplies none
    hostTok : one Token    -- the session token the host allocated
}

-- RevokeCall: one [Revoke] call, revoke(session_token, revoked_by_ref, reason).
sig RevokeCall extends Call {
    tokIn    : one Token,  -- session_token
    byIn     : one Str,    -- revoked_by_ref
    reasonIn : one Str     -- reason
}

-- Sess: one version of a session record (Term records), as the call that wrote it left
-- it. Every field the page names may be absent, and the status is a set, so a write that
-- forgot a field or left two statuses would show; what the page promises (State 1 to 7)
-- is checked, never built into the type. lapsedAt is the field Invariant 12.2 forbids
-- (an expiry timestamp beside the expiry instant, the Intent's `expired_at` column), in
-- the type so a write that stamped one would show. The last two fields are the model's
-- own: which call wrote this version, and which version a [Revoke] found.
sig Sess {
    token     : lone Token,   -- session token
    principal : lone Str,     -- principal reference
    issuer    : lone Str,     -- issued by reference
    issuedAt  : lone Int,     -- issuance instant
    expiresAt : lone Int,     -- expiry instant
    status    : set Status,   -- status
    revokedAt : lone Int,     -- revocation instant
    revokedBy : lone Str,     -- revoked by reference
    reason    : lone Str,     -- revocation reason
    lapsedAt  : lone Int,     -- an expiry timestamp beside the expiry instant (forbidden)
    writtenBy : one Call,
    found     : lone Sess
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The host's clock reads an instant from 0 to 7 seconds into the model's span (Capability
-- requirement 1: the deployment supplies now). Kept small so an expiry deadline is an
-- instant the model can hold (see NOT MODELED HERE).
fact ClockReadsTheModelsSpan {
    all c : Call | c.now >= 0 and c.now <= 7
}

-- A supplied session duration and the configured default are any whole number of seconds
-- from -7 to 7, zero and below included (the caller's and the deployment's; Capability
-- requirement 2). The page sets no maximum (Non-goal 28); this bound is the model's, so a
-- deadline stays in range.
fact DurationsWithinTheModelsSpan {
    all c : IssueCall, d : c.durIn | d >= -7 and d <= 7
    all d : Config.defaultDuration | d >= -7 and d <= 7
}

-- The host allocates, for each [Issue], a session token no session recorded before it
-- carries (Identity 3: the host allocates at the seam; Invariant 7.2 binds the host). The
-- atom takes the token from outside; whether the host keeps this duty across steps is
-- checked in the TLA+ model (Inv7_2_HostTokenFresh).
fact HostAllocatesAnUncarriedToken {
    all c : IssueCall | no v : Sess |
        recorded[v] and C/lt[v.writtenBy, c] and v.token = c.hostTok
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- usable: a string the guards accept: not blank (String 5).
pred usable[s : Str] {
    s not in Strings.blank
}

-- window: the session duration an [Issue] applies: the one the call supplies, or the
-- default session duration where it supplies none (Operation 6, Term expiry deadline).
fun window[c : IssueCall] : set Int {
    (some c.durIn) implies c.durIn else Config.defaultDuration
}

-- first: the first version of the session this version belongs to, the one [Issue] wrote.
fun first[r : Sess] : set Sess {
    { v : r.*found | no v.found }
}

-- origin: the [Issue] call that recorded the session this version belongs to. Two
-- versions with one origin are one session; two origins are two sessions.
fun origin[r : Sess] : set IssueCall {
    first[r].writtenBy & IssueCall
}

-- lapsedFor: the session, as found, is lapsed at the call's now: stored active and now no
-- earlier than its expiry instant (Term lapsed).
pred lapsedFor[pre : Sess, c : Call] {
    pre.status = Active
    some pre.expiresAt and c.now >= pre.expiresAt
}

-- keepsTheIssue: the later version carries what [Issue] recorded, as found: a [Revoke]
-- writes only the status and the revocation fields (Invariant 1.2).
pred keepsTheIssue[pre, post : Sess] {
    post.token     = pre.token
    post.principal = pre.principal
    post.issuer    = pre.issuer
    post.issuedAt  = pre.issuedAt
    post.expiresAt = pre.expiresAt
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- issueWrites: the session an admitted [Issue] records, and the guards it passes first:
-- both references non-blank (Operation 4, 5), a default session duration configured and
-- above the zero duration (Operation 48, 56), and a supplied session duration above the
-- zero duration (Operation 8). The session carries the token the host allocated
-- (Operation 58), the call's references (Operation 50, 51), the injected now as its
-- issuance instant (Operation 9), the expiry deadline as its expiry instant (Operation 6,
-- 10), status active (Operation 2), and no revocation field and no lapse stamp.
pred issueWrites[c : IssueCall, r : Sess] {
    usable[c.prinIn]                                                  -- Operation 4
    usable[c.issIn]                                                   -- Operation 5
    some Config.defaultDuration                                       -- Operation 48
    Config.defaultDuration > 0                                        -- Operation 56
    all d : c.durIn | d >= 0  -- BUG: a zero duration admitted
    r.token     = c.hostTok                                           -- Operation 58
    r.principal = c.prinIn                                            -- Operation 50
    r.issuer    = c.issIn                                             -- Operation 51
    r.issuedAt  = c.now                                               -- Operation 9
    r.expiresAt = plus[c.now, window[c]]                              -- Operation 6, 10
    r.status    = Active                                              -- Operation 2
    no r.revokedAt
    no r.revokedBy
    no r.reason
    no r.lapsedAt
}

-- revokeWrites: the version an admitted [Revoke] records over the version it found: the
-- call's token names the session (Operation 22, Identity 1), the session stands active
-- (Operation 23), and the revoked by reference and the reason are non-blank (Operation
-- 25, 26). A lapsed session is accepted (Operation 27): no guard reads the clock
-- (Clock dependence 2). The version stands in revoked (Operation 28), carries the
-- injected now as its revocation instant (Operation 29), the revoked by reference
-- (Operation 30) and the reason as its revocation reason (Operation 31), and keeps what
-- [Issue] recorded.
pred revokeWrites[pre : Sess, c : RevokeCall, r : Sess] {
    pre.token = c.tokIn                                               -- Operation 22, Identity 1
    pre.status = Active                                               -- Operation 23
    usable[c.byIn]                                                    -- Operation 25
    usable[c.reasonIn]                                                -- Operation 26
    keepsTheIssue[pre, r]
    r.status    = Revoked                                             -- Operation 28
    r.revokedAt = c.now                                               -- Operation 29
    r.revokedBy = c.byIn                                              -- Operation 30
    r.reason    = c.reasonIn                                          -- Operation 31
    r.lapsedAt  = pre.lapsedAt
}

-- written: the version is what its call's write left: an [Issue] writes a first version;
-- a [Revoke] writes over a version an earlier call wrote (a call finds only what was
-- committed before it, Execution Contract Database 2).
pred written[v : Sess] {
    let c = v.writtenBy {
        (c in IssueCall and no v.found and issueWrites[c, v])
        or (c in RevokeCall and some v.found
            and C/lt[v.found.writtenBy, c] and revokeWrites[v.found, c, v])
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): it and every version it
-- was built from are what an admitted call wrote.
pred recorded[r : Sess] {
    all v : r.*found | written[v]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every session stands in exactly one of active and revoked (State 1).
assert A_State_1 {
    all r : Sess | recorded[r] implies one r.status
}
check A_State_1 for 4 but 5 Int

-- A_State_2: every session carries its session token, principal reference, issued by
-- reference, issuance instant, expiry instant and status, whichever call last wrote it
-- (State 2).
assert A_State_2 {
    all r : Sess | recorded[r] implies {
        some r.token
        some r.principal
        some r.issuer
        some r.issuedAt
        some r.expiresAt
        some r.status
    }
}
check A_State_2 for 4 but 5 Int

-- A_State_4: a revoked session carries its revocation instant, revoked by reference and
-- revocation reason: when, by whom and why it was cancelled (State 4).
assert A_State_4 {
    all r : Sess | (recorded[r] and Revoked in r.status) implies {
        some r.revokedAt
        some r.revokedBy
        some r.reason
    }
}
check A_State_4 for 4 but 5 Int

-- A_State_5: an active session carries no revocation instant (State 5).
assert A_State_5 {
    all r : Sess | (recorded[r] and Active in r.status) implies no r.revokedAt
}
check A_State_5 for 4 but 5 Int

-- A_State_6: an active session carries no revoked by reference (State 6).
assert A_State_6 {
    all r : Sess | (recorded[r] and Active in r.status) implies no r.revokedBy
}
check A_State_6 for 4 but 5 Int

-- A_State_7: an active session carries no revocation reason (State 7).
assert A_State_7 {
    all r : Sess | (recorded[r] and Active in r.status) implies no r.reason
}
check A_State_7 for 4 but 5 Int

-- A_Identity_1: a version a [Revoke] wrote carries the session token that call named: a
-- session is found by its token, never by its principal or by anything else, so one
-- token's logout never cancels another session (Identity 1; Non-goal 14).
assert A_Identity_1 {
    all r : Sess | (recorded[r] and r.writtenBy in RevokeCall)
        implies r.token = r.writtenBy.tokIn
}
check A_Identity_1 for 4 but 5 Int

-- A_Invariant_7_1: no two sessions share a session token, so a token names one session
-- and [Validate] has one record to answer from (Invariant 7.1).
assert A_Invariant_7_1 {
    all r1, r2 : Sess | (recorded[r1] and recorded[r2] and origin[r1] != origin[r2])
        implies no (r1.token & r2.token)
}
check A_Invariant_7_1 for 4 but 5 Int

-- A_Invariant_8_1: every revoked session carries a revocation instant (Invariant 8.1,
-- Check 4.1).
assert A_Invariant_8_1 {
    all r : Sess | (recorded[r] and Revoked in r.status) implies some r.revokedAt
}
check A_Invariant_8_1 for 4 but 5 Int

-- A_Invariant_8_2: every revoked session's revoked by reference is non-blank: who
-- cancelled it is always named (Invariant 8.2, Check 4.1).
assert A_Invariant_8_2 {
    all r : Sess | (recorded[r] and Revoked in r.status) implies
        (some r.revokedBy and no (r.revokedBy & Strings.blank))
}
check A_Invariant_8_2 for 4 but 5 Int

-- A_Invariant_8_3: every revoked session's revocation reason is non-blank: why it was
-- cancelled is always stated (Invariant 8.3, Check 4.1).
assert A_Invariant_8_3 {
    all r : Sess | (recorded[r] and Revoked in r.status) implies
        (some r.reason and no (r.reason & Strings.blank))
}
check A_Invariant_8_3 for 4 but 5 Int

-- A_Invariant_10_1: every session carries an expiry instant: no session lives for ever
-- (Invariant 10.1, Check 1.1).
assert A_Invariant_10_1 {
    all r : Sess | recorded[r] implies some r.expiresAt
}
check A_Invariant_10_1 for 4 but 5 Int

-- A_Invariant_12_1: no session carries a stored expired status: the lapse is derived at
-- read time, never written (Invariant 12.1, Check 2.1).
assert A_Invariant_12_1 {
    all r : Sess | recorded[r] implies Expired not in r.status
}
check A_Invariant_12_1 for 4 but 5 Int

-- A_Invariant_12_2: no session carries an expiry timestamp beside its expiry instant
-- (Invariant 12.2, Check 2.2).
assert A_Invariant_12_2 {
    all r : Sess | recorded[r] implies no r.lapsedAt
}
check A_Invariant_12_2 for 4 but 5 Int

-- A_Check_1_3: every session's issuance instant precedes its expiry instant: no session
-- is issued with a window already closed (Check 1.3; Operation 8, 10, 56).
assert A_Check_1_3 {
    all r : Sess | recorded[r] implies
        (all i : r.issuedAt, e : r.expiresAt | i < e)
}
check A_Check_1_3 for 4 but 5 Int

-- A_Operation_4: no session carries a blank principal reference (Operation 4, String 5).
assert A_Operation_4 {
    all r : Sess | recorded[r] implies no (r.principal & Strings.blank)
}
check A_Operation_4 for 4 but 5 Int

-- A_Operation_5: no session carries a blank issued by reference (Operation 5, String 5).
assert A_Operation_5 {
    all r : Sess | recorded[r] implies no (r.issuer & Strings.blank)
}
check A_Operation_5 for 4 but 5 Int

-- A_Operation_10: every session's expiry instant is its issuance instant plus the window
-- its [Issue] applied: the session duration it supplied, or the default session duration
-- where it supplied none (Operation 10, Operation 6, Term expiry deadline).
assert A_Operation_10 {
    all r : Sess | recorded[r] implies
        (all o : origin[r] | r.expiresAt = plus[r.issuedAt, window[o]])
}
check A_Operation_10 for 4 but 5 Int

-- A_Operation_58: every version of a session carries the session token the host
-- allocated for the [Issue] that recorded it: the transition mints no token of its own
-- (Operation 58, Identity 4, Identity 6).
assert A_Operation_58 {
    all r : Sess | recorded[r] implies r.token = origin[r].hostTok
}
check A_Operation_58 for 4 but 5 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowActive: a session just issued with the duration the call supplied, as tok_abc123
-- for user_u91, issued at 10:00:00Z and expiring at 11:00:00Z.
run ShowActive {
    some r : Sess | recorded[r] and r.status = Active and some origin[r].durIn
} for 4 but 5 Int

-- ShowDefaultWindow: a session issued with no session duration, the default session
-- duration applied (Operation 6).
run ShowDefaultWindow {
    some r : Sess | recorded[r] and r.status = Active and no origin[r].durIn
} for 4 but 5 Int

-- ShowRevokedInsideWindow: a session revoked before its deadline, as the logout at
-- 10:45:00Z of a session expiring at 11:00:00Z.
run ShowRevokedInsideWindow {
    some r : Sess | recorded[r] and r.status = Revoked
        and (all t : r.revokedAt, e : r.expiresAt | t < e)
} for 4 but 5 Int

-- ShowRevokedAfterLapse: a session revoked after its deadline had passed, which the page
-- admits, so every closure is attributed (Operation 27; the breach investigation).
run ShowRevokedAfterLapse {
    some r : Sess | recorded[r] and r.status = Revoked
        and (all t : r.revokedAt, e : r.expiresAt | t >= e)
} for 4 but 5 Int

-- ShowTwoSessionsOnePrincipal: two sessions for one principal reference, which the page
-- admits: the atom bounds no number of sessions per principal (Concurrency 4, Non-goal
-- 12).
run ShowTwoSessionsOnePrincipal {
    some r1, r2 : Sess | recorded[r1] and recorded[r2] and origin[r1] != origin[r2]
        and r1.principal = r2.principal
} for 4 but 5 Int
