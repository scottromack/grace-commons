---- MODULE propagate-consent-revocation-downstream-reconciliation-escalate-twice-buggy ----
\* BUGGY TWIN (escalate-twice): The reconciliation records a second escalation for one record (Reconciliation 33). The checker must reject it. Everything else is the correct model.
\* Grace Commons — Propagate Consent Revocation Downstream, the reconciliation.
\* Spec-level formal sibling of compositions/propagate-consent-revocation-downstream.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-09 (the first model, 2026-08-27, checked a single-writer invocation with
\* no terminus; the page has since moved onto the Database contract, under which an invocation
\* is one transaction and retries nothing, so the invocation and the scan are no longer two
\* processes over one act). What the page keeps is a withdrawal or a grant whose outcome the
\* audit write refused, an answer and not a refusal (Audit arm 12, 15, 17): the Consent record
\* is committed and its event is owed. This model is the reconciliation that owes the event its
\* closure, and the clock the closure is measured against. The acts themselves (the gate, the
\* registered set, the order inside each action, the three indexes) are its sibling,
\* propagate-consent-revocation-downstream.tla.
\*
\* WHAT THIS MODEL CHECKS
\* One Consent record, a revoked one whose propagation event is owed (kind P) or a Granted one
\* whose grant event is owed (kind G), and a reconciliation that must run every cadence, land its
\* writes within the run bound, and close what it finds:
\*   - Invariant 2.1      a Consent record whose grant instant plus the widened window precedes now
\*                        carries a grant closure (a grant event, or an escalation of kind grant).
\*   - Invariant 3.5      a paired unpropagated record whose revocation instant plus the widened
\*                        window precedes now carries a propagation closure.
\*   - Invariant 3.2      two propagation events never carry one consent id.
\*   - Invariant 3.3      a propagation event's set equals the registered set at the event's
\*                        boundary, the compensating event's at the earliest candidate's.
\*   - Invariant 3.6      every compensating event carries the recovery flag; Check 3.6 adds that
\*                        a recovery intent comes first.
\*   - Check 3.4          a record the reconciliation escalated names no propagation event.
\*   - Reconciliation 9, 12, 12a, 13, 16, 20, 21, 24, 28, 29, 30, 32, 33   the steps of one run.
\*
\* BOUND
\* Time is a counter, now in 0..T. W = 5 exceeds the liveness sum A + K + R = 4 (Capability
\* requirement 10), the horizon H = 10 exceeds the escalation reach W + K + R = 8 (Capability
\* requirement 34) and the widened window 9, so an Invariant's antecedent is reachable before the
\* record ages. Two pairs q1 and q2 the registrations may bind, and a fault budget of Fb(kind)
\* refusals for the record's compensation: kind P's budget runs past the escalation instant, the
\* only way the late escalation (Reconciliation 30) fires; kind G's covers one refusal and its retry.
\*
\* HOW A RUN IS READ
\* A run takes its now once, at its own seam (Capability requirement 29), starts at least every
\* cadence (Reconciliation 2) and lands its writes within the run bound (Term reconciliation run
\* bound): the model ticks only while a run is within the bound and the next is not overdue. A
\* record's reads and the writes they decide are one transaction (Execution Contract Database 2),
\* so the record is processed in one step, deciding on the run's now and the state as it stands
\* then, anywhere from the run's start to the run bound later. A property of a step (a compensation
\* of a record the page forbids, an escalation before its instant) is a name the step adds to `viol`;
\* the named invariants say `viol` does not hold their name. A step reads the world, never the rule
\* it is checked against.
\*
\* SCOPE (named)
\* - The audit write answers landed or recording-failure. An invalid-request carrying step-1, 2
\*   or 3 is a deployment fault the reconciliation never retries (Audit arm 4, 9), and the
\*   escalation's own write is taken to land at its first attempt: Reconciliation 34 retries a
\*   refused one at the next run, which lands the closure one run after the escalation reach,
\*   past the widened window. That is the page's open line 2026-11-09-c, and the probe
\*   propagate-consent-revocation-downstream-reconciliation-probe-escalation-refused shows it.
\* - Pairing: a record's candidate count is the environment's (0 none, 1 one, 2 several within the
\*   intent candidates cap, 3 over it). That the pairing window holds a pairing's two stamps is
\*   arithmetic (Term pairing window), not a behavior.
\* - A recovery intent refused with recording-failure counts as the compensation meeting a
\*   refusal, and the next run retries it while the orphan is under compensation: the closure
\*   table's reading of Reconciliation 2, 24 and 30, which Reconciliation 28 itself does not state
\*   (open line 2026-11-09-e).
\* - The seam clocks: the composition, Consent and the substrate read one now here. The skew
\*   between seams is the widened window's clock offset allowance, kept as the constant O.
\* - One record at a time: the reconciliation reads every record each run and decides each in its
\*   own transaction, so a second record changes no decision about the first.
EXTENDS Naturals, FiniteSets

