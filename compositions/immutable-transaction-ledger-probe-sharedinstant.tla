---- MODULE immutable-transaction-ledger-probe-sharedinstant ----
\* EXPECT: violation — reachability probe: no two records in the store share a disclosure instant.
\* Grace Commons — Immutable Transaction Ledger with Selective Disclosure, the binding.
\* Spec-level formal sibling of compositions/immutable-transaction-ledger.md. Derived
\* validator; the English spec is the single source of truth. On any disagreement,
\* diagnose per the entry *The conflict protocol* in pressure-testing.md. The binding
\* index and the horizon arithmetic are immutable-transaction-ledger-rebuild.tla; the
\* reading of two stores for a record no intent carries is
\* immutable-transaction-ledger-reconcile.tla.
\*
\* TWO [Disclose Subset] invocations over two act keys that share a subject reference and
\* a recipient and differ in scope (Term act key), so the store read the disclosure probe
\* issues by subject, recipient and instant answers both keys' records and only the
\* probe's own filter keeps them apart. Each invocation takes one seam reading, its now,
\* which its intent carries and its accounting write passes as the disclosure instant
\* (Capability requirement 23 through 25, Action wiring 3 and 6). A record's disclosure
\* id is written here as the invocation whose commit wrote it.
\*
\* ONE TRANSACTION PER INVOCATION (Execution Contract Database 1, Capability requirement 36;
\* re-derived 2026-10-21). The intent, the accounting record and the outcome are store
\* writes of one composition action, so an invocation is one step here, and a reader sees
\* all of its writes or none. What the step commits is what the page answers:
\*   landed       the intent, the record and the outcome (Action wiring 20, 53);
\*   refused      the intent and the refusal record, where Selective Disclosure refuses
\*                the record (Action wiring 48, 49), the refused attempt kept as evidence;
\*   close fails  the intent and the record, where the substrate refuses the outcome
\*                (Action wiring 54; Recoverable Invocation close step 3.3): the outcome
\*                is owed, and the caller holds recording-failure carrying outcome;
\*   refusal fails  the intent alone, where Selective Disclosure refuses the record and
\*                the substrate refuses the refusal record (Action wiring 50);
\*   yields       the intent, with the record or without it, where Selective Disclosure
\*                answers a code it does not declare (Action wiring 51, 52).
\* A step that commits nothing (a refused open, a storage failure, a crash) changes
\* nothing and is not a step. With StoreOneTxn = FALSE an invocation may also end with
\* its accounting write in flight, applying at any later step: the split Database 1 forbids,
\* and the model of 2026-10-19 (-buggy-split).
\*
\* THE CONSTITUENTS, as contracts. Nothing of their protocols is re-modelled.
\*   Selective Disclosure — record answers a disclosure id for a record it persisted; a
\*     refusal leaves the store as the call found it (Operation 16, 17).
\*   Recoverable Invocation — proved in recoverable-invocation.tla and assumed here: the
\*     intent is written before the commit (its Invariant 1); exactly one closing stands
\*     for an invocation, written by the invocation while it lives and by the sweep or an
\*     operator only after it has yielded or its own closing was refused (Invariant 2);
\*     the sweep's closing follows the adopter's probe — committed, a recovered outcome
\*     carrying only what the probe re-derived (Invariant 5.3), or an escalation where the
\*     substrate refuses that outcome too; not-committed, an escalation, the kind having
\*     no commit fence (commit 14); undecidable, an escalation (Invariant 3.5);
\*     unavailable, nothing written, which is a stutter step here; an operator's [Resolve]
\*     supersedes an escalation with an outcome or an abandonment, and an abandonment with
\*     an outcome (resolve 15, 16), on the operator's own run of the probe.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv1_3          no two outcome events carry one disclosure id (Invariant 1.3, Check
\*                   1.5). With one closing per invocation by construction, at every
\*                   state, not only at quiescence.
\*   Inv1_Bijection  every outcome event carries the record its own intent's invocation
\*                   committed: the outcome names its intent (Term outcome event), and the
\*                   intent is where the disclosed set is read (Composition state 16), so
\*                   an outcome carrying another invocation's record would prove another
\*                   disclosure's set (Invariant 1's one-to-one binding).
\*   Inv1_4          every outcome event carries a disclosure id the accounting store
\*                   carries (Invariant 1.4, Check 1.4).
\*   Inv4_1          no disclosure answers success before its accounting record and its
\*                   outcome event have landed (Invariant 4.1), read off the stores at the
\*                   answer.
\*   CR34            no caller discloses the entries before an outcome event carrying the
\*                   disclosure id has landed over a record that has landed (Capability
\*                   requirement 34; Invariant 4's closure of Selective Disclosure
\*                   Invariant 5), read off the stores at the disclosure.
\*   Inv_NoFalseClosing  no invocation stands closed by an abandonment over a record the
\*                   store carries: an operator abandons only where the probe shows no
\*                   record (Term settling closing), and under Database 1 no record lands
\*                   after its invocation's step. The case of open line 2026-10-19-e, a
\*                   write still in flight applying after the abandonment, is the
\*                   -buggy-split twin, rejected.
\*
\* WHAT CARRIES THEM  Inv1_3 and Inv1_Bijection rest on three things this page binds and
\* nothing of the protocol's: the host never gives two invocations of one act key one now
\* (Capability requirement 28), the probe keeps only the records carrying the act key's
\* scope and authority (Term disclosure probe; Recoverable Invocation probe 8), and the
\* probe reads the intent's disclosure instant as a range of that one instant (Term
\* disclosure probe; Recoverable Invocation pairing datum 2, Invariant 3.4). Each dropped
\* alone is a twin the checker rejects: an invocation whose intent committed with no record
\* of its own is recovered onto another invocation's record. Inv1_4 rests on the
\* accounting store never losing a record (Retention asymmetry 1, Selective Disclosure
\* Invariant 6.1). Inv4_1 rests on Action wiring 20 answering a landed disclosure, and
\* CR34 on the caller who holds recording-failure carrying outcome waiting for the outcome
\* by invocation id. Inv_NoFalseClosing rests on Database 1 (-buggy-split).
\*
\* THE PROBE'S FOUR ANSWERS  committed and not-committed are each reached here
\* (Probe_NeverRecovered and Probe_NeverSettled are rejected; an operator settles an
\* escalation the substrate's refusal of a recovered outcome wrote). Undecidable is never
\* reached at the main constants: under Capability requirement 28 and Composes 11 no two
\* records carry one act key and one instant, so Probe_NeverUndecidable holds; with
\* EqualNowBarred = FALSE it is reached, and the escalation it writes keeps the case where
\* both invocations committed safe, while the case where the second committed no record
\* of its own is the twin's violation. Unavailable writes nothing and is a stutter step.
\*
\* NOT MODELED
\*   - Time, and with it the critical section, its lease, the sweep's edges and the call
\*     pause bound: Recoverable Invocation's, proved in its model. Two invocations of one
\*     act key may be open at once here, which the section forbids; the section only
\*     removes behaviours.
\*   - Purges, the binding index and the reconciliation: the -rebuild and -reconcile
\*     models. Every outcome here is live.
\*   - Writes outside the composition (Composes 10, 11 hold here); the -reconcile model
\*     carries one.
\*   - Validation, membership, credentials, the bundle and [Record Entry]: refusals that
\*     write nothing, or writes no invariant here reads.
\*
\* THE BUDGET  N invocations, two in the main configuration, and as many instants: the
\* first opens with the first act key and the first instant, each later one after the one
\* before it with any key and instant the host may give it, which breaks the symmetry
\* between them and loses no behaviour up to renaming. MaxResolves operator resolutions,
\* two by default, so a resolution of each invocation, or an abandonment and the outcome
\* that supersedes it, fit. 1,475 states (the split model of 2026-10-19 took 3,956); at
\* N = 3 the run passes the harness's cap of 200,000 states, not raised for the
\* re-derivation.
\*
\* TWINS AND PROBES  Each is this module byte for byte below its header, with one
\* constant or one invariant changed in its .cfg: -buggy-equalnow, -buggy-probekey,
\* -buggy-probewindow, -buggy-bounded, -buggy-earlyanswer, -buggy-sendfirst,
\* -buggy-split; -probe-recovered, -probe-settled, -probe-sharedinstant,
\* -probe-recoveredsent.
EXTENDS Naturals, FiniteSets

\* EqualNowBarred     TRUE: the host gives no two invocations of one act key one now
\*                    (Capability requirement 28).
\* ProbeKeyFields     TRUE: the probe keeps only the records carrying the act key's scope
\*                    and authority (Term disclosure probe). FALSE: it keeps every record
\*                    the store read by subject, recipient and instant answers.
\* ProbeOneInstant    TRUE: the probe reads the disclosure instant as a range of that one
\*                    instant (Term disclosure probe). FALSE: as a wider range.
\* StoreNeverRemoves  TRUE: the accounting store's retention is unbounded (Retention
\*                    asymmetry 1). FALSE: a record may be removed.
\* AnswerAfterClose   TRUE: a landed disclosure answers the disclosure result (Action
\*                    wiring 20). FALSE: an accounted disclosure answers it.
\* SendAfterOutcome   TRUE: a caller holding recording-failure carrying outcome discloses
\*                    only once an outcome event carrying the disclosure id has landed
\*                    (Capability requirement 34). FALSE: on the code.
\* StoreOneTxn        TRUE: an invocation's writes commit in its one step (Execution
\*                    Contract Database 1). FALSE: its accounting write may also be in flight
\*                    at the step and apply at any later one.
\* N                  invocations. MaxResolves: operator resolutions in all.
CONSTANTS EqualNowBarred, ProbeKeyFields, ProbeOneInstant, StoreNeverRemoves,
          AnswerAfterClose, SendAfterOutcome, StoreOneTxn, N, MaxResolves

