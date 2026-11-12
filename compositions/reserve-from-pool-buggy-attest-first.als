-- reserve-from-pool-buggy-attest-first.als
-- DELIBERATELY WRONG twin of reserve-from-pool.als (unit: compositions/reserve-from-pool.md formal layer).
--
-- INJECTED DEFECT: a call attests before it reads the token results map and the journal, so a replay, a collision and a settle from the journal carry an attestation (Action wiring 13, 126).
--
-- BREAKS: A_Non_goal_13.
-- Everything else is reserve-from-pool.als as written; read its comments there.

module reserve_from_pool_buggy_attest_first

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Token: an idempotency token as the caller supplied it, compared byte-exact (Primitive
-- policy 3, 4): two tokens are the same only when they are the same token.
sig Token {}

-- Digest: a parameters digest, computed at the seam over a call's business parameters (Term
-- parameters digest, Composition state 19).
sig Digest {}

-- Op: what a call asks for — one of the four action types (Term action type) or the
-- read-only query, which is not one.
abstract sig Op {}
abstract sig Kind extends Op {}
one sig KReserve, KConfirm, KCancel, KExpire extends Kind {}
one sig KQuery extends Op {}

-- PState: a reservation's state in Provisional Commitment: Held, then Confirmed, Released or
-- Expired.
abstract sig PState {}
one sig Held, Confirmed, Released, Expired extends PState {}

-- WindowReading: the hold's window as Provisional Commitment reads it at a transition: open or
-- lapsed.
abstract sig WindowReading {}
one sig Open, Lapsed extends WindowReading {}

-- Phase: a journal entry is an action's intent entry or its outcome entry (Term intent entry,
-- Term outcome entry).
abstract sig Phase {}
one sig Intent, Outcome extends Phase {}

-- Code: an answer that is not a reservation id: ok, the answers a constituent decides, the
-- composition's own (token-collision, recording-failure carrying outcome, invalid-request), and
-- Refused, standing for every refusal.
abstract sig Code {}
one sig Ok, NotHeld, WindowElapsed, WindowNotElapsed, PoolCapacityExceeded, TokenCollision,
    RecordingFailureOutcome, InvalidRequest, Refused extends Code {}

-- DPAnswer: what Duplicate Prevention's check answers for a token: seen or not-seen.
abstract sig DPAnswer {}
one sig Seen, NotSeen extends DPAnswer {}

-- Verdict: how a call that ran afresh ends: its writes commit, its constituent's decided answer
-- is settled, or it is refused and writes nothing.
abstract sig Verdict {}
one sig Commit, Settle, Refuse extends Verdict {}

-- Pool: a Capacity Constraint Enforcement pool as it stands: its declared capacity and its
-- allocated count.
sig Pool {
    capacity  : one Int,
    allocated : one Int
}

-- Rsv: a reservation, a Provisional Commitment record keyed by its commitment id (the atom),
-- with its state as it stands.
sig Rsv {
    st : one PState
}

-- PoolEvent: one event on a pool's audit log, a unit allocated or released (a count of one,
-- Action wiring 45, 106), with, as a ghost, the call whose transaction made it.
abstract sig PoolEvent {
    pool : one Pool,
    by   : one Call
}
sig Allocation, Release extends PoolEvent {}

-- Att: one attestation Actor Identity answered: the action reference it binds, an action type
-- and a token (Term action reference).
sig Att {
    rk : one Kind,
    rt : lone Token
}

-- Call: one call as it reached the seam — what it asks for, its place in the store's serial
-- order, its token, digest, pool id (a reserve) and reservation id (a resolving action or the
-- query; at a reserve, the id place hold answered) — and, as ghosts of what it read and did:
-- Duplicate Prevention's answer, the token results entry it found, Provisional Commitment's
-- answer to its transition with the window reading behind it, its verdict, the attestation its
-- attest answered and what the composition answered (a set, so a build that answered twice
-- would show).
sig Call {
    op      : one Op,
    pos     : one Int,
    tok     : lone Token,
    dig     : lone Digest,
    ppool   : lone Pool,
    target  : lone Rsv,
    dp      : lone DPAnswer,
    found   : lone TRE,
    pcAns   : lone Code,
    winRead : lone WindowReading,
    verdict : lone Verdict,
    att     : lone Att,
    answer  : set (Rsv + Code)
}

-- Malformed: the calls whose inputs fail Primitive policy 1, 2, 5, 7 or 8 (a blank or
-- over-long token, a blank credential, a field a constituent's rules refuse, an envelope past
-- the cap). The caller's; an input.
sig Malformed in Call {}

