-- audit-trail-buggy-attestation-deleted.als
-- DELIBERATELY WRONG twin of audit-trail.als (unit: compositions/audit-trail.md formal layer).
--
-- INJECTED DEFECT: [Record Destruction] deletes the attestation its pair names (Composes 8).
--
-- BREAKS: A_Invariant_1_7a.
-- Everything else is audit-trail.als as written; read its comments there.

module audit_trail_buggy_attestation_deleted

open util/integer

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- EventId: an opaque event id, as Event Log answers it at append and as a caller names it
-- to the reads. An id may name nothing any constituent has heard of (Invariant 8.5).
sig EventId {}

-- Ref: an action reference or an actor reference, compared by identity only (the page's
-- byte-for-byte match, Invariant 1.6a).
sig Ref {}

-- Instant: an attestation instant, present or absent; the model never orders instants.
sig Instant {}

-- RecordSet: a byte-exact record set — what a seal committed, or what a caller re-presents
-- to [Verify Record] (Term original event payload, Term verify-time presentation).
sig RecordSet {}

-- RState: the two retention states (Term retention state).
abstract sig RState {}
one sig Retained, Purged extends RState {}

-- TailMode: the deployment's unsealed tail mode, strict or lenient (verify record step 4.4, 4.5).
abstract sig TailMode {}
one sig Strict, Lenient extends TailMode {}

-- Deployment: the one instance's declared configuration the reads consult.
one sig Deployment {
    tailMode : one TailMode
}

-- CallKind: how a [Record Action] that wrote something ended: answered with its event id,
-- or refused at step 3 or step 4 with the partial state record action step 7.11 keeps.
abstract sig CallKind {}
one sig Answered, RefusedAtStep3, RefusedAtStep4 extends CallKind {}

-- RecordCall: one [Record Action] call that wrote something, with the action reference and
-- actor reference it was given (record_action(action_ref, actor_ref, credential, data)).
sig RecordCall {
    actionIn : one Ref,
    actorIn  : one Ref,
    kind     : one CallKind
}

-- Attestation: one attestation record of the composition's Actor Identity instance, with
-- its surviving fields (Term surviving fields; its id is the atom itself) and the call whose
-- step 2 attested it.
sig Attestation {
    actionRef  : lone Ref,
    actorRef   : lone Ref,
    instant    : lone Instant,
    attestedBy : one RecordCall
}

-- Kept: the attestations the attestation records still hold. The composition deletes none
-- (Composes 8), which the build says, not a fact: a deletion is a twin.
sig Kept in Attestation {}

-- Event: one entry of the audit log: its id and sequence number (Event Log's), the full
-- constructed payload's attestation id, action reference and actor reference (Term full
-- constructed payload), event to attestation's entry for it if the entry stands (a lost
-- entry is a rebuild trigger, record action step 5.9), and the call that appended it.
sig Event {
    id            : one EventId,
    seqNo         : one Int,
    payloadAtt    : lone Attestation,
    payloadAction : lone Ref,
    payloadActor  : lone Ref,
    idxAtt        : lone Attestation,
    appendedBy    : one RecordCall
}

-- Unreadable: the events whose data is unreadable — destroyed by the erasure mechanism
-- Defensible Retention delegates to, or a payload storage cannot read. An input here.
sig Unreadable in Event {}

