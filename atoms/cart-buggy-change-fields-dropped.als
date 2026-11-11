-- cart-buggy-change-fields-dropped.als
-- DELIBERATELY WRONG twin of cart.als (unit: `atoms/cart.md formal layer`).
--
-- INJECTED DEFECT: [Change Quantity] writes the new version with only the line id and the new
-- quantity, as a patch written as the whole record, leaving the cart id, item reference and
-- unit price blank (Operation 13).
--
-- BREAKS: A_State_2.
-- Everything else is cart.als as written; read its comments there.

module cart_buggy_change_fields_dropped

open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- CartId: an opaque cart id (Term cart id), which the host supplies at the seam on [Open].
sig CartId {}

-- LineId: an opaque line id (Term line id), which the host supplies at the seam on [Add].
sig LineId {}

-- Currency: a string a call carries as its currency, such as EUR, or eur, which the
-- atom compares codepoint for codepoint, so two different strings are two different atoms
-- (Term currency, Identity 9).
sig Currency {}

-- ItemRef: a string a call carries as its item reference, such as pen, Pen or a blank one
-- (Term item reference). Compared codepoint for codepoint (Identity 7): pen and Pen are two.
sig ItemRef {}

-- Deployment: what the deployment supplies: the accepted currencies (Capability
-- requirement 3) and the line cap (Capability requirement 7, 500 where none is declared).
one sig Deployment {
    accepted : set Currency,
    lineCap  : one Int
}

-- Strings: which item references Operation 5 refuses: the blank ones, and the ones longer
-- than the string cap (Capability requirement 6, 1,024 code points where none is declared).
one sig Strings {
    blank   : set ItemRef,
    overCap : set ItemRef
}

-- Normalizer: what a normalizer that folds case or trims would rewrite a value to, where
-- the result differs from the value (pen for Pen, EUR for eur). The page forbids it for
-- both (Identity 6, 8): the model's own actions never apply it. It is here so the runs
-- can show two references one normalizer would merge, and so a twin can apply it.
one sig Normalizer {
    foldItem : ItemRef -> lone ItemRef,
    foldCode : Currency -> lone Currency
}

-- Call: one call of a writing action ([Open], [Add], [Change Quantity], [Remove], [Clear]).
-- Calls happen in one order, the order Execution Contract Order 1 gives every commit.
abstract sig Call {}

-- OpenCall: one [Open] call, open(currency). The seam supplies it a cart id (Capability
-- requirement 1); the action allocates none.
sig OpenCall extends Call {
    curIn    : one Currency,  -- currency
    seamCart : one CartId     -- the cart id the seam supplies this call
}

-- AddCall: one [Add] call, add(cart_id, item_reference, quantity, unit_price). The seam
-- supplies it a line id (Capability requirement 2).
sig AddCall extends Call {
    addCart  : one CartId,    -- cart_id
    itemIn   : one ItemRef,   -- item_reference
    qtyIn    : one Int,       -- quantity
    priceIn  : one Int,       -- unit_price
    seamLine : one LineId     -- the line id the seam supplies this call
}

-- ChangeCall: one [Change Quantity] call, change_quantity(line_id, new_quantity).
sig ChangeCall extends Call {
    changeLine : one LineId,  -- line_id
    newQty     : one Int      -- new_quantity
}

-- RemoveCall: one [Remove] call, remove(line_id).
sig RemoveCall extends Call {
    removeLine : one LineId   -- line_id
}

-- ClearCall: one [Clear] call, clear(cart_id).
sig ClearCall extends Call {
    clearCart : one CartId    -- cart_id
}

-- Cart: one cart record (Term records), as the [Open] that wrote it left it. Every field
-- the page names may be absent, so a write that forgot one would show; what the page
-- promises (State 1) is checked, never built into the type. The last field is the
-- model's own: which call wrote the record.
sig Cart {
    cartId   : lone CartId,     -- cart id (Identity 1)
    currency : lone Currency,   -- currency
    openedBy : one OpenCall     -- the [Open] whose write left this record
}

