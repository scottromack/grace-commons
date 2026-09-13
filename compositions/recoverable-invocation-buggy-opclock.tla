---- MODULE recoverable-invocation-buggy-opclock ----
\* Grace Commons — Recoverable Invocation: BUGGY TWIN (vacuity guard).
\*
\* THE PROSE AS IT STANDS. Identical to the report-only configuration with
\* OperatorSkew = 1: [Resolve]'s too-young guard compares a present reading
\* against the substrate's `recorded_at`, and NO SEAM SUPPLIES THAT READING.
\* The page enumerates its clocks exhaustively twice and [Resolve] is at none
\* of them, so the only way to close the step is a clock read inside the
\* action — and nothing then bounds how far it runs ahead.
\*
\* `service_identity = none`, because only in a report-only deployment does
\* the operator decide an act's fate against the edge rather than after
\* another writer already has. Its passing sibling is
\* probe-reportonly-clean.tla, which differs by this one constant.
\*
\* Expected result: Inv5_NoFalseAbandon VIOLATED — the operator writes
\* `abandoned` one tick before the edge, on a reading that says otherwise, and
\* the invocation's commit still lands. Gate 9, F7.


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
    PerWriteFence,      \* TRUE: a write is fenced at issue + JournalWriteBound too
    ServiceIdentity,    \* TRUE: the sweep closes acts; FALSE: report-only
    MaxResolves,        \* how many [Resolve] calls the model admits
    SupersedesNamed,    \* TRUE: a resolution names the record it closes over
    OperatorSkew        \* how far the operator's own reading may run ahead

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
    pauses,           \* ticks spent by a process between its gate and its write
    opPhase,          \* idle waiting holding prepared issued done
    opKind,           \* none outcome abandoned  — the operator's disposition
    opState,          \* absent pending returned visible
    opReturnAt,
    opVisibleAt,
    opRecords,        \* the operator's closing records
    opNamed           \* TRUE: that record carries `supersedes` naming another

vars == <<now, fence, invPhase, holder, invExpiry, heldUntil,
          intentState, intentAt, intentVisibleAt, storeState, storeLandAt,
          outcomeState, outcomeIssuedAt, outcomeReplyLost, outcomeReturnAt,
          outcomeVisibleAt, outcomeRecords,
          closingKind, closingState, closingReturnAt, closingVisibleAt,
          closingRecords, sweepNextA, sweepNextB, sweepPhaseA, sweepPhaseB,
          sweepDeaths, pauses,
          opPhase, opKind, opState, opReturnAt, opVisibleAt, opRecords, opNamed>>

opVars == <<opPhase, opKind, opState, opReturnAt, opVisibleAt, opRecords, opNamed>>

Horizon == MaxTime + SweepLease + LateLanding + MaxLand

TypeOK ==
    /\ now \in 0..MaxTime
    /\ fence \in BOOLEAN
    /\ invPhase \in {"idle", "opened", "committed", "prepared", "closing", "readback", "done", "crashed", "yielded"}
    /\ holder \in {"none", "inv", "A", "B", "op"}
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
    /\ opPhase \in {"idle", "waiting", "holding", "prepared", "issued", "done"}
    /\ opKind \in {"none", "outcome", "abandoned"}
    /\ opState \in {"absent", "pending", "returned", "visible"}
    /\ opReturnAt \in 0..Horizon
    /\ opVisibleAt \in 0..Horizon
    /\ opRecords \in 0..MaxResolves
    /\ opNamed \in BOOLEAN

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
    /\ opPhase = "idle"
    /\ opKind = "none"
    /\ opState = "absent"
    /\ opReturnAt = 0
    /\ opVisibleAt = 0
    /\ opRecords = 0
    /\ opNamed = FALSE

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
OpVisible == opState = "visible"
Closed == OutcomeVisible \/ ClosingVisible \/ OpVisible

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
Preparing == invPhase = "prepared" \/ PreparedPhase("A") \/ PreparedPhase("B") \/ opPhase = "prepared"

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
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepPhaseB, sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepPhaseB, sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepPhaseA, sweepPhaseB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   closingVisibleAt, closingRecords, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   closingRecords, sweepNextA, sweepNextB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

