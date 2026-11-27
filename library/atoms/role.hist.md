---
title: Role — history
nav_exclude: true
search_exclude: true
---

# Role — history

The dated record of how [Role](./role.idd) got here, kept out of the spec because a reader does not need it to use the spec today. Everything smaller is in `git log --follow -- library/atoms/role.idd`.

## Decisions

- **2026-11-26 — The atom converted to the bond shape, batch 6 of the converter: it offers the holding id, read by a new [Read Holding], and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; `Term offer key: key holding id; carried by holdings; calls Read Holding` (Bonds Key 9, 10, 26), the holding id declared (Key 18). No action read one holding by its id ([Look Up] takes a person reference), so [Read Holding] answers one or not-known (Operation 30 through 32), as Opus chose for Condition Register (ae6d2e48). No need: the person, granter and revoker references are opaque. The owners NOTE, a concurrency note and the breakdown say each job, not a pattern. Not made here: whether [Ask] is a permission offer (Bonds permission), which would change what the atom offers and is left for a unit of its own. Labelled rules 70 before, 73 after; 543 lines before, 637 after. This history file is new with this unit. *Over:* the drafted actor id need and Look Up as the holding id's read (it takes a person reference). *Because:* unit `atom: Role, converted` (batch 6, 4 of 5).

## Deleted rules

The spec's tombstones, kept here because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Role](./role.idd) may carry it again.

### What people do › Read Holding

```
Deleted: Operation 32. Operation 20 owns it: [Read Holding] is a reading action (Term reading action).
```
