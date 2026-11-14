---- MODULE compensable-workflow-cancel-nofire-buggy ----
\* Grace Commons — Compensable Workflow composition.
\* Spec-level formal sibling of compositions/compensable-workflow.md.
\* BUGGY TWIN (cancel-nofire): A cancel appends the onset and leaves the fire out (Invariant 2.1 broken).
\* The checker must reject it. Everything else is the correct model.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-08 (the first model, 2026-06-16, checked two claims over a bare
\* effect-then-record window). It now carries what the page grew into: an attempt marker
\* before every effect, the four-way verdict (applied, failed, indeterminate, unknown),
\* the critical section as a second writer with lease expiry as its terminus, the halt that
\* parks an attempt without resolving it, the operator's resume, the effect key horizon,
\* the compensation failure policy, and the pivot.
\*
\* WHAT THIS MODEL CHECKS
\* One compensable workflow of two steps, each with a compensating action (the step marked
\* pivot, where the run has one, has none). What it checks is that the run rests only as
\* committed or compensated, and that no real effect is left standing or applied twice,
\* whatever the engine, the lease, the target and the operator do:
\*   - Invariant 4 (all-or-compensated)  a committed run has every effect landed and none
\*                    reversed; a compensated run has every landed effect reversed, the one an
\*                    indeterminate verdict left unrecorded included.
\*   - Invariant 4.1, 4.2, 4.3, 4.4, 4.5  the close carries a compensation run for every completion; the
\*                    commit a completion for every step and no onset; an effect that landed with no
\*                    completion stays an unresolved attempt; no terminal marker over one.
\*   - Invariant 5.1  completed steps are compensated newest first.
\*   - Invariant 6.3  a resume marker returns the run to the phase the halt names.
\*   - Invariant 7.1  no effect is applied twice at a target that honours the effect key
\*                    inside the horizon, under the critical section.
\*   - Invariant 7.2 and Check 7.1  the composition runs no effect whose key is already
\*                    recorded, and records no key twice.
\*   - Invariant 8.1  no step completion follows a compensation onset.
\*   - Invariant 2.1  the spine equals the replayed state at every quiescent point.
\*   - Replay 12 (Check 4.5)  a halt event resolves no attempt it parks.
\*   - Primitive policy 23 to 25 (Check 8.2)  an overflowed step is compensated from the operator's
\*                    inputs, never the truncated ones.
\*   - Action wiring 30, 72, 73 and Non-goal 9  a failed roll-forward step, a cancel over an
\*                    unresolved attempt and a cancel past the pivot begin no compensation, and no
\*                    roll-forward step is compensated.
\*
\* BOUND
\* Two steps (enough for newest first and for a pivot that is the last step), both failure policies
\* and both pivot shapes (none, the second step), every verdict at every effect, the lease expiring at
\* any point, a key lapsing while the run rests halted. The space is small (3,808 states) and
\* exhaustive. Three steps run past the checker's depth cap of 40, which is a hard error and not a
\* truncation, so two is the bound.
\*
\* HOW AN INVARIANT IS READ
\* The step log is the run's only truth and the replay derives every projection from it
\* (Composition state 1 to 3). The log grows with the run, so the model keeps what the replay
\* derives instead: the phase, each step's place (open, done, compensated, or done with a
\* standing compensation failure), the unresolved attempt markers (as effect keys), the halt's phase
\* and named steps. Beside it the model keeps the world the page does not own: how many times each
\* effect really landed at its target, and the keys a target has forgotten. A property of the whole
\* run is read two ways. A property of the state (all-or-compensated, at most once, the terminal
\* rules) is an invariant over the state. A property of a step (newest first, no record twice, no
\* onset on an indeterminate verdict) is a name the step adds to `viol` when it breaks the rule,
\* and the named invariants below say `viol` does not hold their name. A step reads the summary and
\* the world, never the rule it is checked against, so a rule a step gets wrong is caught.
\*
\* THE TWO WRITERS AND THE EFFECT
\* An invocation takes the critical section, re-enters from the log, appends an attempt marker,
\* runs the effect and learns a verdict, and then records. Those are separate steps (`pc`:
\* idle, held, marked, ran), so the window between the effect and its record is open, and the
\* lease can expire inside it: the expired invocation holds an effect reply it must discard
\* (Action wiring 3 to 5; `ghost`), while the next invocation re-enters from the log. A target honours an
\* effect key it has seen until the key lapses (`lap`); a key can lapse only while the run rests
\* halted, and an operator whose parked key has lapsed cannot truthfully assert the horizon (Primitive
\* policy 7), so the run stays halted (open 2026-11-03-d).
\*
\* SCOPE (named)
\* - The parallel compensation order has no semantics on the page (open 2026-11-03-a); the model
\*   takes the reverse order.
\* - Several unresolved attempts (the re-entry after a halt that named two steps) are re-run one per
\*   invocation; Action wiring 15 says all in one, once each per execution, which the model cannot
\*   break, and no invariant reads the difference.
\* - The overflow landing (Primitive policy 9 to 11, 18 to 25: a target answering reversal inputs
\*   larger than the envelope, the truncation mark, the operator's compensation inputs) is a claim
\*   about which inputs reverse a step. The model's steps carry no inputs, so it cannot read it.
\* - The spine fault (Primitive policy 27, Action wiring 57 to 59) is the spine and the log
\*   disagreeing after a landed record. A transition-bearing event and its fire commit together
\*   (Execution Contract Database 1), so the model's fire is part of every write and the fault is
\*   unreachable; the fire's effect on Invariant 2.1 is kept (`sp`).
\* - The start (validation, sizing, the payload cap, the instantiate) and the reads: single-call
\*   refusals before any state is touched.
\* - Invariant 1 (one event per recorded act), Invariant 3.1 (pairing) and Invariant 6.1 and 6.2
\*   are by construction of the projection: a step is one event, a step carries its compensation,
\*   the phase is one value, halted is a phase and never an outcome.
\* - The critical section's cross-node exclusion (Capability requirement 6) and the lease length
\*   (Capability requirement 9) are the host's: the model takes one holder at a time and lets the
\*   lease expire at any point.
\*
\* ENCODING (the proven idiom of compositions/idempotent-reservation.tla)
\* - No Sequences, RECURSIVE or CHOOSE; flat \E/\A; column-aligned junctions; the operators below
\*   are pure over their arguments and read no state variable free.
\* - Keys are numbered: key i is step i's effect, key N + i is step i's compensation.

EXTENDS Naturals

CONSTANT N                  \* number of steps (2: enough for newest first)

Steps == 1..N
Keys  == 1..(2 * N)

VARIABLES
    ph,         \* the phase or outcome the replay derives
    hp,         \* the phase the standing halt names ("none" when no halt stands)
    hs,         \* the steps the standing halt names
    stp,        \* Steps -> place: open | done | comp | fail
    att,        \* the unresolved attempt markers, as effect keys
    eff,        \* Keys -> 0..2 ; real applications of the effect at its target
    lap,        \* the effect keys a target has forgotten (the horizon elapsed)
    pc,         \* the invocation: idle | held | marked | ran
    cur,        \* the effect key the invocation runs (0 outside marked and ran)
    vd,         \* the verdict the invocation holds: none | applied | failed | indet | unknown
    ghost,      \* the effect key of an expired invocation's reply in flight (0 none)
    sp,         \* the spine's state
    ov,         \* the steps whose completion carries the truncation mark (overflowed steps)
    op,         \* the steps whose resume marker carries the operator's compensation inputs
    viol,       \* the names of the rules a step has broken
    piv,        \* the pivot: steps from this one on are roll-forward (0 : the run has no pivot)
    pol         \* the compensation failure policy: halt | continue

vars == <<ph, hp, hs, stp, att, eff, lap, pc, cur, vd, ghost, sp, ov, op, viol, piv, pol>>

Verdicts == {"applied", "failed", "indet", "unknown"}

\* ----- pure helpers over their arguments -----

\* The step a key belongs to.
KStep(k) == IF k <= N THEN k ELSE k - N

\* A key is a compensation's when it is above the step keys.
IsComp(k) == k > N

\* A step is roll-forward when the pivot is set and the step is at or after it.
Roll(pv, i) == pv /= 0 /\ i >= pv

\* A real effect cannot land more than twice in the counter (two is already the break).
Min2(x) == IF x > 2 THEN 2 ELSE x

\* The count an application at the target leaves: a target that honours the key does nothing
\* the second time (it answers the original result); a target that forgot the key applies again.
Ap(e0, lapped) == IF lapped THEN Min2(e0 + 1) ELSE IF e0 = 0 THEN 1 ELSE e0

\* The counts the target can leave for a verdict: applied lands once; failed only where nothing
\* landed; indeterminate may or may not have landed; unknown only where the target recognises a
\* key whose outcome it lost, so only a key it applied and still honours.
Land(e0, lapped, v) ==
    IF v = "applied" THEN {Ap(e0, lapped)}
    ELSE IF v = "failed" THEN (IF e0 = 0 THEN {0} ELSE {})
    ELSE IF v = "indet" THEN {e0, Ap(e0, lapped)}
    ELSE (IF e0 = 1 /\ ~lapped THEN {1} ELSE {})

\* The keys a halt names: the step's effect key in the forward phase, its compensation's otherwise.
Named(h, s) == IF h = "forward" THEN s ELSE {N + i : i \in s}

\* A step's completion (or compensation run) is recorded under its key.
Recorded(st, k) == IF k <= N THEN st[k] /= "open" ELSE st[k - N] = "comp"

\* The keys a halted run still owes: the unresolved attempts and the keys the halt names, less
\* those whose completion record already landed (Replay 11 holds a marker only while its key is
\* not in the applied effects, so a resume marker for a recorded key is no attempt).
Parked(st, a, h, s) == {k \in (a \cup Named(h, s)) : ~Recorded(st, k)}

\* The rule a compensation run breaks when it reverses an overflowed step from the truncated inputs
\* the completion kept and not from the operator's (Primitive policy 23 to 25, Check 8.2).
OvFlags(k, o, p) ==
    IF IsComp(k) /\ KStep(k) \in o /\ KStep(k) \notin p THEN {"Primitive_25"} ELSE {}

\* A completed step no compensation run names, and no standing failure names.
Pending(st) == {i \in Steps : st[i] = "done"}

\* A completed step a standing compensation failure names.
Fails(st) == {i \in Steps : st[i] = "fail"}

\* The newest pending compensation (the reverse order).
NewestPending(st, i) == st[i] = "done" /\ \A j \in Steps : j > i => st[j] /= "done"

\* The first step with no completion (the next step).
NextOpen(st, i) == st[i] = "open" /\ \A j \in Steps : j < i => st[j] /= "open"

\* Every step has a completion event.
AllRecorded(st) == \A i \in Steps : st[i] /= "open"

\* A completion exists for a roll-forward step.
RollDone(pv, st) == \E i \in Steps : Roll(pv, i) /\ st[i] /= "open"

\* The rules a completion record breaks: a key recorded twice (Check 7.1); a step completion once a
\* compensation onset stands (Invariant 8.1); a compensation run before a newer pending one
\* (Invariant 5.1).
ComplFlags(st, k, phs) ==
    (IF Recorded(st, k) THEN {"Check_7_1"} ELSE {})
    \cup (IF ~IsComp(k) /\ phs /= "forward" THEN {"Invariant_8_1"} ELSE {})
    \cup (IF IsComp(k) /\ (\E j \in Steps : j > KStep(k) /\ st[j] = "done") THEN {"Invariant_5_1"} ELSE {})

\* ----- state -----

TypeOK ==
    /\ ph \in {"forward", "compensating", "halted", "committed", "compensated"}
    /\ hp \in {"none", "forward", "compensating"}
    /\ hs \subseteq Steps
    /\ stp \in [Steps -> {"open", "done", "comp", "fail"}]
    /\ att \subseteq Keys
    /\ eff \in [Keys -> 0..2]
    /\ lap \subseteq Keys
    /\ pc \in {"idle", "held", "marked", "ran"}
    /\ cur \in 0..(2 * N)
    /\ vd \in {"none", "applied", "failed", "indet", "unknown"}
    /\ ghost \in 0..(2 * N)
    /\ sp \in {"forward", "compensating", "halted", "committed", "compensated"}
    /\ ov \subseteq Steps
    /\ op \subseteq Steps
    /\ piv \in 0..N
    /\ pol \in {"halt", "continue"}

\* The run starts in the forward phase, nothing recorded, nothing applied, no invocation. The
\* pivot and the failure policy are the deployment's: the model takes each shape the page admits.
Init ==
    /\ piv \in {0, N}
    /\ pol \in {"halt", "continue"}
    /\ ph = "forward"
    /\ hp = "none"
    /\ hs = {}
    /\ stp = [i \in Steps |-> "open"]
    /\ att = {}
    /\ eff = [k \in Keys |-> 0]
    /\ lap = {}
    /\ pc = "idle"
    /\ cur = 0
    /\ vd = "none"
    /\ ghost = 0
    /\ sp = "forward"
    /\ ov = {}
    /\ op = {}
    /\ viol = {}

\* ----- the invocation: take, re-enter, mark, run, record -----

\* An [Advance] takes the critical section (Action wiring 1). A call on a halted run carries the
\* operator's horizon assertion (Primitive policy 7), which an operator makes only while every
\* parked or named key is still honoured at its target; a call without it answers invalid-request
\* and writes nothing, which the model leaves out as a stutter. A terminal run answers
\* already-terminal (Action wiring 10) and writes nothing.
Take ==
    /\ pc = "idle"
    /\ ph \in {"forward", "compensating", "halted"}
    /\ (ph = "halted") => (Parked(stp, att, hp, hs) \cap lap = {})
    /\ pc' = "held"
    /\ UNCHANGED <<ph, hp, hs, stp, att, eff, lap, cur, vd, ghost, sp, viol, piv, pol, ov, op>>

\* The halted arm (Action wiring 49, 50, 85, 86): append a resume marker, an attempt marker, for
\* every named step, and fire the transition back to the phase the halt names (Invariant 6.3). A
\* resume marker for an overflowed step carries the operator's compensation inputs (Event schema 12,
\* Primitive policy 9, 23); the marker for a recorded key is no unresolved attempt (Replay 11).
Resume ==
    /\ pc = "held"
    /\ ph = "halted"
    /\ \E np \in {hp} :
        /\ ph' = np
        /\ sp' = np
        /\ viol' = viol \cup (IF np /= hp THEN {"Invariant_6_3"} ELSE {})
    /\ att' = Parked(stp, att, hp, hs)
    /\ op' = op \cup (hs \cap ov)
    /\ hp' = "none"
    /\ hs' = {}
    /\ UNCHANGED <<stp, eff, lap, pc, cur, vd, ghost, ov, piv, pol>>

