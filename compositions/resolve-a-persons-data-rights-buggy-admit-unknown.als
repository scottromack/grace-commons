-- resolve-a-persons-data-rights-buggy-admit-unknown.als
-- DELIBERATELY WRONG twin of resolve-a-persons-data-rights.als (unit: compositions/resolve-a-persons-data-rights.md formal layer).
--
-- INJECTED DEFECT: a fulfillment is admitted without the request index's answer: a request id no intake event carries is fulfilled (Action wiring 4).
--
-- BREAKS: A_Invariant_1_3.
-- Everything else is resolve-a-persons-data-rights.als as written; read its comments there.

module resolve_a_persons_data_rights_buggy_admit_unknown

open util/integer

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Subject: a subject reference, the data subject whose records are the universe.
sig Subject {}

-- RType: the right type, access or erasure (Term right type).
abstract sig RType {}
one sig Access, Erasure extends RType {}

-- Request: a request id the host minted at [Receive Request]'s seam, naming no other request
-- (Capability requirement 22), with the subject reference and the right type its intake event
-- carries.
sig Request {
    subj  : one Subject,
    rtype : one RType
}

-- Ref: a datum a disposition's reason can carry as its authority: a source text or a
-- reference (Auth), or a retention id (Retention).
abstract sig Ref {}

-- Auth: a source text or a reference — a determination's reference, a ground or a purpose, a
-- host's basis, an attestation reference or a hold id (Term source text).
sig Auth extends Ref {}

-- Retention: a retention id of the business retention instance (Term retention id).
sig Retention extends Ref {}

-- Record: a registered record of the record source registry, with what its source answers:
-- the subject it belongs to; its route, a retention id or (none) the host delete (Capability
-- requirement 5); the host determination's reference (Capability requirement 4); its declared
-- basis's ground or purpose (Capability requirement 3); and what the host delete's deleted and
-- retained arms carry (Term host delete).
sig Record {
    owner     : one Subject,
    rid       : lone Retention,
    detRef    : lone Auth,
    ground    : lone Auth,
    hostBasis : lone Auth,
    attest    : lone Auth
}

-- Det: a record's determination reading (Term determination reading).
abstract sig Det {}
one sig DFailed, DThirdParty, DLegalEx, DNoBar extends Det {}

-- Basis: a record's basis reading (Term basis reading).
abstract sig Basis {}
one sig BUnread, BGround, BGranted, BNotKnown, BWithdrawn, BNone extends Basis {}

-- RRead: a record's retention reading (Term retention reading).
abstract sig RRead {}
one sig RUnread, RClear, RAbsent, RMisPaired, RPurged, RRetained extends RRead {}

-- PRead: a purge plan pair's purge reading (Term purge reading).
abstract sig PRead {}
one sig PDestroyed, PGone, PUnsettled, PHeld, PObliged, PUnknown extends PRead {}

-- HAns: the host delete's answer, as the dispositions read it: deleted, retained carrying a
-- basis, not-known, delete-failed or invalid-credential, and an answer outside the host
-- delete's contract (Disposition 32 through 36).
abstract sig HAns {}
one sig HDeleted, HRetained, HNotKnown, HFailed, HOutside extends HAns {}

-- DAns: the disclosure write's answer: the response disclosure id, a refused disclosure write,
-- or no answer (Term refused disclosure write, Term possibly committed act).
abstract sig DAns {}
one sig DOk, DRefused, DNoAnswer extends DAns {}

-- COp: Consent's four operations (Consent's Operations): grant and revoke write, check and
-- read do not.
abstract sig COp {}
one sig CGrant, CRevoke, CCheck, CRead extends COp {}

-- Verdict: a disposition's verdict (Term verdict), and Planned, the provisional marker an
-- intent carries for a planned record — no verdict (Term planned).
abstract sig Verdict {}
one sig VIncluded, VWithheld, VErased, VRetained, VAnomaly, Planned extends Verdict {}

-- Why: what a disposition's reason says it rests on, one value per arm of Disposition 1
-- through 48 (WDestroyed for every erased arm, WPlanned for the provisional marker).
abstract sig Why {}
one sig WNoBar, WThirdParty, WLegalEx, WDetUnavailable, WOtherBasis, WConsentNotKnown,
        WMisPaired, WUnknownRet, WLegalHold, WRetObligation, WHostNotFound, WUnsettled,
        WDestroyed, WPlanned extends Why {}

-- Inv: an invocation or a leg, with the instant at which it reads the request's state.
abstract sig Inv {
    at : one Int
}

