-- defensible-retention-buggy-unavailable-as-zero.als
-- DELIBERATELY WRONG twin of defensible-retention.als (unit: compositions/defensible-retention.md formal layer).
--
-- INJECTED DEFECT: [Purge Eligible] answers a zero hold count where Legal Hold refused the read, not the unavailable sentinel (Action wiring 36, 37).
--
-- BREAKS: A_Invariant_7_3, A_Invariant_7_2.
-- Everything else is defensible-retention.als as written; read its comments there.

module defensible_retention_buggy_unavailable_as_zero

open util/integer

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Record: a business record reference (Term opaque input), compared byte-exact.
sig Record {}

-- RState: a retention's retention state as Retention Window keeps it: retained or purged.
abstract sig RState {}
one sig Retained, Purged extends RState {}

-- Retention: a retention of the business retention instance; it covers exactly one record
-- (Composition state 27) and a record may carry several (Composition state 28).
sig Retention {
    rec    : one Record,
    rstate : one RState
}

-- Elapsed: the retentions that are elapsed retentions at the now [Purge Eligible] reads at
-- (Term elapsed retention) — the clock's, an input.
sig Elapsed in Retention {}

-- HState: a hold's hold state as Legal Hold keeps it: active or released.
abstract sig HState {}
one sig Active, Released extends HState {}

-- Actor: an actor reference — a caller, a placing actor.
sig Actor {}

-- Hold: a Legal Hold record; it names exactly one record (Composition state 29) and carries
-- the placing actor Legal Hold recorded.
sig Hold {
    hrec     : one Record,
    hstate   : one HState,
    placedBy : one Actor
}

-- Mode: the hold check mode, strict or advisory (Term hold check mode).
abstract sig Mode {}
one sig Strict, Advisory extends Mode {}

-- Instance: the instance's settings: its one hold check mode (Capability requirement 25) and
-- its hold ids cap (Term hold ids cap).
one sig Instance {
    mode : one Mode,
    cap  : one Int
}

-- Answer: what a [Purge Record] call answers: ok, or one of its refusals (the action's
-- signature); AStorageFailure stands for a refusal Retention Window's purge answered after
-- the intent (Action wiring 64 to 66, 79).
abstract sig Answer {}
one sig AOk, ANotKnown, ANotEligible, AUnderActive, AUnderHold, AHoldUnavailable,
        ARecFailGate, ARecFailIntent, ARecFailOutcome, AStorageFailure extends Answer {}

-- Inv: one invocation, named by its invocation id (Term invocation id); the host supplies one
-- per invocation and never one to two (Capability requirement 2, 63), so an invocation is its
-- id. actor is the caller's actor reference, or the placing or releasing actor.
abstract sig Inv {
    actor : one Actor
}

-- Placement: a [Place Record Under Retention] call over prec; placed is the retention
-- Retention Window minted where the call committed (Term committed placement).
sig Placement extends Inv {
    prec   : one Record,
    placed : lone Retention
}

-- HoldPlacement: a [Place Hold] call over hprec; hplaced is the hold Legal Hold minted where
-- the call committed (Term committed hold placement).
sig HoldPlacement extends Inv {
    hprec   : one Record,
    hplaced : lone Hold
}

-- Release: a [Release Hold] call naming one hold id; rel is the holds its calls of Legal
-- Hold's release released (none where it did not commit).
sig Release extends Inv {
    names : one Hold,
    rel   : set Hold
}

-- Purge: a [Purge Record] call. Its inputs, what its reads answered: named, the retention
-- Retention Window's declared read answered for the retention id (none: no retention);
-- saw, the holds Legal Hold's read answered at the gate; sibs, the sibling set read; sibLate,
-- the siblings outside elapsed retention. What it makes of them: hids and hcount, the hold
-- check result as truncated (Primitive policy 20, 21); purged, the retentions its purges
-- purged; ans, its answer.
sig Purge extends Inv {
    named   : lone Retention,
    saw     : set Hold,
    sibs    : set Retention,
    sibLate : set Retention,
    hids    : set Hold,
    hcount  : one Int,
    purged  : set Retention,
    ans     : one Answer
}

-- HoldRefused: the purges whose gate read Legal Hold refused (Action wiring 50, 74, 77) — an input.
sig HoldRefused in Purge {}

-- NamedElapsed: the purges whose named retention is an elapsed retention — the clock's, an input.
sig NamedElapsed in Purge {}

