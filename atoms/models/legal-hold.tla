---- MODULE legal-hold ----
\* Grace Commons — Legal Hold atom.
\* Spec-level formal sibling of atoms/legal-hold.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* WHAT THIS MODEL CHECKS
\* Two load-bearing claims (formal-layer vote 2026-06-03):
\*
\*   Invariant 4 — Concurrent-hold independence: multiple holds may cover the
\*   same record, each with its own lifecycle, and releasing one hold leaves
\*   every other hold's state untouched ("Hold-002 remains Active when Hold-001
\*   is released").  Ghost `releasedByOwn[k]` is TRUE only if hold k was the
\*   explicit target of a `release`, so the predicate is falsifiable.
\*
\*   Invariant 6 — Temporal ordering: for every Released hold,
\*   releasedAt[k] >= placedAt[k].  Modeled with a global monotonically-
\*   advancing clock `now` (a bounded Naturals counter, no Sequences module).
\*   Ghost `placedAt[k]` is stamped with `now` on Place; ghost `releasedAt[k]`
\*   is stamped with `now` on Release.  Because `now` only ever increases,
\*   release can never stamp a tick earlier than placement — the correct model
\*   holds this invariant exhaustively.
\*
\* Added 2026-11-21 (the page's Check 6.1 and 6.2 read committed versions, Execution
\* Contract Generation acceptance 1), each checked across every step:
\*
\*   Invariant 1.1 — a placed hold's placement instant and entry instant never
\*   change (Inv1_1_PlacementFieldsFixed).  Ghost `enteredAt[k]` is the entry
\*   instant [Place] stamps from the injected now (Operation 43); the model has
\*   no supplied instant, so here it equals placedAt[k], and its other placement
\*   fields (ids, actors, reasons) are the Alloy model's, legal-hold.als.
\*
\*   Invariant 8.2 — the hold set never shrinks: a placed hold never returns to
\*   "none" (Inv8_2_HoldSetNeverShrinks); Invariant 8.1, no hold deleted, is the
\*   same move in this model.
\*
\*   Invariant 2.1 (Check 6.3) holds by construction: holds[k] is one value of
\*   HoldState in every state (TypeOK), so each version stands in exactly one
\*   state; the Alloy model checks it on a record whose state is a set of flags.
\*
\* MODELING CHOICES
\* - Up to MaxH holds over one record, each in {none, Active, Released}.
\* - Global clock `now` in 0..MaxClock; `Tick` advances it by 1 (guarded by
\*   now < MaxClock so the state space stays finite).
\* - placedAt[k], enteredAt[k] and releasedAt[k] are initialised to 0 (sentinel "not yet
\*   set"); the invariant fires only when holds[k] = "Released", so the 0
\*   sentinel on unplaced/unreleased slots is safe.
\* - Time is modeled as Naturals, not Sequences — per harness README.
\*
\* SATURATION NOTE (2026-06-04)
\*   MaxH=2, MaxClock=3 → 370 states.  MaxClock=4 → 811 states; state count
\*   grows because more absolute timestamp values exist (not new behavioral
\*   patterns).  The temporal-ordering invariant is purely relational; all
\*   relative orderings (same-tick, 1-apart, 2-apart) are fully represented at
\*   MaxClock=3.  Behavioral-coverage saturation point: MaxClock=3.
\*   MaxH and MaxClock are recorded in legal-hold.cfg.
\*
\* NOT MODELED (out of scope): id discipline, attribution fields, the purge gate
\* (that is the Defensible Retention composition — see defensible-retention.tla).

EXTENDS Naturals, FiniteSets

CONSTANTS
    MaxH,       \* max concurrent holds over the record
    MaxClock    \* clock upper bound (saturation guard)

HoldState == {"none", "Active", "Released"}

VARIABLES
    holds,          \* holds[k] in HoldState
    releasedByOwn,  \* ghost: TRUE iff hold k was released by its own Release action
    now,            \* global monotonic clock counter in 0..MaxClock
    placedAt,       \* ghost: clock tick when hold k was placed (0 = not yet placed)
    enteredAt,      \* ghost: entry instant [Place] stamped from now (Operation 43)
    releasedAt      \* ghost: clock tick when hold k was released (0 = not yet released)

vars == <<holds, releasedByOwn, now, placedAt, enteredAt, releasedAt>>

ActiveCount == Cardinality({k \in 1..MaxH : holds[k] = "Active"})
RecordHeld  == ActiveCount > 0

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

\* Advance the global clock by one tick (guarded so the space remains finite).
Tick ==
    /\ now < MaxClock
    /\ now' = now + 1
    /\ UNCHANGED <<holds, releasedByOwn, placedAt, enteredAt, releasedAt>>

\* Place a hold: stamp placedAt[k] and enteredAt[k] with the current clock.
Place ==
    /\ \E k \in 1..MaxH :
        /\ holds[k] = "none"
        /\ holds'     = [holds     EXCEPT ![k] = "Active"]
        /\ placedAt'  = [placedAt  EXCEPT ![k] = now]
        /\ enteredAt' = [enteredAt EXCEPT ![k] = now]
    /\ UNCHANGED <<releasedByOwn, now, releasedAt>>

\* CORRECT release: transitions ONLY the targeted hold; stamps releasedAt[k]
\* with the current clock (>= placedAt[k] because now only advances).
Release ==
    /\ \E k \in 1..MaxH :
        /\ holds[k] = "Active"
        /\ holds'        = [holds        EXCEPT ![k] = "Released"]
        /\ releasedByOwn' = [releasedByOwn EXCEPT ![k] = TRUE]
        /\ releasedAt'   = [releasedAt   EXCEPT ![k] = now]
    /\ UNCHANGED <<now, placedAt, enteredAt>>

Next == Tick \/ Place \/ Release
Spec == Init /\ [][Next]_vars

\* Invariant 4 — Concurrent-hold independence (load-bearing).
\* A Released hold was released by its own action; no cascading side-effects.
Inv_HoldIndependence ==
    \A k \in 1..MaxH : holds[k] = "Released" => releasedByOwn[k]

\* Invariant 6 — Temporal ordering (load-bearing, closes the GAP).
\* Every Released hold has releasedAt >= placedAt.
Inv_TemporalOrdering ==
    \A k \in 1..MaxH : holds[k] = "Released" => releasedAt[k] >= placedAt[k]

Safety == TypeOK /\ Inv_HoldIndependence /\ Inv_TemporalOrdering

\* Invariant 1.1 — a placed hold's placement instant and entry instant never
\* change, whatever step follows (Check 6.2).
Inv1_1_PlacementFieldsFixed ==
    [][\A k \in 1..MaxH : holds[k] # "none" =>
          /\ placedAt'[k]  = placedAt[k]
          /\ enteredAt'[k] = enteredAt[k]]_vars

\* Invariant 8.2 — the hold set never shrinks: a placed hold is in the set at
\* every later step (Check 6.1; Invariant 8.1, no hold deleted).
Inv8_2_HoldSetNeverShrinks ==
    [][\A k \in 1..MaxH : holds[k] # "none" => holds'[k] # "none"]_vars

====
