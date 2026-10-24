---
title: Cart
parent: Atomic Concepts
has_toc: true
toc: true
---

# Cart

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Cart is a shopping cart: it holds what a person means to buy, one line per item, each line saying how many of the item and the price it had when it was added, and it adds the lines up to a total. A cart is opened in one currency, and every price on it and its total are whole numbers of that currency's smallest unit, such as cents for the euro, so adding them up never rounds. A line keeps the price it was added at even if the shop's price changes later, so the total moves only when a line is added, its quantity is changed, or it is taken out; to charge a new price, the line is taken out and the item added again. The cart decides nothing about what an item costs, whether it is in stock, what tax or delivery applies, whose cart it is, or how the purchase is paid for and becomes an order: each of those belongs to another pattern, which is why one cart can serve an online store, a café's open tab, a wholesale order and a booking alike.

---

## Intent

WHY:
A shop lets a person gather what they mean to buy before they buy it, and the shape recurs wherever goods or services are sold: an online store's basket, a café's open tab, a wholesale order assembled line by line, a booking that collects tickets and extras before payment. The shape is constant — lines, each naming an item, how many of it, and the price it was offered at when it went in, and a total the lines add up to — and this atom is that and nothing more. It does not decide what an item costs, whether one is in stock, what tax or delivery applies, whose cart it is, or how the purchase is paid for and becomes an order; each of those belongs to a composing pattern, and declining them is what lets one cart serve an online store, a till and a booking system alike. Two decisions carry the weight. A line keeps the unit price taken when it was added, and nothing in the atom changes it afterwards, so the total moves only when a line is added, re-counted or taken out, never because a price moved underneath it. And a cart holds at most one line per item, so how many of an item a cart holds is one quantity on one line.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a cart by the cart id.
Identity 2: The atom MUST identify a line by the line id.
Identity 3: The atom MUST NOT reuse a cart id.
Identity 4: The atom MUST NOT reuse a line id.
Identity 5: The atom MUST NOT identify a line by the line's item reference.
Identity 6: The atom MUST NOT normalize an item reference.
Identity 7: The atom MUST compare two item references codepoint for codepoint.
Identity 8: The atom MUST NOT normalize a currency.
Identity 9: The atom MUST compare two currencies codepoint for codepoint.
```

NOTE: watch host obligations — this atom sets no maximum length on the item reference and does not oblige the deployment to set one, the silence posture the *host obligations* row in `open-questions.md` counts.

Term cart: a set of lines gathered toward one purchase, with the currency their prices are counted in — a [Cart].

Term line: one item on a cart, with how many of the item and the unit price taken when the line was added — a [Line].

Term cart id: the opaque value naming one cart — a [Cart Id]; unique for the system's life.

Term line id: the opaque value naming one line — a [Line Id]; unique for the system's life, so an item added again after its line was taken out gets a new line id.

Term item reference: the value naming the item a line is for — a product or a service with the options chosen for it, such as a size, a color, oat milk or a gift wrap, in the deployment's own scheme — an [Item Reference]; the atom reads nothing in it.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects each cart id and line id here.

### State

```
State 1: EVERY cart MUST carry cart id and currency.
State 2: EVERY line MUST carry line id, cart id, item reference, quantity and unit price.
State 3: The atom MUST NOT remove a cart.
```

Term quantity: how many of the item a line holds — a [Quantity]; a positive count.

Term unit price: the price of one of the item, options included, supplied by the composing pattern that prices the item (Composition note 2) and taken from the call that added the line — a [Unit Price]; a whole amount.

Term currency: the unit of account a cart's prices and total are counted in, such as a code from ISO 4217 (the International Organization for Standardization's standard for currency codes) — a [Currency]; set when the cart is opened.

Term minor unit: the smallest unit of a currency — the cent of a euro, or the yen itself.

Term whole amount: a whole number of the cart currency's minor unit, zero or more.

Term positive count: a whole number, one or more.

Term total: the sum, over every line the cart carries, of (quantity * unit price) — a [Total]; zero for a cart carrying no line, counted in the cart currency's minor unit, computed at each [Read] and never stored.

NOTE: watch a term entry's kind — the total is computed at each read and never stored, yet its term entry takes `Kind: Field`, as a stored field's does.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply at the seam a cart id no cart has carried PER Execution Contract Logic confinement 3.
Capability requirement 2: The deployment MUST supply at the seam a line id no line has carried PER Execution Contract Logic confinement 3.
Capability requirement 3: The deployment MUST supply the accepted currencies.
Capability requirement 4: The deployment MUST compute EVERY total without loss.
Capability requirement 5: The deployment MUST supply the database PER Execution Contract Database 1 through 6, Execution Contract Read 1 through 4 and Execution Contract Refusal 1.
```

Term accepted currencies: the currencies the deployment sells in — the set [Open] checks a currency against.

