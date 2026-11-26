---
title: Message Preference — history
nav_exclude: true
search_exclude: true
---

# Message Preference — history

The dated record of how [Message Preference](./message-preference.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/message-preference.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the five actions as a signature block, the ten invariant numbers unchanged and Timestamp ordering kept outside them as its own label family, the six acceptance checks renumbered only into `Check N.k`, the case space kept beside the rules as a table, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the preference store supplied under Execution Contract Store 1 through 4 (Capability requirement 6), and the sixteen rules that restated them tombstoned to their owner — Operation 15 and Invariant 4.1, the new record and the supersession committed in one operation, and Invariant 4.2 and Concurrency 3, no reader observing two records in effect for one principal or a torn record, to Store 1; Invariant 4.3 and 4.4, a refused supersession leaving the prior record in effect and recording no new one, Operation 30, a refused write leaving the store as the call found it, and Supersession atomicity 4 through 7, no crash inside [Set], [Suspend] or [Delete] leaving part of its writes, to Store 1 and Store 3; Supersession atomicity 8, a recovered store standing in no violation of Invariant 3.1, to Store 3; Supersession atomicity 1, the currency check and the supersession write one transition, to Store 1 and Store 2; Concurrency 1 and Supersession atomicity 2, the calls on one principal serialized, and Supersession atomicity 3, an isolation level foreclosing two concurrent [Set] calls, to Store 2; rules 211 to 196. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. At most one record in effect per principal stays the atom's own (Invariant 3.1, Operation 14), as do the instants a supersession and each lifecycle move stamp (State 9 through 12), the recorded timestamps witnessing the serialization order (Concurrency 2), and the records the atom never removes and the count that never falls (State 17, Invariant 9.1 through 9.3). A superseded record stays a record of its own with its own instants, and an auditor reconstructs which record governed from those instants (Check 2.1), so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — The page's records-alone claims read as provable.** *Chose:* *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where the page wrote *from the database alone*, *from the record alone* or *with no recourse to source code, runbooks or developer narration*: Invariant 10.3, under which an auditor clears Check 5.1 provably, and, by wording alone, the Summary's self-containment claim, the auditability property, the quiet-hours example and the acceptance bar; rules 196 to 196. *Over:* the phrase restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Invariant 10.3 changed and no obligation did.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Set]'s refuses line kept as the page wrote it, already in the page's order — invalid-request, undeclared-channel, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 6, Execution Contract Refusal 1); Operation 9 (undeclared-channel only once the principal reference and a preference field are supplied), which only stated it, deleted to Refusal 1; rules 196 to 195. *Over:* the page stating for itself which of [Set]'s refusals answers when both apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-22 — A composed retention may dispose of what the atom never removes, no check asks for what no record carries, and no rule moves a status no call moves.** *Chose:* Invariant 9.2, the count that never falls, deleted to State 17 and Execution Contract Database 4, with Check 1.1 citing Invariant 9.1 alone; Check 6.1 deleted to External check 1, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, and Check 6.2 to Capability requirement 7, the deployment disclosing the fanout-on-no-record policy; Invariant 2.1 and Invariant 2.2, each read as obliging a status to move, deleted to State 1 and Invariant 2.3. *Over:* a count no lawful disposal may lower beside a non-goal sending lawful disposal to Retention Window; two conformance checks no preference record can answer, under an acceptance an external auditor clears from the stored fields; and two rules that a record left suspended by a principal who never returns breaks. *Because:* Final Critique 9 found all three, and the corpus held each cure: the composed erasure's, made on five atoms; the wiring declaration's, made on nine; and the method's 2026-10-08 rule, under which a rule a lawful state breaks is deleted to a rule that already holds that state. Smaller fixes rode with them: the supersession gap bound, with Temporal property 4, Capability requirement 5 and Check 4.1 and 4.2, deleted to State 11 and State 12, since one injected now stamps both instants of a supersession and the atomicity the bound once checked is Execution Contract Database 1's; Temporal property 5 deleted to Execution Contract Logic confinement 7; Composition note 13 to Channel set evolution 1, the declared channel set's governance the deployment's, as Final Critique 8's text had it; Invariant 5.2 and Invariant 10.3 to Check 5.1; Capability requirement 8, the deployment supplying the declared channel set at the seam; rules 195 to 185. What each action answers and writes on every call is unchanged.

- **2026-10-22 — The wiring and a composed retention's disposal are the Execution Contract's.** *Chose:* External check 1, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 6.1's tombstone, which named it, now naming the contract and the checks NOTE's sentence restating it removed; State 17 read by Execution Contract Database 6, so the atom removes no preference record and a disposal a composing retention pattern declares is answered by that pattern's records; both labels cited on Capability requirement 6; rules 185 to 184. *Over:* the page stating for itself that the wiring is an external check and that its no-removal rule binds the atom alone. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration and the composed erasure among them; this page's ninth Final Critique had made both cures one specification at a time. What each action does and answers is unchanged.

- **2026-11-20 — The opaque input has a cap with a default, and the answer arm ok is declared.** *Chose:* the opaque input cap stated with its default, 65,536 bytes where a deployment declares none (the payload cap of Event Log), the deployment declaring its own PER Execution Contract Input 2, a [Set] over it answering invalid-request (Operation 48, the refusal Input 2 names for a call over a cap), and Opaque input bound 2 reading that the atom bounds an opaque input at that cap, where it said the atom bounds none and the deployment owns the bound; the success arm ok of [Suspend] and [Delete] declared as the Member entry Ok, with a marker in Term status. *Over:* settling that an opaque input is uncapped, and naming the arm a deployment disclosure. *Because:* Execution Contract Input 2 says a bound is a default cap and a cap is never left unstated, a deployment never having to supply one; and Scott's direction of 2026-11-19 (group 1 of his ruling of 21:32Z) says a word the grammar resolves to no declaration is declared. The per-principal history read the Summary and the Account-closure example rest on (open line 2026-11-03-b) is a question to Scott, in `## Needs Scott`.

- **2026-11-20 — The atom declares a per-principal history read.** *Chose:* [History For] (`history_for(principal_ref)`), answering every preference record the principal reference carries, a deleted one included, each whole, by set instant earliest first and then by preference id ascending (Operation 50 through 56; the order is Execution Contract Read 5's, which the call names), the answer paged at the deployment's choice as Execution Contract Read 6 allows (Capability requirement 6 now supplies the records PER Read 5 and Read 6); the Summary's and the Account-closure example's promise that the history is queryable now rests on that call; the regulator-audit scenario stays an auditor's read of the database (Check 1.1). *Over:* keeping the history only as records an auditor reads from the database and leaving the access request to the composing pattern, which the Execution Contract's atom interface contract bars from reading an atom's table outside its declared query surface. *Because:* Scott's session decided it for him on 2026-11-20 (rounds/escalations.md, the 12:42Z entry, answering the 09:53Z ask): a promise in the Summary needs a declared call, and Resolve a Person's Data Rights needs a subject-scoped enumeration it cannot otherwise get; the call adds no state and changes no rule that governs [Set], [Suspend], [Delete], [Current For] or [Read]. Its model rows (Operation 50 through 56) are owed, as Operation 48's are.

## Migration notes

- **2026-09-15 — Clock dependence 1 and 2, moved from Operation.** Whether a guard's decision may depend on the clock reading, and under what condition. Both rules stood under `Operation` until council read 75 swept the corpus by rule text rather than by family name; neither word changed.
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

- **2026-11-26 — The atom converted into the tree order and bonded: it mints and offers the preference id, its principal reference is the actor id, and no pattern is named.** *Chose:* the bonding converter's draft (grace-council assets/bond.py), judged line by line: the tree order Task, List and Ordering stand in, every label kept and none renumbered (161 before and after); `preference id` declared in declarations.md and offered as `key preference id; carried by preference records`; the principal reference is the actor id, met by the need `key actor id; pairs principal references`, as Session's is; Non-goal 7, 9, 14, 18, 24, 27 and 29 tombstoned to the Non-goal that owns each declined job (24, naming Permissions, is cut though the converter missed it); the owners NOTE, the Source lines and the onboarding example name no pattern, and two Source lines cite the owning Non-goals in place of the tombstones; the invariants the draft placed twice kept once, the Instance rules under their *Database instance model* heading, and Optional before Needs. *Over:* the converter's need `pairs preference records`, since the principal reference is the field that carries the actor id. *Because:* Scott's ruling of 2026-11-25 8:07 PM Central ("NEXT"), the unit `atom: Message Preference, converted`, batch 1, 4 of 5.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Message Preference](./message-preference.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 11. Execution Contract Logic confinement 13 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 5. State 11 and State 12 own it: one injected now stamps both instants of a supersession.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 4. Capability requirement 5 owns it.
```

### Structure › Operations

```
Deleted: Operation 6. State 4 owns it: an empty channel preferences map EQUALS blank.
Deleted: Operation 7. State 4 owns it: an empty channel preferences map EQUALS blank.
Deleted: Operation 9. Execution Contract Refusal 1 owns it.
Deleted: Operation 15. Execution Contract Database 1 owns it.
Deleted: Operation 30. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Operation 39. Capability requirement 1 owns it.
Deleted: Operation 40. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 41. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 42. Clock dependence 1 owns it.
Deleted: Operation 43. Clock dependence 2 owns it.
```

### Structure › Invariants › Invariant 2 — Status monotonicity

```
  Deleted: Invariant 2.1. State 1 owns it.
  Deleted: Invariant 2.2. State 1 and Invariant 2.3 own it.
```

### Structure › Invariants › Invariant 4 — Supersession atomicity

```
  Deleted: Invariant 4.1. Execution Contract Database 1 owns it.
  Deleted: Invariant 4.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 4.3. Execution Contract Database 1 and Execution Contract Database 3 own it.
  Deleted: Invariant 4.4. Execution Contract Database 1 and Execution Contract Database 3 own it.
```

### Structure › Invariants › Invariant 5 — Channel preferences reference declared channels, and the proof is on the record

```
  Deleted: Invariant 5.2. Check 5.1 owns it.
```

### Structure › Invariants › Invariant 6 — Suspension is value-preserving

```
  Deleted: Invariant 6.2. Operation 21 owns it.
```

### Structure › Invariants › Invariant 8 — No id reuse

```
  Deleted: Invariant 8.1. Instance 2 owns it: the rule ranges over one database instance.
```

### Structure › Invariants › Invariant 9 — Record durability over this atom's own surface

```
  Deleted: Invariant 9.2. State 17 and Execution Contract Database 4 own it.
```

### Structure › Invariants › Invariant 10 — Validation-context self-containment

```
  Deleted: Invariant 10.3. Check 5.1 owns it: a conformance check reads the records alone.
```

### Structure › Invariants › Temporal property — Timestamp ordering

```
  Deleted: Temporal property 4. State 11 and State 12 own it: one injected now stamps both instants of a supersession.
  Deleted: Temporal property 5. Execution Contract Logic confinement 7 owns it: the deployment owns the clock's guarantees, the implementation none of them.
```

### Structure › Database instance model

```
Deleted: Instance 1. Execution Contract Database 7 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 4.1. State 11 and State 12 own it: one injected now stamps both instants of a supersession.
Deleted: Check 4.2. State 11 and State 12 own it: one injected now stamps both instants of a supersession.
Deleted: Check 4.3. Capability requirement 5 owns it; a deployment obligation is not an auditor's check.
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
Deleted: Check 6.2. Capability requirement 7 owns it; a deployment obligation is not an auditor's check.
```

### Generation acceptance › External checks

```
Deleted: External check 1. Execution Contract Conformance 9 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 1 owns it.
```

### Edge cases › Re-creation after deletion

```
Deleted: Re-creation 3. Identity 4 and Instance 2 own it.
```

### Edge cases › Supersession atomicity

```
Deleted: Supersession atomicity 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Supersession atomicity 2. Execution Contract Database 2 owns it.
Deleted: Supersession atomicity 3. Execution Contract Database 2 owns it.
Deleted: Supersession atomicity 4. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Supersession atomicity 5. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Supersession atomicity 6. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Supersession atomicity 7. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Supersession atomicity 8. Execution Contract Database 3 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Capability requirement 10 owns it.
Deleted: Composition note 13. Channel set evolution 1 owns it: the declared channel set and its change history are the deployment's.
```
