---- MODULE immutable-transaction-ledger-rebuild-probe-purgedbound ----
\* EXPECT: violation — reachability probe: no purged outcome is ever bound.
\* Grace Commons — Immutable Transaction Ledger with Selective Disclosure, the binding
\* index and the horizon arithmetic. Spec-level formal sibling of
\* compositions/immutable-transaction-ledger.md; the binding is
\* immutable-transaction-ledger.tla and the reading of two stores
\* immutable-transaction-ledger-reconcile.tla. Derived validator; the English spec is the
\* single source of truth. On any disagreement, diagnose per the entry *The conflict
\* protocol* in pressure-testing.md.
\*
\* ND outcome events, one per disclosure id, and the reconciliation that writes the
\* binding rebuild into the binding index every run (Reconciliation 1 through 3). An
\* outcome event is written by the invocation, whose own binding write lands right after
\* its close (Action wiring 16), or by the sweep or an operator, or by an invocation that
\* died or whose binding write gave no answer (Action wiring 66), none of which write the
\* index. It becomes readable to the ledger enumeration within JWB ticks of its write
\* (Recoverable Invocation's journal write bound) and its payload is purged at its edge,
\* H ticks after its write (Term audit horizon; Retention Window: eligible once now does
\* not precede the deadline), with whatever else happens at that tick in any order.
\*
\* THE RECONCILIATION  One run at a time. A run starts, reads the ledger enumeration
\* (which may give no answer), may meet a store read that gives no answer, and at its end
\* writes the binding rebuild (which may give no answer), all within RB ticks of its
\* start (Capability requirement 32), time free to pass between each step. The next run
\* starts within C ticks of a run's end (Reconciliation 2: the cadence counted after each
\* run, as Recoverable Invocation's condition 1 counts it), and a run may die anywhere
\* before its write, the next starting within DeathGap ticks of the death (Reconciliation
\* 1: a run at every process start). The rebuild binds every live outcome the
\* enumeration read (Composition state 18, one outcome per disclosure id here), leaves a
\* purged binding standing (Composition state 5, 9), and, read as a replace
\* (ReplaceLive), removes a live binding it did not read (Ledger 2026-10-09-p).
\*
\* TIME is each outcome's age and the run's own age, capped, so the model has no horizon
\* and its state space is bounded by its records alone. The clock offset allowance is 0:
\* every duration here is read on one clock, and a constant offset between two clocks
\* moves no duration, so the allowance Capability requirement 33 charges is not exercised.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv1_6  an outcome event purged with no binding in the index had, while it was live,
\*           an outage of the ledger enumeration or of the index's store that the run
\*           meeting it alerted (Invariant 1.6 as the page qualifies it: "A never-written
\*           entry is foreclosed but for an outage that reaches within two cadences and
\*           three runs of the horizon ... each alerted by the run that met it",
\*           Reconciliation 30, 31; Capability requirement 33; Composition state 9).
\*
\* WHAT THE MODEL FOUND  Capability requirement 33, as the page stood at dbe17f5,
\* budgeted no run that dies. At H = C + 2 x RB + JWB + 1, the least horizon it then
\* admitted, a run that dies before its write loses the binding of an outcome no
\* invocation bound, and nothing alerts: the death is neither an outage of the
\* enumeration nor of the index's store (-buggy-deadrun: an outcome the
\* sweep wrote becomes readable just after one run's enumeration; that run ends, the next
\* starts a cadence later and dies, and the purge lands before the run after it reads).
\* The run that missed the outcome, a cadence, the run that dies, a cadence, the run that
\* captures: H must exceed 2 x C + 3 x RB + JWB, the shape of Recoverable Invocation's
\* own condition 1, which budgets one dead sweep run beside this reconciliation; with the
\* next run started at once at the restart (DeathGap = 0), C + 3 x RB + JWB. Measured by
\* controlled variation over seven (C, RB, JWB) tuples from (1, 1, 0) to (2, 2, 1), each
\* least horizon found by raising H one tick at a time with no outage budgeted: with no
\* death the least H that holds is C + 2 x RB + JWB + 1 on every tuple, so Capability
\* requirement 33 is exact for the runs it counts; with one death it is 2 x C + 3 x RB +
\* JWB + 1, and C + 3 x RB + JWB + 1 with DeathGap = 0, on every tuple. The main
\* configuration carries the first. Counted start to start instead (a variant of this
\* module, the next run within C of the last start, over five tuples), the least horizon
\* is C + RB + JWB + 1 with no death, C + 2 x RB + JWB + 1 — Capability requirement 33
\* exactly — with one death and the restart run at once, and 2 x C + 2 x RB + JWB + 1 with
\* the next run a cadence after the death: that page's horizon budgeted a dead run only
\* on that reading of the cadence with Reconciliation 1's run at once, and said neither.
\* The page now charges two cadences and three runs (Capability requirement 33), and the
\* main configuration sits at the least horizon that admits.
\*
\* WHAT CARRIES IT  The rebuild written every run, so an outcome no invocation bound is
\* bound (-buggy-onwrite); a rebuild that never removes a purged binding (-buggy-replace);
\* a rebuild withheld only where the enumeration gave no answer, never for a store read
\* (Reconciliation 28, -buggy-storeblocks); the alert on every read and every write that
\* gave no answer (Reconciliation 30, 31, -buggy-silent); and the horizon
\* (-buggy-deadrun, -buggy-tight).
\*
\* NOT MODELED
\*   - Two outcome events for one disclosure id — Recoverable Invocation's late append
\*     under journal fence none, or a settling outcome beside a superseded one — and so
\*     Composition state 18's lowest sequence number and the open lines 2026-10-09-i and
\*     2026-10-09-q, which are about which of two outcomes a binding names.
\*   - The record read a rebuild needs for each outcome's retention state (2026-10-09-h):
\*     an outcome is live here exactly while its payload is unpurged.
\*   - The loss of a binding the index held, which is the index durability's (Capability
\*     requirement 19, 20), and two runs at once on two nodes: a second node's runs only
\*     add runs, and a stale run's replace removes only a live binding, which the next run
\*     restores, as the single sequence here already shows.
\*   - Clock steps, which would charge the allowance.
\*
\* THE BUDGET  MaxDeaths dead runs, MaxFails outages of the enumeration or the index's
\* store, MaxStoreFails store reads that gave no answer: one each, so a death and an
\* alerted outage fit together. ND outcome events: one in the main configuration, 12,100
\* states; at ND = 2, 578,490, holding (past the harness's cap, run with the checker's
\* caps raised), and -buggy-deadrun is rejected there too. Time is capped ages, so there
\* is no tick bound to raise.
\*
\* TWINS AND PROBES  Each is this module byte for byte below its header, with one
\* constant or one invariant changed in its .cfg: -buggy-deadrun, -buggy-tight,
\* -buggy-onwrite, -buggy-replace, -buggy-storeblocks, -buggy-silent; -probe-purgedbound,
\* -probe-recoveredbound, -probe-storedown, -probe-honestloss, -probe-erased.
EXTENDS Naturals, FiniteSets

