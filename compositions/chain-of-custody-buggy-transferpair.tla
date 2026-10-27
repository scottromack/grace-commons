---- MODULE chain-of-custody-buggy-transferpair ----
\* Grace Commons — Chain of Custody: a custody action's intent, Provenance entry and Audit
\* Trail outcome event as one transaction, the orphan Audit Trail's refusal of the outcome
\* leaves, and the reconciliation that pairs each orphan to the unmatched intents realizing
\* it, then compensates it under the recovery identity behind a recovery intent or escalates
\* it. Spec-level formal sibling of compositions/chain-of-custody.md. Derived validator; the
\* English spec is the single source of truth. On any disagreement, diagnose per the entry
\* *The conflict protocol* in pressure-testing.md.
\*
\* ONE CHAIN, two invocations i1 and i2, and one Provenance write outside the composition's
\* surface, x. Each invocation is a custody action of one kind, transfer or genesis (an
\* origination), chosen at the start: the transfer stands for every leg Term realize pairs
\* alike (transfer, transformation, disclosure, archival), the genesis for the leg that pairs
\* only through the genesis lookup (Reconciliation 17, 18). Every invocation acts as
\* custodian c1 and names the same parameters, so two invocations of one kind realize each
\* other's entries. x is a transfer written outside the composition by the holder at the
\* time, c1 or c2, naming the same chain and incoming custodian, with no intent and no
\* outcome event. Whether the deployment supplies the genesis lookup is chosen at the start
\* (Capability requirement 22).
\*
\* ONE TRANSACTION PER ACTION (Execution Contract Database 1, 2). A custody action lands in one
\* step, as one of:
\*   CommitClean   the intent, the entry and the outcome event naming the intent.
\*   CommitOrphan  the intent and the entry, Audit Trail refusing the outcome event: the
\*                 action answers recording-failure carrying outcome, which surfaces the
\*                 orphan to its caller (Audit arm 19, 24; Invariant 4.1).
\*   CommitFault   the same, with the outcome refused invalid-request below step-4: the
\*                 invocation escalates the orphan as a deployment fault (Audit arm 26).
\*   Refuse        the intent alone, Provenance refusing the write: a refused attempt
\*                 (Action wiring 8, 9; Reconciliation 9).
\* A refusal at the intent and a storage failure commit nothing and are no step. The
\* in-invocation retry the 2026-10-20 rewrite removed is gone from the model with it.
\*
\* THE RECONCILIATION reads each orphan against the unmatched intents inside one transaction
\* with its writes (Database 2; Reconciliation 25, 26). With candidates within the intent
\* candidates cap and none aged, it lands the recovery intent and the compensating event under
\* the recovery identity, carrying the recovery flag and naming the candidates (Reconciliation
\* 10, 13, 21 to 24); with none it opens orphan-unpaired (11, 12); over the cap it escalates
\* (14, 15); with an aged candidate it writes nothing and escalates the overdue orphan (4, 28).
\* Two runs, r1 and r2, race only in -buggy-staleread, where a run writes what it read in an
\* earlier step: two runs land two outcome events for one entry, and a write lands for an
\* intent aged since the read. An intent ages by the audit horizon, and an aged intent's
\* orphan is overdue.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv7_AuthPrecedence  no entry of an invocation without its intent (Invariant 7.1;
\*                        Action wiring 1).
\*   Inv4_Surfaced        every orphan an invocation commits is surfaced in its answer or
\*                        escalated (Invariant 4.1; Audit arm 19, 24, 26).
\*   Inv4_OneOutcome      no entry carries two outcome events (Invariant 4.3).
\*   Inv4_NamesEntry      every outcome event names an entry the chain carries (Invariant
\*                        4.4).
\*   Inv1_Attributed      every outcome event names intents, each of the entry's kind and
\*                        authenticated by the entry's attested custodian (Invariant 1.4;
\*                        Check 1.3; Term realize).
\*   Inv_Cap              no outcome event names more intents than the intent candidates cap
\*                        (Reconciliation 14, 15).
\*   Inv_NoAgedWrite      no write is made for an aged intent (Reconciliation 4).
\*   Inv_GenesisLookup    no genesis entry is compensated where the deployment supplies no
\*                        genesis lookup (Reconciliation 17, 18; Term compensable orphan).
\*   Inv_Recovery         every compensating event stands under the recovery identity, behind
\*                        its recovery intent, carrying the recovery flag, and no other event
\*                        carries the flag (Reconciliation 21 to 23; Invariant 1.3; Check 1.4,
\*                        1.5).
\*
\* THE RULES, as constants, each TRUE here; each twin is this module with one turned FALSE:
\*   IntentFirst     no entry commits without its intent (Action wiring 1;
\*                   Invariant 7.1)                                    -buggy-unauthenticated
\*   Surface         an orphan an invocation commits is surfaced in its
\*                   answer (Audit arm 19, 24; Invariant 4.1)          -buggy
\*   RealizePairing  a transferred entry pairs by Term realize, like every
\*                   other leg (Reconciliation 10); FALSE pairs it by the
\*                   chain and the incoming custodian alone, the retired
\*                   Reconciliation 16, with no Reconciliation 19 behind it
\*                                                                     -buggy-transferpair
\*   ReadInTxn       the reconciliation's read and its writes are one
\*                   transaction (Database 2; Reconciliation 25, 26)   -buggy-staleread
\*   CapCheck        over the cap, escalate and never compensate
\*                   (Reconciliation 14, 15)                           -buggy-uncapped
\*   AgedEdge        no write for an aged intent (Reconciliation 4)    -buggy-aged
\*   GenesisGuard    a genesis intent pairs only through the genesis
\*                   lookup (Reconciliation 17, 18)                    -buggy-genesis
\*   Recovery        a compensating event carries the recovery flag
\*                   (Reconciliation 23)                               -buggy-unflagged
\*
\* THE PROBES, each this module with one deliberate falsehood added to its configuration:
\*   -probe-recovered  a compensating event lands.
\*   -probe-unpaired   an outside transfer by another custodian, beside an unmatched transfer
\*                     intent, lands orphan-unpaired: the case the retired principal
\*                     divergence caught.
\*   -probe-overcap    an orphan with more candidates than the cap is escalated.
\*   -probe-aged       an orphan with an aged candidate is escalated as overdue.
\*   -probe-genesis    a genesis orphan is compensated through the genesis lookup.
\*   -probe-fault      an orphan refused below step-4 is escalated as a deployment fault.
\*
\* NOT MODELLED: the binding index (a derived index, the section titled Composition state in
\* execution-contract.md) and [Verify Custody]; the read-back of invalid-request(step-4) at an
\* outcome (Audit arm 6 to 9), which lands as CommitClean or CommitOrphan; the custody
\* compensation window, the liveness sum and Invariant 4.2's eventuality (the harness checks
\* safety only); Primitive policy; payloads, seals and retention; a finding landed again after
\* it was opened; a compensating event naming intent candidates under the cap, which needs a
\* cap of two (Reconciliation 13).

