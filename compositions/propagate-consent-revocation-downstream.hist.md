---
title: Propagate Consent Revocation Downstream — history
nav_exclude: true
search_exclude: true
---

# Propagate Consent Revocation Downstream — history

The dated record of how [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/propagate-consent-revocation-downstream.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-24 — Rewritten in GRACE lang v0.61; nineteen of twenty-one open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole, its per-key serialization split into the consent exclusion and the pair exclusion because the grammar owns the noun *section* — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces; invariant numbers 1 through 8 unchanged; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and three Edge cases families, the two-instance retention entries joining `Retention asymmetry` as its fourth spec. Choices the page left open, each decided by a standing rule: *governed* defined as the record the composition's grant write made — every record of the instance under the reserved write surface — and Invariant 6 split into a floor and a liveness closure (2026-08-30-d); Consent's not-known at the revoke relayed as not-known with an index-anomaly finding rather than as a recording failure (2026-08-26-g — *make all things mean one thing*: recording-failure is a write that did not land); the gate's exposure and the retention policy reference's validation stated as rules (2026-08-30-f, 2026-08-26-b); the bound measured from the seam reading (2026-08-30-h); the knob collisions stated in the terms (2026-08-30-g); the pairing-key deviation declared and no refusal outcome added (2026-08-30-e — *as simple as possible without losing fidelity*); the expiry asymmetry restated on what this composition observes, not on how Consent expires (2026-08-27-c). **One defect fixed in this pass**: the invocation retried its grant event under the pair exclusion while the reconciliation compensated grant orphans under the consent exclusion, so the two could both land a grant event for one consent; the invocation now takes the consent exclusion once the consent id exists, and a grant candidate set whose retention policy references disagree is escalated rather than chosen (Action wiring 16; Reconciliation 29). *Over:* the prose's step lists, a lettered case list, and revision-history prose. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-21, newest first:

- 2026-08-27 — authentication-precedence gate, fresh reader — 5 foundational (3 corrected in-round, 2 routed and since closed), 9 refining/rhetorical routed (2 since closed)
- Final Critique 7's 7 refining and 3 rhetorical partly still open

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 15. Execution Contract Database 3 owns it.
Deleted: Composition state 22. Execution Contract Derived index 1 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 6. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 7. Recoverable Invocation sweep cadence 2 and 3 own it.
Deleted: Capability requirement 8. Term reconciliation run bound owns it: the run bound counts every write's landing.
Deleted: Capability requirement 10. Recoverable Invocation Instance start 4 and Instance start 5 own it: the worst closure against the closure window, and the retention floor.
Deleted: Capability requirement 11. Execution Contract Database 1 owns it.
Deleted: Capability requirement 12. Execution Contract Database 1 owns it: the composition names no retry span for the administration completion bound to cover.
Deleted: Capability requirement 15. Recoverable Invocation clock allowance owns it: one allowance, set at the instance, covering the widest pair of the clocks.
Deleted: Capability requirement 16. Execution Contract Database 2 owns it.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it.
Deleted: Capability requirement 18. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 19. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to lease.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 22. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion for a host to lack.
Deleted: Capability requirement 24. Execution Contract Database 3 owns it.
Deleted: Capability requirement 25. Execution Contract Database 3 owns it.
Deleted: Capability requirement 29. Recoverable Invocation Primitive policy 18 owns it for the sweep, and the write-ownership leg reads the sweep's run reading (Reconciliation 39).
Deleted: Capability requirement 33. Recoverable Invocation run bound owns it: the sweep's own, and the write-ownership leg runs inside it.
Deleted: Capability requirement 34. Recoverable Invocation Instance start 5 owns it: the retention floor.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 7. Recoverable Invocation Primitive policy 12 and Primitive policy 13 own it: the invocation open sizes the kind's largest record against the substrate's payload cap and refuses invalid-request for an act whose largest record would not fit.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Primitive policy 19 owns it for the intent of the two bound actions.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 41 owns it for the intent of the two bound actions.
Deleted: Audit arm 3. Recoverable Invocation Primitive policy 23 owns it for the intent of the two bound actions.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 43 owns it for the two bound actions; a single write is never retried either (Audit arm 8).
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Deleted: Audit arm 10. Execution Contract Database 1 owns it.
Deleted: Audit arm 11. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an outcome.
Deleted: Audit arm 12. Recoverable Invocation Primitive policy 30 owns it for the outcome of the two bound actions.
Deleted: Audit arm 14. Recoverable Invocation Invariant 8.3 owns it: recording-failure(intent) is a committed nothing.
Deleted: Audit arm 15. Recoverable Invocation Invariant 8.4 owns it: recording-failure(outcome) is a committed act whose record the sweep closes.
Deleted: Audit arm 17. Recoverable Invocation Primitive policy 42 owns it for the outcome of the two bound actions.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 6. Execution Contract Database 2 owns it.
Deleted: Action wiring 10. Consent Operation 10 owns it: the grant write stamps the grant instant from Consent's own now, and the expiry is the caller's, passed unchanged (Action wiring 9).
Deleted: Action wiring 15. Execution Contract Database 1 owns it.
Deleted: Action wiring 16. Execution Contract Database 1 owns it.
Deleted: Action wiring 20. Execution Contract Database 2 owns it.
Deleted: Action wiring 27. Execution Contract Database 2 owns it.
Deleted: Action wiring 43. Reconciliation 9 and Execution Contract Database 1 own it.
Deleted: Action wiring 44. Reconciliation 9 and Execution Contract Database 1 own it.
Deleted: Action wiring 45. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Action wiring 46. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Action wiring 47. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion to release.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 2. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Deleted: Reconciliation 5. Recoverable Invocation Invariant 7.3 and Recoverable Invocation Check 7.1 own it: the sweep excludes a purged intent, and propagation history purged stays an auditor's class (Check 3.4).
Deleted: Reconciliation 7. Execution Contract Database 2 owns it.
Deleted: Reconciliation 8. Execution Contract Database 2 owns it: the reconciliation's reads of a record and the writes they decide are one transaction, and the composition names no exclusion for another holder to hold.
Deleted: Reconciliation 9. Recoverable Invocation reconcile step 2.4 through 2.6 and Recoverable Invocation Invariant 2.1 own it: no closed invocation is written for again.
Deleted: Reconciliation 10. Recoverable Invocation Invariant 3.3 owns it, through the withdrawal probe: the pairing datum, the revocation instant, joins an intent to the record by equality.
Deleted: Reconciliation 12. Recoverable Invocation reconcile step 1.2 and Recoverable Invocation reconcile step 3.12 own it: the sweep writes only for an intent, and only what it read.
Deleted: Reconciliation 12a. Recoverable Invocation reconcile step 3.1 and Recoverable Invocation reconcile step 3.2 own it: the probe runs at every run while the intent is open.
Deleted: Reconciliation 13. The withdrawal probe owns it: its outcome data derives the propagation set at the intent's own position (Recoverable Invocation act probe 6).
Deleted: Reconciliation 14. Recoverable Invocation act probe 6 and Recoverable Invocation Invariant 5.3 own it: the probe re-derives the outcome's other fields from the database.
Deleted: Reconciliation 17. Recoverable Invocation Invariant 3.4 forbids it: the act probe pairs on a pairing datum by equality and never on a stamp within a window.
Deleted: Reconciliation 18. Execution Contract Database 1 owns it.
Deleted: Reconciliation 19. Execution Contract Database 1 owns it.
Deleted: Reconciliation 20. Recoverable Invocation Sweep never 1 and Recoverable Invocation Invariant 9.2 own it: the sweep writes no adopter state, and the grant rebuild reads a recovered grant event (Composition state 10).
Deleted: Reconciliation 21. Recoverable Invocation Invariant 3.5a and Recoverable Invocation reconcile step 3.8 through 3.10 own it: an escalation carries the database candidates, and an outcome never does.
Deleted: Reconciliation 24. Recoverable Invocation Invariant 5.1 and Recoverable Invocation reconcile step 3.2a own it: the recovery intent before any recovered outcome.
Deleted: Reconciliation 25. Recoverable Invocation reconcile step 3.2a owns it: the recovery intent's invocation id, intent event id, act key and plan.
Deleted: Reconciliation 26. Recoverable Invocation Invariant 5.2 and the service identity own it: the recovery identity is the binding's service identity.
Deleted: Reconciliation 27. Recoverable Invocation Invariant 5.2, Recoverable Invocation Primitive policy 11a and Term outcome shape own it: the recovered outcome carries the recovery flag, the acting actor reference and the intent event id.
Deleted: Reconciliation 28. Recoverable Invocation reconcile step 3.17 and Recoverable Invocation Primitive policy 29 own it: a closing-position write refused is left for the next run.
Deleted: Reconciliation 29. Recoverable Invocation reconcile step 3.5, step 3.8 through 3.10 and Recoverable Invocation Invariant 2.1 own it: an uncompensable cause is an escalation, once.
Deleted: Reconciliation 30. Recoverable Invocation reconcile step 3.20 and step 3.17 with Recoverable Invocation Invariant 5.1 own it: there is no escalation instant, and a closing the substrate refuses is surfaced as closure-at-risk or outcome-unrecordable.
Deleted: Reconciliation 31. Recoverable Invocation reconcile step 3.5a, Recoverable Invocation reconcile step 3.8a and Recoverable Invocation reconcile step 3.20 own it: an escalation carries its cause and its candidates.
Deleted: Reconciliation 32. Recoverable Invocation reconcile step 2.5 and Recoverable Invocation reconcile step 2.6 own it: only the invocation resolve supersedes an escalation.
Deleted: Reconciliation 33. Recoverable Invocation Invariant 2.1 owns it.
Deleted: Reconciliation 34. Recoverable Invocation reconcile step 3.17 and Recoverable Invocation reconcile step 3.23 own it.
Deleted: Reconciliation 35. Recoverable Invocation reconcile step 3.21, Recoverable Invocation reconcile step 5.9 and the findings register own it.
Deleted: Reconciliation 36. Recoverable Invocation Term hard alert, reconcile step 5.1 and Recoverable Invocation Primitive policy 40 own it.
Deleted: Reconciliation 37. Recoverable Invocation act probe 4, Recoverable Invocation act probe 5 and Recoverable Invocation reconcile step 3.13 own it for the sweep; Reconciliation 38 states it for the leg.
```

### Composition-level invariants › Invariant 2 — Grant audit coverage

```
  Deleted: Invariant 2.1. Recoverable Invocation Invariant 4.2 and Recoverable Invocation Check 3.1 own it: an intent is open, awaiting the sweep, or closed.
```

### Composition-level invariants › Invariant 3 — Revocation propagation completeness

```
  Deleted: Invariant 3.4. Recoverable Invocation Term hard alert and reconcile step 5.1 own it: the sweep alerts on every orphan, and an Invariant MUST NOT oblige an act (GRACE-lang Standard label 14).
  Deleted: Invariant 3.5. Recoverable Invocation Invariant 4.2 and Recoverable Invocation Check 3.1 own it: no intent stands open past the closure window.
  Deleted: Invariant 3.6. Recoverable Invocation Invariant 5.1 and Recoverable Invocation Invariant 5.2 own it: a recovered outcome is written behind a recovery intent under the service identity and carries the recovery flag.
```

### Composition-level invariants › Invariant 6 — Consent-record retention floor

```
  Deleted: Invariant 6.2. Invariant 6.1 owns it: the retention placement is inside the grant transaction (Action wiring 13), so a committed Consent record carries a consent retention.
```

### Composition-level invariants › Invariant 8 — Authentication precedes commitment

```
  Deleted: Invariant 8.1. Recoverable Invocation Invariant 1.1 owns it: the commit follows the intent, whose record verified the credential.
  Deleted: Invariant 8.2. Recoverable Invocation Invariant 1.1 owns it: the commit follows the intent, whose record verified the credential.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.1. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 3.5. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 3.6. Recoverable Invocation Check 1.1, Recoverable Invocation Check 2.5 and Recoverable Invocation Check 5.1 own it.
Deleted: Check 3.7. Recoverable Invocation reconcile step 3.5a and step 3.20 own it: an escalation carries its cause.
Deleted: Check 3.8. Recoverable Invocation Check 4.1 owns it.
Deleted: Check 3.9. Recoverable Invocation Check 4.1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Recoverable Invocation Primitive policy 5 owns it: every join pairs on the invocation id.
Deleted: Clock semantics 3. Recoverable Invocation Allowance 4 and Allowance 6 own it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 2 owns it: an action's reads and the writes they decide are one transaction, and the composition names no exclusion for [Processing Permitted] to take.
```
