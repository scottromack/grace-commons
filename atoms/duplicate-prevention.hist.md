---
title: Duplicate Prevention — history
nav_exclude: true
search_exclude: true
---

# Duplicate Prevention — history

The dated record of how [Duplicate Prevention](./duplicate-prevention.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/duplicate-prevention.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-11 — Rewritten in GRACE lang v0.34; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two calls as a signature block, rationale under `WHY:`, terms declared where they are used, the invariant numbers and the Ledger unchanged, Non-goals and Edge cases as two sections. *Over:* the prose spec. *Because:* the migration plan — atoms first, since they declare the vocabulary the compositions cite.

- **2026-09-14 — The atom gained an acceptance surface, written from the atom's own rules.** *Chose:* eleven `Check` rules and six `External check` rules, each naming the rule the check tests. *Over:* declining by delegation, which the amended rule admits and this atom cannot honestly take. *Because:* presence became mandatory for every migrated spec on 2026-09-14 (the section titled Generation acceptance in `pressure-testing.md`), and this atom is the one where the absence cost most: a composing pattern's exactly-once guarantee rests on a repeat record not moving the stamp, which is `Invariant 2.2`, and nothing audited it. Every check clears from the recorded set and the atom's own query surface; none invents an obligation, which is what *the bar reduces to the invariants hold* was always asserting and never made testable (council read 65).

## Migration notes

- **2026-09-14 — Invariant 4.1 routed through under guard, and Invariant 4.2 deleted.** Both rules stated the comparison in raw operators — `EXCEEDS window duration` — where the spec already declares under guard as *elapsed term less than window duration* and Operation 6 and Operation 7 route through it. The two spellings disagree at exactly one instant: at `elapsed term = window duration` an identity is not under guard, so the then-standing window-monotonicity invariant required it out of the recorded set while the old Invariant 4.1 obliged no host to drop it. Routing through the declared term closes the boundary with no new operator, which is the cure the `≥` docket row asks whether the grammar needs — and one site fewer that it does (council read 51).
- **2026-09-14 — Invariant 1, tombstoned rather than restated.** The deleted invariant claimed EVERY identity in the recorded set stands under guard, unconditionally, and a WHY beside it narrowed the claim to an eager host — a rule whose scope lived on a surface Surface 15 tells the parser to ignore and Surface 9 lets a writer delete. The atom sells behaviour rather than storage, which the rules already say in both directions: Operation 6 answers seen for an identity under guard and Operation 7 answers not-seen for one that is not, so nothing remained for the invariant to own. Restating it as the answer claim — *EVERY identity the check answers seen for MUST stand under guard* — was considered and refused: that is Operation 7's contrapositive, one proposition under a second label, which is the defect rather than the cure (Authority 3, council read 52).
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
- **2026-09-15 — Clock semantics 1, kept under Clock semantics.** Clock semantics 1 stays under Clock semantics rather than under Clock dependence: it is this atom's one use of the reading, an instance of that family's question rather than a statement of it (council read 75).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Duplicate Prevention](./duplicate-prevention.md) may carry it again.

### Structure › Operations

```
Deleted: Operation 8. Capability requirement 1 owns it.
Deleted: Operation 9. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 10. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 13. Execution Contract Read 1 owns it.
```

### Structure › Invariants › Invariant 2 — Single-recording

```
  Deleted: Invariant 1. Operation 6 and Operation 7 own it.
```

### Structure › Invariants › Invariant 3 — Idempotency of check

```
  Deleted: Invariant 3.2. Operation 6, Operation 7 and Invariant 3.1 own it.
```

### Structure › Invariants › Invariant 4 — Eventual expiry

```
  Deleted: Invariant 4.1. Operation 7 and Execution Contract Database 4 own it.
  Deleted: Invariant 4.2. Operation 7 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.2. Invariant 2.2 owns it.
Deleted: Check 1.3. Invariant 2.1 owns it.
Deleted: Check 1.4. Invariant 2.3 owns it.
Deleted: Check 2.1. Invariant 3.1 owns it.
Deleted: Check 2.2. Invariant 3.1, Check 3.2 and Check 3.3 own it.
Deleted: Check 3.4. Check 3.3 owns it.
Deleted: Check 4.1. Operation 3 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 4. Execution Contract Database 3 owns it.
Deleted: External check 5. Operation 12 owns it.
Deleted: External check 6. Execution Contract Logic confinement 7 owns it: the page relies on no guarantee of the clock.
```

### Non-goals

```
Deleted: Non-goal 2. Execution Contract Database 3 owns it.
Deleted: Non-goal 3. Execution Contract Database 3 owns it.
Deleted: Non-goal 6. Operation 7 and Execution Contract Database 4 own it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Non-goal 12 owns it.
Deleted: Clock semantics 3. Non-goal 13 owns it.
```

### Edge cases › Check database unavailability

```
Deleted: Check unavailability 1. Operation 12 and Operation 13 own it.
Deleted: Check unavailability 2. Operation 12 and Operation 13 own it.
Deleted: Check unavailability 3. Operation 12 and Operation 13 own it.
Deleted: Check unavailability 4. Non-goal 1 owns it.
```

### Edge cases › Lazy expiry

```
Deleted: Lazy expiry 1. Execution Contract Database 4 owns it.
Deleted: Lazy expiry 2. Execution Contract Database 4 owns it.
Deleted: Lazy expiry 3. Operation 7 owns it.
```

### Edge cases › Record storage failure

```
Deleted: Record failure 1. Operation 14 owns it.
Deleted: Record failure 4. Execution Contract Database 3 owns it.
```