-- Entry: one journal entry (Term journal entry): its action type, phase, token, journaled
-- digest, reservation id, pool id, attestation id, sequence number and the pool event it cites,
-- with, as a ghost, the call that appended it.
sig Entry {
    ekind : one Kind,
    phase : one Phase,
    etok  : one Token,
    edig  : one Digest,
    ersv  : lone Rsv,
    epool : lone Pool,
    eatt  : lone Att,
    sn    : one Int,
    cites : lone PoolEvent,
    eby   : one Call
}

-- Aged: the entries whose payload was destroyed past the audit horizon (Term aged entry).
sig Aged in Entry {}

-- TRE: one token results entry (Composition state 16 to 18): its token, action type, digest and
-- result, with, as a ghost, the call that settled it.
sig TRE {
    ttok   : one Token,
    tkind  : one Kind,
    tdig   : one Digest,
    result : set (Rsv + Code),
    tby    : one Call
}

-- Index: the reservation-to-pool binding as it stands, keyed by reservation id
-- (Composition state 1 to 3).
one sig Index {
    at : Rsv -> lone Pool
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers: the page's terms over one state
-- ─────────────────────────────────────────────────────────────────────────────

-- Resolving, SlotReturning: the resolving actions and the slot-returning ones (Term resolving
-- action, Term slot-returning action).
fun Resolving : set Kind { KConfirm + KCancel + KExpire }
fun SlotReturning : set Kind { KCancel + KExpire }

-- terminal: the state a resolving action's ok leaves its reservation in (Term terminal state).
fun terminal[k : Op] : PState {
    k = KConfirm => Confirmed else (k = KCancel => Released else Expired)
}

-- wellFormed: a state-changing call whose inputs pass the boundary (Primitive policy 1 to 8).
pred wellFormed[c : Call] { c.op in Kind and c not in Malformed }

-- J: the journal's entries for the call's token, as the call reads them: appended before it,
-- payload standing (Action wiring 12, Capability requirement 15).
fun J[c : Call] : set Entry {
    { e : Entry - Aged | e.etok = c.tok and e.eby.pos < c.pos }
}

-- matchesMap: the token results entry found carries the call's action type and digest (Term
-- matching token results entry).
pred matchesMap[c : Call] { c.found.tkind = c.op and c.found.tdig = c.dig }

-- The arms a call takes, from what it read:
--   invalid       — a malformed input (Primitive policy 1 to 8);
--   replay        — seen, a matching token results entry (Action wiring 5);
--   collisionMap  — seen, an entry of another action type or digest (Action wiring 6, 7);
--   seenNoEntry   — seen, no entry (Action wiring 10);
--   collisionJ    — not-seen, the journal holds an entry for the token that is not an own entry,
--                   or an own one under another digest (Action wiring 15, 125);
--   fromJournal   — not-seen, the action's outcome entry under the digest (Action wiring 14);
--   intentOnly    — not-seen, the action's intent entry and no outcome entry (Action wiring 19);
--   fresh         — not-seen, the journal holds nothing for the token (Action wiring 20, 119).
pred invalidArm[c : Call] { c.op in Kind and c in Malformed }
pred replayArm[c : Call] { c.dp = Seen and some c.found and matchesMap[c] }
pred collisionMapArm[c : Call] { c.dp = Seen and some c.found and not matchesMap[c] }
pred seenNoEntryArm[c : Call] { c.dp = Seen and no c.found }
pred collisionJournalArm[c : Call] {
    c.dp = NotSeen and some e : J[c] | e.ekind != c.op or e.edig != c.dig
}
pred fromJournalArm[c : Call] {
    c.dp = NotSeen and not collisionJournalArm[c] and some (J[c] & phase.Outcome)
}
pred intentOnlyArm[c : Call] {
    c.dp = NotSeen and not collisionJournalArm[c] and no (J[c] & phase.Outcome) and some J[c]
}
pred freshArm[c : Call] { c.dp = NotSeen and no J[c] }

-- resultOf: the result outcome entries record: a reserve outcome entry's reservation id, ok for
-- a resolving action's.
fun resultOf[es : set Entry] : set (Rsv + Code) {
    { x : Rsv + Code | x in (es & ekind.KReserve).ersv or (x = Ok and some (es - ekind.KReserve)) }
}

-- verdictFor: how a resolving call that ran afresh ends, by Provisional Commitment's answer:
-- ok commits (Action wiring 92, 96, 110, 113); not-held, window-elapsed and window-not-elapsed
-- are settled (Action wiring 85 to 87, 89); a refusal writes nothing (Execution Contract Read 4).
fun verdictFor[k : Kind, a : Code] : Verdict {
    a = Ok => Commit else (a in NotHeld + WindowElapsed + WindowNotElapsed => Settle else Refuse)
}

