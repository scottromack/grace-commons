---
title: Moderation — history
nav_exclude: true
search_exclude: true
---

# Moderation — history

The dated record of how [Moderation](./moderation.md) got here, kept out of the spec because a reader does not need it to use the spec today. Everything smaller is in `git log -- library/atoms/moderation.md`.

## Decisions

- **2026-11-26 — The atom converted to the bond shape, batch 6 of the converter: it mints no id, offers nothing, needs nothing, and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered. A standing is identified by the item reference alone (Identity 1), one for each item, so it extends the item's record and mints no id (Bonds Key 11); a report is identified by its item reference, reporter reference and flagged instant (Identity 2) and no action acts on one report alone ([Dismiss] clears an item's reports together), so Key 9 asks no minted id of it. No need: the item and person references are opaque. The WHY, an example, the breakdown and both NOTEs say each job, not a pattern. Labelled rules 75 before, 75 after; 578 lines before, 630 after. This history file is new with this unit. *Over:* the drafted standing id offer, the converter's fallback for a record whose description names no id. *Because:* unit `atom: Moderation, converted` (batch 6, 1 of 5).