### Operations

```
open(currency)
  answers cart_id
  refuses invalid-currency | storage-failure

add(cart_id, item_reference, quantity, unit_price)
  answers line_id
  refuses not-known | invalid-item-reference | invalid-quantity | invalid-price | already-in-cart | storage-failure

change_quantity(line_id, new_quantity)
  answers ok
  refuses not-known | invalid-quantity | storage-failure

remove(line_id)
  answers ok
  refuses not-known | storage-failure

clear(cart_id)
  answers ok
  refuses not-known | storage-failure

read(cart_id)
  answers cart
  refuses not-known
```

```
Operation 1: IF the currency IS NOT IN the accepted currencies THEN [Open] MUST answer invalid-currency.
Operation 2: [Open] MUST record EXACTLY ONE cart carrying the currency of the call.
Operation 3: [Open] MUST answer the cart id.
Operation 4: IF no cart EXISTS for the cart id THEN a cart action MUST answer not-known.
Operation 5: IF the item reference EQUALS blank THEN [Add] MUST answer invalid-item-reference.
Operation 6: IF the quantity IS NOT IN the positive counts THEN [Add] MUST answer invalid-quantity.
Operation 7: IF the unit price IS NOT IN the whole amounts THEN [Add] MUST answer invalid-price.
Operation 8: IF a line of the cart EXISTS for the item reference THEN [Add] MUST answer already-in-cart.
Operation 9: [Add] MUST record EXACTLY ONE line carrying the cart id, the item reference, the quantity and the unit price of the call.
Operation 10: [Add] MUST answer the line id.
Operation 11: IF no line EXISTS for the line id THEN a line action MUST answer not-known.
Operation 12: IF the new quantity IS NOT IN the positive counts THEN [Change Quantity] MUST answer invalid-quantity.
Operation 13: IF the new quantity DOES NOT EQUAL the line's quantity THEN [Change Quantity] MUST set quantity to the new quantity.
Operation 14: IF the new quantity EQUALS the line's quantity THEN [Change Quantity] MUST NOT write.
Operation 15: [Change Quantity] MUST answer ok.
Operation 16: [Remove] MUST remove the line.
Operation 17: [Remove] MUST answer ok.
Operation 18: [Clear] MUST remove EVERY line of the cart.
Operation 19: [Clear] MUST answer ok.
Deleted: Operation 20. Execution Contract Read 4 owns it.
Operation 21: [Read] MUST answer the cart's currency, EVERY line of the cart AND the cart's total.
Operation 22: [Read] MUST answer a line's line id, item reference, quantity AND unit price.
Operation 23: [Read] MUST NOT write.
```

NOTE: watch host obligations — this atom sets no maximum number of lines on a cart and does not oblige the deployment to set one, the silence posture the *host obligations* row in `open-questions.md` counts.

NOTE: open 2026-10-24-b — whether the read answer carries the cart id: State 1 and Term records give every cart one, while Operation 21 lists the answer without it.

Term new quantity: the quantity a [Change Quantity] call sets — a [New Quantity]; a positive count.

Term cart action: [Add] | [Clear] | [Read] — the actions that name a cart by the cart id.

Term line action: [Change Quantity] | [Remove] — the actions that name a line by the line id.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the carts |
|---|---|---|---|
| [Open] | currency accepted, database accepts | the cart id | one cart lands, carrying the currency and no line (Operation 2) |
| [Open] | currency not accepted | [Invalid Currency] | none (Operation 1) |
| [Add] | inputs valid, no line for the item, database accepts | the line id | one line lands, carrying the call's item reference, quantity and unit price (Operation 9) |
| [Add] | item reference blank | [Invalid Item Reference] | none (Operation 5) |
| [Add] | quantity not a positive count | [Invalid Quantity] | none (Operation 6) |
| [Add] | unit price not a whole amount | [Invalid Price] | none (Operation 7) |
| [Add] | the cart already carries a line for the item | [Already In Cart] | none (Operation 8) |
| [Change Quantity] | new quantity a positive count, different from the line's | ok | the quantity changes; the unit price stands (Operation 13, Invariant 2.1) |
| [Change Quantity] | new quantity equal to the line's | ok | none — no write (Operation 14) |
| [Change Quantity] | new quantity not a positive count | [Invalid Quantity] | none (Operation 12) |
| [Remove] | the line is on a cart | ok | the line leaves the cart; its line id is retired (Operation 16, Identity 4) |
| [Clear] | the cart exists | ok | every line leaves the cart and its line id is retired; the cart stays (Operation 18, Identity 4, State 3) |
| a cart action or a line action | the id names nothing | [Not Known] | none (Operation 4, Operation 11) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| [Read] | the cart exists | the cart's currency, its lines and its total | none (Operation 21 through 23) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

### Invariants