EXTENDS Naturals, FiniteSets

CONSTANTS IntentFirst, Surface, RealizePairing, ReadInTxn, CapCheck, AgedEdge, GenesisGuard, Recovery

Inv == {"i1", "i2"}
Ent == {"i1", "i2", "x"}
Runs == {"r1", "r2"}
Custodians == {"c1", "c2"}
Kinds == {"transfer", "genesis"}
Cap == 1
NONE == "none"

VARIABLES
    kind,    \* Inv -> Kinds: the custody action's kind, fixed at the start
    lookup,  \* BOOLEAN: the deployment supplies the genesis lookup
    st,      \* Inv -> "idle" | "refused" | "clean" | "orphan" | "fault" | "unauth": how the invocation landed
    xc,      \* Custodians \cup {NONE}: the outside transfer's outgoing custodian, NONE until written
    out,     \* Ent -> 0..2: the outcome events naming the entry
    names,   \* Ent -> SUBSET Inv: the intents those outcome events name
    rec,     \* Ent -> BOOLEAN: an outcome event attested under the recovery identity
    flag,    \* Ent -> BOOLEAN: an outcome event carrying the recovery flag
    rint,    \* Ent -> BOOLEAN: a recovery intent landed for the entry
    esc,     \* Ent -> "none" | "fault" | "unpaired" | "overcap" | "overdue": the finding or escalation opened
    surf,    \* Inv -> BOOLEAN: the invocation surfaced its orphan in its answer, or escalated it
    aged,    \* Inv -> BOOLEAN: the intent's audit horizon has passed
    agedw,   \* Ent -> BOOLEAN: a write was made for the entry while an intent it named was aged
    snap,    \* Runs -> Ent \cup {NONE}: twin only, an orphan a run read and has yet to write
    snapc    \* Runs -> SUBSET Inv: twin only, the candidates that run read with it

