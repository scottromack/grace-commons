-- compensable-workflow.als
-- Alloy structural model for the Compensable Workflow composition (Grace Commons
-- compositions/compensable-workflow.md)
-- Grounded on Final Critique 8, 2026-11-06 at ef1f25a — Alloy layer authored 2026-11-11.
-- Derived validator; the English spec is the single source of truth. On any
-- disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
--
-- PURPOSE
-- Verify, by bounded exhaustive search, the STATIC data model of the composition: what one
-- state of one compensable workflow's records must satisfy — the state an auditor reads
-- (Generation acceptance): the definition the start event recorded, the spine's declared
-- states, and the step log, every event in Event Log's one sequence-number order, each with
-- the spine state its fire left (Action wiring 8; Execution Contract Database 1 commits the
-- two together). Every event is one its writer's rules let it append over the events before
-- it, as the replay reads them (Replay 1 to 14). How a call moves the run from one state to
-- the next — the verdicts, the lease, the target that honours a key, the world's effects —
-- is the TLA+ model's, compensable-workflow.tla, which owns the operation sequences.
--
-- RULES ENCODED (named by the page's own labels)
--   Invariant 2.1 — after every event (each can end an invocation, so a quiescent point
--                   can follow it) the spine's current state equals the replayed state
--                   (Check 2.1; a cross-check with the TLA+ model's Invariant_2_1).
--   Invariant 3.1 — every step completion event of an effect step outside the roll-forward
--                   steps carries exactly one compensation reference (Check 3.1), in the
--                   form the page settles: see FOUND (1) on an effect step marked read-only.
--   Invariant 4.1 — a log carrying a compensation close event carries a compensation run
--                   event for every step completion event (Check 4.1; cross-check).
--   Invariant 4.2 — a log carrying a commit event carries a step completion event for every
--                   declared step (Check 4.2; cross-check).
--   Invariant 4.3 — a log carrying a commit event carries no compensation onset event
--                   (Check 4.3; cross-check).
--   Invariant 4.5 — no terminal marker lands over an unresolved attempt (Check 4.4;
--                   cross-check).
--   Invariant 5.1 — the completed steps are compensated newest first: no compensating
--                   action is attempted for a step while a newer completed step with a
--                   compensating action has had none attempted (cross-check; see FOUND (3)
--                   on Check 5.1's wording).
--   Invariant 6.1 — no log carries two terminal markers (Check 6.1).
--   Invariant 6.2 — halted is never read as an outcome: neither the replay's outcome nor
--                   the spine's terminal states take it (Action wiring 62).
--   Invariant 6.3 — a resume marker returns the run, the replay's phase and the spine's
--                   state both, to the phase the newest halt event before it names
--                   (cross-check).
--   Invariant 7.2 — no two completion records carry one effect key (Check 7.1), and no
--                   attempt marker an advance opens to run an effect carries a key already
--                   in the applied effects (cross-check).
--   Invariant 8.1 — no step completion event follows a compensation onset event (Check 8.1;
--                   cross-check).
--   Action wiring 30 — no compensation onset event names a roll-forward step (cross-check).
--   Action wiring 72 — no cancel's onset lands over an unresolved attempt (cross-check).
--   Action wiring 73 — no cancel's onset lands after a roll-forward step completed
--                   (cross-check).
--   Non-goal 9    — no compensating action is attempted or run for a roll-forward step
--                   (cross-check).
--   Check 8.2     — every compensation run event for an overflowed step carries operator as
--                   the input source (Primitive policy 24; cross-check).
--   Composition state 13 — every attempt marker and completion record carries the key
--                   derived for its effect, never one minted per attempt (with Composition
--                   state 11 and 12; Check 7.2 and 7.3).
--   Replay 12     — a halt event resolves no attempt: the unresolved attempts of a halt's
--                   prefix and of that prefix with the halt are the same (Check 4.5).
--
-- NOT CHECKED HERE (nothing testable in Alloy)
--   Invariant 1.1, 1.2 (one event per recorded act, an act behind every event): a recorded
--   act is an act, not a record, so one state cannot tell an event with no act behind it
--   from one with an act, nor one act's two events from two acts.
--   Invariant 4 (the header) and 4.4 (every open obligation in the step log): an escaped
--   effect is an act at a target, outside every record; the TLA+ model keeps the world
--   (Invariant_4_AllOrCompensated, Invariant_4_4_OpenObligations). Its record-side parts are
--   4.1 to 4.3 and 4.5, checked here.
--   Invariant 7.1 (the at-most-once claim, given the target key discipline and the critical
--   section): the claim and the deployment's declarations are no records (External check 1,
--   3 and 6); the TLA+ model's Invariant_7_1 models the target and the section.
--
-- FOUND (recorded, not cured; see the Ledger's formal line)
--   (1) Primitive policy 12 refuses only an unmarked irreversible step (an effect step with
--       no compensating action and no step marker), so it admits an effect step marked
--       read-only with no compensating action; its step completion event carries no
--       compensation reference (Event schema 5), and it is outside the roll-forward steps,
--       so Invariant 3.1 as written fails on it. Term step marker says read-only is "for a
--       step with no external effect to reverse", but no rule refuses the pair. The check
--       below takes the steps the page settles (not marked read-only); run
--       FoundReadOnlyEffectStep shows the admitted state.
--   (2) A completed step declaring no compensating action (a step that is not an effect
--       step, or one marked read-only) stays in the completed steps (Replay 8 removes a step
--       only on a compensation run event) and so stays a pending compensation, yet no rule
--       says what a compensating advance does with it: there is no compensating action to
--       attempt (Action wiring 33 to 35), Action wiring 40 needs no pending compensation to
--       close and 41 needs none to halt, and Invariant 4.1 wants a compensation run event
--       for every step completion event. A run that aborts after such a step has no write
--       the page admits. Run FoundNoCompensationToRun shows the state.
--   (3) Check 5.1 reads compensation run events in the reverse of the step completion
--       order. Under the continue policy a newer step whose compensation definitely failed
--       is passed over (a standing failure is no pending compensation), the older step is
--       compensated, the run halts naming the failed step (Action wiring 41), and the
--       operator's resume runs it last: a conforming log whose run events are not in reverse
--       completion order. Invariant 5.1 holds in the reading checked below (attempted
--       newest first); run FoundContinueOrder shows the log.
--
-- SCOPE
-- One state of one compensable workflow: up to two declared steps (enough for newest
-- first, a pivot that is the last step, and a step that follows a pivot), each with its
-- effect-step flag, step marker and compensating action as the definition declares; up to
-- eight events in the step log (twelve for FoundContinueOrder); both compensation failure
-- policies. The model builds every log whose every event passes its writer's rule, and some
-- no run reaches. The verdicts are not records: an attempt marker that nothing resolved is
-- an attempt whose verdict was indeterminate, unknown, or not yet learned, and a halt over
-- it is admitted (Action wiring 47). No trace, no `var`, no stepping.
--
-- NOT MODELED HERE
--   - The parallel compensation order (open 2026-11-03-a): it has no semantics; the model
--     takes the reverse order (Capability requirement 1).
--   - The re-entry arm's re-run (Action wiring 15 to 19): whether a re-run appends an
--     attempt marker is open (2026-11-06-a); the model appends none and lets a completion
--     record or failure event resolve the standing marker.
--   - The spine fault (Primitive policy 27, Action wiring 57 to 59): no fault halt and no
--     finding; a fire the spine refuses leaves its state where it was, which Invariant 2.1
--     reads.
--   - The start's refusals, the payload cap, the input envelopes and their sizes
--     (Primitive policy 1 to 18, 26): a refused call writes nothing. The start event is the
--     definition the state carries; the compensable workflow record and the reads are left
--     out (Composition state 4 to 10, Action wiring 62 to 68 but 62 and 63, 78 to 80).
--   - The critical section, the lease, the bounds and the horizon (Capability requirement
--     5 to 9, 16, 17): durations and a second writer are the TLA+ model's.
--   - Storage failures (Action wiring 52 to 55): a failed append writes nothing.
--
-- HOW TO READ RESULTS
-- Every "check A_*" must return "No counterexample found" (UNSAT) — the asserted guarantee holds.
-- Every "run Show*" and "run Found*" must return at least one instance (SAT) — confirms
-- non-vacuity, or that the state a finding names is reachable.
-- A "check" returning a counterexample is a spec finding.

module compensable_workflow

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

-- Step: one step the definition declares (Term definition): the steps declared before it,
-- whether it is an effect step, its step marker and its compensating action where it has
-- them, and the effect keys derived for its effect and its compensation's (Composition
-- state 11, 12).
sig Step {
    ahead : set Step,
    effect : lone Yes,
    marker : lone Marker,
    comp : lone CompRef,
    skey : one Key,
    ckey : lone Key
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

-- Event: one event of the step log; earlier holds the events before it in sequence-number
-- order, and sp the spine's current state once the event and its fire committed.
abstract sig Event {
    earlier : set Event,
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
-- model takes one that tells effects apart: one key for each step's effect, one for each
-- declared compensation's and none for a step declaring none, no two alike.
fact KeyDerivation {
    all s : Step | some s.comp iff some s.ckey
    all disj s, t : Step | s.skey != t.skey and no (s.ckey & t.ckey)
    no (Step.skey & Step.ckey)
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

-- prev: the event immediately before e.
fun prev[e : Event] : set Event {
    { p : e.earlier | e.earlier - p in p.earlier }
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

-- pending: the pending compensations, the completed steps no standing failure names.
fun pending[s : set Event] : set Step {
    completed[s] - standingFail[s]
}

-- newestPending: the pending compensation the reverse order takes first, the step declared
-- last (steps complete in declared order) (Capability requirement 1; Invariant 5.1).
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
-- (Primitive policy 12).
pred startAdmits {
    all st : Step | (some st.effect and no st.comp) implies some st.marker
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
    let p = a.earlier, h = newestHalt[p] {
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
    let p = a.earlier {
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
        a.key = a.step.skey
    }
}

-- writesCompAttempt: a compensating advance's attempt marker for the newest pending
-- compensation, which has a compensating action to run (Action wiring 32 to 35), or a
-- halted advance's resume marker after a halt naming the compensating phase (Action wiring
-- 86).
pred writesCompAttempt[a : CompAttempt] {
    let p = a.earlier {
        advanceOpen[p]
        no a.asserted implies {
            phaseOf[p] = Compensating
            no unresolved[p]
            a.step in newestPending[p]
            some a.step.comp
        }
        some a.asserted implies resumeWrites[a, Compensating]
        a.key = a.step.ckey
    }
}

-- writesStepCompleted: the completion of an unresolved step attempt in the forward phase,
-- carrying the step's key, its compensation reference and, where the target answered more
-- than the envelope, the truncation mark (Action wiring 21, 25; Event schema 5; Primitive
-- policy 19, 20).
pred writesStepCompleted[c : StepCompleted] {
    let p = c.earlier {
        advanceOpen[p]
        phaseOf[p] = Forward
        some a : StepAttempt & unresolved[p] | a.step = c.step
        c.key = c.step.skey
        c.compRef = c.step.comp
        some c.overflow implies some c.step.comp
    }
}

-- writesCompRun: the run of an unresolved compensation attempt in the compensating phase,
-- under the compensation's key, with operator as the input source exactly for an overflowed
-- step (Action wiring 36; Primitive policy 23, 24).
pred writesCompRun[r : CompRun] {
    let p = r.earlier {
        advanceOpen[p]
        phaseOf[p] = Compensating
        some a : CompAttempt & unresolved[p] | a.step = r.step
        r.key = r.step.ckey
        r.step in overflowed[p] implies r.source = Operator else r.source = Recorded
    }
}

-- writesCompFailed: under the continue policy, a definitely failed compensation attempt is
-- recorded (Action wiring 38).
pred writesCompFailed[f : CompFailed] {
    let p = f.earlier {
        advanceOpen[p]
        phaseOf[p] = Compensating
        Deployment.policy = Continue
        some a : CompAttempt & unresolved[p] | a.step = f.step
        f.key = f.step.ckey
    }
}

-- writesOnset: a forward advance whose step attempt definitely failed, the step outside the
-- roll-forward steps, names the step (Action wiring 26, 30; Event schema 9); an admitted
-- cancel names none and lands only with no unresolved attempt and no roll-forward step
-- completed (Action wiring 71 to 74, 87; Event schema 13).
pred writesOnset[o : Onset] {
    let p = o.earlier {
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
    let p = h.earlier, ph = phaseOf[p] {
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
    let p = t.earlier {
        advanceOpen[p]
        phaseOf[p] = Forward
        no unresolved[p]
        no nextStep[p]
    }
}

-- writesClose: a compensating advance closes with no pending compensation, no unresolved
-- attempt and no standing failure (Action wiring 40).
pred writesClose[t : Close] {
    let p = t.earlier {
        advanceOpen[p]
        phaseOf[p] = Compensating
        no pending[p]
        no unresolved[p]
        no standingFail[p]
    }
}

-- overflowHalts: whatever follows an overflowed step's completion is the halt naming the
-- forward phase and that step (Primitive policy 21).
pred overflowHalts {
    all c : StepCompleted, e : Event | (some c.overflow and prev[e] = c) implies
        (e in Halt and e.hphase = Forward and e.hsteps = c.step)
}

-- resumesComplete: a halted advance appends a resume marker for every named step before
-- anything else lands (Action wiring 49, 50).
pred resumesComplete {
    all e : Event - resumes | let h = newestHalt[e.earlier] |
        some h implies (all st : h.hsteps | some r : resumes & e.earlier | h in r.earlier and r.step = st)
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

-- spBefore: the spine's state before an event's fire.
fun spBefore[e : Event] : State {
    some prev[e] => prev[e].sp else Spine.initial
}

-- fireTo: what State Machine's fire answers from a state under a wire spelling: the declared
-- transition's to state, none from a terminal state or where none is declared (a refusal).
fun fireTo[from : State, w : set Wire] : set State {
    from in Spine.terminal => none else w.(from.spineTrans)
}

-- fires: the composition fires each transition-bearing event's declared transition with the
-- event (Action wiring 8; Composes 4); a refused fire leaves the spine where it was.
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
    conforms implies all e : Event | e.sp = replayed[e.earlier + e]
}
check A_Invariant_2_1 for 2 but 8 Event, 5 Key

-- A_Invariant_3_1: every step completion event of an effect step outside the roll-forward
-- steps carries exactly one compensation reference — over the steps not marked read-only,
-- the form the page settles (FOUND (1)).
assert A_Invariant_3_1 {
    conforms implies all c : StepCompleted |
        (some c.step.effect and c.step not in rollForward and c.step.marker != ReadOnly)
            implies one c.compRef
}
check A_Invariant_3_1 for 2 but 8 Event, 5 Key

-- A_Invariant_4_1: a log carrying a compensation close event carries a compensation run
-- event for every step completion event.
assert A_Invariant_4_1 {
    conforms implies (some Close implies
        all c : StepCompleted | some r : CompRun | r.step = c.step)
}
check A_Invariant_4_1 for 2 but 8 Event, 5 Key

-- A_Invariant_4_2: a log carrying a commit event carries a step completion event for every
-- declared step.
assert A_Invariant_4_2 {
    conforms implies (some Commit implies all st : Step | some completionOf[st])
}
check A_Invariant_4_2 for 2 but 8 Event, 5 Key

-- A_Invariant_4_3: a log carrying a commit event carries no compensation onset event.
assert A_Invariant_4_3 {
    conforms implies (some Commit implies no Onset)
}
check A_Invariant_4_3 for 2 but 8 Event, 5 Key

-- A_Invariant_4_5: no terminal marker lands while an attempt stands unresolved before it.
assert A_Invariant_4_5 {
    conforms implies all t : Commit + Close | no unresolved[t.earlier]
}
check A_Invariant_4_5 for 2 but 8 Event, 5 Key

-- A_Invariant_5_1: newest first — when a compensating advance attempts a step's compensating
-- action, every newer completed step with a compensating action has had its own attempted.
assert A_Invariant_5_1 {
    conforms implies all a : CompAttempt - resumes, y : Step |
        (some y.comp and some completionOf[y]
            and completionOf[a.step] in completionOf[y].earlier)
        implies some (CompAttempt & step.y & a.earlier)
}
check A_Invariant_5_1 for 2 but 8 Event, 5 Key

-- A_Invariant_6_1: no log carries two terminal markers.
assert A_Invariant_6_1 {
    conforms implies lone (Commit + Close)
}
check A_Invariant_6_1 for 2 but 8 Event, 5 Key

-- A_Invariant_6_2: halted is never an outcome — not among the spine's terminal states, and
-- never an outcome the replay derives.
assert A_Invariant_6_2 {
    conforms implies {
        Halted not in Spine.terminal
        all e : Event | Halted not in outcomeOf[e.earlier + e]
    }
}
check A_Invariant_6_2 for 2 but 8 Event, 5 Key

-- A_Invariant_6_3: a resume marker returns the run to the phase the newest halt before it
-- names — the replay's phase and the spine's state both.
assert A_Invariant_6_3 {
    conforms implies all r : resumes | let h = newestHalt[r.earlier] |
        r.sp = h.hphase and phaseOf[r.earlier + r] = h.hphase
}
check A_Invariant_6_3 for 2 but 8 Event, 5 Key

-- A_Invariant_7_2: no effect runs twice under a recorded key — no two completion records
-- carry one key (Check 7.1), and no attempt marker an advance opens to run an effect (a resume
-- marker re-runs nothing whose key is applied) carries a key already applied before it.
assert A_Invariant_7_2 {
    conforms implies {
        all disj x, y : StepCompleted + CompRun | x.key != y.key
        all a : Attempt - resumes | a.key not in applied[a.earlier]
    }
}
check A_Invariant_7_2 for 2 but 8 Event, 5 Key

-- A_Invariant_8_1: no step completion event follows a compensation onset event.
assert A_Invariant_8_1 {
    conforms implies no c : StepCompleted, o : Onset | o in c.earlier
}
check A_Invariant_8_1 for 2 but 8 Event, 5 Key

-- A_Action_wiring_30: no compensation onset event names a roll-forward step.
assert A_Action_wiring_30 {
    conforms implies no (Onset.ostep & rollForward)
}
check A_Action_wiring_30 for 2 but 8 Event, 5 Key

-- A_Action_wiring_72: no cancel's onset (one naming no step) lands over an unresolved attempt.
assert A_Action_wiring_72 {
    conforms implies all o : Onset | no o.ostep implies no unresolved[o.earlier]
}
check A_Action_wiring_72 for 2 but 8 Event, 5 Key

-- A_Action_wiring_73: no cancel's onset lands after a roll-forward step completed.
assert A_Action_wiring_73 {
    conforms implies all o : Onset | no o.ostep implies
        no ((StepCompleted & o.earlier).step & rollForward)
}
check A_Action_wiring_73 for 2 but 8 Event, 5 Key

-- A_Non_goal_9: no compensating action is attempted or run for a roll-forward step.
assert A_Non_goal_9 {
    conforms implies no ((CompAttempt + CompRun).step & rollForward)
}
check A_Non_goal_9 for 2 but 8 Event, 5 Key

-- A_Check_8_2: every compensation run event for an overflowed step carries operator as the
-- input source.
assert A_Check_8_2 {
    conforms implies all r : CompRun | r.step in overflowed[r.earlier] implies r.source = Operator
}
check A_Check_8_2 for 2 but 8 Event, 5 Key

-- A_Composition_state_13: every attempt marker and completion record carries the key derived
-- for its effect — the step's for a step's effect, the compensation's for a compensation's —
-- the same on every attempt, never one minted per attempt (Composition state 11, 12).
assert A_Composition_state_13 {
    conforms implies {
        all k : StepAttempt + StepCompleted | k.key = k.step.skey
        all k : CompAttempt + CompRun + CompFailed | k.key = k.step.ckey
    }
}
check A_Composition_state_13 for 2 but 8 Event, 5 Key

-- A_Replay_12: a halt event resolves no attempt — the unresolved attempts of the log before a
-- halt and of the same log with the halt are the same (Check 4.5).
assert A_Replay_12 {
    conforms implies all h : Halt | unresolved[h.earlier] = unresolved[h.earlier + h]
}
check A_Replay_12 for 2 but 8 Event, 5 Key

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
} for 2 but 8 Event, 5 Key

-- ShowCompensatedOnFailure: the walkthrough's shape — a step definitely fails, its onset
-- names it, the completed step is compensated and the run closes.
run ShowCompensatedOnFailure {
    conforms
    some o : Onset | some o.ostep
    some CompRun
    some Close
} for 2 but 8 Event, 5 Key

-- ShowCancelled: a cancel begins the compensating phase and the run closes compensated.
run ShowCancelled {
    conforms
    some o : Onset | no o.ostep
    some CompRun
    some Close
} for 2 but 8 Event, 5 Key

-- ShowHaltResumeCompensating: under halt-and-surface a compensation halts the run, the
-- operator's resume returns it to the compensating phase, and it closes.
run ShowHaltResumeCompensating {
    conforms
    Deployment.policy = HaltAndSurface
    some h : Halt | h.hphase = Compensating
    some (resumes & CompAttempt)
    some Close
} for 2 but 8 Event, 5 Key

-- ShowStandingFailureHalt: under continue a compensation failure is recorded and, nothing else
-- owed, the run halts naming it (Action wiring 38, 41).
run ShowStandingFailureHalt {
    conforms
    some f : CompFailed, h : Halt | f in h.earlier and h.hsteps = f.step
        and no (Attempt & h.earlier & unresolved[h.earlier])
} for 2 but 8 Event, 5 Key

-- ShowRollForwardHalt: a failed pivot step halts the run in the forward phase; the resume
-- re-attempts it and the run commits.
run ShowRollForwardHalt {
    conforms
    some h : Halt | h.hphase = Forward and h.hsteps in rollForward
    some (resumes & StepAttempt)
    some Commit
} for 2 but 8 Event, 5 Key

-- ShowOverflow: a step's completion overflows its envelope, the run halts, the resume
-- carries the operator's compensation inputs, and a later compensation runs from them.
run ShowOverflow {
    conforms
    some c : StepCompleted | some c.overflow
    some a : resumes & StepAttempt | some a.inputs
    some r : CompRun | r.source = Operator
} for 2 but 8 Event, 5 Key

-- ShowUnresolvedStanding: an attempt marker nothing resolved stands in the forward phase (an
-- indeterminate verdict at the bound), and the log carries no terminal marker.
run ShowUnresolvedStanding {
    conforms
    some unresolved[Event]
    phaseOf[Event] = Forward
} for 2 but 8 Event, 5 Key

-- FoundReadOnlyEffectStep: FOUND (1) — an effect step marked read-only, declaring no
-- compensating action, admitted and completed with no compensation reference.
run FoundReadOnlyEffectStep {
    conforms
    some c : StepCompleted | some c.step.effect and c.step.marker = ReadOnly and no c.compRef
} for 2 but 8 Event, 5 Key

-- FoundNoCompensationToRun: FOUND (2) — the run compensating, nothing unresolved, and the
-- newest pending compensation a step with no compensating action to attempt.
run FoundNoCompensationToRun {
    conforms
    phaseOf[Event] = Compensating
    no unresolved[Event]
    some newestPending[Event]
    no newestPending[Event].comp
} for 2 but 8 Event, 5 Key

-- FoundContinueOrder: FOUND (3) — under continue, an older step's compensation run event
-- lands before a newer step's, the newer one's run after the operator's resume.
run FoundContinueOrder {
    conforms
    some disj r1, r2 : CompRun | r1 in r2.earlier
        and completionOf[r1.step] in completionOf[r2.step].earlier
} for 2 but 12 Event, 5 Key
