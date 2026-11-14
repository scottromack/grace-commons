---
title: Defensible Retention — history
nav_exclude: true
search_exclude: true
---

# Defensible Retention — history

The dated record of how [Defensible Retention](./defensible-retention.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/defensible-retention.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-11-02 — The audit instance's purge machinery arrived from Audit Trail (the maintainer's ruling of 2026-11-01 18:15Z, "Lawful destruction lives in one page", and his "as recommended" of 21:37Z).** See the Decisions entry of this date and [Audit Trail's history](./audit-trail.hist.md); this page's earlier claim that the audit cascade's gate was a non-goal (Non-goal 20 through 23) and a forthcoming Hold-Aware Audit Retention pattern's is withdrawn, the gate being this page's own.

- **2026-10-06 — The confirming round: what a reader would promote is cured before the reader runs, and a floor says what it does not promise.** *Chose:* one edge, *within the audit horizon*, for every horizon judgment a check makes, two allowances and the store's resolution inside the horizon (Term within the audit horizon, Check 6.4, Term aged-out hold, Term surviving destruction); the invariants that are owed at quiescence saying so, and over acts within the horizon (Invariant 3.1, 3.2, 4.1, 4.2, 8.1, 9.3, Term quiescence); an unverifiable answer over partly purged coverage read as unknown (Check 2.7); every overdue marker alerted on ahead of a run's first take, a run that cannot enumerate alerting on that, and a declared bound on a run's enumeration (Reconciliation 43, 44, Capability requirement 61, Term enumeration bound); an alert floor that promises the alert and a window to answer it and nothing of the closing after, and a closure floor that is the first leg's (Term alert floor, Term closure floor); one audit retention policy over every event of the audit instance, and the composition's action references kept to the composition (Capability requirement 57, 64); the recovery intent given its fields (Reconciliation 45, Term plan); an invocation id never given twice (Capability requirement 63, Check 5.10); a reference's field cap under the substrate's (Capability requirement 62); entry read from a hold placement's intent (Clock semantics 15). *Over:* check edges at the bare horizon while the sweep's stood inside it; invariants stated of every instant the rules themselves break for a while; a floor whose sentence promised a closing its arithmetic could not carry for a backlog; and a stand-in any co-tenant's short-lived event could supply. *Because:* the round the consecutive-rounds bar owed returned one foundational finding on five of its first seven Linus passes, and four of the five were lines this Ledger already carried as refining — the method cures a defect in the pass that finds it whatever its class, and a defect left on a Ledger is the next reader's finding. The models stand: no rule either one reads was changed.
- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except two rejection surfaces the prose misnamed.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Identity`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the wiring surfaces, with `Concurrency`, `Clock semantics` and `Atomic writes` as the edge-case families; the ten invariant numbers unchanged; the acceptance section's own two tiers carried across as `Check` and `External check`. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into defensible-retention` finds nothing in the corpus citing this composition by label, so the rewrite carried no frozen-number risk. **No family was minted.** Every one of the sixteen is standard or already recurring, and two of them move: `Audit arm`, which [Login](./login.md) minted one migration earlier, reaches two specs and so meets Principle 2's recurrence half; `Reconciliation` reaches three and so stands as a promotion candidate under `GRACE-lang.md` Standard label 4. `Identity` is the grammar's own standard family taken for the first time by a composition — thirty specs carry it, all of them atoms that mint ids, and this composition mints none: what it owns is an equality the gate evaluates, which is the same question one layer out.

## Migration notes

- **2026-09-15 — Clock semantics 4, 5 and 16, kept under Clock semantics.** Clock semantics 4, Clock semantics 5 and Clock semantics 16 stay under Clock semantics rather than under Clock dependence: the first two are this layer's uses of the reading and the third says the gate makes none — instances of that family's question, not statements of it (council read 75).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Defensible Retention](./defensible-retention.md) may carry it again.

### Composes

```
Deleted: Composes 11. Composes 21 owns it: the audit instance's end of life is this composition's own, reached through Audit Trail's record_destruction.
```

### Composition logic › Composition state

```
Deleted: Composition state 34. Execution Contract Database 1 owns it.
```

