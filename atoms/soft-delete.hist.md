---
title: Soft Delete — history
nav_exclude: true
---

# Soft Delete — history

The dated record of how [Soft Delete](./soft-delete.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/soft-delete.md`.

## Decisions

Entries that record a migration or a repair rather than a turn the pattern took.

- **2026-09-13 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the four actions as a signature block, Invariant 1 through 8 keeping their numbers, every success effect conditioned on a declared admitted soft delete, admitted restore, admitted purge or admitted read (Hard invariant 16), the three transitioning actions unified under declared transitioning action, acting reference and transition instant terms so their shared guards are stated once rather than three times, the four per-action *rejection priority* lines collapsed to one six-row case space, `Generation acceptance` moved ahead of `Non-goals` to match the migrated corpus, the six acceptance areas opened into `Check 1.1 through 5.4` with four `External check`s, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 19` family and four edge-case families. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into soft-delete` found nothing citing this atom by label. 58.5 KB → 53.8 KB, the smallest reduction of the migration — this atom's prose was already dense, and most of what came out was the four repeated precedence lines.

- **2026-09-13 — Three propositions had two owners each.** *Chose:* `Invariant 1` owns the deletion-epoch semantics and three `Operation` rules that restated it are gone; `Invariant 2` owns membership exclusivity and the `State` family no longer restates it. *Over:* keeping each pair. *Because:* Authority 3, found by `W-duplicate-proposition`. The citation-aim audit then caught the consequence a checker cannot: an Examples citation pointed at deleted `Operation 29`, and after the renumber it resolved cleanly to a different rule about commit atomicity. Third atom running where the audit catches a silently repointed citation, and the second where a *deleted* rule's citation found a new home rather than dangling.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
