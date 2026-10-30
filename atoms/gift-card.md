---
title: Gift Card
parent: Atomic Concepts
has_toc: true
toc: true
---

# Gift Card

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Gift Card is a store gift card: a gift card loaded once with a value in one currency, then spent down, in part or in full, until nothing is left. Whoever holds the gift card's code can spend it, so the code is drawn at random where nobody can guess it, and the seller's own records name the gift card by a separate card id that spends nothing. A spend takes exactly the amount asked or is refused, so a balance never goes below zero, and nothing ever raises a balance: the gift card is never reloaded, never refunded to, never cancelled, never expires and carries no fee. Applying a gift card to a purchase, splitting a payment between a gift card and another method, refunds, and loyalty features such as reloading or transferring a balance each belong to another pattern, which is why one gift card serves an online store, a café and a bookshop alike.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

A shop sells stored value a person can give away, and the shape recurs wherever a shop sells gift cards: a value loaded once, a code whose holder may spend it, and a balance that only goes down. This atom is that and nothing more. Two decisions carry the weight. A spend takes exactly the amount asked or is refused, so a call means one thing and a balance never goes below zero; a checkout that wants to use up a gift card spends the balance it reads and charges the rest elsewhere. And nothing raises a balance, so a gift card that reaches zero is used up for good; reloading, transfer and refunds to a gift card make a loyalty card system, a different concept.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a gift card by the card id.
Identity 2: The atom MUST find a gift card by the card code.
Identity 3: The card code MUST serve as the bearer credential [Check Balance] accepts.
Identity 4: The card code MUST serve as the bearer credential [Spend] accepts.
Identity 5: The atom MUST NOT reuse a card id.
Identity 6: The atom MUST NOT reuse a card code.
Identity 7: The atom MUST NOT normalize a card code.
Identity 8: The atom MUST compare two card codes codepoint for codepoint.
Identity 9: The atom MUST NOT normalize a currency.
Identity 10: The atom MUST compare two currencies codepoint for codepoint.
```

Term gift card: one stored value loaded once in one currency and spent down — a [Gift Card].

Term card id: the opaque value naming one gift card in the seller's records — a [Card Id]; unique for the system's life, and it spends nothing.

Term card code: the random value whose holder may spend a gift card — a [Card Code]; unique for the system's life, answered once, by [Issue].

Term code entropy: 64 bits, the least random material a card code carries.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects each card id and card code here.

### State

```
State 1: EVERY gift card MUST carry card id, card code, currency, value and balance.
State 2: The atom MUST NOT remove a gift card.
```

Term value: the amount a gift card was loaded with at [Issue] — a [Value]; a positive amount.

Term balance: the amount left on a gift card — a [Balance]; a whole amount, the value less every spend.

Term currency: the unit of account a gift card's value and balance are counted in, such as a code from ISO 4217 (the International Organization for Standardization's standard for currency codes) — a [Currency]; set when the gift card is issued.

Term minor unit: the smallest unit of a currency — the cent of a dollar, or the yen itself.

Term whole amount: a whole number of the gift card currency's minor unit, zero or more.

Term positive amount: a whole amount of one or more.

Term used up: a gift card carrying a balance of zero.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply at the seam a card id no gift card has carried PER Execution Contract Logic confinement 3.
Capability requirement 2: The deployment MUST supply at the seam a card code no gift card has carried PER Execution Contract Logic confinement 3.
Capability requirement 3: The deployment MUST draw a card code from a cryptographically secure random source.
Capability requirement 4: The card code's random material MUST NOT fall below the code entropy.
Capability requirement 5: The deployment MUST supply the accepted currencies.
Capability requirement 6: The deployment MUST supply the card cap for EVERY accepted currency.
Capability requirement 7: The deployment MUST supply the database PER Execution Contract Database 1 through 6, Execution Contract Read 1 through 4 and Execution Contract Refusal 1.
```

Term accepted currencies: the currencies the deployment sells gift cards in — the set [Issue] checks a currency against.

Term card cap: the largest value the deployment issues a gift card for in one currency, such as 50000 in US dollars, which is $500 — a [Card Cap]; a positive amount.

### Operations

```
issue(currency, value)
  answers issued(card_id, card_code)
  refuses invalid-currency | invalid-value | over-cap | storage-failure

check_balance(card_code)
  answers balance
  refuses not-known

spend(card_code, amount)
  answers balance
  refuses not-known | invalid-amount | insufficient-balance | storage-failure

read(card_id)
  answers gift card
  refuses not-known
```

