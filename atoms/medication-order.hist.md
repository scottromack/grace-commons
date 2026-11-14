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
