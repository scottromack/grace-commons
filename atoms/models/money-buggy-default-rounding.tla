---- MODULE money-buggy-default-rounding ----
\* DELIBERATELY WRONG twin of money.tla (unit: `atoms/money.md formal layer`).
\*
\* INJECTED DEFECT: [Multiply] rounds down where the call names no rounding,
\* or one outside the four, in place of refusing invalid-rounding: the atom
\* chooses a rounding (Operation 14, Non-goal 5; the Decisions entry's
\* rejected default rounding).
\*
\* BREAKS: Op14_RoundingRefused.
\* Everything else is money.tla as written, its PROOFS section left out (TLAPS
\* proves the correct model only); read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    Currencies,  \* the currencies a call may name, "" (no codepoints) among them
    NumberCap,   \* the number cap the deployment declares (Capability requirement 1)
    PartCap,     \* the part cap the deployment declares (Capability requirement 2)
    Held         \* the values a composing pattern's records may take

\* ---------------------------------------------------------------------------
\* The page's terms
\* ---------------------------------------------------------------------------

\* Size: a whole number without the sign; the size of -250 is 250 (Term size).
Size(x) == IF x < 0 THEN -x ELSE x

\* Roundings: the four roundings (Term roundings).
Roundings == {"down", "up", "half-up", "half-even"}

\* NoMoney: the money field of an answer that carries no money, and of a call
\* that names no other money.
NoMoney == [cur |-> "n/a", amt |-> 0, whole |-> TRUE]

\* NegMoney: a money's negation: the money's currency and the negation of its
\* amount (Term negation).
NegMoney(m) == [cur |-> m.cur, amt |-> -m.amt, whole |-> m.whole]

\* WellFormed: a value carrying a currency of one or more codepoints and a
\* capped number as amount; an amount with a fraction is no whole number (Term
\* well-formed money). A money is a record: its currency, its amount, and
\* whether the amount is whole (FALSE: the amount and a half, as 10.5).
WellFormed(m) == m.cur # "" /\ m.whole /\ Size(m.amt) <= NumberCap

\* CappedNumber: a whole number whose size is no more than the number cap.
CappedNumber(x, whole) == whole /\ x \in Int /\ Size(x) <= NumberCap

\* CappedCount: a positive count (a whole number, one or more) no more than
\* the number cap.
CappedCount(x) == x \in Int /\ x >= 1 /\ x <= NumberCap

\* PS, Sum: the values f[1] to f[n] added up, built as a running total (the
\* share total, the total of the parts, the base sizes added up, the short
\* count). PS(f, n)[k] is the total of the first k.
PS(f, n) == LET ps[k \in 0..n] == IF k = 0 THEN 0 ELSE ps[k - 1] + f[k] IN ps
Sum(f, n) == PS(f, n)[n]

\* Product, Quotient, Remainder: the money's amount times the numerator, kept
\* exact; how many whole times the denominator goes into the product's size;
\* and what that leaves over (Term product, quotient, remainder).
Product(a, num) == a * num
Quotient(p, d) == Size(p) \div d
Remainder(p, d) == Size(p) - Quotient(p, d) * d

\* RoundedSize: the size the named rounding answers from the quotient and the
\* remainder, never reading a sign (Term down, up, half-up, half-even).
RoundedSize(p, d, r) ==
    LET q == Quotient(p, d)
        rm == Remainder(p, d)
    IN CASE r = "down"      -> q
         [] r = "up"        -> IF rm > 0 THEN q + 1 ELSE q
         [] r = "half-up"   -> IF 2 * rm >= d THEN q + 1 ELSE q
         [] r = "half-even" -> IF 2 * rm > d \/ (2 * rm = d /\ q % 2 = 1) THEN q + 1 ELSE q
         [] OTHER           -> q

\* RoundedProduct: the rounded size, negated where the product is below zero
\* (Term rounded product).
RoundedProduct(p, d, r) == IF p < 0 THEN -RoundedSize(p, d, r) ELSE RoundedSize(p, d, r)