CONSTANTS W, K, R, A, O, H, FbP, FbG, MaxSeam, MaxPos, T

\* The pairs a registration binds, the registered set a propagation event carries.
Q == {"q1", "q2"}

\* The refusals the audit write may answer for the record's compensation.
Fb(k) == IF k = "P" THEN FbP ELSE FbG

\* The deployment's windows, as the page defines them: the escalation reach (Term escalation reach)
\* and the widened window (Term widened window).
Reach == W + K + R
Wd == Reach + O

VARIABLES now, since, phase, rn, age, pos, reg,
          kind, st, at, cc, bp, evK, nEv, evSet, flag, ri, candC, idx,
          esc, met, fnd, fault, viol
vars == <<now, since, phase, rn, age, pos, reg,
          kind, st, at, cc, bp, evK, nEv, evSet, flag, ri, candC, idx,
          esc, met, fnd, fault, viol>>

\* The record's escalation instant (Term escalation instant) and whether it has aged out of the
\* audit horizon at the run's now (Term aged record).
Esc == at + W
Aged == at + H < rn

\* The registered set at a boundary: the pairs whose registration event precedes it.
SetAt(b) == {q \in Q : reg[q] # 0 /\ reg[q] < b}

TypeOK ==
    /\ now \in 0..T
    /\ since \in 0..K
    /\ phase \in {"idle", "run"}
    /\ rn \in 0..T
    /\ age \in 0..R
    /\ pos \in 0..MaxPos
    /\ reg \in [Q -> 0..MaxPos]
    /\ kind \in {"none", "P", "G"}
    /\ st \in {"none", "inflight", "orphan", "done"}
    /\ at \in 0..T
    /\ cc \in 0..3
    /\ bp \in 0..MaxPos
    /\ evK \in {"none", "orig", "comp"}
    /\ nEv \in 0..2
    /\ evSet \subseteq Q
    /\ flag \in BOOLEAN
    /\ ri \in BOOLEAN
    /\ candC \in BOOLEAN
    /\ idx \in BOOLEAN
    /\ esc \in 0..2
    /\ met \in BOOLEAN
    /\ fnd \in BOOLEAN
    /\ fault \in 0..FbP
    /\ viol \subseteq {"retry-past-instant", "esc-early", "comp-unpaired", "comp-over-cap",
                       "comp-escalated", "idx-before-event", "esc-twice"}

Init ==
    /\ now = 0
    /\ since = 0
    /\ phase = "idle"
    /\ rn = 0
    /\ age = 0
    /\ pos = 0
    /\ reg = [q \in Q |-> 0]
    /\ kind = "none"
    /\ st = "none"
    /\ at = 0
    /\ cc = 0
    /\ bp = 0
    /\ evK = "none"
    /\ nEv = 0
    /\ evSet = {}
    /\ flag = FALSE
    /\ ri = FALSE
    /\ candC = FALSE
    /\ idx = FALSE
    /\ esc = 0
    /\ met = FALSE
    /\ fnd = FALSE
    /\ fault = 0
    /\ viol = {}

\* Time passes. Never past the last tick a run's writes may land (the run bound), never past the
\* cadence while the reconciliation is idle (Reconciliation 2), and never past the administration
\* completion bound for an invocation that has read its seam and not yet answered.
Tick ==
    /\ now < T
    /\ (phase = "idle") => (since < K)
    /\ (phase = "run") => (age < R)
    /\ (st = "inflight") => (now - at < A)
    /\ now' = now + 1
    /\ since' = IF since < K THEN since + 1 ELSE since
    /\ age' = IF phase = "run" THEN age + 1 ELSE age
    /\ UNCHANGED <<phase, rn, pos, reg, kind, st, at, cc, bp, evK, nEv, evSet, flag, ri,
                   candC, idx, esc, met, fnd, fault, viol>>

\* A registration event lands for a pair, taking the next position in the Event Log.
Register(q) ==
    /\ reg[q] = 0
    /\ pos < MaxPos
    /\ pos' = pos + 1
    /\ reg' = [reg EXCEPT ![q] = pos + 1]
    /\ UNCHANGED <<now, since, phase, rn, age, kind, st, at, cc, bp, evK, nEv, evSet, flag, ri,
                   candC, idx, esc, met, fnd, fault, viol>>

\* An invocation reads its seam: the instant the record will carry (the grant instant, the
\* revocation instant).
Begin(k) ==
    /\ st = "none"
    /\ now <= MaxSeam
    /\ kind' = k
    /\ st' = "inflight"
    /\ at' = now
    /\ UNCHANGED <<now, since, phase, rn, age, pos, reg, cc, bp, evK, nEv, evSet, flag, ri,
                   candC, idx, esc, met, fnd, fault, viol>>

\* The invocation's transaction commits with its event: the clean arm. The event's set is the
\* registered set as the intent's transaction read it (Action wiring 28, 29).
CommitClean ==
    /\ st = "inflight"
    /\ pos < MaxPos
    /\ pos' = pos + 1
    /\ st' = "done"
    /\ bp' = pos + 1
    /\ evK' = "orig"
    /\ nEv' = 1
    /\ evSet' = IF kind = "P" THEN SetAt(pos + 1) ELSE {}
    /\ cc' = 1
    /\ UNCHANGED <<now, since, phase, rn, age, reg, kind, at, flag, ri, candC, idx,
                   esc, met, fnd, fault, viol>>

\* The invocation's transaction commits with the Consent record and the intent, and the audit
\* write refuses the outcome: recording-failure carrying outcome, an answer and not a refusal
\* (Audit arm 12, 15, 17). The record stands, its event is owed, and c is how many intents
\* Reconciliation 10 or 17 will pair to it. Zero is a direct write against a reserved surface.
CommitOwed(c) ==
    /\ st = "inflight"
    /\ pos < MaxPos
    /\ c \in (IF kind = "P" THEN 0..3 ELSE 0..1)
    /\ pos' = IF c = 0 THEN pos ELSE pos + 1
    /\ st' = "orphan"
    /\ cc' = c
    /\ bp' = IF c = 0 THEN 0 ELSE pos + 1
    /\ UNCHANGED <<now, since, phase, rn, age, reg, kind, at, evK, nEv, evSet, flag, ri, candC,
                   idx, esc, met, fnd, fault, viol>>

\* The reconciliation starts a run: it takes its now once, at its seam, and reads the record.
StartRun ==
    /\ phase = "idle"
    /\ phase' = "run"
    /\ rn' = now
    /\ age' = 0
    /\ since' = 0
    /\ UNCHANGED <<now, pos, reg, kind, st, at, cc, bp, evK, nEv, evSet, flag, ri, candC, idx,
                   esc, met, fnd, fault, viol>>

\* The run has read the record, and ends, zeroing its private fields.
RunEnd ==
    /\ phase' = "idle"
    /\ rn' = 0
    /\ age' = 0

\* A record the run has nothing to do for: it is not an orphan yet, carries its event
\* (Reconciliation 9), is escalated already (Reconciliation 32, 35), or has aged out of the audit
\* horizon (Reconciliation 5, reported as propagation history purged).
ProcSkip ==
    /\ phase = "run"
    /\ \/ st # "orphan"
       \/ esc >= 1
       \/ Aged
    /\ RunEnd
    /\ UNCHANGED <<now, since, pos, reg, kind, st, at, cc, bp, evK, nEv, evSet, flag,
                   ri, candC, idx, esc, met, fnd, fault, viol>>

\* An unpropagated record no intent pairs is a direct write against a reserved surface: the
\* reconciliation opens a write-ownership finding and does not compensate it (Reconciliation 11, 12).
ProcFinding ==
    /\ phase = "run"
    /\ kind = "P"
    /\ st = "orphan"
    /\ esc = 0
    /\ ~Aged
    /\ cc = 0
    /\ RunEnd
    /\ fnd' = TRUE
    /\ UNCHANGED <<now, since, pos, reg, kind, st, at, cc, bp, evK, nEv, evSet, flag,
                   ri, candC, idx, esc, met, fault, viol>>

\* An uncompensable cause holds, so the reconciliation records the escalation at the run that reads
\* the record (Reconciliation 29): an ungranted record no intent pairs is no write-ownership finding
\* (Reconciliation 16), and a record whose candidates pass the cap cannot be named in one event.
ProcEscalateNow ==
    /\ phase = "run"
    /\ st = "orphan"
    /\ ~Aged
    /\ ((kind = "G" /\ cc = 0) \/ cc = 3)
    /\ RunEnd
    /\ esc' = esc + 1
    /\ viol' = viol \cup (IF esc >= 1 THEN {"esc-twice"} ELSE {})
    /\ UNCHANGED <<now, since, pos, reg, kind, st, at, cc, bp, evK, nEv, evSet, flag,
                   ri, candC, idx, met, fnd, fault>>

\* A compensable orphan whose escalation instant precedes the run's now, and whose compensation met
\* a refusal, is escalated carrying the last refusal (Reconciliation 30), once (Reconciliation 33).
ProcEscalateLate ==
    /\ phase = "run"
    /\ st = "orphan"
    /\ esc = 0
    /\ ~Aged
    /\ cc \in {1, 2}
    /\ met
    /\ Esc < rn
    /\ RunEnd
    /\ esc' = esc + 1
    /\ viol' = viol \cup (IF esc >= 1 THEN {"esc-twice"} ELSE {})
                       \cup (IF ~(met /\ Esc < rn) THEN {"esc-early"} ELSE {})
    /\ UNCHANGED <<now, since, pos, reg, kind, st, at, cc, bp, evK, nEv, evSet, flag,
                   ri, candC, idx, met, fnd, fault>>

\* The compensation, at the run that first reads the orphan and at each later run while the orphan
\* is under compensation (Reconciliation 12a, 28): a recovery intent under the recovery identity,
\* then the compensating event behind it (Reconciliation 24), carrying the recovery flag
\* (Reconciliation 27), the set at the earliest candidate's boundary (Reconciliation 13) and the
\* candidates where more than one pairs (Reconciliation 21). For a grant the index entries follow
\* the compensating event (Reconciliation 20). o is what the audit write answers.
ProcComp(o) ==
    /\ phase = "run"
    /\ st = "orphan"
    /\ esc = 0
    /\ ~Aged
    /\ cc \in {1, 2}
    /\ ~(met /\ Esc < rn)
    /\ o \in {"ok", "evrefused", "intrefused"}
    /\ (o # "intrefused") \/ (~ri)
    /\ (o = "ok") \/ (fault < Fb(kind))
    /\ RunEnd
    /\ ri' = (o # "intrefused")
    /\ met' = IF o = "ok" THEN met ELSE TRUE
    /\ fault' = IF o = "ok" THEN fault ELSE fault + 1
    /\ st' = IF o = "ok" THEN "done" ELSE "orphan"
    /\ evK' = IF o = "ok" THEN "comp" ELSE evK
    /\ nEv' = IF o = "ok" THEN nEv + 1 ELSE nEv
    /\ flag' = IF o = "ok" THEN TRUE ELSE flag
    /\ evSet' = IF o = "ok" /\ kind = "P" THEN SetAt(bp) ELSE evSet
    /\ candC' = IF o = "ok" THEN (cc = 2) ELSE candC
    /\ idx' = IF o = "ok" /\ kind = "G" THEN TRUE ELSE idx
    /\ viol' = viol \cup (IF met /\ Esc < rn THEN {"retry-past-instant"} ELSE {})
                       \cup (IF cc = 0 THEN {"comp-unpaired"} ELSE {})
                       \cup (IF cc = 3 THEN {"comp-over-cap"} ELSE {})
                       \cup (IF esc >= 1 THEN {"comp-escalated"} ELSE {})
                       \cup (IF idx' /\ evK' = "none" THEN {"idx-before-event"} ELSE {})
    /\ UNCHANGED <<now, since, pos, reg, kind, at, cc, bp, esc, fnd>>

Next ==
    \/ Tick
    \/ \E q \in Q : Register(q)
    \/ \E k \in {"P", "G"} : Begin(k)
    \/ CommitClean
    \/ \E c \in 0..3 : CommitOwed(c)
    \/ StartRun
    \/ ProcSkip
    \/ ProcFinding
    \/ ProcEscalateNow
    \/ ProcEscalateLate
    \/ \E o \in {"ok", "evrefused", "intrefused"} : ProcComp(o)
Spec == Init /\ [][Next]_vars

\* --- composition-level safety invariants ---

\* Invariant 2.1: a Consent record whose grant instant plus the widened window precedes now carries
\* a grant closure: a grant event naming it, or an escalation of kind grant naming it, or its grant
\* instant plus the audit horizon preceding now (Term grant closure).
Invariant_2_1 ==
    (kind = "G" /\ st \in {"orphan", "done"} /\ at + Wd < now)
        => (evK # "none" \/ esc >= 1 \/ at + H < now)

\* Invariant 3.5: a paired unpropagated record whose revocation instant plus the widened window
\* precedes now carries a propagation closure: an event naming the consent or an escalation of kind
\* propagation naming it. An unpropagated record is not aged, a paired one has a candidate.
Invariant_3_5 ==
    (kind = "P" /\ st = "orphan" /\ cc >= 1 /\ at + Wd < now /\ ~(at + H < now))
        => (esc >= 1)

\* Invariant 3.2: two propagation events never carry one consent id.
Invariant_3_2 == nEv <= 1

\* Invariant 3.3: a propagation event's set equals the registered set at the event's boundary.
Invariant_3_3 ==
    (kind = "P" /\ evK # "none") => (evSet = SetAt(bp))

\* Invariant 3.6: every compensating event carries the recovery flag, and Check 3.6: behind a
\* recovery intent the reconciliation attested first.
Invariant_3_6 == (evK = "comp") => (flag /\ ri)

\* Check 3.4 and Reconciliation 32: a record the reconciliation escalated names no event.
Check_3_4 == (esc >= 1) => (evK = "none")

\* Reconciliation 33: no second landed escalation for one record.
Reconciliation_33 == esc <= 1 /\ ~("esc-twice" \in viol)

\* Reconciliation 12, 12a: no compensation of an unpaired record or one over the intent candidates cap.
Reconciliation_12 == ~("comp-unpaired" \in viol) /\ ~("comp-over-cap" \in viol)

\* Reconciliation 28: a compensating event is retried only while the orphan is under compensation.
Reconciliation_28 == ~("retry-past-instant" \in viol)

\* Reconciliation 30: an escalation of a compensable orphan follows its escalation instant and a refusal.
Reconciliation_30 == ~("esc-early" \in viol)

\* Reconciliation 32: a record is not compensated after it is escalated.
Reconciliation_32 == ~("comp-escalated" \in viol)

\* Reconciliation 21: a compensating event names the intent candidates where more than one pairs.
Reconciliation_21 == (evK = "comp" /\ cc = 2) => candC

\* Reconciliation 20: a compensated grant's index entries follow the compensating grant event.
Reconciliation_20 == idx => (evK # "none") /\ ~("idx-before-event" \in viol)

====
