---- MODULE audit-trail ----
\* Grace Commons — Audit Trail composition. Spec-level formal sibling of compositions/audit-trail.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* VERSION 2. v1 performed the cascade as ONE atomic action, which the page forbids
\* claiming (Invariant 4.3) and which supplied the care a careful implementer would
\* (the model was more disciplined than the page). v2 carries the cascade as the page
\* writes it: steps 0, 1, 2, 3 as separate commits in the declared order (Invariant 4.2),
\* under a per-act critical section that is a lease (Per-act critical section 4, 9),
\* a holder that may die at any point, mid-cascade expiry (purge event 7), and the
\* reconciliation scan's first half as a second process: it examines a Purged retention
\* older than purge edge, skips a held section (Per-act critical section 5), re-reads the
\* predicate under the section (First half 7), and re-drives from step 2 adopting what
\* landed (proceed as landed), on a cadence, and may itself die once.
\*
\* WHAT THIS MODEL CHECKS  Invariants 4 (order), 8 (honest destruction; and its liveness
\* arm, bounded), and the one-writer discipline of the per-act critical section.
\*
\* NOT MODELED (Ledger 2026-08-30-e stays open for these)
\* - [Record Action], and the scan's second and third halves (orphan attestation,
\*   unretained event, compensation): the record-action leg is a separate model.
\* - Where the model is more generous than the page: a write issued inside the lease lands
\*   inside it (the page's premise: purge completion bound is set from worst-case latency,
\*   purge completion bound 1); no fence is modelled; clock offset allowance is 0; a scan
\*   run finishes inside its lease or dies (compensation closure latency 1 is a declared bound).
\* - The erasure mechanism answers destroyed on re-delegation (Ledger 2026-08-30-d).
\* - Cadence, lease lengths and the horizon are small constants; "all invariants hold"
\*   is a statement within MaxTime ticks at these constants and nothing more.
EXTENDS Naturals

CONSTANTS LeaseLen, SweepLease, Cadence, MaxTime, MechOk

VARIABLES now, ret, pInst, sealed, destRec, deleg, outc, content, ipc, holder, exp, spc, lastRun, foreign, dup, crashes
vars == <<now, ret, pInst, sealed, destRec, deleg, outc, content, ipc, holder, exp, spc, lastRun, foreign, dup, crashes>>

Edge == LeaseLen   \* purge edge = purge completion bound + clock offset allowance (0 here)
ClosureBound == Edge + 2 * (Cadence + SweepLease)

Live(who) == holder = who /\ now < exp
Incomplete == ~destRec \/ outc # "destroyed"

TypeOK ==
    /\ now \in 0..MaxTime
    /\ ret \in {"Retained", "Purged"}
    /\ pInst \in 0..MaxTime
    /\ sealed \in BOOLEAN
    /\ destRec \in BOOLEAN
    /\ deleg \in 0..4
    /\ outc \in {"none", "destroyed", "failed"}
    /\ content \in {"readable", "destroyed"}
    /\ ipc \in {"idle", "s0", "s1", "s2", "s3", "s4", "done", "dead"}
    /\ holder \in {"none", "inv", "scan"}
    /\ exp \in 0..(MaxTime + LeaseLen + SweepLease)
    /\ spc \in {"idle", "held", "r2", "r3", "r4"}
    /\ lastRun \in 0..MaxTime
    /\ foreign \in BOOLEAN
    /\ dup \in BOOLEAN
    /\ crashes \in 0..1

Init ==
    /\ now = 0
    /\ ret = "Retained"
    /\ pInst = 0
    /\ sealed = FALSE
    /\ destRec = FALSE
    /\ deleg = 0
    /\ outc = "none"
    /\ content = "readable"
    /\ ipc = "idle"
    /\ holder = "none"
    /\ exp = 0
    /\ spc = "idle"
    /\ lastRun = 0
    /\ foreign = FALSE
    /\ dup = FALSE
    /\ crashes = 0

