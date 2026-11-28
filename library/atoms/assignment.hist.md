---
title: Assignment — history
nav_exclude: true
search_exclude: true
---

# Assignment — history

The dated record of how [Assignment](./assignment.idd) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/assignment.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the five actions as a signature block, the refusal order carried by each rule's own condition, the ten invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into assignment` prints nothing, so no number is frozen from outside.

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the assignment store supplied under Execution Contract Store 1 through 4 (Capability requirement 4), and the twelve rules that restated them tombstoned to their owner — Operation 20, Invariant 7.3 and 7.4 and Reassign atomicity 1, the reassign's two writes committed together with no reader seeing one without the other, and Reassign atomicity 4, the repair owed for a landed half, to Store 1; Operation 23, both writes withdrawn on storage-failure, and Reassign atomicity 2 and 3, a crash inside [Reassign] leaving the task neither unassigned nor held twice, to Store 1 and Store 3; Assign race 1, the active-assignment check and the write as one transition, and External check 4, the deployment's evidence of that atomicity and serialization, to Store 1 and Store 2; Assign race 2 and 3, two concurrent assigns never both recording and the later answering already-assigned, to Store 2; rules 110 to 99. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. A handoff is still one action, not a recall followed by an assign (Operation 18 and 19, Invariant 7.1 and 7.2); the atom's own no-delete rules stay (State 10, Invariant 10.1 and 10.2), and so does a refused call leaving the store as found (Operation 24), which covers the guard refusals no Store rule reaches. A task's responsibility chain is separate records ordered by assignment instant, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — A failed read answers on every action, each write's refusals in one stated order; a tie of assignment instants falls to commit order; the wiring declaration is an external check; a holding's end is its terminal stamp.** *Chose:* state-unavailable on all five actions where the read of the assignment records fails, the Execution Contract's Step 1 failure (Operation 34, Term database read), [Active For] and [History For] answering only on an answered read (Operation 25 through 27); the refusals of [Assign], [Recall] and [Reassign] in one stated order each, the read first and then the sequence Final Critique 4's prose gave — the inputs before already-assigned, and a known assignment, then an active one, then the successor (Operation 35 through 37, Term assign refusal order, Term recall refusal order, Term reassign refusal order); two assignments sharing an assignment instant ordered by the commit that recorded each (Operation 28a, Term recording commit), the records supplied under Execution Contract Order 1 beside Database 1 through 4 (Capability requirement 4), and Check 2.1 and the acceptance bar reading that order; the composing patterns a deployment wired in read from the deployment's own declaration (External check 5); and Invariant 9.3, which asked an active holding how it ended, deleted to State 3 and State 4. *Over:* [Active For] answering none, and a write answering no code the page names, when the records cannot be read; one reassign answered two ways by two builds; a [History For] two builds order two ways, and a chain of handoffs at one instant no auditor can rebuild; a conformance check reading what the records do not carry; an invariant every assign breaks. *Because:* Final Critique 5 found each a divergence between conforming builds, or a stated check a conforming build fails, and the corpus already held four of the cures: Actor Identity's fifth round answers a failed read on every action and reads the composing patterns from the deployment's declaration; Retention Window's eighth answers each writing action's refusals in one stated order, the form the maintainer ruled for Verified Repair on 2026-10-19; and Party Identity cites Order 1 beside the Database contract. The entry of 2026-10-19 said a task's chain needs no Order 1, the assignment instants ordering it; a clock that repeats a reading, which Logic confinement 7 allows, ties them, and only the commit order keeps the chain. Compositions affected: the pages that compose this atom route state-unavailable from all five actions, when their rounds read them.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 4, Execution Contract Read 1 through 3) and the rule that restated it, the atom-wide state-unavailable (Operation 34), deleted to Read 1; the read's condition off the read answers it held to an answered read (Operation 25 through 27), the read off the assign, recall and reassign refusal orders, Term database read deleted, state-unavailable off every signature, and the failed read off the case table and the rejection-path example, which now exercises five reasons; rules 103 to 102. *Over:* the page stating for itself what every action answers when the assignment records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's fifth Final Critique had made one of the cures the contract's Read family is written from. What each action answers on an answered read is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each writing action's refuses line kept as the page wrote it, already in the order its refusal order gave — [Assign] invalid-request, already-assigned; [Recall] not-known, not-active; [Reassign] not-known, not-active, invalid-request; storage-failure last on each, answering only at the write — and the order cited from the Execution Contract (Capability requirement 4, Execution Contract Refusal 1); Operation 35, Operation 36 and Operation 37, which evaluated the three refusal orders, deleted to Refusal 1, and Term assign refusal order, Term recall refusal order and Term reassign refusal order deleted with them; rules 102 to 99. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's fifth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-22 — The wiring is read outside the records, as the Execution Contract says.** *Chose:* External check 5, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 5.1's tombstone, which named it, now naming the contract, and the label cited on Capability requirement 4; rules 99 to 98. *Over:* the page stating for itself that the wiring is an external check. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration among them; this page's fifth Final Critique had made the cure one specification at a time. What each action does and answers is unchanged.

