---- MODULE money ----
\* Grace Commons — Money atom (atoms/money.md).
\* Grounded on Final Critique 4, 2026-11-13 at 8b6954c — TLA+ layer authored 2026-11-13.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* PURPOSE
\* Money stores nothing: every action answers from the call's inputs alone
\* (State 2, Operation 23, 24). So this model is not a machine of stored
\* records; it is the six actions as the page states them, each a function from
\* a call's inputs to its answer, and a short sequence of calls around them: a
\* first call; then a composing pattern writing its own records and the same
\* call made again (Operation 23, 24); the same [Multiply] or [Split] made with
\* the money negated (Invariant 6.1, 6.2); and, after an [Add] that answered,
\* the [Subtract] of the same other money from its result (Invariant 5.1). TLC
\* checks every rule below over every call the bounds admit. For the five laws
\* the page claims at every size (Invariant 2.1, 3.1, 4.1, 6.1, 6.2; Generation
\* acceptance), the section PROOFS at the end proves the same operators the
\* actions use for every whole-number amount, every number of parts and every
\* positive share, under TLAPS (tlapm --strict).
\* What one answer must carry as a value (State 1: currency and amount; Identity
\* 2 and 3: currencies compared codepoint for codepoint and never normalized;
\* Invariant 1.1 and 1.2: the money's currency on every result and every part;
\* Invariant 7.1: no result past the number cap) is the Alloy model's,
\* money.als. The two models spell the page's terms alike (money, currency,
\* amount, size, negation, number cap, part cap, well-formed money, result,
\* numerator, denominator, rounding, shares, part).
\*
\* RULES CHECKED (named by the page's own labels)
\*   Operation 1   — a money no well-formed money answers invalid-money  (Op1_InvalidMoney)
\*   Operation 2   — an other money no well-formed money answers
\*                   invalid-money                                      (Op2_OtherInvalidMoney)
\*   Operation 3   — two currencies answer mixed-currency, compared
\*                   codepoint for codepoint (Identity 2)               (Op3_MixedCurrency)
\*   Operation 4   — a sum past the number cap answers over-cap         (Op4_AddOverCap)
\*   Operation 5   — [Add] answers the sum                              (Op5_AddAnswersSum)
\*   Operation 6   — a difference past the cap answers over-cap         (Op6_SubtractOverCap)
\*   Operation 7   — [Subtract] answers the difference                  (Op7_SubtractAnswersDifference)
\*   Operation 8   — [Compare] answers less                             (Op8_CompareLess)
\*   Operation 9   — [Compare] answers equal                            (Op9_CompareEqual)
\*   Operation 10  — [Compare] answers greater                          (Op10_CompareGreater)
\*   Operation 11  — [Negate] answers the negation                      (Op11_NegateAnswersNegation)
\*   Operation 12  — a numerator no capped number answers invalid-rate  (Op12_NumeratorRefused)
\*   Operation 13  — a denominator no capped count answers invalid-rate (Op13_DenominatorRefused)
\*   Operation 14  — no rounding, or one outside the four, answers
\*                   invalid-rounding                                   (Op14_RoundingRefused)
\*   Operation 15  — a rounded size past the cap answers over-cap       (Op15_MultiplyOverCap)
\*   Operation 16  — [Multiply] answers the rounded product             (Op16_MultiplyAnswersRoundedProduct)
\*   Operation 17  — more shares than the part cap answers
\*                   too-many-parts                                     (Op17_TooManyParts)
\*   Operation 18  — no share answers invalid-shares                    (Op18_NoShareRefused)
\*   Operation 19  — a share no capped count answers invalid-shares     (Op19_ShareRefused)
\*   Operation 20  — one part per share, in the order of the shares     (Op20_OnePartPerShare)
\*   Operation 21  — a first part carries its stepped share             (Op21_FirstPartsStepped)
\*   Operation 22  — every other part carries its base share            (Op22_OtherPartsBase)
\*   Operation 23  — an action writes nothing                           (Op23_WritesNothing)
\*   Operation 24  — an action reads no record                          (Op24_ReadsNoRecord)
\*   Invariant 2.1 — a split adds back up                               (Inv2_1_SplitAddsUp)       + proof
\*   Invariant 3.1 — no part a whole minor unit off its exact share     (Inv3_1_GapBelowShareTotal) + proof
\*   Invariant 4.1 — the leftover never exceeds the short count         (Inv4_1_LeftoverFindsShortPart) + proof
\*   Invariant 5.1 — a round trip answers the money                     (Inv5_1_RoundTrip)
\*   Invariant 6.1 — a negated [Multiply] answers the negated result    (Inv6_1_NegatedMultiply)   + proof
\*   Invariant 6.2 — a negated [Split] answers every part negated       (Inv6_2_NegatedSplit)      + proof
\* Where more than one refusal applies, each check expects the one listed
\* first on the action's refuses line (Execution Contract Refusal 1).
\*
\* WHAT THE MODEL TAKES FROM OUTSIDE THE PAGE (its inputs; no ASSUME)
\* - The deployment: a number cap and a part cap, each above zero
\*   (Capability requirement 1, 2, 4, 5), the .cfg's NumberCap and PartCap.
\* - The caller: any call at all, well-formed or not; a composing pattern's
\*   records, which it writes when it likes (Held), and which the atom must
\*   neither write nor read.
\*
\* BOUNDS (the .cfg)
\* A number cap of 4 and a part cap of 3; three currencies, USD, usd (USD in
\* another case: Identity 2) and the currency of no codepoints; amounts and
\* numerators from -5 to 5, one past the cap each way, and a money and a
\* numerator carrying a fraction (10.5 on the page, 1.5 here); denominators
\* from -1 to 5; the four roundings, one outside them (nearest) and none;
\* every list of up to four shares, each from 0 to 5. That reaches every
\* refusal, an exact half of each parity, a rounding that carries a size one
\* past the cap (9 over 2, rounded up, under a cap of 4), a split whose
\* leftover goes to a short part past a part due a whole number (split(2,
\* [2, 1, 1])), and every sign. The composing pattern's records take two
\* values. The section PROOFS has no bound.
\*
\* NOT MODELED HERE
\* - The default caps (eighteen digits; 1,000 parts): TLC counts in 32 bits,
\*   so the model runs under a declared cap (Capability requirement 1, 2); no
\*   rule turns on the cap's value, and the proofs hold at every size.
\* - A fraction in a denominator or a share: it fails the same membership test
\*   as a zero or a negative one (Operation 13, 19), which the model gives.
\* - A currency's length (open 2026-11-13-a: the page bounds none).
\* - The currency an answer carries, and a field an answer leaves out (State
\*   1, Invariant 1.1, 1.2): the Alloy model's. A part here is its amount.
\* - Which currencies exist, a currency's minor unit, conversion (Non-goal 1
\*   to 3: Currency); holding a rate or choosing a rounding (Non-goal 4, 5:
\*   the composing pattern, such as Tax); pricing (Non-goal 6: Pricing); tax
\*   (Non-goal 7: Tax); taking, refunding and settling a payment (Non-goal 8
\*   to 10: Payment); a ledger (Non-goal 11: Ledger); a limit on the sign
\*   (Non-goal 12: the pattern that stores the money, as Gift Card does);
\*   display (Non-goal 13: the deployment). No action here does any of them.
\* - Liveness: the page states no eventually-property, so the model checks
\*   safety only.

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
    ELSE IF rnd \notin Roundings THEN Refuse("invalid-rounding")
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

