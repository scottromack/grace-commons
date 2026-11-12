-- shared-cart-buggy-unshare-not-active-ok.als
-- DELIBERATELY WRONG twin of shared-cart.als (unit: `compositions/shared-cart.md formal layer`).
--
-- INJECTED DEFECT: an unshare whose revoke answers not-active answers ok (Action wiring 24;
-- Composes 11).
--
-- BREAKS: A_Action_wiring_24.
-- Everything else is shared-cart.als as written; read its comments there.

module shared_cart_buggy_unshare_not_active_ok

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Ref: an actor reference or a friend reference, the opaque reference a call carries for a
-- person (Term actor reference, Term friend reference). The composition never authenticates
-- it (Non-goal 1); a blank one is in World.blank.
sig Ref {}

-- CartId: a cart id, Cart's opaque name for one cart. A cart id no cart carries (`c404` in the
-- Rejection paths) is a CartId that Cart's open never answered.
sig CartId {}

-- LineId: a line id, Cart's opaque name for one line, never reused (Cart Identity 4).
sig LineId {}

-- Item: an item reference, the value naming what a line is for; the composition reads
-- nothing in it.
sig Item {}

-- Qty: a quantity a call carries. Cart decides whether it is a positive count (Cart
-- Operation 6, 12); here only whether two quantities are the same matters.
sig Qty {}

-- Price: a unit price an [Add Line] call carries; the composition never checks it (Non-goal 3).
sig Price {}

-- Currency: a currency an [Open Cart] call carries.
sig Currency {}

-- Verb: a cart verb a scope carries, or a verb outside the cart verbs that a [Share Cart]
-- caller may send (`own` in the Rejection paths).
abstract sig Verb {}

-- ViewV, AddV, ChangeV, RemoveV, ShareV: the five cart verbs (Term cart verbs).
one sig ViewV, AddV, ChangeV, RemoveV, ShareV extends Verb {}

-- OwnV: a verb no cart verb equals, such as `own`.
one sig OwnV extends Verb {}

-- Query: the query a view or a history passes to Event Log's read: the whole-log query (a
-- sequence number range with no upper end, Term whole-log query) or a range with an upper end.
abstract sig Query {}

-- WholeLog, Bounded: the two kinds of query.
one sig WholeLog, Bounded extends Query {}

-- ReadKind: a constituent read a call made: Cart's read, Permissions' read, Event Log's read.
abstract sig ReadKind {}

-- CartRead, PermRead, LogRead: the three reads.
one sig CartRead, PermRead, LogRead extends ReadKind {}

-- Permit: what Permissions' permitted answered: permitted or denied.
abstract sig Permit {}

-- Permitted, Denied: the two answers of permitted.
one sig Permitted, Denied extends Permit {}

-- Act: the act's name a cart event carries (Term cart event), one per changing action.
abstract sig Act {}

-- OpenA ... ClearA: open_cart, share_cart, unshare_cart, add_line, change_quantity,
-- remove_line, clear_cart.
one sig OpenA, ShareA, UnshareA, AddA, ChangeA, RemoveA, ClearA extends Act {}

-- Answer: what a call, or a constituent call, answered: ok, an id, a shared cart, cart
-- events, or a refusal code. A refusal code means the same thing whichever pattern answered
-- it, so a constituent's refusal answered unchanged is the same atom (Composes 11).
abstract sig Answer {}

-- AOk, AId, AShared, AEvents: the four non-refusal answers (ok; a cart, grant or line id;
-- a shared cart; cart events).
one sig AOk, AId, AShared, AEvents extends Answer {}

-- The refusal codes the page and its constituents declare.
one sig PermissionDenied, InvalidRequest, NotKnown, NotActive, InvalidCurrency, InvalidItemRef,
    InvalidQuantity, InvalidPrice, AlreadyInCart, CartFull extends Answer {}

-- World: what the world holds beside the records: which references are blank, which
-- currencies the deployment accepts, the unit prices a pricing pattern would take as right
-- (which the composition never asks: Non-goal 3), and three transformations the page forbids
-- the composition, which the correct model never applies and a twin may: a default currency
-- put in place of the caller's, a case folding of an item reference, and a quantity read as
-- an increment on the line's own.
one sig World {
    blank    : set Ref,
    accepted : set Currency,
    okPrice  : set Price,
    fallback : one Currency,
    fold     : Item -> one Item,
    plus     : Qty -> Qty -> one Qty
}

-- Store: the carts Cart's records carry. Cart never removes a cart (Cart State 3).
one sig Store {
    carts : set CartId
}

-- Grant: one grant of Permissions' records; the atom stands for its grant id. Its scope is
-- held as the cart it names and the verb it carries (see the header); a scope that is not a
-- cart scope names no cart or carries no cart verb, so a grant written wrong would show.
sig Grant {
    subject : one Ref,       -- subject reference
    scart   : lone CartId,   -- the cart its action scope names
    sverb   : lone Verb      -- the verb its action scope carries
}

-- Line: one line Cart's records carry now: its line id, its cart and its item reference.
-- A line taken out is no longer one.
sig Line {
    lid   : one LineId,
    lcart : one CartId,
    litem : one Item
}

