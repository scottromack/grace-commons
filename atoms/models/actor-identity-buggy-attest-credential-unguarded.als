-- actor-identity-buggy-attest-credential-unguarded.als
-- DELIBERATELY WRONG twin of actor-identity.als (unit: `atoms/actor-identity.md formal layer`).
--
-- INJECTED DEFECT: [Attest] admits a blank credential (Operation 8 dropped).
--
-- BREAKS: A_Operation_8.
-- Everything else is actor-identity.als as written; read its comments there.

module actor_identity_buggy_attest_credential_unguarded

open util/ordering[AttestCall] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a string a call carries: an action reference, an actor reference or a credential
-- (Term string input). The atom never interprets an opaque reference (Term action
-- reference, Term actor reference), so a string is an uninterpreted token and two
-- different strings are two different atoms.
sig Str {}

-- Strings: which strings the guards refuse: the blank ones (Operation 6, 7, 8) and the
-- ones longer than the string cap (Operation 37, Term string cap).
one sig Strings {
    blank   : set Str,
    overCap : set Str
}

-- Id: an attestation id, the opaque value naming one attestation (Term attestation id).
-- The host allocates it at the seam (Identity 2); the atom only records it.
sig Id {}

-- Key: one piece of public material the actor registry holds for an actor, and the key a
-- credential is under (Term public material, Term current material). The model reads
-- "verifies under a material" as "was produced under that key".
sig Key {}

-- Proof: the cryptographic artifact the deployment's credential mechanism computed at the
-- seam (Term proof, Term cryptographic material), with what it was computed over: the
-- action reference, the actor reference, and the key of the credential that made it.
sig Proof {
    forAction : one Str,
    byActor   : one Str,
    underKey  : lone Key
}

-- Mechanism: the deployment's credential mechanism (Revocation status 4): the key each
-- credential string is under, absent where the string names no credential.
one sig Mechanism {
    keyOf : Str -> lone Key
}

-- Status: what an attestation's state could hold. The page's one state is attested
-- (Term attested); Pending is in the type so a write that parked an attestation
-- elsewhere would show. That none does is checked, never built in.
abstract sig Status {}

-- Attested, Pending: recorded and nothing further to become; a state the page has not.
one sig Attested, Pending extends Status {}

-- RegAnswer: what the actor registry gives [Attest] for the actor reference (Term
-- registry answer).
abstract sig RegAnswer {}

-- Material, UnknownActor, Unreachable: the registry's three answers.
one sig Material, UnknownActor, Unreachable extends RegAnswer {}

-- CheckResult: the credential check the mechanism computes at the seam (Term credential
-- check).
abstract sig CheckResult {}

-- Held, Failed, Unavailable: the credential check's three values.
one sig Held, Failed, Unavailable extends CheckResult {}

-- AttestCall: one [Attest] call, attest(action_ref, actor_ref, credential), with what the
-- host injects at the seam for it (Term seam): now, the attestation id it allocated, the
-- registry answer and the current material it carries, the credential check and the proof
-- the mechanism computed. callerAt is an instant the business caller passes beside the
-- call, which the atom must never take (Operation 26); it is in the type so a write that
-- took it would show.
sig AttestCall {
    now       : one Int,        -- the injected now
    actionIn  : one Str,        -- action_ref
    actorIn   : one Str,        -- actor_ref
    credIn    : one Str,        -- credential
    callerAt  : lone Int,       -- an instant the business caller passes (never taken)
    hostId    : one Id,         -- the attestation id the host allocated
    regAns    : one RegAnswer,  -- the registry answer
    current   : lone Key,       -- the current material the registry answer carries
    credCheck : one CheckResult,-- the credential check
    seamProof : lone Proof      -- the proof the mechanism computed, absent where none
}

-- RevokedCall: the calls whose credential a revocation status names revoked (Term
-- revocation status; Revocation status 1, 3).
sig RevokedCall in AttestCall {}

-- WriteRefused: the calls whose write the database refuses (Operation 10).
sig WriteRefused in AttestCall {}

