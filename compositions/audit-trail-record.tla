---- MODULE audit-trail-record ----
\* Grace Commons — Audit Trail composition, record-action leg. Spec-level formal sibling of
\* compositions/audit-trail.md; the cascade leg is audit-trail.tla. Derived validator; the English
\* spec is the single source of truth. On any disagreement, diagnose per the entry
\* *The conflict protocol* in pressure-testing.md.
\*
\* ONE [Record Action], one step: Execution Contract Database 1 commits its attest, append and placement
\* together (Capability requirement 13), so the step lands the record whole, or the evidence its
\* refusal keeps — the attestation alone at invalid-request(step-3), the attestation and the event at
\* invalid-request(step-4) (record action step 7.11) — or nothing, a storage failure or a crash
\* committing none of it. No scan run meets a record action in flight. TWO scan runs are second
\* processes: the second half (an orphan attestation, Second half 1-13) and the third half (an
\* unretained event, Third half 1-15), each taking the section keyed by the act, pre-checking under it,
\* writing an intent before its repair and one compensation after, each with a lease of compensation
\* closure latency, stopping at expiry (Per-act critical section 13).
\*
\* WHAT THIS MODEL CHECKS  Invariants 1 and 2 (attest first, event first, orphan- and
\* unretained-event closure bounded by closure sum, which budgets one dead scan run), and the
\* one-writer discipline between scan runs (one placement, one intent, one compensation per finding;
\* a compensated orphan never acquires its event, which the twin -split shows rests on Database 1).
\*
\* NOT MODELED
\* - The carried ids of record action step 7.15 and 7.16 and the two-call margin of Term lease are not modelled.
\* - The call pause bound margin: the model's lease is live until its tick, so the margin is zero (call pause bound 1).
\* - The lease call kind and a take with no answer (Per-act critical section 15, 16) are not modelled.
\* - Invariant 1.10's circuit break is carried only as far as the compensation being one write; the run's end
\*   at the first refusal that left an orphan, and [Read Record] step 4.5 and 4.6, are not modelled.
\* - Invariant 8, the cascade and the first half: audit-trail.tla. The beyond-horizon report and the
\*   horizon. Invariants 3, 5, 6 and 7, [Read Record] and [Verify Record], and the return arms of step 7.
\* - The compensating record is one write; the page's own record-action steps inside it, and the
\*   compensation's recursion (it is itself a [Record Action]), are not carried. Step 5 indexes.
\* - The restart-triggered scan run; the single scan-crash budget is shared by both runs.
\* - Where the model is more generous than the page: a write issued inside the lease lands inside it
\*   (a stalled write the page lets land later, refused once the next holder takes the section, its
\*   lease check and the write being one transaction, Capability requirement 13); clock
\*   offset allowance 0; narrated is a flag, not a read of the log.
\* - The leg abort (Per-act critical section 13b, 13c) is NOT exercised: SAbort1 and SAbort2 are
\*   unreachable, because Tick holds time while a run is in flight (compensation closure latency 1),
\*   so no leg outlives its lease. The page's abort arm is unverified here and in audit-trail.tla.
\* - The binding-set predicate against an in-flight cascade (Second half 14, Second half 15):
\*   audit-trail-binding.tla. The scan's retry of an invalid-request refusal on the next run
\*   (Compensation 15), and Tamper Evidence's record set match (Capability requirement 5): not carried.
\* - Not carried, each on the page and unverified here: the Legal Hold gate over a first cascade (purge event 5c; over a re-driven entry, with the placement's
\*   serialization and the hold-release restart, it is audit-trail-hold.tla's); the [Seal Now] crash gap and its rebuild (seal now 13 through 20, Concurrency 1a through 1d, the sealing lock's lease); the start checks Instance start 21 and 22 (horizon); a leg's placement or a seal abandoned is refused once the next holder takes the section, its lease check and its write being one transaction (Capability requirement 13), so no model carries it; the cascade's erasure delegation abandoned (Per-act critical section 2a) is carried by no model; scan run duration (compensation closure latency 3) is not modelled, runs being instantaneous; the [Verify Record] re-read against a
\*   racing cascade (verify record 5, 6); the in-flight arm of [Purge Event] (purge event step 0.7); the third half's
\*   policy resolution (Third half 15). Both models are single-act: the cross-act serialization of Concurrency 1 is
\*   absent, and Invariant 3 is unmodelled.
\* - The constants breach Instance start 18 and 19 (SweepLease = 1 against a closure floor of 4); a conforming regime exceeds the harness's depth cap; the arithmetic at conforming constants is carried by tools/harness/audit-trail-closure.py.
\*   Also not carried: the scan's
\*   one attempt per finding per run and its alert (Third half 11, Compensation 16);
\*   a caller-driven re-entry of [Purge Event] on a Purged retention (purge event step 1.4).
\* - Small constants: "all invariants hold" is a statement within MaxTime ticks at these constants.
EXTENDS Naturals

CONSTANTS RecBound, SweepLease, Cadence, MaxTime

