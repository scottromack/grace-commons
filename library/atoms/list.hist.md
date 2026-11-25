---
title: List — history
nav_exclude: true
search_exclude: true
---

# List — history

The dated record of how [List](./list.md) got here. Everything smaller is in `git log -- atoms/list.md`.

## Decisions

- **2026-11-25 — Written as the one atom that makes a list, mints its id and holds its author.** *Chose:* an atom of its own, five rules, rename and delete taking no caller, the list id allocated by the host at the seam and never reused (as Personal Todo's id is), one key need on `actor id` for the author and one key offer on `list id`. *Over:* leaving the list to the app, or to Permissions or Personal Todo, because the to-do design's first round found that no atom made a list, minted its list id or held its author (rounds/2026-11-24-1956-todo-design/findings.md, finding (c)4). *Because:* Scott's ruling of 2026-11-24 10:50 PM Central ("yes") on that finding, with "the author" meaning the list's author everywhere, renaming included (his 3:23 PM ruling, "the author owns the list"); the caller is carried and never checked, since the app's permission gates rename and delete before the call.