Inv == 1..N          \* the invocations; a record's disclosure id is its invocation
Keys == {1, 2}       \* act keys: one subject and one recipient, two scopes
Instants == 1..N     \* nows the host may inject
\* What an invocation's step committed:
\*   idle  not yet run                   land   the intent, the record and the outcome
\*   refd  the intent and the refusal record   cfail  the intent and the record
\*   rfail the intent alone, its refusal record refused
\*   yield the intent, the commit having answered a code the atom does not declare
Phases == {"idle", "land", "refd", "cfail", "rfail", "yield"}
\* A closing: none, an outcome event, a refusal, an escalation or an abandonment.
Closings == {"none", "out", "refused", "esc", "aband"}

VARIABLES
    key,     \* key[i]: the act key invocation i's intent carries; 0 before its step
    nw,      \* nw[i]: its now, the disclosure instant its intent carries; 0 before
    ph,      \* ph[i]: what its step committed
    pend,    \* pend[i]: its accounting write is in flight past its step (only where
             \* StoreOneTxn fails)
    rec,     \* rec[i]: its record has landed in the accounting store
    gone,    \* gone[i]: its record has been removed (only where StoreNeverRemoves fails)
    cl,      \* cl[i]: the closing standing for its intent
    oid,     \* oid[i]: the disclosure id the standing outcome event carries; 0 for none
    ow,      \* ow[i]: who wrote that outcome — "inv", "sweep" or "op"; "-" for none
    ansSt,   \* ansSt[i]: the call answered success — "no", or "ok"/"bad" by what the
             \* stores held at the answer
    sentSt,  \* sentSt[i]: the caller disclosed the entries — "no", or "ok"/"bad" by
             \* what the stores held at the disclosure
    res,     \* operator resolutions written
    undec    \* the sweep has answered undecidable (read only by Probe_NeverUndecidable)
