---
title: Personal Todo — history
nav_exclude: true
---

# Personal Todo — history

The dated record of how [Personal Todo](./personal-todo.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/personal-todo.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the description policy as its own rule family, the eight invariant numbers unchanged, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan, and this atom is the corpus's simplest shape — the one a reader meets first.

- **2026-09-14 — The atom gained an acceptance surface, kept deliberately plain.** *Chose:* fourteen `Check` rules and three `External check` rules, each one reading of the list against one rule. *Over:* a richer section. *Because:* presence became mandatory on 2026-09-14, and this atom is the reference implementation's first worked example, so its section teaches the shape more than it audits a risk. Two things it does carry are not decoration: the three timestamp checks keep the invariants' conditional form rather than chaining them, since an auditor comparing `added_at ≤ last_edited_at ≤ completed_at` over every unit files against a correct list; and `Check 3.4`'s passing condition is that **nothing happened** — a no-op edit answers ok and writes nothing, so the evidence of conformance is a stamp that did not move (council read 65).

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every unit with its stored fields (Operation 28 through 31). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — "the current set of pending units" and done units, each with its fields — and the migration dropped it with the section. Restored as the prose had it, not widened. Found beside the same loss in Permissions and Actor Identity, which the cold regeneration of the Attributed Permissions Admin demo surfaced (council read 230).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
