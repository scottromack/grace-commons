-- provenance-buggy-guard-unchecked.als
-- DELIBERATELY WRONG twin of provenance.als (unit: `atoms/provenance.md formal layer`).
--
-- INJECTED DEFECT: [Transform], [Disclose] and [Archive] do not compare the caller's
-- custodian reference with the current custodian, so a prior holder's call lands an
-- entry (Operation 26).
--
-- BREAKS: A_Inv4_2.
-- Everything else is provenance.als as written; read its comments there.

module provenance_buggy_guard_unchecked

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Ref: a custodian reference a call carries or an entry holds. The atom matches it
-- exactly and never normalizes it (Identity 11, 12), so a reference is an uninterpreted
-- token and two different references are two different atoms.
sig Ref {}

-- Refs: which references the page's guards refuse: the blank ones, whitespace-only
-- included (String 5).
one sig Refs {
    blank : set Ref
}

-- EventType: an entry's event type (Term event type).
abstract sig EventType {}

-- Originated .. Archived: the six event types; the first two are the genesis types.
one sig Originated, Received, Transferred, Transformed, Disclosed, Archived extends EventType {}

-- ChainState: the chain's state (Term chain state), open or archived.
abstract sig ChainState {}

-- OpenState, ArchivedState: accepting entries, or at terminal disposition.
one sig OpenState, ArchivedState extends ChainState {}

-- Call: one admitted call on the chain, with the entry it appended and the version of
-- the chain record it left, and the call whose version it found (prev; none for the call
-- that opened the chain). The entry's fields may be absent (lone), so a write that
-- forgot one would show; what the page promises is checked, never built into the type.
abstract sig Call {
    prev  : lone Call,       -- the call whose chain record this call found
    sn    : one Int,         -- the entry's sequence number
    etype : one EventType,   -- the entry's event type
    cust  : lone Ref,        -- the entry's custodian reference
    fromC : lone Ref,        -- the entry's from custodian reference
    toC   : lone Ref,        -- the entry's to custodian reference
    state : one ChainState,  -- the chain record as the call left it: chain state,
    cur   : lone Ref,        --   current custodian
    nextSn : one Int         --   and next sequence number
}

-- OriginateCall: an [Originate] call, originate(artifact_ref, custodian_ref,
-- genesis_type); the artifact reference is not modeled.
sig OriginateCall extends Call {
    genCust : one Ref,       -- custodian_ref
    genType : one EventType  -- genesis_type
}

-- TransferCall: a [Transfer] call, transfer(chain_id, to_custodian_ref). It carries no
-- from custodian reference (Operation 18).
sig TransferCall extends Call {
    toIn : one Ref           -- to_custodian_ref
}

-- GuardedCall: a custodian-guarded call (Term custodian-guarded action), carrying the
-- caller's custodian reference.
abstract sig GuardedCall extends Call {
    actIn : one Ref          -- custodian_ref
}