\* The re-entry arm (Action wiring 11, 15, 16, 19): an unresolved attempt is re-run under its own
\* key, newest first, before any new effect; the re-run opens no marker, the one that stands is the
\* attempt (open 2026-11-06-a, and Action wiring 19).
ReEntry ==
    /\ pc = "held"
    /\ ph \in {"forward", "compensating"}
    /\ att /= {}
    /\ \E k \in att :
        /\ \A j \in att : j <= k
        /\ cur' = k
    /\ pc' = "marked"
    /\ UNCHANGED <<ph, hp, hs, stp, att, eff, lap, vd, ghost, sp, viol, piv, pol, ov, op>>

\* A forward advance with no unresolved attempt appends the attempt marker for the next step
\* (Action wiring 22), before any effect (Action wiring 23).
StartStep ==
    /\ pc = "held"
    /\ ph = "forward"
    /\ att = {}
    /\ \E i \in Steps :
        /\ NextOpen(stp, i)
        /\ att' = {i}
        /\ cur' = i
    /\ pc' = "marked"
    /\ UNCHANGED <<ph, hp, hs, stp, eff, lap, vd, ghost, sp, viol, piv, pol, ov, op>>

\* A forward advance with no next step appends the commit event (Action wiring 31) and fires the
\* terminal transition. The run is committed.
Commit ==
    /\ pc = "held"
    /\ ph = "forward"
    /\ att = {}
    /\ AllRecorded(stp)
    /\ ph' = "committed"
    /\ sp' = "committed"
    /\ pc' = "idle"
    /\ UNCHANGED <<hp, hs, stp, att, eff, lap, cur, vd, ghost, viol, piv, pol, ov, op>>

