---
title: Notification — history
nav_exclude: true
search_exclude: true
---

# Notification — history

The dated record of how [Notification](./notification.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/notification.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the six actions as a signature block, the three terminal transitions sharing one declared term and one precondition pair, the nine invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into notification` prints nothing, so no number is frozen from outside, and this atom completes [Notification Fanout](../compositions/notification-fanout.md)'s constituent set with [Subscription](./subscription.md).

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the notification store supplied under Execution Contract Store 1 through 4 (Capability requirement 4), and the four rules that restated them tombstoned to their owner — Terminal atomicity 1, a terminal transition changing status and the terminal stamp together, to Store 1; Terminal atomicity 2 and 3, no crash inside a terminal transition leaving a terminal status without its stamp or a stamp on a pending notification, to Store 1 and Store 3; Terminal atomicity 4, two terminal transitions on one notification id serialized, to Store 2; rules 130 to 127. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. A refused call leaving the notification as the call found it stays the atom's own (Operation 16), as do the caller's reading of a refused deliver (Deliver persistence 1 through 4), the payload kept for the store's life and a composed purge leaving every stored field as written (Payload retention 1 through 5), the recorded fields and a landed stamp that never change (Invariant 1.1, Invariant 1.2) and the atom's durability (State 10, Invariant 9.1 through 9.3). Pending at an instant is read from the creation instant and terminal stamp each notification carries, and [Pending For] answers unordered, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — The string cap bounds the recipient reference, and the deployment supplies it; a failed read answers on every action, each writing shape's refusals in one stated order; the wiring declaration is an external check.** *Chose:* String 6's cap on the recipient reference alone, the payload left unmeasured as Operation 6 and Non-goal 10 say (a payload too large to keep is the database's refusal, Operation 7), and Capability requirement 5 obliging the deployment to supply the cap; state-unavailable on all six actions where the read of the notification records fails, the Execution Contract's Step 1 failure (Operation 27, Term database read), [Create]'s refusals and a terminal transition's each evaluated in one order with the read first (Operation 28, Operation 29), and the reads' answer rules held to an answered read (Operation 17 through 19, Invariant 9.3); Check 6.1 deleted to External check 5, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration. *Over:* a cap that reached a payload the atom may neither read nor validate, as Final Critique 4's String input policy had it reach both string inputs; a cap no rule obliged anyone to supply; six actions with no answer for a read that fails; and a conformance check no notification record can answer. *Because:* Final Critique 5 found each a divergence between conforming builds, two rules no build can both obey, or a check a conforming deployment fails, and the corpus held each cure: the page's own payload rules, which say four times that the atom never reads a payload; the requirement form Credential, Party Identity and Medication Order give a length bound; the failed-read form Actor Identity, Approval Step, Capability and Duplicate Prevention carry; and the external check to which six atoms moved the same check. What each action does on a call it admits is unchanged, save that a payload is no longer measured against the cap.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 4, Execution Contract Read 1 through 3) and the two rules that restated it deleted to it: the atom-wide state-unavailable (Operation 27) to Read 1, and the create refusal order (Operation 28), whose rules after the read both answer invalid-request, to Read 1; the read's condition off the read answers it held to an answered read (Operation 17 through 19, Invariant 9.3), the read off the terminal refusal order, Term database read deleted, and state-unavailable off every signature and the case table; rules 131 to 129. *Over:* the page stating for itself what every action answers when the notification records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's fifth Final Critique had made one of the cures the contract's Read family is written from. What each action answers on an answered read is unchanged, and Invariant 9, which Notification Fanout cites, holds on every answered read as it did.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each terminal transition's refuses line kept as the page wrote it, already in the order the terminal refusal order gave — not-known, not-pending, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 4, Execution Contract Refusal 1); Operation 29, which evaluated the terminal refusal order, deleted to Refusal 1, and Term terminal refusal order deleted with it; rules 129 to 128. *Over:* the page stating for itself which of a terminal transition's refusals answers when both apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's fifth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-22 — The wiring is read outside the records, as the Execution Contract says.** *Chose:* External check 5, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 6.1's tombstone, which named it, now naming the contract, the checks NOTE's sentence restating it removed, and the label cited on Capability requirement 4; rules 128 to 127. *Over:* the page stating for itself that the wiring is an external check. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration among them; this page's fifth Final Critique had made the cure one specification at a time. What each action does and answers is unchanged, and Invariant 9, which Notification Fanout cites, stands as it was.

- **2026-11-02 — The string cap has a default.** *Chose:* the string cap stated as 256 Unicode code points where a deployment declares none, Capability requirement 5 turned to *declare*, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the one string input the cap bounds is the recipient reference, an opaque reference, and 256 code points holds an email address (254) with room to spare; the payload stays outside the cap, as the page left it, and String 6 and Capability requirement 6 stand.

- **2026-11-26 — The atom converted to the bond shape, batch 4 of the converter: it offers the notification id and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; `Term offer key: key notification id; carried by notifications; calls Status Of` (Bonds Key 9, 10, 26), the notification id declared (Key 18). No need: the recipient reference is opaque and never interpreted, so it pairs with no other atom's key. Payload retention 3 and Composition note 5 compose a retention pattern and an idempotency pattern by job; External check 2 and 3, What it is, a WHY sentence, the example, a scenario and both NOTEs say each job, not a pattern. Labelled rules 125 before, 125 after; 677 lines before, 745 after. *Over:* the drafted actor id need, which would bind every recipient to an actor. *Because:* unit `atom: Notification, converted` (batch 4, 5 of 5).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Notification](./notification.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Non-goal 16 owns it.
```

### Structure › Operations

```
Deleted: Operation 21. Execution Contract Read 5 owns it.
Deleted: Operation 24. Capability requirement 1 owns it.
Deleted: Operation 25. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 26. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 27. Execution Contract Read 1 owns it.
Deleted: Operation 28. Execution Contract Read 1 owns it: after the read, every refusal rule of [Create] answers invalid-request.
Deleted: Operation 29. Execution Contract Refusal 1 owns it.
Deleted: Operation 30. Execution Contract Input 4 owns it.
```

### Structure › Invariants › Invariant 2 — Status monotonicity

```
  Deleted: Invariant 2.1. State 1 owns it.
```

### Structure › Invariants › Invariant 3 — Terminal states are exclusive

```
  Deleted: Invariant 3.2. State 6 owns it.
```

### Structure › Invariants › Invariant 4 — Terminal timestamps match status

```
  Deleted: Invariant 4.1. State 3 owns it.
  Deleted: Invariant 4.3. State 4 owns it.
  Deleted: Invariant 4.5. State 5 owns it.
```

### Structure › Invariants › Invariant 5 — Id stability

```
  Deleted: Invariant 5.2. Invariant 1.1 owns it.
```

### Structure › Invariants › Invariant 7 — Pending query excludes terminals

```
  Deleted: Invariant 7.1. Operation 20 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 5. Execution Contract Conformance 9 owns it.
```

### Non-goals

```
Deleted: Non-goal 7. Execution Contract Read 5 owns it.
```

### Edge cases › String policy

```
Deleted: String 5. GRACE-lang Term blank owns it.
```

### Edge cases › Atomicity of a terminal transition

```
Deleted: Terminal atomicity 1. Execution Contract Database 1 owns it.
Deleted: Terminal atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Terminal atomicity 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Terminal atomicity 4. Execution Contract Database 2 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Capability requirement 7 owns it.
Deleted: Composition note 2. Capability requirement 8 owns it.
Deleted: Composition note 7. Operation 14b owns it.
```
