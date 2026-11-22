---- MODULE actor-suspension-buggy-revokerasservice ----
\* BUGGY TWIN: every attributed revocation (Credential.revoke) names the service identity as its revoker, the composition's own actor, whoever's credential its intent verified (Audit arm 2 dropped; Reconciliation 21 read as every cascade's), breaking Inv5_2 (Invariant 5.2, Check 4.6).
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
\* THE ATTESTS (2026-11-22, open line 2026-08-30-i). Two operators, o1 and o2, may call, and
\* the service identity svc runs the sweep (Term service identity). Every record carries the
\* principal it is attested under (by), the cascade's operator (nm) and, on a resume's
\* records, the resumer (res); an outcome carries how its cascade completed (via). Audit
\* Trail attests a record under the presented credential, and appends nothing under one that
\* does not validate (its invalid-credential): so a landed record is the credential check of
\* the principal it is attested under, and a call whose credential does not validate is
\* refused at its intent and is no step (Audit arm 3, 4). The attestation of an aged-out
\* event survives its payload in Audit Trail's destruction record (its event to attestation
\* element), so the model reads by on an aged intent. Each member's revocation records the
\* revoker it names and the trail position of the intent its own step landed (rv). A grant's
\* revoker stands in the intent (Term attributed revocation); the credential c's is the
\* revoked by reference Credential.revoke carries. THE MODEL'S FINDING (2026-11-22): one act
\* is one transaction, so a cascade stops only at its outcome with every planned member
\* closed or unresolved, and a resume's or the sweep's open members are empty in every
\* reachable state (the aged-out snapshot included: the gate refuses an issuance to an actor
\* the trail holds suspending). Inv5_2 therefore bites on a fresh cascade's revocations; a
\* resume's and the sweep's checks are on their attests (Inv5_4, Inv5_5).
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
\*   Inv5_1        no revocation commits unless its own step landed an attested intent, the
\*                 credential check (Invariant 5.1; Audit arm 1, 4).
\*   Inv5_2        a revocation's named revoker is the principal its own intent was attested
\*                 under (Invariant 5.2; Audit arm 2, Action wiring 62, Reconciliation 21;
\*                 Check 4.6, 6.1).
\*   Inv5_3        a suspension intent is attested under the operator it names (Invariant 5.3;
\*                 Composes 25).
\*   Inv5_4        a resume intent is attested under its resumer, and a resumed outcome has
\*                 one earlier in the log (Invariant 5.4; Composes 26; Check 4.4).
\*   Inv5_5        a recovery intent is attested under the service identity, and a swept
\*                 outcome has one earlier in the log (Invariant 5.5; Composes 27, 28,
\*                 Reconciliation 20; Check 4.5).
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
\*   AttestGates    an intent Audit Trail refuses invalid-credential commits no
\*                  revocation (Audit arm 4)                                         -buggy-unattested
\*   NamesOwnWriter an attributed revocation names the principal its own intent
\*                  verified, never the service identity alone (Audit arm 2)  -buggy-revokerasservice
\*   IntentUnderOperator  a suspension intent is attested under the calling operator's
\*                  credential (Composes 25)                                       -buggy-intentasservice
\*   ResumeUnderResumer   a resume intent is attested under the resumer (Composes 26)
\*                                                                                 -buggy-resumeasservice
\*   SweepUnderService    the sweep's records are attested under the service identity,
\*                  never the operator's credential (Composes 27, 28)              -buggy-sweepasoperator
\*
\* NOT MODELLED: the boundary predicate, the reinstatement's credential check and what a
\* validation does not establish (Invariant 5.6 through 5.9), credential rotation as a step
\* (each call's credential validates or the call is refused, so a rotation between acts is
\* the next call's refusal), the plan cap, the completion window's arithmetic, the
\* suspension log, not-known members, and the outcome's refusal by a resume or the sweep
\* (each completes).

EXTENDS Naturals, FiniteSets

CONSTANTS StandOnStop, LiveCredEnds, NoSuspIntent, AgedSnapshot, OrderedIndex,
          AttestGates, NamesOwnWriter, IntentUnderOperator, ResumeUnderResumer, SweepUnderService

Operators == {"o1", "o2"}
Svc == "svc"
Principals == Operators \cup {Svc}
IntentKinds == {"intent", "resumeIntent", "recoveryIntent"}
\* A fresh cascade is called by o1, a resume by either operator: the operators are
\* interchangeable, and the one difference a check reads, a resumer other than the cascade's
\* operator, the resume by o2 keeps (264k states with either operator opening, 67k so).
Caller == "o1"

M == {"g", "c", "x"}
Planned == {"g", "c"}
MaxInv == 2
MaxLen == 7
Pos == 1..MaxLen
Kinds == {"none", "intent", "resumeIntent", "recoveryIntent", "outcome", "reinstated"}
States == {"absent", "active", "suspending", "suspended"}

Nil == [kind |-> "none", inv |-> 0, plan |-> {}, revoked |-> {}, unres |-> {}, marker |-> FALSE, aged |-> FALSE,
        by |-> "none", nm |-> "none", res |-> "none", via |-> "none"]
\* A record: its kind, invocation id, plan, revoked set, unresolved members, plan-unavailable
\* marker, the principal it is attested under (b), the cascade's operator (n), the resumer
\* (rs) and, on an outcome, how its cascade completed (v).
Rec(k, i, p, r, u, mk, b, n, rs, v) ==
    [kind |-> k, inv |-> i, plan |-> p, revoked |-> r, unres |-> u, marker |-> mk, aged |-> FALSE,
     by |-> b, nm |-> n, res |-> rs, via |-> v]

\* A member's revocation: the revoker it names and the position of its own step's intent.
NoRev == [who |-> "none", at |-> 0]
RevBy(w, a) == [who |-> w, at |-> a]
\* The revoker member m's revocation names, its step's intent attested under b: a grant's
\* stands in the intent (Term attributed revocation), the credential c's is the revoked by
\* reference Credential.revoke carries (Audit arm 2).
Revoker(m, b) == IF m = "c" /\ ~NamesOwnWriter THEN Svc ELSE b

VARIABLES status, trail, len, index, pending, mark, nextInv, everRevoked, rv
vars == <<status, trail, len, index, pending, mark, nextInv, everRevoked, rv>>

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
    /\ \A p \in Pos : trail[p].by \in Principals \cup {"none"}
    /\ rv \in [M -> [who : Principals \cup {"none"}, at : 0..MaxLen]]

Init ==
    /\ status = [m \in M |-> IF m \in Planned THEN "active" ELSE "none"]
    /\ trail = [p \in Pos |-> Nil]
    /\ len = 0
    /\ index = [st |-> "absent", pos |-> 0]
    /\ pending = {}
    /\ mark = 0
    /\ nextInv = 1
    /\ everRevoked = {}
    /\ rv = [m \in M |-> NoRev]

\* ---- [Suspend Actor] against an active actor: a fresh cascade ----
\* The snapshot is the actor's active members (Action wiring 10 through 18); the intent
\* carries it as the plan (Action wiring 19), attested under the operator o's credential,
\* which is the call's credential check (Composes 25, Invariant 5.3); every planned member is
\* revoked naming the principal the intent verified (Action wiring 21, 25 through 30; Audit
\* arm 1, 2); the outcome lands (Action wiring 45, 48) or is refused (a stop). A call whose
\* credential does not validate is refused at its intent (Audit arm 3, 4) and is no step.
Fresh(o, how) ==
    /\ nextInv <= MaxInv
    /\ len + 2 <= MaxLen
    /\ Read = "active"
    /\ LET plan == {m \in M : status[m] = "active"}
           k == nextInv
           ip == len + 1
           b == IF IntentUnderOperator THEN o ELSE Svc
           stands == how = "complete" \/ StandOnStop
       IN /\ status' = IF stands THEN [m \in M |-> IF m \in plan THEN "revoked" ELSE status[m]]
                       ELSE status
          /\ rv' = IF stands THEN [m \in M |-> IF m \in plan THEN RevBy(Revoker(m, b), ip) ELSE rv[m]] ELSE rv
          /\ everRevoked' = everRevoked \cup plan
          /\ IF how = "complete"
             THEN /\ trail' = [trail EXCEPT ![ip] = Rec("intent", k, plan, {}, {}, FALSE, b, o, "none", "none"),
                                            ![ip + 1] = Rec("outcome", k, plan, plan, {}, FALSE, b, o, "none", "fresh")]
                  /\ len' = ip + 1
                  /\ pending' = pending \cup {[st |-> "suspending", pos |-> ip], [st |-> "suspended", pos |-> ip + 1]}
             ELSE /\ trail' = [trail EXCEPT ![ip] = Rec("intent", k, plan, {}, {}, FALSE, b, o, "none", "none")]
                  /\ len' = ip
                  /\ pending' = pending \cup {[st |-> "suspending", pos |-> ip]}
          /\ nextInv' = k + 1
    /\ UNCHANGED <<index, mark>>

