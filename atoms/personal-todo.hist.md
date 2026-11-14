---
title: Personal Todo — history
nav_exclude: true
search_exclude: true
---

# Personal Todo — history

The dated record of how [Personal Todo](./personal-todo.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/personal-todo.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the description policy as its own rule family, the eight invariant numbers unchanged, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan, and this atom is the corpus's simplest shape — the one a reader meets first.

- **2026-09-14 — The atom gained an acceptance surface, kept deliberately plain.** *Chose:* fourteen `Check` rules and three `External check` rules, each one reading of the list against one rule. *Over:* a richer section. *Because:* presence became mandatory on 2026-09-14, and this atom is the reference implementation's first worked example, so its section teaches the shape more than it audits a risk. Two things it does carry are not decoration: the three timestamp checks keep the invariants' conditional form rather than chaining them, since an auditor comparing `added_at ≤ last_edited_at ≤ completed_at` over every unit files against a correct list; and `Check 3.4`'s passing condition is that **nothing happened** — a no-op edit answers ok and writes nothing, so the evidence of conformance is a stamp that did not move (council read 65).

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every unit with its stored fields (Operation 28 through 31). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — "the current set of pending units" and done units, each with its fields — and the migration dropped it with the section. Restored as the prose had it, not widened. Found beside the same loss in Permissions and Actor Identity, which the cold regeneration of the Attributed Permissions Admin demo surfaced (council read 230).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Personal Todo](./personal-todo.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Non-goal 16 owns it.
```

### Structure › Operations

```
Deleted: Operation 6. Execution Contract Database 3 owns it.
Deleted: Operation 9a. Operation 32 and Operation 33 own it.
Deleted: Operation 11. Execution Contract Conformance 1 owns the admitted call's write.
Deleted: Operation 24. Execution Contract Read 4 owns it.
Deleted: Operation 25. Capability requirement 1 owns it.
Deleted: Operation 26. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 27. Execution Contract Logic confinement 3 owns it.
```

### Structure › Invariants › Invariant 1 — Membership exclusivity

```
  Deleted: Invariant 1.1. State 1 owns it.
```

### Structure › Invariants › Invariant 4 — Delete is terminal

```
  Deleted: Invariant 4.2. Identity 5 owns id reuse for every id, deleted or not.
```

### Structure › Invariants › Invariant 5 — Edit preserves state

```
  Deleted: Invariant 5.1. Invariant 5.2 and Operation 8 own it.
```

### Structure › Invariants › Invariant 8 — Id stability

```
  Deleted: Invariant 8.1. State 2 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 3.2. Check 3.3 owns it.
Deleted: Check 5.1. Execution Contract Read 4 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 2. Execution Contract Database 1 owns it.
Deleted: External check 3. Execution Contract Database 2 owns it.
```

### Non-goals

```
Deleted: Non-goal 7. Execution Contract Database 5 owns it.
```

### Edge cases › Concurrency on one unit

```
Deleted: Concurrency 2. Execution Contract Database 1 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Composition notes

```
Deleted: Composition note 4. Execution Contract Database 5 owns it.
```