```
Operation 1: IF the currency IS NOT IN the accepted currencies THEN [Issue] MUST answer invalid-currency.
Operation 2: IF the value IS NOT IN the positive amounts THEN [Issue] MUST answer invalid-value.
Operation 3: IF the value EXCEEDS the card cap of the currency THEN [Issue] MUST answer over-cap.
Operation 4: [Issue] MUST record EXACTLY ONE gift card carrying the currency and the value of the call.
Operation 5: [Issue] MUST set the gift card's balance to the value.
Operation 6: [Issue] MUST answer the card id AND the card code.
Operation 7: IF no gift card EXISTS for the card code THEN a code action MUST answer not-known.
Operation 8: [Check Balance] MUST answer the gift card's balance AND the gift card's currency.
Operation 9: [Check Balance] MUST NOT write.
Operation 10: IF the amount IS NOT IN the positive amounts THEN [Spend] MUST answer invalid-amount.
Operation 11: IF the amount EXCEEDS the gift card's balance THEN [Spend] MUST answer insufficient-balance.
Operation 12: [Spend] MUST set balance to (the gift card's balance - the amount).
Operation 13: [Spend] MUST answer the gift card's new balance.
Operation 14: IF no gift card EXISTS for the card id THEN [Read] MUST answer not-known.
Operation 15: [Read] MUST answer the gift card's card id, currency, value AND balance.
Operation 16: [Read] MUST NOT answer the card code.
Operation 17: [Read] MUST NOT write.
```

Term amount: what a [Spend] call takes from a gift card, in the gift card's currency — an [Amount]; a positive amount.

Term code action: [Check Balance] | [Spend] — the actions that name a gift card by the card code.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the gift cards |
|---|---|---|---|
| [Issue] | currency accepted, value within the card cap, database accepts | the card id and the card code | one gift card lands, its balance the value (Operation 4, Operation 5) |
| [Issue] | currency not accepted | [Invalid Currency] | none (Operation 1) |
| [Issue] | value not a positive amount | [Invalid Value] | none (Operation 2) |
| [Issue] | value over the card cap | [Over Cap] | none (Operation 3) |
| [Check Balance] | the code names a gift card | the balance and the currency | none (Operation 8, Operation 9) |
| [Spend] | amount a positive amount, within the balance, database accepts | the new balance | the balance falls by the amount (Operation 12) |
| [Spend] | amount not a positive amount | [Invalid Amount] | none (Operation 10) |
| [Spend] | amount over the balance | [Insufficient Balance] | none (Operation 11, Invariant 4.1) |
| a code action | the code names nothing | [Not Known] | none (Operation 7) |
| [Read] | the card id names a gift card | the card id, currency, value and balance, never the code | none (Operation 15 through 17) |
| [Read] | the card id names nothing | [Not Known] | none (Operation 14) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

### Invariants

- **Invariant 1 — The balance never goes below zero.**
  ```
  Invariant 1.1: EVERY gift card MUST carry a whole amount as the gift card's balance.
  ```
- **Invariant 2 — Nothing raises a balance.**
  ```
  Invariant 2.1: The atom MUST NOT raise a gift card's balance.
  Invariant 2.2: A gift card's balance MUST NOT EXCEED the gift card's value.
  ```
- **Invariant 3 — A gift card keeps its code, its currency and its value.**
  ```
  Invariant 3.1: The atom MUST NOT change a gift card's card code.
  Invariant 3.2: The atom MUST NOT change a gift card's currency.
  Invariant 3.3: The atom MUST NOT change a gift card's value.
  ```
- **Invariant 4 — A refused spend takes nothing.**
  ```
  Invariant 4.1: A refused [Spend] MUST NOT change a gift card's balance.
  ```

## Examples

The same pattern in two domains, then the rejection paths. Amounts are whole numbers of the currency's minor unit, so `5000` in US dollars is $50.00.

### Online store

A shop selling gift cards in US dollars, with a card cap of 50000 ($500), sells a $50 gift card: `issue("USD", 5000)` answers `issued(g1, "7KQ9M2XV4RTP8HNC")`. The buyer gives the code away. The recipient checks it — `check_balance("7KQ9M2XV4RTP8HNC")` answers 5000 in US dollars — and spends $32.18 on an order: `spend("7KQ9M2XV4RTP8HNC", 3218)` answers 1782. On the next visit the order comes to $21.82; the shop's checkout reads the balance, spends all of it — `spend("7KQ9M2XV4RTP8HNC", 1782)` answers 0 — and charges the remaining $4.00 to another payment. The gift card is used up. The shop's support desk reads the gift card by its id — `read(g1)` answers US dollars, a value of 5000 and a balance of 0, and no code.

