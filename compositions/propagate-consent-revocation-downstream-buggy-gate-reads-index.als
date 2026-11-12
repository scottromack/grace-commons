-- propagate-consent-revocation-downstream-buggy-gate-reads-index.als
-- DELIBERATELY WRONG twin of propagate-consent-revocation-downstream.als (unit: `compositions/propagate-consent-revocation-downstream.md formal layer`).
--
-- INJECTED DEFECT: the gate also reads the subject index — permitted only where the consent check answers granted and an indexed consent of the pair stands (Action wiring 55, Invariant 7.2).
--
-- BREAKS: A_Invariant_7_2.
-- Everything else is propagate-consent-revocation-downstream.als as written; read its comments there.

module propagate_consent_revocation_downstream_buggy_gate_reads_index

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Subj: an opaque subject reference, the data subject a consent is about.
sig Subj {}

-- Purp: an opaque processing purpose a consent covers.
sig Purp {}

-- Actor: an actor reference — the operator an administration action runs for.
sig Actor {}

-- Pair: a processing scope with the processor reference that operates it (Term pair).
sig Pair {}

-- Reason: the free-form reason a withdrawal passes to the revoke write.
sig Reason {}

-- Now: an instant the host injects at the seam, compared by equality only.
sig Now {}

-- Scope: the four scopes the composition defines on its Permissions instance.
abstract sig Scope {}
one sig ConsentGrant, ConsentRevoke, ConsentRegister, ConsentRead extends Scope {}

-- Perms: what Permissions' permission check answers permitted, actor by scope.
one sig Perms {
    may : Actor -> Scope
}

-- Status: a Consent record's state as Consent reports it (Expired standing for a grant past
-- its expiry; the clock is not modeled).
abstract sig Status {}
one sig Granted, Revoked, Expired extends Status {}

-- Consent: a Consent record, its atom the consent id — the subject reference, purpose,
-- grantor and grant instant the grant write stamped, its status, the revoker, revocation
-- instant and reason a revoke stamped, and, as the model's ghosts, the grant intent whose
-- commit wrote it and the withdrawal intent whose commit revoked it (none: a write outside
-- every invocation).
sig Consent {
    cSubj     : one Subj,
    cPurp     : one Purp,
    grantor   : one Actor,
    grantedAt : one Now,
    status    : one Status,
    revoker   : lone Actor,
    revokedAt : lone Now,
    reason    : lone Reason,
    grantedBy : lone GrantIntent,
    revokedBy : lone WdIntent
}

-- RState: a consent retention's state on the consent retention instance.
abstract sig RState {}
one sig Retained, RPurged extends RState {}

-- Retention: a consent retention — the Consent record it is over, its state, and, as the
-- model's ghost, the grant intent whose transaction placed it.
sig Retention {
    over   : one Consent,
    rstate : one RState,
    rWrote : lone GrantIntent
}

-- CArm: the commit partition's arm an invocation's commit answered (Term commit partition).
abstract sig CArm {}
one sig Committed, PreCommit, Unknown extends CArm {}

-- Intent: a record Recoverable Invocation's open wrote before the Consent write — its actor
-- reference, its pairing datum (the invocation's now) and, as the model's ghost, its arm.
abstract sig Intent {
    arm    : one CArm,
    iActor : one Actor,
    datum  : one Now
}

-- GrantIntent: a consent.grant.intended event, carrying the grant key (subject reference and
-- purpose) and no consent id (Action wiring 4, 5).
sig GrantIntent extends Intent {
    gSubj : one Subj,
    gPurp : one Purp
}

-- WdIntent: a consent.withdrawal.intended event, carrying the consent id and the reason, and
-- no propagation set (Action wiring 32, 33).
sig WdIntent extends Intent {
    wConsent : one Consent,
    wReason  : one Reason
}

-- RegEvent: a processing.registered event, carrying the consent id and the pair.
sig RegEvent {
    regConsent : one Consent,
    regPair    : one Pair
}

-- PurgedReg: the registration events the record read answers Purged — their payload
-- destroyed at the audit horizon, the event's place in the Event Log surviving.
sig PurgedReg in RegEvent {}

-- RegCall: one [Register Processing] call — its actor, consent id and pair, and the
-- registration event it landed (none: refused, or the audit write failed).
sig RegCall {
    rcActor   : one Actor,
    rcConsent : one Consent,
    rcPair    : one Pair,
    rcEvent   : lone RegEvent
}

-- Log: the Event Log's order over the registration events and the withdrawal intents.
one sig Log {
    order : (RegEvent + WdIntent) -> (RegEvent + WdIntent)
}

-- Binding: a downstream index binding — the consent id, the pair, the registration event id
-- it carries and, as the model's ghost, the call that added it (none: a binding repair or a
-- rebuild).
sig Binding {
    bConsent : one Consent,
    bPair    : one Pair,
    bEvent   : lone RegEvent,
    bCall    : lone RegCall
}

