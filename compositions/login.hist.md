---
title: Login — history
nav_exclude: true
search_exclude: true
---

# Login — history

The dated record of how [Login](./login.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/login.md`.

## Decisions

Entries that record a migration, a family placement, a restoration or a reading of a gate's open lines rather than a turn the pattern took.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision`, `Reconciliation` as the surfaces, the six invariant numbers unchanged, and an acceptance section distributed from the checks the prose already named. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. **No preservation claim was collapsed** — this is the first composition of the epoch carrying none, because every invariant here already emerges and the constituents' guarantees were carried as citations rather than as invariants of their own. The three tombstones it does carry are re-homings inside the spec rather than collapses: `Invariant 4.1` to `Composition state 10`, `Non-goal 3` to `Wiring decision 3`, `Non-goal 14` to `Invariant 2.2`.
- **2026-09-14 — `Reconciliation` reaches recurrence in consecutive migrations, and the decision not to merge it with `Eviction` holds.** *Chose:* to take `Reconciliation` for the issuance-reconciliation sweep. *Over:* minting a third name, or folding it into `Composition state`. *Because:* [Authenticated Actor](./authenticated-actor.md) minted it one migration earlier for the orphaned-credential leg, and this sweep is the same family rather than the same shape: both run outside any invocation, both report or close rather than serve a caller, both owe an age edge. [Idempotent Reservation](./idempotent-reservation.md)'s `Eviction` shares the *shape* and remains separate for the reason council read 61 stated — it evicts where these report, and the difference decides whether a liveness bound is owed. Two consecutive specs is Principle 2's recurrence bar met for `Reconciliation`; `Eviction` stays at one and stays flagged (council read 62).
- **2026-09-27 — What the rewrite dropped, restored.** *Chose:* the arms and names the prose spec carried and the 2026-09-14 rewrite left out: logout relaying Session's already-terminal, storage-failure and invalid-request (Action wiring 27 through 29); the two named stages login's storage-failure lands at before a session exists (Action wiring 30, 31); the cascade's initiation data, its storage-failure answer, its join key in the revoke reason, its not-found count and its failure and not-found events (Action wiring 32 through 36, the revocation tally, the cascade events); the sweep's stored-reason choice of revocation-family member, its orphan reason, its abandon-and-re-run and its recovery intent (Reconciliation 15 through 19). One rule is new rather than restored: the sweep writes a map write failure's pair into both maps (Reconciliation 20), because Check 2.3 waits on that backfill and no rule wrote it. *Over:* a rewrite that claimed nothing but language changed. *Because:* a cold regeneration of the demo met each as a point the page left undecided, and each was decided in the prose spec and in this page's own Decisions of 2026-08-28 and 2026-08-29 (council read 234). Where the rewrite had changed a design on purpose — the credential id read twice rather than the credential verified twice — the rewrite's design stands.
- **2026-09-28 — The 2026-08 gate's open lines, read against the rewritten page.** *Chose:* of 34 open lines, 12 were already closed by the rewrite or the 2026-09-27 restoration and are removed; 21 were live and are cured here — Credential's length bound, the issuer references and the two reserved reasons taken at the boundary (Primitive policy 10 through 14); the entry id as the key between a log entry and its event (Composition state 16, Action wiring 39, Reconciliation 21); the log append's own failure arm and order (Action wiring 37, 38); the relation's cardinality (Composition state 13 through 15); the read's lower edge (Composes 18); the deployment as sole revoker (Capability requirement 17); the failed count carved out of Invariant 2.1; Invariant 5.1 over the rebuilt map; Check 5.2 inside the horizon; and the summary, intent and examples brought to the rules. The formal line stays. *Over:* carrying lines whose anchors — step 5a, the recovery discipline, Configuration — no longer exist. *Because:* a Ledger that names sections the page no longer has cannot be read against the page, and most of what it named had moved, not closed.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Login](./login.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 11. Execution Contract Database 3 owns it.
Deleted: Composition state 12. Execution Contract Database 3 and Execution Contract Database 4 own it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 14. Execution Contract Database 1 owns it.
Deleted: Capability requirement 15. Action wiring 13 owns it: every admitted login records its login event.
Deleted: Capability requirement 19. Primitive policy 18 owns it.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 14. Execution Contract Database 1 owns it: a login's session and its records commit together, so the sweep revokes no session under a reason of its own.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 1. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an owed record.
Deleted: Audit arm 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Audit arm 9. Execution Contract Database 1 owns it: an action that fails commits nothing, so no record stays landed beside it.
Deleted: Audit arm 10. Execution Contract Database 1 owns it: an action that fails commits nothing, so no record stays owed beside it.
Deleted: Audit arm 11. Execution Contract Database 1 owns it: an action that fails commits nothing, so no record stays owed beside it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 6. Execution Contract Database 2 owns it: the credential id read and Session's issue sit in one transaction, so no session commits against a credential the read did not see.
Deleted: Action wiring 7. Execution Contract Database 2 owns it.
Deleted: Action wiring 11. Execution Contract Database 1 owns it: the login's records commit before its map write, and the login succeeded event already carries the pair a rebuild restores.
Deleted: Action wiring 28. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 33. Audit arm 13 owns it.
Deleted: Action wiring 44. Action wiring 14 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 6. Execution Contract Database 1 owns it.
Deleted: Reconciliation 8. Execution Contract Database 1 owns it: a login's session, its login event log entry and its login event commit together, so no session outruns every record.
Deleted: Reconciliation 9. Execution Contract Database 1 owns it.
Deleted: Reconciliation 10. Reconciliation 15 owns it.
Deleted: Reconciliation 11. Execution Contract Database 1 owns it.
Deleted: Reconciliation 16. Execution Contract Database 1 owns it.
Deleted: Reconciliation 18. Execution Contract Database 1 owns it.
```

### Composition-level invariants › Invariant 4 — Login event log completeness

```
  Deleted: Invariant 4.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 4.1. Composition state 10 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.2. Execution Contract Database 1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 1. Execution Contract Database 3 owns it.
Deleted: External check 3. Execution Contract Database 1 owns it.
```

### Non-goals

```
Deleted: Non-goal 3. Wiring decision 3 owns it.
Deleted: Non-goal 14. Invariant 2.2 owns it.
```