### Bookshop

A bookshop in euros sells a €20 gift card: `issue("EUR", 2000)` answers `issued(b7, "Q4WN8ZT2HC6PLM3R")`. A paperback at €9.50 — `spend("Q4WN8ZT2HC6PLM3R", 950)` answers 1050. A notebook at €4.25 — `spend("Q4WN8ZT2HC6PLM3R", 425)` answers 625. The €6.25 left stays on the gift card as long as the shop keeps the gift card, since a gift card never expires.

### Rejection paths

A deployment that accepts `"USD"` with a card cap of 50000, and gift card `g1` above holding a balance of 1782:

- `issue("XYZ", 5000)` — rejected as [Invalid Currency].
- `issue("USD", 0)` — rejected as [Invalid Value]; so is a value of -500.
- `issue("USD", 60000)` — rejected as [Over Cap]: $600 is over the $500 cap.
- `spend("7KQ9M2XV4RTP8HNC", 0)` — rejected as [Invalid Amount].
- `spend("7KQ9M2XV4RTP8HNC", 2000)` — rejected as [Insufficient Balance]; the balance stays 1782 (Invariant 4.1), and a checkout spends 1782 and charges the rest elsewhere.
- `spend("7kq9m2xv4rtp8hnc", 100)` — rejected as [Not Known]: two codes are compared codepoint for codepoint, and the atom normalizes none (Identity 7, Identity 8).
- `check_balance("NOSUCHCODE000000")` — rejected as [Not Known].
- `read(g404)`, where no gift card `g404` exists — rejected as [Not Known].

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

## Generation acceptance

Acceptable when the checks below are provable to an external auditor from the gift cards the database holds, with their earlier versions (Execution Contract Database 5). The atom carries no adversarial scenarios: it neither expires a gift card nor charges a fee, the two acts the federal gift card rule regulates (Non-goal 6, Non-goal 7).

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY gift card carrying card id, card code, currency, value AND balance (State 1).
Check 2.1: An auditor MUST find no two gift cards sharing a card id (Identity 5).
Check 2.2: An auditor MUST find no two gift cards sharing a card code (Identity 6).
Check 3.1: An auditor MUST find EVERY gift card carrying a whole amount as the gift card's balance (Invariant 1.1).
Check 3.2: An auditor MUST find no version of a gift card whose balance EXCEEDS the balance of the gift card's previous version (Invariant 2.1).
Check 3.3: An auditor MUST find no gift card whose balance EXCEEDS the gift card's value (Invariant 2.2).
Check 4.1: An auditor MUST find EVERY version of a gift card carrying the card code of the gift card's first version (Invariant 3.1).
Check 4.2: An auditor MUST find EVERY version of a gift card carrying the currency of the gift card's first version (Invariant 3.2).
Check 4.3: An auditor MUST find EVERY version of a gift card carrying the value of the gift card's first version (Invariant 3.3).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor MUST clear from the deployment's own random source that EVERY card code is drawn from a cryptographically secure random source carrying the code entropy (Capability requirement 3, Capability requirement 4).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT reload a gift card.
Non-goal 2: The atom MUST NOT split a gift card.
Non-goal 3: The atom MUST NOT transfer a gift card's balance.
Non-goal 4: The atom MUST NOT refund to a gift card.
Non-goal 5: The atom MUST NOT cancel a gift card.
Non-goal 6: The atom MUST NOT expire a gift card.
Non-goal 7: The atom MUST NOT charge a fee.
Non-goal 8: The atom MUST NOT apply a gift card to a purchase.
Non-goal 9: The atom MUST NOT split a payment.
Non-goal 10: The atom MUST NOT convert a currency.
Non-goal 11: The atom MUST NOT limit attempts to guess a card code.
Non-goal 12: The atom MUST NOT report an unclaimed balance.
Non-goal 13: The atom MUST NOT hold a gift card's owner.
Non-goal 14: The atom MUST NOT take a payment for a gift card.
Non-goal 15: The atom MUST NOT tell a repeated spend from a new spend.
```

NOTE: the owners — Loyalty Card *(forthcoming)* (Non-goal 1, 2, 3, 5); Payment *(forthcoming)* (Non-goal 4, 14); none, by the maintainer's ruling of 2026-10-30, a plain gift card that never expires and carries no fee (Non-goal 6, 7); Checkout *(forthcoming)* (Non-goal 8, 9); Currency *(forthcoming)* (Non-goal 10); Rate Limit *(forthcoming)* (Non-goal 11); the deployment, under the unclaimed-property law of its state (Non-goal 12); the composing pattern that knows the holder, such as one built on [Session](./session.md) or [Party Identity](./party-identity.md) (Non-goal 13); [Duplicate Prevention](./duplicate-prevention.md) (Non-goal 15).

Where the atom breaks down: a gift card meant to be reloaded, shared, or refunded to, which is a loyalty card system; a gift card spent across currencies.

## Edge cases

### Concurrency

Two spends on one gift card are serialized (Execution Contract Database 2): the later reads the balance the earlier left and is refused as [Insufficient Balance] if its amount is over it, so two spends never both take the last of a balance (Invariant 1.1).

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Spend] where the first landed takes the amount a second time, or is refused as [Insufficient Balance]; so a caller whose answer to [Spend] is lost calls [Check Balance] before it spends again, and a composing pattern needing a repeat to take the amount once composes Duplicate Prevention (Non-goal 15). A repeated [Issue] records a second gift card.

## Composition notes

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern MUST spend a gift card in the gift card's currency.
```

