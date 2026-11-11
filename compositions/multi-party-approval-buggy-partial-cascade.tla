---- MODULE multi-party-approval-buggy-partial-cascade ----
\* BUGGY TWIN (partial-cascade): a cascade's temporal invalid-request lets the commit proceed (Cascade 14 dropped, the retired partial-flag reading): a Pending step stands on a Withdrawn chain (No_withdrawn_residue). The checker must reject it. Everything else is the correct model.
\* Grace Commons — Multi-Party Approval, the chain, its quorum and its five act kinds.
\* Approval Step + Permissions + Assignment + Audit Trail (substrate) + Recoverable Invocation.
\* Spec-level formal sibling of compositions/multi-party-approval.md. Derived validator; the
\* English spec is the single source of truth. On any disagreement, diagnose per the entry
\* *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-10 for the page's composition of Recoverable Invocation (Composes 13 to
\* 17, Term chain bindings). The model of 2026-10-26 read each action as one transaction with
\* an initiation recovery (dispositions a and c, the quarantine), the sweep's retry of a call a
\* partial flag named, and the initiation leg. Those premises are gone: a state-changing action
\* is an open, a commit and a close, three commits and not one transaction (Non-goal 15;
\* Recoverable Invocation Non-goal 1); a refused submit or assign fails the initiation
\* transaction whole (Action wiring 9, 12); a cascade's temporal refusal fails its commit
\* (Cascade 14); and an act whose outcome never landed is Recoverable Invocation's sweep's.
\*
\* ONE CHAIN of N approver slots, under a quorum rule the initial state chooses: [All Of N], or
\* [M Of N] with M below N ([One Of N] is M = 1; [M Of N] with M = N reads as [All Of N]).
\*
\* RECOVERABLE INVOCATION, AS A CONTRACT. Nothing of its mechanism is modelled: no lease, no
\* critical section, no examine edge, no horizon, no clock arithmetic. What this model takes from
\* it, and recoverable-invocation.tla checks:
\*   - [Open] writes the intent before the commit, and refuses act-in-flight while an intent of
\*     the same (kind, act key) stands live, committed or dead (open step 1.7, 3.5).
\*   - The commit answers committed, pre-commit or unknown (commit 1): committed goes to
\*     [Close], pre-commit to [Refuse] (a refusal record, nothing else written), unknown to
\*     [Yield] (commit 8). An unknown arm may or may not have written: the environment chooses.
\*   - A close that fails, or an invocation that dies after its commit, leaves the intent open
\*     for the sweep (Cross-record consistency 1).
\*   - The sweep examines only an intent whose invocation is gone, runs the page's act probe, and
\*     writes the recovered outcome (behind a recovery intent, flagged, under the recovery
\*     identity: one step here, reconcile step 3.2a) on committed, or an escalation otherwise
\*     (reconcile step 3.2, 3.5, 3.8). An unavailable probe writes nothing: a stutter step.
\*   - An operator, through the invocation resolve, may close a dead or escalated intent with an
\*     outcome carrying any data, or abandon it, and may supersede an abandonment with an outcome
\*     (resolve 14 to 16, 32). The resolve does not check the outcome against the chain records
\*     or Approval Step (resolve 28, 31).
\*
\* THE CONSTITUENTS, as contracts. Approval Step: a step decides once, from Pending, by its
\* approver (approve, reject) or its submitter (withdraw), stamping the injected now as its
\* decision instant (Capability requirement 37). Assignment: recall answers ok on an Active
\* assignment and not-active on a Recalled one. Every refusal inside a commit (a submit's or an
\* assign's, a step refusal, the re-reads' mismatches, a cascade's temporal invalid-request, a
\* storage-failure) fails the commit whole and lands the refusal record: one action here,
\* CommitPre, since what each writes is the same, nothing.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv1_1                 a quiescent chain has its full step list (Invariant 1.1).
\*   Inv2_1                 a resolution-terminated chain's state is the quorum rule's answer on
\*                          its routed vector (Invariant 2.1, Check 2.1).
\*   Inv2_2                 the quorum rule answers Pending on a withdrawal-terminated chain's
\*                          pre-withdrawal vector (Invariant 2.2, Check 2.2).
\*   Bypass                 an Approved chain carries the quorum's routed, non-trailing
\*                          approvals: the bypass resistance the page claims.
\*   Inv4_1, Inv4_2         assignment coverage at quiescence (Invariant 4.1, 4.2).
\*   Inv7_1                 a terminal chain's state never changes (Invariant 7.1).
\*   No_withdrawn_residue   a Withdrawn chain carries no Pending step (Cascade 2, Cascade 14).
\*   Trailing_matches       a decision commits only where its intent's trailing flag reads the
\*                          chain state at the commit (Action wiring 64, 65).
\*   Owed_outcome           an invocation whose commit wrote stands open or beside a closing
\*                          (an outcome, an escalation, an abandonment), never a refusal
\*                          (Invariant 5.1; Cross-record consistency 1).
\*   Outcome_names_record   every outcome the invocation or the sweep wrote names the record of
\*                          its kind its pairing datum finds (Term initiation probe, decision
\*                          probe, withdrawal probe; Recoverable Invocation act probe 4, 5).
\*   Terminal_outcome_matches  every outcome the invocation or the sweep wrote carries the
\*                          chain record's terminal summary where its act terminated the chain,
\*                          and none where it did not (Composition state 6, 7; Check 7.1).
\*   Terminal_alert         the chain rebuild alerts a terminal outcome disagreeing with the
\*                          chain record, and two for one chain (Composition state 22).
\*   Shape_alert            the chain rebuild alerts an initiation outcome whose chain shape
\*                          disagrees with the chain record (Composition state 23).
\*   Pairing_unique         a record carries one intent at most, and the sweep answers committed
\*                          only for the intent whose own commit wrote the record (Capability
\*                          requirement 37, 38; Recoverable Invocation pairing datum 2, 4).
\*   Write_ownership_finding  the leg opens a finding for every step decided outside every
\*                          invocation, and for no other (Reconciliation 20).
\*   False_closing_alert    the leg alerts exactly the records whose own intent an abandonment
\*                          or a refusal closed (Reconciliation 50).
\*
\* BOUND
\* N = 3 approver slots. NI = 3 bound invocations, taken in slot order, each an initiation, a
\* decision (approve, reject or withdraw a step) or a chain withdrawal: the initiation and two
\* more, which reach every check's violation in a twin (an [All Of N] chain is not Approved
\* inside the bound; NI = 4 reaches it, a saturation run). MaxOob = 1 step decision written
\* around the composition. MaxFail = 1 failure among the invocations: a pre-commit refusal, an
\* unknown arm, or a close that does not land. Each invocation takes a fresh now from an ordinal
\* clock as its pairing datum (the host's injection, Capability requirement 19, 37, 38), which
\* the composition stamps on the chain record and Approval Step on the step; an out-of-band
\* write reads the same clock. Exhaustive.
\*
\* HOW A STEP IS READ
\* A bound invocation is a slot; its status `st` is none, live (the intent landed), committed,
\* dead (yielded, died, or its close failed: the intent open, the sweep's), closed (an outcome
\* names it), refused (a refusal record), escalated or abandoned. `cby` says who wrote the
\* closing (the invocation, the sweep or the operator), `osum` what terminal state the outcome's
\* terminal summary carries ("none": no summary) and `osh` whether an initiation outcome's chain
\* shape is the chain record's. `cw` says the invocation's own commit wrote and `tcs` what chain
\* state its commit read (ghosts); `cmint`, `ctby` and `sby` say which invocation wrote the chain
\* record, the chain's terminal and a step's decision (0: out of band; ghosts, except that the
\* terminal summary carries the terminating invocation's id, Term terminal summary). The leg's
\* and the rebuild's answers are compared with the ghosts by a name the step adds to `viol`.
\*
\* NOT MODELLED (named)
\* - Recoverable Invocation's mechanism and its own invariants (one writer per act, the recovery
\*   intent before a recovered outcome, the recovery flag, the service identity's attestation,
\*   the closure window, the horizon edge, the escalation's candidates):
\*   recoverable-invocation.tla, inherited here. Authentication before the commit (Recoverable
\*   Invocation Invariant 1.1) is the open's, inherited.
\* - The clock and its edges: the young and aged records, the sweep cadence, the retention
\*   horizon, the aged chains (Reconciliation 5, 44; Invariant 9.1).
\* - Permissions (Invariant 3) and validation ahead of the open (Primitive policy); [Read Chain].
\*   An open names a Pending step; a decision on a decided step is the race the commit's
\*   not-pending refuses.
\* - A cascade call's deterministic arms (Cascade 8, 15) and the superseded arm (Cascade 10):
\*   the cascade withdraws the steps Approval Step holds Pending, so it never meets not-pending
\*   (open line 2026-11-06-c carries the other reading of still-Pending).
\* - A chain record written or terminated outside every invocation (Reconciliation 48, 49): such
\*   a write breaks the chain's own invariants, which hold over the composition's writes
\*   (Composes 12); the leg's step finding is modelled.
\* - The derived indexes (a lost entry is rebuilt before a rule reads it, Composition state 21).

EXTENDS Naturals, FiniteSets

CONSTANTS N, NI, MaxOob, MaxFail

Slots == 1..N
Is == 1..NI
MaxT == NI + MaxOob
Decided == {"Approved", "Rejected", "Withdrawn"}
DecKinds == {"appr", "rej", "swd"}
OpenSt == {"live", "committed", "dead"}
Closed0 == {"abandoned", "refused"}

Verb(k) == IF k = "appr" THEN "Approved" ELSE IF k = "rej" THEN "Rejected" ELSE "Withdrawn"

VARIABLES
    rule, m,                                                    \* the quorum rule
    phase, sub, cs, cat, ctt, cterm, ctby, ccas, cmint, first,  \* the chain record
    ss, how, sat, sby, asg,                                     \* the steps and assignments
    ik, tgt, inow, st, trl, cw, tcs, cby, osum, osh,            \* the bound invocations
    nx, clk, noob, nfail, viol
vars == <<rule, m, phase, sub, cs, cat, ctt, cterm, ctby, ccas, cmint, first,
          ss, how, sat, sby, asg, ik, tgt, inow, st, trl, cw, tcs, cby, osum, osh,
          nx, clk, noob, nfail, viol>>

qr == <<rule, m>>
chain == <<phase, sub, cs, cat, ctt, cterm, ctby, ccas, cmint, first>>
steps == <<ss, how, sat, sby, asg>>
inv == <<ik, tgt, inow, st, trl, cw, tcs, cby, osum, osh>>

\* ---- the routed vector and the quorum rule (Term routed vector, Wiring decision 1 to 7) ----
Met(a)     == IF rule = "all" THEN a = N ELSE a >= m
Lost(r, w) == IF rule = "all" THEN r + w >= 1 ELSE N < r + w + m
Quorum(a, r, w) ==
    IF Met(a) THEN "Approved"
    ELSE IF Lost(r, w) /\ r > 0 THEN "Rejected"
    ELSE IF Lost(r, w) THEN "Withdrawn"
    ELSE "Pending"

\* The page's count: a routed transition whose intent is not trailing, or a cascade withdrawal
\* the terminal summary names; an out-of-band transition counts as Pending.
VecIn(sv, hv, tv, x) == Cardinality({s \in Slots : sv[s] = x /\ ((hv[s] = "routed" /\ ~tv[s]) \/ hv[s] = "cascade")})
QOf(sv, hv, tv) == Quorum(VecIn(sv, hv, tv, "Approved"), VecIn(sv, hv, tv, "Rejected"), VecIn(sv, hv, tv, "Withdrawn"))

\* The implementation's count, which the chain evaluation runs: the page's, in this model.
EvVecIn(sv, hv, tv, x) == Cardinality({s \in Slots : sv[s] = x /\ ((hv[s] = "routed" /\ ~tv[s]) \/ hv[s] = "cascade")})
EvQOf(sv, hv, tv) == Quorum(EvVecIn(sv, hv, tv, "Approved"), EvVecIn(sv, hv, tv, "Rejected"), EvVecIn(sv, hv, tv, "Withdrawn"))

\* A routed step's trailing flag, read from its decision intent (Term routed vector).
TrlVec == [s \in Slots |-> how[s] = "routed" /\ sby[s] \in Is /\ trl[sby[s]]]

\* The pre-withdrawal vector: the cascade withdrawals counted back as Pending.
PwIn(x) == Cardinality({s \in Slots : ss[s] = x /\ how[s] = "routed" /\ ~TrlVec[s]})
PreQ == Quorum(PwIn("Approved"), PwIn("Rejected"), PwIn("Withdrawn"))

RecallAll(a, P) == [s \in Slots |-> IF s \in P /\ a[s] = "Active" THEN "Recalled" ELSE a[s]]

\* ---- the act key's open intent: [Open] refuses act-in-flight while one stands ----
OpenOn(k, key) == \E j \in Is : ik[j] = k /\ st[j] \in OpenSt /\ (k \in DecKinds => tgt[j] = key)

\* ---- the act probes (Term initiation probe, decision probe, withdrawal probe) ----
Matches(i) ==
    IF ik[i] = "init" THEN (IF phase = "live" /\ cat = inow[i] THEN {0} ELSE {})
    ELSE IF ik[i] = "wdr" THEN (IF cterm = "withdrawal" /\ ctt = inow[i] THEN {0} ELSE {})
    ELSE IF ik[i] \in DecKinds THEN
        (IF ss[tgt[i]] = Verb(ik[i]) /\ sat[tgt[i]] = inow[i] THEN {tgt[i]} ELSE {})
    ELSE {}

Writer(i) ==
    IF ik[i] = "init" THEN cmint ELSE IF ik[i] = "wdr" THEN ctby ELSE sby[tgt[i]]

\* The terminal summary a probe or a close reads off the chain record for invocation i.
SumFor(i) == IF ik[i] \in DecKinds \cup {"wdr"} /\ cterm # "none" /\ ctby = i THEN cs ELSE "none"

\* ---- Term carried record: an intent of the record's kind whose act key the record carries and
\* whose pairing datum equals the record's instant ----
InitCarriers == {j \in Is : ik[j] = "init" /\ phase = "live" /\ inow[j] = cat}
WdrCarriers == {j \in Is : ik[j] = "wdr" /\ cterm = "withdrawal" /\ inow[j] = ctt}
StepCarriers(s) == {j \in Is : ik[j] \in DecKinds /\ tgt[j] = s /\ ss[s] = Verb(ik[j]) /\ sat[s] = inow[j]}

\* ---- the write-ownership leg's reading (Reconciliation 20, 45 to 50) ----
LegFindsStep(s) == ss[s] # "Pending" /\ ~(s \in ccas) /\ StepCarriers(s) = {}
LegAlertsStep(s) == \E j \in StepCarriers(s) : st[j] \in Closed0
LegAlertsChain == \E j \in InitCarriers : st[j] \in Closed0
LegAlertsWdr == \E j \in WdrCarriers : st[j] \in Closed0

\* ---- the truth the leg's answers are compared with ----
FalseStep(s) == how[s] = "routed" /\ sby[s] \in Is /\ st[sby[s]] \in Closed0
FalseChain == phase = "live" /\ cmint \in Is /\ st[cmint] \in Closed0
FalseWdr == cterm = "withdrawal" /\ ctby \in Is /\ st[ctby] \in Closed0

\* ---- the chain rebuild's readings (Composition state 22, 23) ----
TermNamers == {j \in Is : st[j] = "closed" /\ osum[j] # "none"}
TermWrong == (\E j \in TermNamers : ctby # j \/ osum[j] # cs) \/ Cardinality(TermNamers) >= 2
TermAlerts == (\E j \in TermNamers : ctby # j \/ osum[j] # cs) \/ Cardinality(TermNamers) >= 2
ShapeWrong == \E j \in Is : ik[j] = "init" /\ st[j] = "closed" /\ ~osh[j]
ShapeAlerts == \E j \in Is : ik[j] = "init" /\ st[j] = "closed" /\ ~osh[j]

TypeOK ==
    /\ rule \in {"all", "m"}
    /\ m \in Slots
    /\ phase \in {"none", "live"}
    /\ sub \in 0..N
    /\ cs \in {"Pending"} \cup Decided
    /\ cat \in 0..MaxT
    /\ ctt \in 0..MaxT
    /\ cterm \in {"none", "resolution", "withdrawal"}
    /\ ctby \in 0..NI
    /\ ccas \subseteq Slots
    /\ cmint \in 0..NI
    /\ first \in {"none"} \cup Decided
    /\ ss \in [Slots -> {"Pending"} \cup Decided]
    /\ how \in [Slots -> {"none", "routed", "cascade", "oob"}]
    /\ sat \in [Slots -> 0..MaxT]
    /\ sby \in [Slots -> 0..NI]
    /\ asg \in [Slots -> {"none", "Active", "Recalled"}]
    /\ ik \in [Is -> {"-", "init", "appr", "rej", "swd", "wdr"}]
    /\ tgt \in [Is -> 0..N]
    /\ inow \in [Is -> 0..MaxT]
    /\ st \in [Is -> {"none", "live", "committed", "dead", "closed", "refused", "escalated", "abandoned"}]
    /\ trl \in [Is -> BOOLEAN]
    /\ cw \in [Is -> BOOLEAN]
    /\ tcs \in [Is -> {"-", "Pending"} \cup Decided]
    /\ cby \in [Is -> {"-", "inv", "sweep", "op"}]
    /\ osum \in [Is -> {"none"} \cup Decided]
    /\ osh \in [Is -> BOOLEAN]
    /\ nx \in 1..(NI + 1)
    /\ clk \in 0..MaxT
    /\ noob \in 0..MaxOob
    /\ nfail \in 0..MaxFail
    /\ viol \subseteq {"finding-false", "finding-missed", "alert-wrong", "term-missed", "shape-missed"}

Init ==
    /\ rule \in {"all", "m"}
    /\ m \in (IF rule = "all" THEN {N} ELSE 1..(N - 1))
    /\ phase = "none"
    /\ sub = 0
    /\ cs = "Pending"
    /\ cat = 0
    /\ ctt = 0
    /\ cterm = "none"
    /\ ctby = 0
    /\ ccas = {}
    /\ cmint = 0
    /\ first = "none"
    /\ ss = [s \in Slots |-> "Pending"]
    /\ how = [s \in Slots |-> "none"]
    /\ sat = [s \in Slots |-> 0]
    /\ sby = [s \in Slots |-> 0]
    /\ asg = [s \in Slots |-> "none"]
    /\ ik = [i \in Is |-> "-"]
    /\ tgt = [i \in Is |-> 0]
    /\ inow = [i \in Is |-> 0]
    /\ st = [i \in Is |-> "none"]
    /\ trl = [i \in Is |-> FALSE]
    /\ cw = [i \in Is |-> FALSE]
    /\ tcs = [i \in Is |-> "-"]
    /\ cby = [i \in Is |-> "-"]
    /\ osum = [i \in Is |-> "none"]
    /\ osh = [i \in Is |-> TRUE]
    /\ nx = 1
    /\ clk = 0
    /\ noob = 0
    /\ nfail = 0
    /\ viol = {}

\* ---------------------------------------------------------------------------------------
\* The state-changing actions: validate, open, commit, close (Recoverable Invocation Action
\* wiring 4).

\* The pairing datum the host injects: a fresh now (Capability requirement 19, 37, 38).
Nows == {clk + 1}

\* [Open] for an initiation (Action wiring 3): the intent lands under the initiator, keyed by
\* the chain id the host injected, carrying the now and no step or assignment id.
OpenInit(t) ==
    LET i == nx IN
    /\ i <= NI
    /\ phase = "none"
    /\ ~(\E j \in Is : ik[j] = "init" /\ st[j] = "live")
    /\ ik' = [ik EXCEPT ![i] = "init"]
    /\ inow' = [inow EXCEPT ![i] = t]
    /\ clk' = t
    /\ st' = [st EXCEPT ![i] = "live"]
    /\ nx' = i + 1
    /\ UNCHANGED <<qr, chain, steps, tgt, trl, cw, tcs, cby, osum, osh, noob, nfail, viol>>

\* [Open] for a decision (Action wiring 17 to 20): the step resolved under the chain, the
\* trailing flag computed from the chain state, the intent keyed by the decision key.
OpenDec(k, s, t) ==
    LET i == nx IN
    /\ i <= NI
    /\ phase = "live"
    /\ s <= sub
    /\ ss[s] = "Pending"
    /\ ~OpenOn(k, s)
    /\ ik' = [ik EXCEPT ![i] = k]
    /\ tgt' = [tgt EXCEPT ![i] = s]
    /\ inow' = [inow EXCEPT ![i] = t]
    /\ trl' = [trl EXCEPT ![i] = (cs # "Pending")]
    /\ clk' = t
    /\ st' = [st EXCEPT ![i] = "live"]
    /\ nx' = i + 1
    /\ UNCHANGED <<qr, chain, steps, cw, tcs, cby, osum, osh, noob, nfail, viol>>

\* [Open] for a chain withdrawal (Action wiring 44 to 46): the chain Pending ahead of the open.
OpenWdr(t) ==
    LET i == nx IN
    /\ i <= NI
    /\ phase = "live"
    /\ cs = "Pending"
    /\ ~OpenOn("wdr", 0)
    /\ ik' = [ik EXCEPT ![i] = "wdr"]
    /\ inow' = [inow EXCEPT ![i] = t]
    /\ clk' = t
    /\ st' = [st EXCEPT ![i] = "live"]
    /\ nx' = i + 1
    /\ UNCHANGED <<qr, chain, steps, tgt, trl, cw, tcs, cby, osum, osh, noob, nfail, viol>>

\* The commits. a = "committed" or "unk-done" (an unknown arm that wrote: the invocation
\* yields, the write landed).

\* The initiation transaction: the chain record, every submit and every assign, together
\* (Term initiation transaction).
CommitInit(i, a) ==
    /\ st[i] = "live"
    /\ ik[i] = "init"
    /\ phase = "none"
    /\ phase' = "live"
    /\ sub' = N
    /\ cat' = inow[i]
    /\ cmint' = i
    /\ asg' = [s \in Slots |-> "Active"]
    /\ cw' = [cw EXCEPT ![i] = TRUE]
    /\ (a = "committed" \/ nfail < MaxFail)
    /\ nfail' = IF a = "committed" THEN nfail ELSE nfail + 1
    /\ st' = [st EXCEPT ![i] = IF a = "committed" THEN "committed" ELSE "dead"]
    /\ UNCHANGED <<qr, cs, ctt, cterm, ctby, ccas, first, ss, how, sat, sby,
                   ik, tgt, inow, trl, tcs, cby, osum, osh, nx, clk, noob, viol>>

\* The decision transaction: the re-read of the chain state against the intent's trailing flag
\* (Action wiring 64, 65), the step write and its recall, and, unless trailing, the chain
\* evaluation with its cascade and the terminal summary (Term decision transaction).
CommitDec(i, a) ==
    LET s    == tgt[i]
        ss1  == [ss EXCEPT ![s] = Verb(ik[i])]
        how1 == [how EXCEPT ![s] = "routed"]
        tv1  == [t \in Slots |-> IF t = s THEN trl[i] ELSE TrlVec[t]]
        a1   == [asg EXCEPT ![s] = IF asg[s] = "Active" THEN "Recalled" ELSE asg[s]]
        q    == EvQOf(ss1, how1, tv1)
        P    == {t \in 1..sub : ss1[t] = "Pending"}
        term == ~trl[i] /\ cs = "Pending" /\ q # "Pending"
        wd   == term /\ q = "Withdrawn"
    IN
    /\ st[i] = "live"
    /\ ik[i] \in DecKinds
    /\ ss[s] = "Pending"
    /\ (cs = "Pending" \/ trl[i])
    /\ ss' = IF wd THEN [t \in Slots |-> IF t \in P THEN "Withdrawn" ELSE ss1[t]] ELSE ss1
    /\ how' = IF wd THEN [t \in Slots |-> IF t \in P THEN "cascade" ELSE how1[t]] ELSE how1
    /\ sat' = [t \in Slots |-> IF t = s \/ (wd /\ t \in P) THEN inow[i] ELSE sat[t]]
    /\ sby' = [t \in Slots |-> IF t = s \/ (wd /\ t \in P) THEN i ELSE sby[t]]
    /\ asg' = IF term THEN RecallAll(a1, P) ELSE a1
    /\ cs' = IF term THEN q ELSE cs
    /\ ctt' = IF term THEN inow[i] ELSE ctt
    /\ cterm' = IF term THEN "resolution" ELSE cterm
    /\ ctby' = IF term THEN i ELSE ctby
    /\ ccas' = IF wd THEN P ELSE ccas
    /\ first' = IF term /\ first = "none" THEN q ELSE first
    /\ tcs' = [tcs EXCEPT ![i] = cs]
    /\ cw' = [cw EXCEPT ![i] = TRUE]
    /\ (a = "committed" \/ nfail < MaxFail)
    /\ nfail' = IF a = "committed" THEN nfail ELSE nfail + 1
    /\ st' = [st EXCEPT ![i] = IF a = "committed" THEN "committed" ELSE "dead"]
    /\ UNCHANGED <<qr, phase, sub, cat, cmint, ik, tgt, inow, trl, cby, osum, osh, nx, clk, noob, viol>>

\* The withdrawal transaction: the re-read of Pending (Action wiring 66, 67), the chain
\* Withdrawn, the cascade over every still-Pending step and the terminal summary.
CommitWdr(i, a) ==
    LET P == {t \in 1..sub : ss[t] = "Pending"} IN
    /\ st[i] = "live"
    /\ ik[i] = "wdr"
    /\ cs = "Pending"
    /\ cs' = "Withdrawn"
    /\ ctt' = inow[i]
    /\ cterm' = "withdrawal"
    /\ ctby' = i
    /\ ccas' = P
    /\ first' = IF first = "none" THEN "Withdrawn" ELSE first
    /\ ss' = [t \in Slots |-> IF t \in P THEN "Withdrawn" ELSE ss[t]]
    /\ how' = [t \in Slots |-> IF t \in P THEN "cascade" ELSE how[t]]
    /\ sat' = [t \in Slots |-> IF t \in P THEN inow[i] ELSE sat[t]]
    /\ sby' = [t \in Slots |-> IF t \in P THEN i ELSE sby[t]]
    /\ asg' = RecallAll(asg, P)
    /\ tcs' = [tcs EXCEPT ![i] = cs]
    /\ cw' = [cw EXCEPT ![i] = TRUE]
    /\ (a = "committed" \/ nfail < MaxFail)
    /\ nfail' = IF a = "committed" THEN nfail ELSE nfail + 1
    /\ st' = [st EXCEPT ![i] = IF a = "committed" THEN "committed" ELSE "dead"]
    /\ UNCHANGED <<qr, phase, sub, cat, cmint, ik, tgt, inow, trl, cby, osum, osh, nx, clk, noob, viol>>

\* A pre-commit arm: a refused submit or assign, a step refusal, the re-reads' mismatches, a
\* cascade's temporal invalid-request, a storage-failure or a state-unavailable. The commit
\* writes nothing and [Refuse] lands the refusal record (Action wiring 9, 12, 22, 23, 65, 67;
\* Cascade 14; Recoverable Invocation commit 2, 3).
CommitPre(i) ==
    /\ st[i] = "live"
    /\ nfail < MaxFail
    /\ nfail' = nfail + 1
    /\ st' = [st EXCEPT ![i] = "refused"]
    /\ UNCHANGED <<qr, chain, steps, ik, tgt, inow, trl, cw, tcs, cby, osum, osh, nx, clk, noob, viol>>

\* An unknown arm that wrote nothing: the invocation yields (Action wiring 68).
CommitLost(i) ==
    /\ st[i] = "live"
    /\ nfail < MaxFail
    /\ nfail' = nfail + 1
    /\ st' = [st EXCEPT ![i] = "dead"]
    /\ UNCHANGED <<qr, chain, steps, ik, tgt, inow, trl, cw, tcs, cby, osum, osh, nx, clk, noob, viol>>

\* [Close] after a committed arm: the outcome carries the chain shape, or the terminal summary
\* where the act terminated the chain (Action wiring 14, 29, 49). It may fail, or the invocation
\* may die first: the intent stays open for the sweep (Action wiring 69; Cross-record
\* consistency 1).
Close(i, o) ==
    /\ st[i] = "committed"
    /\ \/ /\ o = "ok"
          /\ st' = [st EXCEPT ![i] = "closed"]
          /\ cby' = [cby EXCEPT ![i] = "inv"]
          /\ osum' = [osum EXCEPT ![i] = SumFor(i)]
          /\ UNCHANGED nfail
       \/ /\ o = "fail"
          /\ nfail < MaxFail
          /\ nfail' = nfail + 1
          /\ st' = [st EXCEPT ![i] = "dead"]
          /\ UNCHANGED <<cby, osum>>
    /\ UNCHANGED <<qr, chain, steps, ik, tgt, inow, trl, cw, tcs, osh, nx, clk, noob, viol>>

\* ---------------------------------------------------------------------------------------
\* Recoverable Invocation's sweep and the operator's resolve, as contracts.

\* The sweep on an intent whose invocation is gone: the act probe answers committed where
\* exactly one record matches, and the sweep writes the recovered outcome, its terminal summary
\* read off the chain record (Term decision probe, withdrawal probe).
SweepClose(i) ==
    /\ st[i] = "dead"
    /\ Cardinality(Matches(i)) = 1
    /\ st' = [st EXCEPT ![i] = "closed"]
    /\ cby' = [cby EXCEPT ![i] = "sweep"]
    /\ osum' = [osum EXCEPT ![i] = SumFor(i)]
    /\ UNCHANGED <<qr, chain, steps, ik, tgt, inow, trl, cw, tcs, osh, nx, clk, noob, nfail, viol>>

\* Otherwise it escalates.
SweepEscalate(i) ==
    /\ st[i] = "dead"
    /\ Cardinality(Matches(i)) # 1
    /\ st' = [st EXCEPT ![i] = "escalated"]
    /\ UNCHANGED <<qr, chain, steps, ik, tgt, inow, trl, cw, tcs, cby, osum, osh, nx, clk, noob, nfail, viol>>

\* The operator's resolve: an abandonment of a dead or escalated intent.
OpAbandon(i) ==
    /\ st[i] \in {"dead", "escalated"}
    /\ st' = [st EXCEPT ![i] = "abandoned"]
    /\ cby' = [cby EXCEPT ![i] = "op"]
    /\ UNCHANGED <<qr, chain, steps, ik, tgt, inow, trl, cw, tcs, osum, osh, nx, clk, noob, nfail, viol>>

\* The operator's resolve: an outcome carrying the data the records hold ("faithful") or data they
\* do not ("wrong": a terminal summary the chain record does not carry, or a chain shape it does
\* not hold), superseding an abandonment where one stands.
OpOutcome(i, x) ==
    /\ st[i] \in {"dead", "escalated", "abandoned"}
    /\ st' = [st EXCEPT ![i] = "closed"]
    /\ cby' = [cby EXCEPT ![i] = "op"]
    /\ osum' = [osum EXCEPT ![i] = IF x = "faithful" \/ ik[i] = "init" THEN SumFor(i)
                                    ELSE IF SumFor(i) = "Approved" THEN "Rejected" ELSE "Approved"]
    /\ osh' = [osh EXCEPT ![i] = (x = "faithful" \/ ik[i] # "init")]
    /\ UNCHANGED <<qr, chain, steps, ik, tgt, inow, trl, cw, tcs, nx, clk, noob, nfail, viol>>

\* ---------------------------------------------------------------------------------------
\* A step decision written around the composition, with no intent: an out-of-band transition.
OutOfBand(s, x) ==
    /\ noob < MaxOob
    /\ phase = "live"
    /\ s <= sub
    /\ ss[s] = "Pending"
    /\ ss' = [ss EXCEPT ![s] = x]
    /\ how' = [how EXCEPT ![s] = "oob"]
    /\ sat' = [sat EXCEPT ![s] = clk + 1]
    /\ sby' = [sby EXCEPT ![s] = 0]
    /\ clk' = clk + 1
    /\ noob' = noob + 1
    /\ UNCHANGED <<qr, chain, asg, inv, nx, nfail, viol>>

\* The write-ownership leg (Reconciliation 20, 45 to 50): every decided step of the step list,
\* the chain record and its terminal read against the intents, on an answered read.
LegRun ==
    /\ viol' = viol
         \cup (IF \E s \in 1..sub : LegFindsStep(s) /\ how[s] # "oob" THEN {"finding-false"} ELSE {})
         \cup (IF \E s \in 1..sub : ~LegFindsStep(s) /\ how[s] = "oob" THEN {"finding-missed"} ELSE {})
         \cup (IF \/ \E s \in 1..sub : LegAlertsStep(s) # FalseStep(s)
                  \/ LegAlertsChain # FalseChain
                  \/ LegAlertsWdr # FalseWdr
               THEN {"alert-wrong"} ELSE {})
    /\ UNCHANGED <<qr, chain, steps, inv, nx, clk, noob, nfail>>

\* The chain rebuild (Composition state 22, 23): the terminal-data alert and the shape alert.
Rebuild ==
    /\ viol' = viol
         \cup (IF TermWrong /\ ~TermAlerts THEN {"term-missed"} ELSE {})
         \cup (IF ShapeWrong /\ ~ShapeAlerts THEN {"shape-missed"} ELSE {})
    /\ UNCHANGED <<qr, chain, steps, inv, nx, clk, noob, nfail>>

\* -buggy-partial-cascade: a cascade withdraw meets the temporal invalid-request and the commit
\* proceeds without it, the step left Pending on a Withdrawn chain.
WdrResidue(i, r) ==
    LET P == {t \in 1..sub : ss[t] = "Pending"} \ {r} IN
    /\ st[i] = "live"
    /\ ik[i] = "wdr"
    /\ cs = "Pending"
    /\ r \in 1..sub
    /\ ss[r] = "Pending"
    /\ nfail < MaxFail
    /\ nfail' = nfail + 1
    /\ cs' = "Withdrawn"
    /\ ctt' = inow[i]
    /\ cterm' = "withdrawal"
    /\ ctby' = i
    /\ ccas' = P
    /\ first' = IF first = "none" THEN "Withdrawn" ELSE first
    /\ ss' = [t \in Slots |-> IF t \in P THEN "Withdrawn" ELSE ss[t]]
    /\ how' = [t \in Slots |-> IF t \in P THEN "cascade" ELSE how[t]]
    /\ sat' = [t \in Slots |-> IF t \in P THEN inow[i] ELSE sat[t]]
    /\ sby' = [t \in Slots |-> IF t \in P THEN i ELSE sby[t]]
    /\ asg' = RecallAll(asg, P \cup {r})
    /\ tcs' = [tcs EXCEPT ![i] = cs]
    /\ cw' = [cw EXCEPT ![i] = TRUE]
    /\ st' = [st EXCEPT ![i] = "committed"]
    /\ UNCHANGED <<qr, phase, sub, cat, cmint, ik, tgt, inow, trl, cby, osum, osh, nx, clk, noob, viol>>

Next ==
    \/ \E t \in Nows : OpenInit(t)
    \/ \E k \in DecKinds, s \in Slots, t \in Nows : OpenDec(k, s, t)
    \/ \E t \in Nows : OpenWdr(t)
    \/ \E i \in Is, a \in {"committed", "unk-done"} : CommitInit(i, a)
    \/ \E i \in Is, a \in {"committed", "unk-done"} : CommitDec(i, a)
    \/ \E i \in Is, a \in {"committed", "unk-done"} : CommitWdr(i, a)
    \/ \E i \in Is : CommitPre(i)
    \/ \E i \in Is, r \in Slots : WdrResidue(i, r)
    \/ \E i \in Is : CommitLost(i)
    \/ \E i \in Is, o \in {"ok", "fail"} : Close(i, o)
    \/ \E i \in Is : SweepClose(i)
    \/ \E i \in Is : SweepEscalate(i)
    \/ \E i \in Is : OpAbandon(i)
    \/ \E i \in Is, x \in {"faithful", "wrong"} : OpOutcome(i, x)
    \/ \E s \in Slots, x \in Decided : OutOfBand(s, x)
    \/ LegRun
    \/ Rebuild
Spec == Init /\ [][Next]_vars

\* ---- the invariants ----
Quiescent == phase = "live" /\ ~(\E j \in Is : st[j] \in OpenSt \cup {"escalated"})

\* Invariant 1.1: a quiescent chain has its full step list.
Inv1_1 == Quiescent => sub = N

\* Invariant 2.1, 2.2: quorum determinism, split by terminal path.
Inv2_1 == cterm = "resolution" => cs = QOf(ss, how, TrlVec)
Inv2_2 == cterm = "withdrawal" => PreQ = "Pending"

\* Bypass resistance: an Approved chain carries the quorum's routed, non-trailing approvals.
RoutedApprovals == Cardinality({s \in Slots : ss[s] = "Approved" /\ how[s] = "routed" /\ ~TrlVec[s]})
Bypass == cs = "Approved" => RoutedApprovals >= (IF rule = "all" THEN N ELSE m)

\* Invariant 4.1, 4.2: assignment coverage at quiescence, out-of-band decisions aside.
Inv4_1 == \A s \in Slots :
    (Quiescent /\ s <= sub /\ cs = "Pending" /\ ss[s] = "Pending") => asg[s] = "Active"
Inv4_2 == \A s \in Slots :
    (Quiescent /\ s <= sub /\ how[s] # "oob" /\ (ss[s] # "Pending" \/ cs # "Pending")) => asg[s] # "Active"

\* Invariant 7.1: a terminal chain's state never changes.
Inv7_1 == first # "none" => cs = first

\* Cascade 2, Cascade 14: a Withdrawn chain carries no Pending step.
No_withdrawn_residue == cs = "Withdrawn" => \A s \in 1..sub : ss[s] # "Pending"

\* Action wiring 64, 65: a decision commits only where its intent's trailing flag reads the
\* chain state at the commit.
Trailing_matches == \A j \in Is : (ik[j] \in DecKinds /\ cw[j]) => (trl[j] = (tcs[j] # "Pending"))

\* Invariant 5.1, Cross-record consistency 1: an invocation whose commit wrote stands open or
\* beside a closing, never a refusal.
Owed_outcome ==
    \A j \in Is : cw[j] => st[j] \in {"committed", "dead", "closed", "escalated", "abandoned"}

\* Term initiation probe, decision probe, withdrawal probe: an outcome the invocation or the
\* sweep wrote names the record its pairing datum finds. An operator's is detected.
Outcome_names_record ==
    \A j \in Is : (st[j] = "closed" /\ cby[j] # "op") => Matches(j) # {}

\* Composition state 6, 7, Check 7.1: an outcome the invocation or the sweep wrote carries the
\* chain record's terminal summary where its act terminated the chain, and none otherwise.
Terminal_outcome_matches ==
    \A j \in Is : (st[j] = "closed" /\ cby[j] # "op" /\ ik[j] \in DecKinds \cup {"wdr"})
                     => osum[j] = SumFor(j)

\* Composition state 22, 23: the rebuild's alerts.
Terminal_alert == ~("term-missed" \in viol)
Shape_alert == ~("shape-missed" \in viol)

\* Capability requirement 37, 38: a record carries one intent at most, and the sweep answers
\* committed only for the intent whose own commit wrote the record.
Pairing_unique ==
    /\ \A j \in Is : (st[j] = "closed" /\ cby[j] = "sweep") => Writer(j) = j
    /\ Cardinality(InitCarriers) <= 1
    /\ Cardinality(WdrCarriers) <= 1
    /\ \A s \in Slots : Cardinality(StepCarriers(s)) <= 1

\* Reconciliation 20: a finding for every out-of-band transition, and for no other step.
Write_ownership_finding == ~("finding-false" \in viol) /\ ~("finding-missed" \in viol)

\* Reconciliation 50: an alert for exactly the records whose own intent an abandonment or a
\* refusal closed.
False_closing_alert == ~("alert-wrong" \in viol)

====