\* The split's terms, for a money of size s split by shares sh[1..n]:
\* ShareTotal, the shares added up; BaseSize, the part's share product (s times
\* its share) divided by the share total, rounded down; PartRemainder, what
\* that division leaves over; ShortInd, 1 for a short part (its part remainder
\* above zero) and 0 for any other; ShortCount, the short parts counted;
\* Leftover, the size less the base sizes added up; IsFirst, a short part
\* within the first Leftover short parts from the front (Term share total,
\* share product, base size, part remainder, short part, short count,
\* leftover, first parts).
ShareTotal(sh, n) == Sum(sh, n)
BaseSize(s, sh, n, i) == (s * sh[i]) \div ShareTotal(sh, n)
PartRemainder(s, sh, n, i) == s * sh[i] - BaseSize(s, sh, n, i) * ShareTotal(sh, n)
ShortInd(s, sh, n) == [i \in 1..n |-> IF PartRemainder(s, sh, n, i) > 0 THEN 1 ELSE 0]
ShortCount(s, sh, n) == Sum(ShortInd(s, sh, n), n)
BaseSizes(s, sh, n) == [i \in 1..n |-> BaseSize(s, sh, n, i)]
Leftover(s, sh, n) == s - Sum(BaseSizes(s, sh, n), n)
IsFirst(s, sh, n, i) ==
    /\ PartRemainder(s, sh, n, i) > 0
    /\ Sum(ShortInd(s, sh, n), i) <= Leftover(s, sh, n)

\* Step: one minor unit in the direction of the amount; a money of zero has
\* none (Term step). BaseShare: the base size, negated where the amount is
\* below zero (Term base share).
Step(a) == IF a > 0 THEN 1 ELSE IF a < 0 THEN -1 ELSE 0
BaseShare(a, sh, n, i) ==
    IF a < 0 THEN -BaseSize(Size(a), sh, n, i) ELSE BaseSize(Size(a), sh, n, i)

\* SplitParts: one part per share, in the order of the shares: a first part
\* carries its stepped share, the base share plus the step (Operation 21), and
\* every other part its base share (Operation 22).
SplitParts(a, sh, n) ==
    [i \in 1..n |-> IF IsFirst(Size(a), sh, n, i)
                    THEN BaseShare(a, sh, n, i) + Step(a)
                    ELSE BaseShare(a, sh, n, i)]

\* ---------------------------------------------------------------------------
\* The actions: what each answers from the call's inputs alone
\* ---------------------------------------------------------------------------

\* Ans: an answer: a refusal code or "ok", the result (a money), the order
\* ([Compare]) and the parts ([Split]); fields an answer does not use hold
\* NoMoney, "n/a" and no parts.
Ans(code, res, ord, parts) == [ans |-> code, res |-> res, ord |-> ord, parts |-> parts]
Refuse(code) == Ans(code, NoMoney, "n/a", <<>>)
Result(cur, amt) == Ans("ok", [cur |-> cur, amt |-> amt, whole |-> TRUE], "n/a", <<>>)

\* PairRefusal: the first refusal a pair action's two moneys meet, in the
\* order of its refuses line (Operation 1, 2, 3; Execution Contract Refusal
\* 1); two currencies are compared codepoint for codepoint (Identity 2).
PairRefusal(m, o) ==
    IF ~WellFormed(m) THEN "invalid-money"
    ELSE IF ~WellFormed(o) THEN "invalid-money"
    ELSE IF m.cur # o.cur THEN "mixed-currency"
    ELSE "none"

\* AddAnswer: [Add] answers the money of the sum, or over-cap where the sum's
\* size passes the number cap (Operation 4, 5); the result carries the
\* money's currency (Invariant 1.1, the Alloy model's to check).
AddAnswer(m, o) ==
    IF PairRefusal(m, o) # "none" THEN Refuse(PairRefusal(m, o))
    ELSE IF Size(m.amt + o.amt) > NumberCap THEN Refuse("over-cap")
    ELSE Result(m.cur, m.amt + o.amt)

\* SubtractAnswer: [Subtract] answers the money of the difference, or
\* over-cap past the number cap (Operation 6, 7).
SubtractAnswer(m, o) ==
    IF PairRefusal(m, o) # "none" THEN Refuse(PairRefusal(m, o))
    ELSE IF Size(m.amt - o.amt) > NumberCap THEN Refuse("over-cap")
    ELSE Result(m.cur, m.amt - o.amt)

