---- MODULE immutable-transaction-ledger-reconcile-probe-collision ----
\* EXPECT: violation — reachability probe: no run ends silent over an outside record copying an intent's act key and instant.
\* Grace Commons — Immutable Transaction Ledger with Selective Disclosure, the reading of
\* two stores for a record no intent carries. Spec-level formal sibling of
\* compositions/immutable-transaction-ledger.md; the binding is
\* immutable-transaction-ledger.tla and the binding index
\* immutable-transaction-ledger-rebuild.tla. Derived validator; the English spec is the
\* single source of truth. On any disagreement, diagnose per the entry *The conflict
\* protocol* in pressure-testing.md.
\*
\* ONE [Disclose Subset] invocation X and at most one record written to the accounting
\* store outside the composition, O (a deployment's conformance failure, Composes 11),
\* carrying either another instant or X's own act key and instant. X takes its seam
\* reading, its disclosure instant, at any tick, and its transaction commits at any later
\* tick, so the reading may stand far behind the intent (Term young record: "a record whose
\* intent landed later than the edge allows"). The intent and the accounting record
\* commit together (Execution Contract Database 1, Capability requirement 36; re-derived
\* 2026-10-21): the record lands with the intent, or, where Selective Disclosure refused
\* it and the substrate refused the refusal record, the intent commits alone and no record
\* of X's ever lands. Its intent is closed, as Recoverable Invocation's contract has it,
\* within CW ticks of the intent (Invariant 4.2): by an outcome over the record, the
\* invocation's own or the sweep's where the substrate refused the invocation's; or by an
\* escalation, where the record is missing or the substrate refuses the sweep's outcome
\* too. An operator settles an escalation within the settling period S, by an outcome
\* over the record or an abandonment where there is none (Term settling closing). An
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
\* (Reconciliation 32). Every step lies within RB ticks of the start (Capability
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
\*
\* WHAT THE MODEL FOUND  On the page as it stood at dbe17f5, with the accounting write
\* free to apply at any tick after its intent, the aged edge was a run bound short, as the
\* open line 2026-10-09-m said: a record falsely closed — the sweep escalated, an operator
\* abandoned, and the write applied after both — read as no intent's once its intent was
\* purged, and a run opened a write-ownership finding against a record the composition
\* wrote. Measured then by controlled variation, only the edge less two allowances and the
\* run bound, strict, held where the purge's clock may stand an allowance from the
\* deadline's (PurgeSkew = A), and the page took that edge (Term aged record). Under
\* Execution Contract Database 1 no write applies after its intent's transaction, so no
\* record of the composition's is falsely closed, every one has an outcome before its
\* intent can be purged (an escalation is settled within S, Capability requirement 29 and
\* 31), and the aged edge carries none of Inv_R14: dropped term by term it holds — no run
\* bound 123,784 states, one allowance 123,784, the comparison not strict 106,457 — and the
\* three twins that dropped them are retired.
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
\* WHAT THE MODEL SHOWS BESIDE  Probe_NeverSilentCollision is rejected: an outside record
\* carrying X's act key and instant, while X stands closed by its own outcome, is read by
\* no rule of the reconciliation — X's intent carries it, so Reconciliation 14 opens no
\* finding, and X is closed by an outcome, so Reconciliation 33 does not alert — and
\* Check 1.2 has no class for it (Ledger 2026-10-19-d). Probe_NeverFalseClosing now holds
\* (97,512 states): X is never abandoned over a record of its own, which leaves
\* Reconciliation 33 an outside record beside a refused or abandoned intent, a case this
\* model does not place; it is no longer a probe file (Ledger 2026-10-19-e, closed as
\* dissolved).
\*
\* NOT MODELED
\*   - The sweep's probe pairing X onto O: an outcome names X's record here (the binding
\*     model has no write outside the composition).
\*   - The binding rebuild and the index: a record an outcome named is named, per the
\*     rebuild model. X's outcome event's own purge reads into no finding here.
\*   - A refusal over a record that exists: only a store that wrote while refusing leaves
\*     one (a constituent's nonconformance); an intent closed by a refusal has no record.
\*   - The closing records' own purge: an escalation or an abandonment is read through
\*     the intent here, and outlives it in the substrate.
\*   - An outside record's instant aging: O at another instant is always examined.
\*   - A cadence, two nodes, and a failed write to the finding surface (2026-10-09-j).
\*
\* THE BUDGET  One invocation and one outside write, at H = 7, the least horizon that
\* leaves the page's aged edge past the young one at these constants (at H = 6 no record of
\* X's is examined, and the model would hold vacuously). 97,512 states; at H = 8, 123,036,
\* every invariant holding. Time is capped ages, so there is no tick bound to raise.
\*
\* TWINS AND PROBES  Each is this module byte for byte below its header, with one
\* constant or one invariant changed in its .cfg: -buggy-ledgerfirst, -buggy-storeearly,
\* -buggy-emptyread, -buggy-settle; -probe-finding, -probe-inflight, -probe-lastlookup,
\* -probe-collision. Retired 2026-10-21 under Database 1, which they no longer break:
\* -buggy-agededge, -buggy-agedstrict, -buggy-agedallowance and -probe-falseclosing.
EXTENDS Naturals, FiniteSets

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
CONSTANTS WE, H, CW, RBri, S, A, RB, AgedRB, AgedA, AgedStrict, PurgeSkew, YoungEdge,
          LedgerFirst, StoreEarly, EmptyRead

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
    r32      \* a run has alerted an outcome whose disclosure id the store read lacked
vars == <<xPh, xDA, xIA, xIP, xRec, xCl, xEA, delta, oW, rPh, rStep, rAge, rEx, rS1, rEnI,
          rEnN, rS2, rS2ok, rFail, wo, r32>>

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

Init ==
    /\ xPh = "idle" /\ xDA = 0 /\ xIA = 0 /\ xIP = FALSE /\ xRec = FALSE
    /\ xCl = "none" /\ xEA = 0
    /\ delta \in -A..A
    /\ oW = "none"
    /\ rPh = "idle" /\ rStep = 0 /\ rAge = 0 /\ rEx = {} /\ rS1 = {} /\ rEnI = FALSE
    /\ rEnN = FALSE /\ rS2 = {} /\ rS2ok = FALSE /\ rFail = FALSE
    /\ wo = {} /\ r32 = FALSE

RunVars == <<rPh, rStep, rAge, rEx, rS1, rEnI, rEnN, rS2, rS2ok, rFail>>
XVars == <<xPh, xDA, xIA, xIP, xRec, xCl, xEA>>

\* --- the stores ---
InStore(r) == IF r = "X" THEN xRec ELSE oW # "none"

\* --- X, as Recoverable Invocation's contract has it ---

Seam ==
    /\ xPh = "idle"
    /\ xPh' = "seam"
    /\ xDA' = 0
    /\ UNCHANGED <<xEA, xIA, xIP, xRec, xCl, delta, oW, RunVars, wo, r32>>

\* X's transaction commits, at any tick after the seam's reading: the intent with the
\* accounting record, or, where Selective Disclosure refused the record and the substrate
\* the refusal record, the intent alone, after which no record of X's ever lands
\* (Execution Contract Database 1).
Intent ==
    /\ xPh = "seam"
    /\ xPh' = "intent"
    /\ xIA' = 0
    /\ \E withRecord \in BOOLEAN : xRec' = withRecord
    /\ UNCHANGED <<xEA, xDA, xIP, xCl, delta, oW, RunVars, wo, r32>>

\* An outcome closes the intent, or settles an escalation, over the record: the
\* invocation's own, the sweep's where the substrate refused the invocation's, or an
\* operator's.
Outcome ==
    /\ xPh = "intent"
    /\ xCl \in {"none", "esc", "aband"}
    /\ xRec
    /\ ~xIP
    /\ xCl' = "out"
    /\ UNCHANGED <<xEA, xPh, xDA, xIA, xIP, xRec, delta, oW, RunVars, wo, r32>>

\* The sweep escalates where its probe finds no record (no commit fence), or where the
\* substrate refuses the outcome it would write over the record (Term settling closing:
\* outcome-unrecordable).
Escalate ==
    /\ xPh = "intent"
    /\ xCl = "none"
    /\ xCl' = "esc"
    /\ xEA' = 0
    /\ UNCHANGED <<xPh, xDA, xIA, xIP, xRec, delta, oW, RunVars, wo, r32>>

\* An operator settles an escalation with an abandonment where the operator's probe shows
\* no record; under Database 1 none lands after it.
Abandon ==
    /\ xPh = "intent"
    /\ xCl = "esc"
    /\ ~xRec
    /\ ~xIP
    /\ xCl' = "aband"
    /\ UNCHANGED <<xEA, xPh, xDA, xIA, xIP, xRec, delta, oW, RunVars, wo, r32>>

\* The substrate purges X's intent at its edge, PurgeSkew early at most.
PurgeIntent ==
    /\ xPh = "intent"
    /\ ~xIP
    /\ xIA >= H - PurgeSkew
    /\ xIP' = TRUE
    /\ UNCHANGED <<xEA, xPh, xDA, xIA, xRec, xCl, delta, oW, RunVars, wo, r32>>

\* A write to the accounting store outside the composition.
OutsideOther ==
    /\ oW = "none"
    /\ oW' = "other"
    /\ UNCHANGED <<XVars, delta, RunVars, wo, r32>>

OutsideColl ==
    /\ oW = "none"
    /\ xPh = "intent"
    /\ oW' = "coll"
    /\ UNCHANGED <<XVars, delta, RunVars, wo, r32>>

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
    /\ UNCHANGED <<XVars, delta, oW, rS1, rEnI, rEnN, rS2, rS2ok, rFail, wo, r32>>

\* The first store read: the records the start examined that the store carries. With
\* StoreEarly, the read outcomes are checked against is taken here as well, ahead of the
\* enumeration.
StoreRead1 ==
    /\ Next1("S1")
    /\ rStep' = rStep + 1
    /\ rS1' = {r \in rEx : InStore(r)}
    /\ rS2' = IF StoreEarly THEN {r \in Recs : InStore(r)} ELSE rS2
    /\ rS2ok' = IF StoreEarly THEN TRUE ELSE rS2ok
    /\ UNCHANGED <<XVars, delta, oW, rPh, rAge, rEx, rEnI, rEnN, rFail, wo, r32>>

StoreRead1Fails ==
    /\ Next1("S1")
    /\ rStep' = rStep + 1
    /\ rS1' = {}
    /\ rS2' = IF StoreEarly THEN {} ELSE rS2
    /\ rFail' = TRUE
    /\ UNCHANGED <<XVars, delta, oW, rPh, rAge, rEx, rEnI, rEnN, rS2ok, wo, r32>>

\* The ledger enumeration: X's intent, its closing and its outcome as the ledger shows
\* them now. A record an outcome named stays named by its binding past the outcome's
\* purge.
Enumerate ==
    /\ Next1("E")
    /\ rStep' = rStep + 1
    /\ rEnI' = (xPh = "intent" /\ ~xIP)
    /\ rEnN' = (xCl = "out")
    /\ UNCHANGED <<XVars, delta, oW, rPh, rAge, rEx, rS1, rS2, rS2ok, rFail, wo, r32>>

EnumerateFails ==
    /\ Next1("E")
    /\ rStep' = rStep + 1
    /\ rEnI' = FALSE
    /\ rEnN' = FALSE
    /\ rFail' = TRUE
    /\ UNCHANGED <<XVars, delta, oW, rPh, rAge, rEx, rS1, rS2, rS2ok, wo, r32>>

\* The second store read, after the enumeration (Reconciliation 7).
StoreRead2 ==
    /\ Next1("S2")
    /\ rStep' = rStep + 1
    /\ rS2' = IF StoreEarly THEN rS2 ELSE {r \in Recs : InStore(r)}
    /\ rS2ok' = IF StoreEarly THEN rS2ok ELSE TRUE
    /\ UNCHANGED <<XVars, delta, oW, rPh, rAge, rEx, rS1, rEnI, rEnN, rFail, wo, r32>>

StoreRead2Fails ==
    /\ Next1("S2")
    /\ rStep' = rStep + 1
    /\ rS2' = IF StoreEarly THEN rS2 ELSE {}
    /\ rFail' = TRUE
    /\ UNCHANGED <<XVars, delta, oW, rPh, rAge, rEx, rS1, rEnI, rEnN, rS2ok, wo, r32>>

\* An examined record no outcome and no binding names (Term orphan record), and whether
\* an intent the enumeration showed carries its act key and instant.
Orphan(r) == r \in rS1 /\ ~(r = "X" /\ rEnN)
Carried(r) == rEnI /\ (r = "X" \/ oW = "coll")
\* Whether this run's findings stand: every read answered (Reconciliation 29), or, with
\* EmptyRead, a failed read read as empty.
Reports == ~rFail \/ EmptyRead

\* The run ends: Reconciliation 14 and 32 where the run reports.
RunEnd ==
    /\ rPh = "run"
    /\ rStep = 3
    /\ wo' = IF Reports THEN wo \cup {r \in Recs : Orphan(r) /\ ~Carried(r)} ELSE wo
    /\ r32' = IF rS2ok /\ rEnN /\ ~("X" \in rS2) THEN TRUE ELSE r32
    /\ rPh' = "idle"
    /\ rStep' = 0
    /\ rAge' = 0
    /\ rEx' = {} /\ rS1' = {} /\ rEnI' = FALSE /\ rEnN' = FALSE
    /\ rS2' = {} /\ rS2ok' = FALSE /\ rFail' = FALSE
    /\ UNCHANGED <<XVars, delta, oW>>

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
    /\ UNCHANGED <<xPh, xIP, xRec, xCl, delta, oW, rPh, rStep, rEx, rS1, rEnI, rEnN,
                   rS2, rS2ok, rFail, wo, r32>>

Next ==
    \/ Seam \/ Intent \/ Outcome \/ Escalate \/ Abandon
    \/ PurgeIntent \/ OutsideOther \/ OutsideColl
    \/ RunStart \/ StoreRead1 \/ StoreRead1Fails \/ Enumerate \/ EnumerateFails
    \/ StoreRead2 \/ StoreRead2Fails \/ RunEnd
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

\* --- reachability probes: deliberate falsehoods the checker must reject ---

\* No write-ownership finding is ever opened. Rejected: the outside record gets one.
Probe_NeverFinding ==
    wo = {}

\* No run ends reading a falsely closed record (Reconciliation 33's alert). HOLDS under
\* Database 1, X never abandoned over a record of its own (see the header). Not a probe file.
Probe_NeverFalseClosing ==
    ~(rPh = "run" /\ rStep = 3 /\ ~rFail /\ Orphan("X") /\ rEnI /\ xCl = "aband")

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
