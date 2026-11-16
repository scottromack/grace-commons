---
title: Favorite — history
nav_exclude: true
search_exclude: true
---

# Favorite — history

The dated record of how [Favorite](./favorite.md) got here, moved out of the spec on 2026-11-16 because a reader does not need it to use the spec today. Everything smaller is in `git log -- atoms/favorite.md`.

## Decisions

- **2026-11-14 — Drafted through the Grace connector mirroring Punch Card, from an interview with the maintainer.** *Chose:* a favorite as one person's mark on one item, a simple toggle on the screen (the submitter, 2026-11-14: "It is a simple toggle usually a heart filled and unfilled"); marking and unmarking as two requests, each safe to repeat (Operation 7, Operation 10, Operation 11); an unmarked favorite kept with its first marked instant, so marking again restores it where it stood (the submitter: "it never 'moves' in my mind"; State 3, Invariant 2.1); a favorite kept whatever becomes of the item, its availability shown from the catalog (the submitter: "product availability status ... should be shown"; Non-goal 4); no limit on a person's favorites (the submitter: "I can't think of a business that would want to limit your hearts"). *Over:* one toggle request (a repeated tap would undo the first); a favorite removed on unmark and recorded anew on mark (the item would jump to the newest place on every slip); the statuses of an item held by the favorite (a recipe has no stock). *Because:* the EOS test keeps one freestanding concept, a person's mark on an item, and names an owner for the catalog, the caller, sharing, counting and save for later (Non-goal 1 through 8); as simple as possible without losing fidelity keeps one record and two statuses.