- **2026-11-25 — The atom reorganised into the tree order and bonded: an assignment pairs a task id with an actor id, appends to a journal, and no pattern is named.** *Chose:* the tree order Task, List and Ordering stand in, every label kept and none renumbered; the task reference is a task id and the assignee and new assignee references are actor ids, met by the needs `key task id; pairs assignments`, `key actor id; pairs assignees` and `journal: records assignment events; calls append; arms event_id`; Operation 40 (an admitted [Assign], [Recall] or [Reassign] appends one assignment events record through the journal need, as Task's Operation 48 does, else the need is unused); a claim is an assignment whose assignee the app passes as the caller, a glue line of the app's, not a rule here; Non-goal 2, 4, 6 and 8 (each "MUST compose" a named pattern) tombstoned to the Non-goal that owns the declined job; External check 1 and 2, the owners NOTE and the healthcare example say each job without naming a pattern. *Over:* opaque references no atom offers, and a page naming four other patterns. *Because:* Scott's ruling of 2026-11-25 9:49 AM Central ("Go with your 'task'"), the unit `atom: Assignment, bonded`.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Assignment](./assignment.idd) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it: a rule that the transition MUST NOT allocate an id restates it.
Deleted: Identity 4. Execution Contract Logic confinement 14 owns it: the business caller is never the source of an injected value.
Deleted: Identity 5. Invariant 6.1 owns it.
Deleted: Identity 8. Invariant 6.1 owns it.
```

### Structure › State

```
Deleted: State 8. Invariant 4.1 owns it.
Deleted: State 9. Invariant 4.2 owns it.
Deleted: State 10. Invariant 10.1 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. State 13 owns it.
```

### Structure › Operations

```
Deleted: Operation 3. The assign signature's answers line owns it (Closed vocabulary 21 and Closed vocabulary 25).
Deleted: Operation 20. Execution Contract Database 1 owns it.
Deleted: Operation 21. The reassign signature's answers line owns it (Closed vocabulary 21 and Closed vocabulary 25).
Deleted: Operation 23. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Operation 24. Execution Contract Read 4 and Execution Contract Database 3 own it: a refused call writes nothing, and a write that did not commit leaves nothing.
Deleted: Operation 30a. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 31. Capability requirement 1 owns it.
Deleted: Operation 32. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 33. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 34. Execution Contract Read 1 owns it.
Deleted: Operation 35. Execution Contract Refusal 1 owns it.
Deleted: Operation 36. Execution Contract Refusal 1 owns it.
Deleted: Operation 37. Execution Contract Refusal 1 owns it.
```

### Structure › Invariants › Invariant 3 — Status monotonicity

```
  Deleted: Invariant 3.1. State 1 owns it.
```

### Structure › Invariants › Invariant 5 — Id stability

```
  Deleted: Invariant 5.2. Invariant 2.1 owns it.
```

### Structure › Invariants › Invariant 7 — Reassign atomicity

```
  Deleted: Invariant 7.1. Operation 18, Operation 19 and Invariant 1.1 own it: a landed reassign leaves the task reference one active assignment, the one the reassign recorded, and a later recall may leave none.
  Deleted: Invariant 7.3. Execution Contract Database 1 owns it.
  Deleted: Invariant 7.4. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 9 — Complete responsibility history

```
  Deleted: Invariant 9.3. State 3 and State 4 own it: an ended holding carries its recall instant or its transfer instant, and an active one has not ended.
```

### Structure › Invariants › Invariant 10 — Assignment record durability

```
  Deleted: Invariant 10.2. Invariant 10.1 owns it (Execution Contract Database 6).
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 4. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: External check 5. Execution Contract Conformance 9 owns it.
```

### Edge cases › Reassign atomicity

```
Deleted: Reassign atomicity 1. Execution Contract Database 1 owns it.
Deleted: Reassign atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reassign atomicity 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reassign atomicity 4. Execution Contract Database 1 owns it.
```

### Edge cases › The assign race

```
Deleted: Assign race 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Assign race 2. Execution Contract Database 2 owns it.
Deleted: Assign race 3. Execution Contract Database 2 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns it.
Deleted: Composition note 2. Term task reference owns it: the host owns what a task is.
```
