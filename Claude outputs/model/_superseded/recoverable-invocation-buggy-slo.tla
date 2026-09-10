---- MODULE recoverable-invocation-buggy-slo ----
\* Grace Commons — Recoverable Invocation: BUGGY TWIN (vacuity guard).
\*
\* THE PROSE AS IT STANDS. Identical to recoverable-invocation.tla, with
\* PerWriteFence = FALSE: a write is fenced at the lease's expiry and nowhere
\* else, so a write may land later than `journal_write_bound` — which is a
\* DISCLOSED BOUND with headroom, an SLO, and which the page's own commit_fence
\* doctrine says decides nothing — while still inside the lease. Primitive
\* policies then read absence after that bound and retry.
\*
\* The constants differ from the main model's: the lease is long enough that a
\* write issued early still has fence room after the read-back, which is the
\* ordinary case in a real deployment and unreachable at the main model's
\* smaller bounds. The sweeps are pushed out so the race is the invocation
\* against its own retry.
\*
\* Expected result: Inv2_OneWriter VIOLATED — the read-back misses a write
\* still in flight and the retry is the second record. Gate 7, F2.


EXTENDS Naturals

CONSTANTS
    CompletionBound,    \* the invocation's lease; the sweep's lower edge
    SweepLease,         \* the sweep's own lease: max(completion_bound, closure_latency)
    JournalWriteBound,  \* a journal write returns, and is visible, within this
    StoreLatency,       \* a fenced store applies a write within this many ticks
    LateLanding,        \* a fenceless store may apply a write up to this late
    Cadence,            \* ticks between a node's sweep runs
    Window,             \* compensation_window
    MaxTime,            \* the horizon of the model
    OpenBy,             \* the invocation opens by this tick
    MaxSweepDeaths,     \* how many sweep runs may die
    MaxPauses,          \* how many ticks a process may spend paused mid-write
    JournalFence,       \* TRUE: a journal write past the writer's lease is refused
    VisibleOnReturn,    \* TRUE: a returned write is visible to every later read
    JournalSkew,        \* the substrate's clock less the section host's (may be < 0)
    FenceMargin,        \* subtracted from the fence instant when it is minted
    MaxLand,            \* the true worst case for a journal write (>= JournalWriteBound)
    PerWriteFence       \* TRUE: a write is fenced at issue + JournalWriteBound too

Sweeps == {"A", "B"}

VARIABLES
    now,
    fence,            \* TRUE: the act kind declares a commit_fence
    invPhase,         \* idle opened committed prepared closing done crashed yielded
    holder,           \* "none" "inv" "A" "B"
    invExpiry,        \* the invocation's lease expiry: its fence instant
    heldUntil,        \* the current holder's lease expiry (0 when free)
    intentState,      \* "absent" "pending" "visible"
    intentAt,         \* the intent's recorded_at
    intentVisibleAt,
    storeState,       \* "none" "pending" "committed" "dropped"
    storeLandAt,
    outcomeState,     \* "absent" "pending" "returned" "visible"
    outcomeIssuedAt,  \* the tick the outcome in flight was issued
    outcomeReplyLost, \* TRUE: its caller never learns it returned
    outcomeReturnAt,
    outcomeVisibleAt,
    outcomeRecords,   \* outcome records that landed or will land
    closingKind,      \* "none" "abandoned" "escalated"
    closingState,     \* "absent" "pending" "returned" "visible"
    closingReturnAt,
    closingVisibleAt,
    closingRecords,
    sweepNextA,
    sweepNextB,
    sweepPhaseA,      \* idle waiting holding prepOutcome prepClosing issued
    sweepPhaseB,
    sweepDeaths,
    pauses            \* ticks spent by a process between its gate and its write

vars == <<now, fence, invPhase, holder, invExpiry, heldUntil,
          intentState, intentAt, intentVisibleAt, storeState, storeLandAt,
          outcomeState, outcomeIssuedAt, outcomeReplyLost, outcomeReturnAt,
          outcomeVisibleAt, outcomeRecords,
          closingKind, closingState, closingReturnAt, closingVisibleAt,
          closingRecords, sweepNextA, sweepNextB, sweepPhaseA, sweepPhaseB,
          sweepDeaths, pauses>>

Horizon == MaxTime + SweepLease + LateLanding + MaxLand

