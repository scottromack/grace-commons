---
title: Owed Record — history
nav_exclude: true
search_exclude: true
---

# Owed Record — history

The dated record of how [Owed Record](./owed-record.md) got here, begun on 2026-11-13 when the spec's tombstones moved out of it because a reader does not need them to use the spec today; everything smaller is in `git log -- atoms/owed-record.md`.

## Decisions


- **2026-11-01 — Drafted as the owed record, under that name.** *Chose:* one record per obligation — owing pattern, owed id, cause id, recording and due-by instants — recorded in the cause's transaction, discharged once naming its fulfilment, or flagged once past due for a person, who may still discharge it; four actions; no message body and no delivery. The name is *Owed Record*, not the *Outbox* six compositions used for it. *Over:* the textbook outbox, a message queue with delivery status. *Because:* Scott ruled 2026-11-01 that the atom is the single home of an owed item, matching every citation and the shape Recoverable Invocation's intent records carry; Notification Fanout already uses *Outbox* in the textbook sense, so the name follows his rule that all things mean one thing, and the corpus already says *owed record* for this.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Owed Record](./owed-record.md) may carry it again.

### Structure › Operations

```
Deleted: Operation 33. Term matching owed record owns it.
```
