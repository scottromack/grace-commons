---
title: Shared Cart
id: 25
parent: Conceptual Compositions
has_toc: true
toc: true
---

# Shared Cart

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Shared Cart turns one person's cart into one several people can see and add to. Whoever opens a cart can do everything to it, and shares it with each friend one permission at a time: to view it, to add to it, to change a quantity, to take lines out, or to share it further. Every action but opening a cart is checked against those permissions before anything changes, and every change records who made it, so the cart shows which friend added each line, and the full history of who did what stays readable even after a friend's access is taken away. It wires three tested patterns: a cart (Cart), a grant-based permission system (Permissions) and an add-only record of what happened (Event Log). It decides nothing about prices, sign-in or checkout, which belong to other patterns.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

A cart is single-person by design: Cart has no notion of who is acting, Permissions treats an action scope as a meaningless string until a composition gives it meaning, and Event Log stores a payload it never reads. The shape this composition wires recurs wherever people buy together: a gift several friends chip in on, a household's weekly shop, an office lunch order, a wish list shared with family. The constant is a cart several people reach under permissions one person hands out, with a record of who added what, because people are unpredictable and the record is how anyone finds out what happened. This is a composition, not a new primitive: Cart, Permissions and Event Log are unchanged.

</details>

---

## Composes

- **[Cart](../atoms/cart.md)** — the lines, their prices and the total.
- **[Permissions](../atoms/permissions.md)** — the grants every action on a cart checks.
- **[Event Log](../atoms/event-log.md)** — the add-only record of every change and who made it.

```
Composes 1: EXACTLY ONE Cart instance MUST serve the composition.
Composes 2: EXACTLY ONE Permissions instance MUST serve the composition.
Composes 3: EXACTLY ONE Event Log instance MUST serve the composition.
Composes 4: The composition MUST NOT change a constituent's spec.
Composes 5: The composition MUST replace the constituents' own caller surface.
Composes 6: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 7: The composition MUST discharge Permissions Composition note 2.
Composes 8: The composition MUST discharge Event Log Composition note 1.
Composes 9: The composition MUST discharge Event Log Composition note 2.
Composes 10: The composition MUST discharge Event Log Composition note 3.
Composes 11: The composition MUST NOT answer a constituent's rejection changed.
Composes 12: A constituent instance MUST NOT serve a pattern other than the composition.
```

Term composition: this pattern's wiring of [Cart](../atoms/cart.md), [Permissions](../atoms/permissions.md) and [Event Log](../atoms/event-log.md) — the gate, the scope vocabulary, the cart events and the actions below.

Term constituents: [Cart](../atoms/cart.md), [Permissions](../atoms/permissions.md), [Event Log](../atoms/event-log.md).

### Premodel

Drafted before any rule (the section titled *Workflow for adding a new pattern* in [`contributing.md`](../contributing.md), step 3). Every rule the draft writes fills a cell of the closure table under Action wiring.

**Constituents grounded first.** Every constituent is grounded.

| Constituent | Kind | Status | Grounded |
|---|---|---|---|
| Cart | atom | `grounded on Final Critique 4 — 2026-10-24` | yes |
| Permissions | atom | `grounded on Final Critique 8 — 2026-10-26` | yes |
| Event Log | atom | `grounded on Final Critique 13 — 2026-10-25` | yes |

**Bindings.** Each constituent parameter the composition binds, and to what.

| Constituent | Parameter | Bound to |
|---|---|---|
| Cart | accepted currencies | the deployment's, unchanged |
| Cart | unit price (Composition note 2) | the unit price an [Add Line] call carries, supplied by the composing pattern that prices the item (Composition note 4) |
| Permissions | subject reference | the actor reference a call carries (Action wiring 4) |
| Permissions | action scope | a cart scope (Scope vocabulary 2) |
| Permissions | string cap | the deployment's, unchanged |
| Event Log | data | a cart event (Action wiring 22) |
| Event Log | payload cap | the deployment's, unchanged |

**Constituent surface.** What each call can answer, and where the Execution Contract lands it by default.