\* Time passes, unless a scan run is due, the host has a lease to release, or a scan run in flight would outlast its lease
\* (compensation closure latency 1: the deployment declares one whole closure lands inside SweepLease).
Tick ==
    /\ now < MaxTime
    /\ ~(spc = "idle" /\ now - lastRun >= Cadence)
    /\ ~(holder # "none" /\ now >= exp)
    /\ ~(spc # "idle" /\ now + 1 >= exp)
    /\ now' = now + 1
    /\ UNCHANGED <<ret, pInst, sealed, destRec, deleg, outc, content, ipc, holder, exp, spc, lastRun, foreign, dup, crashes>>

\* Host: a lease that has run out is released (Per-act critical section 4). A dead holder's section frees this way.
HostRelease ==
    /\ holder # "none"
    /\ now >= exp
    /\ holder' = "none"
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, deleg, outc, content, ipc, exp, spc, lastRun, foreign, dup, crashes>>

\* Cascade (purge event 1-4): takes the section keyed by event id, lease = purge completion bound.
IStart ==
    /\ ipc = "idle"
    /\ holder = "none"
    /\ ret = "Retained"
    /\ ipc' = "s0"
    /\ holder' = "inv"
    /\ exp' = now + LeaseLen
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, deleg, outc, content, spc, lastRun, foreign, dup, crashes>>

\* Step 0: covering seal exists before step 1 (purge event step 0.3).
IStep0 ==
    /\ ipc = "s0"
    /\ Live("inv")
    /\ sealed' = TRUE
    /\ ipc' = "s1"
    /\ UNCHANGED <<now, ret, pInst, destRec, deleg, outc, content, holder, exp, spc, lastRun, foreign, dup, crashes>>

\* Step 1: retention Purged, purge instant stamped.
IStep1 ==
    /\ ipc = "s1"
    /\ Live("inv")
    /\ sealed
    /\ ret' = "Purged"
    /\ pInst' = now
    /\ ipc' = "s2"
    /\ UNCHANGED <<now, sealed, destRec, deleg, outc, content, holder, exp, spc, lastRun, foreign, dup, crashes>>

\* Step 2: destruction record (membership + pair) in one durable write, before anything is destroyed.
IStep2 ==
    /\ ipc = "s2"
    /\ Live("inv")
    /\ destRec' = TRUE
    /\ ipc' = "s3"
    /\ UNCHANGED <<now, ret, pInst, sealed, deleg, outc, content, holder, exp, spc, lastRun, foreign, dup, crashes>>

\* Step 3: delegate destruction to the erasure mechanism (issued once per attempt).
IStep3 ==
    /\ ipc = "s3"
    /\ Live("inv")
    /\ destRec
    /\ deleg' = deleg + 1
    /\ dup' = IF outc = "destroyed" THEN TRUE ELSE dup
    /\ content' = IF MechOk THEN "destroyed" ELSE content
    /\ ipc' = "s4"
    /\ foreign' = IF holder # "inv" THEN TRUE ELSE foreign
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, outc, holder, exp, spc, lastRun, crashes>>

\* Step 3 close: the outcome record lands; the section is released on return.
IStep4 ==
    /\ ipc = "s4"
    /\ Live("inv")
    /\ outc' = IF MechOk THEN "destroyed" ELSE "failed"
    /\ ipc' = "done"
    /\ holder' = IF holder = "inv" THEN "none" ELSE holder
    /\ foreign' = IF holder # "inv" THEN TRUE ELSE foreign
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, deleg, content, exp, spc, lastRun, dup, crashes>>

\* Mid-cascade expiry (purge event 7): the lease is gone, no further write issues, the invocation returns cascade-failure(step).
IAbort ==
    /\ ipc \in {"s0", "s1", "s2", "s3", "s4"}
    /\ ~Live("inv")
    /\ ipc' = "dead"
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, deleg, outc, content, holder, exp, spc, lastRun, foreign, dup, crashes>>

\* The invocation may die at any point; the host does not see it, the lease runs out.
ICrash ==
    /\ ipc \in {"s0", "s1", "s2", "s3", "s4"}
    /\ ipc' = "dead"
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, deleg, outc, content, holder, exp, spc, lastRun, foreign, dup, crashes>>

\* A cascade that left retention Retained is re-offered by Purge Eligible (purge event 3c).
IRetry ==
    /\ ipc = "dead"
    /\ ret = "Retained"
    /\ ipc' = "idle"
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, deleg, outc, content, holder, exp, spc, lastRun, foreign, dup, crashes>>

\* First half: examine a Purged retention older than purge edge, take the section (First half 2, 6).
SRunTake ==
    /\ spc = "idle"
    /\ ret = "Purged"
    /\ now - pInst >= Edge
    /\ holder = "none"
    /\ Incomplete
    /\ holder' = "scan"
    /\ exp' = now + SweepLease
    /\ spc' = "held"
    /\ lastRun' = now
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, deleg, outc, content, ipc, foreign, dup, crashes>>

\* A run that finds the section held, or nothing to examine, skips (Per-act critical section 5).
SRunSkip ==
    /\ spc = "idle"
    /\ (holder # "none" \/ ret # "Purged" \/ now - pInst < Edge \/ ~Incomplete)
    /\ lastRun' = now
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, deleg, outc, content, ipc, holder, exp, spc, foreign, dup, crashes>>

\* Re-read the predicate under the section before any write (First half 7).
SCheck ==
    /\ spc = "held"
    /\ Live("scan")
    /\ spc' = IF Incomplete THEN "r2" ELSE "idle"
    /\ holder' = IF Incomplete THEN holder ELSE "none"
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, deleg, outc, content, ipc, exp, lastRun, foreign, dup, crashes>>

\* Re-drive from step 2, adopting a destruction record already landed (proceed as landed).
SStep2 ==
    /\ spc = "r2"
    /\ Live("scan")
    /\ destRec' = TRUE
    /\ spc' = "r3"
    /\ UNCHANGED <<now, ret, pInst, sealed, deleg, outc, content, ipc, holder, exp, lastRun, foreign, dup, crashes>>

\* Re-delegate only where no destroyed outcome is recorded (pre-check, Per-act critical section 11-12).
SStep3 ==
    /\ spc = "r3"
    /\ Live("scan")
    /\ deleg' = IF outc = "destroyed" THEN deleg ELSE deleg + 1
    /\ content' = IF outc # "destroyed" /\ MechOk THEN "destroyed" ELSE content
    /\ spc' = "r4"
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, outc, ipc, holder, exp, lastRun, foreign, dup, crashes>>

\* Record the outcome, release.
SStep4 ==
    /\ spc = "r4"
    /\ Live("scan")
    /\ outc' = IF MechOk THEN "destroyed" ELSE "failed"
    /\ spc' = "idle"
    /\ holder' = "none"
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, deleg, content, ipc, exp, lastRun, foreign, dup, crashes>>

\* The scan run may die once; its lease runs out and the next run resumes.
SCrash ==
    /\ spc \in {"held", "r2", "r3", "r4"}
    /\ crashes < 1
    /\ spc' = "idle"
    /\ crashes' = crashes + 1
    /\ UNCHANGED <<now, ret, pInst, sealed, destRec, deleg, outc, content, ipc, holder, exp, lastRun, foreign, dup>>

Next ==
    \/ Tick
    \/ HostRelease
    \/ IStart
    \/ IStep0
    \/ IStep1
    \/ IStep2
    \/ IStep3
    \/ IStep4
    \/ IAbort
    \/ ICrash
    \/ IRetry
    \/ SRunTake
    \/ SRunSkip
    \/ SCheck
    \/ SStep2
    \/ SStep3
    \/ SStep4
    \/ SCrash

Spec == Init /\ [][Next]_vars

\* --- invariants, named as the page names them ---

\* Invariant 4.2 / purge event step 0.3, 2.4: the declared order of commits.
Inv4_Order ==
    /\ (ret = "Purged") => sealed
    /\ destRec => (ret = "Purged")
    /\ (deleg > 0) => destRec
    /\ (content = "destroyed") => destRec

\* Invariant 8: content is gone only under a Purged retention with its destruction record.
Inv8_HonestDestruction ==
    (content = "destroyed") => (ret = "Purged" /\ destRec)

\* Per-act critical section 7-8, 11-12: one writer per act; no delegation
\* after a destroyed outcome is recorded; no write lands outside a held section.
Inv_OneWriter == ~foreign /\ ~dup

\* Invariant 8 liveness arm, bounded: once the closure bound has run from the purge
\* instant, a working mechanism has been answered and the outcome is recorded.
Inv_BoundedClosure ==
    (ret = "Purged" /\ MechOk /\ now >= pInst + ClosureBound) => (outc = "destroyed")

Safety == TypeOK /\ Inv4_Order /\ Inv8_HonestDestruction /\ Inv_OneWriter /\ Inv_BoundedClosure

====
