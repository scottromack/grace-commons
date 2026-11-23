-- compensable-workflow-buggy-merged-replay.als
-- DELIBERATELY WRONG twin of compensable-workflow.als (unit: `compositions/compensable-workflow.md formal layer`).
--
-- INJECTED DEFECT: the replay reads every event of the shared Event Log instance, another
-- run's with its own, so a writer reads the other run's completions as its run's (Replay 1,
-- Composes 13 dropped; the TLA+ model's -merged-replay).
--
-- BREAKS: A_Replay_1, A_Invariant_4_1, A_Invariant_4_2, A_Invariant_5_1, A_Invariant_7_2.
-- Everything else is compensable-workflow.als as written; read its comments there.

module compensable_workflow_buggy_merged_replay

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Yes: the one value of a set flag; a field holding Yes is set, an empty one is not.
one sig Yes {}

-- State: the spine's states, the three phases and the two outcomes (Action wiring 62; Term
-- value sets). The replay derives a phase and, once reached, an outcome from the same values.
abstract sig State {}
one sig Forward, Compensating, Halted, Committed, Compensated extends State {}

-- Wire: the wire spelling of a transition-bearing event's type, the action a spine
-- transition fires under (Term spine transitions).
abstract sig Wire {}
one sig WStepCompleted, WCompBegun, WHalted, WCommitted, WCompRun, WCompensated,
    WCompAttempted, WStepAttempted extends Wire {}

-- Marker: a step marker (Term step marker): read-only, or pivot, the commit point past which
-- the run only rolls forward.
abstract sig Marker {}
one sig ReadOnly, Pivot extends Marker {}

-- Policy: the compensation failure policy (Term compensation failure policy).
abstract sig Policy {}
one sig HaltAndSurface, Continue extends Policy {}

-- Source: the input source a compensation run event carries (Term input source).
abstract sig Source {}
one sig Recorded, Operator extends Source {}

-- CompRef: a compensating action a definition declares, as a compensation reference names it.
sig CompRef {}

-- Key: an effect key (Term effect key).
sig Key {}

-- Run: a compensable workflow, named by its compensable workflow id (Term compensable
-- workflow id).
sig Run {}

-- Step: one step the definition declares (Term definition): the steps declared before it,
-- whether it is an effect step, its step marker and its compensating action where it has
-- them, and for each run the effect keys derived for its effect and its compensation's
-- (Composition state 11, 12: from the compensable workflow id and the step).
sig Step {
    ahead : set Step,
    effect : lone Yes,
    marker : lone Marker,
    comp : lone CompRef,
    skey : Run -> one Key,
    ckey : Run -> lone Key
}

-- Deployment: the deployment's setting the model reads, the compensation failure policy
-- (Capability requirement 2).
one sig Deployment {
    policy : one Policy
}

-- Spine: the State Machine workflow serving the run, as the start instantiated it: its
-- initial state and its terminal states (Action wiring 62, 63). Its declared transitions are
-- the page's ten, spineTrans below.
one sig Spine {
    initial : one State,
    terminal : set State
}

-- Event: one event of the Event Log instance; earlier holds the events before it in
-- sequence-number order, wf the compensable workflow id it carries (Composes 13, Event schema
-- 14: every event carries one, so the field is declared one), and sp the current state of its
-- run's spine once the event and its fire committed.
abstract sig Event {
    earlier : set Event,
    wf : one Run,
    sp : one State
}

-- Keyed: an event carrying a step and an effect key — an attempt marker, a completion record
-- or a compensation failure event (Event schema 4, 5, 7, 8).
abstract sig Keyed extends Event {
    step : one Step,
    key : one Key
}

-- Attempt: an attempt marker (Term attempt marker); asserted holds the recorded horizon
-- assertion, which makes it a resume marker (Term resume marker; Event schema 6).
abstract sig Attempt extends Keyed {
    asserted : lone Yes
}

-- StepAttempt: a step attempt event (`step_attempted`); inputs holds the operator's
-- compensation inputs where a resume marker carries them (Event schema 12).
sig StepAttempt extends Attempt {
    inputs : lone Yes
}

-- CompAttempt: a compensation attempt event (`compensation_attempted`).
sig CompAttempt extends Attempt {}

-- StepCompleted: a step completion event (`step_completed`): the compensation reference and
-- the truncation mark (Event schema 5).
sig StepCompleted extends Keyed {
    compRef : lone CompRef,
    overflow : lone Yes
}

