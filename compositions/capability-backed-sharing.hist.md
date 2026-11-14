---
title: Capability-Backed Sharing — history
nav_exclude: true
search_exclude: true
---

# Capability-Backed Sharing — history

The dated record of how [Capability-Backed Sharing](./capability-backed-sharing.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/capability-backed-sharing.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-23 — Rewritten in GRACE lang v0.61; twenty-four of twenty-five open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration and Logic confinement both — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces; invariant numbers 1 through 4 and 6 unchanged, Invariant 5 tombstoned to Composes 5; the checks renumbered `Check 1.1` through `Check 6.7`, which ends the prose's missing check 6 (2026-08-29-a); `Non-goals` and `Edge cases` split, with `Atomic writes`, `Clock semantics` and `Concurrency` under the second; the Recipient term entry renamed Intended Recipient, since Selective Disclosure declares *recipient* and this page's concept is the one the allocator declared. The lines' fixes, as prescribed: the substrate's step carried on every transcription (2026-08-27-g); a diverged index entry rebuilt before proceeding and an irreconcilable one refused (2026-08-27-i, 2026-08-29-h); the disclosure reading named as what stamps the marker and the event (2026-08-27-j); verification presented with the original payload, modulo the unsealed tail (2026-08-27-k, 2026-08-29-e); the substrate's own partials named as the substrate's (2026-08-27-l); the grammar stated once, read both ways (2026-08-27-m); the authorization event carrying the effective ttl, not an expiry instant no step read (2026-08-29-b); the outcome-position refusal naming the orphan (2026-08-29-d); compensation lateness measured between two substrate recording instants (2026-08-29-f); the past-horizon rebuild claim withdrawn (2026-08-29-g); [Sharing Disclosures]' invalid-query arm (2026-08-29-i); the descriptor capped at this layer, caller fault split from deployment fault (2026-08-29-j); concurrency weakened to at most one (2026-08-29-l); revocation's inputs listed and revocation deliberately ungated by provenance, since revocation is the unattested orphan's recovery (2026-08-29-m); the Summary's *permanently* narrowed, acronyms glossed at first use, Invariant 1 cited to Capability's contract rather than its model, and the history narration moved out of the rules (2026-08-27-n through q, 2026-08-29-k, p, q). *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. The model line stays open (2026-08-29-r). The rewrite also removed a contradiction the prose carried against itself — its wiring-decision section still put the redemption inside the transaction that its own step 4 and edge cases said it could not be in; Wiring decision 4 and Atomic writes 2 now say it once.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Capability-Backed Sharing](./capability-backed-sharing.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 11. Execution Contract Database 1 owns it.
Deleted: Composition state 15. Execution Contract Database 3 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 7. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 8. Recoverable Invocation sweep cadence 2 and Recoverable Invocation sweep cadence 3 own it.
Deleted: Capability requirement 9. Recoverable Invocation Instance start 4 owns it: the worst closure against the closure window, the sweep's run counted in it.
Deleted: Capability requirement 10. Execution Contract Database 1 owns it.
Deleted: Capability requirement 11. Execution Contract Database 1 owns it.
Deleted: Capability requirement 12. Recoverable Invocation Instance start 4 owns it: a blank closure window does not pass, and Capability requirement 24 refuses a start on the composition's own required settings.
Deleted: Capability requirement 13. Execution Contract Database 1 owns it: the composition names no redemption completion bound for a deployment to leave blank.
Deleted: Capability requirement 19. Recoverable Invocation Instance start 5 owns it: the retention floor.
Deleted: Capability requirement 20. Recoverable Invocation run bound owns it: the sweep's own, and the write-ownership leg runs inside it.
Deleted: Capability requirement 21. Recoverable Invocation run bound and Recoverable Invocation Instance start 7 own it.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Primitive policy 19 owns it for the intent of the three bound actions.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 23 owns it for the intent of the three bound actions.
Deleted: Audit arm 3. Execution Contract Database 1 owns it.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 36 owns it: a record the read-back finds is landed.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Deleted: Audit arm 6. Recoverable Invocation Primitive policy 41 owns it for the intent of the three bound actions.
Deleted: Audit arm 7. Recoverable Invocation Primitive policy 43 owns it.
Deleted: Audit arm 8. Recoverable Invocation commit 8d and Recoverable Invocation Primitive policy 31 own it: an outcome that does not land answers recording-failure(outcome), which carries no orphan reference.
Deleted: Audit arm 9. Execution Contract Database 2 owns it.
Deleted: Audit arm 10. Recoverable Invocation Primitive policy 19, Recoverable Invocation Primitive policy 31 and Recoverable Invocation reconcile step 3.18 own it: an invalid-credential lands by the record's position.
Deleted: Audit arm 11. Recoverable Invocation reconcile step 3.19 owns it.
Deleted: Audit arm 12. Recoverable Invocation Invariant 8.3 owns it: recording-failure(intent) is a committed nothing.
Deleted: Audit arm 13. Recoverable Invocation Invariant 8.4 owns it: recording-failure(outcome) is an act that may exist, whose record the sweep closes.
Deleted: Audit arm 14. Recoverable Invocation Invariant 8.4 owns it.
Deleted: Audit arm 15. Recoverable Invocation Primitive policy 35 owns it: the read-back matches by invocation id, not by intent event id.
Deleted: Audit arm 16. Recoverable Invocation Primitive policy 42 owns it: the hard alert on an invalid-request from the substrate.
Deleted: Audit arm 18. Execution Contract Database 1 owns it.
Deleted: Audit arm 19. Recoverable Invocation Primitive policy 41 owns it: an invalid-request(step-3) at the intent answers invalid-request.
Deleted: Audit arm 20. Recoverable Invocation Primitive policy 42 owns it.
Deleted: Audit arm 21. Recoverable Invocation Primitive policy 27 and Recoverable Invocation Primitive policy 28 own it: an invalid-request(step-4) is read back by invocation id.
Deleted: Audit arm 22. Recoverable Invocation refuse step 3.5 through 3.8 own it: a refusal record that does not land answers recording-failure(refusal, constituent_code) with the intent left open.
Deleted: Audit arm 23. Recoverable Invocation's Action wiring table owns it: recording-failure(refusal, constituent_code) is a refusal whose attempt the sweep records.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 1. Recoverable Invocation Action wiring 4 and Recoverable Invocation Invariant 1.1 own it: the allocate follows the invocation open, whose intent record verified the allocator's credential.
Deleted: Action wiring 3. Recoverable Invocation Primitive policy 10 owns it.
Deleted: Action wiring 6. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 7. Recoverable Invocation refuse step 3.1 and Action wiring 5 own it: a refused allocate writes the intent and its sharing.authorize.refused record, and nothing else.
Deleted: Action wiring 9. Execution Contract Database 1 owns it.
Deleted: Action wiring 25. Recoverable Invocation Action wiring 4 owns it: the redeem follows the invocation open.
Deleted: Action wiring 54. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 27. Recoverable Invocation refuse step 3.1 owns it: the refusal record is sharing.disclosure.refused, carrying the redemption failure as the constituent code.
Deleted: Action wiring 30. Action wiring 29 and Capability requirement 22 own it, reversed: the disclosure reading is passed as disclosed_at, the disclosure probe's pairing datum.
Deleted: Action wiring 55. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 33. Execution Contract Database 1 owns it.
Deleted: Action wiring 34. Action wiring 31 owns it: a Selective Disclosure refusal consumes no use, so no unfulfilled redemption exists to seal.
Deleted: Action wiring 37. Execution Contract Database 1 owns it.
Deleted: Action wiring 39. Recoverable Invocation Action wiring 4 and Recoverable Invocation Invariant 1.1 own it: the revoke follows the invocation open, whose intent record verified the revoker's credential.
Deleted: Action wiring 44. Execution Contract Constituent failure 1 owns it.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 3. Execution Contract Database 1 owns it.
Deleted: Wiring decision 4. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Deleted: Reconciliation 4. Recoverable Invocation Invariant 5.2 and Recoverable Invocation service identity 3 own it: the sweep writes under the recovery identity, and the leg writes no event.
Deleted: Reconciliation 5. Recoverable Invocation Invariant 5.1 and Recoverable Invocation reconcile step 3.2a own it: the recovery intent before any recovered outcome.
Deleted: Reconciliation 6. Recoverable Invocation reconcile step 3.2a owns it: the kind's recovery_intended record carries the invocation id, the intent event id, the act key and the plan.
Deleted: Reconciliation 7. Recoverable Invocation Invariant 5.2, Recoverable Invocation Primitive policy 11a and Recoverable Invocation Term recovered outcome payload own it: the recovered outcome carries the recovery flag, the acting actor reference and the intent event id.
Deleted: Reconciliation 8. Term authorization probe, Term disclosure probe, Term revocation probe, Recoverable Invocation act probe 6 and Recoverable Invocation Invariant 5.3 own it: the probe re-derives the outcome's fields from the constituent records.
Deleted: Reconciliation 9. Recoverable Invocation reconcile step 3.2 and Recoverable Invocation reconcile step 2.4 through 2.6 own it: a committed probe closes the intent with the outcome, after a re-read under the critical section.
Deleted: Reconciliation 28. Recoverable Invocation Sweep never 1, Recoverable Invocation Invariant 9.2 and Composition state 16 own it: the sweep writes no adopter state, and the rebuild seals the marker from a recovered disclosure event.
Deleted: Reconciliation 10. Term disclosure probe and Recoverable Invocation act probe 6 own it: a recovered disclosure outcome carries the disclosure record's fields and the allocator Capability's read answers.
Deleted: Reconciliation 11. Recoverable Invocation reconcile step 1.1, Recoverable Invocation reconcile step 1.2 and Recoverable Invocation reconcile step 3.1 own it: the sweep runs the act probe for every open intent.
Deleted: Reconciliation 12. Recoverable Invocation reconcile step 3.12, Recoverable Invocation act probe 6 and Recoverable Invocation Invariant 5.3 own it: the sweep writes only what the probe read.
Deleted: Reconciliation 13. Action wiring 31 owns it: a consumed use and its disclosure record commit together, so no remainder exists.
Deleted: Reconciliation 14. Recoverable Invocation Invariant 3.5a owns it: an outcome never carries candidates.
Deleted: Reconciliation 15. Recoverable Invocation reconcile step 3.5 and Recoverable Invocation Invariant 4.9 own it: an intent whose invocation consumed nothing is escalated, and an operator abandons it.
Deleted: Reconciliation 16. Action wiring 31 owns it: no remainder exists to seal from.
Deleted: Reconciliation 17. Term authorization probe and Recoverable Invocation Invariant 3.3 own it: the pairing datum, the allocation instant, joins an intent to its capability by equality.
Deleted: Reconciliation 18. Composition state 6 and Action wiring 18 own it: a recovered authorization binds no capability-to-sharing entry, so its token is refused not-authorized-sharing and lapses at its ttl, and nothing is revoked.
Deleted: Reconciliation 19. Recoverable Invocation reconcile step 3.8 through 3.10 own it.
Deleted: Reconciliation 27. Recoverable Invocation reconcile step 3.5 and Recoverable Invocation Invariant 4.9 own it: an authorization intent that allocated nothing is escalated, and an operator abandons it.
Deleted: Reconciliation 20. Term revocation probe, Recoverable Invocation reconcile step 3.2 and Reconciliation 33 own it: a revocation an intent carries is closed by the sweep, and one no intent carries opens a write-ownership finding.
Deleted: Reconciliation 21. Term revocation probe and Recoverable Invocation act probe 6 own it.
Deleted: Reconciliation 22. Recoverable Invocation Invariant 2.1 owns it, and Capability's already-terminal refuses a second revoke of one token.
Deleted: Reconciliation 23. Recoverable Invocation reconcile step 3.5, Recoverable Invocation reconcile step 3.8, Recoverable Invocation reconcile step 3.21 and Recoverable Invocation reconcile step 5.1 own it.
Deleted: Reconciliation 24. Recoverable Invocation Invariant 7.2, Recoverable Invocation Instance start 5 and Recoverable Invocation reconcile step 5.9 own it.
Deleted: Reconciliation 25. Recoverable Invocation Invariant 7.2 and Recoverable Invocation reconcile step 1.2 own it.
Deleted: Reconciliation 26. Composes 6 owns it: the leg writes no event, so it compensates nothing, and a substrate partial is the substrate's own reconciliation's.
```

### Composition-level invariants › Invariant 2 — Disclosure-accountability binding

```
  Deleted: Invariant 2.4. Recoverable Invocation Invariant 4.2 and Recoverable Invocation Check 3.1 own it: an intent whose invocation died is closed within the closure window, by an outcome on a committed probe, or escalated.
  Deleted: Invariant 2.5. Recoverable Invocation Instance start 4 through 8 and Recoverable Invocation Check 4.1 own it: the instance does not start without its bounds.
```

### Composition-level invariants › Invariant 3 — Allocation-authorization binding

```
  Deleted: Invariant 3.4. Recoverable Invocation Invariant 4.2 owns it: an authorization intent whose invocation died is closed within the closure window, by an outcome on a committed probe, or escalated.
```

### Composition-level invariants › Invariant 6 — Authentication precedes commitment at the actions that name an actor

```
  Deleted: Invariant 6.1. Recoverable Invocation Invariant 1.1 owns it: the allocate follows the invocation open, whose intent record verified the allocator's credential.
  Deleted: Invariant 6.2. Recoverable Invocation Invariant 1.1 owns it: the revoke follows the invocation open, whose intent record verified the revoker's credential.
  Deleted: Invariant 5. Composes 5 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.4. Check 2.3 owns it.
Deleted: Check 3.1. Recoverable Invocation Check 3.1 and Recoverable Invocation Check 1.1 own it: every intent is closed or escalated within the closure window, and every outcome names its intent.
Deleted: Check 3.5. Check 3.1 owns it.
Deleted: Check 4.3. Action wiring 31 owns it: a consumed use and its disclosure record commit together, so no remainder exists.
Deleted: Check 5.1. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 5.2. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 5.3. Check 5.1 owns it.
Deleted: Check 5.4. Term revocation probe and Recoverable Invocation reconcile step 3.5 own it: a revocation intent is closed by its outcome, its refusal record, a recovered outcome or an escalation.
Deleted: Check 5.5. Action wiring 24 owns it.
Deleted: Check 6.1. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 6.2. Action wiring 31 owns it: no remainder exists to seal from.
Deleted: Check 6.3. Recoverable Invocation Check 6.1 owns it.
Deleted: Check 6.4. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 6.5. Reconciliation 23 owns it.
Deleted: Check 6.6. Execution Contract Database 1 owns it.
Deleted: Check 6.7. Reconciliation 25 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 6. Execution Contract Database 3 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 3. Capability requirement 22 and Term disclosure probe own it, reversed: the disclosure reading is the disclosure record's disclosure instant, and the probe compares them by equality.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```
