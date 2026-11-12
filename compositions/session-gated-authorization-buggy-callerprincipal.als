-- session-gated-authorization-buggy-callerprincipal.als
-- DELIBERATELY WRONG twin of session-gated-authorization.als (unit: `compositions/session-gated-authorization.md formal layer`).
--
-- INJECTED DEFECT: permitted is asked of the principal the request carries, where it carries one, instead of the session's (Invariant 2.1, Action wiring 7, 8).
--
-- BREAKS: A_Invariant_2_1, A_Invariant_2_2.
-- Everything else is session-gated-authorization.als as written; read its comments there.

module session_gated_authorization_buggy_callerprincipal

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: an opaque input a caller presents, a session token or an action scope. The
-- composition compares it byte-exact (Primitive policy 5). folded is what trimming,
-- case-folding or normalizing it would make of it (Primitive policy 6 to 8): another string,
-- which the composition never uses.
sig Str {
    folded : one Str
}

-- Blank: the inputs that are blank (empty, whitespace-only). Which strings are blank is a
-- fact of the strings, taken from outside.
sig Blank in Str {}

-- OverLong: the inputs over the length bound (Term length bound). Which strings exceed it is
-- a fact of the strings and the deployment's bound, taken from outside.
sig OverLong in Str {}

-- Prin: a principal reference: the one a session was issued for, a grant's subject, or a
-- value a forged request carries.
sig Prin {}

-- Instant: an expiry instant a valid answer carries.
sig Instant {}

