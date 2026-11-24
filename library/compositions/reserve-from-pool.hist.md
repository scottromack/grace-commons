---
title: Reserve from Pool — history
nav_exclude: true
search_exclude: true
---

# Reserve from Pool — history

The dated record of how [Reserve from Pool](./reserve-from-pool.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/reserve-from-pool.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-08-25 — Invariant 5's at-most-once is conditioned on Duplicate Prevention's host obligations.** *Chose:* inherit the constituent's declared failure modes as named host obligations (durable, highly available recorded-set store; fail-closed `check`; `token_results` plus `record` durable before the result returns) and condition Invariant 5 and check 5 on them. *Over:* the unconditional at-most-once claim. *Because:* a silent window miss or a fail-open `check` lets a retried [Reserve] take a second slot, and an obligation-traceable miss is a deployment finding, not a coherence disproof.

- **2026-08-26 — Attribution is an `attest` call committed with the journal entry, keyed per invocation.** *Chose:* every state-changing action opens with `Actor Identity.attest(action_ref = "<action>:<idempotency_token>", …)` and carries the `attestation_id` on every journal schema; at the terminal trios the attestation stands outside and before the atomic trio. *Over:* attribution as prose ("attributed via Actor Identity") with a caller-supplied actor_ref. *Because:* the attribution guarantee was neither buildable nor witnessable as written, a shared `action_ref` would bind the proof to a category of act rather than the act, and an attestation inside the trio could not refuse the act it exists to gate.

- **2026-08-27 — The confirm pair is completed by a late journal write, not made atomic and not compensated.** *Chose:* on a post-commit journal failure at [Confirm Reservation], return `recording-failure(post-commit)`, cache and record the token, and owe the outcome entry as a `recovery = true` write carrying the invocation's own attestation, detected from an unmatched confirm_intended against a Confirmed record. *Over:* extending the terminal trio's hard atomic-commit requirement to the pair. *Because:* the trio is atomic because a lost pool release and a lost record of one cannot be told apart; the confirm pair has no pool call and the constituent store answers the question directly, so a late write is safe and a transaction would buy nothing.

- **2026-08-29 — The slot-returning pair is ordered and reconciled by the pool's count, not made atomic; the sweep is bounded and acts as the composition.** *Chose:* [Cancel Reservation] and [Expire Reservation] run transition → pending marker → pool release → `released(…)` marker → outcome entry, none inside a transaction; a pool reconciliation leg that, under the per-pool serialization, computes the pool's deficit from the journaled live set and releases exactly that many slots, naming candidates where several returns were open at once; every sweep leg bounded below by `reservation_completion_bound` and above by the journal horizon, run as a declared service identity behind recovery_intended; the [Reserve] compensation appended after its release rather than "in one host transaction"; the compensation's constituent arms partitioned; `journal_retention_ordering` and `index_durability` declared, the binding's purged half and the pending markers classified truth-bearing with their atoms named. *Over:* the terminal trio as "one atomic commit, a hard conformance requirement". *Because:* the transition is absorbing, the pool release is an append on the pool's own audit log, and the journal entry is an append — no store declares the rollback the trio required, and a journal entry rolled back after landing was a false record; the ambiguity the trio was meant to remove (a lost release versus a lost record of one) is resolved instead by the second source the stores do supply, the pool's own count against the journal (the frozen rules of 2026-08-29 — *Durability boundaries*, *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*, *A derived index splits at the horizon*).

- **2026-08-30 — One writer per act, the windows keyed on the pool's own events, the retry reading the journal before it delegates, and the obligations the constituents decline declared as the deployment's.** *Chose:* a retry terminus, `outcome_retry_attempts`, after which every post-commit write is the sweep's, with the sweep's runs and the invocation serialized on the deployment's declared `host_exclusion` sections and every look-then-write pre-check re-read under them; the reconciliation's unjournaled-return set keyed per reservation — an intent enters only where no slot-returning outcome names the reservation and the terminal state is the one its action writes, outcome over intent on the rebuild — with one recovery entry per reservation and the rest as `intent_candidates`; Invariant 1's windows and check 1 keyed on allocation events of the pool's audit log, an unmatched `reserve_intended` explaining zero slots; [Reserve] step 2 reading the journal for its token on `not-seen` before it delegates — replay on an outcome, defer on a bare intent — and the sweep caching and recording the deferred tokens; `allocated_before` / `allocated_after` copied from the pool's own allocation or release event through `pool_event_read`, the three-call `query`-`allocate`-`query` section dropped; `journal_durability`, `journal_query_shape`, `pool_event_read` and `host_exclusion` declared as inherited obligations and instance capabilities; `recording-failure(intent | outcome)` and invalid-credential on every signature, the intent position uncached and the outcome position cached; the liveness inequality written out with `recovery_write_latency`; `journal_payload_cap` and `recovery_candidates_cap` sizing the largest record at step 1; and, from the closure check, `host_exclusion` as an instance capability with lease semantics — taken at the invocation's first write, exactly `reservation_completion_bound` long, its expiry the invocation's terminus, every later write made only under it — with the pool call of every action pre-checked under the sections and adopting a landed return or compensation (*proceed as landed*), the sweep taking a reservation's section before counting it, the three other actions reading the journal on `not-seen` as [Reserve] does, replay from a compensation populating no binding, and the tri-state `release` marker (`Projects: release`) written into every sentence that still spoke of a boolean or a trio. *Over:* "retry until it lands" beside a sweep starting at the bound; a leg that paired per reservation and wrote per intent; a divergence window keyed on an intent that had taken nothing; a `not-seen` treated as proof that nothing ran; a critical section, a durability and a query shape attributed to constituents whose own text declines them; a bare token on both sides of the commit; *cadence no longer than the window*; *foreclosed by construction*; a section named in no Configuration entry, with no lease and no terminus, under which a stalled invocation could wake between the sweep's pre-check and its append and release twice. *Because:* two compensators over one act land two outcomes and a second release; a refused cancel against a reservation another token returned is not a return begun; a refused intent never receives an outcome, so a window keyed on it never closes; a crash between the outcome and the `record` leaves a completed reservation the retry would duplicate; Capacity Constraint serializes each call and sends the rest to a Transaction composition, Event Log leaves persistence to the deployment, and a capability the constituent declines is the deployment's to declare or nobody's; a caller who cannot tell intent from outcome re-runs a committed act; and a section that is not a declared capability with a bound on its hold is either an undeclared dependency or an unbounded block on the sweep (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen with its tells for uses — with §*Intents pair with outcomes*' third tell and §*Recovery commits under a declared service identity*'s re-entry tell; *Lawful destruction is answered before absence* and *A stamp from another seam never decides a write alone* were swept and found no shape here — no constituent answers `purged`, and no write rests on a cross-seam comparison).

- **2026-09-23 — Rewritten in GRACE lang v0.61; twenty of twenty-two open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration and Logic confinement both — `Primitive policy`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, the prose's *Cross-store consistency under partial failure* becoming the reconciliation it described; invariant numbers 1 through 6 and 8 unchanged, Invariant 7 tombstoned to Composes 5; the checks renumbered `Check 1.1` through `Check 7.2`; `Non-goals` and `Edge cases` split, with `Clock semantics`, `Concurrency` and `Expiry sweep` under the second; the host's mutual exclusion named an *exclusion*, since the grammar owns *section*; and the outcome entries' balances named for what Capacity Constraint Enforcement's events carry now, the opening and closing balance, where the prose still said *Allocated Before* and *Allocated After*. The lines' fixes: the replay declared a bearer answer that attests and journals nothing, since a replay commits nothing and Invariant 8 is about commitment (2026-08-26-e, 2026-08-30-e); Actor Identity's store durability inherited (2026-08-26-f); *bound cryptographically* replaced by Invariant 8's own mechanism-neutral words (2026-08-26-h); the fail-closed check landed as recording-failure carrying outcome, unsettled (2026-08-26-i); no oversell read at quiescence and from the pool's own acceptance, joining no two logs (2026-08-26-j); *attestation* glossed in the Summary (2026-08-26-k); an Action Reference term entry (2026-08-26-l); the digest's exclusion of the actor reference and the credential as rules (2026-08-26-o); validation pinned before the intent against each constituent's own field rules, uncached, the constituents' invalid-request settled after it (2026-08-26-r, 2026-08-30-f); the Terms preamble's count, the idempotency surface declared here rather than deferred, and the Customer Onboarding pointers removed (2026-08-26-t, u, v); the pool leg releasing never more than the open returns, an excess reported (2026-08-30-a); a release reading of unknown, rebuilt as such, and the recovery entries' balances outside the chain (2026-08-30-b); Provisional Commitment's not-known landed as a third position, inconsistency, settled and alerted (2026-08-30-g); the expiry sweep reading not-known as an orphan hold the reconciliation's partial leg resolves (2026-08-30-h); the seam glossed (2026-08-30-k). *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. The two formal lines stay open (2026-08-29-a, 2026-08-30-l). The rewrite also found the reconciliation's partial leg had no way to reach the orphan hold it was told to drive terminal — the hold is unjournaled — and gave it one: the Held commitments no binding names whose resource and requester match the open partial's intent (Reconciliation 30).

- **2026-10-21 — The store's guarantees cited, not restated, and each action's intent, constituent writes and outcome one transaction.** *Chose:* Capability requirement 47 citing Execution Contract Store 1 through 4 for the store the five constituents, the binding and the token results map keep their records in; to Store 3, the durability of the journal, of the commitment and pool stores held at the journal's, of the binding, the token results map, the recorded set and the attestation store, the answer held until the token results entry and the record are durable, and the auditor's check of the journal's durability (Capability requirement 12 through 14, 30, 32 through 34, 36, 38, External check 5); to Store 2, under which an action's reads and the writes they decide are one transaction, the token, reservation and pool exclusions with their supply, release, lease and expiry, every take of them, the fence on later writes and the re-take after a lost one, the reliance on the pool's per-call serialization for concurrent allocates and the auditor's check of the exclusions (Capability requirement 20 through 26, Action wiring 2 through 4, 33 through 37, Concurrency 3, External check 4); to Store 1, under which an action's writes commit together, its constituents' included, the rule refusing a host transaction, which Store 1 as ruled contradicts (Wiring decision 4), and the machinery that existed only because a crash or a refusal between two of an action's writes could leave a partial: the compensating release and compensation entry for a refused place hold and the replay from one, the hold compensation for a refused reserve outcome entry, the outcome-position settles after a committed half with their stages, the release marker with its pending and released values and the pre-check that read it, the in-invocation retries of a post-commit write with their attempts and the late outcome entries, the adoption of a resolving entry found on a re-take, the whole reconciliation with its service identity, completion bound, compensation window, cadence, write latency, liveness sum, candidates cap, consistent pool read and candidate-set test, the divergence windows it closed, the checks of the windows, the marker and the compensation, and the expiry sweep's reading of an orphan hold (Capability requirement 4 through 11, 16, 18, Composition state 5, 8, 9, 12 through 14, Action wiring 16, 17, 38 through 44, 57 through 60, 65 through 77, 94, 99 through 105, 107 through 109, 112, Wiring decision 5, Reconciliation 1 through 39, Invariant 1.2 through 1.4, Check 1.5, 1.7, 3.2 through 3.8, External check 3, Concurrency 2, Expiry sweep 2, 3). By clause, a binding entry carries its pool id alone, the slot-held reading reads the state alone, a slot is released only for a slot-returning transition, a place hold refusal is settled with no compensation ahead of it, the idempotency claim rests on Duplicate Prevention's store obligations alone, a divergence the rebuild does not close is a coherence finding and the replay chain takes every outcome entry citing a pool event (Composition state 3, Action wiring 61, 118, Wiring decision 6, Invariant 5.4, Check 1.6, 7.1); the binding write loses its marker, and the success settles, the slot release and the slot-returning outcome entry follow the answer each needs rather than a marker or an entry written in an earlier commit (Action wiring 78, 79, 96, 106, 110, 113). Rules 345 to 208. *Over:* a transition, a pool release and a journal entry no transaction could span, ordered and returned exactly once by a release marker and a reconciliation that decided from the pool's own count, a [Reserve] partial compensated in line or by the reconciliation, a confirm pair completed by a late write, and three exclusions the host held as leases whose expiry ended an invocation — the turns of 2026-08-30, 2026-08-29 and 2026-08-27, below. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, that a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal, and that Store 2 covers a guard decided across a lease check, the lease keeping its job only for an act outside the store. Nothing in the reservation arc is an act outside the store: the attestation, the journal entries, the allocate and the pool release, the hold and its transitions, the recorded token and the token results entry are store writes, so each action's intent, constituent writes, outcome and settled answer commit together, and the three exclusions, host mutual exclusions over store-only work, are Store 2's. A place hold refused after the allocate leaves only the reserve intent, the refused attempt's evidence, so no slot is taken for it and none is returned (Action wiring 61), and a pool release refused after the transition leaves the reservation Held; a refused append writes nothing, Duplicate Prevention's record never refuses and a constituent's storage failure fails the whole action, so no answer a kept rule gives reaches a partial and nothing is owed once an action returns. The binding stays a derived index outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps it, so it is still written after the reserve outcome entry and rebuilt on a miss, and its entries past the audit horizon stay truth-bearing (Composition state 4, 10, 11, 15, Action wiring 18, Check 1.2 through 1.4). Order rests on the journal's own sequence numbers (Capability requirement 46), and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.

- **2026-11-05 — A refusal writes nothing; an answer a refusal's constituent decides is settled.** *Chose:* not-known, pool-closed and pool-capacity-exceeded moved to [Reserve]'s answers line, and not-held, window-elapsed and window-not-elapsed to the resolving actions', so each call is admitted and its intent entry and settle commit with it (Execution Contract Read 4; GRACE-lang Watch list, the attempt a refusal erases); resource-unavailable, a place hold refused after the allocate took its slot, kept a refusal that writes nothing, its allocate and its intent included, so it is not settled and a retry under its token runs afresh; the settle of a recording-failure carrying inconsistency retired with it (Action wiring 61, 83); Invariant 5.1 conditioned on a settled answer. *Over:* a refused place hold leaving its reserve intent beside a refusal, which Database 1 forbids, or, were it admitted, committing the allocate with no hold. *Because:* Final Critique 9's Linus pass found the refusal and the settled attempt could not both stand, and the cure the corpus made on three pages could not be made for resource-unavailable without a slot leaking, since the compensating release went at the 2026-10-21 turn below.

- **2026-11-18 — A composition action reads the clock once: Capability requirement 42 and Check 4.2 retire to Execution Contract Logic confinement 19.** *Chose:* Capability requirement 42 (the composition compares no now of its own with a constituent's stamp) and Check 4.2, which rested on it alone (an auditor reports no skew between a confirm outcome entry's now and the hold's expiry instant), leave their `Deleted:` tombstones naming Logic confinement 19 and the ruling, never renumbered or reused. Citations found, by label: Capability requirement 42 (Check 4.2 alone, by `cites.py`); no formal model, twin or coverage row names either, so the formal line stands as written. Capability requirement 39 through 41 (one now per invocation, injected at the seam and stamped on every journal entry) and Check 4.1 (a Confirmed reservation's in-window admission read from the Provisional Commitment record) stand. Rules 2 fewer, one of them a check. *Over:* keeping Check 4.2 as an auditor's tolerance: inside one call no skew remains for it to set aside, since Provisional Commitment's confirm reads the now the outcome entry carries. *Because:* Scott, 2026-11-18 6:52 AM Central, "YYY" (rounds/escalations.md 2026-11-18 12:52Z, item 2, on the measure of 06:09Z): a composition action reads the clock once, and every constituent call it makes takes that reading as its now, from MIT's sync-engine (github.com/mit-sdg/sync-engine), which binds one instant per causal flow. The page takes a delta round.

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-21, newest first:

- 2026-08-26 authentication-precedence gate — 3 foundational routed (all since closed), 4 foundational and 8 refining/rhetorical corrected in-round, 9 refining routed (3 since closed)
- Final Critique 8's 7 refining and 3 rhetorical also routed

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Reserve from Pool](./reserve-from-pool.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 5. Execution Contract Database 1 owns it.
Deleted: Composition state 8. Execution Contract Database 1 owns it.
Deleted: Composition state 9. Execution Contract Database 1 owns it.
Deleted: Composition state 12. Execution Contract Database 1 owns it.
Deleted: Composition state 13. Execution Contract Database 1 owns it.
Deleted: Composition state 14. Execution Contract Database 1 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 4. Execution Contract Database 1 owns it.
Deleted: Capability requirement 5. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Capability requirement 6. Execution Contract Database 1 owns it.
Deleted: Capability requirement 7. Execution Contract Database 1 owns it.
Deleted: Capability requirement 8. Execution Contract Database 1 owns it.
Deleted: Capability requirement 9. Execution Contract Database 1 owns it: the composition names no liveness sum for the compensation window to exceed.
Deleted: Capability requirement 10. Execution Contract Database 1 owns it.
Deleted: Capability requirement 11. Execution Contract Database 1 owns it.
Deleted: Capability requirement 12. Execution Contract Database 3 owns it.
Deleted: Capability requirement 13. Execution Contract Database 3 owns it.
Deleted: Capability requirement 14. Execution Contract Database 3 owns it.
Deleted: Capability requirement 16. Execution Contract Database 1 owns it.
Deleted: Capability requirement 18. Execution Contract Database 1 owns it.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it.
Deleted: Capability requirement 22. Execution Contract Database 2 owns it.
Deleted: Capability requirement 23. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 24. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 25. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to lease.
Deleted: Capability requirement 26. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 30. Execution Contract Database 3 owns it.
Deleted: Capability requirement 32. Execution Contract Database 3 owns it.
Deleted: Capability requirement 33. Execution Contract Database 3 owns it.
Deleted: Capability requirement 34. Execution Contract Database 3 owns it.
Deleted: Capability requirement 36. Execution Contract Database 3 owns it.
Deleted: Capability requirement 38. Execution Contract Database 3 owns it.
Deleted: Capability requirement 39. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 40. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 42. Execution Contract Logic confinement 19 owns it: a composition action reads the clock once and every constituent call it makes takes that reading as its now, so no constituent's stamp the call wrote differs from the composition's now (Scott, 2026-11-18 6:52 AM Central, "YYY", rounds/escalations.md 2026-11-18 12:52Z, item 2).
Deleted: Capability requirement 43. Execution Contract Logic confinement 3 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 2. Execution Contract Database 2 owns it.
Deleted: Action wiring 3. Execution Contract Database 2 owns it.
Deleted: Action wiring 4. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Action wiring 16. Execution Contract Database 1 owns it.
Deleted: Action wiring 17. Execution Contract Database 1 owns it.
Deleted: Action wiring 33. Execution Contract Database 2 owns it.
Deleted: Action wiring 34. Execution Contract Database 2 owns it.
Deleted: Action wiring 35. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion for a later write to hold.
Deleted: Action wiring 36. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to lose.
Deleted: Action wiring 37. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to take again.
Deleted: Action wiring 38. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 39. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 40. Execution Contract Database 1 owns it.
Deleted: Action wiring 41. Execution Contract Database 1 owns it.
Deleted: Action wiring 42. Execution Contract Database 1 owns it.
Deleted: Action wiring 43. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 44. Execution Contract Database 1 owns it.
Deleted: Action wiring 57. Execution Contract Database 1 owns it.
Deleted: Action wiring 58. Execution Contract Database 1 owns it.
Deleted: Action wiring 59. Execution Contract Database 1 owns it.
Deleted: Action wiring 60. Execution Contract Database 1 owns it.
Deleted: Action wiring 61. Execution Contract Read 4 owns it: a place hold refusal refuses [Reserve], which writes nothing, its allocate and its reserve intent included.
Deleted: Action wiring 65. Execution Contract Database 1 owns it.
Deleted: Action wiring 66. Execution Contract Database 1 owns it.
Deleted: Action wiring 67. Execution Contract Database 1 owns it.
Deleted: Action wiring 68. Execution Contract Database 1 owns it.
Deleted: Action wiring 69. Execution Contract Database 1 owns it.
Deleted: Action wiring 70. Execution Contract Database 1 owns it.
Deleted: Action wiring 71. Execution Contract Database 1 owns it.
Deleted: Action wiring 72. Execution Contract Database 1 owns it.
Deleted: Action wiring 73. Execution Contract Database 1 owns it.
Deleted: Action wiring 74. Execution Contract Database 1 owns it.
Deleted: Action wiring 75. Execution Contract Database 1 owns it.
Deleted: Action wiring 76. Execution Contract Database 1 owns it.
Deleted: Action wiring 77. Execution Contract Database 1 owns it.
Deleted: Action wiring 83. Execution Contract Read 4 owns it: a recording-failure carrying inconsistency refuses the action, which writes nothing.
Deleted: Action wiring 94. Execution Contract Database 1 owns it.
Deleted: Action wiring 99. Execution Contract Database 1 owns it.
Deleted: Action wiring 100. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 101. Execution Contract Database 1 owns it.
Deleted: Action wiring 102. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 103. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 104. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 105. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 107. Execution Contract Database 1 owns it.
Deleted: Action wiring 108. Execution Contract Database 1 owns it.
Deleted: Action wiring 109. Execution Contract Database 1 owns it.
Deleted: Action wiring 112. Execution Contract Database 1 owns it.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 4. Execution Contract Database 1 owns it.
Deleted: Wiring decision 5. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 2. Execution Contract Database 1 owns it.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Deleted: Reconciliation 4. Execution Contract Database 1 owns it.
Deleted: Reconciliation 5. Execution Contract Database 1 owns it.
Deleted: Reconciliation 6. Execution Contract Database 1 owns it.
Deleted: Reconciliation 7. Execution Contract Database 1 owns it.
Deleted: Reconciliation 8. Execution Contract Database 1 owns it.
Deleted: Reconciliation 9. Execution Contract Database 1 owns it.
Deleted: Reconciliation 10. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Reconciliation 11. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Reconciliation 12. Execution Contract Database 1 owns it.
Deleted: Reconciliation 13. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Reconciliation 14. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Reconciliation 15. Execution Contract Database 1 owns it.
Deleted: Reconciliation 16. Execution Contract Database 1 owns it.
Deleted: Reconciliation 17. Execution Contract Database 1 owns it.
Deleted: Reconciliation 18. Execution Contract Database 1 owns it.
Deleted: Reconciliation 19. Execution Contract Database 1 owns it.
Deleted: Reconciliation 20. Execution Contract Database 1 owns it.
Deleted: Reconciliation 21. Execution Contract Database 1 owns it.
Deleted: Reconciliation 22. Execution Contract Database 1 owns it.
Deleted: Reconciliation 23. Execution Contract Database 1 owns it.
Deleted: Reconciliation 24. Execution Contract Database 1 owns it.
Deleted: Reconciliation 25. Execution Contract Database 1 owns it.
Deleted: Reconciliation 26. Execution Contract Database 1 owns it.
Deleted: Reconciliation 27. Execution Contract Database 1 owns it.
Deleted: Reconciliation 28. Execution Contract Database 1 owns it.
Deleted: Reconciliation 29. Execution Contract Database 1 owns it.
Deleted: Reconciliation 30. Execution Contract Database 1 owns it.
Deleted: Reconciliation 31. Execution Contract Database 1 owns it.
Deleted: Reconciliation 32. Execution Contract Database 1 owns it.
Deleted: Reconciliation 33. Execution Contract Database 1 owns it.
Deleted: Reconciliation 34. Execution Contract Database 1 owns it.
Deleted: Reconciliation 35. Execution Contract Database 1 owns it.
Deleted: Reconciliation 36. Execution Contract Database 1 owns it.
Deleted: Reconciliation 37. Execution Contract Database 1 owns it.
Deleted: Reconciliation 38. Execution Contract Database 1 owns it.
Deleted: Reconciliation 39. Execution Contract Database 1 and Execution Contract Database 2 own it.
```

### Composition-level invariants › Invariant 1 — Allocation coherence

```
  Deleted: Invariant 1.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 1.3. Execution Contract Database 1 owns it.
  Deleted: Invariant 1.4. Execution Contract Database 1 owns it.
```

### Composition-level invariants › Invariant 8 — Authentication precedes commitment

```
  Deleted: Invariant 7. Composes 5 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.5. Execution Contract Database 1 owns it.
Deleted: Check 1.7. Execution Contract Database 1 owns it.
Deleted: Check 3.2. Execution Contract Database 1 owns it.
Deleted: Check 3.3. Execution Contract Database 1 owns it.
Deleted: Check 3.4. Execution Contract Database 1 owns it.
Deleted: Check 3.5. Execution Contract Database 1 owns it.
Deleted: Check 3.6. Execution Contract Database 1 owns it.
Deleted: Check 3.7. Execution Contract Database 1 owns it.
Deleted: Check 3.8. Execution Contract Database 1 owns it.
Deleted: Check 4.2. Execution Contract Logic confinement 19 owns it: Provisional Commitment's confirm judges the hold's window against the now the confirm outcome entry carries, so no skew stands between that now and the hold's expiry instant for an auditor to set aside (Scott, 2026-11-18 6:52 AM Central, "YYY", rounds/escalations.md 2026-11-18 12:52Z, item 2).
```

### Generation acceptance › External checks

```
Deleted: External check 3. Execution Contract Database 1 owns it.
Deleted: External check 4. Execution Contract Database 2 owns it.
Deleted: External check 5. Execution Contract Database 3 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 2. Execution Contract Database 1 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Edge cases › Expiry sweep

```
Deleted: Expiry sweep 2. Execution Contract Database 1 owns it.
Deleted: Expiry sweep 3. Execution Contract Database 1 owns it.
```
