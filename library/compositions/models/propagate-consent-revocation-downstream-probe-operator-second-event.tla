---- MODULE propagate-consent-revocation-downstream-probe-operator-second-event ----
\* EXPECT: violation — reachability probe: an operator's outcome is a second propagation event for one consent id (Invariant 3 NOTE: detected by Check 3.1, not prevented).
\* Grace Commons — Propagate Consent Revocation Downstream.
\* Consent + Permissions + Audit Trail (substrate) + Retention Window + Recoverable Invocation.
\* Spec-level formal sibling of compositions/propagate-consent-revocation-downstream.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-10 for the page's composition of Recoverable Invocation (Composes 15
\* to 19, Term consent bindings). The model of 2026-11-09 read every action as one
\* transaction, the intent, the Consent write and the outcome committing together, and kept
\* the reconciliation (the clock, the pairing, the compensation, the escalation) as a second
\* model. Both premises are gone for the two bound actions: [Record Consent] and [Withdraw
\* Consent] are each an open, a commit and a close, three commits and not one transaction
\* (Non-goal 10; Recoverable Invocation Non-goal 1), and the closing of an act whose outcome
\* never landed is Recoverable Invocation's sweep's. So this one model follows the split arc
\* and replaces both; the reconciliation model and its twins retire to Recoverable
\* Invocation's rules (the coverage matrix names each). [Register Processing], [Read Consent
\* History] and [Processing Permitted] are unbound (Composes 18) and stay one transaction.
\*
\* RECOVERABLE INVOCATION, AS A CONTRACT. Nothing of its mechanism is modelled: no lease, no
\* critical section, no examine edge, no horizon, no clock arithmetic. What this model takes
\* from it, and recoverable-invocation.tla checks:
\*   - [Open] writes the intent, verifying the credential, before the commit, and refuses
\*     act-in-flight while an intent of the same (kind, act key) stands open (open step 1.7,
\*     3.5, 3.7; open invocations 1): one live or yielded invocation per act key here.
\*   - The commit answers committed, pre-commit or unknown (commit 1); committed goes to
\*     [Close], pre-commit to [Refuse] (a refusal record), unknown to [Yield] (commit 8). An
\*     unknown arm may or may not have written: the environment chooses.
\*   - A close that fails (recording-failure carrying outcome), or an invocation that dies
\*     after its commit, leaves the intent open for the sweep (Cross-record consistency 1,
\*     2).
\*   - The sweep examines only an intent whose invocation is gone, runs the page's act
\*     probe, and writes the recovered outcome (behind a recovery intent, flagged as
\*     recovery, under the recovery identity: one step here, reconcile 8) on committed, or
\*     an escalation on not-committed or undecidable (reconcile step 3.2, 3.5, 3.8). An
\*     unavailable probe writes nothing, which is a stutter step.
\*   - An operator, through the invocation resolve, may close an elapsed open intent or an
\*     escalation with an outcome whose data the operator supplies, or abandon it, and may
\*     supersede an abandonment with an outcome (resolve 14 to 16, 32). The resolve does not
\*     check the outcome against the Consent records (resolve 28, 31): the operator may
\*     close any elapsed or escalated intent with an outcome, whatever the records hold,
\*     and a grant outcome may name any record. A withdrawal outcome's set is the one the
\*     operator's own probe run derives: no check reads an operator's set, and fixing it
\*     keeps the state space within one worker's reach.
\*
\* WHAT THIS MODEL CHECKS
\* Two Consent records for one subject and purpose (one grant key), two downstream pairs the
\* first consent's registrations bind, three bound invocations, one write outside any
\* invocation, a history read, and whatever order the invocations, the sweep, the operator,
\* the registrations, the index writes, the horizon's purge and the write-ownership leg take:
\*   - Invariant 1.1     [Processing Permitted] answers permitted only if the consent check
\*                       answers granted.
\*   - Invariant 1.3     two governed consents in Granted never carry one subject reference
\*                       and purpose: the consent check inside the grant transaction.
\*   - Invariant 3.1     every propagation event the invocation or the sweep wrote names a
\*                       Revoked record (Wiring decision 1: the close follows the revoke).
\*   - Invariant 3.2     two propagation events for one consent id are never both the
\*                       invocation's or the sweep's: a second is always an operator's.
\*   - Invariant 3.3     every propagation event the invocation or the sweep wrote carries
\*                       the registered set at its intent's position.
\*   - Invariant 4.1     a binding names a registration event.
\*   - Invariant 5.1     a governed record is carried by the intent of its own write, and a
\*                       history answered has its access event.
\*   - Invariant 6.1     a governed consent carries its retention.
\*   - Invariant 7.1     no constituent write for an actor the permission check denied.
\*   - Invariant 8.3, 8.4  no binding and no history answer before Audit Trail validates
\*                       the caller's credential at the single write.
\*   - Action_wiring_order  a commit follows its intent, an invocation's close its commit.
\*   - Action_wiring_24  an index entry follows a grant event naming the consent id (one the
\*                       close wrote, the sweep recovered or an operator wrote).
\*   - Composition state 6, 13  a binding is never removed; a purged entry is truth-bearing.
\*   - Owed_outcome      an invocation whose commit wrote stands open or beside a closing (an
\*                       outcome, an escalation, an abandonment), never a refusal
\*                       (Recoverable Invocation Invariant 4.1's shape).
\*   - Recovered_set_at_intent  a propagation event the sweep recovered carries the set the
\*                       withdrawal probe derived at the intent's own position (Term
\*                       withdrawal probe; Recoverable Invocation act probe 6).
\*   - Pairing_unique    the probe answers committed only for the intent whose own commit
\*                       wrote the record (Capability requirement 37, 38; Recoverable
\*                       Invocation pairing datum 2, 4).
\*   - Write_ownership_finding  the leg opens a finding for every Consent record a write
\*                       outside every invocation made, and for no other (Reconciliation
\*                       11, 16).
\*   - False_closing_alert  the leg alerts exactly the Consent records standing beside an
\*                       intent of their key and pairing datum closed by an abandonment or a
\*                       refusal (Reconciliation 40, 41).
\*
\* THE OPERATOR'S RESIDUE (Invariant 3 NOTE; Check 3.1, 3.2, 3.10). Invariant 3.1 to 3.3 are
\* checked over the events the invocation and the sweep write. An operator's outcome is the
\* only way a second propagation event, or one naming a record not Revoked, appears; it
\* carries the resolving actor, so an auditor reads it as the operator's
\* (-probe-operator-second-event shows the second event is reachable). An operator's set
\* is unchecked in the same way (Check 3.2); the model fixes it (above). The
\* mirror, an operator abandoning an intent whose write landed, is the false closing the leg
\* alerts (-probe-false-closing).
\*
\* BOUND
\* Consent ids 1..NC = 1..2, minted in order; registrations bind consent 1 (C1) only, as
\* before: a registration on the second consent crosses no rule the first does not. N = 3
\* bound invocations, opened in slot order: a grant, its withdrawal and a third (a re-grant,
\* a retry of the withdrawal, a second grant), the fewest that reach two propagation events
\* for one consent id (the .cfg records the runs at other sizes). MaxDirect = 1 write
\* outside any invocation. Each invocation takes a fresh now from an ordinal clock (the
\* host's injection, Capability requirement 27, 37, 38), and a write outside any invocation
\* reads the same clock. The Event Log's order is an ordinal `pos` given to the events whose
\* order a rule reads: a registration event, a withdrawal intent, and the revoke's commit in
\* the store (Term event's boundary; the window of Cross-record consistency 3). The history
\* read touches nothing any other step reads and no check relates it to them, so it is taken
\* first, before any other step, which loses no behaviour a check reads. Exhaustive.
\*
\* HOW A STEP IS READ
\* A bound invocation is a slot; its status `st` is none, live (the intent landed),
\* committed (the commit answered committed), dead (the invocation yielded, died, or its
\* close failed: the intent open, the sweep's), closed (an outcome names it), refused (a
\* refusal record), escalated or abandoned. `cby` says who wrote the closing (the
\* invocation, the sweep or the operator), `cw` that the invocation's own commit wrote the
\* Consent record (a ghost), and `gBy` and `rBy` which invocation wrote a record's grant and
\* revoke (0: a write outside any invocation; ghosts). A property of a step (a gate that
\* disagrees with the consent check, a write for a denied actor, a leg's finding or alert
\* that disagrees with what the records hold) is a name the step adds to `viol`: the step
\* answers by the page's rule and the name compares that answer with the truth. A step reads
\* the world, never the rule it is checked against. The leg's run reads every record and
\* every intent at once: each record's decision reads only that record and the intents of
\* its keys, so one read stands for the record-by-record reads of Reconciliation 6 and 15.
\*
\* NOT MODELLED (named)
\* - Recoverable Invocation's mechanism and its own invariants (one writer per act, the
\*   recovery intent before a recovered outcome, the recovery flag, the service identity's
\*   attestation, the closure window): recoverable-invocation.tla, inherited here.
\* - The clock and its edges: the young record and the aged record (Reconciliation 4, Term
\*   young record, Term aged record), the sweep's examine edge and horizon edge, the
\*   settling period, the sweep cadence (Reconciliation 2, 39). A commit landing after its
\*   invocation yielded (Recoverable Invocation's stall) is not modelled; the operator's
\*   abandonment over a landed write stands for it.
\* - The pre-commit arms other than already-granted and already-revoked (a storage failure,
\*   an invalid request, a placement refusal): each writes the refusal record and leaves the
\*   Consent record as the already-* arm does. The index-anomaly finding (Action wiring 40).
\* - The Permissions scopes, the retention policy, the Consent expiry, the field caps and
\*   the envelope, the key entries' rebuild beyond "after a grant event", the credential at a
\*   bound action's intent (Recoverable Invocation Invariant 1.1), and the actor match of the
\*   two probes (one actor here).
\* - A repeat registration records an event and changes no binding (Action wiring 22,
\*   Composition state 5): the model takes a pair registered once. A registration refused
\*   writes nothing and is no step.
\* - The derivation's binding repair (Action wiring 31) and the leg's (Reconciliation 22,
\*   23) are the `Bind` step, which writes a missing binding for any landed registration.
\*   The derivation is taken at the close: it reads the registration events preceding its
\*   intent's position, whenever it runs.
EXTENDS Naturals, FiniteSets

CONSTANTS NC, Qs, C1, N, MaxDirect

Cs == 1..NC
Is == 1..N
Perms == {"ok", "denied"}
Creds == {"ok", "bad"}
Kinds == {"grant", "wd"}
OpenSt == {"live", "committed", "dead"}
MaxT == N + MaxDirect
MaxPos == Cardinality(Qs) + N + NC + MaxDirect

VARIABLES
    cs, gAt, rAt, gBy, rBy, rpos, ret,          \* the Consent records and their retention
    idx, bind, regPos, re,                      \* the indexes and the registration events
    hst, hEv, hAns,                             \* the history read
    ik, ic, inow, ipos, ip, iw, st, cw, oset, cby,   \* the bound invocations
    nx, clk, pos, nd,                           \* the next slot, the clock, the log, direct writes
    viol
vars == <<cs, gAt, rAt, gBy, rBy, rpos, ret, idx, bind, regPos, re, hst, hEv, hAns,
          ik, ic, inow, ipos, ip, iw, st, cw, oset, cby, nx, clk, pos, nd, viol>>

consent == <<cs, gAt, rAt, gBy, rBy, rpos, ret>>
regs == <<idx, bind, regPos, re>>
hist == <<hst, hEv, hAns>>
inv == <<ik, ic, inow, ipos, ip, iw, st, cw, oset, cby>>
ctr == <<nx, clk, pos, nd>>

\* The Consent records in Granted: the consent check for the one subject reference and
\* purpose answers granted exactly when there is one.
Granted == {c \in Cs : cs[c] = "granted"}

\* The registered set at a boundary: the pairs whose registration event precedes it in the
\* Event Log (Term registered set). Registrations bind C1 only.
RegAt(c, b) == IF c = C1 THEN {q \in Qs : regPos[q] # 0 /\ regPos[q] < b} ELSE {}

\* The derivation, the invocation's and the withdrawal probe's (Action wiring 28 to 30, Term
\* withdrawal probe): the registration events preceding the boundary that the log still holds,
\* with the purged downstream entries whose event's surviving sequence number precedes it
\* (Check 4.2), never a live entry alone.
DeriveSet(c, b) ==
    IF c = C1
    THEN {q \in Qs : regPos[q] # 0 /\ regPos[q] < b /\ (re[q] = 1 \/ (re[q] = 2 /\ bind[q]))}
    ELSE {}

\* A grant event names the consent id: the close's, the sweep's or an operator's.
GrantEvent(c) == \E i \in Is : ik[i] = "grant" /\ st[i] = "closed" /\ ic[i] = c

\* The act key's open intent: [Open] refuses act-in-flight while one stands.
OpenOn(k, c) == \E j \in Is : ik[j] = k /\ st[j] \in OpenSt /\ (k = "wd" => ic[j] = c)

\* The next consent id a grant mints.
Unused == {c \in Cs : cs[c] = "none"}
NextId == CHOOSE c \in Unused : \A d \in Unused : c <= d

\* An intent of the grant key carries the record's grant instant; one of the consent id
\* carries its revocation instant (Invariant 5.1).
GrantCarried(c) == \E i \in Is : ik[i] = "grant" /\ iw[i] /\ inow[i] = gAt[c]
WdCarried(c) == \E i \in Is : ik[i] = "wd" /\ iw[i] /\ ic[i] = c /\ inow[i] = rAt[c]

\* --- the write-ownership leg's reading (Reconciliation 11, 16, 40, 41) ---
\* A finding where no intent of the record's key carries its pairing datum.
LegFindsG(c) ==
    cs[c] # "none" /\ ~(\E i \in Is : ik[i] = "grant" /\ iw[i] /\ inow[i] = gAt[c])
LegFindsW(c) ==
    cs[c] = "revoked" /\ ~(\E i \in Is : ik[i] = "wd" /\ iw[i] /\ ic[i] = c /\ inow[i] = rAt[c])
\* A Consent record beside an intent of its key and pairing datum closed by an abandonment
\* or a refusal (Term false closing).
LegAlerts(c) ==
    \/ /\ cs[c] = "revoked"
       /\ \E i \in Is : ik[i] = "wd" /\ iw[i] /\ ic[i] = c /\ inow[i] = rAt[c]
                        /\ st[i] \in {"abandoned", "refused"}
    \/ /\ cs[c] # "none"
       /\ \E i \in Is : ik[i] = "grant" /\ iw[i] /\ inow[i] = gAt[c]
                        /\ st[i] \in {"abandoned", "refused"}

\* --- the truth the leg's answers are compared with ---
\* A record a write outside every invocation made (Term write-ownership finding).
OwnerlessG(c) == cs[c] # "none" /\ gBy[c] = 0
OwnerlessW(c) == cs[c] = "revoked" /\ rBy[c] = 0
\* A record whose own invocation's intent was closed by an abandonment or a refusal.
FalselyClosed(c) ==
    \/ cs[c] = "revoked" /\ rBy[c] # 0 /\ st[rBy[c]] \in {"abandoned", "refused"}
    \/ cs[c] # "none" /\ gBy[c] # 0 /\ st[gBy[c]] \in {"abandoned", "refused"}

TypeOK ==
    /\ cs \in [Cs -> {"none", "granted", "revoked"}]
    /\ gAt \in [Cs -> 0..MaxT]
    /\ rAt \in [Cs -> 0..MaxT]
    /\ gBy \in [Cs -> 0..N]
    /\ rBy \in [Cs -> 0..N]
    /\ rpos \in [Cs -> 0..MaxPos]
    /\ ret \in [Cs -> BOOLEAN]
    /\ idx \in [Cs -> BOOLEAN]
    /\ bind \in [Qs -> BOOLEAN]
    /\ regPos \in [Qs -> 0..MaxPos]
    /\ re \in [Qs -> 0..2]
    /\ hst \in {"none", "answered", "denied", "bad", "failed"}
    /\ hEv \in 0..1
    /\ hAns \in 0..1
    /\ ik \in [Is -> Kinds \cup {"-"}]
    /\ ic \in [Is -> 0..NC]
    /\ inow \in [Is -> 0..MaxT]
    /\ ipos \in [Is -> 0..MaxPos]
    /\ ip \in [Is -> Perms]
    /\ iw \in [Is -> BOOLEAN]
    /\ st \in [Is -> {"none", "live", "committed", "dead", "closed", "refused",
                      "escalated", "abandoned"}]
    /\ cw \in [Is -> BOOLEAN]
    /\ oset \in [Is -> SUBSET Qs]
    /\ cby \in [Is -> {"-", "inv", "sweep", "op"}]
    /\ nx \in 1..(N + 1)
    /\ clk \in 0..MaxT
    /\ pos \in 0..MaxPos
    /\ nd \in 0..MaxDirect
    /\ viol \subseteq {"gate-disagrees", "denied-write", "reg-bad-credential", "unbind",
                       "finding-false", "finding-missed", "alert-wrong"}

Init ==
    /\ cs = [c \in Cs |-> "none"]
    /\ gAt = [c \in Cs |-> 0]
    /\ rAt = [c \in Cs |-> 0]
    /\ gBy = [c \in Cs |-> 0]
    /\ rBy = [c \in Cs |-> 0]
    /\ rpos = [c \in Cs |-> 0]
    /\ ret = [c \in Cs |-> FALSE]
    /\ idx = [c \in Cs |-> FALSE]
    /\ bind = [q \in Qs |-> FALSE]
    /\ regPos = [q \in Qs |-> 0]
    /\ re = [q \in Qs |-> 0]
    /\ hst = "none"
    /\ hEv = 0
    /\ hAns = 0
    /\ ik = [i \in Is |-> "-"]
    /\ ic = [i \in Is |-> 0]
    /\ inow = [i \in Is |-> 0]
    /\ ipos = [i \in Is |-> 0]
    /\ ip = [i \in Is |-> "ok"]
    /\ iw = [i \in Is |-> FALSE]
    /\ st = [i \in Is |-> "none"]
    /\ cw = [i \in Is |-> FALSE]
    /\ oset = [i \in Is |-> {}]
    /\ cby = [i \in Is |-> "-"]
    /\ nx = 1
    /\ clk = 0
    /\ pos = 0
    /\ nd = 0
    /\ viol = {}

\* ---------------------------------------------------------------------------------------
\* The bound actions: validate, open, commit, close (Action wiring 4, 32; Recoverable
\* Invocation Action wiring 4).

\* The pairing datum the host injects: a fresh now (Capability requirement 27, 38).
Nows(k, c) == {clk + 1}

\* [Open]: the permission check answered permitted and Primitive policy passed (Action
\* wiring 1 to 3), the subject index resolves a withdrawal's consent id (Primitive policy 5),
\* and no intent of the act key stands open; the intent lands, verifying the credential, and
\* carries the now as the pairing datum (Action wiring 4, 32). A withdrawal intent takes its
\* position in the Event Log: the boundary of its propagation set.
OpenAct(k, c, p, t) ==
    LET i == nx IN
    /\ i <= N
    /\ p = "ok"
    /\ ~OpenOn(k, c)
    /\ (k = "wd") => idx[c]
    /\ (k = "grant") => c = 1
    /\ ik' = [ik EXCEPT ![i] = k]
    /\ ic' = [ic EXCEPT ![i] = IF k = "wd" THEN c ELSE 0]
    /\ inow' = [inow EXCEPT ![i] = t]
    /\ clk' = IF t > clk THEN t ELSE clk
    /\ ipos' = [ipos EXCEPT ![i] = IF k = "wd" THEN pos + 1 ELSE 0]
    /\ pos' = IF k = "wd" THEN pos + 1 ELSE pos
    /\ ip' = [ip EXCEPT ![i] = p]
    /\ iw' = [iw EXCEPT ![i] = TRUE]
    /\ st' = [st EXCEPT ![i] = "live"]
    /\ nx' = i + 1
    /\ UNCHANGED <<cw, oset, cby, nd>>
    /\ UNCHANGED <<consent, regs, hist, viol>>

\* The withdrawal's commit: the revoke write with the intent's revocation instant (Action
\* wiring 34 to 39, 60). Revoked answers committed; already-revoked is pre-commit, the
\* refusal record kept (Recoverable Invocation commit 2, 3); an unknown arm yields, the revoke
\* written or not.
CommitWd(i, a) ==
    LET c == ic[i] IN
    /\ ik[i] = "wd"
    /\ st[i] = "live"
    /\ \/ /\ cs[c] = "granted"
          /\ a \in {"committed", "unk-done"}
          /\ cs' = [cs EXCEPT ![c] = "revoked"]
          /\ rAt' = [rAt EXCEPT ![c] = inow[i]]
          /\ rBy' = [rBy EXCEPT ![c] = i]
          /\ rpos' = [rpos EXCEPT ![c] = pos + 1]
          /\ pos' = pos + 1
          /\ cw' = [cw EXCEPT ![i] = TRUE]
          /\ st' = [st EXCEPT ![i] = IF a = "committed" THEN "committed" ELSE "dead"]
          /\ viol' = viol \cup (IF ip[i] = "denied" THEN {"denied-write"} ELSE {})
          /\ UNCHANGED <<gAt, gBy, ret>>
       \/ /\ cs[c] = "revoked"
          /\ a = "already"
          /\ st' = [st EXCEPT ![i] = "refused"]
          /\ UNCHANGED <<consent, pos, cw, viol>>
       \/ /\ a = "unk-none"
          /\ st' = [st EXCEPT ![i] = "dead"]
          /\ UNCHANGED <<consent, pos, cw, viol>>
    /\ UNCHANGED <<ik, ic, inow, ipos, ip, iw, oset, cby>>
    /\ UNCHANGED <<regs, hist, nx, clk, nd>>

\* The grant's commit: the grant transaction, the consent check, the grant write stamping the
\* injected now and the retention placement, committed together or not at all (Action wiring
\* 7 to 14, 58, 59; Term grant transaction; Capability requirement 37). Already-granted is
\* pre-commit, the transaction rolled back and the refusal record kept.
CommitGrant(i, a) ==
    LET c == NextId IN
    /\ ik[i] = "grant"
    /\ st[i] = "live"
    /\ \/ /\ Granted = {}
          /\ Unused # {}
          /\ a \in {"committed", "unk-done"}
          /\ cs' = [cs EXCEPT ![c] = "granted"]
          /\ gAt' = [gAt EXCEPT ![c] = inow[i]]
          /\ gBy' = [gBy EXCEPT ![c] = i]
          /\ ret' = [ret EXCEPT ![c] = TRUE]
          /\ ic' = [ic EXCEPT ![i] = c]
          /\ cw' = [cw EXCEPT ![i] = TRUE]
          /\ st' = [st EXCEPT ![i] = IF a = "committed" THEN "committed" ELSE "dead"]
          /\ viol' = viol \cup (IF ip[i] = "denied" THEN {"denied-write"} ELSE {})
          /\ UNCHANGED <<rAt, rBy, rpos>>
       \/ /\ Granted # {}
          /\ a = "already"
          /\ st' = [st EXCEPT ![i] = "refused"]
          /\ UNCHANGED <<consent, ic, cw, viol>>
       \/ /\ a = "unk-none"
          /\ st' = [st EXCEPT ![i] = "dead"]
          /\ UNCHANGED <<consent, ic, cw, viol>>
    /\ UNCHANGED <<ik, inow, ipos, ip, iw, oset, cby>>
    /\ UNCHANGED <<regs, hist, ctr>>

\* [Close] after a committed arm: the grant event naming the consent id, or the propagation
\* event carrying the set the withdrawal derives (Action wiring 17, 28 to 30, 41; Wiring
\* decision 1). It may fail (recording-failure carrying outcome) or the invocation may die
\* first: the intent stays open for the sweep (Action wiring 61; Cross-record consistency 1,
\* 2).
Close(i, o) ==
    /\ st[i] = "committed"
    /\ \/ /\ o = "ok"
          /\ st' = [st EXCEPT ![i] = "closed"]
          /\ cby' = [cby EXCEPT ![i] = "inv"]
          /\ oset' = [oset EXCEPT ![i] = IF ik[i] = "wd" THEN DeriveSet(ic[i], ipos[i])
                                                         ELSE {}]
       \/ /\ o = "fail"
          /\ st' = [st EXCEPT ![i] = "dead"]
          /\ UNCHANGED <<cby, oset>>
    /\ UNCHANGED <<ik, ic, inow, ipos, ip, iw, cw>>
    /\ UNCHANGED <<consent, regs, hist, ctr, viol>>

\* ---------------------------------------------------------------------------------------
\* Recoverable Invocation's sweep and the operator's resolve, as contracts.

\* The withdrawal probe: Consent's read by the consent id at the intent's revocation instant
\* answers committed where the record is Revoked at that instant, carrying the set derived at
\* the intent's own position; not-committed otherwise (Term withdrawal probe).
WdProbeSet(i) == DeriveSet(ic[i], ipos[i])

\* The grant probe: Consent's read by the subject reference, the purpose and the grant
\* instant of the intent's pairing datum: one match committed, none not-committed, several
\* undecidable (Term grant probe).
GrantMatches(i) == {c \in Cs : cs[c] # "none" /\ gAt[c] = inow[i]}

Sweep(i) ==
    /\ st[i] = "dead"
    /\ \/ /\ ik[i] = "wd"
          /\ IF cs[ic[i]] = "revoked" /\ rAt[ic[i]] = inow[i]
             THEN /\ st' = [st EXCEPT ![i] = "closed"]
                  /\ cby' = [cby EXCEPT ![i] = "sweep"]
                  /\ oset' = [oset EXCEPT ![i] = WdProbeSet(i)]
                  /\ UNCHANGED ic
             ELSE /\ st' = [st EXCEPT ![i] = "escalated"]
                  /\ UNCHANGED <<cby, oset, ic>>
       \/ /\ ik[i] = "grant"
          /\ IF Cardinality(GrantMatches(i)) = 1
             THEN /\ st' = [st EXCEPT ![i] = "closed"]
                  /\ cby' = [cby EXCEPT ![i] = "sweep"]
                  /\ ic' = [ic EXCEPT ![i] = CHOOSE c \in GrantMatches(i) : TRUE]
                  /\ UNCHANGED oset
             ELSE /\ st' = [st EXCEPT ![i] = "escalated"]
                  /\ UNCHANGED <<cby, oset, ic>>
    /\ UNCHANGED <<ik, inow, ipos, ip, iw, cw>>
    /\ UNCHANGED <<consent, regs, hist, ctr, viol>>

\* The operator's resolve: an outcome whose data the operator supplies, or an abandonment; an
\* abandonment is superseded only by an outcome (resolve 14 to 16, 21, 32). The outcome's
\* consent id is any record's, for a grant (the operator's own probe run may be wrong); a
\* withdrawal's carries the set the operator's probe run derives, since no check reads an
\* operator's set (Invariant 3.3 is detected, not prevented, for it: Check 3.2).
Resolve(i, d, c) ==
    /\ \/ /\ d = "abandon"
          /\ st[i] \in {"dead", "escalated"}
          /\ st' = [st EXCEPT ![i] = "abandoned"]
          /\ cby' = [cby EXCEPT ![i] = "op"]
          /\ UNCHANGED <<ic, oset>>
       \/ /\ d = "outcome"
          /\ st[i] \in {"dead", "escalated", "abandoned"}
          /\ st' = [st EXCEPT ![i] = "closed"]
          /\ cby' = [cby EXCEPT ![i] = "op"]
          /\ IF ik[i] = "wd"
             THEN /\ oset' = [oset EXCEPT ![i] = WdProbeSet(i)]
                  /\ UNCHANGED ic
             ELSE /\ cs[c] # "none"
                  /\ ic' = [ic EXCEPT ![i] = c]
                  /\ UNCHANGED oset
    /\ UNCHANGED <<ik, inow, ipos, ip, iw, cw>>
    /\ UNCHANGED <<consent, regs, hist, ctr, viol>>

\* ---------------------------------------------------------------------------------------
\* A write outside any invocation, against the reserved surface (Composes 11, 12): a grant
\* or a revoke, stamped from the same clock, with no intent, no event and no placement.
DirectGrant ==
    LET c == NextId IN
    /\ nd < MaxDirect
    /\ Unused # {}
    /\ cs' = [cs EXCEPT ![c] = "granted"]
    /\ gAt' = [gAt EXCEPT ![c] = clk + 1]
    /\ clk' = clk + 1
    /\ nd' = nd + 1
    /\ UNCHANGED <<rAt, gBy, rBy, rpos, ret, nx, pos>>
    /\ UNCHANGED <<regs, hist, inv, viol>>

DirectRevoke(c) ==
    /\ nd < MaxDirect
    /\ cs[c] = "granted"
    /\ cs' = [cs EXCEPT ![c] = "revoked"]
    /\ rAt' = [rAt EXCEPT ![c] = clk + 1]
    /\ rpos' = [rpos EXCEPT ![c] = pos + 1]
    /\ clk' = clk + 1
    /\ pos' = pos + 1
    /\ nd' = nd + 1
    /\ UNCHANGED <<gAt, gBy, rBy, ret, nx>>
    /\ UNCHANGED <<regs, hist, inv, viol>>

\* ---------------------------------------------------------------------------------------
\* The unbound actions, one transaction each, and the indexes outside every transaction.

\* [Register Processing], for a consent the subject index resolves (Primitive policy 5) and
\* a pair not yet registered: the registration event lands, Audit Trail validating the
\* caller's credential there (Action wiring 21, Invariant 8.3), and takes its position in the
\* Event Log. A call whose credential does not validate, or whose event is refused, writes
\* nothing and is no step.
Register(q, cr, landed) ==
    /\ idx[C1]
    /\ regPos[q] = 0
    /\ cr = "ok"
    /\ landed
    /\ regPos' = [regPos EXCEPT ![q] = pos + 1]
    /\ re' = [re EXCEPT ![q] = 1]
    /\ pos' = pos + 1
    /\ viol' = viol \cup (IF cr = "bad" THEN {"reg-bad-credential"} ELSE {})
    /\ UNCHANGED <<idx, bind>>
    /\ UNCHANGED <<consent, hist, inv, nx, clk, nd>>

\* The downstream entry, outside every transaction: written only after the registration event
\* lands (Action wiring 25); the same write repairs a binding a crash lost (Action wiring 31,
\* Reconciliation 22, 23).
Bind(q) ==
    /\ regPos[q] # 0
    /\ ~bind[q]
    /\ bind' = [bind EXCEPT ![q] = TRUE]
    /\ UNCHANGED <<idx, regPos, re>>
    /\ UNCHANGED <<consent, hist, inv, ctr, viol>>

\* The audit horizon destroys a registration event's payload once its binding stands; the
\* downstream entry then carries the pair on its own (Composition state 13, 14, 16, 18).
Purge(q) ==
    /\ re[q] = 1
    /\ bind[q]
    /\ re' = [re EXCEPT ![q] = 2]
    /\ UNCHANGED <<idx, bind, regPos>>
    /\ UNCHANGED <<consent, hist, inv, ctr, viol>>

\* The key entries, outside every transaction: written only after a grant event names the
\* consent id, the close's, the sweep's or an operator's (Action wiring 18, 24; Term grant
\* rebuild).
Index(c) ==
    /\ ~idx[c]
    /\ GrantEvent(c)
    /\ idx' = [idx EXCEPT ![c] = TRUE]
    /\ UNCHANGED <<bind, regPos, re>>
    /\ UNCHANGED <<consent, hist, inv, ctr, viol>>

\* [Read Consent History], one transaction, taken first (BOUND): a call the permission check
\* denies, or whose credential does not validate, is refused with nothing written; otherwise
\* the access event lands, Audit Trail validating the credential there, before the history is
\* answered, or is refused and nothing is answered (Action wiring 50 to 52).
History(p, cr, landed) ==
    /\ hst = "none"
    /\ nx = 1 /\ nd = 0 /\ pos = 0
    /\ hst' = IF p = "denied" THEN "denied"
              ELSE IF cr = "bad" THEN "bad"
              ELSE IF landed THEN "answered" ELSE "failed"
    /\ hEv' = IF p = "ok" /\ cr = "ok" /\ landed THEN 1 ELSE 0
    /\ hAns' = IF p = "ok" /\ cr = "ok" /\ landed THEN 1 ELSE 0
    /\ UNCHANGED <<consent, regs, inv, ctr, viol>>

\* The gate: [Processing Permitted] answers permitted exactly when the consent check answers
\* granted, and writes nothing (Action wiring 53 to 57).
Gate ==
    /\ viol' = viol \cup (IF (IF Granted # {} THEN "permitted" ELSE "not-permitted")
                                 # (IF Granted # {} THEN "permitted" ELSE "not-permitted")
                          THEN {"gate-disagrees"} ELSE {})
    /\ UNCHANGED <<consent, regs, hist, inv, ctr>>

\* ---------------------------------------------------------------------------------------
\* The write-ownership leg (Reconciliation 6, 11, 15, 16, 40, 41): every Consent record read
\* against the intents of its keys, on an answered read (Reconciliation 38). It opens a
\* finding and alerts by the page's rule; the names it adds compare the rule's answer with
\* what the records hold.
LegRun ==
    LET fG == {c \in Cs : LegFindsG(c)}
        fW == {c \in Cs : LegFindsW(c)}
        al == {c \in Cs : LegAlerts(c)}
    IN viol' = viol
         \cup (IF \E c \in fG : ~OwnerlessG(c) THEN {"finding-false"} ELSE {})
         \cup (IF \E c \in fW : ~OwnerlessW(c) THEN {"finding-false"} ELSE {})
         \cup (IF \E c \in Cs : OwnerlessG(c) /\ c \notin fG THEN {"finding-missed"} ELSE {})
         \cup (IF \E c \in Cs : OwnerlessW(c) /\ c \notin fW THEN {"finding-missed"} ELSE {})
         \cup (IF \E c \in Cs : (c \in al) # FalselyClosed(c) THEN {"alert-wrong"} ELSE {})
    /\ UNCHANGED <<consent, regs, hist, inv, ctr>>

Next ==
    \/ \E k \in Kinds, c \in Cs, p \in Perms : \E t \in Nows(k, c) : OpenAct(k, c, p, t)
    \/ \E i \in Is, a \in {"committed", "already", "unk-done", "unk-none"} :
           CommitWd(i, a) \/ CommitGrant(i, a)
    \/ \E i \in Is, o \in {"ok", "fail"} : Close(i, o)
    \/ \E i \in Is : Sweep(i)
    \/ \E i \in Is, d \in {"abandon", "outcome"}, c \in Cs : Resolve(i, d, c)
    \/ DirectGrant
    \/ \E c \in Cs : DirectRevoke(c)
    \/ \E q \in Qs, cr \in Creds, l \in BOOLEAN : Register(q, cr, l)
    \/ \E q \in Qs : Bind(q)
    \/ \E q \in Qs : Purge(q)
    \/ \E c \in Cs : Index(c)
    \/ \E p \in Perms, cr \in Creds, l \in BOOLEAN : History(p, cr, l)
    \/ Gate
    \/ LegRun
Spec == Init /\ [][Next]_vars

\* --- composition-level safety invariants ---

\* Invariant 1.1: the gate answers permitted only if the consent check answers granted.
Invariant_1_1 == ~("gate-disagrees" \in viol)

\* Invariant 1.3: two governed consents in Granted never carry one subject reference and
\* purpose. A record a write outside any invocation made is no governed consent (Term
\* governed consent); the write-ownership finding is what names it.
Invariant_1_3 == Cardinality({c \in Granted : gBy[c] # 0}) <= 1

\* Invariant 3.1, with Wiring decision 1: every propagation event the invocation or the sweep
\* wrote names a consent the Consent records hold in Revoked. An operator's is detected, not
\* prevented (Invariant 3 NOTE, Check 3.10).
Invariant_3_1 ==
    \A i \in Is : (ik[i] = "wd" /\ st[i] = "closed" /\ cby[i] # "op") => cs[ic[i]] = "revoked"

\* Invariant 3.2: two propagation events carrying one consent id are never both the
\* invocation's or the sweep's: a second is an operator's, which Check 3.1 detects.
Invariant_3_2 ==
    \A i, j \in Is :
        (i # j /\ ik[i] = "wd" /\ ik[j] = "wd" /\ st[i] = "closed" /\ st[j] = "closed"
         /\ ic[i] = ic[j]) => (cby[i] = "op" \/ cby[j] = "op")

\* Invariant 3.3: a propagation event's set equals the registered set at the event's
\* boundary, the position of its own intent (Term event's boundary). An operator's is
\* detected, not prevented (Check 3.2).
Invariant_3_3 ==
    \A i \in Is : (ik[i] = "wd" /\ st[i] = "closed" /\ cby[i] # "op")
                     => oset[i] = RegAt(ic[i], ipos[i])

\* Invariant 4.1: every binding carries a registration event carrying its pair.
Invariant_4_1 == \A q \in Qs : bind[q] => regPos[q] # 0

\* Invariant 5.1: the lifecycle resolves from the records: a governed record is carried by
\* the intent of its own grant, a Revoked one an invocation revoked by its withdrawal intent,
\* and every history answered has its access event.
Invariant_5_1 ==
    /\ \A c \in Cs : gBy[c] # 0 => GrantCarried(c)
    /\ \A c \in Cs : (cs[c] = "revoked" /\ rBy[c] # 0) => WdCarried(c)
    /\ hAns <= hEv

\* Invariant 6.1: every governed consent carries its consent retention.
Invariant_6_1 == \A c \in Cs : gBy[c] # 0 => ret[c]

\* Invariant 7.1: no constituent write for an actor the permission check denied.
Invariant_7_1 == ~("denied-write" \in viol)

\* Invariant 8.3, 8.4: no binding and no history answer before Audit Trail validates the
\* caller's credential.
Invariant_8_3 == ~("reg-bad-credential" \in viol)
Invariant_8_4 == hAns <= hEv

\* Action wiring 4, 17, 32, 41, Wiring decision 1: a commit follows its intent, and the
\* invocation's close follows its commit.
Action_wiring_order ==
    \A i \in Is : /\ cw[i] => iw[i]
                  /\ (st[i] = "closed" /\ cby[i] = "inv") => cw[i]

\* Action wiring 24: an index entry is written only after a grant event names its consent id.
Action_wiring_24 == \A c \in Cs : idx[c] => GrantEvent(c)

\* Composition state 6: a binding is never removed.
Composition_state_6 == ~("unbind" \in viol)

\* Composition state 13, 14: a purged registration event always has the downstream entry
\* that carries its pair.
Composition_state_13 == \A q \in Qs : (re[q] = 2) => bind[q]

\* Owed outcome (Recoverable Invocation Invariant 4.1's shape; Cross-record consistency 1,
\* 2): an invocation whose commit wrote stands open or beside a closing, never a refusal.
Owed_outcome ==
    \A i \in Is : cw[i] => st[i] \in {"committed", "dead", "closed", "escalated", "abandoned"}

\* The sweep's recovered propagation event carries the set derived at its intent's own
\* position, never at the sweep's now (Term withdrawal probe; Recoverable Invocation act
\* probe 6; Cross-record consistency 3).
Recovered_set_at_intent ==
    \A i \in Is : (ik[i] = "wd" /\ st[i] = "closed" /\ cby[i] = "sweep")
                     => oset[i] = RegAt(ic[i], ipos[i])

\* The probe answers committed only for the intent whose own commit wrote the record
\* (Capability requirement 37, 38; Recoverable Invocation pairing datum 2, 4).
Pairing_unique ==
    \A i \in Is : (st[i] = "closed" /\ cby[i] = "sweep")
                     => IF ik[i] = "wd" THEN rBy[ic[i]] = i ELSE gBy[ic[i]] = i

\* Reconciliation 11, 16: the leg opens a write-ownership finding for every record a write
\* outside every invocation made, and for no other.
Write_ownership_finding == ~("finding-false" \in viol) /\ ~("finding-missed" \in viol)

\* Reconciliation 40, 41: the leg alerts exactly the records whose own intent an abandonment
\* or a refusal closed.
False_closing_alert == ~("alert-wrong" \in viol)

\* Reachability probe: the correct model, this one invariant added, which the checker must find false.
Probe_second == ~(\E i, j \in Is : i # j /\ ik[i] = "wd" /\ ik[j] = "wd" /\ st[i] = "closed" /\ st[j] = "closed" /\ ic[i] = ic[j])

====
