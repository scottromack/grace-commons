-- permissions-buggy-grant-scope-unguarded.als
-- DELIBERATELY WRONG twin of permissions.als (unit: `atoms/permissions.md formal layer`).
--
-- INJECTED DEFECT: [Grant] checks the action scope against the string cap but not for blank, so an
-- empty or whitespace-only scope is recorded (Operation 5).
--
-- BREAKS: A_Operation_5.
-- Everything else is permissions.als as written; read its comments there.

module permissions_buggy_grant_scope_unguarded

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a string a [Grant] carries: a subject reference or an action scope. The atom never
-- interprets one and compares them byte-exactly (String 1), so a string is an
-- uninterpreted token and two different strings are two different atoms.
sig Str {}

-- Strings: which strings the page's guards refuse: the blank ones, whitespace-only
-- included (String 5), and the ones longer than the string cap (String 6).
one sig Strings {
    blank    : set Str,
    overCap  : set Str
}

-- GrantId: an opaque grant id the host allocates at the seam (Identity 2, Term grant id).
sig GrantId {}

-- Status: the grant's status (Term status): active or revoked.
abstract sig Status {}

-- Active, Revoked: the two statuses: in force, or withdrawn and terminal.
one sig Active, Revoked extends Status {}

-- Call: one call of a writing action ([Grant], [Revoke]). The host injects the clock
-- reading, now, at the seam (Capability requirement 1; Term now). Calls happen in one
-- order, the order Execution Contract Order 1 gives every commit.
abstract sig Call {
    now : one Int   -- the injected now
}

-- GrantCall: one [Grant] call, grant(subject_ref, action_scope), with the grant id the host
-- allocated for it at the seam (Identity 2, 4: the business caller supplies none).
sig GrantCall extends Call {
    subjIn  : one Str,       -- subject_ref
    scopeIn : one Str,       -- action_scope
    idIn    : one GrantId    -- the host's allocation
}

-- RevokeCall: one [Revoke] call, revoke(grant_id).
sig RevokeCall extends Call {
    gidIn : one GrantId      -- grant_id
}