\* ---------------------------------------------------------------------------
\* PROOFS (TLAPS). The five laws the page claims at every size, proved over
\* the operators the actions above use, for every whole-number amount, every
\* number of parts and every positive share, with no bound: TLC checks them at
\* the sizes in the .cfg; these prove them at all. Invariant_4_1, _2_1 and
\* _3_1 prove them of the split's terms; Split_Answer_Laws reads the three on
\* what [Split] answers; Invariant_6_1 and _6_2 prove them of what [Multiply]
\* and [Split] answer. The lemmas before them build what the proofs need: a
\* running total and its rules (TLAPS's library modules are not used, so the
\* model stays one file TLC can read). The three definitions just below name
\* TLAPS's provers as TLAPS's own module does, so TLC, which does not ship
\* that module, reads the model unchanged. Run: tlapm --strict money.tla.
\* ---------------------------------------------------------------------------

SMT == TRUE (*{ by (prover:"smt3") }*)
Zenon == TRUE (*{ by (prover:"zenon") }*)
IsaM(X) == TRUE (*{ by (prover:"isabelle"; tactic:@) }*)

\* NatInduction: induction over the natural numbers.
LEMMA NatInduction ==
  ASSUME NEW P(_), P(0), \A n \in Nat : P(n) => P(n + 1)
  PROVE  \A n \in Nat : P(n)
BY IsaM("(intro natInduct, auto)")

\* PSExists: the running total is well defined: for every n some function on
\* 0..n meets its definition.
LEMMA PSExists ==
  ASSUME NEW f
  PROVE  \A n \in Nat : \E g : g = [k \in 0..n |-> IF k = 0 THEN 0 ELSE g[k - 1] + f[k]]
<1> DEFINE P(n) == \E g : g = [k \in 0..n |-> IF k = 0 THEN 0 ELSE g[k - 1] + f[k]]
<1>1. P(0)
  <2> DEFINE g0 == [k \in 0..0 |-> 0]
  <2>1. g0 = [k \in 0..0 |-> IF k = 0 THEN 0 ELSE g0[k - 1] + f[k]]  OBVIOUS
  <2> QED  BY <2>1
<1>2. ASSUME NEW n \in Nat, P(n)  PROVE P(n + 1)
  <2>1. PICK g : g = [k \in 0..n |-> IF k = 0 THEN 0 ELSE g[k - 1] + f[k]]  BY <1>2
  <2> DEFINE h == [k \in 0..n + 1 |-> IF k <= n THEN g[k] ELSE g[n] + f[n + 1]]
  <2>2. \A k \in 0..n + 1 : h[k] = IF k = 0 THEN 0 ELSE h[k - 1] + f[k]
    <3> SUFFICES ASSUME NEW k \in 0..n + 1
                 PROVE  h[k] = IF k = 0 THEN 0 ELSE h[k - 1] + f[k]
      OBVIOUS
    <3>1. CASE k = 0  BY <2>1, <3>1
    <3>2. CASE k \in 1..n  BY <2>1, <3>2
    <3>3. CASE k = n + 1  BY <2>1, <3>3
    <3> QED  BY <3>1, <3>2, <3>3
  <2>3. h = [k \in 0..n + 1 |-> IF k = 0 THEN 0 ELSE h[k - 1] + f[k]]  BY <2>2, Zenon
  <2> QED  BY <2>3
<1> HIDE DEF P
<1>3. \A n \in Nat : P(n)  BY <1>1, <1>2, NatInduction
<1> QED  BY <1>3 DEF P

\* PSDef: the running total meets its definition.
LEMMA PSDef ==
  ASSUME NEW f, NEW n \in Nat
  PROVE  PS(f, n) = [k \in 0..n |-> IF k = 0 THEN 0 ELSE PS(f, n)[k - 1] + f[k]]
BY PSExists DEF PS

\* SumZero: nothing added up is zero.
LEMMA SumZero ==
  ASSUME NEW f  PROVE Sum(f, 0) = 0
BY PSDef DEF Sum

\* PSPrefix: the running total to n + 1 agrees with the one to n up to n.
LEMMA PSPrefix ==
  ASSUME NEW f, NEW n \in Nat
  PROVE  \A k \in 0..n : PS(f, n + 1)[k] = PS(f, n)[k]
<1> DEFINE A == PS(f, n + 1)  B == PS(f, n)
<1>1. A = [k \in 0..n + 1 |-> IF k = 0 THEN 0 ELSE A[k - 1] + f[k]]  BY PSDef
<1>2. B = [k \in 0..n |-> IF k = 0 THEN 0 ELSE B[k - 1] + f[k]]  BY PSDef
<1> DEFINE P(k) == k <= n => A[k] = B[k]
<1>3. P(0)  BY <1>1, <1>2
<1>4. ASSUME NEW k \in Nat, P(k)  PROVE P(k + 1)  BY <1>1, <1>2, <1>4
<1> HIDE DEF P, A, B
<1>5. \A k \in Nat : P(k)  BY <1>3, <1>4, NatInduction
<1> QED  BY <1>5 DEF P, A, B

\* SumStep: adding up to n + 1 is adding up to n, then the (n + 1)th.
LEMMA SumStep ==
  ASSUME NEW f, NEW n \in Nat
  PROVE  Sum(f, n + 1) = Sum(f, n) + f[n + 1]
<1>1. PS(f, n + 1)[n + 1] = PS(f, n + 1)[n] + f[n + 1]  BY PSDef
<1>2. PS(f, n + 1)[n] = PS(f, n)[n]  BY PSPrefix
<1> QED  BY <1>1, <1>2 DEF Sum

\* IntsUpTo, LinearUpTo, BelowUpTo: f[1] to f[n] are whole numbers; h[k] is
\* a*f[k] + c*g[k] for each k from 1 to n; f[k] is no more than g[k] for each
\* k from 1 to n. (Named so a lemma below can take each as one hypothesis.)
IntsUpTo(f, n) == \A k \in 1..n : f[k] \in Int
LinearUpTo(h, a, f, c, g, n) == \A k \in 1..n : h[k] = a * f[k] + c * g[k]
BelowUpTo(f, g, n) == \A k \in 1..n : f[k] <= g[k]

\* SumInt: whole numbers add up to a whole number, at every running total.
LEMMA SumInt ==
  ASSUME NEW f, NEW n \in Nat, IntsUpTo(f, n), NEW k \in 0..n
  PROVE  Sum(f, k) \in Int
<1> DEFINE P(j) == j <= n => Sum(f, j) \in Int
<1>1. P(0)  BY SumZero
<1>2. ASSUME NEW j \in Nat, P(j)  PROVE P(j + 1)
  BY <1>2, SumStep DEF IntsUpTo
<1> HIDE DEF P
<1>3. \A j \in Nat : P(j)  BY <1>1, <1>2, NatInduction
<1> QED  BY <1>3 DEF P

