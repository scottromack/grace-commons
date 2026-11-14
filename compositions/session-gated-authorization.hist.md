---
title: Session-Gated Authorization — history
nav_exclude: true
search_exclude: true
---

# Session-Gated Authorization — history

The dated record of how [Session-Gated Authorization](./session-gated-authorization.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/session-gated-authorization.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the single action as a signature block with `Action wiring` carrying the two-step gate, `Primitive policy` carrying the boundary predicate, `Concurrency` carrying the revocation race, the four invariant numbers unchanged, and the acceptance section's two declared tiers split into `Check` and `External check` exactly as the prose divided them. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label, so the rewrite is free of frozen-number risk. The families are the wiring surfaces this composition actually has — no `Event schema`, no `Replay`, because it stores nothing and rebuilds nothing.

## Migration notes

- **2026-09-15 — Wiring decision 1, moved from Action wiring.** Wiring decision 1 is Action wiring 4's words, moved to the heading that names what it is when the headings were standardized (council read 80).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Session-Gated Authorization](./session-gated-authorization.md) may carry it again.

### Composition logic › Action wiring

```
Deleted: Action wiring 4. Wiring decision 1 owns it.
```

### Composition-level invariants › Invariant 1 — Session gates authorization

```
  Deleted: Invariant 1.2. Session Composition note 4 owns it.
  Deleted: Invariant 1.3. Session Composition note 4 owns it.
  Deleted: Invariant 1.4. Session Composition note 4 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.2. External check 6 owns it.
Deleted: Check 1.3. External check 7 owns it.
```

### Composition notes

```
Deleted: Composition note 2. Composition state 4 owns it.
```
