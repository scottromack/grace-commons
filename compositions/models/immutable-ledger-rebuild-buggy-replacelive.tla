---- MODULE immutable-ledger-rebuild-buggy-replacelive ----
\* BUGGY TWIN: writing the rebuild removes a live binding it did not read, the replace reading Reconciliation 3 no longer has (its merge dropped); was -probe-erased.
\* Grace Commons — Immutable Ledger with Selective Disclosure, the binding
\* index and the horizon arithmetic. Spec-level formal sibling of
\* compositions/immutable-ledger.md; the binding is
\* immutable-ledger.tla and the reading of two stores
\* immutable-ledger-reconcile.tla. Derived validator; the English spec is the
\* single source of truth. On any disagreement, diagnose per the entry *The conflict
\* protocol* in pressure-testing.md.
\*
\* ND outcome events, one per disclosure id, and, where Second holds, a second outcome
\* event carrying disclosure id 1, written after the first, whose own payload either names
\* the first in supersedes (a settling outcome, Recoverable Invocation Which closing stands
\* 2) or names nothing (a duplicate: Recoverable Invocation's late append, or a superseded
\* outcome outliving its superseder); and the reconciliation that writes the
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
\* 1: a run at every process start). The enumeration reads an outcome event live while its
\* payload is readable and unpurged and no readable payload names it in supersedes (Term
\* live outcome event). The rebuild is written by merge (Reconciliation 3, re-derived
\* 2026-11-22): each disclosure id bound to the live outcome event of the lowest sequence
\* number the enumeration read (Composition state 18), a purged binding kept (Composition
\* state 5, 9) unless the enumeration read a linked outcome event, a live outcome event
\* whose own payload names the purged binding's event in supersedes, which takes the
\* binding (Composition state 19, Term linked outcome event); a purged binding never moves
\* to a live outcome event no surviving payload links to it (Composition state 20), and no
\* binding is removed.
\*
\* TIME is each outcome's age and the run's own age, capped, so the model has no horizon
\* and its state space is bounded by its records alone. The clock offset allowance is 0:
\* every duration here is read on one clock, and a constant offset between two clocks
\* moves no duration, so the allowance Capability requirement 33 charges is not exercised.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv1_6    a disclosure id with a purged outcome event and no binding in the index had,
\*             while an outcome of it was live, an outage of the ledger enumeration or of
\*             the index's store that the run meeting it alerted (Invariant 1.6 as the page
\*             qualifies it, Reconciliation 30, 31; Capability requirement 33; Composition
\*             state 9).
\*   Inv_R3Merge  no binding is ever removed (Reconciliation 3: by merge, no binding
\*             removed; Composition state 9). An action property.
\*   Inv_CS19  a run that wrote the rebuild leaves no binding on an outcome event that a
\*             live outcome event it read names in supersedes (Composition state 19, with 18
\*             where the superseded event is still live).
\*   Inv_CS20  a purged binding changes only to a live outcome event that names its event
\*             in supersedes (Composition state 5 with its exception, Composition state 20).
\*             An action property.
\*   Inv_V1_3  a disclosure id a purged binding has named reads bound only on a live
\*             outcome event linked to that binding's event, never on a revived duplicate
\*             (Verdict 1 and Verdict 3 read together: a purged binding beside one unlinked
\*             live outcome reads binding-purged).
\*   Inv_V1a   after a run that wrote the rebuild, a disclosure id that reads bound has its
\*             binding on the live outcome event the run read (Verdict 1a, with Verdict 1),
\*             so [Verify Ledger] and the index agree.
\*   The verdict is the page's own (Verdict 1, 1a, 2, 3): bound on exactly one live outcome
\*   event with no purged binding, or with a linked outcome event; binding-purged on a
\*   purged binding with no linked outcome event and at most one live outcome event.
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
\* least horizon found by raising H one tick at a time with no outage budgeted (2026-10-19,
\* one outcome event per disclosure id). The page now charges two cadences and three runs
\* (Capability requirement 33), and the main configuration sits at the least horizon that
\* admits. 2026-11-22: with the second outcome event the rulings of 2026-11-22 hold as
\* written; nothing found.
\*
\* WHAT CARRIES IT  The rebuild written every run, so an outcome no invocation bound is
\* bound (-buggy-onwrite); a rebuild that never removes a purged binding (-buggy-replace)
\* nor a live one it did not read (-buggy-replacelive: the replace reading Reconciliation 3
\* no longer has); a rebuild withheld only where the enumeration gave no answer, never for
\* a store read (Reconciliation 28, -buggy-storeblocks); the alert on every read and every
\* write that gave no answer (Reconciliation 30, 31, -buggy-silent); the horizon
\* (-buggy-deadrun, -buggy-tight); the rebind to a linked outcome event (-buggy-frozen: a
\* purged binding kept for ever, so a live outcome that supersedes it never takes it); and
\* the rebind to it alone (-buggy-anydup: a purged binding moved to any live outcome event,
\* so a duplicate outliving its superseder reads bound again).
\*
\* NOT MODELED
\*   - A second outcome event whose own write binds (an invocation's late-appended close
\*     writes the binding itself, Action wiring 16): here only the first outcome event's
\*     writer may bind, and the second is a settling outcome or a duplicate the rebuild
\*     alone binds. A duplicate the first outcome's payload names in supersedes (a
\*     superseded outcome placed after its superseder) is the unlinked duplicate here once
\*     the superseder is purged.
\*   - The record read a rebuild needs for each outcome's retention state, and its
\*     unreadable answer (Reconciliation 28's second arm; 2026-10-09-h): an outcome is
\*     live here exactly while its payload is unpurged.
\*   - The loss of a binding the index held, which is the index durability's (Capability
\*     requirement 19, 20), and two runs at once on two nodes: a second node's runs only
\*     add runs, and under merge no run removes a binding.
\*   - Clock steps, which would charge the allowance.
\*
\* THE BUDGET  MaxDeaths dead runs, MaxFails outages of the enumeration or the index's
\* store, MaxStoreFails store reads that gave no answer: one each, so a death and an
\* alerted outage fit together. ND = 1 outcome event and the second one (Second = TRUE)
\* in the main configuration. Time is capped ages, so there is no tick bound to raise.
\*
\* TWINS AND PROBES  Each is this module byte for byte below its header, with one
\* constant or one invariant changed in its .cfg: -buggy-deadrun, -buggy-tight,
\* -buggy-onwrite, -buggy-replace, -buggy-replacelive, -buggy-storeblocks, -buggy-silent,
\* -buggy-frozen, -buggy-anydup; -probe-purgedbound, -probe-recoveredbound,
\* -probe-storedown, -probe-honestloss, -probe-rebind, -probe-dupbeside. Retired
\* 2026-11-22: -probe-erased (a run's replace removing an invocation's live binding), now
\* -buggy-replacelive, Reconciliation 3 writing by merge.
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
\* ReplaceLive    FALSE: the rebuild is written by merge (Reconciliation 3). TRUE: writing
\*                it removes a live binding it did not read.
\* Second         TRUE: a second outcome event carrying disclosure id 1 may be written.
\* RebindLinked   TRUE: a purged binding moves to a linked outcome event the enumeration
\*                read (Composition state 19).
\* AnyDup         FALSE: a purged binding moves to no other live outcome event
\*                (Composition state 20). TRUE: to the lowest one the enumeration read.
\* ND, MaxDeaths, MaxFails, MaxStoreFails  disclosure ids and the budgets.
CONSTANTS H, C, RB, JWB, DeathGap, RebuildEveryRun, KeepPurged, StoreBlocks, Alert,
          ReplaceLive, Second, RebindLinked, AnyDup, ND, MaxDeaths, MaxFails, MaxStoreFails

