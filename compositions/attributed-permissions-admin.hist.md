---
title: Attributed Permissions Admin — history
nav_exclude: true
search_exclude: true
---

# Attributed Permissions Admin — history

The dated record of how [Attributed Permissions Admin](./attributed-permissions-admin.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/attributed-permissions-admin.md`.

## Decisions

Entries that record a migration, an editorial rule or a family placement rather than a turn the pattern took.

- **2026-09-15 — The report-only leg is `Housekeeping`, not `Reconciliation`.** *Chose:* classify the Failed-Grant Reconciliation leg under `Housekeeping`, and state its no-write, no-repair, no-closure-window rules as that family's. *Over:* `Reconciliation`, which the leg's inherited name suggests and which three sibling compositions carry. *Because:* the grammar promoted both families at v0.42 and declared the boundary as one question — *does anything await the leg's output?* Nothing awaits this one: it reports, writes nothing, and promises no window in which an orphan closes, because nothing here **can** close one. An orphan's only resolution is a fresh administrative act by a caller. A leg that could close an orphan would be a second writer over one attestation, which breaks Invariant 7's injectivity with no arm to catch it — so the family that fits is the unawaited pole, and the name the leg has carried since it was prose is not the classification.
- **2026-09-15 — Constituent guarantees are quantified, never counted.** *Chose:* `EVERY` constituent invariant holds over its instance, each constituent's own acceptance bar cleared over its own store, and a rule forbidding this spec to count them. *Over:* the prose's per-constituent invariant and check enumerations. *Because:* every one of those figures had moved since it was written, so the clause asserting nothing was weakened was itself stale — a number a tool can compute belongs to the tool.
- **2026-09-15 — Rewritten in GRACE lang v0.42.** *Chose:* 118 KB of prose replaced by labelled rules across fifteen families, nine invariant numbers unchanged, one of two Ledger lines closed by the rewrite. *Over:* a transliteration carrying the page's unguarded tamper reading and its stale constituent counts into the rule surface. *Because:* a defect the rewrite finds is repaired in the pass that finds it; the line that stays open is the formal model's, which is a model change and not a language one.

## Migration notes

- **2026-09-15 — Clock dependence 1, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what an invocation stamps from it. The rule stood as Clock semantics 8 over a clock reading, a term the spec never declared, and was reworded over now, which the same commit declared beside the seam.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Attributed Permissions Admin](./attributed-permissions-admin.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 20. Execution Contract Database 1 owns it.
Deleted: Composition state 21. Execution Contract Database 1 owns it.
Deleted: Composition state 22. Execution Contract Database 1 owns it: an administrative act's attestations, constituent writes and pairing entries commit together, and the composition names no unpaired grant for a stamp to join to an orphan log entry.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 3. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 5. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 16. Execution Contract Database 1 owns it.
Deleted: Capability requirement 17. Execution Contract Database 1 owns it.
Deleted: Capability requirement 18. Execution Contract Database 1 owns it.
Deleted: Capability requirement 19. Execution Contract Database 1 owns it.
Deleted: Capability requirement 21. Execution Contract Database 1 owns it.
Deleted: Capability requirement 22. Execution Contract Database 1 owns it.
Deleted: Capability requirement 23. Execution Contract Database 1 owns it.
Deleted: Capability requirement 24. Execution Contract Database 1 owns it.
Deleted: Capability requirement 25. Execution Contract Database 1 owns it: an administrative act's attestations, constituent writes and pairing entries commit together, and the composition names no pairing write atomicity for an instance to lack.
Deleted: Capability requirement 26. Execution Contract Database 3 owns it.
Deleted: Capability requirement 31. Execution Contract Database 2 owns it: a pair-scoped revocation's enumeration and the revocations it decides are one transaction, and the composition names no race for a critical section keyed by the pair to close.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 87. Execution Contract Constituent failure 2 owns it.
Deleted: Action wiring 88. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 9. Execution Contract Database 1 owns it.
Deleted: Action wiring 11. Execution Contract Database 1 owns it.
Deleted: Action wiring 12. Execution Contract Database 3 owns it.
Deleted: Action wiring 13. Execution Contract Database 1 owns it.
Deleted: Action wiring 14. Execution Contract Database 1 owns it.
Deleted: Action wiring 89. Execution Contract Constituent failure 2 owns it.
Deleted: Action wiring 90. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 25. Execution Contract Database 1 owns it.
Deleted: Action wiring 31. Execution Contract Database 1 owns it.
Deleted: Action wiring 32. Execution Contract Database 1 owns it.
Deleted: Action wiring 33. Execution Contract Database 1 owns it.
Deleted: Action wiring 34. Execution Contract Database 1 owns it.
Deleted: Action wiring 35. Execution Contract Database 1 owns it.
Deleted: Action wiring 36. Execution Contract Database 1 owns it.
Deleted: Action wiring 93. Execution Contract Constituent failure 2 owns it.
Deleted: Action wiring 95. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 47. Execution Contract Database 2 owns it.
Deleted: Action wiring 49. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 50. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 53. Execution Contract Database 1 owns it.
Deleted: Action wiring 67. Action wiring 63 through 65 own it: an absent attestation the purge record names answers not-applicable(purged) under either retention scope, and one it does not name answers the tamper reading.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 3. Execution Contract Database 1 owns it.
```

### Composition logic › Housekeeping

```
Deleted: Housekeeping 11. Execution Contract Database 1 owns it.
Deleted: Housekeeping 12. Execution Contract Database 1 owns it.
Deleted: Housekeeping 19. Action wiring 38 owns it: a retry stands as a fresh administrative act, and no rule obliges a caller to retry an orphan's act.
```

### Composition-level invariants

```
Deleted: Invariant 1.3. Execution Contract Database 1 owns it.
Deleted: Invariant 2.3. Execution Contract Database 1 owns it.
Deleted: Invariant 9.4. Execution Contract Database 1 and Execution Contract Database 2 own it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.3. Execution Contract Database 1 owns it.
Deleted: Check 5.4. Execution Contract Database 1 owns it.
Deleted: Check 5.5. Execution Contract Database 1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 3. Execution Contract Database 1 owns it.
Deleted: External check 4. Execution Contract Database 3 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 9. Execution Contract Database 1 owns it.
Deleted: Atomic writes 10. Execution Contract Database 1 owns it.
Deleted: Atomic writes 11. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Identity 8 owns it: a proposal carries the request instant (Identity 7), and the request instant is the invocation's seam reading.
Deleted: Clock semantics 1. Capability requirement 1 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 8. Clock dependence 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 4. Execution Contract Database 2 owns it.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Deleted: Concurrency 9. Execution Contract Database 2 owns it: a pair-scoped revocation's enumeration and the revocations it decides are one transaction, so no issuance commits inside the sweep for a critical section to keep out.
```
