---
title: Consent — history
nav_exclude: true
search_exclude: true
---

# Consent — history

The dated record of how [Consent](./consent.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/consent.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the ten invariant numbers and the seven acceptance-check numbers unchanged, the [Check] selection routed through a declared candidate record and the two comparisons through withdrawn and elapsed, the semantic/stored split kept as two rule families with the dated residual note carried over verbatim, the case space kept beside the rules as a table, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk. The rejection priority [Revoke] carried as an arrow diagram is now carried by the guards — a blank consent id is refused before the store is consulted, the terminal answers are exclusive by Invariant 2.1, and the attribution and temporal checks are conditioned on the record standing in [Granted].

## Migration notes

- **2026-06-21 — Clearly-marked residual (execution/render-time refactor).** The *authoritative* expiry determination is **derived** at read time: [Check] and [Read] both compute the state from [Expiry Instant] and [Revocation Instant] against the evaluation instant, and [Check] is a pure query that never writes (Operation 36; there is no `expire` action — Expiry 5). The stored [State] field's [Expired] value is therefore a **materialized cache of the derived state, not the authority** — written for query convenience, and required by Invariant 2.2 to equal the derived state at the moment any result is returned. This stored write is the **residual** of this atom against the render-time target, which would carry no stored [Expired] write at all and derive the projection on every read, as Invitation does. It was *clearly marked in the spec* rather than removed: dropping the stored [State] field is a structural change beyond this refactor, the eager/lazy design was introduced deliberately (Final Critique 4, to resolve the semantic-versus-stored contradiction), and because the cache must equal the derived value at read time it cannot serve as a flag that lags the clock in any conforming implementation. A future re-pass may collapse the stored [State] field to a pure read-time projection; that is an open design point, not done in the refactor.
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
- **2026-09-15 — Clock dependence 1, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. The rule keeps the words it carried as Clock semantics 4; only the heading changed.
- **2026-09-15 — Clock semantics 5, 6 and 8, kept under Clock semantics.** Clock semantics 5, Clock semantics 6 and Clock semantics 8 stay under Clock semantics rather than under Clock dependence: each is one action's use of a reading Clock dependence 1 already permits, and a family rule does not enlarge because an action instantiates it (council read 75).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Consent](./consent.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 8. Execution Contract Logic confinement 10 owns it.
```

### Structure › State

```
Deleted: State 8. Expiry 1 and Invariant 2.1 own it.
Deleted: State 10. Invariant 1.2 and Invariant 9.1 own it.
Deleted: State 11. Invariant 3.1 owns it.
Deleted: State 12. Invariant 3.2 owns it.
Deleted: State 13. Non-goal 23 owns it.
Deleted: State 14. Non-goal 11 owns it.
Deleted: State 15. Non-goal 24 owns it.
Deleted: State 1. Invariant 2.1 owns it.
```

### Structure › State › Expiry

```
Deleted: Expiry 7. Composition note 9 owns it.
```

### Structure › State › Stored state

```
Deleted: Stored state 1. Expiry 5 and Execution Contract Database 4 own it.
Deleted: Stored state 2. Operation 36 and Operation 49 own it.
Deleted: Stored state 4. Execution Contract Database 2 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
```

### Structure › Operations

```
Deleted: Operation 7. State 4, Operation 8 and Operation 9 own it.
Deleted: Operation 11. State 5 and State 16 own it.
Deleted: Operation 14. Execution Contract Refusal 1 owns it.
Deleted: Operation 17. Execution Contract Refusal 1 owns it.
Deleted: Operation 21. Execution Contract Logic confinement 12 owns it.
Deleted: Operation 33. Execution Contract Database 3 owns it.
Deleted: Operation 38. Execution Contract Logic confinement 12 owns it.
Deleted: Operation 53. Execution Contract Query 4 and Operation 47 own it.
Deleted: Operation 54. Instance 2, Operation 47 and Execution Contract Query 3 own it.
Deleted: Operation 60. Execution Contract Query 3 owns it.
Deleted: Operation 61. Capability requirement 1 owns it.
Deleted: Operation 62. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 63. Execution Contract Logic confinement 3 owns it.
```

### Structure › Invariants › Invariant 6 — Expiry coherence

```
  Deleted: Invariant 6.1. Operation 42 and Invariant 6.2 own it.
  Deleted: Invariant 6.3. Operation 36 and Operation 49 own it.
```

### Structure › Invariants › Invariant 8 — Consent record durability

```
  Deleted: Invariant 8.2. Invariant 8.1 and Execution Contract Database 6 own it.
  Deleted: Invariant 8.3. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 9 — Revocation non-retroactivity

```
  Deleted: Invariant 9.2. Invariant 9.1 and Invariant 10.3 own it.
```

### Structure › Invariants › Invariant 10 — Point-in-time faithfulness

```
  Deleted: Invariant 10.4. Invariant 10.1 and Invariant 10.3 own it.
```

### Structure › Database instance model

```
Deleted: Instance 1. Execution Contract Database 7 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.2. Invariant 2.2 and Stored state 3 own it.
Deleted: Check 6.1. Operation 18 and Invariant 3.1 own it.
Deleted: Check 6.2. Operation 19 and Invariant 3.2 own it.
Deleted: Check 6.3. Operation 32 owns it.
Deleted: Check 8.1. Check 8.2 through 8.4 own it.
```

### Edge cases › Clock dependence

```
Deleted: Clock dependence 1. Execution Contract Logic confinement 11 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 5. Operation 8 and Operation 9 own it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 4. Execution Contract Logic confinement 11 owns it.
Deleted: Clock semantics 7. Operation 10 owns it: `now` is never supplied by the business caller, so a grant instant stamped from the injected now is never a caller-supplied instant.
Deleted: Clock semantics 6. Operation 24 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Composition notes

```
Deleted: Composition note 8. Execution Contract Atom interface 1 owns it.
```