\* CompareAnswer: [Compare] answers less, equal or greater: how the money's
\* amount stands against the other money's (Operation 8, 9, 10).
CompareAnswer(m, o) ==
    IF PairRefusal(m, o) # "none" THEN Refuse(PairRefusal(m, o))
    ELSE Ans("ok", NoMoney,
             IF o.amt > m.amt THEN "less" ELSE IF m.amt = o.amt THEN "equal" ELSE "greater",
             <<>>)

\* NegateAnswer: [Negate] answers the money's negation (Operation 1, 11).
NegateAnswer(m) ==
    IF ~WellFormed(m) THEN Refuse("invalid-money")
    ELSE Result(m.cur, -m.amt)

\* MultiplyAnswer: [Multiply] refuses, in the order of its refuses line, a
\* money no well-formed money, a numerator no capped number or a denominator
\* no capped count, a rounding outside the four or none, and a rounded size
\* past the cap; else it answers the rounded product (Operation 1, 12 to 16).
MultiplyAnswer(m, num, nw, den, rnd) ==
    IF ~WellFormed(m) THEN Refuse("invalid-money")
    ELSE IF ~CappedNumber(num, nw) \/ ~CappedCount(den) THEN Refuse("invalid-rate")
    \* BUG: no invalid-rounding refusal; RoundedSize's OTHER arm rounds down
    ELSE IF RoundedSize(Product(m.amt, num), den, rnd) > NumberCap THEN Refuse("over-cap")
    ELSE Result(m.cur, RoundedProduct(Product(m.amt, num), den, rnd))

\* SplitAnswer: [Split] refuses, in the order of its refuses line, a money no
\* well-formed money, more shares than the part cap, and no share or a share
\* no capped count; else it answers the parts (Operation 1, 17 to 22).
SplitAnswer(m, sh, n) ==
    IF ~WellFormed(m) THEN Refuse("invalid-money")
    ELSE IF n > PartCap THEN Refuse("too-many-parts")
    ELSE IF n = 0 \/ \E i \in 1..n : ~CappedCount(sh[i]) THEN Refuse("invalid-shares")
    ELSE Ans("ok", NoMoney, "n/a", SplitParts(m.amt, sh, n))

\* AnswerOf: the answer the action a call names gives its inputs.
AnswerOf(c) ==
    CASE c.op = "add"      -> AddAnswer(c.m, c.o)
      [] c.op = "subtract" -> SubtractAnswer(c.m, c.o)
      [] c.op = "compare"  -> CompareAnswer(c.m, c.o)
      [] c.op = "negate"   -> NegateAnswer(c.m)
      [] c.op = "multiply" -> MultiplyAnswer(c.m, c.num, c.nw, c.den, c.rnd)
      [] c.op = "split"    -> SplitAnswer(c.m, c.sh, c.n)

\* ---------------------------------------------------------------------------
\* The calls a caller may make (the bounds)
\* ---------------------------------------------------------------------------

\* Amounts, Moneys: every whole amount from one past the cap below zero to one
\* past it above, in each currency, and in each currency an amount carrying a
\* fraction (1 and a half).
Amounts == -(NumberCap + 1)..(NumberCap + 1)
Moneys == [cur : Currencies, amt : Amounts, whole : {TRUE}]
          \cup [cur : Currencies, amt : {1}, whole : {FALSE}]

\* Call: a call's inputs: the action; the money; the other money; the
\* numerator (and whether it is whole), the denominator and the rounding
\* ("none" for a call that names none); the shares and how many there are.
Call(op, m, o, num, nw, den, rnd, sh, n) ==
    [op |-> op, m |-> m, o |-> o, num |-> num, nw |-> nw, den |-> den, rnd |-> rnd,
     sh |-> sh, n |-> n]

\* Denominators, CallRoundings: the denominators a [Multiply] call may name,
\* from one below zero to one past the cap; the roundings it may name: the
\* four, one outside them, and none.
Denominators == -1..(NumberCap + 1)
CallRoundings == Roundings \cup {"nearest", "none"}

