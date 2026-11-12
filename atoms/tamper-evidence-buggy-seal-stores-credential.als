-- tamper-evidence-buggy-seal-stores-credential.als
-- DELIBERATELY WRONG twin of tamper-evidence.als (unit: `atoms/tamper-evidence.md formal layer`).
--
-- INJECTED DEFECT: [Seal] keeps the mechanism credential on the evidence (State 5, Operation 5).
--
-- BREAKS: A_State_5.
-- Everything else is tamper-evidence.als as written; read its comments there.

module tamper_evidence_buggy_seal_stores_credential

open util/ordering[SealCall] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a string a call carries: a record set reference or a mechanism credential (Term
-- string cap names both). The atom never interprets an opaque reference (Identity 6,
-- Term record set reference), so a string is an uninterpreted token and two different
-- strings are two different atoms.
sig Str {}

-- Strings: which strings the guards refuse: the blank ones (Operation 6, 7) and the ones
-- longer than the string cap (Operation 34, Term string cap).
one sig Strings {
    blank   : set Str,
    overCap : set Str
}

-- Id: an evidence id, the opaque value naming one evidence (Term evidence id). The host
-- allocates it at the seam (Identity 2); the atom only records it.
sig Id {}

-- Content: what a record set holds when it is presented: the content the proof commits
-- to (Term original record set: "the proof commits to content"). The host owns what a
-- record set is (Non-goal 11); here a content is an uninterpreted token.
sig Content {}

-- Proof: the artifact the deployment's mechanism produced at the seam (Term proof, Term
-- cryptographic material), with the content it commits to.
sig Proof {
    over : one Content
}

-- MechKind: whether the deployment's mechanism takes keying material (Term unkeyed
-- mechanism: "a mechanism that is not unkeyed is keyed").
abstract sig MechKind {}

-- Keyed, Unkeyed: the two kinds.
one sig Keyed, Unkeyed extends MechKind {}

-- Anchoring: whether the deployment's mechanism anchors at seal time (Operation 4, Term
-- anchoring instant).
abstract sig Anchoring {}

-- AnchorsAtSeal, AnchorsNothing: the mechanism records an external anchor at seal time,
-- or anchors nothing.
one sig AnchorsAtSeal, AnchorsNothing extends Anchoring {}

-- Mechanism: the one mechanism the deployment declares (Capability requirement 3).
one sig Mechanism {
    kind      : one MechKind,
    anchoring : one Anchoring
}

-- FailReason: the mechanism failure reason the mechanism gives at the seam where it
-- cannot compute the proof (Term mechanism failure reason); blank (here: absent) where it
-- computes one.
abstract sig FailReason {}

-- UnreadableRecords, KeyingPrecondition, AnchorUnreachable: the three reasons.
one sig UnreadableRecords, KeyingPrecondition, AnchorUnreachable extends FailReason {}

-- Status: what an evidence's state could hold. The page's one state is sealed (Term
-- sealed); Pending is in the type so a write that parked an evidence elsewhere would
-- show. That none does is checked, never built in.
abstract sig Status {}

-- Sealed, Pending: recorded and nothing further to become; a state the page has not.
one sig Sealed, Pending extends Status {}

-- SealCall: one [Seal] call, seal(record_set_ref, mechanism_credential), with what the
-- host injects at the seam for it (Term seam): now, the evidence id it allocated, and the
-- cryptographic material the mechanism computed: the proof, the anchoring instant, or
-- the failure reason. presented is the content the record set reference named at the
-- call, the record set presented at [Seal] (Invariant 2.1, 3.1, 3.2). callerAt is an
-- instant the business caller passes beside the call, which the atom must never take
-- (Operation 25); it is in the type so a write that took it would show.
sig SealCall {
    now        : one Int,        -- the injected now
    refIn      : one Str,        -- record_set_ref
    credIn     : one Str,        -- mechanism_credential
    callerAt   : lone Int,       -- an instant the business caller passes (never taken)
    hostId     : one Id,         -- the evidence id the host allocated
    presented  : one Content,    -- the record set presented at [Seal]
    failReason : lone FailReason,-- the mechanism failure reason, absent where blank
    seamProof  : lone Proof,     -- the proof the mechanism computed, absent where none
    anchorAt   : lone Int        -- the anchoring instant the mechanism's anchor recorded
}

