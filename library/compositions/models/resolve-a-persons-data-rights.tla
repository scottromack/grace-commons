---- MODULE resolve-a-persons-data-rights ----
\* Grace Commons — Resolve a Person's Data Rights. Spec-level formal sibling of
\* compositions/resolve-a-persons-data-rights.md. Derived validator; the English spec is the single
\* source of truth. On any disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-22 for the page's unit `composes Recoverable Invocation`: [Fulfill Erasure Request]
\* binds one act kind, dsar.erasure_execution, on a Recoverable Invocation instance (Composes 15 through 19,
\* Term erasure binding), and [Receive Request] and [Fulfill Access Request] are one transaction each under
\* Execution Contract Database 1, so no access state interleaves and the access models of 2026-11-10 retired.
\* This model checks what the binding leaves the page's own: the commit partition, the erasure probe, the
\* re-entry bind and the seal, over Recoverable Invocation's contracts. Recoverable Invocation's own protocol
\* (one writer per act, the sweep's edges, the lease, the fence of a stale writer, an intent closed once) is
\* recoverable-invocation.tla's, which checks it.
\*
\* Two files carry this one module body. resolve-a-persons-data-rights.tla runs two erasure calls of one
\* request, f and g, against Recoverable Invocation's sweep w and an operator. resolve-a-persons-data-rights-
\* admission.tla runs three calls, f, g and h, so two erasures meet at the open's pre-check and the execution
\* commit's guard while a third binds.
\*
\* ONE request, ONE act key (the request id), and a universe of two records: S, settled before any planned
\* call, and R, the one purge plan pair where a call's retention read answered retained (Disposition 17), or
\* settled erased where it answered purged (Disposition 39). The act section is one holder at a time
\* (Recoverable Invocation act section). A call c:
\*   reads the request's state outside any section (Action wiring 5, 6, 43, 44) and enumerates;
\*   opens the act (Action wiring 24): the pre-check under the section answers act-in-flight over an open
\*     intent, act-landed over an outcome (Recoverable Invocation open step 3.9: the re-entry route), and
\*     otherwise writes the intent, which a refusal, an abandonment or an escalation does not stop;
\*   issues the execution commit (Term execution commit): the guard read refuses already-fulfilled, or the
\*     read fails state-unavailable — pre-commit, closed by the invocation refuse (Action wiring 47) — and
\*     otherwise calls Defensible Retention's purge for R, re-invoked after a retry answer
\*     (Disposition 41, 41a), each answer landing R's purge reading (Term purge reading);
\*   commits the disclosure, the fulfilled event and the executed outcome in one transaction (Action wiring
\*     46), which may fail and leave the act the sweep's;
\*   or runs the re-entry bind (Action wiring 44, 49 through 52): one store transaction under its guard,
\*     sealing from the act's standing .executed closing.
\* A call may stop at any moment after its open (a crash, or the unknown arm: the invocation yield, Action
\* wiring 48); its section lapses and a purge still in flight may land later, or never. The sweep w probes
\* an open intent whose call has stopped (Term erasure probe) and writes .executed or .escalated, never a
\* disclosure and never an abandonment. The operator closes an escalated act once no purge of it is in
\* flight: .executed where its commit made a planned call, .abandoned where it made none.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv_OneSeal             a request carries at most one fulfilled event (Invariant 1.2).
\*   Inv_NoOrphanEvent       no fulfilled event without its response disclosure (Invariant 1.1).
\*   Inv_OneDisclosure       a request carries at most one response disclosure (Invariant 5.1).
\*   Inv_NoOrphanDisclosure  no request-scoped disclosure without its fulfilled event, in any state
\*                           (Invariant 1.4; Action wiring 46, 52).
\*   Inv_Accounted           a destruction a planned call made stands under no refused and no abandoned
\*                           intent: the invocation refuse closes only the pre-commit arm (Action wiring 47,
\*                           Term commit partition).
\*   Inv_Evidence            erased is sealed, and an .executed closing carries R erased, only where the store
\*                           shows R purged (Invariant 3.1; Term erasure probe; Action wiring 50).
\*   Inv_Truth               a record the sealed act's own planned call destroyed is never sealed retained
\*                           (Disposition 42, Term purge reading).
\*   Inv_Cover               a sealed set carries the settled record S with the intent's disposition
\*                           (Invariant 2.1, Action wiring 49).
\*
\* THE TWINS, each this file in a configuration with one constant changed:
\*   -buggy-retry          Retry = TRUE         the re-entry bind's fulfilled event issued a second time (Audit arm 21).
\*   -buggy-coverage       FromIntent = FALSE   the re-entry bind sealed from the .executed closing alone (Action wiring 49).
\*   -buggy-abandon        RefuseLate = TRUE    the invocation refuse after a planned call answered (Action wiring 47).
\*   -buggy-unsettled      Unsettled = FALSE    a purge that did not settle R read as a refusal (Disposition 42).
\*   -buggy-taint          Taint = FALSE        a storage-failure then a refusal sealed retained (Term purge reading).
\*   -buggy-evidence       ReadErased = TRUE    a storage-failure read as erased (Invariant 3.1, Term purge reading).
\*   -buggy-orphan         SealFirst = TRUE     the re-entry bind seals ahead of its disclosure (Action wiring 52).
\*   -buggy-probe-erased   ProbeErased = TRUE   the probe answers committed, R erased, over a gate record with R retained (Term erasure probe).
\*   -buggy-bind-split     BindSplit = TRUE     the disclosure committed apart from its fulfilled event (Action wiring 52);
\*                                              bound again after the event failed, a second disclosure (Inv_OneDisclosure).
\*   -probe-recover        a reachability probe: the sweep probes an act its call left open, the act closes .executed,
\*                         and a second call's re-entry bind writes the one fulfilled event.
\*   -probe-late           a reachability probe: a planned purge lands after the sweep's probe read it retained, the
\*                         escalation stands, and the operator's closing and the bind seal R erased.
\*   -probe-gap            a reachability probe: the probe meets a state its four answers do not name.
\*   -admission-buggy-order  ActLanded = FALSE  the open's pre-check skips the act's outcome (Recoverable Invocation open step 3.9).
\*   -admission-probe-again  a reachability probe: a second erasure seals a request the first refused.
\*
\* WHAT THE MODEL FOUND ON THE PAGE (recorded, not cured):
\*   (1) Term erasure probe names four answers, and a state with none of them is reachable: R reads no purge
\*       under the intent's now while a Defensible Retention gate record names it within the plan span (a purge
\*       that answered under-legal-hold, then the invocation stopped), the host delete plan empty — not
\*       committed, not not-committed, not undecidable (Recoverable Invocation act probe 1 asks exactly one).
\*       -probe-gap reaches it; the sweep here escalates it, as it escalates an undecidable act.
\*   (2) Action wiring 6 (act-in-flight) and Action wiring 44 (the re-entry bind) both fire on a request whose
\*       one act is open and another's standing closing is .executed, and the page orders neither. With the
\*       bind's guard read as Action wiring 44's own, Recoverable Invocation open step 3.9 (act-landed) is what
\*       keeps a bind off a live execution commit: -admission-buggy-order seals twice without it.
\*   (3) Composition notes, "Recoverable Invocation's commit is one call", reads a planned call's no answer as
\*       the unknown partition; Term commit partition reads it as committed, R landing unsettled. This model
\*       follows the Term (the rule); unknown is the commit itself not returning (a stopped call).
\*
\* NOT MODELED: the access and the intake (one transaction each, Execution Contract Database 1); Recoverable
\* Invocation's mechanism — the lease, the take, the sweep's examine and horizon edges, the fence of a stale
\* writer (a stopped call writes nothing to the store; its purge, an act outside the store, may land), and the
\* intent closed once, all recoverable-invocation.tla's; the host delete plan and a second purge plan pair
\* (the probe's undecidable on act probe 3a and 7); the plan cap; the retention re-read of a host delete
\* record; a hold's own timeline (Defensible Retention's gate, an answer here); an operator whose outcome data
\* the stores do not bear out (detected, not prevented: Recoverable Invocation Check 6.1), so the operator here
\* closes .executed exactly where its act's commit made a planned call; the index leg and the stall mark; the
\* audit horizon; the state read's failure; the sizing of the largest record; the clock.
EXTENDS Naturals

