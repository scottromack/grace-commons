---
title: Money
id: 63
parent: Atomic Concepts
has_toc: true
toc: true
---

# Money

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Money is an amount of money as a value: a whole number of a currency's smallest unit, together with the currency. Because the amount is a whole number of minor units and never a decimal, nothing rounds by accident. Two moneys in the same currency are added, subtracted and compared; a money is negated, which turns a charge into its refund; a money is multiplied by a rate, with the rounding named on every call; and a money is split into parts by shares, where the parts always add back up to the original and no part is a whole minor unit off its exact share. Money refuses to mix two currencies, refuses a multiply that names no rounding, refuses a split into more parts than the deployment allows, and refuses a number past the deployment's cap. An amount may be negative, and every rounding works on the size of an amount and keeps its sign, so a refund is always the exact negation of its charge. Money stores nothing: a cart, a gift card or a ledger entry holds a money and leans on these rules. Converting between currencies, knowing which currencies exist, pricing, tax, taking and refunding payment, settlement and the ledger each belong to another pattern.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Every pattern that moves value needs the same few facts, and each one that states them alone states them a little differently: Cart and Gift Card each say what a whole number of a minor unit is. This atom states those facts once, for the patterns that come to lean on it; Cart and Gift Card keep their own statements until the maintainer reopens them (Composition notes). Four decisions carry the weight. A rate is a number and never a money, and a rounding is named on every multiply, so no amount is rounded where a law or a contract did not say to. Every rounding and every split works on the size of an amount and keeps the sign, so a refund is the exact negation of its charge. The minor units a split leaves over go, in the order the caller gave, only to the parts the rounding down took from: a part due a whole number of minor units is never handed an extra one, which keeps every part under one minor unit from its exact share. That rule has a known lean: across repeated splits in one order the earlier parts come out ahead, and a caller who must spread the leftover turns the order of the shares. And the arithmetic is exact before anything is rounded or refused: under the default number cap the product of an amount and a numerator runs to thirty-six digits, so a build that multiplies in sixty-four bits overflows before the atom can refuse, and a build that refuses early refuses calls the atom admits.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a money by the money's currency AND the money's amount.
Identity 2: The atom MUST compare two currencies codepoint for codepoint.
Identity 3: The atom MUST NOT normalize a currency.
```

Term money: an amount in one currency — a [Money]; a value, held by the pattern that needs one. In a rule, the money is the money a call names first.

Term currency: the unit of account an amount is counted in, such as a code from ISO 4217 (the International Organization for Standardization's standard for currency codes) — a [Currency]; a string of one or more codepoints, held as supplied; a string of spaces is one, since which strings name a currency is Currency's to say (Non-goal 2).

NOTE: open 2026-11-13-a — a currency has no length bound (Term currency, Term well-formed money).

Term amount: how many of the currency's minor unit a money holds — an [Amount]; a whole number, negative, zero or positive.

Term minor unit: the smallest unit of a currency — the cent of a dollar, or the yen itself; for a code from ISO 4217, the unit that standard's minor unit exponent gives.

### State

```
State 1: EVERY money MUST carry currency and amount.
State 2: The atom MUST NOT store a money.
```

Term whole number: a number with no fraction — negative, zero or positive.

Term positive count: a whole number, one or more.

Term size: a whole number without the sign — the size of -250 is 250; a money's size is the size of the money's amount.

Term negation: the whole number of the same size with the sign turned — the negation of 250 is -250, and zero is the negation of zero; a money's negation carries the money's currency and the negation of the money's amount.

### Capability requirement

```
Capability requirement 1: The deployment MAY declare the number cap PER Execution Contract Input 2.
Capability requirement 2: The deployment MAY declare the part cap PER Execution Contract Input 2.
Capability requirement 3: The deployment MUST NOT declare a number cap that the size of a money, a numerator, a denominator or a share a composing pattern holds EXCEEDS.
Capability requirement 4: The deployment MAY declare the number cap ONLY IF the number cap EXCEEDS 0.
Capability requirement 5: The deployment MAY declare the part cap ONLY IF the part cap EXCEEDS 0.
```

Term number cap: the largest size of a whole number a call names or answers, an amount, a numerator, a denominator or a share alike — a [Number Cap]; 999999999999999999 where a deployment declares none, which is eighteen digits — a default cap a deployment may override as Execution Contract Input 2 allows, though a call naming a number over the number cap answers invalid-money, invalid-rate or invalid-shares (Operation 1, Operation 2, Operation 12, Operation 13, Operation 19), this atom's own answers in place of Input 2's invalid-request.

Term part cap: the most shares one [Split] call names — a [Part Cap]; 1,000 where a deployment declares none, and a call over the part cap answers too-many-parts (Operation 17).

Term capped number: a whole number whose size is no more than the number cap.

Term capped count: a positive count that is no more than the number cap.

NOTE: the atom holds no record, so the floor Execution Contract Input 2 sets under a cap finds no record of the atom's own to protect; Capability requirement 3 carries the floor to the moneys, the numerators, the denominators and the shares the composing patterns hold, so no lowered cap leaves a held money refused as invalid-money, a held rate's number refused as invalid-rate or a held share refused as invalid-shares. A money a composing pattern comes to hold after a declaration is bounded by that pattern's own amount rules (Execution Contract Input 2, Composition note 1), and a call naming one over the cap answers invalid-money (Operation 1).

NOTE: watch the cap's floor (Capability requirement 4, Capability requirement 5). A number cap of zero refuses every nonzero amount and numerator, every denominator and every share, and a part cap of zero refuses every split, so each is held above zero as Execution Contract Input 2 holds a string cap.

NOTE: the atom asks the deployment for no database, no clock and no random source (State 2, Operation 23, Operation 24). An action reads no record, so Execution Contract Read 1 has no read of the atom's to answer (Operation 24).

### Operations

```
add(money, other_money)
  answers money
  refuses invalid-money | mixed-currency | over-cap

