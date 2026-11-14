---- MODULE approval-step-buggy-subject ----
\* Grace Commons — Approval Step atom: BUGGY TWIN — Invariant 9 (concurrent step independence).
\* Identical to approval-step.tla EXCEPT `Approve` writes by subject, not by
\* step: the two steps share one subject reference, and the approve resolves
\* every pending step on the subject — the `UPDATE ... WHERE subject_ref = X`
\* where `WHERE step_id = X` was meant. Approving s1 also stands the other
\* pending step Approved, a field of a second step the action had no business
\* writing (Invariant 9.1).
\*
\* Expected result: Inv9_StepIndependence VIOLATED. From the initial state,
\* Approve(s1, a1): lastOther = s2, preState = Pending (the snapshot read before
\* the action), but state[s2] = Approved after it. (Invariant 4 also fails on the
\* same step, since s2 now stands Approved by a1, not its approver a2.)

Steps  == {"s1", "s2"}
Actors == {"a1", "a2", "a3"}
StepStates == {"Pending", "Approved", "Rejected", "Withdrawn"}

\* Fixed bindings: a1 approves s1, a2 approves s2; a3 submits both.
approver  == [s \in Steps |-> IF s = "s1" THEN "a1" ELSE "a2"]
submitter == [s \in Steps |-> "a3"]

Other(s) == IF s = "s1" THEN "s2" ELSE "s1"

\* state: Steps -> StepStates ; decidedBy: Steps -> Actors \cup {none}
\* lastOther/preState/preDecided: the Inv9 frame-witness (see header).
VARIABLES state, decidedBy, lastOther, preState, preDecided
vars == <<state, decidedBy, lastOther, preState, preDecided>>

TypeOK ==
    /\ state \in [Steps -> StepStates]
    /\ decidedBy \in [Steps -> (Actors \cup {"none"})]
    /\ lastOther \in (Steps \cup {"none"})
    /\ preState \in StepStates
    /\ preDecided \in (Actors \cup {"none"})

Init ==
    /\ state = [s \in Steps |-> "Pending"]
    /\ decidedBy = [s \in Steps |-> "none"]
    /\ lastOther = "none"
    /\ preState = "Pending"
    /\ preDecided = "none"

\* CORRECT: approve/reject guarded on actor = approver_ref; withdraw on
\* actor = submitter_ref. Each updates only step s; the witness conjuncts
\* snapshot the OTHER step's pre-action values (unprimed reads only).
\* BUG: the write is keyed by subject, so every pending step on it is approved.
Approve(s, actor) ==
    /\ state[s] = "Pending"
    /\ actor = approver[s]
    /\ state' = [t \in Steps |-> IF t = s \/ state[t] = "Pending" THEN "Approved" ELSE state[t]]
    /\ decidedBy' = [t \in Steps |-> IF t = s \/ state[t] = "Pending" THEN actor ELSE decidedBy[t]]
    /\ lastOther' = Other(s)
    /\ preState' = state[Other(s)]
    /\ preDecided' = decidedBy[Other(s)]

Reject(s, actor) ==
    /\ state[s] = "Pending"
    /\ actor = approver[s]
    /\ state' = [state EXCEPT ![s] = "Rejected"]
    /\ decidedBy' = [decidedBy EXCEPT ![s] = actor]
    /\ lastOther' = Other(s)
    /\ preState' = state[Other(s)]
    /\ preDecided' = decidedBy[Other(s)]

Withdraw(s, actor) ==
    /\ state[s] = "Pending"
    /\ actor = submitter[s]
    /\ state' = [state EXCEPT ![s] = "Withdrawn"]
    /\ decidedBy' = [decidedBy EXCEPT ![s] = actor]
    /\ lastOther' = Other(s)
    /\ preState' = state[Other(s)]
    /\ preDecided' = decidedBy[Other(s)]

Next == \E s \in Steps, actor \in Actors :
            \/ Approve(s, actor)
            \/ Reject(s, actor)
            \/ Withdraw(s, actor)
Spec == Init /\ [][Next]_vars

\* Invariant 4 — approver exclusivity.
Inv4_ApproverExclusivity ==
    \A s \in Steps : state[s] \in {"Approved", "Rejected"} => decidedBy[s] = approver[s]

\* Invariant 5 — submitter exclusivity.
Inv5_SubmitterExclusivity ==
    \A s \in Steps : state[s] = "Withdrawn" => decidedBy[s] = submitter[s]

\* Invariant 9 — concurrent step independence (checked, not assumed).
\* In the post-state of every action, the step the action did NOT target still
\* carries exactly the state/decidedBy it had before the action fired.
Inv9_StepIndependence ==
    \/ lastOther = "none"
    \/ (state[lastOther] = preState /\ decidedBy[lastOther] = preDecided)

Safety == TypeOK /\ Inv4_ApproverExclusivity /\ Inv5_SubmitterExclusivity /\ Inv9_StepIndependence

\* NOTE Invariant 3 (terminal absorption) remains enforced by construction (every
\* action guards on state[s] = "Pending"); it is not vote-named load-bearing, so
\* by-construction is acceptable per the coverage cross-check verdicts.

====