-- Session: one of Session's sessions: its token, the principal it was issued for and its
-- expiry instant (Session's own records, read through validate).
sig Session {
    stok  : one Str,
    sprin : one Prin,
    sexp  : one Instant
}

-- Grant: one of Permissions' active grants: a subject and an action scope.
sig Grant {
    gsubj  : one Prin,
    gscope : one Str
}

-- VKind: what Session's validate answered: valid, one of the three invalid reasons
-- (Term invalid answer), or state-unavailable for a failed read.
abstract sig VKind {}
one sig VValid, VExpired, VRevoked, VNotKnown, VUnavailable extends VKind {}

-- VCall: one call of Session's validate: the token it was asked with and its answer; a valid
-- answer carries a principal reference and an expiry instant (Term valid answer).
sig VCall {
    vtok  : one Str,
    vkind : one VKind,
    vprin : lone Prin,
    vexp  : lone Instant
}

-- PKind: what Permissions' permitted answered: permitted, denied, or state-unavailable.
abstract sig PKind {}
one sig PPermitted, PDenied, PUnavailable extends PKind {}

-- PCall: one call of Permissions' permitted: the subject and the scope it was asked with,
-- and its answer.
sig PCall {
    psubj  : one Prin,
    pscope : one Str,
    pkind  : one PKind
}

-- AKind: the composition's answer: permitted, denied, invalid-request, session-invalid or
-- state-unavailable (the action's signature).
abstract sig AKind {}
one sig Permitted, Denied, InvalidRequest, SessionInvalid, StateUnavailable extends AKind {}

-- Reason: the reason a session-invalid answer names (Term value sets: invalid answer reasons).
abstract sig Reason {}
one sig Expired, Revoked, NotKnown extends Reason {}

-- Call: one [Check Permitted] call. tok and scope are its two inputs; claimed is a principal
-- reference a forged request may carry beside them, which the action does not accept
-- (Action wiring 7; the section titled Intent). vc and pc are the constituent calls it made;
-- ans its answer, reason the reason a session-invalid answer names, and leak an expiry
-- instant the answer carries.
sig Call {
    tok     : one Str,
    scope   : one Str,
    claimed : lone Prin,
    vc      : lone VCall,
    pc      : set PCall,
    ans     : one AKind,
    reason  : lone Reason,
    leak    : lone Instant
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: only what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- TokenNamesOneSession: a session token names at most one session (Session's own identity
-- rule).
fact TokenNamesOneSession {
    all disj s1, s2 : Session | s1.stok != s2.stok
}

-- SessionValidateAnswers: what Session's validate guarantees of an answer: a valid answer
-- carries the principal and the expiry instant of the session the token names; any other
-- answer carries neither; not-known only for a token naming no session; expired or revoked
-- only for one naming a session. Which of these a token gets at the call's instant is
-- Session's, taken from outside.
fact SessionValidateAnswers {
    all v : VCall {
        v.vkind = VValid implies
            (some s : Session | s.stok = v.vtok and v.vprin = s.sprin and v.vexp = s.sexp)
        v.vkind != VValid implies (no v.vprin and no v.vexp)
        v.vkind = VNotKnown implies no stok.(v.vtok)
        v.vkind in VExpired + VRevoked implies some stok.(v.vtok)
    }
}

-- PermissionsAnswers: what Permissions' permitted guarantees: where its read succeeds, it
-- answers permitted exactly when an active grant covers the subject and the scope asked, and
-- denied otherwise (Permissions' default deny).
fact PermissionsAnswers {
    all q : PCall | q.pkind != PUnavailable implies
        (q.pkind = PPermitted iff some g : Grant | g.gsubj = q.psubj and g.gscope = q.pscope)
}

-- ConstituentCallsAreCalls: every validate and permitted call in the state belongs to one
-- [Check Permitted] call (the model's scope: the constituents' other callers are the
-- deployment's, Non-goal 9 and 13).
fact ConstituentCallsAreCalls {
    all v : VCall | one vc.v
    all q : PCall | one pc.q
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The wiring: what the composition does with each answer
-- ─────────────────────────────────────────────────────────────────────────────

-- refusedInput: the boundary predicate (Term boundary predicate): an input is blank or over
-- the length bound.
pred refusedInput[c : Call] {
    c.tok in Blank + OverLong or c.scope in Blank + OverLong
}

-- admitted: an admitted gate (Term admitted gate): the inputs cleared the boundary
-- predicate and Session's validate gave a valid answer.
pred admitted[c : Call] {
    not refusedInput[c]
    some c.vc
    c.vc.vkind = VValid
}

-- checkPermitted: the action's wiring for one call. A refused input answers invalid-request
-- and calls nothing (Primitive policy 2 to 4, 9). Otherwise validate is called with the
-- session token (Action wiring 2, 3, 13). A valid answer: permitted is called once, with the
-- valid answer's principal and the action scope (Action wiring 5, 6; Wiring decision 1),
-- and its answer is the call's (Action wiring 10, 11). An invalid answer: session-invalid
-- naming its reason, permitted not called (Action wiring 9, Invariant 1.1). A failed read of
-- either constituent: state-unavailable. No answer carries the expiry instant (Action
-- wiring 12).
pred checkPermitted[c : Call] {
    no c.leak
    refusedInput[c] implies {
        c.ans = InvalidRequest
        no c.vc
        no c.pc
        no c.reason
    } else {
        one c.vc
        c.vc.vtok = c.tok
        c.vc.vkind = VValid implies {
            one c.pc
            (some c.claimed implies c.pc.psubj = c.claimed else c.pc.psubj = c.vc.vprin)  -- BUG: a caller-supplied subject
            c.pc.pscope = c.scope
            c.pc.pkind = PPermitted implies c.ans = Permitted
            c.pc.pkind = PDenied implies c.ans = Denied
            c.pc.pkind = PUnavailable implies c.ans = StateUnavailable
            no c.reason
        }
        c.vc.vkind in VExpired + VRevoked + VNotKnown implies {
            no c.pc
            c.ans = SessionInvalid
            c.vc.vkind = VExpired implies c.reason = Expired
            c.vc.vkind = VRevoked implies c.reason = Revoked
            c.vc.vkind = VNotKnown implies c.reason = NotKnown
        }
        c.vc.vkind = VUnavailable implies {
            no c.pc
            c.ans = StateUnavailable
            no c.reason
        }
    }
}

-- Built: every call in the state is one the composition's wiring made.
pred Built {
    all c : Call | checkPermitted[c]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any set of calls the wiring can make, over any answers the
-- constituents can give, that violates this assertion? No counterexample (UNSAT) = the
-- guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: a call that called Permissions' permitted had a valid answer from
-- Session's validate in that call (Invariant 1.1; Wiring decision 1).
assert A_Invariant_1_1 {
    Built implies all c : Call | some c.pc implies (some c.vc and c.vc.vkind = VValid)
}
check A_Invariant_1_1 for 4

-- A_Invariant_2_1: every subject Permissions' permitted receives is the principal reference
-- of the call's valid answer (Invariant 2.1, Action wiring 5).
assert A_Invariant_2_1 {
    Built implies all c : Call, q : c.pc | q.psubj = c.vc.vprin
}
check A_Invariant_2_1 for 4

-- A_Invariant_2_2: a call queries no principal reference beside the session's own: every
-- subject it asks Permissions about is the principal of the session its token names, a
-- principal the request carries included (Invariant 2.2, Action wiring 7, 8). Read against
-- Session's records, not the validate answer, so it cross-checks 2.1.
assert A_Invariant_2_2 {
    Built implies all c : Call | c.pc.psubj in stok.(c.tok).sprin
}
check A_Invariant_2_2 for 4

-- A_Invariant_3_1: a denied answer follows an admitted gate (Invariant 3.1): a denial means
-- the gate cleared and Permissions was asked.
assert A_Invariant_3_1 {
    Built implies all c : Call | c.ans = Denied implies admitted[c]
}
check A_Invariant_3_1 for 4

-- A_Invariant_3_2: an admitted gate never answers session-invalid (Invariant 3.2): a
-- rejection means the gate did not clear.
assert A_Invariant_3_2 {
    Built implies all c : Call | admitted[c] implies c.ans != SessionInvalid
}
check A_Invariant_3_2 for 4

-- A_Invariant_3_3: a call whose validate gave an invalid answer (expired, revoked or
-- not-known) never answers denied (Invariant 3.3).
assert A_Invariant_3_3 {
    Built implies all c : Call |
        (some c.vc and c.vc.vkind in VExpired + VRevoked + VNotKnown) implies c.ans != Denied
}
check A_Invariant_3_3 for 4

-- A_Invariant_4_1: an admitted gate over a pair no active grant covers answers denied, where
-- Permissions answered (Invariant 4.1; see FINDINGS for its read failing).
assert A_Invariant_4_1 {
    Built implies all c : Call |
        (admitted[c] and PUnavailable not in c.pc.pkind and
         no g : Grant | g.gsubj = c.vc.vprin and g.gscope = c.scope)
        implies c.ans = Denied
}
check A_Invariant_4_1 for 4

-- A_Invariant_4_2: a valid session never stands as sufficient: a permitted answer rests on
-- an active grant covering the session's principal and the action scope (Invariant 4.2).
assert A_Invariant_4_2 {
    Built implies all c : Call |
        c.ans = Permitted implies some g : Grant | g.gsubj = c.vc.vprin and g.gscope = c.scope
}
check A_Invariant_4_2 for 4

-- A_Action_wiring_3: validate is asked with the session token as presented, byte-exact,
-- never trimmed, case-folded or normalized (Action wiring 3, Primitive policy 5 to 8).
assert A_Action_wiring_3 {
    Built implies all c : Call | some c.vc implies c.vc.vtok = c.tok
}
check A_Action_wiring_3 for 4

-- A_Action_wiring_6: permitted is asked with the action scope as presented, byte-exact
-- (Action wiring 6, Primitive policy 5 to 8; Non-goal 5, 6).
assert A_Action_wiring_6 {
    Built implies all c : Call, q : c.pc | q.pscope = c.scope
}
check A_Action_wiring_6 for 4

-- A_Action_wiring_9: a session-invalid answer names the reason the invalid answer carried
-- (Action wiring 9).
assert A_Action_wiring_9 {
    Built implies all c : Call | c.ans = SessionInvalid implies (some c.vc and (
        (c.vc.vkind = VExpired and c.reason = Expired) or
        (c.vc.vkind = VRevoked and c.reason = Revoked) or
        (c.vc.vkind = VNotKnown and c.reason = NotKnown)))
}
check A_Action_wiring_9 for 4

-- A_Action_wiring_10: an admitted gate answers what Permissions' permitted answered,
-- unchanged (Action wiring 10, 11).
assert A_Action_wiring_10 {
    Built implies all c : Call |
        (admitted[c] and one c.pc and c.pc.pkind in PPermitted + PDenied) implies
            ((c.pc.pkind = PPermitted and c.ans = Permitted) or
             (c.pc.pkind = PDenied and c.ans = Denied))
}
check A_Action_wiring_10 for 4

-- A_Action_wiring_12: no answer carries the valid answer's expiry instant (Action wiring 12).
assert A_Action_wiring_12 {
    Built implies no Call.leak
}
check A_Action_wiring_12 for 4

-- A_Primitive_policy_2: a blank session token answers invalid-request (Primitive policy 2).
assert A_Primitive_policy_2 {
    Built implies all c : Call | c.tok in Blank implies c.ans = InvalidRequest
}
check A_Primitive_policy_2 for 4

-- A_Primitive_policy_3: a blank action scope answers invalid-request (Primitive policy 3).
assert A_Primitive_policy_3 {
    Built implies all c : Call | c.scope in Blank implies c.ans = InvalidRequest
}
check A_Primitive_policy_3 for 4

-- A_Primitive_policy_4: an input over the length bound answers invalid-request (Primitive
-- policy 4).
assert A_Primitive_policy_4 {
    Built implies all c : Call |
        (c.tok in OverLong or c.scope in OverLong) implies c.ans = InvalidRequest
}
check A_Primitive_policy_4 for 4

-- A_Primitive_policy_9: no constituent is called for an input the boundary predicate
-- refuses: neither validate nor permitted (Primitive policy 9, Action wiring 2).
assert A_Primitive_policy_9 {
    Built implies all c : Call | refusedInput[c] implies (no c.vc and no c.pc)
}
check A_Primitive_policy_9 for 4

-- ─────────────────────────────────────────────────────────────────────────────
-- Runs (the shapes the page admits; each must be satisfiable)
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowPermitted: a valid session whose principal holds a grant for the scope: permitted
-- (Example: happy path).
run ShowPermitted {
    Built
    some c : Call | c.ans = Permitted
} for 4

-- ShowDenied: a valid session, no grant for the scope: denied (Example: permission denied).
run ShowDenied {
    Built
    some c : Call | c.ans = Denied
} for 4

-- ShowExpired: an expired session: session-invalid(expired), Permissions not called.
run ShowExpired {
    Built
    some c : Call | c.ans = SessionInvalid and c.reason = Expired
} for 4

-- ShowRevoked: a revoked session: session-invalid(revoked), Permissions not called.
run ShowRevoked {
    Built
    some c : Call | c.ans = SessionInvalid and c.reason = Revoked
} for 4

-- ShowNotKnown: a token naming no session: session-invalid(not-known).
run ShowNotKnown {
    Built
    some c : Call | c.ans = SessionInvalid and c.reason = NotKnown
} for 4

-- ShowInvalidRequest: a blank or over-long input: invalid-request, no constituent called
-- (Example: malformed input).
run ShowInvalidRequest {
    Built
    some c : Call | c.ans = InvalidRequest
} for 4

-- ShowValidateUnavailable: Session's read fails: state-unavailable, Permissions not called.
run ShowValidateUnavailable {
    Built
    some c : Call | some c.vc and c.vc.vkind = VUnavailable
} for 4

-- ShowPermittedUnavailable: an admitted gate whose permitted read fails: state-unavailable
-- (the case FINDINGS names against Invariant 4.1).
run ShowPermittedUnavailable {
    Built
    some c : Call | admitted[c] and c.ans = StateUnavailable
} for 4

-- ShowOnePrincipalMixed: one principal permitted for one scope and denied for another
-- (Invariant 4.2: the session is necessary, the grant decides).
run ShowOnePrincipalMixed {
    Built
    some disj c1, c2 : Call | c1.ans = Permitted and c2.ans = Denied and
        c1.pc.psubj = c2.pc.psubj
} for 4

-- ShowForgedPrincipalIgnored: a request carrying a principal other than the session's is
-- answered on the session's principal (Invariant 2; the section titled Intent).
run ShowForgedPrincipalIgnored {
    Built
    some c : Call | some c.claimed and c.claimed != c.vc.vprin and c.ans in Permitted + Denied
} for 4