-- Writer: who wrote a closing — the invocation (its close or its refuse), the sweep, or an
-- operator through the invocation resolve.
abstract sig Writer {}
one sig ByClose, BySweep, ByOperator extends Writer {}

-- Closing: a record that closes an intent under its invocation id, and its writer.
abstract sig Closing {
    closes : one Intent,
    by     : one Writer
}

-- GrantEvent: a consent.grant.granted outcome, carrying the consent id and the retention id.
sig GrantEvent extends Closing {
    geConsent : lone Consent,
    geRet     : lone Retention
}

-- PropEvent: a consent.withdrawal.revoked outcome, the propagation event — the consent id,
-- the reason, the revocation instant and the propagation set it carries.
sig PropEvent extends Closing {
    peConsent : lone Consent,
    peReason  : lone Reason,
    peAt      : lone Now,
    peSet     : set Pair
}

-- Refusal: the refusal record the invocation refuse writes for a pre-commit arm.
sig Refusal extends Closing {}

-- Abandonment: an operator's abandoned disposition through the invocation resolve.
sig Abandonment extends Closing {}

-- Idx: the subject index — the consent ids it resolves.
one sig Idx {
    subj : set Consent
}

-- CheckAns: what Consent's consent check answers.
abstract sig CheckAns {}
one sig CGranted, CRevoked, CExpired, CNotKnown extends CheckAns {}

-- GateAns: what [Processing Permitted] answers.
abstract sig GateAns {}
one sig Permitted, NotPermitted extends GateAns {}

-- GateQuery: one validated gate query — its subject reference and purpose, the consent
-- check's answer at the query's instant, the gate's answer and the withheld state it carries.
sig GateQuery {
    qSubj     : one Subj,
    qPurp     : one Purp,
    qCheck    : one CheckAns,
    qAns      : one GateAns,
    qWithheld : lone CheckAns
}

-- AccessEvent: a consent.history-read event, carrying the subject reference.
sig AccessEvent {
    aSubj : one Subj
}

-- HistoryRead: one [Read Consent History] call past its consent read — its actor, subject
-- reference and the access event it landed (none: the audit write failed).
sig HistoryRead {
    hActor : one Actor,
    hSubj  : one Subj,
    hEvent : lone AccessEvent
}

-- Answered: the history reads that answered the consent history.
sig Answered in HistoryRead {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: only what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- EventLogIsOneOrder: the Event Log holds its events in one total order (Event Log's
-- sequence, reached through Audit Trail).
fact EventLogIsOneOrder {
    let o = Log.order {
        no iden & o
        o.o in o
        all disj x, y : RegEvent + WdIntent | x -> y in o or y -> x in o
    }
}

-- ConsentRecordShape: Consent stamps a revoker, a revocation instant and a reason on a
-- record exactly when it revokes it, and a revoked record stays Revoked (Consent's revoke and
-- its terminal absorption; the lone revokedBy is that absorption: one revoke per record).
fact ConsentRecordShape {
    all c : Consent {
        c.status = Revoked iff some c.revokedAt
        some c.revokedAt iff some c.revoker
        some c.revokedAt iff some c.reason
    }
}

-- ConsentCheckAnswers: Consent's check on a subject reference and purpose answers granted
-- exactly where a record of the pair stands Granted, not-known exactly where none exists, and
-- otherwise a state one of the pair's records holds (Consent's check).
fact ConsentCheckAnswers {
    all q : GateQuery | let R = cSubj.(q.qSubj) & cPurp.(q.qPurp) {
        q.qCheck = CGranted iff (some r : R | r.status = Granted)
        q.qCheck = CNotKnown iff no R
        q.qCheck = CRevoked implies (some r : R | r.status = Revoked)
        q.qCheck = CExpired implies (some r : R | r.status = Expired)
    }
}