\* H              the audit horizon, in ticks from an outcome's write to its purge.
\* C              the reconciliation cadence: the most ticks between a run's end and the
\*                next run's start.
\* RB             the reconciliation run bound.
\* JWB            the journal write bound: the most ticks from an outcome's write to its
\*                being readable by the enumeration.
\* DeathGap       the most ticks between a run's death and the next run's start.
\* RebuildEveryRun  TRUE: every run whose enumeration answered writes the rebuild
\*                (Reconciliation 3). FALSE: only an invocation's own write binds.
\* KeepPurged     TRUE: a rebuild never removes a purged binding (Composition state 9).
\* StoreBlocks    FALSE: only an enumeration that gave no answer withholds the rebuild
\*                (Reconciliation 28). TRUE: a store read that gave no answer does too.
\* Alert          TRUE: a run alerts an enumeration and a rebuild write that gave no
\*                answer (Reconciliation 30, 31).
\* ReplaceLive    TRUE: writing the rebuild removes a live binding it did not read.
\* ND, MaxDeaths, MaxFails, MaxStoreFails  outcome events and the budgets.
CONSTANTS H, C, RB, JWB, DeathGap, RebuildEveryRun, KeepPurged, StoreBlocks, Alert,
          ReplaceLive, ND, MaxDeaths, MaxFails, MaxStoreFails