-- GateOwed: the purges whose gate record the substrate did not append (Term owed record) — an input.
sig GateOwed in Purge {}

-- IntentOwed: the purges whose intent the substrate did not append, so the call commits
-- nothing (Action wiring 83) — an input.
sig IntentOwed in Purge {}

-- PurgeRefused: the purges whose call of Retention Window's purge, for the named retention
-- or for a sibling, answered a refusal or no answer, so the call commits nothing and answers
-- storage-failure (Action wiring 79, 80) — an input.
sig PurgeRefused in Purge {}

-- OutcomeOwed: the purges whose own outcome the substrate did not append, so the call
-- commits nothing (Action wiring 84, 99) — an input.
sig OutcomeOwed in Purge {}

-- Within: the acts that stand within the audit horizon (Term within the audit horizon) — the
-- clock's, an input.
sig Within in Inv {}

-- EKind: an audit record's kind: an intent, an outcome naming what the act did (retention
-- placed, hold placed, hold released or record purged, by the invocation's kind), or a gate
-- record (Term gate record).
abstract sig EKind {}
one sig KIntent, KOutcome, KGate extends EKind {}

-- Event: one audit record on the substrate, carrying its invocation id (Action wiring 3 to 5)
-- and its log position, with the payload fields the rules write: a retention id, a record
-- reference, a hold id, an actor, a hold check result (hold ids and count) and a record purged
-- outcome's purged retention ids.
sig Event {
    inv      : one Inv,
    ekind    : one EKind,
    pos      : one Int,
    eret     : lone Retention,
    erec     : lone Record,
    ehold    : lone Hold,
    eactor   : lone Actor,
    ehids    : set Hold,
    ehcount  : lone Int,
    epurged  : set Retention
}

-- HcrCarried: the records whose payload carries a hold check result field, empty or not.
sig HcrCarried in Event {}

-- Destroyed: the records whose payload the audit instance has destroyed (Term destroyed event).
sig Destroyed in Event {}

-- Tuple: one eligibility tuple [Purge Eligible] answers (Term eligibility tuples): the
-- retention and its hold count, or no count for the unavailable sentinel.
sig Tuple {
    tret   : one Retention,
    tcount : lone Int
}