\* SumLinear: adding up a*f[k] + c*g[k] is a times f's total plus c times g's.
LEMMA SumLinear ==
  ASSUME NEW f, NEW g, NEW h, NEW a \in Int, NEW c \in Int, NEW n \in Nat,
         IntsUpTo(f, n), IntsUpTo(g, n), LinearUpTo(h, a, f, c, g, n)
  PROVE  Sum(h, n) = a * Sum(f, n) + c * Sum(g, n)
<1> DEFINE P(k) == k <= n => Sum(h, k) = a * Sum(f, k) + c * Sum(g, k)
<1>1. P(0)  BY SumZero
<1>2. ASSUME NEW k \in Nat, P(k)  PROVE P(k + 1)
  <2> SUFFICES ASSUME k + 1 <= n  PROVE Sum(h, k + 1) = a * Sum(f, k + 1) + c * Sum(g, k + 1)
    OBVIOUS
  <2>0. k \in 0..n  OBVIOUS
  <2>1. Sum(f, k) \in Int /\ Sum(g, k) \in Int  BY <2>0, SumInt
  <2>2. Sum(h, k + 1) = Sum(h, k) + h[k + 1]  BY SumStep
  <2>3. Sum(f, k + 1) = Sum(f, k) + f[k + 1]  BY SumStep
  <2>4. Sum(g, k + 1) = Sum(g, k) + g[k + 1]  BY SumStep
  <2>5. f[k + 1] \in Int /\ g[k + 1] \in Int /\ h[k + 1] = a * f[k + 1] + c * g[k + 1]
    BY DEF IntsUpTo, LinearUpTo
  <2>6. Sum(h, k) = a * Sum(f, k) + c * Sum(g, k)  BY <1>2
  <2> QED  BY <2>1, <2>2, <2>3, <2>4, <2>5, <2>6, SMT
<1> HIDE DEF P
<1>3. \A k \in Nat : P(k)  BY <1>1, <1>2, NatInduction
<1> QED  BY <1>3 DEF P

\* SumMono: adding up never reverses a comparison made term by term.
LEMMA SumMono ==
  ASSUME NEW f, NEW g, NEW n \in Nat, IntsUpTo(f, n), IntsUpTo(g, n), BelowUpTo(f, g, n)
  PROVE  Sum(f, n) <= Sum(g, n)
<1> DEFINE P(k) == k <= n => Sum(f, k) <= Sum(g, k)
<1>1. P(0)  BY SumZero
<1>2. ASSUME NEW k \in Nat, P(k)  PROVE P(k + 1)
  <2> SUFFICES ASSUME k + 1 <= n  PROVE Sum(f, k + 1) <= Sum(g, k + 1)
    OBVIOUS
  <2>0. k \in 0..n  OBVIOUS
  <2>1. Sum(f, k) \in Int /\ Sum(g, k) \in Int  BY <2>0, SumInt
  <2>2. Sum(f, k + 1) = Sum(f, k) + f[k + 1]  BY SumStep
  <2>3. Sum(g, k + 1) = Sum(g, k) + g[k + 1]  BY SumStep
  <2>4. f[k + 1] \in Int /\ g[k + 1] \in Int /\ f[k + 1] <= g[k + 1]
    BY DEF IntsUpTo, BelowUpTo
  <2>5. Sum(f, k) <= Sum(g, k)  BY <1>2
  <2> QED  BY <2>1, <2>2, <2>3, <2>4, <2>5, SMT
<1> HIDE DEF P
<1>3. \A k \in Nat : P(k)  BY <1>1, <1>2, NatInduction
<1> QED  BY <1>3 DEF P

\* SumPositive: one positive count or more add up to a positive count.
LEMMA SumPositive ==
  ASSUME NEW f, NEW n \in Nat \ {0}, \A k \in 1..n : f[k] \in Nat \ {0}
  PROVE  Sum(f, n) \in Nat \ {0}
<1> DEFINE P(k) == (k <= n /\ k >= 1) => Sum(f, k) \in Nat \ {0}
<1>1. P(0)  OBVIOUS
<1>2. ASSUME NEW k \in Nat, P(k)  PROVE P(k + 1)
  <2> SUFFICES ASSUME k + 1 <= n  PROVE Sum(f, k + 1) \in Nat \ {0}
    OBVIOUS
  <2>1. Sum(f, k + 1) = Sum(f, k) + f[k + 1]  BY SumStep
  <2>2. CASE k = 0  BY <2>1, <2>2, SumZero
  <2>3. CASE k >= 1  BY <1>2, <2>1, <2>3
  <2> QED  BY <2>2, <2>3
<1> HIDE DEF P
<1>3. \A k \in Nat : P(k)  BY <1>1, <1>2, NatInduction
<1> QED  BY <1>3 DEF P

\* DivFacts: dividing a whole number of zero or more by a positive count
\* rounds down, and leaves over zero or more, below the divisor.
LEMMA DivFacts ==
  ASSUME NEW x \in Nat, NEW t \in Nat \ {0}
  PROVE  /\ x \div t \in Nat
         /\ x - (x \div t) * t \in 0..(t - 1)
BY SMT

\* SplitSetting: the setting of the split lemmas below: a size s, n shares,
\* each a positive count.
SplitSetting(s, sh, n) ==
    /\ s \in Nat
    /\ n \in Nat \ {0}
    /\ \A i \in 1..n : sh[i] \in Nat \ {0}

\* PartFacts: for each part, the share product is the base size times the
\* share total T plus the part remainder; the base size is zero or more; the
\* remainder runs from 0 to T - 1; and a part is short just when its
\* remainder is above zero.
LEMMA PartFacts ==
  ASSUME NEW s, NEW sh, NEW n, SplitSetting(s, sh, n)
  PROVE  /\ ShareTotal(sh, n) \in Nat \ {0}
         /\ IntsUpTo(sh, n)
         /\ \A i \in 1..n :
              /\ s * sh[i] \in Nat
              /\ BaseSize(s, sh, n, i) \in Nat
              /\ PartRemainder(s, sh, n, i) \in 0..(ShareTotal(sh, n) - 1)
              /\ s * sh[i] = BaseSize(s, sh, n, i) * ShareTotal(sh, n) + PartRemainder(s, sh, n, i)
              /\ ShortInd(s, sh, n)[i] = IF PartRemainder(s, sh, n, i) > 0 THEN 1 ELSE 0
<1>1. ShareTotal(sh, n) \in Nat \ {0}  BY SumPositive DEF SplitSetting, ShareTotal
<1>2. IntsUpTo(sh, n)  BY DEF SplitSetting, IntsUpTo
<1>3. ASSUME NEW i \in 1..n
      PROVE  /\ s * sh[i] \in Nat
             /\ BaseSize(s, sh, n, i) \in Nat
             /\ PartRemainder(s, sh, n, i) \in 0..(ShareTotal(sh, n) - 1)
             /\ s * sh[i] = BaseSize(s, sh, n, i) * ShareTotal(sh, n) + PartRemainder(s, sh, n, i)
             /\ ShortInd(s, sh, n)[i] = IF PartRemainder(s, sh, n, i) > 0 THEN 1 ELSE 0
  <2>1. s * sh[i] \in Nat  BY DEF SplitSetting
  <2>2. /\ (s * sh[i]) \div ShareTotal(sh, n) \in Nat
        /\ s * sh[i] - ((s * sh[i]) \div ShareTotal(sh, n)) * ShareTotal(sh, n)
             \in 0..(ShareTotal(sh, n) - 1)
    BY <1>1, <2>1, DivFacts
  <2>3. BaseSize(s, sh, n, i) = (s * sh[i]) \div ShareTotal(sh, n)  BY DEF BaseSize
  <2>4. PartRemainder(s, sh, n, i) = s * sh[i] - BaseSize(s, sh, n, i) * ShareTotal(sh, n)
    BY DEF PartRemainder
  <2>5. ShortInd(s, sh, n)[i] = IF PartRemainder(s, sh, n, i) > 0 THEN 1 ELSE 0
    BY DEF ShortInd
  <2> QED  BY <2>1, <2>2, <2>3, <2>4, <2>5, <1>1
