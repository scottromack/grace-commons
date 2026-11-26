---
title: Comment — history
nav_exclude: true
search_exclude: true
---

# Comment — history

The dated record of how [Comment](./comment.md) got here, kept out of the spec because a reader does not need it to use the spec today. Everything smaller is in `git log -- library/atoms/comment.md`.

## Decisions

- **2026-11-26 — The atom converted to the bond shape, batch 6 of the converter: it offers the comment id, read by a new [Read Comment], and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; `Term offer key: key comment id; carried by comments; calls Read Comment` (Bonds Key 9, 10, 26), the comment id declared (Key 18). No action read one comment by its id ([List] takes a target reference), so [Read Comment] answers one (Operation 29, 30) and joins the comment actions, so Operation 4 refuses an id naming no comment; this follows the existence read Opus chose for Condition Register (ae6d2e48). No need: the author and target references are opaque. The owners NOTE and the breakdown say each job, not a pattern. Labelled rules 75 before, 77 after; 550 lines before, 633 after. This history file is new with this unit. *Over:* offering the comment id with no existence read (Key 26). *Because:* unit `atom: Comment, converted` (batch 6, 3 of 5).
