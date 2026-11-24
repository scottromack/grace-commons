---- MODULE lease-buggy-fence ----
\* BUGGY TWIN: the fence is expires_at bare, the allowance not minted into it (Fence 5, Invariant 6.1 violated).
\* Grace Commons — Lease atom. Spec-level formal sibling of atoms/lease.md.
\* Derived validator; the English spec is the single source of truth. On any disagreement,
\* diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* ONE key on one host clock. Party 1 takes the key for Dur and does two kinds of work under the grant:
\*   - an unfenced write: it asks the host what remains and, on a live reading, issues the write within one
\*     call pause of asking (Sizing 2, 3, 3a); the write lands within one call pause of its issue
\*     (Capability requirement 7);
\*   - a fenced write: issued at any moment, a paused holder waking long after its instant included, and
\*     admitted by the store only where the store's own clock reads before the fence, the store's clock
\*     standing Skew behind the host's (Fence 3, 4, 4a, 5).
\* Party 1 may die silently at any moment, and releases only with no call in flight and writes nothing
\* afterwards (Composition note 5c, 5f). Party 2 arrives at any moment and waits; its take succeeds at the
\* first host reading at which the key is free (State 2, Operation 1a, 2), and it then reads what the key protects.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv_NoLateWrite   no write of party 1 lands after party 2 has read: the reason the atom exists.
\*   Inv_Terminus      a grant ends at its release or at its instant and at nothing else (Invariant 2, Invariant 3).
\*   Inv_WaiterBound   a waiter never stands past its bound (Operation 2, Operation 3, Invariant 4.1).
\*   Inv_OneHolder     two grants on the key are never live at one reading (Invariant 1).
\*
\* THE TWINS, each this file with one constant changed:
\*   -buggy-death     FreeOnDeath = TRUE   the host frees the key on a belief that the holder died (Invariant 3.2).
\*   -buggy-margin    Margin = Pause       a lease reads live on one call pause of margin, not two (Sizing 2).
\*   -buggy-fence     FenceCut = 0         the fence is expires_at bare, the allowance not minted in (Fence 5, Invariant 6.1).
\*   -buggy-release   HoldInFlight = FALSE the holder releases with a call in flight (Composition note 5c).
\*   -probe-both      a reachability probe: both writes land and party 2 reads, in one trace.
\*
\* NOT MODELED: a second waiter and arrival order (Operation 5a, Invariant 4.2); try_take; remaining and
\* release answered to a party that is not the holder (Invariant 5); a host restart (Operation 5c,
\* Capability requirement 5); a unit of work and the share term (Sizing 5, 5a, 6), whose arithmetic the
\* composing patterns' instruments carry; a call delivered twice (Capability requirement 10, 11); the rate
\* at which two clocks drift; a store ahead of the host's clock, which only refuses earlier.
EXTENDS Naturals

CONSTANTS Dur, Pause, Skew, MaxTime, Margin, FenceCut, FreeOnDeath, HoldInFlight

VARIABLES now, holder, exp, exp1, rel1, p1, live, chk, uin, uby, udone, fin, fdone, p2, bound, tookAt, read2, late
vars == <<now, holder, exp, exp1, rel1, p1, live, chk, uin, uby, udone, fin, fdone, p2, bound, tookAt, read2, late>>

TypeOK ==
    /\ now \in 0..MaxTime
    /\ holder \in {"none", "p1", "p2"}
    /\ exp \in 0..(MaxTime + Dur)
    /\ exp1 \in 0..(MaxTime + Dur)
    /\ rel1 \in BOOLEAN
    /\ p1 \in {"idle", "held", "dead", "released"}
    /\ live \in BOOLEAN
    /\ chk \in 0..MaxTime
    /\ uin \in BOOLEAN
    /\ uby \in 0..(MaxTime + Pause)
    /\ udone \in BOOLEAN
    /\ fin \in BOOLEAN
    /\ fdone \in BOOLEAN
    /\ p2 \in {"idle", "waiting", "holding"}
    /\ bound \in 0..(MaxTime + Dur)
    /\ tookAt \in 0..MaxTime
    /\ read2 \in BOOLEAN
    /\ late \in BOOLEAN

Init ==
    /\ now = 0
    /\ holder = "none"
    /\ exp = 0
    /\ exp1 = 0
    /\ rel1 = FALSE
    /\ p1 = "idle"
    /\ live = FALSE
    /\ chk = 0
    /\ uin = FALSE
    /\ uby = 0
    /\ udone = FALSE
    /\ fin = FALSE
    /\ fdone = FALSE
    /\ p2 = "idle"
    /\ bound = 0
    /\ tookAt = 0
    /\ read2 = FALSE
    /\ late = FALSE

\* State 2: free is derived from a passed instant at the reading; the key is free at the reading that equals expires_at.
Free ==
    \/ holder = "none"
    \/ now >= exp
    \/ (FreeOnDeath /\ p1 = "dead")

\* Fence 3, 4, 5: the store admits a work item only where its own clock, Skew behind the host's, reads before the fence.
StoreAdmits == now + FenceCut < exp1 + Skew

\* The clock moves only when the host has answered the waiter it owes (Operation 2) and a landed-by bound is not overrun.
Tick ==
    /\ now < MaxTime
    /\ ~(p2 = "waiting" /\ Free)
    /\ ~(uin /\ now >= uby)
    /\ now' = now + 1
    /\ UNCHANGED <<holder, exp, exp1, rel1, p1, live, chk, uin, uby, udone, fin, fdone, p2, bound, tookAt, read2, late>>

