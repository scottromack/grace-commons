---
title: Capability — history
nav_exclude: true
---

# Capability — history

The dated record of how [Capability](./capability.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/capability.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the thirteen invariant numbers and the six acceptance checks unchanged, the derived lapse routed through a declared lapsed and revocable so no rule carries the comparison, the arithmetic in `allocated_at + ttl` moved into a declared expiry deadline (Hard invariant 24), the two things the store cannot clear promoted from prose caveats to `External check 1 through 2`, the two Alloy-confirmed entailments kept as prose beneath the invariants rather than given numbers they never had, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk. The rewrite surfaced one cross-atom fork it does not resolve: a lapsed capability answers [Already Terminal] to [Revoke] while a lapsed [Session](./session.md) accepts one, same mechanic and opposite rulings, neither declaring the other — docketed rather than reconciled, because reconciling it is logic.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
- **2026-09-15 — Clock dependence 1 and 2, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. Both rules keep the words they carried as Clock semantics 4 and 5; only the heading changed.
