-- idempotent-reservation-buggy-collision.als
-- DELIBERATELY WRONG twin of idempotent-reservation.als (unit: compositions/idempotent-reservation.md formal layer).
--
-- INJECTED DEFECT: the action type is not compared: a live entry with the call's digest matches whatever its action type (Action wiring 7).
--
-- BREAKS: A_Invariant_4_1.
-- Everything else is idempotent-reservation.als as written; read its comments there.

module idempotent_reservation_buggy_collision

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Token: an idempotency token as the caller supplied it, opaque and compared byte-exact
-- (Primitive policy 3 to 5): two tokens are the same only when they are the same token.
sig Token {}

-- Malformed: the tokens that fail the boundary predicate — blank, or longer than the token
-- max length (Primitive policy 1, 2). The caller's; an input.
sig Malformed in Token {}

-- Resource, Requester: a place_hold's resource and requester, Provisional Commitment's.
sig Resource {}
sig Requester {}

-- Digest: a parameters digest, computed at the seam over a call's non-token parameters
-- (Term parameters digest, Composition state 9).
sig Digest {}

-- ActionType: the four token-carrying actions (Term action type).
abstract sig ActionType {}
one sig PlaceHold, Confirm, Release, Expire extends ActionType {}

-- PState: a commitment's state, Provisional Commitment's: Held, then Confirmed, Released or
-- Expired.
abstract sig PState {}
one sig Held, Confirmed, Released, Expired extends PState {}

-- Commitment: one Provisional Commitment record, its id the atom itself, with its resource,
-- requester and state as the state stands.
sig Commitment {
    res : one Resource,
    req : one Requester,
    st  : one PState
}

-- Code: an answer that is not a commitment id: ok, the constituent's rejections, and the
-- composition's own (invalid-request on the token, token-collision, outcome-unknown).
abstract sig Code {}
one sig Ok, ResourceUnavailable, RegistryUnavailable, InvalidRequest, NotKnown, NotHeld,
    WindowElapsed, WindowNotElapsed, StorageFailure, TokenCollision, OutcomeUnknown extends Code {}

-- Mark: the recovery mark an entry carries (Term recovery mark): first or recovered.
abstract sig Mark {}
one sig First, Recovered extends Mark {}

-- CheckAnswer: what Duplicate Prevention's check answers for a token: seen, not-seen, or
-- state-unavailable (Action wiring 27).
abstract sig CheckAnswer {}
one sig Seen, NotSeen, StateUnavailable extends CheckAnswer {}

-- Config: the idempotency window, the deployment's (Capability requirement 1), which
-- configures Duplicate Prevention's window too (Composes 8).
one sig Config {
    window : one Int
}

-- Call: one call of a token-carrying action as it reached the seam — its token, action type,
-- parameters (a place_hold's resource and requester, a resolving action's commitment id),
-- the digest the seam computed and the now it read — and, as ghosts of what it read and did:
-- Duplicate Prevention's answer and the token's recording instant there, the live entry it
-- found, the commitments Provisional Commitment held, the constituent's answer where it
-- called it, what the composition answered, and the candidates it carried. The answer is a
-- set, so a build that answered twice, or not at all, would show.
sig Call {
    tok     : one Token,
    act     : one ActionType,
    pres    : lone Resource,
    preq    : lone Requester,
    target  : lone Commitment,
    dig     : one Digest,
    now     : one Int,
    dpCheck : lone CheckAnswer,
    dpAt    : lone Int,
    found   : lone Entry,
    heldAt  : set Commitment,
    reached : lone (Commitment + Code),
    answer  : set (Commitment + Code),
    cands   : set Commitment
}

-- Recorder: the calls that called Duplicate Prevention's record (Action wiring 25).
sig Recorder in Call {}

