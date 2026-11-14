-- execute-gated-workflow-buggy-mark-from-intent.als
-- DELIBERATELY WRONG twin of execute-gated-workflow.als (unit: compositions/execute-gated-workflow.md formal layer).
--
-- INJECTED DEFECT: the binding rebuild takes the consumed mark from a fire intent naming the bound step, not from a firing event (Composition state 9).
--
-- BREAKS: A_Composition_state_9.
-- Everything else is execute-gated-workflow.als as written; read its comments there.

module execute_gated_workflow_buggy_mark_from_intent

open util/integer

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Subject: an opaque subject reference (Term subject reference), compared byte-exact.
sig Subject {}

-- Actor: an actor reference — an initiator, an opener, an approver reference, an assignee.
sig Actor {}

-- Scope: an approval scope a [Gate Spec] entry names.
sig Scope {}

-- Now: an instant — an intent instant, a submitted instant. Compared for equality only.
sig Now {}

-- Action: a transition name (Term action).
sig Action {}

-- FromState: a declared state a guarded transition leaves.
sig FromState {}

-- Wf: an instance State Machine's instantiate minted for a start (Term instance id), with
-- the subject reference and the initiator reference the start carried. An instance no
-- start event names is a quarantined instance (Action wiring 10).
sig Wf {
    subj : one Subject,
    init : one Actor
}

-- GateKey: an instance id, a from-state and an action (Term gate key) of a guarded
-- transition, with the [Gate Spec] entry its guard label names: the approver reference and
-- the scope.
sig GateKey {
    wf    : one Wf,
    from  : one FromState,
    act   : one Action,
    appr  : one Actor,
    scope : one Scope
}

-- SState: an Approval Step's state.
abstract sig SState {}
one sig Pending, Approved, Rejected, Withdrawn extends SState {}

-- Step: one Approval Step: its subject (Term gate subject: a subject reference and an
-- action), approver reference, scope, submitted instant, submitter and state; and — a
-- ghost — the open intent whose admitted opening's submit minted it (none: a step a
-- deployment submitted outside the composition).
sig Step {
    gsubj     : one Subject,
    gact      : one Action,
    sappr     : one Actor,
    sscope    : one Scope,
    sat       : one Now,
    submitter : one Actor,
    st        : one SState,
    by        : lone OpenIntent
}

-- AStatus: an assignment's status (Assignment's).
abstract sig AStatus {}
one sig Active, Recalled extends AStatus {}

-- Asg: one Assignment record: its task (a step id), its assignee and its status.
sig Asg {
    task     : one Step,
    assignee : one Actor,
    status   : one AStatus
}

-- HEntry: one history entry of a workflow machine (its transition id): the workflow, the
-- gate key it fired out of where guarded, and — a ghost of the fire's gate read — the bound
-- step it spent.
sig HEntry {
    hwf   : one Wf,
    hkey  : lone GateKey,
    hstep : lone Step
}

-- Writer: who wrote a record: the invocation, or the sweep under the service identity.
abstract sig Writer {}
one sig ByInvocation, BySweep extends Writer {}

-- Ev: one Event Log event of the workflow namespace, with its Event Log sequence number.
abstract sig Ev {
    sn : one Int
}

-- StartEv: a start event (workflow_started), carrying the whole workflow record.
sig StartEv extends Ev {
    swf : one Wf
}

-- OpenIntent: an open intent (gate_open_intended): the gate key, the intent instant, the
-- approver reference and scope of the key's [Gate Spec] entry (Action wiring 27), and the
-- actor who opened the gate.
sig OpenIntent extends Ev {
    okey   : one GateKey,
    oat    : one Now,
    oappr  : one Actor,
    oscope : one Scope,
    opener : one Actor
}

-- OpeningEv: an opening event (gate_opened): the step, the gate key, the assignment
-- (Composition state 8), the intent reference (one intent, or the candidates), and who
-- wrote it.
sig OpeningEv extends Ev {
    opStep    : one Step,
    opKey     : one GateKey,
    opAsg     : lone Asg,
    opIntents : set OpenIntent,
    opBy      : one Writer
}

-- DecisionEv: a decision event (gate_decided): the step and the gate key.
sig DecisionEv extends Ev {
    dStep : one Step,
    dKey  : one GateKey
}

