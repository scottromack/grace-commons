---
title: Subscription — history
nav_exclude: true
search_exclude: true
---

# Subscription — history

The dated record of how [Subscription](./subscription.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/subscription.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-11-20 — The audience cap, and Lost ledger 4 names no recovery pattern.** *Chose:* [Subscribe] answers scope-full (Operation 33) when an event scope already holds as many active subscriptions as the audience cap allows, 10,000 where a deployment declares none, with Capability requirement 9 citing Execution Contract Input 2, scope-full listed after already-subscribed so an active pair answers already-subscribed first, and [Subscribers For] answering never more than the cap; Lost ledger 4 tells a deployment needing recovery from a lost subscription id to supply it as the deployment's own operating policy, outside the atom. *Over:* leaving [Subscribers For] unbounded with a note that a specification whose domain needs a cap states its own (Read 6); naming an administrative-recovery pattern no page, link or roadmap row carries. *Because:* the maintainer's direction on the open-line choices (rounds/open-line-choices-directions.md, group 8) prefers an explicit cap and refusal for a field an attacker or operator controls, and the subscribers of one scope are written by any caller; its group 4 says what bears on interoperability or audit is named in the atom and operating policy is a deployment capability, and no declared surface of the atom returns a subscription id to such a recovery (Cancel capability 2). The cap follows [Cart]'s line cap (Operation 24). Overrulable: dropping the cap is Operation 33, Capability requirement 9, the case-table row, the [Scope Full] entry and the model's check; the open lines 2026-11-03-a and 2026-11-03-b closed here.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the nine invariant numbers unchanged, Generation acceptance as conformance checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan; this atom carries no cross-spec citations, so the rewrite is free of frozen-number risk.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the subscription store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the seven rules that restated them tombstoned to their owner — Cancel atomicity 1, a cancel changing status and cancellation instant together, to Store 1; Cancel atomicity 2 and 3, no crash inside [Cancel] leaving a cancelled status without its cancellation instant or a cancellation instant on an active subscription, to Store 1 and Store 3; Pair race 1, the pair check and the write one transition, to Store 1 and Store 2; Pair race 2, no two active subscriptions for one pair under concurrent calls, and Pair race 3, a store's uniqueness constraint discharging Pair race 1, to Store 2; Operation 15, a refused write leaving the store as the call found the store, to Store 3; rules 99 to 93. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. At most one active subscription per pair stays the atom's own (Invariant 6.1, Operation 6), as do the atom deleting no subscription (State 7) and the recorded fields that never change (Invariant 1.1). The subscription ids a composing pattern recorded are that pattern's records, not this atom's, so their durability stays the composing pattern's to own (Lost ledger 2, Composition note 3a) and no Store rule the atom cites reaches them. A scope's audience at a past instant is read from the subscription and cancellation instants each subscription carries, and [Subscribers For] answers unordered, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — The wiring declaration is an external check.** *Chose:* Check 5.1 deleted to External check 1, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration. *Over:* a conformance check no subscription record can answer, under an acceptance an external auditor clears from the subscription records' stored fields. *Because:* Final Critique 5 found that a conforming deployment fails it, and the corpus held the cure: the external check to which seven atoms had moved the same check. Smaller fixes rode with it, none changing what a rule means: Invariant 9.1 compares the two instants with PRECEDES (GRACE-lang Earned vocabulary 18), and the term entries no longer call the order best-effort, since it rests on a clock whose readings never go backward, which the deployment owns (Execution Contract Logic confinement 7, to which Clock semantics 1 through 3 were deleted); Identity 3 is deleted to Execution Contract Logic confinement 3, which it restated. What each action does on a call it admits is unchanged.

- **2026-10-22 — The wiring is read outside the records, as the Execution Contract says.** *Chose:* External check 1, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 5.1's tombstone, which named it, now naming the contract, the checks NOTE's sentence restating it removed, and the label cited on Capability requirement 5; rules 92 to 91. *Over:* the page stating for itself that the wiring is an external check. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration among them; this page's fifth Final Critique had made the cure one specification at a time. What each action does and answers is unchanged.

- **2026-11-02 — The string cap has a default.** *Chose:* the string cap stated as 256 Unicode code points where a deployment declares none, Capability requirement 7 added, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; both string inputs, a subscriber reference and an event scope, are opaque references, and 256 code points holds an email address (254) with room to spare.

- **2026-11-26 — The atom converted to the bond shape, batch 5 of the converter: it offers the subscription id, read by a new [Read Subscription], and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; `Term offer key: key subscription id; carried by subscriptions; calls Read Subscription` (Bonds Key 9, 10, 26), the subscription id declared (Key 18). No action read one subscription by its id ([Subscribed] and [Subscribers For] take other keys), so [Read Subscription] answers one (Operation 34 through 36), as Opus chose for Condition Register (ae6d2e48). No need: the subscriber reference is opaque. The three `MUST compose <pattern>` Non-goals (4, 14, 18) tombstoned to the Non-goal that states what the atom does not do; Cancel capability 3 composes a permission pattern by its job; the example heading, the WHY, Term composing pattern and the NOTEs say each job, not a pattern. Labelled rules 95 before, 95 after; 580 lines before, 650 after. *Over:* the drafted actor id need. *Because:* unit `atom: Subscription, converted` (batch 5, 5 of 5).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Subscription](./subscription.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
```

### Structure › State

```
Deleted: State 6. Invariant 2.2 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
```

### Structure › Operations

```
Deleted: Operation 15. Execution Contract Database 3 owns it.
Deleted: Operation 21. Term event scope owns it.
Deleted: Operation 26. Capability requirement 1 owns it.
Deleted: Operation 27. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 28. Execution Contract Logic confinement 3 owns it.
```

### Structure › Invariants › Invariant 2 — Status monotonicity

```
  Deleted: Invariant 2.1. State 1 owns it.
```

### Structure › Invariants › Invariant 3 — Cancellation is terminal

```
  Deleted: Invariant 3.1. Operation 10 owns it.
  Deleted: Invariant 3.2. Operation 20 owns it.
```

### Structure › Invariants › Invariant 8 — Absence means not-subscribed

```
  Deleted: Invariant 8.2. Operation 20 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 1. Execution Contract Conformance 9 owns it.
```

### Edge cases › Atomicity of a cancel

```
Deleted: Cancel atomicity 1. Execution Contract Database 1 owns it.
Deleted: Cancel atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Cancel atomicity 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
```

### Edge cases › The pair race

```
Deleted: Pair race 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Pair race 2. Execution Contract Database 2 owns it.
Deleted: Pair race 3. Execution Contract Database 2 owns it: the pair check and the write are one transaction, and the atom names no rule left for a uniqueness constraint to discharge.
```

### Composition notes

```
Deleted: Composition note 1. Capability requirement 8 owns it.
Deleted: Composition note 3a. Lost ledger 2 owns it.
Deleted: Composition note 3b. Lost ledger 3 owns it.
Deleted: Composition note 4. Non-goal 12 owns it.
```
