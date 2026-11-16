---
title: Duplicate Prevention — history
nav_exclude: true
search_exclude: true
---

# Duplicate Prevention — history

The dated record of how [Duplicate Prevention](./duplicate-prevention.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/duplicate-prevention.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-11 — Rewritten in GRACE lang v0.34; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two calls as a signature block, rationale under `WHY:`, terms declared where they are used, the invariant numbers and the Ledger unchanged, Non-goals and Edge cases as two sections. *Over:* the prose spec. *Because:* the migration plan — atoms first, since they declare the vocabulary the compositions cite.

- **2026-09-14 — The atom gained an acceptance surface, written from the atom's own rules.** *Chose:* eleven `Check` rules and six `External check` rules, each naming the rule the check tests. *Over:* declining by delegation, which the amended rule admits and this atom cannot honestly take. *Because:* presence became mandatory for every migrated spec on 2026-09-14 (the section titled Generation acceptance in `pressure-testing.md`), and this atom is the one where the absence cost most: a composing pattern's exactly-once guarantee rests on a repeat record not moving the stamp, which is `Invariant 2.2`, and nothing audited it. Every check clears from the recorded set and the atom's own query surface; none invents an obligation, which is what *the bar reduces to the invariants hold* was always asserting and never made testable (council read 65).

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 2), and the four rules that set the recorded set's durability tombstoned to Store 3 — Non-goal 2 and Non-goal 3, the recorded set's survival across a restart not required of the atom and left to the deployment, Record failure 4, a durable recorded set where duplicate prevention is safety-critical, and External check 4, the auditor's check of that durability; rules 66 to 63. *Over:* a recorded set whose survival across a restart each deployment chose, a volatile set admitted wherever the guard was not safety-critical. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and that the four Store rules hold for every specification; `execution-contract.md` writes them once as the Store contract, and Store 3 keeps every committed write across a restart. A failed write still answers ok and misses the guard (Record failure 1 through 3), the posture under an unavailable store stays the deployment's to declare (Check unavailability 1 through 4), and the host's drop of an identity that is not under guard stays the atom's own (Invariant 4.1, Lazy expiry 1, Lazy expiry 2). Under guard is derived from the recording instant each entry carries, so the atom cites neither History 1 nor Order 1; what the atom does for its domain is unchanged.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 2, Execution Contract Read 1 through 3) and the rule that restated it, the atom-wide state-unavailable (Operation 13), deleted to Read 1; state-unavailable off [Check]'s answers (Operation 5, Check 3.1), the read's condition off the rules and the term it held to an answered read (Operation 6, Operation 7, Term landed record), Term database read deleted, and state-unavailable off both signatures and the case table; rules 51 to 50. *Over:* the page stating for itself what every action answers when the recorded set cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's fifth Final Critique had made one of the cures the contract's Read family is written from. The response to a state-unavailable answer stays the containing pattern's (Operation 12): proceeding as not seen is fail-open, as seen fail-closed, and the atom decides neither.

- **2026-10-21 — A failed read and a refused write answer as the Execution Contract answers them; the window duration is one per instance and the matching rule is applied before the call; nothing drops an entry, so the recorded set holds every identity placed under guard; two checks answer alike by the rules that fix each answer.** *Chose:* state-unavailable on both actions where the read of the recorded set fails (Operation 13, Term database read) and storage-failure on [Record] where the database refuses its write (Operation 14), with [Check]'s answers held to an answered read (Operation 5 through 7) and [Record]'s placing, stamping, ok and fresh guard held to a landed record (Operation 1 through 3, Invariant 2.3, Term landed record); Operation 4 refusing nothing on the ground that the identity is under guard; Record failure 1 deleted to Operation 14, and Check unavailability 1 through 4 and External check 5 to Operation 12, Operation 13 and Non-goal 1, so proceeding as not-seen or as seen on an unavailable read is the containing pattern's response to an answer; one window duration for each instance of the atom (Operation 11); each identity supplied already reduced to the value the containing pattern's matching rule compares by (Identity 5); Invariant 4.1, Non-goal 6 and Lazy expiry 1 through 3 deleted to Operation 7 and Execution Contract Database 4, with Check 3.4 to Check 3.3, and the recorded set declared as every identity placed under guard, held whether or not its guard still runs; Invariant 3.2 deleted to Operation 6, Operation 7 and Invariant 3.1, and Check 2.2 to Check 2.1, Check 3.2 and Check 3.3. *Over:* a [Check] obliged to answer seen or not-seen and a [Record] obliged to answer ok where the contract answers state-unavailable and storage-failure, so a caller could be told a guard stood that the database never kept; a fail-open posture obliging not-seen for an identity under guard; a window duration two builds could take per call, per entry or at every read; a matching rule two builds could apply inside the atom or before the call; a drop obliged of a host that no declared action lets drop, beside a lazy host the page licensed to keep the entry; and two checks under one now said to answer alike across a [Record] between them. *Because:* Final Critique 5 found each a divergence between conforming builds or two rules no build can both obey, and the corpus held each cure: Actor Identity's, Permissions' and Capability's rounds answer the failed read and the refused write, the method's entry of 2026-10-08 deletes a broken rule to the rules that already hold its states, and Final Critique 4's own text configured the window per containing pattern. This turns three choices the 2026-10-20 entry kept — a failed write answering ok, the posture under an unavailable database declared by the deployment, and the host's drop as the atom's own — because the Database contract the atom takes (Capability requirement 2) and the contract's Step 1 and Step 3 failures leave no conforming build that can make them. What [Check] answers on a read that answers, and what [Record] does on a write that lands, are unchanged.