-- Ful: a fulfillment — a [Fulfill Access Request] or [Fulfill Erasure Request] call — named
-- by its invocation id (Capability requirement 25). Its inputs: the request id it names, the
-- sibling called (act), what the enumeration answered (seen), and per record what its reads
-- answered (det, basis, rread); what its planned calls answered (pread, hans, and the hold ids
-- a held purge answered); what its disclosure write answered (dans). What it makes of them:
-- the Consent operations it called (cops), and the records below.
sig Ful extends Inv {
    req   : one Request,
    act   : one RType,
    seen  : set Record,
    det   : Record -> lone Det,
    basis : Record -> lone Basis,
    rread : Record -> lone RRead,
    pread : Record -> lone PRead,
    hans  : Record -> lone HAns,
    holds : Record -> set Auth,
    dans  : lone DAns,
    cops  : set COp
}

-- EnumFailed: the fulfillments a registered source failed or answered nothing to, or whose
-- disclosure read or Consent read failed (Action wiring 12, 37) — an input.
sig EnumFailed in Ful {}

-- IntentOwed: the fulfillments whose intent Audit Trail refused or did not answer (Audit arm
-- 6, 7, 20) — an input.
sig IntentOwed in Ful {}

-- Yielded: the intended fulfillments whose grant admitted no disclosure write (Term yielded
-- fulfillment) — an input.
sig Yielded in Ful {}

-- DLanded: the fulfillments whose disclosure write answered no answer and landed — an input.
sig DLanded in Ful {}

-- EvOwed: the fulfillments whose fulfilled event did not land — an input.
sig EvOwed in Ful {}

-- Leg: one leg of the reconciliation, over the open intent of the fulfillment lof (Term leg).
-- Its inputs: the planned records whose retention reading it took answered purged (lpurged,
-- Reconciliation 9, 24) and what its disclosure write answered (ldans).
sig Leg extends Inv {
    lof     : one Ful,
    lpurged : set Record,
    ldans   : lone DAns
}

-- RecOwed: the legs whose first write (the recovery intent, or the abandonment) did not land,
-- left to the next run (Reconciliation 28) — an input.
sig RecOwed in Leg {}

-- LEvOwed: the legs whose compensating fulfilled event did not land — an input.
sig LEvOwed in Leg {}

-- LDLanded: the legs whose disclosure write answered no answer and landed — an input.
sig LDLanded in Leg {}

-- EKind: an audit event's kind: the intake event, an intent, a fulfilled event, an
-- abandonment, a recovery intent (Term records).
abstract sig EKind {}
one sig KIntake, KIntent, KFulfilled, KAbandon, KRecovery extends EKind {}

-- Event: one event the composition records through the audit write, carrying its request id
-- and, past the intake, the invocation id of the fulfillment whose intent it opens or closes
-- (Term invocation id); wleg is the leg that wrote it, none where the invocation itself did.
-- An intent and a fulfilled event carry the dispositions, as a verdict, a reason and the
-- reason's authority per record; a fulfilled event carries its response disclosure id and the
-- instant of its fulfillment entry, where one was written.
sig Event {
    ekind : one EKind,
    ereq  : one Request,
    einv  : lone Ful,
    wleg  : lone Leg,
    pos   : one Int,
    dv    : Record -> lone Verdict,
    dwhy  : Record -> lone Why,
    dauth : Record -> set Ref,
    rdisc : lone Disclosure,
    entry : lone Int
}

-- Flagged: the fulfilled events carrying the compensation flag (Term compensation flag).
sig Flagged in Event {}

