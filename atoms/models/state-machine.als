-- state-machine.als
-- Alloy structural model for the Grace Commons State Machine atom
-- (atoms/state-machine.md)
--
-- PURPOSE
-- Verify the load-bearing structural invariants by bounded exhaustive search:
--   Invariant 3 — only-declared-transitions fire (every history entry corresponds
--                 to a declared transition);
--   Invariant 4 — terminal absorption (no transition fires from a terminal state);
--   Invariant 7 — replay determinism (the history is a single linear chain whose
--                 tail uniquely determines current_state; head starts at initial);
--   plus the determinism constraint on the declaration (at most one declared
--   transition per (from_state, action)) and chain consistency (consecutive
--   entries agree: entry[n].to_state = entry[n+1].from_state).
--
-- MODELING APPROACH (mirrors atoms/provenance.als linear-chain style;
-- relations are named `successor`/`predecessor`, NOT succ/pred, which are Alloy
-- built-ins).
-- One workflow instance: a declaration (a set of Trans triples + initial + terminal)
-- and a linear history chain of Entry records. current_state is derived as the tail
-- entry's to_state (or initial if the history is empty). Guard-gating (Invariant 8)
-- is an action-enablement property, not a static state predicate, so it is
-- deliberately out of model scope (cf. Medication Order Inv 9).
--
-- NOT MODELED HERE
-- - Guard evaluation / guard-gating (action-enablement; caller's obligation)
-- - Clock semantics / fired_at ordering (sequence_number is the order source)
-- - actor_ref attribution, tamper-evidence, retention (composing concerns)
-- - storage-failure atomicity (implementation obligation)
--
-- HOW TO READ THE RESULTS
-- Every "check A_*" should return UNSAT (the guarantee holds). Every "run Show*"
-- should return SAT (the configuration space is non-empty).

module state_machine

abstract sig St {}          -- a declared state
abstract sig Action {}      -- a declared transition trigger

-- A declared transition: from --action--> to.
sig Trans {
    tfrom : one St,
    tact  : one Action,
    tto   : one St
}

-- The instance's declaration scalars: the initial state and the terminal set.
one sig Config {
    initial  : one St,
    terminal : set St
}

-- A transition-history entry (one per successful `fire`), linked into a linear chain.
sig Entry {
    successor   : lone Entry,
    predecessor : lone Entry,
    efrom       : one St,    -- from_state recorded on the entry
    eact        : one Action,-- action recorded on the entry
    eto         : one St     -- to_state recorded on the entry
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Well-formedness facts (constrain the universe to VALID instances)
-- ─────────────────────────────────────────────────────────────────────────────

-- Linear history chain (mirror provenance.als): acyclic, singly-linked, no merge.
-- No merging is not a fact: it follows from SuccPredInverse with the `lone`
-- predecessor (and again from SingleHistoryChain with NoCycles), and
-- A_Linear_NoBranching checks it (2026-11-10; the fact NoMerging restated it).
fact NoCycles        { all x : Entry | x not in x.^successor }
fact NoSelfLoop      { all x : Entry | x.successor != x }
fact SuccPredInverse { all a, b : Entry | a.successor = b iff b.predecessor = a }

-- A single history chain per instance: at most one head (entry with no predecessor).
-- With linearity this yields a unique tail, hence a uniquely-determined current_state.
fact SingleHistoryChain { lone (Entry - Entry.successor) }

-- Determinism of the declaration: at most one declared transition per (from, action).
fact DeterministicDecl {
    all disj t1, t2 : Trans | not (t1.tfrom = t2.tfrom and t1.tact = t2.tact)
}

-- The declaration rejects a transition out of a terminal state (instantiate guard).
fact TerminalNoOutgoingDecl {
    no t : Trans | t.tfrom in Config.terminal
}

-- The initial state is not terminal (instantiate guard).
fact InitialNotTerminal { Config.initial not in Config.terminal }

-- Invariant 3 — every history entry corresponds to a declared transition.
fact EveryEntryDeclared {
    all e : Entry | some t : Trans |
        t.tfrom = e.efrom and t.tact = e.eact and t.tto = e.eto
}

-- Chain consistency: consecutive entries agree (to_state of one = from_state of next).
fact ChainConsistency {
    all a, b : Entry | a.successor = b implies a.eto = b.efrom
}

-- The head entry (no predecessor) starts from the declared initial state.
fact HeadFromInitial {
    all e : Entry | (no e.predecessor) implies e.efrom = Config.initial
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions — each "check" must be UNSAT.
-- ─────────────────────────────────────────────────────────────────────────────

-- Checks that restated the model and went (2026-11-10, unit `tooling: every
-- check has a twin that breaks it`): A_Linear_AtMostOneSuccessor and
-- A_Linear_AtMostOnePredecessor (the `lone` fields), A_Linear_NoCycles (fact
-- NoCycles), A_Inv3_OnlyDeclaredTransitions (fact EveryEntryDeclared),
-- A_DeterministicDecl (fact DeterministicDecl), A_ChainConsistency (fact
-- ChainConsistency), A_Inv7_ReplayUniqueTail (fact SingleHistoryChain) and
-- A_Inv7_HeadFromInitial (fact HeadFromInitial). The facts stay as the model's
-- assumptions; no twin of a static snapshot can break them.

-- Linear history: no entry is named as successor by two entries.
assert A_Linear_NoBranching          { all x : Entry | lone (successor.x) }
check A_Linear_NoBranching for 7

-- Invariant 4 — terminal absorption: no entry fires from a terminal state.
assert A_Inv4_TerminalAbsorption {
    no e : Entry | e.efrom in Config.terminal
}
check A_Inv4_TerminalAbsorption for 7

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — each must be SAT (non-vacuity guards).
-- ─────────────────────────────────────────────────────────────────────────────

-- The simplest valid instance: a declaration, no transitions fired yet (current = initial).
run ShowEmptyHistory {
    no Entry
    some Trans
} for 4

-- A single fired transition from the initial state.
run ShowSingleTransition {
    one Entry
    some e : Entry | no e.predecessor and no e.successor and e.efrom = Config.initial
} for 4

-- A two-transition chain: initial -> s1 -> s2, both declared, linear history.
run ShowTwoStepChain {
    some disj a, b : Entry | {
        a.successor = b
        b.predecessor = a
        no a.predecessor
        no b.successor
        a.efrom = Config.initial
        a.eto = b.efrom
    }
} for 5

-- A chain that reaches a terminal state at its tail.
run ShowReachTerminal {
    some e : Entry | no e.successor and e.eto in Config.terminal
    some Config.terminal
} for 5
