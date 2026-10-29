---- MODULE multi-party-approval-probe-shortterminal ----
\* EXPECT: violation — reachability probe: no short chain driven terminal is ever closed by the initiation-failed record.
\* Grace Commons — Multi-Party Approval, the chain and its quorum.
\* Spec-level formal sibling of compositions/multi-party-approval.md. Derived validator;
\* the English spec is the single source of truth. On any disagreement, diagnose per the
\* entry *The conflict protocol* in pressure-testing.md.
\*
\* ONE CHAIN of N approver slots, under a quorum rule the initial state chooses: [All Of N],
\* or [M Of N] with every valid quorum count (Term valid quorum counts; [One Of N] is M = 1).
\* Its initiation lands whole, or stops at a refused submit (disposition a) or a refused
\* initiation event (disposition c) and runs the initiation recovery inside the invocation,
\* whose initiation-failed record lands or is refused, the chain then standing quarantined
\* for the initiation leg (Action wiring 9, 15; Reconciliation 8 through 16).
\*
\* ONE TRANSACTION PER ACTION (Execution Contract Database 1, Capability requirement 26).
\* Every write one action makes, its constituents' included, commits together, so each
\* action below is one step and a reader sees all of it or none. A storage failure commits
\* nothing and is not a step (Action wiring 23 answers it). With OneTxn = FALSE a refused
\* submit's storage failure may leave the steps before it committed with no recovery: the
\* reading the 2026-10-20 turn retired (-buggy-split).
\*
\* THE CONSTITUENTS, as contracts. Approval Step: a step decides once, from Pending, by its
\* approver (approve, reject) or its submitter (withdraw), and refuses a second decision
\* not-pending; a cascade withdrawal may be refused with the temporal invalid-request, a
\* transient arm cured by a later reading. Assignment: recall answers ok on an Active
\* assignment and not-active on a Recalled one. Audit Trail: the outcome, cascade, resolution
\* and withdrawal events land with their action; its refusals are not modelled but the one
\* the recovery reads, the initiation-failed record's.
\*
\* THE ACTIONS. [Initiate Chain] (whole, disposition a, disposition c); a decision by an
\* approver or the initiator, trailing where the chain is terminal (Action wiring 18, 19,
\* 31), evaluating otherwise (Action wiring 30, 34 through 39) and cascading on a terminal
\* answer; [Withdraw Chain]; a decision written around the composition (an out-of-band
\* transition, which Composes 11 forbids and Wiring decision 6 and 7 must keep off the
\* quorum); the sweep's retry of a call a partial flag names (Reconciliation 26, 30); the
\* initiation leg (Reconciliation 8 through 16). A cascade recalls every still-Pending step's
\* assignment and, on a Withdrawn chain, withdraws each, any subset of the withdrawals failing
\* transiently and named by the partial flag (Cascade 1, 2, 8, 9).
\*
\* WHAT THIS MODEL CHECKS
\*   Inv1_1   a quiescent chain the recovery did not close has its full step list
\*            (Invariant 1.1).
\*   Inv2_1   a resolution-terminated chain's state is the quorum rule's answer on its
\*            routed vector (Invariant 2.1, Check 2.1).
\*   Inv2_2   the quorum rule answers Pending on a withdrawal-terminated chain's
\*            pre-withdrawal vector (Invariant 2.2, Check 2.2).
\*   Bypass   an Approved chain carries the quorum's routed, non-trailing approvals: the
\*            bypass resistance the page claims under Invariant 1 and 2.
\*   Inv4_1   at quiescence an open step carries its Active assignment (Invariant 4.1).
\*   Inv4_2   at quiescence a settled step carries none, out-of-band decisions aside
\*            (Invariant 4.2): a write around the composition breaks Composes 11, and the
\*            model asks of it only that it never moves the quorum.
\*   Inv7_1   a terminal chain's state never changes (Invariant 7.1).
\*   NoStuck  every call a partial flag names closes with a closure mark (Reconciliation
\*            30, Term closure mark, Check 5.4).
\*
\* THE RULES, as constants, each TRUE here; each twin is this module with one turned FALSE:
\*   NIsApproverSet   N is the approver set's count (Term routed vector)            -buggy-steplist
\*   NoTrailingCount  no trailing decision counts (Term routed vector)              -buggy-trailing
\*   SupersedeAny     a not-pending retry closes superseded (Term closure mark)     -buggy-closure
\*   OOBNotCounted    an out-of-band transition counts as Pending (Wiring decision 6, 7) -buggy-oob
\*   OneTxn           an action's writes commit together (Execution Contract Database 1) -buggy-split
\*   ShortRecovered   a short chain driven terminal is closed by the initiation-failed
\*                    record (Reconciliation 10, 12, 13, 15; this model's finding)  -buggy-shortshape
\*   RecallCascade    a cascade recalls every still-Pending step's assignment (Cascade 1) -buggy-norecall
\*   StaffAll         a submitted initiation assigns every step (Action wiring 10, 11) -buggy-unstaffed
\*
\* NOT MODELLED, each with its reason: time, the horizon and aged chains (Reconciliation 5,
\* 17, 26, 32 and Term aged chains are a rule's condition, not an interleaving; the model has
\* no clock); the audit write's refusals at an intent or an outcome (Audit arm 1 through 16
\* land each on the caller, and Recoverable Invocation-style re-emission is the transition
\* leg's, a terminal chain's missing terminal event included (Reconciliation 35)); assign's refusals
\* (disposition b, whose chain the recovery closes as it closes disposition c's); the derived
\* indexes (a lost entry is rebuilt before a rule reads it, Composition state 21); [Read Chain].

EXTENDS Naturals, FiniteSets

CONSTANTS N, NIsApproverSet, NoTrailingCount, SupersedeAny, OOBNotCounted, OneTxn, ShortRecovered,
          RecallCascade, StaffAll

Slots   == 1..N
Decided == {"Approved", "Rejected", "Withdrawn"}

\* rule, m: the quorum rule and its count. phase: none (not initiated), live (its chain-shape
\* event landed), quarantined (a chain record with no chain-shape event), closed (its
\* initiation-failed record landed). sub: the step list's length. cs: the chain state. term:
\* the chain's terminal event. first: the first terminal state, for Inv7_1. Per slot: st the
\* step's state; how its decision (routed, a cascade's, out-of-band); trl its trailing flag;
\* asg its assignment; part a partial flag naming its cascade withdrawal; clo the closure.
VARIABLES rule, m, phase, sub, cs, term, first, st, how, trl, asg, part, clo
vars == <<rule, m, phase, sub, cs, term, first, st, how, trl, asg, part, clo>>

