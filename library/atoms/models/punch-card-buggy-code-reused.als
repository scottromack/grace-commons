-- punch-card-buggy-code-reused.als
-- DELIBERATELY WRONG twin of punch-card.als (unit: `atoms/punch-card.md formal layer`).
--
-- INJECTED DEFECT: [Issue] may record a card code the seam supplied an earlier [Issue], a code
-- recycled, not the one it supplied this call (Identity 7, Capability requirement 2).
--
-- BREAKS: A_Identity_7.
-- Everything else is punch-card.als as written; read its comments there.

module punch_card_buggy_code_reused

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- CardId: an opaque card id (Term card id), which the host supplies at the seam on [Issue].
sig CardId {}

-- Code: a string a call carries or the seam supplies as a card code, such as 7KQ9M2XV4RTP8HNC
-- or 7kq9m2xv4rtp8hnc, which the atom compares codepoint for codepoint, so two different
-- strings are two different atoms (Term card code, Identity 9).
sig Code {}

-- Normalizer: what a normalizer that folds case or trims would rewrite a code to, where the
-- result differs from the code (7KQ9 for 7kq9). The page forbids it (Identity 8, Capability
-- requirement 7): the model's own actions never apply it. It is here so a run can show two
-- codes one normalizer would merge, and so a twin can apply it.
one sig Normalizer {
    foldCode : Code -> lone Code
}

-- Call: one call of a writing action ([Issue], [Stamp], [Redeem]). Calls happen in one order,
-- the order Execution Contract Order 1 gives every commit.
abstract sig Call {}

-- IssueCall: one [Issue] call, issue(). The seam supplies it a card id and a card code
-- (Capability requirement 1, 2); the action allocates neither. `declared` is the stamp goal
-- the deployment declared for the instance's start the call ran under, read at that start
-- (Execution Contract Logic confinement 17), or none where it declared none.
sig IssueCall extends Call {
    seamId   : one CardId,    -- the card id the seam supplies this call
    seamCode : one Code,      -- the card code the seam supplies this call
    declared : lone Int       -- the stamp goal the deployment declared, if any
}

-- StampCall: one [Stamp] call, stamp(card_code).
sig StampCall extends Call {
    stampCode : one Code      -- card_code
}

-- RedeemCall: one [Redeem] call, redeem(card_code).
sig RedeemCall extends Call {
    redeemCode : one Code     -- card_code
}

