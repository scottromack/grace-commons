---- MODULE actor-suspension ----
\* Grace Commons — Actor Suspension, the cascade, its resume and sweep, and the miss rule.
\* Spec-level formal sibling of compositions/actor-suspension.md. Derived validator;
\* the English spec is the single source of truth. On any disagreement, diagnose per the
\* entry *The conflict protocol* in pressure-testing.md.
\*
\* ONE ACTOR holding a planned grant g and a planned credential c (the credential arm
\* composed), and one grant x the issuance layer may issue later (a post-snapshot member,
\* Invariant 1.12). Up to two suspension cascades, a reinstatement between them.
\*
\* ONE TRANSACTION PER ACTION (Execution Contract Database 1, Capability requirement 47).
\* Every write one action makes, its constituents' and the substrate's included, commits
\* together, so each action below is one step. A constituent's storage failure or
\* invalid-request commits nothing and is not a step (Action wiring 90; Primitive policy 11,
\* the retired Action wiring 35). An outcome Audit Trail refuses (Audit arm 30's invalid-request
\* below the retention step) stops the act at its outcome: the intent and the revocations
\* stand, the actor stands suspending (Action wiring 45; Invariant 1.5), and a resume
\* (Action wiring 8, 56 through 63) or the sweep (Reconciliation 2 through 26) completes it.
\* With StandOnStop = FALSE a stop undoes the revocations it made: the rollback wiring the
\* 2026-08-29 turn retired (-buggy-rollback).
\*
\* THE INDEX, outside every action's transaction (Composition state 18). An act's entries
\* are written after its commit (Action wiring 20, 52, 85), in any order, or lost; the sweep
\* indexes every event above the high-water mark and advances the mark to the top of what it
\* read (Reconciliation 4, 6, 7). A reader resolves an absent key by the tail read above the
\* mark (Composition state 20 through 29, 54) and takes the trail's answer over an entry
\* only where it stands later in the log (Composition state 27). Events at or below the mark
\* may age out, the audit horizon destroying an intent's plan (Term aged-out open cascade).
\*
\* THE CONSTITUENTS, as contracts. Permissions, Session and Credential revoke a member
\* standing active, and a revoked member is terminal (Composes 24, Atomic writes 3); a benign
\* terminal answer closes nothing new. Audit Trail appends each record with its action.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv1_1        a suspended actor holds no planned member active (Invariant 1.1 to 1.3,
\*                 Check 1.1 to 1.3).
\*   GateSafe      a reader never answers active for an actor the trail holds suspending or
\*                 suspended: what the issuance gate refuses on (Capability requirement 40
\*                 to 42; Composition state 20 through 29, 54).
\*   OutcomeHonest an outcome without the plan-unavailable marker names its intent's whole
\*                 plan, closed or unresolved (Invariant 2.2 to 2.5, 2.8; Wiring decision 8;
\*                 Reconciliation 25, 26).
\*   NoUnrevoke    a revoked member is never active again (Composes 24, Wiring decision 2).
\*   OneOutcome    one outcome per invocation id (Identity 15, Invariant 1.10).
\*
\* THE RULES, as constants, each TRUE here; each twin is this module with one turned FALSE:
\*   StandOnStop    a stopped cascade's revocations stand (Wiring decision 2, 3)     -buggy-rollback
\*   LiveCredEnds   an invalid-request from Credential ends the act (Action wiring 35
\*                  retired to Primitive policy 11)                                  -buggy-unresolved
\*   NoSuspIntent   an absent key reads active only with no suspension intent above
\*                  the mark (Composition state 29, 54)                             -buggy-absentactive
\*   AgedSnapshot   a resume of an aged-out cascade snapshots the actor's active
\*                  members and marks its outcome (Reconciliation 25, 26)           -buggy-agedresume
\*   OrderedIndex   no entry is written over one whose event stands later in the
\*                  log (Composition state 55)                                       -buggy-unordered
\*
\* NOT MODELLED: the boundary predicate, the credential checks and attribution (Invariant
\* 5), the plan cap, the completion window's arithmetic, the suspension log, not-known
\* members, and the outcome's refusal by a resume or the sweep (each completes).