-- transitioned: the resolving calls whose transition Provisional Commitment made and whose
-- transaction committed.
fun transitioned : set Call {
    { c : Call | c.op in Resolving and c.pcAns = Ok and c.verdict = Commit }
}

-- writes: the call ran afresh and its writes commit — a commit or a settle.
pred writes[c : Call] { c.verdict = Commit or c.verdict = Settle }

-- outcomesOf: the outcome entries of the given action types naming the reservation.
fun outcomesOf[r : Rsv, ks : set Kind] : set Entry {
    { e : phase.Outcome | e.ersv = r and e.ekind in ks }
}

-- reservedIn: the reservations a reserve against the pool placed.
fun reservedIn[p : Pool] : set Rsv {
    { r : Rsv | some c : Call | c.op = KReserve and c.target = r and c.ppool = p }
}

-- boundHolding: the pool's bound reservations in a slot-holding state (Term bound slot-holding
-- count, Term slot-holding state).
fun boundHolding[p : Pool] : set Rsv {
    { r : Rsv | Index.at[r] = p and r.st in Held + Confirmed }
}

-- quiet: no [Reserve] against the pool is in flight — every reserve that committed has written
-- its binding entry, its last step (Term quiescence, Action wiring 78).
pred quiet[p : Pool] {
    all c : Call | (c.op = KReserve and c.verdict = Commit and c.ppool = p) implies some Index.at[c.target]
}

-- auditCount: the auditor's count of Check 1.1 — the reservations reached by traversing the
-- journal's reserve outcome entries for the pool and those the pool's binding entries name,
-- less every reservation a slot-returning outcome entry names.
fun auditCount[p : Pool] : set Rsv {
    ({ e : Entry - Aged | e.ekind = KReserve and e.phase = Outcome and e.epool = p }.ersv
        + Index.at.p)
    - { e : Entry - Aged | e.ekind in SlotReturning and e.phase = Outcome }.ersv
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The store runs the calls one after another (Execution Contract Database 2) and Event Log
-- numbers its entries in append order (its total order; Capability requirement 46): positions
-- and sequence numbers are distinct and agree across calls. Four-bit integers hold them.
fact SerialOrder {
    all disj c1, c2 : Call | c1.pos != c2.pos
    all c : Call | c.pos >= 0
    all disj e1, e2 : Entry | e1.sn != e2.sn
    all e : Entry | e.sn >= 0
    all e1, e2 : Entry | e1.eby.pos < e2.eby.pos implies e1.sn < e2.sn
}

-- Each call's parameters, by its signature: the query takes a reservation id and no token
-- (Action wiring 114); a state-changing action takes a token and its digest; a reserve takes a
-- pool id; a resolving action takes a reservation id. The caller's.
fact CallShape {
    all c : Call | c.op = KQuery implies
        (no c.tok and no c.dig and no c.ppool and one c.target and c not in Malformed)
    all c : Call | c.op in Kind implies (one c.tok and one c.dig)
    all c : Call | c.op = KReserve implies one c.ppool else no c.ppool
    all c : Call | c.op in Resolving implies one c.target
}

-- The seam's digest function is collision-resistant over the business parameters (Capability
-- requirement 28, 31; Term business parameter): one digest means one kind of parameters — a
-- reserve's pool or a resolving action's reservation id — and a resolving action's
-- reservation id alone decides its digest.
fact SeamDigest {
    all c1, c2 : Call | (c1.op in Kind and c2.op in Kind and c1.dig = c2.dig) implies {
        c1.op = KReserve iff c2.op = KReserve
        c1.op = KReserve implies c1.ppool = c2.ppool
        c1.op in Resolving implies c1.target = c2.target
    }
    all c1, c2 : Call | (c1.op in Resolving and c2.op in Resolving and c1.target = c2.target)
        implies c1.dig = c2.dig
}

-- Duplicate Prevention's check answers seen only for a token a call recorded before (its
-- record, made with a token results entry, Term settling); a not-seen answer may follow one
-- whose window elapsed.
fact DuplicatePreventionCheck {
    all c : Call | c.dp = Seen implies some w : Call | w.pos < c.pos and w.tok = c.tok and some tby.w
}

-- Actor Identity answers one attestation id per attest call, and no attestation stands that no
-- call's attest answered.
fact ActorIdentityAttestations {
    all a : Att | one att.a
}