vars == <<key, nw, ph, pend, rec, gone, cl, oid, ow, ansSt, sentSt, res, undec>>

TypeOK ==
    /\ key \in [Inv -> Keys \cup {0}]
    /\ nw \in [Inv -> Instants \cup {0}]
    /\ ph \in [Inv -> Phases]
    /\ pend \in [Inv -> BOOLEAN]
    /\ rec \in [Inv -> BOOLEAN]
    /\ gone \in [Inv -> BOOLEAN]
    /\ cl \in [Inv -> Closings]
    /\ oid \in [Inv -> Inv \cup {0}]
    /\ ow \in [Inv -> {"-", "inv", "sweep", "op"}]
    /\ ansSt \in [Inv -> {"no", "ok", "bad"}]
    /\ sentSt \in [Inv -> {"no", "ok", "bad"}]
    /\ res \in 0..MaxResolves
    /\ undec \in BOOLEAN

Init ==
    /\ key = [i \in Inv |-> 0]
    /\ nw = [i \in Inv |-> 0]
    /\ ph = [i \in Inv |-> "idle"]
    /\ pend = [i \in Inv |-> FALSE]
    /\ rec = [i \in Inv |-> FALSE]
    /\ gone = [i \in Inv |-> FALSE]
    /\ cl = [i \in Inv |-> "none"]
    /\ oid = [i \in Inv |-> 0]
    /\ ow = [i \in Inv |-> "-"]
    /\ ansSt = [i \in Inv |-> "no"]
    /\ sentSt = [i \in Inv |-> "no"]
    /\ res = 0
    /\ undec = FALSE