\* InputOf: the inputs of an answered call.
InputOf(r) == Call(r.op, r.m, r.o, r.num, r.nw, r.den, r.rnd, r.sh, r.n)

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    held,   \* the composing pattern's records, which the atom neither writes nor reads
    first,  \* the first call made, and what it answered
    last    \* the last step: a call and what it answered, or the pattern's write

\* vars: every variable.
vars == <<held, first, last>>

\* NoCall: the record of no call yet, and the shape of every such record: the
\* step's kind ("call", "repeat", "negated", "roundtrip" for a call of the
\* atom; "pattern" for the composing pattern's write), the call's inputs and
\* its answer.
NoCall == [kind |-> "none", op |-> "none", m |-> NoMoney, o |-> NoMoney, num |-> 0,
           nw |-> TRUE, den |-> 0, rnd |-> "n/a", sh |-> <<>>, n |-> 0,
           ans |-> "none", res |-> NoMoney, ord |-> "n/a", parts |-> <<>>]

\* Answered: the record of a call of the given kind and what it answered.
Answered(kind, c, a) ==
    [kind |-> kind, op |-> c.op, m |-> c.m, o |-> c.o, num |-> c.num, nw |-> c.nw,
     den |-> c.den, rnd |-> c.rnd, sh |-> c.sh, n |-> c.n,
     ans |-> a.ans, res |-> a.res, ord |-> a.ord, parts |-> a.parts]

\* AtomStep: the kinds of step that are a call of the atom's.
AtomStep == {"call", "repeat", "negated", "roundtrip"}

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ held \in Held
    /\ first.kind \in {"none", "call"}
    /\ last.kind \in AtomStep \cup {"none", "pattern"}
    /\ last.ans \in {"none", "ok", "invalid-money", "mixed-currency", "over-cap",
                     "invalid-rate", "invalid-rounding", "too-many-parts", "invalid-shares"}
    /\ last.res.amt \in Int
    /\ last.ord \in {"n/a", "less", "equal", "greater"}

\* Init: no call yet; the composing pattern's records hold their first value.
Init ==
    /\ held = CHOOSE h \in Held : \A g \in Held : h <= g
    /\ first = NoCall
    /\ last = NoCall

\* Do: a call of the atom's, of the given kind: the step records the call and
\* the answer its action gives the call's inputs.
Do(kind, c) == last' = Answered(kind, c, AnswerOf(c))

\* FirstCall: the first call, any call the bounds admit; the composing
\* pattern's records stand.
FirstCall(c) ==
    /\ Do("call", c)
    /\ first' = last'
    /\ UNCHANGED held

\* PatternWrites: the composing pattern writes its own records (h); no call
\* of the atom's is made.
PatternWrites(h) ==
    /\ held' = h
    /\ last' = [NoCall EXCEPT !.kind = "pattern"]
    /\ UNCHANGED first

\* Repeat: the first call made again, its inputs the same, whatever the
\* composing pattern's records now hold (Operation 24).
Repeat ==
    /\ Do("repeat", InputOf(first))
    /\ UNCHANGED <<held, first>>

\* Negated: the first call, a [Multiply] or a [Split], made with the money's
\* negation, every other input the same (Term negated call).
Negated ==
    /\ first.op \in {"multiply", "split"}
    /\ Do("negated", [InputOf(first) EXCEPT !.m = NegMoney(first.m)])
    /\ UNCHANGED <<held, first>>

\* RoundTrip: after an [Add] that answered a result, a [Subtract] of the same
\* other money from that result (Term round trip).
RoundTrip ==
    /\ first.op = "add"
    /\ first.ans = "ok"
    /\ Do("roundtrip", Call("subtract", first.res, first.o, 0, TRUE, 0, "n/a", <<>>, 0))
    /\ UNCHANGED <<held, first>>