-- CompRun: a compensation run event (`compensation_run`) with its input source (Event
-- schema 7).
sig CompRun extends Keyed {
    source : one Source
}

-- CompFailed: a compensation failure event (`compensation_failed`, Event schema 8).
sig CompFailed extends Keyed {}

-- Onset: a compensation onset event (`compensation_begun`): the failed step where a failed
-- effect began the compensating phase, none where a cancel did (Event schema 9, 13).
sig Onset extends Event {
    ostep : lone Step
}

-- Halt: a halt event (`compensable_workflow_halted`): the phase it leaves and the steps it
-- names (Event schema 10). Fault halts are left out (the spine fault, above).
sig Halt extends Event {
    hphase : one State,
    hsteps : set Step
}

-- Commit: a commit event (`compensable_workflow_committed`), a terminal marker.
sig Commit extends Event {}

-- Close: a compensation close event (`compensable_workflow_compensated`), a terminal marker.
sig Close extends Event {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: only what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- Event Log orders a log's events by sequence number alone (Event Log Invariant 1, 3;
-- Concurrency 2): earlier is a strict total order.
fact EventLogOrder {
    all e : Event | e not in e.earlier
    all e : Event | e.earlier.earlier in e.earlier
    all disj x, y : Event | x in y.earlier or y in x.earlier
}

-- The definition the caller supplies declares its steps in one order (Term definition):
-- ahead (the steps declared before a step) is a strict total order.
fact DefinitionOrder {
    all s : Step | s not in s.ahead
    all s : Step | s.ahead.ahead in s.ahead
    all disj s, t : Step | s in t.ahead or t in s.ahead
}