\* The probe answers committed: the run decides on the outcome record.
SweepPrepareOutcome(s) ==
    /\ PhaseOf(s) = "holding"
    /\ holder = s
    /\ ~Closed
    /\ SweepGateOpen(s)
    /\ ServiceIdentity
    /\ storeState = "committed"
    /\ SetPhase(s, "prepOutcome")
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

\* The probe answers not-committed: abandoned under a fence, escalated without.
SweepPrepareClosing(s) ==
    /\ PhaseOf(s) = "holding"
    /\ holder = s
    /\ ~Closed
    /\ SweepGateOpen(s)
    /\ ServiceIdentity
    /\ storeState \in {"none", "pending", "dropped"}
    /\ SetPhase(s, "prepClosing")
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeReturnAt, outcomeVisibleAt,
                   outcomeRecords, closingKind, closingState, closingReturnAt,
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB,
                   sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepDeaths, pauses, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   outcomeRecords, sweepNextA, sweepNextB, sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   closingVisibleAt, closingRecords, sweepNextA, sweepNextB, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>

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
                   sweepDeaths, pauses, outcomeIssuedAt, outcomeReplyLost, opPhase, opKind, opState,
                   opReturnAt, opVisibleAt, opRecords, opNamed>>


\* ---- the operator: [Resolve] ----------------------------------------------

\* THE OPERATOR'S OWN READING. Every other reading on this page is injected at
\* a seam and compared under one allowance; the page enumerates its clocks
\* exhaustively, twice, and [Resolve] is at none of them — yet its too-young
\* guard compares a present reading against the substrate's `recorded_at`.
\* OperatorSkew is how far that reading may run ahead of the true instant: 0 is
\* a declared operator seam, and anything more is the page as written, where
\* the only way to close the step is a clock read inside the action.
\* The existential is the adversary: the reading may be ANY value in the range,
\* so the protocol must be safe for all of them.
OpReadings == now..(now + OperatorSkew)

OpGateOpen == holder = "op" /\ now + JournalWriteBound <= heldUntil
OpLeaseEnd == IF holder = "op" THEN heldUntil ELSE 0

\* Whether the record this resolution writes NAMES the record it closes over.
\* The page requires `supersedes` over an abandonment. Over an ESCALATION it
\* requires only `resolved_by` — which names the operator and not a record, so
\* the precedence rule and the acceptance check have no referent. That is
\* SupersedesNamed = FALSE, and it is the page as written (gate 9, F6).
OpWouldName ==
    IF ~(ClosingVisible \/ OutcomeVisible) THEN FALSE
    ELSE IF closingKind = "abandoned" THEN TRUE
    ELSE SupersedesNamed

\* There is something for an operator to do. Two arms, and which is available
\* is a property of the deployment, not a budget: an escalation they have
\* investigated (any deployment), or — ONLY where the sweep writes nothing,
\* `service_identity = none` — an open intent past the edge on their own
\* reading. In a deployment whose sweep closes acts, an operator does not race
\* it to an open intent; they resolve what it escalated. Keeping the second arm
\* available everywhere is both unfaithful and the reason v4's first cut did not
\* terminate: the operator then interleaves with both sweeps across most of the
\* reachable space.
OpDue ==
    /\ opPhase = "idle"
    /\ opRecords < MaxResolves
    /\ intentState = "visible"
    /\ \/ (ClosingVisible /\ closingKind = "escalated")
       \/ (~ServiceIdentity /\ ~Closed
           /\ \E r \in OpReadings : r >= intentAt + CompletionBound)

OpSelect ==
    /\ OpDue
    /\ opPhase' = "waiting"
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opKind, opState, opReturnAt, opVisibleAt, opRecords, opNamed>>

\* [Resolve] takes the SAME section on the same key, for the same reason — it
\* is a writer like the others and is serialized like the others.
OpTake ==
    /\ opPhase = "waiting"
    /\ SectionFree
    /\ holder' = "op"
    /\ heldUntil' = now + SweepLease
    /\ opPhase' = "holding"
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opKind, opState, opReturnAt, opVisibleAt, opRecords, opNamed>>