CONSTANTS Calls, WOn, OpOn, Held, Stor, ActLanded, Retry, Unsettled, Taint, ReadErased,
          FromIntent, RefuseLate, BindSplit, SealFirst, ProbeErased

VARIABLES ph, int, plan, rset, r, cs, issued, exR, probed, holder,
          retR, goneR, gateR, destBy, disc, seals, sealedR, sealAct, badCover, rec,
          sealBy, late, gap
vars == <<ph, int, plan, rset, r, cs, issued, exR, probed, holder,
          retR, goneR, gateR, destBy, disc, seals, sealedR, sealAct, badCover, rec,
          sealBy, late, gap>>

Phases == {"idle", "pre", "open", "call", "commit", "bind", "bind2", "bound", "dead", "done"}
IntStates == {"none", "open", "refused", "executed", "escalated", "abandoned"}

TypeOK ==
    /\ ph \in [Calls -> Phases] /\ int \in [Calls -> IntStates]
    /\ plan \in [Calls -> BOOLEAN] /\ rset \in [Calls -> {"none", "erased"}]
    /\ r \in [Calls -> {"none", "tainted", "erased", "retained", "unsettled"}]
    /\ cs \in [Calls -> {"none", "fly", "retry", "lost"}]
    /\ issued \in [Calls -> BOOLEAN] /\ exR \in [Calls -> {"none", "erased"}] /\ probed \in [Calls -> BOOLEAN]
    /\ holder \in Calls \cup {"none"}
    /\ retR \in Calls \cup {"retained"} /\ goneR \in BOOLEAN /\ gateR \in BOOLEAN /\ destBy \in Calls \cup {"none"}
    /\ disc \in 0..2 /\ seals \in 0..2
    /\ sealedR \in {"none", "erased", "retained", "unsettled"} /\ sealAct \in Calls \cup {"none"}
    /\ badCover \in BOOLEAN /\ rec \in BOOLEAN /\ sealBy \in Calls \cup {"none"}
    /\ late \in BOOLEAN /\ gap \in BOOLEAN

