---
title: Capability — history
nav_exclude: true
search_exclude: true
---

# Capability — history

The dated record of how [Capability](./capability.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/capability.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the thirteen invariant numbers and the six acceptance checks unchanged, the derived lapse routed through a declared lapsed and revocable so no rule carries the comparison, the arithmetic in `allocated_at + ttl` moved into a declared expiry deadline (Hard invariant 24), the two things the store cannot clear promoted from prose caveats to `External check 1 through 2`, the two Alloy-confirmed entailments kept as prose beneath the invariants rather than given numbers they never had, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk. The rewrite surfaced one cross-atom fork it does not resolve: a lapsed capability answers [Already Terminal] to [Revoke] while a lapsed [Session](./session.md) accepts one, same mechanic and opposite rulings, neither declaring the other — docketed rather than reconciled, because reconciling it is logic.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the capability store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the thirteen rules that restated them, or stood in for them, tombstoned to their owner — Operation 34 and Invariant 4.1, [Redeem]'s lowering and exhausting move committed in one operation, Operation 45, [Revoke]'s status move and its three revocation fields committed in one operation, Invariant 4.7, no partial write standing as an observable capability, and Invariant 11.3, no partial capability left by a storage-failure, to Store 1; Invariant 4.5, an uncommitted crash leaving the capability as the call found it, to Store 1 and Store 3; Invariant 4.6, a committed crash leaving the lowering standing, and Operation 49, a write the store refused leaving the store as the call found it, to Store 3; Concurrency 1, writes on one capability token serialized, Invariant 4.2 and 4.3, two concurrent redeems at one remaining redemption answering redeemed once and the later one exhausted, and Concurrency 3, a compare-and-set as a way to discharge Concurrency 2, to Store 2; Concurrency 2, the counter read and the counter write one transition, to Store 1 and Store 2; rules 208 to 196. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The redemption bound stays the atom's own (Invariant 4.4), as do a refused [Redeem] lowering nothing (Operation 31), the store refusing a reused capability token (Identity 11, Invariant 12.2) and the atom's no-removal rules (State 13, Invariant 11.1 and 11.2); Check 2.4 now names Operation 32, the exhausting move whose effect it reads. The atom keeps no history of a capability's fields (External check 3 sends it to the composing Audit Trail) and orders nothing by commit, so it cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Revoke]'s refuses line listing its refusals in the order the revoke refusal order gave them — not-known, already-terminal, invalid-request, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 5, Execution Contract Refusal 1); Operation 66, which evaluated the revoke refusal order, deleted to Refusal 1, and Term revoke refusal order deleted with it; rules 201 to 200. Operation 65 and Term redeem refusal order stay the page's own: they order the redemption failure [Redeem] answers inside invalid(redemption failure), an answer and no refusal, and Refusal 1 orders only a refuses line. *Over:* the page stating for itself which of [Revoke]'s refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's sixth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 5, Execution Contract Read 1 through 3) and the two rules that restated it deleted to it: the atom-wide state-unavailable (Operation 62) to Read 1, and the allocate refusal order (Operation 64), whose rules after the read all answer invalid-request, to Read 1; state-unavailable off [Redeem]'s answers (Operation 19) and the read's condition off [Read]'s (Operation 50), the read off the redeem and revoke refusal orders, Term database read deleted, state-unavailable off every signature, and the failed read off the case table and the redeem example; rules 203 to 201. *Over:* the page stating for itself what every action answers when the capability records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's sixth Final Critique had made one of the cures the contract's Read family is written from. What each action answers on an answered read is unchanged, [Redeem]'s storage failure included.

- **2026-10-21 — A failed read and a refused write answer on every action, [Redeem] included; each writing action's refusals answer in one stated order; the effective status reads the stored status; the length cap refuses only the writes; a count is whole, and the default window positive.** *Chose:* state-unavailable on all four actions where the read of the capability records fails, the Execution Contract's Step 1 failure (Operation 62, Term database read), and storage-failure on [Redeem] where the database refuses its write, the contract's Step 3 failure (Operation 63), the arm the row titled *A mutating action with no write-failure outcome* in `open-questions.md` had parked; one refusal order for each writing action, the read first, since the pipeline reads at Step 1 before any guard (Operation 64 through 66), Expiry 8 and Expiry 9 deleted to Operation 26 and Operation 38, which the orders hold, and [Read]'s answer held to an answered read; Invariant 13.4 and Check 4.3 resting the effective status on the stored status, expiry instant and now, as Term effective status already did; String 7 naming [Allocate], and String 9 and String 10 refusing an over-long revoked by reference or reason only on a revocable capability, so [Redeem] and [Read], which refuse no length, meet none, and an over-long token names no capability; a supplied max redemptions held to the whole counts (Operation 61, Term whole count); the default capability ttl held above the zero duration (Capability requirement 6), and Operation 13's floor held to a supplied ttl. *Over:* a redeem whose refused write one build answers storage-failure, as the contract obliges, and another `invalid(exhausted)`; a failed read no signature names; a length refusal obliged on two actions whose signatures carry none; an invariant the page's own Term breaks on every revoked capability past its deadline; a fraction the first redeem lowers below zero; and a configured default of zero or less, which one build refuses and another allocates as a window already closed. *Because:* Final Critique 6 found each a divergence between conforming builds, or two rules no build can both obey, and the corpus already held each cure: Actor Identity's fifth round and the rounds after it answer the failed read on every action, Session's sixth round cured the effective status, the length cap and the default window on its twin mechanics, and Capacity Constraint Enforcement declares its whole counts. The write arm is the one cure the corpus leaves: the maintainer's Database contract, which the atom takes (Capability requirement 5), guarantees no write commits, so no host obligation could make the write unfailable. What the atom answers a well-formed call on a database that reads and writes is unchanged.

