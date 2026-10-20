---
title: Subscription — history
nav_exclude: true
---

# Subscription — history

The dated record of how [Subscription](./subscription.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/subscription.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the nine invariant numbers unchanged, Generation acceptance as conformance checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan; this atom carries no cross-spec citations, so the rewrite is free of frozen-number risk.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