subtract(money, other_money)
  answers money
  refuses invalid-money | mixed-currency | over-cap

compare(money, other_money)
  answers order
  refuses invalid-money | mixed-currency

negate(money)
  answers money
  refuses invalid-money

multiply(money, numerator, denominator, optional rounding)
  answers money
  refuses invalid-money | invalid-rate | invalid-rounding | over-cap

split(money, shares)
  answers parts
  refuses invalid-money | too-many-parts | invalid-shares
```

```
Operation 1: IF the money IS NOT IN the well-formed moneys THEN an action MUST answer invalid-money.
Operation 2: IF the other money IS NOT IN the well-formed moneys THEN a pair action MUST answer invalid-money.
Operation 3: IF the other money's currency DOES NOT EQUAL the money's currency THEN a pair action MUST answer mixed-currency.
Operation 4: IF the sum's size EXCEEDS the number cap THEN [Add] MUST answer over-cap.
Operation 5: [Add] MUST answer EXACTLY ONE result carrying the sum as amount PER Execution Contract Logic confinement 9.
Operation 6: IF the difference's size EXCEEDS the number cap THEN [Subtract] MUST answer over-cap.
Operation 7: [Subtract] MUST answer EXACTLY ONE result carrying the difference as amount PER Execution Contract Logic confinement 9.
Operation 8: IF the other money's amount EXCEEDS the money's amount THEN [Compare] MUST answer less.
Operation 9: IF the money's amount EQUALS the other money's amount THEN [Compare] MUST answer equal.
Operation 10: IF the money's amount EXCEEDS the other money's amount THEN [Compare] MUST answer greater.
Operation 11: [Negate] MUST answer EXACTLY ONE result carrying the negation of the money's amount as amount.
Operation 12: IF the numerator IS NOT IN the capped numbers THEN [Multiply] MUST answer invalid-rate.
Operation 13: IF the denominator IS NOT IN the capped counts THEN [Multiply] MUST answer invalid-rate.
Operation 14: IF the rounding IS NOT IN the roundings, including a call without a rounding, THEN [Multiply] MUST answer invalid-rounding.
Operation 15: IF the rounded size EXCEEDS the number cap THEN [Multiply] MUST answer over-cap.
Operation 16: [Multiply] MUST answer EXACTLY ONE result carrying the rounded product as amount PER Execution Contract Logic confinement 9.
Operation 17: IF the share count EXCEEDS the part cap THEN [Split] MUST answer too-many-parts.
Operation 18: IF the share count EQUALS zero THEN [Split] MUST answer invalid-shares.
Operation 19: IF a share IS NOT IN the capped counts THEN [Split] MUST answer invalid-shares.
Operation 20: [Split] MUST answer EXACTLY ONE part PER share, in the order of the shares.
Operation 21: A first part MUST carry the part's stepped share as amount PER Execution Contract Logic confinement 9.
Operation 22: A part outside the first parts MUST carry the part's base share as amount PER Execution Contract Logic confinement 9.
Operation 23: An action MUST NOT write.
Operation 24: An action MUST NOT read a record.
```

Term action: [Add] | [Subtract] | [Compare] | [Negate] | [Multiply] | [Split] — every action of the atom; none writes and none reads a record.

Term pair action: [Add] | [Subtract] | [Compare] — the actions that name two moneys.

Term well-formed money: a value carrying a currency of one or more codepoints and a capped number as amount; an amount with a fraction, such as 10.5, is no whole number.

Term other money: the second money a pair action names — a [Money].

Term result: the money an [Add], a [Subtract], a [Negate] or a [Multiply] call answers — a [Money].

Term sum: the money's amount plus the other money's amount.

Term difference: the money's amount less the other money's amount.

Term order: less | equal | greater — how the money's amount stands against the other money's amount.

Term rate: a numerator and a denominator together, the pair a [Multiply] call scales a money by — a number and never a money; 8.25 percent is the numerator 825 with the denominator 10000.

Term numerator: the top of a rate — a [Numerator]; a capped number.

Term denominator: the bottom of a rate — a [Denominator]; a capped count.

Term product: the money's amount times the numerator — a whole number, kept exact however large.

Term quotient: the size of the product divided by the denominator, rounded down — how many whole times the denominator goes into the size.

Term remainder: the size of the product less the quotient times the denominator — what the division leaves over; zero or more, and below the denominator.

Term rounding: the rule a [Multiply] call names for the rounded size — a [Rounding]; one of the roundings, named on every call.

Term roundings: down | up | half-up | half-even — the four roundings. Each answers a rounded size from the quotient and the remainder and never reads a sign, so a money and the money's negation round to negations.

Term down: the rounded size is the quotient — toward zero.

Term up: the rounded size is the quotient, and one more where the remainder is above zero — away from zero.

Term half-up: the rounded size is the quotient, and one more where twice the remainder is the denominator or more — an exact half goes away from zero.

Term half-even: the rounded size is the quotient, and one more where twice the remainder is more than the denominator, or is the denominator with the quotient odd — an exact half goes to the even whole number.

Term rounded size: the size the rounding the call names answers.

Term rounded product: the rounded size, negated where the product is below zero.

Term shares: the list of capped counts a [Split] call names, one per part — the [Shares]; a part is due the part's share out of the share total.

Term share count: the number of shares one [Split] call names.

Term share total: the shares of one [Split] call, added up.

Term part: one money a [Split] call answers — a [Money]; the part's share is the share at the part's place in the shares.

Term parts: every part of one [Split] answer, in the order of the shares.

Term share product: the money's size times the part's share — a whole number, kept exact however large.

Term base size: the part's share product divided by the share total, rounded down.

Term part remainder: the part's share product less the part's base size times the share total — what the division leaves over; zero or more, and below the share total.

Term short part: a part whose part remainder is above zero — the rounding down took a piece of a minor unit from the part.

Term short count: the number of short parts of one [Split] call.

Term base share: the part's base size, negated where the money's amount is below zero.

Term leftover: the money's size less the base sizes of the parts, added up — how many minor units the base sizes leave over.

Term first parts: as many short parts as the leftover counts, taken from the front of the order of the shares.

Term step: one minor unit in the direction of the money's amount — 1 for a money above zero, -1 for a money below zero; a money of zero has no step, since its leftover is zero and no part is a first part.

Term stepped share: the part's base share plus the step — the base share moved one minor unit away from zero.

Term total: the amounts of the parts of one [Split] answer, added up.

Term gap: the part's size times the share total, less the part's share product — the part's distance from the part's exact share, scaled by the share total so that no fraction appears; a gap whose size is below the share total is a part under one minor unit from the exact share.

Term round trip: an [Add] of the other money to the money, then a [Subtract] of the same other money from the result; an [Add] or a [Subtract] that answers a refusal has no round trip.

Term negated call: a [Multiply] or a [Split] call naming the money's negation where another call names the money, every other input the same.

The case space, and the rule that owns each case:

| Call | Case | Answer | Owning rule |
|---|---|---|---|
| an action | the money is no well-formed money | [Invalid Money] | Operation 1 |
| a pair action | the other money is no well-formed money | [Invalid Money] | Operation 2 |
| a pair action | the two currencies differ | [Mixed Currency] | Operation 3 |
| [Add] | one currency, the sum within the number cap | the money of the sum | Operation 5 |
| [Add] | the sum over the number cap | [Over Cap] | Operation 4 |
| [Subtract] | one currency, the difference within the number cap | the money of the difference | Operation 7 |
| [Subtract] | the difference over the number cap | [Over Cap] | Operation 6 |
| [Compare] | one currency | less, equal or greater | Operation 8 through 10 |
| [Negate] | a well-formed money | the money's negation | Operation 11 |
| [Multiply] | a rate, one of the roundings, the rounded size within the number cap | the money of the rounded product | Operation 16 |
| [Multiply] | the numerator no capped number, or the denominator no capped count | [Invalid Rate] | Operation 12, Operation 13 |
| [Multiply] | no rounding named, or one outside the roundings | [Invalid Rounding] | Operation 14 |
| [Multiply] | the rounded size over the number cap | [Over Cap] | Operation 15 |
| [Split] | one share or more, no more than the part cap, each a capped count | the parts, adding back up to the money | Operation 20 through 22 |
| [Split] | more shares than the part cap | [Too Many Parts] | Operation 17 |
| [Split] | no share, or a share that is no capped count | [Invalid Shares] | Operation 18, Operation 19 |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | Execution Contract Refusal 1 |

### Invariants

- **Invariant 1 — No answer mixes two currencies.**
  ```
  Invariant 1.1: EVERY result MUST carry the money's currency.
  Invariant 1.2: EVERY part MUST carry the money's currency.
  ```
- **Invariant 2 — A split adds back up.**
  ```
  Invariant 2.1: [Split] MUST answer parts whose total EQUALS the money's amount.
  ```
- **Invariant 3 — No part is a whole minor unit off the part's exact share.**
  ```
  Invariant 3.1: The size of a part's gap MUST fall below the share total.
  ```
- **Invariant 4 — The leftover always finds a short part to take it.**
  ```
  Invariant 4.1: The leftover MUST NOT EXCEED the short count.
  ```
- **Invariant 5 — Adding a money and taking the same money back changes nothing.**
  ```
  Invariant 5.1: A round trip MUST answer the money.
  ```
- **Invariant 6 — A refund is the exact negation of the charge.**
  ```
  Invariant 6.1: A negated [Multiply] call MUST answer the negation of the result.
  Invariant 6.2: A negated [Split] call MUST answer the negation of EVERY part, in the order of the parts.
  ```
- **Invariant 7 — No answer passes the number cap.**
  ```
  Invariant 7.1: A result's size MUST NOT EXCEED the number cap.
  ```

NOTE: why Invariant 4.1 holds — the part remainders of one [Split] call add up to the leftover times the share total; a part outside the short parts adds nothing, and a short part adds less than the share total; so wherever a minor unit is left over the leftover is below the short count, and the first parts are there to take every leftover minor unit (Term first parts, Operation 21).

NOTE: why Invariant 2.1 and Invariant 3.1 follow — the base sizes add up to the money's size less the leftover, and the first parts add the leftover back, one minor unit each; a first part's gap is the share total less the part remainder, above zero and below the share total, and every other part's gap is the negation of the part remainder.

## Examples

The same pattern in three settings, then the rejection paths. An amount is a whole number of the currency's minor unit, so `1999` in US dollars is $19.99.

### Checkout

A shop sells in US dollars. A basket holds a book at $19.99 and a pen at $2.50: `add(money("USD", 1999), money("USD", 250))` answers `money("USD", 2249)`. Sales tax at 8.25 percent is the numerator 825 with the denominator 10000, and the shop's tax rule rounds half-up: `multiply(money("USD", 2249), 825, 10000, half-up)` answers `money("USD", 186)`, since 2249 times 825 is 1855425, the quotient by 10000 is 185, and twice the remainder of 5425 is more than 10000. Named down, the same call answers 185. The basket with tax is `add(money("USD", 2249), money("USD", 186))`, which answers `money("USD", 2435)`, $24.35.

### Shared bill

Three friends split a $100.00 dinner evenly: `split(money("USD", 10000), [1, 1, 1])` answers parts of 3334, 3333 and 3333. Each base size is 3333, one minor unit is left over, and the first short part takes it. A landlord splits ¥1000 between two tenants, one share to two: `split(money("JPY", 1000), [1, 2])` answers 334 and 666. A part due a whole number of minor units takes no leftover: `split(money("USD", 2), [2, 1, 1])` answers 1, 1 and 0, because the first part's division leaves no remainder, and the one minor unit left over goes to the first part the rounding down took from.

### Refund

The dinner is refunded. `negate(money("USD", 10000))` answers `money("USD", -10000)`, and `split(money("USD", -10000), [1, 1, 1])` answers -3334, -3333 and -3333, each part the negation of the charge's part. The tax comes back the same way: `multiply(money("USD", -2249), 825, 10000, half-up)` answers `money("USD", -186)`. On an exact half the two half roundings part: `multiply(money("USD", 250), 1, 100, half-even)` answers 2 and `multiply(money("USD", 350), 1, 100, half-even)` answers 4, where half-up answers 3 and 4, and `multiply(money("USD", -250), 1, 100, half-up)` answers -3. A refund stands below a charge: `compare(money("USD", -500), money("USD", 100))` answers less.

### Rejection paths

A deployment that declares neither cap, so the number cap is eighteen digits and the part cap is 1,000:

- `add(money("USD", 100), money("EUR", 100))` — rejected as [Mixed Currency].
- `add(money("USD", 100), money("usd", 100))` — rejected as [Mixed Currency]: two currencies are compared codepoint for codepoint, and the atom normalizes neither (Identity 2, Identity 3).
- `add(money("USD", 10.5), money("EUR", 100))` — rejected as [Invalid Money], the refusal listed first: an amount is a whole number of the minor unit, so $10.50 is 1050.
- `add(money("USD", 999999999999999999), money("USD", 1))` — rejected as [Over Cap].
- `multiply(money("USD", 100), 1, 0, down)` — rejected as [Invalid Rate]; so is a denominator of -4, and so is `multiply(money("USD", 100), 1.5, 2, down)`, a numerator that is no whole number.
- `multiply(money("USD", 100), 1, 2, nearest)` — rejected as [Invalid Rounding]; so is `multiply(money("USD", 100), 1, 2)`, a call without a rounding.
- `split(money("USD", 100), [])` — rejected as [Invalid Shares].
- `split(money("USD", 100), [2, 0, 3])` — rejected as [Invalid Shares].
- a [Split] of `money("USD", 100)` by 1,001 shares of 1 — rejected as [Too Many Parts]; by 1,000 shares of 1 the call answers 1,000 parts adding up to 100.

This covers every refusal.

## Generation acceptance

Acceptable when the checks below hold for every call an auditor makes: the atom stores nothing, so the calls and the deployment's database log are the whole evidence. Invariant 2.1, Invariant 3.1, Invariant 4.1, Invariant 6.1 and Invariant 6.2 are claimed for a money of any size and a split into any number of parts, so each is owed a proof over every size and not a test at a few.

The conformance table, each row a call and the answer the atom owes, under the default caps and in US dollars but for the row in yen:

| Call | Answer | Rules |
|---|---|---|
| `add(money("USD", 1999), money("USD", 250))` | `money("USD", 2249)` | Operation 5 |
| `subtract(money("USD", 250), money("USD", 1999))` | `money("USD", -1749)` | Operation 7 |
| `compare(money("USD", -500), money("USD", 100))` | less | Operation 8 |
| `compare(money("USD", 100), money("USD", 100))` | equal | Operation 9 |
| `negate(money("USD", 2249))` | `money("USD", -2249)` | Operation 11 |
| `negate(money("USD", 0))` | `money("USD", 0)` | Operation 11 |
| `multiply(money("USD", 2249), 825, 10000, down)` | `money("USD", 185)` | Term down |
| `multiply(money("USD", 2249), 825, 10000, up)` | `money("USD", 186)` | Term up |
| `multiply(money("USD", 2249), 825, 10000, half-up)` | `money("USD", 186)` | Term half-up |
| `multiply(money("USD", -2249), 825, 10000, half-up)` | `money("USD", -186)` | Invariant 6.1 |
| `multiply(money("USD", 250), 1, 100, half-up)` | `money("USD", 3)` | Term half-up |
| `multiply(money("USD", 250), 1, 100, half-even)` | `money("USD", 2)` | Term half-even |
| `multiply(money("USD", 350), 1, 100, half-even)` | `money("USD", 4)` | Term half-even |
| `multiply(money("USD", -250), 1, 100, half-up)` | `money("USD", -3)` | Term half-up, Invariant 6.1 |
| `multiply(money("USD", -250), 1, 100, half-even)` | `money("USD", -2)` | Term half-even, Invariant 6.1 |
| `multiply(money("USD", 1000), 1, 3, up)` | `money("USD", 334)` | Term up |
| `multiply(money("USD", 1000), -1, 3, down)` | `money("USD", -333)` | Term rounded product |
| `multiply(money("USD", 100000000000000000), 1000, 1000000, down)` | `money("USD", 100000000000000)` | Term product: twenty-one digits on the way |
| `split(money("USD", 10000), [1, 1, 1])` | 3334, 3333, 3333 | Operation 21, Operation 22 |
| `split(money("USD", -10000), [1, 1, 1])` | -3334, -3333, -3333 | Invariant 6.2 |
| `split(money("JPY", 1000), [1, 2])` | 334, 666 | Term first parts |
| `split(money("USD", 2), [2, 1, 1])` | 1, 1, 0 | Term short part |
| `split(money("USD", 5), [1, 1, 1, 1, 1, 1, 1])` | 1, 1, 1, 1, 1, 0, 0 | Term leftover |
| `split(money("USD", 100), [2, 3, 5])` | 20, 30, 50 | Operation 22 |
| `split(money("USD", -1), [1, 1])` | -1, 0 | Term step |
| `split(money("USD", 0), [1, 1])` | 0, 0 | Term leftover |
| `add(money("USD", 100), money("EUR", 100))` | mixed-currency | Operation 3 |
| `add(money("USD", 10.5), money("EUR", 100))` | invalid-money | Operation 1, Operation 3, Execution Contract Refusal 1 |
| `add(money("USD", 100), money("USD", 10.5))` | invalid-money | Operation 2 |
| `add(money("USD", 999999999999999999), money("USD", 1))` | over-cap | Operation 4 |
| `subtract(money("USD", -999999999999999999), money("USD", 1))` | over-cap | Operation 6 |
| `multiply(money("USD", 999999999999999999), 2, 1, down)` | over-cap | Operation 15 |
| `multiply(money("USD", 100), 1.5, 2, down)` | invalid-rate | Operation 12 |
| `multiply(money("USD", 100), 1, 0, down)` | invalid-rate | Operation 13 |
| `multiply(money("USD", 100), 1, 2)` | invalid-rounding | Operation 14 |
| `split(money("USD", 100), [])` | invalid-shares | Operation 18 |
| `split(money("USD", 100), [2, 0, 3])` | invalid-shares | Operation 19 |

Term conformance table: the table above, each row a call and the answer the atom owes under the default caps, in the currencies the call names.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY result carrying the money's currency (Invariant 1.1).
Check 1.2: An auditor MUST find EVERY part carrying the money's currency (Invariant 1.2).
Check 2.1: An auditor MUST find EVERY [Split] answer's total EQUALS the money's amount (Invariant 2.1).
Check 3.1: An auditor MUST find no part whose gap's size EXCEEDS the share total (Invariant 3.1).
Check 3.2: An auditor MUST find no part whose gap's size EQUALS the share total (Invariant 3.1).
Check 4.1: An auditor MUST find no [Split] call whose leftover EXCEEDS the short count (Invariant 4.1).
Check 5.1: An auditor MUST find EVERY round trip answering the money (Invariant 5.1).
Check 6.1: An auditor MUST find EVERY negated [Multiply] call answering the negation of the result (Invariant 6.1).
Check 6.2: An auditor MUST find EVERY negated [Split] call answering the negation of EVERY part (Invariant 6.2).
Check 7.1: An auditor MUST find no result whose size EXCEEDS the number cap (Invariant 7.1).
Check 8.1: An auditor MUST find, for EVERY row of the conformance table, the row's answer on the row's call under the default caps, in the currencies the call names (Operation 1 through 22).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the number cap confirmed against the moneys, the numerators, the denominators and the shares held MUST read the number cap the deployment declares and the records of the composing patterns that hold a money, a numerator, a denominator or a share (Capability requirement 3).
External check 2: An auditor needing the number cap and the part cap confirmed above zero MUST read the caps the deployment declares (Capability requirement 4, Capability requirement 5).
External check 3: An auditor needing a money's currency and amount confirmed held together MUST read the records of the composing patterns that hold a money (Composition note 3).
External check 4: An auditor needing every action confirmed to write and read no record MUST read the database log of the deployment across the calls of the actions (Operation 23, Operation 24).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT convert a currency.
Non-goal 2: The atom MUST NOT tell which currencies exist.
Non-goal 3: The atom MUST NOT hold a currency's minor unit.
Non-goal 4: The atom MUST NOT hold a rate.
Non-goal 5: The atom MUST NOT choose a rounding.
Non-goal 6: The atom MUST NOT price an item.
Non-goal 7: The atom MUST NOT calculate a tax.
Non-goal 8: The atom MUST NOT take a payment.
Non-goal 9: The atom MUST NOT refund a payment.
Non-goal 10: The atom MUST NOT settle a payment.
Non-goal 11: The atom MUST NOT keep a ledger.
Non-goal 12: The atom MUST NOT limit a money's sign.
Non-goal 13: The atom MUST NOT format a money for display.
```