Init ==
    /\ ph = [c \in Calls |-> "idle"] /\ int = [c \in Calls |-> "none"]
    /\ plan = [c \in Calls |-> FALSE] /\ rset = [c \in Calls |-> "none"] /\ r = [c \in Calls |-> "none"]
    /\ cs = [c \in Calls |-> "none"] /\ issued = [c \in Calls |-> FALSE]
    /\ exR = [c \in Calls |-> "none"] /\ probed = [c \in Calls |-> FALSE]
    /\ holder = "none" /\ retR = "retained" /\ goneR = FALSE /\ gateR = FALSE /\ destBy = "none"
    /\ disc = 0 /\ seals = 0 /\ sealedR = "none" /\ sealAct = "none"
    /\ badCover = FALSE /\ rec = FALSE /\ sealBy = "none" /\ late = FALSE /\ gap = FALSE

Inc(n) == IF n < 2 THEN n + 1 ELSE 2

\* The request's state, derived from its records (Composition state 15 through 31).
Fulfilled == seals > 0
AnyOpen == \E c \in Calls : int[c] = "open"
AnyEsc == \E c \in Calls : int[c] = "escalated"
AnyExec == \E c \in Calls : int[c] = "executed"

\* Action wiring 44's condition, read again inside the bind's transaction (Execution Contract Database 2): an
\* .executed closing standing with no fulfilled event naming the request. The state read ahead of it routes
\* act-in-flight (Action wiring 6) and compensation-pending (Action wiring 43) first; inside the transaction
\* the guard is the rule's own.
BindRoute == ~Fulfilled /\ AnyExec

