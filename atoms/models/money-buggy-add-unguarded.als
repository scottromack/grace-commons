-- money-buggy-add-unguarded.als
-- DELIBERATELY WRONG twin of money.als (unit: `atoms/money.md formal layer`).
-- INJECTED DEFECT: [Add] never refuses over-cap: a sum past the number cap is answered
-- (Operation 4, Invariant 7.1).
-- BREAKS: A_Invariant_7_1.
-- Everything else is money.als as written; read its comments there.

module money_buggy_add_unguarded

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Currency: a string a call names as a currency, such as USD or usd, held as supplied and
-- compared codepoint for codepoint, so two different strings are two different atoms (Term
-- currency, Identity 2, 3).
sig Currency {}

-- NoCodepoints: the currency string of no codepoints, "", which no well-formed money carries
-- (Term well-formed money).
one sig NoCodepoints extends Currency {}

-- Normalizer: what a normalizer that folds case or trims would rewrite a currency to, where
-- the result differs from it (USD for usd). The page forbids it (Identity 3); the model's own
-- actions never apply it. It is here so a run can show two currencies one normalizer would
-- merge, and so a twin can apply it.
one sig Normalizer {
    fold : Currency -> lone Currency
}

-- Money: a value handed to the atom or answered by it: a currency and an amount, a whole
-- number of the currency's minor unit (Term money, amount). Either field may be absent, so a
-- value that lacks one, and an answer that forgot one, would show; what the page promises
-- (State 1) is checked, never built into the type.
sig Money {
    cur : lone Currency,
    amt : lone Int
}

-- Fractional: the moneys whose amount carries a fraction, as 10.5, which is no whole number
-- (Term well-formed money). The model's integers carry no fraction, so the fraction is marked.
sig Fractional in Money {}

-- Deployment: the number cap and the part cap the deployment declares (Capability
-- requirement 1, 2).
one sig Deployment {
    numberCap : one Int,
    partCap   : one Int
}

-- Refusal: the refusal codes on the actions' refuses lines (Term value sets: the action
-- rejection).
abstract sig Refusal {}
one sig InvalidMoney, MixedCurrency, OverCap, InvalidRate, InvalidRounding, TooManyParts,
        InvalidShares extends Refusal {}

-- Order: what a [Compare] answers (Term order).
abstract sig Order {}
one sig Less, Equal, Greater extends Order {}

-- RoundingName: a rounding a [Multiply] call may name: the four roundings (Term roundings),
-- and Nearest, a name outside them.
abstract sig RoundingName {}
one sig Down, Up, HalfUp, HalfEven, Nearest extends RoundingName {}