NOTE: the owners — Currency *(forthcoming)* (Non-goal 1, 2, 3); the composing pattern that names the rate and the rounding, such as Tax *(forthcoming)* or Currency *(forthcoming)* (Non-goal 4, 5); Pricing *(forthcoming)* (Non-goal 6); Tax *(forthcoming)* (Non-goal 7); Payment *(forthcoming)*, a chargeback included (Non-goal 8, 9, 10); Ledger *(forthcoming)* (Non-goal 11); the pattern that stores the money, as [Gift Card](./gift-card.md) does for a balance (Non-goal 12); the deployment (Non-goal 13).

Where the atom breaks down: a calculation across two currencies; a price or a rate finer than the minor unit, which stays a rate, a numerator with a denominator, until a [Multiply] scales a money by it and brings a money back; a split whose parts must each come to a round figure; a split repeated in one order, where the first parts take the leftover every time and come out ahead by up to a minor unit a split, so that a composing pattern that must spread the leftover turns the order of the shares; a money carried between two deployments whose number caps differ, where the one with the lower cap refuses a size past its own.

## Composition notes

```
Composition note 1: A composing pattern MUST own a declined responsibility the composing pattern needs where the Non-goals name no other owner.
Composition note 2: A composing pattern MUST name the rounding on EVERY [Multiply] call.
Composition note 3: A composing pattern MUST store a money's currency AND the money's amount together.
```

