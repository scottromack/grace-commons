---
title: Gift Card — history
nav_exclude: true
search_exclude: true
---

# Gift Card — history

The dated record of how [Gift Card](./gift-card.md) got here, moved out of the spec on 2026-11-16 because a reader does not need it to use the spec today. Everything smaller is in `git log -- atoms/gift-card.md`.

## Decisions

- **2026-10-30 — Drafted through the Grace connector from the maintainer's interview, mirroring Cart.** *Chose:* a plain gift card, loaded once and spent down (the maintainer, 2026-10-30: "it is a simple gift card concept"; "it is loaded once and used"); a card id for the seller's records beside a random card code its holder spends with (Identity 1 through 4, Operation 16); a spend taking exactly the amount asked or refused (Operation 11, Invariant 4.1); no reload, split, transfer, refund to a gift card or cancelling, which the maintainer placed in a loyalty card system, and no expiry or fee (Non-goal 1 through 7); the card cap the deployment's, per currency (Capability requirement 6), the $500 consumer cap the maintainer named appearing in the examples. *Over:* a gift card named by its code alone, as Capability's token names a capability (the seller's records would carry the secret that spends the gift card); a spend taking what is left when the amount is over the balance (one call would mean two things); a stored used-up state (a balance of zero already says it). *Because:* the EOS test keeps one freestanding concept, a value spent down, and names an owner for everything a store layers on it (Non-goal 1 through 15); with nothing raising a balance and every spend exact, a balance is always the value less the spends an auditor reads from the gift card's versions (Execution Contract Database 5).
