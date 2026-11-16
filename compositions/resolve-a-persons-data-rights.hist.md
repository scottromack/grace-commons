---
title: Resolve a Person's Data Rights — history
nav_exclude: true
search_exclude: true
---

# Resolve a Person's Data Rights — history

The dated record of how [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/resolve-a-persons-data-rights.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-08-26 — The erasure intent record carries a `purge_plan`, and authentication is not inherited across the substrate boundary.** *Chose:* the plan names the retentions a rights fulfillment will attempt, so a purge occasioned by an authorized fulfillment is distinguishable in the shared Audit Trail from a direct call that bypassed the rights process; Defensible Retention verifies the same credential independently at its own boundary. *Over:* treating the outer authentication as covering the nested purges. *Because:* the substrate's surface is independently callable, so what the plan records is provenance, not authority.

- **2026-08-27 — Invariant 1 is safety plus liveness, in three arms.** *Chose:* no `dsar.*_fulfilled` event without its response-disclosure and complete disposition set (earned by write order); no unsurfaced orphan; every orphan compensated within a declared window and distinguishable via `cascade_recovery = true`. *Over:* "commits together or not at all" across a write the substrate cannot withdraw. *Because:* the order was right from the first draft and the claim was merely unprovable — the restatement says what the order earns and nothing more.

- **2026-08-29 — The scan is bounded at both edges and records its intent before it seals or writes.** *Chose:* `fulfillment_completion_bound` below and the audit horizon above for the reconciliation scan; a `dsar.recovery_intended` record before direction 2's cases (i) and (ii); the pairing stated as exact by the Committing gate. *Over:* a scan on `reconciliation_cadence` alone. *Because:* a Committing request seconds old belongs to an invocation about to seal, and case (ii) would write a second response-disclosure beside the one it is about to bind; a seal the scan writes with no record of its own is indistinguishable from a direct call (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*).

- **2026-08-29 — The accounting stores leave the universe, a request can be Committing, and the scan compensates only what reached the bind.** *Chose:* the Selective Disclosure and Consent stores are response content retained as a class, not dispositioned records; a Committing state (intent with no closing event) that both fulfillment actions refuse with compensation-pending; scan step 2 resolved by whether a response-disclosure exists (compensate), records were destroyed (complete), or nothing committed (abandon); `purge_record`'s shared tokens disambiguated by one destruction-safe re-invocation; `retained(retention-obligation)` grounded in the Retention Window record; findings recorded as `dsar.finding_opened` / `dsar.finding_closed` events under a declared service identity. *Over:* a universe the branches could not disposition, a two-state lifecycle, unconditional compensation, categorical token readings, an event the substrate never emits, and a dashboard nothing declared. *Because:* the page's own walkthroughs violated Invariant 2; a retry after a post-commit failure re-ran the fulfillment; the recovery path produced the reverse orphan the safety half forbids; and check 4 failed every conforming implementation.

- **2026-09-24 — Rewritten in GRACE lang v0.61; thirty-three of thirty-four open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration and Logic confinement whole — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with the verdict ladder as its own `Disposition` family; invariant numbers 1 through 8 unchanged, Invariant 9 tombstoned to Composes 6; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and six Edge cases families. Choices the page left open, each decided by a standing rule: the anomaly admitted as a fifth verdict with a finding, terminal for the fulfillment (2026-08-26-g — *as simple as possible without losing fidelity*: a request held open over a record the substrate or the host must settle first answers nothing sooner); access failing closed to an anomaly on a determination error (2026-08-26-h — the same rule the erasure ladder already kept); the recipients and consent limbs sealed as the ids read rather than a digest that diverges by construction (2026-08-26-m); invalid-credential answered as itself at intake (2026-08-26-f, 2026-08-29-b — *make all things mean one thing*); the regulatory reference taken per request (2026-08-29-g — fidelity, since one deployment answers GDPR and CCPA requests alike); the gate's answers mapped by Defensible Retention's own positioned taxonomy, with one destruction-safe re-invocation for the three answers that say nothing about the record (2026-08-26-i, 2026-08-26-j); and an unconfirmable pairing recorded as such in the reason rather than reached through the Retention Window (2026-08-26-r, 2026-08-29-e — *generalize nothing*). One defect found in the pass and fixed in it: the retention-step arm at a pre-effect record was unlanded, so an appended intent answered as retryable left the caller's retry refused compensation-pending. *Over:* the prose's step lists, a closed vocabulary with a fifth member used outside it, and a seal no one could recompute. *Because:* the rules state each landing once and the fork between the siblings once; the formal line stays open because the model, not the page, is what it owes.

- **2026-10-05 — The closing round: one instance for each store it writes, the alert ahead of the take, and a floor that leaves the alert its window.** *Chose:* no two instances of the composition over one Defensible Retention instance or one Selective Disclosure instance (Capability requirement 52, 53); the audit retention policy unchanged for the life of the instance (Capability requirement 54); the overdue alert raised from the run's enumeration ahead of any take, and a run that cannot enumerate alerting on that (Reconciliation 33, 34); an alert floor of two windows, two cadences and five allowances, so the alert has a window to be answered in and a run follows the answer (Term alert floor); a purge attributed to a plan only inside the plan's span (Check 6.3, 6.4, Term plan span); a re-enumerated record of a source registered later read as outside the universe (Check 2.7); verification left to Audit Trail's own acceptance (Check 1.1). *Over:* two reconciliations each reading the other's intents on one trail, an alert a held section could postpone until the intent aged, a floor that alerted and aged within the same minute, an attribution with no upper edge, and a check that convicted an access for a source that did not yet exist. *Because:* Defensible Retention's re-grounding the same day found the instance sharing, the alert under the section and the horizon read from a changed policy on its own page, and each stood here too (the batch rule — reference first, then swept, one closing round); the rest is what that round's nine reader runs found on the way to one clean text. Not swept: Defensible Retention's stand-in, which closes a race a leg's own duration opens at the horizon — here the worst it leaves is a second abandonment of an intent truly abandoned, a safe state, routed as line 2026-10-05-u.

- **2026-10-05 — One request, one writer at a time; a leg seals what the stores show; a gate's answers are read together; findings became alerts.** *Chose:* the request section, a Lease on the request id, over every fulfillment and every leg, an invocation id on every record, and no audit write issued twice; the request's state read from the trail, the durable fulfillment entry and the response disclosure, which never ages; the reconciliation closing an intent by what could have committed — compensate, complete, and abandon only where nothing was planned — and sealing from the stores, remembering nothing; every answer of the gate, the stores and the host read through a declared reading that takes exactly one value, a storage-failure never taken back by a later refusal; every pairing confirmed against Retention Window's own read, a host-managed record's included; the largest record sized whole before the intent, with no digest and no truncation; one audit retention policy for every event the composition records; alerts on a declared surface where finding events had no closer. Each decided by a standing rule: *make all things mean one thing* (the readings, one horizon, section-unavailable as the substrate means it); *as simple as possible without losing fidelity* (alerts for findings, a universe the cap cannot carry refused rather than digested, an unreadable trail answered state-unavailable); *generalize nothing* (Consent asked with no at time, so no reading of this seam's decides an erasure). *Over:* a serialization nothing held, a terminus an invocation that reads the clock once could not observe, a retry after a step-3 refusal, a precedence stated in a WHY, a pairing confirmed against a listing of what is already destroyable, a leg that abandoned a destruction no store shows, and a digest no compensation could seal. *Because:* Defensible Retention's re-grounding moved its purge's answers and what its storage-failure means, and the gate that followed showed every look-then-write on this page resting on a second writer not arriving.

- **2026-10-06 — A round that did not close: what was planned outlives the horizon, both edges read the log's stamp, and an alerted gap is an open obligation.** *Chose:* a stall mark on the request entry for an overdue intent that planned a destruction, written by the run ahead of any take and kept for the life of the instance, so the request reads Committing where the intent has aged out unclosed (Composition state 26, 27; Reconciliation 38, 39); Defensible Retention's stand-in, so a destroyed event later in the log than an intent is read as its possible closing record and no clock decides the horizon edge alone (Term stand-in, Term open intent, Check 8.11, 8.12); young and overdue read on the log's recording instant of the intent, the one instant written under the grant, and never on the now the invocation stamped ahead of its take; a bound for each thing a run does ahead of its legs — alerts, index entries, marks — with a run that fails a write, cannot read the trail or dies mid-enumeration alerted on and read by an auditor as an open obligation (Term alert bound, Term entry bound, Reconciliation 35, 36, 40; Check 1.5, 1.6, 8.7 through 8.10, 8.13); the auditor's horizon edge one allowance wider than the run's (Term horizon event); the cadence start to start (Reconciliation 37); the closure floor counting the leg's take; no retention bound on the two accounting stores (Capability requirement 60, 61); a refusal for each of a missing entry, a failed state read and a read state, with no two obliged at once (Action wiring 4, 34, 35, 38); the hold guarantee claimed only for a fulfillment whose retention read follows the placement (Host-managed records 3); and a named receiver for a record sealed unsettled (Disposition 48). *Over:* an erasure that aged out unclosed and was fulfilled a second time without the records the first destroyed; edges read off a now a stalled host had stamped; checks that convicted a conforming deployment inside a cadence, across an alerted outage or at an aged event not yet destroyed; and a promise that the disclosure never ages, which no rule obliged of the deployment. *Because:* thirteen fresh-reader passes found sixteen foundational findings and each was cured in the pass that found it. Eleven sat in the recovery protocol this page restates beside Defensible Retention (line 2026-10-05-p), and at least five were lines the Ledger already carried as refining, which a reader forbidden the Ledger finds again. No three passes read one text, so the page is `partially resolved` and the text as it stands is owed a round. The eighteen models are unchanged and pass: they read the request section and none of the reconciliation's edges, bounds, marks or the horizon.

- **2026-10-07 — What the Ledger carried as owned is now said in the body, and a run records that it ended.** *Chose:* fifteen open Ledger lines cured or stated where a reader meets them — the answer to an alert as a requirement of the deployment and the alert as a kept record (Capability requirement 62, 63); a stall mark never cleared (Composition state 28); the read a not-known obliges as a rule, and the two departures from Defensible Retention's caller rules declared as such (Action wiring 42); an included disposition carrying no-bar; the basis reading in first-that-holds order; one order of refusals ahead of the intent; the limits of the nesting attribution, of a recovered close's pairing and of the host delete's window stated as limits — and a run recording the end of its enumeration on the alerting surface, so an auditor can tell a lost run from the run that followed it (Reconciliation 41, Term lost run, Check 8.13, 8.14). *Over:* ownership arguments filed in a Ledger the cold reader is forbidden, where each cost a pass to find again, and a check that asked an auditor which run was latest with no record to tell by. *Because:* the one pass run after the drain returned half the refining reports of the passes before it, and its one foundational finding sat in the run-alert check written that morning. Twelve of seventeen findings across fourteen passes are in the recovery protocol this page restates; the page stays `partially resolved`, and the next move is to bind it to Recoverable Invocation and delete what it then cites, with the three passes after.

- **2026-10-21 — A state-unavailable answer writes nothing, as the Execution Contract says; the state read keeps its own failure.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 64, Execution Contract Read 1 through 3) and the rule that restated Read 3 deleted to it (Composition state 23: an action answering state-unavailable records no event); rules 369 to 368. *Over:* the page stating for itself that a state-unavailable answer records nothing. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once. Composition state 22 stays, the page's own answer: its state read fails only where no fulfillment entry or fulfilled event already read settles the request as Fulfilled (Term state read), where Read 1 alone would answer state-unavailable for any failed read; and a failed disclosure or Consent read of an enumerated access still answers incomplete-enumeration (Action wiring 37), a constituent's answer this composition renames.

- **2026-10-21 — The store's guarantees cited, not restated, and a store write's lease check and its commit one transaction; the compensation kept for what Audit Trail still refuses.** *Chose:* Capability requirement 64 citing Execution Contract Store 1 through 4 for the store the constituents and the two indexes keep their records in; to Store 3 and Store 4, the indexes kept for the life of the instance (Capability requirement 50); to Store 1, under which an action's writes commit together, its constituents' included, the order that put the fulfilled event after the response disclosure, which the event's own obligations already rest on (Wiring decision 3), and the reading of Audit Trail's recording-failure carrying step-4 as a landed record, an answer Audit Trail's rewrite left committing nothing or with its reply lost (Audit arm 1, with the tombstones of Audit arm 3, 5 and 12 that named it); to Store 2, under which a store write's lease check and its commit are one transaction, the request section held over an audit write that answered a step-3 refusal (Concurrency 20), so the section is held over a planned call in flight alone and released once every call has answered (Term call in flight, Concurrency 22 through 24, External check 11). Kept against the census: the request index and the fulfillment index stay derived indexes outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps them, each entry written after its event, rebuilt on a miss and backfilled by the reconciliation (Composition state 4, 9, 13, 20, 21, 25, Reconciliation 18, 25, 35, 36, Check 1.5, 1.6); the binding orphan and its compensation, since Audit Trail's refusal of a fulfilled event — an invalid-request below step-4, a reply lost, an invalid-credential after the operator's registration changed — still leaves the response disclosure committed and the event owed (Composition state 24, Reconciliation 8, 12, 32, Invariant 1.4, Check 6.8); and the abandonment of an intent with nothing planned, which a disclosure write that never answered, or a grant spent after the intent, still leaves (Reconciliation 15). The erasure keeps its intent, its outcome, its reconciliation with both edges and the request section with its sizes: Defensible Retention's purge and the host delete are acts outside the store, and the lease keeps its job for them. Rules 372 to 369. *Over:* a disclosure and a fulfilled event no transaction could span, ordered so the event came last — the turn of 2026-08-27, below — and a section held past every answer over an append that might land after its holder's grant. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, that a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal, and that Store 2 covers a guard decided across a lease check, the lease keeping its job for the act outside the store. An access, an erasure with empty plans, an erasure's disclosure and fulfilled event, and a leg's recovery intent, disclosure and event are each the store writes of one action, so no crash leaves half of them; what still reaches a half is a refusal the page keeps as evidence. A request's events are ordered by Event Log's own sequence numbers (Clock semantics 1), and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-21, newest first:

- 2026-10-06: thirteen passes, 16 foundational, each cured in its pass

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 23. Execution Contract Read 3 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 14. Capability requirement 37 owns it.
Deleted: Capability requirement 15. Capability requirement 37 owns it.
Deleted: Capability requirement 19. Capability requirement 39 owns it.
Deleted: Capability requirement 38. Execution Contract Scheduled leg 1 owns it.
Deleted: Capability requirement 43. Execution Contract Scheduled leg 1 owns it.
Deleted: Capability requirement 50. Execution Contract Database 3 and Execution Contract Database 4 own it.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 1. Execution Contract Database 1 owns it.
Deleted: Audit arm 3. Execution Contract Database 1 owns it.
Deleted: Audit arm 4. Audit arm 21 owns it.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Deleted: Audit arm 8. Audit arm 2 owns it.
Deleted: Audit arm 9. Audit arm 21 owns it.
Deleted: Audit arm 10. Action wiring 29 owns it.
Deleted: Audit arm 11. Audit arm 21 owns it.
Deleted: Audit arm 12. Execution Contract Database 1 owns it.
Deleted: Audit arm 13. Audit arm 21 owns it.
Deleted: Audit arm 14. Concurrency 18 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 30. Action wiring 19 owns it.
Deleted: Action wiring 32. Primitive policy 13 owns it.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 3. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 6. Check 1.4 owns it.
Deleted: Reconciliation 7. Reconciliation 22 owns it.
Deleted: Reconciliation 19. Defensible Retention Reconciliation 11 owns it.
Deleted: Reconciliation 20. Defensible Retention Action wiring 70 owns it.
Deleted: Reconciliation 21. Defensible Retention Reconciliation 11 owns it.
```

### Composition logic › Disposition

```
Deleted: Disposition 23. Disposition 22 owns it.
Deleted: Disposition 24. Disposition 42 owns it.
Deleted: Disposition 25. Disposition 42 owns it.
Deleted: Disposition 26. Disposition 20 owns it.
Deleted: Disposition 27. Disposition 41 owns it.
Deleted: Disposition 28. Disposition 43 owns it.
Deleted: Disposition 29. Disposition 42 owns it.
Deleted: Disposition 30. Disposition 43 owns it.
Deleted: Disposition 31. Disposition 44 owns it.
Deleted: Disposition 37. Disposition 47 owns it.
```

### Composition-level invariants › Invariant 8 — Authentication precedes destruction, disclosure and commitment

```
  Deleted: Invariant 9. Composes 6 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 20. Execution Contract Database 2 owns it: an audit write's lease check and append are one transaction, so no append lands beside another holder's closing.
```