vars == <<kind, lookup, st, xc, out, names, rec, flag, rint, esc, surf, aged, agedw, snap, snapc>>

HasIntent(i) == st[i] \in {"refused", "clean", "orphan", "fault"}
HasEntry(e) == IF e = "x" THEN xc # NONE ELSE st[e] \in {"clean", "orphan", "fault", "unauth"}
Fault(e) == IF e = "x" THEN FALSE ELSE st[e] = "fault"
EKind(e) == IF e = "x" THEN "transfer" ELSE kind[e]
ECust(e) == IF e = "x" THEN xc ELSE "c1"
ICust(i) == "c1"
Orphan(e) == HasEntry(e) /\ out[e] = 0
Named(i) == \E e \in Ent : i \in names[e]
Unmatched(i) == HasIntent(i) /\ ~Named(i)
GenesisReach == lookup \/ ~GenesisGuard

\* Term realize: the entry carries the intent's kind and parameters, from the custodian the
\* intent authenticated; a genesis intent is reached only through the genesis lookup.
Realizes(e, i) ==
    /\ kind[i] = EKind(e)
    /\ ICust(i) = ECust(e)
    /\ (kind[i] = "genesis" => GenesisReach)

\* The pairing (Reconciliation 10): Term realize for every leg, or, with RealizePairing
\* FALSE, a transferred entry paired by the chain and the incoming custodian alone.
Pairs(e, i) == IF RealizePairing \/ EKind(e) # "transfer" THEN Realizes(e, i) ELSE kind[i] = "transfer"

Cand(e) == {i \in Inv : Unmatched(i) /\ Pairs(e, i)}
AnyAged(S) == \E i \in S : aged[i]

\* An orphan the reconciliation has yet to land: no outcome event, no finding, no fault.
Open(e) == Orphan(e) /\ esc[e] = "none" /\ ~Fault(e)

Compensable(e) ==
    /\ Open(e)
    /\ Cand(e) # {}
    /\ (CapCheck => Cardinality(Cand(e)) <= Cap)
    /\ (AgedEdge => ~AnyAged(Cand(e)))

TypeOK ==
    /\ kind \in [Inv -> Kinds]
    /\ lookup \in BOOLEAN
    /\ st \in [Inv -> {"idle", "refused", "clean", "orphan", "fault", "unauth"}]
    /\ xc \in (Custodians \cup {NONE})
    /\ out \in [Ent -> 0..2]
    /\ names \in [Ent -> SUBSET Inv]
    /\ rec \in [Ent -> BOOLEAN]
    /\ flag \in [Ent -> BOOLEAN]
    /\ rint \in [Ent -> BOOLEAN]
    /\ esc \in [Ent -> {"none", "fault", "unpaired", "overcap", "overdue"}]
    /\ surf \in [Inv -> BOOLEAN]
    /\ aged \in [Inv -> BOOLEAN]
    /\ agedw \in [Ent -> BOOLEAN]
    /\ snap \in [Runs -> (Ent \cup {NONE})]
    /\ snapc \in [Runs -> SUBSET Inv]

Init ==
    /\ kind \in [Inv -> Kinds]
    /\ lookup \in BOOLEAN
    /\ st = [i \in Inv |-> "idle"]
    /\ xc = NONE
    /\ out = [e \in Ent |-> 0]
    /\ names = [e \in Ent |-> {}]
    /\ rec = [e \in Ent |-> FALSE]
    /\ flag = [e \in Ent |-> FALSE]
    /\ rint = [e \in Ent |-> FALSE]
    /\ esc = [e \in Ent |-> "none"]
    /\ surf = [i \in Inv |-> FALSE]
    /\ aged = [i \in Inv |-> FALSE]
    /\ agedw = [e \in Ent |-> FALSE]
    /\ snap = [r \in Runs |-> NONE]
    /\ snapc = [r \in Runs |-> {}]

\* A custody action, admitted and bound: its intent, its entry and its outcome event naming
\* the intent, in one transaction (Database 1; Action wiring 1, 5).
CommitClean(i) ==
    /\ st[i] = "idle"
    /\ st' = [st EXCEPT ![i] = "clean"]
    /\ out' = [out EXCEPT ![i] = 1]
    /\ names' = [names EXCEPT ![i] = {i}]
    /\ UNCHANGED <<kind, lookup, xc, rec, flag, rint, esc, surf, aged, agedw, snap, snapc>>

