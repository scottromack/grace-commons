---
title: Shared Cart — history
nav_exclude: true
search_exclude: true
---

# Shared Cart — history

The dated record of how [Shared Cart](./shared-cart.md) got here, begun on 2026-11-13 when the spec's tombstones moved out of it because a reader does not need them to use the spec today; everything smaller is in `git log -- compositions/shared-cart.md`.

## Decisions


- **2026-10-30 — Drafted through the Grace connector from the maintainer's need, mirroring Shared Todo.** *Chose:* a cart several people see and add to (the maintainer, 2026-10-30: "a cart my friends can see and add to"), wiring three grounded atoms, so no constituent ripple is accepted; every change attributed to the actor who made it (the maintainer: "knowing the randomness of humans we would want to know this"), through Event Log rather than a record of the composition's own, keeping Shared Todo's no-stored-state shape (Composition state 1); permissions per cart and per verb, the opener holding all five (Action wiring 7, Scope vocabulary 2 through 7); a cart id no grant names answered as permission-denied (Invariant 2.1); the cart event carrying no item reference, which Cart's records hold, so the payload stays bounded by the actor references alone (Capability requirement 2). *Over:* a composition-owned attribution record (a stored record beside the constituents'); Assignment for the adder (it names who is responsible, not who acted); one list-wide scope set, as Shared Todo's (every friend would reach every cart); Capability-backed link sharing (a bearer link names no friend, so attribution would fail). *Because:* Cart, Permissions and Event Log each decline exactly what the others hold, and the closure table lands every answer of every call in a named rule; the receivers of what the composition declines are named in Non-goals and Composition notes, as Shared Todo's council read 55 asked.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Shared Cart](./shared-cart.md) may carry it again.

### Composition notes

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns the declaration of the composing patterns a deployment wired in.
```