-- FireIntent: a fire intent (transition_intended): the workflow, the gate key and bound step
-- where guarded, the moot plan (Action wiring 53); and — a ghost — the history entry its
-- fire appended (none: a fire that refused, Action wiring 57).
sig FireIntent extends Ev {
    fiWf    : one Wf,
    fiKey   : lone GateKey,
    fiStep  : lone Step,
    fiEntry : lone HEntry,
    fiPlan  : set Step
}

-- FiringEv: a firing event (transition_fired): the history entry (its transition id), the
-- bound step where guarded, and who wrote it.
sig FiringEv extends Ev {
    feEntry : one HEntry,
    feStep  : lone Step,
    feBy    : one Writer
}

-- MootRec: a moot record (moot_gate_recalled): the planned step and its gate key.
sig MootRec extends Ev {
    mStep : one Step,
    mKey  : one GateKey
}

-- Purged: the events the record read answers Purged (Retention Window's). An input.
sig Purged in Ev {}

-- AgedStep: the steps whose submitted instant the sweep's now reads as aged (Term aged
-- record). The clock's; an input.
sig AgedStep in Step {}

-- Finding: the steps the sweep opened an out-of-band finding for (Reconciliation 17, 31).
sig Finding in Step {}

-- Decided: the steps a committed [Decide Gate] decided — a ghost of the decision's write.
sig Decided in Step {}

-- WithdrawRefused: the planned steps whose withdraw Approval Step refused to the moot
-- cascade, other than by storage-failure (Cascade 10). Approval Step's answer; an input.
sig WithdrawRefused in Step {}

-- StoredWf: the workflows the stored workflow records carry (workflow_store).
sig StoredWf in Wf {}

