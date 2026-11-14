---
title: Multi-Party Approval — history
nav_exclude: true
search_exclude: true
---

# Multi-Party Approval — history

The dated record of how [Multi-Party Approval](./multi-party-approval.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/multi-party-approval.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-24 — Rewritten in GRACE lang v0.61; forty of forty-one open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` (the quorum rule), `Reconciliation` (the recovery discipline, as four legs), `Cascade` and `Scope vocabulary` as the surfaces; invariant numbers 1 through 5 and 7 through 10 unchanged, Invariant 6 tombstoned to Composes 5; the seven acceptance checks renumbered by the invariant each tests, with the permission and constituent checks the prose lacked; the edge cases split into Non-goals and three Edge cases families. Choices the page left open, each decided by a standing rule: the invocation id the seam injects rides on every event and on the chain record, so the initiation intent joins its chain exactly (2026-08-29-e — *Intents pair with outcomes*); the routed vector defined for all four counts with P derived, a decision routed only by its decision intent, and a purged intent still recognized by its surviving action reference and actor through the event index (2026-08-29-a, -b, -c, -d, 2026-08-26-l); the position exported on every action that straddles a commit, because a re-run initiation is not refused (*A composition's own rejection arm carries the retry bit*); the retention-step arm and the retention-source invalid-request read back by invocation id and proceeding as landed (*A transcribed rejection arm keeps its payload*); the compensation window set against the liveness sum rather than the cadence alone (*Liveness is arithmetic*); the step-assignment pairing rebuilt through Assignment's history_for at any age (2026-08-29-m, 2026-08-26-i); the resolution reason declared on every arm (2026-08-26-g, 2026-08-29-g); a retried recall answered not-known closed with an anomaly mark (2026-08-26-n); and the extraction gate run on the recovery discipline, its verdict left to the higher-order composition test (2026-08-26-m). *Over:* the prose's step lists, a case list ordered a, b, d, c under *order of severity*, a terminal instant defined as *the first moment the rule fired* that two stamping sites contradicted, and an open finding the per-chain serialization had already closed. *Because:* the rules state each landing once; the formal line stays open because the model, not the page, is what it owes.

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

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it: an action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for a decision's step write to run outside.
```