-- Disclosure: a Selective Disclosure record whose scope carries a request id (Term request
-- scope), written by the invocation or the leg dby; every one is the composition's (Capability
-- requirement 41).
sig Disclosure {
    dreq : one Request,
    dpos : one Int,
    dby  : one Inv
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- ownOf: the events a fulfillment wrote itself.
fun ownOf[f : Ful] : set Event { { e : Event | e.einv = f and no e.wleg } }

-- legOf: the events a leg wrote.
fun legOf[l : Leg] : set Event { wleg.l }

-- intentOf: the intent carrying the fulfillment's invocation id.
fun intentOf[f : Ful] : set Event { { e : Event | e.einv = f and e.ekind = KIntent } }

-- closingsOf: the closing records carrying the fulfillment's invocation id — a fulfilled event
-- or an abandonment (Term closing record).
fun closingsOf[f : Ful] : set Event { { e : Event | e.einv = f and e.ekind in KFulfilled + KAbandon } }

-- intakeOf, intentsOf, fulfilledOf: a request's intake event, intents and fulfilled events.
fun intakeOf[q : Request] : set Event { { e : Event | e.ereq = q and e.ekind = KIntake } }
fun intentsOf[q : Request] : set Event { { e : Event | e.ereq = q and e.ekind = KIntent } }
fun fulfilledOf[q : Request] : set Event { { e : Event | e.ereq = q and e.ekind = KFulfilled } }

-- discOf: the request-scoped disclosures carrying the request id; discBy: those an invocation
-- or a leg wrote.
fun discOf[q : Request] : set Disclosure { dreq.q }
fun discBy[i : Inv] : set Disclosure { dby.i }

-- reqOf: the request a fulfillment names, or a leg's intent carries.
fun reqOf[i : Inv] : set Request { i.req + i.lof.req }

-- wposOf: the instants of an invocation's or a leg's own writes, events and disclosures.
fun wposOf[i : Inv] : set Int {
    { e : Event | (e.einv = i and no e.wleg) or e.wleg = i }.pos + discBy[i].dpos
}

-- startOf: where an invocation's hold of the request section starts — at its state read
-- (Concurrency 7: no read of the request's state before the take).
fun startOf[i : Inv] : Int { i.at }

-- sources: every datum a record's sources and the calls over it answered: what a reason can
-- name as a recoverable authority (Check 4.1).
fun sources[r : Record] : set Ref {
    r.detRef + r.ground + r.hostBasis + r.attest + r.rid + r.(Ful.holds)
}

-- The request's state at an instant p, read off the records written before p (Composition
-- state 15 through 19 and 24; Term request state).
-- fulfilledAt: a fulfilled event or a fulfillment entry stands before p.
pred fulfilledAt[q : Request, p : Int] {
    some e : fulfilledOf[q] | lt[e.pos, p] or (some e.entry and lt[e.entry, p])
}

-- openIntentAt: an intent of the request stands before p with no closing record before p, on
-- a request not Fulfilled (Term open intent).
pred openIntentAt[q : Request, p : Int] {
    not fulfilledAt[q, p]
    some i : intentsOf[q] | lt[i.pos, p] and (no c : closingsOf[i.einv] | lt[c.pos, p])
}

-- unboundAt: a request-scoped disclosure stands before p on a request not Fulfilled (Term
-- unbound disclosure).
pred unboundAt[q : Request, p : Int] {
    not fulfilledAt[q, p]
    some d : discOf[q] | lt[d.dpos, p]
}

-- receivedAt: the request's intake event stands before p (the request is known).
pred receivedAt[q : Request, p : Int] {
    some e : intakeOf[q] | lt[e.pos, p]
}

-- admitted: Action wiring 4 through 9 refuse nothing: the request is known, neither Fulfilled
-- nor Committing at the read, and the sibling called matches its right type (Term admitted
-- fulfillment).
pred admitted[f : Ful] {
    not fulfilledAt[f.req, f.at]
    not openIntentAt[f.req, f.at]
    not unboundAt[f.req, f.at]
    f.act = f.req.rtype
}

-- due: an erasure-due record — its basis reading withdrawn or none (Term erasure-due record).
pred due[f : Ful, r : Record] { some f.basis[r] & (BWithdrawn + BNone) }

-- planP: the purge plan — erasure-due records whose route carries a retention id and whose
-- retention reading is retained (Disposition 17).
fun planP[f : Ful] : set Record {
    { r : f.seen | f.act = Erasure and due[f, r] and some r.rid and f.rread[r] = RRetained }
}

-- planH: the host delete plan — erasure-due host-managed records whose retention reading is
-- clear (Disposition 18).
fun planH[f : Ful] : set Record {
    { r : f.seen | f.act = Erasure and due[f, r] and no r.rid and f.rread[r] = RClear }
}

-- retUnread: an erasure's retention read gave no answer for an erasure-due record (Action
-- wiring 38: incomplete-enumeration).
pred retUnread[f : Ful] {
    f.act = Erasure and (some r : f.seen | due[f, r] and f.rread[r] = RUnread)
}

-- go: an enumerated fulfillment (Term enumerated fulfillment).
pred go[f : Ful] { admitted[f] and f not in EnumFailed and not retUnread[f] }

-- landed: an intended fulfillment — its intent landed (Term intended fulfillment).
pred landed[f : Ful] { go[f] and f not in IntentOwed }

-- provV, provW, provA: the provisional disposition of an enumerated record — the access arms
-- (Disposition 3 through 6) and the erasure arms resolved before any planned call
-- (Disposition 7, 10, 11, 14, 15, 19, 39, 40).
fun provV[f : Ful, r : Record] : Verdict {
    f.act = Access =>
        (some f.det[r] & (DThirdParty + DLegalEx) => VWithheld
         else (f.det[r] = DFailed => VAnomaly else VIncluded))
    else (some f.basis[r] & (BGround + BGranted) => VRetained
    else (some f.basis[r] & (BUnread + BNotKnown) => VAnomaly
    else (some f.rread[r] & (RMisPaired + RAbsent) => VAnomaly
    else (f.rread[r] = RPurged => VErased
    else Planned))))
}

fun provW[f : Ful, r : Record] : Why {
    f.act = Access =>
        (f.det[r] = DThirdParty => WThirdParty
         else (f.det[r] = DLegalEx => WLegalEx
         else (f.det[r] = DFailed => WDetUnavailable else WNoBar)))
    else (some f.basis[r] & (BGround + BGranted) => WOtherBasis
    else (f.basis[r] = BUnread => WDetUnavailable
    else (f.basis[r] = BNotKnown => WConsentNotKnown
    else (f.rread[r] = RMisPaired => WMisPaired
    else (f.rread[r] = RAbsent => WUnknownRet
    else (f.rread[r] = RPurged => WDestroyed
    else WPlanned))))))
}

