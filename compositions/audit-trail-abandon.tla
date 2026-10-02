---- MODULE audit-trail-abandon ----
\* A holder that abandons a constituent call and returns (Per-act critical section 2a, Concurrency 1e).
\* Two legs of the scan contend for one act's critical section, a lease. Leg 1 pre-checks, issues one truth-bearing write
\* (modelled as the third half's placement; a seal is the same shape and is not separately modelled) and the host abandons the call at its own timeout; the write lands at some tick
\* inside the lease (the page's premise, record action completion bound 2, compensation closure latency 2).
\* Leg 2, the next run, takes the section, re-reads the pre-check and writes if it still reads a miss.
\* The cure: leg 1 does not release before the lease's instant, so leg 2 cannot read the pre-check until the write has landed.
\* NOT MODELED: the cascade's step 1 and its erasure delegation, a hold placement and its own write, the record action; everything else; audit-trail.tla and audit-trail-record.tla carry the cascade and the record action.
EXTENDS Naturals

VARIABLES now, holder, exp, landBy, plc, infl, st1, st2
vars == <<now, holder, exp, landBy, plc, infl, st1, st2>>

TypeOK ==
    /\ now \in 0..4
    /\ holder \in {"none", "l1", "l2"}
    /\ exp \in 0..7
    /\ landBy \in 0..7
    /\ plc \in 0..2
    /\ infl \in BOOLEAN
    /\ st1 \in {"idle", "issued", "done"}
    /\ st2 \in {"idle", "placing", "done"}

Init ==
    /\ now = 0
    /\ holder = "none"
    /\ exp = 0
    /\ landBy = 0
    /\ plc = 0
    /\ infl = FALSE
    /\ st1 = "idle"
    /\ st2 = "idle"

Tick ==
    /\ now < 4
    /\ now' = now + 1
    /\ UNCHANGED <<holder, exp, landBy, plc, infl, st1, st2>>

\* Leg 1: take, pre-check reads a miss (plc = 0), issue the placement; lease of length 3.
L1Take ==
    /\ st1 = "idle"
    /\ holder = "none"
    /\ plc = 0
    /\ holder' = "l1"
    /\ exp' = now + 3
    /\ landBy' = now + 3
    /\ infl' = TRUE
    /\ st1' = "issued"
    /\ UNCHANGED <<now, plc, st2>>

\* The host abandons the call and leg 1 returns. Per-act critical section 2a: no release before the lease's instant.
L1Release ==
    /\ st1 = "issued"
    /\ holder = "l1"
    /\ now >= exp
    /\ holder' = "none"
    /\ st1' = "done"
    /\ UNCHANGED <<now, exp, landBy, plc, infl, st2>>

\* The abandoned write lands at a tick inside the lease.
Land ==
    /\ infl
    /\ now < landBy
    /\ plc' = plc + 1
    /\ infl' = FALSE
    /\ UNCHANGED <<now, holder, exp, landBy, st1, st2>>

\* Leg 2: take, re-read the pre-check under the section, place on a miss.
L2Take ==
    /\ st2 = "idle"
    /\ holder = "none"
    /\ plc = 0
    /\ holder' = "l2"
    /\ exp' = now + 3
    /\ st2' = "placing"
    /\ UNCHANGED <<now, landBy, plc, infl, st1>>

L2Place ==
    /\ st2 = "placing"
    /\ plc' = plc + 1
    /\ holder' = "none"
    /\ st2' = "done"
    /\ UNCHANGED <<now, exp, landBy, infl, st1>>

Next == Tick \/ L1Take \/ L1Release \/ Land \/ L2Take \/ L2Place

Spec == Init /\ [][Next]_vars

\* EXACTLY ONE placement (Invariant 2.4a) and one covering seal (Invariant 3.1), whichever write the leg issued.
Inv_ExactlyOne == plc <= 1
====