-- Rec: one version of a grant record (Term records), as the call that wrote it left it.
-- Every field the page names may be absent, and the status is a set, so a write that forgot
-- a field or left two statuses would show; what the page promises (State 1 to 5) is
-- checked, never built into the type. The last two fields are the model's own: which call
-- wrote this version, and which version a [Revoke] found.
sig Rec {
    grantId   : lone GrantId,   -- grant id
    subject   : lone Str,       -- subject reference
    scope     : lone Str,       -- action scope
    grantedAt : lone Int,       -- grant instant
    status    : set Status,     -- status
    revokedAt : lone Int,       -- revocation instant
    writtenBy : one Call,
    found     : lone Rec
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The host's clock reads an instant from 0 to 7 seconds into the model's span (Capability
-- requirement 1: the deployment supplies now).
fact ClockReadsTheModelsSpan {
    all c : Call | c.now >= 0 and c.now <= 7
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- usable: a string [Grant]'s guards accept: not blank and not over the string cap.
pred usable[s : Str] {
    s not in Strings.blank + Strings.overCap
}

-- first: the first version of the grant this version belongs to, the one [Grant] wrote.
fun first[r : Rec] : set Rec {
    { v : r.*found | no v.found }
}

-- origin: the [Grant] call that recorded the grant this version belongs to.
fun origin[r : Rec] : set GrantCall {
    first[r].writtenBy & GrantCall
}

-- standsBefore: the version v stands just before the call c: an earlier call wrote it, and
-- no [Revoke] before c wrote a version over it, so it is the latest version of its grant that
-- c finds (Execution Contract Database 2). Every version is asked, so one a stale write left
-- can only hold a [Grant] back, never let one through.
pred standsBefore[v : Rec, c : Call] {
    C/lt[v.writtenBy, c]
    no w : Rec | w.found = v and w.writtenBy in RevokeCall
        and C/lt[v.writtenBy, w.writtenBy] and C/lt[w.writtenBy, c]
        and revokeWrites[v, w.writtenBy, w]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- grantWrites: the grant an admitted [Grant] records, and the guards it passes first: the
-- subject reference and the action scope not blank (Operation 4, 5) and within the string
-- cap (String 6). The grant carries the grant id the host allocated (Identity 2, Invariant
-- 4.1), the pair as the call carries it, the injected now as its grant instant (State 4),
-- status active (Operation 2), and no revocation instant. It records a grant only where no
-- active grant over the pair stands just before it (Operation 1, Operation 34: a held pair
-- writes nothing; what such a call answers, Operation 33, is the TLA+ model's).
pred grantWrites[c : GrantCall, r : Rec] {
    usable[c.subjIn]                                                  -- Operation 4, String 6
    c.scopeIn not in Strings.overCap  -- BUG: blank not refused
    no v : Rec | standsBefore[v, c] and Active in v.status
        and v.subject = c.subjIn and v.scope = c.scopeIn              -- Operation 34, Operation 1
    r.grantId   = c.idIn                                              -- Identity 2
    r.subject   = c.subjIn                                            -- Operation 1
    r.scope     = c.scopeIn                                           -- Operation 1
    r.grantedAt = c.now                                               -- State 4
    r.status    = Active                                              -- Operation 2
    no r.revokedAt
}

-- revokeWrites: the version an admitted [Revoke] records over the version it found: the
-- call's grant id names the grant (Operation 9, Identity 1), and the grant stands in active
-- (Operation 10). The version stands in revoked (Operation 11), carries the injected now as
-- its revocation instant (State 5), and keeps the grant id, the pair and the grant instant.
pred revokeWrites[pre : Rec, c : RevokeCall, r : Rec] {
    pre.grantId = c.gidIn                                             -- Operation 9, Identity 1
    pre.status  = Active                                              -- Operation 10
    r.grantId   = pre.grantId
    r.subject   = pre.subject
    r.scope     = pre.scope
    r.grantedAt = pre.grantedAt
    r.status    = Revoked                                             -- Operation 11
    r.revokedAt = c.now                                               -- State 5
}

-- written: the version is what its call's write left: a [Grant] writes a first version; a
-- [Revoke] writes over a version an earlier call wrote (a call finds only what was
-- committed before it, Execution Contract Database 2).
pred written[v : Rec] {
    let c = v.writtenBy {
        (c in GrantCall and no v.found and grantWrites[c, v])
        or (c in RevokeCall and some v.found
            and C/lt[v.found.writtenBy, c] and revokeWrites[v.found, c, v])
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): it and every version it
-- was built from are what an admitted call wrote.
pred recorded[r : Rec] {
    all v : r.*found | written[v]
}

-- stateAfter: the grant records as they stand once the call k has committed: every recorded
-- version written by k or before it over which no [Revoke] by then wrote a later version.
fun stateAfter[k : Call] : set Rec {
    { r : Rec | recorded[r] and C/lte[r.writtenBy, k]
        and no w : Rec | recorded[w] and w.found = r and C/lte[w.writtenBy, k] }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every grant stands in exactly one of active and revoked (State 1).
assert A_State_1 {
    all r : Rec | recorded[r] implies one r.status
}
check A_State_1 for 4 but 4 Int

-- A_State_2: every grant carries its grant id, subject reference, action scope, grant
-- instant and status, whichever call last wrote it (State 2, Check 1.1).
assert A_State_2 {
    all r : Rec | recorded[r] implies {
        some r.grantId
        some r.subject
        some r.scope
        some r.grantedAt
        some r.status
    }
}
check A_State_2 for 4 but 4 Int

-- A_State_3: a revoked grant carries a revocation instant, so an auditor reads when the
-- access ended (State 3, Check 1.2).
assert A_State_3 {
    all r : Rec | (recorded[r] and Revoked in r.status) implies some r.revokedAt
}
check A_State_3 for 4 but 4 Int

-- A_State_4: every version's grant instant is the now the host injected into the [Grant]
-- that recorded the grant, a revoked version included (State 4).
assert A_State_4 {
    all r : Rec | recorded[r] implies r.grantedAt = origin[r].now
}
check A_State_4 for 4 but 4 Int

-- A_State_5: a version a [Revoke] wrote carries, as its revocation instant, the now the host
-- injected into that [Revoke] (State 5).
assert A_State_5 {
    all r : Rec | (recorded[r] and r.writtenBy in RevokeCall) implies
        r.revokedAt = r.writtenBy.now
}
check A_State_5 for 4 but 4 Int

-- A_Identity_1: a version a [Revoke] wrote carries the grant id that call named: a grant is
-- reached by its id, never by anything else it carries (Identity 1).
assert A_Identity_1 {
    all r : Rec | (recorded[r] and r.writtenBy in RevokeCall) implies
        r.grantId = r.writtenBy.gidIn
}
check A_Identity_1 for 4 but 4 Int

-- A_Invariant_8_1: no grant whose status holds revoked stands in the active grant set, the
-- grants whose status holds active (Invariant 8.1, Term active grant set).
assert A_Invariant_8_1 {
    all r : Rec | (recorded[r] and Revoked in r.status) implies Active not in r.status
}
check A_Invariant_8_1 for 4 but 4 Int

-- A_Operation_2: the grant a [Grant] records stands in active (Operation 2).
assert A_Operation_2 {
    all r : Rec | (recorded[r] and r.writtenBy in GrantCall) implies r.status = Active
}
check A_Operation_2 for 4 but 4 Int

-- A_Operation_4: no grant carries a blank subject reference (Operation 4, String 5).
assert A_Operation_4 {
    all r : Rec | recorded[r] implies no (r.subject & Strings.blank)
}
check A_Operation_4 for 4 but 4 Int

-- A_Operation_5: no grant carries a blank action scope (Operation 5, String 5).
assert A_Operation_5 {
    all r : Rec | recorded[r] implies no (r.scope & Strings.blank)
}
check A_Operation_5 for 4 but 4 Int

-- A_String_6: no grant carries a subject reference or an action scope longer than the
-- string cap (String 6).
assert A_String_6 {
    all r : Rec | recorded[r] implies no ((r.subject + r.scope) & Strings.overCap)
}
check A_String_6 for 4 but 4 Int

-- A_Invariant_11_1: in the grant records as they stand after any call, no two grants whose
-- status holds active are over one pair: two such versions are versions of one grant, carrying
-- one grant id (Invariant 11.1, Identity 7, Check 7.1).
assert A_Invariant_11_1 {
    all k : Call | all r1, r2 : stateAfter[k] |
        (Active in r1.status and Active in r2.status
            and r1.subject = r2.subject and r1.scope = r2.scope) implies r1.grantId = r2.grantId
}
check A_Invariant_11_1 for 4 but 4 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowActive: a grant in force, as g1 binding teller_t9 to initiate:transfer.
run ShowActive {
    some r : Rec | recorded[r] and r.status = Active
} for 4 but 4 Int

-- ShowRevoked: a grant withdrawn, its revocation instant stamped, as g14 after Dr. Chen's
-- patient is transferred.
run ShowRevoked {
    some r : Rec | recorded[r] and r.status = Revoked and some r.revokedAt
} for 4 but 4 Int

-- ShowPairGrantedAgain: a pair granted, revoked and granted again, the second grant a new one
-- with its own grant id, the first standing revoked beside it, as the page admits (a revoked
-- pair may be granted again, as a new grant; Identity 7 holds over the active grants alone).
run ShowPairGrantedAgain {
    some k : Call | some r1, r2 : stateAfter[k] |
        r1.subject = r2.subject and r1.scope = r2.scope and r1.grantId != r2.grantId
        and r1.status = Revoked and r2.status = Active
} for 4 but 4 Int

-- ShowHeldPairNotRecorded: a [Grant] of a pair an active grant already holds records nothing,
-- the earlier grant standing alone over the pair, as teller_t9's second grant of
-- initiate:transfer answers g1 (Operation 34, Identity 7).
run ShowHeldPairNotRecorded {
    some disj c1, c2 : GrantCall | C/lt[c1, c2] and c1.subjIn = c2.subjIn
        and c1.scopeIn = c2.scopeIn and usable[c2.subjIn] and usable[c2.scopeIn]
        and (some r : stateAfter[c2] | r.writtenBy = c1 and r.status = Active)
        and no r : Rec | recorded[r] and r.writtenBy = c2
} for 4 but 4 Int

-- ShowRevokedAtItsGrantInstant: a grant revoked at the clock reading it was granted at,
-- which the page admits (Invariant 9.1 forbids only a revocation instant before it).
run ShowRevokedAtItsGrantInstant {
    some r : Rec | recorded[r] and r.status = Revoked and r.revokedAt = r.grantedAt
} for 4 but 4 Int