Ds == 1..ND
\* The outcome events: e carries disclosure id e for e <= ND; event ND + 1, where Second
\* holds, carries disclosure id 1. An event's number is its sequence number.
NE == ND + (IF Second THEN 1 ELSE 0)
Evs == 1..NE
Dsc(e) == IF e <= ND THEN e ELSE 1
GapCap == IF C > DeathGap THEN C ELSE DeathGap
Min(S) == CHOOSE x \in S : \A y \in S : x <= y
\* An outcome event: none (not yet written), unread (written, not yet readable), read
\* (readable, its payload unpurged), purged (its payload destroyed at its edge).
OStates == {"none", "unread", "read", "purged"}

VARIABLES
    oSt,      \* oSt[e]: the state of outcome event e
    oAge,     \* oAge[e]: ticks since it was written, capped at H
    oBy,      \* oBy[e]: "own" where the invocation's own binding write landed, "none"
              \* where nothing wrote the index; "-" before the write
    sup,      \* sup[e]: the outcome event e's own payload names in supersedes; 0 for none
    bnd,      \* bnd[d]: the outcome event the binding index's binding for d names; 0 none
    pbe,      \* pbe[d]: the first event a purged binding for d named; 0 while none has
              \* (a ghost, read only by Inv_V1_3 and the probes)
    excused,  \* excused[e]: an alerted outage of the enumeration or the index's store met
              \* e while it was live
    rPh,      \* the reconciliation: "gap" between runs, "run" in one
    rAge,     \* ticks since the run started, or since the gap began
    rDeath,   \* the gap follows a run's death
    rEnum,    \* the run's enumeration: "no" not yet read, "ok" answered, "fail" no answer
    rSaw,     \* rSaw[e]: the run's enumeration read e live
    rStore,   \* a store read of this run gave no answer
    deaths, fails, storeFails,
    lastEnd   \* how the last run ended: "-", "wrote", "wroteStoreDown", "withheld",
              \* "failedWrite", "died"