-- The key derivation (Composition state 11, 12): the page names its inputs, the run id and
-- the step, and the compensation reference for a compensation's, and not the function; the
-- model takes one that tells effects apart: for each run one key for each step's effect, one
-- for each declared compensation's and none for a step declaring none, no two alike across
-- the runs.
fact KeyDerivation {
    all s : Step, r : Run | (some s.comp implies one r.(s.ckey)) and (no s.comp implies no r.(s.ckey))
    all s, t : Step, r, q : Run | (s != t or r != q) implies
        (r.(s.skey) != q.(t.skey) and no (r.(s.ckey) & q.(t.ckey)))
    no (Run.(Step.skey) & Run.(Step.ckey))
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers: the replay (Replay 1 to 14), over the events of a prefix s
-- ─────────────────────────────────────────────────────────────────────────────

-- spineTrans: the ten declared spine transitions, from state, wire spelling, to state (Term
-- spine transitions).
fun spineTrans : State -> Wire -> State {
    Forward -> WStepCompleted -> Forward
    + Forward -> WCompBegun -> Compensating
    + Forward -> WHalted -> Halted
    + Forward -> WCommitted -> Committed
    + Compensating -> WCompRun -> Compensating
    + Compensating -> WHalted -> Halted
    + Compensating -> WCompensated -> Compensated
    + Compensating -> WCompAttempted -> Compensating
    + Halted -> WStepAttempted -> Forward
    + Halted -> WCompAttempted -> Compensating
}

-- own: the events before e that carry e's compensable workflow id — the step log a writer of
-- e's run reads, the replay keeping the events carrying the id alone (Replay 1; Term step log).
fun own[e : Event] : set Event {
    e.earlier
}

-- runLog: the step log of a run, the events carrying its id.
fun runLog[r : Run] : set Event {
    wf.r
}

-- prev: the event of e's run immediately before e.
fun prev[e : Event] : set Event {
    { p : own[e] | own[e] - p in p.earlier }
}

-- skeyOf: the key derived for a step's effect in a run.
fun skeyOf[s : Step, r : Run] : set Key {
    r.(s.skey)
}

-- ckeyOf: the key derived for a step's compensation in a run.
fun ckeyOf[s : Step, r : Run] : set Key {
    r.(s.ckey)
}

-- resumes: the resume markers, the attempt markers carrying a recorded horizon assertion.
fun resumes : set Attempt {
    { a : Attempt | some a.asserted }
}

-- terminals: the terminal markers among some events.
fun terminals[s : set Event] : set Event {
    (Commit + Close) & s
}

-- completed: the completed steps — a step completion event landed, no compensation run
-- event yet (Replay 7, 8).
fun completed[s : set Event] : set Step {
    (StepCompleted & s).step - (CompRun & s).step
}

-- applied: the applied effects, the keys the completion records carry (Replay 10, 13).
fun applied[s : set Event] : set Key {
    ((StepCompleted + CompRun) & s).key
}

-- resolvedIn: an attempt marker is answered by a later event of s — a completion record or
-- compensation failure event carrying its key, or an onset naming its step (Term resolving
-- event). A halt event is none (Replay 12).
pred resolvedIn[a : Attempt, s : set Event] {
    (some r : (StepCompleted + CompRun + CompFailed) & s | a in r.earlier and r.key = a.key)
    or (some o : Onset & s | a in o.earlier and o.ostep = a.step)
}

-- unresolved: the unresolved attempts (Replay 11).
fun unresolved[s : set Event] : set Attempt {
    { a : Attempt & s | not resolvedIn[a, s] and a.key not in applied[s] }
}

-- newestHalt: the newest halt event of s.
fun newestHalt[s : set Event] : set Halt {
    { h : Halt & s | no h2 : Halt & s | h in h2.earlier }
}

-- standing: the standing halt — the newest halt, no resume marker after it (Term standing halt).
fun standing[s : set Event] : set Halt {
    { h : newestHalt[s] | no r : resumes & s | h in r.earlier }
}

-- phaseOf: the phase the replay derives (Replay 2 to 4).
fun phaseOf[s : set Event] : State {
    some standing[s] => Halted else (some (Onset & s) => Compensating else Forward)
}

-- outcomeOf: the outcomes the replay derives (Replay 5, 6).
fun outcomeOf[s : set Event] : set State {
    (some (Commit & s) => Committed else none) + (some (Close & s) => Compensated else none)
}

-- replayed: the replayed state — the outcome, or the phase where there is none (Term
-- replayed state).
fun replayed[s : set Event] : set State {
    some outcomeOf[s] => outcomeOf[s] else phaseOf[s]
}

-- nextStep: the first declared step no step completion event names (Term next step).
fun nextStep[s : set Event] : set Step {
    { st : Step - (StepCompleted & s).step | no (st.ahead - (StepCompleted & s).step) }
}

-- rollForward: the roll-forward steps — marked pivot, or after a step marked pivot (Term
-- roll-forward step).
fun rollForward : set Step {
    { st : Step | st.marker = Pivot or some (st.ahead & marker.Pivot) }
}

-- standingFail: the steps a standing failure names — a compensation failure event no later
-- compensation run event for its step answers (Term standing failure).
fun standingFail[s : set Event] : set Step {
    { st : Step | some f : CompFailed & s | f.step = st
        and (no r : CompRun & s | r.step = st and f in r.earlier) }
}

-- refStands: the completed steps whose step completion event's compensation reference does
-- not equal blank.
fun refStands[s : set Event] : set Step {
    { c : StepCompleted & s | some c.compRef }.step
}

-- pending: the pending compensations, the completed steps whose compensation reference does
-- not equal blank and that no standing failure names (Term pending compensation).
fun pending[s : set Event] : set Step {
    (completed[s] & refStands[s]) - standingFail[s]
}

-- newestPending: the pending compensation the reverse order takes first, the step declared
-- last (steps complete in declared order) (Invariant 5.1).
fun newestPending[s : set Event] : set Step {
    { st : pending[s] | no (pending[s] & ahead.st) }
}

-- overflowed: the overflowed steps, whose step completion event carries the truncation mark.
fun overflowed[s : set Event] : set Step {
    { c : StepCompleted & s | some c.overflow }.step
}

-- completionOf: the step completion event of a step.
fun completionOf[st : Step] : set StepCompleted {
    StepCompleted & step.st
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writers: what each record may be, over the events before it
-- ─────────────────────────────────────────────────────────────────────────────

-- startAdmits: the start admits the definition only without an unmarked irreversible step
-- (Primitive policy 12) and without an effect step marked read-only (Primitive policy 29).
pred startAdmits {
    all st : Step | (some st.effect and no st.comp) implies some st.marker
    no st : Step | some st.effect and st.marker = ReadOnly
}

-- spineWrites: the start instantiates the spine with the outcomes as its terminal states and
-- forward as its initial state (Action wiring 62, 63).
pred spineWrites {
    Spine.initial = Forward
    Spine.terminal = Committed + Compensated
}

-- advanceOpen: an [Advance] writes only where no terminal marker stands (Action wiring 10).
pred advanceOpen[p : set Event] {
    no terminals[p]
}

-- cancelOpen: a [Cancel] writes only where no terminal marker stands (Action wiring 71).
pred cancelOpen[p : set Event] {
    no terminals[p]
}

-- resumeWrites: a halted advance's resume marker: the newest halt names the phase the marker
-- returns to (Action wiring 85, 86), only resume markers stand since it, and it names a step
-- the halt names that no marker of the batch names yet (Action wiring 49).
pred resumeWrites[a : Attempt, ph : State] {
    let p = own[a], h = newestHalt[p] {
        one h
        h.hphase = ph
        (p - h.earlier - h) in resumes
        a.step in h.hsteps
        no r : resumes & p | h in r.earlier and r.step = a.step
    }
}

-- writesStepAttempt: a forward advance's attempt marker for the next step (Action wiring 22,
-- 24), or a halted advance's resume marker after a halt naming the forward phase, carrying
-- the operator's compensation inputs exactly where the step overflowed (Action wiring 85;
-- Primitive policy 9, 11; Event schema 12).
pred writesStepAttempt[a : StepAttempt] {
    let p = own[a] {
        advanceOpen[p]
        no a.asserted implies {
            phaseOf[p] = Forward
            no unresolved[p]
            a.step = nextStep[p]
            no a.inputs
        }
        some a.asserted implies {
            resumeWrites[a, Forward]
            some a.inputs iff a.step in overflowed[p]
        }
        a.key = skeyOf[a.step, a.wf]
    }
}

