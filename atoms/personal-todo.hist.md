---
title: Personal Todo — history
nav_exclude: true
search_exclude: true
---

# Personal Todo — history

The dated record of how [Personal Todo](./personal-todo.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/personal-todo.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the description policy as its own rule family, the eight invariant numbers unchanged, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan, and this atom is the corpus's simplest shape — the one a reader meets first.

- **2026-09-14 — The atom gained an acceptance surface, kept deliberately plain.** *Chose:* fourteen `Check` rules and three `External check` rules, each one reading of the list against one rule. *Over:* a richer section. *Because:* presence became mandatory on 2026-09-14, and this atom is the reference implementation's first worked example, so its section teaches the shape more than it audits a risk. Two things it does carry are not decoration: the three timestamp checks keep the invariants' conditional form rather than chaining them, since an auditor comparing `added_at ≤ last_edited_at ≤ completed_at` over every unit files against a correct list; and `Check 3.4`'s passing condition is that **nothing happened** — a no-op edit answers ok and writes nothing, so the evidence of conformance is a stamp that did not move (council read 65).

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every unit with its stored fields (Operation 28 through 31). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — "the current set of pending units" and done units, each with its fields — and the migration dropped it with the section. Restored as the prose had it, not widened. Found beside the same loss in Permissions and Actor Identity, which the cold regeneration of the Attributed Permissions Admin demo surfaced (council read 230).

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 4), and the five rules that restated them tombstoned to their owner — Concurrency 2, every transition atomic, and External check 2, the auditor's evidence of that atomicity, to Store 1; Concurrency 3, a deployment running two clients composing a concurrency-resolution pattern, and External check 3, the auditor's evidence of that pattern, to Store 2; Operation 6, no unit recorded by an [Add] that answers storage-failure, to Store 3; rules 111 to 107. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. Two clients' calls on one unit, all the page gave a concurrency-resolution pattern to resolve, are serialized by Store 2 for every deployment: the later call reads what the earlier committed, and the active-set duplicate check reads inside the transaction that writes. A refused call leaving the unit as the call found it stays the atom's own (Operation 24), as do the linear sequence of one actor's calls the atom assumes (Concurrency 1), the atom itself resolving no two concurrent calls (Non-goal 14) and the id that never changes (Invariant 8.2). The atom keeps no history of a unit (State 10, Non-goal 13), its checks compare the auditor's own reads, and it orders no units (Non-goal 10), so it cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-20 — Undo History retired, and restoration is the store's history.** *Chose:* Non-goal 7, a deployment needing restoration composing Undo History, and Composition note 4, a composing pattern needing restoration appending a deleted unit to an Event Log, tombstoned to Execution Contract Store 5; rules 107 to 105. *Over:* restoration through a composition that kept its own copy of every deleted unit in an event log and replayed it. *Because:* the maintainer ruled 2026-10-20 that Undo History retires: Store 5 keeps every committed version of a record readable, so an undone deletion comes back with its id, timestamps and description, and no composing pattern needs a copy of its own. The atom itself still restores nothing (Non-goal 6). What the atom does for its domain is unchanged.

- **2026-10-22 — An edit resubmitting a unit's own text is a no-op under any cap, and an edit's state is held by the rules of the edit.** *Chose:* Operation 9a held to a new description that differs from the unit's own, with Description 4 and Description 5 naming [Add], so an [Edit] that resubmits a unit's text answers ok, writes nothing and stamps nothing, though a deployment has since lowered the description cap below the stored text; Invariant 5.1, that an edited unit stands in pending, deleted to Invariant 5.2 and Operation 8, and Check 3.2, which tested it, to Check 3.3. *Over:* two rules obliging invalid-description and ok on one call; and a property of every reachable state that a unit edited and then completed breaks, with a check that every conforming list holding such a unit fails. *Because:* Final Critique 5 found both. The case table already answered every same-text edit ok, and under the method's 2026-10-08 rule a rule a lawful state breaks is deleted to the rules that already hold that state: [Edit] lands only on a pending unit (Operation 8) and changes no field beside description and last edit instant (Invariant 5.2), the unit state among them. Smaller fixes rode with them: Invariant 7.1 through 7.3 compare instants with PRECEDES (GRACE-lang Earned vocabulary 18), and Check 4.1 through 4.3 read only a unit carrying the instants they compare; Check 1.1 in Invariant 1.1's words; the Now entry names every action that stamps from now; acronyms glossed at first use; rules 105 to 103. What each action answers and writes is unchanged except on the one call the two rules had split.