\* A compensating advance with no unresolved attempt and a pending compensation appends the
\* compensation attempt marker for the newest pending step (Action wiring 32 to 34, Invariant 5.1).
StartComp ==
    /\ pc = "held"
    /\ ph = "compensating"
    /\ att = {}
    /\ \E i \in Steps :
        /\ NewestPending(stp, i)
        /\ att' = {N + i}
        /\ cur' = N + i
    /\ pc' = "marked"
    /\ UNCHANGED <<ph, hp, hs, stp, eff, lap, vd, ghost, sp, viol, piv, pol, ov, op>>

\* A compensating advance with nothing pending, no unresolved attempt and no standing failure
\* appends the compensation close event (Action wiring 40). The run is compensated.
Close ==
    /\ pc = "held"
    /\ ph = "compensating"
    /\ att = {}
    /\ Pending(stp) = {}
    /\ Fails(stp) = {}
    /\ ph' = "compensated"
    /\ sp' = "compensated"
    /\ pc' = "idle"
    /\ UNCHANGED <<hp, hs, stp, att, eff, lap, cur, vd, ghost, viol, piv, pol, ov, op>>

\* A compensating advance with nothing pending and no unresolved attempt but a standing failure
\* appends a halt event naming every step a standing failure names (Action wiring 41).
HaltStanding ==
    /\ pc = "held"
    /\ ph = "compensating"
    /\ att = {}
    /\ Pending(stp) = {}
    /\ Fails(stp) /= {}
    /\ ph' = "halted"
    /\ sp' = "halted"
    /\ hp' = "compensating"
    /\ hs' = Fails(stp)
    /\ pc' = "idle"
    /\ UNCHANGED <<stp, att, eff, lap, cur, vd, ghost, viol, piv, pol, ov, op>>

