---
title: Capacity Constraint Enforcement — history
nav_exclude: true
search_exclude: true
---

# Capacity Constraint Enforcement — history

The dated record of how [Capacity Constraint Enforcement](./capacity-constraint-enforcement.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/capacity-constraint-enforcement.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.36; nothing but language changed.** *Chose:* the eight actions as a signature block, the fourteen invariant numbers unchanged, the six acceptance areas opened into `Check 1.1 through 6.1` with three External checks for what the store cannot answer, the arithmetic routed through declared requested total and released total so no rule carries a sum, the three host obligations Invariant 4 rests on given their own families (`Concurrency`, `Crash atomicity`, `Arithmetic`). *Over:* the prose spec. *Because:* the migration plan; nothing cites this atom by label. The open question this atom was picked to answer — whether a domain whose logic *is* arithmetic survives Hard invariant 24 — answers yes: `MUST NOT EXCEED` and `EXCEEDS` carry every comparison directly, and only the two sums needed names.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the pool store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the twelve rules that restated them tombstoned to their owner — Invariant 14.1 and Crash atomicity 1, an action's records committed in one operation, Invariant 1.3 and Invariant 14.2, no partial pool or record on storage-failure, and Invariant 14.3, that commit resting on a host obligation, to Store 1; Crash atomicity 2, 3 and 5, no crash inside a writing action leaving an audit event without its pool change, a pool change without its audit event, or a pool [Declare Pool] did not finish, to Store 1 and Store 3; Crash atomicity 4, a recovered store standing in no violation of Invariant 4.1, to Store 3; Concurrency 2, the arithmetic guard and the write one transition, to Store 1 and Store 2; Concurrency 1, concurrent calls on one pool serialized, and Concurrency 3, a compare-and-set on allocated discharging Concurrency 2, to Store 2; rules 222 to 211. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. Invariant 4.1 and Invariant 5.1 now rest on the host obligations Capability requirement 5 and Arithmetic 1 name (Invariant 4.4, Invariant 5.3). The bound and its guards stay the atom's own (Invariant 4.1 through 4.3, Operation 13, Operation 22, Operation 32), as do a refused action leaving the pool as the call found it and appending no audit event (Operation 58, Operation 59), the store refusing a colliding pool id (Identity 14), and the records the atom never removes, re-orders or changes (State 7 through 10, State 19, State 20, Invariant 1.1, 1.2, 7.1, 8.1 through 8.3, 9.1 through 9.3, 12.1, 12.2). The audit log is carried on the pool record, ordered by insertion by the atom itself (State 3, State 11), and an auditor replays it forward rather than reading a record as it stood at a past commit (Check 2.1), so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Allocate]'s refuses line listing its refusals in the order the page states — not-known, the pool's state (suspended, closed) ahead of over-capacity as Operation 14 held it, state ahead of format as the Rejection paths say, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 5, Execution Contract Refusal 1); Operation 14 (over-capacity only on an open pool) and Operation 60 (storage-failure behind every precondition), which only stated the order, deleted to Refusal 1; rules 211 to 209. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-22 — What the pool records cannot show is read beside them; an input past its bound is refused; format answers before arithmetic.** *Chose:* Check 6.1 deleted to External check 4, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration; Check 5.1 through 5.4 deleted to External check 5, the attribution surface found on every audit event outside the composed erasure mechanism's scrub records; Check 3.2 held to the allocation events the replay reaches, and External check 6 reading the capacity across a purge from the anchor Check 2.3 names; Arithmetic 4 and 5 refusing a capacity and a new capacity past the integer width, and String 4 a reason past the reason cap, each with invalid-request; [Allocate], [Release] and [Adjust Capacity] listing invalid-request ahead of their arithmetic refusal; Non-goal 30 and 31 sending a retried call to Duplicate Prevention; Operation 55 and 56 deleted to Execution Contract Read 1, which Capability requirement 5 now cites. *Over:* conformance checks no pool record could clear once a deployment wired in, scrubbed or purged what the page admits (Composition note 1, Invariant 8.4, Invariant 9.4); inputs every build had to refuse with no refusal named; and arithmetic refusals answering ahead of a malformed input, against the page's own Invalid Request entry. *Because:* Final Critique 9 found each, and the corpus held the cures: the external checks to which eight atoms had moved the wiring declaration and three the composed erasure's checks, and Final Critique 8's own text, which answered an overflow and an over-long reason with invalid-request, answered format before any arithmetic check, read the capacity across a purge from the archival step's boundary snapshot, and gave idempotent allocation under retry to Duplicate Prevention. Smaller fixes rode with it, none changing what a rule means: the Summary, the Regulator audit scenario and the Closing Balance entry check the bound against the capacity the declaration and the adjustments set; the airline and banking examples read as their rules answer; and the Not Open and Not Suspended entries name the one state each answers. What each action does on a well-formed call is unchanged.