- **2026-10-31 — What a call writes is the contract's.** *Chose:* Operation 11, that an [Edit] resubmitting a unit's text writes nothing, deleted to Execution Contract Conformance 1, so that edit writes the unit unchanged, as every admitted call does, and answers storage-failure where the database refuses the write; Operation 24, that a refused call leaves the unit as it found it, and Check 5.1, which tested it, deleted to Execution Contract Read 4. *Over:* the page saying for itself what its calls write, against the pipeline's Step 3 in the first case and restating Read 4 in the second. *Because:* Final Critique 6 found that no build could obey both Operation 11 and the pipeline, which writes on every admitted call, and that no record names a refused call, so Check 5.1 passed every deployment, one writing on a refused call included. The 2026-10-22 entry's *writes nothing* and the 2026-10-20 entry's Operation 24 came before Read 4 (2026-10-22). Smaller fixes rode with them: [Edit]'s invalid-description rests on stated conditions (Operation 32 through 34) where Operation 9a leaned on rules naming [Add], and a malformed description answers it on both actions (Description 9, Operation 34); Invariant 1.1 deleted to State 1, Invariant 8.1 to State 2 and Identity 3 to Execution Contract Logic confinement 3; the checks read the committed versions (Execution Contract Generation acceptance 1); the description cap is the deployment's to declare (Capability requirement 5); rules 103 to 101. What each action answers is unchanged except where the page had said two things or nothing: a same-text edit whose write the database refuses, an edit's blank or over-cap text, and a malformed description.

- **2026-11-19 — Invariant 2.1 and 3.1 stay, and the checks that test them are written, not the invariants deleted.** *Chose:* Check 2.4, that no unit stands in pending in a committed version after standing in done in an earlier one (Invariant 2.1, State 9, Execution Contract Generation acceptance 1), and Check 2.1 citing Invariant 2.1 and 3.1, since a deleted unit standing in pending or in done is a deleted unit whose id is in the list. *Over:* deleting the two invariants to State 9 and State 10, the other arm of open line 2026-11-03-b. *Because:* the two invariants head the page's persistence statements and the model holds them as written, so deleting them loses a statement for the cost of one check line, and "as simple as possible without losing fidelity" picks the arm that keeps them. Overrule by deleting Check 2.4 and the two citations and the invariants with them.

- **2026-11-19 — An edit carrying a description over the cap is refused, whatever the unit's own text.** *Chose:* Operation 33 conditioned on the call alone (a pending unit and a new description the call carries over the cap answer invalid-description) and Operation 10 holding where the call is within the cap, so an [Edit] that resubmits a unit's text with trailing whitespace past the cap answers invalid-description, as an [Add] of the same text does (Description 5). *Over:* the 2026-10-22 entry's guard, Operation 33 held to a new description that differs from the unit's own, so a resubmission answers ok under any cap. *Because:* Final Critique 9 (Linus) traced a call whose normalized text equals the unit's and whose carried text is one space over the cap: Execution Contract Input 2 counts the cap on the value as the call carries it and makes a call over it malformed, Operation 34 refuses a malformed new description on a pending unit, and Operation 10 answered ok on the same call, so the page's rules disagreed. The 2026-10-22 entry's reason was a cap a deployment lowered below stored text; Input 2 now bars a cap a stored value exceeds, so that case cannot arise, and as simple as possible without losing fidelity is one rule for the cap on both actions. Overrulable by a new direction.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Personal Todo](./personal-todo.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
```

### Structure › State

```
Deleted: State 8. Operation 19 and Operation 20 own it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Non-goal 16 owns it.
```

### Structure › Operations

```
Deleted: Operation 3. The add signature's answers line owns it (Closed vocabulary 21 and Closed vocabulary 25).
Deleted: Operation 5. Execution Contract Read 4 owns it.
Deleted: Operation 6. Execution Contract Database 3 owns it.
Deleted: Operation 9a. Operation 32 and Operation 33 own it.
Deleted: Operation 11. Execution Contract Conformance 1 owns the admitted call's write.
Deleted: Operation 21. Execution Contract Read 4 owns it.
Deleted: Operation 22. Execution Contract Read 4 owns it.
Deleted: Operation 23. Execution Contract Read 4 owns it.
Deleted: Operation 24. Execution Contract Read 4 owns it.
Deleted: Operation 25. Capability requirement 1 owns it.
Deleted: Operation 26. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 27. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 31. The read signature, which lists no refusal, and Execution Contract Read 1 own it.
```

### Structure › Invariants › Invariant 1 — Membership exclusivity

```
  Deleted: Invariant 1.1. State 1 owns it.
```

### Structure › Invariants › Invariant 4 — Delete is terminal

```
  Deleted: Invariant 4.2. Identity 5 owns id reuse for every id, deleted or not.
```

### Structure › Invariants › Invariant 5 — Edit preserves state

```
  Deleted: Invariant 5.1. Invariant 5.2 and Operation 8 own it.
```

### Structure › Invariants › Invariant 8 — Id stability

```
  Deleted: Invariant 8.1. State 2 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 3.2. Check 3.3 owns it.
Deleted: Check 5.1. Execution Contract Read 4 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 2. Execution Contract Database 1 owns it.
Deleted: External check 3. Execution Contract Database 2 owns it.
```

### Non-goals

```
Deleted: Non-goal 7. Execution Contract Database 5 owns it.
```

### Edge cases › Concurrency on one unit

```
Deleted: Concurrency 2. Execution Contract Database 1 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Composition notes

```
Deleted: Composition note 4. Execution Contract Database 5 owns it.
```