\* The re-read under the section finds an outcome: nothing left to resolve.
OpSeen ==
    /\ opPhase = "holding"
    /\ holder = "op"
    /\ OutcomeVisible
    /\ opPhase' = "done"
    /\ holder' = "none"
    /\ heldUntil' = 0
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opKind, opState, opReturnAt, opVisibleAt, opRecords, opNamed>>

\* The lease will not cover the write: [Resolve] gates on `remaining` as
\* [Close] does, and writes nothing.
OpYield ==
    /\ opPhase = "holding"
    /\ holder = "op"
    /\ ~OutcomeVisible
    /\ ~OpGateOpen
    /\ opPhase' = "done"
    /\ holder' = "none"
    /\ heldUntil' = 0
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opKind, opState, opReturnAt, opVisibleAt, opRecords, opNamed>>

\* The operator ran the probe themselves and it says the act happened: they
\* write the closing the sweep could not, over whatever record stands.
OpPrepareOutcome ==
    /\ opPhase = "holding"
    /\ holder = "op"
    /\ ~OutcomeVisible
    /\ OpGateOpen
    /\ storeState = "committed"
    /\ opKind' = "outcome"
    /\ opPhase' = "prepared"
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opState, opReturnAt, opVisibleAt, opRecords, opNamed>>

\* The operator attests the act did not happen. The page gates this on the
\* intent being older than the edge — compared against THE OPERATOR'S OWN
\* READING, which is the whole of gate 9's F7.
OpPrepareAbandon ==
    /\ opPhase = "holding"
    /\ holder = "op"
    /\ ~OutcomeVisible
    /\ OpGateOpen
    /\ fence
    /\ storeState \in {"none", "pending", "dropped"}
    /\ \E r \in OpReadings : r >= intentAt + CompletionBound
    /\ opKind' = "abandoned"
    /\ opPhase' = "prepared"
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opState, opReturnAt, opVisibleAt, opRecords, opNamed>>

OpIssue ==
    /\ opPhase = "prepared"
    /\ \E r \in (now + 1)..(now + JournalWriteBound) :
         \E v \in r..(now + JournalWriteBound) :
            /\ LegalWrite(r, v)
            /\ ~Fenced(v, OpLeaseEnd)
            /\ opReturnAt' = r
            /\ opVisibleAt' = v
    /\ opState' = "pending"
    /\ opRecords' = opRecords + 1
    /\ opNamed' = OpWouldName
    /\ opPhase' = "issued"
    /\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses, opKind>>

\* The fenced journal refuses the operator's late write: nothing is recorded.
OpDropWrite ==
    /\ opPhase = "prepared"
    /\ JournalFence
    /\ Fenced(now + 1, OpLeaseEnd)
    /\ opPhase' = "done"
    /\ holder' = IF holder = "op" THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "op" THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opKind, opState, opReturnAt, opVisibleAt, opRecords, opNamed>>

\* The write RETURNED: release. Not "became visible" — the page releases on the
\* holder's return, which is the handoff the read-your-writes clause covers.
OpReturn ==
    /\ opPhase = "issued"
    /\ opState \in {"returned", "visible"}
    /\ opPhase' = "done"
    /\ holder' = IF holder = "op" THEN "none" ELSE holder
    /\ heldUntil' = IF holder = "op" THEN 0 ELSE heldUntil
    /\ UNCHANGED <<now, fence, invPhase, invExpiry,
                   intentState, intentAt, intentVisibleAt, storeState,
                   storeLandAt, outcomeState, outcomeIssuedAt, outcomeReplyLost,
                   outcomeReturnAt, outcomeVisibleAt, outcomeRecords,
                   closingKind, closingState, closingReturnAt, closingVisibleAt,
                   closingRecords, sweepNextA, sweepNextB, sweepPhaseA,
                   sweepPhaseB, sweepDeaths, pauses,
                   opKind, opState, opReturnAt, opVisibleAt, opRecords, opNamed>>

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
AfterOpRet == IF opState = "pending" /\ opReturnAt = now + 1
              THEN 0 ELSE opReturnAt
