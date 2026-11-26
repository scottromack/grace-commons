---
title: Owed Record — history
nav_exclude: true
search_exclude: true
---

# Owed Record — history

The dated record of how [Owed Record](./owed-record.md) got here, begun on 2026-11-13 when the spec's tombstones moved out of it because a reader does not need them to use the spec today; everything smaller is in `git log -- atoms/owed-record.md`.

## Decisions


- **2026-11-01 — Drafted as the owed record, under that name.** *Chose:* one record per obligation — owing pattern, owed id, cause id, recording and due-by instants — recorded in the cause's transaction, discharged once naming its fulfilment, or flagged once past due for a person, who may still discharge it; four actions; no message body and no delivery. The name is *Owed Record*, not the *Outbox* six compositions used for it. *Over:* the textbook outbox, a message queue with delivery status. *Because:* Scott ruled 2026-11-01 that the atom is the single home of an owed item, matching every citation and the shape Recoverable Invocation's intent records carry; Notification Fanout already uses *Outbox* in the textbook sense, so the name follows his rule that all things mean one thing, and the corpus already says *owed record* for this.

- **2026-11-20 — A read of one owed record by its pair, a listing that holds discharged, and a cap on the due-by window.** *Chose:* [Read Owed], one owed record by its owing pattern and owed id whatever its status (Operation 44 through 47), and [List Owed] taking discharged as a listed status (Operation 35), so a discharged record is reached through the atom and not only by an auditor's read of the database; a window cap with a default of 31,536,000 seconds that a deployment may override (Term window cap, Capability requirement 7, Operation 48), so a window past what the due-by deadline can hold is refused with invalid-request, Execution Contract Input 2's form; the owners of Non-goal 1, 2 and 5 named as a composing pattern, the owing pattern and the deployment, as the corpus's other pages name an owner that is no page. *Over:* leaving a discharged record to the auditor's read of the database alone; a read by id answering only an open or flagged record; an uncapped window that a caller or an operator controls; a window cap with no default. *Because:* open lines 2026-11-02-a, 2026-11-02-b and 2026-11-03-a, decided by Scott's directions of 2026-11-19 (rounds/open-line-choices-directions-2.md, 3:35 and 3:41 PM Central: "the atom offers a read by id and lists discharged as a status a read can filter on"; group 8 of the ruling of 2026-11-19T21:32Z: a field an attacker or operator controls gets an explicit cap and a refusal; group 4: pure operating policy is a deployment capability).

- **2026-11-26 — The atom converted to the bond shape, batch 4 of the converter: it mints no id, offers nothing, needs nothing, and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered. An owed record is identified by the owing pattern and the owed id the owing pattern gives it (Identity 1): it extends the owing pattern's record, so Bonds Key 11 asks no minted id of it and Key 14 forbids offering an id it carries and does not mint. No need: the actor reference names "the actor or system identity" and the atom interprets none (Identity 5), so binding it to an actor id would change what it means. The four `MUST compose <pattern>` Non-goals (4, 7, 9, 11) tombstoned to the Non-goal that states what the atom does not do; the WHY's three examples, a sentence of What it is, an invariant's gloss, the worked example, a scenario, a source and both NOTEs say each job, not a pattern. Labelled rules 107 before, 103 after; 696 lines before, 743 after. *Over:* the drafted owed id offer and actor id need. *Because:* unit `atom: Owed Record, converted` (batch 4, 3 of 5).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Owed Record](./owed-record.md) may carry it again.

### Structure › Operations

```
Deleted: Operation 33. Term matching owed record owns it.
```
