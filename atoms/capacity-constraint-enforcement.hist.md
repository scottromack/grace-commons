---
title: Capacity Constraint Enforcement — history
nav_exclude: true
---

# Capacity Constraint Enforcement — history

The dated record of how [Capacity Constraint Enforcement](./capacity-constraint-enforcement.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/capacity-constraint-enforcement.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.36; nothing but language changed.** *Chose:* the eight actions as a signature block, the fourteen invariant numbers unchanged, the six acceptance areas opened into `Check 1.1 through 6.1` with three External checks for what the store cannot answer, the arithmetic routed through declared requested total and released total so no rule carries a sum, the three host obligations Invariant 4 rests on given their own families (`Concurrency`, `Crash atomicity`, `Arithmetic`). *Over:* the prose spec. *Because:* the migration plan; nothing cites this atom by label. The open question this atom was picked to answer — whether a domain whose logic *is* arithmetic survives Hard invariant 24 — answers yes: `MUST NOT EXCEED` and `EXCEEDS` carry every comparison directly, and only the two sums needed names.

## Migration notes

- **2026-09-15 — Clock dependence 1 and 2, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. Both rules keep the words they carried as Clock semantics 4 and 5; only the heading changed.
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