\* The effect runs under its key (Action wiring 24, 35) and the target answers a verdict. The
\* model reads the target's side from `eff` and `lap`. The composition runs no effect whose key is
\* in the applied effects (Invariant 7.2).
RunEffect ==
    /\ pc = "marked"
    /\ \E v \in Verdicts :
        \E e \in Land(eff[cur], cur \in lap, v) :
            /\ vd' = v
            /\ eff' = [eff EXCEPT ![cur] = e]
    /\ viol' = viol \cup (IF Recorded(stp, cur) THEN {"Invariant_7_2"} ELSE {})
    /\ pc' = "ran"
    /\ UNCHANGED <<ph, hp, hs, stp, att, lap, cur, ghost, sp, piv, pol, ov, op>>

\* An applied verdict whose completion record lands: the step completion event (Action wiring 21,
\* 25) or the compensation run event (Action wiring 36), and the fire. The key leaves the
\* unresolved attempts (Replay 11). The invocation returns and releases the section.
RecordApplied ==
    /\ pc = "ran"
    /\ vd = "applied"
    /\ stp' = [stp EXCEPT ![KStep(cur)] = IF IsComp(cur) THEN "comp" ELSE "done"]
    /\ att' = att \ {cur}
    /\ viol' = viol \cup ComplFlags(stp, cur, ph) \cup OvFlags(cur, ov, op)
    /\ pc' = "idle"
    /\ cur' = 0
    /\ vd' = "none"
    /\ UNCHANGED <<ph, hp, hs, eff, lap, ghost, sp, piv, pol, ov, op>>