fun provA[f : Ful, r : Record] : set Ref {
    f.act = Access =>
        (some f.det[r] & (DThirdParty + DLegalEx) => r.detRef else none)
    else (some f.basis[r] & (BGround + BGranted) => r.ground
    else (f.rread[r] = RPurged => r.rid else none))
}

-- setV, setW, setA: the sealed disposition — a planned record settled from its planned call's
-- answer (Disposition 20 through 22, 32 through 36, 42 through 45), every other record as the
-- intent carries it.
fun setV[f : Ful, r : Record] : Verdict {
    r in planP[f] =>
        (no f.pread[r] => VAnomaly
         else (some f.pread[r] & (PDestroyed + PGone) => VErased
         else (some f.pread[r] & (PHeld + PObliged) => VRetained
         else VAnomaly)))
    else (r in planH[f] =>
        (f.hans[r] = HDeleted => VErased
         else (f.hans[r] = HRetained => VRetained else VAnomaly))
    else provV[f, r])
}

fun setW[f : Ful, r : Record] : Why {
    r in planP[f] =>
        (no f.pread[r] => WUnsettled
         else (some f.pread[r] & (PDestroyed + PGone) => WDestroyed
         else (f.pread[r] = PHeld => WLegalHold
         else (f.pread[r] = PObliged => WRetObligation
         else (f.pread[r] = PUnknown => WUnknownRet
         else WUnsettled)))))
    else (r in planH[f] =>
        (f.hans[r] = HDeleted => WDestroyed
         else (f.hans[r] = HRetained => WOtherBasis
         else (f.hans[r] = HNotKnown => WHostNotFound else WUnsettled)))
    else provW[f, r])
}

fun setA[f : Ful, r : Record] : set Ref {
    r in planP[f] =>
        (some f.pread[r] & (PDestroyed + PGone + PObliged) => r.rid
         else (f.pread[r] = PHeld => f.holds[r] else none))
    else (r in planH[f] =>
        (f.hans[r] = HDeleted => r.attest
         else (f.hans[r] = HRetained => r.hostBasis else none))
    else provA[f, r])
}

-- possiblyDestroyed: the planned records whose sealed disposition carries erased or unsettled
-- (Term possibly destroyed record).
fun possiblyDestroyed[f : Ful] : set Record {
    { r : planP[f] + planH[f] | setV[f, r] = VErased or setW[f, r] = WUnsettled }
}

-- openAt: the fulfillment's intent stands open at p: no closing record of it before p, on a
-- request not Fulfilled.
pred openAt[f : Ful, p : Int] {
    not fulfilledAt[f.req, p]
    no c : closingsOf[f] | lt[c.pos, p]
}

-- evidence: destruction evidence for a record (Term destruction evidence): for a record whose
-- route carries a retention id, a purge that answered ok or recording-failure carrying outcome
-- (destroyed), a not-known borne out by a purged reading (gone), or a retention reading that
-- answered purged; for a host-managed record, a host delete that answered deleted.
pred evidence[r : Record] {
    some r.rid implies
        ((some f : Ful | some f.pread[r] & (PDestroyed + PGone) or f.rread[r] = RPurged)
         or (some l : Leg | r in l.lpurged))
    no r.rid implies (some f : Ful | f.hans[r] = HDeleted)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- One real-time order: every write lands at its own instant, and every invocation and leg
-- reads at an instant no write takes.
fact Clock {
    all disj e1, e2 : Event | e1.pos != e2.pos
    all disj d1, d2 : Disclosure | d1.dpos != d2.dpos
    all disj i1, i2 : Inv | i1.at != i2.at
    all disj e1, e2 : Event | (some e1.entry and some e2.entry) implies e1.entry != e2.entry
    no Event.pos & Disclosure.dpos
    no (Event.pos + Disclosure.dpos) & Inv.at
    no Event.entry & (Event.pos + Disclosure.dpos + Inv.at)
}

-- The registry and the sources: an enumeration answers records of the request's subject, and
-- one that answered every registered source answers every registered record of the subject
-- (Capability requirement 1, 2; Completeness boundary 1). Each enumerated record carries one
-- reading of each kind, as the Terms classify the sources' and Retention Window's answers: a
-- host-managed record reads unread, clear or mis-paired, a record carrying a retention id never
-- clear (Term retention reading); a bar reading carries the determination's reference (Term
-- determination reading); a ground or a granted consent carries its text (Term basis reading).
fact Sources {
    all f : Ful | f.seen in owner.(f.req.subj)
    all f : Ful - EnumFailed | f.seen = owner.(f.req.subj)
    all f : Ful | f.det.Det = f.seen and f.basis.Basis = f.seen and f.rread.RRead = f.seen
    all f : Ful, r : f.seen | no r.rid implies f.rread[r] in RUnread + RClear + RMisPaired
    all f : Ful, r : f.seen | some r.rid implies f.rread[r] in RUnread + RAbsent + RMisPaired + RPurged + RRetained
    all f : Ful, r : f.seen | some f.det[r] & (DThirdParty + DLegalEx) implies some r.detRef
    all f : Ful, r : f.seen | some f.basis[r] & (BGround + BGranted) implies some r.ground
}

