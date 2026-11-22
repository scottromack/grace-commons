---- MODULE immutable-ledger-reconcile-buggy-emptyread ----
\* BUGGY TWIN: a read that gave no answer is read as empty and the run opens findings (Reconciliation 29 dropped).
\* Grace Commons — Immutable Ledger with Selective Disclosure, the reading of
\* two stores for a record no intent carries. Spec-level formal sibling of
\* compositions/immutable-ledger.md; the binding is
\* immutable-ledger.tla and the binding index
\* immutable-ledger-rebuild.tla. Derived validator; the English spec is the
\* single source of truth. On any disagreement, diagnose per the entry *The conflict
\* protocol* in pressure-testing.md.
\*
\* ONE [Disclose Subset] invocation X and at most one record written to the accounting
\* store outside the composition, O (a deployment's conformance failure, Composes 11),
\* carrying either another instant or X's own act key and instant. X takes its seam
\* reading, its disclosure instant, at any tick, and its intent commits at any later
\* tick, so the reading may stand far behind the intent (Term young record: "a record whose
\* intent landed later than the edge allows"). The intent commits at the open, ahead of
\* the accounting write (Execution Contract Database 3, Capability requirement 36; the
\* page's Cross-record consistency under partial failure; re-derived 2026-11-22, in place of
\* the one transaction of 2026-10-21): the record lands with the intent's step, or the
\* write is in flight past it (InFlight) and the record lands at any later tick, before or
\* after any closing, or no record of X's ever lands. Its intent is closed, as Recoverable
\* Invocation's contract has it,
\* within CW ticks of the intent (Invariant 4.2): by an outcome over the record, the
\* invocation's own or the sweep's where the substrate refused the invocation's; or by an
\* escalation, where the record is missing or the substrate refuses the sweep's outcome
\* too. An operator settles an escalation within the settling period S, by an outcome
\* over the record or an abandonment where the probe shows none (Term settling closing),
\* and the write in flight may land after the abandonment: a false closing. An
\* outcome names X's record (the binding model's Inv1_Bijection), and a record an outcome
\* named is named by a binding once that outcome is purged (the rebuild model's Inv1_6).
\*
\* THE RECONCILIATION  A run reads now once at its start, which decides each record's
\* young and aged edges (Reconciliation 4, Term aged record), then reads the accounting
\* store (Reconciliation 6), then the ledger enumeration (Reconciliation 34), then the
\* store again (Reconciliation 7), and ends: where every read answered, a write-ownership
\* finding for every examined orphan no intent carries (Reconciliation 14); where a read
\* gave no answer, none (Reconciliation 29, 30); and, where the read it is checked against
\* answered, an alert for every outcome whose disclosure id that read lacks
\* (Reconciliation 32); and, where every read answered and the enumeration read an
\* examined orphan's invocation closed by an abandonment, the resolve of Reconciliation 33:
\* through Recoverable Invocation's resolve under the recovery identity, an outcome
\* carrying the disclosure id and naming the false closing in supersedes (resolve 13, 16a),
\* the one audit event the reconciliation records (Reconciliation 27); the resolve answers
\* a refusal where the intent is purged (resolve 12), where a closing other than the one
\* read now stands (resolve 9), or once anywhere (section-unavailable, a recording
\* failure), and a refused resolve is alerted (Reconciliation 38). Every step lies within RB ticks of the start (Capability
\* requirement 32), time free to pass between them. Runs start whenever none is running:
\* extra runs are harmless to a soundness claim, so no cadence is imposed.
\*
\* TIME is each instant's age, capped. The clock offset allowance is A: X's seam and the
\* reconciliation's reading stand up to A apart (delta), and the intent's purge may come
\* PurgeSkew ticks early, where the clock that set its retention deadline and the clock
\* that judges its eligibility differ (Audit Trail: "Clock skew across nodes can cause
\* non-deterministic eligibility"; Retention Window Clock semantics 3). The main
\* configuration lets them stand the allowance apart (PurgeSkew = A).
\*
\* WHAT THIS MODEL CHECKS
\*   Inv_R14   no write-ownership finding names a record the composition wrote: every
\*             record of the composition's is an intent's (Term write-ownership finding:
\*             "an orphan record no intent carries"; Reconciliation 14, 29, 34; Term aged
\*             record). An outside record may be found or not; it is never the
\*             composition's.
\*   Inv_R32   no run alerts an outcome event whose disclosure id the accounting store
\*             carries (Reconciliation 7, 32; Execution Contract Database 2 and Database 3
\*             through Capability requirement 36); every outcome's record is in the store
\*             here, so no such alert is sound.
\*   Inv_CR29  no escalation stands unsettled once its intent's horizon edge has come
\*             (Capability requirement 29), for an operator who settles within the
\*             settling period, at a horizon Capability requirement 31 admits.
\*   Inv_R33   no run that read a false closing over an examined orphan, every read
\*             answered, ends with neither a resolve written nor a resolve refused
\*             (Reconciliation 33).
\*   Inv_R33_13  the reconciliation's resolving outcome never stands beside the false
\*             closing it resolved: it names it in supersedes (Reconciliation 33;
\*             Recoverable Invocation resolve 13, Which closing stands 2).
\*   Inv_R38   a resolve that answered a refusal is alerted (Reconciliation 38).
\*   Inv_R27   every audit event the reconciliation records is a resolving closing of
\*             Reconciliation 33 (Reconciliation 27).
\*
\* WHAT THE MODEL FOUND  On the page as it stood at dbe17f5, with the accounting write
\* free to apply at any tick after its intent (as Database 3 again has it), the aged edge
\* was a run bound short, as the
\* open line 2026-10-09-m said: a record falsely closed — the sweep escalated, an operator
\* abandoned, and the write applied after both — read as no intent's once its intent was
\* purged, and a run opened a write-ownership finding against a record the composition
\* wrote. Measured then by controlled variation, only the edge less two allowances and the
\* run bound, strict, held where the purge's clock may stand an allowance from the
\* deadline's (PurgeSkew = A), and the page took that edge (Term aged record). Under the
\* one transaction of 2026-10-21 the edge carried none of Inv_R14 and its three twins were
\* retired; under Database 3 (2026-11-22) the write in flight lands after its intent's
\* purge again, and each term dropped alone is rejected again (-buggy-agededge,
\* -buggy-agedstrict, -buggy-agedallowance, restored). The rulings of 2026-11-22 hold as
\* written.
\*
\* WHAT CARRIES THEM  Inv_R14: the store read before the enumeration, so every record the
\* run reads has its intent already visible, the intent committing with its record
\* (Reconciliation 34, -buggy-ledgerfirst: a reading two ticks stale, the run's ledger
\* read first, the intent and the record landing between); and no finding from a run a
\* read gave no answer (Reconciliation 29, -buggy-emptyread). Neither edge carries any of
\* it: with YoungEdge = FALSE the model still holds (113,945 states), as the page says
\* ("the edge decides no finding"), and so it does with each term of the aged edge
\* dropped. Inv_R32: the second store read after the enumeration (Reconciliation 7,
\* -buggy-storeearly: the record and its outcome land after the store read and before the
\* enumeration). Inv_CR29: Capability requirement 31, which leaves the settling period
\* between the latest escalation and the intent's horizon edge (-buggy-settle, S = 4). It
\* has a completion bound of slack: window end counts from the examine edge, the
\* escalation lands within the compensation window of the intent itself, so S = 3 holds
\* here (142,043 states) where Capability requirement 31 admits S = 2 (123,208 states,
\* holding; Recoverable Invocation's own open line 2026-10-18-a is about that term).
\*
\* Inv_R33: the resolve (-buggy-noresolve: an alert alone, the page before 2026-11-22).
\* Inv_R33_13: supersedes (-buggy-nosupersedes). Inv_R38: the alert on a refused resolve
\* (-buggy-silentrefusal). Inv_R27: the resolving closing the one audit event
\* (-buggy-auditwrite: the resolve written under an audit write of the reconciliation's own
\* as well).
\*
\* WHAT THE MODEL SHOWS BESIDE  Probe_NeverSilentCollision is rejected: an outside record
\* carrying X's act key and instant, while X stands closed by its own outcome, is read by
\* no rule of the reconciliation — X's intent carries it, so Reconciliation 14 opens no
\* finding, and X is closed by an outcome, so Reconciliation 33 does not alert — and
\* Check 1.2 has no class for it (Ledger 2026-10-19-d). Probe_NeverFalseClosing is
\* rejected again under Database 3 (-probe-falseclosing), and the resolve is reached both
\* ways (-probe-resolved, -probe-resolverefused).
\*
\* NOT MODELED
\*   - The sweep's probe pairing X onto O: an outcome names X's record here (the binding
\*     model has no write outside the composition).
\*   - The binding rebuild and the index: a record an outcome named is named, per the
\*     rebuild model. X's outcome event's own purge reads into no finding here.
\*   - A refusal over a record that exists: a refused write leaves no record of X's
\*     (Selective Disclosure Operation 16, 17), so Reconciliation 33's refusal arm is
\*     reached only through an outside record copying a refused intent (the Alloy model's
\*     ShowRefusalOverCopy); X is never refused here.
\*   - An operator's own correction of the false closing racing the reconciliation's
\*     resolve beyond the re-read: a closing other than the one read answers the resolve
\*     a refusal (resolve 9).
\*   - The closing records' own purge: an escalation or an abandonment is read through
\*     the intent here, and outlives it in the substrate.
\*   - An outside record's instant aging: O at another instant is always examined.
\*   - A cadence, two nodes, and a failed write to the finding surface (Reconciliation 35).
\*
\* THE BUDGET  One invocation and one outside write, at H = 7, the least horizon that
\* leaves the page's aged edge past the young one at these constants (at H = 6 no record of
\* X's is examined, and the model would hold vacuously); one resolve refusal budgeted
\* (MaxRefuse). Time is capped ages, so there is no tick bound to raise.
\*
\* TWINS AND PROBES  Each is this module byte for byte below its header, with one
\* constant or one invariant changed in its .cfg: -buggy-ledgerfirst, -buggy-storeearly,
\* -buggy-emptyread, -buggy-settle, -buggy-agededge, -buggy-agedstrict,
\* -buggy-agedallowance, -buggy-noresolve, -buggy-nosupersedes, -buggy-silentrefusal,
\* -buggy-auditwrite; -probe-finding, -probe-inflight, -probe-lastlookup,
\* -probe-collision, -probe-falseclosing, -probe-resolved, -probe-resolverefused.
EXTENDS Integers, FiniteSets

\* WE           the act kind's window end, in ticks: a record younger than it, read
\*              from its disclosure instant, is young (Term young record).
\* H            the audit horizon. CW: Recoverable Invocation's compensation window, from
\*              the intent. RBri: Recoverable Invocation's run bound (Term horizon edge).
\* S            the settling period: an operator settles an escalation within S ticks.
\* A            the clock offset allowance. RB: the reconciliation run bound.
\* AgedRB       TRUE: the aged edge subtracts the reconciliation run bound (the page).
\* AgedA        the allowances the aged edge subtracts (the page: 2).
\* AgedStrict   TRUE: a record is aged once now does not precede its edge, as Recoverable
\*              Invocation's horizon edge reads (the page). FALSE: once the edge PRECEDES
\*              now.
\* PurgeSkew    how many ticks before its horizon an intent's payload may be purged.
\* YoungEdge    TRUE: a young record is not examined (Reconciliation 4).
\* LedgerFirst  FALSE: the store is read before the enumeration (Reconciliation 34).
\* StoreEarly   FALSE: outcomes are read against a store read the enumeration precedes
\*              (Reconciliation 7). TRUE: against one taken before it.
\* EmptyRead    FALSE: a run a read gave no answer opens no finding (Reconciliation 29).
\*              TRUE: the failed read reads as empty.
\* InFlight     TRUE: X's accounting write may be in flight past its intent's step
\*              (Execution Contract Database 3, the page's reading).
\* Resolve33    TRUE: a false closing is resolved (Reconciliation 33). FALSE: alerted only.
\* SupFC        TRUE: the resolving outcome names the false closing in supersedes.
\* Alert38      TRUE: a refused resolve is alerted (Reconciliation 38).
\* OwnAudit     FALSE: the resolving closing is the reconciliation's one audit event
\*              (Reconciliation 27). TRUE: it records one of its own beside it.
\* MaxRefuse    resolves refused for want of the section or a recording failure.
CONSTANTS WE, H, CW, RBri, S, A, RB, AgedRB, AgedA, AgedStrict, PurgeSkew, YoungEdge,
          LedgerFirst, StoreEarly, EmptyRead, InFlight, Resolve33, SupFC, Alert38,
          OwnAudit, MaxRefuse

Recs == {"X", "O"}
Edge == H - AgedA * A - (IF AgedRB THEN RB ELSE 0)
\* An age past its cap changes no comparison: a disclosure instant an allowance and a
\* tick past the aged edge is aged for any offset, under either comparison, and one an
\* allowance past the young edge is young for none; an intent that old is purged.
CapD == IF Edge + A + 1 > WE + A THEN Edge + A + 1 ELSE WE + A
CapI == H

VARIABLES
    xPh,     \* X: "idle", "seam" (its now read), "intent" (its intent written)
    xDA,     \* ticks since X's seam reading, capped
    xIA,     \* ticks since X's intent, capped
    xIP,     \* X's intent's payload is purged
    xRec,    \* X's record has landed in the accounting store
    xCl,     \* X's standing closing: "none", "out", "esc", "aband"
    xEA,     \* ticks since X's escalation, capped at S
    delta,   \* the reconciliation's clock less X's seam's, within A
    oW,      \* the outside record: "none", "other" (another instant, past the young edge
             \* and short of the aged one), "coll" (X's act key and instant)
    rPh,     \* the run: "idle" or "run"
    rStep,   \* how many of the run's three reads it has taken
    rAge,    \* ticks since the run started
    rEx,     \* the records the start's now leaves neither young nor aged
    rS1,     \* what the first store read showed of rEx
    rEnI,    \* the enumeration showed X's intent
    rEnN,    \* the enumeration showed an outcome naming X's record
    rS2,     \* what the second store read showed
    rS2ok,   \* the store read outcomes are checked against answered
    rFail,   \* a read of this run gave no answer
    wo,      \* the records a write-ownership finding has been opened for
    r32,     \* a run has alerted an outcome whose disclosure id the store read lacked
    xPend,   \* X's accounting write is in flight
    rEnC,    \* the closing of X's the enumeration read
    xRO,     \* the reconciliation's resolving outcome for X has been written
    xNS,     \* an outcome naming X's record stands beside a closing it does not supersede
    refN,    \* resolves refused so far
    al38,    \* a refused resolve has been alerted
    audW,    \* audit events the reconciliation has recorded
    resW,    \* resolving closings the reconciliation has written
    fcLeft   \* a run ended over a false closing it read with no resolve written or refused
vars == <<xPh, xDA, xIA, xIP, xRec, xCl, xEA, delta, oW, rPh, rStep, rAge, rEx, rS1, rEnI,
          rEnN, rS2, rS2ok, rFail, wo, r32, xPend, rEnC, xRO, xNS, refN, al38, audW, resW,
          fcLeft>>

TypeOK ==
    /\ xPh \in {"idle", "seam", "intent"}
    /\ xDA \in 0..CapD /\ xIA \in 0..CapI
    /\ xIP \in BOOLEAN /\ xRec \in BOOLEAN
    /\ xCl \in {"none", "out", "esc", "aband"}
    /\ xEA \in 0..S
    /\ delta \in -A..A
    /\ oW \in {"none", "other", "coll"}
    /\ rPh \in {"idle", "run"}
    /\ rStep \in 0..3
    /\ rAge \in 0..RB
    /\ rEx \subseteq Recs /\ rS1 \subseteq Recs /\ rS2 \subseteq Recs
    /\ rEnI \in BOOLEAN /\ rEnN \in BOOLEAN
    /\ rS2ok \in BOOLEAN
    /\ rFail \in BOOLEAN
    /\ wo \subseteq Recs
    /\ r32 \in BOOLEAN
    /\ xPend \in BOOLEAN
    /\ rEnC \in {"none", "out", "esc", "aband"}
    /\ xRO \in BOOLEAN /\ xNS \in BOOLEAN
    /\ refN \in 0..(MaxRefuse + 1) /\ al38 \in BOOLEAN
    /\ audW \in 0..2 /\ resW \in 0..1
    /\ fcLeft \in BOOLEAN

Init ==
    /\ xPh = "idle" /\ xDA = 0 /\ xIA = 0 /\ xIP = FALSE /\ xRec = FALSE
    /\ xCl = "none" /\ xEA = 0
    /\ delta \in -A..A
    /\ oW = "none"
    /\ rPh = "idle" /\ rStep = 0 /\ rAge = 0 /\ rEx = {} /\ rS1 = {} /\ rEnI = FALSE
    /\ rEnN = FALSE /\ rS2 = {} /\ rS2ok = FALSE /\ rFail = FALSE
    /\ wo = {} /\ r32 = FALSE
    /\ xPend = FALSE /\ rEnC = "none" /\ xRO = FALSE /\ xNS = FALSE
    /\ refN = 0 /\ al38 = FALSE /\ audW = 0 /\ resW = 0 /\ fcLeft = FALSE

RunVars == <<rPh, rStep, rAge, rEx, rS1, rEnI, rEnN, rS2, rS2ok, rFail, rEnC>>
XVars == <<xPh, xDA, xIA, xIP, xRec, xCl, xEA, xPend, xRO, xNS>>
RecVars == <<refN, al38, audW, resW, fcLeft>>

\* --- the stores ---
InStore(r) == IF r = "X" THEN xRec ELSE oW # "none"

\* --- X, as Recoverable Invocation's contract has it ---

Seam ==
    /\ xPh = "idle"
    /\ xPh' = "seam"
    /\ xDA' = 0
    /\ UNCHANGED <<xEA, xIA, xIP, xRec, xCl, xPend, xRO, xNS, delta, oW, RunVars, wo, r32,
                   RecVars>>

\* X's intent commits, at any tick after the seam's reading, ahead of the accounting write
\* (Execution Contract Database 3): the record lands in the step, or the write is in
\* flight past it (InFlight), or no record of X's ever lands (a refused or failed write).
Intent ==
    /\ xPh = "seam"
    /\ xPh' = "intent"
    /\ xIA' = 0
    /\ \E w \in {"rec", "pend", "none"} :
          /\ (w = "pend") => InFlight
          /\ xRec' = (w = "rec")
          /\ xPend' = (w = "pend")
    /\ UNCHANGED <<xEA, xDA, xIP, xCl, xRO, xNS, delta, oW, RunVars, wo, r32, RecVars>>

\* X's write in flight applies, at any later tick, before or after any closing.
Land ==
    /\ xPend
    /\ xRec' = TRUE
    /\ xPend' = FALSE
    /\ UNCHANGED <<xPh, xDA, xIA, xIP, xCl, xEA, xRO, xNS, delta, oW, RunVars, wo, r32,
                   RecVars>>

\* An outcome closes the intent, or settles an escalation, over the record: the
\* invocation's own, the sweep's where the substrate refused the invocation's, or an
\* operator's.
Outcome ==
    /\ xPh = "intent"
    /\ xCl \in {"none", "esc", "aband"}
    /\ xRec
    /\ ~xIP
    /\ xCl' = "out"
    /\ UNCHANGED <<xEA, xPh, xDA, xIA, xIP, xRec, xPend, xRO, xNS, delta, oW, RunVars, wo,
                   r32, RecVars>>

\* The sweep escalates where its probe finds no record (no commit fence), or where the
\* substrate refuses the outcome it would write over the record (Term settling closing:
\* outcome-unrecordable).
Escalate ==
    /\ xPh = "intent"
    /\ xCl = "none"
    /\ xCl' = "esc"
    /\ xEA' = 0
    /\ UNCHANGED <<xPh, xDA, xIA, xIP, xRec, xPend, xRO, xNS, delta, oW, RunVars, wo, r32,
                   RecVars>>

\* An operator settles an escalation with an abandonment where the operator's probe shows
\* no record; under Database 1 none lands after it.
Abandon ==
    /\ xPh = "intent"
    /\ xCl = "esc"
    /\ ~xRec
    /\ ~xIP
    /\ xCl' = "aband"
    /\ UNCHANGED <<xEA, xPh, xDA, xIA, xIP, xRec, xPend, xRO, xNS, delta, oW, RunVars, wo,
                   r32, RecVars>>

\* The substrate purges X's intent at its edge, PurgeSkew early at most.
PurgeIntent ==
    /\ xPh = "intent"
    /\ ~xIP
    /\ xIA >= H - PurgeSkew
    /\ xIP' = TRUE
    /\ UNCHANGED <<xEA, xPh, xDA, xIA, xRec, xCl, xPend, xRO, xNS, delta, oW, RunVars, wo,
                   r32, RecVars>>

\* A write to the accounting store outside the composition.
OutsideOther ==
    /\ oW = "none"
    /\ oW' = "other"
    /\ UNCHANGED <<XVars, delta, RunVars, wo, r32, RecVars>>

OutsideColl ==
    /\ oW = "none"
    /\ xPh = "intent"
    /\ oW' = "coll"
    /\ UNCHANGED <<XVars, delta, RunVars, wo, r32, RecVars>>

\* --- the reconciliation ---

\* A record's age read from the run's now against its disclosure instant.
\* An outside record at another instant is always examined.
Age(r) == xDA + delta
HasInstant(r) == IF r = "X" \/ oW = "coll" THEN xPh # "idle" ELSE oW = "other"
Young(r) == Age(r) < WE
Aged(r) == IF AgedStrict THEN Edge <= Age(r) ELSE Edge < Age(r)
Examined(r) ==
    IF r = "O" /\ oW = "other" THEN TRUE
    ELSE HasInstant(r) /\ ~(YoungEdge /\ Young(r)) /\ ~Aged(r)

\* The run's three reads in their order: the first store read (S1), the enumeration (E),
\* the second store read (S2). Reconciliation 34 puts S1 first; LedgerFirst puts E first.
StepKind(k) ==
    IF LedgerFirst THEN (IF k = 1 THEN "E" ELSE IF k = 2 THEN "S1" ELSE "S2")
                   ELSE (IF k = 1 THEN "S1" ELSE IF k = 2 THEN "E" ELSE "S2")
Next1(kind) == rPh = "run" /\ rStep < 3 /\ StepKind(rStep + 1) = kind
EnumDone == rPh = "run" /\ rStep >= (IF LedgerFirst THEN 1 ELSE 2)

RunStart ==
    /\ rPh = "idle"
    /\ rPh' = "run"
    /\ rStep' = 0
    /\ rAge' = 0
    /\ rEx' = {r \in Recs : Examined(r)}
    /\ UNCHANGED <<XVars, delta, oW, rS1, rEnI, rEnN, rS2, rS2ok, rFail, rEnC, wo, r32,
                   RecVars>>

\* The first store read: the records the start examined that the store carries. With
\* StoreEarly, the read outcomes are checked against is taken here as well, ahead of the
\* enumeration.
StoreRead1 ==
    /\ Next1("S1")
    /\ rStep' = rStep + 1
    /\ rS1' = {r \in rEx : InStore(r)}
    /\ rS2' = IF StoreEarly THEN {r \in Recs : InStore(r)} ELSE rS2
    /\ rS2ok' = IF StoreEarly THEN TRUE ELSE rS2ok
    /\ UNCHANGED <<XVars, delta, oW, rPh, rAge, rEx, rEnI, rEnN, rFail, wo, r32, rEnC, RecVars>>

StoreRead1Fails ==
    /\ Next1("S1")
    /\ rStep' = rStep + 1
    /\ rS1' = {}
    /\ rS2' = IF StoreEarly THEN {} ELSE rS2
    /\ rFail' = TRUE
    /\ UNCHANGED <<XVars, delta, oW, rPh, rAge, rEx, rEnI, rEnN, rS2ok, wo, r32, rEnC, RecVars>>

\* The ledger enumeration: X's intent, its closing and its outcome as the ledger shows
\* them now. A record an outcome named stays named by its binding past the outcome's
\* purge.
Enumerate ==
    /\ Next1("E")
    /\ rStep' = rStep + 1
    /\ rEnI' = (xPh = "intent" /\ ~xIP)
    /\ rEnN' = (xCl = "out" \/ xNS)
    /\ rEnC' = IF xPh = "intent" /\ ~xIP THEN xCl ELSE "none"
    /\ UNCHANGED <<XVars, delta, oW, rPh, rAge, rEx, rS1, rS2, rS2ok, rFail, wo, r32,
                   RecVars>>

EnumerateFails ==
    /\ Next1("E")
    /\ rStep' = rStep + 1
    /\ rEnI' = FALSE
    /\ rEnN' = FALSE
    /\ rEnC' = "none"
    /\ rFail' = TRUE
    /\ UNCHANGED <<XVars, delta, oW, rPh, rAge, rEx, rS1, rS2, rS2ok, wo, r32, RecVars>>

\* The second store read, after the enumeration (Reconciliation 7).
StoreRead2 ==
    /\ Next1("S2")
    /\ rStep' = rStep + 1
    /\ rS2' = IF StoreEarly THEN rS2 ELSE {r \in Recs : InStore(r)}
    /\ rS2ok' = IF StoreEarly THEN rS2ok ELSE TRUE
    /\ UNCHANGED <<XVars, delta, oW, rPh, rAge, rEx, rS1, rEnI, rEnN, rFail, wo, r32, rEnC, RecVars>>

StoreRead2Fails ==
    /\ Next1("S2")
    /\ rStep' = rStep + 1
    /\ rS2' = IF StoreEarly THEN rS2 ELSE {}
    /\ rFail' = TRUE
    /\ UNCHANGED <<XVars, delta, oW, rPh, rAge, rEx, rS1, rEnI, rEnN, rS2ok, wo, r32, rEnC, RecVars>>

\* An examined record no outcome and no binding names (Term orphan record), and whether
\* an intent the enumeration showed carries its act key and instant.
Orphan(r) == r \in rS1 /\ ~(r = "X" /\ rEnN)
Carried(r) == rEnI /\ (r = "X" \/ oW = "coll")
\* Whether this run's findings stand: every read answered (Reconciliation 29), or, with
\* EmptyRead, a failed read read as empty.
Reports == ~rFail \/ EmptyRead

\* The run read a false closing over X's record: an examined orphan whose invocation the
\* enumeration read closed by an abandonment, every read answered (Term false closing).
FalseClosingRead == ~rFail /\ Orphan("X") /\ Carried("X") /\ rEnC = "aband"
\* The run's common end: Reconciliation 14 and 32 where the run reports.
EndCommon ==
    /\ rPh = "run"
    /\ rStep = 3
    /\ wo' = IF Reports THEN wo \cup {r \in Recs : Orphan(r) /\ ~Carried(r)} ELSE wo
    /\ r32' = IF rS2ok /\ rEnN /\ ~("X" \in rS2) THEN TRUE ELSE r32
    /\ rPh' = "idle"
    /\ rStep' = 0
    /\ rAge' = 0
    /\ rEx' = {} /\ rS1' = {} /\ rEnI' = FALSE /\ rEnN' = FALSE
    /\ rS2' = {} /\ rS2ok' = FALSE /\ rFail' = FALSE /\ rEnC' = "none"
    /\ UNCHANGED <<xPh, xDA, xIA, xIP, xRec, xEA, xPend, delta, oW>>

\* The run ends with no false closing to resolve, or, where Resolve33 fails, alerting one
\* only (the page before 2026-11-22), which leaves it standing.
RunEnd ==
    /\ EndCommon
    /\ ~(Resolve33 /\ FalseClosingRead)
    /\ fcLeft' = (fcLeft \/ FalseClosingRead)
    /\ UNCHANGED <<xCl, xRO, xNS, refN, al38, audW, resW>>

\* Reconciliation 33: the resolve writes an outcome carrying X's disclosure id over its
\* record under the recovery identity, naming the false closing in supersedes (with SupFC),
\* so the outcome stands and the abandonment no longer does; without supersedes the
\* abandonment still stands beside it (Which closing stands 2). The closing is the
\* reconciliation's one audit event (Reconciliation 27).
RunEndResolved ==
    /\ EndCommon
    /\ Resolve33 /\ FalseClosingRead
    /\ ~xIP /\ xCl = "aband"
    /\ xCl' = IF SupFC THEN "out" ELSE xCl
    /\ xNS' = ~SupFC
    /\ xRO' = TRUE
    /\ resW' = resW + 1
    /\ audW' = audW + (IF OwnAudit THEN 2 ELSE 1)
    /\ UNCHANGED <<refN, al38, fcLeft>>

\* The resolve answers a refusal: the intent purged (resolve 12), a closing other than the
\* one read standing (resolve 9), or the section or the write refused (MaxRefuse); it
\* writes nothing, and the run alerts it (Reconciliation 38).
RunEndRefused ==
    /\ EndCommon
    /\ Resolve33 /\ FalseClosingRead
    /\ (xIP \/ xCl # "aband" \/ refN < MaxRefuse)
    /\ refN' = refN + 1
    /\ al38' = (al38 \/ Alert38)
    /\ UNCHANGED <<xCl, xRO, xNS, audW, resW, fcLeft>>

\* --- time ---

\* A tick ages every instant. Time does not pass a bound: a run RB old has ended; an intent
\* CW old is closed (Recoverable Invocation Invariant 4.2); an escalation S old is settled
\* (Term settling period); an intent at its edge is purged.
Tick ==
    /\ ~(rPh # "idle" /\ rAge >= RB)
    /\ ~(xPh = "intent" /\ xCl = "none" /\ xIA >= CW)
    /\ ~(xCl = "esc" /\ xEA >= S)
    /\ ~(xPh = "intent" /\ ~xIP /\ xIA >= H - PurgeSkew)
    /\ rAge' = IF rPh # "idle" THEN rAge + 1 ELSE 0
    /\ xDA' = IF xPh # "idle" /\ xDA < CapD THEN xDA + 1 ELSE xDA
    /\ xIA' = IF xPh = "intent" /\ xIA < CapI THEN xIA + 1 ELSE xIA
    /\ xEA' = IF xCl = "esc" /\ xEA < S THEN xEA + 1 ELSE xEA
    /\ UNCHANGED <<xPh, xIP, xRec, xCl, xPend, xRO, xNS, delta, oW, rPh, rStep, rEx, rS1,
                   rEnI, rEnN, rS2, rS2ok, rFail, rEnC, wo, r32, RecVars>>

Next ==
    \/ Seam \/ Intent \/ Land \/ Outcome \/ Escalate \/ Abandon
    \/ PurgeIntent \/ OutsideOther \/ OutsideColl
    \/ RunStart \/ StoreRead1 \/ StoreRead1Fails \/ Enumerate \/ EnumerateFails
    \/ StoreRead2 \/ StoreRead2Fails \/ RunEnd \/ RunEndResolved \/ RunEndRefused
    \/ Tick

Spec == Init /\ [][Next]_vars

\* --- invariants ---

\* A write-ownership finding never names a record the composition wrote: X's record is
\* always X's intent's, its commit following its intent.
Inv_R14 ==
    "X" \notin wo

\* No alert of an outcome event whose disclosure id the store carries.
Inv_R32 ==
    ~r32

\* Capability requirement 29: no escalation stands unsettled once its intent's horizon edge
\* (Recoverable Invocation: recorded_at + retention period - allowance - run bound) has
\* come, for an operator who settles within the settling period, wherever the horizon
\* meets Capability requirement 31.
Inv_CR29 ==
    ~(xPh = "intent" /\ xCl = "esc" /\ xIA + A + RBri >= H)

\* Reconciliation 33: no run that read a false closing ends with it neither resolved nor
\* the resolve refused.
Inv_R33 ==
    ~fcLeft

\* Reconciliation 33 with Recoverable Invocation resolve 13: the reconciliation's resolving
\* outcome never stands beside the false closing it resolved.
Inv_R33_13 ==
    ~(xRO /\ xCl = "aband")

\* Reconciliation 38: a resolve that answered a refusal is alerted.
Inv_R38 ==
    (refN > 0) => al38

\* Reconciliation 27: every audit event the reconciliation records is a resolving closing.
Inv_R27 ==
    audW <= resW

\* --- reachability probes: deliberate falsehoods the checker must reject ---

\* No write-ownership finding is ever opened. Rejected: the outside record gets one.
Probe_NeverFinding ==
    wo = {}

\* No run ends reading a falsely closed record. Rejected under Database 3: the write in
\* flight lands after the operator's abandonment.
Probe_NeverFalseClosing ==
    ~(rPh = "run" /\ rStep = 3 /\ FalseClosingRead)

\* The reconciliation never writes a resolving outcome. Rejected: Reconciliation 33's
\* resolve is reached.
Probe_NeverResolved ==
    ~xRO

\* No resolve is ever refused. Rejected: Reconciliation 38's alert is reached.
Probe_NeverResolveRefused ==
    refN = 0

\* No run reads X's record against the ledger while X's intent has no closing, its
\* outcome owed where the substrate refused it. Rejected: the young edge does not keep such
\* records out; the read order keeps the finding away.
Probe_NeverInFlight ==
    ~(EnumDone /\ "X" \in rS1 /\ rEnI /\ xCl = "none")

\* No run's enumeration reads X's intent within one tick of its purge while X's record
\* is examined. Rejected: the aged edge is reached at its last instant.
Probe_NeverLastLookup ==
    ~(EnumDone /\ "X" \in rS1 /\ rEnI /\ xIA + 1 >= H - PurgeSkew)

\* No run ends silent over an outside record copying X's act key and instant while X
\* stands closed by an outcome. Rejected: Reconciliation 14 and 33 both pass it by.
Probe_NeverSilentCollision ==
    ~(rPh = "run" /\ rStep = 3 /\ ~rFail /\ oW = "coll" /\ Orphan("O") /\ Carried("O")
      /\ xCl = "out")

====