<1> QED  BY <1>1, <1>2, <1>3

\* SplitInts: the share total, the base sizes, the part remainders and the
\* short parts are whole numbers, and so are their totals.
LEMMA SplitInts ==
  ASSUME NEW s, NEW sh, NEW n, SplitSetting(s, sh, n)
  PROVE  /\ IntsUpTo(BaseSizes(s, sh, n), n)
         /\ IntsUpTo(ShortInd(s, sh, n), n)
         /\ IntsUpTo([i \in 1..n |-> PartRemainder(s, sh, n, i)], n)
         /\ Sum(BaseSizes(s, sh, n), n) \in Int
         /\ ShortCount(s, sh, n) \in Int
         /\ Leftover(s, sh, n) \in Int
<1>1. IntsUpTo(BaseSizes(s, sh, n), n)  BY PartFacts DEF IntsUpTo, BaseSizes
<1>2. IntsUpTo(ShortInd(s, sh, n), n)  BY PartFacts DEF IntsUpTo
<1>3. IntsUpTo([i \in 1..n |-> PartRemainder(s, sh, n, i)], n)  BY PartFacts DEF IntsUpTo
<1>4. n \in Nat /\ n \in 0..n  BY DEF SplitSetting
<1>5. Sum(BaseSizes(s, sh, n), n) \in Int  BY <1>1, <1>4, SumInt
<1>6. ShortCount(s, sh, n) \in Int  BY <1>2, <1>4, SumInt DEF ShortCount
<1> QED  BY <1>1, <1>2, <1>3, <1>5, <1>6 DEF Leftover, SplitSetting

\* RemainderTotal: the part remainders add up to the share total times the
\* leftover: the share products add up to s times T, and the base sizes times
\* T to T times the base sizes added up.
LEMMA RemainderTotal ==
  ASSUME NEW s, NEW sh, NEW n, SplitSetting(s, sh, n)
  PROVE  Sum([i \in 1..n |-> PartRemainder(s, sh, n, i)], n)
           = ShareTotal(sh, n) * Leftover(s, sh, n)
<1> DEFINE T == ShareTotal(sh, n)
           R == [i \in 1..n |-> PartRemainder(s, sh, n, i)]
           B == BaseSizes(s, sh, n)
<1>0. /\ T = ShareTotal(sh, n) /\ T = Sum(sh, n)
      /\ R = [i \in 1..n |-> PartRemainder(s, sh, n, i)]
      /\ B = BaseSizes(s, sh, n)
  BY DEF ShareTotal
<1>1. T \in Nat \ {0} /\ IntsUpTo(sh, n)  BY PartFacts
<1>2. IntsUpTo(B, n) /\ Sum(B, n) \in Int  BY SplitInts
<1>3. LinearUpTo(R, s, sh, -T, B, n)
  <2> SUFFICES ASSUME NEW i \in 1..n  PROVE R[i] = s * sh[i] + (-T) * B[i]
    BY DEF LinearUpTo
  <2>1. B[i] = BaseSize(s, sh, n, i) /\ R[i] = PartRemainder(s, sh, n, i)  BY DEF BaseSizes
  <2>2. s * sh[i] = BaseSize(s, sh, n, i) * T + PartRemainder(s, sh, n, i)
        /\ BaseSize(s, sh, n, i) \in Nat /\ PartRemainder(s, sh, n, i) \in Int
        /\ s * sh[i] \in Nat
    BY PartFacts
  <2> HIDE DEF T, R, B
  <2> QED  BY <1>1, <2>1, <2>2, SMT
<1>4. s \in Int /\ -T \in Int /\ n \in Nat  BY <1>1 DEF SplitSetting
<1>5. Sum(R, n) = s * Sum(sh, n) + (-T) * Sum(B, n)  BY <1>1, <1>2, <1>3, <1>4, SumLinear
<1>6. Leftover(s, sh, n) = s - Sum(B, n)  BY DEF Leftover
<1> HIDE DEF T, R, B
<1> QED  BY <1>0, <1>1, <1>2, <1>4, <1>5, <1>6, SMT

\* ShortBound: the part remainders add up to no more than T - 1 times the
\* short count, and to zero or more; the short count is zero or more.
LEMMA ShortBound ==
  ASSUME NEW s, NEW sh, NEW n, SplitSetting(s, sh, n)
  PROVE  /\ Sum([i \in 1..n |-> PartRemainder(s, sh, n, i)], n)
              <= (ShareTotal(sh, n) - 1) * ShortCount(s, sh, n)
         /\ Sum([i \in 1..n |-> PartRemainder(s, sh, n, i)], n) >= 0
         /\ ShortCount(s, sh, n) >= 0
<1> DEFINE T == ShareTotal(sh, n)
           R == [i \in 1..n |-> PartRemainder(s, sh, n, i)]
           I == ShortInd(s, sh, n)
           Z == [i \in 1..n |-> 0]
           U == [i \in 1..n |-> (T - 1) * I[i]]
<1>0. /\ T = ShareTotal(sh, n)
      /\ R = [i \in 1..n |-> PartRemainder(s, sh, n, i)]
      /\ I = ShortInd(s, sh, n)
  OBVIOUS
<1>1. T \in Nat \ {0} /\ n \in Nat  BY PartFacts DEF SplitSetting
<1>2. IntsUpTo(R, n) /\ IntsUpTo(I, n) /\ ShortCount(s, sh, n) \in Int  BY SplitInts
<1>3. \A i \in 1..n : /\ R[i] \in 0..(T - 1)
                      /\ I[i] = IF R[i] > 0 THEN 1 ELSE 0
  BY PartFacts
<1>4. IntsUpTo(U, n) /\ IntsUpTo(Z, n)  BY <1>1, <1>3 DEF IntsUpTo
<1>5. BelowUpTo(R, U, n)
  <2> SUFFICES ASSUME NEW i \in 1..n  PROVE R[i] <= U[i]  BY DEF BelowUpTo
  <2>1. R[i] \in 0..(T - 1) /\ I[i] = IF R[i] > 0 THEN 1 ELSE 0  BY <1>3
  <2>2. U[i] = (T - 1) * I[i]  OBVIOUS
  <2> HIDE DEF T, R, I, U
  <2> QED  BY <1>1, <2>1, <2>2, SMT