- **Invariant 1 — One line per item.**
  ```
  Invariant 1.1: Two lines one cart carries MUST NOT share an item reference.
  ```
- **Invariant 2 — The price taken when added.**
  ```
  Invariant 2.1: The atom MUST NOT change a line's unit price.
  ```
- **Invariant 3 — A line keeps its cart and its item.**
  ```
  Invariant 3.1: The atom MUST NOT change a line's cart id.
  Invariant 3.2: The atom MUST NOT change a line's item reference.
  ```
- **Invariant 4 — A cart keeps its currency.**
  ```
  Invariant 4.1: The atom MUST NOT change a cart's currency.
  ```
- **Invariant 5 — Every line belongs to a cart.**
  ```
  Invariant 5.1: EVERY line's cart id MUST name a cart.
  ```
- **Invariant 6 — Counts and amounts stay whole.**
  ```
  Invariant 6.1: EVERY line MUST carry a positive count as the line's quantity.
  Invariant 6.2: EVERY line MUST carry a whole amount as the line's unit price.
  ```

## Examples

The same pattern in three domains, then the rejection paths. Amounts are whole numbers of the currency's minor unit, so `1999` in euros is €19.99.

### Online store

A shop selling in euros opens a cart: `open("EUR")` answers [Cart Id] `c1`. The shopper adds two T-shirts at €19.99 — `add(c1, "tee-blue-m", 2, 1999)` answers [Line Id] `l1`, and the [Total] is 3998. A mug at €12.50 — `add(c1, "mug-white", 1, 1250)` answers `l2`; the total is 5248. The shopper wants three T-shirts — `change_quantity(l1, 3)`; the total is 7247. That evening the shop raises the T-shirt to €24.99; line `l1` keeps 1999 and the total stays 7247. The shopper takes the mug out — `remove(l2)`; the total is 5997. The shop's checkout reads the cart — three T-shirts at 1999, total 5997 — places its order, and clears the cart: `clear(c1)` leaves `c1` with no line and a total of 0.

### Café tab

A café opens a tab for table 4 in US dollars — `open("USD")` answers `t4`. Two flat whites at $4.50 — `add(t4, "flat-white", 2, 450)` answers `l5` — and a croissant at $3.25 — `add(t4, "croissant", 1, 325)` answers `l6`: the total is 1225. A third flat white is ordered — `change_quantity(l5, 3)`; the total is 1675. Then a flat white with oat milk at $5.10 — `add(t4, "flat-white-oat", 1, 510)` answers `l10`, a second line beside `l5` at its own price, since an item reference names the item with its options; the total is 2185. The croissant goes back — `remove(l6)`; the total is 1860. At three o'clock the café's afternoon prices start; the tab's lines keep the prices they were taken at.

### Wholesale order

A distributor's buyer assembles an order of fasteners in yen, whose minor unit is the yen itself — `open("JPY")` answers `w1`. Five thousand bolts at ¥12 — `add(w1, "bolt-m8-40", 5000, 12)` answers `l9`; the total is 60000. Five thousand nuts at ¥4 — `add(w1, "nut-m8", 5000, 4)`; the total is 80000. The bolts go up to eight thousand — `change_quantity(l9, 8000)`; the total is 116000. A free sample kit — `add(w1, "sample-kit", 1, 0)` — is accepted at a unit price of zero, and the total stays 116000.

### Rejection paths

A deployment that accepts `"EUR"` and `"USD"`, exercising the rejection surface in one short sequence on cart `c9`, opened in euros:

- `open("XYZ")` — rejected as [Invalid Currency].
- `add(c9, "   ", 1, 500)` — rejected as [Invalid Item Reference]: the reference is blank.
- `add(c9, "pen", 0, 500)` — rejected as [Invalid Quantity]; so is a quantity of 2.5.
- `add(c9, "pen", 1, -100)` — rejected as [Invalid Price].
- `add(c9, "   ", 0, -100)` — rejected as [Invalid Item Reference]: three refusals apply, and the one listed first on [Add]'s refuses line answers (Execution Contract Refusal 1).
- `add(c9, "pen", 1, 500)` — accepted, line `l7`. A second `add(c9, "pen", 1, 450)` is rejected as [Already In Cart]: the caller changes `l7`'s quantity, or takes `l7` out and adds the pen again to take the new price.
- `add(c9, "Pen", 1, 500)` — accepted as a different item, line `l8`: two item references are compared codepoint for codepoint.
- `change_quantity(l7, 0)` — rejected as [Invalid Quantity]; a line leaves a cart by [Remove].
- `remove(l7)` — ok. Then `change_quantity(l7, 2)` — rejected as [Not Known]: the line id is retired.
- `add(c404, "pen", 1, 500)`, where no cart `c404` exists — rejected as [Not Known].

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

## Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor from the carts and lines the database holds, with their earlier versions (Execution Contract Database 5). The atom is not regulated and carries no adversarial scenarios.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY cart carrying cart id AND currency (State 1).
Check 1.2: An auditor MUST find EVERY line carrying line id, cart id, item reference, quantity AND unit price (State 2).
Check 2.1: An auditor MUST find no two carts sharing a cart id (Identity 3).
Check 2.2: An auditor MUST find no two lines sharing a line id (Identity 4).
Check 2.3: An auditor MUST find no two lines one cart carries sharing an item reference (Invariant 1.1).
Check 2.4: An auditor MUST find EVERY line's cart id naming a cart (Invariant 5.1).
Check 3.1: An auditor MUST find EVERY version of a line carrying the unit price of the line's first version (Invariant 2.1).
Check 3.2: An auditor MUST find EVERY version of a line carrying the cart id of the line's first version (Invariant 3.1).
Check 3.3: An auditor MUST find EVERY version of a line carrying the item reference of the line's first version (Invariant 3.2).
Check 3.4: An auditor MUST find EVERY version of a cart carrying the currency of the cart's first version (Invariant 4.1).
Check 4.1: An auditor MUST find EVERY line carrying a positive count as the line's quantity (Invariant 6.1).
Check 4.2: An auditor MUST find EVERY line carrying a whole amount as the line's unit price (Invariant 6.2).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing a line's unit price confirmed as the item's price when the line was added MUST read the records of the pattern that priced the item (Non-goal 1).
External check 2: An auditor needing an item reference confirmed as naming a real item MUST read the deployment's catalog (Non-goal 10).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT price an item.
Non-goal 2: The atom MUST NOT apply a discount.
Non-goal 3: The atom MUST NOT apply a tax.
Non-goal 4: The atom MUST NOT hold stock for a line.
Non-goal 5: A deployment needing stock held for a line MUST compose Provisional Commitment.
Non-goal 6: The atom MUST NOT take a payment.
Non-goal 7: The atom MUST NOT turn a cart into an order.
Non-goal 8: The atom MUST NOT close a cart.
Non-goal 9: The atom MUST NOT hold a cart's owner.
Non-goal 10: The atom MUST NOT check an item reference against a catalog.
Non-goal 11: The atom MUST NOT convert a currency.
Non-goal 12: The atom MUST NOT expire a cart.
Non-goal 13: The atom MUST NOT merge two carts.
Non-goal 14: The atom MUST NOT order lines.
Non-goal 15: The atom MUST NOT limit a quantity.
Non-goal 16: The atom MUST NOT read an item reference's options.
Non-goal 17: The atom MUST NOT apply a delivery charge.
```

NOTE: the owners — a pricing pattern *(forthcoming)* (Non-goal 1, Non-goal 2; External check 1); a tax pattern *(forthcoming)* (Non-goal 3); [Provisional Commitment](./provisional-commitment.md) (Non-goal 4, Non-goal 5); a payment pattern *(forthcoming)* (Non-goal 6); a checkout pattern *(forthcoming)* (Non-goal 7, Non-goal 8, Non-goal 13); the composing pattern that knows the shopper, such as one built on [Session](./session.md) or [Party Identity](./party-identity.md) (Non-goal 9); a catalog pattern *(forthcoming)* (Non-goal 10, Non-goal 16; External check 2); a currency pattern *(forthcoming)* (Non-goal 11); a cart-expiry pattern *(forthcoming)* (Non-goal 12); the composing pattern that shows the cart (Non-goal 14); a purchase-limit pattern *(forthcoming)* (Non-goal 15); a delivery pattern *(forthcoming)* (Non-goal 17).

Where the atom breaks down: a purchase whose lines are priced in more than one currency; a cart whose prices must follow the catalog as it changes.

## Edge cases

### Concurrency

Two calls adding one item to one cart are serialized by the database (Execution Contract Database 2): the later call reads the line the earlier one recorded and answers [Already In Cart], so the cart never carries two lines for one item (Invariant 1.1).

### Indeterminate outcome

A caller whose answer is lost may call again. Where no other call changed the cart in between, a repeated [Add] answers [Already In Cart] where the first landed, and [Read] then shows the line and its [Line Id]; a repeated [Change Quantity] or [Clear] leaves the cart as the first left it; a repeated [Remove] answers [Not Known] where the first landed; a repeated [Open] records a second cart, which carries no line. Where another call did change it, the repeat is decided afresh on what that call left (Execution Contract Database 2).

NOTE: watch the lost answer — a caller whose answer is lost cannot tell whether its call landed, an arm the Execution Contract's Error model does not name; this edge case says what calling again meets.

### A price that moves after the add

The line keeps the unit price taken at [Add] (Invariant 2.1). A composing pattern that must charge an item's current price takes the line out with [Remove] and adds the item again, which records a new line with a new [Line Id] carrying the new price; the earlier line's versions stay readable as they stood (Execution Contract Database 5).

## Composition notes

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern MUST supply a unit price in the cart's currency.
```

