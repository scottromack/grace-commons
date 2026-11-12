-- defensible-retention.als
-- Alloy structural model for the Defensible Retention composition (Grace Commons compositions/defensible-retention.md)
-- Grounded on Final Critique 18, 2026-11-05 at 4e61dc9 — Alloy layer authored 2026-11-12.
-- Derived validator; the English spec is the single source of truth. On any
-- disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
--
-- PURPOSE
-- Verify, by bounded exhaustive search, the STATIC data model of the composition's business
-- half: what one state of its records must satisfy — the retentions of the business retention
-- instance, the hold records, the audit records the five actions and the sweep leave (intents,
-- outcomes, gate records) — whatever the admitted writes left, what each [Purge Record] call
-- answers and writes from what its reads answered, and what [Purge Eligible] answers over one
-- state. The record section, the race of a purge against a placement, the lease arithmetic,
-- the sweep's runs and every eventuality are the TLA+ models' (defensible-retention.tla,
-- defensible-retention-outcome.tla), which own the operation sequences; the audit cascade is
-- defensible-retention-audit-hold.tla's and audit-trail.tla's.
--
-- The model has two parts.
--   Part A, the purge and the trail: each invocation is one invocation id (Capability
--   requirement 2, 63). A [Purge Record] call lands its answer and its records rule by rule
--   from what its reads answered — Retention Window's declared read of the named retention and
--   its sibling set, Legal Hold's read at the gate — which are inputs here (Action wiring 44
--   through 66, 76, 83 through 85, 100, 108). A placement, a hold placement and a hold
--   release are store-only acts whose intent, write and outcome commit together (Execution
--   Contract Database 1). The sweep closes an open marker with a recovery outcome or an intent
--   abandoned (Reconciliation 9, 11, 22, 27, 34, 38). Quiescence is a predicate the
--   at-quiescence invariants assume, never a fact.
--   Part B, [Purge Eligible] over one state: the tuples Action wiring 32 through 40, 95, 101
--   and 110 answer, each with its hold count or the unavailable sentinel.
--
-- RULES ENCODED (named by the page's own labels)
--   Invariant 1.1, 1.2, 1.5, 1.6 — under strict mode, a purge whose gate read answered a hold
--                   makes no destruction and answers neither ok, not-eligible nor
--                   under-active-retention.
--   Invariant 1.3 — a refused gate read answers hold-check-unavailable, never an empty result.
--   Invariant 3.1, 3.2 — a committed hold placement and a committed hold release within the
--                   audit horizon carry their outcome naming the hold, at quiescence.
--   Invariant 3.3 — a hold placed outcome carries the hold id, the record reference and the
--                   placing actor.
--   Invariant 4.1, 4.2 — a committed placement and a committed purge within the audit horizon
--                   carry their outcome naming the retention, at quiescence.
--   Invariant 4.3 — a purge answering under-legal-hold carries a gate record.
--   Invariant 4.4 — a record purged outcome carries the hold check result the gate read met.
--   Invariant 4.5 — a gate record carries the blocking hold ids and the blocking count.
--   Invariant 4.6 — no outcome stands for a refusal no intent preceded.
--   Invariant 5.1 — every outcome follows an intent carrying its invocation id.
--   Invariant 5.4 — no gate record follows an intent.
--   Invariant 5.6 — no invocation carries two outcomes.
--   Invariant 7.1 — a hold no release named stands active, and its record is answered
--                   hold-blocked, whatever another hold's release did.
--   Invariant 7.2 — [Purge Eligible] answers a record carrying an active hold hold-blocked.
--   Invariant 7.3 — [Purge Eligible] answers a record whose hold read was refused hold-blocked.
--   Invariant 8.1 — a surviving destruction carries a record purged outcome naming the hold
--                   check result, at quiescence.
--   Invariant 9.1 — a purge whose sibling set carries a retention outside elapsed retention
--                   destroys nothing.
--   Invariant 9.4 — a sibling a purge's read answered and that still stands retained is named
--                   pending in every record purged outcome of that purge.
-- Invariant 1.1, 5.6 and 9.1 are a cross-check with defensible-retention.tla and
-- defensible-retention-outcome.tla (Inv_Gate, Inv_OneOutcome), which check them across the
-- race; here they are checked on what one call writes.
--
-- NOT CHECKED HERE (nothing testable in Alloy)
--   Invariant 2.1 — Retention Window's own records: its place_under_retention writes the
--     retention and its retention state is one of retained, purged; the composition writes none.
--   Invariant 2.2 — the gate's input is a retention id, and a purge naming no retention answers
--     not-known before the gate read (Action wiring 45, 100): an order of reads, the TLA+'s.
--   Invariant 3.4, 3.5, 8.6, 10.3 through 10.5 — what the composition must not claim: no record.
--   Invariant 5.2 — Term open marker's own definition. 5.3 — a reader's rule.
--   Invariant 5.5 — that an invocation's intent lands once rests on the audit arms' retries
--     (Audit arm 1, 2), an order of calls. 5.7 — Term quiescence (no open marker) with 5.6.
--   Invariant 6.1, 6.2 — a post-destruction hold changing nothing: two states (Retention
--     Window's terminal absorption, Event Log's append-only); -probe-after reaches it in TLA+.
--     6.3 through 6.6 — a reader's rules on log order.
--   Invariant 8.2 — Term destroyed record's own definition. 8.3 — instants, Retention Window's
--     Invariant 8. 8.4, 8.5 — the seal and the verification, Audit Trail's.
--   Invariant 9.3 — at quiescence by Term quiescence's own definition (no pending sibling).
--     9.5 — what the gate reads, not a state.
--   Invariant 10.1, 10.2 — an order: no call before the credential validates (the substrate's).
--   Invariant 11, 12, 13 — the audit cascade: audit-trail.tla, defensible-retention-audit-hold.tla
--     and Audit Trail's Invariant 8, as the coverage matrix says.
--
-- THE PAGE RELIES ON, AND DOES NOT STATE (found by this model; recorded, not cured)
--   (a) Invariant 7.1's "purge-eligible" is no declared term. The model reads it as [Purge
--       Eligible] answering the record with a zero hold count (Term hold-blocked); the gate's
--       side is Invariant 1.1. The release's own share is Action wiring 25 (one call of Legal
--       Hold's release with the hold id) and Non-goal 26 (no hold set in one call).
--   (b) Invariant 7.3 restates Term hold-blocked (the sentinel is hold-blocked by definition);
--       its content is Action wiring 36 and 37, which the check reads as the sentinel, never a
--       zero, for a refused read.
--   (c) Invariant 4.2 and 8.1 hold at quiescence only because the purge intent carries the
--       hold check result (Action wiring 76): the sweep's recovery outcome takes it from there
--       (Reconciliation 34), and without it Reconciliation 27 closes a committed purge as intent
--       abandoned. Nothing in Invariant 4 names Action wiring 76 as what it rests on.
--
-- SCOPE
-- for 3 but 6 Event, 4 Int: three records, retentions, holds, actors, invocations and tuples;
-- six audit records; four-bit integers for log positions, counts and the hold ids cap (so a
-- cap of one truncates two holds). The hold check mode is one value for the instance
-- (Capability requirement 25). No trace, no `var`, no stepping: each purge's reads are its
-- own inputs (saw, sibs, sibLate and the flags), its writes what the rules make of them.
--
-- NOT MODELED HERE
--   - The record section, the lease readings and floors, the race of a purge against a hold
--     or sibling placement (the TLA+ models'): a purge's reads are what they answered.
--   - The refusals ahead of the gate other than not-known for an unknown retention id
--     (Action wiring 64, 65, 94), the boundary predicate, the credential and the payload caps.
--   - The hold override field, the purge instant, the indexes and the rebuild.
--   - The candidate-marker match between two markers over one record: the sweep reads its
--     marker's own act (Reconciliation 8); the stand-in is a destroyed event later in the log.
--   - Legal Hold's read order (the truncated list keeps some of the holds, not the first).
--   - The audit cascade and the audit retention instance.
--
-- HOW TO READ RESULTS
-- Every "check A_*" must return "No counterexample found" (UNSAT) — the asserted guarantee holds.
-- Every "run Show*" must return at least one instance (SAT) — confirms non-vacuity.
-- A "check" returning a counterexample is a spec finding.

module defensible_retention

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
-- the siblings outside elapsed retention; sibPend, the siblings whose purge the call leaves
-- pending (a refusal, no answer, or the sibling floor: Action wiring 68, 80, 81). What it
-- makes of them: hids and hcount, the hold check result as truncated (Primitive policy 20,
-- 21); purged, the retentions its purges purged; ans, its answer.
sig Purge extends Inv {
    named   : lone Retention,
    saw     : set Hold,
    sibs    : set Retention,
    sibLate : set Retention,
    sibPend : set Retention,
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

-- IntentOwed: the purges whose intent the substrate did not append — an input.
sig IntentOwed in Purge {}

-- PurgeRefused: the purges whose call of Retention Window's purge for the named retention
-- answered a refusal or no answer — an input.
sig PurgeRefused in Purge {}

-- OutcomeOwed: the committed purges whose own outcome the substrate did not append, or the
-- record section admitted no call of (Audit arm 13 to 22, Concurrency 34) — an input.
sig OutcomeOwed in Purge {}

-- Within: the acts that stand within the audit horizon (Term within the audit horizon) — the
-- clock's, an input.
sig Within in Inv {}

-- SweepPurged: the pending siblings the sweep's sibling-purge legs purged (Reconciliation 19).
sig SweepPurged in Retention {}

-- EKind: an audit record's kind: an intent, an outcome naming what the act did (retention
-- placed, hold placed, hold released or record purged, by the invocation's kind), an intent
-- abandoned (also an outcome: Term outcome), or a gate record (Term gate record).
abstract sig EKind {}
one sig KIntent, KOutcome, KAbandoned, KGate extends EKind {}

-- Event: one audit record on the substrate, carrying its invocation id (Action wiring 3 to 5)
-- and its log position, with the payload fields the rules write: a retention id, a record
-- reference, a hold id, an actor, a hold check result (hold ids and count) and a record purged
-- outcome's purged retention ids, each marked purged or pending.
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
    epurged  : set Retention,
    epending : set Retention
}

-- BySweep: the records the sweep wrote, a recovery outcome or an intent abandoned (the
-- recovery marker, Reconciliation 15).
sig BySweep in Event {}

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

-- closings: the outcomes (an intent abandoned included) carrying the invocation's id.
fun closings[i : Inv] : set Event { { e : Event | e.inv = i and e.ekind in KOutcome + KAbandoned } }

-- ownOutcome: the outcomes the invocation itself wrote.
fun ownOutcome[i : Inv] : set Event { closings[i] - BySweep }

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

-- Retention Window's records: a retention a purge purged stands purged, as does one the
-- sweep purged, and a retention is purged once (Retention Window Invariant 3, terminal
-- absorption: a second purge answers not-retained).
fact RetentionWindowRecords {
    all p : Purge | p.purged in rstate.Purged
    SweepPurged in rstate.Purged
    all disj p1, p2 : Purge | no p1.purged & p2.purged
    all p : Purge | no p.purged & SweepPurged
}

-- Retention Window's declared read: the sibling set answers retentions over the named
-- retention's record beside it (Composition state 19, Term sibling set); the late and the
-- pending siblings are among them.
fact RetentionWindowReads {
    all p : Purge | p.sibs in rec.(p.named.rec) - p.named
    all p : Purge | p.sibLate in p.sibs and p.sibPend in p.sibs
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
-- Part A — the writes: what each call and the sweep leave
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
-- retention where a sibling is not (Action wiring 47); otherwise the intent carrying the hold
-- check result (Action wiring 76, 83), Retention Window's purge of the named retention and of
-- each sibling not left pending (Action wiring 58, 59), and the record purged outcome
-- carrying the retention id, the record reference, the purged retention ids marked purged or
-- pending and the hold check result, after the intent (Action wiring 60 to 63, 84; Atomic
-- writes 5).
pred admitPath[p : Purge] {
    no gateOf[p]
    p not in NamedElapsed implies refuseAhead[p, ANotEligible]
    (p in NamedElapsed and some p.sibLate) implies refuseAhead[p, AUnderActive]
    (p in NamedElapsed and no p.sibLate) implies {
        p in IntentOwed implies refuseAhead[p, ARecFailIntent]
        p not in IntentOwed implies {
            one intentOf[p]
            all i : intentOf[p] | i.eret = p.named and i.erec = p.named.rec
                and i in HcrCarried and i.ehids = p.hids and i.ehcount = p.hcount
            p in PurgeRefused implies (no p.purged and no ownOutcome[p] and p.ans = AStorageFailure)
            p not in PurgeRefused implies {
                p.purged = p.named + (p.sibs - p.sibPend)
                p in OutcomeOwed implies (no ownOutcome[p] and p.ans = ARecFailOutcome)
                p not in OutcomeOwed implies {
                    one ownOutcome[p] and p.ans = AOk
                    all o : ownOutcome[p] | o.ekind = KOutcome and o.eret = p.named
                        and o.erec = p.named.rec and o.epurged = p.purged and o.epending = p.sibPend
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

-- sweepWiring: the sweep closes an open marker — an intent carrying no outcome (Reconciliation
-- 5, 22) — after it: with a recovery outcome where the act committed and the records carry
-- every datum it needs, the hold check result taken from the purge intent and the purged
-- retention ids from Retention Window's records (Reconciliation 11, 13, 34, 38); otherwise
-- as intent abandoned (Reconciliation 9, 27, 37).
pred sweepWiring[e : Event] {
    e.ekind in KOutcome + KAbandoned
    some i : intentOf[e.inv] | lt[i.pos, e.pos]
    no ownOutcome[e.inv]
    (e.inv in Purge and some e.inv.purged and intentOf[e.inv] in HcrCarried) implies {
        e.ekind = KOutcome
        e.eret = e.inv.named and e.erec = e.inv.named.rec
        e in HcrCarried and e.ehids = intentOf[e.inv].ehids and e.ehcount = intentOf[e.inv].ehcount
        e.epurged = { t : rec.(e.erec) | t.rstate = Purged }
        e.epending = { t : rec.(e.erec) | t.rstate = Retained }
    } else e.ekind = KAbandoned
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
    all t : Tuple | t.tret.rec in PERefused implies no t.tcount
    all t : Tuple | t.tret.rec not in PERefused implies t.tcount = #activeOver[t.tret.rec]
}

-- built: every record in the state is what an admitted write left: each call's records by its
-- action's rules, each sweep record by the sweep's, one sweep closing per act (Concurrency 4),
-- the sweep's sibling purges over pending siblings only (Reconciliation 19), and [Purge
-- Eligible]'s answer.
pred built {
    all p : Placement | placementWiring[p]
    all p : HoldPlacement | holdPlacementWiring[p]
    all r : Release | releaseWiring[r]
    all p : Purge | purgeWiring[p]
    BySweep in ekind.(KOutcome + KAbandoned)
    all e : BySweep | sweepWiring[e]
    all disj e1, e2 : BySweep | e1.inv != e2.inv
    SweepPurged in Purge.sibPend
    eligibleWiring
}

-- quiescent: Term quiescence as one state shows it: every intent carries an outcome or a
-- stand-in (a destroyed event later in the log, Term stand-in), and no sibling stands
-- retained over a destroyed record. An assumption of the at-quiescence invariants only.
pred quiescent {
    all i : ekind.KIntent | some closings[i.inv] or (some d : Destroyed | lt[i.pos, d.pos])
    no t : Retention | t.rstate = Retained and t.rec in destroyedRecords
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

-- A_Invariant_3_1: at quiescence, every committed hold placement within the audit horizon
-- carries a hold placed outcome naming its hold.
assert A_Invariant_3_1 {
    (built and quiescent) implies all p : HoldPlacement & Within |
        some p.hplaced implies some o : closings[p] | o.ekind = KOutcome and o.ehold = p.hplaced
}
check A_Invariant_3_1 for 3 but 6 Event, 4 Int

-- A_Invariant_3_2: at quiescence, every committed hold release within the audit horizon
-- carries a hold released outcome naming its hold.
assert A_Invariant_3_2 {
    (built and quiescent) implies all r : Release & Within |
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

-- A_Invariant_4_1: at quiescence, every committed placement within the audit horizon carries a
-- retention placed outcome naming its retention.
assert A_Invariant_4_1 {
    (built and quiescent) implies all p : Placement & Within |
        some p.placed implies some o : closings[p] | o.ekind = KOutcome and o.eret = p.placed
}
check A_Invariant_4_1 for 3 but 6 Event, 4 Int

-- A_Invariant_4_2: at quiescence, every committed purge within the audit horizon carries a
-- record purged outcome naming its retention.
assert A_Invariant_4_2 {
    (built and quiescent) implies all p : Purge & Within |
        some p.purged implies some o : closings[p] | o.ekind = KOutcome and o.eret = p.named
}
check A_Invariant_4_2 for 3 but 6 Event, 4 Int

-- A_Invariant_4_3: every purge that answered under-legal-hold carries a gate record.
assert A_Invariant_4_3 {
    built implies all p : Purge | p.ans = AUnderHold implies some gateOf[p]
}
check A_Invariant_4_3 for 3 but 6 Event, 4 Int

-- A_Invariant_4_4: every record purged outcome, the invocation's or the sweep's, carries the
-- hold check result the purge's gate read met: its true count, and hold ids among those holds,
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
-- ahead of the intent leaves an outcome.
assert A_Invariant_4_6 {
    built implies all o : ekind.(KOutcome + KAbandoned) | some intentOf[o.inv]
}
check A_Invariant_4_6 for 3 but 6 Event, 4 Int

-- A_Invariant_5_1: every outcome follows, in log order, an intent carrying its invocation id.
assert A_Invariant_5_1 {
    built implies all o : ekind.(KOutcome + KAbandoned) |
        some i : intentOf[o.inv] | lt[i.pos, o.pos]
}
check A_Invariant_5_1 for 3 but 6 Event, 4 Int

-- A_Invariant_5_4: no gate record follows an intent carrying its invocation id.
assert A_Invariant_5_4 {
    built implies all g : ekind.KGate | no i : intentOf[g.inv] | lt[i.pos, g.pos]
}
check A_Invariant_5_4 for 3 but 6 Event, 4 Int

-- A_Invariant_5_6: no invocation carries two outcomes, its own and the sweep's together.
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

-- A_Invariant_8_1: at quiescence, every destruction within the audit horizon carries a record
-- purged outcome naming the hold check result its gate read met.
assert A_Invariant_8_1 {
    (built and quiescent) implies all p : Purge & Within |
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

-- A_Invariant_9_4: every record purged outcome names pending each sibling its purge's read
-- answered that still stands retained.
assert A_Invariant_9_4 {
    built implies all o : Event | (o.ekind = KOutcome and o.inv in Purge) implies
        (all s : o.inv.sibs | s.rstate = Retained implies s in o.epending)
}
check A_Invariant_9_4 for 3 but 6 Event, 4 Int

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

-- ShowPendingSibling: a destruction whose outcome names a sibling pending.
run ShowPendingSibling {
    built and some o : ekind.KOutcome | some o.epending
} for 3 but 6 Event, 4 Int

-- ShowRecoveredPurge: a committed purge whose own outcome was owed, recovered by the sweep at
-- quiescence within the audit horizon.
run ShowRecoveredPurge {
    built and quiescent and some p : Purge & Within |
        p in OutcomeOwed and some o : closings[p] & BySweep | o.ekind = KOutcome
} for 3 but 6 Event, 4 Int

-- ShowAbandonedPurge: a purge whose Retention Window call was refused after its intent, closed
-- by the sweep as intent abandoned.
run ShowAbandonedPurge {
    built and some p : Purge | p in PurgeRefused and some o : closings[p] | o.ekind = KAbandoned
} for 3 but 6 Event, 4 Int

-- ShowStandIn: quiescence reached by an intent with no outcome and a destroyed event later in
-- the log.
run ShowStandIn {
    built and quiescent and some i : ekind.KIntent | no closings[i.inv]
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
