---
title: Chain of Custody — history
nav_exclude: true
search_exclude: true
---

# Chain of Custody — history

The dated record of how [Chain of Custody](./chain-of-custody.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/chain-of-custody.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-24 — Rewritten in GRACE lang v0.61; forty-one of forty-three open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole, the per-chain section renamed the chain exclusion because the grammar owns the noun *section* — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with the verdict classes as their own `Verdict` family; invariant numbers 1 through 5 and 7 unchanged, Invariant 6 tombstoned to Composes 5; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and five Edge cases families. Choices the page left open, each decided by a standing rule: the blank credential answered invalid-credential in every action (2026-08-26-e, -r, 2026-08-30-j — *make all things mean one thing*); binding-unknown given a clock-free predicate — an unbound entry earlier than an entry whose event is already purged — and read as a durability finding in the proof and the checks alike (2026-08-30-a, -b, 2026-08-26-i, -u); the substrate's unverifiable reasons relayed unchanged and its compensation-window qualifier carried beside the verification, never in the retention state (2026-08-26-h, -p, -q); the reconciliation's window and cadence given names of their own, apart from the substrate's knobs (2026-08-30-l); the metadata taken off every audit write, and so off the caps (2026-08-26-v — *as simple as possible without losing fidelity*); the purged half named against Erasure Tombstone with the persist-at-purge alternative dropped (2026-08-30-c — *generalize nothing*); and one genesis pairing key, stated once (2026-08-30-n). *Over:* the prose's step lists, a verdict with three unlanded outcomes, and an alternative that rode a cascade the composition does not wrap. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-20, newest first:

- 2026-08-26 authentication-precedence gate — 1 foundational routed (since closed), 2 foundational and 8 refining/rhetorical corrected in-round, 7 refining and 5 rhetorical routed (1 refining since closed)
- Final Critique 7's 2 other foundational (since closed), 7 refining and 4 rhetorical also routed

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Chain of Custody](./chain-of-custody.md) may carry it again.

### Composes

```
Deleted: Composes 8. Composes 9 owns it.
Deleted: Composes 11. Recoverable Invocation Action wiring 4 and Action wiring 6 own it: a bound custody action writes its intent, outcome and refusal records through the invocation open, close and refuse.
```

### Composition logic › Composition state