\* The retired arm (-buggy-unresolved): Credential refuses c's revoke as invalid-request, c is
\* named unresolved, and the cascade records a suspended outcome with c still active.
FreshUnresolved(o) ==
    /\ ~LiveCredEnds
    /\ nextInv <= MaxInv
    /\ len + 2 <= MaxLen
    /\ Read = "active"
    /\ LET plan == {m \in M : status[m] = "active"}
           k == nextInv
           ip == len + 1
           b == IF IntentUnderOperator THEN o ELSE Svc
       IN /\ "c" \in plan
          /\ status' = [m \in M |-> IF m \in plan \ {"c"} THEN "revoked" ELSE status[m]]
          /\ rv' = [m \in M |-> IF m \in plan \ {"c"} THEN RevBy(Revoker(m, b), ip) ELSE rv[m]]
          /\ everRevoked' = everRevoked \cup (plan \ {"c"})
          /\ trail' = [trail EXCEPT ![ip] = Rec("intent", k, plan, {}, {}, FALSE, b, o, "none", "none"),
                                    ![ip + 1] = Rec("outcome", k, plan, plan \ {"c"}, {"c"}, FALSE, b, o, "none", "fresh")]
          /\ len' = ip + 1
          /\ pending' = pending \cup {[st |-> "suspending", pos |-> ip], [st |-> "suspended", pos |-> ip + 1]}
          /\ nextInv' = k + 1
    /\ UNCHANGED <<index, mark>>

