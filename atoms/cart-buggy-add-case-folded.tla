---- MODULE cart-buggy-add-case-folded ----
\* DELIBERATELY WRONG twin of cart.tla (unit: `atoms/cart.md formal layer`).
\*
\* INJECTED DEFECT: [Add] compares the call's item reference with the lines' ignoring case
\* (Identity 7), so with pen on the cart add(c, "Pen", ...) answers already-in-cart
\* (Operation 8).
\*
\* BREAKS: Id7_AlreadyInCartOnlyForTheItem.
\* Everything else is cart.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    MaxCarts,    \* how many cart ids the seam supplies in the model
    MaxLines,    \* how many line ids the seam supplies in the model
    Accepted,    \* the accepted currencies (Capability requirement 3)
    Items,       \* the item references a call may carry
    Quantities,  \* the quantities a call may carry, each a positive count
    Prices,      \* the prices the shop may charge for an item, each a whole amount
    LineCap      \* the line cap (Capability requirement 7)

\* CartIds, LineIds: the ids the seam may supply, in the order it supplies them.
CartIds == 1..MaxCarts
LineIds == 1..MaxLines

\* Fold: what a case-folding normalizer makes of an item reference (pen for
\* Pen). The page forbids it (Identity 6, 7): the model's own actions never
\* apply it; it is here so a twin can.
Fold(i) == IF i = "Pen" THEN "pen" ELSE i

\* NoCall: the record of the last call before any call is made, and the shape
\* of every such record: the action, the cart and line it named, the item
\* reference it carried and what it answered. A call keeps only the fields a
\* check reads: the cart of a refused [Add] and of [Clear], the line of
\* a [Change Quantity], the item of a refused [Add].
NoCall == [op |-> "none", cart |-> 0, line |-> 0, item |-> "none", ans |-> "none"]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    opened,    \* cart id -> whether a cart carries it
    cur,       \* cart id -> the cart's currency ("none" before it is opened)
    nextCart,  \* the next cart id the seam will supply (Capability requirement 1)
    present,   \* line id -> whether the line is on its cart (FALSE once taken off)
    lcart,     \* line id -> the line's cart id (0 before it is recorded)
    litem,     \* line id -> the line's item reference ("none" before it is recorded)
    lqty,      \* line id -> the line's quantity (0 before it is recorded)
    lprice,    \* line id -> the line's unit price (0 before it is recorded)
    nextLine,  \* the next line id the seam will supply (Capability requirement 2)
    catalog,   \* item -> the shop's current price, which the composing pattern supplies
    last,      \* the last call made and what it answered (NoCall's shape)
    wrote      \* the records the last step wrote: <<"cart", id>> and <<"line", id>>

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<opened, cur, nextCart, present, lcart, litem, lqty, lprice, nextLine,
          catalog, last, wrote>>

\* records: every variable that holds a cart's or a line's fields.
records == <<opened, cur, present, lcart, litem, lqty, lprice>>

\* Recorded: a line id an admitted [Add] recorded a line under.
Recorded(l) == l < nextLine

\* LinesOf: the lines the cart carries (Term line count counts them).
LinesOf(c) == {l \in LineIds : Recorded(l) /\ present[l] /\ lcart[l] = c}

\* HasLineFor: the cart carries a line for the item reference, compared
\* codepoint for codepoint (Operation 8, Identity 7).
HasLineFor(c, i) == \E l \in LinesOf(c) : Fold(litem[l]) = Fold(i)   \* BUG: case folded

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ opened \in [CartIds -> BOOLEAN]
    /\ cur \in [CartIds -> Accepted \cup {"none"}]
    /\ nextCart \in 1..(MaxCarts + 1)
    /\ present \in [LineIds -> BOOLEAN]
    /\ lcart \in [LineIds -> 0..MaxCarts]
    /\ litem \in [LineIds -> Items \cup {"none"}]
    /\ lqty \in [LineIds -> Quantities \cup {0}]
    /\ lprice \in [LineIds -> Prices \cup {0}]
    /\ nextLine \in 1..(MaxLines + 1)
    /\ catalog \in [Items -> Prices]
    /\ last \in [op : {"none", "open", "add", "change", "remove", "clear", "read", "price"},
                 cart : 0..MaxCarts, line : 0..MaxLines, item : Items \cup {"none"},
                 ans : {"none", "ok", "already-in-cart"}]
    /\ wrote \subseteq ({"cart"} \X CartIds) \cup ({"line"} \X LineIds)

\* Init: no cart and no line; the shop's prices are any prices.
Init ==
    /\ opened = [c \in CartIds |-> FALSE]
    /\ cur = [c \in CartIds |-> "none"]
    /\ nextCart = 1
    /\ present = [l \in LineIds |-> FALSE]
    /\ lcart = [l \in LineIds |-> 0]
    /\ litem = [l \in LineIds |-> "none"]
    /\ lqty = [l \in LineIds |-> 0]
    /\ lprice = [l \in LineIds |-> 0]
    /\ nextLine = 1
    /\ catalog \in [Items -> Prices]
    /\ last = NoCall
    /\ wrote = {}

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Open: [Open] with an accepted currency (Operation 1) records one cart
\* carrying the cart id the seam supplies and the call's currency (Operation 2,
\* Operation 3) and no line.
Open(x) ==
    /\ nextCart <= MaxCarts
    /\ x \in Accepted
    /\ opened' = [opened EXCEPT ![nextCart] = TRUE]
    /\ cur' = [cur EXCEPT ![nextCart] = x]
    /\ nextCart' = nextCart + 1
    /\ last' = [NoCall EXCEPT !.op = "open", !.ans = "ok"]
    /\ wrote' = {<<"cart", nextCart>>}
    /\ UNCHANGED <<present, lcart, litem, lqty, lprice, nextLine, catalog>>

