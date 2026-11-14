---
title: Session — history
nav_exclude: true
search_exclude: true
---

# Session — history

The dated record of how [Session](./session.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/session.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the twelve invariant numbers and the six acceptance checks unchanged, the derived lapse routed through a declared lapsed and effective status so no rule carries the comparison, the arithmetic in `issued_at + session_duration` moved into a declared expiry deadline (Hard invariant 24), [Validate]'s four-row precedence table kept beside the rules as the case space, Generation acceptance moved ahead of Non-goals to match the migrated corpus, the string-input paragraph raised to a `String 1 through 8` family matching Permissions and Notification, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk. Expiry earned its own family — eight rules that say a lapse writes nothing, fires nothing, stamps nothing and is scheduled by nobody — because the whole commitment was carried by prose emphasis in four places and is now a surface a checker can read.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
- **2026-09-15 — Clock dependence 1 and 2, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. Both rules keep the words they carried as Clock semantics 4 and 5; only the heading changed.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Session](./session.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 8. Invariant 7.1 owns it.
Deleted: Identity 10. Identity 9 and Capability requirement 4 own it.
```

### Structure › State

```
Deleted: State 3. Invariant 10.1 owns it.
Deleted: State 8. Invariant 12.1 owns it.
Deleted: State 9. Invariant 12.2 owns it.
```

### Structure › State › Expiry

```
Deleted: Expiry 1. Invariant 12.3 owns it.
Deleted: Expiry 3. Invariant 12.2 and Invariant 12.3 own it.
Deleted: Expiry 6. Invariant 12.3 owns it.
Deleted: Expiry 7. Operation 38 and Term effective status own it.
Deleted: Expiry 8. Operation 16 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 11. Operation 56 owns it.
Deleted: Capability requirement 7. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 8. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 9. Execution Contract Logic confinement 7 owns it.
Deleted: Configuration 1. Capability requirement 2 owns it.
Deleted: Configuration 2. Operation 48 owns it.
Deleted: Configuration 3. Capability requirement 3 owns it.
Deleted: Configuration 4. Operation 49 owns it.
Deleted: Configuration 5. Capability requirement 4 owns it.
Deleted: Configuration 6. Capability requirement 5 owns it.
Deleted: Configuration 7. Capability requirement 6 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Clock dependence 2 owns it.
Deleted: Clock semantics 6. Non-goal 25 owns it.
Deleted: Clock semantics 7. Non-goal 26 owns it.
```

### Structure › Operations

```
Deleted: Operation 7. Operation 8 and Operation 56 own it.
Deleted: Operation 13. Invariant 6.1 owns it.
Deleted: Operation 21. Invariant 6.1 owns it.
Deleted: Operation 32. Execution Contract Database 1 owns it.
Deleted: Operation 35. Execution Contract Database 3 owns it.
Deleted: Operation 42. Capability requirement 1 owns it.
Deleted: Operation 43. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 44. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 46. Non-goal 7 owns it.
Deleted: Operation 54. Execution Contract Input 1 owns it.
```

### Structure › Invariants › Invariant 2 — Expiry instant immutability

```
  Deleted: Invariant 2.2. Non-goal 7 and Non-goal 8 own it.
```

### Structure › Invariants › Invariant 3 — Validity bound conjunctive, by derivation

```
  Deleted: Invariant 3.2. Expiry 5 owns it.
```

### Structure › Invariants › Invariant 5 — Stored terminal absorbing

```
  Deleted: Invariant 5.2. Operation 23 owns it.
  Deleted: Invariant 5.3. Operation 27 owns it.
```

### Structure › Invariants › Invariant 9 — Session durability over this atom's own surface

```
  Deleted: Invariant 9.3. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 10 — Every session has a finite lifetime

```
  Deleted: Invariant 10.2. Invariant 10.1 owns it.
```

### Structure › Invariants › Invariant 11 — Expiry absorbing, by derivation

```
  Deleted: Invariant 11.2. Invariant 11.1 and Invariant 4.1 own it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.1. External check 2 owns it.
```

### Non-goals

```
Deleted: Non-goal 23. Non-goal 24 and Composition note 3 own it.
```

### Edge cases › Clock dependence

```
Deleted: Clock dependence 1. Execution Contract Logic confinement 3 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Edge cases › String policy

```
Deleted: String 8. Execution Contract Logic confinement 13 owns it.
```

### Composition notes

```
Deleted: Composition note 10. Execution Contract Atom interface 1 owns it.
Deleted: Composition note 11. Non-goal 27 owns it.
```
