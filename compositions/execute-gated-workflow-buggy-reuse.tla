---- MODULE execute-gated-workflow-buggy-reuse ----
\* BUGGY TWIN (vacuity guard) for execute-gated-workflow.tla — the consumption rule's history arm stops at the horizon.
\*
\* The module is the correct model with one rule changed, so the checker must find the
\* counterexample the change makes reachable; a checker that reports every invariant
\* holding here is vacuous.
\*
\* BUG (Wiring decision 3 and 5): the history arm of the consumption rule reads only the entries
\* inside the widened horizon, so a committed firing whose record was never landed stops counting
\* once it is aged. The approval that cleared it reads as live again, the gate key is
\* re-bindable over nothing, and the same approval clears a second firing.
\*
\* Breaks: Invariant_1_OneFiringPerApproval.

\* Grace Commons — Execute Gated Workflow composition.
\* Spec-level formal sibling of compositions/execute-gated-workflow.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-08 (the first model, 2026-06-04, checked one claim over an
\* unbounded consumption arm). It now carries the mooted mark, the consumption rule's
\* horizon arm, the moot cascade, the invocation and the sweep as two processes, and
\* the sweep's four legs joined on the shared reading.
\*
\* WHAT THIS MODEL CHECKS
\* One workflow with two guarded transitions out of its first state s0, g1 and g2,
\* both to s1, and an unguarded way back from s1 to s0. Each guarded transition is
\* cleared by its own Approval Step. Firing either leaves the other one behind, so the
\* firing owes a moot cascade for it. The way back lets the workflow return to s0, so
\* an approval can be offered again after the workflow left the state it was given in.
\* What the model checks is that no approval clears a firing it was not given for:
\*   - Invariant 1.1  a quiescent workflow's guarded history entries each carry a firing
\*                    event naming a step approved before the firing.
\*   - Invariant 1.2  two firing events never carry one step id.
\*   - Invariant 1.3  no firing event names a step a moot record named earlier.
\*   - Invariant 3.1  a quiescent workflow's committed acts each carry exactly one outcome.
\*   - Invariant 3.2  a quiescent workflow's moot cascade entries each carry exactly one
\*                    moot record.
\*   - Invariant 4.1  a quiescent workflow's pending bound step carries one active assignment.
\*   - Invariant 4.2  a quiescent workflow's settled steps carry none.
\*   - Invariant 6.1  a quiescent workflow's process proof resolves (1.1 and 3.1 together).
\* and, from the rules those invariants stand on:
\*   - Wiring decision 3/4  a spent step is never live, and a fresh approval is always live.
\*   - Invariant 1 (heading)  one firing per approval, read from the machine history.
\*   - Reconciliation 5   the sweep writes nothing for a record past the audit horizon.
\*   - Reconciliation 8   no sweep write before its recovery record lands.
\*   - Reconciliation 19/20  a decision event the sweep lands matches the step's own decision.
\*
\* THE TWO PROCESSES
\* The invocation (Open, Decide, Fire) is one transaction (Execution Contract Store 1 and
\* 2; Decisions entry 2026-10-20), so the sweep never sees it half done. What it can leave
\* behind is a refused write that does not roll the act back: an outcome event Audit Trail
\* refused (Audit arm 11) or a cascade call refused other than by a storage failure
\* (Cascade 10, 11). Each such write is chosen by the model, landed or refused, in every
\* invocation. The sweep is the other process: its four legs land what the invocations
\* left owed, one recovery record first, only for records inside the audit horizon.
\* The completion bound, which the page once used as the point where an invocation yielded
\* to the sweep, is not modelled: the invocation retries nothing since 2026-10-20, so there
\* is no point for it to yield at.
\*
\* TIME AND THE WORKFLOW'S LIFETIME
\* clk counts the acts the run has made: every act (an invocation or a sweep write) is stamped
\* with the clock's reading and then advances it by one, so the instants of two acts differ and
\* "does not precede" never ties. Horizon stands for the audit horizon widened by the clock
\* offset allowance, in those ticks: a record older than Horizon is purged (a read answers
\* Purged) and the sweep leaves it alone. Marks are kept past the purge (Composition state 16).
\* Invocations run only while clk < Life, the workflow's lifetime, and Capability requirement 3
\* (the longest workflow lifetime does not exceed the audit horizon) is the case Life <= Horizon,
\* which the correct model's configuration takes. After the lifetime only the sweep and the
\* clock move (Tick), so records age while the sweep still runs, and Reconciliation 5 is
\* exercised. Two twins break the requirement on purpose (Life above Horizon), because the
\* consumption rule's aged arm and the mark's durability are written to hold even then.
\* One reading the model made plain: the mooting rule has no aged arm. Where the lifetime
\* exceeds the horizon, an approval held mooted only by an owed cascade's fire intent reads as
\* live again once that intent is purged, and clears a firing (found at Life = 7, Horizon = 2).
\* Under Capability requirement 3 an intent is never aged while its workflow can fire, so the
\* case is out of reach; it is recorded as an open line on the page (2026-11-08-a).
\* MaxFault bounds how many writes the callees refuse, so the state space stays small while
\* every pair of refusals the rules distinguish is still reached.
\*
\* NOT MODELLED (out of scope for the load-bearing properties)
\* - Invariants 2, 5 and 8: the permission check, the declared-transition check and the
\*   credential check are single-call refusals owned by Permissions, State Machine and
\*   Audit Trail (each has a model of its own); no sequence of them reorders a firing.
\* - The opening leg (Reconciliation 15 to 17, 31) and the start: an opening is one
\*   transaction that lands its event, binding and assignment, so the model takes the
\*   opening event as always landed.
\* - The four derived indexes and their rebuild: a lost entry is a rebuild trigger and
\*   never a relation violation (the invariants section's own sentence), so the model
\*   reads the binding, its marks and the log directly.
\* - Candidates (Reconciliation 24 to 26) and findings (Reconciliation 17, 22, 29): two
\*   intents never pair to one record here because the model's instants are all different.
\* - Several steps in one moot plan: two gates give a plan of at most one step, and a longer
\*   plan is the same per-step cascade repeated.

EXTENDS Naturals, FiniteSets

CONSTANTS
    Gates,        \* the guarded transitions out of s0; the model fixes two
    Steps,        \* the Approval Steps the workflow can mint, as 1..n
    Life,         \* the workflow's lifetime in ticks: invocations run while clk < Life. Capability
                  \* requirement 3 holds where Life <= Horizon
    MaxClk,       \* the last tick of the clock; the sweep runs until then
    Horizon,      \* the audit horizon widened by the clock offset allowance, in ticks
    MaxFire,      \* how many guarded firings the run may hold
    MaxFault      \* how many refused writes the run may hold (an outcome event, a cascade call
                  \* or a decision attempt the callee refused)

ASSUME Cardinality(Gates) = 2
ASSUME Life <= MaxClk

VARIABLES
    ws,           \* the workflow machine's current state: "s0" or "s1"
    clk,          \* the clock, in ticks
    nlog,         \* how many events the log holds (the next event's position is nlog + 1)
    st,           \* each step's Approval Step state
    sgate,        \* each step's gate key, "-" until it is minted
    subAt,        \* each step's submitted instant
    decAt,        \* each step's decided instant, 0 until decided
    asg,          \* each step's assignment: "none", "active" or "recalled"
    bound,        \* each gate key's bound step, 0 when nothing is bound
    cm,           \* each step's consumed mark, kept on the binding that names it
    mm,           \* each step's mooted mark, kept on the binding that names it
    hist,         \* the workflow machine's history: the guarded firings, each with a transition id
    log,          \* the Event Log: every event the composition recorded, each with a position
    flt           \* how many refused writes the run has spent (the fault budget)

vars == <<ws, clk, nlog, st, sgate, subAt, decAt, asg, bound, cm, mm, hist, log, flt>>

NoStep == 0

StepState == {"unused", "pending", "approved", "rejected", "withdrawn"}

\* Every event carries the same fields so one record shape serves the whole log. An event's
\* kind k is: "opened" (an opening event), "dint" (a decision intent), "decided" (a decision
\* event), "fint" (a fire intent, carrying its moot plan), "fired" (a firing event), "moot"
\* (a moot record) or "recov" (a recovery intent). n is its position in the log, at the
\* tick it was recorded, ia the instant of the act it records, dec the decision, plan the
\* moot plan, rl the sweep leg that wrote it ("none" for an invocation's own write).
IsEvent(e) ==
    /\ e.k \in {"opened", "dint", "decided", "fint", "fired", "moot", "recov"}
    /\ e.n \in 1..40
    /\ e.g \in Gates \cup {"-"}
    /\ e.s \in 0..Cardinality(Steps)
    /\ e.t \in 0..40
    /\ e.at \in 0..MaxClk
    /\ e.ia \in 0..MaxClk
    /\ e.dec \in {"-", "approved", "rejected"}
    /\ e.plan \subseteq Steps
    /\ e.rl \in {"none", "firing", "cascade", "decision"}

\* The shape of every variable: states drawn from the sets above, marks as booleans, and a
\* log whose events all have the one shape.
TypeOK ==
    /\ ws \in {"s0", "s1"}
    /\ clk \in 0..MaxClk
    /\ nlog \in 0..40
    /\ st \in [Steps -> StepState]
    /\ sgate \in [Steps -> Gates \cup {"-"}]
    /\ subAt \in [Steps -> 0..MaxClk]
    /\ decAt \in [Steps -> 0..MaxClk]
    /\ asg \in [Steps -> {"none", "active", "recalled"}]
    /\ bound \in [Gates -> Steps \cup {NoStep}]
    /\ cm \in [Steps -> BOOLEAN]
    /\ mm \in [Steps -> BOOLEAN]
    /\ hist \subseteq [t : 1..MaxFire, g : Gates, at : 0..MaxClk]
    /\ \A e \in log : IsEvent(e)
    /\ flt \in 0..MaxFault

\* Nothing has happened: the workflow sits in s0 with no step minted and an empty log.
Init ==
    /\ ws = "s0"
    /\ clk = 0
    /\ nlog = 0
    /\ st = [s \in Steps |-> "unused"]
    /\ sgate = [s \in Steps |-> "-"]
    /\ subAt = [s \in Steps |-> 0]
    /\ decAt = [s \in Steps |-> 0]
    /\ asg = [s \in Steps |-> "none"]
    /\ bound = [g \in Gates |-> NoStep]
    /\ cm = [s \in Steps |-> FALSE]
    /\ mm = [s \in Steps |-> FALSE]
    /\ hist = {}
    /\ log = {}
    /\ flt = 0

\* --- reading the records ---------------------------------------------------------------

\* A record is aged when its instant plus the widened horizon precedes now (Term aged record):
\* a read answers Purged and the sweep does not examine it.
Aged(x) == x + Horizon < clk

\* An event the log still holds (a read does not answer Purged).
Ret(e) == ~Aged(e.at)

\* Whether a retained firing event names the step.
FiredNames(s) == \E e \in log : e.k = "fired" /\ e.s = s /\ Ret(e)

\* Whether a retained firing event carries the transition id.
FiredNamesT(t) == \E e \in log : e.k = "fired" /\ e.t = t /\ Ret(e)

\* Whether a retained moot record names the step.
MootNames(s) == \E e \in log : e.k = "moot" /\ e.s = s /\ Ret(e)

\* Whether a retained moot record answers the cascade entry (transition id, step).
MootNamesTS(t, s) == \E e \in log : e.k = "moot" /\ e.t = t /\ e.s = s /\ Ret(e)

\* Whether a retained decision event names the step.
DecNames(s) == \E e \in log : e.k = "decided" /\ e.s = s /\ Ret(e)

\* Term consumption rule. A bound step is consumed where a firing event names it; where the
\* machine's history holds a guarded firing out of its gate key, at or after the step's
\* submitted instant, that no firing event names (a committed firing whose record is owed) or
\* that is aged (Wiring decision 5: the aged entry still counts, it just is not owed); or
\* where its consumed mark is set.
HistArm(s) ==
    \E h \in hist : /\ h.g = sgate[s]
                    /\ h.at >= subAt[s]
                    /\ (~Aged(h.at) /\ ~FiredNamesT(h.t))

Consumed(s) == cm[s] \/ FiredNames(s) \/ HistArm(s)

\* Term mooting rule. A bound step is mooted where a moot record names it, where a committed
\* firing's fire intent names it in its moot plan, or where its mooted mark is set.
Mooted(s) ==
    \/ mm[s]
    \/ MootNames(s)
    \/ \E e \in log : e.k = "fint" /\ s \in e.plan /\ Ret(e)

\* Term live approvals. An approved bound step neither consumed nor mooted.
Live(s) == st[s] = "approved" /\ ~Consumed(s) /\ ~Mooted(s)

\* Term re-bindable steps (Wiring decision 7): rejected or withdrawn, or approved and spent.
Rebindable(g) ==
    \/ bound[g] = NoStep
    \/ st[bound[g]] \in {"rejected", "withdrawn"}
    \/ (st[bound[g]] = "approved" /\ (Consumed(bound[g]) \/ Mooted(bound[g])))

\* Term moot plan. The steps of the other gate keys that are pending or a live approval.
PlanFor(g) ==
    {x \in Steps : \E h \in Gates \ {g} : bound[h] = x /\ (st[x] = "pending" \/ Live(x))}

\* --- owed records: what the invocations left for the sweep ---------------------------------

\* A committed firing whose firing event no retained record carries, inside the horizon.
OwedFiring(h) == ~Aged(h.at) /\ ~FiredNamesT(h.t)

\* A committed firing whose moot plan names a step no moot record of that firing answers.
OwedCascade(e, s) ==
    /\ e.k = "fint"
    /\ s \in e.plan
    /\ ~Aged(e.at)
    /\ ~MootNamesTS(e.t, s)

\* A decided step with no decision event and no moot record, inside the horizon.
OwedDecision(s) ==
    /\ st[s] \in {"approved", "rejected"}
    /\ ~Aged(decAt[s])
    /\ ~DecNames(s)
    /\ ~MootNames(s)

\* Term quiescent workflows: no invocation in flight (every invocation here is one step) and
\* no record owed past its invocation.
Quiescent ==
    /\ ~(\E h \in hist : OwedFiring(h))
    /\ ~(\E e \in log : \E s \in Steps : OwedCascade(e, s))
    /\ ~(\E s \in Steps : OwedDecision(s))

\* --- the invocation process ---------------------------------------------------------------

\* One tick passes after the workflow's lifetime, so records can age while the sweep is still
\* running. Inside the lifetime a tick is only ever an act's.
Tick ==
    /\ clk >= Life
    /\ clk < MaxClk
    /\ clk' = clk + 1
    /\ UNCHANGED <<ws, nlog, st, sgate, subAt, decAt, asg, bound, cm, mm, hist, log, flt>>

\* The unguarded transition from s1 back to s0 (the page's State Machine has no gate on it). It
\* writes no record of this composition's and is no act the sweep reads, so it takes no tick.
Back ==
    /\ ws = "s1"
    /\ ws' = "s0"
    /\ UNCHANGED <<clk, nlog, st, sgate, subAt, decAt, asg, bound, cm, mm, hist, log, flt>>

\* [Open Gate]: a fresh step is submitted and assigned, and the gate key is bound to it with
\* both marks blank (Wiring decision 9). Allowed only over a re-bindable binding, so it
\* answers already-open for a pending step and for a live approval (Action wiring 25, 26).
OpenGate(g, s) ==
    /\ ws = "s0"
    /\ clk < Life
    /\ st[s] = "unused"
    /\ (s = 1 \/ st[s - 1] /= "unused")
    /\ Rebindable(g)
    /\ clk' = clk + 1
    /\ nlog' = nlog + 1
    /\ st' = [st EXCEPT ![s] = "pending"]
    /\ sgate' = [sgate EXCEPT ![s] = g]
    /\ subAt' = [subAt EXCEPT ![s] = clk]
    /\ asg' = [asg EXCEPT ![s] = "active"]
    /\ bound' = [bound EXCEPT ![g] = s]
    /\ cm' = [cm EXCEPT ![s] = FALSE]
    /\ mm' = [mm EXCEPT ![s] = FALSE]
    /\ log' = log \cup {[k |-> "opened", n |-> nlog + 1, g |-> g, s |-> s, t |-> 0,
                         at |-> clk, ia |-> clk, dec |-> "-", plan |-> {}, rl |-> "none"]}
    /\ UNCHANGED <<ws, decAt, hist, flt>>

\* [Decide Gate]: the named approver approves or rejects the pending bound step; the step
\* write, the recall of its assignment and the decision intent are one transaction, and the
\* decision event lands or is refused (landed chooses which).
DecideGate(g, d, landed) ==
    /\ clk < Life
    /\ flt + (IF landed THEN 0 ELSE 1) <= MaxFault
    /\ flt' = flt + (IF landed THEN 0 ELSE 1)
    /\ bound[g] /= NoStep
    /\ st[bound[g]] = "pending"
    /\ clk' = clk + 1
    /\ nlog' = nlog + 1 + (IF landed THEN 1 ELSE 0)
    /\ st' = [st EXCEPT ![bound[g]] = d]
    /\ decAt' = [decAt EXCEPT ![bound[g]] = clk]
    /\ asg' = [asg EXCEPT ![bound[g]] = "recalled"]
    /\ log' = log \cup {[k |-> "dint", n |-> nlog + 1, g |-> g, s |-> bound[g], t |-> 0,
                         at |-> clk, ia |-> clk, dec |-> d, plan |-> {}, rl |-> "none"]}
                  \cup (IF landed
                        THEN {[k |-> "decided", n |-> nlog + 2, g |-> g, s |-> bound[g], t |-> nlog + 1,
                               at |-> clk, ia |-> clk, dec |-> d, plan |-> {}, rl |-> "none"]}
                        ELSE {})
    /\ UNCHANGED <<ws, sgate, subAt, bound, cm, mm, hist>>