NOTE: composing patterns — none yet. Forthcoming: Currency, Pricing, Tax, Payment, Checkout, Ledger. Cart and Gift Card state their own amount rules and are not reopened by this atom (the maintainer, 2026-11-13).

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the deployment (also: a deployment); a composing pattern; an action; a pair action; a call; an auditor.

Term records: empty.

Term record verbs: identify, compare, normalize, carry, store, declare, answer, write, fall, own, name, convert, tell, hold, choose, price, calculate, take, refund, settle, keep, limit, format, find, read.

Term value sets: action, pair action, order and roundings are declared above and cited here (GRACE-lang Closed vocabulary 15); the action rejection is every code on the refuses lines of the Operations.

Term bounds: positive count (one, the floor of a denominator and a share); number cap (the largest size of a whole number a call names or answers, eighteen digits where a deployment declares none); part cap (the most shares one [Split] call names, 1,000 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.69 (2026-11-13) through the Grace connector.

Term terms: money, currency, amount, minor unit, whole number, positive count, size, negation, number cap, part cap, capped number, capped count, action, pair action, well-formed money, other money, result, sum, difference, order, rate, numerator, denominator, product, quotient, remainder, rounding, roundings, down, up, half-up, half-even, rounded size, rounded product, shares, share count, share total, part, parts, share product, base size, part remainder, short part, short count, base share, leftover, first parts, step, stepped share, total, gap, round trip, negated call, conformance table.

#### Add

Adds two moneys in one [Currency] and answers the money of the sum. Two currencies are refused, and so is a sum past the [Number Cap].

Kind: Operation

#### Subtract

Takes the other money from the money, both in one [Currency], and answers the money of the difference, which may be below zero. Two currencies are refused, and so is a difference past the [Number Cap].

Kind: Operation

#### Compare

Answers how the money stands against the other money in the same [Currency]: less, equal or greater. Two currencies are refused.

Kind: Operation

#### Negate

Answers the money's negation: the same [Currency] and the same size with the sign turned, so a charge becomes a refund. A money of zero answers the same money.

Kind: Operation

#### Multiply

Scales a money by a rate, the [Numerator] with the [Denominator], and brings the answer to a whole [Amount] by the [Rounding] the call names. A call without a rounding is refused.

Kind: Operation

#### Split

Divides a money into parts by [Shares], one part per share in the order given. Every part is rounded down in size, and the minor units left over go one each to the first parts the rounding down took from, so the parts add back up to the money.

Kind: Operation

#### Money

An [Amount] in one [Currency]: a value the atom never stores, held by the pattern that needs one.

Kind: Type

#### Currency

The unit of account a money is counted in, such as an ISO 4217 code; a string of one or more codepoints, held as supplied and compared codepoint for codepoint.

Kind:       Field
Field of:   Money
Projection: currency

#### Amount

How many of the currency's minor unit a money holds: a whole number, negative, zero or positive, whose size is no more than the [Number Cap].

Kind:       Field
Field of:   Money
Projection: amount

#### Numerator

The top of the rate a [Multiply] call scales by: a whole number, negative, zero or positive, whose size is no more than the [Number Cap]; not stored.

Kind:         Parameter
Parameter of: Multiply
Projection:   numerator

#### Denominator

The bottom of the rate a [Multiply] call scales by: a whole number from one through the [Number Cap]; not stored.

Kind:         Parameter
Parameter of: Multiply
Projection:   denominator

#### Rounding

The rule a [Multiply] call names for bringing the answer to a whole [Amount]: down, up, half-up or half-even, each working on the size and keeping the sign. Named on every call; the atom supplies none.

Kind:         Parameter
Parameter of: Multiply
Projection:   rounding

#### Shares

The list a [Split] call names, one whole number from one through the [Number Cap] per part, and no more of them than the [Part Cap]; a part is due its share out of all the shares added up.

Kind:         Parameter
Parameter of: Split
Projection:   shares

#### Number Cap

The largest size of a whole number a call names or answers: an amount, a numerator, a denominator or a share; 999999999999999999 where a deployment declares none, which is eighteen digits. A deployment never declares one below the size of a money, a numerator, a denominator or a share a composing pattern holds, and never one of zero.

Kind:         Parameter
Parameter of: every action ([Add], [Subtract], [Compare], [Negate], [Multiply], [Split])
Projection:   number_cap

#### Part Cap

The most shares one [Split] call names; 1,000 where a deployment declares none. A deployment never declares one of zero.

Kind:         Parameter
Parameter of: Split
Projection:   part_cap

#### Invalid Money

The refusal of a value that is no well-formed money: a currency of no codepoints, an [Amount] that is no whole number, or a size past the [Number Cap].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-money

#### Mixed Currency

The refusal [Add], [Subtract] and [Compare] answer when the two moneys carry different currencies.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: mixed-currency

#### Over Cap

The refusal [Add], [Subtract] and [Multiply] answer when the answer's size would pass the [Number Cap].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: over-cap

#### Invalid Rate

[Multiply]'s refusal of a [Numerator] that is no whole number within the [Number Cap], or of a [Denominator] that is no whole number from one through the cap.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-rate

#### Invalid Rounding

[Multiply]'s refusal of a call without a [Rounding], or with one outside the four.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-rounding

#### Too Many Parts

[Split]'s refusal of [Shares] holding more shares than the [Part Cap].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: too-many-parts

#### Invalid Shares

[Split]'s refusal of [Shares] holding no share, or holding a share that is no whole number from one through the [Number Cap].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-shares

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Add]: #add
[Subtract]: #subtract
[Compare]: #compare
[Negate]: #negate
[Multiply]: #multiply
[Split]: #split
[Money]: #money
[Currency]: #currency
[Amount]: #amount
[Numerator]: #numerator
[Denominator]: #denominator
[Rounding]: #rounding
[Shares]: #shares
[Number Cap]: #number-cap
[Part Cap]: #part-cap
[Invalid Money]: #invalid-money
[Mixed Currency]: #mixed-currency
[Over Cap]: #over-cap
[Invalid Rate]: #invalid-rate
[Invalid Rounding]: #invalid-rounding
[Too Many Parts]: #too-many-parts
[Invalid Shares]: #invalid-shares