-- Provisional Commitment's answers and records: a transition is answered from the state the
-- serial order left (a Held reservation takes ok, window-elapsed or window-not-elapsed; one a
-- committed transition resolved takes not-held — single resolution, its Invariant 2); confirm
-- and release need an open window and expire a lapsed one (its Invariant 7); a reservation is
-- Held until a committed transition leaves it in that action's terminal state; place hold
-- answers an id to one call; and a caller names a reservation already placed.
fact ProvisionalCommitment {
    all c : Call | c.pcAns = Ok implies
        (c.op in KConfirm + KCancel => c.winRead = Open else c.winRead = Lapsed)
    all c : Call | c.pcAns = WindowElapsed implies (c.op in KConfirm + KCancel and c.winRead = Lapsed)
    all c : Call | c.pcAns = WindowNotElapsed implies (c.op = KExpire and c.winRead = Open)
    all c : Call | (no c.pcAns or c.pcAns not in Ok + WindowElapsed + WindowNotElapsed) implies no c.winRead
    all c : Call | (some c.pcAns and c.pcAns in Ok + WindowElapsed + WindowNotElapsed) implies
        no w : transitioned | w.target = c.target and w.pos < c.pos
    all c : Call | c.pcAns = NotHeld implies
        some w : transitioned | w.target = c.target and w.pos < c.pos
    all r : Rsv | r.st = Held iff no (transitioned & target.r)
    all c : transitioned | c.target.st = terminal[c.op]
    all r : Rsv | lone c : Call | c.op = KReserve and c.target = r
    all c : Call, w : Call | (c.op in Resolving + KQuery and w.op = KReserve and w.target = c.target)
        implies w.pos < c.pos
}

-- Capacity Constraint Enforcement's arithmetic: allocated is the pool's allocations less its
-- releases, and never passes the declared capacity (its Invariant 4).
fact CapacityConstraintArithmetic {
    all p : Pool | p.allocated = minus[#(Allocation & pool.p), #(Release & pool.p)]
    all p : Pool | p.capacity >= 0 and p.allocated <= p.capacity
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writes: what each call and each write outside a transaction leave
-- ─────────────────────────────────────────────────────────────────────────────

-- boundaryWiring: a state-changing call is checked against Duplicate Prevention only once its
-- inputs pass (Primitive policy 9); a malformed one is answered invalid-request and writes
-- nothing (Primitive policy 10).
pred boundaryWiring {
    all c : Call | some c.dp iff wellFormed[c]
    all c : Call | invalidArm[c] implies {
        c.answer = InvalidRequest
        no eby.c
        no tby.c
        no by.c
    }
}

-- lookupWiring: a call on a seen token finds the token results entry for it, settled before
-- it, since no entry is evicted before Duplicate Prevention answers not-seen (Composition
-- state 22, Action wiring 5); a call on a not-seen token does not look (Action wiring 12).
pred lookupWiring {
    all c : Call | c.dp = Seen implies some c.found
    all c : Call | some c.found implies
        (c.dp = Seen and c.found.ttok = c.tok and c.found.tby.pos < c.pos)
}

-- queryWiring: the query answers the reservation's reading and writes nothing (Action wiring
-- 114 to 117).
pred queryWiring {
    all c : Call | c.op = KQuery implies {
        c.answer = c.target
        no eby.c
        no tby.c
        no by.c
    }
}

-- answerWiring: a replay answers the entry's result and writes nothing (Action wiring 5, 8, 9);
-- a collision answers token-collision (Action wiring 6, 7, 15, 125); a seen token with no
-- entry, or a bare intent entry, answers recording-failure carrying outcome and settles
-- nothing (Action wiring 10, 11, 19); a settle from the journal answers the outcome entry's
-- result and calls no constituent (Action wiring 14).
pred answerWiring {
    all c : Call | replayArm[c] implies {
        c.answer = c.found.result
        no eby.c
        no tby.c
        no by.c
    }
    all c : Call | (collisionMapArm[c] or collisionJournalArm[c]) implies {
        c.answer = TokenCollision
        no eby.c
        no tby.c
        no by.c
    }
    all c : Call | (seenNoEntryArm[c] or intentOnlyArm[c]) implies {
        c.answer = RecordingFailureOutcome
        no eby.c
        no tby.c
        no by.c
    }
    all c : Call | fromJournalArm[c] implies {
        c.answer = resultOf[J[c] & phase.Outcome]
        no eby.c
        no by.c
    }
}

-- attestWiring: a call that runs afresh calls Actor Identity's attest with the action
-- reference, its action type and token (Action wiring 20, 119), after the journal read, so a
-- token the journal holds is never attested (Action wiring 13, 126); the attestation commits
-- with the call's writes, and a refusal leaves none (Execution Contract Read 4, Action wiring
-- 25).
pred attestWiring {
    all c : Call | some c.att iff (wellFormed[c] and not (freshArm[c] and c.verdict = Refuse))
    all c : Call | some c.att implies (c.att.rk = c.op and c.att.rt = c.tok)
}

