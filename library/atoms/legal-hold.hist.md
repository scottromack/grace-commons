---
title: Legal Hold — history
nav_exclude: true
search_exclude: true
---

# Legal Hold — history

The dated record of how [Legal Hold](./legal-hold.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/legal-hold.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the three actions as a signature block, the read's filter axes and malformed-query grounds as rules rather than a paragraph, the eight invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan, and this atom completes [Defensible Retention](../compositions/defensible-retention.md)'s constituent set with [Retention Window](./retention-window.md) and [Audit Trail](../compositions/audit-trail.md).

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the hold store supplied under Execution Contract Store 1 through 4 (Capability requirement 4), and the five rules that restated them tombstoned to their owner — Invariant 8.3, no partial hold left by a storage-failure from [Place], to Store 1; Concurrency 1 and 2, two releases of one hold id serialized and the later one answering already-released, to Store 2; Operation 22, a release the store refused leaving the hold active, to Store 3; Non-goal 16, a deployment's sweep of the hold store leaving every stored field as written, to Store 4; rules 135 to 131. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The caller's reading of a refused place or release stays the atom's own (Place persistence 1 through 4), as do two placements over one record recording two holds (Concurrency 3), the placement fields that never change (Invariant 1.1) and the atom's no-removal rules (State 7, Invariant 8.1, Invariant 8.2, Non-goal 15). Held at an instant is read from the placement and release instants each hold carries, and [Read] orders by placement instant and hold id, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — [Release]'s refusal order stays the page's own.** *Chose:* Operation 42 and Term release refusal order kept, and only their watch flag removed: [Release] answers invalid-request on a blank hold id ahead of not-known, and on a blank attribution or a time fault after not-known and already-released, so invalid-request holds two places in the order and no fixed refuses line can carry both; the Execution Contract reads a refusal Operation 42 keeps [Release] from answering as not applying to the call (Execution Contract Refusal 1). [Place] and [Read] each answer one refusal before the write, so the page cites nothing new; rules 132 unchanged. *Over:* deleting the order to the contract's rule, which would answer invalid-request ahead of not-known on every call. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers, and that a page keeps its own rule only where its order depends on a condition a fixed line cannot express.

- **2026-10-21 — [Release]'s refusals answer in one stated order; [Read]'s answer carries the database name; the wiring declaration is an external check.** *Chose:* [Release]'s refusal rules evaluated in one order — a blank hold id first, then an unknown hold, a released hold, a blank attribution and the two time guards (Operation 42, Term release refusal order) — the priority Final Critique 4 stated and the GRACE-lang migration dropped; [Read]'s answers arm carrying the database name the read was routed to (`holds(store_name)`), so the name Instance 5 obliges is answered on every answered read, an empty one included; Check 7.1 deleted to External check 5, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration. *Over:* seven refusal rules any two of which could oblige different answers on one call; a database name obliged by a rule and carried by no declared answer, which a build could put on each hold, leaving an empty answer with nothing for a composing pattern to match (Instance 7, Aggregate 3); and a conformance check no hold record can answer. *Because:* Final Critique 5 found each a divergence between conforming builds, two rules no build can both obey, or a check a conforming deployment fails, and the corpus held each cure: the refusal order Approval Step, Retention Window and Selective Disclosure carry, in this page's own Final Critique 4 priority; the signature form, whose arm carries the names an answer holds; and the external check to which Actor Identity, Tamper Evidence, Retention Window, Permissions and Assignment moved the same check. What each action does on a call it admits is unchanged.

- **2026-10-22 — The wiring is read outside the records, and a ban on refusing names its ground, as the Execution Contract says.** *Chose:* External check 5, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 7.1's tombstone, which named it, now naming the contract; Non-goal 4 kept as written and read by Execution Contract Refusal 1's second sentence, so the ban names its ground, a hold over a destroyed record, and keeps [Place] from no refusal its line declares, a blank or malformed input still answering invalid-request; both labels cited on Capability requirement 4; rules 132 to 131. *Over:* the page stating for itself that the wiring is an external check; Non-goal 4 read alone, keeping [Place] from every refusal on a hold over a destroyed record. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration and the refusal ban among them; this page's fifth Final Critique had made the first cure one specification at a time, and the 12:03Z escalation named Non-goal 4 among the refusal ban's uncured sites. What each action does and answers is unchanged.

- **2026-10-24 — [Release]'s refusal order is the Execution Contract's.** *Chose:* the refuses line listing not-known, already-released, invalid-request, then storage-failure, which answers only at the write, and Operation 13 answering not-known only for a hold id that is not blank, so Execution Contract Refusal 1 answers the order the page kept as its own: a blank hold id first, then an unknown hold, a released hold, a blank attribution and the two time guards; Operation 42 deleted to Refusal 1, and Term release refusal order with it. *Over:* Operation 42 kept, which names neither a refusal nor the ground one answers on, so Refusal 1's second sentence reads it as keeping [Release] from no refusal and the line's invalid-request answers ahead of not-known and already-released. *Because:* Final Critique 6 found two builds answering one call differently, one by Operation 42 and one by the refuses line; the maintainer ruled on 2026-10-21 that a page keeps its own order only where a fixed line cannot express it, and with not-known held to a hold id that is not blank, one fixed line expresses this one. What [Release] answers on every call is unchanged.

- **2026-11-02 — The string cap has a default.** *Chose:* the string cap stated as 1,024 Unicode code points where a deployment declares none, Capability requirement 5 added, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs run from references to a free-text reason, and 1,024 code points, the corpus's default for text (Personal Todo's description cap), holds a sentence or two.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Legal Hold](./legal-hold.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 6. Execution Contract Logic confinement 10 owns it.
```

### Structure › State

```
Deleted: State 1. Invariant 2.1 owns it.
Deleted: State 6. Invariant 3.2 owns the absent re-activation.
Deleted: State 7. Invariant 8.1 owns it.
Deleted: State 9. Non-goal 9 owns the case lifecycle.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Non-goal 17 owns it.
```

### Structure › Operations

```
Deleted: Operation 9. Execution Contract Logic confinement 12 owns it.
Deleted: Operation 18a. Execution Contract Logic confinement 12 owns it.
Deleted: Operation 20. Invariant 4.1 owns it.
Deleted: Operation 22. Execution Contract Database 3 owns it.
Deleted: Operation 32. Execution Contract Query 3 and Operation 23 own it.
Deleted: Operation 33. Execution Contract Query 3 and Operation 23 own it.
Deleted: Operation 35. Capability requirement 1 owns it.
Deleted: Operation 36. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 37. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 40. Operation 8 and Operation 10 own it.
Deleted: Operation 41. Operation 17 and Operation 18 own it.
Deleted: Operation 42. Execution Contract Refusal 1 owns it.
```

### Structure › Invariants › Invariant 8 — Hold record durability

```
  Deleted: Invariant 8.3. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 7.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 5. Execution Contract Conformance 9 owns it.
```

### Non-goals

```
Deleted: Non-goal 16. Execution Contract Database 4 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```

### Edge cases › Back-dating a placement or a release

```
Deleted: Backdating 1. Operation 10 owns it.
Deleted: Backdating 2. Operation 8 owns it.
```

### Edge cases › The aggregate question

```
Deleted: Aggregate 3. Instance 7 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns it.
```