\* Operation 1a, 5a: a take that finds a waiter standing does not pass the waiter.
P1Take ==
    /\ p1 = "idle"
    /\ holder = "none"
    /\ p2 # "waiting"
    /\ holder' = "p1"
    /\ exp' = now + Dur
    /\ exp1' = now + Dur
    /\ p1' = "held"
    /\ UNCHANGED <<now, rel1, live, chk, uin, uby, udone, fin, fdone, p2, bound, tookAt, read2, late>>

\* Sizing 2: the host answers the remaining term, and the reading is live only above the write margin.
P1Ask ==
    /\ p1 = "held"
    /\ holder = "p1"
    /\ ~uin
    /\ ~udone
    /\ exp > now + Margin
    /\ live' = TRUE
    /\ chk' = now
    /\ UNCHANGED <<now, holder, exp, exp1, rel1, p1, uin, uby, udone, fin, fdone, p2, bound, tookAt, read2, late>>

\* Sizing 3a: the write follows its reading within one call pause of asking; Capability requirement 7: it lands within one more.
P1Issue ==
    /\ p1 = "held"
    /\ live
    /\ now <= chk + Pause
    /\ uin' = TRUE
    /\ uby' = now + Pause
    /\ live' = FALSE
    /\ UNCHANGED <<now, holder, exp, exp1, rel1, p1, chk, udone, fin, fdone, p2, bound, tookAt, read2, late>>

ULand ==
    /\ uin
    /\ now <= uby
    /\ uin' = FALSE
    /\ udone' = TRUE
    /\ late' = (late \/ read2)
    /\ UNCHANGED <<now, holder, exp, exp1, rel1, p1, live, chk, uby, fin, fdone, p2, bound, tookAt, read2>>

\* A fenced write is issued with no reading at all: the fence, not the lease, is what stops it.
P1Fenced ==
    /\ p1 = "held"
    /\ ~fin
    /\ ~fdone
    /\ fin' = TRUE
    /\ UNCHANGED <<now, holder, exp, exp1, rel1, p1, live, chk, uin, uby, udone, fdone, p2, bound, tookAt, read2, late>>

FLand ==
    /\ fin
    /\ StoreAdmits
    /\ fin' = FALSE
    /\ fdone' = TRUE
    /\ late' = (late \/ read2)
    /\ UNCHANGED <<now, holder, exp, exp1, rel1, p1, live, chk, uin, uby, udone, p2, bound, tookAt, read2>>

FRefuse ==
    /\ fin
    /\ ~StoreAdmits
    /\ fin' = FALSE
    /\ UNCHANGED <<now, holder, exp, exp1, rel1, p1, live, chk, uin, uby, udone, fdone, p2, bound, tookAt, read2, late>>

\* Composition note 5c: no release with a call in flight. Composition note 5f: nothing is issued after it.
P1Release ==
    /\ p1 = "held"
    /\ holder = "p1"
    /\ (~HoldInFlight \/ (~uin /\ ~fin))
    /\ holder' = "none"
    /\ p1' = "released"
    /\ rel1' = TRUE
    /\ live' = FALSE
    /\ UNCHANGED <<now, exp, exp1, chk, uin, uby, udone, fin, fdone, p2, bound, tookAt, read2, late>>

\* Invariant 3: nothing observes the death; the calls the holder issued stay in flight.
P1Die ==
    /\ p1 = "held"
    /\ p1' = "dead"
    /\ live' = FALSE
    /\ UNCHANGED <<now, holder, exp, exp1, rel1, chk, uin, uby, udone, fin, fdone, p2, bound, tookAt, read2, late>>

P2Arrive ==
    /\ p2 = "idle"
    /\ p2' = "waiting"
    /\ bound' = IF Free THEN now ELSE exp
    /\ UNCHANGED <<now, holder, exp, exp1, rel1, p1, live, chk, uin, uby, udone, fin, fdone, tookAt, read2, late>>

P2Grant ==
    /\ p2 = "waiting"
    /\ Free
    /\ holder' = "p2"
    /\ exp' = now + Dur
    /\ p2' = "holding"
    /\ tookAt' = now
    /\ UNCHANGED <<now, exp1, rel1, p1, live, chk, uin, uby, udone, fin, fdone, bound, read2, late>>

P2Read ==
    /\ p2 = "holding"
    /\ ~read2
    /\ read2' = TRUE
    /\ UNCHANGED <<now, holder, exp, exp1, rel1, p1, live, chk, uin, uby, udone, fin, fdone, p2, bound, tookAt, late>>

Next ==
    \/ Tick
    \/ P1Take
    \/ P1Ask
    \/ P1Issue
    \/ ULand
    \/ P1Fenced
    \/ FLand
    \/ FRefuse
    \/ P1Release
    \/ P1Die
    \/ P2Arrive
    \/ P2Grant
    \/ P2Read

Spec == Init /\ [][Next]_vars

Inv_NoLateWrite == late = FALSE

Inv_Terminus == (p2 = "holding" /\ p1 # "idle" /\ ~rel1) => tookAt >= exp1

\* Invariant 1, asserted from the two grants' own instants and not from the one variable that names the holder.
Grant1Live == (p1 = "held" \/ p1 = "dead") /\ ~rel1 /\ now < exp1
Grant2Live == p2 = "holding" /\ now < exp
Inv_OneHolder == ~(Grant1Live /\ Grant2Live)

Inv_WaiterBound == (p2 = "waiting") => now <= bound

Probe_NeverBoth == ~(udone /\ fdone /\ read2)
====
