-- resolve-a-persons-data-rights-buggy-obliged-unnamed.als
-- DELIBERATELY WRONG twin of resolve-a-persons-data-rights.als (re-derived 2026-11-22, unit: compositions/resolve-a-persons-data-rights.md composes Recoverable Invocation).
--
-- INJECTED DEFECT: a record whose purge answered not-eligible or under-active-retention is sealed retained carrying retention-obligation without the retention id (Disposition 22).
--
-- BREAKS: A_Invariant_4_1.
-- Everything else is resolve-a-persons-data-rights.als as written; read its comments there.

module resolve_a_persons_data_rights_buggy_obliged_unnamed

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

-- Part: what the execution commit answers (Term commit partition): pre-commit, committed or
-- unknown.
abstract sig Part {}
one sig PartPre, PartCommitted, PartUnknown extends Part {}

-- Inv: a call of the composition's actions, with the instant at which it reads the request's
-- state.
abstract sig Inv {
    at : one Int
}

-- Ful: a fulfillment — a [Fulfill Access Request] or [Fulfill Erasure Request] call that
-- enumerates — named by its invocation id (Capability requirement 25). Its inputs: the request
-- id it names, the sibling called (act), what the enumeration answered (seen), and per record
-- what its reads answered (det, basis, rread); what its planned calls answered (pread, hans, and
-- the hold ids a held purge answered); what its execution commit answered (part); and the purge
-- plan pairs Recoverable Invocation's sweep, probing its act, read purged under the intent's now
-- (probe). What it makes of them: the Consent operations it called (cops), and the records below.
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
    part  : lone Part,
    probe : set Record,
    cops  : set COp
}

-- EnumFailed: the fulfillments a registered source failed or answered nothing to, or whose
-- disclosure read or Consent read failed (Action wiring 12, 37) — an input.
sig EnumFailed in Ful {}

-- IntentOwed: the fulfillments whose first commit did not land: an access's one transaction,
-- or an erasure's invocation open refused (Audit arm 6, 7, 20; Recoverable Invocation Action
-- wiring 4) — an input.
sig IntentOwed in Ful {}

-- TxFailed: the erasures whose transaction of the disclosure, the fulfilled event and the
-- executed outcome did not commit (Action wiring 46: the close's recording-failure carrying
-- outcome) — an input.
sig TxFailed in Ful {}

-- Bind: a [Fulfill Erasure Request] call whose state read routed it to the re-entry bind of the
-- act bof (Action wiring 44; Term re-entry bind).
sig Bind extends Inv {
    bof : one Ful
}

-- BindFailed: the re-entry binds whose transaction did not commit — an input.
sig BindFailed in Bind {}

-- EKind: an audit event's kind the composition records: the intake event, an intent (the access
-- intent, or the act kind's intent Recoverable Invocation's open writes), a fulfilled event.
abstract sig EKind {}
one sig KIntake, KIntent, KFulfilled extends EKind {}

-- Event: one event on the trail, carrying its request id and, past the intake, the invocation
-- id of the call that wrote it (Term invocation id). An intent and a fulfilled event carry the
-- dispositions, as a verdict, a reason and the reason's authority per record; a fulfilled event
-- carries its response disclosure id, the instant of its fulfillment entry where one was
-- written, and, a re-entry bind's, the act's closing event id (Action wiring 31).
sig Event {
    ekind  : one EKind,
    ereq   : one Request,
    einv   : lone Inv,
    pos    : one Int,
    dv     : Record -> lone Verdict,
    dwhy   : Record -> lone Why,
    dauth  : Record -> set Ref,
    rdisc  : lone Disclosure,
    eclose : lone Closing,
    entry  : lone Int
}

-- CKind: a closing record of the act kind (Recoverable Invocation Term closing record).
abstract sig CKind {}
one sig CRefused, CExecuted, CEscalated, CAbandoned extends CKind {}

-- Closer: who wrote a closing record: the invocation, Recoverable Invocation's sweep, or an
-- operator through Recoverable Invocation's resolve.
abstract sig Closer {}
one sig ByInvocation, BySweep, ByOperator extends Closer {}