\* The dropped gate (-buggy-unattested): Audit Trail refuses the intent invalid-credential, so
\* nothing lands, and the invocation makes its committing calls anyway (no Audit arm 4).
FreshUnattested(o) ==
    /\ ~AttestGates
    /\ Read = "active"
    /\ LET plan == {m \in M : status[m] = "active"}
       IN /\ plan # {}
          /\ status' = [m \in M |-> IF m \in plan THEN "revoked" ELSE status[m]]
          /\ rv' = [m \in M |-> IF m \in plan THEN RevBy(o, 0) ELSE rv[m]]
          /\ everRevoked' = everRevoked \cup plan
    /\ UNCHANGED <<trail, len, index, pending, mark, nextInv>>

\* ---- completing an open cascade: a resume, or the sweep ----
\* The open members are the plan less the members standing closed (Action wiring 56;
\* Reconciliation 23); an aged-out intent's plan is unreadable, and the cascade snapshots the
\* actor's active members and marks its outcome (Reconciliation 25, 26). The outcome names
\* the plan's revoked set in full (Wiring decision 8), or what the snapshot closed, and the
\* cascade's operator (Reconciliation 22). The completing intent is attested under w, the
\* resumer or the service identity (Composes 26, 27; Reconciliation 20), before any revoke
\* (Action wiring 59, Reconciliation 18), and each revocation names w (Action wiring 62,
\* Reconciliation 21). A resumed outcome carries its resumer (Action wiring 49).
Complete(ik, snap, w) ==
    /\ len + 2 <= MaxLen
    /\ \E p \in Logged :
         /\ IsOpen(p)
         /\ LET k == trail[p].inv
                aged == trail[p].aged
                op == trail[p].nm
                open == IF aged THEN (IF snap THEN {m \in M : status[m] = "active"} ELSE {})
                        ELSE {m \in trail[p].plan : status[m] = "active"}
                named == IF aged THEN open ELSE trail[p].plan
                isResume == ik = "resumeIntent"
                b == IF isResume
                     THEN (IF ResumeUnderResumer THEN w ELSE Svc)
                     ELSE (IF SweepUnderService THEN w ELSE op)
                rs == IF isResume THEN w ELSE "none"
                v == IF isResume THEN "resume" ELSE "sweep"
            IN /\ status' = [m \in M |-> IF m \in open THEN "revoked" ELSE status[m]]
               /\ rv' = [m \in M |-> IF m \in open THEN RevBy(Revoker(m, b), len + 1) ELSE rv[m]]
               /\ everRevoked' = everRevoked \cup open
               /\ trail' = [trail EXCEPT ![len + 1] = Rec(ik, k, open, {}, {}, FALSE, b, op, rs, "none"),
                                         ![len + 2] = Rec("outcome", k, trail[p].plan, named, {}, aged /\ snap, b, op, rs, v)]
               /\ len' = len + 2
               /\ pending' = pending \cup {[st |-> "suspended", pos |-> len + 2]}
    /\ UNCHANGED <<index, mark, nextInv>>

\* [Suspend Actor] against a suspending actor resumes the open cascade under the calling
\* operator o, the resumer (Action wiring 8, Invariant 3.3; Term resumer); the sweep needs no
\* caller and runs as the service identity (Reconciliation 2, 3, 20, 31, 32).
Resume(o) == Read = "suspending" /\ Complete("resumeIntent", AgedSnapshot, o)
Sweep == Complete("recoveryIntent", TRUE, Svc)

