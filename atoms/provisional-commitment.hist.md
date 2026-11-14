---
title: Provisional Commitment — history
nav_exclude: true
search_exclude: true
---

# Provisional Commitment — history

The dated record of how [Provisional Commitment](./provisional-commitment.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/provisional-commitment.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-13 — The window boundary is declared once, as a term, instead of being restated at four guard sites.** *Chose:* open and lapsed as a two-member window reading, with the boundary instant declared onto the lapsed side. *Over:* repeating `now < expires_at` and `now ≥ expires_at` in each guard, which is how the prose carried it. *Because:* the boundary is one proposition and a spec pays for a proposition once (GRACE-lang Authority 3); four copies are four chances for an edit to move three of them. It also routes the comparison out of the rules, which carry no arithmetic (GRACE-lang Hard invariant 24).

- **2026-09-13 — Invariant 4 and Invariant 9 are tombstoned; Identity owns id stability and id reuse.** *Chose:* Identity 4 and Identity 5 as the single owners. *Over:* keeping the invariants, which restated them. *Because:* Authority 3 — and Identity 5 is the stronger claim, since two commitments never share an id whether or not either has resolved.

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every commitment with its stored fields (Operation 38 through 41). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — "the current set of [Held] commitments" and the terminal ones, each with its fields — and the migration dropped it with the section. Restored as the prose had it, not widened. Found beside the same loss in Permissions and Actor Identity, which the cold regeneration of the Attributed Permissions Admin demo surfaced (council read 230).

## Migration notes

- **2026-09-13 — Invariant 8, titled for the two instants it floors.** The family floors the two *resolution* instants and not lapse instant, whose floor is the stronger one Invariant 7.2 already carries — an expiry may not precede expiry instant, which by Invariant 6.1 exceeds placement instant. The family was titled *Transition instants* in a draft of the migration, which promised a floor on all three and delivered two (council read 38).
- **2026-09-13 — String 1 through 6, added in the migration.** The family was missing from a draft of the migration, and its absence was invisible rather than benign: Operation 1 and Operation 2 test caller-supplied strings against blank, so without String 5 and String 6 a whitespace-only resource had no declared reading at all and two implementations could disagree about whether it is a hold (council read 38). The reading of blank is shared, which is why the grammar owns it since GRACE-lang v0.52 rather than eleven specs repeating it word for word.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Provisional Commitment](./provisional-commitment.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 13. Execution Contract Database 7 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 5. Capability requirement 18 and Capability requirement 19 own it.
Deleted: Capability requirement 6. Execution Contract Database 3 owns it.
Deleted: Capability requirement 9. Execution Contract Logic confinement 13 owns it.
Deleted: Capability requirement 13. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 14. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 6. Non-goal 26 owns it.
```

### Structure › Operations

```
Deleted: Operation 6. Execution Contract Refusal 1 owns it.
Deleted: Operation 16. Execution Contract Refusal 1 owns it.
Deleted: Operation 20. Execution Contract Refusal 1 owns it.
Deleted: Operation 27. Execution Contract Database 1 owns it.
Deleted: Operation 28. Execution Contract Read 4 owns it.
Deleted: Operation 29. Execution Contract Refusal 1 owns it.
Deleted: Operation 32. Operation 30 owns it.
Deleted: Operation 36. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 37. Execution Contract Logic confinement 3 owns it.
```

### Structure › Invariants › Invariant 3 — Terminal absorption

```
  Deleted: Invariant 4. Identity 4 owns id stability.
```

### Structure › Invariants › Invariant 5 — Property immutability

```
  Deleted: Invariant 5.2. Operation 8 owns it.
```

### Structure › Invariants › Invariant 8 — Resolution instants follow placement

```
  Deleted: Invariant 9. Identity 5 owns id reuse for every id, resolved or not.
```

### Structure › Invariants › Invariant 10 — Commitment record durability

```
  Deleted: Invariant 10.2. Invariant 10.1 and Execution Contract Database 4 own it.
  Deleted: Invariant 10.3. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 6.1. Execution Contract Database 6 owns it.
Deleted: Check 6.2. Execution Contract Database 6 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 6. Execution Contract Conformance 9 owns it.
Deleted: External check 7. Execution Contract Database 6 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```
