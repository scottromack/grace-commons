---
title: Punch Card — history
nav_exclude: true
search_exclude: true
---

# Punch Card — history

The dated record of how [Punch Card](./punch-card.idd) got here, moved out of the spec on 2026-11-16 because a reader does not need it to use the spec today. Everything smaller is in `git log -- atoms/punch-card.md`.

## Deleted rules

The spec's tombstones: each `Deleted:` line under the heading its rule stood under on the page. A tombstone carries no obligation, and its label stays reserved (GRACE-lang Hard invariant 25 and Hard invariant 27).

### What it keeps › Card Id

```
Deleted: Identity 10. Execution Contract Logic confinement 22 owns it.
```

## Decisions

- **2026-11-13 — Drafted through the Grace connector mirroring Gift Card, for GitHub user scottromack.** *Chose:* a punch card that collects one stamp per purchase toward a goal of five and is redeemed at the goal for one free item (the submitter, 2026-11-12: "one stamp per purchase, ten for a free item"); the goal the deployment's, five where none is declared, copied onto the punch card at issue (Capability requirement 5, Operation 2, Invariant 2.2); a redeem that empties the punch card and counts the redemption, so one punch card serves a customer for good (Operation 13, Operation 14); a card id for the shop's records beside a random card code its holder presents (Identity 1 through 5, Operation 18). *Over:* a punch card used up at its first redemption (a stored used-up state and a new punch card per free item, where the stamps at zero already say empty); a stamp on a full punch card rolling into the next five (one call would mean two things, and a free item could go unclaimed); a goal read from the deployment on every call (a changed setting would move a customer's finish line). *Because:* the EOS test keeps one freestanding concept, a count raised to a goal and traded, and names an owner for everything a shop layers on it (Non-goal 1 through 13); as simple as possible without losing fidelity keeps three stored numbers and no status.
