---
title: Duplicate Prevention — history
nav_exclude: true
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