\* An applied forward verdict whose reply carries reversal inputs larger than the step's input
\* envelope (Primitive policy 19 to 22): the completion record lands with the inputs truncated and
\* the truncation mark set, a halt event names the forward phase and the step, and the invocation
\* answers arguments-overflow. The key is recorded, so no attempt is left to park.
RecordOverflow ==
    /\ pc = "ran"
    /\ vd = "applied"
    /\ ~IsComp(cur)
    /\ stp' = [stp EXCEPT ![cur] = "done"]
    /\ att' = att \ {cur}
    /\ ov' = ov \cup {cur}
    /\ ph' = "halted"
    /\ sp' = "halted"
    /\ hp' = "forward"
    /\ hs' = {cur}
    /\ viol' = viol \cup ComplFlags(stp, cur, ph)
    /\ pc' = "idle"
    /\ cur' = 0
    /\ vd' = "none"
    /\ UNCHANGED <<eff, lap, ghost, op, piv, pol>>

\* An applied verdict whose completion record does not land before the step completion bound: the
\* invocation answers storage-failure naming effect-landed (Action wiring 52, 53). The attempt
\* marker stands as the unresolved attempt, the effect stands unrecorded.
RecordStorageFail ==
    /\ pc = "ran"
    /\ vd = "applied"
    /\ pc' = "idle"
    /\ cur' = 0
    /\ vd' = "none"
    /\ UNCHANGED <<ph, hp, hs, stp, att, eff, lap, ghost, sp, viol, piv, pol, ov, op>>