Ds == 1..ND
GapCap == IF C > DeathGap THEN C ELSE DeathGap
\* An outcome event: none (not yet written), unread (written, not yet readable), read
\* (readable and live), purged (its payload destroyed at its edge).
OStates == {"none", "unread", "read", "purged"}

VARIABLES
    oSt,      \* oSt[d]: the state of disclosure d's outcome event
    oAge,     \* oAge[d]: ticks since it was written, capped at H
    oBy,      \* oBy[d]: "own" where the invocation's own binding write landed, "none"
              \* where nothing wrote the index; "-" before the write
    bound,    \* bound[d]: the binding index carries d's binding
    excused,  \* excused[d]: an alerted outage of the enumeration or the index's store met
              \* d's outcome while it was live
    rPh,      \* the reconciliation: "gap" between runs, "run" in one
    rAge,     \* ticks since the run started, or since the gap began
    rDeath,   \* the gap follows a run's death
    rEnum,    \* the run's enumeration: "no" not yet read, "ok" answered, "fail" no answer
    rSaw,     \* rSaw[d]: the run's enumeration read d's outcome live
    rStore,   \* a store read of this run gave no answer
    deaths, fails, storeFails,
    lastEnd   \* how the last run ended: "-", "wrote", "wroteStoreDown", "withheld",
              \* "failedWrite", "died" (read only by the probes)
vars == <<oSt, oAge, oBy, bound, excused, rPh, rAge, rDeath, rEnum, rSaw, rStore,
          deaths, fails, storeFails, lastEnd>>

TypeOK ==
    /\ oSt \in [Ds -> OStates]
    /\ oAge \in [Ds -> 0..H]
    /\ oBy \in [Ds -> {"-", "own", "none"}]
    /\ bound \in [Ds -> BOOLEAN]
    /\ excused \in [Ds -> BOOLEAN]
    /\ rPh \in {"gap", "run"}
    /\ rAge \in 0..(IF RB > GapCap THEN RB ELSE GapCap)
    /\ rDeath \in BOOLEAN
    /\ rEnum \in {"no", "ok", "fail"}
    /\ rSaw \in [Ds -> BOOLEAN]
    /\ rStore \in BOOLEAN
    /\ deaths \in 0..MaxDeaths
    /\ fails \in 0..MaxFails
    /\ storeFails \in 0..MaxStoreFails
    /\ lastEnd \in {"-", "wrote", "wroteStoreDown", "withheld", "failedWrite", "died"}

Init ==
    /\ oSt = [d \in Ds |-> "none"]
    /\ oAge = [d \in Ds |-> 0]
    /\ oBy = [d \in Ds |-> "-"]
    /\ bound = [d \in Ds |-> FALSE]
    /\ excused = [d \in Ds |-> FALSE]
    /\ rPh = "gap"
    /\ rAge = 0
    /\ rDeath = FALSE
    /\ rEnum = "no"
    /\ rSaw = [d \in Ds |-> FALSE]
    /\ rStore = FALSE
    /\ deaths = 0
    /\ fails = 0
    /\ storeFails = 0
    /\ lastEnd = "-"

\* --- the outcome events ---

\* An outcome event lands: by an invocation whose own binding write lands after its close
\* ("own"), or by a writer that writes no binding ("none").
Write(d, by) ==
    /\ oSt[d] = "none"
    /\ oSt' = [oSt EXCEPT ![d] = "unread"]
    /\ oAge' = [oAge EXCEPT ![d] = 0]
    /\ oBy' = [oBy EXCEPT ![d] = by]
    /\ bound' = [bound EXCEPT ![d] = (by = "own")]
    /\ UNCHANGED <<excused, rPh, rAge, rDeath, rEnum, rSaw, rStore, deaths, fails,
                   storeFails, lastEnd>>

