---
title: Permissions — history
nav_exclude: true
---

# Permissions — history

The dated record of how [Permissions](./permissions.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/permissions.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the three actions as a signature block, the string policy as its own rule family, the ten invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan, and this atom completes [Shared Todo](../compositions/shared-todo.md)'s constituent set — Personal Todo, Assignment and Permissions all migrated, which makes that composition the one with no inherited term collision to resolve.

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every grant with its stored fields (Operation 26 through 29). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — "the current set of grants", each with its fields — and the migration dropped it with the section, while Deprovisioning 2, Check 1.1, Attributed Permissions Admin and Actor Suspension all read the store through it. Restored as the prose had it, not widened: no filter, so a composing pattern filters in its own code. Found by the cold regeneration of the Attributed Permissions Admin demo (council read 228).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