NOTE: composing patterns — none yet. Forthcoming: Checkout.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a gift card; a code action; an auditor.

Term records: gift card — one stored value loaded once in one currency, carrying card id, card code, currency, value and balance.

Term record verbs: identify, find, serve, reuse, normalize, compare, carry, remove, supply, draw, fall, record, set, answer, write, raise, change, spend, take, share, read, reload, split, transfer, refund, cancel, expire, charge, apply, convert, limit, report, hold, tell, own, clear, refuse.

Term value sets: code action is declared above and cited here (GRACE-lang Closed vocabulary 15).

Term bounds: positive amount (one, the floor of a value and an amount); whole amount (zero, the floor of a balance); code entropy (64 bits, the floor of a card code's random material).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.69 (2026-10-30) through the Grace connector.

Term terms: gift card, card id, card code, code entropy, seam, value, balance, currency, minor unit, whole amount, positive amount, used up, accepted currencies, card cap, amount, code action, version.

#### Issue

Starts a gift card: checks the [Currency] against the accepted currencies and the [Value] against the [Card Cap], records a gift card whose [Balance] is its value, and answers the new [Card Id] and [Card Code]. The only action that ever answers the code.

Kind: Operation

#### Check Balance

Answers what is left on a gift card, its [Balance] and [Currency], for the [Card Code] presented, and changes nothing.

Kind: Operation

#### Spend

Takes an [Amount] from a gift card, named by its [Card Code], and answers the new [Balance]. An amount over the balance is refused, and the balance stays as it was.

Kind: Operation

#### Read

Answers a gift card for the seller's records, named by its [Card Id]: its [Currency], [Value] and [Balance], never its [Card Code]; changes nothing.

Kind: Operation

#### Gift Card

One stored value, loaded once by [Issue] in one [Currency] and spent down by [Spend]; never reloaded, cancelled or removed by the atom.

Kind: Type

#### Card Id

The opaque, immutable identity of a gift card in the seller's records, allocated by the host at the seam on [Issue], never reused; it spends nothing.

Kind:       Field
Field of:   Gift Card
Projection: card_id

#### Card Code

The random value whose holder may spend a gift card, allocated by the host at the seam on [Issue] from a cryptographically secure random source, with at least 64 bits of random material; never reused, never changed, answered only by [Issue], stored as supplied and compared codepoint for codepoint.

Kind:       Field
Field of:   Gift Card
Projection: card_code

#### Value

The amount a gift card was loaded with: a whole number of the gift card currency's minor unit, one or more, no more than the [Card Cap]; set by [Issue], never changed.

Kind:       Field
Field of:   Gift Card
Projection: value

#### Balance

What is left on a gift card: a whole number of the gift card currency's minor unit, zero or more, never more than the [Value]; set to the value by [Issue], lowered only by [Spend].

Kind:       Field
Field of:   Gift Card
Projection: balance

#### Currency

The unit of account a gift card's [Value] and [Balance] are counted in, such as an ISO 4217 code; set by [Issue] from the accepted currencies, never changed, stored as supplied and compared codepoint for codepoint.

Kind:       Field
Field of:   Gift Card
Projection: currency

#### Amount

What a [Spend] call takes from a gift card, a whole number of the gift card currency's minor unit, one or more; not stored.

Kind:         Parameter
Parameter of: Spend
Projection:   amount

#### Card Cap

The largest [Value] the deployment issues a gift card for in one [Currency], such as 50000 in US dollars, which is $500.

Kind:       Parameter
Parameter of: Issue
Projection: card_cap

#### Invalid Currency

[Issue]'s refusal of a [Currency] the deployment does not accept.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-currency

#### Invalid Value

[Issue]'s refusal of a [Value] that is not a whole number of one or more.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-value

#### Over Cap

[Issue]'s refusal of a [Value] over the [Card Cap] of its currency.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: over-cap

#### Not Known

The refusal of a [Card Code] naming no gift card, on [Check Balance] or [Spend], or of a [Card Id] naming no gift card, on [Read].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Invalid Amount

[Spend]'s refusal of an [Amount] that is not a whole number of one or more.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-amount

#### Insufficient Balance

[Spend]'s refusal of an [Amount] over the gift card's [Balance]; the balance stays as it was, and the caller spends no more than the balance.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: insufficient-balance

#### Storage Failure

The refusal [Issue] or [Spend] answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Issue]: #issue
[Check Balance]: #check-balance
[Spend]: #spend
[Read]: #read
[Gift Card]: #gift-card
[Card Id]: #card-id
[Card Code]: #card-code
[Value]: #value
[Balance]: #balance
[Currency]: #currency
[Amount]: #amount
[Card Cap]: #card-cap
[Invalid Currency]: #invalid-currency
[Invalid Value]: #invalid-value
[Over Cap]: #over-cap
[Not Known]: #not-known
[Invalid Amount]: #invalid-amount
[Insufficient Balance]: #insufficient-balance
[Storage Failure]: #storage-failure

