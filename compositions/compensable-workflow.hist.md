---
title: Compensable Workflow — history
nav_exclude: true
search_exclude: true
---

# Compensable Workflow — history

The dated record of how [Compensable Workflow](./compensable-workflow.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/compensable-workflow.md`.

## Decisions

Entries that record a migration or a rename rather than a turn the pattern took.

- **2026-09-23 — Rewritten in GRACE lang v0.61; nothing but language changed except one tombstone and eight repairs the rewrite could not restate.** *Chose:* `Composes`, `Composition state` with `Replay` beneath it, `Capability requirement`, `Primitive policy`, `Action wiring`, `Wiring decision` and `Event schemas` as the surfaces, in Undo History's and Idempotent Reservation's shapes; invariant numbers 1 through 8 unchanged and Invariant 9 tombstoned; a `Generation acceptance` section with seventeen `Check` and seven `External check` rules, each naming the rule it tests; `Non-goals` and `Edge cases` split, with `Concurrency` and `Indeterminate outcome` under the second; `Compensation Ref` renamed `Compensation Reference`, and `Start Workflow` renamed `Start Compensable Workflow`, the name its wire always carried. The repairs: the compensable workflow record loses the outcome field it declared *set once at start and immutable* while setting it at the terminal and writing it at no step — the replay reads it from the terminal marker (Composition state 5, Replay 5 and 6); a commit event is appended when no next step remains (Action wiring 31), where the prose named the terminal marker and no step that wrote it; the continue policy ends through standing failures (Action wiring 32, 40 and 41), where *move on* re-picked a failed step on every [Advance], since a compensation failure leaves the step completed; a marker whose append fails with an effect standing unrecorded answers effect-landed (Action wiring 55), where the prose positioned it nowhere; [Cancel] past a pivot answers roll-forward (Action wiring 73), where the prose promised *its roll-forward disposition* and declared none; [Cancel] writes only in the forward phase (Action wiring 74 through 76), where a compensation onset event appended in the compensating phase would have fired a transition the spine refuses and answered spine-fault to an ordinary call; [Advance] fires an owed transition before answering already-terminal (Action wiring 81), where the prose answered first and left a terminal marker's owed `fire` to a [Cancel] nobody sends; and two citations re-aimed — the obligation-realization boundary lives in `working-ideas/outbound-contract-ports.md`, not in `execution-contract.md`, and Undo History states the boundary the Intent quoted as Undo History Non-goal 10, the sentence quoted being gone. *Over:* the prose spec, and a first migration that restated those eight as it found them. *Because:* the migration plan, and the standing rule that a finding is fixed in the pass that finds it. Invariant 9, *constituent invariants preserved*, is the class council read 53 ruled — Execution Contract Conformance 8 settles it by reference and Composes 10 cites it — at the class's fourth seam, Idempotent Reservation's being the third. Richardson's title in Standards references is *Microservices saga* again: the saga rename reached a cited title, and a citation keeps the author's word. `formal:` and the open model line are unchanged — the model was stale for reasons that predate this rewrite, and the rewrite touches no `.tla`.

- **2026-09-23 — Progress for where a compensable workflow has got, position for where a write lands.** *Chose:* the phase, current step and outcome renamed **progress**, the read action Position renamed **[Read Progress]** with the wire read_progress, and Invariant 2 titled *Progress equivalence*, numbers unchanged. *Over:* keeping *position* in both senses. *Because:* the page used *position* for two things — the storage-failure positions, which is the sense four other specifications declare, and the phase-step-outcome triple no other page means by it — and a name carries one meaning (council read 166's ruling: this page renames, the corpus keeps *position*). *Progress* is the page's own word for the thing (*forward progress*), and a read action takes the corpus's *Read* form beside [Read Log]; the answer arm is the declared term itself. The TLA+ header's comment still says *position equivalence*; the model is stale for older reasons and untouched here.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Compensable Workflow](./compensable-workflow.md) may carry it again.

### Composition logic › Capability requirement

```
Deleted: Capability requirement 10. Capability requirement 9 owns it.
Deleted: Capability requirement 12. Execution Contract Database 3 owns it.
Deleted: Capability requirement 13. Execution Contract Database 3 owns it.
Deleted: Capability requirement 14. Execution Contract Database 3 owns it: the composition names no constituent record durability for a deployment to leave blank.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 4. Primitive policy 12 owns it: a step declaring no compensating action is refused invalid-definition when it is an unmarked irreversible step, and admitted when it is marked.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 7. Execution Contract Database 1 and Execution Contract Database 2 own it: a start's instantiate, start event and record commit together, in one transaction the database serializes.
Deleted: Action wiring 12. Execution Contract Database 1 owns it: a transition-bearing event and its fire commit together, so no transition is ever owed.
Deleted: Action wiring 13. Execution Contract Database 1 owns it: a transition-bearing event and its fire commit together, so no transition is ever owed.
Deleted: Action wiring 14. Execution Contract Database 1 owns it: a transition-bearing event and its fire commit together, so no transition is ever owed.
Deleted: Action wiring 51. Replay 11 and Action wiring 15 own it: a resume marker is an attempt marker, held unresolved unless its effect key is already applied, and the re-entry arm re-runs every unresolved attempt, once per re-entry arm execution per effect key.
Deleted: Action wiring 56. Action wiring 52 through 55 and Execution Contract Database 1 own it: a transition-bearing event and its fire commit together, so a fire's storage failure leaves its event unlanded.
Deleted: Action wiring 66. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 69. Execution Contract Database 1 owns it: a transition-bearing event and its fire commit together, so no transition is ever owed.
Deleted: Action wiring 70. Execution Contract Database 1 owns it: a transition-bearing event and its fire commit together, so no transition is ever owed.
Deleted: Action wiring 81. Execution Contract Database 1 owns it: a transition-bearing event and its fire commit together, so no transition is ever owed.
Deleted: Action wiring 82. Execution Contract Database 1 owns it: a transition-bearing event and its fire commit together, so no transition is ever owed.
```

### Composition-level invariants › Invariant 1 — Log faithfulness

```
  Deleted: Invariant 1.3. Execution Contract Database 3 owns it.
```

### Composition-level invariants › Invariant 2 — Progress equivalence

```
  Deleted: Invariant 2.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 2.3. Execution Contract Database 1 and Execution Contract Database 3 own it.
```

### Composition-level invariants › Invariant 8 — Forward-closed after abort

```
  Deleted: Invariant 9. Composes 10 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 5. Execution Contract Database 3 owns it.
```
