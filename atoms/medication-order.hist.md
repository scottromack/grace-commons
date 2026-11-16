---
title: Medication Order — history
nav_exclude: true
search_exclude: true
---

# Medication Order — history

The dated record of how [Medication Order](./medication-order.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/medication-order.md`.

## Decisions

Entries that record a taxonomy test rather than a turn the pattern took, and the turn that gave the amend's two writes one transaction and an order its own critical section, which the Store contract took over on 2026-10-20.

- **2026-09-13 — The EOS strip test: the tag is earned, and it is earned by the graph rather than by the guards.** *Chose:* keep `domain: healthcare`, and correct the reason `atoms/TAXONOMY.md` records for it. *Over:* the standing justification, which names the *guards* as irreducibly clinical — verification gating dispensing, the verified-dispensed-administered pipeline, controlled-substance attestation. *Because:* each of those guards is individually derivable from a neutral primitive the corpus already holds. One actor authorizing and a different actor releasing is [Approval Step](./approval-step.md)'s shape. A three-stage custody pipeline is [Chain of Custody](../compositions/chain-of-custody.md)'s. Attributed actions are [Actor Identity](./actor-identity.md)'s. Twelve of the fourteen invariants here strip clean, and the two that do not — Invariant 3.1 and Invariant 6.1 with Invariant 6.2 — both pivot on one thing: an irreversible release, after which the record describes something in another party's custody. That pivot is not clinical either; a warehouse has it.

  What does not strip is the *graph*. Nine states in this topology, with the amendment boundary and the cancel/discontinue split landing on exactly the dispensing edge, is not derivable from neutral primitives — a generic state machine plus a supplied graph is just this atom with the domain moved into a parameter, and the parameter would carry every clinical judgment the graph encodes. The domain hides in the shape, not in the words and not in the rules. The formal layer corroborates: this is the only atom in the migrated set carrying both an Alloy model and a TLA model, and the Alloy model exists because the *structure* needed checking rather than the timing.

  Three specimens now, three hiding places: [Observation](./observation.md) hid nothing and was renamed; [Party Identity](./party-identity.md) hid it in the field schema and kept both name and no tag; this one hides it in the graph and keeps the tag. The test's site-census grows by one per specimen, which is the argument for running it on every atom rather than on the ones that look domain-shaped.
- **2026-08-30 — One writer per transition, and no repair leg.** *Chose:* transactional atomicity of the atom's own store as the only conforming implementation of [Amend]'s two writes, the crash-recovery scan withdrawn; the per-id serialization stated as a critical section — taken before the state check, released on return or death — with a stalled or re-issued invocation re-reading under the critical section and landing an existing rejection; a re-entry arm for a caller whose [Amend] lost its response, retrying only where the original is still amendable; and a deployment-declared clock offset allowance under which the future-dated check on a supplied [Order Instant] runs. *Over:* a scan "that detects and repairs dangling amendment links on restart" offered as an equal alternative to a transaction; a caller left to retry [Amend] blind, which on an original still [Ordered] creates a second successor; a future-dated refusal decided by comparing the caller's stamp to the node's clock with no margin. *Because:* the scan presumed a visible partial record that Invariant 14.2 says never exists, could relink one dangling shape but not the other — the successor's dosing parameters, [Amending Actor] and its amendment reason are nowhere in the store, and un-marking the original rewrites a write-once field — and made a second writer for an amendment the caller's retry could already have landed, branching a chain Invariant 4.1 keeps linear; and a caller's stamp and the node's reading are two clocks, so a refusal resting on their comparison needs the margin on the page.

- **2026-11-02 — The length bound has a default.** *Chose:* the length bound stated as 1,024 Unicode code points where a deployment declares none, the unit written as Unicode code points as Permissions, Credential and Provenance count theirs; String 7 stands, Capability requirement 12 turned to *declare*, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs run from references to a free-text reason, and 1,024 code points, the corpus's default for text (Personal Todo's description cap), holds a sentence or two.

- **2026-10-20 — The store's guarantees cited, not restated, the order's critical section among them.** *Chose:* the order store supplied under Execution Contract Store 1 through 4 (Capability requirement 15), and the twenty rules that restated them, or existed only for a store that could split an amend, tombstoned to their owner — Capability requirement 10, Operation 41 and Atomic writes 4, an admitted amend's two writes committed together, Operation 61 and Atomic writes 1 and 3, a transition's state change and recorded fields committed whole inside the implementation's transactional boundary, Invariant 14.2 and Check 7.3, no partial record left by a storage-failure rejection and the check that finds none, and Invariant 14.3, no repair of a partial record, to Store 1, under which no amend stands half-written; Atomic writes 2, an uncommitted transition discarded whole, to Store 1 and Store 3; Atomic writes 5, a refused amend leaving the original in its pre-call state, to Operation 64 and Store 1; Capability requirement 9, a write acknowledged only once it commits, to Store 3; Capability requirement 5 and 6 and Concurrency 1 through 3, two order actions on one order serialized, the state check evaluated inside the critical section with the state change, and a losing action reading the winner's state and answering the rejection it earns, to Store 2, and with them the section's release on the caller's return and death (Capability requirement 7 and 8) and the bar on detecting a race outside it (Concurrency 4), since the atom names no section any more; rules 230 to 211. *Over:* the atom running its own critical section over an order, released on the caller's return or death, and keeping a no-repair rule for a split amend that no conforming store leaves — the turn of 2026-08-30, now in the history. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract: Store 2 reads the state an order action's guards decide on inside the transaction that writes the action's effects, which is what the section was for, and Store 1 commits [Amend]'s successor and the original's change together or not at all, so no partial record is left to repair. A refused action leaving the order as the call found it, and a refused [Order] or [Amend] recording no order, stays the atom's own (Operation 64 through 66), as do the rules that keep an order once it exists (State 15, Operation 67, Invariant 14.1), since Store 4 alone neither keeps the atom from removing an order nor bars a purge another specification declares. Amendment chains are the atom's own records, linked by predecessor and successor ids, [Read] answers by order instant, and the atom's checks compare an auditor's own reads, so it cites neither History 1 nor Order 1. The re-entry arm for a caller whose [Amend] lost its answer (Indeterminate outcome 3) and the clock offset allowance (Capability requirement 3 and 4) stay as the 2026-08-30 turn set them; what the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the page's order — not-known, the hold, the inactive states, the action's own state rejections, then a blank-input rejection on a field fault once every state check passes, and storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 15, Execution Contract Refusal 1); the pairs that only stated it deleted to Refusal 1: Operation 15 (an inactive-state rejection only on an order not on hold), Operation 28 (a field fault only once every state check passes) and Operation 63 (storage-failure behind every precondition), and Operation 15 taken off Term state check; rules 211 to 208. Operation 12 stays the page's own: a blank order id answers its blank-input rejection ahead of not-known, while every other field fault answers after the state checks, so the rejection holds two places in the order and no fixed line can carry both; Refusal 1 reads a refusal Operation 12 keeps from a call as not applying to it. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-22 — Every refusal on a line is answered where it belongs, an amendment carries its evidence, and a composed retention may purge what the atom never removes.** *Chose:* Operation 19 through 21 answering not-verified on an ordered order, already-dispensed on a dispensed or administered one and not-dispensed on a pre-dispensing one, as Final Critique 4's text had them, so every arm of [Dispense]'s and [Administer]'s refuses lines answers some call; Invariant 3.1, Invariant 6.1 and Invariant 6.2 restated as what [Amend], [Cancel] and [Discontinue] may change (*MUST change an order ONLY IF the order's state IS IN …*); a successor inheriting the original's clinical evidence reference (Operation 33); State 15 deleted to Invariant 14.1 and Execution Contract Database 4, and Check 7.1 and Check 7.2 to External check 9, the page read as Final Critique 4's text read it: the atom never removes an order, and eventual destruction is a composing Retention Window's; String 7 and String 8 refusing an over-long string on [Order] and the order actions alone; Term held-refusing action and a new Term inactive-refusing action leaving out the actions whose signatures carry no on-hold or inactive-state refusal, with Operation 83 holding [Amend]'s inactive-state refusals to the three its line carries and Operation 25 deleted to Operation 14 and Operation 26; and Invariant 12.1 setting aside the hold and reinstate fields Invariant 12.2 and Invariant 12.3 replace each cycle, as Final Critique 4's Invariant 12 did. *Over:* the migration's guards, which answered not-verified on a dispensed order and not-dispensed on an administered one; ONLY IF tails that, read alone, kept each action from every refusal the operations oblige; a successor whose evidence reference no rule decided; the 2026-10-20 entry's reading that State 15, Operation 67 and Invariant 14.1 bar a purge another specification declares; rules over every action or every order action that landed refusals outside a member's signature; and a write-once rule that forbade the hold cycle. *Because:* Final Critique 5 found the seven, and each but the evidence reference stood soundly in Final Critique 4's text or is the corpus's own cure: Selective Disclosure, Party Identity, Provisional Commitment, Observation, Capacity Constraint Enforcement, Message Preference and State Machine cured the composed erasure the same way, and Session, Capability and Party Identity held their String 7 to the actions that refuse it. Smaller fixes rode with them: Operation 80 refuses a non-positive quantity, as Final Critique 4's text did; Operation 81 stamps a successor's order instant and Operation 82 orders two orders sharing an order instant by order id; the ten refusal entries Final Critique 4 carried are restored; the Summary glosses its four dosing terms and the acronyms are spelled out; Term successor ids and Term predecessor ids are gone; rules 208 to 210. What each action answers and writes on a call it admits is unchanged, but that a successor carries the original's clinical evidence reference and is stamped with now as its order instant.

- **2026-10-22 — An admitted call, a composed purge, a ban's ground and an action set's reach are stated once.** *Chose:* the ten admitted terms citing Execution Contract Read 4 for what an action admits, in place of the commit clause each carried; External check 9, a composing Retention Window's purge records read beside the order records, deleted to Execution Contract Database 6, with the tombstones of Check 7.1 and Check 7.2, which named it, now naming the contract; Term held-refusing action and Term inactive-refusing action, the helper terms this page's fifth Final Critique wrote, deleted, with Operation 13 and Invariant 9.1 naming an order action, Operation 14 a state-changing action as the page first had it, and Operation 83, [Amend]'s split, deleted to Operation 14 and GRACE-lang Closed vocabulary 29, under which each rule binds an order action only where the action's signature carries the outcome: on-hold on every order action but [Hold] and [Reinstate], and the inactive state's rejection on every one but [Reinstate], [Amend] answering it on an amended, cancelled or discontinued order and not on a completed one, whose already-completed its signature does not carry; String 7 written again as the page first had it, an over-long string input answering an action's blank-input rejection, and String 8 deleted to String 7 and Closed vocabulary 29, which leaves [Read], whose signature carries invalid-query alone, outside it; Invariant 3.1, Invariant 6.1 and Invariant 6.2 stand as the fifth Final Critique restated them, rules of what an action may change; Database 6 and Read 4 cited on Capability requirement 15; rules 210 to 207. *Over:* the page stating for itself which calls its effect rules reach, that a purge another specification declares is answered outside the order records, and which order actions each state rejection reaches. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect, the composed erasure, the refusal ban and the category reach among them; this page's fifth Final Critique had made all four one specification at a time. What each action does and answers is unchanged.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Medication Order](./medication-order.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 14. Execution Contract Database 7 owns it.
```

### Structure › State

```
Deleted: State 15. Invariant 14.1 and Execution Contract Database 4 own it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 5. Execution Contract Database 2 owns it.
Deleted: Capability requirement 6. Execution Contract Database 2 owns it.
Deleted: Capability requirement 7. Execution Contract Database 2 owns it: an order action's state check and state change are one transaction, and the atom names no section to release.
Deleted: Capability requirement 8. Execution Contract Database 2 owns it: an order action's state check and state change are one transaction, and the atom names no section to release.
Deleted: Capability requirement 9. Execution Contract Database 3 owns it.
Deleted: Capability requirement 10. Execution Contract Database 1 owns it.
Deleted: Capability requirement 11. Execution Contract Logic confinement 13 owns it.
Deleted: Capability requirement 13. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 14. Execution Contract Logic confinement 7 owns it.
```

### Structure › Operations

```
Deleted: Operation 4. Execution Contract Logic confinement 12 owns it.
Deleted: Operation 83. Operation 14 and GRACE-lang Closed vocabulary 29 own it.
Deleted: Operation 15. Execution Contract Refusal 1 owns it.
Deleted: Operation 25. Operation 14 and Operation 26 own it.
Deleted: Operation 28. Execution Contract Refusal 1 owns it.
Deleted: Operation 41. Execution Contract Database 1 owns it.
Deleted: Operation 61. Execution Contract Database 1 owns it.
Deleted: Operation 63. Execution Contract Refusal 1 owns it.
Deleted: Operation 78. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 79. Execution Contract Logic confinement 3 owns it.
```

### Structure › Invariants › Invariant 14 — Order record durability

```
  Deleted: Invariant 14.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 14.3. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 7.1. Execution Contract Database 6 owns it.
Deleted: Check 7.2. Execution Contract Database 6 owns it.
Deleted: Check 7.3. Execution Contract Database 1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 9. Execution Contract Database 6 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 5. Operation 64 and Execution Contract Database 1 own it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 3. Execution Contract Logic confinement 12 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 6. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 7. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 8. Non-goal 25 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 2 owns it: an order action's state check and state change are one transaction, and the atom names no section for a race to fall outside.
```

### Edge cases › Indeterminate outcome

```
Deleted: Indeterminate outcome 2. Execution Contract Error model 1 owns it.
```

### Edge cases › String policy

```
Deleted: String 8. String 7 and GRACE-lang Closed vocabulary 29 own it.
```