---

## Standards references

Gift Card is a primitive whose regulatory anchor it deliberately stays clear of. It inherits from:

- **15 U.S.C. 1693l-1 and Regulation E (12 CFR 1005.20)** — the federal gift card rule, which limits when a gift card's money may expire and when an inactivity fee may be charged. A gift card under this atom never expires and carries no fee (Non-goal 6, Non-goal 7), so the rule's two limits are never reached.
- **FinCEN's prepaid access rule** — store gift cards are mostly outside it below $2,000 per device per day; the card cap is the deployment's to set (Capability requirement 6).
- **ISO 4217** — the codes a currency is commonly named by, and the minor unit every amount on a gift card is counted in.
- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design, leaving payment, checkout and loyalty to concepts of their own.

State unclaimed-property laws, which may oblige a seller to report a balance left long unused, bind the deployment, not the gift card (Non-goal 12).

---

## Status

`draft` — see the Ledger.

## Ledger

```
status: draft
formal: not applicable — vote no 2026-10-30: the atom reads no clock and claims no ordering of its own; its balance, code, currency and value claims are properties each action's rules hold, and its concurrency is Execution Contract Database 2's
last gate: none

open: none
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only; everything smaller lives in `git log -- atoms/gift-card.md`.

- **2026-10-30 — Drafted through the Grace connector from the maintainer's interview, mirroring Cart.** *Chose:* a plain gift card, loaded once and spent down (the maintainer, 2026-10-30: "it is a simple gift card concept"; "it is loaded once and used"); a card id for the seller's records beside a random card code its holder spends with (Identity 1 through 4, Operation 16); a spend taking exactly the amount asked or refused (Operation 11, Invariant 4.1); no reload, split, transfer, refund to a gift card or cancelling, which the maintainer placed in a loyalty card system, and no expiry or fee (Non-goal 1 through 7); the card cap the deployment's, per currency (Capability requirement 6), the $500 consumer cap the maintainer named appearing in the examples. *Over:* a gift card named by its code alone, as Capability's token names a capability (the seller's records would carry the secret that spends the gift card); a spend taking what is left when the amount is over the balance (one call would mean two things); a stored used-up state (a balance of zero already says it). *Because:* the EOS test keeps one freestanding concept, a value spent down, and names an owner for everything a store layers on it (Non-goal 1 through 15); with nothing raising a balance and every spend exact, a balance is always the value less the spends an auditor reads from the gift card's versions (Execution Contract Database 5).

</details>

NOTE: End of Gift Card.