-- writesCompAttempt: a compensating advance's attempt marker for the newest pending
-- compensation, which has a compensating action to run (Action wiring 32 to 35), or a
-- halted advance's resume marker after a halt naming the compensating phase (Action wiring
-- 86).
pred writesCompAttempt[a : CompAttempt] {
    let p = own[a] {
        advanceOpen[p]
        no a.asserted implies {
            phaseOf[p] = Compensating
            no unresolved[p]
            a.step in newestPending[p]
            some a.step.comp
        }
        some a.asserted implies resumeWrites[a, Compensating]
        a.key = ckeyOf[a.step, a.wf]
    }
}

-- writesStepCompleted: the completion of an unresolved step attempt in the forward phase,
-- carrying the step's key, its compensation reference and, where the target answered more
-- than the envelope, the truncation mark (Action wiring 21, 25; Event schema 5; Primitive
-- policy 19, 20).
pred writesStepCompleted[c : StepCompleted] {
    let p = own[c] {
        advanceOpen[p]
        phaseOf[p] = Forward
        some a : StepAttempt & unresolved[p] | a.step = c.step
        c.key = skeyOf[c.step, c.wf]
        c.compRef = c.step.comp
        some c.overflow implies some c.step.comp
    }
}

-- writesCompRun: the run of an unresolved compensation attempt in the compensating phase,
-- under the compensation's key, with operator as the input source exactly for an overflowed
-- step (Action wiring 36; Primitive policy 23, 24).
pred writesCompRun[r : CompRun] {
    let p = own[r] {
        advanceOpen[p]
        phaseOf[p] = Compensating
        some a : CompAttempt & unresolved[p] | a.step = r.step
        r.key = ckeyOf[r.step, r.wf]
        r.step in overflowed[p] implies r.source = Operator else r.source = Recorded
    }
}

-- writesCompFailed: under the continue policy, a definitely failed compensation attempt is
-- recorded (Action wiring 38).
pred writesCompFailed[f : CompFailed] {
    let p = own[f] {
        advanceOpen[p]
        phaseOf[p] = Compensating
        Deployment.policy = Continue
        some a : CompAttempt & unresolved[p] | a.step = f.step
        f.key = ckeyOf[f.step, f.wf]
    }
}

-- writesOnset: a forward advance whose step attempt definitely failed, the step outside the
-- roll-forward steps, names the step (Action wiring 26, 30; Event schema 9); an admitted
-- cancel names none and lands only with no unresolved attempt and no roll-forward step
-- completed (Action wiring 71 to 74, 87; Event schema 13).
pred writesOnset[o : Onset] {
    let p = own[o] {
        phaseOf[p] = Forward
        some o.ostep implies {
            advanceOpen[p]
            some a : StepAttempt & unresolved[p] | a.step = o.ostep
            o.ostep not in rollForward
        }
        no o.ostep implies {
            cancelOpen[p]
            no unresolved[p]
            no ((StepCompleted & p).step & rollForward)
        }
    }
}