\* ---- the routed vector and the quorum rule (Term routed vector, Wiring decision 1 to 7) ----
Cnt(h, t) == \/ (h = "routed" /\ (NoTrailingCount => ~t))
             \/ h = "cascade"
             \/ (h = "oob" /\ ~OOBNotCounted)

CntIn(s, h, t, k, x) == Cardinality({i \in Slots : i <= k /\ s[i] = x /\ Cnt(h[i], t[i])})

NNof(k) == IF NIsApproverSet THEN N ELSE k

Met(a, nn)     == IF rule = "all" THEN a = nn ELSE a >= m
Lost(r, w, nn) == IF rule = "all" THEN r + w >= 1 ELSE nn < r + w + m

Quorum(a, r, w, nn) ==
    IF Met(a, nn) THEN "Approved"
    ELSE IF Lost(r, w, nn) /\ r > 0 THEN "Rejected"
    ELSE IF Lost(r, w, nn) THEN "Withdrawn"
    ELSE "Pending"

QOf(s, h, t, k) ==
    Quorum(CntIn(s, h, t, k, "Approved"), CntIn(s, h, t, k, "Rejected"),
           CntIn(s, h, t, k, "Withdrawn"), NNof(k))

\* The pre-withdrawal vector: cascade withdrawals (a retry's included) and superseded closures
\* counted back as Pending (Term pre-withdrawal vector).
PwCnt(i) == Cnt(how[i], trl[i]) /\ how[i] # "cascade" /\ clo[i] # "superseded"
PwIn(x)  == Cardinality({i \in Slots : i <= sub /\ st[i] = x /\ PwCnt(i)})
PreQ     == Quorum(PwIn("Approved"), PwIn("Rejected"), PwIn("Withdrawn"), NNof(sub))

\* ---- the cascade (Cascade 1, 2, 3, 7, 8, 9) ----
Pend(s, k)        == {i \in 1..k : s[i] = "Pending"}
RecallAll(a, P)   == [i \in Slots |-> IF RecallCascade /\ i \in P /\ a[i] = "Active" THEN "Recalled" ELSE a[i]]
WdSt(s, P, F)     == [i \in Slots |-> IF i \in P \ F THEN "Withdrawn" ELSE s[i]]
WdHow(h, P, F)    == [i \in Slots |-> IF i \in P \ F THEN "cascade" ELSE h[i]]
WdPart(p, F)      == [i \in Slots |-> IF i \in F THEN TRUE ELSE p[i]]
FirstOf(q)        == IF first = "none" THEN q ELSE first

TypeOK ==
    /\ rule \in {"all", "m"}
    /\ m \in Slots
    /\ phase \in {"none", "live", "quarantined", "closed"}
    /\ sub \in 0..N
    /\ cs \in {"Pending"} \cup Decided
    /\ term \in {"none", "resolution", "withdrawal"}
    /\ first \in {"none"} \cup Decided
    /\ st \in [Slots -> {"Pending"} \cup Decided]
    /\ how \in [Slots -> {"none", "routed", "cascade", "oob"}]
    /\ trl \in [Slots -> BOOLEAN]
    /\ asg \in [Slots -> {"none", "Active", "Recalled"}]
    /\ part \in [Slots -> BOOLEAN]
    /\ clo \in [Slots -> {"none", "retried", "superseded", "stuck"}]

Init ==
    /\ rule \in {"all", "m"}
    /\ m \in (IF rule = "all" THEN {N} ELSE Slots)
    /\ phase = "none"
    /\ sub = 0
    /\ cs = "Pending"
    /\ term = "none"
    /\ first = "none"
    /\ st = [i \in Slots |-> "Pending"]
    /\ how = [i \in Slots |-> "none"]
    /\ trl = [i \in Slots |-> FALSE]
    /\ asg = [i \in Slots |-> "none"]
    /\ part = [i \in Slots |-> FALSE]
    /\ clo = [i \in Slots |-> "none"]

\* ---- [Initiate Chain] ----
\* Lands whole: every submit and assign answered, the initiation event landed (Action wiring 16).
InitWhole ==
    /\ phase = "none"
    /\ phase' = "live"
    /\ sub' = N
    /\ asg' = [i \in Slots |-> IF StaffAll \/ i < N THEN "Active" ELSE "none"]
    /\ UNCHANGED <<rule, m, cs, term, first, st, how, trl, part, clo>>

\* Submit k refused invalid-request: the steps before it stand, unassigned (assigns follow every
\* submit, Action wiring 10), and the initiation recovery runs inside the invocation carrying
\* disposition a (Action wiring 9). Its evaluation (Reconciliation 9) finds no decision; on an
\* open vector it quarantines the chain (11) and records the initiation-failed record (12),
\* which lands, withdrawing the chain and cascading (13, 15), or is refused.
InitA(k) ==
    /\ phase = "none"
    /\ sub' = k - 1
    /\ LET q == QOf(st, how, trl, k - 1)
           P == 1..(k - 1)
       IN \/ /\ q # "Pending"
             /\ q \in {"Approved", "Rejected"}
             /\ phase' = "live"
             /\ cs' = q
             /\ term' = "resolution"
             /\ first' = q
             /\ UNCHANGED <<st, how, part>>
          \/ /\ q = "Withdrawn"
             /\ phase' = "live"
             /\ cs' = q
             /\ term' = "resolution"
             /\ first' = q
             /\ \E F \in SUBSET P : /\ st' = WdSt(st, P, F)
                                    /\ how' = WdHow(how, P, F)
                                    /\ part' = WdPart(part, F)
          \/ /\ q = "Pending"
             /\ phase' = "closed"
             /\ cs' = "Withdrawn"
             /\ term' = "withdrawal"
             /\ first' = "Withdrawn"
             /\ \E F \in SUBSET P : /\ st' = WdSt(st, P, F)
                                    /\ how' = WdHow(how, P, F)
                                    /\ part' = WdPart(part, F)
          \/ /\ q = "Pending"
             /\ phase' = "quarantined"
             /\ UNCHANGED <<cs, term, first, st, how, part>>
    /\ UNCHANGED <<rule, m, trl, asg, clo>>

\* The initiation event refused: every step submitted and assigned, the recovery inside the
\* invocation carrying disposition c (Action wiring 15), as InitA on the full list.
InitC ==
    /\ phase = "none"
    /\ sub' = N
    /\ \/ /\ phase' = "closed"
          /\ cs' = "Withdrawn"
          /\ term' = "withdrawal"
          /\ first' = "Withdrawn"
          /\ asg' = RecallAll([i \in Slots |-> "Active"], Slots)
          /\ \E F \in SUBSET Slots : /\ st' = WdSt(st, Slots, F)
                                     /\ how' = WdHow(how, Slots, F)
                                     /\ part' = WdPart(part, F)
       \/ /\ phase' = "quarantined"
          /\ asg' = [i \in Slots |-> "Active"]
          /\ UNCHANGED <<cs, term, first, st, how, part>>
    /\ UNCHANGED <<rule, m, trl, clo>>

\* -buggy-split: a submit's storage failure leaves the steps before it committed and runs no
\* recovery, the chain standing as initiated.
InitSplit(k) ==
    /\ ~OneTxn
    /\ phase = "none"
    /\ phase' = "live"
    /\ sub' = k - 1
    /\ UNCHANGED <<rule, m, cs, term, first, st, how, trl, asg, part, clo>>

\* ---- a decision through the composition ----
\* x = Approved or Rejected by the step's approver, Withdrawn by the initiator ([Withdraw
\* Step]). Trailing where the chain is terminal: no evaluation, no chain write (Action wiring
\* 18, 19, 31). Otherwise the evaluation (30, 34, 35) and, on a terminal answer, the cascade
\* (37) and the resolution event (38). The decision recalls its own assignment (24, 26).
Decide(i, x) ==
    /\ phase \in {"live", "quarantined", "closed"}
    /\ i <= sub
    /\ st[i] = "Pending"
    /\ LET t  == cs # "Pending"
           s1 == [st EXCEPT ![i] = x]
           h1 == [how EXCEPT ![i] = "routed"]
           t1 == [trl EXCEPT ![i] = t]
           a1 == [asg EXCEPT ![i] = IF asg[i] = "Active" THEN "Recalled" ELSE asg[i]]
           q  == QOf(s1, h1, t1, sub)
           P  == Pend(s1, sub)
       IN \/ /\ (t \/ q = "Pending")
             /\ st' = s1
             /\ how' = h1
             /\ trl' = t1
             /\ asg' = a1
             /\ UNCHANGED <<cs, term, first, part>>
          \/ /\ ~t
             /\ q \in {"Approved", "Rejected"}
             /\ st' = s1
             /\ how' = h1
             /\ trl' = t1
             /\ asg' = RecallAll(a1, P)
             /\ cs' = q
             /\ term' = "resolution"
             /\ first' = FirstOf(q)
             /\ UNCHANGED part
          \/ /\ ~t
             /\ q = "Withdrawn"
             /\ trl' = t1
             /\ asg' = RecallAll(a1, P)
             /\ cs' = "Withdrawn"
             /\ term' = "resolution"
             /\ first' = FirstOf("Withdrawn")
             /\ \E F \in SUBSET P : /\ st' = WdSt(s1, P, F)
                                    /\ how' = WdHow(h1, P, F)
                                    /\ part' = WdPart(part, F)
    /\ UNCHANGED <<rule, m, phase, sub, clo>>

