---
title: Category — history
nav_exclude: true
search_exclude: true
---

# Category — history

The dated record of how [Category](./category.md) got here, kept out of the spec because a reader does not need it to use the spec today. Everything smaller is in `git log -- library/atoms/category.md`.

## Decisions

- **2026-11-26 — The atom converted to the bond shape, batch 5 of the converter: it offers the category id, read by a new [Read Category], and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; `Term offer key: key category id; carried by categories; calls Read Category` (Bonds Key 9, 10, 26), the category id declared (Key 18). No action read one category by its id ([List Items] refuses nothing and [Tree] answers the whole tree), so [Read Category] answers one category (Operation 36, 37) and joins the category actions, so Operation 3 refuses an id naming no category; this follows the existence read Opus chose for Condition Register (ae6d2e48). A home is a link record, its identity the item reference and the category id it joins, so it mints no id (Key 11, 12). No need: the caller is the composing pattern's (Non-goal 1). The owners NOTE, the WHY, the breakdown and a source say each job, not a pattern. Labelled rules 77 before, 79 after; 621 lines before, 778 after. This history file is new with this unit. *Over:* the drafted home id offer (a link record mints none) and the drafted Look Up as the category id's read (it takes an item reference). *Because:* unit `atom: Category, converted` (batch 5, 3 of 5).