-- Event: one event of Event Log's records, holding a cart event: the fields the act's row
-- names (Term cart event). `eitem` is there so that an event carrying an item reference,
-- which the page forbids, would show.
sig Event {
    act     : one Act,        -- act
    ecart   : lone CartId,    -- cart_id
    eactor  : lone Ref,       -- actor_ref
    efriend : lone Ref,       -- friend_ref
    everb   : lone Verb,      -- cart_verb
    egrant  : lone Grant,     -- grant_id
    eline   : lone LineId,    -- line_id
    eqty    : lone Qty,       -- new_quantity
    eitem   : lone Item       -- an item reference (never, by the page)
}

-- Call: one call of the composition: the instant it ran at, the actor reference it carried,
-- the constituent reads it made, the events it appended to Event Log, and what it answered.
abstract sig Call {
    at       : one Int,
    actor    : one Ref,
    reads    : set ReadKind,
    appended : set Event,
    ans      : one Answer
}

-- OpenCart: an [Open Cart] call: the currency, the currency it passed to Cart's open and how
-- that came back, the cart id Cart's open answered, the grants Permissions' grant recorded for
-- it, and the cart id it answered.
sig OpenCart extends Call {
    currency : one Currency,
    openCur  : lone Currency,
    openOut  : lone Answer,
    opened   : lone CartId,
    made     : set Grant,
    ansCart  : lone CartId
}

-- Gated: a gated action's call (Term gated action): the cart id it names, and the permitted
-- check it asked: the subject reference, the cart and the verb of the scope, and the answer.
abstract sig Gated extends Call {
    cartIn  : one CartId,
    askRef  : lone Ref,
    askCart : lone CartId,
    askVerb : lone Verb,
    permit  : lone Permit
}

-- ShareCart: a [Share Cart] call: the friend reference and the cart verb, the grant
-- Permissions' grant recorded, and the grant id it answered.
sig ShareCart extends Gated {
    friend   : one Ref,
    verbIn   : one Verb,
    granted  : lone Grant,
    ansGrant : lone Grant
}

-- UnshareCart: an [Unshare Cart] call: the grant id it was given (none: an id naming no grant
-- at all, `g99`), Permissions' read answer, the grants it called revoke on and how that came
-- back.
sig UnshareCart extends Gated {
    grantIn   : lone Grant,
    permRead  : set Grant,
    revCalled : set Grant,
    revOut    : lone Answer
}

-- AddLine: an [Add Line] call: the item reference, quantity and unit price, the arguments it
-- passed to Cart's add, how that came back, the line id Cart's add answered, and the line id
-- it answered.
sig AddLine extends Gated {
    item     : one Item,
    qty      : one Qty,
    price    : one Price,
    addCart  : lone CartId,
    addItem  : lone Item,
    addQty   : lone Qty,
    addPrice : lone Price,
    addOut   : lone Answer,
    added    : lone LineId,
    ansLine  : lone LineId
}

-- ChangeQuantity: a [Change Quantity] call: the line id and the new quantity, the lines Cart's
-- read answered for the cart and the quantity it showed for the line, the arguments passed to
-- Cart's change_quantity, and how that came back.
sig ChangeQuantity extends Gated {
    lineIn  : one LineId,
    newQty  : one Qty,
    chRead  : set LineId,
    seenQty : lone Qty,
    chLine  : lone LineId,
    chQty   : lone Qty,
    chOut   : lone Answer
}

-- RemoveLine: a [Remove Line] call: the line id, the lines Cart's read answered for the cart,
-- the line id passed to Cart's remove, and how that came back.
sig RemoveLine extends Gated {
    rmIn   : one LineId,
    rmRead : set LineId,
    rmLine : lone LineId,
    rmOut  : lone Answer
}

-- ClearCart: a [Clear Cart] call: the cart id passed to Cart's clear and how that came back.
sig ClearCart extends Gated {
    clCart : lone CartId,
    clOut  : lone Answer
}

-- ViewCart: a [View Cart] call: the query it passed to Event Log's read and the events that
-- answered, the lines Cart's read answered, and the shared cart it answered: the lines shown
-- and the adder beside each.
sig ViewCart extends Gated {
    vQuery : lone Query,
    vLog   : set Event,
    vRead  : set LineId,
    shown  : set LineId,
    adder  : LineId -> Ref
}