TypeOK ==
    /\ now \in 0..MaxTime
    /\ fence \in BOOLEAN
    /\ invPhase \in {"idle", "opened", "committed", "prepared", "closing", "readback", "done", "crashed", "yielded"}
    /\ holder \in {"none", "inv", "A", "B"}
    /\ invExpiry \in 0..Horizon
    /\ heldUntil \in 0..Horizon
    /\ intentState \in {"absent", "pending", "visible"}
    /\ intentAt \in 0..Horizon
    /\ intentVisibleAt \in 0..Horizon
    /\ storeState \in {"none", "pending", "committed", "dropped"}
    /\ storeLandAt \in 0..Horizon
    /\ outcomeState \in {"absent", "pending", "returned", "visible"}
    /\ outcomeIssuedAt \in 0..Horizon
    /\ outcomeReplyLost \in BOOLEAN
    /\ outcomeReturnAt \in 0..Horizon
    /\ outcomeVisibleAt \in 0..Horizon
    /\ outcomeRecords \in 0..3
    /\ closingKind \in {"none", "abandoned", "escalated"}
    /\ closingState \in {"absent", "pending", "returned", "visible"}
    /\ closingReturnAt \in 0..Horizon
    /\ closingVisibleAt \in 0..Horizon
    /\ closingRecords \in 0..3
    /\ sweepNextA \in 0..Horizon
    /\ sweepNextB \in 0..Horizon
    /\ sweepPhaseA \in {"idle", "waiting", "holding", "prepOutcome", "prepClosing", "issued"}
    /\ sweepPhaseB \in {"idle", "waiting", "holding", "prepOutcome", "prepClosing", "issued"}
    /\ sweepDeaths \in 0..MaxSweepDeaths
    /\ pauses \in 0..MaxPauses

Init ==
    /\ now = 0
    /\ fence \in BOOLEAN
    /\ invPhase = "idle"
    /\ holder = "none"
    /\ invExpiry = 0
    /\ heldUntil = 0
    /\ intentState = "absent"
    /\ intentAt = 0
    /\ intentVisibleAt = 0
    /\ storeState = "none"
    /\ storeLandAt = 0
    /\ outcomeState = "absent"
    /\ outcomeIssuedAt = 0
    /\ outcomeReplyLost = FALSE
    /\ outcomeReturnAt = 0
    /\ outcomeVisibleAt = 0
    /\ outcomeRecords = 0
    /\ closingKind = "none"
    /\ closingState = "absent"
    /\ closingReturnAt = 0
    /\ closingVisibleAt = 0
    /\ closingRecords = 0
    /\ sweepNextA = Cadence
    /\ sweepNextB \in 1..Cadence
    /\ sweepPhaseA = "idle"
    /\ sweepPhaseB = "idle"
    /\ sweepDeaths = 0
    /\ pauses = 0

\* ---- helpers -------------------------------------------------------------

PhaseOf(s) == IF s = "A" THEN sweepPhaseA ELSE sweepPhaseB
SetPhase(s, ph) ==
    /\ sweepPhaseA' = IF s = "A" THEN ph ELSE sweepPhaseA
    /\ sweepPhaseB' = IF s = "B" THEN ph ELSE sweepPhaseB
NextOf(s) == IF s = "A" THEN sweepNextA ELSE sweepNextB
SetNext(s, t) ==
    /\ sweepNextA' = IF s = "A" THEN t ELSE sweepNextA
    /\ sweepNextB' = IF s = "B" THEN t ELSE sweepNextB
\* Free when nobody holds it, or the holder's lease has run out. The host does
\* not learn of a death; the lease is what ends a hold.
SectionFree == holder = "none" \/ now >= heldUntil

\* The gate every journal write after the first must pass: the holder's
\* remaining lease covers the write bound. NOTE: passing this gate is now a
\* separate step from issuing the write.
InvGateOpen == holder = "inv" /\ now + JournalWriteBound <= invExpiry
SweepGateOpen(s) == holder = s /\ now + JournalWriteBound <= heldUntil

\* A sweep run's own lease end. A run still in a prepared phase that is no
\* longer the holder can only have got there by its lease running out, so its
\* fence instant is already past: any fenced write of its is refused.
SweepLeaseEnd(s) == IF holder = s THEN heldUntil ELSE 0