\* A failed verdict on a forward step before the pivot: the target answered the effect did not
\* land, so a compensation onset event naming the step moves the run into the compensating phase
\* and resolves the attempt (Action wiring 26, 29).
FailedOnset ==
    /\ pc = "ran"
    /\ vd = "failed"
    /\ ~IsComp(cur)
    /\ ~Roll(piv, cur)
    /\ ph' = "compensating"
    /\ sp' = "compensating"
    /\ att' = att \ {cur}
    /\ viol' = viol \cup (IF Roll(piv, cur) THEN {"Action_30"} ELSE {})
    /\ pc' = "idle"
    /\ cur' = 0
    /\ vd' = "none"
    /\ UNCHANGED <<hp, hs, stp, eff, lap, ghost, piv, pol, ov, op>>

\* A failed verdict on a compensation under halt-and-surface: a halt event naming the compensating
\* phase and the step; the attempt stays parked (Action wiring 37, Replay 12).
CompFailedHalt ==
    /\ pc = "ran"
    /\ vd = "failed"
    /\ IsComp(cur)
    /\ pol = "halt"
    /\ ph' = "halted"
    /\ sp' = "halted"
    /\ hp' = "compensating"
    /\ hs' = {KStep(cur)}
    /\ pc' = "idle"
    /\ cur' = 0
    /\ vd' = "none"
    /\ UNCHANGED <<stp, att, eff, lap, ghost, viol, piv, pol, ov, op>>

\* A failed verdict on a compensation under continue: a compensation failure event resolves the
\* attempt and leaves the step a standing failure; the remaining compensations run (Action
\* wiring 38, 39).
CompFailedContinue ==
    /\ pc = "ran"
    /\ vd = "failed"
    /\ IsComp(cur)
    /\ pol = "continue"
    /\ stp' = [stp EXCEPT ![KStep(cur)] = "fail"]
    /\ att' = att \ {cur}
    /\ pc' = "idle"
    /\ cur' = 0
    /\ vd' = "none"
    /\ UNCHANGED <<ph, hp, hs, eff, lap, ghost, sp, viol, piv, pol, ov, op>>

\* A verdict the target has not settled is asked again under the same key inside the step
\* completion bound (Action wiring 27, 42, 46): a failed verdict on a roll-forward step, an
\* indeterminate one, an unknown one.
Retry ==
    /\ pc = "ran"
    /\ \/ vd = "indet"
       \/ vd = "unknown"
       \/ /\ vd = "failed"
          /\ ~IsComp(cur)
          /\ Roll(piv, cur)
    /\ pc' = "marked"
    /\ vd' = "none"
    /\ UNCHANGED <<ph, hp, hs, stp, att, eff, lap, cur, ghost, sp, viol, piv, pol, ov, op>>

\* The bound elapses on a failed roll-forward step: a halt event naming the forward phase and the
\* step; the attempt stays parked (Action wiring 28). Never a compensation onset (Action wiring 30).
BoundFailedRoll ==
    /\ pc = "ran"
    /\ vd = "failed"
    /\ ~IsComp(cur)
    /\ Roll(piv, cur)
    /\ ph' = "halted"
    /\ sp' = "halted"
    /\ hp' = "forward"
    /\ hs' = {KStep(cur)}
    /\ pc' = "idle"
    /\ cur' = 0
    /\ vd' = "none"
    /\ UNCHANGED <<stp, att, eff, lap, ghost, viol, piv, pol, ov, op>>

\* The bound elapses on an indeterminate effect: the invocation answers effect-indeterminate
\* naming no-verdict. It writes nothing: no resolving event, no onset (Action wiring 43 to 45).
BoundIndet ==
    /\ pc = "ran"
    /\ vd = "indet"
    /\ pc' = "idle"
    /\ cur' = 0
    /\ vd' = "none"
    /\ UNCHANGED <<ph, hp, hs, stp, att, eff, lap, ghost, sp, viol, piv, pol, ov, op>>

