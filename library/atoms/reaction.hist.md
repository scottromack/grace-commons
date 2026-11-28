---
title: Reaction — history
nav_exclude: true
search_exclude: true
---

# Reaction — history

The dated record of how [Reaction](./reaction.idd) got here, moved out of the spec on 2026-11-16 because a reader does not need it to use the spec today. Everything smaller is in `git log -- atoms/reaction.md`.

## Decisions

- **2026-11-14 — Drafted through the Grace connector mirroring Favorite, from the maintainer's row on the requested-patterns page and his yes to a plain sketch.** *Chose:* a reaction as one person's answer to one item in one reaction name, the shape the maintainer wrote on the wish list (2026-11-11: one click gives the default, a person holds one reaction per item, choosing another replaces it, clicking it again takes it back); the reaction set and the holding rule as the deployment's two settings, one-per-item where none is declared, one-of-each for the shape of Slack, Discord and GitHub; reacting and withdrawing as two requests, each safe to repeat (Operation 9, Operation 14, Operation 15), as Favorite chose for its mark; a withdrawn reaction kept and counted in no tally (State 3, Operation 20); every reaction named by its word (the maintainer: "Every control is named by its words: a thumb is 'Like', a heart is 'Favorite'"; Non-goal 9). *Over:* one toggle request (a repeated tap would undo the first); a reaction removed on withdraw (Favorite keeps its record, and the database keeps the history either way); two patterns, one for each holding rule (the record and the requests are the same); a vote folded in (the maintainer, 2026-11-11: "VOTING is something but conceptually very similar. We do need to think about it more"; Non-goal 6). *Because:* the EOS test keeps one freestanding concept, a person's answer to an item in a word, and names an owner for the caller, the catalog, telling the author, scores, votes, favorites and the list of who reacted (Non-goal 1 through 10); as simple as possible without losing fidelity keeps one record, two statuses and two settings.
