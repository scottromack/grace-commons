-- observation-buggy-link.als
-- BUGGY TWIN for observation.als (added 2026-11-10, unit `tooling: every check
-- has a twin that breaks it`).
--
-- The correct model with ONE defect: amend writes its two links independently.
-- The `SuccessorPredecessorInverse` fact is DROPPED, so the new observation's
-- predecessor link and the old observation's successor link need not agree: a
-- successor may name a predecessor that does not name it back (a half-written
-- amend), and two observations may name the same successor (two chains merged),
-- against Invariants 2 and 3.
-- Checks this twin breaks: A_Inv3_NoBranching, A_Inv2_SuccessorHasPredecessor.
-- If the checker reports all checks UNSAT here, the harness is vacuous.

module observation_buggy_link
-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- State enum: exactly one of three values (spec section State).
abstract sig State {}
one sig Recorded, Amended, Retracted extends State {}

-- Opaque reference types. Alloy generates concrete atoms freely.
-- These model patient_ref, recorded_by / amended_by / retracted_by, and observation_type.
abstract sig PatientRef {}
abstract sig ClinRef {}       -- clinician reference (recorded_by / amended_by / retracted_by)
abstract sig ObsType {}       -- observation_type (blood_pressure_systolic, heart_rate, …)

-- The observation record.
-- successor:    lone — at most one direct successor (Invariant 3, first half).
--               No "one" because most observations have no successor.
-- predecessor:  lone — at most one direct predecessor (Invariant 3, second half).
-- patient:      one  — always present and immutable (Invariant 1, 4).
-- obsType:      one  — always present and immutable (Invariant 1, 5).
-- recordedBy:   one  — always present and immutable (Invariant 1).
-- amendedBy:    lone — present only on successor observations (set by amend).
-- retractedBy:  lone — present only on Retracted observations (Invariant 9).
-- state:        one  — always exactly one state (spec section State).
sig Obs {
    successor   : lone Obs,   -- the correcting observation (set when this becomes Amended)
    predecessor : lone Obs,   -- the observation this corrects (set on amend creation)
    patient     : one  PatientRef,
    obsType     : one  ObsType,
    recordedBy  : one  ClinRef,
    amendedBy   : lone ClinRef,   -- who made the correction; set only on successor obs
    retractedBy : lone ClinRef,   -- who retracted; set only on Retracted obs
    state       : one  State
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Structural well-formedness facts
-- These constrain the universe to VALID configurations only.
-- A fact is a constraint Alloy treats as always true for all instances.
-- ─────────────────────────────────────────────────────────────────────────────

-- Invariant 3 (no-cycles half): the amendment chain is acyclic.
-- "x in x.^successor" would mean x can reach itself via one or more successor steps.
-- The spec says chains are singly-linked and terminate; they never form a loop.
fact NoCycles {
    all x : Obs | x not in x.^successor
}

-- Invariant 3 (no-merging half): no observation is the successor of two. Not a
-- fact: it follows from SuccessorPredecessorInverse with the `lone` predecessor,
-- and A_Inv3_NoBranching checks it (2026-11-10; the fact LinearChain restated it).

-- Inverse consistency: successor and predecessor are inverses of each other.
-- If obs B is the successor of obs A, then A must be the predecessor of B (and vice versa).
-- This encodes the bidirectional link that spec's State and Operations describe:
-- after amend, original gets successor_id and successor gets predecessor_id.
-- BUG: SuccessorPredecessorInverse DROPPED (was `a.successor = b iff b.predecessor = a`).

-- Invariant 2 (state consistency with successor/predecessor links):
-- An observation in Amended state must have exactly one successor.
-- An observation in Recorded state with a predecessor (i.e., it IS a successor) must have
-- no successor of its own unless it has been further amended.
-- Amended state iff successor is set (the link and the state label are consistent).
fact AmendedIffHasSuccessor {
    all x : Obs | x.state = Amended iff one x.successor
}

-- Recorded state means: not amended (no successor) and not retracted.
-- A Recorded observation may have a predecessor (it is itself a successor) — that is fine;
-- it is still the current end of the chain.
fact RecordedConsistency {
    all x : Obs | x.state = Recorded implies (no x.successor)
}

-- Invariant 6: Retracted is terminal. Not a fact: it follows from
-- AmendedIffHasSuccessor (only an Amended observation has a successor), and
-- A_Inv6_RetractedHasNoSuccessor checks it (2026-11-10; the fact
-- RetractedIsTerminal restated it).

-- Invariant 9 (transition metadata consistency — write-once structural analog):
-- amendedBy is set iff the observation has a predecessor (it was created by amend).
fact AmendedByConsistency {
    all x : Obs | (one x.amendedBy) iff (one x.predecessor)
}

-- retractedBy is set iff the observation is in Retracted state.
fact RetractedByConsistency {
    all x : Obs | (one x.retractedBy) iff (x.state = Retracted)
}

-- Invariant 4: All observations in an amendment chain share the same patient_ref.
-- If B is the successor of A, they must have the same patient.
fact PatientRefInherited {
    all a, b : Obs | a.successor = b implies b.patient = a.patient
}

-- Invariant 5: All observations in an amendment chain share the same observation_type.
-- If B is the successor of A, they must have the same obsType.
fact ObsTypeInherited {
    all a, b : Obs | a.successor = b implies b.obsType = a.obsType
}

-- No self-loops: an observation cannot be its own successor.
-- (Subsumed by NoCycles but stated explicitly for clarity and direct testability.)
fact NoSelfLoop {
    all x : Obs | x.successor != x
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions
-- Each "check" command asks Alloy: is there any configuration satisfying the
-- facts but violating this assertion? UNSAT = guarantee holds. SAT = spec finding.
-- ─────────────────────────────────────────────────────────────────────────────

-- Checks that restated the model and went (2026-11-10, unit `tooling: every
-- check has a twin that breaks it`): A_Inv3_AtMostOnePredecessor (the `lone`
-- field), A_Inv3_NoCycles (fact NoCycles), A_Inv9_AmendedBySetOnSuccessorOnly
-- (fact AmendedByConsistency), A_Inv9_RetractedBySetOnRetractedOnly (fact
-- RetractedByConsistency) and A_SuccessorPredecessorAreInverse (fact
-- SuccessorPredecessorInverse). The facts stay as the model's assumptions; no
-- twin of a static snapshot can break them.

-- A_Inv3_AtMostOneSuccessor (Invariant 3):
-- No observation has more than one direct successor.
assert A_Inv3_AtMostOneSuccessor {
    all x : Obs | lone x.successor
}
check A_Inv3_AtMostOneSuccessor for 8

-- A_Inv3_NoBranching (Invariant 3):
-- No two distinct observations have the same successor (the anti-branching direction).
-- i.e., every observation is the successor of at most one other observation.
assert A_Inv3_NoBranching {
    all x : Obs | lone (successor.x)
}
check A_Inv3_NoBranching for 8

-- A_Inv2_AmendedHasSuccessor (Invariant 2):
-- Every Amended observation has exactly one successor.
assert A_Inv2_AmendedHasSuccessor {
    all x : Obs | x.state = Amended implies one x.successor
}
check A_Inv2_AmendedHasSuccessor for 8

-- A_Inv2_SuccessorHasPredecessor (Invariant 2):
-- Every observation that has a predecessor must itself be the successor of that predecessor.
-- i.e., if x.predecessor = a, then a.successor = x. (Inverse consistency.)
assert A_Inv2_SuccessorHasPredecessor {
    all x : Obs | one x.predecessor implies x.predecessor.successor = x
}
check A_Inv2_SuccessorHasPredecessor for 8

-- A_Inv4_PatientRefChainConsistency (Invariant 4):
-- All observations reachable via successor* from a given observation share the same patient.
assert A_Inv4_PatientRefChainConsistency {
    all x, y : Obs | y in x.*successor implies y.patient = x.patient
}
check A_Inv4_PatientRefChainConsistency for 8

-- A_Inv5_ObsTypeChainConsistency (Invariant 5):
-- All observations reachable via successor* from a given observation share the same obsType.
assert A_Inv5_ObsTypeChainConsistency {
    all x, y : Obs | y in x.*successor implies y.obsType = x.obsType
}
check A_Inv5_ObsTypeChainConsistency for 8

-- A_Inv6_RetractedHasNoSuccessor (Invariant 6):
-- A Retracted observation has no successor. Retraction is terminal.
assert A_Inv6_RetractedHasNoSuccessor {
    all x : Obs | x.state = Retracted implies no x.successor
}
check A_Inv6_RetractedHasNoSuccessor for 8

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs
-- Every "run" must return SAT — at least one instance — confirming the facts do
-- not over-constrain the model (the invariants are mutually satisfiable).
-- ─────────────────────────────────────────────────────────────────────────────

-- A single Recorded observation: the simplest valid store state.
run ShowSingleRecorded {
    some x : Obs | x.state = Recorded and no x.predecessor and no x.successor
} for 3

-- A single Retracted observation with retractedBy set.
run ShowRetracted {
    some x : Obs | x.state = Retracted and one x.retractedBy
} for 3

-- A two-link amendment chain: obs A (Amended) → obs B (Recorded).
-- This is the minimal non-trivial chain. Non-vacuity guard for linearity checks.
run ShowTwoLinkChain {
    some disj a, b : Obs | {
        a.successor = b
        a.state = Amended
        b.state = Recorded
        b.predecessor = a
        one b.amendedBy          -- correction attribution is set
        no a.predecessor         -- a is the chain head (original observation)
        a.patient = b.patient    -- Invariant 4: same patient across chain
        a.obsType = b.obsType    -- Invariant 5: same type across chain
    }
} for 4

-- A three-link amendment chain: obs A (Amended) → obs B (Amended) → obs C (Recorded).
-- This is the critical non-vacuity run: confirms linearity facts permit multi-link chains
-- and does NOT make them impossible (would falsely satisfy the linearity assertions trivially
-- over empty chains).
run ShowThreeLinkChain {
    some disj a, b, c : Obs | {
        a.successor = b
        b.successor = c
        a.state = Amended
        b.state = Amended
        c.state = Recorded
        b.predecessor = a
        c.predecessor = b
        no a.predecessor         -- a is the chain head
        one b.amendedBy
        one c.amendedBy
        a.patient = b.patient
        b.patient = c.patient
        a.obsType = b.obsType
        b.obsType = c.obsType
    }
} for 5

-- A tail-retracted chain: obs A (Amended) → obs B (Retracted).
-- The spec allows Amended → Retracted (State section, valid transitions).
-- The successor B was Recorded, then retracted. A is Amended (has its successor B),
-- B is Retracted (has retractedBy, no further successor allowed).
-- This confirms: retraction of a successor observation does not affect the chain
-- structure up to that point.
run ShowTailRetractedChain {
    some disj a, b : Obs | {
        a.successor = b
        a.state = Amended
        b.state = Retracted
        b.predecessor = a
        one b.amendedBy          -- b was created by amend, so amendedBy is set
        one b.retractedBy        -- b was subsequently retracted
        no a.predecessor         -- a is the chain head
        a.patient = b.patient
        a.obsType = b.obsType
    }
} for 4

-- Two independent chains, different patients — store can hold multiple unrelated chains.
run ShowTwoIndependentChains {
    some disj a, b, c, d : Obs, disj p1, p2 : PatientRef | {
        a.successor = b
        a.state = Amended
        b.state = Recorded
        b.predecessor = a
        a.patient = p1
        b.patient = p1
        c.successor = d
        c.state = Amended
        d.state = Recorded
        d.predecessor = c
        c.patient = p2
        d.patient = p2
        p1 != p2
    }
} for 6