<1>6. BelowUpTo(Z, R, n) /\ BelowUpTo(Z, I, n)  BY <1>3 DEF BelowUpTo
<1>7. LinearUpTo(U, T - 1, I, 0, I, n) /\ LinearUpTo(Z, 0, I, 0, I, n)
  BY <1>1, <1>3 DEF LinearUpTo
<1>8. Sum(R, n) <= Sum(U, n)  BY <1>1, <1>2, <1>4, <1>5, SumMono
<1>9. Sum(U, n) = (T - 1) * Sum(I, n) + 0 * Sum(I, n)  BY <1>1, <1>2, <1>7, SumLinear
<1>10. Sum(Z, n) = 0 * Sum(I, n) + 0 * Sum(I, n)  BY <1>1, <1>2, <1>4, <1>7, SumLinear
<1>11. Sum(Z, n) <= Sum(R, n) /\ Sum(Z, n) <= Sum(I, n)  BY <1>1, <1>2, <1>4, <1>6, SumMono
<1>12. Sum(I, n) = ShortCount(s, sh, n)  BY DEF ShortCount
<1>13. Sum(R, n) \in Int  BY <1>1, <1>2, SumInt
<1> HIDE DEF T, R, I, Z, U
<1> QED  BY <1>0, <1>1, <1>2, <1>8, <1>9, <1>10, <1>11, <1>12, <1>13, SMT

\* THEOREM Invariant_4_1: for a money of any size split by any number of
\* positive shares, the leftover is never more than the short count, and is
\* zero or more (Invariant 4.1).
THEOREM Invariant_4_1 ==
  ASSUME NEW s, NEW sh, NEW n, SplitSetting(s, sh, n)
  PROVE  /\ Leftover(s, sh, n) <= ShortCount(s, sh, n)
         /\ Leftover(s, sh, n) >= 0
<1> DEFINE T == ShareTotal(sh, n)  L == Leftover(s, sh, n)  C == ShortCount(s, sh, n)
           X == Sum([i \in 1..n |-> PartRemainder(s, sh, n, i)], n)
<1>0. L = Leftover(s, sh, n) /\ C = ShortCount(s, sh, n)  OBVIOUS
<1>1. T \in Nat \ {0}  BY PartFacts
<1>2. X = T * L  BY RemainderTotal
<1>3. X <= (T - 1) * C /\ X >= 0 /\ C >= 0  BY ShortBound
<1>4. L \in Int /\ C \in Int /\ X \in Int
  <2>1. IntsUpTo([i \in 1..n |-> PartRemainder(s, sh, n, i)], n) /\ n \in Nat /\ n \in 0..n
    BY SplitInts DEF SplitSetting
  <2> QED  BY <2>1, SplitInts, SumInt
<1> HIDE DEF T, L, C, X
<1>5. L >= 0
  <2> SUFFICES ASSUME L < 0  PROVE FALSE  BY <1>4, SMT
  <2>1. T * L < 0  BY <1>1, <1>4, SMT
  <2> QED  BY <2>1, <1>2, <1>3, <1>4, SMT
<1>6. L <= C
  <2> SUFFICES ASSUME L > C  PROVE FALSE  BY <1>4, SMT
  <2> DEFINE d == L - C - 1
  <2>1. d \in Nat  BY <1>4, SMT
  <2>2. T * L = T * C + T + T * d  BY <1>1, <1>4, SMT
  <2>3. T * d >= 0  BY <1>1, <2>1, SMT
  <2>4. (T - 1) * C = T * C - C  BY <1>1, <1>4, SMT
  <2> HIDE DEF d
  \* the contradiction in three linear steps over the products T * L, T * C and (T - 1) * C, each with the typing it needs,
  \* so no one solver call has to reason about all five facts at once (the one call that did failed on a slower runner)
  <2>5. T * L >= T * C + T  BY <1>1, <1>4, <2>1, <2>2, <2>3, SMT
  <2>6. T * C + T > (T - 1) * C  BY <1>1, <1>3, <1>4, <2>4, SMT
  <2> QED  BY <1>1, <1>2, <1>3, <1>4, <2>5, <2>6, SMT
<1> QED  BY <1>0, <1>5, <1>6

\* FirstCount: the first parts are as many as the leftover.
LEMMA FirstCount ==
  ASSUME NEW s, NEW sh, NEW n, SplitSetting(s, sh, n)
  PROVE  Sum([i \in 1..n |-> IF IsFirst(s, sh, n, i) THEN 1 ELSE 0], n) = Leftover(s, sh, n)
<1> DEFINE L == Leftover(s, sh, n)
           I == ShortInd(s, sh, n)
           F == [i \in 1..n |-> IF IsFirst(s, sh, n, i) THEN 1 ELSE 0]
           Min(x, y) == IF x <= y THEN x ELSE y
<1>0. n \in Nat \ {0}  BY DEF SplitSetting
<1>1. L >= 0 /\ L <= Sum(I, n) /\ L \in Int  BY Invariant_4_1, SplitInts DEF ShortCount
<1>2. \A i \in 1..n : /\ I[i] \in {0, 1}
                      /\ F[i] = IF I[i] = 1 /\ Sum(I, i) <= L THEN 1 ELSE 0
  BY PartFacts DEF IsFirst
<1>3. IntsUpTo(I, n) /\ IntsUpTo(F, n) /\ n \in Nat
  BY <1>2, SplitInts DEF IntsUpTo, SplitSetting
<1> DEFINE P(k) == k <= n => Sum(F, k) = Min(Sum(I, k), L)
<1>4. P(0)  BY <1>1, SumZero
<1>5. ASSUME NEW k \in Nat, P(k)  PROVE P(k + 1)
  <2> SUFFICES ASSUME k + 1 <= n  PROVE Sum(F, k + 1) = Min(Sum(I, k + 1), L)
    OBVIOUS
  <2>0. k \in 0..n /\ k + 1 \in 0..n /\ k + 1 \in 1..n  BY <1>0
  <2>1. Sum(F, k + 1) = Sum(F, k) + F[k + 1]  BY SumStep
  <2>2. Sum(I, k + 1) = Sum(I, k) + I[k + 1]  BY SumStep
  <2>3. Sum(I, k) \in Int /\ Sum(F, k) \in Int /\ Sum(I, k + 1) \in Int
    BY <1>3, <2>0, SumInt
  <2>4. I[k + 1] \in {0, 1} /\ F[k + 1] = IF I[k + 1] = 1 /\ Sum(I, k + 1) <= L THEN 1 ELSE 0
    BY <1>2, <2>0
  <2>5. Sum(F, k) = Min(Sum(I, k), L)  BY <1>5, <2>0
  <2> HIDE DEF L, I, F
  <2> QED  BY <1>1, <2>1, <2>2, <2>3, <2>4, <2>5, SMT
<1> HIDE DEF P
<1>6. \A k \in Nat : P(k)  BY <1>4, <1>5, NatInduction
<1>7. Sum(F, n) = Min(Sum(I, n), L)  BY <1>3, <1>6 DEF P
<1>8. Sum(I, n) \in Int  BY <1>0, <1>3, SumInt
<1> QED  BY <1>1, <1>7, <1>8

\* THEOREM Invariant_2_1: for a money of any whole amount split by any number
\* of positive shares, the parts add back up to the amount (Invariant 2.1).
THEOREM Invariant_2_1 ==
  ASSUME NEW a \in Int, NEW sh, NEW n, SplitSetting(Size(a), sh, n)
  PROVE  Sum(SplitParts(a, sh, n), n) = a