-- CartHistory: a [Cart History] call: the query it passed to Event Log's read, the events that
-- answered, and the cart events it answered.
sig CartHistory extends Gated {
    hQuery : lone Query,
    hLog   : set Event,
    hist   : set Event
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- CartVerb: the five cart verbs (Term cart verbs).
fun CartVerb : set Verb { ViewV + AddV + ChangeV + RemoveV + ShareV }

-- Refusal: every refusal code.
fun Refusal : set Answer { Answer - AOk - AId - AShared - AEvents }

-- Changing: the calls of a changing action (Term changing action).
fun Changing : set Call {
    OpenCart + ShareCart + UnshareCart + AddLine + ChangeQuantity + RemoveLine + ClearCart
}

-- madeAt: a grant's grant instant: the instant of the call whose grant recorded it.
fun madeAt[g : Grant] : set Int { (made.g + granted.g).at }

-- revokedBefore: a grant some earlier unshare's revoke stood in revoked.
pred revokedBefore[g : Grant, t : Int] {
    some u : UnshareCart | g in u.revCalled and u.revOut = AOk and u.at < t
}

-- activeAt: a grant recorded before instant t and not revoked by then: active at t.
pred activeAt[g : Grant, t : Int] {
    some madeAt[g]
    all m : madeAt[g] | m < t
    not revokedBefore[g, t]
}

-- addedTo: the line ids Cart's add answered for one cart.
fun addedTo[c : CartId] : set LineId { { a : AddLine | a.addCart = c }.added }

-- cartGrants: the grants of a set that are grants of the cart (Term grant of the cart): their
-- action scope is one of the cart's verb scopes.
fun cartGrants[gs : set Grant, c : CartId] : set Grant {
    { g : gs | g.scart = c and g.sverb in CartVerb }
}

-- addEvents: the add events among some events that carry a line id (Term add event).
fun addEvents[es : set Event, l : LineId] : set Event {
    { e : es | e.act = AddA and e.eline = l }
}

-- earlier: the events appended by the calls that ran before instant t.
fun earlier[t : Int] : set Event { { e : Event | appended.e.at < t } }

-- outs: how the call's write-making constituent calls came back.
fun outs[c : Call] : set Answer {
    c.openOut + c.revOut + c.addOut + c.chOut + c.rmOut + c.clOut
}

-- gateVerb: the cart verb whose scope gates the action (Scope vocabulary 3 to 7).
fun gateVerb[c : Gated] : Verb {
    c in ShareCart + UnshareCart => ShareV else
    c in AddLine => AddV else
    c in ChangeQuantity => ChangeV else
    c in RemoveLine + ClearCart => RemoveV else
    ViewV
}

-- evt: an event holds exactly these fields of a cart event and no item reference (Term cart
-- event); `none` stands for a field the act's row does not name.
pred evt[e : Event, a : Act, c : set CartId, who : set Ref, fr : set Ref, vb : set Verb,
         gr : set Grant, ln : set LineId, q : set Qty] {
    e.act = a
    e.ecart = c
    e.eactor = who
    e.efriend = fr
    e.everb = vb
    e.egrant = gr
    e.eline = ln
    e.eqty = q
    no e.eitem
}

-- noCall: the call made no constituent call but permitted: no read, no write, no append.
pred noCall[c : Call] {
    no c.reads
    no c.appended
    no c.openCur
    no c.made
    no c.granted
    no c.revCalled
    no c.addCart
    no c.chLine
    no c.rmLine
    no c.clCart
}

-- noAnswer: the call answered no id, no line and no event.
pred noAnswer[c : Call] {
    no c.ansCart
    no c.ansGrant
    no c.ansLine
    no c.shown
    no c.adder
    no c.hist
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The calls run one at a time (Execution Contract Database 2), so no two run at one instant;
-- instants count up from zero.
fact CallsSerialized {
    all c : Call | c.at >= 0
    all disj c, d : Call | c.at != d.at
}

-- The constituent instances serve this composition alone and their own caller surface is
-- replaced (Composes 5, 12, the deployment's wiring): every grant was recorded by one of the
-- composition's grant calls, every event appended by one of its calls, every line recorded by
-- one of its Cart add calls, and every cart opened by one of its Cart open calls, which Cart
-- never removes (Cart State 3).
fact RecordsAreTheCompositionsCalls {
    all g : Grant | one (made.g + granted.g)
    all e : Event | one appended.e
    all l : Line | one a : AddLine |
        a.added = l.lid and a.addOut = AOk and l.lcart = a.addCart and l.litem = a.addItem
    all disj l1, l2 : Line | l1.lid != l2.lid
    Store.carts = OpenCart.opened
}

-- Cart's calls, as Cart's page states them: open refuses a currency the deployment does not
-- accept and otherwise answers a cart id no cart has carried (Cart Operation 1 to 3, Identity
-- 3); add answers a line id no line has carried or one of its declared refusals (Operation 9,
-- 10, Identity 4); change_quantity, remove and clear answer ok or a declared refusal; a read
-- answers only lines added to the cart (Operation 21), with the quantity of a line it answers.
fact CartAnswers {
    all o : OpenCart {
        some o.openCur iff some o.openOut
        o.openOut in AOk + InvalidCurrency
        some o.openCur implies (o.openOut = InvalidCurrency iff o.openCur not in World.accepted)
        o.openOut = AOk iff some o.opened
    }
    all disj o1, o2 : OpenCart | no (o1.opened & o2.opened)
    all a : AddLine {
        some a.addCart iff some a.addOut
        a.addOut in AOk + InvalidItemRef + InvalidQuantity + InvalidPrice + AlreadyInCart
            + CartFull + NotKnown
        a.addOut = AOk iff some a.added
    }
    all disj a1, a2 : AddLine | no (a1.added & a2.added)
    all c : ChangeQuantity {
        some c.chLine iff some c.chOut
        c.chOut in AOk + InvalidQuantity + NotKnown
        CartRead not in c.reads implies no c.chRead
        c.chRead in addedTo[c.cartIn]
        some c.seenQty iff (CartRead in c.reads and c.lineIn in c.chRead)
    }
    all r : RemoveLine {
        some r.rmLine iff some r.rmOut
        r.rmOut in AOk + NotKnown
        CartRead not in r.reads implies no r.rmRead
        r.rmRead in addedTo[r.cartIn]
    }
    all c : ClearCart {
        some c.clCart iff some c.clOut
        c.clOut in AOk + NotKnown
    }
    all v : ViewCart {
        CartRead not in v.reads implies no v.vRead
        v.vRead in addedTo[v.cartIn]
    }
}

-- Permissions' calls, as its page states them: permitted answers permitted exactly when a
-- grant active at the call's instant matches the subject reference and the action scope
-- exactly (Operation 16 to 18, 21, 22); read answers every grant recorded so far (Operation
-- 26); revoke answers not-active for a grant already revoked and otherwise stands it in
-- revoked (Operation 10, 11).
fact PermissionsAnswers {
    all c : Gated {
        some c.askRef iff some c.permit
        some c.askRef iff some c.askCart
        some c.askRef iff some c.askVerb
        some c.permit implies (c.permit = Permitted iff
            (some g : Grant | g.subject = c.askRef and g.scart = c.askCart
                and g.sverb = c.askVerb and activeAt[g, c.at]))
    }
    all u : UnshareCart {
        PermRead in u.reads implies u.permRead = { g : Grant | all m : madeAt[g] | m < u.at }
            else no u.permRead
        some u.revCalled iff some u.revOut
        u.revOut in AOk + NotActive
        some u.revCalled implies
            (u.revOut = NotActive iff (some g : u.revCalled | revokedBefore[g, u.at]))
    }
}

-- Event Log's read, as its page states it: the whole-log query answers every event appended
-- before the read; a range with an upper end answers some of them (Event Log Operation 16,
-- Execution Contract Query 1 to 4). No read, no events.
fact EventLogReads {
    all v : ViewCart {
        some v.vQuery iff LogRead in v.reads
        v.vQuery = WholeLog implies v.vLog = earlier[v.at]
        v.vQuery = Bounded implies v.vLog in earlier[v.at]
        no v.vQuery implies no v.vLog
    }
    all h : CartHistory {
        some h.hQuery iff LogRead in h.reads
        h.hQuery = WholeLog implies h.hLog = earlier[h.at]
        h.hQuery = Bounded implies h.hLog in earlier[h.at]
        no h.hQuery implies no h.hLog
    }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The composition's wiring of each call
-- ─────────────────────────────────────────────────────────────────────────────

-- asks: a gated call asks Permissions' permitted with its actor reference and the cart's
-- verb scope for the action's verb (Action wiring 4, Scope vocabulary 3 to 7).
pred asks[c : Gated] {
    c.askRef = c.actor
    c.askCart = c.cartIn
    c.askVerb = gateVerb[c]
}

-- denied: a call whose permitted answered denied answers permission-denied, calls nothing
-- and answers nothing else (Action wiring 2, 3).
pred denied[c : Gated] {
    c.ans = PermissionDenied
    noCall[c]
    noAnswer[c]
}

-- wiredOpen: [Open Cart]. A blank actor reference answers invalid-request before any call
-- (Action wiring 5). Otherwise Cart's open is called with the currency (Action wiring 6); its
-- refusal is answered (Action wiring 24); its cart id is answered (Action wiring 8) after one
-- grant per verb scope of the new cart to the opener (Action wiring 7) and one open event
-- (Action wiring 22).
pred wiredOpen[o : OpenCart] {
    o.actor in World.blank implies {
        o.ans = InvalidRequest
        noCall[o]
        noAnswer[o]
    } else {
        no o.reads
        o.openCur = o.currency
        o.openOut = InvalidCurrency implies {
            o.ans = InvalidCurrency
            no o.made
            no o.appended
            noAnswer[o]
        } else {
            all v : CartVerb | one g : o.made | g.sverb = v
            all g : o.made | g.subject = o.actor and g.scart = o.opened and g.sverb in CartVerb
            o.ans = AId
            o.ansCart = o.opened
            one o.appended
            evt[o.appended, OpenA, o.opened, o.actor, none, none, none, none, none]
        }
    }
}

-- wiredShare: [Share Cart], gated on the share scope. A verb outside the cart verbs or a blank
-- friend reference answers invalid-request, behind permission-denied (Action wiring 9, 10).
-- Otherwise Permissions' grant is called with the friend and the cart's verb scope for the
-- verb (Action wiring 11), its grant id answered (Action wiring 12), and the share event
-- appended.
pred wiredShare[s : ShareCart] {
    asks[s]
    s.permit = Denied implies denied[s] else {
        no s.reads
        (s.verbIn not in CartVerb or s.friend in World.blank) implies {
            s.ans = InvalidRequest
            no s.granted
            no s.appended
            noAnswer[s]
        } else {
            one s.granted
            s.granted.subject = s.friend
            s.granted.scart = s.cartIn
            s.granted.sverb = s.verbIn
            s.ans = AId
            s.ansGrant = s.granted
            one s.appended
            evt[s.appended, ShareA, s.cartIn, s.actor, s.friend, s.verbIn, s.granted, none, none]
        }
    }
}

-- wiredUnshare: [Unshare Cart], gated on the share scope. Permissions' read is asked; a grant
-- id naming no grant of the cart answers not-known (Action wiring 13); otherwise revoke is
-- called with the grant id (Action wiring 14), its not-active answered unchanged (Action
-- wiring 24), and an ok answered with the unshare event (Action wiring 22, 30).
pred wiredUnshare[u : UnshareCart] {
    asks[u]
    u.permit = Denied implies denied[u] else {
        u.reads = PermRead
        noAnswer[u]
        u.grantIn not in cartGrants[u.permRead, u.cartIn] implies {
            u.ans = NotKnown
            no u.revCalled
            no u.appended
        } else {
            u.revCalled = u.grantIn
            u.revOut = AOk implies {
                u.ans = AOk
                one u.appended
                evt[u.appended, UnshareA, u.cartIn, u.actor, none, none, u.grantIn, none, none]
            } else {
                u.ans = AOk   -- BUG: not-active answered as ok
                no u.appended
            }
        }
    }
}

-- wiredAdd: [Add Line], gated on the add scope. Cart's add is called with the cart id, the
-- item reference, the quantity and the unit price (Action wiring 15); its refusal is answered
-- (Action wiring 24); its line id is answered (Action wiring 16) with the add event.
pred wiredAdd[a : AddLine] {
    asks[a]
    a.permit = Denied implies denied[a] else {
        no a.reads
        a.addCart = a.cartIn
        a.addItem = a.item
        a.addQty = a.qty
        a.addPrice = a.price
        a.addOut = AOk implies {
            a.ans = AId
            a.ansLine = a.added
            one a.appended
            evt[a.appended, AddA, a.cartIn, a.actor, none, none, none, a.added, none]
        } else {
            a.ans = a.addOut
            no a.appended
            noAnswer[a]
        }
    }
}

-- wiredChange: [Change Quantity], gated on the change scope. Cart's read is asked; a line the
-- cart does not carry answers not-known (Action wiring 17); otherwise Cart's change_quantity
-- is called with the line id and the new quantity (Action wiring 18), its refusal answered,
-- and its ok answered with the change event, even when the quantity is the line's own
-- (Wiring decision 2).
pred wiredChange[c : ChangeQuantity] {
    asks[c]
    c.permit = Denied implies denied[c] else {
        c.reads = CartRead
        noAnswer[c]
        c.lineIn not in c.chRead implies {
            c.ans = NotKnown
            no c.chLine
            no c.appended
        } else {
            c.chLine = c.lineIn
            c.chQty = c.newQty
            c.chOut = AOk implies {
                c.ans = AOk
                one c.appended
                evt[c.appended, ChangeA, c.cartIn, c.actor, none, none, none, c.lineIn, c.newQty]
            } else {
                c.ans = c.chOut
                no c.appended
            }
        }
    }
}

-- wiredRemove: [Remove Line], gated on the remove scope. Cart's read is asked; a line the cart
-- does not carry answers not-known (Action wiring 19); otherwise Cart's remove is called with
-- the line id (Action wiring 20) and its ok answered with the remove event.
pred wiredRemove[r : RemoveLine] {
    asks[r]
    r.permit = Denied implies denied[r] else {
        r.reads = CartRead
        noAnswer[r]
        r.rmIn not in r.rmRead implies {
            r.ans = NotKnown
            no r.rmLine
            no r.appended
        } else {
            r.rmLine = r.rmIn
            r.rmOut = AOk implies {
                r.ans = AOk
                one r.appended
                evt[r.appended, RemoveA, r.cartIn, r.actor, none, none, none, r.rmIn, none]
            } else {
                r.ans = r.rmOut
                no r.appended
            }
        }
    }
}

-- wiredClear: [Clear Cart], gated on the remove scope. Cart's clear is called with the cart
-- id (Action wiring 21) and its ok answered with the clear event.
pred wiredClear[c : ClearCart] {
    asks[c]
    c.permit = Denied implies denied[c] else {
        no c.reads
        noAnswer[c]
        c.clCart = c.cartIn
        c.clOut = AOk implies {
            c.ans = AOk
            one c.appended
            evt[c.appended, ClearA, c.cartIn, c.actor, none, none, none, none, none]
        } else {
            c.ans = c.clOut
            no c.appended
        }
    }
}

-- wiredView: [View Cart], gated on the view scope. Cart's read and Event Log's read with the
-- whole-log query (Action wiring 27); the answer is Cart's read answer with each line's adder,
-- the actor reference of the line's add event (Action wiring 25, Composition state 2). It
-- appends nothing.
pred wiredView[v : ViewCart] {
    asks[v]
    v.permit = Denied implies denied[v] else {
        v.reads = CartRead + LogRead
        v.vQuery = WholeLog
        v.ans = AShared
        v.shown = v.vRead
        v.adder = { l : LineId, r : Ref | l in v.shown and r in addEvents[v.vLog, l].eactor }
        no v.appended
    }
}

-- wiredHistory: [Cart History], gated on the view scope. Event Log's read with the whole-log
-- query (Action wiring 27); the answer is the events carrying the cart's id (Action wiring
-- 26). It appends nothing.
pred wiredHistory[h : CartHistory] {
    asks[h]
    h.permit = Denied implies denied[h] else {
        h.reads = LogRead
        h.hQuery = WholeLog
        h.ans = AEvents
        h.hist = { e : h.hLog | e.ecart = h.cartIn }
        no h.appended
    }
}

-- wired: the call did what the page's wiring says for its action.
pred wired[c : Call] {
    c in OpenCart implies wiredOpen[c]
    c in ShareCart implies wiredShare[c]
    c in UnshareCart implies wiredUnshare[c]
    c in AddLine implies wiredAdd[c]
    c in ChangeQuantity implies wiredChange[c]
    c in RemoveLine implies wiredRemove[c]
    c in ClearCart implies wiredClear[c]
    c in ViewCart implies wiredView[c]
    c in CartHistory implies wiredHistory[c]
}

-- allWired: every call that made the state was wired as the page says.
pred allWired { all c : Call | wired[c] }

-- carries: the event is the act's cart event, with the fields its row in the page's table
-- names and no other (Term cart event, the table under Composition state).
pred carries[e : Event, c : Call] {
    c in OpenCart implies evt[e, OpenA, c.opened, c.actor, none, none, none, none, none]
    c in ShareCart implies
        evt[e, ShareA, c.cartIn, c.actor, c.friend, c.verbIn, c.granted, none, none]
    c in UnshareCart implies
        evt[e, UnshareA, c.cartIn, c.actor, none, none, c.grantIn, none, none]
    c in AddLine implies evt[e, AddA, c.cartIn, c.actor, none, none, none, c.added, none]
    c in ChangeQuantity implies
        evt[e, ChangeA, c.cartIn, c.actor, none, none, none, c.lineIn, c.newQty]
    c in RemoveLine implies evt[e, RemoveA, c.cartIn, c.actor, none, none, none, c.rmIn, none]
    c in ClearCart implies evt[e, ClearA, c.cartIn, c.actor, none, none, none, none, none]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_2_1: every grant Permissions carries names a cart Cart carries: its action scope
-- is one of the verb scopes of a cart Cart's open answered (Invariant 2.1, Check 1.1).
assert A_Invariant_2_1 {
    allWired implies
        (all g : Grant | some g.scart and g.scart in Store.carts and g.sverb in CartVerb)
}
check A_Invariant_2_1 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Invariant_3_1: the cart events carry exactly one add event for every line id Cart's
-- records carry, carrying that line id: every line says who added it (Invariant 3.1,
-- Check 2.1).
assert A_Invariant_3_1 {
    allWired implies (all l : Line | one e : Event | e.act = AddA and e.eline = l.lid)
}
check A_Invariant_3_1 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Scope_vocabulary_2: every action scope Permissions carries is written as a cart scope:
-- a cart id and a cart verb (Scope vocabulary 2, Check 3.1).
assert A_Scope_vocabulary_2 {
    allWired implies (all g : Grant | some g.scart and g.sverb in CartVerb)
}
check A_Scope_vocabulary_2 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Scope_vocabulary_3_7: each gated action asks for the cart's verb scope of its own verb:
-- view and history the view scope, add the add scope, change the change scope, remove and
-- clear the remove scope, share and unshare the share scope (Scope vocabulary 3 to 7).
assert A_Scope_vocabulary_3_7 {
    all c : Gated | wired[c] implies {
        c in ViewCart + CartHistory implies c.askVerb = ViewV
        c in AddLine implies c.askVerb = AddV
        c in ChangeQuantity implies c.askVerb = ChangeV
        c in RemoveLine + ClearCart implies c.askVerb = RemoveV
        c in ShareCart + UnshareCart implies c.askVerb = ShareV
    }
}
check A_Scope_vocabulary_3_7 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_1_3: a gated call makes a constituent call (a read, a write or an append)
-- only after permitted answered permitted; a denied answer reaches no constituent at all
-- (Action wiring 1, 3, Composition state 3).
assert A_Action_wiring_1_3 {
    all c : Gated | wired[c] implies (noCall[c] or c.permit = Permitted)
}
check A_Action_wiring_1_3 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_2: a gated call whose permitted answered denied answers permission-denied
-- (Action wiring 2).
assert A_Action_wiring_2 {
    all c : Gated | (wired[c] and c.permit = Denied) implies c.ans = PermissionDenied
}
check A_Action_wiring_2 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_4: a gated call asks permitted with the call's own actor reference and the
-- cart the call names (Action wiring 4).
assert A_Action_wiring_4 {
    all c : Gated | wired[c] implies (c.askRef = c.actor and c.askCart = c.cartIn)
}
check A_Action_wiring_4 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_5: an [Open Cart] with a blank actor reference answers invalid-request and
-- calls nothing (Action wiring 5).
assert A_Action_wiring_5 {
    all o : OpenCart | (wired[o] and o.actor in World.blank) implies
        (o.ans = InvalidRequest and noCall[o])
}
check A_Action_wiring_5 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_6_8: an [Open Cart] past the blank check calls Cart's open with the call's
-- currency, and an answered one answers the cart id Cart's open answered (Action wiring 6, 8).
assert A_Action_wiring_6_8 {
    all o : OpenCart | (wired[o] and o.actor not in World.blank) implies
        (o.openCur = o.currency and (o.ans = AId implies (some o.ansCart and o.ansCart = o.opened)))
}
check A_Action_wiring_6_8 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_7: an answered [Open Cart] granted its actor every verb scope of the new
-- cart: view, add, change, remove and share (Action wiring 7).
assert A_Action_wiring_7 {
    all o : OpenCart | (wired[o] and o.ans = AId) implies
        (all v : CartVerb | some g : o.made |
            g.sverb = v and g.subject = o.actor and g.scart = o.opened)
}
check A_Action_wiring_7 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_9_10: a permitted [Share Cart] whose verb is not a cart verb, or whose friend
-- reference is blank, answers invalid-request and grants nothing (Action wiring 9, 10).
assert A_Action_wiring_9_10 {
    all s : ShareCart |
        (wired[s] and s.permit = Permitted and (s.verbIn not in CartVerb or s.friend in World.blank))
        implies (s.ans = InvalidRequest and no s.granted)
}
check A_Action_wiring_9_10 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_11_12: an answered share granted the friend reference the cart's verb scope
-- for the verb sent, and answered that grant's id (Action wiring 11, 12).
assert A_Action_wiring_11_12 {
    all s : ShareCart | (wired[s] and s.ans = AId) implies {
        one s.granted
        s.granted.subject = s.friend
        s.granted.scart = s.cartIn
        s.granted.sverb = s.verbIn
        s.ansGrant = s.granted
    }
}
check A_Action_wiring_11_12 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_13: a permitted unshare whose grant id names no grant of the cart in
-- Permissions' read answer, another cart's grant included, answers not-known and revokes
-- nothing (Action wiring 13).
assert A_Action_wiring_13 {
    all u : UnshareCart |
        (wired[u] and u.permit = Permitted and u.grantIn not in cartGrants[u.permRead, u.cartIn])
        implies (u.ans = NotKnown and no u.revCalled)
}
check A_Action_wiring_13 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_14: a permitted unshare of a grant of the cart calls revoke with that grant
-- id and no other (Action wiring 14).
assert A_Action_wiring_14 {
    all u : UnshareCart |
        (wired[u] and u.permit = Permitted and u.grantIn in cartGrants[u.permRead, u.cartIn])
        implies u.revCalled = u.grantIn
}
check A_Action_wiring_14 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_15_16: a permitted add calls Cart's add with the call's cart id, item
-- reference, quantity and unit price, and an answered one answers the line id Cart's add
-- answered (Action wiring 15, 16).
assert A_Action_wiring_15_16 {
    all a : AddLine | (wired[a] and a.permit = Permitted) implies {
        a.addCart = a.cartIn
        a.addItem = a.item
        a.addQty = a.qty
        a.addPrice = a.price
        a.ans = AId implies (some a.ansLine and a.ansLine = a.added)
    }
}
check A_Action_wiring_15_16 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_17_19: a permitted change or remove naming a line id the cart does not carry
-- in Cart's read answer, another cart's line included, answers not-known and calls Cart for no
-- write (Action wiring 17, 19).
assert A_Action_wiring_17_19 {
    all c : ChangeQuantity | (wired[c] and c.permit = Permitted and c.lineIn not in c.chRead)
        implies (c.ans = NotKnown and no c.chLine)
    all r : RemoveLine | (wired[r] and r.permit = Permitted and r.rmIn not in r.rmRead)
        implies (r.ans = NotKnown and no r.rmLine)
}
check A_Action_wiring_17_19 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_18_20_21: a permitted change of a line of the cart calls Cart's
-- change_quantity with the line id and the new quantity; a permitted remove calls Cart's
-- remove with the line id; a permitted clear calls Cart's clear with the cart id (Action
-- wiring 18, 20, 21).
assert A_Action_wiring_18_20_21 {
    all c : ChangeQuantity | (wired[c] and c.permit = Permitted and c.lineIn in c.chRead)
        implies (c.chLine = c.lineIn and c.chQty = c.newQty)
    all r : RemoveLine | (wired[r] and r.permit = Permitted and r.rmIn in r.rmRead)
        implies r.rmLine = r.rmIn
    all c : ClearCart | (wired[c] and c.permit = Permitted) implies c.clCart = c.cartIn
}
check A_Action_wiring_18_20_21 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_22: every changing action the composition admits appends its act's cart
-- event, carrying the fields its row names and no other, never an item reference (Action
-- wiring 22, Term cart event, Composes 8 to 10).
assert A_Action_wiring_22 {
    all c : Changing | (wired[c] and c.ans not in Refusal) implies
        (some c.appended and all e : c.appended | carries[e, c])
}
check A_Action_wiring_22 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_24: where a constituent call refuses, the composition answers that refusal,
-- unchanged (Action wiring 24, Composes 11).
assert A_Action_wiring_24 {
    all c : Call | wired[c] implies (all r : outs[c] & Refusal | c.ans = r)
}
check A_Action_wiring_24 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_25: a permitted view answers Cart's read answer, with beside each line the
-- actor reference its add event carries: its adder, not whoever touched it last (Action
-- wiring 25, Composition state 2, Term adder).
assert A_Action_wiring_25 {
    all v : ViewCart | (wired[v] and v.permit = Permitted) implies {
        v.shown = v.vRead
        all l : v.shown | l.(v.adder) = addEvents[v.vLog, l].eactor
    }
}
check A_Action_wiring_25 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_26: a permitted history answers the cart events of the cart: every event it
-- read that carries the cart's id, and no other (Action wiring 26, Term cart events).
assert A_Action_wiring_26 {
    all h : CartHistory | (wired[h] and h.permit = Permitted) implies
        h.hist = { e : h.hLog | e.ecart = h.cartIn }
}
check A_Action_wiring_26 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_27: a permitted view or history reads, through Event Log's read, every cart
-- event of the cart appended before it (Action wiring 27).
assert A_Action_wiring_27 {
    all v : ViewCart | (wired[v] and v.permit = Permitted) implies
        { e : earlier[v.at] | e.ecart = v.cartIn } in v.vLog
    all h : CartHistory | (wired[h] and h.permit = Permitted) implies
        { e : earlier[h.at] | e.ecart = h.cartIn } in h.hLog
}
check A_Action_wiring_27 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_29: a gated call naming a cart id no grant recorded before it names answers
-- permission-denied, never not-known, so a caller learns nothing about carts not shared with
-- them (Action wiring 29).
assert A_Action_wiring_29 {
    all c : Gated |
        (wired[c] and no g : Grant | g.scart = c.cartIn and g.sverb in CartVerb
            and (all m : madeAt[g] | m < c.at))
        implies c.ans = PermissionDenied
}
check A_Action_wiring_29 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Action_wiring_30: an admitted unshare, change, remove or clear whose constituent calls all
-- answered answers ok (Action wiring 30, read with Action wiring 2, 13, 17 and 19: see the
-- finding in the coverage matrix).
assert A_Action_wiring_30 {
    all u : UnshareCart | (wired[u] and u.permit = Permitted
        and u.grantIn in cartGrants[u.permRead, u.cartIn] and u.revOut = AOk) implies u.ans = AOk
    all c : ChangeQuantity | (wired[c] and c.permit = Permitted and c.lineIn in c.chRead
        and c.chOut = AOk) implies c.ans = AOk
    all r : RemoveLine | (wired[r] and r.permit = Permitted and r.rmIn in r.rmRead
        and r.rmOut = AOk) implies r.ans = AOk
    all c : ClearCart | (wired[c] and c.permit = Permitted and c.clOut = AOk) implies c.ans = AOk
}
check A_Action_wiring_30 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Wiring_decision_1: every changing action the composition admits appends exactly one cart
-- event (Wiring decision 1).
assert A_Wiring_decision_1 {
    all c : Changing | (wired[c] and c.ans not in Refusal) implies one c.appended
}
check A_Wiring_decision_1 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Wiring_decision_2: a permitted change to the quantity the line already holds, which Cart
-- answers ok without writing, still appends the call's cart event (Wiring decision 2).
assert A_Wiring_decision_2 {
    all c : ChangeQuantity | (wired[c] and c.permit = Permitted and c.lineIn in c.chRead
        and c.chOut = AOk and c.seenQty = c.newQty) implies some c.appended
}
check A_Wiring_decision_2 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Non_goal_3: a permitted add answers a refusal only where Cart's add refused: the
-- composition checks no unit price of its own (Non-goal 3, Cart Composition note 2).
assert A_Non_goal_3 {
    all a : AddLine | (wired[a] and a.permit = Permitted and a.ans in Refusal) implies
        a.ans = a.addOut
}
check A_Non_goal_3 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- A_Non_goal_10: a permitted share of a cart verb to a friend reference that is not blank
-- grants it, however many friends already hold a grant of the cart (Non-goal 10).
assert A_Non_goal_10 {
    all s : ShareCart | (wired[s] and s.permit = Permitted and s.verbIn in CartVerb
        and s.friend not in World.blank) implies (s.ans = AId and one s.granted)
}
check A_Non_goal_10 for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowBirthdayGift: the walkthrough: Ana opens a cart, lets Ben add, Ben adds a line, and
-- Ana's view shows the line with Ben as its adder.
run ShowBirthdayGift {
    allWired
    some o : OpenCart, s : ShareCart, a : AddLine, v : ViewCart {
        o.ans = AId and s.ans = AId and a.ans = AId and v.ans = AShared
        s.cartIn = o.opened and a.cartIn = o.opened and v.cartIn = o.opened
        s.verbIn = AddV and a.actor = s.friend and s.friend != o.actor and v.actor = o.actor
        a.added in v.shown and a.added.(v.adder) = s.friend
    }
} for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- ShowAddDenied: Cal, holding no add scope, tries to add: permission-denied, nothing called.
run ShowAddDenied {
    allWired
    some o : OpenCart, a : AddLine | o.ans = AId and a.cartIn = o.opened
        and a.actor != o.actor and a.ans = PermissionDenied
} for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- ShowUnknownCart: a view of a cart id no cart carries (`c404`): permission-denied.
run ShowUnknownCart {
    allWired
    some o : OpenCart, v : ViewCart | o.ans = AId and v.cartIn not in Store.carts
        and v.actor = o.actor and v.ans = PermissionDenied
} for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- ShowAlreadyInCart: Cart's add refuses already-in-cart and the composition answers it
-- unchanged, appending nothing.
run ShowAlreadyInCart {
    allWired
    some a : AddLine | a.permit = Permitted and a.ans = AlreadyInCart
} for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- ShowLineNotKnown: a permitted remove of a line the cart does not carry: not-known.
run ShowLineNotKnown {
    allWired
    some r : RemoveLine | r.permit = Permitted and r.ans = NotKnown
} for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- ShowSecondUnshareNotActive: a grant unshared twice: the first answers ok, the second answers
-- Permissions' not-active unchanged.
run ShowSecondUnshareNotActive {
    allWired
    some disj u1, u2 : UnshareCart | u1.grantIn = u2.grantIn and u1.ans = AOk
        and u2.ans = NotActive
} for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- ShowSameQuantityChange: Lea changes a line to the quantity it holds: ok, and the change
-- event is appended all the same (Wiring decision 2).
run ShowSameQuantityChange {
    allWired
    some c : ChangeQuantity | c.ans = AOk and c.seenQty = c.newQty and some c.appended
} for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- ShowHistory: a history after an add answers the open event and the add event, each naming
-- who made it.
run ShowHistory {
    allWired
    some h : CartHistory, a : AddLine | h.ans = AEvents and a.ans = AId
        and a.cartIn = h.cartIn and a.appended in h.hist and #h.hist = 2
} for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- ShowInvalidVerb: a share of a verb outside the cart verbs (`own`): invalid-request.
run ShowInvalidVerb {
    allWired
    some s : ShareCart | s.permit = Permitted and s.verbIn = OwnV and s.ans = InvalidRequest
} for 3 but 4 Int, 4 Call, 7 Grant, 4 Event

-- ShowBlankOpener: an [Open Cart] with a blank actor reference: invalid-request.
run ShowBlankOpener {
    allWired
    some o : OpenCart | o.actor in World.blank and o.ans = InvalidRequest
} for 3 but 4 Int, 4 Call, 7 Grant, 4 Event
