---- MODULE party-identity-buggy-reopen ----
\* Grace Commons — Party Identity atom: BUGGY TWIN — Invariant 3 (closed is absorbing).
\* Identical to party-identity.tla EXCEPT `Reinstate` accepts a closed party as
\* well as a suspended one: its guard reads `pstate \in {"Suspended", "Closed"}`,
\* so a closed party with a passed verification on record is reinstated to
\* verified — leaving closed, which Invariant 3.1 forbids.
\*
\* Expected result: Inv3_ClosedAbsorbing VIOLATED by  VerifyPassed -> Close ->
\* Reinstate : everClosed = TRUE, pstate = Verified. Invariant 4 still holds (a
\* passed verification with no suspend after it).

EXTENDS Naturals, FiniteSets

CONSTANT MaxEvents          \* bound on the event-log length (keeps TLC finite)

\* Event alphabet recorded in the insertion-ordered log:
\*   vp = verify(passed)   vf = verify(failed)
\*   sus = suspend         rei = reinstate        cls = close
\* "e" marks an unfilled log slot.
Event == {"vp", "vf", "sus", "rei", "cls"}
States == {"Unverified", "Verified", "Suspended", "Closed"}

VARIABLES
    pstate,                 \* current party state
    log,                    \* 1..MaxEvents -> Event \cup {"e"} ; insertion order
    len,                    \* number of filled log slots
    everClosed              \* history flag: has close ever fired (for Inv 3)

vars == <<pstate, log, len, everClosed>>

\* A `passed` verification with no suspend after it == a passed verification
\* after the MOST RECENT suspend, in insertion order. Derived from the log.
HasPassedAfterSuspend(lg, n) ==
    \E i \in 1..n :
        /\ lg[i] = "vp"
        /\ \A j \in 1..n : (j > i) => (lg[j] # "sus")

TypeOK ==
    /\ pstate \in States
    /\ len \in 0..MaxEvents
    /\ log \in [1..MaxEvents -> (Event \cup {"e"})]
    /\ everClosed \in BOOLEAN

Init ==
    /\ pstate = "Unverified"            \* enroll: party starts Unverified
    /\ log = [i \in 1..MaxEvents |-> "e"]
    /\ len = 0
    /\ everClosed = FALSE

\* --- actions (each appends exactly one event in insertion order) ---

VerifyPassed ==
    /\ pstate # "Closed"
    /\ len < MaxEvents
    /\ log' = [log EXCEPT ![len + 1] = "vp"]
    /\ len' = len + 1
    /\ pstate' = IF pstate = "Unverified" THEN "Verified" ELSE pstate
    /\ UNCHANGED everClosed

VerifyFailed ==
    /\ pstate # "Closed"
    /\ len < MaxEvents
    /\ log' = [log EXCEPT ![len + 1] = "vf"]
    /\ len' = len + 1
    /\ UNCHANGED <<pstate, everClosed>>

Suspend ==
    /\ pstate = "Verified"
    /\ len < MaxEvents
    /\ log' = [log EXCEPT ![len + 1] = "sus"]
    /\ len' = len + 1
    /\ pstate' = "Suspended"
    /\ UNCHANGED everClosed

\* CORRECT reinstate: guarded on a passed verification after the most recent
\* suspend. This is the atom's direct enforcement of Invariant 4.
\* BUG: reinstate also accepts a closed party.
Reinstate ==
    /\ pstate \in {"Suspended", "Closed"}
    /\ HasPassedAfterSuspend(log, len)
    /\ len < MaxEvents
    /\ log' = [log EXCEPT ![len + 1] = "rei"]
    /\ len' = len + 1
    /\ pstate' = "Verified"
    /\ UNCHANGED everClosed

Close ==
    /\ pstate # "Closed"
    /\ len < MaxEvents
    /\ log' = [log EXCEPT ![len + 1] = "cls"]
    /\ len' = len + 1
    /\ pstate' = "Closed"
    /\ everClosed' = TRUE

Next ==
    \/ VerifyPassed
    \/ VerifyFailed
    \/ Suspend
    \/ Reinstate
    \/ Close

Spec == Init /\ [][Next]_vars

\* --- safety invariants (the verification surface) ---

\* Invariant 2 — state membership exclusivity.
Inv2_StateExclusivity == pstate \in States

\* Invariant 3 — Closed is absorbing (history-flag form).
Inv3_ClosedAbsorbing == everClosed => (pstate = "Closed")

\* Invariant 4 — Verified requires a passed verification after the most recent
\* suspend, in insertion order. THE load-bearing claim.
Inv4_PassedAfterSuspend ==
    (pstate = "Verified") => HasPassedAfterSuspend(log, len)

\* Invariant 6 — append-only in insertion order. Promoted from a by-construction
\* assumption to an explicit check (2026-06-03 coverage cross-check): the log is a
\* contiguous filled prefix — every position <= len holds a real event, every
\* position > len is empty. A malformed append (a hole, or a write past the tail)
\* violates this; append-only/monotonic growth is the structural consequence.
Inv6_AppendOnlyPrefix ==
    \A i \in 1..MaxEvents : (i <= len) <=> (log[i] # "e")

Safety == TypeOK /\ Inv2_StateExclusivity /\ Inv3_ClosedAbsorbing
              /\ Inv4_PassedAfterSuspend /\ Inv6_AppendOnlyPrefix

====