---

## Standards references

Money is a primitive that stays below regulation: the rules that bind money bind the patterns that hold and move it. It inherits from:

- **ISO 4217** — the codes a currency is commonly named by, and the minor unit every amount is counted in. The atom reads neither the list of codes nor a minor unit exponent (Non-goal 2, Non-goal 3).
- **ISO 20022** — the payment message standard, whose currency-and-amount type holds eighteen digits in all, the fraction digits counted; the number cap's default follows it, as eighteen digits of the minor unit (Capability requirement 1).
- **The quota rule of apportionment** — every part is its exact share rounded down or up, the rule the largest remainder method, Alexander Hamilton's of 1792, was built to keep. [Split] keeps the rule (Invariant 3.1) and hands the leftover by the caller's order where that method hands it by the size of the remainder.
- **Java's `RoundingMode`** — the four rounding names as widely shipped: down toward zero, up away from zero, half-up for an exact half away from zero, half-even for an exact half to the even neighbour.
- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design, leaving currency, pricing, tax, payment and the ledger to concepts of their own.

The euro conversion rules of Council Regulation (EC) No 1103/97, a rate used unrounded and the amount paid rounded to the nearest cent, bind Currency, which the atom's exact rate and named rounding leave room for (Non-goal 1). Tax rounding rules and cash rounding bind the patterns that calculate a tax and take a payment (Non-goal 7, Non-goal 8).