\* ---- [Withdraw Chain] on a Pending chain (Action wiring 44 through 50) ----
WithdrawChain ==
    /\ phase \in {"live", "quarantined"}
    /\ cs = "Pending"
    /\ cs' = "Withdrawn"
    /\ term' = "withdrawal"
    /\ first' = FirstOf("Withdrawn")
    /\ LET P == Pend(st, sub)
       IN /\ asg' = RecallAll(asg, P)
          /\ \E F \in SUBSET P : /\ st' = WdSt(st, P, F)
                                 /\ how' = WdHow(how, P, F)
                                 /\ part' = WdPart(part, F)
    /\ UNCHANGED <<rule, m, phase, sub, trl, clo>>

\* ---- a step decision written around the composition (an out-of-band transition) ----
OutOfBand(i, x) ==
    /\ phase # "none"
    /\ i <= sub
    /\ st[i] = "Pending"
    /\ st' = [st EXCEPT ![i] = x]
    /\ how' = [how EXCEPT ![i] = "oob"]
    /\ UNCHANGED <<rule, m, phase, sub, cs, term, first, trl, asg, part, clo>>

\* ---- the sweep's retry of a call a partial flag names (Reconciliation 26, 30) ----
\* The withdrawal lands under a later reading (closure mark retried), or meets a step already
\* decided: not-pending, closed superseded (Term closure mark; Cascade 10's in-cascade form).
\* With SupersedeAny = FALSE only a step its approver decided closes so (the closure mark as
\* the page had it); a step the initiator withdrew has no mark, and the call stays open.
SweepRetry(i) ==
    /\ part[i]
    /\ clo[i] = "none"
    /\ \/ /\ st[i] = "Pending"
          /\ st' = [st EXCEPT ![i] = "Withdrawn"]
          /\ how' = [how EXCEPT ![i] = "cascade"]
          /\ clo' = [clo EXCEPT ![i] = "retried"]
       \/ /\ st[i] # "Pending"
          /\ clo' = [clo EXCEPT ![i] = IF SupersedeAny \/ st[i] \in {"Approved", "Rejected"}
                                       THEN "superseded" ELSE "stuck"]
          /\ UNCHANGED <<st, how>>
    /\ UNCHANGED <<rule, m, phase, sub, cs, term, first, trl, asg, part>>

