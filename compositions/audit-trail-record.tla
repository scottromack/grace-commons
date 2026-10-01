---- MODULE audit-trail-record ----
\* Grace Commons — Audit Trail composition, record-action leg. Spec-level formal sibling of
\* compositions/audit-trail.md; the cascade leg is audit-trail.tla. Derived validator; the English
\* spec is the single source of truth. On any disagreement, diagnose per the entry
\* *The conflict protocol* in pressure-testing.md.
\*
\* ONE [Record Action]: attest (no critical section yet — its key is the attestation id step 2
\* returns), then take the section (record action step 2.6; refused if held, step 2.9), then append
\* only after reading compensated attestations under the section (step 3.5, 3.6), then place — under
\* a lease that begins at the take, a holder that may die, and mid-record expiry. TWO scan runs are
\* second processes: the second half (an orphan attestation, Second half 1-13) and the third half
\* (an unretained event, Third half 1-14), each older than record edge, each taking the section,
\* pre-checking under it, writing an intent before its repair and one compensation after, each with
\* a lease of compensation closure latency, stopping at expiry (Per-act critical section 13).
\*
\* WHAT THIS MODEL CHECKS  Invariants 1 and 2 (attest first, event first, orphan- and
\* unretained-event closure bounded by closure sum, which budgets one dead scan run), and the
\* one-writer discipline (one placement, one intent, one compensation per finding; a compensated
\* orphan never acquires its event).
\*
\* NOT MODELED
\* - Invariant 8, the cascade and the first half: audit-trail.tla. The beyond-horizon report and the
\*   horizon. Invariants 3, 5, 6 and 7, [Read Record] and [Verify Record], and the return arms of step 7.
\* - The compensating record is one write; the page's own record-action steps inside it, and the
\*   compensation's recursion (it is itself a [Record Action]), are not carried. Step 5 indexes.
\* - The restart-triggered scan run; the single scan-crash budget is shared by both runs.
\* - Where the model is more generous than the page: a write issued inside the lease lands inside it
\*   (the page's premise, made an obligation by record action completion bound 2: the pause between a
\*   lease check and its write is inside the bound; no constituent write carries a fence); clock
\*   offset allowance 0; narrated is a flag, not a read of the log.
\* - SweepLease = 1 here: a leg finishes in the tick it takes the section, so a leg that overruns its
\*   lease (Per-act critical section 13) is carried by audit-trail.tla, where SweepLease = 2.
\* - Small constants: "all invariants hold" is a statement within MaxTime ticks at these constants.
EXTENDS Naturals

CONSTANTS RecBound, SweepLease, Cadence, MaxTime

VARIABLES now, ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2
vars == <<now, ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

Edge == RecBound   \* record edge = record action completion bound + clock offset allowance (0 here)
ClosureBound == 2 * RecBound + 2 * (Cadence + SweepLease)   \* the page's closure sum: max(2 * record bound, purge bound) + allowance + 2 * (cadence + closure latency)

Live(who) == holder = who /\ now < exp

TypeOK ==
    /\ now \in 0..MaxTime
    /\ ipc \in {"idle", "t", "a3", "a4", "done", "dead"}
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

\* Step 2: attest. The critical section does not exist yet: its key is the attestation id this step returns (Per-act critical section, record action step 2.6).
IAttest ==
    /\ ipc = "idle"
    /\ att' = TRUE
    /\ attAt' = now
    /\ ipc' = "t"
    /\ UNCHANGED <<now, holder, exp, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* Step 2.6: take the section keyed by the attestation id; the lease begins here, after the attestation committed.
ITake ==
    /\ ipc = "t"
    /\ holder = "none"
    /\ now - attAt < RecBound
    /\ ipc' = "a3"
    /\ holder' = "inv"
    /\ exp' = now + RecBound
    /\ UNCHANGED <<now, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* record action step 2.10-2.11: the invocation has outlived record action completion bound, takes no section and appends nothing.
IOutlived ==
    /\ ipc = "t"
    /\ now - attAt >= RecBound
    /\ ipc' = "dead"
    /\ UNCHANGED <<now, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* record action step 2.9: the section is held (a scan half has it), so the invocation does not append; mid-record expiry arm.
IHeld ==
    /\ ipc = "t"
    /\ holder # "none"
    /\ ipc' = "dead"
    /\ UNCHANGED <<now, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* Step 3: append, after reading compensated attestations under the held section (record action step 3.5, 3.6).
IAppend ==
    /\ ipc = "a3"
    /\ Live("inv")
    /\ att
    /\ cO = 0
    /\ ev' = TRUE
    /\ evAt' = now
    /\ ipc' = "a4"
    /\ UNCHANGED <<now, holder, exp, att, attAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* record action step 3.6: the orphan was already compensated, nothing is appended, the section is released.
IRefused ==
    /\ ipc = "a3"
    /\ Live("inv")
    /\ cO > 0
    /\ ipc' = "dead"
    /\ holder' = IF holder = "inv" THEN "none" ELSE holder
    /\ UNCHANGED <<now, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* Step 4: place under retention; re-reads event to retention first and adopts a placement that landed (record action step 4.1-4.2).
IPlace ==
    /\ ipc = "a4"
    /\ Live("inv")
    /\ plc' = IF plc = 0 THEN 1 ELSE plc + 1
    /\ ipc' = "done"
    /\ holder' = IF holder = "inv" THEN "none" ELSE holder
    /\ UNCHANGED <<now, exp, att, attAt, ev, evAt, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* Mid-record expiry (record action step 7.6): no further write; the partial state is the scan's.
IAbort ==
    /\ ipc \in {"a3", "a4"}
    /\ ~Live("inv")
    /\ ipc' = "dead"
    /\ UNCHANGED <<now, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* The invocation may die at any point.
ICrash ==
    /\ ipc \in {"t", "a3", "a4"}
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

\* A scan run whose lease is gone abandons the run (Per-act critical section 13b, 13c).
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

\* A scan run whose lease is gone abandons the run (Per-act critical section 13b, 13c).
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
    \/ IAttest
    \/ ITake
    \/ IOutlived
    \/ IHeld
    \/ IAppend
    \/ IRefused
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
