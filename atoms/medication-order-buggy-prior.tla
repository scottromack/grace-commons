---- MODULE medication-order-buggy-prior ----
\* Grace Commons — Medication Order atom: BUGGY TWIN (added 2026-11-10, unit
\* `tooling: every check has a twin that breaks it`).
\*
\* Identical to medication-order.tla EXCEPT `hold` does not store prior_state:
\* it leaves `prior` as it was ("none" on a first hold), modeling an
\* implementation that puts the order On Hold without recording where it came
\* from. This violates Invariant 5 (an On Hold order carries its prior_state).
\*
\* Expected result: Inv5_PriorValid VIOLATED. Hold from Ordered: state is
\* "OnHold" with prior = "none". If the checker reports all invariants hold
\* here, the harness is vacuous.

VARIABLES state, prior, heldFrom, justReinstated
vars == <<state, prior, heldFrom, justReinstated>>

States == {"Ordered", "Verified", "Dispensed", "Administered",
           "Completed", "Cancelled", "Discontinued", "OnHold"}
Holdable == {"Ordered", "Verified", "Dispensed", "Administered"}

TypeOK ==
    /\ state \in States
    /\ prior \in (Holdable \cup {"none"})
    /\ heldFrom \in (Holdable \cup {"none"})
    /\ justReinstated \in BOOLEAN

Init ==
    /\ state = "Ordered"
    /\ prior = "none"
    /\ heldFrom = "none"
    /\ justReinstated = FALSE

\* --- forward lifecycle (each clears justReinstated, leaves prior/heldFrom) ---
Verify ==
    /\ state = "Ordered" /\ state' = "Verified"
    /\ justReinstated' = FALSE /\ UNCHANGED <<prior, heldFrom>>
Dispense ==
    /\ state = "Verified" /\ state' = "Dispensed"
    /\ justReinstated' = FALSE /\ UNCHANGED <<prior, heldFrom>>
Administer ==
    /\ state = "Dispensed" /\ state' = "Administered"
    /\ justReinstated' = FALSE /\ UNCHANGED <<prior, heldFrom>>
Complete ==
    /\ state = "Administered" /\ state' = "Completed"
    /\ justReinstated' = FALSE /\ UNCHANGED <<prior, heldFrom>>
Cancel ==
    /\ state \in {"Ordered", "Verified"} /\ state' = "Cancelled"
    /\ justReinstated' = FALSE /\ UNCHANGED <<prior, heldFrom>>
Discontinue ==
    /\ state \in {"Dispensed", "Administered"} /\ state' = "Discontinued"
    /\ justReinstated' = FALSE /\ UNCHANGED <<prior, heldFrom>>

\* hold: record current state as prior_state (and ghost heldFrom).
Hold ==
    /\ state \in Holdable
    /\ state' = "OnHold"
    /\ prior' = prior          \* BUG: was prior' = state (prior_state not stored)
    /\ heldFrom' = state
    /\ justReinstated' = FALSE

\* CORRECT reinstate: return to the stored prior_state, not a parameter.
Reinstate ==
    /\ state = "OnHold"
    /\ state' = prior
    /\ prior' = "none"
    /\ heldFrom' = heldFrom
    /\ justReinstated' = TRUE

Next ==
    \/ Verify
    \/ Dispense
    \/ Administer
    \/ Complete
    \/ Cancel
    \/ Discontinue
    \/ Hold
    \/ Reinstate
Spec == Init /\ [][Next]_vars

\* Invariant 5 (round-trip) — after a reinstate, the order is back in exactly
\* the state it was held from. THE load-bearing claim.
Inv5_ReinstateRoundTrip == justReinstated => (state = heldFrom)

\* Invariant 5 (well-formedness) — On Hold always carries a valid holdable prior.
Inv5_PriorValid == (state = "OnHold") => (prior \in Holdable)

Safety == TypeOK /\ Inv5_ReinstateRoundTrip /\ Inv5_PriorValid

\* NOTE Invariant 9 (On Hold accepts only reinstate) is enforced by construction:
\* every forward action guards on a non-OnHold source state, so from OnHold only
\* Reinstate is enabled.

====
