---
title: Message Preference — history
nav_exclude: true
---

# Message Preference — history

The dated record of how [Message Preference](./message-preference.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/message-preference.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the five actions as a signature block, the ten invariant numbers unchanged and Timestamp ordering kept outside them as its own label family, the six acceptance checks renumbered only into `Check N.k`, the case space kept beside the rules as a table, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk.

## Migration notes

- **2026-09-15 — Clock dependence 1 and 2, moved from Operation.** Whether a guard's decision may depend on the clock reading, and under what condition. Both rules stood under `Operation` until council read 75 swept the corpus by rule text rather than by family name; neither word changed.
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