```
Deleted: Composition state 12. Execution Contract Database 3 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 7. Execution Contract Logic confinement 15 owns it: a required setting blank keeps the instance from starting.
Deleted: Capability requirement 8. Execution Contract Database 1 owns it.
Deleted: Capability requirement 9. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 10. Recoverable Invocation sweep cadence 2 and sweep cadence 3 own it.
Deleted: Capability requirement 11. Recoverable Invocation run bound owns it: the sweep's own, and the write-ownership leg runs inside it.
Deleted: Capability requirement 12. Recoverable Invocation Instance start 4 owns it: the worst closure against the closure window.
Deleted: Capability requirement 13. Execution Contract Database 3 owns it.
Deleted: Capability requirement 14. Execution Contract Database 3 owns it.
Deleted: Capability requirement 16. Execution Contract Database 2 owns it.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 18. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 19. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to lease.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for a host to lack.
Deleted: Capability requirement 27. Recoverable Invocation Primitive policy 18 owns it for the sweep, and the write-ownership leg reads the sweep's run reading (Reconciliation 31).
Deleted: Capability requirement 29. Recoverable Invocation Instance start 5 owns it: the retention floor.
Deleted: Capability requirement 30. Recoverable Invocation clock allowance owns it: one allowance, set at the instance, covering the widest pair of the clocks.
Deleted: Capability requirement 31. Recoverable Invocation clock allowance and Recoverable Invocation Instance start 4 own it: the allowance is the instance's setting, and a start condition reading a blank one does not pass.
Deleted: Capability requirement 32. Recoverable Invocation run bound owns it: the sweep's own, and the write-ownership leg runs inside it.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 14. Recoverable Invocation Term outcome shape and Recoverable Invocation Check 2.5 own it: the invocation close writes the outcome under the intent's actor reference, which Primitive policy 16 and Action wiring 20 make the acting custodian.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Primitive policy 19 owns it for the intent of the five bound actions.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 41 owns it for the intent of the five bound actions.
Deleted: Audit arm 3. Recoverable Invocation Primitive policy 23 owns it for the intent of the five bound actions.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 43 owns it for the five bound actions.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Deleted: Audit arm 6. Recoverable Invocation Primitive policy 27 owns it: the outcome's invalid-request(step-4) is read back by invocation id.
Deleted: Audit arm 7. Recoverable Invocation Primitive policy 35 owns it: the read-back matches by invocation id over the delta range, not by action reference and intent event id over the log.
Deleted: Audit arm 8. Recoverable Invocation Primitive policy 35 owns it.
Deleted: Audit arm 9. Recoverable Invocation Primitive policy 28 owns it.
Deleted: Audit arm 10. Recoverable Invocation Primitive policy 28 owns it: a found read-back returns success with a hard alert.
Deleted: Audit arm 11. Execution Contract Database 1 owns it.
Deleted: Audit arm 12. Execution Contract Database 1 owns it.
Deleted: Audit arm 13. Execution Contract Database 1 owns it.
Deleted: Audit arm 14. Recoverable Invocation reconcile step 2.4 through 2.6 and Execution Contract Database 1 own it.
Deleted: Audit arm 15. Recoverable Invocation reconcile step 2.4 through 2.6 and Execution Contract Database 1 own it.
Deleted: Audit arm 16. Execution Contract Database 2 owns it.
Deleted: Audit arm 17. Execution Contract Database 2 owns it: a custody action's attestations read the actor registry inside one transaction, so no invocation re-attests an outcome.
Deleted: Audit arm 18. Execution Contract Database 1 owns it: a custody action's writes commit together, so no invocation retries an outcome.
Deleted: Audit arm 19. Recoverable Invocation commit 8d, Recoverable Invocation Primitive policy 30 and Recoverable Invocation Primitive policy 31 own it: an outcome that does not land answers recording-failure(outcome).
Deleted: Audit arm 20. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Audit arm 21. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Audit arm 22. Execution Contract Database 2 owns it: a custody action's reads of a chain and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Audit arm 23. Recoverable Invocation Invariant 8.3 owns it: recording-failure(intent) is a committed nothing.
Deleted: Audit arm 24. Recoverable Invocation Invariant 8.4 owns it: recording-failure(outcome) is an act that may exist, whose record the sweep closes.
Deleted: Audit arm 25. Recoverable Invocation Primitive policy 41 owns it for the intent of the five bound actions.
Deleted: Audit arm 26. Recoverable Invocation Primitive policy 42 owns it: the hard alert on the outcome's invalid-request below step-4.
Deleted: Audit arm 27. Recoverable Invocation Primitive policy 31 owns it.
Deleted: Audit arm 28. Recoverable Invocation Primitive policy 42 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 1. Recoverable Invocation Action wiring 4 and Recoverable Invocation Invariant 1.1 own it: the commit follows the invocation open, whose intent record verified the credential.
Deleted: Action wiring 2. Primitive policy 16 and Action wiring 12, 20, 27, 29 and 31 own it.
Deleted: Action wiring 3. Recoverable Invocation Primitive policy 10 owns it.
Deleted: Action wiring 4. Recoverable Invocation Composes 1 owns it: a record carries only the substrate's stamps, and the pairing datum an intent carries is the adopter's parameter, no stamp.
Deleted: Action wiring 6. Execution Contract Database 2 owns it.
Deleted: Action wiring 7. Action wiring 8 and Execution Contract Constituent failure 1 own it: a Provenance storage-failure is a pre-commit arm, closed through the invocation refuse and answered storage-failure.
Deleted: Action wiring 10. Execution Contract Database 1 owns it.
Deleted: Action wiring 22. Action wiring 63 and Action wiring 65 own it: the transfer transaction re-reads the holder and refuses a holder other than the resolved custodian, so the committed entry's outgoing custodian is the resolved custodian.
Deleted: Action wiring 23. Execution Contract Database 2 owns it.
Deleted: Action wiring 24. Action wiring 65 owns it: a holder changed since the resolution is refused not-current-custodian inside the transfer transaction, so no transfer answers principal-divergence.
Deleted: Action wiring 25. Action wiring 65 owns it: a holder changed since the resolution is refused not-current-custodian inside the transfer transaction, so no transfer answers principal-divergence.
Deleted: Action wiring 60. Recoverable Invocation Invariant 8.3 and Recoverable Invocation Invariant 8.4 own it: a refusal commits no custody entry, and recording-failure(outcome) is an answer whose act may exist.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 1. Invariant 1.1 and Invariant 4.3 own it: the outcome event of a settled carried entry whose carrying intent stands neither open, escalated, abandoned nor refused, and no second invocation-written one.
Deleted: Wiring decision 2. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Scheduled leg 1 and Recoverable Invocation sweep cadence 2 own it: the sweep runs at every process start, and the reconciliation runs beside it (Reconciliation 2, Reconciliation 31).
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Deleted: Reconciliation 5. Execution Contract Database 2 owns it.
Deleted: Reconciliation 6. Execution Contract Database 2 owns it: the reconciliation's reads of a chain and the writes they decide are one transaction, and the composition names no exclusion for another holder to hold.
Deleted: Reconciliation 8. Recoverable Invocation reconcile step 1.1, step 1.2 and step 3.1 own it: the sweep runs the act probe for every open intent.
Deleted: Reconciliation 9. Recoverable Invocation commit 2 and Recoverable Invocation reconcile step 3.5 own it: a pre-commit arm closes through the invocation refuse, and an intent whose invocation died before its commit is escalated for an operator to abandon.
Deleted: Reconciliation 10. Recoverable Invocation Invariant 3.3 owns it, through the originate probe and the step probe: the pairing datum, the entry's recording instant, joins an intent to its entry by equality.
Deleted: Reconciliation 12. Recoverable Invocation reconcile step 1.2 and Recoverable Invocation reconcile step 3.12 own it: the sweep writes only for an intent, and only what it read.
Deleted: Reconciliation 13. Recoverable Invocation Invariant 3.5a and Recoverable Invocation reconcile step 3.8 through 3.10 own it: an escalation carries the database candidates, and an outcome never does.
Deleted: Reconciliation 14. Recoverable Invocation reconcile step 3.8 through 3.10 own it.
Deleted: Reconciliation 15. Recoverable Invocation Invariant 3.5a owns it.
Deleted: Reconciliation 16. Term step probe and Recoverable Invocation Invariant 3.3 own it: a transferred entry pairs to its intent by the pairing datum, as every other entry does.
Deleted: Reconciliation 17. Term originate probe and Recoverable Invocation Deviation 4b own it: the genesis lookup is the originate probe's read.
Deleted: Reconciliation 18. Recoverable Invocation Deviation 4c and Recoverable Invocation reconcile step 3.8 own it: with no genesis lookup the originate probe answers undecidable, and the sweep escalates the intent.
Deleted: Reconciliation 19. Action wiring 65 and Reconciliation 11 own it: the transfer transaction refuses a holder changed since the resolution, so no committed transfer's outgoing custodian differs from its intent's, and a transferred entry no intent carries opens a write-ownership finding.
Deleted: Reconciliation 20. Recoverable Invocation reconcile step 1.2 owns it: a transferred entry no intent carries is never closed by the sweep.
Deleted: Reconciliation 21. Recoverable Invocation Invariant 5.1 and Recoverable Invocation reconcile step 3.2a own it: the recovery intent before any recovered outcome.
Deleted: Reconciliation 22. Recoverable Invocation Invariant 5.2 and the service identity own it: the recovery identity is the bindings' service identity.
Deleted: Reconciliation 23. Recoverable Invocation Invariant 5.2, Recoverable Invocation Primitive policy 11a and Recoverable Invocation Term outcome shape own it: the recovered outcome carries the recovery flag, the acting actor reference and the intent event id.
Deleted: Reconciliation 24. Term step probe, Recoverable Invocation act probe 6 and Recoverable Invocation Invariant 5.3 own it: the probe re-derives the outcome's fields from the entry.
Deleted: Reconciliation 25. Recoverable Invocation reconcile step 2.4 through 2.6 own it: the sweep re-reads the invocation's closings under the critical section before it writes.
Deleted: Reconciliation 26. Recoverable Invocation reconcile step 2.5 and step 2.6 own it: an invocation already closed is not written for again, and the binding rebuild binds its outcome (Composition state 7).
Deleted: Reconciliation 27. Recoverable Invocation Sweep never 1 and Recoverable Invocation Invariant 9.2 own it: the sweep writes no adopter state, and the binding rebuild reads a recovered outcome event (Term binding rebuild).
Deleted: Reconciliation 28. Recoverable Invocation reconcile step 3.5, step 3.8 and step 5.1 own it: an intent the sweep cannot close is escalated once and reported at risk.
Deleted: Reconciliation 29. Recoverable Invocation Invariant 2.1 and Recoverable Invocation journal 3 own it: one escalation record per invocation, of the kind's own vocabulary.
```