\* ---- the initiation leg on a quarantined chain (Reconciliation 8 through 16) ----
\* A chain its approvers or its initiator drove terminal records its chain-shape event:
\* the initiation event, disposition d, where its step list is full (Reconciliation 10); the
\* initiation-failed record where it is short, closing the chain without withdrawing it
\* (Reconciliation 12, 13, 15 as cured). With ShortRecovered = FALSE every terminal chain
\* takes the initiation event, as the page had it. A Pending chain takes the initiation-failed
\* record (12), withdrawn and cascaded (13, 15). A refused record is a stutter here.
SweepRecover ==
    /\ phase = "quarantined"
    /\ \/ /\ cs # "Pending"
          /\ (sub = N \/ ~ShortRecovered)
          /\ phase' = "live"
          /\ UNCHANGED <<cs, term, first, st, how, asg, part>>
       \/ /\ cs # "Pending"
          /\ sub < N
          /\ ShortRecovered
          /\ phase' = "closed"
          /\ UNCHANGED <<cs, term, first, st, how, asg, part>>
       \/ /\ cs = "Pending"
          /\ phase' = "closed"
          /\ cs' = "Withdrawn"
          /\ term' = "withdrawal"
          /\ first' = FirstOf("Withdrawn")
          /\ LET P == Pend(st, sub)
             IN /\ asg' = RecallAll(asg, P)
                /\ \E F \in SUBSET P : /\ st' = WdSt(st, P, F)
                                       /\ how' = WdHow(how, P, F)
                                       /\ part' = WdPart(part, F)
    /\ UNCHANGED <<rule, m, sub, trl, clo>>

