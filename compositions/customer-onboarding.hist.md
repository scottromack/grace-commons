---
title: Customer Onboarding — history
nav_exclude: true
search_exclude: true
---

# Customer Onboarding — history

The dated record of how [Customer Onboarding](./customer-onboarding.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/customer-onboarding.md`.

## Decisions

Entries that record a migration or a regeneration rather than a turn the pattern took.

- **2026-09-14 — Rewritten in GRACE lang v0.41.** *Chose:* 180.5 KB of prose replaced by labelled rules across fifteen families, eight invariant numbers unchanged, thirty-eight of thirty-nine Ledger lines closed by the rewrite. *Over:* a mechanical transliteration that would have carried the page's four internal contradictions into the rule surface. *Because:* a defect the rewrite finds is repaired in the pass that finds it; the repairs are named in the entries above and in the commit that lands this.
- **2026-09-28 — What the cold regeneration met, restored.** *Chose:* a clearance forbidden to drop a trigger its record does not name (Action wiring 106), where the rule had forbidden emptying the set — which every healthy clearance does; the external path's unanswered read answered state-unavailable (Action wiring 154), as the trigger and the gate already answer it; and position defined by what the rules use it for — whether a constituent write had committed — rather than by which record failed, which eleven rules contradicted, Action wiring 17 and 62 among them. *Over:* the 2026-09-14 rewrite's readings. *Because:* the prose said *never clear the set*, meaning never sweep it wholesale, and the rewrite made it a prohibition the page's own walkthrough breaks; and a read with no answer had no landing at initiation.
- **2026-11-10 — The model regenerated and the vocabulary switched with the composition of Recoverable Invocation.** *Chose:* `customer-onboarding.tla` re-derived over the split arc (one party, two adverse triggers, three invocations, the suspension, clearance and closure transactions with their re-reads, Recoverable Invocation's sweep and an operator as contracts, one outside write and the reconciliation), its counter retired and its one twin re-pointed, nine twins and seven reachability probes added; and the fifteen `customer-onboarding.*` event classes the page wrote before it bound its act kinds named as pre-switch records the rebuild reads as their counterparts (Composition state 52, Term pre-switch record, Term counterpart). *Over:* keeping the counter beside the new arc, which would have checked a coupling no action of the page performs any longer; and dropping the old classes from every rule, which would have left a case older than the switch unrebuildable inside its binding floor. *Because:* the turn itself is the 2026-11-10 entry of the page's Decisions; this records what it regenerated. The first run of the re-derived model found the clearance's in-flight race, cured on the page in the same unit (Action wiring 164, 165).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Customer Onboarding](./customer-onboarding.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 46. Composition state 47 owns it: the entry of a closed case stands, since the composition never drops one.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 4. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 6. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 24. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 25. Recoverable Invocation sweep cadence 2 and Recoverable Invocation sweep cadence 3 own it.
Deleted: Capability requirement 26. Recoverable Invocation run bound owns it: the sweep's own, and the reconciliation runs inside it.
Deleted: Capability requirement 27. Recoverable Invocation Instance start 4 owns it: the worst closure against the closure window, the sweep's run counted in it.
Deleted: Capability requirement 32. Primitive policy 20 went with its cap: the trigger sets ride the intents in full, bounded by Audit Trail's payload cap (Capability requirement 31).
Deleted: Capability requirement 44. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 46. Recoverable Invocation Instance start 5 owns it: the retention floor.
Deleted: Capability requirement 47. Recoverable Invocation clock allowance owns it: the pairing datum is injected into every constituent's seam (Capability requirement 48), so no recovery comparison reads two clocks.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 20. Recoverable Invocation Primitive policy 12 and Primitive policy 13 own it: an intent whose data exceeds Audit Trail's payload cap, the trigger sets in full included, refuses invalid-request at the open.
```

### Composition logic › Identity

```
Deleted: Identity 10. Recoverable Invocation Primitive policy 9 owns it.
Deleted: Identity 11. Recoverable Invocation Primitive policy 10 owns it.
Deleted: Identity 13. Recoverable Invocation Primitive policy 11a owns it.
Deleted: Identity 14. Recoverable Invocation Primitive policy 5 and Recoverable Invocation Invariant 3.2 own it: a journal join pairs on the invocation id.
Deleted: Identity 15. Recoverable Invocation Invariant 3.2 and Recoverable Invocation act probe 3a own it.
Deleted: Identity 16. Recoverable Invocation Primitive policy 5 owns it: a journal join pairs on the invocation id and no other field.
Deleted: Identity 17. Recoverable Invocation journal 2 owns it: a trigger's intent is the adverse trigger kind's or the periodic review kind's own intended record.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Action wiring 4 and Recoverable Invocation Invariant 1.1 own it for the intent of the seven act kinds.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 19 owns it.
Deleted: Audit arm 3. Recoverable Invocation Primitive policy 41 owns it.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 23 owns it.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Deleted: Audit arm 6. Execution Contract Database 1 owns it.
Deleted: Audit arm 7. Recoverable Invocation Invariant 4.1 owns it: an intent stands open until a closing names its invocation, and the sweep closes it.
Deleted: Audit arm 8. Execution Contract Database 2 owns it.
Deleted: Audit arm 9. Recoverable Invocation Primitive policy 42 owns it.
Deleted: Audit arm 10. Recoverable Invocation Primitive policy 29 through 31 own it: an outcome that does not land answers recording-failure(outcome).
Deleted: Audit arm 11. Recoverable Invocation Invariant 8.3 owns it: recording-failure(intent) is a committed nothing, and the caller may retry.
Deleted: Audit arm 12. Recoverable Invocation Invariant 8.4 owns it: recording-failure(outcome) is an act that may exist, whose record the sweep closes.
Deleted: Audit arm 13. Recoverable Invocation Invariant 8.4 owns it: the caller does not re-run an act whose invocation is unclosed.
Deleted: Audit arm 14. Execution Contract Database 1 owns it.
Deleted: Audit arm 15. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an owed record.
Deleted: Audit arm 16. Recoverable Invocation reconcile step 3.2 and Execution Contract Database 1 own it.
Deleted: Audit arm 17. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an owed record.
Deleted: Audit arm 18. Execution Contract Database 1 owns it.
Deleted: Audit arm 20. Recoverable Invocation Primitive policy 41 through 43 own it: an invalid-request at the intent is the caller's, at the outcome a hard alert.
Deleted: Audit arm 21. Recoverable Invocation Primitive policy 40 and Recoverable Invocation Primitive policy 42 own it: the hard alert.
Deleted: Audit arm 22. Recoverable Invocation Invariant 5.2 owns it: a recovered outcome carries the recovery flag.
Deleted: Audit arm 23. Recoverable Invocation Invariant 5.2 owns it: a recovered outcome names the caller in the acting actor reference.
Deleted: Audit arm 24. Recoverable Invocation Primitive policy 20 through 22 and Recoverable Invocation Primitive policy 41 own it: an intent's invalid-request(step-4) is read back by invocation id, a found record proceeding with a hard alert and none answering invalid-request.
Deleted: Audit arm 25. Recoverable Invocation Primitive policy 43 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 154. Execution Contract Read 1 owns it.
Deleted: Action wiring 18. Execution Contract Database 1 owns it.
Deleted: Action wiring 34. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it: a close that does not land answers recording-failure(outcome).
Deleted: Action wiring 41. Execution Contract Read 1 owns it.
Deleted: Action wiring 50. Recoverable Invocation Primitive policy 23 owns it: a trigger intent that does not land answers recording-failure(intent).
Deleted: Action wiring 51. Recoverable Invocation Invariant 1.1 and Recoverable Invocation Action wiring 4 own it: no commit is issued ahead of a landed intent.
Deleted: Action wiring 62. Recoverable Invocation's refuse owns it: a refusal record that does not land answers recording-failure(refusal, constituent_code), and the sweep records the attempt.
Deleted: Action wiring 65. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Deleted: Action wiring 74. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Deleted: Action wiring 78. Term renewal probe owns it: a renewal is recovered on the act key and the pairing datum.
Deleted: Action wiring 91. Action wiring 83 owns it: the next review due rides the clearance intent, and the clearance outcome carries none.
Deleted: Action wiring 92. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Deleted: Action wiring 93. Term clearance transaction owns it: the verify and the reinstate commit together, and no record stands between them (Recoverable Invocation Action wiring 6).
Deleted: Action wiring 94. Term clearance transaction owns it: the verify and the reinstate commit together, and no record stands between them (Recoverable Invocation Action wiring 6).
Deleted: Action wiring 101. Execution Contract Database 1 owns it.
Deleted: Action wiring 102. Action wiring 90 owns it: the clearance's one outcome carries the reinstate's state change id.
Deleted: Action wiring 103. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Deleted: Action wiring 108. Execution Contract Database 1 owns it.
Deleted: Action wiring 109. Execution Contract Database 1 owns it.
Deleted: Action wiring 110. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Action wiring 117. Recoverable Invocation reconcile step 3.2 and Execution Contract Database 1 own it.
Deleted: Action wiring 118. Execution Contract Database 1 owns it: a closure's close, floor and record commit together, so no invocation completes an earlier closure.
Deleted: Action wiring 119a. Recoverable Invocation open step 3.5 owns it: an earlier closure whose outcome has not landed is an open closure intent, so a second closure meets act-in-flight while the first is in flight, and the second's close answers already-closed once the first committed (Action wiring 119).
Deleted: Action wiring 126. Execution Contract Database 1 owns it.
Deleted: Action wiring 128. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Deleted: Action wiring 133. Execution Contract Database 1 owns it.
Deleted: Action wiring 139. Execution Contract Read 1 owns it.
Deleted: Action wiring 141. Execution Contract Read 1 and Execution Contract Read 2 own it.
Deleted: Action wiring 148. Action wiring 146 owns it.
Deleted: Action wiring 149. Action wiring 146 owns it.
Deleted: Action wiring 150. Action wiring 146 owns it.
Deleted: Action wiring 151. Action wiring 146 and Action wiring 90 own it: the clearance's one outcome carries the clearance instant, the reinstate's state change instant.
Deleted: Action wiring 152. Action wiring 146 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 3. Recoverable Invocation reconcile step 1.1 owns it: the sweep selects every open intent of the act kinds.
Deleted: Reconciliation 4. Execution Contract Database 1 owns it.
Deleted: Reconciliation 6. Recoverable Invocation reconcile step 3.1 and the act probes own it: the sweep runs the kind's act probe against Party Identity's and Retention Window's declared reads (Recoverable Invocation Sweep never 3).
Deleted: Reconciliation 7. Recoverable Invocation reconcile step 3.5 owns it: an intent whose invocation died before its commit is escalated, and an operator who finds the constituents quiet abandons it through the invocation resolve (Recoverable Invocation Invariant 4.9).
Deleted: Reconciliation 8. Recoverable Invocation reconcile step 3.2 owns it: a committed probe answer is closed by the recovered outcome.
Deleted: Reconciliation 9. Recoverable Invocation Invariant 5.1 and Recoverable Invocation reconcile step 3.2a own it: the recovery intent before any recovered outcome.
Deleted: Reconciliation 10. Recoverable Invocation reconcile step 2.4 through 2.6 own it: the sweep re-reads the invocation's closings under the critical section before it writes.
Deleted: Reconciliation 11. Recoverable Invocation reconcile step 3.2a, Recoverable Invocation reconcile step 3.2b, Recoverable Invocation Invariant 5.2 and Recoverable Invocation service identity 3 own it: the sweep writes under the recovery identity.
Deleted: Reconciliation 12. Execution Contract Database 1 owns it.
Deleted: Reconciliation 13. Execution Contract Database 1 owns it.
Deleted: Reconciliation 14. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it: neither the sweep nor the reconciliation calls a constituent's write.
Deleted: Reconciliation 15. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it.
Deleted: Reconciliation 16. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it.
Deleted: Reconciliation 17. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it.
Deleted: Reconciliation 18. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it.
Deleted: Reconciliation 19. Recoverable Invocation Invariant 4.2 and Recoverable Invocation Instance start 4 own it: an open intent is closed within the closure window.
Deleted: Reconciliation 20. Recoverable Invocation reconcile step 3.5, Recoverable Invocation reconcile step 3.8 and Recoverable Invocation reconcile step 5.1 own it: an intent the sweep cannot close is escalated once and reported at risk.
Deleted: Reconciliation 21. Execution Contract Database 1 owns it.
Deleted: Reconciliation 24. Recoverable Invocation Invariant 4.1, Recoverable Invocation reconcile step 3.5 and Recoverable Invocation reconcile step 3.21 own it: a trigger intent carrying no closing stands open until the sweep closes or escalates it.
Deleted: Reconciliation 26. Execution Contract Database 2 owns it.
Deleted: Reconciliation 27. Term verification probe and Recoverable Invocation Invariant 3.3 own it: the probe pairs on the act key and the pairing datum by equality.
Deleted: Reconciliation 28. Term admission probe, Term renewal probe and Recoverable Invocation Invariant 3.3 own it.
Deleted: Reconciliation 29. Term enrollment probe and Recoverable Invocation Deviation 4b own it, reversed: the probe finds the minted party through Party Identity's enrollment instant range.
Deleted: Reconciliation 30. Recoverable Invocation reconcile step 3.5 and Recoverable Invocation reconcile step 3.8 own it: what the enrollment probe cannot decide is escalated.
Deleted: Reconciliation 31. Recoverable Invocation Invariant 3.2 and Recoverable Invocation act probe 3a own it.
Deleted: Reconciliation 32. Term reconciliation owns it: the reconciliation runs inside the sweep's run, which answers its tally to its starter alone.
Deleted: Reconciliation 33. Execution Contract Scheduled leg 1 owns it.
```

### Composition-level invariants

```
Deleted: Invariant 2.4. Recoverable Invocation Invariant 4.2 owns it: an open verification intent is closed within the closure window.
Deleted: Invariant 7.3. Term clearance transaction owns it: the verify and the reinstate commit together, so no clearance window stands for a verified party to carry a closed trigger inside.
Deleted: Invariant 8.1. Recoverable Invocation Invariant 1.1 owns it: no commit stands ahead of the intent the caller's credential attested.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.3. Recoverable Invocation Check 3.1 owns it: an intent carrying no outcome is closed or escalated within the closure window.
Deleted: Check 4.4. Invariant 4.3 and Recoverable Invocation Check 1.1 own it: the clearance writes one intent, attested under the clearing actor, and one outcome naming it.
Deleted: Check 7.6. Term clearance transaction owns it: no clearance stands recorded beside a trigger it left open.
Deleted: Check 8.1. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 8.2. Recoverable Invocation Primitive policy 11 and Identity 9 own it: every record of an invocation carries the act key, and the intent the case id.
Deleted: Check 8.3. Recoverable Invocation Check 1.1 and Recoverable Invocation Invariant 5.2 own it: a recovered outcome is compared against the acting actor reference.
Deleted: Check 8.4. Recoverable Invocation Invariant 5.2 owns it.
Deleted: Check 8.5. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 8.6. Recoverable Invocation Check 6.1 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Recoverable Invocation Action wiring 4 owns it: the close follows the commit.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 5. Execution Contract Database 1 owns it.
Deleted: Atomic writes 6. Execution Contract Database 1 owns it.
Deleted: Atomic writes 7. Execution Contract Database 1 owns it.
Deleted: Atomic writes 8. Execution Contract Database 1 owns it.
Deleted: Atomic writes 9. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Action wiring 146 through 152 own it, one outcome at a time.
Deleted: Clock semantics 1. Capability requirement 1 owns it.
Deleted: Clock semantics 3. Action wiring 153 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 6. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 10. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 11. Non-goal 21 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Invariant 1.1 owns it: a skewed gate read answers permitted only where Party Identity's read reports the party verified, so the skew fails safe.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Deleted: Concurrency 7. Execution Contract Database 2 owns it.
Deleted: Concurrency 8. Execution Contract Database 2 owns it.
```