\* --- the stores, read ---
\* The record r is in the accounting store.
InStore(r) == rec[r] /\ ~gone[r]
\* Some outcome event carries the disclosure id r.
OutNames(r) == \E j \in Inv : cl[j] = "out" /\ oid[j] = r
\* The disclosure probe for invocation i's intent (Term disclosure probe): the store read
\* by the act key's subject and recipient — every key here shares both — and by the
\* intent's disclosure instant as a range of that one instant, kept in the composition's
\* own code to the records carrying the act key's scope and authority.
Matches(i) ==
    {r \in Inv : /\ InStore(r)
                 /\ (ProbeOneInstant => (nw[r] = nw[i]))
                 /\ (ProbeKeyFields => (key[r] = key[i]))}
\* The sweep may close an intent whose invocation yielded, or whose own close or refusal
\* the substrate refused; an invocation's step leaves no intent in flight.
Sweepable(i) == ph[i] \in {"yield", "cfail", "rfail"}

\* --- [Disclose Subset]: validate, open, commit, close, as one transaction ---

\* The step opens with the act key and the seam's now (Action wiring 3; Capability
\* requirement 23). The host gives no two invocations of one act key one now where
\* EqualNowBarred holds (Capability requirement 28).
CanRun(i, k, n) ==
    /\ ph[i] = "idle"
    /\ (i > 1) => (ph[i - 1] # "idle")
    /\ (i = 1) => (k = 1 /\ n = 1)
    /\ EqualNowBarred => (\A j \in Inv \ {i} : ~(key[j] = k /\ nw[j] = n))

\* Landed: the intent, the accounting record and the outcome event carrying its
\* disclosure id commit together (Action wiring 6, 53; Term outcome data).
DiscloseLanded(i, k, n) ==
    /\ CanRun(i, k, n)
    /\ key' = [key EXCEPT ![i] = k]
    /\ nw' = [nw EXCEPT ![i] = n]
    /\ ph' = [ph EXCEPT ![i] = "land"]
    /\ rec' = [rec EXCEPT ![i] = TRUE]
    /\ cl' = [cl EXCEPT ![i] = "out"]
    /\ oid' = [oid EXCEPT ![i] = i]
    /\ ow' = [ow EXCEPT ![i] = "inv"]
    /\ UNCHANGED <<pend, gone, ansSt, sentSt, res, undec>>

\* Refused: Selective Disclosure refuses the record, which leaves the store as the call
\* found it (Operation 16, 17), and the refusal record commits with the intent (Action
\* wiring 48, 49).
DiscloseRefused(i, k, n) ==
    /\ CanRun(i, k, n)
    /\ key' = [key EXCEPT ![i] = k]
    /\ nw' = [nw EXCEPT ![i] = n]
    /\ ph' = [ph EXCEPT ![i] = "refd"]
    /\ cl' = [cl EXCEPT ![i] = "refused"]
    /\ UNCHANGED <<pend, rec, gone, oid, ow, ansSt, sentSt, res, undec>>

\* Close fails: the record commits with the intent and the substrate refuses the outcome;
\* the intent is the sweep's (Action wiring 54).
DiscloseCloseFails(i, k, n) ==
    /\ CanRun(i, k, n)
    /\ key' = [key EXCEPT ![i] = k]
    /\ nw' = [nw EXCEPT ![i] = n]
    /\ ph' = [ph EXCEPT ![i] = "cfail"]
    /\ rec' = [rec EXCEPT ![i] = TRUE]
    /\ UNCHANGED <<pend, gone, cl, oid, ow, ansSt, sentSt, res, undec>>

\* Refusal fails: Selective Disclosure refuses the record and the substrate refuses the
\* refusal record; the intent commits alone and is the sweep's (Action wiring 50).
DiscloseRefusalFails(i, k, n) ==
    /\ CanRun(i, k, n)
    /\ key' = [key EXCEPT ![i] = k]
    /\ nw' = [nw EXCEPT ![i] = n]
    /\ ph' = [ph EXCEPT ![i] = "rfail"]
    /\ UNCHANGED <<pend, rec, gone, cl, oid, ow, ansSt, sentSt, res, undec>>

\* Yields: Selective Disclosure answers a code it does not declare, the invocation yields
\* (Action wiring 51), and the step commits the intent with whatever the write applied;
\* the caller holds recording-failure carrying outcome and the invocation id (Action
\* wiring 52, 68).
DiscloseYields(i, k, n, applied) ==
    /\ CanRun(i, k, n)
    /\ key' = [key EXCEPT ![i] = k]
    /\ nw' = [nw EXCEPT ![i] = n]
    /\ ph' = [ph EXCEPT ![i] = "yield"]
    /\ rec' = [rec EXCEPT ![i] = applied]
    /\ UNCHANGED <<pend, gone, cl, oid, ow, ansSt, sentSt, res, undec>>

\* Only where StoreOneTxn fails: the invocation yields with its accounting write in
\* flight, and the write may apply at any later step, before or after any closing.
DiscloseInFlight(i, k, n) ==
    /\ ~StoreOneTxn
    /\ CanRun(i, k, n)
    /\ key' = [key EXCEPT ![i] = k]
    /\ nw' = [nw EXCEPT ![i] = n]
    /\ ph' = [ph EXCEPT ![i] = "yield"]
    /\ pend' = [pend EXCEPT ![i] = TRUE]
    /\ UNCHANGED <<rec, gone, cl, oid, ow, ansSt, sentSt, res, undec>>

\* A write in flight applies (reachable only where StoreOneTxn fails).
Land(i) ==
    /\ pend[i]
    /\ ~rec[i]
    /\ rec' = [rec EXCEPT ![i] = TRUE]
    /\ pend' = [pend EXCEPT ![i] = FALSE]
    /\ UNCHANGED <<key, nw, ph, gone, cl, oid, ow, ansSt, sentSt, res, undec>>

\* --- the sweep and the operator, by the probe's answer ---

\* committed: exactly one record matches; the recovered outcome carries that record's own
\* fields and disclosure id (Recoverable Invocation reconcile step 3.2, Invariant 5.3).
SweepRecover(i, r) ==
    /\ cl[i] = "none"
    /\ Sweepable(i)
    /\ Matches(i) = {r}
    /\ cl' = [cl EXCEPT ![i] = "out"]
    /\ oid' = [oid EXCEPT ![i] = r]
    /\ ow' = [ow EXCEPT ![i] = "sweep"]
    /\ UNCHANGED <<key, nw, ph, pend, rec, gone, ansSt, sentSt, res, undec>>

\* committed, but the substrate refuses the recovered outcome too: the sweep escalates
\* (Term escalated closing; Term settling closing, outcome-unrecordable).
SweepRecoverRefused(i) ==
    /\ cl[i] = "none"
    /\ Sweepable(i)
    /\ Cardinality(Matches(i)) = 1
    /\ cl' = [cl EXCEPT ![i] = "esc"]
    /\ UNCHANGED <<key, nw, ph, pend, rec, gone, oid, ow, ansSt, sentSt, res, undec>>

\* not-committed: no record matches; with no commit fence the sweep escalates (Recoverable
\* Invocation commit 14b, reconcile step 3.5).
SweepNotCommitted(i) ==
    /\ cl[i] = "none"
    /\ Sweepable(i)
    /\ Matches(i) = {}
    /\ cl' = [cl EXCEPT ![i] = "esc"]
    /\ UNCHANGED <<key, nw, ph, pend, rec, gone, oid, ow, ansSt, sentSt, res, undec>>

\* undecidable: more than one record matches; the sweep escalates naming the candidates
\* and chooses none (Recoverable Invocation Invariant 3.5, reconcile step 3.8, 3.11).
SweepUndecidable(i) ==
    /\ cl[i] = "none"
    /\ Sweepable(i)
    /\ Cardinality(Matches(i)) > 1
    /\ cl' = [cl EXCEPT ![i] = "esc"]
    /\ undec' = TRUE
    /\ UNCHANGED <<key, nw, ph, pend, rec, gone, oid, ow, ansSt, sentSt, res>>

\* An operator settles an escalation, or corrects an abandonment, with an outcome where the
\* operator's own run of the probe finds exactly one record (Term settling closing;
\* Recoverable Invocation resolve 15, 16).
ResolveOutcome(i, r) ==
    /\ res < MaxResolves
    /\ cl[i] \in {"esc", "aband"}
    /\ Matches(i) = {r}
    /\ cl' = [cl EXCEPT ![i] = "out"]
    /\ oid' = [oid EXCEPT ![i] = r]
    /\ ow' = [ow EXCEPT ![i] = "op"]
    /\ res' = res + 1
    /\ UNCHANGED <<key, nw, ph, pend, rec, gone, ansSt, sentSt, undec>>