<1> DEFINE s == Size(a)
           L == Leftover(s, sh, n)
           B == BaseSizes(s, sh, n)
           F == [i \in 1..n |-> IF IsFirst(s, sh, n, i) THEN 1 ELSE 0]
           sg == IF a < 0 THEN -1 ELSE 1
           P == SplitParts(a, sh, n)
<1>0. SplitSetting(s, sh, n) /\ n \in Nat \ {0} /\ s \in Nat  BY DEF SplitSetting
<1>1. IntsUpTo(B, n) /\ IntsUpTo(F, n) /\ n \in Nat /\ sg \in Int /\ Step(a) \in Int
  BY SplitInts DEF IntsUpTo, SplitSetting, Step
<1>2. LinearUpTo(P, sg, B, Step(a), F, n)
  <2> SUFFICES ASSUME NEW i \in 1..n  PROVE P[i] = sg * B[i] + Step(a) * F[i]
    BY DEF LinearUpTo
  <2>1. B[i] \in Int /\ B[i] = BaseSize(s, sh, n, i)  BY <1>1 DEF IntsUpTo, BaseSizes
  <2>2. P[i] = IF IsFirst(s, sh, n, i) THEN BaseShare(a, sh, n, i) + Step(a)
                                       ELSE BaseShare(a, sh, n, i)
    BY DEF SplitParts
  <2>3. BaseShare(a, sh, n, i) = sg * B[i]  BY <2>1 DEF BaseShare
  <2>4. F[i] = IF IsFirst(s, sh, n, i) THEN 1 ELSE 0  OBVIOUS
  <2> HIDE DEF s, L, B, F, sg, P
  <2> QED  BY <1>1, <2>1, <2>2, <2>3, <2>4, SMT
<1>3. Sum(P, n) = sg * Sum(B, n) + Step(a) * Sum(F, n)  BY <1>1, <1>2, SumLinear
<1>4. Sum(F, n) = L  BY FirstCount
<1>5. Sum(B, n) = s - L /\ L \in Int /\ Sum(B, n) \in Int  BY <1>0, SplitInts DEF Leftover
<1>6. a = 0 => L = 0
  <2> SUFFICES ASSUME a = 0  PROVE L = 0  OBVIOUS
  <2>1. s = 0  BY DEF Size
  <2>2. \A i \in 1..n : PartRemainder(s, sh, n, i) = 0
    <3> SUFFICES ASSUME NEW i \in 1..n  PROVE PartRemainder(s, sh, n, i) = 0  OBVIOUS
    <3>1. s * sh[i] = BaseSize(s, sh, n, i) * ShareTotal(sh, n) + PartRemainder(s, sh, n, i)
          /\ BaseSize(s, sh, n, i) \in Nat /\ ShareTotal(sh, n) \in Nat \ {0}
          /\ PartRemainder(s, sh, n, i) \in 0..(ShareTotal(sh, n) - 1)
          /\ sh[i] \in Int
      BY PartFacts DEF IntsUpTo
    <3> HIDE DEF s
    <3> QED  BY <2>1, <3>1, SMT
  <2>3. LinearUpTo(ShortInd(s, sh, n), 0, ShortInd(s, sh, n), 0, ShortInd(s, sh, n), n)
    BY <2>2, PartFacts DEF LinearUpTo
  <2>4. ShortCount(s, sh, n) = 0 * ShortCount(s, sh, n) + 0 * ShortCount(s, sh, n)
    BY <2>3, <1>1, SplitInts, SumLinear DEF ShortCount
  <2>5. ShortCount(s, sh, n) = 0  BY <1>0, <2>4, SplitInts, SMT
  <2>6. L <= ShortCount(s, sh, n) /\ L >= 0  BY <1>0, Invariant_4_1
  <2> QED  BY <2>5, <2>6, <1>5, SMT
<1>7. P = SplitParts(a, sh, n) /\ s = Size(a)  OBVIOUS
<1> HIDE DEF L, B, F, P
<1> QED  BY <1>3, <1>4, <1>5, <1>6, <1>7, SMT DEF Step, Size

\* THEOREM Invariant_3_1: for a money of any whole amount split by any number
\* of positive shares, every part's gap has a size below the share total: no
\* part is a whole minor unit off its exact share (Invariant 3.1).
THEOREM Invariant_3_1 ==
  ASSUME NEW a \in Int, NEW sh, NEW n, SplitSetting(Size(a), sh, n), NEW i \in 1..n
  PROVE  Size(Size(SplitParts(a, sh, n)[i]) * ShareTotal(sh, n) - Size(a) * sh[i])
           < ShareTotal(sh, n)
<1> DEFINE s == Size(a)  T == ShareTotal(sh, n)  b == BaseSize(s, sh, n, i)
           r == PartRemainder(s, sh, n, i)  x == s * sh[i]
<1>0. T = ShareTotal(sh, n) /\ x = Size(a) * sh[i] /\ s = Size(a)  OBVIOUS
<1>1. T \in Nat \ {0} /\ b \in Nat /\ r \in 0..(T - 1) /\ x = b * T + r /\ s \in Nat
      /\ x \in Nat /\ sh[i] \in Nat
  BY PartFacts DEF SplitSetting
<1>2. CASE IsFirst(s, sh, n, i)
  <2>1. r > 0  BY <1>2 DEF IsFirst
  <2>2. a # 0
    <3> SUFFICES ASSUME a = 0  PROVE FALSE  OBVIOUS
    <3>1. s = 0  BY DEF Size
    <3>2. x = 0  BY <3>1, <1>1, SMT
    <3>3. b * T >= 0  BY <1>1, SMT
    <3> HIDE DEF s, T, b, r, x
    <3> QED  BY <1>1, <2>1, <3>2, <3>3, SMT
  <2>3. Size(SplitParts(a, sh, n)[i]) = b + 1
    BY <1>1, <1>2, <2>2 DEF SplitParts, BaseShare, Step, Size
  <2>4. (b + 1) * T - x = T - r  BY <1>1, SMT
  <2> HIDE DEF s, T, b, r, x
  <2> QED  BY <1>0, <1>1, <2>1, <2>3, <2>4, SMT DEF Size
<1>3. CASE ~IsFirst(s, sh, n, i)
  <2>1. Size(SplitParts(a, sh, n)[i]) = b
    BY <1>1, <1>3 DEF SplitParts, BaseShare, Size
  <2>2. b * T - x = -r  BY <1>1, SMT
  <2> HIDE DEF s, T, b, r, x
  <2> QED  BY <1>0, <1>1, <2>1, <2>2, SMT DEF Size
<1> QED  BY <1>2, <1>3

\* MultiplyOk: where [Multiply] answers a result, its money is well-formed,
\* its rate good, its rounding one of the four, and its rounded size within
\* the cap; and the result is the rounded product in the money's currency.
LEMMA MultiplyOk ==
  ASSUME NEW m, NEW num, NEW nw, NEW den, NEW rnd,
         MultiplyAnswer(m, num, nw, den, rnd).ans = "ok"
  PROVE  /\ WellFormed(m) /\ CappedNumber(num, nw) /\ CappedCount(den) /\ rnd \in Roundings
         /\ ~(RoundedSize(Product(m.amt, num), den, rnd) > NumberCap)
         /\ MultiplyAnswer(m, num, nw, den, rnd)
              = Result(m.cur, RoundedProduct(Product(m.amt, num), den, rnd))