\* What a reader of the journal sees.
OutcomeVisible == outcomeState = "visible"
ClosingVisible == closingState = "visible"
Closed == OutcomeVisible \/ ClosingVisible

\* A write returns to its caller at r and becomes visible at v, with
\* now < r <= v <= now + JournalWriteBound. Under VisibleOnReturn the two
\* coincide: a returned write is visible to everyone.
\* A write returns at r and becomes visible at v. JournalWriteBound is the
\* deployment's DISCLOSED bound — an SLO with headroom, which the page's own
\* commit_fence doctrine says decides nothing — so the true worst case is
\* MaxLand, and what actually bounds a landing is the fence.
LegalWrite(r, v) ==
    /\ r \in (now + 1)..(now + MaxLand)
    /\ v \in r..(now + MaxLand)
    /\ VisibleOnReturn => v = r

\* A fenced journal refuses a write that would become visible past the fence
\* instant it was given, exactly as a store-level commit_fence refuses a late
\* commit. Two clocks meet here and that is the point of modeling it:
\*   - the fence INSTANT is minted by the section host, from `expires_at`,
\*     less FenceMargin (the page as written mints it bare: FenceMargin = 0);
\*   - the REFUSAL is judged by the substrate, on the substrate's own clock,
\*     which reads `now + JournalSkew`.
\* A substrate lagging the host (JournalSkew < 0) therefore admits a write the
\* host would call late, for as long as the lag — which is exactly the residue
\* the fence was introduced to remove, and which a margin of one allowance
\* closes. Without the fence the write lands whatever any clock says.
\* EVERY fence instant is minted with the margin, not just the lease's. The
\* checker found the alternative the hard way: with the margin applied to the
\* lease term alone, the per-write term is defeated by exactly the skew the
\* margin exists to cover, and the read-back still misses a write in flight.
FenceInstant(leaseEnd) ==
    LET held == IF leaseEnd > FenceMargin THEN leaseEnd - FenceMargin ELSE 0
        perWrite == IF now + JournalWriteBound > FenceMargin
                    THEN now + JournalWriteBound - FenceMargin ELSE 0
    IN IF PerWriteFence /\ perWrite < held THEN perWrite ELSE held
Fenced(v, leaseEnd) == JournalFence /\ (v + JournalSkew) > FenceInstant(leaseEnd)

SweepScheduled(s) == now >= NextOf(s) /\ PhaseOf(s) = "idle"
AnySweepScheduled == SweepScheduled("A") \/ SweepScheduled("B")
AnyTakeReady == \E s \in Sweeps : PhaseOf(s) = "waiting" /\ SectionFree
\* A run in `holding` re-reads and probes in one instant (inside run_bound).
AnySweepDeciding == (sweepPhaseA = "holding" /\ holder = "A") \/ (sweepPhaseB = "holding" /\ holder = "B")

\* A process is BETWEEN ITS GATE AND ITS WRITE: it has decided to write and has
\* not yet issued. Time passing here is the pause — the thing v1 could not
\* represent, and the thing the spec's own commit_fence text says nothing
\* bounds. It is budgeted rather than free: a pause is an exceptional event (a
\* stop-the-world collection, a migration), so MaxPauses of them may happen and
\* no more. Left unbudgeted, "pause for ever" is a behaviour of every model
\* without fairness and starves the act at every window — a statement about
\* fairness, not about this protocol.
PreparedPhase(s) == PhaseOf(s) \in {"prepOutcome", "prepClosing"}
Preparing == invPhase = "prepared" \/ PreparedPhase("A") \/ PreparedPhase("B")

\* ---- the invocation -------------------------------------------------------

\* [Open]: take the section, issue the intent. Its return and its visibility
\* are one event here (see MODELING CHOICES).
Open ==
    /\ invPhase = "idle"
    /\ now <= OpenBy
    /\ SectionFree
    /\ holder' = "inv"
    /\ invExpiry' = now + CompletionBound
    /\ heldUntil' = now + CompletionBound
    /\ intentState' = "pending"
    /\ intentAt' = now
    /\ \E d \in 1..JournalWriteBound : intentVisibleAt' = now + d
    /\ invPhase' = "opened"
    /\ UNCHANGED <<now, fence, storeState, storeLandAt,
                   outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* The bound commit. Not gated on the lease — a paused process may issue it
