---- MODULE gift-card-buggy-spend-zero-amount ----
\* DELIBERATELY WRONG twin of gift-card.tla (unit: `atoms/gift-card.md formal layer`).
\*
\* INJECTED DEFECT: [Spend] admits an amount of zero, a whole amount but not a positive
\* amount, and answers the balance (Operation 10 off by one).
\*
\* BREAKS: Op10_NonPositiveAmountRefused.
\* Everything else is gift-card.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    MaxCards,   \* how many card ids the seam supplies in the model
    Accepted,   \* the accepted currencies (Capability requirement 5)
    Codes,      \* the card codes the seam may supply and a code action may present
    Values,     \* the values an [Issue] may carry, each a positive amount within the cap
    Amounts     \* the amounts a [Spend] may carry, whole numbers, zero included

\* Ids: the card ids the seam may supply, in the order it supplies them.
Ids == 1..MaxCards

\* NoCode: the code field of an answer that carries no code.
NoCode == "none"

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action; the gift card it named or found (0 for
\* none); the code and the amount it carried; what it answered, and the code,
\* balance and currency its answer carried.
NoCall == [op |-> "none", card |-> 0, code |-> NoCode, amt |-> 0, ans |-> "none",
           outCode |-> NoCode, outBal |-> 0, outCur |-> "none"]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    issued,  \* card id -> whether a gift card carries it
    code,    \* card id -> the gift card's card code (NoCode before it is issued)
    cur,     \* card id -> the gift card's currency ("none" before it is issued)
    val,     \* card id -> the gift card's value (0 before it is issued)
    bal,     \* card id -> the gift card's balance (0 before it is issued)
    spent,   \* card id -> the sum of the amounts every landed spend took (the
             \* model's own ledger of the versions an auditor reads)
    nextId,  \* the next card id the seam will supply (Capability requirement 1)
    last,    \* the last call made and what it answered (NoCall's shape)
    wrote    \* the gift cards the last step wrote

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<issued, code, cur, val, bal, spent, nextId, last, wrote>>

\* records: every variable that holds a gift card's fields.
records == <<issued, code, cur, val, bal>>

\* Carried: some gift card carries the code, compared codepoint for codepoint.
Carried(k) == \E g \in Ids : issued[g] /\ code[g] = k

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ issued \in [Ids -> BOOLEAN]
    /\ code \in [Ids -> Codes \cup {NoCode}]
    /\ cur \in [Ids -> Accepted \cup {"none"}]
    /\ val \in [Ids -> Int]
    /\ bal \in [Ids -> Int]
    /\ spent \in [Ids -> Int]
    /\ nextId \in 1..(MaxCards + 1)
    /\ last \in [op : {"none", "issue", "check", "spend", "read"},
                 card : 0..MaxCards, code : Codes \cup {NoCode}, amt : Amounts \cup {0},
                 ans : {"none", "ok", "not-known", "invalid-amount", "insufficient-balance"},
                 outCode : Codes \cup {NoCode}, outBal : Int, outCur : Accepted \cup {"none"}]
    /\ wrote \subseteq Ids

\* Init: no gift card.
Init ==
    /\ issued = [g \in Ids |-> FALSE]
    /\ code = [g \in Ids |-> NoCode]
    /\ cur = [g \in Ids |-> "none"]
    /\ val = [g \in Ids |-> 0]
    /\ bal = [g \in Ids |-> 0]
    /\ spent = [g \in Ids |-> 0]
    /\ nextId = 1
    /\ last = NoCall
    /\ wrote = {}

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Issue: an admitted [Issue] records one gift card carrying the card id and
\* the card code the seam supplies, the call's currency and value (Operation
\* 4), the value as its balance (Operation 5), and answers the card id and the
\* card code (Operation 6).
Issue(x, v, k) ==
    /\ nextId <= MaxCards
    /\ ~Carried(k)
    /\ issued' = [issued EXCEPT ![nextId] = TRUE]
    /\ code' = [code EXCEPT ![nextId] = k]
    /\ cur' = [cur EXCEPT ![nextId] = x]
    /\ val' = [val EXCEPT ![nextId] = v]
    /\ bal' = [bal EXCEPT ![nextId] = v]
    /\ nextId' = nextId + 1
    /\ last' = [NoCall EXCEPT !.op = "issue", !.card = nextId, !.ans = "ok", !.outCode = k]
    /\ wrote' = {nextId}
    /\ UNCHANGED spent

\* CheckKnown: [Check Balance] with a code a gift card carries answers its
\* balance and its currency (Operation 8) and writes nothing (Operation 9).
CheckKnown(g) ==
    /\ issued[g]
    /\ last' = [NoCall EXCEPT !.op = "check", !.card = g, !.code = code[g], !.ans = "ok",
                              !.outBal = bal[g], !.outCur = cur[g]]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, cur, val, bal, spent, nextId>>

