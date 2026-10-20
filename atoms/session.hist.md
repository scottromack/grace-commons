---
title: Session — history
nav_exclude: true
---

# Session — history

The dated record of how [Session](./session.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/session.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the twelve invariant numbers and the six acceptance checks unchanged, the derived lapse routed through a declared lapsed and effective status so no rule carries the comparison, the arithmetic in `issued_at + session_duration` moved into a declared expiry deadline (Hard invariant 24), [Validate]'s four-row precedence table kept beside the rules as the case space, Generation acceptance moved ahead of Non-goals to match the migrated corpus, the string-input paragraph raised to a `String 1 through 8` family matching Permissions and Notification, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk. Expiry earned its own family — eight rules that say a lapse writes nothing, fires nothing, stamps nothing and is scheduled by nobody — because the whole commitment was carried by prose emphasis in four places and is now a surface a checker can read.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
- **2026-09-15 — Clock dependence 1 and 2, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. Both rules keep the words they carried as Clock semantics 4 and 5; only the heading changed.