\* The bound elapses on an unknown effect: a halt event naming the phase and the step, the attempt
\* parked, and effect-indeterminate naming target-unknown (Action wiring 47, 48).
BoundUnknown ==
    /\ pc = "ran"
    /\ vd = "unknown"
    /\ ph' = "halted"
    /\ sp' = "halted"
    /\ hp' = (IF IsComp(cur) THEN "compensating" ELSE "forward")
    /\ hs' = {KStep(cur)}
    /\ pc' = "idle"
    /\ cur' = 0
    /\ vd' = "none"
    /\ UNCHANGED <<stp, att, eff, lap, ghost, viol, piv, pol, ov, op>>

\* ----- the critical section and the second writer -----

\* The lease expires, the invocation dies, or a host fault loses the section (Action wiring 6): the
\* invocation yields wherever it stands and the section is free. An effect reply in flight is its
\* ghost (Action wiring 5); the invocation writes nothing more (Action wiring 3).
Expire ==
    /\ pc \in {"held", "marked", "ran"}
    /\ pc' = "idle"
    /\ cur' = 0
    /\ vd' = "none"
    /\ ghost' = (IF pc = "ran" /\ vd = "applied" /\ ghost = 0 THEN cur ELSE ghost)
    /\ UNCHANGED <<ph, hp, hs, stp, att, eff, lap, sp, viol, piv, pol, ov, op>>

\* An expired invocation discards the effect reply it still holds (Action wiring 5).
GhostDiscard ==
    /\ ghost /= 0
    /\ ghost' = 0
    /\ UNCHANGED <<ph, hp, hs, stp, att, eff, lap, pc, cur, vd, sp, viol, piv, pol, ov, op>>

\* ----- cancel -----

\* A [Cancel] in the forward phase with no terminal marker, no unresolved attempt and no completed
\* roll-forward step appends a compensation onset event naming no step (Action wiring 74, 87). One
\* with an unresolved attempt answers step-unresolved (Action wiring 72), one past a pivot answers
\* roll-forward (Action wiring 73), one in another phase answers its phase (Action wiring 71, 75,
\* 76): none of those writes, which the model leaves out as a stutter. Cancel takes and releases
\* the section in the one step, so it runs only while no invocation holds it.
Cancel ==
    /\ pc = "idle"
    /\ ph = "forward"
    /\ att = {}
    /\ ~RollDone(piv, stp)
    /\ ph' = "compensating"
    /\ viol' = viol \cup (IF ph = "committed" THEN {"Invariant_4_3"} ELSE {})
                     \cup (IF att /= {} THEN {"Action_72"} ELSE {})
                     \cup (IF RollDone(piv, stp) THEN {"Action_73"} ELSE {})
    /\ UNCHANGED <<hp, hs, stp, att, eff, lap, pc, cur, vd, ghost, sp, piv, pol, ov, op>>

\* ----- the horizon -----

\* A target forgets an applied effect key once the effect key horizon elapses. The model lets it
\* happen only while the run rests halted, on a key the halt parks or names: the rest in the halted
\* phase is the gap a deployment cannot keep (open 2026-11-03-d).
Lapse ==
    /\ ph = "halted"
    /\ pc = "idle"
    /\ \E k \in Parked(stp, att, hp, hs) :
        /\ eff[k] >= 1
        /\ k \notin lap
        /\ lap' = lap \cup {k}
    /\ UNCHANGED <<ph, hp, hs, stp, att, eff, pc, cur, vd, ghost, sp, viol, piv, pol, ov, op>>

Next ==
    \/ Take
    \/ Resume
    \/ ReEntry
    \/ StartStep
    \/ Commit
    \/ StartComp
    \/ Close
    \/ HaltStanding
    \/ RunEffect
    \/ RecordApplied
    \/ RecordOverflow
    \/ RecordStorageFail
    \/ FailedOnset
    \/ CompFailedHalt
    \/ CompFailedContinue
    \/ Retry
    \/ BoundFailedRoll
    \/ BoundIndet
    \/ BoundUnknown
    \/ Expire
    \/ GhostDiscard
    \/ Cancel
    \/ Lapse

Spec == Init /\ [][Next]_vars

\* ----- the verification surface -----

\* Invariant 4 — all-or-compensated, read against the world. A committed run has every effect
\* landed and no compensation applied; a compensated run has every effect that landed reversed by
\* its compensation, the one an indeterminate verdict left unrecorded included. No completed
\* external effect survives an abort uncompensated.
Invariant_4_AllOrCompensated ==
    /\ (ph = "committed") => (\A i \in Steps : eff[i] = 1 /\ eff[N + i] = 0)
    /\ (ph = "compensated") => (\A i \in Steps : eff[i] >= 1 => eff[N + i] >= 1)