\* An operator settles an escalation with an abandonment where the operator's probe shows
\* no record.
ResolveAbandon(i) ==
    /\ res < MaxResolves
    /\ cl[i] = "esc"
    /\ Matches(i) = {}
    /\ cl' = [cl EXCEPT ![i] = "aband"]
    /\ res' = res + 1
    /\ UNCHANGED <<key, nw, ph, pend, rec, gone, oid, ow, ansSt, sentSt, undec>>

\* --- the caller ---

\* The call answers the disclosure result (Action wiring 20): a landed disclosure, or with
\* AnswerAfterClose FALSE an accounted one, its close refused included. What the stores
\* hold at the answer is kept.
Answer(i) ==
    /\ ansSt[i] = "no"
    /\ IF AnswerAfterClose THEN ph[i] = "land" ELSE ph[i] \in {"cfail", "land"}
    /\ ansSt' = [ansSt EXCEPT ![i] = IF rec[i] /\ OutNames(i) THEN "ok" ELSE "bad"]
    /\ UNCHANGED <<key, nw, ph, pend, rec, gone, cl, oid, ow, sentSt, res, undec>>

\* The caller discloses the entries to the recipient: on the answer, under its disclosure
\* id; or, holding recording-failure carrying outcome, once the outcome event its
\* invocation id finds has landed, under the disclosure id that outcome carries (Term
\* position, Capability requirement 34). What the stores hold at the disclosure is kept.
Send(i) ==
    /\ sentSt[i] = "no"
    /\ \/ ansSt[i] # "no"
       \/ /\ ph[i] \in {"yield", "cfail"}
          /\ SendAfterOutcome => (cl[i] = "out")
    /\ LET d == IF ansSt[i] # "no" THEN i ELSE IF cl[i] = "out" THEN oid[i] ELSE 0
       IN sentSt' = [sentSt EXCEPT ![i] = IF d # 0 /\ rec[d] /\ OutNames(d) THEN "ok" ELSE "bad"]
    /\ UNCHANGED <<key, nw, ph, pend, rec, gone, cl, oid, ow, ansSt, res, undec>>