EXTENDS Naturals, FiniteSets

CONSTANTS StandOnStop, LiveCredEnds, NoSuspIntent, AgedSnapshot, OrderedIndex

M == {"g", "c", "x"}
Planned == {"g", "c"}
MaxInv == 2
MaxLen == 7
Pos == 1..MaxLen
Kinds == {"none", "intent", "resumeIntent", "recoveryIntent", "outcome", "reinstated"}
States == {"absent", "active", "suspending", "suspended"}

Nil == [kind |-> "none", inv |-> 0, plan |-> {}, revoked |-> {}, unres |-> {}, marker |-> FALSE, aged |-> FALSE]
Rec(k, i, p, r, u, mk) == [kind |-> k, inv |-> i, plan |-> p, revoked |-> r, unres |-> u, marker |-> mk, aged |-> FALSE]

VARIABLES status, trail, len, index, pending, mark, nextInv, everRevoked
vars == <<status, trail, len, index, pending, mark, nextInv, everRevoked>>

\* ---- reading the trail ----
Life(S) == {p \in S : trail[p].kind \in {"intent", "outcome", "reinstated"}}
LatestIs(S, k) == \E p \in Life(S) : trail[p].kind = k /\ \A q \in Life(S) : q <= p
StateOver(S) ==
    IF Life(S) = {} THEN "none"
    ELSE IF LatestIs(S, "reinstated") THEN "active"
    ELSE IF LatestIs(S, "outcome") THEN "suspended"
    ELSE "suspending"
StateAt(p) ==
    IF trail[p].kind = "reinstated" THEN "active"
    ELSE IF trail[p].kind = "outcome" THEN "suspended"
    ELSE "suspending"
Logged == 1..len
Above == {p \in 1..len : p > mark}
IsOpen(p) == trail[p].kind = "intent" /\ ~\E q \in Logged : trail[q].kind = "outcome" /\ trail[q].inv = trail[p].inv
TrueState == IF StateOver(Logged) = "none" THEN "active" ELSE StateOver(Logged)

\* The miss rule: an absent key is resolved by the tail read above the mark (Composition state
\* 20, 23, 29, 54); a present entry yields to a later trail answer (Composition state 27).
Holds29(p) == IF NoSuspIntent THEN trail[p].kind = "intent" ELSE IsOpen(p)
Read ==
    IF index.st = "absent"
    THEN IF ~\E p \in Above : Holds29(p) THEN "active" ELSE StateOver(Above)
    ELSE IF \E p \in Life(Above) : p > index.pos THEN StateOver(Above) ELSE index.st

Writable(p) == ~OrderedIndex \/ index.st = "absent" \/ index.pos < p

TypeOK ==
    /\ status \in [M -> {"none", "active", "revoked"}]
    /\ len \in 0..MaxLen
    /\ mark \in 0..len
    /\ index.st \in States
    /\ index.pos \in 0..MaxLen
    /\ nextInv \in 1..(MaxInv + 1)
    /\ everRevoked \subseteq M
    /\ \A p \in Pos : trail[p].kind \in Kinds

Init ==
    /\ status = [m \in M |-> IF m \in Planned THEN "active" ELSE "none"]
    /\ trail = [p \in Pos |-> Nil]
    /\ len = 0
    /\ index = [st |-> "absent", pos |-> 0]
    /\ pending = {}
    /\ mark = 0
    /\ nextInv = 1
    /\ everRevoked = {}

