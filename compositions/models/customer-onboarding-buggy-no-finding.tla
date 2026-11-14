---- MODULE customer-onboarding-buggy-no-finding ----
\* BUGGY TWIN (no-finding): The reconciliation pairs a state change with the intents of its kind alone, not their pairing datum, so a suspend written outside every invocation opens no finding once an adverse trigger intent exists (Reconciliation 38; Write_ownership_finding). The checker must reject it. Everything else is the correct model.
\* Grace Commons — Customer Onboarding.
\* Party Identity + Retention Window + Audit Trail (substrate) + Recoverable Invocation.
\* Spec-level formal sibling of compositions/customer-onboarding.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-10 for the page's composition of Recoverable Invocation (Composes 27
\* to 31, Term onboarding bindings). The model it replaces was a counter: one step raised a
\* trigger and suspended, another cleared one and reinstated on the last, so the
\* biconditional open-trigger <=> Suspended held by construction and no recovery was in it.
\* Under Recoverable Invocation each acting action is an open, a commit and a close, three
\* commits and not one transaction (Non-goal 22), acts of different kinds on one party
\* interleave between their opens and their commits, and the open-trigger set is rebuilt
\* from the trigger intents and their closings (Composition state 31 to 34). So this one
\* model follows the split arc for the three kinds the trigger set rests on: the adverse
\* trigger, the clearance (one act: verify and reinstate in one transaction) and the
\* closure, each commit with the re-read the page puts inside it (Action wiring 162 to 167).
\*
\* RECOVERABLE INVOCATION, AS A CONTRACT. Nothing of its mechanism is modelled: no lease, no
\* examine edge, no horizon, no clock arithmetic. What this model takes from it, and
\* recoverable-invocation.tla checks:
\*   - [Open] writes the intent before the commit, and refuses act-in-flight while an intent
\*     of the same (kind, party) stands live, committed or dead (open step 3.5). One party,
\*     so the act key is one value and the critical section is per kind.
\*   - The commit answers committed, pre-commit or unknown (commit 1); committed goes to
\*     [Close], pre-commit to [Refuse] (a refusal record carrying the constituent's code),
\*     unknown to [Yield] (commit 8). An unknown arm may or may not have written.
\*   - A close that fails, or an invocation that dies after its commit, leaves the intent
\*     open for the sweep (Cross-record consistency 1).
\*   - The sweep examines only an intent whose invocation is gone, runs the page's act probe
\*     (Party Identity's state change at the pairing datum, of the kind's new state), and
\*     writes the recovered outcome on exactly one match, an escalation otherwise
\*     (reconcile step 3.2, 3.5, 3.8).
\*   - An operator, through the invocation resolve, may close an open or escalated intent
\*     with an outcome, or abandon it; the resolve checks the outcome against no
\*     constituent record (resolve 28, 31).
\*
\* WHAT THIS MODEL CHECKS
\* One party, verified with an active case at the start; NT adverse triggers; N bound
\* invocations, each an adverse trigger, a clearance or a closure; MaxDirect state changes
\* written on Party Identity outside every invocation; and whatever order they, the sweep,
\* the operator and the reconciliation take:
\*   - Inv_OpenTriggerIffSuspended  at quiescence on an active case, with no operator
\*                              closing and no outside write, the rebuilt open-trigger set is
\*                              non-empty exactly when the party is suspended (Invariant 7.1,
\*                              7.2, Term quiescent case).
\*   - Rebuild_faithful         the rebuilt set always holds every trigger under
\*                              investigation, and at quiescence exactly those: a refusal
\*                              carrying already-suspended keeps its trigger, any other drops
\*                              it, an escalated or open intent keeps it (Composition state 31
\*                              to 34; the trigger set the ghost `gt` tracks from the facts).
\*   - Clear_names_current      a committed clearance names exactly the triggers under
\*                              investigation at its commit (Action wiring 164, 165).
\*   - Closed_case_empty        a quiescent closed case carries no open trigger, the closure
\*                              having swept every one (Invariant 7.4, 7.5; Action wiring 166,
\*                              167).
\*   - Owed_outcome             an invocation whose commit wrote stands open or beside a
\*                              closing that is no refusal (Cross-record consistency 1).
\*   - Pairing_unique           the sweep answers committed only for the intent whose own
\*                              commit wrote the state change (Capability requirement 48, 49).
\*   - Write_ownership_finding  the reconciliation opens a finding for every state change no
\*                              intent carries, and for no other (Reconciliation 37, 38).
\*   - False_closing_alert      it alerts exactly the state changes whose carrying intent an
\*                              abandonment or a refusal closed (Reconciliation 39).
\*
\* BOUND
\* NT = 2 trigger ids, taken in order at an adverse trigger's open. N = 3 bound invocations,
\* taken in slot order. MaxDirect = 1. Each invocation takes a fresh now from an ordinal
\* clock as its pairing datum (Capability requirement 48, 49), which Party Identity stamps
\* as the state change instant; an outside write reads the same clock. Exhaustive.
\*
\* HOW A STEP IS READ
\* A bound invocation is a slot; its status `st` is none, live (the intent landed),
\* committed, dead (yielded, died, or its close failed: the intent open, the sweep's),
\* closed (an outcome names it), refused (a refusal record carrying `code`), escalated or
\* abandoned. `cby` says who wrote the closing. `cw` says its own commit wrote (a ghost);
\* `scby` says which invocation wrote a state change (0: outside every invocation; a ghost);
\* `gt` is the set of triggers under investigation as the facts stand (a ghost), and `ost`
\* the ghost set a clearance's commit saw. The reconciliation's answers are compared with
\* the ghosts by a name its step adds to `viol`.
\*
\* NOT MODELLED (named)
\* - Recoverable Invocation's mechanism and its own invariants (one writer per act, the
\*   recovery intent before a recovered outcome, the recovery flag, the closure window, the
\*   escalation's candidates, Invariant 1.1's intent-first order that Invariant 3.1 now rests
\*   on): recoverable-invocation.tla, inherited here.
\* - The enrollment, admission, verification and periodic review kinds, Retention Window's
\*   placements and the gate: the party starts verified under an active case. Invariant 1,
\*   2, 5 and 6 are out of the model.
\* - The clock and its edges: the young and aged records, the cut-over instant, the audit
\*   horizon. A commit landing after its invocation yielded is the unknown arm that wrote.
\* - Validation ahead of the open is read from the indexes only: an adverse trigger opens on
\*   an active case whatever the party's state, so the suspension transaction's re-read is
\*   what guards the suspend (Action wiring 162, 163).
\* - The alerts of Reconciliation 22, 23, 25 and 43, which read state the model holds
\*   directly: an operator's closing that breaks Invariant 7.1 or 7.2 is excluded from
\*   `Inv_OpenTriggerIffSuspended` and named detected, not prevented.

EXTENDS Naturals, FiniteSets

CONSTANTS NT, N, MaxDirect

Is == 1..N
Tr == 1..NT
MaxT == N + MaxDirect
MaxSC == N + MaxDirect
SCs == 1..MaxSC
OpenSt == {"live", "committed", "dead"}
Unclosed == {"live", "committed", "dead", "escalated"}

VARIABLES
    pst, nsc, sci, scs, scby,                       \* Party Identity
    ik, itr, iset, inow, st, cw, code, cby, oe, ost, \* the bound invocations
    nx, ntr, clk, ndir, gt, viol
vars == <<pst, nsc, sci, scs, scby, ik, itr, iset, inow, st, cw, code, cby, oe, ost,
          nx, ntr, clk, ndir, gt, viol>>

pi == <<pst, nsc, sci, scs, scby>>
inv == <<ik, itr, iset, inow, st, cw, code, cby, oe, ost>>

SC == 1..nsc

\* --- the act section: one live, committed or dead intent per (kind, party) ---
OpenOn(k) == \E j \in Is : ik[j] = k /\ st[j] \in OpenSt

\* --- the case's active flag: false once a closure outcome stands (Composition state 25) ---
Active == ~(\E j \in Is : ik[j] = "cls" /\ st[j] = "closed")

\* --- the rebuild of the case-to-open-triggers index (Composition state 31 to 34) ---
Dropped(i) == st[i] = "abandoned" \/ (st[i] = "refused" /\ code[i] # "as")
Swept(t) == \E j \in Is : ik[j] \in {"clr", "cls"} /\ st[j] = "closed" /\ t \in iset[j]
OpenSet == {t \in Tr : \E i \in Is : /\ ik[i] = "adv"
                                     /\ itr[i] = t
                                     /\ ~Dropped(i)
                                     /\ ~Swept(t)}

Quiescent == ~(\E i \in Is : st[i] \in Unclosed)
OpTouched == \E i \in Is : cby[i] = "op"

\* --- the act probes: Party Identity's state change at the pairing datum, of the kind's
\* new state (Term suspension probe, clearance probe, closure probe) ---
Target(k) == IF k = "adv" THEN "S" ELSE IF k = "clr" THEN "V" ELSE "C"
Matches(i) == {k \in SC : sci[k] = inow[i] /\ scs[k] = Target(ik[i])}

\* --- the reconciliation's reading (Reconciliation 37 to 39; Term carried record) ---
Target2(s) == IF s = "S" THEN "adv" ELSE IF s = "V" THEN "clr" ELSE "cls"
Carries(i, k) == ik[i] = Target2(scs[k]) /\ st[i] # "none"  \* BUG: no pairing datum
LegFinds(k) == ~(\E i \in Is : Carries(i, k))
Closed0 == {"abandoned", "refused"}
LegAlerts(k) == \E i \in Is : Carries(i, k) /\ st[i] \in Closed0
\* --- the truth they are compared with ---
FalseClosing(k) == scby[k] # 0 /\ st[scby[k]] \in Closed0

TypeOK ==
    /\ pst \in {"V", "S", "C"}
    /\ nsc \in 0..MaxSC
    /\ sci \in [SCs -> 0..MaxT]
    /\ scs \in [SCs -> {"-", "S", "V", "C"}]
    /\ scby \in [SCs -> 0..N]
    /\ ik \in [Is -> {"-", "adv", "clr", "cls"}]
    /\ itr \in [Is -> 0..NT]
    /\ iset \in [Is -> SUBSET Tr]
    /\ inow \in [Is -> 0..MaxT]
    /\ st \in [Is -> {"none", "live", "committed", "dead", "closed", "refused",
                      "escalated", "abandoned"}]
    /\ cw \in [Is -> BOOLEAN]
    /\ code \in [Is -> {"-", "as", "nv", "tc", "vf", "na"}]
    /\ cby \in [Is -> {"-", "inv", "sweep", "op"}]
    /\ oe \in [Is -> 0..MaxSC]
    /\ ost \in [Is -> SUBSET Tr]
    /\ nx \in 1..(N + 1)
    /\ ntr \in 1..(NT + 1)
    /\ clk \in 0..MaxT
    /\ ndir \in 0..MaxDirect
    /\ gt \subseteq Tr
    /\ viol \subseteq {"finding-false", "finding-missed", "alert-wrong"}

Init ==
    /\ pst = "V"
    /\ nsc = 0
    /\ sci = [k \in SCs |-> 0]
    /\ scs = [k \in SCs |-> "-"]
    /\ scby = [k \in SCs |-> 0]
    /\ ik = [i \in Is |-> "-"]
    /\ itr = [i \in Is |-> 0]
    /\ iset = [i \in Is |-> {}]
    /\ inow = [i \in Is |-> 0]
    /\ st = [i \in Is |-> "none"]
    /\ cw = [i \in Is |-> FALSE]
    /\ code = [i \in Is |-> "-"]
    /\ cby = [i \in Is |-> "-"]
    /\ oe = [i \in Is |-> 0]
    /\ ost = [i \in Is |-> {}]
    /\ nx = 1
    /\ ntr = 1
    /\ clk = 0
    /\ ndir = 0
    /\ gt = {}
    /\ viol = {}

\* ---------------------------------------------------------------------------------------
\* The acting actions: validate, open, commit, close (Recoverable Invocation Action wiring 4).

\* The pairing datum the host injects: a fresh now (Capability requirement 48, 49).
Nows == {clk + 1}

\* [Trigger Monitoring Review], an adverse type: the open on an active case (Action wiring
\* 39, 46), the trigger intent carrying a fresh trigger id; the trigger is under
\* investigation from its intent.
OpenAdv(t) ==
    LET i == nx IN
    /\ i <= N
    /\ ntr <= NT
    /\ Active
    /\ ~OpenOn("adv")
    /\ ik' = [ik EXCEPT ![i] = "adv"]
    /\ itr' = [itr EXCEPT ![i] = ntr]
    /\ inow' = [inow EXCEPT ![i] = t]
    /\ st' = [st EXCEPT ![i] = "live"]
    /\ clk' = t
    /\ nx' = i + 1
    /\ ntr' = ntr + 1
    /\ gt' = gt \cup {ntr}
    /\ UNCHANGED <<pi, iset, cw, code, cby, oe, ost, ndir, viol>>

\* [Clear Review]: the open on a case carrying an open trigger, the intent naming the
\* open-trigger set as the closed triggers (Action wiring 82, 83).
OpenClr(t) ==
    LET i == nx IN
    /\ i <= N
    /\ OpenSet # {}
    /\ ~OpenOn("clr")
    /\ ik' = [ik EXCEPT ![i] = "clr"]
    /\ iset' = [iset EXCEPT ![i] = OpenSet]
    /\ inow' = [inow EXCEPT ![i] = t]
    /\ st' = [st EXCEPT ![i] = "live"]
    /\ clk' = t
    /\ nx' = i + 1
    /\ UNCHANGED <<pi, itr, cw, code, cby, oe, ost, ntr, ndir, gt, viol>>

\* [Close Party]: the open on an active case, the intent naming the open-trigger set as the
\* open triggers at close (Action wiring 114, 115).
OpenCls(t) ==
    LET i == nx IN
    /\ i <= N
    /\ Active
    /\ ~OpenOn("cls")
    /\ ik' = [ik EXCEPT ![i] = "cls"]
    /\ iset' = [iset EXCEPT ![i] = OpenSet]
    /\ inow' = [inow EXCEPT ![i] = t]
    /\ st' = [st EXCEPT ![i] = "live"]
    /\ clk' = t
    /\ nx' = i + 1
    /\ UNCHANGED <<pi, itr, cw, code, cby, oe, ost, ntr, ndir, gt, viol>>

\* A pre-commit arm closed through [Refuse] with its refusal record: nothing written.
Refuse(i, c) ==
    /\ st' = [st EXCEPT ![i] = "refused"]
    /\ code' = [code EXCEPT ![i] = c]

\* A state change Party Identity writes, stamped with the injected now.
Write(s, i) ==
    LET k == nsc + 1 IN
    /\ k <= MaxSC
    /\ pst' = s
    /\ nsc' = k
    /\ sci' = [sci EXCEPT ![k] = inow[i]]
    /\ scs' = [scs EXCEPT ![k] = s]
    /\ scby' = [scby EXCEPT ![k] = i]

\* The suspension transaction (Term suspension transaction): the re-run pre-check (Action
\* wiring 162, 163), then Party Identity's suspend. a = "committed" or "unk-done" (the
\* unknown arm that wrote: the invocation yields).
CommitAdv(i, a) ==
    /\ st[i] = "live"
    /\ ik[i] = "adv"
    /\ pst = "V"
    /\ Write("S", i)
    /\ cw' = [cw EXCEPT ![i] = TRUE]
    /\ st' = [st EXCEPT ![i] = IF a = "committed" THEN "committed" ELSE "dead"]
    /\ UNCHANGED <<ik, itr, iset, inow, code, cby, oe, ost, nx, ntr, clk, ndir, gt, viol>>

\* Party Identity answers already-suspended: a pre-commit arm, refused carrying the code;
\* the trigger stays under investigation (Action wiring 53 to 55; Composition state 32).
AdvRefuseAs(i) ==
    /\ st[i] = "live"
    /\ ik[i] = "adv"
    /\ pst = "S"
    /\ Refuse(i, "as")
    /\ UNCHANGED <<pi, ik, itr, iset, inow, cw, cby, oe, ost, nx, ntr, clk, ndir, gt, viol>>

\* The re-run pre-check finds the party closed: refused not-verified; the trigger had no
\* effect and is no longer under investigation (Action wiring 163; Composition state 32).
AdvRefuseNv(i) ==
    /\ st[i] = "live"
    /\ ik[i] = "adv"
    /\ pst = "C"
    /\ Refuse(i, "nv")
    /\ gt' = gt \ {itr[i]}
    /\ UNCHANGED <<pi, ik, itr, iset, inow, cw, cby, oe, ost, nx, ntr, clk, ndir, viol>>

\* An adverse trigger intent carrying no closing: its suspend may yet commit.
AdvInFlight == \E j \in Is : ik[j] = "adv" /\ st[j] \in OpenSt

\* The clearance transaction (Term clearance transaction): the re-read of the case's open
\* triggers against the intent's set, and of the adverse trigger intents carrying no
\* closing (Action wiring 164), then verify(passed) and reinstate, together.
CommitClr(i, a) ==
    /\ st[i] = "live"
    /\ ik[i] = "clr"
    /\ OpenSet = iset[i]
    /\ ~AdvInFlight
    /\ pst = "S"
    /\ Write("V", i)
    /\ cw' = [cw EXCEPT ![i] = TRUE]
    /\ ost' = [ost EXCEPT ![i] = gt]
    /\ gt' = gt \ iset[i]
    /\ st' = [st EXCEPT ![i] = IF a = "committed" THEN "committed" ELSE "dead"]
    /\ UNCHANGED <<ik, itr, iset, inow, code, cby, oe, nx, ntr, clk, ndir, viol>>

\* The re-read finds another set, or an adverse trigger intent carrying no closing:
\* refused triggers-changed (Action wiring 165).
ClrRefuseTc(i) ==
    /\ st[i] = "live"
    /\ ik[i] = "clr"
    /\ (OpenSet # iset[i] \/ AdvInFlight)
    /\ Refuse(i, "tc")
    /\ UNCHANGED <<pi, ik, itr, iset, inow, cw, cby, oe, ost, nx, ntr, clk, ndir, gt, viol>>

\* The reinstate refused (not-suspended, already-closed): the verify rolls back with it,
\* refused verification-failed (Action wiring 96 to 98, 155).
ClrRefuseVf(i) ==
    /\ st[i] = "live"
    /\ ik[i] = "clr"
    /\ OpenSet = iset[i]
    /\ ~AdvInFlight
    /\ pst # "S"
    /\ Refuse(i, "vf")
    /\ UNCHANGED <<pi, ik, itr, iset, inow, cw, cby, oe, ost, nx, ntr, clk, ndir, gt, viol>>

\* The closure transaction (Term closure transaction): the re-read of the case's open
\* triggers (Action wiring 166), then Party Identity's close and the post closure placement.
CommitCls(i, a) ==
    /\ st[i] = "live"
    /\ ik[i] = "cls"
    /\ OpenSet = iset[i]
    /\ pst # "C"
    /\ Write("C", i)
    /\ cw' = [cw EXCEPT ![i] = TRUE]
    /\ gt' = gt \ iset[i]
    /\ st' = [st EXCEPT ![i] = IF a = "committed" THEN "committed" ELSE "dead"]
    /\ UNCHANGED <<ik, itr, iset, inow, code, cby, oe, ost, nx, ntr, clk, ndir, viol>>

\* The re-read finds another set: refused triggers-changed (Action wiring 167).
ClsRefuseTc(i) ==
    /\ st[i] = "live"
    /\ ik[i] = "cls"
    /\ OpenSet # iset[i]
    /\ Refuse(i, "tc")
    /\ UNCHANGED <<pi, ik, itr, iset, inow, cw, cby, oe, ost, nx, ntr, clk, ndir, gt, viol>>

\* Party Identity answers already-closed: refused not-active (Action wiring 119).
ClsRefuseNa(i) ==
    /\ st[i] = "live"
    /\ ik[i] = "cls"
    /\ OpenSet = iset[i]
    /\ pst = "C"
    /\ Refuse(i, "na")
    /\ UNCHANGED <<pi, ik, itr, iset, inow, cw, cby, oe, ost, nx, ntr, clk, ndir, gt, viol>>

\* An unknown arm that wrote nothing: the invocation yields (Action wiring 156).
CommitLost(i) ==
    /\ st[i] = "live"
    /\ st' = [st EXCEPT ![i] = "dead"]
    /\ UNCHANGED <<pi, ik, itr, iset, inow, cw, code, cby, oe, ost, nx, ntr, clk, ndir, gt, viol>>

\* [Close] after a committed arm (Action wiring 63, 90, 127). It may fail, or the
\* invocation may die first: the intent stays open for the sweep (Cross-record
\* consistency 1).
Close(i, o) ==
    /\ st[i] = "committed"
    /\ \/ /\ o = "ok"
          /\ st' = [st EXCEPT ![i] = "closed"]
          /\ cby' = [cby EXCEPT ![i] = "inv"]
       \/ /\ o = "fail"
          /\ st' = [st EXCEPT ![i] = "dead"]
          /\ UNCHANGED cby
    /\ UNCHANGED <<pi, ik, itr, iset, inow, cw, code, oe, ost, nx, ntr, clk, ndir, gt, viol>>

\* ---------------------------------------------------------------------------------------
\* Recoverable Invocation's sweep and the operator's resolve, as contracts.

\* The sweep on an intent whose invocation is gone: exactly one match is committed, and
\* the recovered outcome names it.
SweepClose(i) ==
    /\ st[i] = "dead"
    /\ Cardinality(Matches(i)) = 1
    /\ st' = [st EXCEPT ![i] = "closed"]
    /\ cby' = [cby EXCEPT ![i] = "sweep"]
    /\ oe' = [oe EXCEPT ![i] = CHOOSE k \in Matches(i) : TRUE]
    /\ UNCHANGED <<pi, ik, itr, iset, inow, cw, code, ost, nx, ntr, clk, ndir, gt, viol>>

\* Otherwise (none, or several) it escalates.
SweepEscalate(i) ==
    /\ st[i] = "dead"
    /\ Cardinality(Matches(i)) # 1
    /\ st' = [st EXCEPT ![i] = "escalated"]
    /\ UNCHANGED <<pi, ik, itr, iset, inow, cw, code, cby, oe, ost, nx, ntr, clk, ndir, gt, viol>>

\* The operator's abandonment of an open or escalated intent. Where the act did not
\* commit, a trigger it carried is no longer under investigation; where it did, the
\* abandonment is a false closing (Term false closing).
OpAbandon(i) ==
    /\ st[i] \in {"dead", "escalated"}
    /\ st' = [st EXCEPT ![i] = "abandoned"]
    /\ cby' = [cby EXCEPT ![i] = "op"]
    /\ gt' = IF ik[i] = "adv" /\ ~cw[i] THEN gt \ {itr[i]} ELSE gt
    /\ UNCHANGED <<pi, ik, itr, iset, inow, cw, code, oe, ost, nx, ntr, clk, ndir, viol>>

\* The operator's outcome, checked against no constituent record (resolve 28, 31).
OpOutcome(i) ==
    /\ st[i] \in {"dead", "escalated", "abandoned"}
    /\ st' = [st EXCEPT ![i] = "closed"]
    /\ cby' = [cby EXCEPT ![i] = "op"]
    /\ UNCHANGED <<pi, ik, itr, iset, inow, cw, code, oe, ost, nx, ntr, clk, ndir, gt, viol>>

\* ---------------------------------------------------------------------------------------
\* A state change written on Party Identity outside every invocation, with no intent,
\* stamped from the same clock (Composes 20; Non-goal 20).
DirectSuspend ==
    LET k == nsc + 1 IN
    /\ ndir < MaxDirect
    /\ k <= MaxSC
    /\ pst = "V"
    /\ pst' = "S"
    /\ nsc' = k
    /\ sci' = [sci EXCEPT ![k] = clk + 1]
    /\ scs' = [scs EXCEPT ![k] = "S"]
    /\ scby' = [scby EXCEPT ![k] = 0]
    /\ clk' = clk + 1
    /\ ndir' = ndir + 1
    /\ UNCHANGED <<inv, nx, ntr, gt, viol>>

DirectReinstate ==
    LET k == nsc + 1 IN
    /\ ndir < MaxDirect
    /\ k <= MaxSC
    /\ pst = "S"
    /\ pst' = "V"
    /\ nsc' = k
    /\ sci' = [sci EXCEPT ![k] = clk + 1]
    /\ scs' = [scs EXCEPT ![k] = "V"]
    /\ scby' = [scby EXCEPT ![k] = 0]
    /\ clk' = clk + 1
    /\ ndir' = ndir + 1
    /\ UNCHANGED <<inv, nx, ntr, gt, viol>>

\* The reconciliation (Reconciliation 37 to 39): every state change read against the
\* intents. It opens a finding and alerts by the page's rule; the names it adds compare
\* the rule's answer with what the records hold.
LegRun ==
    /\ viol' = viol
         \cup (IF \E k \in SC : LegFinds(k) /\ scby[k] # 0 THEN {"finding-false"} ELSE {})
         \cup (IF \E k \in SC : ~LegFinds(k) /\ scby[k] = 0 THEN {"finding-missed"} ELSE {})
         \cup (IF \E k \in SC : LegAlerts(k) # FalseClosing(k) THEN {"alert-wrong"} ELSE {})
    /\ UNCHANGED <<pi, inv, nx, ntr, clk, ndir, gt>>

Next ==
    \/ \E t \in Nows : OpenAdv(t)
    \/ \E t \in Nows : OpenClr(t)
    \/ \E t \in Nows : OpenCls(t)
    \/ \E i \in Is, a \in {"committed", "unk-done"} : CommitAdv(i, a)
    \/ \E i \in Is : AdvRefuseAs(i)
    \/ \E i \in Is : AdvRefuseNv(i)
    \/ \E i \in Is, a \in {"committed", "unk-done"} : CommitClr(i, a)
    \/ \E i \in Is : ClrRefuseTc(i)
    \/ \E i \in Is : ClrRefuseVf(i)
    \/ \E i \in Is, a \in {"committed", "unk-done"} : CommitCls(i, a)
    \/ \E i \in Is : ClsRefuseTc(i)
    \/ \E i \in Is : ClsRefuseNa(i)
    \/ \E i \in Is : CommitLost(i)
    \/ \E i \in Is, o \in {"ok", "fail"} : Close(i, o)
    \/ \E i \in Is : SweepClose(i)
    \/ \E i \in Is : SweepEscalate(i)
    \/ \E i \in Is : OpAbandon(i)
    \/ \E i \in Is : OpOutcome(i)
    \/ DirectSuspend
    \/ DirectReinstate
    \/ LegRun
Spec == Init /\ [][Next]_vars

\* --- composition-level safety invariants ---

\* Invariant 7.1, 7.2: at quiescence on an active case, the rebuilt set is non-empty
\* exactly when the party is suspended. An operator's closing and an outside write are
\* detected, not prevented (Reconciliation 23, 38, 39, 43), so they are read apart.
Inv_OpenTriggerIffSuspended ==
    (Quiescent /\ Active /\ ~OpTouched /\ ndir = 0) => ((OpenSet # {}) = (pst = "S"))

\* Composition state 31 to 34: the rebuilt set holds every trigger under investigation,
\* and at quiescence no other.
Rebuild_faithful ==
    ~OpTouched => (/\ gt \subseteq OpenSet
                   /\ (Quiescent => OpenSet = gt))

\* Action wiring 164, 165: a committed clearance names exactly the triggers under
\* investigation at its commit.
Clear_names_current ==
    \A i \in Is : (ik[i] = "clr" /\ cw[i] /\ ~OpTouched) => (ost[i] = iset[i])

\* Invariant 7.4, 7.5: a quiescent closed case carries no open trigger.
Closed_case_empty ==
    (Quiescent /\ ~Active /\ ~OpTouched) => (OpenSet = {})

\* Cross-record consistency 1: an invocation whose commit wrote stands open or beside a
\* closing that is no refusal.
Owed_outcome ==
    \A i \in Is : cw[i] => (st[i] \in {"committed", "dead", "closed", "escalated", "abandoned"})

\* Capability requirement 48, 49: the sweep answers committed only for the intent whose
\* own commit wrote the state change.
Pairing_unique ==
    \A i \in Is : (st[i] = "closed" /\ cby[i] = "sweep") => (scby[oe[i]] = i)

\* Reconciliation 37, 38: a finding for every state change no intent carries, and for no
\* other.
Write_ownership_finding == ~("finding-false" \in viol) /\ ~("finding-missed" \in viol)

\* Reconciliation 39: an alert for exactly the state changes whose own intent an
\* abandonment or a refusal closed.
False_closing_alert == ~("alert-wrong" \in viol)

====