- **2026-10-22 — The wiring and a composed scrub are read outside the pool records, as the Execution Contract says.** *Chose:* External check 4, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, and External check 5, the attribution surface read outside the composed erasure mechanism's scrub records, deleted to Execution Contract Database 6, with the tombstones of Check 5.1 through 5.4 and Check 6.1, which named them, now naming the contract and the checks NOTE cut to External check 6; both labels cited on Capability requirement 5; rules 209 to 207. External check 6 is kept as the page's own: the capacity at a purge boundary is read from the anchor the page itself obliges (Check 2.3), not from the purging pattern's records. *Over:* the page stating for itself that the wiring is an external check and that a scrub another specification declares is answered outside the pool records. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration and the composed erasure among them; this page's ninth Final Critique had made both cures one specification at a time. What each action does and answers is unchanged.

- **2026-11-21 — The eleven open lines of Final Critique 10 are closed.** *Chose:* one party draws the ids (the deployment, where the page said the host and the deployment); the pool records refuse a colliding write (Capability requirement 8, answered storage-failure by Operation 57); the anchor across a purge is Capability requirement 7, not an auditor's check; Check 2.4 and Check 2.5 chain every event and the pool's current record to the replay, and Check 7.1 through 7.3, 8.1 and 8.2 check the adjustment and state-change surfaces; the owners of the seven non-goals named, or stated to be none; sixteen names in the Terms registry each given a Term declaration; Invariant 3.2, 3.3, 10.1 and 11.1 written as where the audit log stands, and Invariant 4.2, 4.3, 5.2, 6.2 and 6.3 deleted to the Operation that owns each answer; the audit-log read named as the deployment's read of the pool records, not an action; a composed scrub may reach the declaring actor reference and the declaration reason; String 12 deleted to Execution Contract Logic confinement 13. *Over:* leaving the lines open until a round decided them, an audit-log read action, a scrub that stops at the audit events, and a normalization rule for fields the atom never compares. *Because:* a pattern done with its open lines in its text is not done (Scott, 2026-11-19), and a rule of the corpus decided each cure (Standard label 14, Logic confinement 3, 13 and 16, Database 6, Check 3.2's own form); the chain checks walk a pool's audit log from the declaration, which Check 3.1 and Check 3.2 do not, and where an event was purged they do not run and the anchor stands in (External check 6).

## Migration notes

- **2026-09-15 — Clock dependence 1 and 2, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. Both rules keep the words they carried as Clock semantics 4 and 5; only the heading changed.
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Capacity Constraint Enforcement](./capacity-constraint-enforcement.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 6. Execution Contract Logic confinement 3 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 4. Clock dependence 1 owns it.
Deleted: Clock semantics 5. Clock dependence 2 owns it.
Deleted: Clock semantics 6. Non-goal 29 owns it.
```

### Structure › Operations

```
Deleted: Operation 14. Execution Contract Refusal 1 owns it.
Deleted: Operation 55. Operation 51 and Execution Contract Read 1 own it.
Deleted: Operation 56. Execution Contract Read 1 owns it.
Deleted: Operation 60. Execution Contract Refusal 1 owns it.
Deleted: Operation 61. Capability requirement 1 owns it.
Deleted: Operation 62. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 63. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 64. Clock dependence 1 owns it.
```

### Structure › Invariants › Invariant 1 — Pool record permanence under this atom's actions

```
  Deleted: Invariant 1.3. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 4 — Capacity constraint

```
  Deleted: Invariant 4.2. Operation 13 owns it.
  Deleted: Invariant 4.3. Operation 32 owns it.
```

### Structure › Invariants › Invariant 5 — Non-negativity

```
  Deleted: Invariant 5.2. Operation 22 owns it.
```

### Structure › Invariants › Invariant 6 — Capacity non-negativity

```
  Deleted: Invariant 6.2. Operation 7 and Arithmetic 4 own it.
  Deleted: Invariant 6.3. Operation 30 and Arithmetic 5 own it.
```

### Structure › Invariants › Invariant 14 — Action atomicity

```
  Deleted: Invariant 14.1. Execution Contract Database 1 owns it.
  Deleted: Invariant 14.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 14.3. Execution Contract Database 1 owns it: an action's writes commit together or not at all, and the atom names no host obligation left for the commit to rest on.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.3. Capability requirement 7 owns it.
Deleted: Check 5.1. Execution Contract Database 6 owns it.
Deleted: Check 5.2. Execution Contract Database 6 owns it.
Deleted: Check 5.3. Execution Contract Database 6 owns it.
Deleted: Check 5.4. Execution Contract Database 6 owns it.
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › Conformance checks › External checks

```
Deleted: External check 4. Execution Contract Conformance 9 owns it.
Deleted: External check 5. Execution Contract Database 6 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it: the arithmetic guard and the write are one transaction, and the atom names no rule left for a compare-and-set to discharge.
```

### Edge cases › String policy

```
Deleted: String 3. Execution Contract Input 2 owns it, and Term actor reference cap supplies the default.
Deleted: String 12. Execution Contract Logic confinement 13 owns it, and Identity 10 and Identity 11 own the one comparison the atom makes.
```

### Edge cases › Crash atomicity

```
Deleted: Crash atomicity 1. Execution Contract Database 1 owns it.
Deleted: Crash atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Crash atomicity 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Crash atomicity 5. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Crash atomicity 4. Execution Contract Database 3 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns it.
Deleted: Composition note 8. Execution Contract Atom interface 1 owns it.
```