vars == <<oSt, oAge, oBy, sup, bnd, pbe, excused, rPh, rAge, rDeath, rEnum, rSaw, rStore,
          deaths, fails, storeFails, lastEnd>>

TypeOK ==
    /\ oSt \in [Evs -> OStates]
    /\ oAge \in [Evs -> 0..H]
    /\ oBy \in [Evs -> {"-", "own", "none"}]
    /\ sup \in [Evs -> 0..NE]
    /\ bnd \in [Ds -> 0..NE]
    /\ pbe \in [Ds -> 0..NE]
    /\ excused \in [Evs -> BOOLEAN]
    /\ rPh \in {"gap", "run"}
    /\ rAge \in 0..(IF RB > GapCap THEN RB ELSE GapCap)
    /\ rDeath \in BOOLEAN
    /\ rEnum \in {"no", "ok", "fail"}
    /\ rSaw \in [Evs -> BOOLEAN]
    /\ rStore \in BOOLEAN
    /\ deaths \in 0..MaxDeaths
    /\ fails \in 0..MaxFails
    /\ storeFails \in 0..MaxStoreFails
    /\ lastEnd \in {"-", "wrote", "wroteStoreDown", "withheld", "failedWrite", "died"}

Init ==
    /\ oSt = [e \in Evs |-> "none"]
    /\ oAge = [e \in Evs |-> 0]
    /\ oBy = [e \in Evs |-> "-"]
    /\ sup = [e \in Evs |-> 0]
    /\ bnd = [d \in Ds |-> 0]
    /\ pbe = [d \in Ds |-> 0]
    /\ excused = [e \in Evs |-> FALSE]
    /\ rPh = "gap"
    /\ rAge = 0
    /\ rDeath = FALSE
    /\ rEnum = "no"
    /\ rSaw = [e \in Evs |-> FALSE]
    /\ rStore = FALSE
    /\ deaths = 0
    /\ fails = 0
    /\ storeFails = 0
    /\ lastEnd = "-"

\* --- the page's reads over the substrate ---

