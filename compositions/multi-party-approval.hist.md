---
title: Multi-Party Approval — history
nav_exclude: true
search_exclude: true
---

# Multi-Party Approval — history

The dated record of how [Multi-Party Approval](./multi-party-approval.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/multi-party-approval.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-08-26 — Invariant 4 is safety plus liveness at quiescence, not a static always-claim.** *Chose:* the assignment-cascade claim holds at quiescence conditioned on no open recovery marker, with the partial-cascade and step-7 windows named as bounded surfaced transients; check 4 audits under the same structure. *Over:* the static "always both sides" statement. *Because:* the partial-cascade and trailing-decision paths the spec itself describes reach and violate the static form.

- **2026-08-26 — Recovery emissions are composition-attributed and the retry loop runs only on transient failure.** *Chose:* every record emitted outside the original human invocation attests under `application_actor_ref` with the human in `data` and `recovery = true`; invalid-request foreclosed by budget-derived caps; one vocabulary shared with Execute Gated Workflow. *Over:* re-presenting human credentials on retry, or looping on every rejection. *Because:* a human credential is unavailable to a recovery path, and a deterministic rejection retried forever is a stall.

- **2026-08-29 — The sweep is bounded below as well as above, names candidate intents rather than declaring them unrecoverable, and records its intent before it commits.** *Chose:* `decision_completion_bound` as the transition sweep's lower edge (the horizon it already carried as its upper), `compensation_window` and `reconciliation_cadence` declared; `intent_event_candidates` on every re-emitted record in place of `intent_event_id_unrecoverable = true`; a `chain.recovery_intended` record before every closure that recalls, withdraws, resolves, or re-emits; the cross-store edge case's "atomically or" restated as ordered. *Over:* a sweep whose lower edge was the store-against-events comparison alone, and a flag that said the pairing was unknowable when the records name the candidates. *Because:* the comparison cannot see an invocation that has not written yet, so a sweep inside the bound lands a second outcome for one decision; the candidates are on the trail and naming them is what the pairing rule asks for; and a recall or withdrawal the sweep performs with no record of its own is indistinguishable from a direct call (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*, *Recovery commits under a declared service identity*).

- **2026-08-29 — Recovery is horizon-bounded, evaluate-first, and keyed on the chain's own id.** *Chose:* the initiation leg and the additive rebuild's quarantine apply only inside the audit horizon, with post-horizon chain records declared truth-bearing under `chain_store_durability`; every recovery withdrawal runs the evaluate-first gate and the evaluation leg runs before the initiation leg; each step's stored reason carries its chain_id so the case-(a) scan is exact; every cascade arm is landed with the in-invocation not-pending closing as a supersession. *Over:* an unbounded initiation leg, a recovery that withdrew without evaluating, a scan keyed on subject and initiator, and a cascade whose arms were enumerated only for storage-failure. *Because:* the unbounded leg withdrew every lawfully purged chain at each restart; the ungated recovery overturned credential-verified approvals in the initiator's name; the subject-keyed scan withdrew a concurrently-initiating sibling's step; and the unenumerated arms gave check 2(b) two opposite verdicts on one history.

- **2026-09-24 — Rewritten in GRACE lang v0.61; forty of forty-one open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` (the quorum rule), `Reconciliation` (the recovery discipline, as four legs), `Cascade` and `Scope vocabulary` as the surfaces; invariant numbers 1 through 5 and 7 through 10 unchanged, Invariant 6 tombstoned to Composes 5; the seven acceptance checks renumbered by the invariant each tests, with the permission and constituent checks the prose lacked; the edge cases split into Non-goals and three Edge cases families. Choices the page left open, each decided by a standing rule: the invocation id the seam injects rides on every event and on the chain record, so the initiation intent joins its chain exactly (2026-08-29-e — *Intents pair with outcomes*); the routed vector defined for all four counts with P derived, a decision routed only by its decision intent, and a purged intent still recognized by its surviving action reference and actor through the event index (2026-08-29-a, -b, -c, -d, 2026-08-26-l); the position exported on every action that straddles a commit, because a re-run initiation is not refused (*A composition's own rejection arm carries the retry bit*); the retention-step arm and the retention-source invalid-request read back by invocation id and proceeding as landed (*A transcribed rejection arm keeps its payload*); the compensation window set against the liveness sum rather than the cadence alone (*Liveness is arithmetic*); the step-assignment pairing rebuilt through Assignment's history_for at any age (2026-08-29-m, 2026-08-26-i); the resolution reason declared on every arm (2026-08-26-g, 2026-08-29-g); a retried recall answered not-known closed with an anomaly mark (2026-08-26-n); and the extraction gate run on the recovery discipline, its verdict left to the higher-order composition test (2026-08-26-m). *Over:* the prose's step lists, a case list ordered a, b, d, c under *order of severity*, a terminal instant defined as *the first moment the rule fired* that two stamping sites contradicted, and an open finding the per-chain serialization had already closed. *Because:* the rules state each landing once; the formal line stays open because the model, not the page, is what it owes.

- **2026-10-20 — The store's guarantees cited, not restated, the chain exclusion among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 26), and the twenty-eight rules that restated it, or existed only for a store that could lose or split a write, tombstoned to their owner — the chain store durability the deployment declared and persisted by (Capability requirement 4, Composition state 19), to Store 3 and Store 4; the chain exclusion the host supplied (Capability requirement 15) and every rule holding it across an evaluation, a withdrawal or the sweep's pre-check (Action wiring 33, 42, Reconciliation 6, Concurrency 1, 2), its release on the holder's return and death and at every answer, the bar on running without it, the sweep's skip of a held chain and the bar on serializing two decisions ahead of their evaluations (Capability requirement 16, 17, 18, Action wiring 58, Reconciliation 7, Concurrency 3), and the mid-flight revocation of a credential the intent validated (Audit arm 12), to Store 2; and to Store 1, under which an action's intent, constituent writes, cascade and outcome commit together, the initiation's exclusion that kept the sweep off it (Action wiring 5), the decision's own failed recall riding on its outcome (Action wiring 27), [Withdraw Chain]'s evaluate-first gate, the evaluation leg and its place ahead of the initiation leg (Action wiring 43, Reconciliation 3, 23), the sweep's lower edge (Reconciliation 4), the chainless-step scan (Reconciliation 14), the re-run of a skipped recall and evaluation (Reconciliation 22), the recall leg for calls no partial flag names (Reconciliation 24, 25), the rebuild's hand-off of a retained record to the initiation leg (Composition state 14, 15), and the read-back of a recording-failure at step 4, a split Audit Trail's own rewrite removed (Audit arm 6); with them a submit's or an assign's storage-failure no longer runs the initiation recovery (Action wiring 9, 12) and a decision's outcome carries no partial flag (Action wiring 29); rules 285 to 258. *Over:* a host exclusion on each chain, held across every evaluation, withdrawal and sweep write and released on its holder's return or death; a sweep bounded below by the decision completion bound; and legs that recovered an evaluation, a recall or a cascade withdrawal a crash had lost — the lower edge and the evaluate-first gate are turns of 2026-08-29, below. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice: every write this composition's actions make is a store write, its cascade's included, so Store 2 reads what an evaluation or a withdrawal decides on inside the transaction that writes it, which is what the exclusion was for, and no crash leaves half an action for a leg to find. The initiation recovery, the quarantine, the transition leg's re-emission and the partial-flag retry stay on the refusals that still reach them — a constituent's invalid-request or already-assigned, a refused outcome, a retired service credential, Audit Trail's no-answer arms and Approval Step's temporal invalid-request on a cascade withdrawal; the rebuild still retains every record it cannot produce (Composition state 13), and the decision completion bound stays in the liveness sum (Capability requirement 7, 11). What the composition does for its domain is unchanged.

- **2026-11-10 — The waits retired: the five state-changing actions are five Recoverable Invocation act kinds.** *Chose:* (Scott, 2026-11-09 9:17 PM Central, "A", and 2026-11-10 7:15 AM Central, the wait ruling, "simple DRY"; the map rounds/mpa-ri-map-2026-11-10.md, its directions settled under A, 2026-11-10 7:55 AM Central) the five state-changing actions each bind one act kind — chain.initiation keyed by the chain id the host injects ahead of the open, so no minted-key deviation, chain.approval, chain.rejection and chain.step_withdrawal keyed by the decision key, chain.withdrawal keyed by the chain id, every kind repeatable — with the initiation transaction, the decision transaction and the withdrawal transaction their commits (A: act kinds split by the wait, G1, G2, G15); the intent commits at the open and the outcome at the close, so an Audit Trail fault at the outcome leaves an open intent the sweep closes from the chain record or Approval Step's records, and a constituent's storage-failure is a pre-commit refusal (A: an audit failure composes rather than committing a partial); a refused submit or assign fails the initiation transaction whole, so no partial chain commits and the initiation recovery, its dispositions, the initiation-failed record and the quarantine go (A, G4); a lost initiation event is recovered, the chain left live, not torn down (A, G5); the resolution, the cascade's withdrawals and its supersessions fold into the terminating act's outcome as its terminal summary, written onto the chain record in the same commit, so chain_resolved, the cascade step_withdrawn, cascade_completed and chain_initiation_failed retire and the resolution is attested under the decider (A: kinds split by the wait, the resolution having none of its own, G3, G9); a cascade's temporal invalid-request fails the commit, with the invocation's now injected into Approval Step's seam so that only a clock stepping back meets it, and a deterministic arm proceeds, alerted and named in the summary, so the partial flag, its retry and its closure records go (A, G6, G7; Cascade 14, 15; Capability requirement 37); the trailing flag computed ahead of the open is re-checked inside the decision transaction, a mismatch refused chain-state-changed, and [Withdraw Chain]'s Pending re-read inside its transaction (A: a collision becomes a refusal, G8; Action wiring 64 through 67); every acting action's caller-visible codes Recoverable Invocation's, recording-failure(outcome) answered, [Initiate Chain]'s carrying the chain id, a step refusal and the mismatch leaving a refusal record, the events renamed chain.<kind>.* (A: codes change to Recoverable Invocation's, G14); an operator's outcome detected, not prevented, by the terminal-data alert and the shape alert (Composition state 22, 23), with the false-closing alert in the leg, while the routed vector reads no outcome, so quorum determinism and bypass resistance stay prevented (A: detected, not prevented, with an alert, G11; Reconciliation 50); an intent whose invocation died before its commit escalated for an operator (A, G12); a step decision, a chain record or a terminal no intent carries a write-ownership finding (A: a record with no intent becomes a finding, G13; Reconciliation 20, 48, 49); the mayor's derivable calls taken as the map recommends: one identity, `application_actor_ref`, as the recovery identity, freed once no write of the composition's own actions is attested under it (G10); one completion bound for the five kinds, re-anchored to Recoverable Invocation's span (G16); the chainless-step enumeration and the pre-switch cut-over carried as open lines (G13). Capability requirement 8, 9, 11, 13, 28 through 35, Composition state 5, every live Audit arm rule but 5, Action wiring 15, 39, every live Reconciliation rule but 2, 5, 20 and 39, Cascade 4, 5, 6, 9, Invariant 1.2, 8.2, 10.1 through 10.3, Check 4.2, 5.3, 5.4, 10.1, 10.3, 10.4 and 10.5 tombstoned to what owns them; Composes 13 through 17, Composition state 22 through 25, Capability requirement 37 through 43, Action wiring 64 through 71, Reconciliation 44 through 50, Cascade 14, 15, Check 6.5, 9.1, External check 6, 7, Non-goal 15 through 17 and Cross-record consistency 1 new; the closure table rewritten in Recoverable Invocation's form. Rules 286 to 249. Open lines 2026-11-05-b, 2026-11-06-a and 2026-08-29-u dissolve with the rules and the model they named; 2026-11-06-c is carried, sharpened; 2026-11-10-a, 2026-11-10-b and 2026-11-10-c are opened. *Over:* removing the wait by reversing 2026-10-20 at its other end, so that an Audit Trail refusal of any outcome fails the whole action, which every write here being a database write allows, but which would make Audit Trail's health a precondition of every decision and every withdrawal, so that a deterministic outcome refusal froze every chain on the instance; and keeping the page's own sweep beside Recoverable Invocation, which would have covered the intent-and-outcome pairing twice. *Because:* the waits were self-made: the 2026-10-20 decision kept a committed act when an audit record or a cascade call was refused, and the page then built the initiation recovery and its quarantine, the transition leg's re-emission, the partial-flag retry, a Lease of its own, the compensation window, its cadence, run bound, liveness sum and escalation reach to close them, which Recoverable Invocation owns; sixteen of the twenty-four foundational findings of Final Critique 12 through 17 sat in that machinery or in the audit-arm positions Recoverable Invocation's open, close and refuse own. It turns the 2026-10-20 entry's "stay on the refusals that still reach them", refusal by refusal; the 2026-08-29 entries in part (the sweep's lower edge, its recovery intent and its candidates are Recoverable Invocation's, and the evaluate-first gate loses its subject); the first 2026-08-26 entry in part (the partial-cascade window goes); and the second 2026-08-26 entry (recovery attests under Recoverable Invocation's recovery identity, and the retry loop goes). *Costs:* five bindings and the instance's bounds and sweep, the Lease host the page already had now serving Recoverable Invocation's act section; every acting action's caller-visible codes, which Privileged Access Provisioning relays; the auditor-visible vocabulary, chain_resolved among it, and the resolution's attestation moved from the service identity to the decider; a decision whose chain ended between its resolution and its commit refused chain-state-changed and retried; a chain withdrawal a clock step refuses, which the initiator retries (the partial-cascade run's "the caller still receives withdrawn" no longer holds); operator work for an intent whose invocation died before its commit, which Database 1 had rolled back unseen; Invariant 5.1 and 7.3 fall from prevented to detected against an operator's resolve.

- **2026-11-18 — A composition action reads the clock once: Clock semantics 2 and 3 retire to Execution Contract Logic confinement 19, and Capability requirement 37 cites it.** *Chose:* Clock semantics 2 (the composition compares no terminal instant with a step's decided instant) and Clock semantics 3 (the composition passes no instant to a constituent for the constituent to record) leave their `Deleted:` tombstones naming Logic confinement 19 and the ruling, never renumbered or reused, under a new heading of the Deleted rules, *Edge cases › Clock semantics*, where they stood on the page. Capability requirement 37, which said for this page what Logic confinement 19 now says for every composition (the host injects the invocation's now into Approval Step's and Assignment's seams at the commit), keeps its label, which the TLA+ models and the coverage matrix cite, and carries the obligation PER Logic confinement 19; Capability requirement 23 cites Logic confinement 19 for a constituent's instant being the host's injection, in place of Capability requirement 37. Citations found, by label: none for Clock semantics 2 or 3 (`cites.py`), the coverage matrix's out-of-scope row naming Clock semantics 1 through 3 (now 1, the two listed among the rows that left); Capability requirement 37 (Capability requirement 23; the TLA+ model and its twins' comments, with 19 and 38; the coverage row of the probes' pairing datum); Term operating skew (Capability requirement 27, Check 3.1 and 3.2, Term temporal invalid-request, the breach-forensics scenario). Kept, each with its subject: Capability requirement 27, Check 3.1 and 3.2 and Term operating skew, restated as the bound between the clock of this composition's call and the clock of another call that stamped a constituent's record, as a Permissions grant's issue and revocation are stamped, since an initiation's or a withdrawal's instant is still set against grant stamps other calls wrote; Term temporal invalid-request (two nodes' clocks across two calls); Capability requirement 38. No model changes: no model stated Clock semantics 2 or 3, and Capability requirement 37 keeps its label and its obligation. Rules 2 fewer. *Over:* retiring Capability requirement 37 to a tombstone, which would move the comments of twenty-six models and a coverage row off a label whose obligation stands. *Because:* Scott, 2026-11-18 6:52 AM Central, "YYY" (rounds/escalations.md 2026-11-18 12:52Z, item 2, on the measure of 06:09Z): a composition action reads the clock once, and every constituent call it makes takes that reading as its now, from MIT's sync-engine (github.com/mit-sdg/sync-engine), which binds one instant per causal flow. The page takes a delta round.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Multi-Party Approval](./multi-party-approval.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 5. Action wiring 9 and Action wiring 12 own it: a refused submit or assign fails the initiation transaction whole, so no initiation-failed record exists to carry a disposition.
Deleted: Composition state 14. Execution Contract Database 1 owns it.
Deleted: Composition state 15. Execution Contract Database 1 owns it: an initiation's chain record and its chain-shape event commit together, and the composition names no record a rebuild hands to the initiation leg.
Deleted: Composition state 19. Execution Contract Database 3 and Execution Contract Database 4 own it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 4. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Capability requirement 8. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 9. Recoverable Invocation sweep cadence 2 and Recoverable Invocation sweep cadence 3 own it.
Deleted: Capability requirement 10. Term reconciliation run bound owns it: the run bound counts every write's landing.
Deleted: Capability requirement 11. Recoverable Invocation Instance start 4 owns it: the worst closure against the closure window, the sweep's run counted in it.
Deleted: Capability requirement 13. Recoverable Invocation service identity 3 owns it: no write of the composition's own actions is attested under the recovery identity, so none is gated on a grant.
Deleted: Capability requirement 15. Execution Contract Database 2 owns it.
Deleted: Capability requirement 16. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 18. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for a host to lack.
Deleted: Capability requirement 28. Recoverable Invocation run bound owns it: the sweep's own, and the write-ownership leg runs inside it.
Deleted: Capability requirement 29. Recoverable Invocation Instance start 5 owns it: the retention floor.
Deleted: Capability requirement 30. Recoverable Invocation act section 1 and Recoverable Invocation act section 11 own it: the sweep takes the act's critical section, and the composition holds no Lease (Composes 17).
Deleted: Capability requirement 31. Recoverable Invocation act section 3 owns it.
Deleted: Capability requirement 32. Recoverable Invocation act section 1 owns it: the critical section has the Lease atom's semantics.
Deleted: Capability requirement 33. Recoverable Invocation act section 16 owns it.
Deleted: Capability requirement 34. Recoverable Invocation pause bound 1 owns it: the instance's pause bound.
Deleted: Capability requirement 35. Recoverable Invocation act section 2 owns it.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Primitive policy 19 owns it for the intent of the five bound actions.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 23 owns it for the intent of the five bound actions.
Deleted: Audit arm 3. Recoverable Invocation Primitive policy 41 owns it for the intent of the five bound actions.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 43 owns it.
Deleted: Audit arm 6. Execution Contract Database 1 owns it.
Deleted: Audit arm 7. Recoverable Invocation Primitive policy 27 owns it: the outcome's invalid-request(step-4) is read back by invocation id.
Deleted: Audit arm 8. Recoverable Invocation Primitive policy 35 owns it: the read-back matches by invocation id over the delta range.
Deleted: Audit arm 9. Recoverable Invocation Primitive policy 28 and Recoverable Invocation Primitive policy 36 own it: a record the read-back finds is landed.
Deleted: Audit arm 10. Recoverable Invocation commit 8d, Recoverable Invocation Primitive policy 29 through 31 own it: an outcome that does not land answers recording-failure(outcome).
Deleted: Audit arm 11. Recoverable Invocation Primitive policy 37 and Recoverable Invocation Primitive policy 40 own it.
Deleted: Audit arm 12. Execution Contract Database 2 owns it.
Deleted: Audit arm 13. Recoverable Invocation Primitive policy 29 owns it, reversed: the close retries a recording-failure(step-2) under the critical section to the terminus.
Deleted: Audit arm 14. Recoverable Invocation Invariant 8.3 owns it: recording-failure(intent) is a committed nothing, and the caller may retry.
Deleted: Audit arm 15. Recoverable Invocation Invariant 8.4 owns it: recording-failure(outcome) is an act that may exist, whose record the sweep closes, and the caller does not retry.
Deleted: Audit arm 16. Recoverable Invocation Primitive policy 42 owns it: the hard alert on the outcome's invalid-request below step-4.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 5. Execution Contract Database 1 owns it.
Deleted: Action wiring 15. Action wiring 68, Action wiring 69 and Recoverable Invocation Invariant 8.4 own it: an initiation whose close does not land answers recording-failure(outcome) carrying the chain id, the chain stays live, and its initiation event is the sweep's.
Deleted: Action wiring 27. Execution Contract Database 1 owns it.
Deleted: Action wiring 33. Execution Contract Database 2 owns it.
Deleted: Action wiring 39. Recoverable Invocation Action wiring 4 and Term decision transaction own it: the cascade runs inside the commit, and the close follows the commit.
Deleted: Action wiring 42. Execution Contract Database 2 owns it.
Deleted: Action wiring 43. Execution Contract Database 1 owns it.
Deleted: Action wiring 58. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Scheduled leg 1 and Recoverable Invocation sweep cadence 2 own it: the sweep runs at every process start, and the reconciliation runs beside it (Reconciliation 2, Reconciliation 46).
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Deleted: Reconciliation 4. Execution Contract Database 1 owns it.
Deleted: Reconciliation 6. Execution Contract Database 2 owns it.
Deleted: Reconciliation 7. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for another holder to hold.
Deleted: Reconciliation 8. Recoverable Invocation reconcile step 1.2 and Term initiation probe own it: an open initiation intent is examined once past its examine edge and closed by the probe's answer.
Deleted: Reconciliation 9. Recoverable Invocation Sweep never 1 owns it: the sweep runs no adopter code other than the act probe, and a recovered initiation leaves its chain live.
Deleted: Reconciliation 10. Recoverable Invocation reconcile step 3.2 and Term initiation probe own it: a committed initiation is closed by the recovered chain.initiation.initiated carrying the chain shape the chain record holds.
Deleted: Reconciliation 11. Recoverable Invocation Invariant 4.1 and Recoverable Invocation Invariant 9.2 own it: the open initiation intent stands for the owed initiation event, and the sweep writes no adopter state.
Deleted: Reconciliation 12. Action wiring 9 and Action wiring 12 own it: a refused submit or assign fails the initiation transaction whole, so no initiation-failed record exists.
Deleted: Reconciliation 12a. Action wiring 9 owns it.
Deleted: Reconciliation 12b. Action wiring 12 owns it.
Deleted: Reconciliation 12c. Action wiring 68 and Recoverable Invocation reconcile step 3.2 own it: a staffed initiation whose initiation event did not land is the sweep's, recovered rather than torn down.
Deleted: Reconciliation 13. Action wiring 9, Action wiring 12 and Recoverable Invocation Invariant 9.2 own it: no partial initiation commits, and a lost initiation event is recovered, its chain left live.
Deleted: Reconciliation 14. Execution Contract Database 1 owns it.
Deleted: Reconciliation 15. Action wiring 9 and Action wiring 12 own it: no initiation recovery withdraws a chain.
Deleted: Reconciliation 16. Recoverable Invocation Invariant 4.1 owns it: the open initiation intent stands for the quarantine flag, and closes when the initiation event lands.
Deleted: Reconciliation 17. Recoverable Invocation reconcile step 1.2, Recoverable Invocation reconcile step 3.2 and Term decision probe own it: an open decision intent is closed by the recovered outcome or escalated.
Deleted: Reconciliation 35. Composition state 6, Term decision probe, Term withdrawal probe and Recoverable Invocation reconcile step 3.2 own it: a terminal chain's terminal event is its terminating act's outcome, which the sweep recovers carrying the terminal summary, and the cascade ran inside the terminating commit.
Deleted: Reconciliation 18. Recoverable Invocation Invariant 3.2 and Recoverable Invocation Invariant 3.3 own it: the sweep pairs by invocation id in the journal and by the pairing datum in the database.
Deleted: Reconciliation 19. Recoverable Invocation reconcile step 1.1 and Recoverable Invocation reconcile step 1.2 own it: the sweep closes intents alone, and an out-of-band transition carries none.
Deleted: Reconciliation 21. Recoverable Invocation Invariant 3.5a, Recoverable Invocation Invariant 5.2 and Recoverable Invocation Primitive policy 11a own it: an outcome never carries candidates, and the recovered outcome carries the recovery flag, the acting actor reference and the intent event id.
Deleted: Reconciliation 22. Execution Contract Database 1 owns it.
Deleted: Reconciliation 23. Execution Contract Database 1 owns it.
Deleted: Reconciliation 24. Execution Contract Database 1 owns it.
Deleted: Reconciliation 25. Execution Contract Database 1 owns it.
Deleted: Reconciliation 26. Cascade 14 owns it: a cascade's temporal refusal fails its commit, so no partial flag names a call to retry.
Deleted: Reconciliation 27. Cascade 14 owns it: the sweep retries no call.
Deleted: Reconciliation 28. Recoverable Invocation Invariant 5.1 and Recoverable Invocation reconcile step 3.2a own it: the recovery intent before any recovered outcome.
Deleted: Reconciliation 29. Recoverable Invocation reconcile step 3.2a owns it: the kind's recovery_intended record carries the invocation id, the intent event id, the act key and the plan.
Deleted: Reconciliation 29a. Recoverable Invocation reconcile step 3.2a and Term decision key own it: a decision kind's act key carries the step id.
Deleted: Reconciliation 30. Cascade 10 and Cascade 14 own it: no call is left for the sweep to close, and a superseded cascade withdrawal rides the terminal summary.
Deleted: Reconciliation 31. Recoverable Invocation Invariant 5.2 and Recoverable Invocation service identity 3 own it: the sweep writes under the recovery identity, and the reconciliation writes no event.
Deleted: Reconciliation 32. Recoverable Invocation reconcile step 3.5, Recoverable Invocation reconcile step 3.8 and Recoverable Invocation reconcile step 5.1 own it: an intent the sweep cannot close is escalated once and reported at risk.
Deleted: Reconciliation 33. Recoverable Invocation reconcile step 3.18 and Recoverable Invocation External check 10 own it.
Deleted: Reconciliation 34. Term decision probe and Recoverable Invocation act probe 6 own it: the recalled step ids come from the terminal summary the commit wrote.
Deleted: Reconciliation 36. Term decision probe and Term terminal summary own it: the rule reason is written on the chain record by the terminating commit.
Deleted: Reconciliation 37. Recoverable Invocation Primitive policy 11a, Recoverable Invocation Invariant 5.2 and Term withdrawal probe own it.
Deleted: Reconciliation 38. Action wiring 9 and Action wiring 12 own it: no withdrawal lacks its intent.
Deleted: Reconciliation 40. Recoverable Invocation act section 11 and Recoverable Invocation act section 12 own it: the sweep takes the act's critical section, and the composition holds no Lease (Composes 17).
Deleted: Reconciliation 41. Recoverable Invocation reconcile step 2.3 owns it.
Deleted: Reconciliation 42. Recoverable Invocation act section 15 owns it.
Deleted: Reconciliation 43. Recoverable Invocation reconcile step 3.8 and Recoverable Invocation Invariant 3.5a own it: an escalation carries the database candidates, and an outcome never does.
```

### Composition logic › Cascade

```
Deleted: Cascade 4. Composition state 6 and Recoverable Invocation Action wiring 6 own it: the cascade's withdrawals ride the terminal summary in the terminating act's outcome, and the act writes no other journal record.
Deleted: Cascade 5. Composition state 6 owns it: no cascade record exists to attest; the terminating act's outcome is attested at the invocation close under the caller's credential.
Deleted: Cascade 6. Recoverable Invocation Invariant 5.2 owns it: an outcome the sweep recovers carries the recovery identity's attestation, the caller in the acting actor reference.
Deleted: Cascade 9. Cascade 14 owns it: a temporal refusal fails the commit, so no terminal event carries a partial flag.
```

### Composition-level invariants › Invariant 1 — Chain completeness

```
  Deleted: Invariant 1.2. Action wiring 9 and Action wiring 12 own it: a refused submit or assign fails the initiation transaction whole, so no chain is closed short of its step list.
```

### Composition-level invariants › Invariant 7 — Chain terminal absorption

```
  Deleted: Invariant 6. Composes 5 owns it.
```

### Composition-level invariants › Invariant 8 — Declared fields are immutable

```
  Deleted: Invariant 8.2. Recoverable Invocation Invariant 4.1 owns it: no quarantine flag exists; the open initiation intent stands for it.
```

### Composition-level invariants › Invariant 10 — Authentication precedes commitment

```
  Deleted: Invariant 10.1. Recoverable Invocation Invariant 1.1 owns it: the chain record's write follows the invocation open, whose intent record verified the initiator's credential.
  Deleted: Invariant 10.2. Recoverable Invocation Invariant 1.1 owns it: the step write follows the invocation open, whose intent record verified the caller's credential.
  Deleted: Invariant 10.3. Recoverable Invocation Invariant 1.1 owns it: the chain set Withdrawn follows the invocation open, whose intent record verified the initiator's credential.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 4.2. Cascade 14 owns it: a temporal refusal fails the commit, so no Active assignment stands under a partial flag.
Deleted: Check 5.3. Recoverable Invocation Check 5.1 and Recoverable Invocation Check 5.2 own it: every record the recovery identity attests names an intent another actor attested.
Deleted: Check 5.4. Cascade 14 owns it: no partial flag names a call.
Deleted: Check 10.1. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 10.3. Recoverable Invocation Invariant 3.5a and Recoverable Invocation Check 6.5 own it: no outcome carries candidates, and an escalation's candidates match the database.
Deleted: Check 10.4. Recoverable Invocation Check 1.1 and Recoverable Invocation Invariant 3.2 own it.
Deleted: Check 10.5. Recoverable Invocation Check 3.1 owns it: an intent carrying no outcome is closed or escalated within the closure window.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Execution Contract Logic confinement 19 owns it: a decision's step write reads the invocation's now, so the terminal instant and the deciding step's decided instant one invocation writes are one instant (Scott, 2026-11-18 6:52 AM Central, "YYY", rounds/escalations.md 2026-11-18 12:52Z, item 2).
Deleted: Clock semantics 3. Execution Contract Logic confinement 19 owns it: the host injects the invocation's one reading at every constituent seam the invocation reaches, so an instant the composition passes and one it leaves blank are the same instant; a read's filter on an instant a record holds was never a pass (Term decision probe) (Scott, 2026-11-18 6:52 AM Central, "YYY", rounds/escalations.md 2026-11-18 12:52Z, item 2).
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for a decision's step write to run outside.
```