-- TransformCall, DiscloseCall, ArchiveCall: [Transform], [Disclose] and [Archive].
sig TransformCall, DiscloseCall, ArchiveCall extends GuardedCall {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- CommitOrder: calls on one chain commit one after another, each finding what the call
-- before it committed (Execution Contract Order 1, Database 2): no call comes after
-- itself, and no two calls found the same version of the chain record.
fact CommitOrder {
    no c : Call | c in c.^prev
    all c : Call | lone prev.c
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- eventOf: the event type a custodian-guarded call's entry takes (Operation 69, 71, 73).
fun eventOf[c : GuardedCall] : EventType {
    c in TransformCall => Transformed else (c in DiscloseCall => Disclosed else Archived)
}

-- custodyFound: the current custodian an entry found, replayed from the chain's entries
-- before it by sequence number (Check 3.1, Term current custodian): the to custodian
-- reference of the latest transferred entry, or the genesis entry's custodian reference
-- where no transfer came before.
fun custodyFound[e : Call] : set Ref {
    let earlier = { x : Call | x.sn < e.sn },
        ts = earlier & TransferCall,
        latest = { t : ts | no u : ts | u.sn > t.sn } |
        some ts => latest.toC else (earlier & OriginateCall).cust
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- originateWrites: what an admitted [Originate] writes. It is the chain's first call (the
-- host allocated a chain id no chain held, Identity 3); its custodian reference is not
-- blank (Operation 2) and its genesis type is one of the two (Operation 3). The genesis
-- entry takes the next sequence number a chain begins with, one (Operation 36, Term next
-- sequence number), the genesis type as its event type (Operation 7) and the call's
-- custodian reference (Operation 63); the chain stands open (Operation 8) with that
-- custodian current (Operation 75) and next sequence number raised (Operation 37).
pred originateWrites[c : OriginateCall] {
    no c.prev                                          -- Identity 3
    c.genCust not in Refs.blank                        -- Operation 2
    c.genType in Originated + Received                 -- Operation 3
    c.sn   = 1                                        -- Operation 36
    c.etype = c.genType                                -- Operation 7
    c.cust  = c.genCust                                -- Operation 63
    no c.fromC
    no c.toC
    c.state = OpenState                                -- Operation 8
    c.cur   = c.genCust                                -- Operation 75
    c.nextSn  = plus[c.sn, 1]                           -- Operation 37
}

-- transferWrites: what an admitted [Transfer] writes over the chain record it found: the
-- chain is open (Operation 12) and the to custodian reference not blank (Operation 17).
-- The transferred entry (Operation 20, 66) takes next sequence number (Operation 36),
-- carries no custodian reference (State 5), reads its from custodian reference from the
-- current custodian (Operation 19, 67) and carries the call's to custodian reference
-- (Operation 68); the current custodian becomes it (Operation 21).
pred transferWrites[p : Call, c : TransferCall] {
    p.state = OpenState                                -- Operation 12
    c.toIn not in Refs.blank                           -- Operation 17
    c.sn   = p.nextSn                                   -- Operation 36
    c.etype = Transferred                              -- Operation 66
    no c.cust                                          -- State 5
    c.fromC = p.cur                                    -- Operation 19, 67
    c.toC   = c.toIn                                   -- Operation 68
    c.state = p.state
    c.cur   = c.toIn                                   -- Operation 21
    c.nextSn  = plus[p.nextSn, 1]                          -- Operation 37
}

-- guardedWrites: what an admitted [Transform], [Disclose] or [Archive] writes over the
-- chain record it found: the chain is open (Operation 13 to 15), the custodian reference
-- is not blank (Operation 23) and is the current custodian (Operation 26). The entry
-- takes next sequence number (Operation 36), its own event type (Operation 69, 71, 73)
-- and the call's custodian reference (Operation 70, 72, 74); [Archive] stands the chain
-- archived (Operation 31), and none moves the current custodian (Operation 32 to 34).
pred guardedWrites[p : Call, c : GuardedCall] {
    p.state = OpenState                                -- Operation 13 to 15
    c.actIn not in Refs.blank                          -- Operation 23
    -- BUG: Operation 26 dropped (was c.actIn = p.cur)
    c.sn   = p.nextSn                                   -- Operation 36
    c.etype = eventOf[c]                               -- Operation 69, 71, 73
    c.cust  = c.actIn                                  -- Operation 70, 72, 74
    no c.fromC
    no c.toC
    c.state = (c in ArchiveCall => ArchivedState else p.state)   -- Operation 31
    c.cur   = p.cur                                    -- Operation 32 to 34
    c.nextSn  = plus[p.nextSn, 1]                          -- Operation 37
}

-- written: the call's entry and chain record are what its write left: [Originate] opens
-- the chain; every other call writes over the chain record the call before it left.
pred written[c : Call] {
    c in OriginateCall => originateWrites[c]
    else (some c.prev and
          (c in TransferCall => transferWrites[c.prev, c]
           else guardedWrites[c.prev, c]))
}

-- recorded: a state the page lets the chain hold: one chain, opened by one call, and
-- every call on it an admitted call whose write left what the page says.
pred recorded {
    lone c : Call | no c.prev
    all c : Call | written[c]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Inv4_2: every custodian-guarded entry names, as its custodian reference, the custodian
-- the replay carried into it (Invariant 4.2, Check 3.3).
assert A_Inv4_2 {
    recorded implies all g : GuardedCall | g.cust = custodyFound[g]
}
check A_Inv4_2 for 5 but 4 Int

-- A_Inv4_3: every transferred entry's from custodian reference is the custodian the replay
-- carried into it: no transfer names a false predecessor (Invariant 4.3, Check 3.2).
assert A_Inv4_3 {
    recorded implies all t : TransferCall | t.fromC = custodyFound[t]
}
check A_Inv4_3 for 5 but 4 Int

-- A_Inv4_4: every transferred entry's to custodian reference is the current custodian the
-- chain record holds after it (Invariant 4.4).
assert A_Inv4_4 {
    recorded implies all t : TransferCall | t.toC = t.cur
}
check A_Inv4_4 for 5 but 4 Int

-- A_Inv5_1: no two entries of the chain share a sequence number (Invariant 5.1,
-- Check 4.3).
assert A_Inv5_1 {
    recorded implies all disj a, b : Call | a.sn != b.sn
}
check A_Inv5_1 for 5 but 4 Int

-- A_Inv7_1: every non-transferred entry carries one custodian reference, and it is not
-- blank (Invariant 7.1, Check 1.1).
assert A_Inv7_1 {
    recorded implies all e : Call - TransferCall | one e.cust and e.cust not in Refs.blank
}
check A_Inv7_1 for 5 but 4 Int

-- A_Inv7_2: every transferred entry carries one from and one to custodian reference,
-- neither blank (Invariant 7.2, Check 1.2).
assert A_Inv7_2 {
    recorded implies all t : TransferCall |
        one t.fromC and one t.toC and no (t.fromC + t.toC) & Refs.blank
}
check A_Inv7_2 for 5 but 4 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowSingleGenesis: a chain just opened by an originated genesis entry, as chain-0041 at
-- manuf-lab-7.
run ShowSingleGenesis {
    recorded
    one Call
    Call.etype = Originated
} for 5 but 4 Int

-- ShowReceivedGenesis: a chain opened by a received genesis entry, a second custody
-- episode for a returned batch, as chain-0052 at qa-returns-2.
run ShowReceivedGenesis {
    recorded
    one Call
    Call.etype = Received
} for 5 but 4 Int

-- ShowTransferChain: custody handed from one custodian to another.
run ShowTransferChain {
    recorded
    some t : TransferCall | t.fromC != t.toC
} for 5 but 4 Int

-- ShowGuardedAfterTransfer: the incoming custodian transforms the artifact after a
-- transfer, as the forensic lab on chain-0107.
run ShowGuardedAfterTransfer {
    recorded
    some t : TransferCall, g : TransformCall | t.fromC != t.toC and g.sn > t.sn
} for 5 but 4 Int

-- ShowFullLifecycle: originated, transferred, transformed, disclosed and archived, custody
-- changing once and the chain closed by its current custodian.
run ShowFullLifecycle {
    recorded
    some TransferCall
    some TransformCall
    some DiscloseCall
    some a : ArchiveCall | a.state = ArchivedState
    some t : TransferCall | t.fromC != t.toC
} for 5 but 4 Int
