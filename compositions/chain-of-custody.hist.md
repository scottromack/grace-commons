---
title: Chain of Custody — history
nav_exclude: true
---

# Chain of Custody — history

The dated record of how [Chain of Custody](./chain-of-custody.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/chain-of-custody.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-24 — Rewritten in GRACE lang v0.61; forty-one of forty-three open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole, the per-chain section renamed the chain exclusion because the grammar owns the noun *section* — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with the verdict classes as their own `Verdict` family; invariant numbers 1 through 5 and 7 unchanged, Invariant 6 tombstoned to Composes 5; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and five Edge cases families. Choices the page left open, each decided by a standing rule: the blank credential answered invalid-credential in every action (2026-08-26-e, -r, 2026-08-30-j — *make all things mean one thing*); binding-unknown given a clock-free predicate — an unbound entry earlier than an entry whose event is already purged — and read as a durability finding in the proof and the checks alike (2026-08-30-a, -b, 2026-08-26-i, -u); the substrate's unverifiable reasons relayed unchanged and its compensation-window qualifier carried beside the verification, never in the retention state (2026-08-26-h, -p, -q); the reconciliation's window and cadence given names of their own, apart from the substrate's knobs (2026-08-30-l); the metadata taken off every audit write, and so off the caps (2026-08-26-v — *as simple as possible without losing fidelity*); the purged half named against Erasure Tombstone with the persist-at-purge alternative dropped (2026-08-30-c — *generalize nothing*); and one genesis pairing key, stated once (2026-08-30-n). *Over:* the prose's step lists, a verdict with three unlanded outcomes, and an alternative that rode a cascade the composition does not wrap. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-20, newest first:

- 2026-08-26 authentication-precedence gate — 1 foundational routed (since closed), 2 foundational and 8 refining/rhetorical corrected in-round, 7 refining and 5 rhetorical routed (1 refining since closed)
- Final Critique 7's 2 other foundational (since closed), 7 refining and 4 rhetorical also routed