\* An outcome event is live: its payload readable and unpurged, and no readable payload
\* names it in supersedes (Term live outcome event).
LiveE(e) == oSt[e] = "read" /\ ~(\E e2 \in Evs : oSt[e2] = "read" /\ sup[e2] = e)
LiveOf(d) == {e \in Evs : Dsc(e) = d /\ LiveE(e)}
\* A purged binding names d (Term purged binding).
PB(d) == bnd[d] # 0 /\ oSt[bnd[d]] = "purged"
\* The linked outcome events for d (Term linked outcome event).
LinkedOf(d) == {e \in LiveOf(d) : PB(d) /\ sup[e] = bnd[d]}
\* The binding verdict's arms this model reaches (Verdict 1, 1a, 3).
V1(d) == Cardinality(LiveOf(d)) = 1 /\ ~PB(d)
V1a(d) == LinkedOf(d) # {} /\ Cardinality(LiveOf(d)) = 1
V3(d) == PB(d) /\ LinkedOf(d) = {} /\ Cardinality(LiveOf(d)) <= 1
Bound(d) == V1(d) \/ V1a(d)
\* The ghost's next value, given the next binding index and event states.
NextPbe(b, s) == [d \in Ds |-> IF pbe[d] = 0 /\ b[d] # 0 /\ s[b[d]] = "purged"
                                THEN b[d] ELSE pbe[d]]

\* --- the outcome events ---

\* An outcome event lands: the first event of a disclosure id by an invocation whose own
\* binding write lands after its close ("own"), or by a writer that writes no binding
\* ("none"); the second event after the first, by a writer that writes no binding, its
\* payload naming the first in supersedes or nothing.
Write(e, by, s) ==
    /\ oSt[e] = "none"
    /\ (e > ND) => (oSt[1] # "none" /\ by = "none")
    /\ (e <= ND) => (s = 0)
    /\ oSt' = [oSt EXCEPT ![e] = "unread"]
    /\ oAge' = [oAge EXCEPT ![e] = 0]
    /\ oBy' = [oBy EXCEPT ![e] = by]
    /\ sup' = [sup EXCEPT ![e] = s]
    /\ bnd' = IF by = "own" THEN [bnd EXCEPT ![Dsc(e)] = e] ELSE bnd
    /\ UNCHANGED <<pbe, excused, rPh, rAge, rDeath, rEnum, rSaw, rStore, deaths, fails,
                   storeFails, lastEnd>>

\* The outcome event becomes readable to the enumeration.
Readable(e) ==
    /\ oSt[e] = "unread"
    /\ oSt' = [oSt EXCEPT ![e] = "read"]
    /\ UNCHANGED <<oAge, oBy, sup, bnd, pbe, excused, rPh, rAge, rDeath, rEnum, rSaw,
                   rStore, deaths, fails, storeFails, lastEnd>>

\* The outcome event's payload is purged at its edge, its disclosure id and its
\* supersedes with it.
Purge(e) ==
    /\ oSt[e] = "read"
    /\ oAge[e] >= H
    /\ oSt' = [oSt EXCEPT ![e] = "purged"]
    /\ pbe' = NextPbe(bnd, oSt')
    /\ UNCHANGED <<oAge, oBy, sup, bnd, excused, rPh, rAge, rDeath, rEnum, rSaw, rStore,
                   deaths, fails, storeFails, lastEnd>>

\* --- the reconciliation ---

RunStart ==
    /\ rPh = "gap"
    /\ rPh' = "run"
    /\ rAge' = 0
    /\ rDeath' = FALSE
    /\ rEnum' = "no"
    /\ rSaw' = [e \in Evs |-> FALSE]
    /\ rStore' = FALSE
    /\ UNCHANGED <<oSt, oAge, oBy, sup, bnd, pbe, excused, deaths, fails, storeFails,
                   lastEnd>>

\* The ledger enumeration answers: every outcome event live.
Enumerate ==
    /\ rPh = "run"
    /\ rEnum = "no"
    /\ rEnum' = "ok"
    /\ rSaw' = [e \in Evs |-> LiveE(e)]
    /\ UNCHANGED <<oSt, oAge, oBy, sup, bnd, pbe, excused, rPh, rAge, rDeath, rStore,
                   deaths, fails, storeFails, lastEnd>>

\* The ledger enumeration gives no answer; the run alerts it (Reconciliation 30).
EnumFail ==
    /\ rPh = "run"
    /\ rEnum = "no"
    /\ fails < MaxFails
    /\ rEnum' = "fail"
    /\ fails' = fails + 1
    /\ excused' = [e \in Evs |-> excused[e] \/ (Alert /\ oSt[e] = "read")]
    /\ UNCHANGED <<oSt, oAge, oBy, sup, bnd, pbe, rPh, rAge, rDeath, rSaw, rStore, deaths,
                   storeFails, lastEnd>>

