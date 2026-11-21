---- MODULE legal-hold-buggy-release-re-enters ----
\* Grace Commons — Legal Hold atom: BUGGY TWIN (isolated, Invariant 1.1 guard).
\*
\* Identical to legal-hold.tla EXCEPT `Release` re-stamps enteredAt[k] with
\* the release's now: a release rewrites the entry instant [Place] stamped
\* (Operation 43), which Invariant 1.1 says never changes.
\*
\* Expected result: Inv1_1_PlacementFieldsFixed VIOLATED.  Sequence: Place hold
\* k (enteredAt[k]=0), Tick (now=1), Release hold k (enteredAt[k]=1).  Every
\* other check holds: the release stamps releasedAt with now, targets k alone,
\* and leaves the hold in the set.

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

\* BUG: Release re-stamps the hold's entry instant with its own now, so a
\* release rewrites a placement field (Invariant 1.1).
Release ==
    /\ \E k \in 1..MaxH :
        /\ holds[k] = "Active"
        /\ holds'        = [holds        EXCEPT ![k] = "Released"]
        /\ releasedByOwn' = [releasedByOwn EXCEPT ![k] = TRUE]
        /\ releasedAt'   = [releasedAt   EXCEPT ![k] = now]
        /\ enteredAt'    = [enteredAt    EXCEPT ![k] = now]
    /\ UNCHANGED <<now, placedAt>>

Next == Tick \/ Place \/ Release
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