\* A destruction of R a planned call made, whether or not the store shows it.
Destroyed == retR # "retained" \/ goneR
FirstDest(c) == IF destBy = "none" THEN c ELSE destBy

\* What the re-entry bind seals R as, from the act x whose standing closing is .executed: the intent's own
\* disposition where R was settled ahead of the plan (Action wiring 49), erased where the closing shows R
\* purged (Action wiring 50), anomaly carrying unsettled otherwise (Action wiring 51).
BindR(x) == IF ~plan[x] THEN rset[x] ELSE IF exR[x] = "erased" THEN "erased" ELSE "unsettled"

\* The state read and the enumeration, outside any section (Action wiring 5, 6, 43, 44; Disposition 17, 39).
Read(c) ==
    /\ ph[c] = "idle"
    /\ ph' = [ph EXCEPT ![c] = IF Fulfilled \/ AnyOpen \/ AnyEsc THEN "done" ELSE IF AnyExec THEN "bind" ELSE "pre"]
    /\ plan' = [plan EXCEPT ![c] = (retR = "retained")]
    /\ rset' = [rset EXCEPT ![c] = IF retR = "retained" THEN "none" ELSE "erased"]
    /\ UNCHANGED <<int, r, cs, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The invocation open (Action wiring 24, 45): the pre-check under the section.
OpenInFlight(c) ==
    /\ ph[c] = "pre" /\ holder = "none" /\ AnyOpen
    /\ ph' = [ph EXCEPT ![c] = "done"]
    /\ UNCHANGED <<int, plan, rset, r, cs, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

OpenLanded(c) ==
    /\ ph[c] = "pre" /\ holder = "none" /\ ~AnyOpen /\ ActLanded /\ AnyExec
    /\ ph' = [ph EXCEPT ![c] = "bind"]
    /\ UNCHANGED <<int, plan, rset, r, cs, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

Open(c) ==
    /\ ph[c] = "pre" /\ holder = "none" /\ ~AnyOpen /\ ~(ActLanded /\ AnyExec)
    /\ int' = [int EXCEPT ![c] = "open"]
    /\ holder' = c
    /\ ph' = [ph EXCEPT ![c] = "open"]
    /\ UNCHANGED <<plan, rset, r, cs, issued, exR, probed, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The execution commit's guard read: pre-commit where it answers already-fulfilled, or where the read fails
\* state-unavailable — before any planned call — closed by the invocation refuse (Action wiring 47).
GuardRefuse(c) ==
    /\ ph[c] = "open"
    /\ int' = [int EXCEPT ![c] = "refused"]
    /\ holder' = "none"
    /\ ph' = [ph EXCEPT ![c] = "done"]
    /\ UNCHANGED <<plan, rset, r, cs, issued, exR, probed, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The guard passes: the purge of the one plan pair, or, the plan empty, nothing to call.
GuardPass(c) ==
    /\ ph[c] = "open" /\ ~Fulfilled
    /\ cs' = [cs EXCEPT ![c] = IF plan[c] THEN "fly" ELSE "none"]
    /\ issued' = [issued EXCEPT ![c] = plan[c]]
    /\ ph' = [ph EXCEPT ![c] = IF plan[c] THEN "call" ELSE "commit"]
    /\ UNCHANGED <<int, plan, rset, r, exR, probed, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The purge answers ok, or not-known over a retention the read then answers purged: R erased (Disposition
\* 20, 43). Defensible Retention's purge commits its gate record and the purged retention, stamped with the
\* invocation's now, the pairing datum (Term erasure binding).
AnsOk(c) ==
    /\ ph[c] = "call" /\ cs[c] \in {"fly", "retry"}
    /\ retR' = IF retR = "retained" THEN c ELSE retR
    /\ gateR' = IF retR = "retained" THEN TRUE ELSE gateR
    /\ destBy' = IF retR = "retained" THEN FirstDest(c) ELSE destBy
    /\ r' = [r EXCEPT ![c] = "erased"]
    /\ cs' = [cs EXCEPT ![c] = "none"]
    /\ ph' = [ph EXCEPT ![c] = "commit"]
    /\ UNCHANGED <<int, plan, rset, issued, exR, probed, holder, goneR,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The purge answers under-legal-hold: a gate record, R retained (Disposition 21); after a storage-failure,
