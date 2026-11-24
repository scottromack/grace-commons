-- gift-card.als
-- Alloy structural model for the Gift Card atom (Grace Commons atoms/gift-card.md)
-- Grounded on Final Critique 3, 2026-11-06 at 368ce1f — Alloy layer authored 2026-11-11.
-- Derived validator; the English spec is the single source of truth. On any
-- disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
--
-- PURPOSE
-- Verify, by bounded exhaustive search, the STATIC data model of Gift Card: what the gift
-- cards the database holds, every version of each (Execution Contract Database 5), must
-- satisfy in any one state, whatever calls wrote them. The page's single-state rules are
-- checked here; everything that happens across steps (a balance never raised, a card keeping
-- its code, currency and value, a refused spend taking nothing, no card removed, what a call
-- answers and that a query writes nothing) is the TLA+ model's, gift-card.tla.
--
-- RULES ENCODED (named by the page's own labels)
--   State 1        — every gift card carries card id, card code, currency, value and
--                    balance (Check 1.1).
--   Identity 5     — no two gift cards share a card id (Check 2.1).
--   Identity 6     — no two gift cards share a card code (Check 2.2).
--   Identity 7     — a card code is recorded as the seam supplied it, never normalized.
--   Identity 8     — two card codes compared codepoint for codepoint: a [Spend] lowers only
--                    the gift card carrying the very code it presented (Identity 2 and 4,
--                    Operation 7, are checked through it).
--   Identity 9     — a currency is recorded as the call carried it, never normalized.
--   Operation 1    — every gift card carries a currency among the accepted currencies;
--                    Identity 10 (two currencies compared codepoint for codepoint) is
--                    checked through it.
--   Operation 2    — every gift card's value is a positive amount.
--   Operation 3    — no gift card's value exceeds the card cap of its currency.
--   Operation 5    — the version [Issue] records carries its value as its balance.
--   Invariant 1.1  — every gift card carries a whole amount, zero or more, as its balance
--                    (Check 3.1); Operation 11 is checked through it.
--   Invariant 2.2  — no gift card's balance exceeds its value (Check 3.3).
--
-- NOT CHECKED HERE (across steps; the TLA+ model's)
--   Invariant 2.1 (nothing raises a balance), 3.1 to 3.3 (a card keeps its code, its currency
--   and its value), 4.1 (a refused spend takes nothing) and State 2 (no card removed): each
--   compares a record with a later state of itself. Operation 4 (EXACTLY ONE gift card per
--   [Issue]), 6, 8, 13 and 16 (what a call answers), 9 and 17 (a call that writes nothing),
--   10 and 12 (what a spend of a given amount does) show only in a step.
--
-- SCOPE
-- A state is what a sequence of admitted calls leaves. Each call is one atom, in the order
-- Execution Contract Order 1 gives every commit. [Issue] records a gift card, its first
-- version (Operation 4, 5); [Spend] records a later version over the version it found
-- (Operation 12), and the earlier versions stay (Execution Contract Database 5). The model
-- does not ask whether the version a [Spend] found was still the latest one, so it builds
-- every version a state can hold and some no state reaches; a check that holds over all of
-- them holds over the records. No trace, no `var`, no stepping. Card ids, card codes and
-- currencies are opaque tokens; amounts are whole numbers of the currency's minor unit.
--
-- NOT MODELED HERE
--   - [Check Balance] and [Read] (Operation 8, 9, 14 to 17): a query writes nothing, so it
--     adds no record; the TLA+ model reads what they answer.
--   - Storage failure and the failed read (Execution Contract Database 3, Read 1): a write
--     that did not commit leaves nothing. Which refusal answers (Execution Contract Refusal
--     1): the model needs only whether a call is admitted.
--   - A value or an amount that is not a whole number: the model's numbers are whole
--     (Execution Contract Input 1 holds an input to its type); Operation 2 and 10 are
--     modeled on the sign.
--   - The card code's random material (Capability requirement 3, 4, External check 1): an
--     auditor clears it from the deployment's random source, not from the records.
--   - The default card cap of 50000 minor units: the model takes any positive cap per
--     currency, the default among them. Which currency's minor unit an amount counts and
--     what a composing pattern spends in (Composition note 2) are the composing pattern's.
--   - A deployment whose accepted currencies or card caps change at a restart: the model
--     reads one set and one cap per currency (see the finding in the model's commit).
--
-- HOW TO READ RESULTS
-- Every "check A_*" must return "No counterexample found" (UNSAT) — the asserted guarantee holds.
-- Every "run Show*" must return at least one instance (SAT) — confirms non-vacuity.
-- A "check" returning a counterexample is a spec finding.

module gift_card

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- CardId: an opaque card id (Term card id), which the host supplies at the seam on [Issue].
sig CardId {}

-- Code: a string a call carries or the seam supplies as a card code, such as 7KQ9M2XV4RTP8HNC
-- or 7kq9m2xv4rtp8hnc, which the atom compares codepoint for codepoint, so two different
-- strings are two different atoms (Term card code, Identity 8).
sig Code {}

-- Currency: a string a call carries as its currency, such as USD, or usd (Term currency),
-- compared codepoint for codepoint (Identity 10).
sig Currency {}

-- Deployment: what the deployment supplies: the accepted currencies (Capability requirement
-- 5) and the card cap of each currency (Capability requirement 6; 50000 minor units where it
-- declares none).
one sig Deployment {
    accepted : set Currency,
    cap      : Currency -> one Int
}

-- Normalizer: what a normalizer that folds case or trims would rewrite a value to, where the
-- result differs from the value (7KQ9 for 7kq9, USD for usd). The page forbids it for both
-- (Identity 7, 9, Capability requirement 8, 9): the model's own actions never apply it. It
-- is here so the runs can show two codes one normalizer would merge, and so a twin can
-- apply it.
one sig Normalizer {
    foldCode : Code -> lone Code,
    foldCur  : Currency -> lone Currency
}

-- Call: one call of a writing action ([Issue], [Spend]). Calls happen in one order, the order
-- Execution Contract Order 1 gives every commit.
abstract sig Call {}

-- IssueCall: one [Issue] call, issue(currency, value). The seam supplies it a card id and a
-- card code (Capability requirement 1, 2); the action allocates neither.
sig IssueCall extends Call {
    curIn    : one Currency,  -- currency
    valueIn  : one Int,       -- value
    seamId   : one CardId,    -- the card id the seam supplies this call
    seamCode : one Code       -- the card code the seam supplies this call
}

-- SpendCall: one [Spend] call, spend(card_code, amount).
sig SpendCall extends Call {
    codeIn   : one Code,      -- card_code
    amountIn : one Int        -- amount
}

-- GiftCard: one version of a gift card record (Term records, Term version), as the call that
-- wrote it left it. Every field the page names may be absent, so a write that forgot one
-- would show; what the page promises (State 1) is checked, never built into the type. The
-- last two fields are the model's own: which call wrote this version, and which version a
-- [Spend] found.
sig GiftCard {
    cardId    : lone CardId,    -- card id (Identity 1)
    code      : lone Code,      -- card code (Identity 2)
    currency  : lone Currency,  -- currency
    value     : lone Int,       -- value
    balance   : lone Int,       -- balance
    writtenBy : one Call,
    found     : lone GiftCard
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The seam supplies each [Issue] a card id no gift card has carried (Capability requirement
-- 1, Execution Contract Logic confinement 3 and 16): two [Issue] calls never get one id.
fact SeamSuppliesFreshCardIds {
    all disj a, b : IssueCall | a.seamId != b.seamId
}

-- The seam supplies each [Issue] a card code no gift card has carried (Capability
-- requirement 2, Execution Contract Logic confinement 3 and 16): two [Issue] calls never get
-- one code.
fact SeamSuppliesFreshCodes {
    all disj a, b : IssueCall | a.seamCode != b.seamCode
}

-- The card cap the deployment declares for a currency is a positive amount (Capability
-- requirement 6, Execution Contract Input 2; Term card cap).
fact CardCapIsPositive {
    all x : Currency | x.(Deployment.cap) >= 1
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- first: the first version of the gift card this version belongs to, the one [Issue] wrote.
fun first[g : GiftCard] : set GiftCard {
    { v : g.*found | no v.found }
}

-- issuer: the [Issue] call that recorded the gift card this version belongs to. Two versions
-- with one issuer are one gift card; two issuers are two gift cards.
fun issuer[g : GiftCard] : set IssueCall {
    first[g].writtenBy & IssueCall
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- issueWrites: the gift card an admitted [Issue] records, and the guards it passes first: the
-- currency is among the accepted currencies, compared codepoint for codepoint (Operation 1,
-- Identity 10); the value is a positive amount (Operation 2) and does not exceed the card cap
-- of the currency (Operation 3). The gift card carries the card id and the card code the seam
-- supplied, the call's currency and value as the call carries them (Operation 4, Identity 7,
-- Identity 9), and the value as its balance (Operation 5).
pred issueWrites[i : IssueCall, g : GiftCard] {
    i.curIn in Deployment.accepted                       -- Operation 1, Identity 10
    i.valueIn >= 1                                       -- Operation 2
    i.valueIn <= i.curIn.(Deployment.cap)                -- Operation 3
    g.cardId   = i.seamId                                -- Operation 4, Capability requirement 1
    g.code     = i.seamCode                              -- Operation 4, Identity 7
    g.currency = i.curIn                                 -- Operation 4, Identity 9
    g.value    = i.valueIn                               -- Operation 4
    g.balance  = i.valueIn                               -- Operation 5
}

-- spendWrites: the version an admitted [Spend] records over the version it found: the call
-- names that gift card by its card code, compared codepoint for codepoint (Operation 7,
-- Identity 2, 4, 8); the amount is a positive amount (Operation 10) and does not exceed the
-- balance (Operation 11). The version carries the balance less the amount (Operation 12); a
-- call writes only the fields its own rules name, so the card id, the card code, the
-- currency and the value stay as found.
pred spendWrites[pre : GiftCard, s : SpendCall, g : GiftCard] {
    s.codeIn in pre.code                                 -- Operation 7, Identity 8
    s.amountIn >= 1                                      -- Operation 10
    s.amountIn <= pre.balance                            -- Operation 11
    g.cardId   = pre.cardId
    g.code     = pre.code
    g.currency = pre.currency
    g.value    = pre.value
    g.balance  = minus[pre.balance, s.amountIn]          -- Operation 12
}

-- written: the version is what its call's write left: an [Issue] writes a first version; a
-- [Spend] writes over a version an earlier call wrote (a call finds only what was committed
-- before it, Execution Contract Database 2).
pred written[g : GiftCard] {
    let c = g.writtenBy {
        (c in IssueCall and no g.found and issueWrites[c, g])
        or (c in SpendCall and some g.found
            and C/lt[g.found.writtenBy, c] and spendWrites[g.found, c, g])
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): it and every version it was
-- built from are what an admitted call wrote.
pred recorded[g : GiftCard] {
    all v : g.*found | written[v]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every version of every gift card carries its card id, card code, currency,
-- value and balance, however often it was spent (State 1, Check 1.1).
assert A_State_1 {
    all g : GiftCard | recorded[g] implies {
        some g.cardId
        some g.code
        some g.currency
        some g.value
        some g.balance
    }
}
check A_State_1 for 4 but 4 Int

-- A_Identity_5: no two gift cards share a card id: two gift cards two [Issue] calls recorded
-- never carry one id, the versions of each included (Identity 5, Check 2.1).
assert A_Identity_5 {
    all g1, g2 : GiftCard | (recorded[g1] and recorded[g2] and issuer[g1] != issuer[g2])
        implies no (g1.cardId & g2.cardId)
}
check A_Identity_5 for 4 but 4 Int

-- A_Identity_6: no two gift cards share a card code, so a code names one gift card to spend
-- (Identity 6, Check 2.2).
assert A_Identity_6 {
    all g1, g2 : GiftCard | (recorded[g1] and recorded[g2] and issuer[g1] != issuer[g2])
        implies no (g1.code & g2.code)
}
check A_Identity_6 for 4 but 4 Int

-- A_Identity_7: every gift card carries its card code as the seam supplied it to the [Issue]
-- that recorded it: 7KQ9M2XV4RTP8HNC stays as it is, never rewritten into another form
-- (Identity 7, Term card code: "stored as supplied").
assert A_Identity_7 {
    all g : GiftCard | recorded[g] implies g.code in issuer[g].seamCode
}
check A_Identity_7 for 4 but 4 Int

-- A_Identity_8: every version a [Spend] wrote is of the gift card carrying the very code the
-- spend presented, codepoint for codepoint: 7kq9m2xv4rtp8hnc spends nothing on the gift card
-- 7KQ9M2XV4RTP8HNC names (Identity 8, Operation 7, the rejection paths).
assert A_Identity_8 {
    all g : GiftCard | (recorded[g] and g.writtenBy in SpendCall)
        implies g.writtenBy.codeIn in g.found.code
}
check A_Identity_8 for 4 but 4 Int

-- A_Identity_9: every gift card carries its currency as the [Issue] that recorded it carried
-- it (Identity 9, Term currency: "stored as supplied").
assert A_Identity_9 {
    all g : GiftCard | recorded[g] implies g.currency in issuer[g].curIn
}
check A_Identity_9 for 4 but 4 Int

-- A_Operation_1: every gift card carries a currency among the accepted currencies, matched
-- codepoint for codepoint, so usd is no gift card's currency where only USD is accepted
-- (Operation 1, Identity 10). It holds against the accepted currencies the gift card was
-- issued under: see NOT MODELED HERE.
assert A_Operation_1 {
    all g : GiftCard | recorded[g] implies g.currency in Deployment.accepted
}
check A_Operation_1 for 4 but 4 Int

-- A_Operation_2: every gift card's value is a positive amount, one minor unit or more
-- (Operation 2, Term value).
assert A_Operation_2 {
    all g : GiftCard | recorded[g] implies (all v : g.value | v >= 1)
}
check A_Operation_2 for 4 but 4 Int

-- A_Operation_3: no gift card's value exceeds the card cap of its currency (Operation 3,
-- Term card cap); a value equal to the cap is admitted.
assert A_Operation_3 {
    all g : GiftCard | recorded[g] implies
        (all v : g.value, x : g.currency | v <= x.(Deployment.cap))
}
check A_Operation_3 for 4 but 4 Int

-- A_Operation_5: the version [Issue] records, a gift card's first, carries the value as its
-- balance: a gift card starts full (Operation 5).
assert A_Operation_5 {
    all g : GiftCard | (recorded[g] and no g.found) implies g.balance = g.value
}
check A_Operation_5 for 4 but 4 Int

-- A_Invariant_1_1: every version of every gift card carries a whole amount, zero or more, as
-- its balance: the balance never goes below zero (Invariant 1.1, Check 3.1, Operation 11).
assert A_Invariant_1_1 {
    all g : GiftCard | recorded[g] implies (all b : g.balance | b >= 0)
}
check A_Invariant_1_1 for 4 but 4 Int

-- A_Invariant_2_2: no version of a gift card carries a balance over the gift card's value
-- (Invariant 2.2, Check 3.3).
assert A_Invariant_2_2 {
    all g : GiftCard | recorded[g] implies
        (all b : g.balance, v : g.value | b <= v)
}
check A_Invariant_2_2 for 4 but 4 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowIssued: a gift card just issued, its balance its value, as issue("USD", 5000) answers
-- issued(g1, "7KQ9M2XV4RTP8HNC").
run ShowIssued {
    some g : GiftCard | recorded[g] and no g.found
} for 4 but 4 Int

-- ShowPartlySpent: a gift card spent in part, its balance between zero and its value, as
-- spend("7KQ9M2XV4RTP8HNC", 3218) answers 1782.
run ShowPartlySpent {
    some g : GiftCard | recorded[g] and g.writtenBy in SpendCall
        and g.balance > 0 and g.balance < g.value
} for 4 but 4 Int

-- ShowUsedUp: a gift card spent to zero and kept, its versions with it, as spend(…, 1782)
-- answers 0 and read(g1) still answers it.
run ShowUsedUp {
    some g : GiftCard | recorded[g] and g.writtenBy in SpendCall and g.balance = 0
} for 4 but 4 Int

-- ShowSpentTwice: a gift card spent twice, three versions of one card, as the bookshop's
-- paperback and notebook.
run ShowSpentTwice {
    some g : GiftCard | recorded[g] and some g.found.found
} for 4 but 4 Int

-- ShowTwoCurrencies: two gift cards in two currencies, as a shop's USD card beside a
-- bookshop's EUR card.
run ShowTwoCurrencies {
    some g1, g2 : GiftCard | recorded[g1] and recorded[g2] and g1.currency != g2.currency
} for 4 but 4 Int

-- ShowAtCap: a gift card issued for exactly the card cap of its currency, which Operation 3
-- admits.
run ShowAtCap {
    some g : GiftCard | recorded[g] and no g.found
        and g.value = g.currency.(Deployment.cap)
} for 4 but 4 Int

-- ShowCaseVariantCodes: two gift cards whose codes one normalizer would merge, each its own
-- gift card (Identity 7, 8).
run ShowCaseVariantCodes {
    some g1, g2 : GiftCard | recorded[g1] and recorded[g2] and issuer[g1] != issuer[g2]
        and g2.code = g1.code.(Normalizer.foldCode)
} for 4 but 4 Int
