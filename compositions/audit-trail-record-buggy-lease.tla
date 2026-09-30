---- MODULE audit-trail-record-buggy-lease ----
\* BUGGY TWIN (vacuity guard): the invocation never notices its lease has gone and keeps writing after a scan half compensated the act (Per-act critical section 9b violated).
EXTENDS Naturals

CONSTANTS RecBound, SweepLease, Cadence, MaxTime

VARIABLES now, ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2
vars == <<now, ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

Edge == RecBound   \* record edge = record action completion bound + clock offset allowance (0 here)
ClosureBound == Edge + 2 * (Cadence + SweepLease)

Live(who) == holder = who /\ now < exp

TypeOK ==
    /\ now \in 0..MaxTime
    /\ ipc \in {"idle", "a2", "a3", "a4", "done", "dead"}
    /\ holder \in {"none", "inv", "s1", "s2"}
    /\ exp \in 0..(MaxTime + RecBound + SweepLease)
    /\ att \in BOOLEAN
    /\ attAt \in 0..MaxTime
    /\ ev \in BOOLEAN
    /\ evAt \in 0..MaxTime
    /\ plc \in 0..3
    /\ nO \in 0..3
    /\ cO \in 0..3
    /\ nU \in 0..3
    /\ cU \in 0..3
    /\ crashes \in 0..1
    /\ spc1 \in {"idle", "held", "w1", "w2", "w3"}
    /\ spc2 \in {"idle", "held", "w1", "w2", "w3"}
    /\ tgt1 \in {"none", "O", "U"}
    /\ tgt2 \in {"none", "O", "U"}
    /\ lr1 \in 0..MaxTime
    /\ lr2 \in 0..MaxTime

Init ==
    /\ now = 0
    /\ ipc = "idle"
    /\ holder = "none"
    /\ exp = 0
    /\ att = FALSE
    /\ attAt = 0
    /\ ev = FALSE
    /\ evAt = 0
    /\ plc = 0
    /\ nO = 0
    /\ cO = 0
    /\ nU = 0
    /\ cU = 0
    /\ crashes = 0
    /\ spc1 = "idle"
    /\ spc2 = "idle"
    /\ tgt1 = "none"
    /\ tgt2 = "none"
    /\ lr1 = 0
    /\ lr2 = 0

