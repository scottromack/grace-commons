---- MODULE audit-trail-quiescence ----
\* One act's quiescence (Term quiescence, Term reachability bound), derived from compositions/audit-trail.md
\* on 2026-11-19 (the cure of Ledger line 2026-11-04-a).
\* An act is quiescent when no [Record Action] is in flight for it, its compensation window has elapsed,
\* it is not a suspended entry of Defensible Retention's first half, and its constituents' records are
\* reachable or reachability bound has run since the window's end, its outcome then unknown. The records'
\* reachability comes and goes as dependency outages start and end, and may never return. The checks that
\* read quiescence (Invariant 1.5, 2.4, 8.1; Defensible Retention Check 8.1, 8.13, 8.14) bind over a
\* quiescent act; whether an auditor can clear them over unreachable records is not modelled.
\* NOT MODELED: the window's own arithmetic (Composition-level invariant 1c's extension by outages,
\* Defensible Retention Invariant 12.1's restart: the window's end is the constant WindowEnd here); what the
\* records hold; the scan and the cascade that make them; more than one act.
EXTENDS Naturals

CONSTANTS WindowEnd, Bound, ActBound, MaxTime

VARIABLES now, inFlight, suspended, reach
vars == <<now, inFlight, suspended, reach>>

TypeOK ==
    /\ now \in 0..MaxTime
    /\ inFlight \in BOOLEAN
    /\ suspended \in BOOLEAN
    /\ reach \in BOOLEAN

Init ==
    /\ now = 0
    /\ inFlight = TRUE
    /\ suspended = FALSE
    /\ reach = TRUE

\* Term quiescence, with the reachability bound's arm.
Quiescent ==
    /\ ~inFlight
    /\ now >= WindowEnd
    /\ ~suspended
    /\ (reach \/ now >= WindowEnd + Bound)

\* The act's [Record Action] returns, within record action completion bound (ActBound).
Return ==
    /\ inFlight
    /\ inFlight' = FALSE
    /\ UNCHANGED <<now, suspended, reach>>

\* A dependency outage starts or ends: the constituents' records become unreachable or reachable again.
Outage ==
    /\ reach' = ~reach
    /\ UNCHANGED <<now, inFlight, suspended>>

\* A hold suspends the entry, or its release ends the suspension (Defensible Retention's first half).
Hold ==
    /\ suspended' = ~suspended
    /\ UNCHANGED <<now, inFlight, reach>>

\* Time moves, but not past a record action's bound with the act still in flight.
Tick ==
    /\ now < MaxTime
    /\ ~(inFlight /\ now >= ActBound)
    /\ now' = now + 1
    /\ UNCHANGED <<inFlight, suspended, reach>>

Next == Return \/ Outage \/ Hold \/ Tick

Spec == Init /\ [][Next]_vars

\* Term quiescence (reachability bound): once reachability bound has run past the window's end, an act no
\* [Record Action] holds and no hold suspends is quiescent, whether or not its records are reachable, so
\* the checks that read quiescence bind over it.
Quiescence_ReachedByBound ==
    (now >= WindowEnd + Bound /\ ~inFlight /\ ~suspended) => Quiescent
====
