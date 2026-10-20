---
title: Event Log — history
nav_exclude: true
---

# Event Log — history

The dated record of how [Event Log](./event-log.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/event-log.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-11 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, rationale under `WHY:`, terms declared where they are used, the invariant numbers frozen exactly as the compositions cite them, Non-goals and Edge cases as two sections, the case table kept beside the rules. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail and Recoverable Invocation cite this atom's Invariants 1, 2, 3, 5 and 7, and a rewrite that moved a number would break those citations silently (`tools/grace/cites.py --into event-log`).

- **2026-09-14 — The atom gained an acceptance surface, and the external half is the load-bearing half.** *Chose:* fifteen `Check` rules cleared from one log instance and its read surface, and six `External check` rules naming what the log cannot show about itself. *Over:* declining by delegation, which would have been false — this atom is composed directly, not only through a substrate. *Because:* presence became mandatory on 2026-09-14, and this atom is the corpus's Start Here: it claims append-only, total order and read consistency while the evidence sat in a formal model, a twin suite and five independent renders, none of which a first reader has met. The section is the bridge. `External check 4` is the line that had to be written down — **append-only is not tamper-evidence**, every conformance check above passes over a log an adversary rewrote, and the atom compares the log only against itself (council read 65).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