NOTE: composing patterns — none yet. Forthcoming: a checkout pattern, a pricing pattern and a catalog pattern.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a cart; a line; a cart action; a line action; an auditor.

Term records: cart — a set of lines gathered toward one purchase, carrying cart id and currency; line — one item on a cart, carrying line id, cart id, item reference, quantity and unit price.

Term record verbs: identify, reuse, normalize, compare, carry, remove, supply, compute, record, answer, set, write, take, share, change, name, find, read, price, apply, hold, compose, turn, close, check, convert, expire, merge, order, limit, own, refuse.

Term value sets: cart action and line action are declared above and cited here (GRACE-lang Closed vocabulary 15).

Term bounds: positive count (one, the floor of a quantity); whole amount (zero, the floor of a unit price).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.66 (2026-10-23).

Term terms: cart, line, cart id, line id, item reference, seam, quantity, new quantity, unit price, currency, minor unit, whole amount, positive count, total, accepted currencies, cart action, line action, version.

NOTE: open 2026-10-24-a — eight declared terms carry no term entry, where spec-format's Terms item asks one per declared term (Term terms).

#### Open

The behavior that starts a cart. It checks the [Currency] against the deployment's accepted currencies, records a cart carrying that currency and no line, and answers the new [Cart Id].

Kind: Operation

#### Add

The behavior that puts an item on a cart. It records one [Line] carrying the [Item Reference], the [Quantity] and the [Unit Price] the call supplied, and answers the new [Line Id]. An item already on the cart is refused, so a cart holds one line per item.

Kind: Operation

#### Change Quantity

The behavior that sets a line's [Quantity] to the [New Quantity]. The line's [Unit Price], [Item Reference] and cart are unchanged; a new quantity equal to the line's own writes nothing.

Kind: Operation

#### Remove

The behavior that removes one [Line] from its cart. The [Line Id] is retired and never reused.

Kind: Operation

#### Clear

The behavior that removes every [Line] from a cart. The [Cart] itself stays, with its [Currency], ready for more lines.

Kind: Operation

#### Read

The read-only query answering a cart: its [Currency], every [Line] it carries with each line's [Line Id], [Item Reference], [Quantity] and [Unit Price], and its [Total]. It changes nothing.

Kind: Operation

#### Cart

A set of lines gathered toward one purchase, with the [Currency] their prices are counted in. It is opened by [Open], changed by [Add], [Change Quantity], [Remove] and [Clear], and never closed or removed by the atom.

Kind: Type

#### Line

One item on a cart: its [Item Reference], its [Quantity] and the [Unit Price] taken when it was added. It is recorded by [Add] and leaves its cart by [Remove] or [Clear].

Kind: Type

#### Cart Id

The opaque, immutable identity of a cart, allocated by the host at the seam on [Open] and never reused.

Kind:       Field
Field of:   Cart
Projection: cart_id

#### Line Id

The opaque, immutable identity of a line, allocated by the host at the seam on [Add] and never reused. The [Item Reference] is not the line's identity: an item taken out and added again is a new line.

Kind:       Field
Field of:   Line
Projection: line_id

#### Item Reference

The value naming the item a line is for, in the deployment's own scheme: a product or a service with the options chosen for it, such as a size, a color, oat milk or a gift wrap, so a flat white and a flat white with oat milk are two items, held on one cart as two lines. The atom stores it as supplied, never normalizes it, never reads the options in it, and compares two of them codepoint for codepoint; whether it names a real item, and which options it names, is a catalog's question.

Kind:       Field
Field of:   Line
Projection: item_reference

#### Quantity

How many of the item a line holds: a whole number, one or more. Set by [Add] and changed by [Change Quantity].

Kind:       Field
Field of:   Line
Projection: quantity

#### New Quantity

The quantity a [Change Quantity] call sets on a line: a whole number, one or more. It is consumed by [Change Quantity], not stored under this name.

Kind:         Parameter
Parameter of: Change Quantity
Projection:   new_quantity

#### Unit Price

The price of one of the item, options included, as a whole number of the cart currency's minor unit, zero or more: the price the call that added the line supplied, from the composing pattern that prices the item. No action changes it.

Kind:       Field
Field of:   Line
Projection: unit_price

#### Currency

The unit of account a cart's prices and [Total] are counted in, such as an ISO 4217 code, set by [Open] from the deployment's accepted currencies and never changed. The atom stores it as supplied, never normalizes it, and compares two of them codepoint for codepoint.

Kind:       Field
Field of:   Cart
Projection: currency

#### Total

The sum, over every line a cart carries, of the line's [Quantity] times its [Unit Price], in the cart currency's minor unit; zero for a cart with no line. It is computed at each [Read] and never stored, so it cannot lag the lines.

