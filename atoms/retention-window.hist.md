---
title: Retention Window — history
nav_exclude: true
---

# Retention Window — history

The dated record of how [Retention Window](./retention-window.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/retention-window.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, the refusal order carried by each rule's own condition rather than by the order the rules sit in, the eleven invariant numbers frozen exactly as Audit Trail cites them, Generation acceptance moved ahead of Non-goals as `spec-format.md` requires, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail cites this atom's Invariants 1, 3, 7 and 11 (`tools/grace/cites.py --into retention-window`).

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every retention with its stored fields and, while retained, purge eligible (Operation 29 through 33). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — the retained and purged sets, each retention with its fields, and purge eligibility derived at read time — and the migration dropped it with the section, while Operation 28, Customer Onboarding and Defensible Retention all read the store through it. Restored as the prose had it, not widened. Found beside the same loss in Permissions and Actor Identity, which the cold regeneration of the Attributed Permissions Admin demo surfaced (council read 228).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