\* A second decision attempt on a step already decided: Approval Step answers not-pending, the
\* action refuses, and the decision intent stays as evidence (Action wiring 37, 39).
DecideAgain(g, d) ==
    /\ clk < Life
    /\ flt < MaxFault
    /\ flt' = flt + 1
    /\ bound[g] /= NoStep
    /\ st[bound[g]] \in {"approved", "rejected"}
    /\ clk' = clk + 1
    /\ nlog' = nlog + 1
    /\ log' = log \cup {[k |-> "dint", n |-> nlog + 1, g |-> g, s |-> bound[g], t |-> 0,
                         at |-> clk, ia |-> clk, dec |-> d, plan |-> {}, rl |-> "none"]}
    /\ UNCHANGED <<ws, st, sgate, subAt, decAt, asg, bound, cm, mm, hist>>

\* The moot cascade's effect on one planned step when its calls answer: a pending step is
\* withdrawn and its assignment recalled, the moot record is written and the mooted mark set.
\* An approved step stays approved and only the record and the mark are written (Cascade 3).
CascadeStep(p) == IF st[p] = "pending" THEN "withdrawn" ELSE st[p]

\* [Fire Transition], guarded: only over a live approval (Wiring decision 1). The firing, its
\* fire intent and the consumed step are one transaction. The firing event lands or is
\* refused (landed), and the cascade's calls answer or are refused (cascade).
FireGuarded(g, landed, cascade) ==
    /\ ws = "s0"
    /\ clk < Life
    /\ flt + (IF landed THEN 0 ELSE 1) + (IF cascade \/ PlanFor(g) = {} THEN 0 ELSE 1) <= MaxFault
    /\ flt' = flt + (IF landed THEN 0 ELSE 1) + (IF cascade \/ PlanFor(g) = {} THEN 0 ELSE 1)
    /\ Cardinality(hist) < MaxFire
    /\ bound[g] /= NoStep
    /\ Live(bound[g])
    /\ clk' = clk + 1
    /\ ws' = "s1"
    /\ hist' = hist \cup {[t |-> Cardinality(hist) + 1, g |-> g, at |-> clk]}
    /\ nlog' = nlog + 1 + (IF landed THEN 1 ELSE 0)
                        + (IF cascade /\ PlanFor(g) /= {} THEN 1 ELSE 0)
    /\ cm' = IF landed THEN [cm EXCEPT ![bound[g]] = TRUE] ELSE cm
    /\ st' = IF cascade THEN [x \in Steps |-> IF x \in PlanFor(g) THEN CascadeStep(x) ELSE st[x]]
                        ELSE st
    /\ asg' = IF cascade THEN [x \in Steps |-> IF x \in PlanFor(g) THEN "recalled" ELSE asg[x]]
                         ELSE asg
    /\ mm' = IF cascade THEN [x \in Steps |-> IF x \in PlanFor(g) THEN TRUE ELSE mm[x]] ELSE mm
    /\ log' = log \cup {[k |-> "fint", n |-> nlog + 1, g |-> g, s |-> bound[g],
                         t |-> Cardinality(hist) + 1, at |-> clk, ia |-> clk, dec |-> "-",
                         plan |-> PlanFor(g), rl |-> "none"]}
                  \cup (IF landed
                        THEN {[k |-> "fired", n |-> nlog + 2, g |-> g, s |-> bound[g],
                               t |-> Cardinality(hist) + 1, at |-> clk, ia |-> clk,
                               dec |-> "-", plan |-> {}, rl |-> "none"]}
                        ELSE {})
                  \cup {[k |-> "moot", n |-> nlog + 2 + (IF landed THEN 1 ELSE 0), g |-> sgate[p],
                         s |-> p, t |-> Cardinality(hist) + 1, at |-> clk, ia |-> clk,
                         dec |-> "-", plan |-> {}, rl |-> "none"] :
                        p \in (IF cascade THEN PlanFor(g) ELSE {})}
    /\ UNCHANGED <<sgate, subAt, decAt, bound>>