-- Call: one call of one action, its money, and its answer: a result, an order, parts, or a
-- refusal (the model's own record of the call; the atom keeps none).
abstract sig Call {
    money   : one Money,
    result  : lone Money,
    order   : lone Order,
    parts   : seq Money,
    refusal : lone Refusal
}

-- PairCall: a call of a pair action, naming an other money (Term pair action, other money).
abstract sig PairCall extends Call {
    other : one Money
}

-- AddCall, SubtractCall, CompareCall: add(money, other_money), subtract(money, other_money),
-- compare(money, other_money).
sig AddCall, SubtractCall, CompareCall extends PairCall {}

-- NegateCall: negate(money).
sig NegateCall extends Call {}

-- MultiplyCall: multiply(money, numerator, denominator, optional rounding). `roundedProduct`
-- is the rounded product the page's terms give these inputs (Term rounded product), computed
-- by money.tla; any whole number here.
sig MultiplyCall extends Call {
    numerator      : lone Int,
    denominator    : lone Int,
    rounding       : lone RoundingName,
    roundedProduct : one Int
}

-- FractionalNumerator: the [Multiply] calls whose numerator carries a fraction, as 1.5.
sig FractionalNumerator in MultiplyCall {}

-- SplitCall: split(money, shares), the shares a sequence of whole numbers.
sig SplitCall extends Call {
    shares : seq Int
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The deployment declares each cap above zero (Capability requirement 4, 5). The number cap
-- is at most 7 here so two capped amounts add up within the model's integers (a bound on the
-- search, not a rule; see NOT MODELED HERE).
fact DeclaredCaps {
    Deployment.numberCap > 0
    Deployment.partCap > 0
    Deployment.numberCap <= 7
}

-- A normalizer rewrites a currency only into another currency (the definition of the
-- Normalizer above).
fact NormalizerRewrites {
    no c : Currency | c -> c in Normalizer.fold
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The page's terms
-- ─────────────────────────────────────────────────────────────────────────────

-- withinCap: a whole number whose size is no more than the number cap (Term capped number).
pred withinCap[x : Int] {
    x <= Deployment.numberCap
    x >= minus[0, Deployment.numberCap]
}

-- cappedCount: a positive count no more than the number cap (Term capped count).
pred cappedCount[x : Int] {
    x >= 1
    x <= Deployment.numberCap
}

-- wellFormed: a value carrying a currency of one or more codepoints and a capped number as
-- amount, with no fraction (Term well-formed money).
pred wellFormed[m : Money] {
    some m.cur
    m.cur != NoCodepoints
    some m.amt
    m not in Fractional
    withinCap[m.amt]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The actions: their guards and their answers
-- ─────────────────────────────────────────────────────────────────────────────

-- refuses: the call answers the refusal r and nothing else.
pred refuses[c : Call, r : Refusal] {
    c.refusal = r
    no c.result
    no c.order
    no c.parts
}

-- answersMoney: the call answers one result, a money carrying the currency k and the whole
-- amount a (Operation 5, 7, 11, 16: "a result carrying ... as amount"; the currency is the
-- money's, Invariant 1.1, and a negation's, Term negation).
pred answersMoney[c : Call, k : Currency, a : Int] {
    no c.refusal
    no c.order
    no c.parts
    one c.result
    c.result.cur = k
    c.result.amt = a
    c.result not in Fractional
}

-- pairRefused: the first refusal a pair action's moneys meet, in the order of its refuses
-- line, answered (Operation 1, 2, 3; Execution Contract Refusal 1). Two currencies are
-- compared as atoms, codepoint for codepoint (Identity 2).
pred pairRefused[c : PairCall] {
    not wellFormed[c.money] => refuses[c, InvalidMoney]
    else not wellFormed[c.other] => refuses[c, InvalidMoney]
    else refuses[c, MixedCurrency]
}

-- pairOk: both moneys well-formed, in one currency.
pred pairOk[c : PairCall] {
    wellFormed[c.money]
    wellFormed[c.other]
    c.money.cur = c.other.cur
}

-- addAnswered: [Add] answers the money of the sum, or over-cap past the number cap
-- (Operation 4, 5).
pred addAnswered[c : AddCall] {
    not pairOk[c] => pairRefused[c]
    -- BUG: no over-cap refusal
    else answersMoney[c, c.money.cur, plus[c.money.amt, c.other.amt]]
}

-- subtractAnswered: [Subtract] answers the money of the difference, or over-cap past the cap
-- (Operation 6, 7).
pred subtractAnswered[c : SubtractCall] {
    not pairOk[c] => pairRefused[c]
    else not withinCap[minus[c.money.amt, c.other.amt]] => refuses[c, OverCap]
    else answersMoney[c, c.money.cur, minus[c.money.amt, c.other.amt]]
}

-- compareAnswered: [Compare] answers less, equal or greater (Operation 8, 9, 10).
pred compareAnswered[c : CompareCall] {
    not pairOk[c] => pairRefused[c]
    else {
        no c.refusal
        no c.result
        no c.parts
        c.other.amt > c.money.amt => c.order = Less
        c.other.amt = c.money.amt => c.order = Equal
        c.money.amt > c.other.amt => c.order = Greater
    }
}

-- negateAnswered: [Negate] answers the money's negation: its currency and the negation of its
-- amount (Operation 1, 11, Term negation).
pred negateAnswered[c : NegateCall] {
    not wellFormed[c.money] => refuses[c, InvalidMoney]
    else answersMoney[c, c.money.cur, minus[0, c.money.amt]]
}

-- rateOk: the numerator is a capped number and the denominator a capped count (Operation 12,
-- 13).
pred rateOk[c : MultiplyCall] {
    some c.numerator
    c not in FractionalNumerator
    withinCap[c.numerator]
    some c.denominator
    cappedCount[c.denominator]
}

-- multiplyAnswered: [Multiply] refuses, in the order of its refuses line, a money no
-- well-formed money, a rate no good rate, no rounding or one outside the four, and a rounded
-- size past the cap; else it answers the rounded product (Operation 1, 12 to 16).
pred multiplyAnswered[c : MultiplyCall] {
    not wellFormed[c.money] => refuses[c, InvalidMoney]
    else not rateOk[c] => refuses[c, InvalidRate]
    else (no c.rounding or c.rounding = Nearest) => refuses[c, InvalidRounding]
    else not withinCap[c.roundedProduct] => refuses[c, OverCap]
    else answersMoney[c, c.money.cur, c.roundedProduct]
}

-- splitAnswered: [Split] refuses, in the order of its refuses line, a money no well-formed
-- money, more shares than the part cap, and no share or a share no capped count; else it
-- answers one part per share, each a money in the money's currency (Invariant 1.2) carrying a
-- whole amount, the stepped or base share money.tla computes (Operation 1, 17 to 22).
pred splitAnswered[c : SplitCall] {
    not wellFormed[c.money] => refuses[c, InvalidMoney]
    else #c.shares > Deployment.partCap => refuses[c, TooManyParts]
    else (c.shares.isEmpty or some s : c.shares.elems | not cappedCount[s])
        => refuses[c, InvalidShares]
    else {
        no c.refusal
        no c.result
        no c.order
        c.parts.inds = c.shares.inds
        all p : c.parts.elems | p.cur = c.money.cur and one p.amt and p not in Fractional
    }
}

-- answered: the call's answer is the one its action gives its inputs.
pred answered[c : Call] {
    c in AddCall      => addAnswered[c]
    c in SubtractCall => subtractAnswered[c]
    c in CompareCall  => compareAnswered[c]
    c in NegateCall   => negateAnswered[c]
    c in MultiplyCall => multiplyAnswered[c]
    c in SplitCall    => splitAnswered[c]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any call the page's actions can answer that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every money an answer carries, a result or a part, carries a currency and an
-- amount (State 1).
assert A_State_1 {
    all c : Call | answered[c] implies {
        all r : c.result | some r.cur and some r.amt
        all p : c.parts.elems | some p.cur and some p.amt
    }
}
check A_State_1 for 4 but 5 Int, 3 seq

-- A_Identity_2: a pair action naming two well-formed moneys whose currencies one normalizer
-- would merge, as usd and USD, answers mixed-currency: two currencies are compared codepoint
-- for codepoint (Identity 2; the rejection paths' add(money("USD", 100), money("usd", 100))).
assert A_Identity_2 {
    all c : PairCall | (answered[c] and wellFormed[c.money] and wellFormed[c.other]
                        and c.other.cur in c.money.cur.(Normalizer.fold))
        implies c.refusal = MixedCurrency
}
check A_Identity_2 for 4 but 5 Int, 3 seq

-- A_Invariant_1_1: every result an [Add], a [Subtract], a [Negate] or a [Multiply] answers
-- carries the money's currency, as supplied, never another and never a normalized one
-- (Invariant 1.1, Identity 3, Check 1.1).
assert A_Invariant_1_1 {
    all c : Call | answered[c] implies (all r : c.result | r.cur = c.money.cur)
}
check A_Invariant_1_1 for 4 but 5 Int, 3 seq

-- A_Invariant_1_2: every part a [Split] answers carries the money's currency, as supplied
-- (Invariant 1.2, Identity 3, Check 1.2).
assert A_Invariant_1_2 {
    all c : SplitCall | answered[c] implies (all p : c.parts.elems | p.cur = c.money.cur)
}
check A_Invariant_1_2 for 4 but 5 Int, 3 seq

-- A_Invariant_7_1: no result's size passes the number cap: a sum, a difference, a negation or
-- a rounded product past it is refused, never answered (Invariant 7.1, Check 7.1).
assert A_Invariant_7_1 {
    all c : Call | answered[c] implies (all r : c.result | withinCap[r.amt])
}
check A_Invariant_7_1 for 4 but 5 Int, 3 seq

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowAdd: an [Add] that answers the money of the sum, as the basket's $19.99 and $2.50.
run ShowAdd {
    some c : AddCall | answered[c] and some c.result and c.money.amt > 0 and c.other.amt > 0
} for 4 but 5 Int, 3 seq

-- ShowSubtractBelowZero: a [Subtract] whose difference is below zero, as subtract(USD 250,
-- USD 1999).
run ShowSubtractBelowZero {
    some c : SubtractCall | answered[c] and some c.result and c.result.amt < 0
} for 4 but 5 Int, 3 seq

-- ShowCompareLess: a refund compared with a charge answers less.
run ShowCompareLess {
    some c : CompareCall | answered[c] and c.order = Less and c.money.amt < 0
} for 4 but 5 Int, 3 seq

-- ShowNegate: a charge negated into its refund.
run ShowNegate {
    some c : NegateCall | answered[c] and some c.result and c.money.amt > 0
} for 4 but 5 Int, 3 seq

-- ShowMultiply: a [Multiply] that answers a rounded product.
run ShowMultiply {
    some c : MultiplyCall | answered[c] and some c.result
} for 4 but 5 Int, 3 seq

-- ShowSplit: a [Split] into two parts or more, each in the money's currency.
run ShowSplit {
    some c : SplitCall | answered[c] and #c.parts >= 2
} for 4 but 5 Int, 3 seq

-- ShowMixedCaseVariant: an [Add] of USD and usd refused as mixed-currency (Identity 2).
run ShowMixedCaseVariant {
    some c : AddCall | answered[c] and wellFormed[c.money] and wellFormed[c.other]
        and c.other.cur in c.money.cur.(Normalizer.fold)
} for 4 but 5 Int, 3 seq

-- ShowOverCap: an [Add] whose sum passes the number cap refused as over-cap.
run ShowOverCap {
    some c : AddCall | answered[c] and c.refusal = OverCap
} for 4 but 5 Int, 3 seq

-- ShowFractionRefused: a money whose amount carries a fraction refused as invalid-money.
run ShowFractionRefused {
    some c : Call | answered[c] and c.money in Fractional and c.refusal = InvalidMoney
} for 4 but 5 Int, 3 seq

-- ShowNoCodepointsRefused: a money whose currency has no codepoints refused as invalid-money.
run ShowNoCodepointsRefused {
    some c : Call | answered[c] and c.money.cur = NoCodepoints and c.refusal = InvalidMoney
} for 4 but 5 Int, 3 seq

-- ShowInvalidRate: a [Multiply] whose numerator carries a fraction refused as invalid-rate.
run ShowInvalidRate {
    some c : FractionalNumerator | answered[c] and c.refusal = InvalidRate
} for 4 but 5 Int, 3 seq

-- ShowInvalidRounding: a [Multiply] naming no rounding refused as invalid-rounding.
run ShowInvalidRounding {
    some c : MultiplyCall | answered[c] and no c.rounding and c.refusal = InvalidRounding
} for 4 but 5 Int, 3 seq

-- ShowTooManyParts: a [Split] naming more shares than the part cap refused.
run ShowTooManyParts {
    some c : SplitCall | answered[c] and c.refusal = TooManyParts
} for 4 but 5 Int, 3 seq

-- ShowInvalidShares: a [Split] naming a share of zero refused as invalid-shares.
run ShowInvalidShares {
    some c : SplitCall | answered[c] and 0 in c.shares.elems and c.refusal = InvalidShares
} for 4 but 5 Int, 3 seq
