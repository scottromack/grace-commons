-- reaction.als
-- Alloy structural model for the Reaction atom (Grace Commons atoms/reaction.md)
-- Grounded on Final Critique 1, 2026-11-14 at b585a81 — Alloy layer authored 2026-11-15.
-- Derived validator; the English spec is the single source of truth. On any
-- disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
--
-- PURPOSE
-- Verify, by bounded exhaustive search, the STATIC data model of Reaction: what the reactions
-- the database holds, every version of each (Execution Contract Database 5), must satisfy in
-- any one state, whatever calls wrote them. The page's single-state rules are checked here;
-- everything that happens across steps (no reaction removed, a reaction's first reacted
-- instant, person reference, item reference and reaction name never changed, what [React]
-- and [Withdraw] do to a status and to a rival, which calls write nothing, what every call
-- answers, and the order [Look Up] and [Count] answer in) is the TLA+ model's, reaction.tla.
--
-- RULES ENCODED (named by the page's own labels)
--   State 1        — every reaction carries person reference, item reference, reaction name,
--                    first reacted instant and status (Check 1.1).
--   State 2        — every reaction stands in exactly one of held, withdrawn (Check 1.2).
--   Identity 3     — two person references compared codepoint for codepoint: a [React] or a
--                    [Withdraw] writes only reactions carrying the very person reference the
--                    call carried.
--   Identity 5     — the same for two item references.
--   Identity 7     — the same for two reaction names: a [Withdraw], or a [React] standing a
--                    reaction in held, writes only the reaction carrying the very reaction
--                    name the call carried.
--   Operation 4    — every version a [React] stood in held carries a reaction name the
--                    reaction set offered at that call (Term reaction name: "one of the
--                    reaction set the deployment offered"); which refusal a name outside the
--                    set answers is the TLA+ model's.
--   Operation 5    — the reaction [React] records carries the triple of the call, as the call
--                    carried it (Identity 2, 4 and 6, never normalized, are checked through
--                    it; EXACTLY ONE reaction per [React] is the TLA+ model's).
--   Operation 6    — every version of a reaction carries as its first reacted instant the now
--                    the seam gave the [React] that recorded it (Term first reacted instant:
--                    "set once, never changed").
--   Operation 7    — the reaction [React] records stands in held.
--   Invariant 1.1  — no two reactions share a triple (Check 2.1); Identity 1 is checked
--                    through it.
--
-- NOT CHECKED HERE (across steps; the TLA+ model's)
--   State 3 (no reaction removed) and Invariant 2.1 to 2.4 (a reaction never changes whose it
--   is or what it says): each compares a reaction with a later state of itself. Operation 5's
--   EXACTLY ONE, 8 to 11 and 13 to 15 (what a writing action does to a status or a rival, or
--   that it writes nothing), 1 to 4 and 23 to 25 (the refusals), 12 and 16 to 22 and 26 to 30
--   (what a call answers, that a query writes nothing, and the order of the lists) show only
--   in a step.
--
-- SCOPE
-- A state is what a sequence of calls leaves. Each call is one atom, in the order Execution
-- Contract Order 1 gives every commit, and reads every commit before it (Execution Contract
-- Database 2). A [React] call carries the reaction set and the holding rule the deployment
-- declared when it ran (Capability requirement 7, 8), any set and either rule, since the
-- deployment may change them between calls. [React] records a reaction where the triple has
-- none, its first version (Operation 5 to 7); [React] on a withdrawn reaction, [React] under
-- one-per-item on each rival, and [Withdraw] on a held reaction record a later version over
-- the version they found (Operation 8, 10, 13), in the commit of the call (Execution Contract
-- Database 1), and the earlier versions stay (Execution Contract Database 5). A call that
-- writes nothing (Operation 9, 14, 15), a refused call and a query add no record. Every record
-- a state holds is one an admitted call wrote: the guards of a call read the reactions the
-- earlier records make, so the model asks it of all of them at once (the predicate Scope), and
-- every check and run is stated over a Scope. No trace, no `var`, no stepping. Person
-- references, item references, reaction names and instants are opaque tokens: two different
-- tokens are two different strings.
--
-- NOT MODELED HERE
--   - The refusals (Operation 1 to 3, 23 to 25, and Operation 4's answer): a refused call
--     writes nothing (Execution Contract Read 4), so it adds no record; which refusal answers
--     is the TLA+ model's. So a blank value, one over the string cap, or one that is not a
--     string never reaches a record here.
--   - [Look Up] and [Count] (Operation 17 to 22, 26 to 30): a query writes nothing, so it adds
--     no record; the TLA+ model reads what they answer.
--   - Storage failure and the failed read (Execution Contract Database 3, Read 1): a write
--     that did not commit leaves nothing.
--   - The deployment's own duties at the seam (Capability requirement 4 to 6: no value
--     normalized; Capability requirement 9: no blank or over-cap name declared): the model
--     takes each value as the call carries it and each reaction set as declared; the atom's
--     own share (Identity 2, 4, 6) is checked through Operation 5.
--   - Who may react or read, the catalog, telling the author, scores, votes, favorites, save
--     for later, drawing and listing who reacted (Non-goal 1 to 10): no action here writes
--     them.
--
-- HOW TO READ RESULTS
-- Every "check A_*" must return "No counterexample found" (UNSAT) — the asserted guarantee holds.
-- Every "run Show*" must return at least one instance (SAT) — confirms non-vacuity.
-- A "check" returning a counterexample is a spec finding.

module reaction

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- PersonRef: a string a call carries as a person reference, such as ana or Ana, which the
-- atom compares codepoint for codepoint, so two different strings are two different atoms
-- (Term person reference, Identity 3).
sig PersonRef {}

-- ItemRef: a string a call carries as an item reference, such as post-41 or Post-41,
-- compared codepoint for codepoint (Term item reference, Identity 5).
sig ItemRef {}

-- ReactionName: a word a call carries as a reaction name, such as like or Like, compared
-- codepoint for codepoint (Term reaction name, Identity 7).
sig ReactionName {}

-- Instant: a clock reading the host injects at the seam as now (Capability requirement 2,
-- Execution Contract Logic confinement 11). No rule here turns on the order of two readings.
sig Instant {}

-- Status: where a reaction stands (Term status).
abstract sig Status {}

-- Held: the status of a reaction the person keeps on the item; it counts (Term held).
one sig Held extends Status {}

-- Withdrawn: the status of a reaction the person took back or replaced; it counts for
-- nothing (Term withdrawn).
one sig Withdrawn extends Status {}

-- HoldingRule: how many reactions a person may hold on one item (Term holding rule).
abstract sig HoldingRule {}

-- OnePerItem: one reaction in all; choosing another replaces the first.
one sig OnePerItem extends HoldingRule {}

-- OneOfEach: one reaction in each reaction name.
one sig OneOfEach extends HoldingRule {}

-- Normalizer: what a normalizer that folds case would rewrite a value to, where the result
-- differs (ana for Ana, post-41 for Post-41, like for Like). The page forbids it (Identity 2
-- to 7, Capability requirement 4 to 6): the model's own actions never apply it. It is here so
-- a run can show two values one normalizer would merge, and so a twin can apply it.
one sig Normalizer {
    foldPerson : PersonRef -> lone PersonRef,
    foldItem   : ItemRef -> lone ItemRef,
    foldName   : ReactionName -> lone ReactionName
}

-- Call: one call of a writing action ([React], [Withdraw]) with the triple it carries, and
-- the now the seam gives it. Calls happen in one order, the order Execution Contract Order 1
-- gives every commit.
abstract sig Call {
    callPerson : one PersonRef,     -- person_reference
    callItem   : one ItemRef,       -- item_reference
    callName   : one ReactionName,  -- reaction_name
    now        : one Instant        -- the clock reading injected at the seam
}

-- ReactCall: one [React] call, react(person_reference, item_reference, reaction_name), with
-- the reaction set and the holding rule the deployment declared when it ran (Capability
-- requirement 7, 8): inputs from outside the atom, any set and either rule.
sig ReactCall extends Call {
    offered : set ReactionName,     -- the reaction set
    rule    : one HoldingRule       -- the holding rule
}

-- WithdrawCall: one [Withdraw] call, withdraw(person_reference, item_reference,
-- reaction_name).
sig WithdrawCall extends Call {}

-- Reaction: one version of a reaction record (Term records, Term version), as the call that
-- wrote it left it. Every field the page names may be absent and the status may hold either
-- member or both, so a write that forgot a field or stood a reaction in two statuses would
-- show; what the page promises (State 1, 2) is checked, never built into the type. The last
-- two fields are the model's own: which call wrote this version, and which version the call
-- found.
sig Reaction {
    personRef    : lone PersonRef,     -- person reference
    itemRef      : lone ItemRef,       -- item reference
    reactionName : lone ReactionName,  -- reaction name
    firstReacted : lone Instant,       -- first reacted instant
    status       : set Status,         -- status
    writtenBy    : one Call,
    found        : lone Reaction
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- first: the first version of the reaction this version belongs to, the one [React] wrote.
fun first[g : Reaction] : set Reaction {
    { v : g.*found | no v.found }
}

-- origin: the [React] call that recorded the reaction this version belongs to. Two versions
-- with one origin are one reaction; two origins are two reactions.
fun origin[g : Reaction] : set ReactCall {
    first[g].writtenBy & ReactCall
}

-- currentAt: the version is its reaction's latest version when call c runs: it was written
-- before c, and no later version of the same reaction was written before c (Execution
-- Contract Database 2).
pred currentAt[v : Reaction, c : Call] {
    C/lt[v.writtenBy, c]
    no w : Reaction | origin[w] = origin[v] and C/lt[v.writtenBy, w.writtenBy]
        and C/lt[w.writtenBy, c]
}

-- forPair: the version carries the pair the call carries, each reference compared codepoint
-- for codepoint (Term pair, Identity 3, 5).
pred forPair[v : Reaction, c : Call] {
    v.personRef = c.callPerson
    v.itemRef = c.callItem
}

-- forTriple: the version carries the triple the call carries, each value compared codepoint
-- for codepoint (Term triple, Identity 3, 5, 7).
pred forTriple[v : Reaction, c : Call] {
    forPair[v, c]
    v.reactionName = c.callName
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- reactRecords: the reaction an admitted [React] records where no reaction exists for the
-- triple (Operation 5): the reaction set offers the name (Operation 4); it carries the triple
-- as the call carried it (Operation 5, Identity 2, 4, 6), the first reacted instant from the
-- injected now (Operation 6), and stands in held (Operation 7).
pred reactRecords[c : ReactCall, g : Reaction] {
    c.callName in c.offered                                       -- Operation 4
    no v : Reaction | currentAt[v, c] and forTriple[v, c]         -- Operation 5
    g.personRef    = c.callPerson                                 -- Operation 5, Identity 2
    g.itemRef      = c.callItem                                   -- Operation 5, Identity 4
    g.reactionName = c.callName                                   -- Operation 5, Identity 6
    g.firstReacted = c.now                                        -- Operation 6
    g.status       = Held                                         -- Operation 7
}

-- reactReholds: the version an admitted [React] records over the reaction it found for the
-- triple, standing in withdrawn (Operation 8): the reaction stands in held, and keeps every
-- other field (the case table: "its first reacted instant stands"). A held reaction is not
-- changed (Operation 9).
pred reactReholds[pre : Reaction, c : ReactCall, g : Reaction] {
    c.callName in c.offered                                       -- Operation 4
    currentAt[pre, c]
    forTriple[pre, c]                                             -- Identity 3, 5, 7
    pre.status = Withdrawn                                        -- Operation 8, 9
    g.personRef    = pre.personRef
    g.itemRef      = pre.itemRef
    g.reactionName = pre.reactionName
    g.firstReacted = pre.firstReacted
    g.status       = Held                                         -- Operation 8
}

-- reactReplaces: the version an admitted [React] under one-per-item records over a rival it
-- found, a held reaction carrying the call's pair and another reaction name (Term rival,
-- Operation 10): the rival stands in withdrawn, in the same commit, and keeps every other
-- field. Under one-of-each no rival is written (Operation 11).
pred reactReplaces[pre : Reaction, c : ReactCall, g : Reaction] {
    c.callName in c.offered                                       -- Operation 4
    c.rule = OnePerItem                                           -- Operation 10, 11
    currentAt[pre, c]
    forPair[pre, c]                                               -- Identity 3, 5
    pre.reactionName != c.callName                                -- Term rival, Identity 7
    pre.status = Held                                             -- Term rival
    g.personRef    = pre.personRef
    g.itemRef      = pre.itemRef
    g.reactionName = pre.reactionName
    g.firstReacted = pre.firstReacted
    g.status       = Withdrawn                                    -- Operation 10
}

-- withdrawWrites: the version an admitted [Withdraw] records over the reaction it found for
-- the triple, standing in held (Operation 13): the reaction stands in withdrawn and keeps
-- every other field; nothing is removed (State 3). A withdrawn reaction, or a triple with
-- none, is not written (Operation 14, 15). [Withdraw] reads no reaction set: a reaction held
-- in a name the deployment dropped may still be withdrawn (the Edge case on a changing
-- reaction set).
pred withdrawWrites[pre : Reaction, c : WithdrawCall, g : Reaction] {
    currentAt[pre, c]
    forTriple[pre, c]                                             -- Identity 3, 5, 7
    pre.status = Held                                             -- Operation 13, 14
    g.personRef    = pre.personRef
    g.itemRef      = pre.itemRef
    g.reactionName = pre.reactionName
    g.firstReacted = pre.firstReacted
    g.status       = Withdrawn                                    -- Operation 13
}

-- written: the version is what its call's write left: a [React] writes a first version, a
-- version over the withdrawn reaction it found for the triple, or a version over a rival it
-- found; a [Withdraw] writes over the held reaction it found.
pred written[g : Reaction] {
    let c = g.writtenBy {
        (c in ReactCall and no g.found and reactRecords[c, g])
        or (c in ReactCall and some g.found and reactReholds[g.found, c, g])
        or (c in ReactCall and some g.found and reactReplaces[g.found, c, g])
        or (c in WithdrawCall and some g.found and withdrawWrites[g.found, c, g])
    }
}

-- Scope: every version the state holds is one an admitted call wrote (see SCOPE). It is the
-- model's universe, not a rule of the page: each check reads "in any state the calls can
-- leave".
pred Scope {
    all g : Reaction | written[g]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every version of every reaction carries its person reference, item reference,
-- reaction name, first reacted instant and status, however often it was chosen, replaced and
-- taken back (State 1, Check 1.1).
assert A_State_1 {
    Scope implies all g : Reaction | {
        some g.personRef
        some g.itemRef
        some g.reactionName
        some g.firstReacted
        some g.status
    }
}
check A_State_1 for 4

-- A_State_2: every version of every reaction stands in exactly one of held and withdrawn
-- (State 2, Check 1.2).
assert A_State_2 {
    Scope implies all g : Reaction | one g.status
}
check A_State_2 for 4

-- A_Identity_3: every version a [React] or a [Withdraw] wrote over a reaction it found is of
-- a reaction carrying the very person reference the call carried, codepoint for codepoint:
-- withdraw("Ana", ...) never takes back a reaction of ana (Identity 3).
assert A_Identity_3 {
    Scope implies all g : Reaction | some g.found implies
        g.writtenBy.callPerson = g.found.personRef
}
check A_Identity_3 for 4

-- A_Identity_5: every version a [React] or a [Withdraw] wrote over a reaction it found is of
-- a reaction carrying the very item reference the call carried, codepoint for codepoint
-- (Identity 5).
assert A_Identity_5 {
    Scope implies all g : Reaction | some g.found implies
        g.writtenBy.callItem = g.found.itemRef
}
check A_Identity_5 for 4

-- A_Identity_7: every version a [Withdraw] wrote, or a [React] stood in held, over a reaction
-- it found is of the reaction carrying the very reaction name the call carried, codepoint for
-- codepoint: withdraw("ana", "post-41", "Like") never takes back ana's like (Identity 7).
assert A_Identity_7 {
    Scope implies all g : Reaction |
        (some g.found and (g.writtenBy in WithdrawCall or Held in g.status)) implies
            g.writtenBy.callName = g.found.reactionName
}
check A_Identity_7 for 4

-- A_Operation_4: every version a [React] stood in held carries a reaction name the reaction
-- set offered when that [React] ran: react("ana", "post-41", "wow") never holds wow on the
-- forum, and a name the deployment dropped is never held again (Operation 4, the Edge case on
-- a changing reaction set).
assert A_Operation_4 {
    Scope implies all g : Reaction | (g.writtenBy in ReactCall and Held in g.status) implies
        g.reactionName in g.writtenBy.offered
}
check A_Operation_4 for 4

-- A_Operation_5: the reaction a [React] recorded carries the person reference, the item
-- reference and the reaction name the call carried, as it carried them, never rewritten into
-- another form (Operation 5, Identity 2, 4, 6).
assert A_Operation_5 {
    Scope implies all g : Reaction | no g.found implies {
        g.personRef = origin[g].callPerson
        g.itemRef = origin[g].callItem
        g.reactionName = origin[g].callName
    }
}
check A_Operation_5 for 4

-- A_Operation_6: every version of every reaction carries as its first reacted instant the now
-- the seam gave the [React] that recorded it, so a reaction taken back and chosen again keeps
-- the instant it always had (Operation 6, Term first reacted instant).
assert A_Operation_6 {
    Scope implies all g : Reaction | g.firstReacted = origin[g].now
}
check A_Operation_6 for 4

-- A_Operation_7: the reaction a [React] recorded stands in held: the first tap counts
-- (Operation 7).
assert A_Operation_7 {
    Scope implies all g : Reaction | no g.found implies g.status = Held
}
check A_Operation_7 for 4

-- A_Invariant_1_1: no two reactions share a triple: a person holds a reaction for one triple
-- once or not at all, the versions of each reaction included (Invariant 1.1, Check 2.1).
assert A_Invariant_1_1 {
    Scope implies all g1, g2 : Reaction | origin[g1] != origin[g2] implies
        not (g1.personRef = g2.personRef and g1.itemRef = g2.itemRef
             and g1.reactionName = g2.reactionName)
}
check A_Invariant_1_1 for 4

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowHeld: a reaction just chosen, as react("ana", "post-41", "like").
run ShowHeld {
    Scope and some g : Reaction | no g.found
} for 4

-- ShowWithdrawn: a reaction taken back, kept with its first reacted instant, as ana's love
-- after she taps it again.
run ShowWithdrawn {
    Scope and some g : Reaction | g.writtenBy in WithdrawCall and g.status = Withdrawn
} for 4

-- ShowReheld: a reaction chosen again after it was taken back, carrying the first reacted
-- instant of its first [React], not the now of the [React] that held it again.
run ShowReheld {
    Scope and some g : Reaction | g.writtenBy in ReactCall and some g.found
        and g.status = Held and g.firstReacted != g.writtenBy.now
} for 4

-- ShowReplaced: under one-per-item a reaction replaced by the person's next reaction on the
-- item, in the same commit: ana's like withdrawn when she chooses love (the forum).
run ShowReplaced {
    Scope and some g : Reaction | g.writtenBy in ReactCall and some g.found
        and g.status = Withdrawn and g.writtenBy.rule = OnePerItem
} for 4

-- ShowOneOfEach: under one-of-each two reactions of one person on one item in two reaction
-- names, as r7's thanks and eyes on msg-9 (the team chat).
run ShowOneOfEach {
    Scope and some disj g1, g2 : Reaction | no g1.found and no g2.found
        and g1.personRef = g2.personRef and g1.itemRef = g2.itemRef
        and g1.reactionName != g2.reactionName and g2.writtenBy.rule = OneOfEach
} for 4

-- ShowTallyOfTwo: two persons holding one reaction name on one item, as like with a tally of
-- 2.
run ShowTallyOfTwo {
    Scope and some g1, g2 : Reaction | origin[g1] != origin[g2]
        and g1.itemRef = g2.itemRef and g1.reactionName = g2.reactionName
        and g1.personRef != g2.personRef
} for 4

-- ShowDroppedNameWithdrawn: a reaction held in a reaction name the deployment later dropped,
-- taken back by its person (the Edge case on a changing reaction set).
run ShowDroppedNameWithdrawn {
    Scope and some g : Reaction | g.writtenBy in WithdrawCall and some g.found
        and some c : ReactCall | C/lt[origin[g], c] and C/lt[c, g.writtenBy]
            and g.reactionName not in c.offered
} for 4

-- ShowCaseVariantNames: one person's two reactions on one item whose reaction names one
-- normalizer would merge, like and Like, each its own reaction where a deployment offers both
-- (Identity 6, 7).
run ShowCaseVariantNames {
    Scope and some g1, g2 : Reaction | origin[g1] != origin[g2]
        and g1.personRef = g2.personRef and g1.itemRef = g2.itemRef
        and g2.reactionName = g1.reactionName.(Normalizer.foldName)
} for 4

-- ShowCaseVariantItems: one person's two reactions in one name whose item references one
-- normalizer would merge, post-41 and Post-41, each its own reaction (Identity 4, 5).
run ShowCaseVariantItems {
    Scope and some g1, g2 : Reaction | origin[g1] != origin[g2]
        and g1.personRef = g2.personRef and g1.reactionName = g2.reactionName
        and g2.itemRef = g1.itemRef.(Normalizer.foldItem)
} for 4

-- ShowCaseVariantPersons: two persons whose person references one normalizer would merge, ana
-- and Ana, each holding one reaction name on one item (Identity 2, 3).
run ShowCaseVariantPersons {
    Scope and some g1, g2 : Reaction | origin[g1] != origin[g2]
        and g1.itemRef = g2.itemRef and g1.reactionName = g2.reactionName
        and g2.personRef = g1.personRef.(Normalizer.foldPerson)
} for 4
