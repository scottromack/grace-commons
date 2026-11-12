-- privileged-access-provisioning-buggy-decision-entry-unopened.als
-- DELIBERATELY WRONG twin of privileged-access-provisioning.als (unit:
-- `compositions/privileged-access-provisioning.md formal layer`).
--
-- INJECTED DEFECT: a chain evaluation after a committed rejection opens no pending entry
-- when Audit Trail refuses its denial event (Action wiring 7 dropped).
--
-- BREAKS: A_Invariant_7_1.
-- Everything else is privileged-access-provisioning.als as written; read its comments there.

module privileged_access_provisioning_buggy_decision_entry_unopened

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Mark: a yes on an optional field (present) or a no (absent).
one sig Mark {}

-- Actor: an actor or principal reference — a requestor, a deciding actor, a session's
-- principal.
sig Actor {}

-- V: an opaque value of an identity field (a resource reference, an access scope, a
-- justification, an instant).
sig V {}

-- Instant: a now reading the host injected at an invocation's seam (Capability requirement 23).
sig Instant {}

-- Reason: a reason a provisioning-failure event carries: ttl-elapsed, or a refusal Capability's
-- allocate relayed (Provisioning cascade 6, 7).
abstract sig Reason {}
one sig TtlElapsed extends Reason {}
sig Refusal extends Reason {}

-- IdField: the identity fields a request record carries beside the request id, the requestor
-- reference and the chain id (Term identity field).
abstract sig IdField {}
one sig FResource, FScope, FJustification, FRequestedAt, FExpiresAt extends IdField {}

-- RState: the request states (Term request state).
abstract sig RState {}
one sig Pending, Approved, Provisioned, Denied, Withdrawn, Revoked, ProvisioningFailed extends RState {}

-- CState: the chain states Multi-Party Approval's read chain answers.
abstract sig CState {}
one sig CPending, CApproved, CRejected, CWithdrawn extends CState {}

-- Chain: one chain in the approval substrate, with the state it stands in now.
sig Chain {
    cstate : one CState
}

-- VAnswer: what Credential's verify answered a decision action (Action wiring 1, 3).
abstract sig VAnswer {}
one sig Verified, FailedVerification extends VAnswer {}

-- SAnswer: what Session's validate answered an exercise (Action wiring 75, 76).
abstract sig SAnswer {}
one sig SValid, SInvalid extends SAnswer {}

-- RAnswer: what Capability's redeem answered: redeemed, or a redemption failure (Term
-- exercise failure, less recording-failure, which records nothing).
abstract sig RAnswer {}
one sig Redeemed extends RAnswer {}
abstract sig Failure extends RAnswer {}
one sig Exhausted, Expired, RevokedF, NotKnownF extends Failure {}

-- AllocAnswer: what Capability's allocate answered the provisioning cascade: the token, or
-- invalid-request (a storage-failure writes nothing, Provisioning cascade 15).
abstract sig AllocAnswer {}
one sig AToken, AInvalid extends AllocAnswer {}

-- Kind: the action reference of an event the composition records (Term value sets).
abstract sig Kind {}
one sig KRequest, KInitFail, KDecision, KProv, KDenial, KWithdrawal, KProvFail, KExercise,
    KFailedEx extends Kind {}

-- Inv: an invocation id the host injected (Capability requirement 29) — here, the writer that
-- carried it: a request, a decision action, a chain evaluation or an exercise.
abstract sig Inv {}

-- Req: one admitted [Request Access] and the request record it wrote; the request id is its
-- invocation id (Capability requirement 30). given is what the call supplied and its one now
-- stamped (a ghost of the call); idv is what the record stores now.
sig Req extends Inv {
    requestor : one Actor,
    given : IdField -> one V,
    idv : IdField -> lone V,
    chainId : lone Chain,
    state : one RState
}

-- Decision: one [Approve Step] or [Reject Step] invocation: its actor, whom Credential's
-- verify was called for and what it answered, and whether the decision reached the approval
-- substrate (routed).
sig Decision extends Inv {
    dreq : one Req,
    actor : one Actor,
    verifiedFor : lone Actor,
    verify : lone VAnswer,
    routed : lone Mark
}

