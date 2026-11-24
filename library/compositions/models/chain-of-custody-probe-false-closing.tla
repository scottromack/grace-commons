---- MODULE chain-of-custody-probe-false-closing ----
\* EXPECT: violation — reachability probe: an operator abandons an intent whose write landed: a false closing the leg alerts (Reconciliation 32).
\* Grace Commons — Chain of Custody.
\* Provenance + Audit Trail (substrate) + Recoverable Invocation.
\* Spec-level formal sibling of compositions/chain-of-custody.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-10 for the page's composition of Recoverable Invocation (Composes 12
\* to 16, Term custody bindings). The model of 2026-10-27 read every custody action as one
\* transaction, the intent, the Provenance entry and the outcome committing together, and
\* modelled the page's own reconciliation (the pairing by Term realize, the candidates and
\* their cap, the aged edge, the recovery identity, the escalation). Both premises are gone:
\* a custody action is an open, a commit and a close, three commits and not one transaction
\* (Non-goal 12; Recoverable Invocation Non-goal 1), and the closing of an act whose outcome
\* never landed is Recoverable Invocation's sweep's. So this one model follows the split arc;
\* the reconciliation's twins retire to Recoverable Invocation's rules (the coverage matrix
\* names each).
\*
\* RECOVERABLE INVOCATION, AS A CONTRACT. Nothing of its mechanism is modelled: no lease, no
\* critical section, no examine edge, no horizon, no clock arithmetic. What this model takes
\* from it, and recoverable-invocation.tla checks:
\*   - [Open] writes the intent, verifying the credential, before the commit, and refuses
\*     act-in-flight while an intent of the same (kind, act key) stands open (open step 1.7,
\*     3.5; open invocations 1): one live or yielded invocation per act key here.
\*   - The commit answers committed, pre-commit or unknown (commit 1); committed goes to
\*     [Close], pre-commit to [Refuse] (a refusal record), unknown to [Yield] (commit 8). An
\*     unknown arm may or may not have written: the environment chooses.
\*   - A close that fails, or an invocation that dies after its commit, leaves the intent
\*     open for the sweep (Cross-record consistency 1).
\*   - The sweep examines only an intent whose invocation is gone, runs the page's act probe,
\*     and writes the recovered outcome (behind a recovery intent, flagged as recovery, under
\*     the recovery identity: one step here, reconcile step 3.2a) on committed, or an
\*     escalation on not-committed or undecidable (reconcile step 3.2, 3.5, 3.8). An
\*     unavailable probe writes nothing, which is a stutter step.
\*   - An operator, through the invocation resolve, may close an open or escalated intent
\*     with an outcome naming any entry the operator chooses, or abandon it, and may supersede
\*     an abandonment with an outcome (resolve 14 to 16, 32). The resolve does not check the
\*     outcome against Provenance (resolve 28, 31).
\*
\* WHAT THIS MODEL CHECKS
\* One artifact, one chain, two custodians, three bound invocations, one transfer written to
\* Provenance outside every invocation, and whatever order the invocations, the sweep, the
\* operator, the outside write, the binding rebuild and the write-ownership leg take:
\*   - Inv7_AuthPrecedence      an entry an invocation's commit wrote follows the invocation's
\*                              intent (Action wiring 12, 13, 20, 21, 27, 28; Recoverable
\*                              Invocation Invariant 1.1, which this page's acts rest on).
\*   - Transfer_holder_rechecked  a transferred entry an invocation wrote carries, as its
\*                              outgoing custodian, the custodian its intent was attested under
\*                              (Invariant 7.2, Wiring decision 4; Action wiring 63 to 65).
\*   - Inv1_Attributed          every outcome the invocation or the sweep wrote names an entry
\*                              of its kind whose attested custodian is the intent's actor
\*                              (Invariant 1.2, Check 1.3).
\*   - Invariant_4_3            two outcomes naming one entry are never both the invocation's
\*                              or the sweep's: a second is an operator's (Invariant 4.3 NOTE).
\*   - Recovered_names_entry    every outcome the invocation or the sweep wrote names an entry
\*                              the chain carries (Invariant 4.4; Recoverable Invocation act
\*                              probe 4, 5).
\*   - Owed_outcome             an invocation whose commit wrote stands open or beside a
\*                              closing (an outcome, an escalation, an abandonment), never a
\*                              refusal (Invariant 4.1; Cross-record consistency 1).
\*   - Pairing_unique           the sweep answers committed only for the intent whose own
\*                              commit wrote the entry (Capability requirement 34, 35;
\*                              Recoverable Invocation pairing datum 2, 4).
\*   - Genesis_needs_lookup     no recovered origination where the deployment supplies no
\*                              genesis lookup (Term originate probe; Recoverable Invocation
\*                              Deviation 4c).
\*   - Write_ownership_finding  the leg opens a finding for every entry a write outside every
\*                              invocation made, and for no other (Reconciliation 7, 11).
\*   - False_closing_alert      the leg alerts exactly the entries whose own intent an
\*                              abandonment or a refusal closed (Reconciliation 32).
\*   - Duplicate_detected       the binding rebuild opens a binding-duplicate finding for every
\*                              entry two outcomes name (Composition state 9; Invariant 4.3
\*                              NOTE, detected for an operator's closing).
\*
\* BOUND
\* Chain ids 1..NC = 1..1, minted at the origination's commit. Custodians 1..NCu = 1..2.
\* N = 3 bound invocations, taken in slot order: an origination, a transfer and a third (a
\* second transfer, a transformation, a retry), the fewest that reach a transfer resolved
\* before another's commit and a retried act of one key. MaxDirect = 1 transfer outside any
\* invocation. Whether the deployment supplies the genesis lookup is chosen at the start
\* (Capability requirement 22). Each invocation takes a fresh now from an ordinal clock as its
\* pairing datum (the host's injection, Capability requirement 26, 34, 35), which Provenance
\* stamps as the entry's recording instant; a write outside any invocation reads the same
\* clock. Exhaustive.
\*
\* HOW A STEP IS READ
\* A bound invocation is a slot; its status `st` is none, resolved (a transfer's resolution
\* read done, its open not yet made), live (the intent landed), committed, dead (yielded, died,
\* or its close failed: the intent open, the sweep's), closed (an outcome names it), refused
\* (a refusal record), escalated or abandoned. `cby` says who wrote the closing (the
\* invocation, the sweep or the operator) and `oe` which entry its outcome names (0: none).
\* `cw` says the invocation's own commit wrote an entry, `ie` which (ghosts), and `eby` which
\* invocation wrote an entry (0: a write outside every invocation; a ghost). The leg's and
\* the rebuild's answers are compared with the ghosts by a name the step adds to `viol`: the
\* step answers by the page's rule and the name compares that answer with the truth.
\*
\* NOT MODELLED (named)
\* - Recoverable Invocation's mechanism and its own invariants (one writer per act, the
\*   recovery intent before a recovered outcome, the recovery flag, the service identity's
\*   attestation, the closure window, the horizon edge, the escalation's candidates):
\*   recoverable-invocation.tla, inherited here.
\* - The clock and its edges: the young entry and the aged entry (Reconciliation 4, 34), the
\*   sweep cadence (Reconciliation 2, 31), the settled entry. A commit landing after its
\*   invocation yielded is the unknown arm that wrote; the operator's abandonment over it
\*   stands for Recoverable Invocation's stall.
\* - Disclosure and archival: [Transform Custody] stands for the three custodian-guarded steps
\*   (Action wiring 27 to 32, 66), and the archived refusals (Action wiring 18, 64) are not
\*   reached. Provenance's other refusals and storage-failure: each is a pre-commit arm that
\*   writes what the not-current-custodian refusal writes.
\* - [Verify Custody], the binding index's content (the binding rebuild is read only for its
\*   duplicate finding), payloads, seals, retention, Primitive policy, the metadata.
\* - A second chain: one artifact's second origination finds no chain id and only yields;
\*   the originate probe's several-chains arm (undecidable) is not reached.

EXTENDS Naturals, FiniteSets

CONSTANTS NC, NCu, N, MaxDirect

Cs == 1..NC
Cus == 1..NCu
Is == 1..N
Kinds == {"orig", "xfer", "step"}
OpenSt == {"live", "committed", "dead"}
MaxT == N + MaxDirect
MaxE == N + MaxDirect
Es == 1..MaxE

VARIABLES
    lookup,                                     \* the deployment supplies the genesis lookup
    ne, ech, etyp, efrom, eto, eat, eby,        \* the Provenance entries
    hold,                                       \* each chain's holder (0: not originated)
    ik, ic, icu, ito, inow, st, iw, cw, ie, oe, cby,   \* the bound invocations
    nx, clk, nd,                                \* the next slot, the clock, outside writes
    viol
vars == <<lookup, ne, ech, etyp, efrom, eto, eat, eby, hold,
          ik, ic, icu, ito, inow, st, iw, cw, ie, oe, cby, nx, clk, nd, viol>>

prov == <<ne, ech, etyp, efrom, eto, eat, eby, hold>>
inv == <<ik, ic, icu, ito, inow, st, iw, cw, ie, oe, cby>>

Entries == 1..ne

\* The act kind an entry's event type names: a genesis entry custody.originate, a transferred
\* entry custody.transfer, a transformed entry custody.transform.
KindOf(e) == IF etyp[e] = "gen" THEN "orig" ELSE IF etyp[e] = "xfer" THEN "xfer" ELSE "step"

\* The act key's open intent: [Open] refuses act-in-flight while one stands. An origination's
\* key is its custodian (one artifact, one genesis type); another kind's is its chain id.
OpenOn(k, key) ==
    \E j \in Is : ik[j] = k /\ st[j] \in OpenSt /\ (IF k = "orig" THEN icu[j] = key ELSE ic[j] = key)

Unused == {c \in Cs : hold[c] = 0}
NextId == CHOOSE c \in Unused : \A d \in Unused : c <= d

\* --- Term carried entry: an intent of the entry's act kind whose act key the entry carries
\* (the custodian for a genesis entry, the chain id for another) and whose pairing datum
\* equals the entry's recording instant.
Carries(i, e) ==
    /\ iw[i]
    /\ ik[i] = KindOf(e)
    /\ inow[i] = eat[e]
    /\ IF etyp[e] = "gen" THEN icu[i] = efrom[e] ELSE ic[i] = ech[e]
Carried(e) == \E i \in Is : Carries(i, e)

\* --- the write-ownership leg's reading (Reconciliation 7, 11, 32) ---
LegFinds(e) == ~Carried(e)
LegAlerts(e) == \E i \in Is : Carries(i, e) /\ st[i] \in {"abandoned", "refused"}

\* --- the truth the leg's answers are compared with ---
Ownerless(e) == eby[e] = 0
FalselyClosed(e) == eby[e] # 0 /\ st[eby[e]] \in {"abandoned", "refused"}

\* --- the binding rebuild's reading (Composition state 8, 9) ---
Namers(e) == {i \in Is : st[i] = "closed" /\ oe[i] = e}
RebuildDup(e) == Cardinality(Namers(e)) >= 2

\* --- the act probes (Term originate probe, Term step probe) ---
\* The entries matching an intent's kind, key, parameters and pairing datum. An origination is
\* found only through the genesis lookup (Recoverable Invocation Deviation 4c).
Matches(i) ==
    {e \in Entries :
        /\ etyp[e] = (IF ik[i] = "orig" THEN "gen" ELSE ik[i])
        /\ eat[e] = inow[i]
        /\ efrom[e] = icu[i]
        /\ (ik[i] # "orig" => ech[e] = ic[i])
        /\ (ik[i] = "xfer" => eto[e] = ito[i])}
ProbeReads(i) == ik[i] # "orig" \/ lookup

TypeOK ==
    /\ lookup \in BOOLEAN
    /\ ne \in 0..MaxE
    /\ ech \in [Es -> 0..NC]
    /\ etyp \in [Es -> {"-", "gen", "xfer", "step"}]
    /\ efrom \in [Es -> 0..NCu]
    /\ eto \in [Es -> 0..NCu]
    /\ eat \in [Es -> 0..MaxT]
    /\ eby \in [Es -> 0..N]
    /\ hold \in [Cs -> 0..NCu]
    /\ ik \in [Is -> Kinds \cup {"-"}]
    /\ ic \in [Is -> 0..NC]
    /\ icu \in [Is -> 0..NCu]
    /\ ito \in [Is -> 0..NCu]
    /\ inow \in [Is -> 0..MaxT]
    /\ st \in [Is -> {"none", "resolved", "live", "committed", "dead", "closed", "refused",
                      "escalated", "abandoned"}]
    /\ iw \in [Is -> BOOLEAN]
    /\ cw \in [Is -> BOOLEAN]
    /\ ie \in [Is -> 0..MaxE]
    /\ oe \in [Is -> 0..MaxE]
    /\ cby \in [Is -> {"-", "inv", "sweep", "op"}]
    /\ nx \in 1..(N + 1)
    /\ clk \in 0..MaxT
    /\ nd \in 0..MaxDirect
    /\ viol \subseteq {"finding-false", "finding-missed", "alert-wrong", "dup-missed"}

Init ==
    /\ lookup \in BOOLEAN
    /\ ne = 0
    /\ ech = [e \in Es |-> 0]
    /\ etyp = [e \in Es |-> "-"]
    /\ efrom = [e \in Es |-> 0]
    /\ eto = [e \in Es |-> 0]
    /\ eat = [e \in Es |-> 0]
    /\ eby = [e \in Es |-> 0]
    /\ hold = [c \in Cs |-> 0]
    /\ ik = [i \in Is |-> "-"]
    /\ ic = [i \in Is |-> 0]
    /\ icu = [i \in Is |-> 0]
    /\ ito = [i \in Is |-> 0]
    /\ inow = [i \in Is |-> 0]
    /\ st = [i \in Is |-> "none"]
    /\ iw = [i \in Is |-> FALSE]
    /\ cw = [i \in Is |-> FALSE]
    /\ ie = [i \in Is |-> 0]
    /\ oe = [i \in Is |-> 0]
    /\ cby = [i \in Is |-> "-"]
    /\ nx = 1
    /\ clk = 0
    /\ nd = 0
    /\ viol = {}

\* Append one entry to Provenance, stamped with the injected now.
Append(c, ty, fr, to, t, by) ==
    LET e == ne + 1 IN
    /\ ne' = e
    /\ ech' = [ech EXCEPT ![e] = c]
    /\ etyp' = [etyp EXCEPT ![e] = ty]
    /\ efrom' = [efrom EXCEPT ![e] = fr]
    /\ eto' = [eto EXCEPT ![e] = to]
    /\ eat' = [eat EXCEPT ![e] = t]
    /\ eby' = [eby EXCEPT ![e] = by]
    /\ hold' = [hold EXCEPT ![c] = to]

\* ---------------------------------------------------------------------------------------
\* The custody actions: validate, open, commit, close (Recoverable Invocation Action wiring 4).

\* The pairing datum the host injects: a fresh now (Capability requirement 26, 34, 35).
Nows == {clk + 1}

\* [Transfer Custody]'s resolution read, ahead of the open (Action wiring 16 to 19): the
\* holder the chain shows is the outgoing custodian the intent will be attested under.
Resolve(c, to) ==
    LET i == nx IN
    /\ i <= N
    /\ hold[c] # 0
    /\ to # hold[c]
    /\ ik' = [ik EXCEPT ![i] = "xfer"]
    /\ ic' = [ic EXCEPT ![i] = c]
    /\ icu' = [icu EXCEPT ![i] = hold[c]]
    /\ ito' = [ito EXCEPT ![i] = to]
    /\ st' = [st EXCEPT ![i] = "resolved"]
    /\ nx' = i + 1
    /\ UNCHANGED <<inow, iw, cw, ie, oe, cby, clk, nd, lookup, prov, viol>>

\* [Open] for a resolved transfer: no intent of the chain's transfer kind stands open; the
\* intent lands under the resolved custodian, carrying the now (Action wiring 20).
OpenXfer(i, t) ==
    /\ st[i] = "resolved"
    /\ ~OpenOn("xfer", ic[i])
    /\ inow' = [inow EXCEPT ![i] = t]
    /\ clk' = t
    /\ iw' = [iw EXCEPT ![i] = TRUE]
    /\ st' = [st EXCEPT ![i] = "live"]
    /\ UNCHANGED <<ik, ic, icu, ito, cw, ie, oe, cby, nx, nd, lookup, prov, viol>>

\* [Open] for an origination (Action wiring 12) or a transformation (Action wiring 27): the
\* intent lands under the caller's custodian reference (Primitive policy 16), carrying the now.
OpenAct(k, c, cu, t) ==
    LET i == nx IN
    /\ i <= N
    /\ k \in {"orig", "step"}
    /\ (k = "step") => hold[c] # 0
    /\ (k = "orig") => c = 1
    /\ ~OpenOn(k, IF k = "orig" THEN cu ELSE c)
    /\ ik' = [ik EXCEPT ![i] = k]
    /\ ic' = [ic EXCEPT ![i] = IF k = "orig" THEN 0 ELSE c]
    /\ icu' = [icu EXCEPT ![i] = cu]
    /\ inow' = [inow EXCEPT ![i] = t]
    /\ clk' = t
    /\ iw' = [iw EXCEPT ![i] = TRUE]
    /\ st' = [st EXCEPT ![i] = "live"]
    /\ nx' = i + 1
    /\ UNCHANGED <<ito, cw, ie, oe, cby, nd, lookup, prov, viol>>

\* The commit. a = "committed" or "unk-done" writes (the latter yields, the write landed);
\* "unk-none" yields with nothing written; "pre" is a pre-commit arm, closed through [Refuse]
\* with its refusal record and nothing written (Action wiring 8, 9, 67).
\*   origination: the origination transaction, minting the chain id (Action wiring 13 to 15).
\*   transfer: the transfer transaction re-reads the holder and refuses not-current-custodian
\*     where it changed since the resolution (Action wiring 63, 65), else Provenance's
\*     transfer writes from the holder (Action wiring 21).
\*   transformation: Provenance's guard refuses a caller who is not the holder.
Commit(i, a) ==
    LET c == IF ik[i] = "orig" THEN NextId ELSE ic[i]
        ok == IF ik[i] = "orig" THEN Unused # {} ELSE hold[c] = icu[i]
        ty == IF ik[i] = "orig" THEN "gen" ELSE ik[i]
        to == IF ik[i] = "xfer" THEN ito[i] ELSE icu[i]
    IN
    /\ st[i] = "live"
    /\ \/ /\ a \in {"committed", "unk-done"}
          /\ ok
          /\ Append(c, ty, icu[i], to, inow[i], i)
          /\ ic' = [ic EXCEPT ![i] = c]
          /\ cw' = [cw EXCEPT ![i] = TRUE]
          /\ ie' = [ie EXCEPT ![i] = ne + 1]
          /\ st' = [st EXCEPT ![i] = IF a = "committed" THEN "committed" ELSE "dead"]
       \/ /\ a = "pre"
          /\ ~ok
          /\ ik[i] # "orig"
          /\ st' = [st EXCEPT ![i] = "refused"]
          /\ UNCHANGED <<prov, ic, cw, ie>>
       \/ /\ a = "unk-none"
          /\ st' = [st EXCEPT ![i] = "dead"]
          /\ UNCHANGED <<prov, ic, cw, ie>>
    /\ UNCHANGED <<ik, icu, ito, inow, iw, oe, cby, nx, clk, nd, lookup, viol>>

\* [Close] after a committed arm: the outcome names the entry the commit wrote (Action wiring
\* 15, 26, 66). It may fail, or the invocation may die first: the intent stays open for the
\* sweep (Action wiring 68; Cross-record consistency 1).
Close(i, o) ==
    /\ st[i] = "committed"
    /\ \/ /\ o = "ok"
          /\ st' = [st EXCEPT ![i] = "closed"]
          /\ cby' = [cby EXCEPT ![i] = "inv"]
          /\ oe' = [oe EXCEPT ![i] = ie[i]]
       \/ /\ o = "fail"
          /\ st' = [st EXCEPT ![i] = "dead"]
          /\ UNCHANGED <<cby, oe>>
    /\ UNCHANGED <<ik, ic, icu, ito, inow, iw, cw, ie, nx, clk, nd, lookup, prov, viol>>

\* ---------------------------------------------------------------------------------------
\* Recoverable Invocation's sweep and the operator's resolve, as contracts.

\* The sweep on an intent whose invocation is gone: the act probe answers committed where
\* exactly one entry matches, and the sweep writes the recovered outcome naming it; otherwise
\* (none, several, or an origination with no genesis lookup) it escalates.
Sweep(i) ==
    /\ st[i] = "dead"
    /\ IF ProbeReads(i) /\ Cardinality(Matches(i)) = 1
       THEN /\ st' = [st EXCEPT ![i] = "closed"]
            /\ cby' = [cby EXCEPT ![i] = "sweep"]
            /\ oe' = [oe EXCEPT ![i] = CHOOSE e \in Matches(i) : TRUE]
       ELSE /\ st' = [st EXCEPT ![i] = "escalated"]
            /\ UNCHANGED <<cby, oe>>
    /\ UNCHANGED <<ik, ic, icu, ito, inow, iw, cw, ie, nx, clk, nd, lookup, prov, viol>>

\* The operator's resolve: an outcome naming any entry the operator chooses, or an
\* abandonment; an abandonment is superseded only by an outcome (resolve 14 to 16, 21, 32).
OpResolve(i, d, e) ==
    /\ \/ /\ d = "abandon"
          /\ st[i] \in {"dead", "escalated"}
          /\ st' = [st EXCEPT ![i] = "abandoned"]
          /\ cby' = [cby EXCEPT ![i] = "op"]
          /\ UNCHANGED oe
       \/ /\ d = "outcome"
          /\ st[i] \in {"dead", "escalated", "abandoned"}
          /\ e \in Entries
          /\ st' = [st EXCEPT ![i] = "closed"]
          /\ cby' = [cby EXCEPT ![i] = "op"]
          /\ oe' = [oe EXCEPT ![i] = e]
    /\ UNCHANGED <<ik, ic, icu, ito, inow, iw, cw, ie, nx, clk, nd, lookup, prov, viol>>

\* ---------------------------------------------------------------------------------------
\* A transfer written to Provenance outside every invocation, by the holder at the time, with
\* no intent and no outcome, stamped from the same clock.
Direct(c, to) ==
    /\ nd < MaxDirect
    /\ hold[c] # 0
    /\ to # hold[c]
    /\ Append(c, "xfer", hold[c], to, clk + 1, 0)
    /\ clk' = clk + 1
    /\ nd' = nd + 1
    /\ UNCHANGED <<inv, nx, lookup, viol>>

\* The write-ownership leg (Reconciliation 7, 11, 32): every entry read against the intents,
\* on an answered read (Reconciliation 30). It opens a finding and alerts by the page's rule;
\* the names it adds compare the rule's answer with what the records hold.
LegRun ==
    /\ viol' = viol
         \cup (IF \E e \in Entries : LegFinds(e) /\ ~Ownerless(e) THEN {"finding-false"} ELSE {})
         \cup (IF \E e \in Entries : Ownerless(e) /\ ~LegFinds(e) THEN {"finding-missed"} ELSE {})
         \cup (IF \E e \in Entries : LegAlerts(e) # FalselyClosed(e) THEN {"alert-wrong"} ELSE {})
    /\ UNCHANGED <<inv, nx, clk, nd, lookup, prov>>

\* The binding rebuild (Composition state 7 to 9): an entry two outcomes name opens a
\* binding-duplicate finding.
Rebuild ==
    /\ viol' = viol \cup (IF \E e \in Entries : Cardinality(Namers(e)) >= 2 /\ ~RebuildDup(e)
                         THEN {"dup-missed"} ELSE {})
    /\ UNCHANGED <<inv, nx, clk, nd, lookup, prov>>

Next ==
    \/ \E c \in Cs, cu \in Cus : Resolve(c, cu)
    \/ \E i \in Is, t \in Nows : OpenXfer(i, t)
    \/ \E k \in {"orig", "step"}, c \in Cs, cu \in Cus, t \in Nows : OpenAct(k, c, cu, t)
    \/ \E i \in Is, a \in {"committed", "unk-done", "unk-none", "pre"} : Commit(i, a)
    \/ \E i \in Is, o \in {"ok", "fail"} : Close(i, o)
    \/ \E i \in Is : Sweep(i)
    \/ \E i \in Is, d \in {"abandon", "outcome"}, e \in Es : OpResolve(i, d, e)
    \/ \E c \in Cs, cu \in Cus : Direct(c, cu)
    \/ LegRun
    \/ Rebuild
Spec == Init /\ [][Next]_vars

\* --- composition-level safety invariants ---

\* An entry an invocation's commit wrote follows the invocation's intent.
Inv7_AuthPrecedence == \A i \in Is : cw[i] => iw[i]

\* Invariant 7.2, Wiring decision 4: a transferred entry an invocation wrote carries, as its
\* outgoing custodian, the custodian its intent was attested under.
Transfer_holder_rechecked ==
    \A e \in Entries : (etyp[e] = "xfer" /\ eby[e] # 0) => efrom[e] = icu[eby[e]]

\* Invariant 1.2, Check 1.3: an outcome the invocation or the sweep wrote names an entry of
\* its kind whose attested custodian is the intent's actor. An operator's is detected.
Inv1_Attributed ==
    \A i \in Is : (st[i] = "closed" /\ cby[i] # "op" /\ oe[i] \in Entries)
                     => (KindOf(oe[i]) = ik[i] /\ efrom[oe[i]] = icu[i])

\* Invariant 4.3: two outcomes naming one entry are never both the invocation's or the
\* sweep's; a second is an operator's, which the binding rebuild detects.
Invariant_4_3 ==
    \A i, j \in Is : (i # j /\ st[i] = "closed" /\ st[j] = "closed" /\ oe[i] = oe[j] /\ oe[i] \in Entries)
                        => (cby[i] = "op" \/ cby[j] = "op")

\* Invariant 4.4: an outcome the invocation or the sweep wrote names an entry the chain
\* carries.
Recovered_names_entry ==
    \A i \in Is : (st[i] = "closed" /\ cby[i] # "op") => oe[i] \in Entries

\* Invariant 4.1, Cross-record consistency 1: an invocation whose commit wrote stands open or
\* beside a closing, never a refusal.
Owed_outcome ==
    \A i \in Is : cw[i] => st[i] \in {"committed", "dead", "closed", "escalated", "abandoned"}

\* Capability requirement 34, 35: the sweep answers committed only for the intent whose own
\* commit wrote the entry.
Pairing_unique ==
    \A i \in Is : (st[i] = "closed" /\ cby[i] = "sweep" /\ oe[i] \in Entries) => eby[oe[i]] = i

\* Term originate probe; Recoverable Invocation Deviation 4c: no recovered origination where
\* the deployment supplies no genesis lookup.
Genesis_needs_lookup ==
    \A i \in Is : (ik[i] = "orig" /\ st[i] = "closed" /\ cby[i] = "sweep") => lookup

\* Reconciliation 11: a finding for every entry a write outside every invocation made, and
\* for no other.
Write_ownership_finding == ~("finding-false" \in viol) /\ ~("finding-missed" \in viol)

\* Reconciliation 32: an alert for exactly the entries whose own intent an abandonment or a
\* refusal closed.
False_closing_alert == ~("alert-wrong" \in viol)

\* Composition state 9: the rebuild opens a binding-duplicate finding for every entry two
\* outcomes name.
Duplicate_detected == ~("dup-missed" \in viol)

\* Reachability probe: the correct model, this one invariant added, which the checker must find false.
Probe_false == ~(\E e \in Entries : eby[e] # 0 /\ st[eby[e]] = "abandoned" /\ LegAlerts(e))

====
