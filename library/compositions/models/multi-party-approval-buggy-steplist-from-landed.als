-- multi-party-approval-buggy-steplist-from-landed.als
-- DELIBERATELY WRONG twin of multi-party-approval.als (unit: compositions/multi-party-approval.md formal layer).
--
-- INJECTED DEFECT: the initiation writes the chain record's landed ids, step ids and assignment ids together, as the step list entry (Action wiring 8).
--
-- BREAKS: A_Invariant_1_3.
-- Everything else is multi-party-approval.als as written; read its comments there.

module multi_party_approval_buggy_steplist_from_landed

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Actor: an actor reference — an initiator, an approver reference, an assignee, a decider,
-- an operator.
sig Actor {}

-- RecoveryId: the recovery identity, application_actor_ref, under which Recoverable
-- Invocation's sweep attests every write it makes for the five act kinds (Term recovery
-- identity).
one sig RecoveryId extends Actor {}

-- Subject: an opaque subject reference (Term subject reference), compared byte-exact.
sig Subject {}

-- Scope: the subject's approval scope (Term scope).
sig Scope {}

-- Rule: a quorum rule with its quorum count, compared whole (Term quorum rule).
sig Rule {}

-- Now: an instant — the now one invocation stamps (Capability requirement 19, 23). Compared
-- for equality only.
sig Now {}

-- St: a chain state (Term chain state), which is also an Approval Step's state.
abstract sig St {}
one sig Pending, Approved, Rejected, Withdrawn extends St {}

-- Kind: the five act kinds (Term act kind), one per state-changing action.
abstract sig Kind {}
one sig KInit, KAppr, KRej, KSWd, KWd extends Kind {}

-- Writer: who wrote an outcome — the invocation's close, Recoverable Invocation's sweep, or
-- an operator through the invocation resolve (Term outcome).
abstract sig Writer {}
one sig ByInv, BySweep, ByOper extends Writer {}

-- Path: the terminal path a terminal summary names (Term terminal summary).
abstract sig Path {}
one sig ResolutionPath, WithdrawalPath extends Path {}

-- AStatus: an assignment's status (Assignment's).
abstract sig AStatus {}
one sig Active, Recalled extends AStatus {}

-- Slot: one approver slot of a chain's approver set, naming its approver reference (Term
-- approver set). Two slots may name one approver where the approver set uniqueness is off.
sig Slot {
    slotAppr : one Actor
}

