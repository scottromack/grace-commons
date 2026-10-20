---
title: Provisional Commitment — history
nav_exclude: true
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