### Composition logic › Composition state › erasure outcomes

```
  Deleted: erasure outcomes 5. Execution Contract Database 1, Execution Contract Database 3 and Execution Contract Database 4 own it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 3. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 5. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 34. Concurrency 5 owns it.
Deleted: Capability requirement 35. Concurrency 5 owns it.
Deleted: Capability requirement 49. Execution Contract Database 3 owns it.
Deleted: Capability requirement 51. Execution Contract Scheduled leg 1 owns it.
Deleted: Capability requirement 52. Execution Contract Scheduled leg 1 owns it.
Deleted: Capability requirement 56. Execution Contract Database 2 owns it: Audit Trail names no margin for a record action to start on.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 15. Primitive policy 14 owns it.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 3. Execution Contract Database 1 owns it.
Deleted: Audit arm 4. Execution Contract Database 1 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 16. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 21. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 31. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 42. Action wiring 111 owns it.
Deleted: Action wiring 67. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 78. Action wiring 77 owns it.
Deleted: Action wiring 102. Execution Contract Database 1 owns it.
Deleted: Action wiring 103. Execution Contract Database 1 owns it.
Deleted: Action wiring 104. Execution Contract Database 1 owns it: a hold placement's intent, hold and outcome commit together, and the composition names no read ahead of the intent for Legal Hold to refuse.
Deleted: Action wiring 105. Execution Contract Database 1 owns it: a placement's intent, act and outcome commit together, and the composition names no id list for a placement intent to carry.
Deleted: Action wiring 107. Execution Contract Database 1 owns it.
Deleted: Action wiring 46. Composition state 19 owns it.
Deleted: Action wiring 51. Invariant 1.3 owns it.
```

### Composition logic › Action wiring › Purge Eligible Events contract

```
Deleted: purge eligible events 7. Execution Contract Error model 1 owns it: a declared read of Retention Window whose answer never arrives leaves [Purge Eligible Events] no answer to give, and none to read as an empty list.
```

### Composition logic › Wiring decision › Boundary one — only mechanisms that shred conform

```
Deleted: Boundary one 1. Audit Trail record destruction step 2.9 owns it.
Deleted: Boundary one 6. First half 5 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 10. Execution Contract Database 1 owns it.
Deleted: Reconciliation 12. Reconciliation 9 owns it.
Deleted: Reconciliation 16. Reconciliation 14 owns it.
```

### Composition logic › Reconciliation › First half — the half-completed cascade

```
Deleted: First half 4. First half 3 owns it.
Deleted: First half 8. First half 5 owns it.
```

### Composition-level invariants › Invariant 1 — Hold-blocks-purge

```
  Deleted: Invariant 1.4. Wiring decision 1 owns it.
```

### Composition-level invariants › Invariant 7 — Multi-hold independence

```
  Deleted: Invariant 7.4. Action wiring 53 owns it.
```

### Composition-level invariants › Invariant 9 — Cross-retention joint enforcement

```
  Deleted: Invariant 9.2. Composition state 19 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.3. Check 2.4 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 12. Execution Contract Database 3 owns it.
Deleted: External check 14. Execution Contract Scheduled leg 1 owns it.
```

### Non-goals

```
Deleted: Non-goal 20. Capability requirement 69 owns it: this composition gates the audit instance's cascade, which moved here from Audit Trail.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Action wiring 8 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Action wiring 106 owns it.
Deleted: Clock semantics 6. Composes 18 owns it.
Deleted: Clock semantics 7. Retention Window Operation 13 owns it.
Deleted: Clock semantics 8. Execution Contract Logic confinement 12 owns it.
Deleted: Clock semantics 9. Execution Contract Logic confinement 12 owns it.
Deleted: Clock semantics 10. Event Log Operation 2 owns it, reached through Audit Trail.
Deleted: Clock semantics 12. Action wiring 106 owns it.
Deleted: Clock semantics 13. Action wiring 106 owns it.
Deleted: Clock semantics 17. Capability requirement 36 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Concurrency 5 owns it.
Deleted: Concurrency 2. Concurrency 5 owns it.
Deleted: Concurrency 3. Concurrency 5 owns it.
```