-- Idx: the three keyed indexes as stored: the gate binding index (a gate key's bound step,
-- with its consumed and mooted marks), the gate-assignment index and the transition-event
-- index.
one sig Idx {
    bind  : GateKey -> lone Step,
    cmark : set GateKey,
    mmark : set GateKey,
    g2a   : Step -> lone Asg,
    t2e   : HEntry -> lone FiringEv
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers: the page's terms over one state
-- ─────────────────────────────────────────────────────────────────────────────

-- retained: the events the record read answers Retained.
fun retained : set Ev { Ev - Purged }

-- Outcome: the outcomes (Term outcome): start, opening, decision and firing events.
fun Outcome : set Ev { StartEv + OpeningEv + DecisionEv + FiringEv }

-- named: the workflow an event names: a start event's own, an opening or decision event's
-- or moot record's gate key's, a fire intent's, a firing event's history entry's.
fun named[e : Ev] : set Wf {
    e.swf + e.okey.wf + e.opKey.wf + e.dKey.wf + e.fiWf + e.feEntry.hwf + e.mKey.wf
}

-- found: the workflows an instance action finds (Term found action): those the workflow
-- records resolve, with a rebuild on a miss (Action wiring 16, 17) — those a start event
-- landed for, Retained or still stored.
pred found[w : Wf] { some swf.w }

-- carried: the workflows the workflow records carry: those stored, and those the workflow
-- rebuild reproduces from a Retained start event (Composition state 11).
fun carried : set Wf { StoredWf + (StartEv & retained).swf }

-- asgOf: the assignments whose task is the step (Assignment's history_for).
fun asgOf[s : Step] : set Asg { task.s }

-- invOpenings, legOpenings: the opening events the invocation and the opening leg wrote.
fun invOpenings : set OpeningEv { opBy.ByInvocation }
fun legOpenings : set OpeningEv { opBy.BySweep }

-- matched: the open intents an invocation's opening event names.
fun matched : set OpenIntent { invOpenings.opIntents }

-- pairs: the unmatched open intents a step pairs to (Reconciliation 16): the intent instant
-- equal to the step's submitted instant, the intent gate subject (Term intent gate subject:
-- the subject reference of the gate key's workflow and the gate key's action) equal to the
-- step's subject, the approver reference and scope equal to the step's.
fun pairs[s : Step] : set OpenIntent {
    { i : (OpenIntent & retained) - matched |
        i.oat = s.sat and i.okey.wf.subj = s.gsubj and i.okey.act = s.gact
        and i.oappr = s.sappr and i.oscope = s.sscope }
}

-- recordKeys: the gate key the opening leg records on — the paired intents' one gate key,
-- where the gate key count is one (Reconciliation 15, 31; Term gate key count).
fun recordKeys[s : Step] : set GateKey {
    (#(pairs[s].okey) = 1) => pairs[s].okey else none
}

-- legRecords: the opening leg records an opening event for the step.
pred legRecords[s : Step] { some recordKeys[s] }

-- unopened: no invocation's opening event names the step.
pred unopened[s : Step] { no (invOpenings & opStep.s) }

-- legEligible: a step the opening leg examines and may close: unopened and not aged
-- (Reconciliation 5, 15).
pred legEligible[s : Step] { unopened[s] and s not in AgedStep }

-- owedOpening: a Pending step the leg examines that no invocation's opening event names.
pred owedOpening[s : Step] { s.st = Pending and legEligible[s] }

-- Planned: the steps a committed firing's moot plan names (Term planned steps).
fun Planned : set Step { (fiEntry.HEntry).fiPlan }

-- quiescent: no record owed past its invocation on the workflow (Term quiescent
-- workflows): every submitted step carries an opening event, every decided step a decision
-- event, every planned step a moot record, every history entry a firing event.
pred quiescent[w : Wf] {
    all s : Step | (some s.by and s.by.okey.wf = w) implies some opStep.s
    all s : Decided | (opStep.s).opKey.wf = w implies some dStep.s
    all s : Planned | (opStep.s).opKey.wf = w implies some mStep.s
    all h : hwf.w | some feEntry.h
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- A gate key is a key: two gate keys differ in the instance, the from-state or the action
-- (State Machine's transition uniqueness, Term gate key).
fact GateKeysAreKeys {
    all disj k1, k2 : GateKey | k1.wf != k2.wf or k1.from != k2.from or k1.act != k2.act
}

-- Event Log numbers each event with its own sequence number (Event Log Invariant 3).
fact EventLogSequence {
    all disj e1, e2 : Ev | e1.sn != e2.sn
}

-- Retention Window purges the oldest events first: an event older than a Purged one is
-- Purged.
fact PurgeOldestFirst {
    all e : Purged, e2 : Ev | lt[e2.sn, e.sn] implies e2 in Purged
}

-- The clock's edges: the open intent of a step the sweep examines is not yet purged (the
-- aged record's edge is the audit horizon widened by the clock offset allowance,
-- Capability requirement 16, Term aged record).
fact ExaminedIntentsRetained {
    all s : Step - AgedStep | no (s.by & Purged)
}

-- Approval Step refuses a withdraw only one the moot cascade made.
fact RefusedWithdrawsAreTheCascades {
    WithdrawRefused in MootRec.mStep
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Part A — the records: what each admitted write leaves
-- ─────────────────────────────────────────────────────────────────────────────

-- startWiring: a start lands one start event for the instance it minted, and the workflow
-- record is written only after it (Action wiring 9, 11, 13; Reconciliation 27); every other
-- record of a workflow lands after its start event (an instance action acts only on a found
-- workflow).
pred startWiring {
    all w : Wf | lone swf.w
    StoredWf in StartEv.swf
    all e : Ev - StartEv, s : StartEv | s.swf in named[e] implies lt[s.sn, e.sn]
}

-- openWiring: an opening acts on a found workflow and records the open intent with its gate
-- key's [Gate Spec] entry (Action wiring 27); its submit mints one step carrying the gate
-- subject, the entry's approver reference and scope, the intent instant as the submitted
-- instant and the workflow's initiator as the submitter (Action wiring 28), and its assign
-- one assignment of the step to the approver (Action wiring 29); a landed opening's event
-- names the step, its intent, its gate key and its assignment (Action wiring 33).
pred openWiring {
    all i : OpenIntent | found[i.okey.wf] and i.oappr = i.okey.appr and i.oscope = i.okey.scope
    all i : OpenIntent | lone by.i
    all s : Step | some s.by implies {
        s.gsubj = s.by.okey.wf.subj
        s.gact = s.by.okey.act
        s.sappr = s.by.oappr
        s.sscope = s.by.oscope
        s.sat = s.by.oat
        s.submitter = s.by.okey.wf.init
        one asgOf[s]
        asgOf[s].assignee = s.sappr
    }
    all e : invOpenings {
        some e.opStep.by
        e.opIntents = e.opStep.by
        e.opKey = e.opStep.by.okey
        e.opAsg = asgOf[e.opStep]
        lt[e.opStep.by.sn, e.sn]
    }
    all s : Step | lone (invOpenings & opStep.s)
}

-- decideWiring: a decision decides a bound step — one an opening event names (Action
-- wiring 36) — out of Pending; Approved and Rejected come only from a decision; a step is
-- Withdrawn by its submitter's decision or by the moot cascade; a planned step the cascade
-- reached and no decision decided is Withdrawn, or stays Pending where Approval Step
-- refused the withdraw (Cascade 2, 3, 5, 10); a decision event names a decided step under
-- its gate key, once (Action wiring 46).
pred decideWiring {
    all s : Decided | s.st != Pending and some opStep.s
    all s : Step | s.st in Approved + Rejected implies s in Decided
    all s : Step | s.st = Withdrawn implies (s in Decided or (some mStep.s and s not in WithdrawRefused))
    all s : Step | (some mStep.s and s not in Decided) implies
        ((s in WithdrawRefused) => s.st = Pending else s.st = Withdrawn)
    all d : DecisionEv | d.dStep in Decided and some e : OpeningEv | e.opStep = d.dStep and e.opKey = d.dKey
    all s : Step | lone dStep.s
}

-- recallWiring: an assignment is recalled only by a decided decision (Action wiring 41) or
-- the moot cascade (Cascade 4), each on the assignment the gate-assignment index names
-- after a rebuild (Action wiring 44, 77); and each recalls it — where the index names none,
-- Action wiring 45's alert, the assignment stays Active.
pred recallWiring {
    all a : Asg | a.status = Recalled implies
        (a.task in Decided + MootRec.mStep and a in afterG2a[a.task])
    all s : Decided + MootRec.mStep, a : afterG2a[s] | a.status = Recalled
}

-- fireWiring: a firing acts on a found workflow; a guarded entry fired out of its gate key
-- over the bound step, Approved (Wiring decision 1); its fire intent carries the workflow,
-- the gate key and the bound step (Action wiring 53); a fire intent whose fire refused
-- cleared the same gate read; a moot plan names steps bound on the workflow's other gate
-- keys (Action wiring 52, 54); a firing event names its entry's bound step (Action wiring
-- 59, Reconciliation 12, 13), the invocation's at most once, and the firing leg re-emits
-- only where no firing event names the entry (Reconciliation 11).
pred fireWiring {
    all h : HEntry | found[h.hwf]
    all h : HEntry | some h.hkey iff some h.hstep
    all h : HEntry | some h.hkey implies {
        h.hkey.wf = h.hwf
        h.hstep.st = Approved
        h.hstep in Decided
        some e : OpeningEv | e.opStep = h.hstep and e.opKey = h.hkey
    }
    all h : HEntry | one fiEntry.h
    all fi : FireIntent | found[fi.fiWf]
    all fi : FireIntent | some fi.fiEntry implies
        (fi.fiWf = fi.fiEntry.hwf and fi.fiKey = fi.fiEntry.hkey and fi.fiStep = fi.fiEntry.hstep)
    all fi : FireIntent | some fi.fiKey iff some fi.fiStep
    all fi : FireIntent | some fi.fiKey implies {
        fi.fiKey.wf = fi.fiWf
        fi.fiStep.st = Approved
        some e : OpeningEv | e.opStep = fi.fiStep and e.opKey = fi.fiKey
    }
    all fi : FireIntent, s : fi.fiPlan |
        some e : OpeningEv | e.opStep = s and e.opKey.wf = fi.fiWf and e.opKey != fi.fiKey
    all fi : FireIntent | some fi.fiEntry implies all f : feEntry.(fi.fiEntry) | lt[fi.sn, f.sn]
    all f : FiringEv | f.feStep = f.feEntry.hstep
    all h : HEntry | lone (feBy.ByInvocation & feEntry.h)
    all f : FiringEv | f.feBy = BySweep implies no ((FiringEv - f) & feEntry.(f.feEntry))
}

-- mootWiring: the moot cascade records one moot record per planned step, under its gate key
-- (Cascade 1, 7; Reconciliation 14).
pred mootWiring {
    all m : MootRec | m.mStep in Planned and some e : OpeningEv | e.opStep = m.mStep and e.opKey = m.mKey
    all s : Step | lone mStep.s
}

-- legWiring: the opening leg over the steps it examines. A Pending step no opening event
-- names whose paired intents carry one gate key gets one opening event under that key,
-- carrying the step's assignment and the paired intents (Reconciliation 15, 16, 24); one
-- that pairs to no open intent (Reconciliation 17), or to intents on several gate keys
-- (Reconciliation 31), gets an out-of-band finding; the leg writes nothing else.
pred legWiring {
    all s : Step | (owedOpening[s] and legRecords[s]) implies one (legOpenings & opStep.s)
    all e : legOpenings {
        legEligible[e.opStep]
        legRecords[e.opStep]
        e.opKey in recordKeys[e.opStep]
        e.opIntents = pairs[e.opStep]
        e.opAsg = asgOf[e.opStep]
        all i : e.opIntents | lt[i.sn, e.sn]
    }
    all s : Step | lone (legOpenings & opStep.s)
    all s : Step | (owedOpening[s] and no pairs[s]) implies s in Finding
    all s : Step | (owedOpening[s] and some pairs[s] and not legRecords[s]) implies s in Finding
    all s : Finding | legEligible[s] and not legRecords[s] and no (legOpenings & opStep.s)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Part B — the indexes: stored, rebuilt, and after a rebuild
-- ─────────────────────────────────────────────────────────────────────────────

-- indexWiring: an index entry is written only after the event it derives from lands
-- (Action wiring 13): a gate binding and a gate-assignment entry by a landed opening
-- (Action wiring 34), a transition-event entry by a landed firing (Action wiring 60); a
-- consumed mark only where a firing event names the bound step (Action wiring 61,
-- Reconciliation 13), a mooted mark only where a moot record does (Cascade 8). A write may
-- fail (Action wiring 14), so an entry may be missing or name an earlier write's value.
pred indexWiring {
    all k : GateKey, s : Idx.bind[k] | some e : invOpenings | e.opKey = k and e.opStep = s
    all s : Step, a : Idx.g2a[s] | some e : invOpenings | e.opStep = s and e.opAsg = a
    all h : HEntry, f : Idx.t2e[h] | f.feEntry = h and f.feBy = ByInvocation
    all k : Idx.cmark | some Idx.bind[k] and some f : FiringEv | f.feStep = Idx.bind[k]
    all k : Idx.mmark | some Idx.bind[k] and some m : MootRec | m.mStep = Idx.bind[k]
}

-- latestOpening: the binding rebuild's opening event for a gate key: of the Retained
-- opening events on it, the latest in Event Log order (Term binding rebuild).
fun latestOpening[k : GateKey] : set OpeningEv {
    { e : OpeningEv & retained | e.opKey = k and
        no e2 : OpeningEv & retained | e2.opKey = k and gt[e2.sn, e.sn] }
}

-- rbBind: the bound step the binding rebuild names for a gate key.
fun rbBind[k : GateKey] : set Step { latestOpening[k].opStep }

-- rbCmark, rbMmark: the gate keys whose rebuilt binding carries a consumed mark — from the
-- Retained firing event naming the bound step — or a mooted mark — from the Retained moot
-- record naming it (Term binding rebuild).
fun rbCmark : set GateKey {
    { k : GateKey | some rbBind[k] and some f : FireIntent & retained | f.fiStep = rbBind[k] }
}
fun rbMmark : set GateKey {
    { k : GateKey | some rbBind[k] and some m : MootRec & retained | m.mStep = rbBind[k] }
}

-- afterBind, afterCmark, afterMmark: the gate binding index after a rebuild: the rebuild's
-- entry where it reproduces one, the stored entry where it does not (Composition state 15);
-- a stored mark on the same step stays, a purged mark among them (Composition state 16).
fun afterBind[k : GateKey] : set Step { (some rbBind[k]) => rbBind[k] else Idx.bind[k] }
fun afterCmark : set GateKey { rbCmark + { k : Idx.cmark | afterBind[k] = Idx.bind[k] } }
fun afterMmark : set GateKey { rbMmark + { k : Idx.mmark | afterBind[k] = Idx.bind[k] } }

-- rbG2a: the gate-assignment rebuild for a step: from Approval Step's unfiltered read and
-- the step's assignment history (Composition state 13).
fun rbG2a[s : Step] : set Asg { task.s }

-- afterG2a: the gate-assignment index after a rebuild (Composition state 13, 15).
fun afterG2a[s : Step] : set Asg { (some rbG2a[s]) => rbG2a[s] else Idx.g2a[s] }

-- rbT2e, afterT2e: the firing rebuild — each Retained firing event's id recorded against its
-- transition id (Term firing rebuild) — and the transition-event index after it.
fun rbT2e[h : HEntry] : set FiringEv { (FiringEv & retained) & feEntry.h }
fun afterT2e[h : HEntry] : set FiringEv { (some rbT2e[h]) => rbT2e[h] else Idx.t2e[h] }

-- built: every record in the state is what an admitted write left.
pred built {
    startWiring
    openWiring
    decideWiring
    recallWiring
    fireWiring
    mootWiring
    legWiring
    indexWiring
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Premises the page relies on and does not state (header, findings (a) to (d))
-- ─────────────────────────────────────────────────────────────────────────────

-- indexWritesLand: every index write landed — the workflow record of every start, each
-- gate key's binding from its latest landed opening, each landed opening's gate-assignment
-- entry, each landed firing's transition-event entry. Action wiring 14 admits a failed
-- write (finding (a), run ShowStaleRebind).
pred indexWritesLand {
    StoredWf = StartEv.swf
    all k : GateKey | Idx.bind[k] =
        { e : invOpenings | e.opKey = k and no e2 : invOpenings | e2.opKey = k and gt[e2.sn, e.sn] }.opStep
    all e : invOpenings | Idx.g2a[e.opStep] = e.opAsg
    all f : FiringEv | f.feBy = ByInvocation implies Idx.t2e[f.feEntry] = f
}

-- legOpensFreshKeys: the opening leg records only on a gate key no landed opening bound
-- before it (finding (a), run ShowRecoveredOpeningUnbound).
pred legOpensFreshKeys {
    all e : legOpenings | no e2 : invOpenings | e2.opKey = e.opKey and lt[e2.sn, e.sn]
}

-- purgedStartsStored: a workflow whose start event is Purged carries its stored record
-- (finding (c), run ShowPurgedStartUnrecorded).
pred purgedStartsStored {
    all s : StartEv & Purged | s.swf in StoredWf
}

-- outOfBandUnrecorded: no opening event names a step submitted outside the composition
-- (finding (d), run ShowOutOfBandRecorded).
pred outOfBandUnrecorded {
    all e : OpeningEv | some e.opStep.by
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's writes can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_3_1: no committed act carries two outcomes — a submitted step at most one
-- opening event, a history entry at most one firing event — and on a quiescent workflow
-- every submitted step carries exactly one opening event.
assert A_Invariant_3_1 {
    built implies {
        all s : Step | lone opStep.s
        all h : HEntry | lone feEntry.h
        all w : Wf | quiescent[w] implies
            all s : Step | (some s.by and s.by.okey.wf = w) implies one opStep.s
    }
}
check A_Invariant_3_1 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- A_Invariant_3_3: every Retained outcome names a workflow the workflow records carry —
-- never a quarantined instance. Under premise (c).
assert A_Invariant_3_3 {
    (built and purgedStartsStored) implies all o : Outcome & retained | named[o] in carried
}
check A_Invariant_3_3 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- A_Invariant_4_1: on a quiescent workflow, a gate whose bound step (as the binding rebuild
-- names it) is Pending carries exactly one Active assignment. Under premises (b) and (d).
assert A_Invariant_4_1 {
    (built and no WithdrawRefused and outOfBandUnrecorded) implies
        all k : GateKey | (quiescent[k.wf] and rbBind[k].st = Pending) implies
            one (asgOf[rbBind[k]] & status.Active)
}
check A_Invariant_4_1 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- A_Invariant_4_2: on a quiescent workflow, a gate whose bound step is settled — in a
-- terminal state, or named by a moot record (Term settled steps) — carries no Active
-- assignment.
assert A_Invariant_4_2 {
    built implies
        all k : GateKey | (quiescent[k.wf] and some rbBind[k]
                           and (rbBind[k].st != Pending or some mStep.(rbBind[k]))) implies
            no (asgOf[rbBind[k]] & status.Active)
}
check A_Invariant_4_2 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- A_Reconciliation_15: every opening event the opening leg records names its step under the
-- gate key of the open intent whose submit minted the step, that intent among those it
-- carries — so a gate key count above one is found, never recorded (Reconciliation 31).
-- Under premise (d).
assert A_Reconciliation_15 {
    (built and outOfBandUnrecorded) implies
        all e : legOpenings | e.opKey = e.opStep.by.okey and e.opStep.by in e.opIntents
}
check A_Reconciliation_15 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- A_Reconciliation_16: a Pending step the leg examines whose opening event is owed pairs to
-- the open intent whose submit minted it, whoever opened the gate.
assert A_Reconciliation_16 {
    built implies all s : Step | (owedOpening[s] and some s.by) implies s.by in pairs[s]
}
check A_Reconciliation_16 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- A_Reconciliation_17: no Pending step the leg examines is left with neither an opening
-- event the leg recorded nor an out-of-band finding (Reconciliation 15, 17 and 31
-- together).
assert A_Reconciliation_17 {
    built implies all s : Step | owedOpening[s] implies (some (legOpenings & opStep.s) or s in Finding)
}
check A_Reconciliation_17 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- A_Composition_state_9: no rebuilt mark stands on an intent alone: a consumed mark the
-- binding rebuild sets names a step a committed firing spent (a history entry), and a
-- mooted mark one a committed firing's moot plan names.
assert A_Composition_state_9 {
    built implies all k : GateKey | {
        k in rbCmark implies some h : HEntry | h.hstep = rbBind[k]
        k in rbMmark implies rbBind[k] in Planned
    }
}
check A_Composition_state_9 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- A_Composition_state_11: the workflow records, stored and as the workflow rebuild
-- reproduces them, carry no quarantined instance: every workflow they carry has a start
-- event.
assert A_Composition_state_11 {
    built implies carried in StartEv.swf
}
check A_Composition_state_11 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- A_Composition_state_12: a live gate binding — one whose opening event is Retained — names
-- the step the binding rebuild names for its gate key (Composition state 10: a live index
-- entry is a derived index). Under premise (a).
assert A_Composition_state_12 {
    (built and indexWritesLand and legOpensFreshKeys) implies
        all k : GateKey | (some Idx.bind[k] and
            some e : invOpenings & retained | e.opKey = k and e.opStep = Idx.bind[k])
            implies Idx.bind[k] = rbBind[k]
}
check A_Composition_state_12 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- A_Composition_state_13: after the gate-assignment rebuild, every step the composition
-- submitted carries its own assignment — its opening event landed, owed or Purged.
assert A_Composition_state_13 {
    built implies all s : Step | some s.by implies afterG2a[s] = asgOf[s]
}
check A_Composition_state_13 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- A_Composition_state_14: after the firing rebuild, every history entry a Retained firing
-- event names maps to exactly one event, one naming it.
assert A_Composition_state_14 {
    built implies all h : HEntry | some rbT2e[h] implies (one afterT2e[h] and afterT2e[h].feEntry = h)
}
check A_Composition_state_14 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- A_Composition_state_15: a rebuild retains every stored gate binding it does not
-- reproduce, with its marks, and every stored gate-assignment entry.
assert A_Composition_state_15 {
    built implies {
        all k : GateKey | (some Idx.bind[k] and no rbBind[k]) implies {
            afterBind[k] = Idx.bind[k]
            k in Idx.cmark implies k in afterCmark
            k in Idx.mmark implies k in afterMmark
        }
        all s : Step | (some Idx.g2a[s] and no rbG2a[s]) implies afterG2a[s] = Idx.g2a[s]
    }
}
check A_Composition_state_15 for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowGatedRun: a quiescent workflow whose gate an invocation opened, its approver approved
-- and a guarded firing spent, every outcome landed and every index written.
run ShowGatedRun {
    built and indexWritesLand and some h : HEntry |
        some h.hkey and quiescent[h.hwf] and some (feBy.ByInvocation & feEntry.h)
        and some dStep.(h.hstep) and h.hkey in Idx.cmark
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowRebind: a gate key re-bound over a rejected step by a second landed opening, the
-- stored binding naming the newer step.
run ShowRebind {
    built and indexWritesLand and some k : GateKey |
        #(invOpenings & opKey.k) = 2 and some s : (invOpenings & opKey.k).opStep | s.st = Rejected
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowRecoveredOpening: an opening whose event Audit Trail refused, recorded by the opening
-- leg on a fresh gate key, the binding rebuild naming its step.
run ShowRecoveredOpening {
    built and legOpensFreshKeys and some e : legOpenings | rbBind[e.opKey] = e.opStep
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowAmbiguousPairing: a step whose paired intents carry two gate keys — one action
-- leaving two states, or two workflows on one subject reference — found, not recorded
-- (Reconciliation 31).
run ShowAmbiguousPairing {
    built and some s : Finding | some s.by and #(pairs[s].okey) > 1
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowOutOfBandFinding: a step a deployment submitted outside the composition, found
-- (Reconciliation 17).
run ShowOutOfBandFinding {
    built and some s : Finding | no s.by and no pairs[s]
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowQuarantined: an instance an unlanded start minted: no start event, no record, no
-- record names it (Action wiring 10).
run ShowQuarantined {
    built and some w : Wf | not found[w] and w not in carried and some GateKey
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowRecoveredFiring: a firing whose event the firing leg re-emitted (Reconciliation 11).
run ShowRecoveredFiring {
    built and some f : FiringEv | f.feBy = BySweep and some f.feStep
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowMootedApproval: an Approved step another transition's firing left behind, mooted
-- (approved-unconsumed): its moot record and its mooted mark.
run ShowMootedApproval {
    built and some m : MootRec | m.mStep.st = Approved and m.mKey in Idx.mmark
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowPurgedBindingRetained: a stored gate binding whose opening event is Purged, spent
-- under its consumed mark, kept by the rebuild (Retention asymmetry 2).
run ShowPurgedBindingRetained {
    built and some k : GateKey | some Idx.bind[k] and no rbBind[k] and k in Idx.cmark
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowAssignmentForOwedOpening: a step whose opening event is owed: no stored
-- gate-assignment entry, its assignment named by the rebuild.
run ShowAssignmentForOwedOpening {
    built and some s : Step | owedOpening[s] and some s.by and no Idx.g2a[s] and some afterG2a[s]
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowRecoveredOpeningUnbound: finding (a). Every index write landed; a re-bind's opening
-- event was refused and the leg recorded it: the stored binding names the earlier step, the
-- rebuild the recovered Pending one.
run ShowRecoveredOpeningUnbound {
    built and indexWritesLand and some k : GateKey |
        some Idx.bind[k] and some e : invOpenings & retained | e.opKey = k and e.opStep = Idx.bind[k]
        and Idx.bind[k] != rbBind[k] and rbBind[k].st = Pending
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowStaleRebind: finding (a). No leg ran; a re-bind's binding write failed (Action wiring
-- 14): the stored binding is live and names the earlier step.
run ShowStaleRebind {
    built and no legOpenings and some k : GateKey |
        some Idx.bind[k] and some e : invOpenings & retained | e.opKey = k and e.opStep = Idx.bind[k]
        and Idx.bind[k] != rbBind[k]
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowRefusedWithdraw: finding (b). A quiescent workflow whose bound step a firing mooted
-- with its withdraw refused: Pending, its assignment recalled, its moot record landed.
run ShowRefusedWithdraw {
    built and outOfBandUnrecorded and some k : GateKey |
        quiescent[k.wf] and rbBind[k].st = Pending and rbBind[k] in WithdrawRefused
        and no (asgOf[rbBind[k]] & status.Active)
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowPurgedStartUnrecorded: finding (c). A workflow whose start event is Purged and whose
-- record's write failed, named by a Retained outcome.
run ShowPurgedStartUnrecorded {
    built and some o : Outcome & retained | named[o] not in carried
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec

-- ShowOutOfBandRecorded: finding (d). A step submitted outside the composition coincides with
-- an unmatched open intent and the leg records it as that gate's opening.
run ShowOutOfBandRecorded {
    built and some e : legOpenings | no e.opStep.by
} for 3 but 5 Int, 2 Wf, 2 Subject, 2 Scope, 2 Now, 2 Action, 2 FromState, 2 HEntry, 10 Ev, 2 StartEv, 3 OpenIntent, 3 OpeningEv, 2 DecisionEv, 2 FireIntent, 2 FiringEv, 2 MootRec