-- Entry: one token results entry (Term records) — its token, action type, parameters
-- digest, result, pending instant and recovery mark (Composition state 3) — with, as
-- ghosts, the call that wrote it and Duplicate Prevention's recording instant for its token
-- as that call's transaction left it; and, for an evicted entry, read at its last version
-- (Execution Contract Database 5): the eviction's instant, the check's answer and the
-- recording instant the check read, and the call that evicted it in place (none: the leg).
sig Entry {
    etok    : one Token,
    eact    : one ActionType,
    edig    : one Digest,
    result  : one (Commitment + Code),
    pending : one Int,
    mark    : one Mark,
    by      : one Call,
    guardAt : lone Int,
    evAt    : lone Int,
    evCheck : lone CheckAnswer,
    evDpAt  : lone Int,
    evBy    : lone Call
}

-- Map: the token results map as it stands, keyed by token (Composition state 1, 2).
one sig Map {
    at : Token -> lone Entry
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers: the page's terms over one state
-- ─────────────────────────────────────────────────────────────────────────────

-- W: the idempotency window.
fun W : Int { Config.window }

-- stored, evicted: the entries the map holds, and the last versions of those evicted.
fun stored : set Entry { Token.(Map.at) }
fun evicted : set Entry { Entry - stored }

-- Resolving: the resolving actions (Term resolving action).
fun Resolving : set ActionType { Confirm + Release + Expire }

-- Rerunnable: the action types that run again for a seen token carrying no entry
-- (Indeterminate outcome 13); a place_hold is answered outcome-unknown instead (10).
fun Rerunnable : set ActionType { Confirm + Release + Expire }

-- terminal: the state a resolving action's ok leaves its commitment in.
fun terminal[a : ActionType] : PState {
    a = Confirm => Confirmed else (a = Release => Released else Expired)
}

-- underGuard: Duplicate Prevention holds the token from recording instant g and its elapsed
-- term at instant n is less than the window (Duplicate Prevention's term under guard).
pred underGuard[g : set Int, n : Int] {
    some g and minus[n, g] < W
}

-- windowEnd: the entry's window end, pending instant plus the window (Term window end).
fun windowEnd[e : Entry] : Int { plus[e.pending, W] }

-- elapsedFor: the window has elapsed for the entry at instant n: at its window end and
-- after it (Term window end).
pred elapsedFor[e : Entry, n : Int] {
    minus[n, e.pending] >= W
}

-- resolved: the check's answer as the composition resolves it: state-unavailable as seen,
-- fail-closed (Action wiring 27, Capability requirement 16).
fun resolved[a : CheckAnswer] : CheckAnswer {
    a = StateUnavailable => Seen else a
}

-- wellFormed: the call's token clears the boundary predicate.
pred wellFormed[c : Call] { c.tok not in Malformed }

-- live: the call found a live entry for its token (Term live entry).
pred live[c : Call] { some c.found }

-- matches: the live entry is a matching complete entry — its action type and parameters
-- digest are the call's (Term matching complete entry).
pred matches[c : Call] { c.found.edig = c.dig }

-- The arms a call takes, from what it read:
--   collision — a live entry with another action type or digest (Action wiring 7, 8);
--   replay    — a matching complete entry (Action wiring 9, 10);
--   fresh     — no live entry and the check resolved not-seen (Term fresh request);
--   unknown   — no live entry, the check resolved seen, a place_hold (Indeterminate outcome 10);
--   re-entry  — no live entry, the check resolved seen, a resolving action (13).
pred collisionArm[c : Call] { live[c] and not matches[c] }
pred replayArm[c : Call] { live[c] and matches[c] }
pred freshArm[c : Call] { wellFormed[c] and not live[c] and resolved[c.dpCheck] = NotSeen }
pred unknownArm[c : Call] {
    wellFormed[c] and not live[c] and resolved[c.dpCheck] = Seen and c.act not in Rerunnable
}
pred reEntryArm[c : Call] {
    wellFormed[c] and not live[c] and resolved[c.dpCheck] = Seen and c.act in Rerunnable
}

-- commits: the constituent was called and its answer committed: anything but a storage
-- failure, which commits nothing (Execution Contract Constituent failure 1, Database 1).
pred commits[c : Call] { some c.reached and c.reached != StorageFailure }

-- candidates: the held commitments the call read whose resource and requester are the
-- call's (Indeterminate outcome 3, 4; Term candidates).
fun candidates[c : Call] : set Commitment {
    { k : c.heldAt | k.res = c.pres and k.req = c.preq }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The idempotency window is more than zero (Term idempotency window, as Duplicate
-- Prevention's window duration is).
fact WindowExceedsZero {
    W > 0
}

-- The deployment computes every elapsed term and window end without loss (Execution
-- Contract Logic confinement 9). In the model: the window lies in 1 to 3 and every instant in
-- 0 to 4, so the four-bit integers (-8 to 7) hold every difference and every window end.
fact ExactArithmetic {
    W <= 3
    all c : Call | c.now >= 0 and c.now <= 4
    all c : Call, g : c.dpAt | g >= 0 and g <= 4
    all e : Entry, n : e.evAt + e.evDpAt | n >= 0 and n <= 4
}

-- Each action's parameters, by its signature: a place_hold carries a resource and a
-- requester, a resolving action a commitment id.
fact CallParameters {
    all c : Call | c.act = PlaceHold
        implies (one c.pres and one c.preq and no c.target)
        else (no c.pres and no c.preq and one c.target)
}

-- The seam computes each call's digest with the deployment's one collision-resistant digest
-- function (Capability requirement 3, 4; Term digest function): two calls carry one digest
-- exactly when their non-token parameters are the same. A place_hold's and a resolving
-- action's parameters never are; a confirm's, a release's and an expire's of one commitment
-- always are.
fact SeamDigest {
    all c1, c2 : Call | c1.dig = c2.dig iff
        ((c1.act = PlaceHold iff c2.act = PlaceHold)
         and c1.pres = c2.pres and c1.preq = c2.preq and c1.target = c2.target)
}

-- dpAnswers: Duplicate Prevention's check answers seen for a token under guard at the
-- instant and not-seen for one that is not (its Operation 6, 7); state-unavailable answers
-- nothing about the guard.
pred dpAnswers[a : CheckAnswer, g : set Int, n : Int] {
    a = Seen implies underGuard[g, n]
    a = NotSeen implies not underGuard[g, n]
}

-- Duplicate Prevention's check answers by the recording instant it holds, for a call and
-- for an eviction alike.
fact DuplicatePreventionCheck {
    all c : Call | some c.dpCheck implies dpAnswers[c.dpCheck, c.dpAt, c.now]
    all e : Entry | some e.evCheck implies dpAnswers[e.evCheck, e.evDpAt, e.evAt]
}

-- Duplicate Prevention's record: under guard, the recording instant stands (its Invariant
-- 2.1, 2.2); otherwise a fresh guard is stamped at the record's now (2.3). A transaction that
-- does not record leaves the instant as it was: a check alters nothing (its Invariant 3.1).
fact DuplicatePreventionRecord {
    all e : Entry | e.by in Recorder implies
        e.guardAt = (underGuard[e.by.dpAt, e.by.now] => e.by.dpAt else e.by.now)
    all e : Entry | e.by not in Recorder implies e.guardAt = e.by.dpAt
}

-- Provisional Commitment's answers, by its action signatures: a place_hold answers an id or
-- resource-unavailable, registry-unavailable, invalid-request or storage-failure; a resolving
-- action ok or not-known, not-held, window-elapsed (confirm, release) or window-not-elapsed
-- (expire), or storage-failure. An id answered names a commitment it placed for the call's
-- resource and requester, answered to one place_hold only; an ok leaves the commitment in
-- the action's terminal state, where single resolution keeps it (its Invariant 2).
fact ConstituentAnswers {
    all c : Call | c.act = PlaceHold implies
        c.reached in Commitment + ResourceUnavailable + RegistryUnavailable + InvalidRequest + StorageFailure
    all c : Call | c.act in Resolving implies
        c.reached in Ok + NotKnown + NotHeld + StorageFailure
                     + (c.act = Expire => WindowNotElapsed else WindowElapsed)
    all c : Call, k : Commitment | c.reached = k implies (k.res = c.pres and k.req = c.preq)
    all k : Commitment | lone reached.k
    all c : Call | c.reached = Ok implies c.target.st = terminal[c.act]
}

-- The registry refuses a resource a held commitment carries (Provisional Commitment
-- Capability requirement 17, Operation 5): any read holds at most one Held commitment per
-- resource.
fact OneHeldPerResource {
    all c : Call, r : Resource | lone (c.heldAt & res.r)
}

-- A call reads only what was committed before it (Execution Contract Database 2): no call
-- reads, through the entry it found or evicted, its own write or a write that read it.
fact ReadsPrecede {
    no c : Call | c in c.^(found.by + (~evBy).by)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writes: what each admitted call and the eviction leg leave
-- ─────────────────────────────────────────────────────────────────────────────

-- boundaryWiring: a malformed token is answered invalid-request before Duplicate Prevention's
-- check, the lookup or the constituent is touched (Primitive policy 1, 2, 6); a well-formed
-- one is checked.
pred boundaryWiring {
    all c : Call | not wellFormed[c] implies {
        no c.dpCheck
        no c.found
        no evBy.c
        no c.reached
        c.answer = InvalidRequest
    }
    all c : Call | wellFormed[c] implies one c.dpCheck
}

-- lookupWiring: the map keys each entry by its token (Composition state 2), a call finds the
-- entry under its own token, and an entry the window elapsed for whose token the check
-- resolved not-seen is evicted in place, never found live (Action wiring 12, Term live
-- entry); a call evicts at most one entry, and after it finds none.
pred lookupWiring {
    all t : Token, e : Map.at[t] | e.etok = t
    all c : Call | some c.found implies c.found.etok = c.tok
    all c : Call | some c.found implies not (elapsedFor[c.found, c.now] and resolved[c.dpCheck] = NotSeen)
    all c : Call | lone evBy.c
    all c : Call | some evBy.c implies no c.found
}

-- readsWiring: Duplicate Prevention's recording instant for a token whose entry is stored is
-- the one the entry's writer left: no call records the token while its entry stands (a
-- replay and a collision write nothing, Action wiring 10; a fresh request evicts first,
-- Action wiring 12), and Duplicate Prevention re-stamps only on a record.
pred readsWiring {
    all c : Call | some (c.found + evBy.c) implies c.dpAt = (c.found + evBy.c).guardAt
    all e : Entry | (some e.evAt and no e.evBy) implies e.evDpAt = e.guardAt
}

-- storeWiring: every entry is stored or evicted, and only an evicted one carries an
-- eviction's reading.
pred storeWiring {
    all e : Entry | e in stored iff no e.evAt
    all e : Entry | no e.evAt implies (no e.evCheck and no e.evDpAt and no e.evBy)
    all e : Entry | some e.evAt implies one e.evCheck
}

-- evictionWiring: a call evicts in place an entry the window elapsed for and whose token the
-- check resolved not-seen, at its own now (Action wiring 12); the eviction leg evicts an
-- entry only if the check resolved not-seen and the window elapsed since its pending
-- instant, measured on the composition's own reading (Housekeeping 4 to 6, 9).
pred evictionWiring {
    all e : Entry | some e.evBy implies {
        e.etok = e.evBy.tok
        e.evAt = e.evBy.now
        e.evCheck = e.evBy.dpCheck
        e.evDpAt = e.evBy.dpAt
        elapsedFor[e, e.evAt]
        resolved[e.evCheck] = NotSeen
    }
    all e : Entry | (some e.evAt and no e.evBy) implies {
        resolved[e.evCheck] = NotSeen -- the leg: Housekeeping 4, 6
        elapsedFor[e, e.evAt] -- the leg: Housekeeping 5
    }
}

-- armWiring: what each arm answers, and whether it calls the constituent: a collision
-- answers token-collision (Action wiring 7, 8), a replay the entry's result without the
-- constituent (9, 10), a place_hold on a seen token carrying no entry outcome-unknown with
-- the candidates (Indeterminate outcome 3, 4, 7, 10); a fresh request and a re-entry call
-- the constituent once and answer what it answered (Action wiring 21, Composes 6,
-- Indeterminate outcome 13).
pred armWiring {
    all c : Call | collisionArm[c] implies {
        c.answer = TokenCollision
        no c.reached
    }
    all c : Call | replayArm[c] implies {
        c.answer = c.found.result
        no c.reached
    }
    all c : Call | unknownArm[c] implies {
        c.answer = OutcomeUnknown
        no c.reached
    }
    all c : Call | (freshArm[c] or reEntryArm[c]) implies {
        one c.reached
        c.answer = c.reached
    }
    all c : Call | c.cands = (unknownArm[c] => candidates[c] else none)
}

-- writeWiring: a fresh request or a re-entry whose constituent answer committed writes one
-- entry, a rejection included (Composition state 6, Wiring decision 1, 2), and no other call
-- writes one (Wiring decision 3, 4; Action wiring 10); the entry carries the call's token,
-- action type and digest, the answer it gave, its now as the pending instant, and the first
-- mark from a fresh request or the recovered mark from a re-entry (Term recovery mark,
-- Indeterminate outcome 8); every call that records a result calls Duplicate Prevention's
-- record (Action wiring 25).
pred writeWiring {
    all c : Call | lone by.c
    all c : Call | some by.c iff ((freshArm[c] or reEntryArm[c]) and commits[c])
    all e : Entry | {
        e.etok = e.by.tok
        e.eact = e.by.act
        e.edig = e.by.dig
        e.result = e.by.answer
        e.pending = e.by.now
        e.mark = (freshArm[e.by] => First else Recovered)
    }
    Recorder = Entry.by
}

-- built: every record in the state is what an admitted write left.
pred built {
    boundaryWiring
    lookupWiring
    readsWiring
    storeWiring
    evictionWiring
    armWiring
    writeWiring
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's writes can leave, or any call's answer,
-- that violates this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: a place_hold that found a live entry written by a place_hold carrying its
-- token and digest answers what that call answered: two place_hold calls under one token and
-- digest answer alike inside the window.
assert A_Invariant_1_1 {
    built implies all c : Call, w : c.found.by |
        (c.act = PlaceHold and w.act = PlaceHold and w.tok = c.tok and w.dig = c.dig)
            implies c.answer = w.answer
}
check A_Invariant_1_1 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Invariant_2_1: the same for two resolving calls of one action type (finding (a): the
-- page's text leaves the action type out, and two action types answer unalike).
assert A_Invariant_2_1 {
    built implies all c : Call, w : c.found.by |
        (c.act in Resolving and w.act = c.act and w.tok = c.tok and w.dig = c.dig)
            implies c.answer = w.answer
}
check A_Invariant_2_1 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Invariant_2_2: a call that reaches the constituent found no live entry for its token —
-- a fresh request or a re-entry — so no call inside a live entry's window reaches it again.
assert A_Invariant_2_2 {
    built implies all c : Call | some c.reached implies no c.found
}
check A_Invariant_2_2 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Invariant_3_1: a token's stored entry, and every call answered while that entry was
-- live, name at most one commitment id between them (Check 2.1, the auditor's join of the
-- map to the commitments).
assert A_Invariant_3_1 {
    built implies all t : Token |
        lone ((Map.at[t].result + (found.(Map.at[t])).answer) & Commitment)
}
check A_Invariant_3_1 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Invariant_4_1: a call answered from a live entry, without the constituent, carries that
-- entry's action type: the token binds one action type (Check 1.1).
assert A_Invariant_4_1 {
    built implies all c : Call |
        (some c.found and no c.reached and c.answer = c.found.result) implies c.act = c.found.eact
}
check A_Invariant_4_1 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Invariant_4_2: the same for the parameters digest: the token binds one digest (Check 1.2).
assert A_Invariant_4_2 {
    built implies all c : Call |
        (some c.found and no c.reached and c.answer = c.found.result) implies c.dig = c.found.edig
}
check A_Invariant_4_2 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Invariant_7_1: every evicted entry, read at its last version, was evicted at an instant
-- Duplicate Prevention's guard on its token had elapsed (Check 4.1, Housekeeping 6) and at
-- or after its window end (Check 4.2, Housekeeping 5).
assert A_Invariant_7_1 {
    built implies all e : evicted |
        not underGuard[e.guardAt, e.evAt] and e.evAt >= windowEnd[e]
}
check A_Invariant_7_1 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Composes_7: every stored entry's token is held by Duplicate Prevention, under guard at
-- the entry's pending instant: the record was made with the entry (Action wiring 25).
assert A_Composes_7 {
    built implies all e : stored | underGuard[e.guardAt, e.pending]
}
check A_Composes_7 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Composition_state_6: a call whose constituent answer committed wrote exactly one entry;
-- a call that did not reach the constituent, or whose answer was a storage failure, wrote
-- none.
assert A_Composition_state_6 {
    built implies all c : Call | {
        (some c.reached and c.reached != StorageFailure) implies one by.c
        (no c.reached or c.reached = StorageFailure) implies no by.c
    }
}
check A_Composition_state_6 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Wiring_decision_1: every entry carries the answer the constituent gave the call that
-- wrote it (Check 3.1), and agrees with the constituent's records: an id names a commitment
-- carrying the call's resource and requester, an ok a commitment in the action's terminal
-- state.
assert A_Wiring_decision_1 {
    built implies all e : Entry | {
        e.result = e.by.reached
        e.result in Commitment implies (e.result.res = e.by.pres and e.result.req = e.by.preq)
        e.result = Ok implies e.by.target.st = terminal[e.eact]
    }
}
check A_Wiring_decision_1 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Wiring_decision_3: no entry is keyed by a token that fails the boundary predicate.
assert A_Wiring_decision_3 {
    built implies no e : Entry | e.etok in Malformed
}
check A_Wiring_decision_3 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Wiring_decision_4: no place_hold entry is a recovered entry or carries outcome-unknown:
-- the answer a place_hold gets on a seen token carrying no entry is not recorded
-- (Indeterminate outcome 10).
assert A_Wiring_decision_4 {
    built implies all e : Entry | e.eact = PlaceHold implies (e.mark = First and e.result != OutcomeUnknown)
}
check A_Wiring_decision_4 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Indeterminate_outcome_4: an outcome-unknown answer carries exactly the held commitments
-- the call read whose resource and requester are the call's, and at most one of them (Term
-- candidates: the registry refuses a resource a held commitment carries).
assert A_Indeterminate_outcome_4 {
    built implies all c : Call | OutcomeUnknown in c.answer implies {
        c.cands = { k : c.heldAt | k.res = c.pres and k.req = c.preq }
        lone c.cands
    }
}
check A_Indeterminate_outcome_4 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Indeterminate_outcome_8: an entry whose writer found no live entry and read the token
-- as seen, or the check as unavailable, is a recovered entry and carries the recovered mark.
assert A_Indeterminate_outcome_8 {
    built implies all e : Entry |
        (no e.by.found and e.by.dpCheck in Seen + StateUnavailable) implies e.mark = Recovered
}
check A_Indeterminate_outcome_8 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- A_Action_wiring_27: a call whose check answered state-unavailable and that found no live
-- entry is answered as on a seen token: a place_hold outcome-unknown, and an entry it writes
-- is a recovered one — no fresh request stands on an unavailable check.
assert A_Action_wiring_27 {
    built implies all c : Call | (c.dpCheck = StateUnavailable and no c.found) implies {
        c.act = PlaceHold implies c.answer = OutcomeUnknown
        all e : by.c | e.mark = Recovered
    }
}
check A_Action_wiring_27 for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state or an answer the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowFreshPlaceHold: a first place_hold is delegated and its id recorded against the token
-- with the first mark (the walkthrough's first call).
run ShowFreshPlaceHold {
    built and some e : stored | e.eact = PlaceHold and e.result in Commitment and e.mark = First
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ShowPlaceHoldReplay: a retried place_hold finds the entry and answers the same id without
-- the constituent (the walkthrough's second call).
run ShowPlaceHoldReplay {
    built and some c : Call | c.act = PlaceHold and replayArm[c] and c.answer in Commitment
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ShowConfirmReplay: a retried confirm answers the cached ok while the commitment stands
-- Confirmed, hiding the not-held a direct retry would get (the walkthrough's fifth step).
run ShowConfirmReplay {
    built and some c : Call | c.act = Confirm and replayArm[c] and c.answer = Ok and c.target.st = Confirmed
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ShowEvictedInPlaceThenFresh: a place_hold finds an entry past its window on a not-seen
-- token, evicts it in place and stands as a fresh request, its resource-unavailable
-- recorded (the walkthrough's sixth step).
run ShowEvictedInPlaceThenFresh {
    built and some c : Call | some evBy.c and c.act = PlaceHold and freshArm[c]
        and c.reached = ResourceUnavailable and some by.c
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ShowLegEviction: the eviction leg evicts an entry past its window on a not-seen token.
run ShowLegEviction {
    built and some e : evicted | no e.evBy
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ShowTokenCollision: a confirm reusing a place_hold's token is answered token-collision
-- (the token reuse scenario).
run ShowTokenCollision {
    built and some c : Call | collisionArm[c] and c.act = Confirm and c.found.eact = PlaceHold
        and c.answer = TokenCollision
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ShowOutcomeUnknown: a place_hold whose check answered state-unavailable, finding no
-- entry, is answered outcome-unknown carrying the one held commitment it may have placed.
run ShowOutcomeUnknown {
    built and some c : Call | unknownArm[c] and c.dpCheck = StateUnavailable and one c.cands
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ShowReEntry: a release on a seen token carrying no entry runs again and writes a recovered
-- entry (Indeterminate outcome 8, 13).
run ShowReEntry {
    built and some e : stored | e.mark = Recovered and e.eact = Release
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ShowRecoveredWindowOutlivesGuard: a recovered entry whose window is still open at an
-- instant Duplicate Prevention's guard on its token has elapsed — the case Housekeeping 5
-- guards beside Housekeeping 4.
run ShowRecoveredWindowOutlivesGuard {
    built and some e : stored, n : Int | e.mark = Recovered and n >= e.pending
        and n < windowEnd[e] and not underGuard[e.guardAt, n]
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ShowMalformedToken: a call whose token fails the boundary predicate is answered
-- invalid-request and records nothing.
run ShowMalformedToken {
    built and some c : Call | not wellFormed[c] and c.answer = InvalidRequest and no by.c
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ShowCachedRejection: a place_hold the registry refused is recorded against the token like
-- an answer (Wiring decision 2, the cache-the-failure rule).
run ShowCachedRejection {
    built and some e : stored | e.eact = PlaceHold and e.result = ResourceUnavailable
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ShowStorageFailureRecordsNothing: a fresh request whose write the database refused
-- answers storage-failure and leaves no entry.
run ShowStorageFailureRecordsNothing {
    built and some c : Call | freshArm[c] and c.reached = StorageFailure and no by.c
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester

-- ShowResolvingCollisionAnswersUnalike: finding (a) — a release carrying a confirm's token
-- and, as the confirm's commitment id, its digest is answered token-collision where the
-- confirm was answered ok.
run ShowResolvingCollisionAnswersUnalike {
    built and some c : Call, w : c.found.by | c.act in Resolving and w.act in Resolving
        and c.act != w.act and c.tok = w.tok and c.dig = w.dig and c.answer != w.answer
} for 3 but 4 Int, 2 Token, 2 Commitment, 2 Resource, 2 Requester
