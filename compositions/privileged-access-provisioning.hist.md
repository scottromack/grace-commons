---
title: Privileged Access Provisioning — history
nav_exclude: true
search_exclude: true
---

# Privileged Access Provisioning — history

The dated record of how [Privileged Access Provisioning](./privileged-access-provisioning.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/privileged-access-provisioning.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-08-25 — Every Composition-state element is a derived index over the substrate audit log and the Capability instance's composed scope.** *Chose:* no bearer material on any record surface, every index rebuildable from the trail and the token's scope, a named recovery discipline. *Over:* composition-owned stores carrying request and access truth of their own. *Because:* the records-alone control claim — every privileged token traces to an approved request — is only as strong as the evidence that outlives the composition's own state.

- **2026-08-26 — The `requests:withdraw` scope and third-party withdrawal are dropped.** *Chose:* remove the scope, its term entry and registry entry, and name the administrative alternatives. *Over:* keeping a promise the wiring could not honor. *Because:* the substrate's chain withdrawal is initiator-only and the composition actor is not the initiator, so no honest wiring existed for the path.

- **2026-08-28 — The live provisioning guard is the sweep's detector, and every crash window around the evaluation has a leg.** *Chose:* [Approve Step] step 5 fires the cascade on the same conjunction the sweep's second leg tests (non-terminal ∧ no token for the request ∧ no open provisioning-failed entry), a not-pending from the substrate still runs the evaluation, a terminal-chain leg closes a request whose decision died before evaluating, exercise entries are marked `redeemed` inside the hold, and a failed evaluation opens an entry and still returns approved. *Over:* a guard on the request-state read, and a reconciliation that compared the redemption counter against events alone. *Because:* the `Approved` transient rebuilds to `Pending`, so the state read alone allocated a second token after a crash; the reconciliation read two open entries — a shape the page admitted — as a conformance finding; and a decision that died between commit and evaluation left its request `Pending` forever.

- **2026-08-29 — The sweep pre-checks the trail, is bounded where it runs outside the hold, writes as the composition behind a recovery record, and the truth-bearing state is named.** *Chose:* every sweep leg detects on rebuilt state and the absence of the event, paired by a seam-injected `invocation_id` on every event and entry; the redemption-reconciliation leg examines no entry younger than a declared `recording_completion_bound`; every sweep write is attested under the service identity behind an access_recovery_intended record; the open `audit_pending` payloads are declared truth-bearing, extraction-pending against Outbox, and the store's never-delete rule and the dedicated Capability instance's purge exemption are declared as `store_durability`. *Over:* legs that detected on an index and re-ran a non-idempotent `record_action`, an exercise leg with no lower edge over a window the serialization does not cover, and "all six elements are derived indexes" over state the page itself called truth-bearing. *Because:* a stale index with the event already landed re-emitted duplicates; an entry marked `redeemed` seconds ago belongs to an invocation about to write; a compensation the absent actor did not make cannot be attested as theirs; and a record owed for a committed act that exists in no constituent is not a cache (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*, *Recovery commits under a declared service identity*, *A derived index splits at the horizon*).

- **2026-09-23 — Rewritten in GRACE lang v0.61; forty-four of forty-five open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration and Logic confinement both — `Primitive policy`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with `Provisioning cascade` and `Scope vocabulary` kept as the page's own; the prose's Behavior section distributed to the rules that own each claim; invariant numbers 1 through 10 unchanged; the checks renumbered `Check 1.1` through `Check 6.5`; `Non-goals` and `Edge cases` split, with `Clock semantics`, `Concurrency`, `Expiry` and `Multi-use capabilities` under the second. The choices the lines left open, made by standing rules: the credential checked before the request is resolved, closing the unauthenticated existence oracle and declaring the authenticated residual (2026-08-28-j); the exercise ordered before its provisioning event declared lawful rather than gated, since a delivered token is lawful access (2026-08-28-h); the session check stated existentially, since the record names the principal and no session identifier (2026-08-28-m); the decision event and the credential check kept, with what each adds stated — the request-keyed record and the second registry (2026-08-28-n); the one-credential-two-registries assumption declared (2026-08-28-a); the blank-reason denial's entry closed by a recovery record carrying the reason, or by the horizon (2026-08-28-c); a chain found under a request already Withdrawn closed and reported, not recorded (2026-08-27-p); the substrate's refusals over a possibly committed decision routed to an evaluation entry (2026-08-26-b); a read_chain refusal inside the evaluation answered with the decision and an evaluation entry (2026-08-26-a); the token's deadline restated as Capability's reading plus the remaining ttl, since allocate takes a duration (2026-08-27-j). The rest took their prescribed fixes — the terminal-event walk from the tail, read_record's real arms, the chain shape validated at intake, the token resolved by Capability's read on the token with redeem not called on a miss, the credential second in every signature, the third Permissions call site, the cascading-revocation qualifier carried, Provisioned advancing to Revoked, the provisioning event carrying the redemption count and the expiry instant, the chain-less skip, the counts, the examples' quorum vocabulary, material and Assignment attribution. *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. The model line stays open (2026-08-29-a).

- **2026-10-21 — The store's guarantees cited, not restated, the per-request exclusion among them.** *Chose:* Capability requirement 32 citing Execution Contract Store 1 through 4 for the store the request records and the constituents' records share; to Store 2, under which an action's guard reads and the writes they decide are one transaction, the per-request exclusion the host supplied and released on the holder's return and death, every rule holding it — a pending entry's open and close, the chain evaluation, the provisioning cascade, the reconciliation's legs and a revocation's state write — and the bars on [Read Request] taking it and on an exercise holding it across its record write (Capability requirement 20 through 22, Composition state 33, 34, Action wiring 42, Reconciliation 3, Provisioning cascade 1, Concurrency 1 through 3); to Store 1, under which an action's writes commit together, its constituents' included, the request record written ahead of initiate chain and the request id held back until the chain id landed (Action wiring 14, 30), the exercise entry written ahead of redeem (Action wiring 83), the redemption leg's lower edge with the recording completion bound it read (Reconciliation 9, Capability requirement 11), the redemption gap's attribution of an unmarked exercise entry (Reconciliation 25 through 28), the token leg (Reconciliation 17 through 20) and the initiation leg's repair of a Pending request with no chain id (Reconciliation 31, 34); to Store 3, the Capability instance's durability held at the request store's (Capability requirement 12); and to Store 3 and Store 4, the rebuild of a missing request record and the not-known it preceded (Composition state 15, Action wiring 4). By clause, the chain id's write, the withdrawal's chain call, the redeem and the redeemed mark no longer name the exclusion (Action wiring 17, 63, 85, 86), and the request event follows initiate chain's chain id rather than the chain id's landing on the record (Action wiring 27). Rules 349 to 321. *Over:* a host exclusion on each request held across every evaluation, cascade, withdrawal, exercise, revocation and leg; a request record and an exercise entry written ahead of the act they bracket; and a reconciliation bounded below that finished or attributed what a crash between two writes of one action left — the turns of 2026-08-28 and 2026-08-29, below. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, that a refused attempt a page keeps as evidence stays a domain choice, and that Store 2 covers a guard decided across a lease check, the lease keeping its job for an act outside the store. Every write here but the token's delivery is a store write, the cascade's included, so no crash leaves half an action for a leg to find, and the delivery decides nothing the exclusion held: the cascade fires once because Store 2 reads its guard inside the transaction that allocates. What the page does for its domain is unchanged. The initiation, exercise and provisioning-failure entries stay as the carriers of a record Audit Trail refuses: the initiation-failed withdrawal event, the failed exercise event and a provisioning-failure event the approval leg or a withdrawal fires follow no committed act, so Action wiring 7 opens no entry for them. With them stay the arms those refusals still reach — the initiation entry's completion and close (Action wiring 18, 21, 28), and the initiation leg's search by subject reference, its landing of a refused withdrawal event and its handling of a chain under a Withdrawn request (Reconciliation 30, 33, 35 through 37) — and a failed index write still leaves an action's answer standing, the maps standing outside every action's transaction (Action wiring 9).

- **2026-11-18 — A composition action reads the clock once: Capability requirement 28 retires to Execution Contract Logic confinement 19, and the operating skew is left to two calls' clocks.** *Chose:* Capability requirement 28 (the composition compares no now of its own with a constituent's stamp) leaves its `Deleted:` tombstone naming Logic confinement 19 and the ruling, never renumbered or reused. Citations found, by label: Capability requirement 28 (Check 2.2 and Check 3.2, by `cites.py`); Term operating skew (Check 2.2, 3.2); the walkthrough's provisioning step (Capability requirement 26, the token's window ending within the seam skew of the request's); no formal model, twin or coverage row names Capability requirement 28, so the formal line stands as written. Check 2.2 and Check 3.2 keep their subject and cite the invariant each reads the evidence of (Invariant 3.1, Invariant 6.1, as Check 2.1 and 3.1 do) with Execution Contract Logic confinement 7 in its place: an exercise event's or a decision event's instant is still set against a Session or Credential record stamped by another call, on its own clock, so a discrepancy narrower than the skew between two calls' clocks stays inconclusive. Term operating skew says so: the bound between the clock of this composition's call and the clock of another call that stamped a constituent's record, inside one call every constituent reading the composition's now. The walkthrough's token now ends where the request does, Capability's allocate reading the cascade's one now (Capability requirement 26). Capability requirement 23 through 27 (one now per invocation, the expiry instant and the remaining ttl from it) stand. Rules 1 fewer. *Over:* retiring Check 2.2 and Check 3.2 with the rule they cited: their comparison reaches records another call stamped, which one reading per call does not make equal. *Because:* Scott, 2026-11-18 6:52 AM Central, "YYY" (rounds/escalations.md 2026-11-18 12:52Z, item 2, on the measure of 06:09Z): a composition action reads the clock once, and every constituent call it makes takes that reading as its now, from MIT's sync-engine (github.com/mit-sdg/sync-engine), which binds one instant per causal flow. The page takes a delta round.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Privileged Access Provisioning](./privileged-access-provisioning.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 15. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Composition state 33. Execution Contract Database 2 owns it.
Deleted: Composition state 34. Execution Contract Database 2 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 11. Execution Contract Database 1 owns it.
Deleted: Capability requirement 12. Execution Contract Database 3 owns it.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it: an action's reads of a request and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 22. Execution Contract Database 2 owns it: an action's reads of a request and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 28. Execution Contract Logic confinement 19 owns it: a composition action reads the clock once and every constituent call it makes takes that reading as its now, so no constituent's stamp the call wrote differs from the composition's now (Scott, 2026-11-18 6:52 AM Central, "YYY", rounds/escalations.md 2026-11-18 12:52Z, item 2).
```

### Composition logic › Action wiring

```
Deleted: Action wiring 4. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Action wiring 14. Execution Contract Database 1 owns it.
Deleted: Action wiring 30. Execution Contract Database 1 owns it.
Deleted: Action wiring 42. Execution Contract Database 2 owns it.
Deleted: Action wiring 83. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 3. Execution Contract Database 2 owns it.
Deleted: Reconciliation 7. Composition state 31 owns it: every pending entry carries an invocation id, so no entry is paired by its payload fields.
Deleted: Reconciliation 8. Composition state 31 owns it.
Deleted: Reconciliation 9. Execution Contract Database 1 owns it.
Deleted: Reconciliation 17. Execution Contract Database 1 owns it.
Deleted: Reconciliation 18. Execution Contract Database 1 owns it.
Deleted: Reconciliation 19. Execution Contract Database 1 owns it.
Deleted: Reconciliation 20. Execution Contract Database 1 owns it.
Deleted: Reconciliation 25. Execution Contract Database 1 owns it.
Deleted: Reconciliation 26. Execution Contract Database 1 owns it.
Deleted: Reconciliation 27. Execution Contract Database 1 owns it.
Deleted: Reconciliation 28. Execution Contract Database 1 owns it.
Deleted: Reconciliation 31. Execution Contract Database 1 owns it.
Deleted: Reconciliation 34. Execution Contract Database 1 owns it.
```

### Composition logic › Provisioning cascade

```
Deleted: Provisioning cascade 1. Execution Contract Database 2 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it: an action's reads of a request and the writes they decide are one transaction, and the composition names no exclusion for [Read Request] to take.
Deleted: Concurrency 3. Execution Contract Database 2 owns it: an action's reads of a request and the writes they decide are one transaction, and the composition names no exclusion for an exercise's record write to run outside.
```