| Call | Answers | Refuses | Default landing |
|---|---|---|---|
| Cart.open | cart_id | invalid-currency \| storage-failure | storage-failure: Execution Contract Constituent failure 1 |
| Cart.add | line_id | not-known \| invalid-item-reference \| invalid-quantity \| invalid-price \| already-in-cart \| cart-full \| storage-failure | storage-failure: Execution Contract Constituent failure 1 |
| Cart.change_quantity | ok | not-known \| invalid-quantity \| storage-failure | storage-failure: Execution Contract Constituent failure 1 |
| Cart.remove | ok | not-known \| storage-failure | storage-failure: Execution Contract Constituent failure 1 |
| Cart.clear | ok | not-known \| storage-failure | storage-failure: Execution Contract Constituent failure 1 |
| Cart.read | cart | not-known | failed read: Execution Contract Read 1 |
| Permissions.grant | grant_id | invalid-request \| storage-failure | storage-failure: Execution Contract Constituent failure 1 |
| Permissions.revoke | ok | not-known \| not-active \| storage-failure | storage-failure: Execution Contract Constituent failure 1 |
| Permissions.permitted | permitted \| denied | — | failed read: Execution Contract Read 1 |
| Permissions.read | every grant | — | failed read: Execution Contract Read 1 |
| Event Log.append | event_id | invalid-payload \| storage-failure | storage-failure: Execution Contract Constituent failure 1 |
| Event Log.read | events | invalid-query | failed read: Execution Contract Read 1 |

Every call that never answers lands under Execution Contract Error model 1, and every failed read under Execution Contract Read 1.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST NOT store a record.
Composition state 2: The composition MUST derive a line's adder from the cart events.
Composition state 3: The composition MUST derive who may act on a cart from Permissions' permitted.
Composition state 4: The composition MUST NOT materialize a derived query.
```

Term actor reference: the opaque reference a call carries for the person making it; the composition checks it and never authenticates it (Non-goal 1).

Term friend reference: the actor reference [Share Cart] grants a verb scope to.

Term cart event: the data a changing action appends to Event Log, whose schema the composition owns (Event Log Composition note 3): the fields the act's row below names, each under its projection — the act's name as act, written as the action's signature writes it, the cart id as cart_id, the actor reference as actor_ref, the friend reference as friend_ref, the cart verb as cart_verb, the grant id as grant_id, the line id as line_id, the new quantity as new_quantity — and no other; never an item reference, which the Cart records hold.

NOTE: watch the wire surface (Term cart event).

The cart event each changing action appends, and the rule that owns it:

| Changing action | Its cart event carries |
|---|---|
| [Open Cart] | the act's name, the cart id Cart's open answers and the actor reference (Action wiring 22) |
| [Share Cart] | the act's name, the cart id, the actor reference, the friend reference, the cart verb and the grant id Permissions' grant answers (Action wiring 22) |
| [Unshare Cart] | the act's name, the cart id, the actor reference and the grant id (Action wiring 22) |
| [Add Line] | the act's name, the cart id, the actor reference and the line id Cart's add answers (Action wiring 22) |
| [Change Quantity] | the act's name, the cart id, the actor reference, the line id and the new quantity (Action wiring 22) |
| [Remove Line] | the act's name, the cart id, the actor reference and the line id (Action wiring 22) |
| [Clear Cart] | the act's name, the cart id and the actor reference (Action wiring 22) |

Term add event: the cart event an [Add Line] appends.

Term cart events: the events of the Event Log instance whose data carries one cart id as cart_id, in sequence number order; the cart events of a cart are the ones carrying that cart's id.

Term adder: the actor reference the add event of a line carries.

Term whole-log query: a sequence number range from one carrying no upper end — a query Event Log's read admits, and the one query known to answer every cart event of a cart.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply the constituents' database PER Execution Contract Database 1 and Execution Contract Database 2.
Capability requirement 2: The deployment MUST hold EVERY actor reference within the reference bound.
Capability requirement 3: IF the reference bound EQUALS blank THEN the composition MUST refuse to start.
```

NOTE: watch the unset setting (Capability requirement 3).

Term reference bound: the most bytes an actor reference carries, set by the deployment so the largest cart event, its host-allocated ids at the longest the host allocates, fits Event Log's payload cap.

### Action wiring