\* --- the sweep process --------------------------------------------------------------------

\* The recovery record the sweep writes for a closure before the leg commits any constituent
\* state (Reconciliation 8, 9): it names the leg and the closure, and sits at position nlog + 1,
\* ahead of the leg's own write at nlog + 2. The leg and its recovery record are one transaction
\* (Execution Contract Store 2: the sweep's reads of a workflow and the writes they decide).
RecoveryRecord(rl, t, s) ==
    [k |-> "recov", n |-> nlog + 1, g |-> "-", s |-> s, t |-> t, at |-> clk, ia |-> clk,
     dec |-> "-", plan |-> {}, rl |-> rl]

\* The fire intents on the entry's gate key whose intent instant equals the entry's fired
\* instant and that no firing event names (Reconciliation 12).
Matching(h) == {e \in log : e.k = "fint" /\ e.g = h.g /\ e.at = h.at /\ ~FiredNamesT(e.t)}

\* Firing leg (Reconciliation 11 to 13): re-emits the firing event from the history entry,
\* naming the step the paired fire intent carries, and sets the consumed mark only where the
\* gate key's bound step is that step.
FiringLeg(h, c) ==
    /\ clk < MaxClk
    /\ clk' = clk + 1
    /\ OwedFiring(h)
    /\ Matching(h) = {c}
    /\ nlog' = nlog + 2
    /\ cm' = IF bound[h.g] = c.s THEN [cm EXCEPT ![c.s] = TRUE] ELSE cm
    /\ log' = log \cup {RecoveryRecord("firing", h.t, 0)}
                  \cup {[k |-> "fired", n |-> nlog + 2, g |-> h.g, s |-> c.s, t |-> h.t, at |-> clk,
                         ia |-> h.at, dec |-> "-", plan |-> {}, rl |-> "firing"]}
    /\ UNCHANGED <<ws, st, sgate, subAt, decAt, asg, bound, mm, hist, flt>>

\* Cascade leg (Reconciliation 14): runs the owed cascade calls for the step.
CascadeLeg(e, s) ==
    /\ clk < MaxClk
    /\ clk' = clk + 1
    /\ OwedCascade(e, s)
    /\ nlog' = nlog + 2
    /\ st' = [st EXCEPT ![s] = CascadeStep(s)]
    /\ asg' = [asg EXCEPT ![s] = "recalled"]
    /\ mm' = [mm EXCEPT ![s] = TRUE]
    /\ log' = log \cup {RecoveryRecord("cascade", e.t, s)}
                  \cup {[k |-> "moot", n |-> nlog + 2, g |-> sgate[s], s |-> s, t |-> e.t, at |-> clk,
                         ia |-> e.ia, dec |-> "-", plan |-> {}, rl |-> "cascade"]}
    /\ UNCHANGED <<ws, sgate, subAt, decAt, bound, cm, hist, flt>>

\* The decision intents on the step whose decision is the step's terminal state and whose
\* intent instant is the step's decided instant (Term matching decision intents). The actor
\* is the step's approver in every case here, so it is not a field of the model.
MatchingDecisions(s) ==
    {e \in log : e.k = "dint" /\ e.s = s /\ e.dec = st[s] /\ e.ia = decAt[s]}

\* Decision leg (Reconciliation 18 to 20): records the step's decision event where exactly
\* one decision intent matches; where none matches it records nothing.
DecisionLeg(s, c) ==
    /\ clk < MaxClk
    /\ clk' = clk + 1
    /\ OwedDecision(s)
    /\ MatchingDecisions(s) = {c}
    /\ nlog' = nlog + 2
    /\ log' = log \cup {RecoveryRecord("decision", 0, s)}
                  \cup {[k |-> "decided", n |-> nlog + 2, g |-> sgate[s], s |-> s, t |-> c.n,
                         at |-> clk, ia |-> c.ia, dec |-> c.dec, plan |-> {}, rl |-> "decision"]}
    /\ UNCHANGED <<ws, st, sgate, subAt, decAt, asg, bound, cm, mm, hist, flt>>

Next ==
    \/ Tick
    \/ Back
    \/ \E g \in Gates, s \in Steps : OpenGate(g, s)
    \/ \E g \in Gates, d \in {"approved", "rejected"}, l \in BOOLEAN : DecideGate(g, d, l)
    \/ \E g \in Gates, d \in {"approved", "rejected"} : DecideAgain(g, d)
    \/ \E g \in Gates, l \in BOOLEAN, c \in BOOLEAN : FireGuarded(g, l, c)
    \/ \E h \in hist, c \in log : FiringLeg(h, c)
    \/ \E e \in log, s \in Steps : CascadeLeg(e, s)
    \/ \E s \in Steps, c \in log : DecisionLeg(s, c)

Spec == Init /\ [][Next]_vars

\* --- composition-level invariants ---------------------------------------------------------

\* Invariant 1.1: IF a workflow IS IN the quiescent workflows THEN EVERY guarded history entry
\* of the workflow that IS NOT IN the aged entries MUST carry a firing event naming a step the
\* entry's approver approved. In the model the approver is the one who decided, so the step is
\* approved, and approved before the firing.
Invariant_1_1 ==
    Quiescent =>
        (\A h \in hist :
            (Aged(h.at) \/ (\E e \in log : /\ e.k = "fired"
                                           /\ e.t = h.t
                                           /\ st[e.s] = "approved"
                                           /\ decAt[e.s] < h.at)))

\* Invariant 1.2: Two guarded firing events MUST NOT carry one step id.
Invariant_1_2 ==
    \A e1 \in log : \A e2 \in log :
        ((e1.k = "fired" /\ e2.k = "fired" /\ e1.s = e2.s) => e1.n = e2.n)

\* Invariant 1.3: A guarded firing event MUST NOT name a step a moot record names earlier in
\* the Event Log sequence.
Invariant_1_3 ==
    \A e1 \in log : \A e2 \in log :
        ((e1.k = "moot" /\ e2.k = "fired" /\ e1.s = e2.s) => e2.n < e1.n)

\* Invariant 3.1: IF a workflow IS IN the quiescent workflows THEN EVERY committed act on the
\* workflow MUST carry EXACTLY ONE outcome. The acts are a history entry (its firing event), a
\* submission (its opening event) and a decision (its decision event).
Invariant_3_1 ==
    Quiescent =>
        /\ \A h \in hist :
              (Aged(h.at) \/ Cardinality({e \in log : e.k = "fired" /\ e.t = h.t}) = 1)
        /\ \A s \in Steps :
              ((st[s] = "unused" \/ Aged(subAt[s])) \/
               Cardinality({e \in log : e.k = "opened" /\ e.s = s}) = 1)
        /\ \A s \in Steps :
              ((~(st[s] \in {"approved", "rejected"}) \/ Aged(decAt[s]) \/ MootNames(s)) \/
               Cardinality({e \in log : e.k = "decided" /\ e.s = s}) = 1)

\* Invariant 3.2: EVERY moot cascade entry on a quiescent workflow MUST carry EXACTLY ONE moot
\* record. An entry is a committed firing and a step its moot plan names.
Invariant_3_2 ==
    Quiescent =>
        (\A e \in log : \A s \in Steps :
            ((e.k = "fint" /\ s \in e.plan /\ ~Aged(e.at)) =>
             Cardinality({m \in log : m.k = "moot" /\ m.t = e.t /\ m.s = s}) = 1))

\* Invariant 4.1: IF a gate's bound step EQUALS Pending AND the workflow IS IN the quiescent
\* workflows THEN the step MUST carry EXACTLY ONE Active assignment.
Invariant_4_1 ==
    Quiescent =>
        (\A g \in Gates : (bound[g] /= NoStep /\ st[bound[g]] = "pending") => asg[bound[g]] = "active")

\* Invariant 4.2: IF a gate's bound step IS IN the settled steps AND the workflow IS IN the
\* quiescent workflows THEN the step MUST carry no Active assignment. Settled steps are the
\* terminal ones and the ones a moot record names.
Invariant_4_2 ==
    Quiescent =>
        (\A s \in Steps :
            ((st[s] \in {"approved", "rejected", "withdrawn"} \/ MootNames(s)) => asg[s] /= "active"))

\* Invariant 6.1: IF a workflow IS IN the quiescent workflows THEN the workflow's process proof
\* MUST resolve provably: each guarded entry carries a firing event naming a step approved
\* under it, and every act is attributed and sealed (its one outcome).
Invariant_6_1 == Quiescent => (Invariant_1_1 /\ Invariant_3_1)

\* Invariant 1 (heading, one firing per approval), read from the machine's history and the fire
\* intents, which a purged firing event cannot weaken: no two committed firings name one step.
Invariant_1_OneFiringPerApproval ==
    \A e1 \in log : \A e2 \in log :
        ((e1.k = "fint" /\ e2.k = "fint" /\ e1.s = e2.s) => e1.n = e2.n)

\* Wiring decision 4 (Term mooting rule): a step a committed firing's moot plan names does not
\* clear a later firing, whatever has landed of its cascade.
Wiring_decision_4_MootedNeverFires ==
    \A e \in log : \A f \in log :
        ((e.k = "fint" /\ f.k = "fint" /\ f.s \in e.plan) => f.n < e.n)

\* Wiring decision 3 (Term consumption rule, Wiring decision 5): an approval nothing has
\* spent or mooted is live, so no history entry from before the step was submitted, aged or
\* not, can make it read as consumed.
Wiring_decision_3_FreshApprovalLive ==
    \A s \in Steps :
        ((st[s] = "approved"
          /\ ~(\E h \in hist : h.g = sgate[s] /\ h.at >= subAt[s])
          /\ ~(\E e \in log : e.k = "fint" /\ s \in e.plan)
          /\ ~cm[s] /\ ~mm[s]) => Live(s))

\* Reconciliation 5: the sweep MUST NOT examine an aged record. A record the sweep wrote
\* names the instant of the record it closed, and the sweep's own instant is within the horizon
\* of it.
Reconciliation_5_SweepStaysInsideHorizon ==
    \A e \in log : (e.rl /= "none" => e.at <= e.ia + Horizon)

\* Reconciliation 8: the sweep MUST NOT commit constituent state BEFORE its recovery intent for
\* the closure lands. Every record a leg wrote has a recovery record for its closure earlier in
\* the log. The firing leg's closure is the firing (its transition id); the other two name the
\* step as well.
Reconciliation_8_RecoveryFirst ==
    \A e \in log :
        (e.rl /= "none" /\ e.k /= "recov") =>
        (\E r \in log : /\ r.k = "recov"
                         /\ r.rl = e.rl
                         /\ (e.rl = "decision" \/ r.t = e.t)
                         /\ (e.rl = "firing" \/ r.s = e.s)
                         /\ r.n < e.n)

\* Reconciliation 19 and 20: a decision event answers the decision intent it names (its t),
\* and that intent carries the step's own decision and decided instant, never a refused
\* attempt's.
Reconciliation_19_DecisionMatchesStep ==
    \A e \in log :
        (e.k = "decided") =>
        (\E d \in log : /\ d.k = "dint"
                        /\ d.n = e.t
                        /\ d.s = e.s
                        /\ d.dec = st[e.s]
                        /\ d.ia = decAt[e.s])

Safety ==
    /\ TypeOK
    /\ Invariant_1_1
    /\ Invariant_1_2
    /\ Invariant_1_3
    /\ Invariant_3_1
    /\ Invariant_3_2
    /\ Invariant_4_1
    /\ Invariant_4_2
    /\ Invariant_6_1
    /\ Invariant_1_OneFiringPerApproval
    /\ Wiring_decision_4_MootedNeverFires
    /\ Wiring_decision_3_FreshApprovalLive
    /\ Reconciliation_5_SweepStaysInsideHorizon
    /\ Reconciliation_8_RecoveryFirst
    /\ Reconciliation_19_DecisionMatchesStep

====
