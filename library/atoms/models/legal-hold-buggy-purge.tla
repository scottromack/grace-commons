---- MODULE legal-hold-buggy-purge ----
\* Grace Commons — Legal Hold atom: BUGGY TWIN (isolated, Invariant 8.2 guard).
\*
\* Identical to legal-hold.tla EXCEPT for one action the page does not offer:
\* `Purge` deletes a released hold, its slot returning to "none" (a build that
\* tidies ended obligations away; Invariant 8.1, 8.2).
\*
\* Expected result: Inv8_2_HoldSetNeverShrinks VIOLATED.  Sequence: Place hold
\* k, Release hold k, Purge hold k.  Every other check holds: the placement
\* instants of a hold still in the set never change, and a purged slot is
\* neither active nor released.

EXTENDS Naturals, FiniteSets

CONSTANTS
    MaxH,
    MaxClock

HoldState == {"none", "Active", "Released"}

VARIABLES
    holds,
    releasedByOwn,
    now,
    placedAt,
    enteredAt,
    releasedAt

vars == <<holds, releasedByOwn, now, placedAt, enteredAt, releasedAt>>

TypeOK ==
    /\ holds        \in [1..MaxH -> HoldState]
    /\ releasedByOwn \in [1..MaxH -> BOOLEAN]
    /\ now          \in 0..MaxClock
    /\ placedAt     \in [1..MaxH -> 0..MaxClock]
    /\ enteredAt    \in [1..MaxH -> 0..MaxClock]
    /\ releasedAt   \in [1..MaxH -> 0..MaxClock]

Init ==
    /\ holds         = [k \in 1..MaxH |-> "none"]
    /\ releasedByOwn = [k \in 1..MaxH |-> FALSE]
    /\ now           = 0
    /\ placedAt      = [k \in 1..MaxH |-> 0]
    /\ enteredAt     = [k \in 1..MaxH |-> 0]
    /\ releasedAt    = [k \in 1..MaxH |-> 0]

Tick ==
    /\ now < MaxClock
    /\ now' = now + 1
    /\ UNCHANGED <<holds, releasedByOwn, placedAt, enteredAt, releasedAt>>

Place ==
    /\ \E k \in 1..MaxH :
        /\ holds[k] = "none"
        /\ holds'     = [holds     EXCEPT ![k] = "Active"]
        /\ placedAt'  = [placedAt  EXCEPT ![k] = now]
        /\ enteredAt' = [enteredAt EXCEPT ![k] = now]
    /\ UNCHANGED <<releasedByOwn, now, releasedAt>>

Release ==
    /\ \E k \in 1..MaxH :
        /\ holds[k] = "Active"
        /\ holds'        = [holds        EXCEPT ![k] = "Released"]
        /\ releasedByOwn' = [releasedByOwn EXCEPT ![k] = TRUE]
        /\ releasedAt'   = [releasedAt   EXCEPT ![k] = now]
    /\ UNCHANGED <<now, placedAt, enteredAt>>

\* BUG: a deletion the page does not offer — a released hold leaves the set.
Purge ==
    /\ \E k \in 1..MaxH :
        /\ holds[k] = "Released"
        /\ holds' = [holds EXCEPT ![k] = "none"]
    /\ UNCHANGED <<releasedByOwn, now, placedAt, enteredAt, releasedAt>>

Next == Tick \/ Place \/ Release \/ Purge
Spec == Init /\ [][Next]_vars

Inv_HoldIndependence ==
    \A k \in 1..MaxH : holds[k] = "Released" => releasedByOwn[k]

Inv_TemporalOrdering ==
    \A k \in 1..MaxH : holds[k] = "Released" => releasedAt[k] >= placedAt[k]

Safety == TypeOK /\ Inv_HoldIndependence /\ Inv_TemporalOrdering

Inv1_1_PlacementFieldsFixed ==
    [][\A k \in 1..MaxH : holds[k] # "none" =>
          /\ placedAt'[k]  = placedAt[k]
          /\ enteredAt'[k] = enteredAt[k]]_vars

Inv8_2_HoldSetNeverShrinks ==
    [][\A k \in 1..MaxH : holds[k] # "none" => holds'[k] # "none"]_vars

====
