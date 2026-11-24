-- consent-buggy-revoke-future-instant.als
-- DELIBERATELY WRONG twin of consent.als (unit: `atoms/consent.md formal layer`).
--
-- INJECTED DEFECT: [Revoke] skips Operation 24: a revocation instant after now is recorded,
-- so the record the call revoked still stands in granted at the call.
--
-- BREAKS: A_Operation_26.
-- Everything else is consent.als as written; read its comments there.

module consent_buggy_revoke_future_instant

open util/ordering[ConsentId] as CID

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- ConsentId: an opaque consent id (Term consent id), which the host allocates at the seam
-- for each [Grant] (Identity 2). Ids are ordered as their spellings compare, code point by
-- code point (Execution Contract Logic confinement 10), the order a tie on grant instant
-- reads (Invariant 10.2). The host allocates no blank id (Identity 2), so no id here is.
sig ConsentId {}

-- Str: a string a call carries as a subject reference, a purpose, a granting actor, a
-- revoking actor or a reason (Term string input). Blank ones are among them.
sig Str {}

-- Meta: an opaque metadata payload a [Grant] may carry (Term metadata), a blank one among
-- them.
sig Meta {}

-- Blanks: which strings and which payloads are blank (empty or whitespace only, as the
-- page's Examples read "  ").
one sig Blanks {
    str  : set Str,
    meta : set Meta
}

-- Answer: what [Check] answers (Operation 34): one of the three states, or not-known.
abstract sig Answer {}

-- StateVal: the three states a record stands in (Term state; Term value sets).
abstract sig StateVal extends Answer {}

-- Granted, Revoked, Expired: the three states — in effect, withdrawn, run out.
one sig Granted, Revoked, Expired extends StateVal {}

-- NotKnown: [Check]'s answer where no record of the pair was granted by the at time
-- (Operation 40).
one sig NotKnown extends Answer {}

-- GrantCall: one [Grant] call, grant(subject_ref, purpose, granted_by, optional
-- expires_at, optional metadata), with the clock reading the seam injects and the consent
-- id the host allocates for it.
sig GrantCall {
    subjIn : one Str,         -- subject_ref
    purpIn : one Str,         -- purpose
    byIn   : one Str,         -- granted_by
    expIn  : lone Int,        -- expires_at; none where the call leaves it blank
    metaIn : lone Meta,       -- metadata; none where the call leaves it out
    gNow   : one Int,         -- now, the clock reading at the call (Capability requirement 1)
    seamId : one ConsentId    -- the consent id the host allocates (Identity 2)
}

-- RevokeCall: one [Revoke] call, revoke(consent_id, revoked_by, reason, optional
-- revoked_at), with the clock reading the seam injects.
sig RevokeCall {
    idIn     : one ConsentId, -- consent_id
    revByIn  : one Str,       -- revoked_by
    reasonIn : one Str,       -- reason
    revAtIn  : lone Int,      -- revoked_at; none where the call leaves it blank
    rNow     : one Int        -- now, the clock reading at the call
}

-- CheckCall: one [Check] call, check(subject_ref, purpose, optional at_time), with the
-- clock reading the seam injects.
sig CheckCall {
    cSubj : one Str,          -- subject_ref
    cPurp : one Str,          -- purpose
    atIn  : lone Int,         -- at_time; none where the call leaves it blank
    cNow  : one Int           -- now
}

-- ReadCall: one [Read] call; only its clock reading matters here, since a [Read] here
-- answers every record (see NOT MODELED HERE).
sig ReadCall {
    rdNow : one Int           -- now
}

-- Record: one consent record (Term records), as the calls that wrote it left it. Every
-- field may be absent, so a write that forgot one would show; what the page promises
-- (State 3, Invariant 4, Invariant 7) is checked, never built into the type. The last two
-- fields are the model's own: which [Grant] wrote the record, and which [Revoke], if any,
-- wrote over it.
sig Record {
    cid       : lone ConsentId,  -- consent id
    subj      : lone Str,        -- subject reference
    purpose   : lone Str,        -- purpose
    grantor   : lone Str,        -- granting actor
    grantAt   : lone Int,        -- grant instant
    expiry    : lone Int,        -- expiry instant
    meta      : lone Meta,       -- metadata
    column    : lone StateVal,   -- the stored state: what [Grant] or [Revoke] last wrote
    revoker   : lone Str,        -- revoking actor
    reason    : lone Str,        -- revocation reason
    revAt     : lone Int,        -- revocation instant
    grantedBy : one GrantCall,
    revokedIn : lone RevokeCall
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The host allocates each [Grant] a consent id no other call is given (Identity 2,
-- Execution Contract Logic confinement 3 and 16): two [Grant] calls never get one id.
fact HostAllocatesFreshIds {
    all disj a, b : GrantCall | a.seamId != b.seamId
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The derived state (Term withdrawn, Term elapsed, Expiry 1 to 4)
-- ─────────────────────────────────────────────────────────────────────────────

-- withdrawn: the record carries a revocation instant the evaluation instant does not
-- precede (Term withdrawn).
pred withdrawn[r : Record, e : Int] {
    some r.revAt and r.revAt <= e
}

-- elapsed: the record carries an expiry instant the evaluation instant does not precede
-- (Term elapsed).
pred elapsed[r : Record, e : Int] {
    some r.expiry and r.expiry <= e
}

-- standsIn: the states the record stands in at evaluation instant e, each by the rule
-- that obliges it: revoked where withdrawn (Expiry 1); expired where elapsed and not
-- withdrawn (Expiry 2, 3); granted where neither (Expiry 4). Invariant 2.1 asks that this
-- be exactly one.
fun standsIn[r : Record, e : Int] : set StateVal {
      { s : Revoked | withdrawn[r, e] }                              -- Expiry 1
    + { s : Expired | elapsed[r, e] and not withdrawn[r, e] }        -- Expiry 2, Expiry 3
    + { s : Granted | not withdrawn[r, e] and not elapsed[r, e] }    -- Expiry 4
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- grantAdmitted: the guards an admitted [Grant] passes: the subject reference, the purpose
-- and the granting actor are not blank (Operation 4, 5, 6), and a supplied expiry instant
-- falls after now (Operation 8, 9).
pred grantAdmitted[g : GrantCall] {
    g.subjIn not in Blanks.str                                     -- Operation 4
    g.purpIn not in Blanks.str                                     -- Operation 5
    g.byIn not in Blanks.str                                       -- Operation 6
    all x : g.expIn | x > g.gNow                                   -- Operation 8, Operation 9
}

-- grantFields: the grant fields an admitted [Grant] writes (Term grant field): the consent
-- id the host allocated (Operation 3, Identity 3), the call's subject reference, purpose
-- and granting actor, the grant instant stamped from now (Operation 10), the expiry
-- instant where the call supplies one and none where it leaves it blank (State 4, 6), and
-- the metadata where the call supplies a non-blank one and none otherwise (State 5, 16).
pred grantFields[g : GrantCall, r : Record] {
    r.cid     = g.seamId                                           -- Operation 3, Identity 3
    r.subj    = g.subjIn
    r.purpose = g.purpIn
    r.grantor = g.byIn
    r.grantAt = g.gNow                                             -- Operation 10
    r.expiry  = g.expIn                                            -- State 4, State 6
    r.meta    = g.metaIn - Blanks.meta                             -- State 5, State 16
}

-- resolved: the revocation instant a [Revoke] records: the call's where it supplies one
-- (Operation 20), now where it leaves it blank (Execution Contract Logic confinement 12).
fun resolved[v : RevokeCall] : one Int {
    (some v.revAtIn) => v.revAtIn else v.rNow
}

-- revokeAdmitted: the guards an admitted [Revoke] passes on the record as [Grant] left
-- it: the call names the record's consent id (Operation 16); the record is not elapsed at
-- now (Operation 19); the revoking actor and the reason are not blank (Operation 22, 23);
-- the resolved revocation instant is not after now (Operation 24) and not before the
-- grant instant (Operation 25).
pred revokeAdmitted[v : RevokeCall, r : Record] {
    v.idIn in r.cid                                                -- Operation 16
    not elapsed[r, v.rNow]                                         -- Operation 19
    v.revByIn not in Blanks.str                                    -- Operation 22
    v.reasonIn not in Blanks.str                                   -- Operation 23
    -- BUG: Operation 24 skipped
    resolved[v] >= r.grantAt                                       -- Operation 25
}

-- revokeWrites: what an admitted [Revoke] writes over the record: the stored state
-- revoked (Operation 26), the revoking actor (Operation 27), the reason as the revocation
-- reason (Operation 28) and the resolved revocation instant (Operation 29). It writes no
-- grant field, so the record keeps what [Grant] wrote.
pred revokeWrites[v : RevokeCall, r : Record] {
    revokeAdmitted[v, r]
    r.column  = Revoked                                            -- Operation 26
    r.revoker = v.revByIn                                          -- Operation 27
    r.reason  = v.reasonIn                                         -- Operation 28
    r.revAt   = resolved[v]                                        -- Operation 29
}

-- recorded: a record the page lets the database hold: what an admitted [Grant] wrote, with
-- the stored state granted (Operation 2) and no revocation field; or that, with what an
-- admitted [Revoke] then wrote over it.
pred recorded[r : Record] {
    grantAdmitted[r.grantedBy]
    grantFields[r.grantedBy, r]
    no r.revokedIn implies {
        r.column = Granted                                         -- Operation 2
        no r.revoker
        no r.reason
        no r.revAt
    }
    some r.revokedIn implies revokeWrites[r.revokedIn, r]
}

-- database: a whole database a [Check] or a [Read] reads: every record is admitted, and
-- no two records are one [Grant]'s.
pred database {
    all r : Record | recorded[r]
    all disj r1, r2 : Record | r1.grantedBy != r2.grantedBy
}

-- revokedRecord: a record that is revoked: one whose stored state [Revoke] wrote, or one
-- that stands in revoked at some instant (Invariant 4 and State 7 read either).
pred revokedRecord[r : Record] {
    r.column = Revoked or (some e : Int | Revoked in standsIn[r, e])
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The queries
-- ─────────────────────────────────────────────────────────────────────────────

-- atTime: the instant a [Check] evaluates against: the call's at time where it supplies
-- one (Operation 37), now where it leaves it blank (Execution Contract Logic confinement 12).
fun atTime[c : CheckCall] : one Int {
    (some c.atIn) => c.atIn else c.cNow
}

-- pairBy: the records carrying the call's subject reference and purpose whose grant
-- instant the at time does not precede.
fun pairBy[c : CheckCall] : set Record {
    { r : Record | r.subj = c.cSubj and r.purpose = c.cPurp
                   and some r.grantAt and r.grantAt <= atTime[c] }
}

-- candidate: the candidate record (Term candidate record): among pairBy, the one whose
-- grant instant is the latest, a tie resolving to the greatest consent id (Invariant 10.2).
fun candidate[c : CheckCall] : set Record {
    { r : pairBy[c] | no r2 : pairBy[c] - r |
        r2.grantAt > r.grantAt or (r2.grantAt = r.grantAt and CID/gt[r2.cid, r.cid]) }
}

-- answer: what [Check] answers, from the candidate record alone (Operation 45): not-known
-- where there is none (Operation 40); revoked where it is withdrawn (Operation 41);
-- expired where it is elapsed and not withdrawn (Operation 42, 43); granted where it is
-- neither (Operation 44).
fun answer[c : CheckCall] : set Answer {
    let t = atTime[c], k = candidate[c] |
          { a : NotKnown | no k }                                                -- Operation 40
        + { a : Revoked  | some x : k | withdrawn[x, t] }                        -- Operation 41
        + { a : Expired  | some x : k | elapsed[x, t] and not withdrawn[x, t] }  -- Operation 42, 43
        + { a : Granted  | some x : k | not withdrawn[x, t] and not elapsed[x, t] } -- Operation 44
}

-- carried: the state a [Read] carries on a record it answers: the state the record stands
-- in at now, never the stored state (Term Read, Invariant 2.2).
fun carried[d : ReadCall, r : Record] : set StateVal {
    standsIn[r, d.rdNow]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_3: every record carries its consent id, subject reference, purpose, granting
-- actor, grant instant and stored state (State 3).
assert A_State_3 {
    all r : Record | recorded[r] implies {
        some r.cid
        some r.subj
        some r.purpose
        some r.grantor
        some r.grantAt
        some r.column
    }
}
check A_State_3 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_State_4: a record whose [Grant] supplied an expiry instant carries that instant
-- (State 4).
assert A_State_4 {
    all r : Record | (recorded[r] and some r.grantedBy.expIn) implies r.expiry = r.grantedBy.expIn
}
check A_State_4 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_State_5: a record whose [Grant] supplied non-blank metadata carries it as supplied
-- (State 5, Operation 12: stored, never interpreted).
assert A_State_5 {
    all r : Record | (recorded[r] and some (r.grantedBy.metaIn - Blanks.meta))
        implies r.meta = r.grantedBy.metaIn
}
check A_State_5 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_State_6: a record whose [Grant] left the expiry instant blank carries none, so it
-- never runs out by time (State 6).
assert A_State_6 {
    all r : Record | (recorded[r] and no r.grantedBy.expIn) implies no r.expiry
}
check A_State_6 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_State_16: a record whose [Grant] carried no metadata, or a blank one, carries none
-- (State 16).
assert A_State_16 {
    all r : Record | (recorded[r] and no (r.grantedBy.metaIn - Blanks.meta)) implies no r.meta
}
check A_State_16 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_State_9: at no instant does a record stand in expired while carrying a revocation
-- instant: a withdrawal is recorded only on an agreement still running (State 9).
assert A_State_9 {
    all r : Record, e : Int | (recorded[r] and Expired in standsIn[r, e]) implies no r.revAt
}
check A_State_9 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Expiry_5: no record's stored state is expired: running out is derived, never written
-- (Expiry 5).
assert A_Expiry_5 {
    all r : Record | recorded[r] implies r.column != Expired
}
check A_Expiry_5 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Invariant_2_1: at every evaluation instant, past or future, every record stands in
-- exactly one of granted, revoked and expired (Invariant 2.1; Expiry 1 to 4).
assert A_Invariant_2_1 {
    all r : Record, e : Int | recorded[r] implies one standsIn[r, e]
}
check A_Invariant_2_1 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Invariant_2_2: every [Read] carries on every record exactly one state, the one the
-- record stands in at the read's now (Invariant 2.2, Operation 64's state).
assert A_Invariant_2_2 {
    all d : ReadCall, r : Record | recorded[r] implies {
        one carried[d, r]
        carried[d, r] in standsIn[r, d.rdNow]
    }
}
check A_Invariant_2_2 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Stored_state_3: no answer says granted for an elapsed record: no [Read] carries
-- granted on a record elapsed at its now, and no [Check] answers granted where its
-- candidate record is elapsed at the at time (Stored state 3).
assert A_Stored_state_3 {
    all d : ReadCall, r : Record | (recorded[r] and elapsed[r, d.rdNow])
        implies Granted not in carried[d, r]
    database implies (all c : CheckCall | (some x : candidate[c] | elapsed[x, atTime[c]])
        implies Granted not in answer[c])
}
check A_Stored_state_3 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Invariant_4_1: every revoked record carries a revoking actor, not blank (Invariant
-- 4.1, State 7, Check 3.1).
assert A_Invariant_4_1 {
    all r : Record | (recorded[r] and revokedRecord[r]) implies
        (some r.revoker and r.revoker not in Blanks.str)
}
check A_Invariant_4_1 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Invariant_4_2: every revoked record carries a revocation reason, not blank (Invariant
-- 4.2, State 7, Check 3.1).
assert A_Invariant_4_2 {
    all r : Record | (recorded[r] and revokedRecord[r]) implies
        (some r.reason and r.reason not in Blanks.str)
}
check A_Invariant_4_2 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Invariant_4_3: every revoked record carries a revocation instant, so when the
-- withdrawal took effect is on the record (Invariant 4.3, State 7).
assert A_Invariant_4_3 {
    all r : Record | (recorded[r] and revokedRecord[r]) implies some r.revAt
}
check A_Invariant_4_3 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Invariant_5_1: no record's revocation instant precedes its grant instant: a
-- withdrawal never takes effect before the agreement it ends (Invariant 5.1, Check 3.2).
assert A_Invariant_5_1 {
    all r : Record | (recorded[r] and some r.revAt) implies r.revAt >= r.grantAt
}
check A_Invariant_5_1 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Invariant_6_2: where the candidate record is both withdrawn and elapsed at the at
-- time, [Check] answers revoked: a withdrawal outranks a later expiry (Invariant 6.2).
assert A_Invariant_6_2 {
    database implies all c : CheckCall, x : candidate[c] |
        (withdrawn[x, atTime[c]] and elapsed[x, atTime[c]]) implies answer[c] = Revoked
}
check A_Invariant_6_2 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Invariant_7_1: every record's consent id, subject reference, purpose and granting
-- actor are present and not blank (Invariant 7.1, Check 2.1).
assert A_Invariant_7_1 {
    all r : Record | recorded[r] implies {
        some r.cid
        some r.subj and r.subj not in Blanks.str
        some r.purpose and r.purpose not in Blanks.str
        some r.grantor and r.grantor not in Blanks.str
    }
}
check A_Invariant_7_1 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Invariant_7_2: every record carries a grant instant (Invariant 7.2, Check 2.2).
assert A_Invariant_7_2 {
    all r : Record | recorded[r] implies one r.grantAt
}
check A_Invariant_7_2 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Invariant_10_1: where [Check] answers other than not-known, it answers the state, at
-- the at time, of a record of the call's pair whose grant instant the at time does not
-- precede and no record of the pair granted later by the at time; and it answers
-- not-known only where the pair has no record granted by the at time (Invariant 10.1,
-- Check 8.4, Operation 40, Operation 45).
assert A_Invariant_10_1 {
    database implies all c : CheckCall | let t = atTime[c] | {
        answer[c] = NotKnown iff no pairBy[c]
        answer[c] != NotKnown implies (some r : pairBy[c] |
            (no r2 : pairBy[c] | r2.grantAt > r.grantAt) and answer[c] = standsIn[r, t])
    }
}
check A_Invariant_10_1 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Invariant_10_2: where two or more records of the call's pair share the latest grant
-- instant the at time does not precede, [Check] answers from the one among them with the
-- greatest consent id (Invariant 10.2, Check 8.5).
assert A_Invariant_10_2 {
    database implies all c : CheckCall, r2 : pairBy[c] |
        ((some r1 : pairBy[c] - r2 | r1.grantAt = r2.grantAt)
         and (no r3 : pairBy[c] | r3.grantAt > r2.grantAt
                                  or (r3.grantAt = r2.grantAt and CID/gt[r3.cid, r2.cid])))
        implies answer[c] = standsIn[r2, atTime[c]]
}
check A_Invariant_10_2 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Instance_2: no two records [Grant] calls wrote share a consent id, so an id names one
-- record; with no record removed (Invariant 8.1) no id is reused (Instance 2, Identity 4,
-- Check 1.2).
assert A_Instance_2 {
    all r1, r2 : Record | (recorded[r1] and recorded[r2] and r1.grantedBy != r2.grantedBy)
        implies no (r1.cid & r2.cid)
}
check A_Instance_2 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Operation_2: every record stands in granted at its own grant instant, unless a
-- withdrawal took effect at that very instant: no agreement is recorded already run out
-- (Operation 2; Operation 8 and 9 checked through it).
assert A_Operation_2 {
    all r : Record | (recorded[r] and not withdrawn[r, r.grantAt])
        implies standsIn[r, r.grantAt] = Granted
}
check A_Operation_2 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- A_Operation_26: every record a [Revoke] wrote stands in revoked at that call's now:
-- withdrawing ends use from the call (Operation 26; Operation 24 checked through it).
assert A_Operation_26 {
    all r : Record | (recorded[r] and some r.revokedIn)
        implies standsIn[r, r.revokedIn.rNow] = Revoked
}
check A_Operation_26 for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowOpenEnded: a record with no expiry instant, standing in granted at every instant
-- from its grant on, as a cookie opt-in with no time limit.
run ShowOpenEnded {
    some r : Record | recorded[r] and no r.expiry and no r.revAt
} for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- ShowRunsOut: a record with an expiry instant, granted before it and expired from it,
-- as the HIPAA authorization granted 2025-09-01 to run until 2026-09-01.
run ShowRunsOut {
    some r : Record | recorded[r] and some r.expiry and no r.revAt
        and standsIn[r, r.grantAt] = Granted and standsIn[r, r.expiry] = Expired
} for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- ShowBackdatedWithdrawal: a record revoked with a revocation instant before the call's
-- now (Clock semantics 8), granted before it and revoked from it.
run ShowBackdatedWithdrawal {
    some r : Record | recorded[r] and some r.revokedIn and r.revAt < r.revokedIn.rNow
        and r.revAt > r.grantAt
} for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- ShowWithdrawnThenElapsed: [Check] at an instant after both the revocation instant and
-- the expiry instant of its candidate record, answering revoked (Invariant 6.2).
run ShowWithdrawnThenElapsed {
    database and some c : CheckCall, x : candidate[c] |
        withdrawn[x, atTime[c]] and elapsed[x, atTime[c]] and answer[c] = Revoked
} for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- ShowReconsent: the Example's re-consent: the pair's earlier record revoked, a later one
-- granted, and [Check] answering granted from the later one.
run ShowReconsent {
    database and some c : CheckCall, r1, r2 : pairBy[c] |
        r1.grantAt < r2.grantAt and some r1.revAt and r2 in candidate[c] and answer[c] = Granted
} for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- ShowOlderStillInEffect: two records of one pair, the earlier still in effect and the
-- later revoked: [Check] answers revoked from the later alone (Non-goal 3, Invariant 10.1).
run ShowOlderStillInEffect {
    database and some c : CheckCall, r1, r2 : pairBy[c] |
        r1.grantAt < r2.grantAt and standsIn[r1, atTime[c]] = Granted
        and r2 in candidate[c] and answer[c] = Revoked
} for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- ShowTie: two concurrent [Grant] calls for one pair, two records sharing a grant instant
-- (Concurrency 4), the greater consent id the candidate.
run ShowTie {
    database and some c : CheckCall, disj r1, r2 : pairBy[c] |
        r1.grantAt = r2.grantAt and r2 in candidate[c]
} for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- ShowFutureCheck: [Check] with an at time after now, answering granted, as the 30-day
-- campaign checked before it is queued.
run ShowFutureCheck {
    database and some c : CheckCall | some c.atIn and c.atIn > c.cNow and answer[c] = Granted
} for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- ShowNotKnown: [Check] for a pair with no record granted by the at time, answering
-- not-known, while a record of the pair granted later exists.
run ShowNotKnown {
    database and some c : CheckCall | answer[c] = NotKnown
        and (some r : Record | r.subj = c.cSubj and r.purpose = c.cPurp)
} for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall

-- ShowMetadata: a record carrying the metadata its [Grant] supplied, beside one whose
-- [Grant] supplied a blank payload and carries none.
run ShowMetadata {
    some r1, r2 : Record | recorded[r1] and recorded[r2] and some r1.meta
        and some (r2.grantedBy.metaIn & Blanks.meta) and no r2.meta
} for 3 but 4 Int, 2 RevokeCall, 1 CheckCall, 1 ReadCall