-- verdictWiring: a fresh call ends one way; a resolving one goes to Provisional Commitment
-- only for a reservation with a binding entry, which is never removed (Action wiring 80, 81;
-- Composition state 6), and ends by its answer; a reserve ends by its constituents' answers.
-- Each answers accordingly: the reservation id or ok on a commit (Action wiring 79, 96, 113),
-- the decided answer on a settle (Action wiring 52, 89), Refused on a refusal.
pred verdictWiring {
    all c : Call | one c.verdict iff freshArm[c]
    all c : Call | (freshArm[c] and c.op in Resolving) implies {
        one c.pcAns
        c.verdict = verdictFor[c.op, c.pcAns]
    }
    all c : Call | not (freshArm[c] and c.op in Resolving) implies no c.pcAns
    all c : Call | (c.op in Resolving and writes[c]) implies some Index.at[c.target]
    all c : Call | c.verdict = Commit implies c.answer = (c.op = KReserve => c.target else Ok)
    all c : Call | c.verdict = Settle implies
        c.answer = (c.op = KReserve => PoolCapacityExceeded else c.pcAns)
    all c : Call | c.verdict = Refuse implies {
        c.answer = Refused
        no eby.c
        no tby.c
        no by.c
    }
}

-- holdWiring: a reserve carries a reservation id exactly when its hold was placed and committed
-- (Action wiring 53, 79), and every reservation is one the composition placed (Composes 8).
pred holdWiring {
    all c : Call | c.op = KReserve implies (some c.target iff c.verdict = Commit)
    all r : Rsv | some c : Call | c.op = KReserve and c.target = r
}

-- poolWiring: a committed reserve allocates one unit of its pool (Action wiring 45); a confirm
-- makes no pool write (Action wiring 91); a committed cancel or expire releases one unit of the
-- pool its binding entry names (Action wiring 28, 106); nothing else touches a pool
-- (Wiring decision 6, Composes 9).
pred returnsSlot[c : Call] {
    one by.c
    by.c in Release
    (by.c).pool = Index.at[c.target]
}
pred poolWiring {
    all c : Call | (c.verdict = Commit and c.op = KReserve) implies {
        one by.c
        by.c in Allocation
        (by.c).pool = c.ppool
    }
    all c : Call | (c.verdict = Commit and c.op = KConfirm) implies no by.c
    all c : Call | (c.verdict = Commit and c.op = KCancel) implies returnsSlot[c]
    all c : Call | (c.verdict = Commit and c.op = KExpire) implies returnsSlot[c]
    all c : Call | c.verdict != Commit implies no by.c
}

-- journalWiring: a committed or settled call appends one intent entry carrying its action,
-- token, digest, attestation id and business parameters, a resolving one the binding entry's
-- pool id (Action wiring 26 to 28); a committed call appends one outcome entry after it,
-- carrying its token, the reservation id, the pool id, the event it cites, its attestation id
-- and digest (Action wiring 62, 63, 92, 93, 110, 111); a settled call appends no outcome entry.
pred journalWiring {
    all c : Call | writes[c] implies {
        one (eby.c & phase.Intent)
        all i : eby.c & phase.Intent | {
            i.ekind = c.op
            i.etok = c.tok
            i.edig = c.dig
            i.eatt = c.att
            i.ersv = (c.op = KReserve => none else c.target)
            i.epool = (c.op = KReserve => c.ppool else Index.at[c.target])
            no i.cites
        }
    }
    all c : Call | c.verdict = Settle implies no (eby.c & phase.Outcome)
    all c : Call | c.verdict = Commit implies {
        one (eby.c & phase.Outcome)
        all o : eby.c & phase.Outcome | {
            o.ekind = c.op
            o.etok = c.tok
            o.edig = c.dig
            o.eatt = c.att
            o.ersv = c.target
            o.epool = (c.op = KReserve => c.ppool else Index.at[c.target])
            o.cites = by.c
            all i : eby.c & phase.Intent | i.sn < o.sn
        }
    }
}

-- settleWiring: a call that settles an answer — a commit, a settle, or a settle from the
-- journal — writes one token results entry carrying its token, action type, digest and answer
-- (Term settling, Composition state 17, 18); no other call writes one (Action wiring 9, 11).
pred settleWiring {
    all c : Call | (writes[c] or fromJournalArm[c]) implies one tby.c else no tby.c
    all t : TRE | {
        t.ttok = t.tby.tok
        t.tkind = t.tby.op
        t.tdig = t.tby.dig
        t.result = t.tby.answer
    }
}

-- bindingWiring: a binding entry stands only for a reservation whose reserve outcome entry
-- landed, and carries that entry's pool id — written after it (Composition state 4,
-- Action wiring 78), by a settle from the journal (Action wiring 18) or by the rebuild
-- (Composition state 10, 11).
pred bindingWiring {
    all r : Rsv | some Index.at[r] implies
        some e : Entry | e.ekind = KReserve and e.phase = Outcome and e.ersv = r and Index.at[r] = e.epool
}

