---
title: Condition Register — history
nav_exclude: true
search_exclude: true
---

# Condition Register — history

The dated record of how [Condition Register](./condition-register.md) got here, begun on 2026-11-13 when the spec's tombstones moved out of it because a reader does not need them to use the spec today; everything smaller is in `git log -- atoms/condition-register.md`.

## Decisions


- **2026-11-02 — Drafted as the register three compositions name.** *Chose:* two shapes declared per condition — a sighting, once per condition and subject, and a standing record, one open span per condition and scope, opened, advanced and closed by runs, a recurrence opening a new record; closing keeps last seen at the last run that saw the condition; Report Clear on nothing open answers none-open, not an error; four actions; nothing deleted. *Over:* a standing condition keyed by its name alone. *Because:* Scott's interview of 2026-11-02; Recoverable Invocation keeps one store-unavailable record per kind and Audit Trail one outage per dependency, so a standing condition is keyed by condition and scope, and Recoverable Invocation's span already closes at its last sighting.

- **2026-11-26 — The atom converted to the bond shape, batch 5 of the converter: the record id is the standing id, offered with a new read by it, and no other pattern is named.** *Chose:* the tree order, every label kept and none renumbered. The host-minted "record id" is "standing id" by Bonds Key 17 in every rule, term, entry and projection. Key 10 asks the atom to offer it and Key 26 to name an existence read, and no action took a standing id, so [Read Standing] answers one standing record by its standing id or not-known (Operation 46 through 48), [List Conditions] carries the standing id on every standing record it answers (Operation 49, as Session's Operation 63), and Operation 45's blank-condition refusal names the four actions that take a condition. `Term offer key: key standing id; carried by standing records; calls Read Standing`, the standing id declared (Key 18). A sighting owes no minted id: it is identified by condition and subject and extends the subject's record (Key 11), as Owed Record's records do. No need: the atom carries no actor. The four `MUST compose <pattern>` Non-goals (4, 6, 8, 10) tombstoned to the Non-goal that states what the atom does not do; the WHY, the example and both NOTEs say each job. Opus decided the read (one call). Labelled rules 116 before, 116 after; 676 lines before, 763 after. *Over:* widening [List Conditions] as the existence read, whose required condition and window cannot answer for one value alone; offering nothing, which Key 10 forbids for a minted id. *Because:* unit `atom: Condition Register, converted` (batch 5, 1 of 5).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Condition Register](./condition-register.md) may carry it again.

### Structure › Operations

```
Deleted: Operation 30. Term matching record owns it.
Deleted: Operation 32. Term matching record owns it.
```

### Structure › Invariants

```
Deleted: Invariant 2.2. Invariant 2.1 and Operation 4 own it.
Deleted: Invariant 3.2. Invariant 3.1 and Operation 15 own it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.1. Execution Contract Database 6 owns it.
```

### While something is so › String policy

```
Deleted: String 5. GRACE-lang Term blank owns it: a value carrying only white space is blank.
```
