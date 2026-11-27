---
title: Selective Disclosure — history
nav_exclude: true
search_exclude: true
---

# Selective Disclosure — history

The dated record of how [Selective Disclosure](./selective-disclosure.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/selective-disclosure.md`.

## Decisions

Entries that record a migration or a repair rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the two actions as a signature block, Invariant 1 through 6 keeping their numbers, every success effect conditioned on a declared admitted record or admitted read so no effect binds a refused call (Hard invariant 16), the disclosure instant resolution routed through a declared resolved disclosure instant so no rule restates the default, the rejection precedence carried by `Operation 8` and `Operation 15` rather than by a prose *rejection priority* line repeated in three sections, the six acceptance areas opened into `Check 2.1 through 6.2` with the three named audit gaps raised to `External check 1 through 3`, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 22` family and four edge-case families (`String`, `Clock semantics`, `Concurrency`, `Correction`), the Composition notes prose raised to `Composition note 1 through 9` with the named compositions moved into the WHY. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into selective-disclosure` found nothing in the corpus citing this atom by label, so the rewrite carried no frozen-number risk. 73.9 KB → 49.9 KB.

- **2026-09-12 — A filter's match semantics is a rule, not an assumption.** *Chose:* `Operation 27` (an admitted read answers every matching record) and `Operation 28` (an admitted read answers no record failing a filter). *Over:* the prose, which spelled out matching for the authority type axis alone and left the other four to be inferred from the word *matching* in the action description. *Because:* the migration's Check 5.1 tests that a subject reference query answers every record carrying the reference, and no rule in the spec owned that proposition — a check resting on an unowned invariant, the class the docket has been collecting since council read 12. The gap was invisible to both tools and surfaced only when each check was made to name the rule it tests, which is the discipline earning its keep rather than a finding against the atom.

- **2026-09-12 — Reference-level filtering is a non-goal, not an operation.** *Chose:* `Non-goal 22`. *Over:* an `Operation` rule saying [Read] must not offer the axis. *Because:* `Term filter axes` enumerates five axes and `Operation 22` rejects anything outside them, so the operation-level rule was entailed twice over (Authority 3); what is not entailed is the design claim — reference search is a composing-layer concept — and that belongs with the other surface refusals.

- **2026-09-12 — Six defects the tools passed, found by a self-read before a council read.** *Chose:* `Invariant 1.1` rewritten from a garbled sentence that barely parsed; `Concurrency 2` restored to the prose's claim — two concurrent calls are *independent*, which is what the spec said, not *non-blocking*, which is what I had written; `Correction 4` given a declared correction narrative, because naming the corrected record is unsatisfiable unless a field holds the naming and the prose named two; `Identity 15` changed from the deployment *allocating* an id (contradicting `Identity 2`, where the host allocates) to the deployment choosing the id *format*; `Operation 20`'s lower-case `where` replaced by an admitted `IF … THEN`; the former first conformance check moved to `External check 4`. *Over:* shipping a file both checkers called clean. *Because:* zero tool findings has never once predicted zero council findings, and three of the six were changes in meaning rather than infelicities. The last is the repeatable one: a check asking an auditor to find *every issued* disclosure id cannot be cleared from the store, because the store is exactly what would be missing one — the same split council read 22 forced on Capability, applied here before a reader had to force it.

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the disclosure store supplied under Execution Contract Store 1, Store 3 and Store 4 (Capability requirement 5), and the three rules that restated them, or stood in for them, tombstoned to their owner — Invariant 6.2, no partial record left by a storage-failure, to Store 1; Invariant 6.3, an answered disclosure id naming a durably persisted record, and External check 4, the recorded answers captured to find an issued disclosure id the store is missing, to Store 3; rules 130 to 128. *Over:* the atom restating, for its own store, what every deployment's store guarantees, and a deployment capturing its record answers against a store that might lose a disclosure. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The atom's own no-removal rules stay (State 5, State 8, State 9, Invariant 6.1), since Store 4 alone does not keep the atom from removing a record or the count from falling; a refused [Record] still records nothing and leaves the store as the call found the store, guard refusals included (Operation 16, Operation 17). [Record]'s guards read no store state and each record is written once under a fresh host-allocated id, so the atom cites no Store 2; Check 3.1 and Check 3.2 rest on the auditor's own two reads, and [Read] orders by disclosure instant and disclosure id, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — A composed retention may purge what the atom never removes; [Record]'s refusals answer in one stated order.** *Chose:* State 8 and State 9, which held the record count and every unfiltered read's records for good, tombstoned to the rules that hold what is true — the atom removes no record (Invariant 6.1), the database removes none but by an action a specification declares (Execution Contract Database 4), and an unfiltered read answers what the database holds (Operation 21); Check 3.2 moved to External check 5, which reads the composing pattern's purge records beside two reads; Check 6.2 tombstoned to Check 6.1, which tests the guard that keeps Invariant 4.1; and one record refusal order over [Record]'s guard refusals (Operation 35), with Operation 8 and Operation 15 kept as its pairs. *Over:* a record count that may never fall beside Non-goal 19, which sends a deployment needing a retention bound to Retention Window, whose purge destroys the record, so a conforming deployment broke State 8 and State 9 and failed Check 3.2 at its first purge; a check comparing each record with a creation instant no record carries; and pairwise ONLY IF rules, Operation 8 read alone forbidding what Operation 9 obliges on a call carrying a blank field and an unknown type. *Because:* Final Critique 6 found each two rules no build could both obey, or a check a conforming deployment fails or a violating one passes; Final Critique 5's text already put the purge with Retention Window (*when (if ever) they may be purged — is a composing Retention Window concept*), so the method's entry of 2026-10-08 tombstones the broken rules to the rules that hold the lawful states rather than qualifying them, and Approval Step's sixth round gave the refusal order its form. What the atom does for its domain is unchanged: it records and reads as it did, refuses the same calls with the same codes, and never removes a record.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Record]'s refuses line kept as the page wrote it, already in the order the record refusal order gave — invalid-request, unknown-authority-type, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 5, Execution Contract Refusal 1); the rules that only stated it deleted to Refusal 1: Operation 35, which evaluated the record refusal order, with Term record refusal order, and the pairs Operation 8 (unknown-authority-type only once every field-level precondition passes) and Operation 15 (storage-failure only once they pass and the authority type is known), with Term field-level precondition, which only those pairs read; rules 126 to 123. *Over:* the page stating for itself which of [Record]'s refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's sixth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-22 — A composed purge is answered by the purging pattern's records, as the Execution Contract says.** *Chose:* External check 5, a composing pattern's purge records read beside two unfiltered reads of the disclosure records, deleted to Execution Contract Database 6, with Check 3.2's tombstone, which named it, now naming the contract, and the label cited on Capability requirement 5; the atom's own no-removal rules stand as written and bind its own actions; rules 123 to 122. *Over:* the page stating for itself that a purge another specification declares is answered outside the disclosure records. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the composed erasure among them; this page's sixth Final Critique had made the cure first, one specification at a time. What each action does and answers is unchanged.

- **2026-11-02 — The string cap has a default.** *Chose:* the string cap stated as 1,024 Unicode code points where a deployment declares none, Capability requirement 8 added, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs are references, a recipient and a scope the caller declares in words, and 1,024 code points, the corpus's default for text (Personal Todo's description cap), holds a scope of a sentence or two.

- **2026-11-20 — External check 3's receipt-instant read clears Invariant 4.1, and the vocabulary carries its cited and composing pattern lines.** *Chose:* External check 3 reads the composing Event Log's receipt instant beside the disclosure instant for two needs, a backdated disclosure instant detected and Invariant 4.1 cleared; the vocabulary gains `Term cited` and `Term composing pattern`. *Over:* a conformance check over the records (no record keeps the now its creation read, State 10), a Non-goal that leaves the clearing to no one, and a title-and-summary blockquote at the page head. *Because:* Scott's direction of 2026-11-19 (3:35 and 3:41 PM Central, rounds/open-line-choices-directions-2.md item 124) says the receipt-instant read stands for Invariant 4.1 and the page says so; his direction of 3:47 PM (directions-3, items 100, 121 and 125) keeps the corpus's practice for the atom head, which commit 8c9896b3 wrote into spec-format.md, and leaves GRACE-lang's Closed vocabulary 2 and 3 category lines to the pages that owe them.

- **2026-11-26 — The atom converted to the bond shape, batch 5 of the converter: it offers the disclosure id and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; `Term offer key: key disclosure id; carried by disclosure records; calls Read` (Bonds Key 9, 10, 26), the disclosure id declared (Key 18). No need: the record carries no actor (Non-goal 12), so the drafted actor id need was dropped. The six `MUST compose <pattern>` Non-goals (11, 13, 15, 17, 19, 24) tombstoned to the Non-goal that states what the atom does not do; Non-goal 23 composes a trusted timestamping pattern by its job; the WHY's four peers, External check 3, Term receipt instant, the authority reference entry, two scenarios, Term composing pattern and both NOTEs say each job, not a pattern. Check 1 is no skipped rule: the checks were numbered from 2.1 at the migration (df5fefe3, 2026-09-12), each beside its invariant group, so no tombstone is written for a label that never stood. Labelled rules 119 before, 113 after; 597 lines before, 610 after. *Over:* the drafted actor id need; a tombstone for Check 1. *Because:* unit `atom: Selective Disclosure, converted` (batch 5, 4 of 5).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Selective Disclosure](./selective-disclosure.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 6. Execution Contract Database 7 owns it.
Deleted: Identity 15. Execution Contract Logic confinement 10 owns it.
```

### Structure › State

```
Deleted: State 8. Invariant 6.1 and Execution Contract Database 4 own it.
Deleted: State 9. Operation 27, Execution Contract Query 4, Invariant 6.1 and Execution Contract Database 4 own it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 7. Execution Contract Conformance 9 owns it.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. State 10 owns it.
Deleted: Clock semantics 5. Non-goal 23 owns it.
```

### Structure › Operations

```
Deleted: Operation 8. Execution Contract Refusal 1 owns it.
Deleted: Operation 15. Execution Contract Refusal 1 owns it.
Deleted: Operation 21. Execution Contract Query 4 and Operation 27 own it.
Deleted: Operation 26. Execution Contract Query 2 owns it.
Deleted: Operation 31. Capability requirement 1 owns it.
Deleted: Operation 32. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 33. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 34. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 35. Execution Contract Refusal 1 owns it.
Deleted: Operation 37. Execution Contract Input 1 owns it.
Deleted: Operation 39. Execution Contract Input 4 owns it.
Deleted: Operation 40. Execution Contract Input 4 owns it.
Deleted: Operation 41. Execution Contract Input 4 owns it.
```

### Structure › Invariants › Invariant 2 — Authority completeness

```
  Deleted: Invariant 2.2. Invariant 3.2 owns it.
```

### Structure › Invariants › Invariant 3 — Field completeness

```
  Deleted: Invariant 3.1. State 1 owns it.
```

### Structure › Invariants › Invariant 5 — Unrecorded transmissions

```
  Deleted: Invariant 5.1. Capability requirement 6 owns it.
```

### Structure › Invariants › Invariant 6 — Record durability and append-only nature

```
  Deleted: Invariant 6.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 6.3. Execution Contract Database 3 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 3.2. Execution Contract Database 6 owns it.
Deleted: Check 4.1. Operation 9 owns it.
Deleted: Check 4.2. Operation 16 owns it.
Deleted: Check 6.1. Operation 7 owns it.
Deleted: Check 6.2. Operation 7 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 4. Execution Contract Database 3 owns it.
Deleted: External check 5. Execution Contract Database 6 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 3. Identity 2, Identity 5, Operation 10 and Operation 11 own it.
```

### Edge cases › String policy

```
Deleted: String 7. Execution Contract Logic confinement 13 owns it.
```

### Composition notes

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns it.
Deleted: Composition note 9. Execution Contract Atom interface 1 owns it.
```

### While something is so › String policy

```
Deleted: String 5. GRACE-lang Term blank owns it: a value carrying only white space is blank.
Deleted: String 6. GRACE-lang Term blank owns it: an absent value is blank.
```