\* AnyFirstCall: any call the bounds admit, of every action, made first:
\* a pair action on any two moneys; [Negate] on any money; [Multiply] with any
\* numerator, denominator and rounding, and with a numerator of 1.5; [Split]
\* by every list of up to one share past the part cap.
AnyFirstCall ==
    \/ \E op \in {"add", "subtract", "compare"}, m \in Moneys, o \in Moneys :
          FirstCall(Call(op, m, o, 0, TRUE, 0, "n/a", <<>>, 0))
    \/ \E m \in Moneys : FirstCall(Call("negate", m, NoMoney, 0, TRUE, 0, "n/a", <<>>, 0))
    \/ \E m \in Moneys, num \in Amounts, den \in Denominators, rnd \in CallRoundings :
          FirstCall(Call("multiply", m, NoMoney, num, TRUE, den, rnd, <<>>, 0))
    \/ \E m \in Moneys, den \in 1..2, rnd \in {"down", "half-even"} :
          FirstCall(Call("multiply", m, NoMoney, 1, FALSE, den, rnd, <<>>, 0))
    \/ \E m \in Moneys, k \in 0..(PartCap + 1) :
          \E sh \in [1..k -> 0..(NumberCap + 1)] :
             FirstCall(Call("split", m, NoMoney, 0, TRUE, 0, "n/a", sh, k))

\* Next: the first call, then any of the follow-ups, in any order.
Next ==
    \/ first = NoCall /\ AnyFirstCall
    \/ first # NoCall /\ \E h \in Held \ {held} : PatternWrites(h)
    \/ first # NoCall /\ Repeat
    \/ first # NoCall /\ Negated
    \/ first # NoCall /\ RoundTrip

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface). Each reads the last call the atom
\* answered, whatever its kind, and spells the page's rule in its own words
\* where it can, so a defect in an action is not hidden by sharing its text.
\* ---------------------------------------------------------------------------

\* Atom: the last step was a call of the atom's.
Atom == last.kind \in AtomStep

\* WF: a well-formed money, spelled out: a currency of one or more codepoints,
\* a whole amount, within the number cap either way (Term well-formed money).
WF(m) == m.cur # "" /\ m.whole /\ -NumberCap <= m.amt /\ m.amt <= NumberCap

\* PairOk: the last call named two well-formed moneys in one currency.
PairOk == WF(last.m) /\ WF(last.o) /\ last.m.cur = last.o.cur

\* Op1_InvalidMoney: a call whose money is no well-formed money (a currency
\* of no codepoints, an amount with a fraction, or past the cap) answers
\* invalid-money, the refusal listed first on every refuses line (Operation 1).
Op1_InvalidMoney ==
    (Atom /\ ~WF(last.m)) => last.ans = "invalid-money"

\* Op2_OtherInvalidMoney: a pair action whose money is well-formed and whose
\* other money is not answers invalid-money (Operation 2).
Op2_OtherInvalidMoney ==
    (Atom /\ last.op \in {"add", "subtract", "compare"} /\ WF(last.m) /\ ~WF(last.o))
        => last.ans = "invalid-money"