\* unsettled (Term purge reading).
AnsHeld(c) ==
    /\ Held /\ ph[c] = "call" /\ cs[c] \in {"fly", "retry"} /\ retR = "retained"
    /\ gateR' = TRUE
    /\ r' = [r EXCEPT ![c] = IF cs[c] = "retry" /\ Taint THEN "unsettled" ELSE "retained"]
    /\ cs' = [cs EXCEPT ![c] = "none"]
    /\ ph' = [ph EXCEPT ![c] = "commit"]
    /\ UNCHANGED <<int, plan, rset, issued, exR, probed, holder, retR, goneR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The purge answers storage-failure: the retention stays retained and the record may be gone all the same
\* (Defensible Retention Atomic writes 8, 9). A first one is re-invoked (Disposition 41), a re-invocation's again (Disposition 41a); the
\* last one the plan cap allows is unsettled (Term purge reading, Disposition 42).
AnsStor(c, gone) ==
    /\ Stor /\ ph[c] = "call" /\ cs[c] \in {"fly", "retry"}
    /\ goneR' = IF gone THEN TRUE ELSE goneR
    /\ destBy' = IF gone THEN FirstDest(c) ELSE destBy
    /\ r' = [r EXCEPT ![c] = IF ReadErased THEN "erased"
                             ELSE IF ~Unsettled THEN "retained"
                             ELSE IF cs[c] = "fly" THEN "tainted" ELSE "unsettled"]
    /\ cs' = [cs EXCEPT ![c] = IF ~ReadErased /\ Unsettled /\ cs[c] = "fly" THEN "retry" ELSE "none"]
    /\ ph' = [ph EXCEPT ![c] = IF ~ReadErased /\ Unsettled /\ cs[c] = "fly" THEN "call" ELSE "commit"]
    /\ UNCHANGED <<int, plan, rset, issued, exR, probed, holder, retR, gateR,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* A storage-failure answering a re-invocation is re-invoked again while the plan cap admits a further
\* planned call (Disposition 41a): the run goes on to the first answer other than storage-failure, and the
\* storage-failure above (a plan cap that admits no further call) is its last answer (Term purge reading).
AnsStorAgain(c, gone) ==
    /\ Stor /\ Unsettled /\ ~ReadErased /\ ph[c] = "call" /\ cs[c] = "retry"
    /\ goneR' = IF gone THEN TRUE ELSE goneR
    /\ destBy' = IF gone THEN FirstDest(c) ELSE destBy
    /\ UNCHANGED <<r, cs, ph, int, plan, rset, issued, exR, probed, holder, retR, gateR,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The purge answers no answer within the planned call latency: R unsettled (Term purge reading), the
\* commit going on; the purge may still land, or never.
AnsNone(c) ==
    /\ ph[c] = "call" /\ cs[c] \in {"fly", "retry"}
    /\ r' = [r EXCEPT ![c] = IF Unsettled THEN "unsettled" ELSE "retained"]
    /\ cs' = [cs EXCEPT ![c] = "lost"]
    /\ ph' = [ph EXCEPT ![c] = "commit"]
    /\ UNCHANGED <<int, plan, rset, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* A purge whose call answered no answer, or whose invocation stopped, lands.
LateLand(c) ==
    /\ cs[c] = "lost"
    /\ retR' = IF retR = "retained" THEN c ELSE retR
    /\ gateR' = IF retR = "retained" THEN TRUE ELSE gateR
    /\ destBy' = IF retR = "retained" THEN FirstDest(c) ELSE destBy
    /\ late' = IF probed[c] THEN TRUE ELSE late
    /\ cs' = [cs EXCEPT ![c] = "none"]
    /\ UNCHANGED <<ph, int, plan, rset, r, issued, exR, probed, holder, goneR,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, gap>>