\* CheckUnknown: [Check Balance] with a code no gift card carries answers
\* not-known (Operation 7).
CheckUnknown(k) ==
    /\ ~Carried(k)
    /\ last' = [NoCall EXCEPT !.op = "check", !.code = k, !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, cur, val, bal, spent, nextId>>

\* SpendUnknown: [Spend] with a code no gift card carries answers not-known,
\* the first refusal on its line (Operation 7, Execution Contract Refusal 1).
SpendUnknown(k, a) ==
    /\ ~Carried(k)
    /\ last' = [NoCall EXCEPT !.op = "spend", !.code = k, !.amt = a, !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, cur, val, bal, spent, nextId>>

\* SpendInvalid: [Spend] of an amount that is not a positive amount answers
\* invalid-amount and writes nothing (Operation 10).
SpendInvalid(g, a) ==
    /\ issued[g]
    /\ a < 0                                       \* BUG: zero admitted
    /\ last' = [NoCall EXCEPT !.op = "spend", !.card = g, !.code = code[g], !.amt = a,
                              !.ans = "invalid-amount"]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, cur, val, bal, spent, nextId>>

\* SpendInsufficient: [Spend] of an amount over the balance answers
\* insufficient-balance and writes nothing (Operation 11).
SpendInsufficient(g, a) ==
    /\ issued[g]
    /\ a >= 1
    /\ a > bal[g]
    /\ last' = [NoCall EXCEPT !.op = "spend", !.card = g, !.code = code[g], !.amt = a,
                              !.ans = "insufficient-balance"]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, cur, val, bal, spent, nextId>>

\* SpendLands: [Spend] of a positive amount within the balance sets the
\* balance to the balance less the amount (Operation 12) and answers the new
\* balance (Operation 13); the card code, the currency and the value stand.
SpendLands(g, a) ==
    /\ issued[g]
    /\ a >= 0
    /\ a <= bal[g]
    /\ bal' = [bal EXCEPT ![g] = bal[g] - a]
    /\ spent' = [spent EXCEPT ![g] = spent[g] + a]
    /\ last' = [NoCall EXCEPT !.op = "spend", !.card = g, !.code = code[g], !.amt = a,
                              !.ans = "ok", !.outBal = bal[g] - a]
    /\ wrote' = {g}
    /\ UNCHANGED <<issued, code, cur, val, nextId>>

\* ReadKnown: [Read] of a card id a gift card carries answers its currency,
\* value and balance, never its code (Operation 15, 16), and writes nothing
\* (Operation 17).
ReadKnown(g) ==
    /\ issued[g]
    /\ last' = [NoCall EXCEPT !.op = "read", !.card = g, !.ans = "ok",
                              !.outBal = bal[g], !.outCur = cur[g]]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, cur, val, bal, spent, nextId>>

\* ReadUnknown: [Read] of a card id no gift card carries answers not-known
\* (Operation 14).
ReadUnknown(g) ==
    /\ ~issued[g]
    /\ last' = [NoCall EXCEPT !.op = "read", !.ans = "not-known"]
    /\ wrote' = {}
    /\ UNCHANGED <<issued, code, cur, val, bal, spent, nextId>>

\* Next: any call of the four actions, admitted or refused as the page says.
Next ==
    \/ \E x \in Accepted, v \in Values, k \in Codes : Issue(x, v, k)
    \/ \E g \in Ids : CheckKnown(g)
    \/ \E k \in Codes : CheckUnknown(k)
    \/ \E k \in Codes, a \in Amounts : SpendUnknown(k, a)
    \/ \E g \in Ids, a \in Amounts : SpendInvalid(g, a)
    \/ \E g \in Ids, a \in Amounts : SpendInsufficient(g, a)
    \/ \E g \in Ids, a \in Amounts : SpendLands(g, a)
    \/ \E g \in Ids : ReadKnown(g)
    \/ \E g \in Ids : ReadUnknown(g)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv2_1_NeverRaised: no step raises the balance of an issued gift card: a
