---
title: Shared Cart — history
nav_exclude: true
search_exclude: true
---

# Shared Cart — history

The dated record of how [Shared Cart](./shared-cart.md) got here, begun on 2026-11-13 when the spec's tombstones moved out of it because a reader does not need them to use the spec today; everything smaller is in `git log -- compositions/shared-cart.md`.

## Decisions


- **2026-10-30 — Drafted through the Grace connector from the maintainer's need, mirroring Shared Todo.** *Chose:* a cart several people see and add to (the maintainer, 2026-10-30: "a cart my friends can see and add to"), wiring three grounded atoms, so no constituent ripple is accepted; every change attributed to the actor who made it (the maintainer: "knowing the randomness of humans we would want to know this"), through Event Log rather than a record of the composition's own, keeping Shared Todo's no-stored-state shape (Composition state 1); permissions per cart and per verb, the opener holding all five (Action wiring 7, Scope vocabulary 2 through 7); a cart id no grant names answered as permission-denied (Invariant 2.1); the cart event carrying no item reference, which Cart's records hold, so the payload stays bounded by the actor references alone (Capability requirement 2). *Over:* a composition-owned attribution record (a stored record beside the constituents'); Assignment for the adder (it names who is responsible, not who acted); one list-wide scope set, as Shared Todo's (every friend would reach every cart); Capability-backed link sharing (a bearer link names no friend, so attribution would fail). *Because:* Cart, Permissions and Event Log each decline exactly what the others hold, and the closure table lands every answer of every call in a named rule; the receivers of what the composition declines are named in Non-goals and Composition notes, as Shared Todo's council read 55 asked.

- **2026-11-20 — [Open Cart] answers the opener's five grant ids, and a departing actor's grants are swept by Actor Suspension.** *Chose:* [Open Cart] answers the cart id and the grant id of each of the five verb scopes Permissions' grant answered for the opener (Action wiring 8, Term Opened), so no grant the composition makes is one no caller was told of; Composition note 3 and Non-goal 9 name Actor Suspension as the owner of a departing actor's sweep, which enumerates the actor's grants through Permissions' read and needs no grant id; Composes 12 keeps the Cart and Event Log instances to the composition and Composes 13 lets the Permissions instance serve Actor Suspension beside it, since the sweep runs on that instance. *Over:* a listing action answering a cart's grants (a new action and a new scope for what Permissions' read already answers); the sweep through [Unshare Cart] (it needs the caller to hold the cart's share scope and a grant id, and the last holder's own departure leaves nobody to call it). *Because:* open line 2026-11-04-a, decided by the maintainer (Scott, 2026-11-19 3:35 and 3:41 PM Central, rounds/open-line-choices-directions-2.md, item 139: "yes"); one rule added (Composes 13), two reworded (Action wiring 8, Composes 12) and one note reworded (Composition note 3).

- **2026-11-22 — Final Critique 3: a view reads Cart first, a cart event is written as one object, and an over-long reference is refused at the call.** *Chose:* Action wiring 31 (the view reads Event Log only after Cart answers, so every line Cart carries has its add event already, Invariant 3.1 holding at every commit); Action wiring 32 (a cart event is one object of the interchange text format with a member for every field, each value a string with its quotes, backslashes and control characters escaped, so a friend reference cannot read as a field); Action wiring 33 and 34 (an actor reference over Permissions' string cap refuses [Open Cart], a friend reference over the reference bound or the string cap refuses [Share Cart], where the order of Cart's open and Permissions' grant had left [Open Cart]'s answer to the build); Capability requirement 4 (a cart id fits Permissions' string cap with a verb scope's suffix); Non-goal 11 (no grant of the cart is exempt from an unshare, the opener's included); Invariant 3.1 and Check 2.1 counting a removed line's id; the Indeterminate outcome text corrected for a repeated share and a repeated unshare and extended to a repeated open and an add without view. *Over:* leaving the order of a view's two reads, the encoding of a cart event and the order of an open's two calls to the build. *Because:* one input answers two ways under the old text (Final Critique 3, Linus), and Execution Contract Timing 13 reads no order from a rule's position.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Shared Cart](./shared-cart.md) may carry it again.

### Composition notes

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns the declaration of the composing patterns a deployment wired in.
```