```
open_cart(actor_ref, currency)
  answers cart_id
  refuses invalid-request | invalid-currency | storage-failure

share_cart(actor_ref, cart_id, friend_ref, cart_verb)
  answers grant_id
  refuses permission-denied | invalid-request | storage-failure

unshare_cart(actor_ref, cart_id, grant_id)
  answers ok
  refuses permission-denied | not-known | not-active | storage-failure

add_line(actor_ref, cart_id, item_reference, quantity, unit_price)
  answers line_id
  refuses permission-denied | invalid-item-reference | invalid-quantity | invalid-price | already-in-cart | cart-full | storage-failure

change_quantity(actor_ref, cart_id, line_id, new_quantity)
  answers ok
  refuses permission-denied | not-known | invalid-quantity | storage-failure

remove_line(actor_ref, cart_id, line_id)
  answers ok
  refuses permission-denied | not-known | storage-failure

clear_cart(actor_ref, cart_id)
  answers ok
  refuses permission-denied | storage-failure

view_cart(actor_ref, cart_id)
  answers shared cart
  refuses permission-denied

cart_history(actor_ref, cart_id)
  answers cart events
  refuses permission-denied
```

```
Action wiring 1: EVERY gated call MUST follow a permitted answer for the action's verb scope.
Action wiring 2: IF Permissions' permitted answers denied THEN the composition MUST answer permission-denied.
Action wiring 3: The composition MUST NOT call a constituent for a denied answer.
Action wiring 4: A gated action MUST call Permissions' permitted with the call's actor reference and the action's verb scope.
Action wiring 5: IF the actor reference EQUALS blank THEN [Open Cart] MUST answer invalid-request.
Action wiring 6: [Open Cart] MUST call Cart's open with the currency.
Action wiring 7: [Open Cart] MUST call Permissions' grant with the actor reference for EVERY verb scope of the new cart.
Action wiring 8: [Open Cart] MUST answer the cart id Cart's open answers.
Action wiring 9: IF the cart verb IS NOT IN the cart verbs THEN [Share Cart] MUST answer invalid-request.
Action wiring 10: IF the friend reference EQUALS blank THEN [Share Cart] MUST answer invalid-request.
Action wiring 11: A permitted share MUST call Permissions' grant with the friend reference and the cart's verb scope for the cart verb.
Action wiring 12: A permitted share MUST answer the grant id Permissions' grant answers.
Action wiring 13: A permitted unshare MUST answer not-known for a grant id naming no grant of the cart in Permissions' read answer.
Action wiring 14: A permitted unshare MUST call Permissions' revoke with the grant id.
Action wiring 15: A permitted add MUST call Cart's add with the cart id, the item reference, the quantity and the unit price of the call.
Action wiring 16: A permitted add MUST answer the line id Cart's add answers.
Action wiring 17: A permitted change MUST answer not-known for a line id the cart does not carry in Cart's read answer.
Action wiring 18: A permitted change MUST call Cart's change_quantity with the line id and the new quantity.
Action wiring 19: A permitted remove MUST answer not-known for a line id the cart does not carry in Cart's read answer.
Action wiring 20: A permitted remove MUST call Cart's remove with the line id.
Action wiring 21: A permitted clear MUST call Cart's clear with the cart id.
Action wiring 22: EVERY changing action MUST call Event Log's append with the act's cart event.
Action wiring 23: A refused act MUST NOT call Event Log's append.
Action wiring 24: IF a constituent call refuses THEN the composition MUST answer the refusal.
Action wiring 25: A permitted view MUST answer Cart's read answer AND the adder of EVERY line.
Action wiring 26: A permitted history MUST answer the cart events of the cart.
Action wiring 27: [View Cart] AND [Cart History] MUST read EVERY cart event of the cart through Event Log's read.
Action wiring 28: [View Cart] AND [Cart History] MUST NOT write.
Action wiring 29: A gated action MUST answer permission-denied for a cart id no grant names.
Action wiring 30: IF no constituent call of the action refuses THEN [Unshare Cart], [Change Quantity], [Remove Line] AND [Clear Cart] MUST answer ok.
```

Term gated action: every action but [Open Cart] — the actions that name an open cart by its cart id.

Term gated call: every constituent call a gated action makes but Permissions' permitted.

Term changing action: [Open Cart] | [Share Cart] | [Unshare Cart] | [Add Line] | [Change Quantity] | [Remove Line] | [Clear Cart].

Term refused act: a call the composition answers with a refusal.

Term grant of the cart: a grant whose action scope is one of the cart's verb scopes.

Term shared cart: Cart's read answer for a cart, with the adder beside each line.

Term permitted share: a [Share Cart] call whose share scope check answered permitted.

Term permitted unshare: an [Unshare Cart] call whose share scope check answered permitted.

Term permitted add: an [Add Line] call whose add scope check answered permitted.

Term permitted change: a [Change Quantity] call whose change scope check answered permitted.

Term permitted remove: a [Remove Line] call whose remove scope check answered permitted.