\* Invariant 4.1 — a run carrying a compensation close event carries a compensation run event for
\* every step completion event: no completed step is left, or standing in failure.
Invariant_4_1 ==
    (ph = "compensated") => (\A i \in Steps : stp[i] = "open" \/ stp[i] = "comp")

\* Invariant 4.2 — a run carrying a commit event carries a step completion event for every declared
\* step.
Invariant_4_2 ==
    (ph = "committed") => (\A i \in Steps : stp[i] = "done")

\* Invariant 4.3 — a run carrying a commit event carries no compensation onset event: no cancel
\* lands over a commit, and a committed run's steps are none reversed.
Invariant_4_3 ==
    /\ "Invariant_4_3" \notin viol
    /\ (ph = "committed") => (\A i \in Steps : stp[i] /= "comp" /\ stp[i] /= "fail")

\* Invariant 4.5 — a terminal marker lands only if no attempt is unresolved.
Invariant_4_5 ==
    (ph \in {"committed", "compensated"}) => (att = {})

\* Invariant 5.1 — under the reverse order, completed steps are compensated newest first.
Invariant_5_1 == "Invariant_5_1" \notin viol

\* Invariant 6.3 — a resume marker returns the run to the phase the newest halt event names.
Invariant_6_3 == "Invariant_6_3" \notin viol

\* Invariant 7.1 — the at-most-once claim, given the target key discipline and the critical section:
\* no effect, and no compensation, lands at its target twice.
Invariant_7_1 == \A k \in Keys : eff[k] <= 1

\* Invariant 7.2 — the composition runs no effect whose key is in the applied effects.
Invariant_7_2 == "Invariant_7_2" \notin viol

\* Check 7.1 — no two completion records carry one effect key.
Check_7_1 == "Check_7_1" \notin viol

\* Invariant 8.1 — once a compensation onset event stands, no step completion event is appended.
Invariant_8_1 == "Invariant_8_1" \notin viol

\* Invariant 2.1 — the spine's current state equals the replayed state at every quiescent point
\* (no invocation holds the section). A write that leaves its fire out shows here.
Invariant_2_1 == (pc = "idle") => (sp = ph)

\* Non-goal 9, Action wiring 30 and 73 — no compensation runs for a roll-forward step.
NonGoal_9_NoRollForwardCompensated == \A i \in Steps : Roll(piv, i) => eff[N + i] = 0

\* Primitive policy 23 to 25 and Check 8.2 — a step whose completion carries the truncation mark is
\* compensated only from the operator's compensation inputs, never from the truncated ones.
Primitive_25_OverflowFromOperator == "Primitive_25" \notin viol

\* Replay 12, Check 4.5 — a halt event resolves no attempt: every key a standing halt names is
\* recorded, still an unresolved attempt, or a standing compensation failure (the continue policy
\* resolves the attempt by the failure event, and the halt names the failure).
Replay_12_HaltParksAttempt ==
    (ph = "halted") =>
        (\A k \in Named(hp, hs) : Recorded(stp, k) \/ k \in att \/ stp[KStep(k)] = "fail")

\* Action wiring 30 — a failed roll-forward step begins no compensation: the run rolls forward and
\* is surfaced at the bound, never compensated.
Action_30_NoOnsetOnRollForward == "Action_30" \notin viol

\* Action wiring 72 — a cancel with an unresolved attempt answers step-unresolved and writes nothing:
\* no compensation onset lands over an attempt.
Action_72_NoCancelOverAttempt == "Action_72" \notin viol

\* Action wiring 73 — a cancel after a roll-forward step completed answers roll-forward and writes
\* nothing.
Action_73_NoCancelPastPivot == "Action_73" \notin viol

\* Invariant 4.4 — the composition carries every open obligation in the step log: an effect that
\* landed and has no completion record stays an unresolved attempt, whatever a verdict, a halt, a
\* storage failure or a cancel does after. (An indeterminate verdict is not a failure, Action
\* wiring 45; a completion that did not land does not resolve the effect, Action wiring 53.)
Invariant_4_4_OpenObligations ==
    \A k \in Keys : (eff[k] >= 1 /\ ~Recorded(stp, k)) => k \in att

====