\* Time passes, unless a scan run is due, the host has a lease to release, or a scan run in flight would outlast its lease
\* (compensation closure latency 1).
Tick ==
    /\ now < MaxTime
    /\ ~(spc1 = "idle" /\ now - lr1 >= Cadence)
    /\ ~(spc2 = "idle" /\ now - lr2 >= Cadence)
    /\ ~(holder # "none" /\ now >= exp)
    /\ ~(spc1 # "idle" /\ now + 1 >= exp)
    /\ ~(spc2 # "idle" /\ now + 1 >= exp)
    /\ now' = now + 1
    /\ UNCHANGED <<ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* Host: a lease that has run out is released (Per-act critical section 4).
HostRelease ==
    /\ holder # "none"
    /\ now >= exp
    /\ holder' = "none"
    /\ UNCHANGED <<now, ipc, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* [Record Action]: the critical section is taken at the act's first write, keyed by the attestation id (Concurrency 6).
IStart ==
    /\ ipc = "idle"
    /\ holder = "none"
    /\ ipc' = "a2"
    /\ holder' = "inv"
    /\ exp' = now + RecBound
    /\ UNCHANGED <<now, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* Step 2: attest (Invariant 1.2: attest before append).
IAttest ==
    /\ ipc = "a2"
    /\ ipc # "idle" /\ ipc # "dead" /\ ipc # "done"
    /\ att' = TRUE
    /\ attAt' = now
    /\ ipc' = "a3"
    /\ UNCHANGED <<now, holder, exp, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* Step 3: append, the attestation id inside the payload.
IAppend ==
    /\ ipc = "a3"
    /\ ipc # "idle" /\ ipc # "dead" /\ ipc # "done"
    /\ att
    /\ ev' = TRUE
    /\ evAt' = now
    /\ ipc' = "a4"
    /\ UNCHANGED <<now, holder, exp, att, attAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* Step 4: place under retention; re-reads event to retention first and adopts a placement that landed (record action step 4.1-4.2).
IPlace ==
    /\ ipc = "a4"
    /\ ipc # "idle" /\ ipc # "dead" /\ ipc # "done"
    /\ plc' = IF plc = 0 THEN 1 ELSE plc + 1
    /\ ipc' = "done"
    /\ holder' = IF holder = "inv" THEN "none" ELSE holder
    /\ UNCHANGED <<now, exp, att, attAt, ev, evAt, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* Mid-record expiry (record action step 7.6): no further write; the partial state is the scan's.
IAbort ==
    /\ FALSE
    /\ ipc' = "dead"
    /\ UNCHANGED <<now, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* The invocation may die at any point.
ICrash ==
    /\ ipc \in {"a2", "a3", "a4"}
    /\ ipc' = "dead"
    /\ UNCHANGED <<now, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* Second half: an attestation absent from the binding set and older than record edge (Second half 1-3); takes the critical section keyed by its id.
TakeOrphan1 ==
    /\ spc1 = "idle"
    /\ holder = "none"
    /\ att /\ ~ev
    /\ now - attAt >= Edge
    /\ holder' = "s1"
    /\ exp' = now + SweepLease
    /\ spc1' = "held"
    /\ tgt1' = "O"
    /\ lr1' = now
    /\ UNCHANGED <<now, ipc, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc2, tgt2, lr2>>

\* Third half: an event with no retention, older than record edge (Third half 4-5); takes the critical section keyed by its payload attestation id.
TakeUnretained1 ==
    /\ spc1 = "idle"
    /\ holder = "none"
    /\ ev /\ plc = 0
    /\ now - evAt >= Edge
    /\ holder' = "s1"
    /\ exp' = now + SweepLease
    /\ spc1' = "held"
    /\ tgt1' = "U"
    /\ lr1' = now
    /\ UNCHANGED <<now, ipc, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc2, tgt2, lr2>>

\* A run that finds the section held or nothing to examine skips (Per-act critical section 5).
Skip1 ==
    /\ spc1 = "idle"
    /\ (holder # "none" \/ ~(att /\ ~ev /\ now - attAt >= Edge) /\ ~(ev /\ plc = 0 /\ now - evAt >= Edge))
    /\ lr1' = now
    /\ UNCHANGED <<now, ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, spc2, tgt2, lr2>>

\* Re-read compensated attestations / event to retention under the section before any write (Second half 9, Third half 6).
Check1 ==
    /\ spc1 = "held"
    /\ Live("s1")
    /\ spc1' = IF tgt1 = "O" THEN (IF cO > 0 THEN "idle" ELSE "w1") ELSE (IF cU > 0 /\ plc > 0 THEN "idle" ELSE "w1")
    /\ holder' = IF (tgt1 = "O" /\ cO > 0) \/ (tgt1 = "U" /\ cU > 0 /\ plc > 0) THEN "none" ELSE holder
    /\ UNCHANGED <<now, ipc, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, tgt1, lr1, spc2, tgt2, lr2>>

\* Intent record (audit.reconciliation), once per finding: narrated is read first (Compensation 9-11).
Intent1 ==
    /\ spc1 = "w1"
    /\ Live("s1")
    /\ nO' = IF tgt1 = "O" /\ nO = 0 THEN 1 ELSE nO
    /\ nU' = IF tgt1 = "U" /\ nU = 0 THEN 1 ELSE nU
    /\ spc1' = "w2"
    /\ UNCHANGED <<now, ipc, holder, exp, att, attAt, ev, evAt, plc, cO, cU, crashes, tgt1, lr1, spc2, tgt2, lr2>>

\* The compensating act: for an unretained event, the placement (only where none exists).
Repair1 ==
    /\ spc1 = "w2"
    /\ Live("s1")
    /\ plc' = IF tgt1 = "U" /\ plc = 0 THEN 1 ELSE plc
    /\ spc1' = "w3"
    /\ UNCHANGED <<now, ipc, holder, exp, att, attAt, ev, evAt, nO, cO, nU, cU, crashes, tgt1, lr1, spc2, tgt2, lr2>>

\* The audit.compensation record closes the finding; the section is released.
Compensate1 ==
    /\ spc1 = "w3"
    /\ Live("s1")
    /\ cO' = IF tgt1 = "O" THEN cO + 1 ELSE cO
    /\ cU' = IF tgt1 = "U" THEN cU + 1 ELSE cU
    /\ spc1' = "idle"
    /\ holder' = "none"
    /\ UNCHANGED <<now, ipc, exp, att, attAt, ev, evAt, plc, nO, nU, crashes, tgt1, lr1, spc2, tgt2, lr2>>

\* A scan run whose lease is gone abandons the run.
SAbort1 ==
    /\ spc1 # "idle"
    /\ ~Live("s1")
    /\ spc1' = "idle"
    /\ UNCHANGED <<now, ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, tgt1, lr1, spc2, tgt2, lr2>>

\* The scan run may die once.
SCrash1 ==
    /\ spc1 # "idle"
    /\ crashes < 1
    /\ spc1' = "idle"
    /\ crashes' = crashes + 1
    /\ UNCHANGED <<now, ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, tgt1, lr1, spc2, tgt2, lr2>>

\* Second half: an attestation absent from the binding set and older than record edge (Second half 1-3); takes the critical section keyed by its id.
TakeOrphan2 ==
    /\ spc2 = "idle"
    /\ holder = "none"
    /\ att /\ ~ev
    /\ now - attAt >= Edge
    /\ holder' = "s2"
    /\ exp' = now + SweepLease
    /\ spc2' = "held"
    /\ tgt2' = "O"
    /\ lr2' = now
    /\ UNCHANGED <<now, ipc, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1>>

\* Third half: an event with no retention, older than record edge (Third half 4-5); takes the critical section keyed by its payload attestation id.
TakeUnretained2 ==
    /\ spc2 = "idle"
    /\ holder = "none"
    /\ ev /\ plc = 0
    /\ now - evAt >= Edge
    /\ holder' = "s2"
    /\ exp' = now + SweepLease
    /\ spc2' = "held"
    /\ tgt2' = "U"
    /\ lr2' = now
    /\ UNCHANGED <<now, ipc, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1>>

\* A run that finds the section held or nothing to examine skips (Per-act critical section 5).
Skip2 ==
    /\ spc2 = "idle"
    /\ (holder # "none" \/ ~(att /\ ~ev /\ now - attAt >= Edge) /\ ~(ev /\ plc = 0 /\ now - evAt >= Edge))
    /\ lr2' = now
    /\ UNCHANGED <<now, ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2>>

\* Re-read compensated attestations / event to retention under the section before any write (Second half 9, Third half 6).
Check2 ==
    /\ spc2 = "held"
    /\ Live("s2")
    /\ spc2' = IF tgt2 = "O" THEN (IF cO > 0 THEN "idle" ELSE "w1") ELSE (IF cU > 0 /\ plc > 0 THEN "idle" ELSE "w1")
    /\ holder' = IF (tgt2 = "O" /\ cO > 0) \/ (tgt2 = "U" /\ cU > 0 /\ plc > 0) THEN "none" ELSE holder
    /\ UNCHANGED <<now, ipc, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, tgt2, lr2>>

\* Intent record (audit.reconciliation), once per finding: narrated is read first (Compensation 9-11).
Intent2 ==
    /\ spc2 = "w1"
    /\ Live("s2")
    /\ nO' = IF tgt2 = "O" /\ nO = 0 THEN 1 ELSE nO
    /\ nU' = IF tgt2 = "U" /\ nU = 0 THEN 1 ELSE nU
    /\ spc2' = "w2"
    /\ UNCHANGED <<now, ipc, holder, exp, att, attAt, ev, evAt, plc, cO, cU, crashes, spc1, tgt1, lr1, tgt2, lr2>>

\* The compensating act: for an unretained event, the placement (only where none exists).
Repair2 ==
    /\ spc2 = "w2"
    /\ Live("s2")
    /\ plc' = IF tgt2 = "U" /\ plc = 0 THEN 1 ELSE plc
    /\ spc2' = "w3"
    /\ UNCHANGED <<now, ipc, holder, exp, att, attAt, ev, evAt, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, tgt2, lr2>>

\* The audit.compensation record closes the finding; the section is released.
Compensate2 ==
    /\ spc2 = "w3"
    /\ Live("s2")
    /\ cO' = IF tgt2 = "O" THEN cO + 1 ELSE cO
    /\ cU' = IF tgt2 = "U" THEN cU + 1 ELSE cU
    /\ spc2' = "idle"
    /\ holder' = "none"
    /\ UNCHANGED <<now, ipc, exp, att, attAt, ev, evAt, plc, nO, nU, crashes, spc1, tgt1, lr1, tgt2, lr2>>

\* A scan run whose lease is gone abandons the run.
SAbort2 ==
    /\ spc2 # "idle"
    /\ ~Live("s2")
    /\ spc2' = "idle"
    /\ UNCHANGED <<now, ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, tgt2, lr2>>

\* The scan run may die once.
SCrash2 ==
    /\ spc2 # "idle"
    /\ crashes < 1
    /\ spc2' = "idle"
    /\ crashes' = crashes + 1
    /\ UNCHANGED <<now, ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, spc1, tgt1, lr1, tgt2, lr2>>

Next ==
    \/ Tick
    \/ HostRelease
    \/ IStart
    \/ IAttest
    \/ IAppend
    \/ IPlace
    \/ IAbort
    \/ ICrash
    \/ TakeOrphan1
    \/ TakeUnretained1
    \/ Skip1
    \/ Check1
    \/ Intent1
    \/ Repair1
    \/ Compensate1
    \/ SAbort1
    \/ SCrash1
    \/ TakeOrphan2
    \/ TakeUnretained2
    \/ Skip2
    \/ Check2
    \/ Intent2
    \/ Repair2
    \/ Compensate2
    \/ SAbort2
    \/ SCrash2

Spec == Init /\ [][Next]_vars

\* --- invariants, named as the page names them ---

\* Invariant 1.2, 2: attest before append, append before placement.
Inv1_AttestFirst == ev => att
Inv2_EventFirst == (plc > 0) => ev

\* A compensated orphan never acquires an event afterwards (Second half 9-10 against a late step 3).
Inv1_NoLateEvent == (cO > 0) => ~ev

\* One writer per act: one placement, one intent and one compensation per finding
\* (Compensation 2, 11; Second half 13; Concurrency 6, 9).
Inv_OneWriter == plc <= 1 /\ nO <= 1 /\ cO <= 1 /\ nU <= 1 /\ cU <= 1

\* Invariants 1.4 and 2 liveness arms, bounded: an orphan or an unretained event older
\* than the closure bound has been closed.
Inv_BoundedClosure ==
    /\ (att /\ ~ev /\ now >= attAt + ClosureBound) => (cO > 0)
    /\ (ev /\ now >= evAt + ClosureBound) => (plc > 0)

Safety == TypeOK /\ Inv1_AttestFirst /\ Inv2_EventFirst /\ Inv1_NoLateEvent /\ Inv_OneWriter /\ Inv_BoundedClosure

====
