-- customer-onboarding-buggy-monitor-party-from-intent.als
-- DELIBERATELY WRONG twin of customer-onboarding.als (unit: `compositions/customer-onboarding.md formal layer`).
--
-- INJECTED DEFECT: the case-to-monitoring rebuild takes the party id from the initiation intent, which carries none
-- on the direct path (Composition state 26, Term binding-bearing record, Action wiring 9).
--
-- BREAKS: A_Invariant_6_1.
-- Everything else is customer-onboarding.als as written; read its comments there.

module customer_onboarding_buggy_monitor_party_from_intent

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Party: a party record the Party Identity instance holds, named by its party id.
sig Party {}

-- Actor: an actor reference — a caller, a verifying actor, a clearing actor, an operator, or
-- the composition's own recovery identity.
sig Actor {}

-- RecoveryIdentity: the service identity of the seven act kinds, under which the sweep
-- attests what it writes; no write the composition's own actions make is attested under it
-- (Term recovery identity, Composes 16, 17).
one sig RecoveryIdentity extends Actor {}

-- Evidence: an evidence reference a verification names.
sig Evidence {}

-- Now: an instant the host injects — an intent's pairing datum, and the instant Party
-- Identity and Retention Window stamp on what the commit writes (Capability requirement 48).
-- Compared by equality only.
sig Now {}

-- Case: an onboarding case, named by its case id.
sig Case {}

-- Due: a next review due value an intent carries.
sig Due {}

-- Policy: a retention policy reference. The deployment's two named ones are the active
-- relationship policy and the post closure policy (Capability requirement 15, 16).
sig Policy {}
one sig ActivePolicy, PostClosurePolicy extends Policy {}

-- PState: Party Identity's lifecycle states, cited (Term party state).
abstract sig PState {}
one sig Unverified, Verified, Suspended, Closed extends PState {}

-- Result: the verification results (Term verification results).
abstract sig Result {}
one sig Passed, Failed extends Result {}

-- PIEvent: an event in Party Identity's records — its party, the instant stamped on it, and,
-- as the model's own ghost, the intent whose commit wrote it (none: a write outside every
-- invocation, the second writer Composes 20 forbids and Reconciliation 38 looks for).
abstract sig PIEvent {
    party : one Party,
    at    : one Now,
    wrote : lone Intent
}