-- Minted: an id a constituent mints — a step id or an assignment id (Term minted id; the
-- chain id is the host's). The landed ids carry both kinds.
abstract sig Minted {}

-- Step: one Approval Step record: its subject reference, approver reference, submitter,
-- scope, the chain id its stored reason's prefix carries (Term prefixed reason), its state,
-- its decider and decision or withdrawal instant; and — ghosts — the initiation intent whose
-- committed transaction submitted it (none: submitted outside the composition) and its slot.
sig Step extends Minted {
    ssubj   : one Subject,
    sappr   : one Actor,
    ssub    : one Actor,
    sscope  : one Scope,
    sreason : lone Chain,
    sst     : one St,
    sdec    : lone Actor,
    sdat    : lone Now,
    sby     : lone Intent,
    sslot   : lone Slot
}

-- Asg: one Assignment record: its task (a step id), its assignee and its status.
sig Asg extends Minted {
    task     : one Step,
    assignee : one Actor,
    astatus  : one AStatus
}

-- Chain: a chain id, with the fields of its chain record where the chain records carry one
-- (Stored): the declared fields (subject reference, scope, initiator reference, approver set,
-- quorum rule, initiated instant, the initiation's invocation id), the chain state, the
-- terminal summary (terminal instant, path, terminating invocation, cascade-withdrawn step
-- ids) and the landed ids (Composition state 2, Term declared fields). An invocation is
-- named by its intent.
sig Chain {
    csubj   : one Subject,
    cscope  : one Scope,
    cinit   : one Actor,
    cslots  : set Slot,
    crule   : one Rule,
    ciat    : one Now,
    ciinv   : lone Intent,
    cst     : one St,
    ctat    : lone Now,
    cpath   : lone Path,
    ctinv   : lone Intent,
    ccwd    : set Step,
    clanded : set Minted
}

-- Stored: the chain ids the chain records carry a record for (chain_store). The composition
-- never removes one (Composition state 8).
sig Stored in Chain {}

-- Ev: one Event Log event of the chain namespace, with its Event Log sequence number.
abstract sig Ev {
    sn : one Int
}

-- Intent: an intent the invocation open wrote (Term intent): its act kind, the chain id its
-- act key carries, the step id for a decision key, the caller and the pairing datum.
-- iwrote is a ghost: the chain state a terminating commit wrote (its evaluation's answer, or
-- Withdrawn).
sig Intent extends Ev {
    kind   : one Kind,
    ichain : one Chain,
    istep  : lone Step,
    actor  : one Actor,
    datum  : one Now,
    iwrote : lone St
}

-- Committed: the intents whose commit wrote (Term commit partition: committed). A ghost.
sig Committed in Intent {}

-- Refused: the intents whose commit answered a pre-commit arm, closed by the invocation
-- refuse. A ghost.
sig Refused in Intent {}

-- Trailing: the decision intents carrying the trailing flag (Term trailing flag).
sig Trailing in Intent {}

-- Terminating: the intents whose commit moved their chain out of Pending (Term terminating
-- act). A ghost.
sig Terminating in Intent {}

-- Outcome: an outcome (Term outcome): the intent it closes, who wrote it and the actor its
-- attestation names; the terminal summary it carries (state, terminal instant, terminating
-- invocation), and for an initiation event the chain shape (Composition state 4, 6).
sig Outcome extends Ev {
    oi     : one Intent,
    oby    : one Writer,
    att    : one Actor,
    ost    : lone St,
    otat   : lone Now,
    otinv  : lone Intent,
    osubj  : lone Subject,
    oscope : lone Scope,
    oslots : set Slot,
    orule  : lone Rule,
    oiat   : lone Now,
    osteps : set Minted
}

-- Refusal: a refusal record (Term refusal record) for the intent it closes.
sig Refusal extends Ev {
    ri : one Intent
}

-- Abandon: the abandoned record Recoverable Invocation derives under the intent's kind — the
-- sweep's on a not-committed probe, or an operator's.
sig Abandon extends Ev {
    ai : one Intent
}

-- Escalate: the escalated record Recoverable Invocation derives under the intent's kind; the
-- intent stays open for an operator.
sig Escalate extends Ev {
    xi : one Intent
}

-- Purged: the events the record read answers Purged (Retention Window's). An input.
sig Purged in Ev {}

-- Aged: the aged chains (Term aged chains): the clock's; an input.
sig Aged in Chain {}

-- Oob: the steps decided by an out-of-band transition (Term out-of-band transition): a
-- decision written around the composition, with no intent. A ghost.
sig Oob in Step {}

-- Idx: three of the derived indexes as stored: the step list index, the step-chain index
-- and the step-assignment index, and the event index (Composition state 1).
one sig Idx {
    slist : Chain -> Minted,
    s2c   : Minted -> lone Chain,
    s2a   : Step -> lone Asg,
    eidx  : Chain -> Ev
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers: the page's terms over one state
-- ─────────────────────────────────────────────────────────────────────────────

-- retained: the events the record read answers Retained.
fun retained : set Ev { Ev - Purged }

-- intentOf: the intent an event is or closes.
fun intentOf[e : Ev] : set Intent { (e & Intent) + e.oi + e.ri + e.ai + e.xi }

-- chainOf: the chain id an event's act key carries (Composition state 3).
fun chainOf[e : Ev] : set Chain { intentOf[e].ichain }

-- chainEvents: the chain namespace events naming the chain.
fun chainEvents[c : Chain] : set Ev { { e : Ev | chainOf[e] = c } }

-- stepsOf: the steps the chain's initiation transaction submitted, one per approver slot.
fun stepsOf[c : Chain] : set Step { sby.(c.ciinv) }

-- asgOf: the assignments whose task is the step (Assignment's history_for, Term assignment
-- history).
fun asgOf[s : Step] : set Asg { task.s }

-- decisionKinds: the three decision kinds.
fun decisionKinds : set Kind { KAppr + KRej + KSWd }

-- stateOf: the Approval Step state a decision kind's step write leaves.
fun stateOf[k : Kind] : one St { (k = KAppr) => Approved else ((k = KRej) => Rejected else Withdrawn) }

-- counted: the committed decisions the chain evaluation counts — committed while the chain
-- was Pending, so not trailing (Action wiring 30, 65; Term routed vector).
fun counted : set Intent { (Committed - Trailing) & kind.decisionKinds }

-- stillPending: a terminal chain's steps the routed vector counted as Pending at the
-- terminating commit (Term still-Pending step): every step no counted decision decided,
-- one decided out of band among them.
fun stillPending[c : Chain] : set Step { stepsOf[c] - counted.istep }

-- quiescent: no open intent on the chain (Term quiescent chains): every intent naming it is
-- closed by an outcome, a refusal record or an abandonment; an escalated intent stays open.
pred quiescent[c : Chain] {
    all i : ichain.c | some (oi.i + ri.i + ai.i)
}

-- invReturned: the event ids the invocation open, close and refuse return, which the
-- composition writes into the event index (Action wiring 57).
fun invReturned : set Ev { Intent + oby.ByInv + Refusal }

-- chainless: a Pending step whose subject reference, submitter and scope equal the chain's,
-- whose stored reason carries the chain's id, and which no chain record's landed ids name
-- (Term chainless step).
pred chainless[s : Step, c : Chain] {
    s.sst = Pending and s.ssubj = c.csubj and s.ssub = c.cinit and s.sscope = c.cscope
    and s.sreason = c and s not in Stored.clanded
}

-- initShape: an initiation event carries the chain shape the chain record holds: the
-- declared fields with the step ids (Term chain shape).
pred initShape[o : Outcome, c : Chain] {
    o.osubj = c.csubj and o.oscope = c.cscope and o.oslots = c.cslots and o.orule = c.crule
    and o.oiat = c.ciat and o.osteps = stepsOf[c]
}

-- noShape: an outcome other than an initiation event carries no chain shape.
pred noShape[o : Outcome] {
    no o.osubj and no o.oscope and no o.oslots and no o.orule and no o.oiat and no o.osteps
}

-- noSummary: an outcome that carries no terminal summary.
pred noSummary[o : Outcome] { no o.ost and no o.otat and no o.otinv }

-- invData: what the invocation's close writes: an initiation event the chain shape its
-- commit wrote (Action wiring 14); a decision's outcome the terminal summary where its
-- commit terminated the chain (Action wiring 29); a withdrawal event the terminal summary
-- (Action wiring 49).
pred invData[o : Outcome] {
    o.oi.kind = KInit implies (initShape[o, o.oi.ichain] and noSummary[o]) else noShape[o]
    o.oi.kind != KInit implies
        ((o.oi in Terminating) => (o.ost = o.oi.iwrote and o.otat = o.oi.datum and o.otinv = o.oi)
         else noSummary[o])
}

-- faithful: what an act probe answers committed with — the record its pairing datum finds,
-- read now: the chain shape the chain record holds; the terminal summary where the chain
-- record's names the intent's invocation (Term initiation probe, decision probe, withdrawal
-- probe).
pred faithful[o : Outcome] {
    o.oi in Committed
    o.oi.kind = KInit implies (initShape[o, o.oi.ichain] and noSummary[o]) else noShape[o]
    o.oi.kind != KInit implies
        ((o.oi.ichain.ctinv = o.oi)
            => (o.ost = o.oi.ichain.cst and o.otat = o.oi.ichain.ctat and o.otinv = o.oi)
          else noSummary[o])
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- Event Log numbers each event with its own sequence number (Event Log Invariant 3).
fact EventLogSequence {
    all disj e1, e2 : Ev | e1.sn != e2.sn
}

-- Retention Window purges the oldest events first: an event older than a Purged one is
-- Purged.
fact PurgeOldestFirst {
    all e : Purged, e2 : Ev | e2.sn < e.sn implies e2 in Purged
}

-- The clock's edge: a chain that is not aged has every event inside the retention horizon,
-- so none is Purged (Term aged chains).
fact HorizonEdge {
    all e : Ev | chainOf[e] not in Aged implies e not in Purged
}

-- The host never injects an equal now into two invocations of one act key (Capability
-- requirement 38, the host's obligation).
fact FreshNowPerActKey {
    all disj i, j : Intent | (i.kind = j.kind and i.ichain = j.ichain and i.istep = j.istep)
        implies i.datum != j.datum
}

-- No caller acts under the recovery identity: it attests only the sweep's writes
-- (Recoverable Invocation service identity 3; Capability requirement 12).
fact RecoveryIdentityIsNoCaller {
    no Intent.actor & RecoveryId
}

-- Recoverable Invocation closes an intent once between the invocation and the sweep, the
-- sweep only an intent the invocation did not close, and an abandonment only an intent no
-- outcome of theirs closed; an operator's resolve closes only an intent neither closed
-- (Recoverable Invocation commit 4, reconcile, resolve).
fact RecoverableInvocationClosing {
    all i : Intent | lone (oi.i & oby.(ByInv + BySweep))
    all i : Intent | some (oi.i & oby.ByInv) implies no (ai.i + xi.i)
    all i : Intent | some (oi.i & oby.(ByInv + BySweep)) implies no ai.i
    all o : oby.ByOper | no (oi.(o.oi) & oby.(ByInv + BySweep))
    all o : oby.BySweep | o.att = RecoveryId
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Part A — the records: what each admitted write leaves
-- ─────────────────────────────────────────────────────────────────────────────

-- initWiring: an initiation transaction commits whole or not at all (Action wiring 9, 12;
-- Execution Contract Database 1). A committed one wrote its chain record carrying its
-- caller as the initiator and its now as the initiated instant (Action wiring 6, Capability
-- requirement 23); one submit per approver slot with the chain's subject reference, scope,
-- the slot's approver reference, the initiator as submitter and the prefixed reason (Action
-- wiring 7); one assign per step id to its approver (Action wiring 10); the step ids and
-- assignment ids appended to the landed ids (Action wiring 8, 11). A chain id no committed
-- initiation wrote carries no record. Every assignment is an initiation's (Composes 18: no
-- reassign).
pred initWiring {
    all c : Stored | some c.ciinv and c.ciinv in Committed and c.ciinv.kind = KInit
        and c.ciinv.ichain = c and c.cinit = c.ciinv.actor and c.ciat = c.ciinv.datum
    all i : Committed & kind.KInit | i.ichain in Stored and i.ichain.ciinv = i
    all c : Chain - Stored | no c.ciinv and no c.cslots and no c.clanded
    all s : Slot | lone cslots.s
    all c : Stored, s : c.cslots | one st : stepsOf[c] | st.sslot = s
    all st : Step | some st.sby implies {
        st.sby in Committed & kind.KInit
        st.sslot in st.sby.ichain.cslots
        st.ssubj = st.sby.ichain.csubj
        st.sscope = st.sby.ichain.cscope
        st.sappr = st.sslot.slotAppr
        st.ssub = st.sby.ichain.cinit
        st.sreason = st.sby.ichain
        one asgOf[st]
        asgOf[st].assignee = st.sappr
    }
    all st : Step | no st.sby implies no st.sslot
    all a : Asg | some a.task.sby
    all c : Stored | c.clanded = stepsOf[c] + asgOf[stepsOf[c]]
}

-- decisionWiring: a decision resolves its step under its chain through the step-chain index
-- ahead of the open (Action wiring 17). A committed decision's step write moved the step out
-- of Pending, by the named approver for an approval or rejection and the submitter for a
-- withdrawal, stamping the invocation's now (Action wiring 21, 59 through 61; Capability
-- requirement 37; Approval Step's guarantee). A step leaves Pending once: by one committed
-- decision, the cascade, or a decision written around the composition. A trailing decision
-- commits only on a terminal chain and terminates nothing (Action wiring 18, 31, 65).
pred decisionWiring {
    all i : Intent | i.kind in decisionKinds iff some i.istep
    all i : Intent | some i.istep implies i.istep in stepsOf[i.ichain]
    all i : Committed | some i.istep implies {
        i.istep.sst = stateOf[i.kind]
        i.istep.sdec = i.actor
        i.istep.sdat = i.datum
        i.kind in KAppr + KRej implies i.actor = i.istep.sappr
        i.kind = KSWd implies i.actor = i.istep.ssub
    }
    all s : Step | lone (Committed & istep.s)
    all s : Oob | s.sst != Pending and no (Committed & istep.s) and s not in Stored.ccwd
    all s : Step | s.sst = Pending iff (no (Committed & istep.s) and s not in Stored.ccwd and s not in Oob)
    all s : Step | s.sst = Pending implies (no s.sdec and no s.sdat)
    Trailing in kind.decisionKinds
    all i : Committed & Trailing | i.ichain.cst != Pending and i not in Terminating
}

-- withdrawalWiring: [Withdraw Chain] opens only on a chain the chain records carry, by its
-- initiator (Action wiring 41, 45).
pred withdrawalWiring {
    all i : kind.KWd | i.ichain in Stored and i.actor = i.ichain.cinit
}

-- terminalWiring: a committed chain withdrawal and a counted decision whose evaluation
-- answered a terminal state are terminating; the re-reads inside the decision and withdrawal
-- transactions let one commit move a chain out of Pending (Action wiring 34, 65, 66, 67). The
-- chain record carries that commit: its state, its now as the terminal instant, its path
-- and its invocation (Action wiring 35, 38, 47, 70; Term terminal summary).
pred terminalWiring {
    Terminating in Committed
    all i : Terminating | i.kind = KWd or i in counted
    all i : Committed & kind.KWd | i in Terminating and i.iwrote = Withdrawn
    all i : Terminating & counted | i.iwrote in Approved + Rejected + Withdrawn
    all i : Intent - Terminating | no i.iwrote
    all c : Chain | lone (Terminating & ichain.c)
    all c : Chain - Stored | no (Terminating & ichain.c)
    all c : Chain | no (Terminating & ichain.c) implies
        (c.cst = Pending and no c.ctat and no c.cpath and no c.ctinv)
    all c : Chain | some (Terminating & ichain.c) implies {
        c.ctinv in Terminating & ichain.c
        no t : Terminating & ichain.c | t.sn > c.ctinv.sn
        c.cst = c.ctinv.iwrote
        c.ctat = c.ctinv.datum
        c.cpath = ((c.ctinv.kind = KWd) => WithdrawalPath else ResolutionPath)
    }
}

-- cascadeWiring: a terminating commit runs the cascade over the chain's still-Pending steps
-- (Cascade 1, 2): on a Withdrawn chain it withdraws each step Approval Step still holds
-- Pending, with the initiator as withdrawer at the terminal instant, naming it among the
-- cascade-withdrawn step ids; a step decided out of band answers not-pending and is
-- superseded (Cascade 10). A Pending chain has run no cascade.
pred cascadeWiring {
    all c : Chain | (c.cst = Withdrawn) => c.ccwd = stillPending[c] - Oob else no c.ccwd
    all c : Chain, s : c.ccwd | s.sst = Withdrawn and s.sdec = c.cinit and s.sdat = c.ctat
}

-- recallWiring: an assignment is recalled by the decided decision on its step (Action wiring
-- 24) or by a terminating commit's cascade on a still-Pending step (Cascade 1), and by
-- nothing else of the composition.
pred recallWiring {
    all a : Asg | a.astatus = Recalled iff
        (a.task in Committed.istep or (some c : Chain - cst.Pending | a.task in stillPending[c]))
}

-- outcomeWiring: the invocation closes only a committed act, attested under its caller,
-- carrying what its commit wrote (Action wiring 14, 29, 49); the sweep's probe answers
-- committed with the record it finds (the probes); an operator's outcome is any. The
-- invocation refuses only a pre-commit arm, once.
pred outcomeWiring {
    all o : oby.ByInv | o.oi in Committed and o.att = o.oi.actor and invData[o]
    all o : oby.BySweep | faithful[o]
    no Committed & Refused
    all r : Refusal | r.ri in Refused
    all i : Intent | lone ri.i
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Part B — the indexes: stored, rebuilt, and after a rebuild
-- ─────────────────────────────────────────────────────────────────────────────

-- indexWiring: the step list entry is written inside the initiation transaction (Action
-- wiring 8); a step-chain or step-assignment entry likewise, and may since have been lost —
-- a lost entry is a rebuild trigger (Composition state 21); the event index holds event ids
-- the open, close and refuse returned (Action wiring 57), any of them lost.
pred indexWiring {
    all c : Chain | Idx.slist[c] = c.clanded
    all x : Minted | some Idx.s2c[x] implies (x in Step and some x.sby and Idx.s2c[x] = x.sby.ichain)
    all s : Step | some Idx.s2a[s] implies Idx.s2a[s] = asgOf[s]
    all c : Chain | Idx.eidx[c] in invReturned & chainEvents[c]
}

-- shapeEvs: the chain's chain-shape events the log read finds (Term chain-shape event: the
-- invocation's, the sweep's or an operator's initiation event).
fun shapeEvs[c : Chain] : set Outcome {
    { o : Outcome & retained | o.oi.kind = KInit and o.oi.ichain = c }
}

-- firstShape: the one the rebuild binds, the first by sequence number (Composition state 24).
fun firstShape[c : Chain] : set Outcome {
    { o : shapeEvs[c] | no o2 : shapeEvs[c] | o2.sn < o.sn }
}

-- produced: the chain rebuild produces a record for the chain.
pred produced[c : Chain] { some shapeEvs[c] }

-- termEvs: the chain's terminal events the log read finds (Term terminal event).
fun termEvs[c : Chain] : set Outcome {
    { o : Outcome & retained | o.oi.ichain = c and some o.ost }
}

-- firstTerm: the terminal event the rebuild binds, the first by sequence number.
fun firstTerm[c : Chain] : set Outcome {
    { o : termEvs[c] | no o2 : termEvs[c] | o2.sn < o.sn }
}

-- carried: the chains the chain records carry: those stored, and those the chain rebuild
-- produces (Composition state 12, 13).
fun carried : set Chain { Stored + { c : Chain | produced[c] } }

-- rbInit: the initiator the chain rebuild records — the initiation intent's actor (Term
-- chain rebuild).
fun rbInit[c : Chain] : set Actor { firstShape[c].oi.actor }

-- afterSubj, afterScope, afterInit, afterSlots, afterRule, afterIat, afterIinv: the declared
-- fields after a rebuild: the produced record's, from its chain-shape event; a record the
-- rebuild does not produce retained (Composition state 13).
fun afterSubj[c : Chain] : set Subject { produced[c] => firstShape[c].osubj else c.csubj }
fun afterScope[c : Chain] : set Scope { produced[c] => firstShape[c].oscope else c.cscope }
fun afterInit[c : Chain] : set Actor { produced[c] => rbInit[c] else c.cinit }
fun afterSlots[c : Chain] : set Slot { produced[c] => firstShape[c].oslots else c.cslots }
fun afterRule[c : Chain] : set Rule { produced[c] => firstShape[c].orule else c.crule }
fun afterIat[c : Chain] : set Now { produced[c] => firstShape[c].oiat else c.ciat }
fun afterIinv[c : Chain] : set Intent { produced[c] => firstShape[c].oi else c.ciinv }

-- afterCst, afterTat: the chain state and terminal instant after a rebuild: a terminal
-- record keeps its own (Composition state 26, 27); otherwise the terminal event's, Pending
-- where none exists (Term chain rebuild).
fun afterCst[c : Chain] : set St {
    (not produced[c]) => c.cst
    else ((c in Stored and c.cst != Pending) => c.cst
    else ((some firstTerm[c]) => firstTerm[c].ost else Pending))
}
fun afterTat[c : Chain] : set Now {
    (not produced[c]) => c.ctat
    else ((c in Stored and c.cst != Pending) => c.ctat
    else firstTerm[c].otat)
}

-- afterSlist: the step list after a rebuild: the produced record's ordered step ids, or the
-- stored entry (Composition state 12, 13).
fun afterSlist[c : Chain] : set Minted { produced[c] => firstShape[c].osteps else Idx.slist[c] }

-- afterS2c: the step-chain index after a rebuild: the stored entry, or on a miss the step
-- list index inverted (Composition state 16, 21).
fun afterS2c[x : Minted] : set Chain {
    (some Idx.s2c[x]) => Idx.s2c[x] else { c : Chain | x in afterSlist[c] }
}

-- afterEidx: the event index entry after the event rebuild — the stored ids and every
-- chain namespace record the log read finds against the chain id its act key carries,
-- whoever wrote it (Composition state 18, Term event rebuild, Action wiring 53).
fun afterEidx[c : Chain] : set Ev { Idx.eidx[c] + (retained & chainEvents[c]) }

-- shapeAlert: the shape alert (Composition state 23): an initiation event whose chain shape
-- differs from the chain record's.
pred shapeAlert[c : Chain] {
    c in Stored and (some o : shapeEvs[c] | (not initShape[o, c]) or o.oi.actor != c.cinit)
}

-- terminalAlert: the terminal-data alert (Composition state 22): a terminal event whose
-- terminal summary differs from the chain record's, or two terminal events for one chain.
pred terminalAlert[c : Chain] {
    c in Stored and ((some o : termEvs[c] | o.ost != c.cst or o.otat != c.ctat or o.otinv != c.ctinv)
                     or #termEvs[c] > 1)
}

-- built: every record in the state is what an admitted write left.
pred built {
    initWiring
    decisionWiring
    withdrawalWiring
    terminalWiring
    cascadeWiring
    recallWiring
    outcomeWiring
    indexWiring
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Premises the page relies on and does not state (header, findings (b) and (c))
-- ─────────────────────────────────────────────────────────────────────────────

-- operatorFaithful: every outcome an operator wrote through the invocation resolve closes a
-- committed act and carries what the records hold, as the sweep's would (finding (b)).
pred operatorFaithful {
    all o : oby.ByOper | faithful[o]
}

-- noOutOfBandSubmit: no step was submitted outside the composition (Composes 11; finding (c)).
pred noOutOfBandSubmit {
    all s : Step | some s.sby
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's writes can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: a quiescent chain's step list, after a rebuild, counts exactly its
-- approver set. Under premise (b).
assert A_Invariant_1_1 {
    (built and operatorFaithful) implies
        all c : Stored | quiescent[c] implies #afterSlist[c] = #c.cslots
}
check A_Invariant_1_1 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- A_Invariant_1_3: every step id in a step list, stored or rebuilt, names an Approval Step
-- record. Under premise (b).
assert A_Invariant_1_3 {
    (built and operatorFaithful) implies {
        all c : Chain | Idx.slist[c] in Step
        all c : Chain | afterSlist[c] in Step
    }
}
check A_Invariant_1_3 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- A_Invariant_1_4: the step-chain index, after a rebuild, names exactly one chain for every
-- step id in a step list — the chain whose step list holds it. Under premise (b).
assert A_Invariant_1_4 {
    (built and operatorFaithful) implies
        all c : Chain, x : afterSlist[c] | afterS2c[x] = c
}
check A_Invariant_1_4 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- A_Invariant_1_5: the Approval Step records carry no chainless step of a quiescent chain.
-- Under premise (c).
assert A_Invariant_1_5 {
    (built and noOutOfBandSubmit) implies
        no s : Step, c : Stored | quiescent[c] and chainless[s, c]
}
check A_Invariant_1_5 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- A_Invariant_4_1: on a quiescent chain, every open step (Pending, its chain Pending)
-- carries exactly one Active assignment.
assert A_Invariant_4_1 {
    built implies
        all c : Stored | (quiescent[c] and c.cst = Pending) implies
            all s : stepsOf[c] & sst.Pending | one (asgOf[s] & astatus.Active)
}
check A_Invariant_4_1 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- A_Invariant_4_2: on a quiescent chain, every settled step (terminal, or of a terminal
-- chain) carries no Active assignment — steps decided around the composition aside
-- (Composes 11), as multi-party-approval.tla's Inv4_2 sets them aside.
assert A_Invariant_4_2 {
    built implies
        all c : Stored | quiescent[c] implies
            all s : stepsOf[c] - Oob | (s.sst != Pending or c.cst != Pending) implies
                no (asgOf[s] & astatus.Active)
}
check A_Invariant_4_2 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- A_Invariant_4_3: the composition has recalled no assignment of a Pending step of a
-- Pending chain. A step and a chain leave Pending once and never return, so a recall made
-- while both were Pending shows as one on a step and a chain still Pending.
assert A_Invariant_4_3 {
    built implies
        no a : Asg | a.astatus = Recalled and a.task.sst = Pending and a.task.sby.ichain.cst = Pending
}
check A_Invariant_4_3 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- A_Invariant_5_2: every chain namespace event other than an intent names a chain the chain
-- records carry — read as other than the refusal, abandonment and escalation records of an
-- initiation that committed nothing (finding (a)). Under premise (b).
assert A_Invariant_5_2 {
    (built and operatorFaithful) implies
        all e : Ev - Intent | chainOf[e] in carried
            or (e in Refusal + Abandon + Escalate and intentOf[e].kind = KInit
                and intentOf[e] not in Committed)
}
check A_Invariant_5_2 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- A_Invariant_7_1: a terminal chain's state is the one every commit that terminated it
-- wrote — so no later commit changed it — and a rebuild keeps it. Under premise (b).
assert A_Invariant_7_1 {
    (built and operatorFaithful) implies
        all c : Stored | c.cst != Pending implies {
            all t : Terminating & ichain.c | t.iwrote = c.cst
            afterCst[c] = c.cst
        }
}
check A_Invariant_7_1 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- A_Invariant_7_2: a terminal chain's terminal instant is the now of every commit that
-- terminated it — so no later commit changed it — and a rebuild keeps it. Under premise (b).
assert A_Invariant_7_2 {
    (built and operatorFaithful) implies
        all c : Stored | c.cst != Pending implies {
            all t : Terminating & ichain.c | t.datum = c.ctat
            afterTat[c] = c.ctat
        }
}
check A_Invariant_7_2 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- A_Invariant_7_3: no two terminal events the invocation or the sweep wrote, Retained or
-- Purged, carry one chain id.
assert A_Invariant_7_3 {
    built implies
        all c : Chain | lone { o : oby.(ByInv + BySweep) | o.oi.ichain = c and some o.ost }
}
check A_Invariant_7_3 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- A_Invariant_8_1: a rebuild changes no declared field of a chain record. Under premise (b).
assert A_Invariant_8_1 {
    (built and operatorFaithful) implies
        all c : Stored | afterSubj[c] = c.csubj and afterScope[c] = c.cscope
            and afterInit[c] = c.cinit and afterSlots[c] = c.cslots and afterRule[c] = c.crule
            and afterIat[c] = c.ciat and afterIinv[c] = c.ciinv
}
check A_Invariant_8_1 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- A_Invariant_9_1: a chain that is not aged, its initiation event landed, resolves from its
-- records alone: the step list the records rebuild is its steps, each step's assignment
-- history names its assignment, and its event index entry, rebuilt, names every chain
-- namespace record of the chain. Under premise (b).
assert A_Invariant_9_1 {
    (built and operatorFaithful) implies
        all c : Stored - Aged | produced[c] implies {
            afterSlist[c] = stepsOf[c]
            all s : stepsOf[c] | some asgOf[s]
            chainEvents[c] in afterEidx[c]
        }
}
check A_Invariant_9_1 for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowApprovedChain: a quiescent chain Approved by a decision's chain evaluation, its
-- outcome the invocation's, carrying the terminal summary.
run ShowApprovedChain {
    built and operatorFaithful and some c : Stored |
        quiescent[c] and c.cst = Approved and c.cpath = ResolutionPath
        and some o : oby.ByInv | o.oi = c.ctinv and some o.ost
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowWithdrawnWithCascade: a quiescent chain its initiator withdrew, the cascade having
-- withdrawn a still-Pending step and recalled its assignment.
run ShowWithdrawnWithCascade {
    built and operatorFaithful and some c : Stored |
        quiescent[c] and c.cpath = WithdrawalPath and some c.ccwd
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowTrailingDecision: a decision committed on a terminal chain, carrying the trailing flag,
-- its step decided and recalled, the chain record unchanged.
run ShowTrailingDecision {
    built and operatorFaithful and some i : Committed & Trailing | some i.istep
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowRecoveredInitiation: an initiation whose close did not land, its initiation event
-- recovered by the sweep under the recovery identity, the chain left live.
run ShowRecoveredInitiation {
    built and operatorFaithful and some o : oby.BySweep | o.oi.kind = KInit and o.oi.ichain.cst = Pending
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowRecoveredTerminal: a terminating act's outcome the sweep recovered, carrying the
-- chain record's terminal summary.
run ShowRecoveredTerminal {
    built and operatorFaithful and some o : oby.BySweep | some o.ost
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowOutOfBandDecision: a step decided around the composition on a Pending chain, counted
-- as Pending, its assignment still Active.
run ShowOutOfBandDecision {
    built and some s : Oob | s.sby.ichain.cst = Pending and some (asgOf[s] & astatus.Active)
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowSupersededStep: a Withdrawn chain whose cascade met a step decided out of band
-- (Cascade 10), and withdrew another.
run ShowSupersededStep {
    built and some c : Stored | c.cst = Withdrawn and some (stepsOf[c] & Oob) and some c.ccwd
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowOpenInitiationWindow: a chain record whose initiation intent stands open, no
-- chain-shape event yet (Term open initiation window).
run ShowOpenInitiationWindow {
    built and some c : Stored | not produced[c] and not quiescent[c]
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowLostEntryRebuilt: a step-chain entry lost and rebuilt by inverting the step list.
run ShowLostEntryRebuilt {
    built and operatorFaithful and some c : Stored, x : stepsOf[c] | no Idx.s2c[x] and afterS2c[x] = c
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowAgedChain: an aged chain whose initiation event is Purged, its chain record kept
-- (Retention asymmetry 1).
run ShowAgedChain {
    built and some c : Stored & Aged | c.ciinv in Purged
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowEscalatedDecision: a decision intent the sweep escalated, its chain not quiescent.
run ShowEscalatedDecision {
    built and some x : Escalate | some x.xi.istep and not quiescent[x.xi.ichain]
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowInitiationRefusalNamesNoChain: finding (a). A refused initiation's refusal record
-- names the chain id the host injected, which no chain record carries.
run ShowInitiationRefusalNamesNoChain {
    built and operatorFaithful and some r : Refusal | r.ri.kind = KInit and r.ri.ichain not in carried
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowRebuildTerminatesPendingChain: finding (b)(i). A Pending chain record, an operator's
-- decision outcome carrying a terminal summary: the rebuild writes the chain terminal with
-- no terminating commit; the terminal-data alert fires.
run ShowRebuildTerminatesPendingChain {
    built and some c : Stored | c.cst = Pending and afterCst[c] = Approved and terminalAlert[c]
        and no (Terminating & ichain.c)
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowRebuildRewritesDeclaredFields: finding (b)(ii). An operator's initiation event, the
-- first for its chain, carrying another subject reference and step list: the rebuild writes
-- them over the chain record; the shape alert fires.
run ShowRebuildRewritesDeclaredFields {
    built and some c : Stored | afterSubj[c] != c.csubj and afterSlist[c] != stepsOf[c] and shapeAlert[c]
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowRebuildFromOperatorOnly: finding (b)(iii). An operator's initiation event for an
-- initiation that committed nothing: the rebuild produces a chain record no initiation
-- wrote, naming another chain's step, and no record stands for the shape alert to compare.
run ShowRebuildFromOperatorOnly {
    built and some c : Chain - Stored | produced[c] and not shapeAlert[c]
        and some x : afterSlist[c] | x in stepsOf[Stored]
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now

-- ShowOutOfBandChainless: finding (c). A step submitted outside the composition with a
-- quiescent chain's subject, submitter, scope and prefix: a chainless step.
run ShowOutOfBandChainless {
    built and some s : Step, c : Stored | quiescent[c] and chainless[s, c]
} for 3 but 5 Int, 2 Chain, 3 Slot, 3 Step, 3 Asg, 10 Ev, 4 Intent, 3 Outcome, 1 Refusal, 1 Abandon, 1 Escalate, 4 Actor, 2 Subject, 2 Scope, 2 Rule, 3 Now