\* ---- [Suspend Actor] against an active actor: a fresh cascade ----
\* The snapshot is the actor's active members (Action wiring 10 through 18); the intent
\* carries it as the plan (Action wiring 19); every planned member is revoked (Action wiring
\* 21, 25 through 30); the outcome lands (Action wiring 45, 48) or is refused (a stop).
Fresh(how) ==
    /\ nextInv <= MaxInv
    /\ len + 2 <= MaxLen
    /\ Read = "active"
    /\ LET plan == {m \in M : status[m] = "active"}
           k == nextInv
           ip == len + 1
       IN /\ status' = IF how = "stop" /\ ~StandOnStop THEN status
                       ELSE [m \in M |-> IF m \in plan THEN "revoked" ELSE status[m]]
          /\ everRevoked' = everRevoked \cup plan
          /\ IF how = "complete"
             THEN /\ trail' = [trail EXCEPT ![ip] = Rec("intent", k, plan, {}, {}, FALSE),
                                            ![ip + 1] = Rec("outcome", k, plan, plan, {}, FALSE)]
                  /\ len' = ip + 1
                  /\ pending' = pending \cup {[st |-> "suspending", pos |-> ip], [st |-> "suspended", pos |-> ip + 1]}
             ELSE /\ trail' = [trail EXCEPT ![ip] = Rec("intent", k, plan, {}, {}, FALSE)]
                  /\ len' = ip
                  /\ pending' = pending \cup {[st |-> "suspending", pos |-> ip]}
          /\ nextInv' = k + 1
    /\ UNCHANGED <<index, mark>>

\* The retired arm (-buggy-unresolved): Credential refuses c's revoke as invalid-request, c is
\* named unresolved, and the cascade records a suspended outcome with c still active.
FreshUnresolved ==
    /\ ~LiveCredEnds
    /\ nextInv <= MaxInv
    /\ len + 2 <= MaxLen
    /\ Read = "active"
    /\ LET plan == {m \in M : status[m] = "active"}
           k == nextInv
           ip == len + 1
       IN /\ "c" \in plan
          /\ status' = [m \in M |-> IF m \in plan \ {"c"} THEN "revoked" ELSE status[m]]
          /\ everRevoked' = everRevoked \cup (plan \ {"c"})
          /\ trail' = [trail EXCEPT ![ip] = Rec("intent", k, plan, {}, {}, FALSE),
                                    ![ip + 1] = Rec("outcome", k, plan, plan \ {"c"}, {"c"}, FALSE)]
          /\ len' = ip + 1
          /\ pending' = pending \cup {[st |-> "suspending", pos |-> ip], [st |-> "suspended", pos |-> ip + 1]}
          /\ nextInv' = k + 1
    /\ UNCHANGED <<index, mark>>

\* ---- completing an open cascade: a resume, or the sweep ----
\* The open members are the plan less the members standing closed (Action wiring 56;
\* Reconciliation 23); an aged-out intent's plan is unreadable, and the cascade snapshots the
\* actor's active members and marks its outcome (Reconciliation 25, 26). The outcome names
\* the plan's revoked set in full (Wiring decision 8), or what the snapshot closed.
Complete(ik, snap) ==
    /\ len + 2 <= MaxLen
    /\ \E p \in Logged :
         /\ IsOpen(p)
         /\ LET k == trail[p].inv
                aged == trail[p].aged
                open == IF aged THEN (IF snap THEN {m \in M : status[m] = "active"} ELSE {})
                        ELSE {m \in trail[p].plan : status[m] = "active"}
                named == IF aged THEN open ELSE trail[p].plan
            IN /\ status' = [m \in M |-> IF m \in open THEN "revoked" ELSE status[m]]
               /\ everRevoked' = everRevoked \cup open
               /\ trail' = [trail EXCEPT ![len + 1] = Rec(ik, k, open, {}, {}, FALSE),
                                         ![len + 2] = Rec("outcome", k, trail[p].plan, named, {}, aged /\ snap)]
               /\ len' = len + 2
               /\ pending' = pending \cup {[st |-> "suspended", pos |-> len + 2]}
    /\ UNCHANGED <<index, mark, nextInv>>

\* [Suspend Actor] against a suspending actor resumes the open cascade (Action wiring 8,
\* Invariant 3.3); the sweep needs no caller (Reconciliation 2, 3, 31, 32).
Resume == Read = "suspending" /\ Complete("resumeIntent", AgedSnapshot)
Sweep == Complete("recoveryIntent", TRUE)