-- writesHalt: a halt names the phase it leaves (Event schema 10) and either the step of an
-- unresolved attempt of that phase — a failed roll-forward step, a failed compensation under
-- halt-and-surface, an unknown verdict (Action wiring 28, 37, 47) — or every step a
-- standing failure names once nothing else is owed (Action wiring 41), or the step whose
-- completion just landed overflowed (Primitive policy 21).
pred writesHalt[h : Halt] {
    let p = own[h], ph = phaseOf[p] {
        advanceOpen[p]
        ph in Forward + Compensating
        h.hphase = ph
        (some a : unresolved[p] | h.hsteps = a.step
            and (ph = Forward implies a in StepAttempt)
            and (ph = Compensating implies a in CompAttempt))
        or (ph = Compensating and no pending[p] and no unresolved[p]
            and some standingFail[p] and h.hsteps = standingFail[p])
        or (ph = Forward and (some c : prev[h] & StepCompleted | some c.overflow and h.hsteps = c.step))
    }
}

-- writesCommit: a forward advance with no next step commits (Action wiring 31).
pred writesCommit[t : Commit] {
    let p = own[t] {
        advanceOpen[p]
        phaseOf[p] = Forward
        no unresolved[p]
        no nextStep[p]
    }
}

-- closeAdmits: a compensating advance over a run's step log p may close: no pending
-- compensation, no unresolved attempt and no standing failure (Action wiring 40).
pred closeAdmits[p : set Event] {
    advanceOpen[p]
    phaseOf[p] = Compensating
    no pending[p]
    no unresolved[p]
    no standingFail[p]
}

-- writesClose: the close lands where its run's step log admits it.
pred writesClose[t : Close] {
    closeAdmits[own[t]]
}

-- overflowHalts: whatever follows an overflowed step's completion is the halt naming the
-- forward phase and that step (Primitive policy 21).
pred overflowHalts {
    all c : StepCompleted, e : Event | (some c.overflow and prev[e] = c) implies
        (e in Halt and e.hphase = Forward and e.hsteps = c.step)
}

-- resumesComplete: a halted advance appends a resume marker for every named step before
-- anything else of its run lands (Action wiring 49, 50).
pred resumesComplete {
    all e : Event - resumes | let h = newestHalt[own[e]] |
        some h implies (all st : h.hsteps | some r : resumes & own[e] | h in r.earlier and r.step = st)
}

-- wireOf: the wire spelling a transition-bearing event fires under; none for an event that
-- bears no transition (an attempt marker that is not a resume marker, a compensation failure
-- event) (Term transition-bearing event).
fun wireOf[e : Event] : set Wire {
    e in StepCompleted => WStepCompleted
    else e in CompRun => WCompRun
    else e in Onset => WCompBegun
    else e in Halt => WHalted
    else e in Commit => WCommitted
    else e in Close => WCompensated
    else e in resumes & StepAttempt => WStepAttempted
    else e in resumes & CompAttempt => WCompAttempted
    else none
}

-- spBefore: the state of the event's run's spine before the event's fire.
fun spBefore[e : Event] : State {
    some prev[e] => prev[e].sp else Spine.initial
}

-- fireTo: what State Machine's fire answers from a state under a wire spelling: the declared
-- transition's to state, none from a terminal state or where none is declared (a refusal).
fun fireTo[from : State, w : set Wire] : set State {
    from in Spine.terminal => none else w.(from.spineTrans)
}

-- fires: the composition fires each transition-bearing event's declared transition with the
-- event, in one transaction (Action wiring 8, 94; Composes 4; Execution Contract Database 1:
-- an event whose fire failed is not in the log); a refused fire leaves the spine where it was.
pred fires[e : Event] {
    let to = fireTo[spBefore[e], wireOf[e]] |
        one to implies e.sp = to else e.sp = spBefore[e]
}