\* Audit Trail refuses the outcome event: the intent and the entry commit, and the action
\* answers recording-failure carrying outcome (Audit arm 19, 24).
CommitOrphan(i) ==
    /\ st[i] = "idle"
    /\ st' = [st EXCEPT ![i] = "orphan"]
    /\ surf' = [surf EXCEPT ![i] = Surface]
    /\ UNCHANGED <<kind, lookup, xc, out, names, rec, flag, rint, esc, aged, agedw, snap, snapc>>

\* The outcome refused invalid-request below step-4: escalated at once (Audit arm 26).
CommitFault(i) ==
    /\ st[i] = "idle"
    /\ st' = [st EXCEPT ![i] = "fault"]
    /\ esc' = [esc EXCEPT ![i] = "fault"]
    /\ surf' = [surf EXCEPT ![i] = TRUE]
    /\ UNCHANGED <<kind, lookup, xc, out, names, rec, flag, rint, aged, agedw, snap, snapc>>

\* Provenance refuses the write: the intent stands alone, a refused attempt (Action wiring 8,
\* 9).
Refuse(i) ==
    /\ st[i] = "idle"
    /\ st' = [st EXCEPT ![i] = "refused"]
    /\ UNCHANGED <<kind, lookup, xc, out, names, rec, flag, rint, esc, surf, aged, agedw, snap, snapc>>

\* Twin only: the entry and its outcome event commit with no intent.
CommitUnauth(i) ==
    /\ ~IntentFirst
    /\ st[i] = "idle"
    /\ st' = [st EXCEPT ![i] = "unauth"]
    /\ out' = [out EXCEPT ![i] = 1]
    /\ UNCHANGED <<kind, lookup, xc, names, rec, flag, rint, esc, surf, aged, agedw, snap, snapc>>

\* A transfer written to Provenance outside the composition's surface, by the holder then.
OutsideWrite(c) ==
    /\ xc = NONE
    /\ xc' = c
    /\ UNCHANGED <<kind, lookup, st, out, names, rec, flag, rint, esc, surf, aged, agedw, snap, snapc>>

\* An unmatched intent's audit horizon passes (Term aged intent). A matched intent's age
\* changes nothing the model reads.
Age(i) ==
    /\ Unmatched(i)
    /\ ~aged[i]
    /\ aged' = [aged EXCEPT ![i] = TRUE]
    /\ UNCHANGED <<kind, lookup, st, xc, out, names, rec, flag, rint, esc, surf, agedw, snap, snapc>>

\* The recovery intent and the compensating event, under the recovery identity, carrying the
\* recovery flag and naming the candidates (Reconciliation 13, 21 to 24).
Write(e, S) ==
    /\ out' = [out EXCEPT ![e] = IF out[e] < 2 THEN out[e] + 1 ELSE 2]
    /\ names' = [names EXCEPT ![e] = names[e] \cup S]
    /\ rec' = [rec EXCEPT ![e] = TRUE]
    /\ flag' = [flag EXCEPT ![e] = Recovery]
    /\ rint' = [rint EXCEPT ![e] = TRUE]
    /\ agedw' = [agedw EXCEPT ![e] = IF AnyAged(S) THEN TRUE ELSE agedw[e]]

\* The reconciliation compensates an orphan, its read and its writes in one transaction
\* (Database 2), so it reads again whether an outcome event names the entry (Reconciliation
\* 25, 26).
RecCompensate(e) ==
    /\ ReadInTxn
    /\ Compensable(e)
    /\ Write(e, Cand(e))
    /\ UNCHANGED <<kind, lookup, st, xc, esc, surf, aged, snap, snapc>>

\* No candidate: orphan-unpaired, never compensated (Reconciliation 11, 12).
RecUnpaired(e) ==
    /\ Open(e)
    /\ Cand(e) = {}
    /\ esc' = [esc EXCEPT ![e] = "unpaired"]
    /\ UNCHANGED <<kind, lookup, st, xc, out, names, rec, flag, rint, surf, aged, agedw, snap, snapc>>

\* More candidates than the cap: escalated, never compensated (Reconciliation 14, 15).
RecOverCap(e) ==
    /\ CapCheck
    /\ Open(e)
    /\ Cardinality(Cand(e)) > Cap
    /\ esc' = [esc EXCEPT ![e] = "overcap"]
    /\ UNCHANGED <<kind, lookup, st, xc, out, names, rec, flag, rint, surf, aged, agedw, snap, snapc>>

