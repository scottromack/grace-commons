---
title: Condition Register — history
nav_exclude: true
search_exclude: true
---

# Condition Register — history

The dated record of how [Condition Register](./condition-register.md) got here, begun on 2026-11-13 when the spec's tombstones moved out of it because a reader does not need them to use the spec today; everything smaller is in `git log -- atoms/condition-register.md`.

## Decisions


- **2026-11-02 — Drafted as the register three compositions name.** *Chose:* two shapes declared per condition — a sighting, once per condition and subject, and a standing record, one open span per condition and scope, opened, advanced and closed by runs, a recurrence opening a new record; closing keeps last seen at the last run that saw the condition; Report Clear on nothing open answers none-open, not an error; four actions; nothing deleted. *Over:* a standing condition keyed by its name alone. *Because:* Scott's interview of 2026-11-02; Recoverable Invocation keeps one store-unavailable record per kind and Audit Trail one outage per dependency, so a standing condition is keyed by condition and scope, and Recoverable Invocation's span already closes at its last sighting.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Condition Register](./condition-register.md) may carry it again.

### Structure › Operations

```
Deleted: Operation 30. Term matching record owns it.
Deleted: Operation 32. Term matching record owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.1. Execution Contract Database 6 owns it.
```