\* ---- [Reinstate Actor] (Action wiring 78 through 89) ----
\* Its credential check (Invariant 5.6) is not modelled: the record names no principal.
Reinstate ==
    /\ nextInv <= MaxInv
    /\ len + 1 <= MaxLen
    /\ Read = "suspended"
    /\ trail' = [trail EXCEPT ![len + 1] = Rec("reinstated", 0, {}, {}, {}, FALSE, "none", "none", "none", "none")]
    /\ len' = len + 1
    /\ pending' = pending \cup {[st |-> "active", pos |-> len + 1]}
    /\ UNCHANGED <<status, index, mark, nextInv, everRevoked, rv>>

\* ---- the issuance layer gates on the index (Capability requirement 40 through 42) ----
Issue ==
    /\ status["x"] = "none"
    /\ Read = "active"
    /\ status' = [status EXCEPT !["x"] = "active"]
    /\ UNCHANGED <<trail, len, index, pending, mark, nextInv, everRevoked, rv>>

\* ---- the index: post-commit writes, in any order, or lost; the sweep's indexing ----
IndexWrite ==
    /\ \E w \in pending :
         /\ index' = IF Writable(w.pos) THEN w ELSE index
         /\ pending' = pending \ {w}
    /\ UNCHANGED <<status, trail, len, mark, nextInv, everRevoked, rv>>

IndexLost ==
    /\ \E w \in pending : pending' = pending \ {w}
    /\ UNCHANGED <<status, trail, len, index, mark, nextInv, everRevoked, rv>>

SweepIndex ==
    /\ mark < len
    /\ \/ /\ Life(Above) = {}
          /\ UNCHANGED index
       \/ \E p \in Life(Above) :
            /\ \A q \in Life(Above) : q <= p
            /\ index' = IF Writable(p) THEN [st |-> StateAt(p), pos |-> p] ELSE index
    /\ mark' = len
    /\ UNCHANGED <<status, trail, len, pending, nextInv, everRevoked, rv>>

\* ---- the audit horizon destroys an intent's payload at or below the mark ----
AgeOut ==
    /\ \E p \in Logged :
         /\ p <= mark
         /\ trail[p].kind = "intent"
         /\ ~trail[p].aged
         /\ trail' = [trail EXCEPT ![p] = [trail[p] EXCEPT !.aged = TRUE]]
    /\ UNCHANGED <<status, len, index, pending, mark, nextInv, everRevoked, rv>>

Next ==
    \/ Fresh(Caller, "complete")
    \/ Fresh(Caller, "stop")
    \/ FreshUnresolved(Caller)
    \/ FreshUnattested(Caller)
    \/ \E o \in Operators : Resume(o)
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

\* Invariant 5.1: a revocation commits only in a step whose own intent landed, attested, so
\* under a credential Audit Trail validated (Audit arm 1, 4).
Inv5_1 ==
    \A m \in M :
        rv[m].who # "none" => (rv[m].at \in Logged /\ trail[rv[m].at].kind \in IntentKinds)

\* Invariant 5.2: the revoker a revocation names is the principal its own intent verified
\* (Audit arm 2; Action wiring 62; Reconciliation 21; Check 4.6, 6.1: the intent stands
\* earlier in the log than the revocation, which its step made after it).
Inv5_2 ==
    \A m \in M :
        (rv[m].who # "none" /\ rv[m].at \in Logged) => trail[rv[m].at].by = rv[m].who

\* Invariant 5.3: a suspension intent is attested under the operator it names (Composes 25).
Inv5_3 == \A p \in Logged : trail[p].kind = "intent" => trail[p].by = trail[p].nm

\* Invariant 5.4: a resume intent is attested under its resumer (Composes 26), and every
\* resumed outcome has its cascade's resume intent so attested earlier in the log (Check 4.4).
Inv5_4 ==
    /\ \A p \in Logged : trail[p].kind = "resumeIntent" => trail[p].by = trail[p].res
    /\ \A p \in Logged :
         (trail[p].kind = "outcome" /\ trail[p].via = "resume")
         => \E q \in Logged : /\ q < p
                              /\ trail[q].kind = "resumeIntent"
                              /\ trail[q].inv = trail[p].inv
                              /\ trail[q].by = trail[p].res

\* Invariant 5.5: a recovery intent is attested under the service identity (Composes 27, 28;
\* Reconciliation 20), and every swept outcome has one earlier in the log (Check 4.5).
Inv5_5 ==
    /\ \A p \in Logged : trail[p].kind = "recoveryIntent" => trail[p].by = Svc
    /\ \A p \in Logged :
         (trail[p].kind = "outcome" /\ trail[p].via = "sweep")
         => \E q \in Logged : /\ q < p
                              /\ trail[q].kind = "recoveryIntent"
                              /\ trail[q].inv = trail[p].inv
                              /\ trail[q].by = Svc

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