NeverLand(c) ==
    /\ cs[c] = "lost"
    /\ cs' = [cs EXCEPT ![c] = "none"]
    /\ UNCHANGED <<ph, int, plan, rset, r, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The twin's defect: the invocation refuse after a planned call answered.
RefuseAfter(c) ==
    /\ RefuseLate /\ ph[c] = "commit" /\ holder = c /\ issued[c]
    /\ int' = [int EXCEPT ![c] = "refused"]
    /\ holder' = "none"
    /\ ph' = [ph EXCEPT ![c] = "done"]
    /\ UNCHANGED <<plan, rset, r, cs, issued, exR, probed, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* Committed: the disclosure, the erasure fulfilled event and the executed outcome in one transaction (Action
\* wiring 46); the outcome carries only what the stores re-derive (Recoverable Invocation close 5).
Close(c) ==
    /\ ph[c] = "commit" /\ holder = c
    /\ int' = [int EXCEPT ![c] = "executed"]
    /\ exR' = [exR EXCEPT ![c] = IF retR = c THEN "erased" ELSE "none"]
    /\ disc' = Inc(disc)
    /\ seals' = Inc(seals)
    /\ sealedR' = IF seals = 0 THEN (IF plan[c] THEN r[c] ELSE rset[c]) ELSE sealedR
    /\ sealAct' = IF seals = 0 THEN c ELSE sealAct
    /\ sealBy' = IF seals = 0 THEN c ELSE sealBy
    /\ holder' = "none"
    /\ ph' = [ph EXCEPT ![c] = "done"]
    /\ UNCHANGED <<plan, rset, r, cs, issued, probed, retR, goneR, gateR, destBy, badCover, rec, late, gap>>

\* The transaction fails: nothing commits, the close's recording-failure carrying outcome, the act the
\* sweep's (Action wiring 46).
CloseFail(c) ==
    /\ ph[c] = "commit" /\ holder = c
    /\ holder' = "none"
    /\ ph' = [ph EXCEPT ![c] = "done"]
    /\ UNCHANGED <<int, plan, rset, r, cs, issued, exR, probed, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The call stops: a crash, or the unknown arm's invocation yield (Action wiring 48). Its section lapses.
Stop(c) ==
    /\ ph[c] \in {"open", "call", "commit"}
    /\ ph' = [ph EXCEPT ![c] = "dead"]
    /\ holder' = IF holder = c THEN "none" ELSE holder
    /\ cs' = [cs EXCEPT ![c] = IF cs[c] \in {"fly", "retry"} THEN "lost" ELSE cs[c]]
    /\ UNCHANGED <<int, plan, rset, r, issued, exR, probed, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The re-entry bind (Action wiring 44, 49 through 52): one store transaction, its guard read inside it.
BindTx(c) ==
    /\ ph[c] = "bind" /\ BindRoute /\ ~BindSplit /\ ~SealFirst
    /\ \E x \in Calls :
        /\ int[x] = "executed"
        /\ sealedR' = BindR(x)
        /\ sealAct' = x
    /\ disc' = Inc(disc)
    /\ seals' = Inc(seals)
    /\ badCover' = IF FromIntent THEN badCover ELSE TRUE
    /\ rec' = TRUE
    /\ sealBy' = c
    /\ ph' = [ph EXCEPT ![c] = "bound"]
    /\ UNCHANGED <<int, plan, rset, r, cs, issued, exR, probed, holder, retR, goneR, gateR, destBy, late, gap>>

BindAnswer(c) ==
    /\ ph[c] = "bound"
    /\ ph' = [ph EXCEPT ![c] = "done"]
    /\ UNCHANGED <<int, plan, rset, r, cs, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The twin's defect: the bind's fulfilled event issued a second time (Audit arm 21).