-- Closing: one closing record of the act of the erasure cact, with the plan pairs its outcome
-- shows purged (xpurged), where it is an .executed outcome.
sig Closing {
    cact    : one Ful,
    ckind   : one CKind,
    cby     : one Closer,
    cpos    : one Int,
    xpurged : set Record
}

-- Disclosure: a Selective Disclosure record whose scope carries a request id (Term request
-- scope), written by the call dby; every one is the composition's (Capability requirement 41).
sig Disclosure {
    dreq : one Request,
    dpos : one Int,
    dby  : one Inv
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- ownOf: the events a call wrote.
fun ownOf[i : Inv] : set Event { einv.i }

-- intentOf: the intent carrying the fulfillment's invocation id.
fun intentOf[f : Ful] : set Event { ownOf[f] & ekind.KIntent }

-- closingsOf: the closing records of the act of an erasure; invClosings: those its invocation
-- wrote.
fun closingsOf[f : Ful] : set Closing { cact.f }
fun invClosings[f : Ful] : set Closing { cact.f & cby.ByInvocation }

-- intakeOf, intentsOf, fulfilledOf: a request's intake event, intents and fulfilled events.
fun intakeOf[q : Request] : set Event { { e : Event | e.ereq = q and e.ekind = KIntake } }
fun intentsOf[q : Request] : set Event { { e : Event | e.ereq = q and e.ekind = KIntent } }
fun fulfilledOf[q : Request] : set Event { { e : Event | e.ereq = q and e.ekind = KFulfilled } }

-- closingsOn: the closing records of every act of a request.
fun closingsOn[q : Request] : set Closing { { c : Closing | c.cact.req = q } }

-- discOf: the request-scoped disclosures carrying the request id; discBy: those a call wrote.
fun discOf[q : Request] : set Disclosure { dreq.q }
fun discBy[i : Inv] : set Disclosure { dby.i }

-- evFul: the fulfillment whose enumeration a fulfilled event carries — its own, or for a re-entry
-- bind's, the act's.
fun evFul[e : Event] : set Ful { (e.einv & Ful) + (e.einv & Bind).bof }

-- reqOf: the request a call names.
fun reqOf[i : Inv] : set Request { (i & Ful).req + (i & Bind).bof.req }

-- wposOf: the instants of a call's own writes: events, disclosures, and the closings its
-- invocation wrote.
fun wposOf[i : Inv] : set Int {
    ownOf[i].pos + discBy[i].dpos + (cact.i & cby.ByInvocation).cpos
}

-- sources: every datum a record's sources and the calls over it answered: what a reason can
-- name as a recoverable authority (Check 4.1).
fun sources[r : Record] : set Ref {
    r.detRef + r.ground + r.hostBasis + r.attest + r.rid + r.(Ful.holds)
}

-- standsAt: a closing record stands at p — it lies before p and no later closing of its act
-- lies before p (Recoverable Invocation Term standing closing, read as the latest).
pred standsAt[c : Closing, p : Int] {
    lt[c.cpos, p]
    no c2 : closingsOf[c.cact] | lt[c.cpos, c2.cpos] and lt[c2.cpos, p]
}

-- The request's state at an instant p, read off the records written before p (Composition
-- state 15 through 31; Term request state).
-- fulfilledAt: a fulfilled event or a fulfillment entry stands before p.
pred fulfilledAt[q : Request, p : Int] {
    some e : fulfilledOf[q] | lt[e.pos, p] or (some e.entry and lt[e.entry, p])
}

-- openAt: an intent of the act kind stands before p with no closing record before p
-- (Composition state 17).
pred openAt[q : Request, p : Int] {
    some i : intentsOf[q] | i.einv.act = Erasure and lt[i.pos, p]
        and (no c : closingsOf[i.einv] | lt[c.cpos, p])
}

