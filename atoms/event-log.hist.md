---
title: Event Log — history
nav_exclude: true
search_exclude: true
---

# Event Log — history

The dated record of how [Event Log](./event-log.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/event-log.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-11 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, rationale under `WHY:`, terms declared where they are used, the invariant numbers frozen exactly as the compositions cite them, Non-goals and Edge cases as two sections, the case table kept beside the rules. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail and Recoverable Invocation cite this atom's Invariants 1, 2, 3, 5 and 7, and a rewrite that moved a number would break those citations silently (`tools/grace/cites.py --into event-log`).

- **2026-09-14 — The atom gained an acceptance surface, and the external half is the load-bearing half.** *Chose:* fifteen `Check` rules cleared from one log instance and its read surface, and six `External check` rules naming what the log cannot show about itself. *Over:* declining by delegation, which would have been false — this atom is composed directly, not only through a substrate. *Because:* presence became mandatory on 2026-09-14, and this atom is the corpus's Start Here: it claims append-only, total order and read consistency while the evidence sat in a formal model, a twin suite and five independent renders, none of which a first reader has met. The section is the bridge. `External check 4` is the line that had to be written down — **append-only is not tamper-evidence**, every conformance check above passes over a log an adversary rewrote, and the atom compares the log only against itself (council read 65).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Event Log](./event-log.md) may carry it again.

### Structure › State

```
Deleted: State 7. Execution Contract Database 3 owns it.
```

### Structure › Operations

```
Deleted: Operation 7. Execution Contract Database 2 owns it.
Deleted: Operation 8. Execution Contract Database 2 owns it.
Deleted: Operation 12. Execution Contract Database 2 owns it.
Deleted: Operation 13. Invariant 5.1 owns it.
Deleted: Operation 14. Invariant 5.2 owns it.
Deleted: Operation 18. Term query and Execution Contract Query 1 through 4 own it: what a query holds and when it is malformed is one thing in every build.
Deleted: Operation 19. Capability requirement 1 owns it.
Deleted: Operation 20. Execution Contract Logic confinement 3 owns it.
```

### Structure › Invariants › Invariant 5 — Read consistency

```
  Deleted: Invariant 5.3. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
```

### Structure › Invariants › Invariant 7 — Wall-time best-effort monotonicity

```
  Deleted: Invariant 7.1. Invariant 7.2 owns it: two appends the database serializes can land in the order opposite to their clock readings, so recording instant can fall along append order under a non-decreasing clock.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.4. Execution Contract Database 1 owns it: a refused append writes nothing, so the sequence numbers carry no gap.
Deleted: Check 3.5. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
Deleted: Check 5.1. Check 5.2 owns it: a falling recording instant is no clock finding either, since two appends the database serializes can land in the order opposite to their clock readings.
```

### Generation acceptance › External checks

```
Deleted: External check 1. Execution Contract Database 3 owns it.
Deleted: External check 2. Execution Contract Database 2 owns it.
Deleted: External check 3. Execution Contract Logic confinement 7 owns it: the page relies on no guarantee of the clock.
```

### Non-goals

```
Deleted: Non-goal 16. Execution Contract Database 1 owns it.
```

### Edge cases › Indeterminate outcome

```
Deleted: Indeterminate outcome 1. Execution Contract Error model 1 owns it.
```

### Edge cases › Durability across crashes

```
Deleted: Durability 1. Execution Contract Database 3 owns it.
Deleted: Durability 2. Execution Contract Database 3 owns it.
Deleted: Durability 3. Execution Contract Database 3 owns it.
Deleted: Durability 4. Execution Contract Database 3 owns it.
```

### Edge cases › Sequence-number gaps on storage failure

```
Deleted: Sequence gap 1. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
Deleted: Sequence gap 2. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
Deleted: Sequence gap 3. Execution Contract Database 1 owns it: a refused append writes nothing, so the sequence numbers carry no gap.
Deleted: Sequence gap 4. Execution Contract Database 1 owns it: a refused append writes nothing, so no sequence number is consumed.
```