-- Eval: one chain evaluation, with the provisioning cascade it fired. Ghosts: the chain state
-- read chain answered, the request state its transaction read, whether the provisioning
-- conjunction held, the decision action whose committed decision it follows (none for a
-- leg's run or a withdrawal's not-pending arm). The cascade's allocate answer, the remaining
-- ttl not exceeding zero, the refusal allocate relayed and the token's own deadline are
-- Capability's and the clock's. wrote is the request state it set.
sig Eval extends Inv {
    ereq : one Req,
    sawChain : one CState,
    sawReq : one RState,
    conj : lone Mark,
    follows : lone Decision,
    alloc : lone AllocAnswer,
    elapsed : lone Mark,
    relayed : lone Refusal,
    deadline : lone V,
    wrote : lone RState
}

-- Exercise: one [Exercise Access] invocation: what Session's validate answered and the
-- principal it named, the request the token's composed scope parses to (Capability's read),
-- the invocation's now and what Capability's redeem answered.
sig Exercise extends Inv {
    validate : one SAnswer,
    vprincipal : lone Actor,
    resolved : lone Req,
    now : one Instant,
    redeem : lone RAnswer
}

-- Ev: one event in the trail. src is the invocation id it carries (a recovery record carries
-- the owed record's, Reconciliation 15); rec marks a recovery record, read as the event it
-- names (Composition state 18). The data fields are the ones its kind carries.
sig Ev {
    kind : one Kind,
    src : one Inv,
    req : lone Req,
    rec : lone Mark,
    erequestor : lone Actor,
    sv : IdField -> lone V,
    echain : lone Chain,
    principal : lone Actor,
    at : lone Instant,
    fail : lone Failure,
    reason : lone Reason
}

-- Entry: one pending entry in a request's audit pending list: the action reference and the
-- invocation id of the record it owes and, once the act resolves, that record's data
-- (Composition state 31); open until the record lands (Composition state 32).
sig Entry {
    owner : one Req,
    ekind : one Kind,
    esrc : one Inv,
    isOpen : lone Mark,
    prequestor : lone Actor,
    psv : IdField -> lone V,
    pchain : lone Chain,
    pprincipal : lone Actor,
    pat : lone Instant,
    pfail : lone Failure,
    preason : lone Reason
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: only what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- Multi-Party Approval's terminal chain states stand (its own Invariant 7.1): a chain
-- evaluation that read a chain Approved, Rejected or Withdrawn read the state the chain still
-- stands in.
fact ChainTerminalStands {
    all e : Eval | e.sawChain != CPending implies e.sawChain = e.ereq.chainId.cstate
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- origs: the original events of kind k the invocation w recorded.
fun origs[w : Inv, k : Kind] : set Ev {
    { v : Ev | v.src = w and v.kind = k and no v.rec }
}

-- readings: every event of kind k carrying w's invocation id — originals and recovery records.
fun readings[w : Inv, k : Kind] : set Ev {
    { v : Ev | v.src = w and v.kind = k }
}

-- entriesOf: the pending entries owing w's record of kind k.
fun entriesOf[w : Inv, k : Kind] : set Entry {
    { n : Entry | n.esrc = w and n.ekind = k }
}

-- initKind: the record a request's initiation entry owes — the request event where the
-- record carries the chain id, the initiation-failed withdrawal event otherwise (Term
-- initiation entry).
fun initKind[r : Req] : Kind {
    (some r.chainId) => KRequest else KInitFail
}

-- failOf: the redemption failure an answer carries (none for redeemed).
fun failOf[a : RAnswer] : set Failure {
    a & Failure
}

-- deniedReason: the reason a provisioning-failure event carries — ttl-elapsed where the
-- remaining ttl did not exceed zero, the relayed refusal for another cause (Provisioning
-- cascade 6, 7).
fun deniedReason[e : Eval] : set Reason {
    (some e.elapsed) => TtlElapsed else e.relayed
}

-- provFields: the identity fields a provisioning event carries beside the request id and the
-- requestor reference (Provisioning cascade 8).
fun provFields : set IdField {
    FResource + FScope + FExpiresAt
}

-- quiescent: no pending entry is open (Term quiescence; every invocation here has committed).
pred quiescent {
    no n : Entry | some n.isOpen
}

-- landsOrEntry: the record lands, or Audit Trail refuses it and one entry carries it (Action
-- wiring 7, Provisioning cascade 13).
pred landsOrEntry[w : Inv, k : Kind] {
    lone origs[w, k]
    some origs[w, k] implies no entriesOf[w, k]
    no origs[w, k] implies one entriesOf[w, k]
}

-- entryAlways: one entry carries the record from the act's own transaction; it lands, and
-- the entry closes with it, or the entry stays (Action wiring 13, 21, 28, 29, 82, 91, 92;
-- Provisioning cascade 3).
pred entryAlways[w : Inv, k : Kind] {
    lone origs[w, k]
    one entriesOf[w, k]
    some origs[w, k] implies no entriesOf[w, k].isOpen
}

-- landsOrNothing: the record lands, or Audit Trail refuses it and no rule opens an entry for
-- it (Action wiring 120; Action wiring 7 reaches no record that follows no committed act).
pred landsOrNothing[w : Inv, k : Kind] {
    lone origs[w, k]
    no entriesOf[w, k]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writers: what each record may be
-- ─────────────────────────────────────────────────────────────────────────────

-- requestWrites: an admitted [Request Access] writes the request record from the call's
-- values (Action wiring 13; Capability requirement 25) with its initiation entry, and in the
-- same transaction either writes the chain id initiate chain answered and owes the request
-- event (Action wiring 17, 18, 27 through 29), or, initiate chain refused, owes the
-- initiation-failed withdrawal event and sets the request Withdrawn (Action wiring 19 through
-- 21). Either event carries the request shape. Its state afterwards is Pending or what a
-- chain evaluation set (Composition state 6).
pred requestWrites[r : Req] {
    r.idv = r.given                                                     -- Composition state 4
    entryAlways[r, initKind[r]]
    (src.r).kind + (esrc.r).ekind in initKind[r]
    all n : entriesOf[r, initKind[r]] |
        n.owner = r and n.prequestor = r.requestor and n.psv = r.given and n.pchain = r.chainId
    all v : origs[r, initKind[r]] |
        v.req = r and v.erequestor = r.requestor and v.sv = r.given and v.echain = r.chainId
    no r.chainId implies r.state = Withdrawn                             -- Action wiring 20
    some r.chainId implies {
        no (ereq.r).wrote implies r.state = Pending
        some (ereq.r).wrote implies r.state in (ereq.r).wrote
    }
}

-- decisionWrites: a decision action verifies the actor's credential first (Action wiring 1),
-- routes the decision only on verified and only for a request carrying a chain id (Action
-- wiring 2, 3, 31), and owes a decision event carrying the request id and the chain id,
-- landed or carried by an entry, since the decision committed (Action wiring 7, 39).
pred decisionWrites[d : Decision] {
    one d.verify
    d.verifiedFor = d.actor                                              -- Action wiring 1
    some d.routed implies (d.verify = Verified and some d.dreq.chainId)  -- Action wiring 2, 3, 31
    no d.routed implies (no src.d and no esrc.d)                         -- Action wiring 116
    some d.routed implies landsOrEntry[d, KDecision]
    (src.d).kind + (esrc.d).ekind in KDecision
    all v : origs[d, KDecision] | v.req = d.dreq and v.echain = d.dreq.chainId
    all n : entriesOf[d, KDecision] | n.owner = d.dreq and n.pchain = d.dreq.chainId
}

-- provArm: the evaluation read the chain Approved, the request open and the provisioning
-- conjunction holding (Action wiring 47, 48).
pred provArm[e : Eval] {
    e.sawChain = CApproved and e.sawReq in Pending + Approved and some e.conj
}

-- rejArm: the evaluation read the chain Rejected and the request Pending (Action wiring 53, 54).
pred rejArm[e : Eval] {
    e.sawChain = CRejected and e.sawReq = Pending
}

-- wdArm: the evaluation read the chain Withdrawn and the request Pending (Action wiring 55,
-- 56, 122).
pred wdArm[e : Eval] {
    e.sawChain = CWithdrawn and e.sawReq = Pending
}

-- evalWrites: a chain evaluation reads the request's chain on its chain id (Action wiring
-- 43). On Approved with the provisioning conjunction it fires the cascade (Action wiring 47,
-- 48): a token sets Provisioned and owes the provisioning event (Provisioning cascade 8, 10,
-- 13); invalid-request opens the entry owing the provisioning-failure event, records it with
-- the denial reason and sets ProvisioningFailed (Provisioning cascade 3 through 7). On
-- Rejected or Withdrawn against a Pending request it sets Denied or Withdrawn and owes the
-- denial or withdrawal event (Action wiring 53 through 56, 122) — carried by an entry only
-- where it follows a committed decision (Action wiring 7). Otherwise it writes nothing
-- (Action wiring 57, 58).
pred evalWrites[e : Eval] {
    some e.ereq.chainId                                                  -- Action wiring 43
    some e.follows implies (e.follows.dreq = e.ereq and some e.follows.routed) -- Action wiring 40
    provArm[e] implies {
        one e.alloc                                                      -- Provisioning cascade 2
        e.alloc = AToken implies {
            e.wrote = Provisioned                                        -- Provisioning cascade 10
            landsOrEntry[e, KProv]                                       -- Provisioning cascade 13
            (src.e).kind + (esrc.e).ekind in KProv
            all v : origs[e, KProv] |                                    -- Provisioning cascade 8
                v.req = e.ereq and v.erequestor = e.ereq.requestor and v.sv = provFields <: e.ereq.idv
            all n : entriesOf[e, KProv] |
                n.owner = e.ereq and n.prequestor = e.ereq.requestor and n.psv = provFields <: e.ereq.idv
        }
        e.alloc = AInvalid implies {
            e.wrote = ProvisioningFailed                                 -- Provisioning cascade 5
            some e.elapsed or some e.relayed                             -- Provisioning cascade 6, 7
            entryAlways[e, KProvFail]                                    -- Provisioning cascade 3, 4
            (src.e).kind + (esrc.e).ekind in KProvFail
            all v : origs[e, KProvFail] | v.req = e.ereq and v.reason = deniedReason[e]
            all n : entriesOf[e, KProvFail] | n.owner = e.ereq and n.preason = deniedReason[e]
        }
    }
    not provArm[e] implies no e.alloc                                    -- Wiring decision 3
    rejArm[e] implies {
        e.wrote = Denied                                                 -- Action wiring 54
        landsOrNothing[e, KDenial]                                       -- DEFECT
        (src.e).kind + (esrc.e).ekind in KDenial                         -- Action wiring 53
        all v : origs[e, KDenial] | v.req = e.ereq
        all n : entriesOf[e, KDenial] | n.owner = e.ereq
    }
    wdArm[e] implies {
        e.wrote = Withdrawn                                              -- Action wiring 56
        (some e.follows) => landsOrEntry[e, KWithdrawal] else landsOrNothing[e, KWithdrawal]
        (src.e).kind + (esrc.e).ekind in KWithdrawal                     -- Action wiring 55, 122
        all v : origs[e, KWithdrawal] | v.req = e.ereq
        all n : entriesOf[e, KWithdrawal] | n.owner = e.ereq
    }
    not (provArm[e] or rejArm[e] or wdArm[e]) implies               -- Action wiring 57, 58
        (no e.wrote and no src.e and no esrc.e)
}

-- exerciseWrites: an exercise validates the session first; a non-valid session writes nothing
-- (Action wiring 75 through 77). A valid one resolves the token: a token resolving to no
-- request records a failed exercise event carrying blank as the request id and not-known,
-- with no entry (Action wiring 79 through 81, 119, 120); a resolved one opens the exercise
-- entry carrying the session principal and the exercised instant, redeems, marks or completes
-- the entry, and records the exercise event or the failed exercise event carrying the request
-- id, the session principal, the exercised instant and redeemed or the redemption failure
-- (Action wiring 82, 85 through 92, 118, 121).
pred exerciseWrites[x : Exercise] {
    x.validate = SInvalid implies {
        no x.vprincipal and no x.resolved and no x.redeem and no src.x and no esrc.x
    }
    x.validate = SValid implies {
        one x.vprincipal
        no x.resolved implies {
            no x.redeem                                                  -- Action wiring 79
            landsOrNothing[x, KFailedEx]                                 -- Action wiring 120
            (src.x).kind in KFailedEx
            all v : origs[x, KFailedEx] | no v.req and v.fail = NotKnownF  -- Action wiring 80, 81
        }
        some x.resolved implies {
            one x.redeem                                                 -- Action wiring 85
            let k = (x.redeem = Redeemed) => KExercise else KFailedEx | {
                entryAlways[x, k]                                        -- Action wiring 82, 91, 92
                (src.x).kind + (esrc.x).ekind in k
                all n : entriesOf[x, k] |                                -- Action wiring 82, 86, 118, 121
                    n.owner = x.resolved and n.pprincipal = x.vprincipal and n.pat = x.now
                    and n.pfail = failOf[x.redeem]
                all v : origs[x, k] |                                    -- Action wiring 89, 90
                    v.req = x.resolved and v.principal = x.vprincipal and v.at = x.now
                    and v.fail = failOf[x.redeem]
            }
        }
    }
}

-- recoveryWrites: the reconciliation lands a recovery record only for an open pending entry
-- whose record the trail does not carry (Reconciliation 2, 4 through 6), carrying the owed
-- record's action reference, data and invocation id from the entry, never from an index
-- (Reconciliation 15, 16, 24, 29, 32).
pred recoveryWrites[v : Ev] {
    no origs[v.src, v.kind]
    some n : entriesOf[v.src, v.kind] {
        v.req = n.owner and v.erequestor = n.prequestor and v.sv = n.psv and v.echain = n.pchain
        v.principal = n.pprincipal and v.at = n.pat and v.fail = n.pfail and v.reason = n.preason
    }
}

-- conforms: every record in the state is one its writer's rules let it write; an entry
-- closes only once its record lands (Composition state 32); and the pre-check lands at most
-- one recovery record per owed record (Reconciliation 4 through 6).
pred conforms {
    all r : Req | requestWrites[r]
    all d : Decision | decisionWrites[d]
    all e : Eval | evalWrites[e]
    all x : Exercise | exerciseWrites[x]
    all v : Ev | some v.rec implies recoveryWrites[v]
    all n : Entry | no n.isOpen implies some readings[n.esrc, n.ekind]
    all disj v1, v2 : Ev | not (some v1.rec and some v2.rec and v1.src = v2.src and v1.kind = v2.kind)
}

-- noActDenialsLand: the premise of finding (a) — Audit Trail landed the denial event of every
-- chain evaluation that follows no committed load-bearing act and set a request Denied.
pred noActDenialsLand {
    all e : Eval | (no e.follows and e.wrote = Denied) implies some origs[e, KDenial]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the composition's writers can leave that violates
-- this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_3_1: every exercise event, original or recovered, comes from an invocation whose
-- Session validate answered valid.
assert A_Invariant_3_1 {
    conforms implies all v : Ev | v.kind = KExercise implies
        (v.src in Exercise and v.src.validate = SValid)
}
check A_Invariant_3_1 for 3 but 5 Inv, 6 Ev, 4 Entry

-- A_Invariant_3_2: every exercise event carries, as its session principal reference, the
-- principal reference its invocation's validate answered.
assert A_Invariant_3_2 {
    conforms implies all v : Ev | v.kind = KExercise implies
        (one v.principal and v.principal = v.src.vprincipal)
}
check A_Invariant_3_2 for 3 but 5 Inv, 6 Ev, 4 Entry

-- A_Invariant_6_1: every decision a decision action routed, or whose decision event the trail
-- carries, followed a Credential verify in its invocation that answered verified for the
-- deciding actor.
assert A_Invariant_6_1 {
    conforms implies all d : Decision | (some d.routed or some readings[d, KDecision]) implies
        (d.verify = Verified and d.verifiedFor = d.actor)
}
check A_Invariant_6_1 for 3 but 5 Inv, 6 Ev, 4 Entry

-- A_Invariant_7_1: at quiescence every Denied request carries a denial event (under the
-- premise of finding (a)).
assert A_Invariant_7_1 {
    (conforms and quiescent and noActDenialsLand) implies
        all r : Req | r.state = Denied implies some v : Ev | v.req = r and v.kind = KDenial
}
check A_Invariant_7_1 for 3 but 5 Inv, 6 Ev, 4 Entry

-- A_Invariant_7_2: every Denied request names a chain whose state is Rejected.
assert A_Invariant_7_2 {
    conforms implies all r : Req | r.state = Denied implies r.chainId.cstate = CRejected
}
check A_Invariant_7_2 for 3 but 5 Inv, 6 Ev, 4 Entry

-- A_Invariant_7_3: at quiescence every ProvisioningFailed request carries a
-- provisioning-failure event, from the cascade that failed it, carrying the denial reason
-- that cascade's allocate answer gives.
assert A_Invariant_7_3 {
    (conforms and quiescent) implies all r : Req | r.state = ProvisioningFailed implies
        some e : ereq.r, v : Ev | e.wrote = ProvisioningFailed and v.src = e
            and v.kind = KProvFail and v.req = r and v.reason = deniedReason[e]
}
check A_Invariant_7_3 for 3 but 5 Inv, 6 Ev, 4 Entry

-- A_Invariant_8_1: a request's identity fields are the ones written once: the record holds
-- what its shape-bearing event carries, a provisioning event carries the record's requestor,
-- resource, scope and expiry, and a decision event the record's chain id.
assert A_Invariant_8_1 {
    conforms implies all r : Req, v : req.r {
        v.kind in KRequest + KInitFail implies
            (v.erequestor = r.requestor and v.sv = r.idv and v.echain = r.chainId)
        v.kind = KProv implies (v.erequestor = r.requestor and v.sv = provFields <: r.idv)
        v.kind = KDecision implies v.echain = r.chainId
    }
}
check A_Invariant_8_1 for 3 but 5 Inv, 6 Ev, 4 Entry

-- A_Invariant_10_1: no exercise event is changed: every reading of an exercise's exercise
-- event carries the request, the session principal, the exercised instant and redeemed its
-- exercise fixed.
assert A_Invariant_10_1 {
    conforms implies all x : Exercise, v : readings[x, KExercise] |
        v.req = x.resolved and v.principal = x.vprincipal and v.at = x.now and no v.fail
}
check A_Invariant_10_1 for 3 but 5 Inv, 6 Ev, 4 Entry

-- A_Invariant_10_2: no failed exercise event of a resolved exercise is changed: every reading
-- carries the request, the session principal, the exercised instant and the redemption
-- failure its exercise fixed.
assert A_Invariant_10_2 {
    conforms implies all x : Exercise, v : readings[x, KFailedEx] | some x.resolved implies
        (v.req = x.resolved and v.principal = x.vprincipal and v.at = x.now
            and v.fail = failOf[x.redeem])
}
check A_Invariant_10_2 for 3 but 5 Inv, 6 Ev, 4 Entry

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowHappyPath: the happy path — a routed, verified approval, the cascade provisioning the
-- request, and an exercise under a valid session recording its exercise event.
run ShowHappyPath {
    conforms
    some d : Decision, e : Eval, x : Exercise {
        some d.routed and d.dreq = e.ereq
        e.wrote = Provisioned and e.ereq.state = Provisioned
        x.resolved = e.ereq and x.redeem = Redeemed and some origs[x, KExercise]
    }
} for 3 but 5 Inv, 6 Ev, 4 Entry

-- ShowRejectedDenied: the rejection path — the chain evaluation after a routed rejection finds
-- the chain Rejected and lands the request Denied with its denial event, at quiescence.
run ShowRejectedDenied {
    conforms and quiescent
    some e : Eval | some e.follows and e.wrote = Denied and e.ereq.state = Denied
        and some origs[e, KDenial]
} for 3 but 5 Inv, 6 Ev, 4 Entry

-- ShowSessionInvalid: the session-invalid path — a provisioned request, and an exercise whose
-- session validate refused, which writes nothing.
run ShowSessionInvalid {
    conforms
    some r : Req, x : Exercise | r.state = Provisioned and x.validate = SInvalid
} for 3 but 5 Inv, 6 Ev, 4 Entry

-- ShowForgedToken: the forged-token path — a valid session presenting a token that resolves
-- to no request, recorded as a failed exercise event carrying blank as the request id.
run ShowForgedToken {
    conforms
    some x : Exercise | x.validate = SValid and no x.resolved and some origs[x, KFailedEx]
} for 3 but 5 Inv, 6 Ev, 4 Entry

-- ShowExerciseRecovered: an exercise event Audit Trail refused, its entry left open, and the
-- redemption leg's recovery record standing for it, the entry closed (Reconciliation 24).
run ShowExerciseRecovered {
    conforms and quiescent
    some x : Exercise | x.redeem = Redeemed and no origs[x, KExercise]
        and some readings[x, KExercise]
} for 3 but 5 Inv, 6 Ev, 4 Entry

-- ShowFailedExerciseRecovered: a redemption failure whose failed exercise event Audit Trail
-- refused, recovered from its open entry (Reconciliation 29).
run ShowFailedExerciseRecovered {
    conforms and quiescent
    some x : Exercise | some x.resolved and x.redeem in Failure and no origs[x, KFailedEx]
        and some readings[x, KFailedEx]
} for 3 but 5 Inv, 6 Ev, 4 Entry

-- ShowTtlElapsedFailure: the cascade's allocate refusing a lapsed request, recorded with
-- ttl-elapsed, at quiescence.
run ShowTtlElapsedFailure {
    conforms and quiescent
    some e : Eval | e.wrote = ProvisioningFailed and some e.elapsed and some e.relayed
        and some readings[e, KProvFail] and e.ereq.state = ProvisioningFailed
} for 3 but 5 Inv, 6 Ev, 4 Entry

-- ShowLegProvisioningFailureOwed: a cascade the approval leg fired (no committed act) whose
-- provisioning-failure event Audit Trail refused, carried by its open entry.
run ShowLegProvisioningFailureOwed {
    conforms
    some e : Eval | no e.follows and e.alloc = AInvalid and no origs[e, KProvFail]
        and some entriesOf[e, KProvFail].isOpen
} for 3 but 5 Inv, 6 Ev, 4 Entry

-- ShowInitiationRefused: initiate chain refused — the record carries no chain id, the
-- initiation-failed withdrawal event carries the request shape, and the request is Withdrawn.
run ShowInitiationRefused {
    conforms
    some r : Req | no r.chainId and some origs[r, KInitFail]
} for 3 but 5 Inv, 6 Ev, 4 Entry

-- ShowDenialOwedAfterDecision: a denial event Audit Trail refused after a committed rejection,
-- carried by its open entry (Action wiring 7): the request is Denied, not yet quiescent.
run ShowDenialOwedAfterDecision {
    conforms
    some e : Eval | some e.follows and e.wrote = Denied and no origs[e, KDenial]
        and some entriesOf[e, KDenial].isOpen
} for 3 but 5 Inv, 6 Ev, 4 Entry

-- ShowUnrecordedDenial: finding (a) — a chain evaluation that follows no committed act (a
-- leg's run, a withdrawal's not-pending arm) whose denial event Audit Trail refused: the
-- request stands Denied with no denial event and no open entry, at quiescence.
run ShowUnrecordedDenial {
    conforms and quiescent
    some r : Req | r.state = Denied and no v : Ev | v.req = r and v.kind = KDenial
} for 3 but 5 Inv, 6 Ev, 4 Entry
