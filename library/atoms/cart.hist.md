---
title: Cart — history
nav_exclude: true
search_exclude: true
---

# Cart — history

The dated record of how [Cart](./cart.md) got here, begun on 2026-11-13 when the spec's tombstones moved out of it because a reader does not need them to use the spec today; everything smaller is in `git log -- atoms/cart.md`.

## Decisions


- **2026-11-19 — The read answer carries the cart id.** *Chose:* [Read] answers the cart id with the cart's currency, every line and the total (Operation 21), the case table's [Read] row and the Read entry saying so. *Over:* saying the answer leaves the caller's own cart id out. *Because:* [Cart Id] is a Field of Cart and [Currency] its other, so the answer that projects a cart carries both, as Operation 22 carries all four fields of a line; State 1 and Term records give a cart its id, and a build that leaves it out answers a different shape from one that echoes it, which the open line 2026-10-24-b, asked in three rounds' readers, named. Overrulable: leaving it out is one clause in Operation 21 and the same words in the row and the entry.

- **2026-11-02 — The string cap and the line cap have defaults.** *Chose:* the string cap on an item reference stated as 1,024 Unicode code points and the line cap on a cart as 500 lines, each where a deployment declares none, with Capability requirement 6 and Capability requirement 7 citing Execution Contract Input 2; [Add] answers cart-full (Operation 24), listed after already-in-cart so a repeat of an item the cart already carries answers that first. *Over:* silence on both. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; an item reference names an item with its chosen options, a composed string that 1,024 code points, the corpus's default for text (Personal Todo's description cap), holds, and a cart gathers items toward one purchase, so 500 lines is several times the largest ordinary basket and keeps [Read], which answers every line, bounded.

- **2026-10-23 — Drafted in GRACE lang v0.66, the first pattern written against the Database contract from the start.** *Chose:* a Cart atom, the corpus's first e-commerce pattern, on the maintainer's ruling of 2026-10-23, drafting begun 2026-10-23 17:47Z, from which its rounds to ground count; the Database, Read and Refusal families cited once (Capability requirement 5) and restated nowhere; no clock read. *Over:* a cart folded into a checkout or order pattern; a prose draft migrated later. *Because:* the ruling asks what a pattern written from the start against the Database contract and GRACE lang v0.66 costs to ground; the EOS test keeps one freestanding concept, priced lines and their total, and names an owner for pricing, tax, stock, payment, checkout and delivery (Non-goal 1 through 15, Non-goal 17).

- **2026-10-23 — A line keeps the price taken when it was added, and a cart holds one line per item.** *Chose:* the unit price [Add] takes, which no action changes (Invariant 2.1); one line per item among the lines a cart carries, a second add of the item refused as already-in-cart (Operation 8, Invariant 1.1, Check 2.3); a line named by an opaque line id, never by its item reference (Identity 2, Identity 5), so an item removed and added again is a new line at the new price; a removed line gone from the current records, its versions readable as they stood (Operation 16, Operation 18, Execution Contract Database 5); [Change Quantity] setting a whole new quantity. *Over:* merge-into-existing-line (whose price would the merged units carry?); lines named by their item reference (their history would mix two prices); a removed-line state (a field nothing needs); every version of a removed line erased (what a checkout took would become unreadable); quantity by difference (a repeated call applies it twice). *Because:* the ruling defines a line as an item reference, a quantity and the unit price taken when added; with one line per item and one price per line, the total moves only when a line is added, re-counted or removed, and an auditor reads each line's price from its versions (Execution Contract Database 5); a removed line's versions keep its cart id (Invariant 3.1), so the rule counts only the lines a cart carries.

- **2026-10-23 — One currency per cart, amounts in its minor unit, and no checkout state.** *Chose:* a currency fixed at [Open] from the accepted currencies (Capability requirement 3, Invariant 4.1), stored as supplied and compared codepoint for codepoint (Identity 8, Identity 9); every amount a whole number of the currency's minor unit, the total computed at each read, never stored, without loss (Capability requirement 4); no lifecycle state, a cart never closed or removed by the atom (State 3, Non-goal 8), a checkout reading the lines it takes in its own transaction (Execution Contract Database 1 and Database 2). *Over:* a currency per line (a mixed cart has no total); decimal or floating-point amounts; a currency matched without regard to case (a rule the page never named); a checked-out state (the checkout's decision folded into the atom); a check that a read's total sums its lines (Execution Contract Conformance 6 already holds a read to the records). *Because:* a sum is defined over one unit of account, whole minor units add without rounding, and every committed version of a cart and its lines stays readable (Execution Contract Database 5), so what a checkout took survives the cart's changes.

- **2026-10-24 — An item reference names the item with its options.** *Chose:* one configured item per line, on the maintainer's ruling of 2026-10-23 22:50Z: the item reference names the item with the options chosen for it, in the deployment's own scheme (Term item reference), so Invariant 1.1 and Operation 8, unchanged in wording, hold one line per configured item, as the café tab's two flat whites show; the unit price is the configured item's, supplied by the composing pattern that prices it (Term unit price, Composition note 2); the atom reads no option (Non-goal 16), which a catalog pattern owns. *Over:* options as fields of the line (the atom would read and compare what a catalog defines); an item whose options its reference cannot name, once listed where the atom breaks down. *Because:* an item reference is stored as supplied and compared codepoint for codepoint (Identity 6, Identity 7), so naming the options in it costs the atom no rule, and an item with other options is another item, at its own price.

- **2026-11-26 — The atom converted to the bond shape, batch 5 of the converter: it offers the cart id and the line id, the line id read by a new [Read Line], and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; `Term offer key: key cart id; carried by carts; calls Read` and `Term offer key: key line id; carried by lines; calls Read Line` (Bonds Key 9, 10, 26), both declared (Key 18). No action took a line id to read it, so [Read Line] answers one line by its line id (Operation 26, 27) and is a line action, so Operation 11 refuses a line id naming no line with not-known; this follows the existence read Opus chose for Condition Register (ae6d2e48). No need: the shopper is the composing pattern's (Non-goal 9). Non-goal 5 tombstoned to Non-goal 4; the owners NOTE says each job. Labelled rules 92 before, 93 after; 630 lines before, 728 after. *Over:* offering the line id with no existence read (Key 26). *Because:* unit `atom: Cart, converted` (batch 5, 2 of 5).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Cart](./cart.md) may carry it again.

### Structure › Capability requirement

```
Deleted: Capability requirement 4. Execution Contract Logic confinement 9 owns it.
```

### Structure › Operations

```
Deleted: Operation 20. Execution Contract Read 4 owns it.
```