\* Op3_MixedCurrency: a pair action naming two well-formed moneys whose
\* currencies differ, codepoint for codepoint, answers mixed-currency: USD and
\* usd are two currencies (Operation 3, Identity 2).
Op3_MixedCurrency ==
    (Atom /\ last.op \in {"add", "subtract", "compare"} /\ WF(last.m) /\ WF(last.o)
          /\ last.m.cur # last.o.cur)
        => last.ans = "mixed-currency"

\* Op4_AddOverCap: an [Add] in one currency whose sum's size passes the number
\* cap answers over-cap (Operation 4).
Op4_AddOverCap ==
    (Atom /\ last.op = "add" /\ PairOk
          /\ (last.m.amt + last.o.amt > NumberCap \/ last.m.amt + last.o.amt < -NumberCap))
        => last.ans = "over-cap"

\* Op5_AddAnswersSum: an [Add] in one currency whose sum is within the cap
\* answers a result carrying the sum as amount (Operation 5).
Op5_AddAnswersSum ==
    (Atom /\ last.op = "add" /\ PairOk
          /\ -NumberCap <= last.m.amt + last.o.amt /\ last.m.amt + last.o.amt <= NumberCap)
        => (last.ans = "ok" /\ last.res.amt = last.m.amt + last.o.amt)

\* Op6_SubtractOverCap: a [Subtract] in one currency whose difference's size
\* passes the cap answers over-cap (Operation 6).
Op6_SubtractOverCap ==
    (Atom /\ last.op = "subtract" /\ PairOk
          /\ (last.m.amt - last.o.amt > NumberCap \/ last.m.amt - last.o.amt < -NumberCap))
        => last.ans = "over-cap"

\* Op7_SubtractAnswersDifference: a [Subtract] in one currency whose
\* difference is within the cap answers a result carrying the difference,
\* which may be below zero (Operation 7).
Op7_SubtractAnswersDifference ==
    (Atom /\ last.op = "subtract" /\ PairOk
          /\ -NumberCap <= last.m.amt - last.o.amt /\ last.m.amt - last.o.amt <= NumberCap)
        => (last.ans = "ok" /\ last.res.amt = last.m.amt - last.o.amt)

\* Op8_CompareLess: a [Compare] in one currency where the other money's amount
\* exceeds the money's answers less; a refund stands below a charge
\* (Operation 8).
Op8_CompareLess ==
    (Atom /\ last.op = "compare" /\ PairOk /\ last.o.amt > last.m.amt)
        => (last.ans = "ok" /\ last.ord = "less")

\* Op9_CompareEqual: a [Compare] in one currency of two equal amounts answers
\* equal (Operation 9).
Op9_CompareEqual ==
    (Atom /\ last.op = "compare" /\ PairOk /\ last.o.amt = last.m.amt)
        => (last.ans = "ok" /\ last.ord = "equal")

\* Op10_CompareGreater: a [Compare] in one currency where the money's amount
\* exceeds the other's answers greater (Operation 10).
Op10_CompareGreater ==
    (Atom /\ last.op = "compare" /\ PairOk /\ last.m.amt > last.o.amt)
        => (last.ans = "ok" /\ last.ord = "greater")

\* Op11_NegateAnswersNegation: a [Negate] of a well-formed money answers a
\* result carrying the negation of its amount; zero answers zero (Operation 11).
Op11_NegateAnswersNegation ==
    (Atom /\ last.op = "negate" /\ WF(last.m))
        => (last.ans = "ok" /\ last.res.amt = 0 - last.m.amt)

\* MulMoneyOk: a [Multiply] whose money is well-formed, so the refusal its
\* rate meets comes next on its refuses line.
MulMoneyOk == Atom /\ last.op = "multiply" /\ WF(last.m)

\* Op12_NumeratorRefused: a [Multiply] whose numerator is no capped number (a
\* fraction, as 1.5, or past the cap) answers invalid-rate (Operation 12).
Op12_NumeratorRefused ==
    (MulMoneyOk /\ (~last.nw \/ last.num > NumberCap \/ last.num < -NumberCap))
        => last.ans = "invalid-rate"

\* Op13_DenominatorRefused: a [Multiply] whose denominator is no capped count
\* (zero, below zero, or past the cap) answers invalid-rate (Operation 13).
Op13_DenominatorRefused ==
    (MulMoneyOk /\ (last.den < 1 \/ last.den > NumberCap))
        => last.ans = "invalid-rate"

\* RateOk: a [Multiply] whose money and rate are both good.
RateOk ==
    MulMoneyOk /\ last.nw /\ -NumberCap <= last.num /\ last.num <= NumberCap
               /\ 1 <= last.den /\ last.den <= NumberCap

\* Op14_RoundingRefused: a [Multiply] with a good rate that names no rounding,
\* or one outside down, up, half-up and half-even, answers invalid-rounding:
\* the atom supplies none (Operation 14, Non-goal 5).
Op14_RoundingRefused ==
    (RateOk /\ last.rnd \notin {"down", "up", "half-up", "half-even"})
        => last.ans = "invalid-rounding"

\* Op15_MultiplyOverCap: a [Multiply] whose inputs are all good and whose
\* rounded size passes the number cap answers over-cap (Operation 15).
Op15_MultiplyOverCap ==
    (RateOk /\ last.rnd \in Roundings
            /\ RoundedSize(last.m.amt * last.num, last.den, last.rnd) > NumberCap)
        => last.ans = "over-cap"

\* Op16_MultiplyAnswersRoundedProduct: a [Multiply] that answered carries the
\* rounded product, spelled here by what each rounding means rather than by
\* the quotient and remainder the action uses. With p the exact product, S its
\* size, d the denominator and R the size of the result, R*d is R scaled by d,
\* so R*d - S is d times R's distance from the exact size S/d: down is the
\* whole number at or below S/d, up the one at or above, half-up and half-even
\* the nearest, an exact half going up (away from zero) or to the even one;
\* and the result's sign is the product's (Operation 16, Term roundings,
\* Term rounded product).
Op16_MultiplyAnswersRoundedProduct ==
    (Atom /\ last.op = "multiply" /\ last.ans = "ok")
        => LET p == last.m.amt * last.num
               S == IF p < 0 THEN -p ELSE p
               R == IF last.res.amt < 0 THEN -last.res.amt ELSE last.res.amt
               d == last.den
               twice == 2 * (R * d - S)
           IN /\ (p < 0 => last.res.amt <= 0)
              /\ (p >= 0 => last.res.amt >= 0)
              /\ (last.rnd = "down" => (R * d <= S /\ S < R * d + d))
              /\ (last.rnd = "up" => (R * d >= S /\ S > R * d - d))
              /\ (last.rnd = "half-up" => (-d < twice /\ twice <= d))
              /\ (last.rnd = "half-even" => (-d <= twice /\ twice <= d
                                             /\ ((twice = d \/ twice = -d) => R % 2 = 0)))

\* SplitMoneyOk: a [Split] whose money is well-formed.
SplitMoneyOk == Atom /\ last.op = "split" /\ WF(last.m)

\* Op17_TooManyParts: a [Split] naming more shares than the part cap answers
\* too-many-parts (Operation 17).
Op17_TooManyParts ==
    (SplitMoneyOk /\ last.n > PartCap) => last.ans = "too-many-parts"

\* Op18_NoShareRefused: a [Split] naming no share answers invalid-shares
\* (Operation 18).
Op18_NoShareRefused ==
    (SplitMoneyOk /\ last.n = 0) => last.ans = "invalid-shares"

\* Op19_ShareRefused: a [Split] within the part cap naming a share that is no
\* capped count (zero, or past the cap) answers invalid-shares (Operation 19).
Op19_ShareRefused ==
    (SplitMoneyOk /\ last.n <= PartCap
                  /\ \E i \in 1..last.n : last.sh[i] < 1 \/ last.sh[i] > NumberCap)
        => last.ans = "invalid-shares"

\* SplitOk: a [Split] that answered parts, one per share (so a check below can
\* read part i for every share i).
SplitOk == Atom /\ last.op = "split" /\ last.ans = "ok" /\ DOMAIN last.parts = 1..last.n

\* Op20_OnePartPerShare: a [Split] that answered answered exactly one part per
\* share, in the order of the shares, a part of zero included (Operation 20).
Op20_OnePartPerShare ==
    (Atom /\ last.op = "split" /\ last.ans = "ok") => DOMAIN last.parts = 1..last.n

\* The split's terms spelled again for the checks, from the call's inputs: s
\* the money's size, T the share total, b(i) the base size, short(i) a part
\* whose division leaves something over (by %, not by the action's
\* subtraction), L the leftover, rank(i) how many short parts stand at or
\* before i (counted, not summed), first(i) a short part within the first L,
\* sign the money's sign.
CkS == Size(last.m.amt)
CkT == Sum(last.sh, last.n)
CkB(i) == (CkS * last.sh[i]) \div CkT
CkShort(i) == (CkS * last.sh[i]) % CkT > 0
CkL == CkS - Sum([i \in 1..last.n |-> CkB(i)], last.n)
CkRank(i) == Cardinality({j \in 1..i : CkShort(j)})
CkFirst(i) == CkShort(i) /\ CkRank(i) <= CkL
CkSign == IF last.m.amt < 0 THEN -1 ELSE 1

\* Op21_FirstPartsStepped: in a [Split] that answered, every first part (a
\* short part among the first L short parts, L the leftover, taken from the
\* front of the order of the shares) carries its base share moved one minor
\* unit away from zero: split(USD 2, [2, 1, 1]) gives the leftover to the
\* second part, not the first (Operation 21, Term first parts, Term stepped
\* share).
Op21_FirstPartsStepped ==
    SplitOk => \A i \in 1..last.n : CkFirst(i) => last.parts[i] = CkSign * (CkB(i) + 1)

\* Op22_OtherPartsBase: in a [Split] that answered, every part outside the
\* first parts carries its base share: its base size, with the money's sign
\* (Operation 22, Term base share).
Op22_OtherPartsBase ==
    SplitOk => \A i \in 1..last.n : ~CkFirst(i) => last.parts[i] = CkSign * CkB(i)

\* Inv2_1_SplitAddsUp: the parts of a [Split] that answered add up to the
\* money's amount (Invariant 2.1, Check 2.1). Proved for every size below
\* (THEOREM Invariant_2_1).
Inv2_1_SplitAddsUp ==
    SplitOk => Sum(last.parts, last.n) = last.m.amt

\* Inv3_1_GapBelowShareTotal: no part of a [Split] that answered is a whole
\* minor unit off its exact share: its gap (its size times the share total,
\* less its share product) has a size below the share total (Invariant 3.1,
\* Check 3.1, 3.2). Proved for every size below (THEOREM Invariant_3_1).
Inv3_1_GapBelowShareTotal ==
    SplitOk => \A i \in 1..last.n :
        Size(Size(last.parts[i]) * CkT - CkS * last.sh[i]) < CkT

\* Inv4_1_LeftoverFindsShortPart: for a [Split] that answered, the leftover
\* the action's base sizes leave is no more than the short parts the action
\* counts, so every leftover minor unit finds a short part to take it
\* (Invariant 4.1, Check 4.1). It reads the action's own terms: a call has no
\* answer to show the leftover in. Proved for every size below (THEOREM
\* Invariant_4_1).
Inv4_1_LeftoverFindsShortPart ==
    SplitOk => Leftover(CkS, last.sh, last.n) <= ShortCount(CkS, last.sh, last.n)

\* Inv5_1_RoundTrip: the [Subtract] of the same other money from an [Add]'s
\* result answers the money, its currency and its amount (Invariant 5.1,
\* Check 5.1).
Inv5_1_RoundTrip ==
    last.kind = "roundtrip" => (last.ans = "ok" /\ last.res = first.m)

\* Inv6_1_NegatedMultiply: a [Multiply] naming the money's negation, every
\* other input the same, answers the negation of the first call's result: the
\* tax on a refund is the negation of the tax on the charge (Invariant 6.1,
\* Check 6.1). Proved for every size below (THEOREM Invariant_6_1).
Inv6_1_NegatedMultiply ==
    (last.kind = "negated" /\ last.op = "multiply" /\ first.ans = "ok")
        => (last.ans = "ok" /\ last.res.cur = first.res.cur
            /\ last.res.amt = 0 - first.res.amt)

\* Inv6_2_NegatedSplit: a [Split] naming the money's negation, every other
\* input the same, answers the negation of every part, in the order of the
\* parts (Invariant 6.2, Check 6.2). Proved for every size below (THEOREM
\* Invariant_6_2).
Inv6_2_NegatedSplit ==
    (last.kind = "negated" /\ last.op = "split" /\ first.ans = "ok")
        => (last.ans = "ok" /\ DOMAIN last.parts = DOMAIN first.parts
            /\ \A i \in DOMAIN first.parts : last.parts[i] = 0 - first.parts[i])

\* Op23_WritesNothing: no call of the atom's changes the composing pattern's
\* records; the atom stores no money (Operation 23, State 2).
Op23_WritesNothing ==
    [][last'.kind \in AtomStep => held' = held]_vars

\* Op24_ReadsNoRecord: the first call made again, after the composing pattern
\* has written its records, answers what it answered the first time: the
\* answer comes from the call's inputs alone (Operation 24).
Op24_ReadsNoRecord ==
    last.kind = "repeat"
        => (last.ans = first.ans /\ last.res = first.res /\ last.ord = first.ord
            /\ last.parts = first.parts)

====