Term permitted clear: a [Clear Cart] call whose remove scope check answered permitted.

Term permitted view: a [View Cart] call whose view scope check answered permitted.

Term permitted history: a [Cart History] call whose view scope check answered permitted.

#### Closure table

Every action, every constituent call it makes, and for each call its answer, its refusals, a failed read and a call that never answers, each with the rule that lands it. A refusal is answered unchanged (Composes 11, Action wiring 24); every storage-failure is Execution Contract Constituent failure 1, and an action's writes commit together or not at all (Execution Contract Database 1).

| Action | Call | Answer | Refusals | Failed read | No answer |
|---|---|---|---|---|---|
| [Open Cart] | Cart.open | the cart id, answered (Action wiring 8) | invalid-currency: Action wiring 24 | Execution Contract Read 1 | Execution Contract Error model 1 |
| [Open Cart] | Permissions.grant, once per verb scope | kept by Permissions (Action wiring 7) | invalid-request: Action wiring 24 for an actor reference or cart scope over Permissions' string cap (Permissions String 6); unreachable for a blank actor reference, which Action wiring 5 refuses first | Execution Contract Read 1 | Execution Contract Error model 1 |
| every changing action | Event Log.append | kept by Event Log (Action wiring 22) | invalid-payload: unreachable under Capability requirement 2 and Capability requirement 3 | Execution Contract Read 1 | Execution Contract Error model 1 |
| every gated action | Permissions.permitted | permitted: the action proceeds (Action wiring 1); denied: Action wiring 2, Action wiring 3, and Action wiring 29 for a cart id no grant names | — | Execution Contract Read 1 | Execution Contract Error model 1 |
| [Share Cart] | Permissions.grant | the grant id, answered (Action wiring 12) | invalid-request: Action wiring 24 for a friend reference or cart scope over Permissions' string cap (Permissions String 6); unreachable otherwise, since Action wiring 9 and 10 refuse the call before it is made, behind permission-denied (Execution Contract Refusal 1) | Execution Contract Read 1 | Execution Contract Error model 1 |
| [Unshare Cart] | Permissions.read | the grant, found or not (Action wiring 13) | — | Execution Contract Read 1 | Execution Contract Error model 1 |
| [Unshare Cart] | Permissions.revoke | ok, answered (Action wiring 30) | not-known: unreachable, Action wiring 13 answers first; not-active: Action wiring 24 | Execution Contract Read 1 | Execution Contract Error model 1 |
| [Add Line] | Cart.add | the line id, answered (Action wiring 16) | not-known: unreachable under Action wiring 29 and Invariant 2.1; every other refusal but storage-failure, cart-full among them: Action wiring 24 | Execution Contract Read 1 | Execution Contract Error model 1 |
| [Change Quantity], [Remove Line] | Cart.read | the cart's lines (Action wiring 17, Action wiring 19) | not-known: unreachable under Action wiring 29 and Invariant 2.1 | Execution Contract Read 1 | Execution Contract Error model 1 |
| [Change Quantity] | Cart.change_quantity | ok, answered (Action wiring 30) | not-known: unreachable, Action wiring 17 answers first; invalid-quantity: Action wiring 24 | Execution Contract Read 1 | Execution Contract Error model 1 |
| [Remove Line] | Cart.remove | ok, answered (Action wiring 30) | not-known: unreachable, Action wiring 19 answers first | Execution Contract Read 1 | Execution Contract Error model 1 |
| [Clear Cart] | Cart.clear | ok, answered (Action wiring 30) | not-known: unreachable under Action wiring 29 and Invariant 2.1 | Execution Contract Read 1 | Execution Contract Error model 1 |
| [View Cart] | Cart.read | the cart (Action wiring 25) | not-known: unreachable under Action wiring 29 and Invariant 2.1 | Execution Contract Read 1 | Execution Contract Error model 1 |
| [View Cart], [Cart History] | Event Log.read | the events, filtered to the cart events of the cart (Action wiring 25, Action wiring 26, Action wiring 27) | invalid-query: unreachable under Action wiring 27, which no refused query meets; the whole-log query is a query Event Log admits that meets Action wiring 27 | Execution Contract Read 1 | Execution Contract Error model 1 |

### Wiring decision

```
Wiring decision 1: The composition MUST append EXACTLY ONE cart event per changing action the composition admits (Execution Contract Read 4).
Wiring decision 2: A [Change Quantity] call to the quantity the line already holds MUST append the call's cart event, which records the call made and no change of the line.
```

