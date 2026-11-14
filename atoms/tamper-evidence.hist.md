---
title: Tamper Evidence — history
nav_exclude: true
search_exclude: true
---

# Tamper Evidence — history

The dated record of how [Tamper Evidence](./tamper-evidence.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/tamper-evidence.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, the verify precedence carried by each rule's own condition rather than by the order the rules sit in, the nine invariant numbers frozen exactly as Audit Trail cites them, Generation acceptance moved ahead of Non-goals as `spec-format.md` requires, Non-goals and Edge cases as two sections, the case table kept beside the rules. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail cites this atom's Invariants 1, 3, 4, 8 and 9 (`tools/grace/cites.py --into tamper-evidence`).

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every evidence with its stored fields (Operation 27 through 30). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — "the current set of [Evidence] records", each with its fields — and the migration dropped it with the section. Restored as the prose had it, not widened. Found beside the same loss in Permissions and Actor Identity, which the cold regeneration of the Attributed Permissions Admin demo surfaced (council read 230).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Tamper Evidence](./tamper-evidence.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
```

### Structure › Operations

```
Deleted: Operation 12. Invariant 1.1 owns it.
Deleted: Operation 21. Capability requirement 1 owns it.
Deleted: Operation 22. Capability requirement 4 owns it.
Deleted: Operation 22a. Capability requirement 5 owns it.
Deleted: Operation 23. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 24. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 30. Operation 27 and Execution Contract Read 2 own it.
Deleted: Operation 31. Execution Contract Read 1 owns it.
Deleted: Operation 32. Execution Contract Refusal 1 owns it.
```

### Structure › Invariants › Invariant 2 — Detectability of tampering

```
  Deleted: Invariant 2.3. Non-goal 17 owns it.
```

### Structure › Invariants › Invariant 4 — Verification self-containment given the originating records

```
  Deleted: Invariant 4.2. Invariant 4.3 owns it.
```

### Structure › Invariants › Invariant 9 — Seal record durability

```
  Deleted: Invariant 9.2. Invariant 9.1 and Execution Contract Database 6 own it.
  Deleted: Invariant 9.3. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.1. A trusted-timestamping pattern owns it (Non-goal 9, Non-goal 15): an anchored bound on when a record set changed.
Deleted: Check 5.2. A forensic-attribution pattern owns it (Non-goal 15, Non-goal 16): a bound between two seals on when a record set changed.
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
Deleted: Check 6.2. External check 4 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 3. Execution Contract Conformance 9 owns it.
```

### Edge cases › Atomicity of a seal

```
Deleted: Seal atomicity 1. Execution Contract Database 1 owns it.
Deleted: Seal atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Seal atomicity 3. Execution Contract Database 3 owns it.
```

### Edge cases › Retention coupling

```
Deleted: Retention coupling 1. The composing pattern that owns the purge owns it (Retention coupling 2): a copy of a purged record set can still verify.
Deleted: Retention coupling 3. The composing pattern that owns the purge owns it (Retention coupling 2): what a seal over destroyed records proves.
```

### Edge cases › Verification caching

```
Deleted: Verification caching 3. An external-anchoring pattern owns it (Non-goal 2): what a seal answers once its anchor changes.
```

### Composition notes

```
Deleted: Composition note 5. GRACE-lang Hard invariant 26 owns it.
```