\* gift card that reaches zero is used up for good (Invariant 2.1, Check 3.2).
Inv2_1_NeverRaised ==
    [][\A g \in Ids : issued[g] => bal'[g] <= bal[g]]_vars

\* Inv3_1_CodeKept: no step changes the card code of an issued gift card, a
\* used-up one included (Invariant 3.1, Check 4.1).
Inv3_1_CodeKept ==
    [][\A g \in Ids : issued[g] => code'[g] = code[g]]_vars

\* Inv3_2_CurrencyKept: no step changes the currency of an issued gift card
\* (Invariant 3.2, Check 4.2).
Inv3_2_CurrencyKept ==
    [][\A g \in Ids : issued[g] => cur'[g] = cur[g]]_vars

\* Inv3_3_ValueKept: no step changes the value of an issued gift card: the
\* value is what it was loaded with, whatever was spent (Invariant 3.3, Check
\* 4.3).
Inv3_3_ValueKept ==
    [][\A g \in Ids : issued[g] => val'[g] = val[g]]_vars

\* Inv4_1_RefusedSpendTakesNothing: a [Spend] step that answers a refusal
\* leaves every balance as it was: an amount over the balance takes nothing,
\* not what is left (Invariant 4.1).
Inv4_1_RefusedSpendTakesNothing ==
    [][(last'.op = "spend" /\ last'.ans # "ok") => bal' = bal]_vars

\* State2_NeverRemoved: no step removes an issued gift card, a used-up one
\* included (State 2).
State2_NeverRemoved ==
    [][\A g \in Ids : issued[g] => issued'[g]]_vars

\* Balance_ValueLessSpends: every issued gift card's balance is its value less
\* the amounts of every spend that landed on it, so an auditor can read the
\* balance from the gift card's versions (Term balance; the Decisions entry of
\* 2026-10-30).
Balance_ValueLessSpends ==
    \A g \in Ids : issued[g] => bal[g] = val[g] - spent[g]

\* Op4_OneCardPerIssue: an [Issue] step that answers issued records exactly
\* one new gift card; a repeated [Issue] is a second gift card, never two
\* from one call (Operation 4, the Edge case "Indeterminate outcome").
Op4_OneCardPerIssue ==
    [][(last'.op = "issue" /\ last'.ans = "ok")
         => Cardinality({g \in Ids : issued'[g] /\ ~issued[g]}) = 1]_vars

\* Op6_IssueAnswersCode: an [Issue] that answered issued answered the card id
\* of a gift card it recorded and that gift card's card code, the only answer
\* that ever carries the code (Operation 6).
Op6_IssueAnswersCode ==
    (last.op = "issue" /\ last.ans = "ok")
        => (last.card \in Ids /\ issued[last.card] /\ last.outCode = code[last.card])

\* Op7_UnknownCodeNotKnown: a [Check Balance] or [Spend] presenting a code no
\* gift card carries answered not-known (Operation 7).
Op7_UnknownCodeNotKnown ==
    (last.op \in {"check", "spend"} /\ ~Carried(last.code))
        => last.ans = "not-known"

\* Op8_CheckAnswersBalance: a [Check Balance] that answered a gift card
\* answered its balance and its currency, not its value (Operation 8).
Op8_CheckAnswersBalance ==
    (last.op = "check" /\ last.ans = "ok" /\ last.card \in Ids)
        => (last.outBal = bal[last.card] /\ last.outCur = cur[last.card])

\* Op9_CheckBalanceWritesNothing: a [Check Balance] step writes no record and
\* changes no field of any gift card (Operation 9).
Op9_CheckBalanceWritesNothing ==
    [][last'.op = "check" => (wrote' = {} /\ UNCHANGED records)]_vars

\* Op10_NonPositiveAmountRefused: a [Spend] naming a gift card with an amount
\* that is not a positive amount answered invalid-amount (Operation 10).
Op10_NonPositiveAmountRefused ==
    (last.op = "spend" /\ last.card \in Ids /\ last.amt < 1)
        => last.ans = "invalid-amount"

\* Op12_WithinBalanceLands: a [Spend] naming a gift card with a positive amount
\* no more than its balance lands, and the balance falls by exactly the
\* amount: a spend takes exactly the amount asked, the whole balance included
\* (Operation 11, 12; the Intent's first decision).
Op12_WithinBalanceLands ==
    [][(last'.op = "spend" /\ last'.card \in Ids /\ last'.amt >= 1
            /\ last'.amt <= bal[last'.card])
         => (last'.ans = "ok" /\ bal'[last'.card] = bal[last'.card] - last'.amt)]_vars

\* Op13_SpendAnswersNewBalance: a [Spend] that landed answered the balance the
\* gift card carries after it (Operation 13).
Op13_SpendAnswersNewBalance ==
    (last.op = "spend" /\ last.ans = "ok")
        => (last.card \in Ids /\ last.outBal = bal[last.card])

\* Op16_ReadNeverAnswersCode: a [Read] answer carries no card code: the
\* seller's records never hold what spends the gift card (Operation 16).
Op16_ReadNeverAnswersCode ==
    last.op = "read" => last.outCode = NoCode

\* Op17_ReadWritesNothing: a [Read] step writes no record and changes no field
\* of any gift card (Operation 17).
Op17_ReadWritesNothing ==
    [][last'.op = "read" => (wrote' = {} /\ UNCHANGED records)]_vars

====