\* ---- [Reinstate Actor] (Action wiring 78 through 89) ----
Reinstate ==
    /\ nextInv <= MaxInv
    /\ len + 1 <= MaxLen
    /\ Read = "suspended"
    /\ trail' = [trail EXCEPT ![len + 1] = Rec("reinstated", 0, {}, {}, {}, FALSE)]
    /\ len' = len + 1
    /\ pending' = pending \cup {[st |-> "active", pos |-> len + 1]}
    /\ UNCHANGED <<status, index, mark, nextInv, everRevoked>>

\* ---- the issuance layer gates on the index (Capability requirement 40 through 42) ----
Issue ==
    /\ status["x"] = "none"
    /\ Read = "active"
    /\ status' = [status EXCEPT !["x"] = "active"]
    /\ UNCHANGED <<trail, len, index, pending, mark, nextInv, everRevoked>>

\* ---- the index: post-commit writes, in any order, or lost; the sweep's indexing ----
IndexWrite ==
    /\ \E w \in pending :
         /\ index' = IF Writable(w.pos) THEN w ELSE index
         /\ pending' = pending \ {w}
    /\ UNCHANGED <<status, trail, len, mark, nextInv, everRevoked>>

IndexLost ==
    /\ \E w \in pending : pending' = pending \ {w}
    /\ UNCHANGED <<status, trail, len, index, mark, nextInv, everRevoked>>

SweepIndex ==
    /\ mark < len
    /\ \/ /\ Life(Above) = {}
          /\ UNCHANGED index
       \/ \E p \in Life(Above) :
            /\ \A q \in Life(Above) : q <= p
            /\ index' = IF Writable(p) THEN [st |-> StateAt(p), pos |-> p] ELSE index
    /\ mark' = len
    /\ UNCHANGED <<status, trail, len, pending, nextInv, everRevoked>>

\* ---- the audit horizon destroys an intent's payload at or below the mark ----
AgeOut ==
    /\ \E p \in Logged :
         /\ p <= mark
         /\ trail[p].kind = "intent"
         /\ ~trail[p].aged
         /\ trail' = [trail EXCEPT ![p] = [trail[p] EXCEPT !.aged = TRUE]]
    /\ UNCHANGED <<status, len, index, pending, mark, nextInv, everRevoked>>

Next ==
    \/ Fresh("complete")
    \/ Fresh("stop")
    \/ FreshUnresolved
    \/ Resume
    \/ Sweep
    \/ Reinstate
    \/ Issue
    \/ IndexWrite
    \/ IndexLost
    \/ SweepIndex
    \/ AgeOut

Spec == Init /\ [][Next]_vars

\* ---- what the page guarantees ----
Inv1_1 ==
    \A p \in Life(Logged) :
        (/\ trail[p].kind = "outcome"
         /\ \A q \in Life(Logged) : q <= p)
        => \A m \in trail[p].plan : status[m] # "active"

GateSafe == TrueState \in {"suspending", "suspended"} => Read # "active"

OutcomeHonest ==
    \A p \in Logged :
        (trail[p].kind = "outcome" /\ ~trail[p].marker) => (trail[p].revoked \cup trail[p].unres) = trail[p].plan

NoUnrevoke == \A m \in everRevoked : status[m] = "revoked"

OneOutcome ==
    \A p \in Logged : \A q \in Logged :
        (trail[p].kind = "outcome" /\ trail[q].kind = "outcome" /\ trail[p].inv = trail[q].inv) => p = q

\* ---- reachability probes (each a deliberate falsehood a probe module checks) ----
Probe_NoStop == ~\E p \in Logged : IsOpen(p)
Probe_NoResume == ~\E p \in Logged : trail[p].kind = "resumeIntent"
Probe_NoSweep == ~\E p \in Logged : trail[p].kind = "recoveryIntent"
Probe_NoAgedCompletion == ~\E p \in Logged : trail[p].kind = "outcome" /\ trail[p].marker
Probe_NoMiss == ~(index.st = "absent" /\ TrueState # "active")
Probe_NoLateWrite == ~(index.st # "absent" /\ \E w \in pending : w.pos < index.pos)
Probe_NoReinstate == ~\E p \in Logged : trail[p].kind = "reinstated"
Probe_NoIssue == status["x"] = "none"
Probe_NoSecondCascade == nextInv <= 2

====