<details markdown="block">
<summary>WHY</summary>

Attribution is the composition's load-bearing decision and no constituent holds it: Cart knows no one is acting, Permissions knows who may act but records no act, and Event Log stores a payload it never reads.

</details>

### Scope vocabulary

```
Scope vocabulary 1: The composition MUST define the action scopes the Permissions instance carries.
Scope vocabulary 2: The composition MUST name EVERY action scope as a cart scope.
Scope vocabulary 3: The composition MUST gate [View Cart] AND [Cart History] on the cart's view scope.
Scope vocabulary 4: The composition MUST gate [Add Line] on the cart's add scope.
Scope vocabulary 5: The composition MUST gate [Change Quantity] on the cart's change scope.
Scope vocabulary 6: The composition MUST gate [Remove Line] AND [Clear Cart] on the cart's remove scope.
Scope vocabulary 7: The composition MUST gate [Share Cart] AND [Unshare Cart] on the cart's share scope.
```

Term cart verbs: view | add | change | remove | share.

Term cart scope: an action scope naming one cart and one cart verb, written as the cart id, a colon and the cart verb, such as `c1:add`; a grant names a cart where its action scope EQUALS one of that cart's verb scopes as a whole string, and no rule parses a scope.

Term verb scope: a cart's view scope, add scope, change scope, remove scope or share scope.

Term view scope: the cart scope carrying view, such as `c1:view`.

Term add scope: the cart scope carrying add, such as `c1:add`.

Term change scope: the cart scope carrying change, such as `c1:change`.

Term remove scope: the cart scope carrying remove, such as `c1:remove`.

Term share scope: the cart scope carrying share, such as `c1:share`.

---

## Composition-level invariants

- **Invariant 1 — Permission enforcement.**
  ```
  Invariant 1.1: A denied answer MUST NOT reach a constituent write.
  ```
- **Invariant 2 — Every grant names an open cart.**
  ```
  Invariant 2.1: EVERY grant the Permissions instance carries MUST name a cart the Cart instance carries.
  ```
- **Invariant 3 — Every change is attributed.**
  ```
  Invariant 3.1: The cart events MUST carry EXACTLY ONE add event for EVERY line id the Cart records carry.
  Invariant 3.2: The cart events MUST NOT carry an event for a refused act.
  ```
- **Invariant 4 — Unsharing keeps the lines.**
  ```
  Invariant 4.1: [Unshare Cart] MUST NOT change a line.
  ```

Permission enforcement and attribution together give the shared surface: no friend acts beyond the grants a sharer handed out, and every line says who added it. Because grants are made only by [Open Cart] and by a permitted share, a cart id no grant names is answered as permission-denied, never not-known (Action wiring 29), and a caller learns nothing about carts not shared with them.

---

## Examples

Amounts are whole numbers of the currency's minor unit, so `4999` in US dollars is $49.99.

### Birthday gift

Ana opens a cart in US dollars for her brother's birthday: `open_cart(ana, "USD")` answers `c1`, and Ana holds `c1:view`, `c1:add`, `c1:change`, `c1:remove` and `c1:share`. She lets Ben add and view — `share_cart(ana, c1, ben, "add")` answers grant `g6`, `share_cart(ana, c1, ben, "view")` answers `g7` — and lets Cal view only: `share_cart(ana, c1, cal, "view")` answers `g8`. Ben adds headphones at $49.99: `add_line(ben, c1, "headphones-black", 1, 4999)` answers `l1`. Ana adds a card at $4.50: `add_line(ana, c1, "card-birthday", 1, 450)` answers `l2`. Cal tries `add_line(cal, c1, "socks", 2, 900)` — [Permission Denied]; Cal holds no `c1:add`. `view_cart(cal, c1)` answers both lines and a total of 5449, `l1` added by ben and `l2` by ana. Ana takes away Ben's adding — `unshare_cart(ana, c1, g6)` answers ok — and `l1` stays, still added by ben; Ben's next add is refused, and he can still view. Later Ana lets Cal remove — `share_cart(ana, c1, cal, "remove")` answers `g9` — and `clear_cart(cal, c1)` answers ok: the remove scope reaches every line, Ben's `l1` and Ana's `l2` alike, and the cart events still name who added each.

### Office lunch