\* The outcome event becomes readable to the enumeration.
Readable(d) ==
    /\ oSt[d] = "unread"
    /\ oSt' = [oSt EXCEPT ![d] = "read"]
    /\ UNCHANGED <<oAge, oBy, bound, excused, rPh, rAge, rDeath, rEnum, rSaw, rStore,
                   deaths, fails, storeFails, lastEnd>>

\* The outcome event's payload is purged at its edge, the disclosure id with it.
Purge(d) ==
    /\ oSt[d] = "read"
    /\ oAge[d] >= H
    /\ oSt' = [oSt EXCEPT ![d] = "purged"]
    /\ UNCHANGED <<oAge, oBy, bound, excused, rPh, rAge, rDeath, rEnum, rSaw, rStore,
                   deaths, fails, storeFails, lastEnd>>

\* --- the reconciliation ---

RunStart ==
    /\ rPh = "gap"
    /\ rPh' = "run"
    /\ rAge' = 0
    /\ rDeath' = FALSE
    /\ rEnum' = "no"
    /\ rSaw' = [d \in Ds |-> FALSE]
    /\ rStore' = FALSE
    /\ UNCHANGED <<oSt, oAge, oBy, bound, excused, deaths, fails, storeFails, lastEnd>>

\* The ledger enumeration answers: every outcome event readable and live.
Enumerate ==
    /\ rPh = "run"
    /\ rEnum = "no"
    /\ rEnum' = "ok"
    /\ rSaw' = [d \in Ds |-> oSt[d] = "read"]
    /\ UNCHANGED <<oSt, oAge, oBy, bound, excused, rPh, rAge, rDeath, rStore, deaths,
                   fails, storeFails, lastEnd>>

\* The ledger enumeration gives no answer; the run alerts it (Reconciliation 30).
EnumFail ==
    /\ rPh = "run"
    /\ rEnum = "no"
    /\ fails < MaxFails
    /\ rEnum' = "fail"
    /\ fails' = fails + 1
    /\ excused' = [d \in Ds |-> excused[d] \/ (Alert /\ oSt[d] = "read")]
    /\ UNCHANGED <<oSt, oAge, oBy, bound, rPh, rAge, rDeath, rSaw, rStore, deaths,
                   storeFails, lastEnd>>

\* A read of the accounting store gives no answer (Reconciliation 29, 30).
StoreFail ==
    /\ rPh = "run"
    /\ ~rStore
    /\ storeFails < MaxStoreFails
    /\ rStore' = TRUE
    /\ storeFails' = storeFails + 1
    /\ UNCHANGED <<oSt, oAge, oBy, bound, excused, rPh, rAge, rDeath, rEnum, rSaw,
                   deaths, fails, lastEnd>>

\* Whether this run writes the rebuild (Reconciliation 3, 28).
Writes == RebuildEveryRun /\ rEnum = "ok" /\ ~(StoreBlocks /\ rStore)
\* The binding index once the rebuild is written.
Rebuilt(d) ==
    IF rSaw[d] THEN TRUE
    ELSE IF oSt[d] = "purged" THEN KeepPurged /\ bound[d]
    ELSE ~ReplaceLive /\ bound[d]

\* The run ends, writing the rebuild where it writes one, and the write answers.
RunEnd ==
    /\ rPh = "run"
    /\ rEnum # "no"
    /\ bound' = IF Writes THEN [d \in Ds |-> Rebuilt(d)] ELSE bound
    /\ lastEnd' = IF ~Writes THEN "withheld" ELSE IF rStore THEN "wroteStoreDown" ELSE "wrote"
    /\ rPh' = "gap"
    /\ rAge' = 0
    /\ UNCHANGED <<oSt, oAge, oBy, excused, rDeath, rEnum, rSaw, rStore, deaths, fails,
                   storeFails>>