-- Retention: one retention record: its record reference (the event id it governs, record
-- action step 4.3), its state, the [Record Action] that placed it (none for the third
-- half's compensating placement), and, for a compensating placement, the retentions over
-- its event its re-read under the critical section saw (Third half 6); and the retentions
-- committed before it.
sig Retention {
    recRef   : one EventId,
    state    : one RState,
    placedBy : lone RecordCall,
    seen     : set Retention,
    prior    : set Retention
}

-- Seal: one seal record with its coverage entry: the slice it sealed (first and last
-- sequence number, seal coverage 13), the seals whose ranges its [Seal Now] read sealed
-- through from, the record set it committed, and the seals committed before it.
sig Seal {
    low         : one Int,
    high        : one Int,
    found       : set Seal,
    committed   : one RecordSet,
    sealsBefore : set Seal
}

-- DestructionRecord: what [Record Destruction] step 2 writes for one event (Term destruction
-- record): the event it resolved, the retention its step 1 purged, the pair (event id,
-- attestation id), and the seal whose purged events it adds the event's sequence number to.
sig DestructionRecord {
    event     : one Event,
    retention : one Retention,
    pairId    : one EventId,
    pairAtt   : lone Attestation,
    seal      : lone Seal
}

-- Hold: a legal hold over an event id, which leaves a Purged retention's cascade open
-- (Term event standing: held). Defensible Retention's and Legal Hold's; an input here.
sig Hold {
    over : one EventId
}

-- AttAnswer: what ActorIdentity.verify answers [Verify Record] step 3. The atom's; any.
abstract sig AttAnswer {}
one sig AttVerified, AttFailed, AttNotKnown, AttRegistryUnavailable extends AttAnswer {}

-- SealAnswer: what TamperEvidence.verify answers [Verify Record] step 5. The atom's; bound
-- only by the fact TamperEvidenceBindsRecordSet below.
abstract sig SealAnswer {}
one sig SealVerified, SealFailed, SealNotKnown, SealUnavailable extends SealAnswer {}

-- ReadQuery: one read_record(event_id) call against the state.
sig ReadQuery {
    rid : one EventId
}

-- VerifyQuery: one verify_record(event_id, original_event_payload) call: the id, the record
-- set the caller re-presents, the two constituents' answers, and the record set step 5
-- hands TamperEvidence.verify where step 5 runs.
sig VerifyQuery {
    vid        : one EventId,
    presented  : one RecordSet,
    attAnswer  : one AttAnswer,
    sealAnswer : one SealAnswer,
    sealArg    : lone RecordSet
}

-- RAnswer: what [Read Record] lands: the audit record with data (a live event), the audit
-- record with no data (a Purged one, read record step 4.4c), not-known, or no answer (an
-- unreadable payload standing as an outage of Event Log).
abstract sig RAnswer {}
one sig RecordWithData, RecordNoData, RNotKnown, RNoAnswer extends RAnswer {}

-- VOutcome: what [Verify Record] lands: verified, each failed-verification(reason) and
-- unverifiable(reason) the steps name, not-known, or no answer (an outage).
abstract sig VOutcome {}
one sig Verified, FailPurged, FailAttestation, FailAttestationNotKnown, FailUnsealed,
        FailSeal, FailSealNotKnown, UnverifiablePartlyPurged, UnverifiableRegistry,
        UnverifiableMechanism, VNotKnown, VNoAnswer extends VOutcome {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- Event Log assigns each appended event its own event id and its own sequence number,
-- counted from one (Event Log Invariants 3 and 4, total order and monotonicity).
fact EventLogAssigns {
    all disj e1, e2 : Event | e1.id != e2.id and e1.seqNo != e2.seqNo
    all e : Event | e.seqNo >= 1
}

-- ActorIdentity.attest records the action reference and actor reference it was given and
-- stamps its instant (Actor Identity Invariants 2 and 3, action and actor binding).
fact AttestRecordsItsInputs {
    all a : Attestation {
        a.actionRef = a.attestedBy.actionIn
        a.actorRef  = a.attestedBy.actorIn
        some a.instant
    }
}

-- The retention records and the seal records each commit in one serial order, the order
-- of the one database the instance runs on (Execution Contract Database 1, 2): `prior`
-- and `sealsBefore` are strict total orders.
fact OneCommitOrder {
    all r : Retention | r not in r.prior and r.prior.prior in r.prior
    all disj a, b : Retention | a in b.prior or b in a.prior
    all s : Seal | s not in s.sealsBefore and s.sealsBefore.sealsBefore in s.sealsBefore
    all disj a, b : Seal | a in b.sealsBefore or b in a.sealsBefore
}

-- A [Record Action]'s writes commit together (Execution Contract Database 1), so the
-- retention it placed commits before any later run of the third half can read its event:
-- a compensating placement over the same event id commits after it.
fact RecordActionCommitsTogether {
    all r1, r2 : Retention |
        (some r1.placedBy and no r2.placedBy and r1.recRef = r2.recRef) implies r1 in r2.prior
}

-- TamperEvidence.verify answers verified only for the record set the seal committed
-- (Tamper Evidence Invariant 3, record-set binding; 4, self-containment).
fact TamperEvidenceBindsRecordSet {
    all q : VerifyQuery | (q.sealAnswer = SealVerified and some q.sealArg)
        implies q.sealArg in coveringOf[q.vid].committed
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers: the page's lookups and terms over one state
-- ─────────────────────────────────────────────────────────────────────────────

-- evOf: the log entry an event id resolves to (event to sequence, rebuilt on a miss).
fun evOf[i : EventId] : set Event { id.i }

-- retOf: the retention over an event id (event to retention, rebuilt on a miss).
fun retOf[i : EventId] : set Retention { recRef.i }

-- drOf: the destruction record written for an event id.
fun drOf[i : EventId] : set DestructionRecord { event.id.i }

-- covering: the seals whose slice holds the event's sequence number (Term covering seal).
fun covering[e : Event] : set Seal {
    { s : Seal | s.low <= e.seqNo and e.seqNo <= s.high }
}

-- coveringOf: the covering seal of the event an id names.
fun coveringOf[i : EventId] : set Seal {
    { s : Seal | some e : evOf[i] | s in covering[e] }
}

-- purgedEvents: a seal's purged events — the sequence numbers the destruction records
-- naming it added (Term purged events, record destruction step 2.2).
fun purgedEvents[s : Seal] : set Int { (seal.s).event.seqNo }

-- sealedThrough: the greatest sequence number any seal covers; zero for no seal.
fun sealedThrough : Int { (no Seal) => 0 else max[Seal.high] }

-- e2a: event to attestation's entry for an event, read as a reader reads it: the
-- destruction record's pair where one names the event (event to attestation 3), else the
-- stored entry, else the rebuild from a readable payload (event to attestation 2b).
fun e2a[e : Event] : lone Attestation {
    (some drOf[e.id]) => drOf[e.id].pairAtt
    else ((some e.idxAtt) => e.idxAtt
          else ((e not in Unreadable) => e.payloadAtt else none))
}

-- reachable: the event's records can be read — its data is readable or a destruction
-- record names it. An unreadable payload no destruction record names is an outage of Event
-- Log (Term dependency outage), so no act over it is at quiescence.
pred reachable[e : Event] { e not in Unreadable or some drOf[e.id] }

-- purgedId / retainedId: the retention over the id stands in Purged / Retained.
pred purgedId[i : EventId]   { Purged in retOf[i].state }
pred retainedId[i : EventId] { Retained in retOf[i].state }

-- readableId / unreadableId: a log entry exists for the id and its data is (not) unreadable.
pred readableId[i : EventId]   { some evOf[i] and evOf[i] not in Unreadable }
pred unreadableId[i : EventId] { some evOf[i] and evOf[i] in Unreadable }

-- partly: the covering seal's purged events are not empty and do not hold the event's own
-- sequence number (Term partly-purged coverage).
pred partly[i : EventId] {
    some coveringOf[i]
    some purgedEvents[coveringOf[i]]
    evOf[i].seqNo not in purgedEvents[coveringOf[i]]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Part A — the writes: what each admitted write leaves
-- ─────────────────────────────────────────────────────────────────────────────

-- recordActionWrites: what one [Record Action] leaves: step 2's attestation always; step
-- 3's event carrying the full constructed payload unless step 3 refused; step 4's retention
-- over the event id and step 5's index entry only for an answered call (record action step
-- 2.1, 3.1, 4.3, 5.1, 7.10, 7.11).
pred recordActionWrites[c : RecordCall] {
    one attestedBy.c
    let a = attestedBy.c, ev = appendedBy.c, rs = placedBy.c {
        c.kind = RefusedAtStep3 implies (no ev and no rs)
        c.kind != RefusedAtStep3 implies {
            one ev
            ev.payloadAtt    = a
            ev.payloadAction = c.actionIn
            ev.payloadActor  = c.actorIn
        }
        c.kind = RefusedAtStep4 implies (no rs and no ev.idxAtt)
        c.kind = Answered implies {
            one rs
            rs.recRef = ev.id
            ev.idxAtt in a
        }
    }
}

-- placementWritten: a retention is placed by an answered [Record Action] (above) or by the
-- third half: over an event the full enumeration returned (Third half 1), after a re-read
-- under the critical section held through the placement, which sees every retention over
-- the event committed before it (Third half 5 to 7), and only on a true miss (Term true miss).
pred placementWritten[r : Retention] {
    some r.placedBy implies no r.seen
    no r.placedBy implies {
        some evOf[r.recRef]
        r.seen = { x : r.prior | x.recRef = r.recRef }
        no x : r.seen | x.recRef = r.recRef
    }
}

-- sealWritten: [Seal Now] reads sealed through from every seal committed before it (seal
-- now 17, 18), cuts the slice from sealed through + 1 to the tail position (Term slice,
-- Term tail position: an event's sequence number) and seals it. Sequence numbers count
-- from one, so a slice starts at one or above (the model's integers wrap past their top).
pred sealWritten[s : Seal] {
    s.found = s.sealsBefore
    s.low = ((no s.found) => 1 else plus[max[s.found.high], 1])
    s.low >= 1
    s.high >= s.low
    some e : Event | e.seqNo = s.high
}

-- destructionWritten: [Record Destruction]'s two steps in one transaction (Invariant 4.2):
-- step 1 purges the event's retention; step 2 writes the pair, read from event to
-- attestation with rebuild-on-miss (refusing where none is found, step 2.3b), and adds the
-- event's sequence number to its covering seal's purged events (step 2.2). The record is
-- written before the content is destroyed (Defensible Retention purge event step 2.4), so
-- the rebuild reads the payload.
pred destructionWritten[d : DestructionRecord] {
    d.retention = retOf[d.event.id]
    d.retention.state = Purged
    d.pairId = d.event.id
    d.pairAtt = ((some d.event.idxAtt) => d.event.idxAtt else d.event.payloadAtt)
    some d.pairAtt
    one d.seal
    d.seal = covering[d.event]
}

-- built: every record in the state is what an admitted write left (Composes 4a: no other
-- writer reaches the four instances): each call's writes, each placement, each seal, each
-- destruction record; one destruction record per event (a repeat adopts the one written,
-- record destruction step 2.6, 2.7); a retention reaches Purged only through [Record
-- Destruction] (Composes 10); no attestation is deleted (Composes 8).
pred built {
    all c : RecordCall | recordActionWrites[c]
    all r : Retention | placementWritten[r]
    all s : Seal | sealWritten[s]
    all d : DestructionRecord | destructionWritten[d]
    all disj d1, d2 : DestructionRecord | d1.event != d2.event
    all r : Retention | r.state = Purged implies some retention.r
    Kept in Attestation
    Attestation - DestructionRecord.pairAtt in Kept -- DEFECT: a purged event's attestation may be deleted
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Part B — the reads: what [Read Record] and [Verify Record] land over one state
-- ─────────────────────────────────────────────────────────────────────────────

-- frame: the states the reads are asked over: each id names at most one event, retention
-- and destruction record, each retention names a log entry, each event has at most one
-- covering seal. Part A's writes leave only such states (Invariant 2.4a, 3.1; a retention is
-- placed only over an appended event, and the log removes nothing). The page gives neither
-- read an answer for a retention whose event id resolves to no log entry (read record step
-- 3.3 alerts; no step of either read lands), so without that clause A_Invariant_6_1 and
-- A_Invariant_6_2 fail: the page relies on the writes, not on the reads, for it.
pred frame {
    all i : EventId | lone evOf[i] and lone retOf[i] and lone drOf[i]
    all r : Retention | some evOf[r.recRef]
    all e : Event | lone covering[e]
}

-- rPurged / rRetained: the retention state the reads act on, as they read it from the
-- retention record through event to retention (read record step 1.1, verify record step
-- 1.1). The checks below state the record's own state (purgedId, retainedId).
pred rPurged[i : EventId]   { purgedId[i] }
pred rRetained[i : EventId] { retainedId[i] }

-- readAnswers: every answer a rule of [Read Record] lands for the call, rule by rule. In
-- one state the re-read of step 4.5 finds the retention the first read found.
fun readAnswers[q : ReadQuery] : set RAnswer {
    let i = q.rid |
        ((no retOf[i] and no evOf[i]) => RNotKnown else none)                         -- step 3.1
      + ((rRetained[i] and readableId[i]) => RecordWithData else none)               -- step 4.1
      + ((rPurged[i] and (some drOf[i] or readableId[i])) => RecordNoData else none) -- step 4.4i, 4.4c
      + ((rPurged[i] and no drOf[i] and unreadableId[i]) => RNoAnswer else none)    -- step 4.4h
      + ((rRetained[i] and unreadableId[i]) => RNoAnswer else none)                  -- step 4.5, 4.7
      + ((no retOf[i] and readableId[i]) => RecordWithData else none)                 -- step 5.1
      + ((no retOf[i] and unreadableId[i]) => RNoAnswer else none)                    -- step 5.3
}

-- v2Proceed: [Verify Record] passes steps 1 and 2 to step 3: the retention is not Purged
-- (step 1.2, 1.3) and a log entry with readable data exists (step 2.3, 2.7).
pred v2Proceed[i : EventId] { not rPurged[i] and readableId[i] }

-- v3Ok: step 3's attestation check answered verified (step 3.8).
pred v3Ok[q : VerifyQuery] { v2Proceed[q.vid] and q.attAnswer = AttVerified }

-- runsStep5: step 5 runs: a covering seal exists and its coverage is not partly purged
-- (step 4.3, 4.4, 4.5b).
pred runsStep5[q : VerifyQuery] { v3Ok[q] and some coveringOf[q.vid] and not partly[q.vid] }

-- verifyCalls: step 5 hands TamperEvidence.verify the record set the caller presented
-- (verify record step 5.1), and nothing where step 5 does not run.
pred verifyCalls[q : VerifyQuery] {
    q.sealArg = (runsStep5[q] => q.presented else none)
}

-- verifyAnswers: every outcome a rule of [Verify Record] lands for the call, rule by rule.
fun verifyAnswers[q : VerifyQuery] : set VOutcome {
    let i = q.vid |
        (rPurged[i] => FailPurged else none)                                                   -- step 1.2
      + ((not rPurged[i] and no retOf[i] and no evOf[i]) => VNotKnown else none)               -- step 2.2
      + ((not rPurged[i] and unreadableId[i]) => VNoAnswer else none)                          -- step 2.6
      + ((v2Proceed[i] and q.attAnswer = AttFailed) => FailAttestation else none)               -- step 3.2
      + ((v2Proceed[i] and q.attAnswer = AttNotKnown) => FailAttestationNotKnown else none)     -- step 3.4
      + ((v2Proceed[i] and q.attAnswer = AttRegistryUnavailable) => UnverifiableRegistry else none) -- step 3.3, 6.1
      + ((v3Ok[q] and partly[i]) => UnverifiablePartlyPurged else none)                         -- step 4.2
      + ((v3Ok[q] and no coveringOf[i] and Deployment.tailMode = Strict) => FailUnsealed else none) -- step 4.4
      + ((runsStep5[q] and q.sealAnswer = SealFailed) => FailSeal else none)                    -- step 5.2
      + ((runsStep5[q] and q.sealAnswer = SealNotKnown) => FailSealNotKnown else none)          -- step 5.4
      + ((runsStep5[q] and q.sealAnswer = SealUnavailable) => UnverifiableMechanism else none)  -- step 5.3, 6.2
      + ((v3Ok[q] and not partly[i]
          and (no coveringOf[i] implies Deployment.tailMode = Lenient)
          and (some coveringOf[i] implies q.sealAnswer = SealVerified)) => Verified else none)  -- step 4.5, 7.1
}

-- framed: the frame, with every verify call's step 5 argument as the page writes it.
pred framed {
    frame
    all q : VerifyQuery | verifyCalls[q]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's writes can leave (Part A), or any
-- framed state (Part B), that violates this assertion? No counterexample (UNSAT) = the
-- guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_3: every appended event carries, inside its own payload, the attestation
-- id its own [Record Action] committed at step 2.
assert A_Invariant_1_3 {
    built implies all e : Event |
        some e.payloadAtt and e.payloadAtt.attestedBy = e.appendedBy
}
check A_Invariant_1_3 for 3 but 5 Int

-- A_Invariant_1_5a: for every event whose records are reachable, event to attestation's
-- entry — the stored entry, its rebuild from the payload, or the destruction record's pair —
-- names an attestation the records hold, carrying an action and an actor reference.
assert A_Invariant_1_5a {
    built implies all e : Event | reachable[e] implies {
        some e2a[e]
        e2a[e] in Kept
        some e2a[e].actionRef
        some e2a[e].actorRef
    }
}
check A_Invariant_1_5a for 3 but 5 Int

-- A_Invariant_1_6a: for a live event (no retention, or one not Purged) whose records are
-- reachable, the attestation's action and actor reference are the payload's.
assert A_Invariant_1_6a {
    built implies all e : Event | (not purgedId[e.id] and reachable[e]) implies {
        e2a[e].actionRef = e.payloadAction
        e2a[e].actorRef  = e.payloadActor
    }
}
check A_Invariant_1_6a for 3 but 5 Int

-- A_Invariant_1_7a: for a Purged event, the attestation its destruction record's pair names
-- stands in the records with its surviving fields readable.
assert A_Invariant_1_7a {
    built implies all e : Event | purgedId[e.id] implies {
        some drOf[e.id].pairAtt
        drOf[e.id].pairAtt in Kept
        some drOf[e.id].pairAtt.actionRef
        some drOf[e.id].pairAtt.actorRef
        some drOf[e.id].pairAtt.instant
    }
}
check A_Invariant_1_7a for 3 but 5 Int

-- A_Invariant_2_1: a [Record Action] that answered its event id left a retention over it.
assert A_Invariant_2_1 {
    built implies all c : RecordCall | c.kind = Answered implies some retOf[(appendedBy.c).id]
}
check A_Invariant_2_1 for 3 but 5 Int

-- A_Invariant_2_3: the third half's placement stands only over an event no retention
-- committed before it governed (a true miss), whatever its re-read saw.
assert A_Invariant_2_3 {
    built implies all r : Retention | no r.placedBy implies
        no x : r.prior | x.recRef = r.recRef
}
check A_Invariant_2_3 for 3 but 5 Int

-- A_Invariant_2_4a: no event id carries two retentions (Composes 9a), so at quiescence the
-- one the scan guarantees is exactly one.
assert A_Invariant_2_4a {
    built implies all e : Event | lone retOf[e.id]
}
check A_Invariant_2_4a for 3 but 5 Int

-- A_Invariant_3_1: every event at or below sealed through is covered by exactly one seal:
-- the ranges neither overlap nor leave a hole (seal coverage 7, 8).
assert A_Invariant_3_1 {
    built implies all e : Event | e.seqNo <= sealedThrough implies one covering[e]
}
check A_Invariant_3_1 for 3 but 5 Int

-- A_Invariant_3_2: a Purged event stays covered by exactly one seal, and that covering
-- seal's purged events hold its sequence number (its coverage status reads records-purged).
assert A_Invariant_3_2 {
    built implies all e : Event | purgedId[e.id] implies {
        one covering[e]
        e.seqNo in purgedEvents[covering[e]]
    }
}
check A_Invariant_3_2 for 3 but 5 Int

-- A_Invariant_4_5: every member of a seal's purged events names an event whose retention
-- stands in Purged.
assert A_Invariant_4_5 {
    built implies all s : Seal, n : purgedEvents[s] |
        some e : Event | e.seqNo = n and purgedId[e.id]
}
check A_Invariant_4_5 for 3 but 5 Int

-- A_Invariant_6_1: where every read answers and no unreadable payload stands as an outage
-- (read record step 4.4h, 4.7, 5.3), [Read Record] lands exactly one answer, the audit
-- record (with or without data) or not-known.
assert A_Invariant_6_1 {
    framed implies all q : ReadQuery | let i = q.rid |
        (not (retainedId[i] and unreadableId[i])
         and not (no retOf[i] and unreadableId[i])
         and not (purgedId[i] and no drOf[i] and unreadableId[i]))
        implies (one readAnswers[q] and readAnswers[q] in RecordWithData + RecordNoData + RNotKnown)
}
check A_Invariant_6_1 for 3 but 5 Int

-- A_Invariant_6_2: where every read answers and no unreadable payload under a Retained
-- retention or with no retention stands as an outage (verify record step 2.6), [Verify
-- Record] lands exactly one outcome, and it is not "no answer".
assert A_Invariant_6_2 {
    framed implies all q : VerifyQuery | let i = q.vid |
        (not (retainedId[i] and unreadableId[i]) and not (no retOf[i] and unreadableId[i]))
        implies (one verifyAnswers[q] and VNoAnswer not in verifyAnswers[q])
}
check A_Invariant_6_2 for 3 but 5 Int

-- A_Invariant_7_1: an event a seal covers is answered verified only when the caller
-- re-presented the record set that seal committed: verification needs the original.
assert A_Invariant_7_1 {
    framed implies all q : VerifyQuery |
        (Verified in verifyAnswers[q] and some coveringOf[q.vid])
        implies q.presented in coveringOf[q.vid].committed
}
check A_Invariant_7_1 for 3 but 5 Int

-- A_Invariant_7_3: the record set the seal check is handed is the one the caller
-- presented, never one the composition fetched for itself.
assert A_Invariant_7_3 {
    framed implies all q : VerifyQuery | some q.sealArg implies q.sealArg = q.presented
}
check A_Invariant_7_3 for 3 but 5 Int

-- A_Invariant_8_2b: a held event (a Purged retention a hold keeps open) is answered as a
-- purged one: [Read Record] returns no data, [Verify Record] failed-verification(purged).
assert A_Invariant_8_2b {
    framed implies all i : Hold.over | purgedId[i] implies {
        all q : ReadQuery | q.rid = i implies RecordWithData not in readAnswers[q]
        all q : VerifyQuery | q.vid = i implies verifyAnswers[q] = FailPurged
    }
}
check A_Invariant_8_2b for 3 but 5 Int

-- A_Invariant_8_4: failed-verification(purged) lands only where the retention stands in
-- Purged, never where the content is merely absent.
assert A_Invariant_8_4 {
    framed implies all q : VerifyQuery | FailPurged in verifyAnswers[q] implies purgedId[q.vid]
}
check A_Invariant_8_4 for 3 but 5 Int

-- A_Invariant_8_5: not-known, from either read, lands only for an event id neither the
-- audit log nor the retention records has heard of.
assert A_Invariant_8_5 {
    framed implies {
        all q : ReadQuery | RNotKnown in readAnswers[q] implies (no evOf[q.rid] and no retOf[q.rid])
        all q : VerifyQuery | VNotKnown in verifyAnswers[q] implies (no evOf[q.vid] and no retOf[q.vid])
    }
}
check A_Invariant_8_5 for 3 but 5 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowAnswered: an answered recording — attestation, event, retention, index entry.
run ShowAnswered {
    built and some c : RecordCall | c.kind = Answered and some (appendedBy.c).idxAtt
} for 3 but 5 Int

-- ShowAttestedOrphan: a recording refused at step 3, leaving its attestation and no event
-- (record action step 7.11; what the scan's second half reconciles).
run ShowAttestedOrphan {
    built and some c : RecordCall | c.kind = RefusedAtStep3
} for 3 but 5 Int

-- ShowCompensatingPlacement: a recording refused at step 4 left an event with no
-- retention, and the third half placed one over it.
run ShowCompensatingPlacement {
    built and some c : RecordCall, r : Retention |
        c.kind = RefusedAtStep4 and no r.placedBy and r.recRef = (appendedBy.c).id
} for 3 but 5 Int

-- ShowSealsAndTail: two seals cut one after the other and an event in the unsealed tail.
run ShowSealsAndTail {
    built and #Seal = 2 and some e : Event | e.seqNo > sealedThrough
} for 3 but 5 Int

-- ShowLawfullyDestroyed: a Purged event whose content is destroyed, its destruction record
-- on its covering seal, beside a live event under the same seal (partly purged coverage).
run ShowLawfullyDestroyed {
    built and some d : DestructionRecord, e : Event |
        d.event in Unreadable and e != d.event and not purgedId[e.id] and partly[e.id]
} for 3 but 5 Int

-- ShowIndexEntryLost: an answered recording whose event to attestation entry was lost
-- (record action step 5.9), read through the rebuild.
run ShowIndexEntryLost {
    built and some c : RecordCall | c.kind = Answered and no (appendedBy.c).idxAtt
        and some e2a[appendedBy.c]
} for 3 but 5 Int

-- ShowReadNotKnown: read_record for an id no constituent has heard of lands not-known.
run ShowReadNotKnown {
    framed and some q : ReadQuery | readAnswers[q] = RNotKnown
} for 3 but 5 Int

-- ShowReadOrphanWindow: a log entry with no retention, in its compensation window, read
-- as the audit record with retention status unresolved (read record step 5.1).
run ShowReadOrphanWindow {
    framed and some q : ReadQuery | no retOf[q.rid] and readAnswers[q] = RecordWithData
} for 3 but 5 Int

-- ShowReadDestroyed: a lawfully destroyed event read as the audit record with no data.
run ShowReadDestroyed {
    framed and some q : ReadQuery | unreadableId[q.rid] and readAnswers[q] = RecordNoData
} for 3 but 5 Int

-- ShowReadOutage: an unreadable payload under a Retained retention answers no answer.
run ShowReadOutage {
    framed and some q : ReadQuery | readAnswers[q] = RNoAnswer
} for 3 but 5 Int

-- ShowVerifiedCovered: a covered event verified against the record set its seal committed.
run ShowVerifiedCovered {
    framed and some q : VerifyQuery | some coveringOf[q.vid] and verifyAnswers[q] = Verified
} for 3 but 5 Int

-- ShowVerifiedLenientTail: an event in the unsealed tail verified under lenient mode, with
-- no seal call (verify record step 4.5).
run ShowVerifiedLenientTail {
    framed and some q : VerifyQuery | no coveringOf[q.vid] and no q.sealArg
        and verifyAnswers[q] = Verified
} for 3 but 5 Int

-- ShowFailedUnsealedStrict: the same event under strict mode fails as unsealed.
run ShowFailedUnsealedStrict {
    framed and some q : VerifyQuery | verifyAnswers[q] = FailUnsealed
} for 3 but 5 Int

-- ShowUnverifiablePartlyPurged: a live event whose covering seal is partly purged.
run ShowUnverifiablePartlyPurged {
    framed and some q : VerifyQuery | verifyAnswers[q] = UnverifiablePartlyPurged
} for 3 but 5 Int

-- ShowSealFailed: a covered event whose presented record set the seal rejects.
run ShowSealFailed {
    framed and some q : VerifyQuery | verifyAnswers[q] = FailSeal
} for 3 but 5 Int

-- ShowHeldAnsweredAsPurged: a held event, its content still readable, answered as purged.
run ShowHeldAnsweredAsPurged {
    framed and some q : VerifyQuery | q.vid in Hold.over and readableId[q.vid]
        and verifyAnswers[q] = FailPurged
} for 3 but 5 Int