An office manager opens a cart in euros — `open_cart(maya, "EUR")` answers `c7` — and gives four colleagues add and change. Each adds a lunch; Tom adds two sandwiches, and Lea, seeing the office is short, changes the quantity to three: `change_quantity(lea, c7, l31, 3)` answers ok. `cart_history(maya, c7)` answers every change in order: Tom's add of `l31`, then Lea's change to 3, each naming who made it.

### Rejection paths

Ana's cart `c1` above, after Ben's adding was taken away and before Ana let Cal remove:

- `open_cart("", "USD")` — rejected as [Invalid Request]; the actor reference is blank.
- `open_cart(ana, "XYZ")` — rejected as invalid-currency, Cart's refusal answered unchanged.
- `share_cart(ana, c1, dan, "own")` — rejected as [Invalid Request]; `own` is no cart verb.
- `share_cart(ben, c1, dan, "view")` — rejected as [Permission Denied]; Ben holds no `c1:share`.
- `view_cart(ana, c404)`, where no cart `c404` exists — rejected as [Permission Denied]; no grant names `c404`.
- `remove_line(ana, c1, l99)` — rejected as [Not Known]: `c1` carries no line `l99`.
- `unshare_cart(ana, c1, g99)` — rejected as [Not Known]; a second `unshare_cart(ana, c1, g6)` — rejected as not-active, Permissions' refusal answered unchanged.
- `add_line(ana, c1, "headphones-black", 1, 4999)` — rejected as already-in-cart: Ben's `l1` holds the item; Ana changes its quantity instead.

---

## Generation acceptance

Every check below clears from the three constituents' records; where a claim needs evidence the records do not carry, it is an external check and says so.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY grant the Permissions records carry naming a cart the Cart records carry (Invariant 2.1).
Check 2.1: An auditor MUST find EXACTLY ONE add event for EVERY line id the Cart records carry, carrying the line id (Invariant 3.1).
Check 3.1: An auditor MUST find EVERY action scope the Permissions records carry written as a cart scope (Scope vocabulary 2).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing a denied call confirmed unreached MUST read the deployment's own implementation (Invariant 1.1).
External check 2: An auditor needing a refused act confirmed unrecorded MUST read the deployment's own implementation (Invariant 3.2).
External check 3: An auditor needing an unshare confirmed clear of the lines MUST read the deployment's own implementation (Invariant 4.1).
External check 4: An auditor needing the actor reference bound to a caller MUST read the deployment's authentication layer (Non-goal 1).
External check 5: An auditor needing a call on a cart id no grant names confirmed answered permission-denied MUST read the deployment's own implementation (Action wiring 29).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT authenticate an actor reference.
Non-goal 2: The composition MUST NOT attest a share.
Non-goal 3: The composition MUST NOT check a unit price.
Non-goal 4: The composition MUST NOT turn a cart into an order.
Non-goal 5: The composition MUST NOT share a cart by link.
Non-goal 6: The composition MUST NOT notify a friend.
Non-goal 7: The composition MUST NOT seal a cart event.
Non-goal 8: A deployment needing a tamper-evident record MUST compose Audit Trail.
Non-goal 9: The composition MUST NOT revoke a departing actor's grants.
Non-goal 10: The composition MUST NOT limit the friends a cart is shared with.
```

NOTE: the owners — an authenticating pattern such as [Login](./login.md) or [Authenticated Actor](./authenticated-actor.md) (Non-goal 1, External check 4); [Attributed Permissions Admin](./attributed-permissions-admin.md) (Non-goal 2); Pricing *(forthcoming)* (Non-goal 3); Checkout *(forthcoming)* (Non-goal 4); [Capability](../atoms/capability.md) (Non-goal 5); [Notification](../atoms/notification.md) (Non-goal 6); [Audit Trail](./audit-trail.md) (Non-goal 7, Non-goal 8); the deployment, through [Unshare Cart] (Non-goal 9, Composition note 3); the deployment (Non-goal 10).

---

## Edge cases

### Concurrency

Two friends adding one item to one cart at once are serialized (Execution Contract Database 2): the later reads the line the earlier recorded and answers already-in-cart. A friend's add racing the sharer's unshare is serialized too: the add's permitted read and its writes are one transaction, so the add lands with its add event before the revoke commits, or is denied after.

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Add Line] where the first landed answers already-in-cart, and [View Cart] then shows the line with its adder; a repeated [Share Cart] records a second grant of the same verb scope, which grants nothing more; a repeated [Unshare Cart] answers not-active; a repeated [Change Quantity] answers ok again and appends a second cart event, one for each call made.

---

## Composition notes

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns the declaration of the composing patterns a deployment wired in.
Composition note 2: A deployment MUST bind an actor reference to an authenticated caller.
Composition note 3: A deployment MUST revoke a departing actor's grants through [Unshare Cart].
NOTE: open 2026-11-04-a — a departing sharer holding a cart's last share scope, or a departing opener, has grants whose ids no action answers to the sweep.
Composition note 4: A composing pattern MUST supply a unit price in the cart's currency.
```

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**. References to the constituents' own operations stay qualified calls to those atoms.