- **2026-10-22 — An admitted call and a ban's ground are the Execution Contract's.** *Chose:* Term landed record citing Execution Contract Read 4 for what [Record] admits, in place of the commit clause this page's fifth Final Critique wrote, so Operation 1 through 3 and Invariant 2.3 hold for the calls [Record] admits, a write the database refuses answering storage-failure and changing nothing; Operation 4's ground clause retired, the rule written as *[Record] MUST NOT refuse an identity under guard*, which Execution Contract Refusal 1's second sentence reads as naming the ground, so a refused write still answers storage-failure; Read 4 and Refusal 1 cited on Capability requirement 2; the rule count stays at 50. *Over:* the page stating for itself which calls its effect rules reach, and Operation 4 carrying the ground clause its fifth Final Critique wrote. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect and the refusal ban among them; this page's fifth Final Critique had made both cures one specification at a time. What each action does and answers is unchanged.

## Migration notes

- **2026-09-14 — Invariant 4.1 routed through under guard, and Invariant 4.2 deleted.** Both rules stated the comparison in raw operators — `EXCEEDS window duration` — where the spec already declares under guard as *elapsed term less than window duration* and Operation 6 and Operation 7 route through it. The two spellings disagree at exactly one instant: at `elapsed term = window duration` an identity is not under guard, so the then-standing window-monotonicity invariant required it out of the recorded set while the old Invariant 4.1 obliged no host to drop it. Routing through the declared term closes the boundary with no new operator, which is the cure the `≥` docket row asks whether the grammar needs — and one site fewer that it does (council read 51).
- **2026-09-14 — Invariant 1, tombstoned rather than restated.** The deleted invariant claimed EVERY identity in the recorded set stands under guard, unconditionally, and a WHY beside it narrowed the claim to an eager host — a rule whose scope lived on a surface Surface 15 tells the parser to ignore and Surface 9 lets a writer delete. The atom sells behaviour rather than storage, which the rules already say in both directions: Operation 6 answers seen for an identity under guard and Operation 7 answers not-seen for one that is not, so nothing remained for the invariant to own. Restating it as the answer claim — *EVERY identity the check answers seen for MUST stand under guard* — was considered and refused: that is Operation 7's contrapositive, one proposition under a second label, which is the defect rather than the cure (Authority 3, council read 52).
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
- **2026-09-15 — Clock semantics 1, kept under Clock semantics.** Clock semantics 1 stays under Clock semantics rather than under Clock dependence: it is this atom's one use of the reading, an instance of that family's question rather than a statement of it (council read 75).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Duplicate Prevention](./duplicate-prevention.md) may carry it again.

### Structure › Operations

```
Deleted: Operation 8. Capability requirement 1 owns it.
Deleted: Operation 9. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 10. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 13. Execution Contract Read 1 owns it.
```

### Structure › Invariants › Invariant 2 — Single-recording

```
  Deleted: Invariant 1. Operation 6 and Operation 7 own it.
```

### Structure › Invariants › Invariant 3 — Idempotency of check

```
  Deleted: Invariant 3.2. Operation 6, Operation 7 and Invariant 3.1 own it.
```

### Structure › Invariants › Invariant 4 — Eventual expiry

```
  Deleted: Invariant 4.1. Operation 7 and Execution Contract Database 4 own it.
  Deleted: Invariant 4.2. Operation 7 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.2. Invariant 2.2 owns it.
Deleted: Check 1.3. Invariant 2.1 owns it.
Deleted: Check 1.4. Invariant 2.3 owns it.
Deleted: Check 2.1. Invariant 3.1 owns it.
Deleted: Check 2.2. Invariant 3.1, Check 3.2 and Check 3.3 own it.
Deleted: Check 3.4. Check 3.3 owns it.
Deleted: Check 4.1. Operation 3 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 4. Execution Contract Database 3 owns it.
Deleted: External check 5. Operation 12 owns it.
Deleted: External check 6. Execution Contract Logic confinement 7 owns it: the page relies on no guarantee of the clock.
```

### Non-goals

```
Deleted: Non-goal 2. Execution Contract Database 3 owns it.
Deleted: Non-goal 3. Execution Contract Database 3 owns it.
Deleted: Non-goal 6. Operation 7 and Execution Contract Database 4 own it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Non-goal 12 owns it.
Deleted: Clock semantics 3. Non-goal 13 owns it.
```

### Edge cases › Check database unavailability

```
Deleted: Check unavailability 1. Operation 12 and Operation 13 own it.
Deleted: Check unavailability 2. Operation 12 and Operation 13 own it.
Deleted: Check unavailability 3. Operation 12 and Operation 13 own it.
Deleted: Check unavailability 4. Non-goal 1 owns it.
```

### Edge cases › Lazy expiry

```
Deleted: Lazy expiry 1. Execution Contract Database 4 owns it.
Deleted: Lazy expiry 2. Execution Contract Database 4 owns it.
Deleted: Lazy expiry 3. Operation 7 owns it.
```

### Edge cases › Record storage failure

```
Deleted: Record failure 1. Operation 14 owns it.
Deleted: Record failure 4. Execution Contract Database 3 owns it.
```