\* A record leaves the accounting store, which Retention asymmetry 1 forbids.
Remove(i) ==
    /\ ~StoreNeverRemoves
    /\ InStore(i)
    /\ gone' = [gone EXCEPT ![i] = TRUE]
    /\ UNCHANGED <<key, nw, ph, pend, rec, cl, oid, ow, ansSt, sentSt, res, undec>>

Next ==
    \/ \E i \in Inv, k \in Keys, n \in Instants :
          \/ DiscloseLanded(i, k, n)
          \/ DiscloseRefused(i, k, n)
          \/ DiscloseCloseFails(i, k, n)
          \/ DiscloseRefusalFails(i, k, n)
          \/ \E a \in BOOLEAN : DiscloseYields(i, k, n, a)
          \/ DiscloseInFlight(i, k, n)
    \/ \E i \in Inv : Land(i)
    \/ \E i, r \in Inv : SweepRecover(i, r)
    \/ \E i \in Inv : SweepRecoverRefused(i)
    \/ \E i \in Inv : SweepNotCommitted(i)
    \/ \E i \in Inv : SweepUndecidable(i)
    \/ \E i, r \in Inv : ResolveOutcome(i, r)
    \/ \E i \in Inv : ResolveAbandon(i)
    \/ \E i \in Inv : Answer(i)
    \/ \E i \in Inv : Send(i)
    \/ \E i \in Inv : Remove(i)