Kind:       Field
Field of:   Cart
Projection: total

#### Invalid Currency

The refusal [Open] returns when the [Currency] is not one the deployment accepts. No cart is recorded.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-currency

#### Not Known

The refusal [Add], [Clear] or [Read] returns when the [Cart Id] names no cart, and [Change Quantity] or [Remove] when the [Line Id] names no line on any cart.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Invalid Item Reference

The refusal [Add] returns when the [Item Reference] is blank. No line is recorded.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-item-reference

#### Invalid Quantity

The refusal [Add] returns when the [Quantity], and [Change Quantity] when the [New Quantity], is not a whole number of one or more. Nothing changes.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-quantity

#### Invalid Price

The refusal [Add] returns when the [Unit Price] is not a whole number of zero or more. No line is recorded.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-price

#### Already In Cart

The refusal [Add] returns when the cart already carries a line for the [Item Reference]. No line is recorded; the caller changes that line's quantity, or takes it out and adds the item again.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: already-in-cart

#### Storage Failure

The refusal [Open], [Add], [Change Quantity], [Remove] or [Clear] returns when the database refuses its write after every precondition passes — the Execution Contract's Step 3 failure. Nothing is written.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Open]: #open
[Add]: #add
[Change Quantity]: #change-quantity
[Remove]: #remove
[Clear]: #clear
[Read]: #read
[Cart]: #cart
[Line]: #line
[Cart Id]: #cart-id
[Line Id]: #line-id
[Item Reference]: #item-reference
[Quantity]: #quantity
[New Quantity]: #new-quantity
[Unit Price]: #unit-price
[Currency]: #currency
[Total]: #total
[Invalid Currency]: #invalid-currency
[Not Known]: #not-known
[Invalid Item Reference]: #invalid-item-reference
[Invalid Quantity]: #invalid-quantity
[Invalid Price]: #invalid-price
[Already In Cart]: #already-in-cart
[Storage Failure]: #storage-failure

---

## Standards references

Cart is a primitive, not a regulated business pattern, and has no regulatory anchor of its own. It inherits from:

- **ISO 4217** (the International Organization for Standardization's standard for currency codes) — the codes a currency is commonly named by, and the minor unit every amount on a cart is counted in.
- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design, and the discipline of not absorbing pricing, stock and checkout, each a concept of its own.

Rules on how a price is shown and confirmed to a buyer before a purchase, such as the European Union's Consumer Rights Directive (2011/83/EU), bind the checkout that composes this atom, not the cart.

---

## Status

`grounded on Final Critique 4 — 2026-10-24` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-10-24
formal: not applicable — vote no 2026-10-23: the atom reads no clock and claims no ordering of its own; its one-line-per-item and fixed-price claims are single-state properties each action's rules hold, and its concurrency is Execution Contract Database 2's
last gate: 2026-10-24 — Final Critique 4, the page's first gate round after the 3×3 baseline, three fresh readers (GRID GLM-5.3 Flash on OpenCode Go; EOS MiniMax M3 on OpenCode Go; Linus Mercury 3), each handed only the round's reading set, three passes on one text (frozen at 460866f); the round rests on three counted passes — foundational count 0, held by the blind second triage (2026-10-24, one cold reader given the round's 25 reports, the method's test and the placement rule, and neither the threshold nor what the count decides, which placed none of them foundational); 2 foundational reports, both rejected (the answer ok resolves to the signature block that declares it; a read's total is held to the records by Execution Contract Conformance 6, and no record carries it for a check to read); 17 refining reports, 6 rhetorical reports; clean; two refining findings cured, one routed to a new open line, one answered by its open line, one by its watch flag, and one carried to the maintainer; one sample; 2026-10-24 — Round 3, the last of the 3×3 baseline — foundational count 0, held by the blind second triage, clean, one sample; 2026-10-24 — Round 2 — foundational count 1, set by the blind second triage, cured, not clean; 2026-10-24 — Round 1, the foundation — foundational count 0, held by the blind second triage, clean, one sample

open:
- 2026-10-24-a · refining · Term terms; Vocabulary · eight declared terms (seam, minor unit, whole amount, positive count, accepted currencies, cart action, line action, version) carry no term entry, where spec-format's Terms item asks one per declared term and every specification writes one per name a bracket marker lands on → add the entries, each with a Kind the term entry grammar admits, or read the item as the bracketed names
- 2026-10-24-b · refining · Operation 21; Term cart; Term records · [Read] answers cart, which State 1 and Term records give a cart id and Term cart, Operation 21 and the Read entry do not, so a build echoes the caller's cart id or not by the reading it picks, as readers in each of the last three rounds asked → name the cart id in Operation 21, or say the answer leaves the caller's own id out
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/cart.md`.

- **2026-10-23 — Drafted in GRACE lang v0.66, the first pattern written against the Database contract from the start.** *Chose:* a Cart atom, the corpus's first e-commerce pattern, drafted on the maintainer's ruling of 2026-10-23, drafting begun 2026-10-23 17:47Z (when the rewrite unit that writes it was claimed), so its rounds to ground are counted from that instant; the Database, Read and Refusal families cited once (Capability requirement 5) and restated nowhere, the Intent the page's one WHY, and no clock read anywhere. *Over:* a cart folded into a checkout or order pattern, or a page drafted in the prose shape and migrated later. *Because:* the ruling asks what a pattern written from the start against the Database contract, the Read and Refusal families, the admitted terms and GRACE lang v0.66 costs to ground; the method's EOS test keeps one freestanding concept, a set of priced lines and their total, and names an owner for pricing, tax, stock, payment and checkout (Non-goal 1 through 15).
- **2026-10-23 — A line keeps the price taken when it was added, and a cart holds one line per item.** *Chose:* [Add] records the unit price its call supplies and no action changes it (Invariant 2.1); an item already on the cart is refused as already-in-cart (Operation 8, Invariant 1.1); a line is named by an opaque line id, never by its item reference (Identity 2, Identity 5), so an item taken out and added again is a new line at the new price; and [Change Quantity] sets a whole new quantity rather than adding to the old one. *Over:* a second [Add] of an item merging into the line already there, which leaves open whose price the merged units carry; lines named by their item reference, whose history would mix two prices once an item was taken out and added again; and quantity changes by difference, which a repeated call applies twice. *Because:* the ruling defines a line as an item reference, a quantity and the unit price taken when added; with one line per item and one price per line, the total moves only when a line is added, re-counted or taken out, and every version of a line carries the price its add took, which an auditor reads from the database's history (Execution Contract Database 5).
- **2026-10-23 — One currency per cart, amounts in its minor unit, and no checkout state.** *Chose:* [Open] fixes a cart's currency from the accepted currencies the deployment supplies (Capability requirement 3, Invariant 4.1); every unit price and the total are whole numbers of that currency's minor unit, the total computed at each read, never stored, and without loss (Capability requirement 4); and a cart has no lifecycle state, being neither closed nor removed by the atom (State 3, Non-goal 8), while a checkout reads the lines it takes inside its own transaction (Execution Contract Database 1 and Database 2). *Over:* a currency per line, which leaves a mixed cart with no total; amounts as decimals or floating-point numbers; and a checked-out state on the cart, which would fold the checkout's decision into the atom. *Because:* a sum is defined only over one unit of account, whole minor units add without rounding, and the database keeps every committed version of a cart and its lines readable (Execution Contract Database 5), so what a checkout took stays readable after the cart changes.
- **2026-10-24 — Round 1: a removed line leaves the records, the deployment's ids are fresh, and the storage-failure answer is the Execution Contract's.** *Chose:* [Remove] and [Clear] remove the line (Operation 16, Operation 18), the verb State 3 uses for a cart, where they had taken the line out of its cart; the deployment supplies a cart id no cart has carried and a line id no line has carried (Capability requirement 1, Capability requirement 2); Operation 13 sets a quantity only where the new quantity differs from the line's, beside Operation 14; Operation 20 deleted, since Execution Contract Read 4 answers a failed write with storage-failure for every specification; and the host named among the actors, where Term seam already says the host injects the ids. *Over:* removing every version of a removed line, an erasure the page declares nowhere, which would leave what a checkout took unreadable; a line state marking removed lines, a field the page has no need of; and a storage-failure rule of the page's own, which restated the contract the first Decisions entry says the page cites and restates nowhere. *Because:* the round's two triages upheld no foundational gap. The text already decided a removed line's fate: no field can mark a line out of its cart, so Operation 16 is obeyed only by the line's leaving the database's current records, and Execution Contract Database 5 keeps its versions readable. A unit price is a whole number of the cart currency's minor unit, which no call can carry in another currency. What the readers found was text a step short of saying what it decides, cured in place, and an item reference no length bounds, the host obligations pressure the Watch list counts.
- **2026-10-24 — An item reference names the item with its options.** *Chose:* under the maintainer's ruling of 2026-10-23 22:50Z, a line is one configured item: the item reference names a product or a service with the options chosen for it, in the deployment's own scheme (Term item reference), so Invariant 1.1 and Operation 8, unchanged in wording, hold one line per configured item, and a flat white and a flat white with oat milk are two lines at two prices, as the café tab shows; the unit price is the configured item's, options included, supplied by the composing pattern that prices the item (Term unit price, Composition note 2); and the atom reads no option in an item reference (Non-goal 16), which leaves the options to a catalog pattern. *Over:* options carried on the line as fields of the atom's own, which would make the atom read and compare what a catalog defines; and an item whose options its item reference cannot name, which the page had listed where the atom breaks down. *Because:* the atom stores an item reference as supplied and compares two of them codepoint for codepoint (Identity 6, Identity 7), so naming the options inside it costs the atom no rule, and an item taken with other options is another item, at its own price.
- **2026-10-24 — Round 2: one line per item counts the lines a cart carries, and delivery is declined by name.** *Chose:* Invariant 1.1 and Check 2.3 count the lines one cart carries, where they counted the lines of one cart; the case table gains a row for a failed read and one for a call more than one refusal fits, and its Clear row retires the cleared lines' ids as the Remove row does; Non-goal 17, the atom applies no delivery charge, owned by a delivery pattern *(forthcoming)*; Term writing action deleted, no rule having cited it since Round 1 deleted Operation 20, and the Storage Failure entry names the five actions; Term value sets cites GRACE-lang Closed vocabulary 15 by the grammar's name; and two watch flags, the total's term entry kind and the lines a cart carries, which nothing bounds. *Over:* removing every version of a removed line, so that no history shares an item reference with a live line, an erasure the page declares nowhere, which would leave what a checkout took unreadable; and an open line beside each flag, which would hold in a second place a question the Watch list and the *host obligations* row of `open-questions.md` hold. *Because:* the round's blind second triage placed one finding foundational. A removed line's versions stay readable as they stood and keep their cart id (Execution Contract Database 5, Invariant 3.1), and the auditor reads the records with their earlier versions, so after an item was taken out and added again, the path Term line id makes lawful, Check 2.3 read over the versions counted two lines of one cart for one item and failed a conforming deployment; only the term entries, which carry no obligation, said a removed line leaves its cart. The rule now counts what a cart carries, as Term total does. The Intent declines delivery beside tax, and spec-format names each declined responsibility with its owner; a decision table is the page's completeness argument, so it shows every case an action meets, the Execution Contract's answers among them.
- **2026-10-24 — Round 3: a currency is compared as supplied, and the rejection paths show a call several refusals fit.** *Chose:* the atom never normalizes a currency and compares two currencies codepoint for codepoint (Identity 8, Identity 9), as it treats an item reference (Identity 6, Identity 7), so a call's currency is among the accepted currencies only where it matches one of them codepoint for codepoint; the rejection paths gain `add(c9, "   ", 0, -100)`, which three refusals fit and the first listed on [Add]'s refuses line answers (Execution Contract Refusal 1); and open line 2026-10-24-a, the declared terms that carry no term entry, which the page shares with every specification. *Over:* a currency matched without regard to case, or read as a unit of account under more than one spelling, which the page's rules never named; External check 1 narrowed to any price the pricing pattern ever recorded for the item, which would no longer test that a line keeps the price taken when it was added; the checks restated as reading each record at its current version, which would let a line id reused after a removal pass Check 2.2; and an open line beside each watch flag, as Round 1 and Round 2 declined. *Because:* the round's two triages placed no finding foundational, so the baseline closes on a clean round, one sample. The method's third pass asks of every string the page takes what its rules are, case-sensitivity among them, and the page had answered it for the item reference alone; and the Testing model writes one guard test per refusal, so only an example, compiled into a sequence test, shows which refusal answers when several apply.
- **2026-10-24 — Final Critique 4: grounded on one sample; a version is declared, and a repeated call is read against what came between.** *Chose:* the status `grounded on Final Critique 4 — 2026-10-24`, on one sample, under the maintainer's ruling of 2026-10-23 22:51Z that a page meeting the section titled *What "grounded" means* in `pressure-testing.md` is grounded, with the Summary the atom shape asks of a grounded page, in four plain sentences; Term version, the record as it stood at one commit, which Check 3.1 through 3.4 read and Execution Contract Database 5 keeps; the Indeterminate outcome's repeated calls read where no other call changed the cart in between, and decided afresh on what such a call left (Execution Contract Database 2), the lost answer the Watch list counts; and open line 2026-10-24-b, whether [Read]'s answer carries the cart id. *Over:* a check that a read's total equals the sum of its lines, which would read a read's answer where every check reads the records, while Execution Contract Conformance 6 already holds a read to them; a second declaration of the answer ok, beside the signature block that declares it; Execution Contract Refusal 1 struck from Capability requirement 5, which cites the three families once, as the first Decisions entry chose; and the case table's refusal rows citing Execution Contract Read 4, which no table in the corpus does. *Because:* the round's two triages placed no finding foundational, the formal vote is cast (no), and both open lines are refining, so the page meets the bar on one clean round of three fresh passes, and its second round is owed as its first scheduled rescan. Each cure names what the page already obliged and changes no action's answer or write: the checks had read a version since the draft, and a repeat that meets another call's change meets it as the rules say. Readers in each of the last three rounds asked whether a read echoes the cart id, which State 1 gives every cart and Operation 21 leaves out of the answer, so the question now stands on the page until it is decided.

NOTE: End of Cart.
