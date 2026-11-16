---
title: Compensable Workflow — history
nav_exclude: true
search_exclude: true
---

# Compensable Workflow — history

The dated record of how [Compensable Workflow](./compensable-workflow.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/compensable-workflow.md`.

## Decisions

Entries that record a migration or a rename rather than a turn the pattern took.

- **2026-08-30 — An attempt is recorded before its effect, one writer per run, the ledger honest about which half it is, and the log authoritative over the spine.** *Chose:* `step_attempted` / `compensation_attempted` markers appended before every effect, so an effect whose outcome nobody recorded is an unresolved attempt the records show, over which [Cancel] refuses ([Step Unresolved]) and no compensating phase begins; a three-verdict effect (applied / definitely failed / indeterminate) with the phase flipping only on a verdict the target returned and [Effect Indeterminate] at `step_completion_bound`; `per_run_serialization` declared as an instance capability requirement with lease semantics, under which the `applied_effects` pre-check is re-read; a three-branch re-entry arm (record landed and `fire` missing / attempt present and record missing / fresh) with the log authoritative for position and the State Machine brought to it; Invariant 7 restated as a record-side ledger plus an effect-side key discipline declared as `effect_key_honoured` within `effect_key_horizon`; `constituent_store_durability` declared, with Invariants 1, 2 and 7 conditional on it; the completion record sized at [Start Compensable Workflow] against the Event Log cap with invalid-payload transcribed there only; `storage-failure(effect-landed | none)` on [Advance]; post-pivot roll-forward bounded per invocation and surfaced in [Halted]. On the closure check of the same day: the halted marker parks an attempt and does not resolve it, so [Cancel] stays refused through [Halted] and the exit is the operator's [Advance] carrying `within_horizon = true` (the horizon assertion made explicit in the signature and on the resume marker); `unresolved_attempts` a set, for parallel; a third position `storage-failure(spine)` for a record landed and its `fire` owed, every phase and terminal marker followed by a `fire` and re-derived at branch 1, and any other `fire` refusal a [Spine Fault] finding; one landing for an overflowed envelope — truncated record, `arguments_overflow = true`, operator-supplied compensation_arguments; the peer's third answer as target-unknown; the lease expiry as the terminus for writes with lost = expired = yield; [Read Progress] reading the log, never the spine; [Start Compensable Workflow] serializing on `instantiate` because its id does not yet exist. *Over:* a ledger built from the record that failed, credited with preventing the double-charge it could not see; "the action did not happen" written over a token that also landed after the charge; a phase flip on any failure, timeouts included; *retry until success* past the pivot; a position claimed equal in two stores nothing made equal; durability and idempotency the constituents and the peer decline, used as if granted. *Because:* two deliveries reading one empty ledger both charge the card; a caller told nothing committed cancels over a charge and reaches [Compensated] with it standing; and a guarantee resting on an undeclared capability is only as sound as the capability nobody declared (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *An outcome is sized before the intent*, *A composition's own rejection arm carries the retry bit*, *Capability provenance* frozen — with §*Recovery commits under a declared service identity*'s re-derivability and re-entry clauses).

- **2026-09-23 — Rewritten in GRACE lang v0.61; nothing but language changed except one tombstone and eight repairs the rewrite could not restate.** *Chose:* `Composes`, `Composition state` with `Replay` beneath it, `Capability requirement`, `Primitive policy`, `Action wiring`, `Wiring decision` and `Event schemas` as the surfaces, in Undo History's and Idempotent Reservation's shapes; invariant numbers 1 through 8 unchanged and Invariant 9 tombstoned; a `Generation acceptance` section with seventeen `Check` and seven `External check` rules, each naming the rule it tests; `Non-goals` and `Edge cases` split, with `Concurrency` and `Indeterminate outcome` under the second; `Compensation Ref` renamed `Compensation Reference`, and `Start Workflow` renamed `Start Compensable Workflow`, the name its wire always carried. The repairs: the compensable workflow record loses the outcome field it declared *set once at start and immutable* while setting it at the terminal and writing it at no step — the replay reads it from the terminal marker (Composition state 5, Replay 5 and 6); a commit event is appended when no next step remains (Action wiring 31), where the prose named the terminal marker and no step that wrote it; the continue policy ends through standing failures (Action wiring 32, 40 and 41), where *move on* re-picked a failed step on every [Advance], since a compensation failure leaves the step completed; a marker whose append fails with an effect standing unrecorded answers effect-landed (Action wiring 55), where the prose positioned it nowhere; [Cancel] past a pivot answers roll-forward (Action wiring 73), where the prose promised *its roll-forward disposition* and declared none; [Cancel] writes only in the forward phase (Action wiring 74 through 76), where a compensation onset event appended in the compensating phase would have fired a transition the spine refuses and answered spine-fault to an ordinary call; [Advance] fires an owed transition before answering already-terminal (Action wiring 81), where the prose answered first and left a terminal marker's owed `fire` to a [Cancel] nobody sends; and two citations re-aimed — the obligation-realization boundary lives in `working-ideas/outbound-contract-ports.md`, not in `execution-contract.md`, and Undo History states the boundary the Intent quoted as Undo History Non-goal 10, the sentence quoted being gone. *Over:* the prose spec, and a first migration that restated those eight as it found them. *Because:* the migration plan, and the standing rule that a finding is fixed in the pass that finds it. Invariant 9, *constituent invariants preserved*, is the class council read 53 ruled — Execution Contract Conformance 8 settles it by reference and Composes 10 cites it — at the class's fourth seam, Idempotent Reservation's being the third. Richardson's title in Standards references is *Microservices saga* again: the saga rename reached a cited title, and a citation keeps the author's word. `formal:` and the open model line are unchanged — the model was stale for reasons that predate this rewrite, and the rewrite touches no `.tla`.

- **2026-09-23 — Progress for where a compensable workflow has got, position for where a write lands.** *Chose:* the phase, current step and outcome renamed **progress**, the read action Position renamed **[Read Progress]** with the wire read_progress, and Invariant 2 titled *Progress equivalence*, numbers unchanged. *Over:* keeping *position* in both senses. *Because:* the page used *position* for two things — the storage-failure positions, which is the sense four other specifications declare, and the phase-step-outcome triple no other page means by it — and a name carries one meaning (council read 166's ruling: this page renames, the corpus keeps *position*). *Progress* is the page's own word for the thing (*forward progress*), and a read action takes the corpus's *Read* form beside [Read Log]; the answer arm is the declared term itself. The TLA+ header's comment still says *position equivalence*; the model is stale for older reasons and untouched here.

- **2026-10-21 — The database's guarantees cited, not restated, the owed transition among them.** *Chose:* the database supplied under Execution Contract Database 1 through 4 (Capability requirement 20), and the sixteen rules that restated them, or existed only for a database that could split or forget a write, tombstoned to their owner — to Database 1, under which a transition-bearing event and its fire commit together, so no transition is ever owed: the re-entry arm's branch that fired an owed transition and ran nothing ahead of it (Action wiring 12 through 14), [Cancel]'s firing of it ahead of its compensation onset event (Action wiring 69, 70), [Advance]'s and [Cancel]'s firing of it ahead of already-terminal (Action wiring 81, 82), and the disclaimer of an atomic pair across the spine and the step log (Invariant 2.2); to Action wiring 52 through 55 and Database 1, the spine position of a storage failure (Action wiring 56), which the advance and cancel failure positions lose; to Database 1 and Database 2, a start serialized through instantiate (Action wiring 7); to Database 3, the step log and the spine kept across a restart, the refusal to start without that declaration, the log-faithfulness claim conditioned on it and its external check (Capability requirement 12 through 14, Invariant 1.3, External check 5); and to Database 1 and Database 3, the progress-equivalence claim's conditions (Invariant 2.3). The at-most-once claim is conditioned on the target key discipline and the critical section alone (Invariant 7.1, External check 6); rules 243 to 228. *Over:* a spine and a step log written by separate commits, with a re-entry branch to fire the transition a crash or a storage failure left owed, and a deployment's declaration that both survive a restart — the turn of 2026-08-30, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a database's specification, never the database, and 2026-10-20 that Database 1 binds every database write of one composition action, its constituents' included, acts outside the database staying Recoverable Invocation's: State Machine's workflow and Event Log's events are records in the one database, so a transition-bearing event and its fire commit together or not at all, and a committed write is kept across a restart. What stays is the composition's own, since an effect is an act outside the database, an irreversible act no transaction encloses (the section titled Substrate composition invocation in `execution-contract.md`): the attempt marker commits before the effect and the completion record after it, so the re-entry arm still re-runs an unresolved attempt under its own key and a storage failure still answers none or effect-landed; and the critical section still keeps a second invocation off the effect, the job the maintainer's ruling of 2026-10-20 keeps for a lease around an act outside the database. No rule reads a record as it stood at a past commit or compares two commits, so the composition cites neither Database 5 nor Order 1. What the composition does for its domain is otherwise unchanged.

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