-- retentionWiring: past the audit horizon, a reserve outcome entry's payload goes only once its
-- reservation's binding entry stands (Capability requirement 48), and a slot-returning outcome
-- entry's never while it stands (Capability requirement 49). The model ages no other entry.
pred retentionWiring {
    all e : Aged | e.phase = Outcome and e.ekind in KReserve + SlotReturning
    all e : Aged | e.ekind = KReserve implies some Index.at[e.ersv]
    all e : Aged | e.ekind in SlotReturning implies no Index.at[e.ersv]
}

-- built: every record in the state is what an admitted write left.
pred built {
    boundaryWiring
    lookupWiring
    queryWiring
    answerWiring
    attestWiring
    verdictWiring
    holdWiring
    poolWiring
    journalWiring
    settleWiring
    bindingWiring
    retentionWiring
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's writes can leave, or any call's answer,
-- that violates this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: at quiescence a pool's allocated does not exceed its bound slot-holding
-- count — no slot is leaked.
assert A_Invariant_1_1 {
    built implies all p : Pool | quiet[p] implies p.allocated <= #boundHolding[p]
}
check A_Invariant_1_1 for 3 but 4 Int, 6 Entry

-- A_Invariant_1_5: at quiescence a pool's bound slot-holding count does not exceed its
-- allocated — no slot is counted that was returned.
assert A_Invariant_1_5 {
    built implies all p : Pool | quiet[p] implies #boundHolding[p] <= p.allocated
}
check A_Invariant_1_5 for 3 but 4 Int, 6 Entry

-- A_Invariant_2_1: no reservation has two pool releases (Check 3.1).
assert A_Invariant_2_1 {
    built implies all r : Rsv | lone { e : Release | e.by.target = r }
}
check A_Invariant_2_1 for 3 but 4 Int, 6 Entry

-- A_Invariant_3_1: a pool's Confirmed reservations do not pass its capacity (Check 2.1).
assert A_Invariant_3_1 {
    built implies all p : Pool | #(reservedIn[p] & st.Confirmed) <= p.capacity
}
check A_Invariant_3_1 for 3 but 4 Int, 6 Entry

-- A_Invariant_4_1: no confirm the composition committed read the hold's window lapsed.
assert A_Invariant_4_1 {
    built implies all c : Call | (c.op = KConfirm and c.verdict = Commit) implies c.winRead = Open
}
check A_Invariant_4_1 for 3 but 4 Int, 6 Entry

-- A_Invariant_4_2: no cancel the composition committed read the hold's window lapsed: a lapsed
-- hold resolves only through [Expire Reservation].
assert A_Invariant_4_2 {
    built implies all c : Call | (c.op = KCancel and c.verdict = Commit) implies c.winRead = Open
}
check A_Invariant_4_2 for 3 but 4 Int, 6 Entry

-- A_Invariant_5_1: a call on a token Duplicate Prevention still holds (inside the window),
-- carrying a settled call's token, action type and digest, answers what that call answered
-- (finding (a): the page's text leaves the action type out).
assert A_Invariant_5_1 {
    built implies all c, w : Call |
        (c.dp = Seen and some tby.w and w.pos < c.pos and w.tok = c.tok and w.op = c.op and w.dig = c.dig)
            implies c.answer = w.answer
}
check A_Invariant_5_1 for 3 but 4 Int, 6 Entry

-- A_Invariant_5_2: no two calls that made constituent writes carry one token (Check 5.2) —
-- read for all time, as the journal read carries it past the window.
assert A_Invariant_5_2 {
    built implies all disj c1, c2 : Call | (c1.verdict = Commit and c2.verdict = Commit) implies c1.tok != c2.tok
}
check A_Invariant_5_2 for 3 but 4 Int, 6 Entry

-- A_Invariant_5_3: a well-formed call whose token carries a record another action type left
-- (a journal entry or a token results entry) answers token-collision.
assert A_Invariant_5_3 {
    built implies all c, w : Call |
        (wellFormed[c] and w.pos < c.pos and w.tok = c.tok and w.op != c.op and some (eby.w + tby.w))
            implies c.answer = TokenCollision
}
check A_Invariant_5_3 for 3 but 4 Int, 6 Entry

-- A_Invariant_6_1: each state change a reservation went through carries exactly one outcome
-- entry naming it: its reserve, its confirm if Confirmed, its cancel if Released, its expire if
-- Expired, and no other.
assert A_Invariant_6_1 {
    built implies all r : Rsv | {
        one outcomesOf[r, KReserve]
        r.st = Confirmed implies one outcomesOf[r, KConfirm] else no outcomesOf[r, KConfirm]
        r.st = Released implies one outcomesOf[r, KCancel] else no outcomesOf[r, KCancel]
        r.st = Expired implies one outcomesOf[r, KExpire] else no outcomesOf[r, KExpire]
    }
}
check A_Invariant_6_1 for 3 but 4 Int, 6 Entry

-- A_Invariant_6_2: every outcome entry carries the attestation id its invocation's attest
-- answered (Check 6.6).
assert A_Invariant_6_2 {
    built implies all o : phase.Outcome | one o.eatt and o.eatt = o.eby.att
}
check A_Invariant_6_2 for 3 but 4 Int, 6 Entry

-- A_Invariant_6_3: the intent entry carrying an outcome entry's attestation id stands at or
-- before it in sequence order (Check 6.8).
assert A_Invariant_6_3 {
    built implies all o : phase.Outcome | some i : phase.Intent | i.eatt = o.eatt and i.sn <= o.sn
}
check A_Invariant_6_3 for 3 but 4 Int, 6 Entry

-- A_Invariant_6_4: no journal entry was written by the read-only query.
assert A_Invariant_6_4 {
    built implies no e : Entry | e.eby.op = KQuery
}
check A_Invariant_6_4 for 3 but 4 Int, 6 Entry

-- A_Invariant_8_1: every constituent write — a pool event, a placed hold, a transition — is an
-- invocation's whose attest answered the attestation id.
assert A_Invariant_8_1 {
    built implies {
        all e : PoolEvent | some e.by.att
        all c : Call | (c in transitioned or (c.op = KReserve and some c.target)) implies some c.att
    }
}
check A_Invariant_8_1 for 3 but 4 Int, 6 Entry

-- A_Invariant_8_2: an entry's attestation binds the action reference the entry's own action and
-- token recompose (Check 6.2, 6.5), and the entries carrying one attestation are one
-- invocation's.
assert A_Invariant_8_2 {
    built implies {
        all e : Entry | some e.eatt implies (e.eatt.rk = e.ekind and e.eatt.rt = e.etok)
        all a : Att | lone (eatt.a).eby
    }
}
check A_Invariant_8_2 for 3 but 4 Int, 6 Entry

-- A_Check_1_1: the auditor's count over the traversal and the binding equals the pool's
-- allocated, in every state, the window before a binding entry is written included.
assert A_Check_1_1 {
    built implies all p : Pool | p.allocated = #auditCount[p]
}
check A_Check_1_1 for 3 but 4 Int, 6 Entry

-- A_Wiring_decision_1: a binding entry names the pool whose slot its reservation holds — the
-- pool of the reservation's allocation event.
assert A_Wiring_decision_1 {
    built implies all r : Rsv | some Index.at[r] implies
        Index.at[r] = { a : Allocation | a.by.target = r }.pool
}
check A_Wiring_decision_1 for 3 but 4 Int, 6 Entry

-- A_Wiring_decision_3: no pool release names a Confirmed reservation.
assert A_Wiring_decision_3 {
    built implies all e : Release | e.by.target.st != Confirmed
}
check A_Wiring_decision_3 for 3 but 4 Int, 6 Entry

-- A_Wiring_decision_6: a reservation has a pool release exactly when a slot-returning
-- transition owed one: it is Released or Expired.
assert A_Wiring_decision_6 {
    built implies all r : Rsv | (some e : Release | e.by.target = r) iff r.st in Released + Expired
}
check A_Wiring_decision_6 for 3 but 4 Int, 6 Entry

-- A_Non_goal_9: every reservation holds exactly one slot — one allocation event, of one unit.
assert A_Non_goal_9 {
    built implies all r : Rsv | one { a : Allocation | a.by.target = r }
}
check A_Non_goal_9 for 3 but 4 Int, 6 Entry

-- A_Non_goal_12: a replay records nothing of who replayed: no journal entry and no token
-- results entry.
assert A_Non_goal_12 {
    built implies all c : Call | replayArm[c] implies (no eby.c and no tby.c)
}
check A_Non_goal_12 for 3 but 4 Int, 6 Entry

-- A_Non_goal_13: a replay is not authenticated: it carries no attestation.
assert A_Non_goal_13 {
    built implies all c : Call | replayArm[c] implies no c.att
}
check A_Non_goal_13 for 3 but 4 Int, 6 Entry

-- A_Non_goal_14: a pre-attest refusal — a malformed input, a token collision, a replay —
-- writes no journal entry (Term pre-attest refusal).
assert A_Non_goal_14 {
    built implies all c : Call |
        (invalidArm[c] or collisionMapArm[c] or collisionJournalArm[c] or replayArm[c]) implies no eby.c
}
check A_Non_goal_14 for 3 but 4 Int, 6 Entry

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state or an answer the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowHeldBound: a reserve took a slot, placed a hold and wrote its binding entry (the
-- walkthrough's first step).
run ShowHeldBound {
    built and some r : Rsv | r.st = Held and some Index.at[r] and some p : Pool | p.allocated = 1
} for 3 but 4 Int, 6 Entry

-- ShowConfirmKeepsSlot: a confirmed reservation keeps its slot: no release, still counted
-- (the walkthrough's fifth step).
run ShowConfirmKeepsSlot {
    built and some r : Rsv | r.st = Confirmed and some Index.at[r] and Index.at[r].allocated = 1
} for 3 but 4 Int, 6 Entry

-- ShowCancelReturnsSlot: a cancel returned the slot with its outcome entry citing the release.
run ShowCancelReturnsSlot {
    built and some r : Rsv, o : outcomesOf[r, KCancel] | r.st = Released and o.cites in Release
} for 3 but 4 Int, 6 Entry

-- ShowExpireReturnsSlot: an expire of a lapsed hold returned the slot (the walkthrough's sixth
-- step).
run ShowExpireReturnsSlot {
    built and some c : transitioned | c.op = KExpire and c.winRead = Lapsed and some by.c
} for 3 but 4 Int, 6 Entry

-- ShowCapacityExceededSettled: a reserve against a full pool is settled pool-capacity-exceeded:
-- an intent entry and a token results entry, no outcome entry, no slot (the walkthrough's third
-- step).
run ShowCapacityExceededSettled {
    built and some c : Call | c.op = KReserve and c.verdict = Settle and some tby.c
        and some c.ppool and c.ppool.allocated = c.ppool.capacity
} for 3 but 4 Int, 6 Entry

-- ShowReserveReplay: a retried reserve on a seen token answers the reservation id from the
-- token results entry and takes no second slot (the walkthrough's fourth step).
run ShowReserveReplay {
    built and some c : Call | c.op = KReserve and replayArm[c] and c.answer in Rsv
} for 3 but 4 Int, 6 Entry

-- ShowWindowElapsedSettled: a confirm of a lapsed hold is settled window-elapsed and the hold
-- stays Held (the rejection path).
run ShowWindowElapsedSettled {
    built and some c : Call | c.op = KConfirm and c.verdict = Settle and c.answer = WindowElapsed
        and c.target.st = Held
} for 3 but 4 Int, 6 Entry

-- ShowSettleFromJournal: a retry under a token Duplicate Prevention forgot reads the reserve
-- outcome entry and settles its reservation id without attesting (Action wiring 14, 126).
run ShowSettleFromJournal {
    built and some c : Call | fromJournalArm[c] and c.op = KReserve and c.answer in Rsv and no c.att
} for 3 but 4 Int, 6 Entry

-- ShowSettledAnswerForgotten: the reading — a retry under a forgotten token whose call was
-- settled meets the bare intent entry and answers recording-failure carrying outcome.
run ShowSettledAnswerForgotten {
    built and some c, w : Call | intentOnlyArm[c] and w.verdict = Settle and w.tok = c.tok
} for 3 but 4 Int, 6 Entry

-- ShowTokenCollision: a confirm reusing a reserve's token is answered token-collision.
run ShowTokenCollision {
    built and some c, w : Call | c.op = KConfirm and w.op = KReserve and w.tok = c.tok
        and some eby.w and c.answer = TokenCollision
} for 3 but 4 Int, 6 Entry

-- ShowUnboundWindow: a reserve committed and its binding entry is not yet written — the pool is
-- not quiescent, and the auditor's traversal still reaches the reservation.
run ShowUnboundWindow {
    built and some r : Rsv, p : Pool | no Index.at[r] and r in auditCount[p]
} for 3 but 4 Int, 6 Entry

-- ShowAgedReserveEntry: a reserve outcome entry aged past the horizon once its binding entry
-- stood; the binding still counts the reservation (Composition state 15).
run ShowAgedReserveEntry {
    built and some e : Aged | e.ekind = KReserve and e.ersv.st = Held
} for 3 but 4 Int, 6 Entry

-- ShowQuery: the read-only query answers a reservation's reading.
run ShowQuery {
    built and some c : Call | c.op = KQuery and c.answer = c.target
} for 3 but 4 Int, 6 Entry

-- ShowResolvingCollisionAnswersUnalike: finding (a) — a cancel carrying a confirm's token and,
-- as the confirm's reservation id, its digest is answered token-collision where the confirm was
-- answered ok.
run ShowResolvingCollisionAnswersUnalike {
    built and some c, w : Call | w.op = KConfirm and c.op = KCancel and c.tok = w.tok
        and c.dig = w.dig and some tby.w and w.answer = Ok and c.answer = TokenCollision
} for 3 but 4 Int, 6 Entry