\* An aged candidate: no write, and the overdue orphan escalated (Reconciliation 4, 28).
RecAged(e) ==
    /\ AgedEdge
    /\ Open(e)
    /\ AnyAged(Cand(e))
    /\ esc' = [esc EXCEPT ![e] = "overdue"]
    /\ UNCHANGED <<kind, lookup, st, xc, out, names, rec, flag, rint, surf, aged, agedw, snap, snapc>>

\* Twin only: a run reads an orphan and its candidates in one step ...
RecRead(r, e) ==
    /\ ~ReadInTxn
    /\ snap[r] = NONE
    /\ Compensable(e)
    /\ snap' = [snap EXCEPT ![r] = e]
    /\ snapc' = [snapc EXCEPT ![r] = Cand(e)]
    /\ UNCHANGED <<kind, lookup, st, xc, out, names, rec, flag, rint, esc, surf, aged, agedw>>

\* ... and writes what it read in a later one, the orphan not read again.
RecWrite(r) ==
    /\ snap[r] # NONE
    /\ snap' = [snap EXCEPT ![r] = NONE]
    /\ snapc' = [snapc EXCEPT ![r] = {}]
    /\ Write(snap[r], snapc[r])
    /\ UNCHANGED <<kind, lookup, st, xc, esc, surf, aged>>

Next ==
    \/ \E i \in Inv : CommitClean(i)
    \/ \E i \in Inv : CommitOrphan(i)
    \/ \E i \in Inv : CommitFault(i)
    \/ \E i \in Inv : Refuse(i)
    \/ \E i \in Inv : CommitUnauth(i)
    \/ \E c \in Custodians : OutsideWrite(c)
    \/ \E i \in Inv : Age(i)
    \/ \E e \in Ent : RecCompensate(e)
    \/ \E e \in Ent : RecUnpaired(e)
    \/ \E e \in Ent : RecOverCap(e)
    \/ \E e \in Ent : RecAged(e)
    \/ \E r \in Runs, e \in Ent : RecRead(r, e)
    \/ \E r \in Runs : RecWrite(r)

Spec == Init /\ [][Next]_vars

\* ---- the page's guarantees -------------------------------------------------

Inv7_AuthPrecedence == \A i \in Inv : (HasEntry(i) => HasIntent(i))

Inv4_Surfaced == \A i \in Inv : (Orphan(i) => surf[i])

Inv4_OneOutcome == \A e \in Ent : out[e] <= 1

Inv4_NamesEntry == \A e \in Ent : (out[e] > 0 => HasEntry(e))

Inv1_Attributed ==
    /\ \A e \in Ent : (out[e] > 0 => names[e] # {})
    /\ \A e \in Ent : \A i \in names[e] : (kind[i] = EKind(e) /\ ICust(i) = ECust(e))

Inv_Cap == \A e \in Ent : Cardinality(names[e]) <= Cap

Inv_NoAgedWrite == \A e \in Ent : ~agedw[e]

Inv_GenesisLookup == \A e \in Ent : ((rec[e] /\ EKind(e) = "genesis") => lookup)

Inv_Recovery ==
    /\ \A e \in Ent : (rec[e] => (flag[e] /\ rint[e]))
    /\ \A e \in Ent : (flag[e] => rec[e])

\* ---- reachability probes (each must be violated) ----------------------------

\* a compensating event lands.
Probe_NoRecovered == \A e \in Ent : ~rec[e]
\* an outside transfer by another custodian, beside an unmatched transfer intent, lands
\* orphan-unpaired.
Probe_NoUnpairedOutside == ~(xc = "c2" /\ esc["x"] = "unpaired" /\ (\E i \in Inv : (kind[i] = "transfer" /\ Unmatched(i))))
\* an orphan with more candidates than the cap is escalated.
Probe_NoOverCap == \A e \in Ent : esc[e] # "overcap"
\* an orphan with an aged candidate is escalated as overdue.
Probe_NoAged == \A e \in Ent : esc[e] # "overdue"
\* a genesis orphan is compensated through the genesis lookup.
Probe_NoGenesis == ~(\E i \in Inv : (kind[i] = "genesis" /\ rec[i]))
\* an orphan refused below step-4 is escalated as a deployment fault.
Probe_NoFault == \A e \in Ent : esc[e] # "fault"

====