-- Att: one attestation record (Term records), as the call that wrote it left it. Every
-- field may be absent and the state is a set, so a write that forgot a field or left two
-- states would show; what the page promises (State 1, 3) is checked, never built into the
-- type. credential and material are the fields State 4 and State 7 forbid, in the type
-- so a write that stored one would show. writtenBy is the model's own: the call that
-- recorded it.
sig Att {
    id         : lone Id,       -- attestation id
    action     : lone Str,      -- action reference
    actor      : lone Str,      -- actor reference
    proof      : lone Proof,    -- proof
    at         : lone Int,      -- attestation instant
    status     : set Status,    -- the attestation's state
    credential : lone Str,      -- a stored credential (forbidden, State 4)
    material   : set Key,       -- held public material (forbidden, State 7)
    writtenBy  : one AttestCall
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The mechanism computes the proof from the credential over the action reference and
-- the actor reference the call carries (Term cryptographic material): the proof is over
-- those two, under the credential's key.
fact MechanismComputesTheProofOverTheCall {
    all c : AttestCall, p : c.seamProof {
        p.forAction = c.actionIn
        p.byActor   = c.actorIn
        p.underKey  = Mechanism.keyOf[c.credIn]
    }
}

-- The registry answer material carries the current material; unknown-actor and
-- unreachable carry none (Term registry answer, Term registry view).
fact OnlyMaterialCarriesCurrentMaterial {
    all c : AttestCall | some c.current iff c.regAns = Material
}

-- The credential check holds only where the credential is under the current material
-- the registry answer carries, and only where the mechanism computed a proof (Term
-- credential check: "unavailable where the credential mechanism supplies ... no proof at
-- the seam").
fact CredentialCheckIsTheMechanisms {
    all c : AttestCall | c.credCheck = Held implies {
        some c.current
        Mechanism.keyOf[c.credIn] = c.current
        some c.seamProof
    }
}

-- The host allocates, for each [Attest], an attestation id no attestation recorded before
-- it carries (Identity 2, Capability requirement 6). The atom takes the id from outside;
-- whether the host keeps this duty across steps is checked in the TLA+ model
-- (Cap6_HostIdFresh).
fact HostAllocatesAnUncarriedId {
    all c : AttestCall | no v : Att |
        recorded[v] and C/lt[v.writtenBy, c] and v.id = c.hostId
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing action: its guards and its write
-- ─────────────────────────────────────────────────────────────────────────────

-- attestWrites: the attestation an admitted [Attest] records, and the guards it passes
-- first: the three string inputs non-blank and within the cap (Operation 6, 7, 8, 37);
-- the registry reachable (Operation 33) and holding material for the actor (Operation
-- 31); with material in hand, the credential check neither unavailable (Operation 40) nor
-- failed (Operation 9); no revocation status naming the credential revoked (Operation
-- 36); the database accepting the write (Operation 10). The attestation carries the id
-- the host allocated (Identity 2), the call's action and actor references (Operation 38,
-- 39), the proof the mechanism supplied (Operation 1), the injected now as its instant
-- (Operation 3), stands in attested (State 1), and stores neither the credential nor any
-- public material (State 4, 7; Operation 5).
pred attestWrites[c : AttestCall, r : Att] {
    c.actionIn not in Strings.blank                                   -- Operation 6
    c.actorIn not in Strings.blank                                    -- Operation 7
    no ((c.actionIn + c.actorIn + c.credIn) & Strings.overCap)        -- Operation 37
    c.regAns != Unreachable                                           -- Operation 33
    c.regAns != UnknownActor                                          -- Operation 31
    not (c.regAns = Material and c.credCheck = Unavailable)           -- Operation 40
    not (c.regAns = Material and c.credCheck = Failed)                -- Operation 9
    c not in RevokedCall                                              -- Operation 36
    c not in WriteRefused                                             -- Operation 10
    r.id         = c.hostId                                           -- Identity 2
    r.action     = c.actionIn                                         -- Operation 38
    r.actor      = c.actorIn                                          -- Operation 39
    r.proof      = c.seamProof                                        -- Operation 1
    r.at         = c.now                                              -- Operation 3
    r.status     = Attested                                           -- State 1
    no r.credential                                                   -- State 4, Operation 5
    no r.material                                                     -- State 7
}

-- recorded: an attestation the page lets the records hold: what its call's write left.
pred recorded[r : Att] {
    attestWrites[r.writtenBy, r]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every attestation stands in attested, and in nothing else (State 1).
assert A_State_1 {
    all r : Att | recorded[r] implies r.status = Attested
}
check A_State_1 for 4

-- A_State_3: every attestation carries its attestation id, action reference, actor
-- reference, proof and attestation instant (State 3; Check 1.1 reads them).
assert A_State_3 {
    all r : Att | recorded[r] implies {
        some r.id
        some r.action
        some r.actor
        some r.proof
        some r.at
    }
}
check A_State_3 for 4

-- A_State_4: no attestation stores the credential: it is consumed to make the proof and
-- thrown away (State 4, Operation 5).
assert A_State_4 {
    all r : Att | recorded[r] implies no r.credential
}
check A_State_4 for 4

-- A_State_7: no attestation holds the actor registry's public material: a verifier reads
-- it from the registry (State 7).
assert A_State_7 {
    all r : Att | recorded[r] implies no r.material
}
check A_State_7 for 4

-- A_Identity_2: every attestation carries the attestation id the host allocated at the
-- seam for the [Attest] that recorded it: the transition mints no id of its own
-- (Identity 2, Identity 4, Capability requirement 6).
assert A_Identity_2 {
    all r : Att | recorded[r] implies r.id = r.writtenBy.hostId
}
check A_Identity_2 for 4

-- A_Invariant_2_1: every recorded proof was made over the recorded action reference
-- under the current material the registry answer carried at the attestation's [Attest]:
-- it verifies against that action under that material (Invariant 2.1, Check 3.1).
assert A_Invariant_2_1 {
    all r : Att | recorded[r] implies
        (all p : r.proof | p.forAction = r.action and p.underKey = r.writtenBy.current)
}
check A_Invariant_2_1 for 4

-- A_Invariant_3_1: every recorded proof was made by the recorded actor reference under
-- the current material the registry answer carried at the attestation's [Attest]: it
-- verifies against that actor under that material (Invariant 3.1, Check 3.2).
assert A_Invariant_3_1 {
    all r : Att | recorded[r] implies
        (all p : r.proof | p.byActor = r.actor and p.underKey = r.writtenBy.current)
}
check A_Invariant_3_1 for 4

-- A_Invariant_5_1: no two attestations, recorded by two [Attest] calls, share an
-- attestation id, so an id names one attestation and [Verify] has one record to check
-- (Invariant 5.1).
assert A_Invariant_5_1 {
    all r1, r2 : Att | (recorded[r1] and recorded[r2] and r1.writtenBy != r2.writtenBy)
        implies no (r1.id & r2.id)
}
check A_Invariant_5_1 for 4

-- A_Operation_1: every attestation carries the proof the deployment's mechanism supplied
-- at the seam for its [Attest], and no other (Operation 1).
assert A_Operation_1 {
    all r : Att | recorded[r] implies r.proof = r.writtenBy.seamProof
}
check A_Operation_1 for 4

-- A_Operation_3: every attestation's instant is the now the host injected for its
-- [Attest], never an instant the business caller passed (Operation 3, Operation 26).
assert A_Operation_3 {
    all r : Att | recorded[r] implies r.at = r.writtenBy.now
}
check A_Operation_3 for 4

-- A_Operation_6: no attestation comes from a call carrying a blank action reference
-- (Operation 6).
assert A_Operation_6 {
    all r : Att | recorded[r] implies r.writtenBy.actionIn not in Strings.blank
}
check A_Operation_6 for 4

-- A_Operation_7: no attestation comes from a call carrying a blank actor reference
-- (Operation 7).
assert A_Operation_7 {
    all r : Att | recorded[r] implies r.writtenBy.actorIn not in Strings.blank
}
check A_Operation_7 for 4

-- A_Operation_8: no attestation comes from a call carrying a blank credential
-- (Operation 8).
assert A_Operation_8 {
    all r : Att | recorded[r] implies r.writtenBy.credIn not in Strings.blank
}
check A_Operation_8 for 4

-- A_Operation_37: no attestation comes from a call whose action reference, actor
-- reference or credential runs over the string cap (Operation 37, Term string input).
assert A_Operation_37 {
    all r : Att | recorded[r] implies
        no ((r.writtenBy.actionIn + r.writtenBy.actorIn + r.writtenBy.credIn) & Strings.overCap)
}
check A_Operation_37 for 4

-- A_Operation_9: no attestation comes from a call whose registry answered material and
-- whose credential check failed against the current material (Operation 9).
assert A_Operation_9 {
    all r : Att | recorded[r] implies
        not (r.writtenBy.regAns = Material and r.writtenBy.credCheck = Failed)
}
check A_Operation_9 for 4

-- A_Operation_31: no attestation comes from a call whose registry holds no material for
-- the actor (Operation 31).
assert A_Operation_31 {
    all r : Att | recorded[r] implies r.writtenBy.regAns != UnknownActor
}
check A_Operation_31 for 4

-- A_Operation_33: no attestation comes from a call whose registry was unreachable
-- (Operation 33).
assert A_Operation_33 {
    all r : Att | recorded[r] implies r.writtenBy.regAns != Unreachable
}
check A_Operation_33 for 4

-- A_Operation_36: no attestation comes from a call whose credential a revocation status
-- names revoked (Operation 36).
assert A_Operation_36 {
    all r : Att | recorded[r] implies r.writtenBy not in RevokedCall
}
check A_Operation_36 for 4

-- A_Operation_40: no attestation comes from a call whose registry answered material and
-- whose mechanism supplied no credential check (Operation 40).
assert A_Operation_40 {
    all r : Att | recorded[r] implies
        not (r.writtenBy.regAns = Material and r.writtenBy.credCheck = Unavailable)
}
check A_Operation_40 for 4

-- A_Operation_38: every attestation records the action reference its call carried
-- (Operation 38).
assert A_Operation_38 {
    all r : Att | recorded[r] implies r.action = r.writtenBy.actionIn
}
check A_Operation_38 for 4

-- A_Operation_39: every attestation records the actor reference its call carried
-- (Operation 39).
assert A_Operation_39 {
    all r : Att | recorded[r] implies r.actor = r.writtenBy.actorIn
}
check A_Operation_39 for 4

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowAttested: one attestation, as attestation_a44 binding supervisor_s12 to wire_w91.
run ShowAttested {
    some r : Att | recorded[r]
} for 4

-- ShowTwoForOneAction: two attestations of one action reference by one actor
-- reference, which the page admits: the atom identifies an attestation by neither
-- (Identity 6, 7), so a second sign-off is a second record.
run ShowTwoForOneAction {
    some r1, r2 : Att | recorded[r1] and recorded[r2] and r1.writtenBy != r2.writtenBy
        and r1.action = r2.action and r1.actor = r2.actor
} for 4

-- ShowTwoAtOneInstant: two attestations stamped with one attestation instant, which the
-- page admits: the atom identifies an attestation by no instant (Identity 8).
run ShowTwoAtOneInstant {
    some r1, r2 : Att | recorded[r1] and recorded[r2] and r1.writtenBy != r2.writtenBy
        and r1.at = r2.at
} for 4

-- ShowRefused: a call refused (here, by a revoked credential) leaves no attestation,
-- while another call's attestation stands (Operation 36, Execution Contract Read 4).
run ShowRefused {
    some c : RevokedCall | no r : Att | recorded[r] and r.writtenBy = c
    some r : Att | recorded[r]
} for 4
