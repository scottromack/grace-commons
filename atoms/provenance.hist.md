---
title: Provenance — history
nav_exclude: true
search_exclude: true
---

# Provenance — history

The dated record of how [Provenance](./provenance.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/provenance.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.39; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the six actions as a signature block, Invariant 1 through 8 keeping their numbers and their sub-rule numbering, every success effect conditioned on a declared admitted originate / admitted transfer / admitted transform / admitted disclose / admitted archive so no effect binds a refused call (Hard invariant 16), rejection precedence carried by `Operation 11`, `Operation 16` and `Operation 27` rather than by a WHY note, the seven acceptance areas raised to `Check 1.1 through 7.4`, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 22` family and five edge-case families (`String`, `Clock semantics`, `Concurrency`, `Atomic writes`, `Correction`), the Composition notes prose raised to `Composition note 1 through 8` with the named compositions moved into the WHY. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into provenance` found nothing in the corpus citing this atom by label, so the rewrite carried no frozen-number risk.

- **2026-09-12 — Id uniqueness and the archived read are stated once.** *Chose:* the former Invariant 9 (no id reuse) is carried by `Identity 15` and `Identity 16` in the Identity model, and the former archived-chain-admits-a-read invariant by `Operation 53` on the action surface; the durability invariant took the freed number 9 — a renumbering Hard invariant 26 and Hard invariant 27 forbid, which left Chain of Custody's citation of Provenance's ten invariants pointing past the end; council read 95 returned durability to Invariant 10 and tombstoned Invariant 9. *Over:* keeping both copies for emphasis. *Because:* Authority 3 — two rules must not claim authority for one proposition, and the identity model is where identity rules sit. Both duplicates were found by the checker, not by a reader.

- **2026-09-12 — The transferred entry carries the custodian pair in place of a single custodian reference, not beside it.** *Chose:* `State 4` bounded to a non-transferred entry, `State 5` stating the exclusion, `Invariant 7.1` and `Check 1.1` bounded to match. *Over:* the rewrite's `EVERY entry MUST carry a custodian_ref`, which was mine and wrong. *Because:* the prose State section said the single field "is replaced by" the pair, and the preserved [Custodian Reference] term entry says so too — a rewritten rule contradicted a term entry the migration carried across byte-identical. Found by GLM on a first council read of this atom; the witness was the untouched half of the document, which is the argument for preserving term entries verbatim through a migration.

## Migration notes

- **2026-09-15 — Clock dependence 1 and 2, cut out of Clock semantics and Operation.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. Both rules keep the words they carried as Clock semantics 5 and Operation 57; only the heading changed.
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Provenance](./provenance.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 6. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 17. Execution Contract Database 7 owns it.
```

### Structure › State

```
Deleted: State 19. Execution Contract Database 3 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
```

### Structure › Operations

```
Deleted: Operation 4. Execution Contract Refusal 1 owns it.
Deleted: Operation 16. Execution Contract Refusal 1 owns it.
Deleted: Operation 27. Execution Contract Refusal 1 owns it.
Deleted: Operation 35. Operation 34 owns it.
Deleted: Operation 38. Execution Contract Database 1 owns it.
Deleted: Operation 45. Execution Contract Refusal 1 owns it.
Deleted: Operation 52. Execution Contract Read 1 owns it.
Deleted: Operation 54. Capability requirement 1 owns it.
Deleted: Operation 55. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 56. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 57. Clock dependence 2 owns it.
```

### Structure › Invariants › Invariant 10 — Chain durability over this atom's own surface

```
  Deleted: Invariant 9. Identity 15 and Identity 16 own id uniqueness.
  Deleted: Invariant 10.2. Execution Contract Database 1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 1. Execution Contract Conformance 9 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 5. Execution Contract Database 1 owns it.
Deleted: Atomic writes 6. Execution Contract Database 1 owns it.
Deleted: Atomic writes 7. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 5. Clock dependence 1 owns it.
Deleted: Clock semantics 6. Non-goal 23 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Edge cases › String policy

```
Deleted: String 6. Capability requirement 6 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Capability requirement 7 owns it.
Deleted: Composition note 8. Execution Contract Atom interface 1 owns it.
```