-- escalatedAt, executedAt: an act's standing closing is .escalated, or .executed, at p
-- (Composition state 30, 31).
pred escalatedAt[q : Request, p : Int] { some c : closingsOn[q] | c.ckind = CEscalated and standsAt[c, p] }
pred executedAt[q : Request, p : Int] { some c : closingsOn[q] | c.ckind = CExecuted and standsAt[c, p] }

-- receivedAt: the request's intake event stands before p (the request is known).
pred receivedAt[q : Request, p : Int] {
    some e : intakeOf[q] | lt[e.pos, p]
}

-- admitted: Action wiring 4 through 9, 43 and 44 route the call to the enumeration: the request
-- is known, neither Fulfilled nor Committing at the read, and the sibling called matches its
-- right type (Term admitted fulfillment).
pred admitted[f : Ful] {
    receivedAt[f.req, f.at]
    not fulfilledAt[f.req, f.at]
    not openAt[f.req, f.at]
    not escalatedAt[f.req, f.at]
    not executedAt[f.req, f.at]
    f.act = f.req.rtype
}

-- precheck: Recoverable Invocation's open, under the act section at p: no open intent of the act
-- key (act-in-flight) and no outcome of it (act-landed, open step 3.9) — a refusal, an
-- escalation or an abandonment holding none (Term act key).
pred precheck[f : Ful, p : Int] {
    not openAt[f.req, p]
    no c : closingsOn[f.req] | c.ckind = CExecuted and lt[c.cpos, p]
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

-- landed: an access whose transaction committed, or an intended erasure (Term intended erasure).
pred landed[f : Ful] { go[f] and f not in IntentOwed }

-- sealsOwn: the fulfillment itself writes the disclosure and the fulfilled event — an access whose
-- transaction committed, or an erasure whose commit answered committed and whose transaction of
-- the close committed (Action wiring 22, 46).
pred sealsOwn[f : Ful] {
    landed[f] and (f.act = Access or (f.part = PartCommitted and f not in TxFailed))
}

-- leftOpen: an intended erasure whose invocation closed nothing: the commit answered unknown
-- (Action wiring 48), or committed with the close's transaction failed (Action wiring 46).
pred leftOpen[f : Ful] {
    landed[f] and f.act = Erasure and (f.part = PartUnknown or (f.part = PartCommitted and f in TxFailed))
}

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
        (some f.pread[r] & (PDestroyed + PGone) => r.rid
         else (f.pread[r] = PHeld => f.holds[r] else none))
    else (r in planH[f] =>
        (f.hans[r] = HDeleted => r.attest
         else (f.hans[r] = HRetained => r.hostBasis else none))
    else provA[f, r])
}

