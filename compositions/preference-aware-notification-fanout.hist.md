---
title: Preference-Aware Notification Fanout — history
nav_exclude: true
search_exclude: true
---

# Preference-Aware Notification Fanout — history

The dated record of how [Preference-Aware Notification Fanout](./preference-aware-notification-fanout.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/preference-aware-notification-fanout.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-23 — Rewritten in GRACE lang v0.61; two of four open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole — `Primitive policy`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with the precedence table as its own `Shaping gate` family and the replay procedure as `Verdict replay`; invariant numbers 1 through 5 and 7 through 10 unchanged, Invariant 6 tombstoned to Composes 5 and its store-write limits kept as Composes 7 through 10; the checks renumbered `Check 1.1` through `Check 6.1`; `Non-goals` and `Edge cases` split, with `Clock semantics`, `Concurrency`, `Payload retention`, `Per-channel caps` and `Staleness` under the second; the host's per-disposition section named an *exclusion*, since the grammar owns *section*. The lines' fixes: the overshoot record's undefined *action* field dropped, a detector taking no action to name (2026-08-30-a); a hold retry horizon declared, past which a hold suppression is not retryable, and payload retention bounded by the later of it and the reconciliation window (2026-08-30-c). *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. Two stay open: the orphan lookup's constituent home, which waits on the Reverse Index pattern (2026-08-30-b), and the model (2026-08-30-d).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Preference-Aware Notification Fanout](./preference-aware-notification-fanout.md) may carry it again.

### Composition logic › Capability requirement

```
Deleted: Capability requirement 24. Term reconciliation run bound owns it: the run bound counts every write's landing.
Deleted: Capability requirement 40. Execution Contract Database 1 owns it: a disposition's create and its delivery event commit together, and the composition names no orphan for a lookup to find.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 9. Execution Contract Database 2 owns it.
Deleted: Action wiring 41. Execution Contract Database 2 owns it.
Deleted: Action wiring 49. Execution Contract Database 1 owns it.
Deleted: Action wiring 50. Execution Contract Database 1 owns it.
Deleted: Action wiring 51. Execution Contract Database 1 owns it.
Deleted: Action wiring 57. Execution Contract Database 1 owns it: a redisposition's writes commit together, so no journal-rejected carries a notification id.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 2. Execution Contract Scheduled leg 1 owns it.
Deleted: Reconciliation 12. Execution Contract Database 1 owns it.
Deleted: Reconciliation 13. Execution Contract Database 1 owns it.
Deleted: Reconciliation 14. Execution Contract Database 1 owns it.
Deleted: Reconciliation 15. Execution Contract Database 1 owns it.
Deleted: Reconciliation 16. Execution Contract Database 1 owns it.
Deleted: Reconciliation 27. Execution Contract Database 1 owns it.
Deleted: Reconciliation 33. Execution Contract Database 2 owns it.
Deleted: Reconciliation 34. Execution Contract Database 2 owns it.
```

### Composition-level invariants › Invariant 10 — Invocation identity is unique and journaled

```
  Deleted: Invariant 6. Composes 5 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.2. Execution Contract Database 1 owns it.
Deleted: Check 2.3. Execution Contract Database 1 owns it.
Deleted: Check 3.5. Execution Contract Database 1 owns it.
Deleted: Check 4.2. Execution Contract Database 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```