Reissue(c) ==
    /\ Retry /\ ph[c] = "bound"
    /\ seals' = Inc(seals)
    /\ ph' = [ph EXCEPT ![c] = "done"]
    /\ UNCHANGED <<int, plan, rset, r, cs, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   disc, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The bind's transaction refuses or fails: nothing commits, and the caller calls again — here, after a split
\* bind's second write failed, the same call binds once more.
BindFail(c) ==
    /\ ph[c] \in {"bind", "bind2"}
    /\ ph' = [ph EXCEPT ![c] = IF ph[c] = "bind2" THEN "bind" ELSE "done"]
    /\ UNCHANGED <<int, plan, rset, r, cs, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* The twins' defects: the bind split into two transactions — the disclosure first (BindSplit), or the
\* fulfilled event first (SealFirst).
SplitDisc(c) ==
    /\ BindSplit /\ ph[c] = "bind" /\ BindRoute
    /\ disc' = Inc(disc)
    /\ ph' = [ph EXCEPT ![c] = "bind2"]
    /\ UNCHANGED <<int, plan, rset, r, cs, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

SplitSeal(c) ==
    /\ BindSplit /\ ph[c] = "bind2"
    /\ \E x \in Calls :
        /\ int[x] = "executed"
        /\ sealedR' = IF seals = 0 THEN BindR(x) ELSE sealedR
        /\ sealAct' = IF seals = 0 THEN x ELSE sealAct
    /\ seals' = Inc(seals)
    /\ rec' = TRUE
    /\ sealBy' = IF seals = 0 THEN c ELSE sealBy
    /\ ph' = [ph EXCEPT ![c] = "done"]
    /\ UNCHANGED <<int, plan, rset, r, cs, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   disc, badCover, late, gap>>

FirstSeal(c) ==
    /\ SealFirst /\ ph[c] = "bind" /\ BindRoute
    /\ \E x \in Calls :
        /\ int[x] = "executed"
        /\ sealedR' = BindR(x)
        /\ sealAct' = x
    /\ seals' = Inc(seals)
    /\ rec' = TRUE
    /\ sealBy' = c
    /\ ph' = [ph EXCEPT ![c] = "bind2"]
    /\ UNCHANGED <<int, plan, rset, r, cs, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   disc, badCover, late, gap>>

FirstDisc(c) ==
    /\ SealFirst /\ ph[c] = "bind2"
    /\ disc' = Inc(disc)
    /\ ph' = [ph EXCEPT ![c] = "done"]
    /\ UNCHANGED <<int, plan, rset, r, cs, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* Recoverable Invocation's sweep, under the act section, over an open intent whose call has stopped: the
\* erasure probe (Term erasure probe) — committed where R reads purged under the intent's now, the outcome
\* carrying R erased; not-committed where R does not and no gate record names it; otherwise escalated.
Probe(c) == WOn /\ int[c] = "open" /\ ph[c] \in {"dead", "done"} /\ holder = "none"

SweepCommitted(c) ==
    /\ Probe(c) /\ (retR = c \/ (ProbeErased /\ gateR))
    /\ int' = [int EXCEPT ![c] = "executed"]
    /\ exR' = [exR EXCEPT ![c] = "erased"]
    /\ probed' = [probed EXCEPT ![c] = TRUE]
    /\ UNCHANGED <<ph, plan, rset, r, cs, issued, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

SweepNotCommitted(c) ==
    /\ Probe(c) /\ retR # c /\ ~gateR
    /\ int' = [int EXCEPT ![c] = "escalated"]
    /\ probed' = [probed EXCEPT ![c] = TRUE]
    /\ UNCHANGED <<ph, plan, rset, r, cs, issued, exR, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

\* R does not read purged under the intent's now and a gate record names it: none of the page's four answers
\* names this state (gap); the sweep escalates it, as it escalates an undecidable act.
SweepUndecidable(c) ==
    /\ Probe(c) /\ retR # c /\ gateR
    /\ int' = [int EXCEPT ![c] = "escalated"]
    /\ probed' = [probed EXCEPT ![c] = TRUE]
    /\ gap' = TRUE
    /\ UNCHANGED <<ph, plan, rset, r, cs, issued, exR, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late>>