\* late — which is why the store-level fence exists.
IssueCommit ==
    /\ invPhase = "opened"
    /\ intentState = "visible"
    /\ storeState = "none"
    /\ invPhase' = "committed"
    /\ \/ /\ fence
          /\ \E d \in 1..StoreLatency :
                IF now + d <= invExpiry
                THEN storeState' = "pending" /\ storeLandAt' = now + d
                ELSE storeState' = "dropped" /\ storeLandAt' = 0
       \/ /\ ~fence
          /\ \E d \in 1..LateLanding :
                storeState' = "pending" /\ storeLandAt' = now + d
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, outcomeState,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* [Close] steps 1 and 2: the commit landed, the lease covers a write, no
\* outcome is visible — the invocation decides to write. THE WRITE IS NOT
\* ISSUED YET. Time may pass here: this is the pause the spec admits.
PrepareOutcome ==
    /\ invPhase = "committed"
    /\ storeState = "committed"
    /\ InvGateOpen
    /\ ~OutcomeVisible
    /\ outcomeState = "absent"
    /\ invPhase' = "prepared"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* [Close] step 3: the write goes out. The lease is NOT re-checked — nothing
\* re-checks it in the spec either, and a relative gate cannot bind a process
\* that has already passed it.
IssueOutcomeInv ==
    /\ invPhase = "prepared"
    /\ \E r \in (now + 1)..(now + MaxLand) :
         \E v \in r..(now + MaxLand) :
            /\ LegalWrite(r, v)
            /\ ~Fenced(v, invExpiry)
            /\ outcomeReturnAt' = r
            /\ outcomeVisibleAt' = v
    /\ outcomeState' = "pending"
    /\ outcomeIssuedAt' = now
    /\ outcomeReplyLost' \in BOOLEAN
    /\ outcomeRecords' = outcomeRecords + 1
    /\ invPhase' = "closing"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses>>

\* The fenced journal refuses the late write: no record, recording-failure to
\* the caller, the act is the sweep's.
DropOutcomeInv ==
    /\ invPhase = "prepared"
    /\ JournalFence
    /\ Fenced(now + 1, invExpiry)
    /\ invPhase' = "yielded"
    /\ holder' = IF holder = "inv" THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "inv" THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invExpiry, intentState,
                   intentAt, intentVisibleAt, storeState, storeLandAt,
                   outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* [Close] step 1, the other arm: the lease no longer covers a write. Yield.
Yield ==
    /\ invPhase \in {"opened", "committed"}
    /\ ~InvGateOpen
    /\ invPhase' = "yielded"
    /\ holder' = IF holder = "inv" THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "inv" THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invExpiry, intentState,
                   intentAt, intentVisibleAt, storeState, storeLandAt,
                   outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* Primitive policies: a `record_action` whose reply is LOST is never retried
\* blind — the caller waits out the disclosed bound, reads back, and retries
\* only on absence. The page concludes absence from `journal_write_bound`
\* having elapsed; what actually bounds the write is the fence, which is later,
\* so a write still in flight reads as absent and the retry is a second record.
ReadBackDue ==
    /\ invPhase = "closing"
    /\ outcomeReplyLost
    /\ now >= outcomeIssuedAt + JournalWriteBound
    /\ invPhase' = "readback"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil, intentState,
                   intentAt, intentVisibleAt, storeState, storeLandAt,
                   outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses>>

\* The read-back finds it: adopt, release, return.
ReadBackFound ==
    /\ invPhase = "readback"
    /\ outcomeState = "visible"
    /\ invPhase' = "done"
    /\ holder' = IF holder = "inv" THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "inv" THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invExpiry, intentState, intentAt,
                   intentVisibleAt, storeState, storeLandAt, outcomeState,
                   outcomeIssuedAt, outcomeReplyLost, outcomeReturnAt,
                   outcomeVisibleAt, outcomeRecords, closingKind, closingState,
                   closingReturnAt, closingVisibleAt, closingRecords,
                   sweepNextA, sweepNextB, sweepPhaseA, sweepPhaseB,
                   sweepDeaths, pauses>>