\* A read of the accounting store gives no answer (Reconciliation 29, 30).
StoreFail ==
    /\ rPh = "run"
    /\ ~rStore
    /\ storeFails < MaxStoreFails
    /\ rStore' = TRUE
    /\ storeFails' = storeFails + 1
    /\ UNCHANGED <<oSt, oAge, oBy, sup, bnd, pbe, excused, rPh, rAge, rDeath, rEnum, rSaw,
                   deaths, fails, lastEnd>>

\* Whether this run writes the rebuild (Reconciliation 3, 28).
Writes == RebuildEveryRun /\ rEnum = "ok" /\ ~(StoreBlocks /\ rStore)
\* The binding for d once the rebuild is written by merge: a purged binding kept, or
\* moved to a linked outcome event the enumeration read (Composition state 5, 9, 19, 20);
\* otherwise the lowest live outcome event the enumeration read (Composition state 18), or
\* the binding as it stood.
Rebuilt(d) ==
    LET saw == {e \in Evs : rSaw[e] /\ Dsc(e) = d}
        lk == {e \in saw : sup[e] = bnd[d]}
    IN IF PB(d)
       THEN (IF RebindLinked /\ lk # {} THEN Min(lk)
             ELSE IF AnyDup /\ saw # {} THEN Min(saw)
             ELSE IF KeepPurged THEN bnd[d] ELSE 0)
       ELSE IF saw # {} THEN Min(saw)
       ELSE IF ReplaceLive THEN 0 ELSE bnd[d]

\* The run ends, writing the rebuild where it writes one, and the write answers.
RunEnd ==
    /\ rPh = "run"
    /\ rEnum # "no"
    /\ bnd' = IF Writes THEN [d \in Ds |-> Rebuilt(d)] ELSE bnd
    /\ pbe' = NextPbe(bnd', oSt)
    /\ lastEnd' = IF ~Writes THEN "withheld" ELSE IF rStore THEN "wroteStoreDown" ELSE "wrote"
    /\ rPh' = "gap"
    /\ rAge' = 0
    /\ UNCHANGED <<oSt, oAge, oBy, sup, excused, rDeath, rEnum, rSaw, rStore, deaths, fails,
                   storeFails>>

\* The run ends, and the rebuild's write gives no answer; the run alerts it
\* (Reconciliation 31).
RunEndWriteFails ==
    /\ rPh = "run"
    /\ Writes
    /\ fails < MaxFails
    /\ fails' = fails + 1
    /\ excused' = [e \in Evs |-> excused[e] \/ (Alert /\ rSaw[e])]
    /\ lastEnd' = "failedWrite"
    /\ rPh' = "gap"
    /\ rAge' = 0
    /\ UNCHANGED <<oSt, oAge, oBy, sup, bnd, pbe, rDeath, rEnum, rSaw, rStore, deaths,
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
    /\ UNCHANGED <<oSt, oAge, oBy, sup, bnd, pbe, excused, rEnum, rSaw, rStore, fails,
                   storeFails>>

\* --- time ---

\* A tick ages the run and every written outcome. Time does not pass a bound: a run
\* RB old ends first, a gap at its length is followed by a run first, an outcome JWB old
\* is readable first, and an outcome at its edge is purged first.
Tick ==
    /\ ~(rPh = "run" /\ rAge >= RB)
    /\ ~(rPh = "gap" /\ rAge >= (IF rDeath THEN DeathGap ELSE C))
    /\ \A e \in Evs : ~(oSt[e] = "unread" /\ oAge[e] >= JWB)
    /\ \A e \in Evs : ~(oSt[e] = "read" /\ oAge[e] >= H)
    /\ rAge' = rAge + 1
    /\ oAge' = [e \in Evs |-> IF oSt[e] \in {"unread", "read"} /\ oAge[e] < H
                                THEN oAge[e] + 1 ELSE oAge[e]]
    /\ UNCHANGED <<oSt, oBy, sup, bnd, pbe, excused, rPh, rDeath, rEnum, rSaw, rStore,
                   deaths, fails, storeFails, lastEnd>>