<1> DEFINE A == MultiplyAnswer(m, num, nw, den, rnd)
<1>1. WellFormed(m)
  <2> SUFFICES ASSUME ~WellFormed(m)  PROVE FALSE  OBVIOUS
  <2>1. A = Refuse("invalid-money")  BY DEF MultiplyAnswer
  <2> QED  BY <2>1 DEF Refuse, Ans
<1>2. CappedNumber(num, nw) /\ CappedCount(den)
  <2> SUFFICES ASSUME ~(CappedNumber(num, nw) /\ CappedCount(den))  PROVE FALSE  OBVIOUS
  <2>1. A = Refuse("invalid-rate")  BY <1>1 DEF MultiplyAnswer
  <2> QED  BY <2>1 DEF Refuse, Ans
<1>3. rnd \in Roundings
  <2> SUFFICES ASSUME rnd \notin Roundings  PROVE FALSE  OBVIOUS
  <2>1. A = Refuse("invalid-rounding")  BY <1>1, <1>2 DEF MultiplyAnswer
  <2> QED  BY <2>1 DEF Refuse, Ans
<1>4. ~(RoundedSize(Product(m.amt, num), den, rnd) > NumberCap)
  <2> SUFFICES ASSUME RoundedSize(Product(m.amt, num), den, rnd) > NumberCap  PROVE FALSE
    OBVIOUS
  <2>1. A = Refuse("over-cap")  BY <1>1, <1>2, <1>3 DEF MultiplyAnswer
  <2> QED  BY <2>1 DEF Refuse, Ans
<1>5. A = Result(m.cur, RoundedProduct(Product(m.amt, num), den, rnd))
  BY <1>1, <1>2, <1>3, <1>4 DEF MultiplyAnswer
<1> QED  BY <1>1, <1>2, <1>3, <1>4, <1>5

\* THEOREM Invariant_6_1: for a money of any whole amount and any rate and
\* rounding, where [Multiply] answers a result, the same call naming the
\* money's negation answers the negation of that result (Invariant 6.1).
THEOREM Invariant_6_1 ==
  ASSUME NEW m \in [cur : STRING, amt : Int, whole : BOOLEAN], NEW num \in Int,
         NEW nw \in BOOLEAN, NEW den \in Int, NEW rnd,
         MultiplyAnswer(m, num, nw, den, rnd).ans = "ok"
  PROVE  /\ MultiplyAnswer(NegMoney(m), num, nw, den, rnd).ans = "ok"
         /\ MultiplyAnswer(NegMoney(m), num, nw, den, rnd).res.cur
              = MultiplyAnswer(m, num, nw, den, rnd).res.cur
         /\ MultiplyAnswer(NegMoney(m), num, nw, den, rnd).res.amt
              = -MultiplyAnswer(m, num, nw, den, rnd).res.amt
<1> DEFINE p == Product(m.amt, num)  q == Product(NegMoney(m).amt, num)
<1>1. NegMoney(m).cur = m.cur /\ NegMoney(m).whole = m.whole /\ NegMoney(m).amt = -m.amt
  BY DEF NegMoney
<1>2. q = -p /\ p \in Int  BY <1>1, SMT DEF Product
<1>3. Size(q) = Size(p) /\ Size(NegMoney(m).amt) = Size(m.amt)  BY <1>1, <1>2 DEF Size
<1>4. Quotient(q, den) = Quotient(p, den) /\ Remainder(q, den) = Remainder(p, den)
  BY <1>3 DEF Quotient, Remainder
<1>5. RoundedSize(q, den, rnd) = RoundedSize(p, den, rnd)  BY <1>4 DEF RoundedSize
<1>6. WellFormed(NegMoney(m)) = WellFormed(m)  BY <1>1, <1>3 DEF WellFormed
<1>7. /\ WellFormed(m) /\ CappedNumber(num, nw) /\ CappedCount(den) /\ rnd \in Roundings
      /\ ~(RoundedSize(p, den, rnd) > NumberCap)
      /\ MultiplyAnswer(m, num, nw, den, rnd) = Result(m.cur, RoundedProduct(p, den, rnd))
  BY MultiplyOk
<1>8. MultiplyAnswer(NegMoney(m), num, nw, den, rnd)
        = Result(m.cur, RoundedProduct(q, den, rnd))
  <2>1. ~(RoundedSize(q, den, rnd) > NumberCap)  BY <1>5, <1>7
  <2> QED  BY <1>1, <1>6, <1>7, <2>1 DEF MultiplyAnswer
<1>9. den \in Nat \ {0}  BY <1>7 DEF CappedCount
<1>10. Quotient(p, den) \in Nat /\ Remainder(p, den) \in Int
  BY <1>2, <1>9, SMT DEF Quotient, Remainder, Size
<1>11. RoundedSize(p, den, rnd) \in Int  BY <1>7, <1>10 DEF RoundedSize, Roundings
<1>12. p = 0 => RoundedSize(p, den, rnd) = 0
  <2> SUFFICES ASSUME p = 0  PROVE RoundedSize(p, den, rnd) = 0  OBVIOUS
  <2>1. Quotient(p, den) = 0 /\ Remainder(p, den) = 0
    BY <1>9, SMT DEF Quotient, Remainder, Size
  <2> QED  BY <1>9, <2>1, <1>7 DEF RoundedSize, Roundings
<1>13. RoundedProduct(q, den, rnd) = -RoundedProduct(p, den, rnd)
  BY <1>2, <1>5, <1>11, <1>12 DEF RoundedProduct
<1> QED  BY <1>7, <1>8, <1>13 DEF Result, Ans

\* SplitOkFacts: where [Split] answers parts, its money is well-formed, it
\* names one share to the part cap, each a capped count; and the parts are
\* the money's split.
LEMMA SplitOkFacts ==
  ASSUME NEW m, NEW sh, NEW n, SplitAnswer(m, sh, n).ans = "ok"
  PROVE  /\ WellFormed(m) /\ ~(n > PartCap) /\ n # 0 /\ \A i \in 1..n : CappedCount(sh[i])
         /\ SplitAnswer(m, sh, n) = Ans("ok", NoMoney, "n/a", SplitParts(m.amt, sh, n))
<1> DEFINE A == SplitAnswer(m, sh, n)
<1>1. WellFormed(m)
  <2> SUFFICES ASSUME ~WellFormed(m)  PROVE FALSE  OBVIOUS
  <2>1. A = Refuse("invalid-money")  BY DEF SplitAnswer
  <2> QED  BY <2>1 DEF Refuse, Ans
<1>2. ~(n > PartCap)
  <2> SUFFICES ASSUME n > PartCap  PROVE FALSE  OBVIOUS
  <2>1. A = Refuse("too-many-parts")  BY <1>1 DEF SplitAnswer
  <2> QED  BY <2>1 DEF Refuse, Ans