\* The read-back does NOT find it, so the caller retries — and the first write
\* may still be in flight. That is the second record Invariant 2 forbids.
ReadBackMiss ==
    /\ invPhase = "readback"
    /\ outcomeState /= "visible"
    /\ \E r \in (now + 1)..(now + MaxLand) :
         \E v \in r..(now + MaxLand) :
            /\ LegalWrite(r, v)
            /\ ~Fenced(v, invExpiry)
            /\ outcomeReturnAt' = r
            /\ outcomeVisibleAt' = v
    /\ outcomeState' = "pending"
    /\ outcomeIssuedAt' = now
    /\ outcomeReplyLost' = FALSE
    /\ outcomeRecords' = outcomeRecords + 1
    /\ invPhase' = "closing"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil, intentState,
                   intentAt, intentVisibleAt, storeState, storeLandAt,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses>>

\* The retry is fenced out: nothing more is written; the act is the sweep's.
ReadBackFenced ==
    /\ invPhase = "readback"
    /\ outcomeState /= "visible"
    /\ JournalFence
    /\ Fenced(now + 1, invExpiry)
    /\ invPhase' = "yielded"
    /\ holder' = IF holder = "inv" THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "inv" THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invExpiry, intentState, intentAt,
                   intentVisibleAt, storeState, storeLandAt, outcomeState,
                   outcomeIssuedAt, outcomeReplyLost, outcomeReturnAt,
                   outcomeVisibleAt, outcomeRecords, closingKind, closingState,
                   closingReturnAt, closingVisibleAt, closingRecords,
                   sweepNextA, sweepNextB, sweepPhaseA, sweepPhaseB,
                   sweepDeaths, pauses>>

\* [Close] step 4: the write RETURNED. Release and return — not "the write is
\* visible": nothing tells the caller that.
FinishInv ==
    /\ invPhase = "closing"
    /\ ~outcomeReplyLost
    /\ outcomeState \in {"returned", "visible"}
    /\ invPhase' = "done"
    /\ holder' = IF holder = "inv" THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "inv" THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invExpiry, intentState,
                   intentAt, intentVisibleAt, storeState, storeLandAt,
                   outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* The process dies. A write already issued still lands. The host does not see
\* the death: the lease runs out.
Crash ==
    /\ invPhase \in {"opened", "committed", "prepared", "closing", "readback"}
    /\ invPhase' = "crashed"
    /\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* ---- the sweep ------------------------------------------------------------

\* [Reconcile] step 1: enumerate past the lower edge, nothing closed.
SweepDue(s) ==
    /\ SweepScheduled(s)
    /\ intentState = "visible"
    /\ now >= intentAt + CompletionBound
    /\ ~Closed

