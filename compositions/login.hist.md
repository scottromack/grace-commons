---
title: Login — history
nav_exclude: true
search_exclude: true
---

# Login — history

The dated record of how [Login](./login.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/login.md`.

## Decisions

Entries that record a migration, a family placement, a restoration or a reading of a gate's open lines rather than a turn the pattern took.

- **2026-08-26 — Every Login event is composition-attributed.** *Chose:* attest under `application_actor_ref` / `application_credential`, with the human parties in `data`. *Over:* attesting under the principal's own credential. *Because:* Login's callers are end principals whose material is the thing under test, not registry actors — and a failed login has no valid credential to attest with. This governs every audit write the pattern makes.

- **2026-08-26 — Invariant 2 promises less than it did.** *Chose:* cascade completeness is claimed only for verifies that committed after the revocation, with the in-flight window named and a second cascade prescribed after quiescence. *Over:* single-cascade sufficiency. *Because:* a login whose verify committed before the revocation can land its session after the cascade's snapshot, and no single cascade can see it. The headline guarantee is narrower and true.

- **2026-08-28 — The cascade writes its join key into the Session record, and what cannot be re-emitted is re-run.** *Chose:* step 5b's revoke reason carries `initiation_event_id`, so a sweep re-emission carries the real id and check 3 counts it; the completion event waits for every per-session record; an initiation that dies without completion is abandoned and the cascade re-run. *Over:* re-emitted events with `initiation_event_id: null` excluded from the arithmetic, and a claim that the sweep re-derives every owed record. *Because:* a failed revoke and a not-found token leave nothing in any store to re-derive a record from, so the claim was false; re-running is the only honest closure, and the join key in the reason makes the re-emittable records exact rather than excused.

- **2026-08-28 — The sweep is age-bounded and `login_event_log` is extraction-pending against Event Log.** *Chose:* a declared `login_completion_bound` below which the sweep examines nothing, and the log classified as the composition's own call journal pending extraction, durable now. *Over:* an unbounded sweep and a "conditional derived index". *Because:* the unbounded sweep revoked logins still in flight, and the invented classification let a generator hold the sweep's only intent in memory.

- **2026-08-29 — The sweep is bounded above as well as below, and records its intent before it revokes or re-runs.** *Chose:* every comparison scoped to the audit horizon, past which a missing event is destruction and the record is reported purged rather than repaired; a `login_recovery_intended` event before the second comparison's revoke and the fourth's re-run; `reconciliation_window` and `reconciliation_cadence` declared. *Over:* the age-bounded sweep of 2026-08-28 with no upper edge. *Because:* a comparison past the horizon revokes sessions whose issuance events aged out and re-emits logouts the purge lawfully removed, and a sweep that revokes with no record of its own is indistinguishable from a direct call (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*).

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision`, `Reconciliation` as the surfaces, the six invariant numbers unchanged, and an acceptance section distributed from the checks the prose already named. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. **No preservation claim was collapsed** — this is the first composition of the epoch carrying none, because every invariant here already emerges and the constituents' guarantees were carried as citations rather than as invariants of their own. The three tombstones it does carry are re-homings inside the spec rather than collapses: `Invariant 4.1` to `Composition state 10`, `Non-goal 3` to `Wiring decision 3`, `Non-goal 14` to `Invariant 2.2`.

- **2026-09-14 — `Reconciliation` reaches recurrence in consecutive migrations, and the decision not to merge it with `Eviction` holds.** *Chose:* to take `Reconciliation` for the issuance-reconciliation sweep. *Over:* minting a third name, or folding it into `Composition state`. *Because:* [Authenticated Actor](./authenticated-actor.md) minted it one migration earlier for the orphaned-credential leg, and this sweep is the same family rather than the same shape: both run outside any invocation, both report or close rather than serve a caller, both owe an age edge. [Idempotent Reservation](./idempotent-reservation.md)'s `Eviction` shares the *shape* and remains separate for the reason council read 61 stated — it evicts where these report, and the difference decides whether a liveness bound is owed. Two consecutive specs is Principle 2's recurrence bar met for `Reconciliation`; `Eviction` stays at one and stays flagged (council read 62).

- **2026-09-14 — The first composition to name a composition as a constituent.** *Chose:* `Composes 6` and `Composes 7`, citing the section titled Substrate composition invocation in `execution-contract.md`, with `External check 6` sending an auditor to [Audit Trail](./audit-trail.md)'s own acceptance rather than re-verifying it here. *Over:* listing Event Log, Actor Identity, Retention Window and Tamper Evidence as this composition's constituents, which is what the atom-only reading of `Composes` would have produced. *Because:* the substrate's guarantees are inherited by reference — that is the point of naming a substrate — and re-listing its constituents would have claimed instances this composition does not hold. The corpus composes compositions and this is the first migrated spec where the rule surface has to say so.

- **2026-09-27 — What the rewrite dropped, restored.** *Chose:* the arms and names the prose spec carried and the 2026-09-14 rewrite left out: logout relaying Session's already-terminal, storage-failure and invalid-request (Action wiring 27 through 29); the two named stages login's storage-failure lands at before a session exists (Action wiring 30, 31); the cascade's initiation data, its storage-failure answer, its join key in the revoke reason, its not-found count and its failure and not-found events (Action wiring 32 through 36, the revocation tally, the cascade events); the sweep's stored-reason choice of revocation-family member, its orphan reason, its abandon-and-re-run and its recovery intent (Reconciliation 15 through 19). One rule is new rather than restored: the sweep writes a map write failure's pair into both maps (Reconciliation 20), because Check 2.3 waits on that backfill and no rule wrote it. *Over:* a rewrite that claimed nothing but language changed. *Because:* a cold regeneration of the demo met each as a point the page left undecided, and each was decided in the prose spec and in this page's own Decisions of 2026-08-28 and 2026-08-29 (council read 234). Where the rewrite had changed a design on purpose — the credential id read twice rather than the credential verified twice — the rewrite's design stands.

- **2026-09-28 — The 2026-08 gate's open lines, read against the rewritten page.** *Chose:* of 34 open lines, 12 were already closed by the rewrite or the 2026-09-27 restoration and are removed; 21 were live and are cured here — Credential's length bound, the issuer references and the two reserved reasons taken at the boundary (Primitive policy 10 through 14); the entry id as the key between a log entry and its event (Composition state 16, Action wiring 39, Reconciliation 21); the log append's own failure arm and order (Action wiring 37, 38); the relation's cardinality (Composition state 13 through 15); the read's lower edge (Composes 18); the deployment as sole revoker (Capability requirement 17); the failed count carved out of Invariant 2.1; Invariant 5.1 over the rebuilt map; Check 5.2 inside the horizon; and the summary, intent and examples brought to the rules. The formal line stays. *Over:* carrying lines whose anchors — step 5a, the recovery discipline, Configuration — no longer exist. *Because:* a Ledger that names sections the page no longer has cannot be read against the page, and most of what it named had moved, not closed.

- **2026-10-21 — The store's guarantees cited, not restated, the orphan-session comparison among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 18), and the seventeen rules that restated it, or existed only for a store that could lose or split a write, tombstoned to their owner — to Store 1, under which a login's session, its login event log entry and its login event commit together: the sweep's revoke of a session no record names, with its event, its reason, the boundary rule reserving that reason, its recovery intent and the invariant making the gap the sweep's (Reconciliation 8, 9, 16, 18, Primitive policy 14, Invariant 4.2), the lower edges below which the sweep examined no session and no cascade initiation, the login completion bound they read and its external check, and the auditor's twin of the orphan comparison (Reconciliation 6, 11, Capability requirement 14, External check 3, Check 5.2), and the invocation's own retry of a recording failure (Audit arm 1); to Store 1 and Store 3, the sweep's run at an instance's start and an owed record derived again at a restart (Reconciliation 1, Audit arm 3); to Store 3, the login event log's durability across a restart and its external check (Composition state 11, External check 1); and to Store 3 and Store 4, the bar on rebuilding the log at a restart (Composition state 12); with them Check 3.3 rebuilds a principal reference's session set from the log alone and Check 4.1 reads every cascade initiation, not only one older than the bound; rules 187 to 171. *Over:* a session committed apart from its records and found by a sweep once it outlived a declared completion bound, revoked under a reserved reason, and a login event log held across a restart by a rule of its own — the turns of 2026-08-28 and 2026-08-29, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included: Session's records, the login event log and the audit trail's records are one store, so a login that stops commits nothing and a login that commits leaves its session, its entry and its event together. The other calls a rule decided: the two maps stay a derived index outside the action's atomicity surface (obligation 2 of the section titled Composition state in `execution-contract.md`, which the ruling left as it was), so the maps' own transaction, the map write's failure arm and its event, the cascade's union read, the sweep's backfill and the check that waits on it stay (Composition state 3, 8, Action wiring 10, 11, 18, Reconciliation 20, Invariant 2.3, 2.4, Check 2.3); the audit trail's invalid-request at a record still leaves the action's other writes committed and the record owed, or at step-4 landed (Audit arm 9 through 12), so the re-emission, the comparison of revocations against their events and the cascade's abandon-and-re-run stay (Reconciliation 5, 10, 12, 15, 17, 19); and no kept rule reads a record's earlier version or compares two commits, so Store 5 and Order 1 are not cited. What the composition does for its domain is otherwise unchanged.

- **2026-10-29 — A failed map write is a rebuild trigger, not a recorded outcome.** *Chose:* the maps written after the login's one commit, a failed map write answering the token and leaving its pair on the login succeeded event for the rebuild and the sweep's backfill (Action wiring 10, Reconciliation 20, Check 2.3); the map write failure event, the Success With Map Failure outcome and the confirm read tombstoned (Action wiring 6, 7, 11). *Over:* the map-failure arm the 2026-10-21 entry kept, which logged the map's outcome in the login's own entry and event. *Because:* Execution Contract Database 1 commits a login's session, entry and event together, before the map write that the section titled Composition state in `execution-contract.md` makes evidence of that commit, never a peer write whose failure is recorded; recording the failure would be a second commit of one login, and the login succeeded event already carries the pair (Final Critique 10).

- **2026-11-15 — The rules say what the login's one commit holds.** *Chose:* Action wiring 45 and 46, the login event log entry, the login event and, where Credential's verify answered verified, the session record written in one transaction (Execution Contract Database 1), with Action wiring 9 and 37 saying where their order stands: the maps after the login transaction commits, the login event after the entry lands inside it. *Over:* the one commit living only in the Decisions of 2026-10-21 and 2026-10-29, the case table's *nothing written* and Capability requirement 18's citation, which a reader of the rules alone read as a session committed before its log entry (*ONLY AFTER Session's issue commits*). *Because:* the intent never changed, and no rule said it; the seam trial built the orphan session from the rules as written. Action wiring and Composition state hold 54 rules before and 56 after; the two maps, the map write's failure arm and every other rule stand.

- **2026-11-18 — The cascade is one transaction, so it keeps no abandoned arm: Reconciliation 12, 17 and 19 retire to Execution Contract Database 1, and Login composes nothing for the cascade's initiation, completion, abandonment or recovery.** *Chose:* Reconciliation 12 (the cascade abandoned event), 17 (the sweep's re-run of the cascade for an abandoned initiation) and 19 (the recovery intent before a re-run) leave their `Deleted:` tombstones naming Database 1 and this ruling, never renumbered or reused; Term recovery intent goes; Term cascade events drops the abandoned event; Check 4.1 keeps only its completed arm (an auditor MUST find every cascade initiation event carrying a completion event); Invariant 2's *Rests on* drops Reconciliation 17. Citations found, by label: Reconciliation 12 (Check 4.1, Term cascade events), Reconciliation 17 (Invariant 2's *Rests on*), Reconciliation 19 (Term recovery intent), Reconciliation 20 and the reconciliation window it runs in (kept untouched), Check 4.1, Action wiring 17, 25 and 32 (the cascade's initiation and completion, kept), the Ledger's formal line and open line 2026-08-29-a (its recovery-record half dissolves, its upper-edge half stays), and in the models `login.als` (Abandon, abandonWrites, `A_Check_4_1`) with the copies of them in ten twins; `login.tla` carries no abandon step. Rules 3 fewer (the Reader's IR, 11,973 to 11,970 over the library), checks unchanged at 1,337 (Check 4.1 restated), WHYs 0 to 0. The models follow: `Abandon` and `abandonWrites` leave `login.als`, `A_Check_4_1` reads a completion event, the twin `-buggy-abandons-completed` retires (its defect has no state) and `-buggy-initiation-uncompleted` takes its place, so the assertion keeps a twin that breaks it. *Over:* composing Recoverable Invocation for the cascade, which the unit of 2026-11-17 2:45 PM would have done: the cascade is one transaction (Database 1), so no reachable state holds an initiation without its completion and the abandoned arm has nothing to catch (Scott, 2026-11-17 9:19 PM Central, "as recommended", rounds/escalations.md 2026-11-18 03:19Z, item 2). *Because:* a recovery of a state no rule can reach is a rule that restates Database 1. Beacon's Login sweep was rendered with the abandoned arm: the render is not edited (no hand patches) and is rendered again from the changed page when the delta round has cleared, as the Beacon unit says.

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
Deleted: Reconciliation 12. Execution Contract Database 1 owns it: the cascade is one transaction, so no reachable state holds an initiation without its completion and the abandoned arm has nothing to catch (Scott, 2026-11-17 9:19 PM Central, "as recommended", rounds/escalations.md 2026-11-18 03:19Z, item 2: do not compose Recoverable Invocation for the cascade).
Deleted: Reconciliation 16. Execution Contract Database 1 owns it.
Deleted: Reconciliation 17. Execution Contract Database 1 owns it: the cascade is one transaction, so no reachable state holds an initiation without its completion and the abandoned arm has nothing to catch (Scott, 2026-11-17 9:19 PM Central, "as recommended", rounds/escalations.md 2026-11-18 03:19Z, item 2: do not compose Recoverable Invocation for the cascade).
Deleted: Reconciliation 18. Execution Contract Database 1 owns it.
Deleted: Reconciliation 19. Execution Contract Database 1 owns it: the cascade is one transaction, so no reachable state holds an initiation without its completion and the abandoned arm has nothing to catch (Scott, 2026-11-17 9:19 PM Central, "as recommended", rounds/escalations.md 2026-11-18 03:19Z, item 2: do not compose Recoverable Invocation for the cascade).
```

### Composition-level invariants › Invariant 2 — Cascade completeness

```
  Deleted: Invariant 2.3. Action wiring 18 owns it: the cascade set is the union of the credential-to-sessions map's entry and the event-derived set (Term cascade set).
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
Deleted: Wiring decision 4. Invariant 2.2 owns it.
```