<1>3. n # 0 /\ \A i \in 1..n : CappedCount(sh[i])
  <2> SUFFICES ASSUME n = 0 \/ \E i \in 1..n : ~CappedCount(sh[i])  PROVE FALSE  OBVIOUS
  <2>1. A = Refuse("invalid-shares")  BY <1>1, <1>2 DEF SplitAnswer
  <2> QED  BY <2>1 DEF Refuse, Ans
<1>4. A = Ans("ok", NoMoney, "n/a", SplitParts(m.amt, sh, n))
  BY <1>1, <1>2, <1>3 DEF SplitAnswer
<1> QED  BY <1>1, <1>2, <1>3, <1>4

\* THEOREM Invariant_6_2: for a money of any whole amount and any shares,
\* where [Split] answers parts, the same call naming the money's negation
\* answers the negation of every part, in the order of the parts (Invariant
\* 6.2).
THEOREM Invariant_6_2 ==
  ASSUME NEW m \in [cur : STRING, amt : Int, whole : BOOLEAN], NEW sh, NEW n \in Nat,
         SplitAnswer(m, sh, n).ans = "ok"
  PROVE  /\ SplitAnswer(NegMoney(m), sh, n).ans = "ok"
         /\ DOMAIN SplitAnswer(NegMoney(m), sh, n).parts = DOMAIN SplitAnswer(m, sh, n).parts
         /\ \A i \in DOMAIN SplitAnswer(m, sh, n).parts :
              SplitAnswer(NegMoney(m), sh, n).parts[i] = -SplitAnswer(m, sh, n).parts[i]
<1> DEFINE a == m.amt  s == Size(a)
<1>1. NegMoney(m).amt = -a /\ Size(-a) = s /\ s \in Nat /\ a \in Int  BY DEF NegMoney, Size
<1>2. WellFormed(NegMoney(m)) = WellFormed(m)  BY <1>1 DEF WellFormed, NegMoney
<1>3. /\ WellFormed(m) /\ ~(n > PartCap) /\ n # 0 /\ \A i \in 1..n : CappedCount(sh[i])
      /\ SplitAnswer(m, sh, n) = Ans("ok", NoMoney, "n/a", SplitParts(a, sh, n))
  BY SplitOkFacts
<1>4. SplitAnswer(NegMoney(m), sh, n) = Ans("ok", NoMoney, "n/a", SplitParts(-a, sh, n))
  BY <1>1, <1>2, <1>3 DEF SplitAnswer
<1>5. SplitSetting(s, sh, n)
  <2>1. \A i \in 1..n : sh[i] \in Nat \ {0}  BY <1>3 DEF CappedCount
  <2> QED  BY <1>1, <1>3, <2>1 DEF SplitSetting
<1>6. ASSUME NEW i \in 1..n  PROVE SplitParts(-a, sh, n)[i] = -SplitParts(a, sh, n)[i]
  <2>1. BaseSize(s, sh, n, i) \in Nat /\ ShareTotal(sh, n) \in Nat \ {0}  BY <1>5, PartFacts
  <2>2. a = 0 => BaseSize(s, sh, n, i) = 0
    <3> SUFFICES ASSUME a = 0  PROVE BaseSize(s, sh, n, i) = 0  OBVIOUS
    <3>1. s = 0  BY DEF Size
    <3>2. sh[i] \in Int  BY <1>3 DEF CappedCount
    <3> HIDE DEF s
    <3> QED  BY <2>1, <3>1, <3>2, SMT DEF BaseSize
  <2>3. Step(-a) = -Step(a) /\ (a = 0 => Step(a) = 0)  BY <1>1 DEF Step
  <2>4. BaseShare(-a, sh, n, i) = -BaseShare(a, sh, n, i)
    BY <1>1, <2>1, <2>2 DEF BaseShare
  <2>5. IsFirst(Size(-a), sh, n, i) = IsFirst(s, sh, n, i)  BY <1>1
  <2>6. BaseShare(a, sh, n, i) \in Int /\ Step(a) \in Int  BY <2>1 DEF BaseShare, Step
  <2>7. SplitParts(-a, sh, n)[i] = IF IsFirst(Size(-a), sh, n, i)
                                   THEN BaseShare(-a, sh, n, i) + Step(-a)
                                   ELSE BaseShare(-a, sh, n, i)
    BY DEF SplitParts
  <2>8. SplitParts(a, sh, n)[i] = IF IsFirst(s, sh, n, i)
                                  THEN BaseShare(a, sh, n, i) + Step(a)
                                  ELSE BaseShare(a, sh, n, i)
    BY DEF SplitParts
  <2> QED  BY <2>3, <2>4, <2>5, <2>6, <2>7, <2>8, SMT
<1>7. DOMAIN SplitParts(a, sh, n) = 1..n /\ DOMAIN SplitParts(-a, sh, n) = 1..n
  BY DEF SplitParts
<1> QED  BY <1>3, <1>4, <1>6, <1>7 DEF Ans

\* THEOREM Split_Answer_Laws: the three split laws read on what the [Split]
\* action answers: wherever it answers parts, for a money of any whole amount
\* and any shares, the parts add up to the money's amount (Invariant 2.1),
\* every part's gap has a size below the share total (Invariant 3.1), and the
\* leftover is no more than the short count (Invariant 4.1).
THEOREM Split_Answer_Laws ==
  ASSUME NEW m \in [cur : STRING, amt : Int, whole : BOOLEAN], NEW sh, NEW n \in Nat,
         SplitAnswer(m, sh, n).ans = "ok"
  PROVE  /\ Sum(SplitAnswer(m, sh, n).parts, n) = m.amt
         /\ \A i \in 1..n :
              Size(Size(SplitAnswer(m, sh, n).parts[i]) * ShareTotal(sh, n) - Size(m.amt) * sh[i])
                < ShareTotal(sh, n)
         /\ Leftover(Size(m.amt), sh, n) <= ShortCount(Size(m.amt), sh, n)
<1>1. /\ WellFormed(m) /\ ~(n > PartCap) /\ n # 0 /\ \A i \in 1..n : CappedCount(sh[i])
      /\ SplitAnswer(m, sh, n) = Ans("ok", NoMoney, "n/a", SplitParts(m.amt, sh, n))
  BY SplitOkFacts
<1>2. SplitAnswer(m, sh, n).parts = SplitParts(m.amt, sh, n)  BY <1>1 DEF Ans
<1>3. SplitSetting(Size(m.amt), sh, n)
  <2>1. \A i \in 1..n : sh[i] \in Nat \ {0}  BY <1>1 DEF CappedCount
  <2>2. Size(m.amt) \in Nat  BY DEF Size
  <2> QED  BY <1>1, <2>1, <2>2 DEF SplitSetting
<1>4. Sum(SplitParts(m.amt, sh, n), n) = m.amt  BY <1>3, Invariant_2_1
<1>5. \A i \in 1..n :
        Size(Size(SplitParts(m.amt, sh, n)[i]) * ShareTotal(sh, n) - Size(m.amt) * sh[i])
          < ShareTotal(sh, n)
  BY <1>3, Invariant_3_1
<1>6. Leftover(Size(m.amt), sh, n) <= ShortCount(Size(m.amt), sh, n)  BY <1>3, Invariant_4_1
<1> QED  BY <1>2, <1>4, <1>5, <1>6

====