Next ==
    \/ \E e \in Evs, by \in {"own", "none"}, s \in 0..1 : Write(e, by, s)
    \/ \E e \in Evs : Readable(e)
    \/ \E e \in Evs : Purge(e)
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

\* @isolate-facets Inv_CS19 Inv_V1a
\* Verdict 1a reads bound on the linked outcome event whichever event the binding names,
\* so a run that leaves the binding on the purged event breaks both.
\* @isolate-facets Inv_CS20 Inv_V1_3
\* A purged binding moved to an unlinked live outcome event is the binding Verdict 1 then
\* reads bound, so a rebuild that moves it breaks both.

\* The last run wrote the rebuild and no run has started since.
RunWrote == rPh = "gap" /\ lastEnd \in {"wrote", "wroteStoreDown"}

\* Invariant 1.6, with the page's qualification: a disclosure id whose outcome event is
\* purged keeps a binding, or an alerted outage met an outcome event of it while live.
Inv1_6 ==
    \A d \in Ds : (bnd[d] = 0 /\ \E e \in Evs : Dsc(e) = d /\ oSt[e] = "purged")
                  => (\E e \in Evs : Dsc(e) = d /\ excused[e])

\* Reconciliation 3: the rebuild is written by merge, no binding removed.
Inv_R3Merge ==
    [][\A d \in Ds : (bnd[d] # 0) => (bnd'[d] # 0)]_vars

\* Composition state 19: a run that wrote the rebuild left no binding on an event a live
\* outcome event it read names in supersedes.
Inv_CS19 ==
    RunWrote => ~(\E e \in Evs : rSaw[e] /\ sup[e] # 0 /\ bnd[Dsc(e)] = sup[e])

\* Composition state 5 and 20: a purged binding changes only to a live outcome event that
\* names its event in supersedes.
Inv_CS20 ==
    [][\A d \in Ds : (PB(d) /\ bnd'[d] # 0 /\ bnd'[d] # bnd[d]) => (sup[bnd'[d]] = bnd[d])]_vars

\* Verdict 1 and 3: a disclosure id a purged binding has named reads bound only on a live
\* outcome event linked to that binding's event.
Inv_V1_3 ==
    \A d \in Ds : (pbe[d] # 0 /\ Bound(d)) => (\A e \in LiveOf(d) : sup[e] = pbe[d])

\* Verdict 1a: after a run that wrote the rebuild, a disclosure id that reads bound has
\* its binding on the live outcome event the run read.
Inv_V1a ==
    RunWrote => (\A d \in Ds : \A e \in LiveOf(d) : (Bound(d) /\ rSaw[e]) => (bnd[d] = e))

\* --- reachability probes: deliberate falsehoods the checker must reject ---

\* No purged binding ever stands. Rejected: the truth-bearing half is reached.
Probe_NeverPurgedBound ==
    ~(\E d \in Ds : PB(d))

\* No outcome no invocation bound is ever bound. Rejected: the rebuild captures it.
Probe_NeverRecoveredBound ==
    ~(\E e \in Evs : oBy[e] = "none" /\ bnd[Dsc(e)] = e)

\* No run whose store read gave no answer writes the rebuild. Rejected: a store outage
\* withholds findings, never the rebuild (Reconciliation 28, 29).
Probe_NeverStoreDownRebuild ==
    lastEnd # "wroteStoreDown"

\* No purged outcome is ever left with no binding for its disclosure id. Rejected: an
\* alerted outage and a dead run together lose a binding, the honest loss the page names.
Probe_NeverHonestLoss ==
    ~(\E e \in Evs : oSt[e] = "purged" /\ bnd[Dsc(e)] = 0)

\* No purged binding ever moves. Rejected: a linked outcome event takes it
\* (Composition state 19).
Probe_NeverRebind ==
    ~(\E d \in Ds : pbe[d] # 0 /\ bnd[d] # 0 /\ bnd[d] # pbe[d])

\* No purged binding ever stands beside a live outcome event that is not linked to it.
\* Rejected: the duplicate of Composition state 20 is reached, read binding-purged.
Probe_NeverDupBeside ==
    ~(\E d \in Ds : V3(d) /\ LiveOf(d) # {})

====