Next ==
    \/ InitWhole
    \/ \E k \in Slots : InitA(k)
    \/ InitC
    \/ \E k \in Slots : InitSplit(k)
    \/ \E i \in Slots, x \in Decided : Decide(i, x)
    \/ WithdrawChain
    \/ \E i \in Slots, x \in Decided : OutOfBand(i, x)
    \/ \E i \in Slots : SweepRetry(i)
    \/ SweepRecover

Spec == Init /\ [][Next]_vars

\* ---- the invariants ----
Quiescent ==
    /\ phase \in {"live", "closed"}
    /\ \A i \in Slots : (part[i] => clo[i] \in {"retried", "superseded"})

Inv1_1 == ((Quiescent /\ phase = "live") => sub = N)

Inv2_1 == (term = "resolution" => cs = QOf(st, how, trl, sub))

Inv2_2 == (term = "withdrawal" => PreQ = "Pending")

RoutedApprovals == Cardinality({i \in Slots : i <= sub /\ st[i] = "Approved" /\ how[i] = "routed" /\ ~trl[i]})
Bypass == (cs = "Approved" => RoutedApprovals >= (IF rule = "all" THEN N ELSE m))

Inv4_1 == \A i \in Slots :
    ((Quiescent /\ i <= sub /\ cs = "Pending" /\ st[i] = "Pending") => asg[i] = "Active")

Inv4_2 == \A i \in Slots :
    ((Quiescent /\ i <= sub /\ how[i] # "oob" /\ (st[i] # "Pending" \/ cs # "Pending")) => asg[i] # "Active")

Inv7_1 == (first # "none" => cs = first)

NoStuck == \A i \in Slots : clo[i] # "stuck"

\* ---- reachability probes (each a deliberate falsehood the checker must reject) ----
Probe_NoResidue        == \A i \in Slots : ~part[i]
Probe_NoTrailing       == \A i \in Slots : ~trl[i]
Probe_NoSuperseded     == \A i \in Slots : clo[i] # "superseded"
Probe_NoRecoveryClosed == phase # "closed"
Probe_NoShortTerminal  == ~(phase = "closed" /\ term = "resolution")
Probe_NoApproved       == cs # "Approved"
Probe_NoOutOfBand      == \A i \in Slots : how[i] # "oob"

====