-- conforms: the definition was admitted, the spine instantiated, and every event in the
-- log is one its writer's rules let it append, its fire with it.
pred conforms {
    startAdmits
    spineWrites
    all a : StepAttempt | writesStepAttempt[a]
    all a : CompAttempt | writesCompAttempt[a]
    all c : StepCompleted | writesStepCompleted[c]
    all r : CompRun | writesCompRun[r]
    all f : CompFailed | writesCompFailed[f]
    all o : Onset | writesOnset[o]
    all h : Halt | writesHalt[h]
    all t : Commit | writesCommit[t]
    all t : Close | writesClose[t]
    overflowHalts
    resumesComplete
    all e : Event | fires[e]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the composition's writers can leave that violates
-- this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_2_1: after every event the spine's current state equals the replayed state of
-- the log up to it.
assert A_Invariant_2_1 {
    conforms implies all e : Event | e.sp = replayed[own[e] + e]
}
check A_Invariant_2_1 for 2 but 8 Event, 8 Key

-- A_Invariant_3_1: every step completion event of an effect step outside the roll-forward
-- steps carries exactly one compensation reference — every such step, a step marked
-- read-only being no effect step (Primitive policy 29; FOUND (1), cured).
assert A_Invariant_3_1 {
    conforms implies all c : StepCompleted |
        (some c.step.effect and c.step not in rollForward)
            implies one c.compRef
}
check A_Invariant_3_1 for 2 but 8 Event, 8 Key

-- A_Invariant_4_1: a run carrying a compensation close event carries a compensation run
-- event for every step completion event whose compensation reference does not equal blank.
assert A_Invariant_4_1 {
    conforms implies all w : Run | some (Close & runLog[w]) implies
        all c : StepCompleted & runLog[w] | some c.compRef implies
            some r : CompRun & runLog[w] | r.step = c.step
}
check A_Invariant_4_1 for 2 but 8 Event, 8 Key

-- A_Invariant_4_2: a log carrying a commit event carries a step completion event for every
-- declared step.
assert A_Invariant_4_2 {
    conforms implies all w : Run | some (Commit & runLog[w]) implies
        all st : Step | some (completionOf[st] & runLog[w])
}
check A_Invariant_4_2 for 2 but 8 Event, 8 Key

-- A_Invariant_4_3: a log carrying a commit event carries no compensation onset event.
assert A_Invariant_4_3 {
    conforms implies all w : Run | some (Commit & runLog[w]) implies no (Onset & runLog[w])
}
check A_Invariant_4_3 for 2 but 8 Event, 8 Key

-- A_Invariant_4_5: no terminal marker lands while an attempt stands unresolved before it.
assert A_Invariant_4_5 {
    conforms implies all t : Commit + Close | no unresolved[own[t]]
}
check A_Invariant_4_5 for 2 but 8 Event, 8 Key

-- A_Invariant_5_1: newest first — when a compensating advance attempts a step's compensating
-- action, every newer completed step with a compensating action has had its own attempted.
assert A_Invariant_5_1 {
    conforms implies all a : CompAttempt - resumes, y : Step |
        let cy = completionOf[y] & runLog[a.wf], ca = completionOf[a.step] & runLog[a.wf] |
        (some y.comp and some cy and ca in cy.earlier)
        implies some (CompAttempt & step.y & own[a])
}
check A_Invariant_5_1 for 2 but 8 Event, 8 Key

-- A_Check_5_1: compensation run events land in the reverse of the step completion order, save
-- where a compensation failure event names the newer step: wherever an older step's
-- compensation run event precedes a newer step's in one run, a compensation failure event of
-- that run names the newer step (Check 5.1, Invariant 5.1, Action wiring 97; FOUND (3), cured).
assert A_Check_5_1 {
    conforms implies all disj r1, r2 : CompRun, c1, c2 : StepCompleted |
        (r1.wf = r2.wf and c1.wf = r1.wf and c2.wf = r1.wf
            and c1.step = r1.step and c2.step = r2.step
            and c1 in c2.earlier and r1 in r2.earlier)
        implies some (CompFailed & runLog[r2.wf] & step.(r2.step))
}
check A_Check_5_1 for 2 but 12 Event, 8 Key

-- A_Action_wiring_97: under the continue policy the compensating action of a step a standing
-- failure names is run again only where no pending compensation stands: no resume marker
-- re-opening a standing failure's compensation lands while a pending compensation stands.
assert A_Action_wiring_97 {
    conforms implies all a : resumes & CompAttempt |
        (Deployment.policy = Continue and a.step in standingFail[own[a]])
            implies no pending[own[a]]
}
check A_Action_wiring_97 for 2 but 9 Event, 8 Key

-- A_Invariant_6_1: no log carries two terminal markers.
assert A_Invariant_6_1 {
    conforms implies all w : Run | lone ((Commit + Close) & runLog[w])
}
check A_Invariant_6_1 for 2 but 8 Event, 8 Key

-- A_Invariant_6_2: halted is never an outcome — not among the spine's terminal states, and
-- never an outcome the replay derives.
assert A_Invariant_6_2 {
    conforms implies {
        Halted not in Spine.terminal
        all e : Event | Halted not in outcomeOf[own[e] + e]
    }
}
check A_Invariant_6_2 for 2 but 8 Event, 8 Key

-- A_Invariant_6_3: a resume marker returns the run to the phase the newest halt before it
-- names — the replay's phase and the spine's state both.
assert A_Invariant_6_3 {
    conforms implies all r : resumes | let h = newestHalt[own[r]] |
        r.sp = h.hphase and phaseOf[own[r] + r] = h.hphase
}
check A_Invariant_6_3 for 2 but 8 Event, 8 Key

-- A_Invariant_7_2: no effect runs twice under a recorded key — no two completion records
-- carry one key (Check 7.1), the two runs' included, and no attempt marker an advance opens to
-- run an effect (a resume marker re-runs nothing whose key is applied) carries a key its run
-- already applied before it.
assert A_Invariant_7_2 {
    conforms implies {
        all disj x, y : StepCompleted + CompRun | x.key != y.key
        all a : Attempt - resumes | a.key not in applied[own[a]]
    }
}
check A_Invariant_7_2 for 2 but 8 Event, 8 Key

-- A_Invariant_8_1: no step completion event follows a compensation onset event.
assert A_Invariant_8_1 {
    conforms implies no c : StepCompleted, o : Onset | o in own[c]
}
check A_Invariant_8_1 for 2 but 8 Event, 8 Key

-- A_Action_wiring_30: no compensation onset event names a roll-forward step.
assert A_Action_wiring_30 {
    conforms implies no (Onset.ostep & rollForward)
}
check A_Action_wiring_30 for 2 but 8 Event, 8 Key

-- A_Action_wiring_72: no cancel's onset (one naming no step) lands over an unresolved attempt.
assert A_Action_wiring_72 {
    conforms implies all o : Onset | no o.ostep implies no unresolved[own[o]]
}
check A_Action_wiring_72 for 2 but 8 Event, 8 Key

-- A_Action_wiring_73: no cancel's onset lands after a roll-forward step completed.
assert A_Action_wiring_73 {
    conforms implies all o : Onset | no o.ostep implies
        no ((StepCompleted & own[o]).step & rollForward)
}
check A_Action_wiring_73 for 2 but 8 Event, 8 Key

-- A_Non_goal_9: no compensating action is attempted or run for a roll-forward step.
assert A_Non_goal_9 {
    conforms implies no ((CompAttempt + CompRun).step & rollForward)
}
check A_Non_goal_9 for 2 but 8 Event, 8 Key

-- A_Check_8_2: every compensation run event for an overflowed step carries operator as the
-- input source.
assert A_Check_8_2 {
    conforms implies all r : CompRun | r.step in overflowed[own[r]] implies r.source = Operator
}
check A_Check_8_2 for 2 but 8 Event, 8 Key

-- A_Composition_state_13: every attempt marker and completion record carries the key derived
-- for its effect — the step's for a step's effect, the compensation's for a compensation's —
-- the same on every attempt, never one minted per attempt (Composition state 11, 12).
assert A_Composition_state_13 {
    conforms implies {
        all k : StepAttempt + StepCompleted | k.key = skeyOf[k.step, k.wf]
        all k : CompAttempt + CompRun + CompFailed | k.key = ckeyOf[k.step, k.wf]
    }
}
check A_Composition_state_13 for 2 but 8 Event, 8 Key

-- A_Replay_12: a halt event resolves no attempt — the unresolved attempts of the log before a
-- halt and of the same log with the halt are the same (Check 4.5).
assert A_Replay_12 {
    conforms implies all h : Halt | unresolved[own[h]] = unresolved[own[h] + h]
}
check A_Replay_12 for 2 but 8 Event, 8 Key

-- A_Replay_1: a run's replay keeps the events carrying its own id — no step attempt a forward
-- advance of a run opens passes over a declared step whose completion its own run has not
-- recorded, whatever another run sharing the log has completed (Replay 1; Composes 13; Event
-- schema 14).
assert A_Replay_1 {
    conforms implies all a : StepAttempt - resumes |
        a.step.ahead in (StepCompleted & a.earlier & runLog[a.wf]).step
}
check A_Replay_1 for 2 but 8 Event, 8 Key

-- A_Action_wiring_40: a compensating run whose every completion with a standing compensation
-- reference has its compensation run event, with no attempt unresolved and no standing
-- failure, is one the close may land on: a completion with a blank compensation reference owes
-- no compensation run and holds no close back (Action wiring 40; Term pending compensation;
-- Invariant 4.1).
assert A_Action_wiring_40 {
    conforms implies all w : Run | let s = runLog[w] |
        (no terminals[s] and phaseOf[s] = Compensating and no unresolved[s]
            and no standingFail[s]
            and (all c : StepCompleted & s | some c.compRef implies
                    some r : CompRun & s | r.step = c.step))
        implies closeAdmits[s]
}
check A_Action_wiring_40 for 2 but 8 Event, 8 Key

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowCommitted: two steps completed in order and the run committed.
run ShowCommitted {
    conforms
    #Step = 2
    some Commit
} for 2 but 8 Event, 8 Key

-- ShowCompensatedOnFailure: the walkthrough's shape — a step definitely fails, its onset
-- names it, the completed step is compensated and the run closes.
run ShowCompensatedOnFailure {
    conforms
    some o : Onset | some o.ostep
    some CompRun
    some Close
} for 2 but 8 Event, 8 Key

-- ShowCancelled: a cancel begins the compensating phase and the run closes compensated.
run ShowCancelled {
    conforms
    some o : Onset | no o.ostep
    some CompRun
    some Close
} for 2 but 8 Event, 8 Key

-- ShowHaltResumeCompensating: under halt-and-surface a compensation halts the run, the
-- operator's resume returns it to the compensating phase, and it closes.
run ShowHaltResumeCompensating {
    conforms
    Deployment.policy = HaltAndSurface
    some h : Halt | h.hphase = Compensating
    some (resumes & CompAttempt)
    some Close
} for 2 but 8 Event, 8 Key

-- ShowStandingFailureHalt: under continue a compensation failure is recorded and, nothing else
-- owed, the run halts naming it (Action wiring 38, 41).
run ShowStandingFailureHalt {
    conforms
    some f : CompFailed, h : Halt | f in own[h] and h.hsteps = f.step
        and no (Attempt & own[h] & unresolved[own[h]])
} for 2 but 8 Event, 8 Key

-- ShowRollForwardHalt: a failed pivot step halts the run in the forward phase; the resume
-- re-attempts it and the run commits.
run ShowRollForwardHalt {
    conforms
    some h : Halt | h.hphase = Forward and h.hsteps in rollForward
    some (resumes & StepAttempt)
    some Commit
} for 2 but 8 Event, 8 Key

-- ShowOverflow: a step's completion overflows its envelope, the run halts, the resume
-- carries the operator's compensation inputs, and a later compensation runs from them.
run ShowOverflow {
    conforms
    some c : StepCompleted | some c.overflow
    some a : resumes & StepAttempt | some a.inputs
    some r : CompRun | r.source = Operator
} for 2 but 8 Event, 8 Key

-- ShowUnresolvedStanding: an attempt marker nothing resolved stands in the forward phase (an
-- indeterminate verdict at the bound), and the log carries no terminal marker.
run ShowUnresolvedStanding {
    conforms
    some unresolved[Event]
    phaseOf[Event] = Forward
} for 2 but 8 Event, 8 Key

-- ShowReadOnlyStep: a step marked read-only, no effect step and declaring no compensating
-- action, is admitted and completes with a blank compensation reference (Primitive policy 29
-- refuses only an effect step marked read-only; FOUND (1), cured).
run ShowReadOnlyStep {
    conforms
    some c : StepCompleted | no c.step.effect and c.step.marker = ReadOnly and no c.compRef
} for 2 but 8 Event, 8 Key

-- ShowBlankReferenceClose: a step declaring no compensating action completes with a blank
-- compensation reference, the run is cancelled, and it closes compensated with no
-- compensation run for that step (FOUND (2), cured).
run ShowBlankReferenceClose {
    conforms
    some c : StepCompleted | no c.compRef
        and some t : Close | t.wf = c.wf and no (CompRun & runLog[c.wf] & step.(c.step))
} for 2 but 8 Event, 8 Key

-- ShowSharedLog: two runs' events interleave in the one Event Log instance, one run
-- committing and the other compensated, each replay keeping its own (Composes 3, 13).
run ShowSharedLog {
    conforms
    some disj w1, w2 : Run | some e1, e3 : runLog[w1], e2 : runLog[w2] |
        e1 in e2.earlier and e2 in e3.earlier
        and some (Commit & runLog[w1]) and some (Close & runLog[w2])
} for 2 but 8 Event, 8 Key

-- ShowContinueOrder: under continue, an older step's compensation run event lands before a
-- newer step's, the newer one's run after the operator's resume — the order Check 5.1 reads
-- (Action wiring 97; FOUND (3), cured).
run ShowContinueOrder {
    conforms
    some disj r1, r2 : CompRun | r1 in own[r2]
        and (completionOf[r1.step] & runLog[r1.wf]) in (completionOf[r2.step] & runLog[r2.wf]).earlier
} for 2 but 12 Event, 8 Key