-- WriteRefused: the calls whose write the database refuses (Operation 10, 11).
sig WriteRefused in SealCall {}

-- Ev: one evidence record (Term evidence), as the call that wrote it left it. Every
-- field may be absent and the state is a set, so a write that forgot a field or left two
-- states would show; what the page promises (State 1, 3) is checked, never built into
-- the type. credential is the field State 5 forbids, in the type so a write that stored
-- one would show. writtenBy is the model's own: the call that recorded it.
sig Ev {
    id         : lone Id,       -- evidence id
    ref        : lone Str,      -- record set reference
    proof      : lone Proof,    -- proof
    sealedAt   : lone Int,      -- sealing instant
    anchoredAt : lone Int,      -- anchoring instant
    status     : set Status,    -- the evidence's state
    credential : lone Str,      -- a stored mechanism credential (forbidden, State 5)
    writtenBy  : one SealCall
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The mechanism computes the proof over the record set the record set reference names
-- at the call (Term cryptographic material): the proof commits to the content presented
-- at [Seal].
fact MechanismComputesTheProofOverThePresentedSet {
    all c : SealCall, p : c.seamProof | p.over = c.presented
}

-- The mechanism computes a proof exactly where it gives no failure reason (Term
-- mechanism failure reason: "blank where the mechanism computes one").
fact ProofExactlyWhereNoFailureReason {
    all c : SealCall | some c.seamProof iff no c.failReason
}

-- The seam carries an anchoring instant exactly where the mechanism anchors at seal time
-- and computed the proof (Term cryptographic material: "with the anchoring instant where
-- the mechanism anchors at seal time"; Term anchoring instant: "absent where the
-- mechanism anchors nothing").
fact AnchoringInstantOnlyFromTheAnchor {
    all c : SealCall |
        some c.anchorAt iff (Mechanism.anchoring = AnchorsAtSeal and some c.seamProof)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing action: its guards and its write
-- ─────────────────────────────────────────────────────────────────────────────

-- sealGuards: the guards an admitted [Seal] passes, but the evidence id's: the record
-- set reference non-blank (Operation 6); the credential non-blank unless the mechanism
-- is unkeyed (Operation 7, 8); both string inputs within the cap (Operation 34); the
-- mechanism giving no failure reason (Operation 9); the database accepting the write
-- (Operation 10, 11).
pred sealGuards[c : SealCall] {
    c.refIn not in Strings.blank                                          -- Operation 6
    not (c.credIn in Strings.blank and Mechanism.kind = Keyed)            -- Operation 7, 8
    no ((c.refIn + c.credIn) & Strings.overCap)                           -- Operation 34
    no c.failReason                                                       -- Operation 9
    c not in WriteRefused                                                 -- Operation 10, 11
}

-- sealWrites: the evidence an admitted [Seal] records: the id the host allocated
-- (Identity 2, Invariant 5.1), the call's record set reference, the proof the mechanism
-- supplied (Operation 1), the injected now as its sealing instant (Operation 3), the
-- anchoring instant the anchor recorded, where there is one (Operation 4), standing in
-- sealed (State 1), and not the credential (State 5, Operation 5).
pred sealWrites[c : SealCall, r : Ev] {
    r.id         = c.hostId                                               -- Invariant 5.1
    r.ref        = c.refIn
    r.proof      = c.seamProof                                            -- Operation 1
    r.sealedAt   = c.now                                                  -- Operation 3
    r.anchoredAt = c.anchorAt                                             -- Operation 4
    r.status     = Sealed                                                 -- State 1
    r.credential = c.credIn                                               -- BUG: the credential stored
}

-- laid: an evidence its call's guards and write would leave, the evidence id aside.
pred laid[r : Ev] {
    sealGuards[r.writtenBy]
    sealWrites[r.writtenBy, r]
}

-- carriedBefore: the evidence ids the evidences of the calls before c carry. A laid
-- evidence whose id an earlier one carries is not recorded, but its id is the earlier
-- one's, so the set is the ids the recorded evidences before c carry.
fun carriedBefore[c : SealCall] : set Id {
    { r : Ev | laid[r] and C/lt[r.writtenBy, c] }.id
}

-- sealAdmits: an admitted [Seal]: its guards, and the evidence id the host allocated is
-- one no evidence carries (Identity 5: the atom reuses no evidence id).
pred sealAdmits[c : SealCall] {
    sealGuards[c]
    c.hostId not in carriedBefore[c]                                      -- Identity 5
}

-- recorded: an evidence the page lets the seal records hold: what its admitted call's
-- write left.
pred recorded[r : Ev] {
    sealAdmits[r.writtenBy]
    sealWrites[r.writtenBy, r]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every evidence stands in sealed, and in nothing else (State 1).
assert A_State_1 {
    all r : Ev | recorded[r] implies r.status = Sealed
}
check A_State_1 for 4

-- A_State_3: every evidence carries its evidence id, record set reference, proof and
-- sealing instant (State 3; Check 1.1 reads them).
assert A_State_3 {
    all r : Ev | recorded[r] implies {
        some r.id
        some r.ref
        some r.proof
        some r.sealedAt
    }
}
check A_State_3 for 4

-- A_State_4: an anchoring instant an evidence carries is the one the mechanism's anchor
-- recorded at its [Seal], and an evidence whose mechanism anchors nothing carries none
-- (State 4, Term anchoring instant).
assert A_State_4 {
    all r : Ev | recorded[r] implies {
        r.anchoredAt in r.writtenBy.anchorAt
        Mechanism.anchoring = AnchorsNothing implies no r.anchoredAt
    }
}
check A_State_4 for 4

-- A_State_5: no evidence stores the mechanism credential: it is consumed to make the
-- proof and thrown away (State 5, Operation 5).
assert A_State_5 {
    all r : Ev | recorded[r] implies no r.credential
}
check A_State_5 for 4

-- A_Invariant_5_1: every evidence carries an evidence id, and it is the one the host
-- allocated at the seam for the [Seal] that recorded it: the transition mints none of
-- its own (Invariant 5.1, Identity 2, Identity 4).
assert A_Invariant_5_1 {
    all r : Ev | recorded[r] implies (some r.id and r.id = r.writtenBy.hostId)
}
check A_Invariant_5_1 for 4

-- A_Identity_5: no evidence carries an evidence id an evidence recorded by an earlier
-- [Seal] carries: the atom reuses no evidence id (Identity 5).
assert A_Identity_5 {
    all r1, r2 : Ev | (recorded[r1] and recorded[r2] and C/lt[r1.writtenBy, r2.writtenBy])
        implies r2.id != r1.id
}
check A_Identity_5 for 4

-- A_Identity_8: two evidences that two [Seal] calls recorded over one record set
-- reference carry two evidence ids (Identity 8).
assert A_Identity_8 {
    all r1, r2 : Ev | (recorded[r1] and recorded[r2] and r1.writtenBy != r2.writtenBy
        and r1.ref = r2.ref) implies r1.id != r2.id
}
check A_Identity_8 for 4

-- A_Invariant_6_1: no two evidences, recorded by two [Seal] calls, share an evidence
-- id, so an id names one evidence and [Verify] has one proof to check (Invariant 6.1).
assert A_Invariant_6_1 {
    all r1, r2 : Ev | (recorded[r1] and recorded[r2] and r1.writtenBy != r2.writtenBy)
        implies no (r1.id & r2.id)
}
check A_Invariant_6_1 for 4

-- A_Operation_1: every evidence carries the proof the deployment's mechanism supplied
-- at the seam for its [Seal], and no other (Operation 1).
assert A_Operation_1 {
    all r : Ev | recorded[r] implies r.proof = r.writtenBy.seamProof
}
check A_Operation_1 for 4

-- A_Operation_3: every evidence's sealing instant is the now the host injected for its
-- [Seal], never an instant the business caller passed (Operation 3, Operation 25).
assert A_Operation_3 {
    all r : Ev | recorded[r] implies r.sealedAt = r.writtenBy.now
}
check A_Operation_3 for 4

-- A_Operation_4: where the mechanism anchors at seal time, every evidence carries the
-- anchoring instant the anchor recorded for its [Seal] (Operation 4).
assert A_Operation_4 {
    all r : Ev | (recorded[r] and Mechanism.anchoring = AnchorsAtSeal)
        implies (some r.anchoredAt and r.anchoredAt = r.writtenBy.anchorAt)
}
check A_Operation_4 for 4

-- A_Operation_6: no evidence comes from a call carrying a blank record set reference
-- (Operation 6).
assert A_Operation_6 {
    all r : Ev | recorded[r] implies r.writtenBy.refIn not in Strings.blank
}
check A_Operation_6 for 4

-- A_Operation_7: no evidence comes from a call carrying a blank credential where the
-- mechanism is keyed (Operation 7).
assert A_Operation_7 {
    all r : Ev | (recorded[r] and Mechanism.kind = Keyed)
        implies r.writtenBy.credIn not in Strings.blank
}
check A_Operation_7 for 4

-- A_Operation_8: a call carrying a blank credential to an unkeyed mechanism is admitted
-- wherever no other rule refuses it: a well-formed reference within the cap, no
-- failure reason, a write the database accepts, an id no evidence carries (Operation 8).
assert A_Operation_8 {
    all c : SealCall | (c.credIn in Strings.blank and Mechanism.kind = Unkeyed
        and c.refIn not in Strings.blank
        and no ((c.refIn + c.credIn) & Strings.overCap)
        and no c.failReason and c not in WriteRefused
        and c.hostId not in carriedBefore[c]) implies sealAdmits[c]
}
check A_Operation_8 for 4

-- A_Operation_9: no evidence comes from a call whose mechanism gave a failure reason:
-- unreadable records, a keying precondition, an unreachable anchor (Operation 9).
assert A_Operation_9 {
    all r : Ev | recorded[r] implies no r.writtenBy.failReason
}
check A_Operation_9 for 4

-- A_Operation_11: no evidence comes from a call whose write the database refused: the
-- proof is discarded, not kept in a record (Operation 11, Operation 10).
assert A_Operation_11 {
    all r : Ev | recorded[r] implies r.writtenBy not in WriteRefused
}
check A_Operation_11 for 4

-- A_Operation_34: no evidence comes from a call whose record set reference or
-- mechanism credential runs over the string cap (Operation 34).
assert A_Operation_34 {
    all r : Ev | recorded[r] implies
        no ((r.writtenBy.refIn + r.writtenBy.credIn) & Strings.overCap)
}
check A_Operation_34 for 4

-- A_Non_goal_13: a [Seal] over a record set reference an earlier evidence carries is
-- admitted wherever no rule refuses it: the atom deduplicates no two seals over one
-- record set (Non-goal 13, Concurrent seal 1).
assert A_Non_goal_13 {
    all c : SealCall | ((some r : Ev | recorded[r] and C/lt[r.writtenBy, c] and r.ref = c.refIn)
        and c.refIn not in Strings.blank
        and not (c.credIn in Strings.blank and Mechanism.kind = Keyed)
        and no ((c.refIn + c.credIn) & Strings.overCap)
        and no c.failReason and c not in WriteRefused
        and c.hostId not in carriedBefore[c]) implies sealAdmits[c]
}
check A_Non_goal_13 for 4

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowSealed: one evidence, as evidence_a91 over the day's journal.
run ShowSealed {
    some r : Ev | recorded[r]
} for 4

-- ShowAnchored: an evidence carrying an anchoring instant, as the RFC 3161 token's time
-- in the Financial example (State 4, Operation 4).
run ShowAnchored {
    some r : Ev | recorded[r] and some r.anchoredAt
} for 4

-- ShowTwoOverOneSet: two evidences over one record set reference at one sealing instant,
-- under two ids, which the page admits: two seals stand as independent evidence and the
-- atom identifies an evidence by neither the reference nor the instant (Identity 6, 7,
-- 8; Concurrent seal 1; Non-goal 13).
run ShowTwoOverOneSet {
    some r1, r2 : Ev | recorded[r1] and recorded[r2] and r1.writtenBy != r2.writtenBy
        and r1.ref = r2.ref and r1.sealedAt = r2.sealedAt
} for 4

-- ShowUnkeyedBlankCredential: an evidence from a call carrying a blank credential to an
-- unkeyed mechanism, as a hash chain no key signs (Operation 8).
run ShowUnkeyedBlankCredential {
    some r : Ev | recorded[r] and r.writtenBy.credIn in Strings.blank
} for 4

-- ShowRefused: a call the mechanism could not serve (here, an unreachable anchor) leaves
-- no evidence, while another call's evidence stands (Operation 9, Execution Contract
-- Read 4).
run ShowRefused {
    some c : SealCall | c.failReason = AnchorUnreachable and (no r : Ev | recorded[r] and r.writtenBy = c)
    some r : Ev | recorded[r]
} for 4