-- PERefused: the records whose hold records Legal Hold refused to read during the [Purge
-- Eligible] call — an input.
sig PERefused in Record {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- intentOf: the intents carrying the invocation's id.
fun intentOf[i : Inv] : set Event { { e : Event | e.inv = i and e.ekind = KIntent } }

-- gateOf: the gate records carrying the invocation's id.
fun gateOf[i : Inv] : set Event { { e : Event | e.inv = i and e.ekind = KGate } }

-- closings: the outcomes carrying the invocation's id.
fun closings[i : Inv] : set Event { { e : Event | e.inv = i and e.ekind = KOutcome } }

-- ownOutcome: the outcomes the invocation itself wrote, which are all of them: no other party
-- writes an outcome (Execution Contract Database 1).
fun ownOutcome[i : Inv] : set Event { closings[i] }

-- activeOver: the active holds over a record, what Legal Hold's read with the active state
-- answers for it (Legal Hold Operation 23).
fun activeOver[r : Record] : set Hold { { h : Hold | h.hrec = r and h.hstate = Active } }

-- destroyedRecords: the records a purged retention covers (Term destroyed record).
fun destroyedRecords : set Record { { r : Record | some t : Retention | t.rec = r and t.rstate = Purged } }

-- tuplesOver: the eligibility tuples whose retention covers the record.
fun tuplesOver[r : Record] : set Tuple { { t : Tuple | t.tret.rec = r } }

-- holdBlocked: a tuple with a hold count above zero or the unavailable sentinel (Term hold-blocked).
pred holdBlocked[t : Tuple] { no t.tcount or gt[t.tcount, 0] }

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- Retention Window's records: a retention a purge purged stands purged, and a retention is
-- purged once (Retention Window Invariant 3, terminal absorption: a second purge answers
-- not-retained).
fact RetentionWindowRecords {
    all p : Purge | p.purged in rstate.Purged
    all disj p1, p2 : Purge | no p1.purged & p2.purged
}

-- Retention Window's declared read: the sibling set answers retentions over the named
-- retention's record beside it (Composition state 19, Term sibling set); the late siblings
-- are among them.
fact RetentionWindowReads {
    all p : Purge | p.sibs in rec.(p.named.rec) - p.named
    all p : Purge | p.sibLate in p.sibs
}

-- Legal Hold's read at the gate answers holds over the record it is asked about, and a
-- refused read answers none (Legal Hold Operation 23).
fact LegalHoldReads {
    all p : Purge | p.saw in hrec.(p.named.rec)
    all p : HoldRefused | no p.saw
}

-- Legal Hold's records: a hold stands released exactly when a release's call released it,
-- and once (Legal Hold's release answers already-released for a released hold); every
-- release goes through [Release Hold] (Capability requirement 53).
fact LegalHoldRecords {
    all h : Hold | h.hstate = Released iff h in Release.rel
    all disj r1, r2 : Release | no r1.rel & r2.rel
}

-- The hold ids cap is a positive count the deployment declares (Term hold ids cap, default 32).
fact InstanceSettings {
    gt[Instance.cap, 0]
}

-- Event Log numbers each record with its own sequence number (Event Log Invariant 3).
fact EventLog {
    all disj e1, e2 : Event | e1.pos != e2.pos
}

-- The audit horizon: one audit retention policy for every event (Capability requirement 57),
-- so the substrate destroys payloads oldest first in log order, and an act within the audit
-- horizon has none of its audit records destroyed (Term within the audit horizon, Term horizon
-- margin).
fact AuditHorizon {
    all d : Destroyed, e : Event | lt[e.pos, d.pos] implies e in Destroyed
    no Destroyed & inv.Within
}

-- Execution Contract Database 1: a placement's, a hold placement's and a hold release's
-- intent, constituent write and outcome commit together or not at all (the store-only acts).
fact StoreOnlyActsCommitWhole {
    all p : Placement | (some p.placed iff some intentOf[p]) and (some p.placed iff some ownOutcome[p])
    all p : HoldPlacement | (some p.hplaced iff some intentOf[p]) and (some p.hplaced iff some ownOutcome[p])
    all r : Release | (some r.rel iff some intentOf[r]) and (some r.rel iff some ownOutcome[r])
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Part A — the writes: what each call leaves
-- ─────────────────────────────────────────────────────────────────────────────

-- placementWiring: Retention Window is called with the record reference (Action wiring 9);
-- the intent carries the record reference (Action wiring 6); the retention placed outcome
-- carries the retention id and the record reference, after the intent (Action wiring 11).
pred placementWiring[p : Placement] {
    lone intentOf[p] and lone ownOutcome[p] and no gateOf[p]
    some p.placed implies p.placed.rec = p.prec
    all i : intentOf[p] | i.erec = p.prec
    all o : ownOutcome[p] | o.ekind = KOutcome and o.eret = p.placed and o.erec = p.prec
        and (some i : intentOf[p] | lt[i.pos, o.pos])
}

-- holdPlacementWiring: Legal Hold's place is called with the record reference and the
-- placing actor (Action wiring 17); the hold placed outcome carries the hold id, the record
-- reference and the placing actor, after the intent (Action wiring 18).
pred holdPlacementWiring[p : HoldPlacement] {
    lone intentOf[p] and lone ownOutcome[p] and no gateOf[p]
    some p.hplaced implies (p.hplaced.hrec = p.hprec and p.hplaced.placedBy = p.actor)
    all i : intentOf[p] | i.erec = p.hprec and i.eactor = p.actor
    all o : ownOutcome[p] | o.ekind = KOutcome and o.ehold = p.hplaced and o.erec = p.hprec
        and o.eactor = p.actor and (some i : intentOf[p] | lt[i.pos, o.pos])
}

-- releaseWiring: an admitted release calls Legal Hold's release once, with the hold id
-- (Action wiring 25; Non-goal 26: no hold set in one call); the hold released outcome carries
-- the hold id, after the intent (Action wiring 26).
pred releaseWiring[r : Release] {
    lone intentOf[r] and lone ownOutcome[r] and no gateOf[r]
    some intentOf[r] implies r.rel = r.names
    all i : intentOf[r] | i.ehold = r.names
    all o : ownOutcome[r] | o.ekind = KOutcome and o.ehold = r.names
        and (some i : intentOf[r] | lt[i.pos, o.pos])
}

-- resultWiring: the hold check result is what the gate read answered: empty, or the hold ids
-- truncated to the cap with the true count (Term hold check result, Primitive policy 20, 21).
pred resultWiring[p : Purge] {
    some p.saw implies {
        p.hcount = #p.saw
        p.hids in p.saw
        #p.hids = (lt[Instance.cap, #p.saw] => Instance.cap else #p.saw)
    }
    no p.saw implies (no p.hids and p.hcount = 0)
}

-- refuseAhead: a refusal ahead of the intent: the answer, and no intent, gate record,
-- outcome or purge (Action wiring 108; Non-goal 17).
pred refuseAhead[p : Purge, a : Answer] {
    p.ans = a and no intentOf[p] and no gateOf[p] and no ownOutcome[p] and no p.purged
}

-- gatePath: a strict-mode gate refusal: a purge blocked gate record carrying the retention id,
-- the record reference and the hold check result, and under-legal-hold once it landed; where
-- it is owed, recording-failure carrying gate; no intent and no call of Retention Window's
-- purge (Action wiring 52 to 54, 85, 108).
pred gatePath[p : Purge] {
    no intentOf[p] and no ownOutcome[p] and no p.purged
    p in GateOwed implies (no gateOf[p] and p.ans = ARecFailGate)
    p not in GateOwed implies {
        one gateOf[p] and p.ans = AUnderHold
        all g : gateOf[p] | g.eret = p.named and g.erec = p.named.rec
            and g.ehids = p.hids and g.ehcount = p.hcount
    }
}

-- admitPath: the hold check admitted the destruction (an empty result, or advisory mode):
-- not-eligible where the named retention is not elapsed (Action wiring 57), under-active-
-- retention where a sibling is not (Action wiring 47). Otherwise the call commits nothing where
-- the intent or the outcome is an owed record (Action wiring 83, 84, 99) or a purge of
-- Retention Window answered a refusal or no answer for the named retention or a sibling
-- (Action wiring 79, 80, 81; Execution Contract Read 4); and where it commits, the intent
-- carrying the hold check result (Action wiring 76, 83), Retention Window's purge of the
-- named retention and of every sibling (Action wiring 58, 59), and the record purged outcome
-- carrying the retention id, the record reference, the purged retention ids and the hold check
-- result, after the intent, commit together (Execution Contract Database 1; Atomic writes 5).
pred admitPath[p : Purge] {
    no gateOf[p]
    p not in NamedElapsed implies refuseAhead[p, ANotEligible]
    (p in NamedElapsed and some p.sibLate) implies refuseAhead[p, AUnderActive]
    (p in NamedElapsed and no p.sibLate) implies {
        p in IntentOwed implies refuseAhead[p, ARecFailIntent]
        p not in IntentOwed implies {
            p in PurgeRefused implies refuseAhead[p, AStorageFailure]
            p not in PurgeRefused implies {
                p in OutcomeOwed implies refuseAhead[p, ARecFailOutcome]
                p not in OutcomeOwed implies {
                    p.purged = p.named + p.sibs
                    one intentOf[p]
                    all i : intentOf[p] | i.eret = p.named and i.erec = p.named.rec
                        and i in HcrCarried and i.ehids = p.hids and i.ehcount = p.hcount
                    one ownOutcome[p] and p.ans = AOk
                    all o : ownOutcome[p] | o.ekind = KOutcome and o.eret = p.named
                        and o.erec = p.named.rec and o.epurged = p.purged
                        and o in HcrCarried and o.ehids = p.hids and o.ehcount = p.hcount
                        and (all i : intentOf[p] | lt[i.pos, o.pos])
                }
            }
        }
    }
}

-- purgeWiring: what one [Purge Record] call answers and writes: not-known for a retention id
-- the declared read does not answer, before the gate (Action wiring 45, 100); hold-check-
-- unavailable where Legal Hold refuses the gate read (Action wiring 50); the gate refusal
-- under strict mode where the read answered a hold (Action wiring 52 to 54); otherwise the
-- admitted path.
pred purgeWiring[p : Purge] {
    lone intentOf[p] and lone gateOf[p] and lone ownOutcome[p]
    resultWiring[p]
    no p.named implies refuseAhead[p, ANotKnown]
    some p.named implies {
        p in HoldRefused implies refuseAhead[p, AHoldUnavailable]
        p not in HoldRefused implies {
            (some p.saw and Instance.mode = Strict) implies gatePath[p]
            not (some p.saw and Instance.mode = Strict) implies admitPath[p]
        }
    }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Part B — [Purge Eligible] over one state
-- ─────────────────────────────────────────────────────────────────────────────

-- eligibleWiring: one tuple per elapsed retention standing retained over a record no purge
-- destroyed (Action wiring 33, 95, 101, 110), carrying the unavailable sentinel where Legal
-- Hold refused the read (Action wiring 36, 37) and otherwise the count of active holds over
-- the record (Action wiring 34, 35).
pred eligibleWiring {
    all disj t1, t2 : Tuple | t1.tret != t2.tret
    Tuple.tret = { r : Elapsed | r.rstate = Retained and r.rec not in destroyedRecords }
    all t : Tuple | t.tret.rec in PERefused implies t.tcount = 0
    all t : Tuple | t.tret.rec not in PERefused implies t.tcount = #activeOver[t.tret.rec]
}

-- built: every record in the state is what an admitted write left: each call's records by its
-- action's rules, and [Purge Eligible]'s answer.
pred built {
    all p : Placement | placementWiring[p]
    all p : HoldPlacement | holdPlacementWiring[p]
    all r : Release | releaseWiring[r]
    all p : Purge | purgeWiring[p]
    eligibleWiring
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions — the page's single-state invariants
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: under strict mode, a purge whose gate read answered a hold over the record
-- purges nothing.
assert A_Invariant_1_1 {
    built implies all p : Purge |
        (some p.saw and Instance.mode = Strict) implies no p.purged
}
check A_Invariant_1_1 for 3 but 6 Event, 4 Int

-- A_Invariant_1_2: under strict mode, a purge whose gate read answered a hold never answers ok.
assert A_Invariant_1_2 {
    built implies all p : Purge |
        (some p.saw and Instance.mode = Strict) implies p.ans != AOk
}
check A_Invariant_1_2 for 3 but 6 Event, 4 Int

-- A_Invariant_1_3: a purge whose gate read Legal Hold refused answers hold-check-unavailable
-- and purges nothing: the unreadable hold records are never read as an empty result.
assert A_Invariant_1_3 {
    built implies all p : HoldRefused |
        some p.named implies (p.ans = AHoldUnavailable and no p.purged)
}
check A_Invariant_1_3 for 3 but 6 Event, 4 Int

-- A_Invariant_1_5: under strict mode, a purge whose gate read answered a hold never answers
-- not-eligible.
assert A_Invariant_1_5 {
    built implies all p : Purge |
        (some p.saw and Instance.mode = Strict) implies p.ans != ANotEligible
}
check A_Invariant_1_5 for 3 but 6 Event, 4 Int

-- A_Invariant_1_6: under strict mode, a purge whose gate read answered a hold never answers
-- under-active-retention.
assert A_Invariant_1_6 {
    built implies all p : Purge |
        (some p.saw and Instance.mode = Strict) implies p.ans != AUnderActive
}
check A_Invariant_1_6 for 3 but 6 Event, 4 Int

-- A_Invariant_3_1: every committed hold placement within the audit horizon carries a hold
-- placed outcome naming its hold.
assert A_Invariant_3_1 {
    built implies all p : HoldPlacement & Within |
        some p.hplaced implies some o : closings[p] | o.ekind = KOutcome and o.ehold = p.hplaced
}
check A_Invariant_3_1 for 3 but 6 Event, 4 Int

-- A_Invariant_3_2: every committed hold release within the audit horizon carries a hold
-- released outcome naming its hold.
assert A_Invariant_3_2 {
    built implies all r : Release & Within |
        some r.rel implies some o : closings[r] | o.ekind = KOutcome and o.ehold = r.names
}
check A_Invariant_3_2 for 3 but 6 Event, 4 Int

-- A_Invariant_3_3: a hold placed outcome carries the hold id, the hold's record reference and
-- the placing actor Legal Hold recorded.
assert A_Invariant_3_3 {
    built implies all o : Event | (o.ekind = KOutcome and o.inv in HoldPlacement) implies
        (some o.ehold and o.erec = o.ehold.hrec and o.eactor = o.ehold.placedBy)
}
check A_Invariant_3_3 for 3 but 6 Event, 4 Int

-- A_Invariant_4_1: every committed placement within the audit horizon carries a retention
-- placed outcome naming its retention.
assert A_Invariant_4_1 {
    built implies all p : Placement & Within |
        some p.placed implies some o : closings[p] | o.ekind = KOutcome and o.eret = p.placed
}
check A_Invariant_4_1 for 3 but 6 Event, 4 Int

-- A_Invariant_4_2: every committed purge within the audit horizon carries a record purged
-- outcome naming its retention, whatever the instant of the check (Execution Contract Database 1).
assert A_Invariant_4_2 {
    built implies all p : Purge & Within |
        some p.purged implies some o : closings[p] | o.ekind = KOutcome and o.eret = p.named
}
check A_Invariant_4_2 for 3 but 6 Event, 4 Int

-- A_Invariant_4_3: every purge that answered under-legal-hold carries a gate record.
assert A_Invariant_4_3 {
    built implies all p : Purge | p.ans = AUnderHold implies some gateOf[p]
}
check A_Invariant_4_3 for 3 but 6 Event, 4 Int

-- A_Invariant_4_4: every record purged outcome carries the hold check result the purge's gate read met: its true count, and hold ids among those holds,
-- some exactly where it met some.
assert A_Invariant_4_4 {
    built implies all o : Event | (o.ekind = KOutcome and o.inv in Purge) implies
        (o in HcrCarried and o.ehcount = #(o.inv.saw) and o.ehids in o.inv.saw
         and (some o.ehids iff some o.inv.saw))
}
check A_Invariant_4_4 for 3 but 6 Event, 4 Int

-- A_Invariant_4_5: every gate record carries blocking hold ids, among the holds the gate read
-- answered, and the blocking count, the true count of those holds.
assert A_Invariant_4_5 {
    built implies all g : ekind.KGate |
        some g.ehids and g.ehids in g.inv.saw and g.ehcount = #(g.inv.saw)
}
check A_Invariant_4_5 for 3 but 6 Event, 4 Int

-- A_Invariant_4_6: no outcome stands for an invocation that recorded no intent — no refusal
-- leaves an outcome (Execution Contract Read 4).
assert A_Invariant_4_6 {
    built implies all o : ekind.KOutcome | some intentOf[o.inv]
}
check A_Invariant_4_6 for 3 but 6 Event, 4 Int

-- A_Invariant_5_1: every outcome follows, in log order, an intent carrying its invocation id.
assert A_Invariant_5_1 {
    built implies all o : ekind.KOutcome |
        some i : intentOf[o.inv] | lt[i.pos, o.pos]
}
check A_Invariant_5_1 for 3 but 6 Event, 4 Int

-- A_Invariant_5_4: no gate record follows an intent carrying its invocation id.
assert A_Invariant_5_4 {
    built implies all g : ekind.KGate | no i : intentOf[g.inv] | lt[i.pos, g.pos]
}
check A_Invariant_5_4 for 3 but 6 Event, 4 Int

-- A_Invariant_5_6: no invocation carries two outcomes.
assert A_Invariant_5_6 {
    built implies all i : Inv | lone closings[i]
}
check A_Invariant_5_6 for 3 but 6 Event, 4 Int

-- A_Invariant_7_1: where a release committed over a record, every hold over that record no
-- release named still stands active, and every tuple over the record is hold-blocked: the
-- release did not make the record purge-eligible.
assert A_Invariant_7_1 {
    built implies all r : Release, h : Hold |
        (some r.rel and h.hrec = r.names.hrec and h not in Release.names) implies
            (h.hstate = Active and all t : tuplesOver[h.hrec] | holdBlocked[t])
}
check A_Invariant_7_1 for 3 but 6 Event, 4 Int

-- A_Invariant_7_2: [Purge Eligible] answers every retention over a record carrying an active
-- hold as hold-blocked.
assert A_Invariant_7_2 {
    built implies all t : Tuple | some activeOver[t.tret.rec] implies holdBlocked[t]
}
check A_Invariant_7_2 for 3 but 6 Event, 4 Int

-- A_Invariant_7_3: [Purge Eligible] answers every retention over a record whose hold read was
-- refused as hold-blocked, never with a zero count.
assert A_Invariant_7_3 {
    built implies all t : Tuple | t.tret.rec in PERefused implies holdBlocked[t]
}
check A_Invariant_7_3 for 3 but 6 Event, 4 Int

-- A_Invariant_8_1: every destruction within the audit horizon carries a record purged outcome
-- naming the hold check result its gate read met.
assert A_Invariant_8_1 {
    built implies all p : Purge & Within |
        some p.purged implies some o : closings[p] |
            o.ekind = KOutcome and o in HcrCarried and o.ehcount = #(p.saw) and o.ehids in p.saw
}
check A_Invariant_8_1 for 3 but 6 Event, 4 Int

-- A_Invariant_9_1: a purge whose sibling set carries a retention outside elapsed retention
-- purges nothing, so destroys nothing.
assert A_Invariant_9_1 {
    built implies all p : Purge | some p.sibLate implies no p.purged
}
check A_Invariant_9_1 for 3 but 6 Event, 4 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowCleanDestruction: a strict purge over an unheld record answers ok, its record purged
-- outcome carrying an empty hold check result.
run ShowCleanDestruction {
    built and Instance.mode = Strict and some p : Purge | p.ans = AOk and no p.saw
} for 3 but 6 Event, 4 Int

-- ShowGateRefusal: a strict purge over a held record answers under-legal-hold with a gate
-- record and no intent.
run ShowGateRefusal {
    built and some p : Purge | p.ans = AUnderHold and some gateOf[p]
} for 3 but 6 Event, 4 Int

-- ShowGateOwed: the gate record is owed, and the purge answers recording-failure carrying gate.
run ShowGateOwed {
    built and some p : Purge | p.ans = ARecFailGate
} for 3 but 6 Event, 4 Int

-- ShowTruncatedGate: a gate record whose hold id list the cap truncated carries the true count.
run ShowTruncatedGate {
    built and some g : ekind.KGate | lt[#g.ehids, g.ehcount]
} for 3 but 6 Event, 4 Int

-- ShowHoldUnavailable: Legal Hold refuses the gate read; the purge answers hold-check-unavailable.
run ShowHoldUnavailable {
    built and some p : Purge | p.ans = AHoldUnavailable
} for 3 but 6 Event, 4 Int

-- ShowAdvisoryOverride: under advisory mode a purge over a held record answers ok, its outcome
-- carrying the non-empty hold check result.
run ShowAdvisoryOverride {
    built and Instance.mode = Advisory and some p : Purge | p.ans = AOk and some p.saw
} for 3 but 6 Event, 4 Int

-- ShowNotEligible: a purge naming a retention not yet elapsed answers not-eligible.
run ShowNotEligible {
    built and some p : Purge | p.ans = ANotEligible
} for 3 but 6 Event, 4 Int

-- ShowUnderActiveRetention: a sibling outside elapsed retention; the purge answers
-- under-active-retention.
run ShowUnderActiveRetention {
    built and some p : Purge | p.ans = AUnderActive
} for 3 but 6 Event, 4 Int

-- ShowRefusedPurge: a purge whose Retention Window call answered a refusal or no answer
-- commits nothing and answers storage-failure.
run ShowRefusedPurge {
    built and some p : Purge | p in PurgeRefused and p.ans = AStorageFailure and no intentOf[p]
} for 3 but 6 Event, 4 Int

-- ShowOutcomeOwed: a purge whose outcome is owed commits nothing, intent included, and answers
-- recording-failure carrying outcome.
run ShowOutcomeOwed {
    built and some p : Purge | p in OutcomeOwed and p.ans = ARecFailOutcome and no intentOf[p]
} for 3 but 6 Event, 4 Int

-- ShowPlacementsCommitted: a placement and a hold placement within the audit horizon, each
-- with its outcome.
run ShowPlacementsCommitted {
    built and some p : Placement & Within | some p.placed
    and some h : HoldPlacement & Within | some h.hplaced
} for 3 but 6 Event, 4 Int

-- ShowReleaseLeavesHold: one hold over a record released, another standing active; [Purge
-- Eligible] answers the record's retention with a count of one.
run ShowReleaseLeavesHold {
    built and some r : Release, t : Tuple | some r.rel and t.tret.rec = r.names.hrec and t.tcount = 1
} for 3 but 6 Event, 4 Int

-- ShowEligibleUnheld: [Purge Eligible] answers a retention with a zero hold count.
run ShowEligibleUnheld {
    built and some t : Tuple | t.tcount = 0
} for 3 but 6 Event, 4 Int

-- ShowSentinel: [Purge Eligible] answers a retention with the unavailable sentinel.
run ShowSentinel {
    built and some t : Tuple | no t.tcount
} for 3 but 6 Event, 4 Int