VARIABLES now, ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2
vars == <<now, ipc, holder, exp, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

ClosureBound == 2 * RecBound + 2 * (Cadence + SweepLease)   \* the page's closure sum: max(2 * record bound, purge bound) + allowance + 2 * (cadence + closure latency)

Live(who) == holder = who /\ now < exp

TypeOK ==
    /\ now \in 0..MaxTime
    /\ ipc \in {"idle", "done"}
    /\ holder \in {"none", "s1", "s2"}
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

\* [Record Action], one step under Execution Contract Database 1: the record lands whole; or a refusal at step 3 keeps
\* the attestation and a refusal at step 4 the attestation and the event, written in the refusal's own transaction
\* (record action step 7.11); or a storage failure or a crash commits nothing.
IRecord ==
    /\ ipc = "idle"
    /\ ipc' = "done"
    /\ \/ /\ att' = TRUE
          /\ attAt' = now
          /\ ev' = TRUE
          /\ evAt' = now
          /\ plc' = 1
       \/ /\ att' = TRUE
          /\ attAt' = now
          /\ UNCHANGED <<ev, evAt, plc>>
       \/ /\ att' = TRUE
          /\ attAt' = now
          /\ ev' = TRUE
          /\ evAt' = now
          /\ UNCHANGED plc
       \/ UNCHANGED <<att, attAt, ev, evAt, plc>>
    /\ UNCHANGED <<now, holder, exp, nO, cO, nU, cU, crashes, spc1, tgt1, lr1, spc2, tgt2, lr2>>

\* Second half: an attestation absent from the binding set (Second half 1, 2); takes the critical section keyed by its id.
TakeOrphan1 ==
    /\ spc1 = "idle"
    /\ holder = "none"
    /\ att /\ ~ev
    /\ holder' = "s1"
    /\ exp' = now + SweepLease
    /\ spc1' = "held"
    /\ tgt1' = "O"
    /\ lr1' = now
    /\ UNCHANGED <<now, ipc, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc2, tgt2, lr2>>

\* Third half: an event with no retention (Third half 1-3); takes the critical section keyed by its payload attestation id (Third half 5).
TakeUnretained1 ==
    /\ spc1 = "idle"
    /\ holder = "none"
    /\ ev /\ plc = 0
    /\ holder' = "s1"
    /\ exp' = now + SweepLease
    /\ spc1' = "held"
    /\ tgt1' = "U"
    /\ lr1' = now
    /\ UNCHANGED <<now, ipc, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc2, tgt2, lr2>>

\* A run that finds the section held or nothing to examine skips (Per-act critical section 5).
Skip1 ==
    /\ spc1 = "idle"
    /\ (holder # "none" \/ ~(att /\ ~ev) /\ ~(ev /\ plc = 0))
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

\* Second half: an attestation absent from the binding set (Second half 1, 2); takes the critical section keyed by its id.
TakeOrphan2 ==
    /\ spc2 = "idle"
    /\ holder = "none"
    /\ att /\ ~ev
    /\ holder' = "s2"
    /\ exp' = now + SweepLease
    /\ spc2' = "held"
    /\ tgt2' = "O"
    /\ lr2' = now
    /\ UNCHANGED <<now, ipc, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1>>

\* Third half: an event with no retention (Third half 1-3); takes the critical section keyed by its payload attestation id (Third half 5).
TakeUnretained2 ==
    /\ spc2 = "idle"
    /\ holder = "none"
    /\ ev /\ plc = 0
    /\ holder' = "s2"
    /\ exp' = now + SweepLease
    /\ spc2' = "held"
    /\ tgt2' = "U"
    /\ lr2' = now
    /\ UNCHANGED <<now, ipc, att, attAt, ev, evAt, plc, nO, cO, nU, cU, crashes, spc1, tgt1, lr1>>

\* A run that finds the section held or nothing to examine skips (Per-act critical section 5).
Skip2 ==
    /\ spc2 = "idle"
    /\ (holder # "none" \/ ~(att /\ ~ev) /\ ~(ev /\ plc = 0))
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
    \/ IRecord
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

\* A compensated orphan never acquires an event afterwards (Second half 9-10; Execution Contract Database 1).
Inv1_NoLateEvent == (cO > 0) => ~ev

\* One writer per act: one placement, one intent and one compensation per finding
\* (Compensation 2, 11; Second half 13; Concurrency 9).
Inv_OneWriter == plc <= 1 /\ nO <= 1 /\ cO <= 1 /\ nU <= 1 /\ cU <= 1

\* Invariants 1.4 and 2 liveness arms, bounded: an orphan or an unretained event older
\* than the closure bound has been closed.
Inv_BoundedClosure ==
    /\ (att /\ ~ev /\ now >= attAt + ClosureBound) => (cO > 0)
    /\ (ev /\ now >= evAt + ClosureBound) => (plc > 0)

Safety == TypeOK /\ Inv1_AttestFirst /\ Inv2_EventFirst /\ Inv1_NoLateEvent /\ Inv_OneWriter /\ Inv_BoundedClosure

====