### Composition-level invariants › Invariant 1 — Attributed custody

```
  Deleted: Invariant 1.3. Recoverable Invocation Invariant 5.2, Recoverable Invocation Invariant 5.4 and Recoverable Invocation Term outcome shape own it: an outcome the sweep wrote carries the service identity's attestation and one an operator wrote the operator's, each with the recovery flag and the acting custodian as the acting actor reference.
  Deleted: Invariant 1.4. Recoverable Invocation Invariant 3.1, Recoverable Invocation Check 1.1 and Recoverable Invocation Primitive policy 11a own it: every outcome names its intent by the invocation id and the intent event id, the intent attested under the actor the outcome names.
```

### Composition-level invariants › Invariant 4 — Binding bijection

```
  Deleted: Invariant 4.2. Recoverable Invocation Invariant 4.2 and Recoverable Invocation Check 3.1 own it: an intent whose invocation died is closed within the closure window, by an outcome on a committed probe (Recoverable Invocation reconcile step 3.2), or escalated.
  Deleted: Invariant 4.5. Recoverable Invocation reconcile step 3.5, Recoverable Invocation reconcile step 3.8 and Reconciliation 11 own it: an intent the sweep cannot close is escalated, and an entry no intent carries opens a write-ownership finding.
  Deleted: Invariant 4.6. Reconciliation 11 owns it: a transferred entry no intent carries opens a write-ownership finding, and the sweep never closes it.
```

### Composition-level invariants › Invariant 7 — Authentication precedes commitment

```
  Deleted: Invariant 7.1. Recoverable Invocation Invariant 1.1 owns it: the commit follows the invocation open, whose intent record verified the acting custodian's credential.
  Deleted: Invariant 6. Composes 5 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.4. Recoverable Invocation Check 2.5 owns it: an outcome carrying the recovery flag is the sweep's or an operator's shape.
Deleted: Check 1.5. Recoverable Invocation service identity 3 and Recoverable Invocation Check 2.5 own it.
Deleted: Check 2.2. Verdict 12 owns it.
Deleted: Check 5.4. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Check 5.5. Reconciliation 11 owns it.
Deleted: Check 5.6. Recoverable Invocation Check 4.1 owns it.
Deleted: Check 5.7. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 5.8. Recoverable Invocation Check 4.1 owns it.
Deleted: Check 6.1. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 6.2. Reconciliation 9 owns it.
Deleted: Check 6.3. Check 6.1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 4. Execution Contract Database 2 owns it.
Deleted: External check 5. Execution Contract Database 3 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 3. Recoverable Invocation Allowance 4 and Recoverable Invocation Allowance 6 own it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```