---

## Status

`grounded on Final Critique 4 — 2026-11-13 at 8b6954c` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-11-13 at 8b6954c
formal: verified — money.als + 6 twins (the static data model, one call and its answer: State 1, Identity 2, Invariant 1.1, 1.2 and 7.1 checked, Identity 3 caught by the Invariant 1.1 and 1.2 checks); money.tla + 28 twins (each action as a function of the call's inputs, and the calls around it: Operation 1 through 24 and Invariant 2.1, 3.1, 4.1, 5.1, 6.1 and 6.2 checked, Identity 2 cross-checked by the Operation 3 check, State 2 by the Operation 23 check), with TLAPS proofs over the same model that discharge Invariant 2.1, 3.1, 4.1, 6.1 and 6.2 at every size (tlapm --strict, 696 obligations, none owed); the vote yes of 2026-11-13, on the maintainer's ruling of 2026-11-09 (both models; only the writing vetoes one), and neither vetoed, 2026-11-13
last gate: 2026-11-13 — Final Critique 4, a delta round, one reader (Linus mimo-v2.6-pro), frozen at 8b6954c — foundational count 0, clean, one sample, the blind second triage agreeing (it placed no item foundational; it raised External check 1's missing source for the declared cap as refining, cured, and the later holding of a money past the cap as refining Kind C, recorded in the NOTE beside Capability requirement 3); 2026-11-13 — Final Critique 3 (delta), frozen at 18002aa — foundational count 1, cured, not clean, no sample

open:
- 2026-11-13-a · refining · Term currency; Term well-formed money · a currency is a string of one or more codepoints with no length bound, where the corpus's atoms bound a string input by a string cap (Execution Contract Input 2), so a build that refuses a currency past a limit of its own answers differently from one that admits it → settle whether the atom bounds a currency by a string cap, and what the refusal is, the corpus's default being 1,024 code points
```

## Decisions

- **2026-11-13 — Drafted from the maintainer's design session of the same morning, corrected from a first draft by Grok and again from GLM's review of the corrected draft.** *Chose:* a value the atom never stores, an amount in a currency's minor unit with the currency (the maintainer, 2026-11-13: "Pre design saves us rounds"); signed amounts, the limit to zero or more left to the pattern that needs one (Non-goal 12); a rate as a numerator and a denominator, a number and never a money; four roundings named on every call and no default (Operation 14); every rounding and every split worked on the size with the sign kept, so a refund is the negation of the charge (the maintainer's yes, 2026-11-13; Invariant 6.1, Invariant 6.2), and [Negate] to make one (GLM's review: the headline property had no action); a split whose leftover minor units go left to right (the maintainer's yes, 2026-11-13), narrowed by the drafter to the parts the rounding down took from (Operation 21, Term short part); every definition in whole numbers, a quotient and a remainder in place of an exact fraction (GLM's review, citing GRACE-lang Closed vocabulary 32); a number cap on every whole number a call names or answers and a part cap on a split, each a default a deployment may override (GLM's review: a split answer with no bound), with the floor under the number cap carried to the moneys the composing patterns hold (Capability requirement 3; GLM's review: a lowered cap stranded a held money). *Over:* a stored record with a database and an auditor of versions (Grok's draft); a default rounding; rounding toward the two infinities (a refund lands a minor unit off the charge); the leftover to the first parts whatever the exact share, as first agreed (a part due a whole number takes an extra minor unit: 2 split by shares of 2, 1 and 1 answers 2, 0 and 0, a whole minor unit off, in 4,852 of 94,380 small cases tried, both counts reproduced by GLM's review); the largest remainder first (the same fairness, with a comparison the caller's order cannot steer); a list of accepted currencies in the atom (Currency's, Non-goal 2); an invariant that the same call answers the same answer and a check that nothing is stored (GLM's review: corollaries that constrain nothing); Cart and Gift Card reopened to lean on the atom (the maintainer, 2026-11-13: not now). *Because:* the EOS test keeps one freestanding concept, the arithmetic of an amount in one currency, and names an owner for everything a shop or a bank layers on it (Non-goal 1 through 13); as simple as possible without losing fidelity keeps six actions and two settings; and Invariant 3.1 as the session stated it, no part a whole minor unit off its exact share, holds only under the narrowed rule, tried on 94,380 small splits and 60,000 wide ones, with 282,812 multiplies and 30,016 round trips beside them.

NOTE: End of Money.