-- Line: one version of a line record (Term records, Term version), as the call that wrote
-- it left it. Every field may be absent, as for Cart. The last two fields are the model's
-- own: which call wrote this version, and which version a [Change Quantity] found.
sig Line {
    lineId    : lone LineId,    -- line id (Identity 2)
    lineCart  : lone CartId,    -- cart id
    item      : lone ItemRef,   -- item reference
    quantity  : lone Int,       -- quantity
    unitPrice : lone Int,       -- unit price
    writtenBy : one AddCall + ChangeCall,
    found     : lone Line
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The seam supplies each [Open] a cart id no cart has carried (Capability requirement 1,
-- Execution Contract Logic confinement 3 and 16): two [Open] calls never get one id.
fact SeamSuppliesFreshCartIds {
    all disj a, b : OpenCall | a.seamCart != b.seamCart
}

-- The seam supplies each [Add] a line id no line has carried (Capability requirement 2,
-- Execution Contract Logic confinement 3 and 16): two [Add] calls never get one id.
fact SeamSuppliesFreshLineIds {
    all disj a, b : AddCall | a.seamLine != b.seamLine
}

-- The line cap the deployment declares is a count of lines, zero or more (Term line cap:
-- the most lines a cart holds; Capability requirement 7, Execution Contract Input 2).
fact LineCapIsACount {
    Deployment.lineCap >= 0
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- openWrites: the cart an admitted [Open] records: the call's currency is among the
-- accepted currencies, compared codepoint for codepoint (Operation 1, Identity 9); the
-- cart carries the cart id the seam supplies and the currency as the call carries it
-- (Operation 2, Operation 3, Identity 8).
pred openWrites[o : OpenCall, k : Cart] {
    o.curIn in Deployment.accepted                 -- Operation 1, Identity 9
    k.cartId   = o.seamCart                        -- Operation 3, Capability requirement 1
    k.currency = o.curIn                           -- Operation 2, Identity 8
}

-- recordedCart: a cart record the page lets the records hold: what an admitted [Open] wrote.
pred recordedCart[k : Cart] {
    openWrites[k.openedBy, k]
}

-- cartFound: a call finds a cart for the cart id: an admitted [Open] before the call
-- recorded one (Operation 4; no cart is removed, State 3).
pred cartFound[id : CartId, c : Call] {
    some k : Cart | recordedCart[k] and k.cartId = id and C/lt[k.openedBy, c]
}

-- first: the first version of the line this version belongs to, the one [Add] wrote.
fun first[l : Line] : set Line {
    { v : l.*found | no v.found }
}

-- adder: the [Add] call that recorded the line this version belongs to. Two versions with
-- one adder are one line; two adders are two lines.
fun adder[l : Line] : set AddCall {
    first[l].writtenBy & AddCall
}

-- takesOut: the call takes the line off its cart: a [Remove] naming its line id
-- (Operation 16) or a [Clear] of its cart (Operation 18).
pred takesOut[r : Call, l : Line] {
    (r in RemoveCall and r.removeLine in first[l].lineId)
    or (r in ClearCall and r.clearCart in first[l].lineCart)
}

-- carriedAt: the line is on its cart when call c runs: the [Add] that recorded it ran
-- before c, and no call between them took it off (Execution Contract Database 2).
pred carriedAt[l : Line, c : Call] {
    some a : adder[l] | C/lt[a, c]
        and (no r : Call | C/lt[a, r] and C/lt[r, c] and takesOut[r, l])
}

-- carriedNow: the line is on its cart in the state: no call after its [Add] took it off.
pred carriedNow[l : Line] {
    some a : adder[l] | (no r : Call | C/lt[a, r] and takesOut[r, l])
}

-- linesAt: the lines the cart with this id carries when call c runs, one per [Add] (Term
-- line count).
fun linesAt[id : CartId, c : Call] : set AddCall {
    { a : AddCall | some m : Line | a in adder[m] and id in m.lineCart and carriedAt[m, c] }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- addWrites: the line an admitted [Add] records, and the guards it passes first: the cart
-- exists (Operation 4); the item reference is not blank and not over the string cap
-- (Operation 5); the quantity is a positive count (Operation 6); the unit price is a whole
-- amount (Operation 7); no line the cart carries is for the item reference, compared
-- codepoint for codepoint (Operation 8, Identity 7); the cart holds fewer lines than the
-- line cap (Operation 24). The line carries the line id the seam supplies and the call's
-- cart id, item reference, quantity and unit price (Operation 9, Identity 6).
pred addWrites[a : AddCall, l : Line] {
    cartFound[a.addCart, a]                                        -- Operation 4
    a.itemIn not in Strings.blank + Strings.overCap                -- Operation 5
    a.qtyIn >= 1                                                   -- Operation 6
    a.priceIn >= 0                                                 -- Operation 7
    no m : Line | carriedAt[m, a] and a.addCart in m.lineCart
        and a.itemIn in m.item                                     -- Operation 8, Identity 7
    #linesAt[a.addCart, a] < Deployment.lineCap                    -- Operation 24
    l.lineId    = a.seamLine                                       -- Operation 9, Capability requirement 2
    l.lineCart  = a.addCart                                        -- Operation 9
    l.item      = a.itemIn                                         -- Operation 9, Identity 6
    l.quantity  = a.qtyIn                                          -- Operation 9
    l.unitPrice = a.priceIn                                        -- Operation 9
}

-- changeWrites: the version an admitted [Change Quantity] records over the version it
-- found: the call names a line its cart carries (Operation 11), the new quantity is a
-- positive count (Operation 12) and differs from the line's (Operation 13; where it is
-- equal the call writes nothing, Operation 14, so no version follows). The version carries
-- the new quantity; a call writes only the fields its own rules name, so the line id, the
-- cart id, the item reference and the unit price stay as found.
pred changeWrites[pre : Line, ch : ChangeCall, l : Line] {
    ch.changeLine in pre.lineId                                    -- Operation 11
    carriedAt[pre, ch]                                             -- Operation 11
    ch.newQty >= 1                                                 -- Operation 12
    ch.newQty != pre.quantity                                      -- Operation 13, Operation 14
    l.lineId    = pre.lineId
    no l.lineCart and no l.item and no l.unitPrice                 -- BUG: only the patch written
    l.quantity  = ch.newQty                                        -- Operation 13
}

-- written: the version is what its call's write left: an [Add] writes a first version; a
-- [Change Quantity] writes over a version an earlier call wrote (a call finds only what was
-- committed before it, Execution Contract Database 2).
pred written[v : Line] {
    let c = v.writtenBy {
        (c in AddCall and no v.found and addWrites[c, v])
        or (c in ChangeCall and some v.found
            and C/lt[v.found.writtenBy, c] and changeWrites[v.found, c, v])
    }
}

-- recorded: a line version the page lets the records hold (see SCOPE): it and every
-- version it was built from are what an admitted call wrote.
pred recorded[l : Line] {
    all v : l.*found | written[v]
}

-- carriedLines: the lines a cart carries in the state, one per [Add] (Term line count).
fun carriedLines[k : Cart] : set AddCall {
    { a : AddCall | some l : Line | recorded[l] and a in adder[l]
        and some (k.cartId & l.lineCart) and carriedNow[l] }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every cart carries its cart id and its currency (State 1, Check 1.1).
assert A_State_1 {
    all k : Cart | recordedCart[k] implies {
        some k.cartId
        some k.currency
    }
}
check A_State_1 for 4 but 5 Call, 4 Line, 4 Int

-- A_State_2: every version of every line carries its line id, cart id, item reference,
-- quantity and unit price, however often its quantity changed (State 2, Check 1.2).
assert A_State_2 {
    all l : Line | recorded[l] implies {
        some l.lineId
        some l.lineCart
        some l.item
        some l.quantity
        some l.unitPrice
    }
}
check A_State_2 for 4 but 5 Call, 4 Line, 4 Int

-- A_Identity_3: no two carts share a cart id: two carts two [Open] calls recorded never
-- carry one id, so a cart id names one cart (Identity 3, Check 2.1).
assert A_Identity_3 {
    all k1, k2 : Cart | (recordedCart[k1] and recordedCart[k2] and k1.openedBy != k2.openedBy)
        implies no (k1.cartId & k2.cartId)
}
check A_Identity_3 for 4 but 5 Call, 4 Line, 4 Int

-- A_Identity_4: no two lines share a line id, among the lines a cart carries and the
-- versions of lines taken off, which the database keeps (Execution Contract Database 5):
-- an item taken out and added again is a new line with a new line id (Identity 4,
-- Identity 5, Check 2.2).
assert A_Identity_4 {
    all l1, l2 : Line | (recorded[l1] and recorded[l2] and adder[l1] != adder[l2])
        implies no (l1.lineId & l2.lineId)
}
check A_Identity_4 for 4 but 5 Call, 4 Line, 4 Int

-- A_Identity_6: every line carries its item reference as the [Add] that recorded it
-- carried it: Pen stays Pen, never rewritten into pen (Identity 6, Term item reference).
assert A_Identity_6 {
    all l : Line | recorded[l] implies l.item in adder[l].itemIn
}
check A_Identity_6 for 4 but 5 Call, 4 Line, 4 Int

-- A_Identity_8: every cart carries its currency as the [Open] that recorded it carried it
-- (Identity 8).
assert A_Identity_8 {
    all k : Cart | recordedCart[k] implies k.currency in k.openedBy.curIn
}
check A_Identity_8 for 4 but 5 Call, 4 Line, 4 Int

-- A_Invariant_1_1: two lines one cart carries never share an item reference, so how many
-- of an item a cart holds is one quantity on one line (Invariant 1.1, Check 2.3).
assert A_Invariant_1_1 {
    all l1, l2 : Line | (recorded[l1] and recorded[l2] and adder[l1] != adder[l2]
                         and carriedNow[l1] and carriedNow[l2])
        implies no (l1.lineCart & l2.lineCart) or no (l1.item & l2.item)
}
check A_Invariant_1_1 for 4 but 5 Call, 4 Line, 4 Int

-- A_Invariant_5_1: every line's cart id names a cart, the lines taken off included
-- (Invariant 5.1, Check 2.4).
assert A_Invariant_5_1 {
    all l : Line | recorded[l] implies
        (all id : l.lineCart | some k : Cart | recordedCart[k] and k.cartId = id)
}
check A_Invariant_5_1 for 4 but 5 Call, 4 Line, 4 Int

-- A_Invariant_6_1: every line carries a positive count as its quantity, as [Add] set it or
-- as [Change Quantity] last set it (Invariant 6.1, Check 4.1).
assert A_Invariant_6_1 {
    all l : Line | recorded[l] implies (all q : l.quantity | q >= 1)
}
check A_Invariant_6_1 for 4 but 5 Call, 4 Line, 4 Int

-- A_Invariant_6_2: every line carries a whole amount, zero or more, as its unit price
-- (Invariant 6.2, Check 4.2).
assert A_Invariant_6_2 {
    all l : Line | recorded[l] implies (all p : l.unitPrice | p >= 0)
}
check A_Invariant_6_2 for 4 but 5 Call, 4 Line, 4 Int

-- A_Operation_1: every cart carries a currency among the accepted currencies, matched
-- codepoint for codepoint, so eur is no cart's currency where only EUR is accepted
-- (Operation 1, Identity 9). It holds against the accepted currencies the cart was opened
-- under: see NOT MODELED HERE.
assert A_Operation_1 {
    all k : Cart | recordedCart[k] implies k.currency in Deployment.accepted
}
check A_Operation_1 for 4 but 5 Call, 4 Line, 4 Int

-- A_Operation_5: no line carries a blank item reference or one longer than the string cap
-- (Operation 5).
assert A_Operation_5 {
    all l : Line | recorded[l] implies no (l.item & (Strings.blank + Strings.overCap))
}
check A_Operation_5 for 4 but 5 Call, 4 Line, 4 Int

-- A_Operation_24: no cart carries more lines than the line cap (Operation 24, Term line
-- cap: the most lines a cart holds).
assert A_Operation_24 {
    all k : Cart | recordedCart[k] implies #carriedLines[k] <= Deployment.lineCap
}
check A_Operation_24 for 4 but 5 Call, 4 Line, 4 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowEmptyCart: a cart just opened, carrying no line, as open("EUR") answers c1.
run ShowEmptyCart {
    some k : Cart | recordedCart[k] and no carriedLines[k]
} for 4 but 5 Call, 4 Line, 4 Int

-- ShowTwoLines: a cart carrying two lines for two items, as c1 carries the T-shirts and
-- the mug.
run ShowTwoLines {
    some k : Cart | recordedCart[k] and #carriedLines[k] = 2
} for 4 but 5 Call, 4 Line, 4 Int

-- ShowTwoCurrencies: two carts in two currencies, as a café's USD tab beside a shop's
-- EUR cart.
run ShowTwoCurrencies {
    some k1, k2 : Cart | recordedCart[k1] and recordedCart[k2] and k1.currency != k2.currency
} for 4 but 5 Call, 4 Line, 4 Int

-- ShowQuantityChanged: a line whose quantity [Change Quantity] set, its unit price kept,
-- as change_quantity(l1, 3).
run ShowQuantityChanged {
    some l : Line | recorded[l] and carriedNow[l] and l.writtenBy in ChangeCall
} for 4 but 5 Call, 4 Line, 4 Int

-- ShowFreeSample: a line carried at a unit price of zero, as the free sample kit.
run ShowFreeSample {
    some l : Line | recorded[l] and carriedNow[l] and (some p : l.unitPrice | p = 0)
} for 4 but 5 Call, 4 Line, 4 Int

-- ShowReAdded: an item taken out and added again to one cart: two lines with two line
-- ids, the first taken off and kept as a version, the second carried (the Edge case "A
-- price that moves after the add").
run ShowReAdded {
    some l1, l2 : Line | recorded[l1] and recorded[l2] and adder[l1] != adder[l2]
        and l1.lineCart = l2.lineCart and l1.item = l2.item
        and not carriedNow[l1] and carriedNow[l2]
} for 4 but 5 Call, 4 Line, 4 Int

-- ShowCleared: a cart [Clear] emptied: a line it carried taken off by the clear, the cart
-- still recorded, as clear(c1).
run ShowCleared {
    some r : ClearCall, l : Line | recorded[l] and takesOut[r, l]
        and (some a : adder[l] | C/lt[a, r])
        and (some k : Cart | recordedCart[k] and k.cartId = r.clearCart and no carriedLines[k])
} for 4 but 5 Call, 4 Line, 4 Int

-- ShowCaseVariants: one cart carrying Pen and pen, two item references a normalizer would
-- merge, as two lines (the rejection paths' add(c9, "Pen", 1, 500)).
run ShowCaseVariants {
    some l1, l2 : Line | recorded[l1] and recorded[l2] and carriedNow[l1] and carriedNow[l2]
        and l1.lineCart = l2.lineCart and l2.item = l1.item.(Normalizer.foldItem)
} for 4 but 5 Call, 4 Line, 4 Int

-- ShowCartFull: a cart carrying as many lines as the line cap allows, where the next
-- [Add] answers cart-full.
run ShowCartFull {
    some k : Cart | recordedCart[k] and Deployment.lineCap >= 1
        and #carriedLines[k] = Deployment.lineCap
} for 4 but 5 Call, 4 Line, 4 Int