\* AddAdmitted: [Add] on a cart (Operation 4) carrying no line for the item
\* (Operation 8) and fewer lines than the line cap (Operation 24) records one
\* line carrying the line id the seam supplies and the call's cart id, item
\* reference, quantity and unit price, the price the shop charges now
\* (Operation 9, Composition note 2).
AddAdmitted(c, i, q) ==
    /\ opened[c]
    /\ ~HasLineFor(c, i)
    /\ Cardinality(LinesOf(c)) < LineCap
    /\ nextLine <= MaxLines
    /\ present' = [present EXCEPT ![nextLine] = TRUE]
    /\ lcart' = [lcart EXCEPT ![nextLine] = c]
    /\ litem' = [litem EXCEPT ![nextLine] = i]
    /\ lqty' = [lqty EXCEPT ![nextLine] = q]
    /\ lprice' = [lprice EXCEPT ![nextLine] = catalog[i]]
    /\ nextLine' = nextLine + 1
    /\ last' = [NoCall EXCEPT !.op = "add", !.ans = "ok"]
    /\ wrote' = {<<"line", nextLine>>}
    /\ UNCHANGED <<opened, cur, nextCart, catalog>>

\* AddAlready: [Add] for an item the cart already carries a line for answers
\* already-in-cart and writes nothing (Operation 8).
AddAlready(c, i) ==
    /\ opened[c]
    /\ HasLineFor(c, i)
    /\ last' = [op |-> "add", cart |-> c, line |-> 0, item |-> i, ans |-> "already-in-cart"]
    /\ wrote' = {}
    /\ UNCHANGED <<opened, cur, nextCart, present, lcart, litem, lqty, lprice, nextLine, catalog>>

\* ChangeNew: [Change Quantity] on a line its cart carries (Operation 11) with
\* a new quantity other than the line's sets the quantity (Operation 13); the
\* unit price, the cart id and the item reference stand.
ChangeNew(l, q) ==
    /\ Recorded(l) /\ present[l]
    /\ q # lqty[l]
    /\ lqty' = [lqty EXCEPT ![l] = q]
    /\ last' = [NoCall EXCEPT !.op = "change", !.line = l, !.ans = "ok"]
    /\ wrote' = {<<"line", l>>}
    /\ UNCHANGED <<opened, cur, nextCart, present, lcart, litem, lprice, nextLine, catalog>>

\* ChangeSame: [Change Quantity] with the line's own quantity answers ok and
\* writes nothing (Operation 14, Operation 15).
ChangeSame(l) ==
    /\ Recorded(l) /\ present[l]
    /\ last' = [NoCall EXCEPT !.op = "change", !.line = l, !.ans = "ok"]
    /\ wrote' = {}
    /\ UNCHANGED <<opened, cur, nextCart, present, lcart, litem, lqty, lprice, nextLine, catalog>>

\* Remove: [Remove] on a line its cart carries takes the line off its cart
\* (Operation 16); its line id is retired, since the seam never supplies it
\* again.
Remove(l) ==
    /\ Recorded(l) /\ present[l]
    /\ present' = [present EXCEPT ![l] = FALSE]
    /\ last' = [NoCall EXCEPT !.op = "remove", !.ans = "ok"]
    /\ wrote' = {<<"line", l>>}
    /\ UNCHANGED <<opened, cur, nextCart, lcart, litem, lqty, lprice, nextLine, catalog>>

