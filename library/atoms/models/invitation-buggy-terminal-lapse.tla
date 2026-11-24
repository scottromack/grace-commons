---- MODULE invitation-buggy-terminal-lapse ----
\* Grace Commons — Invitation atom: BUGGY TWIN — the derivation's negative half.
\* Mirrors invitation.tla (execution/render-time refactor, 2026-06-21) EXCEPT
\* `Lapsed` drops `state = Pending`: the window reading is applied to every
\* invitation, so an accepted, declined or revoked invitation reads Expired once
\* now reaches the deadline — where Term effective status gives the stored
\* status (Term lapsed is a pending invitation's reading). The positive half,
\* a lapsed pending invitation reading Expired, still holds.
\*
\* Expected result: Inv_DerivedExpiryCoherent VIOLATED. Accept at now = 0, Tick
\* to ExpiresAt: state = Accepted but EffStatus(now) = Expired.

EXTENDS Naturals

CONSTANT ExpiresAt    \* fixed deadline (a natural; lapsed once now >= ExpiresAt)
CONSTANT MaxClock     \* TypeOK clock domain bound; must be >= ExpiresAt + 1.
                      \* Exploration saturates at ExpiresAt + 1 regardless (Tick clamp).

VARIABLES state, resolution, now
vars == <<state, resolution, now>>

StoredTerminals == {"Accepted", "Declined", "Revoked"}
StoredStates    == {"Pending"} \cup StoredTerminals

TypeOK ==
    /\ state \in StoredStates
    /\ resolution \in (StoredTerminals \cup {"none"})
    /\ now \in 0..MaxClock

Init ==
    /\ state = "Pending"
    /\ resolution = "none"
    /\ now = 0

\* Derived, read-time effective status (render time). Never stored.
Lapsed(c)    == c >= ExpiresAt    \* BUG: the stored state is not consulted
EffStatus(c) == IF Lapsed(c) THEN "Expired" ELSE state

\* The injected clock advances at the I/O seam; it writes nothing else. Clamped
\* at ExpiresAt + 1 (FC F1): one tick past the deadline is the only behaviorally-
\* distinct lapsed value, so the reachable space saturates there.
Tick ==
    /\ now < ExpiresAt + 1
    /\ now' = now + 1
    /\ UNCHANGED <<state, resolution>>

\* Resolving writes: only while Pending AND not lapsed (now < ExpiresAt). The
\* injected `now` is read in the guard (pure); no write ever sets an Expired state.
Resolve(t) ==
    /\ state = "Pending"
    /\ now < ExpiresAt
    /\ state' = t
    /\ resolution' = IF resolution = "none" THEN t ELSE resolution
    /\ UNCHANGED now

Accept  == Resolve("Accepted")
Decline == Resolve("Declined")
Revoke  == Resolve("Revoked")

Next == Accept \/ Decline \/ Revoke \/ Tick
Spec == Init /\ [][Next]_vars

\* Load-bearing — single-resolution by write (immutable once written).
Inv_SingleResolution == (resolution # "none") => (state = resolution)

\* Expiry is derived, never written: the store never holds an "Expired" value
\* (by construction — no action writes it; promoted to an explicit check so a
\* future edit that re-introduces a stored Expired is caught).
Inv_NoStoredExpired == state \in StoredStates

\* The derivation never misclassifies a written terminal as Expired: a stored
\* terminal always reads back as itself. NOTE (FC F2): this antecedent excludes
\* Pending, so it does NOT exercise the positive Pending->Expired derivation — it
\* is the NEGATIVE half only. Inv_LapsedReadsExpired below supplies the positive,
\* non-vacuous half.
Inv_DerivedExpiryCoherent == (state \in StoredTerminals) => (EffStatus(now) = state)

\* POSITIVE derivation (FC F2), non-vacuous: every lapsed Pending record reads
\* Expired. The antecedent Lapsed(now) is reachable (Pending states at
\* now >= ExpiresAt exist — e.g. (Pending, none, ExpiresAt)), so this check
\* actually bites. The buggy twin invitation-buggy-derivation.tla breaks the
\* derivation (EffStatus returns `state` unconditionally) and is rejected here.
Inv_LapsedReadsExpired == Lapsed(now) => (EffStatus(now) = "Expired")

Safety ==
    /\ TypeOK
    /\ Inv_SingleResolution
    /\ Inv_NoStoredExpired
    /\ Inv_DerivedExpiryCoherent
    /\ Inv_LapsedReadsExpired
====