### Vocabulary

Term actors: the composition; the constituents; the deployment (also: a deployment); a composing pattern; the database; an auditor; a cart; a line; a grant; a gated action; a changing action; a refused act; a caller.

Term records: none of the composition's own; the constituents' carts, lines, grants and events.

Term record verbs: serve, change, replace, inherit, discharge, answer, store, derive, materialize, supply, hold, follow, call, define, name, gate, append, read, write, carry, reach, find, authenticate, attest, check, turn, share, notify, seal, compose, revoke, limit, declare, bind, refuse, start.

Term value sets: cart verbs = view | add | change | remove | share; changing action is declared above and cited here (GRACE-lang Closed vocabulary 15).

Term bounds: reference bound (the deployment's, under Event Log's payload cap).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.69 (2026-10-30) through the Grace connector.

Term terms: composition, constituents, actor reference, friend reference, cart event, add event, cart events, adder, whole-log query, reference bound, gated action, gated call, changing action, refused act, grant of the cart, shared cart, permitted share, permitted unshare, permitted add, permitted change, permitted remove, permitted clear, permitted view, permitted history, cart verbs, cart scope, verb scope, view scope, add scope, change scope, remove scope, share scope.

Term cited: Execution Contract Conformance 8 — recursive conformance and the inherited guarantee. Execution Contract Conformance 9 — the declaration of the composing patterns a deployment wired in. [Permissions](../atoms/permissions.md) `Composition note 2` — the scope vocabulary, owned; `Composition note 3` — the caller-to-subject binding, relayed (Composition note 2); `Composition note 5` — a departing subject's sweep, relayed (Composition note 3). [Cart](../atoms/cart.md) `Composition note 2` — the unit price, relayed (Composition note 4). [Event Log](../atoms/event-log.md) `Composition note 1`, `Composition note 2` and `Composition note 3` — append on every change, the meaning of an event and the payload's schema, owned.

#### Open Cart

Starts a shared cart: opens a cart through Cart's `open`, grants the opener every verb scope on it through Permissions' `grant`, appends the cart event, and answers the new cart id. The one action no permission gates.

Kind: Operation

#### Share Cart

Grants a friend one [Cart Verb] on a cart, through Permissions' `grant`, for a caller holding the cart's share scope; answers the grant id.

Kind: Operation

#### Unshare Cart

Takes one grant on a cart away, through Permissions' `revoke`, for a caller holding the cart's share scope. The lines the friend added, and the record of what they did, stay.

Kind: Operation

#### Add Line

Puts an item on a shared cart through Cart's add, for a caller holding the cart's add scope, and records the caller as the line's adder.

Kind: Operation

#### Change Quantity

Changes a line's quantity through Cart's change quantity action, for a caller holding the cart's change scope.

Kind: Operation

#### Remove Line

Takes a line off a shared cart through Cart's remove, for a caller holding the cart's remove scope.

Kind: Operation

#### Clear Cart

Takes every line off a shared cart through Cart's `clear`, for a caller holding the cart's remove scope.

Kind: Operation

#### View Cart

Answers a shared cart for a caller holding its view scope: Cart's `read` answer, with each line's adder from the cart events. Changes nothing.

Kind: Operation

#### Cart History

Answers every change to a shared cart, in order, each with who made it, for a caller holding its view scope. Changes nothing.

Kind: Operation

#### Cart Verb

What one grant lets a friend do to a cart: view, add, change, remove or share.

Kind:         Parameter
Parameter of: Share Cart
Projection:   cart_verb

#### Permission Denied

The composition's own refusal, answered when Permissions' `permitted` answers denied, before any other constituent is called (Invariant 1.1); also the answer for a cart id no grant names (Action wiring 29), so a caller learns nothing about carts not shared with them.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: permission-denied

#### Not Known

