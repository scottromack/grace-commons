---
title: Resolve a Person's Data Rights — history
nav_exclude: true
search_exclude: true
---

# Resolve a Person's Data Rights — history

The dated record of how [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/resolve-a-persons-data-rights.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-11-22 — The stall mark leaves the derived request entry for a store of its own.** *Chose:* the stall mark lives in the stall index, keyed by request id and kept apart from the request entry, still extraction-pending against Owed Record, so the rebuild of a missing request entry from its intake event neither writes nor drops it. *Over:* Scott's direction of 2026-11-19 (rounds/open-line-choices-directions-2.md, item 75), that the mark is read from the intake event itself: no event carries a stall, and the intake event predates it and is immutable, so past the audit horizon the mark is the one carrier of a destruction planned and never sealed. *Because:* a derived index is droppable and regenerated (Execution Contract Composition state), and a mark held in one was cleared by a rebuild that Composition state 28 forbids; the mark was never derivable, so it stands where nothing rebuilds it.

- **2026-11-22 — Defensible Retention owns the retention of the disclosure and consent records, and an erasure's re-enumeration is read both ways.** *Chose:* Capability requirement 60 and 61 place every record of the Selective Disclosure and Consent instances under the Defensible Retention instance's retention (Scott, 2026-11-19, item 76), and each constituent composition note is stated met or declined in the Composition notes; Check 2.6 re-enumerates an erasure's universe from the host's data inventory and finds every surviving record in the disposition set. *Over:* a forbidden bound owned by nothing, and a check that barred the one re-enumeration that finds an erasure omitting a survivor. *Because:* a retention nothing owns is a hold nothing can see, and an omission a re-enumeration can find is the no-silent-omission guarantee's own test.

- **2026-11-18 — Check 3.6 retires: Defensible Retention commits a purge's destruction record with the purge, so no record stands owed under an open marker.** *Chose:* the check goes, and Check 3.1 loses its exception for it; the check's one citation, Defensible Retention Check 5.9, retired under Execution Contract Database 1 and Read 4 (Scott's ruling of 2026-11-17 9:19 PM Central, the Login ruling, applied to Defensible Retention by the unit that retires its recovery). *Over:* repointing the check to another Defensible Retention rule. *Because:* the state it read, a destruction record owed under an open marker, is no state any more: the purge, its intent and its outcome commit together or the call commits nothing. The page returns to `doing` for a delta round, since a check of the conformance section changed.

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

- **2026-11-18 — A composition action reads the clock once: Capability requirement 24 and Clock semantics 2 retire to Execution Contract Logic confinement 19.** *Chose:* Capability requirement 24 (the composition passes no now to a constituent) and Clock semantics 2 (the composition reconciles no skew between the seam's clock and a constituent's) leave their `Deleted:` tombstones naming Logic confinement 19 and the ruling, never renumbered or reused, Clock semantics 2 under a new heading of the Deleted rules, *Edge cases › Clock semantics*, where it stood on the page. Citations found, by label: none (`cites.py`: nothing rests on either); no formal model, twin or coverage row names either, so the formal line stands as written. Kept, each with its subject: Capability requirement 20, 21 and 23 (the allowance declared; one now per invocation, every instant it writes stamped from it), Term clock offset allowance (a reading of now set against a source's creation instant, a stamp another call wrote, or another invocation's now), Term aged event, Term stand-in, Term young intent, Term overdue intent, Term horizon event and Check 2.5 and 3.4, each setting one call's now against an instant another call, a source or the substrate stamped. The section term's floors (Term section work bound, bind floor, plan floor) count Lease's remaining-term readings, which Lease's host answers on its own clock, and Logic confinement 19 leaves them as they are. Rules 2 fewer. *Over:* retiring the allowance or recounting the floors with them: the allowance still has a subject wherever two calls' readings meet (Execution Contract Logic confinement 7 and 18), and a Lease reading is no reading of now. *Because:* Scott, 2026-11-18 6:52 AM Central, "YYY" (rounds/escalations.md 2026-11-18 12:52Z, item 2, on the measure of 06:09Z): a composition action reads the clock once, and every constituent call it makes takes that reading as its now, from MIT's sync-engine (github.com/mit-sdg/sync-engine), which binds one instant per causal flow. The page takes a delta round.

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-21, newest first:

- 2026-10-06: thirteen passes, 16 foundational, each cured in its pass

- **2026-11-22 — The erasure composes Recoverable Invocation; the access and the intake stay one transaction.** *Chose:* bind one act kind, `dsar.erasure_execution`, keyed by the request id, around the planned calls (Defensible Retention's purge and the host delete), whose answers land outside the store, and leave [Receive Request], [Fulfill Access Request] and [Disposition Report] unbound (every write of the access is a store write, so Execution Contract Database 1 commits it whole and a refused call writes nothing). The seal (the disclosure and the fulfilled event) stays the page's own and commits in the transaction the close commits in, or on the caller's next call as the re-entry bind after a sweep or an operator closed the act; the reconciliation's legs, the request section, the compensating event, the case and the binding orphan retire; the index leg keeps the derived-index and stall-mark housekeeping and runs once per Recoverable Invocation run. Directions Option A settled (Scott, 2026-11-09 9:17 PM and 2026-11-10 7:15 AM Central): a binding orphan becomes a refusal; caller codes become Recoverable Invocation's on the erasure; a dead erasure the probe cannot certify escalates to an operator, detected and alerted rather than prevented; kinds split by the wait; a disclosure with no fulfilled event is a finding. Derived by rule: the plan cap in place of the plan floor, the commit's retention re-read ahead of each host delete, the one now as the pairing datum. Rules: 353 before, 286 after (about 90 tombstoned, 55 restated, 20 new); the page lost about 7 KB. *Costs:* an act section and Recoverable Invocation's instance bounds to declare; the erasure's codes change (act-in-flight, journal-unavailable); most dead erasures that touch a host delete or more than one purge need an operator, where the leg sealed them itself; the automatic response to a data subject after a dead erasure now waits for the caller's next call, the one near-call, with Recoverable Invocation's escalated and closure-at-risk alerts between. *Over:* composing for the access too (no wait to protect), keeping the leg beside Recoverable Invocation (two recovery protocols over one intent), and a sweep that writes the disclosure (Recoverable Invocation Sweep never 1). *Because:* twelve of the seventeen foundational findings of 2026-10-06 and 2026-10-07 sat in the pairing, the audit arms, the leg and the request section (Ledger lines 2026-10-05-p and 2026-10-06-l, both closed here), the same latent contradiction with Read 4 that Chain of Custody's and Defensible Retention's maps found, and the map of rounds/rprd-ri-map-2026-11-22.md. The page takes a full round next.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Resolve a Person's Data Rights](./resolve-a-persons-data-rights.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 9. Action wiring 33 owns it: a landed fulfillment is the one that writes the fulfillment entry.
Deleted: Composition state 23. Execution Contract Read 3 owns it.
Deleted: Composition state 24. Execution Contract Database 1 owns it: a disclosure and its fulfilled event commit together or neither does, so no unbound disclosure can stand.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 8. Capability requirement 49 owns it: one policy answers for every event of the audit instance, so no write of the composition carries a retention input.
Deleted: Capability requirement 13. Recoverable Invocation Invariant 5.2 and Sweep never 2 own it: no page write outside an invocation remains an audit write.
Deleted: Capability requirement 14. Capability requirement 37 owns it.
Deleted: Capability requirement 15. Capability requirement 37 owns it.
Deleted: Capability requirement 16. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 17. Recoverable Invocation Instance start 4 owns it: the invocation completion bound.
Deleted: Capability requirement 18. Recoverable Invocation Instance start 4 owns it: the sweep cadence.
Deleted: Capability requirement 19. Capability requirement 39 owns it.
Deleted: Capability requirement 24. Execution Contract Logic confinement 19 owns it: the host injects the invocation's one reading at the seam of every constituent call the invocation makes, so whether the composition passes now to a constituent or leaves the instant blank, the constituent records the same instant (Scott, 2026-11-18 6:52 AM Central, "YYY", rounds/escalations.md 2026-11-18 12:52Z, item 2).
Deleted: Capability requirement 28. Recoverable Invocation Instance start 4 owns it: the pause bound.
Deleted: Capability requirement 29. Recoverable Invocation act section 16 and Instance start 6 through 8 own it.
Deleted: Capability requirement 30. Recoverable Invocation act section 16 and Instance start 6 through 8 own it.
Deleted: Capability requirement 31. Recoverable Invocation act section 16 and Instance start 6 through 8 own it: the Lease Sizing bound for every unfenced write.
Deleted: Capability requirement 32. Recoverable Invocation act section 16 and Instance start 6 through 8 own it.
Deleted: Capability requirement 33. Recoverable Invocation act section 16 and Instance start 6 through 8 own it.
Deleted: Capability requirement 34. Recoverable Invocation act section 16 and Instance start 6 through 8 own it.
Deleted: Capability requirement 36. Recoverable Invocation act section 19 owns it.
Deleted: Capability requirement 38. Execution Contract Scheduled leg 1 owns it.
Deleted: Capability requirement 39. Recoverable Invocation Instance start 4 owns it: the closure window exceeds the worst closure.
Deleted: Capability requirement 40. Execution Contract Input 2 owns it: a bound is a default cap, and the text cap's default is 1,024 code points (Term text cap).
Deleted: Capability requirement 43. Execution Contract Scheduled leg 1 owns it.
Deleted: Capability requirement 46. Recoverable Invocation Primitive policy 18 owns it: the run's now.
Deleted: Capability requirement 48. Recoverable Invocation Instance start 5 owns it: the retention floor.
Deleted: Capability requirement 50. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Capability requirement 55. Execution Contract Scheduled leg 2 owns it: the index leg takes Recoverable Invocation's run's now.
Deleted: Capability requirement 56. Recoverable Invocation's run bound owns it: the index leg runs within the run.
Deleted: Capability requirement 58. Recoverable Invocation service identity 3 owns it.
Deleted: Capability requirement 62. Recoverable Invocation's settling period, Reconcile step 5.9 and Instance start 5 own it: the alert floor it served retires.
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
Deleted: Audit arm 15. Execution Contract Database 1 owns it for the access: a refused closing record commits nothing. Recoverable Invocation Primitive policy 31 owns it for the act kind.
Deleted: Audit arm 16. Recoverable Invocation Invariant 8.3 and its Term recording failure own it.
Deleted: Audit arm 17. Recoverable Invocation Invariant 8.4 owns it.
Deleted: Audit arm 22. Execution Contract Database 1 owns it: nothing is owed under one transaction. Recoverable Invocation's position table owns it for the act kind.
Deleted: Audit arm 23. Execution Contract Database 1 owns it: nothing is owed under one transaction. Recoverable Invocation's position table owns it for the act kind.
Deleted: Audit arm 24. Execution Contract Database 1 owns it: nothing is owed under one transaction. Recoverable Invocation's position table owns it for the act kind.
Deleted: Audit arm 27. Recoverable Invocation Reconcile step 3.18 and Recoverable Invocation External check 10 own it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 14. Disposition 1 and Invariant 2.1 own it: every enumerated record carries exactly one disposition.
Deleted: Action wiring 19. Execution Contract Database 1 owns it for the access: a refused disclosure write commits nothing. Recoverable Invocation's refuse owns it for the act kind (commit 2).
Deleted: Action wiring 20. Recoverable Invocation's position table owns it for the act kind; Audit arm 7 owns it for the access.
Deleted: Action wiring 23. Recoverable Invocation Invariant 1.1 and Action wiring 4 own it: an act kind's intent lands before its commit.
Deleted: Action wiring 29. Recoverable Invocation's table owns it: an unknown partition yields and answers recording-failure carrying outcome.
Deleted: Action wiring 30. Action wiring 19 owns it.
Deleted: Action wiring 32. Primitive policy 13 owns it.
Deleted: Action wiring 39. Execution Contract Database 1 owns it: a disclosure write that answers no answer aborts the transaction.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 1. Disposition 1 and Invariant 2.1 own it.
Deleted: Wiring decision 3. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Recoverable Invocation's sweep cadence and Execution Contract Scheduled leg 1 own it.
Deleted: Reconciliation 2. Recoverable Invocation's sweep cadence 2 and 3 own it.
Deleted: Reconciliation 3. Recoverable Invocation Invariant 7.1 owns it.
Deleted: Reconciliation 4. Recoverable Invocation Invariant 7.2 and 7.3 and Reconcile step 1.2 own it.
Deleted: Reconciliation 5. Recoverable Invocation's service identity binding, Reconcile step 3.2 and Invariant 5.2 own it.
Deleted: Reconciliation 6. Check 1.4 owns it.
Deleted: Reconciliation 7. Reconciliation 22 owns it.
Deleted: Reconciliation 8. Execution Contract Database 1 owns it for the access: no binding orphan can stand. Recoverable Invocation Primitive policy 5 owns the pairing for the act kind, on the invocation id alone.
Deleted: Reconciliation 9. Recoverable Invocation's act probe under the critical section owns it (Reconcile step 2.11 and 3.1).
Deleted: Reconciliation 10. Recoverable Invocation Invariant 5.1 and Reconcile step 3.2 own it.
Deleted: Reconciliation 11. Recoverable Invocation Reconcile step 3.2 owns it.
Deleted: Reconciliation 12. Execution Contract Database 1 owns it for the access: a disclosure never stands without its event. Recoverable Invocation Reconcile step 3.2 and its Term recovered outcome payload own it for the act kind.
Deleted: Reconciliation 13. Recoverable Invocation Reconcile step 3.7, Sweep never 1 and Invariant 9.2 own it: no sweep writes for the adopter, so the response completes on the caller's next call as the re-entry bind (Action wiring 44).
Deleted: Reconciliation 14. Recoverable Invocation Invariant 5.9 and act probe 7 own it: what the stores cannot show is escalated, never sealed by the sweep. Action wiring 51 seals it on the re-entry bind.
Deleted: Reconciliation 15. Execution Contract Database 1 owns it for the access. Recoverable Invocation Invariant 4.9 and Resolve own it for the act kind.
Deleted: Reconciliation 16. Action wiring 49 owns it: the re-entry bind seals every record outside the plans with the intent's disposition.
Deleted: Reconciliation 17. Recoverable Invocation act section 11 and 12 and Invariant 2.2 own it.
Deleted: Reconciliation 18. Composition state 9 owns it.
Deleted: Reconciliation 19. Defensible Retention Reconciliation 11 owns it.
Deleted: Reconciliation 20. Defensible Retention Action wiring 70 owns it.
Deleted: Reconciliation 21. Defensible Retention Reconciliation 11 owns it.
Deleted: Reconciliation 22. Recoverable Invocation Reconcile step 5.1 and 3.21 own it.
Deleted: Reconciliation 23. Recoverable Invocation Reconcile step 2.4 owns it.
Deleted: Reconciliation 24. Action wiring 50 and Term erasure probe own it.
Deleted: Reconciliation 26. Recoverable Invocation Reconcile step 2.3 owns it.
Deleted: Reconciliation 27. Recoverable Invocation Reconcile step 2.10 and 3.13 own it.
Deleted: Reconciliation 28. Recoverable Invocation Reconcile step 2.7, 3.17 and 3.25 own it.
Deleted: Reconciliation 29. Recoverable Invocation Reconcile step 3.7 owns it.
Deleted: Reconciliation 30. Recoverable Invocation Reconcile step 2.11 and 3.1 own it.
Deleted: Reconciliation 31. Recoverable Invocation Term recovered outcome payload owns it. Action wiring 31 owns the enumeration instant.
Deleted: Reconciliation 32. Execution Contract Database 1 owns it: an access is never recovered.
Deleted: Reconciliation 33. Recoverable Invocation Reconcile step 5.1 owns it.
Deleted: Reconciliation 37. Recoverable Invocation's run bound 1 and sweep cadence 3 own it.
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

### Composition-level invariants › Invariant 1 — Binding bijection

```
Deleted: Invariant 1.5. Recoverable Invocation Invariant 2.1 and 4.2 own it.
Deleted: Invariant 1.6. Recoverable Invocation Invariant 5.2 owns it.
```

### Composition-level invariants › Invariant 8 — Authentication precedes destruction, disclosure and commitment

```
  Deleted: Invariant 8.2. Recoverable Invocation Invariant 1.1 owns it.
  Deleted: Invariant 9. Composes 6 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Execution Contract Logic confinement 19 owns it: inside one composition call every constituent reads the composition's now, so no skew stands between the seam's clock and a constituent's for the composition to reconcile (Scott, 2026-11-18 6:52 AM Central, "YYY", rounds/escalations.md 2026-11-18 12:52Z, item 2).
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Recoverable Invocation act section 8, 9, 11 and 12 own it for the act kind; Execution Contract Database 2 owns it for the access.
Deleted: Concurrency 3. Recoverable Invocation act section 7 and open step 2.1 own it: the section is taken by a blocking take, never a try_take.
Deleted: Concurrency 4. Recoverable Invocation's Term critical section holder (Lease Identity 6) owns it.
Deleted: Concurrency 5. Recoverable Invocation's Term critical section key owns it.
Deleted: Concurrency 6. Recoverable Invocation open step 1.7, 3.5 and 2.3 own it: act-in-flight and section-unavailable.
Deleted: Concurrency 7. Recoverable Invocation open step 3 and read invocation 15 own it.
Deleted: Concurrency 8. Recoverable Invocation close step 3.10 and journal write bound 1 own it; Execution Contract Database 2 refuses a write to an overtaken holder.
Deleted: Concurrency 9. Recoverable Invocation close step 3.10 and journal write bound 1 own it.
Deleted: Concurrency 10. Recoverable Invocation close step 3.10 and journal write bound 1 own it.
Deleted: Concurrency 11. Recoverable Invocation journal write bound 1 owns it.
Deleted: Concurrency 12. Recoverable Invocation open step 5.4 through 5.6 own it.
Deleted: Concurrency 13. Recoverable Invocation yield 3 and Action wiring 54 own it: the plan cap bounds the planned calls.
Deleted: Concurrency 14. Recoverable Invocation pause bound 2 and commit 15 own it.
Deleted: Concurrency 15. Recoverable Invocation act section 17 owns it.
Deleted: Concurrency 16. Recoverable Invocation act section 18 owns it.
Deleted: Concurrency 17. Recoverable Invocation open step 4.1 and 4.2 own it.
Deleted: Concurrency 18. Recoverable Invocation act section 10a and refuse step 1.3 own it.
Deleted: Concurrency 19. Recoverable Invocation act section 15 owns it.
Deleted: Concurrency 20. Execution Contract Database 2 owns it: an audit write's lease check and append are one transaction, so no append lands beside another holder's closing.
Deleted: Concurrency 21. Recoverable Invocation act section 10 owns it.
Deleted: Concurrency 22. Recoverable Invocation Term release and close step 4.2 own it.
Deleted: Concurrency 23. Recoverable Invocation act section 16 owns it.
Deleted: Concurrency 24. Recoverable Invocation Reconcile step 4.4 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 3.6. Execution Contract Database 1 and Read 4 own it: Defensible Retention commits a purge's destruction record with the purge, so no destruction record stands owed under an open marker (the Login ruling of 2026-11-17 9:19 PM Central, applied to Defensible Retention by the map of 2026-11-18).
Deleted: Check 6.6. Recoverable Invocation Check 2.5, 2.6 and 5.1 own it.
Deleted: Check 6.7. Recoverable Invocation Check 6.4 owns it.
Deleted: Check 6.8. Check 1.4 owns it.
Deleted: Check 8.1. Recoverable Invocation Check 3.1 and 3.3 through 3.6 and External check 1 own it.
Deleted: Check 8.4. Recoverable Invocation Check 4.1 owns it.
Deleted: Check 8.7. Recoverable Invocation Check 3.1 and 3.3 through 3.6 and External check 1 own it.
Deleted: Check 8.8. Recoverable Invocation Check 3.1 and 3.3 through 3.6 and External check 1 own it.
Deleted: Check 8.11. Recoverable Invocation Check 7.1 through 7.3 own it.
Deleted: Check 8.12. Recoverable Invocation Check 7.1 through 7.3 own it.
```

### Generation acceptance › External checks

```
Deleted: External check 9. Recoverable Invocation External check 3 owns it.
Deleted: External check 11. Recoverable Invocation External check 2 owns it.
```
