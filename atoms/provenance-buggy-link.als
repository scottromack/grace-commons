-- provenance-buggy-link.als
-- BUGGY TWIN for provenance.als (added 2026-11-10, unit `tooling: every check
-- has a twin that breaks it`).
--
-- The correct model with ONE defect: the link between two entries is written one
-- way only. `SuccPredInverse` keeps "an entry's predecessor names an entry whose
-- successor is it" but loses the converse, so an entry may set its successor to
-- an entry that already follows another (a spliced chain: two entries both claim
-- the same next entry, so two entries stand at one position, against
-- Invariant 5.1's one sequence number per entry).
-- Check this twin breaks: A_Linear_NoBranching.
-- If the checker reports all checks UNSAT here, the harness is vacuous.

module provenance_buggy_link
-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures
-- ─────────────────────────────────────────────────────────────────────────────

-- Event type enum: exactly one of six values (spec section State).
abstract sig EventType {}
one sig Originated, Received, Transferred, Transformed, Disclosed, Archived extends EventType {}

-- The genesis event types (a chain opens with exactly one of these).
fun GenesisType : set EventType { Originated + Received }

-- Opaque custodian reference. Alloy generates concrete atoms freely
-- (abstract sig with no extensions behaves as a normal sig).
abstract sig Custodian {}

-- A custody entry.
-- successor/predecessor : lone — linear chain (Invariant 2/5; no branching).
-- etype  : one — exactly one event type (spec section State).
-- holder : one — the current custodian in effect immediately AFTER this entry.
-- acting : lone — the custodian who performed a non-transfer action (genesis,
--          transform, disclose, archive); absent on transfers.
-- fromC  : lone — transfer only: the outgoing custodian (= predecessor.holder).
-- toC    : lone — transfer only: the incoming custodian (= this.holder).
sig Entry {
    successor   : lone Entry,
    predecessor : lone Entry,
    etype       : one  EventType,
    holder      : one  Custodian,
    acting      : lone Custodian,
    fromC       : lone Custodian,
    toC         : lone Custodian
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Structural well-formedness facts (constrain the universe to VALID chains)
-- ─────────────────────────────────────────────────────────────────────────────

-- Linear backbone (Invariant 2/5): acyclic, singly-linked, no branching/merging.
-- No merging (at most one entry names a given entry as its successor) is not a
-- fact: it follows from SuccPredInverse with the `lone` predecessor, and
-- A_Linear_NoBranching checks it (2026-11-10; the fact NoMerging restated it).
fact NoCycles            { all x : Entry | x not in x.^successor }
fact NoSelfLoop          { all x : Entry | x.successor != x }
-- BUG: one way only (was `a.successor = b iff b.predecessor = a`).
fact SuccPredInverse     { all a, b : Entry | b.predecessor = a implies a.successor = b }

-- Invariant 3 / 8 — genesis typing: an entry is genesis (no predecessor) iff its
-- event type is a genesis type. Non-genesis entries carry a non-genesis type.
fact GenesisTyping {
    all x : Entry | (no x.predecessor) iff (x.etype in GenesisType)
}

-- Invariant 6 — Archived is terminal: an Archived entry has no successor.
fact ArchivedTerminal {
    all x : Entry | x.etype = Archived implies no x.successor
}

-- Field shape by event type: which custodian fields an entry may carry.
-- That the ones it carries are present (Invariant 7) is not assumed here: it
-- follows from GenesisTyping and CustodyContinuity, and A_Inv7_CustodianPresent
-- checks it (2026-11-10).
-- Transfers carry no acting custodian.
fact TransferFields {
    all x : Entry | x.etype = Transferred implies no x.acting
}
-- Non-transfer entries carry no from/to.
fact NonTransferFields {
    all x : Entry | x.etype != Transferred implies (no x.fromC and no x.toC)
}

-- Invariant 4 — Custody continuity (the load-bearing fact). At every link the
-- custody coming INTO an entry equals the custody going OUT of its predecessor:
--   * Transferred entry: fromC = predecessor.holder, and the new holder = toC.
--   * any other non-genesis entry: holder = predecessor.holder (custody unchanged)
--     and the acting custodian = the holder (only the current holder may act).
-- Genesis entry: acting = holder (the originating custodian); holder is the
-- genesis custodian by construction.
fact CustodyContinuity {
    all x : Entry |
        (some x.predecessor and x.etype = Transferred) implies
            (x.fromC = x.predecessor.holder and x.holder = x.toC)
    all x : Entry |
        (some x.predecessor and x.etype != Transferred) implies
            (x.holder = x.predecessor.holder and x.acting = x.holder)
    all x : Entry |
        (no x.predecessor) implies (x.acting = x.holder)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions — each "check" asks: is there a configuration satisfying the facts
-- but violating this guarantee? UNSAT = holds. SAT = finding.
-- ─────────────────────────────────────────────────────────────────────────────

-- Checks that restated the model and went (2026-11-10, unit `tooling: every
-- check has a twin that breaks it`): A_Linear_AtMostOneSuccessor and
-- A_Linear_AtMostOnePredecessor (the `lone` fields), A_Linear_NoCycles (fact
-- NoCycles), A_Inv3_SingleOriginTyping (fact GenesisTyping), A_Inv4_UniqueHolder
-- (the `one` holder field) and A_Inv6_ArchivedTerminal (fact ArchivedTerminal).
-- The facts stay as the model's assumptions; no twin of a static snapshot can
-- break them.

-- Linear backbone (Invariant 2/5): no entry is named as successor by two entries.
assert A_Linear_NoBranching          { all x : Entry | lone (successor.x) }
check A_Linear_NoBranching for 8

-- Invariant 4 — Custody continuity (no gap), the load-bearing claim. At every
-- link the incoming custody equals the predecessor's outgoing custody.
assert A_Inv4_CustodyUnbroken {
    all x : Entry | some x.predecessor implies
        ( (x.etype = Transferred implies x.fromC = x.predecessor.holder)
          and
          (x.etype != Transferred implies x.holder = x.predecessor.holder) )
}
check A_Inv4_CustodyUnbroken for 8

-- Invariant 4 — a Transferred entry's hand-to-hand outgoing custodian equals the
-- prior holder (the false-predecessor attack surface; cannot be forged).
assert A_Inv4_TransferHandToHand {
    all x : Entry | x.etype = Transferred implies x.fromC = x.predecessor.holder
}
check A_Inv4_TransferHandToHand for 8

-- Invariant 4 — a Transferred entry installs toC as the new holder.
assert A_Inv4_TransferSetsHolder {
    all x : Entry | x.etype = Transferred implies x.holder = x.toC
}
check A_Inv4_TransferSetsHolder for 8

-- Invariant 4 — only the current holder may transform/disclose/archive: a
-- non-genesis non-transfer entry's acting custodian equals the prior holder.
assert A_Inv4_OnlyHolderActs {
    all x : Entry | (some x.predecessor and x.etype != Transferred) implies
        x.acting = x.predecessor.holder
}
check A_Inv4_OnlyHolderActs for 8

-- Invariant 7 — Custodian presence: every entry names a custodian; transfers name
-- both from and to.
assert A_Inv7_CustodianPresent {
    all x : Entry |
        (x.etype = Transferred implies (one x.fromC and one x.toC))
        and
        (x.etype != Transferred implies one x.acting)
}
check A_Inv7_CustodianPresent for 8

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — each must be SAT (non-vacuity guards).
-- ─────────────────────────────────────────────────────────────────────────────

-- A single genesis (Originated) entry: the simplest valid chain.
run ShowSingleGenesis {
    some x : Entry | x.etype = Originated and no x.predecessor and no x.successor
} for 3

-- A genesis (Received) entry — intake from an external prior holder.
run ShowReceivedGenesis {
    some x : Entry | x.etype = Received and no x.predecessor and no x.successor
} for 3

-- A two-entry chain: Originated → Transferred, custody changes hands.
-- Non-vacuity guard for the continuity / hand-to-hand checks.
run ShowTransferChain {
    some disj a, b : Entry, disj c1, c2 : Custodian | {
        a.etype = Originated
        no a.predecessor
        a.holder = c1
        a.acting = c1
        b.predecessor = a
        a.successor = b
        b.etype = Transferred
        b.fromC = c1
        b.toC = c2
        b.holder = c2
    }
} for 4

-- A full lifecycle: Originated → Transferred → Transformed → Disclosed → Archived.
-- The critical non-vacuity run: a multi-link chain with a custody change and the
-- terminal archive, all holders continuous.
run ShowFullLifecycle {
    some disj a, b, c, d, e : Entry, disj c1, c2 : Custodian | {
        a.etype = Originated     a.holder = c1   a.acting = c1   no a.predecessor
        a.successor = b
        b.etype = Transferred    b.predecessor = a   b.fromC = c1   b.toC = c2   b.holder = c2
        b.successor = c
        c.etype = Transformed    c.predecessor = b   c.holder = c2   c.acting = c2
        c.successor = d
        d.etype = Disclosed      d.predecessor = c   d.holder = c2   d.acting = c2
        d.successor = e
        e.etype = Archived       e.predecessor = d   e.holder = c2   e.acting = c2
        no e.successor
    }
} for 6

-- Two independent chains (different artifacts / custodians) coexisting in a store.
run ShowTwoIndependentChains {
    some disj a, b, c, d : Entry, disj c1, c2, c3, c4 : Custodian | {
        a.etype = Originated   a.holder = c1   a.acting = c1   no a.predecessor
        a.successor = b
        b.etype = Transferred  b.predecessor = a   b.fromC = c1   b.toC = c2   b.holder = c2
        c.etype = Originated   c.holder = c3   c.acting = c3   no c.predecessor
        c.successor = d
        d.etype = Transferred  d.predecessor = c   d.fromC = c3   d.toC = c4   d.holder = c4
    }
} for 6