- **2026-10-22 — The length refusal's split stays the page's own.** *Chose:* String 7, String 9 and String 10 kept as written, the category reach's flag removed: GRACE-lang Closed vocabulary 29 now reads a rule over several actions as binding each only where its signature carries the outcome, so [Redeem] and [Read] would meet no length refusal under one rule over every action, but the split also refuses on [Revoke] only an over-long revoked by reference or reason, and only on a revocable capability, as Operation 39 and Operation 40 refuse a blank one; one rule over every action would also refuse an over-long capability token on a revocable capability, which the page leaves to the token's own lookup. *Over:* String 7 written again as one rule over every action, the page's form before its sixth Final Critique. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the category reach among them, and that a page keeps its own rule where its domain differs. What each action does and answers is unchanged.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
- **2026-09-15 — Clock dependence 1 and 2, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. Both rules keep the words they carried as Clock semantics 4 and 5; only the heading changed.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Capability](./capability.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 8. Invariant 12.1 owns it.
Deleted: Identity 11. Invariant 12.2 owns it.
Deleted: Identity 13. Non-goal 1 owns it.
```

### Structure › State

```
Deleted: State 3. Invariant 10.1 owns it.
Deleted: State 5. Invariant 6.2 owns it.
Deleted: State 8. Invariant 13.1 owns it.
Deleted: State 9. Invariant 13.2 owns it.
Deleted: State 10. Invariant 3.4 owns it.
Deleted: State 14. Non-goal 3 owns it.
```

### Structure › State › Expiry

```
Deleted: Expiry 1. Invariant 13.3 owns it.
Deleted: Expiry 8. Operation 26 owns it.
Deleted: Expiry 9. Operation 38 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Clock dependence 1 owns it.
Deleted: Clock semantics 5. Clock dependence 2 owns it.
Deleted: Clock semantics 6. Non-goal 28 owns it.
```

### Structure › Operations

```
Deleted: Operation 20. Invariant 3.1 owns it.
Deleted: Operation 30. Operation 71 owns it.
Deleted: Operation 34. Execution Contract Database 1 owns it.
Deleted: Operation 45. Execution Contract Database 1 owns it.
Deleted: Operation 49. Execution Contract Database 3 owns it.
Deleted: Operation 55. Capability requirement 1 owns it.
Deleted: Operation 56. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 57. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 61. Execution Contract Input 1 owns it.
Deleted: Operation 62. Execution Contract Read 1 owns it.
Deleted: Operation 64. Execution Contract Read 1 owns it: after the read, every refusal rule of [Allocate] answers invalid-request.
Deleted: Operation 66. Execution Contract Refusal 1 owns it.
Deleted: Operation 67. Execution Contract Input 1 owns it.
```

### Structure › Invariants › Invariant 2 — Redemption counter monotonic

```
  Deleted: Invariant 2.2. Operation 17 owns it.
  Deleted: Invariant 2.4. Operation 71 owns it.
```

### Structure › Invariants › Invariant 4 — Exhaustion atomicity

```
  Deleted: Invariant 4.1. Execution Contract Database 1 owns it.
  Deleted: Invariant 4.2. Execution Contract Database 2 owns it.
  Deleted: Invariant 4.3. Execution Contract Database 2 owns it.
  Deleted: Invariant 4.5. Execution Contract Database 1 and Execution Contract Database 3 own it.
  Deleted: Invariant 4.6. Execution Contract Database 3 owns it.
  Deleted: Invariant 4.7. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 8 — Scope immutability

```
  Deleted: Invariant 8.2. Non-goal 29 owns it.
```

### Structure › Invariants › Invariant 11 — Capability durability over this atom's own surface

```
  Deleted: Invariant 11.3. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 12 — Capability token uniqueness

```
  Deleted: Invariant 12.3. Identity 6 owns it.
```

### Generation acceptance › Conformance checks › External checks

```
Deleted: External check 3. Check 1.2 owns it.
```

### Non-goals

```
Deleted: Non-goal 4. Composition note 2 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it: the counter's read and write are one transaction, and the atom names no rule left for a compare-and-set to discharge.
```

### Edge cases › String policy

```
Deleted: String 8. Execution Contract Logic confinement 13 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Capability requirement 9 owns it.
Deleted: Composition note 7. Execution Contract Atom interface 1 owns it.
```