The composition's own refusal of a grant id naming no grant of the cart on [Unshare Cart] (Action wiring 13) and of a line id the cart does not carry on [Change Quantity] and [Remove Line] (Action wiring 17 and 19); the same code answers a constituent's not-known unchanged (Action wiring 24).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Invalid Request

The composition's own refusal of a blank actor reference on [Open Cart], or of a blank friend reference or a [Cart Verb] outside the cart verbs on [Share Cart]; the same code answers Permissions' invalid-request unchanged, for a reference or cart scope over Permissions' string cap (Action wiring 24).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Open Cart]: #open-cart
[Share Cart]: #share-cart
[Unshare Cart]: #unshare-cart
[Add Line]: #add-line
[Change Quantity]: #change-quantity
[Remove Line]: #remove-line
[Clear Cart]: #clear-cart
[View Cart]: #view-cart
[Cart History]: #cart-history
[Cart Verb]: #cart-verb
[Permission Denied]: #permission-denied
[Invalid Request]: #invalid-request
[Not Known]: #not-known

---

## Standards references

Shared Cart is a wiring of three primitives and not a regulated pattern, so it carries no standard of its own at this layer. The standards it touches are its constituents' and are cited there: [Cart](../atoms/cart.md), [Permissions](../atoms/permissions.md) and [Event Log](../atoms/event-log.md).

## Status

`grounded on Final Critique 2 — 2026-11-05 at b430bcf` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 2 — 2026-11-05 at b430bcf
formal: verified — shared-cart.als + 26 twins (the static data model: Invariant 2.1 and 3.1, Scope vocabulary 2 and 3 through 7, Action wiring 1 through 22, 24 through 27, 29 and 30, Wiring decision 1 and 2 and Non-goal 3 and 10 checked on every call's permitted check, constituent calls, cart event and answer and on the carts, lines, grants and events they leave, with Composes 7 through 11, Composition state 2 and 3 and Scope vocabulary 1 checked through them); shared-cart.tla + 4 twins (across steps, while an opener and a friend share, unshare, add, change, remove, clear, view and read back: Invariant 1.1, 3.2 and 4.1 and Action wiring 28, with Action wiring 23 checked through them); the vote no of 2026-10-30 superseded by the maintainer's ruling of 2026-11-09 (both models; only the writing vetoes one), and neither vetoed; Action wiring 30 checked as Action wiring 2, 13, 17 and 19 read it (its condition does not exclude the composition's own refusals); owed rows: none, 2026-11-12
last gate: 2026-11-05 — Final Critique 2, delta, frozen at b430bcf — foundational count 0, clean, one sample; 2026-11-04 — Final Critique 1, frozen at d7d3b7a — foundational count 5, cured, not clean, no sample

open:
- 2026-11-04-a · refining · Composition note 3; Non-goal 9; Unshare Cart · the sweep of a departing actor's grants through [Unshare Cart] needs the caller to hold the cart's share scope and the grant id, and no action answers the grant ids [Open Cart] gives the opener, so a departing sharer holding the cart's last share scope, or a departing opener, leaves grants the sweep cannot name → decide who may revoke a departing actor's grants and how their grant ids surface (an answer on [Open Cart], or a grant listing)
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only; everything smaller lives in `git log -- compositions/shared-cart.md`.

- **2026-10-30 — Drafted through the Grace connector from the maintainer's need, mirroring Shared Todo.** *Chose:* a cart several people see and add to (the maintainer, 2026-10-30: "a cart my friends can see and add to"), wiring three grounded atoms, so no constituent ripple is accepted; every change attributed to the actor who made it (the maintainer: "knowing the randomness of humans we would want to know this"), through Event Log rather than a record of the composition's own, keeping Shared Todo's no-stored-state shape (Composition state 1); permissions per cart and per verb, the opener holding all five (Action wiring 7, Scope vocabulary 2 through 7); a cart id no grant names answered as permission-denied (Invariant 2.1); the cart event carrying no item reference, which Cart's records hold, so the payload stays bounded by the actor references alone (Capability requirement 2). *Over:* a composition-owned attribution record (a stored record beside the constituents'); Assignment for the adder (it names who is responsible, not who acted); one list-wide scope set, as Shared Todo's (every friend would reach every cart); Capability-backed link sharing (a bearer link names no friend, so attribution would fail). *Because:* Cart, Permissions and Event Log each decline exactly what the others hold, and the closure table lands every answer of every call in a named rule; the receivers of what the composition declines are named in Non-goals and Composition notes, as Shared Todo's council read 55 asked.

</details>

NOTE: End of Shared Cart.
