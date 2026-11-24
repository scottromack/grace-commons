---
title: Gift Card — history
nav_exclude: true
search_exclude: true
---

# Gift Card — history

The dated record of how [Gift Card](./gift-card.md) got here, moved out of the spec on 2026-11-16 because a reader does not need it to use the spec today. Everything smaller is in `git log -- atoms/gift-card.md`.

## Decisions

- **2026-10-30 — Drafted through the Grace connector from the maintainer's interview, mirroring Cart.** *Chose:* a plain gift card, loaded once and spent down (the maintainer, 2026-10-30: "it is a simple gift card concept"; "it is loaded once and used"); a card id for the seller's records beside a random card code its holder spends with (Identity 1 through 4, Operation 16); a spend taking exactly the amount asked or refused (Operation 11, Invariant 4.1); no reload, split, transfer, refund to a gift card or cancelling, which the maintainer placed in a loyalty card system, and no expiry or fee (Non-goal 1 through 7); the card cap the deployment's, per currency (Capability requirement 6), the $500 consumer cap the maintainer named appearing in the examples. *Over:* a gift card named by its code alone, as Capability's token names a capability (the seller's records would carry the secret that spends the gift card); a spend taking what is left when the amount is over the balance (one call would mean two things); a stored used-up state (a balance of zero already says it). *Because:* the EOS test keeps one freestanding concept, a value spent down, and names an owner for everything a store layers on it (Non-goal 1 through 15); with nothing raising a balance and every spend exact, a balance is always the value less the spends an auditor reads from the gift card's versions (Execution Contract Database 5).

- **2026-11-23 — The record carries a digest of the card code, never the card code (Final Critique 5, a delta round, Linus's one foundational finding).** *Chose:* the gift card carries a card code digest the seam computes (Execution Contract Logic confinement 8), State 3 forbids storing the card code, [Issue] answers the live card code once, and [Check Balance] and [Spend] find the gift card by the digest of the code they present (State 1, Identity 2 through 4, 6 and 8, Operation 4 and 16, Invariant 3.1, Capability requirement 12), as Invitation did in its Final Critique 11 and Session by its unit of 2026-11-21. *Over:* Logic confinement 21 left to a deployment's reading (a database dump would hand out every unspent gift card, since the card code spends); a digest answered to the seller's support desk by [Read] (Operation 16 now keeps it from the seller's records as well). *Because:* Execution Contract Logic confinement 21, written 2026-11-19, has no clause letting a specification keep a live bearer credential; the 2026-10-30 entry already refused to let the seller's records carry "the secret that spends the gift card" (a gift card named by its code alone), and the digest keeps that refusal in the records themselves.

## Deleted rules

The spec's tombstones, moved here from the page: each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Gift Card](./gift-card.md) may carry it again.

### Left to others › Composition notes

```
Deleted: Composition note 2. Term amount owns it: a [Spend] takes no currency, and an amount is in the gift card's currency.
```