-- PunchCard: one version of a punch card record (Term records, Term version), as the call that
-- wrote it left it. Every field the page names may be absent, so a write that forgot one would
-- show; what the page promises (State 1) is checked, never built into the type. The last two
-- fields are the model's own: which call wrote this version, and which version a [Stamp] or a
-- [Redeem] found.
sig PunchCard {
    cardId      : lone CardId,  -- card id (Identity 1)
    code        : lone Code,    -- card code (Identity 2)
    goal        : lone Int,     -- goal
    stamps      : lone Int,     -- stamps
    redemptions : lone Int,     -- redemptions
    writtenBy   : one Call,
    found       : lone PunchCard
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The seam supplies each [Issue] a card id no punch card has carried (Capability requirement
-- 1 and 8, Execution Contract Logic confinement 3 and 16): two [Issue] calls never get one id.
fact SeamSuppliesFreshCardIds {
    all disj a, b : IssueCall | a.seamId != b.seamId
}

-- The seam supplies each [Issue] a card code no punch card has carried (Capability requirement
-- 2 and 9, Execution Contract Logic confinement 3 and 16): two [Issue] calls never get one code.
fact SeamSuppliesFreshCodes {
    all disj a, b : IssueCall | a.seamCode != b.seamCode
}

-- A stamp goal the deployment declares is a positive count (Capability requirement 5,
-- Execution Contract Input 2; Term stamp goal).
fact DeclaredStampGoalIsPositive {
    all i : IssueCall | all d : i.declared | d >= 1
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- stampGoal: the stamp goal an [Issue] reads: the one the deployment declared for the
-- instance's start, five where it declared none (Term stamp goal).
fun stampGoal[i : IssueCall] : set Int {
    (some i.declared) => i.declared else 5
}

-- first: the first version of the punch card this version belongs to, the one [Issue] wrote.
fun first[g : PunchCard] : set PunchCard {
    { v : g.*found | no v.found }
}

-- issuer: the [Issue] call that recorded the punch card this version belongs to. Two versions
-- with one issuer are one punch card; two issuers are two punch cards.
fun issuer[g : PunchCard] : set IssueCall {
    first[g].writtenBy & IssueCall
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- issueWrites: the punch card an admitted [Issue] records. It carries the card id and the card
-- code the seam supplied, the code as supplied (Operation 1, Identity 8), the stamp goal as its
-- goal (Operation 2), and zero stamps and zero redemptions (Operation 3, 4). [Issue] has no
-- guard of its own: only a storage failure refuses it.
pred issueWrites[i : IssueCall, g : PunchCard] {
    g.cardId      = i.seamId                             -- Operation 1, Capability requirement 1
    some e : IssueCall | C/lte[e, i] and g.code = e.seamCode  -- BUG: an earlier call's code
    g.goal        = stampGoal[i]                         -- Operation 2
    g.stamps      = 0                                    -- Operation 3
    g.redemptions = 0                                    -- Operation 4
}

-- stampWrites: the version an admitted [Stamp] records over the version it found: the call
-- names that punch card by its card code, compared codepoint for codepoint (Identity 2, 4, 9);
-- the stamps are below the goal, since a punch card at its goal is refused as full (Operation 9;
-- the case table's "stamps below the goal"). The version carries the stamps plus one (Operation
-- 10); a call writes only the fields its own rules name, so the card id, the card code, the goal
-- and the redemptions stay as found.
pred stampWrites[pre : PunchCard, s : StampCall, g : PunchCard] {
    s.stampCode in pre.code                              -- Identity 4, 9
    pre.stamps < pre.goal                                -- Operation 9
    g.cardId      = pre.cardId
    g.code        = pre.code
    g.goal        = pre.goal
    g.redemptions = pre.redemptions
    g.stamps      = plus[pre.stamps, 1]                  -- Operation 10
}

-- redeemWrites: the version an admitted [Redeem] records over the version it found: the call
-- names that punch card by its card code, compared codepoint for codepoint (Identity 2, 5, 9);
-- the stamps equal the goal, since a punch card below it is refused as not-full (Operation 12).
-- The version carries zero stamps (Operation 13) and the redemptions plus one (Operation 14);
-- the card id, the card code and the goal stay as found.
pred redeemWrites[pre : PunchCard, r : RedeemCall, g : PunchCard] {
    r.redeemCode in pre.code                             -- Identity 5, 9
    pre.stamps = pre.goal                                -- Operation 12
    g.cardId      = pre.cardId
    g.code        = pre.code
    g.goal        = pre.goal
    g.stamps      = 0                                    -- Operation 13
    g.redemptions = plus[pre.redemptions, 1]             -- Operation 14
}

-- written: the version is what its call's write left: an [Issue] writes a first version; a
-- [Stamp] or a [Redeem] writes over a version an earlier call wrote (a call finds only what was
-- committed before it, Execution Contract Database 2).
pred written[g : PunchCard] {
    let c = g.writtenBy {
        (c in IssueCall and no g.found and issueWrites[c, g])
        or (c in StampCall and some g.found
            and C/lt[g.found.writtenBy, c] and stampWrites[g.found, c, g])
        or (c in RedeemCall and some g.found
            and C/lt[g.found.writtenBy, c] and redeemWrites[g.found, c, g])
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): it and every version it was
-- built from are what an admitted call wrote.
pred recorded[g : PunchCard] {
    all v : g.*found | written[v]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every version of every punch card carries its card id, card code, goal, stamps
-- and redemptions, however often it was stamped and redeemed (State 1, Check 1.1).
assert A_State_1 {
    all g : PunchCard | recorded[g] implies {
        some g.cardId
        some g.code
        some g.goal
        some g.stamps
        some g.redemptions
    }
}
check A_State_1 for 4 but 4 Int

-- A_Identity_6: no two punch cards share a card id: two punch cards two [Issue] calls recorded
-- never carry one id, the versions of each included (Identity 6, Check 2.1).
assert A_Identity_6 {
    all g1, g2 : PunchCard | (recorded[g1] and recorded[g2] and issuer[g1] != issuer[g2])
        implies no (g1.cardId & g2.cardId)
}
check A_Identity_6 for 4 but 4 Int

-- A_Identity_7: no two punch cards share a card code, so a code names one punch card to stamp
-- or redeem (Identity 7, Check 2.2).
assert A_Identity_7 {
    all g1, g2 : PunchCard | (recorded[g1] and recorded[g2] and issuer[g1] != issuer[g2])
        implies no (g1.code & g2.code)
}
check A_Identity_7 for 4 but 4 Int

-- A_Identity_8: every punch card carries its card code as the seam supplied it to the [Issue]
-- that recorded it: 7KQ9M2XV4RTP8HNC stays as it is, never rewritten into another form
-- (Identity 8, Term card code: "stored as supplied").
assert A_Identity_8 {
    all g : PunchCard | recorded[g] implies g.code in issuer[g].seamCode
}
check A_Identity_8 for 4 but 4 Int

-- A_Identity_9: every version a [Stamp] or a [Redeem] wrote is of the punch card carrying the
-- very code the call presented, codepoint for codepoint: stamp("7kq9m2xv4rtp8hnc") stamps
-- nothing on the punch card 7KQ9M2XV4RTP8HNC names (Identity 9, the rejection paths).
assert A_Identity_9 {
    all g : PunchCard | recorded[g] implies {
        g.writtenBy in StampCall implies g.writtenBy.stampCode in g.found.code
        g.writtenBy in RedeemCall implies g.writtenBy.redeemCode in g.found.code
    }
}
check A_Identity_9 for 4 but 4 Int

-- A_Operation_1: every version of every punch card carries the card id the seam supplied the
-- [Issue] that recorded it, so the shop's records name it by the id the host gave it (Operation
-- 1, Identity 1, Term card id: "immutable").
assert A_Operation_1 {
    all g : PunchCard | recorded[g] implies g.cardId in issuer[g].seamId
}
check A_Operation_1 for 4 but 4 Int

-- A_Operation_2: the version [Issue] records, a punch card's first, carries the stamp goal as
-- its goal: the one declared for the instance's start, five where none was (Operation 2, Term
-- stamp goal; the thrift store's goal of five and the café's six).
assert A_Operation_2 {
    all g : PunchCard | (recorded[g] and no g.found) implies g.goal = stampGoal[issuer[g]]
}
check A_Operation_2 for 4 but 4 Int

-- A_Operation_3: the version [Issue] records carries zero stamps: a punch card starts empty
-- (Operation 3).
assert A_Operation_3 {
    all g : PunchCard | (recorded[g] and no g.found) implies g.stamps = 0
}
check A_Operation_3 for 4 but 4 Int

-- A_Operation_4: the version [Issue] records carries zero redemptions: a new punch card has
-- given no free item (Operation 4).
assert A_Operation_4 {
    all g : PunchCard | (recorded[g] and no g.found) implies g.redemptions = 0
}
check A_Operation_4 for 4 but 4 Int

-- A_Invariant_1_1: every version of every punch card carries a whole count, zero or more, as
-- its stamps (Invariant 1.1, Check 3.1).
assert A_Invariant_1_1 {
    all g : PunchCard | recorded[g] implies (all n : g.stamps | n >= 0)
}
check A_Invariant_1_1 for 4 but 4 Int

-- A_Invariant_1_2: no version of a punch card carries more stamps than its goal: a full punch
-- card takes no more until it is redeemed (Invariant 1.2, Check 3.2).
assert A_Invariant_1_2 {
    all g : PunchCard | recorded[g] implies
        (all n : g.stamps, m : g.goal | n <= m)
}
check A_Invariant_1_2 for 4 but 4 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowIssuedDefault: a punch card just issued where the deployment declared no stamp goal, its
-- goal five, as the thrift store's issue() answers issued(p1, "7KQ9M2XV4RTP8HNC").
run ShowIssuedDefault {
    some g : PunchCard | recorded[g] and no g.found and no issuer[g].declared and g.goal = 5
} for 4 but 4 Int

-- ShowIssuedDeclared: a punch card issued under a stamp goal the deployment declared, as the
-- café's goal of six.
run ShowIssuedDeclared {
    some g : PunchCard | recorded[g] and no g.found and some issuer[g].declared
        and g.goal = 6
} for 4 but 4 Int

-- ShowStamped: a punch card stamped part of the way to its goal.
run ShowStamped {
    some g : PunchCard | recorded[g] and g.writtenBy in StampCall
        and g.stamps > 0 and g.stamps < g.goal
} for 4 but 4 Int

-- ShowFull: a punch card stamped to its goal, which [Stamp] then refuses as full and [Redeem]
-- admits, as the thrift store's fifth stamp.
run ShowFull {
    some g : PunchCard | recorded[g] and g.writtenBy in StampCall and g.stamps = g.goal
} for 4 but 4 Int

-- ShowRedeemed: a punch card just redeemed, empty again with one redemption, as
-- redeem("7KQ9M2XV4RTP8HNC") answers 1.
run ShowRedeemed {
    some g : PunchCard | recorded[g] and g.writtenBy in RedeemCall
} for 4 but 4 Int

-- ShowStampedAfterRedeem: one punch card serving on after a free item, stamped again, as the
-- thrift store's next purchase answers 1.
run ShowStampedAfterRedeem {
    some g : PunchCard | recorded[g] and g.writtenBy in StampCall and g.redemptions > 0
} for 4 but 4 Int

-- ShowTwoGoals: two punch cards with two goals, as the café's punch card c3 keeps its goal of
-- six beside one issued after the stamp goal changed at a restart.
run ShowTwoGoals {
    some g1, g2 : PunchCard | recorded[g1] and recorded[g2] and g1.goal != g2.goal
} for 4 but 4 Int

-- ShowCaseVariantCodes: two punch cards whose codes one normalizer would merge, each its own
-- punch card (Identity 8, 9).
run ShowCaseVariantCodes {
    some g1, g2 : PunchCard | recorded[g1] and recorded[g2] and issuer[g1] != issuer[g2]
        and g2.code = g1.code.(Normalizer.foldCode)
} for 4 but 4 Int
