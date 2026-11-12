-- recoverable-invocation-buggy-outage-no-last-seen.als
-- BUGGY TWIN: Term instance finding broken: an instance finding may carry no last seen.
-- A copy of recoverable-invocation.als with this one defect; the harness must reject it (a check SAT).
-- Alloy structural model for the Recoverable Invocation composition
-- (Grace Commons compositions/recoverable-invocation.md)
-- Grounded on Final Critique 49, 2026-11-07 at 1451abf — Alloy layer authored 2026-11-12.
-- Derived validator; the English spec is the single source of truth. On any
-- disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
--
-- PURPOSE
-- Verify, by bounded exhaustive search, the STATIC data model of the composition: what one
-- state of its records must satisfy — the journal's records (the intent, the
-- recovery_intended records, and the closing records: an outcome, a refusal, an
-- abandonment, an escalation) with the fields each writer puts on them; the sweep runs'
-- examinations, each with the adopter's act probe's answer over the adopter's database; and
-- the findings register. How the records come to be written in time — the critical section,
-- the lease, lost replies, the sweep's cadence and every window — is the TLA+ model's
-- (recoverable-invocation.tla, which this file does not change).
--
-- RULES ENCODED (named by the page's own labels)
--   Invariant 2.1 — two unsuperseded closing records do not name one invocation id (a
--                   cross-check with the TLA+ model's Inv2_OneWriter).
--   Invariant 2.3 — two sweep closings do not name one invocation id.
--   Invariant 3.1 — every record carries its invocation's invocation id.
--   Invariant 3.2 — the journal join behind open invocations pairs on invocation id alone.
--   Invariant 3.3, 3.4 — act probe's committed answer pairs on pairing datum by equality,
--                   never on a stamp.
--   Invariant 3.5a — under pairing datum none, or more than one match, the sweep writes no
--                   outcome and its closing is an escalation naming the candidates.
--   Invariant 4.4, 4.5 — a journal outage is the instance finding journal-unavailable,
--                   carrying first seen and last seen, never an act finding.
--   Invariant 4.8 — the sweep escalates an act its probe cannot certify as committed.
--   Invariant 4.9 — the sweep writes no abandoned record (Check 6.4's reading: an abandoned
--                   record carries a resolving actor).
--   Invariant 5.1 — no sweep outcome without an earlier recovery_intended (a cross-check with
--                   the TLA+ model's Inv9_RecoveryIntentFirst).
--   Invariant 5.2 — a sweep outcome carries the service identity's attestation, recovery and
--                   the original caller in acting actor reference.
--   Invariant 5.3 — a sweep outcome carries only what act probe re-derived.
--   Invariant 5.4 — an operator's outcome carries the operator's attestation, the original
--                   caller and resolving actor.
--   Invariant 5.8 — an operator's abandonment only for an elapsed intent.
--   Invariant 5.9 — an undecidable probe answer is escalated with its candidates.
--   Invariant 5.10 — no sweep closing on a probe answer of unavailable.
--   Invariant 7.1, 7.2, 7.3 — the sweep examines no in-flight intent, none at or past its
--                   horizon edge, none whose payload the substrate destroyed.
--   The writers' rules these checks read: Primitive policy 4, 5, 11, 11a; open step 1.2, 1.9;
--   close 1, 6, close step 2.2, 2.3, 3.1; refuse step 2.2, 3.1; reconcile 2, reconcile step
--   1.2, 2.5, 3.2 through 3.13, 3.20; resolve 1, 9, 13 through 16, 18, 21, 28, 31, 33, 36;
--   act probe 2, 3, 3a, 4, 7, 8, 9; pairing datum 2, 6a; service identity 1a, 3; Which
--   closing stands 2, 7; open invocations 3; Term act finding, Term instance finding and the
--   six conditions.
--
-- NOT CHECKED HERE
--   Nothing testable in Alloy: Invariant 1.2 (a refused call writes nothing, so no state
--   holds it); Invariant 4.1, 4.2, 4.3, 4.3a, 4.6, 4.7, 4.11 (each a closure or a report
--   within a window, or a writer's silence through an outage: properties across steps);
--   Invariant 5.5 (what is not owed: a state with or without a recovery_intended both
--   conform); Invariant 6.1 (the size as the substrate measures a serialized payload is below
--   this model's atoms) and 6.2 (an order); Invariant 8.1 through 8.4 (a signature's
--   declarations and a caller's next call, not records); Invariant 9.2, 9.3 (an absent write
--   to records this model does not hold; a document's transcription).
--   Left to the TLA+ model: Invariant 1.1 (an order), 2.2 (holding the lease across steps),
--   2.6 (a section's authority; the TLA+ model's supersession count). Invariant 9.1 is Audit
--   Trail's.
--
-- READING TAKEN
--   The candidates an undecidable answer names are the database records that match the
--   intent's pairing datum, or match its payload under pairing datum none (act probe 3,
--   3a; Term database candidates); under pairing datum none with no payload match the probe
--   may not answer undecidable, its not-committed is escalated as not-observed, and that
--   escalation names the empty set of candidates (Invariant 3.5a).
--   The re-read a writer makes before its write sees every record of the journal below the
--   write's sequence number (Execution Contract Database 2: the re-read, lease check and
--   append are one transaction), so a writer's guard reads the records with a lower
--   sequence number.
--
-- FOUND (recorded, not cured; see the Ledger's formal line)
--   1. Which fields the sweep's escalation carries is stated two ways: Term as the substrate
--      measures a payload sizes it as database candidates "plus the same" (recovery and
--      acting actor reference), while reconcile step 3.5a and 3.8a list neither and Term
--      recovery sets the flag only on the recovered outcome and an operator's closings. The
--      model leaves both fields free on the sweep's escalation (run ShowEscalationFieldsOpen).
--   2. No rule says act probe answers committed where exactly one database record matches
--      the pairing datum and carries the act key: act probe 2, 8 and 9 say only when it MAY,
--      so a probe may answer not-committed for an act its database holds, and the sweep then
--      escalates as not-observed an act that committed (run ShowNotCommittedWithMatch). No
--      invariant breaks (the escalation is an operator's to settle), but not-observed is then
--      not what the database said.
--
-- SCOPE
-- One state: up to three each of kinds, act keys, invocation ids, actors, pairing data,
-- payload data, outcome refs, database records, sweep runs, examinations, journal records and
-- findings; Int at 5 bits. Instants (recording instants and the runs' and operators' now)
-- range 0 to 6 and durations (invocation completion bound, retention period, clock
-- allowance, run bound, intent candidates cap) 0 to 2, so no edge leaves the Int range.
-- No trace, no `var`, no stepping: the journal is one state, ordered by its sequence numbers.
--
-- NOT MODELED HERE
--   - Time between the records: the lease, the critical section, lost replies and their
--     read-backs, the sweep's cadence and run bound as durations, and the outage; the TLA+
--     model's.
--   - [Open]'s pre-check (open invocations 1, 2, open step 3.4 through 3.9): the TLA+
--     model's Inv7_OneLiveIntent; here two intents of one act may both be open.
--   - Sizing (Invariant 6), the rejection codes, the derived indexes' upkeep beyond the join
--     open invocations 3 states, sequence high water, and the bindings table's lifecycle.
--   - What a sweep escalation and an operator's abandonment carry beyond the fields named
--     here; an operator's purged-intent refusal (resolve 12).
--
-- HOW TO READ RESULTS
-- Every "check A_*" must return "No counterexample found" (UNSAT) — the asserted guarantee holds.
-- Every "run Show*" must return at least one instance (SAT) — confirms non-vacuity.
-- A "check" returning a counterexample is a spec finding.

module recoverable_invocation_buggy_outage_no_last_seen

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Yes: a flag's one value; a field `lone Yes` reads as true when present.
one sig Yes {}

-- Writer: who wrote a journal record (Term actors: a writer is exactly one of the
-- invocation, the sweep run, the operator). A modelling attribute, not a journaled field.
abstract sig Writer {}
one sig Invocation, Sweep, Operator extends Writer {}

-- Answer: what the adopter's act probe answers (act probe 1).
abstract sig Answer {}
one sig Committed, NotCommitted, Undecidable, Unavailable extends Answer {}

-- Cause: a closing record's escalation or abandonment cause (Term cause).
abstract sig Cause {}
one sig CNotCommitted, NotObserved, CUndecidable, OutcomeUnrecordable extends Cause {}

-- Cond: the six conditions of the findings register (Composition state, findings).
abstract sig Cond {}
one sig JournalUnavailable, StoreUnavailable, CredentialRefused,
        ClosureAtRisk, UnboundKind, EscalatedCond extends Cond {}

-- Actor: an actor reference — a caller, an operator, or a kind's service identity.
sig Actor {}

-- ActKey: the key an adopter gives an act (Term act key), compared by byte-identity.
sig ActKey {}

-- InvId: an invocation id, injected at the adopter's seam (Term invocation id).
sig InvId {}

-- Datum: a pairing datum value (Term pairing datum).
sig Datum {}

-- Data: a payload's content — intent data, outcome data, a database record's data.
sig Data {}

-- OutRef: an outcome action reference `<kind>.<outcome>`.
sig OutRef {}

-- Kind: a bound act kind and its bindings: the service identity (or none), the enumerated
-- outcome refs (journal 2), whether the bindings table serves it, its invocation completion
-- bound and its retention period.
sig Kind {
    service   : lone Actor,
    outRefs   : set OutRef,
    served    : lone Yes,
    cbound    : one Int,
    retention : one Int
}

-- Deploy: the instance's clock allowance, run bound and intent candidates cap.
one sig Deploy {
    allowance : one Int,
    runBound  : one Int,
    candCap   : one Int
}

-- StoreRec: a record of the adopter's database: the act key it carries where it carries
-- every field of one (act probe 8), its pairing datum or none, the constituent's stamp, the
-- outcome it re-derives (action reference and data), and the intents whose payload the
-- adopter's comparison says it matches (Term payload match).
sig StoreRec {
    skey   : lone ActKey,
    sdatum : lone Datum,
    stamp  : one Int,
    sref   : one OutRef,
    sdata  : one Data,
    like   : set Intent
}

-- Run: one sweep run, with its one reading of now at the sweep's seam (Primitive policy 18)
-- and the intents whose payload the substrate had destroyed at that reading.
sig Run {
    now  : one Int,
    gone : set Intent
}

-- Exam: one act a run kept and probed: the run, the intent, the probe's answer, whether the
-- database answered a read rejection, whether the outcome's authoritative datum exists
-- only in the dead invocation's memory (act probe 7), and the record a committed answer
-- reads its outcome from.
sig Exam {
    inRun     : one Run,
    of        : one Intent,
    ans       : one Answer,
    storeDown : lone Yes,
    memOnly   : lone Yes,
    hit       : lone StoreRec
}

-- Rec: a journal record: its sequence number (the substrate's), its writer, the
-- composition-written kind, act key, invocation id and intent event id (Primitive policy 11,
-- 11a), the actor record_action attested, and, for the sweep's records, the examination it
-- wrote from (a modelling attribute).
abstract sig Rec {
    sn       : one Int,
    writer   : one Writer,
    kind     : lone Kind,
    key      : lone ActKey,
    inv      : lone InvId,
    iev      : lone Intent,
    attester : one Actor,
    ex       : lone Exam
}

-- Intent: `<kind>.intended`, with the pairing datum its intent data carries (or none), its
-- recording instant and its intent data.
sig Intent extends Rec {
    datum      : lone Datum,
    recordedAt : one Int,
    idata      : one Data
}

-- RecIntended: `<kind>.recovery_intended`, with plan set to outcome (Term plan).
sig RecIntended extends Rec {
    plan : lone Yes
}

-- Closing: a closing record (Term closing record), with supersedes, resolving actor, the
-- recovery flag, acting actor reference and, for an operator's, the operator's reading of now.
abstract sig Closing extends Rec {
    supersedes : set Closing,
    resolver   : lone Actor,
    recovery   : lone Yes,
    acting     : lone Actor,
    opNow      : lone Int
}

-- Outcome: `<kind>.<outcome>`, with its action reference and outcome data.
sig Outcome extends Closing {
    oref  : one OutRef,
    odata : one Data
}

-- Refused: `<kind>.refused`.
sig Refused extends Closing {}

-- Abandoned: `<kind>.abandoned`, with its cause.
sig Abandoned extends Closing {
    acause : one Cause
}

-- Escalated: `<kind>.escalated`, with its cause, the database candidates it names, and the
-- count and range it carries past intent candidates cap (reconcile step 3.10).
sig Escalated extends Closing {
    ecause  : one Cause,
    cands   : set StoreRec,
    overCap : lone Yes
}

-- Finding: a record of the findings register: its condition, kind, act key, invocation id,
-- first seen, last seen and the run that wrote it (Term act finding, Term instance finding).
sig Finding {
    cond      : one Cond,
    fkind     : lone Kind,
    fkey      : lone ActKey,
    finv      : lone InvId,
    firstSeen : lone Run,
    lastSeen  : lone Run,
    runId     : one Run
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: only what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The substrate's sequence numbers are distinct and not negative (Audit Trail).
fact SequenceNumbers {
    all disj a, b : Rec | a.sn != b.sn
    all r : Rec | r.sn >= 0
}

-- An event id names a record already appended: a record naming an intent event id, or a
-- closing named in supersedes, has a lower sequence number (the substrate assigns event ids
-- at the append).
fact NamesWhatExists {
    all r : Rec | some r.iev implies r.iev.sn < r.sn
    all c : Closing, d : c.supersedes | d.sn < c.sn
}

-- An invocation id is fresh per invocation and unique across the instance (Term invocation
-- id: the seam's guarantee), so no two intents carry one.
fact InvocationIdsFresh {
    all disj i, j : Intent | no (i.inv & j.inv)
}

-- The substrate destroys a payload only at its retention deadline, and the clock allowance
-- covers the sweep's seam against the substrate's clock (Audit Trail Invariant 4; Allowance
-- 1): a run sees a payload destroyed only once its reading is within the allowance of the
-- deadline.
fact DestroyedAtDeadline {
    all u : Run, i : u.gone |
        u.now >= minus[plus[i.recordedAt, i.kind.retention], Deploy.allowance]
}

-- The scope: instants 0 to 6, durations 0 to 2, so every edge stays inside 5-bit Int.
fact ScopeBounds {
    all i : Intent | i.recordedAt >= 0 and i.recordedAt <= 6
    all u : Run | u.now >= 0 and u.now <= 6
    all c : Closing | all t : c.opNow | t >= 0 and t <= 6
    all s : StoreRec | s.stamp >= 0 and s.stamp <= 6
    all k : Kind | k.cbound >= 0 and k.cbound <= 2 and k.retention >= 0 and k.retention <= 2
    Deploy.allowance >= 0 and Deploy.allowance <= 2
    Deploy.runBound >= 0 and Deploy.runBound <= 2
    Deploy.candCap >= 0 and Deploy.candCap <= 2
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- examineEdge: recorded_at + invocation completion bound + clock allowance (Term examine edge).
fun examineEdge[i : Intent] : Int {
    plus[plus[i.recordedAt, i.kind.cbound], Deploy.allowance]
}

-- horizonEdge: recorded_at + retention period - clock allowance - run bound (Term horizon edge).
fun horizonEdge[i : Intent] : Int {
    minus[minus[plus[i.recordedAt, i.kind.retention], Deploy.allowance], Deploy.runBound]
}

-- closingsBelow: the closing records naming invocation id v with a sequence number below n —
-- what a writer's re-read under the critical section finds.
fun closingsBelow[v : lone InvId, n : Int] : set Closing {
    { c : Closing | some v and c.inv = v and c.sn < n }
}

-- standingBelow: the standing closing among them: the lowest-numbered of those no other of
-- them names in supersedes (Which closing stands 2, 7; Term standing closing).
fun standingBelow[v : lone InvId, n : Int] : set Closing {
    let cs = closingsBelow[v, n] |
    let un = { c : cs | no d : cs | c in d.supersedes } |
        { c : un | no d : un | d.sn < c.sn }
}

-- matches: the database records whose pairing datum equals the intent's, by equality
-- (pairing datum 2); none where the intent's pairing datum is none.
fun matches[e : Exam] : set StoreRec {
    { s : StoreRec | some e.of.datum and s.sdatum = e.of.datum }
}

-- payloadMatches: under pairing datum none, the records matching the intent's payload
-- (Term payload match).
fun payloadMatches[e : Exam] : set StoreRec {
    { s : StoreRec | no e.of.datum and e.of in s.like }
}

-- candidates: the records an undecidable answer names (the reading taken above).
fun candidates[e : Exam] : set StoreRec {
    matches[e] + payloadMatches[e]
}

-- openInv: open invocations as the rebuild derives it: every intent less those a later
-- closing record names through invocation id (open invocations 3, Primitive policy 5).
fun openInv : set Intent {
    { i : Intent | no c : Closing | c.inv = i.inv and c.sn > i.sn }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writers' rules: what each record in a state may be
-- ─────────────────────────────────────────────────────────────────────────────

-- carriesIds: a record of an invocation carries its intent's kind, act key and invocation
-- id, and names the intent by intent event id (Primitive policy 11, 11a).
pred carriesIds[r : Rec] {
    one r.iev
    r.kind = r.iev.kind
    r.key = r.iev.key
    r.inv = r.iev.inv
}

-- names: an escalation names the candidates, at most intent candidates cap of them, and
-- past the cap carries the count and the range (reconcile step 3.8a, 3.9, 3.10).
pred names[c : Escalated, ps : set StoreRec] {
    c.cands in ps
    #c.cands <= Deploy.candCap
    #ps <= Deploy.candCap implies (c.cands = ps and no c.overCap)
    #ps > Deploy.candCap implies some c.overCap
}

-- intentWrites: [Open]'s intent: of a served kind (open step 1.9), under the caller's
-- actor reference, which is not the kind's service identity (open step 1.2), carrying
-- invocation id, kind and act key (Primitive policy 11).
pred intentWrites[i : Intent] {
    i.writer = Invocation
    no i.iev and no i.ex
    one i.kind and one i.key and one i.inv
    some i.kind.served
    i.attester not in i.kind.service
}

-- invocationWrites: [Close]'s outcome or [Refuse]'s refusal, under the caller's actor
-- reference (close 1, refuse step 3.1), written only where the re-read finds no closing
-- naming the invocation id (close step 2.2, 2.3, 3.1, refuse step 2.2, 2.3); an outcome's
-- action reference is one of the kind's (close 6); the invocation's own outcome carries no
-- recovery, resolving actor or acting actor reference (Term recovery).
pred invocationWrites[r : Rec] {
    r in Outcome + Refused
    carriesIds[r]
    no r.ex
    r.attester = r.iev.attester
    no r.resolver and no r.recovery and no r.acting and no r.supersedes and no r.opNow
    r in Outcome implies r.oref in r.kind.outRefs
    no closingsBelow[r.iev.inv, r.sn]
}

-- sweepWrites: a run's write for an act it examined, under the kind's service identity
-- (reconcile step 3.2a, 3.2b, 3.5a, 3.8a; service identity 1a: none where the kind declares
-- none), only where the step-2 re-read finds no closing (reconcile step 2.5), never on an
-- unavailable probe (reconcile step 3.13a); a recovery_intended then the recovered outcome on
-- committed (reconcile step 3.2), an escalation on not-committed (3.5), undecidable (3.8) or
-- an unrecordable outcome (3.20). Its arms are these; it writes no abandoned record.
pred sweepWrites[r : Rec] {
    r in RecIntended + Outcome + Escalated
    one r.ex
    r.iev = r.ex.of
    carriesIds[r]
    some r.kind.service
    r.attester = r.kind.service
    r.ex.ans != Unavailable
    no closingsBelow[r.iev.inv, r.sn]
    r in Closing implies (no r.resolver and no r.supersedes and no r.opNow)
    r in RecIntended implies (r.ex.ans = Committed and some r.plan)
    r in Outcome implies {
        r.ex.ans = Committed
        r.oref = r.ex.hit.sref and r.odata = r.ex.hit.sdata          -- Term recovered outcome payload
        some r.recovery and r.acting = r.iev.attester                 -- Term recovered outcome payload
        some ri : RecIntended | ri.ex = r.ex and ri.sn < r.sn         -- reconcile step 3.2a before 3.2b
    }
    r in Escalated implies {
        (r.ex.ans = NotCommitted and r.ecause = NotObserved and no r.cands and no r.overCap)
        or (r.ex.ans = Undecidable and r.ecause = CUndecidable and names[r, candidates[r.ex]])
        or (r.ex.ans = Committed and r.ecause = OutcomeUnrecordable and no r.cands and no r.overCap)
    }
}

-- operatorWrites: [Resolve]'s closing, one of the three dispositions (resolve 1), of a
-- served kind (resolve 33), under the operator's own credential with recovery, resolving
-- actor and the original caller in acting actor reference (resolve 21), never under a
-- service identity (service identity 3); over the standing closing it names that closing
-- in supersedes (resolve 13 through 16, 36), refused where a refusal or an invocation's or
-- the sweep's outcome stands (resolve 9); an abandonment only for an elapsed intent at the
-- operator's reading (resolve 18, 19, 32); an outcome's reference the kind's (resolve 31);
-- candidates within the cap (resolve 28).
pred operatorWrites[r : Rec] {
    r in Outcome + Abandoned + Escalated
    carriesIds[r]
    no r.ex
    some r.kind.served
    some r.resolver and r.attester = r.resolver and r.resolver not in Kind.service
    some r.recovery and r.acting = r.iev.attester
    r in Outcome implies r.oref in r.kind.outRefs
    r in Escalated implies #r.cands <= Deploy.candCap
    let s = standingBelow[r.iev.inv, r.sn] {
        no s implies no r.supersedes
        (some s and s in Escalated) implies r.supersedes = s
        (some s and s in Abandoned) implies (r in Outcome and r.supersedes = s)
        (some s and s in Outcome and some s.resolver) implies (r in Outcome and r.supersedes = s)
        not (some s and s in Refused)
        not (some s and s in Outcome and no s.resolver)
    }
    r in Abandoned implies (one r.opNow and examineEdge[r.iev] <= r.opNow)
    r not in Abandoned implies no r.opNow
}

-- examWrites: a run keeps an aged intent of a served kind short of its horizon edge, and no
-- other (reconcile step 1.2, 1.3), and probes it: a read rejection is unavailable (act
-- probe 4); committed only where exactly one record matches the pairing datum, carries the
-- act key and re-derives one of the kind's outcome refs (act probe 2, 8, 9; pairing datum
-- 2, 6a); undecidable where more than one matches or the payload matches (act probe 3a),
-- and only then or where the outcome's datum exists only in memory (act probe 3, 7).
pred examWrites[e : Exam] {
    some e.of.kind.served
    examineEdge[e.of] <= e.inRun.now
    e.inRun.now < horizonEdge[e.of]
    some e.storeDown implies e.ans = Unavailable
    e.ans = Committed implies {
        one matches[e] and e.hit = matches[e]
        some e.hit.skey and e.hit.skey = e.of.key
        e.hit.sref in e.of.kind.outRefs
    }
    e.ans != Committed implies no e.hit
    (no e.storeDown and (#matches[e] > 1 or some payloadMatches[e] or some e.memOnly)) implies e.ans = Undecidable
    e.ans = Undecidable implies (#matches[e] > 1 or some payloadMatches[e] or some e.memOnly)
}

-- ActConds, InstConds: which of the six conditions is an act finding and which an instance
-- finding (the six conditions).
fun ActConds : set Cond { ClosureAtRisk + UnboundKind + EscalatedCond }
fun InstConds : set Cond { JournalUnavailable + StoreUnavailable + CredentialRefused }

-- findingWrites: the register writes a finding as exactly one of an act finding — kind,
-- act key, invocation id, first seen, no last seen — and an instance finding — first seen
-- and last seen, no act key or invocation id (findings 4, Term act finding, Term instance
-- finding); journal-unavailable names no kind, store-unavailable and credential-refused
-- name one (the six conditions).
pred findingWrites[f : Finding] {
    f.cond in ActConds implies
        (one f.fkind and one f.fkey and one f.finv and one f.firstSeen and no f.lastSeen)
    f.cond in InstConds implies
        (no f.fkey and no f.finv and one f.firstSeen and lone f.lastSeen)   -- BUG: last seen optional
    f.cond = JournalUnavailable implies no f.fkind
    f.cond in StoreUnavailable + CredentialRefused implies one f.fkind
}

-- conforms: every record in the state is one its writer's rules let it write.
pred conforms {
    all i : Intent | intentWrites[i]
    all r : Rec - Intent |
        (r.writer = Invocation and invocationWrites[r])
        or (r.writer = Sweep and sweepWrites[r])
        or (r.writer = Operator and operatorWrites[r])
    all e : Exam | examWrites[e]
    all f : Finding | findingWrites[f]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the composition's writers can leave that violates
-- this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_2_1: two unsuperseded closing records do not name one invocation id.
assert A_Invariant_2_1 {
    conforms implies all v : InvId |
        lone { c : Closing | c.inv = v and no d : Closing | c in d.supersedes }
}
check A_Invariant_2_1 for 3 but 5 Int

-- A_Invariant_2_3: two sweep closings do not name one invocation id, so two runs do not
-- close one act.
assert A_Invariant_2_3 {
    conforms implies all v : InvId | lone { c : Closing | c.writer = Sweep and c.inv = v }
}
check A_Invariant_2_3 for 3 but 5 Int

-- A_Invariant_3_1: every record carries one invocation id, and a record of an invocation
-- carries the invocation id of the intent it names.
assert A_Invariant_3_1 {
    conforms implies all r : Rec | one r.inv and (r not in Intent implies r.inv = r.iev.inv)
}
check A_Invariant_3_1 for 3 but 5 Int

-- A_Invariant_3_2: the join that rebuilds open invocations, pairing on invocation id, leaves
-- open exactly the intents no closing names by intent event id.
assert A_Invariant_3_2 {
    conforms implies openInv = { i : Intent | no c : Closing | c.iev = i }
}
check A_Invariant_3_2 for 3 but 5 Int

-- A_Invariant_3_3_3_4: a committed probe answer reads a database record whose pairing datum
-- equals the intent's, the only record carrying it; no stamp decides the pairing.
assert A_Invariant_3_3_3_4 {
    conforms implies all e : Exam | e.ans = Committed implies {
        some e.of.datum
        e.hit.sdatum = e.of.datum
        one { s : StoreRec | s.sdatum = e.of.datum }
    }
}
check A_Invariant_3_3_3_4 for 3 but 5 Int

-- A_Invariant_3_5a: where the intent's pairing datum is none, or more than one database
-- record carries it, the sweep writes no outcome for the act, and its closing is an
-- escalation naming the candidates (within the cap, the count and range past it).
assert A_Invariant_3_5a {
    conforms implies all e : Exam |
        (no e.of.datum or #{ s : StoreRec | s.sdatum = e.of.datum } > 1) implies {
            no o : Outcome | o.ex = e
            all c : Closing | c.ex = e implies {
                c in Escalated
                c.cands in candidates[e]
                #candidates[e] <= Deploy.candCap implies c.cands = candidates[e]
                #candidates[e] > Deploy.candCap implies some c.overCap
            }
        }
}
check A_Invariant_3_5a for 3 but 5 Int

-- A_Invariant_4_4: a journal outage is surfaced as the instance finding journal-unavailable,
-- naming no act key, invocation id or kind — never as the outage's intents.
assert A_Invariant_4_4 {
    conforms implies all f : Finding | f.cond = JournalUnavailable implies
        (no f.finv and no f.fkey and no f.fkind)
}
check A_Invariant_4_4 for 3 but 5 Int

-- A_Invariant_4_5: the outage finding carries first seen and last seen.
assert A_Invariant_4_5 {
    conforms implies all f : Finding | f.cond = JournalUnavailable implies
        (some f.firstSeen and some f.lastSeen)
}
check A_Invariant_4_5 for 3 but 5 Int

-- A_Invariant_4_8: a sweep closing for an act whose probe answered not-committed or
-- undecidable is an escalation.
assert A_Invariant_4_8 {
    conforms implies all c : Closing |
        (c.writer = Sweep and c.ex.ans in NotCommitted + Undecidable) implies c in Escalated
}
check A_Invariant_4_8 for 3 but 5 Int

-- A_Invariant_4_9: the sweep writes no abandoned record; every abandoned record carries a
-- resolving actor (Check 6.4's reading).
assert A_Invariant_4_9 {
    conforms implies all a : Abandoned | a.writer != Sweep and some a.resolver
}
check A_Invariant_4_9 for 3 but 5 Int

-- A_Invariant_5_1: every outcome the sweep writes has a recovery_intended record of the
-- invocation, plan set, at a lower sequence number.
assert A_Invariant_5_1 {
    conforms implies all o : Outcome | o.writer = Sweep implies
        some ri : RecIntended | ri.inv = o.inv and some ri.plan and ri.sn < o.sn
}
check A_Invariant_5_1 for 3 but 5 Int

-- A_Invariant_5_2: every outcome the sweep writes is attested by the kind's service
-- identity, carries recovery, and carries the original caller in acting actor reference.
assert A_Invariant_5_2 {
    conforms implies all o : Outcome | o.writer = Sweep implies {
        o.attester = o.kind.service
        some o.recovery
        o.acting = o.iev.attester
    }
}
check A_Invariant_5_2 for 3 but 5 Int

-- A_Invariant_5_3: every outcome the sweep writes carries the action reference and data a
-- committed probe answer re-derived from the database, and nothing else.
assert A_Invariant_5_3 {
    conforms implies all o : Outcome | o.writer = Sweep implies {
        o.ex.ans = Committed
        o.oref = o.ex.hit.sref
        o.odata = o.ex.hit.sdata
    }
}
check A_Invariant_5_3 for 3 but 5 Int

-- A_Invariant_5_4: every outcome an operator writes carries the operator's attestation,
-- resolving actor, and the original caller in acting actor reference.
assert A_Invariant_5_4 {
    conforms implies all o : Outcome | o.writer = Operator implies {
        some o.resolver
        o.attester = o.resolver
        o.acting = o.iev.attester
    }
}
check A_Invariant_5_4 for 3 but 5 Int

-- A_Invariant_5_8: an operator's abandonment names an elapsed intent at the operator's own
-- reading of now.
assert A_Invariant_5_8 {
    conforms implies all a : Abandoned | a.writer = Operator implies
        (one a.opNow and examineEdge[a.iev] <= a.opNow)
}
check A_Invariant_5_8 for 3 but 5 Int

-- A_Invariant_5_9: an act whose probe answered undecidable is closed by the sweep, if at
-- all, as an escalation naming the candidates.
assert A_Invariant_5_9 {
    conforms implies all e : Exam | e.ans = Undecidable implies
        all c : Closing | c.ex = e implies {
            c in Escalated
            c.cands in candidates[e]
            #candidates[e] <= Deploy.candCap implies c.cands = candidates[e]
        }
}
check A_Invariant_5_9 for 3 but 5 Int

-- A_Invariant_5_10: the sweep writes no closing for an act whose database answered
-- unavailable.
assert A_Invariant_5_10 {
    conforms implies all c : Closing | c.writer = Sweep implies c.ex.ans != Unavailable
}
check A_Invariant_5_10 for 3 but 5 Int

-- A_Invariant_7_1: no run examines an in-flight intent: every examined intent's examine
-- edge is at or before the run's reading.
assert A_Invariant_7_1 {
    conforms implies all e : Exam | examineEdge[e.of] <= e.inRun.now
}
check A_Invariant_7_1 for 3 but 5 Int

-- A_Invariant_7_2: a run examines an intent only while its reading precedes the intent's
-- horizon edge.
assert A_Invariant_7_2 {
    conforms implies all e : Exam | e.inRun.now < horizonEdge[e.of]
}
check A_Invariant_7_2 for 3 but 5 Int

-- A_Invariant_7_3: no run examines an intent whose payload the substrate had destroyed.
assert A_Invariant_7_3 {
    conforms implies all e : Exam | e.of not in e.inRun.gone
}
check A_Invariant_7_3 for 3 but 5 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Runs (non-vacuity: each shape the page admits)
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowInvocationOutcome: the invocation closes its own act through [Close].
run ShowInvocationOutcome {
    conforms
    some o : Outcome | o.writer = Invocation
} for 3 but 5 Int

-- ShowRefused: the invocation closes a pre-commit refusal through [Refuse].
run ShowRefused {
    conforms
    some r : Refused | r.writer = Invocation
} for 3 but 5 Int

-- ShowSweepRecovered: the sweep writes a recovery_intended, then the recovered outcome.
run ShowSweepRecovered {
    conforms
    some o : Outcome | o.writer = Sweep
} for 3 but 5 Int

-- ShowRecoveryIntendedAlone: a recovery_intended with no outcome after it (the run died, or
-- left the outcome for the next run).
run ShowRecoveryIntendedAlone {
    conforms
    some ri : RecIntended | no o : Outcome | o.inv = ri.inv
} for 3 but 5 Int

-- ShowNotObserved: the probe answered not-committed; the sweep escalates as not-observed.
run ShowNotObserved {
    conforms
    some c : Escalated | c.writer = Sweep and c.ecause = NotObserved
} for 3 but 5 Int

-- ShowUndecidableOverCap: two records carry the pairing datum, the cap is one; the
-- escalation names one candidate and carries the count and range.
run ShowUndecidableOverCap {
    conforms
    some c : Escalated | c.writer = Sweep and some c.overCap and some c.cands
} for 3 but 5 Int

-- ShowPayloadMatch: pairing datum none, a record matches the payload; the sweep escalates
-- it as a candidate.
run ShowPayloadMatch {
    conforms
    some c : Escalated | c.writer = Sweep and no c.iev.datum and some c.cands
} for 3 but 5 Int

-- ShowOutcomeUnrecordable: the outcome write was refused; the sweep escalates as
-- outcome-unrecordable.
run ShowOutcomeUnrecordable {
    conforms
    some c : Escalated | c.writer = Sweep and c.ecause = OutcomeUnrecordable
} for 3 but 5 Int

-- ShowReportOnly: a kind with no service identity; the run probes a committed act and
-- writes nothing (reconcile 2).
run ShowReportOnly {
    conforms
    some e : Exam | no e.of.kind.service and e.ans = Committed and no r : Rec | r.ex = e
} for 3 but 5 Int

-- ShowStoreUnavailable: the database answered unavailable; nothing written, and the
-- instance finding store-unavailable stands for the kind.
run ShowStoreUnavailable {
    conforms
    some e : Exam | e.ans = Unavailable and (no r : Rec | r.ex = e)
    some f : Finding | f.cond = StoreUnavailable
} for 3 but 5 Int

-- ShowResolveOverEscalation: an operator settles the sweep's escalation, naming it.
run ShowResolveOverEscalation {
    conforms
    some c : Closing | c.writer = Operator and some (c.supersedes & Escalated)
} for 3 but 5 Int

-- ShowOperatorAbandon: an operator abandons an elapsed intent no closing stood for.
run ShowOperatorAbandon {
    conforms
    some a : Abandoned | a.writer = Operator
} for 3 but 5 Int

-- ShowOutcomeOverAbandonment: an operator's outcome supersedes an operator's abandonment.
run ShowOutcomeOverAbandonment {
    conforms
    some o : Outcome | o.writer = Operator and some (o.supersedes & Abandoned)
} for 3 but 5 Int

-- ShowOperatorCorrection: an operator corrects an operator's outcome by an outcome naming it.
run ShowOperatorCorrection {
    conforms
    some o : Outcome | o.writer = Operator and some (o.supersedes & Outcome)
} for 3 but 5 Int

-- ShowTwoOpenIntents: two open intents of one act (open invocations 2 admits it under no
-- service identity; [Open]'s pre-check is not modelled here).
run ShowTwoOpenIntents {
    conforms
    some disj i, j : openInv | i.kind = j.kind and i.key = j.key and no i.kind.service
} for 3 but 5 Int

-- ShowOutageFinding: the instance finding journal-unavailable with its span.
run ShowOutageFinding {
    conforms
    some f : Finding | f.cond = JournalUnavailable
} for 3 but 5 Int

-- ShowClosureAtRisk: the act finding closure-at-risk names the act's invocation.
run ShowClosureAtRisk {
    conforms
    some f : Finding | f.cond = ClosureAtRisk
} for 3 but 5 Int

-- ShowEscalationFieldsOpen: FOUND 1 — a sweep escalation carrying recovery and acting
-- actor reference, which Term as the substrate measures a payload sizes and reconcile step
-- 3.5a and 3.8a do not list.
run ShowEscalationFieldsOpen {
    conforms
    some c : Escalated | c.writer = Sweep and some c.recovery and some c.acting
} for 3 but 5 Int

-- ShowNotCommittedWithMatch: FOUND 2 — the probe answers not-committed though exactly one
-- record carries the intent's pairing datum and its act key; the sweep escalates it as
-- not-observed.
run ShowNotCommittedWithMatch {
    conforms
    some e : Exam, c : Escalated |
        e.ans = NotCommitted and one matches[e] and matches[e].skey = e.of.key
        and c.ex = e and c.ecause = NotObserved
} for 3 but 5 Int