-- VerifEvent: a verification event — its result, verifying actor reference, evidence
-- reference, and the state change it answered with, if any (Party Identity's verify).
sig VerifEvent extends PIEvent {
    result   : one Result,
    verifier : one Actor,
    evidence : one Evidence,
    change   : lone StateChange
}

-- StateChange: a state change event, carrying the new state.
sig StateChange extends PIEvent {
    newState : one PState
}

-- PILog: the insertion order of Party Identity's records (`pre`: stands earlier than).
one sig PILog {
    pre : PIEvent -> PIEvent
}

-- Placement: a retention the party retention instance holds — the party record it is over,
-- its policy reference, its retention instant and, as a ghost, the intent whose commit placed
-- it (none: placed outside the composition).
sig Placement {
    over     : one Party,
    policy   : one Policy,
    placedAt : one Now,
    placedBy : lone Intent
}

-- Path: the enrollment path (Term enrollment path).
abstract sig Path {}
one sig Direct, External extends Path {}

-- Intent: an intent the invocation open writes — its case id (Identity 9), its act key where
-- the act key is the party id (none on the direct path, Action wiring 9), its pairing datum
-- (Identity 12) and the actor it is attested under (Composes 15).
abstract sig Intent {
    case     : one Case,
    key      : lone Party,
    now      : one Now,
    attester : one Actor
}

-- InitIntent: an initiation intent (enrollment on the direct path, admission on the external
-- path), carrying the retention policy reference and the next review due (Action wiring 8).
sig InitIntent extends Intent {
    path      : one Path,
    retPolicy : one Policy,
    initDue   : lone Due
}

-- VerIntent: a verification intent, carrying the verifying actor reference, the evidence
-- reference, the verification result and the next review due (Action wiring 24, 30).
sig VerIntent extends Intent {
    verVerifier : one Actor,
    verEvidence : one Evidence,
    verResult   : one Result,
    verDue      : lone Due
}

-- AdvIntent: an adverse trigger intent (its trigger fields are the TLA+ model's).
sig AdvIntent extends Intent {}

-- PerIntent: a periodic review intent, carrying a next review due against an unsuspended
-- party (Action wiring 47, 48).
sig PerIntent extends Intent {
    perDue : lone Due
}

-- ClrIntent: a clearance intent, carrying the clearing actor (the call's actor reference),
-- the verifying actor reference, the evidence reference and the next review due (Action
-- wiring 83).
sig ClrIntent extends Intent {
    clearer     : one Actor,
    clrVerifier : one Actor,
    clrEvidence : one Evidence,
    clrDue      : lone Due
}

-- CloIntent: a closure intent (its open triggers at close are the TLA+ model's).
sig CloIntent extends Intent {}

-- Writer: who wrote an outcome — the invocation's close, the sweep (a recovered outcome) or
-- an operator through the invocation resolve.
abstract sig Writer {}
one sig ByClose, BySweep, ByOperator extends Writer {}

-- Closing: a record closing an intent under its invocation id (Term closing).
abstract sig Closing {
    intent : one Intent
}

-- Outcome: the kind's one outcome — its writer, and the verification id, state change id,
-- placement and party id it carries (Action wiring 19, 29, 63, 73, 90, 127).
sig Outcome extends Closing {
    writer    : one Writer,
    verif     : lone VerifEvent,
    sc        : lone StateChange,
    placement : lone Placement,
    oParty    : lone Party
}

-- Refusal: the kind's refused record the invocation refuse writes for a pre-commit arm.
sig Refusal extends Closing {}

-- Abandonment: an operator's abandoned disposition through the invocation resolve.
sig Abandonment extends Closing {}

-- Escalation: the sweep's escalation of an intent it could not close.
sig Escalation extends Closing {}

-- Env: what the environment answers — the parties whose read at [Activity Permitted] answers
-- invalid-query or state-unavailable (Action wiring 136a, Execution Contract Read 1).
one sig Env {
    unreadable : set Party
}

-- Answer: what [Activity Permitted] answers.
abstract sig Answer {}
one sig Permitted, NotKnown, NotVerified, StateUnavailable extends Answer {}

-- Arm: the five arms of Invariant 2.1, so "exactly one" is a count.
abstract sig Arm {}
one sig ArmOutcome, ArmOpen, ArmEscalated, ArmFalseClosing, ArmFinding extends Arm {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Party Identity's log: helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- scBefore: the party's state changes standing earlier in Party Identity's log than e.
fun scBefore[e : PIEvent] : set StateChange {
    { s : StateChange | s.party = e.party and s -> e in PILog.pre }
}

-- lastScBefore: the party's latest state change before e.
fun lastScBefore[e : PIEvent] : set StateChange {
    { s : scBefore[e] | no s2 : scBefore[e] | s -> s2 in PILog.pre }
}

-- priorState: the party's state just before e (unverified before any state change).
fun priorState[e : PIEvent] : set PState {
    (some lastScBefore[e]) => lastScBefore[e].newState else Unverified
}

-- stateOf: the state Party Identity's read reports for a party — its latest state change's.
fun stateOf[p : Party] : set PState {
    let ss = { s : StateChange | s.party = p },
        last = { s : ss | no s2 : ss | s -> s2 in PILog.pre } |
        (some last) => last.newState else Unverified
}

-- isReinstate: a state change from suspended to verified (Party Identity's reinstate).
pred isReinstate[r : StateChange] {
    r.newState = Verified and priorState[r] = Suspended
}

-- lastSuspensionBefore: the party's most recent suspension before e.
fun lastSuspensionBefore[e : PIEvent] : set StateChange {
    let ss = { s : scBefore[e] | s.newState = Suspended } |
        { s : ss | no s2 : ss | s -> s2 in PILog.pre }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: only what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- PILogIsOrder: Party Identity's records stand in one insertion order (Party Identity's
-- append-only log).
fact PILogIsOrder {
    no iden & PILog.pre
    PILog.pre.(PILog.pre) in PILog.pre
    all disj e1, e2 : PIEvent | e1 -> e2 in PILog.pre or e2 -> e1 in PILog.pre
}

-- PartyIdentityLifecycle: Party Identity's own guarantees over its records, cited — a closed
-- party takes no event; verify(passed) against an unverified party answers a state change to
-- verified, written with the verification at its instant and nothing between, and no other
-- verify answers one; a suspend leaves a verified party; a reinstate stands only after a
-- passed verification later than the most recent suspension (Party Identity Operation 15, 18).
fact PartyIdentityLifecycle {
    all e : PIEvent | priorState[e] != Closed
    all s : StateChange {
        s.newState != priorState[s]
        s.newState != Unverified
        s.newState = Suspended implies priorState[s] = Verified
        (s.newState = Verified and priorState[s] = Unverified) implies some change.s
        (s.newState = Verified and priorState[s] = Suspended) implies
            some v : VerifEvent | v.party = s.party and v.result = Passed
                and v -> s in PILog.pre and lastScBefore[s] -> v in PILog.pre
    }
    all v : VerifEvent {
        some v.change iff (priorState[v] = Unverified and v.result = Passed)
        some v.change implies {
            v.change.party = v.party
            v.change.at = v.at
            v.change.newState = Verified
            v -> v.change in PILog.pre
            no e : PIEvent | e.party = v.party and v -> e in PILog.pre and e -> v.change in PILog.pre
        }
    }
    all s : StateChange | lone change.s
}

-- HostInjectsFreshNow: the host never injects an equal now into two invocations of one act
-- key (Capability requirement 49, the host's obligation, External check 12).
fact HostInjectsFreshNow {
    all disj i1, i2 : Intent | (some i1.key and i1.key = i2.key) implies i1.now != i2.now
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The trail and the indexes: helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- finalsOf: the closings that end an intent — an outcome, a refusal record or an abandonment.
fun finalsOf[i : Intent] : set Closing {
    intent.i & (Outcome + Refusal + Abandonment)
}

-- isOpen: an intent no closing names (Recoverable Invocation Invariant 4.1).
pred isOpen[i : Intent] {
    no intent.i
}

-- isEscalated: an intent the sweep escalated and nothing has closed since.
pred isEscalated[i : Intent] {
    some intent.i & Escalation and no finalsOf[i]
}

-- byOperator: an intent an operator closed, with an outcome or an abandonment.
pred byOperator[i : Intent] {
    some finalsOf[i] & (Abandonment + writer.ByOperator)
}

-- initOutcomes: the initiation outcomes of a case.
fun initOutcomes[c : Case] : set Outcome {
    { o : Outcome | o.intent in InitIntent and o.intent.case = c }
}

-- initPartyOf: the party an initiation outcome binds — the intent's party id on the external
-- path, the outcome's on the direct path (Term binding-bearing record).
fun initPartyOf[o : Outcome] : set Party {
    (o.intent.(InitIntent <: path) = External) => o.intent.key else o.oParty
}

-- caseParty: the party a case binds, from its initiation outcome — what the validations
-- ahead of an open resolve the act key through (Action wiring 21, 24).
fun caseParty[c : Case] : set Party {
    { p : Party | some o : initOutcomes[c] | p in initPartyOf[o] }
}

-- p2c: the party-to-case index as its rebuild reads the trail — the initiation outcomes and
-- the periodic review intents (Composition state 23, 24).
fun p2c : Party -> Case {
    { p : Party, c : Case | p in caseParty[c] or some i : PerIntent | i.case = c and i.key = p }
}

-- c2mEntry: the cases the case-to-monitoring index holds an entry for — those with a
-- binding-bearing record (Composition state 26).
fun c2mEntry : set Case {
    { c : Case | some initOutcomes[c] or some i : PerIntent | i.case = c }
}

-- c2mParty: the party a case-to-monitoring entry names, taken from the binding-bearing
-- records (Composition state 26, Term binding-bearing record).
fun c2mParty : Case -> Party {
    { c : Case, p : Party | some o : initOutcomes[c] | p in o.intent.key }   -- DEFECT: the intent's party
    + { c : Case, p : Party | some i : PerIntent | i.case = c and i.key = p }
}

-- c2mDue: the next review due a case-to-monitoring entry carries, from its schedule-bearing
-- records (Composition state 28, Term schedule-bearing record).
fun c2mDue[c : Case] : set Due {
    { d : Due | some o : Outcome | o.intent.case = c and (
        (o.intent in InitIntent and d in o.intent.initDue) or
        (o.intent in VerIntent and some o.sc and d in o.intent.verDue) or
        (o.intent in PerIntent and d in o.intent.perDue) or
        (o.intent in ClrIntent and d in o.intent.clrDue)) }
}

-- activeCases: the cases whose active flag is true — named by the party-to-case index and
-- named by no closure outcome (Composition state 25, Term active flag).
fun activeCases : set Case {
    Party.p2c - { c : Case | some o : Outcome | o.intent in CloIntent and o.intent.case = c }
}

-- verOutcomesOf: the verification outcomes of a party's verification intents.
fun verOutcomesOf[p : Party] : set Outcome {
    { o : Outcome | o.intent in VerIntent and o.intent.key = p }
}

-- gate: what [Activity Permitted] answers — not-known for a party the party-to-case index does
-- not name, state-unavailable for a read that answers none, permitted for a verified party,
-- not-verified otherwise (Action wiring 134 through 140).
fun gate[p : Party] : set Answer {
    (no p.p2c) => NotKnown
    else ((p in Env.unreadable) => StateUnavailable
    else ((stateOf[p] = Verified) => Permitted else NotVerified))
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The reconciliation: what it reads in the state (Reconciliation 37 through 39, 25)
-- ─────────────────────────────────────────────────────────────────────────────

-- carrying: the intents carrying a Party Identity event — of a kind whose commit writes such
-- a record, its act key the event's party, its pairing datum the event's instant (Term carried
-- record, Term carrying intent).
fun carrying[e : PIEvent] : set Intent {
    { i : Intent | i.key = e.party and i.now = e.at and
        (e in VerifEvent implies i in VerIntent + ClrIntent) and
        (e in StateChange implies i in VerIntent + AdvIntent + ClrIntent + CloIntent) }
}

-- finding: the reconciliation opens a write-ownership finding for an event no intent carries
-- (Reconciliation 38).
pred finding[e : PIEvent] {
    no carrying[e]
}

-- falseClosing: an event one intent carries whose carrying intent an abandonment or a refusal
-- closed — alerted (Reconciliation 39, Term false closing).
pred falseClosing[e : PIEvent] {
    one carrying[e]
    some finalsOf[carrying[e]] & (Abandonment + Refusal)
}

-- alert25: Reconciliation 25 — a verified party under an active case carrying no verification
-- outcome naming a state change id and no open verification intent (no record is aged here).
pred alert25[p : Party] {
    stateOf[p] = Verified
    some p.p2c & activeCases
    no o : verOutcomesOf[p] | some o.sc
    no i : VerIntent | i.key = p and isOpen[i]
}

-- datumClean: no event written outside every invocation carries an intent's party and pairing
-- datum. Where one does, the reconciliation reads it as carried and the act probe may name it
-- (FOUND 5); the checks below are taken where the datum is clean.
pred datumClean[i : Intent] {
    no e : PIEvent | no e.wrote and e.party = i.key and e.at = i.now
}

-- arms21: the arms of Invariant 2.1 a verification event stands in.
fun arms21[v : VerifEvent] : set Arm {
    ((some o : Outcome | o.intent in VerIntent and o.verif = v and o.sc = v.change) => ArmOutcome else none)
    + ((some i : carrying[v] | isOpen[i]) => ArmOpen else none)
    + ((some i : carrying[v] | isEscalated[i]) => ArmEscalated else none)
    + (falseClosing[v] => ArmFalseClosing else none)
    + (finding[v] => ArmFinding else none)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writers: what each record may be
-- ─────────────────────────────────────────────────────────────────────────────

-- opensOnKnownCase: every act on a case opens only once the case's initiation outcome stands,
-- keyed by the party the case binds (Action wiring 21, 22, 24, 37, 38, 80, 81, 112, 113).
pred opensOnKnownCase[i : Intent] {
    some initOutcomes[i.case]
    some i.key
    i.key in caseParty[i.case]
}

-- initWrites: an initiation — no party id on the direct path, the party id on the external
-- path (Action wiring 9, 4), the next review due on the intent (Action wiring 8), and its
-- transaction a placement under the caller's retention policy reference at its now over the
-- party (Action wiring 13, 14; Term enrollment transaction, admission transaction).
pred initWrites[i : InitIntent] {
    i.path = Direct implies no i.key
    i.path = External implies some i.key
    one i.initDue
    no wrote.i
    lone placedBy.i
    all pl : placedBy.i {
        pl.policy = i.retPolicy
        pl.placedAt = i.now
        i.path = External implies pl.over = i.key
    }
}

-- verWrites: a verification — the open under the verifying actor (Action wiring 24), the next
-- review due on the intent (Action wiring 30), and its commit Party Identity's verify with the
-- intent's fields at its now (Action wiring 25, Capability requirement 48).
pred verWrites[i : VerIntent] {
    opensOnKnownCase[i]
    i.attester = i.verVerifier
    one i.verDue
    no placedBy.i
    lone wrote.i & VerifEvent
    all v : wrote.i & VerifEvent {
        v.party = i.key
        v.at = i.now
        v.verifier = i.verVerifier
        v.evidence = i.verEvidence
        v.result = i.verResult
    }
    wrote.i & StateChange = (wrote.i & VerifEvent).change
}

-- advWrites: an adverse trigger — no next review due (Action wiring 49), and its suspension
-- transaction one suspend at its now (Term suspension transaction).
pred advWrites[i : AdvIntent] {
    opensOnKnownCase[i]
    no placedBy.i
    lone wrote.i
    all s : wrote.i {
        s in StateChange
        s.party = i.key
        s.at = i.now
        s.(StateChange <: newState) = Suspended
    }
}

-- perWrites: a periodic review — its renewal transaction one placement over the party at its
-- now (Action wiring 67, Term renewal transaction).
pred perWrites[i : PerIntent] {
    opensOnKnownCase[i]
    no wrote.i
    lone placedBy.i
    all pl : placedBy.i {
        pl.over = i.key
        pl.placedAt = i.now
        pl.policy != PostClosurePolicy
    }
}

-- clrWrites: a clearance — the open under the clearing actor (Composes 15, Action wiring 83),
-- the next review due on the intent, and its transaction a passed verification with the
-- intent's verifying actor and evidence, then the reinstate, at its now, nothing between, or
-- nothing at all (Term clearance transaction, Action wiring 84, 85, 95).
pred clrWrites[i : ClrIntent] {
    opensOnKnownCase[i]
    i.attester = i.clearer
    one i.clrDue
    no placedBy.i
    no wrote.i or (some v : wrote.i & VerifEvent, r : wrote.i & StateChange {
        wrote.i = v + r
        v.party = i.key and v.at = i.now
        v.result = Passed
        v.verifier = i.clrVerifier and v.evidence = i.clrEvidence
        r.party = i.key and r.at = i.now and isReinstate[r]
        v -> r in PILog.pre
        no e : PIEvent | e.party = i.key and v -> e in PILog.pre and e -> r in PILog.pre
    })
}

-- cloWrites: a closure — its transaction Party Identity's close and a placement under the post
-- closure policy over the party, at its now, together or not at all (Term closure transaction,
-- Action wiring 116, 123).
pred cloWrites[i : CloIntent] {
    opensOnKnownCase[i]
    (no wrote.i and no placedBy.i) or {
        one wrote.i
        one placedBy.i
        wrote.i in StateChange
        wrote.i.party = i.key
        wrote.i.at = i.now
        wrote.i.(StateChange <: newState) = Closed
        placedBy.i.over = i.key
        placedBy.i.placedAt = i.now
        placedBy.i.policy = PostClosurePolicy
    }
}

-- closePayload: what the invocation close carries, by kind — the records its own commit wrote
-- (Action wiring 19, 29, 63, 73, 90, 127).
pred closePayload[o : Outcome] {
    let i = o.intent {
        i in InitIntent implies (o.placement = placedBy.i and o.oParty = placedBy.i.over
            and no o.verif and no o.sc)
        i in VerIntent implies (o.verif = wrote.i & VerifEvent and o.sc = o.verif.change
            and no o.placement and no o.oParty)
        i in AdvIntent implies (o.sc = wrote.i and no o.verif and no o.placement and no o.oParty)
        i in PerIntent implies (o.placement = placedBy.i and no o.verif and no o.sc and no o.oParty)
        i in ClrIntent implies (o.verif = wrote.i & VerifEvent and o.sc = wrote.i & StateChange
            and no o.placement and no o.oParty)
        i in CloIntent implies (o.sc = wrote.i and o.placement = placedBy.i
            and no o.verif and no o.oParty)
    }
}

-- sweepPayload: what the sweep's recovered outcome carries — the act probe's committed answer.
-- The verification probe keeps the verification event at the pairing datum with the intent's
-- verifying actor and evidence, and the state change at the same instant; the clearance probe
-- the passed one with those, and the state change to verified at the same instant (Term
-- verification probe, Term clearance probe). The other probes find the intent's own records.
pred sweepPayload[o : Outcome] {
    let i = o.intent {
        i in VerIntent implies {
            let F = { v : VerifEvent | v.party = i.key and v.at = i.now
                        and v.verifier = i.verVerifier and v.evidence = i.verEvidence } {
                one F
                o.verif = F
                o.sc = { s : StateChange | s.party = i.key and s.at = i.now }
            }
            no o.placement and no o.oParty
        }
        i in ClrIntent implies {
            let F = { v : VerifEvent | v.party = i.key and v.at = i.now and v.result = Passed
                        and v.verifier = i.clrVerifier and v.evidence = i.clrEvidence },
                G = { s : StateChange | s.party = i.key and s.at = i.now and s.newState = Verified } {
                one F
                one G
                o.verif = F
                o.sc = G
            }
            no o.placement and no o.oParty
        }
        i in InitIntent + AdvIntent + PerIntent + CloIntent implies {
            some wrote.i + placedBy.i
            closePayload[o]
        }
    }
}

-- outcomeWrites: an outcome — the close's only for a commit that wrote; the sweep's by its
-- probe; neither for an intent the sweep escalated; an operator's payload unchecked
-- (Recoverable Invocation commit 4, reconcile step 3.2, resolve 31).
pred outcomeWrites[o : Outcome] {
    let i = o.intent {
        o.writer = ByClose implies {
            some wrote.i + placedBy.i
            closePayload[o]
        }
        o.writer = BySweep implies sweepPayload[o]
        o.writer in ByClose + BySweep implies no intent.i & Escalation
    }
}

-- refusalWrites: the invocation refuse closes only a pre-commit arm, the commit having
-- written nothing (Action wiring 155, Recoverable Invocation commit 3).
pred refusalWrites[f : Refusal] {
    no wrote.(f.intent)
    no placedBy.(f.intent)
    no intent.(f.intent) & Escalation
}

-- escalationWrites: the sweep escalates an intent no close, sweep outcome or refusal closed;
-- only an operator closes it after.
pred escalationWrites[e : Escalation] {
    no finalsOf[e.intent] & (Refusal + writer.(ByClose + BySweep))
}

-- conforms: every record in the state is one its writer's rules let it write.
pred conforms {
    all i : Intent | i.attester != RecoveryIdentity        -- Composes 17
    all i : InitIntent | initWrites[i]
    all i : VerIntent | verWrites[i]
    all i : AdvIntent | advWrites[i]
    all i : PerIntent | perWrites[i]
    all i : ClrIntent | clrWrites[i]
    all i : CloIntent | cloWrites[i]
    all i : Intent | lone finalsOf[i] and lone intent.i & Escalation
    all o : Outcome | outcomeWrites[o]
    all f : Refusal | refusalWrites[f]
    all e : Escalation | escalationWrites[e]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the composition's writers can leave that violates
-- this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: [Activity Permitted] answers permitted only for a party the party-to-case
-- index names and Party Identity's read reports verified.
assert A_Invariant_1_1 {
    conforms implies all p : Party | gate[p] = Permitted implies {
        some p.p2c
        p not in Env.unreadable
        stateOf[p] = Verified
    }
}
check A_Invariant_1_1 for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- A_Invariant_1_2: a party the party-to-case index names and Party Identity's read reports
-- verified is answered permitted.
assert A_Invariant_1_2 {
    conforms implies all p : Party |
        (some p.p2c and p not in Env.unreadable and stateOf[p] = Verified) implies gate[p] = Permitted
}
check A_Invariant_1_2 for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- A_Invariant_2_1: every verification event carrying a state change id stands in exactly one
-- of Invariant 2.1's arms, where no operator's outcome names it or closes its carrying intent
-- (FOUND 1) and no outside write stands at its carrying intent's datum (FOUND 5).
assert A_Invariant_2_1 {
    conforms implies all v : VerifEvent |
        (some v.change
         and (no o : writer.ByOperator | o.verif = v or o.intent in carrying[v])
         and (all i : carrying[v] | datumClean[i]))
        implies one arms21[v]
}
check A_Invariant_2_1 for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- A_Invariant_2_3: a quiescent verified party under an active case carries a verification
-- outcome where its events are all the composition's and no operator closed its intents, and
-- where it carries none, Reconciliation 25 alerts it.
assert A_Invariant_2_3 {
    conforms implies all p : Party |
        (stateOf[p] = Verified and some p.p2c & activeCases
         and no i : Intent | i.key = p and (isOpen[i] or isEscalated[i]))
        implies {
            (no e : PIEvent | e.party = p and no e.wrote) and
            (no i : Intent | i.key = p and byOperator[i])
                implies some verOutcomesOf[p]
            no verOutcomesOf[p] implies alert25[p]
        }
}
check A_Invariant_2_3 for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- A_Invariant_4_1: the verification a clearance outcome of the close or the sweep names is
-- passed, of the party, and stands later in Party Identity's log than the party's most
-- recent suspension before the reinstatement (Check 4.2, 4.3), where no outside write stands at
-- the clearance's datum (FOUND 5).
assert A_Invariant_4_1 {
    conforms implies all o : Outcome |
        (o.intent in ClrIntent and o.writer != ByOperator and some o.sc
         and datumClean[o.intent]) implies {
            some o.verif
            o.verif.result = Passed
            o.verif.party = o.sc.party
            all s : lastSuspensionBefore[o.sc] | s -> o.verif in PILog.pre
        }
}
check A_Invariant_4_1 for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- A_Invariant_4_2: a reinstatement a clearance transaction wrote is named, with a
-- verification id, by a clearance outcome, once its intent stands neither open nor escalated
-- and no operator closed it (FOUND 1, 3).
assert A_Invariant_4_2 {
    conforms implies all r : StateChange |
        (isReinstate[r] and r.wrote in ClrIntent
         and not isOpen[r.wrote] and not isEscalated[r.wrote] and not byOperator[r.wrote])
        implies some o : Outcome | o.intent in ClrIntent and o.sc = r and some o.verif
}
check A_Invariant_4_2 for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- A_Invariant_4_3: a clearance intent stands attested under the clearing actor, never the
-- recovery identity, and the verification its transaction writes carries the verifying actor
-- and the evidence reference the intent names.
assert A_Invariant_4_3 {
    conforms implies all i : ClrIntent {
        i.attester = i.clearer
        i.attester != RecoveryIdentity
        all v : wrote.i & VerifEvent | v.evidence = i.clrEvidence and v.verifier = i.clrVerifier
    }
}
check A_Invariant_4_3 for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- A_Invariant_5_3: a closure outcome of the close or the sweep names a placement the party
-- retention instance holds over the case's party under the post closure policy.
assert A_Invariant_5_3 {
    conforms implies all o : Outcome | (o.intent in CloIntent and o.writer != ByOperator) implies {
        some o.placement
        o.placement.over = o.intent.key
        o.placement.policy = PostClosurePolicy
    }
}
check A_Invariant_5_3 for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- A_Invariant_6_1: a verified party under an active case is named by its case's
-- case-to-monitoring entry.
assert A_Invariant_6_1 {
    conforms implies all p : Party, c : p.p2c & activeCases |
        stateOf[p] = Verified implies p in c.c2mParty
}
check A_Invariant_6_1 for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- A_Invariant_6_2: every case-to-monitoring entry carries a next review due.
assert A_Invariant_6_2 {
    conforms implies all c : c2mEntry | some c2mDue[c]
}
check A_Invariant_6_2 for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ─────────────────────────────────────────────────────────────────────────────
-- Runs (each shape the page admits is reachable)
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowPermitted: a party verified through [Record Verification], its outcome closed by the
-- invocation, answered permitted.
run ShowPermitted {
    conforms
    some p : Party | gate[p] = Permitted and some o : verOutcomesOf[p] | o.writer = ByClose and some o.sc
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowVerifiedWithoutCase: a party Party Identity reports verified that no case of this
-- composition names, answered not-known (Wiring decision 2).
run ShowVerifiedWithoutCase {
    conforms
    some p : Party | stateOf[p] = Verified and gate[p] = NotKnown
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowOutcomeOpenGatePermits: a committed transitioning verification whose outcome has not
-- landed, its intent open, the party answered permitted (Failure path — verification
-- committed, outcome open).
run ShowOutcomeOpenGatePermits {
    conforms
    some v : VerifEvent | some v.change and v.wrote in VerIntent and isOpen[v.wrote]
        and gate[v.party] = Permitted
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowRecoveredVerification: a transitioning verification whose outcome the sweep recovered.
run ShowRecoveredVerification {
    conforms
    some o : Outcome | o.writer = BySweep and o.intent in VerIntent and some o.sc
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowFalseClosingAlerted: an operator abandoned a verification whose verify committed — the
-- false closing alert, and Reconciliation 25's.
run ShowFalseClosingAlerted {
    conforms
    some v : VerifEvent | some v.change and falseClosing[v] and alert25[v.party]
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowOutsideVerificationFound: a transitioning verification written outside every invocation
-- — the write-ownership finding.
run ShowOutsideVerificationFound {
    conforms
    some v : VerifEvent | some v.change and no v.wrote and finding[v]
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowClearance: a reinstatement named by the clearance outcome the invocation closed.
run ShowClearance {
    conforms
    some o : Outcome | o.intent in ClrIntent and o.writer = ByClose and isReinstate[o.sc]
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowClosedCase: a closed case — the party closed and under the post closure placement.
run ShowClosedCase {
    conforms
    some o : Outcome | o.intent in CloIntent and o.writer = ByClose and stateOf[o.intent.key] = Closed
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowDirectPathCase: a direct path case whose entries name the party its outcome carries.
run ShowDirectPathCase {
    conforms
    some o : Outcome | o.intent in InitIntent and o.intent.path = Direct and some o.oParty
        and o.oParty in o.intent.case.c2mParty
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowOperatorNamesAnotherVerification: FOUND 1 — an operator's verification outcome closing
-- the carrying intent of a transitioning verification names another verification id.
run ShowOperatorNamesAnotherVerification {
    conforms
    some v : VerifEvent, o : writer.ByOperator |
        some v.change and o.intent in carrying[v] and o.intent in VerIntent and o.verif != v
        and no arms21[v]
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowOperatorClearanceNamesOldVerification: FOUND 1 — an operator's clearance outcome names a
-- verification older than the party's most recent suspension.
run ShowOperatorClearanceNamesOldVerification {
    conforms
    some o : writer.ByOperator | o.intent in ClrIntent and isReinstate[o.sc] and some o.verif
        and some s : lastSuspensionBefore[o.sc] | o.verif -> s in PILog.pre
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowOperatorClosesUncommitted: FOUND 2 — an operator's closure outcome on a closure whose
-- transaction never committed: the case closed, the party not, no post closure placement.
run ShowOperatorClosesUncommitted {
    conforms
    some o : writer.ByOperator | o.intent in CloIntent and no wrote.(o.intent)
        and o.intent.case not in activeCases and stateOf[o.intent.key] != Closed
        and no pl : Placement | pl.over = o.intent.key and pl.policy = PostClosurePolicy
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowOutsideWriteRecovered: FOUND 5 — the sweep recovers, as a clearance's outcome, a
-- verification and a state change no invocation wrote, stamped with the clearance's datum.
run ShowOutsideWriteRecovered {
    conforms
    some o : Outcome | o.writer = BySweep and o.intent in ClrIntent
        and no o.verif.wrote and no o.sc.wrote
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing

-- ShowReinstatedClearanceOpen: FOUND 3 — a reinstated party whose clearance intent stands open,
-- no clearance outcome naming the reinstatement (Cross-record consistency 1).
run ShowReinstatedClearanceOpen {
    conforms
    some r : StateChange | isReinstate[r] and r.wrote in ClrIntent and isOpen[r.wrote]
        and no o : Outcome | o.sc = r
} for 3 but 6 PIEvent, 4 Placement, 4 Intent, 4 Closing