AfterOpVis == IF opState \in {"pending", "returned"} /\ opVisibleAt = now + 1
              THEN 0 ELSE opVisibleAt
NextOp == IF opState = "pending" /\ opReturnAt = now + 1
          THEN (IF opVisibleAt = now + 1 THEN "visible" ELSE "returned")
          ELSE IF opState \in {"pending", "returned"} /\ opVisibleAt = now + 1
          THEN "visible" ELSE opState

NextClosing == IF closingState = "pending" /\ closingReturnAt = now + 1
               THEN (IF closingVisibleAt = now + 1 THEN "visible" ELSE "returned")
               ELSE IF closingState = "returned" /\ closingVisibleAt = now + 1
               THEN "visible" ELSE closingState

Tick ==
    /\ now < MaxTime
    /\ ~AnySweepScheduled
    /\ ~AnyTakeReady
    /\ ~AnySweepDeciding
    /\ ~(opPhase = "waiting" /\ SectionFree)
    /\ ~(opPhase = "holding" /\ holder = "op")
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
    /\ opState' = NextOp
    /\ opReturnAt' = AfterOpRet
    /\ opVisibleAt' = AfterOpVis
    /\ UNCHANGED <<fence, invPhase, holder, invExpiry, heldUntil,
                   intentAt, outcomeIssuedAt, outcomeReplyLost,
                   outcomeRecords, closingKind, closingRecords,
                   sweepNextA, sweepNextB, sweepPhaseA, sweepPhaseB,
                   sweepDeaths, opPhase, opKind, opRecords, opNamed>>

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
    \/ OpSelect
    \/ OpTake
    \/ OpSeen
    \/ OpYield
    \/ OpPrepareOutcome
    \/ OpPrepareAbandon
    \/ OpIssue
    \/ OpDropWrite
    \/ OpReturn
    \/ Tick

Spec == Init /\ [][Next]_vars

\* ---- invariants -----------------------------------------------------------

Inv1_IntentFirst ==
    (storeState /= "none") => intentState = "visible"

\* A resolution that NAMES the record it closes over, and that record, are one
\* act closed twice on purpose and count as one. A resolution that names
\* nothing is a second closing like any other — which is the whole of F6.
ClosingCount == outcomeRecords + closingRecords + opRecords
                - (IF opNamed THEN 1 ELSE 0)

Inv2_OneWriter ==
    /\ outcomeRecords <= 1
    /\ ClosingCount <= 1

Inv4_BoundedClosure ==
    (/\ intentState = "visible"
     /\ invPhase \in {"crashed", "yielded"}
     /\ now >= intentAt + Window)
    => Closed

Inv5_NoFalseAbandon ==
    /\ (closingKind = "abandoned") => storeState \in {"none", "dropped"}
    /\ (opKind = "abandoned" /\ opRecords > 0)
         => storeState \in {"none", "dropped"}

\* Gate 9, F6. A resolution written over an existing closing must NAME it:
\* without the name the precedence rule and Generation acceptance check 2 have
\* no referent, and both read a lawful resolution as a duplicate.
Inv6_SupersessionNamed ==
    (opRecords > 0 /\ closingRecords + outcomeRecords > 0) => opNamed

Safety == TypeOK /\ Inv1_IntentFirst /\ Inv2_OneWriter /\ Inv4_BoundedClosure
          /\ Inv5_NoFalseAbandon /\ Inv6_SupersessionNamed

\* ---- reachability probes --------------------------------------------------
\* Each of these is a DELIBERATE FALSEHOOD, and the checker must REJECT it.
\* They exist because this model has already been caught holding an invariant
\* whose antecedent could not fire inside the horizon (Inv4, above), and
\* "all invariants hold" is worth nothing for a behaviour the configuration
\* cannot reach. A new component earns its invariants only after its probe
\* fails. Run with --buggy: a violation is the pass.
Probe_OperatorNeverWrites == opRecords = 0
Probe_OperatorNeverSupersedes ==
    ~(opRecords > 0 /\ closingRecords + outcomeRecords > 0)
Probe_OperatorNeverHoldsSection == holder /= "op"

====