-- OneClosingPerIntent: two closing records never name one intent's invocation id
-- (Recoverable Invocation Invariant 2.1, which that page's model checks).
fact OneClosingPerIntent {
    all i : Intent | lone closes.i
}

-- ClosingsOfTheirKind: an outcome closes an intent of its own act kind, a refusal record is
-- the invocation refuse's, and an abandonment is an operator's (Recoverable Invocation's
-- vocabulary and its resolve).
fact ClosingsOfTheirKind {
    GrantEvent.closes in GrantIntent
    PropEvent.closes in WdIntent
    all f : Refusal | f.by = ByClose
    all a : Abandonment | a.by = ByOperator
}

-- HostNowFreshPerActKey: the host never injects an equal now into two invocations of one act
-- key (Capability requirement 38, the host's obligation, cleared by External check 7).
fact HostNowFreshPerActKey {
    all disj i, j : WdIntent | i.wConsent = j.wConsent implies i.datum != j.datum
    all disj i, j : GrantIntent |
        (i.gSubj = j.gSubj and i.gPurp = j.gPurp) implies i.datum != j.datum
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- prec: the Event Log's order.
fun prec : univ -> univ {
    Log.order
}

-- recordsOf: the Consent records of one subject reference and purpose.
fun recordsOf[s : Subj, p : Purp] : set Consent {
    cSubj.s & cPurp.p
}

-- firstReg: the pair's first registration event under the consent id — the earliest in the
-- Event Log of the registration events carrying both.
fun firstReg[c : Consent, p : Pair] : set RegEvent {
    let E = regConsent.c & regPair.p | E - E.prec
}

-- derived: the propagation set the composition derives for consent c at withdrawal intent i
-- (Action wiring 29 through 31, Term propagation set): the pairs of the registration events
-- whose payload the log read still reads, carrying c and preceding i, with the pairs of c's
-- purged downstream entries whose registration event precedes i — never a live entry.
fun derived[c : Consent, i : WdIntent] : set Pair {
    { p : Pair | some e : regConsent.c - PurgedReg | e.regPair = p and e -> i in prec }
  + { p : Pair | some b : bConsent.c | b.bPair = p and b.bEvent in PurgedReg
                                       and b.bEvent -> i in prec }
}

-- registeredAt: the pairs of every registration event carrying consent c that precedes
-- position i in the Event Log, read off the events themselves (a purged one's payload
-- included, as the model's ghost) — Invariant 3.3's registered set at the event's boundary.
fun registeredAt[c : Consent, i : WdIntent] : set Pair {
    (regConsent.c & prec.i).regPair
}

-- grantMatch: the grant probe's read — the Consent records carrying the grant intent's
-- subject reference, purpose, grantor and grant instant (Term grant probe).
fun grantMatch[i : GrantIntent] : set Consent {
    recordsOf[i.gSubj, i.gPurp] & grantor.(i.iActor) & grantedAt.(i.datum)
}

-- wdProbeCommitted: the withdrawal probe's committed answer — the intent's consent stands
-- Revoked at the intent's revocation instant by the intent's actor (Term withdrawal probe).
pred wdProbeCommitted[i : WdIntent] {
    i.wConsent.status = Revoked
    i.wConsent.revokedAt = i.datum
    i.wConsent.revoker = i.iActor
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writers' rules (the page's own)
-- ─────────────────────────────────────────────────────────────────────────────

-- grantWrote: what a committed grant transaction wrote (Term grant transaction): one Consent
-- record carrying the intent's subject reference, purpose, the actor as grantor and the
-- intent's now as grant instant (Action wiring 9, Capability requirement 37), and one consent
-- retention over it (Action wiring 13) — one commit.
pred grantWrote[i : GrantIntent] {
    one grantedBy.i
    let c = grantedBy.i {
        c.cSubj = i.gSubj
        c.cPurp = i.gPurp
        c.grantor = i.iActor
        c.grantedAt = i.datum
    }
    one rWrote.i
    (rWrote.i).over = grantedBy.i
}

-- grantNothing: a grant transaction that rolled back wrote nothing.
pred grantNothing[i : GrantIntent] {
    no grantedBy.i
    no rWrote.i
}

-- wdWrote: what a committed revoke wrote: the intent's consent Revoked, by the actor as
-- revoker, at the intent's revocation instant, with the intent's reason (Action wiring 34).
pred wdWrote[i : WdIntent] {
    revokedBy.i = i.wConsent
    i.wConsent.status = Revoked
    i.wConsent.revokedAt = i.datum
    i.wConsent.revoker = i.iActor
    i.wConsent.reason = i.wReason
}

-- wdNothing: a refused revoke wrote nothing.
pred wdNothing[i : WdIntent] {
    no revokedBy.i
}

-- commitRule: a committed arm wrote its commit, a pre-commit arm nothing, an unknown arm the
-- one or the other (Term commit partition, Recoverable Invocation commit 6, 7); only a grant
-- transaction places on the consent retention instance (Action wiring 13), and the
-- composition never purges it (Retention asymmetry 2).
pred commitRule {
    all i : GrantIntent {
        i.arm = Committed implies grantWrote[i]
        i.arm = PreCommit implies grantNothing[i]
        i.arm = Unknown implies (grantWrote[i] or grantNothing[i])
    }
    all i : WdIntent {
        i.arm = Committed implies wdWrote[i]
        i.arm = PreCommit implies wdNothing[i]
        i.arm = Unknown implies (wdWrote[i] or wdNothing[i])
    }
    all r : Retention | some r.rWrote
    all r : Retention | r.rstate = Retained
}

-- permissionRule: an administration action writes nothing before the permission check
-- answers permitted for its scope (Action wiring 1 through 3): an intent, a registration
-- event and an access event stand only for a permitted actor.
pred permissionRule {
    all i : GrantIntent | i.iActor -> ConsentGrant in Perms.may
    all i : WdIntent | i.iActor -> ConsentRevoke in Perms.may
    all r : RegCall | some r.rcEvent implies r.rcActor -> ConsentRegister in Perms.may
    all h : HistoryRead | some h.hEvent implies h.hActor -> ConsentRead in Perms.may
}

-- closeRule: the invocation close closes a committed arm alone (Recoverable Invocation commit
-- 4): the grant event carries the consent id and retention id the transaction answered
-- (Action wiring 17), the propagation event the consent id, the reason, the revocation
-- instant and the set derived at the intent's position (Action wiring 28, 41); the refuse
-- closes a pre-commit arm alone (Action wiring 8, 11, 12, 14, 35 through 39, 58), and an
-- unknown arm goes to the yield, which closes nothing (Action wiring 59, 60).
pred closeRule {
    all g : GrantEvent | g.by = ByClose implies {
        g.closes.arm = Committed
        g.geConsent = grantedBy.(g.closes)
        g.geRet = rWrote.(g.closes)
    }
    all e : PropEvent | e.by = ByClose implies {
        e.closes.arm = Committed
        e.peConsent = e.closes.wConsent
        e.peReason = e.closes.wReason
        e.peAt = e.closes.datum
        e.peSet = derived[e.closes.wConsent, e.closes]
    }
    all f : Refusal | f.closes.arm = PreCommit
}

-- sweepRule: the sweep writes an outcome only on its act probe's committed answer, carrying
-- what the probe re-derived (Recoverable Invocation act probe 6): the grant probe's one
-- matching record and the retention Retention Window's read holds over that consent id
-- (Term grant probe); the withdrawal probe's Revoked record — its reason and revocation
-- instant — and the set derived at the intent's own position (Term withdrawal probe).
pred sweepRule {
    all g : GrantEvent | g.by = BySweep implies {
        one grantMatch[g.closes]
        g.geConsent = grantMatch[g.closes]
        g.geRet = over.(g.geConsent)
    }
    all e : PropEvent | e.by = BySweep implies {
        wdProbeCommitted[e.closes]
        e.peConsent = e.closes.wConsent
        e.peReason = e.peConsent.reason
        e.peAt = e.peConsent.revokedAt
        e.peSet = derived[e.peConsent, e.closes]
    }
}

-- registerRule: a landed registration's event carries the call's consent id and pair (Action
-- wiring 21), and every registration event is one call's.
pred registerRule {
    all r : RegCall | some r.rcEvent implies {
        r.rcEvent.regConsent = r.rcConsent
        r.rcEvent.regPair = r.rcPair
    }
    all e : RegEvent | one rcEvent.e
}

-- indexRule: a call adds a binding only once its registration event lands, under the call's
-- consent id and pair (Action wiring 22, 25); a binding repair adds one from a registration
-- event's payload (Reconciliation 22); a binding carries the pair's first registration event
-- (Composition state 4, 5) and one consent holds one binding per pair (Composition state 3);
-- no binding is removed, so a pair whose registration event is purged stands bound
-- (Composition state 6, 13, 14); and the subject index holds a consent id only after its
-- grant event lands (Action wiring 24).
pred indexRule {
    all b : Binding | some b.bCall implies {
        b.bCall.rcConsent = b.bConsent
        b.bCall.rcPair = b.bPair
        some b.bCall.rcEvent
    }
    all b : Binding | no b.bCall implies some firstReg[b.bConsent, b.bPair]
    all b : Binding | b.bEvent = firstReg[b.bConsent, b.bPair]
    all c : Consent, p : Pair | lone (bConsent.c & bPair.p)
    all e : PurgedReg | some b : Binding | b.bConsent = e.regConsent and b.bPair = e.regPair
    all c : Idx.subj | some g : GrantEvent | g.geConsent = c
}

-- gateRule: the gate answers permitted where the consent check answers granted, and
-- not-permitted carrying the withheld state otherwise (Action wiring 55, 56).
pred gateRule {
    all q : GateQuery {
        -- DEFECT: a second read beside the consent check, the subject index.
        (q.qCheck = CGranted and some recordsOf[q.qSubj, q.qPurp] & Idx.subj)
            implies (q.qAns = Permitted and no q.qWithheld)
        not (q.qCheck = CGranted and some recordsOf[q.qSubj, q.qPurp] & Idx.subj)
            implies (q.qAns = NotPermitted and q.qWithheld = q.qCheck)
    }
}

-- historyRule: a fetched history read records the access event carrying the subject
-- reference (Action wiring 50), every access event is one read's, and the history is answered
-- only once its access event lands (Action wiring 51, 52).
pred historyRule {
    all h : HistoryRead | some h.hEvent implies h.hEvent.aSubj = h.hSubj
    all a : AccessEvent | one hEvent.a
    all h : Answered | some h.hEvent
}

-- conforms: every record in the state is one its writer's rules let it write.
pred conforms {
    commitRule
    permissionRule
    closeRule
    sweepRule
    registerRule
    indexRule
    gateRule
    historyRule
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Checks (one per single-state rule, named by the page's own label)
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: [Processing Permitted] answers permitted only where the consent check
-- answered granted at the query's instant.
assert A_Invariant_1_1 {
    conforms implies all q : GateQuery | q.qAns = Permitted implies q.qCheck = CGranted
}
check A_Invariant_1_1 for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- A_Invariant_3_1: every propagation event the close or the sweep wrote names a consent the
-- Consent records hold in Revoked (an operator's is detected, Check 3.10: the page's NOTE).
assert A_Invariant_3_1 {
    conforms implies all e : PropEvent | e.by in ByClose + BySweep implies
        e.peConsent.status = Revoked
}
check A_Invariant_3_1 for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- A_Invariant_3_2: no two propagation events the close or the sweep wrote carry one consent
-- id (an operator's second event is detected, Check 3.1).
assert A_Invariant_3_2 {
    conforms implies all disj e1, e2 : PropEvent |
        (e1.by + e2.by in ByClose + BySweep) implies e1.peConsent != e2.peConsent
}
check A_Invariant_3_2 for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- A_Invariant_3_3: a propagation event's set, the close's or the sweep's, equals the pairs of
-- every registration event of its consent preceding the event's boundary — the position of
-- the intent its intent event id names — a purged event's pair among them.
assert A_Invariant_3_3 {
    conforms implies all e : PropEvent | e.by in ByClose + BySweep implies
        e.peSet = registeredAt[e.peConsent, e.closes]
}
check A_Invariant_3_3 for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- A_Invariant_4_1: every binding carries a registration event carrying the binding's pair
-- and consent id.
assert A_Invariant_4_1 {
    conforms implies all b : Binding | some e : b.bEvent |
        e.regPair = b.bPair and e.regConsent = b.bConsent
}
check A_Invariant_4_1 for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- A_Invariant_5_1: the lifecycle resolves from the records: a Consent record a grant
-- invocation wrote carries its intent's subject reference, purpose and pairing datum as its
-- grant instant, and one a withdrawal invocation revoked carries its intent's consent id and
-- pairing datum as its revocation instant — the joins the probes and the leg read.
assert A_Invariant_5_1 {
    conforms implies all c : Consent {
        some c.grantedBy implies (c.grantedBy.gSubj = c.cSubj and c.grantedBy.gPurp = c.cPurp
                                  and c.grantedBy.datum = c.grantedAt)
        some c.revokedBy implies (c.revokedBy.wConsent = c and c.revokedBy.datum = c.revokedAt)
    }
}
check A_Invariant_5_1 for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- A_Invariant_6_1: every governed consent carries a consent retention in Retained, and every
-- consent retention carries Retained (Check 5.1, 5.2).
assert A_Invariant_6_1 {
    conforms implies {
        all c : Consent | some c.grantedBy implies
            (some r : Retention | r.over = c and r.rstate = Retained)
        all r : Retention | r.rstate = Retained
    }
}
check A_Invariant_6_1 for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- A_Invariant_7_1: no Consent write an invocation committed — a grant or a revoke — is for an
-- actor the permission check denied the action's scope.
assert A_Invariant_7_1 {
    conforms implies all c : Consent {
        some c.grantedBy implies c.grantedBy.iActor -> ConsentGrant in Perms.may
        some c.revokedBy implies c.revokedBy.iActor -> ConsentRevoke in Perms.may
    }
}
check A_Invariant_7_1 for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- A_Invariant_7_2: a validated gate query calls only the consent check, so two gate queries
-- whose consent check answered alike answer alike, whatever else the records hold.
assert A_Invariant_7_2 {
    conforms implies all disj q1, q2 : GateQuery | q1.qCheck = q2.qCheck implies
        (q1.qAns = q2.qAns and q1.qWithheld = q2.qWithheld)
}
check A_Invariant_7_2 for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- A_Invariant_8_3: no binding stands without the registration event at which Audit Trail
-- validated the caller's credential — every binding names a landed registration event.
assert A_Invariant_8_3 {
    conforms implies all b : Binding | one b.bEvent and b.bEvent in RegCall.rcEvent
}
check A_Invariant_8_3 for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- A_Invariant_8_4: no consent history is answered without the access event at which Audit
-- Trail validated the caller's credential.
assert A_Invariant_8_4 {
    conforms implies all h : Answered | some h.hEvent and h.hEvent.aSubj = h.hSubj
}
check A_Invariant_8_4 for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- A_Recoverable_Invocation_Invariant_5_3: an outcome the sweep writes carries only what the
-- act probe re-derived from the database — a grant event, the record carrying the intent's
-- key, grantor and pairing datum and a retention over that record, if any; a propagation
-- event, the intent's consent id with that record's reason and revocation instant and the
-- registered set at the intent's own position.
assert A_Recoverable_Invocation_Invariant_5_3 {
    conforms implies {
        all g : GrantEvent | g.by = BySweep implies {
            g.geConsent.cSubj = g.closes.gSubj
            g.geConsent.cPurp = g.closes.gPurp
            g.geConsent.grantor = g.closes.iActor
            g.geConsent.grantedAt = g.closes.datum
            g.geRet.over in g.geConsent
        }
        all e : PropEvent | e.by = BySweep implies {
            e.peConsent = e.closes.wConsent
            e.peReason = e.peConsent.reason
            e.peAt = e.peConsent.revokedAt
            e.peSet = registeredAt[e.peConsent, e.closes]
        }
    }
}
check A_Recoverable_Invocation_Invariant_5_3 for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ─────────────────────────────────────────────────────────────────────────────
-- Runs (each shape the page admits is reachable)
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowGrantLanded: a grant whose transaction committed, its grant event the close's carrying
-- the consent id and retention id, the subject index resolving it (walkthrough step 1).
run ShowGrantLanded {
    conforms
    some g : GrantEvent | g.by = ByClose and some g.geRet and g.geConsent in Idx.subj
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowWithdrawalLanded: a withdrawal closed by its close with its propagation set, and a
-- pair registered after the intent left out of it (walkthrough step 4, Cross-record
-- consistency 3).
run ShowWithdrawalLanded {
    conforms
    some e : PropEvent | e.by = ByClose and some e.peSet
        and some r : regConsent.(e.peConsent) | e.closes -> r in prec and r.regPair not in e.peSet
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowPurgedPairCarried: a propagation set carrying a pair whose registration event the
-- record read answers Purged, through its purged downstream entry (Composition state 13).
run ShowPurgedPairCarried {
    conforms
    some e : PropEvent, r : PurgedReg | e.by = ByClose and r.regConsent = e.peConsent
        and r.regPair in e.peSet
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowRegisteredUnbound: a landed registration whose binding was not yet written (the index
-- is outside the transaction, Composition state 8), its pair carried by the derivation from
-- the event all the same.
run ShowRegisteredUnbound {
    conforms
    some e : PropEvent, r : RegEvent | e.by = ByClose and r.regConsent = e.peConsent
        and r.regPair in e.peSet and no (bConsent.(e.peConsent) & bPair.(r.regPair))
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowSweepRecoversWithdrawal: a committed revoke whose close never landed, recovered by the
-- sweep from the Revoked record (the failure path).
run ShowSweepRecoversWithdrawal {
    conforms
    some e : PropEvent | e.by = BySweep and some e.peSet
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowSweepRecoversGrant: a committed grant whose close never landed, recovered by the sweep
-- from the one matching record with its retention.
run ShowSweepRecoversGrant {
    conforms
    some g : GrantEvent | g.by = BySweep and some g.geRet and g.closes.arm in Committed + Unknown
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowRetryRefused: a retried withdrawal refused already-revoked, its refusal record beside
-- the first withdrawal's propagation event (the already-revoked rejection path).
run ShowRetryRefused {
    conforms
    some disj i, j : WdIntent | i.wConsent = j.wConsent
        and some (closes.i & PropEvent) and some (closes.j & Refusal)
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowRetryLeftOpen: a retried withdrawal refused already-revoked whose refusal record did
-- not land: the intent stands open, the probe answers not-committed at its own datum, and no
-- second propagation event is written (Check 6.4).
run ShowRetryLeftOpen {
    conforms
    some disj i, j : WdIntent | i.wConsent = j.wConsent and i.arm = Committed
        and j.arm = PreCommit and no closes.j and some (closes.i & PropEvent)
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowReConsent: a re-consent — the pair's earlier record Revoked with its propagation
-- event, a later one Granted, and the gate permitting (the re-consent path).
run ShowReConsent {
    conforms
    some disj a, b : Consent | a.cSubj = b.cSubj and a.cPurp = b.cPurp
        and a.status = Revoked and b.status = Granted and some a.grantedBy and some b.grantedBy
        and some peConsent.a
    some q : GateQuery | q.qAns = Permitted
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowGateWithheld: the gate answering not-permitted carrying revoked, and one carrying
-- not-known (a subject who never consented).
run ShowGateWithheld {
    conforms
    some q : GateQuery | q.qWithheld = CRevoked
    some q : GateQuery | q.qWithheld = CNotKnown
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowTwoGrantedOneKey: two governed records Granted for one key — not excluded by one
-- state's rules; Invariant 1.3 holds by the consent check at the commit, the TLA+ model's.
run ShowTwoGrantedOneKey {
    conforms
    some disj a, b : Consent | a.cSubj = b.cSubj and a.cPurp = b.cPurp
        and a.status = Granted and b.status = Granted and some a.grantedBy and some b.grantedBy
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowDirectWrite: a Consent record no grant intent wrote and a revoke no withdrawal intent
-- made — writes outside every invocation (Composes 11, 12), the leg's to find.
run ShowDirectWrite {
    conforms
    some c : Consent | no c.grantedBy and c.status = Revoked and no c.revokedBy
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowOperatorSecondEvent: an operator's propagation event on a consent the close's event
-- already names — detected, not prevented (Invariant 3 NOTE; Check 3.1).
run ShowOperatorSecondEvent {
    conforms
    some disj e1, e2 : PropEvent | e1.by = ByClose and e2.by = ByOperator
        and e1.peConsent = e2.peConsent
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowOperatorEventOnGranted: an operator's propagation event naming a record still Granted
-- — detected by Check 3.10.
run ShowOperatorEventOnGranted {
    conforms
    some e : PropEvent | e.by = ByOperator and e.peConsent.status = Granted
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowSweepRecoversDirectGrant: FOUND 1 — a write outside every invocation at an open grant
-- intent's key, grantor and pairing datum is the grant probe's one match: the sweep recovers
-- a grant event for it carrying no retention id.
run ShowSweepRecoversDirectGrant {
    conforms
    some g : GrantEvent | g.by = BySweep and no g.geConsent.grantedBy and no g.geRet
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair

-- ShowHistoryAnswered: a history read answered beside its access event, and one whose access
-- event failed, unanswered.
run ShowHistoryAnswered {
    conforms
    some h : Answered | some h.hEvent
    some h : HistoryRead | no h.hEvent
} for 3 but 2 Subj, 2 Purp, 2 Actor, 2 Reason, 2 Pair
