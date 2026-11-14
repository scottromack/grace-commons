---
title: Idempotent Reservation — history
nav_exclude: true
search_exclude: true
---

# Idempotent Reservation — history

The dated record of how [Idempotent Reservation](./idempotent-reservation.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/idempotent-reservation.md`.

## Decisions

Entries that record a migration, a council read's collapse, where a classification is carried, a family placement or a regeneration rather than a turn the pattern took.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except two invariants the Execution Contract already owns.** *Chose:* `Composes`, `Composition state`, `Eviction`, `Capability requirement`, `Primitive policy`, `Action wiring`, `Wiring decision` and `Indeterminate outcome` as the surfaces, the six surviving invariant numbers unchanged, and the acceptance section's own two tiers carried across. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. `Eviction` is the one family minted here and it is minted for a reason no other composition has had: the eviction leg is the only leg in the corpus that runs *outside* an invocation, with its own two edges and its own exclusion against the invocations it runs beside, and folding nine rules about a background sweep into `Composition state` would have buried the one surface a reader most needs to find. One spec, flagged, waiting on recurrence (Principle 1 through 3, council read 57's promotion path).
- **2026-09-14 — Two preservation claims are one citation, third instance.** *Chose:* `Composes 5`, with `Invariant 5` and `Invariant 6` tombstoned to it. *Over:* keeping them. *Because:* council read 53's ruling, now applied at its third seam. What they carried beyond the blanket survives as `Composes 6` (the unchanged relay of a constituent rejection, which no atom guarantees about a caller) and `Composes 7` (the once-per-first-invocation `record` discipline, which is this composition's call pattern rather than a property of [Duplicate Prevention](../atoms/duplicate-prevention.md)).
- **2026-09-14 — The extraction-pending element is carried as a rule surface, not softened.** *Chose:* to state the `token_results` map as nine `Composition state` rules with the classification named in the WHY, the proposed atom named, and `Capability requirement 12` through `Capability requirement 14` carrying its durability. *Over:* describing it in prose, as every other composition's state section does — because every other composition's state section had nothing to describe. *Because:* this is the corpus's first migrated composition carrying truth no replay of its constituents reproduces, and the section titled Composition state in `execution-contract.md` says an unflagged truth-bearing composition store is a conformance finding while a flagged one is scheduled debt. The flag is the whole difference, so it belongs on the rule surface where an instrument can find it rather than in a paragraph (council read 58).
- **2026-09-14 — `Eviction` re-cut as `Housekeeping`, joining the leg it was kept apart from.** *Chose:* the family renamed, with the nine rules and every citation of them moving with it. *Over:* keeping a one-spec family named for what this leg happens to do. *Because:* the entry above kept `Eviction` apart from [Authenticated Actor](./authenticated-actor.md)'s `Reconciliation` on *one evicts and one reports*, and the drift pass found that axis wrong — it predicts the liveness bound on two of four legs, and this leg is one of the two it misses, because it takes a critical section and writes to the composition's own store while owing nothing. What decides the bound across all four is whether anything **awaits** the leg's output. Nothing awaits an eviction and nothing awaits an orphan report, so the two are one family; [Login](./login.md)'s and [Defensible Retention](./defensible-retention.md)'s sweeps discharge a promise and are the other. `Housekeeping 7` and `Housekeeping 8` keep their reading unchanged — they are still why this leg owes no liveness bound, and now the family name says so too (council read 64).
- **2026-09-28 — What the rewrite dropped from the re-entry arms, restored.** *Chose:* the collision check over a pending entry as well as a complete one (Action wiring 7, 8); the guard recorded for every result that lands, a re-entry's included (Action wiring 25); a resolving action run again on a seen token carrying no entry, with outcome-unknown kept for [Place Hold] (Indeterminate outcome 10, 13, Wiring decision 4); a resolving action's candidates named (Indeterminate outcome 14); the window strictly longer than the completion bound (Capability requirement 10); and Composition state 8, which conditioned on a returned invocation the map cannot show, tombstoned to Housekeeping 5. *Over:* the 2026-09-14 rewrite's reading, which its Decisions entry called language only. *Because:* the prose spec it replaced decided each of these, and the cold regeneration of 2026-09-28 met every one.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Idempotent Reservation](./idempotent-reservation.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 4. Execution Contract Database 1 owns it.
Deleted: Composition state 5. Execution Contract Database 1 owns it.
Deleted: Composition state 7. Execution Contract Database 1 owns it: an action's writes commit together, and the composition names no overwrite to keep the pending instant across.
Deleted: Composition state 10. Execution Contract Logic confinement 8 owns it.
Deleted: Composition state 8. Housekeeping 5 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 5. Execution Contract Database 2 owns it.
Deleted: Capability requirement 6. Execution Contract Database 2 owns it.
Deleted: Capability requirement 7. Execution Contract Database 2 owns it: an action's reads of a token and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 8. Execution Contract Database 2 owns it: an action's reads of a token and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 9. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Capability requirement 10. Execution Contract Database 1 and Execution Contract Database 2 own it: the composition names no reservation completion bound for the idempotency window to exceed.
Deleted: Capability requirement 11. Execution Contract Database 1 and Execution Contract Database 2 own it: the composition names no reservation completion bound for the idempotency window to exceed.
Deleted: Capability requirement 12. Execution Contract Database 3 owns it.
Deleted: Capability requirement 13. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Capability requirement 14. Execution Contract Database 3 owns it.
Deleted: Capability requirement 15. Execution Contract Database 3 owns it.
Deleted: Capability requirement 17. Execution Contract Database 3 owns it.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 7. Wiring decision 3 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 2. Execution Contract Database 2 owns it.
Deleted: Action wiring 3. Execution Contract Database 2 owns it.
Deleted: Action wiring 4. Execution Contract Database 2 owns it.
Deleted: Action wiring 5. Execution Contract Database 2 owns it: an action's reads of a token and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Action wiring 6. Execution Contract Database 2 owns it: an action's reads of a token and the writes they decide are one transaction, and the composition names no critical section to lapse.
Deleted: Action wiring 11. Execution Contract Database 1 owns it.
Deleted: Action wiring 13. Execution Contract Database 1 owns it.
Deleted: Action wiring 14. Execution Contract Database 1 owns it.
Deleted: Action wiring 15. Execution Contract Database 1 owns it.
Deleted: Action wiring 16. Execution Contract Database 1 owns it.
Deleted: Action wiring 17. Execution Contract Database 1 owns it.
Deleted: Action wiring 18. Execution Contract Database 1 owns it.
Deleted: Action wiring 19. Execution Contract Database 1 owns it: an action's writes commit together, so no recording failure names the outcome.
Deleted: Action wiring 20. Execution Contract Database 1 owns it.
Deleted: Action wiring 24. Action wiring 1 owns it.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 5. Execution Contract Database 1 owns it: an action's writes commit together, so the composition answers no recording failure to record.
```

### Composition logic › Housekeeping

```
Deleted: Housekeeping 1. Execution Contract Database 2 owns it.
Deleted: Housekeeping 2. Execution Contract Database 2 owns it: the eviction leg's reads of a token and the eviction they decide are one transaction, and the composition names no critical section for another holder to hold.
Deleted: Housekeeping 3. Execution Contract Database 1 owns it.
```

### Composition-level invariants › Invariant 7 — Token expiry releases the binding

```
  Deleted: Invariant 5. Composes 5 owns it.
  Deleted: Invariant 6. Composes 5 and Composes 7 own it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 3.2. Execution Contract Database 1 owns it.
Deleted: Check 5.1. Indeterminate outcome 8 owns it.
Deleted: Check 5.2. Execution Contract Database 1 owns it: an action's writes commit together, so no entry records outcome-unknown.
```

### Generation acceptance › External checks

```
Deleted: External check 1. Execution Contract Database 2 owns it.
Deleted: External check 2. Execution Contract Database 3 owns it.
Deleted: External check 4. Execution Contract Database 3 owns it.
```

### Non-goals

```
Deleted: Non-goal 6. Execution Contract Database 1 owns it.
```

### Edge cases › Indeterminate outcome

```
Deleted: Indeterminate outcome 1. Execution Contract Database 1 owns it.
Deleted: Indeterminate outcome 2. Execution Contract Database 1 owns it: an action's writes commit together, so no call finds a pending entry.
Deleted: Indeterminate outcome 5. Execution Contract Database 1 owns it: an action's writes commit together, so no call finds a pending entry.
Deleted: Indeterminate outcome 6. Execution Contract Database 1 owns it: an action's writes commit together, so no call finds a pending entry.
Deleted: Indeterminate outcome 9. Execution Contract Database 1 owns it: an action's writes commit together, so no call finds a pending entry.
Deleted: Indeterminate outcome 12. Execution Contract Database 1 owns it: an action's writes commit together, so no caller receives a recording failure naming the outcome.
Deleted: Indeterminate outcome 14. Execution Contract Database 3 owns it: the database acknowledges a write only once it commits, so no resolving action answers outcome-unknown.
```