-- evidence: destruction evidence for a record (Term destruction evidence): for a record whose
-- route carries a retention id, a purge that answered ok (destroyed), a not-known borne out by a
-- purged reading (gone), or a retention reading that answered purged — the enumeration's, or the
-- erasure probe's; for a host-managed record, a host delete that answered deleted.
pred evidence[r : Record] {
    some r.rid implies
        (some f : Ful | some f.pread[r] & (PDestroyed + PGone) or f.rread[r] = RPurged or r in f.probe)
    no r.rid implies (some f : Ful | f.hans[r] = HDeleted)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- One real-time order: every write lands at its own instant, and every call reads at an instant
-- no write takes.
fact Clock {
    all disj e1, e2 : Event | e1.pos != e2.pos
    all disj d1, d2 : Disclosure | d1.dpos != d2.dpos
    all disj c1, c2 : Closing | c1.cpos != c2.cpos
    all disj i1, i2 : Inv | i1.at != i2.at
    all disj e1, e2 : Event | (some e1.entry and some e2.entry) implies e1.entry != e2.entry
    no Event.pos & Disclosure.dpos
    no (Event.pos + Disclosure.dpos) & Closing.cpos
    no (Event.pos + Disclosure.dpos + Closing.cpos) & Inv.at
    no Event.entry & (Event.pos + Disclosure.dpos + Closing.cpos + Inv.at)
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

-- Recoverable Invocation's act section (its model's): two acts of one request hold it one after
-- the other, each from its intent to its invocation's last write, and the sweep's and an
-- operator's closings fall in no act's span and after the invocation of the act they close.
fact ActSection {
    all disj f1, f2 : Ful | (f1.req = f2.req and some intentOf[f1] and some intentOf[f2]) implies
        ((all x : wposOf[f1], j : intentOf[f2] | lt[x, j.pos]) or (all x : wposOf[f2], j : intentOf[f1] | lt[x, j.pos]))
    all c : Closing - cby.ByInvocation, f : Ful | (f.req = c.cact.req and some intentOf[f]) implies
        not (some j : intentOf[f], x : wposOf[f] | lt[j.pos, c.cpos] and lt[c.cpos, x])
    all c : Closing - cby.ByInvocation, x : wposOf[c.cact] | lt[x, c.cpos]
}

-- An operator's resolve (Recoverable Invocation's, detected by its Check 6.1, not this page's):
-- it closes an act the sweep escalated, later than the escalation; its outcome shows purged only
-- what the stores show destroyed; it abandons only an act whose commit made no planned call.
fact Operator {
    all c : cby.ByOperator | c.ckind in CExecuted + CAbandoned
        and (some s : closingsOf[c.cact] | s.cby = BySweep and s.ckind = CEscalated and lt[s.cpos, c.cpos])
    all c : cby.ByOperator | all r : c.xpurged | evidence[r]
    all c : cby.ByOperator | c.ckind = CAbandoned implies (no c.cact.pread and no c.cact.hans)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writes: what each call, the sweep and the re-entry bind leave
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

-- fulWiring: what one fulfillment writes. A refusal ahead of the enumeration writes nothing
-- (Action wiring 10, 13; Primitive policy 6). An enumerated access writes its intent, the
-- disclosure and the fulfilled event in one transaction under its state read, or nothing
-- (Execution Contract Database 1, 2). An enumerated erasure opens the act (Action wiring 24), Recoverable Invocation's pre-check
-- read under the act section at the intent; its execution commit's guard read refuses
-- already-fulfilled, pre-commit, before any planned call; pre-commit is closed by the invocation
-- refuse (Action wiring 47); committed writes the disclosure, the fulfilled event and the executed
-- outcome — the pairs its own purge destroyed — in one transaction (Action wiring 46, Recoverable
-- Invocation close 5); unknown, or a failed transaction, leaves the act open (Action wiring 48).
pred fulWiring[f : Ful] {
    lone intentOf[f]
    lone ownOf[f] & ekind.KFulfilled
    no ownOf[f] & ekind.KIntake
    lone discBy[f]
    all x : wposOf[f] | lt[f.at, x]
    consentWiring[f]
    not go[f] implies (no ownOf[f] and no discBy[f] and no f.pread and no f.hans and no f.part)
    some intentOf[f] iff landed[f]
    all i : intentOf[f] | provisional[i, f]
    all i : intentOf[f] | f.act = Erasure implies precheck[f, i.pos]
    some f.part iff (landed[f] and f.act = Erasure)
    (some e : fulfilledOf[f.req], i : intentOf[f] | lt[e.pos, i.pos]) implies f.part in PartPre
    (some f.pread or some f.hans) implies f.part in PartCommitted + PartUnknown
    f.pread.PRead in planP[f]
    f.hans.HAns in planH[f]
    some discBy[f] iff sealsOwn[f]
    some (ownOf[f] & ekind.KFulfilled) iff sealsOwn[f]
    all d : discBy[f] | d.dreq = f.req and (all i : intentOf[f] | lt[i.pos, d.dpos])
    all e : ownOf[f] & ekind.KFulfilled |
        one e.rdisc and e.rdisc = discBy[f] and lt[discBy[f].dpos, e.pos] and sealed[e, f] and no e.eclose
    (f.part = PartPre) implies (one invClosings[f] and invClosings[f].ckind = CRefused)
    (f.act = Erasure and sealsOwn[f]) implies
        (one invClosings[f] and invClosings[f].ckind = CExecuted
         and invClosings[f].xpurged = (f.pread.PDestroyed & planP[f]))
    (f.part != PartPre and not (f.act = Erasure and sealsOwn[f])) implies no invClosings[f]
    all c : invClosings[f], i : intentOf[f] | lt[i.pos, c.cpos]
    f.probe in planP[f]
    f.act = Access implies oneTx[f, f.req]
    (f.act = Erasure and sealsOwn[f]) implies closeTx[f]
}

-- sweepWiring: Recoverable Invocation's sweep over an act its invocation left open writes one
-- closing: .executed where the erasure probe answers committed — exactly one plan pair read
-- purged under the intent's now and the host delete plan empty — its outcome showing that pair
-- purged; .escalated otherwise (Term erasure probe). It never refuses, abandons or discloses.
pred sweepWiring[f : Ful] {
    lone closingsOf[f] & cby.BySweep
    some (closingsOf[f] & cby.BySweep) implies leftOpen[f]
    all c : closingsOf[f] & cby.BySweep {
        c.ckind in CExecuted + CEscalated
        c.ckind = CExecuted iff (one f.probe and no planH[f])
        c.ckind = CExecuted implies c.xpurged = f.probe
    }
    lone closingsOf[f] & cby.ByOperator
}

-- oneTx: a call's read and its writes are one store transaction (Execution Contract Database 1,
-- 2): nothing another call writes on the request lands between its read and its last write.
pred oneTx[i : Inv, q : Request] {
    all x : wposOf[i] {
        no e : Event - ownOf[i] | e.ereq = q and lt[i.at, e.pos] and lt[e.pos, x]
        no d : Disclosure - discBy[i] | d.dreq = q and lt[i.at, d.dpos] and lt[d.dpos, x]
        no c : closingsOn[q] | lt[i.at, c.cpos] and lt[c.cpos, x]
    }
}

-- closeTx: an erasure's transaction of the disclosure, the fulfilled event and the executed outcome
-- is one (Action wiring 46; Execution Contract Database 1): the outcome lands between the
-- disclosure and the event, and no other call's write or read of the request lands among them.
pred closeTx[f : Ful] {
    all d : discBy[f], e : ownOf[f] & ekind.KFulfilled {
        all c : invClosings[f] | lt[d.dpos, c.cpos] and lt[c.cpos, e.pos]
        no x : Event - ownOf[f] | x.ereq = f.req and lt[d.dpos, x.pos] and lt[x.pos, e.pos]
        no x : Disclosure - discBy[f] | x.dreq = f.req and lt[d.dpos, x.dpos] and lt[x.dpos, e.pos]
        no x : closingsOn[f.req] - invClosings[f] | lt[d.dpos, x.cpos] and lt[x.cpos, e.pos]
        no i : Inv - f | f.req in reqOf[i] and lt[d.dpos, i.at] and lt[i.at, e.pos]
    }
}

-- bindSet: the re-entry bind's dispositions: every record outside the plans as the intent carries
-- it (Action wiring 49); a purge plan pair the act's standing closing shows purged, erased
-- carrying the retention id (Action wiring 50); every other planned record, a host delete plan
-- record always, anomaly carrying unsettled (Action wiring 51).
pred bindSet[e : Event, i : Event, c : Closing] {
    e.dv.Verdict in i.dv.Verdict and e.dwhy.Why in i.dv.Verdict and e.dauth.Ref in i.dv.Verdict
    all r : i.dv.Verdict - i.dv.Planned | e.dv[r] = i.dv[r] and e.dwhy[r] = i.dwhy[r] and e.dauth[r] = i.dauth[r]
    all r : i.dv.Planned | (r in c.xpurged and some r.rid) =>
        (e.dv[r] = VErased and e.dwhy[r] = WDestroyed and e.dauth[r] = r.rid)
        else (e.dv[r] = VAnomaly and e.dwhy[r] = WUnsettled and no e.dauth[r])
}

-- bindRoute: the bind's state read at its instant routes to the re-entry bind: the request is
-- known, not Fulfilled, no intent stands open and no escalation stands, and the act's standing
-- closing is .executed (Action wiring 4 through 6, 43, 44).
pred bindRoute[b : Bind] {
    receivedAt[b.bof.req, b.at]
    not fulfilledAt[b.bof.req, b.at]
    not openAt[b.bof.req, b.at]
    not escalatedAt[b.bof.req, b.at]
    some c : closingsOf[b.bof] | c.ckind = CExecuted and standsAt[c, b.at]
}

-- bindWiring: a re-entry bind, its state read routing it to the bind, writes in one store
-- transaction the disclosure and then the fulfilled event naming it and the act's standing
-- closing, sealed from the intent and the closing (Action wiring 52); where the transaction does
-- not commit it writes nothing. The transaction's guard is Action wiring 44's own, read again at
-- its writes (Execution Contract Database 2): no fulfilled event names the request there; nothing
-- of another call lands among its writes.
pred bindWiring[b : Bind] {
    no ownOf[b] & ekind.(KIntake + KIntent)
    lone ownOf[b] & ekind.KFulfilled
    lone discBy[b]
    all x : wposOf[b] | lt[b.at, x]
    some discBy[b] iff (bindRoute[b] and b not in BindFailed)
    some (ownOf[b] & ekind.KFulfilled) iff (bindRoute[b] and b not in BindFailed)
    all d : discBy[b] | d.dreq = b.bof.req
    all e : ownOf[b] & ekind.KFulfilled {
        one e.rdisc and e.rdisc = discBy[b] and lt[discBy[b].dpos, e.pos]
        one e.eclose and e.eclose in closingsOf[b.bof] and e.eclose.ckind = CExecuted and standsAt[e.eclose, b.at]
        all i : intentOf[b.bof] | bindSet[e, i, e.eclose]
    }
    no e2 : fulfilledOf[b.bof.req] - ownOf[b] | some x : wposOf[b] | lt[e2.pos, x] or (some e2.entry and lt[e2.entry, x])
    all d : discBy[b], e : ownOf[b] & ekind.KFulfilled {
        no x : Event - ownOf[b] | x.ereq = b.bof.req and lt[d.dpos, x.pos] and lt[x.pos, e.pos]
        no x : Disclosure - discBy[b] | x.dreq = b.bof.req and lt[d.dpos, x.dpos] and lt[x.dpos, e.pos]
        no x : closingsOn[b.bof.req] | lt[d.dpos, x.cpos] and lt[x.cpos, e.pos]
    }
}

-- built: every record in the state is what an admitted write left: one intake event per
-- request id carrying no invocation (Action wiring 1 through 3); every other event a call's, by
-- its rules, on the request it names; the dispositions only on intents and fulfilled events, the
-- disclosure id and the entry only on fulfilled events, the entry after its event (Composition
-- state 9), the closing event id only on a re-entry bind's; every closing record of an intended
-- erasure, after its intent.
pred built {
    all f : Ful | fulWiring[f]
    all f : Ful | sweepWiring[f]
    all b : Bind | bindWiring[b]
    all q : Request | lone intakeOf[q]
    all e : ekind.KIntake | no e.einv
    all e : Event - ekind.KIntake | some e.einv and e.ereq = reqOf[e.einv]
    all e : Event - ekind.(KIntent + KFulfilled) | no e.dv and no e.dwhy and no e.dauth
    all e : Event - ekind.KFulfilled | no e.rdisc and no e.entry and no e.eclose
    all e : ownOf[Ful] | no e.eclose
    all e : Event | some e.entry implies lt[e.pos, e.entry]
    all c : Closing | c.cact.act = Erasure and some intentOf[c.cact]
    all c : Closing, i : intentOf[c.cact] | lt[i.pos, c.cpos]
    all c : Closing | c.ckind != CExecuted implies no c.xpurged
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions — the page's single-state invariants
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: every fulfilled event names a response disclosure carrying its request id,
-- written before it, and carries a verdict — no planned marker — for every enumerated record.
assert A_Invariant_1_1 {
    built implies all e : ekind.KFulfilled |
        some e.rdisc and e.rdisc.dreq = e.ereq and lt[e.rdisc.dpos, e.pos]
        and (all r : evFul[e].seen | some e.dv[r] - Planned)
}
check A_Invariant_1_1 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_1_2: every Fulfilled request carries exactly one fulfilled event.
assert A_Invariant_1_2 {
    built implies all q : Request | some fulfilledOf[q] implies one fulfilledOf[q]
}
check A_Invariant_1_2 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_1_3: every fulfilled event names a request — a request id an intake event carries.
assert A_Invariant_1_3 {
    built implies all e : ekind.KFulfilled | one intakeOf[e.ereq]
}
check A_Invariant_1_3 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_1_4: exactly one fulfilled event names every request-scoped disclosure.
assert A_Invariant_1_4 {
    built implies all d : Disclosure | one rdisc.d
}
check A_Invariant_1_4 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_2_1: every fulfilled event carries exactly one disposition per record of the
-- enumerated universe, and none for a record outside it.
assert A_Invariant_2_1 {
    built implies all e : ekind.KFulfilled |
        e.dv.Verdict in evFul[e].seen and (all r : evFul[e].seen | one e.dv[r] - Planned)
}
check A_Invariant_2_1 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_2_2: no fulfilled event carries the enumeration of a fulfillment whose enumeration
-- failed.
assert A_Invariant_2_2 {
    built implies no e : ekind.KFulfilled | some evFul[e] & EnumFailed
}
check A_Invariant_2_2 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_3_1: every erased disposition a fulfilled event carries has destruction evidence,
-- and so does every pair an .executed closing shows purged.
assert A_Invariant_3_1 {
    built implies {
        all e : ekind.KFulfilled, r : e.dv.VErased | evidence[r]
        all c : ckind.CExecuted, r : c.xpurged | evidence[r]
    }
}
check A_Invariant_3_1 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_3_2: no fulfillment called the host delete for a record whose retention reading
-- is not clear.
assert A_Invariant_3_2 {
    built implies all f : Ful, r : f.hans.HAns | f.rread[r] = RClear
}
check A_Invariant_3_2 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_4_1: every sealed disposition other than an anomaly names the authority it rests
-- on, recoverable from the record's sources and the calls over it; an included one carries
-- no-bar (finding (a)).
assert A_Invariant_4_1 {
    built implies all e : ekind.KFulfilled, r : e.dv.(Verdict - VAnomaly) |
        (e.dv[r] = VIncluded and e.dwhy[r] = WNoBar)
        or (some e.dauth[r] and e.dauth[r] in sources[r])
}
check A_Invariant_4_1 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_5_1: every Fulfilled request carries exactly one request-scoped disclosure.
assert A_Invariant_5_1 {
    built implies all q : Request | some fulfilledOf[q] implies one discOf[q]
}
check A_Invariant_5_1 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_6_2: no call records an event of a request later in the log than the request's
-- fulfilled event, that event's own writer aside (Check 6.9).
assert A_Invariant_6_2 {
    built implies all e : ekind.KFulfilled, x : Event |
        (x.ereq = e.ereq and x.ekind != KIntake and x.einv != e.einv) implies lt[x.pos, e.pos]
}
check A_Invariant_6_2 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_7_1: no fulfillment calls a Consent write.
assert A_Invariant_7_1 {
    built implies all f : Ful | no f.cops & (CGrant + CRevoke)
}
check A_Invariant_7_1 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_7_2: every Consent call a fulfillment makes is Consent's check or read.
assert A_Invariant_7_2 {
    built implies all f : Ful | f.cops in CCheck + CRead
}
check A_Invariant_7_2 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Invariant_8_1: every response disclosure follows, in the log, a landed intent of the
-- fulfillment it answers — the writer's own, or for a re-entry bind's, the act's.
assert A_Invariant_8_1 {
    built implies all d : Disclosure |
        some i : ekind.KIntent | i.einv in (d.dby & Ful) + (d.dby & Bind).bof and lt[i.pos, d.dpos]
}
check A_Invariant_8_1 for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- A_Accounted: no act closed refused or abandoned made a planned call — the invocation refuse
-- closes only the pre-commit arm (Action wiring 47, Term commit partition).
assert A_Accounted {
    built implies all c : ckind.(CRefused + CAbandoned) | no c.cact.pread and no c.cact.hans
}
check A_Accounted for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowAccessFulfilled: an access fulfilled, one record included and one withheld.
run ShowAccessFulfilled {
    built and some e : ekind.KFulfilled | evFul[e].act = Access and VIncluded + VWithheld in Record.(e.dv)
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowHoldGate: an erasure sealed with a record retained on a legal hold beside one erased.
run ShowHoldGate {
    built and some e : ekind.KFulfilled | evFul[e].act = Erasure and WLegalHold + WDestroyed in Record.(e.dwhy)
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowObligedAndBasis: an erasure sealed with a record retained on a retention obligation beside
-- one retained on another lawful basis.
run ShowObligedAndBasis {
    built and some e : ekind.KFulfilled | WRetObligation + WOtherBasis in Record.(e.dwhy)
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowHostDeleted: a host-managed record erased on the host delete's attestation.
run ShowHostDeleted {
    built and some e : ekind.KFulfilled, r : e.dv.VErased | no r.rid
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowUncalledUnsettled: a planned record no planned call settled, sealed unsettled
-- (Disposition 45).
run ShowUncalledUnsettled {
    built and some e : ekind.KFulfilled & ownOf[Ful], r : planP[e.einv] | no e.einv.pread[r] and e.dwhy[r] = WUnsettled
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowRefused: an erasure whose execution commit answered pre-commit, closed refused.
run ShowRefused {
    built and some c : ckind.CRefused | c.cby = ByInvocation
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowSweepBound: the sweep's probe closes an act .executed and a re-entry bind seals the pair it
-- shows purged erased (the orphan rejection path).
run ShowSweepBound {
    built and some e : ekind.KFulfilled | e.eclose.cby = BySweep and VErased in Record.(e.dv)
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowOperatorBound: an act the sweep escalated, an operator closes .executed, and a re-entry bind
-- seals a planned record unsettled.
run ShowOperatorBound {
    built and some e : ekind.KFulfilled | e.eclose.cby = ByOperator and WUnsettled in Record.(e.dwhy)
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowAbandonedByOperator: an act the sweep escalated, abandoned by an operator.
run ShowAbandonedByOperator {
    built and some c : ckind.CAbandoned | c.cby = ByOperator
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowAgainAfterRefusal: a request whose first act was refused is fulfilled by a second
-- erasure.
run ShowAgainAfterRefusal {
    built and some q : Request | #intentsOf[q] = 2 and some fulfilledOf[q] and some c : closingsOn[q] | c.ckind = CRefused
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowAlreadyFulfilledByEvent: a fulfillment reads a request whose fulfillment entry was never
-- written as Fulfilled, off the fulfilled event (Composition state 19, 25).
run ShowAlreadyFulfilledByEvent {
    built and some f : Ful, e : fulfilledOf[f.req] | no e.entry and lt[e.pos, f.at]
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowIncompleteEnumeration: an admitted fulfillment whose enumeration failed writes nothing.
run ShowIncompleteEnumeration {
    built and some f : EnumFailed | admitted[f]
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowYieldedOpen: an intended erasure whose commit answered unknown leaves its intent open.
run ShowYieldedOpen {
    built and some f : Ful | f.part = PartUnknown and no closingsOf[f]
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int

-- ShowConsentChecked: an erasure calls Consent's check for a record whose basis names consent.
run ShowConsentChecked {
    built and some f : Ful | CCheck in f.cops and some ownOf[f]
} for 3 but 6 Event, 3 Ful, 1 Bind, 3 Closing, 4 Int
