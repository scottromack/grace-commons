---
title: Idempotent Reservation — history
nav_exclude: true
search_exclude: true
---

# Idempotent Reservation — history

The dated record of how [Idempotent Reservation](./idempotent-reservation.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/idempotent-reservation.md`.

## Decisions

Entries that record a migration, a council read's collapse, where a classification is carried, a family placement or a regeneration rather than a turn the pattern took.

- **2026-08-30 — The intent is written before the act, the writer is one per token, and what cannot be re-derived is not re-run.** *Chose:* a pending entry written to `token_results` before Provisional Commitment is called, with a re-entry arm that — finding it under the token's critical section — names candidate holds for [Place Hold] and re-runs only the resolving actions, whose second call is effect-free by the constituent's single-resolution invariant; `per_token_serialization` declared as an instance capability requirement (released on return or death; a lease exactly `reservation_completion_bound` long whose expiry is the invocation's terminus) and taken by the eviction leg too, so the invocation and the leg never both write one token; the leg bounded at both edges — nothing younger than the bound, eviction only past the window and only for a `not-seen` token; `recording-failure(intent | outcome)` on every signature, the `outcome` position carrying the committed id, and Provisional Commitment's storage-failure, not-known and window-not-elapsed transcribed; Duplicate Prevention's disclaimed durability and its fail-open/fail-closed choice declared as `duplicate_prevention_store`, condition (c) of Invariant 8; `token_results` durability housed in Configuration; the claimed atomicity between the two stores replaced by write order, five reachable partials, and a recovery for each; and, from the closure check the same day, the complete-entry arm guarded by the window on the composition's own stamps (an expired `not-seen` entry evicted in place, so Invariant 7's fresh request does not wait on the leg), `pending_at` kept on the complete entry with `completed_at` beside it, the critical section declared shared across every instance sharing the store, `commitment_store_acknowledged_atomic` transcribing the constituent's own write obligation so that storage-failure is cached as definitive only where it is, and the pending arm's empty-candidates case proceeding as never delegated. *Over:* "persisted atomically with each successful action" as an implementation requirement, an eviction surface that read an in-flight invocation as evictable, a serialization the spec "assumed", and four signatures that told a caller nothing was committed when a commitment existed. *Because:* the constituent's record carries no token, so a crash between the act and its record leaves an outcome no retry can re-derive — and a retry that re-delegates is the double this composition exists to prevent; two writers over one token land two results; and a caller who cannot tell intent from `outcome` re-runs a committed act (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen — with the section titled *A reconciliation is bounded at both ends* in `pressure-testing.md` and the section titled *Recovery commits under a declared service identity* in `pressure-testing.md` of 2026-08-29).

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except two invariants the Execution Contract already owns.** *Chose:* `Composes`, `Composition state`, `Eviction`, `Capability requirement`, `Primitive policy`, `Action wiring`, `Wiring decision` and `Indeterminate outcome` as the surfaces, the six surviving invariant numbers unchanged, and the acceptance section's own two tiers carried across. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. `Eviction` is the one family minted here and it is minted for a reason no other composition has had: the eviction leg is the only leg in the corpus that runs *outside* an invocation, with its own two edges and its own exclusion against the invocations it runs beside, and folding nine rules about a background sweep into `Composition state` would have buried the one surface a reader most needs to find. One spec, flagged, waiting on recurrence (Principle 1 through 3, council read 57's promotion path).

- **2026-09-14 — Two preservation claims are one citation, third instance.** *Chose:* `Composes 5`, with `Invariant 5` and `Invariant 6` tombstoned to it. *Over:* keeping them. *Because:* council read 53's ruling, now applied at its third seam. What they carried beyond the blanket survives as `Composes 6` (the unchanged relay of a constituent rejection, which no atom guarantees about a caller) and `Composes 7` (the once-per-first-invocation `record` discipline, which is this composition's call pattern rather than a property of [Duplicate Prevention](../atoms/duplicate-prevention.md)).

- **2026-09-14 — The extraction-pending element is carried as a rule surface, not softened.** *Chose:* to state the `token_results` map as nine `Composition state` rules with the classification named in the WHY, the proposed atom named, and `Capability requirement 12` through `Capability requirement 14` carrying its durability. *Over:* describing it in prose, as every other composition's state section does — because every other composition's state section had nothing to describe. *Because:* this is the corpus's first migrated composition carrying truth no replay of its constituents reproduces, and the section titled Composition state in `execution-contract.md` says an unflagged truth-bearing composition store is a conformance finding while a flagged one is scheduled debt. The flag is the whole difference, so it belongs on the rule surface where an instrument can find it rather than in a paragraph (council read 58).

- **2026-09-14 — `Eviction` re-cut as `Housekeeping`, joining the leg it was kept apart from.** *Chose:* the family renamed, with the nine rules and every citation of them moving with it. *Over:* keeping a one-spec family named for what this leg happens to do. *Because:* the entry above kept `Eviction` apart from [Authenticated Actor](./authenticated-actor.md)'s `Reconciliation` on *one evicts and one reports*, and the drift pass found that axis wrong — it predicts the liveness bound on two of four legs, and this leg is one of the two it misses, because it takes a critical section and writes to the composition's own store while owing nothing. What decides the bound across all four is whether anything **awaits** the leg's output. Nothing awaits an eviction and nothing awaits an orphan report, so the two are one family; [Login](./login.md)'s and [Defensible Retention](./defensible-retention.md)'s sweeps discharge a promise and are the other. `Housekeeping 7` and `Housekeeping 8` keep their reading unchanged — they are still why this leg owes no liveness bound, and now the family name says so too (council read 64).

- **2026-09-28 — What the rewrite dropped from the re-entry arms, restored.** *Chose:* the collision check over a pending entry as well as a complete one (Action wiring 7, 8); the guard recorded for every result that lands, a re-entry's included (Action wiring 25); a resolving action run again on a seen token carrying no entry, with outcome-unknown kept for [Place Hold] (Indeterminate outcome 10, 13, Wiring decision 4); a resolving action's candidates named (Indeterminate outcome 14); the window strictly longer than the completion bound (Capability requirement 10); and Composition state 8, which conditioned on a returned invocation the map cannot show, tombstoned to Housekeeping 5. *Over:* the 2026-09-14 rewrite's reading, which its Decisions entry called language only. *Because:* the prose spec it replaced decided each of these, and the cold regeneration of 2026-09-28 met every one.

- **2026-10-20 — The store's guarantees cited, not restated, the pending intent and the per-token critical section among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 18), and the forty-four rules that restated it, or existed only for a store that could lose, split or forget a write, tombstoned to their owner — to Store 1, under which a state-changing action's entry, Provisional Commitment's write and Duplicate Prevention's record commit together: the pending entry written before the constituent call and overwritten after it, with the pending instant kept across the overwrite and its check (Composition state 4, 5, 7, Action wiring 13, Check 3.2), the recording failure at the intent, the result write's retry within the reservation completion bound, the recording failure at the outcome with the answer it carried, the caller's bar on a fresh token after it and the bar on recording one (Action wiring 14, 17 through 19, Indeterminate outcome 12, Wiring decision 5), the result written before the guard and the guard recorded again beside a complete entry (Action wiring 20, 11), the pending arm — an act that may have happened, no second delegation, empty candidates proceeding, the outcome-unknown overwrite, the resolving re-run — with the check of outcome-unknown entries (Indeterminate outcome 1, 2, 5, 6, 9, Check 5.2), the eviction leg's lower edge (Housekeeping 3) and the disclaimer of atomicity across the token results map and the commitment store (Non-goal 6); to Store 1 and Store 2, the reservation completion bound and the window's margin over it (Capability requirement 9 through 11); to Store 2, under which an action's reads of a token and the writes they decide are one transaction, the host's critical section per token with its supply, release, lapse and holding rules, the eviction leg's take and skip, and its external check (Capability requirement 5 through 8, Action wiring 2 through 6, Housekeeping 1, 2, External check 1); to Store 3, the durability across a restart of the token results map and of Duplicate Prevention's recorded set, the acknowledgement only after a write is durable, the commitment store's declared atomic acknowledgement and the external checks of the first and the last (Capability requirement 12, 14, 15, 17, External check 2, 4), with the resolving action's outcome-unknown, which only a commitment store that did not acknowledge atomically reached (Indeterminate outcome 14); and to Store 3 and Store 4, an entry kept for its durability term (Capability requirement 13). With them every signature loses recording-failure and the resolving actions lose outcome-unknown, Invariant 8.1 conditions the exactly-once claim on Duplicate Prevention's store obligations alone, and External check 5 reads External check 3 alone; rules 139 to 96. *Over:* a pending intent written to `token_results` before the act, a host-supplied critical section per token released on return or death with a lease as the invocation's terminus, a write order across two stores with a recovery for each reachable partial, and a re-entry arm naming candidates for an act no record could pair — the turn of 2026-08-30, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included: the token results map, Provisional Commitment's commitment and Duplicate Prevention's recorded set are one store, so an action's entry, its act and its guard commit together or not at all, no reader sees a pending entry, and a storage failure anywhere in the action commits nothing and answers storage-failure. Store 2 reads the state an action's guards decide on inside the transaction that writes the action's effects, an absent entry included, so a second call carrying one token reads what the first committed and replays it; the maintainer ruled 2026-10-20 that it covers a guard decided across a lease check whose grant lives in the one store, the lease keeping its job only for an act outside the store, and nothing in an invocation is an act outside the store: the critical section kept a second call off the first one's writes, and every one of them is a store write — the entry, Provisional Commitment's commitment and Duplicate Prevention's record — while the registry's own section over the availability read stays Provisional Commitment's (its Capability requirement 3 through 5). The other calls a rule decided: the rewrite asks of every census line written before the ruling of 2026-10-20 02:03Z whether a kept answer still reaches the partial it served, and none does here, since Provisional Commitment's refusals write nothing and are recorded with the entry and the guard, and Duplicate Prevention's record never refuses; the arm for a token Duplicate Prevention reports seen with no entry stays (Indeterminate outcome 10, 13, Wiring decision 4), since Duplicate Prevention's fail-closed answer for an unavailable store still reaches it (Capability requirement 16), and with it the candidates, their carriage and the recovered entry's mark (Indeterminate outcome 3, 4, 7, 8, Check 5.1); the empty-candidates case belongs to the pending arm, as the turn of 2026-08-30 says, and goes with it; a code no kept rule answers leaves its signature; and no rule reads a record as it stood at a past commit or compares two commits, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is otherwise unchanged.

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