Spec == Init /\ [][Next]_vars

\* --- invariants ---

\* @isolate-facets Inv1_3 Inv1_Bijection
\* Two outcome events carrying one disclosure id need one of them to carry a record its
\* own invocation did not commit, so no twin breaks Inv1_3 and holds Inv1_Bijection.
\* @isolate-facets Inv4_1 CR34
\* The answer is one of the two routes by which the entries reach the recipient ("the
\* call's answer says so"), so an answer ahead of the outcome is a disclosure ahead of it:
\* no twin breaks Inv4_1 and holds CR34. CR34's other route, the outcome found by
\* invocation id, has its own twin, -buggy-sendfirst.

\* Invariant 1.3: no disclosure id under two live outcome events. Every outcome is live.
Inv1_3 ==
    \A i, j \in Inv : (i # j /\ cl[i] = "out" /\ cl[j] = "out") => (oid[i] # oid[j])

\* Invariant 1's one-to-one binding, through the intent the outcome names.
Inv1_Bijection ==
    \A i \in Inv : (cl[i] = "out") => (oid[i] = i)

\* Invariant 1.4: every outcome event's disclosure id is in the accounting store.
Inv1_4 ==
    \A i \in Inv : (cl[i] = "out") => InStore(oid[i])

\* Invariant 4.1: no success answered ahead of both truth-bearing writes.
Inv4_1 ==
    \A i \in Inv : ansSt[i] # "bad"

\* Capability requirement 34: no disclosure to the recipient ahead of an outcome event
\* carrying the disclosure id, over a record that has landed.
CR34 ==
    \A i \in Inv : sentSt[i] # "bad"

\* No invocation stands closed by an abandonment over a record the store carries (the
\* false closing of open line 2026-10-19-e, dissolved by Database 1).
Inv_NoFalseClosing ==
    ~(\E i \in Inv : cl[i] = "aband" /\ InStore(i))

\* --- reachability probes: deliberate falsehoods the checker must reject ---

\* The sweep never recovers an outcome. Rejected: the committed answer is reached.
Probe_NeverRecovered ==
    \A i \in Inv : ow[i] # "sweep"

\* No operator ever writes an outcome. Rejected: an escalation the substrate's refusal of
\* a recovered outcome wrote is settled by an outcome.
Probe_NeverSettled ==
    \A i \in Inv : ow[i] # "op"

\* No two records in the store ever share a disclosure instant. Rejected: two act keys
\* share an instant, so the probe's scope and authority filter is what parts them.
Probe_NeverSharedInstant ==
    ~(\E i, j \in Inv : i # j /\ InStore(i) /\ InStore(j) /\ nw[i] = nw[j])

\* No caller holding recording-failure carrying outcome ever discloses. Rejected: the
\* caller finds the sweep's or the operator's outcome by its invocation id.
Probe_NeverRecoveredSent ==
    ~(\E i \in Inv : sentSt[i] = "ok" /\ ph[i] \in {"yield", "cfail"})

\* The probe never answers undecidable. HOLDS at the main constants (see the header);
\* rejected with EqualNowBarred = FALSE. Not a probe file.
Probe_NeverUndecidable ==
    ~undec

====