\* The run ends, and the rebuild's write gives no answer; the run alerts it
\* (Reconciliation 31).
RunEndWriteFails ==
    /\ rPh = "run"
    /\ Writes
    /\ fails < MaxFails
    /\ fails' = fails + 1
    /\ excused' = [d \in Ds |-> excused[d] \/ (Alert /\ rSaw[d])]
    /\ lastEnd' = "failedWrite"
    /\ rPh' = "gap"
    /\ rAge' = 0
    /\ UNCHANGED <<oSt, oAge, oBy, bound, rDeath, rEnum, rSaw, rStore, deaths,
                   storeFails>>

\* The run dies before its write: nothing is written and nothing alerts.
RunDies ==
    /\ rPh = "run"
    /\ deaths < MaxDeaths
    /\ deaths' = deaths + 1
    /\ rDeath' = TRUE
    /\ lastEnd' = "died"
    /\ rPh' = "gap"
    /\ rAge' = 0
    /\ UNCHANGED <<oSt, oAge, oBy, bound, excused, rEnum, rSaw, rStore, fails,
                   storeFails>>

\* --- time ---

\* A tick ages the run and every written outcome. Time does not pass a bound: a run
\* RB old ends first, a gap at its length is followed by a run first, an outcome JWB old
\* is readable first, and an outcome at its edge is purged first.
Tick ==
    /\ ~(rPh = "run" /\ rAge >= RB)
    /\ ~(rPh = "gap" /\ rAge >= (IF rDeath THEN DeathGap ELSE C))
    /\ \A d \in Ds : ~(oSt[d] = "unread" /\ oAge[d] >= JWB)
    /\ \A d \in Ds : ~(oSt[d] = "read" /\ oAge[d] >= H)
    /\ rAge' = rAge + 1
    /\ oAge' = [d \in Ds |-> IF oSt[d] \in {"unread", "read"} /\ oAge[d] < H
                               THEN oAge[d] + 1 ELSE oAge[d]]
    /\ UNCHANGED <<oSt, oBy, bound, excused, rPh, rDeath, rEnum, rSaw, rStore, deaths,
                   fails, storeFails, lastEnd>>

Next ==
    \/ \E d \in Ds, by \in {"own", "none"} : Write(d, by)
    \/ \E d \in Ds : Readable(d)
    \/ \E d \in Ds : Purge(d)
    \/ RunStart
    \/ Enumerate
    \/ EnumFail
    \/ StoreFail
    \/ RunEnd
    \/ RunEndWriteFails
    \/ RunDies
    \/ Tick

Spec == Init /\ [][Next]_vars

\* --- invariants ---

\* Invariant 1.6, with the page's qualification: a purged outcome's binding is kept, or
\* an alerted outage of the enumeration or the index's store met the outcome while live.
Inv1_6 ==
    \A d \in Ds : (oSt[d] = "purged" /\ ~bound[d]) => excused[d]

\* --- reachability probes: deliberate falsehoods the checker must reject ---

\* No purged outcome is ever bound. Rejected: the truth-bearing half is reached.
Probe_NeverPurgedBound ==
    ~(\E d \in Ds : oSt[d] = "purged" /\ bound[d])

\* No outcome no invocation bound is ever bound. Rejected: the rebuild captures it.
Probe_NeverRecoveredBound ==
    ~(\E d \in Ds : oBy[d] = "none" /\ bound[d])

\* No run whose store read gave no answer writes the rebuild. Rejected: a store outage
\* withholds findings, never the rebuild (Reconciliation 28, 29).
Probe_NeverStoreDownRebuild ==
    lastEnd # "wroteStoreDown"

\* No purged outcome is ever left unbound. Rejected: an alerted outage and a dead run
\* together lose a binding, the honest loss the page names.
Probe_NeverHonestLoss ==
    ~(\E d \in Ds : oSt[d] = "purged" /\ ~bound[d])

\* No live binding an invocation wrote is ever removed. Rejected under ReplaceLive: a run
\* whose enumeration preceded the outcome's readability removes the invocation's own
\* binding at its write, and the next run restores it (Ledger 2026-10-09-p).
Probe_NeverErased ==
    ~(\E d \in Ds : oBy[d] = "own" /\ oSt[d] \in {"unread", "read"} /\ ~bound[d])

====