\* Clear: [Clear] on a cart takes every line the cart carries off it
\* (Operation 18); the cart stays, with its currency.
Clear(c) ==
    /\ opened[c]
    /\ present' = [l \in LineIds |-> IF l \in LinesOf(c) THEN FALSE ELSE present[l]]
    /\ last' = [op |-> "clear", cart |-> c, line |-> 0, item |-> "none", ans |-> "ok"]
    /\ wrote' = {<<"line", l>> : l \in LinesOf(c)}
    /\ UNCHANGED <<opened, cur, nextCart, lcart, litem, lqty, lprice, nextLine, catalog>>

\* Read: [Read] on a cart answers it and writes nothing (Operation 21 to 23).
Read(c) ==
    /\ opened[c]
    /\ last' = [NoCall EXCEPT !.op = "read", !.ans = "ok"]
    /\ wrote' = {}
    /\ UNCHANGED <<opened, cur, nextCart, present, lcart, litem, lqty, lprice, nextLine, catalog>>

\* PriceMoves: the shop changes an item's price (the composing pattern that
\* prices the item, Non-goal 1); no record of the cart is written.
PriceMoves(i, p) ==
    /\ p # catalog[i]
    /\ catalog' = [catalog EXCEPT ![i] = p]
    /\ last' = [NoCall EXCEPT !.op = "price"]
    /\ wrote' = {}
    /\ UNCHANGED <<opened, cur, nextCart, present, lcart, litem, lqty, lprice, nextLine>>

\* Next: any admitted call, a refused [Add] for an item already in the cart,
\* a [Read], or a move of the shop's price.
Next ==
    \/ \E x \in Accepted : Open(x)
    \/ \E c \in CartIds, i \in Items, q \in Quantities : AddAdmitted(c, i, q)
    \/ \E c \in CartIds, i \in Items : AddAlready(c, i)
    \/ \E l \in LineIds, q \in Quantities : ChangeNew(l, q)
    \/ \E l \in LineIds : ChangeSame(l)
    \/ \E l \in LineIds : Remove(l)
    \/ \E c \in CartIds : Clear(c)
    \/ \E c \in CartIds : Read(c)
    \/ \E i \in Items, p \in Prices : PriceMoves(i, p)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv2_1_PriceKept: no step changes the unit price of a recorded line, while
\* the shop's price moves and the quantity changes: the price taken when the
\* line was added stands (Invariant 2.1, Check 3.1).
Inv2_1_PriceKept ==
    [][\A l \in LineIds : Recorded(l) => lprice'[l] = lprice[l]]_vars

\* Inv3_1_CartKept: no step changes the cart id of a recorded line: a line
\* never moves to another cart (Invariant 3.1, Check 3.2).
Inv3_1_CartKept ==
    [][\A l \in LineIds : Recorded(l) => lcart'[l] = lcart[l]]_vars

\* Inv3_2_ItemKept: no step changes the item reference of a recorded line
\* (Invariant 3.2, Check 3.3).
Inv3_2_ItemKept ==
    [][\A l \in LineIds : Recorded(l) => litem'[l] = litem[l]]_vars

\* Inv4_1_CurrencyKept: no step changes the currency of an opened cart
\* (Invariant 4.1, Check 3.4).
Inv4_1_CurrencyKept ==
    [][\A c \in CartIds : opened[c] => cur'[c] = cur[c]]_vars

\* State3_NeverRemovesCart: no step removes an opened cart, a cleared one or
\* one whose last line was taken off included (State 3).
State3_NeverRemovesCart ==
    [][\A c \in CartIds : opened[c] => opened'[c]]_vars

\* Id7_AlreadyInCartOnlyForTheItem: an [Add] answered already-in-cart was for
\* an item reference a line of the cart carries, the same codepoint for
\* codepoint: Pen is not refused because the cart carries pen (Identity 7,
\* Operation 8, Operation 9).
Id7_AlreadyInCartOnlyForTheItem ==
    (last.op = "add" /\ last.ans = "already-in-cart")
        => \E l \in LineIds : /\ l < nextLine
                              /\ present[l]
                              /\ lcart[l] = last.cart
                              /\ litem[l] = last.item

\* Op14_SameQuantityWritesNothing: a [Change Quantity] step that leaves the
\* line's quantity as it was writes no record (Operation 14).
Op14_SameQuantityWritesNothing ==
    [][(last'.op = "change" /\ lqty'[last'.line] = lqty[last'.line]) => wrote' = {}]_vars

\* Op18_ClearLeavesNoLine: after a [Clear], the cart carries no line
\* (Operation 18).
Op18_ClearLeavesNoLine ==
    last.op = "clear"
        => ~\E l \in LineIds : l < nextLine /\ present[l] /\ lcart[l] = last.cart

\* Op23_ReadWritesNothing: a [Read] step writes no record and changes no
\* field of any cart or line (Operation 23).
Op23_ReadWritesNothing ==
    [][last'.op = "read" => (wrote' = {} /\ UNCHANGED records)]_vars

====