-- The called surfaces: Defensible Retention's under-legal-hold carries the blocking hold ids
-- (Defensible Retention Invariant 4.5), and only it; the host delete's deleted arm carries an
-- attestation reference and its retained arm a basis, an arm with neither being outside its
-- contract (Term outside the host delete's contract).
fact Surfaces {
    all f : Ful, r : Record | some f.holds[r] iff f.pread[r] = PHeld
    all f : Ful, r : Record | f.hans[r] = HDeleted implies some r.attest
    all f : Ful, r : Record | f.hans[r] = HRetained implies some r.hostBasis
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writes: what each fulfillment and each leg leaves
-- ─────────────────────────────────────────────────────────────────────────────

-- provisional: an intent carries the provisional disposition of every enumerated record and
-- no other (Action wiring 16, 24; Disposition 1, 2).
pred provisional[i : Event, f : Ful] {
    i.dv.Verdict in f.seen and i.dwhy.Why in f.seen and i.dauth.Ref in f.seen
    all r : f.seen | i.dv[r] = provV[f, r] and i.dwhy[r] = provW[f, r] and i.dauth[r] = provA[f, r]
}

-- sealed: a fulfillment's own fulfilled event carries the sealed disposition of every
-- enumerated record and no other (Action wiring 22, 27, 31; Snapshot 1).
pred sealed[e : Event, f : Ful] {
    e.dv.Verdict in f.seen and e.dwhy.Why in f.seen and e.dauth.Ref in f.seen
    all r : f.seen | e.dv[r] = setV[f, r] and e.dwhy[r] = setW[f, r] and e.dauth[r] = setA[f, r]
}

-- consentWiring: an enumerated access reads Consent's read (Action wiring 15); an enumerated
-- erasure calls Consent's check for a record whose declared basis names consent (Disposition 9).
pred consentWiring[f : Ful] {
    f.cops = (go[f] and f.act = Access => CRead else none)
           + ((go[f] and f.act = Erasure and (some r : f.seen | some f.basis[r] & (BGranted + BNotKnown + BWithdrawn))) => CCheck else none)
}

-- fulWiring: what one fulfillment writes. A refusal ahead of the intent writes nothing (Action
-- wiring 10, 13; Primitive policy 6); an enumerated fulfillment records its intent, or answers
-- recording-failure carrying intent (Audit arm 7); an intended erasure makes its planned calls
-- (Action wiring 23, 25, 26); an intended fulfillment the grant still admits calls the
-- disclosure write (Action wiring 17, 18, 28); a disclosed one records the fulfilled event naming
-- the disclosure (Action wiring 22, 31); a refused disclosure write with no possibly destroyed
-- record records an abandonment (Action wiring 19), and one that answered no answer none
-- (Action wiring 39).
pred fulWiring[f : Ful] {
    lone ownOf[f] & ekind.KIntent
    lone ownOf[f] & ekind.KFulfilled
    lone ownOf[f] & ekind.KAbandon
    no ownOf[f] & ekind.(KIntake + KRecovery)
    lone discBy[f]
    all x : wposOf[f] | lt[f.at, x]
    consentWiring[f]
    not go[f] implies (no ownOf[f] and no discBy[f] and no f.pread and no f.hans and no f.dans)
    some (ownOf[f] & ekind.KIntent) iff landed[f]
    all i : intentOf[f] | provisional[i, f]
    (some f.pread or some f.hans) implies landed[f]
    f.pread.PRead in planP[f]
    f.hans.HAns in planH[f]
    some f.dans iff (landed[f] and f not in Yielded)
    some discBy[f] iff (f.dans = DOk or (f.dans = DNoAnswer and f in DLanded))
    all d : discBy[f] | d.dreq = f.req and (all i : intentOf[f] | lt[i.pos, d.dpos])
    some (ownOf[f] & ekind.KFulfilled) iff (f.dans = DOk and f not in EvOwed)
    all e : ownOf[f] & ekind.KFulfilled |
        one e.rdisc and e.rdisc = discBy[f] and lt[discBy[f].dpos, e.pos] and sealed[e, f]
    some (ownOf[f] & ekind.KAbandon) iff (f.dans = DRefused and no possiblyDestroyed[f])
    all a : ownOf[f] & ekind.KAbandon, i : intentOf[f] | lt[i.pos, a.pos]
}

-- compSet: a compensating fulfilled event's dispositions, from the intent's own fields: every
-- record outside the plans as the intent carries it (Reconciliation 16); a planned record whose
-- retention reading the leg took answered purged, erased carrying the retention id
-- (Reconciliation 24); every other planned record, anomaly carrying unsettled (Reconciliation 14).
pred compSet[e : Event, i : Event, l : Leg] {
    e.dv.Verdict in i.dv.Verdict and e.dwhy.Why in i.dv.Verdict and e.dauth.Ref in i.dv.Verdict
    all r : i.dv.Verdict - i.dv.Planned | e.dv[r] = i.dv[r] and e.dwhy[r] = i.dwhy[r] and e.dauth[r] = i.dauth[r]
    all r : i.dv.Planned | r in l.lpurged =>
        (e.dv[r] = VErased and e.dwhy[r] = WDestroyed and e.dauth[r] = r.rid)
        else (e.dv[r] = VAnomaly and e.dwhy[r] = WUnsettled and no e.dauth[r])
}

-- compensate: a request-scoped disclosure carries the intent's request id: the recovery intent,
-- then the fulfilled event the intent's fulfillment owed, naming that disclosure (Reconciliation
-- 10, 12, 31); no disclosure of the leg's own.
pred compensate[l : Leg, i : Event, rd : set Disclosure] {
    no discBy[l]
    no legOf[l] & ekind.KAbandon
    some (legOf[l] & ekind.KRecovery) iff l not in RecOwed
    some (legOf[l] & ekind.KFulfilled) iff (l not in RecOwed and l not in LEvOwed)
    all r : legOf[l] & ekind.KRecovery, e : legOf[l] & ekind.KFulfilled | lt[r.pos, e.pos]
    all e : legOf[l] & ekind.KFulfilled | one e.rdisc and e.rdisc in rd and compSet[e, i, l]
}

-- complete: no request-scoped disclosure and a planned record: the recovery intent, the
-- disclosure write (Reconciliation 13, 29), then, once it answered the id, the fulfilled event
-- naming it.
pred complete[l : Leg, i : Event] {
    no legOf[l] & ekind.KAbandon
    some (legOf[l] & ekind.KRecovery) iff l not in RecOwed
    some l.ldans iff l not in RecOwed
    some discBy[l] iff (l.ldans = DOk or (l.ldans = DNoAnswer and l in LDLanded))
    all d : discBy[l] | d.dreq = l.lof.req and (all r : legOf[l] & ekind.KRecovery | lt[r.pos, d.dpos])
    some (legOf[l] & ekind.KFulfilled) iff (l.ldans = DOk and l not in LEvOwed)
    all e : legOf[l] & ekind.KFulfilled |
        one e.rdisc and e.rdisc = discBy[l] and lt[discBy[l].dpos, e.pos] and compSet[e, i, l]
}

-- abandonLeg: no request-scoped disclosure and no planned record: an abandonment carrying the
-- intent's invocation id, and nothing else (Reconciliation 15).
pred abandonLeg[l : Leg] {
    no discBy[l]
    no legOf[l] & ekind.(KRecovery + KFulfilled)
    some (legOf[l] & ekind.KAbandon) iff l not in RecOwed
}

-- legWiring: a leg works the intent of one fulfillment, after it, under the section: it reads
-- the request's events and the disclosure read again (Reconciliation 17, 23) and works the
-- intent only while it stands open; it pairs a request-scoped disclosure to it (Reconciliation 8)
-- and closes it by Reconciliation 12, 13 or 15; its records carry the intent's invocation id
-- (Term invocation id).
pred legWiring[l : Leg] {
    one intentOf[l.lof]
    all i : intentOf[l.lof] | lt[i.pos, l.at]
    openAt[l.lof, l.at]
    all e : legOf[l] | e.einv = l.lof
    no legOf[l] & ekind.(KIntake + KIntent)
    all x : wposOf[l] | lt[l.at, x]
    lone legOf[l] & ekind.KRecovery
    lone legOf[l] & ekind.KFulfilled
    lone legOf[l] & ekind.KAbandon
    lone discBy[l]
    all i : intentOf[l.lof] {
        l.lpurged in i.dv.Planned & rid.Retention
        let rd = { d : discOf[l.lof.req] | lt[d.dpos, l.at] } {
            some rd implies compensate[l, i, rd]
            (no rd and some i.dv.Planned) implies complete[l, i]
            (no rd and no i.dv.Planned) implies abandonLeg[l]
        }
    }
}

-- section: the request section (Concurrency 1, 7; Reconciliation 17): two holders over one
-- request never overlap — each one's span runs from its take, ahead of its state read, to its
-- last write, and every write of the earlier holder lands before the later one takes.
pred section {
    all disj a, b : Inv | (reqOf[a] = reqOf[b] and some wposOf[a] and some wposOf[b]) implies {
        lt[startOf[a], startOf[b]] implies (all x : wposOf[a] | lt[x, startOf[b]])
        lt[startOf[b], startOf[a]] implies (all x : wposOf[b] | lt[x, startOf[a]])
    }
}

-- built: every record in the state is what an admitted write left: one intake event per
-- request id carrying no fulfillment (Action wiring 1 through 3); every other event a
-- fulfillment's or a leg's, by their rules; the dispositions only on intents and fulfilled
-- events, the disclosure id and the entry only on fulfilled events, the entry after its event
-- (Composition state 9, Reconciliation 18, 25); the compensation flag exactly on a leg's
-- fulfilled event (Reconciliation 12); the request section over all.
pred built {
    all f : Ful | fulWiring[f]
    all l : Leg | legWiring[l]
    all q : Request | lone intakeOf[q]
    all e : ekind.KIntake | no e.einv and no e.wleg
    all e : Event - ekind.KIntake | some e.einv and e.ereq = e.einv.req
    all e : Event - ekind.(KIntent + KFulfilled) | no e.dv and no e.dwhy and no e.dauth
    all e : Event - ekind.KFulfilled | no e.rdisc and no e.entry
    all e : Event | some e.entry implies lt[e.pos, e.entry]
    Flagged = ekind.KFulfilled & wleg.Leg
    section
}

-- quiescent: Term quiescence as one state shows it — no intent stands open. An assumption of
-- Invariant 1.5's lower bound only.
pred quiescent {
    all i : ekind.KIntent | some closingsOf[i.einv]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions — the page's single-state invariants
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: every fulfilled event names a response disclosure carrying its request id,
-- written before it, and carries a verdict — no planned marker — for every enumerated record.
assert A_Invariant_1_1 {
    built implies all e : ekind.KFulfilled |
        some e.rdisc and e.rdisc.dreq = e.ereq and lt[e.rdisc.dpos, e.pos]
        and (all r : e.einv.seen | some e.dv[r] - Planned)
}
check A_Invariant_1_1 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_1_2: every Fulfilled request carries exactly one fulfilled event.
assert A_Invariant_1_2 {
    built implies all q : Request | some fulfilledOf[q] implies one fulfilledOf[q]
}
check A_Invariant_1_2 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_1_3: every fulfilled event names a request — a request id an intake event carries.
assert A_Invariant_1_3 {
    built implies all e : ekind.KFulfilled | one intakeOf[e.ereq]
}
check A_Invariant_1_3 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_1_4: every binding orphan — a request-scoped disclosure no fulfilled event names —
-- stands under an open intent of its request.
assert A_Invariant_1_4 {
    built implies all d : Disclosure | no rdisc.d implies
        (no fulfilledOf[d.dreq] and some i : intentsOf[d.dreq] | no closingsOf[i.einv])
}
check A_Invariant_1_4 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_1_5: every intent carries at most one closing record, and at quiescence exactly one.
assert A_Invariant_1_5 {
    built implies all i : ekind.KIntent | lone closingsOf[i.einv]
    (built and quiescent) implies all i : ekind.KIntent | one closingsOf[i.einv]
}
check A_Invariant_1_5 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_1_6: every fulfilled event the reconciliation recorded carries the compensation flag.
assert A_Invariant_1_6 {
    built implies all e : ekind.KFulfilled | some e.wleg implies e in Flagged
}
check A_Invariant_1_6 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_2_1: every fulfilled event carries exactly one disposition per record of the
-- enumerated universe, and none for a record outside it.
assert A_Invariant_2_1 {
    built implies all e : ekind.KFulfilled |
        e.dv.Verdict in e.einv.seen and (all r : e.einv.seen | one e.dv[r] - Planned)
}
check A_Invariant_2_1 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_2_2: no fulfilled event carries the invocation id of a fulfillment whose
-- enumeration failed.
assert A_Invariant_2_2 {
    built implies no e : ekind.KFulfilled | e.einv in EnumFailed
}
check A_Invariant_2_2 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_3_1: every erased disposition a fulfilled event carries has destruction evidence.
assert A_Invariant_3_1 {
    built implies all e : ekind.KFulfilled, r : e.dv.VErased | evidence[r]
}
check A_Invariant_3_1 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_3_2: no fulfillment called the host delete for a record whose retention reading
-- is not clear.
assert A_Invariant_3_2 {
    built implies all f : Ful, r : f.hans.HAns | f.rread[r] = RClear
}
check A_Invariant_3_2 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_4_1: every sealed disposition other than an anomaly names the authority it rests
-- on, recoverable from the record's sources and the calls over it; an included one carries
-- no-bar (finding (a)).
assert A_Invariant_4_1 {
    built implies all e : ekind.KFulfilled, r : e.dv.(Verdict - VAnomaly) |
        (e.dv[r] = VIncluded and e.dwhy[r] = WNoBar)
        or (some e.dauth[r] and e.dauth[r] in sources[r])
}
check A_Invariant_4_1 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_5_1: every Fulfilled request carries exactly one request-scoped disclosure.
assert A_Invariant_5_1 {
    built implies all q : Request | some fulfilledOf[q] implies one discOf[q]
}
check A_Invariant_5_1 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_6_2: no fulfillment records an event of a request later in the log than the
-- request's fulfilled event, its own fulfilled event aside (Check 6.9).
assert A_Invariant_6_2 {
    built implies all e : ekind.KFulfilled, x : Event |
        (x.ereq = e.ereq and x.ekind != KIntake and no x.wleg and x.einv != e.einv) implies lt[x.pos, e.pos]
}
check A_Invariant_6_2 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_7_1: no fulfillment calls a Consent write.
assert A_Invariant_7_1 {
    built implies all f : Ful | no f.cops & (CGrant + CRevoke)
}
check A_Invariant_7_1 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_7_2: every Consent call a fulfillment makes is Consent's check or read.
assert A_Invariant_7_2 {
    built implies all f : Ful | f.cops in CCheck + CRead
}
check A_Invariant_7_2 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_8_1: every response disclosure follows, in the log, a landed intent of the
-- fulfillment it answers — the fulfillment's own or, for a leg's, the intent the leg closes.
assert A_Invariant_8_1 {
    built implies all d : Disclosure |
        some i : ekind.KIntent | i.einv in d.dby + d.dby.lof and lt[i.pos, d.dpos]
}
check A_Invariant_8_1 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- A_Invariant_8_2: no fulfillment made a destroying call without a landed erasure intent.
assert A_Invariant_8_2 {
    built implies all f : Ful | (some f.pread or some f.hans) implies
        (some i : intentOf[f] | i.einv.act = Erasure)
}
check A_Invariant_8_2 for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowAccessFulfilled: an access fulfilled, one record included and one withheld.
run ShowAccessFulfilled {
    built and some e : ekind.KFulfilled | e.einv.act = Access and VIncluded + VWithheld in Record.(e.dv)
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowHoldGate: an erasure sealed with a record retained on a legal hold beside one erased.
run ShowHoldGate {
    built and some e : ekind.KFulfilled | e.einv.act = Erasure and WLegalHold + WDestroyed in Record.(e.dwhy)
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowObligedAndBasis: an erasure sealed with a record retained on a retention obligation beside
-- one retained on another lawful basis.
run ShowObligedAndBasis {
    built and some e : ekind.KFulfilled | WRetObligation + WOtherBasis in Record.(e.dwhy)
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowHostDeleted: a host-managed record erased on the host delete's attestation.
run ShowHostDeleted {
    built and some e : ekind.KFulfilled, r : e.dv.VErased | no r.rid
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowUncalledUnsettled: a planned record the grant admitted no call for, sealed unsettled.
run ShowUncalledUnsettled {
    built and some e : ekind.KFulfilled, r : planP[e.einv] | no e.einv.pread[r] and e.dwhy[r] = WUnsettled
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowCompensated: a leg seals an orphan, naming the disclosure the invocation wrote
-- (Reconciliation 12).
run ShowCompensated {
    built and some e : ekind.KFulfilled | some e.wleg and e.rdisc.dby in Ful
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowCompleted: a leg completes a planned destruction: its own disclosure, then the fulfilled
-- event (Reconciliation 13).
run ShowCompleted {
    built and some e : ekind.KFulfilled | some e.wleg and e.rdisc.dby in Leg
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowLegAbandons: a leg abandons an intent with nothing planned (Reconciliation 15).
run ShowLegAbandons {
    built and some e : ekind.KAbandon | some e.wleg
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowInvocationAbandons: a refused disclosure write, nothing possibly destroyed: the
-- invocation abandons its own intent (Action wiring 19).
run ShowInvocationAbandons {
    built and some e : ekind.KAbandon | no e.wleg
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowOrphanOpen: a binding orphan under its open intent.
run ShowOrphanOpen {
    built and some d : Disclosure | no rdisc.d
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowAgainAfterAbandon: a request whose first intent was abandoned is fulfilled by a second
-- fulfillment.
run ShowAgainAfterAbandon {
    built and some q : Request | #intentsOf[q] = 2 and some fulfilledOf[q]
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowAlreadyFulfilledByEvent: a fulfillment reads a request whose fulfillment entry was never
-- written as Fulfilled, off the fulfilled event (Composition state 19, 25).
run ShowAlreadyFulfilledByEvent {
    built and some f : Ful, e : fulfilledOf[f.req] | no e.entry and lt[e.pos, f.at]
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowIncompleteEnumeration: an admitted fulfillment whose enumeration failed writes nothing.
run ShowIncompleteEnumeration {
    built and some f : EnumFailed | admitted[f]
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowYieldedOpen: an intended erasure whose grant ran out before its disclosure write leaves
-- its intent open.
run ShowYieldedOpen {
    built and some f : Yielded | landed[f] and f.act = Erasure and no closingsOf[f]
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int

-- ShowConsentChecked: an erasure calls Consent's check for a record whose basis names consent.
run ShowConsentChecked {
    built and some f : Ful | CCheck in f.cops and some ownOf[f]
} for 3 but 6 Event, 3 Ful, 2 Leg, 4 Int
