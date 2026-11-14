---- MODULE provisional-commitment-buggy-stamp ----
\* Grace Commons — Provisional Commitment atom: BUGGY TWIN — Invariant 8 (instants follow placement).
\* Mirrors provisional-commitment.tla (Final Critique 4 stored-Expired shape,
\* restored 2026-06-23) EXCEPT `Release` writes the released state without
\* stamping the release instant: the record keeps the field's zero default, an
\* instant before placement (Invariant 8.2). The window guards are intact, so
\* single-resolution and confirm-within-window still hold.
\*
\* Expected result: Inv8_TransitionsAfterPlacement VIOLATED by  Release :
\* state = Released, releasedAt = 0 < PlacedAt = 1.

EXTENDS Naturals

CONSTANTS PlacedAt,         \* clock tick at which place_hold fires (> 0)
          ExpiresAt,        \* window close time; take ExpiresAt > PlacedAt
          MaxClock          \* clock bound (finiteness); take MaxClock > ExpiresAt

Terminals == {"Confirmed", "Released", "Expired"}
States    == {"Held"} \cup Terminals

VARIABLES state, clock, resolution, confirmedAt, releasedAt, expiredAt, everTerminal
vars == <<state, clock, resolution, confirmedAt, releasedAt, expiredAt, everTerminal>>

TypeOK ==
    /\ state \in States
    /\ clock \in 0..MaxClock
    /\ resolution \in (Terminals \cup {"none"})
    /\ confirmedAt \in 0..MaxClock
    /\ releasedAt \in 0..MaxClock
    /\ expiredAt \in 0..MaxClock
    /\ everTerminal \in BOOLEAN

Init ==
    /\ state = "Held"           \* place_hold: commitment starts Held at PlacedAt
    /\ clock = PlacedAt
    /\ resolution = "none"
    /\ confirmedAt = 0          \* sentinel — only valid when state = "Confirmed"
    /\ releasedAt = 0           \* sentinel — only valid when state = "Released"
    /\ expiredAt = 0            \* sentinel — only valid when state = "Expired"
    /\ everTerminal = FALSE

\* The pipeline's implicit clock advances at the I/O seam; it writes nothing else.
Tick ==
    /\ clock < MaxClock
    /\ clock' = clock + 1
    /\ UNCHANGED <<state, resolution, confirmedAt, releasedAt, expiredAt, everTerminal>>

\* CORRECT confirm: a resolving write, admitted only while Held AND strictly
\* within the window (clock < ExpiresAt).
Confirm ==
    /\ state = "Held"
    /\ clock < ExpiresAt
    /\ state' = "Confirmed"
    /\ confirmedAt' = clock
    /\ resolution' = IF resolution = "none" THEN "Confirmed" ELSE resolution
    /\ everTerminal' = TRUE
    /\ UNCHANGED <<clock, releasedAt, expiredAt>>

\* CORRECT release: a resolving write, same window guard as confirm; stamps
\* releasedAt at the current clock.
Release ==
    /\ state = "Held"
    /\ clock < ExpiresAt
    /\ state' = "Released"
    /\ UNCHANGED releasedAt    \* BUG: the release instant is not stamped
    /\ resolution' = IF resolution = "none" THEN "Released" ELSE resolution
    /\ everTerminal' = TRUE
    /\ UNCHANGED <<clock, confirmedAt, expiredAt>>

\* CORRECT expire: the side-effecting lapse event — a resolving write to the
\* stored Expired terminal, admitted only once the window has elapsed
\* (clock >= ExpiresAt). Stamps expiredAt. May be fired by a scheduler/sweep or
\* lazily on access; the model abstracts the trigger as an enabled action.
Expire ==
    /\ state = "Held"
    /\ clock >= ExpiresAt
    /\ state' = "Expired"
    /\ expiredAt' = clock
    /\ resolution' = IF resolution = "none" THEN "Expired" ELSE resolution
    /\ everTerminal' = TRUE
    /\ UNCHANGED <<clock, confirmedAt, releasedAt>>

Next == Tick \/ Confirm \/ Release \/ Expire
Spec == Init /\ [][Next]_vars

\* Load-bearing — single-resolution (immutable once written). Ranges over the
\* three stored terminals; once `resolution` is set, `state` must equal it.
Inv_SingleResolution == (resolution # "none") => (state = resolution)

\* Inv 7 (load-bearing) — a Confirmed commitment was confirmed strictly within
\* the window. With Confirm guarded `clock < ExpiresAt` and Expire guarded
\* `clock >= ExpiresAt` (mutually exclusive), a hold cannot be confirmed after the
\* window closes. The window twin (-buggy-window) admits confirm at
\* clock = ExpiresAt and is caught here.
Inv_ConfirmWithinWindow == (state = "Confirmed") => (confirmedAt < ExpiresAt)

\* Invariant 3 — terminal absorption (history-flag form): once a commitment has
\* entered a stored terminal it stays terminal. A transition out of a terminal
\* state would violate this.
Inv3_TerminalAbsorbing ==
    everTerminal => (state \in Terminals)

\* Inv 8 (load-bearing) — every stored terminal transition timestamp is >=
\* placed_at. PlacedAt > 0 so sentinel 0 is strictly below it; a buggy twin that
\* forgets to capture the real clock is caught.
Inv8_TransitionsAfterPlacement ==
    /\ (state = "Confirmed") => (confirmedAt >= PlacedAt)
    /\ (state = "Released")  => (releasedAt  >= PlacedAt)
    /\ (state = "Expired")   => (expiredAt   >= PlacedAt)

Safety ==
    /\ TypeOK
    /\ Inv_SingleResolution
    /\ Inv_ConfirmWithinWindow
    /\ Inv3_TerminalAbsorbing
    /\ Inv8_TransitionsAfterPlacement

\* NOTE Invariant 1 (membership exclusivity over stored states) is TypeOK.

====
