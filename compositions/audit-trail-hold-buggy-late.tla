---- MODULE audit-trail-hold-buggy-late ----
\* BUGGY TWIN: a leg that stalled past its lease writes when it wakes (Per-act critical section 13b dropped).
\* Grace Commons — Audit Trail composition, the legal hold over an open cascade entry.
\* Spec-level formal sibling of compositions/audit-trail.md; the cascade is audit-trail.tla.
\* Derived validator; the English spec is the single source of truth. On any disagreement,
\* diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* ONE open cascade entry: retention Purged at instant 0, content readable, no destroyed outcome
\* (a cascade that stopped after step 1). THREE processes over it:
\*   - the scan's first half, a run per cadence, taking the per-act critical section by try-take,
\*     reading hold under it (purge event 5c) and then either landing under-legal-hold with
\*     nothing changed (purge event 5b, 5d, First half 9) or completing the cascade;
\*   - a hold placement, which takes the same section, waiting for it, as a lease of purge
\*     completion bound, writes the hold under it and returns (Capability requirement 7a, 7c, 7d,
\*     Per-act critical section 15a, 15b) — or returns having placed nothing;
\*   - a release of the hold, which takes no section and may carry a backdated instant
\*     (Legal Hold Operation 39, 41).
\* The deployment's operational record is the last of: no run has landed the entry
\* under-legal-hold; a run landed it under-legal-hold; a later run read no active hold, at a
\* recorded instant (Composition-level invariant 1h).
\*
\* WHAT THIS MODEL CHECKS
\*   Inv_NoDestroyUnderHold  no content is destroyed while a hold is active (purge event 5b).
\*   Inv_ReDriveAfterRelease after a release, a run reads no active hold within GapMax (First half 10).
\*   Inv_ClosureAfterRestart after the recorded hold-free run the entry closes (Composition-level invariant 1e).
\*   Inv_BoundedClosure      read as an auditor reads it, from the stores and the operational
\*                           record alone: an open entry that is neither held nor a suspended
\*                           entry is closed within closure sum of its start, the start being
\*                           its purge instant or the recorded hold-free run (First half 9, 11,
\*                           Composition-level invariant 1e, Term suspended entry, Term quiescence).
\*
\* THE BUDGET  One fault among the scan's runs (a run that dies holding the section, or stalls
\* after its hold read and wakes later) and ONE hold placement, which may hold the section its
\* whole lease and place nothing. Closure sum budgets exactly that: its Legal Hold part is one
\* placement's lease and the run it displaces. Two placements are outside the budget and outside
\* this model.
\*
\* NOT MODELED
\*   The cascade's own steps and the first cascade (audit-trail.tla); the hold read's failure arm
\*   (purge event 5e); store outages (Composition-level invariant 1c, 1d); clock offset allowance
\*   (0 here); a caller-driven [Purge Event] over the Purged retention (purge event step 1.4);
\*   the erasure mechanism failing (the delegation always destroys); overlapping runs.
\*   Where the model is more generous than the page: a write issued inside a lease lands inside
\*   it (the page's premise, purge completion bound 2), so delegation is one step; and a lease of
\*   n ticks is live through n - 1, so the window has two ticks of room the page's does not.
\*   The twin without the Legal Hold part still breaches, so the hazard is inside the horizon; the
\*   part's exact amount is carried by tools/harness/audit-trail-closure.py, not here.
\*   After a restart the window's own end lies past MaxTime; Inv_ClosureAfterRestart checks the
\*   stronger bound that does fit. Small constants: "all invariants hold" is a statement within
\*   MaxTime ticks at these constants.
\*
\* TWINS AND PROBES  Each is this module byte for byte below its header, with one constant or one
\* invariant changed in its .cfg: -buggy-unserialized, -buggy-late, -buggy-edge, -buggy-backdated,
\* -buggy-unbudgeted; -probe-held, -probe-restart, -probe-open.
EXTENDS Naturals

CONSTANTS LeaseLen, SweepLease, Cadence, MaxTime, MaxPlace, Faults, HoldTerm, SlowPlacer,
          Serialized, GateLive, Suspension, StoreRelease

VARIABLES now, holder, exp, hold, content, closed, spc, zpc, lastRun, runAt, rec, freeRunAt,
          ppc, placed, relInst, relSeen, faults, bad, gap
vars == <<now, holder, exp, hold, content, closed, spc, zpc, lastRun, runAt, rec, freeRunAt,
          ppc, placed, relInst, relSeen, faults, bad, gap>>

Edge == LeaseLen                                   \* purge edge, allowance 0
ClosureSum == Edge + 2 * (Cadence + SweepLease)   \* Term closure sum, allowance 0, Legal Hold absent
Window == ClosureSum + HoldTerm                   \* HoldTerm: the part closure sum adds WHERE Legal Hold EQUALS composed
GapMax == 2 * (Cadence + SweepLease)              \* closure sum's two-run term: a run due, the budgeted dead run, the run after it
Live(who) == holder = who /\ now < exp
InFlight == spc \in {"took", "free", "wrote"}

TypeOK ==
    /\ now \in 0..MaxTime
    /\ holder \in {"none", "scan", "zombie", "placer"}
    /\ exp \in 0..(MaxTime + LeaseLen + SweepLease)
    /\ hold \in BOOLEAN
    /\ content \in {"readable", "destroyed"}
    /\ closed \in BOOLEAN
    /\ spc \in {"idle", "took", "free", "wrote"}
    /\ zpc \in {"none", "free", "wrote"}
    /\ lastRun \in 0..MaxTime
    /\ runAt \in 0..MaxTime
    /\ rec \in {"none", "held", "freed"}
    /\ freeRunAt \in 0..MaxTime
    /\ ppc \in {"idle", "took", "wrote"}
    /\ placed \in 0..MaxPlace
    /\ relInst \in 0..MaxTime
    /\ relSeen \in BOOLEAN
    /\ faults \in 0..Faults
    /\ bad \in BOOLEAN
    /\ gap \in 0..(GapMax + 1)

Init ==
    /\ now = 0
    /\ holder = "none"
    /\ exp = 0
    /\ hold = FALSE
    /\ content = "readable"
    /\ closed = FALSE
    /\ spc = "idle"
    /\ zpc = "none"
    /\ lastRun = 0
    /\ runAt = 0
    /\ rec = "none"
    /\ freeRunAt = 0
    /\ ppc = "idle"
    /\ placed = 0
    /\ relInst = 0
    /\ relSeen = FALSE
    /\ faults = 0
    /\ bad = FALSE
    /\ gap = 0

\* Time passes, unless a run is due, a lease has run out and the host has not yet released it,
\* or a healthy run in flight would outlast its lease (compensation closure latency 1).
Tick ==
    /\ now < MaxTime
    /\ ~(spc = "idle" /\ now - lastRun >= Cadence)
    /\ ~(holder # "none" /\ now >= exp)
    /\ ~(InFlight /\ now + 1 >= exp)
    /\ (SlowPlacer \/ ppc = "idle")
    /\ now' = now + 1
    /\ gap' = IF rec = "held" /\ ~hold /\ gap <= GapMax THEN gap + 1 ELSE gap
    /\ UNCHANGED <<holder, exp, hold, content, closed, spc, zpc, lastRun, runAt, rec, freeRunAt, ppc, placed, relInst, relSeen, faults, bad>>

\* The host ends a section at the lease's instant (Per-act critical section 4).
HostRelease ==
    /\ holder # "none"
    /\ now >= exp
    /\ holder' = "none"
    /\ UNCHANGED <<now, exp, hold, content, closed, spc, zpc, lastRun, runAt, rec, freeRunAt, ppc, placed, relInst, relSeen, faults, bad, gap>>

\* First half: a run examines the open entry past purge edge and takes the section (First half 2, 6).
SRunTake ==
    /\ spc = "idle"
    /\ ~closed
    /\ now >= Edge
    /\ holder = "none"
    /\ holder' = "scan"
    /\ exp' = now + SweepLease
    /\ spc' = "took"
    /\ lastRun' = now
    /\ runAt' = now
    /\ UNCHANGED <<now, hold, content, closed, zpc, rec, freeRunAt, ppc, placed, relInst, relSeen, faults, bad, gap>>

\* A run that finds the section held, or nothing to examine, skips (Per-act critical section 5).
SRunSkip ==
    /\ spc = "idle"
    /\ (holder # "none" \/ closed \/ now < Edge)
    /\ lastRun' = now
    /\ UNCHANGED <<now, holder, exp, hold, content, closed, spc, zpc, runAt, rec, freeRunAt, ppc, placed, relInst, relSeen, faults, bad, gap>>

\* The re-driven [Purge Event] reads hold under the section (purge event 5c). A hold lands
\* under-legal-hold with nothing changed, and the run's instant goes on the operational record.
SLandHeld ==
    /\ spc = "took"
    /\ Live("scan")
    /\ hold
    /\ rec' = "held"
    /\ spc' = "idle"
    /\ holder' = "none"
    /\ UNCHANGED <<zpc, now, exp, hold, content, closed, lastRun, runAt, freeRunAt, ppc, placed, relInst, relSeen, faults, bad, gap>>

\* No active hold: the run goes on. Where an earlier run landed the entry under-legal-hold, this is
\* the hold-free run, and its instant is recorded (Composition-level invariant 1e, 1h); an entry
\* no run landed under-legal-hold does not restart (Composition-level invariant 1i).
SReadFree ==
    /\ spc = "took"
    /\ Live("scan")
    /\ ~hold
    /\ spc' = "free"
    /\ freeRunAt' = IF rec = "held" THEN runAt ELSE freeRunAt
    /\ rec' = IF rec = "held" THEN "freed" ELSE rec
    /\ gap' = 0
    /\ UNCHANGED <<now, holder, exp, hold, content, closed, zpc, lastRun, runAt, ppc, placed, relInst, relSeen, faults, bad>>

\* Destruction record and delegation, issued on a live lease (Per-act critical section 13b).
SDelegate ==
    /\ spc = "free"
    /\ (GateLive => Live("scan"))
    /\ content' = "destroyed"
    /\ bad' = IF hold /\ content = "readable" THEN TRUE ELSE bad
    /\ spc' = "wrote"
    /\ UNCHANGED <<now, holder, exp, hold, closed, zpc, lastRun, runAt, rec, freeRunAt, ppc, placed, relInst, relSeen, faults, gap>>

\* The destroyed outcome is recorded and the section released.
SOutcome ==
    /\ spc = "wrote"
    /\ Live("scan")
    /\ closed' = TRUE
    /\ spc' = "idle"
    /\ holder' = "none"
    /\ UNCHANGED <<zpc, now, exp, hold, content, lastRun, runAt, rec, freeRunAt, ppc, placed, relInst, relSeen, faults, bad, gap>>

\* A leg whose lease has expired issues no further write and skips (Per-act critical section 13b, 13c).
SAbort ==
    /\ InFlight
    /\ ~Live("scan")
    /\ spc' = "idle"
    /\ UNCHANGED <<zpc, now, holder, exp, hold, content, closed, lastRun, runAt, rec, freeRunAt, ppc, placed, relInst, relSeen, faults, bad, gap>>

\* The budgeted fault: a run dies holding the section, or stalls after its hold read and wakes
\* later under the holder value of its own attempt (Per-act critical section 1c).
SCrash ==
    /\ InFlight
    /\ faults < Faults
    /\ spc' = "idle"
    /\ faults' = faults + 1
    /\ UNCHANGED <<zpc, now, holder, exp, hold, content, closed, lastRun, runAt, rec, freeRunAt, ppc, placed, relInst, relSeen, bad, gap>>

SStall ==
    /\ spc = "free"
    /\ zpc = "none"
    /\ holder = "scan"
    /\ faults < Faults
    /\ zpc' = "free"
    /\ spc' = "idle"
    /\ holder' = "zombie"
    /\ faults' = faults + 1
    /\ UNCHANGED <<now, exp, hold, content, closed, lastRun, runAt, rec, freeRunAt, ppc, placed, relInst, relSeen, bad, gap>>

\* The stalled leg wakes. On a live lease it goes on; on an expired one it writes nothing
\* (Per-act critical section 13b). GateLive = FALSE is the twin that writes anyway.
ZDelegate ==
    /\ zpc = "free"
    /\ (GateLive => Live("zombie"))
    /\ content' = "destroyed"
    /\ bad' = IF hold /\ content = "readable" THEN TRUE ELSE bad
    /\ zpc' = "wrote"
    /\ UNCHANGED <<now, holder, exp, hold, closed, spc, lastRun, runAt, rec, freeRunAt, ppc, placed, relInst, relSeen, faults, gap>>

ZOutcome ==
    /\ zpc = "wrote"
    /\ Live("zombie")
    /\ closed' = TRUE
    /\ zpc' = "none"
    /\ holder' = "none"
    /\ UNCHANGED <<now, exp, hold, content, spc, lastRun, runAt, rec, freeRunAt, ppc, placed, relInst, relSeen, faults, bad, gap>>

ZAbort ==
    /\ zpc # "none"
    /\ ~Live("zombie")
    /\ zpc' = "none"
    /\ UNCHANGED <<now, holder, exp, hold, content, closed, spc, lastRun, runAt, rec, freeRunAt, ppc, placed, relInst, relSeen, faults, bad, gap>>

\* Hold placement: takes the section, waiting for it (Per-act critical section 15a), as a lease of
\* purge completion bound (Capability requirement 7c).
PTake ==
    /\ Serialized
    /\ ppc = "idle"
    /\ placed < MaxPlace
    /\ holder = "none"
    /\ holder' = "placer"
    /\ exp' = now + LeaseLen
    /\ ppc' = "took"
    /\ placed' = placed + 1
    /\ UNCHANGED <<now, hold, content, closed, spc, zpc, lastRun, runAt, rec, freeRunAt, relInst, relSeen, faults, bad, gap>>

\* The hold is written on a live lease (Capability requirement 7d).
PWrite ==
    /\ ppc = "took"
    /\ Live("placer")
    /\ hold' = TRUE
    /\ ppc' = "wrote"
    /\ UNCHANGED <<now, holder, exp, content, closed, spc, zpc, lastRun, runAt, rec, freeRunAt, placed, relInst, relSeen, faults, bad, gap>>

\* The placement returns, having placed or not (Per-act critical section 15b), and releases.
PReturn ==
    /\ ppc # "idle"
    /\ (SlowPlacer \/ ppc = "wrote")
    /\ holder' = IF holder = "placer" THEN "none" ELSE holder
    /\ ppc' = "idle"
    /\ UNCHANGED <<now, exp, hold, content, closed, spc, zpc, lastRun, runAt, rec, freeRunAt, placed, relInst, relSeen, faults, bad, gap>>

\* TWIN ONLY: a placement that writes without the section (Capability requirement 7a dropped).
PWriteFree ==
    /\ ~Serialized
    /\ placed < MaxPlace
    /\ hold' = TRUE
    /\ placed' = placed + 1
    /\ UNCHANGED <<now, holder, exp, content, closed, spc, zpc, lastRun, runAt, rec, freeRunAt, ppc, relInst, relSeen, faults, bad, gap>>

\* The hold is released. The store's release instant is the caller's and may be backdated
\* (Legal Hold Operation 39); the model takes the earliest, instant 0.
Release ==
    /\ hold
    /\ hold' = FALSE
    /\ relSeen' = TRUE
    /\ relInst' = 0
    /\ UNCHANGED <<now, holder, exp, content, closed, spc, zpc, lastRun, runAt, rec, freeRunAt, ppc, placed, faults, bad, gap>>

Next ==
    \/ Tick
    \/ HostRelease
    \/ SRunTake
    \/ SRunSkip
    \/ SLandHeld
    \/ SReadFree
    \/ SDelegate
    \/ SOutcome
    \/ SAbort
    \/ SCrash
    \/ SStall
    \/ ZDelegate
    \/ ZOutcome
    \/ ZAbort
    \/ PTake
    \/ PWrite
    \/ PReturn
    \/ PWriteFree
    \/ Release

Spec == Init /\ [][Next]_vars

\* --- invariants, named as the page names them ---

\* purge event 5b: under a hold no further cascade step executes.
Inv_NoDestroyUnderHold == ~bad

\* The auditor's reading. Suspension: a suspended entry is not counted until the recorded hold-free
\* run (Term suspended entry, First half 9, Composition-level invariant 1e). StoreRelease is the
\* twin's reading: the window restarts at the release instant the Legal Hold store carries.
Counted ==
    IF StoreRelease THEN ~hold
    ELSE IF Suspension THEN (~hold /\ rec # "held")
    ELSE ~hold
Start ==
    IF StoreRelease THEN (IF relSeen THEN relInst ELSE 0)
    ELSE IF rec = "freed" THEN freeRunAt ELSE 0
Inv_BoundedClosure == (~closed /\ Counted) => (now <= Start + Window)

\* First half 10, bounded: once the hold is released, a run reads no active hold within GapMax.
Inv_ReDriveAfterRelease == gap <= GapMax

\* Composition-level invariant 1e, in the stronger form the model can reach inside its horizon:
\* after the recorded hold-free run the entry closes within closure sum's two-run term.
Inv_ClosureAfterRestart == (rec = "freed" /\ ~closed) => (now <= freeRunAt + GapMax)

\* Reachability probes: each is a deliberate falsehood the checker must reject.
Probe_NeverLandsHeld == rec # "held"
Probe_NeverClosesAfterRestart == ~(closed /\ rec = "freed")
Probe_NeverOpenAfterRestart == ~(rec = "freed" /\ ~closed /\ now > freeRunAt + 2)

====