\* The operator's resolve of an escalated act, once no purge of it is in flight.
OpReady(c) == OpOn /\ int[c] = "escalated" /\ cs[c] = "none" /\ holder = "none"

OpExecuted(c) ==
    /\ OpReady(c) /\ (retR = c \/ issued[c])
    /\ int' = [int EXCEPT ![c] = "executed"]
    /\ exR' = [exR EXCEPT ![c] = IF retR = c THEN "erased" ELSE "none"]
    /\ UNCHANGED <<ph, plan, rset, r, cs, issued, probed, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

OpAbandoned(c) ==
    /\ OpReady(c) /\ retR # c /\ ~issued[c]
    /\ int' = [int EXCEPT ![c] = "abandoned"]
    /\ UNCHANGED <<ph, plan, rset, r, cs, issued, exR, probed, holder, retR, goneR, gateR, destBy,
                   disc, seals, sealedR, sealAct, badCover, rec, sealBy, late, gap>>

Next ==
    \/ \E c \in Calls : Read(c)
    \/ \E c \in Calls : OpenInFlight(c)
    \/ \E c \in Calls : OpenLanded(c)
    \/ \E c \in Calls : Open(c)
    \/ \E c \in Calls : GuardRefuse(c)
    \/ \E c \in Calls : GuardPass(c)
    \/ \E c \in Calls : AnsOk(c)
    \/ \E c \in Calls : AnsHeld(c)
    \/ \E c \in Calls, g \in BOOLEAN : AnsStor(c, g)
    \/ \E c \in Calls, g \in BOOLEAN : AnsStorAgain(c, g)
    \/ \E c \in Calls : AnsNone(c)
    \/ \E c \in Calls : LateLand(c)
    \/ \E c \in Calls : NeverLand(c)
    \/ \E c \in Calls : RefuseAfter(c)
    \/ \E c \in Calls : Close(c)
    \/ \E c \in Calls : CloseFail(c)
    \/ \E c \in Calls : Stop(c)
    \/ \E c \in Calls : BindTx(c)
    \/ \E c \in Calls : BindAnswer(c)
    \/ \E c \in Calls : Reissue(c)
    \/ \E c \in Calls : BindFail(c)
    \/ \E c \in Calls : SplitDisc(c)
    \/ \E c \in Calls : SplitSeal(c)
    \/ \E c \in Calls : FirstSeal(c)
    \/ \E c \in Calls : FirstDisc(c)
    \/ \E c \in Calls : SweepCommitted(c)
    \/ \E c \in Calls : SweepNotCommitted(c)
    \/ \E c \in Calls : SweepUndecidable(c)
    \/ \E c \in Calls : OpExecuted(c)
    \/ \E c \in Calls : OpAbandoned(c)

Spec == Init /\ [][Next]_vars

Inv_OneSeal == seals <= 1

Inv_NoOrphanEvent == (seals > 0) => (disc > 0)

Inv_OneDisclosure == disc <= 1

Inv_NoOrphanDisclosure == (disc > 0) => (seals > 0)

Inv_Accounted == (destBy # "none") => (int[destBy] \notin {"refused", "abandoned"})

Inv_Evidence ==
    /\ (sealedR = "erased") => (retR # "retained")
    /\ \A c \in Calls : (exR[c] = "erased") => (retR = c)

Inv_Truth == ~(sealedR = "retained" /\ destBy # "none" /\ destBy = sealAct)

Inv_Cover == ~badCover

Probe_NeverRecover == ~(seals = 1 /\ rec /\ \E c \in Calls : probed[c] /\ int[c] = "executed" /\ sealAct = c)
Probe_NeverLate == ~(seals = 1 /\ late /\ sealedR = "erased")
Probe_NeverGap == ~gap
Probe_NeverAgain == ~(\E c \in Calls : int[c] = "refused" /\ sealAct # "none" /\ sealAct # c)
====