\* The run selects the act and calls the blocking take; time passes while it
\* waits (bounded by the holder's remaining lease — the section frees itself).
SweepSelect(s) ==
    /\ SweepDue(s)
    /\ SetPhase(s, "waiting")
    /\ SetNext(s, now + Cadence)
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* The take succeeds. The run's lease is SweepLease, not the act's bound.
SweepTake(s) ==
    /\ PhaseOf(s) = "waiting"
    /\ SectionFree
    /\ holder' = s
    /\ heldUntil' = now + SweepLease
    /\ SetPhase(s, "holding")
    /\ UNCHANGED <<now, fence, invPhase, invExpiry, intentState, intentAt,
                   intentVisibleAt, storeState, storeLandAt, outcomeState,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* [Reconcile] step 2: the re-read under the section finds a visible closing.
\* Nothing to do; release.
SweepSeen(s) ==
    /\ PhaseOf(s) = "holding"
    /\ holder = s
    /\ Closed
    /\ SetPhase(s, "idle")
    /\ holder' = "none"
    /\ heldUntil' = 0
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* The lease will not cover a write: write nothing, leave it for the next run.
SweepYield(s) ==
    /\ PhaseOf(s) = "holding"
    /\ holder = s
    /\ ~Closed
    /\ ~SweepGateOpen(s)
    /\ SetPhase(s, "idle")
    /\ holder' = "none"
    /\ heldUntil' = 0
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* The probe answers committed: the run decides on the outcome record.
SweepPrepareOutcome(s) ==
    /\ PhaseOf(s) = "holding"
    /\ holder = s
    /\ ~Closed
    /\ SweepGateOpen(s)
    /\ storeState = "committed"
    /\ SetPhase(s, "prepOutcome")
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses>>

\* The probe answers not-committed: abandoned under a fence, escalated without.
SweepPrepareClosing(s) ==
    /\ PhaseOf(s) = "holding"
    /\ holder = s
    /\ ~Closed
    /\ SweepGateOpen(s)
    /\ storeState \in {"none", "pending", "dropped"}
    /\ SetPhase(s, "prepClosing")
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses>>

SweepIssueOutcome(s) ==
    /\ PhaseOf(s) = "prepOutcome"
    /\ \E r \in (now + 1)..(now + JournalWriteBound) :
         \E v \in r..(now + JournalWriteBound) :
            /\ LegalWrite(r, v)
            /\ ~Fenced(v, SweepLeaseEnd(s))
            /\ outcomeReturnAt' = r
            /\ outcomeVisibleAt' = v
    /\ outcomeState' = "pending"
    /\ outcomeIssuedAt' = now
    /\ outcomeReplyLost' = FALSE
    /\ outcomeRecords' = outcomeRecords + 1
    /\ SetPhase(s, "issued")
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses>>

SweepIssueClosing(s) ==
    /\ PhaseOf(s) = "prepClosing"
    /\ \E r \in (now + 1)..(now + JournalWriteBound) :
         \E v \in r..(now + JournalWriteBound) :
            /\ LegalWrite(r, v)
            /\ ~Fenced(v, SweepLeaseEnd(s))
            /\ closingReturnAt' = r
            /\ closingVisibleAt' = v
    /\ closingKind' = IF fence THEN "abandoned" ELSE "escalated"
    /\ closingState' = "pending"
    /\ closingRecords' = closingRecords + 1
    /\ SetPhase(s, "issued")
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, sweepNextA, sweepNextB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* The fenced journal refuses the run's late write: nothing is recorded, the
\* run counts the act skipped, and the next run takes it.
SweepDropWrite(s) ==
    /\ PreparedPhase(s)
    /\ JournalFence
    /\ Fenced(now + 1, SweepLeaseEnd(s))
    /\ SetPhase(s, "idle")
    /\ sweepDeaths' = sweepDeaths
    /\ holder' = IF holder = s THEN "none" ELSE holder
    /\ heldUntil' = IF holder = s THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* The run's write RETURNED: release and return. Not "became visible" — the
\* spec releases on the holder's return.
SweepReturn(s) ==
    /\ PhaseOf(s) = "issued"
    /\ \/ outcomeState \in {"returned", "visible"}
       \/ closingState \in {"returned", "visible"}
    /\ SetPhase(s, "idle")
    /\ holder' = IF holder = s THEN "none" ELSE holder
    /\ heldUntil' = IF holder = s THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* A run dies. Its pending write still lands; its lease runs out.
SweepCrash(s) ==
    /\ PhaseOf(s) \in {"waiting", "holding", "prepOutcome", "prepClosing", "issued"}
    /\ sweepDeaths < MaxSweepDeaths
    /\ sweepDeaths' = sweepDeaths + 1
    /\ SetPhase(s, "idle")
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* A scheduled run with nothing to examine reschedules.
SweepSkip(s) ==
    /\ SweepScheduled(s)
    /\ ~SweepDue(s)
    /\ SetNext(s, now + Cadence)
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepPhaseA, sweepPhaseB,
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost>>

\* ---- time -----------------------------------------------------------------

\* Writes return and become visible at their ticks. Time does not advance past
\* a scheduled run, a take that can succeed, or a run's re-read and probe. It
\* DOES advance between a prepare and its issue: that is the pause.
NextIntent == IF intentState = "pending" /\ intentVisibleAt = now + 1
              THEN "visible" ELSE intentState
AfterIntentVis == IF intentState = "pending" /\ intentVisibleAt = now + 1
                  THEN 0 ELSE intentVisibleAt
NextStore == IF storeState = "pending" /\ storeLandAt = now + 1
             THEN "committed" ELSE storeState
AfterStoreLand == IF storeState = "pending" /\ storeLandAt = now + 1
                  THEN 0 ELSE storeLandAt
AfterOutcomeRet == IF outcomeState = "pending" /\ outcomeReturnAt = now + 1
                   THEN 0 ELSE outcomeReturnAt
AfterOutcomeVis == IF outcomeState \in {"pending", "returned"} /\ outcomeVisibleAt = now + 1
                   THEN 0 ELSE outcomeVisibleAt
AfterClosingRet == IF closingState = "pending" /\ closingReturnAt = now + 1
                   THEN 0 ELSE closingReturnAt
AfterClosingVis == IF closingState \in {"pending", "returned"} /\ closingVisibleAt = now + 1
                   THEN 0 ELSE closingVisibleAt
NextOutcome == IF outcomeState = "pending" /\ outcomeReturnAt = now + 1
               THEN (IF outcomeVisibleAt = now + 1 THEN "visible" ELSE "returned")
               ELSE IF outcomeState = "returned" /\ outcomeVisibleAt = now + 1
               THEN "visible" ELSE outcomeState
NextClosing == IF closingState = "pending" /\ closingReturnAt = now + 1
               THEN (IF closingVisibleAt = now + 1 THEN "visible" ELSE "returned")
               ELSE IF closingState = "returned" /\ closingVisibleAt = now + 1
               THEN "visible" ELSE closingState

Tick ==
    /\ now < MaxTime
    /\ ~AnySweepScheduled
    /\ ~AnyTakeReady
    /\ ~AnySweepDeciding
    /\ IF Preparing THEN pauses < MaxPauses /\ pauses' = pauses + 1
                     ELSE pauses' = pauses
    /\ now' = now + 1
    /\ intentState' = NextIntent
    /\ storeState' = NextStore
    /\ outcomeState' = NextOutcome
    /\ closingState' = NextClosing
    /\ intentVisibleAt' = AfterIntentVis
    /\ storeLandAt' = AfterStoreLand
    /\ outcomeReturnAt' = AfterOutcomeRet
    /\ outcomeVisibleAt' = AfterOutcomeVis
    /\ closingReturnAt' = AfterClosingRet
    /\ closingVisibleAt' = AfterClosingVis
    /\ UNCHANGED <<fence, invPhase, holder, invExpiry, heldUntil,
                   intentAt, outcomeIssuedAt, outcomeReplyLost,
                   outcomeRecords, closingKind, closingRecords,
                   sweepNextA, sweepNextB, sweepPhaseA, sweepPhaseB,
                   sweepDeaths>>

Next ==
    \/ Open
    \/ IssueCommit
    \/ PrepareOutcome
    \/ IssueOutcomeInv
    \/ DropOutcomeInv
    \/ Yield
    \/ ReadBackDue
    \/ ReadBackFound
    \/ ReadBackMiss
    \/ ReadBackFenced
    \/ FinishInv
    \/ Crash
    \/ \E s \in Sweeps : SweepSelect(s)
    \/ \E s \in Sweeps : SweepTake(s)
    \/ \E s \in Sweeps : SweepSeen(s)
    \/ \E s \in Sweeps : SweepYield(s)
    \/ \E s \in Sweeps : SweepPrepareOutcome(s)
    \/ \E s \in Sweeps : SweepPrepareClosing(s)
    \/ \E s \in Sweeps : SweepIssueOutcome(s)
    \/ \E s \in Sweeps : SweepIssueClosing(s)
    \/ \E s \in Sweeps : SweepDropWrite(s)
    \/ \E s \in Sweeps : SweepReturn(s)
    \/ \E s \in Sweeps : SweepCrash(s)
    \/ \E s \in Sweeps : SweepSkip(s)
    \/ Tick

Spec == Init /\ [][Next]_vars

\* ---- invariants -----------------------------------------------------------

Inv1_IntentFirst ==
    (storeState /= "none") => intentState = "visible"

Inv2_OneWriter ==
    /\ outcomeRecords <= 1
    /\ outcomeRecords + closingRecords <= 1

Inv4_BoundedClosure ==
    (/\ intentState = "visible"
     /\ invPhase \in {"crashed", "yielded"}
     /\ now >= intentAt + Window)
    => Closed

Inv5_NoFalseAbandon ==
    (closingKind = "abandoned") => storeState \in {"none", "dropped"}

Safety == TypeOK /\ Inv1_IntentFirst /\ Inv2_OneWriter /\ Inv4_BoundedClosure
          /\ Inv5_NoFalseAbandon

====
